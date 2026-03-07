---
stepsCompleted: [1, 2, 3, 4]
inputDocuments: [prd.md, architecture.md]
workflowType: 'epics'
status: 'complete'
completedAt: '2026-02-19'
project_name: 'DevRail'
user_name: 'Matthew'
date: '2026-02-19'
---

# DevRail - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for DevRail, decomposing the requirements from the PRD and Architecture into implementable stories.

## Requirements Inventory

### Functional Requirements

FR1: Developer can reference a single canonical standards document that defines all linting, formatting, security, testing, and commit conventions
FR2: AI agent can read agent instruction files (CLAUDE.md, AGENTS.md, .cursorrules, .opencode/) and determine project standards without human explanation
FR3: Developer can update standards in one place and have all downstream artifacts (agent files, templates) reflect the change
FR4: Developer can define per-language tooling configurations (linter, formatter, security scanner, test runner) in the standards document
FR5: Developer can pull a single Docker image containing all linting, formatting, security, testing, and documentation tools for all supported languages
FR6: Developer can pin a specific container version in their project and upgrade deliberately
FR7: Container can execute make check against any DevRail-compliant project and produce identical results to CI
FR8: Container automatically rebuilds weekly with updated tool versions and publishes a new semver release
FR9: Container includes universal scanning tools (trivy, gitleaks) available to all language ecosystems
FR10: Developer can run make lint to execute all language-appropriate linters for the project
FR11: Developer can run make format to execute all language-appropriate formatters for the project
FR12: Developer can run make test to execute the project's test suite
FR13: Developer can run make security to execute language-specific security scanners
FR14: Developer can run make scan to execute universal security scanning (trivy, gitleaks)
FR15: Developer can run make docs to generate documentation (e.g., terraform-docs for Terraform projects)
FR16: Developer can run make check to execute all of the above targets in sequence
FR17: All Makefile targets execute inside the dev-toolchain Docker container, ensuring environment consistency
FR18: Developer can create a new GitHub repository from the DevRail GitHub template with all standards pre-configured
FR19: Developer can create a new GitLab repository from the DevRail GitLab template with all standards pre-configured
FR20: Templates include pre-commit hooks for conventional commits, linting, formatting, security, and documentation generation
FR21: Templates include CI pipeline configuration (GitHub Actions / GitLab CI) that runs make check using the pinned dev-toolchain container
FR22: Templates include agent instruction files (CLAUDE.md, AGENTS.md, .cursorrules, .opencode/) pointing to DevRail standards
FR23: Templates include EditorConfig, .gitignore, PR/MR templates, and CODEOWNERS
FR24: Developer can retrofit an existing repo by copying DevRail configuration files into it
FR25: Pre-commit hooks enforce conventional commit message format on every commit
FR26: Pre-commit hooks run language-appropriate linting and formatting checks before commit
FR27: Pre-commit hooks run gitleaks to prevent secret leakage before commit
FR28: Pre-commit hooks run terraform-docs to auto-update README documentation for Terraform projects
FR29: Developer can install pre-commit hooks via make install-hooks or equivalent setup target
FR30: GitHub Actions pipeline runs make check inside the dev-toolchain container on every push and PR
FR31: GitLab CI pipeline runs make check inside the dev-toolchain container on every push and MR
FR32: CI results are identical to local make check results (same container, same tools, same config)
FR33: CI pipeline blocks merging if make check fails
FR34: AI agent can read CLAUDE.md and determine all project conventions, required checks, and commit standards
FR35: AI agent can run make check autonomously before marking a story complete
FR36: AI agent can produce conventional commits without human reminding
FR37: BMAD planning agents can incorporate DevRail standards into architecture and planning artifacts when instructed
FR38: Multiple AI tools (Claude Code, Cursor, OpenCode) can consume the same standards through tool-specific instruction files
FR39: Visitor can view the DevRail project overview, getting started guide, and language support reference on devrail.dev
FR40: Documentation site is generated from markdown using Hugo and hosted on Cloudflare
FR41: Contributor can find contribution guidelines for each repo in the ecosystem
FR42: Contributor can add a new language ecosystem by following the established pattern (install script + Makefile targets + pre-commit config)
FR43: All DevRail repos dogfood their own standards (same Makefile, pre-commit, CI pipeline pattern)
FR44: Contributor can submit PRs with conventional commits and have CI validate them automatically

### NonFunctional Requirements

NFR1: make check completes in under 5 minutes for a typical project (< 10,000 LOC)
NFR2: Individual targets (make lint, make format) complete in under 60 seconds for typical projects
NFR3: Pre-commit hooks complete in under 30 seconds to avoid disrupting developer flow
NFR4: Dev-toolchain container image pull time acceptable for CI cold starts (< 2 minutes on standard runners)
NFR5: Dev-toolchain container built from trusted, pinned base images
NFR6: Container builds run trivy self-scan — container must pass its own security scanning
NFR7: No secrets, credentials, or tokens baked into the container image
NFR8: GHCR image signing for supply chain verification
NFR9: Weekly container builds succeed consistently — build failures detected and reported automatically
NFR10: Semver tagging ensures projects pinning to a version are never broken by a new release
NFR11: Pre-commit hooks fail gracefully with clear error messages
NFR12: CI pipelines fail fast with actionable output
NFR13: Dev-toolchain container runs on linux/amd64 and linux/arm64
NFR14: Makefile targets work on Linux and macOS host systems
NFR15: Pre-commit hooks compatible with pre-commit framework v3+
NFR16: Templates work with Git 2.28+
NFR17: Container images published to GitHub Container Registry (ghcr.io/devrail-dev/)
NFR18: GitHub Actions workflows use standard GitHub-hosted runners
NFR19: GitLab CI pipelines use standard GitLab shared runners
NFR20: Pre-commit hooks compatible with the pre-commit framework ecosystem
NFR21: Conventional commit hook integrates with existing pre-commit-conventional-commits repo
NFR22: devrail.dev meets WCAG 2.1 Level A minimum
NFR23: All documentation navigable without JavaScript (Hugo static generation)
NFR24: Code examples include sufficient context to be understood without surrounding text

