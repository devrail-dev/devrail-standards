---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
inputDocuments: [prd.md]
workflowType: 'architecture'
lastStep: 8
status: 'complete'
completedAt: '2026-02-19'
project_name: 'DevRail'
user_name: 'Matthew'
date: '2026-02-18'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements:**
44 FRs across 9 capability areas. The requirements define a multi-repo ecosystem where a dev-toolchain container, Makefile contract, project templates, CI pipelines, and agent instruction files work together to enforce consistent developer standards.

**Non-Functional Requirements:**
- Performance: `make check` < 5 min, pre-commit hooks < 30 sec, individual targets < 60 sec
- Security: Trusted base images, trivy self-scan, no baked secrets, GHCR image signing
- Reliability: Weekly builds with semver, graceful hook failures, fail-fast CI
- Compatibility: linux/amd64 + linux/arm64, Linux + macOS hosts, pre-commit v3+, Git 2.28+
- Integration: GHCR, GitHub Actions, GitLab CI, pre-commit framework

**Scale & Complexity:**
- Primary domain: Developer infrastructure / CI-CD tooling
- Complexity level: Medium
- Architectural components: 6 repos, 1 container image, 2 CI platforms, 4 language ecosystems, 4 agent instruction formats

### Technical Constraints & Dependencies

- Dev-toolchain container must be the single source of all tool versions — no tool installation outside the container
- Makefile targets must produce identical output regardless of invocation context (local, CI, agent)
- Templates for GitHub and GitLab must be functionally equivalent despite platform-specific CI syntax
- Pre-commit hooks must be fast enough for developer flow (< 30 sec) while CI runs the full suite
- Container must support both amd64 and arm64 for CI runners and Apple Silicon development

### Cross-Cutting Concerns

- **Version pinning strategy:** How templates reference container versions, how upgrades propagate
- **Makefile contract consistency:** Same targets, same behavior, across all supported languages
- **Agent instruction synchronization:** Changes to canonical standards must flow to all shim files
- **Dogfooding:** All DevRail repos must use their own standards — the ecosystem validates itself

## Starter Template & Technology Foundations

### Technology Domain

Developer infrastructure — multi-repo ecosystem. No single application framework. Each repo has purpose-built, minimal technology choices.

### Per-Repo Technology Decisions

| Repo | Technology | Starter/Foundation |
|---|---|---|
| **devrail-standards** | Markdown | From scratch — plain documentation |
| **dev-toolchain** | Dockerfile (Debian-based) + shell scripts | From scratch — one install script per language |
| **pre-commit-conventional-commits** | Python (pre-commit framework) | Existing repo — verify and update |
| **github-repo-template** | GitHub template repo + GitHub Actions | From scratch — Makefile + config files |
| **gitlab-repo-template** | GitLab template + `.gitlab-ci.yml` | From scratch — Makefile + config files |
| **devrail.dev** | Hugo + Docsy theme | `hugo new site` + Docsy module, hosted on Cloudflare |

### Foundation Decisions

**Container Base Image:** Debian-based (not Alpine). Broader compatibility with language toolchains, fewer musl-related build issues. Dev tooling image — size is acceptable.

**Makefile Style:** GNU Make with `.PHONY` targets. Two-layer delegation pattern:
- Layer 1 (user-facing): `make check` — delegates to Docker container
- Layer 2 (container-internal): `make _check` — runs actual tool commands
- No alternative build tools (Just, Task, etc.) — GNU Make is universal and dependency-free

**Hugo Site:** Docsy theme via Hugo modules. Documentation-focused, supports versioning, search, and multi-section navigation out of the box.

**Rationale:** Every technology choice optimizes for universality and zero-dependency adoption. No exotic tools, no framework lock-in. A developer (or agent) encountering any DevRail repo should immediately understand the structure.

## Core Architectural Decisions

### Plugin Architecture (Phase 3)

DevRail's monolithic-image model is intentional for the MVP and post-MVP core
language set, but Phase 3 (per PRD §"Phase 3: Community & Platform Integration")
introduces a plugin architecture for community-contributed languages and tools.
The design lives in a companion document: see
[`plugin-architecture-design.md`](plugin-architecture-design.md). Implementation
is staged across `v1.10.0` (loader), `v1.11.0` (reference plugin extraction),
and `v2.0.0` (monolithic-block retirement, breaking change) — see Epic 13.

### Decision Priority Analysis

