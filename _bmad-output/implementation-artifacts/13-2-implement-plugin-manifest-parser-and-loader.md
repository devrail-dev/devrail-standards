# Story 13.2: Implement Plugin Manifest Parser and Loader

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **dev-toolchain maintainer**,
I want the Makefile to discover plugin manifests declared in `.devrail.yml`, parse them with `yq`, and validate them against the v1 plugin manifest schema before any other target runs,
so that downstream targets (Stories 13.3, 13.4, 13.5) can iterate plugin definitions safely and consumers fail fast on misconfigured plugins instead of wedging mid-`make check`.

## Acceptance Criteria

1. **Given** a `.devrail.yml` with a `plugins:` section listing one or more plugins
   **When** `make check` runs
   **Then** each declared plugin's `plugin.devrail.yml` is located, parsed by `yq`, and schema-validated against `schema_version: 1`
   **And** the loader runs **before** `_lint`, `_format`, `_fix`, `_test`, `_security` — no tool runs unless all manifests are valid

2. **Given** a plugin manifest with a `schema_version` other than `1`
   **When** the loader processes it
   **Then** the loader emits a structured `error`-level JSON event identifying the plugin and the unsupported schema version
   **And** `make check` exits with code `2` (configuration error), distinct from `1` (tool failure)

3. **Given** a plugin manifest with `devrail_min_version` greater than the running dev-toolchain image version (read from the image label `org.opencontainers.image.version` or fallback `DEVRAIL_VERSION` env)
   **When** the loader processes it
   **Then** the loader emits an `error` event identifying the gap
   **And** `make check` exits with code `2`

