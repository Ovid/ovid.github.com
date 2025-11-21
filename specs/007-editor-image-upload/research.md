# Research: Editor Image Upload & Launch Enhancements

## Topic 1: Image Resizing Stack & Upload Handling
- **Decision**: Use `Imager` for PNG/GIF/JPG resizing and integrate uploads via Dancer2's `upload` helper, writing temporary files before moving into `root/static/images`.
- **Rationale**: `Imager` natively supports all required formats, offers high-quality resampling, and exposes predictable APIs for constraining output dimensions and recompressing JPEG/PNG files. Dancer2 already depends on Plack middleware that can stream uploads to temp files, so using `upload('field')->path` avoids slurping large blobs into memory. Pairing this with `Path::Tiny` for sanitized destinations keeps the workflow Perl-idiomatic and testable.
- **Alternatives considered**: `Image::Scale` (fast but lacks GIF support and requires extra XS tuning), `Image::Magick`/`PerlMagick` (heavy dependency with brittle installs on macOS CI), `GD` (no GIF write support by default and lower-quality scaling).

## Topic 2: Upload Button Anchor in `root/editor.tt`
- **Decision**: Place the new "Upload Image" control in the existing header action row, immediately to the right of the `Change File` button, and treat that location as the intent behind the spec's "Change Size" wording.
- **Rationale**: Current `root/editor.tt` (lines 200-240) includes only `Change File`, status indicators, and utility buttons; there is no "Change Size" element to attach to. Aligning with the existing header keeps related editing utilities together, ensures keyboard focus order remains logical, and respects the spec's desire for adjacency even though the named button is absent.
- **Alternatives considered**: Creating a brand-new "Change Size" button solely to satisfy placement wording (adds unused UI), or placing the upload button elsewhere (risks diverging from spec intent).

## Topic 3: `MAX_IMAGE_SIZE` Semantics
- **Decision**: Interpret `MAX_IMAGE_SIZE` as a byte budget (default 300_000) stored in `config/ovid.yaml`, use it within both `t/lint.t` and the upload pipeline, and enforce it by iteratively downscaling images until the encoded file size drops below the threshold.
- **Rationale**: `t/lint.t` currently compares the constant against `-s $src`, proving historic usage as a byte limit rather than a pixel dimension. Keeping the same meaning avoids destabilizing lint behavior and matches the "resize to just below ... defined in t/lint.t" requirement. Downscaling until the file written to disk is below the threshold satisfies both lint and upload requirements without needing a second config key.
- **Alternatives considered**: Reinterpreting the value as a max pixel dimension (conflicts with linter logic and makes 300_000 meaningless), or introducing two separate config keys (adds complexity without evidence the user needs distinct values).

## Topic 4: Browser Auto-Open Workflow (`--open` Flag)
- **Decision**: Launch the Dancer2 app in a child process, poll `http://127.0.0.1:<port>/health` (new endpoint) for readiness, and call `Browser::Open::open_browser` exactly once after readiness unless the CLI detects a headless environment (e.g., `$ENV{DISPLAY}` absent on Unix) in which case it logs a warning but continues.
- **Rationale**: `Browser::Open` is already a dependency and abstracts OS-specific commands. Polling the server avoids racing the browser before Dancer2 binds the port, and a health endpoint keeps the check lightweight. Detecting a missing GUI honors the "headless environments" edge case without treating it as a fatal error.
- **Alternatives considered**: Blindly sleeping for a fixed interval (flaky on slower machines), using `system('open', ...)`/`xdg-open` manually (duplicates Browser::Open logic), or forcing the CLI to exit on missing GUI (violates requirement to keep the server running).
