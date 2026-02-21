---
title: "Ecosystem Structure"
linkTitle: "Ecosystem"
weight: 30
description: "Map of all DevRail repositories, their purposes, and how they relate to each other."
---

DevRail is a multi-repo ecosystem. Each repository has a specific purpose and clean integration boundaries with other repos. Understanding this structure helps you contribute to the right place.

## Repository Map

| Repository | Purpose | Key Contents |
|---|---|---|
| [devrail-standards](https://github.com/devrail-dev/devrail-standards) | Canonical source of truth for all development standards | Per-language standards (`standards/*.md`), `.devrail.yml` schema, DEVELOPMENT.md |
| [dev-toolchain](https://github.com/devrail-dev/dev-toolchain) | Docker container image with all tools pre-installed | Dockerfile, per-language install scripts, verification tests |
| [pre-commit-conventional-commits](https://github.com/devrail-dev/pre-commit-conventional-commits) | Pre-commit hook for conventional commit validation | Python package, pre-commit hook definition |
| [github-repo-template](https://github.com/devrail-dev/github-repo-template) | GitHub project template with all DevRail files | Makefile, config files, GitHub Actions workflows |
| [gitlab-repo-template](https://gitlab.com/devrail-dev/gitlab-repo-template) | GitLab project template with all DevRail files | Makefile, config files, `.gitlab-ci.yml` |
| [devrail.dev](https://github.com/devrail-dev/devrail.dev) | This documentation site | Hugo site with Docsy theme |

## Data Flow

Standards flow in one direction through the ecosystem:

```
devrail-standards (canonical rules)
        |
        ├──> dev-toolchain (tools that enforce rules)
        |           |
        |           ├──> github-repo-template (Makefile delegates to container)
        |           |           |
        |           |           └──> CI workflows call make targets
        |           |
        |           └──> gitlab-repo-template (Makefile delegates to container)
        |                       |
        |                       └──> .gitlab-ci.yml calls make targets
        |
        ├──> pre-commit-conventional-commits (hook enforces commit format)
        |
        └──> devrail.dev (publishes standards as documentation)
```

## Integration Boundaries

Repos never import code from each other. Integration happens through three mechanisms:

| Interface | Producer | Consumer | Contract |
|---|---|---|---|
| Container image | dev-toolchain | Templates (via Makefile) | `ghcr.io/devrail-dev/dev-toolchain:v1` with all tools installed |
| Makefile targets | Templates | CI pipelines, agents, developers | `make lint/format/test/security/docs/check` |
| `.devrail.yml` | Developer/agent | Makefile, CI | Language declarations, project settings |
| Pre-commit hook | pre-commit-conventional-commits | Templates (via `.pre-commit-config.yaml`) | Conventional commit validation |
| Agent instructions | DEVELOPMENT.md + shims | AI agents | Critical rules + pointer to full standards |
| Standards docs | devrail-standards | devrail.dev, templates | Canonical rules per language |

## Key Principles

### Each Repo Is Independent

Every repository is independently buildable and testable. There are no cross-repo code dependencies. This means:

- You can contribute to any single repo without needing the others
- CI for each repo runs independently
- Each repo dogfoods its own DevRail standards

### Standards Flow One Direction

Canonical standards live in `devrail-standards`. Everything else consumes them:

- `dev-toolchain` implements the tools defined in the standards
- Templates ship copies of the configuration files
- `devrail.dev` publishes the standards as user-facing documentation

If you want to change a standard, start with `devrail-standards`. Then propagate the change to the other repos.

### The Container Is the Only Shared Runtime

The `dev-toolchain` container image is the only runtime dependency shared across repos. Templates reference it by image tag in their Makefiles. CI pipelines pull it to run checks.

## Contributing to Each Repo

### devrail-standards

- **What to change:** Per-language standards, `.devrail.yml` schema, DEVELOPMENT.md
- **When:** You want to change a rule, add a tool, or update conventions
- **Impact:** Changes here may need to propagate to templates and documentation

### dev-toolchain

- **What to change:** Dockerfile, install scripts, verification tests
- **When:** You want to add a tool, update a tool version, or add a language
- **Impact:** Changes produce a new container image version

### pre-commit-conventional-commits

- **What to change:** Python validation logic, hook configuration
- **When:** You want to change commit message validation rules
- **Impact:** Affects all repos that use the hook

### github-repo-template / gitlab-repo-template

- **What to change:** Makefile, config files, CI workflows
- **When:** You want to update what new projects get out of the box
- **Impact:** Only affects newly created projects (existing projects keep their current files)

### devrail.dev

- **What to change:** Hugo content files, site configuration
- **When:** You want to improve documentation, fix typos, add guides
- **Impact:** Changes are deployed to the live site on merge to main
