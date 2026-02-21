"""Conventional commit message checker.

Validates that a commit message subject line follows the DevRail
conventional commit format: type(scope): description

This module is the entry point for the pre-commit hook. It reads the
commit message file passed as an argument, validates the first line
(subject), and exits with code 0 (pass) or 1 (fail).
"""

from __future__ import annotations

import re
import sys

from conventional_commits.config import (
    COMMIT_PATTERN,
    ERROR_TEMPLATE,
    VALID_SCOPES,
    VALID_TYPES,
)


def validate_commit_message(message: str) -> tuple[bool, str]:
    """Validate a commit message subject line against DevRail conventions.

    Args:
        message: The commit message subject line (first line only).

    Returns:
        A tuple of (is_valid, error_message). If is_valid is True,
        error_message is an empty string.
    """
    # Strip leading/trailing whitespace from the subject line
    subject = message.strip()

    if not subject:
        return False, _format_error(message, "commit message is empty")

    # Allow merge commits to pass through
    if subject.startswith("Merge "):
        return True, ""

    # Allow revert commits to pass through
    if subject.startswith("Revert "):
        return True, ""

    match = re.match(COMMIT_PATTERN, subject)

    if not match:
        return False, _format_error(subject)

    commit_type = match.group("type")
    scope = match.group("scope")
    description = match.group("description")

    # Validate type
    if commit_type not in VALID_TYPES:
        return False, _format_error(
            subject,
            f'invalid type "{commit_type}"',
        )

    # Validate scope
    if scope not in VALID_SCOPES:
        return False, _format_error(
            subject,
            f'invalid scope "{scope}"',
        )

    # Validate description starts with lowercase letter
    if not description[0].islower():
        return False, _format_error(
            subject,
            "description must start with a lowercase letter",
        )

    # Validate description does not end with a period
    if description.endswith("."):
        return False, _format_error(
            subject,
            "description must not end with a period",
        )

    return True, ""


def _format_error(message: str, detail: str = "") -> str:
    """Format the error message shown to the developer.

    Args:
        message: The invalid commit message.
        detail: Optional additional detail about the specific error.

    Returns:
        A formatted, actionable error string.
    """
    types_str = ", ".join(sorted(VALID_TYPES))
    scopes_str = ", ".join(sorted(VALID_SCOPES))

    error = ERROR_TEMPLATE.format(
        message=message,
        types=types_str,
        scopes=scopes_str,
    )

    if detail:
        error = f"{error}\n\n  Specific issue: {detail}"

    return error


def main(argv: list[str] | None = None) -> int:
    """Entry point for the pre-commit hook.

    Reads the commit message from the file path passed as the first
    argument (standard pre-commit commit-msg hook behavior), validates
    the subject line, and returns an exit code.

    Args:
        argv: Command-line arguments. If None, uses sys.argv.

    Returns:
        0 if the commit message is valid, 1 if invalid.
    """
    if argv is None:
        argv = sys.argv[1:]

    if not argv:
        print("ERROR: No commit message file provided.", file=sys.stderr)
        return 1

    commit_msg_file = argv[0]

    try:
        with open(commit_msg_file, encoding="utf-8") as f:
            commit_message = f.readline()
    except (OSError, IOError) as e:
        print(f"ERROR: Could not read commit message file: {e}", file=sys.stderr)
        return 1

    is_valid, error_message = validate_commit_message(commit_message)

    if not is_valid:
        print(error_message, file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
