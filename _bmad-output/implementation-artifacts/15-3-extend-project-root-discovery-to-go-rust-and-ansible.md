# Story 15.3: Extend Project-Root Discovery to Go and Rust

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **developer with a Go or Rust module living in a monorepo subdirectory** (e.g. `services/api/go.mod`, no `go.mod` at repo root),
I want `make lint`/`format`/`fix`/`test`/`security` to discover that module's root and run Go/Rust tools from there,
so that `go test`/`golangci-lint`/`cargo test`/`cargo clippy`/`cargo fmt` don't fail outright with "directory prefix . does not contain main module" / "could not find Cargo.toml" errors.

## Acceptance Criteria

1. **Given** a repo with `services/api/go.mod` (no `go.mod` at repo root)
   **When** `make lint`, `make format`, `make fix`, `make test`, or `make security` runs with no `projects:` override in `.devrail.yml`
   **Then** DevRail discovers `services/api` as the Go root and runs `golangci-lint`/`gofumpt`/`go test`/`govulncheck` with that directory as cwd
   **And** the same failure this story fixes is reproducible today without it: `go test ./...` run from repo root against this layout fails with `pattern ./...: directory prefix . does not contain main module or its selected dependencies`; `golangci-lint run ./...` fails (exit 7) with a typechecking error despite printing a misleading `0 issues.` — confirmed by hand against a real fixture before writing this story, not assumed from the original epic draft (which incorrectly claimed Go "already resolves fine from repo root")

2. **Given** a repo with `services/api/Cargo.toml` (no `Cargo.toml` at repo root)
   **When** any of the five targets above runs
   **Then** DevRail discovers `services/api` as the Rust root and runs `cargo clippy`/`cargo fmt`/`cargo test`/`cargo audit`/`cargo deny` with that directory as cwd
   **And** the same pre-existing failure applies: `cargo clippy`/`cargo fmt --check`/`cargo test` from repo root against this layout all fail with `could not find Cargo.toml in /workspace or any parent directory` — confirmed by hand, same as AC 1

3. **Given** discovery reuses Story 15.1's `lib/project-discover.sh` infrastructure
   **When** implemented
   **Then** `discover_project_roots go` and `discover_project_roots rust` are added as two new `case` branches — `_project_discover_autodetect_go` (searches for `go.mod`) and `_project_discover_autodetect_rust` (searches for `Cargo.toml`), each piped through the existing `_project_discover_normalize` (root-wins / fallback-to-`.` / multi-root) exactly like `python`/`javascript` already are
   **And** no new library file is created — this is a generalization of existing Story 15.1 code, not a new subsystem

