---
title: "Kotlin Language Support"
date: 2026-03-23
description: "DevRail now supports Kotlin with ktlint, detekt, and Gradle -- covering both server-side and Android Kotlin development."
---

DevRail now supports Kotlin as its tenth language ecosystem. Whether you are building server-side Kotlin services or Android applications, DevRail provides consistent linting, static analysis, testing, and security scanning through the same Makefile targets and CI pipelines used by every other supported language.

## What's Included

The dev-toolchain container ships JDK 21, the Kotlin compiler, Gradle, and dedicated analysis tools:

- **ktlint** -- Kotlin linter and formatter that enforces the official Kotlin coding conventions, serving as a dual-purpose tool for both style checking and auto-formatting
- **detekt** -- configurable static code analysis for Kotlin, covering complexity, potential bugs, and code smells
- **Gradle** -- the standard Kotlin build tool, used for running tests and dependency analysis
- **OWASP dependency-check** -- Gradle plugin for scanning dependencies against the National Vulnerability Database
- **trivy** -- universal dependency scanning for Gradle projects

JDK 21 (Eclipse Temurin) is included in the container alongside the Kotlin compiler and Gradle distribution.

## Configuration

Add `kotlin` to your `.devrail.yml`:

```yaml
languages:
  - kotlin
```

ktlint reads `.editorconfig` at the repository root -- no separate config file needed. detekt reads `detekt.yml` for static analysis rules. Both are scaffolded by `devrail init` when Kotlin is declared.

## Makefile Targets

The standard targets work out of the box:

```bash
make lint       # ktlint + detekt (if detekt.yml exists)
make format     # ktlint --format --dry-run
make fix        # ktlint --format
make test       # gradle test (if build.gradle.kts or build.gradle exists)
make security   # gradle dependencyCheckAnalyze (OWASP)
make check      # all of the above
```

## Android Projects

The container handles ktlint, detekt, and Gradle test for all Kotlin projects. Android-specific checks (Android Lint) require the Android SDK, which is not included in the container. For Android projects, configure a separate CI job:

```yaml
# GitHub Actions example -- Android Lint job
- name: Run Android Lint
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-java@v4
      with:
        distribution: temurin
        java-version: 21
    - name: Setup Android SDK
      uses: android-actions/setup-android@v3
    - run: ./gradlew lint
```

Server-side Kotlin projects (Spring Boot, Ktor, etc.) work entirely inside the container with no additional setup.

## Pre-Commit Hooks

ktlint runs as a local pre-commit hook (under 30 seconds):

```yaml
repos:
  - repo: https://github.com/JetBrains/ktlint-pre-commit-hook
    rev: v1.5.0
    hooks:
      - id: ktlint
```

## Getting Started

Pull the latest container and add Kotlin to your project:

```bash
docker pull ghcr.io/devrail-dev/dev-toolchain:v1
```

Or use `devrail init` to set up a new Kotlin project:

```bash
curl -fsSL https://devrail.dev/init.sh | bash -s -- --languages kotlin --ci github --all
```

See the [Kotlin Standards](/docs/standards/kotlin/) page for the full configuration reference.
