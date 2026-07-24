# Story 15.1: Autodetect Project Roots for Python & JavaScript Monorepos

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **developer with a Python+JS monorepo** (e.g. `api/` Python backend + `frontend/` JS/TS frontend, no manifests at repo root),
I want DevRail to discover each language's project root from its manifest file and run that language's tools with cwd set there,
so that local config (`frontend/tsconfig.json`, `vite.config.ts` path aliases, `api/pyproject.toml`) resolves correctly without me restructuring my repo to satisfy a tool that always assumes repo-root.

## Acceptance Criteria

1. **Given** a repo with `api/pyproject.toml` and `frontend/package.json` (no manifests at repo root)
   **When** `make lint`, `make format`, `make fix`, `make test`, or `make security` runs with no `projects:` override in `.devrail.yml`
   **Then** DevRail discovers `api/` as the Python root (via `pyproject.toml`/`setup.py`/`setup.cfg`, first match wins) and `frontend/` as the JS/TS root (via `package.json`)
   **And** each language's tools run with that directory as cwd: ruff/pytest/bandit from `api/`; eslint/tsc/prettier/vitest/`npm audit` from `frontend/`

2. **Given** the discovered `frontend/` root
   **When** eslint, tsc, and vitest run
   **Then** `frontend/tsconfig.json` is found (not "no tsconfig.json found" skip), `vite.config.ts`'s `@` path alias resolves in vitest, and eslint picks up `frontend/`'s own flat config if present

3. **Given** an explicit `projects:` override in `.devrail.yml`:
   ```yaml
   projects:
     - path: api
       languages: [python]
     - path: frontend
       languages: [javascript]
   ```
   **When** any target runs
   **Then** the override is used verbatim — autodetection is skipped entirely for languages named in `projects:`

4. **Given** a single-language repo with manifests at the root (the common case — e.g. this dev-toolchain repo itself, or any existing DevRail consumer today)
   **When** any target runs
   **Then** the discovered root is exactly `.` — output, exit codes, and JSON event shape are byte-for-byte unchanged from pre-Story-15.1 behavior (regression-safe)

5. **Given** a repo where a declared language (per `.devrail.yml` `languages:`) has **no** manifest anywhere in the tree
   **When** any target runs
   **Then** DevRail emits a structured `warn` event ("no project root found for declared language") and that language's block is skipped for that target (same as today's "no files found" skip path), rather than failing

6. **Given** discovery must run inside the container (same trust boundary as `HAS_<LANG>` detection)
   **When** implemented
   **Then** the logic lives in a new sourced `lib/project-discover.sh` helper — a function `discover_project_roots <language>` returning newline-separated root paths — invoked once per language block from `_lint`/`_format`/`_fix`/`_test`/`_security`, mirroring the existing `dispatch_plugin_target` sourced-helper pattern. It must NOT be duplicated inline per `HAS_<LANG>` block (that would be an 11th copy of the same discovery logic across 2 languages × 5 targets = 10 call sites minimum; the discovery *function* itself must be written once)

7. **Given** a monorepo with **multiple** Python (or JS) project roots (e.g. `services/a/pyproject.toml` and `services/b/pyproject.toml`)
   **When** a target runs
   **Then** the tool runs once per discovered root (loop, mirroring the existing Terraform `tf_dirs` multi-directory loop pattern at Makefile `_lint`), and results/failures are attributed per path in the JSON summary (not just a single pass/fail for the whole language)

8. **Given** a passing test suite
   **When** `bash tests/test-project-discover.sh` runs
   **Then** it covers: single-root repo (root = `.`), two-language monorepo (`api/`+`frontend/`), multi-root single-language (two Python services), `projects:` override present, declared language with no manifest anywhere
   **And** all cases produce the expected discovered-root output and (for the Makefile-integration cases) expected cwd-dependent tool behavior

## Tasks / Subtasks

