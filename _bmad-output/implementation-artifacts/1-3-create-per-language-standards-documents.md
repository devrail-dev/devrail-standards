# Story 1.3: Create Per-Language Standards Documents

Status: done

## Story

As a developer,
I want per-language standards documents that specify exact tools, configurations, and conventions for each supported language,
so that agents and developers know exactly which tools to use and how to configure them.

## Acceptance Criteria

1. **Given** the devrail-standards repo exists, **When** per-language documents are created, **Then** `standards/python.md` specifies ruff, ruff format, bandit/semgrep, pytest, mypy with config examples
2. **Given** the per-language documents are created, **Then** `standards/bash.md` specifies shellcheck, shfmt, bats with config examples
3. **Given** the per-language documents are created, **Then** `standards/terraform.md` specifies tflint, terraform fmt, tfsec/checkov, terratest, terraform-docs with config examples
4. **Given** the per-language documents are created, **Then** `standards/ansible.md` specifies ansible-lint, molecule with config examples
5. **Given** the per-language documents are created, **Then** `standards/universal.md` specifies trivy, gitleaks with config examples
6. **Given** all per-language documents exist, **Then** each document follows a consistent structure: tools table, configuration, Makefile targets, pre-commit hooks

## Tasks / Subtasks

- [x] Task 1: Define the consistent per-language document structure (AC: #6)
  - [x] 1.1: Design a template structure all per-language docs follow: overview → tools table → tool configs → Makefile targets → pre-commit hooks → notes
- [x] Task 2: Create standards/python.md (AC: #1)
  - [x] 2.1: Write tools table (ruff, ruff format, bandit, semgrep, pytest, mypy)
  - [x] 2.2: Write config examples for each tool (ruff.toml, pyproject.toml sections)
  - [x] 2.3: Document Makefile targets: `_lint` (ruff check), `_format` (ruff format), `_security` (bandit + semgrep), `_test` (pytest), type check (mypy)
  - [x] 2.4: Document pre-commit hook configuration for ruff + ruff format
- [x] Task 3: Create standards/bash.md (AC: #2)
  - [x] 3.1: Write tools table (shellcheck, shfmt, bats)
  - [x] 3.2: Write config examples (.shellcheckrc, shfmt flags)
  - [x] 3.3: Document Makefile targets: `_lint` (shellcheck), `_format` (shfmt), `_test` (bats)
  - [x] 3.4: Document pre-commit hook configuration for shellcheck + shfmt
- [x] Task 4: Create standards/terraform.md (AC: #3)
  - [x] 4.1: Write tools table (tflint, terraform fmt, tfsec, checkov, terratest, terraform-docs)
  - [x] 4.2: Write config examples (.tflint.hcl, tfsec flags, checkov flags)
  - [x] 4.3: Document Makefile targets: `_lint` (tflint), `_format` (terraform fmt), `_security` (tfsec + checkov), `_test` (terratest), `_docs` (terraform-docs)
  - [x] 4.4: Document pre-commit hook configuration for terraform fmt + tflint + terraform-docs
- [x] Task 5: Create standards/ansible.md (AC: #4)
  - [x] 5.1: Write tools table (ansible-lint, molecule)
  - [x] 5.2: Write config examples (.ansible-lint.yml, molecule config)
  - [x] 5.3: Document Makefile targets: `_lint` (ansible-lint), `_test` (molecule)
  - [x] 5.4: Document pre-commit hook configuration for ansible-lint
- [x] Task 6: Create standards/universal.md (AC: #5)
  - [x] 6.1: Write tools table (trivy, gitleaks)
  - [x] 6.2: Write config examples (trivy flags, .gitleaks.toml)
  - [x] 6.3: Document Makefile targets: `_scan` (trivy + gitleaks)
  - [x] 6.4: Document pre-commit hook configuration for gitleaks

## Dev Notes

### Critical Architecture Constraints

These documents define the **exact tool configurations** that the dev-toolchain container (Epic 2) will install and the Makefile contract (Epic 3) will invoke. The tool names, flags, and config formats specified here become the contract. Be precise.

### Consistent Document Structure

Every per-language document MUST follow this structure:

```markdown
# [Language] Standards

## Tools

| Concern | Tool | Version Strategy |
|---|---|---|
| Linter | tool-name | latest in container |

## Configuration

### [Tool Name]
[Config file format, recommended settings, example config]

## Makefile Targets

| Target | Command | Description |
|---|---|---|
| `_lint` | `tool-name args` | What it checks |

## Pre-Commit Hooks

[.pre-commit-config.yaml snippet for this language's hooks]

## Notes

[Language-specific conventions, gotchas, or tips]
```

### Tool Configuration Details

**Python (standards/python.md):**
- ruff: `ruff check .` for linting, `ruff format .` for formatting. Config in `ruff.toml` or `pyproject.toml [tool.ruff]`
- bandit: `bandit -r .` for security scanning. Config in `pyproject.toml [tool.bandit]`
- semgrep: `semgrep --config auto .` for additional security patterns
- pytest: `pytest` for test execution. Config in `pyproject.toml [tool.pytest.ini_options]`
- mypy: `mypy .` for type checking. Config in `pyproject.toml [tool.mypy]`

**Bash (standards/bash.md):**
- shellcheck: `shellcheck scripts/*.sh` for linting. Config in `.shellcheckrc`
- shfmt: `shfmt -d .` for format checking, `shfmt -w .` for formatting. Flags: `-i 2 -ci -bn`
- bats: `bats tests/` for test execution

**Terraform (standards/terraform.md):**
- tflint: `tflint --recursive` for linting. Config in `.tflint.hcl`
- terraform fmt: `terraform fmt -check -recursive` for format checking
- tfsec: `tfsec .` for security scanning
- checkov: `checkov -d .` for policy-as-code scanning
- terratest: Go-based tests in `tests/` directory
- terraform-docs: `terraform-docs markdown table . > README.md` for auto-generated docs

**Ansible (standards/ansible.md):**
- ansible-lint: `ansible-lint` for linting. Config in `.ansible-lint.yml`
- molecule: `molecule test` for role testing. Config in `molecule/default/`

**Universal (standards/universal.md):**
- trivy: `trivy fs .` for filesystem scanning, `trivy image <image>` for container scanning
- gitleaks: `gitleaks detect --source .` for secret detection. Config in `.gitleaks.toml`

### Pre-Commit Hook Split

Remember the architecture decision: **fast-local / slow-CI split**.

**Local (pre-commit) — must complete in < 30 seconds:**
- Formatting checks (ruff format, shfmt, terraform fmt)
- Linting (ruff check, shellcheck, tflint, ansible-lint)
- Conventional commits
- Gitleaks

**CI-only — runs in `make check`:**
- Security scanning (bandit, semgrep, tfsec, checkov, trivy)
- Full test suites (pytest, bats, terratest, molecule)
- terraform-docs generation

Each per-language doc should clearly mark which hooks are local vs CI-only.

**Source:** [architecture.md - Pre-commit Hook Strategy]

### Previous Story Intelligence

**Story 1.1 created:** `.devrail.yml`, `.editorconfig`, `.gitignore`, `LICENSE`, `Makefile`, `README.md`, `standards/devrail-yml-schema.md`

**Story 1.2 created:** `DEVELOPMENT.md` with structured markers covering all standards by concern and per-language sections.

**Build on previous stories:**
- The `standards/` directory already exists (from Story 1.1)
- DEVELOPMENT.md already has per-language marker sections — these detailed docs expand on those summaries
- Cross-reference DEVELOPMENT.md sections where appropriate rather than duplicating

### Project Structure Notes

This story creates 5 files in the existing `standards/` directory:

```
devrail-standards/
└── standards/
    ├── devrail-yml-schema.md  ← Story 1.1 (exists)
    ├── python.md              ← THIS STORY
    ├── bash.md                ← THIS STORY
    ├── terraform.md           ← THIS STORY
    ├── ansible.md             ← THIS STORY
    └── universal.md           ← THIS STORY
```

**DO NOT create or modify any files outside `standards/`.**

### Anti-Patterns to Avoid

1. **DO NOT** include actual config files (ruff.toml, .shellcheckrc) — document the recommended config content, but the actual files belong in template repos
2. **DO NOT** include tool installation instructions — tools are pre-installed in the container
3. **DO NOT** specify exact tool versions — the container manages versions, these docs specify the tool names and flags
4. **DO NOT** make documents excessively long — these are reference documents, not tutorials
5. **DO NOT** duplicate content already in DEVELOPMENT.md — reference it instead

### Conventional Commits for This Story

- Scope: `standards`
- Example: `feat(standards): add per-language standards documents for Python, Bash, Terraform, Ansible`

### References

- [architecture.md - Shell Script Conventions]
- [architecture.md - Pre-commit Hook Strategy]
- [architecture.md - Output & Logging Conventions]
- [prd.md - Language Support Matrix]
- [prd.md - Functional Requirements FR4]
- [epics.md - Epic 1: Standards Foundation - Story 1.3]
- [Story 1.1 - standards/ directory created]
- [Story 1.2 - DEVELOPMENT.md per-language marker sections]

## Senior Developer Review (AI)

**Reviewer:** Claude Opus 4.6 (adversarial review)
**Date:** 2026-02-20
**Verdict:** PASS

### Acceptance Criteria Verification

| AC | Status | Notes |
|---|---|---|
| AC1 | IMPLEMENTED | standards/python.md specifies ruff, ruff format, bandit, semgrep, pytest, mypy with config examples |
| AC2 | IMPLEMENTED | standards/bash.md specifies shellcheck, shfmt, bats with config examples |
| AC3 | IMPLEMENTED | standards/terraform.md specifies tflint, terraform fmt, tfsec, checkov, terratest, terraform-docs |
| AC4 | IMPLEMENTED | standards/ansible.md specifies ansible-lint, molecule with config examples |
| AC5 | IMPLEMENTED | standards/universal.md specifies trivy, gitleaks with config examples |
| AC6 | IMPLEMENTED | All docs follow consistent structure: Tools table, Configuration, Makefile Targets, Pre-Commit Hooks, Notes |

### Findings

1. **LOW - Consistent document structure verified.** All five documents follow the same template: Tools table with Version Strategy column, Configuration section with per-tool subsections, Makefile Targets table, Pre-Commit Hooks split into Local and CI-Only, Notes section.
2. **LOW - Pre-commit hook split correctly documented.** Each doc clearly marks which hooks are local (< 30s) vs CI-only, matching the architecture decision.
3. **LOW - Cross-references to DEVELOPMENT.md present.** Each doc links back to DEVELOPMENT.md for the full Makefile contract.
4. **LOW - No tool installation instructions included.** Correctly follows anti-pattern guidance.
5. **LOW - ruff.toml config example in python.md is well-structured.** Includes select list with explanatory comments for each rule set.

### Files Modified During Review

None.

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (claude-opus-4-6)

### Debug Log References

None -- clean implementation with no errors or retries.

### Completion Notes List

- All 5 per-language standards documents created in `standards/` directory
- Every document follows the consistent structure: Tools table, Configuration, Makefile Targets, Pre-Commit Hooks (split into Local and CI-Only), Notes
- Pre-commit hooks clearly marked as local (< 30s) vs CI-only per architecture decision
- Documents reference DEVELOPMENT.md rather than duplicating content
- No tool installation instructions, no exact versions, no actual config files created
- Config examples are documented inline as recommended content for template repos

### File List

- `standards/python.md` -- ruff, ruff format, bandit, semgrep, pytest, mypy
- `standards/bash.md` -- shellcheck, shfmt, bats
- `standards/terraform.md` -- tflint, terraform fmt, tfsec, checkov, terratest, terraform-docs
- `standards/ansible.md` -- ansible-lint, molecule
- `standards/universal.md` -- trivy, gitleaks
