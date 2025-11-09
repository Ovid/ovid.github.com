# Implementation Plan: Footnote NoScript Fallback

**Branch**: `002-footnote-noscript-fallback` | **Date**: 2025-11-09 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/002-footnote-noscript-fallback/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Restore graceful degradation for footnotes when JavaScript is disabled, addressing critical accessibility bug where modal overlay blocks all content. Solution implements dual rendering: JavaScript-enabled users continue to see footnotes in modal dialogs (current behavior), while JavaScript-disabled users see traditional anchor-linked footnotes at article end (restored old behavior). This ensures full accessibility per constitution while maintaining modern UX for JS-enabled browsers.

## Technical Context

**Language/Version**: Perl 5.40+ (project standard per constitution)  
**Primary Dependencies**: Template Toolkit 2.x, Dialog.js (client-side for JS mode)  
**Storage**: N/A (static site generation, no database for this feature)  
**Testing**: Test::Most with 90%+ coverage requirement per constitution  
**Target Platform**: Static HTML5 websites, all modern browsers (Chrome, Firefox, Safari, Edge)  
**Project Type**: Static site generator (Perl-based with Template Toolkit templates)  
**Performance Goals**: <50ms additional processing per footnote (NFR-001), maintain <2 min total build time  
**Constraints**: Valid HTML5 output, WCAG 2.1 AA compliance, no JavaScript required for core content access  
**Scale/Scope**: Hundreds of existing articles with footnotes, typical articles have 1-10 footnotes

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### ✅ Principle I - CPAN-Style Module Architecture
**Status**: PASS  
**Justification**: Changes are to existing `Template::Plugin::Ovid` module which follows CPAN conventions. No new modules needed - this is a feature enhancement to existing module with proper POD documentation updates required.

### ✅ Principle II - CLI-First Interface Design
**Status**: PASS  
**Justification**: Static site generation workflow remains CLI-first via `bin/rebuild`. No new CLI interfaces needed for this feature.

### ✅ Principle III - Test::Most with 90%+ Coverage
**Status**: PASS  
**Justification**: Existing tests in `t/ovid_plugin.t` will be enhanced to test both JavaScript and noscript rendering modes. Coverage requirement will be met by adding test cases for:
- `add_note()` dual output generation
- Footer template noscript section rendering
- HTML output validation for both modes
Mock minimization: No mocks needed - testing pure HTML generation which is deterministic.

### ✅ Principle IV - Accessible HTML5 Static Output
**Status**: PASS  
**Justification**: This feature ENHANCES accessibility by fixing critical bug where JS-disabled users cannot read content. Implementation ensures:
- Valid HTML5 (will validate with Nu HTML Checker)
- WCAG 2.1 AA compliance (keyboard navigation, screen reader support)
- Semantic HTML (`<aside>` for footnotes section, `<ol>` for footnote list)
- No JavaScript required for core content (primary goal of this feature)

### ✅ Principle V - Zero External Service Dependencies
**Status**: PASS  
**Justification**: Feature uses only HTML/CSS/JavaScript in generated output. No external API calls, services, or CDNs. All assets are local.

### ✅ Principle VI - Production Data Protection
**Status**: PASS  
**Justification**: No database modifications. This is pure template/module code change. Tests will use test fixtures in `t/fixtures/` or in-memory test data, not production `db/` files.

### ✅ Principle VII - Modern Perl 5.40+ Features
**Status**: PASS  
**Justification**: Existing module uses `use Less::Boilerplate;` which enables modern Perl features. Code changes will use subroutine signatures (`sub add_note ( $self, $note )`), postfix dereferencing, and Type::Tiny where appropriate.

### ✅ Principle VIII - AI Agent Safety Constraints
**Status**: PASS  
**Justification**: No git operations required beyond normal commit workflow. No destructive operations needed.

**GATE STATUS**: ✅ ALL GATES PASSED - Proceed to Phase 0



## Project Structure

### Documentation (this feature)

