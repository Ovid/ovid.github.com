# API Contract: Coverage Report Interface

**Contract ID**: COV-001  
**Date**: 2025-11-09  
**Provider**: Devel::Cover  
**Consumer**: Test Coverage Improvement Feature

## Overview

Defines the interface for coverage reporting used to measure and track test coverage improvements.

## Interface Definition

### Command Line Interface

```bash
cover -test [options]
```

**Parameters**:
- `-test`: Run test suite with coverage collection
- `-report html`: Generate HTML report
- `-outputdir <dir>`: Output directory for reports

**Output**: Coverage database in `cover_db/`, HTML reports in specified directory.

### Data Structure

Coverage data stored in `cover_db/structure` and `cover_db/runs/*`.

**Key Metrics**:
- `statement`: Percentage of statements executed
- `branch`: Percentage of branch paths executed
- `condition`: Percentage of conditions executed
- `subroutine`: Percentage of subroutines called
- `pod`: Percentage of POD executed (optional)

### File Format

HTML reports contain:
- Per-file coverage tables
- Line-by-line coverage indicators
- Summary statistics
- Uncovered line highlighting

## Contract Obligations

### Provider (Devel::Cover)
- MUST generate accurate coverage metrics
- MUST support HTML output format
- MUST handle Test::Most tests
- MUST provide line-level granularity

### Consumer (Coverage Improvement)
- MUST run `cover -test` to collect data
- MUST parse HTML reports for metrics
- MUST use coverage data to identify gaps
- MUST regenerate reports after test changes

## Error Handling

- Invalid test files: Exit code 1, error message to stderr
- Coverage collection failures: Exit code 2, detailed error
- Report generation failures: Exit code 3, error details

## Version Compatibility

- Devel::Cover 1.36+ required
- Compatible with Perl 5.40+
- Test::Most integration verified
