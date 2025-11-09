# Research: Test Coverage Improvement

**Date**: 2025-11-09  
**Feature**: 001-test-coverage-improvement  
**Researcher**: speckit.plan workflow

## Findings

### Unknown: Best practices for identifying unused code in Perl modules

**Decision**: Use combination of static analysis (grep for method calls) and dynamic analysis (Devel::Cover subroutine coverage), supplemented by developer review for dynamic calls.

**Rationale**: Static analysis catches obvious unused methods, dynamic analysis via coverage shows what's actually executed during tests. Developer judgment needed for eval'd code or dynamic method calls.

**Alternatives Considered**:
- Pure static analysis (PPI parser) - rejected because misses dynamic calls.
- Runtime tracing only - rejected because doesn't identify unused code without full execution paths.

### Unknown: Strategies for testing tightly coupled legacy code

**Decision**: Use dependency injection and mocking techniques (Test::MockModule, Test::MockObject) for external dependencies (filesystem, database, network), create fixture data for deterministic testing.

**Rationale**: Allows isolated unit testing without changing architecture. Fixtures ensure reproducible tests.

**Alternatives Considered**:
- Integration testing only - rejected because slower and less reliable.
- Refactor for testability first - out of scope per spec.

### Unknown: Handling XS code or platform-specific code in coverage

**Decision**: Document as untestable if truly platform-specific, aim for 100% coverage on pure Perl code. Use conditional compilation checks.

**Rationale**: XS code can't be unit tested easily, but pure Perl parts can. Documentation ensures transparency.

**Alternatives Considered**:
- Skip coverage entirely - violates 90% minimum.
- Mock XS calls - complex and unreliable.

### Unknown: Testing Template Toolkit rendering

**Decision**: Test by comparing rendered output HTML against expected fixtures, using Test::Most's comparison functions for structured comparison.

**Rationale**: TT rendering is deterministic, fixtures provide clear expectations.

**Alternatives Considered**:
- Manual inspection - not automated.
- Skip TT testing - violates coverage requirements.

### Unknown: Error condition testing for build processes

**Decision**: Simulate failures by mocking file operations, invalid inputs, and dependency failures using Test::Most's exception testing functions (throws_ok, dies_ok).

**Rationale**: Ensures robustness without destructive testing.

**Alternatives Considered**:
- Live failure testing - risky for production code.

### Unknown: Branch coverage for complex conditionals

**Decision**: Use Test::Most's subtest functionality to create separate test cases for each branch path, ensuring all true/false combinations are covered.

**Rationale**: Explicit testing of logic paths catches edge cases.

**Alternatives Considered**:
- Random input testing - less thorough.

### Unknown: Performance impact of coverage testing

**Decision**: Run coverage only during CI/development, not production builds. Use Devel::Cover's selective coverage options.

**Rationale**: Coverage slows execution, but acceptable for testing phase.

**Alternatives Considered**:
- Always-on coverage - too slow for builds.

### Unknown: Documentation of coverage gaps

**Decision**: Use inline TODO comments for uncovered code, with justification. Maintain separate coverage-gap.md if needed.

**Rationale**: Keeps documentation close to code.

**Alternatives Considered**:
- External docs only - harder to maintain.
