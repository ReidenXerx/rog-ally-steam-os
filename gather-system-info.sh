#!/bin/bash
# SteamOS System Information Gatherer
# Collects comprehensive system information for ROG Ally Suite compatibility analysis

set -euo pipefail

# Configuration
readonly LOGFILE="/home/deck/steamos-system-info-$(date +%Y%m%d-%H%M%S).log"
readonly SCRIPT_VERSION="1.0"

# Colors for console output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Logging function that writes to both console and file
log_both() {
    local message="$*"
    echo -e "$message" | tee -a "$LOGFILE"
}

# Safe command execution with error handling
safe_run() {
    local description="$1"
    shift
    local cmd="$*"

    log_both "${BLUE}[INFO]${NC} $description"
    log_both "Command: $cmd"
    log_both "--- OUTPUT START ---"

    if eval "$cmd" >> "$LOGFILE" 2>&1; then
        log_both "--- OUTPUT END (SUCCESS) ---"
    else
        log_both "--- OUTPUT END (FAILED - Exit code: $?) ---"
    fi
    log_both ""
}

# Safe file content display
safe_cat() {
    local description="$1"
    local filepath="$2"

    log_both "${BLUE}[INFO]${NC} $description"
    log_both "File: $filepath"
    log_both "--- CONTENT START ---"

    if [[ -f "$filepath" ]]; then
        cat "$filepath" >> "$LOGFILE" 2>&1 || log_both "Error reading file"
    else
        log_both "File not found"
    fi

    log_both "--- CONTENT END ---"
    log_both ""
}

# Safe directory listing
safe_ls() {
    local description="$1"
    local dirpath="$2"
    local extra_args="${3:-}"

    log_both "${BLUE}[INFO]${NC} $description"
    log_both "Directory: $dirpath"
    log_both "--- LISTING START ---"

    if [[ -d "$dirpath" ]]; then
        eval "ls $extra_args '$dirpath'" >> "$LOGFILE" 2>&1 || log_both "Error listing directory"
    else
        log_both "Directory not found"
    fi

    log_both "--- LISTING END ---"
    log_both ""
}

