# pre-commit-conventional-commits

A [pre-commit](https://pre-commit.com/) hook that enforces [Conventional Commits](https://www.conventionalcommits.org/) with DevRail-specific types and scopes.

[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://github.com/pre-commit/pre-commit)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Quick Start

1. Add to your `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/devrail-dev/pre-commit-conventional-commits
    rev: v1.0.0
    hooks:
      - id: conventional-commits
```

2. Install the hooks:

```bash
make install-hooks
```

3. Commit with the correct format:

```
type(scope): description
```

## Usage

### Commit Format

```
type(scope): description
```

### Valid Types

| Type | When to Use |
|---|---|
| `feat` | A new feature or capability |
| `fix` | A bug fix |
| `docs` | Documentation-only changes |
| `chore` | Maintenance tasks (dependencies, config) |
| `ci` | CI/CD pipeline changes |
| `refactor` | Code restructuring without behavior change |
| `test` | Adding or updating tests |

### Valid Scopes

| Scope | Applies To |
|---|---|
| `python` | Python tooling, configs, or standards |
| `terraform` | Terraform tooling, configs, or standards |
| `bash` | Bash tooling, configs, or standards |
| `ansible` | Ansible tooling, configs, or standards |
| `container` | Dev-toolchain container image |
| `ci` | CI/CD pipeline configuration |
| `makefile` | Makefile targets and patterns |
| `standards` | DevRail standards documentation |

### Examples

```
feat(python): add ruff configuration for type checking
fix(ci): correct Docker image reference in build workflow
docs(standards): update .devrail.yml schema with container overrides
chore(makefile): update dev-toolchain image tag to v1.2.0
ci(container): add weekly rebuild schedule
refactor(bash): extract common logging to shared library
test(terraform): add terratest validation for module outputs
```

### Rules

- `type` is required and must be from the valid types list
- `scope` is required and must be from the valid scopes list
- Colon and space after the closing parenthesis are required
- `description` must be non-empty and start with a lowercase letter
- No period at the end of the description
- Merge commits (`Merge ...`) and revert commits (`Revert ...`) are allowed

## Configuration

This hook requires no configuration. Types and scopes are enforced globally per DevRail standards.

## Contributing

See [DEVELOPMENT.md](DEVELOPMENT.md) for development setup and contribution guidelines.

To add a new language ecosystem to DevRail, see the [Contributing to DevRail](https://github.com/devrail-dev/devrail-standards/blob/main/standards/contributing.md) guide.

## License

[MIT](LICENSE)
