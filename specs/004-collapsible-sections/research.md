# Research: Collapsible Sections

**Feature**: 004-collapsible-sections  
**Date**: 2025-11-16  
**Status**: Complete

## Overview

This document consolidates research findings for implementing collapsible sections in Ovid's static site generator. The feature extends the existing `Template::Plugin::Ovid` module with a new `collapse()` method, following the established pattern used by the `add_note()` footnote functionality.

## Research Topics

### 1. Template::Plugin::Ovid Architecture Pattern

**Decision**: Extend existing `Template::Plugin::Ovid` module with `collapse()` method

**Rationale**: 
- Follows established CPAN-style module architecture (Constitution Principle I)
- Mirrors the successful `add_note()` implementation pattern
- Leverages existing Template::Toolkit plugin infrastructure
- Maintains single namespace for all custom TT extensions

**Implementation Pattern from add_note()**:
```perl
sub add_note ( $self, $note ) {
    my $number = $self->{footnote_number}++;
    my $id     = "note-$number";
    
    # JavaScript-enabled mode: interactive element
    my $dialog = qq{<span aria-label="..." class="open-dialog js-only" ...>};
    
    # NoScript mode: anchor link fallback
    my $noscript = qq{<noscript><a href="..." ...>...</a></noscript>};
    
    # Store data for template footer rendering
    push $self->{footnotes}->@* => { ... };
    
    # Return both JS and noscript elements
    return $dialog . $noscript;
}
```

**Key Observations**:
- Plugin maintains state during template processing (counter, accumulated data)
- Returns HTML that works with/without JavaScript
- Uses instance variables to accumulate content for later rendering
- Follows progressive enhancement: JS-only elements hidden via CSS when disabled

**Alternatives Considered**:
- ❌ Create separate `Template::Plugin::Collapsible` module
  - Rejected: Adds unnecessary namespace proliferation
  - Would require additional `USE Collapsible` in templates
  - Splits related functionality across multiple modules
- ❌ Implement as Template::Toolkit macro
  - Rejected: Macros cannot maintain state or generate unique IDs
  - Cannot process blogdown syntax programmatically
  - Limited error handling capabilities

### 2. Blogdown Content Processing

**Decision**: Apply blogdown processing to `full_content` parameter before rendering

**Rationale**:
- Constitution Principle IX requires blogdown support for all article content
- Enables rich formatting (code blocks, tables, links) in collapsed content
- Maintains consistency with main article rendering pipeline

**Implementation Approach**:
```perl
use Template::Plugin::Blogdown;

sub collapse ( $self, $short_description, $full_content ) {
    # Process full_content through blogdown
    my $blogdown = Template::Plugin::Blogdown->new($self->{_CONTEXT});
    my $processed_content = $blogdown->filter($full_content);
    
    # Generate HTML with processed content
    # ...
}
```

**Integration Points**:
- `Template::Plugin::Blogdown` delegates to `Text::Markdown::Blog`
- Supports triple-tilde code fences with syntax highlighting
- Processes smart quotes, external links, tables
- Allows embedded TT directives (though complex nesting should be tested)

**Edge Cases to Test**:
- Nested TT directives (e.g., `Ovid.add_note()` inside collapsible content)
- Code blocks containing triple-tildes or backticks
- Complex tables with alignment
- External links requiring `target="_blank"` and icon insertion

**Alternatives Considered**:
- ❌ Process blogdown in template layer
  - Rejected: Violates separation of concerns
  - Makes template code more complex
  - Cannot validate/sanitize programmatically
- ❌ Require pre-processed HTML
  - Rejected: Inconsistent with article authoring workflow
  - Forces authors to manage HTML directly
  - Loses benefits of Markdown simplicity

### 3. Progressive Enhancement Strategy

**Decision**: Implement with JavaScript enhancement + noscript fallback

**Rationale**:
- Constitution Principle IV: "No JavaScript required for core content access"
- Follows proven pattern from footnote implementation (Feature 002)
- Ensures accessibility and content availability for all users

**Dual-Mode Architecture**:

**JavaScript-Enabled Mode**:
- Collapsed by default (CSS: `display: none` on content div)
- Clickable trigger area (entire header with icon + short description)
- Toggle visibility via JavaScript event handlers
- Visual feedback (icon change, ARIA state updates)

**NoScript Mode**:
- Both short description and full content visible
- Full content indented for visual hierarchy (per spec clarification)
- No interactive elements shown
- Content remains accessible to screen readers, bots, JS-disabled browsers

**CSS Strategy**:
```css
/* JavaScript-enabled: hide initially */
.collapsible-content {
    display: none;
}

.collapsible-content.expanded {
    display: block;
}

/* NoScript: always visible, indented */
noscript .collapsible-content {
    display: block;
    margin-left: 2em;
    border-left: 3px solid #ccc;
    padding-left: 1em;
}
```

