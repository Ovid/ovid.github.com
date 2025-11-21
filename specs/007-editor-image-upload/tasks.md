---
description: "Task list for implementing editor image upload & launch enhancements"
---

# Tasks: Editor Image Upload & Launch Enhancements

**Input**: Design documents from `/specs/007-editor-image-upload/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Each user story lists the minimum automated coverage required by the specification.
**Organization**: Tasks are grouped by user story to ensure independent delivery and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Task can run in parallel (different files, no direct dependencies on other open tasks)
- **[Story]**: User story label (US1, US2, US3)
- Include exact file paths in every description per Constitution scope guidance.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare shared configuration and dependencies required across the feature.

- [ ] T001 Add `max_image_size_bytes: 300000` plus explanatory comment to `config/ovid.yaml` so linting and uploads share one limit.
- [ ] T002 [P] Ensure `Imager` and `Browser::Open` runtime dependencies are declared (or updated) in `cpanfile` for installation.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Centralize configuration access so subsequent stories can rely on a single MAX_IMAGE_SIZE source.
**⚠️ CRITICAL**: No user story work may begin until this phase is complete.

- [ ] T003 Add a `max_image_size_bytes` accessor and validation in `lib/Less/Config.pm`, returning an integer for downstream consumers.
- [ ] T004 Update `lib/Ovid/App/LiveEditor.pm` bootstrap to load `Less::Config->max_image_size_bytes` once and stash it in the Dancer app config for reuse.
- [ ] T005 Replace the hard-coded `MAX_IMAGE_SIZE` in `t/lint.t` with the config-driven value (fail test if config is missing) to enforce single source of truth.

**Checkpoint**: Config limit exposed and enforced project-wide; user stories can now begin.

---

## Phase 3: User Story 1 - Upload curated images inside the editor (Priority: P1) 🎯 MVP

**Goal**: Give writers an "Upload Image" workflow that accepts PNG/GIF/JPG inputs, captures metadata, resizes under the configured byte limit, stores under `root/static/images/`, and inserts the escaped snippet at the cursor.

**Independent Test**: Launch the editor, upload an allowed image with metadata, confirm the resized file exists in `root/static/images/<filename>`, and verify the returned snippet renders with escaped metadata in preview.

### Tests for User Story 1 ⚠️

- [ ] T006 [US1] Create `t/Ovid/App/LiveEditor/upload.t` to cover success, overwrite rejection, MIME filtering, and config-sized failures for `POST /api/upload-image`.

### Implementation for User Story 1

- [ ] T007 [P] [US1] Introduce `lib/Ovid/Util/Image.pm` (or similar) to validate filenames, call Imager for resizing/compression, and persist files under `root/static/images/` while respecting temp dirs during tests.
- [ ] T008 [US1] Extend `lib/Ovid/App/LiveEditor.pm` with a `POST /api/upload-image` route that streams uploads, uses the image helper, escapes metadata, prompts for overwrite via status codes, and returns the snippet/public paths defined in contracts/openapi.yaml.
- [ ] T009 [P] [US1] Update `root/editor.tt` header markup to add the "Upload Image" button, modal structure, and accessible form fields (filename, source, alt, caption, overwrite confirmation UI).
- [ ] T010 [US1] Implement the accompanying JavaScript in `root/editor.tt` to handle file selection or clipboard paste, call the API, manage overwrite prompts, surface error/success notifications, and insert the snippet at the current cursor position.

**Checkpoint**: Upload flow stores assets under the byte limit, and the editor inserts the escaped snippet automatically.

---

## Phase 4: User Story 2 - Launch article editing with browser auto-open (Priority: P2)

**Goal**: Let authors run `bin/launch <article> --open` so the local server starts and Browser::Open navigates to the editor once the app is ready.

**Independent Test**: Execute `bin/launch sample.tt --open`; verify the CLI starts the server, waits for readiness, opens exactly one browser tab (unless headless), and exits cleanly.

### Tests for User Story 2 ⚠️

- [ ] T011 [US2] Expand `t/bin/launch.t` to simulate `--open`, asserting Browser::Open is called once after `/health` passes and that headless environments emit a warning instead of failing.

### Implementation for User Story 2

- [ ] T012 [US2] Add an `--open` flag to `bin/launch`, including headless detection, ensuring Browser::Open fires once per invocation, and logging failures without killing the server.
- [ ] T013 [US2] Implement a lightweight `GET /health` route in `lib/Ovid/App/LiveEditor.pm` that reports `{ ok => 1, file => ..., timestamp => ... }` for readiness polling.
- [ ] T014 [US2] Teach `bin/launch` to poll `http://127.0.0.1:<port>/health`, handle already-running servers gracefully, and only invoke Browser::Open after the poll succeeds.

