# Story 1.2: Write Canonical DEVELOPMENT.md with Structured Markers

Status: done

## Story

As a developer,
I want a single DEVELOPMENT.md that contains all DevRail standards with machine-readable markers,
so that both humans and automated tools can extract and reference specific sections.

## Acceptance Criteria

1. **Given** the devrail-standards repo exists, **When** DEVELOPMENT.md is created, **Then** it contains all development standards organized by concern (linting, formatting, security, testing, commits)
2. **Given** DEVELOPMENT.md is created, **When** critical rules sections are examined, **Then** they are wrapped in `<!-- devrail:critical-rules -->` / `<!-- /devrail:critical-rules -->` markers
3. **Given** DEVELOPMENT.md is created, **When** per-language sections are examined, **Then** they are wrapped in corresponding markers (e.g., `<!-- devrail:python -->` / `<!-- /devrail:python -->`)
4. **Given** DEVELOPMENT.md is created, **When** the document is rendered as standard markdown, **Then** markers are invisible and the document reads cleanly for humans

## Tasks / Subtasks

- [x] Task 1: Design the DEVELOPMENT.md document structure and marker scheme (AC: #2, #3, #4)
  - [x] 1.1: Define the complete list of marker section names
  - [x] 1.2: Design the document outline — section order, headings, nesting
  - [x] 1.3: Ensure markers are paired open/close HTML comments that render invisibly
- [x] Task 2: Write the critical rules section (AC: #1, #2)
  - [x] 2.1: Write the non-negotiable rules under `<!-- devrail:critical-rules -->` markers
  - [x] 2.2: Include: run `make check` before completing work, use conventional commits, never install tools outside the container, respect `.editorconfig`
- [x] Task 3: Write the standards-by-concern sections (AC: #1)
  - [x] 3.1: Write the Makefile contract section (targets, two-layer pattern, naming, exit codes)
  - [x] 3.2: Write the shell script conventions section (set -euo pipefail, idempotency, logging, getopts, shellcheck)
  - [x] 3.3: Write the configuration section (.devrail.yml reference, .editorconfig rules)
  - [x] 3.4: Write the output and logging conventions section (JSON default, exit codes, verbosity)
  - [x] 3.5: Write the documentation patterns section (README structure, comments, conventional commits, changelog)
- [x] Task 4: Write per-language standards sections with markers (AC: #1, #3)
  - [x] 4.1: Write `<!-- devrail:python -->` section (ruff, bandit/semgrep, pytest, mypy)
  - [x] 4.2: Write `<!-- devrail:bash -->` section (shellcheck, shfmt, bats)
  - [x] 4.3: Write `<!-- devrail:terraform -->` section (tflint, terraform fmt, tfsec/checkov, terratest, terraform-docs)
  - [x] 4.4: Write `<!-- devrail:ansible -->` section (ansible-lint, molecule)
  - [x] 4.5: Write `<!-- devrail:universal -->` section (trivy, gitleaks)
- [x] Task 5: Write the agent enforcement section (AC: #1, #2)
  - [x] 5.1: Write the agent enforcement guidelines (what ALL agents must do)
  - [x] 5.2: Reference the shim file strategy (detailed in Story 1.4)

## Dev Notes

### Critical Architecture Constraints

**DEVELOPMENT.md is the single canonical source of truth for all DevRail standards.** Every agent instruction file (CLAUDE.md, AGENTS.md, .cursorrules, .opencode/) will point to this document. Every template repo will ship a copy. The content and structure defined here propagates throughout the entire ecosystem.

**The markers defined here become a machine-readable API.** Future tooling may extract sections automatically. Choose marker names carefully — they become part of the contract.

**Source:** [architecture.md - Agent Instruction Architecture]

### Structured Marker Specification

**Format:** HTML comments with paired open/close tags.

```markdown
<!-- devrail:section-name -->
Content here is extractable by tooling
<!-- /devrail:section-name -->
```

**Required markers (minimum set):**

| Marker | Purpose |
|---|---|
| `<!-- devrail:critical-rules -->` | Non-negotiable rules every agent must follow |
| `<!-- devrail:makefile-contract -->` | Makefile target contract and patterns |
| `<!-- devrail:shell-conventions -->` | Shell script standards |
| `<!-- devrail:python -->` | Python tooling and conventions |
| `<!-- devrail:bash -->` | Bash tooling and conventions |
| `<!-- devrail:terraform -->` | Terraform tooling and conventions |
| `<!-- devrail:ansible -->` | Ansible tooling and conventions |
| `<!-- devrail:universal -->` | Universal tools (trivy, gitleaks) |
| `<!-- devrail:commits -->` | Conventional commit rules |
| `<!-- devrail:logging -->` | Logging and output conventions |

**Rules:**
- Every open tag MUST have a matching close tag
- Markers MUST NOT nest (no markers inside markers) — keep it flat and simple
- Markers are invisible when rendered in any standard markdown viewer
- Content between markers must be self-contained and meaningful when extracted alone

**Source:** [architecture.md - Configuration File Formats - DEVELOPMENT.md markers]

### Critical Rules Content

The `<!-- devrail:critical-rules -->` section MUST contain these non-negotiable rules that get inlined in every agent shim file:

1. **Run `make check` before completing any story or task** — never mark work done without passing checks
2. **Use conventional commits** — `type(scope): description` format for all commits
3. **Never install tools outside the container** — all tools run inside `ghcr.io/devrail-dev/dev-toolchain:v1`
4. **Respect `.editorconfig`** — never override formatting without explicit instruction
5. **Write idempotent scripts** — check before acting, safe to re-run
6. **Use shared logging library** — no raw `echo` for status messages

**Source:** [architecture.md - Enforcement Guidelines]

### Shell Script Conventions to Document

The shell conventions section must capture ALL of these patterns from the architecture:

- `#!/usr/bin/env bash` + `set -euo pipefail` — always
- **Idempotent by default** — `command -v tool || install_tool`, `mkdir -p`, guard file writes
- Variables: `UPPER_SNAKE_CASE` for env/constants with `readonly`, `lower_snake_case` for locals
- Functions: `lower_snake_case`, prefixed by purpose (`install_`, `check_`, `log_`)
- Argument parsing via getopts; every script supports `--help`
- Shellcheck compliant — enforced by lint target
- Python CLIs use Click

**Shared Library (`lib/`):**
- `lib/log.sh` — `log_info`, `log_warn`, `log_error`, `log_debug`, `die`
- `lib/platform.sh` — `on_mac`, `on_linux`, `on_arm64`
- JSON output by default: `{"level":"info","msg":"...","script":"...","ts":"..."}`
- Human-readable via `DEVRAIL_LOG_FORMAT=human`
- Three verbosity levels: quiet (`DEVRAIL_QUIET=1`), normal, debug (`DEVRAIL_DEBUG=1`)
- All log output to stderr — stdout reserved for tool output

**Validation & Helpers:** `is_empty`, `is_not_empty`, `is_set`, `require_cmd`

**Cleanup & Safety:** Trap handlers (`trap cleanup EXIT`), temp files via `mktemp` only, no interactive prompts

**Self-Documenting Scripts:** Structured header comment (purpose, usage, dependencies), `--help` auto-extracts usage

**Source:** [architecture.md - Shell Script Conventions]

### Makefile Contract to Document

- Public targets: `lower-kebab-case`. Internal: `_`-prefix
- No abbreviations — `security` not `sec`, `format` not `fmt`
- Every public target: `## description` comment for `make help` auto-generation
- `make help` as default target
- Variables: `UPPER_SNAKE_CASE`, overridable with `?=`
- File structure: variables → `.PHONY` → public targets → internal targets
- Target contract: `lint`, `format`, `test`, `security`, `scan`, `docs`, `check`, `install-hooks`
- Two-layer delegation: public targets delegate to Docker, `_`-prefixed targets run inside container

**Source:** [architecture.md - Makefile Authoring Patterns]

### Per-Language Tool Matrix

Each per-language section must reference the exact tools:

| Concern | Python | Bash | Terraform | Ansible |
|---|---|---|---|---|
| Linter | ruff | shellcheck | tflint | ansible-lint |
| Formatter | ruff format | shfmt | terraform fmt | — |
| Security | bandit, semgrep | — | tfsec, checkov | — |
| Tests | pytest | bats | terratest | molecule |
| Type Check | mypy | — | — | — |
| Docs | — | — | terraform-docs | — |
| Universal | trivy, gitleaks | trivy, gitleaks | trivy, gitleaks | trivy, gitleaks |

**Source:** [prd.md - Language Support Matrix]

### Conventional Commits to Document

- Format: `type(scope): description`
- Types: `feat`, `fix`, `docs`, `chore`, `ci`, `refactor`, `test`
- Scopes: `python`, `terraform`, `bash`, `ansible`, `container`, `ci`, `makefile`, `standards`
- Changelog: auto-generated from conventional commits, Keep a Changelog format
- TODO format: `# TODO(devrail#123): description`

**Source:** [architecture.md - Documentation Patterns]

### Output & Logging Conventions to Document

- Each Makefile target: JSON summary with `target`, `status`, `duration_ms`, `errors` array
- `make check`: final summary of all targets with pass/fail and total duration
- Human mode: simple table with status indicators
- Exit codes: `0` (pass), `1` (failure), `2` (misconfiguration)
- CI: job names match target names, JSON to artifact files, exit codes propagated
- Pre-commit: human format by default

**Source:** [architecture.md - Output & Logging Conventions]

### Previous Story Intelligence

**Story 1.1 creates these files that will already exist when Story 1.2 executes:**
- `.devrail.yml` — repo's own config (declares `languages: [bash]`)
- `.editorconfig` — formatting rules
- `.gitignore` — ignore patterns
- `LICENSE` — MIT license
- `Makefile` — two-layer delegation pattern with placeholder internal targets
- `README.md` — stub with standard structure
- `standards/devrail-yml-schema.md` — complete `.devrail.yml` schema spec

**Build on Story 1.1, don't duplicate:**
- Reference the `.devrail.yml` schema doc from the configuration section rather than re-documenting the schema
- The Makefile pattern is already established — document the contract, don't rewrite the file
- The `standards/` directory already exists

### Project Structure Notes

This story creates ONE file in the devrail-standards repo:

```
devrail-standards/
├── .devrail.yml              ← Story 1.1 (exists)
├── .editorconfig             ← Story 1.1 (exists)
├── .gitignore                ← Story 1.1 (exists)
├── DEVELOPMENT.md            ← THIS STORY
├── LICENSE                   ← Story 1.1 (exists)
├── Makefile                  ← Story 1.1 (exists)
├── README.md                 ← Story 1.1 (exists)
└── standards/
    └── devrail-yml-schema.md ← Story 1.1 (exists)
```

**DO NOT create or modify any other files.** Only create `DEVELOPMENT.md`.

### Document Outline (Suggested Structure)

```markdown
# DevRail Development Standards

<!-- devrail:critical-rules -->
## Critical Rules
[Non-negotiable rules for all agents and developers]
<!-- /devrail:critical-rules -->

<!-- devrail:makefile-contract -->
## Makefile Contract
[Target names, delegation pattern, naming conventions]
<!-- /devrail:makefile-contract -->

<!-- devrail:shell-conventions -->
## Shell Script Conventions
[Bash standards, idempotency, logging, helpers]
<!-- /devrail:shell-conventions -->

<!-- devrail:logging -->
## Output & Logging
[JSON format, exit codes, verbosity levels]
<!-- /devrail:logging -->

<!-- devrail:commits -->
## Conventional Commits
[Commit format, types, scopes, changelog]
<!-- /devrail:commits -->

## Language Standards

<!-- devrail:python -->
### Python
[ruff, bandit/semgrep, pytest, mypy]
<!-- /devrail:python -->

<!-- devrail:bash -->
### Bash
[shellcheck, shfmt, bats]
<!-- /devrail:bash -->

<!-- devrail:terraform -->
### Terraform
[tflint, terraform fmt, tfsec/checkov, terratest, terraform-docs]
<!-- /devrail:terraform -->

<!-- devrail:ansible -->
### Ansible
[ansible-lint, molecule]
<!-- /devrail:ansible -->

<!-- devrail:universal -->
### Universal Tools
[trivy, gitleaks]
<!-- /devrail:universal -->
```

**This is a suggested outline, not a rigid template.** The dev agent should use judgment on heading levels, content depth, and flow — but all marker sections and content areas listed above MUST be present.

### Anti-Patterns to Avoid

1. **DO NOT** create tool configuration files (ruff.toml, .shellcheckrc, etc.) — those belong in template repos, not the standards doc
2. **DO NOT** include installation instructions for tools — all tools come pre-installed in the container
3. **DO NOT** duplicate the `.devrail.yml` schema — reference `standards/devrail-yml-schema.md` instead
4. **DO NOT** nest markers inside markers — keep the marker scheme flat
5. **DO NOT** make the document excessively verbose — this is a reference document, not a tutorial. Be precise and direct.
6. **DO NOT** create CLAUDE.md, AGENTS.md, or other agent shim files — those are Story 1.4
7. **DO NOT** modify the Makefile or any Story 1.1 files

### Conventional Commits for This Story

- Scope: `standards`
- Example: `feat(standards): write canonical DEVELOPMENT.md with structured markers`

### References

- [architecture.md - Agent Instruction Architecture]
- [architecture.md - Configuration File Formats - DEVELOPMENT.md markers]
- [architecture.md - Enforcement Guidelines]
- [architecture.md - Shell Script Conventions]
- [architecture.md - Makefile Authoring Patterns]
- [architecture.md - Output & Logging Conventions]
- [architecture.md - Documentation Patterns]
- [prd.md - Language Support Matrix]
- [prd.md - Functional Requirements FR1, FR2, FR3, FR4]
- [epics.md - Epic 1: Standards Foundation - Story 1.2]
- [Story 1.1 - files created and patterns established]

## Senior Developer Review (AI)

**Reviewer:** Claude Opus 4.6 (adversarial review)
**Date:** 2026-02-20
**Verdict:** PASS with minor findings

### Acceptance Criteria Verification

| AC | Status | Notes |
|---|---|---|
| AC1 | IMPLEMENTED | DEVELOPMENT.md contains all standards organized by concern |
| AC2 | IMPLEMENTED | Critical rules wrapped in `<!-- devrail:critical-rules -->` markers |
| AC3 | IMPLEMENTED | Per-language sections wrapped in corresponding markers |
| AC4 | IMPLEMENTED | Markers are invisible HTML comments; document reads cleanly |

### Findings

1. **LOW - All 10 marker pairs present and correctly closed.** Verified: critical-rules, makefile-contract, shell-conventions, logging, commits, python, bash, terraform, ansible, universal. All flat (no nesting).
2. **LOW - Markers are invisible when rendered.** Confirmed HTML comment syntax renders invisibly in standard markdown viewers.
3. **MEDIUM - QUIET verbosity description inaccurate (FIXED).** DEVELOPMENT.md stated "Suppress all output except errors" for DEVRAIL_QUIET=1, but the architecture and implementation suppress info only (warnings still show). Fixed to: "Suppress info messages; show warnings and errors only."
4. **LOW - Configuration section correctly references schema doc.** Links to `standards/devrail-yml-schema.md` rather than duplicating schema content.
5. **LOW - Agent Enforcement section present.** Includes hybrid shim strategy reference and six enforcement guidelines.

### Files Modified During Review

- `DEVELOPMENT.md` -- corrected QUIET mode description in verbosity table

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6

### Debug Log References

N/A

### Completion Notes List

- Created DEVELOPMENT.md at the repo root with all 10 required marker pairs (critical-rules, makefile-contract, shell-conventions, logging, commits, python, bash, terraform, ansible, universal)
- All markers are flat (no nesting) and use paired open/close HTML comment tags
- Content sourced from architecture.md sections: Enforcement Guidelines, Makefile Authoring Patterns, Shell Script Conventions, Output & Logging Conventions, Documentation Patterns, and per-language tool matrix
- Configuration section references `standards/devrail-yml-schema.md` rather than duplicating the schema (per anti-pattern guidance)
- Added Agent Enforcement section referencing the hybrid shim strategy (detailed implementation in Story 1.4)
- Document is human-readable as standard markdown (markers are invisible when rendered) and machine-parseable via marker extraction
- No Story 1.1 files were modified; only DEVELOPMENT.md was created

### File List

- `DEVELOPMENT.md` -- canonical development standards with 10 structured marker sections
