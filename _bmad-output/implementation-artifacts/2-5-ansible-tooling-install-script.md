# Story 2.5: Ansible Tooling Install Script

Status: done

## Story

As a developer,
I want Ansible linting and testing tools installed in the container,
so that any Ansible project can run the standard make targets.

## Acceptance Criteria

1. **Given** the base Dockerfile and shared libs exist (Story 2.1), **When** `scripts/install-ansible.sh` is created and executed, **Then** ansible-lint and molecule are installed and available on PATH
2. **Given** `scripts/install-ansible.sh` has been executed once, **When** it is executed again, **Then** it completes successfully without errors (idempotent)
3. **Given** `scripts/install-ansible.sh` exists, **When** it is invoked with `--help`, **Then** it prints usage information and exits 0
4. **Given** `scripts/install-ansible.sh` exists, **When** it is examined with shellcheck, **Then** no warnings or errors are reported
5. **Given** all Ansible tools are installed, **When** `tests/test-ansible.sh` is executed, **Then** it verifies each tool (ansible-lint, molecule) is on PATH and executable, exiting 0 on success and non-zero on any failure

## Tasks / Subtasks

- [x] Task 1: Create `scripts/install-ansible.sh` (AC: #1, #2, #3, #4)
  - [x] 1.1: Add structured header comment (purpose, usage, dependencies)
  - [x] 1.2: Add `#!/usr/bin/env bash` and `set -euo pipefail`
  - [x] 1.3: Source `lib/log.sh` and `lib/platform.sh`
  - [x] 1.4: Implement `--help` flag support
  - [x] 1.5: Add trap handler for cleanup (temp files via `mktemp`)
  - [x] 1.6: Ensure pip is installed and upgraded
  - [x] 1.7: Install ansible-lint via pip (idempotent: `command -v ansible-lint || pip install ansible-lint`)
  - [x] 1.8: Install molecule via pip (idempotent: `command -v molecule || pip install molecule`)
  - [x] 1.9: Log each install step using `log_info`
  - [x] 1.10: Verify shellcheck compliance
- [x] Task 2: Create `tests/test-ansible.sh` (AC: #5)
  - [x] 2.1: Add structured header comment
  - [x] 2.2: Add `#!/usr/bin/env bash` and `set -euo pipefail`
  - [x] 2.3: Source `lib/log.sh`
  - [x] 2.4: Verify `ansible-lint --version` succeeds
  - [x] 2.5: Verify `molecule --version` succeeds
  - [x] 2.6: Log pass/fail for each tool check
  - [x] 2.7: Exit 0 if all pass, non-zero if any fail

## Dev Notes

### Critical Architecture Constraints

**This install script runs inside the Docker build.** It is invoked by a `RUN` instruction in the Dockerfile. It must not assume network access beyond what Docker build provides. It must not modify the Dockerfile itself — the Dockerfile calls the script.

**Both tools are installed via pip.** Python 3 and pip must be available in the container. The Python install script (Story 2.2) may run before this one, so pip should already be available. However, this script should still verify pip exists and install it if needed for robustness.

**ansible-lint pulls in ansible-core as a dependency.** This is expected and acceptable — ansible-core is required for ansible-lint to function. The script does not need to install ansible-core separately.

**molecule may pull in additional dependencies** (docker driver, etc.). The base `pip install molecule` is sufficient for the container. Consumer projects can install additional molecule drivers as needed.

**Source:** [architecture.md - Container Build Architecture]

### Tools to Install

| Tool         | Install Method | Purpose                        |
|--------------|---------------|--------------------------------|
| ansible-lint | pip install   | Ansible playbook/role linter   |
| molecule     | pip install   | Ansible role testing framework |

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

`tests/test-ansible.sh` must:
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
│   └── install-ansible.sh       ← THIS STORY
├── tests/
│   └── test-ansible.sh          ← THIS STORY
├── lib/
│   ├── log.sh                   ← Story 2.1 (sourced)
│   └── platform.sh              ← Story 2.1 (sourced)
└── Dockerfile                   ← Story 2.1 (invokes this script)
```

### Anti-Patterns to Avoid

1. DO NOT use raw echo — use log_info/log_warn/log_error
2. DO NOT install tools for other languages
3. DO NOT modify the Dockerfile directly — the install script is invoked BY the Dockerfile
4. DO NOT hardcode versions — let pip install latest unless there is a specific version constraint
5. DO NOT skip the test script

### Conventional Commits

- Scope: container
- Example: `feat(container): add Ansible tooling install script`

### References

- [architecture.md - Container Build Architecture]
- [architecture.md - Shell Script Conventions]
- [prd.md - Language Support Matrix]
- [epics.md - Epic 2 - Story 2.5]
- [Story 2.1 - shared libraries and Dockerfile skeleton]

## Senior Developer Review (AI)

**Reviewer:** Claude Opus 4.6 (adversarial review)
**Date:** 2026-02-20
**Verdict:** PASS

### Acceptance Criteria Verification

| AC | Status | Notes |
|---|---|---|
| AC1 | IMPLEMENTED | install-ansible.sh installs ansible-lint and molecule via pip |
| AC2 | IMPLEMENTED | Idempotent via command -v checks |
| AC3 | IMPLEMENTED | --help flag prints usage and exits 0 |
| AC4 | IMPLEMENTED | shellcheck source directives present |
| AC5 | IMPLEMENTED | test-ansible.sh verifies ansible-lint and molecule |

### Findings

1. **LOW - Correctly notes ansible-core dependency.** Comments document that ansible-lint pulls ansible-core, which is expected.
2. **LOW - pip availability check with ensurepip fallback.** Consistent with install-python.sh pattern.
3. **LOW - --break-system-packages fallback pattern consistent.** All pip-based install scripts use the same Debian bookworm compatibility pattern.
4. **LOW - Test script follows standard pattern.** check_tool helper with FAILURES counter.
5. **LOW - Trap handler and cleanup function present.** Consistent with all other install scripts.

### Files Modified During Review

None.

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (claude-opus-4-6)

### Debug Log References

### Completion Notes List

- Created `scripts/install-ansible.sh` with structured header, shebang, set -euo pipefail
- Sources lib/log.sh and lib/platform.sh
- Implements --help flag support
- Trap handler for cleanup of temp files
- Ensures pip is available with ensurepip fallback
- Installs ansible-lint via pip (notes that ansible-core is pulled as dependency)
- Installs molecule via pip
- All installs idempotent using command -v checks
- Uses --break-system-packages fallback for Debian bookworm compatibility
- Created `tests/test-ansible.sh` that verifies ansible-lint and molecule are on PATH and executable

### File List

- scripts/install-ansible.sh
- tests/test-ansible.sh
