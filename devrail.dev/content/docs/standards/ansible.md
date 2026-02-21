---
title: "Ansible Standards"
linkTitle: "Ansible"
weight: 40
description: "Ansible tooling standards: ansible-lint and molecule."
---

## Tools

| Category | Tool | Purpose |
|---|---|---|
| Linting | ansible-lint | Playbook and role linting with best practice enforcement |
| Testing | molecule | Role testing framework with Docker-based scenarios |

All tools are pre-installed in the dev-toolchain container. Do not install them on the host.

## Configuration

### ansible-lint

Config file: `.ansible-lint` at repository root (YAML format, no file extension).

Recommended `.ansible-lint`:

```yaml
# .ansible-lint -- DevRail Ansible linting configuration
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

Available profiles (from least to most strict): `min`, `basic`, `moderate`, `safety`, `shared`, `production`. DevRail uses `production` for maximum standards enforcement.

### molecule

Config directory: `molecule/default/` alongside each role.

Recommended `molecule/default/molecule.yml`:

```yaml
# molecule/default/molecule.yml -- DevRail Ansible role testing configuration
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

### Test Coverage Expectations

Molecule scenarios should test at minimum:

1. **Converge** -- apply the role to a fresh container
2. **Idempotence** -- re-apply the role and verify zero changes
3. **Verify** -- run assertions to confirm expected state

## Makefile Targets

| Target | Command | Description |
|---|---|---|
| `make lint` | `ansible-lint` | Lint playbooks and roles |
| `make test` | `molecule test` | Run molecule test scenarios |

All targets delegate to the dev-toolchain container via the two-layer Makefile delegation pattern.

## Pre-Commit Hooks

### Local Hooks (run on every commit, under 30 seconds)

```yaml
# .pre-commit-config.yaml -- Ansible hooks
repos:
  - repo: https://github.com/ansible/ansible-lint
    rev: ""  # container manages version
    hooks:
      - id: ansible-lint
```

### CI-Only (too slow for local hooks)

- `molecule test` -- full role testing (provisions containers, runs converge, runs verify)

## Notes

- **No dedicated formatter is enforced for Ansible.** YAML formatting is handled by `.editorconfig` (indent size, line endings, trailing whitespace).
- **`ansible-lint` enforces best practices** for playbooks, roles, and task files. It covers naming conventions, deprecated syntax, and Ansible anti-patterns.
- **Role directory structure follows Ansible Galaxy conventions:** `tasks/`, `handlers/`, `defaults/`, `vars/`, `templates/`, `files/`, `meta/`.
- **Molecule scenarios should be comprehensive.** At minimum, test converge, idempotence, and verify.
- **All tools are pre-installed in the dev-toolchain container.** Do not install them on the host.
