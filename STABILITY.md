# Stability

DevRail has reached **v1.0** across all repositories. The core standards, toolchain, templates, and documentation are stable and in production use.

## What "v1.0" Means

- **Backward compatibility.** Breaking changes require a major version bump (`v2.0.0`). Minor and patch releases are additive.
- **Stable interfaces.** Makefile targets, `.devrail.yml` schema, and CLI behavior are committed contracts.
- **New languages are additive.** Adding a language ecosystem is a minor version bump — existing languages and behavior are unaffected.
- **Feedback is welcome.** File issues, open discussions, or submit PRs.

## Component Status

For the full component-by-component status table, see the [dev-toolchain STABILITY.md](https://github.com/devrail-dev/dev-toolchain/blob/main/STABILITY.md).

## Versioning

All DevRail repos follow [Semantic Versioning](https://semver.org/). The container image uses a floating major tag (`:v1`) that always points to the latest `v1.x.x` release. Pin to a specific tag (e.g., `:v1.4.0`) if you need exact reproducibility.

## How to Track Changes

- Watch the [CHANGELOG.md](CHANGELOG.md) in each repo for release-by-release details.
- Breaking changes will be called out explicitly in changelog entries during beta.
