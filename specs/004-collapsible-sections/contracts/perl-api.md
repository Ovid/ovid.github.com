# API Contract: Template::Plugin::Ovid.collapse()

**Feature**: 004-collapsible-sections  
**Version**: 1.0.0  
**Date**: 2025-11-16

## Method Signature

```perl
sub collapse ( $self, $short_description, $full_content )
```

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `$self` | Template::Plugin::Ovid | Yes | Plugin instance (implicit in TT method call) |
| `$short_description` | String | Yes | Summary text displayed when collapsed; shown both collapsed and expanded |
| `$full_content` | String | Yes | Detailed content shown only when expanded; processed through blogdown |

### Return Value

**Type**: String (HTML)

**Description**: Returns a complete HTML structure containing both JavaScript-enabled interactive elements and noscript fallback rendering.

**Structure**:
```html
<div class="collapsible-section">
    <!-- Interactive trigger (JS-enabled) -->
    <div class="collapsible-trigger" ...>{short_description}</div>
    <!-- Content (hidden by default) -->
    <div class="collapsible-content" ...>{processed_full_content}</div>
</div>
<noscript>
    <!-- Fallback (always visible) -->
    <div class="collapsible-section-noscript">...</div>
</noscript>
```

### Exceptions

| Exception | Condition | Error Message |
|-----------|-----------|---------------|
| `croak()` | `$short_description` is undefined | `"collapse() requires short_description parameter"` |
| `croak()` | `$short_description` is empty or whitespace-only | `"collapse() requires short_description parameter"` |
| `croak()` | `$full_content` is undefined | `"collapse() requires full_content parameter"` |
| `croak()` | `$full_content` is empty or whitespace-only | `"collapse() requires full_content parameter"` |

**Error Handling**: All errors are fatal during build time (template processing). This prevents invalid HTML from being generated.

## Template Toolkit Usage

### Basic Example

```tt
[% USE Ovid %]

<article>
    <h1>My Article</h1>
    
    <p>Main content here.</p>
    
    [% Ovid.collapse(
        "Click to see implementation details",
        "The implementation uses a recursive algorithm with memoization for optimal performance."
    ) %]
    
    <p>More content.</p>
</article>
```

### With Blogdown Syntax

```tt
[% Ovid.collapse(
    "Example Code",
    "~~~perl
my \$result = calculate_total(\$items);
say \$result;
~~~"
) %]
```

### Multiple Sections

```tt
[% Ovid.collapse("Section 1", "Details for section 1") %]

[% Ovid.collapse("Section 2", "Details for section 2") %]

[% Ovid.collapse("Section 3", "Details for section 3") %]
```

Each section gets a unique ID automatically.

## HTML Output Contract

### Generated HTML Structure

```html
<!-- Container -->
<div class="collapsible-section">
    
    <!-- Trigger (role=button for accessibility) -->
    <div class="collapsible-trigger"
         id="collapsible-trigger-{N}"
         role="button"
         tabindex="0"
         aria-expanded="false"
         aria-controls="collapsible-content-{N}"
         aria-label="Expand: {short_description}">
        
        <!-- Icon (chevron-down when collapsed, chevron-up when expanded) -->
        <i class="fa fa-chevron-down collapsible-icon" aria-hidden="true"></i>
        
        <!-- Short description text -->
        <span class="collapsible-short">{short_description}</span>
    </div>
    
    <!-- Content region (hidden by default via CSS) -->
    <div id="collapsible-content-{N}"
         class="collapsible-content"
         role="region"
         aria-labelledby="collapsible-trigger-{N}">
        {processed_full_content}
    </div>
    
</div>

<!-- NoScript fallback (always visible when JS disabled) -->
<noscript>
    <div class="collapsible-section-noscript">
        <div class="collapsible-short-noscript">
            <strong>{short_description}</strong>
        </div>
        <div class="collapsible-content-noscript">
            {processed_full_content}
        </div>
    </div>
</noscript>
```

### ID Generation

