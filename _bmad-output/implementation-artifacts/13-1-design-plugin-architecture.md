# Story 13.1: Design Plugin Architecture for Community Extensions

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a community contributor,
I want a clear plugin architecture for extending DevRail with custom tools and languages,
so that I can contribute language support or tool integrations without modifying core repos.

## Acceptance Criteria

1. **Given** the design document, **Then** it specifies extension points (where plugins hook in), interfaces (what plugins must provide), and lifecycle (how plugins are discovered, loaded, and executed)
2. **Given** the design, **When** a contributor wants to add a custom language ecosystem, **Then** the design describes how to create a plugin that adds linter/formatter/test/security targets without forking dev-toolchain
3. **Given** the design, **When** a contributor wants to add a custom linter or formatter for an existing language, **Then** the design describes how to override or augment default tools
4. **Given** the design, **Then** `make check` still aggregates all checks (core + plugin) and gates on all results
5. **Given** the design, **Then** it is compatible with the existing container-based toolchain approach (plugins work with or alongside the dev-toolchain container)
6. **Given** the design document, **Then** it includes an example plugin walkthrough showing a complete custom language plugin from creation to integration
7. **Given** the design document is reviewed, **Then** it is accepted and merged to `_bmad-output/planning-artifacts/`

## Tasks / Subtasks

- [x] Task 1: Research extension patterns in comparable tools (AC: 1, 5)
  - [x] 1.1 Analyze how **pre-commit** handles third-party hooks
  - [x] 1.2 Analyze how **ESLint** handles plugins
  - [x] 1.3 Analyze how **Terraform providers** handle plugins
  - [x] 1.4 Analyze how **GitHub Actions** handle reusable components
  - [x] 1.5 Summarize patterns into a comparison table

- [x] Task 2: Identify extension points in current DevRail architecture (AC: 1, 4, 5)
  - [x] 2.1 Map Makefile extension points (`HAS_<LANG>` blocks across `_lint`/`_format`/`_fix`/`_test`/`_security`/`_init`)
  - [x] 2.2 Map Dockerfile extension points (multi-stage `<lang>-builder`, runtime APT, install scripts)
  - [x] 2.3 Map `.devrail.yml` extension points (`languages:` list + per-language overrides + new `plugins:` section)
  - [x] 2.4 Map pre-commit extension points (per-language hook entries in templates)
  - [x] 2.5 Map CI pipeline extension points (per-language extras like Rails Postgres rspec job)
  - [x] 2.6 Map `devrail init` extension points (`ALL_LANGUAGES` constant, scaffolding via `_init`)

- [x] Task 3: Design the plugin interface (AC: 1, 2, 3, 4)
  - [x] 3.1 Define **plugin manifest format** (`plugin.devrail.yml`) — schema_version, name, version, devrail_min_version, container, targets, gates, pre_commit, init_scaffolds, tool_versions
  - [x] 3.2 Define **Makefile integration pattern** — embedded execution loop in core Makefile that iterates plugin manifests
  - [x] 3.3 Define **container integration pattern** — extended-image with auto-generated `Dockerfile.devrail`
  - [x] 3.4 Define **`.devrail.yml` extension mechanism** — `plugins:` section with `source`/`rev`/`languages` + lockfile
  - [x] 3.5 Define **`make check` aggregation** — plugin results enter existing `ran_languages` / `failed_languages` / JSON summary path
  - [x] 3.6 Define **plugin versioning and distribution** — git-only v1, source-address triple, immutable refs, lockfile

- [x] Task 4: Evaluate container integration strategies (AC: 5)
  - [x] 4.1 **Option A: Extended image** — evaluated
  - [x] 4.2 **Option B: Sidecar containers** — evaluated
  - [x] 4.3 **Option C: Volume-mounted plugins** — evaluated
  - [x] 4.4 **Option D: Runtime install** — evaluated
  - [x] 4.5 **Recommendation: Option A (Extended image)** — rationale documented

- [x] Task 5: Write the design document (AC: 6, 7)
  - [x] 5.1 Created `_bmad-output/planning-artifacts/plugin-architecture-design.md`
  - [x] 5.2 All required sections included (Overview, Research Summary, Extension Surface, Plugin Manifest, Project Configuration, Plugin Lifecycle, Make-Check Aggregation, Per-Language Tool Override, Container Integration, Distribution & Versioning, Security Model, Example Walkthrough, Migration Path, Open Questions)
  - [x] 5.3 ASCII architecture diagram included for plugin lifecycle
  - [x] 5.4 Complete Elixir plugin example walkthrough (manifest, install script, consumer adoption, first run, override, upgrade)
  - [x] 5.5 Three-phase migration path from monolith to plugin-first (`v1.10.0` → `v1.11.0` → `v2.0.0`)
  - [x] 5.6 Trade-offs documented for each container option, manifest field, and versioning axis

- [x] Task 6: Review and finalize (AC: 7)
  - [x] 6.1 Self-review against all 7 acceptance criteria — see Completion Notes
  - [x] 6.2 Design preserves DevRail guarantees: `make check` is the single gate, container is authoritative, immutable refs, JSON summary unchanged
  - [x] 6.3 Story marked as review

## Dev Notes

**This is a DESIGN-ONLY story -- no code implementation.** The output is a design document that will inform future implementation stories.

### Architecture Context

**Current architecture is monolithic:**
- All tools live in one container (`ghcr.io/devrail-dev/dev-toolchain:v1`)
- Makefile has hardcoded language blocks (`HAS_PYTHON`, `HAS_GO`, etc.)
- Adding a language requires PRs to 5 repos (dev-toolchain, standards, 2 templates, devrail.dev)
- This works well for core languages but doesn't scale for community contributions

