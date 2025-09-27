#!/bin/bash
# ROG Ally System Restoration Script
# Restores ASUS hardware controls after SteamOS updates
# This script is designed to run automatically and handle all edge cases

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BASE_DIR="$(dirname "$SCRIPT_DIR")"
readonly CONFIG_DIR="/home/deck/.config/rog-ally-suite"

# Initialize comprehensive logging
if [[ -f "$BASE_DIR/logger.sh" ]]; then
    source "$BASE_DIR/logger.sh"
    init_logging "$@"
    log_message "SYSTEM" "ROG Ally System Restoration started"
    log_system_info
    cleanup_logs 30
    
    # Use the session log from logger
    readonly LOG_DIR="$(dirname "$(get_current_log)")"
    readonly LOGFILE="$(get_current_log)"
else
    # Fallback logging if logger.sh is missing
    readonly LOG_DIR="${BASE_DIR}/logs"
    readonly LOGFILE="${LOG_DIR}/restore-$(date +%Y%m%d-%H%M%S).log"
    mkdir -p "$LOG_DIR"
    exec > >(tee -a "$LOGFILE")
    exec 2> >(tee -a "$LOGFILE" >&2)
    echo "$(date) [SYSTEM] Fallback logging initialized: $LOGFILE"
fi

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Load configuration
load_config() {
    local config_file="${CONFIG_DIR}/config.conf"

    # Default values
    BATTERY_LIMIT=80
    AUTO_POWER_PROFILES=true
    LOG_RETENTION_DAYS=30
    G14_REPO_URL="https://arch.asus-linux.org"
    REQUIRED_PACKAGES=(asusctl power-profiles-daemon)

    # Load user configuration if exists
    if [[ -f "$config_file" ]]; then
        # Source the config file safely
        source "$config_file"
    fi
}

# Logging function (enhanced with universal logger)
log() {
    local level="$1"
    shift
    local message="$*"
    
    # Use enhanced logging if available, otherwise fallback
    if command -v log_message &>/dev/null; then
        log_message "$level" "$message"
    else
        # Fallback logging
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        
        case "$level" in
            "INFO")  echo -e "${BLUE}[INFO]${NC} $message" ;;
            "WARN")  echo -e "${YELLOW}[WARN]${NC} $message" ;;
            "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
            "SUCCESS") echo -e "${GREEN}[SUCCESS]${NC} $message" ;;
        esac
        
        echo "[$timestamp] [$level] $message" >> "$LOGFILE"
    fi
}

# Cleanup old logs
cleanup_logs() {
    find "$LOG_DIR" -name "restore-*.log" -mtime +${LOG_RETENTION_DAYS} -delete 2>/dev/null || true
}

# Check if system needs restoration
needs_restoration() {
    log "INFO" "Checking if restoration is needed..."

    # Check if packages are installed
    for package in "${REQUIRED_PACKAGES[@]}"; do
        if ! pacman -Qi "$package" &>/dev/null; then
            log "INFO" "Package $package is missing, restoration needed"
            return 0
        fi
    done

    # Check if services are running
    if [[ "$AUTO_POWER_PROFILES" == "true" ]]; then
        if ! systemctl is-active --quiet power-profiles-daemon.service; then
            log "INFO" "power-profiles-daemon service not running, restoration needed"
            return 0
        fi
    fi

    # Check if asusctl is functional
    if ! command -v asusctl &>/dev/null; then
        log "INFO" "asusctl command not available, restoration needed"
        return 0
    fi

    log "INFO" "System appears to be in good state, checking anyway..."
    return 0  # Always run for now, can be optimized later
}

# Enable read-write mode on root filesystem
enable_rw_mode() {
    log "INFO" "Checking filesystem mount mode..."

    local mount_status
    mount_status=$(findmnt -no OPTIONS /)

    if echo "$mount_status" | grep -q '\brw\b'; then
        log "SUCCESS" "Root filesystem already in read-write mode"
        return 0
    fi

    log "INFO" "Enabling read-write mode on root filesystem..."

    # Check if steamos-readonly command exists (SteamOS-specific)
    if command -v steamos-readonly &>/dev/null; then
        # Disable SteamOS read-only mode
        if ! sudo steamos-readonly disable; then
            log "ERROR" "Failed to disable SteamOS read-only mode"
            return 1
        fi
        log "INFO" "SteamOS read-only mode disabled"
    else
        log "WARN" "steamos-readonly command not found - may not be running on SteamOS"
        log "INFO" "Attempting direct remount..."
    fi

    sleep 2

    # Remount root as read-write
    if ! sudo mount -o remount,rw /; then
        log "ERROR" "Failed to remount root filesystem as read-write"

        # Additional SteamOS-specific troubleshooting
        if command -v steamos-readonly &>/dev/null; then
            local readonly_status
            readonly_status=$(steamos-readonly status 2>/dev/null || echo "unknown")
            log "ERROR" "SteamOS readonly status: $readonly_status"

            # Try alternative approach
            log "INFO" "Attempting alternative SteamOS unlock method..."
            if sudo steamos-readonly disable --force 2>/dev/null; then
                sleep 3
                sudo mount -o remount,rw / || return 1
            else
                return 1
            fi
        else
            return 1
        fi
    fi

    # Verify the change
    mount_status=$(findmnt -no OPTIONS /)
    if echo "$mount_status" | grep -q '\brw\b'; then
        log "SUCCESS" "Root filesystem successfully mounted as read-write"
        return 0
    else
        log "ERROR" "Failed to enable read-write mode (still: $mount_status)"
        return 1
    fi
}

