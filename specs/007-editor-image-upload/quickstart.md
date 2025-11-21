# Quickstart: Editor Image Upload & Launch Enhancements

## Prerequisites
- Perl 5.40+ via perlbrew (`source ~/.bash_profile`).
- Project dependencies installed: `cpanm --installdeps .` (adds `Imager`).
- Browser available for `Browser::Open` (headless shells will skip auto-launch).

## Configure MAX_IMAGE_SIZE
1. Open `config/ovid.yaml` and add `max_image_size_bytes: 300000` (or your preferred limit).
2. Run `prove -l t/lint.t` to confirm the linter now reads the value from config.

## Launching the Editor
```bash
perl bin/launch root/blog/my-post.tt2markdown --port 3100 --open
```
This command will:
1. Normalize any generated HTML path back to the TT source file.
2. Start the Dancer2 server on `http://127.0.0.1:3100`.
3. Open the editor in your default browser once `/health` responds.
4. Stream server logs until you press `Ctrl+C`.

### Port & Browser Flags
- `--port <number>`: Any value between 1024-65535. The CLI fails fast if the port is busy.
- `--open`: Opens the browser exactly once after the server is ready. On headless hosts, the CLI prints a warning but leaves the server running.

## Uploading an Image
1. Click **Upload Image** (to the right of the header controls) to open the modal.
2. Provide a filename (required) and optional source, alt text, and caption.
3. Either choose a file or paste an image from the clipboard; the preview lists detected MIME type and size.
4. Click **Save**. The server validates type, resizes if needed to stay under `max_image_size_bytes`, writes to `root/static/images/<filename>`, and returns the `[% INCLUDE include/image.tt ... %]` snippet.
5. The snippet is inserted at your current cursor location with all metadata HTML-escaped. Any validation error keeps the modal open with your inputs intact.

## Stopping the Editor
- Press `Ctrl+C` in the terminal running `bin/launch`. The CLI traps the signal, shuts down the child Dancer2 process, and exits cleanly.

## Manual QA Verification (SC-003)

To verify the implementation, perform the following checks:

1.  **Launch with Defaults**:
    - Run `perl bin/launch root/blog/my-post.tt`
    - Verify server starts on port 3000.
    - Verify browser does *not* open automatically.

2.  **Launch with Flags**:
    - Run `perl bin/launch root/blog/my-post.tt --open --port 3100`
    - Verify server starts on port 3100.
    - Verify browser opens automatically to `http://127.0.0.1:3100/`.

3.  **Image Upload**:
    - In the editor, click "Upload Image".
    - Upload a PNG, GIF, and JPG image.
    - Verify images are saved to `root/static/images/`.
    - Verify the inserted snippet is correct: `[% INCLUDE include/image.tt ... %]`.
    - Verify metadata (alt, caption, source) is correctly escaped in the snippet.
    - Verify images larger than `max_image_size_bytes` are resized or rejected (depending on implementation details, here resized).

4.  **Headless Environment**:
    - If possible, run in a headless environment (e.g., Docker container).
    - Run with `--open`.
    - Verify warning is printed and server continues running.