```text
specs/002-footnote-noscript-fallback/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
└── Template/
    └── Plugin/
        └── Ovid.pm              # Modify: add_note() dual rendering

root/
└── include/
    └── footer.tt                # Modify: add noscript footnote section

static/
├── css/
│   └── dialog.css               # Modify/review: ensure dialogs hidden without JS
└── js/
    └── Dialog.js                # No changes (JavaScript-only)

t/
├── ovid_plugin.t                # Modify: add tests for both rendering modes
└── fixtures/
    └── test_footnotes.html      # Create: test fixture for validation

```

**Structure Decision**: Single project structure (default). This is a static site generator with clear separation:
- `lib/` contains Perl modules (Template Toolkit plugins)
- `root/` contains Template Toolkit templates
- `static/` contains CSS/JS assets
- `t/` contains tests mirroring lib/ structure per constitution

No frontend/backend split needed - this is template enhancement within existing monolithic static site generator architecture.




## Complexity Tracking

> **No violations to justify - all Constitution gates passed**

This feature aligns with all constitutional principles and requires no complexity exceptions.

---

## Phase 0: Research & Planning

### Research Tasks

1. **NoScript Tag Behavior Across Browsers**
   - **Question**: How do modern browsers (Chrome, Firefox, Safari, Edge) handle `<noscript>` tag content rendering and hiding?
   - **Goal**: Ensure cross-browser compatibility for footnote fallback
   - **Deliverable**: Browser compatibility matrix and recommended approach

2. **HTML5 Best Practices for Footnotes**
   - **Question**: What is the most semantic HTML5 structure for footnotes? `<aside>`, `<footer>`, `<section>` with `<ol>`, or definition lists?
   - **Goal**: Choose accessible, semantic markup for noscript footnote section
   - **Deliverable**: Recommended HTML structure with ARIA attributes

3. **CSS Strategies for Hiding JS-Dependent Elements**
   - **Question**: What's the best approach to ensure dialog overlays don't display when JS is disabled - `<noscript>` exclusion, CSS `display: none`, or JS-driven `data-` attributes?
   - **Goal**: Prevent visual interference from modal UI when JS disabled
   - **Deliverable**: CSS strategy and code examples

4. **Anchor Navigation and Focus Management**
   - **Question**: How to implement smooth anchor navigation that works with screen readers and keyboard-only users?
   - **Goal**: Ensure bidirectional footnote navigation is accessible
   - **Deliverable**: Anchor link patterns with ARIA labels

5. **Test Coverage for Dual Rendering Modes**
   - **Question**: How to test both JavaScript-enabled and JavaScript-disabled rendering in automated tests?
   - **Goal**: Achieve 90%+ coverage testing both modes
   - **Deliverable**: Testing strategy (may involve parsing generated HTML or template testing frameworks)

6. **Template Toolkit Conditional Rendering**
   - **Question**: What TT2 patterns best handle "if JS enabled render X, else render Y" logic?
   - **Goal**: Clean template code without duplication
   - **Deliverable**: TT2 patterns for dual rendering

### Research Output

**Output Location**: `specs/002-footnote-noscript-fallback/research.md`

Expected structure:
- Decision: [Chosen approach]
- Rationale: [Why chosen over alternatives]
- Alternatives Considered: [What else was evaluated]
- Code Examples: [Concrete implementation patterns]


---

## Phase 1: Design & Contracts

**Prerequisites**: `research.md` complete with all research tasks resolved

### Data Model

**Output Location**: `specs/002-footnote-noscript-fallback/data-model.md`

#### Entities

**Footnote** (in-memory data structure, not persisted)
- **Fields**:
  - `number`: Integer (auto-incremented, starting at 1)
  - `content`: String (HTML-safe footnote text)
  - `js_html`: String (generated HTML for JavaScript modal)
  - `noscript_html`: String (generated HTML for noscript anchor link list)