**Critical Decisions (Block Implementation):**
1. Multi-stage Dockerfile with modular install scripts
2. Major-version floating tags for container versioning
3. `.devrail.yml` config file for language declaration
4. Hybrid agent shim files with critical rules inlined

**Important Decisions (Shape Architecture):**
5. Configurable error handling (run-all default, fail-fast optional)
6. Single DEVELOPMENT.md with structured machine-readable markers
7. Parallel CI jobs per check category
8. Fast-local / slow-CI pre-commit split

**Deferred Decisions (Post-MVP):**
- Automated shim generation from DEVELOPMENT.md markers (manual sync is fine for MVP)
- Renovate/Dependabot automation for container version bumps
- CI performance optimization beyond the 5-minute budget

### Container Build Architecture

- **Decision:** Multi-stage Dockerfile with per-language install scripts
- **Structure:** Builder stages compile Go-based tools (tflint, terraform-docs, trivy, gitleaks); per-language scripts (`install-python.sh`, `install-terraform.sh`, etc.) handle ecosystem-specific installs; final stage copies runtime artifacts only
- **Rationale:** Clean separation of build-time and runtime dependencies; modular scripts allow independent maintenance; adding languages is one script + one Dockerfile line

### Version Pinning & Upgrade Propagation

- **Decision:** Major-version floating tag (`v1`) with exact semver tags also published
- **Tagging Strategy:** Weekly builds publish `v1.3.2` (exact) and update `v1` (floating major). Breaking changes bump the major version.
- **Template Reference:** Templates default to `ghcr.io/devrail-dev/dev-toolchain:v1`. Repos needing reproducibility pin exact versions.
- **Rationale:** Non-breaking tool updates propagate automatically; major version boundary protects against surprise breakage

### Makefile Contract Specification

- **Language Detection:** `.devrail.yml` config file at repo root declares languages, settings, and project metadata. Read by Makefile, CI, and agents.
- **Error Handling:** Run-all-report-all by default (CI and agents see every issue). Fail-fast available via `DEVRAIL_FAIL_FAST=1` env var or `.devrail.yml` setting.
- **Target Contract:** `make lint`, `make format`, `make test`, `make security`, `make scan`, `make docs`, `make check` (all), `make install-hooks`. Each delegates to Docker; internal `_`-prefixed targets execute inside the container.
- **Rationale:** Explicit config eliminates guessing; configurable error handling serves both agent workflows (fix everything at once) and developer workflows (fast feedback)

### Agent Instruction Architecture

- **Shim Strategy:** Hybrid — each tool-specific file (CLAUDE.md, AGENTS.md, .cursorrules, .opencode/) contains a pointer to DEVELOPMENT.md plus critical rules inlined (run `make check`, conventional commits, etc.)
- **Canonical Source:** Single DEVELOPMENT.md with structured markers (`<!-- devrail:critical-rules -->`, etc.) enabling future automated extraction
- **Rationale:** Critical behaviors are present in every tool's native file regardless of cross-reference support; full standards consolidated in one human-readable, machine-parseable document

### CI Pipeline Design

- **Job Structure:** Parallel jobs per category — lint, format, security, test, docs. Each job pulls the container and runs its specific `make` target. Granular status checks on PRs/MRs.
- **Caching:** Natural caching — self-hosted runners retain images between runs; hosted runners pull fresh (no special cache directives needed)
- **Rationale:** Parallel execution stays within 5-minute budget; granular pass/fail gives developers and agents clear signal on what needs fixing

### Pre-commit Hook Strategy

- **Local hooks (< 30 sec):** Formatting, linting, conventional commits, gitleaks
- **CI-only:** Security scanning (trivy, tfsec/checkov), full test suites, terraform-docs generation
- **Rationale:** Catches the most common issues instantly before push; heavy scanning runs where time is less critical

### Decision Impact Analysis

**Implementation Sequence:**
1. `.devrail.yml` schema definition (everything reads this)
2. Container Dockerfile + install scripts (everything runs in this)
3. Makefile contract implementation (everything calls this)
4. DEVELOPMENT.md + agent shim files (agents read these)
5. Pre-commit configuration (local enforcement)
6. CI pipeline templates (remote enforcement)

**Cross-Component Dependencies:**
- `.devrail.yml` schema must be defined before Makefile and CI can consume it
- Container must be built and published before any Makefile target can delegate to it
- DEVELOPMENT.md markers must be defined before shim files can reference them
- Makefile targets must be finalized before CI jobs can call them

