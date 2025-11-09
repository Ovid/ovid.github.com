# Integration Tests

This directory contains integration tests that validate end-to-end functionality across multiple modules.

## Purpose

Integration tests verify that components work together correctly, complementing the unit tests in `t/*.t`. These tests:

- Test interactions between multiple modules
- Validate database operations with test fixtures
- Verify Template Toolkit integration
- Test command-line scripts with real file I/O
- Ensure build process components work together

## Structure

Integration tests are organized by feature area:

```
t/integration/
├── README.md                  # This file
├── 01-foundation.t            # Tests for foundational infrastructure (Phase 2)
├── 02-unused-code-analysis.t  # Tests for User Story 1 (usage analysis)
├── 03-statement-coverage.t    # Tests for User Story 2 (statement coverage validation)
├── 04-branch-coverage.t       # Tests for User Story 3 (branch coverage validation)
└── 05-documentation.t         # Tests for User Story 4 (documentation completeness)
```

## Running Integration Tests

```bash
# Run all integration tests
prove -l t/integration/

# Run specific integration test
prove -l t/integration/01-foundation.t

# Run with verbose output
prove -lv t/integration/
```

## Test Fixtures

Integration tests use fixtures from `t/fixtures/`:
- `t/fixtures/test.db` - SQLite database with test data
- `t/fixtures/templates/` - Template Toolkit template files
- `t/fixtures/markdown/` - Markdown test files
- `t/fixtures/data/` - General test data files

## Guidelines

### When to Write Integration Tests

Write integration tests when:
1. Testing requires multiple modules working together
2. Testing database operations (use test.db fixture)
3. Testing template rendering with real TT objects
4. Validating command-line scripts end-to-end
5. Verifying user story completion criteria

### When to Write Unit Tests

Write unit tests (in `t/*.t`) when:
1. Testing a single module's behavior
2. Testing pure logic without external dependencies
3. Testing error conditions with mocking
4. Achieving coverage targets for specific modules

### Test Design Principles

1. **Isolation**: Each test should be independent and can run in any order
2. **Cleanup**: Tests should clean up any temporary files/data created
3. **Fixtures**: Use shared fixtures from `t/fixtures/`, don't duplicate data
4. **Speed**: Keep integration tests fast; mock slow operations when possible
5. **Clarity**: Use descriptive subtest names that explain what's being validated

## User Story Validation

Each user story has a corresponding integration test that validates completion:

### User Story 1: Identify Unused Code
**Test**: `02-unused-code-analysis.t`
**Validates**:
- bin/analyze-usage script works correctly
- Analysis produces accurate results
- Unused code is documented

### User Story 2: Statement Coverage
**Test**: `03-statement-coverage.t`
**Validates**:
- All 15 modules reach 90%+ statement coverage
- Coverage reports are accurate
- Test suite runs in under 60 seconds

### User Story 3: Branch Coverage
**Test**: `04-branch-coverage.t`
**Validates**:
- Modules with conditionals reach 90%+ branch coverage
- All conditional paths are tested
- Edge cases are covered

### User Story 4: Documentation
**Test**: `05-documentation.t`
**Validates**:
- Coverage gaps are documented
- Unused code decisions are recorded
- Test strategies are explained
- Developer guide exists

## Example Integration Test

```perl
use Test::Most;
use File::Spec;
use DBI;

# Test database fixture
my $test_db = File::Spec->catfile('t', 'fixtures', 'test.db');
my $dbh = DBI->connect("dbi:SQLite:dbname=$test_db", "", "")
    or die "Cannot connect to test database: $DBI::errstr";

subtest 'Database integration' => sub {
    my $sth = $dbh->prepare("SELECT COUNT(*) FROM articles");
    $sth->execute();
    my ($count) = $sth->fetchrow_array();
    
    cmp_ok($count, '>', 0, 'Test database has articles');
};

done_testing;
```

## Maintenance

When modifying integration tests:
1. Update this README if adding new test categories
2. Ensure tests clean up after themselves
3. Keep test fixtures minimal and focused
4. Document complex test scenarios
5. Verify all integration tests pass before committing

## Performance Targets

- Individual integration tests: < 5 seconds each
- Full integration suite: < 30 seconds total
- Combined with unit tests: < 60 seconds total

## Continuous Integration

Integration tests are part of the standard test suite and run with:

```bash
prove -l t/
```

This includes both unit tests (`t/*.t`) and integration tests (`t/integration/*.t`).
