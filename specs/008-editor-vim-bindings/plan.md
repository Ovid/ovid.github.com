# Implementation Plan: Editor Vim Bindings

**Branch**: `008-editor-vim-bindings` | **Date**: 2025-11-22 | **Spec**: `specs/008-editor-vim-bindings/spec.md`
**Input**: Feature specification from `/specs/008-editor-vim-bindings/spec.md`

**Note**: Generated/resumed via `/speckit.plan` workflow.
## Summary

Add optional Vim keybindings to the existing CodeMirror-based editor with a UI checkbox toggle, persisted in `localStorage`, plus interception of `Ctrl-S` / `Cmd-S` for saving without triggering the browser "Save Page" dialog. Assets (CodeMirror core + vim keymap) are vendored locally to comply with Zero External Service Dependencies. Status indicator displays current Vim mode.
## Technical Context

**Language/Version**: Perl 5.40+ (backend), JavaScript ES6 (frontend), CodeMirror 5.65.16  
**Primary Dependencies**: Vendored CodeMirror 5.65.16 core, `keymap/vim.js`; existing `saveContent()` logic; `localStorage`  

**Storage**: Client-side only (`localStorage: vimMode`); no new server storage  
**Testing**: Perl: Test::Most unit test for new module `Ovid::Editor::VimMode` (injection/config); JS behavior manually verifiable + optional future harness (NEEDS CLARIFICATION: JS automated test approach)  

**Target Platform**: Modern desktop browsers (Chrome, Firefox, Safari) within site editor page  
**Project Type**: Static site generator enhancement (frontend asset + minor backend module)  

**Performance Goals**: No measurable increase in editor load (> +50ms); keymap toggle latency < 20ms; save shortcut debounce prevents parallel requests  
**Constraints**: Zero external service dependencies; Do not modify generated directories; Maintain accessibility (checkbox focusable & labeled)  

**Scale/Scope**: Single editor page feature; one new Perl module; vendored JS assets; no global architectural changes
Outstanding Clarifications Resolved in `research.md`: location of existing editor template, save function reuse, vim keymap vendoring. Remaining NEEDS CLARIFICATION: automated JS test strategy (out of scope for Phase 1—documented for later).

## Constitution Check
Pre-Design Gate Evaluation:
- Principle I (CPAN-Style Module): Will add `lib/Ovid/Editor/VimMode.pm` to encapsulate asset path logic and future expansion. PASS (pending implementation).
- Principle II (CLI-First): No new CLI necessary; feature integrates with existing editor page. Justification: purely client-side enhancement; no backend workflow change. PASS.
- Principle III (90%+ Coverage): New Perl module will include tests; existing JS not under Perl coverage metrics (acceptable—JS harness TBD). PASS (commit requires tests).
- Principle IV (Accessible HTML5): Checkbox will include `<label>` and status text; no impact on generated HTML validity. PASS.
- Principle V (Zero External Dependencies): CDN links replaced with local vendored assets. PASS.
- Principle VI (Production Data Protection): No writes to `db/`; only static assets and template edits. PASS.
- Principle VII (Modern Perl 5.40+): New module uses signatures & `use v5.40;`. PASS.
- Principle VIII (AI Safety): Plan does not invoke destructive git operations. PASS.
- Principle IX (Blogdown Format): Unaffected (editor UI only). PASS.

GATE STATUS: All non-negotiables satisfied or planned; proceed to Phase 0 (already completed previously) and Phase 1 design artifacts.
**Structure Decision**:
- Add: `lib/Ovid/Editor/VimMode.pm` (module to expose asset registration and potential future editor config helpers)
- Modify: `root/editor.tt` (swap CDN for local assets; add Vim Mode checkbox, status area, initialization logic)
- Add Assets: `static/js/codemirror/*` (vendored CodeMirror core + vim keymap)
- No changes: `bin/` (no CLI needed)
- Tests: `t/Ovid/Editor/VimMode.t` covering module functions (asset path provision, configuration hints)

## Phases

1. **Setup**: Project initialization and basic structure.
2. **Foundational**: Core infrastructure (vendoring assets, Perl module) - Blocking.
3. **User Story 1 (MVP)**: Toggle Vim Mode, persistence, and status display.
4. **User Story 2**: Save with Keyboard Shortcut (Ctrl-S/Cmd-S).
5. **Polish**: Accessibility and error checking.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (none) | — | — |