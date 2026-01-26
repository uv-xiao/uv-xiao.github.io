---
layout: page
title: APS/Aquas
description: Holistic MLIR-based ASIP hardware-software co-design framework
img:
importance: 2
category: research
github: https://github.com/pku-liang/APS
related_papers:
  - zou2025aquasenhancingdomainspecialization
  - xiao2025aps
  - peng2025clay
---

**Aquas** is a holistic MLIR-based framework for automated ASIP (Application-Specific Instruction-Set Processor) hardware-software co-design. It enhances synthesis with burst-capable DMA and HLS optimizations, and introduces an e-graph-based retargetable compiler for automatic ISAX adoption.

```text
+------------------------------------------------------------------+
|                      Aquas Framework (MLIR)                      |
+------------------------------------------------------------------+
|                                                                  |
|  CADL                              C (App)                       |
|    |                                  |                          |
|    v                                  v                          |
|  +---------------------+    +--------------------------------+   |
|  | Hardware Synthesizer|    |   Retargetable Compiler        |   |
|  | +-----------------+ |    |  +----------+   +----------+   |   |
|  | | aquas dialect   | |    |  |   MLIR   |<->|  e-graph |   |   |
|  | | + affine/scf    | |    |  +-----+----+   +-----+----+   |   |
|  | +--------+--------+ |    |        |              |        |   |
|  |          | optimize |    |   Internal      External       |   |
|  |          v          |    |   Rewrites      Rewrites       |   |
|  | +-----------------+ |    |        |              |        |   |
|  | | HECTOR (tor)    | |    |        +------+-------+        |   |
|  | | + scheduling    | |    |               v                |   |
|  | +--------+--------+ |    |  +------------------------+    |   |
|  |          |          |    |  | Skeleton-Component     |    |   |
|  |          v          |    |  | Pattern Matching       |    |   |
|  | +-----------------+ |    |  +-----------+------------+    |   |
|  | | RTL (CIRCT)     | |    |              v                 |   |
|  | +-----------------+ |    |        LLVM IR -> Binary       |   |
|  +---------------------+    +--------------------------------+   |
|             |                             |                      |
|             v                             v                      |
|  +--------------------------------------------------------+     |
|  |             Rocket/BOOM Core + RoCC Adapter            |     |
|  |  +--------+  +----------------+  +------------------+  |     |
|  |  | L1I/D$ |  |Burst DMA Engine|  |Banked Scratchpad |  |     |
|  |  +--------+  | (TileLink-UH)  |  | (partition-aware)|  |     |
|  |              +----------------+  +------------------+  |     |
|  +--------------------------------------------------------+     |
+------------------------------------------------------------------+
```

## CADL with Optimization Directives

Aquas extends CADL with blockwise memory access and synthesis directives:

```rust
#[partition_array([0],[4],"C")]      // Cyclic partition into 4 banks
static mat: [i32; 16];
#[partition_array([0],[4],"C")]
static vec: [i32; 4];

rtype gemv(rs1: u5, rs2: u5, rd: u5) {
    let ia: u32 = _irf[rs1];
    let oa: u32 = _irf[rs2];
    mat[0+:] = _blockld[ia +:16];    // Burst load 16 elements
    vec[0+:] = _blockld[ia+64 +:4];  // Burst load 4 elements
    with i: u32 = (0, i+1) do {
        acc = 0;
        #[unroll(4)]                  // Full unroll inner loop
        with j: u32 = (0, j_) do {
            acc += mat[i*4+j] * vec[j];
        } while (j_ < 4);
        res[i] = acc;
    } while (i + 1 < 4);
    _irf[rd] = 0;
}
```

## Fast Memory Access via DMA

Aquas synthesizes a burst-capable DMA engine to overcome memory bottlenecks:

| Access Method | Latency | Throughput | Use Case |
|---------------|---------|------------|----------|
| **RoCC port** (single-shot) | 2-3 cycles/elem | Low | Small transfers |
| **Burst DMA** (TileLink-UH) | 15 cycles init | 1 elem/cycle sustained | Large blocks |

**Implementation selection** via ILP optimization:
```
min  Σ t_bur(b)·x_bur,b + t_ss·x_ss
s.t. Σ b·x_bur,b + d_ss·x_ss ≥ D
```

**Partition-aware access**: DMA distributes each 64-bit word across multiple banks in one cycle.

## E-Graph-Based Retargetable Compiler

### Bidirectional MLIR ↔ E-graph Translation

- **MLIR → e-graph**: Operations become e-nodes; blocks become `tuple(...)` of roots
- **E-graph → MLIR**: Witness extraction reconstructs SSA form

### Hybrid Rewriting

| Rewrite Type | Mechanism | Purpose |
|--------------|-----------|---------|
| **Internal** | Egglog fixpoint reasoning | Dataflow equivalences (e.g., `x<<2 ⇝ x*4`) |
| **External** | MLIR passes via e-graph | Control-flow transforms (tiling, unrolling) |

### Skeleton-Component Pattern Matching

ISAXs are decomposed into:
- **Skeleton**: Control structure (loop nesting, trip counts)
- **Components**: Dataflow patterns rooted at side-effect nodes

```
ISAX gemv:
  Skeleton: for i { for j*2 { ... } }
  Components: [yield(acc1,acc2), store(c_ptr)]
```

Matching engine: tag components via Egglog rules → skeleton matcher validates structure → emit ISAX node.

## Hardware Synthesis Flow

```text
CADL --> Pre-Opt MLIR --> Optimize --> Schedule --> FIRRTL --> Verilog
              |              |            |
              |   (affine    |  (modulo   +--> CIRCT
              |    raises)   |   sched)
              |              |
              +-- aquas dialect ops: readrf, writerf, blockload, memstore
```

**Dynamic pipeline elaboration**: Each stage is a transaction with valid-ready handshakes. Loops decompose into entry/body/next transactions.

## Links

- [Project Website](https://aps.ericlyun.me) with tutorials and documentation
- [GitHub](https://github.com/pku-liang/APS)
- Built on [MLIR](https://mlir.llvm.org/), [CIRCT](https://circt.llvm.org/), and [HECTOR](https://github.com/pku-liang/Hector)
