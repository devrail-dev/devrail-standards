# Story 7.2 -- Multi-Tool Observation Checklist

## Overview

Complete one copy of Section 2 (Per-Tool Observations) for EACH tool tested. Use the SAME test project and SAME coding task for all tools to ensure fair comparison. This checklist directly maps to the acceptance criteria and tasks in Story 7.2.

---

## Section 1: Test Setup (Task 1)

- [ ] Test project created from DevRail template (specify: github / gitlab)
- [ ] Sample codebase included (Python + Bash)
- [ ] All agent instruction files verified present:
  - [ ] CLAUDE.md
  - [ ] AGENTS.md
  - [ ] .cursorrules
  - [ ] .opencode/agents.yaml
  - [ ] DEVELOPMENT.md
- [ ] `make check` passes on clean project (or N/A)
- [ ] Standardized coding task prepared (see `7-2-coding-task.md`)

**Template used:** ____________
**Test date range:** ____________

---

## Section 2: Per-Tool Observations

### Instructions

Copy this entire section for each tool tested. Fill in the tool name at the top.

---

### Tool: ________________________

**Tool version:** ____________
**Instruction file tested:** [ ] .cursorrules / [ ] .opencode/agents.yaml / [ ] AGENTS.md
**Date/time of test:** ____________

#### 2.1 Instruction File Consumption

**Did the tool read its instruction file?**

- [ ] Yes, explicitly (tool mentioned the file or its contents)
- [ ] Yes, implicitly (tool followed rules without mentioning the file)
- [ ] No / Unclear (tool did not appear to read the file)
- [ ] Not tested (tool unavailable)

**Evidence:**
```
[paste relevant tool output]
```

#### 2.2 Conventional Commits

**Did the tool produce conventional commits?**

- [ ] All commits follow `type(scope): description` format
- [ ] Some commits follow the format
- [ ] No commits follow the format
- [ ] Tool did not make commits

**Commit messages observed:**

| # | Commit Message | Valid? |
|---|---|---|
| 1 | | |
| 2 | | |
| 3 | | |

**Validator output (`7-1-commit-format-validator.sh`):**
```
[paste output]
```

#### 2.3 Make Check Execution

**Did the tool run `make check`?**

- [ ] Ran `make check` before completing
- [ ] Ran individual make targets
- [ ] Did not run any checks
- [ ] Not observed

**Commands observed:**
```
[paste commands]
```

#### 2.4 Tool Installation Behavior

**Did the tool attempt to install tools outside the container?**

- [ ] No direct tool installation (correct)
- [ ] Attempted tool installation (deviation)
- [ ] Not observed

**If yes, what was attempted?**
```
[paste commands]
```

#### 2.5 DEVELOPMENT.md References

**Did the tool reference DEVELOPMENT.md?**

- [ ] Yes, read DEVELOPMENT.md
- [ ] No, relied only on its instruction file
- [ ] Not observed

#### 2.6 Tool-Specific Observations

**Unique behaviors or limitations:**
```
[free-form notes]
```

#### 2.7 Per-Tool Verdict

| Criterion | Rating |
|---|---|
| Reads instruction file | [ ] Pass / [ ] Partial / [ ] Fail / [ ] Not tested |
| Conventional commits | [ ] Pass / [ ] Partial / [ ] Fail / [ ] Not tested |
| Runs make check | [ ] Pass / [ ] Partial / [ ] Fail / [ ] Not tested |
| No tool installation | [ ] Pass / [ ] Partial / [ ] Fail / [ ] Not tested |
| Overall compliance | [ ] Pass / [ ] Partial / [ ] Fail / [ ] Not tested |

---

## Section 3: AGENTS.md Self-Containment Test (Task 4, AC #3)

This is a separate test from the per-tool observations above. It validates that AGENTS.md is self-contained.

### 3.1 Test Setup

**Method:** Provide AGENTS.md content to a generic LLM (one without tool-specific instruction file loading)

**LLM used:** ____________
**Date:** ____________

### 3.2 Information Extraction Test

Can the agent determine the following from AGENTS.md alone (without reading DEVELOPMENT.md)?

| Information | Determinable from AGENTS.md? | Notes |
|---|---|---|
| Conventional commit format | [ ] Yes / [ ] No / [ ] Partial | |
| Valid commit types | [ ] Yes / [ ] No / [ ] Partial | |
| Valid commit scopes | [ ] Yes / [ ] No / [ ] Partial | |
| `make check` requirement | [ ] Yes / [ ] No / [ ] Partial | |
| Container-only tooling rule | [ ] Yes / [ ] No / [ ] Partial | |
| `.editorconfig` respect | [ ] Yes / [ ] No / [ ] Partial | |
| Idempotent scripts | [ ] Yes / [ ] No / [ ] Partial | |
| Shared logging library | [ ] Yes / [ ] No / [ ] Partial | |
| Available make targets | [ ] Yes / [ ] No / [ ] Partial | |
| Container image reference | [ ] Yes / [ ] No / [ ] Partial | |

### 3.3 Self-Containment Gaps

**Items where AGENTS.md references DEVELOPMENT.md for critical information that should be inlined:**

| # | Missing Information | Currently In | Recommendation |
|---|---|---|---|
| 1 | | | |
| 2 | | | |
| 3 | | | |

### 3.4 AGENTS.md Verdict

- [ ] **Self-contained** -- All critical information is present in AGENTS.md
- [ ] **Mostly self-contained** -- Minor gaps, agent can still comply
- [ ] **Not self-contained** -- Critical information requires reading DEVELOPMENT.md

---

## Section 4: Summary

### Quick Comparison Matrix

| Criterion | Cursor | OpenCode | AGENTS.md (generic) | Claude Code (from 7.1) |
|---|---|---|---|---|
| Reads instruction file | | | | |
| Conventional commits | | | | |
| Runs make check | | | | |
| No tool installation | | | | |
| References DEVELOPMENT.md | | | | |
| Overall | | | | |

### Tools Not Tested

| Tool | Reason |
|---|---|
| | |

---

## Sign-off

**Validator:** ____________
**Date:** ____________
