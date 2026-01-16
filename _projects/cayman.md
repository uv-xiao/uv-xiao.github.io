---
layout: page
title: Cayman
description: Automatic accelerator generation with control flow and memory optimization
img:
importance: 5
category: research
related_papers:
  - xiao2025cayman
---

**Cayman** is a framework for automatic domain-specific accelerator generation that jointly optimizes control flow and data access patterns - two aspects often ignored by existing tools.

```
┌────────────────────────────────────────────────────────────────┐
│                   Cayman Accelerator Generator                  │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Application                                                   │
│       │                                                         │
│       ▼                                                         │
│   ┌───────────────────────────────────────────────────────┐    │
│   │                    Cayman                              │    │
│   │  ┌─────────────┐          ┌─────────────┐             │    │
│   │  │Control Flow │◄────────►│   Memory    │             │    │
│   │  │Optimization │  Joint   │   System    │             │    │
│   │  │             │  Opt.    │   Design    │             │    │
│   │  │• Branches   │          │• Prefetch   │             │    │
│   │  │• Speculation│          │• Banking    │             │    │
│   │  │• Predication│          │• Caching    │             │    │
│   │  └─────────────┘          └─────────────┘             │    │
│   └───────────────────────────────────────────────────────┘    │
│       │                                                         │
│       ▼                                                         │
│   Accelerator RTL (handles irregular apps!)                     │
└────────────────────────────────────────────────────────────────┘
```

## Beyond Embarrassingly Parallel Kernels

Most accelerator generators assume your computation is:
- Perfectly nested loops
- Regular array accesses
- No data-dependent control flow

Real applications have:
- **Irregular control flow**: Branches, early exits, data-dependent iteration
- **Complex memory patterns**: Indirect accesses, sparse data structures
- **Variable latency operations**: Cache misses, memory bank conflicts

Cayman handles the messy reality.

## The Cayman Approach

### 1. Application Profiling
Analyze your application to understand:
- Hot loops and their control flow patterns
- Memory access patterns and reuse distances
- Data-dependent behavior

### 2. Control Flow Optimization
Transform irregular control into hardware-friendly forms:
- **Branch prediction hints**: When branches are predictable
- **Speculative execution**: When wrong paths are cheap
- **Control flow elimination**: When branches can become data flow

### 3. Memory System Design
Automatically design the memory hierarchy:
- **Prefetching strategies**: Based on observed access patterns
- **Banking configurations**: To maximize parallel access
- **Caching policies**: For irregular reuse patterns

### 4. Joint Optimization
Control and memory decisions interact:
- Speculation affects memory bandwidth needs
- Memory latency affects control flow choices

Cayman uses **dynamic programming** to efficiently explore this joint space.

## Key Results

- **Handles irregular applications** that other tools reject
- **Joint optimization** finds better designs than separate passes
- **Competitive performance** with hand-designed accelerators

## Target Applications

Cayman excels at applications that traditional HLS struggles with:
- Graph algorithms (sparse, irregular)
- Tree traversals (data-dependent control)
- Sparse linear algebra (indirect memory access)
- Database operations (variable-length records)
