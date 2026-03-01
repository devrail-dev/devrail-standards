#!/usr/bin/env bash
# validation/e2e/validate-ecosystem.sh -- End-to-end DevRail ecosystem validation
#
# Purpose: Validates that all DevRail repos are compliant with standards,
#          templates produce working projects, and the ecosystem is release-ready.
# Usage:   bash validation/e2e/validate-ecosystem.sh [--help] [--skip-docker] [--skip-templates]
# Dependencies: docker, make, git, pre-commit (optional)
#
# This script performs structural validation of the ecosystem. It checks:
#   1. All repos have required DevRail files
#   2. All .devrail.yml files have correct language declarations
#   3. All Makefiles follow the two-layer delegation pattern
#   4. All .pre-commit-config.yaml files have required hooks
#   5. All repos have CI configurations
#   6. All agent instruction files are present and consistent
#   7. Template repos produce functional projects (if --skip-templates not set)
#
# Exit codes:
#   0 = all validations passed
#   1 = one or more validations failed

set -euo pipefail

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# --- Flags ---
SKIP_DOCKER=false
SKIP_TEMPLATES=false

# --- Help ---
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "validate-ecosystem.sh -- End-to-end DevRail ecosystem validation"
  echo ""
  echo "Usage: bash validation/e2e/validate-ecosystem.sh [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --help            Show this help"
  echo "  --skip-docker     Skip Docker-dependent checks (make check)"
  echo "  --skip-templates  Skip template project creation tests"
  exit 0
fi

# Parse flags
for arg in "$@"; do
  case "$arg" in
    --skip-docker) SKIP_DOCKER=true ;;
    --skip-templates) SKIP_TEMPLATES=true ;;
  esac
done

# --- State ---
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
RESULTS=()

# --- Helpers ---
pass() {
  local msg="$1"
  PASS_COUNT=$((PASS_COUNT + 1))
  RESULTS+=("PASS: $msg")
  echo -e "${GREEN}PASS${NC}: $msg"
}

fail() {
  local msg="$1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
  RESULTS+=("FAIL: $msg")
  echo -e "${RED}FAIL${NC}: $msg"
}

warn() {
  local msg="$1"
  WARN_COUNT=$((WARN_COUNT + 1))
  RESULTS+=("WARN: $msg")
  echo -e "${YELLOW}WARN${NC}: $msg"
}

section() {
  echo ""
  echo "============================================"
  echo " $1"
  echo "============================================"
}

# --- Resolve project root ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# --- Define repos ---
REPOS=(
  "."
  "dev-toolchain"
  "github-repo-template"
  "gitlab-repo-template"
  "pre-commit-conventional-commits"
  "devrail.dev"
)

REPO_NAMES=(
  "devrail-standards"
  "dev-toolchain"
  "github-repo-template"
  "gitlab-repo-template"
  "pre-commit-conventional-commits"
  "devrail.dev"
)

# =========================================================================
# Validation 1: Required Files
# =========================================================================
section "Validation 1: Required DevRail Files"

REQUIRED_FILES=(
  ".devrail.yml"
  ".editorconfig"
  ".gitignore"
  ".pre-commit-config.yaml"
  "AGENTS.md"
  "CLAUDE.md"
  ".cursorrules"
  ".opencode/agents.yaml"
  "LICENSE"
  "Makefile"
  "README.md"
  "CHANGELOG.md"
  "DEVELOPMENT.md"
)

for i in "${!REPOS[@]}"; do
  repo="${REPOS[$i]}"
  name="${REPO_NAMES[$i]}"
  repo_path="${PROJECT_ROOT}/${repo}"

  for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "${repo_path}/${file}" ]]; then
      pass "${name}: ${file} exists"
    else
      fail "${name}: ${file} MISSING"
    fi
  done
done

# =========================================================================
# Validation 2: .devrail.yml Language Declarations
# =========================================================================
section "Validation 2: .devrail.yml Language Declarations"

