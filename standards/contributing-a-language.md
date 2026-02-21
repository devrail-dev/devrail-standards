# Contributing a New Language Ecosystem to DevRail

This document is the authoritative step-by-step guide for adding a new language ecosystem (e.g., Go, Rust, Ruby) to DevRail. It describes the exact pattern established by the existing four languages (Python, Bash, Terraform, Ansible) and references concrete examples at each step.

For a high-level overview of the DevRail ecosystem structure and general contribution workflow, see the [Contributing section on devrail.dev](https://devrail.dev/docs/contributing/).

---

## Architecture Overview

Adding a new language to DevRail involves coordinated changes across multiple repositories. The language ecosystem pattern ensures that every language receives identical treatment: install script, Makefile targets, pre-commit hooks, standards documentation, and verification tests.

```
1. dev-toolchain repo:
   ├── scripts/install-<language>.sh    <-- Install tools into the container
   ├── tests/test-<language>.sh         <-- Verify tools are installed correctly
   └── Dockerfile                       <-- Add install script invocation

2. devrail-standards repo:
   ├── standards/<language>.md          <-- Document tools and configuration
   └── standards/devrail-yml-schema.md  <-- Add the new language to accepted values

3. Reference Makefile (in dev-toolchain and template repos):
   └── Makefile                         <-- Add _lint/_format/_test/_security targets

4. Pre-commit config (in template repos):
   └── .pre-commit-config.yaml          <-- Add language-specific hooks

5. Documentation site (devrail.dev):
   └── content/docs/standards/<lang>.md <-- Publish the standards page
```

The container rebuild process is automatic: when a new install script is merged to `dev-toolchain`, the weekly build (or a manual trigger) produces a new container image containing the new tools. Template repos pick up the new language support the next time `make check` runs with the updated container.

---

## Step 1: Create the Install Script

**Repo:** `dev-toolchain`
**File:** `scripts/install-<language>.sh`
**Example:** See `scripts/install-python.sh` for a complete example.

Every install script follows the same conventions:

```bash
#!/usr/bin/env bash
# scripts/install-<language>.sh -- Install <language> tooling for DevRail
#
# Purpose: Installs <language> linting, formatting, security, and testing tools
#          into the dev-toolchain container.
# Usage:   bash scripts/install-<language>.sh [--help]
# Dependencies: <prerequisites>, lib/log.sh, lib/platform.sh
#
# Tools installed:
#   - <linter>     (<description>)
#   - <formatter>  (<description>)
#   - <scanner>    (<description>)
#   - <test-runner>(<description>)

set -euo pipefail

# --- Resolve library path ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVRAIL_LIB="${DEVRAIL_LIB:-${SCRIPT_DIR}/../lib}"

# shellcheck source=../lib/log.sh
source "${DEVRAIL_LIB}/log.sh"
# shellcheck source=../lib/platform.sh
source "${DEVRAIL_LIB}/platform.sh"

# --- Help ---
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  log_info "install-<language>.sh -- Install <language> tooling for DevRail"
  log_info "Usage: bash scripts/install-<language>.sh [--help]"
  log_info "Tools: <linter>, <formatter>, <scanner>, <test-runner>"
  exit 0
fi

# --- Cleanup trap ---
TMPDIR_CLEANUP=""
cleanup() {
  if [[ -n "${TMPDIR_CLEANUP}" && -d "${TMPDIR_CLEANUP}" ]]; then
    rm -rf "${TMPDIR_CLEANUP}"
  fi
}
trap cleanup EXIT

# --- Tool installation functions ---

install_linter() {
  if command -v <linter> &>/dev/null; then
    log_info "<linter> already installed, skipping"
    return 0
  fi

  log_info "Installing <linter>..."
  # Installation commands here

  require_cmd "<linter>" "Failed to install <linter>"
  log_info "<linter> installed successfully"
}

install_formatter() {
  if command -v <formatter> &>/dev/null; then
    log_info "<formatter> already installed, skipping"
    return 0
  fi

  log_info "Installing <formatter>..."
  # Installation commands here

  require_cmd "<formatter>" "Failed to install <formatter>"
  log_info "<formatter> installed successfully"
}

# --- Main ---
log_info "Installing <language> tools..."
install_linter
install_formatter
log_info "<language> tools installed successfully"
```

### Key Conventions

| Convention | Requirement |
|---|---|
| Shebang | `#!/usr/bin/env bash` |
| Error handling | `set -euo pipefail` |
| Library sourcing | Source `lib/log.sh` and `lib/platform.sh` |
| Idempotency | Check `command -v <tool>` before installing |
| Logging | Use `log_info`, `log_warn`, `log_error` -- never raw `echo` |
| Help flag | Support `--help` / `-h` |
| Cleanup | Register `trap cleanup EXIT` for temp files |
| Verification | End each install function with `require_cmd` |
| Header | Structured comment with purpose, usage, dependencies, tools list |

### Existing Examples

- `scripts/install-python.sh` -- pip-based installation with ruff, bandit, semgrep, pytest, mypy
- `scripts/install-bash.sh` -- binary downloads for shellcheck and shfmt, bats from source
- `scripts/install-terraform.sh` -- Go builder stage binaries + pip packages
- `scripts/install-ansible.sh` -- pip-based installation with ansible-lint, molecule
- `scripts/install-universal.sh` -- Go builder stage for trivy and gitleaks

---

## Step 2: Update the Dockerfile

**Repo:** `dev-toolchain`
**File:** `Dockerfile`

Add the new install script invocation to the Dockerfile. Follow the existing pattern:

```dockerfile
# -- <Language> tools --
COPY scripts/install-<language>.sh /tmp/scripts/
RUN bash /tmp/scripts/install-<language>.sh
```

If the language requires Go-based tools compiled from source, add them to the builder stage (see how `install-terraform.sh` and `install-universal.sh` handle Go builder artifacts).

---

## Step 3: Add Makefile Targets

**Repo:** `dev-toolchain` (and template repos)
**File:** `Makefile`

The Makefile uses `.devrail.yml` to detect which languages are declared. Add conditional blocks for the new language in each internal target (`_lint`, `_format`, `_test`, `_security`).

The pattern for each target is identical. Here is the lint target as an example:

```makefile
# Inside the _lint target, add a block for the new language:
if [ -n "$(HAS_<LANGUAGE>)" ]; then \
    ran_languages="$${ran_languages}\"<language>\","; \
    <lint-command> || { overall_exit=1; failed_languages="$${failed_languages}\"<language>\","; }; \
    if [ "$(DEVRAIL_FAIL_FAST)" = "1" ] && [ $$overall_exit -ne 0 ]; then \
        end_time=$$(date +%s%3N); \
        duration=$$((end_time - start_time)); \
        echo "{\"target\":\"lint\",\"status\":\"fail\",\"duration_ms\":$$duration,\"languages\":[$${ran_languages%,}],\"failed\":[$${failed_languages%,}]}"; \
        exit $$overall_exit; \
    fi; \
fi;
```

Also add the language detection variable near the top of the Makefile:

```makefile
HAS_<LANGUAGE> := $(filter <language>,$(LANGUAGES))
```

### Existing Examples

See the `dev-toolchain/Makefile` for complete examples of how Python, Bash, Terraform, and Ansible blocks are structured within `_lint`, `_format`, `_test`, and `_security` targets.

---

## Step 4: Configure Pre-Commit Hooks

**Repo:** Template repos (`github-repo-template`, `gitlab-repo-template`)
**File:** `.pre-commit-config.yaml`

Add language-specific hooks that run locally (under 30 seconds). Follow the fast-local / slow-CI split:

- **Local hooks (fast):** Linting, formatting, auto-fixes
- **CI-only (slow):** Security scanning, full test suites, heavy analysis

```yaml
# .pre-commit-config.yaml additions for <language>
# --- <Language>: <linter> ---
# <Description of what it checks>
# Triggers on: <file types>
# .devrail.yml language: <language>
- repo: https://github.com/<org>/<linter-hook-repo>
  rev: <pinned-version>
  hooks:
    - id: <linter>

# --- <Language>: <formatter> ---
# <Description of formatting behavior>
- repo: https://github.com/<org>/<formatter-hook-repo>
  rev: <pinned-version>
  hooks:
    - id: <formatter>
```

### Existing Examples

See `pre-commit-conventional-commits/.pre-commit-config.yaml` (Story 4.2) for the comprehensive reference with all four language ecosystems configured. Key entries:

- **Python:** `ruff-pre-commit` (ruff check + ruff format)
- **Bash:** `shellcheck-py` + `pre-commit-shfmt`
- **Terraform:** `pre-commit-terraform` (terraform_fmt, terraform_tflint, terraform_docs)
- **Ansible:** `ansible-lint`

---

## Step 5: Write the Standards Document

**Repo:** `devrail-standards`
**File:** `standards/<language>.md`

Every language standards document follows a consistent structure. Use the existing documents as templates:

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

### <linter>

Config file: `<config-file>` at repository root.

Recommended configuration:

[Include annotated configuration example]

### <formatter>

[Configuration details]

## Makefile Targets

| Target | Tool | Behavior |
|---|---|---|
| `make lint` (via `_lint`) | <linter> | Runs <linter> on all <language> files |
| `make format` (via `_format`) | <formatter> | Checks formatting (CI), fixes formatting (local) |
| `make test` (via `_test`) | <test-runner> | Runs test suite |
| `make security` (via `_security`) | <scanner> | Scans for security issues |

## Pre-Commit Hooks

### Local (fast)

| Hook | Tool | Trigger |
|---|---|---|
| <linter-hook> | <linter> | <file-pattern> |
| <formatter-hook> | <formatter> | <file-pattern> |

### CI-Only (slow)

| Check | Tool | Why CI-only |
|---|---|---|
| <security-scan> | <scanner> | Too slow for local hooks (>30s) |

## Notes

[Language-specific conventions, gotchas, and best practices]
```

### Existing Examples

- `standards/python.md` -- comprehensive with ruff, bandit, semgrep, pytest, mypy
- `standards/bash.md` -- shellcheck, shfmt, bats
- `standards/terraform.md` -- tflint, terraform fmt, tfsec, checkov, terraform-docs
- `standards/ansible.md` -- ansible-lint, molecule
- `standards/universal.md` -- trivy, gitleaks (apply to all repos)

---

## Step 6: Write Verification Tests

**Repo:** `dev-toolchain`
**File:** `tests/test-<language>.sh`
**Example:** See `tests/test-python.sh` for a complete example.

Verification tests confirm that all tools installed by the install script are present and functional inside the container:

```bash
#!/usr/bin/env bash
# tests/test-<language>.sh -- Verify <language> tools are installed and working
#
# Purpose: Validates that all <language> tools are present and produce
#          expected output inside the dev-toolchain container.
# Usage:   bash tests/test-<language>.sh
# Exit:    0 = all tools verified, 1 = one or more tools missing/broken

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVRAIL_LIB="${DEVRAIL_LIB:-${SCRIPT_DIR}/../lib}"
source "${DEVRAIL_LIB}/log.sh"

TESTS_PASSED=0
TESTS_FAILED=0

assert_cmd() {
  local cmd="$1"
  if command -v "$cmd" &>/dev/null; then
    log_info "PASS: $cmd is installed"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_error "FAIL: $cmd is NOT installed"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_version() {
  local cmd="$1"
  local version_flag="${2:---version}"
  if "$cmd" "$version_flag" &>/dev/null; then
    log_info "PASS: $cmd $version_flag succeeds"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_error "FAIL: $cmd $version_flag failed"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# --- Test each tool ---
log_info "Testing <language> tools..."

assert_cmd "<linter>"
assert_version "<linter>"

assert_cmd "<formatter>"
assert_version "<formatter>"

assert_cmd "<scanner>"
assert_version "<scanner>"

assert_cmd "<test-runner>"
assert_version "<test-runner>"

# --- Summary ---
log_info "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
if [[ $TESTS_FAILED -gt 0 ]]; then
  log_error "<language> tool verification FAILED"
  exit 1
fi
log_info "<language> tool verification PASSED"
```

### Existing Examples

- `tests/test-python.sh` -- tests ruff, bandit, semgrep, pytest, mypy
- `tests/test-bash.sh` -- tests shellcheck, shfmt, bats
- `tests/test-terraform.sh` -- tests tflint, terraform, tfsec, checkov, terraform-docs
- `tests/test-ansible.sh` -- tests ansible-lint, molecule
- `tests/test-universal.sh` -- tests trivy, gitleaks

---

## Step 7: Update the `.devrail.yml` Schema

**Repo:** `devrail-standards`
**File:** `standards/devrail-yml-schema.md`

Add the new language to the `Allowed values` list for the `languages` key:

```yaml
# Before
Allowed values: python, bash, terraform, ansible

# After
Allowed values: python, bash, terraform, ansible, <new-language>
```

This ensures that projects declaring the new language in their `.devrail.yml` are recognized as valid.

---

## Step 8: Update the Documentation Site

**Repo:** `devrail.dev`
**File:** `content/docs/standards/<language>.md`

Create a Hugo content page for the new language's standards. Use the same structure as `content/docs/standards/python.md`:

```markdown
---
title: "<Language> Standards"
linkTitle: "<Language>"
weight: <N>
description: "Tools, configuration, and conventions for <language> projects."
---

[Content mirrors standards/<language>.md from devrail-standards]
```

---

## Pull Request Strategy

Adding a new language requires coordinated changes across multiple repos. Submit pull requests in this order:

1. **`dev-toolchain`** -- Install script + Dockerfile update + Makefile targets + verification tests. This PR must be merged and the container rebuilt before other PRs can be tested.

2. **`devrail-standards`** -- Standards document (`standards/<language>.md`) + schema update (`standards/devrail-yml-schema.md`) + this guide updated with the new language as an example.

3. **Template repos** (`github-repo-template`, `gitlab-repo-template`) -- Update `.pre-commit-config.yaml` to include the new language's hooks (commented out by default, with clear instructions for enabling).

4. **`devrail.dev`** -- Add the language standards page to the documentation site.

All commits must follow conventional commit format:

```
feat(<language>): add <tool> to install script
feat(makefile): add <language> lint/format/test/security targets
docs(standards): add <language> standards document
feat(ci): add <language> pre-commit hooks to template
docs(site): add <language> standards page to devrail.dev
```

---

## Container Rebuild Process

After the `dev-toolchain` PR is merged:

1. The weekly build workflow (or manual trigger) builds a new container image
2. The image is tagged with the next semver patch version (e.g., `v1.3.3`) and the floating major tag is updated (`v1`)
3. Template repos that reference `ghcr.io/devrail-dev/dev-toolchain:v1` automatically pick up the new tools
4. Existing projects using the floating tag get the new language support on their next `make check` run

For urgent releases, trigger the build workflow manually from the `dev-toolchain` GitHub Actions page.

---

## Template Update Process

After the templates are updated:

- **New projects** created from the templates get the updated `.pre-commit-config.yaml` with the new language hooks
- **Existing projects** are not affected -- they keep their current configuration. To adopt the new language support, existing projects must manually update their `.pre-commit-config.yaml` and `.devrail.yml`

---

## Self-Verification Checklist

Before submitting your pull requests, verify every item:

- [ ] `scripts/install-<language>.sh` created and follows the install script pattern
- [ ] Script is idempotent (safe to re-run without side effects)
- [ ] Script sources `lib/log.sh` and `lib/platform.sh` -- no raw `echo`
- [ ] Script supports `--help` flag
- [ ] Script uses `require_cmd` for verification after each tool install
- [ ] Script registers a cleanup trap for temp files
- [ ] `Dockerfile` updated to COPY and RUN the install script
- [ ] Container builds successfully with the new script (`docker build .`)
- [ ] `tests/test-<language>.sh` verifies all tools are installed and runnable
- [ ] Tests pass inside the built container
- [ ] `Makefile` has `HAS_<LANGUAGE>` detection variable
- [ ] `_lint` target includes the new language block
- [ ] `_format` target includes the new language block
- [ ] `_test` target includes the new language block
- [ ] `_security` target includes the new language block
- [ ] `standards/<language>.md` created with tools table, configuration, targets, hooks
- [ ] Standards document follows the same structure as `standards/python.md`
- [ ] `.pre-commit-config.yaml` has language-appropriate hooks in template repos
- [ ] Hooks complete in under 30 seconds on typical changesets
- [ ] `standards/devrail-yml-schema.md` updated with the new language in allowed values
- [ ] `devrail.dev` has a page at `content/docs/standards/<language>.md`
- [ ] All commits use conventional commit format (`type(scope): description`)
- [ ] All PRs pass CI (`make check`)
