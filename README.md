# Youwei Xiao's Academic Website

This is my personal academic website built with Jekyll and the al-folio theme. The site features technical blog posts, research projects, presentations, and an academic CV focusing on programming language research, e-graphs, compiler optimization, and related topics.

## Quick Start

### Using Pixi (Recommended)

This project uses [Pixi](https://pixi.sh) for environment management:

```bash
# Install dependencies and set up environment
pixi install

# Start local development server
pixi run serve

# Create a new blog post
pixi run new-post "Your Post Title"
```

### Manual Setup

```bash
# Install dependencies
bash ./scripts/install.sh

# Start local development server
./scripts/serve.sh

# Create a new blog post
./scripts/new-post.sh "Your Post Title"
```

## Project Structure

```
.
├── _posts/              # Blog posts in Markdown with Jekyll frontmatter
├── _pages/              # Static pages (about, blog index, etc.)
├── _slide/              # Marp presentation slides (markdown → HTML)
├── _bibliography/       # BibTeX files for academic references
├── _data/               # YAML data files (coauthors, venues, etc.)
├── _layouts/            # Jekyll layout templates
├── _includes/           # Reusable Jekyll components
├── _sass/               # SCSS stylesheets and theme customization
├── _plugins/            # Custom Ruby plugins for Jekyll
├── assets/              # Static resources (images, css, js, slides)
├── scripts/             # Utility bash scripts
├── _config.yml          # Jekyll configuration
├── Gemfile              # Ruby dependencies
├── package.json         # Node.js dependencies (Marp, Prettier)
└── pixi.toml           # Pixi environment configuration
```

## Writing Blog Posts

### Creating a New Post

```bash
pixi run new-post "My Awesome Post Title"
# or
./scripts/new-post.sh "My Awesome Post Title"
```

This creates a new post in `_posts/` with:
- Proper Jekyll frontmatter
- Yesterday's date (to avoid "future date" build errors)
- Standard template with feature flags

### Post Features

Posts support various features through frontmatter flags:

```yaml
---
layout: post
title: Your Post Title
date: 2024-01-01 00:00:00-0400
description: Brief description
tags: [tag1, tag2]
categories: [category]
featured: true
mermaid: true          # Enable Mermaid diagrams
toc: true              # Table of contents
tabs: true             # Tab component support
tikzjax: true         # TikZ diagrams
pseudocode: true      # Algorithm pseudocode
---
```

## Creating Presentations

Slides use [Marp](https://marp.app/) for Markdown-based presentations:

1. Create a slide in `_slide/your-presentation.md`
2. Build slides: `pixi run build-slides`
3. Embed in posts using iframe:
   ```html
   <iframe src="/assets/slide/your-presentation.html"></iframe>
   ```

## Development Commands

### Pixi Tasks (Recommended)

```bash
pixi run serve          # Start dev server with live reload
pixi run build          # Build production site
pixi run new-post       # Create new blog post
pixi run build-slides   # Convert Marp slides to HTML
pixi run clean          # Clean build artifacts
pixi run format         # Format code with Prettier
```

### Shell Scripts

All scripts are in the `scripts/` directory:

```bash
./scripts/serve.sh              # Start Jekyll dev server (port 4000)
./scripts/build.sh              # Production build
./scripts/new-post.sh "Title"   # Create new post
./scripts/build-slides.sh       # Build Marp slides
./scripts/slide-to-images.sh    # Convert slides to PNG
./scripts/clean.sh              # Clean build artifacts
```

## Key Features

### Academic Features
- **Bibliography Management**: Jekyll Scholar plugin for citations
- **CV/Resume**: Structured academic CV with publications
- **Project Showcase**: Grid layout for research projects

### Technical Features
- **Marp Slides**: Integrated presentation system
- **Math Support**: MathJax for LaTeX equations
- **Code Highlighting**: GitHub-style syntax highlighting
- **Diagram Support**: Mermaid, TikZ, Chart.js
- **Related Posts**: Automatic related post suggestions

### Development Features
- **Live Reload**: Auto-refresh during development
- **Environment Management**: Pixi for reproducible setup
- **Automated Deployment**: GitHub Actions → GitHub Pages
- **Code Quality**: Prettier formatting with Liquid support

## Deployment

The site automatically deploys to GitHub Pages when pushing to the `main` branch:

1. Push changes to `main`
2. GitHub Actions builds the site
3. Deploys to `https://uv-xiao.github.io`

## Configuration

Main configuration files:

- `_config.yml`: Jekyll settings, theme options, plugin config
- `pixi.toml`: Development environment and task definitions
- `marp.config.mjs`: Marp slide configuration
- `CLAUDE.md`: AI assistant instructions for the codebase

## Tips

1. **Date Handling**: Posts use yesterday's date to avoid "future post" errors
2. **Slide Images**: Copy slide PNGs to `assets/slide/` for embedding
3. **Local Port**: Dev server kills any process on port 4000 before starting
4. **Writing Style**: Blog posts use a relaxed, humorous, insightful tone
5. **Performance**: Production builds include CSS purging

## Dependencies

- **Ruby 3.3.5**: Jekyll static site generator
- **Node.js 22**: Marp CLI and Prettier
- **Python 3.12**: Utility scripts and tools
- **Jekyll Plugins**: Scholar, feed, sitemap, etc.
