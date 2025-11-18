# Research: Fix UTF-8 Warnings in Single File Rebuild

**Feature**: 005-utf8-rebuild-warnings  
**Date**: 2025-11-18  
**Status**: Complete

## Overview

This document contains research findings for resolving UTF-8 encoding warnings that appear during single-file rebuilds. The warnings indicate character encoding layer mismatches between decoded UTF-8 strings from file I/O and HTML parsing libraries.

## Research Tasks Completed

1. ✅ Root cause of "Parsing of undecoded UTF-8" warning with HTML::TokeParser::Simple
2. ✅ Best practice solution for UTF-8 handling with HTML parsers
3. ✅ Alternative approaches evaluation
4. ✅ Template Toolkit "Wide character in print" warning analysis
5. ✅ Implementation approach and code changes needed

## Decision 1: Add Missing --encoding and --binmode Flags to Single File Rebuild

### Rationale

**Root cause discovered**: The single-file rebuild (`_run_ttree_single`) is missing the `--encoding` and `--binmode` flags that the full rebuild (`_run_ttree`) uses.

**Full rebuild** (line 465-467 in `Ovid::Site`):
```perl
'--binmode'  => 'utf8',    # encoding of output file
'--encoding' => 'utf8',    # encoding of input files
```

**Single file rebuild** (line 127-135):
```perl
# MISSING: No --binmode or --encoding flags!
```

Without `--encoding => 'utf8'`, Template Toolkit doesn't know the input files are UTF-8 encoded, causing:
1. **"Parsing of undecoded UTF-8" warning**: Template Toolkit internally processes templates without proper UTF-8 handling
2. **"Wide character in print" warning**: Output isn't set to UTF-8 mode without `--binmode`

**The correct solution**: Add the same `--encoding` and `--binmode` flags to `_run_ttree_single` that are used in `_run_ttree`.

### Alternatives Considered

**Alternative 1: Enable utf8_mode on HTML::TokeParser::Simple**
- **Why rejected**: This would only fix warnings from HTML parsing during preprocessing, not the Template Toolkit warnings. The real issue is that ttree needs to know about UTF-8 encoding. Additionally, the full rebuild doesn't need this, so it's not the root cause.

**Alternative 2: Change how files are read**
- **Why rejected**: The `slurp()` function with `:encoding(UTF-8)` is correct and used throughout the codebase. Changing this would affect all callers and create inconsistency.

**Alternative 3: Suppress warnings**
- **Why rejected**: Never appropriate. Warnings indicate real problems with encoding handling that could lead to corrupted output.

### Implementation Notes

**File to modify**: `lib/Ovid/Site.pm`

**Location**: `_run_ttree_single` method (around line 127-135)

**Change**:
```perl
# BEFORE (missing encoding flags):
my @command = (
    'perl', '-Ilib',
    $ttree,
    '--verbose',
    '--src=tmp',
    '--dest=.',
    '--lib=include',
    $relative_file,
);

# AFTER (add encoding flags to match _run_ttree):
my @command = (
    'perl', '-Ilib',
    $ttree,
    '--verbose',
    '--src=tmp',
    '--dest=.',
    '--lib=include',
    '--binmode'  => 'utf8',     # encoding of output file
    '--encoding' => 'utf8',     # encoding of input files
    $relative_file,
);
```

**Verification**: The full rebuild (`_run_ttree`) uses these exact same flags and doesn't produce warnings.

### Edge Cases

1. **Flag order**: The `$relative_file` must remain as the last argument after all flags, as ttree expects the file path at the end.

2. **Consistency with full rebuild**: Any future changes to encoding flags in `_run_ttree` should be mirrored in `_run_ttree_single`.

3. **No impact on preprocessing**: This fix only affects Template Toolkit's processing. The preprocessing step (which runs for both modes) already works correctly.

## Decision 2: Why Full Rebuild Works

### Analysis

The full rebuild uses `_run_ttree()` which includes:
```perl
'--binmode'  => 'utf8',    # encoding of output file
'--encoding' => 'utf8',    # encoding of input files
```

