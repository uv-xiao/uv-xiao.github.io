---
layout: page
title: Cayman
description: Automatic accelerator generation with control flow and data access optimization
img:
importance: 5
category: research
related_papers:
  - xiao2025cayman
---

**Cayman** is the first end-to-end framework that synthesizes high-performance custom accelerators with full control flow and data access support, automating both candidate selection and hardware synthesis.

```text
+------------------------------------------------------------------+
|                        Cayman Framework                          |
+------------------------------------------------------------------+
|                                                                  |
|  Application --> LLVM IR --+--> profile/analyze                  |
|                            |                                     |
|                            +--> build wPST                       |
|                                    |                             |
|  +---------------------------------v---------------------------+ |
|  |             Candidate Selection (DP)                        | |
|  |  +---------+   +------------+   +-------------------------+ | |
|  |  |  wPST   |-->| Accelerator|-->| Pareto-optimal          | | |
|  |  |traversal|   |   Model    |   | Solutions               | | |
|  |  +---------+   | - Ctrl-flow|   | (speedup vs area)       | | |
|  |                | - Interface|   +-------------------------+ | |
|  |                +------------+                               | |
|  +-------------------------------------------------------------+ |
|                            |                                     |
|                            v                                     |
|  +-------------------------------------------------------------+ |
|  |             Accelerator Merging                             | |
|  |  DFG1 + DFG2 --> Reconfigurable Datapath + FSMs             | |
|  +-------------------------------------------------------------+ |
|                            |                                     |
|                            v                                     |
|                     Hardware (Verilog)                           |
+------------------------------------------------------------------+
```

## Limitations of Prior Work

| Approach | Candidate Selection | Control Flow | Data Access | Hardware Sharing |
|----------|--------------------:|--------------|-------------|------------------|
| **HLS** | manual | optimized | specified | / |
| **CFU synthesis** | auto (DFG only) | / | scalar-only | restricted |
| **Off-core accel** | auto | sequential | slow | restricted |
| **Cayman** | **auto** | **optimized** | **specialized** | **flexible** |

Prior frameworks either exclude control flow/memory access, or only synthesize sequential control with slow interfaces.

## Whole-Application Program Structure Tree (wPST)

Cayman extends the traditional PST to capture all SESE (single-entry-single-exit) regions as acceleration candidates:

```
                    root
                   /    \
              func0      func1
              /              \
         loop            loop outer
        linear          /    |    \
          |          entry  head  exit
        linear              |
                       loop dot-product
                       /    |    \
                    head  body  cond
```

Two region types:
- **bb regions**: Basic blocks (dataflow graphs)
- **ctrl-flow regions**: Loops and conditionals

## Data Access Interface Modeling

Cayman systematically models three processor-accelerator interfaces:

| Interface | Mechanism | Best For | Overhead |
|-----------|-----------|----------|----------|
| **Coupled** | ld/st units stall on access | Simple access | Low |
| **Decoupled** | AGUs compute addresses independently | Stream patterns in pipelined loops | Medium (AGUs + FIFOs) |
| **Scratchpad** | Dedicated buffer + DMA sync | High reuse (access count >> footprint) | High (buffer + DMA) |

**Impact example** (dot product `sum += x[i]*y[i]`):

| Control Flow | Coupled | Decoupled | Scratchpad |
|--------------|---------|-----------|------------|
| Sequential | 6N cycles | 4N cycles | - |
| Pipelined | II=3 | II=1 | - |
| Unrolled(2) | 9(N/2) | - | 4(N/2) |

## Candidate Selection Algorithm

Dynamic programming on wPST with heuristic pruning:

```python
def DP(vertex v):
    if prune(v, R): return
    if v is bb:
        F[v] = filter(pareto(accel(v, R)))
    else:
        F[v] = ∅
        for u in v.children:
            DP(u)
            F[v] = filter(F[v] ⊗ F[u])
        if v is ctrl-flow:
            F[v] = filter(F[v] ∪ pareto(accel(v, R)))
```

- **F[v]**: Pareto-optimal solutions for subtree rooted at v
- **⊗**: Combines sibling solutions
- **filter**: Removes solutions too close in area (keeps O(log A) solutions)
- **Complexity**: O(N log²A + E)

## Accelerator Merging

Cayman enables reusable accelerators across kernels with diverse control flows:

```text
+-------------------------------------------------------+
|       Merged Accelerator                              |
|  +-------------------------------------------------+  |
|  | Reconfigurable Datapath (from DFG1 U DFG2)      |  |
|  |  LD --> MUL --> ADD --> ST                      |  |
|  |   ^              ^                              |  |
|  |  MUX            MUX  <-- configBits             |  |
|  +-------------------------------------------------+  |
|       ^ ctrlSignals                                   |
|  +----+----+                                          |
|  |  Ctrl   |<-- select                                |
|  +----+----+                                          |
|    +--+--+                                            |
| FSM1   FSM2  (standalone FSMs for each kernel)        |
| linear  dot-prod                                      |
+-------------------------------------------------------+
```

**Key insight**: Basic blocks with FP ops and data access dominate area; control FSMs are cheap. Merge datapaths, keep separate FSMs.

## Performance Estimation

Speedup calculation without full synthesis:

```
Speedup = T_all / (T_all - T_cand + Cycle_cand / F)
```

Where:
- **T_all**: Total application duration (profiled)
- **T_cand**: Duration of accelerated kernels (profiled)
- **Cycle_cand**: Estimated accelerator cycles (from scheduling)
- **F**: Target frequency

## Implementation

Built on LLVM 18:
- **wPST**: RegionInfoAnalysis pass
- **Profiling**: Custom instrumentation pass
- **Analysis**: MemoryDependenceAnalysis + ScalarEvolution
- **Synthesis**: OpenROAD targeting Nangate45 PDK
