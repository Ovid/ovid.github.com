# Feature Specification: Fix UTF-8 Warnings in Single File Rebuild

**Feature Branch**: `005-utf8-rebuild-warnings`  
**Created**: 2025-11-18  
**Status**: Draft  
**Input**: User description: "Rebuilding a single file (bin/rebuild --file ...) generates UTF8 warnings that will actually break the web site. I don't know how to fix that."

## Clarifications

### Session 2025-11-18

- Q: How should the system respond when it encounters a template file with invalid UTF-8? → A: Fail immediately with clear error message indicating which file and what's wrong
- Q: Should new automated tests be added to verify UTF-8 handling and prevent future regressions? → A: Yes, add new tests that verify UTF-8 handling in single-file rebuilds
- Q: Should UTF-8 validation apply to all files during preprocessing or only the specific file being rebuilt? → A: Validate only the specific file being rebuilt (faster feedback)
- Q: Is any performance degradation acceptable for single-file rebuilds if it ensures correct UTF-8 handling? → A: Ignore performance

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Single File Rebuild Without Warnings (Priority: P1)

Developers need to rebuild individual template files during development without encountering UTF-8 encoding warnings that could indicate broken website output.

**Why this priority**: This is the core issue blocking effective development workflow. UTF-8 warnings indicate potential data corruption that could break the published website.

**Independent Test**: Can be fully tested by running `perl bin/rebuild --file root/blog/torturing-an-llm.tt2markdown --notest` and verifying no UTF-8 warnings appear in output while the generated HTML displays correctly with proper character encoding.

**Acceptance Scenarios**:

1. **Given** a template file containing UTF-8 characters (smart quotes, em dashes, etc.), **When** developer runs `bin/rebuild --file <path>` on that file, **Then** the command completes without "Parsing of undecoded UTF-8" warnings
2. **Given** a template file containing UTF-8 characters, **When** developer runs `bin/rebuild --file <path>`, **Then** the generated HTML file contains correctly encoded UTF-8 characters that display properly in browsers
3. **Given** any template file, **When** developer runs `bin/rebuild --file <path>`, **Then** no "Wide character in print" warnings appear in the output

---

### User Story 2 - Full Site Rebuild Remains Unaffected (Priority: P2)

The full site rebuild process must continue to work correctly without introducing any regressions while fixing the single-file rebuild.

**Why this priority**: We must not break existing functionality. Full rebuilds are the primary production deployment mechanism.

**Independent Test**: Can be tested by running `perl bin/rebuild` (without --file flag) and verifying the entire site builds successfully with proper UTF-8 handling and no warnings.

**Acceptance Scenarios**:

1. **Given** the codebase with UTF-8 fixes applied, **When** developer runs `bin/rebuild` without the --file flag, **Then** all pages are generated with correct UTF-8 encoding matching the previous behavior
2. **Given** the codebase with UTF-8 fixes applied, **When** developer runs `bin/rebuild`, **Then** no new UTF-8 warnings are introduced during the full build process

---

### Edge Cases

- System MUST validate UTF-8 encoding only for the specific file being rebuilt (not all preprocessed files) and fail immediately with clear error message when that file contains invalid UTF-8 sequences, indicating the specific file and nature of the encoding problem
- System MUST reject template files that include binary data or non-text content, providing clear guidance that only UTF-8 text templates are supported
- System MUST handle UTF-8 characters in file paths and directory names correctly, ensuring they are properly encoded throughout the build process

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST process template files with UTF-8 content without generating "Parsing of undecoded UTF-8" warnings from HTML::TokeParser::Simple
- **FR-002**: System MUST process template files without generating "Wide character in print" warnings from Template Toolkit
- **FR-003**: System MUST preserve correct UTF-8 character encoding in generated HTML output files
- **FR-004**: System MUST handle UTF-8 encoding consistently between single-file rebuilds (--file flag) and full site rebuilds
- **FR-005**: System MUST properly decode UTF-8 when passing string data to HTML parsing libraries
- **FR-006**: System MUST validate UTF-8 encoding of the specific file being rebuilt and fail immediately with descriptive error message when encountering invalid UTF-8 sequences, identifying the problematic file and location
- **FR-007**: System MUST include automated tests that verify correct UTF-8 handling during single-file rebuilds, including tests with various UTF-8 characters (smart quotes, em dashes, accented letters)

