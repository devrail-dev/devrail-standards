"""Tests for conventional_commits.check module.

Covers all valid type/scope combinations, invalid message formats,
edge cases, and the main() entry point.
"""

from __future__ import annotations

import pytest

from conventional_commits.check import main, validate_commit_message
from conventional_commits.config import VALID_SCOPES, VALID_TYPES


# ---------------------------------------------------------------------------
# Valid commit messages
# ---------------------------------------------------------------------------

class TestValidCommitMessages:
    """All valid type/scope combinations must be accepted."""

    @pytest.mark.parametrize("commit_type", sorted(VALID_TYPES))
    @pytest.mark.parametrize("scope", sorted(VALID_SCOPES))
    def test_all_type_scope_combinations(self, commit_type, scope):
        message = f"{commit_type}({scope}): add something useful"
        is_valid, error = validate_commit_message(message)
        assert is_valid, f"Expected valid: {message}\nError: {error}"

    def test_feat_python(self):
        is_valid, _ = validate_commit_message(
            "feat(python): add ruff configuration for type checking"
        )
        assert is_valid

    def test_fix_ci(self):
        is_valid, _ = validate_commit_message(
            "fix(ci): correct Docker image reference in build workflow"
        )
        assert is_valid

    def test_docs_standards(self):
        is_valid, _ = validate_commit_message(
            "docs(standards): update .devrail.yml schema with container overrides"
        )
        assert is_valid

    def test_chore_makefile(self):
        is_valid, _ = validate_commit_message(
            "chore(makefile): update dev-toolchain image tag to v1.2.0"
        )
        assert is_valid

    def test_ci_container(self):
        is_valid, _ = validate_commit_message(
            "ci(container): add weekly rebuild schedule"
        )
        assert is_valid

    def test_refactor_bash(self):
        is_valid, _ = validate_commit_message(
            "refactor(bash): extract common logging to shared library"
        )
        assert is_valid

    def test_test_terraform(self):
        is_valid, _ = validate_commit_message(
            "test(terraform): add terratest validation for module outputs"
        )
        assert is_valid

    def test_description_with_numbers(self):
        is_valid, _ = validate_commit_message(
            "chore(container): bump python from 3.11 to 3.12"
        )
        assert is_valid

    def test_description_with_hyphens(self):
        is_valid, _ = validate_commit_message(
            "feat(python): add pre-commit configuration"
        )
        assert is_valid

    def test_description_with_special_chars(self):
        is_valid, _ = validate_commit_message(
            "fix(terraform): resolve `tflint` false positive on aws_instance"
        )
        assert is_valid


# ---------------------------------------------------------------------------
# Merge and revert commits (allowed to pass through)
# ---------------------------------------------------------------------------

class TestMergeAndRevertCommits:
    """Merge and revert commits bypass conventional commit validation."""

    def test_merge_commit(self):
        is_valid, _ = validate_commit_message(
            "Merge branch 'feature/something' into main"
        )
        assert is_valid

    def test_merge_pull_request(self):
        is_valid, _ = validate_commit_message(
            "Merge pull request #42 from devrail-dev/feature-branch"
        )
        assert is_valid

    def test_revert_commit(self):
        is_valid, _ = validate_commit_message(
            'Revert "feat(python): add ruff configuration"'
        )
        assert is_valid


# ---------------------------------------------------------------------------
# Invalid commit messages
# ---------------------------------------------------------------------------

