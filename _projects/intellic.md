---
layout: page
title: IntelliC
description: Human- and LLM-friendly intelligent compiler infrastructure with inspectable representations
img:
importance: 1
category: tools
github: https://github.com/uv-xiao/IntelliC
---

**IntelliC** asks how compiler infrastructure can become intelligent without becoming opaque. The project is a clean-branch rebuild of a human- and LLM-friendly compiler stack whose first invariant is process quality: design, evidence, verification, and agent workflow come before compiler implementation. Every major representation is expected to be explainable, inspectable, replayable, and verifiable before it becomes an implementation dependency.

```text
design intent + source programs
        |
        v
inspectable compiler representations
        |
        v
replay logs, checks, and evidence
        |
        v
agent-assisted compiler development
```

The central idea is that LLM assistance should not be bolted onto an opaque compiler backend. Instead, the compiler should expose artifacts that both humans and agents can read: design documents, intermediate representations, transformation evidence, replayable decisions, and verification hooks. This makes the compiler easier to debug, but it also gives agents a stable surface for proposing changes without hallucinating hidden state.

Key features:

- **Explainable representations:** compiler state should be meaningful enough for a person or LLM to inspect before it is trusted by later passes.
- **Replayable workflows:** important transformations should leave evidence that can be rerun or audited, turning compiler development into a traceable process.
- **Verification-first implementation:** design and checks are treated as dependencies of implementation, not as cleanup after the fact.

```text
for compiler_feature in roadmap:
    write_design(compiler_feature)
    define_visible_ir_or_artifact(compiler_feature)
    attach_replay_or_verification(compiler_feature)
    implement_only_after_evidence_boundary_is_clear()
```

This is intentionally different from a conventional "add passes until it works" compiler project. IntelliC treats the compiler itself as an agent-facing system: optimization, debugging, retargeting, and automated development should proceed through artifacts that make decisions visible rather than through hidden backend side effects.
