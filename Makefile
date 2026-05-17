# Makefile for website project

.PHONY: all test cover lint format loc clean help

all: lint format test ## Lint, format, and run the test suite

test: ## Run the full test suite (recursive, picks up t/integration/)
	prove -rl t/

cover: ## Generate HTML coverage report (one-shot)
	cover -test
	cover -report html -outputdir coverage-report

lint: ## Run perlcritic on lib/ and bin/
	perlcritic lib bin

format: ## Format Perl source with perltidy
	find lib -name '*.pm' -print0 | xargs -0 perltidy --profile=.perltidyrc -b
	find bin -type f -print0 | xargs -0 perltidy --profile=.perltidyrc -b
	find lib bin -name '*.bak' -delete

loc: ## Count lines of our own code (lib/, bin/, t/)
	cloc lib bin t

clean: ## Remove coverage database and report
	cover -delete
	rm -rf coverage-report/

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-10s %s\n", $$1, $$2}'
