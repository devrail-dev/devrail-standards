---
stepsCompleted: [step-01-init, step-02-discovery, step-02b-vision, step-02c-executive-summary, step-03-success, step-04-journeys, step-05-domain, step-06-innovation, step-07-project-type, step-08-scoping, step-09-functional, step-10-nonfunctional, step-11-polish, step-12-complete]
githubOrg: devrail-dev
inputDocuments: []
workflowType: 'prd'
projectName: DevRail
projectDomain: devrail.dev
documentCounts:
  briefs: 0
  research: 0
  brainstorming: 0
  projectDocs: 0
classification:
  projectType: developer_tool
  domain: general
  complexity: medium
  projectContext: greenfield
---

# Product Requirements Document - DevRail

**Author:** Matthew
**Date:** 2026-02-18

## Executive Summary

DevRail is an open-source developer infrastructure platform that eliminates per-project setup tax and enforces consistent quality gates across all repositories — whether the code is written by humans or autonomous AI agents. It provides a single, canonical set of standards backed by a universal Makefile+Docker contract, pre-built CI pipelines for GitHub Actions and GitLab CI, and machine-readable agent instruction files that ensure every AI coding tool follows the same rules without human supervision.

The platform targets individual developers and small teams managing multiple repositories across Python, Bash, Terraform, and Ansible (MVP), with Rails and Go planned for post-MVP growth. It solves the repo sprawl problem: inconsistent linting, ad-hoc security scanning, missing pre-commit hooks, and agents that need constant reminding to run checks. By standardizing these concerns once and distributing them through project templates and a shared dev-toolchain container, every new project starts correct and stays correct.

### What Makes This Special

Most developer standards are written for humans to read. DevRail is designed for autonomous AI agents to execute. The Makefile+Docker contract provides a single interface (`make check`) that works identically in local development, CI pipelines, and agent-driven workflows. Agent instruction files (CLAUDE.md, AGENTS.md, .cursorrules, .opencode/) ship with every template, meaning any AI tool adopted in the future already knows the rules on day one.

The core insight: as AI agents become primary code contributors, the developer standards problem is no longer about human discipline — it's about giving autonomous agents enforceable, unambiguous rules that produce consistent, quality work without supervision. DevRail bridges that gap.

The ecosystem consists of six repositories under `github.com/devrail-dev/`: a canonical standards document, a versioned dev-toolchain Docker container, a conventional commits pre-commit hook (existing), project templates for both GitHub and GitLab, and a Hugo documentation site at devrail.dev.

## Success Criteria

### User Success

- **"Point and it works" standard:** Any AI agent (BMAD, OpenClaw, Claude Code, Cursor) given a link to DevRail follows the standards without additional explanation or reminding
- **BMAD planning integration:** When told to use DevRail during project planning, agents incorporate standards into architecture docs and planning artifacts. Downstream implementation agents inherit the behavior automatically
- **Zero-config new projects:** Using a repo template produces a fully configured project — pre-commit hooks, Makefile, Dockerfile, CI pipeline, .gitignore, EditorConfig — on first use. First commit triggers checks. First push triggers CI
- **Agent autonomy:** Agents run `make check` before completing stories without being asked. Conventional commits enforced automatically via pre-commit

### Business Success

- **3-month target:** All personal projects running on DevRail. Six ecosystem repos established and stable. Every repo passes `make check`
- **12-month target:** Public profile demonstrates platform thinking. Other developers adopting DevRail. If platform lead role materializes, DevRail is ready to fork for internal company use
- **Adoption signal:** GitHub stars, forks, and external contributors as indicators of community value

### Technical Success

- **Consistency guarantee:** Local checks and CI checks produce identical results (Docker-based execution)
- **Container reliability:** Dev-toolchain container builds weekly with versioned releases. Projects pin to specific versions and upgrade deliberately
- **Cross-platform parity:** GitHub Actions and GitLab CI pipelines run the same checks via the same Makefile targets
- **Language coverage:** Linting, formatting, security scanning, and testing standardized for every supported language

### Measurable Outcomes

- 100% of new projects created from DevRail templates
- 0 repos without linting, security scanning, or CI after 3 months
- Agents complete stories with `make check` passing — no human follow-up required
- Time from "new project idea" to "first passing CI" measured in minutes, not hours

## User Journeys

### Journey 1: Matthew — New Project Kickoff

