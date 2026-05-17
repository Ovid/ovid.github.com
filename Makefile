# Makefile for website project

.PHONY: all test cover lint format loc build release clean help

all: lint format test release ## Lint, format, test, then release build

test: ## Run the full test suite (recursive, picks up t/integration/)
	prove -rl t/

build: ## Run a plain site build (skips tests; needs only Perl deps)
	perl bin/rebuild --notest

release: ## Run a release build with search index (needs tinysearch + wasm-pack)
	perl bin/rebuild --release --notest

cover: ## Generate HTML coverage report (one-shot)
	cover -test
	cover -report html -outputdir coverage-report

lint: ## Run perlcritic on lib/ and bin/
	perlcritic lib bin

format: ## Format Perl source with perltidy (bin/ is filtered to files with a Perl shebang so bash scripts like bin/release are left alone)
	find lib -name '*.pm' ! -name '*.bak' -print0 | xargs -0 perltidy --profile=.perltidyrc -b
	find bin -type f ! -name '*.bak' -exec grep --null -lE '^#!.*perl' {} + | xargs -0 perltidy --profile=.perltidyrc -b
	find lib bin -name '*.bak' -delete

loc: ## Count lines of our own code (lib/, bin/, t/)
	cloc lib bin t

clean: ## Remove coverage database and report
	cover -delete
	rm -rf coverage-report/

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-10s %s\n", $$1, $$2}'
