# AGENTS.md

Repository instructions for coding agents working in `uv-xiao.github.io`.

## Overview

This repository is Youwei Xiao's personal academic website built with Jekyll and the al-folio theme.

## Build And Verification

- Use `pixi` tasks for repository workflows instead of calling Jekyll directly.
- Build the website with `pixi run build`.
- Start the local development server with `pixi run serve`.
- For a clean rebuild, use `pixi run rebuild`.
- Do not default to `bundle exec jekyll build` or `bundle exec jekyll serve` unless you are debugging the build scripts themselves.

## Relevant Files

- `pixi.toml`: authoritative task entrypoints for install, build, serve, and rebuild workflows
- `scripts/build.sh`: website build script used by `pixi run build`
- `scripts/serve.sh`: local development server used by `pixi run serve`

## Notes

- A successful website verification in this repository means the site builds through `pixi run build`.
- The LaTeX CV lives under `_cv_latex/` and is verified separately from the Jekyll site.
