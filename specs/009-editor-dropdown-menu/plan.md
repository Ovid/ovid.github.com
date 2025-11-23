# Implementation Plan: Editor Dropdown Menu

**Branch**: `009-editor-dropdown-menu` | **Date**: 2025-11-23 | **Spec**: [specs/009-editor-dropdown-menu/spec.md](specs/009-editor-dropdown-menu/spec.md)
**Input**: Feature specification from `/Users/ovid/website/specs/009-editor-dropdown-menu/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Refactor the editor toolbar in `root/editor.tt` to consolidate "Change File", "Upload Image", "Light Mode", "Vim Mode", and "Syntax Highlight" controls into a single dropdown menu triggered by a hamburger icon. This improves toolbar space efficiency while retaining all existing functionality and user preferences.

## Technical Context

**Language/Version**: Perl 5.40+ (Backend), JavaScript ES6+ (Frontend), HTML5, CSS3
**Primary Dependencies**: Template Toolkit (Server-side), CodeMirror (Client-side Editor)
**Storage**: `localStorage` (Client-side preferences for theme, vim mode, syntax highlight)
**Testing**: Manual UI testing (Browser-based)
**Target Platform**: Modern Web Browsers (Chrome, Firefox, Safari, Edge)
**Project Type**: Web (Static Site Generator with Client-side Editor)
**Performance Goals**: UI interactions < 100ms
**Constraints**: Must preserve existing `saveContent()` logic and CodeMirror initialization/destruction flows.
**Scale/Scope**: Single file modification (`root/editor.tt`)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. CPAN-Style Module Architecture**: N/A (UI-only change, no new Perl modules)
- **II. CLI-First Interface Design**: N/A (UI-only change)
- **III. Test::Most with 90%+ Coverage**: N/A (Frontend interaction, no Perl logic change)
- **IV. Accessible HTML5 Static Output**: Dropdown must be keyboard accessible and semantic.
- **V. Zero External Service Dependencies**: Compliant (No new dependencies)
- **VI. Production Data Protection**: Compliant (No DB access)
- **VII. Modern Perl 5.40+ Features Preferred**: N/A (Frontend)
- **VIII. AI Agent Safety Constraints**: Compliant
- **IX. Blogdown Content Format**: N/A

## Project Structure

### Documentation (this feature)

```text
specs/009-editor-dropdown-menu/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (N/A for this feature, but file will be created as placeholder)
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (N/A)
└── tasks.md             # Phase 2 output
```

### Source Code (repository root)

```text
# This project: Static site generator (Perl + Template Toolkit)
root/
└── editor.tt            # Editor template with embedded JS/CSS to be modified
```

**Structure Decision**: Modification of `root/editor.tt` only. No new Perl modules or CLI scripts required.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | | |
