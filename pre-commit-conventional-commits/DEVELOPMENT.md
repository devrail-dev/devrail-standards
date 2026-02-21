# Development Guide

This document is the canonical reference for developing the pre-commit-conventional-commits hook. All agent instruction files (CLAUDE.md, AGENTS.md, .cursorrules, .opencode/) point here.

---

<!-- devrail:critical-rules -->

## Critical Rules

These six rules are non-negotiable. Every developer and every AI agent must follow them without exception.

1. **Run `make check` before completing any story or task.** Never mark work done without passing checks. This is the single gate for all linting, formatting, security, and test validation.

2. **Use conventional commits.** Every commit message follows the `type(scope): description` format. No exceptions. See the [Conventional Commits](#conventional-commits) section for types and scopes.

3. **Never install tools outside the container.** All linters, formatters, scanners, and test runners live inside `ghcr.io/devrail-dev/dev-toolchain:v1`. The Makefile delegates to Docker. Do not install tools on the host.

4. **Respect `.editorconfig`.** Never override formatting rules (indent style, line endings, trailing whitespace) without explicit instruction. The `.editorconfig` file in each repo is authoritative.

5. **Write idempotent scripts.** Every script must be safe to re-run. Check before acting: `command -v tool || install_tool`, `mkdir -p`, guard file writes with existence checks.

6. **Use the shared logging library.** No raw `echo` for status messages. Use `log_info`, `log_warn`, `log_error`, `log_debug`, and `die` from `lib/log.sh`.

<!-- /devrail:critical-rules -->

<!-- devrail:commits -->

## Conventional Commits

All commits follow [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): description
```

### Types

| Type | When to Use |
|---|---|
| `feat` | A new feature or capability |
| `fix` | A bug fix |
| `docs` | Documentation-only changes |
| `chore` | Maintenance tasks (dependencies, config) |
| `ci` | CI/CD pipeline changes |
| `refactor` | Code restructuring without behavior change |
| `test` | Adding or updating tests |

### Scopes

| Scope | Applies To |
|---|---|
| `python` | Python tooling, configs, or standards |
| `terraform` | Terraform tooling, configs, or standards |
| `bash` | Bash tooling, configs, or standards |
| `ansible` | Ansible tooling, configs, or standards |
| `container` | Dev-toolchain container image |
| `ci` | CI/CD pipeline configuration |
| `makefile` | Makefile targets and patterns |
| `standards` | DevRail standards documentation |

<!-- /devrail:commits -->

## Project Structure

```
pre-commit-conventional-commits/
├── .devrail.yml                 # DevRail project configuration
├── .editorconfig                # Editor formatting rules
├── .gitignore                   # Git ignore patterns
├── .pre-commit-config.yaml      # Pre-commit hooks for this repo
├── .pre-commit-hooks.yaml       # Hook manifest consumed by pre-commit
├── CHANGELOG.md                 # Auto-generated changelog
├── DEVELOPMENT.md               # This file
├── LICENSE                      # MIT license
├── Makefile                     # Build and check targets
├── README.md                    # User-facing documentation
├── setup.cfg                    # Python package configuration
├── setup.py                     # Python package setup
├── conventional_commits/        # Hook source code
│   ├── __init__.py
│   ├── check.py                 # Commit message validation logic
│   └── config.py                # Types, scopes, patterns, templates
└── tests/                       # Test suite
    ├── __init__.py
    ├── test_check.py            # Tests for check module
    └── test_config.py           # Tests for config module
```

## Development Setup

```bash
# Clone the repo
git clone https://github.com/devrail-dev/pre-commit-conventional-commits.git
cd pre-commit-conventional-commits

# Install pre-commit hooks
make install-hooks

# Run tests
make test

# Run all checks
make check
```

## Running Tests

```bash
# Via Makefile (recommended — runs inside container)
make test

# Direct pytest (development only)
pytest tests/ -v
```

## Makefile Targets

Run `make help` to see all available targets:

```
check                Run all checks (lint, format, test, security, docs)
docs                 Generate documentation
format               Run all formatters
help                 Show this help
install-hooks        Install pre-commit hooks
lint                 Run all linters
scan                 Run full scan (lint + security)
security             Run security scanners
test                 Run all tests
```

## Architecture

This repo provides a single pre-commit hook (`conventional-commits`) that validates commit messages against the DevRail conventional commit format. The hook:

1. Is consumed by every DevRail-compliant repo via `.pre-commit-config.yaml`
2. Runs as a `commit-msg` stage hook (not `pre-commit` stage)
3. Validates only the subject line (first line) of the commit message
4. Allows merge and revert commits to pass through
5. Provides clear, actionable error messages on rejection