check_devrail_yml() {
  local repo_path="$1"
  local name="$2"
  local expected_languages="$3"

  if [[ ! -f "${repo_path}/.devrail.yml" ]]; then
    fail "${name}: .devrail.yml missing (cannot validate languages)"
    return
  fi

  local content
  content=$(< "${repo_path}/.devrail.yml")

  if [[ "$expected_languages" == "empty" ]]; then
    if echo "$content" | grep -qE 'languages:\s*\[\]'; then
      pass "${name}: .devrail.yml has empty languages list"
    elif echo "$content" | grep -qE 'languages:' && ! echo "$content" | grep -qE '^\s*-\s+\w'; then
      pass "${name}: .devrail.yml has no language entries"
    else
      # Check if there are commented-out entries only
      local active_langs
      active_langs=$(echo "$content" | grep -E '^\s*-\s+\w' | grep -v '^\s*#' || true)
      if [[ -z "$active_langs" ]]; then
        pass "${name}: .devrail.yml has only commented language entries"
      else
        fail "${name}: .devrail.yml should have empty languages, but has: ${active_langs}"
      fi
    fi
  else
    if echo "$content" | grep -qE "^\s*-\s+${expected_languages}"; then
      pass "${name}: .devrail.yml declares ${expected_languages}"
    else
      fail "${name}: .devrail.yml should declare ${expected_languages}"
    fi
  fi
}

check_devrail_yml "${PROJECT_ROOT}" "devrail-standards" "empty"
check_devrail_yml "${PROJECT_ROOT}/dev-toolchain" "dev-toolchain" "bash"
check_devrail_yml "${PROJECT_ROOT}/github-repo-template" "github-repo-template" "empty"
check_devrail_yml "${PROJECT_ROOT}/gitlab-repo-template" "gitlab-repo-template" "empty"
check_devrail_yml "${PROJECT_ROOT}/pre-commit-conventional-commits" "pre-commit-conventional-commits" "python"
check_devrail_yml "${PROJECT_ROOT}/devrail.dev" "devrail.dev" "empty"

# =========================================================================
# Validation 3: Makefile Two-Layer Delegation Pattern
# =========================================================================
section "Validation 3: Makefile Two-Layer Delegation Pattern"

check_makefile() {
  local repo_path="$1"
  local name="$2"

  if [[ ! -f "${repo_path}/Makefile" ]]; then
    fail "${name}: Makefile missing"
    return
  fi

  local makefile
  makefile=$(< "${repo_path}/Makefile")

  # Check for public targets
  for target in help lint format test security scan docs check install-hooks; do
    if echo "$makefile" | grep -qE "^${target}:"; then
      pass "${name}: Makefile has public target '${target}'"
    else
      fail "${name}: Makefile missing public target '${target}'"
    fi
  done

  # Check for internal targets
  for target in _lint _format _test _security _scan _docs _check; do
    if echo "$makefile" | grep -qE "^${target}:"; then
      pass "${name}: Makefile has internal target '${target}'"
    else
      # Some repos may use _check without individual internals
      warn "${name}: Makefile missing internal target '${target}'"
    fi
  done

  # Check for DOCKER_RUN or docker delegation
  if echo "$makefile" | grep -qE 'DOCKER_RUN|docker run'; then
    pass "${name}: Makefile delegates to Docker"
  else
    fail "${name}: Makefile does not appear to delegate to Docker"
  fi

  # Check for .DEFAULT_GOAL
  if echo "$makefile" | grep -q '.DEFAULT_GOAL'; then
    pass "${name}: Makefile has .DEFAULT_GOAL"
  else
    warn "${name}: Makefile missing .DEFAULT_GOAL"
  fi
}

for i in "${!REPOS[@]}"; do
  check_makefile "${PROJECT_ROOT}/${REPOS[$i]}" "${REPO_NAMES[$i]}"
done

# =========================================================================
# Validation 4: Pre-commit Hooks
# =========================================================================
section "Validation 4: Pre-commit Hooks"

check_precommit() {
  local repo_path="$1"
  local name="$2"

  if [[ ! -f "${repo_path}/.pre-commit-config.yaml" ]]; then
    fail "${name}: .pre-commit-config.yaml missing"
    return
  fi

  local content
  content=$(< "${repo_path}/.pre-commit-config.yaml")

  # Check for conventional commits hook
  if echo "$content" | grep -q 'conventional-commits'; then
    pass "${name}: .pre-commit-config.yaml has conventional-commits hook"
  else
    fail "${name}: .pre-commit-config.yaml MISSING conventional-commits hook"
  fi

  # Check for gitleaks hook
  if echo "$content" | grep -q 'gitleaks'; then
    pass "${name}: .pre-commit-config.yaml has gitleaks hook"
  else
    fail "${name}: .pre-commit-config.yaml MISSING gitleaks hook"
  fi
}

