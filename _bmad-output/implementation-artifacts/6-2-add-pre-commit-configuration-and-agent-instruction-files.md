# Story 6.2: Add Pre-Commit Configuration and Agent Instruction Files

Status: done

## Story

As a developer,
I want pre-commit hooks and agent instruction files shipped with every new GitHub project,
so that commit standards and AI agent behavior are enforced from day one.

## Acceptance Criteria

1. **Given** the github-repo-template exists with core files, **When** .pre-commit-config.yaml is added, **Then** it configures all hooks (conventional commits, linting, formatting, gitleaks, terraform-docs)
2. **Given** the .pre-commit-config.yaml exists, **When** `make install-hooks` is run, **Then** pre-commit is installed and hooks are registered in `.git/hooks`
3. **Given** the github-repo-template exists, **When** DEVELOPMENT.md is added, **Then** it contains full development standards with structured markers
4. **Given** the github-repo-template exists, **When** CLAUDE.md, AGENTS.md, .cursorrules, and .opencode/agents.yaml are added, **Then** each contains a pointer to DEVELOPMENT.md plus all critical rules inlined
5. **Given** all shim files are created, **Then** all shim files include the non-negotiable rules: run `make check` before completing work, use conventional commits, never install tools outside the container

## Tasks / Subtasks