4. **Given** a single-module repo with `go.mod`/`Cargo.toml` at the root (the common case — e.g. this dev-toolchain repo's own future Go/Rust tooling, or any existing DevRail Go/Rust consumer today)
   **When** any target runs
   **Then** the discovered root is exactly `.` — output, exit codes, and JSON event shape are byte-for-byte unchanged from pre-Story-15.3 behavior (regression-safe, identical guarantee to Story 15.1 AC 4)

5. **Given** an explicit `projects:` override in `.devrail.yml` naming `go` or `rust`
   **When** any target runs
   **Then** the override is honored exactly as it already is for `python`/`javascript` (no special-casing needed — `_project_discover_override` is already language-agnostic)

6. **Given** Ansible was in the epic's original scope for this story
   **When** investigated (before writing any code)
   **Then** `ansible-lint` (run bare, from repo root, with playbooks only in a subdirectory) already recursively discovers and lints them correctly with no root-discovery changes needed — confirmed by hand against a real fixture (`deploy/playbooks/site.yml`, no `ansible.cfg` anywhere): `ansible-lint` found and evaluated the file, producing a legitimate lint finding, not a "nothing found" no-op or a crash
   **And** Ansible is therefore explicitly OUT of this story's scope — the epic's "Go, Rust, and Ansible" framing was wrong on the Ansible part; this story only touches Go and Rust

7. **Given** a monorepo with multiple Go (or Rust) module roots (e.g. `services/a/go.mod` and `services/b/go.mod`)
   **When** a target runs
   **Then** the tool runs once per discovered root, and results/failures are attributed per path in the JSON summary, matching Story 15.1 AC 7's guarantee for Python/JS

8. **Given** a passing test suite
   **When** `bash tests/test-project-discover.sh` runs (Story 15.1's suite, extended — not a new script)
   **Then** it additionally covers: Go monorepo root discovery, Rust monorepo root discovery, single-root Go/Rust regression case, and full `make _lint`/`make _test` integration against real Go and Rust fixtures

## Tasks / Subtasks

- [ ] **Task 1: Extend `lib/project-discover.sh`** (AC: 3, 4, 5, 7)
  - [ ] 1.1 Add `_project_discover_autodetect_go`: `find . -name 'go.mod' <excludes> -print0 | xargs -0 -I{} dirname {} | sort -u | sed 's#^\./##' | _project_discover_normalize` — mirrors `_project_discover_autodetect_python`/`_javascript` exactly (same `_PROJECT_DISCOVER_FIND_EXCLUDES` array, same `-print0`/`xargs -0` shellcheck-clean pattern established in Story 15.1).
  - [ ] 1.2 Add `_project_discover_autodetect_rust`: same shape, `find . -name 'Cargo.toml' ...`.
  - [ ] 1.3 Add `go` and `rust` cases to `discover_project_roots`'s `case` statement, calling the two new functions. Update the header comment's "Supported languages: python, javascript" line to add go/rust, and note Ansible was investigated and excluded (with the reason) rather than silently left out.
  - [ ] 1.4 No changes to `_project_discover_override`, `_project_discover_normalize`, or the exclude-paths array — all already language-agnostic.

- [ ] **Task 2: Wire into `_lint`, `_format`, `_fix`, `_test`, `_security`** (AC: 1, 2, 4, 7)
  - [ ] 2.1 `_lint`: wrap the `HAS_GO` block's `golangci-lint run ./...` in a `discover_project_roots go` loop, `(cd "$root" && golangci-lint run ./...)` per root, same tag-qualification convention as Python/JS (`"go"` unqualified at root `.`, `"go:services/api"` otherwise). Same for `HAS_RUST`'s `cargo clippy --all-targets --all-features -- -D warnings`.
  - [ ] 2.2 `_format`: `gofumpt -d .` (Go) and `cargo fmt --all -- --check` (Rust), same loop pattern.
  - [ ] 2.3 `_fix`: `gofumpt -w .` (Go) and `cargo fmt --all` (Rust).
  - [ ] 2.4 `_test`: `go test ./...` (Go) and `cargo test --all-targets` (Rust) — both already gate on file existence (`*_test.go` / `.rs` files + `Cargo.toml`) before running; scope those `find`/existence checks to the discovered root, not the whole repo, exactly like Story 15.1 did for Python/JS's test-file gates.
  - [ ] 2.5 `_security`: `govulncheck ./...` (Go, gated on `go.sum`) and `cargo audit` + `cargo deny check` (Rust, gated on `Cargo.lock`/`deny.toml`) — same per-root loop, same gate-scoped-to-root treatment.
  - [ ] 2.6 Do **not** touch `_docs`/`_init`'s Go/Rust blocks (config scaffolding / doc generation) — out of scope, matching Story 15.1's precedent exactly.
  - [ ] 2.7 No `lib/dependency-install.sh` changes and no wiring of it into Go/Rust — `go test`/`cargo test`/`cargo build` already fetch module/crate dependencies automatically as part of running; there is no Python-`pip`/JS-`npm`-shaped "nothing is importable until an explicit install step runs" problem for these two ecosystems. Confirm this reasoning holds (it does — this was already the epic's original, correct reasoning for excluding Go/Rust from Story 15.2 dependency-install scope) but do not add an install step regardless.

- [ ] **Task 3: `.devrail.yml` schema + docs** (AC: 5, 6)
  - [ ] 3.1 `standards/devrail-yml-schema.md`'s `projects` section already documents `go`/`rust` as valid `languages:` values for `projects:` entries in principle (the schema was written language-agnostically) — verify the worked example doesn't need a Go/Rust-specific addition; if the "Currently honored for python and javascript only" line still exists anywhere, update it to include go/rust.
  - [ ] 3.2 `standards/makefile-contract.md`'s `### projects` entry — update "For Python and JavaScript/TypeScript" framing to include Go/Rust.
  - [ ] 3.3 Do **not** claim Ansible support anywhere — this story explicitly investigated and excluded it (AC 6). If any existing doc text implies "Ansible root-awareness is a follow-on story," correct it to state Ansible doesn't need one.

- [ ] **Task 4: Test fixtures + smoke test extension** (AC: 8)
  - [ ] 4.1 `tests/fixtures/go-monorepo/services/api/{go.mod,main.go,main_test.go}` — a real, minimal Go module with one passing test, in a subdirectory (no `go.mod` at fixture root).
  - [ ] 4.2 `tests/fixtures/rust-monorepo/services/api/{Cargo.toml,src/lib.rs}` — same shape for Rust, one passing `#[test]`.
  - [ ] 4.3 `tests/fixtures/go-single-root/{go.mod,main.go,main_test.go}` — regression fixture, AC 4.
  - [ ] 4.4 `tests/fixtures/rust-single-root/{Cargo.toml,src/lib.rs}` — regression fixture, AC 4.
  - [ ] 4.5 Extend `tests/test-project-discover.sh` (do not create a new script) with unit-level `discover_project_roots go`/`rust` assertions against the new fixtures, plus integration-level `make _lint`/`make _test` runs proving the per-root cwd fix actually resolves the reproduced failures from AC 1/2 (assert `status: pass`, not just "didn't crash").
  - [ ] 4.6 Keep using the `mktemp` `$WORKDIR` + cleanup-trap pattern already established — no direct fixture bind-mounts.

- [ ] **Task 5: CI + docs**
  - [ ] 5.1 No new CI step — `tests/test-project-discover.sh` is already wired into `.github/workflows/ci.yml`; extending it in place means no workflow file change needed.
  - [ ] 5.2 `CHANGELOG.md` `[Unreleased]` → `### Added`: one-line note extending monorepo project-root discovery to Go/Rust, noting Ansible was evaluated and needs no change.
  - [ ] 5.3 `STABILITY.md`: extend Story 15.1's "Monorepo project-root discovery (Python/JS)" row to include Go/Rust (rename if it reads better as "Python/JS/Go/Rust"), rather than adding a whole new row — this is a generalization of the same feature, not a new one.
  - [ ] 5.4 Close GitHub issue #53 for real this time if it's still open for the Go/Rust/Ansible gap specifically — check first; it may already be closed by Story 15.1's PR since the issue's own reproduction case was Python/JS only.

## Dev Notes

### Why this story's scope differs from the epic draft

The epic (`epics.md` Story 15.3) originally read: *"Lower priority than 15.1/15.2 — Go and Rust already resolve fine from repo root in the common case since `go test ./...` and `cargo test` recurse, and Ansible's root signal is fuzzier than a single manifest file."* Both halves of that reasoning were checked by hand before writing this story and turned out backwards:

- **Go/Rust do NOT resolve fine from repo root** when the module isn't rooted there. `go test ./...`, `golangci-lint run ./...`, `cargo test`, `cargo clippy`, `cargo fmt --check` were all reproduced failing against real fixtures with `go.mod`/`Cargo.toml` in a subdirectory — the exact same class of bug issue #53 reported for Python/JS, just unfixed here. This raises this story's priority, not lowers it.
- **Ansible does NOT need root discovery.** `ansible-lint` run bare from repo root against a fixture with playbooks only in `deploy/playbooks/` (no `ansible.cfg` anywhere) correctly found and linted the file — Ansible's tooling already walks the tree looking for YAML content rather than requiring a root marker the way Go/Rust module systems do. Including it in this story would have meant writing discovery logic for a language that doesn't need any.

This is exactly the kind of thing `create-story`'s exhaustive-analysis mandate exists to catch — verify claims made in planning documents against actual tool behavior before writing acceptance criteria around them, rather than carrying an unverified assumption forward into implementation.

### Architecture — this is a generalization, not new work

Everything Story 15.1 built is already language-agnostic:

- `_project_discover_override` reads `projects:` for any language name.
- `_project_discover_normalize` (root-wins / fallback-to-`.` / multi-root) has zero Python/JS-specific logic.
- The only per-language pieces are the two tiny `_project_discover_autodetect_<lang>` functions (one `find` call each) and the `discover_project_roots` dispatch `case`. Adding Go/Rust is two new ~6-line functions and two new `case` branches — not a new file, not a new pattern.

The Makefile wiring is the same shape as Story 15.1's Task 2, applied to 2 more languages × 5 targets = 10 more call sites (same total shape Story 15.1 had for Python/JS).

### Backward-compatibility note (identical guarantee to Story 15.1)

Single-root Go/Rust repos (`go.mod`/`Cargo.toml` at the repo root — the overwhelming majority of today's consumers) must see byte-identical output after this story lands: unqualified `"go"`/`"rust"` tags, no behavior change. Verify this explicitly with a dedicated regression fixture per language (Task 4.3/4.4), not just by inspection.

### What NOT to do

- **Don't** re-derive the "Go/Rust already work fine" claim without testing it — it's wrong, and this story exists specifically because it's wrong. If a future story needs to check similar epic-draft claims for other languages, check them the same way: reproduce the failure by hand first.
- **Don't** create a new `lib/*.sh` file — extend the existing `lib/project-discover.sh`.
- **Don't** add Ansible root-discovery logic — investigated and confirmed unnecessary (AC 6).
- **Don't** add dependency-install wiring for Go/Rust (Story 15.2's concern) — `go test`/`cargo test` fetch their own deps; there's no `ModuleNotFoundError`-shaped gap for these two ecosystems.
- **Don't** bind-mount checked-in fixtures directly as writable Docker workspaces — use the `mktemp` `$WORKDIR` + cleanup-trap pattern, same as every prior story in this epic.
- **Don't** create a second test script — extend `tests/test-project-discover.sh` in place; it already exists for exactly this purpose (project-root discovery, regardless of which languages it currently covers).

### Project structure notes

- All implementation lives in `~/Work/github.com/devrail-dev/dev-toolchain`. Branch: `feat/53-go-rust-project-root-discovery` off `main` (or off Story 15.1/15.2's branches if those haven't merged yet by the time this lands — check current state before branching).
- Conventional commit scope: `makefile`.
- PR description: closes the Go/Rust portion of #53 if not already closed.

## Previous Story Intelligence — Stories 15.1 and 15.2

- **Story 15.1** (`lib/project-discover.sh`, status: `review`) is this story's direct foundation — read it in full, especially the "root wins" limitation documented in its Senior Developer Review (H1) and the schema doc's "Known autodetection limitation" note. That limitation applies identically to Go/Rust once this story lands (a root-level `go.mod` used only for a thin wrapper module, with real modules in subdirectories, would collapse to root-only) — no new work needed, just be aware the existing documented caveat now covers 4 languages instead of 2.
- **Story 15.2** (`lib/dependency-install.sh`, status: `review`) is a sibling, not a dependency — this story doesn't touch it. Confirmed during story creation that Go/Rust don't need an equivalent (see Dev Notes).
- **Real bugs caught in prior stories' reviews, don't repeat them here:**
  - yq `\t`-as-delimiter silently breaking `awk` field-splitting (15.1) — not relevant here, this story adds no new yq expressions.
  - Bind-mounting checked-in fixtures directly, leaking stray Docker-bind-mount artifacts into tracked directories (15.1, and repeated ad hoc during 15.2's manual debugging even after being fixed once) — use `mktemp` + copy + trap, every time, including for quick manual `docker run` sanity checks during implementation, not just in the committed test script.
  - `local rc=$?` after a bare `if...fi` with no `else` always reading `0` (15.2) — not relevant here unless this story's Makefile edits introduce a similar exit-code-capture pattern; if they do, capture inside an explicit `else`.
  - Story file ACs going stale relative to a mid-implementation revision (both 15.1's AC 5 and 15.2's AC 1/AC 9) — if anything about this story's design changes during implementation (e.g., the exact `find`/exclude pattern), update the AC text to match, don't leave it describing the originally-drafted-but-superseded approach.

## Git Intelligence — Recent dev-toolchain Patterns

```
5bd113b fix(makefile): address Story 15.2 code-review findings
dc0479e feat(makefile): install project dependencies before make test
b348df5 fix(makefile): address Story 15.1 code-review findings
4bf9e70 feat(makefile): autodetect project roots for Python/JS monorepos
```

Patterns to **follow**: one feature commit + one review-fix commit per story (not a separate follow-up PR, since nothing in this epic has been pushed/merged yet); `mktemp` + cleanup trap for every test touching `make` + fixtures; extend existing `lib/*.sh`/test scripts rather than creating parallel new ones when the existing one already covers the concern; verify claims by reproducing them, not by reading code and assuming.

## Project Context Reference

- Project root: `~/Work/gitlab.mfsoho.linkridge.net/OrgDocs/development-standards` (this repo, planning)
- Implementation repo: `~/Work/github.com/devrail-dev/dev-toolchain`
- CLAUDE.md critical rules apply throughout (especially #1 `make check`, #6 shared logging library, #7 never suppress failing checks, #8 update docs alongside behavior changes).

## References

- [Source: GitHub issue #53](https://github.com/devrail-dev/dev-toolchain/issues/53) — original bug report; Story 15.1 fixed the Python/JS portion, this story fixes the Go/Rust portion (Ansible needs no fix — see AC 6)
- [Source: `_bmad-output/planning-artifacts/epics.md#Epic 15`] — story-level AC and epic background (note: this story's Dev Notes documents where the epic draft's own assumptions were wrong)
- [Source: `_bmad-output/implementation-artifacts/15-1-autodetect-project-roots-for-python-javascript-monorepos.md`] — direct predecessor; the mechanism this story generalizes
- [Source: `dev-toolchain/lib/project-discover.sh`] — file this story extends
- [Source: `dev-toolchain/tests/test-project-discover.sh`] — test script this story extends

## Dev Agent Record

_(populated during dev-story execution)_

## Change Log

| Date | Change |
|---|---|
| 2026-07-26 | Story created via the formal `create-story` workflow (auto-discovered as the first `backlog` story). Investigated the epic draft's claims by hand before writing ACs: reproduced `go test ./...`/`golangci-lint`/`cargo test`/`cargo clippy`/`cargo fmt` all genuinely failing for a monorepo Go/Rust module not rooted at the repo root (epic draft was wrong — this is not low-priority, it's a real unfixed instance of issue #53), and reproduced `ansible-lint` already working correctly without any root-discovery changes (epic draft was also wrong here — Ansible is out of scope, not a follow-on). Scope corrected to Go + Rust only, framed as a generalization of Story 15.1's existing `lib/project-discover.sh` rather than new work. Status: `ready-for-dev`. |
