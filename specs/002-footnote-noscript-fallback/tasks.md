---
description: "Task list for Footnote NoScript Fallback feature implementation"
---

# Tasks: Footnote NoScript Fallback

**Input**: Design documents from `/specs/002-footnote-noscript-fallback/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Tests are included as this is a critical accessibility feature requiring 90%+ coverage per project constitution.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

- `lib/` - Perl modules
- `root/` - Template Toolkit templates
- `t/` - Test files
- `root/static/` - Static assets (CSS, JS)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify environment and baseline tests

- [X] T001 Activate Perl 5.40+ environment via `source ~/.bash_profile`
- [X] T002 Run baseline tests with `prove -l t/ovid_plugin.t` to establish passing state
- [X] T003 [P] Review existing footnote implementation in lib/Template/Plugin/Ovid.pm (lines 1-200)
- [X] T004 [P] Review existing footer template in root/include/footer.tt for footnote rendering section

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T005 Create test fixtures directory t/fixtures/ if not exists
- [ ] T006 Create test fixture file t/fixtures/test_footnotes.html with sample article containing 3 footnotes
- [ ] T007 Add test helper subroutines in t/ovid_plugin.t for HTML validation and footnote extraction
- [ ] T008 Document current `add_note()` method behavior via tests (baseline for JavaScript mode)

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 3 - Prevent Overlay Interference Without JavaScript (Priority: P1) 🎯 MVP

**Goal**: Fix critical bug where modal overlay blocks all content when JavaScript is disabled, making the page unreadable

**Independent Test**: Disable JavaScript in browser, load an article with footnotes, verify no blocking overlay appears and all content is readable

### Tests for User Story 3 (Critical Accessibility)

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T009 [P] [US3] Add test in t/ovid_plugin.t: "noscript section should exist in footer output"
- [ ] T010 [P] [US3] Add test in t/ovid_plugin.t: "noscript tag should wrap footnotes section"
- [ ] T011 [P] [US3] Add test in t/ovid_plugin.t: "dialog overlay and dialog elements should be outside noscript tag"

### Implementation for User Story 3

- [ ] T012 [US3] Modify root/include/footer.tt to wrap footnotes section in `<noscript>` tag (after dialog elements)
- [ ] T013 [US3] Add `<aside class="footnotes">` section in root/include/footer.tt within noscript tag
- [ ] T014 [US3] Ensure dialog overlay and dialog elements remain outside noscript tag in root/include/footer.tt
- [ ] T015 [US3] Verify HTML structure: dialogs first, then noscript footnote section in root/include/footer.tt

**Checkpoint**: At this point, the critical bug should be fixed - no overlay blocks content when JS is disabled

---

## Phase 4: User Story 1 - JavaScript-Enabled Footnote Viewing (Priority: P1)

**Goal**: Maintain current JavaScript-based modal dialog behavior for footnotes (ensure no regressions)

**Independent Test**: Load article with JavaScript enabled, click footnote icons, verify modals open/close correctly

### Tests for User Story 1 (Regression Prevention)

- [ ] T016 [P] [US1] Add test in t/ovid_plugin.t: "add_note generates span with open-dialog class"
- [ ] T017 [P] [US1] Add test in t/ovid_plugin.t: "add_note generates unique dialog IDs"
- [ ] T018 [P] [US1] Add test in t/ovid_plugin.t: "footnote body contains dialog HTML with ARIA attributes"
- [ ] T019 [P] [US1] Add test in t/ovid_plugin.t: "dialog overlay rendered in footer when has_footnotes is true"

### Implementation for User Story 1

- [ ] T020 [US1] Verify lib/Template/Plugin/Ovid.pm add_note() still generates JavaScript dialog HTML
- [ ] T021 [US1] Verify root/include/footer.tt still renders dialog overlay and Dialog.js initialization
- [ ] T022 [US1] Run manual test: build site with `perl bin/rebuild` and test JavaScript footnote modals
- [ ] T023 [US1] Verify existing ARIA attributes preserved in dialog HTML in lib/Template/Plugin/Ovid.pm

**Checkpoint**: At this point, JavaScript mode should work exactly as before (no regressions)

---

## Phase 5: User Story 2 - NoScript Footnote Navigation (Priority: P2)

**Goal**: Enable readers with JavaScript disabled to navigate to footnotes at article end via anchor links

**Independent Test**: Disable JavaScript, click footnote icon, verify navigation to footnote at bottom, click return link, verify return to reference

### Tests for User Story 2 (NoScript Functionality)

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T024 [P] [US2] Add test in t/ovid_plugin.t: "add_note generates noscript anchor link with href to #footnote-N"
- [ ] T025 [P] [US2] Add test in t/ovid_plugin.t: "add_note generates unique footnote-N-return ID in noscript anchor"
- [ ] T026 [P] [US2] Add test in t/ovid_plugin.t: "noscript footnote list contains li with id=footnote-N"
- [ ] T027 [P] [US2] Add test in t/ovid_plugin.t: "noscript footnote has return link to #footnote-N-return"
- [ ] T028 [P] [US2] Add test in t/ovid_plugin.t: "footnote content field is stored for noscript rendering"

### Implementation for User Story 2

- [ ] T029 [US2] Modify lib/Template/Plugin/Ovid.pm add_note() to add `content` field to footnote hash
- [ ] T030 [US2] Modify lib/Template/Plugin/Ovid.pm add_note() to return noscript anchor link wrapped in `<noscript>` tag
- [ ] T031 [US2] Add noscript anchor link generation in lib/Template/Plugin/Ovid.pm: `<a href="#footnote-N" id="footnote-N-return">`
- [ ] T032 [US2] Update root/include/footer.tt noscript section to render `<ol>` list of footnotes
- [ ] T033 [US2] Add footnote list items in root/include/footer.tt with `id="footnote-N"` and content from `footnote.content`
- [ ] T034 [US2] Add return link in root/include/footer.tt: `<a href="#footnote-N-return">↩ Return to text</a>`
- [ ] T035 [US2] Run manual test: disable JavaScript, verify anchor navigation works bidirectionally

**Checkpoint**: At this point, NoScript users can read and navigate all footnotes

---

## Phase 6: User Story 4 - Maintain Accessibility Standards (Priority: P3)

**Goal**: Ensure footnotes are accessible with assistive technology in both JavaScript and NoScript modes

**Independent Test**: Test with screen reader (both JS enabled and disabled) to verify appropriate announcements

### Tests for User Story 4 (Accessibility)

- [ ] T036 [P] [US4] Add test in t/ovid_plugin.t: "JavaScript dialog has aria-label attributes"
- [ ] T037 [P] [US4] Add test in t/ovid_plugin.t: "noscript anchor has aria-label='Footnote N'"
- [ ] T038 [P] [US4] Add test in t/ovid_plugin.t: "noscript return link has aria-label='Return to footnote N reference'"
- [ ] T039 [P] [US4] Add test in t/ovid_plugin.t: "noscript aside has aria-label='Footnotes'"

### Implementation for User Story 4

- [ ] T040 [P] [US4] Add aria-label to noscript anchor in lib/Template/Plugin/Ovid.pm: `aria-label="Footnote N"`
- [ ] T041 [P] [US4] Add aria-label to aside in root/include/footer.tt: `aria-label="Footnotes"`
- [ ] T042 [P] [US4] Add aria-label to return link in root/include/footer.tt: `aria-label="Return to footnote N reference"`
- [ ] T043 [US4] Add semantic HTML: `<aside>` for footnotes section in root/include/footer.tt
- [ ] T044 [US4] Verify `<ol>` provides numbered list semantics in root/include/footer.tt
- [ ] T045 [US4] Run manual accessibility test with VoiceOver or NVDA in both JS modes

**Checkpoint**: All user stories should now be independently functional and accessible

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories and final validation

- [ ] T046 [P] Add CSS styling for .footnotes section in root/static/css/dialog.css or create root/static/css/footnotes.css
- [ ] T047 [P] Style footnote list with proper spacing, borders, and typography in CSS
- [ ] T048 [P] Add responsive styles for mobile footnote display in CSS
- [ ] T049 Run full test suite with `prove -l t/` to ensure no regressions
- [ ] T050 Run test coverage with `cover -test` and verify 90%+ coverage
- [ ] T051 Generate coverage report with `cover -report html -outputdir coverage-report`
- [ ] T052 Rebuild site with `perl bin/rebuild` and verify build completes without errors
- [ ] T053 Manual test: Chrome with JavaScript enabled - verify footnote modals work
- [ ] T054 Manual test: Chrome with JavaScript disabled - verify footnote navigation works
- [ ] T055 Manual test: Firefox with JavaScript enabled - verify footnote modals work
- [ ] T056 Manual test: Firefox with JavaScript disabled - verify footnote navigation works
- [ ] T057 Manual test: Safari with JavaScript enabled - verify footnote modals work
- [ ] T058 Manual test: Safari with JavaScript disabled - verify footnote navigation works
- [ ] T059 Validate HTML5 output with Nu HTML Checker for sample articles
- [ ] T060 Test edge case: Article with 10+ footnotes in both JS modes
- [ ] T061 Test edge case: Footnote with complex HTML (links, code, formatting) in both modes
- [ ] T062 Test edge case: Footnote in heading or blockquote in both modes
- [ ] T063 [P] Update documentation: Add POD documentation to updated methods in lib/Template/Plugin/Ovid.pm
- [ ] T064 [P] Add inline comments explaining dual rendering logic in lib/Template/Plugin/Ovid.pm
- [ ] T065 Run quickstart.md validation scenarios from specs/002-footnote-noscript-fallback/quickstart.md
- [ ] T066 Format code with perltidy using .perltidyrc on modified Perl files
- [ ] T067 Final verification: All acceptance scenarios from spec.md pass

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Story 3 (Phase 3)**: Depends on Foundational - P1 priority (critical bug fix)
- **User Story 1 (Phase 4)**: Depends on Foundational - P1 priority (regression prevention)
- **User Story 2 (Phase 5)**: Depends on Foundational + US3 - P2 priority (needs noscript structure from US3)
- **User Story 4 (Phase 6)**: Depends on US1 + US2 + US3 - P3 priority (enhances both modes)
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 3 (P1)**: Can start after Foundational - Critical bug fix, creates noscript structure
- **User Story 1 (P1)**: Can start after Foundational - Independent from other stories (regression tests)
- **User Story 2 (P2)**: Depends on US3 completion (needs noscript tag structure in footer)
- **User Story 4 (P3)**: Depends on US1, US2, US3 (adds accessibility to both modes)

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Template changes before manual testing
- Module changes before template changes (for US2)
- Core implementation before accessibility enhancements
- Story complete before moving to next priority

### Parallel Opportunities

- **Setup Phase**: T003 and T004 can run in parallel (reading different files)
- **US3 Tests**: T009, T010, T011 can run in parallel (independent test cases)
- **US1 Tests**: T016, T017, T018, T019 can run in parallel (independent test cases)
- **US2 Tests**: T024, T025, T026, T027, T028 can run in parallel (independent test cases)
- **US4 Tests**: T036, T037, T038, T039 can run in parallel (independent test cases)
- **US4 Implementation**: T040, T041, T042 can run in parallel (different ARIA attributes)
- **Polish Phase**: T046, T047, T048 can run in parallel (CSS styling tasks)
- **Polish Phase**: T063, T064 can run in parallel (documentation tasks)
- **Manual Tests**: T053-T058 can be run in parallel with multiple browsers open

---

## Parallel Example: User Story 2

```bash
# Launch all tests for User Story 2 together:
Task: "Add test: add_note generates noscript anchor link with href to #footnote-N"
Task: "Add test: add_note generates unique footnote-N-return ID in noscript anchor"
Task: "Add test: noscript footnote list contains li with id=footnote-N"
Task: "Add test: noscript footnote has return link to #footnote-N-return"
Task: "Add test: footnote content field is stored for noscript rendering"

