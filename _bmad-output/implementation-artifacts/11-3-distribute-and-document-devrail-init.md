# Story 11.3: Distribute and Document `devrail init`

Status: backlog

## Story

As a developer,
I want to install `devrail init` easily and have clear documentation,
so that I can adopt DevRail in my project without reading the full standards first.

## Acceptance Criteria

1. The `devrail init` script is available via a simple install command (curl, npm, pip, or similar)
2. Installation instructions are documented on devrail.dev
3. A getting-started guide walks through the full adoption flow
4. The devrail.dev site includes a "Quick Start" page with `devrail init` as the entry point
5. `make check` passes on all updated repos

## Tasks / Subtasks

- [ ] Task 1: Set up distribution (AC: 1)
  - [ ] 1.1 Choose distribution mechanism based on 11.1 design
  - [ ] 1.2 Publish the script/package to the chosen registry
  - [ ] 1.3 Test installation from scratch on a clean system

- [ ] Task 2: Write documentation (AC: 2, 3, 4)
  - [ ] 2.1 Add install instructions to devrail.dev
  - [ ] 2.2 Write getting-started guide covering all three adoption paths
  - [ ] 2.3 Update the devrail.dev Quick Start page
  - [ ] 2.4 Add CLI reference documentation

- [ ] Task 3: Validate end-to-end (AC: 5)
  - [ ] 3.1 Test full flow: install → init → make check (greenfield)
  - [ ] 3.2 Test full flow: install → init → make check (retrofit)
  - [ ] 3.3 Run `make check` on all updated repos

## Dev Notes

- Blocked by Story 11.2 (implementation must be completed first)
- Distribution options to consider: GitHub releases (curl-pipe-bash), npm package, pip package, Homebrew tap
- The devrail.dev site currently has Getting Started docs — these need updating, not replacing

### References

- [Source: devrail.dev/content/docs/] — existing documentation
- [Source: Story 11.2] — implementation to distribute

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
