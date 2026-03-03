# Bash Standards

## Tools

| Concern | Tool | Version Strategy |
|---|---|---|
| Linter | shellcheck | Latest in container |
| Formatter | shfmt | Latest in container |
| Tests | bats | Latest in container |

## Configuration

### shellcheck

Config file: `.shellcheckrc` at repository root.

Recommended `.shellcheckrc`:

```
# Default shell dialect
shell=bash

# Enable all optional checks
enable=all
```

shellcheck validates all shell scripts against best practices and catches common errors (quoting, globbing, portability issues).

### shfmt

No config file. Flags are passed on the command line.

Required flags:

| Flag | Meaning |
|---|---|
| `-i 2` | Indent with 2 spaces |
| `-ci` | Indent switch cases |
| `-bn` | Binary operators at start of next line |

Format check: `shfmt -d -i 2 -ci -bn .`
Format fix: `shfmt -w -i 2 -ci -bn .`

### bats

No config file required. Test files use the `.bats` extension and live in the `tests/` directory.

Example test structure:

```bash
#!/usr/bin/env bats

@test "script exits zero on success" {
  run ./scripts/my-script.sh --help
  [ "$status" -eq 0 ]
}
```

## Makefile Targets

| Target | Command | Description |
|---|---|---|
| `_lint` | `shellcheck scripts/*.sh` | Lint all shell scripts |
| `_format` | `shfmt -d -i 2 -ci -bn .` | Check formatting (no changes) |
| `_format` (fix) | `shfmt -w -i 2 -ci -bn .` | Apply formatting fixes |
| `_test` | `bats tests/` | Run bats test suite |

See [DEVELOPMENT.md](../DEVELOPMENT.md) for the full Makefile contract and two-layer delegation pattern.

## Pre-Commit Hooks

### Local Hooks (< 30 seconds)

These run on every commit via `pre-commit`:

```yaml
repos:
  - repo: https://github.com/shellcheck-py/shellcheck-py
    rev: ""  # container manages version
    hooks:
      - id: shellcheck
  - repo: https://github.com/scop/pre-commit-shfmt
    rev: ""  # container manages version
    hooks:
      - id: shfmt
        args: [-i, "2", -ci, -bn]
```

### CI-Only

These run via `make test` in CI pipelines. They are **not** configured as pre-commit hooks due to execution time:

- `bats tests/` -- full test suite

## Notes

- All shell scripts must begin with `#!/usr/bin/env bash` and `set -euo pipefail`. No exceptions. See [DEVELOPMENT.md Shell Script Conventions](../DEVELOPMENT.md#shell-script-conventions) for full coding standards.
- Scripts must be idempotent -- safe to re-run without side effects.
- Use shared logging functions (`log_info`, `log_warn`, `log_error`, `log_debug`, `die`) from `lib/log.sh`. No raw `echo` for status messages.
- Variables: `UPPER_SNAKE_CASE` with `readonly` for constants, `lower_snake_case` for locals.
- Functions: `lower_snake_case`, prefixed by purpose (`install_`, `check_`, `log_`).
- Every script supports `--help` and uses `getopts` for argument parsing.
- All tools are pre-installed in the dev-toolchain container. Do not install them on the host.
- For cross-cutting practices (DRY, idempotency, error handling, testing, naming) and git workflow (branching, code review, conventional commits), see [Coding Practices](coding-practices.md) and [Git Workflow](git-workflow.md).
