---
name: update-academic-website
description: Keep this Jekyll/al-folio academic website consistent when adding or changing papers, arXiv preprints, projects, current research links, CV entries, PDFs, and project pages. Use when Codex is asked to update publications, projects, about-page research text, the website CV, the LaTeX/PDF CV, or related academic-site metadata.
---

# Update Academic Website

## Workflow

1. Read repository instructions first. In this repository, build verification must use `pixi run build`.
2. Check `git status --short --untracked-files=all` before editing. Preserve unrelated user changes and submodule changes.
3. Gather authoritative metadata. For arXiv or recent papers, fetch the current arXiv page/PDF metadata before editing.
4. Update every required surface together:
   - `_bibliography/papers.bib` for publication cards and selected papers.
   - `_projects/*.md` for project pages and `related_papers`.
   - `_pages/about.md` for current research links.
   - `_data/cv.yml` for the website CV.
   - `_cv_latex/CV.tex` and `assets/pdf/CV.pdf` for the PDF CV.
5. Regenerate the PDF CV when `CV.tex` changes: `make -C _cv_latex`.
6. Verify generated HTML and PDF content after building. Use `pdftotext assets/pdf/CV.pdf -` for PDF checks.
7. Run `pixi run build` before completion.

## Consistency Rules

- Use one stable BibTeX key per paper and reuse it in project `related_papers`.
- Prefer `abbr={Preprint}` for arXiv-only entries unless a venue is known.
- Include `html`, `arxiv`, and `pdf` fields when available. Local PDFs go in `assets/pdf/`; remote PDFs may link directly.
- If a project has both a workshop paper and an arXiv/full paper, list the arXiv/full paper first in `related_papers`.
- Keep the about page concise. Current research items should link to the strongest public artifact: project repo, arXiv page, or project page.
- Keep website CV and PDF CV semantically aligned, even if formatting differs.
- If `_cv_latex` is a submodule, inspect and report its nested status separately.

## Verification Checklist

Before finishing, confirm:

- The new or changed title appears on the home/selected papers surface when `selected={true}`.
- The project page shows the expected related publication.
- About-page links point to the intended target.
- Website CV contains the entry in `_site/cv/index.html` after build.
- PDF CV text contains the entry after regeneration.
- `pixi run build` exits 0.

For repo-specific paths and commands, read `references/repo-map.md`.
