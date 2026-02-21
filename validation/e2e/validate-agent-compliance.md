# AI Agent Compliance Validation Checklist

This checklist validates that AI agents (Claude Code, Cursor, OpenCode, etc.) follow DevRail standards automatically when working on a DevRail-managed project, without any additional prompting beyond the instruction files shipped with the project.

## Prerequisites

- A project created from either the GitHub or GitLab template
- An AI agent tool with access to the project (Claude Code, Cursor, etc.)
- Docker installed and running (for `make check`)

## Test Procedure

### Step 1: Open the Project

Open the template-created project in the AI agent tool. Do NOT give any DevRail-specific instructions. The agent should discover the standards from the instruction files (CLAUDE.md, AGENTS.md, .cursorrules, .opencode/agents.yaml, DEVELOPMENT.md).

### Step 2: Give a Simple Coding Task

Ask the agent to perform a straightforward coding task, such as:

> "Add a Python utility function called `parse_config` that reads a YAML file and returns its contents as a dictionary. Include tests."

### Step 3: Observe Agent Behavior

Record whether the agent does each of the following without being prompted:

| # | Check | Expected Behavior | Result |
|---|---|---|---|
| 1 | Reads instruction files | Agent reads CLAUDE.md, DEVELOPMENT.md, or equivalent before starting work | [ ] Pass / [ ] Fail |
| 2 | Uses conventional commits | Commit messages follow `type(scope): description` format | [ ] Pass / [ ] Fail |
| 3 | Runs `make check` | Agent runs `make check` before completing the task | [ ] Pass / [ ] Fail |
| 4 | Does not install tools on host | Agent does not run `pip install`, `npm install`, etc. on the host | [ ] Pass / [ ] Fail |
| 5 | Uses container for checks | Agent uses the Makefile (which delegates to Docker) for all checks | [ ] Pass / [ ] Fail |
| 6 | Respects `.editorconfig` | Generated code follows indent style, line endings from `.editorconfig` | [ ] Pass / [ ] Fail |
| 7 | Follows language conventions | Code follows the conventions documented in `DEVELOPMENT.md` | [ ] Pass / [ ] Fail |

### Step 4: Test with Multiple Agents

Repeat the test with each available agent tool:

| Agent Tool | Instruction File Read | Result | Notes |
|---|---|---|---|
| Claude Code | CLAUDE.md | [ ] Pass / [ ] Fail | |
| Cursor | .cursorrules | [ ] Pass / [ ] Fail | |
| OpenCode | .opencode/agents.yaml | [ ] Pass / [ ] Fail | |
| Other (specify) | AGENTS.md | [ ] Pass / [ ] Fail | |

## Pass Criteria

The AI agent compliance test passes if:

1. The agent reads its tool-specific instruction file (or DEVELOPMENT.md) before starting work
2. All commits produced by the agent use conventional commit format
3. The agent runs `make check` (or individual make targets) before declaring work complete
4. The agent does not attempt to install tools outside the Docker container
5. Generated code respects `.editorconfig` formatting rules

## Failure Resolution

If the agent does not follow standards:

1. Check that the instruction file for that tool exists and contains the critical rules
2. Verify the instruction file mentions `make check`, conventional commits, and container-only tools
3. Check that DEVELOPMENT.md is comprehensive and well-structured
4. If the agent partially follows standards, note which rules were followed and which were not
5. Update the instruction files if the wording is ambiguous or unclear

## Notes

- AI agent behavior can vary between sessions. Run the test multiple times if results are inconsistent.
- The "zero prompting" requirement is aspirational. Document any cases where additional prompting was needed and why.
- Agent compliance depends on the quality of instruction files. Failures here may indicate instruction file improvements rather than agent limitations.
