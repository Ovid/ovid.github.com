# Coverage Exceptions and Justifications

**Feature**: Test Coverage Improvement (001)  
**Created**: 2025-11-09  
**Purpose**: Document code that cannot reach 90%+ coverage with justification

## Critical: Database Protection

### Template::Plugin::Ovid::describe_image() - Partial Coverage

**File**: `lib/Template/Plugin/Ovid.pm`  
**Method**: `describe_image()`  
**Coverage Gap**: Full flow with database writes cannot be unit tested  
**Justification**: **Production Database Protection (Constitution Violation Prevention)**

#### Issue
The `describe_image()` method calls `Ovid::Site::Utils::set_image_description()` which writes to the production database `db/ovid.db`. During test development, it was discovered that this method was modifying the production database, violating the project constitution requirement that tests must never modify production data.

#### Attempted Solutions
1. **Mocking Ovid::Site::Utils functions** - Failed because functions are imported via `use Ovid::Site::Utils qw(...)` into the `Template::Plugin::Ovid` namespace, so mocking the original module doesn't intercept the calls
2. **Mocking in Template::Plugin::Ovid namespace** - Fragile and requires deep knowledge of import mechanics
3. **DBI-level mocking** - Too invasive, would affect all database operations in test suite

#### Current Approach
- **Error path tested**: Verifies `describe_image()` croaks on non-existent files
- **Full flow skipped**: Database-writing code path is commented out with detailed explanation
- **Integration testing**: Full flow should be tested with test database in integration tests (`t/integration/`)

#### Test File
`t/ovid_plugin.t` lines 119-135

#### Code Coverage Impact
- Statement coverage: Reduces by ~3-5% for Template::Plugin::Ovid.pm
- This is acceptable given the critical requirement to protect production data

#### Recommendation
Create integration test in `t/integration/` that:
1. Uses a test database (not `db/ovid.db`)
2. Tests full `describe_image()` flow including database writes
3. Verifies database cleanup after test

## Other Exceptions

_(To be documented as identified during coverage improvement)_

