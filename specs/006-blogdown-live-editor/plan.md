# Implementation Plan: Blogdown Live Editor

**Branch**: `006-blogdown-live-editor` | **Date**: 2025-11-18 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/006-blogdown-live-editor/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Implement a local web-based editor using Dancer2 that allows content authors to write and preview "blogdown" files (articles/blogs) in real-time. The system will auto-save changes to disk and provide a live preview using the existing build logic.

## Technical Context

**Language/Version**: Perl 5.40+
**Primary Dependencies**: Dancer2, Template::Toolkit, Text::Markdown::Blog
**Storage**: Filesystem (source files), SQLite (read-only build data)
**Testing**: Test::Most
**Target Platform**: Localhost (macOS/Linux)
**Project Type**: Web Application (Dancer2) + CLI Launcher
**Performance Goals**: Preview render < 2s
**Constraints**: Bind to 127.0.0.1 only
**Scale/Scope**: Single-user local development tool

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **I. CPAN-Style Module Architecture**: Implemented as `Ovid::App::LiveEditor`.
- [x] **II. CLI-First Interface Design**: Launched via `bin/launch` CLI script.
- [x] **III. Test::Most with 90%+ Coverage**: Will use Test::Most and Devel::Cover.
- [x] **IV. Accessible HTML5 Static Output**: Preview matches production output.
- [x] **V. Zero External Service Dependencies**: Localhost only, no external APIs.
- [x] **VI. Production Data Protection**: Modifies source files only, respects `db/` restrictions.
- [x] **VII. Modern Perl 5.40+ Features**: Will use `use v5.40;` and signatures.
- [x] **VIII. AI Agent Safety Constraints**: N/A (no git ops in feature code).
- [x] **IX. Blogdown Content Format**: Editor supports Markdown + TT directives.

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

```text
# This project: Static site generator (Perl + Template Toolkit)
lib/
├── Ovid/
│   └── App/
│       └── LiveEditor.pm    # Main Dancer2 application
└── Less/
    └── [utility modules].pm # (If needed)

bin/
├── launch                   # CLI script to start the editor
└── rebuild                  # Existing build script (invoked by editor)

root/
├── editor.tt                # Editor interface template
└── [layouts].html           # Existing layouts

t/
├── Ovid/
│   └── App/
│       └── LiveEditor.t     # Tests for the Dancer2 app
└── fixtures/
    └── [test data]

# Generated content - DO NOT MODIFY in feature tasks:
# articles/, blog/, tags/     : Generated HTML
# static/, css/, images/      : User-managed assets
# db/                         : Production databases
# tmp/, cover_db/             : Build artifacts
```

**Structure Decision**:
- `lib/Ovid/App/LiveEditor.pm`: Encapsulates the web application logic.
- `bin/launch`: Entry point for the user.
- `root/editor.tt`: The frontend UI for the editor.

## Complexity Tracking

None. All constitution principles are followed.
