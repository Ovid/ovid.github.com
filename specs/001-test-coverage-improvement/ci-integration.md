# Coverage CI/CD Integration Recommendations

**Feature**: 001-test-coverage-improvement  
**Date**: 2025-11-09  
**Status**: Implementation Complete

## Overview

This document provides recommendations for integrating test coverage into CI/CD pipelines to maintain the achieved 93.3% overall coverage and ensure new code meets quality standards.

## Coverage Metrics Achieved

- **Statement Coverage**: 97.2%
- **Branch Coverage**: 73.7%
- **Condition Coverage**: 71.2%
- **Subroutine Coverage**: 99.0%
- **Pod Coverage**: 44.2%
- **Overall Coverage**: 93.3%

## Recommended CI/CD Workflow

### 1. GitHub Actions Workflow

Create `.github/workflows/coverage.yml`:

```yaml
name: Test Coverage

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  coverage:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Perl
      uses: shogo82148/actions-setup-perl@v1
      with:
        perl-version: '5.40'
    
    - name: Install dependencies
      run: |
        cpanm --installdeps . --notest
        cpanm Devel::Cover Devel::Cover::Report::Coveralls
    
    - name: Run tests with coverage
      run: |
        cover -test -report coveralls
    
    - name: Upload coverage to Coveralls
      env:
        COVERALLS_REPO_TOKEN: ${{ secrets.COVERALLS_TOKEN }}
      run: |
        cover -report coveralls
    
    - name: Check coverage thresholds
      run: |
        perl -MDevel::Cover::Report::Text -e '
          my $db = Devel::Cover::DB->new(db => "cover_db");
          my $total = $db->summary->{Total};
          my $stmt = $total->{statement}{percentage};
          my $branch = $total->{branch}{percentage};
          
          die "Statement coverage $stmt% below 90% threshold" if $stmt < 90;
          die "Branch coverage $branch% below 70% threshold" if $branch < 70;
          
          print "✓ Coverage meets thresholds\n";
        '
```

### 2. Coverage Quality Gates

#### Minimum Thresholds (Enforce in CI)

- **Statement Coverage**: ≥ 90%
- **Branch Coverage**: ≥ 70%
- **Subroutine Coverage**: ≥ 95%

#### Warning Thresholds (Report but Don't Fail)

- **Statement Coverage**: < 95%
- **Branch Coverage**: < 80%
- **Condition Coverage**: < 70%

### 3. Pull Request Checks

Add coverage diff reporting for PRs:

```yaml
- name: Coverage diff
  run: |
    # Compare coverage before/after changes
    git fetch origin main
    git checkout origin/main
    cover -test -silent
    mv cover_db cover_db_main
    
    git checkout ${{ github.sha }}
    cover -test -silent
    
    # Generate diff report
    cover -report diff -old cover_db_main
```

### 4. Local Development Integration

Add pre-commit hook in `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Run tests with coverage before commit

echo "Running tests with coverage..."
make test

if [ $? -ne 0 ]; then
    echo "❌ Tests failed. Commit aborted."
    exit 1
fi

# Optional: Check coverage on changed files only
echo "✓ All tests pass"
exit 0
```

### 5. Coverage Reporting Services

#### Option A: Coveralls.io

```bash
# Install
cpanm Devel::Cover::Report::Coveralls

# Generate report
cover -report coveralls

# Upload (requires COVERALLS_REPO_TOKEN)
cover -report coveralls -service travis-ci
```

#### Option B: Codecov

```bash
# Install
cpanm Devel::Cover::Report::Codecov

# Generate and upload
cover -report codecov
```

#### Option C: Self-Hosted (Current Setup)

```bash
# Generate HTML report
make coverage

# Copy to web-accessible location
rsync -av coverage-report/ /var/www/coverage/
```

## Maintenance Strategy

### Weekly Monitoring

```bash
# Generate coverage report
make coverage

# Check for coverage regressions
cover -report text | grep "Total" | awk '{print $8}'

# Alert if below threshold
```

### Monthly Review

1. Review uncovered lines in low-coverage modules
2. Update `coverage-exceptions.md` with new justified gaps
3. Identify testing opportunities in new code
4. Update coverage badge

### Per-Module Coverage Tracking

Create `.coveragerc` to track per-module minimums:

```ini
[coverage:modules]
Template::Plugin::Ovid = 95.0
Ovid::Site::AI::Images = 100.0
Ovid::Template::Role::Debug = 100.0
Less::Pager = 100.0
Ovid::Template::File = 100.0
Less::Boilerplate = 100.0
Less::Script = 100.0
Text::Markdown::Blog = 92.5
Ovid::Template::File::Collection = 95.5
Ovid::Template::File::FindCode = 100.0
Less::Config = 100.0
Ovid::Site::Utils = 100.0
Ovid::Template::Role::File = 100.0
Ovid::Types = 100.0
Template::Plugin::Config = 100.0
```

## Performance Targets

- **Test Execution**: < 60 seconds (Currently: ~4.6 seconds ✓)
- **Coverage Generation**: < 2 minutes
- **Full CI Pipeline**: < 5 minutes

## Alert Configuration

### Critical Alerts (Break the Build)

- Total statement coverage drops below 90%
- Any module drops below 85% statement coverage
- Test suite fails

### Warning Alerts (Notify but Don't Block)

- Total branch coverage drops below 70%
- New code has < 90% coverage
- Test execution time > 45 seconds

## Badge Integration

Add to README.md:

```markdown
[![Coverage](specs/001-test-coverage-improvement/coverage-badge.svg)](coverage-report/coverage.html)
```

Or use external service:

```markdown
[![Coverage Status](https://coveralls.io/repos/github/Ovid/ovid.github.com/badge.svg?branch=main)](https://coveralls.io/github/Ovid/ovid.github.com?branch=main)
```

## Makefile Targets for CI

The project includes these coverage-related make targets:

```bash
make test       # Run all tests
make coverage   # Generate full coverage report
make clean      # Remove coverage artifacts
```

## Troubleshooting

### Coverage Too Slow

```bash
# Run coverage on changed files only
cover -select_re '^lib/Ovid/Site/' -test

# Use faster HTML report
cover -report html_minimal
```

### Memory Issues

```bash
# Reduce memory usage
export DEVEL_COVER_OPTIONS='-ignore,^t/,-select,^lib/'
cover -test
```

### False Coverage Reports

```bash
# Clean and regenerate
make clean
make coverage
```

## References

- [Devel::Cover Documentation](https://metacpan.org/pod/Devel::Cover)
- [Test::Most Best Practices](https://metacpan.org/pod/Test::Most)
- [Coverage Report](../../coverage-report/coverage.html)
- [Usage Analysis](./usage-analysis-results.md)
- [Coverage Exceptions](./coverage-exceptions.md)
