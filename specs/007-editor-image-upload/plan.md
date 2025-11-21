# Implementation Plan: Editor Image Upload & Launch Enhancements

**Branch**: `007-editor-image-upload` | **Date**: 2025-11-21 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/007-editor-image-upload/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Extend the live editor so writers can upload PNG/GIF/JPG assets directly beside the existing editor controls, capture optional metadata, and automatically insert the canonical `include/image.tt` snippet at the cursor after the image is resized below the configured maximum and stored under `root/static/images`. In parallel, enhance `bin/launch` with `--open` and `--port` flags so authors can choose a non-default port and immediately open the editor via Browser::Open. Centralize `MAX_IMAGE_SIZE` inside `config/ovid.yaml` and update consumers (upload pipeline, `t/lint.t`) to respect the single source of truth.

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: Perl 5.40+  
**Primary Dependencies**: Dancer2, Template Toolkit 2, Browser::Open, Imager (for PNG/GIF/JPG resizing)  
**Storage**: Filesystem (root/, static/), YAML config via `Less::Config`, SQLite read-only for builds  
**Testing**: Test::Most + Devel::Cover (>=90%)  
**Target Platform**: Localhost Dancer2 app on macOS/Linux (CLI-launched)  
**Project Type**: CLI + local web UI (single-user)  
**Performance Goals**: Upload-save-resize-insert cycle completes <5s (SC-001); launch command brings up server and browser <3s  
**Constraints**: Bind to 127.0.0.1, zero external services, upload button to live in existing header action row to the right of the "Change File" control in `root/editor.tt`  
**Scale/Scope**: Single concurrent writer/session; assets stored under `root/static/images` but tests must avoid touching production data  
**Configuration**: `max_image_size_bytes` in `config/ovid.yaml` becomes the single source of truth for lint + upload byte limits (default 300_000)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **I. CPAN-Style Module Architecture**: Upload + CLI logic will live inside existing `Ovid::*` modules with POD and dedicated helpers as needed.
- [x] **II. CLI-First Interface Design**: `bin/launch` remains the primary entry point and will gain new flags.
- [x] **III. Test::Most with 90%+ Coverage**: Plan includes new `t/Ovid/App/LiveEditor/upload.t`, CLI option tests, and coverage validation tied into existing Devel::Cover workflow.
- [x] **IV. Accessible HTML5 Static Output**: Editor UI changes remain within accessible HTML/CSS.
- [x] **V. Zero External Service Dependencies**: Browser::Open is local; uploads and resizing remain offline.
- [x] **VI. Production Data Protection**: Must ensure tests use temp directories so `static/images/` in repo is untouched.
- [x] **VII. Modern Perl 5.40+ Features**: Existing modules already use signatures and `use v5.40;`.
- [x] **VIII. AI Agent Safety Constraints**: No destructive git operations required.
- [x] **IX. Blogdown Content Format**: Uploaded assets feed the existing Blogdown include snippet without altering content format semantics.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
  
  IMPORTANT FOR THIS PROJECT: Per Constitution v1.5.0 Development Scope Boundaries,
  all feature development must be confined to:
  - lib/     : Perl modules (e.g., Ovid::*, Less::*, Template::Plugin::*)
  - bin/     : CLI scripts (e.g., article, rebuild)
  - root/    : Template Toolkit templates (.html files with TT directives)
  
  DO NOT modify generated content (articles/, blog/, tags/), user assets (static/, 
  css/, images/), or production data (db/). These are auto-generated or user-managed.
-->

```text
# This project: Static site generator (Perl + Template Toolkit)
lib/
├── Ovid/
│   └── App/
│       └── LiveEditor.pm        # Add upload endpoint + config-driven resizing helper
├── Less/
│   └── Config.pm                # Already loads config; will expose MAX_IMAGE_SIZE value
└── Ovid/
    └── Util/
        └── [new image helper].pm (if upload logic is extracted)

bin/
├── launch                        # Gains --open/--port handling + browser launch orchestration
└── article                       # Already exists; unchanged except reusing new launch contract

root/
├── editor.tt                     # Adds Upload Image modal + snippet insertion UI/JS
└── include/image.tt              # Reference snippet remains the insertion target

t/
├── Ovid/App/LiveEditor.t         # Extend to cover upload endpoint & validation paths
├── bin/launch.t                  # New tests for CLI option parsing
└── lint.t                        # Read MAX_IMAGE_SIZE from config instead of constant

# Generated content - DO NOT MODIFY in feature tasks:
# articles/, blog/, tags/     : Generated HTML
# static/, css/, images/      : User-managed assets
# db/                         : Production databases
# tmp/, cover_db/             : Build artifacts
```

**Structure Decision**:
- `lib/Ovid/App/LiveEditor.pm`: Add POST `/api/upload-image`, config wiring, and snippet response payloads.
- `lib/Ovid/Util/Image.pm` (working name): Optional helper encapsulating resize + validation logic for reuse/testing.
- `bin/launch`: Integrate Getopt::Long, handle `--open/--port`, validate port availability, and orchestrate Browser::Open once server is ready.
- `root/editor.tt`: Introduce Upload Image button + modal UI, metadata form, clipboard/file handling, and JS snippet insertion.
- `config/ovid.yaml`: Add `max_image_size_bytes` entry consumed via `Less::Config` and reused in code/tests.
- `t/lint.t`: Load config-driven MAX_IMAGE_SIZE and keep warnings consistent.
- `t/Ovid/App/LiveEditor/upload.t` & `t/bin/launch.t`: Ensure new behaviors have coverage.

## Complexity Tracking

None. All gates pass without exceptions.
