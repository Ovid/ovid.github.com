# Data Model: Footnote NoScript Fallback

**Feature**: 002-footnote-noscript-fallback  
**Date**: 2025-11-09  
**Status**: Complete

This document describes the data structures used for dual-mode footnote rendering.

---

## Entity: Footnote

**Context**: In-memory data structure (not persisted to database)  
**Lifecycle**: Created during template processing, exists only during build phase  
**Storage**: Perl hash in `$self->{footnotes}` array within `Template::Plugin::Ovid` instance

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `number` | Integer | Yes | Auto-incremented footnote number (starts at 1) |
| `body` | String (HTML) | Yes | Complete HTML for JavaScript modal dialog |
| `content` | String (HTML) | Yes | Raw footnote content for noscript rendering |

### Example Data Structure

```perl
# Single footnote hash
{
    number  => 1,
    body    => '<div id="dialog-1" class="dialog" role="dialog">...</div>',
    content => 'This is the footnote text with <em>formatting</em>.',
}

# Array of footnotes in plugin instance
$self->{footnotes} = [
    {
        number  => 1,
        body    => '...',  # JavaScript modal HTML
        content => '...',  # Raw HTML content
    },
    {
        number  => 2,
        body    => '...',
        content => '...',
    },
];
```

### Validation Rules

1. **Unique Numbers**: Each footnote must have a unique sequential number within an article
   - Enforced by: Auto-increment counter in `$self->{footnote_number}`
   - Range: 1 to N (no upper limit, but typically < 50 per article)

2. **Non-Empty Content**: The `content` field must not be empty
   - Enforced by: Caller must provide non-empty `$note` parameter
   - Current behavior: No explicit validation (would fail silently)
   - **Enhancement Opportunity**: Add validation in `add_note()` method

3. **Valid HTML**: Both `body` and `content` must be valid HTML5 fragments
   - Enforced by: Template caller provides HTML-safe content
   - Tested by: HTML validation in integration tests

### Relationships

```text
Article (Template Processing)
  └── Template::Plugin::Ovid Instance
        ├── footnote_number: Integer (counter)
        └── footnotes: ArrayRef[HashRef]
              ├── Footnote 1 { number, body, content }
              ├── Footnote 2 { number, body, content }
              └── Footnote N { number, body, content }
```

- **One-to-Many**: One article → Many footnotes
- **Ephemeral**: Footnotes exist only during template processing for that article
- **No Persistence**: Not stored in database, regenerated on each build

### State Transitions

```text
[Template Processing Starts]
         ↓
  Template::Plugin::Ovid->new()
         ↓
  footnote_number = 1
  footnotes = []
         ↓
[Template calls Ovid.add_note("content")]
         ↓
  Create footnote hash
  Increment footnote_number
  Push to footnotes array
  Return inline HTML
         ↓
[Template rendering continues...]
         ↓
[Footer template calls Ovid.get_footnotes()]
         ↓
  Returns footnotes array
  Renders JavaScript dialogs
  Renders noscript section
         ↓
[Template Processing Ends]
```

---

## Entity: Template Context (Template::Plugin::Ovid)

**Purpose**: Singleton-per-template instance managing footnote state during article build

### Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `footnote_number` | Integer | 1 | Next footnote number to assign (auto-increments) |
| `footnotes` | ArrayRef[HashRef] | `[]` | Collection of all footnotes for current article |
| `_CONTEXT` | Template::Context | Required | Template Toolkit context (inherited from base) |
| `tagmap` | HashRef | Loaded from JSON | Tag metadata (unrelated to footnotes) |
| `pager` | Less::Pager | `Less::Pager->new()` | Pagination data (unrelated to footnotes) |

### Methods

#### `add_note($note)` - Create Footnote

**Signature**:
```perl
sub add_note ( $self, $note )
```

**Input**:
- `$note` (String): HTML-safe footnote content

**Output**:
- Returns: String (HTML fragment for inline reference)

**Side Effects**:
1. Increments `$self->{footnote_number}`
2. Creates footnote hash with `number`, `body`, `content` fields
3. Pushes hash to `$self->{footnotes}` array

