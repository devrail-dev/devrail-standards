# Story 13.3: Implement Plugin Resolver and Lockfile

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **dev-toolchain maintainer**,
I want a `make plugins-update` target that resolves every plugin's `rev:` to an immutable SHA, fetches the plugin repo to a deterministic content-addressed cache path, and records the resolved SHA + content hash in `.devrail.lock` — and `make check` that refuses to run when `.devrail.yml` and `.devrail.lock` disagree,
so that plugin builds are reproducible across machines and CI, and tag tampering (rebase a tag onto different code) is detected before any plugin code executes.

## Acceptance Criteria

1. **Given** `.devrail.yml` declares plugins with `rev:` (tag or SHA)
   **When** `make plugins-update` runs
   **Then** every entry's `rev:` is resolved against the source URL via `git ls-remote`
   **And** SHA refs are used directly; tag refs are resolved to the SHA they currently point at
   **And** branch refs are rejected with a clear error event ("branch refs are not allowed; use a tag or SHA")

2. **Given** a successful resolution
   **When** `make plugins-update` finishes
   **Then** `.devrail.lock` (YAML, sibling of `.devrail.yml`) is written with one entry per plugin containing: `source`, `rev` (as declared), `sha` (resolved), `schema_version` (read from manifest), `content_hash` (sha256 of the cloned tree)
   **And** the lockfile is sorted deterministically by `source` (stable across re-runs)
   **And** the lockfile starts with a top-level `schema_version: 1` so future format changes can be detected

3. **Given** a plugin source needs fetching
   **When** the resolver clones it
   **Then** the clone lands at `${DEVRAIL_PLUGINS_DIR:-/opt/devrail/plugins}/<source-slug>/<rev>/` (matching the path the loader from Story 13.2 reads)
   **And** the `<sha>` directory contains the manifest at `<sha-dir>/plugin.devrail.yml` AND the rest of the plugin repo (install scripts, scaffolds)
   **And** re-running against the same SHA is a no-op (idempotent — checked-out tree exists, content_hash unchanged)
   **And** parallel `make plugins-update` invocations don't corrupt the cache (atomic-rename or lock file)

4. **Given** `.devrail.yml` declares a plugin and `.devrail.lock` exists
   **When** `make _plugins-load` runs (the Story 13.2 loader)
   **Then** the resolver's `_plugins-verify` prerequisite checks every declared plugin has a matching `.devrail.lock` entry whose `rev:` matches `.devrail.yml`'s `rev:`
   **And** if any entry is missing or mismatched, it emits a structured error event and exits 2 with a clear message ("run `make plugins-update`")
   **And** if the on-disk cached tree's content_hash doesn't match the lockfile's `content_hash`, it exits 2 with a tampering-detected error

5. **Given** `.devrail.lock` does NOT exist but `.devrail.yml` declares plugins
   **When** `make check` runs
   **Then** the loader exits 2 with `run \`make plugins-update\` to generate .devrail.lock`
   **And** when `.devrail.yml` declares NO plugins (or `plugins: []`), absence of `.devrail.lock` is fine (no regression for v1.9.x consumers)

6. **Given** a plugin source URL is unreachable (network failure, 404, auth required)
   **When** `make plugins-update` runs
   **Then** the resolver emits a structured error event identifying the source and the underlying git error
   **And** exits 2 (configuration error) — distinguishable from manifest-validation failures
   **And** the lockfile is NOT partially written (atomic — either the whole resolution succeeds or no lockfile change)

7. **Given** a passing test suite
   **When** `bash tests/test-plugin-resolver.sh` runs
   **Then** it covers: SHA passthrough, tag-to-SHA resolution, branch-ref rejection, lockfile generation + determinism, idempotent re-fetch, lockfile-disagreement detection, content-hash mismatch (tampering), missing-lockfile error, and unreachable-source error
   **And** all cases produce the expected exit code and JSON event signatures
   **And** tests use a local-filesystem git fixture (no network dependency) — `git init && git commit && git tag` over a fixture tree

## Tasks / Subtasks