**Key tension: Simplicity vs Extensibility**
- The monolithic approach is DevRail's strength: one container, one Makefile, one `make check`
- Plugins must not sacrifice this simplicity -- `make check` must still be the single gate
- Community contributors should be able to add languages without waiting for core team review cycles

**Constraints from architecture.md:**
- Dev-toolchain container must be the single source of all tool versions
- Makefile targets must produce identical output regardless of invocation context
- Container must support both amd64 and arm64
- Performance: `make check` < 5 min, pre-commit hooks < 30 sec

### Research Starting Points

- **pre-commit framework**: Best-in-class repo-based plugin model. Each hook repo defines `hooks.yaml` with entry points. Version pinned per-project. Excellent isolation.
- **ESLint plugins**: npm ecosystem. `eslint-plugin-*` naming convention. Flat config allows composing multiple plugins. No isolation -- shares Node.js runtime.
- **Terraform providers**: Registry-based. Binary protocol. `required_providers` block with version constraints. Strong isolation (separate binaries).
- **GitHub Actions**: `action.yml` manifest. Composite actions for reusable logic. Marketplace for discovery. Container actions for isolation.

### Possible Plugin Manifest (strawman)

```yaml
# plugin.devrail.yml
name: elixir
version: 1.0.0
description: "Elixir language support for DevRail"

tools:
  linter: credo
  formatter: mix format
  test: mix test
  security: mix_audit

container:
  base: "elixir:1.17-slim"
  install: "scripts/install-elixir.sh"

makefile:
  lint: "mix credo --strict"
  format_check: "mix format --check-formatted"
  format_fix: "mix format"
  test: "mix test"
  security: "mix_audit"

gate_files:
  test: "mix.exs"
  security: "mix.lock"

pre_commit:
  - repo: https://github.com/user/elixir-pre-commit
    hooks: [credo, mix-format]
```

### Project Structure Notes

- Design document goes in `_bmad-output/planning-artifacts/plugin-architecture-design.md`
- No code changes to any repo in this story
- Implementation stories will be created after design acceptance (Epic 13 continuation)

### References

- [Source: _bmad-output/planning-artifacts/architecture.md] -- current system architecture
- [Source: _bmad-output/planning-artifacts/prd.md] -- Phase 3: "Plugin architecture, community contributions"
- [Source: standards/contributing.md] -- current contribution model for new languages
- [Source: standards/makefile-contract.md] -- Makefile behavioral contract that plugins must respect
- [Source: dev-toolchain/Dockerfile] -- current container build structure
- [Source: dev-toolchain/Makefile] -- current language detection and target pattern

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6

### Debug Log References

- Analyzed architecture.md for system constraints
- Reviewed contributing.md for current language addition pattern
- Identified 4 comparable plugin systems for research (pre-commit, ESLint, Terraform, GitHub Actions)
- Compiled container integration strategy options

### Completion Notes List

- Story enhanced from skeleton to comprehensive design story with research tasks, evaluation criteria, and strawman manifest
- 6 tasks decomposed into 26 subtasks with AC traceability
- Container integration strategies documented as 4 options to evaluate
- Research sources identified for each comparable tool
- Plugin manifest strawman provides concrete starting point for design discussions

**Story 13.1 design output (2026-04-27):**

- Design document created: `_bmad-output/planning-artifacts/plugin-architecture-design.md`
- All 7 acceptance criteria addressed:
  - **AC1** (extension points, interfaces, lifecycle) — covered in *Plugin Lifecycle*, *Plugin Manifest*, and *Current DevRail Extension Surface*
  - **AC2** (custom language without forking dev-toolchain) — covered end-to-end in *Example Walkthrough — An Elixir Plugin*
  - **AC3** (override default tools) — covered in *Per-Language Tool Override*
  - **AC4** (`make check` still aggregates) — covered in *Make-Check Aggregation* (plugin results join existing `ran_languages`/`failed_languages`/JSON summary)
  - **AC5** (compatible with container toolchain) — covered in *Container Integration* with four strategies evaluated; Option A (extended image) recommended
  - **AC6** (example walkthrough) — covered in *Example Walkthrough — An Elixir Plugin* (5 steps from authoring to upgrade)
  - **AC7** (design merged to planning-artifacts) — file lives in `_bmad-output/planning-artifacts/plugin-architecture-design.md`; story moved to `review` status pending acceptance
- Research sources used: pre-commit, ESLint plugins, Terraform providers, GitHub Actions custom actions
- Key design decisions:
  - Plugin distribution: git repos with source-address triple (`host/namespace/name`), immutable `rev:` refs, content-hashed lockfile
  - Container integration: extended image (`FROM ghcr.io/devrail-dev/dev-toolchain:v1` + plugin layers) — preserves "one container, one make check"
  - Manifest: single `plugin.devrail.yml` with `schema_version: 1`, `devrail_min_version`, `targets`, `gates`, `container`, `pre_commit`, `init_scaffolds`, `tool_versions`
  - Migration: three-phase rollout (`v1.10.0` adds loader, `v1.11.0` extracts Kotlin as reference plugin, `v2.0.0` removes monolithic `HAS_<LANG>` blocks)
- Open questions explicitly enumerated for follow-up stories (registry, signing, parallel execution, plugin-to-plugin deps, standards-doc auto-generation, CI services, devrail-init integration)
- No code changes in this story; implementation stories will follow from the migration phasing

### File List

- `_bmad-output/planning-artifacts/plugin-architecture-design.md` — created
- `_bmad-output/implementation-artifacts/13-1-design-plugin-architecture.md` — updated (status, task checkboxes, completion notes)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — updated (`13-1` → `review`)
