# Story 13.7: Extract Kotlin as Reference Plugin

Status: ready-for-dev

## Story

As a maintainer,
I want Kotlin moved out of the dev-toolchain image into a separate `devrail-plugin-kotlin` repo and documented as the reference extraction recipe,
so that the plugin model is proven against a real language ecosystem and other languages can follow the same path.

## Acceptance Criteria

1. **Given** a new `github.com/devrail-dev/devrail-plugin-kotlin` repository,
   **When** it is published with a v1.0.0 tag,
   **Then** it contains a valid `plugin.devrail.yml` (schema_version 1) declaring `name: kotlin`, `devrail_min_version: 1.10.0`, container fragment (JDK 21 builder, ktlint / detekt / gradle install_script), and targets matching the existing dev-toolchain Kotlin behaviour (`lint`, `format_check`, `format_fix`, `test`, `security`) with their existing gates.

2. **Given** a consumer workspace that declares the plugin in `.devrail.yml` and lists kotlin only in `plugins:` (NOT in `languages:` to avoid the core-vs-plugin precedence rule),
   **When** `make check` runs,
   **Then** the extended-image build produces a working Kotlin tooling stack identical in behaviour to the in-core version (same ktlint/detekt/gradle versions, same gate logic, same JSON event shape).

3. **Given** the plugin repo follows the contributor checklist from Story 13.6's `standards/contributing.md` § "Contributing a Plugin",
   **When** a maintainer reviews the repo,
   **Then** every checklist item is satisfied (manifest fields, `install.sh` idempotent and using `set -euo pipefail`, README documents the language, semver tag, etc.).

4. **Given** a contributor wants to extract another core language as a plugin,
   **When** they read `OrgDocs/standards/contributing.md`,
   **Then** they find a new "Extracting a core language as a plugin" subsection (under "Contributing a Plugin") that documents the step-by-step recipe used for Kotlin: identify Dockerfile bits, identify Makefile blocks, write the manifest, port the install script, port the test fixture, validate with a `file://` workspace, publish.

5. **Given** the dev-toolchain image still ships Kotlin in core for v1.11.x,
   **When** v1.11.0 is cut,
   **Then** existing consumers with `languages: [kotlin]` see ZERO behavioural change — the plugin extraction is **additive in v1.11**; the actual removal is gated to v2.0.0 (Story 13.9). This story does NOT touch the dev-toolchain Kotlin Dockerfile / Makefile blocks.

6. **Given** v1.11.0 carries the extraction recipe + new plugin repo,
   **When** the release lands,
   **Then** CHANGELOG, STABILITY, devrail.dev blog, and the standards docs all reflect the reference plugin's existence and link to the new repo.

7. **Given** the new plugin repo lives outside of OrgDocs,
   **When** it is set up,
   **Then** it follows the existing DevRail-managed repo standards (`make check` works against its own contents — bash idempotency, conventional commits, CI workflow that validates the manifest + test the install script).

## Tasks / Subtasks