## Implementation Patterns & Consistency Rules

### Pattern Categories Defined

**Critical Conflict Points Identified:** 6 categories where AI agents could make different choices, with explicit rules to prevent divergence.

### Shell Script Conventions

**All scripts MUST follow these rules:**

- `#!/usr/bin/env bash` + `set -euo pipefail` — always, no exceptions
- **Idempotent by default** — check before acting, safe to re-run. Use `command -v tool || install_tool`, `mkdir -p`, guard file writes with existence checks
- Variables: `UPPER_SNAKE_CASE` for env/constants with `readonly`, `lower_snake_case` for locals
- Functions: `lower_snake_case`, prefixed by purpose (`install_`, `check_`, `log_`)
- Argument parsing via getopts; every script supports `--help`
- Shellcheck compliant — enforced by lint target
- Python CLIs use Click

**Shared Library (`lib/`):**
- `lib/log.sh` — logging functions, verbosity control
- `lib/platform.sh` — platform detection helpers (`on_mac`, `on_linux`, `on_arm64`)

**Logging Standard:**
- Shared log functions: `log_info`, `log_warn`, `log_error`, `log_debug`, `die`
- `die "message"` — log error + exit 1 in one call
- JSON output by default: `{"level":"info","msg":"...","script":"...","ts":"..."}`
- Human-readable via `DEVRAIL_LOG_FORMAT=human`: `[INFO]  message`
- Three verbosity levels: quiet (`DEVRAIL_QUIET=1`), normal (default), debug (`DEVRAIL_DEBUG=1`)
- All log output to stderr — stdout reserved for tool output
- No raw `echo` for status messages, no inline ANSI colors — log library handles formatting
- Error entries include `exit_code` when applicable

**Validation & Helpers:**
- `is_empty`, `is_not_empty`, `is_set` — one way to check variables, every time
- `require_cmd "docker" "Install Docker to continue"` — dependency guards upfront
- Platform detection: `on_mac`, `on_linux`, `on_arm64`

**Cleanup & Safety:**
- Trap handlers registered at script start: `trap cleanup EXIT`
- Temp files via `mktemp` only, cleaned up by trap
- No interactive prompts — scripts run in containers and CI

**Self-Documenting Scripts:**
- Structured header comment: purpose (one line), usage, dependencies
- `--help` flag auto-extracts usage from header — no hand-written usage strings

### Makefile Authoring Patterns

- Public targets: `lower-kebab-case` (e.g., `install-hooks`). Internal targets: `_` prefix (e.g., `_lint`)
- No abbreviations — `security` not `sec`, `format` not `fmt`
- Every public target: `## description` comment for `make help` auto-generation
- `make help` as the default target
- Variables: `UPPER_SNAKE_CASE`, overridable with `?=` (e.g., `DEVRAIL_IMAGE ?= ghcr.io/devrail-dev/dev-toolchain:v1`)
- File structure: variables → `.PHONY` declarations → public targets → internal targets

### Configuration File Formats

**`.devrail.yml`:**
- YAML format — consistent with CI/CD ecosystem
- `snake_case` for all keys — no camelCase, no kebab-case
- Top-level keys: `languages`, `fail_fast`, `log_format`, plus per-language overrides
- Comments encouraged for non-obvious settings

**DEVELOPMENT.md markers:**
- HTML comment syntax: `<!-- devrail:section-name -->` / `<!-- /devrail:section-name -->`
- Paired open/close tags for extractable sections
- Invisible when rendered, machine-parseable for tooling

**EditorConfig:**
- `.editorconfig` in every repo — indent style, line endings, trailing whitespace
- Agents must respect existing `.editorconfig`, never override without explicit instruction

### File & Directory Organization

**Container repo (`dev-toolchain`):**
```
Dockerfile
Makefile
.devrail.yml
scripts/
  install-python.sh
  install-terraform.sh
  install-ansible.sh
  install-bash.sh
  install-universal.sh
lib/
  log.sh
  platform.sh
tests/
  test-python.sh
  test-terraform.sh
```

**Template repos (`github-repo-template`, `gitlab-repo-template`):**
```
Makefile
.devrail.yml
.editorconfig
.gitignore
.pre-commit-config.yaml
DEVELOPMENT.md
CLAUDE.md
AGENTS.md
.cursorrules
.opencode/
  agents.yaml
.github/ or .gitlab/
  PULL_REQUEST_TEMPLATE.md or merge_request_templates/
  CODEOWNERS
  workflows/ or .gitlab-ci.yml
```

