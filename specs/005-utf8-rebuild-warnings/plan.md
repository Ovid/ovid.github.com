# Implementation Plan: Fix UTF-8 Warnings in Single File Rebuild

**Branch**: `005-utf8-rebuild-warnings` | **Date**: 2025-11-18 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/005-utf8-rebuild-warnings/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Fix UTF-8 encoding warnings that appear when rebuilding individual template files via `bin/rebuild --file`. The warnings ("Parsing of undecoded UTF-8" from HTML::TokeParser::Simple and "Wide character in print" from Template Toolkit) indicate character encoding layer mismatches that could break website output. The fix involves ensuring consistent UTF-8 handling throughout the preprocessing and template rendering pipeline, specifically when HTML::TokeParser::Simple processes decoded UTF-8 strings.

## Technical Context

**Language/Version**: Perl 5.40+  
**Primary Dependencies**: Template::Toolkit 3.102+, HTML::TokeParser::Simple, Text::Markdown::Blog  
**Storage**: SQLite (build-time data only, in `db/ovid.db`)  
**Testing**: Test::Most with 90%+ coverage requirement  
**Target Platform**: Static site generator (builds on macOS/Linux, deploys anywhere)  
**Project Type**: CLI tool / static site generator  
**Performance Goals**: Per constitution, performance is explicitly ignored for single-file rebuilds (ASM-006)  
**Constraints**: 
- No changes to Template2/ directory (CON-001)
- Must maintain backward compatibility with existing templates (CON-004)
- Solution must work with existing Template Toolkit installation (CON-002)
- Changes should be minimal and focused on encoding layer handling (CON-003)  
**Scale/Scope**: ~200 template files, individual file rebuilds during development workflow

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### ✅ I. CPAN-Style Module Architecture
- **Status**: COMPLIANT
- **Evidence**: Fix will modify existing modules (`Ovid::Template::File`, `Ovid::Site`, possibly `Less::Script`) which already follow CPAN conventions with proper namespacing, POD documentation, and declared dependencies in cpanfile.
- **Action**: Ensure any new utility functions maintain full POD documentation.

### ✅ II. CLI-First Interface Design
- **Status**: COMPLIANT
- **Evidence**: No changes to CLI interface required. Fix is internal to existing `bin/rebuild --file` functionality.
- **Action**: None required.

### ✅ III. Test::Most with 90%+ Coverage
- **Status**: COMPLIANT - requires new tests
- **Evidence**: FR-007 mandates automated tests for UTF-8 handling in single-file rebuilds. Tests must verify UTF-8 characters (smart quotes, em dashes, accented letters) are correctly processed.
- **Action**: Create test file (e.g., `t/utf8_single_file_rebuild.t`) with fixtures containing UTF-8 content. Ensure coverage remains ≥90%.

### ✅ IV. Accessible HTML5 Static Output
- **Status**: COMPLIANT
- **Evidence**: Fix ensures UTF-8 characters display correctly in generated HTML, improving rather than degrading accessibility.
- **Action**: Verify UTF-8 meta charset tags remain in generated HTML.

### ✅ V. Zero External Service Dependencies
- **Status**: COMPLIANT
- **Evidence**: Fix is purely internal encoding handling. No external services involved.
- **Action**: None required.

### ✅ VI. Production Data Protection
- **Status**: COMPLIANT
- **Evidence**: Tests will use fixtures in `t/fixtures/`. No modification of production data files in `db/` directory.
- **Action**: Ensure test fixtures are self-contained and use File::Temp for any temporary output verification.

### ✅ VII. Modern Perl 5.40+ Features Preferred
- **Status**: COMPLIANT
- **Evidence**: Existing modules already use `use v5.40;`, subroutine signatures, and modern features. Fix will maintain this standard.
- **Action**: Use signatures for any new subroutines. Prefer `try/catch` if error handling is needed.

### ✅ VIII. AI Agent Safety Constraints
- **Status**: COMPLIANT
- **Evidence**: No git operations performed by this feature implementation.
- **Action**: None required.

### ✅ IX. Blogdown Content Format
- **Status**: COMPLIANT
- **Evidence**: Fix ensures blogdown templates with UTF-8 content process correctly. Preserves existing content format.
- **Action**: None required.

### ✅ Development Scope Boundaries
- **Status**: COMPLIANT
- **Evidence**: Changes confined to `lib/` (Ovid::Template::File, Ovid::Site, possibly Less::Script) and `t/` (new test file). No modification of generated content or user assets.
- **Action**: Document which specific modules are modified in research.md.

**GATE RESULT**: ✅ **PASS** - All constitution principles satisfied. No violations to justify.

**POST-PHASE 1 RE-EVALUATION**: ✅ **PASS** - Design completed in Phase 1 confirms:
- Changes limited to 3 files in `lib/` directory (Ovid::Template::File, Ovid::Site, Text::Markdown::Blog)
- New test file in `t/` directory with fixtures
- No API changes, no new dependencies, no architectural modifications
- Implementation is minimal (adding `->utf8_mode(1)` calls) and focused on encoding layer handling
- All constitution principles remain satisfied

## Project Structure

### Documentation (this feature)

```text
specs/005-utf8-rebuild-warnings/
├── spec.md              # Feature specification (already exists)
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command) - N/A for this feature
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
# This project: Static site generator (Perl + Template Toolkit)
lib/
├── Ovid/
│   └── Site.pm                    # WILL MODIFY: _run_ttree_single() add --encoding/--binmode flags
└── ...                            # No other lib/ changes needed

bin/
└── rebuild                        # NO CHANGES: delegates to Ovid::Site

t/
├── utf8_single_file_rebuild.t     # WILL CREATE: new test for UTF-8 handling
└── fixtures/
    └── utf8_test_template.tt      # WILL CREATE: test fixture with UTF-8 content

# Generated content - DO NOT MODIFY in feature tasks:
# articles/, blog/, tags/     : Generated HTML
# static/, css/, images/      : User-managed assets
# db/                         : Production databases
# tmp/, cover_db/             : Build artifacts
```

**Structure Decision**: This feature modifies only `Ovid::Site` to add the missing `--encoding` and `--binmode` flags to the `_run_ttree_single()` method, matching what `_run_ttree()` already uses for full rebuilds. New tests in `t/utf8_single_file_rebuild.t` will verify the fix with real UTF-8 template fixtures.

