# Story 7.1 -- Claude Code Coding Task

## Task Description

This is the standardized coding task to give to Claude Code when validating CLAUDE.md consumption. The task is designed to exercise multiple DevRail standards: conventional commits, `make check`, tool containment, and code quality.

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

## Why This Task

This task is chosen because it:

1. **Requires code creation** -- The agent must write Python code, exercising formatting and linting standards
2. **Requires test creation** -- The agent must write tests, exercising the test conventions
3. **Requires committing** -- The agent must produce commit messages, exercising conventional commit standards
4. **Is non-trivial but self-contained** -- Complex enough to observe real behaviors, simple enough to not require external dependencies
5. **Does not require tool installation** -- All tools needed (ruff, pytest) should be in the dev-toolchain container

## How to Use

1. Set up the test project using `7-1-test-project-setup.sh`
2. Open the test project in Claude Code
3. Paste the task description from "The Task" section above
4. **Do NOT mention CLAUDE.md, standards, or `make check`** -- the agent should discover these from CLAUDE.md
5. Observe the agent's behavior using the observation checklist

## What to Watch For

- Does the agent read CLAUDE.md before starting work?
- Does the agent produce `type(scope): description` commit messages?
- Does the agent run `make check` (or individual targets) before declaring work complete?
- Does the agent attempt to install ruff, pytest, or other tools directly?
- Does the agent reference DEVELOPMENT.md for detailed standards?