Matthew has an idea for a new homelab service. He opens GitLab, clicks "New Project," selects the DevRail template for Python. The repo appears with a Makefile, Dockerfile, pre-commit config, GitLab CI pipeline, .gitignore, EditorConfig, agent instruction files — everything. He clones it, writes his first module, runs `git commit`. Pre-commit fires: ruff, conventional commit format check. It all passes. He pushes. GitLab CI runs `make check` inside the dev-toolchain container. Green pipeline. He spent zero time on setup. He's writing business logic within minutes of having the idea.

For a Terraform project, he selects the DevRail Terraform template. He writes a module, commits. Pre-commit fires: `terraform fmt`, `tflint`, `terraform-docs`. The README automatically updates with his module's inputs, outputs, and resources. He never wrote a line of documentation. It just happened.

Three months later he looks across his repos. Every single one has the same structure, same checks, same CI. He upgrades the dev-toolchain container version in one place and rolls it out. No snowflakes. No surprises.

### Journey 2: AI Agent — Story Completion

A BMAD implementation agent is working through a story on Matthew's project. The agent reads `CLAUDE.md` in the repo root, which points to the DevRail standards. It knows: conventional commits required, `make check` must pass before marking a story complete. The agent writes code, commits with `feat: add user authentication endpoint`, and runs `make check`. Ruff catches a formatting issue. The agent fixes it, re-runs, gets green. Story marked complete. Matthew never had to say "did you run the checks?" — the agent already knew.

An OpenClaw instance picks up a different task on the same repo. It reads `AGENTS.md`, sees the same standards. Same behavior. Different tool, identical outcome.

### Journey 3: CI Pipeline — Enforcement Gate

A developer pushes code to a DevRail-templated repo on GitHub. GitHub Actions triggers. The workflow pulls the pinned dev-toolchain container (`ghcr.io/devrail-dev/dev-toolchain:v1.4.0`), mounts the workspace, and runs `make check`. Linting, formatting, security scanning, tests — all execute in the same container that ran locally. The results are identical to what the developer (or agent) saw on their machine. If it passed locally, it passes in CI. If it fails, the failure is real — not an environment mismatch. The PR gets a red check, the developer fixes it, and the cycle repeats.

### Journey 4: New Adopter — Discovery and Adoption

A developer named Sarah is drowning in repo sprawl. She's got 15 side projects, each with different linting setups — some have none at all. She's started using Claude Code and Cursor but keeps forgetting to tell them about her project conventions. She finds DevRail on GitHub, reads the README, and sees: one Makefile contract, one Docker container, templates for GitHub and GitLab, agent instruction files included. She uses the GitHub template for her next project. First commit, pre-commit hooks fire. First push, CI passes. She realizes she can retrofit her existing repos by copying the Makefile, Dockerfile reference, and agent instruction files. Within a week, her most active repos are standardized. She stars the repo and tells a colleague.

### Journey 5: Contributor — Improving the Ecosystem

A Go developer named Alex has been using DevRail for Python and Terraform projects and wants Go support. He checks the dev-toolchain container repo, sees the clear structure — one install script per language ecosystem. He writes `go.sh` adding golangci-lint, gosec, and go test tooling. He updates the Makefile template with Go-specific targets following the established pattern. He submits a PR with conventional commits, the CI passes (DevRail eats its own dog food), and includes documentation updates. Matthew reviews, merges, and the next weekly container build includes Go support. Alex updates his Go projects to the new container version and they're on the rails.

### Journey Requirements Summary

| Journey | Capabilities Revealed |
|---|---|
| **Matthew — New Project** | Repo templates, pre-commit config, CI pipelines, Makefile contract, zero-config setup, auto-generated Terraform docs |
| **AI Agent — Story Completion** | Agent instruction files, machine-readable standards, `make check` contract, conventional commit enforcement |
| **CI Pipeline — Enforcement** | Docker-based execution, pinned container versions, cross-platform CI parity, identical local/remote results |
| **New Adopter — Discovery** | Clear documentation/README, easy template adoption, retrofit path for existing repos, onboarding experience |
| **Contributor — Ecosystem Growth** | Contributing guide, clear repo structure, extensible language support pattern, DevRail self-hosting (dogfooding) |

## Innovation & Novel Patterns

### Detected Innovation Areas

