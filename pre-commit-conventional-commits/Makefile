# Variables
DEVRAIL_IMAGE      ?= ghcr.io/devrail-dev/dev-toolchain:v1
DEVRAIL_FAIL_FAST  ?= 0
DEVRAIL_LOG_FORMAT ?= json

DOCKER_RUN := docker run --rm \
	-v "$$(pwd):/workspace" \
	-w /workspace \
	-e DEVRAIL_FAIL_FAST=$(DEVRAIL_FAIL_FAST) \
	-e DEVRAIL_LOG_FORMAT=$(DEVRAIL_LOG_FORMAT) \
	$(DEVRAIL_IMAGE)

.DEFAULT_GOAL := help

# .PHONY declarations
.PHONY: help check docs format install-hooks lint scan security test
.PHONY: _lint _format _test _security _scan _docs _check

# Public targets
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

check: ## Run all checks (lint, format, test, security, scan, docs)
	$(DOCKER_RUN) make _check

docs: ## Generate documentation
	$(DOCKER_RUN) make _docs

format: ## Run all formatters
	$(DOCKER_RUN) make _format

# install-hooks is the ONE target that runs on the host, not inside the container.
# It modifies .git/hooks/ which is a host-side concern. This target must work
# without the dev-toolchain container — a developer should be able to clone a
# repo and run `make install-hooks` immediately before pulling any Docker images.
#
# Hook registration:
#   pre-commit install              -> .git/hooks/pre-commit (lint, format, gitleaks, terraform-docs)
#   pre-commit install --hook-type commit-msg -> .git/hooks/commit-msg (conventional commits)
#
# Exit codes:
#   0 = success
#   2 = misconfiguration (missing Python, not a git repo)
install-hooks: ## Install pre-commit hooks
	@if ! command -v python3 >/dev/null 2>&1; then \
		echo "Error: Python 3 is required to install pre-commit. Install Python 3 and try again."; \
		exit 2; \
	fi
	@if ! git rev-parse --git-dir >/dev/null 2>&1; then \
		echo "Error: Not in a git repository. Run 'git init' first."; \
		exit 2; \
	fi
	@if ! command -v pre-commit >/dev/null 2>&1; then \
		echo "Installing pre-commit..."; \
		if command -v pipx >/dev/null 2>&1; then \
			pipx install pre-commit; \
		else \
			pip install --user pre-commit; \
		fi; \
	fi
	@pre-commit install
	@pre-commit install --hook-type commit-msg
	@echo "Pre-commit hooks installed successfully. Hooks will run on every commit."

lint: ## Run all linters
	$(DOCKER_RUN) make _lint

scan: ## Run universal scanners (trivy, gitleaks)
	$(DOCKER_RUN) make _scan

security: ## Run security scanners
	$(DOCKER_RUN) make _security

test: ## Run all tests
	$(DOCKER_RUN) make _test

# Internal targets
_lint:
	# Language-specific linting (Python)
	# Requires dev-toolchain container (Epic 2)
	@echo "lint: not yet implemented — requires dev-toolchain container"

_format:
	# Language-specific formatting (Python)
	# Requires dev-toolchain container (Epic 2)
	@echo "format: not yet implemented — requires dev-toolchain container"

_test:
	# Run pytest test suite
	# Requires dev-toolchain container (Epic 2)
	@echo "test: not yet implemented — requires dev-toolchain container"

_security:
	# Security scanning (Python)
	# Requires dev-toolchain container (Epic 2)
	@echo "security: not yet implemented — requires dev-toolchain container"

_scan:
	# Universal scanning (trivy, gitleaks)
	# Requires dev-toolchain container (Epic 2)
	@echo "scan: not yet implemented — requires dev-toolchain container"

_docs:
	# Documentation generation
	# Requires dev-toolchain container (Epic 2)
	@echo "docs: not yet implemented — requires dev-toolchain container"

_check: _lint _format _test _security _scan _docs
	# Orchestrates all checks; reports composite summary
	@echo "check: all checks complete"
