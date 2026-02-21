# Story 7.3 -- BMAD Planning Integration Observation Checklist

## Overview

Use this checklist to evaluate BMAD-generated planning artifacts for DevRail standards integration. The checklist covers three phases: architecture artifact evaluation, story artifact evaluation, and downstream agent consumption testing.

---

## Section 1: Test Setup (Task 1)

- [ ] DevRail reference material prepared (see `7-3-bmad-devrail-context.md`)
- [ ] Project scenario defined (see `7-3-planning-scenario.md`)
- [ ] BMAD planning session initiated with DevRail instructions

**BMAD tool/version used:** ____________
**BMAD agent model:** ____________
**Date of planning session:** ____________

### 1.1 DevRail Context Provided

**How was DevRail context provided to BMAD?**

- [ ] `7-3-bmad-devrail-context.md` provided as reference material
- [ ] Full DEVELOPMENT.md provided
- [ ] architecture.md provided
- [ ] Verbal/text instructions only
- [ ] Other: ____________

**Exact instruction given to BMAD regarding DevRail:**
```
[paste the instruction text]
```

---

## Section 2: Architecture Document Evaluation (Task 1, AC #1)

Evaluate the BMAD-generated architecture document for DevRail references.

### 2.1 Container Reference

- [ ] Architecture mentions `ghcr.io/devrail-dev/dev-toolchain:v1`
- [ ] Architecture mentions dev-toolchain container (generic reference)
- [ ] Architecture mentions container-based tool execution
- [ ] No container reference found

**Evidence:**
```
[paste relevant section]
```

### 2.2 Makefile Contract Reference

- [ ] Architecture mentions `make check` as validation step
- [ ] Architecture mentions specific Makefile targets (make lint, make test, etc.)
- [ ] Architecture mentions Makefile as the developer interface
- [ ] Architecture mentions two-layer delegation pattern
- [ ] No Makefile reference found

**Evidence:**
```
[paste relevant section]
```

### 2.3 Configuration Reference

- [ ] Architecture mentions `.devrail.yml`
- [ ] Architecture mentions `.editorconfig`
- [ ] Architecture mentions `.pre-commit-config.yaml`
- [ ] No configuration file references found

**Evidence:**
```
```

### 2.4 Agent Instruction Files

- [ ] Architecture lists agent instruction files (CLAUDE.md, AGENTS.md, etc.)
- [ ] Architecture includes agent files in project directory structure
- [ ] No agent instruction file references found

**Evidence:**
```
```

### 2.5 Language Tooling

- [ ] Architecture references correct Python tools (ruff, pytest, bandit)
- [ ] Architecture references correct Bash tools (shellcheck, shfmt, bats)
- [ ] Architecture references correct Terraform tools (tflint, terraform fmt, tfsec)
- [ ] Architecture references correct Ansible tools (ansible-lint, molecule)
- [ ] Architecture uses generic/incorrect tool references
- [ ] No language-specific tool references found

**Evidence:**
```
```

### Architecture Evaluation Score

| Reference | Present? | Accurate? |
|---|---|---|
| Dev-toolchain container | [ ] Yes / [ ] No | [ ] Yes / [ ] No / [ ] N/A |
| Makefile contract | [ ] Yes / [ ] No | [ ] Yes / [ ] No / [ ] N/A |
| .devrail.yml | [ ] Yes / [ ] No | [ ] Yes / [ ] No / [ ] N/A |
| Agent instruction files | [ ] Yes / [ ] No | [ ] Yes / [ ] No / [ ] N/A |
| Language tooling | [ ] Yes / [ ] No | [ ] Yes / [ ] No / [ ] N/A |
| Project structure | [ ] Yes / [ ] No | [ ] Yes / [ ] No / [ ] N/A |

---

## Section 3: Epic/Story Artifact Evaluation (Task 2, AC #2, #4)

Evaluate BMAD-generated epics and stories for DevRail compliance requirements.

### 3.1 Sample Stories Evaluated

List the stories you reviewed:

| # | Story Title | Epic |
|---|---|---|
| 1 | | |
| 2 | | |
| 3 | | |
| 4 | | |
| 5 | | |

### 3.2 Acceptance Criteria Evaluation

**Does `make check` appear as a completion gate?**

| Story | `make check` in AC? | How Referenced? |
|---|---|---|
| Story 1 | [ ] Yes / [ ] No | |
| Story 2 | [ ] Yes / [ ] No | |
| Story 3 | [ ] Yes / [ ] No | |
| Story 4 | [ ] Yes / [ ] No | |
| Story 5 | [ ] Yes / [ ] No | |

**Percentage of stories with `make check` as completion gate:** _____%

### 3.3 Dev Notes Evaluation

**Do dev notes reference DevRail conventions?**

