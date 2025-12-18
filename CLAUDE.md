# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a personal static website built with Perl and Template Toolkit. Content is authored in a hybrid format called "blogdown" that combines Markdown prose with Template Toolkit directives. The site is generated entirely at build time with zero runtime dependencies.

**Core Technologies**:
- Perl 5.40+ with modern features (signatures, postfix dereferencing)
- Template Toolkit 2.x/3.x for templating
- Text::Markdown::Blog for Markdown processing
- SQLite for build-time metadata storage
- Dancer2 for the live editor server

## Development Commands

### Environment Setup
```bash
# CRITICAL: Run this in every new terminal session
source ~/.bash_profile  # Activates perlbrew and Perl 5.40+

# Verify correct Perl version
perl -v  # Should show 5.40 or higher

# Install all dependencies
cpanm --installdeps . --with-configure --with-develop --with-all-features
```

### Building the Site
```bash
# Full build (preprocesses files, runs ttree, executes tests)
perl bin/rebuild

# Build without running tests (not recommended)
perl bin/rebuild --notest

# Build single file only
perl bin/rebuild --file=root/blog/my-post.tt

# Release build (includes search engine generation)
perl bin/rebuild --release
```

### Creating Content
```bash
# Create new article
perl bin/article -type=article "Article Title"

# Create new blog post
perl bin/article -type=blog "Blog Post Title"

# Launch live editor for existing file
perl bin/launch root/articles/my-article.tt

# Launch editor on custom port
perl bin/launch --port=3001 root/blog/my-post.tt
```

### Testing
```bash
# Run all tests
prove -l t/

# Run single test file
prove -lv t/blogdown.t

# Generate coverage report
make coverage
# or
cover -test
cover -report html -outputdir coverage-report

# Clean coverage data
make clean
```

### Local Development Server
```bash
# Serve site locally (requires App::HTTPThis)
http_this
# Opens at http://127.0.0.1:7007/
```

### Code Formatting
```bash
# Format Perl code (uses .perltidyrc)
perltidy --profile=.perltidyrc lib/**/*.pm bin/*
```

### Database Management
```bash
# Deploy database migrations
sqitch deploy

# Revert migrations
sqitch revert

# Check migration status
sqitch status
```

## Architecture

### Build Pipeline

The rebuild process (`bin/rebuild` → `Ovid::Site`) follows this sequence:

1. **Preprocessing** (`Ovid::Template::File` & `Collection`):
   - Scans `root/` directory for `.tt` and `.tt2markdown` files
   - Extracts metadata (title, tags, date) from Template Toolkit preambles
   - Generates table of contents by parsing HTML headings (`{{TOC}}` markers)
   - Collects tags across all articles (`{{TAGS}}` markers)
   - Applies smart quotes, fixes code blocks, handles UTF-8
   - Writes processed files to `tmp/` directory

2. **Tag Template Generation**:
   - Creates tag index pages in `root/tags/` based on collected metadata
   - Builds tagmap JSON for client-side navigation

3. **RSS Feed Generation**:
   - Builds `article.rss` and `blog.rss` from article metadata using XML::RSS

4. **Article Pagination**:
   - Creates paginated index pages (`articles_2.html`, `blog_3.html`, etc.)
   - Uses `Less::Pager` for pagination logic

5. **Template Toolkit Processing** (`ttree`):
   - Runs Template Toolkit's ttree utility on `tmp/` directory
   - Processes all `.tt` files through Template::Plugin::Blogdown
   - Outputs final HTML to root directory (`articles/`, `blog/`)

6. **Sitemap Generation**:
   - Crawls generated HTML to build `sitemap.xml`

7. **Search Engine** (release builds only):
   - Generates WebAssembly-based search index using tinysearch

### Module Organization

**Core Site Generation** (`lib/Ovid/`):
- `Ovid::Site` - Main orchestrator for build pipeline
- `Ovid::Site::Utils` - Shared utilities (smart quotes, slug generation)
- `Ovid::Template::File` - Single template file processing
- `Ovid::Template::File::Collection` - Batch processing of template files
- `Ovid::Template::File::FindCode` - Code block extraction and syntax highlighting
- `Ovid::Types` - Type::Tiny type definitions for validation

**Live Editor** (`lib/Ovid/App/`):
- `Ovid::App::LiveEditor` - Dancer2 app for real-time preview
- `Ovid::Util::Image` - Image upload and resizing with Imager

**Template Plugins** (`lib/Template/Plugin/`):
- `Template::Plugin::Blogdown` - TT filter for Markdown processing
- `Template::Plugin::Ovid` - Custom directives (footnotes, notes, images)
- `Template::Plugin::Config` - Access to Less::Config settings

**Markdown Processing** (`lib/Text/`):
- `Text::Markdown::Blog` - Extended Markdown with smart quotes, code blocks

**Configuration/Utilities** (`lib/Less/`):
- `Less::Config` - YAML-based configuration loader
- `Less::Script` - Common imports for scripts
- `Less::Boilerplate` - Common imports for modules
- `Less::Pager` - Pagination logic

### Content Format (Blogdown)

Articles and blog posts use `.tt` or `.tt2markdown` files with this structure:

```tt
[%
    title            = 'Article Title';
    type             = 'article';  # or 'blog'
    slug             = 'url-slug';
    include_comments = 1;
    syntax_highlight = 1;
    date             = '2025-11-16';
    USE Ovid;
%]
[% WRAPPER include/wrapper.tt blogdown=1 -%]

{{TOC}}
{{TAGS perl programming testing}}

# Markdown Heading

Regular Markdown content with [inline links](https://example.com).

Use TT directives for dynamic features:[% Ovid.add_note('Footnote text here') %]

~~~perl
# Code blocks use triple-tilde fencing
my $code = "syntax highlighted";
~~~

[% END %]
```

