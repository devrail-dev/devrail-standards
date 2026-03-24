---
title: "Kotlin"
linkTitle: "Kotlin"
weight: 50
description: "Kotlin tooling standards: ktlint, detekt, Gradle, and Android Lint."
---

Kotlin projects use ktlint for linting and formatting, detekt for static analysis, Gradle for building and testing, and Android Lint for Android-specific checks on CI.

## Tools

| Category | Tool | Purpose |
|---|---|---|
| Linter / Formatter | ktlint | Kotlin linter and formatter (official coding conventions) |
| Static Analysis | detekt | Configurable static code analysis |
| Build / Tests | Gradle | Build tool and test runner (`gradle test`) |
| Security | OWASP dependency-check | Dependency vulnerability scanning (Gradle plugin) |
| Android Lint | Android Lint | Android-specific checks (requires Android SDK, CI-only) |

All tools except Android Lint are pre-installed in the dev-toolchain container. Do not install them on the host.

## Configuration

### ktlint

Config file: `.editorconfig` at repository root (ktlint respects EditorConfig).

```ini
# .editorconfig -- ktlint configuration
[*.{kt,kts}]
indent_size = 4
max_line_length = 120
ktlint_code_style = ktlint_official
```

ktlint enforces the official Kotlin coding conventions. No separate config file is needed beyond `.editorconfig`.

### detekt

Config file: `detekt.yml` at repository root.

```yaml
# detekt.yml -- DevRail Kotlin static analysis configuration
build:
  maxIssues: 0

complexity:
  LongMethod:
    threshold: 50
  LongParameterList:
    functionThreshold: 7
  ComplexMethod:
    threshold: 15

style:
  MagicNumber:
    active: true
    ignoreNumbers: ["-1", "0", "1", "2"]
  MaxLineLength:
    maxLineLength: 120
  WildcardImport:
    active: true

potential-bugs:
  UnsafeCast:
    active: true
```

Setting `maxIssues: 0` causes any finding to fail the build.

### Gradle (OWASP dependency-check)

Add the plugin to `build.gradle.kts`:

```kotlin
plugins {
    id("org.owasp.dependencycheck") version "11.1.1"
}

dependencyCheck {
    failBuildOnCVSS = 7.0f
    formats = listOf("HTML", "JSON")
}
```

## Makefile Targets

| Target | Command | Description |
|---|---|---|
| `make lint` | `ktlint` | Lint all Kotlin files |
| `make lint` | `detekt --build-upon-default-config --config detekt.yml` | Static analysis (if `detekt.yml` exists) |
| `make format` | `ktlint --format --dry-run` | Check formatting |
| `make fix` | `ktlint --format` | Apply formatting fixes |
| `make security` | `gradle dependencyCheckAnalyze` | OWASP dependency scanning |
| `make test` | `gradle test` | Run test suite |

## Pre-Commit Hooks

### Local Hooks (run on every commit, under 30 seconds)

ktlint runs on every commit to catch lint and formatting issues:

```yaml
# .pre-commit-config.yaml -- Kotlin hooks
repos:
  - repo: https://github.com/JetBrains/ktlint-pre-commit-hook
    rev: v1.5.0
    hooks:
      - id: ktlint
```

### CI-Only (too slow for local hooks)

- `detekt` -- static code analysis (requires full project context)
- `gradle test` -- full test suite
- `gradle dependencyCheckAnalyze` -- OWASP dependency vulnerability scanning
- `gradle lint` -- Android Lint (Android projects only, requires Android SDK)

## Notes

- **ktlint is dual-purpose: linter and formatter.** It checks and enforces the official Kotlin coding conventions. Run `ktlint` to check and `ktlint --format` to fix.
- **detekt complements ktlint.** While ktlint focuses on style and formatting, detekt provides deeper static analysis (complexity, potential bugs, code smells). Both run in CI.
- **Gradle is the standard build tool.** Both `gradle test` and dependency checking require Gradle. The container ships Gradle and JDK 21 so projects do not need the Gradle wrapper, though `gradlew` is supported if present.
- **Android Lint requires the Android SDK.** For Android projects, configure a separate CI job with the Android SDK. The container handles ktlint, detekt, and Gradle test for all Kotlin projects.
- **JDK 21 is included in the container.** Eclipse Temurin JDK 21 is COPY'd from a builder stage.
- **`build.gradle.kts` or `build.gradle` presence gates testing.** If neither file exists, Gradle commands are skipped.
- **ktlint uses `.editorconfig` for configuration.** Consistent with DevRail's `.editorconfig`-first approach.
- **All tools are pre-installed in the dev-toolchain container.** Do not install them on the host.
- For cross-cutting coding practices and git workflow standards that apply to all languages, see [Coding Practices](/docs/standards/practices/).
