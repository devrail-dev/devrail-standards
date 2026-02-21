#!/usr/bin/env bash
# Purpose: Validate that git commit messages follow DevRail conventional commit format
# Usage: ./7-1-commit-format-validator.sh [--repo <path>] [--count <n>]
# Dependencies: git, grep
set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================
readonly VALID_TYPES="feat|fix|docs|chore|ci|refactor|test"
readonly VALID_SCOPES="python|terraform|bash|ansible|container|ci|makefile|standards"
readonly COMMIT_PATTERN="^(${VALID_TYPES})\((${VALID_SCOPES})\): [a-z]"

REPO_PATH="."
COMMIT_COUNT="10"

# ============================================================================
# Argument Parsing
# ============================================================================
while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo)
            REPO_PATH="$2"
            shift 2
            ;;
        --count)
            COMMIT_COUNT="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [--repo <path>] [--count <n>]"
            echo ""
            echo "Validates git commit messages against DevRail conventional commit format."
            echo ""
            echo "Options:"
            echo "  --repo     Path to git repository (default: current directory)"
            echo "  --count    Number of recent commits to check (default: 10)"
            echo "  --help     Show this help message"
            echo ""
            echo "Expected format: type(scope): description"
            echo "  Valid types:  ${VALID_TYPES}"
            echo "  Valid scopes: ${VALID_SCOPES}"
            echo "  Description must start with lowercase letter and use imperative mood"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ============================================================================
# Validation
# ============================================================================
echo "============================================"
echo "DevRail Commit Format Validator"
echo "============================================"
echo "Repository: ${REPO_PATH}"
echo "Checking last ${COMMIT_COUNT} commits"
echo "Pattern: type(scope): description"
echo "  Valid types:  ${VALID_TYPES}"
echo "  Valid scopes: ${VALID_SCOPES}"
echo ""

cd "${REPO_PATH}"

if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "ERROR: Not a git repository: ${REPO_PATH}"
    exit 2
fi

TOTAL=0
PASS=0
FAIL=0

echo "--- Commit Analysis ---"
echo ""

while IFS= read -r commit_line; do
    if [[ -z "${commit_line}" ]]; then
        continue
    fi

    TOTAL=$((TOTAL + 1))
    HASH="${commit_line%% *}"
    MESSAGE="${commit_line#* }"

    if echo "${MESSAGE}" | grep -qE "${COMMIT_PATTERN}"; then
        echo "[PASS] ${HASH} ${MESSAGE}"
        PASS=$((PASS + 1))
    else
        echo "[FAIL] ${HASH} ${MESSAGE}"
        FAIL=$((FAIL + 1))

        # Provide specific feedback on what's wrong
        if ! echo "${MESSAGE}" | grep -qE "^(${VALID_TYPES})\("; then
            echo "       -> Invalid or missing type. Expected one of: ${VALID_TYPES}"
        elif ! echo "${MESSAGE}" | grep -qE "^(${VALID_TYPES})\((${VALID_SCOPES})\)"; then
            echo "       -> Invalid or missing scope. Expected one of: ${VALID_SCOPES}"
        elif ! echo "${MESSAGE}" | grep -qE "^(${VALID_TYPES})\((${VALID_SCOPES})\): "; then
            echo "       -> Missing colon-space separator after scope"
        elif ! echo "${MESSAGE}" | grep -qE "^(${VALID_TYPES})\((${VALID_SCOPES})\): [a-z]"; then
            echo "       -> Description must start with a lowercase letter"
        fi
    fi
done < <(git log --oneline -n "${COMMIT_COUNT}" 2>/dev/null)

echo ""
echo "--- Summary ---"
echo "Total commits checked: ${TOTAL}"
echo "Pass: ${PASS}"
echo "Fail: ${FAIL}"

if [[ "${TOTAL}" -eq 0 ]]; then
    echo ""
    echo "No commits found in repository."
    exit 0
fi

PASS_RATE=$(( (PASS * 100) / TOTAL ))
echo "Pass rate: ${PASS_RATE}%"

echo ""
if [[ "${FAIL}" -eq 0 ]]; then
    echo "RESULT: ALL COMMITS CONFORM to DevRail conventional commit format."
    exit 0
else
    echo "RESULT: ${FAIL} commit(s) DO NOT conform to DevRail conventional commit format."
    exit 1
fi
