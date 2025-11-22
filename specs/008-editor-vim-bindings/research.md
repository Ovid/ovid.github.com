# Research: Editor Vim Bindings

## Unknowns & Clarifications

### 1. Current Editor Implementation
- **Finding**: The editor is implemented in `root/editor.tt` using CodeMirror 5.65.16 loaded from `cdnjs`.
- **Resolution**: We will replace the CDN links with local vendored files to comply with Constitution Principle V and the Feature Spec.

### 2. Vim Keymap Availability
- **Finding**: CodeMirror 5 provides a `keymap/vim.js` module.
- **Resolution**: We will download this file along with the core CodeMirror library.

### 3. Save Functionality
- **Finding**: `root/editor.tt` has a `saveContent()` function that posts to `/api/save`.
- **Resolution**: We can reuse this function for the `Ctrl-S` shortcut.

## Technology Decisions

### 1. Vendoring CodeMirror
- **Decision**: Download CodeMirror 5.65.16 assets to `static/js/codemirror/`.
- **Rationale**:
    -   **Compliance**: Satisfies Constitution Principle V (Zero External Service Dependencies).
    -   **Reliability**: Ensures editor works offline and isn't subject to CDN outages.
    -   **Consistency**: Ensures all editor assets (core + vim) are from the same version.
- **Alternatives Considered**:
    -   *Use CDN for core, vendor Vim*: Rejected because it violates Principle V and risks version mismatch.
    -   *Upgrade to CodeMirror 6*: Rejected as out of scope for this feature; sticking to the existing version minimizes regression risk.

### 2. Vim Mode Toggle
- **Decision**: Use a simple checkbox in the top bar, persisted to `localStorage`.
- **Rationale**: Matches the spec requirements and existing patterns (like "Syntax Highlight" toggle).

### 3. Shortcut Interception
- **Decision**: Use `document.addEventListener('keydown', ...)` or CodeMirror's `extraKeys` option.
- **Rationale**: CodeMirror's `extraKeys` is the cleanest way to handle editor-specific shortcuts, but `Ctrl-S` should probably work even if focus is slightly outside (though spec says "within the editor"). `extraKeys` is safer to avoid conflicting with browser if focus is elsewhere, but `Ctrl-S` is usually global. However, spec says "intercept 'ctrl-s' ... within the editor".
- **Refinement**: We will use CodeMirror's `extraKeys` for `Ctrl-S` / `Cmd-S` to ensure it only triggers when editing.

## Implementation Strategy

1.  **Vendor Assets**: Create `static/js/codemirror` and populate with downloaded files.
2.  **Update Template**: Modify `root/editor.tt` to point to local files.
3.  **Add UI**: Add "Vim Mode" checkbox to the header.
4.  **Add Logic**:
    -   Load `vimMode` from `localStorage`.
    -   Initialize CodeMirror with `keyMap: 'vim'` if enabled.
    -   Add event listener to checkbox to toggle `editor.setOption('keyMap', ...)` and update `localStorage`.
    -   Add `extraKeys` configuration to map `Ctrl-S` and `Cmd-S` to `saveContent()`.
    -   Add status display logic (CodeMirror Vim mode exposes events for mode changes).

