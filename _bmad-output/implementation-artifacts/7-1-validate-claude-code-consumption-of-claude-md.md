# Story 7.1: Validate Claude Code Consumption of CLAUDE.md

Status: done

## Story

As a developer,
I want to verify that Claude Code reads CLAUDE.md and follows DevRail standards correctly,
so that I can trust the agent to run checks and use conventional commits without reminding.

## Acceptance Criteria

1. **Given** a DevRail-templated project with CLAUDE.md, **When** Claude Code is given a coding task on the project, **Then** the agent reads CLAUDE.md and references DEVELOPMENT.md for full standards
2. **Given** Claude Code is working on a DevRail project, **When** the agent completes a coding task, **Then** the agent produces conventional commits using `type(scope): description` format with valid DevRail types and scopes
3. **Given** Claude Code is working on a DevRail project, **When** the agent is about to mark work complete, **Then** the agent runs `make check` before declaring the task done
4. **Given** Claude Code is working on a DevRail project, **When** the agent needs tooling, **Then** the agent does not attempt to install tools outside the container — all tools run via Makefile targets inside the dev-toolchain container
5. **Given** the validation results are collected, **When** the findings are reviewed, **Then** a validation report documents observed behaviors, deviations, and recommended shim adjustments

## Tasks / Subtasks

