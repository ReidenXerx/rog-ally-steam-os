#!/bin/bash
# ROG Ally Suite - Quick Launcher
# Simple entry point for the ROG Ally Suite

set -euo pipefail

# Colors
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# Get script directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if main menu exists
if [[ -f "$SCRIPT_DIR/rog-ally-menu.sh" ]]; then
    echo -e "${BLUE}🎮 Starting ROG Ally Suite...${NC}"
    echo
    
    # Make sure it's executable
    chmod +x "$SCRIPT_DIR/rog-ally-menu.sh"
    
    # Run the main menu
    exec "$SCRIPT_DIR/rog-ally-menu.sh"
else
    echo -e "${YELLOW}⚠ ROG Ally Suite main menu not found.${NC}"
    echo
    echo "Available options:"
    
    # Check what scripts are available
    if [[ -f "$SCRIPT_DIR/install.sh" ]]; then
        echo -e "• Run installer: ${GREEN}./install.sh${NC}"
    fi
    
    if [[ -f "$SCRIPT_DIR/verify-steamos-compatibility.sh" ]]; then
        echo -e "• Check compatibility: ${GREEN}./verify-steamos-compatibility.sh${NC}"
    fi
    
    echo
    echo "Please ensure all ROG Ally Suite files are present in this directory."
fi
