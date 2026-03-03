# Terraform Standards

## Tools

| Concern | Tool | Version Strategy |
|---|---|---|
| Linter | tflint | Latest in container |
| Formatter | terraform fmt | Latest in container |
| Security | tfsec | Latest in container |
| Security | checkov | Latest in container |
| Tests | terratest | Latest in container |
| Docs | terraform-docs | Latest in container |

## Configuration

### tflint

Config file: `.tflint.hcl` at repository root.

Recommended `.tflint.hcl`:

```hcl
config {
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}
```

Add provider-specific plugins as needed (e.g., `plugin "aws"` for AWS resources).

### terraform fmt

No config file. Built into the Terraform CLI. Enforces the canonical HCL formatting style.

### tfsec

No config file required for default operation. To suppress specific findings, use inline comments:

```hcl
resource "aws_s3_bucket" "example" {
  #tfsec:ignore:aws-s3-enable-bucket-logging
  bucket = "my-bucket"
}
```

### checkov

No config file required for default operation. To skip specific checks, use the `--skip-check` flag or inline comments:

```hcl
resource "aws_s3_bucket" "example" {
  #checkov:skip=CKV_AWS_18:Logging not required for this bucket
  bucket = "my-bucket"
}
```

### terratest

Go-based infrastructure tests in the `tests/` directory. Test files follow Go conventions (`*_test.go`).

Example test structure:

```go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
)

func TestTerraformModule(t *testing.T) {
    opts := &terraform.Options{
        TerraformDir: "../",
    }
    defer terraform.Destroy(t, opts)
    terraform.InitAndApply(t, opts)
}
```

### terraform-docs

No config file required for default operation. Generates markdown documentation from Terraform module inputs, outputs, and descriptions.

Output is injected between markers in `README.md`:

```markdown
<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
```

## Makefile Targets

| Target | Command | Description |
|---|---|---|
| `_lint` | `tflint --recursive` | Lint all Terraform configurations |
| `_format` | `terraform fmt -check -recursive` | Check formatting (no changes) |
| `_format` (fix) | `terraform fmt -recursive` | Apply formatting fixes |
| `_security` | `tfsec .` | Security scanning for Terraform |
| `_security` | `checkov -d .` | Policy-as-code scanning |
| `_test` | `cd tests && go test -v -timeout 30m` | Run terratest suite |
| `_docs` | `terraform-docs markdown table . > README.md` | Generate module documentation |

See [DEVELOPMENT.md](../DEVELOPMENT.md) for the full Makefile contract and two-layer delegation pattern.

## Pre-Commit Hooks

### Local Hooks (< 30 seconds)

These run on every commit via `pre-commit`:

```yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: ""  # container manages version
    hooks:
      - id: terraform_fmt
      - id: terraform_tflint
```

### CI-Only

These run via `make security`, `make test`, and `make docs` in CI pipelines. They are **not** configured as pre-commit hooks due to execution time:

- `tfsec .` -- security scanning
- `checkov -d .` -- policy-as-code scanning
- `cd tests && go test -v -timeout 30m` -- terratest suite
- `terraform-docs markdown table .` -- documentation generation

## Notes

- `terraform fmt` is the only accepted formatter. Do not use third-party HCL formatters.
- Both `tfsec` and `checkov` run as part of `make security`. They are complementary: tfsec focuses on Terraform-specific misconfigurations, checkov applies broader policy-as-code rules.
- `terraform-docs` runs as part of `make docs`. It auto-generates module documentation from variable and output blocks. Place `<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->` markers in your `README.md`.
- `terratest` tests are written in Go. The `tests/` directory must contain a `go.mod` file.
- All tools are pre-installed in the dev-toolchain container. Do not install them on the host.
- For cross-cutting practices (DRY, idempotency, error handling, testing, naming) and git workflow (branching, code review, conventional commits), see [Coding Practices](coding-practices.md) and [Git Workflow](git-workflow.md).
