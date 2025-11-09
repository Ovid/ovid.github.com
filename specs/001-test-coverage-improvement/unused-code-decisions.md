# Unused Code Decisions

**Date**: 2025-11-09  
**Feature**: 001-test-coverage-improvement  
**Purpose**: Document decisions on how to handle potentially unused methods identified by usage analysis

## Summary

Usage analysis identified potentially unused methods across several modules. However, many methods flagged as "potentially unused" are actually called from Template Toolkit templates, which the static analysis tool cannot detect. This document categorizes each method and provides clear recommendations.

## Decision Categories

- **KEEP & TEST**: Method is used (either in code or templates), must write tests
- **KEEP & SKIP**: Method is used only in templates, integration tests are sufficient
- **INVESTIGATE**: Unclear usage, needs manual verification
- **CONSIDER REMOVAL**: Appears truly unused, candidate for deletion

## Module-by-Module Decisions

### 1. Template/Plugin/Ovid.pm

**File**: `lib/Template/Plugin/Ovid.pm`  
**Current Coverage**: 36.1% statement

| Method | Decision | Rationale | Action |
|--------|----------|-----------|--------|
| `image_type` | KEEP & TEST | Used in `root/include/header.tt` for og:image:type meta tags | Add unit tests |
| `tags` | INVESTIGATE | Not found in templates, may be unused | Check template usage manually |
| `tags_for_url` | KEEP & TEST | Used in `root/include/tags_for_article.tt` | Add unit tests |
| `tags_by_weight` | KEEP & TEST | Used in `root/include/links.tt` | Add unit tests |
| `has_articles_for_tag` | INVESTIGATE | Not found in templates, may be unused | Check template usage manually |
| `name_for_tag` | INVESTIGATE | Not found in templates, may be unused | Check template usage manually |
| `files_for_tag` | INVESTIGATE | Not found in templates, may be unused | Check template usage manually |
| `title_for_tag_file` | INVESTIGATE | Not found in templates, may be unused | Check template usage manually |
| `note` | KEEP & TEST | Used in multiple articles (e.g., `why-is-object-oriented-programming-bad.tt`) | Add unit tests for footnote generation |
| `youtube` | KEEP & TEST | Heavily used in templates (`publicspeaking.tt`, `videos.tt2markdown`, multiple articles) | Add unit tests |
| `get_footnotes` | KEEP & TEST | Used in `root/include/footer.tt` | Add unit tests |
| `has_footnotes` | KEEP & TEST | Used in `root/include/footer.tt` for conditional rendering | Add unit tests |
| `is_blog` | INVESTIGATE | Not found in templates or code, may be unused | Check if this is legacy code |

**Priority**: HIGH - This is the lowest coverage module and the Template Plugin is critical infrastructure

### 2. Less/Pager.pm

**File**: `lib/Less/Pager.pm`  
**Current Coverage**: 78.7% statement

| Method | Decision | Rationale | Action |
|--------|----------|-----------|--------|
| `next` | INVESTIGATE | May be confused with `next_post`, or may be legacy pagination method | Review code and determine if needed |
| `all` | INVESTIGATE | Could be for returning all items, check if templates use it | Search templates for usage |

**Priority**: MEDIUM - Already good coverage, but `next` and `all` should be clarified

### 3. Ovid/Template/File/Collection.pm

**File**: `lib/Ovid/Template/File/Collection.pm`  
**Current Coverage**: 88.2% statement

| Method | Decision | Rationale | Action |
|--------|----------|-----------|--------|
| `next` | INVESTIGATE | Iterator method, may be used in templates via FOREACH | Check template iteration patterns |
| `reset` | INVESTIGATE | Iterator reset, typically paired with `next` | Check if iterator pattern is used |

**Priority**: LOW - Already high coverage, these may be iterator methods

### 4. Ovid/Template/File/FindCode.pm

**File**: `lib/Ovid/Template/File/FindCode.pm`  
**Current Coverage**: 93.2% statement

| Method | Decision | Rationale | Action |
|--------|----------|-----------|--------|
| `is_end_marker` | KEEP & TEST | Likely used internally for code block parsing | Add tests for edge cases |
| `parse` | INVESTIGATE | May be a main entry point not detected by analysis | Review calling patterns |

**Priority**: LOW - Already excellent coverage

### 5. Ovid/Template/File.pm

**File**: `lib/Ovid/Template/File.pm`  
**Current Coverage**: 82.9% statement

| Method | Decision | Rationale | Action |
|--------|----------|-----------|--------|
| `next` | INVESTIGATE | May be iterator method used in templates | Check template iteration |
| `rewrite` | INVESTIGATE | Could be legacy or administrative function | Check if used in build scripts |

