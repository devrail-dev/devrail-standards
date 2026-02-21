# Story 2.1: Initialize Repository with Multi-Stage Dockerfile and Shared Libraries

Status: done

## Story

As a developer,
I want a dev-toolchain repo with a multi-stage Dockerfile skeleton and shared bash libraries,
so that per-language install scripts have a consistent foundation to build on.

## Acceptance Criteria

1. **Given** a new dev-toolchain repository, **When** the repo is initialized, **Then** it contains a multi-stage Dockerfile with a Debian-based builder stage and a clean final stage
2. **Given** the repo is initialized, **When** the shared library is examined, **Then** `lib/log.sh` provides `log_info`, `log_warn`, `log_error`, `log_debug`, `die` functions with JSON default output
3. **Given** the repo is initialized, **When** the platform library is examined, **Then** `lib/platform.sh` provides `on_mac`, `on_linux`, `on_arm64` detection helpers
4. **Given** `lib/log.sh` exists, **Then** it supports `DEVRAIL_LOG_FORMAT=human`, `DEVRAIL_QUIET=1`, `DEVRAIL_DEBUG=1`
5. **Given** the repo is initialized, **Then** validation helpers (`is_empty`, `is_not_empty`, `is_set`, `require_cmd`) are available
6. **Given** all shared libraries exist, **Then** the repo includes `.devrail.yml`, `.editorconfig`, `.gitignore`, `Makefile`, `README.md`, `LICENSE`, and agent instruction files

## Tasks / Subtasks

