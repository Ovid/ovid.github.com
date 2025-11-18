# Quickstart: Fix UTF-8 Warnings in Single File Rebuild

**Feature**: 005-utf8-rebuild-warnings  
**Date**: 2025-11-18  
**For**: Developers implementing the fix

## What This Feature Does

Eliminates UTF-8 encoding warnings that appear when rebuilding individual template files via `bin/rebuild --file <template>`. The fix adds the same UTF-8 encoding flags to the single-file rebuild that the full rebuild already uses.

**Root Cause**: The single-file rebuild was missing `--encoding utf8` and `--binmode utf8` flags when calling Template Toolkit's `ttree` command. The full rebuild includes these flags, which is why it doesn't produce warnings.

## Before You Start

### Prerequisites

1. **Environment activated**:
   ```bash
   source ~/.bash_profile  # Activates perlbrew + Perl 5.40
   perl -v                 # Verify Perl 5.40+
   ```

2. **Dependencies installed**:
   ```bash
   cpanm --installdeps . --with-configure --with-develop --with-all-features
   ```

3. **Verify the problem exists**:
   ```bash
   perl bin/rebuild --file root/blog/torturing-an-llm.tt2markdown --notest
   ```
   
   You should see warnings:
   - `Parsing of undecoded UTF-8 will give garbage when decoding entities`
   - `Wide character in print`

### Key Files

- **`lib/Ovid/Site.pm`**: Contains both `_run_ttree()` (full rebuild, has flags) and `_run_ttree_single()` (single file rebuild, missing flags)
- **`bin/rebuild`**: CLI entry point that delegates to `Ovid::Site`

## Implementation Steps

### Step 1: Add UTF-8 Encoding Flags to Single File Rebuild

**File**: `lib/Ovid/Site.pm`  
**Method**: `_run_ttree_single`  
**Location**: Around line 127-135

```perl
# FIND THIS:
my @command = (
    'perl', '-Ilib',
    $ttree,
    '--verbose',
    '--src=tmp',
    '--dest=.',
    '--lib=include',
    $relative_file,
);

# CHANGE TO:
my @command = (
    'perl', '-Ilib',
    $ttree,
    '--verbose',
    '--src=tmp',
    '--dest=.',
    '--lib=include',
    '--binmode'  => 'utf8',     # encoding of output file (same as _run_ttree)
    '--encoding' => 'utf8',     # encoding of input files (same as _run_ttree)
    $relative_file,
);
```

**Why**: These are the exact same flags that `_run_ttree()` uses for full rebuilds (line 465-467). They tell Template Toolkit that input files are UTF-8 and output should be UTF-8.

**That's it!** This is the only code change needed.

### Step 2: Create Test File

**File**: `t/utf8_single_file_rebuild.t`

```perl
use Test::Most;
use Capture::Tiny 'capture';
use Less::Script;
use File::Temp;
use File::Spec::Functions 'catfile';

# Create test fixture with UTF-8 content
my $fixture_content = <<'TEMPLATE';
[%
    title            = 'UTF-8 Test Article';
    type             = 'blog';
    slug             = 'utf8-test';
    date             = '2025-11-18';
%]
[% WRAPPER include/wrapper.tt blogdown=1 -%]

{{TOC}}

# Testing UTF-8 Characters

Smart quotes: "Hello" 'world'
Em dash: —
Café résumé

# HTML Entities

Entity test: &eacute; &mdash; &hearts;

[% END %]
TEMPLATE

my $tempdir = File::Temp->newdir();
my $fixture_file = catfile($tempdir, 'utf8_test.tt2markdown');
splat($fixture_file, $fixture_content);

# Test: rebuild single file without warnings
my ($stdout, $stderr, $exit) = capture {
    system('perl', 'bin/rebuild', '--file', $fixture_file, '--notest');
};

# Verify no UTF-8 warnings
unlike $stderr, qr/Parsing of undecoded UTF-8/i, 
    'No "Parsing of undecoded UTF-8" warning';
unlike $stderr, qr/Wide character in print/i,
    'No "Wide character in print" warning';

# Verify build succeeded
is $exit, 0, 'Build completed successfully';

# Verify output contains UTF-8 characters correctly
my $output_file = catfile($tempdir->dirname, 'blog', 'utf8-test.html');
SKIP: {
    skip "Output file not generated", 3 unless -f $output_file;
    
    my $html = slurp($output_file);
    
    like $html, qr/café/i, 'UTF-8 characters preserved in output';
    like $html, qr/résumé/i, 'Accented characters preserved';
    like $html, qr/charset=.utf-8./i, 'UTF-8 charset declared in HTML';
}

done_testing();
```

**Why**: Verifies the fix works and prevents future regressions (FR-007, Constitution III).

### Step 3: Run Tests

```bash
# Run specific test
prove -lv t/utf8_single_file_rebuild.t

# Run full test suite
prove -l t/

# Check coverage
cover -test
cover -report html -outputdir coverage-report
```

