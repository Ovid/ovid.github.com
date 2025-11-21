# Feature Specification: Editor Image Upload & Launch Enhancements

**Feature Branch**: `007-editor-image-upload`  
**Created**: 2025-11-21  
**Status**: Draft  
**Input**: User description: "When I run `bin/launch <article>`, I want an --open flag that will use Browser::Open to automatically open my browser to edit the article I'm opening. I also need a `--port` flag that will let me specify a port other than the default one of 3000. Finally, to the right of the 'Change Size` button defined in`root/editor.tt`, I would like an \"Upload Image\" button that will let me select or paste an image as png, gif, or jpg. The upload form should allow me to add the filename, optional source, optional alt, and optional caption. When I click \"Save\", it should resize the image to just below `$MAX_IMAGE_SIZE` defined in `t/lint.t`, and save it to `root/static/images/<filename>`. The $MAX_IMAGE_SIZE should now be defined in `config/ovid.yaml` rather than duplicated in the code. After the image is saved, in the current position of the cursor in the editor, the snippet should be inserted with HTML escaping."

## Clarifications

### Session 2025-11-21

- Q: How should the editor handle filename collisions when saving a new image? → A: Prompt the writer for explicit overwrite confirmation before replacing an existing file.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Upload curated images inside the editor (Priority: P1)

As a writer using the in-browser editor, I can click "Upload Image" beside "Change Size", select or paste a PNG/GIF/JPG, add filename plus optional source/alt/caption, and on Save the system resizes the asset below the allowed maximum, stores it under `root/static/images/`, and inserts the templated include snippet at my cursor position with HTML-escaped values.

**Why this priority**: Enables visually rich posts without leaving the editor and removes current manual image handling bottleneck.

**Independent Test**: Start the editor, upload an eligible image with metadata, confirm the resized file is stored, metadata persists, and the snippet renders correctly in preview.

**Acceptance Scenarios**:

1. **Given** the editor is open on an article, **When** I click "Upload Image" and choose a PNG smaller than the maximum, **Then** the image saves under the provided filename and a snippet with my metadata appears at the cursor.
2. **Given** I paste a JPG from clipboard and supply optional source/alt/caption, **When** I click Save, **Then** the image is downscaled just below the allowed limit and the snippet reflects my escaped metadata values.

---

### User Story 2 - Launch article editing with browser auto-open (Priority: P2)

As a CLI author, I can run `bin/launch <article> --open` and the tool automatically opens my default browser to the editing UI for that article after the local server starts.

**Why this priority**: Removes context switching and shortens the feedback loop when editing specific content.

**Independent Test**: Execute `bin/launch sample-article --open`, verify the command exits successfully, server logs show launch, and the browser opens the editor page exactly once.

**Acceptance Scenarios**:

1. **Given** the default port is free, **When** I launch with `--open`, **Then** the server starts and Browser::Open navigates to the correct editor URL automatically.
2. **Given** the server is already running, **When** I rerun with `--open`, **Then** the command fails gracefully or reuses the session while only opening one browser tab.

---

### User Story 3 - Override port for local launch (Priority: P3)

As a developer with port conflicts, I can pass `--port <number>` when running `bin/launch <article>` so the local editing server binds to the requested port while keeping other behavior unchanged.

**Why this priority**: Prevents workflow blocks when port 3000 is unavailable and supports parallel local servers.

**Independent Test**: Run `bin/launch post --port 3100`, confirm the process listens on 3100 and all generated URLs (including those opened via `--open`) honor the override.

**Acceptance Scenarios**:

1. **Given** port 3000 is busy, **When** I pass `--port 3100`, **Then** the server starts on 3100 and the CLI output reflects the override.
2. **Given** I combine `--port` and `--open`, **When** the server starts, **Then** the browser opens using the overridden port in the URL.

---

### Edge Cases

- Upload request exceeds the maximum size before resizing (e.g., massive raw files) — system must reject with guidance instead of crashing.
- User supplies a filename that already exists in `root/static/images/` — editor must prompt for overwrite confirmation before replacing the file, otherwise block saving.
- Clipboard paste lacks filename — UI must enforce providing a filename before enabling Save.
- Non PNG/GIF/JPG files or corrupted data pasted — system must show a validation error and prevent saving.
- `--open` invoked on headless environments — command must skip browser launch and warn without failing the server startup.
- `--port` receives an invalid or restricted port — CLI must validate input and inform the user instead of hanging.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `bin/launch` MUST accept an `--open` flag that, after the server is ready, launches the default browser via Browser::Open exactly once for the targeted article editor URL.
- **FR-002**: `bin/launch` MUST accept a `--port <number>` option (default 3000) that validates the port range (1024-65535) and ensures all generated URLs, logs, and downstream services use the override.
- **FR-003**: The command MUST fail fast with actionable messaging if the requested port is unavailable or invalid, without leaving orphaned processes.
- **FR-004**: The maximum image size constant MUST move to `config/ovid.yaml`, and all code (including tests and upload logic) MUST read from that centralized value to avoid duplication.
- **FR-005**: The editor UI MUST add an "Upload Image" button to the right of "Change Size" and display a modal/form that accepts file selection or clipboard paste for PNG/GIF/JPG content.
- **FR-006**: The upload modal MUST require filename input and allow optional source, alt, and caption text fields, persisting their values until the modal closes.
- **FR-007**: On Save, the system MUST validate type, capture the image bytes, downscale to just below `MAX_IMAGE_SIZE` while preserving aspect ratio, and skip upscaling smaller images.
- **FR-008**: Successfully saved assets MUST be written to `root/static/images/<filename>` (creating directories as needed) and, if a file already exists, the system MUST prompt for explicit overwrite confirmation before writing.
- **FR-009**: After saving, the editor MUST insert the provided Template Toolkit snippet at the cursor position, escaping HTML entities in metadata fields to prevent double-quote issues.
- **FR-010**: The editor MUST surface clear error states for validation failures (unsupported type, missing filename, oversized file, write failure) without losing the user's metadata inputs.
- **FR-011**: Logging or user-visible notifications MUST confirm the target path and snippet insertion so writers can trust the outcome without inspecting the filesystem.

### Key Entities *(include if feature involves data)*

- **Image Asset**: Represents an uploaded image with attributes filename, mime type, raw bytes, resized dimensions, source, alt text, caption, and storage path (`/static/images/<filename>`). Linked to the article draft only via the inserted snippet.
- **Launch Session**: Represents one invocation of `bin/launch` with attributes article target, chosen port, flags (`--open`), server state, and any resulting browser URL.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 95% of attempted uploads that meet type/size rules complete (resize + save + snippet insert) in under 5 seconds on a standard local machine.
- **SC-002**: 100% of `bin/launch` executions that include `--open` open exactly one browser tab/window pointed at the requested article editor, with failures logged and reported to the user.
- **SC-003**: 100% of `--port` overrides within the valid range result in the server listening on the requested port, verified via automated tests.
- **SC-004**: Editorial QA confirms that metadata entered in the upload modal appears verbatim (properly escaped) in the resulting snippet across at least three manual test cases (one per supported image format).

## Assumptions

- Resizing "just below" the maximum means the larger dimension is reduced to one pixel less than `MAX_IMAGE_SIZE` while preserving aspect ratio; smaller inputs remain unchanged.
- The clipboard paste feature captures a single image at a time; drag-and-drop is treated the same as file selection.
- Browser::Open uses the system default browser, and lack of GUI support (e.g., remote SSH sessions) triggers a warning rather than an error.
- All snippet insertions occur in the currently focused editor pane, and undo/redo history records the action automatically.
