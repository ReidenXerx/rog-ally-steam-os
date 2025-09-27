#!/bin/bash
# ROG Ally Suite - Interactive Main Menu
# User-friendly interface for all ROG Ally Suite operations

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly VERSION="2.0"

# Initialize comprehensive logging
if [[ -f "$SCRIPT_DIR/logger.sh" ]]; then
    source "$SCRIPT_DIR/logger.sh"

    # Initialize logging but don't redirect stdout/stderr yet
    # We'll do that after showing initial messages
    mkdir -p "/home/deck/.local/share/rog-ally-suite/logs"
    readonly SESSION_LOG_FILE="/home/deck/.local/share/rog-ally-suite/logs/session-$(date +%Y%m%d-%H%M%S).log"
    readonly LATEST_LOG_LINK="/home/deck/.local/share/rog-ally-suite/logs/latest.log"

    # Create session log file
    cat > "$SESSION_LOG_FILE" << EOF
================================================================================
ROG Ally Suite - Session Log
Started: $(date)
User: $(whoami)
Working Directory: $(pwd)
Script: ${0##*/}
Arguments: $*
================================================================================

EOF

    # Create/update latest log symlink
    rm -f "$LATEST_LOG_LINK"
    ln -sf "$SESSION_LOG_FILE" "$LATEST_LOG_LINK"

    # Set up logging redirection AFTER we show the menu
    LOGGING_ENABLED=true
else
    # Fallback logging if logger.sh is missing
    readonly LOG_DIR="/home/deck/.local/share/rog-ally-suite/logs"
    readonly LOGFILE="${LOG_DIR}/menu-$(date +%Y%m%d-%H%M%S).log"
    mkdir -p "$LOG_DIR"

    # Don't redirect output immediately for fallback either
    LOGGING_ENABLED=false
fi

# Colors and styling (defined after logging setup)
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly NC='\033[0m'

# Enable logging redirection
enable_logging() {
    if [[ "$LOGGING_ENABLED" == "true" ]]; then
        # Set up logging redirection
        exec > >(tee -a "$SESSION_LOG_FILE")
        exec 2> >(tee -a "$SESSION_LOG_FILE" >&2)

        # Log system info now that redirection is active
        echo "$(date '+%Y-%m-%d %H:%M:%S') [SYSTEM] Logging redirection enabled"
        echo "$(date '+%Y-%m-%d %H:%M:%S') [SYSTEM] ROG Ally Suite Menu v$VERSION started"

        # Log system info
        if command -v log_system_info &>/dev/null; then
            log_system_info
        fi

        # Clean up old logs
        if command -v cleanup_logs &>/dev/null; then
            cleanup_logs 30
        fi
    elif [[ "$LOGGING_ENABLED" == "false" && -n "${LOGFILE:-}" ]]; then
        # Fallback logging
        exec > >(tee -a "$LOGFILE")
        exec 2> >(tee -a "$LOGFILE" >&2)
        echo "$(date) [SYSTEM] Fallback logging redirection enabled: $LOGFILE"
    fi
}

# Clear screen and show header
show_header() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${WHITE}                        🎮 ROG Ally Suite v${VERSION} 🎮                        ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${CYAN}              Professional ASUS Hardware Control for SteamOS              ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo
}

