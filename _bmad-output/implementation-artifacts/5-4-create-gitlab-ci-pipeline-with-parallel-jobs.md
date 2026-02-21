# Story 5.4: Create GitLab CI Pipeline with Parallel Jobs

Status: done

## Story

As a developer,
I want a .gitlab-ci.yml that runs parallel check jobs using the dev-toolchain container,
so that every push and MR gets granular pass/fail feedback.

## Acceptance Criteria

1. **Given** the gitlab-repo-template exists with Makefile, **When** .gitlab-ci.yml is added, **Then** it defines parallel jobs for lint, format, security, test, and docs
2. **Given** the .gitlab-ci.yml exists, **When** a job is examined, **Then** each job pulls `ghcr.io/devrail-dev/dev-toolchain:v1` and runs its corresponding `make` target
3. **Given** the .gitlab-ci.yml exists, **When** job names are examined, **Then** job names match Makefile target names for clear status reporting (lint, format, security, test, docs)
4. **Given** the .gitlab-ci.yml exists, **When** an MR is created and any job fails, **Then** the MR is blocked from merging
5. **Given** the .gitlab-ci.yml exists, **When** code is pushed or an MR is created, **Then** the pipeline runs automatically

## Tasks / Subtasks

- [x] Task 1: Create .gitlab-ci.yml with pipeline structure (AC: #1, #5)
  - [x] 1.1: Define pipeline stages (check)
  - [x] 1.2: Set default image to `ghcr.io/devrail-dev/dev-toolchain:v1`
  - [x] 1.3: Configure pipeline to trigger on push and merge request events
- [x] Task 2: Create parallel jobs for each check category (AC: #2, #3)
  - [x] 2.1: Create `lint` job that runs `make _lint` inside the container
  - [x] 2.2: Create `format` job that runs `make _format` inside the container
  - [x] 2.3: Create `security` job that runs `make _security` inside the container
  - [x] 2.4: Create `test` job that runs `make _test` inside the container
  - [x] 2.5: Create `docs` job that runs `make _docs` inside the container
- [x] Task 3: Configure merge blocking on failure (AC: #4)
  - [x] 3.1: Ensure all jobs are required (not `allow_failure`)
  - [x] 3.2: Document branch protection settings needed in GitLab project settings
- [x] Task 4: Add CI output artifacts
  - [x] 4.1: Configure each job to write JSON output to artifact files
  - [x] 4.2: Set appropriate artifact expiration

## Dev Notes

### Critical Architecture Constraints

**CI is the REMOTE enforcement layer.** While pre-commit hooks (Story 5.2) catch common issues locally, CI runs the full suite including heavy scanning (security, tests) that is too slow for pre-commit.

**CI results MUST be identical to local `make check` results.** Both use the same container image and the same Makefile targets. The only difference is invocation context — CI runs individual jobs in parallel while `make check` runs them sequentially.

**Jobs run INSIDE the container, not via Docker-in-Docker.** Since GitLab CI already runs each job in a container, the jobs use the dev-toolchain image directly and call the internal `_`-prefixed Makefile targets (e.g., `make _lint`), not the public targets that delegate to Docker.

**Source:** [architecture.md - CI Pipeline Design]

### .gitlab-ci.yml Structure

```yaml
# .gitlab-ci.yml — DevRail CI pipeline
# Runs parallel check jobs using the dev-toolchain container.
# Each job matches a Makefile target for consistent local/CI behavior.

image: ghcr.io/devrail-dev/dev-toolchain:v1

stages:
  - check

lint:
  stage: check
  script:
    - make _lint
  artifacts:
    paths:
      - .devrail-output/
    expire_in: 1 week
    when: always

format:
  stage: check
  script:
    - make _format
  artifacts:
    paths:
      - .devrail-output/
    expire_in: 1 week
    when: always

security:
  stage: check
  script:
    - make _security
  artifacts:
    paths:
      - .devrail-output/
    expire_in: 1 week
    when: always

test:
  stage: check
  script:
    - make _test
  artifacts:
    paths:
      - .devrail-output/
    expire_in: 1 week
    when: always

docs:
  stage: check
  script:
    - make _docs
  artifacts:
    paths:
      - .devrail-output/
    expire_in: 1 week
    when: always
```

**Key design points:**
- All jobs are in the same `check` stage so they run in parallel
- Using internal `_`-prefixed targets since the CI runner IS the container
- Artifacts capture JSON output for debugging
- No `allow_failure` — all jobs must pass for MR to be mergeable

### Parallel Execution in GitLab CI

GitLab CI runs all jobs within the same stage in parallel automatically. By placing all check jobs in a single `check` stage, they execute concurrently without additional configuration.

**Performance budget:** The full pipeline should complete within 5 minutes (NFR1). Each individual job should complete within 60 seconds (NFR2).

**Source:** [prd.md - NFR1, NFR2]

### GitLab CI vs GitHub Actions Equivalence

This pipeline MUST produce results functionally identical to the GitHub Actions workflows (Epic 6, Story 6.3):

| GitLab CI | GitHub Actions |
|---|---|
| Single `.gitlab-ci.yml` | Separate workflow files per category |
| `image:` directive | `container:` in job definition |
| `stage: check` for parallelism | Separate workflows for parallelism |
| `make _lint` (inside container) | `make _lint` (inside container) |
| Artifacts via `artifacts:` | Artifacts via `actions/upload-artifact` |

The key invariant: same container, same `make` targets, same results.

**Source:** [architecture.md - CI Pipeline Design]

### GitLab Branch Protection

For MRs to be blocked on CI failure, the GitLab project must have "Pipelines must succeed" enabled in Settings > General > Merge requests. Document this requirement in the README (Story 5.5) or as a comment in .gitlab-ci.yml.

### Previous Story Intelligence

**Story 5.1 created:** Makefile with two-layer delegation pattern (public targets + internal `_`-prefixed targets)

**Story 5.2 created:** .pre-commit-config.yaml

**Story 5.3 created:** DEVELOPMENT.md, CLAUDE.md, AGENTS.md, .cursurrules, .opencode/agents.yaml

**Build on previous stories:**
- CREATE `.gitlab-ci.yml` (new file)
- The CI jobs call `make _lint`, `make _format`, etc. — the internal targets defined in the Makefile from Story 5.1

### Project Structure Notes

This story creates 1 file:

```
gitlab-repo-template/
└── .gitlab-ci.yml            ← THIS STORY
```

### Anti-Patterns to Avoid

1. **DO NOT** use Docker-in-Docker — the CI job IS running in the dev-toolchain container; call internal targets directly
2. **DO NOT** use `allow_failure: true` on any check job — all checks must pass for MR to merge
3. **DO NOT** create separate stages for each job type — use a single `check` stage for parallel execution
4. **DO NOT** hardcode tool commands in .gitlab-ci.yml — always delegate to Makefile targets for consistency with local execution
5. **DO NOT** add deployment or release jobs — this is a template for project CI, not a deployment pipeline
6. **DO NOT** add `only:` or `except:` rules that would skip pipeline runs on push or MR events
7. **DO NOT** add MR templates or CODEOWNERS — that is Story 5.5

### Conventional Commits for This Story

- Scope: `ci`
- Example: `feat(ci): create GitLab CI pipeline with parallel lint, format, security, test, docs jobs`

### References

- [architecture.md - CI Pipeline Design]
- [architecture.md - Output & Logging Conventions - CI Output]
- [prd.md - Functional Requirements FR21, FR31, FR32, FR33]
- [prd.md - Non-Functional Requirements NFR1, NFR2, NFR12, NFR19]
- [epics.md - Epic 5: GitLab Project Template - Story 5.4]
- [Story 5.1 - Makefile with internal targets]
- [Story 6.3 - GitHub Actions equivalent (cross-reference for parity)]

## Senior Developer Review (AI)

**Reviewer:** Claude Opus 4.6 (Adversarial Review)
**Date:** 2026-02-20

### Acceptance Criteria Status

| AC | Status | Notes |
|---|---|---|
| AC1: Parallel jobs for lint, format, security, test, docs | IMPLEMENTED | All 5 jobs in single `check` stage for parallel execution |
| AC2: Jobs pull dev-toolchain:v1 and run make targets | IMPLEMENTED | `image: ghcr.io/devrail-dev/dev-toolchain:v1` at top level, each job calls `make _<target>` |
| AC3: Job names match Makefile targets | IMPLEMENTED | lint, format, security, test, docs -- exact matches |
| AC4: MR blocked on failure | IMPLEMENTED | No `allow_failure` on any job; header comment documents "Pipelines must succeed" setting |
| AC5: Pipeline runs on push and MR | IMPLEMENTED | GitLab CI default behavior; no restrictive only/except rules |

### Findings

1. **INFO - Correct image reference**: `ghcr.io/devrail-dev/dev-toolchain:v1` at the top level, inherited by all jobs. Correct per architecture spec.

2. **INFO - Internal targets correctly used**: All jobs call `make _lint`, `make _format`, etc. (internal targets) since CI IS the container. This avoids Docker-in-Docker. Correct per architecture decision.

3. **LOW - No `scan` job in CI pipeline**: The CI pipeline has lint, format, security, test, docs -- but no `scan` job. The architecture says "Parallel jobs per category -- lint, format, security, test, docs" which matches. The `scan` target (trivy + gitleaks) runs as part of `make check` locally but is not a separate CI job. This is consistent with the story's own AC which only lists these 5. The `security` job covers language-specific scanners; `scan` (trivy/gitleaks) could be added as an enhancement. NOT A DEFECT per story scope.

4. **INFO - Artifacts configured correctly**: Each job captures `.devrail-output/` with `expire_in: 1 week` and `when: always` (captures even on failure). Good for debugging.

5. **INFO - Pipeline structure is clean and minimal**: Single stage, no unnecessary complexity. Matches the architecture principle of simplicity.

### Files Modified During Review

None -- this story's implementation is correct as-is.

## Dev Agent Record

### Agent Model Used
Claude Opus 4.6 (claude-opus-4-6)

### Debug Log References

### Completion Notes List
- Created `.gitlab-ci.yml` with the following structure:
  - Default image set to `ghcr.io/devrail-dev/dev-toolchain:v1`
  - Single `check` stage for parallel execution of all jobs
  - Five parallel jobs: `lint`, `format`, `security`, `test`, `docs` -- job names match Makefile target names
  - Each job calls the internal `_`-prefixed Makefile target (e.g., `make _lint`) since the CI runner IS the container
  - No `allow_failure` on any job -- all checks must pass for MR to merge
  - Each job captures `.devrail-output/` as artifacts with `expire_in: 1 week` and `when: always` for debugging failed jobs
  - Pipeline triggers automatically on push and merge request events (GitLab CI default behavior; no restrictive `only:`/`except:` rules added)
  - Header comment documents the prerequisite to enable "Pipelines must succeed" in GitLab project settings
  - No Docker-in-Docker -- jobs run directly in the dev-toolchain container
  - No deployment or release jobs -- template focuses on project CI checks only

### File List
- `gitlab-repo-template/.gitlab-ci.yml`
