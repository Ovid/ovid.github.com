# Research: Footnote NoScript Fallback

**Feature**: 002-footnote-noscript-fallback  
**Date**: 2025-11-09  
**Status**: Complete

This document captures research findings for implementing dual-mode footnote rendering (JavaScript + NoScript fallback).

---

## 1. NoScript Tag Behavior Across Browsers

### Decision
Use `<noscript>` tag to wrap the footnote section in footer template. Modern browsers universally support this tag and hide its content when JavaScript is enabled.

### Rationale
- **Browser Support**: All modern browsers (Chrome 1+, Firefox 1+, Safari 3+, Edge all versions) support `<noscript>` with identical behavior
- **Automatic Hiding**: When JavaScript is enabled, `<noscript>` content is not rendered in DOM - no CSS needed
- **Clean Separation**: Clear semantic distinction between JS and no-JS modes
- **No JavaScript Required**: Unlike CSS-based hiding, `<noscript>` works even if CSS fails to load

### Alternatives Considered
1. **CSS-based hiding with `.no-js` class**: Requires adding/removing classes via JavaScript, adds complexity
2. **Server-side user agent detection**: Unreliable, doesn't handle JS being disabled after page load
3. **Progressive enhancement with `display: none`**: Could leave vestigial HTML in DOM, less clean

### Browser Compatibility Matrix

| Browser | Version | `<noscript>` Support | Notes |
|---------|---------|---------------------|-------|
| Chrome | All | ✅ Full | Content not in DOM when JS enabled |
| Firefox | All | ✅ Full | Content not in DOM when JS enabled |
| Safari | All | ✅ Full | Content not in DOM when JS enabled |
| Edge | All | ✅ Full | Content not in DOM when JS enabled |
| IE11 | Legacy | ✅ Full | Works identically |

### Code Example
```html
<!-- In footer.tt -->
[% IF Ovid.has_footnotes %]
  <!-- JavaScript mode - dialog overlay -->
  <div class="dialog-overlay" tabindex="-1"></div>
  [% footnotes = Ovid.get_footnotes %]
  <!-- ... Dialog.js initialization ... -->
  
  <!-- NoScript mode - fallback footnote list -->
  <noscript>
    <aside class="footnotes" id="footnotes-section" aria-label="Footnotes">
      <h2>Footnotes</h2>
      <ol>
        [% FOR fn IN footnotes %]
        <li id="footnote-[% fn.number %]">
          [% fn.noscript_content %]
          <a href="#footnote-[% fn.number %]-return">↩ Return to text</a>
        </li>
        [% END %]
      </ol>
    </aside>
  </noscript>
[% END %]
```

---

## 2. HTML5 Best Practices for Footnotes

### Decision
Use `<aside class="footnotes">` with `<ol>` for the footnote list. Each list item uses bidirectional anchor links.

### Rationale
- **Semantic HTML5**: `<aside>` is specifically for "content tangentially related to main content" - perfect for footnotes
- **Accessibility**: `<ol>` provides numbered list semantics for screen readers, matching visual presentation
- **ARIA Support**: `aria-label="Footnotes"` on `<aside>` clearly identifies the section for assistive technology
- **Consistent Numbering**: `<ol>` auto-numbers match footnote reference numbers visually

### Alternatives Considered
1. **`<section>` instead of `<aside>`**: Less semantic - footnotes are auxiliary content
2. **Definition list `<dl>`**: Overkill for simple footnotes, less familiar pattern
3. **Paragraph list with manual numbering**: Less semantic, no automatic list structure for screen readers
4. **`<footer>` element**: Could confuse with page footer, less specific

### Recommended HTML Structure
```html
<aside class="footnotes" id="footnotes-section" aria-label="Footnotes">
  <h2>Footnotes</h2>
  <ol>
    <li id="footnote-1">
      This is the first footnote content with <em>formatting</em>.
      <a href="#footnote-1-return" aria-label="Return to footnote 1 reference">↩ Return to text</a>
    </li>
    <li id="footnote-2">
      Second footnote with <a href="https://example.com">a link</a>.
      <a href="#footnote-2-return" aria-label="Return to footnote 2 reference">↩ Return to text</a>
    </li>
  </ol>
</aside>
```

