# Story 11.3: Distribute and Document `devrail init`

Status: done

## Story

As a developer,
I want to install `devrail init` easily and have clear documentation,
so that I can adopt DevRail in my project without reading the full standards first.

## Acceptance Criteria

1. `curl -fsSL https://devrail.dev/init.sh | bash` downloads and runs `devrail init`
2. Installation instructions are documented on devrail.dev
3. The existing getting-started guides are updated to reference `devrail init` as the primary adoption path
4. The devrail.dev Getting Started index page leads with `devrail init` as the entry point
5. CLI reference documentation exists for all `devrail init` options
6. `make check` passes on all updated repos

## Tasks / Subtasks

- [x] Task 1: Set up curl-pipe-bash distribution via devrail.dev (AC: 1)
  - [x] 1.1 Add `static/_redirects` file to `devrail.dev` Hugo site with redirect: `/init.sh` → `https://raw.githubusercontent.com/devrail-dev/dev-toolchain/main/scripts/devrail-init.sh 302`
  - [x] 1.2 Deploy and verify `curl -fsSL https://devrail.dev/init.sh | bash -- --help` works
  - [x] 1.3 Test in a fresh temp directory: `curl -fsSL https://devrail.dev/init.sh | bash -- --all --languages python --ci github --yes`

- [x] Task 2: Update existing documentation on devrail.dev (AC: 2, 3, 4, 5)
  - [x] 2.1 Update `content/docs/getting-started/_index.md` — lead with `devrail init` one-liner, reframe template/manual paths as alternatives
  - [x] 2.2 Update `content/docs/getting-started/new-project.md` — add `devrail init` section as the recommended path before template instructions
  - [x] 2.3 Update `content/docs/getting-started/retrofit.md` — replace manual file-copying steps with `devrail init` commands, keep manual steps as fallback
  - [x] 2.4 Create `content/docs/getting-started/cli-reference.md` — document all CLI options (`--languages`, `--ci`, `--all`, `--agents-only`, `--yes`, `--force`, `--dry-run`, `--version`), 4-layer adoption model, `.devrail.yml` configuration, conflict resolution behavior

- [x] Task 3: Validate end-to-end (AC: 6)
  - [x] 3.1 Greenfield test: `mktemp -d`, `git init`, `curl | bash -- --all --languages python --ci github --yes`, then `docker run ... make check` — verify all files created and checks pass
  - [x] 3.2 Retrofit test: clone an existing repo, run `devrail init --all --languages <lang> --ci <platform> --yes`, verify Makefile backup, .gitignore append, no file conflicts
  - [x] 3.3 Run `make check` on the devrail.dev repo to validate documentation changes

## Dev Notes

- Story 11.2 is done (PR #11 merged on dev-toolchain, 16/16 bats tests pass)
- The script is 1107 lines of POSIX-compatible bash at `dev-toolchain/scripts/devrail-init.sh`
- Script implements 4-layer progressive adoption: Layer 1 (agent files), Layer 2 (pre-commit), Layer 3 (Makefile + container), Layer 4 (CI pipelines)
- CLI flags: `--languages`, `--ci`, `--all`, `--agents-only`, `--yes`, `--force`, `--dry-run`, `--version`
- Small files embedded as heredocs; Makefile and DEVELOPMENT.md downloaded at runtime from `raw.githubusercontent.com/devrail-dev/github-repo-template/main/`
- The script header already references `curl -fsSL https://devrail.dev/init.sh | bash` — this URL doesn't work yet (primary deliverable of this story)

### Distribution Mechanism

Cloudflare Pages (which hosts devrail.dev) supports a `_redirects` file in the site root. Hugo serves static files from the `static/` directory. Add `static/_redirects` to redirect `/init.sh` to the raw GitHub script URL. This keeps a single source of truth (the script in dev-toolchain) without manual sync.

### Devrail.dev Site Context

- Hugo site with Docsy theme, repo at `github.com/devrail-dev/devrail.dev`
- Deploys via GitHub Actions to Cloudflare Pages
- Hugo URL pattern: `/:year/:month/:title/` (not filename-based) — important for blog post links
- PRs required for changes; merge triggers deploy
- Org secrets: `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`

### Existing Documentation Files to Update

- `content/docs/getting-started/_index.md` — main entry point (prerequisites, path selection)
- `content/docs/getting-started/new-project.md` — template-based project creation
- `content/docs/getting-started/retrofit.md` — adding DevRail to existing repos
- `content/docs/getting-started/agents.md` — AI agent setup (no changes needed — agents-only is already a path)
- `content/docs/getting-started/badge.md` — compliance badge (no changes needed)

### References

- [Source: dev-toolchain/scripts/devrail-init.sh] — the script to distribute (PR #11, merged)
- [Source: dev-toolchain/tests/test-devrail-init.sh] — 16 bats tests (all passing)
- [Source: devrail.dev/content/docs/getting-started/] — existing docs to update
- [Source: _bmad-output/planning-artifacts/devrail-init-design.md] — CLI design specification

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6

### Debug Log References

- `curl -fsSL https://devrail.dev/init.sh | bash -s -- --help` — returns full usage text
- Greenfield test: 19 files created, `make _check` passes (5 pass, 1 skip for tests)
- Retrofit test: existing Makefile skipped, .gitignore appended with marker, GitLab CI generated
- `make check` passes on devrail.dev repo

### Completion Notes List

- `static/_redirects` uses Cloudflare Pages 302 redirect to raw.githubusercontent.com — single source of truth, no manual sync
- Getting Started index now leads with `curl -fsSL https://devrail.dev/init.sh | bash` one-liner
- New Project page recommends `devrail init` first, templates as alternative
- Retrofit page recommends `devrail init` first, manual curl commands as fallback
- CLI Reference page covers all options, 4 adoption layers, conflict resolution, examples
- PR: https://github.com/devrail-dev/devrail.dev/pull/15

### File List

- `devrail.dev/static/_redirects` — new (Cloudflare Pages redirect for /init.sh)
- `devrail.dev/content/docs/getting-started/_index.md` — modified (lead with devrail init)
- `devrail.dev/content/docs/getting-started/new-project.md` — modified (add devrail init section)
- `devrail.dev/content/docs/getting-started/retrofit.md` — modified (replace manual steps with devrail init)
- `devrail.dev/content/docs/getting-started/cli-reference.md` — new (CLI reference page)
