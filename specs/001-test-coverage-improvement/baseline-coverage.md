# Baseline Coverage Metrics

**Generated**: 2025-11-09  
**Tool**: Devel::Cover 1.44  
**Command**: `cover -test && cover -report html -outputdir coverage-report`

## Overall Project Coverage

| Metric | Coverage | Notes |
|--------|----------|-------|
| **Statement** | 85.1% | Overall statement coverage |
| **Branch** | 61.8% | Overall branch coverage |
| **Condition** | 68.5% | Overall condition coverage |
| **Subroutine** | 89.5% | Overall subroutine coverage |
| **Pod** | 45.1% | Overall POD documentation coverage |
| **Total** | 81.3% | Overall weighted coverage |

## Module-by-Module Coverage (15 Target Modules)

Sorted from lowest to highest total coverage:

### Critical Coverage Gaps (Below 50%)

| Module | Statement | Branch | Condition | Subroutine | Pod | Total |
|--------|-----------|--------|-----------|------------|-----|-------|
| `lib/Template/Plugin/Ovid.pm` | 39.7% | 0.0% | 0.0% | 50.0% | 26.0% | **36.1%** |
| `lib/Ovid/Site/AI/Images.pm` | 46.1% | 0.0% | n/a | 72.7% | n/a | **47.7%** |

### Moderate Coverage Gaps (50-80%)

| Module | Statement | Branch | Condition | Subroutine | Pod | Total |
|--------|-----------|--------|-----------|------------|-----|-------|
| `lib/Ovid/Template/Role/Debug.pm` | 70.0% | 16.6% | n/a | 100.0% | n/a | **63.3%** |
| `lib/Less/Pager.pm` | 82.8% | 60.0% | n/a | 83.3% | 83.3% | **78.7%** |

### Near-Target Coverage (80-90%)

| Module | Statement | Branch | Condition | Subroutine | Pod | Total |
|--------|-----------|--------|-----------|------------|-----|-------|
| `lib/Ovid/Template/File.pm` | 87.5% | 65.6% | 72.7% | 100.0% | 0.0% | **82.9%** |
| `lib/Less/Boilerplate.pm` | 83.7% | n/a | n/a | 90.9% | n/a | **85.1%** |
| `lib/Less/Script.pm` | 88.2% | 50.0% | 33.3% | 92.8% | 100.0% | **86.1%** |
| `lib/Text/Markdown/Blog.pm` | 92.5% | 81.2% | 55.0% | 100.0% | 33.3% | **87.6%** |
| `lib/Ovid/Template/File/Collection.pm` | 95.5% | 58.3% | n/a | 100.0% | 66.6% | **88.2%** |

### Already Meeting Statement Target (90%+)

| Module | Statement | Branch | Condition | Subroutine | Pod | Total |
|--------|-----------|--------|-----------|------------|-----|-------|
| `lib/Ovid/Template/File/FindCode.pm` | 100.0% | 83.3% | 89.4% | 100.0% | 0.0% | **93.2%** |
| `lib/Less/Config.pm` | 100.0% | n/a | n/a | 100.0% | 0.0% | **94.7%** |
| `lib/Ovid/Site/Utils.pm` | 100.0% | 50.0% | n/a | 100.0% | 100.0% | **97.6%** |
| `lib/Ovid/Template/Role/File.pm` | 100.0% | n/a | n/a | 100.0% | n/a | **100.0%** |
| `lib/Ovid/Types.pm` | 100.0% | n/a | n/a | 100.0% | n/a | **100.0%** |
| `lib/Template/Plugin/Config.pm` | 100.0% | 100.0% | n/a | 100.0% | 100.0% | **100.0%** |

## Analysis Summary

### Coverage Distribution

- **Below 50% total**: 2 modules (13.3%)
- **50-80% total**: 2 modules (13.3%)
- **80-90% total**: 5 modules (33.3%)
- **90%+ total**: 6 modules (40.0%)

### Statement Coverage Distribution

- **Below 50%**: 1 module (6.7%)
- **50-80%**: 1 module (6.7%)
- **80-90%**: 4 modules (26.7%)
- **90%+**: 9 modules (60.0%)

### Branch Coverage Issues

Modules with 0% branch coverage (critical):
1. `lib/Template/Plugin/Ovid.pm` - 0.0%
2. `lib/Ovid/Site/AI/Images.pm` - 0.0%

Modules with low branch coverage (<50%):
1. `lib/Ovid/Template/Role/Debug.pm` - 16.6%
2. `lib/Less/Script.pm` - 50.0%
3. `lib/Ovid/Site/Utils.pm` - 50.0%

### Priority Targets for Improvement

**High Priority** (Statement coverage < 50%):
1. `lib/Template/Plugin/Ovid.pm` - 39.7% stmt, 0.0% branch
2. `lib/Ovid/Site/AI/Images.pm` - 46.1% stmt, 0.0% branch

**Medium Priority** (Statement coverage 50-90%):
1. `lib/Ovid/Template/Role/Debug.pm` - 70.0% stmt, 16.6% branch
2. `lib/Less/Pager.pm` - 82.8% stmt, 60.0% branch
3. `lib/Ovid/Template/File.pm` - 87.5% stmt, 65.6% branch
4. `lib/Less/Boilerplate.pm` - 83.7% stmt, n/a branch
5. `lib/Less/Script.pm` - 88.2% stmt, 50.0% branch
6. `lib/Text/Markdown/Blog.pm` - 92.5% stmt, 81.2% branch
7. `lib/Ovid/Template/File/Collection.pm` - 95.5% stmt, 58.3% branch

**Low Priority** (Already at 90%+ statement coverage, focus on branch):
1. `lib/Ovid/Template/File/FindCode.pm` - 100.0% stmt, 83.3% branch
2. `lib/Ovid/Site/Utils.pm` - 100.0% stmt, 50.0% branch

## Test Suite Performance

**Full test suite timing**: (To be measured with `time prove -l t/`)

## Next Steps

1. Run usage analysis on all 15 modules to identify unused code
2. Start with highest-priority gaps: `Template/Plugin/Ovid.pm` and `Ovid/Site/AI/Images.pm`
3. Systematically work through modules to achieve 90%+ statement coverage
4. Address branch coverage gaps after statement coverage targets are met
5. Document any untestable code with clear justification

## Coverage Report Location

- **HTML Report**: `coverage-report/coverage.html`
- **Database**: `cover_db/`
- **View Command**: Open `coverage-report/coverage.html` in a browser
