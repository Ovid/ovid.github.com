# Development Edit Button Feature

**Date**: 2026-01-01
**Status**: Design Approved
**Author**: Curtis "Ovid" Poe

## Overview

Add an "Edit" button to every page when browsing the site locally that opens the live editor for the current page's source file. The button only appears when running a custom development server, ensuring zero impact on production builds.

**Key Requirements**:
- Edit button appears only when running custom dev server (`bin/review`)
- Button positioned in upper left corner, above search functionality
- Clicking opens live editor for current page's source file
- Automatically maps URLs to source `.tt` or `.tt2markdown` files
- Shows appropriate errors for unmappable files (tag pages, indexes)
- Fire-and-forget API call to launch editor in background
- Comprehensive tests ensure dev tools never leak to production

## Architecture

The feature consists of three main components:

### 1. Development Server (`bin/review`)
A Dancer2 application that replaces `http_this` for local development. Runs on port 7007, serves static files, provides API endpoints, and injects dev mode flag into HTML responses.

### 2. HTML Injection Middleware
Server-side hook that injects `window.DEV_MODE = true` and `<script src="/dev-tools.js"></script>` into all HTML responses. This signals to client-side code that dev mode is active.

### 3. Client-Side Dev Tools (`/dev-tools.js`)
JavaScript that checks for `window.DEV_MODE` flag, creates Edit button UI, extracts source file path from URL, and makes API call to launch editor.

## Component Details

### bin/review (New Development Server)

**Purpose**: Custom development server with dev mode capabilities

**Technology**: Dancer2 web framework

**Key Features**:
- Serves static files from root directory on port 7007
- Provides `/api/launch-editor` endpoint
- Injects dev mode flag into HTML responses via middleware
- Maintains compatibility with existing `http_this` workflow

**Static File Serving**:
```perl
# Serve generated HTML files
get '/**' => sub {
    my ($splat) = splat;
    my $path = join('/', @$splat);

    # Map to file system
    my $file = path($path)->absolute;

    # Serve if exists
    return send_file($file, system_path => 1) if -f $file;

    # 404 otherwise
    status 404;
    return "Not found";
};
```

**HTML Injection Hook**:
```perl
hook after => sub {
    my $response = shift;

    # Only inject into HTML responses
    return unless $response->content_type =~ m{text/html};

    my $content = $response->content;

    # Inject dev mode flag and script reference in <head>
    my $injection = q{
        <script>window.DEV_MODE = true;</script>
        <script src="/dev-tools.js"></script>
    };

    $content =~ s{</head>}{$injection</head>};
    $response->content($content);
};
```

### API Endpoint: POST /api/launch-editor

**Purpose**: Launch live editor for specified file

**Request Body**:
```json
{
  "file": "root/blog/my-post.tt"
}
```

**Response** (Success):
```json
{
  "success": true,
  "file": "root/blog/my-post.tt"
}
```

**Response** (Error):
```json
{
  "error": "File not found: root/blog/my-post.tt"
}
```

**Implementation**:
```perl
post '/api/launch-editor' => sub {
    my $file = body_parameters->get('file');

    # Validate file path
    return send_error("No file specified", 400) unless $file;
    return send_error("Invalid file path", 400) if $file =~ /\.\./;

    # Check file exists
    my $path = path($file);
    return send_error("File not found: $file", 404) unless $path->exists;

    # Launch editor in background (fire-and-forget)
    my $launch_cmd = "perl bin/launch '$file' 2>&1 &";
    system($launch_cmd);

    return to_json({ success => 1, file => $file });
};
```

**Security Considerations**:
- Path validation prevents directory traversal (`..` check)
- File existence verification before launch
- No authentication needed (localhost-only server)
- Inherits `bin/launch` security (project directory restriction)

### File Path Detection Logic

**Challenge**: Map URL paths to source template files

**Solution**: JavaScript function that mirrors `bin/launch` auto-correction logic

