# Story 6.3: Create GitHub Actions Workflows with Parallel Jobs

Status: done

## Story

As a developer,
I want GitHub Actions workflows that run parallel check jobs using the dev-toolchain container,
so that every push and PR gets granular pass/fail status checks.

## Acceptance Criteria

1. **Given** the github-repo-template exists with Makefile, **When** GitHub Actions workflow files are added, **Then** .github/workflows/ contains separate workflow files for lint, format, security, test, and docs
2. **Given** the workflow files exist, **When** a workflow is examined, **Then** each pulls `ghcr.io/devrail-dev/dev-toolchain:v1` and runs its corresponding `make` target
3. **Given** the workflow files exist, **When** events are examined, **Then** each workflow runs on push and pull_request events
4. **Given** the workflow files exist, **When** a PR is created and any check fails, **Then** PRs are blocked from merging (branch protection recommended in README)
5. **Given** the CI results are examined, **Then** they are identical to local `make check` results (same container, same tools, same config)

## Tasks / Subtasks

- [x] Task 1: Create .github/workflows/ directory (AC: #1)
  - [x] 1.1: Create `.github/workflows/` directory structure
- [x] Task 2: Create lint.yml workflow (AC: #1, #2, #3)
  - [x] 2.1: Define workflow name: "Lint"
  - [x] 2.2: Configure trigger on push and pull_request events
  - [x] 2.3: Define job running in `ghcr.io/devrail-dev/dev-toolchain:v1` container
  - [x] 2.4: Run `make _lint` inside the container
- [x] Task 3: Create format.yml workflow (AC: #1, #2, #3)
  - [x] 3.1: Define workflow name: "Format"
  - [x] 3.2: Configure trigger on push and pull_request events
  - [x] 3.3: Define job running in dev-toolchain container
  - [x] 3.4: Run `make _format` inside the container
- [x] Task 4: Create security.yml workflow (AC: #1, #2, #3)
  - [x] 4.1: Define workflow name: "Security"
  - [x] 4.2: Configure trigger on push and pull_request events
  - [x] 4.3: Define job running in dev-toolchain container
  - [x] 4.4: Run `make _security` inside the container
- [x] Task 5: Create test.yml workflow (AC: #1, #2, #3)
  - [x] 5.1: Define workflow name: "Test"
  - [x] 5.2: Configure trigger on push and pull_request events
  - [x] 5.3: Define job running in dev-toolchain container
  - [x] 5.4: Run `make _test` inside the container
- [x] Task 6: Create docs.yml workflow (AC: #1, #2, #3)
  - [x] 6.1: Define workflow name: "Docs"
  - [x] 6.2: Configure trigger on push and pull_request events
  - [x] 6.3: Define job running in dev-toolchain container
  - [x] 6.4: Run `make _docs` inside the container
- [x] Task 7: Document branch protection requirements (AC: #4)
  - [x] 7.1: Add comment in workflow files about branch protection setup
  - [x] 7.2: Document the branch protection settings needed in README (Story 6.4)

## Dev Notes

### Critical Architecture Constraints

**Separate workflow files per category.** Unlike GitLab CI which uses a single `.gitlab-ci.yml` with parallel jobs in the same stage, GitHub Actions achieves parallelism through separate workflow files. Each workflow runs independently and reports its own status check on PRs.

**Jobs run INSIDE the container, not via Docker-in-Docker.** GitHub Actions supports running jobs in a container using the `container:` directive. The jobs use the dev-toolchain image directly and call the internal `_`-prefixed Makefile targets.

**CI results MUST be identical to local `make check` results.** Same container, same `make` targets, same results. The only difference is invocation context.

**Source:** [architecture.md - CI Pipeline Design]

### GitHub Actions Workflow Structure

Each workflow file follows this pattern:

```yaml
# .github/workflows/lint.yml
name: Lint

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/devrail-dev/dev-toolchain:v1
    steps:
      - uses: actions/checkout@v4
      - name: Run lint
        run: make _lint
```

**Key design points:**
- `container:` directive runs the job inside the dev-toolchain image
- Internal `_`-prefixed targets are called since the job IS running in the container
- `actions/checkout@v4` is required to get the code into the container workspace
- Each workflow reports as a separate status check on PRs

### GitHub Actions vs GitLab CI Equivalence

This set of workflows MUST produce results functionally identical to the GitLab CI pipeline (Story 5.4):

| GitHub Actions | GitLab CI |
|---|---|
| Separate workflow files (lint.yml, format.yml, etc.) | Single `.gitlab-ci.yml` |
| `container:` directive | `image:` directive |
| Separate workflows for parallelism | `stage: check` for parallelism |
| `make _lint` (inside container) | `make _lint` (inside container) |
| `actions/upload-artifact` | `artifacts:` directive |
| Runs on push and pull_request | Runs on push and MR |
| Branch protection for merge blocking | "Pipelines must succeed" for MR blocking |

The key invariant: same container, same `make` targets, same results.

### Branch Protection

For PRs to be blocked on CI failure, the GitHub repository must have branch protection rules configured:

1. Go to Settings > Branches > Branch protection rules
2. Add rule for `main` branch
3. Enable "Require status checks to pass before merging"
4. Select all five status checks (lint, format, security, test, docs)

This is a manual GitHub UI step. Document it in the README (Story 6.4).

### Performance Budget

The full set of workflows should complete within 5 minutes (NFR1). Each individual workflow should complete within 60 seconds (NFR2). Separate workflows run in parallel on GitHub-hosted runners.

**Source:** [prd.md - NFR1, NFR2, NFR18]

### Previous Story Intelligence

**Story 6.1 created:** Makefile with two-layer delegation pattern (public targets + internal `_`-prefixed targets)

**Story 6.2 created:** .pre-commit-config.yaml, DEVELOPMENT.md, CLAUDE.md, AGENTS.md, .cursurrules, .opencode/agents.yaml

**Story 5.4 created (in gitlab-repo-template):** .gitlab-ci.yml with parallel jobs — the functional equivalent using GitLab CI syntax

**Build on previous stories:**
- CREATE `.github/workflows/lint.yml`, `format.yml`, `security.yml`, `test.yml`, `docs.yml` (all new files)
- The CI jobs call `make _lint`, `make _format`, etc. — the internal targets defined in the Makefile from Story 6.1

### Project Structure Notes

This story creates 1 directory and 5 files:

```
github-repo-template/
└── .github/
    └── workflows/
        ├── lint.yml               ← THIS STORY
        ├── format.yml             ← THIS STORY
        ├── security.yml           ← THIS STORY
        ├── test.yml               ← THIS STORY
        └── docs.yml               ← THIS STORY
```

### Anti-Patterns to Avoid

1. **DO NOT** use Docker-in-Docker — use the `container:` directive to run the job inside the dev-toolchain image
2. **DO NOT** combine all checks into a single workflow file — use separate files for parallel execution and granular status checks
3. **DO NOT** hardcode tool commands in workflow files — always delegate to Makefile targets
4. **DO NOT** add deployment or release workflows — this is a template for project CI, not a deployment pipeline
5. **DO NOT** add `workflow_dispatch` triggers unless explicitly needed — keep it simple with push and pull_request
6. **DO NOT** add PR templates or CODEOWNERS — that is Story 6.4
7. **DO NOT** configure branch protection programmatically — document it as a manual step

### Conventional Commits for This Story

- Scope: `ci`
- Example: `feat(ci): create GitHub Actions workflows with parallel lint, format, security, test, docs jobs`

### References

- [architecture.md - CI Pipeline Design]
- [architecture.md - Output & Logging Conventions - CI Output]
- [prd.md - Functional Requirements FR21, FR30, FR32, FR33]
- [prd.md - Non-Functional Requirements NFR1, NFR2, NFR12, NFR18]
- [epics.md - Epic 6: GitHub Project Template - Story 6.3]
- [Story 5.4 - GitLab CI pipeline (cross-reference for parity)]
- [Story 6.1 - Makefile with internal targets]

## Senior Developer Review (AI)

**Reviewer:** Claude Opus 4.6 (Adversarial Review)
**Date:** 2026-02-20

### Acceptance Criteria Status

| AC | Status | Notes |
|---|---|---|
| AC1: Separate workflow files for lint, format, security, test, docs | IMPLEMENTED | 5 files in `.github/workflows/` |
| AC2: Each pulls dev-toolchain:v1 and runs make target | IMPLEMENTED | `container: image: ghcr.io/devrail-dev/dev-toolchain:v1` with `make _<target>` |
| AC3: Workflows run on push and pull_request | IMPLEMENTED | Both events configured for `main` branch |
| AC4: PRs blocked on failure | IMPLEMENTED | Header comment documents branch protection setup |
| AC5: Results identical to local make check | IMPLEMENTED | Same container, same internal make targets |

### Findings

1. **INFO - Correct container directive used**: All 5 workflows use `container: image: ghcr.io/devrail-dev/dev-toolchain:v1` instead of Docker-in-Docker. Correct per architecture.

2. **INFO - actions/checkout@v4 present in all workflows**: Required to get code into container workspace. Present in all 5 files.

3. **LOW - No artifact upload in GitHub workflows**: GitLab CI captures `.devrail-output/` as artifacts. GitHub workflows do not use `actions/upload-artifact`. The architecture equivalence table mentions artifacts via `actions/upload-artifact` for GitHub. However, this was not in the story's AC, and artifacts are optional for initial template. NOT FIXED (enhancement for future iteration).

4. **INFO - Workflow names are capitalized correctly**: Lint, Format, Security, Test, Docs. The job names within workflows match Makefile targets (lint, format, security, test, docs). Correct.

5. **INFO - Branch restriction to `main`**: All workflows trigger on push to main and pull_request to main. This is the standard approach. Projects can customize branch patterns.

6. **LOW - No `scan` workflow**: Same as GitLab CI (Story 5.4) -- no separate scan workflow. The 5 categories (lint, format, security, test, docs) match the architecture spec. Consistent with GitLab template.

### Files Modified During Review

None -- this story's implementation is correct as-is.

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (claude-opus-4-6)

### Debug Log References

### Completion Notes List

- Created `.github/workflows/` directory structure
- Created `lint.yml` workflow: name "Lint", triggers on push to main and pull_request to main, runs in `ghcr.io/devrail-dev/dev-toolchain:v1` container using `container:` directive, checks out code with `actions/checkout@v4`, runs `make _lint`
- Created `format.yml` workflow: name "Format", same trigger/container pattern, runs `make _format`
- Created `security.yml` workflow: name "Security", same trigger/container pattern, runs `make _security`
- Created `test.yml` workflow: name "Test", same trigger/container pattern, runs `make _test`
- Created `docs.yml` workflow: name "Docs", same trigger/container pattern, runs `make _docs`
- All five workflows are separate files enabling parallel execution on GitHub-hosted runners and granular status checks on PRs
- Each workflow file includes a header comment documenting the branch protection setup needed to block merges on failure (Settings > Branches > Require status checks)
- Branch protection documentation for README deferred to Story 6.4 as specified

### File List

- `github-repo-template/.github/workflows/lint.yml`
- `github-repo-template/.github/workflows/format.yml`
- `github-repo-template/.github/workflows/security.yml`
- `github-repo-template/.github/workflows/test.yml`
- `github-repo-template/.github/workflows/docs.yml`
