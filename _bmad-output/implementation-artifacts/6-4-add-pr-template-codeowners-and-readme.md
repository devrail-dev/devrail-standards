# Story 6.4: Add PR Template, CODEOWNERS, and README

Status: done

## Story

As a developer,
I want pull request templates, CODEOWNERS, and documentation pre-configured,
so that every PR follows a consistent format and the project is well-documented from the start.

## Acceptance Criteria

1. **Given** the github-repo-template exists, **When** .github/PULL_REQUEST_TEMPLATE.md is added, **Then** it provides a structured PR template with summary, test plan, and checklist
2. **Given** the github-repo-template exists, **When** .github/CODEOWNERS is added, **Then** it is present with a placeholder structure that teams can customize
3. **Given** the github-repo-template exists, **When** README.md is completed, **Then** it follows the standard structure including a "Retrofit Existing Project" section with step-by-step instructions
4. **Given** the github-repo-template exists, **When** CHANGELOG.md is added, **Then** it is initialized with Keep a Changelog format

## Tasks / Subtasks

- [x] Task 1: Create GitHub PR template (AC: #1)
  - [x] 1.1: Create `.github/PULL_REQUEST_TEMPLATE.md`
  - [x] 1.2: Include structured sections: Summary, Changes, Test Plan, Checklist
  - [x] 1.3: Include checklist items for: `make check` passing, conventional commits, documentation updated, CHANGELOG updated
  - [x] 1.4: Include placeholder for linked issues
- [x] Task 2: Create CODEOWNERS (AC: #2)
  - [x] 2.1: Create `.github/CODEOWNERS`
  - [x] 2.2: Add placeholder structure with comments explaining how to configure ownership patterns
  - [x] 2.3: Include example entries for common patterns (Makefile, .github/, .devrail.yml)
- [x] Task 3: Complete README.md with retrofit section (AC: #3)
  - [x] 3.1: Update `README.md` (exists as stub from Story 6.1) with full content
  - [x] 3.2: Write project title and one-line description placeholder
  - [x] 3.3: Add badge placeholders (CI status, license)
  - [x] 3.4: Write quick start section (3 steps: use template, configure .devrail.yml, make install-hooks)
  - [x] 3.5: Write usage section with `make help` output reference
  - [x] 3.6: Write configuration section explaining .devrail.yml
  - [x] 3.7: Write contributing section linking to DEVELOPMENT.md
  - [x] 3.8: Write "Retrofit Existing Project" section with step-by-step instructions
  - [x] 3.9: Add license section
- [x] Task 4: Create CHANGELOG.md (AC: #4)
  - [x] 4.1: Create `CHANGELOG.md` with Keep a Changelog header
  - [x] 4.2: Add `[Unreleased]` section with initial template setup entry

## Dev Notes

### Critical Architecture Constraints

**This is the FINAL story in Epic 6.** After this story, the github-repo-template is complete and ready for use. Unlike Epic 5 which has a separate retrofit story (5.6), Epic 6 combines the retrofit documentation into this story's README.

**PR template location is GitHub-specific.** GitHub uses `.github/PULL_REQUEST_TEMPLATE.md` for the default PR template. This differs from GitLab which uses `.gitlab/merge_request_templates/default.md`.

**CODEOWNERS location is GitHub-specific.** GitHub supports CODEOWNERS in `.github/CODEOWNERS`, `CODEOWNERS`, or `docs/CODEOWNERS`. We use `.github/CODEOWNERS` for consistency with the `.github/` directory structure.

**Source:** [architecture.md - Complete Per-Repo Directory Structures - github-repo-template]

### PR Template Content

The PR template should be functionally equivalent to the GitLab MR template (Story 5.5) but adapted for GitHub conventions:

```markdown
## Summary

<!-- Brief description of the changes -->

## Changes

<!-- List the key changes made -->

-

## Related Issues

<!-- Link related issues: Closes #123, Relates to #456 -->

## Test Plan

<!-- How were these changes tested? -->

- [ ] `make check` passes
- [ ] Manual testing completed (describe below)

## Checklist

- [ ] Code follows project standards (see DEVELOPMENT.md)
- [ ] All commits use conventional commit format
- [ ] Documentation updated (if applicable)
- [ ] CHANGELOG.md updated (if applicable)
- [ ] No secrets or credentials in the changeset
```

### CODEOWNERS Structure

```
# .github/CODEOWNERS
# GitHub Code Owners file
# Docs: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners
#
# Each line defines a file pattern and the users/teams responsible.
# The last matching pattern takes precedence.
#
# Examples:
# * @default-team
# Makefile @devops-team
# .github/ @devops-team
# .devrail.yml @devops-team
# *.py @python-team
# *.tf @infra-team
```

### README with Retrofit Section

The README follows the standard structure (same as Story 5.5) but includes an additional "Retrofit Existing Project" section (equivalent to what Story 5.6 adds to the GitLab template):

```markdown
## Retrofit Existing Project

To add DevRail standards to an existing GitHub repository:

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
- [ ] Copy `.opencode/agents.yaml`

### Step 4: CI Workflows
- [ ] Copy `.github/workflows/` directory (lint.yml, format.yml, security.yml, test.yml, docs.yml)
- [ ] Configure branch protection: Settings > Branches > Require status checks

### Step 5: Project Documentation
- [ ] Copy `.github/PULL_REQUEST_TEMPLATE.md`
- [ ] Copy `.github/CODEOWNERS` and configure for your team
- [ ] Copy `CHANGELOG.md` if not already present

### Step 6: Verify
- [ ] Run `make check` and fix any issues
- [ ] Create a test commit to verify pre-commit hooks fire
- [ ] Create a test PR to verify CI workflows run
```

### GitHub vs GitLab Documentation Differences

The README content differs from the GitLab template in these specific areas:

| Section | GitHub | GitLab |
|---|---|---|
| Quick start | "Use this template" button | Fork or create from template |
| CI setup | Branch protection > Require status checks | Settings > Pipelines must succeed |
| Retrofit CI step | Copy `.github/workflows/` directory | Copy `.gitlab-ci.yml` |
| Retrofit PR step | Copy `.github/PULL_REQUEST_TEMPLATE.md` | Copy `.gitlab/merge_request_templates/` |

### CHANGELOG Format

Identical to Story 5.5:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Conventional Commits](https://www.conventionalcommits.org/).

## [Unreleased]

### Added
- Initial project setup from DevRail GitHub template
```

### Previous Story Intelligence

**Story 6.1 created:** Makefile, .devrail.yml, .editorconfig, .gitignore, LICENSE, README.md (stub)

**Story 6.2 created:** .pre-commit-config.yaml, DEVELOPMENT.md, CLAUDE.md, AGENTS.md, .cursurrules, .opencode/agents.yaml

**Story 6.3 created:** .github/workflows/lint.yml, format.yml, security.yml, test.yml, docs.yml

**Story 5.5 created (in gitlab-repo-template):** .gitlab/merge_request_templates/default.md, .gitlab/CODEOWNERS, README.md (full), CHANGELOG.md — the functional equivalent for GitLab

**Story 5.6 created (in gitlab-repo-template):** Retrofit documentation in README — adapt this for GitHub

**Build on previous stories:**
- UPDATE `README.md` (exists as stub from Story 6.1) — add full content including retrofit section
- CREATE `.github/PULL_REQUEST_TEMPLATE.md` (new)
- CREATE `.github/CODEOWNERS` (new, in the `.github/` directory already created by Story 6.3)
- CREATE `CHANGELOG.md` (new)

### Project Structure Notes

This story creates 3 new files and updates 1 existing file:

```
github-repo-template/
├── .github/
│   ├── CODEOWNERS                       ← THIS STORY
│   └── PULL_REQUEST_TEMPLATE.md         ← THIS STORY
├── CHANGELOG.md                         ← THIS STORY
└── README.md                            ← THIS STORY (update from stub)
```

### Anti-Patterns to Avoid

1. **DO NOT** put CODEOWNERS at the repo root — use `.github/CODEOWNERS` for consistency with GitHub conventions
2. **DO NOT** make the PR template content different from the MR template in meaning — only format and platform references should differ
3. **DO NOT** add real badge URLs — use placeholder format with TODO comments
4. **DO NOT** create an automation script for retrofit — documented manual steps for MVP
5. **DO NOT** modify any files from previous stories (Makefile, workflows, agent files) unless fixing a verified issue
6. **DO NOT** include commented-out code in templates — templates should be clean and ready to use
7. **DO NOT** skip the retrofit section — unlike the GitLab template (which has a separate Story 5.6), the GitHub template includes retrofit docs directly in this story

### Conventional Commits for This Story

- Scope: `template`
- Example: `feat(template): add PR template, CODEOWNERS, README with retrofit section, and CHANGELOG`

### References

- [architecture.md - Documentation Patterns - README structure]
- [architecture.md - Complete Per-Repo Directory Structures - github-repo-template]
- [prd.md - Functional Requirements FR18, FR23, FR24]
- [epics.md - Epic 6: GitHub Project Template - Story 6.4]
- [Story 5.5 - GitLab MR templates and CODEOWNERS (cross-reference for parity)]
- [Story 5.6 - GitLab retrofit documentation (cross-reference for parity)]
- [Stories 6.1-6.3 - All previously created files]

## Senior Developer Review (AI)

**Reviewer:** Claude Opus 4.6 (Adversarial Review)
**Date:** 2026-02-20

### Acceptance Criteria Status

| AC | Status | Notes |
|---|---|---|
| AC1: PR template with structured sections | IMPLEMENTED | Summary, Changes, Related Issues, Test Plan, Checklist -- functionally equivalent to GitLab MR template |
| AC2: CODEOWNERS with placeholder structure | IMPLEMENTED | In `.github/CODEOWNERS` with commented examples, GitHub docs link |
| AC3: README with standard structure + retrofit | IMPLEMENTED | Full standard structure with 6-step retrofit section |
| AC4: CHANGELOG with Keep a Changelog format | IMPLEMENTED | Standard header, [Unreleased] section with initial entry |

### Findings

1. **INFO - PR template is functionally equivalent to GitLab MR template**: Both have identical sections (Summary, Changes, Related Issues, Test Plan, Checklist) with the same checklist items. Content is byte-for-byte identical. Good.

2. **INFO - CODEOWNERS correctly uses GitHub path and docs link**: `.github/CODEOWNERS` with link to GitHub docs (not GitLab). Examples reference `.github/` instead of `.gitlab-ci.yml`. Correct platform-specific adaptation.

3. **INFO - README has complete retrofit section**: 6-step process with checklists. Steps correctly reference GitHub-specific paths (`.github/workflows/`, `.github/PULL_REQUEST_TEMPLATE.md`, `.github/CODEOWNERS`) and GitHub-specific settings (branch protection). Correct platform adaptation.

4. **INFO - README includes branch protection and template repository setup sections**: Configuration section documents both branch protection and how to enable the GitHub template repository feature. Unique to GitHub template. Correct.

5. **LOW - README retrofit section doesn't mention LICENSE**: Same as GitLab template (Story 5.6). Existing repos typically have their own license. NOT FIXED (consistent with GitLab template approach).

6. **INFO - CHANGELOG uses "DevRail GitHub template" vs GitLab's "DevRail GitLab template"**: Platform-specific initial entry. Correct differentiation.

### Files Modified During Review

None -- this story's implementation is correct as-is.

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (claude-opus-4-6)

### Debug Log References

### Completion Notes List

- Created `.github/PULL_REQUEST_TEMPLATE.md` with structured sections: Summary, Changes, Related Issues, Test Plan (with `make check` and manual testing checkboxes), and Checklist (standards compliance, conventional commits, documentation, CHANGELOG, no secrets)
- Created `.github/CODEOWNERS` with placeholder structure including documentation link, explanation of how patterns work and precedence, and example entries for common patterns (wildcard default team, Makefile, .github/, .devrail.yml, *.py, *.tf)
- Updated `README.md` from stub to full content including: project title/description placeholder, CI status and license badge placeholders, 3-step quick start ("Use this template" button, configure .devrail.yml, make install-hooks), usage table with all make targets, configuration section (.devrail.yml example, branch protection setup, GitHub template repository setup), contributing section linking to DEVELOPMENT.md, complete 6-step "Retrofit Existing Project" section with checklists for core config, pre-commit, agent files, CI workflows, project docs, and verification
- Created `CHANGELOG.md` with Keep a Changelog format header, Conventional Commits adherence note, [Unreleased] section with initial template setup entry

### File List

- `github-repo-template/.github/PULL_REQUEST_TEMPLATE.md`
- `github-repo-template/.github/CODEOWNERS`
- `github-repo-template/CHANGELOG.md`
- `github-repo-template/README.md` (updated from stub)
