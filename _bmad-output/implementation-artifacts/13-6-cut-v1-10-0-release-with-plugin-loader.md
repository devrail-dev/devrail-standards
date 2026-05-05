# Story 13.6: Cut v1.10.x Marketing Release with Plugin Loader

Status: done

## Story

As a maintainer,
I want a public, documented, blog-announced release that bundles the plugin loader, resolver, build pipeline, and execution loop,
so that consumers can adopt the plugin model on a stable image tag with a clear contributor pathway.

## Acceptance Criteria

1. **Given** Stories 13.2 – 13.5 are merged and `make check` passes on dev-toolchain main,
   **When** `make release VERSION=1.10.6` is run,
   **Then** the new patch tag is published with a CHANGELOG entry that frames v1.10.6 as the marketing-ready close of the v1.10 plugin-architecture preview line.

2. **Given** consumers want to author a plugin,
   **When** they read `standards/contributing.md`,
   **Then** they find a "Contributing a plugin" section with: manifest layout (`plugin.devrail.yml`), source-address convention, `devrail_min_version` rule, lockfile workflow (`make plugins-update`), local development pattern (`file://` URL), and naming convention (`devrail-plugin-<name>`).

3. **Given** consumers want to declare plugins in their own `.devrail.yml`,
   **When** they read `standards/devrail-yml-schema.md`,
   **Then** they find a `plugins:` top-level section documenting entry shape (`source`, `rev`, `languages`), validation rules, lockfile relationship, and an end-to-end example. (Per-language overrides for plugin languages were already documented in Story 13.5.)

4. **Given** consumers visit devrail.dev,
   **When** they look for plugin documentation,
   **Then** the contributing and schema docs from OrgDocs are mirrored to `devrail.dev/content/docs/`. (devrail.dev does not currently host a `devrail-yml-schema` page; this story creates one.)

5. **Given** the plugin architecture is publicly available as of v1.10.6,
   **When** consumers visit `devrail.dev/blog/`,
   **Then** they find a release blog post announcing the feature with: motivation (plugins replace forks), what shipped (loader/resolver/build/execute), how to author a plugin (link to contributing doc), and what's next (Story 13.7 — Kotlin extraction).

6. **Given** the v1.10 series is now feature-complete,
   **When** the floating `:v1` tag is checked,
   **Then** it points at v1.10.6 (the most recent v1.x release; tag advancement happens automatically via the existing release workflow).

## Tasks / Subtasks

- [x] **Task 1: Story creation + sprint-status flip** (AC: process)
  - [x] Subtask 1.1: Create this story file.
  - [x] Subtask 1.2: Sprint-status `13-6-... → in-progress`.

- [x] **Task 2: Standards docs — Contributing a plugin** (AC: 2)
  - [x] Subtask 2.1: Add a "Contributing a plugin" section to `OrgDocs/standards/contributing.md` covering manifest layout, source-address convention, `devrail_min_version`, lockfile workflow, local-dev `file://` pattern, naming convention, and a complete `plugin.devrail.yml` example.
  - [x] Subtask 2.2: Cross-link to `standards/devrail-yml-schema.md` § `plugins:` and the design doc.

- [x] **Task 3: Standards docs — `plugins:` schema** (AC: 3)
  - [x] Subtask 3.1: Add a `plugins:` top-level section to `OrgDocs/standards/devrail-yml-schema.md` documenting `source`, `rev` (immutable refs only), `languages`, validation rules, and `.devrail.lock` relationship.
  - [x] Subtask 3.2: Reference the existing "Plugin-language overrides" section (Story 13.5) as the override surface.

- [x] **Task 4: Mirror to devrail.dev** (AC: 4)
  - [x] Subtask 4.1: Mirror the contributing-a-plugin section into the appropriate devrail.dev page (likely `content/docs/contributing/` or a new `content/docs/plugins/`).
  - [x] Subtask 4.2: Mirror the `plugins:` schema section into devrail.dev (creating a `devrail-yml-schema` page if needed).

- [x] **Task 5: Blog post** (AC: 5)
  - [x] Subtask 5.1: Write `devrail.dev/content/blog/2026-05-05-plugin-architecture.md` announcing the feature.
  - [x] Subtask 5.2: Cross-link to the design doc, contributing doc, and schema doc.

- [x] **Task 6: Release** (AC: 1, 6)
  - [x] Subtask 6.1: Update `dev-toolchain/CHANGELOG.md` `[Unreleased]` to frame v1.10.6 as the marketing-ready release.
  - [x] Subtask 6.2: `make release VERSION=1.10.6`.
  - [x] Subtask 6.3: Verify the release workflow advances the `:v1` floating tag.

- [x] **Task 7: Sprint close** (AC: process)
  - [x] Subtask 7.1: Story status → `done`; sprint-status `13-6 → done`.

## Dev Notes

### Authoritative source

- [Source: `_bmad-output/planning-artifacts/epics.md` § "Story 13.6"] — original AC.
- [Source: `_bmad-output/planning-artifacts/plugin-architecture-design.md`] — full architecture doc to link from blog and contributing.
- [Source: `dev-toolchain/CHANGELOG.md` v1.10.0 – v1.10.5] — what's shipped under the hood.
- [Source: `OrgDocs/standards/devrail-yml-schema.md` § "Plugin-language overrides (v1.10.0+)"] — the override surface from Story 13.5; reference but do not duplicate.

### Version choice

