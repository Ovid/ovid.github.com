# Contract: Template::Plugin::Ovid::add_note Method

**Feature**: 002-footnote-noscript-fallback  
**Component**: Template::Plugin::Ovid module  
**Date**: 2025-11-09

---

## Method Signature

```perl
sub add_note ( $self, $note )
```

---

## Purpose

Creates a footnote entry and returns inline HTML for the footnote reference marker. This method is called from Template Toolkit templates to add footnotes to articles.

---

## Input Parameters

### `$self`
- **Type**: `Template::Plugin::Ovid` instance
- **Required**: Yes (implicit)
- **Description**: Plugin instance with current footnote state

### `$note`
- **Type**: String (HTML-safe content)
- **Required**: Yes
- **Description**: The footnote text content, may include HTML formatting tags
- **Valid Examples**:
  - `'Simple footnote text'`
  - `'Footnote with <em>emphasis</em>'`
  - `'Footnote with <a href="https://example.com">link</a>'`
- **Invalid Examples**:
  - `undef` (should die or warn)
  - `''` (empty string - should die or warn)
  - Unsafe HTML (user must sanitize before calling)

---

## Output

### Return Value

**Type**: String (HTML fragment)

**JavaScript-Enabled Mode Output**:
```html
<span aria-label="Open Footnote" class="open-dialog" id="open-dialog-N">
  <i class="fa fa-clipboard fa_custom"></i>
</span>
```

Where `N` is the auto-incremented footnote number (1, 2, 3, ...).

**NoScript Mode Output**:
This method ALSO needs to generate noscript HTML for inline reference (NEW REQUIREMENT):

```html
<noscript>
  <a href="#footnote-N" id="footnote-N-return" aria-label="Footnote N">
    <i class="fa fa-clipboard fa_custom"></i>
  </a>
</noscript>
```

**Combined Return Value (NEW)**:
```html
<span aria-label="Open Footnote" class="open-dialog" id="open-dialog-1">
  <i class="fa fa-clipboard fa_custom"></i>
</span><noscript><a href="#footnote-1" id="footnote-1-return" aria-label="Footnote 1"><i class="fa fa-clipboard fa_custom"></i></a></noscript>
```

---

## Side Effects

### State Changes

1. **Increments Footnote Counter**:
   ```perl
   my $number = $self->{footnote_number}++;
   ```
   - Before: `$self->{footnote_number} = N`
   - After: `$self->{footnote_number} = N + 1`

2. **Appends to Footnotes Array**:
   ```perl
   push $self->{footnotes}->@* => {
       number  => $number,
       body    => $body,      # JavaScript dialog HTML
       content => $note,      # Raw content for noscript
   };
   ```
   - Before: `$self->{footnotes} = [ ... ]` (length N)
   - After: `$self->{footnotes} = [ ..., {new footnote} ]` (length N+1)

### No External Side Effects
- No file I/O
- No database writes
- No network calls
- No global state modification

---

## Generated Data Structure

Each call to `add_note($note)` creates one footnote hash in `$self->{footnotes}`:

```perl
{
    number  => 1,  # Integer, unique within article
    body    => '<div id="dialog-1" class="dialog" role="dialog" aria-labelledby="note-1" aria-describedby="note-description-1">
        <strong id="note-1">Footnotes</strong>
        <p id="note-description-1" class="sr-only">Note number 1</p>
        <div>CONTENT HERE</div>
        <button type="button" aria-label="Close Navigation" class="close-dialog" id="close-dialog-1">
            <i class="fa fa-times"></i>
        </button>
    </div>',
    content => 'CONTENT HERE',  # Raw HTML content for noscript rendering
}
```

---

## Usage Examples

### Basic Footnote

**Template Code**:
```tt2
[% USE Ovid %]
<p>This article needs a footnote.[% Ovid.add_note('This is the footnote content.') %]</p>
```

**Generated HTML**:
```html
<p>This article needs a footnote.<span aria-label="Open Footnote" class="open-dialog" id="open-dialog-1"><i class="fa fa-clipboard fa_custom"></i></span><noscript><a href="#footnote-1" id="footnote-1-return" aria-label="Footnote 1"><i class="fa fa-clipboard fa_custom"></i></a></noscript></p>
```

**Stored Footnote Data**:
```perl
{
    number  => 1,
    body    => '<div id="dialog-1">...</div>',
    content => 'This is the footnote content.',
}
```

### Footnote with HTML

**Template Code**:
```tt2
[% Ovid.add_note('See <a href="https://example.com">this article</a> for more information.') %]
```

**Stored Content**:
```perl
{
    number  => 1,
    body    => '<div id="dialog-1">...See <a href="https://example.com">this article</a> for more information...</div>',
    content => 'See <a href="https://example.com">this article</a> for more information.',
}
```

### Multiple Footnotes

**Template Code**:
```tt2
[% USE Ovid %]
<p>First reference.[% Ovid.add_note('First footnote') %]</p>
<p>Second reference.[% Ovid.add_note('Second footnote') %]</p>
```

**Stored Data**:
```perl
[
    { number => 1, body => '...', content => 'First footnote' },
    { number => 2, body => '...', content => 'Second footnote' },
]
```

---

## Error Conditions