### ARIA Attributes
- `aria-label="Footnotes"` on `<aside>` - announces section purpose
- `aria-label="Footnote N"` on inline reference link - clear link purpose
- `aria-label="Return to footnote N reference"` on return link - clear return action

---

## 3. CSS Strategies for Hiding JS-Dependent Elements

### Decision
No additional CSS needed. The `<noscript>` tag automatically prevents its content from rendering when JavaScript is enabled. Dialog elements remain in DOM but are controlled by Dialog.js.

### Rationale
- **Browser Native**: `<noscript>` provides built-in hiding without CSS
- **Minimal Changes**: Existing Dialog.js CSS already handles dialog visibility
- **Performance**: No CSS parsing/application overhead
- **Reliability**: Works even if CSS fails to load

### Alternatives Considered
1. **CSS `display: none` on `.dialog-overlay` by default**: Requires JavaScript to show dialog, adds complexity
2. **Modernizr `.no-js` class removal**: Adds dependency, unnecessary complexity
3. **CSS `@supports` queries**: Not needed - JavaScript detection is the trigger

### Current Dialog.js CSS (No Changes Required)
The existing dialog CSS already handles visibility:
```css
/* Dialog overlay is hidden until Dialog.js adds .active class */
.dialog-overlay {
  position: fixed;
  opacity: 0;
  pointer-events: none;
  /* Dialog.js adds .active class when dialog opens */
}

.dialog-overlay.active {
  opacity: 1;
  pointer-events: auto;
}
```

### NoScript CSS (Optional Styling)
```css
/* Optional: Style the noscript footnotes section */
.footnotes {
  margin-top: 2rem;
  padding-top: 1rem;
  border-top: 2px solid #ccc;
}

.footnotes h2 {
  font-size: 1.5rem;
  margin-bottom: 1rem;
}

.footnotes ol {
  list-style-position: outside;
  padding-left: 2rem;
}

.footnotes li {
  margin-bottom: 1rem;
}
```

---

## 4. Anchor Navigation and Focus Management

### Decision
Use standard HTML anchor links with unique IDs. No JavaScript focus management needed in noscript mode.

### Rationale
- **Browser Native**: Anchor navigation is built into HTML, works without JavaScript
- **Accessible**: Screen readers announce "Navigated to footnote N" automatically
- **Keyboard Support**: Tab/Shift+Tab navigation works automatically
- **Simple**: No custom JavaScript focus management needed

### Anchor Link Patterns

**Inline Reference (in article text)**:
```html
<!-- JavaScript enabled: opens dialog -->
<span aria-label="Open Footnote" class="open-dialog" id="open-dialog-1">
  <i class="fa fa-clipboard fa_custom"></i>
</span>

<!-- JavaScript disabled: navigates to footnote -->
<noscript>
  <a href="#footnote-1" id="footnote-1-return" aria-label="Footnote 1">
    <i class="fa fa-clipboard fa_custom"></i>
  </a>
</noscript>
```

**Footnote at End of Article**:
```html
<li id="footnote-1">
  Footnote content goes here.
  <a href="#footnote-1-return" aria-label="Return to footnote 1 reference">
    ↩ Return to text
  </a>
</li>
```

### ARIA Labels for Screen Readers
- Forward link: `aria-label="Footnote 1"` - announces "Link, Footnote 1"
- Return link: `aria-label="Return to footnote 1 reference"` - announces "Link, Return to footnote 1 reference"

### Alternatives Considered
1. **JavaScript smooth scrolling**: Not needed, breaks without JS
2. **Focus management via JS**: Unnecessary complexity for anchor navigation
3. **Skip links**: Not needed, footnotes are sequential

---

## 5. Test Coverage for Dual Rendering Modes

