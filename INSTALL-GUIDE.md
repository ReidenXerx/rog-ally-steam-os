# ROG Ally Suite Installation Guide

## 🎯 **For Your Specific SteamOS Setup**

Based on the system analysis from your ROG Ally running SteamOS 3.7.15, here's the optimized installation process:

## 📋 **Pre-Installation Status**

✅ **Your system has:**

-   SteamOS 3.7.15 (Build 20250903.1) ✓
-   G14 repository already configured ✓
-   steamos-readonly command available ✓
-   Root filesystem in RW mode ✓
-   Proper user environment (deck user) ✓

⚠️ **Issues detected:**

-   Legacy ROG scripts present (need cleanup)
-   G14 database needs refresh
-   No ASUS packages currently installed

## 🚀 **Installation Steps**

### Step 1: Download the Suite

```bash
# If you haven't already, download/extract to:
cd /home/deck/rog-ally-steam-os-main/
```

### Step 2: Clean Up Legacy Scripts

```bash
# Remove your old scripts to prevent conflicts
chmod +x cleanup-legacy.sh
./cleanup-legacy.sh
```

This will remove:

-   `/home/deck/restore_asusctl.sh` (your old script)
-   `/home/deck/rogfix-repair.sh` (your old repair script)
-   `/home/deck/startup-wrapper.sh` (your old wrapper)
-   `/home/deck/.config/autostart/rogfix.desktop` (old autostart)
-   Log files: `rogfix.log`, `fixlog.log`, `startup.log`

### Step 3: Install the New Suite

```bash
# Run the installer
chmod +x install.sh
./install.sh
```

The installer will:

1. Set up proper directory structure in `~/.local/share/rog-ally-suite/`
2. Configure sudoers for passwordless operations
3. Create systemd user service for automatic restoration
4. Generate configuration file
5. Set up autostart fallback

### Step 4: Test the Installation

```bash
# Test manual restoration
~/.local/share/rog-ally-suite/scripts/system-restore.sh
```

This should:

-   Refresh the G14 repository database
-   Install `asusctl` and `power-profiles-daemon`
-   Set battery limit to 80%
-   Enable power-profiles-daemon service

### Step 5: Verify Everything Works

```bash
# Check if asusctl is installed and working
asusctl --version
asusctl -c  # Should show battery limit

# Check if power-profiles-daemon is running
systemctl status power-profiles-daemon.service

# Check systemd user service
systemctl --user status rog-ally-restore.service
```

## ⚙️ **Configuration**

Edit your settings:

```bash
nano ~/.config/rog-ally-suite/config.conf
```

Available options:

-   `BATTERY_LIMIT=80` (change to 60-100%)
-   `AUTO_POWER_PROFILES=true` (enable/disable power management)
-   `LOG_RETENTION_DAYS=30` (how long to keep logs)

## 🔄 **Testing Persistence**

To test that it survives updates:

1. Note current functionality: `asusctl -c`
2. Reboot the system: `sudo reboot`
3. After reboot, check if everything is restored automatically
4. Check logs: `ls ~/.local/share/rog-ally-suite/logs/`

## 🐛 **Troubleshooting Your Specific Setup**

### If G14 Database Issues Persist:

```bash
# Force clear and refresh G14 database
sudo rm -f /usr/lib/holo/pacmandb/sync/g14.db*
sudo pacman -Sy
```

### If steamos-readonly Issues:

```bash
# Check current status
steamos-readonly status

# If needed, disable manually
sudo steamos-readonly disable
sudo mount -o remount,rw /
```

### If Packages Won't Install:

```bash
# Check if system is in RW mode
findmnt -no OPTIONS /

# Should show: rw,relatime,ssd,discard=async,space_cache=v2,subvolid=5,subvol=/
```

## 📊 **Expected Results**

After successful installation:

✅ **Installed packages:**

-   `asusctl` (ASUS hardware control)
-   `power-profiles-daemon` (power management)

✅ **Active services:**

-   `power-profiles-daemon.service` (system)
-   `rog-ally-restore.service` (user)

✅ **Configuration files:**

-   `~/.config/rog-ally-suite/config.conf`
-   `~/.config/systemd/user/rog-ally-restore.service`
-   `~/.config/autostart/rog-ally-suite.desktop`
-   `/etc/sudoers.d/rog-ally-suite`

✅ **Battery limit set:** 80% (or your configured value)

## 🎉 **Success Indicators**

You'll know it's working when:

1. `asusctl -c` shows your battery limit
2. Battery stops charging at the set limit
3. System automatically restores after reboots
4. No password prompts for ASUS operations

## 🆘 **Need Help?**

Check the logs:

```bash
# Installation log
cat ~/.local/share/rog-ally-suite/logs/install.log

# Latest restoration log
ls -la ~/.local/share/rog-ally-suite/logs/restore-*.log
tail ~/.local/share/rog-ally-suite/logs/restore-*.log
```

Your system is perfectly compatible - this should work flawlessly! 🚀