- [ ] **Task 1: Create `devrail-plugin-kotlin` repo** (AC: 1, 7)
  - [ ] Subtask 1.1: `gh repo create devrail-dev/devrail-plugin-kotlin --public --description "DevRail plugin: Kotlin language ecosystem (ktlint, detekt, Gradle, JDK 21)"` (or via UI). MIT licence.
  - [ ] Subtask 1.2: Initialize with `plugin.devrail.yml` (schema_version 1, name: kotlin, version: 1.0.0, devrail_min_version: 1.10.0).
  - [ ] Subtask 1.3: Container fragment: `base_image: eclipse-temurin:21-jdk` (mirroring dev-toolchain's `jdk-builder`), `copy_from_builder: [/opt/java/openjdk]`, `env: { JAVA_HOME: /opt/java/openjdk, PATH: ... }`, `apt_packages: []` (the install script handles ktlint/detekt/gradle).
  - [ ] Subtask 1.4: Port `dev-toolchain/scripts/install-kotlin.sh` to `devrail-plugin-kotlin/install.sh`. Self-contained (no `lib/log.sh` dependency from dev-toolchain — replace `log_info` calls with `printf` since plugin install scripts run during docker build, not in the lib-instrumented runtime). Idempotent. Set `set -euo pipefail`.
  - [ ] Subtask 1.5: Port targets from dev-toolchain Makefile lines 551-560, 730-740, 884-895, 1009-1019, 1230-1245 (lint / format_check / format_fix / test / security) into `targets:` block. Carry the gate paths (`build.gradle.kts`, `*.kt`/`*.kts` glob, etc.).
  - [ ] Subtask 1.6: Add a project README documenting: what's included (ktlint, detekt, gradle, JDK 21), how to declare in `.devrail.yml`, supported `devrail_min_version`, link to extraction-recipe doc.
  - [ ] Subtask 1.7: Adopt DevRail standards in the new repo via `bash <(curl -s https://devrail.dev/init.sh)` (or equivalent). `make check` on the new repo passes.
  - [ ] Subtask 1.8: Annotated tag `v1.0.0`, push.

- [ ] **Task 2: End-to-end validation** (AC: 2, 3)
  - [ ] Subtask 2.1: Create a hermetic test workspace under `dev-toolchain/tests/fixtures/kotlin-via-plugin/` that declares the kotlin plugin via `file://` URL pointing at a checked-out `devrail-plugin-kotlin` working copy.
  - [ ] Subtask 2.2: New smoke test `dev-toolchain/tests/test-kotlin-plugin-extraction.sh` — runs `make plugins-update + make check` against the fixture, asserts the same JSON shape and behaviour as `tests/test-kotlin.sh` on a kotlin-in-core workspace.
  - [ ] Subtask 2.3: Verify the plugin repo's own `make check` passes.

- [ ] **Task 3: Standards docs — Extraction recipe** (AC: 4)
  - [ ] Subtask 3.1: Add an "Extracting a core language as a plugin" subsection to `OrgDocs/standards/contributing.md` under "Contributing a Plugin", documenting the Kotlin extraction step-by-step: how to identify Dockerfile bits to migrate, how to map Makefile language blocks → manifest targets, install-script porting (no lib/log.sh deps), gate-path translation, fixture-based testing, publish.
  - [ ] Subtask 3.2: Reference Story 13.7 + the kotlin plugin repo as the canonical example.
  - [ ] Subtask 3.3: Mirror to `devrail.dev/content/docs/contributing/adding-a-plugin.md` (or sibling page).

- [ ] **Task 4: dev-toolchain release prep** (AC: 5, 6)
  - [ ] Subtask 4.1: Update dev-toolchain CHANGELOG `[Unreleased]` § Added with a note about the reference plugin (no code change in dev-toolchain itself). Verify v1.10.x kotlin behaviour unchanged.
  - [ ] Subtask 4.2: Update `STABILITY.md` to note the reference plugin's existence and the back-compat guarantee through v1.11.x.
  - [ ] Subtask 4.3: NOTE: kotlin removal from the dev-toolchain Dockerfile/Makefile is OUT OF SCOPE for 13.7 — that's Story 13.9 (v2.0.0).

- [ ] **Task 5: Cut v1.11.0** (AC: 6)
  - [ ] Subtask 5.1: `make release VERSION=1.11.0` on dev-toolchain.
  - [ ] Subtask 5.2: Verify the floating `:v1` tag advances.

- [ ] **Task 6: devrail.dev blog post** (AC: 6)
  - [ ] Subtask 6.1: `content/blog/2026-MM-DD-kotlin-as-reference-plugin.md` — what the extraction looks like, what's in the new repo, how this proves the plugin model, what comes next (v2.0.0 retirement of monolithic blocks).
  - [ ] Subtask 6.2: Link to the new `devrail-plugin-kotlin` repo and the extraction-recipe doc.

- [ ] **Task 7: Sprint close** (AC: process)
  - [ ] Subtask 7.1: Story status → review after PR opens; → done after merge.
  - [ ] Subtask 7.2: Sprint-status `13-7-... → done`. Mark Story 13.8 (v1.11.0 release) ready for follow-up — note: Story 13.8 is largely satisfied by Task 5 here; it may be retroactively marked done.

## Dev Notes

### Authoritative source

- [Source: `_bmad-output/planning-artifacts/epics.md` § "Story 13.7"] — original placeholder.
- [Source: `_bmad-output/planning-artifacts/plugin-architecture-design.md` § "Container Integration" Option A] — extended-image execution model the plugin must satisfy.
- [Source: `dev-toolchain/Makefile` HAS_KOTLIN blocks] — the canonical behaviour the plugin must reproduce.
- [Source: `dev-toolchain/scripts/install-kotlin.sh`] — install logic to port.
- [Source: `dev-toolchain/Dockerfile` `jdk-builder` stage + JDK COPY + PATH] — container bits the plugin manifest must replace.

### Scope boundary

**In scope:**
- New `github.com/devrail-dev/devrail-plugin-kotlin` repository (manifest, install script, README, CI, v1.0.0 tag)
- Extraction-recipe documentation (OrgDocs + devrail.dev mirror)
- v1.11.0 release with blog post
- End-to-end test against a hermetic fixture using `file://` URL

**Out of scope (gated to Story 13.9, v2.0.0):**
- Removing kotlin from dev-toolchain Dockerfile/Makefile
- `devrail-init migrate --to v2`
- Loader changes to allow plugin-overrides-core for languages already in core (current rule: "core wins" — design doc § "Resolution rules")
- Other languages' extractions (Swift, Ruby, etc.) — they follow the same recipe but are separate stories

### Why Kotlin and not another language

Per the original design doc, Kotlin was chosen because (a) it is the most recently added core language (March 2026), so the install logic is freshest in maintainers' minds; (b) its install script is JVM-pulled-binary heavy (ktlint, detekt, gradle each downloaded) — a worst-case for plugin authors and a good stress test of the model; (c) the JDK 21 dependency exercises the `copy_from_builder` pattern non-trivially.

### Loader precedence rule + workaround for testing

The loader's resolution rule (design doc § "Project Configuration"): "For each entry in `languages:`, the loader checks core compiled-in languages first, then plugins." A consumer that lists `kotlin` in `languages:` will hit the in-core block; the plugin in `plugins:` will not be invoked.

For end-to-end validation in this story, the test workspace MUST NOT list kotlin in `languages:`. It declares the plugin in `plugins:` only, and the plugin's `languages: [kotlin]` field handles dispatch. Plugin-supplied languages still get a place in the JSON event (via the dispatcher) without going through the core HAS_<LANG> path.

This works during v1.11.x because consumers have a choice (core OR plugin). v2.0.0 removes the core path entirely (Story 13.9).

### Container fragment specifics

The dev-toolchain Dockerfile uses a multi-stage `jdk-builder` to keep the runtime image lean. Plugins use `copy_from_builder: [<paths>]` with `base_image: <stage-image>` to express the same pattern:

```yaml
container:
  base_image: eclipse-temurin:21-jdk
  copy_from_builder:
    - /opt/java/openjdk
  env:
    JAVA_HOME: /opt/java/openjdk
    PATH: /opt/java/openjdk/bin:${PATH}
  install_script: install.sh
```

The dispatcher's `_extended-image` build pipeline (Story 13.4) renders this as:

```dockerfile
FROM ghcr.io/devrail-dev/dev-toolchain:v1.11.0 AS runtime
COPY --from=eclipse-temurin:21-jdk /opt/java/openjdk /opt/java/openjdk
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH=/opt/java/openjdk/bin:${PATH}
COPY .devrail-plugins-build/devrail-plugin-kotlin/v1.0.0/install.sh /opt/devrail/plugins/devrail-plugin-kotlin/install.sh
RUN chmod +x /opt/devrail/plugins/devrail-plugin-kotlin/install.sh && bash /opt/devrail/plugins/devrail-plugin-kotlin/install.sh
```

### Install-script porting notes

`dev-toolchain/scripts/install-kotlin.sh` sources `lib/log.sh` and `lib/platform.sh`. These libs live in dev-toolchain at `/opt/devrail/lib/` — they're available at runtime but NOT at the plugin-build phase (the plugin's install.sh runs during docker build of the extended image, with the working dir being the plugin's staged directory under `.devrail-plugins-build/`).

Two options:
- a) Strip lib dependencies from the plugin's `install.sh`. Replace `log_info` with `printf '%s\n' "$msg" >&2` etc. Self-contained.
- b) Vendor a minimal `log.sh` into the plugin repo.

