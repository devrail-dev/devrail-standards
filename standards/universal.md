# Universal Standards

These tools run for every DevRail-managed project regardless of declared languages.

## Tools

| Concern | Tool | Version Strategy |
|---|---|---|
| Vulnerability Scanning | trivy | Latest in container |
| Secret Detection | gitleaks | Latest in container |
| Changelog Generation | git-cliff | Latest in container |

## Configuration

### trivy

No config file required for default operation. trivy scans for known vulnerabilities in filesystem dependencies and container images.

Common invocation flags:

| Flag | Purpose |
|---|---|
| `--severity HIGH,CRITICAL` | Filter to high and critical findings only |
| `--exit-code 1` | Non-zero exit on findings (default behavior) |
| `--format json` | JSON output for CI pipelines |

To ignore specific findings, create a `.trivyignore` file at repository root:

```
# .trivyignore
CVE-2023-XXXXX
```

### gitleaks

Config file: `.gitleaks.toml` at repository root (optional, for custom rules or allowlists).

Recommended `.gitleaks.toml`:

```toml
[allowlist]
  description = "Project-specific allowlist"
  paths = [
    '''\.gitleaks\.toml''',
  ]
```

gitleaks detects secrets (API keys, tokens, passwords) in git history and staged changes. Use the allowlist only for verified false positives.

### git-cliff

Config file: `cliff.toml` at repository root (required for changelog generation).

git-cliff parses conventional commit messages and generates a structured `CHANGELOG.md` grouped by commit type (features, fixes, etc.). It requires a `cliff.toml` configuration file that defines the changelog format, commit groups, and output template.

The `cliff.toml` file is scaffolded automatically by `make init` when setting up a new DevRail project.

Common invocation flags:

| Flag | Purpose |
|---|---|
| `--output CHANGELOG.md` | Write changelog to file |
| `--tag <version>` | Generate changelog up to a specific tag |
| `--unreleased` | Only include unreleased changes |
| `--prepend CHANGELOG.md` | Prepend new entries to existing changelog |

## Makefile Targets

| Target | Command | Description |
|---|---|---|
| `_scan` | `trivy fs .` | Filesystem vulnerability scan |
| `_scan` | `trivy image <image>` | Container image vulnerability scan |
| `_scan` | `gitleaks detect --source .` | Secret detection in repository |
| `_changelog` | `git-cliff --output CHANGELOG.md` | Generate changelog from conventional commits |

See [DEVELOPMENT.md](../DEVELOPMENT.md) for the full Makefile contract and two-layer delegation pattern.

## Pre-Commit Hooks

### Local Hooks (< 30 seconds)

gitleaks runs on every commit to catch secrets before they enter git history:

```yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: ""  # container manages version
    hooks:
      - id: gitleaks
```

### CI-Only

These run via `make scan` in CI pipelines. They are **not** configured as pre-commit hooks due to execution time:

- `trivy fs .` -- full filesystem vulnerability scanning
- `trivy image <image>` -- container image scanning (when applicable)

## Notes

- `trivy` and `gitleaks` run as part of `make scan`, which is separate from `make security`. The `make security` target runs language-specific scanners (bandit, tfsec, etc.), while `make scan` runs universal scanners.
- `git-cliff` runs as part of `make changelog`, which is a standalone target invoked on-demand. It is not included in `make check`.
- `gitleaks` is one of the few tools that runs both locally (pre-commit) and in CI. The local hook catches secrets immediately; CI provides a final safety net.
- Findings at any severity level cause a non-zero exit code. Do not suppress findings without explicit justification in `.trivyignore` or `.gitleaks.toml` allowlist.
- Both trivy and gitleaks produce JSON output in CI for artifact collection and reporting.
- All tools are pre-installed in the dev-toolchain container. Do not install them on the host.