**JavaScript Strategy**:
```javascript
// Vanilla JS, no framework dependencies (Constitution Principle V)
document.querySelectorAll('.collapsible-trigger').forEach(trigger => {
    trigger.addEventListener('click', function(e) {
        const contentId = this.getAttribute('aria-controls');
        const content = document.getElementById(contentId);
        const isExpanded = this.getAttribute('aria-expanded') === 'true';
        
        // Toggle state
        this.setAttribute('aria-expanded', !isExpanded);
        content.classList.toggle('expanded');
        
        // Update icon
        const icon = this.querySelector('i');
        icon.classList.toggle('fa-chevron-down');
        icon.classList.toggle('fa-chevron-up');
    });
});
```

**Alternatives Considered**:
- ❌ JavaScript-only implementation
  - Rejected: Violates Constitution Principle IV
  - Excludes users without JavaScript
  - Fails accessibility requirements
- ❌ CSS-only toggle using `:target` pseudo-class
  - Rejected: Changes URL hash, breaks navigation
  - Limited styling control for states
  - Poor accessibility (no ARIA support)

### 4. Accessibility Requirements (WCAG 2.1 Level AA)

**Decision**: Implement full ARIA attributes and keyboard navigation

**Required ARIA Attributes**:
```html
<!-- Trigger element -->
<div class="collapsible-trigger" 
     role="button"
     tabindex="0"
     aria-expanded="false"
     aria-controls="collapsible-content-1"
     aria-label="Expand: [short description]">
    <i class="fa fa-chevron-down" aria-hidden="true"></i>
    <span>[short description]</span>
</div>

<!-- Content element -->
<div id="collapsible-content-1"
     class="collapsible-content"
     role="region"
     aria-labelledby="collapsible-trigger-1">
    [full content]
</div>
```

**Keyboard Navigation**:
- `Enter` or `Space` to toggle expansion
- `Tab` to navigate to/from trigger
- Screen readers announce state changes ("expanded"/"collapsed")

**Visual Indicators**:
- Icon change: chevron-down → chevron-up
- Color/style change on focus (visible focus indicator)
- Smooth transitions (optional enhancement, out of scope for P1)

**Testing Checklist**:
- [ ] Screen reader announces state correctly (NVDA, JAWS, VoiceOver)
- [ ] Keyboard navigation works without mouse
- [ ] Focus visible on all interactive elements
- [ ] Color contrast meets WCAG AA (4.5:1 for text, 3:1 for UI components)
- [ ] Valid HTML5 (no ARIA violations)

**Alternatives Considered**:
- ❌ Details/summary native HTML elements
  - Rejected: Limited styling control
  - Browser inconsistencies in behavior
  - Cannot easily integrate with noscript fallback
  - Icon positioning challenges
- ❌ Minimal ARIA (just aria-expanded)
  - Rejected: Fails WCAG AA requirements
  - Poor screen reader experience
  - May not announce content correctly

### 5. State Management & Unique Identifiers

**Decision**: Use instance counter similar to footnote numbering

**Implementation**:
```perl
package Template::Plugin::Ovid;

sub new ( $class, $context ) {
    bless {
        _CONTEXT           => $context,
        footnote_number    => 1,  # Existing
        collapsible_number => 1,  # New
        # ...
    }, $class;
}

sub collapse ( $self, $short_description, $full_content ) {
    my $number = $self->{collapsible_number}++;
    my $trigger_id = "collapsible-trigger-$number";
    my $content_id = "collapsible-content-$number";
    # ...
}
```

**Rationale**:
- Ensures unique IDs per page (required for ARIA aria-controls)
- Simple, predictable, deterministic
- No collision risk within single page context
- Testable and debuggable

**Edge Cases**:
- Multiple articles on one page: Plugin instance per template, so counters reset
- Deep nesting: Not supported (per spec "Out of Scope")
- Manual ID conflicts: Unlikely with generated pattern

**Alternatives Considered**:
- ❌ Hash-based IDs (content checksum)
  - Rejected: Adds complexity
  - Non-deterministic with blogdown processing
  - Harder to test
- ❌ UUID/random IDs
  - Rejected: Non-deterministic, breaks testing
  - Overkill for static generation
  - Reduces debuggability

### 6. Error Handling & Validation

**Decision**: Throw errors for invalid parameters during build time

**Validation Rules** (per FR-001a):
```perl
sub collapse ( $self, $short_description, $full_content ) {
    # Validate parameters
    croak("collapse() requires short_description parameter")
        unless defined $short_description && $short_description =~ /\S/;
    
    croak("collapse() requires full_content parameter")
        unless defined $full_content && $full_content =~ /\S/;
    
    # Continue with processing...
}
```

**Rationale**:
- Fail fast during build (not at runtime)
- Clear error messages guide authors
- Prevents invalid HTML generation
- Follows Perl best practices (croak for library code)

**Error Scenarios**:
- Empty string: `[% Ovid.collapse("", "content") %]` → Build error
- Whitespace only: `[% Ovid.collapse("   ", "content") %]` → Build error
- Undefined: `[% Ovid.collapse(undef, "content") %]` → Build error
- Missing parameter: `[% Ovid.collapse("text") %]` → TT compile error

