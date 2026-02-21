#!/usr/bin/env bash
# validation/e2e/validate-template.sh -- Validate a template-created project
#
# Purpose: Creates a temporary project from either the GitHub or GitLab template,
#          then validates that make check passes, pre-commit hooks work, and
#          the project is fully functional out of the box.
# Usage:   bash validation/e2e/validate-template.sh <github|gitlab> [--skip-ci]
# Dependencies: docker, make, git, pre-commit
#
# This script:
#   1. Copies the template repo to a temp directory
#   2. Initializes it as a git repo
#   3. Runs make check
#   4. Installs pre-commit hooks
#   5. Tests a valid commit (should pass)
#   6. Tests an invalid commit message (should fail)
#   7. Reports results
#
# Exit codes:
#   0 = all validations passed
#   1 = one or more validations failed
#   2 = misconfiguration (bad arguments, missing tools)

set -euo pipefail

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# --- Help ---
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" || -z "${1:-}" ]]; then
  echo "validate-template.sh -- Validate a DevRail template project"
  echo ""
  echo "Usage: bash validation/e2e/validate-template.sh <github|gitlab> [OPTIONS]"
  echo ""
  echo "Arguments:"
  echo "  github    Test the GitHub repository template"
  echo "  gitlab    Test the GitLab repository template"
  echo ""
  echo "Options:"
  echo "  --skip-ci  Skip CI pipeline validation (requires remote access)"
  echo "  --help     Show this help"
  exit 0
fi

TEMPLATE_TYPE="$1"
SKIP_CI=false

for arg in "$@"; do
  case "$arg" in
    --skip-ci) SKIP_CI=true ;;
  esac
done

if [[ "$TEMPLATE_TYPE" != "github" && "$TEMPLATE_TYPE" != "gitlab" ]]; then
  echo "Error: First argument must be 'github' or 'gitlab'"
  exit 2
fi

# --- State ---
PASS_COUNT=0
FAIL_COUNT=0
RESULTS=()

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  RESULTS+=("PASS: $1")
  echo -e "${GREEN}PASS${NC}: $1"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  RESULTS+=("FAIL: $1")
  echo -e "${RED}FAIL${NC}: $1"
}

warn() {
  RESULTS+=("WARN: $1")
  echo -e "${YELLOW}WARN${NC}: $1"
}

# --- Resolve paths ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [[ "$TEMPLATE_TYPE" == "github" ]]; then
  TEMPLATE_DIR="${PROJECT_ROOT}/github-repo-template"
else
  TEMPLATE_DIR="${PROJECT_ROOT}/gitlab-repo-template"
fi

# --- Create temp directory ---
TMPDIR=$(mktemp -d)
cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

TEST_PROJECT="${TMPDIR}/test-project-${TEMPLATE_TYPE}"

echo "============================================"
echo " Template Validation: ${TEMPLATE_TYPE}"
echo "============================================"
echo ""
echo "Template source: ${TEMPLATE_DIR}"
echo "Test project: ${TEST_PROJECT}"
echo ""

# --- Step 1: Copy template ---
echo "--- Step 1: Copy template to test directory ---"
cp -r "$TEMPLATE_DIR" "$TEST_PROJECT"
if [[ -d "$TEST_PROJECT" ]]; then
  pass "Template copied to test directory"
else
  fail "Failed to copy template"
  exit 1
fi

# --- Step 2: Initialize as git repo ---
echo ""
echo "--- Step 2: Initialize git repository ---"
cd "$TEST_PROJECT"
git init -q
git add -A
git commit -q -m "feat(init): initial project from ${TEMPLATE_TYPE} template" --no-verify 2>/dev/null || true
if git rev-parse --git-dir &>/dev/null; then
  pass "Git repository initialized"
else
  fail "Failed to initialize git repository"
fi

