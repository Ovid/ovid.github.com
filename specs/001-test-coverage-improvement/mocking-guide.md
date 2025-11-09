# Mocking Guide for Test Coverage

**Created**: 2025-11-09  
**Feature**: 001-test-coverage-improvement

## Philosophy: Minimize Mocking

Per the project constitution and testing best practices, **mocking should be minimized** and used only when necessary. The majority of tests should use real dependencies.

## When to Mock (Justified Cases)

Mock **ONLY** in these scenarios:

### 1. External Network APIs
**Justification**: Cannot rely on external services in tests (unreliable, slow, may cost money)

**Example**: AI image description API in `Ovid/Site/AI/Images.pm`

```perl
use Test::Most;
use Test::MockModule;

my $mock_lwp = Test::MockModule->new('LWP::UserAgent');
$mock_lwp->mock('post', sub {
    return HTTP::Response->new(
        200, 'OK',
        ['Content-Type' => 'application/json'],
        '{"description": "A test image"}'
    );
});

# Now test the module's error handling and data processing
# without making actual API calls
```

### 2. Non-Deterministic Behavior
**Justification**: Tests must be reproducible

**Example**: Current timestamp, random values

```perl
use Test::MockModule;

my $mock_time = Test::MockModule->new('Time::HiRes');
$mock_time->mock('time', sub { return 1699564800; }); # Fixed timestamp

# Test time-dependent logic with predictable results
```

### 3. Destructive Operations in Production Code
**Justification**: Cannot safely test file deletion, database drops, etc.

**Example**: File system operations that could damage the repository

```perl
use Test::MockModule;

my $mock_file = Test::MockModule->new('File::Path');
$mock_file->mock('remove_tree', sub {
    # Don't actually delete anything
    return 1;
});

# Test error handling without destroying files
```

## When NOT to Mock

### ❌ Database Operations
**Use real test database** (`t/fixtures/test.db`) instead.

```perl
# WRONG: Mocking database
my $mock_dbi = Test::MockModule->new('DBI');
$mock_dbi->mock('connect', sub { ... });

# RIGHT: Use test fixture
my $dbh = DBI->connect("dbi:SQLite:dbname=t/fixtures/test.db", "", "");
```

### ❌ File System Reads
**Use real test fixtures** in `t/fixtures/` instead.

```perl
# WRONG: Mocking file reads
my $mock_file = Test::MockModule->new('File::Slurp');

# RIGHT: Use fixture files
my $content = read_file('t/fixtures/data/sample.txt');
```

### ❌ Template Toolkit Rendering
**Use real TT objects** with fixture templates.

```perl
# WRONG: Mocking Template Toolkit
my $mock_tt = Test::MockModule->new('Template');

# RIGHT: Use real Template with fixture
use Template;
my $tt = Template->new({
    INCLUDE_PATH => 't/fixtures/templates',
});
```

### ❌ Internal Module Dependencies
**Use real module instances** unless they have external dependencies.

```perl
# WRONG: Mocking internal modules
my $mock_utils = Test::MockModule->new('Ovid::Site::Utils');

# RIGHT: Use real module
use Ovid::Site::Utils;
my $utils = Ovid::Site::Utils->new();
```

## Test::MockModule Usage

Test::MockModule is the preferred mocking tool for this project.

### Basic Usage

```perl
use Test::Most;
use Test::MockModule;

# Create a mock for an existing module
my $mock = Test::MockModule->new('Some::Module');

# Mock a specific method
$mock->mock('method_name', sub {
    my ($self, @args) = @_;
    return "mocked result";
});

# Restore original behavior
$mock->unmock('method_name');

# Or restore all at once
undef $mock;
```

### Partial Mocking

