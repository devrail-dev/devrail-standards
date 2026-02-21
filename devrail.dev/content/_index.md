---
title: "DevRail"
linkTitle: "DevRail"
---

{{% blocks/cover title="DevRail" image_anchor="top" height="full" color="primary" %}}
One Makefile. One Container. Every Language.

Opinionated development standards for teams that ship with AI agents.

{{% blocks/link-down color="info" %}}
{{% /blocks/cover %}}

{{% blocks/section color="white" %}}

## Why DevRail?

DevRail provides a universal development contract that works the same way for every developer, every CI pipeline, and every AI agent. No more environment drift. No more "works on my machine."

{{% /blocks/section %}}

{{% blocks/section color="light" type="row" %}}

{{% blocks/feature icon="fa-terminal" title="One Command" %}}
Run `make check` and get consistent results everywhere -- your laptop, CI, or an AI agent. The Makefile delegates to a Docker container that has every tool pre-installed.

[Get Started](/docs/getting-started/)
{{% /blocks/feature %}}

{{% blocks/feature icon="fa-cube" title="One Container" %}}
The `dev-toolchain` container includes linters, formatters, security scanners, and test runners for Python, Bash, Terraform, and Ansible. Pin a version and forget about tool management.

[Learn About the Container](/docs/container/)
{{% /blocks/feature %}}

{{% blocks/feature icon="fa-file-code" title="Every Language" %}}
Per-language standards define which tools run, how they are configured, and what Makefile targets invoke them. Consistent patterns across all supported ecosystems.

[View Standards](/docs/standards/)
{{% /blocks/feature %}}

{{% /blocks/section %}}

{{% blocks/section color="white" %}}

## How It Works

1. **Start from a template.** Create a new repository from the GitHub or GitLab template. All DevRail files are pre-configured.

2. **Declare your languages.** Edit `.devrail.yml` to list the languages your project uses. The Makefile reads this file to determine which tools to run.

3. **Run `make check`.** Every linter, formatter, security scanner, and test runner executes inside the dev-toolchain container. Results are identical on every machine.

4. **Ship with confidence.** CI pipelines call the same `make` targets. Pre-commit hooks catch issues before push. AI agents follow the same standards.

{{% /blocks/section %}}

{{% blocks/section color="light" %}}

## Ready to Start?

- [Quick Start Guide](/docs/getting-started/) -- Get up and running in minutes
- [Standards Reference](/docs/standards/) -- Per-language tooling conventions
- [Container Documentation](/docs/container/) -- How the dev-toolchain works
- [Contributing](/docs/contributing/) -- Help improve DevRail

{{% /blocks/section %}}
