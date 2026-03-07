# Story 2.10: Cut Dev-Toolchain Release for Post-v1.5.0 Features

Status: ready-for-dev

## Story

As a maintainer,
I want to cut a proper minor release for all features merged since v1.5.0,
so that the published container image includes Rust, Terragrunt, fix target, pre-push hooks, tool version manifest, and the release script.

## Acceptance Criteria

1. CHANGELOG.md is updated with all [Unreleased] entries under [1.6.0]
2. The tag v1.6.0 is created and pushed
3. GitHub Actions builds and publishes the container image to GHCR
4. The v1 floating tag is updated to point to v1.6.0
5. The GitHub Release is created with release notes
6. The tool version manifest is attached to the release

## Tasks / Subtasks

- [ ] Task 1: Verify CHANGELOG.md is complete (AC: 1)
  - [ ] 1.1 Review [Unreleased] section — ensure all post-v1.5.0 features are documented
  - [ ] 1.2 Features to verify are listed: Rust ecosystem, Terragrunt support, `make fix` target, pre-push hooks, tool version manifest (`report-tool-versions.sh`), `make release` script, critical rule 8 docs
  - [ ] 1.3 Add any missing entries before release

- [ ] Task 2: Run `make check` (AC: 1)
  - [ ] 2.1 Verify all checks pass on current main

- [ ] Task 3: Cut the release (AC: 2, 3, 4, 5, 6)
  - [ ] 3.1 Run `make release VERSION=1.6.0`
  - [ ] 3.2 Confirm push when prompted
  - [ ] 3.3 Verify GitHub Actions build completes successfully
  - [ ] 3.4 Verify container image is published to GHCR with v1.6.0 tag
  - [ ] 3.5 Verify v1 floating tag is updated
  - [ ] 3.6 Verify GitHub Release is created with tool version manifest

## Dev Notes

- `make release VERSION=1.6.0` runs `scripts/release.sh` which handles: semver validation, precondition checks, CHANGELOG update via sed, commit, tag, interactive push confirmation
- The release script was added in the previous session (PR #8, merged)
- Current latest tag is v1.5.0 — all Rust, terragrunt, and other features are merged to main but unreleased
- The weekly cron build bumps patch versions automatically, but feature releases need a deliberate minor bump
- The CHANGELOG [Unreleased] section in the actual repo may be incomplete — need to cross-reference git log since v1.5.0
- After release, the `build.yml` workflow handles: multi-arch build, GHCR publish, cosign signing, floating tag update, release notes, tool version manifest attachment

### Project Structure Notes

- `scripts/release.sh` — the release ceremony script
- `Makefile` — `make release VERSION=x.y.z` target
- `CHANGELOG.md` — must have [Unreleased] section with content
- `.github/workflows/build.yml` — triggered by tag push, handles publishing

### References

- [Source: dev-toolchain/scripts/release.sh] — release script
- [Source: dev-toolchain/Makefile] — release target definition
- [Source: dev-toolchain/DEVELOPMENT.md#Releasing] — release process documentation
- [Source: dev-toolchain/.github/workflows/build.yml] — automated build/publish pipeline
- [Source: epics.md#Story 2.10] — acceptance criteria
- **Depends on:** Story 4.5 (so the pre-commit hook accepts the `release` scope for the release commit)

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
