#!/bin/bash
# SteamOS Compatibility Verification Script
# Checks if the current system has all required SteamOS-specific features

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
WARNINGS=0

# Test result tracking
log_test() {
    local status="$1"
    local test_name="$2"
    local details="$3"

    case "$status" in
        "PASS")
            echo -e "${GREEN}✓${NC} $test_name"
            [[ -n "$details" ]] && echo -e "  ${BLUE}→${NC} $details"
            ((CHECKS_PASSED++))
            ;;
        "FAIL")
            echo -e "${RED}✗${NC} $test_name"
            [[ -n "$details" ]] && echo -e "  ${RED}→${NC} $details"
            ((CHECKS_FAILED++))
            ;;
        "WARN")
            echo -e "${YELLOW}⚠${NC} $test_name"
            [[ -n "$details" ]] && echo -e "  ${YELLOW}→${NC} $details"
            ((WARNINGS++))
            ;;
    esac
}

echo -e "${BLUE}=== SteamOS Compatibility Verification ===${NC}"
echo "This script verifies that your system has all the necessary components"
echo "for the ROG Ally Suite to function properly on SteamOS."
echo
echo -e "${YELLOW}Note:${NC} This verification should be run on your target SteamOS/Linux system,"
echo "not on the development machine where you're preparing the scripts."
echo

# 1. Check if running on SteamOS
check_steamos() {
    echo -e "${BLUE}[1] Checking SteamOS Environment${NC}"

    # First check if we're on a Unix-like system
    local uname_output=$(uname -s 2>/dev/null || echo "unknown")

    if [[ "$uname_output" != "Linux" ]]; then
        log_test "FAIL" "Not running on Linux" "Detected: $uname_output"
        log_test "FAIL" "Platform compatibility" "This suite requires Linux (SteamOS/Arch)"
        echo
        return
    fi

    # Check for SteamOS version file
    if [[ -f /etc/os-release ]]; then
        local os_name=$(grep '^NAME=' /etc/os-release | cut -d'"' -f2 2>/dev/null || echo "Unknown")
        local os_id=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 2>/dev/null || echo "unknown")
        local os_version=$(grep '^VERSION=' /etc/os-release | cut -d'"' -f2 2>/dev/null || echo "Unknown")

        if [[ "$os_id" == "steamos" || "$os_name" == *"SteamOS"* ]]; then
            log_test "PASS" "SteamOS detected" "$os_name $os_version"
        elif [[ "$os_id" == "arch" || "$os_name" == *"Arch"* ]]; then
            log_test "PASS" "Arch Linux detected" "$os_name (compatible with SteamOS)"
        else
            log_test "WARN" "Different Linux distribution" "Detected: $os_name (ID: $os_id)"
            log_test "WARN" "Compatibility note" "Scripts are optimized for SteamOS/Arch but may work on other distributions"
        fi
    else
        log_test "FAIL" "Cannot detect OS" "/etc/os-release not found"
        log_test "WARN" "Compatibility unknown" "Unable to determine Linux distribution"
    fi
    echo
}

# 2. Check for deck user
check_deck_user() {
    echo -e "${BLUE}[2] Checking User Environment${NC}"

    if [[ "$USER" == "deck" ]]; then
        log_test "PASS" "Running as deck user" ""
    else
        log_test "WARN" "Not running as deck user" "Current user: $USER"
        log_test "WARN" "Path assumption" "Scripts assume /home/deck paths"
    fi

    # Check if /home/deck exists
    if [[ -d "/home/deck" ]]; then
        log_test "PASS" "Deck home directory exists" "/home/deck found"
    else
        log_test "FAIL" "Deck home directory missing" "/home/deck not found"
    fi
    echo
}

# 3. Check SteamOS-specific commands
check_steamos_commands() {
    echo -e "${BLUE}[3] Checking SteamOS-Specific Commands${NC}"

    # steamos-readonly command
    if command -v steamos-readonly &>/dev/null; then
        log_test "PASS" "steamos-readonly command available" "$(which steamos-readonly)"

        # Test if we can check readonly status
        if steamos-readonly status &>/dev/null; then
            local readonly_status=$(steamos-readonly status 2>/dev/null || echo "unknown")
            log_test "PASS" "steamos-readonly functional" "Current status: $readonly_status"
        else
            log_test "WARN" "steamos-readonly not functional" "May need sudo access"
        fi
    else
        log_test "FAIL" "steamos-readonly command missing" "Essential for enabling RW mode"
    fi

    # findmnt command (should be standard but let's verify)
    if command -v findmnt &>/dev/null; then
        log_test "PASS" "findmnt command available" "$(which findmnt)"

        # Test findmnt functionality
        if findmnt -no OPTIONS / &>/dev/null; then
            local mount_opts=$(findmnt -no OPTIONS / 2>/dev/null || echo "unknown")
            log_test "PASS" "findmnt functional" "Root mount options: $mount_opts"
        else
            log_test "WARN" "findmnt not working properly" ""
        fi
    else
        log_test "FAIL" "findmnt command missing" "Needed for checking filesystem status"
    fi
    echo
}

# 4. Check package management
check_package_management() {
    echo -e "${BLUE}[4] Checking Package Management${NC}"

    # pacman
    if command -v pacman &>/dev/null; then
        log_test "PASS" "pacman available" "$(which pacman)"

        # Check if we can query packages (should work in RO mode)
        if pacman -Q &>/dev/null; then
            local pkg_count=$(pacman -Q | wc -l)
            log_test "PASS" "pacman query functional" "$pkg_count packages installed"
        else
            log_test "WARN" "pacman queries not working" ""
        fi
    else
        log_test "FAIL" "pacman missing" "Required for package installation"
    fi

    # pacman-key
    if command -v pacman-key &>/dev/null; then
        log_test "PASS" "pacman-key available" "$(which pacman-key)"
    else
        log_test "FAIL" "pacman-key missing" "Required for repository setup"
    fi
    echo
}

