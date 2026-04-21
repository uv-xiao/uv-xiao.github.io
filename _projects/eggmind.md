---
layout: page
title: EggMind
description: LLM-guided EqSat strategy synthesis with explicit strategy artifacts
img:
importance: 2
category: research
related_papers:
  - yin2026eggmind
  - xiao2026eggmind
---

**EggMind** addresses a bottleneck in equality-saturation-based compilers: once rewrite rules are abundant, the hard problem shifts from discovering rules to controlling when and how those rules should interact. Instead of asking an LLM to mutate backend code directly, EggMind turns EqSat strategy design into an offline synthesis problem over explicit strategy artifacts, so search decisions can be inspected, reused, evaluated, and kept within tractable e-graph growth.

```text
rule synthesis + target cases
        |
        v
EqSatL strategy artifacts
        |
        v
LLM proposal + evaluator feedback
        |
        +--> proof-derived rewrite motifs
        +--> tractability guidance
        |
        v
selected strategy lowered to EqSat backend
```

The central abstraction is **EqSatL**, a small domain-specific language that represents strategy structure explicitly: rulesets, phase ordering, simplification points, budgets, and extraction checkpoints. This gives the LLM a manipulable object at the right level of abstraction. Strategies are no longer hidden inside low-level egglog scripts; they become reusable compiler artifacts that can be proposed, compared, and refined across a family of optimization cases.

Key features:

- **Explicit strategy boundary:** EqSatL separates high-level search intent from backend implementation details, making strategies inspectable before they are lowered.
- **Proof-derived motif feedback:** successful runs are distilled into compact rewrite motifs from proof objects, giving the agent reusable evidence about which rewrite chains actually helped.
- **Tractability guidance:** evaluation feedback steers proposals away from unstable phase structures that trigger e-graph explosion or premature pruning.

```text
memory = {strategy_pool, motif_cache}
while synthesis_budget remains:
    candidate = LLM.propose(EqSatL, memory, tractability_feedback)
    run = evaluate(candidate, benchmark_cases)
    motifs = extract_proof_motifs(run.successful_rewrites)
    memory = update(memory, candidate, run.metrics, motifs)
return select_strategy(memory.strategy_pool)
```

The result is a superoptimization workflow that sits between destructive rewriting and full unguided EqSat. On the reported vectorization benchmarks, EggMind reduces final cost and peak memory relative to full EqSat, and the paper also demonstrates transfer to an XLA-based tensor compiler and a logic-synthesis case study. The broader point is that LLMs become more useful for compiler optimization when the system gives them structured strategy objects and actionable feedback instead of raw backend code.
