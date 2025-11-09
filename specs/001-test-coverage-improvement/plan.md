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
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
# [REMOVE IF UNUSED] Option 1: Single project (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# [REMOVE IF UNUSED] Option 2: Web application (when "frontend" + "backend" detected)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# [REMOVE IF UNUSED] Option 3: Mobile + API (when "iOS/Android" detected)
api/
└── [same as backend above]

ios/ or android/
└── [platform-specific structure: feature modules, UI flows, platform tests]
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
