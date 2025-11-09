# Feature Specification: Footnote NoScript Fallback

**Feature Branch**: `002-footnote-noscript-fallback`  
**Created**: 2025-11-09  
**Status**: Draft  
**Input**: User description: "Bug report: When JS is disabled all footnotes are shown and the page overlay is active (same as when you click a footnote) with no way of disabling that. Restore the old <noscript> behavior where footnotes are listed at the end of the article with anchor links for navigation when JavaScript is disabled, while maintaining current JavaScript-based popup behavior when JavaScript is enabled."

## Terminology & Definitions *(mandatory)*

**Footnote**: A reference marker in the article text (displayed as a clipboard icon) that links to additional commentary or clarification.

**JavaScript-Enabled Behavior**: When JavaScript is available, clicking a footnote icon opens an accessible modal dialog overlay with the footnote text, using the Dialog.js library.

**NoScript Fallback Behavior**: When JavaScript is disabled or unavailable, footnotes appear as:
1. An inline anchor link at the point of reference (with a clipboard icon)
2. A numbered list of footnotes at the end of the article content
3. Bidirectional navigation via anchor links (reference → footnote, footnote → reference)

**Graceful Degradation**: The principle that the site must remain fully functional and accessible when JavaScript is disabled, with footnotes readable through standard HTML anchor navigation.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - JavaScript-Enabled Footnote Viewing (Priority: P1)

As a reader with JavaScript enabled, I want to click on footnote markers and see footnotes in a popup dialog so that I can read additional context without losing my place in the article.

**Why this priority**: This is the current production behavior and must remain unchanged. Most users have JavaScript enabled, making this the primary user experience.

**Independent Test**: Can be fully tested by loading an article with footnotes in a JavaScript-enabled browser, clicking footnote icons, and verifying the modal dialog appears with correct content. Can be tested independently of the noscript functionality.

**Acceptance Scenarios**:

