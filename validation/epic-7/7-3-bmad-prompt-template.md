# Story 7.3 -- Proposed BMAD Prompt Template for DevRail-Aware Planning

## Purpose

This is a proposed standard prompt template (or persona update) for BMAD planning agents to incorporate DevRail standards. It is an output of the Story 7.3 validation -- the recommendation for how to integrate DevRail into BMAD planning sessions.

## Proposed BMAD System Prompt Addition

Add the following to the BMAD planning agent's system prompt or persona definition when planning DevRail-managed projects:

---

### DevRail Standards Integration

When planning projects that follow DevRail development standards, incorporate the following into all architecture and story artifacts:

**Architecture Documents MUST include:**
1. Reference to `ghcr.io/devrail-dev/dev-toolchain:v1` as the tool execution environment
2. The Makefile contract (`make check`, `make lint`, `make format`, `make test`, `make security`, `make scan`, `make docs`) as the universal developer interface
3. `.devrail.yml` as the project configuration file declaring languages and settings
4. Agent instruction files (CLAUDE.md, AGENTS.md, .cursorrules, .opencode/agents.yaml) in the project directory structure
5. Language-specific tooling from the DevRail toolchain (ruff for Python, shellcheck/shfmt for Bash, tflint/terraform fmt for Terraform, ansible-lint for Ansible)

**Every Implementation Story MUST include:**
1. `make check` as an explicit acceptance criterion: "All `make check` targets pass"
2. In Dev Notes -- Conventional Commits section:
   - "All commits follow `type(scope): description` format"
   - Valid types: feat, fix, docs, chore, ci, refactor, test
   - Valid scopes: python, terraform, bash, ansible, container, ci, makefile, standards
3. In Dev Notes -- Constraints section:
   - "All tools run inside the dev-toolchain container. Do not install linters, formatters, or scanners on the host."
4. In Dev Notes -- Project Structure section:
   - Include DevRail files (Makefile, .devrail.yml, .editorconfig, agent instruction files)

**Script-Related Stories MUST include:**
1. "All scripts use `#!/usr/bin/env bash` and `set -euo pipefail`"
2. "Scripts must be idempotent -- safe to re-run"
3. "Use shared logging library (`lib/log.sh`) -- no raw echo for status messages"
4. "Scripts must pass shellcheck"

---

## How to Validate This Template

After adopting this template:

1. Run a BMAD planning session with the template active
2. Evaluate generated artifacts using `7-3-artifact-evaluator.sh`
3. Check the observation checklist (`7-3-observation-checklist.md`)
4. Compare results against pre-template BMAD output
5. Iterate on the template based on findings

## Template Versioning

| Version | Date | Changes |
|---|---|---|
| 1.0 | 2026-02-20 | Initial proposal based on Story 7.3 validation |

## Notes

- This template is a proposal. Actual BMAD integration may require different formatting depending on the BMAD framework version and persona configuration.
- The template should be tested and refined based on actual BMAD behavior.
- If BMAD supports structured context injection, the `7-3-bmad-devrail-context.md` file may be more appropriate than a system prompt modification.
