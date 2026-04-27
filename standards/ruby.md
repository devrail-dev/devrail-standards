# Ruby Standards

## Tools

| Concern | Tool | Version Strategy |
|---|---|---|
| Linter | rubocop | Latest in container |
| Linter | rubocop-rails | Latest in container |
| Linter | rubocop-rspec | Latest in container |
| Linter | rubocop-performance | Latest in container |
| Formatter | rubocop | Latest in container |
| Security | brakeman | Latest in container |
| Security | bundler-audit | Latest in container |
| Tests | rspec | Latest in container |
| Code Smells | reek | Latest in container |
| Type Check | sorbet | Latest in container |

## Configuration

### rubocop

Config file: `.rubocop.yml` at repository root.

Recommended `.rubocop.yml`:

```yaml
require:
  - rubocop-rails
  - rubocop-rspec
  - rubocop-performance

AllCops:
  TargetRubyVersion: 3.4
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

Recommended `.reek.yml`:

```yaml
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

Recommended `.rspec`:

```text
--require spec_helper
--format documentation
--color
```

### sorbet

Config file: `sorbet/config` at repository root.

Recommended `sorbet/config`:

```text
--dir
.
--ignore=vendor/
--ignore=db/
--ignore=bin/
```

Sorbet uses typed signatures (`# typed: strict`, `# typed: true`, etc.) at the top of each file. Start with `# typed: false` and incrementally adopt.

### brakeman

No config file required. Brakeman scans Rails applications for common security vulnerabilities. It only applies to Rails projects (detected by `config/application.rb`).

### bundler-audit

No config file required. Scans `Gemfile.lock` for known vulnerable gem versions. Run `bundler-audit update` periodically to refresh the advisory database.

## Makefile Targets

| Target | Command | Description |
|---|---|---|
| `_lint` | `rubocop .` | Lint all Ruby files |
| `_lint` | `reek .` | Detect code smells |
| `_format` | `rubocop --check --fail-level error .` | Check formatting (no changes) |
| `_format` (fix) | `rubocop -a .` | Apply safe auto-corrections |
| `_security` | `brakeman -q` | Rails security scanning (Rails only) |
| `_security` | `bundler-audit check` | Dependency vulnerability scanning |
| `_test` | `rspec` | Run test suite |

See [DEVELOPMENT.md](../DEVELOPMENT.md) for the full Makefile contract and two-layer delegation pattern.

## Pre-Commit Hooks

### Local Hooks (< 30 seconds)

These run on every commit via `pre-commit`:

```yaml
repos:
  - repo: https://github.com/rubocop/rubocop
    rev: ""  # container manages version
    hooks:
      - id: rubocop
```

### CI-Only

These run via `make security` and `make test` in CI pipelines. They are **not** configured as pre-commit hooks due to execution time:

- `brakeman -q` -- Rails security scanning
- `bundler-audit check` -- dependency vulnerability scanning
- `rspec` -- full test suite
- `reek .` -- code smell detection (when project is large)
- `sorbet` -- type checking (when project adopts typed signatures)

## Notes

- rubocop is the single tool for both linting and formatting. Do not use standardrb or prettier-ruby.
- `rubocop-rails`, `rubocop-rspec`, and `rubocop-performance` are rubocop extensions loaded via `require:` in `.rubocop.yml`. They are not standalone tools.
- `brakeman` only runs for Rails applications. It is skipped if `config/application.rb` is not present.
- `bundler-audit` only runs if `Gemfile.lock` exists. It checks for known vulnerabilities in declared gem dependencies.
- `reek` runs as part of `make lint`. It detects code smells (feature envy, too-many-instance-variables, etc.).
- `sorbet` is optional. Projects can incrementally adopt it by adding `# typed:` sigils to files.
- All tools are pre-installed in the dev-toolchain container. Do not install them on the host.
- **Rails rspec in CI:** The dev-toolchain container handles static analysis (rubocop, reek, brakeman, bundler-audit) but Rails integration tests typically need a database service (Postgres, MySQL). In CI, run a separate rspec job with the project's own `ruby` image, Bundler, and a database service. The DevRail `make _test` target handles rspec for simple cases; use a dedicated CI job when your tests require external services.
- For cross-cutting practices (DRY, idempotency, error handling, testing, naming) and git workflow (branching, code review, conventional commits), see [Coding Practices](coding-practices.md) and [Git Workflow](git-workflow.md).