**Key Features**:
- `{{TOC}}` generates table of contents from headings
- `{{TAGS tag1 tag2}}` declares article tags
- `[% Ovid.add_note('text') %]` creates footnotes
- Triple-tilde code blocks with optional language specifier
- Smart quotes applied automatically outside code
- External links auto-tagged with `target="_blank"`

### Database Schema

SQLite database at `db/ovid.db` stores build-time metadata:

**Tables**:
- `articles` - Metadata for all articles/blog posts (title, slug, description, type, sort_order)
- `article_types` - Lookup table (id, type: 'article' or 'blog')
- `images` - AI-generated image descriptions for accessibility

**Migration Tool**: Sqitch manages schema changes in `sqitch/deploy/` and `sqitch/revert/`

## Key Development Rules

### NON-NEGOTIABLE Principles

1. **Test Coverage**: Maintain 90%+ test coverage with Test::Most
   - Unit tests for all public methods
   - Integration tests for build workflows
   - Use real dependencies over mocks when possible

2. **CPAN Module Architecture**: Every feature must be a proper module
   - Full POD documentation (NAME, SYNOPSIS, DESCRIPTION, METHODS)
   - Clear namespace under `Ovid::` or project namespace
   - Declared dependencies in `cpanfile`

3. **Production Data Protection**: NEVER modify files in `db/` during tests
   - Use fixtures from `t/fixtures/` or temporary databases
   - Tests must be read-only on production data
   - `git status` should show no changes to `db/` after tests

4. **Modern Perl 5.40+**: Use modern syntax in all new code
   - `use v5.40;` in all modules
   - Subroutine signatures required: `sub foo ($x, $y)`
   - Postfix dereferencing: `$hashref->%*`, `$arrayref->@*`
   - Type constraints via Type::Tiny for public APIs

5. **Git Safety**: AI agents must NEVER run destructive git commands
   - Prohibited: `git push --force`, `git reset --hard`, `git clean -fd`, `git rebase`
   - Allowed: Read-only ops, safe commits, branches

6. **Development Scope**: Only modify these directories for features:
   - `lib/` - Perl modules
   - `bin/` - CLI scripts
   - `root/` - Template Toolkit templates
   - Do NOT modify: `articles/`, `blog/`, `static/`, `db/`, `tmp/`

### Code Quality Standards

- **CLI-First Design**: All functionality accessible via command-line with `Getopt::Long`
- **Accessible HTML5**: Generated HTML must be WCAG 2.1 Level AA compliant
- **Zero External Services**: Build must work offline (except opt-in features)
- **Format All Code**: Run `perltidy` with `.perltidyrc` before committing
- **Complete Tasks Fully**: Always run full test suite before marking tasks complete

## Testing Strategy

### Test Structure
- Test files in `t/` mirror module structure
- Fixtures in `t/fixtures/` for static test data
- Use `Test::Most` for all tests
- Mock only when necessary (external APIs, non-deterministic behavior)

### Running Specific Test Types
```bash
# Unit tests for specific module
prove -lv t/blogdown.t

# Integration tests
prove -lv t/integration/

# Coverage for specific file
cover -test -select lib/Ovid/Site.pm
```

## Common Development Workflows

### Adding a New Feature

1. Design as CPAN-style module with clear API
2. Write tests first (TDD approach)
3. Implement module to pass tests
4. Add CLI interface if user-facing
5. Update POD documentation
6. Run `cover -test` to verify 90%+ coverage
7. Run `perl bin/rebuild` to ensure no regressions
8. Update `cpanfile` if dependencies added
9. Format code: `perltidy --profile=.perltidyrc lib/**/*.pm`

### Debugging Build Issues

```bash
# Enable verbose output
perl bin/rebuild 2>&1 | tee build.log

# Test single file
perl bin/rebuild --file=root/blog/problematic-post.tt

# Check template syntax
ttree -f root/blog/problematic-post.tt

# Run debugger on specific module
perl -d -Ilib -MOvid::Site -e 'Ovid::Site->new->build'
```

### Working with the Live Editor

The live editor provides side-by-side preview while editing:

```bash
perl bin/launch root/articles/my-article.tt
```

**Features**:
- Real-time Markdown preview
- Image upload with automatic resizing (max 300KB)
- Vim mode toggle (persisted in localStorage)
- Syntax highlighting toggle
- Dark mode toggle
- File browser for all templates in `root/`

**Security**: Editor only allows editing files within `root/` directory

## Important Files

- `bin/rebuild` - Main build orchestrator
- `bin/article` - Create new article/blog post with metadata
- `bin/launch` - Start live editor server
- `lib/Ovid/Site.pm` - Core build pipeline logic
- `.perltidyrc` - Code formatting rules
- `cpanfile` - Dependency specifications
- `sqitch.conf` - Database migration configuration
- `.specify/memory/constitution.md` - Full project principles and governance

## Tips for Working with This Codebase

- **Always activate perlbrew first**: `source ~/.bash_profile`
- **Read before modifying**: Never propose changes to code you haven't read
- **Test incrementally**: Run tests for modules as you modify them
- **Respect the build order**: Some `Ovid::Site` methods must run in sequence
- **Use fixtures for tests**: Never write to `db/ovid.db` in tests
- **Check generated output**: View results at `http://127.0.0.1:7007/` after rebuild
- **Consult constitution**: When in doubt, check `.specify/memory/constitution.md`
