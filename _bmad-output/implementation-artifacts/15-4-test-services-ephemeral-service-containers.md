# Story 15.4: `test.services` — Ephemeral Service Containers for Integration Tests

Status: review

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

- [x] **Task 1: `scripts/test-services.sh` — host-side orchestration script** (AC: 1, 2, 3, 5, 6, 7, 8)
  - [x] 1.1 New script, `up`/`down` subcommands, matching the existing `scripts/*.sh` header/style convention (`lib/log.sh` sourced, standard purpose/usage/deps header).
  - [x] 1.2 `up`: read `.devrail.yml` `test.services` via `yq`. Empty/absent → no-op, exit 0 (AC 6). Non-empty:
    - Detect and clean up any stale state directory from a prior incomplete run first (AC 8) — `rm -f` any tracked container by name (ignore "not found" errors) and `docker network rm` any tracked network (ignore "not found"/"has active endpoints" errors gracefully — log and continue) before proceeding.
    - Check `docker_network` is NOT also set in `.devrail.yml` when `test.services` is non-empty — if both are set, emit a clear `error`-level event and exit 2 (AC 5).
    - For each `test.services` entry: match against `postgres:*` or `redis:*` (simple prefix match on the image reference before the colon). Anything else → `error` event naming the unsupported entry, exit 2 (AC 7). Do not start any containers if ANY entry is unsupported — validate the whole list before starting anything (fail fast, not partial-then-fail).
    - Generate a unique network name (e.g. `devrail-test-<random-suffix>` — `mktemp`-style, not a deterministic name based on cwd, so concurrent `make test` runs on the same host/CI runner don't collide). `docker network create <name>`.
    - For each service, generate a unique container name, start it detached and attached to the network with sane test-friendly defaults (`postgres:16` → `POSTGRES_PASSWORD=devrail`, `POSTGRES_DB=devrail_test`, `POSTGRES_USER=postgres`; `redis:7` → no auth, defaults are fine for an ephemeral throwaway instance), poll for readiness with a bounded timeout (`pg_isready`/`redis-cli ping` via `docker exec`, ~30s cap, clear timeout error if exceeded), then append the corresponding `DATABASE_URL`/`REDIS_URL` line to the state env file.
    - Write state to `.devrail/test-services/`: `network` (network name), `containers` (one name per line, for teardown), `env` (the env-file DOCKER_RUN will consume via `--env-file`).
  - [x] 1.3 `down`: if `.devrail/test-services/` doesn't exist, no-op exit 0. Else: `docker rm -f` every tracked container (ignore individual failures, log and continue — don't let one already-gone container block cleaning up the rest), `docker network rm` the tracked network, remove the state directory.
  - [x] 1.4 Idempotent, re-runnable, safe against partial prior state (this is the whole point of AC 8's stale-state handling).
  - [x] 1.5 Structured JSON events throughout (`log_event`/`log_info`/`log_error` from `lib/log.sh`) — no raw `echo`, matching every other script in this codebase.

- [x] **Task 2: Wire into the Makefile** (AC: 4, 6)
  - [x] 2.1 Add `_test-services-up` host-side target: `@bash scripts/test-services.sh up`. Depends on `_ensure-host-cache` (needs `.devrail/` machinery already set up the way `_extended-image` does).
  - [x] 2.2 Add two new recursively-expanded (`=`) Make variables, mirroring `DEVRAIL_RESOLVED_IMAGE`'s existing pattern exactly: `DEVRAIL_TEST_SERVICES_NETWORK_FLAG` (reads `.devrail/test-services/network` if present, emits `--network <name>`, else empty) and `DEVRAIL_TEST_SERVICES_ENV_FLAG` (reads for `.devrail/test-services/env`'s existence, emits `--env-file .devrail/test-services/env`, else empty).
  - [x] 2.3 Fold both into the shared `DOCKER_RUN` macro (alongside the existing `DEVRAIL_NETWORK_FLAG`/`DEVRAIL_ENV_FLAGS`). Confirm by inspection AND by testing that this is a true no-op for `lint`/`format`/`fix`/`security`/`scan`/`docs`/`changelog`/`plugins-update` when no `test.services` are declared (the overwhelming majority case, and literally always the case for every target except `test`, since nothing else depends on `_test-services-up`).
  - [x] 2.4 Change the public `test:` target's recipe from the current one-liner (`$(DOCKER_RUN) make _test`) to add `_test-services-up` as a prerequisite and wrap the body in a shell `trap '...test-services.sh down' EXIT` so teardown runs regardless of `make _test`'s exit code (AC 1, AC 8).
  - [x] 2.5 Do **not** touch `check:`'s recipe or dependency chain beyond what naturally follows from `test:` already being one of `check`'s constituent targets — `make check` should pick this up for free through `test:`, not need separate wiring.

