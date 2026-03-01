# devrail-standards

> **Beta** -- DevRail is under active development. Standards, tooling, and documentation may change without notice. See [STABILITY.md](STABILITY.md) for details.

Opinionated development standards for teams that ship with AI agents.

<!-- badges-start -->
<!-- TODO: Add CI status badge when CI pipeline is configured -->
<!-- TODO: Add license badge (MIT) -->
<!-- TODO: Add version/release badge -->
<!-- badges-end -->

## Quick Start

1. Clone this repository and read the standards that apply to your language.
2. Copy `.devrail.yml`, `Makefile`, and agent instruction files into your project (or use a DevRail template repo).
3. Run `make help` to see available targets.

## Usage

The Makefile is the universal execution interface for all DevRail-managed projects. Every target produces consistent behavior whether invoked by a developer, CI pipeline, or AI agent.

| Target | Purpose |
|---|---|
| `make help` | Show available targets (default) |
| `make lint` | Run all linters for declared languages |
| `make format` | Run all formatters for declared languages |
| `make test` | Run project test suite |
| `make security` | Run language-specific security scanners |
| `make scan` | Run universal scanning (trivy, gitleaks) |
| `make docs` | Generate documentation |
| `make check` | Run all of the above; report composite summary |
| `make install-hooks` | Install pre-commit hooks |

All targets except `help` and `install-hooks` delegate to the dev-toolchain Docker container. See the [Makefile contract specification](standards/makefile-contract.md) for the full behavioral contract.

## Standards

The `standards/` directory contains the canonical reference documents for all DevRail conventions:

| Document | Description |
|---|---|
| [makefile-contract.md](standards/makefile-contract.md) | Makefile target contract, two-layer delegation pattern, error handling, and output format |
| [devrail-yml-schema.md](standards/devrail-yml-schema.md) | `.devrail.yml` configuration file schema specification |
| [python.md](standards/python.md) | Python tooling standards (ruff, bandit, pytest, mypy) |
| [bash.md](standards/bash.md) | Bash tooling standards (shellcheck, shfmt, bats) |
| [terraform.md](standards/terraform.md) | Terraform tooling standards (tflint, tfsec, checkov, terraform-docs) |
| [ansible.md](standards/ansible.md) | Ansible tooling standards (ansible-lint, molecule) |
| [ruby.md](standards/ruby.md) | Ruby tooling standards (rubocop, brakeman, bundler-audit, rspec, reek, sorbet) |
| [go.md](standards/go.md) | Go tooling standards (golangci-lint, gofumpt, govulncheck, go test) |
| [javascript.md](standards/javascript.md) | JavaScript/TypeScript tooling standards (eslint, prettier, npm audit, vitest, tsc) |
| [universal.md](standards/universal.md) | Universal security tools (trivy, gitleaks) |
| [coding-practices.md](standards/coding-practices.md) | General coding principles, naming, error handling, testing, and dependencies |
| [git-workflow.md](standards/git-workflow.md) | Branch strategy, pull requests, code review, merge policy, and git security |
| [release-versioning.md](standards/release-versioning.md) | Semantic versioning, tagging, release process, hotfixes, and changelogs |
| [ci-cd-pipelines.md](standards/ci-cd-pipelines.md) | Pipeline structure, stage contracts, deployment gates, and artifact management |
| [container-standards.md](standards/container-standards.md) | Base images, multi-stage builds, security, image tagging, and health checks |
| [secrets-management.md](standards/secrets-management.md) | Secret classification, storage, rotation, access control, and CI/CD secrets |
| [api-cli-design.md](standards/api-cli-design.md) | API versioning, error responses, CLI conventions, and backward compatibility |
| [monitoring-observability.md](standards/monitoring-observability.md) | Health checks, structured logging, metrics, alerting, and dashboards |
| [incident-response.md](standards/incident-response.md) | Severity levels, incident workflow, post-mortems, runbooks, and on-call |
| [data-handling.md](standards/data-handling.md) | Data classification, PII handling, retention, encryption, and compliance |
| [agent-instructions.md](standards/agent-instructions.md) | AI agent instruction file strategy and hybrid shim pattern |
| [contributing-a-language.md](standards/contributing-a-language.md) | Step-by-step guide for adding a new language ecosystem |

## Configuration

Every DevRail-managed repository includes a `.devrail.yml` file at the repo root. This file declares the project's languages and settings, and is read by the Makefile, CI pipelines, and AI agents.

```yaml
languages:
  - python
  - bash

fail_fast: false
log_format: json
```

See [standards/devrail-yml-schema.md](standards/devrail-yml-schema.md) for the complete schema specification, including per-language tool overrides and the full language support matrix.

## Contributing

See [DEVELOPMENT.md](DEVELOPMENT.md) for development standards, coding conventions, and contribution guidelines.

To add a new language ecosystem to DevRail, see [Contributing a New Language Ecosystem](standards/contributing-a-language.md).

This project follows [Conventional Commits](https://www.conventionalcommits.org/). All commits use the `type(scope): description` format.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
