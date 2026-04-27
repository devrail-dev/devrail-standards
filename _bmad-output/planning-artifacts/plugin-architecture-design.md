---
status: draft
storyId: '13.1'
date: '2026-04-27'
project_name: 'DevRail'
user_name: 'Matthew'
---

# Plugin Architecture Design

_Design for community-extensible language and tool support in DevRail._

## Overview

DevRail today is monolithic: every supported language is compiled into the dev-toolchain container, declared in a hardcoded `HAS_<LANG>` block in the Makefile, and documented across five repos. This works for the eight core languages (Python, Bash, Terraform, Ansible, Ruby, Go, JavaScript/TypeScript, Rust, Swift, Kotlin) but does not scale to community contributions: adding a single language requires PRs against five repos, image rebuilds, and core-team review.

This document specifies a plugin architecture that lets a community contributor add a new language ecosystem (or replace a tool inside an existing one) **without modifying any DevRail core repository**. The design preserves DevRail's foundational guarantees:

- `make check` is the single gate — it aggregates core targets and plugin targets uniformly.
- The dev-toolchain container is the single source of truth for tool versions.
- Project configuration lives in `.devrail.yml`.
- All output follows the existing structured JSON event format.

The chosen approach is a **declarative manifest + git-repo distribution** model — closest in spirit to the pre-commit framework, with elements borrowed from Terraform's required-providers and GitHub Actions' `action.yml`.

### Acceptance criteria mapping

| AC | Section |
|----|---------|
| 1 | Extension Points; Plugin Manifest; Plugin Lifecycle |
| 2 | Plugin Manifest; Example Walkthrough |
| 3 | Per-Language Tool Override |
| 4 | Make-Check Aggregation |
| 5 | Container Integration (Recommendation = Extended Image) |
| 6 | Example Walkthrough |
| 7 | This document, accepted via Story 13.1 review |

## Research Summary: Comparable Plugin Systems

Four ecosystems were studied as prior art. Each is summarized in one paragraph; full notes live in the story's research log.

**pre-commit** — Repo-based discovery via `repos:` in `.pre-commit-config.yaml`. Each plugin repo ships a `.pre-commit-hooks.yaml` manifest declaring hooks (id, entry, language). Pre-commit creates an isolated language environment per hook (Python venv, Node `node_modules`, Rust cargo target, etc.). Versions are pinned via immutable `rev:` (tag or SHA); branch refs are explicitly disallowed. `minimum_pre_commit_version` on a hook lets the framework refuse to run with an old core. _Lessons: declarative manifest, immutable refs, language-environment isolation._

**ESLint plugins** — npm-distributed, naming convention `eslint-plugin-<name>` or `@scope/eslint-plugin-<name>`. A plugin module exports `meta`/`rules`/`processors`/`configs`. Flat config (`eslint.config.js`) imports the plugin and registers it under a namespace; rules are addressed as `"namespace/rule-name"`. No runtime isolation — plugins share Node.js with ESLint. Versioning via `peerDependencies`. _Lessons: namespace-scoped identifiers; configs bundled with plugins; thin manifest._

**Terraform providers** — Declared in `required_providers { source = "ns/name", version = "~> 1.0" }`. Source addresses can target the public registry, an organization mirror, or a filesystem path with the same syntax. `terraform init` resolves and downloads; `.terraform.lock.hcl` records resolved versions and platform-specific hashes. Providers run as separate processes; Terraform speaks RPC to them, which gives strong isolation and a stable wire protocol. _Lessons: source-address triple (registry/namespace/name) is the global identity; lockfile is non-negotiable for reproducibility; out-of-process execution buys protocol stability._

**GitHub Actions** — `action.yml` manifest with `inputs`/`outputs`/`runs`. Three execution modes: composite (compose other steps), JavaScript (run on the runner), Docker container (full isolation, Linux-only). Referenced from workflows as `uses: owner/repo@ref`. Convention is to use moving major-version tags (`@v3`) backed by signed releases, or pinned commit SHAs for security-sensitive use. _Lessons: typed input/output contract; multiple execution modes for different isolation needs; major-version tag convention._