# Show system status
show_status() {
    echo -e "${BOLD}📊 System Status:${NC}"

    # Check if suite is installed
    if [[ -d "/home/deck/.local/share/rog-ally-suite" ]]; then
        echo -e "   ${GREEN}✓${NC} ROG Ally Suite: ${GREEN}Installed${NC}"

        # Check if asusctl is available
        if command -v asusctl &>/dev/null; then
            local battery_limit=$(asusctl -c 2>/dev/null | grep -o '[0-9]\+' || echo "Unknown")
            echo -e "   ${GREEN}✓${NC} ASUS Controls: ${GREEN}Active${NC} (Battery limit: ${battery_limit}%)"
        else
            echo -e "   ${YELLOW}⚠${NC} ASUS Controls: ${YELLOW}Not installed${NC}"
        fi

        # Check service status
        if systemctl --user is-enabled rog-ally-restore.service &>/dev/null; then
            echo -e "   ${GREEN}✓${NC} Auto-restore: ${GREEN}Enabled${NC}"
        else
            echo -e "   ${YELLOW}⚠${NC} Auto-restore: ${YELLOW}Disabled${NC}"
        fi
    else
        echo -e "   ${RED}✗${NC} ROG Ally Suite: ${RED}Not installed${NC}"
    fi

    # Check SteamOS
    if [[ -f /etc/os-release ]] && grep -q "steamos" /etc/os-release; then
        local steamos_version=$(grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 || echo "Unknown")
        echo -e "   ${GREEN}✓${NC} SteamOS: ${GREEN}${steamos_version}${NC}"
    else
        echo -e "   ${YELLOW}⚠${NC} SteamOS: ${YELLOW}Not detected${NC}"
    fi

    echo
}

# Main menu
show_menu() {
    echo -e "${BOLD}🚀 Available Actions:${NC}"
    echo
    echo -e "   ${CYAN}1.${NC} ${WHITE}Fresh Installation${NC}     - First-time setup for new users"
    echo -e "   ${CYAN}2.${NC} ${WHITE}System Check${NC}          - Verify compatibility and status"
    echo -e "   ${CYAN}3.${NC} ${WHITE}Install/Upgrade${NC}       - Install or upgrade the suite"
    echo -e "   ${CYAN}4.${NC} ${WHITE}Restore ASUS Controls${NC}  - Manually restore hardware controls"
    echo -e "   ${CYAN}5.${NC} ${WHITE}Configuration${NC}         - Edit settings and preferences"
    echo -e "   ${CYAN}6.${NC} ${WHITE}Cleanup Legacy${NC}        - Remove old ROG Ally scripts"
    echo -e "   ${CYAN}7.${NC} ${WHITE}System Information${NC}    - Gather detailed system info"
    echo -e "   ${CYAN}8.${NC} ${WHITE}Troubleshooting${NC}       - Diagnostic tools and fixes"
    echo -e "   ${CYAN}9.${NC} ${WHITE}Uninstall${NC}            - Remove the suite completely"
    echo -e "   ${CYAN}h.${NC} ${WHITE}Help & Guides${NC}         - Documentation and guides"
    echo -e "   ${CYAN}q.${NC} ${WHITE}Quit${NC}                 - Exit this menu"
    echo
}

# Wait for user input
wait_for_input() {
    echo -e "${DIM}Press any key to continue...${NC}"
    read -n 1 -s
}

# Execute script with error handling
run_script() {
    local script_name="$1"
    local description="$2"

    log_message "INFO" "$description"
    log_message "DEBUG" "Running: $script_name"
    echo -e "${BLUE}[INFO]${NC} $description"
    echo -e "${DIM}Running: $script_name${NC}"
    echo

    if [[ -f "$SCRIPT_DIR/$script_name" ]]; then
        if chmod +x "$SCRIPT_DIR/$script_name"; then
            local exit_code=0

            # Use enhanced logging if available
            if command -v log_script_execution &>/dev/null; then
                log_script_execution "$SCRIPT_DIR/$script_name" "$description" || exit_code=$?
            else
                "$SCRIPT_DIR/$script_name" || exit_code=$?
            fi

            echo
            if [[ $exit_code -eq 0 ]]; then
                echo -e "${GREEN}✓ Success!${NC} $description completed."
                log_message "SUCCESS" "$description completed successfully"
            else
                echo -e "${YELLOW}⚠ Completed with warnings.${NC} $description finished but check output above for any issues."
                log_message "WARN" "$description completed with warnings (exit code: $exit_code)"
            fi
        else
            echo
            echo -e "${RED}✗ Error!${NC} Cannot make $script_name executable."
            log_message "ERROR" "Cannot make $script_name executable"
        fi
    else
        echo -e "${RED}✗ Error!${NC} Script $script_name not found."
        log_message "ERROR" "Script not found: $script_name"
    fi

    echo
    wait_for_input
}

