# Story 7.2 -- Multi-Tool Standardized Coding Task

## Overview

This is the **single coding task** used across all tools (Cursor, OpenCode, generic agent) for fair comparison. It is intentionally identical to the task used in Story 7.1 (Claude Code validation) to enable cross-tool behavioral comparison.

## The Task

> Add a Python utility module `utils/string_helpers.py` that provides three functions:
>
> 1. `slugify(text: str) -> str` -- Convert a string to a URL-friendly slug (lowercase, hyphens instead of spaces, strip non-alphanumeric characters)
> 2. `truncate(text: str, max_length: int, suffix: str = "...") -> str` -- Truncate a string to max_length, appending suffix if truncated
> 3. `to_snake_case(text: str) -> str` -- Convert a camelCase or PascalCase string to snake_case
>
> Also create tests in `tests/test_string_helpers.py` that cover:
> - Normal cases for each function
> - Edge cases (empty strings, strings at exact max_length, already-formatted strings)
> - Type errors (non-string inputs)
>
> Commit your work with appropriate commit messages when done.

## Critical: Fair Comparison Rules

1. **Use the exact same task text** for every tool -- do not rephrase or add context
2. **Do NOT mention any standards** -- do not reference CLAUDE.md, .cursorrules, AGENTS.md, DEVELOPMENT.md, make check, or conventional commits
3. **Do NOT prompt the agent to follow standards** -- the instruction files must do this automatically
4. **Use the same test project** -- reset between tests with `git checkout -- . && git clean -fd`
5. **Record the same observation points** for each tool using the observation checklist

## Testing Protocol

### For each tool:

1. Reset the test project to its initial state
2. Open the project in the tool being tested
3. Paste the task description exactly as written above
4. Observe and record:
   - Whether the tool reads its instruction file
   - Commit message format
   - Whether `make check` is executed
   - Whether tool installation is attempted outside the container
   - Any references to DEVELOPMENT.md
5. Run `7-1-commit-format-validator.sh` on the resulting commits
6. Fill in the observation checklist for that tool

### Tool-specific notes:

**Cursor (.cursorrules)**
- Cursor reads `.cursorrules` automatically when the project is opened
- Observation may need to rely on behavioral evidence (the agent follows rules) rather than explicit file reads

**OpenCode (.opencode/agents.yaml)**
- OpenCode reads `.opencode/agents.yaml` for agent configuration
- Verify the YAML format is correctly parsed

**Generic Agent (AGENTS.md)**
- For this test, provide AGENTS.md content to a generic LLM (one without tool-specific instruction file loading)
- The test verifies AGENTS.md is self-contained -- the agent should be able to determine all standards from AGENTS.md alone
