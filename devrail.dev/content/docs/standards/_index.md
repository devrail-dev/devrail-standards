---
title: "Standards"
linkTitle: "Standards"
weight: 20
description: "Per-language tooling standards for Python, Bash, Terraform, Ansible, Ruby, Go, JavaScript/TypeScript, Rust, Swift, Kotlin, and universal security tools."
---

DevRail defines opinionated tooling standards for each supported language ecosystem. Every tool is pre-installed in the dev-toolchain container and invoked through consistent Makefile targets.

## Language Support Matrix

The following table shows the default tool for each concern per language. These tools are pre-installed in the `dev-toolchain` container.

| Concern | Python | Bash | Terraform | Ansible | Ruby | Go | JavaScript | Rust | Swift | Kotlin |
|---|---|---|---|---|---|---|---|---|---|---|
| Linter | ruff | shellcheck | tflint | ansible-lint | rubocop, reek | golangci-lint | eslint | clippy | SwiftLint | ktlint, detekt |
| Formatter | ruff format | shfmt | terraform fmt, terragrunt hclfmt | -- | rubocop | gofumpt | prettier | rustfmt | swift-format | ktlint |
| Security | bandit, semgrep | -- | tfsec, checkov | -- | brakeman, bundler-audit | govulncheck | npm audit | cargo-audit, cargo-deny | -- | OWASP dependency-check |
| Tests | pytest | bats | terratest | molecule | rspec | go test | vitest | cargo test | swift test | gradle test |
| Type Check | mypy | -- | -- | -- | sorbet | -- | tsc | -- | -- | -- |
| Docs | -- | -- | terraform-docs | -- | -- | -- | -- | -- | -- | -- |
| Universal | trivy, gitleaks, git-cliff | trivy, gitleaks, git-cliff | trivy, gitleaks, git-cliff | trivy, gitleaks, git-cliff | trivy, gitleaks, git-cliff | trivy, gitleaks, git-cliff | trivy, gitleaks, git-cliff | trivy, gitleaks, git-cliff | trivy, gitleaks, git-cliff | trivy, gitleaks, git-cliff |

A `--` entry means the concern does not apply to that language. Universal tools run for all projects regardless of declared languages.

## Makefile Target Mapping

Each Makefile target runs the relevant tools for all languages declared in `.devrail.yml`:

| Target | What It Runs |
|---|---|
| `make lint` | ruff check, shellcheck, tflint, ansible-lint, mypy, rubocop, reek, golangci-lint, eslint, tsc, clippy, SwiftLint, ktlint, detekt |
| `make format` | ruff format --check, shfmt -d, terraform fmt -check, terragrunt hclfmt --terragrunt-check, rubocop --check, gofumpt -d, prettier --check, cargo fmt --check, swift-format lint, ktlint --format --dry-run |
| `make fix` | ruff format, shfmt -w, terraform fmt, terragrunt hclfmt, rubocop -a, gofumpt -w, prettier --write, cargo fmt, swift-format format, ktlint --format |
| `make test` | pytest, bats, terratest, molecule, rspec, go test, vitest, cargo test, swift test, gradle test |
| `make security` | bandit, semgrep, tfsec, checkov, brakeman, bundler-audit, govulncheck, npm audit, cargo-audit, cargo-deny, OWASP dependency-check |
| `make scan` | trivy, gitleaks (universal -- all projects) |
| `make docs` | terraform-docs |
| `make changelog` | git-cliff (generate CHANGELOG.md from conventional commits) |
| `make check` | All of the above in sequence |

## Per-Language Pages

- [Coding Practices](/docs/standards/practices/) -- principles, error handling, testing, git workflow
- [Python Standards](/docs/standards/python/) -- ruff, bandit, semgrep, pytest, mypy
- [Bash Standards](/docs/standards/bash/) -- shellcheck, shfmt, bats
- [Terraform Standards](/docs/standards/terraform/) -- tflint, terraform fmt, terragrunt hclfmt, tfsec, checkov, terratest, terraform-docs
- [Ansible Standards](/docs/standards/ansible/) -- ansible-lint, molecule
- [Ruby Standards](/docs/standards/ruby/) -- rubocop, brakeman, bundler-audit, rspec, reek, sorbet
- [Go Standards](/docs/standards/go/) -- golangci-lint, gofumpt, govulncheck, go test
- [JavaScript Standards](/docs/standards/javascript/) -- eslint, prettier, npm audit, vitest, tsc
- [Rust Standards](/docs/standards/rust/) -- clippy, rustfmt, cargo-audit, cargo-deny, cargo test
- [Swift Standards](/docs/standards/swift/) -- SwiftLint, swift-format, swift test, xcodebuild
- [Kotlin Standards](/docs/standards/kotlin/) -- ktlint, detekt, Gradle, Android Lint
- [Universal Security](/docs/standards/universal/) -- trivy, gitleaks, git-cliff

## Consistent Page Structure

The Coding Practices page covers cross-cutting standards (principles, error handling, testing, git workflow) that apply to all languages. Each per-language page follows a consistent structure:

1. **Tools** -- table of tools with category, name, and purpose
2. **Configuration** -- configuration examples with inline comments
3. **Makefile Targets** -- which targets invoke which tools
4. **Pre-Commit Hooks** -- which hooks run locally vs. CI-only
5. **Notes** -- important conventions and gotchas
