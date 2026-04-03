---
layout: page
title: HTP
description: Human- and LLM-friendly retargetable compiler substrate with inspectable IRs
img:
importance: 1
category: tools
github: https://github.com/uv-xiao/htp
---

**HTP** asks how a retargetable compiler can stay understandable instead of becoming an opaque stack. The project builds a compiler substrate for heterogeneous tensor programs whose intermediate forms remain readable, inspectable, and interpretable to both human developers and LLM agents.

```text
programs and kernels
        |
        v
inspectable compiler artifacts
        |
        v
retargetable backends
```

The high-level idea is simple: retargeting should not require giving up visibility. Rather than burying decisions inside backend-specific lowering pipelines, HTP keeps the important compiler state exposed so optimization, debugging, and retargeting can be followed and revised step by step.