### Additional Requirements

- Multi-stage Dockerfile with per-language install scripts (builder stages for Go-based tools, final stage copies runtime only)
- Major-version floating tag (v1) with exact semver tags also published; weekly builds update both
- .devrail.yml config file at repo root declares languages, settings, project metadata
- Hybrid agent shim files: pointer to DEVELOPMENT.md plus critical rules inlined
- Configurable error handling: run-all-report-all default, fail-fast via DEVRAIL_FAIL_FAST=1 or .devrail.yml
- Single DEVELOPMENT.md with structured markers (<!-- devrail:section-name -->) for machine extraction
- Parallel CI jobs per category (lint, format, security, test, docs)
- Fast-local / slow-CI pre-commit split
- Shell script conventions: #!/usr/bin/env bash, set -euo pipefail, idempotent, shared logging library (lib/log.sh), JSON output default, getopts, shellcheck compliant, Click for Python CLIs
- Shared library: lib/log.sh (log_info, log_warn, log_error, log_debug, die), lib/platform.sh (on_mac, on_linux, on_arm64)
- Three verbosity levels: quiet (DEVRAIL_QUIET=1), normal, debug (DEVRAIL_DEBUG=1)
- Validation helpers: is_empty, is_not_empty, is_set, require_cmd
- Trap handlers for cleanup, temp files via mktemp only
- Self-documenting scripts with structured headers and --help
- Makefile patterns: lower-kebab-case public targets, _ prefix internal, make help default, ## comments for auto-help
- .devrail.yml: YAML format, snake_case keys, top-level keys (languages, fail_fast, log_format)
- DEVELOPMENT.md markers: HTML comment open/close tags
- EditorConfig in every repo
- File organization: scripts/ for executables, lib/ for sourced libraries, tests/ at root, config at root
- Exit codes: 0 (pass), 1 (failure), 2 (misconfiguration)
- Makefile target output: JSON summary per target, final summary from make check
- CI job names match target names, JSON output to artifact files
- README structure: title → badges → quick start → usage → config → contributing → license
- Comments explain why not what, no commented-out code, TODO(devrail#123) format
- Conventional commits: type(scope): description with defined types and scopes
- Changelog auto-generated from conventional commits, Keep a Changelog format
- Implementation sequence: .devrail.yml schema → container → Makefile contract → DEVELOPMENT.md + shims → pre-commit → CI pipelines

### FR Coverage Map

| FR | Epic | Description |
|---|---|---|
| FR1 | Epic 1 | Canonical standards document |
| FR2 | Epic 1 | Agent instruction files readable |
| FR3 | Epic 1 | Single-source update propagation |
| FR4 | Epic 1 | Per-language tooling configs |
| FR5 | Epic 2 | Single Docker image with all tools |
| FR6 | Epic 2 | Pinned container versions |
| FR7 | Epic 2 | Container executes make check identically to CI |
| FR8 | Epic 2 | Weekly automated rebuilds with semver |
| FR9 | Epic 2 | Universal scanning tools included |
| FR10 | Epic 3 | make lint target |
| FR11 | Epic 3 | make format target |
| FR12 | Epic 3 | make test target |
| FR13 | Epic 3 | make security target |
| FR14 | Epic 3 | make scan target |
| FR15 | Epic 3 | make docs target |
| FR16 | Epic 3 | make check runs all targets |
| FR17 | Epic 3 | All targets execute inside container |
| FR18 | Epic 6 | GitHub template repo creation |
| FR19 | Epic 5 | GitLab template repo creation |
| FR20 | Epic 5, 6 | Templates include pre-commit hooks |
| FR21 | Epic 5, 6 | Templates include CI pipeline config |
| FR22 | Epic 5, 6 | Templates include agent instruction files |
| FR23 | Epic 5, 6 | Templates include EditorConfig, .gitignore, PR/MR templates, CODEOWNERS |
| FR24 | Epic 5, 6 | Retrofit existing repos |
| FR25 | Epic 4 | Conventional commit enforcement |
| FR26 | Epic 4 | Language-appropriate linting/formatting hooks |
| FR27 | Epic 4 | Gitleaks pre-commit hook |
| FR28 | Epic 4 | Terraform-docs pre-commit hook |
| FR29 | Epic 4 | make install-hooks target |
| FR30 | Epic 6 | GitHub Actions CI pipeline |
| FR31 | Epic 5 | GitLab CI pipeline |
| FR32 | Epic 6 | CI/local result identity (GitHub) |
| FR33 | Epic 5, 6 | CI blocks merging on failure |
| FR34 | Epic 7 | Agent reads CLAUDE.md |
| FR35 | Epic 7 | Agent runs make check autonomously |
| FR36 | Epic 7 | Agent produces conventional commits |
| FR37 | Epic 7 | BMAD planning integration |
| FR38 | Epic 7 | Multi-tool agent instruction consumption |
| FR39 | Epic 8 | devrail.dev project overview and guides |
| FR40 | Epic 8 | Hugo + Cloudflare hosting |
| FR41 | Epic 8 | Per-repo contribution guidelines |
| FR42 | Epic 9 | Add language ecosystem pattern |
| FR43 | Epic 9 | All repos dogfood standards |
| FR44 | Epic 9 | PR with conventional commits + CI validation |

## Epic List

### Epic 1: Standards Foundation
A canonical, machine-readable set of development standards exists that humans and AI agents can reference.
**FRs covered:** FR1, FR2, FR3, FR4
**Repo:** devrail-standards

### Epic 2: Dev-Toolchain Container
A single Docker image with all linting, formatting, security, and testing tools can be pulled and used immediately.
**FRs covered:** FR5, FR6, FR7, FR8, FR9
**Repo:** dev-toolchain

### Epic 3: Makefile Contract
Developer can run `make check` on any project and get consistent, comprehensive results inside the container.
**FRs covered:** FR10, FR11, FR12, FR13, FR14, FR15, FR16, FR17
**Repo:** Template repos + dev-toolchain

### Epic 4: Pre-Commit Enforcement
Every commit is validated locally — format, lint, conventional commits, secrets — before it hits the remote.
**FRs covered:** FR25, FR26, FR27, FR28, FR29
**Repo:** pre-commit-conventional-commits + template repos

### Epic 5: GitLab Project Template
Developer creates a new GitLab project from the template and gets a fully configured repo with CI pipeline — zero setup.
**FRs covered:** FR19, FR20, FR21, FR22, FR23, FR24, FR31, FR33
**Repo:** gitlab-repo-template

### Epic 6: GitHub Project Template
Developer creates a new GitHub project from the template and gets a fully configured repo with CI pipeline — zero setup.
**FRs covered:** FR18, FR20, FR21, FR22, FR23, FR24, FR30, FR32, FR33
**Repo:** github-repo-template

### Epic 7: AI Agent Integration
AI agents (Claude Code, Cursor, OpenCode, BMAD) follow DevRail standards autonomously without human reminding.
**FRs covered:** FR34, FR35, FR36, FR37, FR38
**Repo:** Cross-cutting

### Epic 8: Documentation Site
Anyone can discover DevRail, understand what it does, and get started at devrail.dev.
**FRs covered:** FR39, FR40, FR41
**Repo:** devrail.dev

### Epic 9: Dogfooding & Contributor Experience
All DevRail repos eat their own dog food, and new contributors can add language ecosystems following a clear pattern.
**FRs covered:** FR42, FR43, FR44
**Repo:** All repos

## Epic 1: Standards Foundation

A canonical, machine-readable set of development standards exists that humans and AI agents can reference.

### Story 1.1: Initialize Repository and Define .devrail.yml Schema

As a developer,
I want a documented .devrail.yml schema that defines how projects declare their languages and settings,
So that all downstream tools (Makefile, CI, agents) have a single config file to read.

**Acceptance Criteria:**

**Given** a new devrail-standards repository
**When** the repo is initialized
**Then** it contains .devrail.yml, .editorconfig, .gitignore, LICENSE, and Makefile
**And** standards/devrail-yml-schema.md documents the complete schema with all supported keys, types, defaults, and examples
**And** the schema defines top-level keys: `languages`, `fail_fast`, `log_format` with per-language override structure

### Story 1.2: Write Canonical DEVELOPMENT.md with Structured Markers

As a developer,
I want a single DEVELOPMENT.md that contains all DevRail standards with machine-readable markers,
So that both humans and automated tools can extract and reference specific sections.

**Acceptance Criteria:**

**Given** the devrail-standards repo exists
**When** DEVELOPMENT.md is created
**Then** it contains all development standards organized by concern (linting, formatting, security, testing, commits)
**And** critical rules sections are wrapped in `<!-- devrail:critical-rules -->` / `<!-- /devrail:critical-rules -->` markers
**And** per-language sections are wrapped in corresponding markers (e.g., `<!-- devrail:python -->`)
**And** the document renders cleanly as standard markdown with markers invisible

### Story 1.3: Create Per-Language Standards Documents

As a developer,
I want per-language standards documents that specify exact tools, configurations, and conventions for each supported language,
So that agents and developers know exactly which tools to use and how to configure them.

**Acceptance Criteria:**

**Given** the devrail-standards repo exists
**When** per-language documents are created
**Then** standards/python.md specifies ruff, ruff format, bandit/semgrep, pytest, mypy with config examples
**And** standards/bash.md specifies shellcheck, shfmt, bats with config examples
**And** standards/terraform.md specifies tflint, terraform fmt, tfsec/checkov, terratest, terraform-docs with config examples
**And** standards/ansible.md specifies ansible-lint, molecule with config examples
**And** standards/universal.md specifies trivy, gitleaks with config examples
**And** each document follows a consistent structure: tools table, configuration, Makefile targets, pre-commit hooks

### Story 1.4: Create Agent Instruction File Templates

As a developer,
I want template versions of all agent instruction files (CLAUDE.md, AGENTS.md, .cursorrules, .opencode/),
So that project templates can ship files that tell AI agents to follow DevRail standards.

**Acceptance Criteria:**

**Given** the DEVELOPMENT.md and standards documents exist
**When** agent instruction templates are created
**Then** standards/agent-instructions.md documents the shim strategy and critical rules list
**And** template CLAUDE.md contains a pointer to DEVELOPMENT.md plus all critical rules inlined
**And** template AGENTS.md contains equivalent content for generic agent consumption
**And** template .cursorrules contains equivalent content for Cursor
**And** template .opencode/agents.yaml contains equivalent content for OpenCode
**And** all shim files include: "run `make check` before completing work", "use conventional commits", "never install tools outside the container"

### Story 1.5: Write Makefile Contract and README

As a developer,
I want the Makefile contract specification documented and the repo README completed,
So that anyone can understand the DevRail target naming, behavior, and contribution process.

**Acceptance Criteria:**

**Given** all standards documents exist
**When** the Makefile contract spec and README are written
**Then** standards/makefile-contract.md documents all targets, the two-layer delegation pattern, error handling, and exit codes
**And** README.md follows the standard structure: title, badges, quick start, usage, configuration, contributing, license
**And** the repo's own Makefile, .pre-commit-config.yaml, and agent instruction files are configured (dogfooding)

## Epic 2: Dev-Toolchain Container

A single Docker image with all linting, formatting, security, and testing tools can be pulled and used immediately.

### Story 2.1: Initialize Repository with Multi-Stage Dockerfile and Shared Libraries

As a developer,
I want a dev-toolchain repo with a multi-stage Dockerfile skeleton and shared bash libraries,
So that per-language install scripts have a consistent foundation to build on.

**Acceptance Criteria:**

**Given** a new dev-toolchain repository
**When** the repo is initialized
**Then** it contains a multi-stage Dockerfile with a Debian-based builder stage and a clean final stage
**And** lib/log.sh provides log_info, log_warn, log_error, log_debug, die functions with JSON default output
**And** lib/platform.sh provides on_mac, on_linux, on_arm64 detection helpers
**And** lib/log.sh supports DEVRAIL_LOG_FORMAT=human, DEVRAIL_QUIET=1, DEVRAIL_DEBUG=1
**And** validation helpers (is_empty, is_not_empty, is_set, require_cmd) are available
**And** the repo includes .devrail.yml, .editorconfig, .gitignore, Makefile, README, LICENSE, and agent instruction files

### Story 2.2: Python Tooling Install Script

As a developer,
I want Python linting, formatting, security, and testing tools installed in the container,
So that any Python project can run `make lint`, `make format`, `make security`, and `make test`.

**Acceptance Criteria:**

**Given** the base Dockerfile and shared libraries exist
**When** scripts/install-python.sh is created and executed
**Then** ruff, bandit, semgrep, pytest, and mypy are installed and available on PATH
**And** the script is idempotent — safe to re-run without side effects
**And** the script uses shared logging library (no raw echo)
**And** the script supports --help and follows the structured header convention
**And** tests/test-python.sh verifies all Python tools are installed and executable

### Story 2.3: Bash Tooling Install Script

As a developer,
I want Bash linting, formatting, and testing tools installed in the container,
So that any Bash project can run `make lint`, `make format`, and `make test`.

**Acceptance Criteria:**

**Given** the base Dockerfile and shared libraries exist
**When** scripts/install-bash.sh is created and executed
**Then** shellcheck, shfmt, and bats are installed and available on PATH
**And** the script is idempotent, uses shared logging, supports --help
**And** tests/test-bash.sh verifies all Bash tools are installed and executable

### Story 2.4: Terraform Tooling Install Script

As a developer,
I want Terraform linting, formatting, security, testing, and documentation tools installed in the container,
So that any Terraform project can run all standard make targets including `make docs`.

**Acceptance Criteria:**

**Given** the base Dockerfile and shared libraries exist
**When** scripts/install-terraform.sh is created and executed
**Then** tflint, tfsec, checkov, terratest, and terraform-docs are installed and available on PATH
**And** terraform fmt is available via terraform binary
**And** the script is idempotent, uses shared logging, supports --help
**And** tests/test-terraform.sh verifies all Terraform tools are installed and executable

### Story 2.5: Ansible Tooling Install Script

As a developer,
I want Ansible linting and testing tools installed in the container,
So that any Ansible project can run `make lint` and `make test`.

**Acceptance Criteria:**

**Given** the base Dockerfile and shared libraries exist
**When** scripts/install-ansible.sh is created and executed
**Then** ansible-lint and molecule are installed and available on PATH
**And** the script is idempotent, uses shared logging, supports --help
**And** tests/test-ansible.sh verifies all Ansible tools are installed and executable

### Story 2.6: Universal Security Tools Install Script

As a developer,
I want trivy and gitleaks installed in the container,
So that any project can run `make scan` for container/dependency scanning and secret detection.

**Acceptance Criteria:**

**Given** the base Dockerfile and shared libraries exist
**When** scripts/install-universal.sh is created and executed
**Then** trivy and gitleaks are installed and available on PATH
**And** the script is idempotent, uses shared logging, supports --help
**And** tests/test-universal.sh verifies both tools are installed and executable

### Story 2.7: Multi-Arch Build and GHCR Publishing

As a developer,
I want the container to build for amd64 and arm64 and publish to GHCR with semver + major-version floating tags,
So that CI runners and Apple Silicon Macs can pull the same image, and projects can pin or float versions.

**Acceptance Criteria:**

**Given** the Dockerfile and all install scripts are complete
**When** the build workflow runs
**Then** the image is built for linux/amd64 and linux/arm64
**And** the image is pushed to ghcr.io/devrail-dev/dev-toolchain with an exact semver tag (e.g., v1.0.0)
**And** the major-version floating tag (e.g., v1) is updated to point to the new image
**And** .github/workflows/build.yml defines the build and push process
**And** .github/workflows/release.yml handles semver tagging

### Story 2.8: Automated Weekly Builds

As a developer,
I want the container to rebuild automatically every week with updated tool versions,
So that projects get security patches and tool updates without manual intervention.

**Acceptance Criteria:**

**Given** the build and release workflows exist
**When** the weekly schedule triggers (or manual dispatch)
**Then** a new container image is built with the latest tool versions
**And** a new semver patch version is published (e.g., v1.0.1 → v1.0.2)
**And** the major-version floating tag is updated
**And** build failures are detected and reported via GitHub Actions notification
**And** the build workflow is configured with `schedule: cron` for weekly execution

### Story 2.9: Container Self-Validation

As a developer,
I want the container to pass its own `make check` and trivy self-scan,
So that I know the tooling image itself meets DevRail standards.

**Acceptance Criteria:**

**Given** the container is built with all tools
**When** `make check` is run against the dev-toolchain repo inside its own container
**Then** all shell scripts pass shellcheck
**And** all scripts pass shfmt formatting
**And** gitleaks finds no secrets
**And** trivy scan of the container image reports no critical/high vulnerabilities
**And** .github/workflows/ci.yml runs this validation on every push and PR

## Epic 3: Makefile Contract

Developer can run `make check` on any project and get consistent, comprehensive results inside the container.

### Story 3.1: Create Reference Makefile with Two-Layer Delegation Pattern

As a developer,
I want a reference Makefile that delegates all targets to the dev-toolchain container,
So that every command runs in an identical environment regardless of where it's invoked.

**Acceptance Criteria:**

**Given** the dev-toolchain container is available on GHCR
**When** the reference Makefile is created
**Then** `DEVRAIL_IMAGE ?= ghcr.io/devrail-dev/dev-toolchain:v1` is configurable at the top
**And** public targets (`lint`, `format`, `test`, `security`, `scan`, `docs`, `check`, `install-hooks`) delegate to Docker with workspace mounted
**And** internal targets (`_lint`, `_format`, `_test`, `_security`, `_scan`, `_docs`, `_check`) run the actual tool commands inside the container
**And** `make help` is the default target and auto-generates from `## description` comments
**And** the Makefile reads `.devrail.yml` to determine which languages are active
**And** file structure follows: variables → .PHONY → public targets → internal targets

### Story 3.2: Implement Lint and Format Targets

As a developer,
I want `make lint` and `make format` to run all language-appropriate linters and formatters,
So that code style is enforced consistently across all supported languages.

**Acceptance Criteria:**

**Given** the reference Makefile with delegation pattern exists
**When** `make lint` is run on a project with `.devrail.yml` declaring `languages: [python, bash]`
**Then** ruff check and shellcheck run against the appropriate file types
**And** only tools for declared languages execute — no errors for missing language files
**When** `make format` is run
**Then** ruff format and shfmt run against the appropriate file types
**And** each target outputs JSON summary with target, status, duration_ms
**And** exit code 0 on pass, 1 on failure, 2 on misconfiguration

### Story 3.3: Implement Test and Security Targets

As a developer,
I want `make test` and `make security` to run language-appropriate test suites and security scanners,
So that code correctness and security are validated consistently.

**Acceptance Criteria:**

**Given** the reference Makefile exists
**When** `make test` is run on a project declaring Python
**Then** pytest executes the project's test suite
**When** `make test` is run on a project declaring Terraform
**Then** terratest executes (if tests exist; graceful skip if no tests found)
**When** `make security` is run
**Then** bandit/semgrep runs for Python, tfsec/checkov runs for Terraform
**And** each target outputs JSON summary and uses correct exit codes

### Story 3.4: Implement Scan and Docs Targets

As a developer,
I want `make scan` for universal security scanning and `make docs` for documentation generation,
So that every project gets trivy/gitleaks coverage and Terraform projects get auto-generated docs.

**Acceptance Criteria:**

**Given** the reference Makefile exists
**When** `make scan` is run on any project
**Then** trivy runs filesystem/dependency scan and gitleaks runs secret detection
**When** `make docs` is run on a project declaring Terraform
**Then** terraform-docs generates and updates README documentation sections
**When** `make docs` is run on a project without Terraform
**Then** the target exits 0 with a "no docs targets configured" message
**And** each target outputs JSON summary and uses correct exit codes

### Story 3.5: Implement make check Orchestration

As a developer,
I want `make check` to run all targets with configurable error handling,
So that CI and agents see all issues at once while developers can opt for fast failure.

**Acceptance Criteria:**

**Given** all individual targets (lint, format, test, security, scan, docs) are implemented
**When** `make check` is run with default settings
**Then** all targets execute regardless of individual failures (run-all-report-all)
**And** a final JSON summary lists all targets with pass/fail status and total duration
**And** exit code is 0 only if all targets pass, 1 if any fail
**When** `DEVRAIL_FAIL_FAST=1` is set or `fail_fast: true` in `.devrail.yml`
**Then** execution stops at the first failure
**And** human-mode output is available via `DEVRAIL_LOG_FORMAT=human`

## Epic 4: Pre-Commit Enforcement

Every commit is validated locally — format, lint, conventional commits, secrets — before it hits the remote.

### Story 4.1: Verify and Update Conventional Commits Hook

As a developer,
I want the existing pre-commit-conventional-commits hook verified for DevRail compatibility and updated if needed,
So that conventional commit enforcement works reliably with pre-commit v3+.

**Acceptance Criteria:**

**Given** the existing pre-commit-conventional-commits repo at github.com/devrail-dev/
**When** the hook is reviewed and tested
**Then** it enforces the format `type(scope): description` with valid types (feat, fix, docs, chore, ci, refactor, test)
**And** it accepts the DevRail scopes (python, terraform, bash, ansible, container, ci, makefile)
**And** it is compatible with pre-commit framework v3+
**And** it rejects commits that don't match the format with a clear, actionable error message
**And** the repo is updated with DevRail standards (.devrail.yml, Makefile, agent instruction files)

### Story 4.2: Configure Language-Appropriate Linting and Formatting Hooks

As a developer,
I want pre-commit hooks that run fast linting and formatting checks on staged files before commit,
So that common issues are caught instantly without waiting for CI.

**Acceptance Criteria:**

**Given** the pre-commit framework is installed
**When** a `.pre-commit-config.yaml` is configured for a project declaring Python and Bash
**Then** ruff check runs on staged `.py` files
**And** ruff format --check runs on staged `.py` files
**And** shellcheck runs on staged `.sh` files
**And** shfmt --diff runs on staged `.sh` files
**When** a project declares Terraform
**Then** terraform fmt --check runs on staged `.tf` files
**And** tflint runs on staged `.tf` files
**And** all hooks complete within 30 seconds for typical changesets
**And** hooks only run tools for languages declared in `.devrail.yml`

### Story 4.3: Add Gitleaks and Terraform-Docs Hooks

As a developer,
I want gitleaks to prevent secrets from being committed and terraform-docs to auto-update READMEs,
So that secrets never reach the remote and Terraform documentation stays current automatically.

**Acceptance Criteria:**

**Given** the pre-commit config exists
**When** gitleaks hook is configured
**Then** it scans staged files for secrets, API keys, and credentials before every commit
**And** it blocks the commit with a clear message if secrets are detected
**When** terraform-docs hook is configured for a Terraform project
**Then** it auto-generates and updates the README with inputs, outputs, and resources on every commit
**And** if the README changes, the updated file is staged automatically
**And** both hooks complete within the 30-second budget

### Story 4.4: Create make install-hooks Target

As a developer,
I want a single `make install-hooks` command that sets up all pre-commit hooks for my project,
So that getting started with local enforcement is a one-command operation.

**Acceptance Criteria:**

**Given** a DevRail-compliant project with `.pre-commit-config.yaml`
**When** `make install-hooks` is run
**Then** pre-commit is installed (if not already present) and hooks are registered in `.git/hooks`
**And** the command is idempotent — safe to re-run
**And** it works on both macOS and Linux
**And** it provides clear output on success and clear error messages on failure
**And** running `git commit` after installation triggers all configured hooks

## Epic 5: GitLab Project Template

Developer creates a new GitLab project from the template and gets a fully configured repo with CI pipeline — zero setup.

### Story 5.1: Initialize GitLab Template with Core Configuration

As a developer,
I want a GitLab template repo with Makefile, .devrail.yml, EditorConfig, and .gitignore pre-configured,
So that new projects start with the right foundation files from the first commit.

**Acceptance Criteria:**

**Given** a new gitlab-repo-template repository
**When** the template is initialized
**Then** it contains a working Makefile with the two-layer delegation pattern referencing `ghcr.io/devrail-dev/dev-toolchain:v1`
**And** .devrail.yml is present with commented examples for all supported languages
**And** .editorconfig enforces indent style, line endings, and trailing whitespace
**And** .gitignore covers common patterns with per-language sections
**And** LICENSE file is included (MIT or user-configurable)

### Story 5.2: Add Pre-Commit Configuration

As a developer,
I want pre-commit hooks pre-configured in the GitLab template,
So that new projects enforce commit standards from the first commit.

**Acceptance Criteria:**

**Given** the gitlab-repo-template exists with core files
**When** .pre-commit-config.yaml is added
**Then** it configures conventional commits, language linting/formatting, gitleaks, and terraform-docs hooks
**And** hooks reference the DevRail pre-commit-conventional-commits repo
**And** the config includes clear comments explaining each hook's purpose
**And** `make install-hooks` is functional in the template

### Story 5.3: Add Agent Instruction Files

As a developer,
I want agent instruction files shipped with every new GitLab project,
So that any AI tool used on the project knows the standards from day one.

**Acceptance Criteria:**

**Given** the gitlab-repo-template exists
**When** agent instruction files are added
**Then** DEVELOPMENT.md is present with full standards and structured markers
**And** CLAUDE.md contains pointer to DEVELOPMENT.md plus critical rules inlined
**And** AGENTS.md contains equivalent content for generic agent consumption
**And** .cursorrules contains equivalent content for Cursor
**And** .opencode/agents.yaml contains equivalent content for OpenCode
**And** all shim files include the non-negotiable rules: run `make check`, conventional commits, no tools outside container

### Story 5.4: Create GitLab CI Pipeline with Parallel Jobs

As a developer,
I want a .gitlab-ci.yml that runs parallel check jobs using the dev-toolchain container,
So that every push and MR gets granular pass/fail feedback.

**Acceptance Criteria:**

**Given** the gitlab-repo-template exists with Makefile
**When** .gitlab-ci.yml is added
**Then** it defines parallel jobs for lint, format, security, test, and docs
**And** each job pulls `ghcr.io/devrail-dev/dev-toolchain:v1` and runs its corresponding `make` target
**And** job names match target names for clear status reporting
**And** MRs are blocked from merging if any job fails
**And** the pipeline runs on every push and MR event

### Story 5.5: Add MR Templates, CODEOWNERS, and README

As a developer,
I want merge request templates and CODEOWNERS pre-configured,
So that every MR follows a consistent format and code review routing is automatic.

**Acceptance Criteria:**

**Given** the gitlab-repo-template exists
**When** GitLab-specific files are added
**Then** .gitlab/merge_request_templates/default.md provides a structured MR template with summary, test plan, and checklist
**And** .gitlab/CODEOWNERS is present with placeholder structure
**And** README.md follows the standard structure: title, badges, quick start, usage, config, contributing, license
**And** CHANGELOG.md is initialized with Keep a Changelog format

### Story 5.6: Document Retrofit Path for Existing Repos

As a developer,
I want clear documentation on how to add DevRail to an existing GitLab repo,
So that I can standardize repos that weren't created from the template.

**Acceptance Criteria:**

**Given** the gitlab-repo-template is complete
**When** the retrofit documentation is written
**Then** README includes a "Retrofit Existing Project" section with step-by-step instructions
**And** instructions list which files to copy and in what order
**And** instructions explain how to configure .devrail.yml for the project's languages
**And** instructions include `make install-hooks` and first `make check` run as verification steps

## Epic 6: GitHub Project Template

Developer creates a new GitHub project from the template and gets a fully configured repo with CI pipeline — zero setup.

### Story 6.1: Initialize GitHub Template with Core Configuration

As a developer,
I want a GitHub template repo with Makefile, .devrail.yml, EditorConfig, and .gitignore pre-configured,
So that new projects start correct from the first commit.

**Acceptance Criteria:**

**Given** a new github-repo-template repository
**When** the template is initialized
**Then** it contains a working Makefile with the two-layer delegation pattern referencing `ghcr.io/devrail-dev/dev-toolchain:v1`
**And** .devrail.yml is present with commented examples for all supported languages
**And** .editorconfig, .gitignore, and LICENSE are configured
**And** the repo is configured as a GitHub template repository

### Story 6.2: Add Pre-Commit Configuration and Agent Instruction Files

As a developer,
I want pre-commit hooks and agent instruction files shipped with every new GitHub project,
So that commit standards and AI agent behavior are enforced from day one.

**Acceptance Criteria:**

**Given** the github-repo-template exists with core files
**When** pre-commit and agent files are added
**Then** .pre-commit-config.yaml configures all hooks (conventional commits, linting, formatting, gitleaks, terraform-docs)
**And** DEVELOPMENT.md, CLAUDE.md, AGENTS.md, .cursorrules, .opencode/agents.yaml are present
**And** all shim files include non-negotiable rules
**And** `make install-hooks` is functional

### Story 6.3: Create GitHub Actions Workflows with Parallel Jobs

As a developer,
I want GitHub Actions workflows that run parallel check jobs using the dev-toolchain container,
So that every push and PR gets granular pass/fail status checks.

**Acceptance Criteria:**

**Given** the github-repo-template exists with Makefile
**When** GitHub Actions workflow files are added
**Then** .github/workflows/ contains separate workflow files for lint, format, security, test, and docs
**And** each workflow pulls `ghcr.io/devrail-dev/dev-toolchain:v1` and runs its corresponding `make` target
**And** each workflow runs on push and pull_request events
**And** PRs are blocked from merging if any check fails (branch protection recommended in README)
**And** CI results are identical to local `make check` results

### Story 6.4: Add PR Template, CODEOWNERS, and README

As a developer,
I want pull request templates, CODEOWNERS, and documentation pre-configured,
So that every PR follows a consistent format and the project is well-documented from the start.

**Acceptance Criteria:**

**Given** the github-repo-template exists
**When** GitHub-specific files are added
**Then** .github/PULL_REQUEST_TEMPLATE.md provides a structured PR template
**And** .github/CODEOWNERS is present with placeholder structure
**And** README.md follows standard structure including a "Retrofit Existing Project" section
**And** CHANGELOG.md is initialized with Keep a Changelog format

## Epic 7: AI Agent Integration

AI agents (Claude Code, Cursor, OpenCode, BMAD) follow DevRail standards autonomously without human reminding.

### Story 7.1: Validate Claude Code Consumption of CLAUDE.md

As a developer,
I want to verify that Claude Code reads CLAUDE.md and follows DevRail standards correctly,
So that I can trust the agent to run checks and use conventional commits without reminding.

**Acceptance Criteria:**

**Given** a DevRail-templated project with CLAUDE.md
**When** Claude Code is given a coding task on the project
**Then** the agent reads CLAUDE.md and references DEVELOPMENT.md for full standards
**And** the agent produces conventional commits (type(scope): description format)
**And** the agent runs `make check` before marking work complete
**And** the agent does not attempt to install tools outside the container

### Story 7.2: Validate Multi-Tool Agent Instruction Consumption

As a developer,
I want to verify that Cursor, OpenCode, and generic agents each read their respective instruction files,
So that any AI tool used on a DevRail project inherits the standards.

**Acceptance Criteria:**

**Given** a DevRail-templated project with all agent instruction files
**When** Cursor is used on the project
**Then** it reads .cursorrules and follows DevRail standards
**When** OpenCode is used on the project
**Then** it reads .opencode/agents.yaml and follows DevRail standards
**When** a generic agent reads AGENTS.md
**Then** it can determine all project conventions, required checks, and commit standards

### Story 7.3: Validate BMAD Planning Integration

As a developer,
I want BMAD planning agents to incorporate DevRail standards into architecture and planning artifacts,
So that downstream implementation agents inherit the behavior automatically.

**Acceptance Criteria:**

**Given** a BMAD project planning session
**When** the user instructs the planning agent to use DevRail standards
**Then** the architecture document references DevRail Makefile contract and container
**And** the epics/stories include DevRail compliance in acceptance criteria
**And** implementation agents reading the planning artifacts know to follow DevRail standards
**And** the agent includes `make check` as a standard story completion gate

## Epic 8: Documentation Site

Anyone can discover DevRail, understand what it does, and get started at devrail.dev.

### Story 8.1: Initialize Hugo Site with Docsy Theme

As a visitor,
I want a professional documentation site scaffolded and deployable,
So that DevRail has a public home for guides and reference material.

**Acceptance Criteria:**

**Given** a new devrail.dev repository
**When** the Hugo site is initialized
**Then** Hugo is configured with Docsy theme via Go modules
**And** hugo.toml is configured with site title, description, and base URL (devrail.dev)
**And** the site builds successfully with `hugo` command
**And** the repo includes Makefile, .devrail.yml, .editorconfig, agent instruction files (dogfooding)
**And** content/_index.md has a landing page with project tagline and key value propositions

### Story 8.2: Write Getting Started and Standards Documentation

As a visitor,
I want getting started guides and standards reference pages,
So that I can adopt DevRail in minutes.

**Acceptance Criteria:**

**Given** the Hugo site is scaffolded
**When** documentation content is created
**Then** content/docs/getting-started/ contains a quick start guide (new project + retrofit)
**And** content/docs/standards/ contains per-language reference pages
**And** content/docs/container/ documents the dev-toolchain image usage
**And** content/docs/templates/ documents both GitHub and GitLab template usage
**And** all pages meet WCAG 2.1 Level A minimum (inherent in Docsy)
**And** all documentation is navigable without JavaScript

### Story 8.3: Write Contribution Guidelines and Deploy to Cloudflare

As a visitor,
I want contribution guidelines for the ecosystem and a live site at devrail.dev,
So that I can contribute to DevRail and the world can find it.

**Acceptance Criteria:**

**Given** the documentation content exists
**When** contribution docs and deployment are configured
**Then** content/docs/contributing/ documents how to add languages, submit PRs, and the ecosystem structure
**And** .github/workflows/deploy.yml deploys to Cloudflare Pages on push to main
**And** .github/workflows/ci.yml runs `make check` on PRs
**And** devrail.dev is live and accessible
**And** each ecosystem repo's contribution section links back to the site

## Epic 9: Dogfooding & Contributor Experience

All DevRail repos eat their own dog food, and new contributors can add language ecosystems following a clear pattern.

### Story 9.1: Apply DevRail Standards to All DevRail Repos

As a maintainer,
I want every DevRail ecosystem repo to use its own standards,
So that the ecosystem validates itself and demonstrates the pattern.

**Acceptance Criteria:**

**Given** all six DevRail repos exist
**When** DevRail standards are applied to each repo
**Then** every repo has .devrail.yml, Makefile, .pre-commit-config.yaml, .editorconfig, agent instruction files
**And** `make check` passes on every repo
**And** CI pipelines run on every repo
**And** pre-commit hooks are active on every repo
**And** all commits across the ecosystem use conventional commit format

### Story 9.2: Write Contribution Guide with Language Ecosystem Pattern

As a contributor,
I want clear documentation on how to add a new language ecosystem to DevRail,
So that I can contribute Go, Rails, or other language support following the established pattern.

**Acceptance Criteria:**

**Given** the established pattern (install script + Makefile targets + pre-commit hooks + standards doc)
**When** the contribution guide is written
**Then** it documents the step-by-step process: create install script, add Makefile targets, configure pre-commit hooks, write standards doc, add tests
**And** it references existing language scripts as examples
**And** it explains the PR process with conventional commits
**And** it is linked from every repo's DEVELOPMENT.md and the devrail.dev site

### Story 9.3: End-to-End Ecosystem Validation

As a maintainer,
I want to verify the entire ecosystem works end-to-end,
So that I can confidently release DevRail for public use.

**Acceptance Criteria:**

**Given** all DevRail repos are complete and standards-compliant
**When** end-to-end validation is performed
**Then** creating a new project from the GitLab template produces a repo where `make check` passes on first run
**And** creating a new project from the GitHub template produces a repo where `make check` passes on first run
**And** pushing to either template triggers CI that passes
**And** pre-commit hooks fire on first commit and enforce all rules
**And** an AI agent given the project follows standards without additional prompting

## Backlog — Post-MVP Stories

Stories added after MVP shipped to address gaps discovered during active use.

### Story 4.5: Update Conventional Commit Scopes for All Languages

As a developer,
I want the pre-commit conventional commits hook to accept all current language scopes,
So that commits for Ruby, Go, JavaScript, Rust, and new workflow scopes are not rejected.

**Acceptance Criteria:**

**Given** the pre-commit-conventional-commits hook repo at github.com/devrail-dev/
**When** the valid scopes list is updated
**Then** it accepts all language scopes: python, bash, terraform, ansible, ruby, go, javascript, rust
**And** it accepts all workflow scopes: container, ci, makefile, standards, security, changelog, release
**And** the updated hook version is referenced in both template repos' `.pre-commit-config.yaml`
**And** the dev-toolchain repo's `.pre-commit-config.yaml` references the updated hook
**And** `make check` passes on all repos after the update

**Repos:** pre-commit-conventional-commits, dev-toolchain, github-repo-template, gitlab-repo-template

### Story 2.6: Cut Dev-Toolchain Release for Post-v1.5.0 Features

As a maintainer,
I want to cut a proper minor release for all features merged since v1.5.0,
So that the published container image includes Rust, Terragrunt, fix target, pre-push hooks, tool version manifest, and the release script.

**Acceptance Criteria:**

**Given** all post-v1.5.0 features are merged to main and `make check` passes
**When** `make release VERSION=1.6.0` is run
**Then** CHANGELOG.md is updated with all [Unreleased] entries under [1.6.0]
**And** the tag v1.6.0 is created and pushed
**And** GitHub Actions builds and publishes the container image to GHCR
**And** the v1 floating tag is updated to point to v1.6.0
**And** the GitHub Release is created with release notes
**And** the tool version manifest is attached to the release

**Repos:** dev-toolchain
**Depends on:** Story 4.5 (so the release commit uses the correct scope)
