# Makefile Contract Specification

This document is the authoritative reference for the DevRail Makefile contract. Every DevRail-managed repository uses a Makefile as its universal execution interface. Developers, CI pipelines, and AI agents all interact with the project through `make` targets. Behavior is identical regardless of invocation context.

## Public Targets

Every DevRail-managed repo exposes exactly these public targets:

| Target | Purpose | Behavior |
|---|---|---|
| `help` | Default target; shows available targets | Auto-generated from `## description` comments in the Makefile |
| `lint` | Run all language-appropriate linters | Delegates to Docker container; runs `_lint` inside |
| `format` | Run all language-appropriate formatters | Delegates to Docker container; runs `_format` inside |
| `fix` | Auto-fix formatting issues in-place | Delegates to Docker container; runs `_fix` inside |
| `test` | Run project test suite | Delegates to Docker container; runs `_test` inside |
| `security` | Run language-specific security scanners | Delegates to Docker container; runs `_security` inside |
| `scan` | Run universal scanning (trivy, gitleaks) | Delegates to Docker container; runs `_scan` inside |
| `docs` | Generate documentation | Delegates to Docker container; runs `_docs` inside |
| `changelog` | Generate changelog from conventional commits | Delegates to Docker container; runs `_changelog` inside |
| `check` | Run ALL above targets; report composite summary | Orchestrates all targets in sequence, reports pass/fail summary |
| `install-hooks` | Install pre-commit and pre-push hooks | Runs locally on the host (not inside container) |

### Target Descriptions

#### `help`

The default target. When a developer runs `make` with no arguments, `help` is invoked. It parses the Makefile for lines matching the pattern `target: ## description` and prints a formatted list of all public targets with their descriptions.

```
$ make help
changelog            Generate changelog from conventional commits
check                Run all checks (lint, format, test, security, docs)
docs                 Generate documentation
fix                  Auto-fix formatting issues in-place
format               Run all formatters
help                 Show this help
install-hooks        Install pre-commit hooks
lint                 Run all linters
scan                 Run full scan (lint + security)
security             Run security scanners
test                 Run all tests
```

#### `lint`

Runs all linters for the languages declared in `.devrail.yml`. Delegates to the dev-toolchain container where the `_lint` internal target executes language-specific linters (e.g., `ruff check` for Python, `shellcheck` for Bash, `tflint` for Terraform, `ansible-lint` for Ansible, `rubocop` and `reek` for Ruby, `golangci-lint` for Go, `eslint` and `tsc` for JavaScript/TypeScript, `cargo clippy` for Rust).

#### `format`

Runs all formatters for the declared languages. Delegates to the container where `_format` executes tools like `ruff format` for Python, `shfmt` for Bash, `terraform fmt` and `terragrunt hclfmt` for Terraform, `rubocop` for Ruby, `gofumpt` for Go, `prettier` for JavaScript/TypeScript, and `cargo fmt` for Rust.

#### `fix`

Applies all formatters in write mode for the languages declared in `.devrail.yml`. Unlike `format` (which only checks), `fix` modifies files in-place. Delegates to the container where `_fix` executes tools like `ruff format` for Python, `shfmt -w` for Bash, `terraform fmt` and `terragrunt hclfmt` for Terraform, `rubocop -a` for Ruby, `gofumpt -w` for Go, `prettier --write` for JavaScript, and `cargo fmt` for Rust.

This target is intentionally excluded from `make check` because `check` must be a read-only operation. Run `make fix` manually when you want to auto-remediate formatting issues reported by `make format`.

#### `test`

Runs the project test suite. Delegates to the container where `_test` executes test runners like `pytest` for Python, `bats` for Bash, `terratest` for Terraform, `molecule` for Ansible, `rspec` for Ruby, `go test` for Go, `vitest` for JavaScript/TypeScript, and `cargo test` for Rust.

#### `security`

Runs language-specific security scanners. Delegates to the container where `_security` executes tools like `bandit` and `semgrep` for Python, `tfsec` and `checkov` for Terraform, `brakeman` and `bundler-audit` for Ruby, `govulncheck` for Go, `npm audit` for JavaScript/TypeScript, and `cargo audit` and `cargo deny` for Rust.

#### `scan`

Runs universal scanners that apply to every project regardless of language. Delegates to the container where `_scan` executes `trivy` (vulnerability scanning) and `gitleaks` (secret detection).

#### `changelog`

Generates a changelog from conventional commit history. Delegates to the container where `_changelog` executes `git-cliff` to parse commits and produce a structured changelog. git-cliff reads the repository's commit history, groups entries by type (features, fixes, etc.), and outputs a `CHANGELOG.md` file. This target runs independently of `make check` and is invoked on-demand rather than as part of the standard check sequence.

