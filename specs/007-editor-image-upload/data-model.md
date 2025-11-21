# Data Model: Editor Image Upload & Launch Enhancements

## Entities

### ImageUploadRequest (client → server contract)
- **filename**: Required string, no path separators, must end with `.png`, `.jpg`, `.jpeg`, or `.gif`.
- **blob**: Binary payload originating from file input or clipboard paste; validated against `max_image_size_bytes` after processing.
- **mime_type**: Derived from upload headers; used to enforce PNG/GIF/JPG support.
- **source_url**: Optional HTTPS/HTTP URL cited in captions.
- **alt_text**: Optional short description; defaults to blank (server may auto-generate later).
- **caption**: Optional Markdown-safe string.
- **overwrite**: Boolean flag gate when destination file already exists.

### ImageAsset (persisted file under `root/static/images`)
- **storage_path**: Absolute path to the saved file; derived from project root + filename.
- **public_src**: `/static/images/<filename>` path inserted into snippets.
- **size_bytes**: File size after resizing/compression; must be `< max_image_size_bytes`.
- **dimensions**: `{ width, height }` after resizing; maintain aspect ratio.
- **format**: One of `png|jpg|gif` matching encoder selection.
- **metadata**: `{ alt, source, caption }` sanitized for Template insertion.
- **created_at**: Timestamp stored in logs/notifications (optional for UI messaging).

### SnippetInsertion
- **template**: Literal `[% INCLUDE include/image.tt ... %]` block.
- **cursor_offset**: Character index where snippet is inserted (server returns snippet; client handles placement for both `<textarea>` and CodeMirror modes).
- **escaped_fields**: Metadata values after HTML entity escaping to avoid double quotes or TT parsing issues.

### LaunchSession (CLI invocation of `bin/launch`)
- **target_file**: Absolute path resolved from CLI argument (auto-converted from generated HTML to source TT as needed).
- **port**: Integer (default 3000) validated between 1024-65535.
- **open_flag**: Boolean, indicates whether to auto-open browser.
- **browser_status**: `pending | opened | skipped_headless | failed` to drive CLI messaging.
- **child_pid**: PID of forked Dancer2 server process for lifecycle control.

### PortBinding (derived from LaunchSession)
- **host**: Always `127.0.0.1` per security constraints.
- **port**: Mirrors LaunchSession.port.
- **status**: `available | in-use` from socket probe; if `in-use`, CLI aborts before booting server.

## Relationships
- `ImageUploadRequest → ImageAsset`: A validated request becomes a stored asset once resizing succeeds.
- `ImageAsset → SnippetInsertion`: Stored metadata populates the snippet block inserted into the editor.
- `LaunchSession → PortBinding`: Each launch checks/creates a binding; failures propagate back to the CLI before server startup.
- `LaunchSession → BrowserStatus`: If `--open` is set and the health probe passes, Browser::Open transitions the status to `opened`.

## Validation Rules
- Filenames must be ASCII-safe, lowercased, and unique unless `overwrite=true`.
- Only PNG, JPG/JPEG, and GIF content-types are accepted; others yield `415 Unsupported Media Type`.
- Clipboard uploads without filenames require the modal to force entry before enabling "Save".
- Overwrite prompts happen when an existing file with the same name is detected; server requires the explicit flag to proceed.
- Ports <1024, >65535, or already bound result in CLI errors before forking Dancer2.
- `max_image_size_bytes` applies twice: once during linting (existing tests) and once after resizing to ensure the saved file is compliant.

## State Transitions

### Image Upload
1. `idle` → `collecting`: User opens modal and fills metadata/chooses file.
2. `collecting` → `validating`: Client-side checks (filename present, extension allowed, file selected/pasted).
3. `validating` → `pending-overwrite`: Triggered when server reports an existing file; UI blocks until user confirms overwrite.
4. `validating|pending-overwrite` → `processing`: Server streams upload, normalizes filename, and resizes.
5. `processing` → `saved`: File written, snippet returned, modal closes, snippet inserted at cursor.
6. `processing` → `error`: Server validation failure; metadata remains in modal for retry.

### `bin/launch`
1. `init`: Parse CLI args, normalize path, ensure file exists.
2. `port-check`: Probe requested port; fail-fast on conflicts.
3. `forking`: Spawn child running Dancer2 and set `LIVE_EDITOR_FILE`.
4. `waiting-health`: Parent polls `/health` endpoint until server ready.
5. `opening-browser`: If `--open`, call Browser::Open once; skip if headless.
6. `active`: CLI streams logs until user terminates; child PID tracked for cleanup.
7. `shutdown`: SIGINT or child exit; CLI reports status and returns exit code.
