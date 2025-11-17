---

description: "Task list for collapsible sections feature implementation"
---

# Tasks: Collapsible Sections

**Input**: Design documents from `/specs/004-collapsible-sections/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Tests are explicitly requested in this feature specification and follow TDD approach.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [X] T001 [P] Create test fixtures directory at `t/fixtures/collapsible-sections/`
- [X] T002 [P] Create CSS file `static/css/collapsible.css` with base structure (comments only)
- [X] T003 [P] Create JavaScript file `static/js/collapsible.js` with module skeleton (comments only)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 Add collapsible section counter instance variable to `lib/Template/Plugin/Ovid.pm` initialization
- [X] T005 Create test file `t/template/plugin/ovid-collapse.t` with Test::Most setup and basic structure

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Basic Collapsible Content Display (Priority: P1) 🎯 MVP

**Goal**: Content authors can add collapsible sections that display a short description by default and expand to show full content when clicked.

**Independent Test**: Add a single collapsible section to an article template, verify it displays collapsed with short description, expands on click to show full content, and collapses on second click.

### Tests for User Story 1 (TDD - Write FIRST, ensure FAIL before implementation)

- [X] T006 [P] [US1] Add parameter validation tests to `t/template/plugin/ovid-collapse.t` (empty short_description, empty full_content, undefined parameters)
- [X] T007 [P] [US1] Add basic collapse() method invocation test to `t/template/plugin/ovid-collapse.t` (returns HTML string)
- [X] T008 [P] [US1] Add HTML structure test to `t/template/plugin/ovid-collapse.t` (verify div.collapsible-section exists)
- [X] T009 [P] [US1] Add unique ID generation test to `t/template/plugin/ovid-collapse.t` (multiple calls produce sequential IDs)
- [X] T010 [P] [US1] Create test fixture `t/fixtures/collapsible-sections/basic.tt` with single collapsible section template
- [X] T011 [P] [US1] Create expected output `t/fixtures/collapsible-sections/expected/basic.html` with complete HTML structure
- [X] T012 [US1] Add fixture-based integration test to `t/template/plugin/ovid-collapse.t` (render basic.tt, compare to expected/basic.html)

### Implementation for User Story 1

- [X] T013 [US1] Implement `collapse()` method signature with parameter validation in `lib/Template/Plugin/Ovid.pm` (croak on empty/undefined params)
- [X] T014 [US1] Implement collapsible section counter increment in `collapse()` method in `lib/Template/Plugin/Ovid.pm`
- [X] T015 [US1] Implement unique ID generation (trigger and content IDs) in `collapse()` method in `lib/Template/Plugin/Ovid.pm`
- [X] T016 [US1] Implement basic HTML structure generation (container, trigger div, content div) in `collapse()` method in `lib/Template/Plugin/Ovid.pm`
- [X] T017 [US1] Add ARIA attributes to HTML output (role, tabindex, aria-expanded, aria-controls, aria-labelledby) in `collapse()` method in `lib/Template/Plugin/Ovid.pm`
- [X] T018 [US1] Add Font Awesome chevron-down icon to trigger element in `collapse()` method in `lib/Template/Plugin/Ovid.pm`
- [X] T019 [US1] Implement noscript fallback HTML structure in `collapse()` method in `lib/Template/Plugin/Ovid.pm`
- [X] T020 [US1] Verify all US1 tests pass (run `prove -l t/template/plugin/ovid-collapse.t`)

**Checkpoint**: At this point, User Story 1 Perl API should be fully functional and testable independently

---

## Phase 4: User Story 2 - Full-Width Visual Integration (Priority: P2)

**Goal**: Collapsible sections span the full width of the article content area and visually integrate with existing article design.

**Independent Test**: Create a collapsible section and verify it spans full width of content area without breaking layout.

### Tests for User Story 2 (TDD)

- [ ] T021 [P] [US2] Add CSS selector tests to `t/template/plugin/ovid-collapse.t` (verify .collapsible-section class exists in output)
- [ ] T022 [P] [US2] Add CSS class verification tests to `t/template/plugin/ovid-collapse.t` (trigger, icon, content classes present)

### Implementation for User Story 2

- [ ] T023 [P] [US2] Implement base section container styles in `static/css/collapsible.css` (full width, margin, border, border-radius)
- [ ] T024 [P] [US2] Implement trigger styles in `static/css/collapsible.css` (flexbox layout, padding, cursor, background)
- [ ] T025 [P] [US2] Implement icon positioning styles in `static/css/collapsible.css` (margin-right, color, font-size)
- [ ] T026 [P] [US2] Implement short description text styles in `static/css/collapsible.css` (flex: 1, font-weight, color)
- [ ] T027 [P] [US2] Implement collapsed content state in `static/css/collapsible.css` (display: none, border-top, padding)
- [ ] T028 [P] [US2] Implement expanded content state in `static/css/collapsible.css` (.expanded class with display: block)
- [ ] T029 [P] [US2] Implement hover state styles in `static/css/collapsible.css` (.collapsible-trigger:hover)
- [ ] T030 [P] [US2] Implement focus state styles for accessibility in `static/css/collapsible.css` (outline, outline-offset per WCAG 2.1 AA)
- [ ] T031 [US2] Add responsive media query for mobile in `static/css/collapsible.css` (@media max-width: 550px)
- [ ] T032 [US2] Verify CSS meets WCAG 2.1 Level AA contrast requirements (manual check or automated tool)

**Checkpoint**: At this point, User Stories 1 AND 2 should both work - Perl generates proper HTML with full styling

---

## Phase 5: User Story 3 - Template Syntax for Authors (Priority: P1)

**Goal**: Content authors can use simple Template Toolkit syntax `[% Ovid.collapse("summary", "details") %]` with blogdown support.

**Independent Test**: Write Template Toolkit syntax in article template, build site, verify correct HTML generation with blogdown processing.

### Tests for User Story 3 (TDD)

- [ ] T033 [P] [US3] Add blogdown processing test to `t/template/plugin/ovid-collapse.t` (full_content with Markdown code blocks)
- [ ] T034 [P] [US3] Create test fixture `t/fixtures/collapsible-sections/blogdown-content.tt` with complex blogdown syntax (code blocks, lists, links)
- [ ] T035 [P] [US3] Create expected output `t/fixtures/collapsible-sections/expected/blogdown-content.html` with processed blogdown HTML
- [ ] T036 [US3] Add blogdown integration test to `t/template/plugin/ovid-collapse.t` (render blogdown-content.tt, verify code highlighting)

### Implementation for User Story 3

- [ ] T037 [US3] Add Template::Plugin::Blogdown import to `lib/Template/Plugin/Ovid.pm` (if not already present)
- [ ] T038 [US3] Implement blogdown processing in `collapse()` method in `lib/Template/Plugin/Ovid.pm` (filter full_content through blogdown)
- [ ] T039 [US3] Test edge case: nested TT directives in full_content (e.g., Ovid.add_note() inside collapsible)
- [ ] T040 [US3] Verify all US3 tests pass (run `prove -l t/template/plugin/ovid-collapse.t`)

**Checkpoint**: At this point, User Stories 1, 2, AND 3 should all work - full authoring capability with rich formatting

---

## Phase 6: User Story 4 - Multiple Sections Per Article (Priority: P2)

**Goal**: Content authors can add multiple independent collapsible sections to a single article, each operating independently.

**CRITICAL REQUIREMENT**: Multiple collapsible sections must be completely independent. Opening or closing one section MUST NOT affect the state of any other section on the page. Each section must have its own unique identifiers and maintain its own state.

**Independent Test**: Add 3 collapsible sections to one article, verify each opens/closes independently without affecting other sections.

### Tests for User Story 4 (TDD)

- [ ] T041 [P] [US4] Create test fixture `t/fixtures/collapsible-sections/multiple.tt` with 3 collapsible sections
- [ ] T042 [P] [US4] Create expected output `t/fixtures/collapsible-sections/expected/multiple.html` with 3 independent sections (each with unique IDs)
- [ ] T043 [US4] Add multiple sections test to `t/template/plugin/ovid-collapse.t` (verify unique IDs: collapsible-trigger-1, -2, -3)
- [ ] T044 [US4] Add independence test to `t/template/plugin/ovid-collapse.t` (verify each section has distinct trigger ID, content ID, and aria-controls linking)
- [ ] T044a [US4] Add test for no shared state between sections in `t/template/plugin/ovid-collapse.t` (verify no global CSS classes or data attributes that could cause interference)

### Implementation for User Story 4

- [ ] T045 [US4] Verify counter increments correctly across multiple collapse() calls in `lib/Template/Plugin/Ovid.pm` (already implemented in T014, validate uniqueness)
- [ ] T045a [US4] Verify each section generates completely unique IDs (trigger ID, content ID) with no possibility of collision in `lib/Template/Plugin/Ovid.pm`
- [ ] T045b [US4] Verify aria-controls attributes correctly link each trigger to its own content (not to other sections) in `lib/Template/Plugin/Ovid.pm`
- [ ] T046 [US4] Document JavaScript isolation requirement: each event handler must only toggle its own section (implement in Phase 8)
- [ ] T047 [US4] Verify all US4 tests pass (run `prove -l t/template/plugin/ovid-collapse.t`)
- [ ] T047a [US4] Add test for duplicate content independence (two sections with identical short_description and full_content must still have unique IDs) in `t/template/plugin/ovid-collapse.t`

**Checkpoint**: All user stories except US5 (noscript) should now be independently functional. CRITICAL: Multiple sections on same page must operate in complete isolation.

---

## Phase 7: User Story 5 - Non-JavaScript Fallback (Priority: P2)

**Goal**: Readers without JavaScript can still access all content, displayed expanded and indented.

**Independent Test**: Disable JavaScript in browser, verify collapsible sections display both short description and full content in expanded, indented format.

### Tests for User Story 5 (TDD)

- [X] T048 [P] [US5] Add noscript HTML structure test to `t/template/plugin/ovid-collapse.t` (verify <noscript> tag present)
- [X] T049 [P] [US5] Add noscript content test to `t/template/plugin/ovid-collapse.t` (verify both short and full content in noscript)
- [X] T050 [US5] Add noscript CSS class test to `t/template/plugin/ovid-collapse.t` (.collapsible-section-noscript, .collapsible-short-noscript, .collapsible-content-noscript)

### Implementation for User Story 5

- [X] T051 [US5] Verify noscript HTML generation in `lib/Template/Plugin/Ovid.pm` (already implemented in T019, validate)
- [ ] T052 [P] [US5] Implement noscript container styles in `static/css/collapsible.css` (border, padding, background)
- [X] T053 [P] [US5] Implement noscript short description styles in `static/css/collapsible.css` (font-weight, margin-bottom)
- [X] T054 [US5] Implement noscript content indentation styles in `static/css/collapsible.css` (margin-left: 2em, border-left, padding-left per spec)
- [X] T055 [US5] Verify all US5 tests pass (run `prove -l t/template/plugin/ovid-collapse.t`)

**Checkpoint**: All 5 user stories should now be complete with noscript fallback working

---

## Phase 8: JavaScript Interactive Behavior (Cross-Cutting)

**Goal**: Implement client-side JavaScript for expand/collapse interaction (affects US1, US4).

**CRITICAL INDEPENDENCE REQUIREMENT**: JavaScript must ensure complete independence between sections. Each click handler must ONLY affect its own section, never other sections. No global state should be shared between sections.

**Independent Test**: Open page with multiple collapsible sections, click different triggers, verify each section expands/collapses independently without affecting others.

### Tests for JavaScript (Manual - browser-based)

- [ ] T056 Document manual test procedure in `specs/004-collapsible-sections/quickstart.md` (single section test, multiple sections independence test, keyboard test, screen reader test)
- [ ] T056a Document independence validation test: open 3 sections in sequence, verify states don't interfere with each other

### Implementation for JavaScript

- [ ] T057 [P] Implement DOMContentLoaded event listener in `static/js/collapsible.js`
- [ ] T058 [P] Implement querySelectorAll to find all .collapsible-trigger elements in `static/js/collapsible.js`
- [ ] T059 Implement toggleCollapsible() function in `static/js/collapsible.js` (receives specific trigger element, NOT global state)
- [ ] T059a Ensure toggleCollapsible() uses the trigger element's aria-controls to find its specific content (NOT a global selector)
- [ ] T060 Implement aria-expanded attribute toggling in toggleCollapsible() in `static/js/collapsible.js` (only on the specific trigger passed)
- [ ] T061 Implement .expanded class toggling on content element in toggleCollapsible() in `static/js/collapsible.js` (only on the content linked via aria-controls)
- [ ] T062 Implement icon class swapping (fa-chevron-down ↔ fa-chevron-up) in toggleCollapsible() in `static/js/collapsible.js` (only within the specific trigger element)
- [ ] T063 Implement click event listener attachment in `static/js/collapsible.js` (attach to each trigger individually, NOT delegated from parent)
- [ ] T064 Implement keydown event listener for Enter and Space keys in `static/js/collapsible.js` (attach to each trigger individually)
- [ ] T065 Add error handling for missing content elements in `static/js/collapsible.js` (console.warn if aria-controls points to non-existent element)
- [ ] T065a Add validation that each trigger's aria-controls points to exactly one element (warn if multiple or zero matches)
- [ ] T066 Test JavaScript in Chrome, Firefox, Safari, Edge with multiple sections (manual cross-browser testing - verify independence)

**Checkpoint**: Full interactive behavior complete, accessible via mouse and keyboard. VERIFIED: Multiple sections operate independently.

---

## Phase 9: Integration & Wrapper Template

**Goal**: Ensure collapsible.css and collapsible.js are loaded in article pages.

### Implementation for Integration

- [ ] T067 Verify if `root/include/wrapper.tt` needs modification to include `static/css/collapsible.css` (check existing CSS inclusion pattern)
- [ ] T068 Verify if `root/include/wrapper.tt` needs modification to include `static/js/collapsible.js` (check existing JS inclusion pattern)
- [ ] T069 If needed, add `<link rel="stylesheet" href="/static/css/collapsible.css">` to `root/include/wrapper.tt`
- [ ] T070 If needed, add `<script src="/static/js/collapsible.js"></script>` to `root/include/wrapper.tt` (before closing </body>)

**Checkpoint**: CSS and JS properly loaded on all article pages

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements, documentation, and validation

- [ ] T071 [P] Add POD documentation for `collapse()` method in `lib/Template/Plugin/Ovid.pm` (parameters, return value, examples)
- [ ] T072 [P] Update `specs/004-collapsible-sections/quickstart.md` with final examples (if not already complete)
- [ ] T073 Run full test suite with coverage: `cover -test -report html -outputdir coverage-report`
- [ ] T074 Verify 90%+ test coverage for new code (check `coverage-report/lib-Template-Plugin-Ovid-pm.html`)
- [ ] T075 Run perltidy on modified Perl files: `perltidy --profile=.perltidyrc lib/Template/Plugin/Ovid.pm t/template/plugin/ovid-collapse.t`
- [ ] T076 Run full site rebuild: `perl bin/rebuild`
- [ ] T077 Verify no build errors or warnings in `errors.err`
- [ ] T078 Create sample article demonstrating collapsible sections feature with multiple independent sections (optional, for documentation)
- [ ] T079 Add accessibility validation: WAVE tool or axe DevTools on generated page (manual check)
- [ ] T080 Validate HTML5 compliance: W3C Validator on generated article page (manual check)
- [ ] T081 Test print styles: verify all collapsible content visible when printing (manual check)
- [ ] T082 Test high contrast mode: verify collapsible sections readable in Windows High Contrast (manual check)
- [ ] T083 Test reduced motion: verify no animations for users with prefers-reduced-motion (CSS check)
- [ ] T084 Run quickstart.md validation scenarios (test all examples in quickstart guide)
- [ ] T085 **Independence Validation**: Test page with 5+ collapsible sections - verify opening/closing one never affects others (manual test with various browsers)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - US1 (Phase 3): Can start after Foundational - No dependencies
  - US2 (Phase 4): Can start after Foundational - No dependencies on US1 (CSS is independent)
  - US3 (Phase 5): Depends on US1 completion (extends Perl method)
  - US4 (Phase 6): Depends on US1 completion (tests multiple calls)
  - US5 (Phase 7): Can start after Foundational - No dependencies (noscript is independent)
- **JavaScript (Phase 8)**: Depends on US1 HTML structure being defined
- **Integration (Phase 9)**: Depends on CSS (US2) and JS (Phase 8) being complete
- **Polish (Phase 10)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - CORE FUNCTIONALITY
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Independent (CSS styling)
- **User Story 3 (P1)**: Depends on US1 (extends collapse() method with blogdown)
- **User Story 4 (P2)**: Depends on US1 (tests multiple collapse() calls)
- **User Story 5 (P2)**: Can start after Foundational (Phase 2) - Independent (noscript fallback)

### Within Each User Story

- Tests MUST be written and FAIL before implementation (TDD approach)
- Core Perl implementation before CSS/JS
- HTML generation before JavaScript behavior
- Basic functionality before edge cases

### Parallel Opportunities

- **Phase 1 (Setup)**: All 3 tasks (T001-T003) can run in parallel
- **Phase 2 (Foundational)**: T004 and T005 can run in parallel
- **Phase 3 (US1 Tests)**: T006-T011 can run in parallel (different test cases/fixtures)
- **Phase 4 (US2 CSS)**: T023-T030 can run in parallel (independent CSS rules)
- **Phase 5 (US3 Tests)**: T033-T035 can run in parallel (different test fixtures)
- **Phase 6 (US4 Tests)**: T041-T042 can run in parallel (fixture creation)
- **Phase 7 (US5 Tests)**: T048-T050 can run in parallel (different test cases)
- **Phase 7 (US5 CSS)**: T052-T053 can run in parallel (independent CSS rules)
- **Phase 8 (JS)**: T057-T058 can run in parallel (different functions in same file - coordinate carefully)
- **Phase 10 (Polish)**: T071-T072 can run in parallel (documentation in different files)

---

## Parallel Example: User Story 1 - Tests

```bash
# Launch all tests for User Story 1 together:
Task T006: "Add parameter validation tests to t/template/plugin/ovid-collapse.t"
Task T007: "Add basic collapse() method invocation test to t/template/plugin/ovid-collapse.t"
Task T008: "Add HTML structure test to t/template/plugin/ovid-collapse.t"
Task T009: "Add unique ID generation test to t/template/plugin/ovid-collapse.t"
Task T010: "Create test fixture t/fixtures/collapsible-sections/basic.tt"
Task T011: "Create expected output t/fixtures/collapsible-sections/expected/basic.html"

