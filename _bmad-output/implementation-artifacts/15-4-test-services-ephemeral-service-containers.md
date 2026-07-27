# Story 15.4: `test.services` — Ephemeral Service Containers for Integration Tests

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **developer whose test suite needs a real database or cache** (e.g. a FastAPI/Rails app with integration tests against Postgres, or a cache-layer test against Redis),
I want `.devrail.yml` `test.services: [postgres:16, redis:7]` to start throwaway service containers before `make test` and tear them down afterward, with connection details injected as environment variables,
so that I don't have to hand-manage a sibling Postgres/Redis container and Docker network myself (today's only option, via issue #48's `docker_network`/`env` keys) just to run integration tests locally or in CI.

## Acceptance Criteria

1. **Given** `.devrail.yml` declares `test:` `services: [postgres:16]`
   **When** `make test` runs
   **Then** DevRail creates a throwaway Docker network, starts a `postgres:16` container attached to it, waits for it to accept connections (`pg_isready`), injects `DATABASE_URL=postgresql://postgres:devrail@<container>:5432/devrail_test` into the toolchain container, runs the test suite, and tears down the service container + network afterward — regardless of whether the test suite passed or failed
   **And** the toolchain container can actually reach the service and run a real query against it — proven with a real `psql`/`SELECT 1` (or language-suite-equivalent), not just "the container started"

2. **Given** `.devrail.yml` declares `services: [redis:7]`
   **When** `make test` runs
   **Then** DevRail starts a `redis:7` container the same way, waits for readiness (`redis-cli ping` → `PONG`), and injects `REDIS_URL=redis://<container>:6379`
   **And** both `postgres` and `redis` can be declared together — two service containers, one shared ephemeral network, both env vars injected

3. **Given** the toolchain container has no `docker` CLI and no `/var/run/docker.sock` mount (confirmed by hand before writing this story — see Dev Notes)
   **When** implemented
   **Then** all container/network orchestration happens **host-side** (a new host-side prerequisite of the public `test` target, mirroring the existing `_extended-image` host-side-prerequisite pattern), never by giving the toolchain container Docker socket access — that would be a real privilege-escalation surface (root-equivalent host access) for a feature that doesn't need it

4. **Given** the existing `docker_network`/`env` mechanism (issue #48) already lets the toolchain container join a network and receive env vars
   **When** implemented
   **Then** `test.services`' host-side orchestration produces exactly what that existing mechanism already consumes — an ephemeral network name and an env file — added as two new `$(if $(wildcard ...))`-guarded, recursively-expanded flag variables folded into the existing shared `DOCKER_RUN` macro (empty/no-op for every target except `test`, since only `test`'s new host-side prerequisite ever creates the state files they read)
   **And** no new "special path" is invented for `test` — it still resolves to `$(DOCKER_RUN) make _test`, just with `DOCKER_RUN` now transparently carrying two more (usually-empty) flags

5. **Given** `test.services` and the existing `docker_network` key both put a `--network` flag into the same `docker run` invocation, and only one `--network` flag is honored
   **When** both are declared simultaneously in the same `.devrail.yml`
   **Then** `make test` fails fast at the host-side orchestration step with a clear misconfiguration error (exit 2) explaining the two keys are mutually exclusive for the `test` target specifically, rather than silently running with whichever flag Docker happens to pick

6. **Given** a project with no `test:` `services:` key (the overwhelming majority of consumers, including every existing fixture from Stories 15.1–15.3)
   **When** `make test` runs
   **Then** the new host-side prerequisite is a fast no-op (no network created, no containers started) and `make test`'s behavior, output, and timing are unchanged from pre-Story-15.4

7. **Given** an unsupported `test.services` entry (anything other than a `postgres:*` or `redis:*` image reference)
   **When** `make test` runs
   **Then** DevRail fails fast with a clear misconfiguration error naming the unsupported entry, rather than silently skipping it or pretending to start a service it doesn't actually know how to configure/inject env for — matching this project's established "don't half-implement a signal you can't act on" precedent from Story 15.2 (poetry/pipenv lockfiles) and Story 15.1 (Ansible root-discovery)

8. **Given** the test suite (or the orchestration itself) fails partway through
   **When** `make test` exits (any exit code)
   **Then** the service container(s) and ephemeral network are still torn down — verified by actually killing a test run mid-flight and confirming no orphaned containers/networks remain, not just by reading the trap code and assuming it works
   **And** a stale state directory left over from a previous run that never got torn down (e.g. the process was killed with `SIGKILL`, which a shell `trap` cannot intercept) is detected and cleaned up automatically at the start of the *next* `make test` run, rather than causing container/network name collisions forever