**Expected**: All tests pass, no UTF-8 warnings, coverage ≥90%.

### Step 4: Verify Fix with Real Templates

```bash
# Test with actual template that caused the issue
perl bin/rebuild --file root/blog/torturing-an-llm.tt2markdown --notest

# Should see NO warnings about UTF-8
# Output should show: "Single file rebuild complete."
```

### Step 5: Full Site Rebuild

```bash
# Verify full rebuild still works
perl bin/rebuild

# Should complete without new warnings
# All tests should pass
```

## Verification Checklist

- [ ] No "Parsing of undecoded UTF-8" warnings during single-file rebuild
- [ ] No "Wide character in print" warnings
- [ ] New test file passes: `prove -lv t/utf8_single_file_rebuild.t`
- [ ] Full test suite passes: `prove -l t/`
- [ ] Test coverage ≥90%: `cover -test`
- [ ] Full site rebuild works: `perl bin/rebuild`
- [ ] UTF-8 characters display correctly in generated HTML
- [ ] All existing functionality unchanged (User Story 2)

## Troubleshooting

### Problem: Still seeing UTF-8 warnings

**Solution**: Verify you added both `--binmode => 'utf8'` AND `--encoding => 'utf8'` to the `@command` array in `_run_ttree_single`. Both flags are required.

**Double-check**: Compare your `_run_ttree_single` with `_run_ttree` (line 465-467). They should now have the same encoding flags.

### Problem: Test fails because ttree can't find the file

**Solution**: Ensure `$relative_file` is the LAST argument in the `@command` array, after all the flags. Template Toolkit expects the file path at the end.

### Problem: Tests fail with "wide character" errors

**Solution**: Ensure test fixtures are saved with UTF-8 encoding:
```bash
file -I t/fixtures/utf8_test_template.tt2markdown
# Should show: charset=utf-8
```

### Problem: Coverage below 90%

**Solution**: Add more test cases to `t/utf8_single_file_rebuild.t`:
- Test with different UTF-8 characters (emoji, CJK, etc.)
- Test comparison between single-file and full rebuild output
- Test error handling for invalid UTF-8 (should fail cleanly)

### Problem: Full rebuild shows new warnings

**Cause**: Unlikely with this fix, since we're matching what the full rebuild already does.

**Solution**: Review your changes carefully. You should ONLY have modified the `@command` array in `_run_ttree_single`. Verify with:
```bash
git diff lib/Ovid/Site.pm
```

## Understanding the Fix

### Why These Flags?

Template Toolkit's `ttree` command needs to know:
1. **`--encoding utf8`**: "The input template files are UTF-8 encoded"
2. **`--binmode utf8`**: "Write output files with UTF-8 encoding"

Without these flags, ttree treats input as bytes and outputs without UTF-8 layer, causing:
- "Parsing of undecoded UTF-8" warnings
- "Wide character in print" warnings

### Why Didn't Full Rebuild Warn?

The full rebuild (`_run_ttree` method) already includes these flags (line 465-467):
```perl
'--binmode'  => 'utf8',
'--encoding' => 'utf8',
```

The single-file rebuild (`_run_ttree_single`) was missing them. Now they match!

### The Data Flow

```
Template File (UTF-8 bytes on disk)
    ↓
ttree with --encoding utf8 (knows input is UTF-8)
    ↓
Template Toolkit processes correctly
    ↓
ttree with --binmode utf8 (writes UTF-8 output)
    ↓
HTML File (UTF-8 bytes, properly encoded)
```

## What NOT to Do

❌ **Don't change anything in `_run_ttree()`**: The full rebuild already works correctly  
❌ **Don't remove the existing flags**: Keep `--verbose`, `--src`, `--dest`, `--lib`  
❌ **Don't change file reading**: `slurp()` and preprocessing are fine  
❌ **Don't suppress warnings**: They indicate real problems  
❌ **Don't skip tests**: Required by Constitution Principle III  

## Success Criteria

✅ Zero UTF-8 warnings when running `bin/rebuild --file <template>`  
✅ UTF-8 characters display identically in single-file and full rebuilds  
✅ All existing tests pass  
✅ New tests verify UTF-8 handling  
✅ Test coverage ≥90%  

## Next Steps

After completing this implementation:

1. **Review**: Have another developer review the changes
2. **Format**: Run `perltidy --profile=.perltidyrc lib/**/*.pm`
3. **Commit**: Commit with clear message referencing spec
4. **Document**: Update any relevant documentation

## Getting Help

- **Research document**: See `research.md` for detailed technical analysis
- **Data model**: See `data-model.md` for encoding state flow
- **Feature spec**: See `spec.md` for complete requirements
- **Constitution**: See `.specify/memory/constitution.md` for coding standards

## Time Estimate

- **Implementation**: 10-15 minutes (add 2 lines to 1 file)
- **Testing**: 60-90 minutes (create fixtures, write tests)
- **Verification**: 15-30 minutes (run full suite, check coverage)

**Total**: ~1.5-2.5 hours for complete, tested implementation.
