---
title: "Go"
linkTitle: "Go"
weight: 30
description: "Go tooling standards: golangci-lint, gofumpt, govulncheck, and go test."
---

Go projects use golangci-lint for linting, gofumpt for formatting, govulncheck for security scanning, and go test for testing.

## Tools

| Category | Tool | Purpose |
|---|---|---|
| Linter | golangci-lint v2 | Meta-linter (bundles go vet, staticcheck, gosec, errcheck, etc.) |
| Formatter | gofumpt | Strict superset of gofmt |
| Security | govulncheck | Scans module dependencies for known vulnerabilities |
| Tests | go test | Built-in Go test runner |

All tools are pre-installed in the dev-toolchain container. Do not install them on the host.

## Configuration

### golangci-lint

Config file: `.golangci.yml` at repository root.

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

golangci-lint v2 uses a `version: "2"` key in the config file. It is a meta-linter that bundles dozens of linters. Do not install standalone versions of go vet, staticcheck, gosec, or errcheck.

### gofumpt

No config file required. gofumpt is a strict superset of `gofmt`. It enforces additional formatting rules (grouped imports, consistent spacing). Run with `gofumpt -w .` to apply fixes or `gofumpt -d .` to check.

### govulncheck

No config file required. Scans `go.sum` for known vulnerabilities in module dependencies. Requires the Go SDK at runtime because it uses `go/packages` internally.

## Makefile Targets

| Target | Command | Description |
|---|---|---|
| `make lint` | `golangci-lint run ./...` | Lint all Go files |
| `make format` | `gofumpt -d .` | Check formatting (diff mode) |
| `make security` | `govulncheck ./...` | Dependency vulnerability scanning (if `go.sum` exists) |
| `make test` | `go test ./...` | Run test suite (if `*_test.go` files exist) |

## Pre-Commit Hooks

### Local Hooks (run on every commit, under 30 seconds)

golangci-lint runs on every commit to catch lint and formatting issues:

```yaml
# .pre-commit-config.yaml -- Go hooks
repos:
  - repo: https://github.com/golangci/golangci-lint
    rev: v2.1.6
    hooks:
      - id: golangci-lint-full
```

### CI-Only (too slow for local hooks)

- `govulncheck ./...` -- dependency vulnerability scanning
- `go test ./...` -- full test suite

## Notes

- **golangci-lint v2 is the single linting tool.** It bundles go vet, staticcheck, gosec, errcheck, and dozens more. Do not install standalone versions of these linters.
- **gofumpt is a strict superset of gofmt.** All gofmt-valid code is gofumpt-valid, but gofumpt enforces additional style rules. Use gofumpt exclusively.
- **govulncheck requires the Go SDK at runtime.** Unlike other tools that are standalone binaries, govulncheck uses `go/packages` to analyze module dependencies. The Go SDK is included in the dev-toolchain container for this reason.
- **Go tools use `./...` patterns.** The `./...` pattern matches all packages in the module. This is the standard Go convention for recursive operations.
- **`go.sum` presence gates security scanning.** If no `go.sum` file exists, govulncheck is skipped because there are no module dependencies to scan.
- **All tools are pre-installed in the dev-toolchain container.** Do not install them on the host.
- For cross-cutting coding practices and git workflow standards that apply to all languages, see [Coding Practices](/docs/standards/practices/).
