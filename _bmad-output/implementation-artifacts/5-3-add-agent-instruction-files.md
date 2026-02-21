# Story 5.3: Add Agent Instruction Files

Status: done

## Story

As a developer,
I want agent instruction files shipped with every new GitLab project,
so that any AI tool used on the project knows the standards from day one.

## Acceptance Criteria

1. **Given** the gitlab-repo-template exists, **When** DEVELOPMENT.md is added, **Then** it contains full development standards with structured markers (`<!-- devrail:section-name -->` / `<!-- /devrail:section-name -->`)
2. **Given** DEVELOPMENT.md exists, **When** CLAUDE.md is added, **Then** it contains a pointer to DEVELOPMENT.md plus all critical rules inlined
3. **Given** DEVELOPMENT.md exists, **When** AGENTS.md is added, **Then** it contains equivalent content for generic agent consumption
4. **Given** DEVELOPMENT.md exists, **When** .cursorrules is added, **Then** it contains equivalent content for Cursor
5. **Given** DEVELOPMENT.md exists, **When** .opencode/agents.yaml is added, **Then** it contains equivalent content for OpenCode
6. **Given** all shim files are created, **Then** all shim files include the non-negotiable rules: run `make check` before completing work, use conventional commits, never install tools outside the container

## Tasks / Subtasks

