#!/usr/bin/env bash
# Purpose: Evaluate BMAD-generated planning artifacts for DevRail standards integration
# Usage: ./7-3-artifact-evaluator.sh <path-to-bmad-output-directory>
# Dependencies: grep
set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <path-to-bmad-output-directory>"
    echo ""
    echo "Evaluates BMAD-generated planning artifacts for DevRail standards integration."
    echo "The directory should contain architecture.md and story files."
    echo ""
    echo "Options:"
    echo "  --help    Show this help message"
    exit 1
fi

if [[ "$1" == "--help" ]]; then
    echo "Usage: $0 <path-to-bmad-output-directory>"
    echo ""
    echo "Evaluates BMAD-generated planning artifacts for DevRail standards integration."
    echo "Checks architecture documents and story files for DevRail references."
    exit 0
fi

BMAD_DIR="$1"

if [[ ! -d "${BMAD_DIR}" ]]; then
    echo "ERROR: Directory not found: ${BMAD_DIR}"
    exit 2
fi

TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# ============================================================================
# Helper Functions
# ============================================================================
check() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if [[ "$1" == "pass" ]]; then
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        echo "  [PASS] $2"
    else
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        echo "  [FAIL] $2"
    fi
}

check_pattern() {
    local file="$1"
    local pattern="$2"
    local description="$3"

    if grep -qri "${pattern}" "${file}" 2>/dev/null; then
        check "pass" "${description}"
    else
        check "fail" "${description}"
    fi
}

# ============================================================================
# Main
# ============================================================================
echo "============================================"
echo "BMAD Artifact DevRail Integration Evaluator"
echo "============================================"
echo "BMAD output directory: ${BMAD_DIR}"
echo ""

# ============================================================================
# Phase 1: Find Artifacts
# ============================================================================
echo "=== Phase 1: Discovering Artifacts ==="
echo ""

ARCH_FILES=()
STORY_FILES=()
EPIC_FILES=()

while IFS= read -r -d '' file; do
    filename="$(basename "${file}")"
    case "${filename}" in
        architecture*)
            ARCH_FILES+=("${file}")
            echo "  Found architecture file: ${file}"
            ;;
        *epic*)
            EPIC_FILES+=("${file}")
            echo "  Found epic file: ${file}"
            ;;
        *story*|*[0-9]-[0-9]*)
            STORY_FILES+=("${file}")
            echo "  Found story file: ${file}"
            ;;
    esac
done < <(find "${BMAD_DIR}" -name "*.md" -print0 2>/dev/null)

# Also check for .md files in subdirectories that might be stories
while IFS= read -r -d '' file; do
    filename="$(basename "${file}")"
    # Skip already-found files
    already_found=false
    for af in "${ARCH_FILES[@]}" "${EPIC_FILES[@]}" "${STORY_FILES[@]}"; do
        if [[ "${file}" == "${af}" ]]; then
            already_found=true
            break
        fi
    done
    if [[ "${already_found}" == "false" ]]; then
        STORY_FILES+=("${file}")
        echo "  Found additional MD file: ${file}"
    fi
done < <(find "${BMAD_DIR}" -mindepth 2 -name "*.md" -print0 2>/dev/null)

echo ""
echo "  Architecture files: ${#ARCH_FILES[@]}"
echo "  Epic files: ${#EPIC_FILES[@]}"
echo "  Story files: ${#STORY_FILES[@]}"
echo ""

