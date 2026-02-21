---
title: "New Project"
linkTitle: "New Project"
weight: 10
description: "Create a new DevRail-compliant project from a GitHub or GitLab template."
---

The fastest way to start a DevRail-compliant project is to create a repository from one of the official templates. All DevRail configuration files are included and pre-configured.

## From GitHub Template

### Step 1: Create the Repository

Navigate to the [DevRail GitHub template](https://github.com/devrail-dev/github-repo-template) and click **"Use this template"** to create a new repository in your organization or personal account.

Alternatively, use the GitHub CLI:

```bash
# Create a new repository from the DevRail GitHub template
gh repo create my-new-project --template devrail-dev/github-repo-template --public
cd my-new-project
```

### Step 2: Configure Your Languages

Edit `.devrail.yml` to declare which languages your project uses. The Makefile reads this file to determine which tools to run.

```yaml
# .devrail.yml -- declare your project's languages
languages:
  - python
  - bash

fail_fast: false
log_format: json
```

Supported languages: `python`, `bash`, `terraform`, `ansible`. List only the languages your project actually uses.

### Step 3: Install Pre-Commit Hooks

```bash
# Install git hooks for local enforcement
make install-hooks
```

This sets up pre-commit hooks that run formatting checks and secret detection on every commit.

### Step 4: Run Your First Check

```bash
# Run all DevRail checks
make check
```

The first run pulls the dev-toolchain Docker image (~1 GB). Subsequent runs use the cached image and complete in under 5 minutes.

### Step 5: Make Your First Commit

```bash
# Stage all files
git add .

# Commit using conventional commit format
git commit -m "feat: initialize project with DevRail standards"
```

The pre-commit hooks run automatically. If any check fails, fix the issue and commit again.

## From GitLab Template

### Step 1: Create the Project

In GitLab, navigate to **New Project > Create from template > Custom** and select the DevRail GitLab template. Enter your project name and create the project.

Alternatively, clone the template manually:

```bash
# Clone the DevRail GitLab template
git clone https://gitlab.com/devrail-dev/gitlab-repo-template.git my-new-project
cd my-new-project

# Reset git history for a clean start
rm -rf .git
git init
git add .
git commit -m "feat: initialize project with DevRail standards"
```

### Step 2: Configure Your Languages

Edit `.devrail.yml` just as described in the GitHub workflow above. The configuration file format is identical across platforms.

### Step 3: Install Pre-Commit Hooks and Verify

```bash
# Install git hooks
make install-hooks

# Run all DevRail checks
make check
```

## What Is Included in the Template

Both templates ship with the following files:

| File | Purpose |
|---|---|
| `Makefile` | Universal execution interface with two-layer delegation |
| `.devrail.yml` | Language declaration and project settings |
| `.editorconfig` | Editor formatting rules (indent, line endings, whitespace) |
| `.gitignore` | Standard ignore patterns |
| `.pre-commit-config.yaml` | Pre-commit hook configuration |
| `DEVELOPMENT.md` | Canonical development standards |
| `CLAUDE.md` | Claude Code agent instructions |
| `AGENTS.md` | Generic agent instructions |
| `.cursorrules` | Cursor agent instructions |
| `.opencode/agents.yaml` | OpenCode agent instructions |
| `CHANGELOG.md` | Changelog (Keep a Changelog format) |
| `LICENSE` | MIT license |
| `README.md` | Project README template |
| CI configuration | GitHub Actions workflows or `.gitlab-ci.yml` |

## Next Steps

- [View Standards Reference](/docs/standards/) to understand which tools run for your declared languages
- [Learn About the Container](/docs/container/) to understand how the dev-toolchain image works
- [Customize Templates](/docs/templates/) for advanced configuration
