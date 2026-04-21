---
name: debug-website-deploy
description: Build, serve, deploy, and debug this Jekyll/al-folio academic website. Use when Codex is asked to fix local build failures, Jekyll/Liquid/BibTeX/CV/PDF issues, local server problems, GitHub Pages deployment failures, broken links, generated assets, or CI workflow problems for this repository.
---

# Debug Website Deploy

## First Principles

- Use repository entrypoints: `pixi run build`, `pixi run serve`, and `pixi run rebuild`.
- Do not call Jekyll directly unless debugging the scripts or CI workflow itself.
- Treat generated `_site` content as output. Fix source files, scripts, or config instead.
- Preserve unrelated dirty work and inspect submodules separately.

## Local Build Debugging

1. Reproduce with `pixi run build`.
2. Read the first real error, not only the final failure line.
3. Map the error to the source surface:
   - Bibliography errors: `_bibliography/papers.bib`, `_layouts/bib.liquid`, `_plugins/hide-custom-bibtex.rb`.
   - Page/render errors: `_pages`, `_layouts`, `_includes`, `_sass`, `_config.yml`.
   - CV PDF errors: `_cv_latex/CV.tex`, `_cv_latex/Makefile`, `assets/pdf/CV.pdf`.
   - Notebook/blog conversion errors: `_posts`, `assets/jupyter`, Python/Jupyter dependencies.
4. Make the smallest source fix and rerun the same command.
5. If a warning is unrelated and build exits 0, report it as residual warning rather than a blocker.

## Local Serve Debugging

Use `pixi run serve`. If port 4000 is occupied, identify the process with `lsof -i:4000` and either stop it if it is yours or use the build output for static verification. Do not edit `scripts/serve.sh` just to bypass a local port conflict.

## Deployment Debugging

1. Inspect `.github/workflows/deploy.yml` and the failing GitHub Actions log.
2. Compare CI commands with local commands. CI currently installs nbconvert, sets `JEKYLL_ENV=production`, runs `bundle exec jekyll build`, purges CSS, then deploys `_site`.
3. Reproduce the closest local equivalent through `pixi run build` first. Only run direct Bundler/Jekyll commands when testing a CI-specific hypothesis.
4. For broken links after deploy, inspect `.github/workflows/broken-links-site.yml` and reproduce local paths against `_site/**/*.html` when possible.

## Verification

Before claiming a fix:

- Run the exact failing command when local.
- Run `pixi run build` for normal site verification.
- Check affected generated HTML with `rg` in `_site` when content presence matters.
- Check `assets/pdf/CV.pdf` with `pdftotext` when CV content matters.
- Report any warnings separately from failures.

For path and workflow details, read `references/repo-commands.md`.
