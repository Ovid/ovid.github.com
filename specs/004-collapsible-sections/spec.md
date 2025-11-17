# Feature Specification: Collapsible Sections

**Feature Branch**: `004-collapsible-sections`  
**Created**: 2025-11-16  
**Status**: Draft  
**Input**: User description: "collapsible sections feature"

## Clarifications

### Session 2025-11-16

- Q: When a collapsible section is collapsed, what should be clickable to expand it? → A: The entire collapsed area is clickable (both icon and short description text)
- Q: Where should the expand/collapse icon be positioned relative to the short description? → A: Icon on the left side of the short description
- Q: How should the icon change between collapsed and expanded states? → A: Different icons for each state (e.g., chevron-down when collapsed, chevron-up when expanded)
- Q: When the short description parameter is empty or only whitespace, what should happen? → A: System should throw an error when the function is called and either parameter is empty
- Q: How should collapsible sections behave when JavaScript is disabled? → A: Display the entire content expanded and indented (no collapse functionality)
- Q: When multiple collapsible sections exist on a single page, how should they interact? → A: Each section operates completely independently - opening or closing one section must not affect the state of any other section

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Basic Collapsible Content Display (Priority: P1)

Content authors can add collapsible sections to their articles that display a short description by default and expand to show full content when readers click to open them.

**Why this priority**: This is the core functionality - without it, the feature doesn't exist. It provides immediate value by allowing authors to hide supplementary content that might distract from the main article flow.

**Independent Test**: Can be fully tested by adding a single collapsible section to an article, verifying it displays collapsed by default showing the short description, expands on click to show full content, and collapses again on second click.

**Acceptance Scenarios**:

1. **Given** an article with a collapsible section, **When** a reader views the page, **Then** the section displays collapsed showing only the short description and an expand icon
2. **Given** a collapsed section, **When** the reader clicks anywhere in the collapsed area (icon or short description text), **Then** the section expands to reveal the full content
3. **Given** an expanded section, **When** the reader clicks the collapse icon, **Then** the section collapses back to showing only the short description

---

### User Story 2 - Full-Width Visual Integration (Priority: P2)

Collapsible sections span the full width of the article content area and visually integrate with the existing article design to maintain a consistent reading experience.

**Why this priority**: Visual consistency is important for professional appearance and user trust, but the feature can function without perfect styling initially.

**Independent Test**: Can be tested by creating a collapsible section and verifying it spans the full width of the article content area and doesn't break the page layout.

**Acceptance Scenarios**:

1. **Given** an article with a collapsible section, **When** the page renders, **Then** the section spans the full width of the content area
2. **Given** multiple collapsible sections in an article, **When** the page renders, **Then** all sections maintain consistent styling and spacing

---

### User Story 3 - Template Syntax for Authors (Priority: P1)

Content authors can use a simple Template Toolkit syntax to create collapsible sections, similar to the existing footnote syntax.

**Why this priority**: Without an easy authoring interface, the feature cannot be used. This is core functionality.

**Independent Test**: Can be tested by writing the Template Toolkit syntax in an article template file and verifying it generates the correct HTML output when the site is built.

**Acceptance Scenarios**:

1. **Given** the Template Toolkit syntax `[% Ovid.collapse("summary", "details") %]`, **When** the site is built, **Then** a collapsible section is generated with "summary" as the short description and "details" as the full content
2. **Given** content with blogdown formatting in the full content parameter, **When** the site is built, **Then** the blogdown syntax is properly processed and rendered as HTML
3. **Given** the Template Toolkit syntax with empty short_description or full_content, **When** the site is built, **Then** the build process throws an error indicating which parameter is invalid

---

### User Story 4 - Multiple Sections Per Article (Priority: P2)

Content authors can add multiple independent collapsible sections to a single article, each operating independently.

**Why this priority**: While useful, a single collapsible section per article would still provide value. Multiple sections enhance flexibility.

**Independent Test**: Can be tested by adding 3 collapsible sections to one article and verifying each can be opened and closed independently without affecting the others.

**Acceptance Scenarios**:

1. **Given** an article with multiple collapsible sections, **When** a reader opens one section, **Then** the other sections remain in their current state (opened or closed)
2. **Given** multiple sections with different content, **When** the page renders, **Then** each section displays its own unique short description and full content

---

### User Story 5 - Non-JavaScript Fallback (Priority: P2)

Readers without JavaScript enabled can still access all content in collapsible sections, displayed in an expanded and indented format.

**Why this priority**: Accessibility and progressive enhancement are important, but most modern users have JavaScript enabled. This ensures content is never hidden from any user.

**Independent Test**: Can be tested by disabling JavaScript in the browser and verifying that collapsible sections display both short description and full content in an expanded, indented format.

