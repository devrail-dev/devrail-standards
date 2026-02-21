"""Configuration for conventional commit message validation.

Defines the valid types, scopes, and format rules enforced by the
conventional-commits pre-commit hook. These values are dictated by
DevRail standards and must match the types and scopes documented in
DEVELOPMENT.md.
"""

# Valid commit message types per DevRail standards
VALID_TYPES = frozenset({
    "feat",
    "fix",
    "docs",
    "chore",
    "ci",
    "refactor",
    "test",
})

# Valid commit message scopes per DevRail standards
VALID_SCOPES = frozenset({
    "python",
    "terraform",
    "bash",
    "ansible",
    "container",
    "ci",
    "makefile",
    "standards",
})

# Regex pattern for the conventional commit subject line.
# Format: type(scope): description
# - type: required, must be one of VALID_TYPES
# - scope: required, must be one of VALID_SCOPES
# - colon + space after closing paren: required
# - description: required, must start with a lowercase letter
# - no trailing period
COMMIT_PATTERN = r"^(?P<type>[a-z]+)\((?P<scope>[a-z]+)\): (?P<description>.+)$"

# Maximum subject line length (recommended, not enforced at MVP)
MAX_SUBJECT_LENGTH = 72

# Error message template shown when a commit is rejected
ERROR_TEMPLATE = """ERROR: Commit message does not follow conventional commit format.

  Your message: "{message}"

  Expected format: type(scope): description

  Valid types:  {types}
  Valid scopes: {scopes}

  Examples:
    feat(python): add ruff configuration for type checking
    fix(ci): correct Docker image reference in build workflow
    docs(standards): update .devrail.yml schema

  Rules:
    - type and scope are required
    - description must be non-empty and start with a lowercase letter
    - no period at the end of the description"""