**Return Value (JavaScript mode)**:
```html
<span aria-label="Open Footnote" class="open-dialog" id="open-dialog-1">
  <i class="fa fa-clipboard fa_custom"></i>
</span>
```

**Stored Data**:
```perl
{
    number  => 1,
    body    => '<div id="dialog-1" class="dialog" ...>$note</div>',
    content => $note,
}
```

#### `get_footnotes()` - Retrieve All Footnotes

**Signature**:
```perl
sub get_footnotes($self)
```

**Output**:
- Returns: ArrayRef[HashRef] - Array of footnote hashes

**Example**:
```perl
my $footnotes = $plugin->get_footnotes();
# Returns: [ { number => 1, body => '...', content => '...' }, ... ]
```

#### `has_footnotes()` - Check If Footnotes Exist

**Signature**:
```perl
sub has_footnotes($self)
```

**Output**:
- Returns: Boolean (true if any footnotes exist)

**Implementation**:
```perl
sub has_footnotes($self) {
    return scalar $self->{footnotes}->@*;
}
```

---

## Template Rendering Model

### Input: Article Template

```tt2
[% USE Ovid %]
<article>
  <p>This is an article with a footnote.[% Ovid.add_note('Footnote content here') %]</p>
  <p>Another paragraph with another footnote.[% Ovid.add_note('Second footnote') %]</p>
</article>
```

### Processing: Template::Plugin::Ovid State

**After First `add_note()` Call**:
```perl
$self->{footnote_number} = 2;  # Incremented
$self->{footnotes} = [
    {
        number  => 1,
        body    => '<div id="dialog-1" ...>Footnote content here</div>',
        content => 'Footnote content here',
    }
];
```

**After Second `add_note()` Call**:
```perl
$self->{footnote_number} = 3;  # Incremented
$self->{footnotes} = [
    {
        number  => 1,
        body    => '<div id="dialog-1" ...>Footnote content here</div>',
        content => 'Footnote content here',
    },
    {
        number  => 2,
        body    => '<div id="dialog-2" ...>Second footnote</div>',
        content => 'Second footnote',
    },
];
```

### Output: Footer Template Rendering

```tt2
[% IF Ovid.has_footnotes %]
  [% footnotes = Ovid.get_footnotes %]
  
  <!-- JavaScript mode -->
  [% FOR fn IN footnotes %]
    [% fn.body %]  <!-- Renders dialog HTML -->
    <script>/* Initialize Dialog.js */</script>
  [% END %]
  
  <!-- NoScript mode -->
  <noscript>
    <aside class="footnotes">
      <ol>
        [% FOR fn IN footnotes %]
        <li id="footnote-[% fn.number %]">
          [% fn.content %]  <!-- Renders raw content -->
          <a href="#footnote-[% fn.number %]-return">↩</a>
        </li>
        [% END %]
      </ol>
    </aside>
  </noscript>
[% END %]
```

### Generated HTML Output

**JavaScript-Enabled Browser Sees**:
```html
<article>
  <p>This is an article with a footnote.<span class="open-dialog" id="open-dialog-1">📋</span></p>
  <p>Another paragraph.<span class="open-dialog" id="open-dialog-2">📋</span></p>
</article>

<div class="dialog-overlay"></div>
<div id="dialog-1" class="dialog">Footnote content here</div>
<div id="dialog-2" class="dialog">Second footnote</div>
<script>/* Dialog.js initialization */</script>

<!-- <noscript> content not rendered -->
```

**JavaScript-Disabled Browser Sees**:
```html
<article>
  <p>This is an article with a footnote.<span class="open-dialog" id="open-dialog-1">📋</span></p>
  <p>Another paragraph.<span class="open-dialog" id="open-dialog-2">📋</span></p>
</article>

<div class="dialog-overlay"></div>  <!-- Present but inert -->
<div id="dialog-1" class="dialog">...</div>  <!-- Present but inert -->
<div id="dialog-2" class="dialog">...</div>  <!-- Present but inert -->

<!-- <noscript> content DOES render -->
<aside class="footnotes" id="footnotes-section" aria-label="Footnotes">
  <h2>Footnotes</h2>
  <ol>
    <li id="footnote-1">
      Footnote content here
      <a href="#footnote-1-return">↩ Return to text</a>
    </li>
    <li id="footnote-2">
      Second footnote
      <a href="#footnote-2-return">↩ Return to text</a>
    </li>
  </ol>
</aside>
```

