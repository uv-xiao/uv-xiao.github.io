---
name: write-reading-notes
description: Create durable reading notes for papers, arXiv PDFs, technical reports, GitHub repositories, and local codebases. Use when Codex is asked to read, summarize, compare, review, extract insights from, or write notes about a paper, repository, project, or source artifact.
---

# Write Reading Notes

## Workflow

1. Identify the artifact: paper URL/PDF, repository URL, local path, commit, branch, or set of files. If the target is remote or recent, fetch current metadata before writing notes.
2. Inspect existing note conventions before creating files. Use the requested destination when provided; otherwise prefer `notes/YYYY-MM-DD-<slug>.md` unless the repository already has a clearer notes directory.
3. Read for structure before detail. For papers, capture title, authors, venue/status, date, abstract, method, experiments, and claims. For repositories, capture purpose, entry points, build/test commands, architecture, dependencies, and active risks.
4. Separate source facts from inference. Mark uncertain claims explicitly and keep direct quotes short with links or page/section references.
5. Write notes that support future work: concise summary first, then reusable technical details, questions, and follow-up actions.

## Paper Notes

Use this order:

1. Metadata: title, authors, venue/status, date, URL, PDF/source links.
2. One-sentence takeaway.
3. Problem and motivation.
4. Core idea and mechanism.
5. Evaluation setup and headline results.
6. Limitations, assumptions, and missing evidence.
7. Relevance to the current repository or project.
8. Open questions and follow-ups.

When reading arXiv papers, prefer the abstract page for metadata and the PDF/HTML for technical content. Record the arXiv ID and version if visible.

## Repository Notes

Use this order:

1. Metadata: repository URL/path, branch/commit if known, license if relevant.
2. Purpose and audience.
3. Quick start: install, build, test, run commands.
4. Architecture map: major directories, main abstractions, data/control flow.
5. Key implementation details with file references.
6. Operational concerns: configs, generated artifacts, CI/deploy path.
7. Gaps, risks, and questions.
8. Follow-up tasks.

For local repositories, use `rg --files`, `rg`, and targeted file reads. Do not infer behavior from filenames alone when code can be inspected.

## Output Quality

- Prefer bullets and compact sections over prose summaries.
- Include enough detail that another agent can continue the work without rereading everything.
- Avoid marketing language and unsupported claims.
- Preserve citations, commit SHAs, and exact commands.

For copyable note skeletons, read `references/note-templates.md`.
