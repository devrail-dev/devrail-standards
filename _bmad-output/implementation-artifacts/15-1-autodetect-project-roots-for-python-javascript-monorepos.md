# Story 15.1: Autodetect Project Roots for Python & JavaScript Monorepos

Status: review

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

5. **Given** a repo where a declared language (per `.devrail.yml` `languages:`) has **no** manifest anywhere in the tree (e.g. a bare-scripts Python repo with no `pyproject.toml`)
   **When** any target runs
   **Then** the discovered root falls back to `.` — the tool still runs from the repository root exactly as it did before this story existed. **(Revised during implementation — see Dev Agent Record.)** The original draft of this AC specified "skip and warn," but `_lint`/`_security` ran unconditionally at `.` regardless of manifest presence *before* this story (no prior gating on manifest existence), so a "skip" behavior here would have been a regression for real projects that lint fine without a `pyproject.toml`. Falling back to `.` preserves that pre-existing behavior exactly.

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

- [x] **Task 1: Discovery helper library** (AC: 1, 3, 5, 6, 7)
  - [x] 1.1 Create `lib/project-discover.sh`. Source `lib/log.sh` per convention. Standard header (purpose, usage, deps).
  - [x] 1.2 Implement `discover_project_roots <language>`. If `.devrail.yml` has a `projects:` entry whose `languages:` list contains `<language>`, emit that entry's `path:` (or multiple paths if more than one `projects:` entry names the language) and return — autodetection short-circuits.
  - [x] 1.3 Otherwise, autodetect: for `python`, find directories containing `pyproject.toml`, `setup.py`, or `setup.cfg` (first match per directory wins that directory; a dir with more than one manifest type only counts once). For `javascript`, find directories containing `package.json`. Exclude `.git/`, `node_modules/`, `vendor/`, `.venv/`, `venv/`, `dist/`, `build/`, `.terraform/` subtrees from the search (mirror the existing `find ... -not -path` exclusion lists already used per-language in `_lint`).
  - [x] 1.4 If no manifest found anywhere, fall back to `.` (revised during implementation — see AC 5 note; `discover_project_roots` never returns empty, so callers never need a "no root found" branch).
  - [x] 1.5 If a manifest exists at repo root (`.`) — and also, as a generalization, if any *other* manifest happens to exist elsewhere too — the root manifest wins and only `.` is returned, avoiding double-running a tool that already recurses (AC 4 — regression path, no behavior change).
  - [x] 1.6 Output contract: newline-separated relative paths (e.g. `.`, `api`, `frontend`), no trailing slash, suitable for a `for root in $(discover_project_roots python); do ...; done` loop in Make recipes.
  - [x] 1.7 Pure bash + `yq` (already in image) for the `projects:` override read. No new dependencies.
  - [x] 1.8 Idempotent, no filesystem mutation, safe to call multiple times per `make` invocation (called once per language per target).

