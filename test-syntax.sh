#!/bin/bash
# Syntax checker for ROG Ally Suite scripts
# This can be run on any system to verify script syntax

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

echo -e "${BLUE}=== ROG Ally Suite Syntax Verification ===${NC}"
echo "Checking all scripts for syntax errors..."
echo

SCRIPTS=(
    "install.sh"
    "system-restore.sh"
    "uninstall.sh"
    "verify-steamos-compatibility.sh"
)

PASSED=0
FAILED=0

for script in "${SCRIPTS[@]}"; do
    if [[ -f "$script" ]]; then
        echo -n "Checking $script... "
        if bash -n "$script" 2>/dev/null; then
            echo -e "${GREEN}✓ PASS${NC}"
            ((PASSED++))
        else
            echo -e "${RED}✗ FAIL${NC}"
            echo -e "${RED}Syntax errors in $script:${NC}"
            bash -n "$script"
            ((FAILED++))
        fi
    else
        echo -e "${YELLOW}⚠ SKIP${NC} $script (file not found)"
    fi
done

echo
echo -e "${BLUE}=== Syntax Check Summary ===${NC}"
echo -e "${GREEN}Passed:${NC} $PASSED"
echo -e "${RED}Failed:${NC} $FAILED"

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}✓ All scripts have valid syntax!${NC}"
    echo -e "${BLUE}→ Ready for deployment to SteamOS${NC}"
    exit 0
else
    echo -e "${RED}✗ Fix syntax errors before deployment${NC}"
    exit 1
fi
