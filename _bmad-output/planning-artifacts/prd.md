---
stepsCompleted: [step-01-init, step-02-discovery, step-02b-vision, step-02c-executive-summary, step-03-success, step-04-journeys, step-05-domain, step-06-innovation, step-07-project-type, step-08-scoping, step-09-functional, step-10-nonfunctional, step-11-polish, step-12-complete]
githubOrg: devrail-dev
inputDocuments:
  - product-brief-development-standards-2026-03-06.md
workflowType: 'prd'
workflow: 'edit'
projectName: DevRail
projectDomain: devrail.dev
documentCounts:
  briefs: 1
  research: 0
  brainstorming: 0
  projectDocs: 4
classification:
  projectType: developer_tool
  domain: general
  complexity: medium
  projectContext: shipped
lastEdited: 2026-03-06
editHistory:
  - date: 2026-03-06
    changes: "Comprehensive update: 4→8 languages, shipped MVP state, refined vision from Product Brief, updated FRs for fix/changelog/init targets, restructured phasing"
---

# Product Requirements Document - DevRail

**Author:** Matthew
**Date:** 2026-02-18
**Last Updated:** 2026-03-06

## Executive Summary

DevRail is an open-source, agent-first developer infrastructure platform that eliminates per-project setup tax and enforces consistent quality gates across all repositories. It provides a single canonical set of standards backed by a universal Makefile+Docker contract, pre-built CI pipelines for GitHub Actions and GitLab CI, and machine-readable agent instruction files that ensure any AI coding tool follows the same rules without repeated prompting.

Agents aren't broken — they're unconstrained. Given unambiguous, enforceable rules, agents produce consistent, high-quality output. The problem is that no standard infrastructure exists for giving agents those rules. Every new project requires the developer to re-teach preferences, burning tokens on boilerplate instructions instead of business logic.

Every generation of developer tooling has solved the consistency problem for its era:

| Era | Problem | Solution |
|---|---|---|
| Pre-CI | "Did you run the tests?" | Jenkins, Travis |
| Pre-linting | "Did you format the code?" | EditorConfig, Prettier |
| Pre-containers | "Works on my machine" | Docker |
| **2026 — Agent era** | **"Does the agent know the rules?"** | **DevRail** |

DevRail is consistency infrastructure for the agent era. It was built to scratch an itch — the creator needed it for his own projects — and is open-source for anyone who needs it too.

### What Makes This Special

DevRail exists because 2026 is the year agents became primary code contributors. That shift created three requirements that no existing tool addresses:

1. **Agent-first standards** — built for machines to consume, not humans to read. Standards are structured for machine readability and enforced through a single `make check` contract — not retrofitted onto a human-first system.
2. **One command, three actors** — `make check` is the universal contract for developers, agents, and CI pipelines. The same interface, the same container, the same result. No previous tool has collapsed the human interface and CI interface into one.
3. **Zero-config project start** — template repos produce fully configured projects. First commit triggers checks, first push triggers CI, agents already know the rules. Minutes from idea to first passing build.

The ecosystem consists of six repositories under `github.com/devrail-dev/`: a canonical standards document covering all supported language ecosystems, a versioned dev-toolchain Docker container, a conventional commits pre-commit hook, project templates for both GitHub and GitLab, and a Hugo documentation site at devrail.dev.

## Success Criteria

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
- Natural consequence of solving agent drift and setup friction

### Business Objectives

DevRail is not a revenue-generating product. Success is measured by utility and adoption:

- **Personal utility:** All personal and side projects running on DevRail. Every repo passes `make check`. No snowflake repos.
- **Adoption growth:** External developers discovering and using DevRail — signals that the project solves a real, generalizable problem
- **Ecosystem improvement:** More usage drives more feedback, more contributions, and better standards

### Key Performance Indicators

