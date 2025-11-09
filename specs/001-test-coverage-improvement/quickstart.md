# Quickstart: Test Coverage Improvement

**Date**: 2025-11-09  
**Feature**: 001-test-coverage-improvement  
**Audience**: Developers working on legacy code testing

## Prerequisites

- Perl 5.40+ installed
- Devel::Cover installed (`cpanm Devel::Cover`)
- Test::Most installed (already in cpanfile)
- Project dependencies installed (`cpanm --installdeps .`)

## Workflow Overview

1. **Identify unused code** for each module
2. **Review current coverage** metrics
3. **Add comprehensive tests** using Test::Most
4. **Maximize coverage** to highest achievable level
5. **Document gaps** with justifications

## Step-by-Step Guide

### 1. Setup Coverage Environment

```bash
# Install coverage tools if needed
cpanm Devel::Cover

# Run initial coverage baseline
cover -test

# Generate HTML report
cover -report html -outputdir coverage-report
```

### 2. Analyze Module Usage

For each module in the coverage report:

```bash
# Check current coverage for specific module
cover -report html -outputdir coverage-report lib/Ovid/Site.pm

# Identify potentially unused methods (manual grep for now)
grep -r "method_name" lib/ bin/ t/ --include="*.pm" --include="*.pl"
```

### 3. Create/Update Test Files

Test files must mirror `lib/` structure in `t/`:

```bash
# For lib/Ovid/Site.pm, create t/Ovid/Site.t
touch t/Ovid/Site.t
```

Test file template:

```perl
use Test::Most;
use Ovid::Site;

# Test public methods
subtest 'build_site method' => sub {
    my $site = Ovid::Site->new(...);
    ok($site->build_site(), 'build_site succeeds');
    # Add more assertions...
};

done_testing;
```

### 4. Run Coverage for Module

```bash
# Run tests with coverage for specific module
cover -test t/Ovid/Site.t

# Check coverage improvement
cover -report text | grep "Ovid/Site.pm"
```

### 5. Iterate and Maximize

- Add tests for edge cases
- Mock external dependencies
- Test error conditions
- Aim for 90%+ statement coverage
- Maximize branch coverage

### 6. Document Gaps

For uncovered code, add comments:

```perl
# TODO: Cannot test this error condition - requires specific OS state
# Coverage Gap: Platform-specific code, approved by reviewer
```

## Common Patterns

### Testing File Operations

```perl
use Test::MockModule;

my $mock = Test::MockModule->new('Some::Module');
$mock->mock('open', sub { return 1 });
$mock->mock('print', sub { return 1 });
```

### Testing Database Operations

```perl
# Use fixtures in t/fixtures/
my $db_file = 't/fixtures/test.db';
# Populate with test data
```

### Testing Template Rendering

```perl
use Ovid::Template::File;
my $template = Ovid::Template::File->new(...);
my $output = $template->render({data => 'test'});
is($output, expected_html(), 'template renders correctly');
```

## Troubleshooting

- **Coverage not updating**: Clear cover_db/ and re-run
- **Tests failing**: Check Test::Most syntax and ensure all tests are compatible
- **Mocking issues**: Use Test::MockModule or Test::MockObject for complex objects
- **Slow runs**: Run coverage selectively during development

## Success Criteria

- All 15 modules >=90% statement coverage
- Branch coverage maximized
- Tests use Test::Most consistently
- Unused code documented
- Full test suite <60 seconds
