# Story 7.3 -- BMAD Planning Scenario

## Purpose

This document defines the realistic project scenario for the BMAD planning validation test. The BMAD agent will be asked to plan this project while incorporating DevRail standards.

## The Project Scenario

### Project Name

**InfraWatch** -- A lightweight infrastructure monitoring service

### Project Description

> InfraWatch is a Python microservice that monitors infrastructure health for small teams. It periodically checks the status of configured endpoints (HTTP services, database connections, DNS records) and reports results via a REST API and optional Slack notifications.
>
> The project includes:
> - A Python API server (FastAPI) that exposes health check results
> - Bash scripts for deployment and configuration management
> - Terraform modules for provisioning the monitoring infrastructure on AWS (ECS Fargate)
> - An Ansible playbook for configuring on-premise monitoring agents
>
> The project must follow DevRail development standards.

### Why This Scenario

This scenario is chosen because it:

1. **Exercises multiple languages** -- Python, Bash, Terraform, Ansible (all DevRail-supported)
2. **Is realistic and non-trivial** -- A real-world microservice with infrastructure
3. **Requires multiple DevRail standards** -- Linting, formatting, security scanning, testing, conventional commits
4. **Is familiar enough for BMAD** -- Standard microservice architecture, nothing exotic
5. **Generates enough stories** -- The planning session should produce 3-5 epics with multiple stories each

## BMAD Planning Prompt

Use the following prompt to initiate the BMAD planning session:

> Plan the InfraWatch project -- a Python microservice for infrastructure health monitoring.
>
> The project includes:
> - A FastAPI-based REST API for health check results
> - Bash deployment and configuration scripts
> - Terraform modules for AWS ECS Fargate provisioning
> - An Ansible playbook for on-premise agent configuration
>
> This project follows DevRail development standards (see the DevRail context provided). All architecture decisions and story artifacts must incorporate DevRail standards including the Makefile contract, dev-toolchain container, conventional commits, and agent instruction files.
>
> Please generate:
> 1. An architecture document
> 2. Epics and stories with acceptance criteria
> 3. Dev notes that reference DevRail conventions

## What to Evaluate

After the BMAD planning session completes, evaluate the generated artifacts using the observation checklist (`7-3-observation-checklist.md`). Specifically look for:

### In the Architecture Document

- [ ] References `ghcr.io/devrail-dev/dev-toolchain:v1` container
- [ ] References Makefile contract (`make check`, `make lint`, etc.)
- [ ] References `.devrail.yml` configuration
- [ ] References agent instruction files (CLAUDE.md, AGENTS.md, etc.)
- [ ] Lists DevRail project structure in directory layout
- [ ] Mentions language-specific tools (ruff, shellcheck, tflint, ansible-lint)

### In Epic/Story Artifacts

- [ ] `make check` appears as acceptance criterion or completion gate
- [ ] Conventional commits referenced in dev notes
- [ ] Container-only tooling constraint mentioned
- [ ] Agent instruction files listed in project structure
- [ ] Pre-commit hooks referenced
- [ ] Script standards mentioned (idempotency, logging, set -euo pipefail)

### In Implementation Handoff

- [ ] Story contains enough DevRail context for an implementation agent to follow standards
- [ ] No additional prompting about DevRail should be needed
- [ ] Make check is an explicit completion gate, not an implicit assumption