- [x] **Task 1: Resolver script** (AC: 1, 6)
  - [x] 1.1 Create `scripts/plugin-resolver.sh`. Sources `lib/log.sh` and `lib/version.sh`. Header in standard format.
  - [x] 1.2 Implement `resolve_ref <source-url> <rev>` — emits the resolved SHA on stdout, returns non-zero on error.
    - SHA passthrough: if `rev` matches `^[a-f0-9]{40}$` (full SHA), echo it back verbatim and verify the source URL has it via `git ls-remote --exit-code <url> <sha>`. If `git ls-remote` doesn't expose unfetched SHAs (most servers don't), fall through to a shallow clone + `git rev-parse <sha>`.
    - Tag resolution: `git ls-remote --tags <url> <rev>` → parse the SHA from the output. Reject if multiple matches (annotated tag's `<rev>^{}` peeled form should be preferred).
    - Branch rejection: if `git ls-remote --heads <url>` returns a match for `<rev>`, emit a structured error with `field: rev`, `reason: "branch refs are not allowed; use a tag or SHA"`, and return non-zero. Branch refs are detected even when they share a name with a tag (rare; reject if either matches a branch).
  - [x] 1.3 Implement `fetch_to_cache <source-url> <sha> <plugins-dir>` — clones the source at `<sha>` into `<plugins-dir>/<basename>/<sha>/`. Use shallow clone (`--depth 1`) when fetching by SHA via `git fetch <url> <sha>`. Idempotent — if the directory exists and contains `.git/HEAD` matching the SHA, skip.
  - [x] 1.4 Implement `compute_content_hash <dir>` — `find <dir> -type f -not -path '*/.git/*' -print0 | sort -z | xargs -0 sha256sum | sha256sum | cut -d' ' -f1`. Stable across machines (sort and exclude `.git/`).
  - [x] 1.5 Implement `resolve_all <devrail-yml> <plugins-dir>` — orchestrates: read `.devrail.yml` `plugins:`, for each entry call resolve+fetch+hash, return a YAML structure on stdout that can be redirected to `.devrail.lock`.
  - [x] 1.6 Atomic lockfile write — write to `.devrail.lock.tmp`, then `mv` into place at the end. Don't leave a partial lockfile on resolver failure (AC 6).
  - [x] 1.7 Honour `${DEVRAIL_PLUGINS_DIR:-/opt/devrail/plugins}` env override for testability.

- [x] **Task 2: Lockfile verification script** (AC: 4, 5)
  - [x] 2.1 Create `scripts/plugin-lockfile-verify.sh`. Compares `.devrail.yml` against `.devrail.lock`.
  - [x] 2.2 For each plugin in `.devrail.yml`: locate matching `.devrail.lock` entry by `source`. Compare `rev` (must match what's declared). Emit structured error per mismatch, exit 2.
  - [x] 2.3 If a plugin entry exists in `.devrail.yml` with no matching lock entry (or vice versa), emit error and exit 2.
  - [x] 2.4 For each lock entry: read the cached manifest at `<plugins_dir>/<slug>/<rev>/`, compute content_hash, compare to recorded `content_hash`. On mismatch, emit a tampering-detected error and exit 2.
  - [x] 2.5 If `.devrail.yml` declares no plugins (or `plugins: []`), the script is a no-op (exit 0) — preserves v1.9.x behaviour even when `.devrail.lock` happens to exist (lock entries for absent plugins are an info event, not an error).

- [x] **Task 3: Public `plugins-update` Make target** (AC: 1, 2, 3, 6)
  - [x] 3.1 Add `plugins-update` public target to Makefile that runs `$(DOCKER_RUN) make _plugins-update`.
  - [x] 3.2 Add `_plugins-update` internal target that invokes `bash /opt/devrail/scripts/plugin-resolver.sh`. Reads `.devrail.yml`, writes `.devrail.lock`. Exits 0 on success, 2 on resolution/fetch failure.
  - [x] 3.3 Update help text in `make help` so `plugins-update` shows up.
  - [x] 3.4 If `.devrail.yml` declares no plugins, emit info event and exit 0 (no lockfile generated, none needed).

- [x] **Task 4: Wire `_plugins-verify` into the loader prerequisite chain** (AC: 4, 5)
  - [x] 4.1 Add `_plugins-verify` internal target that invokes `plugin-lockfile-verify.sh`. Exits 2 on any disagreement.
  - [x] 4.2 Story 13.2's `_plugins-load` is currently `_plugins-load: _check-config`. Update to `_plugins-load: _plugins-verify` so verification runs first. (`_plugins-verify: _check-config` to preserve the chain.)
  - [x] 4.3 If `.devrail.yml` has no `plugins:` section or `plugins: []`, `_plugins-verify` is a no-op (exit 0) — guarantees no regression for v1.9.x consumers who never declared plugins.
  - [x] 4.4 If `.devrail.yml` has plugins but `.devrail.lock` is absent, emit a clear error event ("run `make plugins-update` to generate .devrail.lock") and exit 2.

- [x] **Task 5: Test fixtures** (AC: 7)
  - [x] 5.1 Create `tests/fixtures/plugin-repos/elixir-v1/` — a fully self-contained mini git repo (just files; the test will `git init` it). Contains: `plugin.devrail.yml` (valid v1 manifest), `install.sh`, `README.md`, an arbitrary file or two so content_hash is non-trivial.
  - [x] 5.2 Don't check in `.git/` — the test harness will run `git init`, `git add`, `git commit`, `git tag v1.0.0` over the fixture tree to produce a local-filesystem git source. This avoids network dependency.
  - [x] 5.3 Create a second fixture `tests/fixtures/plugin-repos/elixir-v1-tampered/` — same files but with a modified `plugin.devrail.yml` (different `description`) so the content_hash differs while the rev (tag name) is identical. The test will swap this in to simulate tag-rebase tampering.

- [x] **Task 6: Smoke test** (AC: 7)
  - [x] 6.1 Create `tests/test-plugin-resolver.sh`. Pattern mirrors `tests/test-plugin-loader.sh`.
  - [x] 6.2 **SHA passthrough**: declare a plugin with `rev: <40-char-sha>`. Lock entry's `sha` = declared rev verbatim.
  - [x] 6.3 **Tag → SHA resolution**: declare `rev: v1.0.0` against the local fixture git repo. Lock entry's `sha` matches `git rev-parse v1.0.0` from the fixture.
  - [x] 6.4 **Branch rejection**: declare `rev: main`. Resolver exits 2 with a `branch refs are not allowed` error event.
  - [x] 6.5 **Lockfile determinism**: run `make plugins-update` twice; lockfile content_hash and ordering identical.
  - [x] 6.6 **Idempotent fetch**: second `plugins-update` doesn't re-clone (verified by `mtime` of cached `<sha>/.git` directory unchanged).
  - [x] 6.7 **Lockfile mismatch**: edit `.devrail.lock` to flip a `rev`. `make _plugins-verify` exits 2 with a `lockfile mismatch` error event referring to the offending plugin.
  - [x] 6.8 **Tampering detection**: replace cached tree with `elixir-v1-tampered/` content (without updating lockfile). `_plugins-verify` exits 2 with a `content_hash mismatch` event.
  - [x] 6.9 **Missing lockfile**: declare a plugin, delete `.devrail.lock`. `_plugins-verify` exits 2 with `run make plugins-update`.
  - [x] 6.10 **No regression for plugin-less consumers**: `.devrail.yml` with no `plugins:` section → `_plugins-verify` exits 0 silently even with no `.devrail.lock`.
  - [x] 6.11 **Unreachable source**: declare a plugin with `source: file:///nonexistent/path`. Resolver exits 2; `.devrail.lock` is unchanged (atomic, not partially written).

- [x] **Task 7: Wire smoke test into CI**
  - [x] 7.1 Add a step to `.github/workflows/ci.yml` after the `Plugin loader smoke test` step: `bash tests/test-plugin-resolver.sh`.

- [x] **Task 8: Documentation**
  - [x] 8.1 CHANGELOG.md `[Unreleased]` → `### Added`: line announcing `make plugins-update` and `.devrail.lock`.
  - [x] 8.2 Update STABILITY.md "Plugin loader prelude" row to extend to "Plugin loader + resolver + lockfile" (still Preview status).
  - [x] 8.3 No changes yet to `standards/devrail-yml-schema.md` — Story 13.6 bundles all schema/standards-doc updates per the migration plan. Do NOT preemptively edit the schema doc.

## Dev Notes

### Authoritative source

The resolver/lockfile contract is defined in `_bmad-output/planning-artifacts/plugin-architecture-design.md` — read **§"Lockfile"** (line 432+), **§"Plugin Lifecycle"** steps 1-3 (line 269+), and **§"Project Configuration"** (line 239+) before starting Task 1. If the design and this story disagree, the design wins.

### Scope boundary (read carefully)

This story implements **resolver + lockfile + verifier**. Out of scope:

- **The build pipeline (Dockerfile.devrail generation)** — Story 13.4
- **The execution loop (running plugin commands)** — Story 13.5
- **The release work** — Story 13.6
- **Cosign signature verification** — Story 13.10 (open question follow-up)

The resolver populates the path the loader (Story 13.2) reads. The loader-fix branch `fix/13-2-review-followups` (in flight at the time of this story's authoring) made the loader rev-aware (`<plugins-dir>/<slug>/<rev>/plugin.devrail.yml`); this story's resolver MUST land manifests at exactly that path, including the `<rev>` segment. (If the fix branch hasn't merged yet, rebase this story onto post-fix `main`.)

### Architectural constraints

- **Immutable refs only** — design `§"Resolution rules"` line 262. Branch refs are rejected with a clear error.
- **Source addresses are git URLs (v1)** — `host/namespace/name` triples but practically just the URL. No registry layer.
- **Lockfile format** — design `§"Lockfile"` shows the canonical shape:
  ```yaml
  schema_version: 1
  plugins:
    - source: github.com/community/devrail-plugin-elixir
      rev: v1.0.0
      sha: 7f3a2b8e5c1d9a6b2e4f8a1c0d3b5e7a9c2f4d6b
      schema_version: 1
      content_hash: sha256:abcd...
  ```
- **`make plugins-update` is a public target** (consumer runs it explicitly, like `bundle update` or `cargo update`); `_plugins-verify` is internal (auto-runs as a `_plugins-load` prereq).
- **`.devrail.lock` is checked into VCS** by consumers — like `Gemfile.lock`, `Cargo.lock`, `package-lock.json`. Document this in CHANGELOG.

### Why `git ls-remote` not `git fetch` for resolution

For tag → SHA resolution, `git ls-remote --tags <url> <tag>` is one round-trip and doesn't write anything to disk. Only fetch (Task 1.3) when we actually need the tree. Keeps `make plugins-update` fast on a no-op rerun where everything's already cached.

### Content hash strategy

Per design `§"Lockfile"`: `content_hash: sha256:<hex>`. The hash must be:
- **Reproducible across machines** — same tree → same hash, regardless of clock/uid/git config
- **Sensitive to tampering** — any file edit changes the hash
- **Independent of `.git/`** — git's own metadata (refs, config, packed-refs) varies between clones of the same SHA

Implementation: `find <dir> -type f -not -path '*/.git/*' -print0 | sort -z | xargs -0 sha256sum | sha256sum | cut -d' ' -f1`. Sort is locale-invariant via `LC_ALL=C` (set at script top).

### Why two scripts not one

`plugin-resolver.sh` does the heavy work (`make plugins-update`); `plugin-lockfile-verify.sh` is fast (`make check` runs it on every invocation). Keeping verify-only in a separate script means the hot path doesn't pay the cost of the resolver's clone-and-hash machinery.

### File touchpoints

| Path | Change |
|---|---|
| `dev-toolchain/scripts/plugin-resolver.sh` | New — resolves refs, fetches, computes content hash, writes `.devrail.lock` atomically. |
| `dev-toolchain/scripts/plugin-lockfile-verify.sh` | New — fast verification used by `_plugins-verify` prereq. |
| `dev-toolchain/Makefile` | New `plugins-update` (public) + `_plugins-update` + `_plugins-verify` targets. Update `_plugins-load` prereq from `_check-config` to `_plugins-verify`. |
| `dev-toolchain/tests/test-plugin-resolver.sh` | New — 11-check smoke test. |
| `dev-toolchain/tests/fixtures/plugin-repos/elixir-v1/` | New fixture tree (files only, no `.git/`). |
| `dev-toolchain/tests/fixtures/plugin-repos/elixir-v1-tampered/` | New fixture tree for tampering test. |
| `dev-toolchain/.github/workflows/ci.yml` | New step invoking `tests/test-plugin-resolver.sh`. |
| `dev-toolchain/CHANGELOG.md` | `[Unreleased]` → `Added` entry. |
| `dev-toolchain/STABILITY.md` | Update plugin-loader row. |

### Existing patterns to reuse (don't reinvent)

- **Structured logging** — `lib/log.sh`'s new `log_event` (added in the Story 13.2 review-fix branch). All resolver events go through it. Use `language=_plugins` consistently with Story 13.2.
- **Exit code convention** — 0 pass, 1 tool failure, 2 misconfig. Resolver/verifier failures are misconfig (2).
- **Test pattern** — `tests/test-plugin-loader.sh` is the reference. Same `mktemp -d` + docker-cleanup-trap + `assert_eq`/`assert_jq` helpers. Lift verbatim.
- **Fixture pattern** — `tests/fixtures/plugins/<slug>/v1.0.0/plugin.devrail.yml` already exists. Plugin-repo fixtures (this story) live in a parallel `tests/fixtures/plugin-repos/<slug>/` tree with no `.git/` (the test harness initialises git).

### Consumer DX considerations

- Lockfile diffs in PRs should be readable. YAML keys sorted deterministically (`source` first, then alphabetically within the entry).
- Error messages must tell consumers what to do: `"run \`make plugins-update\`"`, `"branch refs are not allowed; pin a tag or SHA"`, etc. The Story 13.2 review found that bare error messages without remediation hints are easy to ship; don't repeat that mistake.

### Anti-patterns (do NOT do)

- **Don't use `curl` to fetch tarballs.** git is the protocol. `git fetch` + `git ls-remote` only.
- **Don't shell out to `gh`/`glab` for source URLs.** Plain git URLs (`https://...`, `git@...`, `file://...`) so private GitLabs and on-prem sources work without auth-tool dependencies.
- **Don't add a `--no-verify` mode for the lockfile check.** Disagreement is always an error. If you find yourself wanting to bypass it, the lockfile is wrong; rerun `plugins-update`.
- **Don't auto-run `plugins-update` from `make check`.** Consumers must opt in; surprising network calls violate the deterministic-build expectation. Same as `bundler` / `cargo`.
- **Don't add per-plugin parallel resolution in v1.** Sequential is correct (small N, one-shot operation, predictable error reporting). Parallelism is a future optimization.

## Previous Story Intelligence — Story 13.2

Story 13.2 shipped the parser + loader (PR #31, merged into v1.10.0). Senior-developer review followed (`fix/13-2-review-followups` branch, in flight as of this story's authoring) with these decisions that constrain Story 13.3:

- **Manifest cache path is rev-aware.** Loader looks at `<plugins-dir>/<slug>/<rev>/plugin.devrail.yml`. Resolver MUST land manifests at this exact path, including the `<rev>` segment.
- **Cache file `/tmp/devrail-plugins-loaded.yaml` contains the FULL manifest content** (review fix H1). Story 13.5 will consume that cache directly. The lockfile is a separate artifact for reproducibility — don't conflate the two. The loader writes the cache; the resolver writes the lockfile.
- **`log_event` helper exists in `lib/log.sh`** (review fix M2). Use it for all resolver events. Pattern: `log_event error "lockfile mismatch" plugin=elixir source=... reason=...`. Numeric values use `:=` syntax: `log_event info "fetched" bytes:=12345`.
- **Plugin entries require both `source:` and `rev:`** (review fix added explicit `rev` check to loader). Same constraint applies in resolver — fail fast if either is missing.
- **`gates:` is now validated by the parser** (review fix M1) — resolver doesn't need to re-validate, but be aware the parsed-cache shape is well-formed if the loader has run.

## Git Intelligence — Recent dev-toolchain Patterns

Recent commits relevant to plumbing this story:

```
2323544 chore(release): prepare v1.10.0
03e97a5 feat(makefile): plugin manifest parser and loader prelude (Story 13.2) (#31)
03ef4a4 fix(makefile): rails make check honours .bundle/config + bundle exec + db:test:prepare (#30) (#32)
1ba9295 chore(release): prepare v1.9.1
c588028 fix(container): install libyaml-dev so bundle install can compile psych (#28) (#29)
```

Patterns to follow:

- **Atomic file writes** — Story 13.0 (`devrail-init`) uses temp-then-rename for safety. Same pattern here for `.devrail.lock`.
- **Test exit-code capture** — the Story 13.2 implementation hit a bug where `out=$(... || true); exit_code=$?` always returned 0. Use `out=$(...) && exit_code=0 || exit_code=$?`. Already documented in `tests/test-plugin-loader.sh`.
- **`yq` !!null handling** — Story 13.2 hit a snag where `yq -r '.field | type'` returns `!!null` (not bare `null`) for absent keys. The `yq_type` helper in `plugin-validator.sh` handles this; reuse the pattern (or extract to a shared `lib/yq-helpers.sh` if needed).

Patterns to avoid:

- **Don't bypass `lib/log.sh`** — Story 13.2's review found hand-crafted JSON in the validator, fixed by adding `log_event` to log.sh. Don't repeat the bypass; use `log_event` from day one.
- **Don't hardcode `/opt/devrail/plugins`** — Story 13.2 was patched to honour `${DEVRAIL_PLUGINS_DIR:-/opt/devrail/plugins}` for testability. Resolver must do the same (`DEVRAIL_PLUGINS_DIR` env override).

## Latest Tech Information

No external tech research required. All tools are in v1.10.0:

- **`git` 2.x** — bookworm slim's stock git. `ls-remote`, `fetch --depth 1`, `rev-parse`, `tag` all available.
- **`yq` v4.44.1** — `load(...)` for embedding manifest content in YAML output, `eval-all` for stream processing, `-i` for in-place edits.
- **`sha256sum`** — coreutils. Available unconditionally.
- **`find` + `xargs -0` + `sort -z`** — null-delimited piping; locale-stable when `LC_ALL=C` is set.

## Project Context Reference

- Project root: `~/Work/gitlab.mfsoho.linkridge.net/OrgDocs/development-standards`
- Implementation repo: `~/Work/github.com/devrail-dev/dev-toolchain`
- Plugin design: `_bmad-output/planning-artifacts/plugin-architecture-design.md`
- Predecessor story: `_bmad-output/implementation-artifacts/13-2-implement-plugin-manifest-parser-and-loader.md`
- CLAUDE.md critical rules apply (especially #1 `make check` before completion, #6 use shared logging library, #7 never suppress failing checks).

## References

- [Source: `_bmad-output/planning-artifacts/plugin-architecture-design.md#Lockfile`] — lockfile schema (line 432)
- [Source: `_bmad-output/planning-artifacts/plugin-architecture-design.md#Plugin Lifecycle`] — resolver's place in the lifecycle (steps 2-3, line 269+)
- [Source: `_bmad-output/planning-artifacts/plugin-architecture-design.md#Project Configuration`] — `.devrail.yml` `plugins:` schema (line 239)
- [Source: `_bmad-output/planning-artifacts/plugin-architecture-design.md#Distribution & Versioning`] — three version axes (line 415+)
- [Source: `_bmad-output/planning-artifacts/plugin-architecture-design.md#Security Model`] — immutable-refs rationale (line 456+)
- [Source: `_bmad-output/planning-artifacts/epics.md#Story 13.3`] — story-level AC
- [Source: `_bmad-output/implementation-artifacts/13-2-implement-plugin-manifest-parser-and-loader.md`] — predecessor; loader contract
- [Source: `dev-toolchain/Makefile`] — `_plugins-load` recipe to extend with `_plugins-verify`
- [Source: `dev-toolchain/lib/log.sh`] — `log_event` helper (added in Story 13.2 review-fix)
- [Source: `dev-toolchain/tests/test-plugin-loader.sh`] — test pattern reference

## Dev Agent Record

### Agent Model Used

Claude Opus 4.7 (1M context) — single-session execution via `/bmad-bmm-dev-story` workflow.

### Debug Log References

- **First smoke-test run failed at Case 1**: `git ls-remote` couldn't reach `file://` URLs because git 2.38+ defaults `protocol.file.allow=user`, blocking the file protocol from non-interactive contexts (CVE-2022-39253 mitigation). Fixed by passing `-c protocol.file.allow=always` to all git invocations in the resolver (`ls-remote`, `remote add`, `fetch`). Production plugins use `https://`/`ssh://` and aren't affected; the override only matters for the local-fixture test harness.
- **Second smoke-test run failed at Case 1 again**: the test embedded a host-side `file://$WORKDIR/elixir-repo` URL in `.devrail.yml`, but the docker container couldn't see that host path. Fixed by mounting `$WORKDIR` at the same path inside the container (`-v "$WORKDIR:$WORKDIR"`) so `file://` URLs resolve identically inside and outside.
- **Plugin loader integration tests broke** after wiring `_plugins-verify` as a `_plugins-load` prereq — the existing fixtures didn't have `.devrail.lock` so verify failed first. Fixed by adding a `write_matching_lockfile` helper to `tests/test-plugin-loader.sh` that computes content_hash inside the container and writes a matching lockfile per integration case.
- **`make _check` self-check broke**: shellcheck flagged unused `write_lockfile_entry` function (replaced inline) and unused `GIT_URL_TAMPERED` variable (the tampering test uses a different mechanism). Removed both. Also `shfmt -w` reformatted the new scripts to the repo's 2-space-indent + brace-block style; running it as root inside the container left the files root-owned and the next pre-commit hook failed with `PermissionError`. Fixed by `sudo chown` after running shfmt.
- Two container rebuilds were needed: one full (`COPY scripts/` invalidates downstream layers) and one cached (just for the resolver script edit).

### Completion Notes List

- Ultimate context engine analysis completed — comprehensive developer guide created. Story 13.3 is the v1.10.x resolver + lockfile, depends on Story 13.2's loader contract (rev-aware paths, full-manifest cache, log_event helper). Scope explicitly bounded against 13.4 (build pipeline) and 13.5 (execution loop).

**Implementation summary (2026-05-03):**

- All 7 acceptance criteria satisfied. All 8 tasks / 30+ subtasks marked complete.
- Resolver (`scripts/plugin-resolver.sh`, ~230 lines) handles SHA passthrough, tag-to-SHA via `git ls-remote --tags` (peeled annotated form preferred), branch ref rejection via `git ls-remote --heads`, and atomic lockfile write via temp+rename.
- Verifier (`scripts/plugin-lockfile-verify.sh`, ~140 lines) runs as a `_plugins-load` prereq on every `make check`. No-op when no plugins declared (regression-safe for v1.9.x and v1.10.x consumers without `plugins:`).
- Cache path uses rev-aware structure `<plugins-dir>/<slug>/<rev>/` matching what Story 13.2's loader reads (post-review-fix).
- Content_hash strategy: `find . -type f -not -path './.git/*' -not -name '.devrail.sha' -print0 | sort -z | xargs -0 sha256sum | sha256sum`. Stable across machines via `LC_ALL=C`. Excludes `.git/` (varies between clones) and `.devrail.sha` (resolver's own sentinel).
- Lockfile entries sorted alphabetically by `source` for deterministic diffs in PRs.
- Used new `lib/log.sh::log_event` helper added in PR #33 (Story 13.2 review fix M2). Numeric values use `:=` syntax: `log_event info "fetched" plugin_count:=3`.
- 11-case smoke test in `tests/test-plugin-resolver.sh` uses local-filesystem git fixtures (no network). Harness builds two git repos in-place (one valid, one tampered) via docker-init-add-commit-tag dance. Tampering test swaps cached tree contents without updating lockfile to verify content_hash detection.
- Updated existing `tests/test-plugin-loader.sh` to write a matching `.devrail.lock` for integration cases via a new `write_matching_lockfile` helper. Missing-rev integration case now expected to fail at `_plugins-verify` rather than at the loader (the verifier checks for source/rev presence).

**Verification (all green locally against the freshly built image):**

- `tests/test-plugin-resolver.sh` — 11/11
- `tests/test-plugin-loader.sh` — 11/11 (regression-safe with new prereq)
- `tests/smoke-rails.sh` — 4/4 (regression-safe)
- `make _check` on dev-toolchain itself — pass

**Implementation PR:** https://github.com/devrail-dev/dev-toolchain/pull/34

### File List

**Implementation (dev-toolchain repo, branch `feat/13-3-plugin-resolver`, PR #34):**

- `scripts/plugin-resolver.sh` — new
- `scripts/plugin-lockfile-verify.sh` — new
- `Makefile` — modified (added `plugins-update` public target + `_plugins-update` and `_plugins-verify` internal targets; updated `_plugins-load` prereq from `_check-config` to `_plugins-verify`)
- `tests/fixtures/plugin-repos/elixir-v1/{plugin.devrail.yml,install.sh,README.md}` — new
- `tests/fixtures/plugin-repos/elixir-v1-tampered/{plugin.devrail.yml,install.sh,README.md}` — new
- `tests/test-plugin-resolver.sh` — new (11-case smoke)
- `tests/test-plugin-loader.sh` — modified (added `write_matching_lockfile` helper; integration cases now satisfy `_plugins-verify`; missing-rev case adjusted)
- `.github/workflows/ci.yml` — modified (added "Plugin resolver smoke test" step)
- `STABILITY.md` — modified ("Plugin loader prelude" row extended to "Plugin loader + resolver + lockfile")
- `CHANGELOG.md` — modified (added `[Unreleased] → Added` entry)

**Story tracking (OrgDocs repo, branch `feat/13-3-implement-plugin-resolver-and-lockfile`):**

- `_bmad-output/implementation-artifacts/13-3-implement-plugin-resolver-and-lockfile.md` — modified (status, all 30+ task checkboxes, Dev Agent Record, File List)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — modified (`13-3`: `ready-for-dev` → `in-progress` → `review`)

### Change Log

| Date | Change |
|---|---|
| 2026-05-01 | Story created via `/bmad-bmm-create-story` (status: ready-for-dev) |
| 2026-05-03 | Implementation completed via `/bmad-bmm-dev-story`; status moved to `review`; PR #34 opened on dev-toolchain |
| 2026-05-03 | Senior-developer review completed via `/bmad-bmm-code-review`; 12 findings (1 HIGH, 5 MED, 6 LOW); all addressed via PR #35 (`fix/13-3-review-followups`); status moved to `done` |

## Senior Developer Review (AI)

**Reviewer:** Matthew (review executed by Opus 4.7 — same model that implemented the story; see caveat)
**Date:** 2026-05-03
**Outcome:** Approve (after follow-up fix PR #35)

### Caveat

Same model that wrote the implementation also performed the review. Findings skew toward checklist-sweep rather than independent insight. A future review under a different model is welcome and may surface additional issues.

### Findings

**HIGH severity (must fix — done in PR #35):**

- [x] **H1** — Malformed `.devrail.yml` silently treated as "no plugins declared". `yq ... \|\| echo 0` swallowed parse errors, exit 0 with "no plugins" message. Fixed by both resolver and verifier wrapping yq via a `parse_plugin_count` helper that distinguishes "parse failure" (exit 2 with structured error) from "no plugins entry".

**MEDIUM severity (should fix — done in PR #35):**

- [x] **M1** — Verifier interpolated source URL into yq expression unquoted; malformed/malicious source values could break the query. Fixed by passing via `strenv()` instead.
- [x] **M2** — Slug collisions (two sources with same `basename`) silently overwrote each other's caches. Fixed by tracking `SLUG_TO_SOURCE` during the resolve loop and emitting `plugin slug collision` error on second occurrence.
- [x] **M3** — `fetch_to_cache` had a race window between `rm -rf target` and `mv fetch_dir target`; concurrent `make check` could see absent path. Fixed via atomic swap (move existing aside, install new, remove old) with rollback.
- [x] **M4** — `compute_content_hash` duplicated between resolver and verifier; future drift risk. Extracted to new `lib/plugin-cache.sh` along with `derive_slug` helper.
- [x] **M5** — Resolver didn't validate fetched manifest, leading to "make plugins-update succeeds, every make check fails". Fixed by invoking `plugin-validator.sh` on the fetched manifest before recording content_hash.

**LOW severity (nice to fix — done in PR #35):**

- [x] **L1** — `fetch_to_cache` comment said 3 args, takes 4. Comment updated.
- [x] **L2** — `.git`-suffixed URLs yielded ugly slugs. `derive_slug` now strips the suffix.
- [x] **L3** — Source URLs with colons could break YAML parsing if format evolved. Lockfile entries now double-quoted via `yaml_quote` helper.
- [x] **L4** — No test for `_plugins-update` no-op with no plugins. Added Case 15.
- [x] **L5** — Idempotent-fetch test asserted event presence, not absence of re-clone. Added Case 16 that checks `.devrail.sha` mtime stability.
- [x] **L6** — No test for `.git`-suffixed source URL. Added Case 14.

### Action Items

All 12 action items resolved in PR #35 (`fix/13-3-review-followups`).

- [x] [AI-Review][HIGH] H1: distinguish yq parse failure from no-plugins [scripts/plugin-resolver.sh, plugin-lockfile-verify.sh → fixed]
- [x] [AI-Review][MED] M1: yq query injection in verifier [scripts/plugin-lockfile-verify.sh → fixed via strenv]
- [x] [AI-Review][MED] M2: slug collision detection [scripts/plugin-resolver.sh → fixed]
- [x] [AI-Review][MED] M3: atomic cache swap [scripts/plugin-resolver.sh → fixed]
- [x] [AI-Review][MED] M4: extract compute_content_hash to lib [lib/plugin-cache.sh → fixed]
- [x] [AI-Review][MED] M5: validate manifest in resolver [scripts/plugin-resolver.sh → fixed]
- [x] [AI-Review][LOW] L1: fetch_to_cache comment arity [scripts/plugin-resolver.sh → fixed]
- [x] [AI-Review][LOW] L2: strip .git suffix in derive_slug [lib/plugin-cache.sh → fixed]
- [x] [AI-Review][LOW] L3: quote lockfile values [scripts/plugin-resolver.sh → fixed]
- [x] [AI-Review][LOW] L4: test _plugins-update no-op [tests/test-plugin-resolver.sh → fixed]
- [x] [AI-Review][LOW] L5: assert mtime stability [tests/test-plugin-resolver.sh → fixed]
- [x] [AI-Review][LOW] L6: test .git-suffixed URL [tests/test-plugin-resolver.sh → fixed]
