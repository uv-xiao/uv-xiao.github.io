---
layout: page
title: PTO Runtime
description: Ascend chips and LingQu SuperPods task-graph runtime coordinating host, AICPU, and AICore execution
img:
importance: 3
category: tools
github: https://github.com/uv-xiao/pto-runtime
---

**PTO Runtime** focuses on the execution side of compiled tensor workloads on Ascend chips and LingQu SuperPods. The core problem is that a compiled tensor program is not just a list of kernels: it is a dependency graph that must coordinate host orchestration, AICPU scheduling, AICore kernel execution, device memory, and simulation or hardware backends. PTO Runtime turns that graph into a three-program execution model with explicit APIs between each layer.

```text
Python/compiler graph builder
        |
        v
Host runtime (.so)
        |
        v
AICPU scheduler (.so)
        |
        v
AICore compute kernels (.o)
```

The central technical idea is to make task dependencies a runtime object rather than a convention hidden in launch order. The host runtime manages device setup, binary loading, memory allocation, and Python bindings. The AICPU side owns task scheduling and dependency tracking. AICore workers execute kernels assigned through handshake buffers and report completion back to the scheduler.

Key features:

- **Three-program model:** host, AICPU, and AICore binaries are compiled separately but connected by stable C/Python APIs and shared device data structures.
- **Runtime variants:** `host_build_graph` builds the graph on the host for debugging, `aicpu_build_graph` moves graph construction to the device, and `tensormap_and_ringbuffer` uses TensorMap-derived dependencies plus ring buffers for production-style streaming.
- **Simulation-to-hardware path:** `a2a3sim` supports thread-based host simulation without Ascend hardware, while `a2a3` targets real devices through CANN.

```text
ready = tasks with fanin == 0
while unfinished tasks remain:
    task = scheduler.pop_ready(ready)
    core = wait_for_idle_aicore()
    handshake[core].task = task
    handshake[core].aicpu_ready = true
    wait until handshake[core].task_status == done
    for succ in task.successors:
        succ.fanin -= 1
        if succ.fanin == 0:
            ready.push(succ)
```

The project matters because it gives a compiler-generated tensor graph an execution substrate with explicit coordination semantics for Ascend chips and LingQu SuperPods. Instead of treating host code, device scheduling, and compute kernels as disconnected artifacts, PTO Runtime makes them parts of one graph-driven system that can be debugged in simulation and then moved toward Ascend hardware execution.
