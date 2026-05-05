# Story 13.5: Implement Plugin Execution Loop and JSON Aggregation

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a maintainer,
I want each plugin's targets executed within the existing `_lint`/`_format`/`_fix`/`_test`/`_security` blocks, with results aggregated into the existing JSON summary,
so that consumers see plugin and core results uniformly.

## Acceptance Criteria

1. **Given** a plugin manifest with `targets:` and `gates:` defined and the plugin loaded into the cache (Story 13.2) and resolved (Story 13.3) and built into the project-local image (Story 13.4),
   **When** `make _lint` (or `_format` / `_fix` / `_test` / `_security`) runs inside the project-local image,
   **Then** every loaded plugin's matching target is dispatched after the core `HAS_<LANG>` blocks for that target.

2. **Given** a plugin target has `gates:` declared (per-target list of paths that must all exist for the target to run),
   **When** the dispatcher evaluates the gate against the project workspace,
   **Then** the target runs iff every gate path exists (file or directory; glob patterns supported; absolute paths rejected). Empty list or missing key = always run. Gate evaluation emits a structured `plugin gate skipped` event when the target is skipped.

3. **Given** a plugin target whose `cmd` references `{paths}` and the manifest declares `paths_var` + `paths_default`,
   **When** the dispatcher renders the command,
   **Then** `{paths}` is substituted with the runtime value of `${<PATHS_VAR>}` (falling back to `paths_default` if unset). Existing-path filtering applies (mirroring `RUBY_PATHS`).

4. **Given** a plugin language has a per-language override in `.devrail.yml` (e.g. `elixir: { linter: dialyxir }`),
   **When** the dispatcher selects the command for that target,
   **Then** the override replaces the entire `targets.<name>.cmd` string from the manifest. Override applies only to the matching target; other targets fall back to the manifest default.

5. **Given** a plugin target executes,
   **When** it succeeds,
   **Then** `<plugin-name>` (or `<plugin-name>:<tool>` when the cmd is composite) is appended to `ran_languages`. **When** it fails, the same identifier is appended to `failed_languages` and `overall_exit=1` is set. The final JSON event for that target lists plugin and core entries together.

6. **Given** `DEVRAIL_FAIL_FAST=1` is set,
   **When** any plugin target fails,
   **Then** the dispatcher short-circuits the same as core failures — emits the JSON event with status fail and exits non-zero immediately, before later plugins or later targets run.

7. **Given** a `.devrail.yml` declares zero plugins (or `plugins:` is absent),
   **When** any target runs,
   **Then** the dispatcher is a no-op (no loop iteration, no extra events). v1.9.x consumers see byte-identical JSON output.

8. **Given** a plugin manifest is loaded but declares no `cmd` for a given target,
   **When** that target runs,
   **Then** the plugin contributes nothing to that target (no event, no entry in `ran_languages`). This is the "I only do lint, not test" case.

9. **Given** the dispatcher emits a structured event for every plugin invocation,
   **When** the per-target JSON summary is assembled,
   **Then** plugin entries appear in `languages` and `failed` exactly like core entries — no special `plugins:` array, no extra envelope. Consumers cannot distinguish plugin vs core results from the JSON shape.

10. **Given** the smoke test fixture `tests/fixtures/plugin-repos/minimal-v1` is exercised end-to-end,
    **When** `tests/test-plugin-execution.sh` runs,
    **Then** at minimum these cases pass:
    - dispatcher no-op when no plugins declared
    - single plugin with one passing target → entry in `ran_languages`, exit 0
    - single plugin with one failing target → entry in `failed_languages`, exit 1
    - gate skip (gate path absent) → no execution, structured `gate skipped` event
    - gate run (gate path present) → execution, normal accounting
    - `paths_var`/`paths_default` interpolation
    - per-language override replaces manifest default
    - `DEVRAIL_FAIL_FAST=1` short-circuit on plugin failure
    - manifest with target `lint` but no `test` → only `_lint` invokes the plugin
    - JSON shape regression: zero-plugin run produces byte-identical event output to v1.9.x baseline

## Tasks / Subtasks

