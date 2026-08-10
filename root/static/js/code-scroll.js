/*
 * Keyboard access to horizontally scrolling code samples.
 *
 * pre.scrolled is `overflow-x: auto`, so a sample wider than the column
 * scrolls. A scroll container that cannot be focused cannot be scrolled with
 * the arrow keys, which leaves the right-hand side of long lines unreachable
 * for anyone not using a pointer (WCAG 2.1 §2.1.1).
 *
 * Chrome already handles this: it makes scroll containers focusable on its
 * own, and only while they actually overflow. This script supplies the same
 * behaviour for browsers that do not, and is a no-op where the browser has it
 * -- an explicit tabindex="0" on an already-focusable scroller changes
 * nothing.
 *
 * Whether a sample overflows depends on the column width, so this cannot be
 * baked into the markup at build time: on a 390px viewport every sample on a
 * code-heavy page scrolls, while at desktop width none of them do. Marking
 * every <pre> at build time would strew focus stops across desktop pages that
 * have nothing to scroll. So the check runs against real layout, and again
 * whenever the layout changes.
 *
 * The label is a group rather than a region on purpose. `role="region"` is the
 * usual advice for a scrollable area, but it is a landmark, and a page here
 * can hold forty code samples -- forty landmarks would bury <main> and the nav
 * in the landmark menu, costing more than it gives. `role="group"` still takes
 * an accessible name, so the focus stop announces itself without that cost.
 */
(function () {
    'use strict';

    function label(pre) {
        var code = pre.querySelector('code');
        var match = code && /\blanguage-([\w+#-]+)/.exec(code.className || '');
        if (!match) {
            return 'Code sample, scrollable';
        }
        var name = match[1];
        return name.charAt(0).toUpperCase() + name.slice(1) + ' code sample, scrollable';
    }

    function sync() {
        var samples = document.querySelectorAll('pre.scrolled');
        for (var i = 0; i < samples.length; i++) {
            var pre = samples[i];
            if (pre.scrollWidth > pre.clientWidth) {
                pre.setAttribute('tabindex', '0');
                pre.setAttribute('role', 'group');
                pre.setAttribute('aria-label', label(pre));
            }
            else {
                // Stop being a focus stop as soon as there is nothing to
                // scroll, so widening the window does not leave dead ones
                // behind.
                pre.removeAttribute('tabindex');
                pre.removeAttribute('role');
                pre.removeAttribute('aria-label');
            }
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', sync);
    }
    else {
        sync();
    }

    // Fonts land after first paint and change how wide a sample measures, so
    // re-check once they are ready.
    if (document.fonts && document.fonts.ready) {
        document.fonts.ready.then(sync);
    }

    var pending;
    window.addEventListener('resize', function () {
        clearTimeout(pending);
        pending = setTimeout(sync, 150);
    });
})();
