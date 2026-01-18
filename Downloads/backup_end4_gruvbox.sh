#!/bin/bash

set -e

echo "=== End-4 Gruvbox Configuration Backup & Snapshot ==="
echo ""

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m'

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}"
   exit 1
fi

BACKUP_DIR="/home/david/Backups/end4-gruvbox-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo -e "${BLUE}Creating backup directory: $BACKUP_DIR${NC}"
echo ""

# ============================================================================
# QUICKSHELL CONFIGURATION BACKUP
# ============================================================================
echo -e "${YELLOW}[1/8] Backing up QuickShell configuration...${NC}"

QUICKSHELL_BACKUP="$BACKUP_DIR/quickshell"
mkdir -p "$QUICKSHELL_BACKUP"

# Copy entire quickshell config
echo "  - Copying QuickShell config..."
cp -r /home/david/.config/quickshell "$QUICKSHELL_BACKUP/"

# Count files
QUICKSHELL_FILES=$(find "$QUICKSHELL_BACKUP/quickshell" -type f | wc -l)
echo "  - Backed up $QUICKSHELL_FILES files"

echo -e "${GREEN}  ✓ QuickShell backup complete${NC}"
echo ""

# ============================================================================
# HYPRLAND CONFIGURATION BACKUP
# ============================================================================
echo -e "${YELLOW}[2/8] Backing up Hyprland configuration...${NC}"

HYPRLAND_BACKUP="$BACKUP_DIR/hyprland"
mkdir -p "$HYPRLAND_BACKUP"

echo "  - Copying Hyprland config..."
cp -r /home/david/.config/hypr "$HYPRLAND_BACKUP/" 2>/dev/null || echo "  - No Hyprland config found"

echo -e "${GREEN}  ✓ Hyprland backup complete${NC}"
echo ""

# ============================================================================
# THEME AND APPEARANCE BACKUP
# ============================================================================
echo -e "${YELLOW}[3/8] Backing up themes and appearance...${NC}"

THEME_BACKUP="$BACKUP_DIR/themes"
mkdir -p "$THEME_BACKUP"

# GTK themes
echo "  - Backing up GTK configurations..."
cp -r /home/david/.config/gtk-3.0 "$THEME_BACKUP/" 2>/dev/null || true
cp -r /home/david/.config/gtk-4.0 "$THEME_BACKUP/" 2>/dev/null || true

# Kvantum themes
echo "  - Backing up Kvantum themes..."
cp -r /home/david/.config/Kvantum "$THEME_BACKUP/" 2>/dev/null || true

