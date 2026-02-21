---
title: "Container"
linkTitle: "Container"
weight: 30
description: "How to use the dev-toolchain container image with the Makefile delegation pattern."
---

The dev-toolchain container is the heart of DevRail. It packages every linter, formatter, security scanner, and test runner into a single Docker image, ensuring consistent tool versions and behavior across every machine.

## Pulling the Image

The dev-toolchain image is hosted on GitHub Container Registry (GHCR):

```bash
# Pull the latest major version (recommended for most projects)
docker pull ghcr.io/devrail-dev/dev-toolchain:v1

# Pull a specific version (for reproducible builds)
docker pull ghcr.io/devrail-dev/dev-toolchain:v1.3.2
```

## How It Works with the Makefile

The Makefile uses a **two-layer delegation pattern** to ensure all tools run inside the container.

### Layer 1: User-Facing Targets (Host)

Public targets run on the host machine. Their sole responsibility is to invoke the dev-toolchain Docker container with the corresponding internal target.

```makefile
# Layer 1 -- public targets delegate to Docker
DEVRAIL_IMAGE ?= ghcr.io/devrail-dev/dev-toolchain:v1
DOCKER_RUN    ?= docker run --rm -v "$$(pwd):/workspace" -w /workspace $(DEVRAIL_IMAGE)

lint: ## Run all linters
	$(DOCKER_RUN) make _lint

format: ## Run all formatters
	$(DOCKER_RUN) make _format
```

### Layer 2: Internal Targets (Container)

Internal targets run inside the Docker container. They execute the actual tool commands. Internal targets are prefixed with `_` and are not intended for direct invocation by users.

```makefile
# Layer 2 -- internal targets execute inside the container
_lint:
	ruff check .
	shellcheck scripts/*.sh

_format:
	ruff format .
	shfmt -w scripts/*.sh
```

### Delegation Flow

```
Developer / CI / AI Agent
      |
      v
  make lint          (Layer 1: runs on host)
      |
      v
  docker run ...     (container startup)
      |
      v
  make _lint         (Layer 2: runs inside container)
      |
      v
  ruff, shellcheck   (actual tool execution)
```

### Why Two Layers?

1. **Environment consistency.** All tools run inside the same container, with the same versions, on every machine. No "works on my machine" drift.
2. **Zero host dependencies.** Developers only need Docker and Make installed. All linters, formatters, scanners, and test runners live in the container.
3. **Identical behavior everywhere.** Local development, CI pipelines, and AI agents all invoke the same targets and get the same results.

### Exceptions

- `make install-hooks` runs directly on the host because pre-commit hooks must be installed in the host's git repository, not inside a container.
- `make help` runs on the host because it only needs to parse the Makefile itself.

## Version Pinning

### Major-Version Floating Tag (Default)

Templates default to `ghcr.io/devrail-dev/dev-toolchain:v1`. This floating tag is updated with every release within the v1 major version. Non-breaking tool updates propagate automatically.

```yaml
# .devrail.yml or Makefile variable
# Uses the floating major version tag
DEVRAIL_IMAGE ?= ghcr.io/devrail-dev/dev-toolchain:v1
```

### Exact Version Pinning

For projects requiring reproducible builds, pin to an exact semver tag:

```makefile
# Pin to an exact version for reproducibility
DEVRAIL_IMAGE ?= ghcr.io/devrail-dev/dev-toolchain:v1.3.2
```

### Tagging Strategy

| Tag | Example | Behavior |
|---|---|---|
| Major floating | `v1` | Updated on every release; non-breaking updates propagate automatically |
| Exact semver | `v1.3.2` | Immutable; never updated after publication |

Weekly builds publish both an exact semver tag (e.g., `v1.3.2`) and update the floating major tag (`v1`). Breaking changes bump the major version.

### Upgrading

To upgrade to a new exact version:

```makefile
# Update the version in your Makefile
DEVRAIL_IMAGE ?= ghcr.io/devrail-dev/dev-toolchain:v1.4.0
```

If you use the floating `v1` tag, upgrades happen automatically when the container image is re-pulled.

## Multi-Architecture Support

The dev-toolchain image is built for both `linux/amd64` and `linux/arm64` architectures:

| Architecture | Used By |
|---|---|
| `linux/amd64` | Most CI runners (GitHub Actions, GitLab CI), Intel/AMD desktops |
| `linux/arm64` | Apple Silicon (M1/M2/M3) development machines, ARM-based CI runners |

Docker automatically selects the correct platform for your machine. No manual configuration is needed.

## Tools Included

The dev-toolchain container includes all tools needed for every supported language ecosystem:

### Python

| Tool | Purpose |
|---|---|
| ruff | Linting and formatting |
| bandit | Security-focused static analysis |
| semgrep | Multi-language static analysis |
| pytest | Test runner |
| mypy | Static type checking |

### Bash

| Tool | Purpose |
|---|---|
| shellcheck | Static analysis for shell scripts |
| shfmt | Shell script formatting |
| bats | Bash Automated Testing System |

### Terraform

| Tool | Purpose |
|---|---|
| tflint | Terraform-specific linting |
| terraform fmt | Canonical HCL formatting (via Terraform CLI) |
| tfsec | Terraform security scanning |
| checkov | Policy-as-code scanning |
| terratest | Infrastructure testing (Go-based) |
| terraform-docs | Module documentation generation |

### Ansible

| Tool | Purpose |
|---|---|
| ansible-lint | Playbook and role linting |
| molecule | Role testing framework |

### Universal

| Tool | Purpose |
|---|---|
| trivy | Vulnerability scanning (filesystem and images) |
| gitleaks | Secret detection |
| pre-commit | Git hook management |

## Running Tools Directly

While the Makefile delegation pattern is the recommended approach, you can invoke the container directly for debugging or exploration:

```bash
# Open an interactive shell inside the container
docker run --rm -it -v "$(pwd):/workspace" -w /workspace \
  ghcr.io/devrail-dev/dev-toolchain:v1 bash

# Run a specific tool directly
docker run --rm -v "$(pwd):/workspace" -w /workspace \
  ghcr.io/devrail-dev/dev-toolchain:v1 ruff check .

# Run make check inside the container
docker run --rm -v "$(pwd):/workspace" -w /workspace \
  ghcr.io/devrail-dev/dev-toolchain:v1 make _check
```