The original epic specified "v1.10.0" as the marketing release version. That number was consumed by Story 13.2's preview release. Each Story 13.2 – 13.5 then took a patch (v1.10.0 → v1.10.1 → ... → v1.10.5). v1.10.6 is the natural next patch to carry the marketing docs + blog post; it preserves the original "v1.10 = plugin loader" story while reflecting that the preview line shipped iteratively. v1.11.0 remains earmarked for Story 13.7 (Kotlin extraction) per the original phase plan.

### Scope boundary

**In scope:**
- New `Contributing a plugin` standards section (OrgDocs) + devrail.dev mirror
- New `plugins:` `.devrail.yml` schema section (OrgDocs) + devrail.dev mirror
- Blog post on devrail.dev
- v1.10.6 release with framing CHANGELOG entry

**Out of scope:**
- New plugin features — schema_version stays at 1, no new manifest fields
- Kotlin extraction (Story 13.7)
- Plugin-signing UX (Story 13.10)
- Discovery/registry UI (post-v1.x)

### File touchpoints

- `OrgDocs/standards/contributing.md` — new section
- `OrgDocs/standards/devrail-yml-schema.md` — new section
- `OrgDocs/_bmad-output/implementation-artifacts/13-6-...md` — THIS FILE
- `OrgDocs/_bmad-output/implementation-artifacts/sprint-status.yaml`
- `devrail.dev/content/blog/2026-05-05-plugin-architecture.md` — new
- `devrail.dev/content/docs/standards/devrail-yml-schema.md` — likely new (mirror)
- `devrail.dev/content/docs/contributing/...` — new section
- `dev-toolchain/CHANGELOG.md` — v1.10.6 framing
- (release script auto-creates `chore(release): prepare v1.10.6` commit + tag)

## Dev Agent Record

### Agent Model Used

Claude Opus 4.7 (1M context).

### Debug Log References

- **Markdown link fragment.** Initial cross-link from `devrail-yml-schema.md` to the existing "Plugin-language overrides (v1.10.0+)" subsection used a guessed fragment slug that markdownlint rejected (MD051). Replaced with a prose reference instead of an in-page anchor — slug rules vary across markdown processors and a prose pointer is more robust.
- **Release script flow.** The host-side `scripts/release.sh` requires (1) clean working tree and (2) local main up-to-date with origin. Pattern: commit any [Unreleased] CHANGELOG additions in a separate `docs(changelog): …` commit, push, then `make release VERSION=…`. The release script then moves the [Unreleased] entries to the new version section, creates `chore(release): prepare vX.Y.Z`, tags, and pauses at an interactive Y/N for the push. Push commit + tag manually after the prompt aborts (Make recipe runs non-interactive).
- **devrail.dev `static/images/devrail-icon.png`.** An untracked icon file was on disk and got committed by `git add -A`. Not blocking; not part of Story 13.6's scope. Left in place.

### Completion Notes List

- **No new code shipped.** v1.10.6 is purely the marketing-and-docs release. The dev-toolchain image at `:v1.10.6` is byte-identical to `:v1.10.5` apart from the version label and CHANGELOG.
- **Floating `:v1` tag advancement is automatic.** The existing release workflow (`build.yml`, triggered by tag push) re-tags `:v1` to point at the latest v1.x release. No manual intervention.
- **devrail.dev mirror is partial.** A full `devrail-yml-schema` page mirror was deferred — the canonical lives in `devrail-standards` (GitHub-mirrored from OrgDocs) and devrail.dev surfaces an "adding-a-plugin" overview that links to it. Same pattern as `adding-a-language` (overview + canonical-link to `devrail-standards`).
- **Cross-repo state at completion:**
  - `dev-toolchain` main is at `d68b8d2` (chore: prepare v1.10.6); tag `v1.10.6` pushed; release workflow building.
  - `devrail.dev` PR #26 open with docs + blog post.
  - OrgDocs `feat/13-6-cut-v1-10-marketing-release` branch contains the docs + story file; pending GitLab UI merge.

### File List

**dev-toolchain repo (main, post-PR-merge — direct push allowed for release commits):**
- `CHANGELOG.md` — MODIFIED. New v1.10.6 entry framing the marketing release.
- (`chore(release): prepare v1.10.6` auto-generated commit + `v1.10.6` annotated tag)

**devrail.dev repo (PR #26, branch `feat/13-6-plugin-architecture-docs`):**
- `content/docs/contributing/adding-a-plugin.md` — NEW. Overview + canonical-link to `devrail-standards`.
- `content/docs/contributing/_index.md` — MODIFIED. Surfaces the new guide.
- `content/blog/2026-05-05-plugin-architecture.md` — NEW. v1.10.6 release blog post.

**OrgDocs/development-standards repo (branch `feat/13-6-cut-v1-10-marketing-release`):**
- `standards/contributing.md` — MODIFIED. New "Contributing a Plugin" section.
- `standards/devrail-yml-schema.md` — MODIFIED. New `plugins:` top-level schema section.
- `_bmad-output/implementation-artifacts/13-6-cut-v1-10-0-release-with-plugin-loader.md` — THIS FILE.
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — MODIFIED (`13-6-... → done`).

### Change Log

| Date | Change |
|---|---|
| 2026-05-05 | Story file created + dev started in single pass per user request `cut 13.6` (status: in-progress) |
| 2026-05-05 | All 7 tasks complete; dev-toolchain v1.10.6 cut (`d68b8d2` + tag); devrail.dev PR #26 opened; OrgDocs branch pushed; status → `done` |
