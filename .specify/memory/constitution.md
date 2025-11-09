<!--
Sync Impact Report:
Version: 1.1.0 → 1.2.1
Modified Principles: Added VIII. Environment Setup, Expanded Compliance Verification
Added Sections: Environment Setup subsection under Development Workflow, Additional compliance requirements
Removed Sections: None
Templates Status:
  - ✅ .specify/templates/plan-template.md (no changes required)
  - ✅ .specify/templates/spec-template.md (no changes required)
  - ✅ .specify/templates/tasks-template.md (no changes required)
Follow-up TODOs:
  - Verify template files align with CPAN-style module structure
  - Add Test2::Suite coverage reporting to CI/CD if not present
  - Document CLI conventions in developer guidelines
  - Update AI agent prompts to reference git safety constraints
-->

# Ovid's Website Constitution

## Core Principles

### I. CPAN-Style Module Architecture (NON-NEGOTIABLE)

Every feature MUST be implemented as a proper CPAN-style module with:
- Clear namespace hierarchy under `Ovid::` or project-specific namespace
- Each module serves a single, well-defined purpose
- Full POD documentation including NAME, SYNOPSIS, DESCRIPTION, and METHODS
- Independent installability and testability
- Declared dependencies in `cpanfile` with minimum version requirements

**Rationale**: CPAN conventions ensure code reusability, maintainability, and align with Perl ecosystem best practices. Modules become portable assets that can be extracted, shared, or published independently.

### II. CLI-First Interface Design

All primary functionality MUST be accessible via command-line interface:
- Use `Getopt::Long` for argument parsing with clear option names
- Follow UNIX conventions: options via flags, data via stdin or file args
- Output to stdout (success/data), stderr (errors/warnings), with appropriate exit codes (0 = success, non-zero = failure)
- Support `--help` and `--version` flags for all scripts
- Provide both verbose and quiet modes where appropriate

**Rationale**: CLI interfaces enable automation, testing, composition with other tools, and align with the static site generation workflow. They provide a stable contract that doesn't depend on web services or GUI frameworks.

### III. Test2::Suite with 90%+ Coverage (NON-NEGOTIABLE)

Testing discipline MUST include:
- Minimum 90% test coverage across all modules
- Use Test2::Suite (Test2::V0, Test2::Tools::*) as the testing framework
- Test files in `t/` directory mirroring `lib/` structure
- Unit tests for all public methods and functions
- Integration tests for end-to-end workflows (build, pagination, RSS generation)
- Edge cases, error conditions, and failure modes explicitly tested
- Coverage reports generated and tracked (e.g., via Devel::Cover)

**Rationale**: Test2::Suite provides modern testing features superior to Test::More. High coverage ensures refactoring safety and catches regressions. Static site generators have deterministic outputs making them ideal for comprehensive testing.

### IV. Accessible HTML5 Static Output

Generated HTML MUST meet accessibility and web standards:
- Valid HTML5 markup (validate with validator.w3.org or Nu HTML Checker)
- Semantic HTML elements (`<article>`, `<nav>`, `<header>`, etc.)
- WCAG 2.1 Level AA compliance minimum
- Proper heading hierarchy (no skipped levels)
- Alt text for all images
- Keyboard navigable interfaces
- Responsive design supporting mobile, tablet, desktop viewports
- No JavaScript required for core content access

**Rationale**: Accessibility is a moral and legal requirement. Static HTML ensures maximum compatibility, performance, and longevity. Semantic markup improves SEO and enables assistive technologies.

### V. Zero External Service Dependencies

The build and deployment process MUST NOT require:
- External API calls during build (except for explicit opt-in features like search indexing)
- Cloud services for core functionality
- Third-party CDNs for essential assets (JavaScript, CSS, fonts)
- Database servers during runtime (SQLite for build-time data is acceptable)
- Authentication to external services for standard operations

**Rationale**: External dependencies introduce failure points, latency, privacy concerns, and vendor lock-in. Static sites should build offline and deploy anywhere. This ensures reliability, reproducibility, and control.

### VI. Modern Perl 5.40+ Features Preferred

Code style and language features MUST prioritize:
- Perl 5.40+ features: signatures (`sub foo ($x, $y)`), `isa` operator, field syntax
- `use v5.40;` or higher in all new modules
- Postfix dereferencing (`$hashref->%*`, `$arrayref->@*`)
- Subroutine signatures enabled (avoid prototypes)
- Prefer `try/catch` (Feature::Try or Try::Tiny) over eval blocks
- Type constraints via Type::Tiny for public APIs
- Avoid legacy syntax: no indirect object notation, no bareword filehandles

