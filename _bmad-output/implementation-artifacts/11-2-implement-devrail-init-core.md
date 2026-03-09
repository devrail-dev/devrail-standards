# Story 11.2: Implement `devrail init` Core Script

Status: backlog

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

- [ ] Task 1: Implement core script (AC: 1, 2, 6)
  - [ ] 1.1 Create script following design from Story 11.1
  - [ ] 1.2 Implement `.devrail.yml` parsing
  - [ ] 1.3 Implement file generation for core files (Makefile, DEVELOPMENT.md, .editorconfig, .gitignore)
  - [ ] 1.4 Implement file generation for agent files (CLAUDE.md, AGENTS.md, .cursorrules)
  - [ ] 1.5 Implement file generation for pre-commit config (.pre-commit-config.yaml)
  - [ ] 1.6 Implement CI platform detection and generation (.github/workflows or .gitlab-ci.yml)

- [ ] Task 2: Implement interactive mode (AC: 3)
  - [ ] 2.1 Add interactive prompts for language selection
  - [ ] 2.2 Add interactive prompts for CI platform selection
  - [ ] 2.3 Generate `.devrail.yml` from interactive responses

- [ ] Task 3: Implement conflict resolution (AC: 4)
  - [ ] 3.1 Detect existing files before generation
  - [ ] 3.2 Implement prompt/skip/overwrite/merge strategies
  - [ ] 3.3 Default to prompt when files exist

- [ ] Task 4: Implement --dry-run (AC: 7)
  - [ ] 4.1 Add --dry-run flag that shows planned file operations without writing

- [ ] Task 5: Test and validate (AC: 5)
  - [ ] 5.1 Test against empty directory (greenfield)
  - [ ] 5.2 Test against existing project (retrofit)
  - [ ] 5.3 Test idempotency (re-run produces no changes)
  - [ ] 5.4 Verify generated files match template repos

## Dev Notes

- Blocked by Story 11.1 (design must be completed first)
- Implementation language TBD (bash script vs Go CLI vs Python CLI) — decided in 11.1
- Must follow DevRail critical rules (idempotent scripts, shared logging, etc.)

### References

- [Source: Story 11.1 design document] — CLI specification
- [Source: github-repo-template/] — reference files for generation
- [Source: gitlab-repo-template/] — reference files for generation

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
