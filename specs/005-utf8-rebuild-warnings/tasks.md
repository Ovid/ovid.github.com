# Tasks: Fix UTF-8 Warnings in Single File Rebuild

**Input**: Design documents from `/specs/005-utf8-rebuild-warnings/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Tests are included per FR-007 and Constitution Principle III (90%+ coverage requirement)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

## Path Conventions

**This Project (Static Site Generator)**:
- **Development scope** (per Constitution v1.5.0): `lib/`, `bin/`, `t/`
- **Generated content** (do NOT modify): `articles/`, `blog/`, `tags/`
- **User assets** (do NOT modify): `static/`, `css/`, `images/`
- **Tests**: `t/` (mirrors `lib/` structure)
- **Fixtures**: `t/fixtures/` (test data only)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and environment verification

- [X] T001 Verify Perl 5.40+ environment is activated via `source ~/.bash_profile && perl -v`
- [X] T002 Install/verify dependencies via `cpanm --installdeps . --with-configure --with-develop --with-all-features`
- [X] T003 Verify current problem exists by running `perl bin/rebuild --file root/blog/torturing-an-llm.tt2markdown --notest` and confirming UTF-8 warnings appear

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: N/A - This feature has no foundational blocking tasks. User stories can proceed directly after Setup.

---

## Phase 3: User Story 1 - Single File Rebuild Without Warnings (Priority: P1) 🎯 MVP

**Goal**: Eliminate UTF-8 encoding warnings when rebuilding individual template files via `bin/rebuild --file`, ensuring UTF-8 characters display correctly in generated HTML

**Independent Test**: Run `perl bin/rebuild --file root/blog/torturing-an-llm.tt2markdown --notest` and verify:
1. No "Parsing of undecoded UTF-8" warnings appear
2. No "Wide character in print" warnings appear
3. Generated HTML displays UTF-8 characters correctly in browsers

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T004 [US1] Create test fixture with UTF-8 content in `t/fixtures/templates/utf8_test_template.tt2markdown` (smart quotes, em dashes, accented letters, HTML entities)
- [X] T005 [US1] Create test file `t/utf8_single_file_rebuild.t` that verifies no UTF-8 warnings appear during single-file rebuild
- [X] T006 [US1] Add test case to verify generated HTML contains correctly encoded UTF-8 characters
- [X] T007 [US1] Add test case to verify UTF-8 charset meta tag is present in generated HTML
- [X] T008 [US1] Run new test and verify it FAILS with current code: `prove -lv t/utf8_single_file_rebuild.t`

### Implementation for User Story 1

- [ ] T009 [US1] Modify `lib/Ovid/Site.pm` method `_run_ttree_single` (around line 127-135) to add `--binmode => 'utf8'` flag to ttree command array
- [ ] T010 [US1] Modify `lib/Ovid/Site.pm` method `_run_ttree_single` to add `--encoding => 'utf8'` flag to ttree command array (same flags used in `_run_ttree` method)
- [ ] T011 [US1] Verify encoding flags are added BEFORE `$relative_file` argument (must be last in command array)
- [ ] T012 [US1] Add inline comments documenting the encoding flags match `_run_ttree` method behavior
- [ ] T013 [US1] Run new test and verify it PASSES: `prove -lv t/utf8_single_file_rebuild.t`
- [ ] T014 [US1] Verify fix with real template: `perl bin/rebuild --file root/blog/torturing-an-llm.tt2markdown --notest` shows no warnings

**Checkpoint**: At this point, single-file rebuilds should work without UTF-8 warnings and generate correct output

---

## Phase 4: User Story 2 - Full Site Rebuild Remains Unaffected (Priority: P2)

**Goal**: Ensure full site rebuild continues to work correctly without regressions after UTF-8 fix is applied

**Independent Test**: Run `perl bin/rebuild` (without --file flag) and verify:
1. All pages generate successfully
2. No new UTF-8 warnings are introduced
3. UTF-8 encoding matches previous behavior

### Tests for User Story 2

- [ ] T015 [US2] Add test case in `t/utf8_single_file_rebuild.t` to compare single-file output with full rebuild output (should be byte-identical for UTF-8 content)
- [ ] T016 [US2] Create test that runs full rebuild and captures any UTF-8 warnings
- [ ] T017 [US2] Run new test and verify it PASSES (full rebuild already works): `prove -lv t/utf8_single_file_rebuild.t`

### Implementation for User Story 2

- [ ] T018 [US2] Run full test suite to verify no regressions: `prove -l t/`
- [ ] T019 [US2] Run full site rebuild and verify success: `perl bin/rebuild`
- [ ] T020 [US2] Spot-check generated HTML files for correct UTF-8 character rendering in browser
- [ ] T021 [US2] Verify existing templates with UTF-8 content display correctly (articles with smart quotes, em dashes, etc.)

**Checkpoint**: Both single-file and full-site rebuilds should work correctly with proper UTF-8 handling

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Ensure code quality, coverage, and documentation standards

- [ ] T022 Run test coverage analysis: `cover -test`
- [ ] T023 Generate HTML coverage report: `cover -report html -outputdir coverage-report`
- [ ] T024 Verify coverage is ≥90% per Constitution Principle III
- [ ] T025 Format code with perltidy: `perltidy --profile=.perltidyrc lib/Ovid/Site.pm`
- [ ] T026 Run full test suite one final time: `prove -l t/`
- [ ] T027 Verify all quickstart.md verification steps pass
- [ ] T028 Document the fix in commit message referencing FR-001 through FR-007

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: N/A - No foundational phase for this feature
- **User Stories (Phase 3+)**: Can start immediately after Setup
  - User Story 1 (P1) is independent - can start after Setup
  - User Story 2 (P2) depends on User Story 1 completion (tests comparison between modes)
- **Polish (Final Phase)**: Depends on both user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Setup (Phase 1) - No dependencies on other stories
- **User Story 2 (P2)**: Depends on User Story 1 completion - Tests verify full rebuild remains unaffected by US1 changes

### Within Each User Story

**User Story 1**:
- T004-T008: All test creation tasks can run in parallel (different concerns)
- T008 must complete before T009 (verify tests fail before implementing)
- T009-T012: Implementation tasks must be done sequentially (modifying same file/method)
- T013-T014: Verification tasks run after implementation

**User Story 2**:
- T015-T017: Test tasks can run in parallel
- T018-T021: Verification tasks should run sequentially

### Parallel Opportunities

**Setup Phase**: All tasks are sequential (environment verification)

**User Story 1 - Test Creation** (can run in parallel):
```bash
Task T004: "Create test fixture in t/fixtures/utf8_test_template.tt2markdown"
Task T005: "Create test file t/utf8_single_file_rebuild.t"
```

**User Story 1 - Test Cases** (within T005, can be written in parallel):
- Test case for no UTF-8 warnings
- Test case for correct UTF-8 in output
- Test case for charset meta tag

**User Story 2 - Tests** (can run in parallel):
```bash
Task T015: "Add comparison test to t/utf8_single_file_rebuild.t"
Task T016: "Create test for full rebuild warnings"
```

**Polish Phase** (some parallelization):
```bash
# Can run in parallel:
Task T022: "Run test coverage analysis"
Task T025: "Format code with perltidy"
```

---

## Parallel Example: User Story 1 Test Creation

```bash
# Launch test fixture and test file creation together:
Task: "Create test fixture with UTF-8 content in t/fixtures/utf8_test_template.tt2markdown"
Task: "Create base test file structure in t/utf8_single_file_rebuild.t"

