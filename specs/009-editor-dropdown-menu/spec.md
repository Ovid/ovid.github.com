# Feature Specification: Editor Dropdown Menu

**Feature Branch**: `009-editor-dropdown-menu`
**Created**: 2025-11-23
**Status**: Draft
**Input**: User description: "I need to take the "Change File", "Upload Image", and "Light Mode" buttons, along with the "Vim Mode" and "Syntax Highlight" checkboxes in the top bar of `root/editor.tt` template and turn them into a dropdown menu to save space in the toolbar. The menu should contain the following elements in this order (where "Change File" is renamed to "Edit Post"): Edit Post, Upload Image, Light Mode, Vim Mode, Syntax Highlight. The "Light Mode", "Vim Mode", and "Syntax Highlight" should merely toggle those features on and off as they currently do. "Edit Post" and "Upload Image" should also be in the menu and retain their current behavior."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Access Editor Actions via Menu (Priority: P1)

As a content editor, I want to access file management and upload tools from a consolidated menu so that the toolbar is less cluttered.

**Why this priority**: This moves essential functionality into the new UI structure. Without this, users cannot change files or upload images.

**Independent Test**: Can be fully tested by opening the menu and verifying that "Edit Post" and "Upload Image" trigger their respective dialogs.

**Acceptance Scenarios**:

1. **Given** the editor is loaded, **When** I click the "Menu" button in the toolbar, **Then** a dropdown menu appears containing "Edit Post" and "Upload Image".
2. **Given** the dropdown menu is open, **When** I click "Edit Post", **Then** the file selection dialog appears (same behavior as previous "Change File" button).
3. **Given** the dropdown menu is open, **When** I click "Upload Image", **Then** the image upload dialog appears.

---

### User Story 2 - Toggle Editor Preferences via Menu (Priority: P1)

As a content editor, I want to toggle editor display preferences from the menu so that I can customize my writing environment without cluttering the toolbar.

**Why this priority**: Moves existing preference controls to the new location.

**Independent Test**: Can be fully tested by toggling each preference in the menu and observing the editor change state.

**Acceptance Scenarios**:

1. **Given** the dropdown menu is open, **When** I click "Light Mode", **Then** the editor theme toggles between light and dark, and the menu item reflects the new state.
2. **Given** the dropdown menu is open, **When** I click "Vim Mode", **Then** the editor keybindings toggle between Vim and Standard, and the menu item reflects the new state.
3. **Given** the dropdown menu is open, **When** I click "Syntax Highlight", **Then** the syntax highlighting toggles on/off, and the menu item reflects the new state.
4. **Given** I have changed preferences, **When** I reload the page, **Then** the menu items correctly reflect the persisted state (per existing behavior).

### Edge Cases

- What happens when the menu is open and the user clicks outside it? (Should close)
- What happens if the window is resized? (Menu should remain anchored or close)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The editor toolbar MUST contain a dropdown menu trigger (labeled "Menu" or using a standard icon).
- **FR-002**: The dropdown menu MUST contain exactly these items in this order:
    1. Edit Post
    2. Upload Image
    3. Light Mode
    4. Vim Mode
    5. Syntax Highlight
- **FR-003**: The "Edit Post" item MUST trigger the existing file selection logic (renamed from "Change File").
- **FR-004**: The "Upload Image" item MUST trigger the existing image upload logic.
- **FR-005**: The "Light Mode" item MUST toggle the visual theme and visually indicate its active state (e.g., checkbox or toggle switch).
- **FR-006**: The "Vim Mode" item MUST toggle Vim keybindings and visually indicate its active state.
- **FR-007**: The "Syntax Highlight" item MUST toggle syntax highlighting and visually indicate its active state.
- **FR-008**: The original "Change File", "Upload Image", "Light Mode" buttons and "Vim Mode", "Syntax Highlight" checkboxes MUST be removed from the toolbar.
- **FR-009**: The dropdown menu MUST close when clicking outside of it.

### Key Entities

- N/A (UI change only, no new data entities)

## Success Criteria *(mandatory)*

- **SC-001**: The editor toolbar takes up less horizontal space or is less cluttered than the previous version.
- **SC-002**: All 5 functionalities (Edit Post, Upload Image, Light Mode, Vim Mode, Syntax Highlight) are accessible and functional.
- **SC-003**: User preferences for modes are preserved across sessions (retaining existing persistence).

## Assumptions

- The existing `saveContent()` and other logic remains unchanged; we are only moving the triggers.
- Standard HTML/CSS/JS can be used for the dropdown implementation.
- "Edit Post" is purely a label change for "Change File".
