---
title: "Terraform Standards"
linkTitle: "Terraform"
weight: 30
description: "Terraform tooling standards: tflint, terraform fmt, tfsec, checkov, terratest, and terraform-docs."
---

## Tools

| Category | Tool | Purpose |
|---|---|---|
| Linting | tflint | Terraform-specific linting rules |
| Formatting | terraform fmt | Canonical HCL formatting |
| Security | tfsec | Terraform-focused security scanning |
| Security | checkov | Policy-as-code scanning |
| Testing | terratest | Go-based infrastructure testing |
| Documentation | terraform-docs | Auto-generate module documentation |

All tools are pre-installed in the dev-toolchain container. Do not install them on the host.

## Configuration

### tflint

Config file: `.tflint.hcl` at repository root.

Recommended `.tflint.hcl`:

```hcl
# .tflint.hcl -- DevRail Terraform linting configuration
config {
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# Add provider-specific plugins as needed:
# plugin "aws" {
#   enabled = true
#   version = "0.30.0"
#   source  = "github.com/terraform-linters/tflint-ruleset-aws"
# }
```

### terraform fmt

No config file. Built into the Terraform CLI. Enforces the canonical HCL formatting style.

```bash
# Check formatting (exits non-zero if files need formatting)
terraform fmt -check -recursive

# Apply formatting
terraform fmt -recursive
```

### tfsec

No config file required for default operation. To suppress specific findings, use inline comments:

```hcl
# Suppress a specific tfsec finding with justification
resource "aws_s3_bucket" "example" {
  #tfsec:ignore:aws-s3-enable-bucket-logging
  bucket = "my-bucket"
}
```

### checkov

No config file required for default operation. To skip specific checks, use inline comments:

```hcl
# Suppress a specific checkov finding with justification
resource "aws_s3_bucket" "example" {
  #checkov:skip=CKV_AWS_18:Logging not required for this bucket
  bucket = "my-bucket"
}
```

### terratest

Go-based infrastructure tests in the `tests/` directory. Test files follow Go conventions (`*_test.go`).

```go
// tests/terraform_module_test.go -- example terratest file
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
)

func TestTerraformModule(t *testing.T) {
    // Configure Terraform options
    opts := &terraform.Options{
        TerraformDir: "../",
    }

    // Clean up resources after test
    defer terraform.Destroy(t, opts)

    // Apply Terraform configuration
    terraform.InitAndApply(t, opts)
}
```

The `tests/` directory must contain a `go.mod` file for the test module.

### terraform-docs

No config file required for default operation. Generates markdown documentation from Terraform module inputs, outputs, and descriptions.

Place markers in your `README.md` where documentation should be injected:

```markdown
<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
```

Then run:

```bash
# Generate module documentation and inject into README.md
terraform-docs markdown table . > README.md
```

## Makefile Targets

| Target | Command | Description |
|---|---|---|
| `make lint` | `tflint --recursive` | Lint all Terraform configurations |
| `make format` | `terraform fmt -check -recursive` | Check formatting (no changes) |
| `make security` | `tfsec .` | Security scanning for Terraform |
| `make security` | `checkov -d .` | Policy-as-code scanning |
| `make test` | `cd tests && go test -v -timeout 30m` | Run terratest suite |
| `make docs` | `terraform-docs markdown table .` | Generate module documentation |

All targets delegate to the dev-toolchain container via the two-layer Makefile delegation pattern.

## Pre-Commit Hooks

### Local Hooks (run on every commit, under 30 seconds)

```yaml
# .pre-commit-config.yaml -- Terraform hooks
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: ""  # container manages version
    hooks:
      - id: terraform_fmt
      - id: terraform_tflint
```

### CI-Only (too slow for local hooks)

- `tfsec .` -- security scanning
- `checkov -d .` -- policy-as-code scanning
- `cd tests && go test -v -timeout 30m` -- terratest suite
- `terraform-docs markdown table .` -- documentation generation

## Notes

- **`terraform fmt` is the only accepted formatter.** Do not use third-party HCL formatters.
- **Both `tfsec` and `checkov` run as part of `make security`.** They are complementary: tfsec focuses on Terraform-specific misconfigurations, checkov applies broader policy-as-code rules.
- **`terraform-docs` runs as part of `make docs`.** Place `<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->` markers in your `README.md`.
- **`terratest` tests are written in Go.** The `tests/` directory must contain a `go.mod` file.
- **All tools are pre-installed in the dev-toolchain container.** Do not install them on the host.
