# Story 11.2: Implement `devrail init` Core Script

Status: review

## Story

As a developer adopting DevRail,
I want `devrail init` to generate all required configuration files based on my `.devrail.yml`,
so that my project is DevRail-compliant with a single command.

## Acceptance Criteria

1. Running `devrail init` in a project directory generates all standard DevRail files
2. The script reads `.devrail.yml` to determine languages, CI platform, and options
3. If no `.devrail.yml` exists, the script prompts interactively to create one
4. Existing files are handled per the conflict resolution strategy (prompt by default)
5. Generated files match the current template repos (github-repo-template, gitlab-repo-template)
6. The script is idempotent — safe to re-run
7. `--dry-run` shows what would be generated without writing files

## Tasks / Subtasks

- [x] Task 1: Create script skeleton with option parsing (AC: 1, 7)
  - [x] 1.1 Create `devrail-init.sh` in dev-toolchain repo with POSIX-compatible shebang and usage/help
  - [x] 1.2 Parse CLI options: `--languages`, `--ci`, `--all`, `--agents-only`, `--yes`, `--force`, `--dry-run`, `--version`
  - [x] 1.3 Implement dry-run mode (track operations, print summary, write nothing)

- [x] Task 2: Implement Layer 1 — Agent instruction files (AC: 1, 5)
  - [x] 2.1 Embed CLAUDE.md, AGENTS.md, .cursorrules, .opencode/agents.yaml content as heredocs
  - [x] 2.2 Write scaffold function that creates files with conflict detection
  - [x] 2.3 Implement `--agents-only` shortcut

- [x] Task 3: Implement Layer 2 — Pre-commit hooks (AC: 1, 2, 5)
  - [x] 3.1 Embed .pre-commit-config.yaml template with language-conditional hook blocks
  - [x] 3.2 Generate language-aware config based on `.devrail.yml` languages list
  - [x] 3.3 Check for `pre-commit` installation and print instructions if missing

- [x] Task 4: Implement Layer 3 — Makefile + container (AC: 1, 2, 4, 5)
  - [x] 4.1 Embed Makefile, DEVELOPMENT.md, .editorconfig, .gitignore, .gitleaksignore content
  - [x] 4.2 Implement `.devrail.yml` creation from `--languages` flag or interactive prompt
  - [x] 4.3 Implement Makefile merge strategy (detect markers, backup+include for non-DevRail Makefiles)
  - [x] 4.4 Implement .gitignore append-with-marker pattern

- [x] Task 5: Implement Layer 4 — CI pipelines (AC: 1, 2, 5)
  - [x] 5.1 Embed GitHub Actions ci.yml, PR template, CODEOWNERS
  - [x] 5.2 Embed GitLab CI .gitlab-ci.yml, MR template, CODEOWNERS
  - [x] 5.3 Select platform from `--ci` flag or interactive prompt

- [x] Task 6: Implement interactive mode (AC: 3)
  - [x] 6.1 Add interactive prompts for language selection (multi-select from 8 ecosystems)
  - [x] 6.2 Add interactive prompts for CI platform selection (github/gitlab/none)
  - [x] 6.3 Add 4-layer adoption prompts per design doc
  - [x] 6.4 Generate `.devrail.yml` from interactive responses

- [x] Task 7: Implement conflict resolution (AC: 4, 6)
  - [x] 7.1 Detect existing files before each write
  - [x] 7.2 Interactive mode: prompt with [s]kip / [o]verwrite / [b]ackup+overwrite
  - [x] 7.3 `--yes` mode: skip existing files
  - [x] 7.4 `--force` mode: overwrite without prompting

- [x] Task 8: Test and validate (AC: 5, 6, 7)
  - [x] 8.1 Write bats tests for option parsing and scaffold functions
  - [x] 8.2 Test greenfield: empty directory, all layers
  - [x] 8.3 Test retrofit: existing project with Makefile, verify merge strategy
  - [x] 8.4 Test idempotency: re-run produces no changes
  - [x] 8.5 Test dry-run: verify no files written
  - [x] 8.6 Test --agents-only: verify only Layer 1 files created
  - [x] 8.7 Verify generated files match template repo content

## Dev Notes

- Design doc: `_bmad-output/planning-artifacts/devrail-init-design.md` (Story 11.1, done)
- Implementation: single POSIX-compatible shell script with embedded heredocs
- Lives in dev-toolchain repo at `scripts/devrail-init.sh`
- File contents sourced from github-repo-template and gitlab-repo-template
- Makefile and DEVELOPMENT.md downloaded from GitHub raw URLs (too large for heredoc embedding)
- `make init` (container-side) remains separate — generates per-language tool configs (ruff.toml, etc.)
- `devrail init` (host-side) generates project structure files (Makefile, CI, agent files, etc.)

### References

- [Source: devrail-init-design.md] — CLI specification and design decisions
- [Source: github-repo-template/] — reference files for generation
- [Source: gitlab-repo-template/] — reference files for generation

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6

### Debug Log References

- `make check` passed on dev-toolchain repo
- 16/16 bats tests pass
- Manual testing: greenfield (19 files), idempotency (all skipped), dry-run (no files), agents-only (4 files), GitLab CI, Makefile backup+merge

### Completion Notes List

- Script is 1082 lines of bash (after shfmt formatting)
- Small files (agent instructions, .editorconfig, .gitleaksignore, CI workflows) embedded as heredocs
- Large files (Makefile, DEVELOPMENT.md) downloaded from `raw.githubusercontent.com/devrail-dev/github-repo-template/main/`
- Pre-commit config generated dynamically based on language list — only active hooks for declared languages
- GitHub CI generates 6 separate workflow files (lint, format, test, security, scan, docs) matching template structure
- Makefile merge: detects DevRail markers for in-place update, backs up non-DevRail Makefiles with include guidance
- .gitignore: appends below `# --- DevRail ---` marker, skips if marker already present
- Container version tag (`$DEVRAIL_VERSION`) flows through to all generated files
- PR: https://github.com/devrail-dev/dev-toolchain/pull/11

### File List

- `dev-toolchain/scripts/devrail-init.sh` — new script (created)
- `dev-toolchain/tests/test-devrail-init.sh` — new bats tests (created)
