#!/usr/bin/env bash
# Purpose: Verify CLAUDE.md shim content consistency across all DevRail repos
# Usage: ./7-1-shim-content-verifier.sh [<project-root-path>]
# Dependencies: diff, find
set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"

# Repos expected to contain CLAUDE.md
readonly REPOS=(
    "."
    "github-repo-template"
    "gitlab-repo-template"
    "dev-toolchain"
    "pre-commit-conventional-commits"
    "devrail.dev"
)

# Required content patterns in CLAUDE.md
readonly REQUIRED_PATTERNS=(
    "DEVELOPMENT.md"
    "make check"
    "conventional commits"
    "type(scope): description"
    "Never install tools outside the container"
    "ghcr.io/devrail-dev/dev-toolchain"
    ".editorconfig"
    "idempotent"
    "lib/log.sh"
    "make help"
)

# ============================================================================
# Main
# ============================================================================
echo "============================================"
echo "CLAUDE.md Shim Content Verifier"
echo "============================================"
echo "Project root: ${PROJECT_ROOT}"
echo ""

OVERALL_PASS=true

# ============================================================================
# Check 1: File Presence
# ============================================================================
echo "--- Check 1: CLAUDE.md File Presence ---"
echo ""

for repo in "${REPOS[@]}"; do
    local_path="${PROJECT_ROOT}/${repo}/CLAUDE.md"
    if [[ -f "${local_path}" ]]; then
        echo "[PASS] ${repo}/CLAUDE.md exists"
    else
        echo "[FAIL] ${repo}/CLAUDE.md NOT FOUND"
        OVERALL_PASS=false
    fi
done

echo ""

# ============================================================================
# Check 2: Required Content Patterns
# ============================================================================
echo "--- Check 2: Required Content Patterns ---"
echo ""

for repo in "${REPOS[@]}"; do
    local_path="${PROJECT_ROOT}/${repo}/CLAUDE.md"
    if [[ ! -f "${local_path}" ]]; then
        echo "[SKIP] ${repo}/CLAUDE.md -- file not found"
        continue
    fi

    echo "Checking ${repo}/CLAUDE.md:"
    repo_pass=true

    for pattern in "${REQUIRED_PATTERNS[@]}"; do
        if grep -qi "${pattern}" "${local_path}" 2>/dev/null; then
            echo "  [PASS] Contains: '${pattern}'"
        else
            echo "  [FAIL] Missing:  '${pattern}'"
            repo_pass=false
            OVERALL_PASS=false
        fi
    done

    if [[ "${repo_pass}" == "true" ]]; then
        echo "  -> All required patterns present"
    else
        echo "  -> MISSING required patterns"
    fi
    echo ""
done

# ============================================================================
# Check 3: Content Consistency Across Repos
# ============================================================================
echo "--- Check 3: Content Consistency Across Repos ---"
echo ""

REFERENCE="${PROJECT_ROOT}/CLAUDE.md"
if [[ ! -f "${REFERENCE}" ]]; then
    echo "[SKIP] Reference CLAUDE.md not found at project root"
else
    for repo in "${REPOS[@]}"; do
        if [[ "${repo}" == "." ]]; then
            continue
        fi
        local_path="${PROJECT_ROOT}/${repo}/CLAUDE.md"
        if [[ ! -f "${local_path}" ]]; then
            echo "[SKIP] ${repo}/CLAUDE.md -- file not found"
            continue
        fi

        if diff -q "${REFERENCE}" "${local_path}" > /dev/null 2>&1; then
            echo "[PASS] ${repo}/CLAUDE.md matches reference"
        else
            echo "[DIFF] ${repo}/CLAUDE.md differs from reference"
            echo "       Differences:"
            diff --brief "${REFERENCE}" "${local_path}" 2>/dev/null || true
        fi
    done
fi

echo ""

# ============================================================================
# Check 4: Shim Structure Validation
# ============================================================================
echo "--- Check 4: Shim Structure Validation ---"
echo ""
echo "Validating CLAUDE.md follows the hybrid shim pattern:"
echo "  1. Pointer to DEVELOPMENT.md"
echo "  2. Critical rules inlined"
echo "  3. Quick reference section"
echo ""

for repo in "${REPOS[@]}"; do
    local_path="${PROJECT_ROOT}/${repo}/CLAUDE.md"
    if [[ ! -f "${local_path}" ]]; then
        echo "[SKIP] ${repo}/CLAUDE.md -- file not found"
        continue
    fi

    echo "Checking ${repo}/CLAUDE.md structure:"

    # Check for DEVELOPMENT.md pointer
    if grep -q "DEVELOPMENT.md" "${local_path}"; then
        echo "  [PASS] Contains pointer to DEVELOPMENT.md"
    else
        echo "  [FAIL] Missing pointer to DEVELOPMENT.md"
        OVERALL_PASS=false
    fi

    # Check for Critical Rules section
    if grep -qi "Critical Rules" "${local_path}"; then
        echo "  [PASS] Contains 'Critical Rules' section"
    else
        echo "  [FAIL] Missing 'Critical Rules' section"
        OVERALL_PASS=false
    fi

    # Check for Quick Reference section
    if grep -qi "Quick Reference" "${local_path}"; then
        echo "  [PASS] Contains 'Quick Reference' section"
    else
        echo "  [FAIL] Missing 'Quick Reference' section"
        OVERALL_PASS=false
    fi

    # Count critical rules (numbered items)
    rule_count=$(grep -cE "^[0-9]+\." "${local_path}" 2>/dev/null || echo "0")
    if [[ "${rule_count}" -ge 6 ]]; then
        echo "  [PASS] Contains ${rule_count} numbered rules (expected >= 6)"
    else
        echo "  [WARN] Contains only ${rule_count} numbered rules (expected >= 6)"
    fi

    echo ""
done

# ============================================================================
# Summary
# ============================================================================
echo "============================================"
if [[ "${OVERALL_PASS}" == "true" ]]; then
    echo "RESULT: ALL CHECKS PASSED"
    echo "CLAUDE.md shim content is consistent and complete across all repos."
    exit 0
else
    echo "RESULT: SOME CHECKS FAILED"
    echo "Review the output above for details on missing or inconsistent content."
    exit 1
fi
