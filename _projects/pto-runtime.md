---
layout: page
title: PTO Runtime
description: Task-graph runtime for distributed tensor compilation and coordinated host-device execution
img:
importance: 3
category: tools
github: https://github.com/uv-xiao/pto-runtime
---

**PTO Runtime** focuses on the execution side of compiled tensor workloads. It turns dependency-rich task graphs into coordinated runtime execution across host control, device-side scheduling, and compute kernels.

```text
compiled task graph
        |
        v
runtime coordination
        |
        v
scalable device execution
```

The project aims to make large tensor programs feel like organized flows of work instead of disconnected kernels. By treating execution as a graph problem, PTO Runtime creates a path from compilation output to structured, scalable system behavior.