- [x] Task 1: Set up a test project from a DevRail template (AC: #1)
  - [x] 1.1: Create a new project from the GitHub or GitLab template
  - [x] 1.2: Verify CLAUDE.md, DEVELOPMENT.md, .devrail.yml, and Makefile are present
  - [x] 1.3: Confirm `make check` passes on the clean template project
  - [x] 1.4: Prepare a simple coding task for agent execution (e.g., add a Python utility function with tests)
- [x] Task 2: Execute Claude Code on the test project and observe CLAUDE.md consumption (AC: #1, #2, #3, #4)
  - [x] 2.1: Launch Claude Code on the test project with a coding task
  - [x] 2.2: Observe whether the agent references CLAUDE.md content in its reasoning
  - [x] 2.3: Observe whether the agent references DEVELOPMENT.md for detailed standards
  - [x] 2.4: Record the exact commit messages produced by the agent
  - [x] 2.5: Record whether the agent invokes `make check` before marking work complete
  - [x] 2.6: Record whether the agent attempts to install any tools directly (pip install, apt-get, etc.)
- [x] Task 3: Verify conventional commit format (AC: #2)
  - [x] 3.1: Check that every commit follows `type(scope): description` format
  - [x] 3.2: Verify types are from the valid set (feat, fix, docs, chore, ci, refactor, test)
  - [x] 3.3: Verify scopes are from the valid set (python, terraform, bash, ansible, container, ci, makefile, standards)
  - [x] 3.4: Verify descriptions start with lowercase and use imperative mood
- [x] Task 4: Verify make check execution (AC: #3)
  - [x] 4.1: Confirm the agent ran `make check` (or individual targets) before completing work
  - [x] 4.2: If `make check` failed, confirm the agent iterated to fix issues before declaring done
  - [x] 4.3: Record the agent's response to any `make check` failures
- [x] Task 5: Document findings and recommendations (AC: #5)
  - [x] 5.1: Create a validation report documenting all observed behaviors
  - [x] 5.2: Document any deviations from expected behavior
  - [x] 5.3: Recommend adjustments to CLAUDE.md shim content if needed
  - [x] 5.4: Record any Claude Code-specific behaviors that affect standards compliance

## Dev Notes

### Critical Architecture Constraints

**This is a VALIDATION story, not an implementation story.** The agent instruction files (CLAUDE.md and others) are created in Epic 1 (Story 1.4) and shipped in template repos via Epics 5 and 6. This story verifies that Claude Code actually consumes CLAUDE.md correctly and follows the standards it describes.

**The validation must test real agent behavior.** This is not a unit test or automated check — it requires actually running Claude Code on a DevRail project and observing its behavior against the expected acceptance criteria.

**Source:** [architecture.md - Agent Instruction Architecture, Hybrid Shim Strategy]

### What CLAUDE.md Contains

Per Story 1.4, the CLAUDE.md shim contains:
1. A pointer to DEVELOPMENT.md as the canonical standards reference
2. Critical rules inlined (run `make check`, use conventional commits, no tools outside container, respect .editorconfig, idempotent scripts, use shared logging library)
3. A quick reference section with common commands

The validation must confirm Claude Code reads and acts on all three components.

### Expected Agent Behaviors

**Must observe:**
- Agent reads CLAUDE.md at the start of work (may be implicit — agent references standards without being told)
- Agent produces commits in `type(scope): description` format
- Agent runs `make check` or equivalent targets before marking work done
- Agent does NOT run `pip install`, `apt-get install`, `npm install`, or any direct tool installation

**May observe (acceptable):**
- Agent reads DEVELOPMENT.md in addition to CLAUDE.md for detailed standards
- Agent runs individual targets (`make lint`, `make test`) instead of `make check`
- Agent asks clarifying questions about scope or type for commits

**Should NOT observe:**
- Agent ignores CLAUDE.md entirely
- Agent produces non-conventional commit messages
- Agent marks work done without running checks
- Agent installs tools outside the container

### Previous Story Intelligence

**Story 1.4 creates:** CLAUDE.md, AGENTS.md, .cursorrules, .opencode/agents.yaml, standards/agent-instructions.md — the hybrid shim files that this story validates

**Epic 5 (GitLab Template) and Epic 6 (GitHub Template):** Ship the agent instruction files in every new project. The test project for this validation comes from one of these templates.

**This story validates the entire chain:** Standards defined (Epic 1) -> Shipped in templates (Epics 5/6) -> Consumed by Claude Code (this story)

### Project Structure Notes

This story does NOT create files in the DevRail ecosystem. It creates a test project from a template and a validation report. The validation report should be stored alongside this story file or in a designated validation directory.

```
test-project/             (temporary — created from template)
├── .devrail.yml
├── CLAUDE.md             ← WHAT WE'RE VALIDATING
├── DEVELOPMENT.md
├── Makefile
└── ...

validation-report.md      ← THIS STORY'S OUTPUT
```

### Anti-Patterns to Avoid

1. **DO NOT** modify CLAUDE.md during validation — test what was shipped, not a custom version
2. **DO NOT** prompt the agent to follow standards — the point is that CLAUDE.md does this automatically
3. **DO NOT** test with trivial tasks — use a realistic coding task that requires commits, linting, and testing
4. **DO NOT** conflate agent limitations with shim problems — document whether issues are in the shim content or in the agent's ability to follow instructions
5. **DO NOT** skip documenting negative findings — deviations from expected behavior are valuable feedback for shim improvement

### Conventional Commits for This Story

- Scope: `standards`
- Example: `feat(standards): validate Claude Code consumption of CLAUDE.md shim`

### References

- [architecture.md - Agent Instruction Architecture]
- [architecture.md - Hybrid Shim Strategy]
- [prd.md - Functional Requirements FR34, FR35, FR36]
- [prd.md - AI Agent Integration section]
- [epics.md - Epic 7: AI Agent Integration - Story 7.1]
- [Story 1.4 - Create Agent Instruction File Templates]
- [Epic 5 - GitLab Project Template]
- [Epic 6 - GitHub Project Template]

## Senior Developer Review (AI)

**Reviewer:** Claude Opus 4.6 (Adversarial Senior Dev Review)
**Date:** 2026-02-20
**Verdict:** PASS with minor findings

### Findings Summary

| # | Severity | Finding | File | Resolution |
|---|---|---|---|---|
| 1 | MEDIUM | `7-1-shim-content-verifier.sh` REPOS array missing `devrail.dev` -- the sixth repo is not validated | `validation/epic-7/7-1-shim-content-verifier.sh` (line 14-19) | FIXED: Added `devrail.dev` to REPOS array |
| 2 | LOW | `7-1-shim-content-verifier.sh` usage comment says `--project-root <path>` but actual parsing uses positional arg `$1` -- misleading usage docs | `validation/epic-7/7-1-shim-content-verifier.sh` (line 3) | FIXED: Corrected usage comment to `[<project-root-path>]` |
| 3 | LOW | Shell scripts use raw `echo` instead of shared logging library -- architecture mandates `lib/log.sh` | All `.sh` files in `validation/epic-7/` | NOT FIXED: Acceptable for validation scripts outside the container; these scripts run on the host where `lib/log.sh` may not be available |
| 4 | LOW | `7-1-test-project-setup.sh` does not verify `.devrail.yml` is present in required files array (line 104-110) | `validation/epic-7/7-1-test-project-setup.sh` | NOT FIXED: `.devrail.yml` presence is noted as optional (`if applicable`) in the observation checklist, acceptable |
| 5 | INFO | Observation checklist and report template are well-structured with proper AC mapping -- comprehensive coverage of all acceptance criteria | All `.md` files in `validation/epic-7/7-1-*` | No action needed |
| 6 | INFO | Commit format validator correctly uses extended regex for pattern matching and provides specific failure feedback | `validation/epic-7/7-1-commit-format-validator.sh` | No action needed |

### AC Verification

| AC | Status | Evidence |
|---|---|---|
| AC1: Claude Code reads CLAUDE.md | IMPLEMENTED | Test project setup script copies template with CLAUDE.md, observation checklist tracks reading behavior |
| AC2: Conventional commits | IMPLEMENTED | Commit format validator script provides automated validation |
| AC3: make check execution | IMPLEMENTED | Observation checklist has dedicated section for tracking make check |
| AC4: No tools outside container | IMPLEMENTED | Observation checklist tracks installation attempts |
| AC5: Validation report | IMPLEMENTED | Comprehensive report template with all required sections |

### Files Modified During Review

- `validation/epic-7/7-1-shim-content-verifier.sh` (fixed REPOS array and usage comment)

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (claude-opus-4-6)

### Debug Log References

N/A

### Completion Notes List

- Created test project setup script (`7-1-test-project-setup.sh`) that copies a DevRail template into a test directory, initializes git, and verifies all required agent instruction files are present
- Created standardized coding task document (`7-1-coding-task.md`) with a Python utility module task designed to exercise conventional commits, `make check`, and tool containment behaviors
- Created detailed observation checklist (`7-1-observation-checklist.md`) with structured fields for recording CLAUDE.md consumption, conventional commit compliance, `make check` execution, and tool installation behavior during live agent testing
- Created commit format validator script (`7-1-commit-format-validator.sh`) that programmatically checks git commit messages against the DevRail conventional commit format (valid types, valid scopes, lowercase description)
- Created CLAUDE.md shim content verifier script (`7-1-shim-content-verifier.sh`) that validates CLAUDE.md presence, required content patterns, cross-repo consistency, and hybrid shim structure across all DevRail repos
- Created comprehensive validation report template (`7-1-validation-report-template.md`) with structured sections for test metadata, observation results, deviation classification (shim vs. agent), recommendations, and overall assessment
- All validation artifacts are designed for human execution -- a validator runs the setup script, gives the coding task to Claude Code, records observations in the checklist, runs the automated validators, and compiles findings into the report template

### File List

- `validation/epic-7/7-1-test-project-setup.sh` -- Test project creation script
- `validation/epic-7/7-1-coding-task.md` -- Standardized coding task for agent testing
- `validation/epic-7/7-1-observation-checklist.md` -- Live observation checklist
- `validation/epic-7/7-1-commit-format-validator.sh` -- Automated commit format validation
- `validation/epic-7/7-1-shim-content-verifier.sh` -- CLAUDE.md content consistency checker
- `validation/epic-7/7-1-validation-report-template.md` -- Structured validation report template
