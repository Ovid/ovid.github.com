# Feature Specification: Legacy Code Test Coverage Improvement

**Feature Branch**: `001-test-coverage-improvement`  
**Created**: 2025-11-09  
**Status**: Draft  
**Input**: User description: "This is a legacy Perl project designed to build Curtis 'Ovid' Poe's static web site. We are going to refactor this project. Before that, we have to walk through every module in the project, one-by-one, and increase its test coverage as high as possible, with no module less than 90%+. Because this is legacy code, it's possible that there is code that is not used. Before adding tests to improve coverage, determine if the existing code is actually used."

## Terminology & Definitions *(mandatory)*

**Highest Achievable Coverage**: Coverage is considered to have reached its "highest achievable" or "maximum achievable" level when all remaining uncovered lines have documented justification explaining why they cannot or should not be tested (per FR-011). This means:
- All testable code paths have tests written for them
- Any line not covered has an explicit reason documented (e.g., "platform-specific code not applicable to current OS", "error handling for impossible state given type constraints", "deprecated code pending removal")
- The module meets the minimum 90% threshold
- Further coverage improvement would require either testing truly unreachable code or architectural refactoring (which is out of scope)

**Example**: A module at 92% coverage where the remaining 8% consists of Windows-specific error handling (tested on Linux), with inline comments documenting each uncovered section, has achieved "highest achievable coverage".

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Identify Unused Code (Priority: P1)

As a developer preparing for refactoring, I need to identify and document unused code in each module so that I can make informed decisions about whether to test it, remove it, or keep it.

**Why this priority**: Testing unused code wastes time and creates technical debt. Identifying dead code first prevents writing tests for code that will be removed, saving significant effort.

**Independent Test**: Can be fully tested by running static analysis on each module, checking call sites across the codebase, and producing a report of potentially unused methods/functions. Delivers immediate value by highlighting refactoring candidates.

**Acceptance Scenarios**:

1. **Given** a module with methods that are never called anywhere in the codebase, **When** I run usage analysis, **Then** the report identifies these methods as "potentially unused"
2. **Given** a module with methods called only in commented-out code or dead branches, **When** I run usage analysis, **Then** these methods are flagged for review
3. **Given** a module analysis is complete, **When** I review the report, **Then** I can see which methods are used, where they're called from, and their usage frequency
4. **Given** dead code is identified, **When** I document findings, **Then** each unused method has a note indicating whether to remove, test, or investigate further

---

### User Story 2 - Achieve Highest Possible Statement Coverage Per Module (Minimum 90%+) (Priority: P2)

As a developer, I need to systematically increase test coverage for each module as high as possible, with at least 90%+ statement coverage so that I can safely refactor the codebase with confidence.

**Why this priority**: Once we know what code is actually used (P1), we need comprehensive tests before refactoring. This is the core deliverable that enables safe refactoring.

**Independent Test**: Can be fully tested by running Devel::Cover on each module individually, verifying coverage meets 90% threshold, and validating tests use Test::Most. Each module can be tested independently.

**Acceptance Scenarios**:

1. **Given** a module with current coverage below 90%, **When** I add comprehensive tests, **Then** running `cover -test` shows statement coverage as high as possible, meeting at least 90%
2. **Given** a module test file, **When** I review the code, **Then** all tests use Test::Most instead of other testing frameworks
3. **Given** tests are written for a module, **When** I run the test suite, **Then** all edge cases, error conditions, and normal flows are covered to maximize coverage
4. **Given** a module reaches maximum achievable coverage, **When** I review uncovered lines, **Then** I can document why remaining lines are not covered (e.g., error handling for impossible states) - coverage is considered "highest achievable" when all remaining uncovered lines have documented justification per FR-011
5. **Given** all modules reach target coverage, **When** I generate a full coverage report, **Then** no module shows below 90% statement coverage, with each module at its highest possible level

---

### User Story 3 - Achieve Highest Possible Branch Coverage Per Module (Minimum 90%+) (Priority: P3)

As a developer, I need to achieve the highest possible branch coverage for conditional logic in each module, with at least 90%+ coverage, so that all decision paths are tested before refactoring.

**Why this priority**: Branch coverage catches logic errors that statement coverage misses. While important, it can be partially addressed while achieving statement coverage (P2), making it lower priority.

**Independent Test**: Can be fully tested by reviewing Devel::Cover branch coverage metrics and adding tests for uncovered conditionals. Each module's branch coverage can be improved independently.

**Acceptance Scenarios**:

1. **Given** a module with conditional logic, **When** I run coverage analysis, **Then** each if/else, ternary, and logical operator path is tested to achieve maximum branch coverage, with minimum 90%
2. **Given** a module with complex boolean expressions, **When** I write tests, **Then** both true and false outcomes of each condition are covered to maximize coverage, with minimum 90%
3. **Given** error handling code with multiple exit paths, **When** tests run, **Then** coverage report shows all error branches executed for highest possible coverage, with minimum 90%
4. **Given** a module reaches maximum achievable branch coverage, **When** I review uncovered branches, **Then** each has documented justification for exclusion per FR-011 - this defines when branch coverage is "highest achievable"