Option (a) is simpler and more honest for plugin authors who don't want to ship a vendored copy of the dev-toolchain libs. Use option (a) for the kotlin plugin — and document this nuance in the extraction recipe.

### Targets translation

| dev-toolchain Makefile block | Plugin manifest target | Gate |
|---|---|---|
| HAS_KOTLIN in `_lint` (ktlint) | `lint.cmd: "ktlint {paths}"` | `["build.gradle.kts"]` (or `*.kt`) |
| HAS_KOTLIN in `_lint` (detekt) | merge into same `lint.cmd` via `&&`, OR add a separate cmd via composite identifier | n/a (gates are per target, not per tool) |
| HAS_KOTLIN in `_format` | `format_check.cmd: "ktlint --format --dry-run"` | `["build.gradle.kts"]` |
| HAS_KOTLIN in `_fix` | `format_fix.cmd: "ktlint --format"` | `["build.gradle.kts"]` |
| HAS_KOTLIN in `_test` | `test.cmd: "gradle test --no-daemon"` | `["build.gradle.kts"]` |
| HAS_KOTLIN in `_security` | `security.cmd: "gradle dependencyCheckAnalyze --no-daemon"` | `["build.gradle.kts"]` |

The "ktlint AND detekt" composite under `lint` is a known limitation of the v1 plugin contract — only one cmd per target. Options: chain via `&& detekt-cli ...`, or wrap in a tiny shim script. Document the chosen approach in the plugin README.