**Alternatives Considered**:
- ❌ Silent fallback (render nothing)
  - Rejected: Hides authoring mistakes
  - Content silently disappears
  - No feedback to author
- ❌ Default values
  - Rejected: Encourages invalid usage
  - Unclear semantics (what should default be?)
  - Spec requires both parameters

### 7. CSS Architecture & Styling Approach

**Decision**: Create dedicated `static/css/collapsible.css` stylesheet

**Styling Strategy**:
- Full-width sections (per FR-009)
- Visual consistency with existing article design
- Clear collapsed vs expanded states
- Icon positioning on left (per clarification)
- Indented noscript fallback (per clarification)

**CSS Structure**:
```css
/* Base collapsible styles */
.collapsible-section {
    width: 100%;
    margin: 1.5em 0;
    border: 1px solid #e0e0e0;
    border-radius: 4px;
}

.collapsible-trigger {
    display: flex;
    align-items: center;
    padding: 1em;
    cursor: pointer;
    background: #f9f9f9;
    transition: background-color 0.2s;
}

.collapsible-trigger:hover {
    background: #f0f0f0;
}

.collapsible-trigger:focus {
    outline: 2px solid #0066cc;
    outline-offset: 2px;
}

.collapsible-icon {
    margin-right: 0.75em;
    color: #666;
}

.collapsible-content {
    padding: 0 1em 1em 1em;
    display: none;
}

.collapsible-content.expanded {
    display: block;
}

/* NoScript fallback */
noscript .collapsible-content {
    display: block;
    margin-left: 2em;
    border-left: 3px solid #ccc;
    padding-left: 1em;
}

noscript .collapsible-trigger {
    cursor: default;
    background: transparent;
}
```

**Integration with Existing Styles**:
- Inherits typography from main.css
- Matches border/color scheme of existing elements
- Responsive (inherits from skeleton.css grid)
- Works with syntax highlighting (prism.css)

**Alternatives Considered**:
- ❌ Inline styles in Perl module
  - Rejected: Violates separation of concerns
  - Hard to customize/theme
  - No caching benefits
- ❌ Add to existing main.css
  - Rejected: Keeps feature modular
  - Easier to remove/modify independently
  - Clear ownership

### 8. JavaScript Architecture & Event Handling

**Decision**: Create standalone `static/js/collapsible.js` module

**Implementation Approach**:
```javascript
// Vanilla JavaScript, no dependencies
(function() {
    'use strict';
    
    // Initialize on DOM ready
    function initCollapsibles() {
        const triggers = document.querySelectorAll('.collapsible-trigger');
        
        triggers.forEach(trigger => {
            // Mouse/touch interaction
            trigger.addEventListener('click', toggleCollapsible);
            
            // Keyboard interaction
            trigger.addEventListener('keydown', function(e) {
                if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault();
                    toggleCollapsible.call(this, e);
                }
            });
        });
    }
    
    function toggleCollapsible(e) {
        const contentId = this.getAttribute('aria-controls');
        const content = document.getElementById(contentId);
        const isExpanded = this.getAttribute('aria-expanded') === 'true';
        
        // Toggle ARIA state
        this.setAttribute('aria-expanded', !isExpanded);
        
        // Toggle content visibility
        content.classList.toggle('expanded');
        
        // Update icon
        const icon = this.querySelector('.collapsible-icon');
        icon.classList.toggle('fa-chevron-down');
        icon.classList.toggle('fa-chevron-up');
    }
    
    // Initialize when DOM ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initCollapsibles);
    } else {
        initCollapsibles();
    }
})();
```

**Key Features**:
- Zero dependencies (no jQuery, no frameworks)
- Immediate initialization for dynamically loaded content
- Keyboard accessibility built-in
- Event delegation friendly
- Idempotent (safe to run multiple times)

**Browser Compatibility**:
- Modern browsers only (per assumption: "no IE11 requirement")
- Uses `querySelectorAll`, `classList`, `addEventListener`
- All supported in Chrome, Firefox, Safari, Edge (modern)

**Alternatives Considered**:
- ❌ Inline event handlers (onclick)
  - Rejected: Poor separation of concerns
  - CSP (Content Security Policy) issues
  - Harder to test
- ❌ jQuery dependency
  - Rejected: Constitution Principle V (minimize dependencies)
  - Adds unnecessary weight (~30KB)
  - Vanilla JS sufficient for simple interactions

## Summary

All research complete. No NEEDS CLARIFICATION items remain. The implementation follows:

1. **Architecture**: Extend `Template::Plugin::Ovid` with `collapse()` method
2. **Content Processing**: Apply blogdown to `full_content` parameter
3. **Progressive Enhancement**: JavaScript + noscript fallback pattern
4. **Accessibility**: Full ARIA attributes, keyboard navigation
5. **State Management**: Instance counter for unique IDs
6. **Error Handling**: Build-time validation with clear errors
7. **Styling**: Dedicated CSS file, full-width responsive design
8. **JavaScript**: Vanilla JS module, zero dependencies

All decisions align with Constitution principles and established codebase patterns.
