# Implementation Plan: Test Coverage Improvement

**Branch**: `001-test-coverage-improvement` | **Date**: 2025-11-09 | **Spec**: /Users/ovid/website/specs/001-test-coverage-improvement/spec.md
**Input**: Feature specification from `/specs/001-test-coverage-improvement/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Systematically increase test coverage for all 15 modules in the legacy Perl static site generator to at least 90% statement coverage and highest possible branch coverage, using Test::Most and Devel::Cover, after identifying and documenting unused code.

## Technical Context

**Language/Version**: Perl 5.40+  
**Primary Dependencies**: Devel::Cover, Test::Most, Type::Tiny, Getopt::Long, SQLite  
**Storage**: SQLite for build-time data (acceptable per constitution)  
**Testing**: Test::Most with Devel::Cover for coverage reporting  
**Target Platform**: Cross-platform (macOS, Linux), command-line static site generation  
**Project Type**: CLI tool/library for static website building  
**Performance Goals**: Build process <2 min, test suite <60 sec, coverage report regeneration <2 min  
**Constraints**: Zero external service dependencies, accessible HTML5 output, 90%+ coverage, CLI-first interface  
**Scale/Scope**: 15 modules, incremental per-module testing, no architecture changes

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. CPAN-Style Module Architecture**: PASS - All modules follow Ovid:: namespace, proper structure.
- **II. CLI-First Interface Design**: PASS - Build scripts in bin/, use Getopt::Long.
- **III. Test::Most with 90%+ Coverage**: PASS - This feature implements the required testing discipline.
- **IV. Accessible HTML5 Static Output**: PASS - Site generates accessible HTML5.
- **V. Zero External Service Dependencies**: PASS - No external APIs required for core build.
- **VI. Modern Perl 5.40+ Features Preferred**: PASS - Code uses signatures, modern features.
- **VII. AI Agent Safety Constraints**: PASS - No destructive git operations planned.

All gates pass. No violations to justify.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

This is a single Perl project with standard CPAN-style structure:

```text
lib/                    # Perl modules (Ovid::*, Less::*, Template::Plugin::*)
├── Ovid/
│   ├── Site.pm
│   ├── Site/
│   │   ├── AI/
│   │   │   └── Images.pm
│   │   └── Utils.pm
│   ├── Template/
│   │   ├── File.pm
│   │   ├── File/
│   │   │   ├── Collection.pm
│   │   │   └── FindCode.pm
│   │   └── Role/
│   │       ├── Debug.pm
│   │       └── File.pm
│   └── Types.pm
├── Less/
│   ├── Boilerplate.pm
│   ├── Config.pm
│   ├── Pager.pm
│   └── Script.pm
├── Template/
│   └── Plugin/
│       ├── Config.pm
│       └── Ovid.pm
└── Text/
    └── Markdown/
        └── Blog.pm

bin/                    # CLI scripts (article, rebuild, analyze-usage)
├── article
├── rebuild
└── analyze-usage       # New: usage analysis tool (to be created)

t/                      # Test files (mirrors lib/ structure)
├── fixtures/           # Test fixtures and sample data
├── integration/        # Integration tests (to be created)
├── Ovid/
│   ├── Site.t
│   └── ...
└── ...

config/                 # Configuration files
db/                     # SQLite databases for build-time data
cover_db/               # Coverage reports (excluded from version control)
coverage-report/        # HTML coverage output (excluded from version control)

specs/001-test-coverage-improvement/
├── spec.md
├── plan.md             # This file
├── tasks.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
├── baseline-coverage.md            # To be created
├── usage-analysis-results.md       # To be created
├── unused-code-decisions.md        # To be created
├── coverage-exceptions.md          # To be created
├── branch-coverage-exceptions.md   # To be created
├── test-strategies.md              # To be created
├── fixture-guide.md                # To be created
├── coverage-summary.md             # To be created
└── lessons-learned.md              # To be created
```

**Structure Decision**: Standard single-project CPAN-style Perl application with test-first development approach. All modules follow namespace conventions (Ovid::, Less::, Template::Plugin::, Text::). Test files in `t/` mirror the `lib/` directory structure. Coverage tooling output goes to `cover_db/` and `coverage-report/` directories.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
