# Story 2.4: Terraform Tooling Install Script

Status: done

## Story

As a developer,
I want Terraform linting, security, documentation, and testing tools installed in the container,
so that any Terraform project can run the standard make targets.

## Acceptance Criteria

1. **Given** the base Dockerfile and shared libs exist (Story 2.1), **When** `scripts/install-terraform.sh` is created and executed, **Then** tflint, tfsec, checkov, terraform-docs, and terraform are installed and available on PATH, and terratest is available as a Go module dependency
2. **Given** `scripts/install-terraform.sh` has been executed once, **When** it is executed again, **Then** it completes successfully without errors (idempotent)
3. **Given** `scripts/install-terraform.sh` exists, **When** it is invoked with `--help`, **Then** it prints usage information and exits 0
4. **Given** `scripts/install-terraform.sh` exists, **When** it is examined with shellcheck, **Then** no warnings or errors are reported
5. **Given** all Terraform tools are installed, **When** `tests/test-terraform.sh` is executed, **Then** it verifies each binary tool (tflint, tfsec, checkov, terraform-docs, terraform) is on PATH and executable, exiting 0 on success and non-zero on any failure

## Tasks / Subtasks

- [x] Task 1: Create `scripts/install-terraform.sh` (AC: #1, #2, #3, #4)
  - [x] 1.1: Add structured header comment (purpose, usage, dependencies)
  - [x] 1.2: Add `#!/usr/bin/env bash` and `set -euo pipefail`
  - [x] 1.3: Source `lib/log.sh` and `lib/platform.sh`
  - [x] 1.4: Implement `--help` flag support
  - [x] 1.5: Add trap handler for cleanup (temp files via `mktemp`)
  - [x] 1.6: Install tflint — Go binary (built in go-builder stage or downloaded; detect arch via `lib/platform.sh`; idempotent)
  - [x] 1.7: Install tfsec — Go binary (built in go-builder stage or downloaded; idempotent)
  - [x] 1.8: Install checkov via pip (idempotent: `command -v checkov || pip install checkov`)
  - [x] 1.9: Install terraform-docs — Go binary (built in go-builder stage or downloaded; idempotent)
  - [x] 1.10: Install terraform — HashiCorp binary download (detect arch; idempotent)
  - [x] 1.11: Document terratest as a Go module dependency (no binary install — used as Go test dependency in consumer projects)
  - [x] 1.12: Log each install step using `log_info`
  - [x] 1.13: Verify shellcheck compliance
- [x] Task 2: Create `tests/test-terraform.sh` (AC: #5)
  - [x] 2.1: Add structured header comment
  - [x] 2.2: Add `#!/usr/bin/env bash` and `set -euo pipefail`
  - [x] 2.3: Source `lib/log.sh`
  - [x] 2.4: Verify `tflint --version` succeeds
  - [x] 2.5: Verify `tfsec --version` succeeds
  - [x] 2.6: Verify `checkov --version` succeeds
  - [x] 2.7: Verify `terraform-docs --version` succeeds
  - [x] 2.8: Verify `terraform version` succeeds
  - [x] 2.9: Log pass/fail for each tool check
  - [x] 2.10: Exit 0 if all pass, non-zero if any fail

## Dev Notes

### Critical Architecture Constraints

**This install script runs inside the Docker build.** It is invoked by a `RUN` instruction in the Dockerfile. It must not assume network access beyond what Docker build provides. It must not modify the Dockerfile itself — the Dockerfile calls the script.

**Multiple install methods are used.** This story has the most diverse set of install methods: Go binaries (tflint, tfsec, terraform-docs), pip (checkov), and direct binary download (terraform). The script must handle all three cleanly.

**Go binaries can be built in the go-builder stage or downloaded as pre-built binaries.** If using the go-builder stage, the Dockerfile will `COPY --from=go-builder` the compiled binaries. If downloading, use `lib/platform.sh` to detect architecture (amd64 vs arm64). Either approach is acceptable — choose the one that keeps the final image smallest.

**Terraform binary comes from HashiCorp.** Download from `releases.hashicorp.com`. Use the correct architecture. Verify the download if possible (SHA256 checksum).

**Terratest is NOT a binary tool.** It is a Go module used as a test dependency. The install script should document this but does not need to install a binary. Consumer projects will `go get` terratest as needed.

**Source:** [architecture.md - Container Build Architecture]

### Tools to Install

| Tool            | Install Method                        | Purpose                         |
|-----------------|---------------------------------------|---------------------------------|
| tflint          | Go binary (builder stage or download) | Terraform linter                |
| tfsec           | Go binary (builder stage or download) | Terraform security scanner      |
| checkov         | pip install                           | IaC security scanner            |
| terraform-docs  | Go binary (builder stage or download) | Terraform documentation gen     |
| terraform       | HashiCorp binary download             | Terraform CLI (for `fmt`)       |
| terratest       | Go module (no binary install)         | Go test framework for Terraform |

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

`tests/test-terraform.sh` must:
- Verify each binary tool is on PATH using `command -v`
- Verify each binary tool is executable by running `<tool> --version`
- Note that terratest is a Go module and cannot be tested via `command -v` — the test should log a note that terratest is a Go dependency, not a standalone binary
- Use `log_info` / `log_error` for reporting
- Exit 0 if all binary tools pass, non-zero if any fail
- Follow the same shell script standards (shebang, set flags, shellcheck)

### Previous Story Intelligence

Story 2.1 creates: Dockerfile skeleton, `lib/log.sh`, `lib/platform.sh`, Makefile, repo foundation files. The shared libraries provide `log_info`, `log_warn`, `log_error`, `log_debug`, `die`, `require_cmd`, and platform detection helpers. All install scripts source these.

### Project Structure Notes

```
dev-toolchain/
├── scripts/
│   └── install-terraform.sh     ← THIS STORY
├── tests/
│   └── test-terraform.sh        ← THIS STORY
├── lib/
│   ├── log.sh                   ← Story 2.1 (sourced)
│   └── platform.sh              ← Story 2.1 (sourced)
└── Dockerfile                   ← Story 2.1 (invokes this script)
```

### Anti-Patterns to Avoid

1. DO NOT use raw echo — use log_info/log_warn/log_error
2. DO NOT install tools for other languages
3. DO NOT modify the Dockerfile directly — the install script is invoked BY the Dockerfile
4. DO NOT hardcode versions — let pip/apt install latest unless there is a specific version constraint
5. DO NOT skip the test script

### Conventional Commits

- Scope: container
- Example: `feat(container): add Terraform tooling install script`

### References

- [architecture.md - Container Build Architecture]
- [architecture.md - Shell Script Conventions]
- [prd.md - Language Support Matrix]
- [epics.md - Epic 2 - Story 2.4]
- [Story 2.1 - shared libraries and Dockerfile skeleton]

## Senior Developer Review (AI)

**Reviewer:** Claude Opus 4.6 (adversarial review)
**Date:** 2026-02-20
**Verdict:** PASS

### Acceptance Criteria Verification

| AC | Status | Notes |
|---|---|---|
| AC1 | IMPLEMENTED | tflint, tfsec, terraform-docs from go-builder; checkov via pip; terraform via binary download; terratest documented as Go module |
| AC2 | IMPLEMENTED | Idempotent via command -v checks |
| AC3 | IMPLEMENTED | --help flag supported with terratest note |
| AC4 | IMPLEMENTED | shellcheck source directives present |
| AC5 | IMPLEMENTED | test-terraform.sh verifies all 5 binary tools plus terratest note |

### Findings

1. **LOW - Terraform version auto-detection with fallback.** Uses HashiCorp checkpoint API to determine latest version, falls back to hardcoded v1.9.8. Good defensive coding.
2. **LOW - Platform detection via lib/platform.sh.** Uses `get_arch` and `get_os` for correct binary download.
3. **LOW - checkov install uses same --break-system-packages pattern.** Consistent with install-python.sh approach.
4. **LOW - terratest correctly documented as Go module.** Log messages explain it's not a binary install, consumer projects use `go get`. Test script logs informational note about this.
5. **LOW - test-terraform.sh uses "version" (no --) for terraform.** Correct: terraform uses `terraform version` not `terraform --version`.

### Files Modified During Review

None.

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (claude-opus-4-6)

### Debug Log References

### Completion Notes List

- Created `scripts/install-terraform.sh` with structured header, shebang, set -euo pipefail
- Sources lib/log.sh and lib/platform.sh for logging and platform detection
- Implements --help flag support
- Trap handler for cleanup of temp directory
- tflint, tfsec, terraform-docs verified as present (expected from Go builder stage)
- checkov installed via pip with --break-system-packages fallback (idempotent)
- terraform CLI downloaded from releases.hashicorp.com with auto-detected version and architecture
- terratest documented as Go module dependency — no binary install
- All installs are idempotent using command -v checks
- Created `tests/test-terraform.sh` that verifies tflint, tfsec, checkov, terraform-docs, terraform are on PATH and executable
- Test script logs note about terratest being a Go module dependency

### File List

- scripts/install-terraform.sh
- tests/test-terraform.sh