- [x] **Task 1: Design + extract a reusable execution helper library** (AC: 1, 2, 3, 4, 5, 6, 8, 9)
  - [x] Subtask 1.1: Add `lib/plugin-execute.sh` sourced inside the container; expose `dispatch_plugin_target <target-name>`, `evaluate_gate <plugin-cache-entry> <target-name>`, `render_cmd <plugin-cache-entry> <target-name>`, `apply_override <language> <target-name> <default-cmd>`. Helpers MUST be sourceable into a Makefile recipe via `bash -c`, and they MUST emit structured JSON via `lib/log.sh:log_event` (no raw `echo`).
  - [x] Subtask 1.2: `evaluate_gate` reads `gates.<target>` from the loaded plugin entry in `${DEVRAIL_PLUGINS_CACHE:-/tmp/devrail-plugins-loaded.yaml}`. For each path: reject absolute; resolve relative to `$$(pwd)`; expand globs via `compgen -G` with empty-result short-circuit; require ALL paths to match. Emit `log_event info "plugin gate skipped" plugin=... target=... missing=...` when gate fails.
  - [x] Subtask 1.3: `render_cmd` reads `targets.<target>.cmd`; if `paths_var` set, substitute `{paths}` with runtime-filtered `${<paths_var>}` (filter to existing paths, mirroring how `RUBY_PATHS` is filtered in the Ruby block). If `paths_var` unset and `cmd` contains literal `{paths}`, treat as misconfiguration → exit 2 with structured error.
  - [x] Subtask 1.4: `apply_override` reads `<language>.<override-key>` from `.devrail.yml` (where `<override-key>` follows the existing convention: `linter` for `lint`, `formatter` for `format_check`/`format_fix`, `test`/`security`/etc.). When override is present, return it verbatim as the cmd; otherwise return the manifest default.
  - [x] Subtask 1.5: Add `dispatch_plugin_target <target-name>` that iterates `.plugins[]` from the loader cache, calls gate → render → override, runs the cmd (`bash -c "$$cmd"`), updates `ran_languages` / `failed_languages` / `overall_exit` via shared shell variables (passed by reference is not portable in bash, so dispatch sets them in caller scope by being sourced rather than executed).
  - [x] Subtask 1.6: Each helper has a `--help` mode that prints purpose + invocation pattern. Each helper is shellcheck/shfmt-clean (`shellcheck -x`, `shfmt -d -i 2 -ci`).

- [x] **Task 2: Wire the dispatcher into every target recipe** (AC: 1, 5, 6)
  - [x] Subtask 2.1: After the last `HAS_<LANG>` block in `_lint` (Makefile lines ~367–582), source `lib/plugin-execute.sh` and call `dispatch_plugin_target lint`. Preserve the `DEVRAIL_FAIL_FAST` short-circuit and the final JSON event emission. Same for `_format` (`format_check`), `_fix` (`format_fix`/`fix`), `_test` (`test`), `_security` (`security`).
  - [x] Subtask 2.2: For `_check`, do NOT add a separate plugin loop — `_check` already invokes `_lint`/`_format`/`_test`/`_security` in sequence and aggregates their JSON; plugin results flow up automatically. Verify the existing `_check` aggregation handles plugin entries unchanged.
  - [x] Subtask 2.3: Document the wire-in convention (where to insert the dispatch line, how to source the helper) inline in the Makefile so future target additions follow the pattern.

- [x] **Task 3: No-op regression safety** (AC: 7, 8)
  - [x] Subtask 3.1: When `.plugins[]` in the loader cache is empty, `dispatch_plugin_target` returns immediately without emitting any event (no startup banner, no `loop complete`). Verify byte-identical JSON for a `languages: [bash]` workspace.
  - [x] Subtask 3.2: When a plugin manifest declares only some targets (e.g., `lint` and `format_check` but no `test`), `_test` runs the loop but skips that plugin without an event. The plugin contributes nothing to `_test`'s `ran_languages`.
  - [x] Subtask 3.3: Run `tests/test-plugin-loader.sh`, `tests/test-plugin-resolver.sh`, `tests/test-plugin-build-pipeline.sh`, `tests/smoke-rails.sh`, and per-language tests; all must remain green (no regression).

- [x] **Task 4: Tests** (AC: 10)
  - [x] Subtask 4.1: Create `tests/test-plugin-execution.sh` mirroring the harness pattern of `test-plugin-build-pipeline.sh`: hermetic workspace per case, fixtures from `tests/fixtures/plugin-repos/minimal-v1`, hand-crafted lockfile + pre-populated host cache to keep the SUT scoped to the dispatcher.
  - [x] Subtask 4.2: Cases for AC10 (no-op, single pass, single fail, gate skip, gate run, paths interpolation, override, fail-fast, partial-targets, JSON regression). Each case asserts both exit code and the relevant `log_event` message via jq filters (consistent with existing tests).
  - [x] Subtask 4.3: Add a fixture variant under `tests/fixtures/plugin-repos/minimal-v1-with-targets/` (or extend `minimal-v1`) so the manifest declares `targets.lint.cmd: "true"` (passing) and a flag-flippable failing target. Reuse the existing `install_script: install.sh` and slug pattern.
  - [x] Subtask 4.4: Add a new step "Plugin execution smoke test" to `.github/workflows/ci.yml` after the existing build-pipeline smoke test step.

