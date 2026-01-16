---
layout: post
title: Inside Mirage (3) - Megakernel Persistent Runtime
date: 2025-12-27 00:00:00
description: Deep dive into Mirage's MPK runtime - worker-scheduler model, event-driven synchronization, and multi-GPU support
tags: mirage mlsys gpu cuda
categories: mlsys
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

This post continues our exploration of [Mirage](https://github.com/mirage-project/mirage), diving into the **Megakernel Persistent Kernel (MPK)** runtime that powers high-performance LLM inference. If the [previous post on the transpiler](/blog/2025/mirage-transpiler-cuda/) showed you *what* code gets generated, this post shows you *how* that code executes.

> **Related reading:** Check out my [MPK paper summary](/blog/2025/mirage-mpk-paper/) for the high-level ideas behind this architecture.

---

## 1. The Megakernel Execution Model

Traditional CUDA programming launches separate kernels for each operation. Mirage's megakernel takes a radically different approach: **launch once, run forever**.

```
Traditional Model:
┌────────┐     ┌────────┐     ┌────────┐
│Kernel 1│→CPU→│Kernel 2│→CPU→│Kernel 3│→ ...
└────────┘     └────────┘     └────────┘
   5-10μs latency each launch

Megakernel Model:
┌─────────────────────────────────────────┐
│        Mega-Kernel (Persistent)          │
│   Runs until all tasks complete          │
└─────────────────────────────────────────┘
   Single launch, amortized overhead
```

The megakernel contains all the fused operations from the transpiler, plus a scheduling runtime that manages their execution.

---

## 2. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           Host (Python API)                             │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────────────┐    │
│  │ Kernel Graph   │  │ Threadblock    │  │ Task Graph Compiler    │    │
│  │ (KGraph)       │──│ Graph (TBGraph)│──│ Fusion & Scheduling    │    │
│  └────────────────┘  └────────────────┘  └────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼ Launch once
┌─────────────────────────────────────────────────────────────────────────┐
│                         GPU Megakernel                                  │
│                                                                         │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐    ┌───────────────────┐   │
│  │ Worker 0  │ │ Worker 1  │ │ Worker 2  │    │ Scheduler SMs     │   │
│  │    SM     │ │    SM     │ │    SM     │    │ ┌─────┐ ┌─────┐  │   │
│  │  ┌─────┐  │ │  ┌─────┐  │ │  ┌─────┐  │◄───│ │Sch0 │ │Sch1 │  │   │
│  │  │Task │  │ │  │Task │  │ │  │Task │  │    │ └──┬──┘ └──┬──┘  │   │
│  │  │Queue│  │ │  │Queue│  │ │  │Queue│  │    │    │       │     │   │
│  │  └─────┘  │ │  └─────┘  │ │  └─────┘  │    │  Event    Event  │   │
│  └───────────┘ └───────────┘ └───────────┘    │  Queues   Queues │   │
│       │              │              │         └───────────────────┘   │
│       └──────────────┴──────────────┴──────────────────┘              │
│                     Event Counter Array                                │
└─────────────────────────────────────────────────────────────────────────┘
```

The GPU is partitioned into:
- **Workers**: Most SMs, executing tensor operations
- **Schedulers**: A few SMs dedicated to task distribution

This separation keeps the workers focused on compute while schedulers handle coordination.

---

## 3. Grid Layout and Role Assignment

The kernel grid is organized to separate workers from schedulers:

**File**: `mirage/include/mirage/persistent_kernel/persistent_kernel.cuh:440-456`

```cpp
__device__ __forceinline__ void persistent_checker(RuntimeConfig config) {
  int const num_schedulers =
      config.num_local_schedulers + config.num_remote_schedulers;
  int const num_schedulers_per_sm = std::min((int)blockDim.x / 32, 4);

  // Grid layout: [workers | schedulers]
  assert(gridDim.x ==
         config.num_workers + num_schedulers / num_schedulers_per_sm);
}
```

```
gridDim.x = num_worker_blocks + num_scheduler_blocks

Block Types:
[0, num_workers-1]              : Worker blocks (1 worker per SM)
[num_workers, gridDim.x-1]      : Scheduler blocks (up to 4 schedulers per SM)
```

Each scheduler runs in a single warp (32 threads), allowing up to 4 schedulers per SM to maximize scheduler throughput without wasting too many SMs.

---

## 4. Worker Main Loop

Workers are the computational workhorses. Here's the execution flow:

**File**: `mirage/include/mirage/persistent_kernel/persistent_kernel.cuh:458-582`

```cpp
__device__ __forceinline__ void execute_worker(RuntimeConfig config) {
  // Task buffering in shared memory
  constexpr int TASK_DESCS_BUFFER_LENGTH = 16;
  __shared__ TaskDesc task_descs[TASK_DESCS_BUFFER_LENGTH];
  __shared__ TaskId task_ids[TASK_DESCS_BUFFER_LENGTH];
  __shared__ TaskId *worker_queues[2];  // Local + remote queue

  int const worker_id = blockIdx.x;

  while (true) {
    // PHASE 1: Fetch tasks from queue (batch load up to 16)
    if (queue_pos == queue_len) {
      // Round-robin poll across local and remote queues
      // Use cp.async for efficient task descriptor loading
      ...
    }

    // PHASE 2: Wait for dependencies (event counters)
    TaskDesc *task_desc = task_descs + queue_pos;
    for (int i = 0; i < task_desc->num_wait_local_events; i++) {
      // Spin-wait with acquire semantics
      while (atomicAdd(&counters[event_idx], 0) < threshold) {}
      __threadfence();
    }

    // PHASE 3: Execute task
    if (task_desc->task_type == TASK_TERMINATE) {
      return;
    }
    _execute_task(task_desc, config);

    // PHASE 4: Trigger downstream events
    for (int i = 0; i < task_desc->num_trigger_local_events; i++) {
      atom_add_release_gpu_u64(&counters[event_idx], delta);
    }

    queue_pos += 1;
  }
}
```

### Key Design Points

**Batch task loading**: Workers fetch up to 16 tasks at once using `cp.async`, hiding memory latency by overlapping descriptor fetches with computation.

**Double-buffered queues**: Each worker polls two queues (local and remote) to support multi-GPU task dispatch. The round-robin polling prevents starvation.

**Event-driven synchronization**: Instead of global barriers, tasks wait on specific event counters and trigger events on completion. This enables fine-grained parallelism.

---

## 5. Scheduler Main Loop

Schedulers manage the work distribution. They're more complex than workers because they handle multiple event types and coordinate task launches.

**File**: `mirage/include/mirage/persistent_kernel/persistent_kernel.cuh:737-981`

```cpp
__device__ __forceinline__ void execute_scheduler(RuntimeConfig config, int offset) {
  int const num_schedulers =
      config.num_local_schedulers + config.num_remote_schedulers;
  int const num_schedulers_per_sm = std::min((int)blockDim.x / 32, 4);
  int const warp_id = threadIdx.x / 32;

  // Only first 4 warps run schedulers (one scheduler per warp)
  if (threadIdx.x % 32 == 0 && warp_id < num_schedulers_per_sm) {
    int const sched_id = blockIdx.x * num_schedulers_per_sm + warp_id + offset;

    // Each scheduler manages a subset of workers
    EventId *sched_queues[2];       // Local + global queue
    int sched_queue_ids[2];
    unsigned long long int my_first_worker, my_last_worker;

    // Local schedulers also process events from the global queue
    sched_queues[0] = config.sched_queues[sched_id];
    sched_queue_ids[0] = sched_id;
    if (sched_id < config.num_local_schedulers) {
      sched_queues[1] = config.sched_queues[num_schedulers];  // Global queue
      sched_queue_ids[1] = num_schedulers;
      get_first_last_ids(config.num_workers, config.num_local_schedulers,
                         sched_id, &my_first_worker, &my_last_worker);
    }

    size_t cur_event_pos[2] = {0, 0};
    size_t last_event_pos[2] = {0, 0};
    size_t worker_queue_next_free_task_pos[MAX_WORKER_PER_SCHEDULER];
    int next_worker = my_first_worker;
    int queue_idx = 0;
    size_t iteration_num = 0;

    while (true) {
      // PHASE 1: Poll event queues (round-robin across local and global)
      while (cur_event_pos[queue_idx] == last_event_pos[queue_idx]) {
        last_event_pos[queue_idx] = ld_acquire_gpu_u64(
            &config.sched_queue_last_ready_event_id[sched_queue_ids[queue_idx]]);
        if (cur_event_pos[queue_idx] < last_event_pos[queue_idx]) {
          break;
        }
        queue_idx = (queue_idx == num_sched_queues - 1) ? 0 : queue_idx + 1;
        __nanosleep(10);  // Avoid overwhelming I/O
      }

      // PHASE 2: Process event
      EventId event_id = ld_relaxed_gpu_u64(
          &sched_queues[queue_idx][cur_event_pos[queue_idx] % config.per_sched_queue_len]);
      EventDesc e = config.all_events[event_id];

      // Handle termination
      if (is_termination_event(event_id, e)) {
        for (int i = my_first_worker; i < my_last_worker; i++) {
          // Send TASK_TERMINATE to all workers
          size_t last_task_id = worker_queue_next_free_task_pos[i - my_first_worker]++;
          st_relaxed_gpu_u64(&config.worker_queues[i][last_task_id % config.per_worker_queue_len], 0);
          atom_add_release_gpu_u64(&config.worker_queue_last_ready_task_id[i], 1);
        }
        return;
      }

      // Handle end-of-task-graph (batch boundary for LLM inference)
      if (e.event_type == EVENT_END_OF_TASK_GRAPH) {
        if (!prepare_next_batch(config)) {
          terminate_schedulers(config);
        } else {
          // Launch begin_task_graph for next iteration
          size_t last_task_id = worker_queue_next_free_task_pos[next_worker - my_first_worker]++;
          st_relaxed_gpu_u64(
              &config.worker_queues[next_worker][last_task_id % config.per_worker_queue_len],
              compute_task_id(iteration_num + 1, 1 /*begin_task_graph*/));
          atom_add_release_gpu_u64(&config.worker_queue_last_ready_task_id[next_worker], 1);
          next_worker = (next_worker == my_last_worker - 1) ? my_first_worker : next_worker + 1;
        }
      }
      // Handle massive task launches (split across all local schedulers)
      else if (e.event_type == EVENT_LAUNCH_MASSIVE_TASKS) {
        // Each scheduler gets a portion of tasks
        TaskId my_first_task, my_last_task;
        get_first_last_ids(e.last_task_id - e.first_task_id,
                           config.num_local_schedulers, sched_id,
                           &my_first_task, &my_last_task);
        my_first_task += e.first_task_id;
        my_last_task += e.first_task_id;

        // Round-robin distribute tasks to workers
        for (size_t i = my_first_task; i < my_last_task; i++) {
          size_t last_task_id = worker_queue_next_free_task_pos[next_worker - my_first_worker]++;
          st_relaxed_gpu_u64(
              &config.worker_queues[next_worker][last_task_id % config.per_worker_queue_len],
              compute_task_id(iteration_num, i));
          atom_add_release_gpu_u64(&config.worker_queue_last_ready_task_id[next_worker], 1);
          next_worker = (next_worker == my_last_worker - 1) ? my_first_worker : next_worker + 1;
        }
      }

      cur_event_pos[queue_idx] += 1;
    }
  }
}
```

### Scheduler Execution Flow

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                    Scheduler Main Loop                                  │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  1. Poll Event Queues (round-robin local + global)              │   │
│  │     └─ ld_acquire_gpu_u64(&sched_queue_last_ready_event_id)     │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                               │                                         │
│                               ▼                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  2. Fetch Event from Queue                                      │   │
│  │     └─ ld_relaxed_gpu_u64(&sched_queues[queue_idx][pos])        │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                               │                                         │
│                               ▼                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  3. Process Event by Type                                       │   │
│  │                                                                 │   │
│  │     EVENT_TERMINATE                                             │   │
│  │       └─ Send TASK_TERMINATE to all workers → return            │   │
│  │                                                                 │   │
│  │     EVENT_END_OF_TASK_GRAPH                                     │   │
│  │       └─ prepare_next_batch() → launch begin_task_graph         │   │
│  │                                                                 │   │
│  │     EVENT_LAUNCH_MASSIVE_TASKS                                  │   │
│  │       └─ Split tasks across schedulers → round-robin to workers │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                               │                                         │
│                               ▼                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  4. Dispatch Tasks to Workers (round-robin)                     │   │
│  │     ├─ st_relaxed_gpu_u64(&worker_queues[worker_id][pos], task) │   │
│  │     └─ atom_add_release_gpu_u64(&last_ready_task_id[w], 1)      │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### Event Types

| Event Type | Purpose |
|------------|---------|
| `EVENT_TERMINATE` | Signal all workers to exit |
| `EVENT_END_OF_TASK_GRAPH` | Batch boundary - prepare next iteration |
| `EVENT_LAUNCH_MASSIVE_TASKS` | Bulk task dispatch across workers |
| `EVENT_LAUNCH_DEPENDENT_TASKS` | Tasks depending on previous iteration |

---

## 6. Event-Driven Synchronization

The event system is the heart of MPK's coordination mechanism.

### Event Counter Model

**File**: `mirage/include/mirage/persistent_kernel/persistent_kernel.cuh:157-159`

```cpp
// Initialize all event counters to zero
for (int i = threadIdx.x; i < config.num_events; i += blockDim.x) {
  all_event_counters[i] = 0;
}
__syncthreads();
```

### Event Triggering

**File**: `mirage/include/mirage/persistent_kernel/persistent_kernel.cuh:397-410`

```cpp
// After task completion, trigger dependent events
for (int i = 0; i < task_desc->num_trigger_local_events; i++) {
  EventDesc event_desc = task_desc->trigger_local_events[i];
  uint64_t *event_counter_ptr = &all_event_counters[event_desc.event_idx];

  // Release semantics: ensure tile data visible before counter increment
  atom_add_release_gpu_u64(event_counter_ptr, (uint64_t)event_desc.trigger_delta);
}
```

### Event ID Encoding

```cpp
// 64-bit EventId: nvshmem_tag(16) | owner_gpu(16) | event_idx(32)
EVENT_NVSHMEM_TAG = 0x1e00000000000000;

__device__ bool is_nvshmem_event(EventId id) {
    return (id & EVENT_NVSHMEM_TAG) > 0;
}
```

The encoding allows distinguishing local events from cross-GPU NVSHMEM events, enabling efficient routing.

---

## 7. Cross-GPU Communication

For multi-GPU inference, MPK leverages **NVSHMEM symmetric heap** for zero-copy communication.

### Architecture

```
GPU 0                                         GPU 1
┌───────────────────────────────────────┐    ┌───────────────────────────────────────┐
│  Workers                              │    │  Workers                              │
│  ┌─────────────────────────────────┐  │    │  ┌─────────────────────────────────┐  │
│  │ Worker 0                        │  │    │  │ Worker 0                        │  │
│  │  - Local Queue [0]              │  │    │  │  - Local Queue [0]              │  │
│  │  - Remote Queue [num_workers]   │  │    │  │  - Remote Queue [num_workers]   │  │
│  └─────────────────────────────────┘  │    │  └─────────────────────────────────┘  │
│                                       │    │                                       │
│  TASK_NVSHMEM_COPY transfers data ────┼────┼──► Data + signal arrive together     │
│  via nvshmem_putmem_signal()          │    │                                       │
└───────────────────────────────────────┘    └───────────────────────────────────────┘
                    │                                        │
                    └────────────────┬───────────────────────┘
                                     │
                           NVSHMEM Symmetric Heap
              (queues, event counters, data - same address on all GPUs)
```

### Symmetric Heap Allocation

**File**: `persistent_kernel.cuh:1005-1012`

```cpp
template <typename DT>
DT *gpu_malloc(size_t size) {
#ifdef USE_NVSHMEM
  dst_ptr = nvshmem_malloc(size);  // Symmetric heap - same address on all GPUs
#else
  cudaMalloc(&dst_ptr, size);
#endif
  return static_cast<DT *>(dst_ptr);
}
```

### Cross-GPU Data Transfer

The `TASK_NVSHMEM_COPY` task uses `nvshmem_putmem_signal` to **atomically** transfer data AND signal completion:

```cpp
// TASK_NVSHMEM_COPY internally does:
nvshmem_putmem_signal(
    remote_data_ptr,           // Destination on remote GPU (symmetric address)
    local_data_ptr,            // Source on local GPU
    size_in_bytes,
    &remote_event_counter,     // Signal location on remote GPU
    signal_value,              // Value to add
    NVSHMEM_SIGNAL_ADD,
    target_pe                  // Target GPU rank
);
// This atomically: (1) copies data, (2) signals remote event counter
```

### NVSHMEM Event Waiting

**File**: `persistent_kernel.cuh:596-610`

```cpp
#ifdef MIRAGE_USE_NVSHMEM
// Wait for remote tile data
nvshmem_signal_wait_until(
    &all_event_counters[event_desc.event_idx],
    NVSHMEM_CMP_GE,
    (uint64_t)event_desc.wait_threshold);
#endif
```

### Cross-GPU Communication Flow

```
GPU 0 Worker                          GPU 1 Worker
     │                                      │
     │ Execute TASK_NVSHMEM_COPY            │ Waiting on nvshmem_signal_wait_until()
     │     │                                │         │
     │     ├─► nvshmem_putmem_signal() ─────┼────────►│
     │     │   (data + signal atomically)   │         │
     │     │                                │    Event counter incremented
     │                                      │         │
     │                                      │    ◄────┘ Wait satisfied
     │                                      │
     │                                      │ Execute dependent task
```

---

## 8. Task Implementation

Megakernel tasks are **hand-written CUDA templates**, not generated code. The transpiler only extracts shape parameters to instantiate these templates.

```
Two Separate Systems in Mirage:

┌─────────────────────────────────────────────────────────────────────────┐
│  TBGraph / STensor (Transpiler Path)                                    │
│  - Used for STANDALONE kernel code generation                           │
│  - NOT used by megakernel runtime                                       │
└─────────────────────────────────────────────────────────────────────────┘
                              │
                              │ Extract shapes only
                              ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  Megakernel Tasks (Runtime Path)                                        │
│  - Hand-written CUDA templates in tasks/ampere/*.cuh, tasks/hopper/*.cuh│
│  - TaskRegister instantiates templates with extracted dimensions        │
│  - Executed by worker SMs at runtime                                    │
└─────────────────────────────────────────────────────────────────────────┘
```

### Example: Linear Layer

**File**: `mirage/include/mirage/persistent_kernel/tasks/ampere/linear.cuh`

```cpp
// Hand-written CUDA template - NOT generated code
template <typename T,
          int BATCH_SIZE,
          int OUTPUT_SIZE,
          int REDUCTION_SIZE,
          int O_STRIDE = OUTPUT_SIZE,
          int PIPE_MAX = 3>
__device__ __forceinline__ void linear_kernel(void const *input_ptr,
                                              void const *weight_ptr,
                                              void const *residual_ptr,
                                              void *output_ptr,
                                              int num_active_tokens,
                                              bool residual) {
  // Manual tiling, shared memory management, MMA operations
  constexpr int TILE_SIZE = 128;
  constexpr int FORLOOP_RANGE = REDUCTION_SIZE / TILE_SIZE;
  // ... hundreds of lines of hand-optimized CUDA
}
```

### TaskRegister: Template Instantiation

**File**: `mirage/src/kernel/task_register.cc`

```cpp
int TaskRegister::register_rmsnorm_task(threadblock::Graph const &bgraph,
                                        std::vector<int> const &params) {
  // Extract dimensions from TBGraph (used as specification)
  int batch_size = output_ops[0]->output_tensors[0].dim[0];
  int hidden_dim = output_ops[0]->output_tensors[0].dim[1];

  // Generate function CALL to hand-written template (NOT generated code)
  mirage::transpiler::CodeKeeper code;
  code.e("kernel::rms_norm_impl<bfloat16, $, $>(", batch_size, hidden_dim);
  code.e("    task_desc->input_ptrs[0],");
  code.e("    task_desc->input_ptrs[1],");
  code.e("    task_desc->output_ptrs[0],");
  code.e("    1e-6f);");
  return register_task_variant(TASK_RMS_NORM, code.to_string());
}
```

### Available Task Types

| Task Type | Implementation File |
|-----------|---------------------|
| `TASK_LINEAR` | `tasks/ampere/linear.cuh` |
| `TASK_RMS_NORM` | `tasks/ampere/rmsnorm.cuh` |
| `TASK_SILU_MUL` | `tasks/ampere/silu_mul.cuh` |
| `TASK_PAGED_ATTENTION_*` | `tasks/ampere/multitoken_paged_attention*.cuh` |
| `TASK_LINEAR_HOPPER` | `tasks/hopper/linear_hopper.cuh` |
| `TASK_NVSHMEM_COPY` | Cross-GPU data transfer |

### Architecture-Specific Implementations

```
persistent_kernel/tasks/
├── ampere/      # SM80: CP.ASYNC-based loading
├── hopper/      # SM90: TMA-based loading
└── blackwell/   # SM100: New tensor core operations
```

---

## 9. Worker-Scheduler Communication

The communication flow between workers and schedulers forms a closed loop:

```
┌─────────────────────────────────────────────────────────────────────────┐
│               Worker-Scheduler Communication Architecture               │
│                                                                         │
│  Schedulers                              Workers                        │
│  ┌────────────┐                         ┌────────────┐                 │
│  │ Scheduler 0│──────────────────────────│ Worker 0  │                 │
│  │            │                    ┌────│ Worker 1  │                 │
│  └────────────┘                    │    │ Worker 2  │                 │
│                                    │    └────────────┘                 │
│  ┌────────────┐                    │                                   │
│  │ Scheduler 1│────────────────────┼────│ Worker 3  │                 │
│  │            │              ┌─────┼────│ Worker 4  │                 │
│  └────────────┘              │     │    │ Worker 5  │                 │
│                              │     │    └────────────┘                 │
│         ▲                    │     │          │                        │
│         │                    │     │          │                        │
│    Event Queues         Worker Queues   Event Counters                 │
│   (sched_queues)       (worker_queues)  (all_event_counters)           │
│                              │     │          │                        │
│         │                    │     │          ▼                        │
│    ┌────┴────┐          ┌────┴─────┴────┐                              │
│    │ Workers │          │  Schedulers   │                              │
│    │ trigger │──────────│  dispatch     │                              │
│    │ events  │          │  tasks        │                              │
│    └─────────┘          └───────────────┘                              │
└─────────────────────────────────────────────────────────────────────────┘

Communication Flow:
1. Worker completes task → increments event counter
2. Event counter reaches threshold → event placed in scheduler queue
3. Scheduler processes event → creates TaskId(iteration, task_idx)
4. Scheduler places task in worker queue → worker fetches and executes
```

---

## 10. Performance Characteristics

| Aspect | Traditional Kernels | MPK Runtime |
|--------|---------------------|-------------|
| Kernel launch overhead | 5-10μs per kernel | Amortized (single launch) |
| Inter-layer pipelining | Not possible | Enabled |
| Compute/Comm overlap | Manual | Automatic via events |
| GPU utilization | Variable (gaps) | High (continuous) |
| Scheduling | Host-side | Device-side |

The MPK runtime shines in scenarios with:
- **Small batch sizes**: Launch overhead dominates traditional approaches
- **Multi-GPU setups**: NVSHMEM overlap maximizes bandwidth utilization
- **Deep models**: More layers = more opportunities for pipelining

---

## 11. Key Takeaways

1. **Persistent execution** eliminates kernel launch overhead by keeping one kernel running
2. **Worker-scheduler separation** allows dedicated coordination without impacting compute
3. **Event counters** provide lock-free, fine-grained synchronization
4. **NVSHMEM integration** enables efficient cross-GPU communication with atomic signals
5. **Hand-written task templates** ensure peak performance for critical operations
6. **Architecture-specific paths** leverage SM-specific features (TMA, etc.)

The MPK runtime is a fascinating example of bringing operating system concepts (cooperative scheduling, event-driven I/O) into GPU programming. It shows that the traditional host-device model isn't the only way to program GPUs - sometimes the GPU can be its own scheduler.

---

## References

- [Mirage GitHub Repository](https://github.com/mirage-project/mirage)
- [MPK Paper (arXiv:2512.22219)](https://arxiv.org/abs/2512.22219)
- [NVSHMEM Documentation](https://docs.nvidia.com/nvshmem/)
- [CuTe Documentation](https://github.com/NVIDIA/cutlass/blob/main/media/docs/cute/00_quickstart.md)

> **Previous:** [Inside Mirage (2) - Transpiler from MuGraph to CUDA](/blog/2025/mirage-transpiler-cuda/)
