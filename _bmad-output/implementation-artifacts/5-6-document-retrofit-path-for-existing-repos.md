# Story 5.6: Document Retrofit Path for Existing Repos

Status: done

## Story

As a developer,
I want clear documentation on how to add DevRail to an existing GitLab repo,
so that I can standardize repos that weren't created from the template.

## Acceptance Criteria

1. **Given** the gitlab-repo-template is complete, **When** the retrofit documentation is written, **Then** README.md includes a "Retrofit Existing Project" section with step-by-step instructions
2. **Given** the retrofit section exists, **When** a developer reads it, **Then** instructions list which files to copy and in what order
3. **Given** the retrofit section exists, **When** a developer reads it, **Then** instructions explain how to configure .devrail.yml for the project's languages
4. **Given** the retrofit section exists, **When** a developer follows the steps, **Then** `make install-hooks` and a first `make check` run are included as verification steps

## Tasks / Subtasks

- [x] Task 1: Write retrofit documentation in README.md (AC: #1, #2, #3, #4)
  - [x] 1.1: Add "Retrofit Existing Project" section to README.md
  - [x] 1.2: Document the file copy order with rationale (core config first, then CI, then agent files)
  - [x] 1.3: Document .devrail.yml configuration for common language combinations
  - [x] 1.4: Document verification steps: `make install-hooks`, `make check`
  - [x] 1.5: Document common issues and troubleshooting (container pull, hook installation, CI pipeline activation)
  - [x] 1.6: Include a checklist format for easy tracking

## Dev Notes

### Critical Architecture Constraints

**This is the FINAL story in Epic 5.** After this story, the gitlab-repo-template is complete and ready for use. The template must support both new projects (created from the template) and existing projects (retrofitted with DevRail files).

**Retrofit MUST be documented, not automated.** For MVP, the retrofit path is a documented set of manual steps. Automation (e.g., a `devrail init` command) is post-MVP.

**The retrofit path must produce a project indistinguishable from one created from the template.** After following the retrofit instructions, the project should have all the same files and CI behavior as a fresh template project.

**Source:** [prd.md - FR24: Developer can retrofit an existing repo]

### Retrofit File Copy Order

The order matters because some files reference others:

1. **Core configuration (foundation):**
   - `.devrail.yml` — configure languages for your project
   - `.editorconfig` — copy as-is
   - `.gitignore` — merge with existing .gitignore (don't overwrite)
   - `Makefile` — copy as-is (or merge if project has existing Makefile)

2. **Pre-commit hooks (local enforcement):**
   - `.pre-commit-config.yaml` — copy and uncomment hooks for your languages
   - Run `make install-hooks` to activate

3. **Agent instruction files (AI integration):**
   - `DEVELOPMENT.md` — copy as-is
   - `CLAUDE.md` — copy as-is
   - `AGENTS.md` — copy as-is
   - `.cursorrules` — copy as-is
   - `.opencode/agents.yaml` — copy as-is

4. **CI pipeline (remote enforcement):**
   - `.gitlab-ci.yml` — copy as-is
   - Enable "Pipelines must succeed" in GitLab project settings

5. **Project documentation:**
   - `.gitlab/merge_request_templates/default.md` — copy as-is
   - `.gitlab/CODEOWNERS` — copy and configure for your team
   - `CHANGELOG.md` — copy if not already present

6. **Verification:**
   - Run `make install-hooks`
   - Run `make check` — fix any issues found
   - Create a test MR to verify CI pipeline works

### Retrofit Checklist Format

```markdown
## Retrofit Existing Project

To add DevRail standards to an existing GitLab repository:

### Step 1: Core Configuration

- [ ] Copy `.devrail.yml` and uncomment your project's languages
- [ ] Copy `.editorconfig`
- [ ] Merge `.gitignore` patterns into your existing .gitignore
- [ ] Copy `Makefile` (or merge targets if you have an existing Makefile)

### Step 2: Pre-Commit Hooks

- [ ] Copy `.pre-commit-config.yaml` and uncomment hooks for your languages
- [ ] Run `make install-hooks`

### Step 3: Agent Instruction Files

- [ ] Copy `DEVELOPMENT.md`, `CLAUDE.md`, `AGENTS.md`, `.cursorrules`
- [ ] Copy `.opencode/agents.yaml` (create `.opencode/` directory first)

### Step 4: CI Pipeline

- [ ] Copy `.gitlab-ci.yml`
- [ ] Enable "Pipelines must succeed" in Settings > General > Merge requests

### Step 5: Project Documentation

- [ ] Copy `.gitlab/merge_request_templates/default.md`
- [ ] Copy `.gitlab/CODEOWNERS` and configure for your team
- [ ] Copy `CHANGELOG.md` if not already present

### Step 6: Verify

- [ ] Run `make check` and fix any issues
- [ ] Create a test commit to verify pre-commit hooks fire
- [ ] Create a test MR to verify CI pipeline runs
```

### Common Troubleshooting Issues

Document these common issues and solutions:

1. **Container pull failure:** Ensure Docker is running and can pull from `ghcr.io`. Run `docker pull ghcr.io/devrail-dev/dev-toolchain:v1` to test.
2. **Pre-commit install failure:** Ensure `pre-commit` is installed. Install via `pip install pre-commit` or `brew install pre-commit`.
3. **Makefile conflicts:** If the project has an existing Makefile, merge the DevRail targets. The DevRail Makefile structure (variables, .PHONY, public targets, internal targets) can coexist with project-specific targets.
4. **.gitignore conflicts:** Do not overwrite the existing .gitignore. Merge the DevRail patterns into it.
5. **CI pipeline not running:** Ensure the GitLab project has CI/CD enabled in Settings > General > Visibility, project features, permissions.

### Previous Story Intelligence

**Stories 5.1-5.5 created:** All template files are now in place:
- Story 5.1: Makefile, .devrail.yml, .editorconfig, .gitignore, LICENSE
- Story 5.2: .pre-commit-config.yaml
- Story 5.3: DEVELOPMENT.md, CLAUDE.md, AGENTS.md, .cursurrules, .opencode/agents.yaml
- Story 5.4: .gitlab-ci.yml
- Story 5.5: .gitlab/merge_request_templates/default.md, .gitlab/CODEOWNERS, README.md (full), CHANGELOG.md

**Build on previous stories:**
- UPDATE `README.md` — add the "Retrofit Existing Project" section to the existing README

### Project Structure Notes

This story modifies 1 existing file:

```
gitlab-repo-template/
└── README.md                 ← THIS STORY (update — add retrofit section)
```

No new files are created.

### Anti-Patterns to Avoid

1. **DO NOT** create an automation script or CLI tool — retrofit is documented manual steps for MVP
2. **DO NOT** instruct users to delete their existing configuration — always merge, never overwrite
3. **DO NOT** assume the target project has Docker installed — include Docker as a prerequisite
4. **DO NOT** skip the verification steps — `make check` and a test MR must be part of the instructions
5. **DO NOT** add GitLab-specific API automation (project settings changes) — document what settings to change manually

### Conventional Commits for This Story

- Scope: `template`
- Example: `docs(template): add retrofit instructions for existing GitLab repos`

### References

- [architecture.md - Complete Per-Repo Directory Structures - gitlab-repo-template]
- [prd.md - Functional Requirements FR24]
- [epics.md - Epic 5: GitLab Project Template - Story 5.6]
- [Stories 5.1-5.5 - Complete template file set]

## Senior Developer Review (AI)

**Reviewer:** Claude Opus 4.6 (Adversarial Review)
**Date:** 2026-02-20

### Acceptance Criteria Status

| AC | Status | Notes |
|---|---|---|
| AC1: README includes "Retrofit Existing Project" section | IMPLEMENTED | Section present with 6-step instructions |
| AC2: Instructions list files to copy and order | IMPLEMENTED | Ordered: core config, pre-commit, agent files, CI, project docs, verify |
| AC3: Instructions explain .devrail.yml configuration | IMPLEMENTED | Step 1 mentions uncommenting project languages |
| AC4: make install-hooks and make check as verification | IMPLEMENTED | Step 6 includes `make check`, test commit, and test MR |

### Findings

1. **INFO - Retrofit section follows correct file copy order**: Core config first (foundation), pre-commit (local enforcement), agent files (AI integration), CI (remote enforcement), project docs (templates), verify (end-to-end). Matches the story spec exactly.

2. **INFO - Prerequisites documented**: Docker and Make with verification command. Correct.

3. **INFO - Merge semantics emphasized**: Instructions say "Merge `.gitignore` patterns" and "Copy `Makefile` (or merge targets if you have an existing Makefile)". Follows the anti-pattern guidance of never overwriting existing files.

4. **INFO - Troubleshooting section covers all 5 common issues**: Container pull, pre-commit install, Makefile conflicts, .gitignore conflicts, CI pipeline not running. Comprehensive.

5. **LOW - Retrofit section doesn't mention LICENSE**: The retrofit instructions don't include copying the LICENSE file. This is arguably correct -- existing repos already have their own license. But it could be mentioned as "Keep your existing LICENSE or copy if needed." NOT FIXED (design choice).

### Files Modified During Review

None -- this story's implementation is correct as-is.

## Dev Agent Record

### Agent Model Used
Claude Opus 4.6 (claude-opus-4-6)

### Debug Log References

### Completion Notes List
- Added "Retrofit Existing Project" section to README.md with comprehensive step-by-step instructions
- Documented 6-step file copy order with rationale:
  - Step 1: Core Configuration (foundation files other components depend on)
  - Step 2: Pre-Commit Hooks (local enforcement)
  - Step 3: Agent Instruction Files (AI integration)
  - Step 4: CI Pipeline (remote enforcement)
  - Step 5: Project Documentation (MR templates, CODEOWNERS, changelog)
  - Step 6: Verify (end-to-end validation)
- Each step includes checkbox items for easy tracking
- Documented prerequisites (Docker and Make) with verification command
- Included .devrail.yml configuration guidance (uncomment languages)
- Documented verification steps: `make check`, test commit for hooks, test MR for CI
- Added Troubleshooting section covering 5 common issues:
  - Container pull failure with test command
  - Pre-commit install failure with installation options
  - Makefile conflicts with merge guidance
  - .gitignore conflicts with merge-not-overwrite instruction
  - CI pipeline not running with GitLab settings path
- All instructions use merge semantics (never overwrite existing files)

### File List
- `gitlab-repo-template/README.md` (updated -- added retrofit section)