| KPI | Measurement | Why It Matters |
|---|---|---|
| Agent compliance rate | % of agent-produced commits that pass `make check` on first run | Core signal that agent drift is solved |
| Time to first green CI | Minutes from repo creation to first passing pipeline | Core signal that setup friction is solved |
| GitHub stars | Count over time | Awareness and interest signal |
| Template usage | Repos created from DevRail templates (GitHub insights) | Active adoption signal |
| Forks | Count over time | Signal of developers evaluating or customizing |
| External PRs | PRs from non-maintainers | Community contribution signal |
| Container pulls | GHCR download counts | Usage signal beyond template adoption |

### Measurable Outcomes

- 100% of new projects created from DevRail templates
- Agents complete stories with `make check` passing — no human follow-up required
- Time from "new project idea" to "first passing CI" measured in minutes, not hours

## User Journeys

### Primary Persona: The Agent-Augmented Developer

A developer who uses AI agents as primary code contributors across multiple repositories. They may be solo or leading a small team, but critically, they don't have a platform engineering team handing them golden paths.

### Journey 1: Greenfield — New Project Kickoff

Matt has an idea for a new homelab service. He opens GitHub, clicks "Use this template," selects the DevRail template. The repo appears with a Makefile, pre-commit config, CI pipeline, .gitignore, EditorConfig, agent instruction files — everything. He clones it, writes his first module, runs `git commit`. Pre-commit fires: ruff, conventional commit format check. It all passes. He pushes. GitHub Actions runs `make check` inside the dev-toolchain container. Green pipeline. He spent zero time on setup. He's writing business logic within minutes of having the idea.

For a Rust project, he selects the same template and sets `languages: [rust]` in `.devrail.yml`. Clippy, rustfmt, cargo-audit, cargo-deny — all configured and running. For Terraform with Terragrunt, he adds `terraform` and gets tflint, tfsec, checkov, terraform-docs, and terragrunt hclfmt. Every language follows the same pattern.

Three months later he looks across his repos. Every single one has the same structure, same checks, same CI. He upgrades the dev-toolchain container version in one place and rolls it out. No snowflakes. No surprises.

### Journey 2: Brownfield — Retrofitting Existing Repos

Sarah has 15 side projects with inconsistent tooling. She discovers DevRail and starts with the lowest-barrier entry point: copying CLAUDE.md into her most active repo. Her agents immediately start following standards — conventional commits, running checks, not suppressing failures. She didn't install anything or change her CI.

A week later, she adds the Makefile and pre-commit config to that repo. Now she has `make check` locally and hooks on commit. The following week, she adds the CI pipeline. Over three weeks, she went from "agents need constant reminding" to "everything is automated" — one layer at a time.

### Journey 3: Agent — Story Completion (System Actor)

A Claude Code agent is working through a task on Matt's project. It reads `CLAUDE.md` in the repo root. It knows: conventional commits required, `make check` must pass before completing work, never suppress failing checks, use the shared logging library. The agent writes code, commits with `feat: add user authentication endpoint`, and runs `make check`. Ruff catches a formatting issue. The agent fixes it, re-runs, gets green. Task complete. Matt never had to say "did you run the checks?" — the agent already knew.

A Cursor session picks up a different task on the same repo. It reads `.cursorrules`, sees the same standards. Same behavior. Different tool, identical outcome.

### Journey 4: Adoption Script — `devrail init` (Phase 2)

A developer named Alex finds DevRail and runs `curl -sL devrail.dev/init.sh | bash` in his existing repo. The script asks in plain language:

- "Do you want agents to follow your project's standards?" → lists the exact files that will be added
- "Do you want automatic formatting and linting checks on every commit?" → shows what pre-commit config looks like
- "Do you want one command to run all checks locally?" → explains the Makefile + container setup
- "Do you want CI to enforce everything automatically?" → shows the pipeline config

Alex answers yes to the first two, not ready for the rest. Two files are added, nothing else changes. A month later he re-runs the script and adds the Makefile. Progressive adoption, no pressure.

### Journey 5: Contributor — Improving the Ecosystem (Aspirational)

