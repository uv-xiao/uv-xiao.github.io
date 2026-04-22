---
layout: post
title: "(Paper Reading) Event Tensor: A Unified Abstraction for Compiling Dynamic Megakernel"
date: 2026-04-21 00:00:00
description: Detailed notes on Event Tensor, a compiler abstraction for dynamic GPU megakernels with symbolic-shape and data-dependent task dependencies.
tags: paper-reading mlsys gpu compiler megakernel llm-inference
categories: paper-reading
tabs: true
thumbnail:
mermaid:
  enabled: true
  zoomable: true
toc:
  beginning: true
  sidebar: left
pretty_table: true
tikzjax: true
pseudocode: true
---

```txt
@misc{jin2026eventtensor,
  title = {Event Tensor: A Unified Abstraction for Compiling Dynamic Megakernel},
  author = {Jin, Hongyi and Hou, Bohan and Wang, Guanjie and Lai, Ruihang and Chen, Jinqi and Ye, Zihao and Cai, Yaxing and Dong, Yixin and Cheng, Xinhao and Zhang, Zhihao and Zhao, Yilong and Huang, Yingyi and Yang, Lijie and Jiang, Jinchen and Oliaro, Gabriele and Ji, Jianan and Miao, Xupeng and Grover, Vinod and Mowry, Todd C. and Jia, Zhihao and Chen, Tianqi},
  year = {2026},
  eprint = {2604.13327},
  archivePrefix = {arXiv},
  primaryClass = {cs.DC},
  url = {https://arxiv.org/abs/2604.13327}
}
```

