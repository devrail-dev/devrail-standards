# Story 15.2: Autodetect and Install Python/JS Dependencies Before `make test`

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **developer with a dependency-bearing project** (e.g. a FastAPI backend using `uv`, or a Vue/Vite frontend using `npm`),
I want `make test` to install my project's dependencies before running pytest/vitest,
so that tests don't fail at import time with `ModuleNotFoundError`/unresolved-import errors — the exact failure mode reported in issue #52.

## Acceptance Criteria

1. **Given** a Python project root (as discovered by Story 15.1's `discover_project_roots`) containing `uv.lock`
   **When** `make test` runs
   **Then** DevRail installs dependencies via `uv export --frozen --no-hashes --format requirements-txt | uv pip install --system --break-system-packages -r -` before `pytest` runs, from that project's root — **not** `uv sync --frozen` as originally drafted; see the Dev Agent Record for why `uv sync`'s isolated `.venv` doesn't work in this container (the globally-installed `pytest` binary can't see into it)
   **And** a project's own real dependency (e.g. a package declared in `pyproject.toml`) is importable in the test suite afterward — proving install, not just invocation

2. **Given** a Python project root with no `uv.lock` but a `requirements*.txt` file
   **When** `make test` runs
   **Then** DevRail installs via `pip install -r <file>` before `pytest` runs (first matching `requirements*.txt` wins if more than one exists — deterministic glob order)

3. **Given** a Python project root with no lockfile and no `requirements*.txt`, but a `pyproject.toml` or `setup.py`
   **When** `make test` runs
   **Then** DevRail installs via `pip install -e .` before `pytest` runs

4. **Given** a JS/TS project root (as discovered by Story 15.1) containing `package-lock.json`
   **When** `make test` runs
   **Then** DevRail installs dependencies via `npm ci` before `vitest` runs, from that project's root
   **And** a project's own real dependency is importable in the test suite afterward

5. **Given** `.devrail.yml` declares `test.install` (a shell command string)
   **When** `make test` runs for that project root
   **Then** the configured command replaces autodetection entirely for that root's install step (both Python and JS honor this override identically — it's language-agnostic, just "run this before the test suite")

6. **Given** `.devrail.yml` declares `test.setup` (a shell command string)
   **When** `make test` runs
   **Then** the configured command runs **after** install succeeds and **before** the test suite (e.g. database migrations) — for every discovered root of every declared language, not just one

7. **Given** a project with no lockfile/manifest/requirements file for a declared language (stdlib-only code, or a project not yet using any dependency management)
   **When** `make test` runs
   **Then** no install step runs — behavior is unchanged from pre-Story-15.2 (regression-safe; this is the majority case for e.g. Bash/Terraform/Ansible-only repos and any Python/JS repo Story 15.1 already exercises without deps)

8. **Given** `.devrail.yml` `fail_fast`/`DEVRAIL_FAIL_FAST=1`
   **When** dependency installation fails (network error, unresolvable dependency, non-zero exit from `uv sync`/`npm ci`/`pip install`)
   **Then** `make test` fails fast with a clear `{"target":"test","status":"fail",...}` event identifying the failed install step — it must not silently proceed to run pytest/vitest against a broken/partial install

9. **Given** all installs run inside the container against the bind-mounted `/workspace`
   **When** `make test` completes
   **Then** nothing is written to the host beyond the project's own dependency directories under the workspace (`.venv`/site-packages via `pip`/`uv`, `node_modules/` via `npm`) — no host-level state, matching the existing container isolation model

10. **Given** a passing test suite
    **When** `bash tests/test-dependency-install.sh` runs
    **Then** it covers: `uv.lock` install + real dependency import (Python), `requirements.txt` install (Python), `pyproject.toml`-only install (Python), `package-lock.json` install + real dependency import (JS), `test.install` override, `test.setup` ordering, no-manifest regression case (AC 7)
    **And** each installing case actually exercises network-based package resolution (PyPI/npm registry) inside the container — not mocked — since the whole point is proving real installs unblock real imports

## Tasks / Subtasks

- [x] **Task 1: Add `uv` to the container image** (AC: 1)
  - [x] 1.1 **Scope discovery (read before starting):** the current image (`ghcr.io/devrail-dev/dev-toolchain:1.12.0`) has `pip`/`pip3` and `npm`/`npx` — it does **not** have `uv`, `poetry`, `pipenv`, `pnpm`, or `yarn`. Issue #52's own reproduction case uses `uv` for the Python side (`api/` — FastAPI backend, `uv`) and `npm` for JS (`frontend/` — Vue/Vite, `npm`), so this story's literal scope is **uv + pip for Python, npm for JS**. `poetry`/`pipenv`/`pnpm`/`yarn` are explicitly deferred (would require additional container tooling beyond this story's scope — flag as follow-up, do not silently half-implement by detecting their lockfiles without the tool to act on them).
  - [x] 1.2 Add `uv` install to `scripts/install-python.sh`: `pip install uv` (or `pip install --break-system-packages uv` matching the existing pip-upgrade fallback pattern already in that script). `uv` is officially distributed on PyPI as a self-contained wheel — no new Dockerfile stage, no new apt packages, no new COPY needed; `install-python.sh` already runs directly in the final runtime stage.
  - [x] 1.3 Idempotent check before install, matching the script's existing style: `command -v uv &>/dev/null || pip install uv ...`.
  - [x] 1.4 Add `uv` to `tests/test-python.sh`'s tool-presence checks (`check_tool uv --version`), matching how `ruff`/`bandit`/`pytest`/`mypy` are already verified there.