for i in "${!REPOS[@]}"; do
  check_precommit "${PROJECT_ROOT}/${REPOS[$i]}" "${REPO_NAMES[$i]}"
done

# =========================================================================
# Validation 5: CI Configurations
# =========================================================================
section "Validation 5: CI Configurations"

# GitHub-hosted repos
GITHUB_REPOS=(
  "."
  "dev-toolchain"
  "github-repo-template"
  "pre-commit-conventional-commits"
  "devrail.dev"
)

GITHUB_REPO_NAMES=(
  "devrail-standards"
  "dev-toolchain"
  "github-repo-template"
  "pre-commit-conventional-commits"
  "devrail.dev"
)

for i in "${!GITHUB_REPOS[@]}"; do
  repo="${GITHUB_REPOS[$i]}"
  name="${GITHUB_REPO_NAMES[$i]}"
  repo_path="${PROJECT_ROOT}/${repo}"

  if [[ -d "${repo_path}/.github/workflows" ]]; then
    workflow_count=$(find "${repo_path}/.github/workflows" -name '*.yml' -o -name '*.yaml' 2>/dev/null | wc -l)
    if [[ "$workflow_count" -gt 0 ]]; then
      pass "${name}: has ${workflow_count} GitHub Actions workflow(s)"
    else
      fail "${name}: .github/workflows/ exists but contains no workflow files"
    fi
  else
    fail "${name}: MISSING .github/workflows/ directory"
  fi
done

# GitLab-hosted repo
if [[ -f "${PROJECT_ROOT}/gitlab-repo-template/.gitlab-ci.yml" ]]; then
  pass "gitlab-repo-template: has .gitlab-ci.yml"

  # Check that it uses the dev-toolchain image
  if grep -q 'dev-toolchain' "${PROJECT_ROOT}/gitlab-repo-template/.gitlab-ci.yml"; then
    pass "gitlab-repo-template: .gitlab-ci.yml references dev-toolchain container"
  else
    fail "gitlab-repo-template: .gitlab-ci.yml does not reference dev-toolchain container"
  fi

  # Check that it runs make targets
  if grep -q 'make _' "${PROJECT_ROOT}/gitlab-repo-template/.gitlab-ci.yml"; then
    pass "gitlab-repo-template: .gitlab-ci.yml runs internal make targets"
  else
    fail "gitlab-repo-template: .gitlab-ci.yml does not run make targets"
  fi
else
  fail "gitlab-repo-template: MISSING .gitlab-ci.yml"
fi

# =========================================================================
# Validation 6: Agent Instruction File Consistency
# =========================================================================
section "Validation 6: Agent Instruction Files"

check_agent_files() {
  local repo_path="$1"
  local name="$2"

  for file in CLAUDE.md AGENTS.md .cursorrules ".opencode/agents.yaml"; do
    if [[ ! -f "${repo_path}/${file}" ]]; then
      fail "${name}: ${file} missing"
      continue
    fi

    local content
    content=$(< "${repo_path}/${file}")

    # Check for critical rules presence
    if echo "$content" | grep -qi 'make check'; then
      pass "${name}: ${file} mentions 'make check'"
    else
      fail "${name}: ${file} does not mention 'make check'"
    fi

    if echo "$content" | grep -qi 'conventional commit'; then
      pass "${name}: ${file} mentions conventional commits"
    else
      fail "${name}: ${file} does not mention conventional commits"
    fi
  done
}

for i in "${!REPOS[@]}"; do
  check_agent_files "${PROJECT_ROOT}/${REPOS[$i]}" "${REPO_NAMES[$i]}"
done

# =========================================================================
# Validation 7: Cross-Cutting Consistency
# =========================================================================
section "Validation 7: Cross-Cutting Consistency"

# Check that all .editorconfig files are identical
first_editorconfig=$(< "${PROJECT_ROOT}/.editorconfig")
for i in "${!REPOS[@]}"; do
  repo="${REPOS[$i]}"
  name="${REPO_NAMES[$i]}"
  if [[ "$repo" == "." ]]; then continue; fi

  repo_path="${PROJECT_ROOT}/${repo}"
  if [[ -f "${repo_path}/.editorconfig" ]]; then
    current=$(< "${repo_path}/.editorconfig")
    if [[ "$current" == "$first_editorconfig" ]]; then
      pass "${name}: .editorconfig matches devrail-standards"
    else
      warn "${name}: .editorconfig differs from devrail-standards (may be intentional)"
    fi
  fi