### Decision
Test HTML output generation in Perl unit tests. Both JavaScript and NoScript HTML fragments are generated server-side and can be tested without browser automation.

### Rationale
- **Server-Side Rendering**: Both modes generate static HTML during build - no runtime JavaScript needed for testing
- **Deterministic Output**: HTML generation is pure function of input content
- **Fast Tests**: No browser automation overhead (Selenium, etc.)
- **90% Coverage Achievable**: Test both code paths in `add_note()` and footer template rendering

### Testing Strategy

**Unit Tests** (`t/ovid_plugin.t`):
```perl
use Test::Most;
use Template::Plugin::Ovid;

subtest 'add_note generates dual HTML output' => sub {
    my $context = mock_template_context();
    my $plugin = Template::Plugin::Ovid->new($context);
    
    my $inline_html = $plugin->add_note('Test footnote content');
    
    # Test JavaScript mode HTML (inline span)
    like $inline_html, qr/class="open-dialog"/, 'JS mode: has open-dialog class';
    like $inline_html, qr/id="open-dialog-1"/, 'JS mode: correct dialog ID';
    
    # Test that footnote data is stored
    my $footnotes = $plugin->get_footnotes();
    is scalar @$footnotes, 1, 'One footnote stored';
    
    # Test JavaScript dialog body
    like $footnotes->[0]{body}, qr/id="dialog-1"/, 'Dialog has correct ID';
    like $footnotes->[0]{body}, qr/Test footnote content/, 'Dialog contains content';
    
    # Test NoScript HTML (if stored separately)
    like $footnotes->[0]{noscript_html}, qr/id="footnote-1"/, 'NoScript: footnote ID';
    like $footnotes->[0]{noscript_html}, qr/Test footnote content/, 'NoScript: content';
};

subtest 'Template rendering with footnotes' => sub {
    # Test that footer template generates noscript section
    # May require Template Toolkit test harness
};
```

**Integration Tests** (optional - validate built HTML):
```perl
subtest 'Built article HTML validation' => sub {
    # Build test article with footnotes
    system('perl bin/rebuild') == 0 or die "Build failed";
    
    # Read generated HTML
    my $html = path('articles/test-article.html')->slurp;
    
    # Validate both modes present
    like $html, qr/<noscript>.*footnotes.*<\/noscript>/s, 'NoScript section exists';
    like $html, qr/class="dialog-overlay"/, 'Dialog overlay exists';
    
    # Validate HTML5
    my $validator = HTML::Validator::Nu->new;
    my $result = $validator->validate($html);
    ok !$result->has_errors, 'Valid HTML5';
};
```

### Coverage Goals
- `add_note()`: 100% - test with various content (plain text, HTML, special chars)
- `get_footnotes()`: 100% - test empty and populated states
- `has_footnotes()`: 100% - test boolean logic
- Footer template: 90%+ - test rendering with/without footnotes

### Alternatives Considered
1. **Browser automation (Selenium)**: Slow, adds dependencies, unnecessary for static HTML
2. **JavaScript testing (Jest)**: Not needed - Dialog.js unchanged, already tested
3. **Manual testing only**: Violates 90% coverage requirement

---

## 6. Template Toolkit Conditional Rendering

### Decision
Use Template Toolkit's `[% IF %]` directive to conditionally render dialog elements. Wrap noscript footnotes in `<noscript>` tag. No special TT2 conditionals needed - rely on HTML's native `<noscript>`.

### Rationale
- **Separation of Concerns**: HTML `<noscript>` handles JS detection, not Template Toolkit
- **Clean Templates**: No duplicated content - dialog and noscript sections reference same footnote data
- **Maintainable**: Single source of truth for footnote content in Perl module

### Template Toolkit Patterns

**Current Pattern (JavaScript only)**:
```tt2
[% IF Ovid.has_footnotes %]
  <div class="dialog-overlay" tabindex="-1"></div>
  [% footnotes = Ovid.get_footnotes %]
  [% FOR footnote IN footnotes %]
    [% footnote.body %]
    <script>
      var myDialog[% footnote.number %] = new Dialog(...);
    </script>
  [% END %]
[% END %]
```