class TestInvalidCommitMessages:
    """All invalid formats must be rejected with clear error messages."""

    def test_plain_text_no_format(self):
        is_valid, error = validate_commit_message("updated something")
        assert not is_valid
        assert "type(scope): description" in error

    def test_missing_scope(self):
        is_valid, error = validate_commit_message("feat: add new feature")
        assert not is_valid
        assert "type(scope): description" in error

    def test_missing_colon(self):
        is_valid, error = validate_commit_message("feat(python) add something")
        assert not is_valid

    def test_missing_space_after_colon(self):
        is_valid, error = validate_commit_message("feat(python):add something")
        assert not is_valid

    def test_uppercase_type(self):
        is_valid, error = validate_commit_message("Feat(python): add something")
        assert not is_valid

    def test_invalid_type(self):
        is_valid, error = validate_commit_message("update(python): add something")
        assert not is_valid
        assert "invalid type" in error

    def test_invalid_scope(self):
        is_valid, error = validate_commit_message("feat(invalid): add something")
        assert not is_valid
        assert "invalid scope" in error

    def test_empty_description(self):
        # The regex requires at least one character after ": "
        is_valid, error = validate_commit_message("feat(python): ")
        assert not is_valid

    def test_uppercase_description(self):
        is_valid, error = validate_commit_message(
            "feat(python): Add something with uppercase"
        )
        assert not is_valid
        assert "lowercase" in error

    def test_description_ends_with_period(self):
        is_valid, error = validate_commit_message(
            "feat(python): add something useful."
        )
        assert not is_valid
        assert "period" in error

    def test_empty_message(self):
        is_valid, error = validate_commit_message("")
        assert not is_valid
        assert "empty" in error

    def test_whitespace_only_message(self):
        is_valid, error = validate_commit_message("   ")
        assert not is_valid
        assert "empty" in error

    def test_scope_with_hyphen(self):
        # Scopes must be exact matches from the valid set
        is_valid, error = validate_commit_message(
            "feat(my-scope): add something"
        )
        assert not is_valid

    def test_multiple_scopes(self):
        is_valid, error = validate_commit_message(
            "feat(python,bash): add something"
        )
        assert not is_valid

    def test_empty_scope(self):
        is_valid, error = validate_commit_message("feat(): add something")
        assert not is_valid

    def test_type_with_numbers(self):
        is_valid, error = validate_commit_message("feat2(python): add something")
        assert not is_valid


# ---------------------------------------------------------------------------
# Error message quality
# ---------------------------------------------------------------------------

class TestErrorMessageQuality:
    """Error messages must be actionable and contain all necessary info."""

    def test_error_shows_user_message(self):
        _, error = validate_commit_message("bad message")
        assert "bad message" in error

    def test_error_shows_expected_format(self):
        _, error = validate_commit_message("bad message")
        assert "type(scope): description" in error

    def test_error_shows_valid_types(self):
        _, error = validate_commit_message("bad message")
        assert "feat" in error
        assert "fix" in error
        assert "docs" in error
        assert "chore" in error
        assert "ci" in error
        assert "refactor" in error
        assert "test" in error

    def test_error_shows_valid_scopes(self):
        _, error = validate_commit_message("bad message")
        assert "python" in error
        assert "terraform" in error
        assert "bash" in error
        assert "ansible" in error
        assert "container" in error
        assert "makefile" in error
        assert "standards" in error

    def test_error_shows_examples(self):
        _, error = validate_commit_message("bad message")
        assert "feat(python): add ruff configuration" in error
        assert "fix(ci): correct Docker image reference" in error

    def test_error_shows_specific_issue_for_invalid_type(self):
        _, error = validate_commit_message("update(python): something")
        assert 'invalid type "update"' in error

    def test_error_shows_specific_issue_for_invalid_scope(self):
        _, error = validate_commit_message("feat(invalid): something")
        assert 'invalid scope "invalid"' in error

    def test_error_shows_specific_issue_for_uppercase_description(self):
        _, error = validate_commit_message("feat(python): Something uppercase")
        assert "lowercase" in error

    def test_error_shows_specific_issue_for_trailing_period(self):
        _, error = validate_commit_message("feat(python): add something.")
        assert "period" in error


# ---------------------------------------------------------------------------
# main() entry point
# ---------------------------------------------------------------------------

class TestMain:
    """Test the main() entry point used by the pre-commit hook."""

    def test_valid_message_returns_zero(self, tmp_path):
        msg_file = tmp_path / "COMMIT_EDITMSG"
        msg_file.write_text("feat(python): add ruff configuration\n")
        assert main([str(msg_file)]) == 0

    def test_invalid_message_returns_one(self, tmp_path):
        msg_file = tmp_path / "COMMIT_EDITMSG"
        msg_file.write_text("bad message\n")
        assert main([str(msg_file)]) == 1

    def test_no_arguments_returns_one(self):
        assert main([]) == 1

    def test_missing_file_returns_one(self):
        assert main(["/nonexistent/COMMIT_EDITMSG"]) == 1

    def test_multiline_message_only_checks_first_line(self, tmp_path):
        msg_file = tmp_path / "COMMIT_EDITMSG"
        msg_file.write_text(
            "feat(python): add ruff configuration\n\nThis is the body.\n"
        )
        assert main([str(msg_file)]) == 0

    def test_merge_commit_returns_zero(self, tmp_path):
        msg_file = tmp_path / "COMMIT_EDITMSG"
        msg_file.write_text("Merge branch 'feature' into main\n")
        assert main([str(msg_file)]) == 0
