# Story 13.4: Implement Extended-Image Build Pipeline

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **dev-toolchain maintainer**,
I want `make check` to auto-generate a `Dockerfile.devrail` that layers each declared plugin's container fragment (`apt_packages`, `copy_from_builder`, `install_script`, `env`) onto the core image, build the resulting image via BuildKit, and use it for every subsequent in-container target,
so that plugin tools are available alongside core tools in a single container without sacrificing the "one container, one `make check`" guarantee or breaking reproducibility.

## Acceptance Criteria

1. **Given** a project with one or more plugins declared in `.devrail.yml`
   **When** `make check` runs
   **Then** a `Dockerfile.devrail` is generated in the workspace from the cached plugin manifests' `container:` blocks (`base_image`, `apt_packages`, `copy_from_builder`, `install_script`, `env`)
   **And** the file is auto-generated (header comment "auto-generated; do not edit by hand")
   **And** the file's contents are deterministic — re-running with an unchanged plugin set produces a byte-identical Dockerfile.devrail

2. **Given** a generated `Dockerfile.devrail`
   **When** the build pipeline runs
   **Then** the image is built via `docker build` (BuildKit) and tagged `devrail-local:<hash>` where `<hash>` is the SHA256 of the generated Dockerfile contents (first 16 hex chars)
   **And** the build output is wrapped: progress lines suppressed, only the final result emitted as a structured `info` event (`{"level":"info","msg":"extended image built","tag":"devrail-local:<hash>","duration_ms":N,"language":"_plugins"}`)
   **And** on build failure the JSON event level is `error` with the failing plugin slug + the captured stderr tail

3. **Given** an unchanged plugin set on a subsequent invocation
   **When** the build pipeline runs
   **Then** the existing `devrail-local:<hash>` tag is detected (`docker image inspect`) and reused without invoking `docker build`
   **And** an `info` event records "extended image cache hit"
   **And** total wall time of the pipeline is < 1 second on the cache-hit path

4. **Given** an extended image was successfully built
   **When** subsequent public targets (`check`, `lint`, `format`, `fix`, `test`, `security`) run
   **Then** `DOCKER_RUN` invokes the project-local `devrail-local:<hash>` image instead of `ghcr.io/devrail-dev/dev-toolchain:v1`
   **And** the loader, verifier, validator, and execution loop all run inside that extended image

5. **Given** `.devrail.yml` declares no `plugins:` section (the v1.10.x baseline)
   **When** `make check` runs
   **Then** no `Dockerfile.devrail` is generated, no extended image is built
   **And** `DOCKER_RUN` continues to use `ghcr.io/devrail-dev/dev-toolchain:v1` (regression-safe for v1.9.x and v1.10.x consumers)

6. **Given** the host-side plugin cache must persist across container invocations
   **When** any plugin-using target runs
   **Then** `${HOME}/.cache/devrail/plugins` (or `${DEVRAIL_HOST_PLUGINS_CACHE}` override) is bind-mounted at `/opt/devrail/plugins` in the container
   **And** the directory is created on the host if it doesn't exist (mode 0755, owned by the host user)
   **And** plugin manifests fetched by `make plugins-update` survive container exit and are visible to subsequent `make check` invocations without re-fetching

7. **Given** a plugin's `container:` block declares an `install_script`
   **When** the extended image is built
   **Then** the install script runs as the final RUN layer (after apt packages, COPY blocks, ENV)
   **And** the script is sourced from the cached plugin tree (`/opt/devrail/plugins/<slug>/<rev>/<install_script>`) — copied into the image at a known path so subsequent runs don't depend on the host cache being mounted

8. **Given** a passing test suite
   **When** `bash tests/test-plugin-build-pipeline.sh` runs
   **Then** it covers: dockerfile generation determinism, build cache hit/miss, no-plugins regression, host cache mount + persistence, install_script execution, multi-plugin layering, build failure surfaces structured error
   **And** all cases produce expected exit codes + JSON event signatures
   **And** tests use a minimal fixture plugin whose install script is a no-op (`echo "ok"`) so test wall time stays under 60s per run after first build

## Tasks / Subtasks