- **Agent-first developer standards:** Most developer standards assume a human reader. DevRail treats autonomous AI agents as first-class consumers — standards are structured for machine readability and enforceable through a single `make check` contract
- **Universal execution contract:** The Makefile+Docker pattern creates a single interface that works identically for humans, AI agents, and CI systems. No environment-specific behavior, no "works on my machine"
- **Multi-tool agent instruction pattern:** Shipping CLAUDE.md, AGENTS.md, .cursorrules, and .opencode/ as standard repo scaffolding — ensuring any AI coding tool adopted in the future inherits project standards on day one
- **Standards-as-code ecosystem:** A canonical standards document drives all downstream artifacts (container tooling, templates, agent files). Change the standard, everything follows

### Market Context

No established open-source project currently packages developer standards specifically for AI agent consumption. Individual developers are solving this ad-hoc with per-repo CLAUDE.md files or manual agent prompting. DevRail is the first attempt to systematize this across tools, languages, and platforms.

### Validation Approach

Empirical validation through direct use:
- Deploy DevRail across all personal projects
- Measure whether agents (BMAD, OpenClaw, Claude Code, Cursor) follow standards without manual prompting
- Track reduction in "did you run the checks?" interventions
- Compare agent output quality and consistency before and after DevRail adoption
- Success = agents behave correctly by default, not by reminder

## Developer Tool Specific Requirements

### Ecosystem Architecture

DevRail is delivered as a coordinated ecosystem of six repositories under `github.com/devrail-dev/`:

| Repository | Purpose | Platform |
|---|---|---|
| **devrail-standards** | Canonical standards document — source of truth | GitHub |
| **dev-toolchain** | Docker image with all linting/security/test tools | GitHub (GHCR) |
| **pre-commit-conventional-commits** | Conventional commit enforcement hook (existing) | GitHub |
| **github-repo-template** | GitHub project template with full DevRail setup | GitHub |
| **gitlab-repo-template** | GitLab project template with full DevRail setup | GitLab |
| **devrail.dev** | Hugo static site hosted on Cloudflare — project overview and guides | GitHub + Cloudflare |

### Language Support Matrix

"Supported language" means the following are configured and working:

| Concern | Python | Bash | Terraform | Ansible |
|---|---|---|---|---|
| **Linter** | ruff | shellcheck | tflint | ansible-lint |
| **Formatter** | ruff format | shfmt | terraform fmt | — |
| **Security** | bandit/semgrep | — | tfsec/checkov | — |
| **Tests** | pytest | bats | terratest | molecule |
| **Type Check** | mypy | — | — | — |
| **Docs** | — | — | terraform-docs | — |
| **Universal** | trivy, gitleaks | trivy, gitleaks | trivy, gitleaks | trivy, gitleaks |

Each language gets: linter config, formatter config, security scanner config, test runner config, pre-commit hooks, and Makefile targets. Build targets are explicitly out of scope — every project handles builds differently.

### Adoption Methods

1. **New project (primary):** Create repo from GitHub/GitLab template — zero-config, everything works immediately
2. **Existing project (retrofit):** Copy Makefile, Dockerfile reference, pre-commit config, agent instruction files, EditorConfig, .gitignore into existing repo
3. **Container only:** `docker pull` the dev-toolchain image for use in custom workflows

No CLI tool or setup script for MVP. Templates and file copying are the right level of simplicity.

### Documentation Strategy

- **Per-repo READMEs:** Clear, concise, not verbose. What it is, how to use it, how to contribute
- **devrail.dev website:** Hugo static site hosted on Cloudflare. Project overview, getting started guide, language support reference, contribution guide
- **Agent instruction files:** Machine-readable standards in CLAUDE.md, AGENTS.md, .cursorrules, .opencode/ — documentation that agents consume directly

### Implementation Considerations

- All six repos dogfood DevRail — each repo uses the same Makefile+Docker pattern, pre-commit hooks, and CI pipelines
- The dev-toolchain container is the single dependency — templates reference a pinned version
- Weekly automated container builds with semver tagging enable deliberate upgrades
- Pre-commit hooks run a subset of checks locally (fast feedback); CI runs the full `make check` (authoritative)

## Project Scoping & Phased Development

### MVP Strategy & Philosophy

**MVP Approach:** Platform MVP — all ecosystem components ship together because the value is in the connected system, not individual repos. Implementation is sequenced to unblock downstream work, with the documentation site last.

**Resource Requirements:** Solo developer (Matthew) with AI agent assistance via BMAD and other tools.

**GitHub Organization:** `github.com/devrail-dev/` — all public repos live under this org. Container images at `ghcr.io/devrail-dev/`.

### MVP Feature Set (Phase 1)

**Implementation Sequence:**