A Java developer named Priya has been using DevRail for Python and Go projects and wants Java support. She checks the dev-toolchain container repo, sees the clear structure — one install script per language ecosystem. She writes `install-java.sh` adding Checkstyle, SpotBugs, and JUnit tooling. She updates the Makefile with Java-specific targets following the established pattern. She submits a PR with conventional commits, the CI passes (DevRail dogfoods itself), and includes documentation updates. Matthew reviews, merges, and the next weekly container build includes Java support.

### Journey Requirements Summary

| Journey | Capabilities Revealed |
|---|---|
| **Greenfield — New Project** | Repo templates, pre-commit config, CI pipelines, Makefile contract, zero-config setup, multi-language support |
| **Brownfield — Retrofit** | Tiered adoption paths, partial adoption (agent files only), progressive layering, non-destructive setup |
| **Agent — Story Completion** | Agent instruction files, machine-readable standards, `make check` contract, conventional commit enforcement |
| **Adoption Script** | `devrail init`, problem-language UX, transparency on what gets added, idempotent re-runs |
| **Contributor — Ecosystem Growth** | Contributing guide, clear repo structure, extensible language support pattern, DevRail dogfooding |

## Innovation & Novel Patterns

### Detected Innovation Areas

- **Agent-first developer standards:** Most developer standards assume a human reader. DevRail treats autonomous AI agents as first-class consumers — standards are structured for machine readability and enforceable through a single `make check` contract
- **Universal execution contract:** The Makefile+Docker pattern creates a single interface that works identically for humans, AI agents, and CI systems. One command, three actors — no previous tool has collapsed these interfaces into one
- **Multi-tool agent instruction pattern:** Shipping CLAUDE.md, AGENTS.md, .cursorrules, and .opencode/ as standard repo scaffolding — ensuring any AI coding tool adopted in the future inherits project standards on day one. The hybrid shim pattern (one canonical source, tool-specific shims) ensures new agent platforms can be supported quickly
- **Standards-as-code ecosystem:** A canonical standards document drives all downstream artifacts (container tooling, templates, agent files). Change the standard, everything follows
- **Progressive adoption architecture:** From copying one file to full ecosystem adoption, each tier delivers immediate value without requiring the next

### Why 2026

Every previous generation of developer tooling removed human discipline from one quality concern. CI solved "did you run the tests?" Prettier solved "did you format the code?" Docker solved "works on my machine." In 2026, agents crossed the threshold from helpful autocomplete to primary code contributors. The volume of agent-written code has crossed a threshold where consistency can't be managed by prompting anymore. It needs infrastructure. DevRail is that infrastructure.

### Market Context

No established open-source project currently packages developer standards specifically for AI agent consumption:

- **Super-linter / MegaLinter:** Multi-language linting containers, but no agent instruction files, no Makefile contract, no project scaffolding
- **Cookiecutter / Copier:** Project templating that stamps out a repo and walks away. No ongoing enforcement, no agent awareness
- **trunk.io:** Developer experience layer, but SaaS/proprietary and not agent-oriented

Individual developers are solving this ad-hoc with per-repo CLAUDE.md files or manual agent prompting. DevRail is the first attempt to systematize this across tools, languages, and platforms.

### Validation Approach

Empirical validation through direct use:
- All personal projects running on DevRail (achieved)
- Agents follow standards without manual prompting (validated daily)
- Reduction in "did you run the checks?" interventions (effectively zero)
- Agent output quality and consistency before and after DevRail adoption (measurable improvement)
- Builder-is-user feedback loop keeps the platform honest — dogfooding at scale with multiple repos and real agents

## Developer Tool Specific Requirements

### Ecosystem Architecture

DevRail is delivered as a coordinated ecosystem of six repositories under `github.com/devrail-dev/`:

