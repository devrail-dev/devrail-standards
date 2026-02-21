---
title: "Submitting Pull Requests"
linkTitle: "Pull Requests"
weight: 20
description: "Pull request workflow, conventional commits, CI expectations, and code review process."
---

All contributions to DevRail repositories follow a standard pull request workflow. This guide covers the process from branch creation to merge.

## Workflow

### Step 1: Fork and Clone

```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/<your-username>/<repo-name>.git
cd <repo-name>

# Add the upstream remote
git remote add upstream https://github.com/devrail-dev/<repo-name>.git
```

### Step 2: Create a Branch

```bash
# Create a feature branch from main
git checkout -b feat/my-feature main
```

Use a descriptive branch name that reflects the change type and scope:

- `feat/add-go-support` -- new feature
- `fix/shellcheck-exit-code` -- bug fix
- `docs/update-python-config` -- documentation change

### Step 3: Make Your Changes

Follow the development standards defined in the repository's `DEVELOPMENT.md`. Run checks as you work:

```bash
# Run all checks to verify your changes
make check
```

### Step 4: Commit with Conventional Commits

Every commit must follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
type(scope): description
```

#### Types

| Type | When to Use | Example |
|---|---|---|
| `feat` | A new feature or capability | `feat(python): add ruff rule E501` |
| `fix` | A bug fix | `fix(container): correct shellcheck path` |
| `docs` | Documentation-only changes | `docs(standards): update terraform tools table` |
| `chore` | Maintenance tasks | `chore(deps): update trivy to v0.50` |
| `ci` | CI/CD pipeline changes | `ci(github): add caching to lint job` |
| `refactor` | Code restructuring | `refactor(makefile): simplify docker run flags` |
| `test` | Adding or updating tests | `test(bash): add shfmt formatting test` |

#### Scopes

| Scope | Applies To |
|---|---|
| `python` | Python tooling, configs, or standards |
| `bash` | Bash tooling, configs, or standards |
| `terraform` | Terraform tooling, configs, or standards |
| `ansible` | Ansible tooling, configs, or standards |
| `container` | Dev-toolchain container image |
| `ci` | CI/CD pipeline configuration |
| `makefile` | Makefile targets and patterns |
| `docs` | Documentation content |
| `standards` | DevRail standards documentation |

#### Examples

```bash
# Good -- clear, descriptive, follows the format
git commit -m "feat(python): add semgrep to security scanning pipeline"
git commit -m "fix(container): resolve arm64 trivy binary download"
git commit -m "docs(getting-started): add GitLab template instructions"

# Bad -- missing type/scope, vague description
git commit -m "update stuff"
git commit -m "fix things"
git commit -m "WIP"
```

Pre-commit hooks enforce the conventional commit format. If your commit message does not match the pattern, the commit is rejected with a descriptive error message.

### Step 5: Push and Create a Pull Request

```bash
# Push your branch to your fork
git push origin feat/my-feature
```

Create a pull request on GitHub using the PR template. Fill in:

- **Summary** -- what changed and why
- **Related issues** -- link to any GitHub issues
- **Testing** -- how you verified the change works

### Step 6: CI Checks

Every pull request triggers CI checks. All checks must pass before the PR can be merged:

| Check | What It Validates |
|---|---|
| `make lint` | All linters pass |
| `make format` | Code formatting matches standards |
| `make test` | All tests pass |
| `make security` | No security issues found |
| `make docs` | Documentation generates correctly |
| Hugo build | Site builds with `hugo --minify` (devrail.dev only) |

If any check fails, fix the issue, commit the fix, and push again. CI runs automatically on each push.

### Step 7: Code Review

A maintainer reviews the PR. Common review criteria:

- Follows DevRail coding conventions
- Includes appropriate tests
- Documentation is updated if needed
- Commits follow conventional commit format
- No unnecessary changes outside the stated scope

### Step 8: Merge

Once approved and all CI checks pass, a maintainer merges the PR. Squash merging is preferred for clean git history.

## CI Expectations

### All Repos

Every DevRail repository runs `make check` (or individual `make` targets) inside the dev-toolchain container on pull requests. The container ensures consistent tool versions across local development and CI.

### devrail.dev (This Site)

The documentation site has an additional CI check: `hugo --minify` must succeed. This verifies that all content renders correctly without build errors.

## Tips for a Smooth Review

1. **Keep PRs small and focused.** One logical change per PR. Large PRs are harder to review and more likely to have merge conflicts.
2. **Write descriptive commit messages.** Reviewers read commit messages to understand the intent behind each change.
3. **Run `make check` before pushing.** Do not rely on CI to catch issues. Fix them locally first.
4. **Update documentation.** If your change affects user-facing behavior, update the relevant documentation pages.
5. **Respond to review feedback promptly.** Address all comments, either by making changes or explaining why the current approach is correct.
