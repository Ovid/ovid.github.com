# API Contract: Usage Analysis Interface

**Contract ID**: USAGE-001  
**Date**: 2025-11-09  
**Provider**: Custom usage analysis script (to be implemented)  
**Consumer**: Test Coverage Improvement Feature

## Overview

Defines the interface for analyzing method/function usage across the codebase to identify potentially unused code.

## Interface Definition

### Command Line Interface

```bash
analyze-usage.pl --module <path> [--output <file>]
```

**Parameters**:
- `--module <path>`: Path to module to analyze (required)
- `--output <file>`: Output file for report (optional, defaults to stdout)
- `--format <json|text>`: Output format (default: text)

**Output**: Report of method usage with call sites.

### Data Structure (JSON Format)

```json
{
  "module": "lib/Ovid/Site.pm",
  "methods": [
    {
      "name": "build_site",
      "call_count": 5,
      "call_locations": [
        "bin/build-site.pl:42",
        "t/Ovid/Site.t:15"
      ],
      "potentially_unused": false
    },
    {
      "name": "unused_method",
      "call_count": 0,
      "call_locations": [],
      "potentially_unused": true
    }
  ]
}
```

### Text Format

```
Module: lib/Ovid/Site.pm
Method: build_site
  Calls: 5
  Locations: bin/build-site.pl:42, t/Ovid/Site.t:15
  Status: used

Method: unused_method
  Calls: 0
  Locations: (none)
  Status: potentially unused
```

## Contract Obligations

### Provider (Usage Analysis Script)
- MUST scan all .pm and .pl files in lib/, bin/, t/
- MUST use static analysis (grep/regex) for method calls
- MUST handle dynamic calls with developer review flag
- MUST output in specified format
- MUST return exit code 0 on success, non-zero on error

### Consumer (Coverage Improvement)
- MUST run analysis before adding tests
- MUST review potentially unused methods
- MUST document decisions in code comments
- MUST not remove code without approval

## Error Handling

- Module file not found: Exit code 1, "Module not found"
- Parse errors: Exit code 2, "Failed to parse module"
- Output write failures: Exit code 3, "Cannot write output"

## Implementation Notes

- Use PPI or regex for parsing Perl code
- Handle method calls via ->, ::, and indirect notation
- Flag methods only called in tests as "test-only"
- Consider inheritance and role composition