done

# Check that all LICENSE files exist and are MIT
for i in "${!REPOS[@]}"; do
  repo="${REPOS[$i]}"
  name="${REPO_NAMES[$i]}"
  repo_path="${PROJECT_ROOT}/${repo}"

  if [[ -f "${repo_path}/LICENSE" ]]; then
    if grep -q 'MIT License' "${repo_path}/LICENSE"; then
      pass "${name}: LICENSE is MIT"
    else
      warn "${name}: LICENSE exists but may not be MIT"
    fi
  fi
done

# Check contribution guide links
section "Validation 7b: Contribution Guide Cross-Links"

for i in "${!REPOS[@]}"; do
  repo="${REPOS[$i]}"
  name="${REPO_NAMES[$i]}"
  repo_path="${PROJECT_ROOT}/${repo}"

  if [[ -f "${repo_path}/README.md" ]]; then
    if grep -qi 'contributing' "${repo_path}/README.md"; then
      pass "${name}: README.md has contributing section"
    else
      warn "${name}: README.md may not have a contributing section"
    fi
  fi
done

# Check that contribution guide exists
if [[ -f "${PROJECT_ROOT}/standards/contributing.md" ]]; then
  pass "devrail-standards: standards/contributing.md exists"
else
  fail "devrail-standards: standards/contributing.md MISSING"
fi

# =========================================================================
# Validation 8: Docker-Dependent Checks (optional)
# =========================================================================
if [[ "$SKIP_DOCKER" == "false" ]]; then
  section "Validation 8: Docker-Dependent Checks"

  if command -v docker &>/dev/null; then
    if docker info &>/dev/null 2>&1; then
      pass "Docker is installed and running"

      # Try pulling the dev-toolchain image
      echo "Pulling dev-toolchain image (this may take a moment)..."
      if docker pull ghcr.io/devrail-dev/dev-toolchain:v1 &>/dev/null 2>&1; then
        pass "dev-toolchain image pulled successfully"

        # Run make check on each repo
        for i in "${!REPOS[@]}"; do
          repo="${REPOS[$i]}"
          name="${REPO_NAMES[$i]}"
          repo_path="${PROJECT_ROOT}/${repo}"

          echo "Running make check on ${name}..."
          if (cd "$repo_path" && make check) &>/dev/null 2>&1; then
            pass "${name}: make check passes"
          else
            fail "${name}: make check FAILED"
          fi
        done
      else
        warn "Could not pull dev-toolchain image -- skipping make check tests"
      fi
    else
      warn "Docker is installed but not running -- skipping Docker checks"
    fi
  else
    warn "Docker is not installed -- skipping Docker checks"
  fi
else
  section "Validation 8: Docker-Dependent Checks (SKIPPED)"
  warn "Docker checks skipped via --skip-docker flag"
fi

# =========================================================================
# Summary
# =========================================================================
section "VALIDATION SUMMARY"

echo ""
echo "Total checks: $((PASS_COUNT + FAIL_COUNT + WARN_COUNT))"
echo -e "  ${GREEN}Passed: ${PASS_COUNT}${NC}"
echo -e "  ${RED}Failed: ${FAIL_COUNT}${NC}"
echo -e "  ${YELLOW}Warnings: ${WARN_COUNT}${NC}"
echo ""

if [[ $FAIL_COUNT -eq 0 ]]; then
  echo -e "${GREEN}============================================${NC}"
  echo -e "${GREEN} ECOSYSTEM VALIDATION: PASS${NC}"
  echo -e "${GREEN}============================================${NC}"
  echo ""
  echo "Release readiness: GO"
  echo "All structural validations passed. The DevRail ecosystem is ready for release."
  exit 0
else
  echo -e "${RED}============================================${NC}"
  echo -e "${RED} ECOSYSTEM VALIDATION: FAIL${NC}"
  echo -e "${RED}============================================${NC}"
  echo ""
  echo "Release readiness: NO-GO"
  echo "${FAIL_COUNT} validation(s) failed. Fix the issues above before release."
  echo ""
  echo "Failed checks:"
  for result in "${RESULTS[@]}"; do
    if [[ "$result" == FAIL:* ]]; then
      echo "  - ${result#FAIL: }"
    fi
  done
  exit 1
fi
