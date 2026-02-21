# Story 3.4: Implement Scan and Docs Targets

Status: done

## Story

As a developer,
I want `make scan` to run universal security scanners and `make docs` to auto-generate documentation,
so that every project gets vulnerability scanning and documentation generation regardless of language, with minimal configuration.

## Acceptance Criteria

1. **Given** any project with `.devrail.yml`, **When** `make scan` is run, **Then** `trivy` executes a filesystem scan against the project directory
2. **Given** any project with `.devrail.yml`, **When** `make scan` is run, **Then** `gitleaks` executes to detect secrets in the repository history
3. **Given** a scan target completes, **When** examining stdout, **Then** a JSON summary is emitted: `{"target":"scan","status":"pass|fail","duration_ms":1234}`
4. **Given** a project with `.devrail.yml` declaring `languages: [terraform]`, **When** `make docs` is run, **Then** `terraform-docs` generates documentation for each Terraform module directory
5. **Given** a project with `.devrail.yml` that does NOT include `terraform`, **When** `make docs` is run, **Then** the target exits 0 with a JSON message: `{"target":"docs","status":"skip","reason":"no docs targets configured"}`
6. **Given** a scan or docs target encounters a misconfiguration, **When** examining the output, **Then** exit code 2 is returned with a JSON error message
7. **Given** trivy or gitleaks finds vulnerabilities or secrets, **When** examining the exit code, **Then** exit code 1 is returned

## Tasks / Subtasks

