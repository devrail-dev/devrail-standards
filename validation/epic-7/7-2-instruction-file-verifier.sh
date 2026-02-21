#!/usr/bin/env bash
# Purpose: Verify all agent instruction files are present, correctly formatted, and contain consistent content
# Usage: ./7-2-instruction-file-verifier.sh [--project-root <path>]
# Dependencies: grep, diff
set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"

# Repos expected to contain all agent instruction files
readonly REPOS=(
    "."
    "github-repo-template"
    "gitlab-repo-template"
    "dev-toolchain"
    "pre-commit-conventional-commits"
    "devrail.dev"
)

# Agent instruction files to check
readonly INSTRUCTION_FILES=(
    "CLAUDE.md"
    "AGENTS.md"
    ".cursorrules"
    ".opencode/agents.yaml"
)

# Critical rules that must appear in ALL instruction files (case-insensitive patterns)
readonly CRITICAL_RULES=(
    "make check"
    "conventional commits"
    "type(scope): description"
    "install tools outside the container"
    ".editorconfig"
    "idempotent"
    "log.sh"
)

OVERALL_PASS=true
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
        OVERALL_PASS=false
        echo "  [FAIL] $2"
    fi
}

# ============================================================================
# Main
# ============================================================================
echo "============================================"
echo "Multi-Tool Agent Instruction File Verifier"
echo "============================================"
echo "Project root: ${PROJECT_ROOT}"
echo "Repos:        ${REPOS[*]}"
echo ""

# ============================================================================
# Check 1: File Presence Across Repos
# ============================================================================
echo "=== Check 1: File Presence Across All Repos ==="
echo ""

for repo in "${REPOS[@]}"; do
    repo_dir="${PROJECT_ROOT}/${repo}"
    repo_label="${repo}"
    if [[ "${repo}" == "." ]]; then
        repo_label="(project root)"
    fi

    echo "Repo: ${repo_label}"

    for file in "${INSTRUCTION_FILES[@]}"; do
        if [[ -f "${repo_dir}/${file}" ]]; then
            check "pass" "${file} exists"
        else
            check "fail" "${file} NOT FOUND"
        fi
    done

    # Also check DEVELOPMENT.md
    if [[ -f "${repo_dir}/DEVELOPMENT.md" ]]; then
        check "pass" "DEVELOPMENT.md exists"
    else
        check "fail" "DEVELOPMENT.md NOT FOUND"
    fi

    echo ""
done

# ============================================================================
# Check 2: Critical Rule Presence in Each File
# ============================================================================
echo "=== Check 2: Critical Rules in Each Instruction File ==="
echo ""

for repo in "${REPOS[@]}"; do
    repo_dir="${PROJECT_ROOT}/${repo}"
    repo_label="${repo}"
    if [[ "${repo}" == "." ]]; then
        repo_label="(project root)"
    fi

    for file in "${INSTRUCTION_FILES[@]}"; do
        filepath="${repo_dir}/${file}"
        if [[ ! -f "${filepath}" ]]; then
            continue
        fi

        echo "File: ${repo_label}/${file}"

        for rule in "${CRITICAL_RULES[@]}"; do
            if grep -qi "${rule}" "${filepath}" 2>/dev/null; then
                check "pass" "Contains: '${rule}'"
            else
                check "fail" "Missing:  '${rule}'"
            fi
        done

        echo ""
    done
done

# ============================================================================
# Check 3: Format-Specific Validation
# ============================================================================
echo "=== Check 3: Format-Specific Validation ==="
echo ""

