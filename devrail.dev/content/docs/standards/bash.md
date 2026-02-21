---
title: "Bash Standards"
linkTitle: "Bash"
weight: 20
description: "Bash tooling standards: shellcheck, shfmt, and bats."
---

## Tools

| Category | Tool | Purpose |
|---|---|---|
| Linting | shellcheck | Static analysis for shell scripts |
| Formatting | shfmt | Consistent shell script formatting |
| Testing | bats | Bash Automated Testing System |

All tools are pre-installed in the dev-toolchain container. Do not install them on the host.

## Configuration

### shellcheck

Config file: `.shellcheckrc` at repository root.

Recommended `.shellcheckrc`:

```bash
# .shellcheckrc -- DevRail shell script linting configuration

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

```bash
# Check formatting (no changes -- exits non-zero if formatting differs)
shfmt -d -i 2 -ci -bn .

# Apply formatting fixes
shfmt -w -i 2 -ci -bn .
```

### bats

No config file required. Test files use the `.bats` extension and live in the `tests/` directory.

Example test structure:

```bash
#!/usr/bin/env bats
# tests/test-my-script.bats -- example bats test file

@test "script exits zero on success" {
  run ./scripts/my-script.sh --help
  [ "$status" -eq 0 ]
}

@test "script fails on missing argument" {
  run ./scripts/my-script.sh
  [ "$status" -ne 0 ]
}
```

## Makefile Targets

| Target | Command | Description |
|---|---|---|
| `make lint` | `shellcheck scripts/*.sh` | Lint all shell scripts |
| `make format` | `shfmt -d -i 2 -ci -bn .` | Check formatting (no changes) |
| `make test` | `bats tests/` | Run bats test suite |

All targets delegate to the dev-toolchain container via the two-layer Makefile delegation pattern.

## Pre-Commit Hooks

### Local Hooks (run on every commit, under 30 seconds)

```yaml
# .pre-commit-config.yaml -- Bash hooks
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

### CI-Only (too slow for local hooks)

- `bats tests/` -- full test suite

## Shell Script Conventions

All shell scripts in DevRail-managed repositories must follow these conventions:

### Mandatory Header

Every shell script begins with:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

No exceptions.

### Idempotency

Scripts must be safe to re-run without side effects:

```bash
# Check before installing
command -v my-tool > /dev/null 2>&1 || install_my_tool

# Create directories safely
mkdir -p /path/to/directory

# Guard file writes with existence checks
if [ ! -f /path/to/config ]; then
  create_config
fi
```

### Naming Conventions

| Element | Convention | Example |
|---|---|---|
| Environment variables / constants | `UPPER_SNAKE_CASE` with `readonly` | `readonly DEVRAIL_VERSION="1.0.0"` |
| Local variables | `lower_snake_case` | `local output_dir` |
| Functions | `lower_snake_case`, prefixed by purpose | `install_python`, `check_deps` |

### Logging

Use shared log functions from `lib/log.sh`. Never use raw `echo` for status messages:

```bash
# Correct -- use shared logging functions
log_info "Starting installation"
log_warn "Config file not found, using defaults"
log_error "Installation failed"
die "Critical error -- cannot continue"

# Incorrect -- never use raw echo for status output
echo "Starting installation"  # Do not do this
```

## Notes

- **All scripts must begin with `#!/usr/bin/env bash` and `set -euo pipefail`.** No exceptions.
- **Scripts must be idempotent** -- safe to re-run without side effects.
- **Use shared logging functions** from `lib/log.sh`. No raw `echo` for status messages.
- **Every script supports `--help`** and uses `getopts` for argument parsing.
- **All tools are pre-installed in the dev-toolchain container.** Do not install them on the host.
