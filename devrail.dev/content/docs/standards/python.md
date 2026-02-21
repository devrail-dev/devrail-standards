---
title: "Python Standards"
linkTitle: "Python"
weight: 10
description: "Python tooling standards: ruff, bandit, semgrep, pytest, and mypy."
---

## Tools

| Category | Tool | Purpose |
|---|---|---|
| Linting | ruff | Fast Python linter (replaces flake8, isort, pyupgrade) |
| Formatting | ruff format | Fast Python formatter (replaces black) |
| Security | bandit | Security-focused AST linter for Python |
| Security | semgrep | Multi-language static analysis with security rules |
| Testing | pytest | Standard Python test runner |
| Type Checking | mypy | Static type checker for Python |

All tools are pre-installed in the dev-toolchain container. Do not install them on the host.

## Configuration

### ruff

Config file: `ruff.toml` or `pyproject.toml` under `[tool.ruff]`.

Recommended `ruff.toml`:

```toml
# ruff.toml -- DevRail Python linting and formatting configuration
line-length = 120
target-version = "py311"

[lint]
select = [
    "E",    # pycodestyle errors
    "W",    # pycodestyle warnings
    "F",    # pyflakes
    "I",    # isort
    "UP",   # pyupgrade
    "B",    # flake8-bugbear
    "S",    # flake8-bandit (subset)
    "C4",   # flake8-comprehensions
    "SIM",  # flake8-simplify
]

[format]
quote-style = "double"
indent-style = "space"
```

ruff replaces flake8, isort, pyupgrade, and black. Do not install those tools separately.

### bandit

Config in `pyproject.toml`:

```toml
# pyproject.toml -- bandit security scanning configuration
[tool.bandit]
exclude_dirs = ["tests"]
skips = []
```

### semgrep

No project-level config file required. Uses `--config auto` to pull community rulesets.

```bash
# semgrep runs with auto-config to apply community security rules
semgrep --config auto .
```

### pytest

Config in `pyproject.toml`:

```toml
# pyproject.toml -- pytest test runner configuration
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-v --tb=short"
```

### mypy

Config in `pyproject.toml`:

```toml
# pyproject.toml -- mypy static type checking configuration
[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_configs = true
```

## Makefile Targets

| Target | Command | Description |
|---|---|---|
| `make lint` | `ruff check .` | Lint all Python files |
| `make lint` | `mypy .` | Static type checking |
| `make format` | `ruff format --check .` | Check formatting (no changes) |
| `make security` | `bandit -r .` | Security-focused static analysis |
| `make security` | `semgrep --config auto .` | Pattern-based security scanning |
| `make test` | `pytest` | Run test suite |

All targets delegate to the dev-toolchain container via the two-layer Makefile delegation pattern. The public target (e.g., `make lint`) runs on the host and invokes `docker run ... make _lint` inside the container.

## Pre-Commit Hooks

### Local Hooks (run on every commit, under 30 seconds)

```yaml
# .pre-commit-config.yaml -- Python hooks
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: ""  # container manages version
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
```

### CI-Only (too slow for local hooks)

These tools run via `make security` and `make test` in CI pipelines:

- `bandit -r .` -- security scanning
- `semgrep --config auto .` -- pattern-based scanning
- `pytest` -- full test suite
- `mypy .` -- type checking (when project is large)

## Notes

- **ruff is the single tool for both linting and formatting.** Do not use flake8, isort, black, or autopep8 alongside ruff.
- **mypy runs as part of `make lint`**, not as a separate target. It validates type annotations alongside ruff's lint checks.
- **bandit and semgrep are complementary.** Bandit catches Python-specific issues, semgrep applies broader security patterns. Both run as part of `make security`.
- **All tools are pre-installed in the dev-toolchain container.** Do not install them on the host machine.
- **Python CLIs in DevRail repos use Click** for argument parsing (not argparse).
