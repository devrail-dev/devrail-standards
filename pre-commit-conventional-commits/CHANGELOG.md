# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-02-20

### Added

- Conventional commit message validation hook for pre-commit v3+
- DevRail-specific types: feat, fix, docs, chore, ci, refactor, test
- DevRail-specific scopes: python, terraform, bash, ansible, container, ci, makefile, standards
- Clear, actionable error messages on commit rejection
- Merge and revert commit pass-through
- Comprehensive test suite covering all type/scope combinations
- DevRail standard project files (.devrail.yml, .editorconfig, Makefile, agent instructions)
- Pre-commit config with language-appropriate linting, formatting, gitleaks, and terraform-docs hooks
- `make install-hooks` target for one-command pre-commit setup