---

### User Story 4 - Document Coverage Gaps and Decisions (Priority: P4)

As a developer, I need to document coverage gaps and testing decisions for each module so that future maintainers understand why certain code isn't tested.

**Why this priority**: Documentation is important but can be done as modules are tested (alongside P2-P3). It's the lowest priority because it's a byproduct of the testing process rather than a prerequisite.

**Independent Test**: Can be fully tested by reviewing documentation for each module and verifying that untested code sections have clear justifications in comments or a separate tracking document.

**Acceptance Scenarios**:

1. **Given** a module has code that cannot be tested (e.g., platform-specific code), **When** coverage is reviewed, **Then** comments explain why testing is not feasible
2. **Given** dead code is identified, **When** I document findings, **Then** the module has a comment noting "TODO: Remove unused method X before refactoring"
3. **Given** error conditions are difficult to trigger, **When** tests are written, **Then** documentation explains the testing approach (mocking, dependency injection, etc.)
4. **Given** all modules reach target coverage, **When** I review documentation, **Then** each module has clear notes about coverage decisions

---

### Edge Cases

- **Edge Case 1 (XS/Platform-specific code)**: What happens when a module has XS code or platform-specific code that can't be tested on the current system?
  - **Resolution**: Document as untestable in coverage-exceptions.md; aim for 100% coverage on pure Perl code (see research.md for detailed approach)
- **Edge Case 2 (External state dependencies)**: How do we handle modules that depend on external state (filesystem, database, network) for testing?
  - **Resolution**: Use Test::MockModule and Test::MockObject for mocking; create fixtures in t/fixtures/ (see FR-015, T009c)
- **Edge Case 3 (Template Toolkit coupling)**: What if a module is tightly coupled to Template Toolkit rendering and difficult to unit test?
  - **Resolution**: Test by comparing rendered output against expected fixtures; use minimal template fixtures (see research.md)
- **Edge Case 4 (Build failures/error cases)**: How do we test code that only runs during build failures or edge cases that are hard to reproduce?
  - **Resolution**: Simulate failures by mocking file operations and invalid inputs; use Test::Most exception testing (throws_ok, dies_ok)
- **Edge Case 5 (Dynamic code)**: What happens when code coverage tools report inaccurate coverage due to string eval, runtime code generation, or dynamic method calls?
  - **Resolution**: Static analysis will flag potentially unused code; document dynamic dispatch in usage-analysis-results.md; manual review required

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST analyze each module to identify methods/functions with zero call sites in the codebase
- **FR-002**: System MUST generate a usage report showing which methods are called, their call sites, and usage frequency
- **FR-003**: Developer MUST review each module's current coverage metrics before adding tests
- **FR-004**: Tests MUST use Test::Most exclusively for new tests
- **FR-005**: Each module test file MUST mirror the `lib/` structure in the `t/` directory (e.g., `lib/Ovid/Site.pm` → `t/Ovid/Site.t`)
- **FR-006**: Tests MUST achieve minimum 90% statement coverage per module, aiming for highest achievable level
- **FR-007**: Tests MUST achieve minimum 90% branch coverage per module where conditional logic exists, aiming for highest achievable level
- **FR-008**: Tests MUST cover all public methods and exported functions
- **FR-009**: Tests MUST include error condition testing (invalid inputs, boundary cases, failure modes)
- **FR-010**: Coverage reports MUST be generated using Devel::Cover with HTML output
- **FR-011**: Each module's uncovered code MUST have documented justification (inline comments or separate doc)
- **FR-012**: Dead code identified MUST be marked with TODO comments for removal or investigated for hidden usage
- **FR-013**: Tests MUST NOT duplicate existing tests - review and enhance existing test files
- **FR-014**: Integration tests MUST remain passing after adding unit tests
- **FR-015**: Module dependencies MUST be mockable for isolated unit testing

### Key Entities

- **Module Under Test**: A Perl module in `lib/` requiring coverage improvement; has attributes: file path, current coverage %, uncovered lines, dead code candidates, public API surface
- **Test File**: A Test::Most test file in `t/` corresponding to a module; has attributes: file path, test count, coverage contributed, assertions
- **Coverage Report**: Output from Devel::Cover; has attributes: per-module metrics (statement %, branch %, condition %), uncovered line numbers, HTML visualization
- **Usage Analysis**: Report of method/function call sites; has attributes: method name, call count, call locations, potentially unused flag
- **Coverage Gap**: Documented explanation for untested code; has attributes: module, line numbers, reason for exclusion, reviewer approval

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All 15 modules achieve the highest possible statement coverage, with no module below 90% (currently only 5/15 meet this threshold)
- **SC-002**: All modules with conditional logic achieve the highest possible branch coverage, with no module below 90% (currently 59.3% average)
- **SC-003**: Zero modules remain below 80% total coverage, with each module maximized to its achievable level (currently Template/Plugin/Ovid.pm at 36.1%)
- **SC-004**: Usage analysis identifies and documents all potentially unused code across all modules
- **SC-005**: All untested code (the remaining <10% in each module) has documented justification
- **SC-006**: Full test suite completes successfully in under 60 seconds
- **SC-007**: Coverage reports can be regenerated on-demand in under 2 minutes
- **SC-008**: Every module has a corresponding test file using Test::Most
- **SC-009**: All test files use consistent testing practices with Test::Most
- **SC-010**: Refactoring can begin with confidence that regressions will be caught by tests

