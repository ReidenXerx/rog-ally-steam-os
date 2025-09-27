# Fresh SteamOS Installation Guide

## 🆕 **For Brand New ROG Ally / SteamOS Users**

This guide is for users who just got their ROG Ally or performed a fresh SteamOS installation and want to set up ASUS hardware controls for the first time.

## 📋 **What You Need to Know**

Fresh SteamOS comes with:
- ❌ No ASUS hardware controls (`asusctl`)
- ❌ No battery charge limiting
- ❌ No power profile management
- ❌ Read-only filesystem (immutable)
- ❌ Limited sudo access

After this installation:
- ✅ Full ASUS hardware control
- ✅ Battery charge limiting (default 80%)
- ✅ Power profile management
- ✅ Automatic restoration after SteamOS updates
- ✅ Persistent configuration

## 🚀 **Step-by-Step Installation**

### Step 1: Initial Setup

First, you need to set up basic access to your system:

#### Enable Developer Mode (Required)
1. Go to **Steam** → **Settings** → **System** → **Developer**
2. Enable **"Enable Developer Mode"**
3. Set a **sudo password** for the deck user when prompted
4. Reboot your system

> **Why?** SteamOS is locked down by default. Developer mode gives you access to install software.

#### Access Desktop Mode
1. Hold **Power Button** → **Switch to Desktop**
2. Open **Konsole** (terminal)

### Step 2: Download ROG Ally Suite

```bash
# Download the suite (choose one method):

# Method 1: Using git (if available)
git clone https://github.com/yourusername/rog-ally-steam-os.git
cd rog-ally-steam-os

# Method 2: Download ZIP and extract
# Download from GitHub, extract to ~/rog-ally-steam-os
cd ~/rog-ally-steam-os
```

### Step 3: First-Time System Check

Run our compatibility checker to see what needs to be set up:

```bash
chmod +x verify-steamos-compatibility.sh
./verify-steamos-compatibility.sh
```

**Expected results for fresh system:**
- ✅ SteamOS detected
- ✅ Deck user environment
- ❌ No ASUS packages installed
- ❌ G14 repository not configured
- ⚠️ Sudo may require password

### Step 4: Run the Installer

```bash
# Make installer executable
chmod +x install.sh

# Run the installer
./install.sh
```

**What happens during installation:**
1. **Password prompt**: You'll be asked for your sudo password (the one you set in Developer Mode)
2. **Directory setup**: Creates all necessary directories
3. **Sudoers configuration**: Sets up passwordless sudo for ASUS operations
4. **Service installation**: Creates automatic restoration service
5. **Configuration**: Generates default settings

### Step 5: First-Time Package Installation

The installer only sets up the framework. Now install the actual ASUS packages:

```bash
# Run the system restoration (this installs asusctl)
~/.local/share/rog-ally-suite/scripts/system-restore.sh
```

**What happens during first restoration:**
1. **Filesystem unlock**: Switches to read-write mode
2. **Repository setup**: Adds G14 repository for ASUS packages
3. **Package installation**: Installs `asusctl` and `power-profiles-daemon`
4. **Service activation**: Starts power management services
5. **Battery limit**: Sets charge limit to 80%

### Step 6: Verify Everything Works

Check that everything is installed and working:

```bash
# Check asusctl is installed and working
asusctl --version
asusctl -c  # Should show battery limit

# Check services are running
systemctl status power-profiles-daemon.service
systemctl --user status rog-ally-restore.service

# Check battery limit is applied
asusctl -c  # Should show "Charge limit: 80"
```

### Step 7: Test Automatic Restoration

The most important test - does it survive reboots?

```bash
# Reboot your system
sudo reboot
```

After reboot:
1. **Switch back to Desktop Mode**
2. **Open terminal**
3. **Check if everything is still working:**
   ```bash
   asusctl -c  # Should still show battery limit
   ```

If it works, congratulations! 🎉 Your ROG Ally now has persistent ASUS controls!

## ⚙️ **Customization for Fresh Users**

### Change Battery Limit

Edit the configuration file:
```bash
nano ~/.config/rog-ally-suite/config.conf
```

Change the battery limit (example for 70%):
```bash
BATTERY_LIMIT=70
```

Apply the new setting:
```bash
~/.local/share/rog-ally-suite/scripts/system-restore.sh
```

### Available Battery Limits
- **60%**: Maximum battery life preservation
- **70%**: Good balance for daily use
- **80%**: Default - recommended for most users
- **90%**: For users who need more capacity
- **100%**: Disable charge limiting (not recommended)

## 🔧 **Troubleshooting Fresh Installs**

### "sudo: a password is required"

**Problem**: You haven't set up sudo access yet.

**Solution**:
1. Go to Steam Settings → System → Developer
2. Enable Developer Mode
3. Set a sudo password when prompted
4. Reboot and try again

### "steamos-readonly: command not found"

**Problem**: You're not running on SteamOS.

**Solution**: This suite is designed specifically for SteamOS. It won't work on regular Linux distributions.

### "Failed to enable read-write mode"

**Problem**: System is stuck in read-only mode.

**Solution**:
```bash
# Try manual unlock
sudo steamos-readonly disable
sudo mount -o remount,rw /

# Then run installer again
./install.sh
```

### "Package installation failed"

**Problem**: Network issues or repository problems.

**Solution**:
```bash
# Check internet connection
ping google.com

# Try manual package database refresh
sudo pacman -Sy

# Run restoration again
~/.local/share/rog-ally-suite/scripts/system-restore.sh
```

### "Service won't start"

**Problem**: Systemd user service issues.

**Solution**:
```bash
# Reload systemd configuration
systemctl --user daemon-reload

# Enable and start service manually
systemctl --user enable --now rog-ally-restore.service

# Check status
systemctl --user status rog-ally-restore.service
```

## 📱 **Returning to Gaming Mode**

After installation, you can return to Gaming Mode:

1. **Power Button** → **Return to Gaming Mode**
2. Your ASUS controls will work automatically
3. Battery will charge only to your set limit
4. Everything persists across reboots and updates

## 🎯 **What Fresh Users Get**

After successful installation:

### Hardware Control
- ✅ Battery charge limiting (protects battery health)
- ✅ Power profile management (performance/battery modes)
- ✅ Full ASUS hardware integration

### Automatic Operation
- ✅ Starts automatically on boot
- ✅ Survives SteamOS updates
- ✅ No manual intervention needed
- ✅ Works in both Desktop and Gaming modes

### Monitoring and Logs
- ✅ Installation logs in `~/.local/share/rog-ally-suite/logs/`
- ✅ Service logs via `journalctl --user -u rog-ally-restore.service`
- ✅ Configuration in `~/.config/rog-ally-suite/config.conf`

## 🆘 **Getting Help**

If you run into issues:

1. **Check the logs**:
   ```bash
   ls -la ~/.local/share/rog-ally-suite/logs/
   cat ~/.local/share/rog-ally-suite/logs/install.log
   ```

2. **Run the compatibility check**:
   ```bash
   ./verify-steamos-compatibility.sh
   ```

3. **Try manual restoration**:
   ```bash
   ~/.local/share/rog-ally-suite/scripts/system-restore.sh
   ```

4. **Check system status**:
   ```bash
   ./gather-system-info.sh
   ```

## 🎉 **Welcome to the ROG Ally Community!**

You now have a professional-grade ASUS hardware control system that will keep your ROG Ally running optimally while preserving battery health. Enjoy your gaming! 🎮

---

**Note**: This guide assumes you're using a genuine ASUS ROG Ally device with SteamOS. The suite is optimized for this specific hardware and software combination.
