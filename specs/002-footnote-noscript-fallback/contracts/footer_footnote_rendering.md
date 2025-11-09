# Contract: Footer Template Footnote Rendering

**Feature**: 002-footnote-noscript-fallback  
**Component**: root/include/footer.tt template  
**Date**: 2025-11-09

---

## Template Block Purpose

Renders footnotes at the end of articles in two modes:
1. **JavaScript Mode**: Dialog overlays with Dialog.js initialization
2. **NoScript Mode**: Anchor-linked footnote list within `<noscript>` tag

---

## Template Condition

```tt2
[% IF Ovid.has_footnotes %]
  <!-- Footnote rendering -->
[% END %]
```

Only renders footnote section if `Ovid.has_footnotes` returns true (i.e., at least one footnote was added via `Ovid.add_note()` during article template processing).

---

## JavaScript Mode Rendering (Current Behavior)

### Current Implementation

```tt2
[% IF Ovid.has_footnotes %]
  <!-- Dialog overlay -->
  <div class="dialog-overlay" tabindex="-1"></div>
  
  [% footnotes = Ovid.get_footnotes %]
  <script type="text/javascript" src="/static/js/Dialog.js"></script>
  
  [% FOR footnote IN footnotes %]
    [% footnote.body %]
    <script>
      var dialogOverlay = document.querySelector('.dialog-overlay');
      var myDialog[% footnote.number %] = new Dialog(
        document.querySelector('#dialog-[% footnote.number %]'),
        dialogOverlay
      );
      myDialog[% footnote.number %].addEventListeners(
        '#open-dialog-[% footnote.number %]',
        '#close-dialog-[% footnote.number %]'
      );
    </script>
  [% END %]
[% END %]
```

### Generated HTML (JavaScript Mode)

```html
<div class="dialog-overlay" tabindex="-1"></div>
<script type="text/javascript" src="/static/js/Dialog.js"></script>

<div id="dialog-1" class="dialog" role="dialog" aria-labelledby="note-1">
  <strong id="note-1">Footnotes</strong>
  <p id="note-description-1" class="sr-only">Note number 1</p>
  <div>First footnote content</div>
  <button type="button" class="close-dialog" id="close-dialog-1">
    <i class="fa fa-times"></i>
  </button>
</div>
<script>
  var dialogOverlay = document.querySelector('.dialog-overlay');
  var myDialog1 = new Dialog(
    document.querySelector('#dialog-1'),
    dialogOverlay
  );
  myDialog1.addEventListeners('#open-dialog-1', '#close-dialog-1');
</script>

<div id="dialog-2" class="dialog" role="dialog" aria-labelledby="note-2">
  <!-- Second dialog... -->
</div>
<script>
  var myDialog2 = new Dialog(...);
</script>
```

### Contract Guarantees (JavaScript Mode)

- ✅ Dialog overlay rendered once before all dialogs
- ✅ Dialog.js library loaded once
- ✅ Each footnote gets a unique `#dialog-N` element
- ✅ Each footnote gets initialized with Dialog.js
- ✅ Dialog elements have proper ARIA attributes
- ✅ Dialog trigger (in article text) matches dialog ID

---

## NoScript Mode Rendering (NEW IMPLEMENTATION)

### New Template Addition

```tt2
[% IF Ovid.has_footnotes %]
  <!-- JavaScript mode (existing, unchanged) -->
  <div class="dialog-overlay" tabindex="-1"></div>
  [% footnotes = Ovid.get_footnotes %]
  <!-- ... existing dialog rendering ... -->
  
  <!-- NoScript mode (NEW) -->
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

### Generated HTML (NoScript Mode)

**Note**: This HTML is wrapped in `<noscript>` tag, so it's only rendered when JavaScript is disabled.

```html
<noscript>
  <aside class="footnotes" id="footnotes-section" aria-label="Footnotes">
    <h2>Footnotes</h2>
    <ol>
      <li id="footnote-1">
        First footnote content
        <a href="#footnote-1-return" aria-label="Return to footnote 1 reference">
          ↩ Return to text
        </a>
      </li>
      <li id="footnote-2">
        Second footnote content
        <a href="#footnote-2-return" aria-label="Return to footnote 2 reference">
          ↩ Return to text
        </a>
      </li>
    </ol>
  </aside>
