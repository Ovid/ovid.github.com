# Test Coverage Lift — Design

Date: 2026-05-17
Status: Approved, ready for implementation plan

## Goal

Raise unit-test coverage on the three weakest files in the codebase and produce
honest coverage numbers by excluding `t/*.t` files from the coverage report.

The goal is the coverage percentage, not regression-class prevention. (That
choice was deliberate; see "Out of scope" for what this work explicitly does
*not* try to address.)

## Targets

| File                       | Current | Target |
| -------------------------- | ------- | ------ |
| `lib/Ovid/Site.pm`         | 22.4 %  | ≥ 85 % |
| `lib/Ovid/Util/Image.pm`   | 17.6 %  | ≥ 90 % |
| `bin/review`               | 67.8 %  | ≥ 85 % |
| Overall (lib + bin, `t/` excluded) | ~84 %   | ≥ 90 % |

`lib/Ovid/Site.pm::_build_tinysearch` is the one explicit exception — it
shells out to the `tinysearch` and `wasm-pack` Rust binaries, which the
Makefile already isolates behind `make release` (commit `0609316f`). Covering
it would require those binaries in test environments. `Site.pm` clears the 85 %
target without it.

## Scope

In scope, in implementation order:

1. Makefile and CLAUDE.md update so `make cover` excludes `t/`.
2. `lib/Ovid/Site.pm` — pure functions, filesystem methods, DB-bound methods,
   and the `ttree`/`_assert_tt_config`/`_get_git_lastmod` external-process
   methods.
3. `lib/Ovid/Util/Image.pm` — full sweep of the `process` method.
4. `bin/review` — extend the existing `t/dev_server.t` to cover the fork-launch
   path and the remaining branches in the static handler.

## Test files

One file per concern. Existing tests stay in place.

### Site.pm

Split by tier so each file pays its setup cost once.

- **`t/site_pure_functions.t`** (new) — `_clean_text`, `_get_sitemap_priority`,
  `_get_change_frequency`, `_get_article_list`, `_get_pagination`,
  `_article_page`, `_html_to_text`. No fixtures.

- **`t/site_filesystem.t`** (new) — `_set_files`, `_clean_tmp_directory`,
  `_preprocess_files`, `_copy_to_tmp` happy path (existing
  `t/site_single_file.t` only hits one branch and stays as-is),
  `_write_tag_templates`, `_write_tagmap`, `_write_sitemap`. Uses
  `File::Temp::tempdir(CLEANUP=>1)` plus `chdir` for isolation.

- **`t/site_db.t`** (new) — `_rebuild_rss_feeds` and
  `_rebuild_article_pagination`. Loads `t/fixtures/test-schema.sql` into an
  in-memory SQLite at test start (same pattern as `t/dbh.t`), populates a
  handful of article rows, then asserts on the generated RSS (via
  `XML::RSS` parse) and on the generated pagination `.tt` files (via direct
  file read).

- **`t/site_ttree.t`** (new) — `_assert_tt_config` (with `$ENV{HOME}`
  override pointing at a tempdir with and without a `.ttreerc`),
  `_execute_ttree` and `_run_ttree` against a minimal fixture under
  `t/fixtures/ttree/`, `_run_ttree_single` against the same fixture, and
  `_get_git_lastmod` against both the real repo (git-success branch) and a
  tempdir-only file (mtime-fallback branch). Asserts on output content,
  not stdout/stderr wording, to survive `Template::App::ttree` version
  drift.

### Util/Image.pm