### Pattern synthesis

| Concern | Strongest pattern | Source |
|---|---|---|
| Discovery | Explicit declaration in project config | pre-commit, Terraform |
| Manifest | Single YAML at plugin repo root | pre-commit (`.pre-commit-hooks.yaml`), GH Actions (`action.yml`) |
| Identity | `host/namespace/name` source address | Terraform |
| Pinning | Immutable refs (tag or SHA) only, with lockfile | pre-commit, Terraform |
| Isolation | Per-language environment in shared host | pre-commit |
| Protocol versioning | Min-version field in manifest | pre-commit (`minimum_pre_commit_version`) |
| Multiple execution modes | Composite / JS / Docker | GitHub Actions |

DevRail's design adopts **declarative YAML manifests, git-repo distribution, immutable refs, a min-core-version field, and a single execution mode (extended container image)**. The single-mode choice is deliberate — DevRail's value proposition is _one container, one make check_ — and is revisited in [Container Integration](#container-integration).

## Current DevRail Extension Surface

Adding a language today touches **nine surfaces** across the dev-toolchain repo (and additional surfaces in standards/template/site repos that follow downstream). Plugins must address the same set; the goal is to push as much of this into a single declarative manifest as possible.

### 1. Makefile

Each language has:

- A `HAS_<LANG>` filter near the top: `HAS_RUBY := $(filter ruby,$(LANGUAGES))`.
- Five conditional blocks in `_lint`, `_format`, `_fix`, `_test`, `_security` — each ~10–25 lines of bash inside the recipe, reading project files to gate execution and invoking tools.
- A scaffolding block in `_init` that writes default config files.
- A line in the tool-version manifest under `_docs`.

Example pattern (current, simplified):

```makefile
if [ -n "$(HAS_RUBY)" ]; then
    ran_languages="$${ran_languages}\"ruby\","
    ruby_paths=""
    for p in $(RUBY_PATHS); do [ -d "$$p" ] && ruby_paths="$$ruby_paths $$p"; done
    if [ -n "$$ruby_paths" ]; then
        rubocop $$ruby_paths || { overall_exit=1; failed_languages="$${failed_languages}\"ruby:rubocop\","; }
    fi
fi
```

### 2. Dockerfile

- Optional `<lang>-builder` stage when the language needs a separate compiler/runtime (Rust, Swift, Ruby, JDK, Node).
- `RUN bash /opt/devrail/scripts/install-<lang>.sh` line in the runtime stage.
- COPY blocks from builder stages.
- APT packages added to the base layer when needed (e.g., `libyaml-0-2` for Ruby's psych binding).

### 3. `scripts/install-<lang>.sh`

Idempotent installer. Sources `lib/log.sh` and `lib/platform.sh`. For COPY-pattern languages (Go, Rust, Ruby) this becomes verify-only.

### 4. `tests/test-<lang>.sh`

Smoke test verifying every tool is on `PATH` and reports a version.

### 5. `.devrail.yml`

A line in `languages:` plus, optionally, per-language overrides.

### 6. `devrail-init.sh`

The `ALL_LANGUAGES` constant; per-language scaffolding via the `_init` Make target.

### 7. Pre-commit template (`.pre-commit-config.yaml`)

In the github/gitlab repo templates, language-specific hook entries (e.g., `mirrors-eslint`, `pre-commit-cargo`).

### 8. CI templates

Per-language extras when the language can't run inside dev-toolchain (e.g., the dedicated Rails rspec job with a Postgres service).

### 9. Standards documentation

`standards/<lang>.md` in OrgDocs and devrail-standards (mirror); `content/docs/standards/<lang>.md` in devrail.dev. Plus one row in the language matrix in each `_index.md`.

A plugin must replace surfaces 1–6 declaratively, can opt into surface 7, and is responsible for documenting itself (surfaces 8–9 stay manual but are plugin-author concerns, not core concerns).

### Per-target gating files (existing convention)

These file-existence checks are how core languages decide whether each target should run. Plugins must declare their own gates.

| Target | Gate file (examples) |
|---|---|
| `_lint` | source files of the language type |
| `_format` | same as `_lint` |
| `_test` | `*_test.go`, `spec/`, `*.test.js`, `tests/` |
| `_security` | `Gemfile.lock` (bundler-audit), `go.sum` (govulncheck), `Cargo.lock` (cargo-audit), `package-lock.json` (npm audit) |
| `_security` (Rails) | `config/application.rb` (brakeman) |

## Plugin Manifest

Each plugin is a git repo whose root contains a `plugin.devrail.yml` manifest. The repo also contains an install script and any container fragments the plugin needs.

```yaml
# plugin.devrail.yml — declares an Elixir language plugin
schema_version: 1            # plugin manifest schema; bumped on breaking changes
name: elixir                 # the language identifier consumers list in .devrail.yml
version: 1.0.0               # plugin's own semver
description: "Elixir language support for DevRail"
homepage: https://github.com/community/devrail-plugin-elixir

# Minimum core version; the loader refuses to load this plugin against an older core.
devrail_min_version: 1.10.0

# Container fragment — see "Container Integration" for the full contract.
container:
  base_image: elixir:1.17-slim   # used when this plugin is built as the runtime
  install_script: install.sh     # path inside the plugin repo
  apt_packages:                  # appended to runtime apt layer when extending the image
    - inotify-tools
  copy_from_builder:             # paths to COPY from the builder stage (optional)
    - /usr/local/bin/elixir
    - /usr/local/bin/mix
    - /usr/local/lib/elixir
  env:                           # ENV directives to add to the runtime image
    MIX_ENV: prod

# Target commands. Each is a single shell command run inside the dev-toolchain container.
# `paths_var` interpolates a Make-level variable similar to RUBY_PATHS.
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

# Per-target gates. The target only runs when ALL listed paths exist (file or dir).
# Glob patterns supported; absolute paths NOT supported (workspace-relative only).
gates:
  lint:     ["mix.exs"]
  format_check: ["mix.exs"]
  format_fix:   ["mix.exs"]
  test:     ["mix.exs", "test/"]
  security: ["mix.lock"]

# Pre-commit hook entries to inject when consumers opt in.
# These are passed through verbatim to .pre-commit-config.yaml.
pre_commit:
  - repo: https://github.com/JakeBecker/elixir-formatter
    rev: v1.2.0
    hooks:
      - id: mix-format

# Files written by `make init` when the language is selected.
init_scaffolds:
  - dest: .credo.exs
    content_template: scaffolds/credo.exs.tmpl
  - dest: .formatter.exs
    content_template: scaffolds/formatter.exs.tmpl

# Tool version reporting.
tool_versions:
  - name: elixir
    cmd: "elixir --version | head -1"
  - name: mix
    cmd: "mix --version"
  - name: credo
    cmd: "mix credo --version"
```

### Manifest schema rules

- `schema_version` (int, required) — pinned at `1` for the initial release. The loader rejects manifests with an unknown major schema.
- `name` (string, required) — must match `^[a-z][a-z0-9_-]*$`. Becomes the language identifier in `.devrail.yml`.
- `version` (semver string, required) — plugin's own version.
- `devrail_min_version` (semver string, required) — minimum dev-toolchain version. The loader compares against the running container's version and refuses load on mismatch.
- `targets` (mapping, required) — at least one of `lint`, `format_check`, `format_fix`, `fix`, `test`, `security`. Each target's `cmd` is a string interpolated with `{paths}` if `paths_var` is set.
- `gates` (mapping, optional) — per-target list of paths that must all exist for the target to run. Empty list = always run. Missing key = always run.
- `container` (mapping, optional but typically required) — see [Container Integration](#container-integration).
- `pre_commit` (list, optional) — verbatim entries appended to consumer `.pre-commit-config.yaml`.
- `init_scaffolds` (list, optional) — files written by `make init`.
- `tool_versions` (list, optional) — entries for the version manifest.

### Plugin identity

A plugin is identified by its **source address**, mirroring Terraform: `host/namespace/name`. For initial release only git URLs are supported; a registry layer can be added later without breaking change. Examples:

- `github.com/community/devrail-plugin-elixir`
- `gitlab.example.com/internal/devrail-plugin-cobol`

The trailing `name` does not have to match the manifest's `name` field, but convention is `devrail-plugin-<name>`.

## Project Configuration (`.devrail.yml`)

Consumers declare plugins in their `.devrail.yml`:

```yaml
languages:
  - python
  - bash
  - elixir          # provided by a plugin

plugins:
  - source: github.com/community/devrail-plugin-elixir
    rev: v1.0.0     # immutable ref — tag or SHA, never a branch
    languages: [elixir]   # which `languages:` entries this plugin supplies

env:
  MIX_HOME: /workspace/.mix
```

### Resolution rules

- For each entry in `languages:`, the loader checks core compiled-in languages first, then plugins.
- A plugin's `languages:` field declares which language identifiers it provides. The loader fails fast on conflicts (two plugins claim `elixir`).
- `rev:` is required and must be an immutable ref. Branch refs are rejected.
- Existing per-language overrides (`ruby: { linter: ... }`) work for plugin languages too.

### Lockfile

Once plugins are introduced, `.devrail.lock` (sibling of `.devrail.yml`) records the resolved commit SHA, manifest schema version, and content hash for every declared plugin. Lockfile is checked into VCS. Loader refuses to run when `.devrail.yml` and `.devrail.lock` disagree without an explicit `make plugins-update`.

## Plugin Lifecycle

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  ┌───────────────┐       ┌──────────────────┐                   │
│  │  make check   │──────▶│  plugin loader   │                   │
│  └───────────────┘       └────────┬─────────┘                   │
│                                   │                             │
│           ┌───────────────────────┼───────────────────────┐     │
│           ▼                       ▼                       ▼     │
│   ┌──────────────┐       ┌─────────────────┐    ┌─────────────┐ │
│   │ resolve refs │──────▶│ verify checksums│───▶│ load mfsts  │ │
│   │ (.devrail.yml│       │ (.devrail.lock) │    │ validate    │ │
│   │  + plugins:) │       └─────────────────┘    │ schema      │ │
│   └──────────────┘                              └──────┬──────┘ │
│                                                        │        │
│                                                        ▼        │
│                          ┌──────────────────────────────────┐   │
│                          │   for each target               │   │
│                          │   (lint, format, test, ...)     │   │
│                          │                                  │   │
│                          │   1. core HAS_<LANG> blocks      │   │
│                          │   2. for each plugin, evaluate   │   │
│                          │      gate, run cmd, record       │   │
│                          │      result in JSON summary      │   │
│                          └──────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

1. **Discovery**. The plugin loader reads `plugins:` from `.devrail.yml`.
2. **Resolution**. For each plugin, it resolves the `rev` against the configured source. SHAs are used directly; tags are resolved to SHAs and verified against `.devrail.lock` if present.
3. **Fetch**. Plugin repos are cloned to `~/.cache/devrail/plugins/<host>/<namespace>/<name>/<sha>` (host) or `/opt/devrail/plugins/<sha>` (in-container). Caches are content-addressed; refetching the same SHA is a no-op.
4. **Validation**. The manifest is parsed and validated against the schema; `devrail_min_version` is compared to the running container version. Any failure aborts before running any tools.
5. **Build (extended-image mode)**. For each plugin, a project-local `Dockerfile.devrail` is generated that extends `ghcr.io/devrail-dev/dev-toolchain:v1` with the plugin's `apt_packages`, COPY blocks, install script, and ENV. The resulting image is built and tagged `devrail-local:<hash-of-plugins>`. Cached by content hash.
6. **Execute**. `make _lint` (etc.) runs inside the project-local image. The core Makefile body has hardcoded blocks for compiled-in languages plus a final loop over plugin manifests:
    ```bash
    for plugin in $$(yq '.plugins[].name' .devrail.yml); do
      gate_ok=$$(check_gates lint "$$plugin")
      if [ "$$gate_ok" = "1" ]; then
        cmd=$$(yq ".targets.lint.cmd" /opt/devrail/plugins/.../plugin.devrail.yml)
        eval "$$cmd" || record_failure "$$plugin" "lint"
      fi
    done
    ```
7. **Aggregate**. Plugin results enter the existing `ran_languages`/`failed_languages`/JSON summary path. From the consumer's perspective the JSON is identical whether a language is core or plugin-provided.

## Make-Check Aggregation

`make check` continues to call `_lint`, `_format`, `_test`, `_security`, `_scan`, `_docs` and produce a single JSON summary. Plugin results are reported in the same arrays:

```json
{
  "target": "check",
  "status": "fail",
  "duration_ms": 45123,
  "results": [
    {"target": "lint", "status": "fail", "duration_ms": 12300},
    {"target": "format", "status": "pass", "duration_ms": 800}
  ],
  "passed": ["format", "scan"],
  "failed": ["lint"]
}
```

The granular per-language entries (`failed_languages: ["ruby:rubocop", "elixir:credo"]`) remain unchanged — plugin languages appear alongside core languages with the same identifier convention `<language>` or `<language>:<tool>`.

`DEVRAIL_FAIL_FAST=1` continues to short-circuit on first failure regardless of whether the failing language is core or plugin.

## Per-Language Tool Override

The existing override mechanism in `.devrail.yml` extends naturally to plugin languages:

```yaml
elixir:
  linter: dialyxir          # overrides plugin default of credo
  test: "mix test --cover"  # overrides plugin default
```

The plugin manifest's `targets.<name>.cmd` is the default; an override in `.devrail.yml` replaces the entire command string for that target. This keeps the override surface symmetric with core languages.

## Container Integration

Four strategies were evaluated for how plugins add tools to the runtime environment.

### Option A: Extended image (RECOMMENDED)

A consumer's `make check` builds a project-local image that extends the core dev-toolchain image, layering plugin install steps on top:

```dockerfile
# Auto-generated; do not edit by hand.
FROM ghcr.io/devrail-dev/dev-toolchain:v1.10.0 AS runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
      inotify-tools \
    && rm -rf /var/lib/apt/lists/*
COPY --from=elixir:1.17-slim /usr/local/bin/elixir /usr/local/bin/elixir
COPY --from=elixir:1.17-slim /usr/local/bin/mix /usr/local/bin/mix
COPY --from=elixir:1.17-slim /usr/local/lib/elixir /usr/local/lib/elixir
ENV MIX_ENV=prod
RUN bash /opt/devrail/plugins/elixir/install.sh
```

**Pros.**
- Single container at `make check` time — preserves the existing mental model.
- Multi-stage builder pattern is already used internally for Rust/Swift/Ruby/JDK; familiar.
- Build cache works exactly like the current container (BuildKit content-addresses each layer; unchanged plugin set produces a cache hit).
- Tool versions remain reproducible because the plugin manifest pins everything.
- Compatible with the existing CI flow — `docker build` runs once per pipeline.

**Cons.**
- Adds a build step on the consumer's first run with a new plugin set (~30s–2min depending on plugin).
- Requires Docker BuildKit (already a hard requirement).

### Option B: Sidecar containers

Plugin tools run in separate containers; the dev-toolchain container orchestrates them via `docker exec` or shared volumes.

**Pros.** Strong isolation; independent versioning per plugin.

**Cons.** Significantly more complex. Requires container-in-container or socket mounting; cross-platform support is fiddly; adds latency per tool invocation; turns `make check` from a single `docker run` into a small orchestration system. Conflicts with the "one container" simplicity that DevRail trades on.

### Option C: Volume-mounted plugins

Plugin binaries are mounted into the dev-toolchain container at runtime via `-v` flags.

**Pros.** No image rebuild.

**Cons.** Host-platform dependency (plugin must ship binaries for every supported arch); breaks reproducibility (plugin contents on the host can drift from what `.devrail.lock` records); CI implications are messy. Host-platform binary distribution is a problem we explicitly don't want to take on.

### Option D: Runtime install

`make check` runs the plugin's install script inside the container at every invocation, installing tools into a tmpfs or named volume.

**Pros.** Zero build step.

**Cons.** Slow first run on every host; depends on network availability at run time; plugin authors carry the entire risk surface of a "works in CI / fails on plane wifi" install script. Caching would mitigate but pushes us back toward the Extended-image complexity without its benefits.

### Decision

**Option A — Extended image — is the recommendation.**

Rationale: it preserves DevRail's "one container, one make check" guarantee, reuses the multi-stage builder pattern already proven in core, gets correct caching behavior for free via BuildKit content-addressing, and gives plugin authors a familiar Dockerfile-fragment-shaped contract. The first-run build cost is the only meaningful downside, and it is amortized across subsequent invocations in the same project.

A future runtime-install fallback (Option D) for casual experimentation can be layered on top without changing the plugin manifest contract — the manifest is execution-mode-agnostic.

## Distribution & Versioning

### Distribution

- **Storage.** Public git repositories. No registry layer in v1; the source-address triple (`host/namespace/name`) is sufficient identity.
- **Naming convention.** `devrail-plugin-<name>` for the repo. Not enforced — `name` in the manifest is authoritative — but encouraged for discoverability.
- **Discovery.** Initially a curated `awesome-devrail` README listing community plugins, similar to pre-commit's hook index. A registry can be added in a later phase.
- **Trust.** Plugin authors are responsible for signing their tags. The lockfile records content hashes so tampering with a tag (rebasing it onto different code) is detected. A future enhancement is integration with `cosign` for tag signature verification.

### Versioning

Three version axes coexist:

1. **Plugin schema version (`schema_version`)** — the manifest's own format. Bumped on a breaking change to the manifest. The loader rejects unknown majors. **Currently `1`.**
2. **Plugin version (`version`)** — semver of the plugin itself. Consumers pin via `rev:` (tag or SHA, immutable). The plugin author owns this versioning.
3. **DevRail minimum version (`devrail_min_version`)** — the oldest dev-toolchain version this plugin supports. The loader compares it against the running container's version (read from the image label `org.opencontainers.image.version`). Plugins use this to require new manifest fields without breaking older cores.

### Lockfile

`.devrail.lock` (YAML) is checked into VCS and looks like:

```yaml
schema_version: 1
plugins:
  - source: github.com/community/devrail-plugin-elixir
    rev: v1.0.0
    sha: 7f3a2b8e5c1d9a6b2e4f8a1c0d3b5e7a9c2f4d6b
    schema_version: 1
    content_hash: sha256:abcd...
```

`make plugins-update` re-resolves all `rev:` entries and rewrites the lockfile. `make check` refuses to run if `.devrail.yml` and `.devrail.lock` disagree, mirroring `bundler` / `cargo` / `npm ci` behavior.

### Backwards compatibility commitments

- The DevRail core team commits to keeping schema_version `1` valid for at least one major (v2.x) after a successor schema is introduced.
- Adding optional fields to `plugin.devrail.yml` is not a schema bump.
- Removing or renaming required fields is a schema bump.
- Changing the meaning of an existing field is a schema bump.
- Plugin authors can target multiple core majors by leaving optional fields unset.

## Security Model

A plugin executes arbitrary install-script bash inside the consumer's container build, then arbitrary commands inside the runtime container. Treating plugins as trusted code is the correct mental model — the same as treating a pre-commit hook repo as trusted, or a GitHub Action.

Mitigations:

- **Immutable refs only** — tag rebasing is detected by the lockfile content hash.
- **No automatic upgrades** — `rev:` is what runs; `make plugins-update` is the only path to new code, and it produces a reviewable lockfile diff.
- **Schema validation** — a structurally invalid manifest never runs.
- **`make check` is the gate** — plugin code runs inside the container, on the consumer's source tree, with the container's filesystem and network access. This is identical to the existing trust model for the core image.
- **No plugin-managed secrets** — plugins must not read `.env` files or expect secret injection beyond what's already in `.devrail.yml`'s `env:` block, which the consumer controls.
- **Future**: cosign-style signature verification for plugin release tags, an opt-in flag in `.devrail.yml` (`plugin_signature_required: true`).

## Example Walkthrough — An Elixir Plugin

Concrete end-to-end example: a community contributor wants to add Elixir support without forking the dev-toolchain repo.

### Step 1: Plugin repo layout

```
devrail-plugin-elixir/
├── plugin.devrail.yml
├── install.sh                         # runs inside the runtime stage
├── scaffolds/
│   ├── credo.exs.tmpl
│   └── formatter.exs.tmpl
├── tests/test-elixir.sh               # mirrors core test-<lang>.sh
├── README.md
└── LICENSE
```

`plugin.devrail.yml` is the manifest shown in [Plugin Manifest](#plugin-manifest).

`install.sh`:

```bash
#!/usr/bin/env bash
# Install Elixir tools (credo, mix_audit) — runs inside the runtime image.
set -euo pipefail
mix local.hex --force
mix local.rebar --force
mix archive.install hex credo --force
mix archive.install hex mix_audit --force
```

The author tags the repo `v1.0.0`.

### Step 2: Consumer adoption

A project that wants Elixir support adds:

```yaml
# .devrail.yml
languages: [elixir]
plugins:
  - source: github.com/community/devrail-plugin-elixir
    rev: v1.0.0
    languages: [elixir]
```

Then runs `make plugins-update` to populate `.devrail.lock`, commits both files, and runs `make check`.

### Step 3: First `make check` execution

```
$ make check
{"level":"info","msg":"resolving plugin: github.com/community/devrail-plugin-elixir@v1.0.0","script":"plugin-loader"}
{"level":"info","msg":"sha matches lockfile (7f3a2b8e...)","script":"plugin-loader"}
{"level":"info","msg":"building extended image devrail-local:f3c9...","script":"plugin-loader"}
[+] Building 47.2s (12/12) FINISHED
{"target":"lint","status":"pass","duration_ms":2891,"languages":["elixir"]}
{"target":"format","status":"pass","duration_ms":312,"languages":["elixir"]}
{"target":"test","status":"pass","duration_ms":4230,"languages":["elixir"]}
{"target":"security","status":"pass","duration_ms":890,"languages":["elixir"]}
{"target":"check","status":"pass","duration_ms":8650,"results":[...],"passed":["lint","format","test","security","scan","docs"],"failed":[]}
```

Subsequent runs reuse the cached extended image (~3s overhead vs the core image alone).

### Step 4: Replacing the default tool

The consumer prefers `dialyxir` over the plugin's default `credo`:

```yaml
elixir:
  linter: dialyxir
```

The plugin's `targets.lint.cmd` is replaced by the consumer's command. Everything else (gates, container, version manifest) stays the same.

### Step 5: Plugin upgrade

The plugin author publishes `v1.1.0`. The consumer:

```bash
$ vim .devrail.yml          # bump rev: v1.0.0 -> v1.1.0
$ make plugins-update       # rewrites .devrail.lock with the new sha
$ git diff .devrail.lock    # review the resolved sha and content hash
$ make check                # rebuilds the extended image, runs the new toolchain
```

## Migration Path

The transition from monolith to plugin-capable is staged across three releases.

### Phase 1 — `v1.10.0`: Plugin loader, all core languages remain compiled-in

- Add the plugin loader to the dev-toolchain container.
- Add `plugins:` schema to `.devrail.yml`.
- Add `make plugins-update` and `.devrail.lock` handling.
- Document the plugin manifest contract.
- All eight core languages continue to be compiled into the runtime image. `HAS_<LANG>` blocks remain in the Makefile.
- **Compatibility**: Projects that don't add `plugins:` see no behavior change.

### Phase 2 — `v1.11.0`: Reference plugin, hybrid mode validated

- Extract one core language (proposed: Kotlin, the newest) into a community-maintained plugin in a separate repo.
- The dev-toolchain image continues to ship Kotlin tooling for back-compat, but a project can opt out by setting `legacy_languages: [kotlin]: false` in `.devrail.yml` and using the plugin instead.
- Document the extraction process so other languages can follow.
- **Compatibility**: No project breakage; opt-in plugin path proven on a real ecosystem.

### Phase 3 — `v2.0.0`: Plugins are first-class

- Remove all `HAS_<LANG>` blocks from the core Makefile. All language support becomes plugin-based.
- The dev-toolchain image becomes a thin runtime hosting the plugin loader and shared libraries; per-language tooling moves to plugin repos.
- `devrail-plugin-python`, `devrail-plugin-ruby`, etc. become the canonical homes.
- Projects must declare `plugins:` for any language they want, including former core languages.
- **Compatibility**: Major bump — projects on `:v1` continue working unchanged. Migration to `:v2` requires adding `plugins:` entries for all used languages. Provide an automated migration tool: `devrail-init migrate --to v2`.

The phasing keeps every intermediate state shippable and avoids a flag day.

## Open Questions

These are deferred to subsequent stories:

1. **Registry vs git-only**. Initial release is git-only. A registry (similar to `registry.terraform.io` or `pypi.org`) would simplify discovery but adds infrastructure. Decision deferred to v2 timeframe.
2. **Plugin signing**. `cosign`-style signature verification on plugin release tags. Adds tooling burden; defer until first reported supply-chain incident or until enabled-by-default in dependency tooling more broadly.
3. **Parallel plugin execution**. Plugin loops are sequential in v1. Parallelizing requires defining what shared state (filesystem mutations, environment variables) plugins are allowed to touch.
4. **Plugin-to-plugin dependencies**. Manifest doesn't yet support `requires: [other-plugin]`. Defer until a real use case emerges.
5. **Standards-doc auto-generation**. A plugin could ship `standards.md` content; the devrail.dev site could auto-include third-party plugin docs. Out of scope for v1.
6. **Handling plugin-introduced CI services** (e.g., the Postgres rspec pattern). Plugins currently can't declare CI-only services. Documented workaround: the plugin README instructs the consumer to add the relevant block to their CI config. A future schema field (`ci_services:`) would automate this.
7. **`devrail init` integration**. `make init` consults `init_scaffolds`, but `devrail-init.sh` (the curl-pipe-bash bootstrapper) doesn't yet know about plugins. Needs a follow-up story.

## References

- [Source: `_bmad-output/planning-artifacts/architecture.md`] — current system architecture
- [Source: `_bmad-output/planning-artifacts/prd.md`] — Phase 3 plugin architecture goal
- [Source: `standards/contributing.md`] — current language addition checklist
- [Source: `standards/makefile-contract.md`] — Makefile behavioral contract that plugins must respect
- [Source: `dev-toolchain/Dockerfile`] — current container build pattern (multi-stage builders)
- [Source: `dev-toolchain/Makefile`] — current `HAS_<LANG>` pattern and language detection
- [pre-commit framework documentation](https://pre-commit.com/#new-hooks)
- [ESLint plugin documentation](https://eslint.org/docs/latest/extend/plugins)
- [Terraform `required_providers`](https://developer.hashicorp.com/terraform/language/providers/requirements)
- [GitHub Actions custom actions](https://docs.github.com/en/actions/sharing-automations/creating-actions/about-custom-actions)
