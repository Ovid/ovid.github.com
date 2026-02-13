# Separating Template::Plugin::Ovid Concerns

**Date:** 2025-12-18
**Status:** Design Complete - Ready for Implementation
**Author:** Curtis "Ovid" Poe

## Problem Statement

`lib/Template/Plugin/Ovid.pm` conflates multiple concerns:
- Template rendering utilities (footnotes, collapsible sections, embeds)
- Tag/taxonomy queries
- Pagination delegation

This violates single responsibility principle and makes the code harder to test and maintain.

## Solution Overview

Extract concerns into separate, focused plugins:
- **Keep:** `Template::Plugin::Ovid` for rendering utilities
- **New:** `Template::Plugin::Ovid::Tags` for tag operations
- **Direct Use:** `Less::Pager` via thin wrapper for pagination

## Current Usage Analysis

### Template Method Usage (from git grep analysis)
```
92 add_note      (footnotes)
54 youtube       (video embeds)
36 collapse      (collapsible sections)
31 note          (footnote alias)
27 cite          (external links)
 6 link          (internal links)
 2 name_for_tag  (tag display names)
 1 this_post     (pagination)
 1 image_type    (MIME types)
```

### Include File Usage
- `root/include/footer.tt` - uses `has_footnotes()`, `get_footnotes()`
- `root/include/tag-cloud.tt` - uses `tags_by_weight()`, `weight_for_tag()`, `name_for_tag()`
- `root/include/pager.tt` - uses `prev_post()`, `next_post()`
- `root/include/image.tt` - uses `describe_image()`

### Dead Code (not used anywhere)
- `tags()`, `tags_for_url()`, `has_articles_for_tag()`
- `count_for_tag()`, `files_for_tag()`, `title_for_tag_file()`
- `is_blog()`

## Architecture

### File Structure
```
lib/Template/Plugin/
├── Ovid.pm              # Core rendering utilities
├── Ovid/
│   └── Tags.pm          # Tag queries and operations
└── Pager.pm             # Thin wrapper for Less::Pager
```

### Responsibility Split

#### Template::Plugin::Ovid (Refactored)
**Purpose:** Template rendering enhancements

**Methods to keep:**
- `add_note($note)` - Add footnote
- `note($note)` - Alias for add_note
- `get_footnotes()` - Retrieve footnotes for footer
- `has_footnotes()` - Check if footnotes exist
- `collapse($short, $full)` - Collapsible sections
- `youtube($id)` - YouTube embeds
- `cite($url, $name)` - External links with icon
- `link($url, $name)` - Internal links
- `image_type($image)` - MIME type detection
- `describe_image($image)` - AI-generated alt text

**Constructor (simplified):**
```perl
sub new ( $class, $context ) {
    bless {
        _CONTEXT                   => $context,
        footnote_number            => 1,
        footnote_names             => {},
        footnotes                  => [],
        collapsible_section_number => 1,
    }, $class;
}
```

**Dependencies removed:**
- `Less::Pager` (no longer needed)
- `Ovid::Template::File::Collection` (only used for tags)
- `Mojo::JSON` (tagmap moves to Tags plugin)
- `List::Util` (only used for tag weights)

#### Template::Plugin::Ovid::Tags (New)
**Purpose:** Tag/taxonomy queries

**File:** `lib/Template/Plugin/Ovid/Tags.pm`

**Constructor:**
```perl
sub new ( $class, $context ) {
    my $tagmap_file = config()->{tagmap_file};
    my $json = path($tagmap_file)->slurp_utf8;

    bless {
        _CONTEXT => $context,
        tagmap   => decode_json($json),
    }, $class;
}
```

**Methods:**
- `tags_by_weight()` - Returns tags sorted by article count (for tag cloud)
- `weight_for_tag($tag)` - Calculates display weight (1-9 scale)
- `name_for_tag($tag)` - Returns display name from config

**Dependencies:**
- `Less::Config` - for config access
- `Mojo::JSON` - for tagmap parsing
- `List::Util` - for min/max in weight calculation
- `Path::Tiny` - for file reading

**Usage:**
```tt
[% USE tags = Ovid.Tags %]
[% FOREACH tag IN tags.tags_by_weight %]
  <a href="/tags/[% tag %].html"
     data-weight="[% tags.weight_for_tag(tag) %]">
    [% tags.name_for_tag(tag) %]
  </a>
[% END %]
```

#### Template::Plugin::Pager (Thin Wrapper)
**Purpose:** Allow templates to use Less::Pager with TT syntax