if [[ ${#ARCH_FILES[@]} -eq 0 ]] && [[ ${#STORY_FILES[@]} -eq 0 ]]; then
    echo "ERROR: No artifacts found in ${BMAD_DIR}."
    echo "Expected architecture.md and/or story files."
    exit 2
fi

# ============================================================================
# Phase 2: Architecture Document Evaluation
# ============================================================================
echo "=== Phase 2: Architecture Document Evaluation ==="
echo ""

for arch_file in "${ARCH_FILES[@]}"; do
    echo "Evaluating: ${arch_file}"
    echo ""

    echo "  --- Container References ---"
    check_pattern "${arch_file}" "dev-toolchain" "References dev-toolchain container"
    check_pattern "${arch_file}" "ghcr.io" "References GHCR container registry"
    check_pattern "${arch_file}" "container" "Mentions container-based execution"

    echo "  --- Makefile Contract ---"
    check_pattern "${arch_file}" "make check" "References 'make check'"
    check_pattern "${arch_file}" "make lint\|make test\|make format\|make security" "References specific make targets"
    check_pattern "${arch_file}" "[Mm]akefile" "Mentions Makefile"

    echo "  --- Configuration ---"
    check_pattern "${arch_file}" "devrail.yml\|devrail\.yml" "References .devrail.yml"
    check_pattern "${arch_file}" "editorconfig" "References .editorconfig"
    check_pattern "${arch_file}" "pre-commit" "References pre-commit"

    echo "  --- Agent Instructions ---"
    check_pattern "${arch_file}" "CLAUDE.md\|AGENTS.md\|cursorrules\|opencode" "References agent instruction files"

    echo "  --- Language Tooling ---"
    check_pattern "${arch_file}" "ruff\|pytest\|bandit" "References Python tools"
    check_pattern "${arch_file}" "shellcheck\|shfmt" "References Bash tools"
    check_pattern "${arch_file}" "tflint\|terraform fmt\|tfsec" "References Terraform tools"
    check_pattern "${arch_file}" "ansible-lint\|molecule" "References Ansible tools"

    echo "  --- Conventional Commits ---"
    check_pattern "${arch_file}" "conventional commit" "Mentions conventional commits"

    echo ""
done

# ============================================================================
# Phase 3: Story Artifact Evaluation
# ============================================================================
echo "=== Phase 3: Story Artifact Evaluation ==="
echo ""

ALL_STORY_FILES=("${EPIC_FILES[@]}" "${STORY_FILES[@]}")

if [[ ${#ALL_STORY_FILES[@]} -eq 0 ]]; then
    echo "  No story/epic files found. Skipping story evaluation."
else
    stories_with_make_check=0
    stories_with_commits=0
    stories_with_container=0
    stories_total=0

    for story_file in "${ALL_STORY_FILES[@]}"; do
        stories_total=$((stories_total + 1))
        echo "Evaluating: ${story_file}"

        # Check for make check as completion gate
        if grep -qi "make check" "${story_file}" 2>/dev/null; then
            check "pass" "'make check' referenced"
            stories_with_make_check=$((stories_with_make_check + 1))
        else
            check "fail" "'make check' NOT referenced"
        fi

        # Check for conventional commits
        if grep -qi "conventional commit\|type(scope)" "${story_file}" 2>/dev/null; then
            check "pass" "Conventional commits referenced"
            stories_with_commits=$((stories_with_commits + 1))
        else
            check "fail" "Conventional commits NOT referenced"
        fi

        # Check for container constraint
        if grep -qi "container\|dev-toolchain\|install.*outside" "${story_file}" 2>/dev/null; then
            check "pass" "Container constraint referenced"
            stories_with_container=$((stories_with_container + 1))
        else
            check "fail" "Container constraint NOT referenced"
        fi

        echo ""
    done

    echo "--- Story Summary ---"
    echo ""
    if [[ "${stories_total}" -gt 0 ]]; then
        echo "  Stories with 'make check': ${stories_with_make_check}/${stories_total} ($(( (stories_with_make_check * 100) / stories_total ))%)"
        echo "  Stories with conventional commits: ${stories_with_commits}/${stories_total} ($(( (stories_with_commits * 100) / stories_total ))%)"
        echo "  Stories with container constraint: ${stories_with_container}/${stories_total} ($(( (stories_with_container * 100) / stories_total ))%)"
    fi
    echo ""
fi

# ============================================================================
# Phase 4: Overall DevRail Reference Search
# ============================================================================
echo "=== Phase 4: Overall DevRail Reference Density ==="
echo ""
echo "Searching all artifacts for key DevRail terms..."
echo ""

DEVRAIL_TERMS=(
    "make check"
    "conventional commit"
    "dev-toolchain"
    "devrail"
    "container"
    "Makefile"
    "editorconfig"
    "pre-commit"
    "idempotent"
    "log_info\|log_warn\|log_error\|log.sh"
    "CLAUDE.md\|AGENTS.md"
    "cursorrules\|opencode"
    "shellcheck"
    "ruff"
    "tflint"
    "ansible-lint"
)

for term in "${DEVRAIL_TERMS[@]}"; do
    count=$(grep -rci "${term}" "${BMAD_DIR}" 2>/dev/null | awk -F: '{sum += $NF} END {print sum+0}')
    if [[ "${count}" -gt 0 ]]; then
        echo "  [${count} refs] ${term}"
    else
        echo "  [0 refs] ${term}"
    fi
done

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "============================================"
echo "Summary"
echo "============================================"
echo "Total checks:  ${TOTAL_CHECKS}"
echo "Passed:        ${PASSED_CHECKS}"
echo "Failed:        ${FAILED_CHECKS}"

if [[ "${TOTAL_CHECKS}" -gt 0 ]]; then
    PASS_RATE=$(( (PASSED_CHECKS * 100) / TOTAL_CHECKS ))
    echo "Pass rate:     ${PASS_RATE}%"

    echo ""
    if [[ "${PASS_RATE}" -ge 80 ]]; then
        echo "ASSESSMENT: STRONG DevRail integration in BMAD artifacts"
    elif [[ "${PASS_RATE}" -ge 50 ]]; then
        echo "ASSESSMENT: MODERATE DevRail integration in BMAD artifacts"
    else
        echo "ASSESSMENT: WEAK DevRail integration in BMAD artifacts"
    fi
fi

echo ""
echo "NOTE: This automated evaluator checks for presence of DevRail terms."
echo "Manual review is still needed to assess accuracy and completeness."
echo "Use 7-3-observation-checklist.md for the full manual evaluation."
