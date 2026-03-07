---
stepsCompleted: [1, 2, 3, 4, 5, 6]
status: complete
completedAt: 2026-03-06
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/architecture.md
  - _bmad-output/planning-artifacts/epics.md
  - README.md
date: 2026-03-06
author: Matthew
---

# Product Brief: DevRail

<!-- Content will be appended sequentially through collaborative workflow steps -->

## Executive Summary

DevRail is an open-source, agent-first developer infrastructure platform that eliminates per-project setup tax and enforces consistent quality gates across all repositories. It provides a single canonical set of standards backed by a universal Makefile+Docker contract, pre-built CI pipelines for GitHub Actions and GitLab CI, and machine-readable agent instruction files that ensure any AI coding tool follows the same rules without repeated prompting.

In 2026, agents crossed the threshold from helpful autocomplete to primary code contributors. Developers spinning up multiple repositories daily burn context window repeating the same instructions: use conventional commits, run checks, don't suppress failures, write idempotent scripts. That's a consistency problem — and every generation of developer tooling has solved the consistency problem for its era:

| Era | Problem | Solution |
|---|---|---|
| Pre-CI | "Did you run the tests?" | Jenkins, Travis |
| Pre-linting | "Did you format the code?" | EditorConfig, Prettier |
| Pre-containers | "Works on my machine" | Docker |
| **2026 — Agent era** | **"Does the agent know the rules?"** | **DevRail** |

DevRail is consistency infrastructure for the agent era. It was built to scratch an itch — the creator needed it for his own projects — and is open-source for anyone who needs it too.

---

## Core Vision

### Problem Statement

Agents aren't broken — they're unconstrained. Given unambiguous, enforceable rules, agents produce consistent, high-quality output. The problem is that no standard infrastructure exists for giving agents those rules. Every new project requires the developer to re-teach preferences, burning tokens on boilerplate instructions instead of business logic. Without enforceable, machine-readable standards, agent-assisted development produces technical debt from day one.

### Problem Impact

- **Token tax:** Every new repo costs hundreds of tokens in repeated instructions before productive work begins
- **Agent drift:** Without constraints, models pick different approaches each session — inconsistent linting, ad-hoc security scanning, varying commit styles — creating maintenance burden across repos
- **Setup friction:** Developers copy files from previous projects or manually configure CI/CD for each new repository, slowing the path from idea to first passing build
- **Repo sprawl:** Without standardization, a developer's portfolio of projects becomes a collection of snowflakes — each with its own conventions, tool versions, and CI quirks
- **Scale of the problem:** In 2026, spinning up multiple new repos a day is common. The consistency problem compounds with every repo and every agent session

### Why Existing Solutions Fall Short

Every previous generation of developer tooling removed human discipline from one quality concern. No existing solution removes human discipline from the entire agent workflow — standards, enforcement, and project scaffolding — in a single ecosystem.

- **Super-linter / MegaLinter:** Multi-language linting containers, but no agent instruction files, no Makefile contract, no project scaffolding. They aggregate tools without providing an opinionated standard.
- **Cookiecutter / Copier:** Project templating that stamps out a repo and walks away. No ongoing enforcement, no container-based consistency, no agent awareness.
- **trunk.io:** Developer experience layer, but SaaS/proprietary and not agent-oriented.
- **No existing solution** ships CLAUDE.md, AGENTS.md, or .cursorrules as first-class artifacts. None treat "the agent reads the repo and knows what to do" as the core design principle.

### Proposed Solution

DevRail is a contract chain: canonical standards flow one direction, enforcement flows through one container, and one command — `make check` — surfaces the result. Agents, humans, and CI pipelines all use the same interface and get the same answer.

The ecosystem consists of six repositories under `github.com/devrail-dev/`:

1. **Canonical standards** — the source of truth for all conventions across 8 language ecosystems
2. **Dev-toolchain container** — a single Docker image with every linter, formatter, scanner, and test runner pre-installed
3. **Makefile contract** — one interface (`make check`) that works identically for developers, agents, and CI
4. **Project templates** — battle-tested repo scaffolding for GitHub and GitLab with CI pipelines, pre-commit hooks, and agent instruction files pre-configured
5. **Agent instruction files** — CLAUDE.md, AGENTS.md, .cursorrules, .opencode/ shipped with every template so any AI tool knows the rules on day one
6. **Documentation site** — devrail.dev as the public reference, so agents anywhere on the internet can be pointed at it

### Key Differentiators

DevRail exists because 2026 is the year agents became primary code contributors. That shift created three requirements that no existing tool addresses:

1. **Agent-first standards** — built for machines to consume, not humans to read. Standards are structured for machine readability and enforced through a single `make check` contract — not retrofitted onto a human-first system.
2. **One command, three actors** — `make check` is the universal contract for developers, agents, and CI pipelines. The same interface, the same container, the same result. No previous tool has collapsed the human interface and CI interface into one.
3. **Zero-config project start** — template repos produce fully configured projects. First commit triggers checks, first push triggers CI, agents already know the rules. Minutes from idea to first passing build.

