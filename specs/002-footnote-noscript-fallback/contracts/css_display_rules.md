# Contract: CSS Display Rules for Footnotes

**Feature**: 002-footnote-noscript-fallback  
**Component**: CSS styling for dialog and noscript elements  
**Date**: 2025-11-09

---

## Purpose

Define CSS rules to ensure:
1. Dialog elements don't interfere with noscript content
2. NoScript footnotes section is styled appropriately
3. No visual conflicts between JavaScript and noscript modes

---

## Key Principle

**Browser-Native Hiding**: The `<noscript>` tag provides automatic hiding when JavaScript is enabled. No CSS needed for core functionality. CSS here is for:
- Styling the noscript footnotes section (optional)
- Ensuring dialog elements remain hidden until Dialog.js activates them

---

## Dialog CSS (Existing, No Changes Required)

### Current Dialog.js Styles

```css
/* /static/css/dialog.css or inline styles */

.dialog-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.7);
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.3s;
  z-index: 1000;
}

.dialog-overlay.active {
  opacity: 1;
  pointer-events: auto;
}

.dialog {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  background: white;
  padding: 2rem;
  border-radius: 8px;
  max-width: 600px;
  width: 90%;
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.3s;
  z-index: 1001;
}

.dialog.active {
  opacity: 1;
  pointer-events: auto;
}

.close-dialog {
  position: absolute;
  top: 1rem;
  right: 1rem;
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
}
```

### Contract Guarantees (Dialog CSS)

- ✅ Dialogs hidden by default (`opacity: 0`, `pointer-events: none`)
- ✅ Only visible when Dialog.js adds `.active` class
- ✅ If JavaScript fails to load, dialogs remain hidden (safe fallback)
- ✅ No interference with noscript content (different elements, different IDs)

---

## NoScript Footnotes CSS (NEW, Optional)

### Recommended Styles

```css
/* /static/css/footnotes.css or inline in footer */

.footnotes {
  margin-top: 3rem;
  margin-bottom: 2rem;
  padding-top: 2rem;
  border-top: 2px solid #d1d5db;
  font-size: 0.9rem;
  color: #374151;
}

.footnotes h2 {
  font-size: 1.5rem;
  font-weight: 600;
  margin-bottom: 1rem;
  color: #111827;
}

.footnotes ol {
  list-style-position: outside;
  padding-left: 2rem;
  margin-left: 0;
}

.footnotes li {
  margin-bottom: 1rem;
  line-height: 1.6;
}

.footnotes li::marker {
  font-weight: bold;
  color: #6b7280;
}

.footnotes a {
  display: inline-block;
  margin-left: 0.5rem;
  text-decoration: none;
  color: #2563eb;
  font-weight: 600;
  transition: color 0.2s;
}

.footnotes a:hover {
  color: #1d4ed8;
  text-decoration: underline;
}

.footnotes a:focus {
  outline: 2px solid #2563eb;
  outline-offset: 2px;
}

/* Screen reader only class (if needed) */
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border-width: 0;
}
```

### Responsive Design

```css
@media screen and (max-width: 768px) {
  .footnotes {
    margin-top: 2rem;
    padding-top: 1.5rem;
    font-size: 0.85rem;
  }
  
  .footnotes h2 {
    font-size: 1.25rem;
  }
  
  .footnotes ol {
    padding-left: 1.5rem;
  }
}
```

---

## Browser Behavior Contracts

### JavaScript Enabled

