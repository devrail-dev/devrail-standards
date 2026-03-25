# Story 13.1: Design Plugin Architecture for Community Extensions

Status: ready-for-dev

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

- [ ] Task 1: Research extension patterns in comparable tools (AC: 1, 5)
  - [ ] 1.1 Analyze how **pre-commit** handles third-party hooks: repo-based discovery, hook manifest (`hooks.yaml`), isolation model, version pinning
  - [ ] 1.2 Analyze how **ESLint** handles plugins: npm package convention (`eslint-plugin-*`), rule registration, shared configs, flat config composition
  - [ ] 1.3 Analyze how **Terraform providers** handle plugins: registry-based discovery, versioned binaries, provider manifest, required_providers block
  - [ ] 1.4 Analyze how **GitHub Actions** handle reusable components: `action.yml` manifest, composite actions, marketplace distribution
  - [ ] 1.5 Summarize patterns: discovery mechanisms, manifest formats, isolation strategies, version management, backwards compatibility approaches

- [ ] Task 2: Identify extension points in current DevRail architecture (AC: 1, 4, 5)
  - [ ] 2.1 Map Makefile extension points: how `_lint`, `_format`, `_test`, `_security`, `_fix` iterate over languages; where a plugin could register a new language block
  - [ ] 2.2 Map Dockerfile extension points: how tools are installed; options for extending (multi-stage COPY, sidecar containers, volume mounts, runtime install)
  - [ ] 2.3 Map `.devrail.yml` extension points: how the schema could accept plugin-defined languages; per-language override mechanism
  - [ ] 2.4 Map pre-commit extension points: how `.pre-commit-config.yaml` includes external repos; how plugins could register hooks
  - [ ] 2.5 Map CI pipeline extension points: how GitHub Actions/GitLab CI could include plugin-defined jobs
  - [ ] 2.6 Map `devrail init` extension points: how the init script could discover and scaffold plugin config

- [ ] Task 3: Design the plugin interface (AC: 1, 2, 3, 4)
  - [ ] 3.1 Define **plugin manifest format** (`plugin.devrail.yml` or similar) specifying: language name, tool binaries, Makefile target commands, pre-commit hooks, config file templates, gating conditions
  - [ ] 3.2 Define **Makefile integration pattern**: how plugins register language blocks in `_lint`/`_format`/`_test`/`_security` without modifying the core Makefile (options: include files, dynamic target generation, plugin directory scanning)
  - [ ] 3.3 Define **container integration pattern**: how plugins add tools to the image (options: extending base image, sidecar container, volume-mounted binaries, runtime install via plugin script)
  - [ ] 3.4 Define **`.devrail.yml` extension mechanism**: how `languages:` accepts plugin-defined entries; how per-language overrides work for plugin languages
  - [ ] 3.5 Define **`make check` aggregation**: how plugin check results are collected and included in the composite pass/fail decision
  - [ ] 3.6 Define **plugin versioning and distribution**: how plugins are versioned, discovered, and installed (options: git repos, registry, directory convention)

- [ ] Task 4: Evaluate container integration strategies (AC: 5)
  - [ ] 4.1 **Option A: Extended image** -- Dockerfile `FROM ghcr.io/devrail-dev/dev-toolchain:v1` + plugin install. Pros: simple, single container. Cons: rebuild per-project, no standard distribution.
  - [ ] 4.2 **Option B: Sidecar containers** -- Plugin tools run in separate containers alongside dev-toolchain. Pros: isolation, independent versioning. Cons: complex orchestration, shared filesystem issues.
  - [ ] 4.3 **Option C: Volume-mounted plugins** -- Plugin binaries mounted into dev-toolchain container at runtime. Pros: no image rebuild. Cons: host dependency, platform compatibility.
  - [ ] 4.4 **Option D: Runtime install** -- `make check` runs plugin install script inside container before execution. Pros: zero build step. Cons: slow first run, network dependency.
  - [ ] 4.5 **Recommendation**: Evaluate each against DevRail's core constraints (single container, reproducible, CI-compatible, fast) and recommend the winning approach with rationale

- [ ] Task 5: Write the design document (AC: 6, 7)
  - [ ] 5.1 Create `_bmad-output/planning-artifacts/plugin-architecture-design.md`
  - [ ] 5.2 Include sections: Overview, Extension Points, Plugin Manifest, Makefile Integration, Container Integration, Distribution & Versioning, Example Walkthrough, Migration Path, Open Questions
  - [ ] 5.3 Include architecture diagrams (ASCII or mermaid) showing plugin discovery and execution flow
  - [ ] 5.4 Include complete example: a hypothetical "Elixir plugin" showing manifest, Makefile snippet, Dockerfile extension, and `.devrail.yml` usage
  - [ ] 5.5 Include migration path from current monolithic approach to plugin-capable architecture (backwards compatible)
  - [ ] 5.6 Document trade-offs and rationale for each design decision

- [ ] Task 6: Review and finalize (AC: 7)
  - [ ] 6.1 Self-review against acceptance criteria
  - [ ] 6.2 Verify design preserves all current DevRail guarantees (make check gates everything, container is authoritative, conventional commits enforced)
  - [ ] 6.3 Mark story as review

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

### File List
