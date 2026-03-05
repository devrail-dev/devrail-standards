# .devrail.yml Schema Specification

This document defines the complete schema for `.devrail.yml`, the project configuration file used by all DevRail-managed repositories. This file is the single source of truth that the Makefile, CI pipelines, and AI agents read to understand a project's language stack and settings.

## File Location

`.devrail.yml` MUST be placed at the repository root directory.

## Format

- YAML format (consistent with CI/CD ecosystem)
- `snake_case` for ALL keys (no camelCase, no kebab-case)
- Comments encouraged for non-obvious settings

## Top-Level Keys

### `languages`

**Type:** list of strings (required)

**Description:** Declares which languages are used in the project. This list drives which linters, formatters, security scanners, and test runners are executed by Makefile targets and CI jobs.

**Allowed values:** `python`, `bash`, `terraform`, `ansible`, `ruby`, `go`, `javascript`, `rust`

**Validation rules:**

- Must be a non-empty list
- Each entry must be one of the supported language identifiers
- Duplicate entries are ignored
- Order does not affect execution

**Example:**

```yaml
languages:
  - python
  - bash
```

### `fail_fast`

**Type:** boolean (optional)

**Default:** `false`

**Description:** Controls error handling behavior for Makefile targets and CI jobs. When `false` (default), all checks run to completion and report all issues (run-all-report-all). When `true`, execution stops at the first failure.

Can also be overridden at runtime via the `DEVRAIL_FAIL_FAST=1` environment variable.

**Validation rules:**

- Must be a boolean (`true` or `false`)
- If omitted, defaults to `false`

**Example:**

```yaml
fail_fast: false
```

### `log_format`

**Type:** string (optional)

**Default:** `json`

**Description:** Controls the output format for Makefile targets and scripts.

**Allowed values:**

- `json` -- structured JSON output (default, preferred for CI and agents)
- `human` -- human-readable table format

Can also be overridden at runtime via the `DEVRAIL_LOG_FORMAT=human` environment variable.

**Validation rules:**

- Must be one of: `json`, `human`
- If omitted, defaults to `json`

**Example:**

```yaml
log_format: json
```

## Per-Language Overrides

Per-language overrides are optional top-level keys matching the language name. They allow customization of tools for a specific language in the project. If omitted, default tools for the language are used.

**Structure:** Each override key matches a language listed in `languages`. The value is a mapping of concern names to tool names (string) or tool lists (list of strings).

**Override keys:**

- `linter` -- linting tool
- `formatter` -- formatting tool
- `security` -- security scanning tools
- `test` -- test runner
- `type_check` -- type checking tool
- `docs` -- documentation generation tool

**Validation rules:**

- Override keys must match an entry in the `languages` list
- Override keys for unlisted languages are ignored
- Individual tool overrides are optional; omitted keys use defaults
- Tool values can be a string (single tool) or list of strings (multiple tools)

**Example:**

```yaml
languages:
  - python

python:
  linter: ruff
  formatter: ruff
  security:
    - bandit
    - semgrep
  test: pytest
  type_check: mypy
```

## Complete Examples

### Single-Language Project (Bash)

A simple shell-script project with all defaults:

```yaml
# .devrail.yml — shell scripts only
languages:
  - bash

fail_fast: false
log_format: json
```

### Single-Language Project (Python)

A Python project with explicit tool overrides:

```yaml
# .devrail.yml — Python project
languages:
  - python

fail_fast: false
log_format: json

python:
  linter: ruff
  formatter: ruff
  security:
    - bandit
    - semgrep
  test: pytest
  type_check: mypy
```

### Multi-Language Project

A project using Python for application code and Terraform for infrastructure:

```yaml
# .devrail.yml — multi-language project
languages:
  - python
  - terraform

fail_fast: false
log_format: human

python:
  linter: ruff
  formatter: ruff
  security:
    - bandit
    - semgrep
  test: pytest
  type_check: mypy

terraform:
  linter: tflint
  formatter: terraform-fmt
  security:
    - tfsec
    - checkov
  test: terratest
  docs: terraform-docs
```

### Single-Language Project (Ruby on Rails)

A Rails project using Ruby defaults:

```yaml
# .devrail.yml — Ruby on Rails project
languages:
  - ruby

fail_fast: false
log_format: json

ruby:
  linter:
    - rubocop
    - reek
  formatter: rubocop
  security:
    - brakeman
    - bundler-audit
  test: rspec
  type_check: sorbet
```

