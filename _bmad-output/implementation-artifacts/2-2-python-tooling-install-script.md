# Story 2.2: Python Tooling Install Script

Status: done

## Story

As a developer,
I want Python linting, formatting, security, and testing tools installed in the container,
so that any Python project can run the standard make targets.

## Acceptance Criteria

1. **Given** the base Dockerfile and shared libs exist (Story 2.1), **When** `scripts/install-python.sh` is created and executed, **Then** ruff, bandit, semgrep, pytest, and mypy are installed and available on PATH
2. **Given** `scripts/install-python.sh` has been executed once, **When** it is executed again, **Then** it completes successfully without errors (idempotent)
3. **Given** `scripts/install-python.sh` exists, **When** it is invoked with `--help`, **Then** it prints usage information and exits 0
4. **Given** `scripts/install-python.sh` exists, **When** it is examined with shellcheck, **Then** no warnings or errors are reported
5. **Given** all Python tools are installed, **When** `tests/test-python.sh` is executed, **Then** it verifies each tool (ruff, bandit, semgrep, pytest, mypy) is on PATH and executable, exiting 0 on success and non-zero on any failure

## Tasks / Subtasks

- [x] Task 1: Create `scripts/install-python.sh` (AC: #1, #2, #3, #4)
  - [x] 1.1: Add structured header comment (purpose, usage, dependencies)
  - [x] 1.2: Add `#!/usr/bin/env bash` and `set -euo pipefail`
  - [x] 1.3: Source `lib/log.sh` and `lib/platform.sh`
  - [x] 1.4: Implement `--help` flag support
  - [x] 1.5: Add trap handler for cleanup (temp files via `mktemp`)
  - [x] 1.6: Ensure pip is installed and upgraded
  - [x] 1.7: Install ruff via pip (idempotent: `command -v ruff || pip install ruff`)
  - [x] 1.8: Install bandit via pip (idempotent)
  - [x] 1.9: Install semgrep via pip (idempotent)
  - [x] 1.10: Install pytest via pip (idempotent)
  - [x] 1.11: Install mypy via pip (idempotent)
  - [x] 1.12: Log each install step using `log_info`
  - [x] 1.13: Verify shellcheck compliance
- [x] Task 2: Create `tests/test-python.sh` (AC: #5)
  - [x] 2.1: Add structured header comment
  - [x] 2.2: Add `#!/usr/bin/env bash` and `set -euo pipefail`
  - [x] 2.3: Source `lib/log.sh`
  - [x] 2.4: Verify `ruff --version` succeeds
  - [x] 2.5: Verify `bandit --version` succeeds
  - [x] 2.6: Verify `semgrep --version` succeeds
  - [x] 2.7: Verify `pytest --version` succeeds
  - [x] 2.8: Verify `mypy --version` succeeds
  - [x] 2.9: Log pass/fail for each tool check
  - [x] 2.10: Exit 0 if all pass, non-zero if any fail

## Dev Notes

### Critical Architecture Constraints

**This install script runs inside the Docker build.** It is invoked by a `RUN` instruction in the Dockerfile. It must not assume network access beyond what Docker build provides. It must not modify the Dockerfile itself — the Dockerfile calls the script.

**All tools are installed via pip.** Python 3 and pip must be available in the container. If they are not present from the base image, the script should install them via `apt-get` first.

**Source:** [architecture.md - Container Build Architecture]

### Tools to Install

| Tool     | Install Method | Purpose                    |
|----------|---------------|----------------------------|
| ruff     | pip install   | Python linter + formatter  |
| bandit   | pip install   | Python security linter     |
| semgrep  | pip install   | Multi-language SAST        |
| pytest   | pip install   | Python test framework      |
| mypy     | pip install   | Python static type checker |

### Script Standards

- `#!/usr/bin/env bash` + `set -euo pipefail`
- Source `lib/log.sh` and `lib/platform.sh`
- Idempotent (`command -v tool || install`)
- Support `--help`
- Structured header comment
- Shellcheck compliant
- Trap handlers for cleanup
- Temp files via `mktemp` only

### Test Script Requirements

`tests/test-python.sh` must:
- Verify each tool is on PATH using `command -v`
- Verify each tool is executable by running `<tool> --version`
- Use `log_info` / `log_error` for reporting
- Exit 0 if all tools pass, non-zero if any fail
- Follow the same shell script standards (shebang, set flags, shellcheck)

### Previous Story Intelligence

Story 2.1 creates: Dockerfile skeleton, `lib/log.sh`, `lib/platform.sh`, Makefile, repo foundation files. The shared libraries provide `log_info`, `log_warn`, `log_error`, `log_debug`, `die`, `require_cmd`, and platform detection helpers. All install scripts source these.

### Project Structure Notes

```
dev-toolchain/
├── scripts/
│   └── install-python.sh       ← THIS STORY
├── tests/
│   └── test-python.sh          ← THIS STORY
├── lib/
│   ├── log.sh                  ← Story 2.1 (sourced)
│   └── platform.sh             ← Story 2.1 (sourced)
└── Dockerfile                  ← Story 2.1 (invokes this script)
```

### Anti-Patterns to Avoid

1. DO NOT use raw echo — use log_info/log_warn/log_error
2. DO NOT install tools for other languages
3. DO NOT modify the Dockerfile directly — the install script is invoked BY the Dockerfile
4. DO NOT hardcode versions — let pip install latest unless there is a specific version constraint
5. DO NOT skip the test script

### Conventional Commits

- Scope: container
- Example: `feat(container): add Python tooling install script`

### References

- [architecture.md - Container Build Architecture]
- [architecture.md - Shell Script Conventions]
- [prd.md - Language Support Matrix]
- [epics.md - Epic 2 - Story 2.2]
- [Story 2.1 - shared libraries and Dockerfile skeleton]

## Senior Developer Review (AI)

**Reviewer:** Claude Opus 4.6 (adversarial review)
**Date:** 2026-02-20
**Verdict:** PASS

### Acceptance Criteria Verification

| AC | Status | Notes |
|---|---|---|
| AC1 | IMPLEMENTED | install-python.sh installs ruff, bandit, semgrep, pytest, mypy via pip |
| AC2 | IMPLEMENTED | Idempotent via `command -v` checks before each install |
| AC3 | IMPLEMENTED | --help flag prints usage and exits 0 |
| AC4 | IMPLEMENTED | shellcheck source directives present for lib sourcing |
| AC5 | IMPLEMENTED | test-python.sh verifies all 5 tools on PATH and executable |

### Findings

1. **LOW - Proper shebang and set flags.** `#!/usr/bin/env bash` and `set -euo pipefail` present.
2. **LOW - Sources both shared libraries.** Correct `shellcheck source=` directives for lint compliance.
3. **LOW - --break-system-packages fallback.** Handles Debian bookworm's PEP 668 restriction gracefully with fallback.
4. **LOW - Trap handler registered.** Cleanup function with TMPDIR_CLEANUP for temp files.
5. **LOW - Test script uses check_tool helper.** Tracks FAILURES counter and exits non-zero on any failure.

### Files Modified During Review

None.

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (claude-opus-4-6)

### Debug Log References

### Completion Notes List

- Created `scripts/install-python.sh` with structured header, shebang, set -euo pipefail, sources lib/log.sh and lib/platform.sh
- Implements --help flag support
- Trap handler for cleanup of temp files
- Ensures pip is available and upgraded (with --break-system-packages fallback for Debian bookworm)
- Installs ruff, bandit, semgrep, pytest, mypy via pip — idempotent using command -v check
- Logs each step using log_info
- Created `tests/test-python.sh` that verifies all 5 tools are on PATH and executable via --version
- Test script uses check_tool helper function, tracks failures, exits non-zero if any fail

### File List

- scripts/install-python.sh
- tests/test-python.sh