**URL to File Path Mapping**:
```javascript
function urlToSourceFile(url) {
    const urlObj = new URL(url);
    let path = urlObj.pathname;

    // Remove leading slash and .html extension
    // /blog/my-post.html → blog/my-post
    path = path.replace(/^\//, '').replace(/\.html$/, '');

    // Try .tt first
    let sourcePath = `root/${path}.tt`;

    // For articles and blog, also try .tt2markdown
    if (path.startsWith('articles/') || path.startsWith('blog/')) {
        // Could try both, but server will validate
        // Prefer .tt, fallback handled by server-side file check
    }

    return sourcePath;
}
```

**Special Cases**:
- Tag pages (`/tags/perl.html`): Show error - no direct source file
- Paginated indexes (`/blog_2.html`): Show error - generated file
- Homepage (`/index.html`): Maps to `root/index.tt`

**Error Handling**:
When API returns 404, show user-friendly error:
```javascript
alert(`Cannot open editor: ${response.error}\n\nThis may be a generated page (tags, pagination) without a direct source file.`);
```

### Edit Button UI/UX

**Visual Design**:
- Small icon button with pencil symbol (Font Awesome or Unicode ✏️)
- Positioned in upper left corner, above search functionality
- Minimal visual footprint to avoid cluttering pages
- Hover effect to indicate interactivity

**HTML Structure** (injected by dev-tools.js):
```html
<button id="dev-edit-button"
        style="position: fixed; top: 10px; left: 10px; z-index: 9999;"
        title="Edit this page in live editor">
  ✏️
</button>
```

**Interaction Flow**:
1. User clicks Edit button
2. JavaScript extracts current URL
3. Converts URL to source file path
4. POSTs to `/api/launch-editor` with file path
5. Server validates and launches `bin/launch` in background
6. New browser window opens with live editor (handled by `bin/launch`)
7. User sees confirmation or error alert

**CSS Styling**:
```css
#dev-edit-button {
    background: #4CAF50;
    color: white;
    border: none;
    border-radius: 4px;
    padding: 8px 12px;
    cursor: pointer;
    font-size: 16px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.2);
}

#dev-edit-button:hover {
    background: #45a049;
}
```

### dev-tools.js Implementation

**Full Client-Side Script**:
```javascript
(function() {
    // Only run if dev mode is enabled
    if (!window.DEV_MODE) return;

    // Wait for DOM ready
    document.addEventListener('DOMContentLoaded', function() {
        createEditButton();
    });

    function createEditButton() {
        const button = document.createElement('button');
        button.id = 'dev-edit-button';
        button.innerHTML = '✏️';
        button.title = 'Edit this page in live editor';
        button.style.cssText = `
            position: fixed;
            top: 10px;
            left: 10px;
            z-index: 9999;
            background: #4CAF50;
            color: white;
            border: none;
            border-radius: 4px;
            padding: 8px 12px;
            cursor: pointer;
            font-size: 16px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.2);
        `;

        button.addEventListener('click', handleEditClick);
        button.addEventListener('mouseenter', function() {
            this.style.background = '#45a049';
        });
        button.addEventListener('mouseleave', function() {
            this.style.background = '#4CAF50';
        });

        document.body.appendChild(button);
    }

    function handleEditClick() {
        const sourceFile = urlToSourceFile(window.location.href);

        fetch('/api/launch-editor', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ file: sourceFile })
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                console.log('Editor launched for:', data.file);
            } else if (data.error) {
                alert(`Cannot open editor: ${data.error}\n\nThis may be a generated page without a direct source file.`);
            }
        })
        .catch(error => {
            console.error('Error launching editor:', error);
            alert('Failed to launch editor. Check console for details.');
        });
    }

    function urlToSourceFile(url) {
        const urlObj = new URL(url);
        let path = urlObj.pathname;

        // Remove leading slash and .html extension
        path = path.replace(/^\//, '').replace(/\.html$/, '');

        // Default to index if empty
        if (!path) path = 'index';

        // Map to source file
        return `root/${path}.tt`;
    }
})();
```

## Testing Strategy

**Critical Requirement**: Ensure dev tools NEVER appear in production builds

### Test Files

#### 1. `t/dev_server.t`
**Purpose**: Verify bin/review server functionality