# Fresh installation workflow
fresh_installation() {
    show_header
    echo -e "${BOLD}🆕 Fresh Installation Wizard${NC}"
    echo
    echo "This will guide you through setting up ROG Ally Suite on a fresh SteamOS system."
    echo
    echo -e "${YELLOW}Prerequisites:${NC}"
    echo "• SteamOS Developer Mode enabled"
    echo "• Sudo password set for deck user"
    echo "• Internet connection available"
    echo
    echo -e "${CYAN}Installation steps:${NC}"
    echo "1. Check system compatibility"
    echo "2. Install the suite"
    echo "3. Install ASUS packages"
    echo "4. Configure settings"
    echo

    read -p "Continue with fresh installation? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return
    fi

    echo
    echo -e "${BOLD}Step 1: Compatibility Check${NC}"
    run_script "verify-steamos-compatibility.sh" "Checking system compatibility"

    echo -e "${BOLD}Step 2: Installing Suite${NC}"
    run_script "install.sh" "Installing ROG Ally Suite"

    echo -e "${BOLD}Step 3: Installing ASUS Packages${NC}"
    if [[ -f "/home/deck/.local/share/rog-ally-suite/scripts/system-restore.sh" ]]; then
        echo -e "${BLUE}[INFO]${NC} Installing ASUS hardware controls"
        echo -e "${DIM}Running: system-restore.sh${NC}"
        echo

        if /home/deck/.local/share/rog-ally-suite/scripts/system-restore.sh; then
            echo
            echo -e "${GREEN}✓ Success!${NC} ASUS controls installed and configured."
        else
            echo
            echo -e "${RED}✗ Error!${NC} ASUS controls installation failed."
        fi
    else
        echo -e "${RED}✗ Error!${NC} Suite installation incomplete."
    fi

    echo
    echo -e "${BOLD}Step 4: Final Verification${NC}"
    if command -v asusctl &>/dev/null; then
        local battery_limit=$(asusctl -c 2>/dev/null | grep -o '[0-9]\+' || echo "Unknown")
        echo -e "${GREEN}✓ Installation Complete!${NC}"
        echo
        echo -e "${BOLD}Your ROG Ally is now configured with:${NC}"
        echo -e "• Battery charge limit: ${battery_limit}%"
        echo -e "• Automatic restoration after updates"
        echo -e "• Power profile management"
        echo
        echo -e "${CYAN}Next steps:${NC}"
        echo -e "• Reboot to test automatic restoration"
        echo -e "• Use option 5 to customize settings"
        echo -e "• Return to Gaming Mode - everything works automatically!"
    else
        echo -e "${RED}✗ Installation incomplete.${NC} Please check the logs and try again."
    fi

    echo
    wait_for_input
}

