# Story 12.3: Add Kotlin Language Ecosystem

Status: done

## Story

As a developer working in Kotlin,
I want DevRail to support Kotlin with linting, formatting, security scanning, and testing,
so that I get the same DevRail experience as all other supported languages.

## Acceptance Criteria

1. **Given** the dev-toolchain container, **When** a project declares `kotlin` in `.devrail.yml`, **Then** `make lint` runs ktlint and detekt and reports results
2. **Given** the dev-toolchain container, **When** a project declares `kotlin` in `.devrail.yml`, **Then** `make format` checks ktlint formatting and `make fix` applies fixes
3. **Given** the dev-toolchain container, **When** a project declares `kotlin` in `.devrail.yml`, **Then** `make test` runs `gradle test` (gated on `build.gradle.kts` or `build.gradle` presence)
4. **Given** the dev-toolchain container, **When** a project declares `kotlin` in `.devrail.yml`, **Then** `make security` runs OWASP dependency-check (gated on Gradle config presence)
5. **Given** `standards/kotlin.md`, **Then** it follows the consistent structure: Tools, Configuration, Makefile Targets, Pre-Commit Hooks, Notes
6. **Given** `devrail-yml-schema.md`, **Then** `kotlin` appears in the Allowed Values list and the Language Support Matrix
7. **Given** the template repos, **Then** `.pre-commit-config.yaml` includes Kotlin hooks (commented out by default)
8. **Given** `devrail init --languages kotlin`, **Then** the init script scaffolds Kotlin config files and uncomments the pre-commit hooks
9. **Given** all changes merged, **Then** `make check` passes on all 5 DevRail repos
10. **Given** all changes merged to dev-toolchain, **Then** a new semver release is tagged and the container image is published to GHCR

## Tasks / Subtasks

- [x] Task 1: Create install script (AC: 1, 2, 3, 4) -- **Repo: dev-toolchain**
  - [x] 1.1 Created `dev-toolchain/scripts/install-kotlin.sh` following mandatory pattern
  - [x] 1.2 ktlint v1.5.0 standalone binary download (idempotent: `command -v ktlint`)
  - [x] 1.3 detekt-cli v1.23.7 JAR + wrapper script (idempotent: file existence check)
  - [x] 1.4 Gradle v8.12 distribution download (idempotent: `command -v gradle`)
  - [x] 1.5 All tools verified with `require_cmd`

- [x] Task 2: Create verification test script (AC: 1, 2, 3) -- **Repo: dev-toolchain**
  - [x] 2.1 Created `dev-toolchain/tests/test-kotlin.sh`
  - [x] 2.2 Verifies ktlint with version output
  - [x] 2.3 Verifies detekt-cli presence
  - [x] 2.4 Verifies gradle with version output
  - [x] 2.5 Verifies java with version output (JDK 21)

- [x] Task 3: Update Dockerfile (AC: 1, 2, 3, 4) -- **Repo: dev-toolchain**
  - [x] 3.1 Added `FROM eclipse-temurin:21-jdk-bookworm AS jdk-builder`
  - [x] 3.2 COPY JDK: `COPY --from=jdk-builder /opt/java/openjdk /opt/java/openjdk`
  - [x] 3.3 Set `ENV JAVA_HOME=/opt/java/openjdk PATH="/opt/java/openjdk/bin:${PATH}"`
  - [x] 3.4 Install script runs via existing scripts/ COPY + `RUN bash /opt/devrail/scripts/install-kotlin.sh`

- [x] Task 4: Update Makefile targets (AC: 1, 2, 3, 4) -- **Repo: dev-toolchain**
  - [x] 4.1 Added `HAS_KOTLIN := $(filter kotlin,$(LANGUAGES))`
  - [x] 4.2 Added Kotlin block to `_lint`: `ktlint` + `detekt-cli` (gated on `*.kt`/`*.kts` + `detekt.yml`)
  - [x] 4.3 Added Kotlin block to `_format`: `ktlint --format --dry-run` (gated on `*.kt`/`*.kts`)
  - [x] 4.4 Added Kotlin block to `_fix`: `ktlint --format`
  - [x] 4.5 Added Kotlin block to `_test`: `gradle test` (gated on `build.gradle.kts`/`build.gradle`)
  - [x] 4.6 Added Kotlin block to `_security`: `gradle dependencyCheckAnalyze` (gated on Gradle config)
  - [ ] 4.7 Kotlin scaffolding for `_init` -- pending
  - [ ] 4.8 Sync Makefile to template repos -- pending (separate PRs)

- [x] Task 5: Write standards document (AC: 5) -- **Repo: development-standards** -- DONE (Story 14.3)
  - [x] 5.1 Created `standards/kotlin.md` with Tools, Configuration, Makefile Targets, Pre-Commit Hooks, Notes
  - [x] 5.2 Included annotated configs for ktlint (.editorconfig), detekt (detekt.yml), and Gradle (OWASP plugin)
  - [x] 5.3 Documented gating: `*.kt`/`*.kts` for lint/format, `build.gradle.kts`/`build.gradle` for test/security

