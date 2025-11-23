# Feature Specification: Editor Vim Bindings

**Feature Branch**: `008-editor-vim-bindings`
**Created**: 2025-11-22
**Status**: Draft
**Input**: User description: "Add optional vim bindings to the editor with a toggle checkbox in the top bar, and intercept 'ctrl-s' to save the file."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Toggle Vim Mode (Priority: P1)

As a content author who prefers Vim keybindings, I want to be able to toggle "Vim Mode" on and off so that I can edit content using my preferred input method.

**Why this priority**: This is the core feature request.

**Independent Test**: Can be tested by clicking the checkbox and verifying that the editor's behavior changes (e.g., `j`/`k` move cursor vs typing characters).

**Acceptance Scenarios**:

1. **Given** the editor is open, **When** I check the "Vim Mode" checkbox in the top bar, **Then** the editor switches to Vim keybindings.
2. **Given** Vim Mode is enabled, **When** I uncheck the "Vim Mode" checkbox, **Then** the editor switches back to standard keybindings.
3. **Given** I have enabled Vim Mode, **When** I reload the page, **Then** Vim Mode remains enabled (preference is persisted).

---

### User Story 2 - Save with Keyboard Shortcut (Priority: P1)

As a content author, I want to save my work using `Ctrl-S` (or `Cmd-S` on macOS) so that I don't have to reach for the mouse or wait for auto-save, and so that I don't accidentally save the web page itself.

**Why this priority**: Improves workflow efficiency and prevents the browser's default "Save Page As" behavior which is disruptive.

**Independent Test**: Can be tested by making a change and pressing `Ctrl-S`, then verifying the save status indicator.

**Acceptance Scenarios**:

1. **Given** I have unsaved changes in the editor, **When** I press `Ctrl-S` (Windows/Linux) or `Cmd-S` (macOS), **Then** the content is saved to the server.
2. **Given** I press `Ctrl-S` or `Cmd-S`, **Then** the browser's default "Save Page As" dialog does NOT appear.
3. **Given** I am in Vim Mode, **When** I press `Ctrl-S` or `Cmd-S` in Insert or Normal mode, **Then** the content is saved.

### Edge Cases

- What happens if the Vim keymap library fails to load? (Should fallback to default and disable checkbox)
- If `Ctrl-S` is pressed while a save is in progress, the new request is ignored (debounced) until the current save completes.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a "Vim Mode" checkbox in the editor's top bar.
- **FR-002**: System MUST load the CodeMirror Vim keymap library from a local static asset (vendored), not a CDN.
- **FR-003**: When "Vim Mode" is checked, the editor MUST use the `vim` keymap.
- **FR-004**: When "Vim Mode" is unchecked, the editor MUST use the `default` keymap.
- **FR-005**: System MUST persist the user's "Vim Mode" preference in `localStorage` and restore it on page load.
- **FR-006**: System MUST intercept `Ctrl-S` and `Cmd-S` key events within the editor.
- **FR-007**: When `Ctrl-S` or `Cmd-S` is detected, the system MUST trigger the existing save function and prevent the default browser behavior.
- **FR-008**: System MUST display the current Vim mode (e.g., Normal, Insert) when Vim mode is active.
- **FR-009**: System MUST NOT intercept browser-reserved shortcuts (e.g., Ctrl-W, Ctrl-N, Ctrl-T) other than Ctrl-S/Cmd-S.
- **FR-010**: System MUST ignore `Ctrl-S` or `Cmd-S` save requests if a save operation is currently in progress.

### Key Entities *(include if feature involves data)*

- **User Preference**: Stored client-side (localStorage) to remember the Vim mode setting.

## Success Criteria *(mandatory)*

- **SC-001**: Users can enable and disable Vim mode via the UI.
- **SC-002**: When enabled, standard Vim navigation keys (h, j, k, l) move the cursor in Normal mode.
- **SC-003**: `Ctrl-S` and `Cmd-S` successfully trigger a save operation 100% of the time without opening the browser's save dialog.
- **SC-004**: User preference for Vim mode is retained after a page refresh.
- **SC-005**: The editor displays the current Vim mode (e.g., "-- INSERT --") when in Vim mode.

## Clarifications

### Session 2025-11-22
- Q: Should we add a visual status indicator for Vim mode? → A: Yes, add a status indicator (e.g., "-- INSERT --").
- Q: Should we aggressively intercept browser shortcuts (Ctrl-W, etc.)? → A: No, only intercept Ctrl-S and standard Vim navigation.
- Q: How should the Vim library be loaded? → A: Vendor the file (serve locally from `static/js/`), do not use CDN.
- Q: Should the Vim Mode preference be persisted? → A: Yes, persist in localStorage.
- Q: How to handle Ctrl-S during an active save? → A: Ignore (debounce) the new request until the current save completes.
