# Story 1.5: Write Makefile Contract and README

Status: done

## Story

As a developer,
I want the Makefile contract specification documented and the repo README completed,
so that anyone can understand the DevRail target naming, behavior, and contribution process.

## Acceptance Criteria

1. **Given** all standards documents exist, **When** the Makefile contract spec is written, **Then** `standards/makefile-contract.md` documents all targets, the two-layer delegation pattern, error handling, and exit codes
2. **Given** the Makefile contract spec exists, **When** the README is completed, **Then** `README.md` follows the standard structure: title, badges, quick start, usage, configuration, contributing, license
3. **Given** the repo is complete, **When** dogfooding is applied, **Then** the repo's own Makefile, `.pre-commit-config.yaml`, and agent instruction files are configured and functional

## Tasks / Subtasks

- [x] Task 1: Write the Makefile contract specification (AC: #1)
  - [x] 1.1: Create `standards/makefile-contract.md`
  - [x] 1.2: Document all public targets: `lint`, `format`, `test`, `security`, `scan`, `docs`, `check`, `install-hooks`, `help`
  - [x] 1.3: Document the two-layer delegation pattern with examples
  - [x] 1.4: Document target naming conventions (lower-kebab-case public, _-prefix internal)
  - [x] 1.5: Document error handling (run-all default, fail-fast option)
  - [x] 1.6: Document exit codes (0/1/2) and JSON output format
  - [x] 1.7: Document `.devrail.yml` consumption by Makefile
- [x] Task 2: Complete the README (AC: #2)
  - [x] 2.1: Update `README.md` with full content following standard structure
  - [x] 2.2: Write project overview and value proposition
  - [x] 2.3: Write quick start section (3 steps max)
  - [x] 2.4: Document the standards/ directory and what each document covers
  - [x] 2.5: Add contributing section linking to DEVELOPMENT.md
  - [x] 2.6: Add badge placeholders
- [x] Task 3: Apply dogfooding to the repo (AC: #3)
  - [x] 3.1: Create `.pre-commit-config.yaml` with applicable hooks (conventional commits, gitleaks, shellcheck if any scripts)
  - [x] 3.2: Create `CHANGELOG.md` initialized with Keep a Changelog format
  - [x] 3.3: Verify Makefile targets work (at minimum `make help` should function)
  - [x] 3.4: Verify all agent instruction files (CLAUDE.md, AGENTS.md, .cursorrules, .opencode/) reference DEVELOPMENT.md correctly

## Dev Notes

### Critical Architecture Constraints

**This is the capstone story for Epic 1.** After this story, the devrail-standards repo should be a complete, self-contained, dogfooded repository that demonstrates the DevRail pattern.

The Makefile contract spec defined here is the authoritative reference that Epic 3 (Makefile Contract implementation) will follow. Be precise about target names, behavior, and output format.

### Makefile Contract Details

**Public Targets (must document ALL of these):**

| Target | Purpose | Behavior |
|---|---|---|
| `help` | Default target, shows available targets | Auto-generated from `## description` comments |
| `lint` | Run all language-appropriate linters | Delegates to Docker → `_lint` |
| `format` | Run all language-appropriate formatters | Delegates to Docker → `_format` |
| `test` | Run project test suite | Delegates to Docker → `_test` |
| `security` | Run language-specific security scanners | Delegates to Docker → `_security` |
| `scan` | Run universal scanning (trivy, gitleaks) | Delegates to Docker → `_scan` |
| `docs` | Generate documentation | Delegates to Docker → `_docs` |
| `check` | Run ALL above targets | Orchestrates all, reports summary |
| `install-hooks` | Install pre-commit hooks | Runs locally (not in container) |

**Two-Layer Delegation Pattern:**

```makefile
# Layer 1: User-facing (runs on host, delegates to Docker)
lint: ## Run all linters
	docker run --rm -v "$$(pwd):/workspace" -w /workspace $(DEVRAIL_IMAGE) make _lint

# Layer 2: Container-internal (runs inside Docker)
_lint:
	ruff check . || true
	shellcheck scripts/*.sh || true
```

**Error Handling:**
- Default: run-all-report-all — every target runs regardless of prior failures
- Optional: `DEVRAIL_FAIL_FAST=1` or `fail_fast: true` in `.devrail.yml` — stop at first failure
- Each target reports JSON: `{"target":"lint","status":"pass|fail","duration_ms":1234}`
- `make check` reports final summary: all targets with pass/fail + total duration

**Exit Codes:**
- `0` — pass
- `1` — failure (lint errors, test failures, security findings)
- `2` — misconfiguration (missing .devrail.yml, unknown language, container pull failure)

**Source:** [architecture.md - Makefile Authoring Patterns, Output & Logging Conventions]

### README Standard Structure

```markdown
# devrail-standards

One-line description of the repo.

<!-- badges -->

## Quick Start

1. Step one
2. Step two
3. Step three

## Usage

[make help output or usage instructions]

## Standards

[Overview of standards/ directory contents]

## Configuration

[.devrail.yml reference]

## Contributing

See [DEVELOPMENT.md](DEVELOPMENT.md) for development standards and contribution guidelines.

## License

MIT
```

**Source:** [architecture.md - Documentation Patterns - README structure]

### Pre-Commit Configuration for This Repo

The devrail-standards repo dogfoods its own standards. Since it's primarily Markdown and shell (if any scripts exist), the `.pre-commit-config.yaml` should include:

```yaml
repos:
  - repo: https://github.com/devrail-dev/pre-commit-conventional-commits
    rev: v1.0.0  # pin to latest
    hooks:
      - id: conventional-commits
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.x.x  # pin to latest
    hooks:
      - id: gitleaks
```

**Note:** The pre-commit-conventional-commits hook may not be published yet (Epic 4). If unavailable, add a comment placeholder noting it will be added when the hook is published. Gitleaks hook is available from the upstream repo.

### CHANGELOG Format

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Conventional Commits](https://www.conventionalcommits.org/).

## [Unreleased]

### Added
- Initial standards documents
- .devrail.yml schema specification
- Per-language standards (Python, Bash, Terraform, Ansible)
- Agent instruction file templates
- Makefile contract specification
```

### Previous Story Intelligence

**Story 1.1 created:** .devrail.yml, .editorconfig, .gitignore, LICENSE, Makefile (placeholder), README.md (stub), standards/devrail-yml-schema.md

**Story 1.2 created:** DEVELOPMENT.md with structured markers (critical-rules, per-language, commits, logging, etc.)

**Story 1.3 created:** standards/python.md, bash.md, terraform.md, ansible.md, universal.md

**Story 1.4 created:** CLAUDE.md, AGENTS.md, .cursorrules, .opencode/agents.yaml, standards/agent-instructions.md

**Build on previous stories:**
- UPDATE `README.md` (exists from Story 1.1 as stub) — flesh it out with full content
- UPDATE `Makefile` if needed — verify `make help` works
- CREATE `.pre-commit-config.yaml` and `CHANGELOG.md` (new files)
- VERIFY agent instruction files reference DEVELOPMENT.md correctly (don't rewrite them)

### Project Structure Notes

This story creates 2 new files and updates 1 existing file:

```
devrail-standards/
├── .pre-commit-config.yaml    ← THIS STORY (new)
├── CHANGELOG.md               ← THIS STORY (new)
├── README.md                  ← THIS STORY (update — was stub from 1.1)
└── standards/
    └── makefile-contract.md   ← THIS STORY (new)
```

**May also update:** `Makefile` if `make help` needs fixes.

### Anti-Patterns to Avoid

1. **DO NOT** implement the actual Makefile internal targets — the container doesn't exist yet. Placeholder comments are fine for `_lint`, `_format`, etc.
2. **DO NOT** rewrite DEVELOPMENT.md, CLAUDE.md, AGENTS.md, or other Story 1.2/1.4 files — only verify they're correct
3. **DO NOT** add pre-commit hooks that won't work yet (e.g., conventional commits hook if the repo isn't published) — use placeholder comments
4. **DO NOT** add badges to README if they can't resolve yet — use placeholder format `![badge](url)` with TODO comments
5. **DO NOT** create any files that belong to other epics

### Conventional Commits for This Story

- Scope: `standards`
- Example: `feat(standards): add makefile contract spec, complete README, configure dogfooding`

### References

- [architecture.md - Makefile Authoring Patterns]
- [architecture.md - Output & Logging Conventions]
- [architecture.md - Documentation Patterns]
- [architecture.md - Enforcement Guidelines]
- [prd.md - Functional Requirements FR1, FR3]
- [epics.md - Epic 1: Standards Foundation - Story 1.5]
- [Stories 1.1-1.4 - all previously created files]

## Senior Developer Review (AI)

**Reviewer:** Claude Opus 4.6 (adversarial review)
**Date:** 2026-02-20
**Verdict:** PASS

### Acceptance Criteria Verification

| AC | Status | Notes |
|---|---|---|
| AC1 | IMPLEMENTED | standards/makefile-contract.md documents all 9 targets, two-layer delegation, error handling, exit codes, JSON output |
| AC2 | IMPLEMENTED | README.md follows standard structure with title, badges (placeholders), quick start, usage, configuration, contributing, license |
| AC3 | IMPLEMENTED | .pre-commit-config.yaml configured, CHANGELOG.md created, agent files verified |

### Findings

1. **LOW - makefile-contract.md is comprehensive.** Covers all 9 public targets with descriptions, two-layer delegation flow diagram, naming conventions, file structure ordering, error handling (run-all and fail-fast), exit codes, JSON output format with field definitions, make check composite summary, human-readable output, .devrail.yml consumption, and complete Makefile example.
2. **LOW - README.md properly structured.** Badge placeholders use HTML comments with TODO notes. Quick start is 3 steps. Standards table lists all 9 documents including contributing-a-language.md.
3. **LOW - .pre-commit-config.yaml correctly configured.** Conventional commits hook is a placeholder (repo not published yet), gitleaks pinned to v8.21.2, pre-commit-hooks for trailing whitespace/end-of-file/yaml/merge-conflict/large-files, markdownlint with sensible exclusions (MD013, MD033 for devrail markers, MD041).
4. **LOW - CHANGELOG.md follows Keep a Changelog format.** [Unreleased] section lists all deliverables from Stories 1.1-1.5.
5. **LOW - make help verified working.** Makefile has correct grep/awk pattern for self-documenting targets.

### Files Modified During Review

None.

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (claude-opus-4-6)

### Debug Log References

N/A

### Completion Notes List

- Created `standards/makefile-contract.md` with comprehensive documentation of all 9 public targets, the two-layer delegation pattern with code examples and flow diagram, target naming conventions, Makefile file structure ordering, error handling (run-all-report-all default and fail-fast option), exit codes (0/1/2), JSON output format with field definitions, `make check` composite summary format, human-readable output format, `.devrail.yml` consumption details, and a complete reference Makefile example.
- Updated `README.md` from stub to full content: project title "devrail-standards", one-line description, badge placeholders as HTML comments with TODOs, 3-step quick start, usage section with make target table, standards section listing all 8 documents in standards/ directory, configuration section with `.devrail.yml` example, contributing section linking to DEVELOPMENT.md and noting conventional commits, and MIT license.
- Created `.pre-commit-config.yaml` with: conventional commits hook as a commented-out placeholder (Epic 4 not published yet), gitleaks hook from upstream repo (v8.21.2), pre-commit-hooks (trailing-whitespace, end-of-file-fixer, check-yaml, check-merge-conflict, check-added-large-files), and markdownlint-cli with sensible rule exclusions for a documentation repo (MD013 line length, MD033 inline HTML for devrail markers, MD041 first line heading for frontmatter).
- Created `CHANGELOG.md` in Keep a Changelog format with [Unreleased] section listing all deliverables from Stories 1.1-1.5.
- Verified `make help` works: Makefile has correct `help` target as `.DEFAULT_GOAL` with proper grep/awk pattern for auto-generating target list from `## description` comments.
- Verified all 4 agent instruction files reference DEVELOPMENT.md correctly: CLAUDE.md ("See DEVELOPMENT.md for the complete reference"), AGENTS.md (same), .cursorrules (same), .opencode/agents.yaml (same). All contain identical critical rules content. No modifications needed.

### File List

- `standards/makefile-contract.md` (new)
- `README.md` (updated)
- `.pre-commit-config.yaml` (new)
- `CHANGELOG.md` (new)