- [x] Task 1: Implement `_scan` internal target (AC: #1, #2, #3, #7)
  - [x] 1.1: Implement trivy filesystem scan: `trivy fs --format json .`
  - [x] 1.2: Implement gitleaks detection: `gitleaks detect --source . --report-format json`
  - [x] 1.3: Run both scanners regardless of language declarations (universal scanners apply to all projects)
  - [x] 1.4: Aggregate results: exit 0 if both pass, exit 1 if either finds issues
  - [x] 1.5: Respect `DEVRAIL_FAIL_FAST=1` -- stop after first scanner failure
- [x] Task 2: Implement `_docs` internal target (AC: #4, #5)
  - [x] 2.1: Read `.devrail.yml` to check if `terraform` is in the languages list
  - [x] 2.2: If Terraform is declared, discover Terraform module directories (directories containing `*.tf` files)
  - [x] 2.3: Run `terraform-docs markdown table --output-file README.md .` in each module directory
  - [x] 2.4: If no docs-capable languages are declared, exit 0 with skip JSON message
  - [x] 2.5: Design for extensibility -- future languages may add docs generation (e.g., Python Sphinx, Go godoc)
- [x] Task 3: Implement JSON summary output (AC: #3, #5, #6)
  - [x] 3.1: Capture timing for duration_ms
  - [x] 3.2: Emit scan summary: `{"target":"scan","status":"pass|fail","duration_ms":N,"scanners":["trivy","gitleaks"]}`
  - [x] 3.3: Emit docs summary: `{"target":"docs","status":"pass|skip","duration_ms":N}`
  - [x] 3.4: On misconfiguration, emit error JSON with exit code 2
- [x] Task 4: Implement error handling (AC: #6, #7)
  - [x] 4.1: Trivy failure (vulnerabilities found) returns exit 1, not exit 2
  - [x] 4.2: Gitleaks finding secrets returns exit 1, not exit 2
  - [x] 4.3: Missing tool in container returns exit 2 (misconfiguration)
  - [x] 4.4: Default run-all-report-all for both scanners

## Dev Notes

### Critical Architecture Constraints

**Scan targets are universal -- they run on every project regardless of language.** Unlike lint, format, test, and security targets which are language-specific, `make scan` runs trivy and gitleaks on any codebase. The only prerequisite is a valid `.devrail.yml` file.

**Docs generation is currently Terraform-only.** The `make docs` target only has `terraform-docs` for MVP. Other languages may add doc generation in future versions. The target must handle this gracefully by skipping when no docs tools apply.

**terraform-docs writes files.** Unlike `make format` which runs in check mode, `terraform-docs` is expected to generate or update README.md files in Terraform module directories. This is intentional -- docs generation is a build step, not a check.

**Source:** [architecture.md - Makefile Contract Specification]

### Technical Details

#### Trivy Filesystem Scan

```bash
trivy fs --format json --output /tmp/trivy-results.json . || trivy_exit=$?
```

Trivy scans for:
- Known vulnerabilities in dependencies (package-lock.json, requirements.txt, go.sum, etc.)
- Misconfigurations in IaC files
- Exposed secrets (complementary to gitleaks)

Exit code mapping:
- `0` -- no vulnerabilities found
- `1` -- vulnerabilities found (map to DevRail exit 1)
- Other -- tool error (map to DevRail exit 2)

#### Gitleaks Detection

```bash
gitleaks detect --source . --report-format json --report-path /tmp/gitleaks-results.json || gitleaks_exit=$?
```

Gitleaks scans for:
- Hardcoded secrets (API keys, passwords, tokens)
- Credential patterns in git history

Exit code mapping:
- `0` -- no leaks found
- `1` -- leaks found (map to DevRail exit 1)
- Other -- tool error (map to DevRail exit 2)

#### terraform-docs Invocation

```bash
# Discover Terraform module directories
tf_dirs=$(find . -name '*.tf' -not -path './.git/*' -not -path './.terraform/*' | \
    xargs -I{} dirname {} | sort -u)

for dir in $tf_dirs; do
    terraform-docs markdown table --output-file README.md "$dir"
done
```

**Note:** `terraform-docs` may need a `.terraform-docs.yml` config file in the project root or module directory. The default behavior (generate markdown table) is acceptable for MVP.

#### JSON Output

Scan summary:
```json
{"target":"scan","status":"pass","duration_ms":5432,"scanners":["trivy","gitleaks"]}
```

Scan failure:
```json
{"target":"scan","status":"fail","duration_ms":5432,"scanners":["trivy","gitleaks"],"failed":["gitleaks"]}
```

Docs skip:
```json
{"target":"docs","status":"skip","reason":"no docs targets configured","duration_ms":5}
```

Docs success:
```json
{"target":"docs","status":"pass","duration_ms":890,"modules":["modules/vpc","modules/iam"]}
```

### Previous Story Intelligence

- Story 3.1 creates the reference Makefile with `scan` and `docs` public targets delegating to `_scan` and `_docs`
- Story 3.2 establishes the pattern for language dispatch, JSON output, and run-all-report-all -- follow the same patterns
- Story 3.3 establishes the security target pattern -- `make scan` runs universal scanners while `make security` (Story 3.3) runs language-specific scanners; do not duplicate
- Epic 2 installs trivy, gitleaks, and terraform-docs in the container

### Project Structure Notes

Like Stories 3.2 and 3.3, this story extends the reference Makefile from Story 3.1. The `_scan` and `_docs` internal targets are added to the existing file.

### Anti-Patterns to Avoid

1. DO NOT hardcode language checks for scan targets -- trivy and gitleaks are universal and run on all projects
2. DO NOT swallow exit codes -- a trivy vulnerability finding or gitleaks secret detection must propagate as exit 1
3. DO NOT skip JSON output -- every invocation must produce a JSON summary line on stdout
4. DO NOT duplicate security scanners -- language-specific scanners (bandit, tfsec) are in `make security` (Story 3.3), universal scanners (trivy, gitleaks) are in `make scan`
5. DO NOT fail when no docs tools apply -- exit 0 with skip status
6. DO NOT run terraform-docs in check mode -- docs generation is expected to write/update files

### Conventional Commits

- Scope: `makefile`
- Examples:
  - `feat(makefile): implement scan target with trivy and gitleaks`
  - `feat(makefile): implement docs target with terraform-docs support`

### References

- [architecture.md - Makefile Contract Specification]
- [architecture.md - Output & Logging Conventions]
- [architecture.md - Language Support Matrix]
- [prd.md - Functional Requirements FR3, FR6]
- [prd.md - Language Support Matrix - Universal Tools]
- [epics.md - Epic 3: Makefile Contract - Story 3.4]

## Senior Developer Review (AI)

**Reviewer:** Claude Opus 4.6 (adversarial review)
**Date:** 2026-02-20
**Verdict:** PASS with observations

### Acceptance Criteria Assessment

| AC | Status | Notes |
|----|--------|-------|
| #1 | IMPLEMENTED | trivy fs with JSON output to /tmp/trivy-results.json |
| #2 | IMPLEMENTED | gitleaks detect with JSON report |
| #3 | IMPLEMENTED | JSON summary emitted with scanners array |
| #4 | IMPLEMENTED | terraform-docs runs per discovered module directory |
| #5 | IMPLEMENTED | Non-terraform projects get skip JSON with exit 0 |
| #6 | IMPLEMENTED | Exit code 2 for trivy/gitleaks error (exit > 1) |
| #7 | IMPLEMENTED | trivy/gitleaks exit 1 maps to DevRail exit 1 |

### Findings (4 total)

1. **[MEDIUM] Trivy stderr suppressed with 2>/dev/null** -- `trivy fs ... 2>/dev/null` suppresses all trivy error output. If trivy encounters a genuine error (exit > 1), the developer will see the JSON error message from the Makefile but not trivy's own error output explaining what went wrong. This makes debugging harder. Not fixing for MVP but should be addressed later.

2. **[MEDIUM] _docs target only checks HAS_TERRAFORM for skip, ignoring other potential future doc generators** -- The skip logic at the end uses `if [ -z "$(HAS_TERRAFORM)" ]` which is correct for MVP but is not extensible. When adding future doc generators (e.g., Python Sphinx), the skip condition would need to be updated. The completion notes mention extensible design but the actual condition is single-language. Acceptable for MVP.

3. **[LOW] terraform-docs writes to README.md in each module directory** -- This is correct per the spec ("terraform-docs writes files... docs generation is a build step, not a check"). Verified this is intentional.

4. **[LOW] Scan target runs universally regardless of language** -- Correctly implemented. _scan does not check HAS_* language variables, running trivy and gitleaks on all projects. This matches the spec.

### Files Modified During Review

None (no code fixes needed for this story)

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (claude-opus-4-6)

### Debug Log References

### Completion Notes List

- Implemented _scan internal target with trivy fs (filesystem scan with JSON output to /tmp/trivy-results.json) and gitleaks detect (with JSON report to /tmp/gitleaks-results.json)
- Both scanners run universally regardless of language declarations
- Exit code mapping: trivy/gitleaks exit 1 maps to DevRail exit 1 (findings), exit >1 maps to exit 2 (misconfiguration/error)
- Run-all-report-all default: both scanners run even if trivy fails; DEVRAIL_FAIL_FAST=1 stops after first failure
- JSON summary includes scanners array and failed array on failure
- Implemented _docs internal target with terraform-docs support
- terraform-docs runs markdown table with --output-file README.md for each discovered Terraform module directory
- When terraform is not in languages list, exits 0 with skip JSON message
- JSON summary includes modules array listing processed directories
- Extensible design: docs target checks HAS_TERRAFORM; additional language blocks can be added for future doc generators

### File List

- github-repo-template/Makefile (modified)
- gitlab-repo-template/Makefile (modified)
- dev-toolchain/Makefile (modified)
