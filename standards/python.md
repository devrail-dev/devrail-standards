# Python Standards

## Tools

| Concern | Tool | Version Strategy |
|---|---|---|
| Linter | ruff | Latest in container |
| Formatter | ruff format | Latest in container |
| Security | bandit | Latest in container |
| Security | semgrep | Latest in container |
| Tests | pytest | Latest in container |
| Type Check | mypy | Latest in container |

## Configuration

### ruff

Config file: `ruff.toml` or `pyproject.toml` under `[tool.ruff]`.

Recommended `ruff.toml`:

```toml
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
[tool.bandit]
exclude_dirs = ["tests"]
skips = []
```

### semgrep

No project-level config file required. Uses `--config auto` to pull community rulesets.

### pytest

Config in `pyproject.toml`:

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-v --tb=short"
```

### mypy

Config in `pyproject.toml`:

```toml
[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_configs = true
```

## Makefile Targets

| Target | Command | Description |
|---|---|---|
| `_lint` | `ruff check .` | Lint all Python files |
| `_lint` | `mypy .` | Static type checking |
| `_format` | `ruff format --check .` | Check formatting (no changes) |
| `_format` (fix) | `ruff format .` | Apply formatting fixes |
| `_security` | `bandit -r .` | Security-focused static analysis |
| `_security` | `semgrep --config auto .` | Pattern-based security scanning |
| `_test` | `pytest` | Run test suite |

See [DEVELOPMENT.md](../DEVELOPMENT.md) for the full Makefile contract and two-layer delegation pattern.

## Pre-Commit Hooks

### Local Hooks (< 30 seconds)

These run on every commit via `pre-commit`:

```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: ""  # container manages version
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
```

### CI-Only

These run via `make security` and `make test` in CI pipelines. They are **not** configured as pre-commit hooks due to execution time:

- `bandit -r .` -- security scanning
- `semgrep --config auto .` -- pattern-based scanning
- `pytest` -- full test suite
- `mypy .` -- type checking (when project is large)

## Notes

- ruff is the single tool for both linting and formatting. Do not use flake8, isort, black, or autopep8.
- `mypy` runs as part of `make lint`, not as a separate target.
- `bandit` and `semgrep` run as part of `make security`. They are complementary: bandit catches Python-specific issues, semgrep applies broader security patterns.
- All tools are pre-installed in the dev-toolchain container. Do not install them on the host.
- Python CLIs in DevRail repos use Click for argument parsing (see [DEVELOPMENT.md Shell Script Conventions](../DEVELOPMENT.md#shell-script-conventions)).
