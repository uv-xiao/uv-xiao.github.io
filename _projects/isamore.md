---
layout: page
title: ISAMORE
description: Finding reusable instructions via e-graph anti-unification
img:
importance: 1
category: research
github: https://github.com/pku-liang/ISAMORE
related_papers:
  - youwei2025isamore
---

**ISAMORE** is an end-to-end framework for discovering reusable custom instructions from domain applications using e-graph anti-unification.

```
┌─────────────────────────────────────────────────────────────────┐
│                      ISAMORE Framework                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Domain Programs                    Ruleset Generation          │
│        │                                   │                     │
│        ▼ LLVM                              │                     │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                         RII                              │   │
│   │  ┌─────────┐    ┌─────────┐    ┌──────────┐             │   │
│   │  │Structured│───►│ E-graph │───►│  Phase   │◄──Ruleset  │   │
│   │  │   DSL   │    │ encode  │    │ Scheduler│             │   │
│   │  └─────────┘    └─────────┘    └────┬─────┘             │   │
│   │                                     │                    │   │
│   │       ┌─────────────────────────────┼────────────┐      │   │
│   │       │         Per-Phase Loop      │            │      │   │
│   │       │  ┌────────┐  ┌─────────┐  ┌─▼────────┐   │      │   │
│   │       │  │ EqSat  │─►│ Smart AU│─►│Vectorize │   │      │   │
│   │       │  └────────┘  └─────────┘  └────┬─────┘   │      │   │
│   │       │                    ┌───────────┘         │      │   │
│   │       │  ┌────────┐  ┌─────▼───┐                 │      │   │
│   │       │  │Extract │◄─│ Select  │◄── Cost Model  │      │   │
│   │       │  └────────┘  └─────────┘     (HLS+PDK)  │      │   │
│   │       └──────────────────────────────────────────┘      │   │
│   └─────────────────────────────────────────────────────────┘   │
│        │                                                         │
│        ▼                                                         │
│   CI₀, CI₁, ... ──► Verilog (via HLS/CIRCT)                      │
└─────────────────────────────────────────────────────────────────┘
```

## The Reusability Problem

Existing instruction customization approaches suffer from **low reusability**:

| Approach | Problem |
|----------|---------|
| **Fine-grained** [enumeration] | Enumerate convex subgraphs, miss larger patterns |
| **Coarse-grained** [NOVIA] | Merge basic blocks, syntactic-only, hard to reuse |
| **Both** | Overlook semantic equivalence, no vectorization |

**ISAMORE's insight**: Use e-graph anti-unification to identify semantically equivalent common patterns across applications, fundamentally considering reusability.

## Reusable Instruction Identification (RII)

RII is the core methodology, combining e-graph techniques with hardware-aware optimization:

### 1. Structured DSL

ISAMORE introduces a DSL to encode programs with control flow as e-graph terms:

```
e ::= Literal | UnaryOp(e) | BinaryOp(e₁, e₂)
    | If(eᵢₙ, eₜₕₑₙ, eₑₗₛₑ)    // Conditional
    | Loop(eᵢₙ, eᵦₒdᵧ)         // Do-while loop
    | Vec(e₁, ...) | VecOp(...)  // Vector operations
    | ?x | App(eₚₐₜ, e*)       // Pattern application
```

### 2. Phase-Oriented Iteration

Instead of monolithic equality saturation (which explodes), RII applies phases:

```
Phase 1: int-sat rules    → saturate integer equivalences
Phase 2: float-sat rules  → saturate float equivalences
Phase 3+: nonsat rules    → selective, restrained application
```

Each phase identifies patterns over previously identified ones, discovering **increasingly reusable patterns**.

### 3. Smart AU Identification

Two heuristics overcome exponential AU complexity:

**Similarity-based e-class pairing**: Only pair e-classes with:
- Consistent result types (via type inference)
- High structural similarity (via 64-bit structural hashing)

**Heuristic pattern sampling**: Instead of all AU patterns:
- **Boundary**: Keep only min/max by feature function
- **KD-tree**: Partition by feature vector, sample evenly

### 4. Pattern Vectorization

RII exploits data-level parallelism from scalar programs:

```
┌─────────────────────────────────────────────────────┐
│ 1. Seed Packing: Find scalar pattern instances      │
│    (seeds), pack into Vec e-nodes                   │
│                                                      │
│ 2. Pack Expansion: Lift rewrites recover vector     │
│    constructors: Vec(Add a b)(Add c d) ⇝           │
│                  VecAdd(Vec a c)(Vec b d)           │
│                                                      │
│ 3. Acyclic Pruning: Greedy extraction + compress    │
│    to eliminate Get→Vec→Get cycles                  │
└─────────────────────────────────────────────────────┘
```

### 5. Hardware-Aware Selection

Cost model estimates performance and area impact:

```
ΔL(p) = Σᵤ∈ᵤₛₑ₍ₚ₎ (Σₒ∈ₚ CPO(bb(o,u))) - L_HLS(p)
S(P) = L_cpu / (L_cpu - Σₚ∈P ΔL(p))
A(P) = Σₚ∈P A_HLS(p)
```

- **CPO**: Cycles per operation from GEM5 profiling
- **L_HLS**: Hardware latency from ASAP scheduling
- **Pareto-optimal selection**: Trade off speedup vs. area

## E-Graph Anti-Unification

Given two e-classes, AU finds their least general generalization:

```
AU(a×2+b, 1+i<<1) via e-graph:
  1. EqSat: 1+i<<1 ≡ (1+i)×2
  2. AU: (a+b)×2, (1+i)×2 → (?x+?y)×2
```

Formalization:
```
AU(a, b) = ⋃_{nₐ∈M(a), nᵦ∈M(b)} AU(nₐ, nᵦ)
AU(s(a₁,...,aₖ), s(b₁,...,bₖ)) = {s(p₁,...,pₖ) | pᵢ ∈ AU(aᵢ,bᵢ)}
AU(s₁(...), s₂(...)) = ?x   if s₁ ≠ s₂
```

## Links

- [GitHub](https://github.com/pku-liang/ISAMORE)
- Built on [egg](https://github.com/egraphs-good/egg) and [babble](https://github.com/dcao/babble) frameworks
- Backend synthesis via [CIRCT](https://circt.llvm.org/)