**Why this couldn't exist before:** The volume of agent-written code has crossed a threshold where consistency can't be managed by prompting anymore. It needs infrastructure. DevRail is that infrastructure — and the builder-is-user feedback loop (dogfooding at scale, spinning up multiple repos daily with real agents) keeps the platform honest in a way that can't be replicated from the outside.

---

## Target Users

### Primary User

**The Agent-Augmented Developer**

A developer who uses AI agents as primary code contributors across multiple repositories. They may be solo or leading a small team, but critically, they don't have a platform engineering team handing them golden paths. They spin up new projects frequently and need consistent standards without burning tokens re-teaching preferences every session.

- **Context:** Manages multiple active repositories across one or more languages. Uses Claude Code, Cursor, or similar AI coding tools daily. Works across personal projects and potentially across employers.
- **Current pain:** Repeating the same instructions to agents every session. Copying config files from previous repos. Inconsistent linting, commit styles, and security practices across repos. Time wasted on CI/CD setup instead of business logic.
- **Success moment:** An agent reads the repo's instruction files and produces correctly formatted, conventionally committed, security-scanned code without a single instruction about project standards. First push, green CI. Minutes from idea to working project.
- **Long-term value:** Their entire portfolio of projects shares one set of standards. Upgrading the dev-toolchain container version rolls improvements across everything. No snowflakes.

**Adoption Paths:**

| Path | Entry Point | Barrier | End State |
|---|---|---|---|
| **Partial (wedge)** | Copy CLAUDE.md and agent instruction files into an existing repo | One file | Agents follow standards immediately; no container or CI changes required |
| **Retrofit (brownfield)** | Add Makefile, pre-commit config, and CI pipeline to existing repos | Configuration | Full DevRail enforcement on existing projects |
| **Template (greenfield)** | Create new repo from GitHub or GitLab template | Zero config | Everything pre-configured from first commit |

Partial adoption is the entry wedge. Even a single agent instruction file changes agent behavior. Full template adoption is the high ceiling, not the starting requirement.

### System Actors

**AI Agents** — Non-human consumers that read CLAUDE.md, AGENTS.md, .cursorrules, or .opencode/ and execute accordingly. They are the primary *reason* DevRail exists but are a mechanism, not a user — they don't choose to adopt DevRail, they're pointed at it. How different agent platforms consume standards is an evolving interface; the hybrid shim pattern (one canonical source, tool-specific shims) ensures new agent platforms can be supported quickly as they emerge.

**CI Pipelines** — Enforcement gates configured by the developer. GitHub Actions and GitLab CI workflows pull the dev-toolchain container and run `make check`. They guarantee that what passed locally passes in CI, identically.

### Aspirational User: The Contributor

A developer who has adopted DevRail and wants to improve it — adding a language ecosystem, fixing a bug, or improving documentation. This persona is not yet realized but the architecture is explicitly designed to support it: one install script per language, consistent Makefile target patterns, and DevRail dogfooding its own standards means contributions follow a clear, repeatable pattern.

### User Journey

1. **Discovery:** Developer finds DevRail through GitHub, devrail.dev, or by encountering a repo that uses it. The public documentation means agents can also be pointed at devrail.dev directly.
2. **Entry (low barrier):** Copies agent instruction files into an existing repo. Agents immediately start following standards — no container, no CI changes required.
3. **Expansion:** Adds Makefile, pre-commit hooks, and CI pipeline. Existing repo now has full DevRail enforcement.
4. **New projects:** Creates repos from DevRail templates. Everything pre-configured from first commit.
5. **"Aha" moment:** The first time an agent reads CLAUDE.md and runs `make check` without being asked. No repeated instructions, no token tax — the agent just knows.
6. **Portfolio consistency:** Over weeks, all active repos converge on one standard. Container version upgrades propagate improvements.
7. **Contribution (future):** Developer identifies a gap, follows the contribution pattern, and extends the ecosystem for everyone.

---

## Success Metrics

### User Success

**Agent Consistency (primary):**
- Agents produce output that follows project standards without per-session instruction
- Same task given to different models or different sessions yields structurally consistent results — same commit format, same formatting, same check-before-done behavior
- Signal: the developer stops finding inconsistencies across agent-produced work

**Setup Friction (primary):**
- New repo to first passing CI measured in minutes, not hours
- Developer never manually configures linting, formatting, security scanning, or CI pipelines for a new project
- Signal: every new project starts from a DevRail template with zero additional setup

**Token Efficiency (byproduct):**
- Context window spent on business logic, not boilerplate instructions
- Not explicitly measured, but a natural consequence of solving agent drift and setup friction

### Business Objectives

