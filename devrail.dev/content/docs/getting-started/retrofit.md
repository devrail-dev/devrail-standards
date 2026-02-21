---
title: "Retrofit Existing Project"
linkTitle: "Retrofit"
weight: 20
description: "Add DevRail standards to an existing repository."
---

If you already have a repository and want to adopt DevRail standards, follow this guide to add the necessary configuration files without disrupting your existing code.

## Step 1: Copy DevRail Files

Copy the following files from the DevRail template repository into your project root. You can download them individually or clone the template and copy them over.

### Required Files

These files are essential for DevRail to work:

```bash
# Download required DevRail files from the GitHub template
# Replace with your preferred method (curl, wget, manual copy)
curl -O https://raw.githubusercontent.com/devrail-dev/github-repo-template/main/Makefile
curl -O https://raw.githubusercontent.com/devrail-dev/github-repo-template/main/.devrail.yml
curl -O https://raw.githubusercontent.com/devrail-dev/github-repo-template/main/.editorconfig
curl -O https://raw.githubusercontent.com/devrail-dev/github-repo-template/main/.pre-commit-config.yaml
curl -O https://raw.githubusercontent.com/devrail-dev/github-repo-template/main/DEVELOPMENT.md
```

| File | Purpose | Can You Skip It? |
|---|---|---|
| `Makefile` | Universal execution interface | No -- required |
| `.devrail.yml` | Language declaration | No -- required |
| `.editorconfig` | Editor formatting rules | No -- required |
| `.pre-commit-config.yaml` | Pre-commit hook config | Recommended |
| `DEVELOPMENT.md` | Canonical standards doc | Recommended |

### Optional Files

These files enhance the development experience but are not strictly required:

```bash
# Download optional agent instruction files
curl -O https://raw.githubusercontent.com/devrail-dev/github-repo-template/main/CLAUDE.md
curl -O https://raw.githubusercontent.com/devrail-dev/github-repo-template/main/AGENTS.md
curl -O https://raw.githubusercontent.com/devrail-dev/github-repo-template/main/.cursorrules
mkdir -p .opencode
curl -o .opencode/agents.yaml https://raw.githubusercontent.com/devrail-dev/github-repo-template/main/.opencode/agents.yaml
```

| File | Purpose |
|---|---|
| `CLAUDE.md` | Claude Code agent instructions |
| `AGENTS.md` | Generic agent instructions |
| `.cursorrules` | Cursor agent instructions |
| `.opencode/agents.yaml` | OpenCode agent instructions |

## Step 2: Configure `.devrail.yml`

Edit `.devrail.yml` to declare which languages your project uses:

```yaml
# .devrail.yml -- configure for your project
languages:
  - python    # Include if your project has Python code
  - bash      # Include if your project has shell scripts
  # - terraform  # Include if your project has Terraform configs
  # - ansible    # Include if your project has Ansible playbooks

fail_fast: false
log_format: json
```

Only list languages that your project actually uses. The Makefile reads this file to determine which tools to run.

## Step 3: Review Your `.gitignore`

Make sure your `.gitignore` includes common DevRail patterns. Add these lines if they are not already present:

```gitignore
# DevRail / Editor
.DS_Store
Thumbs.db
*.swp
*.swo
*~
```

## Step 4: Install Pre-Commit Hooks

```bash
# Install git hooks for local enforcement
make install-hooks
```

This command runs `pre-commit install` to set up hooks that check formatting, linting, and secret detection on every commit.

## Step 5: Run Your First Check

```bash
# Run all DevRail checks against your existing code
make check
```

Expect some findings on the first run -- your existing code may not match DevRail formatting or linting standards. This is normal.

### Fixing Findings

Use `make` targets to auto-fix what can be auto-fixed:

```bash
# Auto-format code (inside the container)
# Note: formatting targets apply fixes directly
docker run --rm -v "$(pwd):/workspace" -w /workspace \
  ghcr.io/devrail-dev/dev-toolchain:v1 make _format
```

For linting issues that cannot be auto-fixed, address them manually following the guidance in the [Standards Reference](/docs/standards/).

## Step 6: Commit DevRail Files

```bash
# Stage all DevRail configuration files
git add Makefile .devrail.yml .editorconfig .pre-commit-config.yaml DEVELOPMENT.md

# Optionally stage agent instruction files
git add CLAUDE.md AGENTS.md .cursorrules .opencode/agents.yaml

# Commit using conventional commit format
git commit -m "chore: add DevRail development standards"
```

## Handling Conflicts with Existing Configuration

### Existing Makefile

If your project already has a Makefile, you have two options:

1. **Merge targets.** Add DevRail's public targets (`lint`, `format`, `test`, `security`, `scan`, `docs`, `check`, `install-hooks`) to your existing Makefile. Keep your existing targets alongside them.

2. **Replace.** If your existing Makefile only has basic targets, replace it entirely with the DevRail Makefile.

In either case, ensure the DevRail `DEVRAIL_IMAGE` variable and `DOCKER_RUN` delegation pattern are present.

### Existing `.editorconfig`

If you already have an `.editorconfig`, compare it with the DevRail default. DevRail's `.editorconfig` enforces:

- UTF-8 charset
- LF line endings
- Final newline inserted
- Trailing whitespace trimmed
- 2-space indentation (except Makefile: tabs, Python: 4 spaces, Shell: 2 spaces)

Merge any project-specific overrides you need, but do not weaken the baseline rules.

### Existing Linter Configurations

DevRail does not require you to delete existing linter configurations (`ruff.toml`, `.shellcheckrc`, `.tflint.hcl`, etc.). The dev-toolchain container tools will use your project-level configuration files if they exist.

## Next Steps

- Run `make check` regularly as you work on existing code
- Review the [Standards Reference](/docs/standards/) to understand what each tool checks
- Set up [CI pipelines](/docs/contributing/pull-requests/) to enforce standards on every pull request