4. **Given** a plugin manifest missing any required field (`schema_version`, `name`, `version`, `devrail_min_version`, `targets`) or violating field constraints (e.g. `name` doesn't match `^[a-z][a-z0-9_-]*$`)
   **When** the loader processes it
   **Then** the loader emits a per-violation `error` event citing the field and the violation reason
   **And** `make check` exits with code `2`

5. **Given** all declared plugins parse and validate successfully
   **When** the loader completes
   **Then** the loader emits a single `info`-level summary event with `loaded` count and per-plugin metadata (name, version, declared targets)
   **And** the loaded manifest data is exposed to subsequent targets in a way they can iterate (e.g. via a parsed cache file at a known path inside the container)

6. **Given** a `.devrail.yml` without a `plugins:` section (the v1.9.x baseline)
   **When** `make check` runs
   **Then** the loader emits a single `info`-level event noting "no plugins declared" and exits with code `0`
   **And** all existing core-language behavior is unchanged (regression-safe)

7. **Given** a passing test suite
   **When** `bash tests/test-plugin-loader.sh` runs
   **Then** it covers: valid happy path, unknown schema_version, devrail_min_version too high, name regex violation, missing required field, no `plugins:` section
   **And** all six cases produce the expected exit code and JSON event signatures

## Tasks / Subtasks

- [x] **Task 1: Schema validator script** (AC: 2, 4)
  - [x] 1.1 Create `scripts/plugin-validator.sh`. Sources `lib/log.sh` and `lib/platform.sh` per existing convention. Header in the project's standard format (purpose, usage, deps).
  - [x] 1.2 Implement `validate_manifest <path>` function. Uses `yq` (already in image, v4.44.1) to parse. Validates required fields exist and types match (`schema_version: int`, `name: string`, `version: string`, `devrail_min_version: string`, `targets: mapping`).
  - [x] 1.3 Validate field constraints: `schema_version == 1`; `name` matches `^[a-z][a-z0-9_-]*$`; `version` and `devrail_min_version` are dotted-numeric semver (`^[0-9]+\.[0-9]+\.[0-9]+$`).
  - [x] 1.4 Validate at least one of `lint`/`format_check`/`format_fix`/`fix`/`test`/`security` exists in `targets:`.
  - [x] 1.5 Each violation calls `log_error` with structured fields: `{"level":"error","msg":"plugin schema violation","plugin":"<name>","field":"<path>","reason":"<reason>","language":"_plugins"}`.
  - [x] 1.6 Return non-zero on any violation; cumulative — report ALL violations, don't fail-fast on the first one (consumers want full feedback in one run).
  - [x] 1.7 Idempotent and re-runnable. No filesystem mutations except optional cache write (Task 3).

- [x] **Task 2: Version comparison helper** (AC: 3)
  - [x] 2.1 Add `version_gte <a> <b>` to `lib/platform.sh` (or `lib/version.sh` if cleaner) — returns 0 if `a >= b` semver-wise. Pure bash, no external deps.
  - [x] 2.2 Image version detection: read `DEVRAIL_VERSION` env first; if empty, read OCI label `org.opencontainers.image.version` from `/etc/os-release`-equivalent or `/opt/devrail/VERSION` (whichever the existing release script writes — verify in `scripts/release.sh`).
  - [x] 2.3 Validator calls `version_gte "$IMAGE_VERSION" "$MANIFEST_MIN"`; on false, emits structured error and increments violation count.

- [x] **Task 3: Loader prelude in Makefile** (AC: 1, 5, 6)
  - [x] 3.1 Add `_plugins-load` internal target. Reads `.devrail.yml` `plugins:` via `yq`. For each entry, expects `plugin.devrail.yml` at a deterministic local path: `/opt/devrail/plugins/<source-slug>/<rev>/plugin.devrail.yml` (Story 13.3 will populate this; Story 13.2 only consumes it).
  - [x] 3.2 If `plugins:` is absent or empty, emit `{"level":"info","msg":"no plugins declared","language":"_plugins"}` and exit 0.
  - [x] 3.3 For each plugin, invoke `bash /opt/devrail/scripts/plugin-validator.sh <manifest-path>`.
  - [x] 3.4 Aggregate validator exit codes. Any non-zero → `_plugins-load` exits with code `2`.
  - [x] 3.5 On success, write a parsed cache to `/tmp/devrail-plugins-loaded.yaml` (or similar) — a yq-flattened map of plugin name → manifest contents — for Story 13.5's execution loop.
  - [x] 3.6 Wire `_plugins-load` as a dependency of `_check`, `_lint`, `_format`, `_fix`, `_test`, `_security`. Each must invoke `_plugins-load` before its language blocks. Use Make's prerequisite mechanism so it runs once per `make` invocation, not once per target.
  - [x] 3.7 Emit summary event on completion: `{"level":"info","msg":"plugin loader complete","loaded":<N>,"failed":<M>,"plugins":[...],"language":"_plugins"}`.

- [x] **Task 4: Test fixtures** (AC: 7)
  - [x] 4.1 `tests/fixtures/plugins/valid-elixir/plugin.devrail.yml` — happy path, mirrors the design doc's Elixir example (minimal — just `schema_version`, `name`, `version`, `devrail_min_version: 1.10.0`, `targets.lint.cmd`, `gates.lint`).
  - [x] 4.2 `tests/fixtures/plugins/invalid-schema/plugin.devrail.yml` — `schema_version: 2`.
  - [x] 4.3 `tests/fixtures/plugins/incompatible-version/plugin.devrail.yml` — `devrail_min_version: 99.0.0`.
  - [x] 4.4 `tests/fixtures/plugins/bad-name/plugin.devrail.yml` — `name: Elixir` (uppercase, violates regex).
  - [x] 4.5 `tests/fixtures/plugins/missing-field/plugin.devrail.yml` — omits `targets:`.
  - [x] 4.6 Each fixture is the *manifest only* — no install scripts, no container fragments. Story 13.2 doesn't consume those.

- [x] **Task 5: Smoke test script** (AC: 7)
  - [x] 5.1 Create `tests/test-plugin-loader.sh`. Pattern: mirrors `tests/smoke-rails.sh` (mktemp fixture dir, docker-cleanup trap, structured pass/fail output).
  - [x] 5.2 For each fixture, build a synthetic `.devrail.yml` referencing it and run `bash scripts/plugin-validator.sh <fixture>` directly (don't depend on the full Makefile loader for unit-level tests).
  - [x] 5.3 Then exercise the full loader: run `make _plugins-load` against a workspace whose `.devrail.yml` declares a plugin pointing at a checked-in fixture path, verify exit code and JSON event signature.
  - [x] 5.4 Cover the no-`plugins:`-section case to lock in regression safety (AC 6).
  - [x] 5.5 Tests assert specific JSON fields (`level`, `msg`, `language`, plugin name) using `jq`. No string-matching of full lines (brittle).

- [x] **Task 6: Wire smoke test into CI** (AC: 7)
  - [x] 6.1 Add a step to `.github/workflows/ci.yml` after the existing `Rails 7+ smoke test` step, mirroring its structure: `bash tests/test-plugin-loader.sh`.
  - [x] 6.2 Update `tests/smoke-rails.sh`'s header docstring to add issue references if any are filed for plugin loader regressions later (out of scope for this story; just leave the comment block consistent with `smoke-rails.sh`'s style).

- [x] **Task 7: Documentation** (AC: 1, 6)
  - [x] 7.1 Add a `## Plugin Loader (post-Story 13.2)` subsection to `dev-toolchain/STABILITY.md` (or `README.md` if a more visible spot is preferred) noting that the loader exists, runs as a prelude, and that without `plugins:` in `.devrail.yml` behavior is unchanged.
  - [x] 7.2 No changes yet to `standards/devrail-yml-schema.md` — Story 13.6 (the v1.10.0 release-prep story) bundles all schema/standards-doc updates into one MR. **Do not** preemptively add a `plugins:` section to the schema doc in this story; it will conflict with 13.6's MR scope.
  - [x] 7.3 CHANGELOG.md entry under `[Unreleased]` → `### Added`: a one-line note about the plugin loader prelude landing.

## Dev Notes

### Authoritative source

The plugin manifest schema, lifecycle, and loader contract are defined in `_bmad-output/planning-artifacts/plugin-architecture-design.md`. Read **§"Plugin Manifest"** and **§"Manifest schema rules"** before starting Task 1. If the design doc and this story disagree, the design doc wins — flag the discrepancy in code review.

### Scope boundary (read carefully)

This story is **parser + loader prelude only**. The loader assumes plugin manifests are already present at deterministic local paths inside the container. The component that *fetches* plugin repos and *resolves* refs to those local paths is **Story 13.3** — do not implement fetching here. Tests use checked-in fixtures rather than network-fetched plugin repos.

The execution loop that *runs plugin commands* during `_lint`/`_format`/etc. is **Story 13.5** — do not implement target dispatch here. Story 13.2 stops at "manifests are validated and cached for downstream targets to consume".

### Architecture pattern context

The dev-toolchain Makefile follows a [two-layer delegation pattern](dev-toolchain/Makefile) — public targets on the host invoke `docker run` against internal `_<target>` recipes. Plugin loader work is **internal-only** (`_plugins-load`); no public host target needed in this story. Internal targets read `.devrail.yml` directly via `yq` (which is in the image at `/usr/local/bin/yq`, v4.44.1).

### File touchpoints

| Path | Change |
|---|---|
| `dev-toolchain/Makefile` | Add `_plugins-load` internal target; wire as prerequisite of `_check`, `_lint`, `_format`, `_fix`, `_test`, `_security`. |
| `dev-toolchain/scripts/plugin-validator.sh` | New — schema validator. |
| `dev-toolchain/lib/platform.sh` (or new `lib/version.sh`) | Add `version_gte` helper. |
| `dev-toolchain/tests/test-plugin-loader.sh` | New — smoke test. |
| `dev-toolchain/tests/fixtures/plugins/*/plugin.devrail.yml` | New — five manifest fixtures. |
| `dev-toolchain/.github/workflows/ci.yml` | New step invoking `tests/test-plugin-loader.sh`. |
| `dev-toolchain/CHANGELOG.md` | One-line `Added` entry under `[Unreleased]`. |
| `dev-toolchain/STABILITY.md` (or `README.md`) | Brief plugin-loader-exists note. |

### Logging convention (existing — reuse)

`lib/log.sh` exports `log_info`, `log_warn`, `log_error`, `log_debug`, `die`. They emit structured JSON when `DEVRAIL_LOG_FORMAT=json` (default) and human-readable otherwise. Use these — **no raw `echo` for status messages** (CLAUDE.md critical rule 6).

Existing JSON event shape across the codebase:

```json
{"level":"info","msg":"<message>","script":"<calling-script>","language":"<lang-or-_meta>","ts":"<iso8601>"}
```

For loader events use `language: "_plugins"` (underscore prefix to namespace from real language names).

### Exit code convention (existing — reuse)

- `0` — pass
- `1` — tool failure (existing convention for `_lint` etc.)
- `2` — misconfiguration (missing `.devrail.yml`, missing tools, etc.) — **plugin schema/version violations land here**

The `_check` orchestrator already documents this triple in the Makefile comments. The loader inherits it.

### Schema-validation strategy

Pure bash + `yq` is sufficient. Don't add a JSON Schema runner (`ajv`, `python-jsonschema`, etc.) — adds a dep and overshoots the v1 schema's complexity. The schema has six required fields and three regexes; bash handles it cleanly.

### `yq` cheatsheet for this story

- Existence check: `yq -e '.field' file.yml` returns 0 if present, 4 if missing
- Type check: `yq -r '.field | type' file.yml` → `"!!str"`, `"!!int"`, etc.
- Mapping iteration: `yq '.targets | keys | .[]' file.yml`
- Selecting entries: `yq -r '.plugins[] | .name + "@" + .rev' .devrail.yml`

### Testing standard

Smoke tests live in `tests/`. Pattern: `tests/test-<area>.sh`. Follow the existing convention (`tests/test-ruby.sh`, `tests/smoke-rails.sh`):

- `set -euo pipefail`
- Source `lib/log.sh` for output
- Use `mktemp -d` for fixtures + cleanup trap
- Assert with `jq` on JSON events (e.g. `jq -e 'select(.level=="error" and .plugin=="bad-name")' < events.log`)
- Single positive case + N negative cases per scenario
- Each test prints a clear `==> step` heading and a `PASS`/`FAIL` summary

`make _check` includes `tests/` in shellcheck scope. Linter must pass on all new scripts.

### Project structure notes

- All implementation lives under `~/Work/github.com/devrail-dev/dev-toolchain` (separate repo from this planning repo). Open the work as a feature branch off that repo's `main`, e.g. `feat/13-2-plugin-loader`.
- Conventional commit scope for this work: `makefile` or `container` (existing scopes; pre-commit-conventional-commits hook v1.1.0 accepts both).
- PR closes neither issue #25 nor #28 — those are done. Reference Story 13.2 in the PR description.

### What NOT to do (anti-patterns observed in similar projects)

- **Don't** use `python -c` to parse YAML. The container has python but using it for YAML in a Makefile recipe is a regression — yq is the standard tool here.
- **Don't** generate intermediate Make snippets via codegen. The design explicitly chose an "embedded execution loop" over include-files (see design doc §"Plugin Lifecycle"). Plugin manifests are *consumed at runtime*, not converted to Makefile.
- **Don't** add a registry/manifest-cache abstraction. v1 is git-only with content-addressed local paths; over-engineering this story bleeds scope into Story 13.3.
- **Don't** use suppression annotations (`# shellcheck disable=...`) to bypass linter complaints. Fix the underlying issue (CLAUDE.md critical rule 7).

## Previous Story Intelligence — Story 13.1

Story 13.1 produced `_bmad-output/planning-artifacts/plugin-architecture-design.md` (610 lines). Key decisions that constrain this story:

- **Manifest format is YAML with `schema_version: 1`** — bumped on breaking change. Validator must reject other majors.
- **Plugin identity is a source-address triple `host/namespace/name`** (Terraform-style). Story 13.3 implements resolution; Story 13.2 just consumes the local path the resolver writes.
- **Immutable refs only** — `rev:` in `.devrail.yml` must be a tag or SHA. Branch refs are rejected. Story 13.3 enforces; Story 13.2 doesn't see refs directly (it sees post-resolution local paths).
- **`devrail_min_version` enforced by loader** — Story 13.2's job. Pattern from pre-commit's `minimum_pre_commit_version`.
- **Per-target gates evaluated by execution loop** (Story 13.5). Story 13.2 only validates the gate *syntax*; it doesn't evaluate gates against the workspace.
- **Container fragments (`container.base_image`, `apt_packages`, etc.) consumed by build pipeline** (Story 13.4). Story 13.2 only validates that the fields are present and well-typed, not that they describe a buildable image.
- **Pre-commit hooks (`pre_commit:`) consumed at `make init` time, not validate time.** Story 13.2 validates structure if present; doesn't process them.

The design doc explicitly says **"DO NOT BE LAZY"** (its phrase) about which design decisions are load-bearing. The seven open questions in §"Open Questions" are explicitly out of scope for v1.10.0 (Stories 13.2–13.6). Don't pull any of them in.

## Git Intelligence — Recent dev-toolchain Patterns

Last eight commits in `github.com/devrail-dev/dev-toolchain`:

```
1ba9295 chore(release): prepare v1.9.1
c588028 fix(container): install libyaml-dev so bundle install can compile psych (#28) (#29)
4e90944 chore(release): prepare v1.9.0
102b820 feat(makefile): pass .devrail.yml env: section into container, auto-detect ANSIBLE_ROLES_PATH (#27)
98f4396 fix(ruby): bump container Ruby to 3.4, scope rubocop/reek to RUBY_PATHS (#25) (#26)
bf338d6 feat(container): add kustomize and kubeconform for Kubernetes validation (#24)
895cdd6 fix(container): build SwiftLint from source for arm64 support (#22)
200c0e8 feat(container): add Swift and Kotlin language ecosystem support (#19)
```

Patterns to **follow** (proven in recent commits):

- Multi-stage Dockerfile with named builder stages for compiled toolchains (Ruby, Rust, Swift, JDK).
- `lib/log.sh` for structured JSON events; never raw `echo` (the env-flags PR `#27` follows this; the rubocop scope work `#26` follows this).
- `tests/<area>.sh` smoke scripts mounting fixtures via bind volume; cleanup via in-container `rm` (added in PR `#29` after we hit the root-owned-files snag).
- Conventional commit scopes accepted: `makefile`, `container`, `ruby`, `ci`, `security`, `release`. Use `makefile` or `container` for this story.
- One PR per story (PRs `#26`, `#27`, `#29` each map to a single fix). Don't bundle 13.2 and 13.3 into one PR.

Patterns to **avoid** (subtle issues from recent commits):

- The env-flags work in PR `#27` had a `:=` ordering bug (`DEVRAIL_ENV_FLAGS` referenced `DEVRAIL_CONFIG` before it was defined). When you add `_plugins-load`, **place any new `:=` evaluations after `DEVRAIL_CONFIG`'s definition**.
- The Ruby bump in PR `#26` initially missed `libyaml-0-2` then `libyaml-dev`. Lesson: when validating Ruby/Python/etc.-adjacent additions, run a real consumer scenario (not just `--version`). For the plugin loader, the smoke test must actually parse a manifest end-to-end, not just verify `yq` is on PATH.
- shfmt enforces 2-space indents in shell scripts (PR `#26` had to fix 4-space indents post-hoc). Default your editor to 2-space when writing `scripts/plugin-validator.sh` and `tests/test-plugin-loader.sh`.

## Latest Tech Information

No external tech research required for this story. All tools used are already in the v1.9.1 image:

- **`yq` v4.44.1** — already pinned in `Dockerfile:99-104`. No upgrade needed for Story 13.2; the queries used are basic (`.plugins[]`, `.targets | keys`, `.<field> | type`). v4.x semantics are stable.
- **`jq`** — already in apt base layer. Used in tests for assertion.
- **`bash` 5.x** — Debian bookworm slim. `[[`, regex match `=~`, parameter expansion all available.
- **`shellcheck`** — already in image; passes on every new shell script via pre-commit + `make _lint`.
- **`shfmt`** — already in image (`/usr/local/bin/shfmt`); enforces 2-space indent.

## Project Context Reference

- Project root: `~/Work/gitlab.mfsoho.linkridge.net/OrgDocs/development-standards` (this repo, planning)
- Implementation repo: `~/Work/github.com/devrail-dev/dev-toolchain`
- Standards docs: `standards/makefile-contract.md` (Makefile conventions), `standards/coding-practices.md` (general principles)
- Plugin design source of truth: `_bmad-output/planning-artifacts/plugin-architecture-design.md`
- CLAUDE.md critical rules apply throughout (especially #1 `make check` before completion, #6 use shared logging library, #7 never suppress failing checks).

## References

- [Source: `_bmad-output/planning-artifacts/plugin-architecture-design.md#Plugin Manifest`] — schema definition
- [Source: `_bmad-output/planning-artifacts/plugin-architecture-design.md#Manifest schema rules`] — field-level constraints
- [Source: `_bmad-output/planning-artifacts/plugin-architecture-design.md#Plugin Lifecycle`] — loader's place in the lifecycle (steps 1–4)
- [Source: `_bmad-output/planning-artifacts/architecture.md#Plugin Architecture (Phase 3)`] — top-level architectural pointer
- [Source: `_bmad-output/planning-artifacts/epics.md#Story 13.2`] — story-level AC
- [Source: `_bmad-output/implementation-artifacts/13-1-design-plugin-architecture.md`] — predecessor story
- [Source: `standards/makefile-contract.md`] — Makefile authoring conventions
- [Source: `dev-toolchain/Makefile`] — current target structure (study `_check`, `_lint` to mirror the prelude pattern)
- [Source: `dev-toolchain/lib/log.sh`] — logging library
- [Source: `dev-toolchain/tests/smoke-rails.sh`] — test pattern reference

## Dev Agent Record

### Agent Model Used

Claude Opus 4.7 (1M context) — single-session execution via `/bmad-bmm-dev-story` workflow.

### Debug Log References

- Initial smoke-test run: `tests/test-plugin-loader.sh` failed on the very first negative case because the original assertions used `out=$(... || true); exit_code=$?`, which always resolves `$?` to `0` (the assignment's exit code, not the validator's). Pattern was wrong for capturing exit codes after a possibly-failing command. Fixed by switching to `out=$(...) && exit_code=0 || exit_code=$?` everywhere — same idiom used in `tests/smoke-rails.sh`.
- Second smoke-test run: `missing-field` fixture reported the violation reason as "must be a mapping; got !!null" instead of "required field is missing". Root cause: `yq -r '.targets | type'` returns `!!null` (yq's tagged-null type) when a key is absent, not `null`. The validator's `yq_type` helper only mapped bare `null` to "missing"; updated to also map `!!null` to "missing". After this fix, all 8 plugin-loader smoke checks pass.
- Full container rebuild needed once for the Dockerfile ARG/RUN/COPY changes (~5 min); a smaller cached rebuild for the validator script edit (~3 min).

### Completion Notes List

- Ultimate context engine analysis completed — comprehensive developer guide created. Story 13.2 is the foundational v1.10.0 plugin-loader story; downstream stories 13.3–13.6 depend on its parser/loader contract. Scope boundaries explicitly drawn against 13.3 (fetcher) and 13.5 (executor) so the dev agent doesn't bleed work across stories.

**Implementation summary (2026-04-30):**

- All 7 acceptance criteria satisfied; 30 subtasks across 7 tasks marked complete.
- Validator (`scripts/plugin-validator.sh`, ~190 lines) uses pure bash + yq. Cumulative violation reporting per task 1.6 — emits one event per violation, never short-circuits. Exit codes per task header: 0 valid / 2 schema violation / 3 manifest unreadable.
- `lib/version.sh` introduced (separate file, not appended to `platform.sh`) — kept semver logic isolated for future reuse. `version_gte` is lenient on `0.0.0-dev` / empty (returns 0) so local builds without `--build-arg DEVRAIL_VERSION` don't break the loader.
- Loader prelude uses `${DEVRAIL_PLUGINS_DIR:-/opt/devrail/plugins}` and `${DEVRAIL_PLUGINS_CACHE:-/tmp/devrail-plugins-loaded.yaml}` env overrides for testability — production defaults match the design doc; tests bind-mount a fixture directory at `/opt/devrail/plugins`.
- Wired as prerequisite of `_check`, `_lint`, `_format`, `_fix`, `_test`, `_security` by replacing each target's `_check-config` prereq with `_plugins-load` (which itself depends on `_check-config`). Net effect: `_check-config` → `_plugins-load` → target body. Same chain on every recipe.
- Dockerfile records image semver via `ARG DEVRAIL_VERSION=0.0.0-dev` → `/opt/devrail/VERSION` and `LABEL org.opencontainers.image.version`. Will need a one-line addition to `build.yml` (`--build-arg DEVRAIL_VERSION=...`) to pass the actual release tag through; that's release-script plumbing, not Story 13.2 scope.
- 5 fixtures (`tests/fixtures/plugins/*/plugin.devrail.yml`) cover the matrix in AC 7. Smoke test asserts via `jq -e` on JSON event signatures (no fragile string matching).
- CI step added to `.github/workflows/ci.yml` after the Rails smoke step.
- STABILITY.md gains a "Plugin loader prelude" row in the component matrix (Preview status — full plugin support arrives at v1.10.0).
- `standards/devrail-yml-schema.md` intentionally NOT touched — that's Story 13.6's bundled MR per task 7.2.

**Verification (all green locally against the freshly built image):**

- `tests/test-plugin-loader.sh` — 8/8 (5 unit cases + 3 integration cases)
- `tests/smoke-rails.sh` — 3/3 (regression-safe; loader is a no-op with no `plugins:` section)
- `make _check` on dev-toolchain itself — pass; emits `"no plugins declared"` info event then proceeds normally

**Implementation PR:** https://github.com/devrail-dev/dev-toolchain/pull/31

### File List

**Implementation (dev-toolchain repo, branch `feat/13-2-plugin-loader`, PR #31):**

- `scripts/plugin-validator.sh` — new
- `lib/version.sh` — new
- `Makefile` — modified (added `_plugins-load` target; switched 6 targets from `_check-config` to `_plugins-load` prereq)
- `Dockerfile` — modified (added `ARG DEVRAIL_VERSION`, `LABEL org.opencontainers.image.version`, RUN write `/opt/devrail/VERSION`)
- `tests/fixtures/plugins/valid-elixir/plugin.devrail.yml` — new
- `tests/fixtures/plugins/invalid-schema/plugin.devrail.yml` — new
- `tests/fixtures/plugins/incompatible-version/plugin.devrail.yml` — new
- `tests/fixtures/plugins/bad-name/plugin.devrail.yml` — new
- `tests/fixtures/plugins/missing-field/plugin.devrail.yml` — new
- `tests/test-plugin-loader.sh` — new
- `.github/workflows/ci.yml` — modified (added "Plugin loader smoke test" step)
- `STABILITY.md` — modified (added "Plugin loader prelude" component row)
- `CHANGELOG.md` — modified (added `[Unreleased] → Added` entry)

**Story tracking (OrgDocs repo, branch `feat/13-2-create-story`, MR pending):**

- `_bmad-output/implementation-artifacts/13-2-implement-plugin-manifest-parser-and-loader.md` — modified (status, all 30 task checkboxes, Dev Agent Record, File List)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — modified (`13-2`: `ready-for-dev` → `in-progress` → `review`)

### Change Log

| Date | Change |
|---|---|
| 2026-04-27 | Story created via `/bmad-bmm-create-story` (status: ready-for-dev) |
| 2026-04-30 | Implementation completed via `/bmad-bmm-dev-story`; status moved to `review`; PR #31 opened on dev-toolchain |
| 2026-05-01 | PR #31 merged; v1.10.0 cut (also includes #30 Rails fixes) |
| 2026-05-03 | Senior-developer review completed via `/bmad-bmm-code-review`; 9 findings (2 HIGH, 2 MED, 5 LOW); all addressed via PR #33 (`fix/13-2-review-followups`); status moved to `done` |

## Senior Developer Review (AI)

**Reviewer:** Matthew (review executed by Opus 4.7 — same model that implemented the story; see caveat below)
**Date:** 2026-05-03
**Outcome:** Approve (after follow-up fix PR #33)

### Caveat

Per the dev-story workflow's recommendation, code-review should run under a **different** LLM than the one that implemented the story. This review was conducted under Opus 4.7, which is the same model that wrote the original implementation. Findings should be treated as a checklist sweep (catch obvious gaps and design/implementation drift) rather than a true second-pair-of-eyes review. A future review under Sonnet 4.6 or a different family is welcome and may surface additional findings.

### Findings

**HIGH severity (must fix — done in PR #33):**

- [x] **H1** — Cache file content didn't match design's intent. Design (`plugin-architecture-design.md` §"Plugin Lifecycle" step 6) says the cache exposes "manifest data" / "yq-flattened map of plugin name → manifest contents" so Story 13.5's execution loop can iterate `targets.<x>.cmd` and `gates.<x>` without re-parsing. Implementation only wrote `name`/`version`/`source`/`manifest`-path. Fixed by using `yq -i '.plugins += [load("$manifest") + {source, rev, manifest_path}]'` to merge full manifest with resolution metadata. Tests now assert `.plugins[0].targets.lint.cmd` resolves.
- [x] **H2** — Manifest path dropped the `<rev>` segment. Story task 3.1 and design `§"Plugin Lifecycle"` step 3 specify `<plugins-dir>/<slug>/<rev>/plugin.devrail.yml`. Implementation used `<plugins-dir>/<slug>/plugin.devrail.yml` (no rev), preventing multiple versions of the same plugin from coexisting and misaligning with what Story 13.3's resolver will populate. Fixed by including `<rev>` in the lookup path. Test fixtures restructured.

**MEDIUM severity (should fix — done in PR #33):**

- [x] **M1** — `gates` field was never validated. Per design schema rules, `gates` is optional but if present must be a mapping of valid target names to lists of strings. Validator skipped it entirely; Story 13.5 would have crashed at runtime on malformed gates. Fixed by adding gates validation to `plugin-validator.sh` + a new `bad-gates` fixture.
- [x] **M2** — Validator hand-crafted JSON via `printf`, bypassing `lib/log.sh` (CLAUDE.md critical rule #6 — "use the shared logging library"). Fixed by adding a new `log_event` function to `lib/log.sh` that accepts arbitrary extra fields, and refactoring the validator to use it. `DEVRAIL_LOG_FORMAT=human` now works for plugin events too.

**LOW severity (nice to fix — done in PR #33):**

- [x] **L1** — `lib/platform.sh` was sourced but never used in `plugin-validator.sh`. Removed.
- [x] **L2** — `PLUGIN_NAME` was extracted and used in JSON output before name-regex validation. A malformed name could taint pre-validation events. Fixed by regex-checking before adoption.
- [x] **L3** — Tests asserted exit codes and JSON events but never exercised the cache file content. Added a `yq`-based assertion that reads the cache file and verifies full-manifest contract.
- [x] **L4** — `lib/version.sh::get_devrail_version` silently fell through to `"0.0.0-dev"` (lenient mode) when `/opt/devrail/VERSION` existed but was unreadable. A consumer could think `devrail_min_version` was being enforced when it wasn't. Fixed by warning when the file exists but isn't readable.
- [x] **L5** — No test for `plugins: []` (empty array). Added integration case.

### Action Items

All 9 action items resolved in PR #33 (`fix/13-2-review-followups`).

- [x] [AI-Review][HIGH] H1: cache must contain full manifest content [Makefile:215-217 → fixed]
- [x] [AI-Review][HIGH] H2: manifest path must include rev [Makefile:204-205 → fixed; fixtures restructured]
- [x] [AI-Review][MED] M1: validate gates field [scripts/plugin-validator.sh → fixed]
- [x] [AI-Review][MED] M2: route events through lib/log.sh [scripts/plugin-validator.sh, lib/log.sh → fixed]
- [x] [AI-Review][LOW] L1: remove unused lib/platform.sh source [scripts/plugin-validator.sh:25 → fixed]
- [x] [AI-Review][LOW] L2: regex-validate PLUGIN_NAME before use [scripts/plugin-validator.sh:109 → fixed]
- [x] [AI-Review][LOW] L3: assert cache content in tests [tests/test-plugin-loader.sh → fixed]
- [x] [AI-Review][LOW] L4: warn on unreadable /opt/devrail/VERSION [lib/version.sh:34 → fixed]
- [x] [AI-Review][LOW] L5: test plugins:[] empty array case [tests/test-plugin-loader.sh → fixed]