| Repository | Purpose | Platform |
|---|---|---|
| **devrail-standards** | Canonical standards document — source of truth for all conventions | GitHub |
| **dev-toolchain** | Docker image with all linting/security/test tools for 8 language ecosystems | GitHub (GHCR) |
| **pre-commit-conventional-commits** | Conventional commit enforcement hook | GitHub |
| **github-repo-template** | GitHub project template with full DevRail setup | GitHub |
| **gitlab-repo-template** | GitLab project template with full DevRail setup | GitLab |
| **devrail.dev** | Hugo static site hosted on Cloudflare — documentation, standards reference, blog | GitHub + Cloudflare |

### Language Support Matrix

"Supported language" means linter, formatter, security scanner, test runner, pre-commit hooks, and Makefile targets are configured and working:

| Concern | Python | Bash | Terraform | Ansible | Ruby | Go | JavaScript/TS | Rust |
|---|---|---|---|---|---|---|---|---|
| **Linter** | ruff | shellcheck | tflint | ansible-lint | rubocop, reek | golangci-lint | eslint, tsc | clippy |
| **Formatter** | ruff format | shfmt | terraform fmt, terragrunt hclfmt | — | rubocop | gofumpt | prettier | rustfmt |
| **Security** | bandit, semgrep | — | tfsec, checkov | — | brakeman, bundler-audit | govulncheck | npm audit | cargo-audit, cargo-deny |
| **Tests** | pytest | bats | terratest | molecule | rspec | go test | vitest | cargo test |
| **Type Check** | mypy | — | — | — | sorbet | — | tsc | — |
| **Docs** | — | — | terraform-docs | — | — | — | — | — |
| **Universal** | trivy, gitleaks, git-cliff | trivy, gitleaks, git-cliff | trivy, gitleaks, git-cliff | trivy, gitleaks, git-cliff | trivy, gitleaks, git-cliff | trivy, gitleaks, git-cliff | trivy, gitleaks, git-cliff | trivy, gitleaks, git-cliff |

Build targets are explicitly out of scope — every project handles builds differently.

### Makefile Target Contract

| Target | What It Runs |
|---|---|
| `make help` | Show available targets (default) |
| `make lint` | All language-appropriate linters + type checkers |
| `make format` | All language-appropriate formatters (check mode) |
| `make fix` | All language-appropriate formatters (write/fix mode) |
| `make test` | Project test suite for all declared languages |
| `make security` | Language-specific security scanners |
| `make scan` | Universal scanning (trivy, gitleaks) |
| `make docs` | Documentation generation (terraform-docs, tool versions) |
| `make changelog` | Generate CHANGELOG.md from conventional commits (git-cliff) |
| `make check` | All of the above in sequence |
| `make install-hooks` | Install pre-commit hooks |
| `make init` | Initialize project scaffolding for declared languages |
| `make release VERSION=x.y.z` | Cut a versioned release (CHANGELOG update, tag, push) |

All targets except `help`, `install-hooks`, `init`, and `release` delegate to the dev-toolchain Docker container.

### Adoption Methods

| Method | Entry Point | Barrier | Outcome |
|---|---|---|---|
| **Partial (wedge)** | Copy agent instruction files (CLAUDE.md, AGENTS.md, .cursorrules, .opencode/) | One file | Agents follow standards immediately |
| **Retrofit (brownfield)** | Add Makefile, pre-commit config, CI pipeline | Configuration | Full DevRail enforcement on existing projects |
| **Template (greenfield)** | Create repo from GitHub/GitLab template | Zero config | Everything pre-configured from first commit |
| **`devrail init` (Phase 2)** | Run adoption script | One command | Progressive adoption with transparent file-by-file disclosure |
| **Container only** | `docker pull` the dev-toolchain image | Docker pull | Use in custom workflows |

### Documentation Strategy

- **Per-repo READMEs:** Clear, concise, not verbose. What it is, how to use it, how to contribute
- **devrail.dev website:** Hugo static site hosted on Cloudflare. Project overview, getting started guide, per-language standards reference, tool version manifest, blog
- **Agent instruction files:** Machine-readable standards in CLAUDE.md, AGENTS.md, .cursorrules, .opencode/ — documentation that agents consume directly

### Implementation Considerations

