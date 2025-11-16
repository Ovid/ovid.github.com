# Data Model: Collapsible Sections

**Feature**: 004-collapsible-sections  
**Date**: 2025-11-16  
**Status**: Complete

## Overview

This document defines the data entities and their relationships for the collapsible sections feature. Since this is a static site generator feature, there are no runtime database entities. Instead, this models the data structures used during template processing and the resulting HTML output.

## Entities

### 1. CollapsibleSection (Template Processing State)

**Description**: Internal state maintained by `Template::Plugin::Ovid` during template processing to track collapsible sections.

**Lifecycle**: Created during template processing, discarded after page generation

**Attributes**:

| Attribute | Type | Required | Description | Validation |
|-----------|------|----------|-------------|------------|
| `number` | Integer | Yes | Sequential identifier for this section (1-based) | > 0, unique per page |
| `short_description` | String | Yes | Summary text displayed when collapsed | Non-empty, non-whitespace |
| `full_content` | String | Yes | Detailed content shown when expanded | Non-empty, non-whitespace |
| `trigger_id` | String | Yes | HTML ID for trigger element | `collapsible-trigger-{number}` |
| `content_id` | String | Yes | HTML ID for content element | `collapsible-content-{number}` |
| `processed_content` | String | Yes | Blogdown-processed full_content | Generated from full_content |

**State Transitions**: None (stateless within page context)

**Example**:
```perl
{
    number             => 1,
    short_description  => "Click to see implementation details",
    full_content       => "~~~perl\nsub example { ... }\n~~~",
    trigger_id         => "collapsible-trigger-1",
    content_id         => "collapsible-content-1",
    processed_content  => "<pre><code class=\"language-perl\">sub example { ... }</code></pre>",
}
```

### 2. CollapsibleHTML (Generated Output)

**Description**: The HTML structure output by the `collapse()` method, embedded in the generated static page.

**Lifecycle**: Generated during build, persists in static HTML files

**Structure**:
```html
<!-- Container -->
<div class="collapsible-section">
    
    <!-- Trigger (clickable header) -->
    <div class="collapsible-trigger"
         id="collapsible-trigger-{number}"
         role="button"
         tabindex="0"
         aria-expanded="false"
         aria-controls="collapsible-content-{number}"
         aria-label="Expand: {short_description}">
        <i class="fa fa-chevron-down collapsible-icon" aria-hidden="true"></i>
        <span class="collapsible-short">{short_description}</span>
    </div>
    
    <!-- Content (hidden by default in JS mode) -->
    <div id="collapsible-content-{number}"
         class="collapsible-content"
         role="region"
         aria-labelledby="collapsible-trigger-{number}">
        {processed_content}
    </div>
    
</div>

<!-- NoScript fallback (always visible) -->
<noscript>
    <div class="collapsible-section-noscript">
        <div class="collapsible-short-noscript">
            <strong>{short_description}</strong>
        </div>
        <div class="collapsible-content-noscript">
            {processed_content}
        </div>
    </div>
</noscript>
```

**ARIA Attributes**:
- `role="button"`: Trigger is an interactive button
- `tabindex="0"`: Trigger is keyboard-focusable
- `aria-expanded`: Indicates current state (false=collapsed, true=expanded)
- `aria-controls`: Links trigger to content region by ID
- `aria-label`: Provides context for screen readers
- `aria-labelledby`: Associates content with trigger
- `aria-hidden="true"`: Hides decorative icon from screen readers

### 3. PluginState (Template::Plugin::Ovid Instance)

**Description**: Extended state in the Template::Plugin::Ovid plugin instance to track collapsible sections across a template rendering session.

**Lifecycle**: Created when template processing begins, destroyed when template processing completes

**Existing Attributes** (for context):
- `_CONTEXT`: Template::Toolkit context object
- `footnote_number`: Counter for footnotes
- `footnote_names`: Hash of named footnotes
- `footnotes`: Array of footnote data
- `pager`: Less::Pager instance
- `tagmap`: Decoded JSON tag mapping

**New Attributes**:

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `collapsible_number` | Integer | Yes | Counter for generating unique collapsible section IDs (starts at 1) |

**Note**: Unlike footnotes, collapsibles don't accumulate data for footer rendering. Each section is self-contained and rendered inline.

## Relationships

### Template Processing Flow

```
Article Template (.tt2markdown)
    ↓
Template::Toolkit processes [% WRAPPER include/wrapper.html blogdown=1 %]
    ↓
Template::Toolkit encounters [% Ovid.collapse("short", "full") %]
    ↓
Template::Plugin::Ovid.collapse() method called
    ↓ (validates parameters)
    ↓
Increment collapsible_number counter
    ↓
Process full_content through Template::Plugin::Blogdown
    ↓
Generate CollapsibleHTML structure
    ↓
Return HTML string to template
    ↓
Continue template processing
    ↓
Final HTML output written to articles/ or blog/
```

### Runtime Interaction Flow (JavaScript-Enabled)