- [x] **Task 2: Dependency-install helper library** (AC: 1, 2, 3, 4, 5, 7, 8, 9)
  - [x] 2.1 Create `lib/dependency-install.sh`. Source `lib/log.sh`. Standard header. Mirrors `lib/project-discover.sh`'s sourced-helper pattern (Story 15.1 precedent) — do not duplicate install logic per language block.
  - [x] 2.2 Implement `install_project_deps <language> <root>` — runs (cd'd into) `<root>`:
    - Read `.devrail.yml` `test.install` first (via `yq`, mirroring `_project_discover_override`'s read pattern in `lib/project-discover.sh`). If present, run it verbatim and return its exit code — no autodetection.
    - Else autodetect per language:
      - `python`: `uv.lock` present → `uv export --frozen --no-hashes --format requirements-txt | uv pip install --system --break-system-packages -r -` (revised during implementation — see Dev Agent Record; NOT `uv sync`). Else `requirements*.txt` (first glob match, sorted) → `pip install --break-system-packages -r <file>`. Else `pyproject.toml` or `setup.py` present → `pip install --break-system-packages -e .`. Else → no-op (AC 7). All three need `--break-system-packages` on this container's Debian/PEP 668 Python.
      - `javascript`: `package-lock.json` present → `npm ci`. Else → no-op (AC 7).
    - Return the install command's real exit code; do not swallow failures (AC 8).
  - [x] 2.3 Implement `run_project_setup <root>` — reads `.devrail.yml` `test.setup` (language-agnostic, root-scoped) and runs it if present, after a successful install. Return its exit code.
  - [x] 2.4 Both functions log a structured `info` event before running (command being run, language, root) and an `error` event on failure — no raw `echo`.
  - [x] 2.5 Pure bash + `yq`, no new dependencies beyond Task 1's `uv`.

- [x] **Task 3: Wire into `_test` only** (AC: 1, 2, 3, 4, 5, 6, 7, 8)
  - [x] 3.1 In the `HAS_PYTHON` block of `_test`, inside the per-root loop added by Story 15.1: before the existing test-file-existence gate and `pytest` call, invoke `install_project_deps python "$root"`. On failure, set `overall_exit=1`, tag `failed_languages` with `"python:<root>:install"` (or unqualified `"python:install"` when root is `.`, matching Story 15.1's tag-qualification convention), and **do not** run pytest for that root (AC 8 — don't test against a broken install). On success (or no-op — nothing to install), proceed to `run_project_setup "$root"` (if `test.setup` is configured), then the existing test-file gate + `pytest`.
  - [x] 3.2 Same for the `HAS_JAVASCRIPT` block of `_test`: `install_project_deps javascript "$root"` before the existing vitest gate.
  - [x] 3.3 **Do not** wire dependency install into `_lint`/`_format`/`_fix`/`_security` — this story is `make test` only, matching issue #52's literal scope. (Note for future stories: `ruff`/`eslint` don't need project deps installed to lint; `mypy`/`tsc` arguably would benefit, but that's a different problem — do not scope-creep here.)
  - [x] 3.4 Source `lib/dependency-install.sh` once near the top of `_test`'s recipe, alongside the existing `lib/project-discover.sh` / `lib/plugin-execute.sh` source lines.

- [x] **Task 4: `.devrail.yml` schema** (AC: 5, 6)
  - [x] 4.1 In `standards/devrail-yml-schema.md`, document a new top-level `test:` mapping with `install` (string, optional) and `setup` (string, optional) keys. Note explicitly that `test.services` (ephemeral DB/cache containers) is a separate, not-yet-implemented key — do not imply it works (Story 15.4).
  - [x] 4.2 Update `standards/makefile-contract.md`'s `.devrail.yml` Consumption section with a `### test` entry (mirroring the `### projects` entry Story 15.1 added) — CLAUDE.md rule 8 burned this as a real finding in Story 15.1's code review; don't repeat it.

- [x] **Task 5: Test fixtures + smoke test** (AC: 10)
  - [x] 5.1 New fixture `tests/fixtures/python-uv-deps/` — `pyproject.toml` declaring one tiny, stable, zero-transitive-dependency PyPI package (do not use anything with a large dependency graph — lockfile review burden and network flakiness both scale with graph size), a generated `uv.lock` (run `uv lock` inside the container and check in the real output — do not hand-write a lockfile), and a `tests/test_smoke.py` that imports the declared dependency and asserts something trivial about it. Must fail with `ModuleNotFoundError` before this story's install step exists, pass after.
  - [x] 5.2 New fixture `tests/fixtures/python-requirements-deps/` — same shape but `requirements.txt` instead of `uv.lock` (no `pyproject.toml` needed for this one, or a minimal one without `uv.lock`).
  - [x] 5.3 New fixture `tests/fixtures/python-pyproject-only/` — `pyproject.toml` declaring the dependency, no lockfile, no requirements.txt — exercises the `pip install -e .` fallback path.
  - [x] 5.4 New fixture `tests/fixtures/js-npm-deps/` — `package.json` declaring one tiny, stable npm package, a real generated `package-lock.json` (run `npm install` inside the container and check in the result), and a vitest test importing the dependency.
  - [x] 5.5 New fixture `tests/fixtures/test-install-override/` — `.devrail.yml` with `test.install: "<custom command>"` and a project shape where autodetection would pick a *different* command if the override weren't honored (proves precedence).
  - [x] 5.6 New fixture `tests/fixtures/test-setup-ordering/` — `.devrail.yml` with `test.setup` that writes a marker file, and a test that asserts the marker file exists — proves setup runs after install, before tests.
  - [x] 5.7 Create `tests/test-dependency-install.sh`. Pattern: mirror `tests/test-project-discover.sh` (Story 15.1) — `mktemp` `$WORKDIR` + cleanup trap (do not bind-mount `tests/fixtures/` directly; Story 15.1's code review already caught this exact mistake once). Each installing case needs real network access to PyPI/npm inside the container — note this explicitly in the script's header (CI runners have network egress; this is not something to mock).
  - [x] 5.8 Regression fixture: reuse Story 15.1's `single-root-python` fixture (no lockfile/requirements/pyproject beyond what's already there — actually it already has a `pyproject.toml`, so add a **new** minimal fixture instead, e.g. `tests/fixtures/python-no-deps/` with just a `.py` file and zero manifest, or verify against `tests/fixtures/declared-lang-no-manifest/` from Story 15.1 — no install step should run there) — AC 7.

- [x] **Task 6: CI + docs**
  - [x] 6.1 Add a step to `.github/workflows/ci.yml` after the Story 15.1 "Project-root discovery smoke test" step: `bash tests/test-dependency-install.sh`.
  - [x] 6.2 `CHANGELOG.md` `[Unreleased]` → `### Added`: one-line note on dependency install before `make test` (Python/JS).
  - [x] 6.3 `STABILITY.md`: extend or add alongside Story 15.1's "Monorepo project-root discovery (Python/JS)" row — this story completes the pairing issue #52 + #53 originally described as related; note `uv`/`pip`/`npm` supported, `poetry`/`pipenv`/`pnpm`/`yarn` explicitly not yet.
  - [x] 6.4 Close GitHub issue #52 from the PR description (`Closes #52`).

## Dev Notes

### Architecture pattern context

No new architectural constraints beyond the established Makefile contract (two-layer delegation, JSON event envelope, sourced `lib/*.sh` helpers per Story 13.5/15.1 precedent — see `architecture.md` §"Makefile Contract Specification", which predates and doesn't need updating for this story). `lib/dependency-install.sh` follows the exact same shape as `lib/project-discover.sh`: pure bash, sourced once per recipe, one function per concern.

### Critical scope-narrowing discovery (read before Task 1)

The epic's original proposed-solution table (from issue #52, carried into `epics.md`) lists five Python signals (`uv.lock`/`poetry.lock`/`Pipfile.lock`/`requirements*.txt`/`pyproject.toml`) and three JS signals (`package-lock.json`/`pnpm-lock.yaml`/`yarn.lock`). **Only `uv`, `pip`, and `npm` are actually installed in the container today** — `poetry`, `pipenv`, `pnpm`, `yarn` are not. Detecting `poetry.lock` and then shelling out to a `poetry` binary that doesn't exist would fail confusingly (or require silently falling back, which is worse — a silent fallback to the wrong installer against a poetry-managed project could install the wrong dependency set). This story implements exactly the two package managers issue #52's own reproduction case needs (`uv` for the FastAPI backend, `npm` for the Vue frontend) plus `pip` as `uv`'s zero-lockfile fallback. Adding `poetry`/`pipenv`/`pnpm`/`yarn` is real, achievable follow-up work (none of them need a new Dockerfile stage — `pip install poetry`/`pip install pipenv` and `corepack enable` for pnpm/yarn since Node 22 ships corepack) but is **not** this story's job. Do not detect a lockfile for a tool that isn't installed.

### Backward-compatibility note (mirrors Story 15.1's pattern)

`_test`'s existing per-language, per-root loop (added by Story 15.1) already gates on test-file existence before running pytest/vitest. This story's install step runs **before** that gate, not instead of it — a project with a lockfile but zero test files still gets its deps installed (harmless, matches "install is idempotent and safe") but still hits the existing "skipping python tests: no test files found" skip path afterward, unchanged. Don't collapse the two gates into one; they answer different questions ("can I install" vs "is there anything to test").

### File touchpoints

| Path | Change |
|---|---|
| `dev-toolchain/scripts/install-python.sh` | Add `uv` install (one line + idempotency check). |
| `dev-toolchain/tests/test-python.sh` | Add `uv` to tool-presence checks. |
| `dev-toolchain/lib/dependency-install.sh` | New — `install_project_deps`, `run_project_setup`. |
| `dev-toolchain/Makefile` | Modify `_test` only — Python and JavaScript blocks. Source the new lib. Install (+ optional setup) before the existing test-file gate. |
| `dev-toolchain/tests/test-dependency-install.sh` | New — smoke test (network-dependent, real installs). |
| `dev-toolchain/tests/fixtures/python-uv-deps/**` | New fixture (real `uv.lock`, generated in-container). |
| `dev-toolchain/tests/fixtures/python-requirements-deps/**` | New fixture. |
| `dev-toolchain/tests/fixtures/python-pyproject-only/**` | New fixture. |
| `dev-toolchain/tests/fixtures/js-npm-deps/**` | New fixture (real `package-lock.json`, generated in-container). |
| `dev-toolchain/tests/fixtures/test-install-override/**` | New fixture. |
| `dev-toolchain/tests/fixtures/test-setup-ordering/**` | New fixture. |
| `dev-toolchain/tests/fixtures/python-no-deps/**` | New fixture (AC 7 regression). |
| `dev-toolchain/.github/workflows/ci.yml` | New step invoking `tests/test-dependency-install.sh`. |
| `dev-toolchain/CHANGELOG.md` | `[Unreleased] → Added` entry. |
| `dev-toolchain/STABILITY.md` | Extend Story 15.1's monorepo-discovery row or add a sibling row. |
| `OrgDocs/development-standards/standards/devrail-yml-schema.md` | Document `test.install`/`test.setup`. |
| `OrgDocs/development-standards/standards/makefile-contract.md` | `### test` entry (don't repeat Story 15.1's L2 finding). |

### Logging convention (existing — reuse)

`lib/log.sh` exports `log_info`, `log_warn`, `log_error`, `log_debug`, `die`, `log_event`. No raw `echo` for status messages (CLAUDE.md critical rule 6).

### Testing standard (Story 15.1 precedent — follow exactly)

`tests/test-<area>.sh`: `set -euo pipefail`, `mktemp -d` `$WORKDIR` + cleanup trap (docker-based `rm -rf` for root-owned artifacts — installs will create root-owned `node_modules/`, `.venv/`, `__pycache__/`), copy fixtures into `$WORKDIR` before running anything — **never** bind-mount `tests/fixtures/` directly as a writable workspace. This exact mistake was made and caught in Story 15.1's code review; there is no excuse to repeat it here now that the precedent (and the reason for it) is documented.

### What NOT to do (anti-patterns — some observed in Story 15.1's own review)

- **Don't** detect a lockfile for a package manager that isn't installed (`poetry.lock`, `Pipfile.lock`, `pnpm-lock.yaml`, `yarn.lock`) — see the scope-narrowing note above.
- **Don't** wire dependency install into `_lint`/`_format`/`_fix`/`_security` — `_test` only, per issue #52's literal scope.
- **Don't** swallow install failures and proceed to run the test suite anyway (AC 8) — a partial/broken install produces confusing downstream test failures that look like test bugs, not install bugs.
- **Don't** bind-mount checked-in fixtures directly as writable Docker workspaces (Story 15.1 code-review finding — use `mktemp` + copy + trap).
- **Don't** mock or stub the package-registry network calls in `tests/test-dependency-install.sh` — the entire point of this story is that real installs unblock real imports; a mocked test would prove nothing about the actual bug in issue #52.
- **Don't** use suppression annotations to silence shellcheck/lint on new files (CLAUDE.md critical rule 7).
- **Don't** hand-write `uv.lock`/`package-lock.json` fixture content — generate them for real inside the container and check in the actual output, the same way a real consumer's lockfile would be generated.

### Project structure notes

- All implementation lives in `~/Work/github.com/devrail-dev/dev-toolchain`. Branch: `feat/52-dependency-install-before-test` off `main` (this story's implementation branch is independent of Story 15.1's `feat/53-monorepo-project-root-discovery` — that work should already be merged or at least stable before this story lands, since this story's Makefile changes assume Story 15.1's per-root loop structure already exists in `_test`).
- Conventional commit scope: `makefile` (existing scope).
- PR description: `Closes #52`, references Story 15.2, notes dependency on Story 15.1.

## Previous Story Intelligence — Story 15.1

Story 15.1 (`15-1-autodetect-project-roots-for-python-javascript-monorepos.md`, status: `review`) is the direct foundation this story builds on. Key decisions/learnings that carry forward:

- **`discover_project_roots <language>` never returns empty** — always at least `.`. This story's `_test` wiring loops over its output exactly like Story 15.1's other four targets already do; no new "did we find a root" branching needed.
- **Tag qualification convention**: `failed_languages`/`ran_languages` entries are qualified with `:<root>` only when root ≠ `.` (e.g. `"python:api"`, unqualified `"python"` for the single-root case). This story's install-failure tag (`"python:<root>:install"`) must follow the same convention — unqualified `"python:install"` when root is `.`, so single-root consumers see byte-identical-shaped output to what they'd see if Story 15.1 didn't exist (extending the same regression guarantee).
- **Real bugs caught in 15.1's own review, don't repeat them here:**
  - A yq expression using `\t` as a field delimiter silently emitted a literal `\t` instead of a real tab, breaking `awk -F'\t'` field-splitting. `lib/project-discover.sh`'s `_project_discover_override` now uses `::` + `join()` instead of `as $var` string concatenation — if this story's `install_project_deps` needs to read `test.install`/`test.setup` via a similar yq pattern, copy that exact idiom, not the original broken one.
  - Bind-mounting checked-in `tests/fixtures/` directly as a writable Docker workspace let a Docker bind-mount quirk leave a stray root-owned file inside git-tracked fixtures. `tests/test-project-discover.sh` was rewritten to use `mktemp` + copy + cleanup trap — copy that pattern verbatim for `tests/test-dependency-install.sh`.
  - A schema doc claimed validation rules ("`path` must exist," "`languages` must be non-empty") that no code enforced. If this story's `test.install`/`test.setup` schema doc entries claim any validation, make sure the code actually does it, or word the doc to match reality.
  - `standards/makefile-contract.md` was originally missed when `standards/devrail-yml-schema.md` was updated — Task 4.2 above exists specifically so this story doesn't repeat that gap.
- **`_project_discover_normalize`'s "root wins" limitation** (documented in `devrail-yml-schema.md` after Story 15.1's review): a root-level `pyproject.toml` used only for shared tool config collapses monorepo discovery to `.`. This story's dependency-install step runs per discovered root — if a user is affected by that Story 15.1 limitation, they're already using the `projects:` override to work around it, and this story's install step composes with that transparently (it just reads whatever root Story 15.1's `discover_project_roots` hands it).

## Git Intelligence — Recent dev-toolchain Patterns

Last several commits in `github.com/devrail-dev/dev-toolchain`:

```
b348df5 fix(makefile): address Story 15.1 code-review findings
4bf9e70 feat(makefile): autodetect project roots for Python/JS monorepos
5595449 chore(release): prepare v1.12.0
60b4254 feat(makefile): docker_network/docker_volumes + rspec-rails detection (#49)
```

Patterns to **follow**:

- `lib/*.sh` sourced helper per cross-cutting concern (not per-language duplication) — Story 13.5's `dispatch_plugin_target`, Story 15.1's `lib/project-discover.sh`, now this story's `lib/dependency-install.sh`.
- `mktemp` `$WORKDIR` + docker-based cleanup trap for any test that runs `make` against fixtures — established in `tests/test-plugin-loader.sh`, reaffirmed (after a real mistake) in `tests/test-project-discover.sh`.
- One PR per story where reasonably scoped; Story 15.1 landed as two commits on one branch (initial implementation + review-fix commit) rather than a separate follow-up PR, since nothing had been pushed/merged yet when review findings came in. Follow the same shape here if code-review finds real issues: fix in the same still-local branch, don't create a `fix/15-2-review-followups` branch unless this branch has already been pushed/merged by the time review happens.

Patterns to **avoid** (from Story 15.1's own review, summarized above): lockfile detection for uninstalled tools, direct fixture bind-mounts in tests, doc/code validation-claim mismatches, incomplete documentation updates (schema doc but not makefile-contract.md).

## Latest Tech Information

- **`uv`** — officially PyPI-distributed (`pip install uv`), no separate binary download needed. **Revised during implementation:** `uv sync --frozen` populates an isolated `.venv/`, which is the wrong target for this container — `pytest` is a single globally-installed binary (like every other DevRail tool), and it cannot see into a project-local venv without explicit activation/wrapping, which `make test`'s bare `pytest` invocation doesn't do. The fix is `uv export --frozen --no-hashes --format requirements-txt | uv pip install --system --break-system-packages -r -` — converts the lockfile to a plain requirements list and installs it into the same system Python `pytest` already runs against, mirroring the `requirements.txt`/`pyproject.toml` fallback paths below. `uv export --frozen` still fails (rather than silently regenerating) if `pyproject.toml` and the lockfile disagree — the "trust the lockfile" semantics are preserved, just not via `uv sync`.
- **`npm ci`** — already implicitly relied upon elsewhere in this codebase's design intent (`_security`'s existing `npm audit` block already gates on `package-lock.json` presence, the same signal this story reuses for `npm ci`).
- No other external research required — this story shells out to already-well-documented, stable CLI tools (`uv`, `pip`, `npm`) with no version-sensitive API surface relevant to a Makefile wiring task.

## Project Context Reference

- Project root: `~/Work/gitlab.mfsoho.linkridge.net/OrgDocs/development-standards` (this repo, planning)
- Implementation repo: `~/Work/github.com/devrail-dev/dev-toolchain`
- Standards docs: `standards/makefile-contract.md`, `standards/devrail-yml-schema.md`
- CLAUDE.md critical rules apply throughout (especially #1 `make check` before completion, #6 shared logging library, #7 never suppress failing checks, #8 update docs alongside behavior changes — see Story 15.1's L2 finding for why this one specifically needs care).

## References

- [Source: GitHub issue #52](https://github.com/devrail-dev/dev-toolchain/issues/52) — original bug report; the FastAPI(`uv`)+Vue(`npm`) reproduction case this story implements exactly
- [Source: GitHub issue #53](https://github.com/devrail-dev/dev-toolchain/issues/53) — companion issue; this story depends on Story 15.1's root discovery
- [Source: `_bmad-output/planning-artifacts/epics.md#Epic 15`] — story-level AC and epic background
- [Source: `_bmad-output/implementation-artifacts/15-1-autodetect-project-roots-for-python-javascript-monorepos.md`] — direct predecessor; read in full before starting, especially its Senior Developer Review section
- [Source: `dev-toolchain/lib/project-discover.sh`] — sourced-helper pattern to mirror exactly
- [Source: `dev-toolchain/scripts/install-python.sh`] — where `uv` gets added; study the existing idempotent-install style
- [Source: `dev-toolchain/tests/test-project-discover.sh`] — test pattern to mirror (mktemp + cleanup trap, JSON summary assertions)
- [Source: `standards/makefile-contract.md`] — Makefile authoring conventions; `### projects` entry added by Story 15.1 is the template for this story's `### test` entry

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 — single-session execution via the formal `dev-story` workflow (BMad Master acting as the dev agent).

### Debug Log References

- **`uv sync` targets the wrong environment (AC 1 revision).** Implemented `uv sync --frozen` exactly as drafted, wired it into `_test`, and the end-to-end fixture test failed with `ModuleNotFoundError` even though `uv sync` reported success and the dependency was verifiably present in `.venv/lib/python3.11/site-packages/`. Root cause: `uv sync` creates and populates an isolated project venv; this container's philosophy is "tools installed once, globally" (`pytest` lives in system site-packages), and bare `pytest` — invoked with no venv activation, no `uv run` wrapper — never looks inside `.venv/`. Confirmed by hand: even `source .venv/bin/activate && which pytest` still resolved to `/usr/local/bin/pytest` (activation only prepends `.venv/bin` to PATH; since pytest isn't installed there, PATH resolution falls through to the system binary, which is a script with a hardcoded system-Python shebang — venv activation never redirects that). Considered `uv venv --system-site-packages` (lets a venv's *own* python see system packages) but that doesn't help either, since the Makefile invokes bare `pytest`, not `.venv/bin/python -m pytest`. Fixed by not creating a venv at all: `uv export --frozen --no-hashes --format requirements-txt | uv pip install --system --break-system-packages -r -` installs the lockfile's resolved packages straight into system site-packages, exactly where `pytest` already looks. `--break-system-packages` was also needed on top of `--system` — this Debian Python is PEP 668 "externally managed," the same reason `scripts/install-python.sh` already carries a `--break-system-packages` fallback for the tool installs themselves. Applied the same flag to the `requirements.txt`/`pyproject.toml` `pip install` paths too, once discovered — bare `pip install` without it fails outright on this container (verified directly before assuming it was fine).
- **Real bug: exit code always 0 on install failure (AC 8 violation, caught by testing AC 8 explicitly before marking the task done).** Original `install_project_deps`/`run_project_setup` used `if (subshell); then return 0; fi; local rc=$?; ...; return "$rc"`. A dedicated fixture (`python-install-fails`, a `requirements.txt` naming a nonexistent package, with a test that raises `AssertionError` if it ever runs) proved pytest ran anyway — `overall_exit` never got set, `failed_languages` showed plain `"python"` (from pytest's own failure) instead of `"python:install"`. Root cause, confirmed by isolated repro (`if (false); then return 0; fi; echo $?` prints `0`, not `1`): per POSIX, an `if` with no `else` branch taken has exit status **zero** when the condition is false — not the condition's own exit code. `$?` read after a bare `fi` is therefore always 0 in this shape, regardless of what failed. This is not a `local`-specific quirk (masking $? via `local var=$(cmd)` is the well-known one, per ShellCheck SC2155, but this bug reproduces with plain `rc=$?` too, and outside any function) — it's this specific "check $? after a bare `if...fi` with no `else`" antipattern. Fixed by moving the failure handling into an explicit `else` branch, where `$?` genuinely reflects the failed condition. Re-verified: `python-install-fails` now correctly reports `{"status":"fail","failed":["python:install"]}` and the test suite's "should never run" assertion is never reached.
- Picked fixture dependencies (`first`, `humanize`, `inflection` for Python; `ms` for JS) by first checking `pip list`/`npm ls` output for what's *already* globally present in the container (via ruff/bandit/semgrep/ansible-lint/etc.'s own transitive dependencies) — an initial attempt using `six` silently "passed" even with zero install logic wired up, because `six` turned out to already be a transitive dependency of something else in the image. Confirmed each chosen package is genuinely absent before treating a fixture as valid.
- Validated with the same fast-overlay-image technique as Story 15.1 (`FROM ghcr.io/devrail-dev/dev-toolchain:1.12.0` + `COPY lib/ scripts/install-python.sh`, then `RUN bash install-python.sh` to pick up the new `uv` tool) rather than a full multi-stage rebuild — confirmed `uv 0.11.32` installs cleanly via `pip install uv` with no Dockerfile stage changes needed, exactly as anticipated during story creation.

### Completion Notes List

- All 10 ACs implemented; AC 1 revised mid-implementation (see debug log) — the `uv` install mechanism changed, the underlying guarantee (install from `uv.lock`, fail if lockfile disagrees with `pyproject.toml`) did not.
- `uv` added to the container: one line in `scripts/install-python.sh`'s existing `PYTHON_TOOLS` array (idempotency and install pattern already handled by that script's loop — no new code needed there), `uv --version` added to `tests/test-python.sh`.
- `lib/dependency-install.sh` (~120 lines): `install_project_deps <language> <root>` and `run_project_setup <root>`, mirroring `lib/project-discover.sh`'s sourced-helper shape exactly. `.devrail.yml` `test.install`/`test.setup` resolved via an absolute path captured at source time (before any per-root `cd`), avoiding the same relative-path-after-cd class of bug Story 15.1 had to get right for its own override reads.
- Wired into `_test` only (Python + JavaScript blocks), inside Story 15.1's existing per-root loop: install → setup → existing test-file gate → pytest/vitest. Install/setup failures are tagged `<lang>:<root>:install` / `<lang>:<root>:setup` (unqualified `<lang>:install` when root is `.`, matching Story 15.1's tag convention), and short-circuit before the test suite runs (AC 8, verified with a dedicated failing-install fixture — not just asserted from reading the code).
- `.devrail.yml` `test.install`/`test.setup` documented in both `standards/devrail-yml-schema.md` and `standards/makefile-contract.md` — Story 15.1's code review flagged the schema-doc-only, makefile-contract-doc-missed gap explicitly as something not to repeat; both got updated in this story from the start.
- 7 new fixtures under `dev-toolchain/tests/fixtures/`: `python-uv-deps` (real generated `uv.lock`), `python-requirements-deps`, `python-pyproject-only`, `python-install-fails` (AC 8), `js-npm-deps` (real generated `package-lock.json`), `test-install-override`, `test-setup-ordering`. Reused Story 15.1's `declared-lang-no-manifest` fixture for the AC 7 regression case rather than creating a redundant one.
- `tests/test-dependency-install.sh`: 10 assertions, all against real `make _test` runs with real network installs (PyPI/npm) inside the container — no mocking, per the story's own explicit anti-pattern list. Uses the `mktemp` `$WORKDIR` + cleanup-trap pattern from the start (Story 15.1 had to retrofit this after a review finding; this story didn't repeat the mistake in the committed script — though seven ad hoc manual `docker run` commands during interactive debugging *did* directly bind-mount Story 15.1's already-committed fixtures at one point and left transient stray `Makefile`/`.egg-info`/`__pycache__` artifacts in the working tree; caught and cleaned via `git status --short` before staging, nothing landed in a commit).
- CI wired: new "Dependency install smoke test" step in `.github/workflows/ci.yml`, after Story 15.1's step.
- `CHANGELOG.md` `[Unreleased] → Added` and `STABILITY.md` (new "Dependency install before `make test` (Python/JS)" row, Preview) updated.

**Verification (all green, against a fast Docker overlay of `ghcr.io/devrail-dev/dev-toolchain:1.12.0` + the new `lib/`/`scripts/install-python.sh`/`tests/test-python.sh`):**

- `shellcheck`/`shfmt` across the **full repo** file set (matching the real `_lint` invocation exactly, not an isolated subset) — clean
- `bash tests/test-dependency-install.sh` — **10 passed, 0 failed**, including the AC 8 fail-fast case with a real network-resolvable-but-nonexistent package
- `bash tests/test-project-discover.sh` (Story 15.1) — 20/20, confirming no regression from `_test`'s new install/setup wiring
- `bash tests/test-plugin-loader.sh` (Story 13.2) — all pass, confirming the third `lib/*.sh` source line added to `_test`'s prelude doesn't regress the plugin loader
- `bash tests/smoke-rails.sh` — all pass, confirming Ruby's `_test` path (untouched by this story) is unaffected
- Manual fixture-by-fixture `make _test` runs for every new fixture, both before (`ModuleNotFoundError`/unresolved-import, matching issue #52's actual reported failure) and after wiring the install step (pass) — not just trusting the test script's assertions in isolation

**Not run:** a full `docker build` of the real multi-stage Dockerfile (same rationale as Story 15.1 — the Rust/Swift/Kotlin/Ruby builder stages are too slow for iterative local validation; `scripts/install-python.sh` runs directly in the final stage with no COPY dependency, so the overlay technique is equivalent for this story's purposes). CI's real build will exercise it. `make check` on the dev-toolchain repo itself was not re-run (repo declares `languages: [bash]` only, doesn't exercise this story's code path).

**No PR opened yet** — implementation complete and committed locally to `feat/52-dependency-install-before-test` (branched from `feat/53-monorepo-project-root-discovery`, which is itself not yet pushed/merged), pending user confirmation to push, matching the standing session default for visible-to-others actions.

### File List

**Implementation (dev-toolchain repo, branch `feat/52-dependency-install-before-test`, based on `feat/53-monorepo-project-root-discovery`):**

- `lib/dependency-install.sh` — new
- `scripts/install-python.sh` — modified (added `uv` to `PYTHON_TOOLS`, header/help text)
- `tests/test-python.sh` — modified (added `uv --version` check)
- `Makefile` — modified (`_test` only: sourced the new lib; wired `install_project_deps`/`run_project_setup` into the Python and JavaScript per-root loops)
- `tests/test-dependency-install.sh` — new
- `tests/fixtures/python-uv-deps/**` — new (includes a real, container-generated `uv.lock`)
- `tests/fixtures/python-requirements-deps/**` — new
- `tests/fixtures/python-pyproject-only/**` — new
- `tests/fixtures/python-install-fails/**` — new (AC 8)
- `tests/fixtures/js-npm-deps/**` — new (includes a real, container-generated `package-lock.json`)
- `tests/fixtures/test-install-override/**` — new
- `tests/fixtures/test-setup-ordering/**` — new
- `.github/workflows/ci.yml` — modified (new "Dependency install smoke test" step)
- `CHANGELOG.md` — modified (`[Unreleased] → Added` entry)
- `STABILITY.md` — modified (new component row)

**Story tracking + schema doc (OrgDocs/development-standards repo, branch `feat/15-2-create-story`):**

- `_bmad-output/implementation-artifacts/15-2-autodetect-and-install-python-js-dependencies-before-make-test.md` — this file (status, all task checkboxes, AC 1 revision, Dev Agent Record, File List)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — will need a further update to `15-2: review`
- `standards/devrail-yml-schema.md` — modified (`test:` key documented, both the per-key section and the summary table)
- `standards/makefile-contract.md` — modified (`### test` entry + Supported Keys row, from the start — not a post-review fix this time)

## Change Log

| Date | Change |
|---|---|
| 2026-07-25 | Story created via the formal `create-story` workflow (auto-discovered as the first `backlog` story in `sprint-status.yaml`), following exhaustive artifact analysis. Critical scope-narrowing finding during creation: the container image doesn't have `uv`/`poetry`/`pipenv`/`pnpm`/`yarn` installed — only `pip` and `npm`. Scoped to `uv`+`pip` (Python) and `npm` (JS), matching issue #52's literal reproduction case, with `poetry`/`pipenv`/`pnpm`/`yarn` explicitly deferred. Status: `ready-for-dev`. |
| 2026-07-25 | Ran the formal `dev-story` workflow end to end (red-green-refactor per task, real fixtures, real network installs). Two real bugs found and fixed during implementation, not just at review: AC 1's `uv sync` targeted the wrong (isolated venv) environment and never actually worked with this container's globally-installed `pytest`; a `local rc=$?` placement bug meant every install failure was silently treated as success (AC 8 violation), caught only because AC 8 was tested with a dedicated failing-install fixture rather than assumed correct from reading the code. Full regression suite green (project-discover, plugin-loader, smoke-rails, plus the new 10-assertion dependency-install suite). Status moved to `review`. Committed locally to `feat/52-dependency-install-before-test`; not pushed. |