- [x] **Task 3: `.devrail.yml` schema + docs** (AC: 5, 7, 9)
  - [x] 3.1 `standards/devrail-yml-schema.md`: document `test.services` (list of strings, `postgres:<tag>`/`redis:<tag>` only for now) under the existing `test:` section (added by Story 15.2) — do not create a new top-level section. State plainly: mutually exclusive with `docker_network` for the `test` target; unsupported entries error, they don't skip silently; `docker-compose.test.yml` autodetection is explicitly not implemented.
  - [x] 3.2 `standards/makefile-contract.md`: extend the `### test` entry (added by Story 15.2) with a short note on the host-side orchestration and its no-op guarantee when unused.
  - [x] 3.3 Document the injected env var names (`DATABASE_URL`, `REDIS_URL`) and their exact format so a consumer knows what to expect without reading the script.

- [x] **Task 4: Test suite** (AC: 10)
  - [x] 4.1 New `tests/test-test-services.sh` (not an extension of an existing script — this is genuinely new orchestration behavior). Follow the established `mktemp` `$WORKDIR` + cleanup-trap convention from Stories 15.1–15.3.
  - [x] 4.2 Cases: Postgres alone (real `SELECT 1` through the injected `DATABASE_URL`, run from inside a throwaway container on the same network — mirrors how the design was hand-verified during `create-story`), Redis alone (`SET`/`GET` through `REDIS_URL`), both together, no `test.services` declared (assert `make test` behaves identically to a Story-15.1-era fixture — reuse `tests/fixtures/single-root-python`), `docker_network` + `test.services` both declared → exit 2 with a clear error, an unsupported entry (e.g. `mysql:8`) → exit 2 with a clear error naming it.
  - [x] 4.3 **Teardown verification is not optional** — after each service-starting test case, assert (via `docker ps -a --filter` / `docker network ls --filter`, matched against the state this story's own naming scheme produces) that no DevRail-created container or network remains. This is the one AC in this story where "the trap code looks right" is not sufficient evidence — actually kill a `make test` run mid-flight (e.g. `timeout 2 ... || true` against a scenario designed to still be orchestrating) at least once and confirm cleanup still happened, not just the happy-path completion case.
  - [x] 4.4 Requires Docker-in-Docker capability in whatever environment runs this test (the CI runner already has this — it's running `docker build`/`docker run` for every other test in this suite). Note this plainly in the script's header, same as `tests/test-dependency-install.sh` notes its network requirement.

- [x] **Task 5: CI + docs**
  - [x] 5.1 Add a step to `.github/workflows/ci.yml` after the Story 15.3 step: `bash tests/test-test-services.sh`.
  - [x] 5.2 `CHANGELOG.md` `[Unreleased]` → `### Added`.
  - [x] 5.3 `STABILITY.md`: new row (this is not a generalization of an existing row the way Story 15.3 was — it's a genuinely new capability). Mark Preview.
  - [x] 5.4 This is the last story in Epic 15 — check whether the epic itself should move to `done` once this lands (all four stories `review`/merged) and whether an epic retrospective is warranted per the sprint-status workflow notes.

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

### Agent Model Used

Claude Sonnet 5 — single-session execution via the formal `dev-story` workflow.

### Debug Log References

- **Consumer-repo compat gap caught mid-implementation.** The story's design didn't originally account for `_devrail-host-bin`'s existing precedent: consumer template repos inherit this Makefile but not `scripts/`, so any new host-side script needs the same local-vs-extracted-from-image resolution `_extended-image` already has. Added a `_test-services-host-bin` target mirroring that pattern exactly (same cache file, same docker create/cp/rm shape) — without it, `test.services` would have silently only worked for the dev-toolchain repo itself, not for the actual target audience (external consumers). Verified both paths: local (`scripts/test-services.sh` present) and extracted (fixture with no local `scripts/`, using a container image with the script baked in via `COPY scripts/`).
- **Three real bugs in the test script itself, all different flavors of "state doesn't cross a boundary the way it looks like it should":**
  1. `workspace_for`'s original design used a global `WORKSPACE_COUNTER` incremented inside the function to generate unique per-call directory names. Every call site invoked it as `X="$(workspace_for ...)"` — command substitution always forks a subshell in bash, so the counter's increment never escaped back to the caller; every call saw the counter at its initial value and collided on the same destination path. `cp -R src dest` then nests `src` *inside* `dest` instead of overlaying it once `dest` already exists from a prior call, and the *second* call's leftover root-owned `.pytest_cache`/`__pycache__` (written by `pytest` running as root inside the container) then made the *third* call's `rm -rf` of that same reused path fail with permission errors. Fixed by switching to `mktemp -d` for guaranteed-unique names instead of hand-rolled shared state.
  2. `(cd "$ws" && make test >log 2>&1); rc=$?` — this is the *exact* class of bug Story 15.2's own review caught in `lib/dependency-install.sh` (`local rc=$?` after a bare `if...fi` with no `else`), just in a different shape: under `set -e`, a bare failing command aborts the script *before* the next line (`rc=$?`) ever runs, so a genuine `make test` failure would have killed the whole test suite silently instead of being recorded as a `FAIL`. Fixed with an explicit `if/else`-wrapped helper (`run_make_test`), same fix shape as Story 15.2's.
  3. The mid-flight-kill test originally did `(cd "$ws" && make test ... &)` — backgrounding *inside* the subshell's parens means the subshell forks the background job and exits immediately, so `$!` in the *outer* script never referred to anything real (`set -u` then correctly flagged it as unbound). Worse, the very first attempt at killing "the right process" used `kill -9 -- -$PGID` (process-group kill) on the assumption the backgrounded job got its own process group — it doesn't, in a non-interactive script (no job control), so this killed the *entire test script's own process group*, terminating itself mid-suite. Fixed by moving `&` outside the parens (so `$!` is meaningful) and killing only the specific PID, which is also the more realistic simulation anyway — a detached (`docker run -d`) container survives its parent process dying regardless.
- None of these three bugs were in the actual product code (`scripts/test-services.sh`, `Makefile`) — all three were in the test harness written to verify it. The product code's own manual verification (done before writing the automated suite) worked correctly on the first attempt for every scenario, including the SIGKILL case.

### Completion Notes List

- All 10 ACs implemented. AC 3's constraint (no Docker socket in the toolchain container) was verified, not assumed, before any code was written — see the story's own Dev Notes and Change Log.
- `scripts/test-services.sh` (~220 lines): `up`/`down` subcommands. Fail-fast validation (mutual exclusion with `docker_network`, unsupported entries) happens before anything is started. Stale-state detection at the top of `up` handles the SIGKILL case Make's own prerequisite/trap mechanism structurally cannot (a trap only helps once `test:`'s own recipe body has started running — a failure *during* the `_test-services-up` prerequisite, or a SIGKILL of the whole process tree, bypasses it entirely, which is exactly why `up` also self-heals from stale state on its own).
- Makefile: two new recursively-expanded flag variables (`DEVRAIL_TEST_SERVICES_NETWORK_FLAG`/`_ENV_FLAG`) folded into the existing shared `DOCKER_RUN` macro — verified empty/no-op for `lint`/`format`/`fix`/`security`/`scan`/`docs`/`changelog`/`plugins-update` by construction (nothing but `_test-services-up` ever creates the state files they check for) and by the full existing regression suite passing unchanged. `test:`'s recipe gained a `trap '...test-services.sh down' EXIT` wrapping its `$(DOCKER_RUN) make _test` call.
- `_test-services-host-bin` added alongside `_test-services-up`, mirroring `_devrail-host-bin`/`_extended-image`'s local-vs-extracted pattern (see debug log — this wasn't in the original task breakdown, added once the existing precedent was noticed).
- `.devrail.yml` `test.services` documented in `standards/devrail-yml-schema.md` (which already had a "not implemented" placeholder for this exact key from Story 15.2 — replaced with the real contract) and `standards/makefile-contract.md`.
- 3 new fixtures: `test-services-pg-redis` (used as a template, overwritten per-case by the test script), `test-services-mutex` (`docker_network` + `services` both set), `test-services-unsupported` (`mysql:8`).
- `tests/test-test-services.sh`: 19 assertions, all against real `make test` invocations with real Postgres/Redis containers — including genuinely killing a run mid-flight with `SIGKILL` and confirming both the orphan and the next run's self-healing, not just asserting the trap code looks right.
- CI wired: new "Test services smoke test" step, after Story 15.2's step (Story 15.3 needed no new CI step, so this is the next one in sequence).
- `CHANGELOG.md` `[Unreleased] → Added` and `STABILITY.md` (new row — this is a genuinely new capability, not a generalization of an existing one) updated.

**Verification (all green, against a fast Docker overlay of `ghcr.io/devrail-dev/dev-toolchain:1.12.0` + `lib/` + `scripts/` + `scripts/install-python.sh`):**

- `shellcheck`/`shfmt` across the full repo file set — clean
- `bash tests/test-test-services.sh` — **19 passed, 0 failed**, including the SIGKILL scenario
- `bash tests/test-project-discover.sh` (Stories 15.1/15.3) — 46/46, confirming the shared `DOCKER_RUN` macro change is a true no-op for every other target
- `bash tests/test-dependency-install.sh` (Story 15.2) — 12/12
- `bash tests/test-plugin-loader.sh` (Story 13.2) — all pass
- `bash tests/smoke-rails.sh` — all pass
- Manual verification before the automated suite existed: `docker network create` → `docker run -d` (Postgres) → `pg_isready` polling → real `psql`/`SELECT 1` from a sibling container by hostname → cleanup, and the same for Redis (`redis-cli ping` → real `SET`/`GET`) — proving the core mechanics work before any Makefile/script code was written around them
- `docker ps`/`docker network ls` confirmed empty of `devrail-test-*` resources after every successful run, after the mutex/unsupported-entry error paths (nothing started), and after the SIGKILL-then-rerun sequence

**Not run:** a full `docker build` of the real multi-stage Dockerfile (same rationale as Stories 15.1–15.3). `make check` on the dev-toolchain repo itself was not re-run (repo declares `languages: [bash]` only).

**No PR opened yet** — implementation complete and committed locally to `feat/52-test-services` (branched from `feat/53-go-rust-project-root-discovery`, itself not yet pushed/merged), pending user confirmation, same standing session default as every prior story in this epic.

### File List

**Implementation (dev-toolchain repo, branch `feat/52-test-services`, based on `feat/53-go-rust-project-root-discovery`):**

- `scripts/test-services.sh` — new
- `Makefile` — modified (two new `DEVRAIL_TEST_SERVICES_*` variables folded into `DOCKER_RUN`; new `_test-services-host-bin` and `_test-services-up` targets; `test:` recipe gained the prerequisite + cleanup trap)
- `tests/test-test-services.sh` — new
- `tests/fixtures/test-services-pg-redis/**` — new
- `tests/fixtures/test-services-mutex/**` — new
- `tests/fixtures/test-services-unsupported/**` — new
- `.github/workflows/ci.yml` — modified (new "Test services smoke test" step)
- `CHANGELOG.md` — modified (`[Unreleased] → Added` entry)
- `STABILITY.md` — modified (new component row)

**Story tracking + schema docs (OrgDocs/development-standards repo, branch `feat/15-4-create-story`):**

- `_bmad-output/implementation-artifacts/15-4-test-services-ephemeral-service-containers.md` — this file (status, all task checkboxes, Dev Agent Record, File List)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — modified (`15-4: ready-for-dev` → `review`)
- `_bmad-output/planning-artifacts/epics.md` — already updated during story creation
- `standards/devrail-yml-schema.md` — modified (`test.services` documented — replaces the "not implemented" placeholder from Story 15.2)
- `standards/makefile-contract.md` — modified (`### test` entry extended)

**Review-fix pass, dev-toolchain repo (same branch `feat/52-test-services`):**

- `Makefile` — further modified (new `DEVRAIL_TEST_SERVICES_PROBE`/`HAS_TEST_SERVICES_DECLARED` variables; guards added to `_test-services-host-bin` and `_test-services-up`; `test:`'s cleanup trap now checks for the extracted script's existence rather than assuming it)
- `scripts/test-services.sh` — further modified (duplicate-service-kind rejection in the validation loop)

**Review-fix pass, development-standards repo (same branch `feat/15-4-create-story`):**

- `standards/devrail-yml-schema.md` — further modified (duplicate-kind validation rule, credential rationale, concurrent-invocation known limitation)

## Change Log

| Date | Change |
|---|---|
| 2026-07-26 | Story created via the formal `create-story` workflow (auto-discovered as the last remaining `backlog` story in Epic 15). Unlike prior stories in this epic, the critical design question here was architectural (how to orchestrate sibling containers safely) rather than a claim to verify — investigated and confirmed the toolchain container has no Docker socket access (ruling out in-container orchestration), then designed and hand-verified a host-side orchestration approach (network create, service start, readiness wait, cross-container connectivity, cleanup) end-to-end for both Postgres and Redis before writing any AC. Scoped to Postgres/Redis only (matching the epic's own example, not a generic-image claim); `docker-compose.test.yml` autodetection explicitly deferred. Status: `ready-for-dev`. |
| 2026-07-27 | `dev-story` complete: implemented `scripts/test-services.sh` (up/down, stale-state self-healing, fail-fast validation) and wired it into the Makefile via a `_test-services-up`/`_test-services-host-bin` prerequisite pair (mirroring the existing `_extended-image`/`_devrail-host-bin` local-vs-extracted pattern) plus an `EXIT` trap on `test:` for guaranteed teardown. New `tests/test-test-services.sh` (19 assertions) found and fixed 3 bugs in the test harness itself (not the product code): a subshell-scoped counter that silently never incremented across `$(...)` calls, a bare `rc=$?` that `set -e` would have skipped on a real failure, and a `kill -9` on the wrong process group that took out the whole test script instead of just the simulated crashed container. All 10 ACs verified, including a genuine mid-flight `SIGKILL` of `make test` followed by confirming both the orphaned resources and the next run's self-healing. Full existing regression suite (project-discover, dependency-install, plugin-loader, smoke-rails) re-run and unaffected. Status: `review`. |
| 2026-07-27 | `code-review` complete: found and fixed 3 issues. (1) `_test-services-host-bin` unconditionally extracted the orchestrator script from the image on every consumer repo without local `scripts/`, even when `test.services` was never declared — unlike its sibling `_devrail-host-bin`, which guards on `HAS_PLUGINS_DECLARED`. Added the matching `HAS_TEST_SERVICES_DECLARED` guard (plus a matching guard on `_test-services-up`'s invocation and a defensive existence check in `test:`'s cleanup trap, since skipping extraction meant the extracted script might no longer exist for the trap to call). (2) Duplicate service kinds (e.g. two `postgres:<tag>` entries) weren't rejected — both containers would start, but the second's `DATABASE_URL` line would silently shadow the first's in the env file, leaving the first container running but unreachable for the whole test run. Added a dedup check to the validation loop, fails fast before anything starts. (3) The schema doc didn't explain that the fixed Postgres/Redis credentials are intentional (throwaway per-run network, nothing durable to protect) or that concurrent `make test` runs in the same checkout race on the shared `.devrail/test-services/` state path — documented both. All fixes re-verified against a live overlay image: full 19-assertion suite still green, plus two new manual checks (extraction now skipped end-to-end when no services declared; a duplicate-`postgres` config now fails fast with nothing started). Status: `review`. |

## Senior Developer Review (AI)

**Reviewer:** Matthew (review executed by Claude Sonnet 5 — same model that implemented the story; see caveat below)
**Date:** 2026-07-27
**Outcome:** Approve (after in-session fixes)

### Caveat

Same caveat as every prior story in this epic: this is the same model/session that wrote the implementation, not an independent second reviewer. To compensate, the review deliberately looked past the ACs (which the implementation already satisfies, per the dev-story verification) and instead diffed this story's own two host-side Makefile targets against their explicitly-named precedent (`_devrail-host-bin`/`_extended-image`, built for the plugin system) line by line, on the theory that "mirrors an existing pattern" claims are exactly where a real story-to-story regression is most likely to hide — a deviation from a pattern the commit message itself claims to be following is a stronger signal than a fresh read of unfamiliar code.

### Findings

**MEDIUM severity:**

- [x] **M1** — `_test-services-host-bin` did not carry the `HAS_PLUGINS_DECLARED`-equivalent guard that its own doc comment claims to mirror ("mirrors `_devrail-host-bin`'s pattern exactly"). `_devrail-host-bin` skips its `docker create`/`docker cp`/`docker rm` dance entirely when no plugins are declared; `_test-services-host-bin` ran that same dance unconditionally for every consumer repo without a local `scripts/test-services.sh` (i.e. every template-repo consumer, the majority use case) — even when `test.services` was never set. Confirmed by hand: a fresh checkout with no `test.services` key still extracted the script and its cache file before this fix. **Fix:** added `DEVRAIL_TEST_SERVICES_PROBE`/`HAS_TEST_SERVICES_DECLARED` (same shape as `DEVRAIL_PLUGIN_PROBE`/`HAS_PLUGINS_DECLARED`) and guarded both `_test-services-host-bin`'s extraction and `_test-services-up`'s invocation branch on it. This surfaced a second-order risk while fixing it: skipping extraction meant `test:`'s cleanup trap could try to invoke an extracted script that was never extracted, so the trap was also changed from an unconditional if/else to an existence check (`[ -f .devrail/host-bin/scripts/test-services.sh ]`) — robust regardless of why the file might be missing, not coupled to the new guard's exact logic. Verified: extraction confirmed skipped end-to-end (`.devrail/host-bin/scripts/` never created) for a no-services fixture, `make test` still passes, and the full 19-assertion suite (which exercises the services-declared path where extraction must still happen) stays green.
- [x] **M2** — `test.services` validation checked each entry was a *supported kind* but never checked for *duplicate kinds*. `services: [postgres:16, postgres:15]` would start two Postgres containers, but the `env` file (consumed via `docker run --env-file`, one `KEY=VALUE` per line, last occurrence wins for a repeated key) would end up with `DATABASE_URL` pointing only at the second container — the first would run for the entire test suite, fully billed in resources, completely unreachable via the one env var the feature exists to inject. Not a hypothetical: nothing in the schema said this was invalid, so a user declaring `services: [postgres:14, postgres:16]` while migrating a version pin, for instance, would hit this silently. **Fix:** added a dedup check to the existing full-list validation pass in `scripts/test-services.sh`, so a repeated kind fails fast (exit 2, clear message naming the kind) before any container starts — verified by hand against a fresh `postgres:16` + `postgres:15` fixture: exit 2, no container or network created.

**LOW severity:**

- [x] **L1** — Two things were true but undocumented: fixed Postgres/Redis credentials (`POSTGRES_PASSWORD=devrail`, no Redis auth) aren't configurable, and the state directory `.devrail/test-services/` isn't namespaced per invocation, so two `make test` runs started concurrently in the same checkout can race — the second run's stale-state self-healing could tear down the first run's still-active containers, not just a genuinely-abandoned one. Neither is a code defect (the credentials are fine precisely because the network is throwaway and unshared; the concurrency assumption matches the rest of the Makefile's existing host-side caching, none of which is lock-protected either), but a reader hitting either wasn't told it was expected. **Fix:** added both as explicit notes to `standards/devrail-yml-schema.md`'s "Ephemeral test services" section — the credential note as a design-rationale sentence, the concurrency note as a "Known limitation" paragraph naming the failure mode and the existing serialized-`make test`-per-checkout assumption it inherits.

### Discrepancy check (git vs. story File List)

No discrepancies in the original implementation commit (`1eba31a`). The review-fix pass's changes (`Makefile`, `scripts/test-services.sh` in dev-toolchain; `standards/devrail-yml-schema.md` in development-standards) are new, uncommitted-as-of-this-writing changes, reflected in the updated File List above and staged for a follow-up commit on the same branches (`feat/52-test-services`, `feat/15-4-create-story`) per this epic's established pattern.

### Action Items

All 3 findings resolved in this session — folded into the still-local `feat/52-test-services` (dev-toolchain) and `feat/15-4-create-story` (development-standards) branches, same pattern as Stories 15.1–15.3.

- [x] [AI-Review][MED] M1: add `HAS_TEST_SERVICES_DECLARED` guard to `_test-services-host-bin`/`_test-services-up`, harden `test:`'s cleanup trap against the now-possible skipped-extraction case [`Makefile` → fixed]
- [x] [AI-Review][MED] M2: reject duplicate `test.services` kinds during validation [`scripts/test-services.sh` → fixed]
- [x] [AI-Review][LOW] L1: document fixed-credential rationale and the concurrent-invocation known limitation [`standards/devrail-yml-schema.md` → fixed]
