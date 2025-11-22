---
description: "Task list for Editor Vim Bindings feature"
---

# Tasks: Editor Vim Bindings

**Input**: Design documents from `/specs/008-editor-vim-bindings/`
**Prerequisites**: plan.md, spec.md, research.md, contracts/openapi.yaml

**Tests**: Tests are included for the new Perl module. JS testing is manual per plan.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Create directory `static/js/codemirror` for vendored assets

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T002 [P] Vendor CodeMirror 5.65.16 core JS to `static/js/codemirror/codemirror.js` (Source: `https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/codemirror.min.js`)
- [ ] T003 [P] Vendor CodeMirror Vim keymap to `static/js/codemirror/vim.js` (Source: `https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/keymap/vim.min.js`)
- [ ] T004 [P] Vendor CodeMirror CSS to `static/js/codemirror/codemirror.css` (Source: `https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/codemirror.min.css`)
- [ ] T005 Create `lib/Ovid/Editor/VimMode.pm` with asset path helpers and configuration logic
- [ ] T006 Create `t/Ovid/Editor/VimMode.t` to test module instantiation and asset path methods

**Checkpoint**: Foundation ready - Assets exist and backend module is tested.

---

## Phase 3: User Story 1 - Toggle Vim Mode (Priority: P1) 🎯 MVP

**Goal**: Users can toggle Vim keybindings via a checkbox, persisted in localStorage.

**Independent Test**: Open editor, check "Vim Mode", verify Vim navigation (h/j/k/l) works. Reload page, verify mode persists.

### Implementation for User Story 1

- [ ] T007 [US1] Update `root/editor.tt` to reference local CodeMirror assets (`static/js/codemirror/*`) instead of CDN
- [ ] T008 [US1] Add "Vim Mode" checkbox and status container HTML to `root/editor.tt` header
- [ ] T009 [US1] Implement `vimMode` localStorage persistence logic in `root/editor.tt`
- [ ] T010 [US1] Implement keymap toggling logic (setOption 'keyMap') in `root/editor.tt`
- [ ] T011 [US1] Implement Vim mode status display logic (event listener for 'vim-mode-change') in `root/editor.tt`

**Checkpoint**: User Story 1 fully functional. Editor works with local assets and Vim mode toggle.

---

## Phase 4: User Story 2 - Save with Keyboard Shortcut (Priority: P1)

**Goal**: Users can save content using Ctrl-S / Cmd-S.

**Independent Test**: Make changes, press Ctrl-S, verify save occurs and browser dialog is suppressed.

### Implementation for User Story 2

- [ ] T012 [US2] Implement `Ctrl-S` and `Cmd-S` interception in `root/editor.tt` using CodeMirror `extraKeys`
- [ ] T013 [US2] Ensure save shortcut triggers existing `saveContent()` function, prevents default browser behavior, and implements debounce logic (FR-010) in `root/editor.tt`

**Checkpoint**: User Stories 1 AND 2 work.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T014 Verify accessibility of "Vim Mode" checkbox (labels, focus) in `root/editor.tt`
- [ ] T015 Verify no console errors when toggling modes or saving in `root/editor.tt`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies.
- **Foundational (Phase 2)**: Depends on Setup. Blocks US1 and US2.
- **User Story 1 (P1)**: Depends on Foundational.
- **User Story 2 (P1)**: Depends on Foundational. Can be done in parallel with US1, but logically follows it as it enhances the editor further.

### Parallel Opportunities

- T002, T003, T004 (Vendoring) can run in parallel.
- T005, T006 (Perl Module) can run in parallel with Vendoring.
- US1 and US2 could theoretically run in parallel if `root/editor.tt` edits are managed carefully, but sequential is safer to avoid merge conflicts in the same file.

---

## Implementation Strategy

### MVP First (User Story 1)

1. Complete Setup & Foundational (Assets & Module).
2. Implement US1 (Toggle & Local Assets).
3. Validate Vim mode works.

### Incremental Delivery

1. Add US2 (Save Shortcut).
2. Validate Save Shortcut works.
3. Polish.
