# Implementation Plan: Collapsible Sections

**Branch**: `004-collapsible-sections` | **Date**: 2025-11-16 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/004-collapsible-sections/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Add a Template Toolkit plugin method `Ovid.collapse(short_description, full_content)` to create collapsible sections in articles. Sections display collapsed by default (JavaScript-enabled), expand on click to show full content, and support blogdown formatting. Multiple sections per page operate independently with unique identifiers. Progressive enhancement ensures content accessibility when JavaScript is disabled (expanded, indented format).

## Technical Context

**Language/Version**: Perl 5.40+ (per Constitution Principle VII)  
**Primary Dependencies**: Template::Toolkit 3.102+, Text::Markdown::Blog (via Template::Plugin::Blogdown)  
**Storage**: N/A (static site generation, no runtime database for this feature)  
**Testing**: Test::Most (per Constitution Principle III, 90%+ coverage required)  
**Target Platform**: Static HTML5 output for modern browsers (Chrome, Firefox, Safari, Edge)  
**Project Type**: Static site generator - Template Toolkit plugin extension  
**Performance Goals**: <100ms page load impact for 5 collapsible sections, <30 seconds authoring time  
**Constraints**: Zero external dependencies (Constitution Principle V), WCAG 2.1 AA compliance, keyboard accessible  
**Scale/Scope**: Multiple independent sections per article, blogdown content processing, progressive enhancement (no-JS fallback)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: CPAN-Style Module Architecture ✅
- **Status**: COMPLIANT
- **Approach**: Extend existing `Template::Plugin::Ovid` module with new `collapse()` method, following same pattern as `add_note()`
- **Namespace**: `Template::Plugin::Ovid` (already established)
- **Documentation**: POD with NAME, SYNOPSIS, DESCRIPTION, METHODS
- **Dependencies**: Declared in `cpanfile` (Template::Toolkit already present, Text::Markdown::Blog via Blogdown)

### Principle II: CLI-First Interface Design ✅
- **Status**: COMPLIANT
- **Approach**: Template Toolkit plugin accessible via `[% Ovid.collapse(...) %]` syntax in templates, processed during `bin/rebuild` execution
- **CLI Tool**: Existing `bin/rebuild` script handles site generation
- **No new CLI needed**: Feature integrates into existing build workflow

### Principle III: Test::Most with 90%+ Coverage ✅
- **Status**: COMPLIANT - MUST ACHIEVE
- **Testing Strategy**:
  - Unit tests for `collapse()` method in `t/template_plugin_ovid.t`
  - Test parameter validation (empty/whitespace detection)
  - Test HTML output generation (collapsed state markup)
  - Test unique ID generation for multiple sections
  - Test blogdown processing integration
  - Test no-JavaScript fallback rendering
  - Integration test: full article build with multiple collapsible sections
- **Mock Minimization**: Use real Template::Toolkit and blogdown processor; only mock if file I/O becomes performance bottleneck in tests
- **Coverage Target**: 90%+ via Devel::Cover

### Principle IV: Accessible HTML5 Static Output ✅
- **Status**: COMPLIANT - CRITICAL REQUIREMENT
- **Accessibility Features**:
  - ARIA attributes: `aria-expanded`, `role="button"`, `aria-label`
  - Keyboard navigation: Enter/Space to toggle collapse state
  - Semantic HTML: `<div>` with appropriate ARIA, `<button>` or clickable region
  - No JavaScript required for content access (progressive enhancement)
  - Screen reader announcements for state changes
- **Validation**: Test with NVDA/JAWS, keyboard-only navigation, W3C validator

### Principle V: Zero External Service Dependencies ✅
- **Status**: COMPLIANT
- **Approach**: 
  - All assets (CSS, JavaScript) served locally from `static/`
  - No CDN dependencies (use local Font Awesome if icons needed)
  - Build-time processing only, no runtime API calls
  - Static HTML generation

### Principle VI: Production Data Protection ✅
- **Status**: COMPLIANT
- **Approach**:
  - Tests use fixtures in `t/fixtures/` directory
  - No modification of `db/` directory during tests
  - Read-only access to production data if needed for integration tests
  - Use File::Temp for temporary test outputs

### Principle VII: Modern Perl 5.40+ Features Preferred ✅
- **Status**: COMPLIANT
- **Code Style**:
  - `use v5.40;` at top of all modules
  - Subroutine signatures: `sub collapse ($self, $short_desc, $full_content)`
  - Postfix dereferencing where applicable
  - Type::Tiny for parameter validation if complex types needed
  - No legacy syntax (indirect object notation, bareword filehandles)

### Principle VIII: AI Agent Safety Constraints ✅
- **Status**: COMPLIANT - INFORMATIONAL
- **Note**: No destructive git operations planned; all work on feature branch `004-collapsible-sections`

