# Story 12.1: Add New Language Ecosystem (Template)

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->
<!-- TEMPLATE STORY: Clone this file and replace [LANGUAGE]/[language] with the target language before development. -->

## Story

As a developer working in [LANGUAGE],
I want DevRail to support [LANGUAGE] with linting, formatting, security scanning, and testing,
so that I get the same DevRail experience as all other supported languages.

## Acceptance Criteria

1. **Given** the dev-toolchain container, **When** a project declares `[language]` in `.devrail.yml`, **Then** `make lint` runs the [LANGUAGE] linter and reports results
2. **Given** the dev-toolchain container, **When** a project declares `[language]` in `.devrail.yml`, **Then** `make format` checks [LANGUAGE] formatting and `make fix` applies fixes
3. **Given** the dev-toolchain container, **When** a project declares `[language]` in `.devrail.yml`, **Then** `make test` runs the [LANGUAGE] test runner (gated on presence of test files/config)
4. **Given** the dev-toolchain container, **When** a project declares `[language]` in `.devrail.yml`, **Then** `make security` runs [LANGUAGE]-specific security scanning (gated on lock file/config presence)
5. **Given** `standards/[language].md`, **Then** it follows the consistent structure: Tools, Configuration, Makefile Targets, Pre-Commit Hooks, Notes
6. **Given** `devrail-yml-schema.md`, **Then** `[language]` appears in the Allowed Values list and the Language Support Matrix
7. **Given** the template repos, **Then** `.pre-commit-config.yaml` includes [LANGUAGE] hooks (commented out by default)
8. **Given** `devrail init --languages [language]`, **Then** the init script scaffolds [LANGUAGE] config files and uncommments the pre-commit hooks
9. **Given** all changes merged, **Then** `make check` passes on all 5 DevRail repos (dev-toolchain, development-standards, github-repo-template, gitlab-repo-template, devrail.dev)
10. **Given** all changes merged to dev-toolchain, **Then** a new semver release is tagged and the container image is published to GHCR

## Tasks / Subtasks

- [ ] Task 1: Create install script (AC: 1, 2, 3, 4)
  - [ ] 1.1 Create `dev-toolchain/scripts/install-[language].sh` following the mandatory pattern (header, set -euo pipefail, lib sourcing, --help, cleanup trap, idempotent install functions, require_cmd verification)
  - [ ] 1.2 Install the linter: [LINTER] (idempotent: `command -v [linter]` or language-specific check before install)
  - [ ] 1.3 Install the formatter: [FORMATTER] (if different from linter)
  - [ ] 1.4 Install the security scanner: [SCANNER] (if language-specific, beyond trivy)
  - [ ] 1.5 Install the test runner: [TEST_RUNNER] (if not built-in to the language SDK)
  - [ ] 1.6 Verify all tools with `require_cmd` at end of each install function

- [ ] Task 2: Create verification test script (AC: 1, 2, 3, 4)
  - [ ] 2.1 Create `dev-toolchain/tests/test-[language].sh` using `assert_cmd` and `assert_version` helpers
  - [ ] 2.2 Verify linter is installed and runs: `assert_cmd [linter]`
  - [ ] 2.3 Verify formatter is installed and runs: `assert_cmd [formatter]`
  - [ ] 2.4 Verify test runner is available: `assert_cmd [test-runner]`
  - [ ] 2.5 Verify security tool is available (if language-specific)

- [ ] Task 3: Update Dockerfile (AC: 1, 2, 3, 4)
  - [ ] 3.1 Add builder stage if language requires SDK COPY (pattern: Go, Rust, Node.js, Swift)
  - [ ] 3.2 Add `COPY scripts/install-[language].sh /tmp/scripts/` and `RUN bash /tmp/scripts/install-[language].sh` to runtime stage
  - [ ] 3.3 Add environment variables if needed (e.g., JAVA_HOME, SWIFT_PATH)
  - [ ] 3.4 Build container and verify: `docker build .`