**File:** `lib/Template/Plugin/Pager.pm`

**Implementation:**
```perl
package Template::Plugin::Pager;
use base 'Template::Plugin';
use Less::Pager;

sub new ( $class, $context, $params ) {
    return Less::Pager->new($params->%*);
}

1;
```

**Usage:**
```tt
[% USE pager = Pager(type => type) %]
[% prev = pager.prev_post(type, slug) %]
[% next = pager.next_post(type, slug) %]
```

## Migration Plan

### Files Requiring Updates

#### 1. root/include/tag-cloud.tt
```tt
# Before:
[% FOREACH tag IN Ovid.tags_by_weight %]
    <a data-weight="[% Ovid.weight_for_tag(tag) %]">
        [% Ovid.name_for_tag(tag) %]
    </a>
[% END %]

# After:
[% USE tags = Ovid.Tags %]
[% FOREACH tag IN tags.tags_by_weight %]
    <a data-weight="[% tags.weight_for_tag(tag) %]">
        [% tags.name_for_tag(tag) %]
    </a>
[% END %]
```

#### 2. root/include/pager.tt
```tt
# Before:
[% prev = Ovid.prev_post(type, slug) %]
[% next = Ovid.next_post(type, slug) %]

# After:
[% USE pager = Pager(type => type) %]
[% prev = pager.prev_post(type, slug) %]
[% next = pager.next_post(type, slug) %]
```

#### 3. Templates using name_for_tag directly (2 files)
Update to use `[% USE tags = Ovid.Tags %]` and change calls to `tags.name_for_tag()`

#### 4. Templates using this_post (1 file)
Update to use `[% USE pager = Pager %]` syntax

### Unchanged Templates
- 250+ templates using `Ovid.add_note()`, `Ovid.collapse()`, `Ovid.youtube()`, etc.
- `root/include/footer.tt` (footnote rendering)
- Templates using `Ovid.cite()` or `Ovid.link()`
- `root/include/image.tt` (using `describe_image()`)

## Implementation Steps

1. **Create Template::Plugin::Ovid::Tags**
   - Implement new plugin with tag methods
   - Add tests
   - Verify POD documentation

2. **Create Template::Plugin::Pager**
   - Implement thin wrapper
   - Add tests

3. **Update Include Templates**
   - Update `root/include/tag-cloud.tt`
   - Update `root/include/pager.tt`
   - Find and update templates with direct `name_for_tag()` calls
   - Find and update templates with `this_post()` calls

4. **Refactor Template::Plugin::Ovid**
   - Remove tag-related methods
   - Remove pagination methods
   - Remove dead code (7 unused methods)
   - Simplify constructor
   - Remove unused dependencies
   - Update POD documentation
   - Update tests

5. **Run Full Test Suite**
   - Verify all tests pass
   - Check test coverage
   - Run full site rebuild
   - Verify generated HTML is identical

6. **Git Commit**
   - Commit with descriptive message
   - Reference this design document

## Expected Outcomes

### Code Quality
- `Template::Plugin::Ovid` shrinks from 272 lines to ~160 lines
- Each plugin has single, clear responsibility
- Dependencies reduced in main plugin
- Dead code eliminated

### Testing
- Easier to mock tag operations separately
- Pagination testing isolated to wrapper
- Rendering utilities testable independently

### Maintenance
- Clear separation makes future changes easier
- Template code documents its dependencies via USE statements
- Easier to identify unused functionality

## Risks & Mitigations

### Risk: Breaking existing templates
**Mitigation:** Migration is backward compatible. Old code continues working until we remove old methods from Ovid.pm in step 4.

### Risk: Missing template usages
**Mitigation:** Git grep analysis identified all usages. Full test suite and rebuild will catch any missed cases.

### Risk: describe_image was almost deleted
**Mitigation:** Thorough search of bin/ and lib/ directories prevented this. Always verify "dead" code before deletion.

## Success Criteria

- [ ] All tests pass
- [ ] Full site rebuild succeeds
- [ ] Generated HTML identical to pre-refactor
- [ ] Code coverage maintained or improved
- [ ] POD documentation complete for all plugins
- [ ] Git commit with clean history

## References

- Original file: `lib/Template/Plugin/Ovid.pm`
- Usage analysis: Git grep of `root/`, `bin/`, `lib/`
- Related: `Less::Pager`, `Less::Config`, `Ovid::Site::AI::Images`