- [ ] **Task 1: Discovery helper library** (AC: 1, 3, 5, 6, 7)
  - [ ] 1.1 Create `lib/project-discover.sh`. Source `lib/log.sh` per convention. Standard header (purpose, usage, deps).
  - [ ] 1.2 Implement `discover_project_roots <language>`. If `.devrail.yml` has a `projects:` entry whose `languages:` list contains `<language>`, emit that entry's `path:` (or multiple paths if more than one `projects:` entry names the language) and return — autodetection short-circuits.
  - [ ] 1.3 Otherwise, autodetect: for `python`, find directories containing `pyproject.toml`, `setup.py`, or `setup.cfg` (first match per directory wins that directory; a dir with more than one manifest type only counts once). For `javascript`, find directories containing `package.json`. Exclude `.git/`, `node_modules/`, `vendor/`, `.venv/`, `venv/`, `dist/`, `build/`, `.terraform/` subtrees from the search (mirror the existing `find ... -not -path` exclusion lists already used per-language in `_lint`).
  - [ ] 1.4 If no manifest found anywhere and no `.` manifest either, emit `log_warn` ("no project root found for declared language") and return empty (caller skips, per AC 5).
  - [ ] 1.5 If a manifest exists at repo root (`.`) and nowhere else, return `.` (AC 4 — regression path, no behavior change).
  - [ ] 1.6 Output contract: newline-separated relative paths (e.g. `.`, `api`, `frontend`), no trailing slash, suitable for a `for root in $(discover_project_roots python); do ...; done` loop in Make recipes.
  - [ ] 1.7 Pure bash + `yq` (already in image) for the `projects:` override read. No new dependencies.
  - [ ] 1.8 Idempotent, no filesystem mutation, safe to call multiple times per `make` invocation (called once per language per target).