1. **Given** an article with footnotes and JavaScript is enabled, **When** I click a footnote clipboard icon, **Then** a modal dialog overlay appears with the footnote text
2. **Given** a footnote modal is open, **When** I click the close button (×) or press ESC, **Then** the modal closes and I return to reading position
3. **Given** a footnote modal is open, **When** I click the overlay background, **Then** the modal closes
4. **Given** multiple footnotes exist in an article, **When** I click different footnote icons, **Then** each displays its corresponding footnote text in the modal
5. **Given** the page has JavaScript enabled, **When** I view the page source or DOM, **Then** no `<noscript>` content is visible to the user (it's hidden by the browser)

---

### User Story 2 - NoScript Footnote Navigation (Priority: P2)

As a reader with JavaScript disabled or using a browser with JavaScript blocked, I want to click on footnote markers to navigate to footnote text at the end of the article so that I can read footnotes without requiring JavaScript.

**Why this priority**: This addresses the reported accessibility bug. While fewer users disable JavaScript, accessibility and graceful degradation are core requirements per the project constitution.

**Independent Test**: Can be fully tested by loading an article with JavaScript disabled, clicking footnote anchor links, and verifying navigation to the footnotes section at the bottom. Delivers standalone value for no-JS users.

**Acceptance Scenarios**:

1. **Given** an article with footnotes and JavaScript is disabled, **When** I load the page, **Then** I see a "Footnotes" section at the end of the article content (before the footer) with all footnotes listed
2. **Given** JavaScript is disabled, **When** I click a footnote clipboard icon in the text, **Then** the browser scrolls to the corresponding footnote at the bottom of the page
3. **Given** I'm viewing a footnote at the bottom, **When** I click the return link, **Then** the browser scrolls back to where the footnote was referenced in the text
4. **Given** multiple footnotes exist, **When** JavaScript is disabled, **Then** each footnote has a unique numbered ID and correct bidirectional anchor links
5. **Given** JavaScript is disabled, **When** I view the page, **Then** no modal dialog overlay or JavaScript-based UI elements are visible or interfere with reading
6. **Given** JavaScript is disabled, **When** I load the page, **Then** there is no visible page overlay blocking content

---

### User Story 3 - Prevent Overlay Interference Without JavaScript (Priority: P1)

As a reader with JavaScript disabled, I want the page to be fully readable without any modal overlays or visual interference so that I can read the article content normally.

**Why this priority**: This directly addresses the critical bug where "the page overlay is active with no way of disabling that" - this makes the entire page unreadable without JavaScript. This is a critical accessibility failure.

**Independent Test**: Can be fully tested by disabling JavaScript and verifying that no modal overlay appears on page load and that all article content is readable. This is independently testable and addresses the most severe aspect of the bug.

**Acceptance Scenarios**:

1. **Given** JavaScript is disabled, **When** I load an article page with footnotes, **Then** no `.dialog-overlay` element is visible or blocks content
2. **Given** JavaScript is disabled, **When** I load an article page with footnotes, **Then** no `.dialog` elements are visible on the page
3. **Given** JavaScript is disabled, **When** I inspect the page CSS, **Then** the dialog overlay and dialog boxes have appropriate `display: none` or equivalent hiding via `<noscript>` wrapper exclusion
4. **Given** JavaScript is disabled, **When** I scroll through the article, **Then** no semi-transparent dark overlay covers the content
5. **Given** JavaScript is disabled, **When** I use Reader Mode or DOM inspector, **Then** the page is fully accessible without requiring modifications

---

### User Story 4 - Maintain Accessibility Standards (Priority: P3)

As a reader using assistive technology, I want footnotes to be accessible whether JavaScript is enabled or disabled so that I can navigate and understand footnotes regardless of my browsing environment.

**Why this priority**: Accessibility is critical but the current JavaScript implementation already has ARIA attributes. This story ensures the noscript fallback is also accessible.

**Independent Test**: Can be tested with screen readers (both with and without JavaScript) to verify that footnote navigation is announced correctly and that all content is accessible.

**Acceptance Scenarios**:

1. **Given** JavaScript is enabled, **When** I use a screen reader, **Then** footnote links are announced with appropriate ARIA labels ("Open Footnote")
2. **Given** JavaScript is disabled, **When** I use a screen reader, **Then** footnote anchor links are announced meaningfully (e.g., "Footnote 1", "Return to reference")
3. **Given** either JavaScript state, **When** I navigate with keyboard only, **Then** I can access and read all footnotes using Tab and Enter keys
4. **Given** footnotes exist in noscript mode, **When** I use a screen reader, **Then** the footnotes section is properly announced as a landmark or heading

---

### Edge Cases

- **Edge Case 1 (Nested HTML in footnotes)**: What happens when footnote text contains complex HTML (links, code blocks, formatting)?
  - **Resolution**: Both JavaScript and noscript implementations must render HTML correctly; test with footnotes containing `<a>`, `<code>`, `<em>`, `<strong>` tags
  
- **Edge Case 2 (Many footnotes)**: How does the system handle articles with 20+ footnotes?
  - **Resolution**: NoScript section should have anchor navigation that works efficiently; JavaScript dialogs already handle this individually; test with high-footnote-count articles
  
- **Edge Case 3 (Footnote in heading or special context)**: What happens when a footnote appears in a heading, blockquote, or list item?
  - **Resolution**: Anchor links must work regardless of parent context; IDs must be unique; test footnotes in various HTML contexts
  
- **Edge Case 4 (Browser compatibility)**: How do different browsers handle the noscript tag and hidden JavaScript elements?
  - **Resolution**: Test in Chrome, Firefox, Safari with JavaScript both enabled and disabled; verify CSS properly hides JS elements when noscript is active
  
- **Edge Case 5 (Search engine indexing)**: Will search engines properly index both versions of footnotes?
  - **Resolution**: Search engines typically execute JavaScript; noscript content should not duplicate content; verify robots see intended content

- **Edge Case 6 (Anchor link conflicts)**: What if footnote IDs conflict with existing page anchor IDs?
  - **Resolution**: Use consistent "footnote-N" and "footnote-N-return" naming pattern; audit existing ID usage to prevent conflicts

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST maintain current JavaScript-based modal dialog behavior for footnotes when JavaScript is enabled (modal opens on click, closes on ESC key or overlay click, traps focus within dialog)
- **FR-002**: System MUST render a "Footnotes" section at the end of article content (before pager/footer) when JavaScript is disabled
- **FR-003**: System MUST wrap JavaScript-dependent elements (`.dialog-overlay`, `.dialog` divs, Dialog.js scripts) so they are not rendered when JavaScript is disabled
- **FR-004**: System MUST provide anchor link navigation from footnote reference to footnote text when JavaScript is disabled
- **FR-005**: System MUST provide return anchor link from footnote text back to reference point when JavaScript is disabled
- **FR-006**: System MUST use unique, sequential IDs for footnotes (e.g., `footnote-1`, `footnote-2`) in noscript mode
- **FR-007**: System MUST use unique return reference IDs (e.g., `footnote-1-return`, `footnote-2-return`) in noscript mode
- **FR-008**: System MUST display footnote numbers consistently between reference point and footnote list in noscript mode
- **FR-009**: System MUST NOT display both JavaScript dialog content and noscript footnote list to the same user
- **FR-010**: System MUST ensure no modal overlay or visual interference appears when JavaScript is disabled
- **FR-011**: System MUST render footnote content correctly in both JavaScript modal and noscript list formats
- **FR-012**: The `add_note()` method in `lib/Template/Plugin/Ovid.pm` MUST generate both JavaScript-compatible HTML and noscript-compatible HTML
- **FR-013**: Template footer (`root/include/footer.tt`) MUST conditionally render footnotes section based on presence of footnotes and JavaScript state
- **FR-014**: System MUST maintain ARIA attributes for accessibility in JavaScript mode
- **FR-015**: System MUST use semantic HTML for footnotes in noscript mode (ordered list or definition list)
- **FR-016**: System MUST prevent dialog overlay and dialog elements from displaying when JavaScript is disabled by wrapping them in appropriate mechanisms (e.g., excluding from `<noscript>` content or ensuring they are only rendered when JavaScript initializes)

### Non-Functional Requirements

- **NFR-001**: Footnote rendering MUST NOT significantly impact page load time (< 50ms additional processing)
- **NFR-002**: Solution MUST work across modern browsers (Chrome, Firefox, Safari, Edge) with JavaScript both enabled and disabled
- **NFR-003**: HTML output MUST be valid HTML5
- **NFR-004**: CSS for dialogs MUST only apply when JavaScript is enabled (avoid style conflicts)
- **NFR-005**: The implementation MUST be compatible with existing Template Toolkit template structure
- **NFR-006**: Changes MUST NOT break existing articles that use `Ovid.add_note()` or `Ovid.note()`

### Key Entities

- **Footnote Reference**: The inline marker in article text where a footnote is called (clipboard icon + anchor link)
- **Footnote Content**: The actual text of the footnote, including any HTML formatting
- **Footnote Number**: Sequential numeric identifier for each footnote in an article
- **JavaScript Dialog**: The modal popup component using Dialog.js library
- **NoScript Footnote List**: The HTML section at the end of articles containing all footnotes with navigation links

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: When JavaScript is enabled, all footnote interactions match current production behavior (modal dialogs open/close correctly) - verified by manual testing in 3+ browsers
- **SC-002**: When JavaScript is disabled, readers can navigate to and from all footnotes using anchor links - verified by testing with JavaScript disabled in 3+ browsers
- **SC-003**: When JavaScript is disabled, no modal overlay or visual interference blocks article content - verified by visual inspection and screenshot comparison
- **SC-004**: All existing articles with footnotes (e.g., `building-an-iphone-app-with-chatgpt.html`) display correctly in both JavaScript and noscript modes - verified by testing representative sample of 5+ articles
- **SC-005**: HTML validation passes for articles with footnotes in both JavaScript and noscript modes - verified by W3C validator
- **SC-006**: Zero regressions in existing functionality - all existing tests pass after implementation
- **SC-007**: Screen reader announces footnotes appropriately in both modes - verified with NVDA or VoiceOver testing
- **SC-008**: The bug report scenario ("page overlay is active with no way of disabling") is completely resolved - verified by disabling JavaScript and confirming no overlay appears

## Implementation Context *(informational)*

### Current Implementation

The current footnote system (post-commit `0c0ca339`) works as follows:

1. **Template Toolkit Call**: Articles use `[% Ovid.add_note("note text") %]` or `[% Ovid.note("note text") %]`
2. **Perl Module**: `lib/Template/Plugin/Ovid.pm::add_note()` generates:
   - An inline `<span>` with class `open-dialog` and ID `open-dialog-N`
   - A `<div>` with class `dialog` and ID `dialog-N` containing the footnote
   - Stores footnote data in `$self->{footnotes}` array
3. **Footer Rendering**: `root/include/footer.tt` checks `Ovid.has_footnotes` and renders:
   - A `.dialog-overlay` div
   - All footnote dialog divs
   - Dialog.js library script
   - JavaScript initialization for each footnote's dialog behavior

### Old Implementation (pre-commit `0c0ca339`)

Before the JavaScript modal implementation:

1. `add_note()` generated `<sup>` tags with anchor links (e.g., `<sup id="1-return"><a href="#1">1</a></sup>`)
2. Footer rendered a "Footnotes" section with all footnotes as paragraphs
3. Each footnote had bidirectional anchor links: `<p id="1"><a href="#1-return">[1]</a> footnote text</p>`
4. No JavaScript dependency - pure HTML anchor navigation
5. This was wrapped in standard HTML rendering, not `<noscript>` tags

### Files Requiring Changes

- **lib/Template/Plugin/Ovid.pm**: Modify `add_note()` to generate both JS and noscript HTML
- **root/include/footer.tt**: Add noscript footnote section rendering
- **static/css/dialog.css** (or create new): Ensure dialog elements don't show when JS disabled
- **Test files**: Update `t/ovid_plugin.t` to test both rendering modes

### Historical Context

- Commit `0c0ca339`: Removed old footnote list rendering from footer, introduced Dialog.js modals
- Commit `926a38ae`: Removed support for named footnotes (only numbered footnotes now)
- Commit `1ce27622`: Added `note()` method as alias to `add_note()`

## Out of Scope *(informational)*

The following are explicitly **NOT** part of this specification:

- **Named footnotes**: The system used to support named footnotes (e.g., `[% Ovid.add_note('text', 'name') %]`), but this was removed in commit `926a38ae`. This spec maintains numbered-only footnotes.
- **Visual redesign**: The appearance of JavaScript modals should remain unchanged. Only noscript rendering is being added.
- **Footnote editing UI**: This is a static site; footnotes are defined in source templates only.
- **Dynamic footnote loading**: All footnote content is rendered at page build time.
- **Browser backward compatibility**: No need to support IE11 or older browsers; modern browsers only (last 2 major versions).
- **Progressive enhancement beyond noscript**: No need for intermediate states or feature detection; either JavaScript works or it doesn't.
- **Footnote search/filtering**: Not adding any search functionality for footnotes.
- **Analytics/tracking**: Not tracking whether users are using JS or noscript mode.

## Open Questions *(to be resolved)*

1. Should the noscript footnotes section use `<ol>` (ordered list), `<dl>` (definition list), or `<div>` with `<p>` elements?
   - **Recommendation**: Use `<ol>` for semantic meaning (ordered list of footnotes), with each footnote as an `<li id="footnote-N">`

2. Should the footnotes section in noscript mode be wrapped in a `<noscript>` tag, or should it always be rendered but hidden via CSS when JavaScript is enabled?
   - **Resolution**: Use `<noscript>` tags to wrap the footnotes list section. The JavaScript dialog elements should NOT be wrapped in `<noscript>` but should only be rendered conditionally when JavaScript is available (controlled by template logic). This provides clean separation: noscript content for no-JS users, dialog content for JS users.

3. What is the exact placement of the footnotes section? Before or after the pager?
   - **Recommendation**: After the article content but before the pager (navigation to previous/next articles), to keep footnotes as part of the article context.

4. Should the footnote icon in noscript mode be different from the JavaScript icon?
   - **Recommendation**: Keep the same clipboard icon for consistency, but the anchor behavior changes (no dialog, direct navigation).

5. How should we handle the Dialog.js initialization scripts in noscript mode?
   - **Recommendation**: Wrap all Dialog.js script tags and dialog initialization in a conditional that checks for `Ovid.has_footnotes`, which is already done. Ensure the `.dialog` and `.dialog-overlay` elements are hidden via CSS when noscript is active.

## Research Notes *(informational)*

### Git History Analysis

- **Commit 0c0ca339**: This commit shows the transition from the old footnote implementation to the current Dialog.js-based modal system
  - Removed: Footnote list rendering in `footer.tt`
  - Removed: `<sup>` anchor links generated by `add_note()`
  - Added: Dialog.js modal dialogs
  - Added: `.dialog` and `.dialog-overlay` CSS classes
  - Changed: Test expectations in `t/ovid_plugin.t`

### Current Bug Symptoms

Per the bug report:
- "When JS is disabled all footnotes are shown" - This suggests dialog HTML is being rendered but not properly hidden
- "Page overlay is active with no way of disabling" - The `.dialog-overlay` element is visible and blocking content
- "Page were readable without Reader mode or futzing around with DOM inspector" - The overlay makes normal reading impossible

### Technical Approach

The solution requires:
1. Dual rendering: Generate both JS modal HTML and noscript anchor HTML from `add_note()`
2. Conditional display: Use `<noscript>` tags and CSS to show only the appropriate version
3. Ensure Dialog.js scripts don't execute or don't affect page when JavaScript is disabled
4. Preserve accessibility in both modes

### Similar Implementations

Reference sites with noscript footnote handling:
- Wikipedia: Uses inline references with popups when available, fallback to anchor links
- Academic sites often use numbered superscripts with anchor navigation as baseline
- Ghost blogging platform: Similar footnote popup approach with anchor fallback
