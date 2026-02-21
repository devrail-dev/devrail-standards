# Story 7.2 -- AGENTS.md Self-Containment Test Procedure

## Purpose

This procedure tests whether AGENTS.md is self-contained: can a generic agent (one without tool-specific instruction file loading) determine all DevRail project conventions, required checks, and commit standards from AGENTS.md alone?

## Test Method

1. Select a generic LLM that does NOT automatically load project files (e.g., ChatGPT, a base Claude API call without CLAUDE.md, or similar)
2. Provide the complete contents of AGENTS.md as system context or user message
3. Ask the agent a series of questions about the project's standards
4. Record whether the agent can answer correctly from AGENTS.md alone

## Test Script

### Step 1: Provide AGENTS.md Context

Paste the full contents of AGENTS.md to the LLM. Prefix with:

> "The following is the AGENTS.md file from a project you are working on. Use it to understand the project's standards and conventions."

### Step 2: Ask Extraction Questions

Ask each question below. Record the agent's answer and whether it is correct.

#### Question 1: Commit Format

> "What format should commit messages follow in this project?"

**Expected answer:** `type(scope): description` format (conventional commits)

**Agent's answer:**
```
```
**Correct?** [ ] Yes / [ ] No / [ ] Partial

---

#### Question 2: Pre-Completion Checks

> "What must I run before marking any task as complete?"

**Expected answer:** `make check`

**Agent's answer:**
```
```
**Correct?** [ ] Yes / [ ] No / [ ] Partial

---

#### Question 3: Tool Installation

> "I need to install ruff for Python linting. How should I do this?"

**Expected answer:** Do NOT install tools directly. All tools are in the dev-toolchain container (`ghcr.io/devrail-dev/dev-toolchain:v1`). Use Makefile targets.

**Agent's answer:**
```
```
**Correct?** [ ] Yes / [ ] No / [ ] Partial

---

#### Question 4: Available Commands

> "What make targets are available in this project?"

**Expected answer:** `make check`, `make help` (at minimum). Full list: `make lint`, `make format`, `make test`, `make security`, `make scan`, `make docs`, `make check`, `make install-hooks`.

**Agent's answer:**
```
```
**Correct?** [ ] Yes / [ ] No / [ ] Partial

---

#### Question 5: Script Writing Standards

> "I need to write a new bash script. What rules should I follow?"

**Expected answer:** Should mention idempotency, shared logging library (`lib/log.sh`), `set -euo pipefail`, no raw echo.

**Agent's answer:**
```
```
**Correct?** [ ] Yes / [ ] No / [ ] Partial

---

#### Question 6: Formatting Rules

> "How do I know what formatting rules to follow (indentation, line endings, etc.)?"

**Expected answer:** Respect `.editorconfig`

**Agent's answer:**
```
```
**Correct?** [ ] Yes / [ ] No / [ ] Partial

---

#### Question 7: Valid Commit Types

> "What are the valid commit types I can use?"

**Expected answer:** The agent should NOT be able to answer this from AGENTS.md alone (AGENTS.md does not list specific types). This tests whether AGENTS.md has a gap.

**Agent's answer:**
```
```
**Could agent answer?** [ ] Yes (gap not present) / [ ] No (gap confirmed) / [ ] Partial

---

#### Question 8: Valid Commit Scopes

> "What are the valid scopes for commit messages?"

**Expected answer:** The agent should NOT be able to answer this from AGENTS.md alone (AGENTS.md does not list specific scopes). This tests whether AGENTS.md has a gap.

**Agent's answer:**
```
```
**Could agent answer?** [ ] Yes (gap not present) / [ ] No (gap confirmed) / [ ] Partial

---

### Step 3: Behavioral Test

Give the agent the standard coding task (from `7-2-coding-task.md`) with AGENTS.md as the only context. Ask:

> "Based on the project standards, write the commit message you would use for adding a new string_helpers module with tests."

**Expected answer:** A message in `type(scope): description` format, e.g., `feat(python): add string helpers utility module`

**Agent's answer:**
```
```
**Follows conventional commit format?** [ ] Yes / [ ] No / [ ] Partial

---

## Results Summary

### Information Extraction Results

| Question | Topic | Answerable from AGENTS.md? | Notes |
|---|---|---|---|
| 1 | Commit format | | |
| 2 | Pre-completion checks | | |
| 3 | Tool installation | | |
| 4 | Available commands | | |
| 5 | Script standards | | |
| 6 | Formatting rules | | |
| 7 | Valid commit types | | |
| 8 | Valid commit scopes | | |

### Self-Containment Assessment

- [ ] **Fully self-contained** -- All critical information is present in AGENTS.md
- [ ] **Mostly self-contained** -- Minor gaps that do not prevent basic compliance
- [ ] **Not self-contained** -- Critical information requires reading DEVELOPMENT.md

### Identified Gaps

| # | Missing Information | Impact | Recommendation |
|---|---|---|---|
| 1 | | | |
| 2 | | | |
| 3 | | | |

### AGENTS.md Improvement Recommendations

| # | Recommendation | Priority |
|---|---|---|
| 1 | | |
| 2 | | |
| 3 | | |