# Main information gathering function
main() {
    # Initialize log file
    cat > "$LOGFILE" << EOF
================================================================================
SteamOS System Information Report
Generated: $(date)
Script Version: $SCRIPT_VERSION
================================================================================

EOF

    log_both "${GREEN}=== SteamOS System Information Gatherer ===${NC}"
    log_both "Collecting comprehensive system information..."
    log_both "Log file: $LOGFILE"
    log_both ""

    # ========================================================================
    # BASIC SYSTEM INFORMATION
    # ========================================================================
    log_both "${YELLOW}=== 1. BASIC SYSTEM INFORMATION ===${NC}"

    safe_cat "OS Release Information" "/etc/os-release"
    safe_run "Kernel and System Info" "uname -a"
    safe_run "Current User Info" "whoami"
    safe_run "Current Directory" "pwd"
    safe_run "Home Directory" "echo \$HOME"
    safe_run "User ID Info" "id"
    safe_run "Uptime" "uptime"
    safe_run "System Load" "cat /proc/loadavg"

    # ========================================================================
    # STEAMOS-SPECIFIC COMMANDS
    # ========================================================================
    log_both "${YELLOW}=== 2. STEAMOS-SPECIFIC COMMANDS ===${NC}"

    safe_run "steamos-readonly location" "which steamos-readonly"
    safe_run "steamos-readonly help" "steamos-readonly --help"
    safe_run "steamos-readonly status" "steamos-readonly status"
    safe_run "steamos-readonly version" "steamos-readonly --version"

    # ========================================================================
    # FILESYSTEM INFORMATION
    # ========================================================================
    log_both "${YELLOW}=== 3. FILESYSTEM INFORMATION ===${NC}"

    safe_run "Root filesystem mount options" "findmnt -no OPTIONS /"
    safe_run "All mount points" "findmnt"
    safe_run "Mount command output for root" "mount | grep ' / '"
    safe_run "Disk space usage" "df -h"
    safe_run "Filesystem types" "lsblk -f"

    # ========================================================================
    # USER ENVIRONMENT
    # ========================================================================
    log_both "${YELLOW}=== 4. USER ENVIRONMENT ===${NC}"

    safe_ls "Home directory contents" "/home/deck" "-la"
    safe_ls "Config directory" "/home/deck/.config" "-la"
    safe_ls "Local share directory" "/home/deck/.local/share" "-la"
    safe_ls "Local bin directory" "/home/deck/.local/bin" "-la"

    safe_run "Environment variables" "env | sort"
    safe_run "Shell information" "echo \$SHELL"
    safe_run "PATH variable" "echo \$PATH"

    # ========================================================================
    # PACKAGE MANAGEMENT
    # ========================================================================
    log_both "${YELLOW}=== 5. PACKAGE MANAGEMENT ===${NC}"

    safe_run "pacman location" "which pacman"
    safe_run "pacman version" "pacman --version"
    safe_run "pacman-key location" "which pacman-key"

    safe_cat "pacman.conf" "/etc/pacman.conf"
    safe_ls "pacman.d directory" "/etc/pacman.d" "-la"

    safe_run "Currently installed packages (count)" "pacman -Q | wc -l"
    safe_run "ASUS-related packages" "pacman -Q | grep -i asus || echo 'No ASUS packages found'"
    safe_run "Power-related packages" "pacman -Q | grep -i power || echo 'No power packages found'"
    safe_run "asusctl package" "pacman -Qi asusctl || echo 'asusctl not installed'"
    safe_run "power-profiles-daemon package" "pacman -Qi power-profiles-daemon || echo 'power-profiles-daemon not installed'"

    # ========================================================================
    # SYSTEMD INFORMATION
    # ========================================================================
    log_both "${YELLOW}=== 6. SYSTEMD INFORMATION ===${NC}"

    safe_run "systemctl location" "which systemctl"
    safe_run "systemd user status" "systemctl --user is-system-running"
    safe_run "systemd user units (first 20)" "systemctl --user list-units | head -20"
    safe_run "systemd user services" "systemctl --user list-unit-files --type=service | head -20"

    safe_ls "User systemd directory" "/home/deck/.config/systemd" "-la"
    safe_ls "User systemd services" "/home/deck/.config/systemd/user" "-la"

    # ========================================================================
    # SUDO CONFIGURATION
    # ========================================================================
    log_both "${YELLOW}=== 7. SUDO CONFIGURATION ===${NC}"

    safe_run "sudo location" "which sudo"
    safe_run "sudo version" "sudo --version"
    safe_run "Current sudo permissions" "sudo -l || echo 'Cannot list sudo permissions'"

    safe_ls "sudoers.d directory" "/etc/sudoers.d" "-la"
    safe_run "sudoers.d files content" "find /etc/sudoers.d -type f -exec echo 'File: {}' \\; -exec cat {} \\; 2>/dev/null || echo 'Cannot read sudoers files'"

    # ========================================================================
    # DESKTOP ENVIRONMENT
    # ========================================================================
    log_both "${YELLOW}=== 8. DESKTOP ENVIRONMENT ===${NC}"

    safe_ls "Autostart directory" "/home/deck/.config/autostart" "-la"
    safe_run "Desktop session info" "echo \"XDG_CURRENT_DESKTOP: \$XDG_CURRENT_DESKTOP\""
    safe_run "Desktop session" "echo \"DESKTOP_SESSION: \$DESKTOP_SESSION\""
    safe_run "Display info" "echo \"DISPLAY: \$DISPLAY\""
    safe_run "Wayland info" "echo \"WAYLAND_DISPLAY: \$WAYLAND_DISPLAY\""

    # ========================================================================
    # HARDWARE INFORMATION
    # ========================================================================
    log_both "${YELLOW}=== 9. HARDWARE INFORMATION ===${NC}"

    safe_run "CPU info" "lscpu"
    safe_run "Memory info" "free -h"
    safe_run "Hardware info (brief)" "lshw -short 2>/dev/null || echo 'lshw not available'"
    safe_run "USB devices" "lsusb 2>/dev/null || echo 'lsusb not available'"
    safe_run "PCI devices" "lspci 2>/dev/null || echo 'lspci not available'"

    safe_cat "CPU info detailed" "/proc/cpuinfo"
    safe_cat "Memory info detailed" "/proc/meminfo"

    # ========================================================================
    # ASUS-SPECIFIC CHECKS
    # ========================================================================
    log_both "${YELLOW}=== 10. ASUS-SPECIFIC CHECKS ===${NC}"

    safe_run "asusctl command availability" "which asusctl || echo 'asusctl not found'"
    safe_run "asusctl version" "asusctl --version || echo 'asusctl not available'"
    safe_run "asusctl help" "asusctl --help || echo 'asusctl not available'"
    safe_run "Current battery limit" "asusctl -c || echo 'Cannot get battery limit'"

    safe_run "ASUS-related processes" "ps aux | grep -i asus || echo 'No ASUS processes found'"
    safe_run "Power profiles daemon status" "systemctl status power-profiles-daemon.service || echo 'power-profiles-daemon not running'"

    # ========================================================================
    # NETWORK INFORMATION
    # ========================================================================
    log_both "${YELLOW}=== 11. NETWORK INFORMATION ===${NC}"

    safe_run "Network interfaces" "ip addr show"
    safe_run "Network connectivity test" "ping -c 3 8.8.8.8 || echo 'Network connectivity test failed'"
    safe_run "DNS resolution test" "nslookup google.com || echo 'DNS test failed'"

    # ========================================================================
    # EXISTING ROG ALLY CONFIGURATIONS
    # ========================================================================
    log_both "${YELLOW}=== 12. EXISTING ROG ALLY CONFIGURATIONS ===${NC}"

    safe_ls "Check for existing ROG scripts in home" "/home/deck" "-la | grep -i rog || echo 'No ROG files found'"
    safe_run "Check for existing ROG processes" "ps aux | grep -i rog || echo 'No ROG processes found'"
    safe_run "Check for existing autostart entries" "find /home/deck/.config/autostart -name '*rog*' -o -name '*asus*' 2>/dev/null || echo 'No ROG/ASUS autostart entries found'"

    # ========================================================================
    # SUMMARY
    # ========================================================================
    log_both "${YELLOW}=== INFORMATION GATHERING COMPLETE ===${NC}"

    local end_time=$(date)
    log_both "Collection completed at: $end_time"
    log_both "Total log file size: $(du -h "$LOGFILE" | cut -f1)"
    log_both ""
    log_both "${GREEN}✅ System information successfully collected!${NC}"
    log_both "${BLUE}📁 Log file saved to: $LOGFILE${NC}"
    log_both ""
    log_both "You can now share this log file for analysis."
    log_both "The file contains comprehensive system information needed"
    log_both "to optimize the ROG Ally Suite for your SteamOS setup."
}

# Error handling
trap 'echo -e "\n${RED}Script interrupted!${NC}" | tee -a "$LOGFILE"' INT TERM

# Run main function
main "$@"
