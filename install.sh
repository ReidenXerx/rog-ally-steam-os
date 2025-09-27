#!/bin/bash
# ROG Ally ASUS Control Suite Installer for SteamOS
# Automatically installs and configures ASUS hardware controls that persist across SteamOS updates
# Author: Improved by Claude
# Version: 2.0

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly INSTALL_DIR="/home/deck/.local/share/rog-ally-suite"
readonly LOG_DIR="/home/deck/.local/share/rog-ally-suite/logs"
readonly CONFIG_DIR="/home/deck/.config/rog-ally-suite"
readonly LOGFILE="${LOG_DIR}/install.log"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Ensure directories exist
mkdir -p "$INSTALL_DIR" "$LOG_DIR" "$CONFIG_DIR"

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

# Error handler
error_exit() {
    log "ERROR" "$1"
    exit 1
}

# Check if running as deck user
check_user() {
    if [[ "$USER" != "deck" ]]; then
        error_exit "This script must be run as the 'deck' user"
    fi
}

# Check sudo access
check_sudo() {
    log "INFO" "Checking sudo access..."

    if ! sudo -n true 2>/dev/null; then
        log "WARN" "Sudo access not configured. Setting up temporary access..."

        # Prompt for password once to set up proper sudoers
        if ! sudo true; then
            error_exit "Unable to obtain sudo access"
        fi
    fi

    log "SUCCESS" "Sudo access confirmed"
}

# Setup sudoers configuration
setup_sudoers() {
    log "INFO" "Setting up sudoers configuration..."

    local sudoers_file="/etc/sudoers.d/rog-ally-suite"
    local temp_sudoers=$(mktemp)

    cat > "$temp_sudoers" << EOF
# ROG Ally Suite - Allow specific commands without password
deck ALL=(ALL) NOPASSWD: \\
    /usr/bin/steamos-readonly, \\
    /usr/bin/mount, \\
    /usr/bin/pacman, \\
    /usr/bin/pacman-key, \\
    /usr/bin/systemctl, \\
    /usr/bin/tee /etc/pacman.conf, \\
    /usr/bin/asusctl, \\
    ${INSTALL_DIR}/scripts/system-restore.sh

# Validate sudoers syntax
Defaults:deck !requiretty
EOF

    # Validate sudoers syntax
    if ! sudo visudo -c -f "$temp_sudoers"; then
        rm -f "$temp_sudoers"
        error_exit "Invalid sudoers configuration generated"
    fi

    sudo cp "$temp_sudoers" "$sudoers_file"
    sudo chmod 440 "$sudoers_file"
    rm -f "$temp_sudoers"

    log "SUCCESS" "Sudoers configuration installed"
}

# Copy scripts to install directory
install_scripts() {
    log "INFO" "Installing scripts..."

    mkdir -p "${INSTALL_DIR}/scripts"

    # Copy all scripts from current directory
    cp "$SCRIPT_DIR"/*.sh "${INSTALL_DIR}/scripts/" 2>/dev/null || true

    # Make scripts executable
    chmod +x "${INSTALL_DIR}/scripts"/*.sh

    log "SUCCESS" "Scripts installed to $INSTALL_DIR"
}

# Create systemd user service for automatic restoration
create_systemd_service() {
    log "INFO" "Creating systemd user service..."

    local service_dir="/home/deck/.config/systemd/user"
    mkdir -p "$service_dir"

    cat > "${service_dir}/rog-ally-restore.service" << EOF
[Unit]
Description=ROG Ally ASUS Control Restoration
After=graphical-session.target
Wants=graphical-session.target

[Service]
Type=oneshot
ExecStart=${INSTALL_DIR}/scripts/system-restore.sh
StandardOutput=append:${LOG_DIR}/service.log
StandardError=append:${LOG_DIR}/service.log
RemainAfterExit=yes

[Install]
WantedBy=default.target
EOF

    # Enable the service
    systemctl --user daemon-reload
    systemctl --user enable rog-ally-restore.service

    log "SUCCESS" "Systemd service created and enabled"
}

# Create desktop autostart entry as fallback
create_autostart() {
    log "INFO" "Creating autostart entry..."

    local autostart_dir="/home/deck/.config/autostart"
    mkdir -p "$autostart_dir"

    cat > "${autostart_dir}/rog-ally-suite.desktop" << EOF
[Desktop Entry]
Type=Application
Name=ROG Ally Suite
Comment=Restore ASUS hardware controls after SteamOS updates
Exec=${INSTALL_DIR}/scripts/system-restore.sh
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
StartupNotify=false
EOF

    chmod +x "${autostart_dir}/rog-ally-suite.desktop"

    log "SUCCESS" "Autostart entry created"
}

# Create configuration file
create_config() {
    log "INFO" "Creating configuration..."

    cat > "${CONFIG_DIR}/config.conf" << EOF
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

    log "SUCCESS" "Configuration created at ${CONFIG_DIR}/config.conf"
}

# Main installation function
main() {
    log "INFO" "Starting ROG Ally Suite installation..."
    log "INFO" "Install directory: $INSTALL_DIR"
    log "INFO" "Log directory: $LOG_DIR"

    check_user
    check_sudo
    setup_sudoers
    install_scripts
    create_systemd_service
    create_autostart
    create_config

    log "SUCCESS" "Installation completed successfully!"
    log "INFO" "You can now run the restoration manually with: ${INSTALL_DIR}/scripts/system-restore.sh"
    log "INFO" "Or it will run automatically on next login/boot"
    log "INFO" "Configuration file: ${CONFIG_DIR}/config.conf"
    log "INFO" "Logs will be written to: $LOG_DIR"

    echo
    echo -e "${GREEN}Installation Summary:${NC}"
    echo "✓ Scripts installed to: $INSTALL_DIR"
    echo "✓ Systemd service enabled"
    echo "✓ Autostart entry created"
    echo "✓ Sudoers configured for passwordless operations"
    echo "✓ Configuration file created"
    echo
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Review configuration in: ${CONFIG_DIR}/config.conf"
    echo "2. Test the restoration: ${INSTALL_DIR}/scripts/system-restore.sh"
    echo "3. Reboot to test automatic restoration"
}

# Run main function
main "$@"
