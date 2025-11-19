---
description: "Task list for Blogdown Live Editor feature"
---

# Tasks: Blogdown Live Editor

**Input**: Design documents from `/specs/006-blogdown-live-editor/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Tests are MANDATORY per Constitution Principle III (90%+ coverage required).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

**This Project (Static Site Generator)**:
- **Development scope** (per Constitution v1.5.0): `lib/`, `bin/`, `root/`
- **Generated content** (do NOT modify): `articles/`, `blog/`, `tags/`
- **User assets** (do NOT modify): `static/`, `css/`, `images/`
- **Tests**: `t/` (mirrors `lib/` structure)
- **Fixtures**: `t/fixtures/` (test data only)

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Add `Dancer2` to `cpanfile`
- [x] T002 Create directory `lib/Ovid/App`

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 Create `lib/Ovid/App/LiveEditor.pm` skeleton with basic package declaration
- [x] T004 Create `bin/launch` skeleton with shebang, basic usage, and strict localhost binding configuration (FR-009)
- [x] T005 Create `root/editor.tt` skeleton with basic HTML structure

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

## Phase 3: User Story 1 - Launch Editor and Preview Content (Priority: P1) 🎯 MVP

**Goal**: Launch editor with file content and preview.

**Independent Test**: Run `bin/launch path/to/file` and verify editor loads with content and preview.

### Implementation for User Story 1

- [x] T005a [US1] Create `t/Ovid/App/LiveEditor.t` boilerplate using `Test::Most`
- [x] T006 [US1] Implement argument parsing in `bin/launch` to accept file path and pass to app
- [x] T007 [US1] Implement `get '/'` route in `lib/Ovid/App/LiveEditor.pm` to read the target file and render `editor.tt`
- [x] T008 [US1] Implement editor UI in `root/editor.tt` with textarea (populated with content) and iframe for preview
- [x] T009 [US1] Implement `get '/preview'` route in `lib/Ovid/App/LiveEditor.pm` to return rendered HTML
- [x] T010 [US1] Implement preview generation logic in `lib/Ovid/App/LiveEditor.pm` (invoking `bin/rebuild` logic or similar)
- [x] T010a [US1] Add unit tests for route handlers in `t/Ovid/App/LiveEditor.t`

## Phase 4: User Story 2 - Save Changes to Disk (Priority: P1)

**Goal**: Auto-save changes to disk.

**Independent Test**: Edit content, wait, verify file on disk is updated.

### Implementation for User Story 2

- [x] T011 [US2] Implement `post '/api/save'` route in `lib/Ovid/App/LiveEditor.pm` to write content to disk
- [x] T012 [US2] Implement client-side JS in `root/editor.tt` to capture input, debounce, and POST to `/api/save`
- [x] T013 [US2] Implement client-side JS in `root/editor.tt` to handle "Refresh Preview" button click (manual trigger only, per FR-008)
- [x] T013a [US2] Add tests for save endpoint validation in `t/Ovid/App/LiveEditor.t`

## Phase 5: User Story 3 - Accurate Preview via Rebuild Logic (Priority: P2)

**Goal**: Ensure preview matches production build.

**Independent Test**: Compare preview HTML with `bin/rebuild` output.

### Implementation for User Story 3

- [x] T014 [US3] Verify and refine `lib/Ovid/App/LiveEditor.pm` preview logic to ensure it uses the full site context (e.g. correct layout, CSS links)
- [X] T014a [US3] Add integration test verifying preview output matches `bin/rebuild` output

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final touches, error handling, and non-functional requirements

- [x] T015 Add CSS styling to `root/editor.tt` for a better editing experience (split pane layout)
- [x] T016 Add error handling in `bin/launch` for missing or invalid files
- [x] T017 Add error handling in `lib/Ovid/App/LiveEditor.pm` for save failures
- [x] T028 [Polish] Modify `bin/article` to use `Browser::Open` to launch the editor and open the browser automatically

## Phase 7: User Story 4 - File Switching (Priority: P2)

**Goal**: Allow user to switch files without restarting the server.

**Independent Test**: Open editor, use "Open File" feature to switch to another file, verify content loads and can be saved.

### Implementation for User Story 4

- [x] T018 [US4] Implement `_get_target_file` helper in `lib/Ovid/App/LiveEditor.pm` to resolve file from query param or ENV, with security checks
- [x] T019 [US4] Update `get '/'`, `post '/api/save'`, `get '/preview'` to use `_get_target_file`
- [x] T020 [US4] Update `root/editor.tt` to include file path in API calls and display current filename
- [x] T021 [US4] Add "Open File" UI to `root/editor.tt` and handle navigation
- [x] T022 [US4] Add tests for file switching and security constraints in `t/Ovid/App/LiveEditor.t`

## Phase 8: Refinement - File Picker (Priority: P1)

**Goal**: Replace manual file path entry with a UI file picker restricted to the `root/` directory.

**Independent Test**: Open editor, click "Change File", see list of files in `root/`, select one, and verify editor switches to it.

### Implementation for Phase 8

- [x] T023 [Refinement] Implement `get '/api/files'` in `lib/Ovid/App/LiveEditor.pm` to list all files in `root/` (recursive) as JSON
- [x] T024 [Refinement] Update `_get_target_file` in `lib/Ovid/App/LiveEditor.pm` to strictly enforce files are within `root/` directory
- [x] T025 [Refinement] Update `root/editor.tt` to replace text input with a "Change File" button and a modal dialog
- [x] T026 [Refinement] Implement JS in `root/editor.tt` to fetch file list and populate the modal
- [x] T027 [Refinement] Add tests for `/api/files` and stricter security in `t/Ovid/App/LiveEditor.t`

## Dependencies

1. **US1** depends on **Foundational Phase**
2. **US2** depends on **US1** (needs editor UI and server)
3. **US3** depends on **US1** (needs preview mechanism)
4. **US4** depends on **US1** (needs basic editor structure)

## Parallel Execution Examples

- **US2** and **US3** can be developed in parallel after **US1** is complete.
- Within **US1**, `root/editor.tt` (T008) and `lib/Ovid/App/LiveEditor.pm` (T007, T009) can be worked on somewhat independently if the API contract is agreed upon.

## Implementation Strategy

1. **MVP (US1)**: Get the editor running and showing content.
2. **Persistence (US2)**: Make it useful by saving changes.
3. **Fidelity (US3)**: Ensure the preview is accurate.
4. **Polish**: Improve UX and robustness.
