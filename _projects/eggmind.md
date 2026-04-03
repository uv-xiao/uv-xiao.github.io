---
layout: page
title: EggMind
description: Execution-guided agentic superoptimizer for scalable equality saturation
img:
importance: 4
category: research
related_papers:
  - xiao2026eggmind
---

**EggMind** explores how agentic reasoning can make equality saturation more scalable and more directed. Instead of treating superoptimization as blind search, it runs a bounded optimization loop that proposes, tests, diagnoses, and revises rewrite strategies.

```text
rewrite space
      |
      v
search with execution feedback
      |
      v
better optimization strategies
```

The high-level idea is to let execution evidence guide the search for useful rewrites. This makes the optimizer less like a brute-force enumerator and more like a system that learns which transformations are worth pursuing.
