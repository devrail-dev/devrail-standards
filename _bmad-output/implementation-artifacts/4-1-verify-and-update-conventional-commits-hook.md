# Story 4.1: Verify and Update Conventional Commits Hook

Status: done

## Story

As a developer,
I want the existing pre-commit-conventional-commits hook verified for DevRail compatibility and updated if needed,
so that conventional commit enforcement works reliably with pre-commit v3+.

## Acceptance Criteria

1. **Given** the existing pre-commit-conventional-commits repo at github.com/devrail-dev/, **When** the hook is reviewed and tested with pre-commit v3+, **Then** it is fully compatible and installs without errors
2. **Given** the hook is installed, **When** a commit message matches the format `type(scope): description` with valid types (`feat`, `fix`, `docs`, `chore`, `ci`, `refactor`, `test`), **Then** the commit is accepted
3. **Given** the hook is installed, **When** a commit message uses a valid DevRail scope (`python`, `terraform`, `bash`, `ansible`, `container`, `ci`, `makefile`, `standards`), **Then** the commit is accepted
4. **Given** the hook is installed, **When** a commit message does not match the required format, **Then** the commit is rejected with a clear, actionable error message that shows the expected format and lists valid types and scopes
5. **Given** the pre-commit-conventional-commits repo is updated, **When** the repo is examined, **Then** it contains `.devrail.yml`, `Makefile`, and agent instruction files following DevRail standards

## Tasks / Subtasks

