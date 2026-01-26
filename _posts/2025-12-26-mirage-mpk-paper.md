---
layout: post
title: Paper Reading - Mirage Persistent Kernel (MPK)
date: 2025-12-26 00:00:00
description: Notes on the Mirage MPK paper - a compiler and runtime for mega-kernelizing tensor programs
tags: paper-reading mlsys gpu cuda
categories: paper-reading
tabs: true
thumbnail:
mermaid:
  enabled: true
  zoomable: true
toc:
  beginning: true
pretty_table: true
tikzjax: true
pseudocode: true
---

This post summarizes the key ideas from [**Mirage Persistent Kernel: A Compiler and Runtime for Mega-Kernelizing Tensor Programs**](https://arxiv.org/abs/2512.22219) (arXiv:2512.22219). If you're interested in how modern LLM inference can push GPU utilization to the limit, this paper offers some genuinely clever solutions.

---

## The Problem: Death by a Thousand Kernel Launches

Modern deep learning workloads, especially LLM inference, involve a parade of small tensor operations: layer norms, projections, attention, MLPs. Each operation typically launches a separate CUDA kernel. The result?

- **Kernel launch overhead**: Each launch costs 5-10 microseconds. That adds up fast.
- **Memory bandwidth waste**: Data gets written to global memory, then read back for the next operation.
- **GPU sitting idle**: Between kernel launches, the GPU twiddles its thumbs waiting for the host.
- **No cross-layer optimization**: Each kernel is optimized in isolation.

The standard solution of "fuse more operations" has limits. At some point, you need a fundamentally different execution model.

## The MPK Solution: One Kernel to Rule Them All

**Mirage Persistent Kernel (MPK)** takes the fusion idea to its logical extreme: fuse the *entire inference* into a single, persistent mega-kernel that stays resident on the GPU.

```text
Traditional:  [Kernel 1] -> CPU -> [Kernel 2] -> CPU -> [Kernel 3] -> ...
MPK:          [=================== Mega-Kernel ===================]
                              ^ runs until done
```

The key insight is that kernel launch overhead isn't inherent to GPU computation - it's an artifact of the host-device programming model. By keeping the kernel alive and scheduling work *on the GPU*, MPK sidesteps this bottleneck entirely.

---

## System Architecture

MPK introduces a **worker-scheduler model** that lives entirely on the GPU:

```text
+--------------------------------------------------------------+
|                  Mega-Kernel (Persistent)                    |
|  +--------------------------------------------------------+  |
|  |                  Schedulers                            |  |
|  |   (Dedicated warps that manage work distribution)      |  |
|  +------------------------+-------------------------------+  |
|                           |                                  |
|                           v                                  |
|  +--------------------------------------------------------+  |
|  |                  Task Queue                            |  |
|  |   [Task 0] [Task 1] [Task 2] [Task 3] ...              |  |
|  +------------------------+-------------------------------+  |
|                           |                                  |
|                           v                                  |
|  +--------------------------------------------------------+  |
|  |                   Workers                              |  |
|  |  [SM 0] [SM 1] [SM 2] ... (execute actual compute)     |  |
|  +--------------------------------------------------------+  |
+--------------------------------------------------------------+
```

### Workers and Schedulers

**Workers** (most SMs) execute the actual tensor computations. Each worker:
1. Polls the task queue for ready work
2. Executes the task (a fused operation from Mirage's transpiler)
3. Signals completion via event counters
4. Repeats until termination

**Schedulers** (a few dedicated warps) manage task distribution:
1. Monitor event queues for completed dependencies
2. Distribute newly-ready tasks to workers in round-robin fashion
3. Handle cross-layer and cross-iteration boundaries
4. Coordinate multi-GPU communication

This separation keeps the workers focused on compute while schedulers handle the coordination overhead.

### Event-Driven Synchronization

Instead of expensive `__syncthreads()` or atomic barriers, MPK uses **event counters** for fine-grained synchronization:

```cpp
// Worker completion: increment counter with release semantics
atom_add_release_gpu_u64(&event_counters[event_id], delta);

// Dependency wait: spin until counter reaches threshold
while (atomicAdd(&event_counters[dep_event], 0) < threshold) {
    __nanosleep(10);
}
__threadfence();  // Acquire semantics
```

This enables:
- **Lock-free** task queue operations
- **Fine-grained** inter-task dependencies
- **Minimal overhead** compared to traditional synchronization

---

## Key Technical Contributions

### 1. Task Graph Compilation

Rather than CUDA graphs (kernel granularity), MPK compiles at **sub-kernel granularity**. Each task in the task graph represents a fused operation from Mirage's transpiler:

| Traditional CUDA Graph | MPK Task Graph |
|------------------------|----------------|
| Kernel launch = 1 node | Fused op = 1 task |
| Host-side scheduling | Device-side scheduling |
| Static dependencies | Dynamic event-driven |

### 2. Inter-Layer Pipelining

With device-side scheduling, MPK enables **inter-layer pipelining**:

```text
Time ->
Token 0: [RMSNorm][Attn][FFN]
Token 1:    [RMSNorm][Attn][FFN]
Token 2:       [RMSNorm][Attn][FFN]
         +-- GPU continuously utilized --+
```

Different tokens flow through different layers simultaneously, maximizing SM utilization.

### 3. Computation/Communication Overlap

For multi-GPU inference, MPK overlaps compute with NVSHMEM-based communication:

```cpp
// Data transfer task uses nvshmem_putmem_signal
nvshmem_putmem_signal(
    remote_ptr,        // Destination on peer GPU
    local_ptr,         // Source data
    size,              // Bytes to transfer
    &remote_event,     // Signal on completion
    signal_value,
    NVSHMEM_SIGNAL_ADD,
    target_pe          // Peer GPU rank
);
```

The `putmem_signal` atomically transfers data AND signals the remote GPU, enabling tight overlap.

### 4. Double-Buffered Task Queues

Workers poll from two queues (local + remote) to support cross-GPU task dispatch:

```cpp
worker_queues[0] = local_queue[worker_id];
if (num_gpus > 1) {
    worker_queues[1] = remote_queue[worker_id];
}
// Round-robin poll both queues
```

---

## Performance Results

The paper reports impressive gains over traditional approaches:

| Metric | Improvement |
|--------|-------------|
| Kernel launch overhead | ~95% reduction |
| Memory bandwidth | 40-60% reduction |
| End-to-end speedup | 1.2-2.0x (model dependent) |

The gains are most pronounced for:
- **Small batch sizes**: Launch overhead dominates
- **Multi-GPU setups**: Communication/compute overlap pays off
- **Deep models**: More layers = more fusion opportunities

---

## Comparison with Alternatives

| Approach | Scheduling | Fusion | Multi-GPU |
|----------|------------|--------|-----------|
| **MPK** | Device-side, event-driven | Automatic (mega-kernel) | NVSHMEM events |
| CUDA Graphs | Host-side, static | None | Manual |
| Triton | Host-side | Manual | Manual |
| FlashAttention | N/A | Single-op | N/A |

MPK's key differentiation is the **fully on-device execution model** that eliminates host-GPU round trips during inference.

---

## Limitations and Future Directions

**Current limitations:**
- Fusion effectiveness varies by operation mix
- Control flow within fused kernels is limited
- Tested up to 4 GPUs (scaling to 8+ is future work)
- Compile-time task graph (no dynamic shapes)

**Interesting future directions:**
- Adaptive fusion based on runtime profiling
- Support for more complex control flow
- Integration with continuous batching for variable-length sequences

---

## My Take

MPK represents a significant step toward treating the GPU as a **truly autonomous compute device** rather than a host-controlled accelerator. The worker-scheduler model is elegant - it's essentially implementing a cooperative multitasking runtime inside a single CUDA kernel.

The event-driven synchronization using atomic counters is particularly clever. It achieves the semantics of condition variables without the overhead, leveraging the fact that GPU memory accesses have predictable latency.

For practitioners, the key takeaway is: **kernel launch overhead matters more than you think**, especially as models get faster and batches get smaller. MPK shows one path toward eliminating this overhead entirely.

---

## References

- [Paper on arXiv](https://arxiv.org/abs/2512.22219)
- [Mirage GitHub Repository](https://github.com/mirage-project/mirage)
- [NVSHMEM Documentation](https://docs.nvidia.com/nvshmem/)

> **Next:** For a deep dive into Mirage's code and implementation details, check out my [Inside Mirage series](/blog/tag/mirage/).