- **Relationships**: Footnotes belong to a single article/page rendering context
- **Validation**: 
  - `number` must be unique within article context
  - `content` must not be empty
  - Both HTML outputs must be valid HTML5 fragments
- **State Transitions**: 
  - Created via `add_note()` call in template
  - Stored in `$self->{footnotes}` array during template processing
  - Rendered once in footer template

**Template Context** (existing Template::Plugin::Ovid instance)
- **Fields**:
  - `footnote_number`: Integer (next footnote number to assign)
  - `footnotes`: ArrayRef[HashRef] (collection of footnote data)
- **Methods**:
  - `add_note($content)`: Create footnote, return inline HTML
  - `get_footnotes()`: Return array of footnotes for rendering
  - `has_footnotes()`: Boolean check for footer conditional

### API Contracts

**Note**: This is a static site generator - "API" here refers to the public interface of Perl modules and Template Toolkit methods.

**Output Location**: `specs/002-footnote-noscript-fallback/contracts/`

#### Contract 1: Template::Plugin::Ovid::add_note

**File**: `contracts/add_note_method.md`

```perl
# Method signature
sub add_note ( $self, $note )

# Input:
#   $note - String, HTML-safe footnote content
#
# Output:
#   String - HTML fragment for inline footnote marker
#
# Side Effects:
#   - Increments $self->{footnote_number}
#   - Pushes footnote data to $self->{footnotes} array
#
# Returns (example):
#   JavaScript-enabled browsers see:
#     <span aria-label="Open Footnote" class="open-dialog" id="open-dialog-1">
#       <i class="fa fa-clipboard fa_custom"></i>
#     </span>
#
#   JavaScript-disabled browsers see:
#     <a href="#footnote-1" id="footnote-1-return" aria-label="Footnote 1">
#       <i class="fa fa-clipboard fa_custom"></i>
#     </a>
#
# Error Conditions:
#   - Dies if $note is empty or undefined
```

#### Contract 2: Footer Template Footnote Section

**File**: `contracts/footer_footnote_rendering.md`

```tt2
# Template Toolkit block in root/include/footer.tt

# Condition: IF Ovid.has_footnotes

# JavaScript Mode (current behavior - unchanged):
#   Renders:
#     - <div class="dialog-overlay">
#     - For each footnote: <div class="dialog" id="dialog-N">
#     - Dialog.js initialization scripts
#
# NoScript Mode (new behavior):
#   Renders within <noscript> tag:
#     <aside class="footnotes" id="footnotes-section" aria-label="Footnotes">
#       <h2>Footnotes</h2>
#       <ol>
#         <li id="footnote-1">
#           [footnote content]
#           <a href="#footnote-1-return">↩ Return to text</a>
#         </li>
#       </ol>
#     </aside>
#
# Contract guarantees:
#   - Unique IDs for all footnotes (footnote-N, footnote-N-return)
#   - Bidirectional navigation (text ↔ footnote)
#   - Valid HTML5 output
#   - No visual overlap between JS and noscript modes
```

#### Contract 3: CSS Hiding Behavior

**File**: `contracts/css_display_rules.md`

```css
/* Ensure dialog elements are never visible when noscript is active */

/* These rules prevent dialog overlay from appearing when JS disabled */
.dialog-overlay,
.dialog {
  /* Only displayed when JavaScript initializes Dialog.js */
  /* Default hidden state if JS fails to load */
}

/* NoScript footnote section visible only when JS disabled */
noscript .footnotes {
  display: block;
}

/* Contract: 
   - Dialog elements must not interfere with noscript content
   - Screen readers must not encounter hidden dialog content when JS disabled
   - Visual order: noscript footnotes appear after article, before footer
*/
```

### Quickstart Guide

**Output Location**: `specs/002-footnote-noscript-fallback/quickstart.md`