- [ ] **Task 2: Wire into `_lint`, `_format`, `_fix`, `_test`, `_security`** (AC: 1, 2, 4, 7)
  - [ ] 2.1 In each of the five internal targets, for the `HAS_PYTHON` block: replace the bare tool invocation (e.g. `ruff check .`) with a loop over `discover_project_roots python`, running the tool with `(cd "$root" && <tool> .)` per root — mirroring the existing Terraform `(cd "$dir" && tflint)` pattern already in `_lint`.
  - [ ] 2.2 Same for the `HAS_JAVASCRIPT` block across all five targets: `eslint`, `tsc --noEmit` (gate on `<root>/tsconfig.json` existence, not repo-root `tsconfig.json`), `prettier`, `vitest run`, `npm audit`.
  - [ ] 2.3 File-existence gates that currently `find .` for `*.py`/`*_test.py`/JS test files must scope the `find` to the discovered root, not the whole repo (otherwise a JS-only project's stray Python file in an unrelated directory could falsely gate Python tools on).
  - [ ] 2.4 Aggregate per-root failures into `failed_languages` with the root path included (e.g. `"python:api"` instead of just `"python"`) so a monorepo failure identifies which project failed (AC 7). Confirm this doesn't break any existing single-root consumer's JSON-parsing expectations — single-root case still emits `"python"` unqualified when root is `.` (see Dev Notes: backward-compat note).
  - [ ] 2.5 `source lib/project-discover.sh` once near the top of each recipe (alongside the existing `. /opt/devrail/lib/plugin-execute.sh` source line).

- [ ] **Task 3: `.devrail.yml` schema** (AC: 3)
  - [ ] 3.1 In `standards/devrail-yml-schema.md` (development-standards repo, NOT dev-toolchain), document the new top-level `projects:` key: list of `{path: string, languages: [string]}`. Include the worked `api`/`frontend` example from the AC.
  - [ ] 3.2 Note explicitly: `projects:` is optional; omitting it uses autodetection (AC 1); it's per-language, not global — a repo can autodetect Python while overriding JS, if ever needed (mixed mode is naturally supported since `discover_project_roots` is called once per language).

- [ ] **Task 4: Test fixtures + smoke test** (AC: 8)
  - [ ] 4.1 `tests/fixtures/monorepo-python-js/api/pyproject.toml` — minimal valid pyproject with a trivial `tests/test_smoke.py`.
  - [ ] 4.2 `tests/fixtures/monorepo-python-js/frontend/package.json` + `frontend/vite.config.ts` (with a `@` alias) + `frontend/tsconfig.json` + a trivial `frontend/src/__tests__/smoke.test.ts` importing via the alias — proves AC 2's alias-resolution claim, not just file discovery.
  - [ ] 4.3 `tests/fixtures/single-root-python/pyproject.toml` at fixture root — regression fixture for AC 4.
  - [ ] 4.4 `tests/fixtures/multi-root-python/services/a/pyproject.toml`, `services/b/pyproject.toml` — AC 7.
  - [ ] 4.5 `tests/fixtures/monorepo-with-override/.devrail.yml` (with `projects:`) — AC 3.
  - [ ] 4.6 `tests/fixtures/declared-lang-no-manifest/.devrail.yml` (declares `python` but ships zero `.py`/manifest files) — AC 5.
  - [ ] 4.7 Create `tests/test-project-discover.sh`. Pattern: mirror `tests/test-plugin-loader.sh` (mktemp/fixture bind-mount, `jq`-based JSON event assertions, no brittle string matching). Unit-level: source `lib/project-discover.sh` directly and call `discover_project_roots` against each fixture dir, assert stdout. Integration-level: run `make _lint`/`make _test` against the `monorepo-python-js` fixture inside the container and assert the eslint/tsc/pytest/vitest invocations actually succeeded (proves cwd + alias resolution, not just path discovery).

- [ ] **Task 5: CI + docs**
  - [ ] 5.1 Add a step to `.github/workflows/ci.yml` after the existing plugin-loader smoke test step: `bash tests/test-project-discover.sh`.
  - [ ] 5.2 `CHANGELOG.md` `[Unreleased]` → `### Added`: one-line note on monorepo project-root discovery for Python/JS.
  - [ ] 5.3 `STABILITY.md`: add a row noting per-project monorepo discovery (Python/JS) — Preview status until Story 15.2 lands alongside it.
  - [ ] 5.4 Close GitHub issue #53 from the PR description (`Closes #53`).

## Dev Notes

### Architecture pattern context

The dev-toolchain Makefile follows a two-layer delegation pattern (`Makefile:1-15` header comment) — public targets on the host `docker run` into internal `_<target>` recipes. This story's discovery logic is **internal-only** (`lib/project-discover.sh`, sourced inside the container recipes) — no new public host target needed. It follows the precedent set by Story 13.5's `dispatch_plugin_target` (`lib/plugin-execute.sh`): a sourced bash function invoked once per recipe, not per-language duplicated logic.

### Backward-compatibility note (important — read before Task 2.4)

The single-root case (root = `.`) is the overwhelming majority of existing consumers. Verify the JSON summary's `failed_languages` array is unchanged in that case — do NOT emit `"python:."` for the root=`.` case; emit bare `"python"` exactly as today. Only qualify with the path when the discovered root is not `.` (i.e., genuinely a monorepo). This keeps every existing single-root project's `make check` output byte-identical, satisfying AC 4 literally rather than just "close enough."

### File touchpoints

| Path | Change |
|---|---|
| `dev-toolchain/lib/project-discover.sh` | New — `discover_project_roots <language>` helper. |
| `dev-toolchain/Makefile` | Modify `_lint`, `_format`, `_fix`, `_test`, `_security` — Python and JavaScript blocks only. Source the new lib. Loop over discovered roots. |
| `dev-toolchain/tests/test-project-discover.sh` | New — smoke test. |
| `dev-toolchain/tests/fixtures/monorepo-python-js/**` | New fixture. |
| `dev-toolchain/tests/fixtures/single-root-python/**` | New fixture (regression). |
| `dev-toolchain/tests/fixtures/multi-root-python/**` | New fixture. |
| `dev-toolchain/tests/fixtures/monorepo-with-override/**` | New fixture. |
| `dev-toolchain/tests/fixtures/declared-lang-no-manifest/**` | New fixture. |
| `dev-toolchain/.github/workflows/ci.yml` | New step invoking `tests/test-project-discover.sh`. |
| `dev-toolchain/CHANGELOG.md` | `[Unreleased] → Added` entry. |
| `dev-toolchain/STABILITY.md` | New component row. |
| `OrgDocs/development-standards/standards/devrail-yml-schema.md` | Document `projects:` key. |

### Logging convention (existing — reuse)

`lib/log.sh` exports `log_info`, `log_warn`, `log_error`, `log_debug`, `die`, `log_event` (added in Story 13.2's review follow-up — accepts arbitrary structured fields, prefer this over hand-rolled `printf` JSON). No raw `echo` for status messages (CLAUDE.md critical rule 6).

### Testing standard

Smoke tests live in `tests/test-<area>.sh`. `set -euo pipefail`, source `lib/log.sh`, `mktemp -d` + cleanup trap, assert with `jq -e` on JSON event fields — never string-match full lines. `make _check` shellchecks everything under `tests/`; new scripts must pass shfmt (2-space indent) and shellcheck cleanly.

### What NOT to do (anti-patterns observed in similar stories)

- **Don't** duplicate the discovery `find` logic per target. Write `discover_project_roots` once in `lib/project-discover.sh`; every call site sources and calls it.
- **Don't** let this story bleed into Story 15.2's scope (dependency install). This story only changes *cwd*; it must not add `npm ci`/`uv sync`/any install step. Verify: after this story lands, a fixture project without dependencies pre-installed should behave exactly as it does today (still `ModuleNotFoundError` if the project has real deps — that's Story 15.2's job to fix).
- **Don't** use suppression annotations to silence shellcheck/lint on the new files (CLAUDE.md critical rule 7).
- **Don't** touch Go, Rust, Ansible, Ruby, Bash, Terraform, Swift, or Kotlin blocks in this story — out of scope (Story 15.3 / already handled / not applicable). Terraform already has its own per-directory loop (`tf_dirs`) predating this story; leave it as-is, though a future cleanup could rebase it onto the shared helper — not this story's job.

### Project structure notes

- All Makefile/lib/test implementation lives in `~/Work/github.com/devrail-dev/dev-toolchain` (separate repo from this planning repo). Branch: `feat/53-monorepo-project-root-discovery` off `main`.
- Conventional commit scope: `makefile` (existing scope, accepted by pre-commit-conventional-commits v1.1.0).
- PR description: `Closes #53`, references Story 15.1.

## Project Context Reference

- Project root: `~/Work/gitlab.mfsoho.linkridge.net/OrgDocs/development-standards` (this repo, planning)
- Implementation repo: `~/Work/github.com/devrail-dev/dev-toolchain`
- Standards docs: `standards/makefile-contract.md`, `standards/devrail-yml-schema.md`
- CLAUDE.md critical rules apply throughout (especially #1 `make check` before completion, #6 shared logging library, #7 never suppress failing checks, #8 update docs alongside behavior changes).

## References

- [Source: GitHub issue #53](https://github.com/devrail-dev/dev-toolchain/issues/53) — original bug report, reproduction, and proposed solution table this story implements (Python/JS subset)
- [Source: GitHub issue #52](https://github.com/devrail-dev/dev-toolchain/issues/52) — companion issue; Story 15.2 builds on this story's root discovery
- [Source: `_bmad-output/planning-artifacts/epics.md#Epic 15`] — story-level AC and epic background
- [Source: `dev-toolchain/Makefile`] — current target structure; study the existing Terraform `tf_dirs` loop (`_lint`) as the multi-root precedent, and `dispatch_plugin_target` (`lib/plugin-execute.sh`) as the sourced-helper precedent
- [Source: `dev-toolchain/lib/log.sh`] — logging library
- [Source: `dev-toolchain/tests/test-plugin-loader.sh`] — test pattern reference
- [Source: `_bmad-output/implementation-artifacts/13-2-implement-plugin-manifest-parser-and-loader.md`] — prior story establishing the "sourced lib/ helper, not per-language duplication" precedent this story follows

## Dev Agent Record

_(populated during dev-story execution)_

## Change Log

| Date | Change |
|---|---|
| 2026-07-24 | Story created via BMad Master direct authoring (status: ready-for-dev), following user decision to formalize GitHub issues #52/#53 into a proper epic before implementation |
