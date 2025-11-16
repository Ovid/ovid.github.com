# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

This feature implements collapsible sections for articles, allowing authors to hide supplementary content that readers can reveal by clicking. The implementation extends the existing `Template::Plugin::Ovid` module with a new `collapse(short_description, full_content)` method, following the established pattern from the `add_note()` footnote functionality.

**Key Technical Decisions**:
- **Architecture**: Extend `Template::Plugin::Ovid` (follows Constitution Principle I - CPAN-Style Module Architecture)
- **Content Processing**: Apply blogdown to `full_content` parameter (Constitution Principle IX - Blogdown Content Format)
- **Progressive Enhancement**: JavaScript-enabled interactive mode + noscript fallback (Constitution Principle IV - Accessible HTML5)
- **State Management**: Instance counter for unique IDs (mirrors footnote implementation)
- **Styling**: Dedicated CSS file (`static/css/collapsible.css`) with full-width responsive design
- **JavaScript**: Vanilla JS module (`static/js/collapsible.js`) with zero external dependencies (Constitution Principle V)

**Implementation Components**:
1. Perl module extension: `Template::Plugin::Ovid.collapse()` method
2. CSS stylesheet: `static/css/collapsible.css` (progressive enhancement)
3. JavaScript module: `static/js/collapsible.js` (optional interaction layer)
4. Test suite: `t/template/plugin/ovid-collapse.t` with 90%+ coverage
5. Documentation: POD in module, quickstart guide for authors

## Technical Context

**Language/Version**: Perl 5.40+ (per Constitution Principle VII)  
**Primary Dependencies**: Template::Toolkit 3.102+, Text::Markdown::Blog (via Template::Plugin::Blogdown)  
**Storage**: N/A (static site generation, no runtime database for this feature)  
**Testing**: Test::Most 0.38+ with 90%+ coverage requirement (per Constitution Principle III)  
**Target Platform**: Static HTML output with progressive enhancement (JavaScript optional)  
**Project Type**: Static site generator module + client-side JavaScript enhancement  
**Performance Goals**: No measurable build time increase (<50ms per collapsible section during build)  
**Constraints**: Zero external service dependencies, accessible without JavaScript (Constitution Principles V & IV)  
**Scale/Scope**: Support unlimited collapsible sections per article, each independent

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I - CPAN-Style Module Architecture ✅
- **Status**: COMPLIANT
- **Implementation**: New method `collapse()` added to existing `Template::Plugin::Ovid` module
- **Rationale**: Extends existing plugin following same pattern as `add_note()` method

### Principle II - CLI-First Interface Design ✅
- **Status**: COMPLIANT (N/A)
- **Rationale**: Template plugin provides Template Toolkit interface; no CLI needed for this feature

### Principle III - Test::Most with 90%+ Coverage ⚠️
- **Status**: MUST VERIFY
- **Requirement**: All new code must achieve 90%+ test coverage
- **Tests needed**: 
  - Unit tests for `collapse()` method with various inputs
  - Edge cases: empty parameters, blogdown syntax processing, multiple sections
  - Integration tests for noscript rendering
  - Template rendering tests

### Principle IV - Accessible HTML5 Static Output ⚠️
- **Status**: MUST VERIFY
- **Requirements checklist**:
  - Valid HTML5 markup (expandable sections)
  - WCAG 2.1 Level AA compliance (ARIA attributes required)
  - Keyboard navigation (expand/collapse via keyboard)
  - No JavaScript required for core content access (noscript fallback)
  - Semantic HTML elements

### Principle V - Zero External Service Dependencies ✅
- **Status**: COMPLIANT
- **Verification**: Feature uses only local Template processing and client-side JavaScript

### Principle VI - Production Data Protection ✅
- **Status**: COMPLIANT
- **Verification**: Tests will use fixtures in `t/fixtures/`, no database modifications needed

### Principle VII - Modern Perl 5.40+ Features ⚠️
- **Status**: MUST VERIFY
- **Requirements**:
  - Use `use v5.40;` in any new modules
  - Subroutine signatures for `collapse()` method
  - Follow existing pattern in `Template::Plugin::Ovid`

