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

## Contributing a Plugin

DevRail plugins extend the dev-toolchain image with new languages or tool integrations without forking the core repos. The plugin loader (shipped in v1.10.x) reads `plugins:` from a consumer's `.devrail.yml`, resolves each entry to an immutable git ref, builds a project-local extended image (`devrail-local:<hash>`), and dispatches plugin-defined targets inside the existing `_lint` / `_format` / `_fix` / `_test` / `_security` recipes.

If you have a tool you want every DevRail-managed project to use, you can ship it as a plugin instead of opening a PR against the core dev-toolchain. This section walks through the contributor surface.

> **See also:** [Plugin architecture design doc](https://github.com/devrail-dev/dev-toolchain/blob/main/docs/plugin-architecture.md) for the full rationale and lifecycle. [`devrail-yml-schema.md` § `plugins:`](devrail-yml-schema.md#plugins) for the consumer-side declaration shape.

### Plugin layout

A plugin is a git repository containing a `plugin.devrail.yml` manifest at the repo root. By convention the repo is named `devrail-plugin-<name>` (the trailing `name` is not enforced — the manifest's `name` field is authoritative — but encouraged for discoverability):

```
devrail-plugin-elixir/
├── plugin.devrail.yml      # the manifest (required)
├── install.sh              # tool install script (referenced by container.install_script)
├── README.md               # description, supported versions, how to declare
└── LICENSE
```

### Manifest (`plugin.devrail.yml`)

```yaml
schema_version: 1
name: elixir
version: 1.0.0
description: Elixir / Erlang language ecosystem for DevRail
devrail_min_version: 1.10.0

container:
  base_image: elixir:1.17-slim       # used when this plugin is built as the runtime
  install_script: install.sh          # path inside the plugin repo
  apt_packages:                       # appended to runtime apt layer
    - inotify-tools
  copy_from_builder:                  # paths to COPY from the builder stage
    - /usr/local/bin/elixir
    - /usr/local/bin/mix
    - /usr/local/lib/elixir
  env:
    MIX_ENV: prod

targets:
  lint:
    cmd: "mix credo --strict {paths}"
    paths_var: ELIXIR_PATHS
    paths_default: "lib test"
  format_check:
    cmd: "mix format --check-formatted"
  format_fix:
    cmd: "mix format"
  test:
    cmd: "mix test"
  security:
    cmd: "mix deps.audit"

gates:
  lint: ["mix.exs"]
  format_check: ["mix.exs"]
  format_fix: ["mix.exs"]
  test: ["mix.exs", "test/"]
  security: ["mix.lock"]
```

Field-by-field:

- **`schema_version`** (int, required) — pinned at `1` for the v1.10.x line. The loader rejects manifests with an unknown major schema. A future schema bump will be major (`2`) and the loader will keep `schema_version: 1` valid for at least one major after that.
- **`name`** (string, required) — must match `^[a-z][a-z0-9_-]*$`. Becomes the language identifier consumers use in `.devrail.yml` `languages:` and as the override key (e.g., `elixir: { linter: dialyxir }`).
- **`version`** (semver string, required) — your plugin's own version. Consumers pin via `rev:`; this field is informational.
- **`devrail_min_version`** (semver string, required) — the oldest dev-toolchain version this plugin supports. The loader compares against the running container's version label and refuses load on mismatch. Use `1.10.0` for plugins that target the first stable plugin-loader release.
- **`container`** (mapping, required for v1) — see "Container integration" below.
- **`targets`** (mapping, required) — at least one of `lint`, `format_check`, `format_fix`, `fix`, `test`, `security`. Each target's `cmd` runs inside the project-local extended image. `{paths}` interpolates `${<paths_var>}` (filtered to existing paths); without `paths_var`, `{paths}` is a config error.
- **`gates`** (mapping, optional) — per-target list of paths that must all exist for the target to run. Workspace-relative only; absolute paths rejected. Empty list or missing key = always run.

### Container integration

Plugins extend the dev-toolchain image via Docker BuildKit. At `make check` time, the consumer's host runs the orchestrator, generates a `Dockerfile.devrail` from the plugin loader cache, and builds `devrail-local:<hash>`:

```dockerfile
FROM ghcr.io/devrail-dev/dev-toolchain:v1.10.6 AS runtime

# --- plugin: elixir@v1.0.0 ---
RUN apt-get update && apt-get install -y --no-install-recommends \
      inotify-tools \
    && rm -rf /var/lib/apt/lists/*
COPY --from=elixir:1.17-slim /usr/local/bin/elixir /usr/local/bin/elixir
COPY --from=elixir:1.17-slim /usr/local/bin/mix /usr/local/bin/mix
COPY --from=elixir:1.17-slim /usr/local/lib/elixir /usr/local/lib/elixir
ENV MIX_ENV=prod
COPY .devrail-plugins-build/devrail-plugin-elixir/v1.0.0/install.sh /opt/devrail/plugins/devrail-plugin-elixir/install.sh
RUN chmod +x /opt/devrail/plugins/devrail-plugin-elixir/install.sh && bash /opt/devrail/plugins/devrail-plugin-elixir/install.sh
```

Cache hits are free — unchanged plugin sets re-use the existing image. First-build cost is plugin-dependent (typically 30 s – 2 min).

### Versioning and immutability

- Tag releases with semver tags (`v1.0.0`, `v1.1.0`). Consumers pin via `rev:` (tag or full SHA, never a branch).
- The dev-toolchain resolver records the resolved SHA + content hash in the consumer's `.devrail.lock` on `make plugins-update`. Subsequent `make check` invocations refuse to run if the lockfile and `.devrail.yml` disagree.
- Re-tagging an existing tag onto different code is detected via content_hash mismatch and surfaces as an error. Don't move tags; cut new ones.

### Local development

Test your plugin against a local consumer workspace before publishing:

```bash
# In the consumer's .devrail.yml
languages:
  - elixir

plugins:
  - source: file:///home/you/devrail-plugin-elixir
    rev: v1.0.0
    languages: [elixir]
```

```bash
# Then in the consumer repo:
make plugins-update     # resolver fetches the file:// fixture
make check              # build pipeline + execution loop run the plugin
```

For automated plugin tests, mirror the harness pattern in `dev-toolchain/tests/test-plugin-execution.sh`: hermetic per-case workspace, hand-crafted loader cache, assertions via `jq` on the structured event log.

### Override surface

Consumers can override your manifest defaults from `.devrail.yml`:

```yaml
elixir:
  linter: dialyxir          # replaces targets.lint.cmd
  test: "mix test --cover"  # replaces targets.test.cmd
```

Override keys: `lint→linter`, `format_check`/`format_fix→formatter`, `fix→fixer`, `test→test`, `security→security`. Overrides take the entire command verbatim; `{paths}` is not interpolated for overrides.

### Distribution

For the v1.10 release, plugins are distributed via public git URLs (no central registry yet). Add yours to the community `awesome-devrail` list (TBD) once the discovery layer is in place.

### What's NOT in scope for v1.10

These features are deferred to later phases:

- **Plugin signing / signature verification** — Story 13.10. For now, the lockfile content_hash detects tampering with a tag, but not authenticity.
- **Sidecar containers** — see the design doc § "Container integration"; rejected for v1.
- **Volume-mounted plugins** — same.
- **Runtime install (no rebuild)** — same.
- **Parallel plugin execution** — sequential per design; needs shared-state semantics first.

### Extracting a core language as a plugin

The reference example for "I want to take an existing core DevRail language and ship it as an external plugin" is **`devrail-plugin-kotlin`** ([github.com/devrail-dev/devrail-plugin-kotlin](https://github.com/devrail-dev/devrail-plugin-kotlin)), built during Story 13.7. The recipe below is what we did for Kotlin and what other contributors should do for the next language.

> **Important:** During v1.10.x and v1.11.x the extraction is **additive** — the language stays in dev-toolchain core AND a plugin exists. v2.0.0 (Story 13.9) removes the core path; until then, consumers can use either. The loader's "core wins over plugin" precedence rule means that if a consumer lists the language in `languages:`, they hit the in-core path; to exercise the plugin they must put the language ONLY in the plugin's `languages:` block. Document this for your plugin's users.

#### Step 1: Identify the surface to extract

For a target language `LANG`, find every place dev-toolchain touches it. The Kotlin example:

| Surface | Files | What it does |
|---|---|---|
| Builder stage | `Dockerfile` (lines around `FROM eclipse-temurin:21-jdk AS jdk-builder`) | Source for the JDK that gets COPY'd into runtime |
| Runtime COPY | `Dockerfile` (lines around `COPY --from=jdk-builder /opt/java/openjdk`) | What lands in the runtime image |
| Runtime PATH | `Dockerfile` `ENV PATH=...` | How tools are discoverable |
| Install script | `scripts/install-LANG.sh` | Install logic for tools beyond the language runtime (linters, formatters, build tools) |
| Tests | `tests/test-LANG.sh` | Runtime verification |
| Makefile var | `HAS_LANG := $(filter LANG,$(LANGUAGES))` | Detection variable |
| Makefile blocks | `if [ -n "$(HAS_LANG)" ]; then ... fi;` in `_lint`, `_format`, `_fix`, `_test`, `_security` | Per-target behaviour |
| Pre-commit | `.pre-commit-config.yaml` (template repos) | Local hook config (NOT extracted in v1 — pre-commit support is separate from plugin loader) |

`grep -nE "HAS_<LANG>|<lang>" Makefile Dockerfile scripts/install-<lang>.sh tests/test-<lang>.sh` is the fastest way to inventory.

#### Step 2: Map Makefile blocks → plugin manifest targets

Each `if [ -n "$(HAS_LANG)" ]; then ... fi` block in dev-toolchain becomes one plugin manifest target. Translation rules:

- The shell command inside the block (e.g., `ktlint`, `gradle test --no-daemon`) becomes `targets.<name>.cmd`.
- A path glob the core block tests (`find . -name '*.kt'`) becomes `gates.<name>: ["<path>"]` — but use the project-marker file (`build.gradle.kts`, `Cargo.toml`) when possible because the loader's gate mechanism only checks file existence, not file contents.
- Multi-tool blocks (Kotlin runs ktlint AND detekt under `_lint`) collapse to ONE cmd via `&&`. The v1 contract is one cmd per target. Document this in your plugin README.
- Languages with `*_PATHS` runtime-filtering (Ruby's `RUBY_PATHS`) translate to `paths_var` + `paths_default` on the manifest target. The dispatcher's `{paths}` interpolation handles the existing-path filter.

The Kotlin extraction's mapping (in `devrail-plugin-kotlin/plugin.devrail.yml`):

```yaml
targets:
  lint:
    cmd: "ktlint && (test -f detekt.yml && detekt-cli --build-upon-default-config --config detekt.yml || detekt-cli --build-upon-default-config)"
  format_check: { cmd: "ktlint --format --dry-run" }
  format_fix:   { cmd: "ktlint --format" }
  test:         { cmd: "gradle test --no-daemon" }
  security:     { cmd: "gradle dependencyCheckAnalyze --no-daemon" }
gates:
  lint: ["build.gradle.kts"]
  # ... same gate for every target
```

#### Step 3: Port the install script

Plugin install scripts run during `docker build` of the consumer's `Dockerfile.devrail`. At that point the dev-toolchain libs (`/opt/devrail/lib/log.sh`, `platform.sh`) are NOT yet copied into the layer being built. So:

- **Strip every `source "${DEVRAIL_LIB}/log.sh"` and `source "${DEVRAIL_LIB}/platform.sh"`.** Replace `log_info "..."` calls with `printf '[install-<lang>] %s\n' "$msg" >&2`. Self-contained scripts are the contract for plugin authors.
- **Keep `set -euo pipefail`.** Idempotency checks (`command -v ktlint &>/dev/null && return`) keep `make plugins-update + make check` cycles fast on re-run.
- **No `require_cmd` calls** — that helper lives in the dev-toolchain libs you're not allowed to source. Inline a simple `command -v <bin>` check at the bottom for verification, or rely on `set -e` + the explicit version checks (`ktlint --version`).
- **Keep cleanup traps** for any `mktemp -d` you create.

The Kotlin port at `devrail-plugin-kotlin/install.sh` is a complete worked example — compare it side-by-side with `dev-toolchain/scripts/install-kotlin.sh` to see the deltas.

#### Step 4: Write the container fragment

The plugin manifest's `container:` block must reproduce dev-toolchain's runtime layer for the language. For Kotlin:

```yaml
container:
  base_image: eclipse-temurin:21-jdk     # the same builder stage dev-toolchain uses
  copy_from_builder:
    - /opt/java/openjdk                  # exactly what dev-toolchain COPYs from jdk-builder
  env:
    JAVA_HOME: /opt/java/openjdk
    PATH: "/opt/java/openjdk/bin:${PATH}"
  install_script: install.sh
```

The build pipeline (Story 13.4) renders this into the consumer's project-local `Dockerfile.devrail` automatically.

#### Step 5: Initialize the plugin repo with DevRail standards

A plugin repo is itself a DevRail-managed project. Adopt the standards so the plugin's own bash / YAML / docs lint cleanly:

```sh
gh repo create devrail-dev/devrail-plugin-<lang> --public --license MIT
git clone git@github.com:devrail-dev/devrail-plugin-<lang>.git
cd devrail-plugin-<lang>

# Copy the reference Makefile + scaffolding
cp /path/to/dev-toolchain/Makefile .
cp /path/to/dev-toolchain/.gitignore .
cp /path/to/dev-toolchain/.editorconfig .
cp /path/to/dev-toolchain/.pre-commit-config.yaml .

# Add a .devrail.yml that lints just bash (the install script)
cat >.devrail.yml <<YAML
languages:
  - bash
fail_fast: false
log_format: json
YAML

make check    # confirms shellcheck/shfmt/trivy/gitleaks all clean
```

Then add `.github/workflows/ci.yml` that runs `make check` plus the manifest validator on every push (see the `devrail-plugin-kotlin` example — two jobs: `check` and `validate-manifest`).

#### Step 6: Validate end-to-end

Before tagging v1.0.0, exercise the plugin against a real consumer workspace via a `file://` URL:

```sh
# In a fresh test consumer
cat >.devrail.yml <<YAML
plugins:
  - source: file:///home/you/devrail-plugin-<lang>
    rev: v1.0.0       # the tag you're about to cut
    languages: [<lang>]
YAML

# (Optional but recommended) tag locally first
cd /home/you/devrail-plugin-<lang>
git tag -a v1.0.0 -m "v1.0.0 — initial release"
cd -

make plugins-update    # resolver fetches via file:// and writes .devrail.lock
make check             # builds devrail-local:<hash>, runs the plugin's targets
```

If the build succeeds and `make check` reports the plugin in `ran_languages`, the extraction is structurally complete.

For automated regression coverage, add a manifest-shape smoke test to `dev-toolchain/tests/` mirroring `tests/test-kotlin-plugin-extraction.sh` — it validates the plugin's manifest, fetches it via the resolver, and asserts the loader cache matches the in-core behaviour. Vendor the plugin's manifest into `dev-toolchain/tests/fixtures/<lang>-via-plugin/` to keep the test hermetic.

#### Step 7: Tag and announce

```sh
cd /path/to/devrail-plugin-<lang>
git tag -a v1.0.0 -m "v1.0.0 — initial release"
git push origin v1.0.0
```

Then update `dev-toolchain/CHANGELOG.md` with a note about the new reference plugin (no code change in dev-toolchain proper — the language stays in core for back-compat through v1.x). Cut a minor release on dev-toolchain to advertise the plugin's availability.

#### Anti-patterns

- **Don't remove the language from dev-toolchain core.** That's v2.0.0 / Story 13.9. Until then, the extraction is additive.
- **Don't depend on `lib/log.sh` from the plugin's `install.sh`.** Self-contained scripts only.
- **Don't introduce a new manifest field to handle "two tools per target".** Document the `&&` chaining workaround instead.
- **Don't skip the manifest-shape smoke test in dev-toolchain.** It's how we catch drift between the plugin and the in-core behaviour.

### Plugin checklist

Before publishing a `v1.0.0` release of your plugin:

- [ ] `plugin.devrail.yml` has all required fields (`schema_version`, `name`, `version`, `devrail_min_version`, `targets`)
- [ ] `name` matches `^[a-z][a-z0-9_-]*$`
- [ ] `devrail_min_version` is set to the earliest dev-toolchain version you've tested against (typically `1.10.0`)
- [ ] At least one `targets.<name>.cmd` is defined
- [ ] Each `cmd` that uses `{paths}` declares `paths_var` and `paths_default`
- [ ] `gates:` are workspace-relative (no absolute paths)
- [ ] `container.install_script` (if used) is idempotent, uses `set -euo pipefail`, and does NOT depend on `lib/log.sh` from dev-toolchain
- [ ] Plugin tested locally against a consumer workspace via `file://` URL
- [ ] First tag is an annotated semver tag (`git tag -a v1.0.0`); not a branch ref
- [ ] README documents which `.devrail.yml` `languages:` entries the plugin provides
- [ ] Plugin repo itself passes `make check` (DevRail-standard scaffolding adopted)