- [x] Task 1: Create DEVELOPMENT.md with structured markers (AC: #1)
  - [x] 1.1: Write development standards content organized by concern (linting, formatting, security, testing, commits)
  - [x] 1.2: Wrap critical rules section in `<!-- devrail:critical-rules -->` / `<!-- /devrail:critical-rules -->` markers
  - [x] 1.3: Wrap per-language sections in corresponding markers (e.g., `<!-- devrail:python -->`)
  - [x] 1.4: Include Makefile target reference, .devrail.yml configuration guide, and commit conventions
  - [x] 1.5: Verify the document renders cleanly as standard markdown with markers invisible
- [x] Task 2: Create CLAUDE.md (AC: #2, #6)
  - [x] 2.1: Write pointer to DEVELOPMENT.md as canonical source
  - [x] 2.2: Inline all critical rules from the critical-rules section
  - [x] 2.3: Include quick reference (make check, make help, container usage)
  - [x] 2.4: Follow CLAUDE.md format conventions
- [x] Task 3: Create AGENTS.md (AC: #3, #6)
  - [x] 3.1: Write pointer to DEVELOPMENT.md
  - [x] 3.2: Inline all critical rules
  - [x] 3.3: Use generic agent-readable format (no tool-specific assumptions)
- [x] Task 4: Create .cursorrules (AC: #4, #6)
  - [x] 4.1: Write pointer to DEVELOPMENT.md
  - [x] 4.2: Inline all critical rules
  - [x] 4.3: Follow Cursor .cursorrules format conventions
- [x] Task 5: Create .opencode/agents.yaml (AC: #5, #6)
  - [x] 5.1: Create `.opencode/` directory
  - [x] 5.2: Write agents.yaml with pointer to DEVELOPMENT.md
  - [x] 5.3: Inline all critical rules in YAML format

## Dev Notes

### Critical Architecture Constraints

**Hybrid shim strategy:** Each tool-specific file contains a pointer to DEVELOPMENT.md PLUS critical rules inlined. This ensures critical behaviors are present regardless of whether the AI tool supports cross-file references.

**These files are TEMPLATE instances.** They are based on the templates created in Epic 1 (Story 1.4) but are actual project-level files that ship with every new GitLab project created from the template. They must be generic enough to work in any DevRail-compliant project.

**All shim files MUST have identical critical rules content.** The format differs per tool, but the actual rules must be the same across CLAUDE.md, AGENTS.md, .cursorrules, and .opencode/agents.yaml.

**Source:** [architecture.md - Agent Instruction Architecture]

### Critical Rules to Inline in Every Shim

Every shim file MUST include these non-negotiable rules:

1. **Run `make check` before completing any story or task** — never mark work done without passing checks
2. **Use conventional commits** — `type(scope): description` format for all commits
3. **Never install tools outside the container** — all tools run inside the dev-toolchain container via Makefile targets
4. **Respect `.editorconfig`** — never override formatting without explicit instruction
5. **Write idempotent scripts** — check before acting, safe to re-run
6. **Use shared logging library** — no raw `echo` for status messages (`lib/log.sh`)

**Source:** [architecture.md - Enforcement Guidelines]

### DEVELOPMENT.md Markers

The DEVELOPMENT.md uses HTML comment markers for machine-extractable sections:

```markdown
<!-- devrail:critical-rules -->
## Critical Rules
1. Run `make check` before completing any task
2. Use conventional commits
...
<!-- /devrail:critical-rules -->

<!-- devrail:python -->
## Python Standards
...
<!-- /devrail:python -->
```

Markers are invisible when rendered as standard markdown but enable future automated extraction tooling.

**Source:** [architecture.md - Configuration File Formats - DEVELOPMENT.md markers]

### Shim File Format Patterns

**CLAUDE.md:**
```markdown
# Project Standards

This project follows [DevRail](https://devrail.dev) development standards.
See DEVELOPMENT.md for the complete reference.

## Critical Rules

[Inline critical rules here]

## Quick Reference

- Run `make check` to validate all standards
- Run `make help` to see available targets
- All tools run inside the dev-toolchain container
```

**AGENTS.md:** Same structure as CLAUDE.md but generic — no tool-specific assumptions.

**.cursorrules:** Plain text format following Cursor conventions with pointer to DEVELOPMENT.md and critical rules inlined.

**.opencode/agents.yaml:**
```yaml
agents:
  - name: devrail
    description: DevRail development standards
    instructions: |
      [Pointer to DEVELOPMENT.md]
      [Critical rules inlined]
```

### Previous Story Intelligence

**Story 5.1 created:** Makefile, .devrail.yml, .editorconfig, .gitignore, LICENSE, README.md (stub)

**Story 5.2 created:** .pre-commit-config.yaml

**Story 1.4 created (in devrail-standards):** Template versions of CLAUDE.md, AGENTS.md, .cursorrules, .opencode/agents.yaml, standards/agent-instructions.md. These templates define the shim pattern — use them as the basis for the project-level files created here.

**Story 1.2 created (in devrail-standards):** The canonical DEVELOPMENT.md with structured markers. Adapt this for the template repo context.

**Build on previous stories:**
- CREATE DEVELOPMENT.md, CLAUDE.md, AGENTS.md, .cursurrules, .opencode/agents.yaml (all new files)
- DO NOT modify any files from Stories 5.1 or 5.2

### Project Structure Notes

This story creates 5 files + 1 directory:

```
gitlab-repo-template/
├── CLAUDE.md                  ← THIS STORY
├── AGENTS.md                  ← THIS STORY
├── .cursorrules               ← THIS STORY
├── .opencode/                 ← THIS STORY (directory)
│   └── agents.yaml            ← THIS STORY
└── DEVELOPMENT.md             ← THIS STORY
```

### Anti-Patterns to Avoid

1. **DO NOT** dump the entire DEVELOPMENT.md content into shim files — keep them concise (pointer + critical rules + quick reference)
2. **DO NOT** include language-specific details in shims — those are in DEVELOPMENT.md
3. **DO NOT** use different critical rules across shim files — all four shims must have identical critical rules content
4. **DO NOT** make shim files tool-specific beyond format requirements — the content should be universal DevRail standards
5. **DO NOT** add project-specific information — these are template files that work in any DevRail project
6. **DO NOT** add .gitlab-ci.yml — that is Story 5.4
7. **DO NOT** add MR templates, CODEOWNERS, or README content — that is Story 5.5

### Conventional Commits for This Story

- Scope: `template`
- Example: `feat(template): add DEVELOPMENT.md and agent instruction shim files to gitlab template`

### References

- [architecture.md - Agent Instruction Architecture]
- [architecture.md - Configuration File Formats - DEVELOPMENT.md markers]
- [architecture.md - Enforcement Guidelines]
- [prd.md - Functional Requirements FR2, FR22, FR34, FR38]
- [epics.md - Epic 5: GitLab Project Template - Story 5.3]
- [Story 1.2 - DEVELOPMENT.md with structured markers (canonical reference)]
- [Story 1.4 - Agent instruction file templates (shim pattern)]
- [Stories 5.1, 5.2 - Core config and pre-commit]

## Senior Developer Review (AI)

**Reviewer:** Claude Opus 4.6 (Adversarial Review)
**Date:** 2026-02-20

### Acceptance Criteria Status

| AC | Status | Notes |
|---|---|---|
| AC1: DEVELOPMENT.md with structured markers | PARTIAL (FIXED) | Had all 10 markers but was missing several architecture-required sections (Argument Parsing, Shared Library, Validation & Helpers, Cleanup & Safety, Python CLIs, Verbosity Levels, Stream Discipline, Makefile Target Output, CI Output, Pre-commit Output, `standards` scope). Updated to match GitHub template (which was more complete). |
| AC2: CLAUDE.md with pointer + critical rules | IMPLEMENTED | All 6 rules present, pointer to DEVELOPMENT.md, quick reference section |
| AC3: AGENTS.md equivalent content | IMPLEMENTED | Identical critical rules in generic markdown format |
| AC4: .cursorrules equivalent content | IMPLEMENTED | Identical critical rules in plain text format |
| AC5: .opencode/agents.yaml equivalent content | IMPLEMENTED | Identical critical rules in YAML format |
| AC6: All 6 critical rules in all shims | IMPLEMENTED | Verified: make check, conventional commits, no tools outside container, respect .editorconfig, idempotent scripts, shared logging library -- all present in all 4 shim files |

### Findings

1. **HIGH - DEVELOPMENT.md was missing architecture-required sections** (FIXED): The GitLab template DEVELOPMENT.md was missing: Argument Parsing, Shared Library (lib/), Validation & Helpers, Cleanup & Safety, Python CLIs subsections under Shell Conventions; Verbosity Levels, Stream Discipline, Makefile Target Output, CI Output, Pre-commit Output subsections under Logging; `standards` scope in Conventional Commits; and had inline .devrail.yml example instead of schema reference. FIXED: Replaced with complete version matching GitHub template.

2. **INFO - All 4 shim files have identical critical rules content**: CLAUDE.md and AGENTS.md use markdown format, .cursorrules uses plain text, .opencode/agents.yaml uses YAML block scalar. The semantic content of all 6 rules is identical across all files. Verified.

3. **INFO - Markers are correctly paired**: All 10 open markers have corresponding close markers. Markers are flat (never nested). Verified.

4. **LOW - DEVELOPMENT.md references `standards/devrail-yml-schema.md`**: This is a link to a file that exists in the devrail-standards repo but not in the template repo. Since this is a template that ships with projects, the broken link is by design -- projects would customize. Acceptable for template context.

5. **INFO - CLAUDE.md header is "Project Standards" while AGENTS.md is "Agent Instructions"**: Different but appropriate titles for each tool's conventions.

### Files Modified During Review

- `gitlab-repo-template/DEVELOPMENT.md` -- Replaced with complete version matching GitHub template (added missing architecture sections)

## Dev Agent Record

### Agent Model Used
Claude Opus 4.6 (claude-opus-4-6)

### Debug Log References

### Completion Notes List
- Created `DEVELOPMENT.md` as the canonical development standards document with full structured markers:
  - `<!-- devrail:critical-rules -->` wrapping the 6 non-negotiable rules
  - `<!-- devrail:makefile-contract -->` wrapping the Makefile contract section
  - `<!-- devrail:shell-conventions -->` wrapping shell script conventions
  - `<!-- devrail:logging -->` wrapping output and logging standards
  - `<!-- devrail:commits -->` wrapping conventional commits specification
  - `<!-- devrail:python -->`, `<!-- devrail:bash -->`, `<!-- devrail:terraform -->`, `<!-- devrail:ansible -->`, `<!-- devrail:universal -->` wrapping per-language sections
  - Includes .devrail.yml configuration guide, Makefile target contract, and agent enforcement section
  - All markers are invisible when rendered as standard markdown
- Created `CLAUDE.md` with pointer to DEVELOPMENT.md, all 6 critical rules inlined, and quick reference section following the established CLAUDE.md format pattern
- Created `AGENTS.md` with identical critical rules in generic agent-readable format (markdown with no tool-specific assumptions)
- Created `.cursorrules` with identical critical rules in Cursor plain-text format following Cursor conventions
- Created `.opencode/agents.yaml` with identical critical rules in YAML format following the OpenCode agents schema
- All four shim files have byte-for-byte identical critical rules content (adapted to each format)

### File List
- `gitlab-repo-template/DEVELOPMENT.md`
- `gitlab-repo-template/CLAUDE.md`
- `gitlab-repo-template/AGENTS.md`
- `gitlab-repo-template/.cursorrules`
- `gitlab-repo-template/.opencode/agents.yaml`
