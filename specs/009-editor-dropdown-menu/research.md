# Research: Editor Dropdown Menu

**Feature**: Editor Dropdown Menu
**Date**: 2025-11-23

## Decisions

### 1. UI Component Implementation
- **Decision**: Implement a custom dropdown menu using standard HTML, CSS, and vanilla JavaScript within `root/editor.tt`.
- **Rationale**: The project uses vanilla JS and CSS for the editor. Introducing a framework or library for a single dropdown is unnecessary overhead.
- **Alternatives Considered**: 
    - **jQuery UI**: Too heavy for this single feature.
    - **Bootstrap**: Would require adding a large dependency.

### 2. Menu Trigger
- **Decision**: Use a standard Hamburger Icon (☰) unicode character or SVG.
- **Rationale**: Universally recognized symbol for menus.
- **Alternatives Considered**: "Menu" text label (takes more space).

### 3. State Indication
- **Decision**: Use checkmarks (✓) next to active toggle items (Light Mode, Vim Mode, Syntax Highlight).
- **Rationale**: Clear visual indicator of state without needing complex toggle switch UI elements inside the menu.

### 4. Menu Behavior
- **Decision**: 
    - Clicking "Edit Post" or "Upload Image" closes the menu immediately.
    - Clicking toggle items keeps the menu open to allow multiple toggles.
    - Clicking outside the menu closes it.
- **Rationale**: Improves usability by allowing users to configure multiple settings at once without reopening the menu.

## Unknowns Resolved

- **Q**: How is the current toolbar implemented?
- **A**: It is a flexbox `<header>` in `root/editor.tt` with inline styles and buttons/checkboxes.

- **Q**: Are there existing JS libraries?
- **A**: CodeMirror is used, but no general UI library like Bootstrap. Vanilla JS is used for logic.
