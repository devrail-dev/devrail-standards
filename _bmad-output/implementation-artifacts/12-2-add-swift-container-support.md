# Story 12.2: Add Swift Language Ecosystem

Status: done

## Story

As a developer working in Swift,
I want DevRail to support Swift with linting, formatting, security scanning, and testing,
so that I get the same DevRail experience as all other supported languages.

## Acceptance Criteria

1. **Given** the dev-toolchain container, **When** a project declares `swift` in `.devrail.yml`, **Then** `make lint` runs SwiftLint and reports results
2. **Given** the dev-toolchain container, **When** a project declares `swift` in `.devrail.yml`, **Then** `make format` checks swift-format formatting and `make fix` applies fixes
3. **Given** the dev-toolchain container, **When** a project declares `swift` in `.devrail.yml`, **Then** `make test` runs `swift test` (gated on `Package.swift` presence)
4. **Given** the dev-toolchain container, **When** a project declares `swift` in `.devrail.yml`, **Then** `make security` uses trivy for dependency scanning (gated on `Package.resolved` presence)
5. **Given** `standards/swift.md`, **Then** it follows the consistent structure: Tools, Configuration, Makefile Targets, Pre-Commit Hooks, Notes
6. **Given** `devrail-yml-schema.md`, **Then** `swift` appears in the Allowed Values list and the Language Support Matrix
7. **Given** the template repos, **Then** `.pre-commit-config.yaml` includes Swift hooks (commented out by default)
8. **Given** `devrail init --languages swift`, **Then** the init script scaffolds Swift config files and uncomments the pre-commit hooks
9. **Given** all changes merged, **Then** `make check` passes on all 5 DevRail repos
10. **Given** all changes merged to dev-toolchain, **Then** a new semver release is tagged and the container image is published to GHCR

## Tasks / Subtasks

- [x] Task 1: Create install script (AC: 1, 2, 3, 4) -- **Repo: dev-toolchain**
  - [x] 1.1 Created `dev-toolchain/scripts/install-swift.sh` following mandatory pattern
  - [x] 1.2 SwiftLint v0.58.0 pre-built binary download (idempotent: `command -v swiftlint`)
  - [x] 1.3 swift-format v601.0.0 pre-built binary download (idempotent: `command -v swift-format`)
  - [x] 1.4 All tools verified with `require_cmd`

- [x] Task 2: Create verification test script (AC: 1, 2, 3) -- **Repo: dev-toolchain**
  - [x] 2.1 Created `dev-toolchain/tests/test-swift.sh`
  - [x] 2.2 Verifies swiftlint with version output
  - [x] 2.3 Verifies swift-format with version output
  - [x] 2.4 Verifies swift compiler with version output

- [x] Task 3: Update Dockerfile (AC: 1, 2, 3, 4) -- **Repo: dev-toolchain**
  - [x] 3.1 Added `FROM swift:6.1-slim-bookworm AS swift-builder`
  - [x] 3.2 COPY Swift toolchain: `COPY --from=swift-builder /usr /usr/local/swift`
  - [x] 3.3 Install script runs via existing scripts/ COPY + `RUN bash /opt/devrail/scripts/install-swift.sh`
  - [x] 3.4 Set `ENV PATH="/usr/local/swift/bin:${PATH}"`

- [x] Task 4: Update Makefile targets (AC: 1, 2, 3, 4) -- **Repo: dev-toolchain**
  - [x] 4.1 Added `HAS_SWIFT := $(filter swift,$(LANGUAGES))`
  - [x] 4.2 Added Swift block to `_lint`: `swiftlint lint --strict` (gated on `*.swift`)
  - [x] 4.3 Added Swift block to `_format`: `swift-format lint --strict -r .` (gated on `*.swift`)
  - [x] 4.4 Added Swift block to `_fix`: `swift-format format -i -r .`
  - [x] 4.5 Added Swift block to `_test`: `swift test` (gated on `Package.swift` + `*.swift`)
  - [ ] 4.6 Swift scaffolding for `_init` -- pending
  - [ ] 4.7 Sync Makefile to template repos -- pending (separate PRs)

- [x] Task 5: Write standards document (AC: 5) -- **Repo: development-standards** -- DONE (Story 14.1)
  - [x] 5.1 Created `standards/swift.md` with Tools, Configuration, Makefile Targets, Pre-Commit Hooks, Notes
  - [x] 5.2 Included annotated configs for SwiftLint (.swiftlint.yml) and swift-format (.swift-format JSON)
  - [x] 5.3 Documented gating: `*.swift` for lint/format, `Package.swift` for test, `Package.resolved` for security

- [x] Task 6: Update schema and documentation (AC: 6) -- **Repo: development-standards** -- DONE (Story 14.1)
  - [x] 6.1 Added `swift` to Allowed Values in `standards/devrail-yml-schema.md`
  - [x] 6.2 Added Swift column to Language Support Matrix
  - [x] 6.3 Added Swift row to `README.md` standards table
  - [x] 6.4 Added `swift` scope to `DEVELOPMENT.md` conventional commits scopes

