---
date: '2026-04-28'
author: Matthew (with BMad Master)
status: pending-approval
trigger_story: '13.1'
scope: Moderate
---

# Sprint Change Proposal — Epic 13 Expansion (Plugin Architecture Implementation)

## Section 1 — Issue Summary

Story 13.1 ("Design Plugin Architecture for Community Extensions") was a design-only deliverable that produced `_bmad-output/planning-artifacts/plugin-architecture-design.md` (610 lines, merged 2026-04-27). Its output explicitly enumerates implementation work in three phases — `v1.10.0` plugin loader, `v1.11.0` reference plugin extraction, `v2.0.0` monolithic-block retirement — plus seven open-question follow-ups.

**The problem:** none of that work exists in the backlog. Epic 13 has only one story (13-1, now in `review`); `epics.md` has no Epic 13 section at all (it stops at Epic 9 + post-MVP backlog stories 4.5 and 2.10); and `sprint-status.yaml` lists `epic-13: in-progress` with only `13-1-design-plugin-architecture: review`. Running `create-story` halts with "no backlog stories found", because there literally are none.

**Discovery:** surfaced when invoking `/bmad-bmm-create-story` immediately after merging Story 13.1 — the workflow's auto-discovery returned no candidates.

**Evidence:**
- `create-story` workflow output: "No backlog stories found in sprint-status.yaml"
- `epics.md` line 173 ("## Epic List") through line 922 ("## Backlog — Post-MVP Stories") covers only Epics 1–9 + Stories 4.5 and 2.10. No Epic 13.
- `sprint-status.yaml` lines 132–134 show Epic 13 with a single story.
- `plugin-architecture-design.md` §"Migration Path" (lines 410+) explicitly enumerates v1.10.0 / v1.11.0 / v2.0.0 work; §"Open Questions" (lines 484+) lists 7 deferred items.

## Section 2 — Impact Analysis

**Epic Impact**

- **Epic 13 (current epic, in-progress):** scope expands from one design story to ten total stories. Epic objective and acceptance criteria do not change — the design simply revealed the implementation work the epic always implied.
- **No other active epics:** Epics 1–12 and 14 are `done`. No downstream ripple.
- **No new epics needed:** v2.0.0 retirement work stays in Epic 13 (still plugin architecture). Open-question follow-ups can be Epic 15 ("Plugin Ecosystem Hardening") in the future if many materialize, but premature now.

**Story Impact**

| Story | Change |
|---|---|
| 13.1 | No change (in `review`, design merged) |
| 13.2 – 13.6 | **New** — v1.10.0 implementation work, BDD AC drafted in `epics.md` |
| 13.7, 13.8 | **New (placeholder)** — v1.11.0 reference plugin extraction; AC firms up after v1.10.0 |
| 13.9 | **New (placeholder)** — v2.0.0 monolith retirement; major version bump |
| 13.10 | **New (placeholder)** — Plugin signing follow-up; lowest priority |

**Artifact Conflicts**

| Artifact | Conflict | Action |
|---|---|---|
| PRD | None — Phase 3 already lists "Plugin/extension architecture" (line 297) | No edit |
| `architecture.md` | Predates the design; zero "plugin" mentions | Pointer subsection added under "Core Architectural Decisions" |
| `epics.md` | No Epic 13 section | Backfilled with full Epic 13 + 10 story summaries |
| `sprint-status.yaml` | Epic 13 had only one story | 9 new `backlog` story lines added |
| UX docs | N/A — tooling project, no UX | None |
| dev-toolchain code | None at correction time | Modified during implementation stories (13.2+), not during this correction |

**Technical Impact**

- **No code changes** in this correction. Pure planning artifact updates.
- Future implementation work (Stories 13.2–13.6) will touch `dev-toolchain/Makefile`, `dev-toolchain/Dockerfile`, `standards/devrail-yml-schema.md`, `standards/contributing.md`, and `devrail.dev/content/blog/` — all anticipated by the design doc.

## Section 3 — Recommended Approach

**Selected: Option 1 — Direct Adjustment.**