- `{N}` is replaced with sequential number starting from 1
- Each call to `collapse()` increments the counter
- IDs are unique within a single page render
- Pattern: `collapsible-trigger-1`, `collapsible-content-1`, `collapsible-trigger-2`, etc.

### ARIA Attributes (Accessibility Contract)

| Attribute | Element | Value | Purpose |
|-----------|---------|-------|---------|
| `role="button"` | `.collapsible-trigger` | Fixed | Indicates interactive button behavior |
| `tabindex="0"` | `.collapsible-trigger` | Fixed | Makes trigger keyboard-focusable |
| `aria-expanded` | `.collapsible-trigger` | `"false"` (initial) | Indicates collapsed state; toggled by JS |
| `aria-controls` | `.collapsible-trigger` | `collapsible-content-{N}` | Links to controlled content region |
| `aria-label` | `.collapsible-trigger` | `"Expand: {short_description}"` | Provides screen reader context |
| `aria-labelledby` | `.collapsible-content` | `collapsible-trigger-{N}` | Associates content with trigger |
| `aria-hidden="true"` | Icon `<i>` | Fixed | Hides decorative icon from screen readers |
| `role="region"` | `.collapsible-content` | Fixed | Marks content as landmark region |

### CSS Classes (Styling Contract)

| Class | Element | Purpose |
|-------|---------|---------|
| `.collapsible-section` | Container `<div>` | Wraps entire collapsible section |
| `.collapsible-trigger` | Trigger `<div>` | Clickable header area |
| `.collapsible-icon` | Icon `<i>` | Font Awesome chevron icon |
| `.collapsible-short` | Text `<span>` | Short description text |
| `.collapsible-content` | Content `<div>` | Full content area (hidden by default) |
| `.expanded` | Content `<div>` | Added by JS when expanded (makes visible) |
| `.collapsible-section-noscript` | NoScript container | Fallback section wrapper |
| `.collapsible-short-noscript` | NoScript header | Fallback short description |
| `.collapsible-content-noscript` | NoScript content | Fallback full content |

## JavaScript API Contract

### Event Listeners

JavaScript in `static/js/collapsible.js` will:

1. Find all `.collapsible-trigger` elements on page load
2. Attach `click` event listener to each trigger
3. Attach `keydown` event listener to each trigger (for Enter/Space keys)

### Event Handling Behavior

When trigger is clicked or activated via keyboard:

1. Read current `aria-expanded` value
2. Toggle `aria-expanded` between `"true"` and `"false"`
3. Toggle `.expanded` class on corresponding content element
4. Toggle icon class: `.fa-chevron-down` ↔ `.fa-chevron-up`

### JavaScript State Contract

| State | aria-expanded | .expanded class | Icon class | Content visibility |
|-------|---------------|-----------------|------------|-------------------|
| Collapsed (initial) | `"false"` | Absent | `.fa-chevron-down` | Hidden (CSS: `display: none`) |
| Expanded | `"true"` | Present | `.fa-chevron-up` | Visible (CSS: `display: block`) |

## CSS Contract

### Required Styles (static/css/collapsible.css)

```css
/* JavaScript-enabled: hide content by default */
.collapsible-content {
    display: none;
}

/* JavaScript-enabled: show when expanded */
.collapsible-content.expanded {
    display: block;
}

/* NoScript fallback: always show content, indented */
noscript .collapsible-content-noscript {
    display: block;
    margin-left: 2em;
    border-left: 3px solid #ccc;
    padding-left: 1em;
}
```

## Blogdown Processing Contract

### Input Processing

The `$full_content` parameter is processed through `Template::Plugin::Blogdown->filter()` before inclusion in HTML.

**Supported Syntax** (from Text::Markdown::Blog):
- Triple-tilde code fences: ` ~~~perl ... ~~~ `
- Smart quotes: `"text"` → `"text"`
- External links: Auto-adds `target="_blank"` and external link icon
- Tables: MultiMarkdown syntax
- Standard Markdown: headers, lists, emphasis, links, etc.