**Checkpoint**: CLI auto-opens the browser reliably and communicates gracefully when display access is unavailable.

---

## Phase 5: User Story 3 - Override port for local launch (Priority: P3)

**Goal**: Allow `bin/launch <article> --port <number>` to bind the Dancer2 server to a caller-specified port while keeping all URLs and auto-open behavior consistent.

**Independent Test**: Run `bin/launch mypost.tt --port 3100 --open`; confirm the server binds to 3100, every logged URL references the override, and the browser opens with the new port.

### Tests for User Story 3 ⚠️

- [ ] T015 [US3] Extend `t/bin/launch.t` to cover valid/invalid `--port` values, conflict detection, and combinations with `--open`.

### Implementation for User Story 3

- [ ] T016 [US3] Add `--port` parsing and validation (1024-65535 defaulting to 3000) to `bin/launch`, emitting actionable errors for out-of-range input.
- [ ] T017 [US3] Update `bin/launch` to probe port availability before forking, bind the server to the requested port, and propagate the override to Browser::Open URLs and CLI messaging.

**Checkpoint**: Launch command honors caller-selected ports and prevents conflicts before startup.

---

## Final Phase: Polish & Cross-Cutting Concerns

**Purpose**: Align documentation and contracts with the delivered behavior.

- [ ] T018 [P] Document `--open`, `--port`, and the upload workflow in `README.md`, including headless caveats and config instructions.
- [ ] T019 [P] Refresh `specs/007-editor-image-upload/quickstart.md` steps to reflect the final CLI flags and modal behavior.
- [ ] T020 [P] Update `specs/007-editor-image-upload/contracts/openapi.yaml` with the final response shapes for `/api/upload-image` and `/health` (bytes, dimensions, status codes).
- [ ] T021 [P] Document the SC-004 manual QA run in `specs/007-editor-image-upload/quickstart.md`, covering PNG/GIF/JPG uploads with metadata proofs (screenshots or log excerpts) and noting any discrepancies for follow-up.

---

## Dependencies & Execution Order

1. **Setup → Foundational → User Stories → Polish**: T001-T005 must complete before any user story begins; Polish tasks wait until all targeted stories ship.
2. **User Story Order (graph)**: `US1 (P1)` → `US2 (P2)` → `US3 (P3)`; US2 depends on Ready `/health` from US1 only for shared module structure, while US3 builds on the CLI scaffolding from US2.
3. **Within User Stories**:
   - Tests (T006, T011, T015) precede implementation tasks to satisfy fail-first guidance.
   - For US1, T007 and T009 can run in parallel once T006 passes; T008 consumes T007; T010 depends on T008 and T009.
   - For US2, T012 and T013 feed into T014 (polling and launch orchestration).
   - For US3, T016 must finish before T017 wires the port through the runtime.

## Parallel Execution Examples

- **US1**: After T006, run T007 (image helper) alongside T009 (modal markup) since they touch different files; merge before starting T008/T010.
- **US2**: T012 (`bin/launch` flag handling) and T013 (`/health` route) can proceed in parallel because they reside in separate files; T014 then integrates both.
- **US3**: Execute T015 (tests) first, then tackle T016 (option parsing) while another developer handles T017 (port propagation and probing) once parsing is ready.

## Implementation Strategy

1. **MVP (User Story 1)**: Complete Phases 1-3 to deliver the upload workflow; verify via independent test before touching CLI work.
2. **Incremental Delivery**: Layer User Story 2 to add auto-open convenience, then User Story 3 for advanced port selection; each story remains testable on its own.
3. **Validation Cadence**: After each phase, run targeted tests (`prove -l t/Ovid/App/LiveEditor/upload.t`, `prove -l t/bin/launch.t`, then full `prove -l t/`) to maintain 90%+ coverage.
4. **Documentation First-Class**: Finish with Polish tasks so README and quickstart stay authoritative for contributors following quickstart.md.