### Principle IX: Blogdown Content Format ✅
- **Status**: COMPLIANT - CRITICAL INTEGRATION
- **Approach**:
  - Full content parameter supports blogdown Markdown syntax
  - Process `full_content` through existing blogdown pipeline
  - Preserve TT directives within collapsed content (nested plugins like footnotes)
  - Template usage: `[% Ovid.collapse("Summary here", "~~~perl\ncode\n~~~") %]`

### Quality Standards Check ✅

**Code Organization**:
- Module: Extend `lib/Template/Plugin/Ovid.pm`
- Tests: Add to existing `t/template_plugin_ovid.t`
- Static assets: JavaScript in `static/js/`, CSS in `css/`
- Templates: Integration tests use `t/fixtures/test-article.tt2markdown`

**Documentation Requirements**:
- POD for `collapse()` method with examples
- Parameter descriptions (short_description, full_content)
- Error conditions documented
- Usage examples in SYNOPSIS

**Performance Expectations**:
- Minimal build time impact (<100ms for 5 sections per spec)
- No memory leaks from repeated section generation
- HTML output minification compatible

**Development Scope Boundaries** ✅:
- **MODIFY**: `lib/Template/Plugin/Ovid.pm` (add `collapse()` method)
- **CREATE**: `static/js/collapsible.js` (client-side toggle behavior)
- **CREATE**: `static/css/collapsible.css` (section styling)
- **CREATE**: `t/template/plugin/ovid-collapse.t` (unit tests for new functionality)
- **DO NOT MODIFY**: `articles/`, `blog/`, `db/`, `tmp/`, generated content

### Summary: ALL GATES PASSED ✅

No violations. Feature fully compliant with constitution.

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
└── Template/
    └── Plugin/
        └── Ovid.pm          # MODIFY: Add collapse() method

bin/
└── rebuild                   # Existing CLI (no changes needed)

root/
└── [no changes to templates] # Feature is plugin-based, used via [% Ovid.collapse() %]

static/
├── js/
│   └── collapsible.js        # CREATE: Client-side expand/collapse logic
└── css/
    └── collapsible.css       # CREATE: Styling for collapsible sections

t/
├── template/
│   └── plugin/
│       └── ovid-collapse.t   # CREATE: Unit tests for collapse() method
└── fixtures/
    └── test-collapsible.tt2markdown  # CREATE: Integration test fixture

# Generated content - DO NOT MODIFY:
# articles/, blog/, tags/     : Generated HTML
# db/                         : Production databases
# tmp/, cover_db/             : Build artifacts
```

**Structure Decision**: 
- Extend `Template::Plugin::Ovid` with `collapse()` method (similar to `add_note()` pattern)
- Create standalone JavaScript file at `static/js/collapsible.js` for progressive enhancement
- Create separate CSS file at `static/css/collapsible.css` for section styling
- Tests in `t/template/plugin/ovid-collapse.t` mirror existing `add_note()` test patterns

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations found. This section is not applicable.

---

## Planning Status

**Status**: ✅ COMPLETE  
**Date Completed**: 2025-11-16  
**Next Phase**: Implementation tasks (use `/speckit.tasks` command)

### Completed Phases

#### Phase 0: Research ✅
- **Output**: `research.md`
- **Status**: All technical unknowns resolved
- **Key Decisions**:
  - Auto-incrementing counter for unique section IDs
  - Template::Plugin::Blogdown for content processing
  - WAI-ARIA Disclosure Pattern for accessibility
  - Event delegation for JavaScript interactions
  - No-JS fallback with duplicate HTML blocks

#### Phase 1: Design & Contracts ✅
- **Outputs**:
  - `data-model.md` - Entity structure and state management
  - `quickstart.md` - Author-facing documentation
  - `contracts/perl-api.md` - `collapse()` method contract
  - `contracts/javascript-api.md` - Client-side API specification
  - `contracts/css-contract.md` - Styling requirements
- **Status**: All design artifacts complete
- **Agent Context**: GitHub Copilot context updated with new technologies

### Artifacts Summary

| Artifact | Status | Purpose |
|----------|--------|---------|
| `spec.md` | ✅ Complete | Feature specification with clarifications |
| `plan.md` | ✅ Complete | This implementation plan |
| `research.md` | ✅ Complete | Technical research and decisions |
| `data-model.md` | ✅ Complete | Entity definitions and validation |
| `quickstart.md` | ✅ Complete | Author documentation |
| `contracts/perl-api.md` | ✅ Complete | Perl API contract |
| `contracts/javascript-api.md` | ✅ Complete | JavaScript API contract |
| `contracts/css-contract.md` | ✅ Complete | CSS styling contract |
| `tasks.md` | ⏳ Pending | Use `/speckit.tasks` to generate |

### Ready for Implementation

All planning phases complete. Feature is ready for task breakdown and implementation.

**Constitution Re-check**: ✅ All gates still passed after design phase

**Next Steps**:
1. Run `/speckit.tasks` to break down implementation into actionable tasks
2. Begin implementation following task priorities
3. Maintain 90%+ test coverage throughout development
4. Validate accessibility with screen readers and keyboard navigation
