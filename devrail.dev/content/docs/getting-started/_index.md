---
title: "Getting Started"
linkTitle: "Getting Started"
weight: 10
description: "Quick start guides for creating new DevRail projects and retrofitting existing repositories."
---

Get up and running with DevRail in minutes. Whether you are starting a brand-new project or adding DevRail standards to an existing repository, the process is straightforward.

## Prerequisites

Before you begin, make sure you have the following installed on your machine:

| Tool | Purpose | Install Guide |
|---|---|---|
| [Docker](https://docs.docker.com/get-docker/) | Runs the dev-toolchain container | [Docker Installation](https://docs.docker.com/get-docker/) |
| [GNU Make](https://www.gnu.org/software/make/) | Universal execution interface | Pre-installed on macOS and Linux |
| [pre-commit](https://pre-commit.com/#install) | Git hook management | `pip install pre-commit` |

All other tools (linters, formatters, security scanners, test runners) are pre-installed inside the dev-toolchain container. You do not need to install them on your host machine.

## Choose Your Path

- **[New Project](/docs/getting-started/new-project/)** -- Start a new repository from a DevRail template. All configuration files are pre-set.
- **[Retrofit Existing Project](/docs/getting-started/retrofit/)** -- Add DevRail standards to a repository you already have.

## Verify Your Setup

After setting up DevRail (either path), verify everything works by running:

```bash
# Run all DevRail checks (linting, formatting, security, tests)
make check
```

This command pulls the dev-toolchain Docker image (if not already cached), mounts your project directory, and runs every configured check inside the container. A passing `make check` means your project is DevRail-compliant.
