# CI/CD Pipelines

Continuous integration and continuous deployment standards for DevRail-managed repositories. These complement the [Makefile Contract](../DEVELOPMENT.md#makefile-contract) and [Release & Versioning](release-versioning.md) standards.

## Pipeline Structure

### Standard Stages

Every CI pipeline follows this stage order:

```
lint → format → test → security → scan → build → deploy
```

Not every project uses every stage. A library may stop after `scan`. An infrastructure repo may replace `build → deploy` with `plan → apply`. The order is fixed -- stages never run out of sequence.

### Stage-to-Target Mapping

Each CI stage maps directly to a `make` target. The same command runs locally and in CI:

| Stage | Make Target | Purpose |
|---|---|---|
| lint | `make lint` | Static analysis for all declared languages |
| format | `make format` | Formatting verification (fails if changes needed) |
| test | `make test` | Run all test suites |
| security | `make security` | Language-specific security scanners (bandit, tfsec, checkov) |
| scan | `make scan` | Universal scanners (trivy, gitleaks) |
| build | `make build` | Compile, package, or build container images |
| deploy | `make deploy` | Deploy to target environment |

### Stage Contract

1. **CI stages call `make` targets.** CI job scripts contain only `make <target>`, not raw tool invocations. This guarantees local-CI parity.
2. **Each stage is independent.** A stage must not assume artifacts from a previous stage unless explicitly configured as a dependency.
3. **Each stage produces JSON output.** Results are written to artifact files for downstream consumption and reporting.
4. **Exit codes are propagated.** No swallowed failures. A non-zero exit from any `make` target fails the CI job.

## Required vs Optional Jobs

### Required (Blocking)

These jobs must pass before a PR can be merged:

| Job | Rationale |
|---|---|
| `lint` | Catches bugs and enforces standards |
| `format` | Prevents formatting drift |
| `test` | Verifies correctness |
| `security` | Catches known vulnerabilities in code |
| `scan` | Catches secrets and container vulnerabilities |

### Optional (Advisory)

These jobs provide information but do not block merge:

| Job | Rationale |
|---|---|
| `docs` | Documentation generation may have soft warnings |
| Coverage reporting | Informational, not a gate |
| Performance benchmarks | Track trends, not hard gates |

Configure advisory jobs to allow failure in the CI platform (GitHub: `continue-on-error: true`, GitLab: `allow_failure: true`).

## Deployment Gates

### Environment Progression

```
feature branch → staging → production
```

| Environment | Trigger | Gate |
|---|---|---|
| **Staging** | Merge to `main` | Automatic (all CI checks pass) |
| **Production** | Manual trigger or tag push | Manual approval required |

### Rules

1. **Never auto-deploy to production** without explicit approval. Use manual gates (GitHub Environments, GitLab manual jobs) or tag-triggered releases.
2. **Staging mirrors production** as closely as possible. Same container images, same configuration structure, same infrastructure topology.
3. **Rollback must be possible.** Every deployment must support rolling back to the previous version. Document the rollback procedure.
4. **Deployment is idempotent.** Running the deploy target twice produces the same result. No duplicate resources, no orphaned state.

## Pipeline Variations

### Library Pipeline

Libraries are consumed by other projects, not deployed:

```
lint → format → test → security → scan → publish
```

- `publish` pushes to a package registry (PyPI, npm, etc.) only on tag
- No `deploy` stage
- Version is read from the tag, not from a file

### Service Pipeline

Services are built and deployed:

```
lint → format → test → security → scan → build → deploy
```

- `build` produces a container image or binary
- `deploy` pushes to staging automatically, production manually

### Infrastructure Pipeline

Terraform, Ansible, and other infrastructure-as-code:

```
lint → format → security → scan → plan → apply
```

- `plan` generates an execution plan and stores it as an artifact
- `apply` is always manual and requires approval
- No `test` stage in the standard pipeline (terratest runs separately if configured)

## Artifact Management

### Naming

Artifact names include enough context to identify their origin:

```
<project>-<stage>-<commit-sha>.json
```

Example: `dev-toolchain-lint-a1b2c3d.json`

### Retention

| Artifact Type | Retention |
|---|---|
| CI job logs | 30 days (platform default) |
| Test reports | 30 days |
| Build artifacts (images, binaries) | Indefinite for tagged releases, 7 days for branch builds |
| Terraform plans | Until applied or superseded |

### Reproducibility

1. **Pin the toolchain image.** CI jobs use `ghcr.io/devrail-dev/dev-toolchain:v1` (or a specific digest), never `latest`.
2. **Commit lock files.** Dependency resolution must be deterministic.
3. **Tag build artifacts.** Container images are tagged with `vX.Y.Z` for releases and `sha-<short>` for CI builds.

## Pipeline Performance

### Caching

- Cache dependency directories between runs (`pip cache`, `.terraform/plugins`, `node_modules`)
- Cache the dev-toolchain container image pull
- Invalidate caches when lock files change

### Parallelism

- Run independent stages in parallel where the platform supports it (e.g., `lint`, `format`, and `test` can run concurrently)
- Use matrix builds for multi-version testing (Python 3.11 + 3.12, Terraform 1.8 + 1.9)

### Fail-Fast

- **Default behavior:** Run all jobs and report all failures. This gives developers complete feedback in one pipeline run.
- **Fail-fast mode:** Available via `DEVRAIL_FAIL_FAST=1`. Stops the pipeline at the first failure. Useful during local development or for fast feedback loops.

### Pipeline Duration Targets

| Pipeline Type | Target Duration |
|---|---|
| PR validation (lint + format + test + security + scan) | < 10 minutes |
| Full build (including container image) | < 15 minutes |
| Deploy to staging | < 5 minutes |

These are targets, not hard limits. If a pipeline consistently exceeds its target, investigate and optimize.

## Branch-Specific Behavior

| Branch | Pipeline Behavior |
|---|---|
| Feature branches | Run lint, format, test, security, scan. No build or deploy. |
| `main` | Full pipeline including build. Auto-deploy to staging. |
| Tags (`vX.Y.Z`) | Full pipeline + release artifacts + publish/deploy to production (with approval). |

## Notes

- CI configuration files (`.github/workflows/*.yml`, `.gitlab-ci.yml`) are treated as code and follow the same review process as application code.
- Pipeline changes should be tested in a feature branch before merging to `main`.
- For platform-specific CI configuration details, refer to the template repos (`github-repo-template`, `gitlab-repo-template`).