# Configuration menu
configuration_menu() {
    while true; do
        show_header
        echo -e "${BOLD}⚙️ Configuration Menu${NC}"
        echo

        local config_file="/home/deck/.config/rog-ally-suite/config.conf"
        if [[ -f "$config_file" ]]; then
            echo -e "${BOLD}Current Settings:${NC}"
            local battery_limit=$(grep "^BATTERY_LIMIT=" "$config_file" 2>/dev/null | cut -d'=' -f2 || echo "80")
            local auto_power=$(grep "^AUTO_POWER_PROFILES=" "$config_file" 2>/dev/null | cut -d'=' -f2 || echo "true")
            echo -e "• Battery limit: ${battery_limit}%"
            echo -e "• Auto power profiles: ${auto_power}"
            echo
        else
            echo -e "${YELLOW}⚠ Configuration file not found. Please install the suite first.${NC}"
            echo
            wait_for_input
            return
        fi

        echo -e "${BOLD}Configuration Options:${NC}"
        echo
        echo -e "   ${CYAN}1.${NC} Change battery charge limit"
        echo -e "   ${CYAN}2.${NC} Toggle automatic power profiles"
        echo -e "   ${CYAN}3.${NC} Edit configuration file manually"
        echo -e "   ${CYAN}4.${NC} Reset to defaults"
        echo -e "   ${CYAN}5.${NC} Apply current configuration"
        echo -e "   ${CYAN}b.${NC} Back to main menu"
        echo

        read -p "Select option: " choice

        case $choice in
            1)
                echo
                echo -e "${BOLD}Battery Charge Limit Options:${NC}"
                echo -e "• ${GREEN}60%${NC} - Maximum battery preservation"
                echo -e "• ${GREEN}70%${NC} - Good balance for daily use"
                echo -e "• ${GREEN}80%${NC} - Recommended default"
                echo -e "• ${GREEN}90%${NC} - More capacity, less preservation"
                echo -e "• ${GREEN}100%${NC} - Disable limiting (not recommended)"
                echo
                read -p "Enter new battery limit (60-100): " new_limit

                if [[ "$new_limit" =~ ^[0-9]+$ ]] && [[ $new_limit -ge 60 ]] && [[ $new_limit -le 100 ]]; then
                    sed -i "s/^BATTERY_LIMIT=.*/BATTERY_LIMIT=$new_limit/" "$config_file"
                    echo -e "${GREEN}✓${NC} Battery limit set to ${new_limit}%"
                else
                    echo -e "${RED}✗${NC} Invalid battery limit. Please enter 60-100."
                fi
                echo
                wait_for_input
                ;;
            2)
                local current_power=$(grep "^AUTO_POWER_PROFILES=" "$config_file" | cut -d'=' -f2)
                if [[ "$current_power" == "true" ]]; then
                    sed -i "s/^AUTO_POWER_PROFILES=.*/AUTO_POWER_PROFILES=false/" "$config_file"
                    echo -e "${GREEN}✓${NC} Automatic power profiles disabled"
                else
                    sed -i "s/^AUTO_POWER_PROFILES=.*/AUTO_POWER_PROFILES=true/" "$config_file"
                    echo -e "${GREEN}✓${NC} Automatic power profiles enabled"
                fi
                echo
                wait_for_input
                ;;
            3)
                if command -v nano &>/dev/null; then
                    nano "$config_file"
                elif command -v vim &>/dev/null; then
                    vim "$config_file"
                else
                    echo -e "${RED}✗${NC} No text editor available. Please install nano or vim."
                    wait_for_input
                fi
                ;;
            4)
                read -p "Reset configuration to defaults? (y/N): " -r
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    cat > "$config_file" << EOF
# ROG Ally Suite Configuration
# Edit these values to customize behavior

# Battery charge limit (percentage)
BATTERY_LIMIT=80

# Enable automatic power profile management
AUTO_POWER_PROFILES=true

# Log retention (days)
LOG_RETENTION_DAYS=30

# G14 repository URL
G14_REPO_URL=https://arch.asus-linux.org

# Required packages
REQUIRED_PACKAGES=(asusctl power-profiles-daemon)
EOF
                    echo -e "${GREEN}✓${NC} Configuration reset to defaults"
                    echo
                    wait_for_input
                fi
                ;;
            5)
                if [[ -f "/home/deck/.local/share/rog-ally-suite/scripts/system-restore.sh" ]]; then
                    echo -e "${BLUE}[INFO]${NC} Applying current configuration..."
                    /home/deck/.local/share/rog-ally-suite/scripts/system-restore.sh
                    echo -e "${GREEN}✓${NC} Configuration applied"
                else
                    echo -e "${RED}✗${NC} Suite not properly installed"
                fi
                echo
                wait_for_input
                ;;
            b|B)
                return
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                sleep 1
                ;;
        esac
    done
}

