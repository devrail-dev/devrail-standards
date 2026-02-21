# Ansible Standards

## Tools

| Concern | Tool | Version Strategy |
|---|---|---|
| Linter | ansible-lint | Latest in container |
| Tests | molecule | Latest in container |

## Configuration

### ansible-lint

Config file: `.ansible-lint` at repository root (YAML format, no extension).

Recommended `.ansible-lint`:

```yaml
profile: production

exclude_paths:
  - .cache/
  - .github/
  - .gitlab/

skip_list:
  - yaml[truthy]  # Allow 'yes'/'no' in Ansible-native contexts

warn_list:
  - experimental
```

Profiles (from least to most strict): `min`, `basic`, `moderate`, `safety`, `shared`, `production`. Use `production` for DevRail-managed projects.

### molecule

Config directory: `molecule/default/` alongside each role.

Recommended `molecule/default/molecule.yml`:

```yaml
driver:
  name: docker

platforms:
  - name: instance
    image: debian:bookworm-slim
    pre_build_image: true

provisioner:
  name: ansible

verifier:
  name: ansible
```

Molecule scenarios live alongside roles. Each role should have at least a `default` scenario.

## Makefile Targets

| Target | Command | Description |
|---|---|---|
| `_lint` | `ansible-lint` | Lint playbooks and roles |
| `_test` | `molecule test` | Run molecule test scenarios |

See [DEVELOPMENT.md](../DEVELOPMENT.md) for the full Makefile contract and two-layer delegation pattern.

## Pre-Commit Hooks

### Local Hooks (< 30 seconds)

These run on every commit via `pre-commit`:

```yaml
repos:
  - repo: https://github.com/ansible/ansible-lint
    rev: ""  # container manages version
    hooks:
      - id: ansible-lint
```

### CI-Only

These run via `make test` in CI pipelines. They are **not** configured as pre-commit hooks due to execution time:

- `molecule test` -- full role testing (provisions containers, runs converge, runs verify)

## Notes

- No dedicated formatter is enforced for Ansible. YAML formatting is handled by `.editorconfig` (indent size, line endings, trailing whitespace).
- `ansible-lint` enforces best practices for playbooks, roles, and task files. It covers naming conventions, deprecated syntax, and Ansible anti-patterns.
- `molecule` scenarios should test at minimum: converge (apply), idempotence (re-apply with zero changes), and verify (assertions).
- Role directory structure follows Ansible Galaxy conventions: `tasks/`, `handlers/`, `defaults/`, `vars/`, `templates/`, `files/`, `meta/`.
- All tools are pre-installed in the dev-toolchain container. Do not install them on the host.