1. **devrail-standards** — write the canonical standards document first. Everything references this.
2. **dev-toolchain container** — build the Docker image with all MVP language tools. This unblocks everything else.
3. **pre-commit-conventional-commits** — already exists. Verify compatibility, update if needed.
4. **gitlab-repo-template** — primary development platform. First template to validate the pattern.
5. **github-repo-template** — second template, same pattern adapted for GitHub Actions.
6. **devrail.dev** — Hugo site on Cloudflare. Last because READMEs carry the load until the site exists.

**Must-Have Capabilities:**
- Makefile+Docker contract (`make lint`, `make format`, `make test`, `make security`, `make scan`, `make docs`, `make check`)
- Pre-commit hooks: conventional commits, linting, formatting, security, terraform-docs
- CI pipelines for both GitHub Actions and GitLab CI
- Agent instruction files: CLAUDE.md, AGENTS.md, .cursorrules, .opencode/
- Language support: Python, Bash, Terraform, Ansible
- EditorConfig, .gitignore, PR/MR templates, CODEOWNERS
- Dev-toolchain container with weekly builds and semver releases

### Phase 2 (Growth)

- Rails language support
- Go language support
- New adopter onboarding improvements based on feedback
- Retrofit guide for existing repos
- Community contribution workflows

### Phase 3 (Expansion)

- Additional language ecosystems as demand emerges
- Plugin/extension architecture for custom tool additions
- Enterprise fork documentation and guide
- Integration with CI/CD platforms beyond GitHub and GitLab
- Expanded agent tool support as new AI coding tools emerge

### Risk Mitigation Strategy

**Technical Risks:** Container size may grow large with four language ecosystems — mitigated by multi-stage Docker builds and accepting that dev tooling images don't need to be slim. If container builds break, projects pin to last known good version.

**Market Risks:** Adoption depends on the agent-first value proposition being real — mitigated by validating on Matthew's own projects first. If agents don't meaningfully change behavior from instruction files, the pre-commit/CI enforcement layer still delivers value.

**Resource Risks:** Solo developer with AI assistance. If scope proves too large, the implementation sequence allows shipping standards + container + GitLab template as a functional minimum. GitHub template and site can follow.

**Innovation Risks:**
- AI tools may ignore or misinterpret agent instruction files — pre-commit hooks and CI enforce standards regardless of agent behavior. The contract is enforced at commit time, not at agent discretion.
- Agent instruction file formats may change across tools — thin shim pattern (one canonical source, tool-specific shims) means updates are localized.
- Standards may be too rigid for diverse project needs — start with Matthew's own projects as proving ground before wider release.

## Functional Requirements

### Standards & Configuration

- **FR1:** Developer can reference a single canonical standards document that defines all linting, formatting, security, testing, and commit conventions
- **FR2:** AI agent can read agent instruction files (CLAUDE.md, AGENTS.md, .cursorrules, .opencode/) and determine project standards without human explanation
- **FR3:** Developer can update standards in one place and have all downstream artifacts (agent files, templates) reflect the change
- **FR4:** Developer can define per-language tooling configurations (linter, formatter, security scanner, test runner) in the standards document

### Dev-Toolchain Container

- **FR5:** Developer can pull a single Docker image containing all linting, formatting, security, testing, and documentation tools for all supported languages
- **FR6:** Developer can pin a specific container version in their project and upgrade deliberately
- **FR7:** Container can execute `make check` against any DevRail-compliant project and produce identical results to CI
- **FR8:** Container automatically rebuilds weekly with updated tool versions and publishes a new semver release
- **FR9:** Container includes universal scanning tools (trivy, gitleaks) available to all language ecosystems

### Makefile Contract

- **FR10:** Developer can run `make lint` to execute all language-appropriate linters for the project
- **FR11:** Developer can run `make format` to execute all language-appropriate formatters for the project
- **FR12:** Developer can run `make test` to execute the project's test suite
- **FR13:** Developer can run `make security` to execute language-specific security scanners
- **FR14:** Developer can run `make scan` to execute universal security scanning (trivy, gitleaks)
- **FR15:** Developer can run `make docs` to generate documentation (e.g., terraform-docs for Terraform projects)
- **FR16:** Developer can run `make check` to execute all of the above targets in sequence
- **FR17:** All Makefile targets execute inside the dev-toolchain Docker container, ensuring environment consistency

### Project Templates