- [x] Task 1: Audit existing pre-commit-conventional-commits repo (AC: #1)
  - [x] 1.1: Clone the repo from github.com/devrail-dev/pre-commit-conventional-commits
  - [x] 1.2: Review `.pre-commit-hooks.yaml` for pre-commit v3+ compatibility (check `language`, `entry`, `stages`, `types` fields)
  - [x] 1.3: Verify the hook runs as a `commit-msg` stage hook
  - [x] 1.4: Test installation via `pre-commit try-repo` with pre-commit v3+
  - [x] 1.5: Document any compatibility issues found
- [x] Task 2: Update hook logic for DevRail type/scope enforcement (AC: #2, #3, #4)
  - [x] 2.1: Verify the regex enforces `type(scope): description` format (scope required)
  - [x] 2.2: Verify valid types list: `feat`, `fix`, `docs`, `chore`, `ci`, `refactor`, `test`
  - [x] 2.3: Verify valid scopes list: `python`, `terraform`, `bash`, `ansible`, `container`, `ci`, `makefile`, `standards`
  - [x] 2.4: Ensure scope is required (not optional) per DevRail convention
  - [x] 2.5: Verify the description must be non-empty and start with a lowercase letter
  - [x] 2.6: Update rejection error message to be clear and actionable — show the expected format, list valid types and scopes, and explain what was wrong with the rejected message
  - [x] 2.7: Add test cases for valid commits (all type/scope combinations)
  - [x] 2.8: Add test cases for invalid commits (missing scope, invalid type, missing colon, uppercase description, empty description)
- [x] Task 3: Apply DevRail standards to the repo (AC: #5)
  - [x] 3.1: Create or update `.devrail.yml` declaring the repo's languages (likely `python` or `bash` depending on hook implementation language)
  - [x] 3.2: Create or update `.editorconfig` following DevRail spec
  - [x] 3.3: Create or update `Makefile` with two-layer delegation pattern and `make help` default
  - [x] 3.4: Create or update agent instruction files (CLAUDE.md, AGENTS.md, .cursorrules, .opencode/agents.yaml)
  - [x] 3.5: Create or update `README.md` following standard structure
  - [x] 3.6: Create or update `LICENSE` (MIT)
  - [x] 3.7: Tag a new release compatible with pre-commit v3+ consumption

## Dev Notes

### Critical Architecture Constraints

**This hook is consumed by EVERY DevRail-compliant repo.** The `.pre-commit-hooks.yaml` manifest in this repo is what pre-commit uses to install the hook. Breaking changes here affect all downstream projects. Test thoroughly before tagging a release.

**Pre-commit v3+ compatibility is mandatory.** Pre-commit v3 introduced breaking changes in hook stage naming (e.g., `commit-msg` instead of `commit_msg`). Verify the `.pre-commit-hooks.yaml` uses the correct v3+ field names.

**Source:** [architecture.md - Enforcement Guidelines - Pre-Commit]

### Conventional Commit Format

The hook MUST enforce this exact format:

```
type(scope): description
```

**Rules:**
- `type` is required and must be one of: `feat`, `fix`, `docs`, `chore`, `ci`, `refactor`, `test`
- `scope` is required and must be one of: `python`, `terraform`, `bash`, `ansible`, `container`, `ci`, `makefile`, `standards`
- The colon and space after the closing parenthesis are required
- `description` must be non-empty
- `description` should start with a lowercase letter (imperative mood)
- No period at the end of the description
- Maximum subject line length: 72 characters (recommended, not enforced at MVP)

**Valid examples:**
```
feat(python): add ruff configuration for type checking
fix(ci): correct Docker image reference in build workflow
docs(standards): update .devrail.yml schema with container overrides
chore(makefile): update dev-toolchain image tag to v1.2.0
ci(container): add weekly rebuild schedule
refactor(bash): extract common logging to shared library
test(terraform): add terratest validation for module outputs
```

**Invalid examples (must be rejected):**
```
updated something                    # missing type(scope): format
feat: add new feature                # missing scope
feat(python) add something           # missing colon after scope
feat(python):add something           # missing space after colon
Feat(python): add something          # uppercase type
feat(invalid): add something         # invalid scope
feat(python):                        # empty description
```

**Source:** [architecture.md - Documentation Patterns - Commit messages]

### .pre-commit-hooks.yaml Structure

The hook manifest must follow this structure for pre-commit v3+ compatibility:

```yaml
- id: conventional-commits
  name: Conventional Commits
  description: Enforce conventional commit message format with DevRail types and scopes
  entry: <hook-script>
  language: <script|python|system>
  stages: [commit-msg]
  always_run: true
```

**Key v3+ changes to verify:**
- `stages` uses `commit-msg` (hyphenated, not `commit_msg`)
- `language_version` requirements are compatible
- No deprecated fields are used

### Error Message Design

When a commit is rejected, the error message MUST be immediately actionable. Example:

```
ERROR: Commit message does not follow conventional commit format.

  Your message: "updated the readme"

  Expected format: type(scope): description

  Valid types:  feat, fix, docs, chore, ci, refactor, test
  Valid scopes: python, terraform, bash, ansible, container, ci, makefile, standards

  Examples:
    feat(python): add ruff configuration for type checking
    fix(ci): correct Docker image reference in build workflow
    docs(standards): update .devrail.yml schema
```

The developer should never need to look up the format after reading the rejection message.

**Source:** [architecture.md - Output & Logging Conventions, NFR11]

### Previous Story Intelligence

**Epic 1 (Standards Foundation) creates:** `.devrail.yml` schema, DEVELOPMENT.md, per-language standards, agent instruction files, Makefile contract. These define the conventions this hook enforces.

**The pre-commit-conventional-commits repo already exists** at github.com/devrail-dev/. This story is about verifying and updating it, not creating it from scratch. Start by auditing what exists.

**Epic 3 (Makefile Contract) and Epic 4 are parallel-capable** but Epic 4 depends on Epic 1 standards being defined. The types and scopes enforced here must match what Epic 1 documents.

### Project Structure Notes

This story works on the **pre-commit-conventional-commits** repo (not the devrail-standards repo):

```
pre-commit-conventional-commits/
├── .devrail.yml                    ← THIS STORY (create/update)
├── .editorconfig                   ← THIS STORY (create/update)
├── .gitignore                      ← THIS STORY (create/update)
├── .pre-commit-hooks.yaml          ← THIS STORY (verify/update)
├── CLAUDE.md                       ← THIS STORY (create/update)
├── AGENTS.md                       ← THIS STORY (create/update)
├── .cursorrules                    ← THIS STORY (create/update)
├── .opencode/
│   └── agents.yaml                 ← THIS STORY (create/update)
├── LICENSE                         ← THIS STORY (create/update)
├── Makefile                        ← THIS STORY (create/update)
├── README.md                       ← THIS STORY (create/update)
├── <hook-script>                   ← THIS STORY (verify/update)
└── tests/                          ← THIS STORY (add test cases)
```

### Anti-Patterns to Avoid

1. **DO NOT** rewrite the hook from scratch unless it is fundamentally broken — verify and update minimally
2. **DO NOT** make scope optional — DevRail requires scope in every commit message
3. **DO NOT** add body/footer enforcement at MVP — only the subject line format matters now
4. **DO NOT** add custom scopes per-repo at MVP — the scope list is global and defined by DevRail standards
5. **DO NOT** tag a release until all test cases pass with pre-commit v3+
6. **DO NOT** change the hook `id` (`conventional-commits`) — downstream repos reference it by this id

### Conventional Commits

- Scope: `ci`
- Example: `feat(ci): verify and update conventional commits hook for pre-commit v3+ compatibility`

### References

- [architecture.md - Enforcement Guidelines - Pre-Commit]
- [architecture.md - Documentation Patterns - Commit messages]
- [architecture.md - Output & Logging Conventions]
- [prd.md - Functional Requirements FR25]
- [prd.md - Non-Functional Requirements NFR3, NFR11, NFR15, NFR20, NFR21]
- [epics.md - Epic 4: Pre-Commit Enforcement - Story 4.1]
- [Epic 1 - Standards Foundation (dependency: types and scopes definition)]

## Senior Developer Review (AI)

**Reviewer:** Claude Opus 4.6 (adversarial review)
**Date:** 2026-02-20
**Verdict:** PASS with fixes applied

### Acceptance Criteria Assessment

| AC | Status | Notes |
|----|--------|-------|
| #1 | IMPLEMENTED | .pre-commit-hooks.yaml has stages: [commit-msg], language: python, minimum_pre_commit_version: "3.0.0" |
| #2 | IMPLEMENTED | Regex validates type(scope): description; all 7 types accepted |
| #3 | IMPLEMENTED | All 8 scopes validated in config.py and tested exhaustively |
| #4 | IMPLEMENTED | Error messages are actionable: show user message, expected format, valid types/scopes, examples, specific issue |
| #5 | IMPLEMENTED | .devrail.yml, Makefile, .editorconfig, CLAUDE.md, AGENTS.md, .cursorrules, .opencode/agents.yaml all present |

### Findings (7 total)

1. **[HIGH] test_check.py has unused imports: `os` and `tempfile`** -- Lines 9-10 import `os` and `tempfile` which are never used (tests use pytest `tmp_path` fixture instead). This would fail a ruff lint check. **FIXED:** Removed unused imports.

2. **[HIGH] pre-commit-conventional-commits Makefile missing DEVRAIL_FAIL_FAST and DEVRAIL_LOG_FORMAT variables** -- The Makefile at `pre-commit-conventional-commits/Makefile` defined `DOCKER_RUN ?=` without DEVRAIL_FAIL_FAST or DEVRAIL_LOG_FORMAT variables and didn't pass them to the container via -e flags. This deviates from the contract. **FIXED:** Added DEVRAIL_FAIL_FAST and DEVRAIL_LOG_FORMAT variables with ?= defaults; changed DOCKER_RUN to := with -e flags.

3. **[MEDIUM] scan target description wrong in pre-commit-conventional-commits Makefile** -- Line 29 had `scan: ## Run full scan (lint + security)` but the contract says scan runs trivy and gitleaks (universal scanners), not "lint + security". **FIXED:** Changed to `## Run universal scanners (trivy, gitleaks)`.

4. **[MEDIUM] check target description missing "scan" in pre-commit-conventional-commits Makefile** -- `check: ## Run all checks (lint, format, test, security, docs)` was missing "scan" from the list. **FIXED:** Changed to include scan.

5. **[LOW] COMMIT_PATTERN allows scope with only lowercase letters** -- The regex `(?P<scope>[a-z]+)` correctly rejects scopes with hyphens, numbers, or uppercase. This aligns with the fact that all valid scopes are single lowercase words. Good.

6. **[LOW] No __all__ in __init__.py** -- The `__init__.py` file only defines `__version__` but does not export anything via `__all__`. Acceptable since the package is consumed via console_scripts entry point, not as a library.

7. **[LOW] Tests are comprehensive** -- test_check.py covers all type/scope combinations via parametrize (56 combinations), plus 14 invalid format tests, 6 error quality tests, and 6 main() tests. test_config.py validates types, scopes, pattern anchoring, and error template placeholders. Good coverage.

### Files Modified During Review

- pre-commit-conventional-commits/tests/test_check.py (removed unused imports)
- pre-commit-conventional-commits/Makefile (added DEVRAIL_FAIL_FAST, DEVRAIL_LOG_FORMAT, fixed DOCKER_RUN, fixed target descriptions)

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (claude-opus-4-6)

### Debug Log References

### Completion Notes List

- Created Python-based conventional commits hook with `conventional_commits/check.py` as the entry point and `conventional_commits/config.py` for configuration (types, scopes, patterns, error templates)
- Hook manifest `.pre-commit-hooks.yaml` uses pre-commit v3+ compatible fields: `stages: [commit-msg]`, `language: python`, `minimum_pre_commit_version: "3.0.0"`
- Entry point registered via `setup.cfg` console_scripts as `conventional-commits-check`
- Regex enforces `type(scope): description` format with scope required, lowercase description start, no trailing period
- Merge commits (`Merge ...`) and revert commits (`Revert ...`) pass through without validation
- Error messages are actionable: show the user's message, expected format, valid types/scopes, examples, and specific issue detail
- Comprehensive test suite in `tests/test_check.py` and `tests/test_config.py` covering all type/scope combinations (parametrized), invalid formats, error message quality, and main() entry point
- Applied DevRail standards: `.devrail.yml` (python), `.editorconfig`, `.gitignore`, `Makefile` (two-layer delegation), `LICENSE` (MIT), `README.md`, `DEVELOPMENT.md`, `CHANGELOG.md`
- Agent instruction files created: `CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `.opencode/agents.yaml`

### File List

- `pre-commit-conventional-commits/.pre-commit-hooks.yaml`
- `pre-commit-conventional-commits/setup.cfg`
- `pre-commit-conventional-commits/setup.py`
- `pre-commit-conventional-commits/conventional_commits/__init__.py`
- `pre-commit-conventional-commits/conventional_commits/config.py`
- `pre-commit-conventional-commits/conventional_commits/check.py`
- `pre-commit-conventional-commits/tests/__init__.py`
- `pre-commit-conventional-commits/tests/test_check.py`
- `pre-commit-conventional-commits/tests/test_config.py`
- `pre-commit-conventional-commits/.devrail.yml`
- `pre-commit-conventional-commits/.editorconfig`
- `pre-commit-conventional-commits/.gitignore`
- `pre-commit-conventional-commits/Makefile`
- `pre-commit-conventional-commits/LICENSE`
- `pre-commit-conventional-commits/README.md`
- `pre-commit-conventional-commits/DEVELOPMENT.md`
- `pre-commit-conventional-commits/CHANGELOG.md`
- `pre-commit-conventional-commits/CLAUDE.md`
- `pre-commit-conventional-commits/AGENTS.md`
- `pre-commit-conventional-commits/.cursorrules`
- `pre-commit-conventional-commits/.opencode/agents.yaml`