# Setup pacman keys and repository
setup_pacman() {
    log "INFO" "Setting up pacman keys and repositories..."

    # Initialize pacman keys
    log "INFO" "Initializing pacman keyring..."
    sudo pacman-key --init || {
        log "WARN" "Pacman key init failed, continuing anyway"
    }

    sudo pacman-key --populate archlinux || {
        log "WARN" "Pacman key populate failed, continuing anyway"
    }

    # Add G14 repository key
    log "INFO" "Adding G14 repository key..."
    sudo pacman-key --recv-keys 8F654886F17D497FEFE3DB448B15A6B0E9A3FA35 || {
        log "WARN" "Failed to receive G14 key, continuing anyway"
    }

    sudo pacman-key --lsign-key 8F654886F17D497FEFE3DB448B15A6B0E9A3FA35 || {
        log "WARN" "Failed to sign G14 key, continuing anyway"
    }

    # Add G14 repository to pacman.conf if not present
    if ! grep -q "\[g14\]" /etc/pacman.conf; then
        log "INFO" "Adding G14 repository to pacman.conf..."

        local repo_config
        repo_config=$(cat << EOF

[g14]
SigLevel = Never
Server = ${G14_REPO_URL}
EOF
        )

        echo "$repo_config" | sudo tee -a /etc/pacman.conf > /dev/null
        log "SUCCESS" "G14 repository added"
    else
        log "INFO" "G14 repository already present in pacman.conf"
    fi

    # Force database refresh for g14 repo (common issue on SteamOS)
    log "INFO" "Refreshing G14 repository database..."
    if ! sudo pacman -Sy --noconfirm; then
        log "WARN" "Initial database refresh failed, trying alternative approach..."
        # Sometimes the database needs to be cleared first
        sudo rm -f /usr/lib/holo/pacmandb/sync/g14.db* 2>/dev/null || true
        if ! sudo pacman -Sy --noconfirm; then
            log "ERROR" "Failed to refresh package databases after multiple attempts"
            return 1
        fi
    fi

    # Update package databases
    log "INFO" "Updating package databases..."
    if ! sudo pacman -Sy; then
        log "ERROR" "Failed to update package databases"
        return 1
    fi

    log "SUCCESS" "Pacman setup completed"
}