- [x] Task 1: Initialize the dev-toolchain repository (AC: #6)
  - [x] 1.1: Create `.devrail.yml` declaring `languages: [bash]`
  - [x] 1.2: Create `.editorconfig` (same spec as devrail-standards)
  - [x] 1.3: Create `.gitignore` covering OS files, editor files, Docker build artifacts
  - [x] 1.4: Create `LICENSE` (MIT)
  - [x] 1.5: Create `Makefile` with two-layer delegation pattern, build targets for Docker
  - [x] 1.6: Create `README.md` stub with standard structure
  - [x] 1.7: Create agent instruction files (CLAUDE.md, AGENTS.md, .cursorrules, .opencode/agents.yaml) — copy from devrail-standards templates
- [x] Task 2: Create multi-stage Dockerfile skeleton (AC: #1)
  - [x] 2.1: Create Dockerfile with Debian-based builder stage(s) for Go-based tools
  - [x] 2.2: Create final stage that copies runtime artifacts
  - [x] 2.3: Add placeholder comments for per-language install script invocations
  - [x] 2.4: Set up WORKDIR, PATH, and base system dependencies
- [x] Task 3: Create lib/log.sh (AC: #2, #4)
  - [x] 3.1: Implement `log_info`, `log_warn`, `log_error`, `log_debug` functions
  - [x] 3.2: Implement `die` function (log_error + exit 1)
  - [x] 3.3: Implement JSON output format as default: `{"level":"info","msg":"...","script":"...","ts":"..."}`
  - [x] 3.4: Implement human-readable mode via `DEVRAIL_LOG_FORMAT=human`: `[INFO]  message`
  - [x] 3.5: Implement `DEVRAIL_QUIET=1` (suppress info, show warn/error only)
  - [x] 3.6: Implement `DEVRAIL_DEBUG=1` (enable debug messages)
  - [x] 3.7: All output to stderr — stdout reserved for tool output
  - [x] 3.8: Include error entries with `exit_code` when applicable
- [x] Task 4: Create lib/platform.sh (AC: #3)
  - [x] 4.1: Implement `on_mac` (returns 0 on macOS, 1 otherwise)
  - [x] 4.2: Implement `on_linux` (returns 0 on Linux, 1 otherwise)
  - [x] 4.3: Implement `on_arm64` (returns 0 on ARM64/aarch64, 1 otherwise)
- [x] Task 5: Create validation helpers (AC: #5)
  - [x] 5.1: Implement `is_empty "$var"` — returns 0 if variable is empty/unset
  - [x] 5.2: Implement `is_not_empty "$var"` — returns 0 if variable has value
  - [x] 5.3: Implement `is_set "$var_name"` — returns 0 if variable is declared
  - [x] 5.4: Implement `require_cmd "docker" "Install Docker to continue"` — exit 2 if command not found

## Dev Notes

### Critical Architecture Constraints

**This is the foundation for the entire dev-toolchain container.** Every install script (Stories 2.2-2.6) will source these shared libraries. The log.sh and platform.sh APIs become the internal contract — don't change function signatures after this story.

**The Dockerfile defined here must support multi-arch builds** (linux/amd64 + linux/arm64). The build workflow (Story 2.7) will use `docker buildx` for multi-arch. Design the Dockerfile accordingly — avoid arch-specific assumptions.

**Source:** [architecture.md - Container Build Architecture]

### Dockerfile Structure

```dockerfile
# === Builder stage: Go-based tools ===
FROM golang:1.22-bookworm AS go-builder
# tflint, terraform-docs, trivy, gitleaks compiled here
# Will be added by install scripts in Stories 2.2-2.6

# === Final stage ===
FROM debian:bookworm-slim AS runtime

# Base system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    make \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Copy shared libraries
COPY lib/ /opt/devrail/lib/
ENV PATH="/opt/devrail/bin:${PATH}"
ENV DEVRAIL_LIB="/opt/devrail/lib"

# Copy Go-built binaries from builder
# COPY --from=go-builder /go/bin/* /usr/local/bin/
# (Added by per-language install scripts)

# Per-language install scripts will be added here
# COPY scripts/ /opt/devrail/scripts/
# RUN /opt/devrail/scripts/install-python.sh
# (Added by Stories 2.2-2.6)

WORKDIR /workspace
```

**Key points:**
- Debian bookworm-slim as final base (not Alpine — broader compatibility)
- Go builder stage for compiling Go-based tools
- Shared libs at `/opt/devrail/lib/`
- Scripts at `/opt/devrail/scripts/`
- Binaries on PATH at `/opt/devrail/bin/`
- `/workspace` as WORKDIR (where repos get mounted)

**Source:** [architecture.md - Container Build Architecture, Foundation Decisions]

### lib/log.sh API

```bash
#!/usr/bin/env bash
# lib/log.sh — DevRail shared logging library
# Source this file: source "${DEVRAIL_LIB}/log.sh"

# JSON output (default):
# {"level":"info","msg":"Installing Python tools","script":"install-python.sh","ts":"2026-02-19T10:30:00Z"}

# Human output (DEVRAIL_LOG_FORMAT=human):
# [INFO]  Installing Python tools

log_info "message"    # Info-level message (suppressed by DEVRAIL_QUIET=1)
log_warn "message"    # Warning-level message (always shown)
log_error "message"   # Error-level message (always shown)
log_debug "message"   # Debug-level message (only when DEVRAIL_DEBUG=1)
die "message"         # log_error + exit 1
```

**Implementation requirements:**
- Detect `DEVRAIL_LOG_FORMAT` — default `json`, option `human`
- Detect `DEVRAIL_QUIET` — suppress info messages
- Detect `DEVRAIL_DEBUG` — enable debug messages
- All output to stderr (`>&2`)
- JSON includes: `level`, `msg`, `script` (from `$0`), `ts` (ISO 8601)
- Error entries include `exit_code` field when applicable
- No ANSI colors in JSON mode; optional in human mode
- Script MUST follow: `#!/usr/bin/env bash`, `set -euo pipefail`, idempotent

**Source:** [architecture.md - Shell Script Conventions - Logging Standard]

### Validation Helpers Location

The validation helpers (`is_empty`, `is_not_empty`, `is_set`, `require_cmd`) can live in `lib/log.sh` or a separate `lib/helpers.sh`. Either approach is acceptable. If separate, the install scripts should source both.

### Makefile for This Repo

The dev-toolchain Makefile needs additional targets beyond the standard contract:

```makefile
DEVRAIL_IMAGE ?= ghcr.io/devrail-dev/dev-toolchain
DEVRAIL_TAG ?= local

.PHONY: help build lint format check

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Build the container image locally
	docker build -t $(DEVRAIL_IMAGE):$(DEVRAIL_TAG) .

lint: ## Run linters (shellcheck on scripts)
	docker run --rm -v "$$(pwd):/workspace" -w /workspace $(DEVRAIL_IMAGE):$(DEVRAIL_TAG) make _lint

check: ## Run all checks
	docker run --rm -v "$$(pwd):/workspace" -w /workspace $(DEVRAIL_IMAGE):$(DEVRAIL_TAG) make _check
```

**Note:** This repo has a chicken-and-egg problem — the Makefile delegates to the container, but the container is what we're building. The `build` target builds locally first. Lint/check can run against a previously built local image or the published one.

### Shell Script Standards Reminder

ALL scripts in this repo MUST follow:
- `#!/usr/bin/env bash` + `set -euo pipefail`
- Idempotent — safe to re-run
- Structured header comment (purpose, usage, dependencies)
- `--help` flag support
- Use shared logging library (no raw echo)
- Shellcheck compliant
- Trap handlers for cleanup
- Temp files via `mktemp` only

**Source:** [architecture.md - Shell Script Conventions]

### Project Structure Notes

```
dev-toolchain/
├── .devrail.yml               ← THIS STORY
├── .editorconfig              ← THIS STORY
├── .gitignore                 ← THIS STORY
├── CLAUDE.md                  ← THIS STORY
├── AGENTS.md                  ← THIS STORY
├── .cursorrules               ← THIS STORY
├── .opencode/
│   └── agents.yaml            ← THIS STORY
├── Dockerfile                 ← THIS STORY (skeleton)
├── LICENSE                    ← THIS STORY
├── Makefile                   ← THIS STORY
├── README.md                  ← THIS STORY
├── lib/
│   ├── log.sh                 ← THIS STORY
│   └── platform.sh            ← THIS STORY
├── scripts/                   ← THIS STORY (empty dir or placeholder)
└── tests/                     ← THIS STORY (empty dir or placeholder)
```

### Anti-Patterns to Avoid

1. **DO NOT** install any language tools in this story — that's Stories 2.2-2.6. The Dockerfile should have placeholder comments.
2. **DO NOT** use Alpine as base image — use Debian bookworm-slim for broader compatibility
3. **DO NOT** use raw `echo` in lib/log.sh — it IS the logging library, but test output should still use the JSON/human format
4. **DO NOT** hardcode architecture assumptions — the image must work on both amd64 and arm64
5. **DO NOT** create GitHub Actions workflows — those are Stories 2.7-2.9
6. **DO NOT** add DEVELOPMENT.md — that will be copied/adapted from devrail-standards in a later story or as part of dogfooding

### Conventional Commits for This Story

- Scope: `container`
- Example: `feat(container): initialize dev-toolchain repo with Dockerfile skeleton and shared libraries`

### References

- [architecture.md - Container Build Architecture]
- [architecture.md - Foundation Decisions - Container Base Image]
- [architecture.md - Shell Script Conventions]
- [architecture.md - Shell Script Conventions - Logging Standard]
- [architecture.md - Complete Per-Repo Directory Structures - dev-toolchain]
- [prd.md - Functional Requirements FR5, FR7, FR9]
- [prd.md - Non-Functional Requirements NFR5, NFR13]
- [epics.md - Epic 2: Dev-Toolchain Container - Story 2.1]

## Senior Developer Review (AI)

**Reviewer:** Claude Opus 4.6 (adversarial review)
**Date:** 2026-02-20
**Verdict:** PASS with fixes applied

### Acceptance Criteria Verification

| AC | Status | Notes |
|---|---|---|
| AC1 | IMPLEMENTED | Multi-stage Dockerfile with go-builder (golang:1.22-bookworm) and runtime (debian:bookworm-slim) |
| AC2 | IMPLEMENTED | lib/log.sh provides log_info, log_warn, log_error, log_debug, die with JSON default |
| AC3 | IMPLEMENTED | lib/platform.sh provides on_mac, on_linux, on_arm64 plus on_amd64, get_arch, get_os |
| AC4 | IMPLEMENTED | log.sh supports DEVRAIL_LOG_FORMAT=human, DEVRAIL_QUIET=1, DEVRAIL_DEBUG=1 |
| AC5 | IMPLEMENTED | Validation helpers is_empty, is_not_empty, is_set, require_cmd in lib/log.sh |
| AC6 | IMPLEMENTED | .devrail.yml, .editorconfig, .gitignore, Makefile, README.md, LICENSE, agent files all present |

### Findings

1. **HIGH - JSON escaping bug in lib/log.sh (FIXED).** The `_log_json` function's sed command escaped quotes before backslashes (`s/"/\\"/g; s/\\/\\\\/g`), which would double-escape already-escaped quotes. Fixed to escape backslashes first: `s/\\/\\\\/g; s/"/\\"/g`.
2. **HIGH - Missing yq dependency in Dockerfile (FIXED).** The Makefile uses `yq` for `.devrail.yml` language detection (`LANGUAGES := $(shell yq '.languages[]' ...)`), but yq was not installed in the Dockerfile. Added yq installation step via binary download from mikefarah/yq GitHub releases.
3. **LOW - lib/log.sh double-source guard is well-implemented.** Uses `_DEVRAIL_LOG_LOADED` readonly variable with `return 0 2>/dev/null || true` for both source and direct execution contexts.
4. **LOW - lib/platform.sh handles both arch naming conventions.** `on_arm64` checks both "aarch64" and "arm64", `on_amd64` checks both "x86_64" and "amd64". `get_arch` normalizes to "amd64"/"arm64".
5. **LOW - Makefile is thorough.** 498 lines with full language-conditional execution, JSON output, fail-fast support, duration tracking. Well beyond the "placeholder" originally specified.
6. **LOW - Dockerfile uses TARGETARCH ARG.** Properly declared for multi-arch builds in both builder and runtime stages.

### Files Modified During Review

- `dev-toolchain/lib/log.sh` -- fixed JSON escaping order in _log_json
- `dev-toolchain/Dockerfile` -- added yq installation for YAML parsing

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (claude-opus-4-6)

### Debug Log References

### Completion Notes List

- Created `.devrail.yml` with `languages: [bash]`
- Created `.editorconfig` matching devrail-standards spec
- Created `.gitignore` covering OS, editor, Docker, temp, and env files
- Created `LICENSE` (MIT, 2026 DevRail)
- Created `Makefile` with two-layer delegation pattern (public targets delegate to Docker, internal `_` prefixed targets run inside container)
- Created `README.md` with standard structure (title, badges, quick start, usage, tools table, configuration, architecture, contributing, license)
- Created agent instruction files: `CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `.opencode/agents.yaml`
- Created multi-stage `Dockerfile` with Go builder stage (golang:1.22-bookworm) and Debian bookworm-slim runtime stage
- Created `lib/log.sh` with full logging API: log_info, log_warn, log_error, log_debug, die; JSON default format with human mode; DEVRAIL_QUIET and DEVRAIL_DEBUG support; all output to stderr; exit_code in error entries
- Created `lib/platform.sh` with on_mac, on_linux, on_arm64, on_amd64, get_arch, get_os helpers
- Validation helpers (is_empty, is_not_empty, is_set, require_cmd) included in lib/log.sh
- Created `.pre-commit-config.yaml` for repo-level pre-commit hooks
- Created `CHANGELOG.md` in Keep a Changelog format

### File List

- .devrail.yml
- .editorconfig
- .gitignore
- .pre-commit-config.yaml
- .cursorrules
- .opencode/agents.yaml
- AGENTS.md
- CHANGELOG.md
- CLAUDE.md
- Dockerfile
- LICENSE
- Makefile
- README.md
- lib/log.sh
- lib/platform.sh
