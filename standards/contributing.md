# Contributing to DevRail

This document covers how to contribute to the DevRail project -- from reporting bugs and suggesting improvements to adding new language ecosystems. For a high-level overview of the ecosystem structure, see the [Contributing section on devrail.dev](https://devrail.dev/docs/contributing/).

---

## How to Contribute

DevRail welcomes contributions across several areas:

| Contribution Type | Where |
|---|---|
| Bug reports and feature requests | Open an issue in the relevant repository |
| Standards improvements | `development-standards` repo |
| Tooling and container changes | `dev-toolchain` repo |
| Template improvements | `github-repo-template` or `gitlab-repo-template` |
| Documentation site | `devrail.dev` repo |
| New language ecosystem | See [Adding a New Language](#adding-a-new-language-ecosystem) below |

---

## Development Setup

### Prerequisites

- Docker (for running the dev-toolchain container)
- Git
- Python 3 (for pre-commit hooks)

### Clone and Verify

```bash
# Clone the repo you want to contribute to
git clone <repo-url>
cd <repo>

# Install pre-commit hooks
make install-hooks

# Run all checks to verify your setup
make check
```

Every DevRail repo uses the same Makefile contract. `make check` runs linting, formatting, tests, security, and scanning inside the dev-toolchain container.

---

## Repository Map

DevRail is split across multiple repositories. Know which repo to change for your contribution:

```
development-standards    Standards documents, .devrail.yml schema, this guide
  └── standards/*.md     Per-language standards, Makefile contract, CI pipelines

dev-toolchain            Container image with all tools pre-installed
  ├── Dockerfile         Container build definition
  ├── Makefile           Reference Makefile with all internal targets
  ├── scripts/           Per-language install scripts
  ├── tests/             Per-language verification tests
  └── lib/               Shared libraries (log.sh, platform.sh)

github-repo-template     GitHub template for new projects
  ├── .github/workflows/ CI workflow files
  ├── Makefile            Reference Makefile (synced with dev-toolchain)
  └── .pre-commit-config.yaml

gitlab-repo-template     GitLab template for new projects
  ├── .gitlab-ci.yml     CI pipeline configuration
  ├── Makefile            Reference Makefile (synced with dev-toolchain)
  └── .pre-commit-config.yaml

devrail.dev              Documentation site (Hugo + Docsy)
  └── content/docs/      Standards pages, getting started, contributing guides
```

---

## Pull Request Process

### Branch Naming

Use descriptive branch names with a type prefix:

```
feat/add-rust-support
fix/shellcheck-false-positive
docs/update-terraform-examples
```

### Conventional Commits

All commits must follow the [Conventional Commits](https://www.conventionalcommits.org/) format:

```
type(scope): description
```

**Types:** `feat`, `fix`, `docs`, `chore`, `ci`, `refactor`, `test`

**Scopes:** `python`, `bash`, `terraform`, `ansible`, `ruby`, `go`, `javascript`, `container`, `ci`, `makefile`, `standards`

**Examples:**

```
feat(ruby): add rubocop pre-commit hook
fix(makefile): correct terraform lint directory detection
docs(standards): update Go security scanner section
ci(container): add arm64 build matrix
```

### Before Submitting

1. Run `make check` and ensure all checks pass
2. Write clear commit messages following conventional commit format
3. Keep PRs focused -- one logical change per PR
4. Update documentation if your change affects user-facing behavior

### Multi-Repo Changes

Some changes span multiple repositories. Submit PRs in dependency order:

1. `dev-toolchain` (container must be rebuilt first)
2. `development-standards` (standards documentation)
3. Template repos (pick up new container features)
4. `devrail.dev` (documentation site)

---

## Code Style

### Shell Scripts

- Shebang: `#!/usr/bin/env bash`
- Error handling: `set -euo pipefail`
- Use `lib/log.sh` for all output -- never raw `echo`
- Use `lib/platform.sh` for platform detection
- Scripts must be idempotent (safe to re-run)
- Support `--help` / `-h` flag
- Register `trap cleanup EXIT` for temp files

### Makefile

- Follow the two-layer delegation pattern (public targets on host, internal targets in container)
- Public targets: `lower-kebab-case` with `## description` for auto-help
- Internal targets: `_prefixed`
- All internal targets emit JSON summary output
- Exit codes: 0 = pass, 1 = failure, 2 = misconfiguration

### Standards Documents

- Follow the consistent page structure: Tools, Configuration, Makefile Targets, Pre-Commit Hooks, Notes
- Include annotated configuration examples
- Reference the Makefile contract for target behavior

---

## Adding a New Language Ecosystem

This section is the authoritative step-by-step guide for adding a new language ecosystem (e.g., Rust, Elixir) to DevRail. It describes the exact pattern established by the existing seven languages (Python, Bash, Terraform, Ansible, Ruby, Go, JavaScript) and references concrete examples at each step.

### Architecture Overview

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

### Step 1: Create the Install Script

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

#### Key Conventions

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

#### Existing Examples

- `scripts/install-python.sh` -- pip-based installation with ruff, bandit, semgrep, pytest, mypy
- `scripts/install-bash.sh` -- binary downloads for shellcheck and shfmt, bats from source
- `scripts/install-terraform.sh` -- Go builder stage binaries + pip packages
- `scripts/install-ansible.sh` -- pip-based installation with ansible-lint, molecule
- `scripts/install-ruby.sh` -- gem-based installation with rubocop, reek, brakeman, rspec, sorbet
- `scripts/install-go.sh` -- verify-only (tools COPY'd from Go builder stage)
- `scripts/install-javascript.sh` -- npm-based installation with eslint, prettier, typescript, vitest
- `scripts/install-universal.sh` -- Go builder stage for trivy and gitleaks

---

### Step 2: Update the Dockerfile

**Repo:** `dev-toolchain`
**File:** `Dockerfile`

Add the new install script invocation to the Dockerfile. Follow the existing pattern:

```dockerfile
# -- <Language> tools --
COPY scripts/install-<language>.sh /tmp/scripts/
RUN bash /tmp/scripts/install-<language>.sh
```

If the language requires a runtime SDK (like Go or Node.js), add a builder stage and COPY the runtime to the final image. See the Go and Node.js stages in the Dockerfile for examples.

---

### Step 3: Add Makefile Targets

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

Also add a scaffolding block to the `_init` target so `make init` creates the standard config files for the new language.

**Important:** The template repo Makefiles must be kept in sync with the dev-toolchain Makefile. After updating dev-toolchain, copy the internal targets to both template repos.

---

### Step 4: Configure Pre-Commit Hooks

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

#### Existing Examples

- **Python:** `ruff-pre-commit` (ruff check + ruff format)
- **Bash:** `shellcheck-py` + `pre-commit-shfmt`
- **Terraform:** `pre-commit-terraform` (terraform_fmt, terraform_tflint)
- **Ansible:** `ansible-lint`
- **Ruby:** `rubocop`
- **Go:** `golangci-lint-full`
- **JavaScript:** `mirrors-eslint` + `mirrors-prettier`

---

### Step 5: Write the Standards Document

**Repo:** `development-standards`
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
## Makefile Targets
## Pre-Commit Hooks
## Notes
```

---

### Step 6: Write Verification Tests

**Repo:** `dev-toolchain`
**File:** `tests/test-<language>.sh`

Verification tests confirm that all tools installed by the install script are present and functional inside the container. Use `assert_cmd` and `assert_version` helpers. See `tests/test-python.sh` for a complete example.

---

### Step 7: Update the `.devrail.yml` Schema

**Repo:** `development-standards`
**File:** `standards/devrail-yml-schema.md`

Add the new language to the `Allowed values` list for the `languages` key.

---

### Step 8: Update the Documentation Site

**Repo:** `devrail.dev`
**File:** `content/docs/standards/<language>.md`

Create a Hugo content page for the new language's standards. Update the language support matrix in `content/docs/standards/_index.md`.

---

### Language PR Strategy

Adding a new language requires coordinated changes across multiple repos. Submit pull requests in this order:

1. **`dev-toolchain`** -- Install script + Dockerfile update + Makefile targets + verification tests. This PR must be merged and the container rebuilt before other PRs can be tested.

2. **`development-standards`** -- Standards document + schema update + this guide updated with the new language as an example.

3. **Template repos** -- Update `.pre-commit-config.yaml` to include the new language's hooks (commented out by default).

4. **`devrail.dev`** -- Add the language standards page to the documentation site.

---

### Container Rebuild Process

After the `dev-toolchain` PR is merged:

1. The weekly build workflow (or manual trigger) builds a new container image
2. The image is tagged with the next semver patch version and the floating major tag is updated (`v1`)
3. Template repos that reference `ghcr.io/devrail-dev/dev-toolchain:v1` automatically pick up the new tools
4. Existing projects using the floating tag get the new language support on their next `make check` run

---

### Self-Verification Checklist

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
- [ ] `_init` target scaffolds config files for the new language
- [ ] `standards/<language>.md` created with tools table, configuration, targets, hooks
- [ ] `.pre-commit-config.yaml` has language-appropriate hooks in template repos
- [ ] `standards/devrail-yml-schema.md` updated with the new language in allowed values
- [ ] `devrail.dev` has a page at `content/docs/standards/<language>.md`
- [ ] All commits use conventional commit format (`type(scope): description`)
- [ ] All PRs pass CI (`make check`)
