# ROG Ally Suite for SteamOS

A comprehensive solution for maintaining ASUS ROG Ally hardware controls on SteamOS that automatically restores functionality after system updates.

## 🎯 What This Solves

SteamOS is an immutable operating system that wipes custom installations during updates. This suite:

-   **Automatically restores** ASUS hardware controls (`asusctl`) after SteamOS updates
-   **Manages power profiles** for optimal performance and battery life
-   **Sets battery charge limits** to preserve battery health
-   **Provides seamless automation** with proper sudo configuration
-   **Includes comprehensive logging** for troubleshooting

## 🚀 Features

-   ✅ **Persistent across updates**: Survives SteamOS system updates
-   ✅ **Automatic restoration**: Runs on boot/login without user intervention
-   ✅ **Battery management**: Configurable charge limits (default 80%)
-   ✅ **Power profiles**: Automatic power-profiles-daemon management
-   ✅ **Secure sudo**: Minimal permissions with proper sudoers configuration
-   ✅ **Comprehensive logging**: Detailed logs for troubleshooting
-   ✅ **Easy configuration**: Simple config file for customization
-   ✅ **Clean uninstaller**: Complete removal when needed

## 📦 Installation

### 🎯 **Super Easy Start (Recommended)**

**Just run this one command:**

```bash
./start.sh
```

**Or use the full interactive menu:**

```bash
./rog-ally-menu.sh
```

The menu provides:
- 🆕 **Fresh Installation Wizard** - Perfect for new users
- ✅ **System Compatibility Check** - Verify your setup
- ⚙️ **Configuration Manager** - Easy settings management
- 🔧 **Troubleshooting Tools** - Fix issues quickly
- 📚 **Built-in Help System** - No need to read docs

### 🚀 **Manual Installation (Advanced Users)**

#### Step 1: Compatibility Check

```bash
chmod +x verify-steamos-compatibility.sh
./verify-steamos-compatibility.sh
```

#### Step 2: Legacy Cleanup (If Upgrading)

```bash
chmod +x cleanup-legacy.sh
./cleanup-legacy.sh
```

#### Step 3: Install

```bash
chmod +x install.sh
./install.sh
```

The installer will:

1. Set up proper directory structure
2. Configure sudoers for passwordless operations
3. Install systemd service for automatic restoration
4. Create fallback autostart entry
5. Generate configuration file

### Manual Steps (if needed)

If the automatic sudo setup fails, you may need to run this once manually:

```bash
sudo ./install.sh
```

## ⚙️ Configuration

Edit the configuration file at `~/.config/rog-ally-suite/config.conf`:

```bash
# Battery charge limit (percentage, 1-100)
BATTERY_LIMIT=80

# Enable automatic power profile management
AUTO_POWER_PROFILES=true

# Log retention (days)
LOG_RETENTION_DAYS=30

# G14 repository URL
G14_REPO_URL=https://arch.asus-linux.org

# Required packages
REQUIRED_PACKAGES=(asusctl power-profiles-daemon)
```

## 🔧 Usage

### Automatic Operation

The suite runs automatically:

-   **On boot**: Via systemd user service
-   **On login**: Via autostart entry (fallback)

### Manual Operation

Run restoration manually:

```bash
~/.local/share/rog-ally-suite/scripts/system-restore.sh
```

Check current battery limit:

```bash
asusctl -c
```

Set battery limit manually:

```bash
sudo asusctl -c 80
```

## 📋 Directory Structure

```
~/.local/share/rog-ally-suite/
├── scripts/
│   ├── system-restore.sh      # Main restoration script
│   └── install.sh             # Installer script
└── logs/                      # Restoration logs

~/.config/rog-ally-suite/
└── config.conf                # User configuration

~/.config/systemd/user/
└── rog-ally-restore.service   # Systemd service

~/.config/autostart/
└── rog-ally-suite.desktop     # Autostart entry

/etc/sudoers.d/
└── rog-ally-suite             # Sudo permissions
```