This is a reading note for [**Event Tensor: A Unified Abstraction for Compiling Dynamic Megakernel**](https://arxiv.org/abs/2604.13327), submitted to arXiv on April 14, 2026.

The short version:

> Event Tensor turns fine-grained megakernel synchronization into a first-class tensor object in compiler IR, so a compiler can represent, transform, and lower dynamic task dependencies instead of hand-writing one-off persistent kernels.

That is the real contribution. The paper is not claiming that event counters, semaphores, persistent kernels, or GPU task queues are new by themselves. The novelty is the **compiler abstraction**: represent events as symbolic-shaped tensors, express producer-to-event and event-to-consumer relations with coordinate maps, and then lower the same representation into either static or dynamic megakernel schedules.

## Why This Paper Matters

LLM serving is increasingly bottlenecked by execution overhead, especially in low-batch decoding:

- A decode step can contain hundreds or thousands of small GPU operations.
- Kernel launch latency can be comparable to, or larger than, the fastest kernels.
- Kernel boundaries act as global synchronization barriers.
- CUDA Graph reduces launch overhead but still preserves kernel boundaries.
- Megakernels remove launch gaps and allow tile-level overlap, but they are hard to program and usually assume fixed shapes or simple dense workloads.

The paper targets the missing piece:

```text
CUDA Graph:
  less launch overhead
  still kernel-by-kernel dependency boundaries
  hard to handle many dynamic shapes without recapture

Manual megakernel:
  one persistent kernel
  fine-grained task overlap
  hard to write, hard to maintain, hard to support dynamism

Event Tensor:
  compiler IR for tile dependencies
  symbolic shapes for dynamic batches
  data-dependent event updates/triggers for MoE-like routing
  static or dynamic scheduling generated from one abstraction
```

The key insight is very simple:

```text
Data tensors:
  multidimensional values indexed by coordinates

Event tensors:
  multidimensional completion events indexed by coordinates
```

Once synchronization becomes tensor-shaped, the compiler can reuse the same symbolic-shape machinery used for data tensors. This is what makes dynamic megakernels possible without recompiling or recapturing every concrete shape.

## Main Contributions

The contributions can be read as four layers.

### 1. Event Tensor As A First-Class IR Object

The paper defines an **Event Tensor** as a multidimensional array of event counters. Each element records whether some set of producer tasks has completed. Consumers can wait on the event or be triggered by it.

This changes synchronization from scattered low-level code into an analyzable IR object:

```text
Before:
  hand-written semaphore counters
  custom wait loops
  task graph materialized or hard-coded manually

After:
  ETensor(shape, wait_count)
  producer out_edges: task_coord -> event_coord
  consumer in_edges:  task_coord -> event_coord
  compiler lowers notify/wait/trigger
```

The paper's formulation is roughly:

```python
E = ETensor(shape=(n,), wait_count=4)

B = call_device(
    partial_sum,
    tile_num=(n, 4),
    in_edges={},
    out_edges={E: "ij->i"},
)

C = call_device(
    final_sum,
    tile_num=(n,),
    in_edges={E: "i->i"},
    out_edges={},
)
```

The string `"ij->i"` means that producer task `(i, j)` updates event `E[i]`. Since there are four values of `j`, each `E[i]` waits for four partial-sum tasks. The consumer task `final_sum(i)` can run as soon as `E[i]` is complete. It does not need every row's partial sums to finish.

### 2. Symbolic-Shape Task Graphs

The Event Tensor shape can contain symbolic dimensions, such as batch size `B` or number of token blocks `n`.

That means the compiler can represent a **family of task graphs**:

```text
Template:
  E: ETensor((B, H))
  task_grid: (B, H)

Runtime B = 1:
  materialized event grid has 1 * H events

Runtime B = 8:
  materialized event grid has 8 * H events
```

The compiler does not need to generate a separate CUDA Graph or megakernel for every batch size. The symbolic Event Tensor is a compact task-graph template.

This is the first major reason the abstraction is useful for production inference. Continuous batching creates dynamic shape values all the time. Static CUDA Graph capture handles this by capturing many shape-specialized graphs, which creates warmup overhead and deployment complexity.

### 3. Data-Dependent Updates And Triggers

Dynamic shapes are not enough. MoE layers introduce **data-dependent control flow**: the tasks that should run depend on routing tensors computed at runtime.

The paper uses MoE as the core example:

```text
Token -> TopK router -> token grouping -> expert GroupGEMM -> scatter/output
```

For each token, `topk` decides which experts it should visit. This means:

- A grouping task for token `i` may update expert event `E[topk[i, k]]`.
- Each expert event's wait count depends on how many tokens were routed to it.
- Each expert event may trigger a runtime-dependent range of GroupGEMM tiles.
- The range is represented by an `exp_indptr` array, similar to CSR sparse matrix indexing.

In text form:

```text
topk:
  token i -> selected experts

exp_indptr:
  expert e -> GroupGEMM tile range
  tiles for expert e are [exp_indptr[e], exp_indptr[e + 1])
```

The novelty is that Event Tensor allows these runtime tensors to participate in event indexing and triggering:

```text
data-dependent update:
  grouping_tile(token_i) notifies E[topk[i, k]]

data-dependent trigger:
  E[expert_e] triggers GroupGEMM tiles in
  range(exp_indptr[e], exp_indptr[e + 1])
```

This is a clean abstraction boundary. The compiler still emits a persistent kernel, but the runtime values determine the actual dependency edges followed by that kernel.

### 4. One Abstraction, Two Scheduling Strategies

The same Event Tensor graph can be lowered into two scheduling styles:

| Strategy | Best For | Mechanism | Cost |
|---|---|---|---|
| Static scheduling | Predictable workloads | Precompute per-SM task queues, insert wait/notify | Low runtime overhead, less adaptive |
| Dynamic scheduling | Irregular workloads | GPU task queue, push tasks when events complete, idle SMs pop work | Better load balance, queue overhead |

This is important because megakernel scheduling is workload-dependent. Dense transformer decode often benefits from static scheduling because tasks are regular and scheduling overhead matters. MoE and communication-heavy kernels may benefit from dynamic scheduling because task times and routing are irregular.

## Core Mental Model

Think of the computation as three objects:

```text
Task grid:
  A multidimensional set of tile-level tasks.
  Example: GEMM tiles (m_tile, n_tile).

Event tensor:
  A multidimensional set of event counters.
  Example: E[row_block] means all partial sums for that row block are ready.

Coordinate maps:
  Functions from task coordinates to event coordinates.
  Example: producer (i, j) updates event i.
```

The general dependency pattern is:

```text
producer task -> event tensor element -> consumer task
```

But the dependency edges are not manually listed. They are represented by compact index maps:

```text
Producer grid P(i, j)
  out_edges: P(i, j) -> E(i)

Consumer grid C(i)
  in_edges: E(i) -> C(i)
```

This gives the compiler enough information to generate synchronization code without materializing a huge task graph in host memory.

## Example: Split Row Sum

The paper's simple example is a split-K row sum.

Suppose:

```text
A shape: (n * 32, 128)
C shape: (n * 32)
Goal:
  C[row] = sum over A[row, :]
```

Instead of one task per row block, split the reduction into two stages:

```text
partial_sum(i, j):
  B[i*32 : i*32+32, j] =
    sum A[i*32 : i*32+32, j*32 : j*32+32]

final_sum(i):
  C[i*32 : i*32+32] =
    sum B[i*32 : i*32+32, :]
```

The first stage has task grid `(n, 4)`. The second stage has task grid `(n,)`.

Naive kernel-by-kernel execution does this:

```text
run all partial_sum(i, j)
global kernel boundary
run all final_sum(i)
```

Event Tensor execution does this:

```text
partial_sum(0, 0) -> E[0]
partial_sum(0, 1) -> E[0]
partial_sum(0, 2) -> E[0]
partial_sum(0, 3) -> E[0]
E[0] complete -> final_sum(0)

partial_sum(1, 0) -> E[1]
...
E[1] complete -> final_sum(1)
```

Now `final_sum(0)` can start as soon as row block 0 is ready, even if row block 1 is still computing.

The event counter implementation is:

```text
E[i].counter starts at 4

partial_sum(i, j):
  compute B tile
  atomic_dec(E[i].counter)

final_sum(i):
  wait until E[i].counter == 0
  compute C tile
```

This looks small, but this is exactly the dependency pattern that scales to transformer layers: a later tiled operator often only needs a subset of a previous operator's tiles.

## Event Tensor IR

A minimal IR for reproducing the abstraction needs these pieces.

```python
class EventTensor:
    def __init__(self, name, shape, wait_count=None):
        self.name = name
        self.shape = shape          # can contain symbolic variables
        self.wait_count = wait_count

class Edge:
    def __init__(self, event_tensor, coord_map, kind):
        self.event_tensor = event_tensor
        self.coord_map = coord_map  # task_coord -> event_coord
        self.kind = kind            # "in" or "out"

class TaskGrid:
    def __init__(self, name, tile_shape, device_func):
        self.name = name
        self.tile_shape = tile_shape
        self.device_func = device_func
        self.in_edges = []
        self.out_edges = []

class GraphFunc:
    def __init__(self):
        self.task_grids = []
        self.event_tensors = []
```

For the split row sum:

```python
n = SymVar("n")
E = EventTensor("E", shape=(n,), wait_count=4)

partial = TaskGrid("partial_sum", tile_shape=(n, 4), device_func=partial_sum)
partial.out_edges.append(Edge(E, coord_map=lambda i, j: (i,), kind="out"))

final = TaskGrid("final_sum", tile_shape=(n,), device_func=final_sum)
final.in_edges.append(Edge(E, coord_map=lambda i: (i,), kind="in"))

graph = GraphFunc()
graph.event_tensors.append(E)
graph.task_grids.extend([partial, final])
```

The compiler must infer two facts:

```text
E[i] producer count = number of partial tasks that map to E[i] = 4
final_sum(i) is ready when E[i] reaches zero
```

For static maps like `"ij->i"`, this can be derived statically. For data-dependent maps like `topk[i, k]`, initialization must be computed at runtime.

## Runtime Semantics

At runtime, an Event Tensor is lowered to an integer tensor.

```text
E: ETensor(shape=(n,), wait_count=4)

lowers to:
  int E_counter[n]
  initialized to 4 for each i
```

The two basic operations are:

```c
notify(E, idx):
  old = atomic_sub(&E_counter[idx], 1)
  if old == 1:
      trigger consumers of E[idx]

wait(E, idx):
  while atomic_load(&E_counter[idx]) != 0:
      spin
```

For static scheduling, `trigger` usually just releases a waiting task because the task is already in some SM's precomputed queue.

For dynamic scheduling, `trigger` pushes newly ready consumer tasks into a GPU queue.

Important implementation notes:

- `notify` must publish the producer's writes before the counter reaches zero.
- `wait` must acquire visibility of producer writes before reading produced data.
- A practical CUDA implementation should use release semantics on notify and acquire semantics after wait, or an equivalent combination of atomics and fences.
- The paper describes the runtime state as integer tensors plus scheduler queues. It does not require a general host-side task graph executor at runtime.

## Static Scheduling

Static scheduling precomputes the task order before launch.

The generated megakernel has one persistent loop per SM or worker group:

```text
host:
  static_schedule = GenerateStaticSchedule(graph)
  copy static_schedule to GPU
  launch persistent_kernel<<<num_sms, ...>>>(static_schedule, ...)

device:
  sm_id = get_sm_id()
  while task = static_schedule[sm_id].next():
      for each input event of task:
          wait(event)
      run task tile
      for each output event of task:
          notify(event)
```

The paper's static transformation can be written as:

```python
def static_schedule_transform(mod, graph):
    mod_updated = copy(mod)
    static_schedule = GenerateStaticSchedule(graph)
    fused_kernel = NewPersistentKernel()
    fused_kernel.add_buffer(static_schedule)

    for task_grid in graph.task_grids:
        fused_kernel.add_dispatch_logic(task_grid)

        for event in task_grid.in_edges:
            fused_kernel.add_wait_logic(event)

        fused_kernel.add_tile_logic(task_grid)

        for event in task_grid.out_edges:
            fused_kernel.add_notify_logic(event)

    mod_updated.replace(graph, fused_kernel)
    return mod_updated
```

For regular workloads, static scheduling is appealing because it avoids GPU queue push/pop overhead. The cost is that the schedule may be suboptimal when task durations vary.

The paper uses these policies for dynamism under static scheduling:

- **Shape dynamism**: sample representative shape values; unseen shapes reuse the queue for the next larger sampled shape.
- **Data-dependent dynamism**: conservatively rewrite related notify/wait operations to a single worst-case event such as `E[0]`.
- **Queue construction**: use a simple round-robin policy.

That means static scheduling supports dynamism, but conservatively. It is best when the task graph is regular enough that the precomputed order remains good.

## Dynamic Scheduling

Dynamic scheduling uses a lightweight GPU task scheduler.

The execution model is:

```text
ready queue:
  contains tasks whose dependencies are satisfied

worker SM:
  pop ready task
  execute tile
  notify output events
  if an event reaches zero:
      push its consumer tasks
```

Text diagram:

```text
time T1:
  SM0 finishes producer P0
  E[k] goes from 2 to 1
  no consumer is ready yet
  SM0 pops another ready task

time T2:
  SM1 finishes producer P1
  E[k] goes from 1 to 0
  consumers of E[k] are pushed to queue
  an idle SM pops one consumer and runs it
```

The paper's dynamic transformation is:

```python
def dynamic_schedule_transform(mod, graph):
    mod_updated = copy(mod)
    fused_kernel = NewPersistentKernel()
    scheduler = GPUScheduler()

    fused_kernel.add_pop_logic(scheduler.pop_tasks)

    for task_grid in graph.task_grids:
        fused_kernel.add_dispatch_logic(task_grid)
        fused_kernel.add_tile_logic(task_grid)

        for event in task_grid.out_edges:
            fused_kernel.add_complete_on_logic(
                event,
                on_complete=scheduler.push_tasks,
            )

    mod_updated.replace(graph, fused_kernel)
    return mod_updated
```

The paper reports a centralized queue in global memory shared across SMs. This is simple but may contend at scale. The appendix also describes an **early push** optimization: push a consumer task when all its producer tasks have been dispatched, not necessarily completed, then keep an extra wait before the consumer's actual execution. This overlaps scheduler push overhead with producer computation.

Inferred implementation skeleton:

```c
while (true) {
    Task t = queue_pop(global_ready_queue);
    if (t.kind == DONE) break;

    // The task may have been pushed early.
    for (dep in t.input_events) {
        wait(dep.event, dep.index);
    }

    dispatch_tile(t);

    for (out in t.output_events) {
        old = atomic_sub_release(&out.event.counter[out.index], 1);
        if (old == 1) {
            for (consumer in consumers(out.event, out.index)) {
                queue_push(global_ready_queue, consumer);
            }
        }
    }
}
```

Dynamic scheduling naturally handles runtime shapes and data-dependent routing because tasks are generated or selected after runtime values are known.

## Data-Dependent MoE In Detail

MoE is the best example because it has both irregular work and fine-grained producer-consumer structure.

A simplified MoE layer:

```text
input tokens
  -> router computes topk experts
  -> grouping reorders tokens by expert
  -> GroupGEMM expert computation
  -> scatter/combine output
```

The dynamic dependency challenge:

```text
The compiler does not know at compile time:
  how many tokens go to expert 0
  how many tokens go to expert 1
  which grouping tasks update which expert events
  how many GroupGEMM tiles each expert needs
```

Event Tensor representation:

```text
E_expert[e]:
  event for expert e's grouped tokens being ready

topk[token, k]:
  runtime selected expert

exp_count[e]:
  runtime number of tokens routed to expert e

exp_indptr[e]:
  prefix sum of GroupGEMM tiles per expert
```

Runtime initialization:

```python
for e in experts:
    E_expert[e].counter = exp_count[e]
```

Grouping tasks:

```python
for token in tokens:
    for k in range(top_k):
        e = topk[token, k]
        group_token_for_expert(token, e)
        notify(E_expert[e])
```

Triggering GroupGEMM:

```python
def on_expert_ready(e):
    begin = exp_indptr[e]
    end = exp_indptr[e + 1]
    for tile_id in range(begin, end):
        push_task(GroupGEMM, tile_id)
```

This is the core abstraction win. The same Event Tensor can encode:

- static edges like `ij -> i`;
- symbolic-shape event grids like `(B, H)`;
- data-dependent updates like `i -> topk[i, :]`;
- data-dependent triggers like `e -> range(exp_indptr[e], exp_indptr[e + 1])`.

Without this abstraction, every MoE megakernel needs custom scheduling code.

## Lowering To A Minimal Runtime

The paper emphasizes that ETC does not need a heavy task-graph runtime.

Runtime state:

```text
1. integer tensors for Event Tensor counters
2. task queue data structures for dynamic scheduling
3. precomputed execution queues for static scheduling
```

The dependency graph is compiled into control flow. There is no generic runtime walking a fully materialized graph of millions of nodes.

This matters because tile-level LLM task graphs can be huge. If every tile and every edge were separately materialized, graph management overhead could dominate.

The compiled-in model:

```text
Event Tensor IR:
  compact symbolic dependencies

compiler lowering:
  wait/notify/push/pop inserted into persistent kernel

runtime:
  counters and queues only
```

## End-To-End Compilation Flow

The paper's system is the Event Tensor Compiler, or ETC. It is implemented as compiler passes on top of Apache TVM. The abstraction itself is intended to be compiler-agnostic and could be integrated into stacks such as Triton or CuteDSL.

The pipeline:

```text
1. Start from a computational graph with tiled operators.
   Device functions are already partitioned into CTA-level tasks.

2. Add Event Tensors and in_edges/out_edges.
   These encode fine-grained dependencies between task grids.

3. Run graph-level optimizations.
   This includes standard graph optimization and memory planning.

4. Run tile-level optimizations.
   This decides low-level instruction mapping, pipelining, and operator details.

5. Choose a scheduling transformation.
   Static: precompute per-SM queues.
   Dynamic: insert scheduler push/pop logic.

6. Emit a persistent GPU kernel.
   The fused device function dispatches all tile kinds inside one kernel.

7. Add weight-prefetching pass.
   If the task's weights are known before input activation arrives, prefetch them while waiting.

8. For static scheduling, materialize the per-SM task order.
```

The important assumption is step 1: ETC starts from tiled operators. It is not yet automatically discovering every possible tile partition from a high-level PyTorch graph. The conclusion says future work could generate Event Tensor task graphs from standard computational graphs.

## How To Replicate The System From Scratch

This section is not all explicitly specified by the paper. It is a practical reconstruction plan based on the paper's abstraction and pseudocode.

### Step 1: Build A Tiny Event Tensor IR

Implement:

```python
SymVar
Tensor
EventTensor
TaskGrid
EdgeMap
GraphFunc
```

Required APIs:

```python
graph.add_event(name, shape, wait_count)
graph.call_device(fn, tile_num, args, in_edges, out_edges)
edge_map(task_coord, runtime_tensors) -> event_coord_or_range
```

Represent edge maps in two forms:

```text
static affine/einsum maps:
  "ij->i"
  "bh->bh"
  "bh->u"

general lambda maps:
  lambda i, k: topk[i, k]
  lambda e: range(exp_indptr[e], exp_indptr[e + 1])
```

For a first prototype, do not implement a full parser. Store Python callbacks or a small structured map object.

### Step 2: Implement Counter Initialization

For each Event Tensor element, compute the number of producers that must notify it.

Static case:

```python
for event_index in E.shape:
    E.counter[event_index] = count_producers_mapping_to(event_index)
```

For `"ij->i"` with tile shape `(n, 4)`:

```python
E.counter[i] = 4
```

Dynamic case:

```python
E.counter[e] = runtime_exp_count[e]
```

For MoE, this count can be computed from `topk`.

### Step 3: Implement Notify And Wait Intrinsics

Define compiler intrinsics:

```python
event_notify(E, index)
event_wait(E, index)
event_trigger(E, index)
```

Lower them to CUDA-like code:

```c
__device__ void event_notify(int* counter, int idx) {
    int old = atomicSubRelease(&counter[idx], 1);
    if (old == 1) {
        // event complete
    }
}

__device__ void event_wait(int* counter, int idx) {
    while (atomicLoadAcquire(&counter[idx]) != 0) {
        __nanosleep(8);
    }
}
```

If release/acquire atomics are not available in your prototype stack, use conservative fences:

```c
__threadfence();
atomicSub(&counter[idx], 1);

while (atomicAdd(&counter[idx], 0) != 0) {}
__threadfence();
```

This is slower but useful for correctness-first prototyping.

### Step 4: Implement A Static Scheduler

For every task grid, enumerate concrete tasks for the selected shape.

```python
tasks = []
for task_grid in graph.task_grids:
    for coord in product(range(dim) for dim in materialize(task_grid.tile_shape)):
        tasks.append(TaskInstance(task_grid, coord))
```

Use round-robin per-SM queues:

```python
queues = [[] for _ in range(num_sms)]
for k, task in enumerate(tasks):
    queues[k % num_sms].append(task)
```

Emit one persistent kernel:

```c
while (cursor < queue_len[sm_id]) {
    Task t = queue[sm_id][cursor++];

    for each input edge:
        idx = eval_edge_map(edge, t.coord);
        event_wait(edge.E, idx);

    dispatch_task(t);

    for each output edge:
        idx = eval_edge_map(edge, t.coord);
        event_notify(edge.E, idx);
}
```

This already replicates the paper's basic static scheduling idea.

### Step 5: Implement A Dynamic Scheduler

Start with a simple global MPMC queue in GPU global memory:

```c
struct Queue {
    Task* buffer;
    unsigned int head;
    unsigned int tail;
};
```

A simple prototype can use atomic increments:

```c
bool push(Queue* q, Task t) {
    int pos = atomicAdd(&q->tail, 1);
    q->buffer[pos] = t;
    return true;
}

bool pop(Queue* q, Task* out) {
    int pos = atomicAdd(&q->head, 1);
    if (pos >= q->tail) return false;
    *out = q->buffer[pos];
    return true;
}
```

This is not production-grade because `tail` visibility and empty-queue races need careful handling. For a robust version:

- use fixed-capacity ring buffers with sequence numbers;
- or one queue per SM/CTA plus work stealing;
- or a centralized queue with CAS-protected head/tail and memory fences.

For functional replication, the first version is enough if tasks are seeded conservatively and queue capacity is large.

Dynamic kernel skeleton:

```c
while (!done) {
    Task t;
    if (!pop(global_queue, &t)) {
        if (all_tasks_done()) break;
        backoff();
        continue;
    }

    for each input edge:
        event_wait(edge.E, eval_edge_map(edge, t.coord));

    dispatch_task(t);

    for each output edge:
        idx = eval_edge_map(edge, t.coord);
        old = atomicSub(&edge.E.counter[idx], 1);
        if (old == 1) {
            push_consumers(edge.E, idx);
        }
}
```

`push_consumers(E, idx)` needs an inverse mapping from event coordinates to consumer tasks. For static maps, precompute this inverse relation. For dynamic maps, compute it using runtime tensors.

### Step 6: Implement Dispatch

A persistent kernel needs to dispatch among task kinds:

```c
switch (task.kind) {
    case TASK_Q_NORM:
        q_norm_tile(task.coord, args...);
        break;
    case TASK_ROPE:
        rope_tile(task.coord, args...);
        break;
    case TASK_GEMM:
        gemm_tile(task.coord, args...);
        break;
    case TASK_REDUCE_SCATTER:
        reduce_scatter_tile(task.coord, args...);
        break;
}
```

This is where operator kernels live. Event Tensor does not replace the need for good tile kernels. It coordinates them.

### Step 7: Implement Shape Dynamism

At compile time:

```python
compile persistent kernel with symbolic dimensions
```

At runtime:

```python
shape_env = {"B": actual_batch, "n": actual_num_blocks}
materialize event counters using shape_env
materialize static queue for next larger sampled shape, or dynamic ready tasks
launch one persistent kernel
```

For static scheduling, sample shape buckets:

```python
sampled_B = [1, 2, 4, 8, 16, 32, 64, 128]
bucket = min(x for x in sampled_B if x >= actual_B)
use schedule[bucket]
guard tasks whose coordinates exceed actual_B
```

For dynamic scheduling, seed the queue only with tasks valid under actual runtime shape.

### Step 8: Implement MoE Dynamic Dependencies

Minimum MoE prototype:

```python
topk = router(tokens)                  # shape [num_tokens, top_k]
exp_count = histogram(topk)            # shape [num_experts]
exp_indptr = prefix_sum(tile_count(exp_count))
```

Event setup:

```python
E_grouped = EventTensor(
    "E_grouped",
    shape=(num_experts,),
    wait_count=lambda e: exp_count[e],
)
```

Tasks:

```text
route/group task:
  coordinate: token_id
  output event: E_grouped[topk[token_id, k]]

groupgemm task:
  coordinate: tile_id
  input event: E_grouped[expert_of_tile(tile_id)]
```

Trigger:

```python
def consumers_of_E_grouped(e):
    return [
        Task(kind=GROUPGEMM, coord=tile)
        for tile in range(exp_indptr[e], exp_indptr[e + 1])
    ]
```

Correctness checks:

- every routed token is grouped exactly once per selected expert;
- `sum(exp_count) == num_tokens * top_k`;
- every GroupGEMM tile belongs to exactly one expert;
- scatter uses the inverse permutation from grouping.

### Step 9: Add Weight Prefetching

The paper says ETC generates weight-prefetching functions based on user annotations. The idea:

```text
If a task is known before its input activation is ready,
the worker can prefetch the task's weights while waiting on input events.
```

Implementation pattern:

```c
Task t = get_next_task();

prefetch_weights(t);

for dep in t.input_events:
    event_wait(dep);

run_tile(t);
```

This is especially useful when the schedule knows a GEMM tile's weight block before the activation tile is produced.

## Minimal Correctness Tests

An LLM agent trying to reproduce the system should start with these tests.

### Test 1: Split Row Sum

Goal:

```text
partial_sum(i, j) -> E[i] -> final_sum(i)
```

Checks:

- Output equals a reference row sum.
- `final_sum(i)` can run before `partial_sum(i+1, *)` completes.
- No `final_sum(i)` runs before all four partial sums for `i` complete.

### Test 2: Static GEMM + Reduce-Scatter Mock

Use fake tile functions first:

```text
MM tile sleeps/spins for compute time
RS tile sleeps/spins for communication time
```

Check:

- RS tile starts as soon as its dependent MM tiles finish.
- MM and RS tasks overlap on different SMs.
- Static queue preserves correctness.

Then replace fake tiles with real GEMM and communication.

### Test 3: Dynamic Queue Load Balancing

Create tasks with variable runtime:

```text
some experts get many tokens
some experts get few tokens
```

Check:

- dynamic scheduler reduces idle time compared with static schedule;
- queue operations do not lose or duplicate tasks;
- all tasks complete exactly once.

### Test 4: MoE Routing

Use a small MoE:

```text
num_tokens = 8
num_experts = 4
top_k = 2
```

Check:

- `exp_count` matches `topk`;
- event counters initialize from `exp_count`;
- expert GroupGEMM tasks triggered from `exp_indptr`;
- final output matches a normal multi-kernel MoE reference.

### Test 5: Dynamic Shape Buckets

For static scheduling:

```text
compile buckets B = [1, 2, 4, 8]
run actual B = 3 using bucket 4
guard invalid tasks
```

Check:

- output matches reference;
- tasks for invalid coordinates do not touch memory;
- no deadlock occurs from counters expecting invalid producers.

This last point is subtle. If a bucket schedule contains more tasks than the actual shape, counter initialization must match the actual shape, or invalid producer tasks must still perform dummy notifies. The cleaner design is to guard both task execution and counter counts from the same runtime shape.

## Evaluation Summary

The paper evaluates ETC on a server with:

- 8 NVIDIA B200 GPUs connected by NVLink;
- Ubuntu 24.04;
- PyTorch 2.8.0;
- CUDA 13.0;
- NVIDIA driver 580.82.07.

The baselines include deep learning compilers, specialized libraries, and serving systems. The paper notes that existing megakernel frameworks mainly target single-batch inference and cannot be fairly compared on dynamic-shape or data-dependent workloads.

### Fused Communication And Computation

Workloads:

- GEMM + Reduce-Scatter;
- All-Gather + GEMM;
- tensor parallel size 8;
- 8192 tokens;
- MLP configurations derived from Qwen3, LLaMA, Gemma, GPT-3, and related model sizes.

Baselines:

- cuBLAS + NCCL sequential execution;
- TP-Async;
- Triton Distributed v0.0.2-rc;
- cuBLASMp.

Scheduling choices:

- GEMM + Reduce-Scatter uses dynamic scheduling because communication latency can be unpredictable.
- All-Gather + GEMM uses static scheduling because ring all-gather has predictable data arrival and DMA does not consume SM compute in the same way.

Headline result:

- ETC achieves up to 1.40x speedup over the cuBLAS + NCCL baseline for both workloads.

The claimed reason is fine-grained overlap. Event Tensor lets the compiler break monolithic operations into tile dependencies, so compute and communication resources remain busy instead of waiting at kernel boundaries.

### MoE Layer

Workload:

- complete MoE layer from Qwen3-30B-A3B;
- 128 experts;
- top-k 8;
- variable token counts;
- single B200.

Baselines:

- Triton 3.4.0 MoE implementation;
- FlashInfer 0.2.14.post1.

Scheduling:

- ETC uses dynamic scheduling because routing creates irregular task durations and load imbalance.

Headline result:

- up to 1.23x speedup over the best baseline at 1024 tokens.

The important part is not just the number. The MoE experiment tests the core data-dependent Event Tensor claim: the whole MoE dataflow can be fused into one megakernel even though routing decisions are runtime values.

### End-To-End Low-Batch Serving

Workloads:

- Qwen3-30B-A3B MoE model;
- Qwen3-32B dense model;
- Qwen3-32B with tensor parallelism TP=4.

Benchmark setup:

- decoding stage;
- synthetic dataset;
- prefill length 512;
- generate 100 output tokens;
- batch sizes 1 to 128;
- metric is time per output token, TPOT.

Baselines:

- vLLM v0.11.0rc2;
- SGLang v0.5.3rc0;
- both use CUDA Graph and torch.compile-style optimizations.

Headline results:

- Qwen3-30B-A3B: 1.48x speedup over vLLM and 1.20x over SGLang at batch size 1.
- Qwen3-32B single GPU: up to 1.15x over vLLM at batch size 1, and up to 1.09x over SGLang at batch size 64.
- Qwen3-32B TP=4: ETC matches vLLM with speedups from 0.99x to 1.06x; SGLang is faster in some cases due to its optimized CPU scheduler.

The paper says ETC's compiled megakernels cover the full decoding pipeline: Attention, RoPE, KV-cache, Norm, MLP, and MoE, not just GEMM.

The specific optimizations enabled by removing kernel boundaries:

- Q's Norm + RoPE can run concurrently with K's Norm + RoPE + CacheAppend.
- GroupGEMM stages in MoE can be pipelined.
- GEMM stages in MLP can be pipelined.
- Weight prefetching can begin before input activations are ready.
- Wave quantization is reduced because SMs are assigned work more smoothly across fused operators.

### Warmup Overhead

The paper measures engine warmup time for Qwen3-32B, including engine initialization, model loading, JIT compilation, and CUDA Graph capture.

| Method | Warmup Time | Number Of JIT Graph Captures |
|---|---:|---:|
| SGLang JIT | 583 s | 51 |
| vLLM JIT | 123 s | 67 |
| ETC AOT | 35 s | 0 |

ETC also has an offline compilation time of 107 s for Qwen3-32B, but that is not repeated at serving startup. The reason this works is symbolic-shape Event Tensor support: one precompiled shape-generic megakernel can cover dynamic runtime shapes.

### Static vs Dynamic Scheduling

The paper compares static and dynamic scheduling against an unfused megakernel baseline. The unfused baseline uses the same operator code, but inserts a global synchronization-style event between stages. Therefore the speedups isolate the value of fine-grained Event Tensor dependencies rather than better operator kernels.

MoE layer, relative to unfused megakernel:

| Tokens | Static | Dynamic |
|---:|---:|---:|
| 1 | 1.03 | 0.95 |
| 128 | 1.02 | 1.06 |
| 1024 | 1.04 | 1.08 |
| 4096 | 1.02 | 1.03 |

Qwen3-32B TP=4, relative to unfused megakernel:

| Batch Size | Static | Dynamic |
|---:|---:|---:|
| 1 | 1.09 | 0.83 |
| 16 | 1.06 | 0.82 |
| 32 | 1.07 | 0.85 |
| 128 | 1.06 | 0.89 |

Interpretation:

- Dynamic scheduling helps irregular MoE once token count is large enough to amortize scheduler overhead.
- Static scheduling wins on regular dense distributed decode because dynamic queue overhead is too high, especially for remote task queues.
- Supporting both strategies in one compiler framework is therefore useful.

## What Is Actually New?

I think the novelty is easy to misunderstand, so here is the sharp version.

Not new by itself:

- persistent kernels;
- semaphore counters;
- spin-wait synchronization;
- GPU task queues;
- static per-SM schedules;
- dynamic work queues;
- CUDA Graph alternatives;
- operator fusion.

New contribution:

```text
Represent fine-grained task synchronization as symbolic-shaped tensors in compiler IR,
then lower that representation into static or dynamic persistent megakernel schedules,
including data-dependent event updates and triggers.
```

The Event Tensor is an abstraction that makes existing mechanisms composable and compiler-generatable.

The difference is similar to the difference between:

```text
manual CUDA shared-memory programming
```

and

```text
a compiler IR that explicitly represents memory scopes and layouts
```

The low-level mechanisms may already exist, but the IR decides whether a compiler can reason about them systematically.

## Limitations And Open Questions

### The Compiler Starts From Tiled Operators

ETC assumes operators are already partitioned into CTA-level tasks, either user-specified through a DSL or provided as compiler builtins. Automatically generating optimal Event Tensor graphs from arbitrary model graphs is future work.

This means a full reproduction still needs a good tile-kernel layer:

- GEMM tiles;
- attention tiles;
- RoPE and Norm tiles;
- GroupGEMM tiles;
- communication tiles.

Event Tensor coordinates them, but does not remove the need to implement them.

### Static Scheduling Is Conservative For Dynamism

The paper's static scheduling support for data-dependent dynamism can fall back to conservative synchronization such as rewriting dependencies to `E[0]`. This preserves correctness but can lose parallelism.

This is probably why dynamic scheduling is important for MoE.

### Dynamic Scheduling Uses A Centralized Queue

The paper says the implementation uses a centralized global-memory queue for simplicity. This may become a bottleneck at larger scale or with very small tasks.

Potential future improvements:

- per-SM queues;
- per-cluster queues;
- work stealing;
- hierarchical schedulers;
- specialized queue layouts for predictable producer-consumer patterns.

### Memory Ordering Details Are Crucial

The paper describes notify/wait with integer counters and atomics, but a robust reproduction must be careful about memory consistency.

A producer must make its output data visible before the event reaches zero. A consumer must not read produced data before acquiring the completed event.

This is easy to get wrong in CUDA, especially if different CTAs or SMs communicate through global memory.

### Evaluation Is Strong But Hardware-Specific

The main experiments use B200 GPUs. The abstraction is not B200-specific, but performance trade-offs are hardware-dependent:

- atomic cost;
- queue contention;
- copy engine behavior;
- tensor core shape support;
- NVLink and multimem behavior;
- SM count and occupancy constraints.

Replication on H100 or A100 should preserve the idea, but not necessarily the same speedups.

### Operator Quality Still Matters

The paper notes some cases where ETC trails the best baseline due to engineering factors, such as compiler-generated GEMM tiles being less tuned than cuBLAS and CPU-side overhead in the serving engine.

This is important. A megakernel compiler can expose more overlap, but poor tile kernels can erase the benefit.

## My Take

This paper is interesting because it identifies a clean compiler abstraction for a messy systems problem.

Manual megakernels are powerful but painful. CUDA Graphs are practical but too coarse. Event Tensor sits between them:

```text
fine-grained enough:
  tile-level dependencies, task overlap, dynamic MoE routing

structured enough:
  tensor-shaped IR, symbolic dimensions, compiler transformations

low-level enough:
  lowers to counters, queues, persistent kernels
```

The abstraction also fits a bigger trend: LLM serving wants less CPU involvement and more device-side autonomy. MPK-style systems and other megakernel efforts show that one persistent kernel can remove launch overhead. Event Tensor asks the next compiler question: how do we make this programmable and dynamic enough for real serving workloads?

For me, the most valuable idea is not "use a counter." It is:

```text
Make synchronization tensor-shaped.
```

Once dependencies are shaped like tensors, symbolic shape compilation, dynamic indexing, and task graph transformations become natural compiler problems instead of bespoke CUDA engineering.

## Checklist For An LLM Agent Reimplementation

If an LLM agent had to replicate a small version from this note only, it should implement in this order:

1. Implement `EventTensor`, `TaskGrid`, `EdgeMap`, and `GraphFunc`.
2. Support static edge maps like `"ij->i"` using simple coordinate projection.
3. Lower Event Tensors to integer counters.
4. Implement `notify` and `wait` with conservative atomics and fences.
5. Build a static round-robin per-SM task queue.
6. Emit a persistent kernel that loops through the static queue.
7. Validate on split row sum.
8. Add a dynamic global ready queue.
9. Push consumer tasks when event counters reach zero.
10. Validate on variable-duration fake tasks.
11. Add runtime edge maps using tensors such as `topk` and `exp_indptr`.
12. Validate on a toy MoE layer.
13. Add static shape buckets and runtime guards.
14. Add weight prefetch hooks before event waits.
15. Replace fake tile functions with real GEMM, communication, attention, and MoE kernels.
16. Compare against kernel-by-kernel and CUDA Graph baselines.
17. Measure both raw GPU time and end-to-end serving TPOT.
18. Add ablations against an unfused megakernel using identical tile code.

The core thing to preserve is this invariant:

```text
Every consumer task must wait for exactly the Event Tensor elements
that cover the producer tasks whose data it reads.
```

Everything else, static queues, dynamic queues, prefetching, and shape buckets, is an optimization around that invariant.