9. **Given** `docker-compose.test.yml` autodetection was mentioned as optional in the epic's original draft
   **When** scoped for this story
   **Then** it is explicitly deferred — a distinct parsing/config-translation surface with its own scope, not needed to deliver the core `test.services` ask. Do not attempt it here.

10. **Given** a passing test suite
    **When** `bash tests/test-test-services.sh` runs (new script — this is new orchestration behavior, not an extension of an existing per-recipe concern like Stories 15.1–15.3's `tests/test-project-discover.sh`)
    **Then** it covers: Postgres alone, Redis alone, both together, no `test.services` declared (regression/no-op), the `docker_network` + `test.services` mutual-exclusion error, an unsupported service entry erroring clearly, and — critically — that teardown actually happens (query `docker ps`/`docker network ls` after the test run and assert nothing DevRail-created remains), using real Docker operations against real Postgres/Redis images, not mocks

## Tasks / Subtasks

- [ ] **Task 1: `scripts/test-services.sh` — host-side orchestration script** (AC: 1, 2, 3, 5, 6, 7, 8)
  - [ ] 1.1 New script, `up`/`down` subcommands, matching the existing `scripts/*.sh` header/style convention (`lib/log.sh` sourced, standard purpose/usage/deps header).
  - [ ] 1.2 `up`: read `.devrail.yml` `test.services` via `yq`. Empty/absent → no-op, exit 0 (AC 6). Non-empty:
    - Detect and clean up any stale state directory from a prior incomplete run first (AC 8) — `rm -f` any tracked container by name (ignore "not found" errors) and `docker network rm` any tracked network (ignore "not found"/"has active endpoints" errors gracefully — log and continue) before proceeding.
    - Check `docker_network` is NOT also set in `.devrail.yml` when `test.services` is non-empty — if both are set, emit a clear `error`-level event and exit 2 (AC 5).
    - For each `test.services` entry: match against `postgres:*` or `redis:*` (simple prefix match on the image reference before the colon). Anything else → `error` event naming the unsupported entry, exit 2 (AC 7). Do not start any containers if ANY entry is unsupported — validate the whole list before starting anything (fail fast, not partial-then-fail).
    - Generate a unique network name (e.g. `devrail-test-<random-suffix>` — `mktemp`-style, not a deterministic name based on cwd, so concurrent `make test` runs on the same host/CI runner don't collide). `docker network create <name>`.
    - For each service, generate a unique container name, start it detached and attached to the network with sane test-friendly defaults (`postgres:16` → `POSTGRES_PASSWORD=devrail`, `POSTGRES_DB=devrail_test`, `POSTGRES_USER=postgres`; `redis:7` → no auth, defaults are fine for an ephemeral throwaway instance), poll for readiness with a bounded timeout (`pg_isready`/`redis-cli ping` via `docker exec`, ~30s cap, clear timeout error if exceeded), then append the corresponding `DATABASE_URL`/`REDIS_URL` line to the state env file.
    - Write state to `.devrail/test-services/`: `network` (network name), `containers` (one name per line, for teardown), `env` (the env-file DOCKER_RUN will consume via `--env-file`).
  - [ ] 1.3 `down`: if `.devrail/test-services/` doesn't exist, no-op exit 0. Else: `docker rm -f` every tracked container (ignore individual failures, log and continue — don't let one already-gone container block cleaning up the rest), `docker network rm` the tracked network, remove the state directory.
  - [ ] 1.4 Idempotent, re-runnable, safe against partial prior state (this is the whole point of AC 8's stale-state handling).
  - [ ] 1.5 Structured JSON events throughout (`log_event`/`log_info`/`log_error` from `lib/log.sh`) — no raw `echo`, matching every other script in this codebase.

- [ ] **Task 2: Wire into the Makefile** (AC: 4, 6)
  - [ ] 2.1 Add `_test-services-up` host-side target: `@bash scripts/test-services.sh up`. Depends on `_ensure-host-cache` (needs `.devrail/` machinery already set up the way `_extended-image` does).
  - [ ] 2.2 Add two new recursively-expanded (`=`) Make variables, mirroring `DEVRAIL_RESOLVED_IMAGE`'s existing pattern exactly: `DEVRAIL_TEST_SERVICES_NETWORK_FLAG` (reads `.devrail/test-services/network` if present, emits `--network <name>`, else empty) and `DEVRAIL_TEST_SERVICES_ENV_FLAG` (reads for `.devrail/test-services/env`'s existence, emits `--env-file .devrail/test-services/env`, else empty).
  - [ ] 2.3 Fold both into the shared `DOCKER_RUN` macro (alongside the existing `DEVRAIL_NETWORK_FLAG`/`DEVRAIL_ENV_FLAGS`). Confirm by inspection AND by testing that this is a true no-op for `lint`/`format`/`fix`/`security`/`scan`/`docs`/`changelog`/`plugins-update` when no `test.services` are declared (the overwhelming majority case, and literally always the case for every target except `test`, since nothing else depends on `_test-services-up`).
  - [ ] 2.4 Change the public `test:` target's recipe from the current one-liner (`$(DOCKER_RUN) make _test`) to add `_test-services-up` as a prerequisite and wrap the body in a shell `trap '...test-services.sh down' EXIT` so teardown runs regardless of `make _test`'s exit code (AC 1, AC 8).
  - [ ] 2.5 Do **not** touch `check:`'s recipe or dependency chain beyond what naturally follows from `test:` already being one of `check`'s constituent targets — `make check` should pick this up for free through `test:`, not need separate wiring.

- [ ] **Task 3: `.devrail.yml` schema + docs** (AC: 5, 7, 9)
  - [ ] 3.1 `standards/devrail-yml-schema.md`: document `test.services` (list of strings, `postgres:<tag>`/`redis:<tag>` only for now) under the existing `test:` section (added by Story 15.2) — do not create a new top-level section. State plainly: mutually exclusive with `docker_network` for the `test` target; unsupported entries error, they don't skip silently; `docker-compose.test.yml` autodetection is explicitly not implemented.
  - [ ] 3.2 `standards/makefile-contract.md`: extend the `### test` entry (added by Story 15.2) with a short note on the host-side orchestration and its no-op guarantee when unused.
  - [ ] 3.3 Document the injected env var names (`DATABASE_URL`, `REDIS_URL`) and their exact format so a consumer knows what to expect without reading the script.

- [ ] **Task 4: Test suite** (AC: 10)
  - [ ] 4.1 New `tests/test-test-services.sh` (not an extension of an existing script — this is genuinely new orchestration behavior). Follow the established `mktemp` `$WORKDIR` + cleanup-trap convention from Stories 15.1–15.3.
  - [ ] 4.2 Cases: Postgres alone (real `SELECT 1` through the injected `DATABASE_URL`, run from inside a throwaway container on the same network — mirrors how the design was hand-verified during `create-story`), Redis alone (`SET`/`GET` through `REDIS_URL`), both together, no `test.services` declared (assert `make test` behaves identically to a Story-15.1-era fixture — reuse `tests/fixtures/single-root-python`), `docker_network` + `test.services` both declared → exit 2 with a clear error, an unsupported entry (e.g. `mysql:8`) → exit 2 with a clear error naming it.
  - [ ] 4.3 **Teardown verification is not optional** — after each service-starting test case, assert (via `docker ps -a --filter` / `docker network ls --filter`, matched against the state this story's own naming scheme produces) that no DevRail-created container or network remains. This is the one AC in this story where "the trap code looks right" is not sufficient evidence — actually kill a `make test` run mid-flight (e.g. `timeout 2 ... || true` against a scenario designed to still be orchestrating) at least once and confirm cleanup still happened, not just the happy-path completion case.
  - [ ] 4.4 Requires Docker-in-Docker capability in whatever environment runs this test (the CI runner already has this — it's running `docker build`/`docker run` for every other test in this suite). Note this plainly in the script's header, same as `tests/test-dependency-install.sh` notes its network requirement.

- [ ] **Task 5: CI + docs**
  - [ ] 5.1 Add a step to `.github/workflows/ci.yml` after the Story 15.3 step: `bash tests/test-test-services.sh`.
  - [ ] 5.2 `CHANGELOG.md` `[Unreleased]` → `### Added`.
  - [ ] 5.3 `STABILITY.md`: new row (this is not a generalization of an existing row the way Story 15.3 was — it's a genuinely new capability). Mark Preview.
  - [ ] 5.4 This is the last story in Epic 15 — check whether the epic itself should move to `done` once this lands (all four stories `review`/merged) and whether an epic retrospective is warranted per the sprint-status workflow notes.

## Dev Notes

### The core architectural constraint (read first)

The toolchain container has **no `docker` CLI and no `/var/run/docker.sock` mount** — confirmed by hand before writing this story:

```
$ docker run --rm ghcr.io/devrail-dev/dev-toolchain:1.12.0 bash -c 'command -v docker'
(no output — not found)
$ grep -n "docker.sock" Makefile
(no matches)
```

This rules out the "toolchain container orchestrates its own sibling containers" approach entirely — that would require mounting the host's Docker socket into the container, which grants that container root-equivalent control over the host (a well-known container-escape/privilege-escalation vector). This story does not need that capability and must not introduce it. All orchestration is host-side, mirroring `_extended-image`'s existing host-side-prerequisite pattern exactly.

### The design, proven by hand before writing any code

The full mechanics were verified working end-to-end during `create-story`, not just designed on paper:

```bash
docker network create devrail-test-<x>
docker run -d --network devrail-test-<x> --name pg-<x> -e POSTGRES_PASSWORD=devrail -e POSTGRES_DB=devrail_test postgres:16
# poll: docker exec pg-<x> pg_isready -U postgres   (ready after ~5s)
docker run --rm --network devrail-test-<x> postgres:16 psql "postgresql://postgres:devrail@pg-<x>:5432/devrail_test" -c "SELECT 1;"
# → real result: 1 row
docker rm -f pg-<x>; docker network rm devrail-test-<x>
```

Same pattern verified for `redis:7` (`redis-cli ping` → `PONG`, then a real `SET`/`GET` round-trip through the network by hostname). Both took well under a minute end-to-end including image pulls. This is not a hypothetical design — every step above ran for real before AC 1/2 were written to describe it.

### Reusing existing plumbing instead of inventing a parallel path

`DEVRAIL_RESOLVED_IMAGE` already demonstrates the exact pattern this story needs: a host-side prerequisite target (`_extended-image`) writes a value to a file under `.devrail/`, and a **recursively-expanded** (`=`, not `:=`) Make variable reads that file lazily at `DOCKER_RUN`-expansion time, which happens *after* the prerequisite has already run (Make prerequisite ordering guarantees this). This story adds two more variables in that same shape (`DEVRAIL_TEST_SERVICES_NETWORK_FLAG`, `DEVRAIL_TEST_SERVICES_ENV_FLAG`), folded into the *same* shared `DOCKER_RUN` macro every target already uses. Because they're `$(if $(wildcard ...))`-guarded and only `test:` depends on the prerequisite that ever creates the files they check for, they're a true no-op everywhere else — no new macro, no new "test-specific docker run," no risk of the ephemeral network leaking into `make lint`.

### Why Postgres/Redis specifically, not arbitrary images

The epic's own draft used `postgres:16, redis:7` as the example, not a claim of generic support. Supporting an arbitrary image would mean either no readiness check at all (racy — tests could start before the service accepts connections) or a generic port-open check (weaker than `pg_isready`/`redis-cli ping`, which confirm the *service*, not just the *TCP listener*, is ready) and no way to know what env var name/URL scheme to inject. Matches the scope-narrowing precedent from Story 15.2 (only `uv`/`pip`/`npm`, not `poetry`/`pipenv`/`pnpm`/`yarn`) and Story 15.1 (Ansible excluded once investigation showed it needed something different than what was built). Adding a third/fourth well-known service later is a small, additive follow-up in the same shape — not a redesign.

### Backward-compatibility note (identical guarantee shape to Stories 15.1–15.3)

The overwhelming majority of consumers declare no `test.services` — `_test-services-up` must be fast (a single `yq` read, nothing else) and every new Make variable must resolve empty for them. Verify explicitly with a regression fixture, not just by inspection.

### What NOT to do

- **Don't** install `docker` CLI or mount `/var/run/docker.sock` into the toolchain container — see the constraint above.
- **Don't** support arbitrary `test.services` image references — Postgres/Redis only, fail clearly on anything else (AC 7).
- **Don't** attempt `docker-compose.test.yml` autodetection — explicitly deferred (AC 9).
- **Don't** let `test.services` and `docker_network` silently coexist with undefined `--network` precedence — fail fast (AC 5).
- **Don't** trust that a `trap ... EXIT` handles every termination case — it does not catch `SIGKILL`. Handle stale state at the *start* of the next `up`, not just cleanup at the end of `down` (AC 8).
- **Don't** claim teardown works because the trap code reads correctly — verify it by actually checking `docker ps`/`docker network ls` after a test run, and after a mid-flight kill, same rigor Story 15.3's review demanded for AC 7's multi-root claim.
- **Don't** bind-mount checked-in fixtures directly as writable Docker workspaces in the new test script — `mktemp` + copy + trap, same as every prior story in this epic.

### Project structure notes

- Implementation in `~/Work/github.com/devrail-dev/dev-toolchain`. Branch: `feat/52-test-services` off `main` (or off Stories 15.1–15.3's branches if those haven't merged yet — check current state before branching; this story depends on Story 15.2's `test:` schema key existing, not on 15.1/15.3's Makefile changes, so it can branch from either the tip of the epic's work or from `main` plus a cherry-pick of 15.2, whichever is cleaner at implementation time).
- Conventional commit scope: `makefile`.
- Closes the remainder of issue #52's original proposal (the `test.services` piece Story 15.2 explicitly deferred).

## Previous Story Intelligence — Stories 15.1–15.3

- **Story 15.2** is this story's direct dependency — `test:` `install`/`setup` keys already exist in the schema; this story adds `services` as a sibling key under the same `test:` mapping, not a new top-level key.
- **Real bugs caught in prior stories, apply the same scrutiny here:**
  - Story 15.2: an untested assumption (`uv sync`'s venv) turned out completely wrong when actually run. This story's design was therefore verified by hand (network create → container start → readiness → cross-container query → cleanup) *before* writing ACs around it — same discipline, applied earlier in the process this time.
  - Story 15.2: `local rc=$?` after a bare `if...fi` with no `else` silently discarded failure. Any exit-code capture in `scripts/test-services.sh` must use an explicit `else` branch.
  - Story 15.3 (code review): AC claims not backed by committed tests (multi-root, format/fix/security coverage). This story's AC 10/Task 4 are written to explicitly require verifying teardown really happens (not just that the trap code exists) — don't let this story's own review catch the same class of gap a third time.
  - Story 15.1 (code review): bind-mounting checked-in fixtures directly as writable Docker workspaces leaked stray artifacts into tracked directories. Use `mktemp` + copy + trap in the new test script from the start.

## Latest Tech Information

- **`postgres:16`** — official image, `POSTGRES_PASSWORD`/`POSTGRES_DB`/`POSTGRES_USER` env vars control initialization; `pg_isready` ships in the image and is the standard readiness signal (confirmed working, ~5s cold start including image-already-present case).
- **`redis:7`** — official image, no auth by default; `redis-cli ping` → `PONG` is the standard readiness signal (confirmed working, ~1s cold start).
- **Docker networking** — a user-defined bridge network (`docker network create`, no driver flag needed) gives automatic DNS resolution of container names to other containers on the same network; confirmed by hand (`psql postgresql://...@pg-<x>:5432/...` resolved and connected using the container's `--name` as hostname with no extra config).
- **`docker run --env-file <path>`** — native Docker flag, reads `KEY=VALUE` lines from a file; simpler than converting to N separate `-e KEY=VALUE` flags for a dynamically-sized service list.

## Project Context Reference

- Project root: `~/Work/gitlab.mfsoho.linkridge.net/OrgDocs/development-standards` (this repo, planning)
- Implementation repo: `~/Work/github.com/devrail-dev/dev-toolchain`
- CLAUDE.md critical rules apply throughout (especially #1 `make check`, #6 shared logging library, #7 never suppress failing checks, #8 update docs alongside behavior changes).

## References

- [Source: GitHub issue #52](https://github.com/devrail-dev/dev-toolchain/issues/52) — original proposal; `services:` was explicitly called out as "the one piece autodetect can't fully infer" and "a distinct, larger piece of work"
- [Source: `_bmad-output/planning-artifacts/epics.md#Epic 15`] — story-level AC and epic background
- [Source: `_bmad-output/implementation-artifacts/15-2-autodetect-and-install-python-js-dependencies-before-make-test.md`] — direct dependency; the `test:` schema key this story extends
- [Source: `dev-toolchain/Makefile`] — study `_extended-image`/`DEVRAIL_RESOLVED_IMAGE` (lines ~35-62, ~189-210) as the exact pattern this story's host-side-prerequisite + recursively-expanded-variable design mirrors
- [Source: Makefile `docker_network`/`docker_volumes` handling (issue #48)] — the existing mechanism this story's output feeds into

## Dev Agent Record

_(populated during dev-story execution)_

## Change Log

| Date | Change |
|---|---|
| 2026-07-26 | Story created via the formal `create-story` workflow (auto-discovered as the last remaining `backlog` story in Epic 15). Unlike prior stories in this epic, the critical design question here was architectural (how to orchestrate sibling containers safely) rather than a claim to verify — investigated and confirmed the toolchain container has no Docker socket access (ruling out in-container orchestration), then designed and hand-verified a host-side orchestration approach (network create, service start, readiness wait, cross-container connectivity, cleanup) end-to-end for both Postgres and Redis before writing any AC. Scoped to Postgres/Redis only (matching the epic's own example, not a generic-image claim); `docker-compose.test.yml` autodetection explicitly deferred. Status: `ready-for-dev`. |
