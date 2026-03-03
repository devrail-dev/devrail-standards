---
title: "Coding Practices"
linkTitle: "Practices"
weight: 5
description: "Cross-cutting coding and git practices for all DevRail projects."
---

These practices apply to every DevRail project regardless of language. They are enforced by code review, not automated tooling. The per-language pages cover *which tools run*; this page covers *how to write the code those tools check*.

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
| **Idempotency** | Operations must be safe to re-run. The result of running something once must be identical to running it N times. |

## Idempotency

Every script, migration, deployment, and configuration change must be safe to re-run without causing damage or duplication.

### Patterns by Context

| Context | Pattern |
|---|---|
| **Shell scripts** | `command -v tool \|\| install_tool`, `mkdir -p`, guard file writes with existence checks. |
| **Database migrations** | Use a migration framework that tracks applied migrations by ID. Never rely on manual execution order. |
| **Terraform** | Declare desired state, not imperative steps. `terraform apply` is inherently idempotent when state is managed correctly. |
| **Ansible** | Use declarative modules over `command`/`shell`. Set `creates:` or `removes:` on shell tasks. Use `changed_when` to avoid false changes. |
| **CI/CD pipelines** | Pipeline stages must not fail or produce different results when re-triggered. Use `--if-not-exists` flags and check artifact existence before publishing. |
| **Python** | Guard resource creation with existence checks. Use `os.makedirs(path, exist_ok=True)`, catch `FileExistsError`. |
| **Configuration management** | Write config files atomically (write to temp, then rename). Check current state before modifying. Never append without checking for existing entries. |

### Anti-Patterns

- Blindly appending to files (duplicate entries on re-run)
- `INSERT` without `ON CONFLICT` / `IF NOT EXISTS`
- Scripts that assume clean state (empty directory, fresh database)
- Provisioners or setup scripts with no guards

## Error Handling

1. **Validate inputs at system boundaries.** User input, API payloads, environment variables, and file contents must be validated before use. Internal function-to-function calls can trust types and contracts.
2. **No swallowed exceptions.** Every `except`, `catch`, or error branch must either handle the error meaningfully or re-raise/propagate it. Bare `except:` (Python) and empty `catch {}` blocks are prohibited.
3. **Fail with meaningful messages.** Error messages must include what went wrong, what was expected, and (when possible) how to fix it.
4. **Use language-appropriate error patterns.** See the per-language standard for specifics (e.g., `set -euo pipefail` in Bash, specific exception types in Python).
5. **Log errors before propagating.** Use the appropriate logging mechanism so errors are visible in structured output even if the caller catches and handles them.

## Testing

### Test Pyramid

Maintain a healthy ratio: **unit tests > integration tests > end-to-end tests**.

- **Unit tests** -- fast, isolated, test a single function or method. Mock external dependencies.
- **Integration tests** -- verify that components work together (e.g., script + filesystem, module + provider).
- **End-to-end tests** -- validate full workflows. Fewer of these; they are slower and more brittle.

### Test Naming

Use descriptive names: `test_<what>_<condition>_<expected>`.

### Coverage

- Aim for meaningful coverage, not vanity metrics. 80% coverage of critical paths beats 100% coverage padded with trivial assertions.
- **New code must include tests.** PRs that add logic without tests are incomplete.

## Git Workflow

- **Never push directly to `main`.** All changes reach the default branch through a pull/merge request.
- **Branch naming:** `type/short-description` (e.g., `feat/add-ansible-support`, `fix/shellcheck-false-positive`).
- **Conventional commits:** Every commit message follows `type(scope): description`.
- **Minimum 1 approval required** before merging. No self-merge (exception: solo maintainers after CI passes).
- **Never force-push shared branches.** Force push is acceptable on your own feature branches only.
- **Squash-merge feature branches** into `main` for clean, linear history.
- **No secrets in commits.** Enforced by `gitleaks` in pre-commit hooks and `make scan`.

## Code Organization

- **Function length: ~50 lines maximum.** If a function exceeds this, consider splitting it.
- **One primary concern per file.** A file named `auth.py` should contain authentication logic, not unrelated utilities.
- **No circular dependencies.** If A imports B and B imports A, refactor to extract the shared dependency into C.

## Dependencies

- **Lock files are mandatory.** Use the appropriate lock file for each language and commit it to version control.
- **Pin versions.** Allow compatible ranges only in dependency declarations; lock files pin to exact versions.
- **Respond to security advisories promptly.** Run `make security` and `make scan` after dependency updates.

## Notes

- These practices are enforced by code review, not by automated tooling. Automated enforcement is covered by the per-language tool standards.
- When a practice here conflicts with a language-specific standard, the language-specific standard takes precedence.
- These practices are embedded in every project's DEVELOPMENT.md via the DevRail template repos.
- Full reference: [Coding Practices](https://gitlab.mfsoho.linkridge.net/OrgDocs/development-standards/-/blob/main/standards/coding-practices.md) and [Git Workflow](https://gitlab.mfsoho.linkridge.net/OrgDocs/development-standards/-/blob/main/standards/git-workflow.md) in the planning repo.