- All six repos dogfood DevRail — each repo uses the same Makefile+Docker pattern, pre-commit hooks, and CI pipelines
- The dev-toolchain container is the single dependency — templates reference a pinned major version (`v1`)
- Weekly automated container builds with semver tagging enable deliberate upgrades
- Pre-commit hooks run a subset of checks locally (fast feedback); CI runs the full `make check` (authoritative)
- Two-layer Makefile delegation: public targets on host delegate to Docker, internal `_`-prefixed targets run inside the container
- `.devrail.yml` at repo root declares languages, enabling automatic tool selection

## Product Scope & Phased Development

### MVP (Shipped)

DevRail MVP is complete and in active daily use. The shipped ecosystem includes:

**All six ecosystem repositories** established and stable under `github.com/devrail-dev/`.

**8 language ecosystems:** Python, Bash, Terraform (+ Terragrunt), Ansible, Ruby, Go, JavaScript/TypeScript, Rust

**Makefile targets:** help, lint, format, fix, test, security, scan, docs, changelog, check, install-hooks, init, release

**Agent integration:** CLAUDE.md, AGENTS.md, .cursorrules, .opencode/ shipped with every template. 8 critical rules enforced.

**CI/CD:** GitHub Actions and GitLab CI pipelines, weekly automated container builds with semver releases, multi-arch support (amd64 + arm64).

**Documentation site:** devrail.dev live on Cloudflare with standards reference, getting started guide, tool version manifest, and blog.

### Phase 2a: Reduce Friction

- **`devrail init` adoption script:** Standalone, idempotent script (hosted in standards repo, downloadable via `curl`) that progressively adopts DevRail into any repo. Asks in problem language with full transparency on what files get added. No container dependency. Safe to re-run — users layer on more DevRail as they're ready.

- **Single-source template generation:** Dev-toolchain becomes the single source of truth for template Makefile internal targets. When dev-toolchain merges changes to internal targets, a CI job generates updated template Makefiles and opens PRs on both template repos automatically. Eliminates "templates fell behind dev-toolchain" drift.

### Phase 2b: Expand Reach (When Needed)

- **New language ecosystems:** Java, Elixir, C# — added when there's a real need from personal use or adoption signals. The pattern is proven and repeatable (4 languages added in 2 weeks).
- **Agent platform integrations:** Track emerging platforms and support them reactively. The hybrid shim pattern ensures new platforms can be supported quickly.
- **Documentation site refinement:** Evaluate and improve devrail.dev based on real usage patterns.

### Phase 3: Community & Platform Integration

- External contributors following the established contribution pattern
- Enterprise fork documentation and guide
- Plugin/extension architecture for custom tool additions
- If adoption grows, DevRail's configuration format (`.devrail.yml`) could serve as a standard interface between projects and agent platforms — a native way for agent tools to understand a project's standards without reading instruction files

### Risk Mitigation Strategy

**Technical Risks:** Container size grows with 8 language ecosystems — mitigated by multi-stage Docker builds and accepting that dev tooling images don't need to be slim. If container builds break, projects pin to last known good version.

**Market Risks:** Adoption depends on the agent-first value proposition being real — validated on all personal projects. Pre-commit/CI enforcement layer delivers value regardless of agent behavior.

**Resource Risks:** Solo developer with AI assistance. MVP is shipped and stable. Future phases are incremental additions, not large architectural changes.

**Innovation Risks:**
- AI tools may ignore or misinterpret agent instruction files — pre-commit hooks and CI enforce standards regardless of agent behavior
- Agent instruction file formats may change across tools — hybrid shim pattern (one canonical source, tool-specific shims) means updates are localized
- Cross-repo drift between dev-toolchain and templates — single-source generation (Phase 2a) eliminates this class of problem

## Functional Requirements

### Standards & Configuration