### Single-Language Project (Go)

A Go project using defaults:

```yaml
# .devrail.yml — Go project
languages:
  - go

fail_fast: false
log_format: json

go:
  linter: golangci-lint
  formatter: gofumpt
  security: govulncheck
  test: go-test
```

### Single-Language Project (JavaScript/TypeScript)

A TypeScript project using defaults:

```yaml
# .devrail.yml — TypeScript project
languages:
  - javascript

fail_fast: false
log_format: json

javascript:
  linter: eslint
  formatter: prettier
  security: npm-audit
  test: vitest
  type_check: tsc
```

### Single-Language Project (Rust)

A Rust project using defaults:

```yaml
# .devrail.yml — Rust project
languages:
  - rust

fail_fast: false
log_format: json

rust:
  linter: clippy
  formatter: rustfmt
  security:
    - cargo-audit
    - cargo-deny
  test: cargo-test
```

### Full Eight-Language Project

A project using all supported languages:

```yaml
# .devrail.yml — all supported languages
languages:
  - python
  - bash
  - terraform
  - ansible
  - ruby
  - go
  - javascript
  - rust

fail_fast: true
log_format: json

python:
  linter: ruff
  formatter: ruff
  security:
    - bandit
    - semgrep
  test: pytest
  type_check: mypy

terraform:
  linter: tflint
  formatter: terraform-fmt
  security:
    - tfsec
    - checkov
  test: terratest
  docs: terraform-docs

ruby:
  linter:
    - rubocop
    - reek
  formatter: rubocop
  security:
    - brakeman
    - bundler-audit
  test: rspec
  type_check: sorbet

go:
  linter: golangci-lint
  formatter: gofumpt
  security: govulncheck
  test: go-test

javascript:
  linter: eslint
  formatter: prettier
  security: npm-audit
  test: vitest
  type_check: tsc

rust:
  linter: clippy
  formatter: rustfmt
  security:
    - cargo-audit
    - cargo-deny
  test: cargo-test
```

## Language Support Matrix

The following table shows the default tool for each concern per language. These are the tools included in the `dev-toolchain` container.

| Concern | Python | Bash | Terraform | Ansible | Ruby | Go | JavaScript | Rust |
|---|---|---|---|---|---|---|---|---|
| Linter | ruff | shellcheck | tflint | ansible-lint | rubocop, reek | golangci-lint | eslint | clippy |
| Formatter | ruff format | shfmt | terraform fmt, terragrunt hclfmt | -- | rubocop | gofumpt | prettier | rustfmt |
| Security | bandit, semgrep | -- | tfsec, checkov | -- | brakeman, bundler-audit | govulncheck | npm audit | cargo-audit, cargo-deny |
| Tests | pytest | bats | terratest | molecule | rspec | go test | vitest | cargo test |
| Type Check | mypy | -- | -- | -- | sorbet | -- | tsc | -- |
| Docs | -- | -- | terraform-docs | -- | -- | -- | -- | -- |
| Universal | trivy, gitleaks | trivy, gitleaks | trivy, gitleaks | trivy, gitleaks | trivy, gitleaks | trivy, gitleaks | trivy, gitleaks | trivy, gitleaks |

**Notes:**

- "Universal" tools run for all languages and are not language-specific overrides
- A `--` entry means the concern does not apply to that language
- Default tools are used when no per-language override is specified
- `terraform` includes Terragrunt formatting (`terragrunt hclfmt`) — no separate language entry needed. Terragrunt formatting runs automatically when `terragrunt.hcl` files are detected

## Exit Codes

All tools consuming `.devrail.yml` follow standard DevRail exit codes:

| Code | Meaning |
|---|---|
| `0` | Pass |
| `1` | Failure (lint errors, test failures, security findings) |
| `2` | Misconfiguration (missing `.devrail.yml`, unknown language, container pull failure) |

## Schema Summary

| Key | Type | Required | Default | Description |
|---|---|---|---|---|
| `languages` | list of strings | Yes | -- | Languages used in the project |
| `fail_fast` | boolean | No | `false` | Stop on first failure |
| `log_format` | string | No | `json` | Output format (`json` or `human`) |
| `<language>` | mapping | No | -- | Per-language tool overrides |
