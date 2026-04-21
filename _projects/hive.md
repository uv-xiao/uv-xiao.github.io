---
layout: page
title: Hive
description: Multi-agent inference infrastructure for algorithm- and task-level scaling
img:
importance: 2
category: tools
github: https://github.com/veri-smart/hive
related_papers:
  - luo2026hive
---

**Hive** addresses the serving problem created by modern agentic LLM workloads: scaling is no longer only about bigger models or more GPUs. Algorithm-level scaling, such as Tree-of-Thoughts and repeated sampling, creates redundant reasoning branches; task-level scaling decomposes work across multiple agents with very different context lengths, cache footprints, and contribution patterns. Hive makes these structures visible to the inference system so the backend can optimize them instead of treating every request as an independent prompt.

```text
agent and scaling description frontend
        |
        v
coroutine-style flow graph
        |
        v
Logits Cache + Agent-Aware Scheduling
        |
        v
algorithm- and task-level scaling backend
```

The frontend describes per-agent behavior and test-time scaling algorithms as asynchronous coroutine-like task spawning and synchronization. That description is not just a programming convenience; it exposes the structure the backend needs to identify repeated sampling paths and agent-specific resource importance.

Key features:

- **Logits Cache:** reuses intermediate logits across redundant sampling paths. Instead of recomputing every replayed branch, Hive can preserve stable tokens and resample only selected hotspot positions.
- **Agent-Aware Scheduling:** allocates compute and KV-cache resources according to agent contribution, so coordinator or hotspot agents are not evicted as if they were ordinary requests.
- **Multi-agent flow modeling:** represents task delegation and synchronization explicitly, enabling the runtime to see algorithm-level branching and task-level agent heterogeneity together.

```text
for agent_event in flow_graph:
    if event spawns reasoning branches:
        logits = lookup_or_decode(LogitsCache, branch_state)
        output = replay_stable_tokens_and_resample_hotspots(logits)
    if event updates agent state:
        priority = contribution(agent_id, cache_hotspots, runtime_profile)
        scheduler.place_request(agent_id, priority)
```

The paper evaluates Hive on repeated resampling and multi-agent hardware-verification workflows. Reported results show Logits Cache improving resampling throughput and Agent-Aware Scheduling reducing hotspot miss rates. The project matters because it treats agent structure as a first-class systems signal: the inference backend can optimize the shape of the workflow, not only the shape of the model.
