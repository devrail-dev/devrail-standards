# Story 13.2: Implement Plugin Manifest Parser and Loader

Status: ready-for-dev

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

- [ ] **Task 1: Schema validator script** (AC: 2, 4)
  - [ ] 1.1 Create `scripts/plugin-validator.sh`. Sources `lib/log.sh` and `lib/platform.sh` per existing convention. Header in the project's standard format (purpose, usage, deps).
  - [ ] 1.2 Implement `validate_manifest <path>` function. Uses `yq` (already in image, v4.44.1) to parse. Validates required fields exist and types match (`schema_version: int`, `name: string`, `version: string`, `devrail_min_version: string`, `targets: mapping`).
  - [ ] 1.3 Validate field constraints: `schema_version == 1`; `name` matches `^[a-z][a-z0-9_-]*$`; `version` and `devrail_min_version` are dotted-numeric semver (`^[0-9]+\.[0-9]+\.[0-9]+$`).
  - [ ] 1.4 Validate at least one of `lint`/`format_check`/`format_fix`/`fix`/`test`/`security` exists in `targets:`.
  - [ ] 1.5 Each violation calls `log_error` with structured fields: `{"level":"error","msg":"plugin schema violation","plugin":"<name>","field":"<path>","reason":"<reason>","language":"_plugins"}`.
  - [ ] 1.6 Return non-zero on any violation; cumulative — report ALL violations, don't fail-fast on the first one (consumers want full feedback in one run).
  - [ ] 1.7 Idempotent and re-runnable. No filesystem mutations except optional cache write (Task 3).

- [ ] **Task 2: Version comparison helper** (AC: 3)
  - [ ] 2.1 Add `version_gte <a> <b>` to `lib/platform.sh` (or `lib/version.sh` if cleaner) — returns 0 if `a >= b` semver-wise. Pure bash, no external deps.
  - [ ] 2.2 Image version detection: read `DEVRAIL_VERSION` env first; if empty, read OCI label `org.opencontainers.image.version` from `/etc/os-release`-equivalent or `/opt/devrail/VERSION` (whichever the existing release script writes — verify in `scripts/release.sh`).
  - [ ] 2.3 Validator calls `version_gte "$IMAGE_VERSION" "$MANIFEST_MIN"`; on false, emits structured error and increments violation count.

- [ ] **Task 3: Loader prelude in Makefile** (AC: 1, 5, 6)
  - [ ] 3.1 Add `_plugins-load` internal target. Reads `.devrail.yml` `plugins:` via `yq`. For each entry, expects `plugin.devrail.yml` at a deterministic local path: `/opt/devrail/plugins/<source-slug>/<rev>/plugin.devrail.yml` (Story 13.3 will populate this; Story 13.2 only consumes it).
  - [ ] 3.2 If `plugins:` is absent or empty, emit `{"level":"info","msg":"no plugins declared","language":"_plugins"}` and exit 0.
  - [ ] 3.3 For each plugin, invoke `bash /opt/devrail/scripts/plugin-validator.sh <manifest-path>`.
  - [ ] 3.4 Aggregate validator exit codes. Any non-zero → `_plugins-load` exits with code `2`.
  - [ ] 3.5 On success, write a parsed cache to `/tmp/devrail-plugins-loaded.yaml` (or similar) — a yq-flattened map of plugin name → manifest contents — for Story 13.5's execution loop.
  - [ ] 3.6 Wire `_plugins-load` as a dependency of `_check`, `_lint`, `_format`, `_fix`, `_test`, `_security`. Each must invoke `_plugins-load` before its language blocks. Use Make's prerequisite mechanism so it runs once per `make` invocation, not once per target.
  - [ ] 3.7 Emit summary event on completion: `{"level":"info","msg":"plugin loader complete","loaded":<N>,"failed":<M>,"plugins":[...],"language":"_plugins"}`.

- [ ] **Task 4: Test fixtures** (AC: 7)
  - [ ] 4.1 `tests/fixtures/plugins/valid-elixir/plugin.devrail.yml` — happy path, mirrors the design doc's Elixir example (minimal — just `schema_version`, `name`, `version`, `devrail_min_version: 1.10.0`, `targets.lint.cmd`, `gates.lint`).
  - [ ] 4.2 `tests/fixtures/plugins/invalid-schema/plugin.devrail.yml` — `schema_version: 2`.
  - [ ] 4.3 `tests/fixtures/plugins/incompatible-version/plugin.devrail.yml` — `devrail_min_version: 99.0.0`.
  - [ ] 4.4 `tests/fixtures/plugins/bad-name/plugin.devrail.yml` — `name: Elixir` (uppercase, violates regex).
  - [ ] 4.5 `tests/fixtures/plugins/missing-field/plugin.devrail.yml` — omits `targets:`.
  - [ ] 4.6 Each fixture is the *manifest only* — no install scripts, no container fragments. Story 13.2 doesn't consume those.

- [ ] **Task 5: Smoke test script** (AC: 7)
  - [ ] 5.1 Create `tests/test-plugin-loader.sh`. Pattern: mirrors `tests/smoke-rails.sh` (mktemp fixture dir, docker-cleanup trap, structured pass/fail output).
  - [ ] 5.2 For each fixture, build a synthetic `.devrail.yml` referencing it and run `bash scripts/plugin-validator.sh <fixture>` directly (don't depend on the full Makefile loader for unit-level tests).
  - [ ] 5.3 Then exercise the full loader: run `make _plugins-load` against a workspace whose `.devrail.yml` declares a plugin pointing at a checked-in fixture path, verify exit code and JSON event signature.
  - [ ] 5.4 Cover the no-`plugins:`-section case to lock in regression safety (AC 6).
  - [ ] 5.5 Tests assert specific JSON fields (`level`, `msg`, `language`, plugin name) using `jq`. No string-matching of full lines (brittle).

- [ ] **Task 6: Wire smoke test into CI** (AC: 7)
  - [ ] 6.1 Add a step to `.github/workflows/ci.yml` after the existing `Rails 7+ smoke test` step, mirroring its structure: `bash tests/test-plugin-loader.sh`.
  - [ ] 6.2 Update `tests/smoke-rails.sh`'s header docstring to add issue references if any are filed for plugin loader regressions later (out of scope for this story; just leave the comment block consistent with `smoke-rails.sh`'s style).

- [ ] **Task 7: Documentation** (AC: 1, 6)
  - [ ] 7.1 Add a `## Plugin Loader (post-Story 13.2)` subsection to `dev-toolchain/STABILITY.md` (or `README.md` if a more visible spot is preferred) noting that the loader exists, runs as a prelude, and that without `plugins:` in `.devrail.yml` behavior is unchanged.
  - [ ] 7.2 No changes yet to `standards/devrail-yml-schema.md` — Story 13.6 (the v1.10.0 release-prep story) bundles all schema/standards-doc updates into one MR. **Do not** preemptively add a `plugins:` section to the schema doc in this story; it will conflict with 13.6's MR scope.
  - [ ] 7.3 CHANGELOG.md entry under `[Unreleased]` → `### Added`: a one-line note about the plugin loader prelude landing.

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

(populated by dev agent at implementation time)

### Debug Log References

### Completion Notes List

- Ultimate context engine analysis completed — comprehensive developer guide created. Story 13.2 is the foundational v1.10.0 plugin-loader story; downstream stories 13.3–13.6 depend on its parser/loader contract. Scope boundaries explicitly drawn against 13.3 (fetcher) and 13.5 (executor) so the dev agent doesn't bleed work across stories.

### File List
