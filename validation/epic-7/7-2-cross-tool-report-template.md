# Story 7.2 -- Cross-Tool Agent Instruction Validation Report

## Test Metadata

| Field | Value |
|---|---|
| Story | 7.2 -- Validate Multi-Tool Agent Instruction Consumption |
| Date Range | YYYY-MM-DD to YYYY-MM-DD |
| Validator | [name] |
| Template Used | [github / gitlab] |
| Test Project Location | [path] |

---

## 1. Test Setup (Task 1)

### 1.1 Test Project

**Source template:** [github-repo-template / gitlab-repo-template]

**Setup method:** `7-2-test-project-setup.sh`

**Sample codebase included:** [ ] Yes / [ ] No

### 1.2 Agent Instruction Files Verification

| File | Present? | Content Valid? |
|---|---|---|
| CLAUDE.md | [ ] Yes / [ ] No | [ ] Yes / [ ] No |
| AGENTS.md | [ ] Yes / [ ] No | [ ] Yes / [ ] No |
| .cursorrules | [ ] Yes / [ ] No | [ ] Yes / [ ] No |
| .opencode/agents.yaml | [ ] Yes / [ ] No | [ ] Yes / [ ] No |
| DEVELOPMENT.md | [ ] Yes / [ ] No | [ ] Yes / [ ] No |
| Makefile | [ ] Yes / [ ] No | [ ] Yes / [ ] No |

**`7-2-instruction-file-verifier.sh` output:**
```
[paste summary]
```

### 1.3 Clean Project Validation

**`make check` result:** [ ] Pass / [ ] Fail / [ ] N/A

### 1.4 Coding Task

**Task used:** See `7-2-coding-task.md` (identical to 7-1 for cross-comparison)

---

## 2. Cursor Validation (Task 2, AC #1)

### 2.1 Test Configuration

| Field | Value |
|---|---|
| Cursor Version | |
| AI Model Used | |
| Date of Test | |
| Project Reset Before Test? | [ ] Yes / [ ] No |

### 2.2 .cursorrules Consumption

**Did Cursor read .cursorrules?**
- [ ] Yes, explicitly
- [ ] Yes, implicitly (followed rules without mentioning file)
- [ ] No / Unclear
- [ ] Not tested (Cursor unavailable)

**Evidence:**
```
```

### 2.3 Standards Compliance

| Standard | Observed? | Evidence |
|---|---|---|
| Conventional commits | [ ] Yes / [ ] No / [ ] Partial | |
| Runs `make check` | [ ] Yes / [ ] No | |
| No tool installation outside container | [ ] Yes / [ ] No | |
| References DEVELOPMENT.md | [ ] Yes / [ ] No | |

### 2.4 Commit Messages

| # | Message | Valid Format? |
|---|---|---|
| 1 | | |
| 2 | | |
| 3 | | |

### 2.5 Cursor-Specific Observations

```
[free-form notes about Cursor-specific behaviors or limitations]
```

### 2.6 Cursor Verdict

[ ] Pass / [ ] Partial Pass / [ ] Fail / [ ] Not Tested

---

## 3. OpenCode Validation (Task 3, AC #2)

### 3.1 Test Configuration

| Field | Value |
|---|---|
| OpenCode Version | |
| AI Model Used | |
| Date of Test | |
| Project Reset Before Test? | [ ] Yes / [ ] No |

### 3.2 agents.yaml Consumption

**Did OpenCode read .opencode/agents.yaml?**
- [ ] Yes, explicitly
- [ ] Yes, implicitly (followed rules without mentioning file)
- [ ] No / Unclear
- [ ] Not tested (OpenCode unavailable)

**Evidence:**
```
```

### 3.3 Standards Compliance

| Standard | Observed? | Evidence |
|---|---|---|
| Conventional commits | [ ] Yes / [ ] No / [ ] Partial | |
| Runs `make check` | [ ] Yes / [ ] No | |
| No tool installation outside container | [ ] Yes / [ ] No | |
| References DEVELOPMENT.md | [ ] Yes / [ ] No | |

### 3.4 Commit Messages

| # | Message | Valid Format? |
|---|---|---|
| 1 | | |
| 2 | | |
| 3 | | |

### 3.5 OpenCode-Specific Observations

```
[free-form notes about OpenCode-specific behaviors or limitations]
```

### 3.6 OpenCode Verdict

[ ] Pass / [ ] Partial Pass / [ ] Fail / [ ] Not Tested

