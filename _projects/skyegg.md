---
layout: page
title: SkyEgg
description: Joint implementation selection and scheduling using e-graphs
img:
importance: 3
category: research
related_papers:
  - xiao2025skyeggjointimplementationselection
---

**SkyEgg** is a hardware synthesis framework that jointly optimizes implementation selection and scheduling using e-graphs. It overcomes the suboptimality of sequential HLS phases by representing both algebraic rewrites and hardware implementations as rewrite rules.

```text
+----------------------------------------------------------------+
|                      SkyEgg Framework                          |
+----------------------------------------------------------------+
|                                                                |
|  MLIR Program              Library (DSP48E2, LUT, FP IPs)      |
|       |                           |                            |
|       v                           | Implementation Rules       |
|  +----------+                     | -(A+D)*B => DSP(Vec(A,D,B))|
|  | E-graph  |<--------------------+ A*B => DSP(Vec(A,B))       |
|  |  init    |                       A+B => LUT(Vec(A,B))       |
|  +----+-----+                                                  |
|       | Equality Saturation (algebraic + impl rewrites)        |
|       v                                                        |
|  +----------------------------------------------------------+  |
|  |              E-graph saturate                            |  |
|  |  +-----+   +-----+   +-----+                             |  |
|  |  | a+b | = | LUT |   | DSP |  <-- same e-class           |  |
|  |  +-----+   +-----+   +-----+                             |  |
|  +----------------------------+-----------------------------+  |
|                               |                                |
|       +-----------------------+-------------------+            |
|       v                       v                   v            |
|  +---------+            +----------+        +----------+       |
|  |  MILP   |            |   ASAP   |        |  Timing  |       |
|  | Solver  |            | Heuristic|        |  Model   |       |
|  +----+----+            +----+-----+        +----------+       |
|       +--------+---------+                                     |
|                v                                               |
|  (impl_selection, schedule) --> Verilog                        |
+----------------------------------------------------------------+
```

## The Sequential Synthesis Dilemma

Traditional HLS separates two interdependent decisions:

| Phase | Decision | Problem |
|-------|----------|---------|
| **Implementation Selection** | DSP vs LUT? Pipeline depth? | Ad-hoc pattern matching, ignores scheduling impact |
| **Scheduling** | Which cycle for each op? | Fixed implementations, pessimistic delay estimates |

**Example**: `-(a+b)*c` in 16-bit
- Vitis HLS: 3 cycles (LUT add + LUT neg + DSP mul)
- Optimal: 2 cycles (single DSP48E2 with pre-adder and negation)

The optimal solution requires **algebraic rewriting** (`-(a+b)*c → -((a+b)*c)`) combined with **DSP-aware implementation selection**—neither phase alone can discover it.

## Implementation Rules

SkyEgg models hardware implementations as e-graph rewrite rules:

```text
Matcher             => Applier                   [Condition]
------------------------------------------------------------
-((A+D)*B)          => DSP(Vec(A,D,B))          [A<=30b, D<=27b, B<=18b]
A*B                 => DSP(Vec(A,B))            [integer types]
A+B                 => LUT(Vec(A,B))            [any type]
```

Each implementation has **configurable pipeline registers**:
- DSP48E2: up to 4 internal registers (controls freq: 304MHz → 600MHz)
- FP IP cores: configurable overall latency

## Timing Model

For each implementation, profile from Vivado synthesis:

```text
                    t_incoming
              +--------+---------+
    Input --->| Stage 0|  Reg 1  |---> ...
              +--------+---------+
                          |
                          v t_cycle (register-to-register)
              +--------+---------+
         ...--| Stage L|   Out   |---> t_outgoing
              +--------+---------+
```

**Chain delay** between implementations determines if pipeline registers must be inserted.

## MILP Formulation

Joint optimization over the saturated e-graph:

**Minimize**: `f_root + α·Σ(b_I)` (latency + penalty for implementations)

**Completeness constraints**:
- Root e-class must be selected
- Selected e-class ⟹ at least one contained impl e-node selected
- Selected impl e-node ⟹ all child e-classes selected

**Scheduling constraints**:
- Dependency: `s_I ≥ f_cls` for children
- Latency: `f_I = s_I + L_I`
- Chaining: insert registers if path delay > clock period

## Efficient Solving

| Solver | Approach | Scalability |
|--------|----------|-------------|
| **MILP** | Exact with top-k chaining constraints | Optimal for <400 ops |
| **ASAP** | Greedy earliest-finish selection | <1 sec for 600+ ops |

The ASAP heuristic achieves near-optimal results: only 1 case out of 41 had slightly worse latency than MILP.

## Links

- Implemented with [egglog](https://github.com/egraphs-good/egglog) Python binding
- Targets Xilinx Kintex UltraScale+ FPGAs
