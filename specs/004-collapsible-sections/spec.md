# Feature Specification: Collapsible Sections

**Feature Branch**: `004-collapsible-sections`  
**Created**: 2025-11-16  
**Status**: Draft  
**Input**: User description: "collapsible sections feature"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Basic Collapsible Content Display (Priority: P1)

Content authors can add collapsible sections to their articles that display a short description by default and expand to show full content when readers click to open them.

**Why this priority**: This is the core functionality - without it, the feature doesn't exist. It provides immediate value by allowing authors to hide supplementary content that might distract from the main article flow.

**Independent Test**: Can be fully tested by adding a single collapsible section to an article, verifying it displays collapsed by default showing the short description, expands on click to show full content, and collapses again on second click.

**Acceptance Scenarios**:

1. **Given** an article with a collapsible section, **When** a reader views the page, **Then** the section displays collapsed showing only the short description and a clickable expand icon
2. **Given** a collapsed section, **When** the reader clicks the expand icon, **Then** the section expands to reveal the full content
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

---

### User Story 4 - Multiple Sections Per Article (Priority: P2)

Content authors can add multiple independent collapsible sections to a single article, each operating independently.

**Why this priority**: While useful, a single collapsible section per article would still provide value. Multiple sections enhance flexibility.

**Independent Test**: Can be tested by adding 3 collapsible sections to one article and verifying each can be opened and closed independently without affecting the others.

**Acceptance Scenarios**:

1. **Given** an article with multiple collapsible sections, **When** a reader opens one section, **Then** the other sections remain in their current state (opened or closed)
2. **Given** multiple sections with different content, **When** the page renders, **Then** each section displays its own unique short description and full content

---

### Edge Cases

- What happens when the short description is very long (multiple paragraphs)?
- What happens when the full content is empty?
- What happens when the short description is empty?
- How does the feature behave with complex HTML in the full content (nested lists, images, code blocks)?
- What happens when a collapsible section contains another Template Toolkit plugin call (like footnotes or YouTube embeds)?
- How does screen reader navigation work with collapsed vs expanded states?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a Template Toolkit plugin method `Ovid.collapse(short_description, full_content)` that accepts two string parameters
- **FR-002**: System MUST render collapsible sections in a collapsed state by default when the page loads
- **FR-003**: System MUST display the short description text when a section is collapsed
- **FR-004**: System MUST provide a clickable icon or button to expand a collapsed section
- **FR-005**: System MUST reveal the full content when a user clicks to expand a section
- **FR-006**: System MUST provide a clickable icon or button to collapse an expanded section
- **FR-007**: System MUST hide the full content when a user clicks to collapse a section
- **FR-008**: System MUST process blogdown syntax within the full_content parameter
- **FR-009**: System MUST render collapsible sections at full width of the content area
- **FR-010**: System MUST support multiple independent collapsible sections within a single article
- **FR-011**: System MUST maintain the open/closed state of each section independently
- **FR-012**: System MUST provide appropriate ARIA attributes for accessibility (aria-expanded, role, aria-label)
- **FR-013**: System MUST be keyboard accessible (allow expand/collapse via keyboard navigation)

### Key Entities

- **Collapsible Section**: A content container with two states (collapsed/expanded), containing a short description (always visible) and full content (conditionally visible). Each section has a unique identifier within the page context.

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