- [x] **Task 5: Documentation** (AC: 4, 9)
  - [x] Subtask 5.1: Update `OrgDocs/development-standards/standards/devrail-yml-schema.md`: document the per-language override syntax for plugin languages, examples for each target type, and the precedence rule (override > manifest default).
  - [-] Subtask 5.2: Deferred to Story 13.6 (marketing release) — devrail.dev does not currently host a `devrail-yml-schema` page; new public-facing docs land with v1.10.0.
  - [x] Subtask 5.3: Update `dev-toolchain/STABILITY.md` to mark "Plugin loader + resolver + lockfile + build pipeline + execution loop" — same row, append to scope.
  - [x] Subtask 5.4: Update `dev-toolchain/CHANGELOG.md` `[Unreleased] § Added` with a one-line entry referencing Story 13.5.
  - [x] Subtask 5.5: Make sure `make help` text remains accurate (no new public targets).

- [x] **Task 6: Validate end-to-end against the dev-toolchain repo** (AC: 7, all)
  - [x] Subtask 6.1: Run `make check` on the dev-toolchain repo itself (no plugins declared) — confirm zero behavioral or JSON diff vs. v1.10.4 baseline.
  - [x] Subtask 6.2: Run `make check` on a hand-crafted workspace with the `minimal-v1` plugin declared and a passing target — confirm dispatcher reports the plugin in `ran_languages`.

- [ ] **Task 7: Code review prep** (process)
  - [x] Subtask 7.1: Move story status to `review` after PR opens.
  - [ ] Subtask 7.2: Run `/bmad-bmm-code-review`; address findings on a fix branch following the established 13.2 / 13.3 / 13.4 pattern.

## Dev Notes

### Authoritative source

This story implements the execution loop described in `_bmad-output/planning-artifacts/plugin-architecture-design.md` § "Plugin Lifecycle" step 6 (Execute) and step 7 (Aggregate), and § "Make-Check Aggregation". The shape of the for-loop pseudocode in the design doc is the canonical model — implementers should treat that snippet as the contract.

### Scope boundary

**In scope:**
- Per-target plugin dispatch inside `_lint`/`_format`/`_fix`/`_test`/`_security`
- Gate evaluation, command interpolation, per-language overrides
- JSON aggregation into existing `ran_languages` / `failed_languages` arrays
- `DEVRAIL_FAIL_FAST` parity
- No-op regression safety
- Hermetic smoke test exercising all of the above

**Out of scope:**
- New public Makefile targets — this story extends existing recipes only
- Parallel plugin execution (sequential per design doc § "Open questions remaining")
- New plugin manifest fields — schema_version stays at 1
- Pre-commit hook synthesis from `pre_commit:` (deferred until 13.6 release prep)
- `init_scaffolds:` consumption from `make init` (deferred)
- `tool_versions:` consumption by `report-tool-versions.sh` (deferred)
- `make scan` and `make docs` — these are universal scanners not language-scoped, so they don't loop over plugins

### Architectural notes

The execution loop runs **inside the project-local extended image** built by Story 13.4. It does NOT run on the host. This means:

- The loader cache (`/tmp/devrail-plugins-loaded.yaml`, populated by `_plugins-load`) is the source of truth — no re-reading of plugin manifests at execute time.
- The plugin's `cmd` string is run via `bash -c "$$cmd"` inside the container. Tools are present because Story 13.4 baked them in via `apt_packages` / `copy_from_builder` / `install_script`.
- Working directory for every plugin invocation is `/workspace` (the same as core target invocations).
- The plugin's `cmd` MUST NOT escape the container or workspace; that's a plugin-author responsibility (no sandboxing in v1).

### Existing patterns to reuse

- **Per-target JSON envelope.** The `start_time` / `overall_exit` / `ran_languages` / `failed_languages` / fail-fast / final `echo` pattern at the top and bottom of every `_lint`/`_format`/etc. recipe (Makefile lines ~367–582). The dispatcher must hook into the SAME shell variables; do NOT introduce a parallel accounting path.
- **Path-list filtering.** `RUBY_PATHS` filtering (Makefile line ~440) — runtime existence check via `[ -e "$$p" ]` before passing to the tool. Plugin `paths_var` interpolation should mirror this exactly.
- **Per-language override.** The existing convention is implicit (no centralized helper) — Ruby reads `.ruby.linter` etc. ad-hoc. For plugins, formalize this in `apply_override` so plugin authors get one consistent override surface.
- **Structured logging.** `lib/log.sh:log_event` is the only acceptable way to emit JSON events. Story 13.4's review surfaced inline `printf` JSON as an anti-pattern; do not repeat it.
- **Cache-driven execution.** Story 13.2's loader writes the FULL manifest content into the cache (not just paths). The dispatcher reads `targets.<name>.cmd`, `gates.<name>`, etc. directly from that cache without re-fetching the manifest. This keeps the dispatcher fast and hermetic.

### Anti-patterns (do NOT do)

