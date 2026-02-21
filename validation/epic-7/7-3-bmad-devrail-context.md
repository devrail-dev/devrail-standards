# Story 7.3 -- DevRail Context for BMAD Planning Sessions

## Purpose

This document provides the DevRail reference material to give to a BMAD planning agent when validating whether BMAD can incorporate DevRail standards into architecture and planning artifacts. Use this as the DevRail context input during the BMAD planning session.

## How to Use

1. Start a BMAD planning session
2. Provide the project scenario (see `7-3-planning-scenario.md`)
3. Include this DevRail context as reference material for the BMAD agent
4. Instruct the BMAD agent: "This project follows DevRail development standards. Incorporate these standards into the architecture and planning artifacts."

---

## DevRail Standards Summary

### Overview

DevRail is a developer infrastructure platform that provides:
- A **dev-toolchain container** (`ghcr.io/devrail-dev/dev-toolchain:v1`) containing all linters, formatters, scanners, and test runners
- A **Makefile contract** that provides a universal execution interface: `make lint`, `make format`, `make test`, `make security`, `make scan`, `make docs`, `make check` (runs all)
- **Agent instruction files** (CLAUDE.md, AGENTS.md, .cursorrules, .opencode/agents.yaml) that tell AI agents how to work on the project
- A **`.devrail.yml` configuration file** at the repo root that declares languages and settings

### Critical Rules (Must Be In Every Story)

1. **Run `make check` before completing any story or task.** This is the single gate for all linting, formatting, security, and test validation.
2. **Use conventional commits.** Format: `type(scope): description`. Types: feat, fix, docs, chore, ci, refactor, test. Scopes: python, terraform, bash, ansible, container, ci, makefile, standards.
3. **Never install tools outside the container.** All tools run inside the dev-toolchain container via Makefile targets.
4. **Respect `.editorconfig`.** Formatting rules are defined in `.editorconfig` at the repo root.
5. **Write idempotent scripts.** Scripts must be safe to re-run.
6. **Use the shared logging library.** Use `log_info`, `log_warn`, `log_error`, `log_debug`, and `die` from `lib/log.sh`.

### Makefile Contract

Every DevRail-managed repo exposes these public targets:

| Target | Purpose |
|---|---|
| `make help` | List all targets (default target) |
| `make lint` | Run all linters |
| `make format` | Run all formatters |
| `make test` | Run all test suites |
| `make security` | Run security scanners |
| `make scan` | Run universal scanners (trivy, gitleaks) |
| `make docs` | Generate documentation |
| `make check` | Run ALL of the above |
| `make install-hooks` | Install pre-commit hooks |

### Project Structure

Every DevRail-managed project contains:

```
project-root/
  .devrail.yml           # Language declarations and settings
  .editorconfig          # Formatting rules
  .pre-commit-config.yaml # Pre-commit hook configuration
  Makefile               # Universal execution interface
  DEVELOPMENT.md         # Canonical standards reference
  CLAUDE.md              # Claude Code agent instructions
  AGENTS.md              # Generic agent instructions
  .cursorrules           # Cursor agent instructions
  .opencode/
    agents.yaml          # OpenCode agent instructions
```

### What BMAD-Generated Artifacts Should Include

**In architecture documents:**
- Reference to `ghcr.io/devrail-dev/dev-toolchain:v1` as the tool execution environment
- Reference to the Makefile contract (`make check`, `make lint`, etc.) as the developer interface
- Reference to `.devrail.yml` as the project configuration file
- Reference to agent instruction files as part of the project structure

**In epic/story artifacts:**
- `make check` as a standard acceptance criterion or completion gate
- Conventional commits referenced in dev notes
- "No tools outside the container" as a constraint
- Agent instruction files listed in project structure notes

### Language Tooling

| Language | Linter | Formatter | Security | Tests |
|---|---|---|---|---|
| Python | ruff | ruff format | bandit, semgrep | pytest |
| Bash | shellcheck | shfmt | -- | bats |
| Terraform | tflint | terraform fmt | tfsec, checkov | terratest |
| Ansible | ansible-lint | -- | -- | molecule |

### Shell Script Requirements

- `#!/usr/bin/env bash` + `set -euo pipefail` (always)
- Idempotent (check before acting)
- Use shared logging library from `lib/log.sh`
- Shellcheck compliant
- Structured header comment (Purpose, Usage, Dependencies)