</noscript>
```

### Contract Guarantees (NoScript Mode)

- ✅ Content only rendered when JavaScript is disabled
- ✅ Each footnote has unique `id="footnote-N"` matching anchor link in article
- ✅ Each footnote has return link to `#footnote-N-return` (anchor in article text)
- ✅ Footnotes listed in sequential order (1, 2, 3, ...)
- ✅ Semantic HTML (`<aside>` for tangential content, `<ol>` for numbered list)
- ✅ Accessible (ARIA labels, semantic structure, keyboard navigable)
- ✅ Footnote content uses `footnote.content` field (raw HTML, not dialog wrapper)

---

## Complete Template Structure (Both Modes)

```tt2
[% USE date %]
[% USE Config %]

<!-- ... existing footer content ... -->

[% IF Ovid.has_footnotes %]
  <!-- Mode 1: JavaScript Enabled -->
  <div class="dialog-overlay" tabindex="-1"></div>
  [% footnotes = Ovid.get_footnotes %]
  <script type="text/javascript" src="/static/js/Dialog.js"></script>
  
  [% FOR footnote IN footnotes %]
    [% footnote.body %]
    <script>
      var dialogOverlay = document.querySelector('.dialog-overlay');
      var myDialog[% footnote.number %] = new Dialog(
        document.querySelector('#dialog-[% footnote.number %]'),
        dialogOverlay
      );
      myDialog[% footnote.number %].addEventListeners(
        '#open-dialog-[% footnote.number %]',
        '#close-dialog-[% footnote.number %]'
      );
    </script>
  [% END %]
  
  <!-- Mode 2: JavaScript Disabled (NEW) -->
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

<!-- ... existing footer content continues ... -->
```

---

## Data Requirements

### Template Variables

| Variable | Type | Source | Description |
|----------|------|--------|-------------|
| `Ovid` | Template::Plugin::Ovid | `[% USE Ovid %]` (in article template) | Plugin instance |
| `footnotes` | ArrayRef[HashRef] | `Ovid.get_footnotes` | Array of footnote data |

### Footnote Hash Structure

Each element in `footnotes` array must have:

```perl
{
    number  => Integer,  # Unique footnote number (1, 2, 3, ...)
    body    => String,   # Full HTML for JavaScript dialog
    content => String,   # Raw HTML content for noscript rendering
}
```

---

## HTML ID Contracts

### Bidirectional Anchor Navigation

**In Article Text** (generated by `add_note()`):
```html
<noscript>
  <a href="#footnote-1" id="footnote-1-return">📋</a>
</noscript>
```

**In Footer Footnote List**:
```html
<li id="footnote-1">
  Footnote content
  <a href="#footnote-1-return">↩ Return to text</a>
</li>
```

### ID Naming Convention

- **Footnote List Item**: `footnote-N` (e.g., `footnote-1`, `footnote-2`)
- **Article Reference Point**: `footnote-N-return` (e.g., `footnote-1-return`)
- **JavaScript Dialog**: `dialog-N` (existing, unchanged)
- **Dialog Trigger**: `open-dialog-N` (existing, unchanged)
- **Dialog Close Button**: `close-dialog-N` (existing, unchanged)

### Uniqueness Guarantee

- ✅ All IDs unique within a single article
- ✅ No conflicts between JavaScript and noscript IDs
- ✅ Sequential numbering prevents collisions

---

## Accessibility Contracts

### ARIA Attributes

**Footnotes Section**:
- `role` implicit (none needed for `<aside>`)
- `aria-label="Footnotes"` - announces section purpose

**Footnote List**:
- `<ol>` provides list semantics (auto-numbered)
- Each `<li>` has unique `id` for anchor navigation

**Return Links**:
- `aria-label="Return to footnote N reference"` - clear link purpose
- Visual symbol: ↩ (U+21A9 LEFTWARDS ARROW WITH HOOK)