- **`t/util_image.t`** (new) — every branch of `process`:
  - success under size (copy-as-is)
  - success after spatial resize
  - success after JPEG quality drop
  - `invalid_filename` (path-traversal patterns `..`, `/`, `\`)
  - `exists` (no-overwrite collision)
  - `invalid_type` (unsupported extension)
  - `invalid_image` (corrupt bytes with valid extension)
  - `write_error` (Imager `write` failure — driven by writing to a
    read-only target if reachable, otherwise via a synthetic input that
    Imager refuses to re-encode in the chosen format)
  - `too_large` (synthetic image that won't compress under the limit even
    after 20 attempts)

  Uses a minimal stand-in for `Dancer2::Core::Request::Upload` exposing the
  `tempname` and `copy_to` methods that `Ovid::Util::Image` actually calls.
  Existing `t/editor-upload.t` keeps its end-to-end Dancer2-route role; this
  file is the unit-level workhorse.

### bin/review

Extend `t/dev_server.t` (not a new file):

- Hit the `Dancer2::Core::Response::Delayed` short-circuit in the `after`
  hook (request a static non-HTML asset).
- Hit the wrong-content-type branch (response without `text/html`).
- Cover the fork path in `/api/launch-editor`: replace the current
  `$ENV{TESTING}` skip with a test-only env knob
  (`OVID_REVIEW_TEST_LAUNCH_CMD`, default unset) that, when set, runs the
  fork/dup/exec path against `perl -e 'exit 0'` instead of `bin/launch`.
  This exercises `_terminate_previous_editor`, the fork, the dup, and the
  `$editor_child_pid` assignment without spawning a real editor. Default
  test runs (and production runs) keep the current skip behaviour.
- Cover the `realpath` symlink-trickery branch in the static handler.

## Fixtures and helpers

### New fixture files (under `t/fixtures/`)

- `ttree/include/wrapper.tt` — minimal wrapper producing
  `<html><body>...</body></html>`.
- `ttree/sample.tt` — trivial template producing predictable HTML for
  ttree-output assertions.
- `ttree/.ttreerc` — a `.ttreerc` shaped exactly like the one
  `_assert_tt_config` warns about. Used as a target for `$ENV{HOME}` override.
- `images/under_limit.png` — small PNG (<10 KB) for the copy-as-is branch.
- `images/over_limit.jpg` — synthetic JPEG starting above 300 KB that
  compresses below the limit on the first quality drop.
- `images/incompressible.png` — random-noise PNG that won't compress under
  300 KB even after 20 attempts. Sized to keep the `too_large` test under
  1 s.
- `images/corrupt.jpg` — non-image bytes with a `.jpg` extension.

### Fixture generator

- `script/generate-image-fixtures.pl` (new). Run-once helper that produces
  the three synthetic image fixtures via `Imager`. Committed alongside the
  fixtures so their bytes are reproducible and explainable rather than
  mystery binary blobs. Not invoked by the build or test pipeline.

### Shared test helper

- `t/lib/TestHelper/Site.pm` (new). Wraps the boilerplate the three new
  Site tests share:
  - `setup_tempdir_site()` returns `($site, $tempdir)` with `chdir` already
    done into a tempdir containing a `root/` skeleton.
  - `with_test_db { ... }` deploys `t/fixtures/test-schema.sql` into a
    temp SQLite DB and points `Less::Config`'s `dbh` at it for the
    duration of the block. Uses `local $ENV{...}` and `chdir` discipline
    so state doesn't leak between tests.
  - Built incrementally — only add helpers when the next test needs them.

The `t/lib/` directory is new. Tests that need it add `use lib 't/lib'`.

### DB fixture safety

`t/site_db.t` deploys `t/fixtures/test-schema.sql` into an in-memory
SQLite at test start; the on-disk fixture `t/fixtures/test.db` is never
modified, and `db/ovid.db` is never opened. The CLAUDE.md "production data
protection" rule is preserved.

## Makefile and documentation change

The `cover` target currently:

```make
cover: ## Generate HTML coverage report (one-shot)
	cover -test
	cover -report html -outputdir coverage-report
```

Change to:

```make
cover: ## Generate HTML coverage report (one-shot)
	cover -test -ignore_re '^t/'
	cover -report html -outputdir coverage-report -ignore_re '^t/'
```

Update CLAUDE.md's "Generate coverage report" snippet (`cover -test` /
`cover -report html ...`) to match. The `clean` target needs no change.

## Implementation order

Each step leaves the suite green and overall coverage strictly higher.

1. Makefile coverage fix and CLAUDE.md snippet update. Re-run `make cover`,
   confirm `t/*.t` rows are gone, record honest baseline.
2. `t/site_pure_functions.t`. Biggest delta per LOC.
3. `t/util_image.t` + `script/generate-image-fixtures.pl` + image fixtures.
   Self-contained; covers the most regression-prone external-input surface.
4. `t/lib/TestHelper/Site.pm` (incremental — add helpers as later tests
   need them; no big up-front design).
5. `t/site_filesystem.t`.
6. `t/site_db.t` + in-memory schema deploy.
7. `t/site_ttree.t` + `t/fixtures/ttree/` fixtures. Last in the Site.pm
   chain because it carries the highest setup cost.
8. Extend `t/dev_server.t` for the `bin/review` fork-launch and remaining
   branches.

After each step: `prove -rl t/` green, `make cover` shows the affected file
moving toward its target. If a step lands below target, add tests before
moving on.

## Risks and mitigations

- **`_build_tinysearch` stays uncovered.** Documented above and in a
  `# Coverage note:` comment on the method, pointing at the `release`-target
  rationale.
- **ttree fixture fragility.** `Template::App::ttree` has changed shape
  before. Mitigation: assertions target output content (predictable HTML
  strings), not stdout/stderr wording, and the fixture template uses the
  simplest TT directives possible.
- **DB fixture drift.** If sqitch migrations change schema,
  `t/fixtures/test-schema.sql` will fall out of date. Mitigation: tests
  load the schema file directly into an in-memory DB at test start (same
  pattern as `t/dbh.t`). Drift surfaces as immediate test failure, not
  silent wrong-coverage.
- **Image fixture reproducibility.** `Imager` byte-output isn't stable
  across versions. Mitigation: the generator script is committed; if a
  fixture goes stale, regenerate. Tests assert on size and
  decode-ability, never on byte-equality.
- **Fork-path test pollution.** The new `bin/review` fork test could leave
  zombie children on failure. Mitigation: the test-only knob runs
  `perl -e 'exit 0'` (immediate clean exit); the test issues `waitpid`
  with a 5 s timeout; failure to reap is a test-suite failure, not a
  silent leak.

## Out of scope

Deliberately not done in this work:

- `lib/Ovid/Site.pm::_build_tinysearch` (see above).
- Raising coverage on files already over 90 %.
- Refactoring `Site.pm` (currently 769 lines, 24 methods) into smaller
  modules. The "test coverage" framing the user accepted is to *cover the
  file as it stands*, not to restructure it. A `Site.pm` split is its own
  brainstorm.
- Regression-class hardening for the TT-to-Perl plugin seam (the class of
  bug behind the recent tag, `is_blog`, and Collection regressions). The
  user explicitly chose "raise the % number" over "prevent regression
  classes" — that work is also its own brainstorm.
