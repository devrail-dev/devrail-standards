# Release & Versioning

Release management and versioning standards for DevRail-managed repositories. These complement the [Git Workflow](git-workflow.md) and [Conventional Commits](../DEVELOPMENT.md#conventional-commits) standards.

## Semantic Versioning

All DevRail-managed projects follow [Semantic Versioning 2.0.0](https://semver.org/):

```
MAJOR.MINOR.PATCH
```

### When to Bump

| Component | When | Example |
|---|---|---|
| **MAJOR** | Breaking changes that require consumers to modify their code or configuration | Removing a public API endpoint, changing a CLI flag's behavior, dropping support for a platform |
| **MINOR** | New functionality that is backward-compatible | Adding a new API endpoint, new CLI command, new optional configuration field |
| **PATCH** | Backward-compatible bug fixes | Fixing incorrect output, correcting error handling, patching a security vulnerability |

### Rules

1. **Never break backward compatibility without a major version bump.** If in doubt, it is a breaking change.
2. **`0.x.y` versions have no stability guarantee.** Breaking changes may occur in minor releases during initial development. Once `1.0.0` is released, semver rules are strictly enforced.
3. **Version numbers only increase.** Never re-use a version number, even if the release was yanked or retracted.
4. **Changelogs drive version decisions.** Review the changelog generated from conventional commits to determine the correct bump level.

## Tagging

### Tag Format

```
vX.Y.Z
```

Always prefix with `v`. Examples: `v1.0.0`, `v2.3.1`, `v0.5.0-rc.1`.

### Tag Rules

1. **Use annotated tags.** Annotated tags include the tagger, date, and message. Lightweight tags are not permitted for releases.

   ```bash
   git tag -a v1.2.0 -m "Release v1.2.0"
   ```

2. **Tag from `main` only.** Release tags must point to commits on the default branch. Never tag a feature branch.
3. **Never move or delete a published tag.** Once a tag is pushed, it is immutable. If a release is defective, create a new patch release.
4. **Tag after merge, not before.** The tagged commit must be the final, reviewed, CI-passing commit on `main`.

## Release Process

### Standard Release

1. **Review the changelog.** Verify that all changes since the last release are captured. Confirm the version bump level (major, minor, patch).
2. **Create the tag.** Use an annotated tag on the `main` branch.
3. **Push the tag.** `git push origin vX.Y.Z`. CI should trigger the release pipeline.
4. **Create the platform release.** GitHub Release or GitLab Release with:
   - Release title: `vX.Y.Z`
   - Body: changelog entries since the previous release
   - Attach build artifacts if applicable (binaries, container images, packages)
5. **Verify the release.** Confirm artifacts are published, container images are pushed, packages are available.

### Automated Releases

Where possible, automate the release process through CI:

- Tag push triggers the release pipeline
- Changelog is auto-generated from conventional commits
- Artifacts are built and attached automatically
- Platform release is created by CI (using `gh release create` or GitLab release API)

## Hotfix Workflow

When a critical bug or security vulnerability is found in a released version:

1. **Branch from the release tag.** `git checkout -b fix/critical-bug vX.Y.Z`
2. **Fix and test.** Apply the minimum change needed. Run `make check`.
3. **Open a PR to `main`.** Follow the normal review process.
4. **Merge and tag.** After merge, tag the new patch release: `vX.Y.(Z+1)`.
5. **Release.** Follow the standard release process.

If the fix cannot cleanly merge to `main` (e.g., `main` has diverged significantly), cherry-pick the fix onto `main` separately and ensure both the release and `main` are patched.

## Pre-release Versions

Use pre-release identifiers for versions that are not yet stable:

| Type | Format | Example |
|---|---|---|
| Release candidate | `vX.Y.Z-rc.N` | `v1.0.0-rc.1` |
| Beta | `vX.Y.Z-beta.N` | `v1.0.0-beta.1` |
| Alpha | `vX.Y.Z-alpha.N` | `v1.0.0-alpha.1` |

### Rules

- Pre-release versions have **lower precedence** than the associated release (`v1.0.0-rc.1` < `v1.0.0`)
- Increment the numeric suffix for successive pre-releases: `rc.1`, `rc.2`, `rc.3`
- Pre-release tags follow the same rules as release tags (annotated, from `main` or a release branch, immutable)
- Do not publish pre-release artifacts to production registries unless clearly marked

## Library vs Service Versioning

### Libraries

Libraries **must** follow semver strictly. Consumers depend on version ranges, and breaking those guarantees causes cascading failures:

- Every public API change must be reflected in the version number
- Deprecation warnings must precede removal by at least one minor release
- Lock files in consuming projects pin exact versions; semver correctness determines upgrade safety

### Services

Services have more flexibility because they do not have external API consumers in the same way:

- **Semver** is recommended for services with public APIs (REST, gRPC, CLI tools)
- **Date-based versioning** (`YYYY.MM.DD` or `YYYY.MM.N`) is acceptable for internal services, dashboards, or applications where the concept of "breaking change" is less meaningful
- Whichever scheme is chosen, apply it consistently within the project

## Changelog

### Format

Follow [Keep a Changelog](https://keepachangelog.com/):

```markdown
## [1.2.0] - 2026-02-25

### Added
- New `--format` flag for CLI output (#45)

### Fixed
- Correct exit code when no files are found (#42)

### Changed
- Minimum Python version is now 3.11 (#44)
```

### Rules

1. **Auto-generate from conventional commits.** Use tooling to generate the changelog from commit history. Manual entries are allowed for additional context.
2. **Group by type.** `Added`, `Fixed`, `Changed`, `Removed`, `Deprecated`, `Security`.
3. **Link to issues/PRs.** Every entry references the relevant issue or PR number.
4. **One changelog per repo.** `CHANGELOG.md` at the repository root.

## Notes

- Version bumps are determined by the nature of the changes, not by time elapsed or number of commits.
- For monorepos with multiple independently versioned packages, each package maintains its own version and changelog.
- The release process should be documented in the project's `CONTRIBUTING.md` or `DEVELOPMENT.md` if it deviates from the standard workflow described here.
