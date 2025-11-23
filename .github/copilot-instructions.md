# website Development Guidelines

Auto-generated from all feature plans. Last updated: 2025-11-09

## Active Technologies
- Perl 5.40+ (project standard per constitution) + Template Toolkit 2.x, Dialog.js (client-side for JS mode) (002-footnote-noscript-fallback)
- N/A (static site generation, no database for this feature) (002-footnote-noscript-fallback)
- Perl 5.40+ (per Constitution Principle VII) + Template::Toolkit 3.102+, Text::Markdown::Blog (via Template::Plugin::Blogdown) (004-collapsible-sections)
- N/A (static site generation, no runtime database for this feature) (004-collapsible-sections)
- Perl 5.40+ + Template::Toolkit 3.102+, HTML::TokeParser::Simple, Text::Markdown::Blog (005-utf8-rebuild-warnings)
- SQLite (build-time data only, in `db/ovid.db`) (005-utf8-rebuild-warnings)
- Perl 5.40+ + Dancer2, Template::Toolkit, Text::Markdown::Blog (006-blogdown-live-editor)
- Filesystem (source files), SQLite (read-only build data) (006-blogdown-live-editor)
- Perl 5.40+ + Dancer2, Template Toolkit 2, Browser::Open, Imager (for PNG/GIF/JPG resizing) (007-editor-image-upload)
- Filesystem (root/, static/), YAML config via `Less::Config`, SQLite read-only for builds (007-editor-image-upload)
- JavaScript (ES6+), Perl 5.40+ (Backend existing) + CodeMirror 5.65.16 (Client-side editor) (008-editor-vim-bindings)
- `localStorage` (Client-side preference persistence) (008-editor-vim-bindings)
- Perl 5.40+ (backend), JavaScript ES6 (frontend), CodeMirror 5.65.16 + Vendored CodeMirror 5.65.16 core, `keymap/vim.js`; existing `saveContent()` logic; `localStorage` (008-editor-vim-bindings)
- Client-side only (`localStorage: vimMode`); no new server storage (008-editor-vim-bindings)
- Perl 5.40+ (Backend), JavaScript ES6+ (Frontend), HTML5, CSS3 + Template Toolkit (Server-side), CodeMirror (Client-side Editor) (009-editor-dropdown-menu)
- `localStorage` (Client-side preferences for theme, vim mode, syntax highlight) (009-editor-dropdown-menu)

- Perl 5.40+ + Devel::Cover, Test::Most, Type::Tiny, Getopt::Long, SQLite (001-test-coverage-improvement)

## Project Structure

```text
lib/                    # Perl modules (Ovid::*, Less::*, Template::Plugin::*)
bin/                    # CLI scripts (article, rebuild, etc.)
t/                      # Test files (mirrors lib/ structure)
root/                   # Template Toolkit templates
include/                # Template Toolkit includes
static/                 # Static assets (images, CSS, JS)
config/                 # Configuration files
db/                     # SQLite databases for build-time data
fixtures/               # Test fixtures
articles/               # Generated article HTML
blog/                   # Generated blog HTML
tags/                   # Generated tag pages
tmp/                    # Build artifacts (excluded from version control)
cover_db/               # Coverage reports (excluded from version control)
```

## Commands

# Environment setup (required before any work)
source ~/.bash_profile  # Activates perlbrew and Perl 5.40+

# Install dependencies
cpanm --installdeps . --with-configure --with-develop --with-all-features

# Create new article/blog post
perl bin/article -type=article "Article Title"
perl bin/article -type=blog "Blog Title"

# Build site
perl bin/rebuild

# Run tests
prove -l t/

# Run tests with coverage
cover -test

# Generate HTML coverage report
cover -report html -outputdir coverage-report

# Format code with perltidy
perltidy --profile=.perltidyrc lib/**/*.pm bin/*

# Local development server
http_this  # Serves site at http://127.0.0.1:7007/

## Code Style

Perl 5.40+: Follow standard conventions from constitution.md
- Use `use v5.40;` or higher in all modules
- Subroutine signatures required
- Format all code with perltidy using .perltidyrc
- 90%+ test coverage (Test::Most)
- Full POD documentation for all modules
- All tasks must pass entire test suite before completion

## Recent Changes
- 009-editor-dropdown-menu: Added Perl 5.40+ (Backend), JavaScript ES6+ (Frontend), HTML5, CSS3 + Template Toolkit (Server-side), CodeMirror (Client-side Editor)
- 008-editor-vim-bindings: Added Perl 5.40+ (backend), JavaScript ES6 (frontend), CodeMirror 5.65.16 + Vendored CodeMirror 5.65.16 core, `keymap/vim.js`; existing `saveContent()` logic; `localStorage`
- 008-editor-vim-bindings: Added JavaScript (ES6+), Perl 5.40+ (Backend existing) + CodeMirror 5.65.16 (Client-side editor)


<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
