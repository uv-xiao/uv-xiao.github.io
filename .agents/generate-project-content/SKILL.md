---
name: generate-project-content
description: Generate rich academic project content from source artifacts such as papers, arXiv pages, PDFs, repositories, READMEs, docs, code, slides, and existing notes. Use when Codex is asked to draft, expand, rewrite, or improve project pages/descriptions with a strong research story, clear technical overview, novelty/features emphasized, and explanatory text diagrams or pseudocode.
---

# Generate Project Content

## Goal

Turn source material into a project page that is useful to a technical reader: why the project matters, what it does, what is novel, how it works, and how to reason about the system.

## Workflow

1. Gather sources before writing. Use papers for claims and repositories/docs for implementation status. If a source is remote, fetch current metadata/content when the user expects current facts.
2. Extract the project spine:
   - Problem: what bottleneck, gap, or missing abstraction motivates the work.
   - Insight: the core idea that makes the project different.
   - System: the main components, algorithm, compiler pass, runtime, or workflow.
   - Novelty: what is new compared with obvious baselines or prior systems.
   - Evidence: paper results, implemented artifacts, examples, or current limitations.
3. Draft with a strong story first. The first paragraph should name the project, state the problem, and say what the project changes.
4. Add the technical body. Explain the overall mechanism, then the main features or contributions. Keep details grounded in the sources.
5. Add one clarity aid:
   - a text diagram for architecture/data flow,
   - pseudocode for an algorithm/search/runtime loop,
   - or a compact before/after contrast.
6. Mark uncertainty. Do not overclaim results, maturity, benchmarks, or open-source status beyond the sources.
7. Fit the target surface. For `_projects/*.md`, keep frontmatter concise and put the rich explanation in Markdown body.

## Content Requirements

Every generated project page should include:

- A concise frontmatter `description` that fits a card.
- A first paragraph with the full story, not just a label.
- A technical overview that names the core abstractions.
- A novelty/features section or paragraph that makes the contribution memorable.
- A text diagram or pseudocode block that clarifies the mechanism.
- A closing paragraph that explains why the design matters or how it changes the workflow.

## Style

- Prefer concrete nouns and mechanisms over generic phrases like "framework for X".
- Use "because" logic: explain why each design choice matters.
- Avoid empty praise, marketing language, and claims unsupported by sources.
- Use bullets for features only when the features have distinct technical roles.
- Keep project-card descriptions short; put depth in the page body.

## Source Handling

- Papers: use abstract, introduction, method/system sections, figures, evaluation, and limitations.
- Repositories: inspect README, docs, examples, tests, and top-level architecture. Treat TODO docs and design docs as intent unless code/tests show implementation.
- Existing project pages: preserve accurate facts and improve structure; do not delete useful project-specific context.

For a copyable project-page structure and example text blocks, read `references/project-page-structure.md`.