# Install required packages
install_packages() {
    log "INFO" "Installing required packages..."

    local missing_packages=()

    # Check which packages are missing
    for package in "${REQUIRED_PACKAGES[@]}"; do
        if ! pacman -Qi "$package" &>/dev/null; then
            missing_packages+=("$package")
        fi
    done

    if [[ ${#missing_packages[@]} -eq 0 ]]; then
        log "SUCCESS" "All required packages are already installed"
        return 0
    fi

    log "INFO" "Installing missing packages: ${missing_packages[*]}"

    # First attempt: Standard installation
    if sudo pacman -S --noconfirm "${missing_packages[@]}"; then
        log "SUCCESS" "Packages installed successfully"
        return 0
    fi

    log "WARN" "Standard installation failed, trying alternative approaches..."

    # Second attempt: Skip signature verification for problematic packages
    log "INFO" "Attempting installation with relaxed signature checking..."
    if sudo pacman -S --noconfirm --assume-installed gnupg "${missing_packages[@]}"; then
        log "SUCCESS" "Packages installed with relaxed signature checking"
        return 0
    fi

    # Third attempt: Install packages individually to isolate issues
    log "INFO" "Attempting individual package installation..."
    local installed_packages=()
    local failed_packages=()

    for package in "${missing_packages[@]}"; do
        log "INFO" "Installing $package individually..."

        # Try standard install first
        if sudo pacman -S --noconfirm "$package"; then
            installed_packages+=("$package")
            log "SUCCESS" "Installed: $package"
        else
            # Try with signature bypass for SteamOS packages
            log "WARN" "Standard install failed for $package, trying signature bypass..."
            if sudo pacman -U --noconfirm --assume-installed gnupg "/var/cache/pacman/pkg/${package}-"*.pkg.tar.* 2>/dev/null || \
               sudo pacman -S --noconfirm --disable-download-timeout "$package"; then
                installed_packages+=("$package")
                log "SUCCESS" "Installed with bypass: $package"
            else
                failed_packages+=("$package")
                log "ERROR" "Failed to install: $package"
            fi
        fi
    done

    # Report results
    if [[ ${#installed_packages[@]} -gt 0 ]]; then
        log "SUCCESS" "Successfully installed: ${installed_packages[*]}"
    fi

    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        log "ERROR" "Failed to install: ${failed_packages[*]}"
        log "WARN" "This may be due to SteamOS signature issues. You can try:"
        log "WARN" "1. Reboot and run the script again"
        log "WARN" "2. Clear package cache: sudo rm -rf /var/cache/pacman/pkg/*"
        log "WARN" "3. Refresh keys: sudo pacman-key --refresh-keys"

        # Don't fail completely if at least some packages were installed
        if [[ ${#installed_packages[@]} -gt 0 ]]; then
            log "WARN" "Partial installation completed, continuing..."
            return 0
        else
            return 1
        fi
    fi

    log "SUCCESS" "All packages installed successfully"
    return 0
}

# Configure and start services
setup_services() {
    log "INFO" "Setting up services..."

    if [[ "$AUTO_POWER_PROFILES" == "true" ]]; then
        log "INFO" "Enabling power-profiles-daemon service..."

        if sudo systemctl enable --now power-profiles-daemon.service; then
            log "SUCCESS" "power-profiles-daemon service enabled and started"
        else
            log "WARN" "Failed to enable power-profiles-daemon service"
        fi
    fi
}

# Configure ASUS hardware
configure_asus_hardware() {
    log "INFO" "Configuring ASUS hardware..."

    # Check if asusctl is available
    if ! command -v asusctl &>/dev/null; then
        log "ERROR" "asusctl command not found after installation"
        return 1
    fi

    # Set battery charge limit
    if [[ "$BATTERY_LIMIT" -gt 0 && "$BATTERY_LIMIT" -le 100 ]]; then
        log "INFO" "Setting battery charge limit to ${BATTERY_LIMIT}%..."

        if sudo asusctl -c "$BATTERY_LIMIT"; then
            log "SUCCESS" "Battery charge limit set to ${BATTERY_LIMIT}%"
        else
            log "WARN" "Failed to set battery charge limit"
        fi
    fi

    # Additional ASUS configurations can be added here
    log "SUCCESS" "ASUS hardware configuration completed"
}

# Perform system health check
health_check() {
    log "INFO" "Performing system health check..."

    local errors=0

    # Check packages
    for package in "${REQUIRED_PACKAGES[@]}"; do
        if ! pacman -Qi "$package" &>/dev/null; then
            log "ERROR" "Package $package is not installed"
            ((errors++))
        fi
    done

    # Check services
    if [[ "$AUTO_POWER_PROFILES" == "true" ]]; then
        if ! systemctl is-active --quiet power-profiles-daemon.service; then
            log "ERROR" "power-profiles-daemon service is not running"
            ((errors++))
        fi
    fi

    # Check asusctl functionality
    if ! command -v asusctl &>/dev/null; then
        log "ERROR" "asusctl command is not available"
        ((errors++))
    elif ! asusctl --help &>/dev/null; then
        log "ERROR" "asusctl command is not functional"
        ((errors++))
    fi

    if [[ $errors -eq 0 ]]; then
        log "SUCCESS" "System health check passed"
        return 0
    else
        log "ERROR" "System health check failed with $errors errors"
        return 1
    fi
}

# Main restoration function
main() {
    local start_time=$(date)
    log "INFO" "Starting ROG Ally system restoration at $start_time"
    log "INFO" "Log file: $LOGFILE"

    # Load configuration
    load_config

    # Cleanup old logs
    cleanup_logs

    # Check if restoration is needed
    if ! needs_restoration; then
        log "INFO" "System restoration not needed, exiting"
        exit 0
    fi

    # Perform restoration steps
    if ! enable_rw_mode; then
        log "ERROR" "Failed to enable read-write mode, cannot continue"
        exit 1
    fi

    if ! setup_pacman; then
        log "ERROR" "Failed to setup pacman, cannot continue"
        exit 1
    fi

    if ! install_packages; then
        log "ERROR" "Failed to install packages, cannot continue"
        exit 1
    fi

    setup_services
    configure_asus_hardware

    # Final health check
    if health_check; then
        local end_time=$(date)
        log "SUCCESS" "ROG Ally system restoration completed successfully at $end_time"
        log "INFO" "Started: $start_time"
        log "INFO" "Finished: $end_time"
        exit 0
    else
        log "ERROR" "System restoration completed with errors"
        exit 1
    fi
}

# Handle script termination
trap 'log "WARN" "Script interrupted or terminated"' INT TERM

# Run main function
main "$@"