**Tests**:
- Server starts on port 7007
- Serves static HTML files correctly
- `/api/launch-editor` endpoint exists and responds
- Returns appropriate error codes (400, 404)
- Accepts valid file paths

**Example**:
```perl
use Test::Most;
use Plack::Test;
use HTTP::Request::Common;

# Load app
my $app = do 'bin/review' or die $!;

test_psgi $app => sub {
    my $cb = shift;

    # Test API endpoint exists
    my $res = $cb->(POST '/api/launch-editor',
        Content_Type => 'application/json',
        Content => '{"file":"root/index.tt"}'
    );

    ok $res->is_success, 'API endpoint responds';

    # Test validation
    $res = $cb->(POST '/api/launch-editor',
        Content_Type => 'application/json',
        Content => '{"file":"../etc/passwd"}'
    );

    is $res->code, 400, 'Rejects path traversal';
};
```

#### 2. `t/dev_tools_injection.t`
**Purpose**: Verify HTML responses contain DEV_MODE flag when served by bin/review

**Tests**:
- HTML responses contain `window.DEV_MODE = true`
- HTML responses contain `<script src="/dev-tools.js"></script>`
- Non-HTML responses are not modified
- Injection appears in `<head>` section

**Example**:
```perl
use Test::Most;
use Plack::Test;
use HTTP::Request::Common;

my $app = do 'bin/review' or die $!;

test_psgi $app => sub {
    my $cb = shift;

    my $res = $cb->(GET '/index.html');
    my $content = $res->content;

    like $content, qr{window\.DEV_MODE\s*=\s*true},
        'HTML contains DEV_MODE flag';

    like $content, qr{<script src="/dev-tools\.js"></script>},
        'HTML contains dev-tools script reference';

    like $content, qr{</head>.*window\.DEV_MODE}s,
        'Injection appears before closing head tag';
};
```

#### 3. `t/dev_tools_exclusion.t` (CRITICAL SAFETY TEST)
**Purpose**: Verify generated static files NEVER contain dev tools or DEV_MODE flag

**Tests**:
- Scan all generated HTML files in `articles/`, `blog/`, etc.
- Confirm NO file contains `window.DEV_MODE`
- Confirm NO file contains `/dev-tools.js` reference
- Fail loudly if dev tools found in production files

**Example**:
```perl
use Test::Most;
use Path::Tiny;

# Scan all generated HTML
my @html_files = path('.')
    ->child('articles')->children(qr/\.html$/)
    ->concat(path('.')->child('blog')->children(qr/\.html$/));

for my $file (@html_files) {
    my $content = $file->slurp_utf8;

    unlike $content, qr{window\.DEV_MODE},
        "$file must not contain DEV_MODE flag";

    unlike $content, qr{dev-tools\.js},
        "$file must not contain dev-tools.js reference";
}

ok scalar(@html_files) > 0, 'Found HTML files to test';
```

#### 4. `t/root/dev_tools_js.t`
**Purpose**: Verify dev-tools.js exists and contains expected logic

**Tests**:
- File exists at correct path
- Contains DEV_MODE check
- Contains createEditButton function
- Contains urlToSourceFile function
- Contains fetch call to /api/launch-editor

**Example**:
```perl
use Test::Most;
use Path::Tiny;

my $js_file = path('static/dev-tools.js');

ok $js_file->exists, 'dev-tools.js exists';

my $content = $js_file->slurp_utf8;

like $content, qr{window\.DEV_MODE},
    'Checks for DEV_MODE flag';

like $content, qr{function createEditButton},
    'Contains createEditButton function';

like $content, qr{function urlToSourceFile},
    'Contains urlToSourceFile function';

like $content, qr{/api/launch-editor},
    'Makes API call to launch-editor endpoint';
```

### Test Execution Order

1. Run `t/dev_tools_exclusion.t` FIRST to ensure production safety
2. Run `t/dev_server.t` to verify server functionality
3. Run `t/dev_tools_injection.t` to verify dev mode injection
4. Run `t/root/dev_tools_js.t` to verify client-side logic

All tests must pass before feature is considered complete.

## Security Considerations

