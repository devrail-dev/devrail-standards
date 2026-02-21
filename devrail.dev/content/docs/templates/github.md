---
title: "GitHub Template"
linkTitle: "GitHub"
weight: 10
description: "How to create a DevRail-compliant repository from the GitHub template."
---

The [GitHub repo template](https://github.com/devrail-dev/github-repo-template) provides a ready-to-use starting point for DevRail-compliant projects hosted on GitHub.

## Creating a Repository

### From the GitHub Web UI

1. Navigate to [github.com/devrail-dev/github-repo-template](https://github.com/devrail-dev/github-repo-template)
2. Click **"Use this template"** > **"Create a new repository"**
3. Enter your repository name and settings
4. Click **"Create repository"**
5. Clone the new repository to your machine

### From the GitHub CLI

```bash
# Create a new repository from the DevRail template
gh repo create my-project --template devrail-dev/github-repo-template --public
cd my-project
```

## File Inventory

The template includes the following files:

### DevRail Configuration

| File | Purpose |
|---|---|
| `Makefile` | Universal execution interface with two-layer delegation pattern |
| `.devrail.yml` | Language declaration and project settings |
| `.editorconfig` | Editor formatting rules (indent, line endings, whitespace) |
| `.gitignore` | Standard ignore patterns |
| `.pre-commit-config.yaml` | Pre-commit hook configuration for local enforcement |

### Documentation

| File | Purpose |
|---|---|
| `DEVELOPMENT.md` | Canonical development standards (single source of truth) |
| `CHANGELOG.md` | Changelog in Keep a Changelog format |
| `LICENSE` | MIT license |
| `README.md` | Project README template |

### Agent Instruction Files

| File | Purpose |
|---|---|
| `CLAUDE.md` | Instructions for Claude Code |
| `AGENTS.md` | Generic agent instructions |
| `.cursorrules` | Instructions for Cursor |
| `.opencode/agents.yaml` | Instructions for OpenCode |

### CI/CD

| File | Purpose |
|---|---|
| `.github/workflows/lint.yml` | Lint job -- runs `make lint` |
| `.github/workflows/format.yml` | Format job -- runs `make format` |
| `.github/workflows/security.yml` | Security job -- runs `make security` |
| `.github/workflows/test.yml` | Test job -- runs `make test` |
| `.github/workflows/docs.yml` | Docs job -- runs `make docs` |
| `.github/PULL_REQUEST_TEMPLATE.md` | PR description template |
| `.github/CODEOWNERS` | Code ownership for review assignment |

## Customization

### Step 1: Configure Languages

Edit `.devrail.yml` to match your project:

```yaml
# .devrail.yml -- configure for your project
languages:
  - python
  - bash
```

### Step 2: Update README

Replace the template README content with your project's description, maintaining the DevRail-standard structure:

- Title and one-line description
- Badges
- Quick start (3 steps max)
- Usage (`make help` output)
- Configuration
- Contributing (link to DEVELOPMENT.md)
- License

### Step 3: Customize CI Workflows

The GitHub Actions workflows are pre-configured to run each `make` target in a separate job using the dev-toolchain container. Adjust the workflow triggers if your branching strategy differs from the default (PRs to `main`).

### Step 4: Set Up Code Owners

Edit `.github/CODEOWNERS` to reflect your team's ownership structure:

```
# .github/CODEOWNERS
* @your-org/your-team
```

## Common Customization Patterns

### Adding a Language

To add a language to your project, edit `.devrail.yml`:

```yaml
languages:
  - python
  - bash
  - terraform  # Added terraform
```

The Makefile automatically adjusts which tools run based on this list. No other file changes are needed.

### Changing the Container Version

To pin a specific container version:

```makefile
# In your Makefile, override the default image
DEVRAIL_IMAGE ?= ghcr.io/devrail-dev/dev-toolchain:v1.3.2
```

### Adjusting CI Triggers

By default, CI workflows run on pull requests to `main`. To change this:

```yaml
# In .github/workflows/*.yml
on:
  pull_request:
    branches: [main, develop]  # Add additional branches
```