**Standards repo (`devrail-standards`):**
```
DEVELOPMENT.md
standards/
  python.md
  bash.md
  terraform.md
  ansible.md
  universal.md
```

**Rules:**
- `scripts/` for executables, `lib/` for sourced libraries — never mixed
- `tests/` at repo root — always
- Config files at repo root — no nested config directories
- No `src/` in infrastructure repos

### Output & Logging Conventions

**Makefile Target Output:**
- Each target: JSON summary with `target`, `status`, `duration_ms`, and `errors` array on failure
- `make check`: final summary of all targets with pass/fail and total duration
- Human mode: simple table with status indicators

**Exit Codes:**
- `0` — pass
- `1` — failure (lint errors, test failures, security findings)
- `2` — misconfiguration (missing `.devrail.yml`, unknown language, container pull failure)

**CI Output:**
- Job names match target names: `lint`, `format`, `security`, `test`, `docs`
- Each job writes JSON output to artifact file
- Exit codes propagated — no swallowed failures

**Pre-commit:**
- Human format by default — respects framework conventions
- CI overrides to JSON when needed

### Documentation Patterns

**README structure (every repo):**
- Title + one-line description → Badges → Quick start (3 steps max) → Usage (`make help` output) → Configuration → Contributing (link to DEVELOPMENT.md) → License

**Code comments:**
- Comments explain *why*, not *what* — no over-commenting obvious code
- No commented-out code — delete it, git has history
- TODO format: `# TODO(devrail#123): description` — linked to issues

**Commit messages (conventional commits):**
- Format: `type(scope): description`
- Types: `feat`, `fix`, `docs`, `chore`, `ci`, `refactor`, `test`
- Scopes: `python`, `terraform`, `bash`, `ansible`, `container`, `ci`, `makefile`

**Changelog:**
- Auto-generated from conventional commits
- CHANGELOG.md per repo, Keep a Changelog format

### Enforcement Guidelines

**All AI Agents MUST:**
- Run `make check` before completing any story or task
- Follow conventional commits for all commits
- Write idempotent scripts — check before acting
- Use shared logging library — no raw `echo`
- Respect `.editorconfig` and existing formatting
- Never install tools outside the container

**Pattern Enforcement:**
- Pre-commit hooks enforce locally (format, lint, conventional commits, gitleaks)
- CI enforces the full suite (security, tests, docs)
- Agents self-enforce via instruction files (CLAUDE.md, AGENTS.md, .cursorrules, .opencode/)

## Project Structure & Boundaries

### FR Category → Repo Mapping

| FR Category | Primary Repo | Supporting Repos |
|---|---|---|
| Standards & Config (FR1-4) | devrail-standards | templates (consume) |
| Dev-Toolchain Container (FR5-9) | dev-toolchain | — |
| Makefile Contract (FR10-17) | templates (github + gitlab) | dev-toolchain (internal targets) |
| Project Templates (FR18-24) | github-repo-template, gitlab-repo-template | devrail-standards (source) |
| Pre-Commit Enforcement (FR25-29) | pre-commit-conventional-commits | templates (configure) |
| CI/CD Pipeline (FR30-33) | github-repo-template, gitlab-repo-template | dev-toolchain (image) |
| AI Agent Integration (FR34-38) | devrail-standards (canonical), templates (shims) | — |
| Documentation Site (FR39-41) | devrail.dev | all repos (content source) |
| Contributor Experience (FR42-44) | all repos | devrail-standards (defines rules) |

### Complete Per-Repo Directory Structures

**1. `devrail-standards`** — canonical source of truth
```
devrail-standards/
├── .devrail.yml
├── .editorconfig
├── .gitignore
├── .pre-commit-config.yaml
├── CHANGELOG.md
├── DEVELOPMENT.md
├── LICENSE
├── Makefile
├── README.md
├── CLAUDE.md
├── AGENTS.md
├── .cursorrules
├── .opencode/
│   └── agents.yaml
└── standards/
    ├── python.md
    ├── bash.md
    ├── terraform.md
    ├── ansible.md
    ├── universal.md
    ├── makefile-contract.md
    ├── agent-instructions.md
    └── devrail-yml-schema.md
```