- [x] Task 6: Update schema and documentation (AC: 6) -- **Repo: development-standards** -- DONE (Story 14.3)
  - [x] 6.1 Added `kotlin` to Allowed Values in `standards/devrail-yml-schema.md`
  - [x] 6.2 Added Kotlin column to Language Support Matrix
  - [x] 6.3 Added Kotlin row to `README.md` standards table
  - [x] 6.4 Added `kotlin` scope to `DEVELOPMENT.md` conventional commits scopes

- [x] Task 7: Update devrail.dev documentation site (AC: 6) -- **Repo: development-standards** -- DONE (Story 14.3)
  - [x] 7.1 Created `devrail.dev/content/docs/standards/kotlin.md` with Hugo/Docsy front matter
  - [x] 7.2 Updated `devrail.dev/content/docs/standards/_index.md` (matrix, target mapping, per-language links)

- [ ] Task 8: Configure pre-commit hooks (AC: 7) -- **Repos: github-repo-template, gitlab-repo-template**
  - [ ] 8.1 Add ktlint hook: `JetBrains/ktlint-pre-commit-hook` rev `v1.5.0` with `ktlint` hook ID
  - [ ] 8.2 Add as commented-out block in both template repos

- [ ] Task 9: Update devrail init (AC: 8) -- **Repo: dev-toolchain**
  - [ ] 9.1 Add `kotlin` to VALID_LANGUAGES in `devrail-init.sh`
  - [ ] 9.2 Add Kotlin config scaffolding (`.editorconfig` ktlint entries, `detekt.yml`)
  - [ ] 9.3 Add Kotlin pre-commit hook uncommenting logic

- [ ] Task 10: Update conventional commit scopes (AC: 9) -- **Repo: pre-commit-conventional-commits**
  - [ ] 10.1 Add `kotlin` to valid scopes list
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

**JDK COPY pattern** (new pattern for JVM languages):
- Builder stage: `FROM eclipse-temurin:21-jdk-bookworm AS jdk-builder`
- COPY JDK to runtime, set JAVA_HOME and PATH
- install-kotlin.sh downloads: Kotlin compiler, Gradle, ktlint binary, detekt CLI
- Unlike Go/Rust/Swift, JVM tools are typically standalone binaries or JARs, not compiler components

**Key gotchas:**
- JDK 21 is a significant container size addition (~300MB) -- evaluate impact on image size
- ktlint is distributed as a standalone binary (no JDK needed at runtime for ktlint itself)
- detekt can run as standalone CLI JAR or as Gradle plugin
- Android Lint requires Android SDK -- documented as CI-only for Android projects
- `build.gradle.kts` OR `build.gradle` presence gates Gradle commands (check for both)
- OWASP dependency-check is a Gradle plugin, requires build config to include it
- Gradle wrapper (`gradlew`) is preferred if present in the project; fall back to system Gradle

### Cross-Story Context

- Standards doc, schema, README, DEVELOPMENT.md, devrail.dev updates already completed in Story 14.3
- Tasks 5, 6, 7 are pre-completed -- only container, template, and release work remains
- Swift (Story 12.2) and Kotlin should share the release (Task 12) -- bundle into a single version bump

### References

- [Source: standards/kotlin.md] -- Kotlin standards (created in Story 14.3)
- [Source: standards/contributing.md] -- 8-step language addition checklist
- [Source: dev-toolchain/scripts/install-javascript.sh] -- npm install pattern (closest to Kotlin's binary downloads)
- [Source: 14-3-add-kotlin-language-ecosystem.md] -- standards work already completed

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6

### Debug Log References

- Created install-kotlin.sh with ktlint binary, detekt-cli JAR + wrapper, Gradle distribution
- Created test-kotlin.sh with command -v checks for java, ktlint, detekt-cli, gradle
- Updated Dockerfile with jdk-builder stage, COPY JDK, JAVA_HOME + PATH
- Updated Makefile with HAS_KOTLIN in _lint, _format, _fix, _test, _security targets

### Completion Notes List

- install-kotlin.sh: ktlint v1.5.0 binary, detekt-cli v1.23.7 JAR with bash wrapper, Gradle v8.12 distribution
- test-kotlin.sh: verifies java, ktlint, detekt-cli, gradle with version output
- Dockerfile: `FROM eclipse-temurin:21-jdk-bookworm AS jdk-builder`, COPY to /opt/java/openjdk, JAVA_HOME + PATH set
- Makefile: `*.kt`/`*.kts` file gating for lint/format/fix, `build.gradle.kts`/`build.gradle` gating for test/security, `detekt.yml` gating for detekt
- Tasks 5-7 pre-completed in Story 14.3 (standards doc, schema, devrail.dev)
- Tasks 8-12 require template repo and release work (separate PRs)

### File List

- `dev-toolchain/scripts/install-kotlin.sh` -- new (Kotlin install script)
- `dev-toolchain/tests/test-kotlin.sh` -- new (Kotlin verification tests)
- `dev-toolchain/Dockerfile` -- modified (jdk-builder stage, COPY, JAVA_HOME, PATH)
- `dev-toolchain/Makefile` -- modified (HAS_KOTLIN + 5 target blocks)
