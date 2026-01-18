# System Recovery Cheat Sheet
**CachyOS + Hyprland (end-4 dots) Backup & Recovery Guide**

Date Created: 31 December 2025  
System: XPS 9500 - CachyOS with Btrfs + Snapper

---

## Current Backup Status

✅ **Automatic Snapshots Enabled**
- Snapper creates hourly/daily snapshots automatically
- Old snapshots auto-delete to save space

✅ **Manual Snapshot Created**
- Description: "Fully working system - Mailspring fixed, all configs good"
- Created: 31 December 2025

✅ **Config Backups Created**
- Location: `~/Backups/`
- Hyprland configs: `hypr-config-20251231.tar.gz`
- User configs: `user-configs-20251231.tar.gz`

---

## Recovery Methods

### Method 1: Boot into Snapshot (System Won't Boot)

1. Reboot your system
2. In GRUB menu, select **"Snapshots"**
3. Choose your working snapshot from the list
4. Boot into that snapshot
5. System should boot into the working state

---

### Method 2: Rollback from Running System

If your system boots but something is broken:

```bash
# List all available snapshots
sudo snapper list

# Rollback to a specific snapshot (replace 42 with your snapshot number)
sudo snapper rollback 42

# Reboot to apply the rollback
reboot
```

**Tip:** Look for your snapshot with description "Fully working system - Mailspring fixed, all configs good"

---

### Method 3: Restore Just Your Configs

If only your user configurations are broken (Hyprland, Mailspring, etc.):

```bash
# Navigate to backups directory
cd ~/Backups

# Restore Hyprland configs
tar -xzf hypr-config-20251231.tar.gz -C ~/

# Restore all user configs
tar -xzf user-configs-20251231.tar.gz -C ~/

# Log out and back in to apply changes
```

---

## Creating New Snapshots

### Manual Snapshot (Before Making Changes)

```bash
sudo snapper -c root create --description "Your description here"
```

**Example:**
```bash
sudo snapper -c root create --description "Before installing new GPU drivers"
```

### Backup Your Configs

```bash
# Create backup directory if it doesn't exist
mkdir -p ~/Backups

# Backup Hyprland configs
tar -czf ~/Backups/hypr-config-$(date +%Y%m%d).tar.gz ~/.config/hypr/

# Backup all important user configs
tar -czf ~/Backups/user-configs-$(date +%Y%m%d).tar.gz \
    ~/.config/Mailspring \
    ~/.config/gtk-3.0 \
    ~/.config/gtk-4.0 \
    ~/.local/share/applications
```

---

## Checking Backup Status

### View All Snapshots
```bash
sudo snapper list
```

### Check Automatic Snapshot Timers
```bash
# Timeline timer (creates snapshots)
sudo systemctl status snapper-timeline.timer

# Cleanup timer (removes old snapshots)
sudo systemctl status snapper-cleanup.timer
```

Both should show `Active: active (waiting)`

---

## Important Directories

- **Snapshots:** `/snapshots/` (managed by Snapper)
- **Config Backups:** `~/Backups/`
- **Hyprland Configs:** `~/.config/hypr/`
- **Mailspring Config:** `~/.config/Mailspring/`
- **Custom Desktop Files:** `~/.local/share/applications/`

---

## Emergency Commands

### Force Rebuild GRUB (if snapshots don't appear in GRUB)
```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### List What Changed Between Snapshots
```bash
# Compare snapshot 42 with snapshot 50
sudo snapper status 42..50
```

### Delete Specific Snapshot (to free space)
```bash
# Delete snapshot number 42
sudo snapper delete 42
```

---

## Working System Details (as of 31 Dec 2025)

**Successfully Configured:**
- Mailspring with gnome-keyring integration
- `gnome-keyring-daemon` auto-starts via Hyprland
- Mailspring launches with proper flags: `--password-store="gnome-libsecret" --ozone-platform-hint=x11`
- Hyprland end-4 dots fully configured
- Multi-GPU setup (Intel UHD + GTX 1650 Ti + RTX 4070 Ti eGPU)
- Gruvbox theming applied
- All custom keybindings working

**Key Configuration Files:**
- `~/.config/hypr/custom/execs.conf` - Contains gnome-keyring startup
- `~/.config/hypr/custom/keybinds.conf` - Custom keybindings
- `/usr/share/applications/Mailspring.desktop` - Mailspring launcher

---

## Notes

- Snapper snapshots are bootable - you can select them in GRUB
- Timeline creates automatic snapshots hourly/daily
- Cleanup automatically removes old snapshots based on retention policy
- User config backups (in `~/Backups/`) are separate from Snapper snapshots
- Always create a manual snapshot before major system changes
- Test your backups periodically to ensure they work

---

**Remember:** When in doubt, boot into a snapshot from GRUB. It's the safest recovery method.
