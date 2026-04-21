# Project Page Structure

Use this structure for `_projects/<slug>.md` when no stronger local pattern exists.

```markdown
---
layout: page
title: <Project Name>
description: <One concise card sentence naming the core technical contribution>
img:
importance: <number>
category: research
github: <optional repo URL>
related_papers:
  - <optional-bib-key>
---

**<Project Name>** addresses <specific problem> by <core idea>. Instead of <baseline or common failure mode>, it <main mechanism> so that <technical/user benefit>.

The central technical idea is <one-sentence insight>. The system exposes <abstraction/component 1>, <component 2>, and <component 3>, which together let <workflow or algorithm> operate with <property such as reuse, tractability, portability, controllability, verifiability>.

```text
<input/problem state>
        |
        v
<core abstraction or analysis>
        |
        v
<optimization/runtime/compiler action>
        |
        v
<observable output or benefit>
```

Key features:

- **<Feature name>:** <What it does and why it is new/useful.>
- **<Feature name>:** <What it enables technically.>
- **<Feature name>:** <How it changes the workflow or system behavior.>

At a high level, <Project Name> matters because <closing research impact>. This makes <task> less like <old way> and more like <new way>.
```

## Pseudocode Pattern

Use pseudocode when the project is algorithmic or loop-driven.

```text
state = initialize(source_programs_or_tasks)
while budget remains:
    candidate = propose_or_select(state)
    evidence = evaluate(candidate)
    state = refine(state, candidate, evidence)
return best_artifact_or_plan(state)
```

Replace generic verbs with project-specific operations: parse, profile, schedule, rewrite, cache, verify, lower, synthesize, execute, diagnose.

## Strong Story Checklist

- The opening names a real pain point.
- The project has a clear antagonist: opacity, search explosion, manual retargeting, redundant inference, brittle lowering, missing verification, etc.
- The novelty is a mechanism, not just a domain.
- The visual block teaches the architecture or algorithm.
- The closing explains the workflow change, not just the implementation.
