# Branch Coverage Exceptions

**Created**: 2025-11-09  
**Feature**: 001-test-coverage-improvement  
**Purpose**: Document branches that cannot reach 90%+ coverage with justification

## Overview

This document tracks modules where achieving 90%+ branch coverage is not feasible due to untestable edge cases, infrastructure limitations, or where the cost of testing exceeds the benefit.

## Modules Below 90% Branch Coverage

### Less/Script.pm (75.0% branch coverage)

**Status**: Maximum achievable coverage - documented exception

**Uncovered Branches**:

1. **Line 106: DBI Connection Failure** (50% - F branch not covered)
   ```perl
   state $dbh = DBI->connect("dbi:SQLite:dbname=db/ovid.db", "", "") 
     or croak("Could not find database handle: $DBI::errstr");
   ```
   
   **Justification**: 
   - This branch tests database connection failure, which only occurs when:
     - Database file is missing/corrupted
     - Permissions are denied  
     - SQLite driver is not installed
   - Testing this requires either:
     - Mocking DBI->connect (violates "avoid mocking database operations" per constitution)
     - Corrupting/deleting the production database file (destructive)
     - Creating an invalid database path (requires code modification)
   - **Risk assessment**: Low - database connection failures are immediately apparent on application startup
   - **Alternative coverage**: Manual testing during deployment validates this path
   
   **Recommendation**: Accept 75% branch coverage as maximum achievable per testing philosophy

---

### Less/Pager.pm (85.0% branch coverage)

**Status**: Maximum achievable coverage - documented exception

**Uncovered Branches**:

1. **Line 85: Empty Records Array** (50% - F branch not covered)
   ```perl
   $self->_set_page_number( $self->current_page_number + 1 ) if @$records;
   ```
   
   **Justification**:
   - This branch handles the case where database query returns empty results
   - Protected by guard clause at line 69: `return if $self->_current_offset >= $self->total;`
   - Only reachable if:
     - Race condition: records deleted between total() calculation and query
     - Database inconsistency: total() and query return different results
     - SQL query logic error (would be caught in integration testing)
   - Testing requires either:
     - Mocking database to return empty results (violates constitution)
     - Deleting records mid-test (creates test pollution)
     - Forcing race condition (non-deterministic, fragile)
   - **Risk assessment**: Very low - protected by guard clause
   - **Alternative coverage**: Integration tests verify pagination consistency

2. **Line 111: Database Query Failure in _get_prev_next** (50% - T branch not covered)
   ```perl
   $result = dbh()->selectall_arrayref(...) or return;
   ```
   
   **Justification**:
   - Tests database query failure when finding prev/next post
   - Only fails if:
     - Database connection lost mid-operation
     - SQL syntax error (caught in integration tests)  
     - Table schema changes (caught in integration tests)
   - Testing requires mocking database (violates constitution)
   - **Risk assessment**: Low - failures are immediate and obvious
   - **Alternative coverage**: Integration tests validate prev/next navigation

3. **Line 135: Database Query Failure in this_post** (50% - T branch not covered)  
   ```perl
   my $result = dbh()->selectall_arrayref(...) or return;
   ```
   
   **Justification**:
   - Same as line 111 - database query failure scenario
   - Testing requires mocking (violates constitution)
   - **Risk assessment**: Low - failures are immediate and obvious
   - **Alternative coverage**: Integration tests validate post retrieval

**Recommendation**: Accept 85% branch coverage as maximum achievable per testing philosophy

---

## Summary

| Module | Branch Coverage | Target | Status | Uncovered Branches | Justification |
|--------|----------------|--------|--------|-------------------|---------------|
| Less/Script.pm | 75.0% | 90% | Exception | 1 (DBI failure) | Requires mocking or destructive tests |
| Less/Pager.pm | 85.0% | 90% | Exception | 3 (DB failures, race condition) | Requires mocking or non-deterministic tests |

**Total Modules with Exceptions**: 2 of 15 (13.3%)  
**Modules at 90%+**: 13 of 15 (86.7%)

## Alternative Risk Mitigation

While these branches cannot be unit tested without violating project testing principles, they are covered by:

1. **Integration Tests**: Full database operations in t/integration/
2. **Manual Testing**: Deployment and smoke tests catch connection failures
3. **Error Monitoring**: Production logs would immediately show these errors
4. **Fast Failure**: All uncovered branches fail fast and obviously
5. **Guard Clauses**: Protective checks (like line 69 in Pager.pm) prevent edge cases

## Conclusion

The uncovered branches represent:
- Infrastructure failure scenarios (database connection)
- Race conditions protected by guard clauses  
- Error paths that fail fast and obviously

Achieving 90%+ branch coverage on these modules would require:
- Violating "minimize mocking" principle
- Writing fragile, non-deterministic tests
- Corrupting test data or production databases

**Decision**: Accept current coverage levels as maximum achievable within project constraints.

---

*Last Updated*: 2025-11-09  
*Next Review*: When database infrastructure changes or new testing tools become available