### Server-Side Security
- **Localhost binding**: Server binds to `127.0.0.1` only (no external access)
- **Path validation**: Reject paths containing `..` to prevent traversal
- **File existence checks**: Verify files exist before launching editor
- **Project directory restriction**: Inherited from `bin/launch` (only edits files within project)

### Client-Side Security
- **No sensitive data exposure**: Dev mode flag is intentionally visible (dev-only feature)
- **API endpoint not exposed in production**: Endpoint only exists when bin/review is running
- **No authentication needed**: Server is localhost-only by design

### Production Safety
- **Zero production impact**: Dev tools only injected by bin/review server
- **Static files remain clean**: Generated HTML never contains dev mode code
- **Comprehensive exclusion tests**: `t/dev_tools_exclusion.t` prevents leakage
- **Gitignore protection**: Ensure dev-tools.js is in static/ directory (not accidentally served)

## Implementation Checklist

### Phase 1: Development Server
- [ ] Create `bin/review` script with Dancer2 app
- [ ] Implement static file serving on port 7007
- [ ] Add HTML injection hook for dev mode flag
- [ ] Add `<script src="/dev-tools.js">` injection
- [ ] Test server starts and serves files

### Phase 2: API Endpoint
- [ ] Implement `POST /api/launch-editor` endpoint
- [ ] Add path validation (reject `..`)
- [ ] Add file existence checking
- [ ] Implement background process launch for `bin/launch`
- [ ] Test with valid and invalid file paths

### Phase 3: Client-Side Dev Tools
- [ ] Create `static/dev-tools.js` file
- [ ] Implement `window.DEV_MODE` check
- [ ] Implement `createEditButton()` function
- [ ] Implement `urlToSourceFile()` mapping logic
- [ ] Implement `handleEditClick()` with fetch to API
- [ ] Add error handling for unmappable files

### Phase 4: Testing
- [ ] Write `t/dev_server.t` (server functionality)
- [ ] Write `t/dev_tools_injection.t` (dev mode flag injection)
- [ ] Write `t/dev_tools_exclusion.t` (production safety - CRITICAL)
- [ ] Write `t/root/dev_tools_js.t` (client-side logic)
- [ ] Run all tests and verify 100% pass rate
- [ ] Verify test coverage for new code

### Phase 5: Integration Testing
- [ ] Run `bin/review` and browse to http://127.0.0.1:7007/
- [ ] Verify Edit button appears on articles
- [ ] Verify Edit button appears on blog posts
- [ ] Click Edit button on various pages and verify live editor opens
- [ ] Test error handling on tag pages and paginated indexes
- [ ] Verify Edit button does NOT appear in static files (production check)

### Phase 6: Documentation
- [ ] Update `CLAUDE.md` with `bin/review` usage
- [ ] Add troubleshooting section for common issues
- [ ] Document keyboard shortcuts if added
- [ ] Add "Development Workflow" section explaining bin/review vs http_this

## Future Enhancements

**Out of scope for initial implementation, but worth considering**:

1. **Keyboard Shortcut**: Add `Ctrl+E` or `Cmd+E` to trigger edit button
2. **File Browser Integration**: Show file picker when source file is ambiguous
3. **Live Reload**: Auto-refresh page when file is saved in editor
4. **Multi-File Editing**: Allow opening multiple editors simultaneously
5. **Port Configuration**: Allow custom port via `--port` flag
6. **Status Indicator**: Show when editor server is running (color-coded dot)

## Success Criteria

The feature is considered complete when:

1. ✅ Edit button appears on all pages when running `bin/review`
2. ✅ Edit button does NOT appear in generated static files
3. ✅ Clicking Edit button opens live editor for correct source file
4. ✅ Error handling works for unmappable files (tags, pagination)
5. ✅ All four test files pass with 100% success rate
6. ✅ `t/dev_tools_exclusion.t` confirms zero production leakage
7. ✅ Documentation updated in `CLAUDE.md`
8. ✅ Manual integration testing passes all scenarios

## References

- Existing live editor: `bin/launch`
- Template processing: `lib/Ovid/Template/File.pm`
- URL routing: See existing site structure in `root/`
- Dancer2 documentation: https://metacpan.org/pod/Dancer2
