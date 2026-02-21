# Story 1.4: Create Agent Instruction File Templates

Status: done

## Story

As a developer,
I want template versions of all agent instruction files (CLAUDE.md, AGENTS.md, .cursorrules, .opencode/),
so that project templates can ship files that tell AI agents to follow DevRail standards.

## Acceptance Criteria

1. **Given** the DEVELOPMENT.md and standards documents exist, **When** agent instruction templates are created, **Then** `standards/agent-instructions.md` documents the shim strategy and critical rules list
2. **Given** the shim strategy is documented, **When** template CLAUDE.md is created, **Then** it contains a pointer to DEVELOPMENT.md plus all critical rules inlined
3. **Given** the shim strategy is documented, **When** template AGENTS.md is created, **Then** it contains equivalent content for generic agent consumption
4. **Given** the shim strategy is documented, **When** template .cursorrules is created, **Then** it contains equivalent content for Cursor
5. **Given** the shim strategy is documented, **When** template .opencode/agents.yaml is created, **Then** it contains equivalent content for OpenCode
6. **Given** all shim files are created, **Then** all shim files include: "run `make check` before completing work", "use conventional commits", "never install tools outside the container"

## Tasks / Subtasks

- [x] Task 1: Document the agent shim strategy (AC: #1)
  - [x] 1.1: Create `standards/agent-instructions.md` explaining the hybrid shim pattern
  - [x] 1.2: Document the critical rules list that gets inlined in every shim
  - [x] 1.3: Document how shim files reference DEVELOPMENT.md
  - [x] 1.4: Document the rationale for hybrid approach (pointer + critical rules)
- [x] Task 2: Create template CLAUDE.md (AC: #2, #6)
  - [x] 2.1: Write pointer to DEVELOPMENT.md as canonical source
  - [x] 2.2: Inline all critical rules from `<!-- devrail:critical-rules -->` section
  - [x] 2.3: Include Claude-specific formatting (CLAUDE.md conventions)
- [x] Task 3: Create template AGENTS.md (AC: #3, #6)
  - [x] 3.1: Write pointer to DEVELOPMENT.md
  - [x] 3.2: Inline all critical rules
  - [x] 3.3: Use generic agent-readable format
- [x] Task 4: Create template .cursorrules (AC: #4, #6)
  - [x] 4.1: Write pointer to DEVELOPMENT.md
  - [x] 4.2: Inline all critical rules
  - [x] 4.3: Follow Cursor .cursorrules conventions
- [x] Task 5: Create template .opencode/agents.yaml (AC: #5, #6)
  - [x] 5.1: Create `.opencode/` directory
  - [x] 5.2: Write agents.yaml with pointer to DEVELOPMENT.md
  - [x] 5.3: Inline all critical rules in YAML format

## Dev Notes

### Critical Architecture Constraints

**Hybrid shim strategy:** Each tool-specific file contains a pointer to DEVELOPMENT.md PLUS critical rules inlined. This ensures critical behaviors are present regardless of whether the AI tool supports cross-file references.

**These files are TEMPLATES.** They will be copied into template repos (Epics 5 and 6) and from there into every new project. They must be generic enough to work in any DevRail-compliant project.

**Source:** [architecture.md - Agent Instruction Architecture]

### Critical Rules to Inline in Every Shim

Every shim file MUST include these non-negotiable rules (extracted from DEVELOPMENT.md `<!-- devrail:critical-rules -->`):

1. **Run `make check` before completing any story or task** — never mark work done without passing checks
2. **Use conventional commits** — `type(scope): description` format for all commits
3. **Never install tools outside the container** — all tools run inside the dev-toolchain container via Makefile targets
4. **Respect `.editorconfig`** — never override formatting without explicit instruction
5. **Write idempotent scripts** — check before acting, safe to re-run
6. **Use shared logging library** — no raw `echo` for status messages (`lib/log.sh`)

### Shim File Format Patterns

**CLAUDE.md format:**
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

**AGENTS.md format:**
```markdown
# Agent Instructions

[Same structure as CLAUDE.md but generic — no tool-specific assumptions]
```

**.cursorrules format:**
```
[Plain text format following Cursor conventions]
[Pointer to DEVELOPMENT.md]
[Critical rules inlined]
```

**.opencode/agents.yaml format:**
```yaml
agents:
  - name: devrail
    description: DevRail development standards
    instructions: |
      [Pointer to DEVELOPMENT.md]
      [Critical rules inlined]
```

**Source:** [architecture.md - Agent Instruction Architecture]

### Key Design Principle

The shim files should be **concise but complete on critical rules.** The pointer to DEVELOPMENT.md handles the full standards. The inlined rules handle the non-negotiable behaviors that agents MUST follow even if they can't read cross-referenced files.

**DO NOT** dump the entire DEVELOPMENT.md into each shim. The shims should be short — pointer + critical rules + quick reference.

### Previous Story Intelligence

**Story 1.1 created:** Repo foundation files (.devrail.yml, .editorconfig, .gitignore, LICENSE, Makefile, README.md, standards/devrail-yml-schema.md)

**Story 1.2 created:** DEVELOPMENT.md with structured markers including `<!-- devrail:critical-rules -->` section. This is the canonical source the shims point to.

**Story 1.3 created:** Per-language standards documents (standards/python.md, bash.md, terraform.md, ansible.md, universal.md)

**Build on previous stories:**
- Extract the exact critical rules text from DEVELOPMENT.md's `<!-- devrail:critical-rules -->` section for inlining
- Reference DEVELOPMENT.md as "the canonical source" — don't summarize or paraphrase the full standards

### Project Structure Notes

This story creates 5 files + 1 directory:

```
devrail-standards/
├── CLAUDE.md                  ← THIS STORY
├── AGENTS.md                  ← THIS STORY
├── .cursorrules               ← THIS STORY
├── .opencode/                 ← THIS STORY (directory)
│   └── agents.yaml            ← THIS STORY
└── standards/
    └── agent-instructions.md  ← THIS STORY
```

**DO NOT modify any existing files.** Only create the files listed above.

### Anti-Patterns to Avoid

1. **DO NOT** dump the entire DEVELOPMENT.md content into shim files — keep them concise (pointer + critical rules + quick reference)
2. **DO NOT** include language-specific details in shims — those are in DEVELOPMENT.md
3. **DO NOT** use different critical rules across shim files — all four shims must have identical critical rules content
4. **DO NOT** make shim files tool-specific beyond format requirements — the content should be universal DevRail standards
5. **DO NOT** add project-specific information — these are templates that work in any DevRail project

### Conventional Commits for This Story

- Scope: `standards`
- Example: `feat(standards): create agent instruction file templates with hybrid shim pattern`

### References

- [architecture.md - Agent Instruction Architecture]
- [architecture.md - Enforcement Guidelines]
- [prd.md - Functional Requirements FR2, FR34, FR38]
- [prd.md - AI Agent Integration section]
- [epics.md - Epic 1: Standards Foundation - Story 1.4]
- [Story 1.2 - DEVELOPMENT.md with critical-rules markers]

## Senior Developer Review (AI)

**Reviewer:** Claude Opus 4.6 (adversarial review)
**Date:** 2026-02-20
**Verdict:** PASS

### Acceptance Criteria Verification

| AC | Status | Notes |
|---|---|---|
| AC1 | IMPLEMENTED | standards/agent-instructions.md documents shim strategy and critical rules list |
| AC2 | IMPLEMENTED | CLAUDE.md contains pointer to DEVELOPMENT.md plus all 6 critical rules inlined |
| AC3 | IMPLEMENTED | AGENTS.md contains equivalent content for generic agent consumption |
| AC4 | IMPLEMENTED | .cursorrules contains equivalent content in plain text format |
| AC5 | IMPLEMENTED | .opencode/agents.yaml contains equivalent content in YAML format |
| AC6 | IMPLEMENTED | All shim files include the three mandatory rules: make check, conventional commits, no tools outside container |

### Findings

1. **LOW - All four shim files verified with identical critical rules.** CLAUDE.md, AGENTS.md, .cursorrules, and .opencode/agents.yaml all contain the same six critical rules.
2. **LOW - Format-appropriate structure in each file.** CLAUDE.md and AGENTS.md use markdown headers, .cursorrules uses plain text, agents.yaml uses YAML instructions block.
3. **LOW - Shim files are concise.** Each file is under 35 lines -- pointer + critical rules + quick reference. No DEVELOPMENT.md content dump.
4. **LOW - agent-instructions.md thoroughly documents the rationale.** Explains why hybrid approach was chosen, lists the shim file inventory, and describes the structure pattern.
5. **LOW - No project-specific information in templates.** Files are generic and work in any DevRail-compliant project.

### Files Modified During Review

None.

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (claude-opus-4-6) via Claude Code

### Debug Log References

None -- implementation was straightforward with no debugging required.

### Completion Notes List

- Created `standards/agent-instructions.md` documenting the hybrid shim strategy, rationale, critical rules list, cross-reference pattern, and shim file inventory.
- Created `CLAUDE.md` with pointer to DEVELOPMENT.md, all 6 critical rules inlined, and quick reference section using Claude Code CLAUDE.md conventions.
- Created `AGENTS.md` with identical content to CLAUDE.md but with a generic "Agent Instructions" header -- no tool-specific assumptions.
- Created `.cursorrules` in plain text format following Cursor conventions with pointer, critical rules, and quick reference.
- Created `.opencode/agents.yaml` in YAML format with agents list structure, pointer to DEVELOPMENT.md, and critical rules inlined in the instructions block.
- All 4 shim files contain identical critical rules content extracted verbatim from the `<!-- devrail:critical-rules -->` section of DEVELOPMENT.md.
- No existing files were modified.
- All files follow `.editorconfig` settings (2-space indent, UTF-8, LF line endings, final newline, trim trailing whitespace).

### File List

- `standards/agent-instructions.md` -- hybrid shim strategy documentation
- `CLAUDE.md` -- Claude Code agent instruction shim
- `AGENTS.md` -- generic agent instruction shim
- `.cursorrules` -- Cursor agent instruction shim
- `.opencode/agents.yaml` -- OpenCode agent instruction shim
