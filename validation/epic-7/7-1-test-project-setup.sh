#!/usr/bin/env bash
# Purpose: Set up a test project from a DevRail template for Claude Code validation
# Usage: ./7-1-test-project-setup.sh [--template github|gitlab] [--output-dir <path>]
# Dependencies: git, cp
set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly DEFAULT_OUTPUT_DIR="${SCRIPT_DIR}/test-project-7-1"
readonly DEFAULT_TEMPLATE="github"

# ============================================================================
# Argument Parsing
# ============================================================================
TEMPLATE="${DEFAULT_TEMPLATE}"
OUTPUT_DIR="${DEFAULT_OUTPUT_DIR}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --template)
            TEMPLATE="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [--template github|gitlab] [--output-dir <path>]"
            echo ""
            echo "Sets up a test project from a DevRail template for Claude Code validation."
            echo ""
            echo "Options:"
            echo "  --template    Template to use: github or gitlab (default: github)"
            echo "  --output-dir  Output directory for test project (default: ./test-project-7-1)"
            echo "  --help        Show this help message"
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
case "${TEMPLATE}" in
    github)
        TEMPLATE_DIR="${PROJECT_ROOT}/github-repo-template"
        ;;
    gitlab)
        TEMPLATE_DIR="${PROJECT_ROOT}/gitlab-repo-template"
        ;;
    *)
        echo "ERROR: Invalid template '${TEMPLATE}'. Must be 'github' or 'gitlab'."
        exit 1
        ;;
esac

if [[ ! -d "${TEMPLATE_DIR}" ]]; then
    echo "ERROR: Template directory not found: ${TEMPLATE_DIR}"
    exit 1
fi

# ============================================================================
# Setup
# ============================================================================
echo "============================================"
echo "DevRail Test Project Setup for Story 7.1"
echo "============================================"
echo "Template:   ${TEMPLATE}"
echo "Source:     ${TEMPLATE_DIR}"
echo "Output:     ${OUTPUT_DIR}"
echo ""

# Create output directory
if [[ -d "${OUTPUT_DIR}" ]]; then
    echo "WARNING: Output directory already exists. Removing and recreating."
    rm -rf "${OUTPUT_DIR}"
fi
mkdir -p "${OUTPUT_DIR}"

# Copy template files
echo "Copying template files..."
cp -r "${TEMPLATE_DIR}/." "${OUTPUT_DIR}/"

# Initialize git repo if not already one
if [[ ! -d "${OUTPUT_DIR}/.git" ]]; then
    echo "Initializing git repository..."
    (cd "${OUTPUT_DIR}" && git init && git add -A && git commit -m "chore(standards): initialize test project from ${TEMPLATE} template")
fi

# ============================================================================
# Verification
# ============================================================================
echo ""
echo "Verifying required files..."

REQUIRED_FILES=(
    "CLAUDE.md"
    "DEVELOPMENT.md"
    "AGENTS.md"
    ".cursorrules"
    ".opencode/agents.yaml"
    "Makefile"
)

PASS=true
for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "${OUTPUT_DIR}/${file}" ]]; then
        echo "  [PASS] ${file}"
    else
        echo "  [FAIL] ${file} -- NOT FOUND"
        PASS=false
    fi
done

echo ""
if [[ "${PASS}" == "true" ]]; then
    echo "All required files present. Test project is ready."
else
    echo "WARNING: Some required files are missing. Review the template."
fi

echo ""
echo "============================================"
echo "Test project ready at: ${OUTPUT_DIR}"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Open the test project in Claude Code"
echo "  2. Give Claude Code a coding task (see 7-1-coding-task.md)"
echo "  3. Observe behavior using the checklist (see 7-1-observation-checklist.md)"
echo "  4. Record findings in the validation report template (see 7-1-validation-report-template.md)"
