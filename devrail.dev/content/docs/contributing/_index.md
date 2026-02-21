---
title: "Contributing"
linkTitle: "Contributing"
weight: 50
description: "How to contribute to the DevRail ecosystem -- adding languages, submitting pull requests, and understanding the repo structure."
---

DevRail is an open ecosystem. Contributions are welcome, whether you want to add support for a new language, improve documentation, or fix bugs.

## Getting Started

Before contributing, familiarize yourself with:

1. **The [DevRail standards](/docs/standards/)** -- understand the tooling conventions your contribution must follow
2. **The [ecosystem structure](/docs/contributing/ecosystem/)** -- understand which repo to contribute to
3. **The [pull request process](/docs/contributing/pull-requests/)** -- understand the workflow and CI expectations

## Contribution Types

| Type | Where to Contribute | Guide |
|---|---|---|
| Add a new language | `dev-toolchain` + `devrail-standards` | [Adding a Language](/docs/contributing/adding-a-language/) |
| Fix a bug | The repo where the bug exists | [Pull Requests](/docs/contributing/pull-requests/) |
| Improve documentation | `devrail.dev` (this site) | [Pull Requests](/docs/contributing/pull-requests/) |
| Update a tool version | `dev-toolchain` | [Pull Requests](/docs/contributing/pull-requests/) |
| Add a CI feature | `github-repo-template` or `gitlab-repo-template` | [Pull Requests](/docs/contributing/pull-requests/) |

## Development Setup

To contribute to the devrail.dev documentation site:

```bash
# Clone the documentation site repository
git clone https://github.com/devrail-dev/devrail.dev.git
cd devrail.dev

# Install pre-commit hooks
make install-hooks

# Start the local development server
make serve
```

The site is available at `http://localhost:1313/`. Changes to content files are automatically reloaded.

### Prerequisites

| Tool | Purpose | Install Guide |
|---|---|---|
| [Hugo extended](https://gohugo.io/installation/) | Build the documentation site | [Hugo Installation](https://gohugo.io/installation/) |
| [Go](https://go.dev/dl/) >= 1.21 | Required for Hugo modules | [Go Installation](https://go.dev/dl/) |
| [Docker](https://docs.docker.com/get-docker/) | Run `make check` | [Docker Installation](https://docs.docker.com/get-docker/) |
| [pre-commit](https://pre-commit.com/#install) | Git hook management | `pip install pre-commit` |

To contribute to other DevRail repos, the prerequisites are simpler -- only Docker and Make are required, since all tools run inside the dev-toolchain container.

## Contribution Guides

- [Adding a New Language](/docs/contributing/adding-a-language/) -- Step-by-step guide for adding language ecosystem support
- [Submitting Pull Requests](/docs/contributing/pull-requests/) -- Workflow, conventional commits, CI expectations
- [Ecosystem Structure](/docs/contributing/ecosystem/) -- Repo map and relationships