- **FR1:** Developer can reference a single canonical standards document that defines all linting, formatting, security, testing, and commit conventions across all supported language ecosystems
- **FR2:** AI agent can read agent instruction files (CLAUDE.md, AGENTS.md, .cursorrules, .opencode/) and determine project standards without human explanation
- **FR3:** Developer can update standards in one place and have all downstream artifacts (agent files, templates) reflect the change
- **FR4:** Developer can define per-language tooling configurations in `.devrail.yml` and the Makefile automatically selects appropriate tools

### Dev-Toolchain Container

- **FR5:** Developer can pull a single Docker image containing all linting, formatting, security, testing, and documentation tools for all 8 supported language ecosystems
- **FR6:** Developer can pin a specific container version in their project and upgrade deliberately via major-version floating tag (`v1`)
- **FR7:** Container can execute `make check` against any DevRail-compliant project and produce identical results to CI
- **FR8:** Container automatically rebuilds weekly with updated tool versions and publishes a new semver release
- **FR9:** Container includes universal scanning tools (trivy, gitleaks, git-cliff) available to all language ecosystems
- **FR10:** Container publishes a tool version manifest as a release asset, consumed by devrail.dev for automated version documentation
- **FR56:** Developer can run `make release VERSION=x.y.z` to cut a manual release — the script updates CHANGELOG.md, commits with conventional commit format, creates an annotated semver tag, and pushes to trigger the existing build and release pipelines

### Makefile Contract

- **FR11:** Developer can run `make lint` to execute all language-appropriate linters for the project
- **FR12:** Developer can run `make format` to check formatting compliance for all declared languages
- **FR13:** Developer can run `make fix` to auto-fix formatting issues for all declared languages
- **FR14:** Developer can run `make test` to execute the project's test suite
- **FR15:** Developer can run `make security` to execute language-specific security scanners
- **FR16:** Developer can run `make scan` to execute universal security scanning (trivy, gitleaks)
- **FR17:** Developer can run `make docs` to generate documentation (terraform-docs, tool version reports)
- **FR18:** Developer can run `make changelog` to generate CHANGELOG.md from conventional commits using git-cliff
- **FR19:** Developer can run `make check` to execute all targets in sequence with run-all-report-all error handling
- **FR20:** Developer can run `make init` to scaffold language-specific configuration files for declared languages
- **FR21:** All Makefile targets execute inside the dev-toolchain Docker container via two-layer delegation (public targets → Docker → internal `_` targets)
- **FR22:** Developer can enable fail-fast mode via `DEVRAIL_FAIL_FAST=1` or `.devrail.yml` setting

### Project Templates

- **FR23:** Developer can create a new GitHub repository from the DevRail GitHub template with all standards pre-configured
- **FR24:** Developer can create a new GitLab repository from the DevRail GitLab template with all standards pre-configured
- **FR25:** Templates include pre-commit hooks for conventional commits, linting, formatting, security, and documentation generation
- **FR26:** Templates include CI pipeline configuration (GitHub Actions / GitLab CI) that runs `make check` using the pinned dev-toolchain container
- **FR27:** Templates include agent instruction files (CLAUDE.md, AGENTS.md, .cursorrules, .opencode/) with critical rules inlined
- **FR28:** Templates include EditorConfig, .gitignore, PR/MR templates, and CODEOWNERS
- **FR29:** Developer can retrofit an existing repo by copying DevRail configuration files into it

### Pre-Commit Enforcement

- **FR30:** Pre-commit hooks enforce conventional commit message format on every commit
- **FR31:** Pre-commit hooks run language-appropriate linting and formatting checks before commit
- **FR32:** Pre-commit hooks run gitleaks to prevent secret leakage before commit
- **FR33:** Pre-commit hooks run terraform-docs to auto-update README documentation for Terraform projects
- **FR34:** Developer can install pre-commit hooks via `make install-hooks`
- **FR35:** Pre-push hooks run `make check` as a final gate before pushing to remote

### CI/CD Pipeline