**2. `dev-toolchain`** — the container image
```
dev-toolchain/
├── .devrail.yml
├── .editorconfig
├── .gitignore
├── .pre-commit-config.yaml
├── .github/
│   ├── CODEOWNERS
│   └── workflows/
│       ├── build.yml
│       ├── release.yml
│       └── ci.yml
├── CHANGELOG.md
├── DEVELOPMENT.md
├── Dockerfile
├── LICENSE
├── Makefile
├── README.md
├── CLAUDE.md
├── AGENTS.md
├── .cursorrules
├── .opencode/
│   └── agents.yaml
├── scripts/
│   ├── install-python.sh
│   ├── install-terraform.sh
│   ├── install-ansible.sh
│   ├── install-bash.sh
│   └── install-universal.sh
├── lib/
│   ├── log.sh
│   └── platform.sh
└── tests/
    ├── test-python.sh
    ├── test-terraform.sh
    ├── test-ansible.sh
    ├── test-bash.sh
    └── test-universal.sh
```

**3. `github-repo-template`**
```
github-repo-template/
├── .devrail.yml
├── .editorconfig
├── .gitignore
├── .pre-commit-config.yaml
├── .github/
│   ├── CODEOWNERS
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── workflows/
│       ├── lint.yml
│       ├── format.yml
│       ├── security.yml
│       ├── test.yml
│       └── docs.yml
├── CHANGELOG.md
├── DEVELOPMENT.md
├── LICENSE
├── Makefile
├── README.md
├── CLAUDE.md
├── AGENTS.md
├── .cursorrules
└── .opencode/
    └── agents.yaml
```

**4. `gitlab-repo-template`** — functionally identical, platform-specific CI
```
gitlab-repo-template/
├── .devrail.yml
├── .editorconfig
├── .gitignore
├── .pre-commit-config.yaml
├── .gitlab/
│   ├── CODEOWNERS
│   └── merge_request_templates/
│       └── default.md
├── .gitlab-ci.yml
├── CHANGELOG.md
├── DEVELOPMENT.md
├── LICENSE
├── Makefile
├── README.md
├── CLAUDE.md
├── AGENTS.md
├── .cursorrules
└── .opencode/
    └── agents.yaml
```

**5. `pre-commit-conventional-commits`** — existing repo
```
pre-commit-conventional-commits/
├── .devrail.yml
├── .editorconfig
├── .gitignore
├── .pre-commit-config.yaml
├── .pre-commit-hooks.yaml
├── CHANGELOG.md
├── DEVELOPMENT.md
├── LICENSE
├── Makefile
├── README.md
├── conventional_commits/
│   ├── __init__.py
│   ├── check.py
│   └── config.py
└── tests/
    ├── __init__.py
    ├── test_check.py
    └── test_config.py
```

**6. `devrail.dev`** — Hugo documentation site
```
devrail.dev/
├── .devrail.yml
├── .editorconfig
├── .gitignore
├── .pre-commit-config.yaml
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── deploy.yml
├── CHANGELOG.md
├── DEVELOPMENT.md
├── LICENSE
├── Makefile
├── README.md
├── hugo.toml
├── go.mod
├── go.sum
├── content/
│   ├── _index.md
│   ├── docs/
│   │   ├── getting-started/
│   │   ├── standards/
│   │   ├── container/
│   │   ├── templates/
│   │   └── contributing/
│   └── blog/
├── layouts/
│   └── partials/
├── static/
│   └── images/
└── assets/
    └── scss/
```

### Integration Boundaries

**Ecosystem Data Flow:**
```
devrail-standards (canonical rules)
        │
        ├──→ dev-toolchain (tools that enforce rules)
        │           │
        │           ├──→ github-repo-template (Makefile delegates to container)
        │           │           │
        │           │           └──→ CI workflows call make targets
        │           │
        │           └──→ gitlab-repo-template (Makefile delegates to container)
        │                       │
        │                       └──→ .gitlab-ci.yml calls make targets
        │
        ├──→ pre-commit-conventional-commits (hook enforces commit format)
        │
        └──→ devrail.dev (publishes standards as docs)
```

**Contract Interfaces:**

| Interface | Producer | Consumer | Contract |
|---|---|---|---|
| Container image | dev-toolchain | templates (via Makefile) | `ghcr.io/devrail-dev/dev-toolchain:v1` with all tools installed |
| Makefile targets | templates | CI pipelines, agents, developers | `make lint/format/test/security/docs/check` |
| `.devrail.yml` | developer/agent | Makefile, CI | Language declarations, project settings |
| Pre-commit hook | pre-commit-conventional-commits | templates (via `.pre-commit-config.yaml`) | Conventional commit validation |
| Agent instructions | DEVELOPMENT.md + shims | AI agents | Critical rules + pointer to full standards |
| Standards docs | devrail-standards | devrail.dev, templates | Canonical rules per language |

