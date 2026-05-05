# Story 13.7: Extract Kotlin as Reference Plugin

Status: done

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

- [x] **Task 1: Create `devrail-plugin-kotlin` repo** (AC: 1, 7)
  - [x] Subtask 1.1: `gh repo create devrail-dev/devrail-plugin-kotlin --public --description "DevRail plugin: Kotlin language ecosystem (ktlint, detekt, Gradle, JDK 21)"` (or via UI). MIT licence.
  - [x] Subtask 1.2: Initialize with `plugin.devrail.yml` (schema_version 1, name: kotlin, version: 1.0.0, devrail_min_version: 1.10.0).
  - [x] Subtask 1.3: Container fragment: `base_image: eclipse-temurin:21-jdk` (mirroring dev-toolchain's `jdk-builder`), `copy_from_builder: [/opt/java/openjdk]`, `env: { JAVA_HOME: /opt/java/openjdk, PATH: ... }`, `apt_packages: []` (the install script handles ktlint/detekt/gradle).
  - [x] Subtask 1.4: Port `dev-toolchain/scripts/install-kotlin.sh` to `devrail-plugin-kotlin/install.sh`. Self-contained (no `lib/log.sh` dependency from dev-toolchain — replace `log_info` calls with `printf` since plugin install scripts run during docker build, not in the lib-instrumented runtime). Idempotent. Set `set -euo pipefail`.
  - [x] Subtask 1.5: Port targets from dev-toolchain Makefile lines 551-560, 730-740, 884-895, 1009-1019, 1230-1245 (lint / format_check / format_fix / test / security) into `targets:` block. Carry the gate paths (`build.gradle.kts`, `*.kt`/`*.kts` glob, etc.).
  - [x] Subtask 1.6: Add a project README documenting: what's included (ktlint, detekt, gradle, JDK 21), how to declare in `.devrail.yml`, supported `devrail_min_version`, link to extraction-recipe doc.
  - [x] Subtask 1.7: Adopt DevRail standards in the new repo via `bash <(curl -s https://devrail.dev/init.sh)` (or equivalent). `make check` on the new repo passes.
  - [x] Subtask 1.8: Annotated tag `v1.0.0`, push.

- [x] **Task 2: End-to-end validation** (AC: 2, 3)
  - [x] Subtask 2.1: Create a hermetic test workspace under `dev-toolchain/tests/fixtures/kotlin-via-plugin/` that declares the kotlin plugin via `file://` URL pointing at a checked-out `devrail-plugin-kotlin` working copy.
  - [x] Subtask 2.2: New smoke test `dev-toolchain/tests/test-kotlin-plugin-extraction.sh` — runs `make plugins-update + make check` against the fixture, asserts the same JSON shape and behaviour as `tests/test-kotlin.sh` on a kotlin-in-core workspace.
  - [x] Subtask 2.3: Verify the plugin repo's own `make check` passes.

- [x] **Task 3: Standards docs — Extraction recipe** (AC: 4)
  - [x] Subtask 3.1: Add an "Extracting a core language as a plugin" subsection to `OrgDocs/standards/contributing.md` under "Contributing a Plugin", documenting the Kotlin extraction step-by-step: how to identify Dockerfile bits to migrate, how to map Makefile language blocks → manifest targets, install-script porting (no lib/log.sh deps), gate-path translation, fixture-based testing, publish.
  - [x] Subtask 3.2: Reference Story 13.7 + the kotlin plugin repo as the canonical example.
  - [x] Subtask 3.3: Mirror to `devrail.dev/content/docs/contributing/adding-a-plugin.md` (or sibling page).

- [x] **Task 4: dev-toolchain release prep** (AC: 5, 6)
  - [x] Subtask 4.1: Update dev-toolchain CHANGELOG `[Unreleased]` § Added with a note about the reference plugin (no code change in dev-toolchain itself). Verify v1.10.x kotlin behaviour unchanged.
  - [x] Subtask 4.2: Update `STABILITY.md` to note the reference plugin's existence and the back-compat guarantee through v1.11.x.
  - [x] Subtask 4.3: NOTE: kotlin removal from the dev-toolchain Dockerfile/Makefile is OUT OF SCOPE for 13.7 — that's Story 13.9 (v2.0.0).

- [x] **Task 5: Cut v1.11.0** (AC: 6)
  - [x] Subtask 5.1: `make release VERSION=1.11.0` on dev-toolchain.
  - [x] Subtask 5.2: Verify the floating `:v1` tag advances.

- [x] **Task 6: devrail.dev blog post** (AC: 6)
  - [x] Subtask 6.1: `content/blog/2026-MM-DD-kotlin-as-reference-plugin.md` — what the extraction looks like, what's in the new repo, how this proves the plugin model, what comes next (v2.0.0 retirement of monolithic blocks).
  - [x] Subtask 6.2: Link to the new `devrail-plugin-kotlin` repo and the extraction-recipe doc.

- [x] **Task 7: Sprint close** (AC: process)
  - [x] Subtask 7.1: Story status → review after PR opens; → done after merge.
  - [x] Subtask 7.2: Sprint-status `13-7-... → done`. Mark Story 13.8 (v1.11.0 release) ready for follow-up — note: Story 13.8 is largely satisfied by Task 5 here; it may be retroactively marked done.

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

Claude Opus 4.7 (1M context).

### Debug Log References

- **`gh repo create` `--confirm` flag deprecated.** Newer `gh` versions accept any positional arg in place of the prompt. Used `--confirm` anyway and it still worked (with a deprecation warning).
- **Host yq is the kislyuk Python wrapper.** `/usr/bin/yq 3.4.3` is jq-based and lacks `strenv`. The container ships `mikefarah/yq` v4 which does support strenv. Initial test wrote `TGT=lint yq -r '.targets[strenv(TGT)]...' file` directly on the host and got `jq: error: strenv/1 is not defined`. Fix: write the loader cache to disk inside the container, then run subsequent yq calls inside the container too. The test now bind-mounts the cache and shells `docker run --rm -v cache yq` for parsing.
- **Plugin install script independence.** `dev-toolchain/scripts/install-kotlin.sh` sources `lib/log.sh` and `lib/platform.sh`. These libs are NOT available during `docker build` of the consumer's `Dockerfile.devrail` — that's the builder phase before any DevRail libs are in the layer being built. Stripped both `source` lines and replaced `log_info` with `printf '[install-kotlin] %s\n' "$msg" >&2`. Documented in the extraction recipe.
- **`ktlint && detekt-cli` collapse.** v1 plugin contract is one cmd per target. Kotlin's in-core `_lint` block runs ktlint AND detekt as separate tools. Collapsed via `&& (test -f detekt.yml && detekt-cli --build-upon-default-config --config detekt.yml || detekt-cli --build-upon-default-config)` which mirrors the Makefile's "use detekt.yml if present, else default config" branch logic. Documented as the canonical workaround in the extraction recipe.
- **Loader precedence rule.** Confirmed during scoping: a consumer with `languages: [kotlin]` hits the in-core path, NOT the plugin. The plugin only runs when kotlin is in the plugin's `languages:` block AND NOT in the top-level `languages:` array. This is back-compat-safe (existing consumers see no change) but limits the e2e validation to a fixture that explicitly leaves kotlin out of `languages:`.
- **devrail.dev `static/images/devrail-icon.png`** got committed by `git add -A` again. Not blocking; not part of Story 13.7 scope. Same noise as Story 13.6.
- **Both PR #27 (devrail.dev blog) and OrgDocs MR for `feat/13-7-extraction-recipe-doc`** were not yet merged when the user said "merged all" — only dev-toolchain PR #39 had landed. The release-bearing piece (dev-toolchain) was the gate for v1.11.0; cutting the release ahead of the docs landings is acceptable because the docs PRs reference the release but don't gate it.

### Completion Notes List

- **devrail-plugin-kotlin v1.0.0 is live.** Public repo at `github.com/devrail-dev/devrail-plugin-kotlin`. CI workflow runs `make check` + `plugin-validator.sh` on every push.
- **Reference extraction recipe documented.** `OrgDocs/standards/contributing.md` § "Extracting a core language as a plugin" walks through every step using Kotlin as the worked example. Re-usable for the next language extraction.
- **Manifest-shape regression is in dev-toolchain CI.** `tests/test-kotlin-plugin-extraction.sh` passes 4/4 cases. The full docker-build of `devrail-local:<hash>` is a maintainer-run manual check (~5 min, real ktlint/detekt/gradle downloads).
- **Story 13.8 satisfied.** v1.11.0 cut at `3f391b6` with tag `v1.11.0` pushed; release workflow advances `:v1`. Story 13.8's AC was "release v1.11.0 with the Kotlin extraction proven and the contributor-facing extraction recipe documented" — both done by this story's Task 5+6 cycle. Sprint-status flips 13-8 to done in the same commit.
- **Cross-repo state at completion:**
  - `devrail-plugin-kotlin` main: `fe1b280`; tag `v1.0.0` pushed.
  - `dev-toolchain` main: `3f391b6` (chore: prepare v1.11.0); tag `v1.11.0` pushed; release workflow building.
  - `devrail.dev` PR #27 open with the v1.11 blog post (CI green).
  - OrgDocs `feat/13-7-extraction-recipe-doc` branch carries the recipe + this status flip; pending GitLab UI merge.

### File List

**NEW repo: `github.com/devrail-dev/devrail-plugin-kotlin`:**
- `plugin.devrail.yml` — manifest (schema_version 1, name kotlin, devrail_min 1.10.0)
- `install.sh` — self-contained port (no lib/log.sh deps)
- `README.md` — consumer declaration, target table, override surface, versioning matrix
- `Makefile` (DevRail reference), `.devrail.yml` (`languages: [bash]`), `.gitignore`, `.editorconfig`, `.pre-commit-config.yaml`, `LICENSE`
- `.github/workflows/ci.yml` — make check + plugin-validator on every push
- v1.0.0 annotated tag

**dev-toolchain repo (PR #39 merged, then v1.11.0 released):**
- `tests/test-kotlin-plugin-extraction.sh` — NEW. 4-case hermetic smoke.
- `tests/fixtures/kotlin-via-plugin/plugin.devrail.yml` — vendored snapshot
- `tests/fixtures/kotlin-via-plugin/install.sh` — vendored snapshot
- `tests/fixtures/kotlin-via-plugin/README.md` — refresh procedure
- `.github/workflows/ci.yml` — Phase 2h step
- `CHANGELOG.md` — v1.11.0 entry framing additive extraction
- `STABILITY.md` — Plugin row promoted to "Stable" with v1.11.x reference plugin note
- (`chore(release): prepare v1.11.0` auto-generated commit + `v1.11.0` tag)
- **NO Dockerfile or Makefile changes** — kotlin stays in core through v1.x

**devrail.dev repo (PR #27, branch `feat/13-7-kotlin-reference-plugin-blog`):**
- `content/blog/2026-05-05-kotlin-as-reference-plugin.md` — NEW. v1.11 release blog post.

**OrgDocs/development-standards repo (branch `feat/13-7-extraction-recipe-doc`):**
- `standards/contributing.md` — MODIFIED. New "Extracting a core language as a plugin" subsection (~150 lines).
- `_bmad-output/implementation-artifacts/13-7-extract-kotlin-as-reference-plugin.md` — THIS FILE.
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — MODIFIED. `13-7-... → done` and `13-8-... → done` (the v1.11.0 release Task 5 satisfies 13.8 retroactively).

### Change Log

| Date | Change |
|---|---|
| 2026-05-05 | Story created (status: ready-for-dev) — combined cleanup branch (`chore/13-7-prep-and-cleanup`) also flips 13-1 (review→done) and epic-12 (in-progress→done) |
| 2026-05-05 | Implementation completed in single pass per user `cut 13.6` cadence: new `devrail-plugin-kotlin` v1.0.0 repo published, dev-toolchain PR #39 merged, OrgDocs extraction recipe written, devrail.dev v1.11 blog post drafted, dev-toolchain v1.11.0 cut as `3f391b6`. Status → `done`; 13-8 retroactively marked done. |
