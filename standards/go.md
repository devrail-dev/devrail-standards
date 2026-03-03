# Go Standards

## Tools

| Concern | Tool | Version Strategy |
|---|---|---|
| Linter | golangci-lint v2 | Latest in container |
| Formatter | gofumpt | Latest in container |
| Security | govulncheck | Latest in container |
| Tests | go test | Bundled with Go SDK |

golangci-lint v2 is a meta-linter that bundles go vet, staticcheck, gosec, errcheck, and many others. Standalone gosec is not needed.

## Configuration

### golangci-lint

Config file: `.golangci.yml` at repository root.

Recommended `.golangci.yml`:

```yaml
# .golangci.yml -- DevRail Go lint configuration
version: "2"

linters:
  enable:
    - errcheck
    - govet
    - staticcheck
    - gosec
    - ineffassign
    - unused
    - gocritic
    - gofumpt
    - misspell
    - revive

issues:
  exclude-dirs:
    - vendor
    - node_modules
```

golangci-lint v2 uses a `version: "2"` key in the config file. Linters not listed under `enable` use the tool's defaults.

### gofumpt

No config file required. gofumpt is a strict superset of `gofmt`. It enforces additional formatting rules (grouped imports, consistent spacing). Run with `gofumpt -w .` to apply fixes or `gofumpt -d .` to check.

### govulncheck

No config file required. Scans `go.sum` for known vulnerabilities in module dependencies. Requires the Go SDK at runtime because it uses `go/packages` internally.

## Makefile Targets

| Target | Command | Description |
|---|---|---|
| `_lint` | `golangci-lint run ./...` | Lint all Go files (if `*.go` files exist) |
| `_format` | `gofumpt -d .` | Check formatting (diff mode, non-zero on unformatted) |
| `_format` (fix) | `gofumpt -w .` | Apply formatting fixes |
| `_security` | `govulncheck ./...` | Dependency vulnerability scanning (if `go.sum` exists) |
| `_test` | `go test ./...` | Run test suite (if `*_test.go` files exist) |

See [DEVELOPMENT.md](../DEVELOPMENT.md) for the full Makefile contract and two-layer delegation pattern.

## Pre-Commit Hooks

### Local Hooks (< 30 seconds)

golangci-lint runs on every commit to catch lint and formatting issues:

```yaml
repos:
  - repo: https://github.com/golangci/golangci-lint
    rev: v2.1.6
    hooks:
      - id: golangci-lint-full
```

### CI-Only

These run via `make security` and `make test` in CI pipelines. They are **not** configured as pre-commit hooks due to execution time:

- `govulncheck ./...` -- dependency vulnerability scanning
- `go test ./...` -- full test suite

## Notes

- **golangci-lint v2 is the single linting tool.** It bundles go vet, staticcheck, gosec, errcheck, and dozens more. Do not install standalone versions of these linters.
- **gofumpt is a strict superset of gofmt.** All gofmt-valid code is gofumpt-valid, but gofumpt enforces additional style rules. Use gofumpt exclusively.
- **govulncheck requires the Go SDK at runtime.** Unlike other tools that are standalone binaries, govulncheck uses `go/packages` to analyze module dependencies. The Go SDK is included in the dev-toolchain container for this reason.
- **Go tools use `./...` patterns.** The `./...` pattern matches all packages in the module. This is the standard Go convention for recursive operations.
- **`go.sum` presence gates security scanning.** If no `go.sum` file exists, govulncheck is skipped because there are no module dependencies to scan.
- **All tools are pre-installed in the dev-toolchain container.** Do not install them on the host.
- For cross-cutting practices (DRY, idempotency, error handling, testing, naming) and git workflow (branching, code review, conventional commits), see [Coding Practices](coding-practices.md) and [Git Workflow](git-workflow.md).
