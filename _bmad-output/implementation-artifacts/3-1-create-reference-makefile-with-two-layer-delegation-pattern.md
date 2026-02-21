# Story 3.1: Create Reference Makefile with Two-Layer Delegation Pattern

Status: done

## Story

As a developer,
I want a reference Makefile that implements the two-layer delegation pattern with Docker container integration,
so that all DevRail-enabled projects have a consistent, copy-paste-ready interface for running checks locally and in CI.

## Acceptance Criteria

1. **Given** the reference Makefile is created, **When** a developer examines the top of the file, **Then** `DEVRAIL_IMAGE ?= ghcr.io/devrail-dev/dev-toolchain:v1` is configurable via environment variable override
2. **Given** the reference Makefile exists, **When** a developer runs a public target (e.g., `make lint`), **Then** the target delegates execution to a Docker container using the `DEVRAIL_IMAGE`
3. **Given** the reference Makefile exists, **When** a developer examines internal targets, **Then** all internal targets use the `_`-prefix naming convention and are designed to run inside the container
4. **Given** the reference Makefile exists, **When** a developer runs `make` with no arguments, **Then** `make help` executes as the default target, displaying all public targets with their `## comment` descriptions
5. **Given** the reference Makefile exists, **When** the Makefile starts, **Then** it reads `.devrail.yml` to determine which languages are active and conditionally includes language-specific targets
6. **Given** the reference Makefile exists, **When** a developer examines the file structure, **Then** it follows the canonical order: variables, `.PHONY` declarations, public targets (with `## description`), internal `_`-prefixed targets

## Tasks / Subtasks