- **FR18:** Developer can create a new GitHub repository from the DevRail GitHub template with all standards pre-configured
- **FR19:** Developer can create a new GitLab repository from the DevRail GitLab template with all standards pre-configured
- **FR20:** Templates include pre-commit hooks for conventional commits, linting, formatting, security, and documentation generation
- **FR21:** Templates include CI pipeline configuration (GitHub Actions / GitLab CI) that runs `make check` using the pinned dev-toolchain container
- **FR22:** Templates include agent instruction files (CLAUDE.md, AGENTS.md, .cursorrules, .opencode/) pointing to DevRail standards
- **FR23:** Templates include EditorConfig, .gitignore, PR/MR templates, and CODEOWNERS
- **FR24:** Developer can retrofit an existing repo by copying DevRail configuration files into it

### Pre-Commit Enforcement

- **FR25:** Pre-commit hooks enforce conventional commit message format on every commit
- **FR26:** Pre-commit hooks run language-appropriate linting and formatting checks before commit
- **FR27:** Pre-commit hooks run gitleaks to prevent secret leakage before commit
- **FR28:** Pre-commit hooks run terraform-docs to auto-update README documentation for Terraform projects
- **FR29:** Developer can install pre-commit hooks via `make install-hooks` or equivalent setup target

### CI/CD Pipeline

- **FR30:** GitHub Actions pipeline runs `make check` inside the dev-toolchain container on every push and PR
- **FR31:** GitLab CI pipeline runs `make check` inside the dev-toolchain container on every push and MR
- **FR32:** CI results are identical to local `make check` results (same container, same tools, same config)
- **FR33:** CI pipeline blocks merging if `make check` fails

### AI Agent Integration

- **FR34:** AI agent can read CLAUDE.md and determine all project conventions, required checks, and commit standards
- **FR35:** AI agent can run `make check` autonomously before marking a story complete
- **FR36:** AI agent can produce conventional commits without human reminding
- **FR37:** BMAD planning agents can incorporate DevRail standards into architecture and planning artifacts when instructed
- **FR38:** Multiple AI tools (Claude Code, Cursor, OpenCode) can consume the same standards through tool-specific instruction files

### Documentation Site

- **FR39:** Visitor can view the DevRail project overview, getting started guide, and language support reference on devrail.dev
- **FR40:** Documentation site is generated from markdown using Hugo and hosted on Cloudflare
- **FR41:** Contributor can find contribution guidelines for each repo in the ecosystem

### Contributor Experience

- **FR42:** Contributor can add a new language ecosystem by following the established pattern (install script + Makefile targets + pre-commit config)
- **FR43:** All DevRail repos dogfood their own standards (same Makefile, pre-commit, CI pipeline pattern)
- **FR44:** Contributor can submit PRs with conventional commits and have CI validate them automatically

## Non-Functional Requirements

### Performance

- `make check` completes in under 5 minutes for a typical project (< 10,000 LOC)
- Individual targets (`make lint`, `make format`) complete in under 60 seconds for typical projects
- Pre-commit hooks complete in under 30 seconds to avoid disrupting developer flow
- Dev-toolchain container image pull time is acceptable for CI cold starts (target < 2 minutes on standard runners)

### Security

- Dev-toolchain container is built from trusted, pinned base images
- Container builds run trivy self-scan — the container must pass its own security scanning
- No secrets, credentials, or tokens are baked into the container image
- GHCR image signing for supply chain verification

### Reliability

- Weekly container builds succeed consistently — build failures are detected and reported automatically
- Semver tagging ensures projects pinning to a version are never broken by a new release
- Pre-commit hooks fail gracefully — a hook failure should produce a clear error message, not a cryptic stack trace
- CI pipelines fail fast with actionable output

### Compatibility

- Dev-toolchain container runs on linux/amd64 and linux/arm64 (covers CI runners and Apple Silicon Macs)
- Makefile targets work on Linux and macOS host systems
- Pre-commit hooks are compatible with pre-commit framework v3+
- Templates work with Git 2.28+ (for `init.defaultBranch` support)

### Integration

- Container images published to GitHub Container Registry (ghcr.io/devrail-dev/)
- GitHub Actions workflows use standard GitHub-hosted runners
- GitLab CI pipelines use standard GitLab shared runners
- Pre-commit hooks compatible with the pre-commit framework ecosystem
- Conventional commit hook integrates with Matthew's existing `pre-commit-conventional-commits` repo

### Documentation Accessibility

- devrail.dev meets WCAG 2.1 Level A minimum
- All documentation is navigable without JavaScript (Hugo static generation)
- Code examples include sufficient context to be understood without surrounding text
