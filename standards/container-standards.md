# Container Standards

Standards for building, tagging, and running container images in DevRail-managed repositories. These complement the [CI/CD Pipelines](ci-cd-pipelines.md) build stage and the [Universal Security Tools](universal.md) scanning.

## Base Images

### Selection

1. **Use official or verified images.** Pull from Docker Hub official images, verified publishers, or your organization's private registry. Never use unverified community images for production workloads.
2. **Prefer minimal base images.** Use `alpine`, `distroless`, or `-slim` variants when the application supports them. Smaller images mean fewer vulnerabilities and faster pulls.
3. **Match the runtime to the application.** Use language-specific runtime images (`python:3.12-slim`, `node:20-alpine`) rather than installing runtimes on a generic base.

### Pinning

| Approach | When to Use | Example |
|---|---|---|
| **Pin to digest** | Production builds, security-critical images | `python@sha256:abc123...` |
| **Pin to specific tag** | General development | `python:3.12.3-slim-bookworm` |
| **Never use `latest`** | -- | `python:latest` is prohibited |

Pin base images to a specific version or digest. Unversioned tags (`latest`, `stable`) can change without notice and break reproducibility.

## Multi-Stage Builds

### Pattern

Use multi-stage builds to separate build dependencies from the runtime image:

```dockerfile
# Build stage
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

# Runtime stage
FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /app .
USER appuser
CMD ["python", "main.py"]
```

### Rules

1. **Build tools stay in the build stage.** Compilers, package managers, header files -- none of these belong in the runtime image.
2. **Copy only what is needed.** Use `COPY --from=builder` to bring over only application code and installed dependencies.
3. **The runtime image should not have `pip`, `npm`, `apt`, or equivalent.** If the application does not need them at runtime, do not include them.

## Layer Ordering

Order Dockerfile instructions from least-changing to most-changing:

```
1. Base image (FROM)
2. System packages (apt-get, apk)
3. Application dependencies (requirements.txt, package.json)
4. Application code (COPY . .)
5. Runtime configuration (CMD, ENTRYPOINT)
```

This maximizes cache reuse. Changing application code does not invalidate the dependency installation layer.

### Rules

1. **`COPY` dependency manifests before application code.** Copy `requirements.txt`, `package.json`, `go.sum` first, install dependencies, then copy the rest of the application.
2. **Combine `RUN` commands where logical.** Reduce layers by chaining related commands: `RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*`
3. **Clean up in the same layer.** Package manager caches (`/var/lib/apt/lists/*`, `pip cache`) must be removed in the same `RUN` instruction that creates them.

## Security

### Non-Root User

1. **Never run containers as root in production.** Create a dedicated user and switch to it:

   ```dockerfile
   RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser
   USER appuser
   ```

2. **Set `USER` after all `RUN` commands that require root** (package installation, directory creation).
3. **Verify with `docker run --rm <image> whoami`.** The output should not be `root`.

### No Secrets in Images

1. **Never use `ENV` or `ARG` for secrets.** These are visible in image history (`docker history`).
2. **Use BuildKit `--secret` mounts** for build-time secrets:

   ```dockerfile
   RUN --mount=type=secret,id=npmrc,target=/root/.npmrc npm install
   ```

3. **Inject runtime secrets via environment variables or mounted volumes.** The image itself contains no credentials.

### Scanning

1. **Scan images with `trivy`** as part of `make scan`. This is enforced in CI.
2. **Fix or accept findings before release.** Critical and high vulnerabilities must be addressed. Document accepted risks for lower severities.
3. **Rebuild images when base images receive security updates.** Monitor base image advisories and rebuild regularly.

## Image Tagging

### Tag Format

| Context | Tag Format | Example |
|---|---|---|
| Release | `vX.Y.Z` | `myapp:v1.2.0` |
| CI build | `sha-<short>` | `myapp:sha-a1b2c3d` |
| Branch build | `branch-<name>` | `myapp:branch-feat-auth` |

### Rules

1. **Never overwrite a release tag.** `v1.2.0` always points to the same image. If the image is defective, release `v1.2.1`.
2. **Never use `latest` for production deployments.** Use explicit version tags.
3. **`latest` may be updated as a convenience** for development, pointing to the most recent release. It is never the source of truth.
4. **Include the image digest in deployment manifests** when maximum reproducibility is required.

## Health Checks

### Dockerfile HEALTHCHECK

Include a `HEALTHCHECK` instruction for standalone containers:

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080/healthz || exit 1
```

### Orchestrator Probes

When running under Kubernetes or similar orchestrators, prefer orchestrator-level probes over `HEALTHCHECK`:

| Probe | Purpose | Endpoint |
|---|---|---|
| **Liveness** | Is the process alive? Restart if not. | `/healthz` |
| **Readiness** | Can the process serve traffic? Remove from load balancer if not. | `/readyz` |
| **Startup** | Has the process finished initializing? | `/healthz` with extended timeout |

### Rules

1. **Every service container exposes a health endpoint.** No exceptions.
2. **Health checks do not test external dependencies.** `/healthz` checks the process itself, not the database or upstream APIs. Use `/readyz` for dependency checks.
3. **Health checks are fast.** Target < 100ms response time. No heavy computation or I/O.

## .dockerignore

### Requirements

Every project with a Dockerfile must have a `.dockerignore` file. This prevents unnecessary files from entering the build context.

### Minimum Exclusions

```
.git
.gitignore
.env
.env.*
*.md
LICENSE
Makefile
docker-compose*.yml
.github/
.gitlab-ci.yml
tests/
docs/
__pycache__/
*.pyc
.terraform/
*.tfstate
node_modules/
.venv/
```

### Rules

1. **Mirror `.gitignore` patterns** and add build-specific exclusions.
2. **Exclude test and documentation directories** unless the application needs them at runtime.
3. **Exclude CI configuration files.** `.github/`, `.gitlab-ci.yml`, and similar files are not needed in the image.

## Notes

- The `ghcr.io/devrail-dev/dev-toolchain:v1` image follows all of these standards and serves as a reference implementation.
- For container orchestration standards (Kubernetes manifests, Helm charts, docker-compose), refer to the deployment-specific documentation for your project.
- Container builds should be reproducible. Given the same source code, lock files, and base image digest, the build should produce a functionally identical image.
