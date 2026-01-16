---
layout: post
title: Inside Mirage (2) - Transpiler from MuGraph to CUDA
date:  2025-11-25 00:00:00
description: Deep dive into Mirage's transpiler - the journey from MuGraph to CUDA through fusion resolution, layout planning, scheduling, and code generation
tags:
categories:
tabs: true
thumbnail:
mermaid:
  enabled: true
  zoomable: true
toc:
  beginning: true
  # sidebar: left
pretty_table: true
tikzjax: true
pseudocode: true
---

In this blog, we dive deep into **Mirage's Transpiler**, the component responsible for translating optimized MuGraph representations into efficient CUDA code. The transpiler bridges the gap between the high-level graph representation and low-level GPU execution.

> This chapter is based on [`docs/transpiler/transpiler.md`](https://github.com/arch-of-shadow/mirage/tree/uv_tutorial_00/docs/transpiler/transpiler.md). It is very nice and detailed. I recommend reading it first to get the algorithm insights.

> For Runtime knowledge, I learned from [Zhihu](https://www.zhihu.com/collection/694786845) and [Weixin](https://mp.weixin.qq.com/s/sVjLJMHGpeSuLFaKOmBeow).

> **Note:** This post follows the hands-on [Mirage Tutorial (uv_tutorial_00 branch)](https://github.com/arch-of-shadow/mirage/tree/uv_tutorial_00).

---

## 1. Overview

The transpiler takes a kernel graph (potentially containing custom threadblock graphs) and generates optimized CUDA code. This is both an **algorithmic challenge** (deciding tensor layouts, memory allocation, scheduling) and an **engineering challenge** (maintaining correctness while maximizing performance).

### 1.1 Architecture

The transpiler consists of two major components:

1. **The Transpiler** (`src/transpiler/`): Translates MuGraph into CUDA code
2. **The Runtime** (`include/mirage/transpiler/runtime/`): Header-only library providing optimized kernels for the generated code

```
┌─────────────────────┐
│   Kernel Graph      │
│   (MuGraph)         │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│   Transpiler        │
│  ┌───────────────┐  │
│  │ Fusion        │  │
│  │ Resolution    │  │
│  └───────┬───────┘  │
│          ▼          │
│  ┌───────────────┐  │
│  │ Layout        │  │
│  │ Resolution    │  │
│  └───────┬───────┘  │
│          ▼          │
│  ┌───────────────┐  │
│  │ TB Graph      │  │
│  │ Scheduling    │  │
│  └───────┬───────┘  │
│          ▼          │
│  ┌───────────────┐  │
│  │ Swizzle       │  │
│  │ Planning      │  │
│  └───────┬───────┘  │
│          ▼          │
│  ┌───────────────┐  │
│  │ Memory        │  │
│  │ Planning      │  │
│  └───────┬───────┘  │
│          ▼          │
│  ┌───────────────┐  │
│  │ Code          │  │
│  │ Generation    │  │
│  └───────────────┘  │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│   Generated CUDA    │
│   + Runtime Headers │
└─────────────────────┘
```

### 1.2 Source Code Structure

The transpiler source code is organized as follows:

| File | Purpose |
|------|---------|
| `transpile.cc` | Main entry point, graph preprocessing |
| `resolve_tb_fusion.cc` | Threadblock-level operator fusion |
| `resolve_tensor_layout.cc` | Layout resolution using Z3 solver |
| `sched_tb_graph.cc` | Threadblock graph scheduling |
| `plan_tb_swizzle.cc` | Swizzle planning to avoid bank conflicts |
| `plan_dtensor_memory.cc` | Global memory planning for DTensors |
| `plan_stensor_memory.cc` | Shared memory planning for STensors |
| `transpiler_kn.cc` | Kernel-level code generation |
| `transpiler_tb.cc` | Threadblock-level code generation |
| `transpiler_tb_hopper.cc` | Hopper-specific code generation |
| `transpiler_tb_blackwell.cc` | Blackwell-specific code generation |

### 1.3 Transpiler Pipeline

The transpilation process follows these steps (from `transpiler.h`):

```cpp
TranspileResult generate_code() {
  this->resolve_distributed_config();  // Multi-GPU configuration
  this->resolve_dtensor_meta();        // Gather tensor metadata
  this->resolve_tb_fusion();           // Plan operator fusion
  this->resolve_tensor_layout();       // Decide tensor layouts
  this->plan_dtensor_memory();         // Allocate global memory
  return this->transpile_ugraph();     // Generate CUDA code
}
```

## 2. Threadblock-Level Data Fusion

The first step is deciding which operators can be fused together to reduce memory traffic.

### 2.1 The Problem

In threadblock-level code, operators read from shared memory, compute, and write back. Fusion avoids intermediate memory operations:

**Without Fusion:**
```
Matmul: Read A, B → Compute → Write C to SMEM
Exp:    Read C from SMEM → Compute → Write D to SMEM
```

**With Fusion:**
```
Matmul+Exp: Read A, B → Compute Matmul → Apply Exp in registers → Write D to SMEM
```

### 2.2 Fusion Rules

Currently, Mirage fuses **unary elementwise operators** with their predecessor when:
1. The predecessor has exactly one consumer
2. The predecessor is not an input op with `forloop_dim = -1`
3. The predecessor is not a forloop accumulator (the loop body vs. outside the loop)
4. The predecessor is not a reduction max op (which has two outputs)

**Code Reference** (`src/transpiler/resolve_tb_fusion.cc:39-65`):

```cpp
// Currently we only fuse elementwise unary operators and
// forloop_accum_no_red with the previous operator
for (tb::TBOperator *const op : tb_graph.operators) {
  if ((type::is_threadblock_element_unary(op->op_type)) ||
      (op->op_type == type::TB_FORLOOP_ACCUM_NO_RED_OP)) {
    tb::STensor const &input0 = op->input_tensors.at(0);
    tb::TBOperator *prev_op = input0.owner_op;
    // Check various conditions...
    if (num_consumers.at(input0.guid) == 1 &&
        prev_op->op_type != type::TB_FORLOOP_ACCUM_NO_RED_OP &&
        prev_op->op_type != type::TB_INPUT_OP &&
        /* ... other conditions ... */) {
      is_fused_with_prev[op] = true;
      is_fused_with_next[prev_op] = true;
    }
  }
}
```

### 2.3 Fusion Chains

After determining fusion relationships, operators are grouped into **chains**:

```cpp
// Construct `fusion_chain`
for (tb::TBOperator *const last_op : tb_graph.operators) {
  if (is_fused_with_next[last_op]) continue;
  // Now last_op is the tail of a fusion chain
  std::vector<tb::TBOperator const *> fused_ops;
  tb::TBOperator *cur_op = last_op;
  while (true) {
    fused_ops.push_back(cur_op);
    if (is_fused_with_prev[cur_op]) {
      cur_op = cur_op->input_tensors.at(0).owner_op;
    } else {
      break;
    }
  }
  std::reverse(fused_ops.begin(), fused_ops.end());
  fusion_chain[leading_op] = fused_ops;
}
```

**Example Chain:**
```
Matmul → Exp → Square → Store
  ↑
Leading Op    Fused Ops →
```

## 3. Layout Resolution

Tensor layout (the stride of each dimension) critically affects performance. The transpiler uses the **Z3 SMT solver** to find optimal layouts.

### 3.1 Problem Formulation

For each tensor dimension, we create boolean variables:
- `di_x_y`: Is dimension y of DTensor x the innermost dimension?
- `si_x_y`: Is dimension y of STensor x the innermost dimension?
- `sw_x_y`: Is dimension y of STensor x swizzled?

### 3.2 Constraints

**Hard constraints** (must be satisfied):
1. Each tensor has exactly one innermost dimension
2. Each STensor has at most one swizzled dimension
3. The innermost dimension cannot be swizzled
4. Matmul inputs/outputs must have innermost dim in last two dimensions
5. Input tensors must match the user-provided stride layout

**Code Reference** (`src/transpiler/resolve_tensor_layout.cc:179-216`):

```cpp
for (kn::DTensor const &dtensor : all_dtensors) {
  // Every DTensor can only have 1 innermost dim
  z3::expr_vector innermost_exprs(ctx);
  for (int i = 0; i < num_dims; ++i) {
    innermost_exprs.push_back(d_is_innermost[dtensor.guid][i]);
  }
  opt.add(z3::atmost(innermost_exprs, 1));
  opt.add(z3::atleast(innermost_exprs, 1));
}

// For matmul, innermost must be in last two dims
for (kn::DTensor const &tensor : {lhs, rhs, output}) {
  int num_dims = tensor.num_dims;
  opt.add(d_is_innermost[tensor.guid][num_dims - 1] ||
          d_is_innermost[tensor.guid][num_dims - 2]);
}
```

### 3.3 Cost Model

The optimizer minimizes a cost function:

| Scenario | Cost |
|----------|------|
| Input without wide copy | 4000 |
| Output without wide copy | 4000 |
| Matmul without ldmatrix | 10000 |
| Input without cp.async | 20000 |
| Swizzling a dimension | 1000 |
| Shared memory usage | 1 per byte |

**Code Reference** (`src/transpiler/resolve_tensor_layout.cc:51-76`):

```cpp
namespace cost {
cost_t KN_REDUCTION_INNERMOST_EQ_REDUC_DIM = 4000;
cost_t TB_INPUT_NO_WIDE_COPY = 4000;
cost_t TB_OUTPUT_NO_WIDE_COPY = 4000;
cost_t TB_MATMUL_NO_LDMATRIX = 10000;
cost_t TB_INPUT_NO_CP_ASYNC = 20000;
cost_t SWIZZLE_DIM = 1000;
cost_t SMEM_FACTOR = 1;
}
```

### 3.4 Stride Calculation

After determining innermost dimensions, strides are calculated:

```cpp
void calc_tensor_strides(size_t *strides, size_t &num_phy_elems,
                         int num_dims, int const dims[],
                         int innermost_dim, int datatype_size) {
  // Order: [innermost, N-1, N-2, ..., innermost+1, innermost-1, ..., 0]
  vector<int> dim_order = {innermost_dim};
  for (int i = num_dims - 1; i >= 0; --i) {
    if (i != innermost_dim) dim_order.push_back(i);
  }

  size_t alignment = std::max(16 / datatype_size, 1);
  size_t cur_stride = 1;
  for (int dim_idx : dim_order) {
    strides[dim_idx] = cur_stride;
    if (dims[dim_idx] != 1) {
      // Pad first non-1 dimension to 16-byte alignment
      cur_stride *= round_to_multiple((size_t)dims[dim_idx], alignment);
    }
  }
  num_phy_elems = cur_stride;
}
```

**Example:**
```
Shape: [4, 8, 16], innermost_dim = 2, dtype = half (2 bytes)
Order: [2, 1, 0]
Strides: [128, 16, 1]  (dim 2 padded: 16 → 16, dim 1: 16*8=128)
```

## 4. Threadblock Graph Scheduling

The scheduler determines the order of operator execution within a threadblock.

### 4.1 Objectives

1. **Minimize synchronizations** (`__syncthreads()`)
2. **Minimize peak shared memory usage**

These can conflict - the scheduler prioritizes fewer synchronizations.

### 4.2 Algorithm: Modified Topological Sort

Each operator is assigned a **depth** (longest path from any input):

```cpp
// Calculate depth using dynamic programming
for (tb::TBOperator *const op : tb_graph.operators) {
  if (op->op_type == type::TB_INPUT_OP) {
    op2chaining_meta[op] = {0, next_chain_idx++, 0};
  }
}
for (tb::TBOperator *const op : tb_graph.operators) {
  if (op->op_type == type::TB_INPUT_OP) continue;
  if (is_fused_with_prev[op]) {
    // Same depth as predecessor
    OpChainingMeta prev_meta = op2chaining_meta.at(prev_op);
    op2chaining_meta[op] = {prev_meta.level, prev_meta.fuse_chain_idx,
                            prev_meta.pos_in_fuse_chain + 1};
  } else {
    // max(input depths) + 1
    int res = 0;
    for (tb::STensor const &input : op->input_tensors) {
      res = std::max(res, op2chaining_meta.at(input.owner_op).level);
    }
    op2chaining_meta[op] = {res + 1, next_chain_idx++, 0};
  }
}
```

### 4.3 Schedule Structure

The schedule has three phases:

```cpp
struct TBSched {
  std::vector<TBSchedNode> pre_loop_nodes;   // Before the forloop
  std::vector<TBSchedNode> loop_nodes;       // Inside the forloop
  std::vector<TBSchedNode> post_loop_nodes;  // After the forloop
};
```

**Synchronization Rule:** A `__syncthreads()` is inserted when the depth changes.

### 4.4 Metadata Refinement

The scheduler also decides per-operator metadata:

```cpp
struct TBSchedOpMeta {
  bool is_chunked_input;    // Use 128-bit wide copies?
  bool is_pipelined_input;  // Use async cp.async?
  bool is_chunked_output;   // Use 128-bit wide writes?
  bool is_accum_in_reg;     // Keep accumulator in registers?
  // ...
};
```

**Register Accumulator Heuristic** (`src/transpiler/sched_tb_graph.cc:236-253`):
```cpp
// Allow accumulators to take up to 192 registers per thread
// (Each thread has 255 32-bit registers max)
if (per_thread_accum_numel_tot + per_thr_accum_numel <= 192) {
  op_meta.is_accum_in_reg = true;
  per_thread_accum_numel_tot += per_thr_accum_numel;
} else {
  op_meta.is_accum_in_reg = false;
}
```

## 5. Swizzle Planning

Swizzling reorders shared memory layout to avoid **bank conflicts**.

### 5.1 The Problem

Shared memory has 32 banks. When threads in a warp access the same bank, accesses are serialized. The `ldmatrix` instruction loads 16x16 tiles - without swizzling, threads may conflict.

### 5.2 XOR-Based Swizzling

Used when the innermost dimension size is a power of 2:

```
new_addr = old_addr XOR row
```

**Example (8x8 tensor, 8 banks):**
```
Original:              Swizzled:
Bank: 0 1 2 3 4 5 6 7  Bank: 0 1 2 3 4 5 6 7
Row 0: 0 1 2 3 4 5 6 7  Row 0: 0 1 2 3 4 5 6 7
Row 1: 0 1 2 3 4 5 6 7  Row 1: 1 0 3 2 5 4 7 6  (XOR with 1)
Row 2: 0 1 2 3 4 5 6 7  Row 2: 2 3 0 1 6 7 4 5  (XOR with 2)
...
```

**Parameters:** CuTe's `Swizzle<B, M, S>` with:
- B = log2(num_chunks_in_128B)
- M = log2(chunk_size_in_elements)
- S = log2(num_chunks_in_inner_dim)

### 5.3 Shift-Based Swizzling

Used when innermost dimension is not a power of 2:

```
new_addr = old_addr + row * shift
```

The shift is chosen so that `gcd(new_stride, num_banks) == 1`.

**Code Reference** (`src/transpiler/plan_tb_swizzle.cc:141-172`):

```cpp
if (is_power_of_2(num_chunks_in_inner_dim)) {
  // XOR-based swizzling
  meta.is_xor_swizzled = true;
  meta.xor_swizzle_b = log2(num_chunks_in_128B);
  meta.xor_swizzle_m = log2(chunk_size_num_elems);
  meta.xor_swizzle_s = log2(num_chunks_in_inner_dim);
} else {
  // Shift-based swizzling
  int new_num_chunks = num_chunks_in_inner_dim;
  while (gcd(new_num_chunks, num_chunks_in_128B) != 1) {
    new_num_chunks++;
  }
  // Update strides to reflect padding
  meta.strides[meta.innermost_dim] = 1;
  size_t cur_stride = new_num_chunks * chunk_size_num_elems;
  // ... update other strides
}
```

## 6. Memory Planning

### 6.1 Global Memory (DTensors)

DTensor memory is allocated sequentially with 128-byte alignment:

```cpp
class MemoryPlanner {
  size_t cur_addr = 0;

  size_t allocate(size_t size) {
    size_t addr = cur_addr;
    cur_addr += size;
    cur_addr = round_to_multiple(cur_addr, 128);  // 128B alignment
    return addr;
  }
};
```

Only **intermediate tensors** (not inputs/outputs) are allocated from the buffer.

### 6.2 Shared Memory (STensors)

STensor memory planning is modeled as **Dynamic Storage Allocation (DSA)**:

**Problem:** Given tensors with (size, alloc_time, free_time), minimize peak memory.

**Geometric View:** Pack axis-parallel rectangles (height = size, width = lifetime) without overlap.

### 6.3 Tensor Lifecycles

```cpp
// Pre-loop inputs: allocated at pre_loop time, freed at 2T or post_loop usage
// Loop intermediates: allocated/freed within each iteration
// Accumulators: allocated before loop, freed after post_loop usage
// Post-loop intermediates: allocated/freed within post_loop phase
```

Timeline encoding:
- Pre-loop: time 0 to T
- Loop: time T to 2T
- Post-loop: time 2T to 3T

### 6.4 Allocation Algorithms

Three heuristics are tried; the best result is used:

```cpp
vector<std::shared_ptr<AbstractMemoryPlanner>> planners = {
  std::make_shared<FirstFitMemoryPlanner>(),
  std::make_shared<BestFitMemoryPlanner>(),
  std::make_shared<WorseFitMemoryPlanner>()
};
```

**First-Fit:** Choose the first free block that fits
**Best-Fit:** Choose the smallest free block that fits
**Worse-Fit:** Choose the largest free block that fits

**Code Reference** (`src/transpiler/plan_stensor_memory.cc:184-213`):

```cpp
class FirstFitMemoryPlanner : public OnlineAllocMemoryPlannerBase {
  Range select_range(size_t size) override {
    auto it = std::find_if(free_ranges.begin(), free_ranges.end(),
      [&](Range const &range) {
        return range.second - range.first >= size;
      });
    return {it->first, it->first + size};
  }
};
```

## 7. Code Generation

### 7.1 Kernel-Level Code

For each kernel-level operator, the transpiler generates appropriate code:

**Matmul:** Calls cuBLAS via the runtime
```cpp
exec.e("kn::gemm<$>($,$,$, $,$,$, ...);",
       compute_type, out0_ptr, in0_ptr, in1_ptr, m, n, k, ...);
```

**Elementwise:** Uses CuTe layouts
```cpp
exec.e("using kernel = kn::ElementUnaryKernel<$, "
       "kn::ElementUnaryOpType::$, $, $>;",
       datatype, op_type, in_layout, out_layout);
exec.e("kernel::run($, $);", out_ptr, in_ptr);
```

**Custom Op:** Generates a complete CUDA kernel

### 7.2 Custom Kernel Structure

For `KN_CUSTOMIZED_OP`, a complete kernel is generated:

```cpp
__global__ void custom_kernel_0(half* output, half const* input) {
  int thread_idx = threadIdx.x;
  extern __shared__ char buf[];

  // Define STensor pointers
  half *stensor0_ptr = (half*)(buf + 0);
  half *stensor1_ptr = (half*)(buf + 1024);

  // Pre-loop: Load static inputs
  STensor0InputAtom::run(stensor0_ptr, dtensor_tile_ptr, thread_idx);
  __syncthreads();

  // Main loop
  for (int for_idx = 0; for_idx < FORLOOP_RANGE; for_idx++) {
    // Load inputs for this iteration
    STensor1InputAtom::run(stensor1_ptr, dtensor_tile_ptr + offset*for_idx, thread_idx);
    __syncthreads();

    // Compute
    Matmul0Kernel::run(matmul_accum, stensor0_ptr, stensor1_ptr, thread_idx);
    // ... more operators
  }
  __syncthreads();

  // Post-loop: reductions, outputs
  OutputAtom::run(dtensor_output, stensor_result, thread_idx);
}
```

### 7.3 Epilogue Fusion

Fused operators are implemented as **epilogues**:

```cpp
string transpile_fusion_epilogue(chain, dtype) {
  string res = "tb::EpilogueStore<half>";
  for (op in chain[1:]) {
    if (op->op_type == TB_EXP_OP)
      res = fmt("tb::EpilogueExp<half, $>", res);
    else if (op->op_type == TB_FORLOOP_ACCUM_NO_RED_OP)
      res = "tb::EpilogueStoreAccum<half>";
    // ...
  }
  return res;
}
```

**Example chain `Matmul → Exp → Store`:**
```cpp
using Epilogue = tb::EpilogueExp<half, tb::EpilogueStore<half>>;
```

### 7.4 Architecture-Specific Code

**Hopper (SM90):**
- TMA (Tensor Memory Accelerator) for async copies
- Warp group specialization
- `SM90_TMA_LOAD` copy atoms

**Blackwell (SM100):**
- 2-SM MMA instructions
- Cluster-level synchronization
- TMEM allocation

## 8. Running Example: RMSNorm + Linear

Let's trace through transpiling our running example:

### 8.1 Input Graph

```python
# From c1_architecture
X = graph.new_input([batch, seq, hidden])
W_norm = graph.new_input([hidden])
W_linear = graph.new_input([hidden, output])

# Custom op with threadblock graph:
# 1. Load X tile
# 2. Square X
# 3. Reduce sum
# 4. Sqrt (get RMS)
# 5. Divide X by RMS
# 6. Matmul with W_linear
# 7. Store result
```

### 8.2 Fusion Analysis

```
TB_INPUT (X) → TB_SQUARE → TB_REDUCTION → TB_SQRT → TB_DIV → TB_MATMUL → TB_OUTPUT
     ↑              ↑
Not fusable    Can fuse with TB_INPUT? No (TB_INPUT has forloop_dim)
```

Result: Minimal fusion (individual operators)

### 8.3 Layout Resolution

Z3 constraints:
- Input X: innermost_dim from user (e.g., last dim)
- All matmul operands: innermost in last two dims
- STensors: prefer same innermost as DTensors for wide copy

### 8.4 Scheduling

```
pre_loop_nodes: [TB_INPUT(W_norm)]  # Static weight
loop_nodes: [TB_INPUT(X), TB_SQUARE, TB_REDUCTION, TB_SQRT,
             TB_DIV, TB_MATMUL, TB_FORLOOP_ACCUM]
post_loop_nodes: [TB_OUTPUT]
```

Synchronizations inserted between depth changes.

### 8.5 Generated Code (Simplified)

```cpp
__global__ void custom_kernel_rmsnorm_linear(...) {
  extern __shared__ char buf[];

  // Load weight (pre-loop)
  WNormInputAtom::run(wnorm_ptr, wnorm_tile, thread_idx);
  __syncthreads();

  for (int for_idx = 0; for_idx < K_TILES; for_idx++) {
    // Load X tile
    XInputAtom::run(x_ptr, x_tile + for_idx * TILE_K, thread_idx);
    __syncthreads();

    // RMSNorm computation
    SquareKernel::run(sq_ptr, x_ptr, thread_idx);
    __syncthreads();
    ReductionKernel::run(sum_ptr, sq_ptr, thread_idx);
    __syncthreads();
    SqrtKernel::run(rms_ptr, sum_ptr, thread_idx);
    DivKernel::run(norm_ptr, x_ptr, rms_ptr, thread_idx);
    __syncthreads();

    // Matmul with accumulation
    MatmulKernel::run(accum, norm_ptr, wlinear_ptr, thread_idx);
  }
  __syncthreads();

  // Output
  OutputAtom::run(output_tile, accum, thread_idx);
}
```

## 9. Python Examples

To see the transpiler in action, run the example scripts:

```bash
# Inspect layout resolution
python3 tutorial/c2_transpiler_cuda/layout_resolution_example.py

# Visualize scheduling
python3 tutorial/c2_transpiler_cuda/scheduling_example.py

# See generated code
python3 tutorial/c2_transpiler_cuda/codegen_example.py
```

## 10. Key Takeaways

1. **Fusion** reduces memory traffic but is currently limited to unary operators
2. **Layout resolution** uses Z3 to balance multiple competing objectives
3. **Scheduling** minimizes synchronizations using depth-based topological sort
4. **Swizzling** avoids bank conflicts with XOR or shift-based methods
5. **Memory planning** uses best-of-three heuristics for shared memory
6. **Code generation** leverages CuTe for portable tensor operations

The transpiler is the bridge between Mirage's graph-level optimizations and efficient GPU execution. Understanding these algorithms helps when:
- Adding new operators
- Debugging performance issues
- Extending support for new architectures

> **Next Up:** The next post in this series will cover Mirage's **Persistent Kernel (MPK) Runtime** - the mega-kernel architecture that enables high-performance LLM inference with event-driven scheduling and multi-GPU support.