- [ ] Task 4: Update Makefile targets (AC: 1, 2, 3, 4)
  - [ ] 4.1 Add `HAS_[LANGUAGE] := $(filter [language],$(LANGUAGES))` detection variable
  - [ ] 4.2 Add [LANGUAGE] block to `_lint` target with proper error handling and fail-fast support
  - [ ] 4.3 Add [LANGUAGE] block to `_format` target (check mode)
  - [ ] 4.4 Add [LANGUAGE] block to `_fix` target (write mode)
  - [ ] 4.5 Add [LANGUAGE] block to `_test` target (gated on test file/config presence)
  - [ ] 4.6 Add [LANGUAGE] block to `_security` target (gated on lock file/config presence)
  - [ ] 4.7 Add [LANGUAGE] scaffolding to `_init` target (create default config files)
  - [ ] 4.8 Sync Makefile to both template repos

- [ ] Task 5: Write standards document (AC: 5)
  - [ ] 5.1 Create `standards/[language].md` with sections: Tools, Configuration, Makefile Targets, Pre-Commit Hooks, Notes
  - [ ] 5.2 Include annotated configuration examples for each tool
  - [ ] 5.3 Document gating conditions (which files must exist for each tool to run)

- [ ] Task 6: Update schema and documentation (AC: 6)
  - [ ] 6.1 Add `[language]` to Allowed Values in `standards/devrail-yml-schema.md`
  - [ ] 6.2 Add [LANGUAGE] column to Language Support Matrix in `devrail-yml-schema.md`
  - [ ] 6.3 Add `[language]` row to `README.md` standards table
  - [ ] 6.4 Add `[language]` scope to `DEVELOPMENT.md` conventional commits scopes

- [ ] Task 7: Update devrail.dev documentation site (AC: 6)
  - [ ] 7.1 Create `devrail.dev/content/docs/standards/[language].md` with Hugo/Docsy front matter
  - [ ] 7.2 Update `devrail.dev/content/docs/standards/_index.md` (matrix, target mapping, per-language links)

- [ ] Task 8: Configure pre-commit hooks (AC: 7)
  - [ ] 8.1 Find appropriate community pre-commit hooks for [LANGUAGE] (linter + formatter)
  - [ ] 8.2 Add hooks to both template repos' `.pre-commit-config.yaml` (commented out by default)
  - [ ] 8.3 Pin hook versions explicitly

- [ ] Task 9: Update devrail init (AC: 8)
  - [ ] 9.1 Add [LANGUAGE] to the language validation list in `devrail-init.sh`
  - [ ] 9.2 Add [LANGUAGE] config file scaffolding
  - [ ] 9.3 Add [LANGUAGE] pre-commit hook uncommenting logic

- [ ] Task 10: Update conventional commit scopes (AC: 9)
  - [ ] 10.1 Add `[language]` to the pre-commit-conventional-commits hook's valid scopes
  - [ ] 10.2 Tag a new version of the hook
  - [ ] 10.3 Update hook version in all repos' `.pre-commit-config.yaml`

- [ ] Task 11: Validate across all repos (AC: 9)
  - [ ] 11.1 Run `make check` on dev-toolchain
  - [ ] 11.2 Run `make check` on development-standards
  - [ ] 11.3 Run `make check` on github-repo-template
  - [ ] 11.4 Run `make check` on gitlab-repo-template
  - [ ] 11.5 Run `make check` on devrail.dev

- [ ] Task 12: Cut release (AC: 10)
  - [ ] 12.1 Update `STABILITY.md` in dev-toolchain
  - [ ] 12.2 Run `make release VERSION=X.Y.0`
  - [ ] 12.3 Verify GHCR image published
  - [ ] 12.4 Verify floating `v1` tag updated

## Dev Notes

**This is a TEMPLATE STORY.** To use it:
1. Clone this file as `12-N-add-[language]-language-ecosystem.md`
2. Replace all `[LANGUAGE]` with the language name (title case) and `[language]` with the identifier (lowercase)
3. Replace `[LINTER]`, `[FORMATTER]`, `[SCANNER]`, `[TEST_RUNNER]` with actual tool names
4. Adjust tasks based on the language's specific tooling needs

### Architecture Patterns to Follow

**Container Strategy (choose one based on language):**
- **SDK COPY pattern** (Go, Rust, Node.js, Swift): Multi-stage build, COPY SDK from official slim image to runtime stage. install-[language].sh is verify-only.
- **Package manager install pattern** (Ruby, JavaScript): Runtime install via gem/npm. install-[language].sh runs `gem install` or `npm install -g`.
- **System package pattern** (Python, Bash): Install via apt or pip. install-[language].sh runs apt-get/pip install.

