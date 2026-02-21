"""Tests for conventional_commits.config module."""

from conventional_commits.config import (
    COMMIT_PATTERN,
    ERROR_TEMPLATE,
    VALID_SCOPES,
    VALID_TYPES,
)


class TestValidTypes:
    """Verify the valid types list matches DevRail standards."""

    def test_contains_all_required_types(self):
        expected = {"feat", "fix", "docs", "chore", "ci", "refactor", "test"}
        assert VALID_TYPES == expected

    def test_types_are_frozen(self):
        assert isinstance(VALID_TYPES, frozenset)

    def test_no_extra_types(self):
        expected = {"feat", "fix", "docs", "chore", "ci", "refactor", "test"}
        assert VALID_TYPES - expected == set()


class TestValidScopes:
    """Verify the valid scopes list matches DevRail standards."""

    def test_contains_all_required_scopes(self):
        expected = {
            "python",
            "terraform",
            "bash",
            "ansible",
            "container",
            "ci",
            "makefile",
            "standards",
        }
        assert VALID_SCOPES == expected

    def test_scopes_are_frozen(self):
        assert isinstance(VALID_SCOPES, frozenset)

    def test_no_extra_scopes(self):
        expected = {
            "python",
            "terraform",
            "bash",
            "ansible",
            "container",
            "ci",
            "makefile",
            "standards",
        }
        assert VALID_SCOPES - expected == set()


class TestCommitPattern:
    """Verify the regex pattern is defined."""

    def test_pattern_is_string(self):
        assert isinstance(COMMIT_PATTERN, str)

    def test_pattern_starts_with_anchor(self):
        assert COMMIT_PATTERN.startswith("^")

    def test_pattern_ends_with_anchor(self):
        assert COMMIT_PATTERN.endswith("$")


class TestErrorTemplate:
    """Verify the error template contains required information."""

    def test_template_contains_format_example(self):
        assert "type(scope): description" in ERROR_TEMPLATE

    def test_template_contains_types_placeholder(self):
        assert "{types}" in ERROR_TEMPLATE

    def test_template_contains_scopes_placeholder(self):
        assert "{scopes}" in ERROR_TEMPLATE

    def test_template_contains_message_placeholder(self):
        assert "{message}" in ERROR_TEMPLATE

    def test_template_contains_examples(self):
        assert "feat(python):" in ERROR_TEMPLATE
        assert "fix(ci):" in ERROR_TEMPLATE
        assert "docs(standards):" in ERROR_TEMPLATE