- [ ] **Task 1: Dockerfile.devrail generator script** (AC: 1, 7)
  - [ ] 1.1 Create `scripts/plugin-build-extended-image.sh`. Sources `lib/log.sh`, `lib/plugin-cache.sh`. Header in standard format.
  - [ ] 1.2 Implement `generate_dockerfile <devrail.yml> <output-path>`:
    - Read the loader cache (`/tmp/devrail-plugins-loaded.yaml` from Story 13.2) which already contains full manifests
    - For each plugin, emit a labelled section: `# --- plugin: <name>@<rev> ---`
    - Emit `apt_packages` as a single `RUN apt-get update && apt-get install -y --no-install-recommends <pkgs> && rm -rf /var/lib/apt/lists/*` (only when non-empty)
    - Emit `copy_from_builder` as multiple `COPY --from=<base_image> <src> <src>` lines (only when non-empty; uses the manifest's `base_image` as the `--from` source)
    - Emit `env` as a single `ENV K=V K=V ...` line per pair (sorted by key for determinism)
    - Emit `install_script` as `COPY` of the script into `/opt/devrail/plugins/<slug>/install.sh` then `RUN bash /opt/devrail/plugins/<slug>/install.sh` (script is copied into the image so it doesn't depend on the host cache mount at runtime)
  - [ ] 1.3 Always start with `# Auto-generated by plugin-build-extended-image.sh; DO NOT EDIT.` header and `FROM ghcr.io/devrail-dev/dev-toolchain:v$(get_devrail_version) AS runtime`. Use a pinned tag, not `:v1` floating, so a v1 minor bump doesn't silently invalidate every consumer's cache.
  - [ ] 1.4 Plugin order = lockfile order (alphabetical by source URL — already deterministic from Story 13.3) so dockerfile content hashes are stable.
  - [ ] 1.5 Output exits 0 on success. Skip silently if no plugins declared (no Dockerfile.devrail written).

- [ ] **Task 2: Host-side plugin cache mount** (AC: 6)
  - [ ] 2.1 Add `DEVRAIL_HOST_PLUGINS_CACHE` Makefile variable defaulting to `${HOME}/.cache/devrail/plugins`.
  - [ ] 2.2 Update `DOCKER_RUN` to bind-mount `$(DEVRAIL_HOST_PLUGINS_CACHE):/opt/devrail/plugins`. Always present (even with no plugins declared — the directory is just empty in that case).
  - [ ] 2.3 Create the cache directory on the host before any docker invocation. Pattern: `mkdir -p $(DEVRAIL_HOST_PLUGINS_CACHE)` as a `_check-config` prereq, or as part of a new `_ensure-host-cache` target chained from `_check-config`.
  - [ ] 2.4 Smoke-test: after `make plugins-update`, the host cache directory contains the expected `<slug>/<rev>/plugin.devrail.yml`. After `docker run --rm` finishes, the cache survives.

- [ ] **Task 3: Build pipeline target — `_extended-image` and `_extended-image-resolve`** (AC: 2, 3)
  - [ ] 3.1 Add `_extended-image` internal target that generates `Dockerfile.devrail` and builds the image. Wraps `docker build --quiet -t devrail-local:<hash> -f Dockerfile.devrail .` with structured event emission.
  - [ ] 3.2 Hash the generated `Dockerfile.devrail` (sha256, first 16 hex chars) for the tag suffix.
  - [ ] 3.3 Cache hit: if `docker image inspect devrail-local:<hash>` succeeds, skip the build, emit `extended image cache hit`.
  - [ ] 3.4 Build failures: capture stderr, emit `error`-level event with `failed_plugin` (last plugin section that started in the dockerfile) and `stderr_tail` (last 20 lines).
  - [ ] 3.5 On success, write the chosen tag to `.devrail/extended-image-tag` (workspace-local, gitignored) so other targets can read it without re-hashing.
  - [ ] 3.6 Cache-hit timing target: < 1s wall (verified by smoke test). Include `duration_ms` in the cache-hit event.

- [ ] **Task 4: DOCKER_RUN swap-in for plugin-using projects** (AC: 4, 5)
  - [ ] 4.1 Add `DEVRAIL_RESOLVED_IMAGE` Make-time variable: defaults to `$(DEVRAIL_IMAGE):$(DEVRAIL_TAG)`; if `.devrail/extended-image-tag` exists and `HAS_PLUGINS` is non-empty, override to that tag.
  - [ ] 4.2 Update `DOCKER_RUN` to use `$(DEVRAIL_RESOLVED_IMAGE)` instead of `$(DEVRAIL_IMAGE):$(DEVRAIL_TAG)`.
  - [ ] 4.3 Add `_extended-image` to the prereq chain of public host targets (`check`, `lint`, etc.) so the image is built before `DOCKER_RUN` is invoked. Tricky because `DOCKER_RUN` is `:=` immediate-eval — solution: split into two-stage host-target. First stage materializes the image and writes the tag file; second stage reads the tag file and runs the in-container target. Pattern: `check: _extended-image && $(DOCKER_RUN_DYNAMIC) make _check` where `DOCKER_RUN_DYNAMIC` is recursively-expanded.
  - [ ] 4.4 No-plugins regression: when `HAS_PLUGINS` is empty, `DEVRAIL_RESOLVED_IMAGE` stays at the core image; no Dockerfile.devrail written; no docker build invoked.
  - [ ] 4.5 Add `.devrail/` to a project-template `.gitignore` snippet (touched in Story 13.6 as part of the v1.11.0 release prep).

- [ ] **Task 5: Test fixtures + smoke test** (AC: 8)
  - [ ] 5.1 Create `tests/fixtures/plugin-repos/extended-elixir-v1/`:
    - `plugin.devrail.yml` with a complete `container:` block: `base_image: alpine:3`, `apt_packages: [bash]` (alpine doesn't have apt — pick something universally cheap; revisit), `copy_from_builder: [/bin/sh]`, `env: { TEST_PLUGIN_VAR: hello }`, `install_script: install.sh`
    - `install.sh`: `#!/usr/bin/env bash\necho "extended-elixir install"\n` (no-op fast-execute)
    - Note on `apt_packages` and `alpine`: alpine uses `apk`. For testability, set `base_image: debian:bookworm-slim` and pick a tiny package like `tree` or `jq`. **Decision: use `debian:bookworm-slim` + `apt_packages: [jq]`** so the apt path matches production.
  - [ ] 5.2 Create `tests/test-plugin-build-pipeline.sh`. Pattern mirrors `tests/test-plugin-resolver.sh` (mktemp + git-init harness + `run_make` helper).
  - [ ] 5.3 **Case 1: dockerfile generation determinism** — write a `.devrail.yml` with one plugin, run `_extended-image` twice, sha256 the generated `Dockerfile.devrail` both times, assert equal.
  - [ ] 5.4 **Case 2: build cache hit** — run `_extended-image` twice, assert second invocation emits `extended image cache hit` (not `extended image built`); assert wall time < 1s for second.
  - [ ] 5.5 **Case 3: no plugins → no Dockerfile.devrail, no devrail-local image** — `.devrail.yml` with `languages: [bash]`, no `plugins:`. Run `_extended-image`. Assert `Dockerfile.devrail` does NOT exist; assert `docker images -q devrail-local` is empty (or unchanged).
  - [ ] 5.6 **Case 4: install_script executes** — build, then `docker run --rm devrail-local:<hash> bash -c 'cat /opt/devrail/plugins/<slug>/install.sh'` to verify the script is in the image; or `docker run --rm devrail-local:<hash> printenv TEST_PLUGIN_VAR` to verify the env was applied.
  - [ ] 5.7 **Case 5: multi-plugin layering** — declare two plugins in `.devrail.yml`, build, assert the resulting image has both plugins' env vars present.
  - [ ] 5.8 **Case 6: build failure surfaces structured event** — fixture plugin with `install_script` that exits 1. Run `_extended-image`. Assert exit 2; assert `error` event with `failed_plugin` and `stderr_tail`.
  - [ ] 5.9 **Case 7: host cache persistence** — run `make plugins-update`, then check `${HOME}/.cache/devrail/plugins/<slug>/<rev>/plugin.devrail.yml` exists. Run `make check` (which would trigger another container invocation), confirm the manifest is still there.
  - [ ] 5.10 Use `read_via_docker` helper (sidecar container with `:ro` mount) for cache-content checks since the cache is root-owned 0700 inside docker.

- [ ] **Task 6: Wire smoke test into CI** (AC: 8)
  - [ ] 6.1 Add a step in `.github/workflows/ci.yml` after the existing plugin resolver smoke test: `bash tests/test-plugin-build-pipeline.sh`.

- [ ] **Task 7: Documentation + CHANGELOG**
  - [ ] 7.1 CHANGELOG.md `[Unreleased]` → `### Added`: extended-image build pipeline, host-side persistent plugin cache.
  - [ ] 7.2 Update STABILITY.md "Plugin loader + resolver + lockfile" row to "Plugin loader + resolver + lockfile + build pipeline" (still Preview; execution loop in Story 13.5).
  - [ ] 7.3 Document the `${HOME}/.cache/devrail/plugins` host directory in STABILITY.md "Consumer responsibilities" section (existing area for postgres/bundle install notes).
  - [ ] 7.4 No changes yet to `standards/devrail-yml-schema.md` — Story 13.6 bundles all schema/standards-doc updates.

## Dev Notes

### Authoritative source

The build pipeline contract is defined in `_bmad-output/planning-artifacts/plugin-architecture-design.md` — read **§"Container Integration"** (the chosen Option A — Extended image) and **§"Plugin Lifecycle"** step 5 ("Build (extended-image mode)") before starting Task 1. If the design and this story disagree, the design wins.

### Scope boundary

This story implements the build pipeline and host-side cache plumbing. Out of scope:

- **Execution loop (Story 13.5)** — the per-target dispatch that runs plugin commands during `_lint`/`_format`/etc. Story 13.4 ensures the plugin tools are *present in the image*; Story 13.5 ensures they get *invoked*.
- **v1.11.0 release (Story 13.6)** — packaging the cumulative work.
- **`.devrail.yml` schema doc updates** — bundled into Story 13.6.

### Architectural notes

**Where the Dockerfile.devrail is generated:** in the workspace, alongside `.devrail.yml`. Add `Dockerfile.devrail` and `.devrail/` to a recommended `.gitignore` (Story 13.6 will bundle this into the project template). Generation runs inside the container (yq + access to cached manifests); host runs `docker build` against the workspace.

**Why pin to `:v$(get_devrail_version)` not `:v1`:** the floating major tag changes every minor release. Using it as the `FROM` line means every consumer's `devrail-local:<hash>` invalidates the moment a new core minor lands — even if they didn't touch their plugin set. Pinning to the exact patch version means the hash is stable across local invocations and only churns when the consumer explicitly upgrades the core.

**Host cache layout decision (Story 13.4 closes a Story 13.3 gap):**

The resolver writes to `/opt/devrail/plugins/<slug>/<rev>/...` inside the container. Story 13.3 didn't add a host-side bind mount, so the cache was ephemeral — every `make plugins-update` worked once, then disappeared. Story 13.4 adds the persistent host mount (`${HOME}/.cache/devrail/plugins:/opt/devrail/plugins`) which closes that gap. **This is a 13.3 follow-up that 13.4 is the right place to land**, because the build pipeline is the first consumer that *needs* the cache to survive (the dockerfile generator reads cached manifests).

**Why host_user-owned, not container-root-owned, host cache:**

The resolver and verifier currently run as root inside the container, which means cached manifests end up root-owned on the host. The host user can't read 0700 dirs. Two fixes possible:
- (a) `chmod 0755` the cache after each fetch
- (b) run as the host user inside the container via `--user $(id -u):$(id -g)`

Option (a) is simpler. Apply in `fetch_to_cache` (small follow-up to Story 13.3 work — fold into this PR).

### Dockerfile.devrail generation strategy

Generate inside the container; the script is a Bash + yq affair that reads `${DEVRAIL_PLUGINS_CACHE:-/tmp/devrail-plugins-loaded.yaml}` (Story 13.2's loader cache, which already contains the full merged manifest content). The cache file has a `plugins:` list where each entry is the manifest merged with `source/rev/manifest_path`. So:

```bash
yq -r '.plugins[] | .container.base_image' "$cache_file"
yq -r '.plugins[] | .container.apt_packages // [] | .[]' "$cache_file"
# etc.
```

Cleaner than re-reading individual manifest files.

**Caveat: the loader cache is at `/tmp/...` inside the container — ephemeral.** When `_extended-image` runs, it depends on `_plugins-load` having populated the cache earlier in the same `make` invocation. The dependency chain becomes: `_extended-image: _plugins-load`, and `_plugins-load: _plugins-verify: _check-config` already exists from Stories 13.2/13.3.

### Build wrapping strategy

`docker build --quiet -t devrail-local:<hash> -f Dockerfile.devrail .` — `--quiet` suppresses BuildKit's progress UI but still prints the final image ID on stdout (we capture and discard it). On failure, `--quiet` actually leaks more output than non-quiet — `docker build 2>&1 | tail -100` and tail the captured output for the error event.

For the cache hit path, `docker image inspect devrail-local:<hash>` returns 0 if the image exists locally. Read the timestamp from the inspect output for the `image_age_seconds` field of the cache-hit event (informational; helps consumers understand "this image is from yesterday's plugin set").

### File touchpoints

| Path | Change |
|---|---|
| `dev-toolchain/scripts/plugin-build-extended-image.sh` | New — generates Dockerfile.devrail, hashes, runs docker build, emits structured events. |
| `dev-toolchain/Makefile` | New `_extended-image` internal target, `DEVRAIL_HOST_PLUGINS_CACHE` variable, `DEVRAIL_RESOLVED_IMAGE` swap-in. Add `_extended-image` to prereq chain of `check`/`lint`/etc. (host-side targets). |
| `dev-toolchain/scripts/plugin-resolver.sh` | Small follow-up: chmod cache to 0755 after fetch (closes the 0700-host-blocked side effect). |
| `dev-toolchain/tests/fixtures/plugin-repos/extended-elixir-v1/` | New fixture with full `container:` block. |
| `dev-toolchain/tests/test-plugin-build-pipeline.sh` | New 7-case smoke test. |
| `dev-toolchain/.github/workflows/ci.yml` | New "Plugin build-pipeline smoke test" step. |
| `dev-toolchain/CHANGELOG.md` | `[Unreleased]` → `Added`. |
| `dev-toolchain/STABILITY.md` | Update plugin row + add host-cache to consumer responsibilities. |

### Existing patterns to reuse

- **Structured logging** — `lib/log.sh::log_event`. Use `language="_plugins"` consistently.
- **Exit code convention** — 0 pass, 1 tool failure, 2 misconfig (use 2 for build failures since they're plugin-config failures, not consumer-source failures).
- **Test pattern** — `tests/test-plugin-resolver.sh` is the closest reference (uses local-fs git fixtures and `run_make` helper).
- **`derive_slug` and `compute_content_hash`** — already in `lib/plugin-cache.sh` from Story 13.3 review fix M4.

### Anti-patterns (do NOT do)

- **Don't run `docker build` from inside the container.** Build is host-side. The container generates Dockerfile.devrail; the host invokes docker.
- **Don't pin `FROM` to `:v1` (floating).** Use the exact patch version (`v$(get_devrail_version)`).
- **Don't shell out to anything outside `lib/`** for the dockerfile-content hash — `sha256sum` + bash is enough.
- **Don't bake the install_script execution result into the cache.** The script runs at *image build* time; if it depends on network or external state, the build is non-reproducible. That's a plugin-author concern; document the expectation in `standards/contributing.md` (Story 13.6).
- **Don't add per-target Dockerfile.devrail variants.** One image per plugin set, not one per target.

## Previous Story Intelligence — Stories 13.2 + 13.3

- **Loader cache (`/tmp/devrail-plugins-loaded.yaml`)** is the input to the dockerfile generator. Contains full manifest content per plugin (Story 13.2 review fix H1). Don't re-parse individual manifests.
- **`lib/plugin-cache.sh`** has `derive_slug` (`.git`-suffix-stripping basename) and `compute_content_hash` (Story 13.3 review fix M4). Reuse for the build-pipeline hash logic.
- **Lockfile is alphabetical-by-source** (Story 13.3 review fix). Loader iterates plugins in lockfile order. Therefore the dockerfile generator iterates in lockfile order, producing deterministic content hashes.
- **`make _check` ordering** is now: `_check-config → _plugins-verify → _plugins-load → _check`. Story 13.4 wedges `_extended-image` in. Final order: `_check-config → _ensure-host-cache → _plugins-verify → _plugins-load → _extended-image (host-side) → DOCKER_RUN → _check (in-container)`. Note `_extended-image` is the FIRST host-side step; the others are in-container. Care needed in target arrangement.
- **The `gates:` field is parser-validated** (Story 13.2 review fix M1). Story 13.4 doesn't touch gates.
- **`DEVRAIL_PLUGINS_DIR` env override** is recognised in resolver and verifier. Build pipeline must honour it too — tests rely on this for fixture-mounted setups.
- **PR pattern** for Story 13.x: implementation PR, then review-followup PR, then patch release. Two cycles in one is OK if the implementation PR's review surface is small.

## Git Intelligence — Recent dev-toolchain Patterns

```
35475df chore(release): prepare v1.10.2
d92a982 fix(makefile): address Story 13.3 senior-developer review findings (#35)
7705db8 feat(makefile): plugin resolver and lockfile (Story 13.3) (#34)
6cc4182 chore(release): prepare v1.10.1
3b91e95 fix(makefile): address Story 13.2 senior-developer review findings (#33)
```

Patterns to follow (proven across 13.2 and 13.3):

- **Per-script structure:** sources lib/log.sh + lib/plugin-cache.sh, has `--help`, validates args, sets `LC_ALL=C`, traps temp-file cleanup on EXIT.
- **Cache files** in `/tmp/devrail-*.yaml` (or `.devrail/...` workspace-local for human-visible artifacts).
- **`run_make` helper** in tests is the right pattern for orchestrating multi-case smoke tests with shared docker fixtures.
- **Pre-commit hook ownership**: shfmt rewrites files as root inside the container; `sudo chown` after to restore. Already a known dance.

Patterns to avoid:

- **Don't add new `:= $(shell ...)` evaluations before `DEVRAIL_CONFIG`.** Place new immediate-eval Make variables AFTER the existing language-detection block (Story 13.2 review caught this in PR #27 originally).
- **Don't write tests that do host-side filesystem checks on docker-written paths** without using a sidecar `:ro` mount (Story 13.3 Case 16 hit this with `mktemp -d`'s 0700 default).
- **Don't accumulate findings without writing a regression test.** Each finding from the 13.2 + 13.3 reviews resulted in a new test case; that's why the loader smoke test grew from 8 to 11 and the resolver smoke from 11 to 16.

## Latest Tech Information

No external research needed. Tools used:

- **`docker build`** v28.x with BuildKit (already a hard requirement; `Makefile` uses it for `make build`).
- **`docker image inspect`** for cache-hit detection.
- **`yq` v4.44.1** — `eval-all` for stream processing the loader cache; `load(...)` for inlining files.
- **`sha256sum`** — coreutils, already in image.
- **bash 5.x** — associative arrays, parameter expansion (`${var//pattern/replacement}`), all available.

## Project Context Reference

- Project root: `~/Work/gitlab.mfsoho.linkridge.net/OrgDocs/development-standards`
- Implementation repo: `~/Work/github.com/devrail-dev/dev-toolchain`
- Plugin design: `_bmad-output/planning-artifacts/plugin-architecture-design.md` §"Container Integration"
- Predecessor stories: 13.2 (`13-2-implement-plugin-manifest-parser-and-loader.md`), 13.3 (`13-3-implement-plugin-resolver-and-lockfile.md`)
- CLAUDE.md critical rules apply (especially #1 `make check` before completion, #6 use shared logging library, #7 never suppress failing checks).

## References

- [Source: `_bmad-output/planning-artifacts/plugin-architecture-design.md#Container Integration`] — Option A rationale and example Dockerfile (line 351+)
- [Source: `_bmad-output/planning-artifacts/plugin-architecture-design.md#Plugin Lifecycle`] — step 5, build phase (line 304)
- [Source: `_bmad-output/planning-artifacts/plugin-architecture-design.md#Plugin Manifest`] — `container:` block schema (line 154+)
- [Source: `_bmad-output/planning-artifacts/epics.md#Story 13.4`] — story-level AC
- [Source: `_bmad-output/implementation-artifacts/13-2-implement-plugin-manifest-parser-and-loader.md`] — loader cache contract
- [Source: `_bmad-output/implementation-artifacts/13-3-implement-plugin-resolver-and-lockfile.md`] — host cache layout, lockfile format
- [Source: `dev-toolchain/Makefile`] — current `_check`/`_lint`/etc. recipe structure
- [Source: `dev-toolchain/lib/plugin-cache.sh`] — `derive_slug`, `compute_content_hash`
- [Source: `dev-toolchain/lib/log.sh`] — `log_event`
- [Source: `dev-toolchain/tests/test-plugin-resolver.sh`] — test harness pattern reference

## Dev Agent Record

### Agent Model Used

(populated by dev agent at implementation time)

### Debug Log References

### Completion Notes List

- Ultimate context engine analysis completed — comprehensive developer guide created. Story 13.4 is the v1.10.x build-pipeline story; depends on Stories 13.2 (loader cache) and 13.3 (resolver). Closes a 13.3 gap by adding the host-side persistent plugin cache mount. Scope explicitly bounded against 13.5 (execution loop) and 13.6 (release).

### File List
