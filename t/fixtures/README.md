# Test Fixtures

This directory contains shared test data for the test suite.

## Structure

- `templates/` - Template Toolkit template fixtures for testing template rendering
- `markdown/` - Markdown file fixtures for testing blog/article parsing
- `data/` - General data files (JSON, text, etc.) for testing

## Usage

Test files can reference fixtures using relative paths:

```perl
use Test::Most;
use File::Spec;

my $fixture_file = File::Spec->catfile('t', 'fixtures', 'data', 'sample.txt');
```

## Guidelines

1. Keep fixtures minimal - only include data necessary for tests
2. Use descriptive filenames that indicate the fixture's purpose
3. Document complex fixtures with inline comments
4. Avoid large binary files unless absolutely necessary
5. Clean up any temporary files created during tests

## Maintenance

When adding new fixtures:
1. Place them in the appropriate subdirectory
2. Update this README if adding new categories
3. Ensure fixtures are version controlled (not in .gitignore)
4. Remove unused fixtures to prevent bloat
