# Data Model: Fix UTF-8 Warnings in Single File Rebuild

**Feature**: 005-utf8-rebuild-warnings  
**Date**: 2025-11-18  
**Status**: Complete

## Overview

This feature involves fixing UTF-8 encoding handling rather than creating new data structures. The entities documented here represent the existing data flow and states that the fix must preserve and correct.

## Entities

### Template File

**Description**: Source template file containing UTF-8 encoded content.

**Attributes**:
- `filename` (string): Absolute path to template file (e.g., `root/blog/article.tt2markdown`)
- `raw_contents` (decoded string): File contents read with `:encoding(UTF-8)` layer, producing Perl character strings with UTF8 flag set
- `type` (enum): Template type - `'article'` or `'blog'`
- `title` (string): Article/blog title extracted from template metadata
- `slug` (string): URL-friendly identifier
- `tags` (array of strings): Topic tags for categorization

**Encoding State**:
- **Input**: UTF-8 bytes on disk
- **After `slurp()`**: Decoded character string (UTF8 flag set, contains Unicode code points)
- **Expected by HTML::TokeParser::Simple**: Requires `utf8_mode(1)` when processing decoded strings

**Validation Rules**:
- File must be valid UTF-8 (per FR-006)
- File must exist and be readable
- Must contain required template metadata (title, type, slug)

**State Transitions**:
1. **On Disk** → `slurp()` → **Decoded Character String**
2. **Decoded String** → `HTML::TokeParser::Simple->new()` + `utf8_mode(1)` → **Parsed HTML Tokens**
3. **Parsed Tokens** → preprocessing → **Preprocessed Content**
4. **Preprocessed Content** → Template Toolkit → **Generated HTML**

### Preprocessed Content

**Description**: Intermediate representation of template after preprocessing but before Template Toolkit rendering.

**Attributes**:
- `content` (decoded string): Template content with TOC, code blocks wrapped, and other macros expanded
- `toc_links` (array of strings): Generated table of contents HTML links
- `tags` (array of strings): Extracted tags from `{{TAGS}}` macro
- `encoding_state` (internal): Must remain as decoded character string throughout preprocessing

**Processing Steps**:
1. Parse markdown headers to build TOC
2. Wrap code blocks in Template Toolkit directives
3. Expand `{{TOC}}` macro
4. Extract and remove `{{TAGS}}` macro
5. Add anchors to headings for TOC links

**Encoding Requirements**:
- Input: Decoded character string from `slurp()`
- HTML parser: Must use `utf8_mode(1)` to handle decoded input
- Output: Decoded character string (preserves UTF-8 characters)
- Passed to Template Toolkit which handles encoding via `--binmode utf8`

### Generated HTML

**Description**: Final HTML output file after Template Toolkit processing.

**Attributes**:
- `filename` (string): Output path (e.g., `articles/article-name.html`)
- `content` (UTF-8 bytes): HTML with proper UTF-8 encoding
- `charset` (metadata): Must include `<meta charset="utf-8">` tag

**Encoding Requirements**:
- Template Toolkit writes UTF-8 bytes to disk via `--binmode utf8` configuration
- Browser interprets as UTF-8 via charset declaration
- All UTF-8 characters from source template must render correctly

**Validation**:
- Must be valid HTML5
- UTF-8 characters must display correctly in browsers
- No encoding corruption (mojibake)

## Data Flow Diagram

```
Template File (UTF-8 bytes on disk)
    ↓
slurp() [with :encoding(UTF-8) layer]
    ↓
Decoded Character String (UTF8 flag set, Unicode code points)
    ↓
HTML::TokeParser::Simple->new(string => $content)
    ↓
** FIX: parser->utf8_mode(1) **  ← Tells parser input is decoded
    ↓
Parse HTML (decode entities to Unicode)
    ↓
Preprocessed Content (decoded character string)
    ↓
Template Toolkit (--binmode utf8, --encoding utf8)
    ↓
Generated HTML (UTF-8 bytes on disk)
    ↓
Browser (interprets via charset=utf-8)
    ↓
Displayed Page (correct UTF-8 rendering)
```

## Encoding States

### State 1: Byte String (UTF8 flag NOT set)

**Characteristics**:
- Raw bytes from file system
- May contain UTF-8 encoded data, but Perl doesn't know this
- Each byte is 0-255
- HTML::Parser's **default expectation** (utf8_mode OFF)

**Example**:
```perl
open my $fh, '<:raw', $file;  # No encoding layer
my $bytes = do { local $/; <$fh> };
# $bytes: UTF-8 bytes but UTF8 flag not set
# café stored as: "\xC3\xA9"
```

### State 2: Character String (UTF8 flag set) ← **Our Case**

**Characteristics**:
- Decoded Unicode code points
- Result of `:encoding(UTF-8)` layer or `decode_utf8()`
- Characters can be > 255
- HTML::Parser requires **utf8_mode(1)** for this state

**Example**:
```perl
open my $fh, '<:encoding(UTF-8)', $file;  # Encoding layer
my $chars = do { local $/; <$fh> };
# $chars: Decoded Unicode characters with UTF8 flag
# café stored as Unicode code points: "caf\x{E9}"
```

## Relationships

### Template File → Preprocessed Content (1:1)

