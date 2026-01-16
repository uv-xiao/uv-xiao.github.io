---
layout: page
title: Hector
description: Multi-level IR for hardware synthesis built on MLIR
img:
importance: 4
category: tools
github: https://github.com/pku-liang/Hector
related_papers:
  - xu2022hector
---

**Hector** is a two-level IR for hardware synthesis built on MLIR, providing a unified representation for HLS (static, dynamic, hybrid scheduling) and hardware generators.

```
┌──────────────────────────────────────────────────────────────┐
│                    Hector Two-Level IR                        │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│   SCF/Affine (MLIR)                                           │
│        │                                                      │
│        ▼                                                      │
│   ┌────────────────────────────────────────────────────────┐ │
│   │  ToR IR (TOpological Representation)                    │ │
│   │  ┌──────────────┐    ┌──────────────────────────────┐  │ │
│   │  │ Time Graph   │    │  tor.for %i = %c0 to %c10    │  │ │
│   │  │  0─►1─►2─►3  │    │    %x = tor.load on (0 to 1) │  │ │
│   │  │    └─►4─┘    │    │    %y = tor.mulf on (1 to 3) │  │ │
│   │  │  (topology)  │    │  } on (0 to 4)               │  │ │
│   │  └──────────────┘    └──────────────────────────────┘  │ │
│   │  Scheduling: static | pipeline | dynamic | hybrid       │ │
│   └────────────────────────────────────────────────────────┘ │
│        │ Time Graph Transform + Lowering                     │
│        ▼                                                      │
│   ┌────────────────────────────────────────────────────────┐ │
│   │  HEC IR (Hierarchical Elastic Component)                │ │
│   │  ┌──────────┐  ┌──────────┐  ┌──────────┐              │ │
│   │  │STG-style │  │Pipeline  │  │Handshake │              │ │
│   │  │(stateset)│  │(stageset)│  │(graph)   │              │ │
│   │  │ @s0→@s1  │  │ stg0→stg1│  │fork,merge│              │ │
│   │  └──────────┘  └──────────┘  └──────────┘              │ │
│   │  Allocate-assign: explicit resources + signal routing   │ │
│   └────────────────────────────────────────────────────────┘ │
│        │ RTL Generation                                      │
│        ▼                                                      │
│   Chisel ──► Verilog                                          │
└──────────────────────────────────────────────────────────────┘
```

## Why Two Levels?

| Level | Abstraction | Key Question | Use Case |
|-------|-------------|--------------|----------|
| **ToR** | Time graph + operations | *When* does each op execute? | Scheduling, control flow |
| **HEC** | Components + allocations | *Where* does computation happen? | Resource sharing, RTL gen |

## ToR IR: TOpological Representation

Combines a **time graph** (topology) with **functional operations** bound to graph elements.

**Four node types**:
- **Normal**: leads a sequential edge with cycle count (`"seq:2"`)
- **Call**: stalls until callee finishes (`"call"`)
- **If**: leads two branches, each flows to terminator
- **Loop**: leads loop body with back edge

**Operations bind to edges/nodes**:
```mlir
%x = tor.load %A[%i] on (0 to 1)      // edge binding
%y = tor.mulf %x, %c on (1 to 3)      // 2-cycle multiply
tor.for %i = %lb to %ub { ... } on (0 to 4)  // node binding
```

**Three scheduling manners** supported in the same graph:
- Static (`"seq:2"`)
- Pipeline (`"pipeline", II=1`)
- Dynamic (resolved at runtime with handshake)

## HEC IR: Hierarchical Elastic Component

**Allocate-assign mechanism** — explicit resource definition and signal routing:
```mlir
// Allocation
%m.lhs, %m.rhs, %m.res = hec.primitive "m" is "muli" : i32, i32, i32
%reg = hec.wire "reg" : i32

// Assignment
hec.assign %m.lhs = %a
hec.assign %m.rhs = %b
hec.assign %reg = %m.res
```

**Three component styles**:

| Style | Structure | Use Case |
|-------|-----------|----------|
| **STG** | `stateset { state @s0 { ... goto @s1 } }` | Static FSM |
| **Pipeline** | `stageset { stage @s0 { ... } }` | Pipelined datapath |
| **Handshake** | `graph { ... }` with fork/merge/branch | Dynamic scheduling |

## Compilation Flow

1. **Time Graph Transformation**: Split hybrid graphs into single-manner subgraphs connected by function calls
2. **Lowering ToR → HEC**:
   - Resource sharing via conflict graph coloring
   - Register sharing via live range analysis
   - Elastic unit insertion (fork, merge, branch) for dynamic modules
3. **RTL Generation**: Map HEC to Chisel modules with FSM/pipeline/handshake controllers

## Why MLIR?

- **Dialect system**: ToR and HEC as separate dialects with clean transformations
- **SSA form**: Enables standard compiler optimizations
- **Nested regions**: Natural representation for `stateset`, `stageset`, control flow
- **Extensibility**: Easy to add new operations, attributes, and passes

## Links

- [GitHub](https://github.com/pku-liang/Hector)
