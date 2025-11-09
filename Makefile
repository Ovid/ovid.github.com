# Makefile for website project
# Supports coverage testing with `cover -test`

.PHONY: test coverage clean help

# Default target
help:
	@echo "Available targets:"
	@echo "  make test      - Run all tests with prove"
	@echo "  make coverage  - Generate coverage report with cover -test"
	@echo "  make clean     - Remove coverage database"
	@echo "  make help      - Show this help message"

# Run tests (required by cover -test)
test:
	prove -l t/

# Generate coverage report
coverage:
	cover -test
	cover -report html -outputdir coverage-report

# Clean coverage database
clean:
	cover -delete
	rm -rf coverage-report/

