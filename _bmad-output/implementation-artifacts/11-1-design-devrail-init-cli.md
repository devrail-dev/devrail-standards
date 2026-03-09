# Story 11.1: Design `devrail init` CLI and Adoption Script

Status: ready-for-dev

## Story

As a developer adopting DevRail,
I want to run a single command that scaffolds all DevRail configuration files for my project,
so that I can progressively integrate DevRail without manually copying files from templates.

## Acceptance Criteria

1. A design document exists specifying the `devrail init` CLI interface, options, and behavior
2. The design covers all three adoption paths: partial (wedge), retrofit (brownfield), and template (greenfield)
3. The design specifies which files are generated and how existing files are handled (merge vs overwrite vs skip)
4. The design addresses `.devrail.yml` as the input configuration driving all scaffolding
5. The design is validated against the PRD Phase 2a requirements

## Tasks / Subtasks

- [ ] Task 1: Research existing adoption patterns (AC: 2)
  - [ ] 1.1 Review the product brief's Phase 2a description
  - [ ] 1.2 Catalog what files `make init` currently generates inside the container
  - [ ] 1.3 Identify gaps between `make init` and a full `devrail init` experience
  - [ ] 1.4 Document the three adoption paths and what each requires

- [ ] Task 2: Design the CLI interface (AC: 1, 3, 4)
  - [ ] 2.1 Define command syntax: `devrail init [options]`
  - [ ] 2.2 Define options: `--languages`, `--ci-platform`, `--force`, `--dry-run`, etc.
  - [ ] 2.3 Specify file generation matrix: which files for which languages/platforms
  - [ ] 2.4 Define conflict resolution strategy (existing files: prompt, skip, merge, overwrite)
  - [ ] 2.5 Define `.devrail.yml` as the primary input with interactive prompts as fallback

- [ ] Task 3: Write the design document (AC: 1, 5)
  - [ ] 3.1 Create design doc in `_bmad-output/planning-artifacts/`
  - [ ] 3.2 Include CLI interface specification
  - [ ] 3.3 Include file generation matrix
  - [ ] 3.4 Include adoption path workflows
  - [ ] 3.5 Validate against PRD Phase 2a requirements

## Dev Notes

- `make init` / `make _init` already exists in dev-toolchain (Story 1.4.0) — scaffolds ruff.toml, .shellcheckrc, .tflint.hcl, etc.
- `devrail init` would be a HOST-side script (not container-side) that also generates: .devrail.yml, .pre-commit-config.yaml, Makefile, CLAUDE.md, AGENTS.md, .cursorrules, .github/ or .gitlab-ci.yml, DEVELOPMENT.md
- The script should be distributable as a single shell script (curl-pipe-bash pattern) or via npm/pip
- Key question: should this be a new repo (`devrail-cli`) or live in `dev-toolchain`?
- Product brief Phase 2a: "devrail init adoption script for progressive DevRail integration"

### References

- [Source: product-brief-development-standards-2026-03-06.md] — Phase 2a description
- [Source: dev-toolchain/Makefile] — existing `make init` target
- [Source: github-repo-template/] — greenfield template files
- [Source: gitlab-repo-template/] — greenfield template files

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
