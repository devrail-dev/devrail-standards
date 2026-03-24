# Swift Standards

## Tools

| Concern | Tool | Version Strategy |
|---|---|---|
| Linter | SwiftLint | Latest in container |
| Formatter | swift-format | Latest in container (Apple's official formatter) |
| Tests (SPM) | swift test | Ships with Swift toolchain |
| Tests (Xcode) | xcodebuild | macOS CI runners only |

SwiftLint is the de facto standard linter for Swift, enforcing style and convention rules. swift-format is Apple's official code formatter. Both run on Linux inside the dev-toolchain container. For Xcode-based projects, `xcodebuild test` runs on macOS CI runners outside the container.

## Configuration

### SwiftLint

Config file: `.swiftlint.yml` at repository root.

Recommended `.swiftlint.yml`:

```yaml
# .swiftlint.yml -- DevRail Swift lint configuration
# See: https://realm.github.io/SwiftLint/rule-directory.html

opt_in_rules:
  - closure_body_length
  - collection_alignment
  - contains_over_filter_count
  - discouraged_optional_boolean
  - empty_collection_literal
  - empty_count
  - empty_string
  - enum_case_associated_values_count
  - explicit_init
  - fatal_error_message
  - first_where
  - force_unwrapping
  - implicitly_unwrapped_optional
  - last_where
  - multiline_arguments
  - multiline_parameters
  - overridden_super_call
  - prefer_zero_over_explicit_init
  - redundant_nil_coalescing
  - sorted_first_last
  - toggle_bool
  - unneeded_parentheses_in_closure_argument
  - vertical_whitespace_closing_braces

excluded:
  - .build
  - Packages
  - DerivedData

line_length:
  warning: 120
  error: 200

type_body_length:
  warning: 300
  error: 500

file_length:
  warning: 500
  error: 1000
```

SwiftLint is invoked with `--strict` to treat all warnings as errors. Rules can be customized per-project; the defaults above match DevRail conventions for readability and safety.

### swift-format

Config file: `.swift-format` (JSON) at repository root.

Recommended `.swift-format`:

```json
{
  "version": 1,
  "lineLength": 120,
  "indentation": {
    "spaces": 4
  },
  "maximumBlankLines": 1,
  "respectsExistingLineBreaks": true,
  "lineBreakBeforeControlFlowKeywords": false,
  "lineBreakBeforeEachArgument": true,
  "indentConditionalCompilationBlocks": true,
  "lineBreakAroundMultilineExpressionChainComponents": true
}
```

swift-format is Apple's official Swift formatter. It handles all whitespace, indentation, and line-breaking decisions. Do not use both swift-format and SwiftLint's autocorrect for formatting -- swift-format is authoritative for style, SwiftLint is authoritative for lint rules.

## Makefile Targets

| Target | Command | Description |
|---|---|---|
| `_lint` | `swiftlint lint --strict` | Lint all Swift files (if `*.swift` files exist) |
| `_format` | `swift-format lint --strict -r .` | Check formatting (non-zero on unformatted) |
| `_fix` | `swift-format format -i -r .` | Apply formatting fixes |
| `_test` | `swift test` | Run SPM test suite (if `Package.swift` exists) |

See [DEVELOPMENT.md](../DEVELOPMENT.md) for the full Makefile contract and two-layer delegation pattern.

## Pre-Commit Hooks

### Local Hooks (< 30 seconds)

SwiftLint via pre-commit:

```yaml
repos:
  - repo: https://github.com/realm/SwiftLint
    rev: 0.58.0
    hooks:
      - id: swiftlint
        args: ["lint", "--strict"]
```

Formatting is checked by `swift-format` inside the container via `make format`. There is no pre-commit formatting hook because Apple's swift-format does not have native pre-commit support, and using a different formatter (e.g., nicklockwood/SwiftFormat) would produce inconsistent results with the container. Run `make fix` locally to auto-format before committing.

### CI-Only

These run via `make test` in CI pipelines. They are **not** configured as pre-commit hooks due to execution time:

- `swift test` -- SPM test suite
- `xcodebuild test` -- Xcode project tests (macOS runners only, outside container)

## Notes

- **SwiftLint is the single linting tool.** It is the most widely adopted Swift linter with extensive rule coverage. It runs on both macOS and Linux.
- **swift-format is the single formatting tool inside the container.** Apple's official formatter handles all code style decisions. The pre-commit hook uses nicklockwood/SwiftFormat for broader pre-commit integration.
- **The Swift toolchain is included in the container.** The full toolchain (swiftc, swift build, swift test, Swift Package Manager) is COPY'd from the `swift:6.1-slim-bookworm` builder stage.
- **`Package.swift` presence gates SPM testing.** If no `Package.swift` file exists, `swift test` is skipped. Xcode-only projects must configure `xcodebuild test` in their CI pipeline directly.
- **`xcodebuild` does not run inside the container.** It requires macOS and Xcode. For projects that use Xcode, configure a separate macOS CI job that runs `xcodebuild test` outside the container. The container handles linting and formatting only for these projects.
- **Security scanning uses trivy.** There is no dedicated Swift dependency audit tool comparable to `cargo-audit` or `npm audit`. Trivy scans `Package.resolved` for known vulnerabilities in Swift package dependencies.
- **All tools are pre-installed in the dev-toolchain container.** Do not install them on the host.
- For cross-cutting practices (DRY, idempotency, error handling, testing, naming) and git workflow (branching, code review, conventional commits), see [Coding Practices](coding-practices.md) and [Git Workflow](git-workflow.md).