#### `docs`

Generates documentation. Delegates to the container where `_docs` executes documentation generators. Runs `terraform-docs` for Terraform modules and generates a tool version report (`.devrail-output/tool-versions.json`) listing the versions of all tools available for the declared languages.

#### `check`

The composite target. Runs all of the above targets (`lint`, `format`, `test`, `security`, `scan`, `docs`) in sequence. Reports a final summary of all targets with pass/fail status and total duration. This is the single gate that developers, CI, and agents use to validate a project.

#### `install-hooks`

Installs pre-commit and pre-push hooks into the local repository. This is the only public target that runs directly on the host instead of delegating to Docker. It executes `pre-commit install` to set up commit-time hooks (formatting, secret detection) and `pre-commit install --hook-type pre-push` to set up a pre-push hook that runs `make check` before every push.

## Two-Layer Delegation Pattern

The Makefile uses a two-layer delegation pattern to ensure all tools run inside a consistent, containerized environment.

### Layer 1: User-Facing Targets (Host)

Public targets run on the host machine. Their sole responsibility is to invoke the dev-toolchain Docker container with the corresponding internal target.

```makefile
DEVRAIL_IMAGE ?= ghcr.io/devrail-dev/dev-toolchain:v1
DOCKER_RUN    ?= docker run --rm -v "$$(pwd):/workspace" -w /workspace $(DEVRAIL_IMAGE)

lint: ## Run all linters
	$(DOCKER_RUN) make _lint

format: ## Run all formatters
	$(DOCKER_RUN) make _format
```

### Layer 2: Internal Targets (Container)

Internal targets run inside the Docker container. They execute the actual tool commands. Internal targets are prefixed with `_` and are not intended for direct invocation by users.

```makefile
_lint:
	ruff check . || true
	shellcheck scripts/*.sh || true

_format:
	ruff format .
	shfmt -w scripts/*.sh
```

### Delegation Flow

```
Developer/CI/Agent
      |
      v
  make lint          (Layer 1: host)
      |
      v
  docker run ...     (container startup)
      |
      v
  make _lint         (Layer 2: inside container)
      |
      v
  ruff, shellcheck   (actual tool execution)
```

### Why Two Layers?

1. **Environment consistency.** All tools run inside the same container, with the same versions, on every machine. No "works on my machine" drift.
2. **Zero host dependencies.** Developers only need Docker and Make installed. All linters, formatters, scanners, and test runners live in the container.
3. **Identical behavior everywhere.** Local development, CI pipelines, and AI agents all invoke the same targets and get the same results.

### Exceptions

`install-hooks` is the only public target that does not delegate to Docker. Pre-commit hooks must be installed in the host's git repository, not inside a container.

`help` also runs directly on the host because it only needs to parse the Makefile itself.

## Target Naming Conventions

### Public Targets

- **Case:** `lower-kebab-case`
- **Examples:** `install-hooks`, `lint`, `format`, `security`
- **No abbreviations:** `security` not `sec`, `format` not `fmt`, `install-hooks` not `hooks`
- **Documentation:** Every public target has a `## description` comment on the same line as the target name. This comment is used by `make help` for auto-generated documentation.

```makefile
lint: ## Run all linters
security: ## Run security scanners
install-hooks: ## Install pre-commit hooks
```

### Internal Targets

- **Prefix:** `_` (underscore)
- **Case:** `_lower-kebab-case`
- **Examples:** `_lint`, `_format`, `_fix`, `_test`, `_security`, `_scan`, `_docs`, `_changelog`, `_check`
- Internal targets do NOT have `## description` comments and do NOT appear in `make help` output.

### Variables

- **Case:** `UPPER_SNAKE_CASE`
- **Override syntax:** `?=` (conditionally assigned, allowing environment variable overrides)
- **Examples:** `DEVRAIL_IMAGE`, `DOCKER_RUN`, `DEVRAIL_FAIL_FAST`

## Makefile File Structure

Every DevRail Makefile follows this ordering:

```makefile
# 1. Variables
DEVRAIL_IMAGE ?= ghcr.io/devrail-dev/dev-toolchain:v1
DOCKER_RUN    ?= docker run --rm -v "$$(pwd):/workspace" -w /workspace $(DEVRAIL_IMAGE)

.DEFAULT_GOAL := help

# 2. .PHONY declarations
.PHONY: help lint format fix test security scan docs changelog check install-hooks
.PHONY: _lint _format _fix _test _security _scan _docs _changelog _check

# 3. Public targets (with ## description comments)
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

lint: ## Run all linters
	$(DOCKER_RUN) make _lint

# ... remaining public targets ...

# 4. Internal targets (no ## comments)
_lint:
	ruff check . || true
	shellcheck scripts/*.sh || true
```

## Error Handling

