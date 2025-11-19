# Data Model: Blogdown Live Editor

## Entities

### Source File
The primary entity being edited.

- **Path**: Absolute path to the file on disk.
- **Content**: Raw text content (Markdown + TT directives).
- **Type**: `article` or `blog` (determined by file location or metadata).
- **Last Modified**: Timestamp of last save.

### Preview
The generated output.

- **HTML Content**: The rendered HTML.
- **Status**: `stale` | `fresh`.

## State Management

### Editor State (Client-side)
- **Dirty**: Boolean, true if content has changed since last save.
- **Saving**: Boolean, true if save request is in flight.
- **Content**: Current text in the editor.

### Server State
- **Current File**: The file currently being edited (passed at startup).
