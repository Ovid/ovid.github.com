# Data Model: Test Coverage Improvement

**Date**: 2025-11-09  
**Feature**: 001-test-coverage-improvement  
**Designer**: speckit.plan workflow

## Entities

### Module Under Test

Represents a Perl module requiring coverage improvement.

**Attributes**:
- `file_path` (string): Absolute path to the module file (e.g., `lib/Ovid/Site.pm`)
- `current_coverage_pct` (float): Current statement coverage percentage (0.0-100.0)
- `uncovered_lines` (array<int>): Line numbers with uncovered code
- `dead_code_candidates` (array<string>): Method/function names potentially unused
- `public_api_surface` (array<string>): Public methods/functions to test
- `dependencies` (array<string>): External modules this module depends on
- `test_file_path` (string): Corresponding test file path (e.g., `t/Ovid/Site.t`)

**Relationships**:
- Has many `CoverageReport` entries
- Has one `UsageAnalysis`
- Has many `CoverageGap` entries

**Validation Rules**:
- `file_path` must exist and be readable
- `current_coverage_pct` >= 0.0 and <= 100.0
- `public_api_surface` must include all exported functions

### Test File

Represents a Test2::Suite test file corresponding to a module.

**Attributes**:
- `file_path` (string): Absolute path to the test file
- `test_count` (int): Number of test assertions/subtests
- `coverage_contributed` (float): Coverage percentage added by this test file
- `assertions` (array<string>): List of test assertion descriptions
- `framework` (string): Testing framework used (must be "Test2::Suite")

**Relationships**:
- Belongs to `Module Under Test`
- Contributes to `CoverageReport`

**Validation Rules**:
- `file_path` must mirror `lib/` structure in `t/`
- `framework` must be "Test2::Suite" (no Test::More)
- `test_count` > 0

### Coverage Report

Output from Devel::Cover analysis.

**Attributes**:
- `module_path` (string): Module being reported
- `statement_pct` (float): Statement coverage percentage
- `branch_pct` (float): Branch coverage percentage (nullable)
- `condition_pct` (float): Condition coverage percentage (nullable)
- `subroutine_pct` (float): Subroutine coverage percentage
- `pod_pct` (float): POD coverage percentage (nullable)
- `uncovered_line_numbers` (array<int>): Lines not executed
- `html_visualization_path` (string): Path to HTML coverage report

**Relationships**:
- Belongs to `Module Under Test`

**Validation Rules**:
- All percentages >= 0.0 and <= 100.0
- `statement_pct` >= 90.0 for completion
- `html_visualization_path` must be accessible

### Usage Analysis

Report of method/function call sites across the codebase.

**Attributes**:
- `method_name` (string): Name of the method/function analyzed
- `call_count` (int): Number of times called across codebase
- `call_locations` (array<string>): File paths and line numbers of calls
- `potentially_unused` (boolean): Flag if no calls found

**Relationships**:
- Belongs to `Module Under Test`

**Validation Rules**:
- `call_count` >= 0
- If `potentially_unused` true, `call_locations` empty

### Coverage Gap

Documented explanation for untested code.

**Attributes**:
- `module` (string): Module name
- `line_numbers` (array<int>): Affected line numbers
- `reason` (string): Justification for exclusion (e.g., "platform-specific code", "error handling for impossible state")
- `reviewer_approval` (boolean): Whether reviewed and approved

**Relationships**:
- Belongs to `Module Under Test`

**Validation Rules**:
- `reason` must be non-empty
- `reviewer_approval` required for acceptance

## State Transitions

### Module Under Test States
- `identified`: Initial state, coverage measured
- `analyzing_usage`: Checking for unused code
- `testing`: Adding test cases
- `maximizing_coverage`: Achieving highest possible coverage
- `documenting_gaps`: Recording justifications for remaining gaps
- `complete`: >=90% coverage, gaps documented

### Coverage Report States
- `initial`: Baseline measurement
- `updated`: After adding tests
- `final`: Maximum achievable coverage

## Data Flow

1. Load `Module Under Test` list from coverage report
2. For each module, generate `Usage Analysis`
3. Create/update `Test File` with Test2::Suite tests
4. Run tests to generate updated `Coverage Report`
5. Identify and document `Coverage Gap` entries
6. Validate all modules reach `complete` state