### Anti-patterns

- **Don't remove kotlin from dev-toolchain core in this story.** That's v2.0.0. Removing now breaks consumers.
- **Don't introduce a new manifest field to handle "two tools per target".** Document the `&&` chaining workaround instead.
- **Don't make the plugin install script depend on dev-toolchain's `lib/log.sh`.** Self-contained scripts are the contract for plugin authors.

### File touchpoints

**New repo: `github.com/devrail-dev/devrail-plugin-kotlin` (entirely new):**
- `plugin.devrail.yml` — manifest
- `install.sh` — ported from dev-toolchain
- `README.md`
- `LICENSE` (MIT)
- DevRail-standard files: `Makefile`, `.devrail.yml`, `.pre-commit-config.yaml`, etc.
- `.github/workflows/` — CI

**dev-toolchain repo (release-only):**
- `CHANGELOG.md` — v1.11.0 entry
- `STABILITY.md` — note the reference plugin
- `tests/test-kotlin-plugin-extraction.sh` — NEW smoke test (validates the plugin against a fixture)
- `tests/fixtures/kotlin-via-plugin/` — NEW fixture
- `.github/workflows/ci.yml` — add a step for the new smoke test
- (NO Dockerfile / Makefile changes — kotlin stays in core for v1.11.x)

**OrgDocs/development-standards repo:**
- `standards/contributing.md` — new "Extracting a core language as a plugin" subsection
- `_bmad-output/implementation-artifacts/13-7-...md` — THIS FILE
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — `13-7-... → done`

**devrail.dev repo:**
- `content/docs/contributing/adding-a-plugin.md` — extension with extraction-recipe section
- `content/blog/2026-MM-DD-kotlin-as-reference-plugin.md` — release blog post

## Dev Agent Record

### Agent Model Used

(to be filled by dev workflow)

### Debug Log References

(to be filled by dev workflow)

### Completion Notes List

(to be filled by dev workflow)

### File List

(to be filled by dev workflow)

### Change Log

| Date | Change |
|---|---|
| 2026-05-05 | Story created (status: ready-for-dev) — combined cleanup branch (`chore/13-7-prep-and-cleanup`) also flips 13-1 (review→done) and epic-12 (in-progress→done) |
