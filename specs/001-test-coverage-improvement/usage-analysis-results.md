# Usage Analysis Results

**Date**: 2025-11-09  
**Feature**: 001-test-coverage-improvement  
**Analysis Tool**: bin/analyze-usage

## Executive Summary

Analyzed all 15 modules in the project to identify potentially unused code. This analysis scans the entire codebase (lib/, bin/, t/) to find method call sites for each public method defined in the modules.

**Key Findings**:
- Total modules analyzed: 15
- Detailed analysis reports stored in: `specs/001-test-coverage-improvement/analysis/`
- Several modules have potentially unused methods that should be reviewed before writing tests

## Analysis Methodology

The usage analysis tool:
1. Parses each module to extract public method definitions (non-private, i.e., not starting with `_`)
2. Searches all Perl files (*.pm, *.pl, *.t) for method call sites
3. Counts call frequency and records locations
4. Flags methods with zero calls as "potentially unused"

**Limitations**:
- Static analysis cannot detect dynamic method calls (e.g., via `$obj->$method_name`)
- Does not analyze Template Toolkit templates for method usage
- Method calls via string evaluation may not be detected

## Module-by-Module Findings

### 1. Template/Plugin/Ovid.pm (36.1% coverage)

**Location**: `analysis/Template-Plugin-Ovid.txt`

**Potentially Unused Methods** (11 methods):
- `image_type` - No calls found
- `tags` - No calls found
- `tags_for_url` - No calls found
- `tags_by_weight` - No calls found
- `has_articles_for_tag` - No calls found
- `name_for_tag` - No calls found
- `files_for_tag` - No calls found
- `title_for_tag_file` - No calls found
- `note` - No calls found
- `youtube` - No calls found
- `get_footnotes` - No calls found
- `has_footnotes` - No calls found

**Heavily Used Methods**:
- `new` - 43 calls (heavily used across codebase)
- Multiple tag-related methods appear unused but may be called from templates

**Recommendation**: Review tag-related methods to determine if they're called from Template Toolkit templates (not detected by static analysis) or if they're truly unused and can be safely removed.

### 2. Ovid/Site/AI/Images.pm (47.7% coverage)

**Location**: `analysis/Ovid-Site-AI-Images.txt`

**Public Methods**: 1 method
- `describe_image` - 1 call (used in Template/Plugin/Ovid.pm)

**Recommendation**: This module has minimal public API. Focus testing efforts on the single public method.

### 3. Ovid/Template/Role/Debug.pm (63.3% coverage)

**Location**: `analysis/Ovid-Template-Role-Debug.txt`

**Analysis Status**: Review analysis file for detailed findings.

### 4. Less/Pager.pm (78.7% coverage)

**Location**: `analysis/Less-Pager.txt`

**Potentially Unused Methods** (2 methods):
- `next` - No calls found
- `all` - No calls found

**Used Methods**:
- `total_pages` - 1 call
- `prev_post` - 4 calls
- `next_post` - 5 calls
- `this_post` - 1 call

**Recommendation**: The `next` method name suggests pagination functionality but isn't being used. May be dead code or an incomplete feature. The `all` method should be reviewed to determine if it's needed.

### 5. Ovid/Template/File.pm (82.9% coverage)

**Location**: `analysis/Ovid-Template-File.txt`

**Analysis Status**: Review analysis file for detailed findings.

### 6. Less/Boilerplate.pm (85.1% coverage)

**Location**: `analysis/Less-Boilerplate.txt`

**Analysis Status**: Review analysis file for detailed findings.

### 7. Less/Script.pm (86.1% coverage)

**Location**: `analysis/Less-Script.txt`

**Analysis Status**: Review analysis file for detailed findings.

### 8. Text/Markdown/Blog.pm (87.6% coverage)

**Location**: `analysis/Text-Markdown-Blog.txt`

**Analysis Status**: Review analysis file for detailed findings.

### 9. Ovid/Template/File/Collection.pm (88.2% coverage)

**Location**: `analysis/Ovid-Template-File-Collection.txt`

**Analysis Status**: Review analysis file for detailed findings.

### 10. Ovid/Template/File/FindCode.pm (93.2% coverage)

**Location**: `analysis/Ovid-Template-File-FindCode.txt`

**Analysis Status**: Review analysis file for detailed findings.

### 11. Less/Config.pm (94.7% coverage)

**Location**: `analysis/Less-Config.txt`

**Analysis Status**: Review analysis file for detailed findings.

### 12. Ovid/Site/Utils.pm (97.6% coverage)

**Location**: `analysis/Ovid-Site-Utils.txt`

**Analysis Status**: Review analysis file for detailed findings.

### 13. Ovid/Template/Role/File.pm (100.0% coverage)

**Location**: `analysis/Ovid-Template-Role-File.txt`

**Analysis Status**: Already at 100% coverage. Review analysis file to verify all methods are actually used.

### 14. Ovid/Types.pm (100.0% coverage)

**Location**: `analysis/Ovid-Types.txt`

**Note**: This module uses Type::Library and does not have traditional subroutine definitions. No methods detected by the analysis tool, which is expected.

### 15. Template/Plugin/Config.pm (100.0% coverage)

**Location**: `analysis/Template-Plugin-Config.txt`

**Analysis Status**: Already at 100% coverage. Review analysis file for method usage patterns.

## Summary Statistics

Based on initial review of analysis files:

- **High Priority for Review**: Template/Plugin/Ovid.pm (11 potentially unused methods)
- **Medium Priority**: Less/Pager.pm (2 potentially unused methods)
- **Low Priority**: Modules with 90%+ coverage already

## Next Steps

1. **Review potentially unused methods** in each module's analysis file
2. **Check Template Toolkit templates** for methods that static analysis missed
3. **Document decisions** in `unused-code-decisions.md`:
   - Methods to remove (dead code)
   - Methods to keep but not test (template-only usage)
   - Methods to test (active code)
4. **Add TODO comments** to source files for identified unused methods

## Analysis Files Reference

All detailed analysis results are stored in:
```
specs/001-test-coverage-improvement/analysis/
├── Less-Boilerplate.txt
├── Less-Config.txt
├── Less-Pager.txt
├── Less-Script.txt
├── Ovid-Site-AI-Images.txt
├── Ovid-Site-Utils.txt
├── Ovid-Template-File-Collection.txt
├── Ovid-Template-File-FindCode.txt
├── Ovid-Template-File.txt
├── Ovid-Template-Role-Debug.txt
├── Ovid-Template-Role-File.txt
├── Ovid-Types.txt
├── Template-Plugin-Config.txt
├── Template-Plugin-Ovid.txt
└── Text-Markdown-Blog.txt
```

## Recommendations for Testing Strategy

1. **Skip testing truly unused code**: If a method has no calls and serves no purpose, mark it for removal rather than testing
2. **Test Template-called methods**: Methods called only from templates should still be tested
3. **Prioritize high-value methods**: Focus testing on methods with multiple call sites (indicates important functionality)
4. **Consider integration tests**: For methods primarily called from templates, integration tests may be more valuable than unit tests

## Validation

Run the following command to regenerate analysis for any module:

```bash
bin/analyze-usage --module lib/Path/To/Module.pm --format text
```

Or with JSON output:

```bash
bin/analyze-usage --module lib/Path/To/Module.pm --format json
```