# Then implement sequentially (dependencies exist):
Task: "Modify add_note() to add content field" (first)
Task: "Modify add_note() to return noscript anchor" (depends on content field)
Task: "Update footer.tt noscript section" (depends on content field)
```

---

## Implementation Strategy

### MVP First (User Stories 3 + 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 3 (Critical bug fix - no blocking overlay)
4. Complete Phase 4: User Story 1 (Ensure no regressions in JS mode)
5. **STOP and VALIDATE**: Test both modes, verify critical bug is fixed
6. Deploy/demo if ready (Users can now read articles with JS disabled!)

### Full Feature Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 3 → Test independently → Critical bug fixed!
3. Add User Story 1 → Test independently → No regressions confirmed
4. Add User Story 2 → Test independently → Full anchor navigation working
5. Add User Story 4 → Test independently → Accessibility enhanced
6. Complete Polish phase → All edge cases tested, documentation complete
7. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers (after Foundational phase):

1. Developer A: User Story 3 + User Story 1 (P1 priority items, can be parallel)
2. Developer B: User Story 2 (P2 priority, after US3 completes)
3. Developer C: User Story 4 (P3 priority, after US1+US2+US3 complete)
4. All developers: Polish phase tasks in parallel

### Critical Path

The fastest path to fixing the reported bug:

1. T001-T008: Setup and Foundation (required)
2. T009-T015: User Story 3 (fixes blocking overlay bug)
3. T016-T023: User Story 1 (ensures no regressions)
4. T049-T058: Critical manual tests
5. **Result**: Bug fixed, feature working in both modes

---

## Notes

- [P] tasks = different files, no dependencies, can run in parallel
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing (TDD approach)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- **Critical**: US3 is highest priority - it fixes the blocking overlay bug that makes articles unreadable
- **Test coverage**: Must achieve 90%+ per constitution.md requirements
- **No regressions**: US1 ensures current JavaScript behavior is preserved
- **Accessibility**: US4 ensures both modes are screen-reader friendly

---

## Success Criteria Mapping

| Success Criteria | Completed By Tasks |
|-----------------|-------------------|
| SC-001: JavaScript mode matches current behavior | T016-T023, T053-T058 |
| SC-002: NoScript anchor navigation works | T024-T035, T054-T058 |
| SC-003: No blocking overlay without JS | T009-T015, T054-T058 |
| SC-004: Existing articles work in both modes | T053-T062 |
| SC-005: HTML5 validation passes | T059 |
| SC-006: Zero regressions | T049-T050 |
| SC-007: Screen reader accessibility | T036-T045 |
| SC-008: Bug report scenario resolved | T009-T015, T065 |

---

## Validation Checklist

Before considering this feature complete:

- [ ] All tests pass (`prove -l t/`)
- [ ] Coverage ≥ 90% (`cover -test`)
- [ ] Site builds without errors (`perl bin/rebuild`)
- [ ] JavaScript mode: Footnote modals open/close in 3+ browsers
- [ ] NoScript mode: Anchor navigation works in 3+ browsers
- [ ] NoScript mode: No blocking overlay appears
- [ ] HTML5 validation passes for sample articles
- [ ] Screen reader testing completed (both modes)
- [ ] Edge cases tested (10+ footnotes, complex HTML, various contexts)
- [ ] Code formatted with perltidy
- [ ] POD documentation updated
- [ ] All quickstart.md scenarios pass
- [ ] All acceptance scenarios from spec.md pass
