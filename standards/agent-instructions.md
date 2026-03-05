# Agent Instruction File Strategy

This document describes the hybrid shim strategy used by DevRail to communicate development standards to AI coding agents.

## Overview

DevRail uses a **hybrid shim** pattern for agent instruction files. Each tool-specific file (CLAUDE.md, AGENTS.md, .cursorrules, .opencode/agents.yaml) contains two things:

1. **A pointer to DEVELOPMENT.md** -- the canonical, complete source of all development standards.
2. **Critical rules inlined directly** -- the eight non-negotiable rules that agents must follow regardless of whether they resolve cross-file references.

## Rationale

AI coding agents vary in their ability to follow cross-file references. Some agents (like Claude Code) reliably read referenced files. Others may ignore or miss cross-references entirely.

The hybrid approach solves this:

- **Pointer to DEVELOPMENT.md** ensures agents with cross-reference support get the full context -- language-specific tooling, Makefile contract, shell conventions, logging standards, and more.
- **Inlined critical rules** ensure that even agents which ignore cross-references still follow the eight most important behaviors. These rules represent the minimum viable compliance for any agent operating on a DevRail-managed project.

This is deliberately not an all-or-nothing approach. Dumping the entire DEVELOPMENT.md into every shim would create maintenance burden and version drift. Inlining only a pointer would risk agents missing critical behaviors. The hybrid shim balances completeness with reliability.

## Critical Rules

Every shim file inlines these eight rules verbatim. They are extracted from the `<!-- devrail:critical-rules -->` section of DEVELOPMENT.md.

1. **Run `make check` before completing any story or task.** Never mark work done without passing checks. This is the single gate for all linting, formatting, security, and test validation.
2. **Use conventional commits.** Every commit message follows the `type(scope): description` format. No exceptions.
3. **Never install tools outside the container.** All linters, formatters, scanners, and test runners live inside `ghcr.io/devrail-dev/dev-toolchain:v1`. The Makefile delegates to Docker. Do not install tools on the host.
4. **Respect `.editorconfig`.** Never override formatting rules (indent style, line endings, trailing whitespace) without explicit instruction.
5. **Write idempotent scripts.** Every script must be safe to re-run. Check before acting: `command -v tool || install_tool`, `mkdir -p`, guard file writes with existence checks.
6. **Use the shared logging library.** No raw `echo` for status messages. Use `log_info`, `log_warn`, `log_error`, `log_debug`, and `die` from `lib/log.sh`.
7. **Never suppress failing checks.** When a lint, format, security, or test check fails, fix the underlying issue. Never comment out code, add suppression annotations, disable rules, or mark CI jobs as allowed-to-fail to bypass a failing check. If a finding is a confirmed false positive, document the justification inline alongside the tool's designated suppression mechanism.
8. **Update documentation when changing behavior.** When a change affects public interfaces, configuration, CLI usage, or setup steps, update the relevant documentation (README, DEVELOPMENT.md, inline docs) in the same commit or PR. Do not leave documentation out of sync with code.

## How Shim Files Reference DEVELOPMENT.md

Each shim file includes a statement such as:

> This project follows DevRail development standards. See DEVELOPMENT.md for the complete reference.

The exact phrasing varies slightly by format (Markdown, YAML, plain text), but the semantics are identical: DEVELOPMENT.md is the canonical source, and the shim is a concise entry point.

## Shim File Inventory

| File | Format | Tool |
|---|---|---|
| `CLAUDE.md` | Markdown | Claude Code |
| `AGENTS.md` | Markdown | Generic (any agent) |
| `.cursorrules` | Plain text | Cursor |
| `.opencode/agents.yaml` | YAML | OpenCode |

All four shim files contain identical critical rules content. Format-specific differences are limited to syntax and structural conventions required by each tool.

## Shim File Structure

Every shim follows this structure:

1. **Header** -- identifies the file as a DevRail standards pointer.
2. **Pointer** -- directs the agent to DEVELOPMENT.md for full standards.
3. **Critical Rules** -- the eight rules inlined verbatim.
4. **Quick Reference** -- a short list of the most common commands.

The shim files are templates. They contain no project-specific information and work in any DevRail-compliant repository.