Each template file is preprocessed exactly once per build, producing one preprocessed content representation.

**Processing Function**: `Ovid::Template::File::rewrite()`

**Encoding Constraint**: Must preserve UTF-8 character encoding throughout preprocessing.

### Preprocessed Content → Generated HTML (1:1)

Each preprocessed template is rendered by Template Toolkit to produce one HTML file.

**Processing Function**: Template Toolkit (`ttree`)

**Encoding Constraint**: `--binmode utf8` ensures output is UTF-8 bytes.

### Multiple Files → Tag Map (N:1)

Multiple templates can reference the same tag, aggregated in tag map for tag index pages.

**Not affected by this fix**: Tag handling occurs after UTF-8 is correctly processed.

## Constraints

### Encoding Constraints

1. **Input Constraint**: Template files MUST be valid UTF-8 (enforced by `slurp()` with `:encoding(UTF-8)`)
2. **Processing Constraint**: Decoded strings MUST use `utf8_mode(1)` when passed to HTML::TokeParser::Simple
3. **Output Constraint**: Template Toolkit MUST use `--binmode utf8` for correct output encoding
4. **Validation Constraint**: Invalid UTF-8 in input files MUST cause immediate failure with clear error (FR-006)

### Performance Constraints

Per ASM-006 and constraints section: Performance is explicitly ignored for single-file rebuilds. Correctness takes priority.

### Backward Compatibility Constraints

- Existing templates MUST continue to work without modification (CON-004)
- Full site rebuilds MUST not be affected (User Story 2)
- Generated HTML MUST be identical to pre-fix output (byte-for-byte where UTF-8 is already correct)

## Edge Cases

### Invalid UTF-8 Sequences

**Condition**: Template file contains invalid UTF-8 byte sequences.

**Expected Behavior**: `slurp()` with `:encoding(UTF-8)` layer will die with clear error message indicating file and problem (FR-006).

**Handling**: No special code needed; Perl's encoding layer handles this automatically.

### Mixed Byte/Character Strings

**Condition**: Code path accidentally creates mixed encoded/decoded strings.

**Expected Behavior**: HTML::Parser will warn or croak depending on `utf8_mode` setting.

**Prevention**: Ensure all file I/O uses consistent encoding layers. All `slurp()` calls use `:encoding(UTF-8)`.

### HTML Entities in UTF-8 Content

**Condition**: Template contains both UTF-8 characters (é) and HTML entities (&eacute;).

**Expected Behavior**: With `utf8_mode(1)`:
- UTF-8 character `é` → remains `é` (U+00E9)
- HTML entity `&eacute;` → decoded to `é` (U+00E9)
- Both produce identical output (correct)

**Without Fix**: Entity decoding in context of decoded UTF-8 causes corruption.

### Empty or Binary Files

**Condition**: Template file is empty or contains binary data.

**Expected Behavior**:
- Empty file: Processes successfully (no content to encode)
- Binary file: `:encoding(UTF-8)` layer fails with clear error (desired per edge cases in spec)

## Implementation Impact

### Modified Files

1. **`lib/Ovid/Template/File.pm`**
   - `_preprocess_macros()`: Add `$p->utf8_mode(1)` after line 204
   - Encoding state: Input is decoded string from `$self->_code`

2. **`lib/Ovid/Site.pm`**
   - HTML processing in sitemap generation: Add `$parser->utf8_mode(1)` after line 644
   - Encoding state: Input is decoded string from `slurp($file)`

3. **`lib/Text/Markdown/Blog.pm`**
   - External link processing: Add `$parser->utf8_mode(1)` after line 85
   - Encoding state: Input is decoded string passed to plugin

### No Changes Required

- **`lib/Less/Script.pm`**: `slurp()` and `splat()` already use `:encoding(UTF-8)` correctly
- **Template Toolkit configuration**: `--binmode utf8` already set
- **Template files**: No modifications needed to existing templates

## Testing Data Model

### Test Fixture: UTF-8 Template

**File**: `t/fixtures/utf8_test_template.tt2markdown`

**Required Content**:
- UTF-8 characters: Smart quotes "", em dash —, café, résumé
- HTML entities: `&eacute;`, `&mdash;`, `&hearts;`
- Markdown headers for TOC generation
- Code blocks to test `is_in_code` state handling

**Expected Output**:
- All UTF-8 characters render correctly in HTML
- All entities decode correctly to Unicode
- No encoding warnings in STDERR
- HTML includes `<meta charset="utf-8">`

### Test Assertions

**Encoding State Checks**:
- Input string has UTF8 flag set: `utf8::is_utf8($string)`
- Parser uses utf8_mode: Verified by absence of warnings
- Output HTML is valid UTF-8: Can be read back with `:encoding(UTF-8)`

**Functional Checks**:
- Generated HTML contains expected characters
- No "Parsing of undecoded UTF-8" warnings (FR-001)
- No "Wide character in print" warnings (FR-002)
- UTF-8 characters identical between single and full rebuilds (FR-004)

## Summary

This data model documents the encoding states and transformations that occur during template processing. The fix ensures proper encoding layer handling at the HTML parsing stage by enabling `utf8_mode(1)` when the parser receives decoded character strings. This aligns the parser's expectations with the actual encoding state of the input data, eliminating warnings and preventing potential corruption.