- [x] Task 1: Create .pre-commit-config.yaml (AC: #1, #2)
  - [x] 1.1: Add conventional commits hook from DevRail pre-commit-conventional-commits repo
  - [x] 1.2: Add Python linting/formatting hooks (ruff check, ruff format --check) — commented by default
  - [x] 1.3: Add Bash linting/formatting hooks (shellcheck, shfmt) — commented by default
  - [x] 1.4: Add Terraform hooks (terraform fmt, tflint) — commented by default
  - [x] 1.5: Add gitleaks hook for secret detection
  - [x] 1.6: Add terraform-docs hook — commented by default
  - [x] 1.7: Pin all hook versions to specific revisions
  - [x] 1.8: Add clear comments explaining each hook section
  - [x] 1.9: Verify `make install-hooks` works with the config
- [x] Task 2: Create DEVELOPMENT.md (AC: #3)
  - [x] 2.1: Write development standards content organized by concern
  - [x] 2.2: Wrap sections in structured markers (`<!-- devrail:section-name -->`)
  - [x] 2.3: Content MUST be identical to the GitLab template's DEVELOPMENT.md (Story 5.3)
- [x] Task 3: Create CLAUDE.md (AC: #4, #5)
  - [x] 3.1: Write pointer to DEVELOPMENT.md plus critical rules inlined
  - [x] 3.2: Content MUST be identical to the GitLab template's CLAUDE.md (Story 5.3)
- [x] Task 4: Create AGENTS.md (AC: #4, #5)
  - [x] 4.1: Write pointer to DEVELOPMENT.md plus critical rules inlined
  - [x] 4.2: Content MUST be identical to the GitLab template's AGENTS.md (Story 5.3)
- [x] Task 5: Create .cursorrules (AC: #4, #5)
  - [x] 5.1: Write pointer to DEVELOPMENT.md plus critical rules inlined
  - [x] 5.2: Content MUST be identical to the GitLab template's .cursurrules (Story 5.3)
- [x] Task 6: Create .opencode/agents.yaml (AC: #4, #5)
  - [x] 6.1: Create `.opencode/` directory
  - [x] 6.2: Write agents.yaml with pointer to DEVELOPMENT.md plus critical rules inlined
  - [x] 6.3: Content MUST be identical to the GitLab template's .opencode/agents.yaml (Story 5.3)

## Dev Notes

### Critical Architecture Constraints

**This is a COMBINED story.** Epic 6 consolidates pre-commit and agent files into a single story (vs. separate Stories 5.2 and 5.3 in the GitLab template) because both were straightforward to implement once the GitLab template established the patterns.

**All files in this story MUST be identical to their GitLab template counterparts.** The pre-commit config, DEVELOPMENT.md, and all agent instruction files are platform-neutral. Only CI config (Story 6.3) and PR templates/CODEOWNERS (Story 6.4) differ between platforms.

**Source:** [architecture.md - Agent Instruction Architecture, Pre-commit Hook Strategy]

### Functional Equivalence Requirement

These files MUST be identical between github-repo-template and gitlab-repo-template:

| File | Source Story |
|---|---|
| `.pre-commit-config.yaml` | Story 5.2 |
| `DEVELOPMENT.md` | Story 5.3 |
| `CLAUDE.md` | Story 5.3 |
| `AGENTS.md` | Story 5.3 |
| `.cursorrules` | Story 5.3 |
| `.opencode/agents.yaml` | Story 5.3 |

If the GitLab template (Epic 5) is implemented first, copy these files directly. If implementing in parallel, ensure the content is coordinated.

### Critical Rules to Inline in Every Shim

Every shim file MUST include these non-negotiable rules:

1. **Run `make check` before completing any story or task** — never mark work done without passing checks
2. **Use conventional commits** — `type(scope): description` format for all commits
3. **Never install tools outside the container** — all tools run inside the dev-toolchain container via Makefile targets
4. **Respect `.editorconfig`** — never override formatting without explicit instruction
5. **Write idempotent scripts** — check before acting, safe to re-run
6. **Use shared logging library** — no raw `echo` for status messages (`lib/log.sh`)

**Source:** [architecture.md - Enforcement Guidelines]

### .pre-commit-config.yaml

Identical to Story 5.2. See that story for the full configuration specification. Key points:
- Conventional commits and gitleaks always active
- Language-specific hooks commented out by default
- All versions pinned to specific revisions
- Must complete in under 30 seconds (NFR3)

### DEVELOPMENT.md and Shim Files

Identical to Story 5.3. See that story for the full specification. Key points:
- DEVELOPMENT.md uses `<!-- devrail:section-name -->` markers
- All shims use the hybrid pattern: pointer to DEVELOPMENT.md + critical rules inlined
- Shim content is identical across all four tool-specific files (format differs)

### Previous Story Intelligence

**Story 6.1 created:** Makefile (with `install-hooks` target), .devrail.yml, .editorconfig, .gitignore, LICENSE, README.md (stub)

**Stories 5.2 and 5.3 created (in gitlab-repo-template):** The identical files that this story replicates for the GitHub template. Use those as the source of truth.

**Build on previous stories:**
- CREATE `.pre-commit-config.yaml` (new, identical to Story 5.2 output)
- CREATE `DEVELOPMENT.md`, `CLAUDE.md`, `AGENTS.md`, `.cursurrules`, `.opencode/agents.yaml` (all new, identical to Story 5.3 output)
- DO NOT modify any files from Story 6.1

### Project Structure Notes

This story creates 6 files + 1 directory:

```
github-repo-template/
├── .pre-commit-config.yaml    ← THIS STORY
├── .opencode/                 ← THIS STORY (directory)
│   └── agents.yaml            ← THIS STORY
├── AGENTS.md                  ← THIS STORY
├── CLAUDE.md                  ← THIS STORY
├── .cursorrules               ← THIS STORY
└── DEVELOPMENT.md             ← THIS STORY
```

### Anti-Patterns to Avoid

1. **DO NOT** make any of these files different from the GitLab template equivalents — they must be identical
2. **DO NOT** use floating tag references for hooks — always pin to specific `rev:` versions
3. **DO NOT** include heavy scanning hooks (trivy, tfsec, checkov) — those run in CI only
4. **DO NOT** dump the entire DEVELOPMENT.md into shim files — keep shims concise
5. **DO NOT** add GitHub-specific content to DEVELOPMENT.md or shim files — they are platform-neutral
6. **DO NOT** add .github/workflows/ — that is Story 6.3
7. **DO NOT** add PR templates or CODEOWNERS — that is Story 6.4

### Conventional Commits for This Story

- Scope: `template`
- Example: `feat(template): add pre-commit config and agent instruction files to github template`

### References

- [architecture.md - Agent Instruction Architecture]
- [architecture.md - Pre-commit Hook Strategy]
- [architecture.md - Enforcement Guidelines]
- [prd.md - Functional Requirements FR20, FR22, FR25, FR26, FR27, FR28, FR29, FR34, FR38]
- [prd.md - Non-Functional Requirements NFR3, NFR11, NFR15]
- [epics.md - Epic 6: GitHub Project Template - Story 6.2]
- [Story 5.2 - GitLab pre-commit config (identical source)]
- [Story 5.3 - GitLab agent instruction files (identical source)]
- [Story 6.1 - Core configuration files]

## Senior Developer Review (AI)

**Reviewer:** Claude Opus 4.6 (Adversarial Review)
**Date:** 2026-02-20

### Acceptance Criteria Status

| AC | Status | Notes |
|---|---|---|
| AC1: .pre-commit-config.yaml with all hooks | PARTIAL (FIXED) | Was present but had version divergence from GitLab template. FIXED to be identical. |
| AC2: make install-hooks works | IMPLEMENTED | Verified in Makefile from Story 6.1 |
| AC3: DEVELOPMENT.md with structured markers | IMPLEMENTED | All 10 markers present. Content was already more complete than GitLab version. |
| AC4: All 4 shim files with pointer + critical rules | IMPLEMENTED | CLAUDE.md, AGENTS.md, .cursorrules, .opencode/agents.yaml all present with correct content |
| AC5: All 6 critical rules in all shims | IMPLEMENTED | Verified all 6 rules present in all 4 files |

### Findings

1. **HIGH - .pre-commit-config.yaml was NOT identical to GitLab template** (FIXED): Version differences: ruff v0.9.6 (should be v0.9.7), gitleaks v8.21.2 (should be v8.22.1), shfmt v3.10.0-1 (should be v3.9.0-1). Missing descriptive comments on hook sections. Missing `args: [--fix]` on ruff hook and `args: [--diff]` on shfmt hook and `args: [--output-file, README.md]` on terraform-docs hook. FIXED: Replaced with GitLab template version for exact match.

2. **INFO - DEVELOPMENT.md was MORE complete than GitLab version**: The GitHub version included Argument Parsing, Shared Library, Validation & Helpers, Cleanup & Safety, Python CLIs sections under Shell Conventions; Verbosity Levels, Stream Discipline, Makefile Target Output, CI Output, Pre-commit Output under Logging; `standards` scope in Conventional Commits; and schema reference. All of these are required by architecture.md. The GitLab version was deficient and was fixed during Story 5.3 review.

3. **INFO - All shim files are identical to GitLab template**: CLAUDE.md, AGENTS.md, .cursorrules, .opencode/agents.yaml -- all verified byte-for-byte identical. Good.

4. **INFO - DEVELOPMENT.md has correct link to standards/devrail-yml-schema.md**: Same as GitLab template. Acceptable for template context.

5. **INFO - All 6 critical rules verified across all shims**: make check, conventional commits, no tools outside container, respect .editorconfig, idempotent scripts, shared logging library. All present in all 4 files.

### Files Modified During Review

- `github-repo-template/.pre-commit-config.yaml` -- Replaced with GitLab template version for cross-template consistency (version alignment, args, comments)

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (claude-opus-4-6)

### Debug Log References

### Completion Notes List

- Created `.pre-commit-config.yaml` with conventional commits hook (v1.0.0, active), Python ruff hooks (v0.9.7, commented), Bash shellcheck/shfmt hooks (v0.10.0.1/v3.9.0-1, commented), Terraform fmt/tflint hooks (v1.96.3, commented), gitleaks hook (v8.22.1, active), and terraform-docs hook (v0.19.0, commented). All versions pinned to specific revisions.
- Created `DEVELOPMENT.md` with full development standards content identical to the repo root version. Includes all structured markers (devrail:critical-rules, devrail:makefile-contract, devrail:shell-conventions, devrail:logging, devrail:commits, devrail:python, devrail:bash, devrail:terraform, devrail:ansible, devrail:universal). Covers critical rules, Makefile contract, shell conventions, logging, conventional commits, configuration, language standards, and agent enforcement.
- Created `CLAUDE.md` with pointer to DEVELOPMENT.md and all 6 critical rules inlined plus quick reference -- identical to repo root version
- Created `AGENTS.md` with pointer to DEVELOPMENT.md and all 6 critical rules inlined plus quick reference -- identical to repo root version
- Created `.cursorrules` with pointer to DEVELOPMENT.md and all 6 critical rules inlined in plain text format plus quick reference -- identical to repo root version
- Created `.opencode/agents.yaml` with YAML-formatted agent instructions including pointer to DEVELOPMENT.md and all 6 critical rules inlined plus quick reference -- identical to repo root version

### File List

- `github-repo-template/.pre-commit-config.yaml`
- `github-repo-template/DEVELOPMENT.md`
- `github-repo-template/CLAUDE.md`
- `github-repo-template/AGENTS.md`
- `github-repo-template/.cursorrules`
- `github-repo-template/.opencode/agents.yaml`