### Principle VIII - AI Agent Safety ✅
- **Status**: COMPLIANT (N/A)
- **Rationale**: No destructive git operations required for this feature

### Principle IX - Blogdown Content Format ⚠️
- **Status**: MUST VERIFY
- **Requirement**: `collapse()` method must process blogdown syntax in `full_content` parameter
- **Implementation**: Must apply blogdown processing similar to main article content

### Gate Status: CONDITIONAL PASS
All ⚠️ items will be resolved during implementation and verified in Phase 1 design.

---

## Post-Design Constitution Re-Evaluation

**Re-check Date**: 2025-11-16 (after Phase 1 design complete)

### Principle III - Test::Most with 90%+ Coverage ✅
- **Status**: DESIGN COMPLIANT
- **Design includes**:
  - Unit tests in `t/template/plugin/ovid-collapse.t`
  - Test fixtures in `t/fixtures/collapsible-sections/`
  - Edge case coverage (empty params, blogdown processing, multiple sections)
  - Integration tests for noscript rendering
  - Contract specifies comprehensive test requirements

### Principle IV - Accessible HTML5 Static Output ✅
- **Status**: DESIGN COMPLIANT
- **Design includes**:
  - Full ARIA attribute specification (aria-expanded, aria-controls, aria-labelledby, role)
  - Keyboard navigation support (Tab, Enter, Space)
  - Noscript fallback with indented content
  - Semantic HTML structure
  - WCAG 2.1 Level AA color contrast requirements
  - Print styles (all content visible when printed)
  - High contrast mode support
  - Reduced motion support

### Principle VII - Modern Perl 5.40+ Features ✅
- **Status**: DESIGN COMPLIANT
- **Design includes**:
  - Subroutine signatures: `sub collapse ( $self, $short_description, $full_content )`
  - Error handling with `croak()` (best practice)
  - Follows existing module patterns in `Template::Plugin::Ovid`

### Principle IX - Blogdown Content Format ✅
- **Status**: DESIGN COMPLIANT
- **Design includes**:
  - Explicit blogdown processing via `Template::Plugin::Blogdown->filter()`
  - Applied to `full_content` parameter before HTML generation
  - Supports all blogdown features (code blocks, tables, smart quotes, external links)
  - Tested with complex blogdown syntax in test fixtures

### Final Gate Status: ✅ FULL PASS

All constitution principles are satisfied by the design. Implementation can proceed with confidence that the architecture aligns with project standards.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
# Static site generator (Perl + Template Toolkit)
lib/
├── Template/
│   └── Plugin/
│       └── Ovid.pm                 # MODIFY: Add collapse() method

t/
├── template/
│   └── plugin/
│       └── ovid-collapse.t         # CREATE: Tests for collapse() method
└── fixtures/
    └── collapsible-sections/       # CREATE: Test fixtures
        ├── basic.tt                # Single collapsible section
        ├── multiple.tt             # Multiple sections
        ├── blogdown-content.tt     # Complex blogdown in content
        └── expected/               # Expected HTML output
            ├── basic.html
            ├── multiple.html
            └── blogdown-content.html

static/
├── css/
│   └── collapsible.css             # CREATE: Styling for collapsible sections
└── js/
    └── collapsible.js              # CREATE: JavaScript for expand/collapse behavior

include/
└── wrapper.html                    # POSSIBLY MODIFY: May need to include collapsible.js/css

# Generated content - DO NOT MODIFY in feature tasks:
# articles/, blog/, tags/         : Generated HTML
# db/                             : Production databases
# tmp/, cover_db/                 : Build artifacts
```

**Structure Decision**: 
- **lib/Template/Plugin/Ovid.pm**: Add `collapse($short_description, $full_content)` method following the pattern of `add_note()`
- **t/template/plugin/ovid-collapse.t**: Comprehensive test suite for the new method
- **t/fixtures/collapsible-sections/**: Template fixtures and expected HTML for testing
- **static/css/collapsible.css**: Styles for collapsed/expanded states, noscript fallback
- **static/js/collapsible.js**: Client-side JavaScript for interactive expand/collapse
- **include/wrapper.html**: May need modification to include new CSS/JS files (TBD in research phase)

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
