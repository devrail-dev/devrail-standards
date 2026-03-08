# Story 4.5: Update Conventional Commit Scopes for All Languages

Status: ready-for-dev

## Story

As a developer,
I want the pre-commit conventional commits hook to accept all current language scopes,
so that commits for Ruby, Go, JavaScript, Rust, and new workflow scopes are not rejected.

## Acceptance Criteria

1. The hook accepts all language scopes: python, bash, terraform, ansible, ruby, go, javascript, rust
2. The hook accepts all workflow scopes: container, ci, makefile, standards, security, changelog, release
3. The updated hook version is referenced in both template repos' `.pre-commit-config.yaml`
4. The dev-toolchain repo's `.pre-commit-config.yaml` references the updated hook
5. `make check` passes on all updated repos

## Tasks / Subtasks

- [ ] Task 1: Update pre-commit-conventional-commits repo (AC: 1, 2)
  - [ ] 1.1 Update `VALID_SCOPES` in `conventional_commits/config.py` — add: ruby, go, javascript, rust, security, changelog, release
  - [ ] 1.2 Update test suite in `tests/test_check.py` — add parametrized cases for new scopes
  - [ ] 1.3 Update `tests/test_config.py` — verify VALID_SCOPES count matches expected
  - [ ] 1.4 Update README.md — add new scopes to the valid scopes list
  - [ ] 1.5 Sync DEVELOPMENT.md — add rust, security, changelog, release (ruby/go/javascript already there)
  - [ ] 1.6 Run `make check` and all tests pass
  - [ ] 1.7 Tag new version (v1.1.0 — minor bump for new scopes)

- [ ] Task 2: Update dev-toolchain `.pre-commit-config.yaml` (AC: 4)
  - [ ] 2.1 Bump `rev:` from `v1.0.0` to `v1.1.0` for the conventional-commits hook
  - [ ] 2.2 Run `make check` passes

- [ ] Task 3: Update github-repo-template `.pre-commit-config.yaml` (AC: 3)
  - [ ] 3.1 Bump `rev:` from `v1.0.0` to `v1.1.0` for the conventional-commits hook
  - [ ] 3.2 Run `make check` passes

- [ ] Task 4: Update gitlab-repo-template `.pre-commit-config.yaml` (AC: 3)
  - [ ] 4.1 Bump `rev:` from `v1.0.0` to `v1.1.0` for the conventional-commits hook
  - [ ] 4.2 Run `make check` passes

## Dev Notes

- The scope validation is hardcoded in Python: `conventional_commits/config.py` uses a `frozenset` called `VALID_SCOPES`
- The check module (`check.py`) uses regex `r"^(?P<type>[a-z]+)\((?P<scope>[a-z]+)\): (?P<description>.+)$"` and validates scope membership
- Current `VALID_SCOPES` in config.py: python, terraform, bash, ansible, container, ci, makefile, standards (8 scopes)
- DEVELOPMENT.md already documents ruby, go, javascript but config.py doesn't implement them — this is a known doc/code mismatch
- All three downstream repos (dev-toolchain, github-template, gitlab-template) pin `rev: v1.0.0` with no hook_args overrides
- No hook_args mechanism exists for per-repo scope customization — scopes are centralized in the hook package

### Project Structure Notes

- `pre-commit-conventional-commits/` — source of truth for scope validation
  - `conventional_commits/config.py` — VALID_SCOPES frozenset
  - `conventional_commits/check.py` — regex + validation logic
  - `tests/test_check.py` — parametrized acceptance tests
  - `tests/test_config.py` — config validation tests
- Downstream consumers all use identical hook config block (no per-repo overrides)

### References

- [Source: pre-commit-conventional-commits/conventional_commits/config.py] — VALID_SCOPES definition
- [Source: pre-commit-conventional-commits/conventional_commits/check.py] — validation logic
- [Source: dev-toolchain/.pre-commit-config.yaml] — rev: v1.0.0
- [Source: github-repo-template/.pre-commit-config.yaml] — rev: v1.0.0
- [Source: gitlab-repo-template/.pre-commit-config.yaml] — rev: v1.0.0
- [Source: epics.md#Story 4.5] — acceptance criteria

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
