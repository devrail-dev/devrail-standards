# Coding Practices

General software engineering practices that apply across all languages in DevRail-managed repositories. These complement the language-specific tool standards (Python, Bash, Terraform, Ansible) and the toolchain-enforced rules in [DEVELOPMENT.md](../DEVELOPMENT.md).

## Principles

| Principle | Rule |
|---|---|
| **DRY** (Don't Repeat Yourself) | Extract repeated logic into shared functions or modules. If the same block appears three or more times, refactor it. |
| **KISS** (Keep It Simple, Stupid) | Choose the simplest solution that meets the requirement. Avoid clever code that requires comments to explain. |
| **YAGNI** (You Aren't Gonna Need It) | Do not build for hypothetical future requirements. Implement what is needed now. |
| **Single Responsibility** | Each function, class, or module does one thing. If a description requires "and", split it. |
| **Separation of Concerns** | Keep business logic, data access, configuration, and presentation in distinct layers. |
| **Fail Fast** | Detect errors as early as possible. Validate inputs at boundaries. Return or raise immediately on invalid state. |
| **Least Surprise** | Code should behave as a reader would expect. Follow language idioms and project conventions. |
| **Idempotency** | Operations must be safe to re-run. The result of running something once must be identical to running it N times. See the [Idempotency](#idempotency) section for per-context patterns. |

## Idempotency

Every script, migration, deployment, and configuration change must be safe to re-run without causing damage or duplication. This is a universal principle -- not just a shell script rule.

### Patterns by Context

| Context | Pattern |
|---|---|
| **Shell scripts** | `command -v tool \|\| install_tool`, `mkdir -p`, guard file writes with existence checks. See [Shell Script Conventions](../DEVELOPMENT.md#shell-script-conventions). |
| **Database migrations** | Use a migration framework that tracks applied migrations by ID. Never rely on manual execution order. See [Database Migrations](#database-migrations). |
| **Terraform** | Declare desired state, not imperative steps. `terraform apply` is inherently idempotent when state is managed correctly. Never use `local-exec` provisioners for stateful operations without guards. |
| **Ansible** | Use declarative modules (`ansible.builtin.copy`, `ansible.builtin.service`) over `command`/`shell`. Set `creates:` or `removes:` on shell tasks. Use `changed_when` to avoid false changes. |
| **CI/CD pipelines** | Pipeline stages must not fail or produce different results when re-triggered. Use `--if-not-exists` flags, check artifact existence before publishing, and make deployments re-entrant. |
| **Python setup / init scripts** | Guard resource creation with existence checks. Use `os.makedirs(path, exist_ok=True)`, catch `FileExistsError`, check API state before creating resources. |
| **Configuration management** | Write config files atomically (write to temp, then rename). Check current state before modifying. Never append without checking for existing entries. |

### Anti-Patterns

- Blindly appending to files (duplicate entries on re-run)
- `INSERT` without `ON CONFLICT` / `IF NOT EXISTS`
- Scripts that assume clean state (empty directory, fresh database)
- Provisioners or setup scripts with no guards

## Naming Conventions

### Files and Directories

| Element | Convention | Example |
|---|---|---|
| Files (general) | `kebab-case` | `install-python.sh`, `devrail-yml-schema.md` |
| Python modules | `snake_case` | `commit_check.py`, `log_utils.py` |
| Terraform modules | `kebab-case` directories, `snake_case` files | `modules/vpc-setup/main.tf` |
| Test files | Mirror source name with `test` prefix/suffix | `test_check.py`, `test-lint.bats` |

### Code Identifiers

Follow the dominant convention for each language:

| Language | Variables / Functions | Constants | Classes / Types |
|---|---|---|---|
| Python | `snake_case` | `UPPER_SNAKE_CASE` | `PascalCase` |
| Bash | `lower_snake_case` | `UPPER_SNAKE_CASE` with `readonly` | N/A |
| Terraform | `snake_case` | N/A | `PascalCase` (module names) |
| Ansible | `snake_case` | `UPPER_SNAKE_CASE` | N/A |
| Ruby | `snake_case` | `UPPER_SNAKE_CASE` | `PascalCase` |
| Go | `camelCase` / `PascalCase` (exported) | `PascalCase` | `PascalCase` |
| JavaScript | `camelCase` | `UPPER_SNAKE_CASE` | `PascalCase` |

### General Naming Rules

- Names describe intent, not type -- `user_count` not `user_int`
- Boolean names read as assertions -- `is_valid`, `has_permission`, `should_retry`
- Avoid abbreviations unless universally understood (`url`, `id`, `config` are fine; `usr_cnt` is not)
- Collections use plural nouns -- `users`, `error_messages`, `allowed_hosts`

## Error Handling

### Rules

1. **Validate inputs at system boundaries.** User input, API payloads, environment variables, and file contents must be validated before use. Internal function-to-function calls can trust types and contracts.

2. **No swallowed exceptions.** Every `except`, `catch`, or error branch must either handle the error meaningfully or re-raise/propagate it. Bare `except:` (Python) and empty `catch {}` blocks are prohibited.

3. **Fail with meaningful messages.** Error messages must include what went wrong, what was expected, and (when possible) how to fix it.

4. **Use language-appropriate error patterns.**

| Language | Pattern |
|---|---|
| Python | Raise specific exceptions (`ValueError`, `FileNotFoundError`). Use `try/except` with explicit exception types. |
| Bash | `set -euo pipefail` + `die "message"` from `lib/log.sh`. Guard commands with `\|\|`. |
| Terraform | Use `validation` blocks in variables. Use `precondition`/`postcondition` in lifecycle blocks. |
| Ansible | Use `failed_when` and `changed_when`. Validate with `assert` tasks. |

1. **Log errors before propagating.** Use the appropriate logging mechanism (`log_error`, Python `logging`, etc.) so errors are visible in structured output even if the caller catches and handles them.

## Check Failures

When a lint, format, security, or test check fails, the correct response is always to **fix the root cause**. Never suppress, disable, or work around a failing check to make CI green.

### Rules

1. **Fix the issue, not the symptom.** If `cargo clippy` or `eslint` reports a warning, fix the code. If `cargo audit` or `bandit` reports a vulnerability, update the dependency or remediate the code.

2. **No blanket suppressions.** Do not add `# noqa`, `# nosec`, `// nolint`, `#tfsec:ignore`, `allow_failure: true`, `continue-on-error: true`, `--skip-check`, or equivalent annotations to make a check pass without fixing the issue.

3. **False positives require documented justification.** If a finding is a confirmed false positive, suppress it using the tool's designated mechanism (e.g., `.gitleaksignore`, inline `#tfsec:ignore` comment) **and** include a comment explaining why it is a false positive. Undocumented suppressions will be flagged in code review.

4. **Never comment out failing code.** Commenting out code that triggers a lint or security finding is not a fix. It is hiding the problem and removing functionality.

5. **Never remove checks.** Do not delete linter rules, remove CI stages, or drop tools from `.devrail.yml` to avoid failures.

### Anti-Patterns

| Anti-Pattern | Correct Response |
|---|---|
| Adding `# noqa` / `# nosec` without explanation | Fix the code or document why it's a false positive |
| Setting CI job to `allow_failure: true` | Fix the failing check |
| Commenting out code that triggers a security finding | Remediate the vulnerability |
| Removing a language from `.devrail.yml` to skip checks | Fix the issues in that language |
| Adding `--skip-check` flags to CI commands | Fix the finding or document the false positive |

## Testing Standards

### Test Pyramid

Maintain a healthy ratio: **unit tests > integration tests > end-to-end tests**.

- **Unit tests** -- fast, isolated, test a single function or method. Mock external dependencies.
- **Integration tests** -- verify that components work together (e.g., script + filesystem, module + provider).
- **End-to-end tests** -- validate full workflows. Fewer of these; they are slower and more brittle.

### Test Naming

Use descriptive names that communicate the scenario:

```
test_<what>_<condition>_<expected>
```

Examples:

- `test_validate_commit_with_missing_type_returns_error`
- `test_install_script_when_tool_exists_skips_install`
- `test_lint_target_with_no_files_exits_zero`

### What to Test

- **Test behavior, not implementation.** Assert on outputs and side effects, not on internal method calls.
- **Test edge cases.** Empty inputs, missing files, permission errors, boundary values.
- **Test error paths.** Verify that invalid inputs produce the correct error messages and exit codes.

### Coverage

- Aim for meaningful coverage, not vanity metrics. 80% coverage of critical paths beats 100% coverage padded with trivial assertions.
- New code must include tests. PRs that add logic without tests are incomplete.
- Coverage tooling is configured per language (pytest-cov, bats, etc.).

### Red-Green-Refactor

When adding features or fixing bugs:

1. **Red** -- write a failing test that demonstrates the requirement or bug.
2. **Green** -- write the minimum code to make the test pass.
3. **Refactor** -- clean up the code while keeping tests green.

## Code Organization

### Function Length

- **Guideline: ~50 lines maximum.** If a function exceeds this, consider splitting it.
- Extract helper functions for distinct logical steps.
- Long functions are acceptable only when splitting would reduce clarity (e.g., a linear sequence of sequential steps with no reuse).

### File Structure

- **One primary concern per file.** A file named `auth.py` should contain authentication logic, not unrelated utilities.
- **Group related files in directories.** Use `lib/`, `utils/`, `modules/`, or language-appropriate conventions.
- **No circular dependencies.** If A imports B and B imports A, refactor to extract the shared dependency into C.

### Import Ordering

Follow the language standard:

| Language | Convention |
|---|---|
| Python | stdlib, third-party, local (enforced by ruff `I` rules) |
| Bash | Source `lib/` scripts at the top of the file, after `set -euo pipefail` |
| Terraform | `required_providers` first, then variables, then resources |

## Documentation

### README Structure

Every repository must have a README.md with at minimum:

- Project name and one-line description
- Quick start / usage instructions
- Link to DEVELOPMENT.md for contribution standards

### Inline Documentation

- **Public APIs** (functions, classes, modules intended for external use) must have docstrings or equivalent documentation.
- **Internal code** does not need docstrings unless the logic is non-obvious.
- Comments explain *why*, not *what*. See [Code Comments](../DEVELOPMENT.md#code-comments) in DEVELOPMENT.md.

### Architecture Decision Records (ADRs)

For significant architectural decisions (new dependencies, major refactors, technology choices):

- Record the decision in an ADR document under `docs/adr/` or equivalent
- Format: title, status, context, decision, consequences
- ADRs are immutable once accepted -- supersede with a new ADR rather than editing

## Dependencies

### Version Pinning

- **Lock files are mandatory.** Use `requirements.txt` / `poetry.lock` (Python), `.terraform.lock.hcl` (Terraform), or equivalent.
- Pin to exact versions in lock files. Allow compatible ranges only in dependency declarations (e.g., `pyproject.toml`).
- Commit lock files to version control.

### Maintenance

- Update dependencies regularly. Review changelogs before upgrading.
- Respond to security advisories promptly -- patch vulnerable dependencies within the advisory's recommended timeframe.
- Run `make security` and `make scan` after dependency updates to catch known vulnerabilities.

### Selection Criteria

When adding a new dependency, evaluate:

| Criterion | Expectation |
|---|---|
| Maintenance | Actively maintained, recent releases, responsive to issues |
| License | Compatible with MIT (the DevRail license). No GPL or AGPL for library dependencies. |
| Scope | Does one thing well. Avoid large frameworks when a focused library suffices. |
| Security | No known unpatched vulnerabilities. Published security policy preferred. |

## Database Migrations

### Rules

1. **Use a migration framework.** Alembic (Python/SQLAlchemy), Flyway, Liquibase, golang-migrate, or equivalent. Never run raw DDL scripts by hand.

2. **Forward-only in production.** Down migrations are unreliable with production data. If a migration needs to be reversed, write a new forward migration that undoes the change.

3. **Migrations must be idempotent.** Use `IF NOT EXISTS`, `IF EXISTS`, `ON CONFLICT DO NOTHING`, and equivalent guards. A migration that has already been applied must not fail or produce side effects when re-run.

4. **Separate schema changes from data migrations.** DDL (create table, add column) and DML (backfill data, transform values) go in separate migration files. This makes failures easier to diagnose and retry.

5. **Timestamp-prefix migration files.** Name format: `YYYYMMDDHHMMSS_short_description`. This guarantees ordering and avoids ID collisions across branches.

6. **No destructive DDL without a rollback plan.** Before dropping a column, table, or index in production:
   - Verify no code references the object (deploy code changes first)
   - Back up the data if it cannot be reconstructed
   - Document the rollback procedure in the migration's commit message or PR description

7. **Test migrations against production-like data.** A migration that works on an empty database may fail or take hours on a table with millions of rows. Test with representative data volumes before deploying.

### Migration Checklist

| Check | Why |
|---|---|
| Migration file has timestamp prefix | Ordering and conflict avoidance |
| DDL and DML are in separate files | Isolate failures, simplify retries |
| Uses `IF NOT EXISTS` / `IF EXISTS` guards | Idempotency |
| Tested against non-trivial data volume | Avoids production surprises (locks, timeouts) |
| No data loss without documented backup plan | Reversibility |
| Code changes deployed before destructive DDL | No runtime errors from missing columns/tables |

## Notes

- These practices are enforced by code review, not by automated tooling. Automated enforcement is covered by the per-language tool standards.
- When a practice here conflicts with a language-specific standard, the language-specific standard takes precedence (e.g., Terraform's formatting rules override general file naming).
- For shell-specific coding standards, see [Shell Script Conventions](../DEVELOPMENT.md#shell-script-conventions) in DEVELOPMENT.md.
