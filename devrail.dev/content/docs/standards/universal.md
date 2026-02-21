---
title: "Universal Security"
linkTitle: "Universal Security"
weight: 50
description: "Universal security tools that run for every project: trivy and gitleaks."
---

These tools run for every DevRail-managed project regardless of declared languages. They provide baseline vulnerability scanning and secret detection.

## Tools

| Category | Tool | Purpose |
|---|---|---|
| Vulnerability Scanning | trivy | Container image and filesystem vulnerability scanning |
| Secret Detection | gitleaks | Detect secrets in git history and staged changes |

All tools are pre-installed in the dev-toolchain container. Do not install them on the host.

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

```text
# .trivyignore -- suppress verified false positives only
# Include a justification comment for each suppressed CVE
CVE-2023-XXXXX
```

### gitleaks

Config file: `.gitleaks.toml` at repository root (optional, for custom rules or allowlists).

Recommended `.gitleaks.toml`:

```toml
# .gitleaks.toml -- gitleaks secret detection configuration
[allowlist]
  description = "Project-specific allowlist"
  paths = [
    '''\.gitleaks\.toml''',
  ]
```

gitleaks detects secrets (API keys, tokens, passwords) in git history and staged changes. Use the allowlist only for verified false positives.

## Makefile Targets

| Target | Command | Description |
|---|---|---|
| `make scan` | `trivy fs .` | Filesystem vulnerability scan |
| `make scan` | `trivy image <image>` | Container image vulnerability scan |
| `make scan` | `gitleaks detect --source .` | Secret detection in repository |

The `make scan` target is separate from `make security`. The `security` target runs language-specific scanners (bandit, tfsec, etc.), while `scan` runs universal scanners that apply to all projects.

## Pre-Commit Hooks

### Local Hooks (run on every commit, under 30 seconds)

gitleaks runs on every commit to catch secrets before they enter git history:

```yaml
# .pre-commit-config.yaml -- universal security hooks
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: ""  # container manages version
    hooks:
      - id: gitleaks
```

### CI-Only (too slow for local hooks)

- `trivy fs .` -- full filesystem vulnerability scanning
- `trivy image <image>` -- container image scanning (when applicable)

## Notes

- **`trivy` and `gitleaks` run as part of `make scan`**, which is separate from `make security`. The `security` target handles language-specific scanners, while `scan` handles universal scanners.
- **gitleaks runs both locally and in CI.** The local pre-commit hook catches secrets immediately; CI provides a final safety net.
- **Findings at any severity level cause a non-zero exit code.** Do not suppress findings without explicit justification in `.trivyignore` or `.gitleaks.toml` allowlist.
- **Both tools produce JSON output in CI** for artifact collection and reporting.
- **All tools are pre-installed in the dev-toolchain container.** Do not install them on the host.
