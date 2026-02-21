# Story 2.7: Multi-Arch Build and GHCR Publishing

Status: done

## Story

As a developer,
I want the container to build for amd64 and arm64 and publish to GHCR with semver + major-version floating tags,
so that all team members can pull a consistent, versioned image regardless of their host architecture.

## Acceptance Criteria

1. **Given** the Dockerfile and all install scripts are complete, **When** the build workflow runs, **Then** the image is built for linux/amd64 and linux/arm64
2. **Given** a multi-arch build completes, **When** the image is pushed, **Then** it is published to `ghcr.io/devrail-dev/dev-toolchain` with an exact semver tag (e.g., `v1.0.0`)
3. **Given** a new semver tag is pushed, **When** the release workflow runs, **Then** the major-version floating tag (e.g., `v1`) is updated to point to the new image
4. **Given** the workflows are examined, **Then** `.github/workflows/build.yml` defines the build and push process using `docker buildx`
5. **Given** the workflows are examined, **Then** `.github/workflows/release.yml` handles semver tagging and major-version floating tag updates

## Tasks / Subtasks

- [x] Task 1: Create `.github/workflows/build.yml` for multi-arch build and push (AC: #1, #2, #4)
  - [x] 1.1: Set up workflow triggers (push to main, tag push matching `v*`)
  - [x] 1.2: Configure `docker/setup-buildx-action` for multi-platform builds
  - [x] 1.3: Configure `docker/setup-qemu-action` for arm64 emulation on amd64 runners
  - [x] 1.4: Authenticate to GHCR using `GITHUB_TOKEN` via `docker/login-action`
  - [x] 1.5: Build with `docker/build-push-action` targeting `linux/amd64,linux/arm64`
  - [x] 1.6: Push image with exact semver tag extracted from the git tag
  - [x] 1.7: Add `org.opencontainers.image.*` labels (source, description, version, licenses)
- [x] Task 2: Create `.github/workflows/release.yml` for semver and floating tag management (AC: #3, #5)
  - [x] 2.1: Trigger on successful completion of build workflow (or on tag push)
  - [x] 2.2: Parse the semver tag to extract the major version number
  - [x] 2.3: Update the major-version floating tag (e.g., `v1`) to point to the new image manifest
  - [x] 2.4: Create a GitHub Release with auto-generated release notes
- [x] Task 3: Create `.github/CODEOWNERS` for workflow review gating
  - [x] 3.1: Add CODEOWNERS entry for `.github/` directory
- [x] Task 4: Configure GHCR authentication and permissions (AC: #2)
  - [x] 4.1: Set `permissions: packages: write` in workflow
  - [x] 4.2: Ensure `GITHUB_TOKEN` has access to push to `ghcr.io`
  - [x] 4.3: Set package visibility to public (or document manual step)

## Dev Notes

### Critical Architecture Constraints

**This story creates the publishing pipeline for the dev-toolchain container.** The build workflow defined here is extended by Story 2.8 (weekly scheduled builds) and the CI workflow is added in Story 2.9. Design the workflow to be modular enough for reuse.

**Multi-arch is mandatory.** Team members use both Intel and Apple Silicon machines. The image MUST be a multi-arch manifest supporting `linux/amd64` and `linux/arm64`.

**Source:** [architecture.md - Container Build Architecture, Publishing Strategy]

### Docker Buildx Commands Reference

The build workflow should use GitHub Actions with established Docker actions rather than raw CLI commands:

```yaml
# Key actions to use:
- docker/setup-qemu-action@v3      # ARM64 emulation
- docker/setup-buildx-action@v3    # Buildx builder
- docker/login-action@v3           # GHCR auth
- docker/metadata-action@v5        # Tag/label generation
- docker/build-push-action@v6      # Multi-arch build+push
```

Equivalent raw CLI (for understanding — prefer the Actions above):

```bash
# Create builder
docker buildx create --name devrail-builder --use

# Build and push multi-arch
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag ghcr.io/devrail-dev/dev-toolchain:v1.0.0 \
  --tag ghcr.io/devrail-dev/dev-toolchain:v1 \
  --push .
```

### GHCR Authentication

GHCR authentication uses the built-in `GITHUB_TOKEN`:

```yaml
- name: Log in to GHCR
  uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

The workflow needs `permissions: packages: write` to push images. The `GITHUB_TOKEN` is automatically available in GitHub Actions — no manual secret creation required.

### Semver Tagging Strategy

**Exact semver tag:** `v1.0.0`, `v1.0.1`, `v1.1.0`, etc. These are immutable — once pushed, never overwritten.

**Major-version floating tag:** `v1` always points to the latest `v1.x.x` release. This is the tag consumers should reference in their `.devrail.yml` or Makefile:

```makefile
DEVRAIL_IMAGE ?= ghcr.io/devrail-dev/dev-toolchain
DEVRAIL_TAG ?= v1
```

The `docker/metadata-action` can handle this automatically:

```yaml
- name: Extract metadata
  uses: docker/metadata-action@v5
  with:
    images: ghcr.io/devrail-dev/dev-toolchain
    tags: |
      type=semver,pattern={{version}}
      type=semver,pattern={{major}}
```

### GitHub Actions Workflow Structure

```yaml
# .github/workflows/build.yml
name: Build and Publish Container
on:
  push:
    tags:
      - 'v[0-9]+.[0-9]+.[0-9]+'
  workflow_dispatch: {}

permissions:
  contents: read
  packages: write

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-qemu-action@v3
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/metadata-action@v5
        id: meta
        with:
          images: ghcr.io/devrail-dev/dev-toolchain
          tags: |
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}
      - uses: docker/build-push-action@v6
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### `.github/` Directory Structure

```
.github/
├── CODEOWNERS
└── workflows/
    ├── build.yml       <-- THIS STORY
    ├── release.yml     <-- THIS STORY
    └── ci.yml          <-- Story 2.9
```

### Previous Story Intelligence

**Story 2.1 creates:** Dockerfile skeleton, lib/log.sh, lib/platform.sh, Makefile, agent instruction files, `.devrail.yml`

**Stories 2.2-2.6 create:** Per-language install scripts (python, bash, terraform, ansible, universal security) that are invoked during `docker build`

**This story requires:** A complete, buildable Dockerfile. All install scripts from Stories 2.2-2.6 must be in place for the image to build successfully. However, the workflow files themselves can be written and committed before the install scripts exist.

### Anti-Patterns to Avoid

1. **DO NOT** use Docker Hub — all images publish to GHCR (`ghcr.io`) only
2. **DO NOT** skip multi-arch — both `linux/amd64` and `linux/arm64` are required
3. **DO NOT** hardcode image versions or tags in the workflow — use `docker/metadata-action` to derive from git tags
4. **DO NOT** use personal access tokens for GHCR auth — use the built-in `GITHUB_TOKEN`
5. **DO NOT** create CI validation workflows — that is Story 2.9
6. **DO NOT** add scheduled/cron triggers — that is Story 2.8

### Conventional Commits for This Story

- Scope: `container`
- Example: `feat(container): add multi-arch build workflow and GHCR publishing`

### References

- [architecture.md - Container Build Architecture]
- [architecture.md - Publishing Strategy]
- [architecture.md - Foundation Decisions - Container Tagging: major-version floating tag]
- [prd.md - Functional Requirements FR5, FR7]
- [prd.md - Non-Functional Requirements NFR5, NFR8]
- [epics.md - Epic 2: Dev-Toolchain Container - Story 2.7]
- [Stories 2.1-2.6 - Dockerfile and install scripts]

## Senior Developer Review (AI)

**Reviewer:** Claude Opus 4.6 (adversarial review)
**Date:** 2026-02-20
**Verdict:** PASS

### Acceptance Criteria Verification

| AC | Status | Notes |
|---|---|---|
| AC1 | IMPLEMENTED | build.yml targets linux/amd64,linux/arm64 via docker/build-push-action |
| AC2 | IMPLEMENTED | Image pushed to ghcr.io/devrail-dev/dev-toolchain with semver tag |
| AC3 | IMPLEMENTED | release.yml updates major-version floating tag (e.g., v1) via force-push |
| AC4 | IMPLEMENTED | .github/workflows/build.yml uses docker buildx with QEMU for arm64 |
| AC5 | IMPLEMENTED | .github/workflows/release.yml handles semver tagging and GitHub Release creation |

### Findings

1. **LOW - Proper use of Docker GitHub Actions.** Uses setup-qemu-action@v3, setup-buildx-action@v3, login-action@v3, metadata-action@v5, build-push-action@v6. All pinned to major versions.
2. **LOW - GHA cache enabled.** `cache-from: type=gha` and `cache-to: type=gha,mode=max` for efficient layer caching.
3. **LOW - GHCR auth uses GITHUB_TOKEN.** No personal access tokens. Workflow has `packages: write` permission.
4. **LOW - release.yml creates GitHub Release with cosign verify documentation.** Release body includes docker pull commands for both exact and floating tags, plus cosign verification instructions.
5. **LOW - CODEOWNERS correctly gates .github/, Dockerfile, and lib/ directories.** @devrail-dev/maintainers team required for review.
6. **LOW - Major version tag force-push in release.yml.** Correctly uses `git tag -f` and `git push --force` for floating tag updates.

### Files Modified During Review

None.

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (claude-opus-4-6)

### Debug Log References

### Completion Notes List

- Created `.github/workflows/build.yml` with multi-arch build and GHCR push
  - Triggers on semver tag push (v*.*.* pattern) and workflow_dispatch
  - Uses docker/setup-qemu-action for ARM64 emulation
  - Uses docker/setup-buildx-action for multi-platform builds
  - Authenticates to GHCR via GITHUB_TOKEN
  - docker/metadata-action generates semver (exact) and major (floating) tags
  - docker/build-push-action builds for linux/amd64,linux/arm64
  - GHA cache-from/cache-to for build layer caching
  - OCI labels for source, description, licenses
- Created `.github/workflows/release.yml` for GitHub Release creation
  - Triggers on semver tag push
  - Extracts version components from tag
  - Creates GitHub Release with auto-generated release notes and image pull instructions
  - Force-updates major version git tag (e.g., v1) to point to latest release
- Created `.github/CODEOWNERS` with entries for .github/, Dockerfile, and lib/ directories

### File List

- .github/workflows/build.yml
- .github/workflows/release.yml
- .github/CODEOWNERS