**Rationale:**
- *Direct Adjustment* fits cleanly: add new stories under an in-progress epic, no rework.
- *Rollback* is N/A — Story 13.1 was successful and design-only; nothing to revert.
- *MVP Review* is N/A — MVP shipped 2026-03-08 (45/45 stories done); this is post-MVP Phase 3 work explicitly anticipated by the PRD.

**Effort estimate:** Medium for this correction (~6 documents touched, fully drafted in-session). Implementation stories themselves are a multi-release effort across `v1.10.0` → `v1.11.0` → `v2.0.0`.

**Risk:** Low for the correction (planning artifacts only). Implementation risk is bounded by the design doc's three-phase migration, which is explicitly back-compat through `v1.x`.

**Timeline impact:** Zero on the existing release schedule — this *is* the schedule for Phase 3.

## Section 4 — Detailed Change Proposals

### 4.1 Architecture pointer

`_bmad-output/planning-artifacts/architecture.md`

Inserted a 5-line "Plugin Architecture (Phase 3)" subsection under "Core Architectural Decisions", pointing to `plugin-architecture-design.md` and noting the three-phase rollout. Additive only.

### 4.2 Epic 13 backfill

`_bmad-output/planning-artifacts/epics.md`

Appended a complete "## Epic 13: Plugin Architecture for Community Extensions" section with epic goal, migration strategy, and all ten story entries (13.1 reference + 13.2–13.6 with full BDD AC + 13.7–13.10 as elaboration-pending placeholders). Each story is anchored to a phase and a depends-on chain.

### 4.3 Sprint-status entries

`_bmad-output/implementation-artifacts/sprint-status.yaml`

Added 9 `backlog` story lines under `epic-13:` in the order matching the depends-on chain, before `epic-13-retrospective: optional`.

```yaml
  epic-13: in-progress
  13-1-design-plugin-architecture: review
  13-2-implement-plugin-manifest-parser-and-loader: backlog
  13-3-implement-plugin-resolver-and-lockfile: backlog
  13-4-implement-extended-image-build-pipeline: backlog
  13-5-implement-plugin-execution-loop-and-json-aggregation: backlog
  13-6-cut-v1-10-0-release-with-plugin-loader: backlog
  13-7-extract-kotlin-as-reference-plugin: backlog
  13-8-cut-v1-11-0-release-with-reference-plugin-extraction-recipe: backlog
  13-9-retire-monolithic-has-lang-blocks: backlog
  13-10-plugin-signing: backlog
  epic-13-retrospective: optional
```

### 4.4 Story files (deferred to `create-story`)

Story files for 13.2–13.10 are intentionally not generated in this correction. The `create-story` workflow does deeper per-story analysis (architecture trace, previous-story intelligence, web research) than this workflow can replicate. Each `backlog` story will be picked up by `create-story` in order when ready to work.

## Section 5 — Implementation Handoff

**Scope classification:** **Moderate** — backlog reorganization needed; no fundamental replan required.

**Routing:**

- **Scrum Master / dev workflow** — pick up Story 13.2 next via `/bmad-bmm-create-story` (it will auto-select the first `backlog` entry in epic-13).
- **Dev team** — implement Stories 13.2–13.5 in dependency order; each is a `dev-story` cycle with `code-review`. Bundle releases through Story 13.6 (`v1.10.0` cut).
- **PM / Architect** — re-engage at the v1.11.0 boundary (after Story 13.6 ships) to validate the Kotlin extraction approach against real-world community feedback before continuing to Stories 13.7+.

**Deliverables produced by this workflow:**

- ✅ Sprint Change Proposal document (this file)
- ✅ Architecture pointer subsection added
- ✅ Epic 13 backfilled in `epics.md` with 10 story summaries
- ✅ 9 new `backlog` entries in `sprint-status.yaml`

**Success criteria:**

- `create-story` auto-selects Story 13.2 on next invocation (no more "no backlog stories" halt)
- A future reader entering through `architecture.md` is led to `plugin-architecture-design.md`
- A future reader entering through `epics.md` finds Epic 13 documented with the same fidelity as Epics 1–9

**Approval pending** — see Step 5 of the correct-course workflow.