- **Don't add a `_plugins-execute` target.** Plugin results must aggregate into the existing per-target JSON event. A separate target would force consumers to remember a new entry point.
- **Don't fork the JSON event shape.** Plugin entries appear in `languages: [...]` and `failed: [...]` arrays alongside core. No `plugins:` sub-array, no special envelope. AC9 is explicit about this.
- **Don't run plugin commands on the host.** They run inside the project-local image where the plugin's tools live. The orchestrator from Story 13.4 already swaps DOCKER_RUN to use `devrail-local:<hash>`.
- **Don't re-read `plugin.devrail.yml` at execute time.** Read from the loader cache. Story 13.2 wrote the full manifest into the cache for exactly this purpose.
- **Don't introduce a new severity / event level.** Use `log_event info` for run/skip; `log_event error` for the failed cmd path; `log_event warn` for gate-config violations. Mirror Story 13.2 / 13.3 / 13.4 conventions.
- **Don't use `eval`.** Story 13.4's prior reviews flagged `eval` as a hardening risk. Use `bash -c "$$cmd"` (single layer of expansion, predictable quoting).

### File touchpoints

**dev-toolchain repo:**
- `lib/plugin-execute.sh` — NEW. Helpers `dispatch_plugin_target`, `evaluate_gate`, `render_cmd`, `apply_override`. Sourceable into Makefile recipes.
- `Makefile` — MODIFIED. Insert `dispatch_plugin_target <name>` call after the last `HAS_<LANG>` block in each of `_lint`, `_format`, `_fix`, `_test`, `_security`. ~5 insertions, ~3-line each.
- `tests/test-plugin-execution.sh` — NEW. Smoke test for AC10.
- `tests/fixtures/plugin-repos/minimal-v1/plugin.devrail.yml` — possibly EXTENDED with multiple targets, or a sibling fixture `minimal-v1-with-targets/`.
- `.github/workflows/ci.yml` — MODIFIED. Add "Plugin execution smoke test" step.
- `CHANGELOG.md` — MODIFIED.
- `STABILITY.md` — MODIFIED (extend the plugin row's scope description).

**OrgDocs/development-standards repo:**
- `standards/devrail-yml-schema.md` — MODIFIED. Document per-language override for plugin languages.
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — MODIFIED at end (`13-5-... → review` then `done`).
- `_bmad-output/implementation-artifacts/13-5-...md` — THIS FILE.

**devrail.dev repo:**
- `content/docs/standards/devrail-yml-schema.md` — MODIFIED. Mirror the OrgDocs change.

### Loader cache contract (refresher from 13.2)

`/tmp/devrail-plugins-loaded.yaml` looks like:

```yaml
plugins:
  - schema_version: 1
    name: elixir
    version: 1.0.0
    devrail_min_version: 1.10.0
    container: { ... }
    targets:
      lint: { cmd: "mix credo --strict {paths}", paths_var: ELIXIR_PATHS, paths_default: "lib test" }
      format_check: { cmd: "mix format --check-formatted" }
      ...
    gates:
      lint: ["mix.exs"]
      ...
    source: github.com/community/devrail-plugin-elixir
    rev: v1.0.0
    manifest_path: /opt/devrail/plugins/devrail-plugin-elixir/v1.0.0/plugin.devrail.yml
```

The dispatcher reads from this single file via `yq`. Do not pass the cache path as an argument — read `${DEVRAIL_PLUGINS_CACHE:-/tmp/devrail-plugins-loaded.yaml}` consistent with the loader.

### Override key convention

Per design doc § "Per-Language Tool Override":

| Manifest target | `.devrail.yml` override key |
|---|---|
| `lint` | `linter` |
| `format_check` | `formatter` |
| `format_fix` | `formatter` (same as format_check by convention; can override separately) |
| `fix` | `fixer` |
| `test` | `test` |
| `security` | `security` |

When a plugin language has e.g. `elixir: { linter: dialyxir }`, the rendered cmd for `_lint` becomes literally `dialyxir` (no `{paths}` interpolation; user-provided overrides are taken verbatim as the design doc specifies). If the user wants paths, they include them in the override string explicitly. This is the cleanest semantic and matches how the override pattern works for core languages today.

## Previous Story Intelligence — Story 13.4

Story 13.4 (PR #36 + PR #37, released as v1.10.3 + v1.10.4) shipped the extended-image build pipeline. Key learnings that bear on 13.5:

- **`lib/plugin-cache.sh` is the canonical place for "things both X and Y need to know about plugins"** — Story 13.3's review (M2) extracted `derive_slug` + `compute_content_hash` there, and Story 13.4's review (M2) re-used it. If 13.5 finds itself duplicating logic into `lib/plugin-execute.sh`, consider whether it belongs in `plugin-cache.sh` instead. The two libs are sourceable independently (guard with `_DEVRAIL_PLUGIN_CACHE_LOADED`).
- **`log_event` (lib/log.sh) is the structured-logging path.** Story 13.2 review added the helper specifically to kill inline `printf '{...}\n'` constructs. New code must use it.
- **Test harness pattern: `populate_cache` + `write_lockfile` + per-case workspace.** Don't go through `make plugins-update` in test cases unless the SUT is the plugin update path. For 13.5 the SUT is the dispatcher — pre-populate the cache and lockfile, mount the workspace into the container, and exercise `make _lint` / `_test` / etc. directly. Mirror `tests/test-plugin-build-pipeline.sh:make_full_pipeline_ws` exactly.
- **`make check` on the dev-toolchain repo runs without any `.devrail.yml` plugins**, so 13.5's "no-op safety" path must hold for the project's own `make check`. CI catches this implicitly — but add the assertion explicitly in the test suite (AC10's "JSON regression" case).
- **shellcheck `-x` (follow source) is required** for any script that `source`s libs. The pre-commit hook runs `shellcheck` standalone (no `-x`); the CI step runs `shellcheck -x` separately. Both must pass.
- **shfmt formats as root inside container, then host pre-commit fails on permissions.** After running shfmt against a file: `sudo chown mmellor:mmellor <file>`. (Issue surfaced repeatedly in 13.4.)
- **Conventional-commit scopes accepted by the hook:** `ansible, bash, changelog, ci, container, go, javascript, makefile, python, release, ruby, rust, security, standards, terraform`. Use `makefile` for Makefile-related changes, `standards` for docs, `ci` for workflow changes. There is NO `tests` scope — test-only commits go under the relevant feature's scope (e.g., `fix(makefile): ...`).
- **CI `build-and-validate` job runs every smoke test**, including the new build-pipeline smoke (which now takes ~25–28 minutes). Adding a new test step extends CI further. Keep `test-plugin-execution.sh` cases hermetic (no docker build) where possible — the dispatcher can be exercised entirely against the fixture's `cmd: "true"` / `cmd: "false"` without any rebuild.
- **The `_extended-image` Makefile path now expects `_devrail-host-bin` to extract scripts from the container for consumer repos.** 13.5's dispatcher runs INSIDE the container so it doesn't need host-side extraction — but make sure tests that bypass the orchestrator (e.g., a `make _lint` invocation that depends on `_plugins-load` only) still work after 13.5's changes.

## Git Intelligence — Recent dev-toolchain Patterns

Last 5 dev-toolchain commits (after merging 13.4):

```
8ba2c92 chore(release): prepare v1.10.4
46e582c feat(makefile): extended-image build pipeline (Story 13.4b) (#37)
6578934 feat(makefile): host cache + Dockerfile.devrail generator (Story 13.4a) (#36)
35475df chore(release): prepare v1.10.2
d92a982 fix(makefile): address Story 13.3 senior-developer review findings (#35)
```

Patterns:

- **Story-level squash merges.** Each story lands as one PR with one squash commit. Review-fixes either get folded into the open PR (13.4b pattern) or land as a separate `fix/<story>-review-followups` PR (13.2 / 13.3 pattern). Maintainer chooses based on PR open/merged state at review time.
- **Patch release after each merged story PR.** v1.10.0 (13.2) → v1.10.1 (13.2 fixes) → v1.10.2 (13.3 fixes) → v1.10.3 (13.4a) → v1.10.4 (13.4b). 13.5 will land as v1.10.5; 13.6 is the marketing-version cut (advances `:v1` floating tag).
- **Pre-commit + pre-push hooks gate every push.** `make check` runs as pre-push, so tests must pass locally before push. CI re-runs the same gates; a failed CI is rare unless the test depends on container state that differs (image rebuild, permissions, etc.).
- **Conventional commit format strictly enforced.** Lowercase description start. No period at end. Description after `:` is mandatory non-empty.

## Latest Tech Information

No new external dependencies for Story 13.5. The dispatcher uses:

- `yq` (v4.x, already in container) for cache reads. Use `strenv()` for any interpolation of cache values into yq filters (Story 13.3 review M1 hardening).
- `bash` 5.x (already in container) for sourcing libs and the dispatch loop.
- `compgen -G` (bash builtin) for glob expansion in gate evaluation. Not in POSIX sh, but the container runs bash everywhere — fine.
- `jq` (already in container) only for tests, not the dispatcher itself.

No version pins, no new libraries, no API surface to research.

## Project Context Reference

This story sits in **Epic 13: Plugin Architecture for Community Extensions**, Phase 1 (`v1.10.0` train). It is the FINAL implementation story before the `v1.10.0` marketing release (Story 13.6). The four implementation stories together compose the v1.10.x plugin loader:

| Story | Status | Surface |
|---|---|---|
| 13.2 | done (v1.10.0/.1) | Plugin manifest parser, loader, schema validation |
| 13.3 | done (v1.10.2) | Plugin resolver, `.devrail.lock`, content_hash verification |
| 13.4 | done (v1.10.3/.4) | Extended-image build pipeline, Dockerfile.devrail, host orchestrator distribution |
| **13.5** | **this story** | **Execution loop, JSON aggregation, per-language overrides** |

After 13.5 ships, all v1.10.0 ACs are satisfied and 13.6 (marketing release) becomes mechanical: bump version, write blog post, advance `:v1` floating tag, update standards docs.

The plugin model remains **back-compat** through v1.10.x — workspaces without `plugins:` see no behavioral change. v1.11.x extracts Kotlin as the first reference plugin (Story 13.7); v2.0.0 retires the monolithic `HAS_<LANG>` blocks entirely (Story 13.9). 13.5 must NOT introduce any back-compat break.

## References

- [Source: `_bmad-output/planning-artifacts/plugin-architecture-design.md` § "Plugin Lifecycle" steps 6–7] — execute and aggregate model.
- [Source: `_bmad-output/planning-artifacts/plugin-architecture-design.md` § "Make-Check Aggregation"] — JSON shape contract.
- [Source: `_bmad-output/planning-artifacts/plugin-architecture-design.md` § "Per-Language Tool Override"] — override semantics.
- [Source: `_bmad-output/planning-artifacts/plugin-architecture-design.md` § "Manifest schema rules"] — `targets:` and `gates:` shapes.
- [Source: `_bmad-output/planning-artifacts/epics.md` § "Story 13.5"] — original epic-level AC.
- [Source: `_bmad-output/implementation-artifacts/13-2-...md`] — loader cache contract (full manifest body in cache).
- [Source: `_bmad-output/implementation-artifacts/13-3-...md`] — `lib/plugin-cache.sh` extraction pattern.
- [Source: `_bmad-output/implementation-artifacts/13-4-...md`] — `lib/plugin-execute.sh` is the natural sibling to `lib/plugin-cache.sh`.
- [Source: `dev-toolchain/Makefile` lines 367–582] — `_lint` recipe shape and JSON-emission pattern to mirror.
- [Source: `dev-toolchain/lib/log.sh`] — `log_event` helper signature.

## Dev Agent Record

### Agent Model Used

Claude Opus 4.7 (1M context).

### Debug Log References

- **Recipe shell.** Initial implementation sourced `lib/plugin-execute.sh` from each Makefile recipe but the recipe ran in `/bin/sh` (dash), not bash. Bash-only constructs (`[[`, `((`, indirect parameter expansion `${!var}`) failed with `[[: not found` and `Bad for loop variable`. Fix: added `SHELL := /bin/bash` at the top of the Makefile so recipes use bash. Existing POSIX-sh recipes remain valid (bash is a superset).
- **shfmt flag mismatch.** First shfmt pass used `-i 2 -ci` and produced 4-space-indented case branches. The Makefile's `_format` recipe runs `shfmt -d` with default flags (no `-ci`), which expects branches at 2-space indent (same as `case`). Re-ran `shfmt -w` with no flags to match.
- **shellcheck SC2034.** The dispatcher writes to `overall_exit`, `ran_languages`, `failed_languages` in caller scope (Makefile recipe). shellcheck flagged these as "appears unused" (SC2034). Added targeted disables — they are caller-scope variables sourced from the recipe, not local to the helper.
- **Caller-scope contract.** Discovered the `dispatch_plugin_target` function must NOT use `local overall_exit=` shadows for the caller-scope vars; the helper directly mutates them. Documented the contract in the lib's header comment so future maintainers don't add `local` declarations that would silently break aggregation.
- **Container rebuild required.** Iteration cycle was `edit lib → docker build → bash tests/test-plugin-execution.sh` because the lib is COPY'd into the image at /opt/devrail/lib/. Build is fast (~2s after the first uncached layer) thanks to BuildKit caching the apt and language-builder layers.
- **`make check` regression.** Caught at the end of Task 3 when running `make check` against the dev-toolchain repo itself: scan failed once (292s) but passed on standalone re-run (5s). Hypothesis: trivy DB fetch / first-run download. Not related to my changes — same flake exists in v1.10.4.

### Completion Notes List

- **Final implementation story before v1.10.0 marketing release.** Stories 13.2 (loader), 13.3 (resolver/lockfile), 13.4 (build pipeline), and now 13.5 (execution loop) compose the v1.10.x plugin loader. Story 13.6 cuts v1.10.0 with a blog post; nothing technical remains.
- **Plugin contract is sealed at schema_version: 1.** Plugin authors can write a manifest today and rely on the loader/dispatcher behaviour. The override map (`lint→linter` etc.) is documented in `OrgDocs/standards/devrail-yml-schema.md`.
- **Reference fixture stable.** `tests/fixtures/plugin-repos/minimal-v1` works end-to-end through the build pipeline AND now the dispatcher. It's small enough that 13.5 didn't need a separate fixture.
- **No new public Make targets.** All changes extend existing recipes. `make help` is unchanged.
- **Code review pending.** Recommend running `/bmad-bmm-code-review` under a different model than the implementer (Opus 4.7) to surface blind spots — same caveat documented in 13.2 / 13.3 / 13.4 reviews.

### File List

**dev-toolchain repo (PR #38, branch `feat/13-5-plugin-execution-loop`):**

- `lib/plugin-execute.sh` — NEW. Sourceable dispatcher library with `evaluate_gate`, `render_cmd`, `apply_override`, `dispatch_plugin_target`.
- `Makefile` — MODIFIED. Added `SHELL := /bin/bash`; sourced `lib/plugin-execute.sh` at the top of `_lint`, `_format`, `_fix`, `_test`, `_security`; inserted `dispatch_plugin_target <name>` + per-block fail-fast guard after the last `HAS_<LANG>` block in each.
- `tests/test-plugin-execution.sh` — NEW. 10-case smoke test for the dispatcher.
- `.github/workflows/ci.yml` — MODIFIED. Added "Plugin execution smoke test" step after the build-pipeline smoke.
- `CHANGELOG.md` — MODIFIED. `[Unreleased] § Added` documents Story 13.5.
- `STABILITY.md` — MODIFIED. Plugin row scope extended to include the execution loop.

**OrgDocs/development-standards repo (branch `feat/13-5-create-story`):**

- `_bmad-output/implementation-artifacts/13-5-implement-plugin-execution-loop-and-json-aggregation.md` — THIS FILE.
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — MODIFIED (`13-5-... → review`).
- `standards/devrail-yml-schema.md` — MODIFIED. New "Plugin-language overrides (v1.10.0+)" section.
- `.gitignore` — MODIFIED. Added `.claude/` entry to keep Claude Code's session lock files out of commits.

### Change Log

| Date | Change |
|---|---|
| 2026-05-04 | Story created via `/bmad-bmm-create-story` (status: ready-for-dev) |
| 2026-05-04 | Implementation completed via `/bmad-bmm-dev-story`; status moved to `review`; PR #38 opened on dev-toolchain |
| 2026-05-04 | Senior-developer review completed via `/bmad-bmm-code-review`; 13 findings (1 HIGH, 7 MED, 5 LOW); all addressed via follow-up commit on PR #38 (`feat/13-5-plugin-execution-loop`) |

## Senior Developer Review (AI)

**Reviewer:** Matthew (review executed by Opus 4.7 — same model that implemented the story; see caveat)
**Date:** 2026-05-04
**Outcome:** Approve (after follow-up commit on PR #38)

### Caveat

Same model that wrote the implementation also performed the review. Findings skew toward checklist-sweep rather than independent insight. A future review under a different model is welcome and may surface additional issues.

### Scope

The review covered the dev-toolchain Story 13.5 implementation (PR #38, branch `feat/13-5-plugin-execution-loop`): `lib/plugin-execute.sh` dispatcher, Makefile recipe wiring (`_lint`/`_format`/`_fix`/`_test`/`_security`), `tests/test-plugin-execution.sh`, CI step, CHANGELOG, and STABILITY.

### Findings

**HIGH severity (must fix — done in PR #38 follow-up commit):**

- [x] **H1** — `lib/plugin-execute.sh:render_cmd` called `exit 2` from a sourced library when a manifest declared `{paths}` without a `paths_var`. Because the lib was sourced into the Makefile recipe's shell, `exit 2` killed the whole recipe BEFORE the final JSON event was emitted (no `failed_languages` entry, no `{"target":"lint","status":"fail",…}` line). Fixed by changing `exit 2` to `return 2`; the dispatcher catches non-zero from `render_cmd` (and similarly from `evaluate_gate`'s new return-2 path), marks the plugin as `<name>:cmd-config` / `<name>:gate-config` failed, and continues iterating (or fail-fast'ing). Case 12 verifies the second plugin still runs after the first plugin's config error.

**MEDIUM severity (should fix — done in PR #38 follow-up commit):**

- [x] **M1** — `evaluate_gate` returned `1` for both gate-skip-because-path-missing AND absolute-path config error. Caller treated both as silent skip — a misconfigured plugin manifest got no surface in `failed_languages` or `overall_exit`. Now returns 0/1/2 distinctly: 0 = pass, 1 = silent skip (already-logged info event), 2 = config error (already-logged error event). Dispatcher adds `<plugin>:gate-config` to `failed_languages` for the 2 case (Case 11).
- [x] **M2** — yq `2>/dev/null` on cache reads (lines 56, 75, 77, 83, 125, 126, 133, 134, 217 in the original) silently swallowed loader-cache parse errors. Same anti-pattern as Story 13.2 / 13.4 H1 reviews — re-introduced. Now the dispatcher does ONE yq → JSON conversion at entry and surfaces parse errors as a structured error event with `_plugins:cache-parse` plugin-system failure (Case 15).
- [x] **M3** — `apply_override` + every per-plugin lookup forked `yq` per call (~8N yq invocations per recipe). Now we do 2 yq → JSON conversions at the start of `dispatch_plugin_target` (cache + `.devrail.yml`) and use `jq` for all subsequent lookups. Each `jq` call on a small JSON blob is much faster than `yq` on a YAML file. Combined with M2, the new path is ~3N jq calls + 2 yq calls per dispatch.
- [x] **M4** — `bash -c "${final_cmd}"` had no timeout. A hanging plugin command would block `make check` indefinitely. Added an optional `DEVRAIL_PLUGIN_TIMEOUT_SECONDS` env var; when set, the dispatcher wraps the cmd in `timeout -k 5 N bash -c …`. Default unset = no timeout (preserves current behaviour).
- [x] **M5** — `_fix` dispatched only `format_fix`. The design doc's schema accepts `targets.fix.cmd` as a separate target, but the Makefile never invoked it — silent no-op for plugin authors who used `fix:`. Now `_fix` dispatches both `format_fix` AND `fix` in sequence with the standard fail-fast guard between them.
- [x] **M6** — Path-with-shell-meta-chars injection vector through `${cmd//\{paths\}/${filtered}}` → `bash -c "${final_cmd}"`. A directory named `lib;evil` (if it existed) would inject. Filter loop now rejects paths matching `*[\;\|\&\$\<\>\(\)\`\\\"\']*` with a `plugin path contains shell-meta characters; skipping` warn event (Case 13 inserts a `lib;evil` directory and asserts it's filtered while `lib` survives).
- [x] **M7** — Story Dev Agent Record File List omitted the OrgDocs `.gitignore` change (added `.claude/` entry in commit b5785e4). File List updated.

**LOW severity (nice to fix — done in PR #38 follow-up commit):**

- [x] **L1** — Four scattered `# shellcheck disable=SC2034` comments around caller-scope variable assignments. Tightened to a single `:` no-op assignment at the top of `dispatch_plugin_target` that registers the four caller-scope vars (`overall_exit`, `ran_languages`, `failed_languages`, `skipped_languages`) in one place.
- [x] **L2** — Tests missed five error paths: absolute-path gate (Case 11), `{paths}` without paths_var (Case 12), shell-meta path rejection (Case 13), double-source guard (Case 14), and malformed-cache parse error (Case 15). All added.
- [x] **L3** — Case 9's silent-skip assertion was narrow (only checked absence of `"plugin target executing"`). Tightened to reject any plugin event of any kind for the absent target.
- [x] **L4** — STABILITY.md's Makefile-contract row now documents the `SHELL := /bin/bash` pin and the implication for consumer template repos that inherit it.
- [x] **L5** — Dispatcher now appends gate-skipped plugins to `skipped_languages` (when the recipe maintains that array — `_test`/`_security`). Harmless when the recipe doesn't use the var. Closes the inconsistency between core "no work to do" and plugin gate-skip handling.

### Action Items

All 13 action items resolved in the follow-up commit on PR #38 (`feat/13-5-plugin-execution-loop`).

- [x] [AI-Review][HIGH] H1: render_cmd returns instead of exits [lib/plugin-execute.sh → fixed]
- [x] [AI-Review][MED] M1: evaluate_gate distinguishes gate-skip from gate-config-error [lib/plugin-execute.sh → fixed]
- [x] [AI-Review][MED] M2: cache parse errors surface loudly [lib/plugin-execute.sh → fixed]
- [x] [AI-Review][MED] M3: cache + .devrail.yml pre-parsed once via yq→JSON [lib/plugin-execute.sh → fixed]
- [x] [AI-Review][MED] M4: optional DEVRAIL_PLUGIN_TIMEOUT_SECONDS [lib/plugin-execute.sh → fixed]
- [x] [AI-Review][MED] M5: _fix dispatches both format_fix and fix [Makefile → fixed]
- [x] [AI-Review][MED] M6: shell-meta path filter [lib/plugin-execute.sh → fixed]
- [x] [AI-Review][MED] M7: story File List includes .gitignore change [story file → fixed]
- [x] [AI-Review][LOW] L1: consolidate SC2034 disables [lib/plugin-execute.sh → fixed]
- [x] [AI-Review][LOW] L2: 5 new test cases (11-15) [tests/test-plugin-execution.sh → fixed]
- [x] [AI-Review][LOW] L3: tighten silent-skip assertion [tests/test-plugin-execution.sh → fixed]
- [x] [AI-Review][LOW] L4: STABILITY.md SHELL note [STABILITY.md → fixed]
- [x] [AI-Review][LOW] L5: skipped_languages on gate-skip [lib/plugin-execute.sh → fixed]