- [x] Task 1: Create the reference Makefile skeleton with variables and help target (AC: #1, #4, #6)
  - [x] 1.1: Define all `?=` overridable variables at the top: `DEVRAIL_IMAGE`, `DEVRAIL_TAG`, `DEVRAIL_FAIL_FAST`, `DEVRAIL_LOG_FORMAT`
  - [x] 1.2: Set `.DEFAULT_GOAL := help`
  - [x] 1.3: Implement `help` target using `grep -E` pattern to auto-generate help from `## comment` annotations
  - [x] 1.4: Add `.PHONY` declarations for all public targets
- [x] Task 2: Implement Docker delegation layer for public targets (AC: #2)
  - [x] 2.1: Create `DOCKER_RUN` variable encapsulating the `docker run --rm -v` invocation pattern
  - [x] 2.2: Implement public target stubs (`lint`, `format`, `test`, `security`, `scan`, `docs`, `check`) that delegate to `_`-prefixed internal targets via `$(DOCKER_RUN) make _<target>`
  - [x] 2.3: Pass through environment variables (`DEVRAIL_FAIL_FAST`, `DEVRAIL_LOG_FORMAT`) to the container via `-e` flags
- [x] Task 3: Implement .devrail.yml parsing (AC: #5)
  - [x] 3.1: Use `yq` or shell-based YAML parsing inside the container to read `.devrail.yml` and extract the `languages` list
  - [x] 3.2: Store active languages in a Make variable for conditional target execution
  - [x] 3.3: Exit with code 2 (misconfiguration) if `.devrail.yml` is missing or malformed
- [x] Task 4: Create internal target structure (AC: #3)
  - [x] 4.1: Create `_lint`, `_format`, `_test`, `_security`, `_scan`, `_docs`, `_check` internal targets as placeholders
  - [x] 4.2: Document the delegation contract: public targets run on host, internal targets run in container
  - [x] 4.3: Add inline comments explaining the pattern for downstream story authors (Stories 3.2-3.5)
- [x] Task 5: Implement make help auto-generation (AC: #4)
  - [x] 5.1: Ensure every public target has a `## description` comment on the target line
  - [x] 5.2: Verify `help` target output is clean, sorted, and colored for terminal readability
  - [x] 5.3: Include a header line showing the project name and DevRail version

## Dev Notes

### Critical Architecture Constraints

**This Makefile becomes the contract that developers, agents, and CI all use.** Every template repo (GitLab, GitHub) will copy or include this Makefile. The structure, variable names, and target names defined here are the public API of DevRail.

**The two-layer pattern is non-negotiable.** Public targets run on the host and delegate to Docker. Internal `_`-prefixed targets run inside the container where all tools are installed. This separation ensures the developer machine only needs Docker and Make.

**Source:** [architecture.md - Core Architectural Decisions - Makefile Contract Specification]

### Technical Details

#### Two-Layer Delegation Pattern

```makefile
DEVRAIL_IMAGE ?= ghcr.io/devrail-dev/dev-toolchain:v1
DEVRAIL_FAIL_FAST ?= 0
DEVRAIL_LOG_FORMAT ?= json

DOCKER_RUN := docker run --rm \
    -v "$$(pwd):/workspace" \
    -w /workspace \
    -e DEVRAIL_FAIL_FAST=$(DEVRAIL_FAIL_FAST) \
    -e DEVRAIL_LOG_FORMAT=$(DEVRAIL_LOG_FORMAT) \
    $(DEVRAIL_IMAGE)

.DEFAULT_GOAL := help

.PHONY: help lint format test security scan docs check

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

lint: ## Run all linters
	$(DOCKER_RUN) make _lint

_lint:
	# Internal: runs inside container
	# Reads .devrail.yml, dispatches to language-specific linters
```

**Key conventions:**
- Variables use `UPPER_SNAKE_CASE` with `?=` for overridability
- Public targets use `lower-kebab-case`
- Internal targets use `_`-prefix
- Every public target has a `## description` for help auto-generation

**Source:** [architecture.md - Makefile Authoring Patterns]

#### .devrail.yml Parsing Inside Container

The container has `yq` available. Language detection pattern:

```bash
LANGUAGES := $(shell yq '.languages[]' .devrail.yml 2>/dev/null)
HAS_PYTHON := $(filter python,$(LANGUAGES))
HAS_BASH := $(filter bash,$(LANGUAGES))
HAS_TERRAFORM := $(filter terraform,$(LANGUAGES))
HAS_ANSIBLE := $(filter ansible,$(LANGUAGES))
```

If `.devrail.yml` is missing, internal targets should exit with code 2:

```bash
@if [ ! -f .devrail.yml ]; then \
    echo '{"target":"lint","status":"error","error":"missing .devrail.yml","exit_code":2}'; \
    exit 2; \
fi
```

#### JSON Output Contract

Every target must produce a JSON summary line on stdout:

```json
{"target":"lint","status":"pass","duration_ms":1234}
```

On failure:

```json
{"target":"lint","status":"fail","duration_ms":1234,"exit_code":1}
```

On misconfiguration:

```json
{"target":"lint","status":"error","error":"missing .devrail.yml","exit_code":2}
```

**Source:** [architecture.md - Output & Logging Conventions]

#### Exit Codes

- `0` -- pass
- `1` -- failure (linter found issues, tests failed, etc.)
- `2` -- misconfiguration (missing .devrail.yml, missing tools, etc.)

#### File Structure Order

The Makefile MUST follow this canonical order:
1. Header comment with description and usage
2. Variables (`?=` overridable)
3. `DOCKER_RUN` composite variable
4. `.DEFAULT_GOAL`
5. `.PHONY` declarations
6. Public targets (alphabetical, each with `## description`)
7. Internal `_`-prefixed targets (matching order of public targets)

### Previous Story Intelligence

- Epic 1 defines the `.devrail.yml` schema, `.editorconfig`, and Makefile contract specification in standards docs
- Epic 2 builds the dev-toolchain container with all tools installed -- this Makefile delegates to that container
- Story 1.1 created a basic Makefile skeleton in the devrail-standards repo; this story creates the full reference implementation
- Story 1.5 documented the Makefile contract in `standards/makefile-contract.md`

### Project Structure Notes

This reference Makefile primarily lives in the template repos and the dev-toolchain reference implementation. The file created here serves as the canonical source that templates copy from.

```
template-repo/
├── .devrail.yml
├── Makefile              <-- THIS STORY (reference implementation)
└── ...
```

### Anti-Patterns to Avoid

1. DO NOT hardcode language checks -- read .devrail.yml to determine active languages
2. DO NOT swallow exit codes -- propagate 0/1/2 faithfully from internal targets through public targets
3. DO NOT skip JSON output -- every target must emit a JSON summary line on stdout
4. DO NOT use spaces for Makefile indentation -- tabs are mandatory (enforced by .editorconfig)
5. DO NOT put tool invocations in public targets -- public targets ONLY delegate to Docker, all logic lives in internal targets
6. DO NOT use abbreviated target names -- use `security` not `sec`, `format` not `fmt`
7. DO NOT make internal targets `.PHONY` with help comments -- only public targets appear in help output

### Conventional Commits

- Scope: `makefile`
- Examples:
  - `feat(makefile): create reference Makefile with two-layer delegation pattern`
  - `feat(makefile): implement .devrail.yml language detection`

### References

- [architecture.md - Core Architectural Decisions - Makefile Contract Specification]
- [architecture.md - Makefile Authoring Patterns]
- [architecture.md - Output & Logging Conventions]
- [architecture.md - Configuration File Formats]
- [prd.md - Functional Requirements FR3, FR4]
- [epics.md - Epic 3: Makefile Contract - Story 3.1]

## Senior Developer Review (AI)

**Reviewer:** Claude Opus 4.6 (adversarial review)
**Date:** 2026-02-20
**Verdict:** PASS with fixes applied

### Acceptance Criteria Assessment

| AC | Status | Notes |
|----|--------|-------|
| #1 | IMPLEMENTED | DEVRAIL_IMAGE uses ?= for override |
| #2 | IMPLEMENTED | Public targets delegate via DOCKER_RUN |
| #3 | IMPLEMENTED | All internal targets use _ prefix |
| #4 | IMPLEMENTED | .DEFAULT_GOAL := help with ## comment parsing |
| #5 | IMPLEMENTED | yq-based .devrail.yml parsing with HAS_* variables |
| #6 | IMPLEMENTED | Canonical file structure order followed |

### Findings (5 total)

1. **[HIGH] install-hooks target in github/gitlab templates was a bare `pre-commit install`** -- No Python check, no git repo check, no pre-commit auto-installation, no --hook-type commit-msg registration. This violates the contract spec which requires idempotent, robust hook installation. **FIXED:** Replaced with full install-hooks implementation including Python 3 check, git repo validation, pipx/pip fallback, and dual hook registration (pre-commit + commit-msg).

2. **[HIGH] dev-toolchain Makefile missing install-hooks target and .PHONY entry** -- The dev-toolchain Makefile had no install-hooks target at all, and the .PHONY declaration was missing install-hooks. **FIXED:** Added install-hooks to .PHONY and implemented the full target.

3. **[MEDIUM] _check-config does not quote DEVRAIL_CONFIG in test -f** -- `if [ ! -f $(DEVRAIL_CONFIG) ]` should be `if [ ! -f "$(DEVRAIL_CONFIG)" ]` to handle paths with spaces. **FIXED:** Added quotes across all three Makefiles.

4. **[LOW] Language detection via $(shell yq ...) runs at Makefile parse time on the host** -- The LANGUAGES variable is set via $(shell yq ...) which executes when Make parses the file on the host. On the host, yq may not be installed, so LANGUAGES silently evaluates to empty. This is acceptable because the public targets don't use these variables directly (they delegate to Docker), and the internal targets inside the container will parse correctly. However, this means a developer can't inspect language variables from the host. Acceptable for MVP.

5. **[LOW] JSON output uses custom field names (languages, failed) not in the makefile-contract.md spec** -- The contract spec defines `errors` array on failure; the implementation uses `failed` and `languages` arrays. This is an enhancement over the spec and provides more structured information. Acceptable deviation but noted for spec update.

### Files Modified During Review

- github-repo-template/Makefile (install-hooks expanded, _check-config quoted)
- gitlab-repo-template/Makefile (install-hooks expanded, _check-config quoted)
- dev-toolchain/Makefile (install-hooks added, _check-config quoted, .PHONY updated)

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (claude-opus-4-6)

### Debug Log References

### Completion Notes List

- Updated all three Makefiles (github-repo-template, gitlab-repo-template, dev-toolchain) with the complete two-layer delegation pattern
- Added DEVRAIL_IMAGE, DEVRAIL_FAIL_FAST, DEVRAIL_LOG_FORMAT as ?= overridable variables
- DOCKER_RUN variable encapsulates docker run with volume mount, workspace dir, and env passthrough
- .DEFAULT_GOAL set to help; help target auto-generates from ## comments with sorted, colored output
- .devrail.yml parsing via yq with HAS_PYTHON/HAS_BASH/HAS_TERRAFORM/HAS_ANSIBLE filter variables
- _check-config internal target validates .devrail.yml exists, exits 2 on missing config
- All internal targets (_lint, _format, _test, _security, _scan, _docs, _check) created with full implementation
- Public targets listed alphabetically with ## description comments
- .PHONY declarations for both public and internal targets
- Canonical file structure order maintained: variables, DOCKER_RUN, .DEFAULT_GOAL, .PHONY, public targets, internal targets

### File List

- github-repo-template/Makefile (modified)
- gitlab-repo-template/Makefile (modified)
- dev-toolchain/Makefile (modified)
