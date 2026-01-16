---
layout: page
title: ISAMORE
description: Finding reusable instructions via e-graph anti-unification
img:
importance: 1
category: research
related_papers:
  - youwei2025isamore
---

**ISAMORE** applies e-graph techniques to discover **reusable** custom instructions - instructions that benefit multiple applications, not just one.

```
┌─────────────────────────────────────────────────────────────────┐
│              ISAMORE: Finding Reusable Instructions              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   App A          App B          App C                            │
│  ┌─────┐        ┌─────┐        ┌─────┐                          │
│  │a*2+b│        │x*2+y│        │p*2+q│                          │
│  └──┬──┘        └──┬──┘        └──┬──┘                          │
│     │              │              │                              │
│     └──────────────┼──────────────┘                              │
│                    │                                             │
│                    ▼  Anti-Unification                           │
│              ┌──────────┐                                        │
│              │ ?0*2+?1  │  ◄── Common pattern!                   │
│              └──────────┘                                        │
│                    │                                             │
│                    ▼                                             │
│              ┌──────────┐                                        │
│              │  Custom  │  One instruction,                      │
│              │   Instr  │  benefits all apps                     │
│              └──────────┘                                        │
└─────────────────────────────────────────────────────────────────┘
```

## The Instruction Reuse Problem

Custom instructions provide significant speedups, but come with costs:

- **Design effort**: Each instruction needs hardware implementation
- **Verification**: Every new instruction must be validated
- **Compiler support**: Instruction selection, scheduling, register allocation

If an instruction only helps one application, is it worth the effort?

**ISAMORE's insight**: Find instructions that are useful across *many* applications. One instruction, many beneficiaries.

## The Challenge

Application-specific instructions are easy to find - just look at hot loops. But **reusable** instructions require finding patterns that:

1. Appear across multiple, different applications
2. Are general enough to be useful, but specific enough to accelerate
3. Have reasonable implementation cost

This is a needle-in-a-haystack problem across a combinatorial space.

## E-Graphs + Anti-Unification

ISAMORE's key insight: **anti-unification** on e-graphs efficiently finds common patterns.

### What is Anti-Unification?
Given two expressions, anti-unification finds their most specific generalization:
```
anti_unify(a * 2 + b, x * 2 + y) = ?0 * 2 + ?1
```

The result is a pattern that matches both inputs, with holes (`?0`, `?1`) for the differences.

### Why E-Graphs?
E-graphs represent equivalence classes of expressions. Anti-unification on e-graphs finds patterns across **all equivalent forms** of each application's computation:
- `a * 2` ≡ `a << 1` ≡ `a + a`
- The pattern might match one form in app A, another form in app B

This dramatically increases the chances of finding reusable patterns.

## The ISAMORE Pipeline

1. **Build e-graphs** for candidate instruction sequences from each application
2. **Apply anti-unification** across applications to find common patterns
3. **Filter patterns** by:
   - Reusability score (how many apps benefit?)
   - Implementation cost (is it worth building?)
   - Compilation feasibility (can we actually use it?)
4. **Output** ranked list of recommended custom instructions

## Results

ISAMORE discovers instructions that:
- Accelerate multiple benchmarks (not just the one they came from)
- Have reasonable implementation cost
- Can be compiled efficiently by standard techniques
