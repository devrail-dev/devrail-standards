# Story 13.6: Cut v1.10.x Marketing Release with Plugin Loader

Status: in-progress

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

- [ ] **Task 1: Story creation + sprint-status flip** (AC: process)
  - [ ] Subtask 1.1: Create this story file.
  - [ ] Subtask 1.2: Sprint-status `13-6-... → in-progress`.

- [ ] **Task 2: Standards docs — Contributing a plugin** (AC: 2)
  - [ ] Subtask 2.1: Add a "Contributing a plugin" section to `OrgDocs/standards/contributing.md` covering manifest layout, source-address convention, `devrail_min_version`, lockfile workflow, local-dev `file://` pattern, naming convention, and a complete `plugin.devrail.yml` example.
  - [ ] Subtask 2.2: Cross-link to `standards/devrail-yml-schema.md` § `plugins:` and the design doc.

- [ ] **Task 3: Standards docs — `plugins:` schema** (AC: 3)
  - [ ] Subtask 3.1: Add a `plugins:` top-level section to `OrgDocs/standards/devrail-yml-schema.md` documenting `source`, `rev` (immutable refs only), `languages`, validation rules, and `.devrail.lock` relationship.
  - [ ] Subtask 3.2: Reference the existing "Plugin-language overrides" section (Story 13.5) as the override surface.

- [ ] **Task 4: Mirror to devrail.dev** (AC: 4)
  - [ ] Subtask 4.1: Mirror the contributing-a-plugin section into the appropriate devrail.dev page (likely `content/docs/contributing/` or a new `content/docs/plugins/`).
  - [ ] Subtask 4.2: Mirror the `plugins:` schema section into devrail.dev (creating a `devrail-yml-schema` page if needed).

- [ ] **Task 5: Blog post** (AC: 5)
  - [ ] Subtask 5.1: Write `devrail.dev/content/blog/2026-05-05-plugin-architecture.md` announcing the feature.
  - [ ] Subtask 5.2: Cross-link to the design doc, contributing doc, and schema doc.

- [ ] **Task 6: Release** (AC: 1, 6)
  - [ ] Subtask 6.1: Update `dev-toolchain/CHANGELOG.md` `[Unreleased]` to frame v1.10.6 as the marketing-ready release.
  - [ ] Subtask 6.2: `make release VERSION=1.10.6`.
  - [ ] Subtask 6.3: Verify the release workflow advances the `:v1` floating tag.

- [ ] **Task 7: Sprint close** (AC: process)
  - [ ] Subtask 7.1: Story status → `done`; sprint-status `13-6 → done`.

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

(to be filled during implementation)

### Completion Notes List

(to be filled during implementation)

### File List

(to be filled during implementation)

### Change Log

| Date | Change |
|---|---|
| 2026-05-05 | Story file created + dev started in single pass per user request `cut 13.6` (status: in-progress) |