**Rationale**: Modern Perl features improve safety, readability, and maintainability. Signatures prevent parameter errors. Type constraints document and enforce contracts. This positions the codebase for long-term maintainability as Perl evolves.

### VII. AI Agent Safety Constraints (NON-NEGOTIABLE)

AI agents operating on this codebase MUST NOT execute destructive git operations:
- PROHIBITED: `git push --force`, `git push -f`, `git rebase`, `git reset --hard`, `git clean -fd`
- PROHIBITED: `git branch -D`, `git tag -d`, `git reflog expire`, `git gc --prune=now`
- PROHIBITED: Any git command with `--force`, `-f`, `--hard`, or destructive flags
- PROHIBITED: Direct modification of `.git/` directory contents
- ALLOWED: Read-only operations (`git status`, `git log`, `git diff`, `git branch -l`, `git ls-remote`)
- ALLOWED: Safe operations (`git fetch`, `git checkout`, `git branch`, `git commit`, `git add`)
- REQUIRED: When creating branches or commits, agents must inform the user and wait for confirmation if the operation could affect remote state

**Rationale**: AI agents can make mistakes in command construction or context interpretation. Destructive git operations can cause irrecoverable data loss, break collaboration workflows, and violate repository policies. Humans must retain ultimate control over repository history and remote state. Read-only and safe operations enable agents to gather context without risk.

## Quality Standards

### Code Organization

- Modules in `lib/` directory with proper namespace hierarchy
- Scripts in `bin/` directory as thin wrappers around module functionality
- Configuration in versioned files (YAML, JSON, or Perl data structures)
- Templates in `root/` and `include/` directories
- Static assets in `static/` directory (images, CSS, JS)
- Build artifacts in `tmp/` (excluded from version control)

### Documentation Requirements

Every module and script MUST include:
- POD documentation with clear examples
- Parameter descriptions including types and constraints
- Return value documentation
- Error conditions and exceptions documented
- Usage examples in SYNOPSIS section
- Inline comments for complex logic

### Performance Expectations

- Build process should complete in under 2 minutes for typical site sizes
- Incremental builds supported where possible
- Memory usage should scale linearly with content volume
- No memory leaks during repeated builds
- Generated HTML should be minified or optimized for production builds

## Development Workflow

### Adding New Features

1. Design feature as a module with clear API
2. Write tests first (Test2::Suite)
3. Implement module to pass tests
4. Add CLI interface if user-facing
5. Update documentation (POD + README if needed)
6. Verify test coverage meets 90% threshold
7. Run full build to ensure no regressions
8. Update `cpanfile` if new dependencies added

### Refactoring Guidelines

- Never reduce test coverage below 90%
- Run full test suite before and after
- Preserve public API contracts or version bump
- Document breaking changes in changelog
- Update dependent code and templates

### Dependency Management

- Minimize dependencies: evaluate necessity before adding
- Prefer core modules when functionality overlaps
- Pin minimum versions in `cpanfile` based on required features
- Avoid XS dependencies unless performance-critical
- Document dependency rationale in code comments

### Environment Setup

All development work MUST use the correct Perl environment:
- Run `source ~/.bash_profile` in every new terminal session to activate perlbrew
- This ensures Perl 5.40+ with required modules is available
- Verify with `perl -v` showing version 5.40 or higher
- Install missing modules via `cpanm` after environment activation

**Rationale**: Consistent environment prevents version conflicts and ensures all modern Perl features are available. Perlbrew provides isolated, reproducible development environments.

## Governance

### Constitution Authority

This constitution supersedes all other development practices, style guides, or conventions. When conflicts arise, constitution principles take precedence.

### Amendment Process

Amendments require:
1. Documented proposal with rationale
2. Impact assessment on existing code
3. Version bump according to semantic versioning:
   - **MAJOR**: Removing or fundamentally changing core principles
   - **MINOR**: Adding new principles or expanding existing ones
   - **PATCH**: Clarifications, wording improvements, non-semantic changes
4. Update of dependent templates and documentation
5. Migration plan if existing code affected

### Compliance Verification

All code changes MUST:
- Pass automated test suite with 90%+ coverage
- Follow module structure and CLI conventions
- Include accessibility validation for HTML changes
- Document dependencies and version requirements
- Maintain zero external service dependencies for core features
- Pass entire test suite before marking any task complete
- Format all code with perltidy using .perltidyrc in project root
- Adhere to additional compliance requirements as specified in the constitution

### Exception Handling

Deviations from constitution principles require:
- Explicit justification in code comments or commit messages
- Documentation of technical constraints preventing compliance
- Plan for eventual compliance if temporary deviation
- Review and approval for non-negotiable principles

**Version**: 1.2.1 | **Ratified**: 2025-11-09 | **Last Amended**: 2025-11-09
