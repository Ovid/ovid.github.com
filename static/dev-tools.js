(function() {
    // Test hook: expose urlToSourceFile to Node via CommonJS without
    // requiring a browser. The browser path has no `module` global, so
    // this branch is invisible to bin/review-served pages.
    if (typeof module !== 'undefined' && module.exports) {
        module.exports = { urlToSourceFile: urlToSourceFile };
        return;
    }

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
                alert('Cannot open editor: ' + data.error +
                      '\n\nThis may be a generated page without a direct source file.');
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

        path = path.replace(/^\//, '');

        // Trailing slash → directory index (mirrors bin/review's
        // /projects/extraction/ → projects/extraction/index.html).
        // Handle this BEFORE the extensionless branch, because
        // path.split('/').pop() on a trailing-slash path returns ''
        // and would skip the .html append, producing 'root/foo/.tt'.
        if (path === '' || path.endsWith('/')) {
            path = path + 'index.html';
        }

        // If the final segment has no extension, treat it as the
        // extensionless form of a .html page (matches bin/review's
        // server-side resolution). Then strip .html for source-file mapping.
        // The two-step approach (append .html, then strip .html) ensures
        // both /blog/foo and /blog/foo.html go through one canonical form
        // before deriving the source file path.
        const finalSegment = path.split('/').pop() || '';
        if (finalSegment !== '' && !finalSegment.includes('.')) {
            path = path + '.html';
        }
        path = path.replace(/\.html$/, '');

        if (!path) path = 'index';

        return 'root/' + path + '.tt';
    }
})();
