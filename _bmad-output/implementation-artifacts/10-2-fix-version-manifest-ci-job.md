# Story 10.2: Fix Version-Manifest CI Job for Releases

Status: ready-for-dev

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

- [ ] Task 1: Investigate why the version-manifest job was skipped in v1.6.0 (AC: 1)
  - [ ] 1.1 Review `build.yml` workflow to understand the version-manifest job's trigger conditions
  - [ ] 1.2 Check the v1.6.0 build run logs for the version-manifest job
  - [ ] 1.3 Identify the root cause (conditional gate, dependency, permissions, or other)

- [ ] Task 2: Fix the version-manifest job (AC: 1, 2)
  - [ ] 2.1 Apply the fix based on root cause analysis
  - [ ] 2.2 Verify the fix doesn't break other jobs in the build pipeline

- [ ] Task 3: Verify the manifest content (AC: 3)
  - [ ] 3.1 Run `scripts/report-tool-versions.sh` locally inside the container to validate output
  - [ ] 3.2 Confirm all 8 language ecosystems are represented
  - [ ] 3.3 Confirm Terragrunt version is included

- [ ] Task 4: Verify devrail.dev versions page (AC: 4)
  - [ ] 4.1 Check if the devrail.dev site has automation to pull version manifests from releases
  - [ ] 4.2 If automated, verify it picks up the new release asset
  - [ ] 4.3 If manual, update the versions page content

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

### Debug Log References

### Completion Notes List

### File List