**Acceptance Scenarios**:

1. **Given** a browser with JavaScript disabled, **When** a reader views a page with collapsible sections, **Then** all sections display in expanded form showing both short description and full content
2. **Given** non-JavaScript rendering, **When** the content displays, **Then** the full content appears indented to visually distinguish it from the short description

---

### Edge Cases

- What happens when the short description is very long (multiple paragraphs)?
- How does the feature behave with complex HTML in the full content (nested lists, images, code blocks)?
- What happens when a collapsible section contains another Template Toolkit plugin call (like footnotes or YouTube embeds)?
- How does screen reader navigation work with collapsed vs expanded states?
- How does the non-JavaScript fallback render when both short description and full content contain complex formatting?
- How does the system ensure that sections with similar or identical content remain isolated from each other?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a Template Toolkit plugin method `Ovid.collapse(short_description, full_content)` that accepts two string parameters
- **FR-001a**: System MUST throw an error during site build if either the short_description or full_content parameter is empty or contains only whitespace
- **FR-002**: System MUST render collapsible sections in a collapsed state by default when the page loads (JavaScript-enabled browsers only)
- **FR-003**: System MUST display the short description text when a section is collapsed
- **FR-004**: System MUST make the entire collapsed section area clickable (both icon and short description text) to expand the section
- **FR-004a**: System MUST display the expand/collapse icon on the left side of the short description
- **FR-004b**: System MUST display different icons for collapsed state (indicating expandability) versus expanded state (indicating collapsibility)
- **FR-005**: System MUST reveal the full content when a user clicks to expand a section
- **FR-006**: System MUST provide a clickable icon or button to collapse an expanded section
- **FR-007**: System MUST hide the full content when a user clicks to collapse a section
- **FR-008**: System MUST process blogdown syntax within the full_content parameter
- **FR-009**: System MUST render collapsible sections at full width of the content area
- **FR-010**: System MUST support multiple independent collapsible sections per article where each section maintains its own open/closed state without affecting other sections
- **FR-011**: System MUST provide appropriate ARIA attributes for accessibility including: `role="button"` (required), `aria-expanded="true"/"false"` (required), `aria-controls="{id}"` (required), `tabindex="0"` (required), and `aria-labelledby` (optional for enhanced screen reader context)
- **FR-012**: System MUST be keyboard accessible (allow expand/collapse via keyboard navigation)
- **FR-013**: System MUST provide a graceful degradation for non-JavaScript environments by displaying both short description and full content in an expanded, indented format

### Key Entities

- **Collapsible Section**: A content container with two states (collapsed/expanded), containing a short description (always visible) and full content (conditionally visible). Each section has a unique identifier within the page context to ensure independent operation when multiple sections exist on the same page.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Content authors can create a collapsible section using the Template Toolkit syntax in under 30 seconds
- **SC-002**: Readers can expand a collapsed section with a single click or keyboard action
- **SC-003**: Collapsible sections render correctly across all modern browsers (Chrome, Firefox, Safari, Edge)
- **SC-004**: Page load time increases by no more than 100ms when including 5 collapsible sections
- **SC-005**: Screen reader users can navigate and interact with collapsible sections successfully
- **SC-006**: Collapsible sections maintain visual consistency with existing article design elements

## Scope & Boundaries

### In Scope

- Template Toolkit plugin method for creating collapsible sections
- Basic expand/collapse interaction with icon indicators
- Support for blogdown syntax in full content
- Accessibility features (ARIA attributes, keyboard navigation)
- Visual styling consistent with existing site design
- Multiple independent sections per article

### Out of Scope

- Remembering collapsed/expanded state across page loads
- Animations or transitions (initially; can be added later for polish)
- Nested collapsible sections (sections within sections)
- Automatic collapsing of other sections when one is opened (accordion behavior)
- Search engine optimization considerations for collapsed content
- Deep linking to specific collapsible sections
- Table of contents integration

## Assumptions

- The existing `Template::Plugin::Ovid` module structure supports adding new methods similar to `add_note()`
- The site uses client-side JavaScript for interactive features (based on the existing footnote dialog implementation)
- Blogdown processing is already available and can be applied to content passed to the plugin
- The site's CSS framework allows for full-width elements within the content area
- Icon fonts (Font Awesome) are available for expand/collapse indicators, consistent with existing footnote icons
- Modern browser support only (no IE11 requirement)

## Dependencies

- Existing Template Toolkit infrastructure and `Template::Plugin::Ovid` module
- Blogdown processing capability for content formatting
- Client-side JavaScript for interactive expand/collapse behavior
- CSS styling system for visual presentation
- Icon font library (Font Awesome) for expand/collapse indicators