for repo in "${REPOS[@]}"; do
    repo_dir="${PROJECT_ROOT}/${repo}"
    repo_label="${repo}"
    if [[ "${repo}" == "." ]]; then
        repo_label="(project root)"
    fi

    # CLAUDE.md: Should be valid Markdown with heading structure
    claude_file="${repo_dir}/CLAUDE.md"
    if [[ -f "${claude_file}" ]]; then
        echo "CLAUDE.md (${repo_label}):"
        if grep -q "^# " "${claude_file}"; then
            check "pass" "Has Markdown heading (# ...)"
        else
            check "fail" "Missing Markdown heading"
        fi
        if grep -q "^## " "${claude_file}"; then
            check "pass" "Has Markdown subheadings (## ...)"
        else
            check "fail" "Missing Markdown subheadings"
        fi
        if grep -q "DEVELOPMENT.md" "${claude_file}"; then
            check "pass" "Contains DEVELOPMENT.md reference"
        else
            check "fail" "Missing DEVELOPMENT.md reference"
        fi
        echo ""
    fi

    # AGENTS.md: Should be valid Markdown, similar structure to CLAUDE.md
    agents_file="${repo_dir}/AGENTS.md"
    if [[ -f "${agents_file}" ]]; then
        echo "AGENTS.md (${repo_label}):"
        if grep -q "^# " "${agents_file}"; then
            check "pass" "Has Markdown heading (# ...)"
        else
            check "fail" "Missing Markdown heading"
        fi
        if grep -q "DEVELOPMENT.md" "${agents_file}"; then
            check "pass" "Contains DEVELOPMENT.md reference"
        else
            check "fail" "Missing DEVELOPMENT.md reference"
        fi
        echo ""
    fi

    # .cursorrules: Should be plain text (not Markdown headers)
    cursorrules_file="${repo_dir}/.cursorrules"
    if [[ -f "${cursorrules_file}" ]]; then
        echo ".cursorrules (${repo_label}):"
        if grep -q "DEVELOPMENT.md" "${cursorrules_file}"; then
            check "pass" "Contains DEVELOPMENT.md reference"
        else
            check "fail" "Missing DEVELOPMENT.md reference"
        fi
        # .cursorrules should be plain text, not use Markdown bold
        if grep -q "Critical Rules" "${cursorrules_file}"; then
            check "pass" "Contains 'Critical Rules' section"
        else
            check "fail" "Missing 'Critical Rules' section"
        fi
        echo ""
    fi

    # .opencode/agents.yaml: Should be valid YAML
    opencode_file="${repo_dir}/.opencode/agents.yaml"
    if [[ -f "${opencode_file}" ]]; then
        echo ".opencode/agents.yaml (${repo_label}):"
        if grep -q "^agents:" "${opencode_file}"; then
            check "pass" "Has 'agents:' top-level key (valid YAML structure)"
        else
            check "fail" "Missing 'agents:' top-level key"
        fi
        if grep -q "name:" "${opencode_file}"; then
            check "pass" "Has 'name:' field"
        else
            check "fail" "Missing 'name:' field"
        fi
        if grep -q "instructions:" "${opencode_file}"; then
            check "pass" "Has 'instructions:' field"
        else
            check "fail" "Missing 'instructions:' field"
        fi
        if grep -q "DEVELOPMENT.md" "${opencode_file}"; then
            check "pass" "Contains DEVELOPMENT.md reference in instructions"
        else
            check "fail" "Missing DEVELOPMENT.md reference in instructions"
        fi
        echo ""
    fi
done

# ============================================================================
# Check 4: Cross-File Content Consistency
# ============================================================================
echo "=== Check 4: Cross-File Content Consistency ==="
echo ""
echo "Verifying that all instruction files within each repo contain the same critical rules."
echo ""

for repo in "${REPOS[@]}"; do
    repo_dir="${PROJECT_ROOT}/${repo}"
    repo_label="${repo}"
    if [[ "${repo}" == "." ]]; then
        repo_label="(project root)"
    fi

    echo "Repo: ${repo_label}"

    for rule in "${CRITICAL_RULES[@]}"; do
        files_with_rule=0
        files_checked=0

        for file in "${INSTRUCTION_FILES[@]}"; do
            filepath="${repo_dir}/${file}"
            if [[ ! -f "${filepath}" ]]; then
                continue
            fi
            files_checked=$((files_checked + 1))
            if grep -qi "${rule}" "${filepath}" 2>/dev/null; then
                files_with_rule=$((files_with_rule + 1))
            fi
        done

        if [[ "${files_checked}" -eq 0 ]]; then
            continue
        fi

        if [[ "${files_with_rule}" -eq "${files_checked}" ]]; then
            check "pass" "'${rule}' present in all ${files_checked} instruction files"
        elif [[ "${files_with_rule}" -gt 0 ]]; then
            check "fail" "'${rule}' present in ${files_with_rule}/${files_checked} instruction files (inconsistent)"
        else
            check "fail" "'${rule}' missing from all ${files_checked} instruction files"
        fi
    done

    echo ""
done

# ============================================================================
# Summary
# ============================================================================
echo "============================================"
echo "Summary"
echo "============================================"
echo "Total checks:  ${TOTAL_CHECKS}"
echo "Passed:        ${PASSED_CHECKS}"
echo "Failed:        ${FAILED_CHECKS}"

if [[ "${TOTAL_CHECKS}" -gt 0 ]]; then
    PASS_RATE=$(( (PASSED_CHECKS * 100) / TOTAL_CHECKS ))
    echo "Pass rate:     ${PASS_RATE}%"
fi

echo ""
if [[ "${OVERALL_PASS}" == "true" ]]; then
    echo "RESULT: ALL CHECKS PASSED"
    echo "All agent instruction files are present, correctly formatted, and contain consistent content."
    exit 0
else
    echo "RESULT: SOME CHECKS FAILED"
    echo "Review the output above for details."
    exit 1
fi