# Help menu
help_menu() {
    while true; do
        show_header
        echo -e "${BOLD}📚 Help & Documentation${NC}"
        echo
        echo -e "${BOLD}Available Guides:${NC}"
        echo
        echo -e "   ${CYAN}1.${NC} Fresh Installation Guide    - Complete setup for new users"
        echo -e "   ${CYAN}2.${NC} Troubleshooting Guide       - Common issues and solutions"
        echo -e "   ${CYAN}3.${NC} Configuration Guide         - Customization options"
        echo -e "   ${CYAN}4.${NC} About ROG Ally Suite        - Project information"
        echo -e "   ${CYAN}b.${NC} Back to main menu"
        echo

        read -p "Select guide: " choice

        case $choice in
            1)
                if [[ -f "$SCRIPT_DIR/FRESH-INSTALL-GUIDE.md" ]]; then
                    echo
                    echo -e "${BOLD}Fresh Installation Guide${NC}"
                    echo -e "${DIM}Opening guide...${NC}"

                    if command -v less &>/dev/null; then
                        less "$SCRIPT_DIR/FRESH-INSTALL-GUIDE.md"
                    else
                        cat "$SCRIPT_DIR/FRESH-INSTALL-GUIDE.md"
                        wait_for_input
                    fi
                else
                    echo -e "${RED}✗${NC} Guide not found: FRESH-INSTALL-GUIDE.md"
                    wait_for_input
                fi
                ;;
            2)
                echo
                echo -e "${BOLD}🔧 Common Troubleshooting Steps${NC}"
                echo
                echo -e "${YELLOW}1. Check System Status:${NC}"
                echo "   systemctl --user status rog-ally-restore.service"
                echo
                echo -e "${YELLOW}2. Check Logs:${NC}"
                echo "   ls ~/.local/share/rog-ally-suite/logs/"
                echo "   tail ~/.local/share/rog-ally-suite/logs/restore-*.log"
                echo
                echo -e "${YELLOW}3. Manual Restoration:${NC}"
                echo "   ~/.local/share/rog-ally-suite/scripts/system-restore.sh"
                echo
                echo -e "${YELLOW}4. Re-run Installation:${NC}"
                echo "   ./install.sh"
                echo
                echo -e "${YELLOW}5. Check ASUS Controls:${NC}"
                echo "   asusctl --version"
                echo "   asusctl -c"
                echo
                wait_for_input
                ;;
            3)
                echo
                echo -e "${BOLD}⚙️ Configuration Options${NC}"
                echo
                echo -e "${YELLOW}Battery Limits:${NC}"
                echo "• 60% - Maximum battery life"
                echo "• 80% - Recommended balance (default)"
                echo "• 100% - No limiting"
                echo
                echo -e "${YELLOW}Configuration File:${NC}"
                echo "~/.config/rog-ally-suite/config.conf"
                echo
                echo -e "${YELLOW}Apply Changes:${NC}"
                echo "Use option 5 in Configuration Menu or run:"
                echo "~/.local/share/rog-ally-suite/scripts/system-restore.sh"
                echo
                wait_for_input
                ;;
            4)
                echo
                echo -e "${BOLD}🎮 About ROG Ally Suite v${VERSION}${NC}"
                echo
                echo -e "${CYAN}Purpose:${NC}"
                echo "Professional ASUS hardware control suite for SteamOS that survives system updates."
                echo
                echo -e "${CYAN}Features:${NC}"
                echo "• Automatic battery charge limiting"
                echo "• Power profile management"
                echo "• Persistent across SteamOS updates"
                echo "• User-friendly configuration"
                echo "• Comprehensive logging"
                echo
                echo -e "${CYAN}Compatibility:${NC}"
                echo "• ASUS ROG Ally devices"
                echo "• SteamOS 3.x"
                echo "• Arch Linux (partial)"
                echo
                echo -e "${CYAN}Author:${NC} Improved by Claude & Community"
                echo -e "${CYAN}License:${NC} Open Source"
                echo
                wait_for_input
                ;;
            b|B)
                return
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                sleep 1
                ;;
        esac
    done
}

