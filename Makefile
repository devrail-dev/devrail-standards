DEVRAIL_IMAGE ?= ghcr.io/devrail-dev/dev-toolchain:v1
DOCKER_RUN    ?= docker run --rm -v "$$(pwd):/workspace" -w /workspace $(DEVRAIL_IMAGE)

.DEFAULT_GOAL := help

.PHONY: help lint format test security scan docs check install-hooks
.PHONY: _lint _format _test _security _scan _docs _check

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

lint: ## Run all linters
	$(DOCKER_RUN) make _lint

format: ## Run all formatters
	$(DOCKER_RUN) make _format

test: ## Run all tests
	$(DOCKER_RUN) make _test

security: ## Run security scanners
	$(DOCKER_RUN) make _security

scan: ## Run full scan (lint + security)
	$(DOCKER_RUN) make _scan

docs: ## Generate documentation
	$(DOCKER_RUN) make _docs

check: ## Run all checks (lint, format, test, security, docs)
	$(DOCKER_RUN) make _check

install-hooks: ## Install pre-commit hooks
	pre-commit install
	pre-commit install --hook-type pre-push

_lint:
	# Internal target — runs inside container
	# Requires dev-toolchain container (Epic 2)
	@echo "lint: not yet implemented — requires dev-toolchain container"

_format:
	# Internal target — runs inside container
	# Requires dev-toolchain container (Epic 2)
	@echo "format: not yet implemented — requires dev-toolchain container"

_test:
	# Internal target — runs inside container
	# Requires dev-toolchain container (Epic 2)
	@echo "test: not yet implemented — requires dev-toolchain container"

_security:
	# Internal target — runs inside container
	# Requires dev-toolchain container (Epic 2)
	@echo "security: not yet implemented — requires dev-toolchain container"

_scan:
	# Internal target — runs inside container
	# Requires dev-toolchain container (Epic 2)
	@echo "scan: not yet implemented — requires dev-toolchain container"

_docs:
	# Internal target — runs inside container
	# Requires dev-toolchain container (Epic 2)
	@echo "docs: not yet implemented — requires dev-toolchain container"

_check: _lint _format _test _security _scan _docs
	# Internal target — orchestrates all checks inside container
	@echo "check: all checks complete"
