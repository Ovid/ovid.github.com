# Tasks: Test Coverage Improvement

**Input**: Design documents from `/specs/001-test-coverage-improvement/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Tests are the deliverable of this feature - no additional test tasks generated.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- Existing project structure: `lib/`, `t/`, `bin/` at repository root
- Test files mirror lib structure in t/
- Coverage reports in `cover_db/`

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Tool installation and environment setup

- [ ] T001 Install Devel::Cover and Test2::Suite dependencies via cpanfile
- [ ] T002 Configure coverage environment and verify Devel::Cover installation
- [ ] T003 [P] Update cpanfile with any missing dependencies for testing

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core tools and baseline that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T004 Create usage analysis script in bin/analyze-usage.pl per usage-analysis-contract.md
- [ ] T005 Run initial coverage baseline with `cover -test` and generate HTML report
- [ ] T006 Document current coverage metrics for all 15 modules in coverage-baseline.md

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Identify Unused Code (Priority: P1) 🎯 MVP

**Goal**: Analyze each module to identify methods/functions with zero call sites and document findings

**Independent Test**: Run usage analysis script on a module and verify it identifies potentially unused methods

### Implementation for User Story 1

- [ ] T007 [P] [US1] Analyze usage for lib/Less/Boilerplate.pm and document potentially unused methods
- [ ] T008 [P] [US1] Analyze usage for lib/Less/Config.pm and document potentially unused methods
- [ ] T009 [P] [US1] Analyze usage for lib/Less/Pager.pm and document potentially unused methods
- [ ] T010 [P] [US1] Analyze usage for lib/Less/Script.pm and document potentially unused methods
- [ ] T011 [P] [US1] Analyze usage for lib/Ovid/Site/AI/Images.pm and document potentially unused methods
- [ ] T012 [P] [US1] Analyze usage for lib/Ovid/Site/Utils.pm and document potentially unused methods
- [ ] T013 [P] [US1] Analyze usage for lib/Ovid/Template/File.pm and document potentially unused methods
- [ ] T014 [P] [US1] Analyze usage for lib/Ovid/Template/File/Collection.pm and document potentially unused methods
- [ ] T015 [P] [US1] Analyze usage for lib/Ovid/Template/File/FindCode.pm and document potentially unused methods
- [ ] T016 [P] [US1] Analyze usage for lib/Ovid/Template/Role/Debug.pm and document potentially unused methods
- [ ] T017 [P] [US1] Analyze usage for lib/Ovid/Template/Role/File.pm and document potentially unused methods
- [ ] T018 [P] [US1] Analyze usage for lib/Ovid/Types.pm and document potentially unused methods
- [ ] T019 [P] [US1] Analyze usage for lib/Template/Plugin/Config.pm and document potentially unused methods
- [ ] T020 [P] [US1] Analyze usage for lib/Template/Plugin/Ovid.pm and document potentially unused methods
- [ ] T021 [P] [US1] Analyze usage for lib/Text/Markdown/Blog.pm and document potentially unused methods

**Checkpoint**: At this point, unused code identified for all modules

---

## Phase 4: User Story 2 - Achieve Highest Possible Statement Coverage (Priority: P2)

**Goal**: Add comprehensive tests to achieve at least 90% statement coverage for each module

**Independent Test**: Run `cover -test` on a module's test file and verify statement coverage >=90%

### Implementation for User Story 2

- [ ] T022 [P] [US2] Add tests for lib/Less/Boilerplate.pm to achieve 90%+ statement coverage in t/Less/Boilerplate.t
- [ ] T023 [P] [US2] Add tests for lib/Less/Config.pm to achieve 90%+ statement coverage in t/Less/Config.t
- [ ] T024 [P] [US2] Add tests for lib/Less/Pager.pm to achieve 90%+ statement coverage in t/Less/Pager.t
- [ ] T025 [P] [US2] Add tests for lib/Less/Script.pm to achieve 90%+ statement coverage in t/Less/Script.t
- [ ] T026 [P] [US2] Add tests for lib/Ovid/Site/AI/Images.pm to achieve 90%+ statement coverage in t/Ovid/Site/AI/Images.t
- [ ] T027 [P] [US2] Add tests for lib/Ovid/Site/Utils.pm to achieve 90%+ statement coverage in t/Ovid/Site/Utils.t
- [ ] T028 [P] [US2] Add tests for lib/Ovid/Template/File.pm to achieve 90%+ statement coverage in t/Ovid/Template/File.t
- [ ] T029 [P] [US2] Add tests for lib/Ovid/Template/File/Collection.pm to achieve 90%+ statement coverage in t/Ovid/Template/File/Collection.t
- [ ] T030 [P] [US2] Add tests for lib/Ovid/Template/File/FindCode.pm to achieve 90%+ statement coverage in t/Ovid/Template/File/FindCode.t
- [ ] T031 [P] [US2] Add tests for lib/Ovid/Template/Role/Debug.pm to achieve 90%+ statement coverage in t/Ovid/Template/Role/Debug.t
- [ ] T032 [P] [US2] Add tests for lib/Ovid/Template/Role/File.pm to achieve 90%+ statement coverage in t/Ovid/Template/Role/File.t
- [ ] T033 [P] [US2] Add tests for lib/Ovid/Types.pm to achieve 90%+ statement coverage in t/Ovid/Types.t
- [ ] T034 [P] [US2] Add tests for lib/Template/Plugin/Config.pm to achieve 90%+ statement coverage in t/Template/Plugin/Config.t
- [ ] T035 [P] [US2] Add tests for lib/Template/Plugin/Ovid.pm to achieve 90%+ statement coverage in t/Template/Plugin/Ovid.t
- [ ] T036 [P] [US2] Add tests for lib/Text/Markdown/Blog.pm to achieve 90%+ statement coverage in t/Text/Markdown/Blog.t

**Checkpoint**: All modules achieve 90%+ statement coverage

---

## Phase 5: User Story 3 - Achieve Highest Possible Branch Coverage (Priority: P3)

**Goal**: Add tests for conditional logic to achieve highest possible branch coverage for each module

**Independent Test**: Run coverage analysis and verify branch coverage is maximized for modules with conditionals

### Implementation for User Story 3

- [ ] T037 [P] [US3] Add branch coverage tests for lib/Less/Boilerplate.pm in t/Less/Boilerplate.t
- [ ] T038 [P] [US3] Add branch coverage tests for lib/Less/Config.pm in t/Less/Config.t
- [ ] T039 [P] [US3] Add branch coverage tests for lib/Less/Pager.pm in t/Less/Pager.t
- [ ] T040 [P] [US3] Add branch coverage tests for lib/Less/Script.pm in t/Less/Script.t
- [ ] T041 [P] [US3] Add branch coverage tests for lib/Ovid/Site/AI/Images.pm in t/Ovid/Site/AI/Images.t
- [ ] T042 [P] [US3] Add branch coverage tests for lib/Ovid/Site/Utils.pm in t/Ovid/Site/Utils.t
- [ ] T043 [P] [US3] Add branch coverage tests for lib/Ovid/Template/File.pm in t/Ovid/Template/File.t
- [ ] T044 [P] [US3] Add branch coverage tests for lib/Ovid/Template/File/Collection.pm in t/Ovid/Template/File/Collection.t
- [ ] T045 [P] [US3] Add branch coverage tests for lib/Ovid/Template/File/FindCode.pm in t/Ovid/Template/File/FindCode.t
- [ ] T046 [P] [US3] Add branch coverage tests for lib/Ovid/Template/Role/Debug.pm in t/Ovid/Template/Role/Debug.t
- [ ] T047 [P] [US3] Add branch coverage tests for lib/Ovid/Template/Role/File.pm in t/Ovid/Template/Role/File.t
- [ ] T048 [P] [US3] Add branch coverage tests for lib/Ovid/Types.pm in t/Ovid/Types.t
- [ ] T049 [P] [US3] Add branch coverage tests for lib/Template/Plugin/Config.pm in t/Template/Plugin/Config.t
- [ ] T050 [P] [US3] Add branch coverage tests for lib/Template/Plugin/Ovid.pm in t/Template/Plugin/Ovid.t
- [ ] T051 [P] [US3] Add branch coverage tests for lib/Text/Markdown/Blog.pm in t/Text/Markdown/Blog.t

**Checkpoint**: All modules with conditionals achieve highest possible branch coverage

---

## Phase 6: User Story 4 - Document Coverage Gaps (Priority: P4)

**Goal**: Document coverage gaps and testing decisions for each module

**Independent Test**: Review module documentation and verify untested code has justifications

### Implementation for User Story 4

- [ ] T052 [P] [US4] Document coverage gaps for lib/Less/Boilerplate.pm with justifications
- [ ] T053 [P] [US4] Document coverage gaps for lib/Less/Config.pm with justifications
- [ ] T054 [P] [US4] Document coverage gaps for lib/Less/Pager.pm with justifications
- [ ] T055 [P] [US4] Document coverage gaps for lib/Less/Script.pm with justifications
- [ ] T056 [P] [US4] Document coverage gaps for lib/Ovid/Site/AI/Images.pm with justifications
- [ ] T057 [P] [US4] Document coverage gaps for lib/Ovid/Site/Utils.pm with justifications
- [ ] T058 [P] [US4] Document coverage gaps for lib/Ovid/Template/File.pm with justifications
- [ ] T059 [P] [US4] Document coverage gaps for lib/Ovid/Template/File/Collection.pm with justifications
- [ ] T060 [P] [US4] Document coverage gaps for lib/Ovid/Template/File/FindCode.pm with justifications
- [ ] T061 [P] [US4] Document coverage gaps for lib/Ovid/Template/Role/Debug.pm with justifications
- [ ] T062 [P] [US4] Document coverage gaps for lib/Ovid/Template/Role/File.pm with justifications
- [ ] T063 [P] [US4] Document coverage gaps for lib/Ovid/Types.pm with justifications
- [ ] T064 [P] [US4] Document coverage gaps for lib/Template/Plugin/Config.pm with justifications
- [ ] T065 [P] [US4] Document coverage gaps for lib/Template/Plugin/Ovid.pm with justifications
- [ ] T066 [P] [US4] Document coverage gaps for lib/Text/Markdown/Blog.pm with justifications

**Checkpoint**: All coverage gaps documented with justifications

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements and validation

- [ ] T067 Run full test suite and verify all tests pass
- [ ] T068 Generate final coverage report and verify all modules meet 90%+ statement coverage
- [ ] T069 [P] Update README.md with testing information
- [ ] T070 Validate quickstart.md instructions work correctly
- [ ] T071 Clean up temporary files and coverage artifacts

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - User stories proceed sequentially in priority order (P1 → P2 → P3 → P4)
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational - No dependencies on other stories
- **User Story 2 (P2)**: Depends on US1 completion (unused code identified before testing)
- **User Story 3 (P3)**: Depends on US2 completion (statement coverage before branch)
- **User Story 4 (P4)**: Depends on US2/US3 completion (after coverage achieved)

### Within Each User Story

- All tasks within a story can run in parallel (different modules)
- Core implementation before documentation

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks can run in parallel
- Once Foundational completes, tasks within each user story can run in parallel (different modules)
- Different modules within the same story can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

```bash
# Launch analysis for multiple modules in parallel:
Task: "Analyze usage for lib/Less/Boilerplate.pm and document potentially unused methods"
Task: "Analyze usage for lib/Less/Config.pm and document potentially unused methods"
# ... etc for all modules
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1 (analyze all modules for unused code)
4. **STOP and VALIDATE**: Verify usage analysis works and findings documented
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Validate unused code identification
3. Add User Story 2 → Validate statement coverage improvements
4. Add User Story 3 → Validate branch coverage improvements
5. Add User Story 4 → Validate documentation completeness
6. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Multiple developers can work on different modules within the same user story
   - Or one developer per user story if sequential
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different modules, no dependencies between modules
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable per module
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: cross-module dependencies, breaking existing functionality
