# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Using Gemini CLI for Large Codebase Analysis

When analyzing large codebases or multiple files that might exceed context limits, use the Gemini CLI with its massive
context window. Use `gemini -p` to leverage Google Gemini's large context capacity.

### File and Directory Inclusion Syntax

Use the `@` syntax to include files and directories in your Gemini prompts. The paths should be relative to WHERE you run the
  gemini command:

#### Examples:

**Single file analysis:**
gemini -p "@src/main.py Explain this file's purpose and structure"

Multiple files:
gemini -p "@package.json @src/index.js Analyze the dependencies used in the code"

Entire directory:
gemini -p "@src/ Summarize the architecture of this codebase"

Multiple directories:
gemini -p "@src/ @tests/ Analyze test coverage for the source code"

Current directory and subdirectories:
gemini -p "@./ Give me an overview of this entire project"

## Or use --all_files flag:
gemini --all_files -p "Analyze the project structure and dependencies"

### Implementation Verification Examples

Check if a feature is implemented:
gemini -p "@src/ @lib/ Has dark mode been implemented in this codebase? Show me the relevant files and functions"

Verify authentication implementation:
gemini -p "@src/ @middleware/ Is JWT authentication implemented? List all auth-related endpoints and middleware"

Check for specific patterns:
gemini -p "@src/ Are there any React hooks that handle WebSocket connections? List them with file paths"

Verify error handling:
gemini -p "@src/ @api/ Is proper error handling implemented for all API endpoints? Show examples of try-catch blocks"

Check for rate limiting:
gemini -p "@backend/ @middleware/ Is rate limiting implemented for the API? Show the implementation details"

Verify caching strategy:
gemini -p "@src/ @lib/ @services/ Is Redis caching implemented? List all cache-related functions and their usage"

Check for specific security measures:
gemini -p "@src/ @api/ Are SQL injection protections implemented? Show how user inputs are sanitized"

Verify test coverage for features:
gemini -p "@src/payment/ @tests/ Is the payment processing module fully tested? List all test cases"

When to Use Gemini CLI

Use gemini -p when:
- Analyzing entire codebases or large directories
- Comparing multiple large files
- Need to understand project-wide patterns or architecture
- Current context window is insufficient for the task
- Working with files totaling more than 100KB
- Verifying if specific features, patterns, or security measures are implemented
- Checking for the presence of certain coding patterns across the entire codebase

Important Notes

- Paths in @ syntax are relative to your current working directory when invoking gemini
- The CLI will include file contents directly in the context
- No need for --yolo flag for read-only analysis
- Gemini's context window can handle entire codebases that would overflow Claude's context
- When checking implementations, be specific about what you're looking for to get accurate results



## Overview

This is Youwei Xiao's personal academic website built with Jekyll and the al-folio theme. The site serves as a technical blog, portfolio, and academic CV featuring content about programming language research, particularly e-graphs, egglog, compiler optimization, and related topics.

## Key Commands

### Development

- **Setup**: `bash ./install.sh` - Installs all dependencies (Ruby gems and npm packages)
- **Local server**: `./localdeploy.sh` - Starts Jekyll server with live reload on port 4000, builds Marp slides
- **New blog post**: `./newpost.sh "Post Title"` - Creates a new blog post with proper frontmatter

### Build & Deploy

- **Build site**: `bundle exec jekyll build` - Builds the site to `_site/` directory
- **Clean build**: `bundle exec jekyll clean` - Removes the `_site/` directory
- **Deploy**: Automatic via GitHub Actions when pushing to main branch

### Slides

- **Build slides**: `npm exec -c "marp -c marp.config.mjs -I _slide/ -o assets/slide/"` - Converts Marp markdown to HTML
- **Convert to images**: `./marpimg.sh <slide.md>` - Converts slide to PNG images

## Architecture

### Content Structure

- **Blog posts** (`_posts/`): Technical articles in Markdown with Jekyll frontmatter. Posts use yesterday's date to avoid "future date" errors
- **Static pages** (`_pages/`): About, blog index, and other permanent pages
- **Slides** (`_slide/`): Marp-based presentation slides that get converted to HTML/images
- **Bibliography** (`_bibliography/`): BibTeX files for academic references

### Jekyll Configuration

- **Theme**: al-folio academic theme with custom SCSS modifications
- **Plugins**: Jekyll Scholar for bibliography, custom Ruby plugins in `_plugins/`
- **Collections**: News and projects collections configured in `_config.yml`

### Build Pipeline

1. **Local development**: Jekyll serves with `--lsi` flag for related posts
2. **Slide processing**: Marp CLI converts markdown slides to HTML/images before Jekyll build
3. **Production build**: GitHub Actions workflow handles deployment with CSS purging

### Key Dependencies

- **Ruby/Jekyll**: Static site generation (Ruby 3.3.5)
- **Marp**: Markdown-based slide presentations
- **Prettier**: Code formatting with Liquid plugin
- **npm packages**: See `package.json` for Marp and formatting tools

## Important Notes

- The site deploys automatically to GitHub Pages from the main branch
- Local development kills any process on port 4000 before starting
- Blog posts use yesterday's date to prevent "future date" build errors
- Slide images are copied to `assets/slide/` during build
- When composing a post, please use relaxed, humorous, and insightful tone. We're writing personal blog, not academic paper.