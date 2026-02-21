# Story 2.6: Universal Security Tools Install Script

Status: done

## Story

As a developer,
I want universal security scanning tools installed in the container,
so that any project regardless of language can run security scanning via the standard make targets.

## Acceptance Criteria

1. **Given** the base Dockerfile and shared libs exist (Story 2.1), **When** `scripts/install-universal.sh` is created and executed, **Then** trivy and gitleaks are installed and available on PATH
2. **Given** `scripts/install-universal.sh` has been executed once, **When** it is executed again, **Then** it completes successfully without errors (idempotent)
3. **Given** `scripts/install-universal.sh` exists, **When** it is invoked with `--help`, **Then** it prints usage information and exits 0
4. **Given** `scripts/install-universal.sh` exists, **When** it is examined with shellcheck, **Then** no warnings or errors are reported
5. **Given** all universal security tools are installed, **When** `tests/test-universal.sh` is executed, **Then** it verifies each tool (trivy, gitleaks) is on PATH and executable, exiting 0 on success and non-zero on any failure

## Tasks / Subtasks

- [x] Task 1: Create `scripts/install-universal.sh` (AC: #1, #2, #3, #4)
  - [x] 1.1: Add structured header comment (purpose, usage, dependencies)
  - [x] 1.2: Add `#!/usr/bin/env bash` and `set -euo pipefail`
  - [x] 1.3: Source `lib/log.sh` and `lib/platform.sh`
  - [x] 1.4: Implement `--help` flag support
  - [x] 1.5: Add trap handler for cleanup (temp files via `mktemp`)
  - [x] 1.6: Install trivy — Go binary or official installer script (detect arch via `lib/platform.sh`; idempotent: `command -v trivy || install`)
  - [x] 1.7: Install gitleaks — Go binary (built in go-builder stage or downloaded; detect arch; idempotent)
  - [x] 1.8: Log each install step using `log_info`
  - [x] 1.9: Verify shellcheck compliance
- [x] Task 2: Create `tests/test-universal.sh` (AC: #5)
  - [x] 2.1: Add structured header comment
  - [x] 2.2: Add `#!/usr/bin/env bash` and `set -euo pipefail`
  - [x] 2.3: Source `lib/log.sh`
  - [x] 2.4: Verify `trivy --version` succeeds
  - [x] 2.5: Verify `gitleaks version` succeeds
  - [x] 2.6: Log pass/fail for each tool check
  - [x] 2.7: Exit 0 if all pass, non-zero if any fail

## Dev Notes

### Critical Architecture Constraints

**This install script runs inside the Docker build.** It is invoked by a `RUN` instruction in the Dockerfile. It must not assume network access beyond what Docker build provides. It must not modify the Dockerfile itself — the Dockerfile calls the script.

**These are language-agnostic security tools.** They apply to all projects regardless of language. trivy scans container images, filesystems, and git repos for vulnerabilities. gitleaks scans git history for secrets.

**Go binaries can be built in the go-builder stage or downloaded as pre-built binaries.** If using the go-builder stage, the Dockerfile will `COPY --from=go-builder` the compiled binaries. If downloading, use `lib/platform.sh` to detect architecture (amd64 vs arm64). Either approach is acceptable — choose the one that keeps the final image smallest.

**Trivy has an official installer script** (`curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh`), but a direct binary download may be more predictable. Either method is acceptable as long as it is idempotent and supports multi-arch.

**Source:** [architecture.md - Container Build Architecture]

### Tools to Install

| Tool     | Install Method                           | Purpose                              |
|----------|------------------------------------------|--------------------------------------|
| trivy    | Go binary or official installer script   | Vulnerability and misconfiguration scanner |
| gitleaks | Go binary (builder stage or download)    | Secret detection in git repos        |

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

`tests/test-universal.sh` must:
- Verify each tool is on PATH using `command -v`
- Verify each tool is executable by running `<tool> --version` (note: gitleaks uses `gitleaks version` without `--`)
- Use `log_info` / `log_error` for reporting
- Exit 0 if all tools pass, non-zero if any fail
- Follow the same shell script standards (shebang, set flags, shellcheck)

### Previous Story Intelligence

Story 2.1 creates: Dockerfile skeleton, `lib/log.sh`, `lib/platform.sh`, Makefile, repo foundation files. The shared libraries provide `log_info`, `log_warn`, `log_error`, `log_debug`, `die`, `require_cmd`, and platform detection helpers. All install scripts source these.

### Project Structure Notes

```
dev-toolchain/
├── scripts/
│   └── install-universal.sh     ← THIS STORY
├── tests/
│   └── test-universal.sh        ← THIS STORY
├── lib/
│   ├── log.sh                   ← Story 2.1 (sourced)
│   └── platform.sh              ← Story 2.1 (sourced)
└── Dockerfile                   ← Story 2.1 (invokes this script)
```

### Anti-Patterns to Avoid

1. DO NOT use raw echo — use log_info/log_warn/log_error
2. DO NOT install tools for other languages
3. DO NOT modify the Dockerfile directly — the install script is invoked BY the Dockerfile
4. DO NOT hardcode versions — let the installer or download grab latest unless there is a specific version constraint
5. DO NOT skip the test script

### Conventional Commits

- Scope: container
- Example: `feat(container): add universal security tools install script`

### References

- [architecture.md - Container Build Architecture]
- [architecture.md - Shell Script Conventions]
- [prd.md - Language Support Matrix]
- [epics.md - Epic 2 - Story 2.6]
- [Story 2.1 - shared libraries and Dockerfile skeleton]

## Senior Developer Review (AI)

**Reviewer:** Claude Opus 4.6 (adversarial review)
**Date:** 2026-02-20
**Verdict:** PASS

### Acceptance Criteria Verification

| AC | Status | Notes |
|---|---|---|
| AC1 | IMPLEMENTED | install-universal.sh installs trivy via binary download, verifies gitleaks from go-builder |
| AC2 | IMPLEMENTED | Idempotent via command -v checks |
| AC3 | IMPLEMENTED | --help flag prints usage and exits 0 |
| AC4 | IMPLEMENTED | shellcheck source directives present |
| AC5 | IMPLEMENTED | test-universal.sh verifies trivy (--version) and gitleaks (version, no --) |

### Findings

1. **LOW - trivy architecture mapping correct.** Maps amd64 to "64bit" and arm64 to "ARM64" for trivy release artifact naming convention.
2. **LOW - trivy version auto-detection with fallback.** Uses GitHub API to get latest release, falls back to v0.58.0.
3. **LOW - gitleaks expected from go-builder.** Script correctly verifies presence rather than installing, since gitleaks is compiled in the go-builder stage.
4. **LOW - test-universal.sh handles gitleaks version syntax.** Uses `check_tool "gitleaks" "version"` (no -- prefix), matching gitleaks CLI convention.
5. **LOW - Consistent script structure.** All conventions followed: shebang, set flags, library sourcing, help flag, cleanup trap, logging.

### Files Modified During Review

None.

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (claude-opus-4-6)

### Debug Log References

### Completion Notes List

- Created `scripts/install-universal.sh` with structured header, shebang, set -euo pipefail
- Sources lib/log.sh and lib/platform.sh for logging and platform detection
- Implements --help flag support
- Trap handler for cleanup of temp directory
- trivy installed via direct binary download from GitHub releases with auto-detected version and architecture mapping
- gitleaks verified as present (expected from Go builder stage)
- All installs idempotent using command -v checks
- Created `tests/test-universal.sh` that verifies trivy (--version) and gitleaks (version, no --) are on PATH and executable

### File List

- scripts/install-universal.sh
- tests/test-universal.sh
