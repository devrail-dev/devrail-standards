#!/usr/bin/env bash
# Purpose: Set up a test project for multi-tool agent instruction validation
# Usage: ./7-2-test-project-setup.sh [--template github|gitlab] [--output-dir <path>]
# Dependencies: git, cp, mkdir
set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly DEFAULT_OUTPUT_DIR="${SCRIPT_DIR}/test-project-7-2"
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
            echo "Sets up a test project for multi-tool agent instruction validation (Story 7.2)."
            echo "The same project is used for Cursor, OpenCode, and AGENTS.md testing."
            echo ""
            echo "Options:"
            echo "  --template    Template to use: github or gitlab (default: github)"
            echo "  --output-dir  Output directory for test project (default: ./test-project-7-2)"
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
echo "DevRail Test Project Setup for Story 7.2"
echo "Multi-Tool Agent Validation"
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

# Add a minimal Python + Bash codebase for realistic testing
echo "Adding sample codebase for realistic testing..."
mkdir -p "${OUTPUT_DIR}/utils"
mkdir -p "${OUTPUT_DIR}/scripts"
mkdir -p "${OUTPUT_DIR}/tests"

# Sample Python file
cat > "${OUTPUT_DIR}/utils/__init__.py" << 'PYEOF'
"""DevRail test project utility modules."""
PYEOF

cat > "${OUTPUT_DIR}/utils/config.py" << 'PYEOF'
"""Configuration helpers for DevRail test project."""


def load_config(path: str) -> dict:
    """Load configuration from a YAML file.

    Args:
        path: Path to the configuration file.

    Returns:
        Dictionary containing configuration values.
    """
    # Placeholder for testing -- actual implementation would use pyyaml
    return {"path": path, "loaded": True}
PYEOF

# Sample Bash script
cat > "${OUTPUT_DIR}/scripts/health-check.sh" << 'BASHEOF'
#!/usr/bin/env bash
# Purpose: Run a basic health check on the project
# Usage: ./scripts/health-check.sh
# Dependencies: make
set -euo pipefail

echo "Health check: OK"
BASHEOF

# Sample test file
cat > "${OUTPUT_DIR}/tests/__init__.py" << 'PYEOF'
"""Test suite for DevRail test project."""
PYEOF

cat > "${OUTPUT_DIR}/tests/test_config.py" << 'PYEOF'
"""Tests for configuration helpers."""

from utils.config import load_config


def test_load_config_returns_dict():
    """Test that load_config returns a dictionary."""
    result = load_config("/tmp/test.yml")
    assert isinstance(result, dict)


def test_load_config_includes_path():
    """Test that load_config includes the path in the result."""
    result = load_config("/tmp/test.yml")
    assert result["path"] == "/tmp/test.yml"
PYEOF

# Initialize git repo
if [[ ! -d "${OUTPUT_DIR}/.git" ]]; then
    echo "Initializing git repository..."
    (cd "${OUTPUT_DIR}" && git init && git add -A && git commit -m "chore(standards): initialize test project from ${TEMPLATE} template with sample codebase")
fi

# ============================================================================
# Verification
# ============================================================================
echo ""
echo "Verifying all agent instruction files..."

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
    echo "All agent instruction files present. Test project is ready for multi-tool testing."
else
    echo "WARNING: Some files are missing. Review the template."
fi

echo ""
echo "============================================"
echo "Test project ready at: ${OUTPUT_DIR}"
echo "============================================"
echo ""
echo "IMPORTANT: Use the SAME project for all tool tests."
echo "Reset the project between tests with:"
echo "  cd ${OUTPUT_DIR} && git checkout -- . && git clean -fd"
echo ""
echo "Next steps:"
echo "  1. Test Cursor:   Open project in Cursor, give coding task, observe .cursorrules behavior"
echo "  2. Test OpenCode: Open project in OpenCode, give coding task, observe agents.yaml behavior"
echo "  3. Test AGENTS.md: Feed AGENTS.md to a generic agent, verify self-containment"
echo "  4. Use 7-2-observation-checklist.md for each tool"
echo "  5. Compile cross-tool report using 7-2-cross-tool-report-template.md"
