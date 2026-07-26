# .devrail.yml Schema Specification

This document defines the complete schema for `.devrail.yml`, the project configuration file used by all DevRail-managed repositories. This file is the single source of truth that the Makefile, CI pipelines, and AI agents read to understand a project's language stack and settings.

## File Location

`.devrail.yml` MUST be placed at the repository root directory.

## Format

- YAML format (consistent with CI/CD ecosystem)
- `snake_case` for ALL keys (no camelCase, no kebab-case)
- Comments encouraged for non-obvious settings

## Top-Level Keys

### `languages`

**Type:** list of strings (required)

**Description:** Declares which languages are used in the project. This list drives which linters, formatters, security scanners, and test runners are executed by Makefile targets and CI jobs.

**Allowed values:** `python`, `bash`, `terraform`, `ansible`, `ruby`, `go`, `javascript`, `rust`, `swift`, `kotlin`

**Validation rules:**

- Must be a non-empty list
- Each entry must be one of the supported language identifiers
- Duplicate entries are ignored
- Order does not affect execution

**Example:**

```yaml
languages:
  - python
  - bash
```

### `fail_fast`

**Type:** boolean (optional)

**Default:** `false`

**Description:** Controls error handling behavior for Makefile targets and CI jobs. When `false` (default), all checks run to completion and report all issues (run-all-report-all). When `true`, execution stops at the first failure.

Can also be overridden at runtime via the `DEVRAIL_FAIL_FAST=1` environment variable.

**Validation rules:**

- Must be a boolean (`true` or `false`)
- If omitted, defaults to `false`

**Example:**

```yaml
fail_fast: false
```

### `log_format`

**Type:** string (optional)

**Default:** `json`

**Description:** Controls the output format for Makefile targets and scripts.

**Allowed values:**

- `json` -- structured JSON output (default, preferred for CI and agents)
- `human` -- human-readable table format

Can also be overridden at runtime via the `DEVRAIL_LOG_FORMAT=human` environment variable.

**Validation rules:**

- Must be one of: `json`, `human`
- If omitted, defaults to `json`

**Example:**

```yaml
log_format: json
```

### `env`

**Type:** mapping of string to string (optional)

**Default:** `{}` (empty)

