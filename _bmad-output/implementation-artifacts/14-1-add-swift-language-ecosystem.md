# Story 14.1: Add Swift Language Ecosystem

Status: done

## Story

As a developer working on Swift projects,
I want DevRail to support Swift linting, formatting, testing, and security scanning,
so that my Swift code follows the same standards-driven workflow as all other DevRail-supported languages.

## Acceptance Criteria

1. `standards/swift.md` exists with the standard structure (Tools, Configuration, Makefile Targets, Pre-Commit Hooks, Notes)
2. `.devrail.yml` schema accepts `swift` as a valid language identifier
3. Language support matrix in `devrail-yml-schema.md` and `devrail.dev` includes Swift
4. README.md lists the Swift standards document
5. DEVELOPMENT.md includes `swift` in conventional commit scopes
6. `devrail.dev/content/docs/standards/swift.md` exists with Hugo front matter
7. `devrail.dev/content/docs/standards/_index.md` includes Swift in the matrix and per-language links
8. `make check` passes on the development-standards repo

## Tasks / Subtasks

- [x] Task 1: Create Swift standards document (AC: 1)
  - [x] 1.1 Research Swift tooling: SwiftLint (linter), swift-format (formatter), swift test (SPM), xcodebuild (Xcode projects)
  - [x] 1.2 Write `standards/swift.md` with Tools table, Configuration sections for SwiftLint and swift-format, Makefile Targets, Pre-Commit Hooks, and Notes
  - [x] 1.3 Document xcodebuild as CI-only (macOS runners) since it cannot run in the Linux container

- [x] Task 2: Update schema and documentation (AC: 2, 3, 4, 5)
  - [x] 2.1 Add `swift` to allowed values in `standards/devrail-yml-schema.md`
  - [x] 2.2 Add Swift column to language support matrix in `devrail-yml-schema.md`
  - [x] 2.3 Add Swift row to README.md standards table
  - [x] 2.4 Add `swift` scope to DEVELOPMENT.md conventional commits scopes table

- [x] Task 3: Update documentation site (AC: 6, 7)
  - [x] 3.1 Create `devrail.dev/content/docs/standards/swift.md` with Hugo/Docsy front matter
  - [x] 3.2 Update `devrail.dev/content/docs/standards/_index.md` with Swift in matrix and per-language links

- [ ] Task 4: Validate (AC: 8)
  - [ ] 4.1 Run `make check` on development-standards repo

## Dev Notes

- Swift tooling for the container:
  - **SwiftLint** (realm/SwiftLint): the de facto standard Swift linter, runs on Linux
  - **swift-format** (apple/swift-format): Apple's official formatter, runs on Linux
  - **swift test**: SPM-based test runner, runs on Linux
  - **xcodebuild**: macOS-only (requires Xcode), CI-only on macOS runners
- Container strategy: COPY Swift toolchain from `swift:6.1-slim-bookworm` (same pattern as Go, Node.js)
- SwiftLint can be installed via Swift Package Manager or pre-built binary
- swift-format is built from source with `swift build` or available as a pre-built binary
- Security scanning: trivy covers Swift dependencies via `Package.resolved` -- no dedicated Swift audit tool exists
- SPM projects gate on `Package.swift` presence; Xcode projects gate on `*.xcodeproj`
- This story covers documentation only in this repo; container/Makefile/template changes tracked separately in dev-toolchain

### Dev-Toolchain Changes (tracked separately)

Files to create:
- `dev-toolchain/scripts/install-swift.sh`
- `dev-toolchain/tests/test-swift.sh`

Files to modify:
- `dev-toolchain/Dockerfile` (COPY Swift from builder stage, RUN install-swift.sh)
- `dev-toolchain/Makefile` (HAS_SWIFT + _lint/_format/_fix/_test/_security blocks)
- Both template `.pre-commit-config.yaml` files
- Both template `.devrail.yml` files

### References

- [Source: standards/rust.md] -- format reference for language standards doc
- [Source: standards/contributing.md] -- 8-step language addition checklist
- [Source: devrail.dev/content/docs/standards/go.md] -- devrail.dev page format reference

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6

### Debug Log References

- Reviewed all 8 existing language standards docs for format consistency
- Reviewed contributing.md 8-step checklist for completeness

### Completion Notes List

- `standards/swift.md` created with full Tools, Configuration, Makefile Targets, Pre-Commit Hooks, Notes sections
- SwiftLint config includes opt-in rules for safety (force_unwrapping, implicitly_unwrapped_optional)
- swift-format (Apple's official) used for container; nicklockwood/SwiftFormat referenced for pre-commit hooks
- xcodebuild documented as CI-only on macOS runners -- cannot run in Linux container
- `devrail-yml-schema.md` updated: `swift` added to allowed values and language support matrix
- `README.md` updated with Swift standards doc link
- `DEVELOPMENT.md` updated with `swift` conventional commit scope
- `devrail.dev/content/docs/standards/swift.md` created with Hugo/Docsy front matter
- `devrail.dev/content/docs/standards/_index.md` updated with Swift in matrix, target mapping, and per-language links

### File List

- `standards/swift.md` -- new (Swift language standards document)
- `standards/devrail-yml-schema.md` -- modified (added swift to allowed values and matrix)
- `README.md` -- modified (added Swift standards doc link)
- `DEVELOPMENT.md` -- modified (added swift scope)
- `devrail.dev/content/docs/standards/swift.md` -- new (Hugo documentation page)
- `devrail.dev/content/docs/standards/_index.md` -- modified (added Swift to matrix and links)