# Troubleshooting menu
troubleshooting_menu() {
    show_header
    echo -e "${BOLD}🔧 Troubleshooting Tools${NC}"
    echo
    echo -e "   ${CYAN}1.${NC} Quick System Check"
    echo -e "   ${CYAN}2.${NC} Detailed System Info"
    echo -e "   ${CYAN}3.${NC} Check Service Logs"
    echo -e "   ${CYAN}4.${NC} Reset Services"
    echo -e "   ${CYAN}5.${NC} Force Package Reinstall"
    echo -e "   ${CYAN}6.${NC} Fix Package Signature Issues"
    echo -e "   ${CYAN}b.${NC} Back to main menu"
    echo

    read -p "Select tool: " choice

    case $choice in
        1)
            echo
            echo -e "${BOLD}Quick System Check${NC}"
            echo

            # Check basic functionality
            if command -v asusctl &>/dev/null; then
                echo -e "${GREEN}✓${NC} asusctl: Available"
                asusctl -c 2>/dev/null && echo -e "${GREEN}✓${NC} Battery limit: Working" || echo -e "${RED}✗${NC} Battery limit: Not working"
            else
                echo -e "${RED}✗${NC} asusctl: Not installed"
            fi

            if systemctl --user is-active --quiet rog-ally-restore.service; then
                echo -e "${GREEN}✓${NC} Service: Running"
            else
                echo -e "${RED}✗${NC} Service: Not running"
            fi

            if systemctl is-active --quiet power-profiles-daemon.service; then
                echo -e "${GREEN}✓${NC} Power profiles: Active"
            else
                echo -e "${RED}✗${NC} Power profiles: Inactive"
            fi

            echo
            wait_for_input
            ;;
        2)
            run_script "gather-system-info.sh" "Gathering detailed system information"
            ;;
        3)
            echo
            echo -e "${BOLD}Service Logs${NC}"
            echo
            echo -e "${CYAN}User service logs:${NC}"
            journalctl --user -u rog-ally-restore.service --no-pager -n 20 || echo "No user service logs"
            echo
            echo -e "${CYAN}Recent restoration logs:${NC}"
            if ls /home/deck/.local/share/rog-ally-suite/logs/restore-*.log &>/dev/null; then
                tail -n 10 /home/deck/.local/share/rog-ally-suite/logs/restore-*.log | tail -n 20
            else
                echo "No restoration logs found"
            fi
            echo
            wait_for_input
            ;;
        4)
            echo
            echo -e "${BOLD}Resetting Services${NC}"
            echo

            systemctl --user daemon-reload
            systemctl --user restart rog-ally-restore.service || echo "Service restart failed"

            echo -e "${GREEN}✓${NC} Services reset"
            echo
            wait_for_input
            ;;
        5)
            echo
            echo -e "${BOLD}Force Package Reinstall${NC}"
            echo
            read -p "This will reinstall all ASUS packages. Continue? (y/N): " -r
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                if [[ -f "/home/deck/.local/share/rog-ally-suite/scripts/system-restore.sh" ]]; then
                    /home/deck/.local/share/rog-ally-suite/scripts/system-restore.sh
                else
                    echo -e "${RED}✗${NC} Suite not installed"
                fi
            fi
            echo
            wait_for_input
            ;;
        6)
            echo
            echo -e "${BOLD}Fix Package Signature Issues${NC}"
            echo
            echo "This will attempt to fix common SteamOS package signature problems:"
            echo "• Clear corrupted package cache"
            echo "• Refresh package database"
            echo "• Reinitialize package keys"
            echo
            read -p "Continue with signature fix? (y/N): " -r
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo
                echo -e "${BLUE}[INFO]${NC} Clearing package cache..."
                sudo rm -rf /var/cache/pacman/pkg/* 2>/dev/null || echo "Cache clear failed"

                echo -e "${BLUE}[INFO]${NC} Refreshing package database..."
                sudo pacman -Sy || echo "Database refresh failed"

                echo -e "${BLUE}[INFO]${NC} Reinitializing package keys..."
                sudo pacman-key --init || echo "Key init failed"
                sudo pacman-key --populate archlinux || echo "Key populate failed"

                echo -e "${GREEN}✓${NC} Signature fix completed"
                echo "Try running the installation again"
            fi
            echo
            wait_for_input
            ;;
        b|B)
            return
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            sleep 1
            ;;
    esac
}

# Main menu loop
main() {
    # Show initial header and menu before enabling logging
    show_header
    show_status
    show_menu

    # Show log location info
    if [[ "$LOGGING_ENABLED" == "true" ]]; then
        echo -e "${CYAN}📝 Session log:${NC} $SESSION_LOG_FILE"
        echo -e "${CYAN}🔗 Latest log:${NC} $LATEST_LOG_LINK"
        echo -e "${DIM}Use 'tail -f $LATEST_LOG_LINK' to follow the log${NC}"
        echo
    fi

    # Now enable logging after the user sees the menu
    enable_logging

    while true; do
        read -p "Select an option: " choice

        # Log user selection
        if command -v log_message &>/dev/null; then
            log_message "DEBUG" "User selected option: $choice"
        fi

        case $choice in
            1)
                fresh_installation
                show_header
                show_status
                show_menu
                ;;
            2)
                run_script "verify-steamos-compatibility.sh" "Running system compatibility check"
                show_header
                show_status
                show_menu
                ;;
            3)
                run_script "install.sh" "Installing/upgrading ROG Ally Suite"
                show_header
                show_status
                show_menu
                ;;
            4)
                if [[ -f "/home/deck/.local/share/rog-ally-suite/scripts/system-restore.sh" ]]; then
                    echo -e "${BLUE}[INFO]${NC} Manually restoring ASUS controls"
                    echo -e "${DIM}Running: system-restore.sh${NC}"
                    echo

                    if /home/deck/.local/share/rog-ally-suite/scripts/system-restore.sh; then
                        echo
                        echo -e "${GREEN}✓ Success!${NC} ASUS controls restored."
                    else
                        echo
                        echo -e "${RED}✗ Error!${NC} Restoration failed."
                    fi
                    echo
                    wait_for_input
                else
                    echo -e "${RED}✗ Error!${NC} Suite not installed. Please install first."
                    echo
                    wait_for_input
                fi
                show_header
                show_status
                show_menu
                ;;
            5)
                configuration_menu
                show_header
                show_status
                show_menu
                ;;
            6)
                run_script "cleanup-legacy.sh" "Cleaning up legacy ROG Ally scripts"
                show_header
                show_status
                show_menu
                ;;
            7)
                run_script "gather-system-info.sh" "Gathering system information"
                show_header
                show_status
                show_menu
                ;;
            8)
                troubleshooting_menu
                show_header
                show_status
                show_menu
                ;;
            9)
                run_script "uninstall.sh" "Uninstalling ROG Ally Suite"
                show_header
                show_status
                show_menu
                ;;
            h|H)
                help_menu
                show_header
                show_status
                show_menu
                ;;
            q|Q)
                echo
                echo -e "${GREEN}Thank you for using ROG Ally Suite! 🎮${NC}"
                echo
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                sleep 1
                show_header
                show_status
                show_menu
                ;;
        esac
    done
}

# Check if running as deck user
if [[ "$USER" != "deck" ]] && [[ "$USER" != "$(whoami)" ]]; then
    echo -e "${RED}Warning:${NC} This script is designed to run as the 'deck' user on SteamOS."
    echo -e "Current user: $USER"
    echo
    read -p "Continue anyway? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Run main menu
main "$@"