### Key Entities *(include if feature involves data)*

- **Template File**: Source `.tt` or `.tt2markdown` file containing UTF-8 encoded content with smart quotes, special characters, or non-ASCII text
- **Generated HTML**: Output HTML file that must preserve UTF-8 character encoding from source templates
- **Preprocessed Content**: Intermediate representation of template content after preprocessing but before Template Toolkit processing

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Running `bin/rebuild --file <any-template>` produces zero UTF-8-related warnings in terminal output
- **SC-002**: Generated HTML files from single-file rebuilds display all UTF-8 characters identically to full site rebuilds when viewed in browsers
- **SC-003**: All existing tests continue to pass without modification, confirming no regression in full rebuild functionality
- **SC-004**: UTF-8 characters (curly quotes, em dashes, accented letters, etc.) in template files appear correctly in final HTML output
- **SC-005**: New automated tests verify UTF-8 handling in single-file rebuilds and detect encoding-related regressions

## Technical Context *(mandatory)*

### Current Implementation

The system uses:
- Perl 5.40+ with UTF-8 string handling
- Template Toolkit 3.102+ invoked via `ttree` with `--encoding utf8` and `--binmode utf8`
- `slurp()` function that reads files with `:encoding(UTF-8)` layer
- `splat()` function that writes files with `:encoding(UTF-8)` layer
- HTML::TokeParser::Simple for parsing HTML content during preprocessing

### Warning Details

When running `perl bin/rebuild --file root/blog/torturing-an-llm.tt2markdown --notest`, the following warnings appear:

```
Parsing of undecoded UTF-8 will give garbage when decoding entities at 
/Users/ovid/perl5/perlbrew/perls/perl-5.40.0/lib/site_perl/5.40.0/darwin-2level/HTML/PullParser.pm line 82.

Wide character in print at 
/Users/ovid/perl5/perlbrew/perls/perl-5.40.0/lib/site_perl/5.40.0/darwin-2level/Template.pm line 204.
```

### Analysis

The warnings indicate a character encoding layer mismatch:
1. Files are read as UTF-8 character strings (decoded)
2. HTML::TokeParser::Simple expects either byte strings or needs explicit UTF-8 handling
3. Template Toolkit is outputting wide characters (decoded UTF-8) but the output stream may not be expecting them

### Constraints

- **CON-001**: No changes allowed to Template2/ directory (contains ttree utility)
- **CON-002**: Solution must work with existing Template Toolkit installation and configuration
- **CON-003**: Changes should be minimal and focused on encoding layer handling
- **CON-004**: Must maintain backward compatibility with existing template files

## Dependencies *(mandatory)*

### Internal Dependencies

- `Less::Script` module (provides `slurp()` and `splat()` functions)
- `Ovid::Template::File` module (preprocesses template files)
- `Text::Markdown::Blog` module (converts markdown with UTF-8 handling)
- `Ovid::Site` module (orchestrates build process)

### External Dependencies

- Template Toolkit 3.102+
- HTML::TokeParser::Simple (CPAN module)
- Perl 5.40+ with built-in Unicode support

## Assumptions *(mandatory)*

- **ASM-001**: All template files in the repository are validly encoded as UTF-8
- **ASM-002**: The full rebuild process (`bin/rebuild` without --file) currently handles UTF-8 correctly
- **ASM-003**: The warnings appear only during single-file rebuilds, not full rebuilds
- **ASM-004**: The issue is related to how preprocessed content is handled before Template Toolkit processing
- **ASM-005**: Developers have standard Unix-like terminal environments that properly display UTF-8
- **ASM-006**: Correctness of UTF-8 handling takes priority over performance for single-file rebuilds; any performance overhead from proper encoding handling is acceptable

## Out of Scope *(mandatory)*

- Converting the site to use different character encodings (UTF-8 is the standard)
- Upgrading or replacing Template Toolkit with alternative templating engines
- Modifying HTML::TokeParser::Simple or other CPAN dependencies
- Adding new preprocessing features beyond fixing the encoding warnings
- Retroactively fixing any existing UTF-8 corruption in published content

## Future Considerations *(optional)*

- Consider adding explicit encoding validation during template preprocessing
- Evaluate whether HTML::TokeParser::Simple could be replaced with a more modern HTML parser
- Add automated tests that verify UTF-8 handling across the build pipeline
- Document UTF-8 handling best practices for contributors adding new build features