These flags tell Template Toolkit:
- **`--encoding utf8`**: Input template files are UTF-8 encoded
- **`--binmode utf8`**: Output files should be written with UTF-8 encoding

With these flags, Template Toolkit properly handles UTF-8 throughout the processing pipeline, preventing both warnings.

### Why Single File Rebuild Failed

The `_run_ttree_single()` method was calling ttree **without** these encoding flags, causing Template Toolkit to:
1. Not recognize input as UTF-8 → "Parsing of undecoded UTF-8" warnings
2. Not set output to UTF-8 mode → "Wide character in print" warnings

### Solution

Add the same `--binmode` and `--encoding` flags to `_run_ttree_single()` that are used in `_run_ttree()`.

## Decision 3: Testing Strategy

### Rationale

Per FR-007 and Constitution Principle III, comprehensive tests are mandatory with 90%+ coverage.

### Test Requirements

**New test file**: `t/utf8_single_file_rebuild.t`

**Test cases must include**:
1. Template with UTF-8 characters (smart quotes: "", em dashes: —, accented letters: café)
2. Template with HTML entities (`&eacute;`, `&mdash;`, `&hearts;`)
3. Verify no warnings in STDERR during single-file rebuild
4. Verify generated HTML contains correctly encoded UTF-8
5. Compare single-file output with full rebuild output (should be identical)

**Test fixture**: `t/fixtures/utf8_test_template.tt2markdown`

**Test approach**:
```perl
use Test::Most;
use Capture::Tiny 'capture';

# Capture STDERR to verify no warnings
my ($stdout, $stderr, $exit) = capture {
    system('perl', 'bin/rebuild', '--file', $fixture_path, '--notest');
};

ok $stderr !~ /Parsing of undecoded UTF-8/, 'No UTF-8 parsing warnings';
ok $stderr !~ /Wide character in print/, 'No wide character warnings';

# Verify output correctness
my $output = slurp($generated_html);
like $output, qr/café/, 'UTF-8 characters preserved';
like $output, qr/charset=.utf-8./i, 'UTF-8 charset declared';
```

## Summary of Decisions

| Decision | Action | Files Affected |
|----------|--------|----------------|
| **Add encoding flags to single-file rebuild** | Add `--binmode => 'utf8'` and `--encoding => 'utf8'` to ttree command | `Ovid::Site` (`_run_ttree_single` method) |
| **Testing** | Create comprehensive UTF-8 test with comparison to full rebuild | `t/utf8_single_file_rebuild.t`, `t/fixtures/` |

## Technical Reference

### Character Encoding Layers in Perl

**Decoded character strings** (UTF8 flag set):
- Result of reading with `:encoding(UTF-8)` layer
- Internal Perl representation as Unicode code points
- Can contain characters > 255

**Byte strings** (UTF8 flag not set):
- Raw bytes from file
- May represent UTF-8 encoded data, but not decoded
- HTML::Parser's default expectation

### HTML::Parser Inheritance Chain

```
HTML::TokeParser::Simple (v3.16)
  └─> HTML::TokeParser
       └─> HTML::PullParser
            └─> HTML::Parser (provides utf8_mode method)
```

### References

- HTML::Parser documentation: `utf8_mode` method
- perlunifaq: Perl Unicode FAQ
- perluniintro: Introduction to Unicode in Perl
- Constitution Principle III: Test coverage requirements
- Feature Spec FR-007: Test requirements for UTF-8 handling

## Risk Assessment

**Risk Level**: Very Low

**Justification**:
- We're simply adding the same flags that the full rebuild already uses
- The full rebuild proves these flags work correctly
- Minimal change (adding 2 parameters to an array)
- Backward compatible (only affects behavior for files with UTF-8 content)
- Testable with deterministic fixtures

**Mitigation**:
- Comprehensive test coverage with UTF-8 fixtures
- Compare single-file output with full rebuild output
- Full test suite must pass per Constitution requirements
