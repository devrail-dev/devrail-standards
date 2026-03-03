# Git Workflow

Git discipline and collaboration standards for DevRail-managed repositories. These complement the [Conventional Commits](../DEVELOPMENT.md#conventional-commits) section in DEVELOPMENT.md and the security scanning enforced by [gitleaks](universal.md).

## Branch Strategy

### Rules

1. **Never push directly to `main` (or `master`).** All changes reach the default branch through a pull/merge request. No exceptions.
2. **Create feature branches from `main`.** Always branch from the latest `main` to minimize merge conflicts.
3. **Delete branches after merge.** Stale branches clutter the repo. Configure your platform to auto-delete merged branches.

### Branch Naming

```
type/short-description
```

Use the same `type` prefixes as [Conventional Commits](../DEVELOPMENT.md#conventional-commits):

| Type | Example |
|---|---|
| `feat` | `feat/add-ansible-support` |
| `fix` | `fix/shellcheck-false-positive` |
| `docs` | `docs/update-python-standards` |
| `chore` | `chore/bump-ruff-version` |
| `ci` | `ci/add-arm64-build` |
| `refactor` | `refactor/simplify-log-library` |
| `test` | `test/add-bats-coverage` |

Rules:
- Use lowercase with hyphens -- no underscores, no camelCase
- Keep descriptions short (2-4 words)
- Include issue number when applicable: `fix/123-login-error`

## Pull/Merge Requests

### Requirements

Every change to `main` goes through a pull request (GitHub) or merge request (GitLab):

1. **Descriptive title** -- follows conventional commit format: `type(scope): description`
2. **Summary** -- explain *what* changed and *why*. Link to the issue being addressed.
3. **Test plan** -- describe how the change was tested. Include commands to reproduce.
4. **Small, focused PRs** -- one logical change per PR. Large PRs are harder to review and more likely to introduce bugs.

### PR/MR Templates

DevRail template repos ship with PR/MR templates. Use them. They include:

- Summary section
- Test plan checklist
- Standards compliance checklist (`make check` passes, conventional commits used)

### Draft PRs

Use draft/WIP PRs for:

- Work in progress that needs early feedback
- Changes that are not yet ready for review
- Experimental approaches you want to discuss before investing more time

## Code Review

### Process

1. **Minimum 1 approval required** before merging to `main`.
2. **No self-merge.** The author does not approve their own PR. (Exception: solo maintainers on small repos may self-merge after CI passes.)
3. **Review within 24 hours.** Unreviewed PRs block progress. If you cannot review in time, say so and suggest another reviewer.
4. **Re-review after significant changes.** If a review round produces substantial rework, request a fresh review rather than relying on the original approval.

### What Reviewers Check

| Area | What to Look For |
|---|---|
| **Correctness** | Does the code do what the PR claims? Are edge cases handled? |
| **Tests** | Are new behaviors covered by tests? Do existing tests still pass? |
| **Security** | No secrets, no injection vulnerabilities, no unsafe deserialization, proper input validation |
| **Standards** | Follows DevRail conventions (naming, logging, idempotency, error handling) |
| **Documentation** | Public APIs documented, README updated if user-facing behavior changed |
| **Simplicity** | Could this be simpler? Is there unnecessary complexity or premature abstraction? |

### Review Etiquette

- Comment on the code, not the author. "This function could be split" not "you wrote a messy function."
- Distinguish between blocking issues and suggestions. Prefix optional feedback with "nit:" or "suggestion:".
- Approve when satisfied. Do not hold PRs hostage over style preferences already covered by automated tooling.

## Commit Discipline

### Atomic Commits

Each commit represents **one logical change**:

- A bug fix is one commit (not three: "try fix", "actually fix", "fix typo in fix")
- A feature may be multiple commits if it has distinct, meaningful steps
- Refactoring and behavior changes are separate commits, even if related

### Conventional Commits

All commits follow the format defined in [DEVELOPMENT.md Conventional Commits](../DEVELOPMENT.md#conventional-commits). This section does not duplicate those rules -- refer there for types, scopes, and format.

### Force Push Policy

- **Never `--force-push` to shared branches** (`main`, `develop`, release branches). This rewrites history that others depend on.
- **Force push is acceptable on your own feature branches** to clean up history before review (interactive rebase, squash fixups).
- If you must force push a shared branch due to an emergency (e.g., removing an accidentally committed secret), coordinate with the team first.

### Squash Policy

- **Squash-merge feature branches** into `main` for a clean, linear history. The squashed commit message should follow conventional commit format.
- **Individual commits on feature branches** do not need to be perfectly formatted, but should still be meaningful (no "WIP" or "asdf" commits in the final PR).

## Branch Protection

Configure branch protection on `main` (or `master`) in every repository:

| Setting | Value |
|---|---|
| Require pull request before merging | Yes |
| Required approvals | 1 minimum |
| Require status checks to pass | Yes (`make check` / CI pipeline) |
| Require branches to be up to date | Yes |
| Allow force pushes | No |
| Allow deletions | No |

Platform-specific configuration:

- **GitHub:** Configure via Settings > Branches > Branch protection rules
- **GitLab:** Configure via Settings > Repository > Protected branches

## Merge Strategy

### Feature Branches

**Squash and merge** (default). This produces one clean commit per feature on `main`:

- The squash commit message uses conventional commit format
- Individual feature branch commits are preserved in the PR history
- This keeps `main` history readable and bisectable

### Long-Lived Branches

For branches that track upstream or parallel development (e.g., release branches):

- **Rebase** to incorporate changes from `main`
- **Merge commits** when syncing back to `main` (to preserve the branch context)

### Conflict Resolution

- Resolve merge conflicts locally, not in the platform UI
- After resolving, run `make check` to verify the resolution did not break anything
- If conflicts are extensive, consider splitting the PR into smaller pieces

## Security

### Secrets

1. **No secrets in commits.** No API keys, passwords, tokens, or credentials in source code -- ever. This is enforced by `gitleaks` in pre-commit hooks and `make scan`.
2. **No `.env` files committed.** Add `.env` to `.gitignore`. Use `.env.example` with placeholder values to document required variables.
3. **Use platform-provided secret management.** GitHub Secrets, GitLab CI/CD Variables, or a dedicated secrets manager (Vault, AWS Secrets Manager, etc.).
4. **If a secret is accidentally committed**, rotate the secret immediately. Do not rely on `git rebase` to remove it -- the secret is already in reflog and may be in clones.

### .gitignore

Every repository must have a `.gitignore` that excludes at minimum:

- IDE/editor files (`.idea/`, `.vscode/`, `*.swp`)
- OS artifacts (`.DS_Store`, `Thumbs.db`)
- Build artifacts and caches (`__pycache__/`, `.terraform/`, `*.tfstate`)
- Environment files (`.env`, `.env.local`)
- Dependency directories (`node_modules/`, `.venv/`)

### Signed Commits

Signed commits (GPG or SSH) are recommended but not required. If your organization requires commit signing, configure it at the platform level via branch protection rules.

### Vulnerability Reporting

- Do not open public issues for security vulnerabilities
- Use the platform's private security advisory feature (GitHub Security Advisories, GitLab confidential issues)
- Follow the project's `SECURITY.md` if one exists

## Notes

- Branch protection settings should be configured as part of repository setup, using the DevRail template repos as a baseline.
- The `gitleaks` pre-commit hook catches most secret leaks before they reach the remote. See [Universal Security Tools](universal.md) for configuration.
- The `make check` pre-push hook runs the full DevRail check suite before every `git push`, providing a local safety net in addition to CI. Skip with `git push --no-verify` when necessary.
- For commit message format details, see [Conventional Commits](../DEVELOPMENT.md#conventional-commits) in DEVELOPMENT.md. This document intentionally does not duplicate those rules.
