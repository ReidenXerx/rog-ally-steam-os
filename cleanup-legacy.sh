#!/bin/bash
# Legacy ROG Ally Scripts Cleanup
# Removes old scripts and configurations before installing the new suite

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Log function
log() {
    local level="$1"
    shift
    local message="$*"

    case "$level" in
        "INFO")  echo -e "${BLUE}[INFO]${NC} $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS]${NC} $message" ;;
    esac
}

# Check if running as deck user
check_user() {
    if [[ "$USER" != "deck" ]]; then
        log "ERROR" "This script must be run as the 'deck' user"
        exit 1
    fi
}

# Confirm cleanup
confirm_cleanup() {
    echo -e "${YELLOW}Legacy ROG Ally Scripts Cleanup${NC}"
    echo "This will remove old ROG Ally scripts and configurations:"
    echo
    echo "Files to be removed:"
    echo "  - /home/deck/restore_asusctl.sh"
    echo "  - /home/deck/rogfix-repair.sh"
    echo "  - /home/deck/startup-wrapper.sh"
    echo "  - /home/deck/.config/autostart/rogfix.desktop"
    echo
    echo "Log files to be removed:"
    echo "  - /home/deck/rogfix.log"
    echo "  - /home/deck/fixlog.log"
    echo "  - /home/deck/startup.log"
    echo
    echo "This cleanup is recommended before installing the new ROG Ally Suite"
    echo "to avoid conflicts between old and new scripts."
    echo

    read -p "Proceed with cleanup? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log "INFO" "Cleanup cancelled by user"
        exit 0
    fi
}

# Remove legacy scripts
remove_legacy_scripts() {
    log "INFO" "Removing legacy ROG Ally scripts..."

    local legacy_scripts=(
        "/home/deck/restore_asusctl.sh"
        "/home/deck/rogfix-repair.sh"
        "/home/deck/startup-wrapper.sh"
    )

    local removed=0
    for script in "${legacy_scripts[@]}"; do
        if [[ -f "$script" ]]; then
            if rm -f "$script" 2>/dev/null; then
                log "SUCCESS" "Removed: $script"
                ((removed++))
            else
                log "WARN" "Failed to remove: $script (permission denied?)"
            fi
        else
            log "INFO" "Not found: $script"
        fi
    done

    log "INFO" "Removed $removed legacy script(s)"
}

# Remove legacy autostart entries
remove_legacy_autostart() {
    log "INFO" "Removing legacy autostart entries..."

    local legacy_autostart=(
        "/home/deck/.config/autostart/rogfix.desktop"
    )

    local removed=0
    for entry in "${legacy_autostart[@]}"; do
        if [[ -f "$entry" ]]; then
            if rm -f "$entry" 2>/dev/null; then
                log "SUCCESS" "Removed: $entry"
                ((removed++))
            else
                log "WARN" "Failed to remove: $entry (permission denied?)"
            fi
        else
            log "INFO" "Not found: $entry"
        fi
    done

    log "INFO" "Removed $removed legacy autostart entrie(s)"
}

# Remove legacy log files
remove_legacy_logs() {
    log "INFO" "Removing legacy log files..."

    local legacy_logs=(
        "/home/deck/rogfix.log"
        "/home/deck/fixlog.log"
        "/home/deck/startup.log"
    )

    local removed=0
    for logfile in "${legacy_logs[@]}"; do
        if [[ -f "$logfile" ]]; then
            # Show file size before removal
            local size=$(du -h "$logfile" 2>/dev/null | cut -f1 || echo "unknown")
            if rm -f "$logfile" 2>/dev/null; then
                log "SUCCESS" "Removed: $logfile ($size)"
                ((removed++))
            else
                log "WARN" "Failed to remove: $logfile (permission denied?)"
            fi
        else
            log "INFO" "Not found: $logfile"
        fi
    done

    log "INFO" "Removed $removed legacy log file(s)"
}

# Remove legacy sudoers (if any)
remove_legacy_sudoers() {
    log "INFO" "Checking for legacy sudoers configurations..."

    local legacy_sudoers=(
        "/etc/sudoers.d/rogfix"
    )

    local removed=0
    for sudoers_file in "${legacy_sudoers[@]}"; do
        if [[ -f "$sudoers_file" ]]; then
            if sudo rm -f "$sudoers_file"; then
                log "SUCCESS" "Removed legacy sudoers: $sudoers_file"
                ((removed++))
            else
                log "WARN" "Failed to remove: $sudoers_file"
            fi
        else
            log "INFO" "Not found: $sudoers_file"
        fi
    done

    if [[ $removed -eq 0 ]]; then
        log "INFO" "No legacy sudoers configurations found"
    else
        log "INFO" "Removed $removed legacy sudoers file(s)"
    fi
}

# Check for running legacy processes
check_legacy_processes() {
    log "INFO" "Checking for running legacy processes..."

    local legacy_processes=$(ps aux | grep -E "(restore_asusctl|rogfix|startup-wrapper)" | grep -v grep || true)

    if [[ -n "$legacy_processes" ]]; then
        log "WARN" "Found running legacy processes:"
        echo "$legacy_processes"
        echo
        log "WARN" "You may want to kill these processes manually"
    else
        log "SUCCESS" "No running legacy processes found"
    fi
}

# Main cleanup function
main() {
    log "INFO" "Starting legacy ROG Ally scripts cleanup..."

    check_user
    confirm_cleanup

    local cleanup_errors=0

    remove_legacy_scripts || ((cleanup_errors++))
    remove_legacy_autostart || ((cleanup_errors++))
    remove_legacy_logs || ((cleanup_errors++))
    remove_legacy_sudoers || ((cleanup_errors++))
    check_legacy_processes || true  # This shouldn't cause failure

    if [[ $cleanup_errors -eq 0 ]]; then
        log "SUCCESS" "Legacy cleanup completed successfully!"
    else
        log "SUCCESS" "Legacy cleanup completed with $cleanup_errors warnings (check output above)"
    fi

    echo
    echo -e "${GREEN}Cleanup Summary:${NC}"
    echo "✓ Legacy scripts processed"
    echo "✓ Legacy autostart entries processed"
    echo "✓ Legacy log files processed"
    echo "✓ Legacy sudoers checked"
    echo "✓ Legacy processes checked"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Run the new installer: ./install.sh"
    echo "2. Configure settings: ~/.config/rog-ally-suite/config.conf"
    echo "3. Test the restoration: ~/.local/share/rog-ally-suite/scripts/system-restore.sh"

    # Exit with success even if there were warnings
    exit 0
}

# Run main function
main "$@"
