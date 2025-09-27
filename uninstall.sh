#!/bin/bash
# ROG Ally Suite Uninstaller
# Removes all components of the ROG Ally Suite while preserving user data

set -euo pipefail

# Configuration
readonly INSTALL_DIR="/home/deck/.local/share/rog-ally-suite"
readonly CONFIG_DIR="/home/deck/.config/rog-ally-suite"
readonly LOGFILE="/home/deck/rog-ally-uninstall.log"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case "$level" in
        "INFO")  echo -e "${BLUE}[INFO]${NC} $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS]${NC} $message" ;;
    esac

    echo "[$timestamp] [$level] $message" >> "$LOGFILE"
}

# Check if running as deck user
check_user() {
    if [[ "$USER" != "deck" ]]; then
        log "ERROR" "This script must be run as the 'deck' user"
        exit 1
    fi
}

# Confirm uninstallation
confirm_uninstall() {
    echo -e "${YELLOW}WARNING: This will remove the ROG Ally Suite${NC}"
    echo "The following will be removed:"
    echo "  - All scripts and binaries"
    echo "  - Systemd service"
    echo "  - Autostart entries"
    echo "  - Sudoers configuration"
    echo
    echo "The following will be PRESERVED:"
    echo "  - Your configuration files in ~/.config/rog-ally-suite"
    echo "  - Installed packages (asusctl, power-profiles-daemon)"
    echo "  - System services (they will keep running)"
    echo

    read -p "Are you sure you want to uninstall? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log "INFO" "Uninstallation cancelled by user"
        exit 0
    fi
}

# Remove systemd service
remove_systemd_service() {
    log "INFO" "Removing systemd user service..."

    local service_file="/home/deck/.config/systemd/user/rog-ally-restore.service"

    if systemctl --user is-enabled rog-ally-restore.service &>/dev/null; then
        systemctl --user disable rog-ally-restore.service
        log "SUCCESS" "Systemd service disabled"
    fi

    if systemctl --user is-active rog-ally-restore.service &>/dev/null; then
        systemctl --user stop rog-ally-restore.service
        log "SUCCESS" "Systemd service stopped"
    fi

    if [[ -f "$service_file" ]]; then
        rm -f "$service_file"
        log "SUCCESS" "Systemd service file removed"
    fi

    systemctl --user daemon-reload
}

# Remove autostart entry
remove_autostart() {
    log "INFO" "Removing autostart entry..."

    local autostart_file="/home/deck/.config/autostart/rog-ally-suite.desktop"

    if [[ -f "$autostart_file" ]]; then
        rm -f "$autostart_file"
        log "SUCCESS" "Autostart entry removed"
    else
        log "INFO" "Autostart entry not found"
    fi

    # Also remove old autostart entries
    local old_autostart="/home/deck/.config/autostart/rogfix.desktop"
    if [[ -f "$old_autostart" ]]; then
        rm -f "$old_autostart"
        log "SUCCESS" "Old autostart entry removed"
    fi
}

# Remove sudoers configuration
remove_sudoers() {
    log "INFO" "Removing sudoers configuration..."

    local sudoers_files=(
        "/etc/sudoers.d/rog-ally-suite"
        "/etc/sudoers.d/rogfix"  # Old file
    )

    for file in "${sudoers_files[@]}"; do
        if [[ -f "$file" ]]; then
            if sudo rm -f "$file"; then
                log "SUCCESS" "Removed sudoers file: $file"
            else
                log "WARN" "Failed to remove sudoers file: $file"
            fi
        fi
    done
}

# Remove installation directory
remove_install_dir() {
    log "INFO" "Removing installation directory..."

    if [[ -d "$INSTALL_DIR" ]]; then
        rm -rf "$INSTALL_DIR"
        log "SUCCESS" "Installation directory removed: $INSTALL_DIR"
    else
        log "INFO" "Installation directory not found"
    fi
}

# Clean up legacy files
remove_legacy_files() {
    log "INFO" "Cleaning up legacy files..."

    local legacy_files=(
        "/home/deck/rogfix.log"
        "/home/deck/fixlog.log"
        "/home/deck/startup.log"
        "/home/deck/restore_asusctl.sh"
        "/home/deck/rogfix-repair.sh"
        "/home/deck/startup-wrapper.sh"
    )

    for file in "${legacy_files[@]}"; do
        if [[ -f "$file" ]]; then
            rm -f "$file"
            log "SUCCESS" "Removed legacy file: $file"
        fi
    done
}

# Ask about configuration removal
ask_config_removal() {
    echo
    read -p "Do you want to remove configuration files as well? (yes/no): " -r
    if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        if [[ -d "$CONFIG_DIR" ]]; then
            rm -rf "$CONFIG_DIR"
            log "SUCCESS" "Configuration directory removed: $CONFIG_DIR"
        fi
    else
        log "INFO" "Configuration files preserved in: $CONFIG_DIR"
    fi
}

# Ask about package removal
ask_package_removal() {
    echo
    echo "The following packages were installed by ROG Ally Suite:"
    echo "  - asusctl"
    echo "  - power-profiles-daemon"
    echo
    read -p "Do you want to remove these packages? (yes/no): " -r
    if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log "INFO" "Removing packages..."

        # Enable read-write mode first
        if sudo steamos-readonly disable && sudo mount -o remount,rw /; then
            if sudo pacman -R --noconfirm asusctl power-profiles-daemon; then
                log "SUCCESS" "Packages removed successfully"
            else
                log "WARN" "Failed to remove some packages"
            fi
        else
            log "WARN" "Failed to enable read-write mode, cannot remove packages"
        fi
    else
        log "INFO" "Packages preserved"
    fi
}

# Main uninstall function
main() {
    log "INFO" "Starting ROG Ally Suite uninstallation..."

    check_user
    confirm_uninstall

    remove_systemd_service
    remove_autostart
    remove_sudoers
    remove_install_dir
    remove_legacy_files

    ask_config_removal
    ask_package_removal

    log "SUCCESS" "ROG Ally Suite uninstallation completed"

    echo
    echo -e "${GREEN}Uninstallation Summary:${NC}"
    echo "✓ Systemd service removed"
    echo "✓ Autostart entries removed"
    echo "✓ Sudoers configuration removed"
    echo "✓ Installation directory removed"
    echo "✓ Legacy files cleaned up"
    echo
    echo -e "${BLUE}Note:${NC} If you removed packages, you may want to reboot"
    echo "to ensure all services are properly stopped."
    echo
    echo "Uninstall log saved to: $LOGFILE"
}

# Run main function
main "$@"
