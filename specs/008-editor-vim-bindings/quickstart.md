# Quickstart: Editor Vim Bindings

## Overview

The editor now supports Vim keybindings for users who prefer modal editing. This feature is entirely client-side and persists your preference across sessions.

## Enabling Vim Mode

1.  Navigate to the editor (e.g., `/editor?file=root/index.tt`).
2.  Look for the **Vim Mode** checkbox in the top header bar.
3.  Check the box to enable Vim bindings.
4.  The status bar (bottom of editor) will show the current Vim mode (e.g., `-- NORMAL --`, `-- INSERT --`).

## Using Vim Mode

-   **Normal Mode**: Default state. Use `h`, `j`, `k`, `l` to move.
-   **Insert Mode**: Press `i` to enter. Type normally. Press `Esc` to return to Normal Mode.
-   **Visual Mode**: Press `v` to enter. Select text.

## Saving Changes

-   Press `Ctrl-S` (Windows/Linux) or `Cmd-S` (macOS) to save the file.
-   This works in both Vim Mode (Insert/Normal) and Standard Mode.
-   The browser's default "Save Page" dialog is suppressed.

## Troubleshooting

-   **Vim Mode not working?**: Ensure JavaScript is enabled. Try refreshing the page.
-   **Status not showing?**: The status indicator appears in the header bar next to the "Saved" status.