- **FR36:** GitHub Actions pipeline runs `make check` inside the dev-toolchain container on every push and PR
- **FR37:** GitLab CI pipeline runs `make check` inside the dev-toolchain container on every push and MR
- **FR38:** *(see FR7)* CI and local environments produce identical results through shared container execution
- **FR39:** CI pipeline blocks merging if `make check` fails

### AI Agent Integration

- **FR40:** AI agent can read CLAUDE.md and determine all project conventions, required checks, and commit standards
- **FR41:** AI agent can run `make check` autonomously before marking work complete
- **FR42:** AI agent can produce conventional commits without human reminding
- **FR43:** Multiple AI tools (Claude Code, Cursor, OpenCode) can consume the same standards through tool-specific instruction files
- **FR44:** BMAD planning agents can incorporate DevRail standards into architecture and planning artifacts when instructed

### Documentation Site

- **FR45:** Visitor can view DevRail project overview, getting started guide, per-language standards reference, and tool version manifest on devrail.dev
- **FR46:** Documentation site is generated from markdown using Hugo and hosted on Cloudflare
- **FR47:** Tool version manifest is automatically updated from dev-toolchain release assets via CI
- **FR48:** Contributor can find contribution guidelines for each repo in the ecosystem

### Contributor Experience

- **FR49:** Contributor can add a new language ecosystem by following the established pattern (install script + Makefile targets + pre-commit config + standards doc)
- **FR50:** All DevRail repos dogfood their own standards (same Makefile, pre-commit, CI pipeline pattern)
- **FR51:** Contributor can submit PRs with conventional commits and have CI validate them automatically

---

### Phase 2 Features

- **FR52:** Developer can run `devrail init` to progressively adopt DevRail into an existing repo with transparent, problem-language prompts
- **FR53:** `devrail init` detects existing configuration and prompts before overwriting — no silent overrides
- **FR54:** `devrail init` is idempotent — safe to re-run to layer on additional DevRail capabilities
- **FR55:** Template Makefile internal targets are generated from dev-toolchain source of truth via CI, with automated PRs to template repos on change

## Non-Functional Requirements

### Performance

- `make check` completes in under 5 minutes for a typical project (< 10,000 LOC)
- Individual targets (`make lint`, `make format`) complete in under 60 seconds for typical projects
- Pre-commit hooks complete in under 30 seconds to avoid disrupting developer flow
- Dev-toolchain container image pull time is acceptable for CI cold starts (target < 2 minutes on standard runners)

### Security

- Dev-toolchain container is built from trusted, pinned base images (Debian bookworm)
- Container builds run trivy self-scan — the container must pass its own security scanning
- No secrets, credentials, or tokens are baked into the container image
- GHCR image signing for supply chain verification

### Reliability

- Weekly container builds succeed consistently — build failures are detected and reported automatically
- Semver tagging ensures projects pinning to a version are never broken by a new release
- Major-version floating tag (`v1`) propagates non-breaking updates automatically
- Pre-commit hooks fail gracefully — a hook failure produces a clear error message, not a cryptic stack trace
- CI pipelines fail fast with actionable output

### Compatibility

- Dev-toolchain container runs on linux/amd64 and linux/arm64 (covers CI runners and Apple Silicon Macs)
- Makefile targets work on Linux and macOS host systems
- Pre-commit hooks are compatible with pre-commit framework v3+
- Templates work with Git 2.28+ (for `init.defaultBranch` support)
- Container supports 8 language toolchains concurrently without version conflicts

### Integration

- Container images published to GitHub Container Registry (ghcr.io/devrail-dev/)
- GitHub Actions workflows use standard GitHub-hosted runners
- GitLab CI pipelines use standard GitLab shared runners
- Pre-commit hooks compatible with the pre-commit framework ecosystem
- Conventional commit hook integrates with `pre-commit-conventional-commits` repo
- Hugo Docsy theme via Hugo modules for documentation site

### Documentation Accessibility

- devrail.dev meets WCAG 2.1 Level A minimum
- All documentation is navigable without JavaScript (Hugo static generation)
- Code examples include sufficient context to be understood without surrounding text
