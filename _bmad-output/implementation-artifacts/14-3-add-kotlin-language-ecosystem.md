# Story 14.3: Add Kotlin Language Ecosystem

Status: done

## Story

As a developer working on Kotlin projects,
I want DevRail to support Kotlin linting, formatting, testing, and security scanning,
so that my Kotlin code follows the same standards-driven workflow as all other DevRail-supported languages.

## Acceptance Criteria

1. `standards/kotlin.md` exists with the standard structure (Tools, Configuration, Makefile Targets, Pre-Commit Hooks, Notes)
2. `.devrail.yml` schema accepts `kotlin` as a valid language identifier
3. Language support matrix in `devrail-yml-schema.md` and `devrail.dev` includes Kotlin
4. README.md lists the Kotlin standards document
5. DEVELOPMENT.md includes `kotlin` in conventional commit scopes
6. `devrail.dev/content/docs/standards/kotlin.md` exists with Hugo front matter
7. `devrail.dev/content/docs/standards/_index.md` includes Kotlin in the matrix and per-language links
8. `make check` passes on the development-standards repo

## Tasks / Subtasks

- [x] Task 1: Create Kotlin standards document (AC: 1)
  - [x] 1.1 Research Kotlin tooling: ktlint (linter/formatter), detekt (static analysis), Gradle (build/test), Android Lint (Android projects)
  - [x] 1.2 Write `standards/kotlin.md` with Tools table, Configuration sections for ktlint, detekt, and Gradle, Makefile Targets, Pre-Commit Hooks, and Notes
  - [x] 1.3 Document Android Lint as CI-only for Android projects (requires Android SDK)

- [x] Task 2: Update schema and documentation (AC: 2, 3, 4, 5)
  - [x] 2.1 Add `kotlin` to allowed values in `standards/devrail-yml-schema.md`
  - [x] 2.2 Add Kotlin column to language support matrix in `devrail-yml-schema.md`
  - [x] 2.3 Add Kotlin row to README.md standards table
  - [x] 2.4 Add `kotlin` scope to DEVELOPMENT.md conventional commits scopes table

- [x] Task 3: Update documentation site (AC: 6, 7)
  - [x] 3.1 Create `devrail.dev/content/docs/standards/kotlin.md` with Hugo/Docsy front matter
  - [x] 3.2 Update `devrail.dev/content/docs/standards/_index.md` with Kotlin in matrix and per-language links

- [ ] Task 4: Validate (AC: 8)
  - [ ] 4.1 Run `make check` on development-standards repo

## Dev Notes

- Kotlin tooling for the container:
  - **ktlint** (pinterest/ktlint): Kotlin linter and formatter, standalone JAR or binary
  - **detekt** (detekt/detekt): static analysis for Kotlin, standalone CLI
  - **Gradle**: build tool, needed for `gradle test` and dependency management
  - **Android Lint**: part of Android command-line tools, requires Android SDK -- CI-only for Android projects
- Container strategy: Install JDK from `eclipse-temurin:21-jdk-bookworm` builder stage, Kotlin compiler via kotlinc, Gradle via direct download
- ktlint is distributed as a standalone binary (no JDK dependency at runtime for the binary distribution)
- detekt distributed as standalone CLI JAR or via Gradle plugin
- Security scanning: trivy covers Gradle dependencies; `gradle dependencyCheckAnalyze` (OWASP plugin) for dedicated scanning
- Kotlin projects gate on `build.gradle.kts` or `build.gradle` presence; `*.kt` files for lint/format
- Single `kotlin` entry in `.devrail.yml` covers both JVM and Android Kotlin

### Dev-Toolchain Changes (tracked separately)

Files to create:
- `dev-toolchain/scripts/install-kotlin.sh`
- `dev-toolchain/tests/test-kotlin.sh`

Files to modify:
- `dev-toolchain/Dockerfile` (COPY JDK from builder stage, install Kotlin + Gradle + ktlint + detekt)
- `dev-toolchain/Makefile` (HAS_KOTLIN + _lint/_format/_fix/_test/_security blocks)
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

- `standards/kotlin.md` created with full Tools, Configuration, Makefile Targets, Pre-Commit Hooks, Notes sections
- ktlint documented as dual-purpose (linter + formatter) using `.editorconfig` for config
- detekt documented with `maxIssues: 0` zero-tolerance policy
- OWASP dependency-check documented as Gradle plugin for security scanning
- Android Lint documented as CI-only requiring Android SDK
- JDK 21 (Eclipse Temurin) noted as container dependency
- `devrail-yml-schema.md` updated: `kotlin` added to allowed values and language support matrix
- `README.md` updated with Kotlin standards doc link
- `DEVELOPMENT.md` updated with `kotlin` conventional commit scope
- `devrail.dev/content/docs/standards/kotlin.md` created with Hugo/Docsy front matter
- `devrail.dev/content/docs/standards/_index.md` updated with Kotlin in matrix, target mapping, and per-language links

### File List

- `standards/kotlin.md` -- new (Kotlin language standards document)
- `standards/devrail-yml-schema.md` -- modified (added kotlin to allowed values and matrix)
- `README.md` -- modified (added Kotlin standards doc link)
- `DEVELOPMENT.md` -- modified (added kotlin scope)
- `devrail.dev/content/docs/standards/kotlin.md` -- new (Hugo documentation page)
- `devrail.dev/content/docs/standards/_index.md` -- modified (added Kotlin to matrix and links)