DevRail is not a revenue-generating product. Success is measured by utility and adoption:

- **Personal utility:** All personal and side projects running on DevRail. Every repo passes `make check`. No snowflake repos.
- **Adoption growth:** External developers discovering and using DevRail — signals that the project solves a real, generalizable problem
- **Ecosystem improvement:** More usage drives more feedback, more contributions, and better standards. The project gets better as it's used more.

### Key Performance Indicators

| KPI | Measurement | Why It Matters |
|---|---|---|
| Agent compliance rate | % of agent-produced commits that pass `make check` on first run | Core signal that agent drift is solved |
| Time to first green CI | Minutes from repo creation to first passing pipeline | Core signal that setup friction is solved |
| GitHub stars | Count over time | Awareness and interest signal |
| Template usage | Repos created from DevRail templates (GitHub insights) | Active adoption signal |
| Forks | Count over time | Signal of developers evaluating or customizing |
| External PRs | PRs from non-maintainers | Community contribution signal — "this has legs" |
| Container pulls | GHCR download counts | Usage signal beyond template adoption |

---

## MVP Scope

### Core Features (Shipped)

DevRail MVP is complete and in active daily use. The shipped ecosystem includes:

**Ecosystem (6 repositories):**
- Canonical standards document with 23 standards files
- Dev-toolchain container (`ghcr.io/devrail-dev/dev-toolchain:v1`) with weekly automated builds
- Pre-commit conventional commits hook
- GitHub repo template with Actions CI
- GitLab repo template with GitLab CI
- Documentation site at devrail.dev

**Language Support (8 ecosystems):**
Python, Bash, Terraform (+ Terragrunt), Ansible, Ruby, Go, JavaScript/TypeScript, Rust

**Makefile Contract (10 targets):**
`make lint`, `make format`, `make fix`, `make test`, `make security`, `make scan`, `make docs`, `make changelog`, `make check`, `make install-hooks`

**Agent Integration:**
CLAUDE.md, AGENTS.md, .cursorrules, .opencode/ shipped with every template. 8 critical rules enforced.

### Out of Scope for MVP

- Build targets — every project handles builds differently
- Runtime/deployment concerns — DevRail is dev-time infrastructure only
- Enterprise features — no RBAC, no SaaS, no paid tier
- CLI tool — templates and file copying are the right level of simplicity for MVP

### MVP Success Criteria

MVP success is validated by daily use:
- All personal projects running on DevRail templates
- Agents follow standards without per-session instruction
- New project to first passing CI in minutes
- 8 language ecosystems stable and passing `make check`

### Future Vision

**Phase 2a: Reduce Friction**

- **`devrail init` adoption script:** A standalone, idempotent script (hosted in the standards repo, downloadable via `curl`) that progressively adopts DevRail into any repo. No container dependency. The script:
  - Detects what already exists in the repo — no silent overrides; prompts before overwriting existing files
  - Asks in problem language with full transparency:
    - "Do you want agents to follow your project's standards?" → lists exact files that will be added (CLAUDE.md, AGENTS.md, .cursorrules, .opencode/)
    - "Do you want automatic formatting and linting checks on every commit?" → lists .pre-commit-config.yaml and its dependencies
    - "Do you want one command to run all checks locally?" → lists Makefile, .devrail.yml, container reference
    - "Do you want CI to enforce everything automatically?" → lists CI pipeline config for GitHub Actions or GitLab CI
  - Each prompt shows what files get added, what they do, and any dependencies — full transparency, no magic
  - Safe to re-run — users layer on more DevRail as they're ready
  - Educational by design — by the time a user answers four questions, they understand DevRail's architecture

- **Single-source template generation:** Dev-toolchain becomes the single source of truth for template Makefile internal targets. When dev-toolchain merges changes to internal targets (`_lint`, `_format`, etc.), a CI job generates updated template Makefiles and opens PRs on both template repos automatically. This eliminates the entire class of "templates fell behind dev-toolchain" drift problems.

**Phase 2b: Expand Reach (When Needed)**

- **New language ecosystems:** Java, Elixir, C# — added when there's a real need from personal use or adoption signals. The pattern is proven and repeatable (4 languages added in 2 weeks). Each addition is an operation, not a strategic milestone.
- **Agent platform integrations:** Track emerging platforms and support them reactively. The hybrid shim pattern ensures new platforms can be supported quickly.
- **Documentation site refinement:** Evaluate and improve devrail.dev based on real usage patterns.

**Phase 3: Community & Platform Integration**

- External contributors following the established contribution pattern
- Enterprise fork documentation and guide
- Plugin/extension architecture for custom tool additions
- If adoption grows, DevRail's configuration format (`.devrail.yml`) could serve as a standard interface between projects and agent platforms — a native way for agent tools to understand a project's standards without reading instruction files. This is aspiration, not promise — each step of adoption earns the next.