### Screen Reader Behavior

**JavaScript Enabled**:
1. Reader encounters: "Link, Open Footnote"
2. User activates: Modal dialog opens, focus trapped in dialog
3. Dialog announced: "Dialog, Footnotes, Note number 1"
4. User closes: Focus returns to trigger point

**JavaScript Disabled**:
1. Reader encounters: "Link, Footnote 1"
2. User activates: Navigates to footnote list
3. Footnote announced: "List, ordered, 3 items, List item 1, [content]"
4. User activates return link: "Link, Return to footnote 1 reference"
5. Navigates back: Returns to reading position

---

## Visual Placement

### JavaScript Mode
- Dialog overlay appears as full-page overlay
- Dialog appears centered on screen
- Article content remains in place (not scrolled)

### NoScript Mode
- Footnotes section appears at end of article content
- Before pager navigation (previous/next article links)
- Before page footer (copyright, comments)

**Visual Order**:
```text
┌─────────────────────────────┐
│ Article Content             │
├─────────────────────────────┤  ← Article ends
│ (Footnotes - NoScript only) │  ← NEW: Footnotes section
├─────────────────────────────┤
│ Pager (Previous/Next)       │
├─────────────────────────────┤
│ Hire Me / Contact Info      │
├─────────────────────────────┤
│ Copyright Footer            │
├─────────────────────────────┤
│ Disqus Comments             │
└─────────────────────────────┘
```

---

## CSS Styling Contracts

### NoScript Footnotes Styling

```css
/* Optional: Style the noscript footnotes section */
.footnotes {
  margin-top: 2rem;
  padding-top: 1rem;
  border-top: 2px solid #ccc;
  font-size: 0.9rem;
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

.footnotes a {
  text-decoration: none;
  color: #0066cc;
  font-weight: bold;
}
```

### Dialog CSS (Existing, Unchanged)

Dialog.js already handles dialog visibility. No changes needed to prevent interference with noscript content.

---

## Testing Contracts

### Template Rendering Tests

```perl
subtest 'Footer renders noscript section' => sub {
    # Mock Template Toolkit context
    my $tt = Template->new();
    my $plugin = Template::Plugin::Ovid->new($mock_context);
    
    $plugin->add_note('Test footnote');
    
    my $output;
    $tt->process('include/footer.tt', { Ovid => $plugin }, \$output);
    
    # Test noscript section presence
    like $output, qr/<noscript>/, 'Footer contains noscript tag';
    like $output, qr/<aside class="footnotes"/, 'Contains footnotes aside';
    like $output, qr/<ol>/, 'Contains ordered list';
    like $output, qr/id="footnote-1"/, 'Footnote has correct ID';
    like $output, qr/Test footnote/, 'Footnote content rendered';
    like $output, qr/href="#footnote-1-return"/, 'Return link present';
};
```

### HTML Validation

```perl
subtest 'Generated HTML is valid HTML5' => sub {
    # Build test article
    system('perl bin/rebuild') == 0 or die "Build failed";
    
    my $html = path('articles/test-footnotes.html')->slurp;
    
    # Validate with Nu HTML Checker
    my $validator = HTML::Validator::Nu->new;
    my $result = $validator->validate($html);
    
    ok !$result->has_errors, 'HTML5 validation passes';
};
```

---

## Backward Compatibility

### Existing Behavior Preserved

- ✅ JavaScript mode unchanged (dialogs still work)
- ✅ Existing articles render identically with JS enabled
- ✅ No breaking changes to template API
- ✅ Additive only - new noscript section added

### New Behavior

- ✅ JavaScript-disabled users now see footnotes (bug fix)
- ✅ Noscript section only visible when JS disabled
- ✅ No visual interference between modes

---

## Contract Version

**Version**: 2.0.0 (Major change - adds noscript functionality)  
**Previous Version**: 1.0.0 (JavaScript-only)  
**Status**: Proposed (pending implementation)

---

**Related Contracts**:
- [add_note Method](add_note_method.md)
- [CSS Display Rules](css_display_rules.md)
