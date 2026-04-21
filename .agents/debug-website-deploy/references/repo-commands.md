# Repository Commands And Workflows

## Pixi Tasks

```bash
pixi run build
pixi run serve
pixi run rebuild
pixi run build-slides
```

`pixi run build` calls `scripts/build.sh`, which sources `scripts/setup-env.sh` and then runs the Jekyll build. Use it for repository verification.

## Deployment Workflow

- `.github/workflows/deploy.yml` runs on pushes and PRs touching site content.
- CI uses Ruby 3.3.5, Python 3.13, `pip3 install --upgrade nbconvert`, `JEKYLL_ENV=production bundle exec jekyll build`, `purgecss`, and `JamesIves/github-pages-deploy-action`.
- `.github/workflows/broken-links-site.yml` runs after successful deploy and checks local links in `_site/**/*.html` with lychee.

## Useful Diagnostics

```bash
git status --short --untracked-files=all
git -C _cv_latex status --short
rg -n "<title-or-link>" _site
pdftotext assets/pdf/CV.pdf -
lsof -i:4000
```