# 5. Check systemd user services
check_systemd() {
    echo -e "${BLUE}[5] Checking Systemd User Services${NC}"

    # Check if systemd user instance is running
    if systemctl --user is-system-running &>/dev/null; then
        local status=$(systemctl --user is-system-running 2>/dev/null || echo "unknown")
        log_test "PASS" "Systemd user instance running" "Status: $status"
    else
        log_test "WARN" "Systemd user instance issues" "May affect service installation"
    fi

    # Check user service directory
    local user_service_dir="/home/deck/.config/systemd/user"
    if [[ -d "$user_service_dir" ]]; then
        log_test "PASS" "User service directory exists" "$user_service_dir"
    else
        log_test "PASS" "User service directory missing" "Will be created during installation"
    fi

    # Check if we can enable/disable services
    if systemctl --user list-units &>/dev/null; then
        local unit_count=$(systemctl --user list-units --no-legend | wc -l)
        log_test "PASS" "Systemctl user commands work" "$unit_count units loaded"
    else
        log_test "WARN" "Systemctl user commands failing" ""
    fi
    echo
}

# 6. Check filesystem structure
check_filesystem() {
    echo -e "${BLUE}[6] Checking Filesystem Structure${NC}"

    # Check if root is mounted
    if mountpoint -q /; then
        log_test "PASS" "Root filesystem mounted" ""

        # Check current mount options
        local mount_opts=$(findmnt -no OPTIONS / 2>/dev/null || echo "unknown")
        if echo "$mount_opts" | grep -q '\bro\b'; then
            log_test "PASS" "Root filesystem in read-only mode" "As expected for SteamOS"
        elif echo "$mount_opts" | grep -q '\brw\b'; then
            log_test "WARN" "Root filesystem in read-write mode" "Unusual for SteamOS default state"
        else
            log_test "WARN" "Cannot determine filesystem mode" "Mount options: $mount_opts"
        fi
    else
        log_test "FAIL" "Root filesystem issues" ""
    fi

    # Check critical directories
    local critical_dirs=("/etc" "/usr" "/var" "/home")
    for dir in "${critical_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            log_test "PASS" "Directory $dir exists" ""
        else
            log_test "FAIL" "Directory $dir missing" ""
        fi
    done
    echo
}

# 7. Check sudo configuration
check_sudo() {
    echo -e "${BLUE}[7] Checking Sudo Configuration${NC}"

    if command -v sudo &>/dev/null; then
        log_test "PASS" "sudo command available" "$(which sudo)"

        # Test sudo access (without actually running privileged commands)
        if sudo -n true 2>/dev/null; then
            log_test "PASS" "Passwordless sudo configured" ""
        else
            log_test "WARN" "Sudo requires password" "Installation will prompt for password"
        fi

        # Check existing sudoers files
        if [[ -d "/etc/sudoers.d" ]]; then
            log_test "PASS" "Sudoers.d directory exists" "/etc/sudoers.d"

            local existing_files=$(ls /etc/sudoers.d/ 2>/dev/null | wc -l)
            if [[ $existing_files -gt 0 ]]; then
                log_test "PASS" "Existing sudoers configurations" "$existing_files files found"
            fi
        else
            log_test "WARN" "Sudoers.d directory missing" ""
        fi
    else
        log_test "FAIL" "sudo command missing" "Required for system modifications"
    fi
    echo
}

# 8. Check desktop environment
check_desktop() {
    echo -e "${BLUE}[8] Checking Desktop Environment${NC}"

    # Check for autostart directory
    local autostart_dir="/home/deck/.config/autostart"
    if [[ -d "$autostart_dir" ]]; then
        log_test "PASS" "Autostart directory exists" "$autostart_dir"
    else
        log_test "PASS" "Autostart directory missing" "Will be created during installation"
    fi

    # Check for desktop session
    if [[ -n "${XDG_CURRENT_DESKTOP:-}" ]]; then
        log_test "PASS" "Desktop session detected" "$XDG_CURRENT_DESKTOP"
    elif [[ -n "${DESKTOP_SESSION:-}" ]]; then
        log_test "PASS" "Desktop session detected" "$DESKTOP_SESSION"
    else
        log_test "WARN" "No desktop session detected" "May be running in console mode"
    fi
    echo
}

# Main function
main() {

    check_steamos
    check_deck_user
    check_steamos_commands
    check_package_management
    check_systemd
    check_filesystem
    check_sudo
    check_desktop

    # Summary
    echo -e "${BLUE}=== Verification Summary ===${NC}"
    echo -e "${GREEN}Passed:${NC} $CHECKS_PASSED"
    echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
    echo -e "${RED}Failed:${NC} $CHECKS_FAILED"
    echo

    if [[ $CHECKS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✓ System appears compatible with ROG Ally Suite${NC}"
        if [[ $WARNINGS -gt 0 ]]; then
            echo -e "${YELLOW}⚠ Some warnings were found - review them above${NC}"
        fi
        echo -e "${BLUE}→ You can proceed with installation${NC}"
        exit 0
    else
        echo -e "${RED}✗ System compatibility issues detected${NC}"
        echo -e "${RED}→ Review failed checks above before installation${NC}"
        exit 1
    fi
}

# Run main function
main "$@"