# Color schemes
echo "  - Backing up color schemes..."
mkdir -p "$THEME_BACKUP/color-schemes"
cp /home/david/.local/share/color-schemes/*.colors "$THEME_BACKUP/color-schemes/" 2>/dev/null || true

# Qt configuration
cp /home/david/.config/qt5ct "$THEME_BACKUP/" -r 2>/dev/null || true
cp /home/david/.config/qt6ct "$THEME_BACKUP/" -r 2>/dev/null || true

# KDE globals (if using)
cp /home/david/.config/kdeglobals "$THEME_BACKUP/" 2>/dev/null || true

echo -e "${GREEN}  ✓ Theme backup complete${NC}"
echo ""

# ============================================================================
# PLYMOUTH BOOT ANIMATION BACKUP
# ============================================================================
echo -e "${YELLOW}[4/8] Backing up Plymouth boot animation...${NC}"

PLYMOUTH_BACKUP="$BACKUP_DIR/plymouth"
mkdir -p "$PLYMOUTH_BACKUP"

# Copy the gruvbox-rubiks theme
if [ -d "/usr/share/plymouth/themes/gruvbox-rubiks" ]; then
    echo "  - Copying Plymouth Gruvbox Rubik's Cube theme..."
    cp -r /usr/share/plymouth/themes/gruvbox-rubiks "$PLYMOUTH_BACKUP/"
    echo "  - Theme files: $(ls -1 $PLYMOUTH_BACKUP/gruvbox-rubiks/*.png 2>/dev/null | wc -l) frames"
else
    echo "  - No Plymouth Gruvbox theme found"
fi

# Save configuration
mkdir -p "$PLYMOUTH_BACKUP/config"
plymouth-set-default-theme > "$PLYMOUTH_BACKUP/config/current-theme.txt" 2>/dev/null || true
cp /etc/default/grub "$PLYMOUTH_BACKUP/config/grub" 2>/dev/null || true
cp /etc/mkinitcpio.conf "$PLYMOUTH_BACKUP/config/mkinitcpio.conf" 2>/dev/null || true

echo -e "${GREEN}  ✓ Plymouth backup complete${NC}"
echo ""

# ============================================================================
# DOLPHIN FILE MANAGER BACKUP
# ============================================================================
echo -e "${YELLOW}[5/8] Backing up Dolphin configuration...${NC}"

DOLPHIN_BACKUP="$BACKUP_DIR/dolphin"
mkdir -p "$DOLPHIN_BACKUP"

echo "  - Copying Dolphin configuration..."
cp /home/david/.config/dolphinrc "$DOLPHIN_BACKUP/" 2>/dev/null || true
cp -r /home/david/.local/share/dolphin "$DOLPHIN_BACKUP/" 2>/dev/null || true

echo -e "${GREEN}  ✓ Dolphin backup complete${NC}"
echo ""

# ============================================================================
# OTHER CONFIGURATION FILES
# ============================================================================
echo -e "${YELLOW}[6/8] Backing up other configurations...${NC}"

OTHER_BACKUP="$BACKUP_DIR/other-configs"
mkdir -p "$OTHER_BACKUP"

# Waybar (if used)
cp -r /home/david/.config/waybar "$OTHER_BACKUP/" 2>/dev/null || true

# Kitty/Alacritty terminal configs
cp -r /home/david/.config/kitty "$OTHER_BACKUP/" 2>/dev/null || true
cp -r /home/david/.config/alacritty "$OTHER_BACKUP/" 2>/dev/null || true

# Rofi/Wofi
cp -r /home/david/.config/rofi "$OTHER_BACKUP/" 2>/dev/null || true
cp -r /home/david/.config/wofi "$OTHER_BACKUP/" 2>/dev/null || true

# Fonts
mkdir -p "$OTHER_BACKUP/fonts"
cp -r /home/david/.local/share/fonts "$OTHER_BACKUP/" 2>/dev/null || true

# Cursors
mkdir -p "$OTHER_BACKUP/icons"
cp -r /home/david/.local/share/icons "$OTHER_BACKUP/" 2>/dev/null || true
cp -r /home/david/.icons "$OTHER_BACKUP/" 2>/dev/null || true

echo -e "${GREEN}  ✓ Other configs backup complete${NC}"
echo ""

# ============================================================================
# PACKAGE LIST
# ============================================================================
echo -e "${YELLOW}[7/8] Recording installed packages...${NC}"

PACKAGE_BACKUP="$BACKUP_DIR/packages"
mkdir -p "$PACKAGE_BACKUP"

echo "  - Saving package list..."
pacman -Qe > "$PACKAGE_BACKUP/explicitly-installed.txt"
pacman -Qq > "$PACKAGE_BACKUP/all-packages.txt"

# Save AUR packages separately
pacman -Qm > "$PACKAGE_BACKUP/aur-packages.txt" || true

# Save specific theme-related packages
pacman -Q | grep -E "gtk|qt|kvantum|plymouth|gruvbox|hypr|quickshell" > "$PACKAGE_BACKUP/theme-packages.txt" || true

echo -e "${GREEN}  ✓ Package list saved${NC}"
echo ""

# ============================================================================
# CREATE BTRFS SNAPSHOT
# ============================================================================
echo -e "${YELLOW}[8/8] Creating Btrfs snapshot...${NC}"

SNAPSHOT_DESC="End-4 Gruvbox complete config - QuickShell media/swap fix - $(date +%Y-%m-%d)"

if command -v snapper &>/dev/null; then
    echo "  - Creating snapshot with Snapper..."
    SNAPSHOT_NUM=$(snapper -c root create --description "$SNAPSHOT_DESC" --cleanup-algorithm number --print-number)
    echo "  - Snapshot #$SNAPSHOT_NUM created"
    echo -e "${GREEN}  ✓ Btrfs snapshot created${NC}"
else
    echo -e "${YELLOW}  ⚠ Snapper not found, skipping automatic snapshot${NC}"
    echo "  - You can manually create a snapshot with:"
    echo "    sudo snapper -c root create --description \"$SNAPSHOT_DESC\""
fi

echo ""

# ============================================================================
# CREATE DOCUMENTATION
# ============================================================================
echo "Creating documentation..."

cat > "$BACKUP_DIR/README.md" << 'READMEEOF'
# End-4 Gruvbox Configuration Backup

## Overview
This backup contains your complete End-4 desktop environment with Gruvbox theming.

## Contents

### QuickShell Configuration (`quickshell/`)
- Complete QuickShell II (Illogical Impulse) configuration
- Custom bar with media player and resource monitors
- Fixed issues:
  - Media box width constraint (max 200px)
  - Swap icon always visible
  - Short text proper padding (8px left)
  - Smooth scrolling animation with pauses

### Hyprland Configuration (`hyprland/`)
- Hyprland window manager configuration
- Keybindings and workspace settings
- Display and input configuration

### Themes (`themes/`)
- GTK 3/4 Gruvbox themes
- Kvantum Gruvbox theme configuration
- KDE color schemes
- Qt5/Qt6 theme settings

### Plymouth Boot Animation (`plymouth/`)
- Gruvbox Rubik's Cube boot animation (36 frames)
- Animation plays once and holds on final frame
- Configuration files (GRUB, mkinitcpio)

### Dolphin File Manager (`dolphin/`)
- Dolphin configuration with Gruvbox integration
- Custom view settings

### Other Configs (`other-configs/`)
- Terminal emulator configs
- Application launchers
- Fonts and icons
- Additional theming files

### Package Lists (`packages/`)
- All installed packages
- Explicitly installed packages
- AUR packages
- Theme-related packages

## Restoration Instructions

### Quick Restore (Same System)
```bash
# Restore QuickShell
cp -r quickshell/quickshell ~/.config/

# Restore themes
cp -r themes/gtk-3.0 ~/.config/
cp -r themes/gtk-4.0 ~/.config/
cp -r themes/Kvantum ~/.config/
cp -r themes/color-schemes/* ~/.local/share/color-schemes/

# Restore Plymouth (requires sudo)
sudo cp -r plymouth/gruvbox-rubiks /usr/share/plymouth/themes/
sudo plymouth-set-default-theme gruvbox-rubiks
sudo mkinitcpio -P

# Restart QuickShell
pkill quickshell && quickshell &
```

### Full System Restore (Fresh Install)
```bash
# 1. Install base packages from package list
sudo pacman -S --needed - < packages/all-packages.txt

# 2. Install AUR packages (using your preferred AUR helper)
yay -S --needed - < packages/aur-packages.txt

# 3. Restore all configurations
cp -r quickshell/quickshell ~/.config/
cp -r hyprland/hypr ~/.config/
cp -r themes/* ~/.config/
cp -r other-configs/fonts ~/.local/share/
cp -r other-configs/icons ~/.local/share/

# 4. Restore Plymouth
sudo cp -r plymouth/gruvbox-rubiks /usr/share/plymouth/themes/
sudo plymouth-set-default-theme gruvbox-rubiks
sudo mkinitcpio -P
sudo grub-mkconfig -o /boot/grub/grub.cfg

# 5. Reboot
reboot
```

## Key Files Modified

### QuickShell Bar Files
- `quickshell/ii/modules/ii/bar/Media.qml` - Media player component
  - Width constraint: max 200px
  - Text padding: 8px for short text
  - Smooth scrolling with pauses
  
- `quickshell/ii/modules/ii/bar/Resources.qml` - Resource monitors
  - Swap icon always visible (removed media title check)
  - Line 27-29: Added `|| true` to show condition

### Plymouth Configuration
- Theme: gruvbox-rubiks (36 frames, 1920x1080)
- Plays once and holds on final frame
- Gruvbox dark background (#282828)
- Kernel parameters: `quiet splash loglevel=3`

## GitHub Repository
Your Gruvbox setup is also available in your GitHub repository with an automated install script.

## Troubleshooting

### QuickShell not starting
```bash
# Check logs
journalctl --user -u quickshell

# Try running manually
quickshell --help
```

### Themes not applying
```bash
# Reload GTK settings
gsettings set org.gnome.desktop.interface gtk-theme "Gruvbox-Dark"

# Reload Qt settings
kvantummanager
```

### Plymouth not showing
```bash
# Check if theme is set
plymouth-set-default-theme

# Verify kernel parameters
cat /proc/cmdline | grep "quiet splash"

# Check initramfs
lsinitcpio /boot/initramfs-linux.img | grep plymouth
```

## Backup Information
- Created: $(date)
- Location: $(pwd)
- System: CachyOS with Hyprland + QuickShell
- Theme: Gruvbox Dark
- Total Size: $(du -sh . | cut -f1)

## Important Notes
- Always test backups before relying on them
- Keep multiple backup copies
- Regular snapshots are recommended
- Btrfs snapshots can be managed with Snapper

## Contact & Support
For issues or questions about this configuration, refer to your GitHub repository or the End-4 dots project.
READMEEOF

# Create restoration script
cat > "$BACKUP_DIR/RESTORE.sh" << 'RESTORESCRIPT'
#!/bin/bash

echo "=== End-4 Gruvbox Configuration Restoration ==="
echo ""
echo "This will restore your End-4 Gruvbox configuration."
echo ""

read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[1/5] Restoring QuickShell configuration..."
cp -r "$SCRIPT_DIR/quickshell/quickshell" ~/.config/

echo "[2/5] Restoring themes..."
cp -r "$SCRIPT_DIR/themes/gtk-3.0" ~/.config/ 2>/dev/null || true
cp -r "$SCRIPT_DIR/themes/gtk-4.0" ~/.config/ 2>/dev/null || true
cp -r "$SCRIPT_DIR/themes/Kvantum" ~/.config/ 2>/dev/null || true
mkdir -p ~/.local/share/color-schemes
cp "$SCRIPT_DIR/themes/color-schemes"/*.colors ~/.local/share/color-schemes/ 2>/dev/null || true

echo "[3/5] Restoring other configurations..."
cp -r "$SCRIPT_DIR/hyprland/hypr" ~/.config/ 2>/dev/null || true
cp -r "$SCRIPT_DIR/dolphin/dolphinrc" ~/.config/ 2>/dev/null || true

echo "[4/5] Restoring Plymouth (requires sudo)..."
if [ -d "$SCRIPT_DIR/plymouth/gruvbox-rubiks" ]; then
    sudo cp -r "$SCRIPT_DIR/plymouth/gruvbox-rubiks" /usr/share/plymouth/themes/
    sudo plymouth-set-default-theme gruvbox-rubiks
    sudo mkinitcpio -P
fi

echo "[5/5] Restarting QuickShell..."
pkill quickshell
sleep 1
quickshell &

echo ""
echo "Restoration complete!"
echo "- QuickShell configuration restored"
echo "- Themes restored"
echo "- Plymouth boot animation restored"
echo ""
echo "You may need to log out and back in for all changes to take effect."
RESTORESCRIPT

chmod +x "$BACKUP_DIR/RESTORE.sh"

# Create summary file
cat > "$BACKUP_DIR/BACKUP-INFO.txt" << EOF
=============================================================================
END-4 GRUVBOX CONFIGURATION BACKUP SUMMARY
=============================================================================
Created: $(date)
Backup Location: $BACKUP_DIR

CONTENTS:
---------
1. QuickShell Configuration (Complete)
   - Bar components with media player
   - Resource monitors (CPU, RAM, Swap)
   - Custom Gruvbox styling
   - Fixed issues: media box width, swap visibility, text padding

2. Hyprland Window Manager Configuration
   - Workspace setup
   - Keybindings
   - Display settings

3. Themes & Appearance
   - GTK 3/4 Gruvbox themes
   - Kvantum Gruvbox configuration
   - Qt5/Qt6 theming
   - Color schemes
   - Fonts and icons

4. Plymouth Boot Animation
   - Gruvbox Rubik's Cube (36 frames)
   - Plays once and holds on final frame
   - Configuration files included

5. Dolphin File Manager
   - Custom configuration
   - View settings

6. Package Lists
   - All installed packages
   - Explicitly installed packages
   - AUR packages
   - Theme-related packages

RECENT FIXES:
-------------
✓ Media box max width: 200px (prevents overlap)
✓ Swap icon always visible (removed media title check)
✓ Short text padding: 8px left margin
✓ Smooth scrolling with pauses

BTRFS SNAPSHOT:
---------------
$(if command -v snapper &>/dev/null; then echo "Created: #$SNAPSHOT_NUM"; else echo "Not created (Snapper not available)"; fi)
Description: $SNAPSHOT_DESC

QUICK RESTORE:
--------------
cd "$BACKUP_DIR"
./RESTORE.sh

MANUAL RESTORE:
---------------
See README.md for detailed instructions

BACKUP SIZE:
------------
Total: $(du -sh "$BACKUP_DIR" | cut -f1)
- QuickShell: $(du -sh "$BACKUP_DIR/quickshell" 2>/dev/null | cut -f1 || echo "N/A")
- Themes: $(du -sh "$BACKUP_DIR/themes" 2>/dev/null | cut -f1 || echo "N/A")
- Plymouth: $(du -sh "$BACKUP_DIR/plymouth" 2>/dev/null | cut -f1 || echo "N/A")

GITHUB REPOSITORY:
------------------
Your configuration is also backed up in your GitHub repository
with an automated install script.

=============================================================================
EOF

cat "$BACKUP_DIR/BACKUP-INFO.txt"

# Set proper ownership
chown -R david:david "$BACKUP_DIR" 2>/dev/null || chown -R 1000:1000 "$BACKUP_DIR"

echo ""
echo -e "${GREEN}=== Backup Complete! ===${NC}"
echo ""
echo -e "Backup location: ${BLUE}$BACKUP_DIR${NC}"
echo ""
echo "What's been backed up:"
echo "  ✓ Complete QuickShell configuration"
echo "  ✓ Hyprland configuration"
echo "  ✓ All Gruvbox themes (GTK, Qt, Kvantum)"
echo "  ✓ Plymouth boot animation"
echo "  ✓ Dolphin file manager settings"
echo "  ✓ Package lists"
echo "  ✓ Btrfs snapshot (if Snapper available)"
echo "  ✓ Documentation and restoration scripts"
echo ""
echo "To restore on another system:"
echo "  cd $BACKUP_DIR"
echo "  ./RESTORE.sh"
echo ""
echo "Or push to your GitHub repository for permanent backup!"
echo ""
