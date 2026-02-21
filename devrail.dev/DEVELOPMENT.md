# DevRail Development Standards

This document is the single canonical source of truth for all DevRail development standards applied to the devrail.dev documentation site.

---

<!-- devrail:critical-rules -->

## Critical Rules

These six rules are non-negotiable. Every developer and every AI agent must follow them without exception.

1. **Run `make check` before completing any story or task.** Never mark work done without passing checks. This is the single gate for all linting, formatting, security, and test validation.

2. **Use conventional commits.** Every commit message follows the `type(scope): description` format. No exceptions. See the [Conventional Commits](#conventional-commits) section for types and scopes.

3. **Never install tools outside the container.** All linters, formatters, scanners, and test runners live inside `ghcr.io/devrail-dev/dev-toolchain:v1`. The Makefile delegates to Docker. Do not install tools on the host.

4. **Respect `.editorconfig`.** Never override formatting rules (indent style, line endings, trailing whitespace) without explicit instruction. The `.editorconfig` file in each repo is authoritative.

5. **Write idempotent scripts.** Every script must be safe to re-run. Check before acting: `command -v tool || install_tool`, `mkdir -p`, guard file writes with existence checks.

6. **Use the shared logging library.** No raw `echo` for status messages. Use `log_info`, `log_warn`, `log_error`, `log_debug`, and `die` from `lib/log.sh`.

<!-- /devrail:critical-rules -->

<!-- devrail:makefile-contract -->

## Makefile Contract

The Makefile is the universal execution interface. Developers, CI pipelines, and AI agents all interact with the project through `make` targets.

### Hugo-Specific Targets

This is a documentation site, so it includes Hugo-specific targets alongside the standard DevRail contract:

| Target | Purpose |
|---|---|
| `make help` | List all targets with descriptions (default target) |
| `make build` | Build the Hugo site with `hugo --minify` |
| `make serve` | Start local development server with `hugo server` |
| `make check` | Run all DevRail checks |
| `make install-hooks` | Install pre-commit hooks |

<!-- /devrail:makefile-contract -->

<!-- devrail:commits -->

## Conventional Commits

All commits follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Format

```
type(scope): description
```

### Types

| Type | When to Use |
|---|---|
| `feat` | A new feature or capability |
| `fix` | A bug fix |
| `docs` | Documentation-only changes |
| `chore` | Maintenance tasks (dependencies, config) |
| `ci` | CI/CD pipeline changes |
| `refactor` | Code restructuring without behavior change |
| `test` | Adding or updating tests |

### Scopes

| Scope | Applies To |
|---|---|
| `docs` | Documentation content changes |
| `ci` | CI/CD pipeline configuration |
| `hugo` | Hugo configuration changes |

<!-- /devrail:commits -->

## Site Architecture

This site is built with [Hugo](https://gohugo.io/) using the [Docsy](https://www.docsy.dev/) theme. Content is written in Markdown and rendered to static HTML.

### Content Structure

```
content/
├── _index.md              -- Landing page
├── docs/
│   ├── _index.md          -- Documentation overview
│   ├── getting-started/   -- Quick start guides
│   ├── standards/         -- Per-language standards reference
│   ├── container/         -- Dev-toolchain container docs
│   ├── templates/         -- Project template docs
│   └── contributing/      -- Contribution guidelines
└── blog/                  -- Blog posts (future)
```

### Prerequisites

- [Hugo extended](https://gohugo.io/installation/) (for building the site)
- [Go](https://go.dev/dl/) >= 1.21 (for Hugo modules)
- [Docker](https://docs.docker.com/get-docker/) (for `make check`)
- [pre-commit](https://pre-commit.com/) (for git hooks)
