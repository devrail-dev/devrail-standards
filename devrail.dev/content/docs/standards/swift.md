---
title: "Swift"
linkTitle: "Swift"
weight: 45
description: "Swift tooling standards: SwiftLint, swift-format, swift test, and xcodebuild."
---

Swift projects use SwiftLint for linting, swift-format for formatting, swift test for SPM-based testing, and xcodebuild for Xcode project testing on macOS CI runners.

## Tools

| Category | Tool | Purpose |
|---|---|---|
| Linter | SwiftLint | Style and convention enforcement |
| Formatter | swift-format | Apple's official code formatter |
| Tests (SPM) | swift test | Swift Package Manager test runner |
| Tests (Xcode) | xcodebuild | Xcode project test runner (macOS only) |

All tools except xcodebuild are pre-installed in the dev-toolchain container. Do not install them on the host.

## Configuration

### SwiftLint

Config file: `.swiftlint.yml` at repository root.

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
  - force_unwrapping
  - implicitly_unwrapped_optional
  - multiline_arguments
  - overridden_super_call
  - sorted_first_last
  - toggle_bool

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
```

SwiftLint is invoked with `--strict` to treat all warnings as errors.

### swift-format

Config file: `.swift-format` (JSON) at repository root.

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
  "lineBreakBeforeEachArgument": true
}
```

swift-format is Apple's official Swift formatter. It is authoritative for all code style decisions.

## Makefile Targets

| Target | Command | Description |
|---|---|---|
| `make lint` | `swiftlint lint --strict` | Lint all Swift files |
| `make format` | `swift-format lint --strict -r .` | Check formatting (diff mode) |
| `make fix` | `swift-format format -i -r .` | Apply formatting fixes |
| `make test` | `swift test` | Run SPM test suite (if `Package.swift` exists) |

## Pre-Commit Hooks

### Local Hooks (run on every commit, under 30 seconds)

SwiftLint runs on every commit to catch lint issues:

```yaml
# .pre-commit-config.yaml -- Swift hooks
repos:
  - repo: https://github.com/realm/SwiftLint
    rev: 0.58.0
    hooks:
      - id: swiftlint
        args: ["lint", "--strict"]
```

### CI-Only (too slow for local hooks)

- `swift test` -- SPM test suite
- `xcodebuild test` -- Xcode project tests (macOS runners only, outside container)

## Notes

- **SwiftLint is the single linting tool.** It is the most widely adopted Swift linter with extensive rule coverage. It runs on both macOS and Linux.
- **swift-format is the single formatting tool inside the container.** Apple's official formatter handles all code style decisions.
- **The Swift toolchain is included in the container.** The full toolchain (swiftc, swift build, swift test, Swift Package Manager) is COPY'd from the `swift:6.1-slim-bookworm` builder stage.
- **`Package.swift` presence gates SPM testing.** If no `Package.swift` exists, `swift test` is skipped. Xcode-only projects must configure `xcodebuild test` in their CI pipeline directly.
- **`xcodebuild` does not run inside the container.** It requires macOS and Xcode. Configure a separate macOS CI job for Xcode project testing.
- **Security scanning uses trivy.** Trivy scans `Package.resolved` for known vulnerabilities in Swift package dependencies.
- **All tools are pre-installed in the dev-toolchain container.** Do not install them on the host.
- For cross-cutting coding practices and git workflow standards that apply to all languages, see [Coding Practices](/docs/standards/practices/).
