# Quickstart: Blogdown Live Editor

## Prerequisites
- Perl 5.40+
- `cpanm` installed
- Dependencies installed: `cpanm --installdeps .`

## Installation
1. Ensure `Dancer2` is installed (added to `cpanfile`).
2. Run `cpanm --installdeps .`

## Usage

### Launching the Editor
To edit an article or blog post:

```bash
perl bin/launch path/to/article.md
```

This will:
1. Start the Dancer2 server on `http://127.0.0.1:3000`.
2. Open the editor in your default browser (optional, or just print the URL).

### Editing
1. Type in the left pane.
2. Wait 1 second for auto-save.
3. Click "Refresh Preview" (or wait if auto-refresh is enabled) to see changes in the right pane.

### Stopping
Press `Ctrl+C` in the terminal to stop the server.