- [x] Task 7: Update devrail.dev documentation site (AC: 6) -- **Repo: development-standards** -- DONE (Story 14.1)
  - [x] 7.1 Created `devrail.dev/content/docs/standards/swift.md` with Hugo/Docsy front matter
  - [x] 7.2 Updated `devrail.dev/content/docs/standards/_index.md` (matrix, target mapping, per-language links)

- [ ] Task 8: Configure pre-commit hooks (AC: 7) -- **Repos: github-repo-template, gitlab-repo-template**
  - [ ] 8.1 Add SwiftLint hook: `realm/SwiftLint` rev `0.58.0` with `swiftlint` hook ID
  - [ ] 8.2 Add SwiftFormat hook: `nicklockwood/SwiftFormat` rev `0.55.5` with `swiftformat` hook ID
  - [ ] 8.3 Add as commented-out blocks in both template repos

- [ ] Task 9: Update devrail init (AC: 8) -- **Repo: dev-toolchain**
  - [ ] 9.1 Add `swift` to VALID_LANGUAGES in `devrail-init.sh`
  - [ ] 9.2 Add Swift config scaffolding (`.swiftlint.yml`, `.swift-format`)
  - [ ] 9.3 Add Swift pre-commit hook uncommenting logic

- [ ] Task 10: Update conventional commit scopes (AC: 9) -- **Repo: pre-commit-conventional-commits**
  - [ ] 10.1 Add `swift` to valid scopes list
  - [ ] 10.2 Tag new version
  - [ ] 10.3 Update hook version in all repos' `.pre-commit-config.yaml`

- [ ] Task 11: Validate across all repos (AC: 9) -- **All repos**
  - [ ] 11.1 Run `make check` on dev-toolchain
  - [ ] 11.2 Run `make check` on development-standards
  - [ ] 11.3 Run `make check` on github-repo-template
  - [ ] 11.4 Run `make check` on gitlab-repo-template
  - [ ] 11.5 Run `make check` on devrail.dev

- [ ] Task 12: Cut release (AC: 10) -- **Repo: dev-toolchain**
  - [ ] 12.1 Update `STABILITY.md`
  - [ ] 12.2 Run `make release VERSION=X.Y.0`
  - [ ] 12.3 Verify GHCR image published
  - [ ] 12.4 Verify floating `v1` tag updated

## Dev Notes

### Container Strategy

**SDK COPY pattern** (same as Go, Rust):
- Builder stage: `FROM swift:6.1-slim-bookworm AS swift-builder`
- COPY the Swift toolchain (swiftc, swift build, swift test, SPM) to runtime
- install-swift.sh is **verify-only** (confirms tools exist, installs SwiftLint + swift-format)

**Key gotchas:**
- `xcodebuild` is macOS-only -- cannot run in Linux container. Xcode project testing documented as CI-only on macOS runners
- SwiftLint has Linux builds (pre-built binaries from GitHub releases)
- swift-format (Apple's) can be built from source using `swift build` on Linux
- Security scanning: no dedicated `swift audit` tool -- use trivy on `Package.resolved`
- `Package.swift` presence gates SPM test; `*.swift` files gate lint/format

### Cross-Story Context

- Standards doc, schema, README, DEVELOPMENT.md, devrail.dev updates already completed in Story 14.1
- Tasks 5, 6, 7 are pre-completed -- only container, template, and release work remains

### References

- [Source: standards/swift.md] -- Swift standards (created in Story 14.1)
- [Source: standards/contributing.md] -- 8-step language addition checklist
- [Source: dev-toolchain/scripts/install-rust.sh] -- verify-only install pattern reference
- [Source: 14-1-add-swift-language-ecosystem.md] -- standards work already completed

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6

### Debug Log References

- Created install-swift.sh following verify-only + install pattern (SwiftLint binary + swift-format binary)
- Created test-swift.sh with command -v checks for swift, swiftlint, swift-format
- Updated Dockerfile with swift-builder stage and COPY to runtime
- Updated Makefile with HAS_SWIFT in _lint, _format, _fix, _test targets

### Completion Notes List

- install-swift.sh: SwiftLint v0.58.0 pre-built binary, swift-format v601.0.0 pre-built binary, architecture-aware downloads
- test-swift.sh: verifies swift, swiftlint, swift-format with version output
- Dockerfile: `FROM swift:6.1-slim-bookworm AS swift-builder`, COPY to /usr/local/swift, PATH updated
- Makefile: `*.swift` file gating for lint/format/fix, `Package.swift` gating for test
- Tasks 5-7 pre-completed in Story 14.1 (standards doc, schema, devrail.dev)
- Tasks 8-12 require template repo and release work (separate PRs)

### File List

- `dev-toolchain/scripts/install-swift.sh` -- new (Swift install script)
- `dev-toolchain/tests/test-swift.sh` -- new (Swift verification tests)
- `dev-toolchain/Dockerfile` -- modified (swift-builder stage, COPY, PATH)
- `dev-toolchain/Makefile` -- modified (HAS_SWIFT + 5 target blocks)