**Makefile Target Pattern:**
```makefile
# Detection variable
HAS_[LANGUAGE] := $(filter [language],$(LANGUAGES))

# Inside each target (_lint, _format, _fix, _test, _security):
if [ -n "$(HAS_[LANGUAGE])" ]; then \
    ran_languages="$${ran_languages}\"[language]\","; \
    [command] || { overall_exit=1; failed_languages="$${failed_languages}\"[language]\","; }; \
    if [ "$(DEVRAIL_FAIL_FAST)" = "1" ] && [ $$overall_exit -ne 0 ]; then \
        # ... fail-fast JSON output ... \
        exit $$overall_exit; \
    fi; \
fi;
```

**Gating Conditions (common patterns):**
- Lint/Format: gate on `*.[ext]` files existing
- Test: gate on test files AND config file (e.g., `Package.swift`, `build.gradle.kts`, `Cargo.toml`)
- Security: gate on lock/dependency file (e.g., `Package.resolved`, `Cargo.lock`, `go.sum`, `package-lock.json`)

**Install Script Mandatory Structure:**
```bash
#!/usr/bin/env bash
# scripts/install-[language].sh -- Install [LANGUAGE] tooling for DevRail
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVRAIL_LIB="${DEVRAIL_LIB:-${SCRIPT_DIR}/../lib}"
source "${DEVRAIL_LIB}/log.sh"
source "${DEVRAIL_LIB}/platform.sh"
# --help flag, cleanup trap, idempotent install functions, require_cmd verification
```

### Multi-Repo PR Strategy

Submit PRs in this order (dependency chain):
1. **pre-commit-conventional-commits** -- add `[language]` scope, tag new version
2. **dev-toolchain** -- install script + Dockerfile + Makefile + tests + release
3. **development-standards** -- standards doc + schema update
4. **github-repo-template** -- pre-commit hooks + .devrail.yml
5. **gitlab-repo-template** -- pre-commit hooks + .devrail.yml
6. **devrail.dev** -- standards page + blog post

### Previous Language Additions (Reference)

| Language | Container Pattern | Install Pattern | Key Gotchas |
|---|---|---|---|
| Ruby | System Ruby 3.1 | `gem install` | bookworm ships 3.1 not 3.4; reek version pinning |
| Go | COPY from `golang` image | verify-only | SDK needed at runtime for govulncheck |
| JavaScript | COPY from `node:22-bookworm-slim` | `npm install -g` | manual npm/npx symlinks needed |
| Rust | COPY from `rust:1-slim-bookworm` | verify-only | no curl in base; clippy/rustfmt need rustup component add |
| Swift | COPY from `swift:6.1-slim-bookworm` | verify-only (planned) | xcodebuild macOS-only; SPM-first |
| Kotlin | COPY JDK from `eclipse-temurin:21-jdk` | binary downloads | Android Lint needs Android SDK (CI-only) |

### References

- [Source: standards/contributing.md] -- authoritative 8-step checklist with code examples
- [Source: MEMORY.md -> Adding a New Language -- Checklist] -- file-level checklist
- [Source: dev-toolchain/scripts/install-rust.sh] -- verify-only install pattern
- [Source: dev-toolchain/scripts/install-ruby.sh] -- gem install pattern
- [Source: dev-toolchain/scripts/install-javascript.sh] -- npm install pattern
- [Source: standards/rust.md] -- most recent language standards doc format
- [Source: devrail.dev/content/docs/standards/go.md] -- Hugo page format

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6

### Debug Log References

- Analyzed all 10 existing language ecosystems for pattern extraction
- Cross-referenced standards/contributing.md 8-step checklist
- Extracted architecture constraints from architecture.md
- Compiled previous language addition gotchas from MEMORY.md

### Completion Notes List

- Story enhanced from skeleton template to comprehensive dev agent guide
- Includes concrete code patterns for Makefile targets, install scripts, and gating conditions
- Previous language addition reference table prevents known gotchas
- Multi-repo PR strategy documents dependency chain
- All 12 tasks decomposed into atomic subtasks with AC traceability

### File List
