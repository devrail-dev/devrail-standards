---
title: "Ruby"
linkTitle: "Ruby"
weight: 25
description: "Ruby and Rails tooling standards: rubocop, brakeman, bundler-audit, rspec, reek, and sorbet."
---

Ruby projects use rubocop for linting and formatting, brakeman and bundler-audit for security, rspec for testing, reek for code smell detection, and optionally sorbet for type checking.

## Tools

| Category | Tool | Purpose |
|---|---|---|
| Linter + Formatter | rubocop | Style enforcement and auto-correction |
| Linter (Rails) | rubocop-rails | Rails-specific rubocop rules |
| Linter (RSpec) | rubocop-rspec | RSpec-specific rubocop rules |
| Linter (Perf) | rubocop-performance | Performance-focused rubocop rules |
| Security | brakeman | Static analysis for Rails security vulnerabilities |
| Security | bundler-audit | Checks Gemfile.lock for known vulnerable gems |
| Tests | rspec | Ruby test framework |
| Code Smells | reek | Detects code smells (feature envy, long methods, etc.) |
| Type Check | sorbet | Gradual static type checker for Ruby |

All tools are pre-installed in the dev-toolchain container. Do not install them on the host.

## Configuration

### rubocop

Config file: `.rubocop.yml` at repository root.

```yaml
# .rubocop.yml -- DevRail Ruby style configuration
require:
  - rubocop-rails
  - rubocop-rspec
  - rubocop-performance

AllCops:
  TargetRubyVersion: 3.1
  NewCops: enable
  Exclude:
    - "db/schema.rb"
    - "bin/**/*"
    - "vendor/**/*"
    - "node_modules/**/*"

Style/Documentation:
  Enabled: false

Metrics/BlockLength:
  Exclude:
    - "spec/**/*"
    - "config/routes.rb"

Layout/LineLength:
  Max: 120
```

rubocop handles both linting and formatting. Do not use standardrb or prettier-ruby separately.

### reek

Config file: `.reek.yml` at repository root.

```yaml
# .reek.yml -- code smell detection configuration
exclude_paths:
  - vendor
  - db/schema.rb
  - bin

detectors:
  IrresponsibleModule:
    enabled: false
  UncommunicativeVariableName:
    accept:
      - e
      - i
      - k
      - v
```

### rspec

Config file: `.rspec` at repository root.

```text
--require spec_helper
--format documentation
--color
```

### sorbet

Config file: `sorbet/config` at repository root.

```text
--dir
.
--ignore=vendor/
--ignore=db/
--ignore=bin/
```

Sorbet uses typed signatures (`# typed: strict`, `# typed: true`, etc.) at the top of each file. Start with `# typed: false` and incrementally adopt stricter levels.

### brakeman

No config file required. Brakeman scans Rails applications for common security vulnerabilities (SQL injection, XSS, mass assignment, etc.). It only runs for Rails projects (detected by the presence of `config/application.rb`).

### bundler-audit

No config file required. Scans `Gemfile.lock` for known vulnerable gem versions. Run `bundler-audit update` periodically to refresh the advisory database.

## Makefile Targets

| Target | Command | Description |
|---|---|---|
| `make lint` | `rubocop .` | Lint all Ruby files |
| `make lint` | `reek .` | Detect code smells |
| `make format` | `rubocop --check --fail-level error .` | Check formatting (no changes) |
| `make security` | `brakeman -q` | Rails security scanning (Rails only) |
| `make security` | `bundler-audit check` | Dependency vulnerability scanning |
| `make test` | `rspec` | Run test suite (if `spec/` exists) |

## Pre-Commit Hooks

### Local Hooks (run on every commit, under 30 seconds)

rubocop runs on every commit to catch style and formatting issues:

```yaml
# .pre-commit-config.yaml -- Ruby hooks
repos:
  - repo: https://github.com/rubocop/rubocop
    rev: ""  # container manages version
    hooks:
      - id: rubocop
```

### CI-Only (too slow for local hooks)

- `brakeman -q` -- Rails security scanning
- `bundler-audit check` -- dependency vulnerability scanning
- `rspec` -- full test suite
- `reek .` -- code smell detection (when project is large)
- `sorbet` -- type checking (when project adopts typed signatures)

## Notes

- **rubocop is the single tool for both linting and formatting.** Do not use standardrb or prettier-ruby.
- **`rubocop-rails`, `rubocop-rspec`, and `rubocop-performance`** are rubocop extensions loaded via `require:` in `.rubocop.yml`. They are not standalone CLI tools.
- **`brakeman` only runs for Rails applications.** It is skipped if `config/application.rb` is not present.
- **`bundler-audit` only runs if `Gemfile.lock` exists.** It checks for known vulnerabilities in declared gem dependencies.
- **`reek` runs as part of `make lint`.** It detects code smells (feature envy, too-many-instance-variables, data clump, etc.).
- **`sorbet` is optional.** Projects can incrementally adopt it by adding `# typed:` sigils to Ruby files. The `sorbet-runtime` gem provides runtime type annotations.
- **All tools are pre-installed in the dev-toolchain container.** Do not install them on the host.
- **Rails rspec in CI:** The dev-toolchain container handles static analysis (rubocop, reek, brakeman, bundler-audit) but Rails integration tests typically need a database service (Postgres, MySQL). In CI, run a separate rspec job with the project's own `ruby` image, Bundler, and a database service. The DevRail `make _test` target handles rspec for simple cases; use a dedicated CI job when your tests require external services.
- For cross-cutting coding practices and git workflow standards that apply to all languages, see [Coding Practices](/docs/standards/practices/).