### Run-All-Report-All (Default)

By default, every target runs to completion regardless of whether prior targets failed. This ensures that developers and agents see the full picture of all issues in a single run, rather than fixing one error at a time.

Within a single target (e.g., `_lint`), individual tool failures are captured but do not prevent subsequent tools from running. For example, if `ruff check` fails, `shellcheck` still runs.

After all tools complete, the target reports its overall status.

### Fail-Fast (Optional)

Fail-fast mode stops execution at the first failure. This is useful for CI pipelines where early termination saves compute time.

Fail-fast can be enabled in two ways:

1. **Environment variable:** `DEVRAIL_FAIL_FAST=1 make check`
2. **Configuration file:** Set `fail_fast: true` in `.devrail.yml`

The environment variable takes precedence over the configuration file.

### Precedence

```
DEVRAIL_FAIL_FAST env var  >  .devrail.yml fail_fast  >  default (false)
```

## Exit Codes

All Makefile targets follow a consistent exit code convention:

| Code | Meaning | Examples |
|---|---|---|
| `0` | Pass | All linters pass, all tests pass, no security findings |
| `1` | Failure | Lint errors found, test failures, security vulnerabilities detected |
| `2` | Misconfiguration | Missing `.devrail.yml`, unknown language in config, container image pull failure |

### Exit Code Rules

- Exit code `2` always takes precedence over `1`. If a target encounters both misconfiguration and tool failures, it exits with `2`.
- `make check` exits with the highest exit code from any individual target. If `lint` exits `1` and `security` exits `0`, `check` exits `1`.
- Exit codes are never swallowed. CI pipelines and agents rely on these codes for pass/fail determination.

## JSON Output Format

### Per-Target Output

Each target produces a JSON summary on stdout upon completion:

```json
{"target":"lint","status":"pass","duration_ms":1234,"errors":[]}
```

On failure, the `errors` array contains descriptive strings:

```json
{"target":"lint","status":"fail","duration_ms":2345,"errors":["ruff: 3 violations found","shellcheck: 1 warning in scripts/deploy.sh"]}
```

### Field Definitions

| Field | Type | Description |
|---|---|---|
| `target` | string | The target name (e.g., `lint`, `format`, `test`) |
| `status` | string | `pass` or `fail` |
| `duration_ms` | integer | Execution time in milliseconds |
| `errors` | array of strings | Empty on pass; error descriptions on fail |

### `make check` Composite Summary

`make check` produces a composite summary after all targets complete:

```json
{
  "target": "check",
  "status": "fail",
  "duration_ms": 12345,
  "results": [
    {"target": "lint", "status": "pass", "duration_ms": 1234},
    {"target": "format", "status": "pass", "duration_ms": 567},
    {"target": "test", "status": "fail", "duration_ms": 3456},
    {"target": "security", "status": "pass", "duration_ms": 2345},
    {"target": "scan", "status": "pass", "duration_ms": 1890},
    {"target": "docs", "status": "pass", "duration_ms": 432}
  ]
}
```

The top-level `status` is `fail` if any individual target failed, `pass` if all passed.

### Human-Readable Output

When `DEVRAIL_LOG_FORMAT=human` is set (or `log_format: human` in `.devrail.yml`), targets produce a table instead of JSON:

```
Target          Status    Duration
------          ------    --------
lint            PASS      1.2s
format          PASS      0.6s
test            FAIL      3.5s
security        PASS      2.3s
scan            PASS      1.9s
docs            PASS      0.4s
------          ------    --------
check           FAIL      9.9s
```

## `.devrail.yml` Consumption

The Makefile reads `.devrail.yml` to determine project configuration. The following keys affect Makefile behavior:

### `languages`

Determines which language-specific tools run within each target. For example, if `languages` contains `python` and `bash`, `make lint` will run `ruff check` and `shellcheck` but not `tflint` or `ansible-lint`.

### `fail_fast`