**What the Browser Does**:
1. Parses HTML, encounters `<noscript>` tag
2. JavaScript is enabled → ignores `<noscript>` content
3. `<noscript>` content **not added to DOM**
4. CSS rules for `.footnotes` never applied (elements don't exist)

**What the User Sees**:
- Dialog overlay and dialogs in DOM (but hidden via CSS)
- Dialog.js loads, adds `.active` class on click
- Footnotes appear as modal popups
- No footnotes section at end of article

### JavaScript Disabled

**What the Browser Does**:
1. Parses HTML, encounters `<noscript>` tag
2. JavaScript is disabled → renders `<noscript>` content
3. `<aside class="footnotes">` and `<ol>` added to DOM
4. CSS rules for `.footnotes` applied

**What the User Sees**:
- Dialog overlay and dialogs in DOM (but remain hidden - no Dialog.js to activate)
- "Footnotes" section at end of article
- Anchor navigation works for footnote references

---

## No-JS Fallback Safety

### Defensive CSS (Optional)

If concerned that dialog elements might somehow become visible without JavaScript:

```css
/* Ensure dialogs never show if JavaScript fails to load */
@media screen {
  .dialog-overlay:not(.active),
  .dialog:not(.active) {
    display: none !important;
  }
}
```

**Note**: This is likely unnecessary since Dialog.js already handles hiding, and dialogs start with `opacity: 0` and `pointer-events: none`.

---

## Print Styles

### Print Footnotes (Both Modes)

```css
@media print {
  /* Hide JavaScript dialogs when printing */
  .dialog-overlay,
  .dialog {
    display: none !important;
  }
  
  /* Ensure noscript footnotes print */
  .footnotes {
    display: block !important;
    page-break-inside: avoid;
  }
  
  .footnotes li {
    page-break-inside: avoid;
  }
}
```

**Contract**: When printing, always show traditional footnote list (noscript version), even if JavaScript is enabled.

---

## Dark Mode Support (Optional)

```css
@media (prefers-color-scheme: dark) {
  .footnotes {
    border-top-color: #4b5563;
    color: #d1d5db;
  }
  
  .footnotes h2 {
    color: #f9fafb;
  }
  
  .footnotes li::marker {
    color: #9ca3af;
  }
  
  .footnotes a {
    color: #60a5fa;
  }
  
  .footnotes a:hover {
    color: #93c5fd;
  }
  
  .footnotes a:focus {
    outline-color: #60a5fa;
  }
}
```

---

## Accessibility CSS Contracts

### Focus Indicators

**Required**: All interactive elements (links) must have visible focus indicators for keyboard navigation.

```css
.footnotes a:focus {
  outline: 2px solid #2563eb;
  outline-offset: 2px;
}

.footnotes a:focus-visible {
  outline: 2px solid #2563eb;
  outline-offset: 2px;
}
```

### High Contrast Mode

```css
@media (prefers-contrast: high) {
  .footnotes {
    border-top: 3px solid currentColor;
  }
  
  .footnotes a {
    text-decoration: underline;
    font-weight: bold;
  }
}
```

---

## CSS File Organization

### Option 1: Inline in Footer Template

```tt2
<noscript>
  <style>
    .footnotes { margin-top: 3rem; /* ... */ }
    .footnotes h2 { font-size: 1.5rem; /* ... */ }
    /* ... more styles ... */
  </style>
  <aside class="footnotes">
    <!-- footnote list -->
  </aside>
</noscript>
```

**Pros**: Ensures styles only load when needed  
**Cons**: Increases HTML size, harder to maintain

### Option 2: Separate CSS File

```html
<link rel="stylesheet" href="/static/css/footnotes.css">
```

**Pros**: Cacheable, maintainable, separation of concerns  
**Cons**: Extra HTTP request (minor with HTTP/2)

### Option 3: Include in Main CSS

```css
/* /static/css/main.css */
/* ... existing styles ... */

/* Footnotes (noscript fallback) */
.footnotes { /* ... */ }
```

**Pros**: No extra HTTP request, already loaded  
**Cons**: Loads CSS even for pages without footnotes

**Recommendation**: Option 3 (include in main CSS) - simplest, most performant with modern browsers.

---

## Contract Guarantees

### Visual Isolation

- ✅ Dialog elements and noscript elements never both visible simultaneously
- ✅ No z-index conflicts (dialogs use z-index 1000+, footnotes in document flow)
- ✅ No layout shifts when switching between modes

### Accessibility

- ✅ All links have visible focus indicators
- ✅ High contrast mode supported
- ✅ Color is not the only indicator (underlining, symbols used)
- ✅ Text remains readable at 200% zoom

### Browser Compatibility

- ✅ Works in all modern browsers (Chrome, Firefox, Safari, Edge)
- ✅ Graceful degradation in older browsers (basic anchor navigation still works)
- ✅ Print styles ensure readable output

---

## Testing Contracts

### Visual Regression Tests

```javascript
// Example with Playwright or similar
test('NoScript footnotes display correctly', async ({ page }) => {
  await page.goto('/articles/test-article.html');
  await page.setJavaScriptEnabled(false);
  
  // Check footnotes section exists
  const footnotes = await page.locator('.footnotes');
  await expect(footnotes).toBeVisible();
  
  // Check styling applied
  const borderTop = await footnotes.evaluate(el => 
    getComputedStyle(el).borderTopWidth
  );
  expect(borderTop).toBe('2px');
});

test('Dialog elements hidden when JS disabled', async ({ page }) => {
  await page.goto('/articles/test-article.html');
  await page.setJavaScriptEnabled(false);
  
  const dialogOverlay = await page.locator('.dialog-overlay');
  const isVisible = await dialogOverlay.isVisible();
  expect(isVisible).toBe(false);
});
```

### Accessibility Tests

```javascript
test('Footnote links have focus indicators', async ({ page }) => {
  await page.goto('/articles/test-article.html');
  await page.setJavaScriptEnabled(false);
  
  const returnLink = await page.locator('.footnotes a').first();
  await returnLink.focus();
  
  const outline = await returnLink.evaluate(el => 
    getComputedStyle(el).outlineWidth
  );
  expect(outline).not.toBe('0px');
});
```

---

## Contract Version

**Version**: 1.0.0 (Initial noscript support)  
**Status**: Proposed (pending implementation)

---

**Related Contracts**:
- [add_note Method](add_note_method.md)
- [Footer Template Footnote Rendering](footer_footnote_rendering.md)