---

## Data Flow Diagram

```text
┌─────────────────────────────────────────────────────────────────┐
│ Article Template (.tt file)                                     │
│                                                                  │
│  [% USE Ovid %]                                                 │
│  Article text [% Ovid.add_note('footnote') %] more text        │
│                                                                  │
└──────────────────┬──────────────────────────────────────────────┘
                   │ Template Toolkit processes
                   ↓
┌─────────────────────────────────────────────────────────────────┐
│ Template::Plugin::Ovid Instance                                 │
│                                                                  │
│  footnote_number: 1 → 2 → 3 (auto-increment)                   │
│  footnotes: []                                                  │
│    ↓ add_note() called                                          │
│  footnotes: [ { number: 1, body: ..., content: ... } ]         │
│    ↓ add_note() called again                                    │
│  footnotes: [ {...}, { number: 2, body: ..., content: ... } ]  │
│                                                                  │
└──────────────────┬──────────────────────────────────────────────┘
                   │ Returns inline HTML to template
                   ↓
┌─────────────────────────────────────────────────────────────────┐
│ Generated Article HTML (partial)                                │
│                                                                  │
│  <p>Text <span class="open-dialog" id="open-dialog-1">📋</span></p> │
│  <p>More <span class="open-dialog" id="open-dialog-2">📋</span></p> │
│                                                                  │
└──────────────────┬──────────────────────────────────────────────┘
                   │ Footer template includes
                   ↓
┌─────────────────────────────────────────────────────────────────┐
│ Footer Template (footer.tt)                                     │
│                                                                  │
│  [% IF Ovid.has_footnotes %]                                    │
│    [% footnotes = Ovid.get_footnotes %]                         │
│                                                                  │
│    <!-- JavaScript mode -->                                     │
│    [% FOR fn IN footnotes %]                                    │
│      [% fn.body %]  ← Dialog HTML from 'body' field             │
│    [% END %]                                                    │
│                                                                  │
│    <!-- NoScript mode -->                                       │
│    <noscript>                                                   │
│      <ol>                                                       │
│      [% FOR fn IN footnotes %]                                  │
│        <li id="footnote-[% fn.number %]">                       │
│          [% fn.content %]  ← Raw content from 'content' field   │
│        </li>                                                    │
│      [% END %]                                                  │
│      </ol>                                                      │
│    </noscript>                                                  │
│  [% END %]                                                      │
│                                                                  │
└──────────────────┬──────────────────────────────────────────────┘
                   │ Final HTML output
                   ↓
┌─────────────────────────────────────────────────────────────────┐
│ Static HTML File (articles/my-article.html)                     │
│                                                                  │
│  Contains both JavaScript dialogs AND noscript footnote list    │
│  Browser chooses which to display based on JS availability      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Testing Data Model

### Test Fixtures

**Minimal Footnote**:
```perl
{
    number  => 1,
    body    => '<div id="dialog-1">Minimal footnote</div>',
    content => 'Minimal footnote',
}
```

**Footnote with HTML Formatting**:
```perl
{
    number  => 2,
    body    => '<div id="dialog-2">Footnote with <em>emphasis</em> and <a href="...">link</a></div>',
    content => 'Footnote with <em>emphasis</em> and <a href="...">link</a>',
}
```

**Multiple Footnotes**:
```perl
[
    { number => 1, body => '...', content => 'First footnote' },
    { number => 2, body => '...', content => 'Second footnote' },
    { number => 3, body => '...', content => 'Third footnote' },
]
```

### Test Scenarios

1. **Empty State**: No footnotes added, `has_footnotes()` returns false
2. **Single Footnote**: One `add_note()` call, verify data structure
3. **Multiple Footnotes**: Sequential `add_note()` calls, verify numbering
4. **HTML Content**: Footnote contains `<a>`, `<code>`, `<em>` tags, verify proper escaping
5. **Edge Case**: Very long footnote (>1000 chars), verify no truncation

---

## Next Phase

Data model complete. Proceed to **Phase 1: Contracts** to document API contracts and create quickstart guide.

**Status**: ✅ Data Model Complete