When `true`, the Makefile stops at the first target failure instead of running all targets. See [Error Handling](#error-handling) for details.

### `log_format`

When set to `human`, targets produce human-readable table output instead of JSON. See [JSON Output Format](#json-output-format) for details.

### Config Reading Pattern

The Makefile reads `.devrail.yml` at startup. If the file is missing, the Makefile exits with code `2` (misconfiguration) for any target that requires language detection. The `help` and `install-hooks` targets work without `.devrail.yml`.

```makefile
# Pattern for reading .devrail.yml (conceptual — actual implementation in Epic 3)
DEVRAIL_CONFIG := .devrail.yml

_check-config:
	@test -f $(DEVRAIL_CONFIG) || (echo "Missing .devrail.yml" && exit 2)
```

### Supported Keys

| `.devrail.yml` Key | Makefile Effect |
|---|---|
| `languages` | Selects which tools run in `_lint`, `_format`, `_fix`, `_test`, `_security`, `_docs` |
| `fail_fast` | Enables fail-fast error handling (overridden by `DEVRAIL_FAIL_FAST` env var) |
| `log_format` | Switches output between JSON and human-readable (overridden by `DEVRAIL_LOG_FORMAT` env var) |
| `<language>` overrides | Customizes tool selection for a specific language |

For the complete `.devrail.yml` schema, see [`devrail-yml-schema.md`](devrail-yml-schema.md).

## Complete Makefile Example

Below is a complete reference Makefile demonstrating all conventions:

```makefile
# Variables
DEVRAIL_IMAGE ?= ghcr.io/devrail-dev/dev-toolchain:v1
DOCKER_RUN    ?= docker run --rm -v "$$(pwd):/workspace" -w /workspace $(DEVRAIL_IMAGE)

.DEFAULT_GOAL := help

# .PHONY declarations
.PHONY: help lint format fix test security scan docs changelog check install-hooks
.PHONY: _lint _format _fix _test _security _scan _docs _changelog _check

# Public targets
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

lint: ## Run all linters
	$(DOCKER_RUN) make _lint

fix: ## Auto-fix formatting issues in-place
	$(DOCKER_RUN) make _fix

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

changelog: ## Generate changelog from conventional commits
	$(DOCKER_RUN) make _changelog

check: ## Run all checks (lint, format, test, security, docs)
	$(DOCKER_RUN) make _check

install-hooks: ## Install pre-commit hooks
	pre-commit install
	pre-commit install --hook-type pre-push

# Internal targets
_lint:
	# Language-specific linting (driven by .devrail.yml languages list)
	# Python:     ruff check .
	# Bash:       shellcheck scripts/*.sh
	# Terraform:  tflint
	# Ansible:    ansible-lint
	# Ruby:       rubocop, reek
	# Go:         golangci-lint run ./...
	# JavaScript: eslint, tsc --noEmit
	# Rust:       cargo clippy

_format:
	# Language-specific format checking (driven by .devrail.yml languages list)
	# Python:     ruff format --check .
	# Bash:       shfmt -d scripts/*.sh
	# Terraform:  terraform fmt -check -recursive, terragrunt hclfmt --terragrunt-check
	# Ruby:       rubocop --check
	# Go:         gofumpt -d .
	# JavaScript: prettier --check .
	# Rust:       cargo fmt --all -- --check

_fix:
	# Language-specific format fixing (driven by .devrail.yml languages list)
	# Python:     ruff format .
	# Bash:       shfmt -w scripts/*.sh
	# Terraform:  terraform fmt -recursive, terragrunt hclfmt
	# Ruby:       rubocop -a .
	# Go:         gofumpt -w .
	# JavaScript: prettier --write .
	# Rust:       cargo fmt --all

_test:
	# Language-specific tests (driven by .devrail.yml languages list)
	# Python:     pytest
	# Bash:       bats tests/
	# Terraform:  go test ./tests/...
	# Ansible:    molecule test
	# Ruby:       rspec
	# Go:         go test ./...
	# JavaScript: vitest run
	# Rust:       cargo test --all-targets

_security:
	# Language-specific security scanning (driven by .devrail.yml languages list)
	# Python:     bandit -r . && semgrep --config auto .
	# Terraform:  tfsec . && checkov -d .
	# Ruby:       brakeman, bundler-audit
	# Go:         govulncheck ./...
	# JavaScript: npm audit
	# Rust:       cargo audit, cargo deny check

_scan:
	# Universal scanning (runs for all projects)
	# trivy fs .
	# gitleaks detect

_docs:
	# Documentation generation (driven by .devrail.yml languages list)
	# Terraform: terraform-docs markdown table . > README.md

_changelog:
	# Changelog generation from conventional commits
	# git-cliff --output CHANGELOG.md

_check: _lint _format _test _security _scan _docs
	# Orchestrates all checks; reports composite summary
```

## Related Documents

- [`.devrail.yml` Schema Specification](devrail-yml-schema.md) -- configuration file schema
- [Universal Standards](universal.md) -- universal security tools (trivy, gitleaks)
- [Python Standards](python.md) -- Python-specific tooling
- [Bash Standards](bash.md) -- Bash-specific tooling
- [Terraform Standards](terraform.md) -- Terraform-specific tooling
- [Ansible Standards](ansible.md) -- Ansible-specific tooling
- [Ruby Standards](ruby.md) -- Ruby-specific tooling
- [Go Standards](go.md) -- Go-specific tooling
- [JavaScript Standards](javascript.md) -- JavaScript/TypeScript-specific tooling
- [Rust Standards](rust.md) -- Rust-specific tooling