---

## 4. AGENTS.md Self-Containment Validation (Task 4, AC #3)

### 4.1 Test Configuration

| Field | Value |
|---|---|
| Generic LLM Used | |
| Date of Test | |
| Method | Provide AGENTS.md as context, ask extraction questions |

### 4.2 Self-Containment Results

**See `7-2-agents-md-self-containment-test.md` for full procedure.**

| Information | Extractable from AGENTS.md? |
|---|---|
| Conventional commit format | [ ] Yes / [ ] No / [ ] Partial |
| Valid commit types | [ ] Yes / [ ] No / [ ] Partial |
| Valid commit scopes | [ ] Yes / [ ] No / [ ] Partial |
| `make check` requirement | [ ] Yes / [ ] No / [ ] Partial |
| Container-only tooling | [ ] Yes / [ ] No / [ ] Partial |
| `.editorconfig` respect | [ ] Yes / [ ] No / [ ] Partial |
| Script idempotency | [ ] Yes / [ ] No / [ ] Partial |
| Shared logging library | [ ] Yes / [ ] No / [ ] Partial |

### 4.3 Self-Containment Gaps

| # | Missing Information | Impact | Should Inline? |
|---|---|---|---|
| 1 | | | |
| 2 | | | |

### 4.4 AGENTS.md Verdict

[ ] Self-contained / [ ] Mostly self-contained / [ ] Not self-contained

---

## 5. Cross-Tool Comparison (Task 5, AC #4, #5)

### 5.1 Behavioral Comparison Matrix

| Criterion | Claude Code (7.1) | Cursor | OpenCode | AGENTS.md (generic) |
|---|---|---|---|---|
| Reads instruction file | | | | |
| Conventional commits | | | | |
| Runs `make check` | | | | |
| No tool installation | | | | |
| References DEVELOPMENT.md | | | | |
| Overall compliance | | | | |

### 5.2 Common Patterns (What All Tools Get Right)

1. ____________
2. ____________
3. ____________

### 5.3 Divergences (Where Tools Differ)

| # | Divergence | Affected Tools | Root Cause |
|---|---|---|---|
| 1 | | | |
| 2 | | | |
| 3 | | | |

### 5.4 Deviation Classification (AC #5)

| # | Deviation | Shim Content Issue? | Tool Capability Limitation? | Affected Tools | Recommendation |
|---|---|---|---|---|---|
| 1 | | [ ] | [ ] | | |
| 2 | | [ ] | [ ] | | |
| 3 | | [ ] | [ ] | | |

**Classification criteria:**
- **Shim content issue:** The instruction file content could be improved to prevent this deviation. Fix is in DevRail.
- **Tool capability limitation:** The tool cannot follow this instruction regardless of content. Fix is in the tool (not DevRail).

### 5.5 Per-Tool Shim Adjustment Recommendations

#### CLAUDE.md (for Claude Code)

| # | Recommendation | Priority | Rationale |
|---|---|---|---|
| 1 | | | |

#### .cursorrules (for Cursor)

| # | Recommendation | Priority | Rationale |
|---|---|---|---|
| 1 | | | |

#### .opencode/agents.yaml (for OpenCode)

| # | Recommendation | Priority | Rationale |
|---|---|---|---|
| 1 | | | |

#### AGENTS.md (for generic agents)

| # | Recommendation | Priority | Rationale |
|---|---|---|---|
| 1 | | | |

---

## 6. Overall Assessment

### Verdict

[ ] **PASS** -- All tools read their instruction files and follow DevRail standards
[ ] **PARTIAL PASS** -- Most tools comply; documented deviations are minor or tool-limited
[ ] **FAIL** -- Significant gaps in agent instruction consumption across tools

### Confidence Level

[ ] **High** -- All tools tested with clear evidence
[ ] **Medium** -- Some tools tested; others documented as not tested
[ ] **Low** -- Insufficient testing completed

### Key Findings

1. ____________
2. ____________
3. ____________

### Top Priority Shim Improvements

1. ____________
2. ____________
3. ____________

---

## Appendix

### A. Raw Observation Checklists

[Attach or reference completed `7-2-observation-checklist.md` copies]

### B. Instruction File Verifier Output

```
[paste full 7-2-instruction-file-verifier.sh output]
```

### C. Commit Format Validator Outputs (Per Tool)

**Cursor:**
```
```

**OpenCode:**
```
```