**Priority**: MEDIUM - Needs to reach 90% coverage

### 6. Template/Plugin/Config.pm

**File**: `lib/Template/Plugin/Config.pm`  
**Current Coverage**: 100.0% statement

| Method | Decision | Rationale | Action |
|--------|----------|-----------|--------|
| (one method flagged) | KEEP - NO ACTION | Already 100% coverage, method is tested | None |

**Priority**: NONE - Already at target coverage

### 7. Text/Markdown/Blog.pm

**File**: `lib/Text/Markdown/Blog.pm`  
**Current Coverage**: 87.6% statement

| Method | Decision | Rationale | Action |
|--------|----------|-----------|--------|
| `blogdown` | INVESTIGATE | May be legacy or alternative entry point | Check usage in build process |

**Priority**: MEDIUM - Needs to reach 90% coverage

## Template-Called Methods

The following methods are confirmed to be called from Template Toolkit templates (not detectable by static analysis):

### Critical Template Methods (Must Test)

1. **`Ovid.youtube(id)`** - Embeds YouTube videos
   - Used in: `publicspeaking.tt`, `videos.tt2markdown`, multiple articles
   - **HIGH PRIORITY** - Core functionality for content

2. **`Ovid.note(text)`** - Creates footnotes
   - Used in: Multiple article templates
   - **HIGH PRIORITY** - Important for article annotations

3. **`Ovid.has_footnotes`** / **`Ovid.get_footnotes`**
   - Used in: `root/include/footer.tt`
   - **HIGH PRIORITY** - Footnote rendering system

4. **`Ovid.image_type(url)`**
   - Used in: `root/include/header.tt`
   - **MEDIUM PRIORITY** - Meta tag generation

5. **`Ovid.tags_for_url(url)`**
   - Used in: `root/include/tags_for_article.tt`
   - **HIGH PRIORITY** - Tag system

6. **`Ovid.tags_by_weight`**
   - Used in: `root/include/links.tt`
   - **HIGH PRIORITY** - Tag cloud/navigation

## Testing Strategy

### Phase 1: Template-Called Methods (Highest Priority)

These methods MUST be tested because they're actively used in production templates:

1. `youtube` - Test YouTube embed generation
2. `note` / `has_footnotes` / `get_footnotes` - Test footnote system
3. `tags_for_url` / `tags_by_weight` - Test tag system
4. `image_type` - Test image meta tag generation

### Phase 2: Investigate Before Testing

These methods need manual verification before writing tests:

1. Check template files for usage of `next`, `all`, `reset` (iterator methods)
2. Search build scripts for `rewrite`, `blogdown`, `parse`
3. Review tag methods: `has_articles_for_tag`, `name_for_tag`, `files_for_tag`, `title_for_tag_file`

### Phase 3: Consider Removal

After investigation, if methods are confirmed unused:

1. Add deprecation warnings with suggested alternatives
2. Document in changelog
3. Remove in next major version (not in this feature)

## Manual Verification Checklist

- [ ] Search all `.tt` and `.tt2markdown` files for each "INVESTIGATE" method
- [ ] Check `bin/rebuild` and other build scripts for method calls
- [ ] Review git history for when methods were last modified
- [ ] Consider if methods might be part of public API used by external code

## Recommendations

1. **Do NOT remove any code in this feature** - Focus on testing what exists
2. **Prioritize template-called methods** - These are proven to be in use
3. **Add integration tests for template rendering** - Will catch template-method interactions
4. **Document findings in TODO comments** - As per Task T026

## Next Steps (Task T026)

Add TODO comments to source files for each method:

```perl
# TODO (Coverage Improvement 001): This method appears unused in Perl code
# but may be called from templates. Verify usage before considering removal.
# See: specs/001-test-coverage-improvement/unused-code-decisions.md
sub potentially_unused_method {
    ...
}
```

For confirmed template usage:

```perl
# NOTE: Called from Template Toolkit templates (e.g., root/include/footer.tt)
# Static analysis cannot detect this usage pattern.
sub template_called_method {
    ...
}
```

## Appendix: Static Analysis Limitations

The usage analysis tool has the following limitations:

1. **Cannot detect Template Toolkit calls**: Methods called as `[% Ovid.method() %]` in templates
2. **Cannot detect dynamic calls**: `$obj->$method_name` style invocations
3. **Cannot detect external usage**: If this code is used by other projects
4. **May miss string eval**: `eval "package->method()"`

Always combine static analysis with:
- Template file searches (`grep -r "\.method_name" root/ include/`)
- Git history (`git log -S "method_name"`)
- Manual code review