### Business Value

- **Reduced risk**: Refactoring a well-tested codebase reduces the chance of breaking production
- **Faster iterations**: High coverage enables confident, rapid code changes
- **Knowledge transfer**: Comprehensive tests serve as executable documentation for future maintainers
- **Quality baseline**: Establishes testing discipline for all future code changes

## Assumptions *(mandatory)*

- Test coverage will be measured using Devel::Cover as it's the standard Perl coverage tool
- **90% coverage is an absolute minimum requirement** - exceptions are rare and require explicit justification with documented evidence that remaining code is truly unreachable (e.g., platform-specific code on different OS, deprecated code with removal date)
- Branch/condition coverage targets of 90% apply where conditional logic exists
- Unused code determination will use static analysis (grep, IDE search) plus developer judgment - some seemingly unused code may be called dynamically
- The current test suite runs and passes - we're adding to existing tests, not fixing broken ones
- Test files will be enhanced incrementally, module-by-module, rather than all at once
- SQLite database for testing can be populated with fixture data for integration tests
- Template Toolkit rendering can be tested by comparing output HTML against expected fixtures
- **Coverage exceptions below 90% must be documented in coverage-exceptions.md with specific technical justification** - "highest possible coverage" does not mean accepting low coverage without exhaustive testing effort
- POD documentation coverage is tracked separately and not part of the 90% requirement
- The refactoring phase (after testing) is out of scope for this specification

## Scope *(mandatory)*

### In Scope

- Analysis of all 15 modules listed in the coverage report
- Writing new Test::Most tests for uncovered code
- Enhancing existing Test::Most tests
- Documenting unused code and coverage gaps
- Generating comprehensive coverage reports
- Testing of build process modules (Ovid::Site, Ovid::Template::*)
- Testing of utility modules (Less::*, Template::Plugin::*)
- Testing error conditions and edge cases

### Out of Scope

- Actual refactoring of modules (comes after testing phase)
- Rewriting modules to be more testable (architecture changes deferred)
- Removing dead code (only identifying and documenting it)
- Performance optimization of tests or modules
- Testing of `bin/` scripts (CLI testing is separate effort)
- Testing of Template Toolkit templates in `root/` and `include/`
- Generated HTML output testing (covered by integration tests)
- Database schema changes or migration testing
- Adding new features or changing behavior
- Fixing bugs discovered during testing (document for separate tickets)
- POD documentation improvements

## Dependencies *(mandatory)*

- Devel::Cover must be installed and functional
- Test::Most must be available
- Existing test infrastructure (database fixtures, test utilities) must be working
- Access to production-like test data for realistic testing
- Ability to run tests in isolation without affecting development database

## Constraints *(mandatory)*

- Must maintain backward compatibility - no API changes during testing phase
- Tests must run successfully on Perl 5.40+ (per constitution)
- No new module dependencies unless absolutely necessary for testing
- Test files must follow existing project conventions (file naming, structure)
- Coverage improvements must not slow down test suite significantly (target: <60 sec total)
- Module-by-module approach prevents "big bang" testing that's hard to review
- **Production data protection (Constitution VI)**: Tests MUST NOT modify files in `db/` directory
  - All database-dependent tests must use read-only operations or test fixtures in `t/fixtures/`
  - Running test suite must leave `db/` directory unchanged (verifiable via `git status`)
  - Use File::Temp or test-specific databases for any write operations needed in tests

## Risks *(mandatory)*

- **Risk**: Unused code is actually called dynamically (via string eval, dispatch tables) and static analysis misses it
  - **Mitigation**: Review seemingly unused code carefully; run full integration tests before marking as dead
  
- **Risk**: Some modules are tightly coupled and difficult to test in isolation
  - **Mitigation**: Use mocking techniques or dependency injection; document coupling as technical debt
  
- **Risk**: Achieving 90% coverage on legacy code reveals significant bugs that need fixing
  - **Mitigation**: Document bugs separately; focus on testing current behavior, not fixing it
  
- **Risk**: Template Toolkit integration makes some code paths hard to test without full rendering
  - **Mitigation**: Create minimal template fixtures; test template processing logic separately from rendering
  
- **Risk**: Coverage targets may not be achievable for some modules without significant refactoring
  - **Mitigation**: Document exceptions; aim for "best achievable coverage" with justification

## Open Questions

*None - all requirements are sufficiently specified for implementation.*
