# Development Guide

This document is the canonical reference for developing the pre-commit-conventional-commits hook. All agent instruction files (CLAUDE.md, AGENTS.md, .cursorrules, .opencode/) point here.

---

<!-- devrail:critical-rules -->

## Critical Rules

These eight rules are non-negotiable. Every developer and every AI agent must follow them without exception.

1. **Run `make check` before completing any story or task.** Never mark work done without passing checks. This is the single gate for all linting, formatting, security, and test validation.

2. **Use conventional commits.** Every commit message follows the `type(scope): description` format. No exceptions. See the [Conventional Commits](#conventional-commits) section for types and scopes.

3. **Never install tools outside the container.** All linters, formatters, scanners, and test runners live inside `ghcr.io/devrail-dev/dev-toolchain:v1`. The Makefile delegates to Docker. Do not install tools on the host.

4. **Respect `.editorconfig`.** Never override formatting rules (indent style, line endings, trailing whitespace) without explicit instruction. The `.editorconfig` file in each repo is authoritative.

5. **Write idempotent scripts.** Every script must be safe to re-run. Check before acting: `command -v tool || install_tool`, `mkdir -p`, guard file writes with existence checks.

6. **Use the shared logging library.** No raw `echo` for status messages. Use `log_info`, `log_warn`, `log_error`, `log_debug`, and `die` from `lib/log.sh`.

7. **Never suppress failing checks.** When a lint, format, security, or test check fails, fix the underlying issue. Never comment out code, add suppression annotations (`# noqa`, `# nosec`, `#tfsec:ignore`, `// nolint`), disable rules, or mark CI jobs as allowed-to-fail to bypass a failing check. If a finding is a confirmed false positive, document the justification inline alongside the tool's designated suppression mechanism.

8. **Update documentation when changing behavior.** When a change affects public interfaces, configuration, CLI usage, or setup steps, update the relevant documentation (README, DEVELOPMENT.md, inline docs) in the same commit or PR. Do not leave documentation out of sync with code.

<!-- /devrail:critical-rules -->

<!-- devrail:commits -->

## Conventional Commits

All commits follow [Conventional Commits](https://www.conventionalcommits.org/):

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
| `python` | Python tooling, configs, or standards |
| `bash` | Bash tooling, configs, or standards |
| `terraform` | Terraform tooling, configs, or standards |
| `ansible` | Ansible tooling, configs, or standards |
| `ruby` | Ruby tooling, configs, or standards |
| `go` | Go tooling, configs, or standards |
| `javascript` | JavaScript/TypeScript tooling, configs, or standards |
| `container` | Dev-toolchain container image |
| `ci` | CI/CD pipeline configuration |
| `makefile` | Makefile targets and patterns |
| `standards` | DevRail standards documentation |

<!-- /devrail:commits -->

<!-- devrail:coding-practices -->

## Coding Practices

General software engineering standards that apply across all languages. For the full reference, see [`standards/coding-practices.md`](standards/coding-practices.md).

- **DRY, KISS, YAGNI** -- don't repeat yourself, keep it simple, build only what is needed now
- **Single responsibility** -- each function, class, or module does one thing
- **Fail fast** -- validate inputs at boundaries, return or raise immediately on invalid state
- **No swallowed exceptions** -- every error branch handles the error meaningfully or propagates it
- **Test behavior, not implementation** -- assert on outputs and side effects, follow the test pyramid (unit > integration > e2e)
- **New code must include tests** -- PRs that add logic without tests are incomplete
- **~50 line function guideline** -- split long functions into focused helpers
- **Pin dependency versions** -- commit lock files, update regularly, respond to security advisories promptly

<!-- /devrail:coding-practices -->

<!-- devrail:git-workflow -->

## Git Workflow

Git discipline and collaboration standards. For the full reference, see [`standards/git-workflow.md`](standards/git-workflow.md).

- **Never push directly to `main`** -- all changes reach the default branch through a pull/merge request
- **Branch naming** -- `type/short-description` (e.g., `feat/add-auth`, `fix/login-error`)
- **Minimum 1 approval required** before merging, no self-merge
- **Atomic commits** -- one logical change per commit, conventional commit format
- **No `--force-push` to shared branches** -- only force push your own feature branches
- **Squash-merge feature branches** for clean, linear history on `main`
- **No secrets in commits** -- enforced by gitleaks pre-commit hook and `make scan`
- **Branch protection on `main`** -- require PR, approvals, and CI pass

<!-- /devrail:git-workflow -->

<!-- devrail:release-versioning -->

## Release & Versioning

Release management and versioning discipline. For the full reference, see [`standards/release-versioning.md`](standards/release-versioning.md).

- **Semantic versioning** -- `MAJOR.MINOR.PATCH` with strict adherence after `v1.0.0`
- **Annotated tags only** -- `vX.Y.Z` format, tagged from `main`, never moved or deleted after push
- **Release process** -- review changelog, tag, push, create platform release with artifacts
- **Hotfixes** -- branch from tag, fix, merge to `main`, tag new patch release
- **Pre-release versions** -- `v1.0.0-rc.1`, `v1.0.0-beta.1` conventions for unstable releases
- **Libraries vs services** -- libraries follow semver strictly; services may use date-based versioning
- **Changelog** -- auto-generated from conventional commits, [Keep a Changelog](https://keepachangelog.com/) format

<!-- /devrail:release-versioning -->

<!-- devrail:ci-cd-pipelines -->

## CI/CD Pipelines

Continuous integration and deployment standards. For the full reference, see [`standards/ci-cd-pipelines.md`](standards/ci-cd-pipelines.md).

- **Standard stages** -- `lint → format → test → security → scan → build → deploy` (in order)
- **Stage contract** -- each CI stage calls a `make` target; identical behavior locally and in CI
- **Required jobs** -- lint, format, test, security, scan must pass before merge
- **Deployment gates** -- auto-deploy to staging on merge to `main`; manual approval for production
- **Pipeline types** -- library (test+publish), service (test+build+deploy), infrastructure (plan+apply)
- **Artifact management** -- release tags are immutable, pin toolchain versions, commit lock files
- **Performance** -- cache dependencies, parallelize independent stages, target < 10 min for PR checks

<!-- /devrail:ci-cd-pipelines -->

<!-- devrail:container-standards -->

## Container Standards

Container image build and runtime standards. For the full reference, see [`standards/container-standards.md`](standards/container-standards.md).

- **Pin base images** -- use specific tags or digests, never `latest`
- **Multi-stage builds** -- separate build dependencies from the runtime image
- **Layer ordering** -- least-changing layers first to maximize cache reuse
- **Non-root user** -- never run containers as root in production
- **No secrets in images** -- inject at runtime via env vars or mounted volumes
- **Image tagging** -- `vX.Y.Z` for releases, `sha-<short>` for CI builds, never overwrite release tags
- **Health checks** -- every service container exposes `/healthz` and `/readyz` endpoints
- **`.dockerignore` required** -- exclude `.git`, tests, docs, and build artifacts from the context

<!-- /devrail:container-standards -->

<!-- devrail:secrets-management -->

## Secrets Management

Standards for handling secrets and sensitive configuration. For the full reference, see [`standards/secrets-management.md`](standards/secrets-management.md).

- **Classify correctly** -- secrets vs sensitive config vs environment config vs application config
- **Never in source control** -- no API keys, passwords, or tokens in committed files (enforced by gitleaks)
- **Platform secrets** -- use GitHub/GitLab secrets or a dedicated manager (Vault, AWS SM, GCP SM)
- **`.env` gitignored, `.env.example` committed** -- document required variables with placeholders
- **`UPPER_SNAKE_CASE` naming** -- prefix by service or context to avoid collisions
- **Rotate on schedule** -- 90-day minimum for keys and credentials; immediately on exposure
- **Least privilege** -- no shared credentials, service accounts over personal, audit access

<!-- /devrail:secrets-management -->

<!-- devrail:api-cli-design -->

## API & CLI Design

Standards for designing APIs and CLIs. For the full reference, see [`standards/api-cli-design.md`](standards/api-cli-design.md).

- **Version APIs from day one** -- URL path (`/v1/`) preferred; never break clients without a version bump
- **JSON by default** -- consistent envelope, ISO 8601 timestamps, request IDs in every response
- **Structured errors** -- machine-readable `code`, human-readable `message`, detailed `fields`; correct HTTP status codes
- **CLI conventions** -- `--help` on every command, exit codes 0/1/2, JSON output for machines
- **Backward compatibility** -- additive changes are safe; removals require deprecation + version bump
- **OpenAPI for APIs** -- spec is the source of truth, kept in sync with code
- **Pagination and rate limiting** -- standard patterns for collection endpoints

<!-- /devrail:api-cli-design -->

<!-- devrail:monitoring-observability -->

## Monitoring & Observability

Runtime monitoring and observability standards. For the full reference, see [`standards/monitoring-observability.md`](standards/monitoring-observability.md).

- **Health endpoints** -- `/healthz` (liveness) and `/readyz` (readiness) for every service
- **Structured logging** -- JSON format, correlation IDs, log levels (`debug`, `info`, `warn`, `error`)
- **RED metrics** -- Rate, Errors, Duration for every service; Prometheus-style exposition
- **Alerting** -- alert on symptoms not causes, every alert links to a runbook, minimize noise
- **Dashboards** -- one per service minimum, golden signals visible at a glance
- **Never log PII** -- no secrets, tokens, emails, or government IDs in logs; redact if unavoidable

<!-- /devrail:monitoring-observability -->

<!-- devrail:incident-response -->

## Incident Response

Incident detection, response, and learning standards. For the full reference, see [`standards/incident-response.md`](standards/incident-response.md).

- **Severity levels** -- SEV1 (15 min response) through SEV4 (1 business day)
- **Incident workflow** -- detect → triage → mitigate → resolve → post-mortem
- **Communication** -- status page updates, stakeholder notification cadence per severity
- **Post-mortems** -- required for SEV1-SEV2, blameless, concrete action items with owners and due dates
- **Runbooks** -- required for every production service, stored alongside code, reviewed quarterly
- **On-call** -- defined rotation, clean handoffs, escalation path documented

<!-- /devrail:incident-response -->

<!-- devrail:data-handling -->

## Data Handling

Data classification, privacy, and compliance standards. For the full reference, see [`standards/data-handling.md`](standards/data-handling.md).

- **Data classification** -- public, internal, confidential, restricted; classify at collection time
- **PII handling** -- identify, minimize collection, encrypt at rest and in transit, document what is collected
- **Retention** -- define periods per data type, automate deletion, support right-to-deletion requests
- **Backups** -- regular, tested restores, encrypted, offsite copy, automated
- **Encryption** -- TLS 1.2+ in transit, AES-256 at rest, keys managed via secrets manager
- **Compliance awareness** -- GDPR, CCPA, HIPAA, PCI DSS as applicable; breach notification process documented
- **Never log PII** -- redact or mask if logging is unavoidable; route to restricted log stream

<!-- /devrail:data-handling -->

## Project Structure

```
pre-commit-conventional-commits/
├── .devrail.yml                 # DevRail project configuration
├── .editorconfig                # Editor formatting rules
├── .gitignore                   # Git ignore patterns
├── .pre-commit-config.yaml      # Pre-commit hooks for this repo
├── .pre-commit-hooks.yaml       # Hook manifest consumed by pre-commit
├── CHANGELOG.md                 # Auto-generated changelog
├── DEVELOPMENT.md               # This file
├── LICENSE                      # MIT license
├── Makefile                     # Build and check targets
├── README.md                    # User-facing documentation
├── setup.cfg                    # Python package configuration
├── setup.py                     # Python package setup
├── conventional_commits/        # Hook source code
│   ├── __init__.py
│   ├── check.py                 # Commit message validation logic
│   └── config.py                # Types, scopes, patterns, templates
└── tests/                       # Test suite
    ├── __init__.py
    ├── test_check.py            # Tests for check module
    └── test_config.py           # Tests for config module
```

## Development Setup

```bash
# Clone the repo
git clone https://github.com/devrail-dev/pre-commit-conventional-commits.git
cd pre-commit-conventional-commits

# Install pre-commit hooks
make install-hooks

# Run tests
make test

# Run all checks
make check
```

## Running Tests

```bash
# Via Makefile (recommended — runs inside container)
make test

# Direct pytest (development only)
pytest tests/ -v
```

## Makefile Targets

Run `make help` to see all available targets:

```
check                Run all checks (lint, format, test, security, docs)
docs                 Generate documentation
format               Run all formatters
help                 Show this help
install-hooks        Install pre-commit hooks
lint                 Run all linters
scan                 Run full scan (lint + security)
security             Run security scanners
test                 Run all tests
```

## Architecture

This repo provides a single pre-commit hook (`conventional-commits`) that validates commit messages against the DevRail conventional commit format. The hook:

1. Is consumed by every DevRail-compliant repo via `.pre-commit-config.yaml`
2. Runs as a `commit-msg` stage hook (not `pre-commit` stage)
3. Validates only the subject line (first line) of the commit message
4. Allows merge and revert commits to pass through
5. Provides clear, actionable error messages on rejection
