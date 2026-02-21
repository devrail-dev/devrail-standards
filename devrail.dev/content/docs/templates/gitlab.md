---
title: "GitLab Template"
linkTitle: "GitLab"
weight: 20
description: "How to create a DevRail-compliant project from the GitLab template."
---

The [GitLab repo template](https://gitlab.com/devrail-dev/gitlab-repo-template) provides a ready-to-use starting point for DevRail-compliant projects hosted on GitLab.

## Creating a Project

### From the GitLab Web UI

1. Navigate to **New Project** > **Create from template**
2. Select the **Custom** tab
3. Choose the DevRail GitLab template
4. Enter your project name and settings
5. Click **Create project**
6. Clone the new project to your machine

### Manual Clone

If the template is not available in your GitLab instance's template list:

```bash
# Clone the DevRail GitLab template
git clone https://gitlab.com/devrail-dev/gitlab-repo-template.git my-project
cd my-project

# Reset git history for a clean start
rm -rf .git
git init
git add .
git commit -m "feat: initialize project with DevRail standards"

# Add your GitLab remote
git remote add origin https://gitlab.com/your-group/my-project.git
git push -u origin main
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
| `.gitlab-ci.yml` | GitLab CI pipeline with parallel jobs |
| `.gitlab/CODEOWNERS` | Code ownership for review assignment |
| `.gitlab/merge_request_templates/default.md` | MR description template |

## GitLab CI Pipeline

The `.gitlab-ci.yml` pipeline runs each `make` target as a separate job inside the dev-toolchain container:

```yaml
# .gitlab-ci.yml -- parallel jobs for each check category
image: ghcr.io/devrail-dev/dev-toolchain:v1

stages:
  - check

lint:
  stage: check
  script:
    - make _lint

format:
  stage: check
  script:
    - make _format

security:
  stage: check
  script:
    - make _security

test:
  stage: check
  script:
    - make _test

docs:
  stage: check
  script:
    - make _docs
```

Jobs run in parallel within the `check` stage for fast feedback.

## Customization

### Step 1: Configure Languages

Edit `.devrail.yml` to match your project:

```yaml
# .devrail.yml -- configure for your project
languages:
  - python
  - terraform
```

### Step 2: Update README

Replace the template README content with your project's description, following the same structure as the GitHub template.

### Step 3: Set Up Code Owners

Edit `.gitlab/CODEOWNERS` to reflect your team's ownership structure:

```
# .gitlab/CODEOWNERS
* @your-group/your-team
```

## Common Customization Patterns

### Adding a Language

Edit `.devrail.yml` and add the language:

```yaml
languages:
  - python
  - bash
  - ansible  # Added ansible
```

No other file changes are needed. The Makefile and CI pipeline automatically adjust.

### Changing the Container Version

Override the container image in `.gitlab-ci.yml`:

```yaml
# Pin to a specific version
image: ghcr.io/devrail-dev/dev-toolchain:v1.3.2
```

Also update the `DEVRAIL_IMAGE` variable in your `Makefile` for local development consistency.

### Adjusting CI Triggers

By default, the pipeline runs on merge requests to `main`. To change this:

```yaml
# .gitlab-ci.yml
workflow:
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == "main"'
    - if: '$CI_COMMIT_BRANCH == "develop"'  # Add additional branches
```

## Differences from GitHub Template

The GitHub and GitLab templates are functionally equivalent. The differences are limited to platform-specific CI configuration:

| Aspect | GitHub Template | GitLab Template |
|---|---|---|
| CI config | `.github/workflows/*.yml` | `.gitlab-ci.yml` |
| MR/PR template | `.github/PULL_REQUEST_TEMPLATE.md` | `.gitlab/merge_request_templates/default.md` |
| Code owners | `.github/CODEOWNERS` | `.gitlab/CODEOWNERS` |
| Template usage | "Use this template" button | "Create from template" in new project |

All DevRail configuration files (Makefile, `.devrail.yml`, `.editorconfig`, agent files, etc.) are identical across both templates.