**Description:** Extra environment variables passed into the toolchain container. Each `KEY: value` pair is injected as `-e KEY=value` on the `docker run` invocation (the Makefile's `DEVRAIL_ENV_FLAGS`). Useful for tools and test suites that read configuration from the environment (e.g. a Rails test database host).

**Validation rules:**

- Must be a mapping; keys and values are treated as strings
- Empty or omitted is a no-op

**Example:**

```yaml
env:
  RAILS_ENV: test
  DATABASE_HOST: myapp-pg
```

### `docker_network`

**Type:** string (optional)

**Default:** `""` (none)

**Description:** Attaches the toolchain container to an existing user-defined Docker network (`--network <name>`) so it can reach sibling service containers by hostname — the common pattern for running `make test` against a database in a separate container (e.g. a Postgres reachable at `myapp-pg`). A single network name; `docker run` honors only one `--network` at launch.

**Validation rules:**

- Must be a string naming a Docker network that already exists on the host
- Empty or omitted is a no-op (no `--network` flag is added)

**Example:**

```yaml
docker_network: myapp-test
```

### `docker_volumes`

**Type:** list of strings (optional)

**Default:** `[]` (empty)

**Description:** Additional volume mounts for the toolchain container. Each entry is passed verbatim as `-v <spec>` to `docker run`, accepting the full Docker volume syntax — `host:container`, `host:container:ro`, or `named-volume:container`. Useful for mounting fixture data or sharing a cache across runs. The repository root is always mounted at `/workspace` regardless of this key.

**Validation rules:**

- Must be a list of strings, each a valid `docker -v` spec
- Empty or omitted is a no-op

**Example:**

```yaml
docker_volumes:
  - ./fixtures:/workspace/fixtures
  - shared-cache:/cache
```

### `projects`

**Type:** list of mappings (optional)

**Default:** `[]` (empty — autodetection applies)

**Description:** Overrides autodetection of per-language project roots in a monorepo. Without this key, `make lint`/`format`/`fix`/`test`/`security` autodetect each declared language's project directory from its manifest file (`pyproject.toml`/`setup.py`/`setup.cfg` for Python, `package.json` for JavaScript/TypeScript, `go.mod` for Go, `Cargo.toml` for Rust) and run that language's tools with cwd set there, so local config (`tsconfig.json`, `vite.config.ts` path aliases, `pyproject.toml`) resolves correctly — and, for Go/Rust, so `go test`/`golangci-lint`/`cargo test`/`cargo clippy`/`cargo fmt` don't fail outright with "directory prefix . does not contain main module" / "could not find Cargo.toml" errors when the module isn't rooted at the repo root. A manifest at the repository root is treated as the common single-project case (root resolves to `.`, matching pre-monorepo-support behavior exactly); when no manifest exists anywhere, tools fall back to running from the repository root, same as before this feature existed. Set `projects:` only for layouts autodetection can't infer.

**Known autodetection limitation:** autodetection treats a manifest at the repository root as authoritative and does not also descend into subdirectories — if your repo has a root-level `pyproject.toml` used only for shared tool config (a common pattern) alongside real per-language subdirectories, autodetection collapses to root-only and won't discover the subdirectories. Use an explicit `projects:` entry per subdirectory to get correct per-project execution in that layout.

**Go workspaces (`go.work`):** autodetection looks for `go.mod` files and is unaware of `go.work` — Go's own native multi-module workspace mechanism. In practice this doesn't conflict: a `go.work`-based repo typically has no `go.mod` at the repository root (each workspace member has its own), so autodetection finds and runs each member module independently from its own directory, which is correct on its own terms. What it does **not** do is preserve any `go.work`-level behavior that spans modules (e.g. a `replace` directive resolved only in workspace mode) — each module is tested/linted in isolation, as if `go.work` didn't exist. If your workspace relies on cross-module resolution, either declare each member as an explicit `projects:` entry pointing at a wrapper command that runs `go build`/`go test` from the workspace root, or track this as a gap to revisit (not yet a dedicated story).

**Entry shape:** Each entry is a mapping with these keys:

- **`path`** (string, required) — the project's root directory, relative to the repository root.
- **`languages`** (list of strings, required) — which `languages:` entries this project supplies tools for.

**Validation rules:**

- `path` should name a directory that exists in the repository — a non-existent path logs a warning at runtime but is not rejected outright (unlike `plugins:`, `projects:` has no dedicated schema validator yet)
- `languages` should be a non-empty list of strings drawn from the declared `languages:` list — this is not currently enforced; an unrecognized or mismatched entry is silently ignored rather than erroring
- Honored for `python`, `javascript`, `go`, and `rust`. Ansible needs no equivalent — `ansible-lint` already recursively discovers playbooks from cwd regardless of where they live in the repo, with no root-marker file the way `go.mod`/`Cargo.toml` are for their toolchains.

**Example:**

```yaml
languages:
  - python
  - javascript

projects:
  - path: api
    languages: [python]
  - path: frontend
    languages: [javascript]
```

### `test`

**Type:** mapping (optional)

**Default:** `{}` (empty — autodetection applies)

**Description:** Controls dependency installation and setup for `make test`. Without this key, `make test` autodetects and installs each Python/JavaScript project's dependencies (from the roots discovered per the `projects` key above) before running `pytest`/`vitest`, so tests don't fail at import time with `ModuleNotFoundError`/unresolved-import errors.

**Autodetection (Python):** first match wins — `uv.lock` present → `uv export --frozen --no-hashes --format requirements-txt | uv pip install --system --break-system-packages -r -`; else `requirements*.txt` present → `pip install --break-system-packages -r <file>` (plain `requirements.txt` wins if present, regardless of other `requirements-*.txt` variants; otherwise the alphabetically-first match); else `pyproject.toml`/`setup.py` present → `pip install --break-system-packages -e .`; else no install runs.

**Autodetection (JavaScript/TypeScript):** `package-lock.json` present → `npm ci`; else no install runs.

**Currently supported package managers:** `uv` and `pip` (Python), `npm` (JS/TS) only. `poetry`, `pipenv`, `pnpm`, and `yarn` are not installed in the container and their lockfiles are not autodetected — this is tracked as follow-on work (Story 15.3+), not a bug. Installs land in the container's system Python/Node environment, not an isolated per-project virtualenv — this container's tools (`pytest`, `ruff`, etc.) are themselves installed system-wide, so a project's own dependencies have to land in the same place to be visible to them.

**Operational notes:**

- **`make test` now requires network egress** (to PyPI and/or the npm registry) for any Python/JS project with a manifest — this is new as of this feature; previously `make test` had no network dependency. CI runners typically have this by default; air-gapped or network-restricted environments will need `test.install` pointed at a local/vendored install path, or a private package index configured via the usual `pip`/`npm` environment variables.
- **The `pip install -e .` fallback** (no lockfile, no `requirements*.txt` — just a `pyproject.toml`/`setup.py`) leaves a `<package-name>.egg-info/` directory inside the project's own source tree as a normal editable-install side effect. It's harmless but will show up as an untracked directory in `git status` if you don't already `.gitignore` it.

**Keys:**

- **`install`** (string, optional) — a shell command that replaces autodetection entirely for every discovered project root of every declared language. Use this when autodetection can't infer your setup (e.g. a `poetry.lock`-based project, or an install step with extra flags).
- **`setup`** (string, optional) — a shell command that runs after a successful install and before the test suite, for every discovered project root of every declared language (e.g. database migrations). No-op if absent.
- **`services`** — **not implemented.** Ephemeral service containers (e.g. `services: [postgres:16, redis:7]`) for integration tests are a separate, larger piece of work tracked as a follow-up story. Do not add this key expecting it to do anything yet.

**Validation rules:**

- `install` and `setup` should be valid shell command strings — neither is currently schema-validated; a malformed command simply fails at `make test` runtime with a normal shell error, the same as any other misconfigured `.devrail.yml` string value
- A failed install or setup step fails `make test` immediately for that project root — the test suite does not run against a broken/partial install

**Example:**

```yaml
languages:
  - python

test:
  install: "poetry install"
  setup: "python manage.py migrate"
```

### `plugins`

**Type:** list of mappings (optional)

**Default:** `[]` (empty)

**Description:** Declares plugin sources that extend the dev-toolchain image with additional languages or tool integrations. The plugin loader (v1.10.0+) reads each entry, resolves `rev:` to an immutable SHA via `git ls-remote`, builds a project-local extended image (`devrail-local:<hash>`), and dispatches plugin-defined targets inside the existing `_lint` / `_format` / `_fix` / `_test` / `_security` recipes.

**Entry shape:** Each plugin entry is a mapping with these keys:

- **`source`** (string, required) — the plugin's git URL. `https://`, `git@`, `git://`, and `file://` schemes are supported. The trailing path component (after stripping `.git`) becomes the cache slug — collisions between two distinct sources with the same basename are rejected at resolve time.
- **`rev`** (string, required) — an immutable git ref. Tags or full SHAs are accepted; branch refs are rejected. The resolver records the resolved SHA + content hash to `.devrail.lock`.
- **`languages`** (list of strings, required) — which `languages:` entries this plugin supplies. The loader fails fast on conflicts (two plugins claiming the same language).

**Validation rules:**

- `source` must be a string, non-empty, and a valid git URL
- `rev` must be a tag or full SHA — never a branch (the resolver rejects branch refs with a clear error)
- `languages` must be a non-empty list of strings, each matching `^[a-z][a-z0-9_-]*$`
- Two plugins cannot claim the same `languages:` entry
- `make check` refuses to run if `.devrail.yml` and `.devrail.lock` disagree (mirrors `bundler` / `cargo` / `npm ci` behaviour)

**Lockfile relationship:** Once `plugins:` is non-empty, `.devrail.lock` becomes a required sibling of `.devrail.yml` and is checked into VCS. Run `make plugins-update` to (re-)resolve refs and rewrite the lockfile. The lockfile records, per plugin: resolved SHA, manifest schema version, and content_hash. Re-tagging an existing tag onto different code is detected via content_hash mismatch.

**Example:**

```yaml
languages:
  - python
  - bash
  - elixir          # provided by a plugin

plugins:
  - source: github.com/community/devrail-plugin-elixir
    rev: v1.0.0
    languages: [elixir]
```

For per-language overrides of plugin-supplied languages, see the **Plugin-language overrides** subsection under "Per-Language Overrides" below — the override surface is symmetric with core languages.

For full plugin authoring guidance, see [`contributing.md` § Contributing a plugin](contributing.md#contributing-a-plugin).

## Per-Language Overrides

Per-language overrides are optional top-level keys matching the language name. They allow customization of tools for a specific language in the project. If omitted, default tools for the language are used.

**Structure:** Each override key matches a language listed in `languages`. The value is a mapping of concern names to tool names (string) or tool lists (list of strings).

**Override keys:**

- `linter` -- linting tool
- `formatter` -- formatting tool
- `security` -- security scanning tools
- `test` -- test runner
- `type_check` -- type checking tool
- `docs` -- documentation generation tool

**Validation rules:**

- Override keys must match an entry in the `languages` list
- Override keys for unlisted languages are ignored
- Individual tool overrides are optional; omitted keys use defaults
- Tool values can be a string (single tool) or list of strings (multiple tools)

**Example:**

```yaml
languages:
  - python

python:
  linter: ruff
  formatter: ruff
  security:
    - bandit
    - semgrep
  test: pytest
  type_check: mypy
```

### Plugin-language overrides (v1.10.0+)

Languages contributed by plugins (declared in `plugins:`) accept the same
override keys. The override **replaces the plugin manifest's
`targets.<name>.cmd`** for that target. The override applies only to the
matching target — other targets fall back to the manifest's defaults.

**Override key map (manifest target → `.devrail.yml` key):**

| Plugin manifest target | Override key |
|---|---|
| `lint` | `linter` |
| `format_check` | `formatter` |
| `format_fix` | `formatter` |
| `fix` | `fixer` |
| `test` | `test` |
| `security` | `security` |

When you supply an override, the entire command string is taken verbatim —
`{paths}` interpolation is not applied to overrides. Include any path
arguments inline if you want them.

**Example:**

```yaml
languages:
  - python
  - elixir          # provided by a plugin

plugins:
  - source: github.com/community/devrail-plugin-elixir
    rev: v1.0.0
    languages: [elixir]

elixir:
  linter: dialyxir          # replaces the plugin's default `mix credo --strict`
  test: "mix test --cover"  # replaces the plugin's default `mix test`
```

## Complete Examples

### Single-Language Project (Bash)

A simple shell-script project with all defaults:

```yaml
# .devrail.yml — shell scripts only
languages:
  - bash

fail_fast: false
log_format: json
```

### Single-Language Project (Python)

A Python project with explicit tool overrides:

```yaml
# .devrail.yml — Python project
languages:
  - python

fail_fast: false
log_format: json

python:
  linter: ruff
  formatter: ruff
  security:
    - bandit
    - semgrep
  test: pytest
  type_check: mypy
```

### Multi-Language Project

A project using Python for application code and Terraform for infrastructure:

```yaml
# .devrail.yml — multi-language project
languages:
  - python
  - terraform

fail_fast: false
log_format: human

python:
  linter: ruff
  formatter: ruff
  security:
    - bandit
    - semgrep
  test: pytest
  type_check: mypy

terraform:
  linter: tflint
  formatter: terraform-fmt
  security:
    - tfsec
    - checkov
  test: terratest
  docs: terraform-docs
```

### Single-Language Project (Ruby on Rails)

A Rails project using Ruby defaults, whose `rspec` suite talks to a Postgres
running in a sibling container on a user-defined network:

```yaml
# .devrail.yml — Ruby on Rails project
languages:
  - ruby

fail_fast: false
log_format: json

# Reach the test database container by hostname and tell Rails where it is.
docker_network: myapp-test
env:
  RAILS_ENV: test
  DATABASE_HOST: myapp-pg

ruby:
  linter:
    - rubocop
    - reek
  formatter: rubocop
  security:
    - brakeman
    - bundler-audit
  test: rspec
  type_check: sorbet
```

### Single-Language Project (Go)

A Go project using defaults:

```yaml
# .devrail.yml — Go project
languages:
  - go

fail_fast: false
log_format: json

go:
  linter: golangci-lint
  formatter: gofumpt
  security: govulncheck
  test: go-test
```

### Single-Language Project (JavaScript/TypeScript)

A TypeScript project using defaults:

```yaml
# .devrail.yml — TypeScript project
languages:
  - javascript

fail_fast: false
log_format: json

javascript:
  linter: eslint
  formatter: prettier
  security: npm-audit
  test: vitest
  type_check: tsc
```

### Single-Language Project (Rust)

A Rust project using defaults:

```yaml
# .devrail.yml — Rust project
languages:
  - rust

fail_fast: false
log_format: json

rust:
  linter: clippy
  formatter: rustfmt
  security:
    - cargo-audit
    - cargo-deny
  test: cargo-test
```

### Full Eight-Language Project

A project using all supported languages:

```yaml
# .devrail.yml — all supported languages
languages:
  - python
  - bash
  - terraform
  - ansible
  - ruby
  - go
  - javascript
  - rust

fail_fast: true
log_format: json

python:
  linter: ruff
  formatter: ruff
  security:
    - bandit
    - semgrep
  test: pytest
  type_check: mypy

terraform:
  linter: tflint
  formatter: terraform-fmt
  security:
    - tfsec
    - checkov
  test: terratest
  docs: terraform-docs

ruby:
  linter:
    - rubocop
    - reek
  formatter: rubocop
  security:
    - brakeman
    - bundler-audit
  test: rspec
  type_check: sorbet

go:
  linter: golangci-lint
  formatter: gofumpt
  security: govulncheck
  test: go-test

javascript:
  linter: eslint
  formatter: prettier
  security: npm-audit
  test: vitest
  type_check: tsc

rust:
  linter: clippy
  formatter: rustfmt
  security:
    - cargo-audit
    - cargo-deny
  test: cargo-test
```

## Language Support Matrix

The following table shows the default tool for each concern per language. These are the tools included in the `dev-toolchain` container.

| Concern | Python | Bash | Terraform | Ansible | Ruby | Go | JavaScript | Rust | Swift | Kotlin |
|---|---|---|---|---|---|---|---|---|---|---|
| Linter | ruff | shellcheck | tflint | ansible-lint | rubocop, reek | golangci-lint | eslint | clippy | SwiftLint | ktlint, detekt |
| Formatter | ruff format | shfmt | terraform fmt, terragrunt hclfmt | -- | rubocop | gofumpt | prettier | rustfmt | swift-format | ktlint |
| Security | bandit, semgrep | -- | tfsec, checkov | -- | brakeman, bundler-audit | govulncheck | npm audit | cargo-audit, cargo-deny | -- | OWASP dependency-check |
| Tests | pytest | bats | terratest | molecule | rspec | go test | vitest | cargo test | swift test | gradle test |
| Type Check | mypy | -- | -- | -- | sorbet | -- | tsc | -- | -- | -- |
| Docs | -- | -- | terraform-docs | -- | -- | -- | -- | -- | -- | -- |
| Universal | trivy, gitleaks | trivy, gitleaks | trivy, gitleaks | trivy, gitleaks | trivy, gitleaks | trivy, gitleaks | trivy, gitleaks | trivy, gitleaks | trivy, gitleaks | trivy, gitleaks |

**Notes:**

- "Universal" tools run for all languages and are not language-specific overrides
- A `--` entry means the concern does not apply to that language
- Default tools are used when no per-language override is specified
- `terraform` includes Terragrunt formatting (`terragrunt hclfmt`) — no separate language entry needed. Terragrunt formatting runs automatically when `terragrunt.hcl` files are detected

## Exit Codes

All tools consuming `.devrail.yml` follow standard DevRail exit codes:

| Code | Meaning |
|---|---|
| `0` | Pass |
| `1` | Failure (lint errors, test failures, security findings) |
| `2` | Misconfiguration (missing `.devrail.yml`, unknown language, container pull failure) |

## Schema Summary

| Key | Type | Required | Default | Description |
|---|---|---|---|---|
| `languages` | list of strings | Yes | -- | Languages used in the project |
| `fail_fast` | boolean | No | `false` | Stop on first failure |
| `log_format` | string | No | `json` | Output format (`json` or `human`) |
| `projects` | list of mappings | No | `[]` | Override autodetected per-language project roots (Python/JS monorepos) |
| `test` | mapping | No | `{}` | Override dependency install (`install`) and pre-test setup (`setup`) for `make test` |
| `<language>` | mapping | No | -- | Per-language tool overrides |