**Boundary Rules:**
- Repos never import code from each other — integration is via container image, config files, and documentation
- The container image is the only shared runtime dependency
- Standards flow one direction: devrail-standards → everything else
- Each repo is independently buildable and testable

## Architecture Validation Results

### Coherence Validation ✅

**Decision Compatibility:** All 8 architectural decisions validated for mutual compatibility. No contradictions found. Decisions reinforce each other — the container provides tools, Makefiles provide the contract, templates provide the scaffolding, agent files provide the instructions, CI provides enforcement.

**Pattern Consistency:** Naming conventions (`snake_case` universal), output formats (JSON default), exit codes (0/1/2), and directory structures are consistent across all six repos.

**Structure Alignment:** Per-repo directory trees support all architectural decisions. Integration boundaries are clean — repos interact only through container images, config files, and documentation.

### Requirements Coverage ✅

**Functional Requirements:** All 44 FRs across 9 capability areas have explicit architectural support. Each FR category maps to one or more repos with clear ownership.

**Non-Functional Requirements:** All performance budgets (< 5 min full suite, < 30 sec hooks, < 60 sec targets), security requirements (trivy, gitleaks, trusted base), compatibility targets (multi-arch, macOS + Linux), and integration requirements (GHCR, GitHub Actions, GitLab CI, pre-commit) are architecturally addressed.

### Implementation Readiness ✅

**Decision Completeness:** All critical and important decisions documented with rationale. Technology choices specified per repo. Deferred decisions explicitly listed with rationale.

**Structure Completeness:** Complete directory trees for all 6 repos. Every file has a purpose. Integration points mapped via contract interface table.

**Pattern Completeness:** 6 pattern categories covering shell scripts, Makefiles, configuration, directory organization, output conventions, and documentation. Enforcement guidelines defined for agents, pre-commit, and CI.

### Gap Analysis

**No Critical Gaps.**

**Important (address during implementation):**
- `.devrail.yml` complete schema specification — first implementation deliverable
- Template cross-platform equivalence testing — CI concern during template implementation

**Deferred to Post-MVP:**
- Automated shim generation from DEVELOPMENT.md markers
- Renovate/Dependabot automation for container version bumps
- CI performance optimization

### Architecture Completeness Checklist

**✅ Requirements Analysis**
- [x] Project context analyzed (6 repos, 4 languages, 2 CI platforms)
- [x] Scale and complexity assessed (medium)
- [x] Technical constraints identified (5 constraints)
- [x] Cross-cutting concerns mapped (4 concerns)

**✅ Architectural Decisions**
- [x] 8 decisions documented with rationale
- [x] Technology stack fully specified per repo
- [x] Integration patterns defined (contract interface table)
- [x] Performance considerations addressed (budgets, caching, local/CI split)

**✅ Implementation Patterns**
- [x] Shell script conventions (idempotency, logging, error handling, helpers)
- [x] Makefile authoring patterns (naming, structure, documentation)
- [x] Configuration file formats (YAML, markers, EditorConfig)
- [x] File & directory organization (complete per-repo trees)
- [x] Output & logging conventions (JSON default, exit codes)
- [x] Documentation patterns (README, comments, commits, changelog)

**✅ Project Structure**
- [x] Complete directory structures for all 6 repos
- [x] FR categories mapped to repos
- [x] Integration boundaries and data flow documented
- [x] Contract interfaces defined

### Architecture Readiness Assessment

**Overall Status:** READY FOR IMPLEMENTATION

**Confidence Level:** High

**Key Strengths:**
- Clear separation of concerns across 6 repos with no code coupling
- Universal execution contract (Makefile → Docker) eliminates environment inconsistency
- Agent-first design with hybrid shim strategy covers multiple AI backends
- Dogfooding requirement ensures the ecosystem validates itself

**First Implementation Priority:**
1. Define `.devrail.yml` schema in devrail-standards
2. Build dev-toolchain container with install scripts
3. Implement Makefile contract in templates
4. Write DEVELOPMENT.md + agent shim files
5. Configure pre-commit hooks
6. Build CI pipeline configurations
