# Story 12.1: Add New Language Ecosystem (Template)

Status: backlog

## Story

As a developer working in [LANGUAGE],
I want DevRail to support [LANGUAGE] with linting, formatting, security scanning, and testing,
so that I get the same DevRail experience as all other supported languages.

## Acceptance Criteria

1. The dev-toolchain container includes all [LANGUAGE] tools (linter, formatter, security scanner, test runner)
2. The Makefile supports [LANGUAGE] with lint, format, test, security, and fix targets
3. A canonical standards document exists at `standards/[language].md`
4. The devrail.dev site includes a [LANGUAGE] standards page
5. Both template repos include [LANGUAGE] pre-commit hooks (commented out)
6. `.devrail.yml` schema supports the new language entry
7. `make check` passes across all repos
8. A release is cut with the new language

## Tasks / Subtasks

- [ ] Task 1: Create install script (`dev-toolchain/scripts/install-[language].sh`)
- [ ] Task 2: Create test script (`dev-toolchain/tests/test-[language].sh`)
- [ ] Task 3: Update Dockerfile with language dependencies and install
- [ ] Task 4: Update Makefile with `HAS_[LANGUAGE]` detection and targets
- [ ] Task 5: Write `standards/[language].md`
- [ ] Task 6: Write `devrail.dev/content/docs/standards/[language].md`
- [ ] Task 7: Update both template `.pre-commit-config.yaml` files
- [ ] Task 8: Update both template `.devrail.yml` files
- [ ] Task 9: Update `devrail-yml-schema.md` with new language
- [ ] Task 10: Update `devrail.dev` docs index and language matrix
- [ ] Task 11: Update `STABILITY.md` and `README.md` in dev-toolchain
- [ ] Task 12: Run `make check` on all repos
- [ ] Task 13: Cut release

## Dev Notes

- This is a **template story** — clone and customize for each new language (Elixir, Java, C#, etc.)
- Follow the complete checklist in `standards/contributing.md` and the "Adding a New Language" section in MEMORY.md
- Pattern: COPY SDK from official image in builder stage → install-[language].sh verifies (Go, Rust) or installs (Ruby, JS)
- Pre-commit hooks: find appropriate community hooks or use local hooks
- The conventional-commits hook (v1.1.0) already accepts all current language scopes — new languages need a scope added

### References

- [Source: standards/contributing.md] — full checklist for adding a language
- [Source: MEMORY.md → Adding a New Language — Checklist] — file-level checklist

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