```perl
# Mock only specific methods, others work normally
my $mock = Test::MockModule->new('Ovid::Site::AI::Images', no_auto => 1);

# Only mock the external API call
$mock->mock('_call_ai_api', sub {
    return { description => 'Test description' };
});

# All other methods work normally
my $images = Ovid::Site::AI::Images->new();
$images->describe_image('test.jpg'); # Uses real code except _call_ai_api
```

### Mocking Class Methods

```perl
my $mock = Test::MockModule->new('Some::Module');

$mock->mock('class_method', sub {
    my ($class, @args) = @_;
    return "mocked";
});
```

## Test::MockObject Usage

Use Test::MockObject when you need a fake object instance.

```perl
use Test::MockObject;

# Create a mock object
my $mock_obj = Test::MockObject->new();

# Set up method behaviors
$mock_obj->mock('method_name', sub { return 'result' });

# Set return values
$mock_obj->set_always('simple_method', 'value');
$mock_obj->set_series('changing_method', 1, 2, 3);

# Track method calls
$mock_obj->set_true('method_that_returns_true');
$mock_obj->called_ok('method_name');
```

## Documentation Requirements

When using mocks in tests, **MUST document the justification**:

```perl
subtest 'AI image description with mocked API' => sub {
    # MOCK JUSTIFICATION: External AI API cannot be called in tests
    # - Requires API key and credits
    # - Unreliable network dependency
    # - Slow response times
    my $mock_api = Test::MockModule->new('LWP::UserAgent');
    $mock_api->mock('post', sub { ... });
    
    # Test the module's error handling and data processing
};
```

## Testing Strategy Document

All mocking decisions should be documented in:
`specs/001-test-coverage-improvement/test-strategies.md`

Include:
- Which modules use mocking
- Which methods are mocked
- Justification for each mock
- Alternative approaches considered

## Validation

Before adding a mock, ask:
1. Can I use a real test fixture instead?
2. Can I use a real test database instead?
3. Is this an external dependency I cannot control?
4. Is the operation non-deterministic?
5. Is the operation destructive?

If all answers are "no", **don't mock**.

## Examples by Module

### Ovid/Site/AI/Images.pm
**Justification**: Calls external AI API  
**Mock**: LWP::UserAgent HTTP requests  
**Alternative Rejected**: Real API calls (expensive, unreliable)

### Modules Using Database
**Justification**: N/A (use real test database)  
**Mock**: None  
**Alternative**: Use `t/fixtures/test.db`

### Template Rendering
**Justification**: N/A (use real templates)  
**Mock**: None  
**Alternative**: Use fixtures in `t/fixtures/templates/`

## Best Practices

1. **Mock at the boundary**: Mock external systems, not internal logic
2. **Keep mocks simple**: Complex mocks are a code smell
3. **Test the real code**: Mocks should test error handling, not business logic
4. **Document extensively**: Future maintainers need to understand why
5. **Prefer integration tests**: When possible, test with real dependencies
6. **Use fixtures over mocks**: Fixtures are more maintainable

## Anti-Patterns to Avoid

```perl
# ❌ BAD: Mocking everything
my $mock1 = Test::MockModule->new('Module1');
my $mock2 = Test::MockModule->new('Module2');
my $mock3 = Test::MockModule->new('Module3');

# ✅ GOOD: Use real dependencies
use Module1;
use Module2;
use Module3;
```

```perl
# ❌ BAD: Mocking implementation details
$mock->mock('_internal_method', sub { ... });

# ✅ GOOD: Test through public API
my $obj = Module->new();
$obj->public_method();
```

```perl
# ❌ BAD: Mocking without justification
my $mock = Test::MockModule->new('DBI');

# ✅ GOOD: Use test fixture
my $dbh = DBI->connect("dbi:SQLite:dbname=t/fixtures/test.db");
```

## Resources

- Test::MockModule CPAN docs: https://metacpan.org/pod/Test::MockModule
- Test::MockObject CPAN docs: https://metacpan.org/pod/Test::MockObject
- Project constitution: Prefer real dependencies over mocks
