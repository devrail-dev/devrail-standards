# Story 4.4: Create make install-hooks Target

Status: done

## Story

As a developer,
I want a single `make install-hooks` command that sets up all pre-commit hooks for my project,
so that getting started with local enforcement is a one-command operation.

## Acceptance Criteria

1. **Given** a DevRail-compliant project with `.pre-commit-config.yaml`, **When** `make install-hooks` is run, **Then** pre-commit is installed (if not already present) and hooks are registered in `.git/hooks`
2. **Given** `make install-hooks` has already been run, **When** it is run again, **Then** it completes successfully without errors (idempotent)
3. **Given** the developer is on macOS or Linux, **When** `make install-hooks` is run, **Then** it completes successfully on both platforms
4. **Given** `make install-hooks` succeeds, **When** clear output is examined, **Then** it reports success with a message confirming hooks are installed
5. **Given** `make install-hooks` fails (e.g., Python not available), **When** the error output is examined, **Then** it provides a clear error message explaining what went wrong and how to fix it
6. **Given** hooks are installed via `make install-hooks`, **When** the developer runs `git commit`, **Then** all configured pre-commit hooks trigger (conventional commits, linting, formatting, gitleaks, terraform-docs)

## Tasks / Subtasks

- [x] Task 1: Implement the `install-hooks` Makefile target (AC: #1, #2, #3)
  - [x] 1.1: Add `install-hooks` as a public target in the reference Makefile with `## Install pre-commit hooks` description
  - [x] 1.2: Add `install-hooks` to the `.PHONY` declaration
  - [x] 1.3: Implement pre-commit installation check — detect if `pre-commit` is already on PATH
  - [x] 1.4: If pre-commit is not installed, install via `pip install pre-commit` (prefer `pipx install pre-commit` if `pipx` is available)
  - [x] 1.5: Run `pre-commit install` to register hooks in `.git/hooks/pre-commit` and `.git/hooks/commit-msg`
  - [x] 1.6: Run `pre-commit install --hook-type commit-msg` explicitly to ensure the commit-msg hook is registered (needed for conventional commits)
  - [x] 1.7: Ensure the target is idempotent — re-running does not error or duplicate hooks
  - [x] 1.8: Verify compatibility on macOS (zsh default shell, Homebrew Python) and Linux (bash default shell, system/apt Python)
- [x] Task 2: Implement success and error output (AC: #4, #5)
  - [x] 2.1: On success, print a clear message: "Pre-commit hooks installed successfully. Hooks will run on every commit."
  - [x] 2.2: On failure to find Python, print: "Error: Python 3 is required to install pre-commit. Install Python 3 and try again."
  - [x] 2.3: On failure to install pre-commit, print the pip/pipx error and suggest manual installation
  - [x] 2.4: On failure to register hooks (e.g., not in a git repo), print: "Error: Not in a git repository. Run 'git init' first."
  - [x] 2.5: Use exit code 0 for success, exit code 2 for misconfiguration (missing Python, not a git repo)
- [x] Task 3: Verify end-to-end hook triggering (AC: #6)
  - [x] 3.1: After `make install-hooks`, verify `.git/hooks/pre-commit` exists and is executable
  - [x] 3.2: After `make install-hooks`, verify `.git/hooks/commit-msg` exists and is executable
  - [x] 3.3: Make a test commit with a valid conventional commit message — verify all hooks fire
  - [x] 3.4: Make a test commit with an invalid message — verify it is rejected
  - [x] 3.5: Make a test commit with a staged file containing a secret pattern — verify gitleaks blocks it
  - [x] 3.6: Document the full end-to-end flow in the Makefile comments or README
- [x] Task 4: Document the target in the Makefile contract (AC: #1, #4)
  - [x] 4.1: Ensure `make help` shows `install-hooks` with its description
  - [x] 4.2: Add comments in the Makefile explaining the install-hooks implementation
  - [x] 4.3: Note that `install-hooks` is the ONE target that runs on the host, not inside the container

## Dev Notes

### Critical Architecture Constraints

**`install-hooks` is the ONLY public Makefile target that runs on the host machine, not inside the container.** All other targets (lint, format, test, security, scan, docs, check) delegate to Docker. `install-hooks` must run directly on the developer's machine because it modifies `.git/hooks/`, which is a host-side concern.

**Pre-commit requires Python 3.** This is an unavoidable dependency for the host machine. The target should detect Python availability and provide a clear error if it is missing. Do not attempt to install Python — only install the `pre-commit` package.

**This target must work without the dev-toolchain container.** A developer should be able to clone a repo and run `make install-hooks` immediately, before pulling any Docker images.

**Source:** [architecture.md - Makefile Authoring Patterns, Enforcement Guidelines]

### Implementation Pattern

```makefile
install-hooks: ## Install pre-commit hooks
	@if ! command -v python3 >/dev/null 2>&1; then \
		echo "Error: Python 3 is required to install pre-commit. Install Python 3 and try again."; \
		exit 2; \
	fi
	@if ! command -v pre-commit >/dev/null 2>&1; then \
		echo "Installing pre-commit..."; \
		if command -v pipx >/dev/null 2>&1; then \
			pipx install pre-commit; \
		else \
			pip install --user pre-commit; \
		fi; \
	fi
	@pre-commit install
	@pre-commit install --hook-type commit-msg
	@echo "Pre-commit hooks installed successfully. Hooks will run on every commit."
```

**Key design decisions:**
- `pipx` preferred over `pip` when available (isolates pre-commit in its own venv)
- `pip install --user` as fallback (avoids permission issues, does not require sudo)
- Explicit `--hook-type commit-msg` to register the conventional commits hook
- `@` prefix suppresses command echo for clean output

### Hook Registration Details

Pre-commit creates hook scripts in `.git/hooks/`:
- `.git/hooks/pre-commit` — triggers linting, formatting, gitleaks, terraform-docs hooks
- `.git/hooks/commit-msg` — triggers conventional commits hook

Both must be registered. The default `pre-commit install` only registers `pre-commit`. The `--hook-type commit-msg` call registers the commit-msg hook separately.

### Cross-Platform Considerations

**macOS:**
- Default shell is zsh (Makefile still runs with `make`'s default `/bin/sh`)
- Python may be installed via Homebrew (`/opt/homebrew/bin/python3`) or system (`/usr/bin/python3`)
- `pip` may require `--break-system-packages` on newer Python versions — `pipx` avoids this
- `command -v` works in both bash and zsh

**Linux:**
- Default shell is typically bash
- Python may be `python3` (Debian/Ubuntu) or `python` (Arch, Fedora)
- The target should check `python3` first, then `python`
- `pip install --user` places executables in `~/.local/bin` — may not be on PATH

**Both platforms:**
- `make` is available (GNU Make on Linux, Apple Make on macOS — both support the required features)
- `git` must be initialized (`git init`) before hooks can be installed
- The `.git/hooks/` directory must exist (created by `git init`)

### Makefile Target Placement

Per the Makefile structure convention, `install-hooks` is a public target:

```makefile
# Variables
DEVRAIL_IMAGE ?= ghcr.io/devrail-dev/dev-toolchain:v1

# .PHONY declarations
.PHONY: help lint format test security scan docs check install-hooks

# Public targets (alphabetical or logical order)
help: ## Show this help
	...

install-hooks: ## Install pre-commit hooks
	...

lint: ## Run all linters
	...

# Internal targets
_lint:
	...
```

Note: `install-hooks` does NOT have a corresponding `_install-hooks` internal target because it does not delegate to the container.

### Previous Story Intelligence

**Story 4.1 creates:** Verified conventional commits hook. This story's `install-hooks` target registers it via `pre-commit install --hook-type commit-msg`.

**Story 4.2 creates:** Linting and formatting hook entries in `.pre-commit-config.yaml`. These are registered via `pre-commit install`.

**Story 4.3 creates:** Gitleaks and terraform-docs hook entries. These are also registered via `pre-commit install`.

**Epic 3 Story 3.1 creates:** The reference Makefile with the two-layer delegation pattern. This story adds the `install-hooks` target to that Makefile. If Epic 3 is not yet complete, the `install-hooks` target can be documented independently and integrated when the reference Makefile is built.

**Epic 1 Story 1.5:** Documented `install-hooks` as one of the standard Makefile targets in the Makefile contract specification. This story implements what that spec describes.

### Project Structure Notes

This story modifies the reference Makefile (or template Makefile) and verifies end-to-end integration:

```
<template-repo>/
├── .pre-commit-config.yaml         ← Stories 4.1-4.3 (hooks configured)
├── Makefile                        ← THIS STORY (add install-hooks target)
└── .git/
    └── hooks/
        ├── pre-commit              ← Created by `pre-commit install`
        └── commit-msg              ← Created by `pre-commit install --hook-type commit-msg`
```

### Anti-Patterns to Avoid

1. **DO NOT** run `install-hooks` inside the Docker container — it must run on the host machine to modify `.git/hooks/`
2. **DO NOT** use `sudo` to install pre-commit — use `pipx` or `pip install --user`
3. **DO NOT** install Python as part of this target — only install the `pre-commit` package
4. **DO NOT** pin a specific pre-commit version at MVP — install latest stable
5. **DO NOT** create a separate shell script for installation — keep the logic in the Makefile target for simplicity
6. **DO NOT** skip the `--hook-type commit-msg` registration — without it, conventional commits enforcement will not trigger
7. **DO NOT** assume `pip` is the only installation method — check for `pipx` first for better isolation

### Conventional Commits

- Scope: `ci`
- Example: `feat(ci): create make install-hooks target for one-command pre-commit setup`

### References

- [architecture.md - Makefile Authoring Patterns]
- [architecture.md - Enforcement Guidelines - Pre-Commit]
- [prd.md - Functional Requirements FR29]
- [prd.md - Non-Functional Requirements NFR3, NFR11, NFR14, NFR15]
- [epics.md - Epic 4: Pre-Commit Enforcement - Story 4.4]
- [Story 4.1 - conventional commits hook (commit-msg registration)]
- [Story 4.2 - linting/formatting hooks (pre-commit registration)]
- [Story 4.3 - gitleaks and terraform-docs hooks (pre-commit registration)]
- [Epic 1 Story 1.5 - Makefile contract (install-hooks spec)]
- [Epic 3 Story 3.1 - reference Makefile (target placement)]

## Senior Developer Review (AI)

**Reviewer:** Claude Opus 4.6 (adversarial review)
**Date:** 2026-02-20
**Verdict:** PASS with fixes applied

### Acceptance Criteria Assessment

| AC | Status | Notes |
|----|--------|-------|
| #1 | IMPLEMENTED | Python check, pipx/pip fallback, pre-commit install, --hook-type commit-msg |
| #2 | IMPLEMENTED | Idempotent: re-running succeeds (pre-commit install and pipx/pip are naturally idempotent) |
| #3 | IMPLEMENTED | Uses command -v (works in both bash and zsh), git rev-parse for git check |
| #4 | IMPLEMENTED | Success message: "Pre-commit hooks installed successfully..." |
| #5 | IMPLEMENTED | Error messages for missing Python 3 and not-a-git-repo |
| #6 | IMPLEMENTED | Both pre-commit and commit-msg hooks registered |

### Findings (5 total)

1. **[HIGH] install-hooks only implemented in pre-commit-conventional-commits Makefile, not in template Makefiles** -- The story's file list says `pre-commit-conventional-commits/Makefile` was updated, but the github-repo-template and gitlab-repo-template Makefiles had a bare `pre-commit install` without any of the required checks (Python, git, pipx/pip). The dev-toolchain Makefile had no install-hooks at all. **FIXED in Story 3.1 review:** All three template Makefiles now have the full install-hooks implementation.

2. **[MEDIUM] The pre-commit-conventional-commits Makefile correctly implements install-hooks** -- The implementation at `pre-commit-conventional-commits/Makefile` lines 49-76 includes Python 3 check (exit 2), git repo check (exit 2), pipx/pip fallback for pre-commit installation, dual hook registration (pre-commit + commit-msg), and success message. This is the reference implementation.

3. **[LOW] pip install --user may not add to PATH** -- On some Linux systems, `pip install --user pre-commit` places the binary in `~/.local/bin` which may not be on PATH. The subsequent `pre-commit install` command would then fail. The pipx path is preferred and checked first, which handles this better. Acceptable for MVP.

4. **[LOW] No version pinning for pre-commit installation** -- `pipx install pre-commit` or `pip install --user pre-commit` installs latest. Per dev notes: "DO NOT pin a specific pre-commit version at MVP -- install latest stable." This is correct per spec.

5. **[LOW] install-hooks does not have a corresponding _install-hooks** -- Correctly documented and implemented. This is the ONE target that runs on the host, not inside the container. No _install-hooks internal target needed.

### Files Modified During Review

- github-repo-template/Makefile (full install-hooks implementation -- done in Story 3.1 review)
- gitlab-repo-template/Makefile (full install-hooks implementation -- done in Story 3.1 review)
- dev-toolchain/Makefile (install-hooks added -- done in Story 3.1 review)

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (claude-opus-4-6)

### Debug Log References

### Completion Notes List

- Implemented `install-hooks` as a public Makefile target with `## Install pre-commit hooks` description for `make help` auto-generation
- Added `install-hooks` to `.PHONY` declaration
- Python 3 availability check: exits with code 2 and clear message if `python3` not on PATH
- Git repository check: exits with code 2 and "Error: Not in a git repository. Run 'git init' first." if not in a git repo
- Pre-commit installation: checks if `pre-commit` is already on PATH; if not, prefers `pipx install pre-commit` (better isolation), falls back to `pip install --user pre-commit` (avoids sudo/permission issues)
- Registers both hook types: `pre-commit install` for pre-commit stage (lint, format, gitleaks, terraform-docs) and `pre-commit install --hook-type commit-msg` for conventional commits
- Idempotent: re-running succeeds without errors or duplicated hooks (both `pre-commit install` and pipx/pip are naturally idempotent)
- Success message: "Pre-commit hooks installed successfully. Hooks will run on every commit."
- Cross-platform compatible: uses `command -v` (works in both bash and zsh), `git rev-parse --git-dir` for git check
- Documented in Makefile with block comment explaining: host-only execution, hook registration details, exit codes
- `install-hooks` does NOT have a corresponding `_install-hooks` internal target (does not delegate to container)
- `@` prefix on all commands suppresses command echo for clean output

### File List

- `pre-commit-conventional-commits/Makefile` (updated with fully-specified install-hooks target)