# Then add test cases to t/utf8_single_file_rebuild.t:
Task: "Add test case: verify no UTF-8 warnings"
Task: "Add test case: verify correct UTF-8 in output"
Task: "Add test case: verify charset meta tag"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (verify environment and dependencies)
2. Complete Phase 3: User Story 1
   - Create tests first (T004-T008)
   - Verify tests FAIL
   - Implement fix (T009-T012)
   - Verify tests PASS (T013-T014)
3. **STOP and VALIDATE**: Test single-file rebuilds with various templates
4. Deploy/commit if ready

### Incremental Delivery

1. Complete Setup → Environment ready
2. Add User Story 1 → Test independently → Single-file rebuilds work without warnings (MVP!)
3. Add User Story 2 → Test independently → Confirm full rebuild unaffected
4. Complete Polish → Ensure code quality standards met
5. Each phase adds validation without breaking previous work

### Single Developer Strategy

This is a small, focused fix suitable for one developer:

1. Complete Setup (5-10 minutes)
2. Complete User Story 1 (1-2 hours):
   - Write tests with fixtures
   - Verify tests fail
   - Add two lines to `lib/Ovid/Site.pm`
   - Verify tests pass
3. Complete User Story 2 (30 minutes):
   - Add comparison tests
   - Run full rebuild verification
4. Complete Polish (20 minutes):
   - Check coverage
   - Format code
   - Final verification

**Total estimated time**: 2-3 hours

---

## Notes

- This is a minimal fix: adding 2 flags to a single method in `lib/Ovid/Site.pm`
- The full rebuild (`_run_ttree`) already has these flags - we're just matching that behavior
- Tests are mandatory per FR-007 and Constitution Principle III
- No changes to Template2/ directory (CON-001)
- No changes to template files (CON-004)
- Solution works with existing Template Toolkit installation (CON-002)
- Changes are minimal and focused on encoding layer handling (CON-003)
- Performance is explicitly ignored per ASM-006
- All tasks target `lib/` or `t/` directories only (per Constitution development scope)

---

## Success Criteria Verification

After completing all tasks, verify:

- [ ] **SC-001**: Running `bin/rebuild --file <any-template>` produces zero UTF-8-related warnings
- [ ] **SC-002**: Generated HTML files from single-file rebuilds display UTF-8 characters identically to full site rebuilds
- [ ] **SC-003**: All existing tests continue to pass without modification
- [ ] **SC-004**: UTF-8 characters (curly quotes, em dashes, accented letters) in template files appear correctly in final HTML
- [ ] **SC-005**: New automated tests verify UTF-8 handling in single-file rebuilds and detect encoding-related regressions
- [ ] **Coverage**: Test coverage remains ≥90% per Constitution Principle III
- [ ] **Constitution**: All constitution principles remain satisfied (verified in plan.md)