**New Pattern (JavaScript + NoScript)**:
```tt2
[% IF Ovid.has_footnotes %]
  <!-- JavaScript mode - dialog overlay -->
  <div class="dialog-overlay" tabindex="-1"></div>
  
  [% footnotes = Ovid.get_footnotes %]
  
  <!-- Render JavaScript dialogs -->
  [% FOR footnote IN footnotes %]
    [% footnote.body %]
    <script>
      var myDialog[% footnote.number %] = new Dialog(
        document.querySelector('#dialog-[% footnote.number %]'),
        document.querySelector('.dialog-overlay')
      );
      myDialog[% footnote.number %].addEventListeners(
        '#open-dialog-[% footnote.number %]',
        '#close-dialog-[% footnote.number %]'
      );
    </script>
  [% END %]
  
  <!-- NoScript mode - fallback footnote list -->
  <noscript>
    <aside class="footnotes" id="footnotes-section" aria-label="Footnotes">
      <h2>Footnotes</h2>
      <ol>
        [% FOR footnote IN footnotes %]
        <li id="footnote-[% footnote.number %]">
          [% footnote.content %]
          <a href="#footnote-[% footnote.number %]-return" 
             aria-label="Return to footnote [% footnote.number %] reference">
            ↩ Return to text
          </a>
        </li>
        [% END %]
      </ol>
    </aside>
  </noscript>
[% END %]
```

### Perl Module Changes

**Store both content and number separately**:
```perl
sub add_note ( $self, $note ) {
    my $number = $self->{footnote_number}++;
    my $id     = "note-$number";
    
    # JavaScript dialog HTML (existing)
    my $dialog = qq{<span aria-label="Open Footnote" class="open-dialog" id="open-dialog-$number"> <i class="fa fa-clipboard fa_custom"></i> </span>};
    my $body = <<"HTML";
    <div id="dialog-$number" class="dialog" role="dialog" aria-labelledby="$id" aria-describedby="note-description-$number">
        <strong id="$id">Footnotes</strong>
        <p id="note-description-$number" class="sr-only">Note number $number</p>
        <div>$note</div>
        <button type="button" aria-label="Close Navigation" class="close-dialog" id="close-dialog-$number"> <i class="fa fa-times"></i> </button>
    </div>
HTML

    # Store footnote data with both body and raw content
    push $self->{footnotes}->@* => {
        number  => $number,
        body    => $body,      # JavaScript dialog HTML
        content => $note,      # Raw content for noscript rendering
    };
    
    return $dialog;
}
```

### Alternatives Considered
1. **TT2 WRAPPER/BLOCK for mode switching**: Over-engineered for simple dual rendering
2. **Separate TT2 macros for JS/NoScript**: Duplicates logic, harder to maintain
3. **Server-side user agent detection**: Unreliable, doesn't handle JS disabled mid-session

---

## Summary of Decisions

| Research Area | Decision | Key Benefit |
|---------------|----------|-------------|
| NoScript Behavior | Use `<noscript>` tag | Browser-native, zero CSS needed |
| HTML Structure | `<aside>` + `<ol>` + bidirectional anchors | Semantic, accessible, standards-compliant |
| CSS Strategy | No changes needed | `<noscript>` handles hiding automatically |
| Anchor Navigation | Standard HTML anchor links | Works without JavaScript, accessible by default |
| Test Strategy | Perl unit tests for HTML output | Fast, deterministic, 90% coverage achievable |
| TT2 Patterns | `<noscript>` wrapping + data separation | Clean, maintainable, single source of truth |

---

## Next Phase

With research complete, proceed to **Phase 1: Design & Contracts** to document:
- Data model for footnote storage
- API contracts for `add_note()` method
- Footer template contract
- Quickstart guide for developers

**Status**: ✅ Research Complete - Ready for Design Phase