### Current Behavior (No Validation)
- **Empty Note**: Currently no validation, creates footnote with empty content
- **Undefined Note**: Would likely cause runtime error in string interpolation
- **Non-String Note**: Would stringify (may or may not be desired)

### Recommended Future Validation

```perl
sub add_note ( $self, $note ) {
    croak 'add_note() requires a non-empty note parameter'
        unless defined $note && length $note > 0;
    
    # ... rest of implementation
}
```

### Error Examples

**Undefined Note**:
```perl
Ovid.add_note()  # Missing parameter
# Should die: 'add_note() requires a non-empty note parameter'
```

**Empty Note**:
```perl
Ovid.add_note('')
# Should die: 'add_note() requires a non-empty note parameter'
```

---

## Contract Guarantees

### Uniqueness
- ✅ Each footnote gets a unique sequential number (1, 2, 3, ...)
- ✅ No ID collisions within a single article
- ⚠️ Numbers reset for each article (new Template::Plugin::Ovid instance)

### HTML Safety
- ⚠️ Method does NOT sanitize input - caller must provide safe HTML
- ✅ Generated wrapper HTML is safe (hardcoded)
- ✅ Output is valid HTML5 fragments

### Accessibility
- ✅ JavaScript mode: `aria-label="Open Footnote"` on trigger
- ✅ NoScript mode: `aria-label="Footnote N"` on anchor link
- ✅ Dialog has proper ARIA attributes (`role="dialog"`, `aria-labelledby`, etc.)

### Performance
- ✅ O(1) operation - constant time regardless of number of existing footnotes
- ✅ No I/O operations
- ✅ Minimal memory allocation (one hash per footnote)

---

## Backward Compatibility

### Current Behavior (Pre-Implementation)
```perl
sub add_note ( $self, $note ) {
    # Returns only JavaScript dialog trigger
    return qq{<span class="open-dialog" id="open-dialog-$number">...</span>};
    
    # Stores only dialog body
    push $self->{footnotes}->@* => { number => $number, body => $body };
}
```

### New Behavior (Post-Implementation)
```perl
sub add_note ( $self, $note ) {
    # Returns BOTH JavaScript trigger AND noscript anchor
    return qq{<span class="open-dialog"...>...</span><noscript><a href="#footnote-$number"...>...</a></noscript>};
    
    # Stores dialog body AND raw content
    push $self->{footnotes}->@* => {
        number  => $number,
        body    => $body,     # For JavaScript mode
        content => $note,     # For noscript mode (NEW)
    };
}
```

### Breaking Changes
- ✅ **None** - Return value still contains JavaScript trigger HTML
- ✅ **Additive Only** - Adds noscript HTML and `content` field
- ✅ **Template Compatible** - Existing templates work unchanged (just get extra noscript markup)

---

## Testing Requirements

### Unit Tests

```perl
subtest 'add_note basic functionality' => sub {
    my $plugin = Template::Plugin::Ovid->new($mock_context);
    
    my $html = $plugin->add_note('Test footnote');
    
    # Test JavaScript mode HTML
    like $html, qr/class="open-dialog"/, 'Contains dialog trigger';
    like $html, qr/id="open-dialog-1"/, 'Has correct dialog ID';
    
    # Test NoScript mode HTML (NEW)
    like $html, qr/<noscript>/, 'Contains noscript tag';
    like $html, qr/href="#footnote-1"/, 'Has correct footnote anchor';
    like $html, qr/id="footnote-1-return"/, 'Has correct return anchor ID';
    
    # Test stored data
    my $footnotes = $plugin->get_footnotes();
    is $footnotes->[0]{number}, 1, 'Footnote number is 1';
    like $footnotes->[0]{body}, qr/Test footnote/, 'Body contains content';
    is $footnotes->[0]{content}, 'Test footnote', 'Content field matches input';
};

subtest 'add_note with HTML content' => sub {
    my $plugin = Template::Plugin::Ovid->new($mock_context);
    
    my $html = $plugin->add_note('Footnote with <em>emphasis</em>');
    
    my $footnotes = $plugin->get_footnotes();
    like $footnotes->[0]{content}, qr/<em>emphasis<\/em>/, 'HTML preserved in content';
};

subtest 'add_note sequential numbering' => sub {
    my $plugin = Template::Plugin::Ovid->new($mock_context);
    
    $plugin->add_note('First');
    $plugin->add_note('Second');
    $plugin->add_note('Third');
    
    my $footnotes = $plugin->get_footnotes();
    is $footnotes->[0]{number}, 1, 'First footnote is number 1';
    is $footnotes->[1]{number}, 2, 'Second footnote is number 2';
    is $footnotes->[2]{number}, 3, 'Third footnote is number 3';
};
```

### Coverage Target
- ✅ 100% line coverage for `add_note()` method
- ✅ Test all code paths (happy path, edge cases)
- ✅ Validate both JavaScript and noscript HTML generation

---

## Contract Version

**Version**: 2.0.0 (Major change - adds noscript functionality)  
**Previous Version**: 1.0.0 (JavaScript-only)  
**Status**: Proposed (pending implementation)

---

**Next Contract**: [Footer Template Footnote Rendering](footer_footnote_rendering.md)