# All 6 tasks write to different files or different test cases in same file
# Can be done simultaneously by multiple developers or AI agents
```

---

## Parallel Example: User Story 2 - CSS Implementation

```bash
# Launch all CSS styling tasks together:
Task T023: "Implement base section container styles in static/css/collapsible.css"
Task T024: "Implement trigger styles in static/css/collapsible.css"
Task T025: "Implement icon positioning styles in static/css/collapsible.css"
Task T026: "Implement short description text styles in static/css/collapsible.css"
Task T027: "Implement collapsed content state in static/css/collapsible.css"
Task T028: "Implement expanded content state in static/css/collapsible.css"
Task T029: "Implement hover state styles in static/css/collapsible.css"
Task T030: "Implement focus state styles in static/css/collapsible.css"

# All 8 tasks add independent CSS rules to same file
# Sequential editing required, but can be batched in single commit
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 3 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL)
3. Complete Phase 3: User Story 1 (Basic collapsible content)
4. Complete Phase 5: User Story 3 (Template syntax with blogdown)
5. Complete Phase 8: JavaScript (Interactive behavior)
6. Complete Phase 9: Integration (Include CSS/JS in wrapper)
7. **STOP and VALIDATE**: Test basic collapsible sections with blogdown support
8. Deploy/demo if ready

