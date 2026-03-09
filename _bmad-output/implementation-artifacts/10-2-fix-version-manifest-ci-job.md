# Story 10.2: Fix Version-Manifest CI Job for Releases

Status: review

## Story

As a maintainer,
I want the version-manifest CI job to generate and attach a tool version report to each GitHub release,
so that users can see exactly which tool versions are included in each container image.

## Acceptance Criteria

1. The `version-manifest` job in `build.yml` runs successfully on tag pushes
2. The tool version manifest (markdown file) is attached as an asset to the GitHub release
3. The manifest includes versions for all tools across all 8 language ecosystems
4. The devrail.dev versions page is updated (if auto-generated from release assets)

## Tasks / Subtasks

- [x] Task 1: Investigate why the version-manifest job was skipped in v1.6.0 (AC: 1)
  - [x] 1.1 Review `build.yml` workflow to understand the version-manifest job's trigger conditions
  - [x] 1.2 Check the v1.6.0 build run logs for the version-manifest job
  - [x] 1.3 Identify the root cause (conditional gate, dependency, permissions, or other)

- [x] Task 2: Fix the version-manifest job (AC: 1, 2)
  - [x] 2.1 Apply the fix based on root cause analysis
  - [x] 2.2 Verify the fix doesn't break other jobs in the build pipeline

- [x] Task 3: Verify the manifest content (AC: 3)
  - [x] 3.1 Run `scripts/report-tool-versions.sh` locally inside the container to validate output
  - [x] 3.2 Confirm all 8 language ecosystems are represented
  - [x] 3.3 Confirm Terragrunt version is included

- [x] Task 4: Verify devrail.dev versions page (AC: 4)
  - [x] 4.1 Check if the devrail.dev site has automation to pull version manifests from releases
  - [x] 4.2 If automated, verify it picks up the new release asset
  - [x] 4.3 If manual, update the versions page content

## Dev Notes

- The `version-manifest` job was added as part of the tool version manifest feature (Story 2.9 / PR #4)
- The job ran for 0 seconds in the v1.6.0 build — likely skipped by a conditional
- `scripts/report-tool-versions.sh` is the script that generates the manifest inside the container
- The devrail.dev site had a PR (#5) for `/docs/container/versions/` with CI-generated markdown
- The build workflow is at `dev-toolchain/.github/workflows/build.yml`

### References

- [Source: dev-toolchain/.github/workflows/build.yml] — build and release pipeline
- [Source: dev-toolchain/scripts/report-tool-versions.sh] — version manifest generator
- [Source: devrail.dev PR #5] — versions page on documentation site

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6

### Debug Log References

- v1.6.0 build run showed version-manifest job completed in 0s (skipped)
- `docker run ghcr.io/devrail-dev/dev-toolchain:1.6.0 bash /opt/devrail/scripts/report-tool-versions.sh` — produced valid JSON with 38 tools across 8 ecosystems

### Completion Notes List

- **Root cause**: GitHub Actions transitive `needs` chain skip behavior. When `auto-version` job is skipped (tag push trigger), downstream jobs inherit the skip even through intermediate jobs that use `always()`. The `version-manifest` job had `needs: [build-and-push]` but its `if` condition (`startsWith(github.ref, 'refs/tags/v')`) wasn't enough — GitHub's default behavior skips jobs when any ancestor in the needs chain was skipped.
- **Fix**: Changed `version-manifest` job's `if` from `startsWith(github.ref, 'refs/tags/v')` to `always() && needs.build-and-push.result == 'success' && startsWith(github.ref, 'refs/tags/v')`. The `always()` function overrides the default skip behavior, and the explicit success check ensures it only runs when the build actually succeeded.
- **Manifest verification**: `report-tool-versions.sh` produces valid JSON output with all 8 language ecosystems (Python, Bash, Terraform, Ansible, Ruby, Go, JavaScript/TypeScript, Rust) plus universal security tools and Terragrunt.
- **Devrail.dev versions page**: Already working — `update-versions.yml` workflow runs on `release: published` events and creates PRs to update the versions page. PR #12 was merged to fix org-level Actions permissions that were blocking this.
- **Note**: The `:v1` floating tag appears stale (different image ID from `:1.6.0`). This is caused by the `docker/metadata-action` `v{{major}}` pattern producing `:v1` tag (with v prefix) while `build-and-push` also produces `:1.6.0` (without v prefix). This is a separate issue — the floating tag works correctly, it just may not have been updated for v1.6.0 specifically.

### File List

- `dev-toolchain/.github/workflows/build.yml` — fixed `version-manifest` job `if` condition (line 123)
- PR: https://github.com/devrail-dev/dev-toolchain/pull/10
