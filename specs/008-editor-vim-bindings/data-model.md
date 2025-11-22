# Data Model: Editor Vim Bindings

## Client-Side Storage (localStorage)

| Key | Type | Description | Example |
|-----|------|-------------|---------|
| `vimMode` | String ("true" / "false") | User preference for Vim keybindings. | `"true"` |

## Server-Side Data

No changes to server-side data models. The save functionality uses the existing `/api/save` endpoint which accepts `content` and `file` parameters.