**Rationale**: US1 + US3 provide core authoring capability. US2 (styling), US4 (multiple sections), and US5 (noscript) are enhancements.

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Basic collapsible works (no styling)
3. Add User Story 2 → Test independently → Full visual integration
4. Add User Story 3 → Test independently → Blogdown support for rich content
5. Add User Story 4 → Test independently → Multiple sections validated
6. Add User Story 5 → Test independently → Noscript accessibility complete
7. Add JavaScript (Phase 8) → Interactive behavior
8. Add Integration (Phase 9) → Full feature complete
9. Each increment adds value without breaking previous functionality

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - **Developer A**: User Story 1 (Perl API) + User Story 3 (blogdown integration)
   - **Developer B**: User Story 2 (CSS styling) + User Story 5 (noscript CSS)
   - **Developer C**: JavaScript (Phase 8) after US1 HTML structure defined
3. Stories complete and integrate independently
4. Final integration (Phase 9) by any developer

---

## Notes

- **[P] tasks**: Different files or independent sections, no dependencies
- **[Story] label**: Maps task to specific user story for traceability
- **TDD approach**: All tests written FIRST, must FAIL before implementation begins
- **Each user story**: Independently completable and testable (except US3/US4 depend on US1)
- **Verify tests fail**: Before implementing, run `prove -l t/template/plugin/ovid-collapse.t` and confirm failures
- **Commit frequency**: After each task or logical group (e.g., all US1 tests together)
- **Stop at checkpoints**: Validate each story independently before proceeding
- **Constitution compliance**: 90%+ test coverage, perltidy formatting, Modern Perl 5.40+ features
- **Manual testing**: JavaScript and accessibility features require browser-based validation
- **Coverage target**: All new Perl code in `lib/Template/Plugin/Ovid.pm` must achieve 90%+ coverage

