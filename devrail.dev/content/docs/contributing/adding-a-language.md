---
title: "Adding a New Language"
linkTitle: "Adding a Language"
weight: 10
description: "Step-by-step guide for adding a new language ecosystem to DevRail."
---

Adding a new language to DevRail involves changes across multiple repositories. This guide walks through the complete process.

{{% alert title="Canonical Reference" color="info" %}}
The authoritative, detailed version of this guide with full code templates and concrete examples lives in the `devrail-standards` repo at [`standards/contributing-a-language.md`](https://github.com/devrail-dev/devrail-standards/blob/main/standards/contributing-a-language.md). This page provides the overview; the canonical guide provides copy-pasteable templates for every step.
{{% /alert %}}

## Overview

Adding a language ecosystem requires updates to six areas:

1. **Install script** in `dev-toolchain` -- installs the language's tools in the container
2. **Makefile targets** in `dev-toolchain` -- adds `_lint`, `_format`, `_test`, `_security` targets
3. **Pre-commit hooks** -- configures local hooks for the new language
4. **Standards document** in `devrail-standards` -- documents the tools and conventions
5. **Verification tests** in `dev-toolchain` -- validates all tools work correctly
6. **Schema update** in `devrail-standards` -- adds the new language to `.devrail.yml` accepted values

## Step 1: Create the Install Script

Create `scripts/install-<language>.sh` in the `dev-toolchain` repository. The script must follow DevRail shell conventions:

```bash
#!/usr/bin/env bash
# Purpose: Install <language> development tools
# Usage: install-<language>.sh
# Dependencies: curl, apt-get (or appropriate package manager)
set -euo pipefail

# Source shared logging library
source "$(dirname "$0")/../lib/log.sh"

install_linter() {
  # Check before installing (idempotent)
  if command -v <linter> > /dev/null 2>&1; then
    log_info "<linter> already installed"
    return 0
  fi

  log_info "Installing <linter>..."
  # Installation commands here
}

install_formatter() {
  if command -v <formatter> > /dev/null 2>&1; then
    log_info "<formatter> already installed"
    return 0
  fi

  log_info "Installing <formatter>..."
  # Installation commands here
}

# Main
install_linter
install_formatter
log_info "<language> tools installed successfully"
```

Key requirements:

- **Idempotent** -- check before installing, safe to re-run
- **Uses `lib/log.sh`** -- no raw `echo` for status messages
- **Self-documenting header** -- purpose, usage, dependencies

## Step 2: Add Makefile Targets

Add internal targets to the `dev-toolchain` Makefile for the new language:

```makefile
# Internal targets for <language>
_lint-<language>:
	<linter-command>

_format-<language>:
	<formatter-command>

_test-<language>:
	<test-runner-command>

_security-<language>:
	<security-scanner-command>
```

Update the existing `_lint`, `_format`, `_test`, and `_security` targets to include the new language when it is declared in `.devrail.yml`.

## Step 3: Configure Pre-Commit Hooks

Add pre-commit hook entries for the new language's local hooks (those that run in under 30 seconds):

```yaml
# .pre-commit-config.yaml additions for <language>
repos:
  - repo: https://github.com/<org>/<linter-hook>
    rev: ""
    hooks:
      - id: <linter>
  - repo: https://github.com/<org>/<formatter-hook>
    rev: ""
    hooks:
      - id: <formatter>
```

Remember the split: fast hooks (linting, formatting) run locally; slow hooks (security scanning, full tests) run in CI only.

## Step 4: Write the Standards Document

Create `standards/<language>.md` in the `devrail-standards` repository. Follow the consistent structure used by all per-language standards pages:

```markdown
# <Language> Standards

## Tools

| Concern | Tool | Version Strategy |
|---|---|---|
| Linter | <linter> | Latest in container |
| Formatter | <formatter> | Latest in container |
| Security | <scanner> | Latest in container |
| Tests | <test-runner> | Latest in container |

## Configuration

[Configuration file examples with inline comments]

## Makefile Targets

[Which targets run which tools]

## Pre-Commit Hooks

[Local hooks and CI-only hooks]

## Notes

[Important conventions and gotchas]
```

## Step 5: Write Verification Tests

Create `tests/test-<language>.sh` in the `dev-toolchain` repository:

```bash
#!/usr/bin/env bats
# tests/test-<language>.sh -- verify <language> tools are installed and working

@test "<linter> is installed" {
  run command -v <linter>
  [ "$status" -eq 0 ]
}

@test "<linter> runs successfully" {
  run <linter> --version
  [ "$status" -eq 0 ]
}

@test "<formatter> is installed" {
  run command -v <formatter>
  [ "$status" -eq 0 ]
}
```

## Step 6: Update the `.devrail.yml` Schema

In `devrail-standards`, update `standards/devrail-yml-schema.md` to add the new language to the list of allowed values for the `languages` key:

```yaml
# Updated allowed values
languages:
  - python
  - bash
  - terraform
  - ansible
  - <new-language>  # Add the new language
```

## Checklist

Before submitting your pull requests, verify:

- [ ] Install script is idempotent (safe to re-run)
- [ ] Install script uses `lib/log.sh` for logging
- [ ] All tools install and run inside the dev-toolchain container
- [ ] Makefile targets follow the naming conventions (`_lint`, `_format`, `_test`, `_security`)
- [ ] Pre-commit hooks complete in under 30 seconds
- [ ] Standards document follows the consistent structure
- [ ] Verification tests pass inside the container
- [ ] `.devrail.yml` schema is updated
- [ ] All commits use conventional commit format

## Pull Request Strategy

Adding a new language requires coordinated changes across multiple repos. Submit PRs in this order:

1. **`dev-toolchain`** -- install script + Makefile targets + tests
2. **`devrail-standards`** -- standards document + schema update
3. **Templates** -- update `.pre-commit-config.yaml` with new hooks
4. **`devrail.dev`** -- add documentation page for the new language