# --- Step 3: Check required files ---
echo ""
echo "--- Step 3: Verify required files ---"
REQUIRED_FILES=(
  ".devrail.yml"
  ".editorconfig"
  ".gitignore"
  ".pre-commit-config.yaml"
  "CLAUDE.md"
  "AGENTS.md"
  ".cursorrules"
  ".opencode/agents.yaml"
  "LICENSE"
  "Makefile"
  "README.md"
  "CHANGELOG.md"
  "DEVELOPMENT.md"
)

for file in "${REQUIRED_FILES[@]}"; do
  if [[ -f "${TEST_PROJECT}/${file}" ]]; then
    pass "File exists: ${file}"
  else
    fail "File missing: ${file}"
  fi
done

# --- Step 4: Check CI configuration ---
echo ""
echo "--- Step 4: Verify CI configuration ---"
if [[ "$TEMPLATE_TYPE" == "github" ]]; then
  if [[ -d "${TEST_PROJECT}/.github/workflows" ]]; then
    workflow_count=$(find "${TEST_PROJECT}/.github/workflows" -name '*.yml' | wc -l)
    pass "GitHub Actions: ${workflow_count} workflow(s) present"
  else
    fail "GitHub Actions: .github/workflows/ missing"
  fi
else
  if [[ -f "${TEST_PROJECT}/.gitlab-ci.yml" ]]; then
    pass "GitLab CI: .gitlab-ci.yml present"
  else
    fail "GitLab CI: .gitlab-ci.yml missing"
  fi
fi

# --- Step 5: Run make check (if Docker available) ---
echo ""
echo "--- Step 5: Run make check ---"
if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
  echo "Running make check (this may take a moment)..."
  if make check 2>&1; then
    pass "make check passes on first run"
  else
    fail "make check FAILED on first run"
  fi
else
  warn "Docker not available -- skipping make check"
fi

# --- Step 6: Test pre-commit hooks ---
echo ""
echo "--- Step 6: Test pre-commit hooks ---"
if command -v pre-commit &>/dev/null; then
  # Install hooks
  if pre-commit install && pre-commit install --hook-type commit-msg; then
    pass "Pre-commit hooks installed"
  else
    fail "Pre-commit hook installation failed"
  fi

  # Test valid commit
  echo "test" > test-file.txt
  git add test-file.txt
  if git commit -m "feat(test): add test file" 2>&1; then
    pass "Valid conventional commit accepted"
  else
    fail "Valid conventional commit rejected (hooks may be misconfigured)"
  fi

  # Test invalid commit
  echo "test2" > test-file2.txt
  git add test-file2.txt
  if git commit -m "bad commit message" 2>&1; then
    fail "Invalid commit message was accepted (hook should have rejected it)"
  else
    pass "Invalid commit message correctly rejected"
    git reset HEAD test-file2.txt 2>/dev/null || true
  fi
else
  warn "pre-commit not installed -- skipping hook tests"
fi

# --- Step 7: Verify make help output ---
echo ""
echo "--- Step 7: Verify make help ---"
help_output=$(make help 2>&1 || true)
for target in lint format test security scan docs check install-hooks; do
  if echo "$help_output" | grep -q "$target"; then
    pass "make help shows target: ${target}"
  else
    fail "make help missing target: ${target}"
  fi
done

# --- Summary ---
echo ""
echo "============================================"
echo " TEMPLATE VALIDATION SUMMARY: ${TEMPLATE_TYPE}"
echo "============================================"
echo ""
echo "Total checks: $((PASS_COUNT + FAIL_COUNT))"
echo -e "  ${GREEN}Passed: ${PASS_COUNT}${NC}"
echo -e "  ${RED}Failed: ${FAIL_COUNT}${NC}"
echo ""

if [[ $FAIL_COUNT -eq 0 ]]; then
  echo -e "${GREEN}TEMPLATE VALIDATION: PASS${NC}"
  exit 0
else
  echo -e "${RED}TEMPLATE VALIDATION: FAIL${NC}"
  echo ""
  echo "Failed checks:"
  for result in "${RESULTS[@]}"; do
    if [[ "$result" == FAIL:* ]]; then
      echo "  - ${result#FAIL: }"
    fi
  done
  exit 1
fi