| Convention | Referenced in Dev Notes? | How Many Stories? |
|---|---|---|
| Conventional commits | [ ] Yes / [ ] No | ___/__ |
| Container-only tooling | [ ] Yes / [ ] No | ___/__ |
| Script standards (idempotency, logging) | [ ] Yes / [ ] No | ___/__ |
| `.editorconfig` respect | [ ] Yes / [ ] No | ___/__ |
| Pre-commit hooks | [ ] Yes / [ ] No | ___/__ |
| Agent instruction files | [ ] Yes / [ ] No | ___/__ |

### 3.4 Project Structure in Stories

- [ ] Stories include DevRail project structure in notes
- [ ] Stories reference agent instruction files
- [ ] Stories mention `.devrail.yml`
- [ ] No project structure references found

### 3.5 Story Evaluation Score

| Criterion | Present? | Consistent Across Stories? |
|---|---|---|
| `make check` completion gate | [ ] Yes / [ ] No | [ ] Yes / [ ] No |
| Conventional commits in dev notes | [ ] Yes / [ ] No | [ ] Yes / [ ] No |
| Container tooling constraint | [ ] Yes / [ ] No | [ ] Yes / [ ] No |
| Script standards | [ ] Yes / [ ] No | [ ] Yes / [ ] No |
| Agent instruction files | [ ] Yes / [ ] No | [ ] Yes / [ ] No |

---

## Section 4: Downstream Agent Consumption Test (Task 3, AC #3)

Test whether an implementation agent can follow DevRail standards based on BMAD-generated story content alone.

### 4.1 Test Setup

**Implementation agent used:** ____________ (Claude Code or equivalent)
**Story provided:** ____________ (select one BMAD-generated story)
**Date:** ____________

**Was CLAUDE.md / instruction file available?** [ ] Yes / [ ] No
(Ideally test WITHOUT instruction files to isolate BMAD artifact quality)

### 4.2 Agent Behavior Observations

**Did the agent follow DevRail standards based on the BMAD story alone?**

| Standard | Followed Without Additional Prompting? | Evidence |
|---|---|---|
| Conventional commits | [ ] Yes / [ ] No / [ ] Partial | |
| `make check` execution | [ ] Yes / [ ] No / [ ] Partial | |
| Container-only tooling | [ ] Yes / [ ] No / [ ] Partial | |
| Script standards | [ ] Yes / [ ] No / [ ] Partial / [ ] N/A | |

### 4.3 Additional Prompting Needed?

**Did the agent need extra prompting to follow DevRail standards?**

- [ ] No additional prompting needed (ideal)
- [ ] Needed minor clarification on one standard
- [ ] Needed significant prompting for multiple standards
- [ ] Agent did not follow DevRail standards at all

**What prompting was needed?**
```
[describe what additional context was needed]
```

### 4.4 Handoff Gap Analysis

**Standards lost in the BMAD-to-implementation handoff:**

| # | Standard Lost | Was It in the BMAD Story? | Root Cause |
|---|---|---|---|
| 1 | | [ ] Yes / [ ] No | |
| 2 | | [ ] Yes / [ ] No | |
| 3 | | [ ] Yes / [ ] No | |

**Root cause classifications:**
- **Not included by BMAD:** BMAD did not incorporate this standard into the story
- **Included but insufficient:** BMAD mentioned it but without enough detail for the agent
- **Agent limitation:** Standard was present but agent did not follow it

---

## Section 5: Summary Assessment

### 5.1 DevRail Integration Quality

| Phase | Rating | Notes |
|---|---|---|
| Architecture document | [ ] Strong / [ ] Moderate / [ ] Weak / [ ] None | |
| Story acceptance criteria | [ ] Strong / [ ] Moderate / [ ] Weak / [ ] None | |
| Story dev notes | [ ] Strong / [ ] Moderate / [ ] Weak / [ ] None | |
| Downstream agent consumption | [ ] Strong / [ ] Moderate / [ ] Weak / [ ] None | |
| Overall integration | [ ] Strong / [ ] Moderate / [ ] Weak / [ ] None | |

### 5.2 Standards Propagation Scorecard

| DevRail Standard | In Architecture? | In Stories? | Followed by Agent? |
|---|---|---|---|
| `make check` | | | |
| Conventional commits | | | |
| Container-only tooling | | | |
| `.editorconfig` | | | |
| Idempotent scripts | | | |
| Shared logging library | | | |
| Agent instruction files | | | |
| `.devrail.yml` config | | | |

### 5.3 Classification of Issues

| # | Issue | BMAD Capability? | DevRail Communication? | Integration Pattern? |
|---|---|---|---|---|
| 1 | | | | |
| 2 | | | | |

**Classifications:**
- **BMAD capability:** BMAD cannot incorporate this type of context (tool limitation)
- **DevRail communication:** The DevRail context provided was insufficient or unclear
- **Integration pattern:** The way DevRail was presented to BMAD could be improved

---

## Sign-off

**Validator:** ____________
**Date:** ____________
**Verdict:** [ ] Pass / [ ] Partial Pass / [ ] Fail
