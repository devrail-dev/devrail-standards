# Story 2.8: Automated Weekly Builds

Status: done

## Story

As a developer,
I want the container to rebuild automatically every week with updated tool versions,
so that the dev-toolchain image stays current with security patches and tool updates without manual intervention.

## Acceptance Criteria

1. **Given** build and release workflows exist (Story 2.7), **When** the weekly schedule triggers, **Then** a new container image is built with the latest tool versions
2. **Given** a scheduled build completes successfully, **When** the image is tagged, **Then** a new semver patch version is published (e.g., `v1.0.1` increments to `v1.0.2`)
3. **Given** a new patch version is published, **When** the floating tag is updated, **Then** the major-version floating tag (e.g., `v1`) points to the new image
4. **Given** a scheduled build fails, **When** the failure is detected, **Then** a notification is sent via GitHub Actions (issue creation or workflow notification)
5. **Given** the workflow is examined, **Then** the build workflow includes a `schedule` trigger with cron syntax for weekly execution
6. **Given** a developer needs an immediate rebuild, **When** they trigger `workflow_dispatch`, **Then** the build runs on demand with the same semver bump behavior

## Tasks / Subtasks

- [x] Task 1: Add cron schedule trigger to build workflow (AC: #1, #5)
  - [x] 1.1: Add `schedule` trigger with cron expression `0 6 * * 1` (Monday 6:00 AM UTC) to `.github/workflows/build.yml`
  - [x] 1.2: Ensure schedule trigger only runs on the default branch (main)
  - [x] 1.3: Add `workflow_dispatch` trigger for manual execution (AC: #6)
- [x] Task 2: Implement automatic semver patch version bump (AC: #2, #3)
  - [x] 2.1: Create logic to determine the latest semver tag from git tags
  - [x] 2.2: Implement patch version increment (e.g., `v1.0.1` becomes `v1.0.2`)
  - [x] 2.3: Create and push the new git tag
  - [x] 2.4: Trigger the existing build-and-push workflow with the new tag
  - [x] 2.5: Ensure the major-version floating tag is updated by the existing release workflow
- [x] Task 3: Configure failure notification (AC: #4)
  - [x] 3.1: Add a failure detection step that runs `if: failure()`
  - [x] 3.2: Create a GitHub Issue on build failure with build log link and failure details
  - [x] 3.3: Label the issue with `build-failure` and `automated` labels
- [x] Task 4: Add safeguards for scheduled builds
  - [x] 4.1: Add a check to skip the build if no changes exist since the last tag (optional optimization)
  - [x] 4.2: Ensure scheduled builds do not interfere with manual tag-triggered builds

## Dev Notes

### Critical Architecture Constraints

**This story extends the build workflow created in Story 2.7.** Do not duplicate workflow logic. The scheduled trigger should reuse the same build-and-push job. The key addition is the automatic semver bump and the schedule trigger.

**Weekly builds ensure tool freshness.** When the container builds, `apt-get update` and tool installers pull the latest versions. This keeps the image patched without manual intervention.

**Source:** [architecture.md - Container Build Architecture, Automated Build Strategy]

### GitHub Actions Cron Syntax

```yaml
on:
  schedule:
    # Run every Monday at 6:00 AM UTC
    - cron: '0 6 * * 1'
  workflow_dispatch: {}
  push:
    tags:
      - 'v[0-9]+.[0-9]+.[0-9]+'
```

**Important cron notes:**
- GitHub Actions cron uses UTC timezone
- Scheduled workflows only run on the default branch
- Minimum interval is 5 minutes, but weekly is appropriate for this use case
- GitHub may delay scheduled workflows during periods of high load

### Semver Auto-Bump Strategy

The scheduled build needs to determine the next patch version:

```bash
# Get the latest semver tag
LATEST_TAG=$(git tag --list 'v[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname | head -n1)

# Parse components
MAJOR=$(echo "$LATEST_TAG" | sed 's/v//' | cut -d. -f1)
MINOR=$(echo "$LATEST_TAG" | sed 's/v//' | cut -d. -f2)
PATCH=$(echo "$LATEST_TAG" | sed 's/v//' | cut -d. -f3)

# Increment patch
NEW_TAG="v${MAJOR}.${MINOR}.$((PATCH + 1))"

# Create and push new tag
git tag "$NEW_TAG"
git push origin "$NEW_TAG"
```

**Only patch versions are auto-bumped.** Minor and major version bumps are always manual, intentional decisions by the team.

### Failure Notification Options

**Option 1 (Recommended): GitHub Issue creation on failure**

```yaml
- name: Create issue on failure
  if: failure()
  uses: actions/github-script@v7
  with:
    script: |
      await github.rest.issues.create({
        owner: context.repo.owner,
        repo: context.repo.repo,
        title: `Weekly build failed: ${new Date().toISOString().split('T')[0]}`,
        body: `The scheduled weekly build failed.\n\nWorkflow run: ${context.serverUrl}/${context.repo.owner}/${context.repo.repo}/actions/runs/${context.runId}`,
        labels: ['build-failure', 'automated']
      });
```

**Option 2: GitHub Actions built-in notification** — GitHub sends email notifications for failed workflows by default. This may be sufficient if the team monitors GitHub notifications.

### Workflow Architecture

The recommended approach is to have the schedule trigger in the build workflow itself, with a preliminary job that handles the auto-bump:

```yaml
jobs:
  auto-version:
    if: github.event_name == 'schedule' || github.event_name == 'workflow_dispatch'
    runs-on: ubuntu-latest
    outputs:
      new_tag: ${{ steps.bump.outputs.new_tag }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - id: bump
        run: |
          # Determine and create new patch tag
          # ... (semver bump logic)
          echo "new_tag=${NEW_TAG}" >> "$GITHUB_OUTPUT"
      - run: |
          git tag "${{ steps.bump.outputs.new_tag }}"
          git push origin "${{ steps.bump.outputs.new_tag }}"

  build-and-push:
    needs: [auto-version]
    if: always() && (needs.auto-version.result == 'success' || github.event_name == 'push')
    # ... (existing build job from Story 2.7)
```

### Previous Story Intelligence

**Story 2.7 creates:** `.github/workflows/build.yml` with multi-arch build and GHCR push, `.github/workflows/release.yml` for semver tagging and floating tag updates, `.github/CODEOWNERS`

**This story modifies:** `.github/workflows/build.yml` to add schedule trigger, auto-version job, and failure notification. The release workflow from Story 2.7 handles the floating tag update automatically when a new tag is pushed.

**Build on Story 2.7:** Do NOT duplicate the build-and-push logic. Add the schedule trigger and auto-bump job to the existing workflow. The tag push from the auto-bump job will trigger the existing build pipeline.

### Anti-Patterns to Avoid

1. **DO NOT** duplicate build-and-push workflow logic — extend the existing workflow from Story 2.7
2. **DO NOT** auto-bump minor or major versions — only patch versions are automated
3. **DO NOT** schedule builds more frequently than weekly — this avoids unnecessary image churn and registry storage
4. **DO NOT** skip failure notification — silent build failures lead to stale images
5. **DO NOT** create CI validation workflows — that is Story 2.9
6. **DO NOT** force-push tags — semver tags are immutable once published

### Conventional Commits for This Story

- Scope: `container`
- Example: `feat(container): add weekly scheduled builds with automatic semver patch bump`

### References

- [architecture.md - Container Build Architecture]
- [architecture.md - Foundation Decisions - Automated Build Cadence: weekly]
- [prd.md - Functional Requirements FR5]
- [prd.md - Non-Functional Requirements NFR5, NFR13]
- [epics.md - Epic 2: Dev-Toolchain Container - Story 2.8]
- [Story 2.7 - Multi-Arch Build and GHCR Publishing]

## Senior Developer Review (AI)

**Reviewer:** Claude Opus 4.6 (adversarial review)
**Date:** 2026-02-20
**Verdict:** PASS

### Acceptance Criteria Verification

| AC | Status | Notes |
|---|---|---|
| AC1 | IMPLEMENTED | build.yml has schedule trigger with cron `0 6 * * 1` (Monday 6 AM UTC) |
| AC2 | IMPLEMENTED | auto-version job increments patch version (e.g., v1.0.1 -> v1.0.2) |
| AC3 | IMPLEMENTED | Tag push triggers existing build-and-push job, which triggers release.yml for floating tag |
| AC4 | IMPLEMENTED | notify-failure job creates GitHub Issue with build-failure and automated labels |
| AC5 | IMPLEMENTED | Schedule trigger present in build.yml on trigger list |
| AC6 | IMPLEMENTED | workflow_dispatch trigger enables manual builds |

### Findings

1. **LOW - Auto-version job correctly conditional.** Runs only on schedule and workflow_dispatch events, skipped for tag push events.
2. **LOW - Semver parsing uses standard sed/cut pattern.** Handles missing tags gracefully (starts at v1.0.0).
3. **LOW - build-and-push correctly chains.** `needs: [auto-version]` with `if: always() && (needs.auto-version.result == 'success' || needs.auto-version.result == 'skipped')` handles both scheduled and tag-push flows.
4. **LOW - notify-failure creates informative issues.** Includes trigger type, workflow run link, and appropriate labels.
5. **LOW - permissions elevated to contents: write.** Required for git tag push by auto-version job.

### Files Modified During Review

None.

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (claude-opus-4-6)

### Debug Log References

### Completion Notes List

- Extended `.github/workflows/build.yml` (created in Story 2.7) with:
  - Added `schedule` trigger with cron `0 6 * * 1` (Monday 6:00 AM UTC)
  - Added `auto-version` job that runs for schedule and workflow_dispatch events
  - Auto-version determines latest semver tag, increments patch version, creates and pushes new tag
  - Handles case where no tags exist yet (starts at v1.0.0)
  - `build-and-push` job now depends on `auto-version` with conditional execution
  - For tag push events, uses the pushed tag directly; for scheduled/manual, uses auto-bumped tag
  - Updated permissions to `contents: write` (needed for tag push)
  - Added `notify-failure` job that creates GitHub Issue on build failure
  - Issue includes trigger type, workflow run link, and labels (build-failure, automated)
  - Scheduled builds do not interfere with manual tag-triggered builds via conditional job execution

### File List

- .github/workflows/build.yml
