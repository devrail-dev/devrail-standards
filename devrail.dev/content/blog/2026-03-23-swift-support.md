---
title: "Swift Language Support"
date: 2026-03-23
description: "DevRail now supports Swift with SwiftLint, swift-format, and swift test -- bringing Apple-platform development into the standards-driven workflow."
---

DevRail now supports Swift as its ninth language ecosystem. Swift projects get the same standards-driven workflow as every other DevRail-supported language: linting, formatting, testing, and security scanning through consistent Makefile targets and CI pipelines.

## What's Included

The dev-toolchain container ships the full Swift toolchain alongside dedicated linting and formatting tools:

- **SwiftLint** -- the de facto standard Swift linter, enforcing style and convention rules with extensive opt-in rule coverage
- **swift-format** -- Apple's official code formatter, handling all whitespace, indentation, and line-breaking decisions
- **swift test** -- Swift Package Manager's built-in test runner for SPM-based projects
- **trivy** -- universal dependency scanning via `Package.resolved`

The full Swift toolchain (swiftc, swift build, swift test, Swift Package Manager) is included in the container, COPY'd from the official `swift:6.1-slim-bookworm` image.

## Configuration

Add `swift` to your `.devrail.yml`:

```yaml
languages:
  - swift
```

SwiftLint reads `.swiftlint.yml` at the repository root. swift-format reads `.swift-format` (JSON). Both config files are scaffolded by `devrail init` when Swift is declared.

## Makefile Targets

The standard targets work out of the box:

```bash
make lint       # swiftlint lint --strict
make format     # swift-format lint --strict -r .
make fix        # swift-format format -i -r .
make test       # swift test (if Package.swift exists)
make check      # all of the above
```

## Xcode Projects

The container runs on Linux, so `xcodebuild` is not available inside it. For Xcode-based projects (iOS, macOS apps), the container handles linting and formatting. Testing requires a separate macOS CI runner:

```yaml
# GitHub Actions example -- macOS job for xcodebuild
- name: Run Xcode tests
  runs-on: macos-latest
  steps:
    - uses: actions/checkout@v4
    - run: xcodebuild test -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 16'
```

SPM-based projects (those with `Package.swift`) run `swift test` inside the container with no additional setup.

## Pre-Commit Hooks

SwiftLint runs as a local pre-commit hook (under 30 seconds):

```yaml
repos:
  - repo: https://github.com/realm/SwiftLint
    rev: 0.58.0
    hooks:
      - id: swiftlint
        args: ["lint", "--strict"]
```

## Getting Started

Pull the latest container and add Swift to your project:

```bash
docker pull ghcr.io/devrail-dev/dev-toolchain:v1
```

Or use `devrail init` to set up a new Swift project:

```bash
curl -fsSL https://devrail.dev/init.sh | bash -s -- --languages swift --ci github --all
```

See the [Swift Standards](/docs/standards/swift/) page for the full configuration reference.