### ⚠️ CRITICAL: Section Independence Requirement

**Multiple collapsible sections MUST be completely independent:**

1. **Unique Identifiers**: Each section must have its own unique trigger ID and content ID (e.g., `collapsible-trigger-1`, `collapsible-content-1`)
2. **Isolated Event Handlers**: JavaScript event listeners must only affect their own section, never others
3. **No Shared State**: No global variables or shared state between sections
4. **ARIA Linking**: Each trigger's `aria-controls` must point ONLY to its own content element
5. **CSS Classes**: Use instance-specific targeting (via unique IDs), not shared classes that could interfere
6. **Testing**: Every test of multiple sections must verify that toggling one section does NOT change the state of any other section

**Implementation Pattern**:
- Perl: Counter-based unique ID generation (already in T014-T015)
- HTML: Each trigger links to its content via `aria-controls="collapsible-content-{N}"`
- JavaScript: Use `aria-controls` attribute to find the specific content element to toggle
- Never use shared selectors like "toggle all expanded sections" or "close other sections when opening one"

---

## Summary Statistics

- **Total Tasks**: 90 (updated to include T047a)
- **Setup Tasks**: 3
- **Foundational Tasks**: 2
- **User Story 1 (P1)**: 15 tasks (7 tests + 8 implementation)
- **User Story 2 (P2)**: 12 tasks (2 tests + 10 implementation)
- **User Story 3 (P1)**: 8 tasks (4 tests + 4 implementation)
- **User Story 4 (P2)**: 11 tasks (6 tests + 5 implementation) - **Enhanced for independence requirement**
- **User Story 5 (P2)**: 8 tasks (3 tests + 5 implementation)
- **JavaScript (Cross-cutting)**: 14 tasks (updated) - **Enhanced for independence requirement**
- **Integration**: 4 tasks
- **Polish & Validation**: 15 tasks (includes final independence validation)

**Parallel Opportunities**: 35 tasks marked [P] can run in parallel within their respective phases

**MVP Scope** (Recommended): Setup + Foundational + US1 + US3 + JavaScript + Integration = ~48 tasks for core functionality

**Independent Test Criteria**:
- US1: Single collapsible section works (collapsed by default, expands on click, collapses on second click)
- US2: Section spans full width with proper visual styling
- US3: Blogdown syntax processed correctly in full content
- US4: **Multiple sections operate completely independently** (3+ sections tested, verify no state interference)
- US5: Content accessible without JavaScript (noscript fallback with indentation)

**CRITICAL SUCCESS CRITERION**: Multiple collapsible sections on the same page MUST operate in complete isolation. Opening or closing one section MUST NEVER affect any other section's state.