```
Page Load
    ↓
static/js/collapsible.js executes
    ↓
Finds all .collapsible-trigger elements
    ↓
Attaches click/keydown event listeners
    ↓
User clicks trigger or presses Enter/Space
    ↓
JavaScript toggles:
    - aria-expanded attribute (false ↔ true)
    - .expanded class on content element
    - icon class (fa-chevron-down ↔ fa-chevron-up)
    ↓
CSS shows/hides content based on .expanded class
    ↓
Screen reader announces state change
```

### NoScript Flow

```
Page Load (JavaScript disabled)
    ↓
Browser ignores <script> tags
    ↓
CSS rule: noscript .collapsible-content { display: block; }
    ↓
All content visible, indented
    ↓
Trigger element visible but non-interactive
    ↓
User scrolls/reads all content directly
```

## Data Validation Rules

### Input Validation (Build Time)

1. **short_description**:
   - MUST NOT be undefined
   - MUST NOT be empty string
   - MUST NOT be only whitespace (regex: `/\S/` must match)
   - MAY contain HTML (will be escaped if needed)
   - MAY contain Markdown (but won't be processed - only full_content gets blogdown)

2. **full_content**:
   - MUST NOT be undefined
   - MUST NOT be empty string
   - MUST NOT be only whitespace (regex: `/\S/` must match)
   - MAY contain blogdown syntax (will be processed)
   - MAY contain embedded TT directives (will be evaluated if not already processed)

### Generated ID Validation (Build Time)

1. **trigger_id and content_id**:
   - MUST be unique within the page
   - MUST match pattern: `collapsible-(trigger|content)-\d+`
   - MUST be valid HTML ID (no spaces, starts with letter or underscore)

### HTML Output Validation (Build Time)

1. **ARIA attributes**:
   - `aria-expanded` MUST be "true" or "false" (string, not boolean)
   - `aria-controls` MUST match an existing element ID
   - `aria-labelledby` MUST match an existing element ID

2. **CSS classes**:
   - MUST include `.collapsible-section` on container
   - MUST include `.collapsible-trigger` on trigger
   - MUST include `.collapsible-content` on content

## Error Conditions

### Build-Time Errors

| Error | Condition | Exception Message |
|-------|-----------|-------------------|
| Missing short_description | `$short_description` is undefined or whitespace-only | `"collapse() requires short_description parameter"` |
| Missing full_content | `$full_content` is undefined or whitespace-only | `"collapse() requires full_content parameter"` |
| Blogdown processing failure | `Template::Plugin::Blogdown->filter()` throws | (Propagate original error) |

### Runtime Errors (JavaScript)

These are logged to console but don't break page functionality:

| Error | Condition | Handling |
|-------|-----------|----------|
| Missing content element | `document.getElementById(contentId)` returns null | Log warning, skip this trigger |
| Invalid aria-controls | `aria-controls` doesn't match any element | Log warning, skip this trigger |

## Testing Data Requirements

### Test Fixtures (t/fixtures/collapsible-sections/)

1. **basic.tt**: Single collapsible section with simple text
   - short_description: "Summary text"
   - full_content: "Detailed explanation here."

2. **multiple.tt**: Three independent collapsible sections
   - Verifies unique ID generation
   - Tests independent state management

3. **blogdown-content.tt**: Complex blogdown syntax
   - Code blocks with triple-tildes
   - External links (should get target="_blank")
   - Smart quotes
   - Nested lists

4. **edge-cases.tt**: Boundary conditions
   - Very long short_description (multi-paragraph)
   - full_content with embedded TT directives
   - Unicode in descriptions
   - HTML entities in content

5. **invalid-params.tt**: Error conditions (should fail build)
   - Empty short_description
   - Whitespace-only full_content
   - Missing parameters

## Integration Points

### With Existing Features

1. **Footnotes (Feature 002)**:
   - Can be used inside collapsible content: `[% Ovid.collapse("Note", "Detail[% Ovid.add_note('foo') %]") %]`
   - Footnote counter and collapsible counter are independent
   - Both use similar dual-mode (JS/noscript) pattern

2. **Blogdown (Constitution Principle IX)**:
   - Collapsible `full_content` processed through same blogdown pipeline as article body
   - Ensures consistent formatting and link handling
   - Syntax highlighting works in collapsed code blocks

3. **Template Wrapper (include/wrapper.html)**:
   - Must include `static/css/collapsible.css` in `<head>`
   - Must include `static/js/collapsible.js` before `</body>`
   - No other changes required (progressive enhancement)

### External Dependencies

None. All processing is self-contained within:
- `Template::Plugin::Ovid` (Perl module)
- `Template::Plugin::Blogdown` (existing dependency)
- `static/js/collapsible.js` (new, zero dependencies)
- `static/css/collapsible.css` (new, standalone)

## Summary

The collapsible sections feature introduces:
- 1 new internal entity: CollapsibleSection (ephemeral state)
- 1 new output structure: CollapsibleHTML (static HTML)
- 1 new plugin state attribute: collapsible_number (counter)
- 2 new static assets: collapsible.js, collapsible.css

All entities follow established patterns from the footnote implementation and comply with Constitution principles for accessibility, progressive enhancement, and zero external dependencies.