**Processing Order**:
1. Validate `$full_content` (non-empty, non-whitespace)
2. Pass to `Template::Plugin::Blogdown->filter($full_content)`
3. Receive processed HTML
4. Insert into `.collapsible-content` div

## Progressive Enhancement Contract

### With JavaScript Enabled

- Content starts collapsed (CSS: `display: none`)
- User clicks trigger to expand
- JavaScript toggles `.expanded` class
- Content becomes visible
- Icon changes from chevron-down to chevron-up
- ARIA state updates for screen readers

### With JavaScript Disabled

- `<noscript>` block renders fallback HTML
- Both short description and full content visible
- Content indented for visual hierarchy
- No interactive behavior
- Trigger visible but non-functional (CSS removes hover/cursor styles)

## Compatibility Requirements

### Browser Support

- Modern browsers only (Chrome, Firefox, Safari, Edge)
- No IE11 support required
- Requires CSS class toggle support
- Requires `querySelectorAll`, `addEventListener`, `classList` APIs

### Screen Reader Support

- NVDA (Windows)
- JAWS (Windows)
- VoiceOver (macOS, iOS)
- Must announce state changes ("collapsed"/"expanded")

### Keyboard Navigation

- `Tab`: Focus trigger
- `Enter` or `Space`: Toggle expansion
- Screen reader shortcuts work as expected

## Testing Contract

### Unit Test Requirements

```perl
# t/template/plugin/ovid-collapse.t

use Test::Most;

subtest 'Basic functionality' => sub {
    # Test valid inputs return HTML
    # Test unique IDs generated
    # Test blogdown processing applied
};

subtest 'Error conditions' => sub {
    # Test empty short_description throws error
    # Test whitespace-only full_content throws error
    # Test undefined parameters throw errors
};

subtest 'Multiple sections' => sub {
    # Test sequential numbering
    # Test ID uniqueness
    # Test independent state
};

subtest 'ARIA compliance' => sub {
    # Test all required ARIA attributes present
    # Test aria-controls matches content ID
    # Test aria-labelledby matches trigger ID
};

subtest 'NoScript rendering' => sub {
    # Test noscript block included
    # Test content duplicated correctly
};
```

### Integration Test Requirements

1. Render template with collapsible sections
2. Validate HTML5 output (Nu HTML Checker)
3. Verify ARIA attributes
4. Test with screen reader (manual or automated)
5. Test keyboard navigation
6. Verify CSS applies correctly
7. Verify JavaScript toggles work

## Versioning

**Current Version**: 1.0.0

**Breaking Changes Policy**:
- Method signature changes → Major version bump
- HTML structure changes → Major version bump (may break CSS/JS)
- CSS class name changes → Major version bump
- ARIA attribute changes → Major version bump
- New optional parameters → Minor version bump
- Bug fixes → Patch version bump

## Migration Guide

### From No Collapsible Sections

**Before**:
```tt
<p>Here's some extra detail that might distract from the main flow.</p>
```

**After**:
```tt
[% Ovid.collapse(
    "Click for extra details",
    "Here's some extra detail that might distract from the main flow."
) %]
```

### Combining with Footnotes

```tt
[% Ovid.collapse(
    "Implementation Notes",
    "The algorithm uses memoization.[% Ovid.add_note('See Cormen et al.') %]"
) %]
```

Both features work together seamlessly.

## Summary

This API contract defines:
- **Perl API**: `collapse($short_description, $full_content)` method signature
- **HTML Output**: Specific structure with ARIA attributes and CSS classes
- **JavaScript Behavior**: Event handling and state management
- **CSS Styling**: Required classes and progressive enhancement
- **Blogdown Processing**: Content transformation pipeline
- **Error Handling**: Build-time validation and clear error messages
- **Accessibility**: WCAG 2.1 Level AA compliance
- **Testing**: Comprehensive test coverage requirements

All contracts align with Constitution principles and established codebase patterns.