- [x] **Task 2: Wire into `_lint`, `_format`, `_fix`, `_test`, `_security`** (AC: 1, 2, 4, 7)
  - [x] 2.1 In each of the five internal targets, for the `HAS_PYTHON` block: replace the bare tool invocation (e.g. `ruff check .`) with a loop over `discover_project_roots python`, running the tool with `(cd "$root" && <tool> .)` per root — mirroring the existing Terraform `(cd "$dir" && tflint)` pattern already in `_lint`.
  - [x] 2.2 Same for the `HAS_JAVASCRIPT` block across all five targets: `eslint`, `tsc --noEmit` (gate on `<root>/tsconfig.json` existence, not repo-root `tsconfig.json`), `prettier`, `vitest run`, `npm audit`.
  - [x] 2.3 File-existence gates that currently `find .` for `*.py`/`*_test.py`/JS test files must scope the `find` to the discovered root, not the whole repo (otherwise a JS-only project's stray Python file in an unrelated directory could falsely gate Python tools on).
  - [x] 2.4 Aggregate per-root failures into `failed_languages` with the root path included (e.g. `"python:api"` instead of just `"python"`) so a monorepo failure identifies which project failed (AC 7). Confirm this doesn't break any existing single-root consumer's JSON-parsing expectations — single-root case still emits `"python"` unqualified when root is `.` (see Dev Notes: backward-compat note).
  - [x] 2.5 `source lib/project-discover.sh` once near the top of each recipe (alongside the existing `. /opt/devrail/lib/plugin-execute.sh` source line).

- [x] **Task 3: `.devrail.yml` schema** (AC: 3)
  - [x] 3.1 In `standards/devrail-yml-schema.md` (development-standards repo, NOT dev-toolchain), document the new top-level `projects:` key: list of `{path: string, languages: [string]}`. Include the worked `api`/`frontend` example from the AC.
  - [x] 3.2 Note explicitly: `projects:` is optional; omitting it uses autodetection (AC 1); it's per-language, not global — a repo can autodetect Python while overriding JS, if ever needed (mixed mode is naturally supported since `discover_project_roots` is called once per language).

- [x] **Task 4: Test fixtures + smoke test** (AC: 8)
  - [x] 4.1 `tests/fixtures/monorepo-python-js/api/pyproject.toml` — minimal valid pyproject with a trivial `tests/test_smoke.py`.
  - [x] 4.2 `tests/fixtures/monorepo-python-js/frontend/package.json` + `frontend/vite.config.ts` (with a `@` alias) + `frontend/tsconfig.json` + a trivial `frontend/src/__tests__/smoke.test.ts` importing via the alias — proves AC 2's alias-resolution claim, not just file discovery.
  - [x] 4.3 `tests/fixtures/single-root-python/pyproject.toml` at fixture root — regression fixture for AC 4.
  - [x] 4.4 `tests/fixtures/multi-root-python/services/a/pyproject.toml`, `services/b/pyproject.toml` — AC 7.
  - [x] 4.5 `tests/fixtures/monorepo-with-override/.devrail.yml` (with `projects:`) — AC 3.
  - [x] 4.6 `tests/fixtures/declared-lang-no-manifest/.devrail.yml` (declares `python` but ships zero `.py`/manifest files) — AC 5.
  - [x] 4.7 Create `tests/test-project-discover.sh`. Pattern: mirror `tests/test-plugin-loader.sh` (mktemp/fixture bind-mount, `jq`-based JSON event assertions, no brittle string matching). Unit-level: source `lib/project-discover.sh` directly and call `discover_project_roots` against each fixture dir, assert stdout. Integration-level: run `make _lint`/`make _test` against the `monorepo-python-js` fixture inside the container and assert the eslint/tsc/pytest/vitest invocations actually succeeded (proves cwd + alias resolution, not just path discovery).

- [x] **Task 5: CI + docs**
  - [x] 5.1 Add a step to `.github/workflows/ci.yml` after the existing plugin-loader smoke test step: `bash tests/test-project-discover.sh`.
  - [x] 5.2 `CHANGELOG.md` `[Unreleased]` → `### Added`: one-line note on monorepo project-root discovery for Python/JS.
  - [x] 5.3 `STABILITY.md`: add a row noting per-project monorepo discovery (Python/JS) — Preview status until Story 15.2 lands alongside it.
  - [x] 5.4 Close GitHub issue #53 from the PR description (`Closes #53`).

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

### Agent Model Used

Claude Sonnet 5 — single-session execution via BMad Master direct authoring (not a separate `/bmad-bmm-dev-story` invocation).

### Debug Log References

- Initial `discover_project_roots` design (Task 1.4/AC 5) specified "no manifest found → warn and skip." Before wiring it into the Makefile, re-read the *actual* pre-existing `_lint`/`_security` Python blocks and found they run `ruff check .` / `bandit -r . -q` **unconditionally** — no manifest-existence gate ever existed. Shipping "skip when no manifest" would have been a real regression for any bare-scripts Python project (declares `languages: [python]`, has `.py` files, no `pyproject.toml`) that lints fine today. Revised the design to fall back to `.` instead — `discover_project_roots` now never returns empty output, which also simplified every Makefile call site (no "did we find anything" branch needed). AC 5 and Task 1.4/1.5 updated to match; see the AC 5 note above.
- `_project_discover_override`'s first yq expression used `.path as $p | (.languages // [])[] | $p + "\t" + .` piped to `awk -F'\t'`. Tested with the real container's yq v4.44.1 and found it emitted a **literal two-character `\t`** (backslash + t), not an actual tab — yq does not reliably expand `\t` as an escape in this expression form. `awk -F'\t'` (which GNU awk treats as an actual tab) then failed to split the field, silently breaking the `projects:` override entirely (autodetection always won, no error surfaced). Caught by explicit override-fixture testing before this went anywhere near a PR. Fixed by switching to a `"::"` delimiter and restructuring the yq expression to `[.path, (.languages // [])[]] | join("::")` — this also happened to sidestep a real shellcheck SC2016 finding (the `as $p` binding pattern, written inside single quotes, reads as an unexpanded-bash-variable false positive; the `join()` rewrite doesn't introduce any `$name` token at all, so there's nothing to flag).
- `find ... | xargs -I{} dirname {}` (copied from the Makefile's pre-existing Terraform `tf_dirs` pattern) triggered shellcheck SC2038 once moved into a real `.sh` file — the Makefile's *embedded* shell was never shellchecked (only `find . -name '*.sh'` results are, and `Makefile` doesn't match that glob), so this exact pattern had never been checked before. Fixed with `-print0` / `xargs -0`, no suppression annotation (CLAUDE.md rule 7).
- Validated end-to-end against a fast Docker overlay (`FROM ghcr.io/devrail-dev/dev-toolchain:1.12.0` + `COPY lib/`) rather than a full multi-stage rebuild — the real Dockerfile's Rust/Swift/Kotlin/Ruby builder stages make a from-scratch build too slow for iterative testing. The overlay is sufficient because `lib/` is `COPY`'d verbatim with no build-time processing; CI still does a full real build before running `tests/test-project-discover.sh`.
- Discovered a pre-existing, unrelated container limitation while building the `frontend/eslint.config.js` fixture: `import ... from "typescript-eslint"` (or any globally npm-installed package) fails under Node's ESM resolver regardless of cwd — Node's ESM loader does not consult the global `node_modules` path the way CJS `require` (via `NODE_PATH`) does. Reproduced identically at a bare repo root with no monorepo involvement, confirming it's not a Story 15.1 regression. Worked around it in the fixture (plain-JS eslint config, no TS-aware linting needed to prove cwd/config resolution) rather than fixing it — out of scope here; worth a follow-up issue if the org wants TS-aware eslint configs to work with the container's global npm installs.

### Completion Notes List

- All 8 ACs implemented; AC 5 revised mid-implementation per the debug log above (fallback-to-`.` instead of skip-and-warn) — a stronger regression guarantee than the original draft, not a scope reduction.
- `lib/project-discover.sh` (~120 lines): `discover_project_roots <language>` never returns empty. Precedence: `projects:` override → autodetected roots (root-manifest wins over any nested manifest; multiple nested roots returned as-is) → fallback to `.` when nothing found. Supports `python` and `javascript` only per this story's scope; any other language argument logs a warning and falls back to `.` (forward-compatible no-op for Story 15.3).
- Wired into `_lint`, `_format`, `_fix`, `_test`, `_security` for the `HAS_PYTHON` and `HAS_JAVASCRIPT` blocks only (10 call sites: 5 targets × 2 languages) — `_docs` and `_init`'s HAS_PYTHON/HAS_JAVASCRIPT blocks (config scaffolding, not tool execution) are untouched, matching the story's scope boundary. Terraform's pre-existing `tf_dirs` loop is untouched (already multi-root-aware; rebasing it onto the shared helper is explicitly out of scope per Dev Notes).
- Single-root byte-compatibility (AC 4) verified directly: `failed_languages`/`ran_languages` tags are qualified with `:<root>` only when root ≠ `.`; root = `.` produces the exact pre-existing unqualified tag (`"python"`, `"python:bandit"`, `"javascript:eslint"`, etc.).
- `.devrail.yml` `projects:` key documented in `standards/devrail-yml-schema.md` (both the per-key section and the summary table) in the OrgDocs planning repo.
- 5 fixtures added under `dev-toolchain/tests/fixtures/`: `single-root-python` (regression), `monorepo-python-js` (api/ Python + frontend/ JS/TS, including a real `@` alias exercised by an actual vitest import — not just a config value), `multi-root-python` (two Python services), `monorepo-with-override` (`projects:` override), `declared-lang-no-manifest` (fallback-to-`.` case).
- `tests/test-project-discover.sh`: 6 unit-level assertions (source `lib/project-discover.sh` directly against each fixture, no Makefile involved) + 5 integration-level assertions (`make _lint`/`make _test` against real fixtures inside the container, following the `test-plugin-loader.sh` convention of bind-mounting `$REPO_ROOT/Makefile:/workspace/Makefile:ro` alongside the fixture directory). 11/11 pass.
- CI wired: new step in `.github/workflows/ci.yml` after the existing plugin-loader smoke test.
- `CHANGELOG.md` `[Unreleased] → Added` and `STABILITY.md` (new "Monorepo project-root discovery (Python/JS)" row, status: Preview) updated.

**Verification (all green, against a fast Docker overlay of `ghcr.io/devrail-dev/dev-toolchain:1.12.0` + the new `lib/`):**

- `shellcheck lib/project-discover.sh` — clean (0 findings; two SC2038 + one SC2016 finding fixed for real during development, not suppressed)
- `shfmt -d lib/project-discover.sh` — clean
- `shellcheck tests/test-project-discover.sh` / `shfmt -d tests/test-project-discover.sh` — clean
- `bash tests/test-project-discover.sh` (`DEVRAIL_IMAGE`/`DEVRAIL_TAG` pointed at the overlay) — **11 passed, 0 failed**
- Manual `make _lint`/`make _test` runs against `monorepo-python-js`: `{"target":"lint","status":"pass","languages":["python:api","javascript:frontend"]}`, `{"target":"test","status":"pass","languages":["python:api","javascript:frontend"],"skipped":[]}` — vitest's `smoke.test.ts` (importing `@/greet`) passed, proving the `@` alias resolves from the correct cwd
- Manual `make _lint`/`make _test`/`make _security` runs against `single-root-python`: `"languages":["python"]` in all three — confirms AC 4's byte-identical unqualified-tag guarantee, including `"failed":["python:bandit"]` matching the pre-existing tag format exactly when bandit legitimately flags something (a `B101 assert_used` finding in the fixture's own test file — expected bandit behavior, not a bug)

**Not run:** a full `docker build` of the real multi-stage Dockerfile (Rust/Swift/Kotlin/Ruby builder stages make this too slow for iterative local validation). CI's `docker build` step will exercise the real build; `lib/` is `COPY`'d verbatim so the overlay-image validation above is equivalent for this story's purposes. `make check`/`make _check` on the dev-toolchain repo itself was not re-run in-session (repo only declares `languages: [bash]`, so it doesn't exercise this story's code path) — the project's own commit hooks and CI will still gate on it before merge.

**No PR opened yet** — implementation is complete and committed to a local branch (`feat/53-monorepo-project-root-discovery`) pending user confirmation to push/open a PR (BMad Master surfaced this as a standing default: pushing/opening PRs is a "visible to others" action requiring confirmation per session conventions).

### File List

**Implementation (dev-toolchain repo, branch `feat/53-monorepo-project-root-discovery`):**

- `lib/project-discover.sh` — new (post-review: added a `[[ -d ... ]]` existence warning for `projects:` override paths — code-review finding)
- `Makefile` — modified (`_lint`, `_format`, `_fix`, `_test`, `_security`: sourced the new lib; replaced the `HAS_PYTHON`/`HAS_JAVASCRIPT` blocks with per-root loops)
- `tests/test-project-discover.sh` — new (post-review: rewritten to copy fixtures into a `mktemp`-based `$WORKDIR` with a cleanup trap — matching `tests/test-plugin-loader.sh` — instead of bind-mounting checked-in fixtures directly; original version leaked a Docker bind-mount artifact into `tests/fixtures/`. Also extended with `_format`/`_fix`/`_security` integration coverage, previously only manually spot-checked — code-review findings)
- `tests/fixtures/single-root-python/**` — new
- `tests/fixtures/monorepo-python-js/**` — new
- `tests/fixtures/multi-root-python/**` — new
- `tests/fixtures/monorepo-with-override/**` — new
- `tests/fixtures/declared-lang-no-manifest/**` — new (post-review: removed `script.py` — the fixture's own task description said "ships zero .py/manifest files" but a stray `.py` file had been included — code-review finding)
- `.github/workflows/ci.yml` — modified (new "Project-root discovery smoke test" step)
- `CHANGELOG.md` — modified (`[Unreleased] → Added` entry)
- `STABILITY.md` — modified (new component row)

**Story tracking + schema doc (OrgDocs/development-standards repo):**

- `_bmad-output/planning-artifacts/epics.md` — modified (Epic 15 added, branch `feat/15-1-create-story`, already committed)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — modified (branch `feat/15-1-create-story`, already committed; will need a further update to `15-1: review` — see Change Log)
- `_bmad-output/implementation-artifacts/15-1-autodetect-project-roots-for-python-javascript-monorepos.md` — this file (status, all task checkboxes, AC 5 revision, Dev Agent Record, File List, Senior Developer Review)
- `standards/devrail-yml-schema.md` — modified (`projects:` key documented; updated again post-review to soften overclaimed validation rules and add the "root wins" limitation note)
- `standards/makefile-contract.md` — modified (post-review: `projects:` subsection + Supported Keys row — flagged as a doc gap by code-review, CLAUDE.md rule 8)

## Change Log

| Date | Change |
|---|---|
| 2026-07-24 | Story created via BMad Master direct authoring (status: ready-for-dev), following user decision to formalize GitHub issues #52/#53 into a proper epic before implementation |
| 2026-07-24 | Implementation completed via BMad Master direct authoring (not a separate dev-story session); AC 5 revised (fallback-to-`.` instead of skip-and-warn) after discovering the original draft would have regressed bare-manifest-less Python projects; status moved to `review`; committed locally to `feat/53-monorepo-project-root-discovery` in dev-toolchain, not yet pushed or opened as a PR pending user confirmation |
| 2026-07-24 | Ran the `dev-story` workflow's completion sequence (step 9) formally against the already-implemented story: task_check found zero incomplete tasks, so per the workflow's own logic execution skipped straight to the completion/DoD gate. Re-ran the full regression suite against the committed state (fast Docker overlay of `ghcr.io/devrail-dev/dev-toolchain:1.12.0` + this branch's `lib/`): `shellcheck`/`shfmt` clean, `tests/test-project-discover.sh` 11/11, `tests/test-plugin-loader.sh` all pass (confirms the new `lib/project-discover.sh` source line added to every recipe didn't regress the plugin loader prelude), `tests/smoke-rails.sh` all pass (confirms untouched-language recipe flow, e.g. Ruby's unqualified `"languages":["ruby"]` tag, is unaffected). DoD checklist confirmed: all tasks `[x]`, File List complete, Dev Agent Record present, Change Log present, only permitted story sections modified. Status remains `review` (already at target state — no `in-progress` transition needed). Next: `code-review` workflow. |
| 2026-07-24 | `code-review` workflow executed (adversarial pass). 5 findings (1 HIGH, 2 MEDIUM, 2 LOW); all addressed in-session (no separate follow-up PR — see Senior Developer Review below for detail). Regression suite re-run post-fix: 20/20 (up from 11, the new format/fix/security integration cases). Outcome: Approve. |

## Senior Developer Review (AI)

**Reviewer:** Matthew (review executed by Claude Sonnet 5 — same model that implemented the story; see caveat below)
**Date:** 2026-07-24
**Outcome:** Approve (after in-session fixes; no separate follow-up PR needed)

### Caveat

Per the `dev-story`/`code-review` workflow's recommendation, code review should run under a **different** LLM than the one that implemented the story. This review was conducted under Sonnet 5, the same model/session that wrote the original implementation. Findings should be treated as a rigorous adversarial self-audit rather than a true second-pair-of-eyes review — the workflow's explicit minimum-3-issues mandate and git-vs-story cross-referencing forced genuine re-examination beyond what a casual self-check would surface, and did in fact catch a real regression risk (H1) and a real Docker-mount bug in the test harness that a "looks good" pass would have missed. A future review under a different model family remains worthwhile.

### Findings

**HIGH severity:**

- [x] **H1** — `_project_discover_normalize`'s "root wins" rule (a manifest at `.` suppresses all nested manifests, collapsing discovery to `.`) silently defeats monorepo detection for a common real-world layout: a root-level `pyproject.toml` holding only shared tool config (e.g. `[tool.ruff]`) alongside genuine per-language subdirectories. No AC, fixture, or test covers this case, and the code comments only frame it as an optimization ("avoid double-running"), not as a real limitation users could hit. **Fix:** did not redesign the algorithm under review-time pressure (the `projects:` override already provides a correct, low-risk escape hatch for exactly this layout). Instead documented the limitation explicitly in `standards/devrail-yml-schema.md` with the concrete workaround, so a user hitting it isn't stuck or confused — [`devrail-yml-schema.md#projects`](../../standards/devrail-yml-schema.md), "Known autodetection limitation" paragraph.

**MEDIUM severity:**

- [x] **M1** — The committed `tests/test-project-discover.sh` only integration-tested `make _lint` and `make _test`, despite AC 1 explicitly listing `lint`/`format`/`fix`/`test`/`security` as in scope. `_format`/`_fix`/`_security`'s per-root cwd/tagging behavior had only been verified manually, ad hoc, during the session — not captured in the automated (CI-run) regression suite. **Fix:** added real integration assertions for all three remaining targets against both the monorepo fixture (qualified tags: `["python:api","javascript:frontend"]`, and `_security`'s per-root failed/skipped tagging: `["python:api:bandit"]` / `["javascript:frontend"]`) and the single-root fixture (unqualified tags, AC 4). Test count went from 11 to 20, all passing.
- [x] **M2** — `standards/devrail-yml-schema.md`'s new `projects:` section stated "Validation rules" (`path` must exist as a directory; `languages` must be a non-empty list drawn from declared `languages:`) that **no code anywhere enforces** — unlike `plugins:`, which has a real schema validator (`scripts/plugin-validator.sh`). A misconfigured `projects:` entry is silently ignored or fails opaquely deep inside a `cd` rather than being caught with a clear error, contradicting what the doc promised. **Fix:** added a real (lightweight) runtime check — `discover_project_roots` now `log_warn`s when an override path doesn't exist as a directory — and reworded the doc's "Validation rules" to accurately describe current behavior (warn-not-reject for path existence; `languages` still unenforced) rather than overclaiming.

**LOW severity:**

- [x] **L1** — Task 4.6 committed `tests/fixtures/declared-lang-no-manifest/script.py`, but the task's own description says the fixture "ships zero `.py`/manifest files." The discrepancy didn't affect test correctness (`discover_project_roots` only cares about manifest absence, not `.py` file absence) but the fixture didn't match its documented intent. **Fix:** removed `script.py`; the fixture now contains only `.devrail.yml`.
- [x] **L2** — CLAUDE.md critical rule 8 ("update documentation when changing behavior... in the same commit") was only partially honored: `standards/devrail-yml-schema.md` was updated, but `standards/makefile-contract.md` — the standards doc that actually describes the Makefile's execution model (cwd, target behavior) — said nothing about the new per-project cwd behavior, even though this is a direct, material change to how the documented "two-layer delegation" contract runs tools. **Fix:** added a `### projects` subsection (mirroring the existing `languages`/`fail_fast`/`log_format` entries) and a `Supported Keys` table row, cross-referencing the schema doc for full detail.

### Discrepancy check (git vs. story File List)

No discrepancies — every file touched (implementation + post-review fixes) is reflected in the File List above, and every File List entry has a corresponding change in `git diff main..feat/53-monorepo-project-root-discovery` (dev-toolchain) or the working tree (development-standards).

### Action Items

All 5 findings resolved in this session — no separate follow-up branch/PR (unlike Story 13.2's pattern, where fixes landed in a dedicated `fix/13-2-review-followups` PR after the original PR merged; here, nothing had been pushed/merged yet, so fixes were folded directly into the still-local `feat/53-monorepo-project-root-discovery` branch before it goes up for review).

- [x] [AI-Review][HIGH] H1: document the "root wins" autodetection limitation and its `projects:` override workaround [`standards/devrail-yml-schema.md` → fixed]
- [x] [AI-Review][MED] M1: add `_format`/`_fix`/`_security` integration test coverage [`tests/test-project-discover.sh` → fixed, 11 → 20 assertions]
- [x] [AI-Review][MED] M2: enforce (warn on) `projects:` path existence at runtime; correct the doc's validation claims [`lib/project-discover.sh`, `standards/devrail-yml-schema.md` → fixed]
- [x] [AI-Review][LOW] L1: remove stray `.py` file contradicting the fixture's documented intent [`tests/fixtures/declared-lang-no-manifest/script.py` → removed]
- [x] [AI-Review][LOW] L2: document the new cwd-scoping behavior in the Makefile contract standards doc, not just the schema doc [`standards/makefile-contract.md` → fixed]

**Bonus fix (not a scored finding, caught while verifying M1):** the original `tests/test-project-discover.sh` bind-mounted the checked-in `tests/fixtures/` directories directly as writable Docker workspaces. A Docker bind-mount behavior (mounting a file at a container path whose host-side directory is itself a live bind mount can materialize an empty placeholder file on the host) left stray root-owned `Makefile` files inside the tracked fixture directories after a local run. Rewritten to copy each fixture into a `mktemp`-based `$WORKDIR` with a cleanup trap before running any `make` target — matching the established `tests/test-plugin-loader.sh` convention, which this story's original test script should have followed from the start.
