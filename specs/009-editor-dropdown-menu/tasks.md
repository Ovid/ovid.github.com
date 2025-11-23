# Tasks: Editor Dropdown Menu

**Feature Branch**: `009-editor-dropdown-menu`
**Status**: In Progress

## Phase 1: Setup
*Goal: Prepare environment for UI modifications.*

- [x] T001 Verify `root/editor.tt` exists and is writable

## Phase 2: Foundational
*Goal: Establish the visual and functional structure of the dropdown menu.*

- [x] T002 Implement Dropdown Menu HTML structure (trigger button using Font Awesome `fa-bars` + menu container) with ARIA attributes (`aria-expanded`, `aria-haspopup`, `role="menu"`) in `root/editor.tt`
- [x] T003 Implement Dropdown Menu CSS (positioning, z-index, visibility, styling) including active state checkmark styles in `root/editor.tt`
- [x] T004 Implement basic JS for opening/closing menu (click trigger, click outside listener, close on action item click, Escape key support) in `root/editor.tt`

## Phase 3: User Story 1 - Access Editor Actions via Menu
*Goal: Move file and image actions to the new menu.*
*Independent Test: Open menu, click "Edit Post" (opens file dialog), click "Upload Image" (opens upload dialog).*

- [x] T005 [US1] Implement "Edit Post" menu item and wire to existing file selection logic in `root/editor.tt`
- [x] T006 [US1] Implement "Upload Image" menu item and wire to existing upload logic in `root/editor.tt`
- [x] T007 [US1] Move "Refresh Preview" button to left side of toolbar in `root/editor.tt`
- [x] T008 [US1] Remove legacy "Change File" and "Upload Image" buttons from toolbar in `root/editor.tt`

## Phase 4: User Story 2 - Toggle Editor Preferences via Menu
*Goal: Move preference toggles to the menu and implement state indication.*
*Independent Test: Toggle each preference in menu, verify editor state changes and checkmark updates. Reload page to verify persistence.*

- [x] T009 [US2] Implement "Light Mode" menu item with checkmark logic in `root/editor.tt`
- [x] T010 [US2] Implement "Vim Mode" menu item with checkmark logic in `root/editor.tt`
- [x] T011 [US2] Implement "Syntax Highlight" menu item with checkmark logic in `root/editor.tt`
- [x] T012 [US2] Update JS to keep menu open when clicking toggle items in `root/editor.tt`
- [x] T013 [US2] Update JS to initialize menu item states from `localStorage` on load in `root/editor.tt`
- [x] T014 [US2] Remove legacy "Light Mode" button and checkboxes from toolbar in `root/editor.tt`

## Phase 5: Polish & Cross-Cutting Concerns
*Goal: Ensure usability and accessibility.*

- [x] T015 Verify keyboard accessibility for Dropdown Menu in `root/editor.tt`
- [x] T016 Verify responsive layout of toolbar with new menu in `root/editor.tt`

## Dependencies

1. **Phase 2 (Foundational)** must be completed before **Phase 3** and **Phase 4**.
2. **Phase 3** and **Phase 4** can be executed in parallel as they touch different logical parts of the menu, though they edit the same file (merge conflicts possible).
3. **Phase 5** requires all previous phases.

## Implementation Strategy

- **MVP**: Complete Phase 2 and Phase 3 to have a functional menu with actions.
- **Full Feature**: Complete Phase 4 to fully replace the old toolbar.
- **Incremental Delivery**: Can deploy after Phase 3 if old toggles are left in place temporarily, but goal is single release.
