# Story 7.1 -- Claude Code Observation Checklist

## Overview

Use this checklist while observing Claude Code working on the test project. Record each observation as it happens. This checklist maps directly to the acceptance criteria and task subtasks in Story 7.1.

---

## Pre-Test Setup Verification (Task 1)

- [ ] Test project created from DevRail template
- [ ] CLAUDE.md is present and unmodified
- [ ] DEVELOPMENT.md is present and unmodified
- [ ] Makefile is present
- [ ] `.devrail.yml` is present (if applicable)
- [ ] `make check` passes on clean template (or N/A if Makefile is not yet functional)
- [ ] Coding task prepared (see `7-1-coding-task.md`)

**Template used:** ____________
**Date/time of test:** ____________
**Claude Code version:** ____________

---

## Observation 1: CLAUDE.md Consumption (Task 2, AC #1)

Record whether Claude Code reads and references CLAUDE.md content.

### 2.1: Agent reads CLAUDE.md

- [ ] Agent explicitly reads/references CLAUDE.md
- [ ] Agent implicitly follows CLAUDE.md rules (without explicitly mentioning it)
- [ ] Agent ignores CLAUDE.md entirely

**Evidence (paste relevant agent output):**
```
[paste here]
```

### 2.2: Agent references DEVELOPMENT.md

- [ ] Agent reads DEVELOPMENT.md for detailed standards
- [ ] Agent relies only on CLAUDE.md content
- [ ] Agent does not reference either file

**Evidence:**
```
[paste here]
```

### 2.3: Standards awareness demonstrated

- [ ] Agent mentions conventional commits without being prompted
- [ ] Agent mentions `make check` without being prompted
- [ ] Agent mentions container-based tooling without being prompted
- [ ] Agent mentions `.editorconfig` without being prompted
- [ ] Agent mentions idempotent scripts without being prompted
- [ ] Agent mentions shared logging library without being prompted

---

## Observation 2: Conventional Commits (Task 3, AC #2)

Record every commit message produced by the agent.

### Commit Log

| # | Commit Message | Valid Format? | Valid Type? | Valid Scope? | Lowercase Desc? | Imperative Mood? |
|---|---|---|---|---|---|---|
| 1 | | [ ] | [ ] | [ ] | [ ] | [ ] |
| 2 | | [ ] | [ ] | [ ] | [ ] | [ ] |
| 3 | | [ ] | [ ] | [ ] | [ ] | [ ] |
| 4 | | [ ] | [ ] | [ ] | [ ] | [ ] |
| 5 | | [ ] | [ ] | [ ] | [ ] | [ ] |

### Conventional Commit Reference

**Valid types:** `feat`, `fix`, `docs`, `chore`, `ci`, `refactor`, `test`
**Valid scopes:** `python`, `terraform`, `bash`, `ansible`, `container`, `ci`, `makefile`, `standards`
**Format:** `type(scope): description` (description starts lowercase, imperative mood)

### Commit Format Verdict

- [ ] All commits follow conventional format
- [ ] Some commits follow conventional format
- [ ] No commits follow conventional format

**Notes:**
```
[paste observations about commit quality]
```

---

## Observation 3: Make Check Execution (Task 4, AC #3)

Record whether the agent runs `make check` or equivalent targets.

### 4.1: Check execution

- [ ] Agent ran `make check` before completing work
- [ ] Agent ran individual targets (`make lint`, `make test`, etc.) before completing work
- [ ] Agent did NOT run any checks before completing work

**Exact commands observed:**
```
[paste here]
```

### 4.2: Iteration on failures

- [ ] `make check` passed on first run
- [ ] `make check` failed and agent iterated to fix issues
- [ ] `make check` failed and agent did NOT attempt to fix
- [ ] Agent did not run `make check` (N/A)

**Agent response to failures (if any):**
```
[paste here]
```

### 4.3: Check timing

- [ ] Agent ran checks BEFORE committing
- [ ] Agent ran checks AFTER committing
- [ ] Agent ran checks both before and after committing
- [ ] Agent did not run checks

---

## Observation 4: Tool Installation Behavior (AC #4)

Record whether the agent attempts to install tools outside the container.

### 4.1: Tool installation attempts

- [ ] Agent did NOT attempt any direct tool installation (correct behavior)
- [ ] Agent attempted `pip install` directly
- [ ] Agent attempted `apt-get install` directly
- [ ] Agent attempted `npm install` directly
- [ ] Agent attempted `brew install` directly
- [ ] Agent attempted other tool installation: ____________

**Evidence:**
```
[paste here]
```

### 4.2: Container awareness

- [ ] Agent explicitly mentioned using tools via the container/Makefile
- [ ] Agent used `make` targets without mentioning containers
- [ ] Agent was unaware of the container model

---

## Summary Assessment

### Overall Compliance Score

| Criterion | Rating (Pass/Partial/Fail) | Notes |
|---|---|---|
| Reads CLAUDE.md | | |
| References DEVELOPMENT.md | | |
| Conventional commits | | |
| Runs `make check` | | |
| No tool installation outside container | | |
| Overall standards awareness | | |

### Classification of Deviations

For each deviation observed, classify the root cause:

| Deviation | Shim Content Issue? | Agent Capability Limitation? | Notes |
|---|---|---|---|
| | | | |
| | | | |
| | | | |

### Recommended CLAUDE.md Adjustments

1. ____________
2. ____________
3. ____________

### Additional Observations

```
[free-form notes about agent behavior, surprises, patterns]
```

---

## Sign-off

**Validator:** ____________
**Date:** ____________
**Verdict:** [ ] Pass / [ ] Partial Pass / [ ] Fail
