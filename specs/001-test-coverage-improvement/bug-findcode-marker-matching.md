# Bug Report: Incorrect Marker Matching in Ovid::Template::File::FindCode

**Date Discovered**: 2025-11-09  
**File**: `lib/Ovid/Template/File/FindCode.pm`  
**Severity**: Medium  
**Status**: Documented (not fixed during coverage improvement)

## Summary

The `_is_tt()` method in `Ovid::Template::File::FindCode` accepts a `$marker` parameter but ignores it, always checking `$self->_marker` instead. This is inconsistent with the parallel `_is_markdown()` method and causes unexpected marker matching behavior.

## The Bug

### Current Implementation (Lines 135-137)

```perl
sub _is_tt ( $self, $marker = $self->_marker ) {
    return $self->is_in_code && $self->_marker eq 'WRAPPER';
}
```

**Problem**: The `$marker` parameter is accepted but never used. The method always checks `$self->_marker` regardless of what marker is passed in.

### Compare with _is_markdown (Lines 132-134)

```perl
sub _is_markdown ( $self, $marker = $self->_marker ) {
    return $self->is_in_code && $marker eq '```';
}
```

**Correct**: This method properly uses the `$marker` parameter in its comparison.

## Impact

### Unexpected Behavior

When in a TT code block (WRAPPER), a markdown closing marker (```) will incorrectly close the block:

```perl
my $state = Ovid::Template::File::FindCode->new( filename => "test.tt" );
$state->parse('[% WRAPPER include/code.tt language="perl" %]');
# Now in TT code block, marker = 'WRAPPER'

$state->parse('```');
# BUG: This closes the TT block! 
# Expected: Should stay in code block (mismatched markers)
# Actual: Exits code block
```

### Why This Happens

In `_markers_match($marker)`:

```perl
return ( $self->_is_markdown && $self->_is_markdown($marker) 
      || $self->_is_tt && $self->_is_tt($marker) );
```

When checking if ``` closes a TT block:
1. `$self->_is_markdown` = `is_in_code && _marker eq '```'` = false (marker is 'WRAPPER')
2. `$self->_is_markdown('```')` = `is_in_code && '```' eq '```'` = true
3. First part: `false && true` = false
4. `$self->_is_tt` = `is_in_code && _marker eq 'WRAPPER'` = true
5. `$self->_is_tt('```')` = `is_in_code && _marker eq 'WRAPPER'` = true ⚠️ **BUG: Should check if '```' eq 'WRAPPER'**
6. Second part: `true && true` = true
7. Result: true (markers match - INCORRECT!)

### Expected Behavior

The `_is_tt()` method should work like `_is_markdown()`:

```perl
sub _is_tt ( $self, $marker = $self->_marker ) {
    return $self->is_in_code && $marker eq 'WRAPPER';  # Use $marker parameter
}
```

With this fix:
- `_is_tt('```')` would return `is_in_code && '```' eq 'WRAPPER'` = false
- `_markers_match('```')` would return false when in a TT block
- Markdown markers would NOT close TT blocks (correct behavior)

## Current Workaround

The bug has been documented in tests with explanatory comments:

```perl
# Note: Due to implementation quirk in _is_tt(), markdown marker DOES close TT blocks
$state->parse('```');
ok !$state->is_in_code, 'Markdown marker closes TT block (implementation behavior)';
```

## Recommendation

### Fix the Bug

Change line 136 in `lib/Ovid/Template/File/FindCode.pm`:

```perl
# Before (BUGGY):
sub _is_tt ( $self, $marker = $self->_marker ) {
    return $self->is_in_code && $self->_marker eq 'WRAPPER';
}

# After (FIXED):
sub _is_tt ( $self, $marker = $self->_marker ) {
    return $self->is_in_code && $marker eq 'WRAPPER';
}
```

### Update Tests

After fixing, update `t/code_blocks.t` to expect correct behavior:

```perl
# Start with TT block
$state->parse('[% WRAPPER include/code.tt language="java" %]');
ok $state->is_in_code, 'Should be in TT code block';

# Try to close with markdown marker
$state->parse('```');
ok $state->is_in_code, 'Markdown marker should NOT close TT block';
ok !$state->is_end_marker, 'Mismatched marker should not be recognized';

# Close with correct TT END tag
$state->parse('[% END %]');
ok !$state->is_in_code, 'TT END should close TT block';
```

## Why Not Fixed During Coverage Work

Per the project constitution (AI Agent Safety Constraints):

> "When working on test coverage improvements, focus on testing existing behavior rather than fixing bugs unless explicitly instructed. Document bugs found but don't fix them without permission."

This bug was discovered during Phase 4, Group 4 (T069-T077) of the test coverage improvement work. Rather than changing the implementation behavior, the tests were written to match the current (buggy) behavior and the bug was documented for future remediation.

## Additional Notes

- The bug has likely existed since the module was created
- No production issues reported (may indicate this code path is rarely used, or users expect/accept the behavior)
- Fixing this bug is a one-line change but would be a **breaking change** if any code relies on the current behavior
- Before fixing, search the codebase for usage patterns to assess impact

## Related Files

- Implementation: `lib/Ovid/Template/File/FindCode.pm`
- Tests: `t/code_blocks.t` (lines 152-184, "Mismatched markers" subtest)
- Coverage spec: `specs/001-test-coverage-improvement/tasks.md` (T069-T070)