```markdown
# Footnote NoScript Fallback - Developer Quickstart

## What This Feature Does

Fixes critical accessibility bug where footnotes are unreadable when JavaScript is disabled. Implements dual rendering so:
- **JavaScript ON**: Footnotes appear in modal popups (current behavior)
- **JavaScript OFF**: Footnotes appear as anchor-linked list at article end (restored behavior)

## Testing the Feature

### Test with JavaScript Enabled (Current Behavior)
1. Build site: `perl bin/rebuild`
2. Start local server: `http_this`
3. Open an article with footnotes in browser
4. Click clipboard icon - modal should appear
5. Press ESC or click overlay - modal closes

### Test with JavaScript Disabled (New Behavior)
1. Build site: `perl bin/rebuild`
2. Disable JavaScript in browser:
   - Chrome: DevTools → Settings → Debugger → Disable JavaScript
   - Firefox: about:config → javascript.enabled → false
3. Open same article
4. Verify:
   - No modal overlay blocks content ✅
   - "Footnotes" section appears at article end ✅
   - Clicking clipboard icon navigates to footnote ✅
   - "Return to text" link navigates back ✅

## Running Tests

```bash
# Activate Perl environment
source ~/.bash_profile

# Run all tests
prove -l t/

# Run only footnote plugin tests
prove -lv t/ovid_plugin.t

# Run with coverage
cover -test
```

## Files Modified

- `lib/Template/Plugin/Ovid.pm` - Dual rendering in add_note()
- `root/include/footer.tt` - Noscript footnote section
- `t/ovid_plugin.t` - Test coverage for both modes

## Quick Implementation Check

```perl
# In lib/Template/Plugin/Ovid.pm, add_note() should:
# 1. Generate JS modal HTML (existing)
# 2. Generate noscript anchor HTML (new)
# 3. Store both in footnotes array

# In root/include/footer.tt:
# - Existing: Render dialog-overlay and Dialog.js (JS mode)
# - New: Render <noscript> section with <ol> of footnotes
```
```

### Agent Context Update

After Phase 1 design completion, run:

```bash
.specify/scripts/bash/update-agent-context.sh copilot
```

This will:
- Update `.github/copilot-instructions.md`
- Add "Perl 5.40+ + Template Toolkit, Dialog.js, Test::Most" if not present
- Preserve manual additions between markers
- Document this feature's architectural decisions

---

## Phase 2: Task Planning

**Note**: Phase 2 task breakdown will be created by the `/speckit.tasks` command (NOT by `/speckit.plan`).

The tasks.md file will be generated in a separate step and will include:
- Granular implementation tasks
- Test creation tasks
- Documentation update tasks
- Validation and QA tasks

**Output Location**: `specs/002-footnote-noscript-fallback/tasks.md` (generated later)

---

## Next Steps

1. ✅ **Plan Complete** - This file documents the implementation approach
2. ⏭️ **Research Phase** - Fill `research.md` by investigating the 6 research tasks
3. ⏭️ **Design Phase** - Fill `data-model.md` and `contracts/` based on research findings
4. ⏭️ **Update Agent Context** - Run update-agent-context.sh script
5. ⏭️ **Task Creation** - Run `/speckit.tasks` to generate implementation task list
6. ⏭️ **Implementation** - Execute tasks from tasks.md
7. ⏭️ **Testing & Validation** - Ensure 90%+ coverage, HTML validation, accessibility checks

## Success Criteria Checklist

When implementation is complete, verify:

- [ ] JavaScript-enabled users see modal dialogs (unchanged behavior)
- [ ] JavaScript-disabled users see footnotes section at article end
- [ ] No modal overlay blocks content when JS disabled (bug fixed)
- [ ] Anchor navigation works bidirectionally (text ↔ footnote)
- [ ] All tests pass with 90%+ coverage
- [ ] HTML validates as HTML5
- [ ] Screen reader announces footnotes correctly in both modes
- [ ] Existing articles render correctly in both modes
- [ ] No performance regression (<50ms additional processing)

---

**Branch**: `002-footnote-noscript-fallback`  
**Plan Status**: Complete - Ready for Phase 0 Research  
**Next Command**: Begin research tasks or proceed directly to design if research is obvious
