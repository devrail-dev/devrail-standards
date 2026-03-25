# Story 14.4: Write Kotlin Support Blog Post

Status: done

## Story

As a DevRail user,
I want to read a blog post announcing Kotlin language support,
so that I understand the new capabilities and how to use them in my Kotlin projects.

## Acceptance Criteria

1. Blog post is created at `devrail.dev/content/blog/2026-03-23-kotlin-support.md`
2. Post covers ktlint, detekt, Gradle testing, and Android Lint integration
3. Post follows existing blog post format and Hugo/Docsy front matter conventions
4. Post includes `.devrail.yml` configuration example for Kotlin
5. `make check` passes on the devrail.dev content

## Tasks / Subtasks

- [x] Task 1: Write the blog post (AC: 1, 2, 3, 4)
  - [x] 1.1 Review existing blog posts for format and tone
  - [x] 1.2 Write post covering: ktlint linting/formatting, detekt static analysis, Gradle test runner, Android Lint for Android projects, OWASP dependency-check
  - [x] 1.3 Include `.devrail.yml` example and container pull command

- [ ] Task 2: Validate (AC: 5)
  - [ ] 2.1 Run `make check` on devrail.dev content

## Dev Notes

- Blog post format: Hugo front matter (title, date, description), clean technical prose, code examples, no emojis
- Previous language blog posts: `2026-03-04-rust-support.md`, `2026-03-05-terragrunt-support.md`
- Key messaging: Kotlin is the 10th language ecosystem in DevRail, first JVM language, covers both server-side and Android Kotlin
- Note the Android Lint limitation (requires Android SDK) and Gradle-first approach

### References

- [Source: devrail.dev/content/blog/] -- existing blog posts for format reference
- [Source: standards/kotlin.md] -- Kotlin standards document

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6

### Debug Log References

- Reviewed 4 existing blog posts for format/tone consistency

### Completion Notes List

- Blog post written at `devrail.dev/content/blog/2026-03-23-kotlin-support.md` with Hugo front matter
- Post covers: ktlint, detekt, Gradle testing, OWASP dependency-check, Android Lint CI integration
- Includes `.devrail.yml` example, Makefile targets, pre-commit hooks, devrail init command
- Documents Android Lint limitation and Android SDK CI workaround with GitHub Actions example
- Highlights Kotlin as 10th language ecosystem, first JVM language in DevRail
- Matches existing blog post format: clean technical prose, code examples, no emojis

### File List

- `devrail.dev/content/blog/2026-03-23-kotlin-support.md` -- new (Kotlin support blog post)
