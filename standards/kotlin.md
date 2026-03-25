# Kotlin Standards

## Tools

| Concern | Tool | Version Strategy |
|---|---|---|
| Linter | ktlint | Latest in container |
| Static Analysis | detekt | Latest in container |
| Formatter | ktlint | Latest in container (dual-purpose: lint + format) |
| Security (deps) | OWASP dependency-check | Gradle plugin (CI-only) |
| Tests | Gradle (`gradle test`) | Ships with Gradle wrapper |
| Android Lint | Android Lint | Android SDK required (CI-only for Android projects) |

ktlint is a Kotlin linter and formatter that enforces the official Kotlin coding conventions and Android Kotlin style guide. detekt provides static code analysis with configurable rule sets. Gradle is the standard build tool for Kotlin projects, handling both compilation and testing.

## Configuration

### ktlint

Config file: `.editorconfig` at repository root (ktlint respects EditorConfig).

ktlint-specific `.editorconfig` additions:

```ini
# .editorconfig -- ktlint configuration
# See: https://pinterest.github.io/ktlint/latest/rules/configuration-ktlint/

[*.{kt,kts}]
indent_size = 4
max_line_length = 120
ktlint_code_style = ktlint_official
```

ktlint enforces the official Kotlin coding conventions by default. The `ktlint_official` code style is the strictest option, following ktlint's own curated rule set. No separate config file is needed beyond `.editorconfig`.

### detekt

Config file: `detekt.yml` at repository root.

Recommended `detekt.yml`:

```yaml
# detekt.yml -- DevRail Kotlin static analysis configuration
# See: https://detekt.dev/docs/rules/

build:
  maxIssues: 0

complexity:
  LongMethod:
    threshold: 50
  LongParameterList:
    functionThreshold: 7
    constructorThreshold: 10
  ComplexMethod:
    threshold: 15
  TooManyFunctions:
    thresholdInFiles: 20
    thresholdInClasses: 15

style:
  MagicNumber:
    active: true
    ignoreNumbers:
      - "-1"
      - "0"
      - "1"
      - "2"
  MaxLineLength:
    maxLineLength: 120
  WildcardImport:
    active: true

potential-bugs:
  UnsafeCast:
    active: true
  UselessPostfixExpression:
    active: true
```

detekt runs static analysis across the entire codebase. Setting `maxIssues: 0` causes any finding to fail the build, consistent with DevRail's zero-tolerance policy.

### Gradle

Config file: `build.gradle.kts` (Kotlin DSL preferred) or `build.gradle` (Groovy DSL).

For OWASP dependency-check, add the plugin to `build.gradle.kts`:

```kotlin
// build.gradle.kts -- OWASP dependency-check plugin
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
| `_lint` | `ktlint` | Lint all Kotlin files (if `*.kt` or `*.kts` files exist) |
| `_lint` | `detekt --build-upon-default-config --config detekt.yml` | Static analysis (if `detekt.yml` exists) |
| `_format` | `ktlint --format --dry-run` | Check formatting (non-zero on unformatted) |
| `_fix` | `ktlint --format` | Apply formatting fixes |
| `_security` | `gradle dependencyCheckAnalyze` | OWASP dependency scanning (if `build.gradle.kts` or `build.gradle` exists) |
| `_test` | `gradle test` | Run test suite (if `build.gradle.kts` or `build.gradle` exists) |

See [DEVELOPMENT.md](../DEVELOPMENT.md) for the full Makefile contract and two-layer delegation pattern.

## Pre-Commit Hooks

### Local Hooks (< 30 seconds)

ktlint via pre-commit:

```yaml
repos:
  - repo: https://github.com/macisamuele/language-formatters-pre-commit-hooks
    rev: v2.14.0
    hooks:
      - id: pretty-format-kotlin
        args: ["--autofix"]
```

Alternatively, using the ktlint standalone hook:

```yaml
repos:
  - repo: https://github.com/JetBrains/ktlint-pre-commit-hook
    rev: v1.5.0
    hooks:
      - id: ktlint
```

### CI-Only

These run via `make security`, `make test`, and `make lint` in CI pipelines. They are **not** configured as pre-commit hooks due to execution time:

- `detekt` -- static code analysis (requires full project context)
- `gradle test` -- full test suite
- `gradle dependencyCheckAnalyze` -- OWASP dependency vulnerability scanning
- `gradle lint` -- Android Lint (Android projects only, requires Android SDK)

## Notes

- **ktlint is dual-purpose: linter and formatter.** It checks and enforces the official Kotlin coding conventions. There is no separate formatter tool -- ktlint handles both concerns. Run `ktlint` to check and `ktlint --format` to fix.
- **detekt complements ktlint.** While ktlint focuses on style and formatting, detekt provides deeper static analysis (complexity, potential bugs, code smells). Both should run in CI.
- **Gradle is the standard build tool.** Both `gradle test` and dependency checking require Gradle. The container ships Gradle and a JDK so projects do not need the Gradle wrapper, though `gradlew` is supported if present.
- **Android Lint requires the Android SDK.** For Android projects, configure a separate CI job with the Android SDK that runs `gradle lint`. The container handles ktlint, detekt, and Gradle test for all Kotlin projects (JVM and Android).
- **JDK 21 is included in the container.** The Eclipse Temurin JDK 21 is COPY'd from a builder stage. Kotlin compiler and Gradle both require the JVM at runtime.
- **`build.gradle.kts` or `build.gradle` presence gates testing and security scanning.** If neither file exists, `gradle test` and `gradle dependencyCheckAnalyze` are skipped.
- **ktlint uses `.editorconfig` for configuration.** This is consistent with DevRail's `.editorconfig`-first approach. No separate ktlint config file is needed.
- **Security scanning also uses trivy.** Trivy covers Gradle dependencies as a universal scanner. OWASP dependency-check provides more detailed CVE analysis for JVM projects.
- **All tools are pre-installed in the dev-toolchain container.** Do not install them on the host.
- For cross-cutting practices (DRY, idempotency, error handling, testing, naming) and git workflow (branching, code review, conventional commits), see [Coding Practices](coding-practices.md) and [Git Workflow](git-workflow.md).