## 🔍 Troubleshooting

### Check Service Status

```bash
# Check if systemd service is running
systemctl --user status rog-ally-restore.service

# View service logs
journalctl --user -u rog-ally-restore.service -f
```

### Check Installation Logs

```bash
# View latest restoration log
ls -la ~/.local/share/rog-ally-suite/logs/
tail -f ~/.local/share/rog-ally-suite/logs/restore-*.log
```

### Common Issues

#### 1. Sudo Password Prompts

**Symptom**: Scripts ask for password despite sudoers configuration

**Solution**:

```bash
# Check sudoers file exists
sudo cat /etc/sudoers.d/rog-ally-suite

# If missing, reinstall
./install.sh
```

#### 2. Packages Not Installing

**Symptom**: `asusctl` or `power-profiles-daemon` installation fails

**Solution**:

```bash
# Check if system is in read-write mode
findmnt -no OPTIONS /

# If read-only, enable read-write manually
sudo steamos-readonly disable
sudo mount -o remount,rw /

# Then run restoration
~/.local/share/rog-ally-suite/scripts/system-restore.sh
```

#### 3. Service Not Starting

**Symptom**: Systemd service fails to start

**Solution**:

```bash
# Reload systemd configuration
systemctl --user daemon-reload

# Enable and start service manually
systemctl --user enable --now rog-ally-restore.service

# Check for errors
systemctl --user status rog-ally-restore.service
```

#### 4. Battery Limit Not Applied

**Symptom**: Battery charges beyond set limit

**Solution**:

```bash
# Check if asusctl is working
asusctl --help

# Check current limit
asusctl -c

# Set limit manually
sudo asusctl -c 80

# Check if it persists after reboot
```

### Debug Mode

Enable verbose logging by editing the restoration script and adding `set -x` at the top.

## 🗑️ Uninstallation

To completely remove the suite:

```bash
chmod +x uninstall.sh
./uninstall.sh
```

The uninstaller will:

-   Remove all scripts and services
-   Clean up sudoers configuration
-   Optionally remove configuration files
-   Optionally remove installed packages

## 🔒 Security Notes

The sudoers configuration grants specific permissions only:

-   `steamos-readonly` - Enable/disable read-only mode
-   `mount` - Remount filesystems
-   `pacman*` - Package management
-   `systemctl` - Service management
-   `asusctl` - ASUS hardware control

These are the minimum permissions required for functionality.

## 🆚 Comparison with Legacy Scripts

| Feature              | Legacy Scripts  | New Suite              |
| -------------------- | --------------- | ---------------------- |
| Language consistency | Mixed RU/EN     | English only           |
| Error handling       | Basic           | Comprehensive          |
| Logging              | Minimal         | Detailed with rotation |
| Configuration        | Hardcoded       | File-based             |
| Sudo handling        | Crude `-n` flag | Proper sudoers         |
| Modularity           | Monolithic      | Modular design         |
| Persistence          | Manual setup    | Automatic              |
| Uninstaller          | None            | Complete cleanup       |

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

### Development Setup

1. Clone the repository
2. Make changes to scripts
3. Test on SteamOS (or Arch Linux VM)
4. Ensure all scripts pass shellcheck

### Testing

Test the suite after SteamOS updates:

1. Note current functionality
2. Perform SteamOS update
3. Verify automatic restoration
4. Check logs for any issues

## 📄 License

This project is provided as-is for the ROG Ally community. Use at your own risk.

## 🙏 Acknowledgments

-   Original scripts and inspiration from the SteamOS/ROG Ally community
-   [asus-linux.org](https://asus-linux.org) for the excellent hardware support
-   SteamOS developers for the robust base system

---

**Note**: This suite is designed specifically for ASUS ROG Ally devices running SteamOS. It may work on other ASUS gaming handhelds but has not been tested on other devices.
