#!/bin/bash

set -e

echo "=== Backup & Snapshot: Plymouth Boot Animation + Dolphin Gruvbox Theming ==="
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

BACKUP_DIR="/home/david/Backups/gruvbox-plymouth-dolphin-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo -e "${BLUE}Creating backup directory: $BACKUP_DIR${NC}"
echo ""

# ============================================================================
# PLYMOUTH BOOT ANIMATION BACKUP
# ============================================================================
echo -e "${YELLOW}[1/6] Backing up Plymouth Boot Animation...${NC}"

PLYMOUTH_BACKUP="$BACKUP_DIR/plymouth"
mkdir -p "$PLYMOUTH_BACKUP"

# Copy the entire theme directory
echo "  - Copying Plymouth theme files..."
cp -r /usr/share/plymouth/themes/gruvbox-rubiks "$PLYMOUTH_BACKUP/"

# Save configuration files
echo "  - Backing up Plymouth configuration..."
mkdir -p "$PLYMOUTH_BACKUP/config"
plymouth-set-default-theme > "$PLYMOUTH_BACKUP/config/current-theme.txt"
cp /etc/mkinitcpio.conf "$PLYMOUTH_BACKUP/config/mkinitcpio.conf"
cp /etc/default/grub "$PLYMOUTH_BACKUP/config/grub"
cat /proc/cmdline > "$PLYMOUTH_BACKUP/config/kernel-cmdline.txt" || true

# Save the original GIF
echo "  - Backing up original GIF source..."
if [ -f "/home/david/Downloads/GruvboxRubiksCube/contents/splash/images/plasma_d.gif" ]; then
    cp "/home/david/Downloads/GruvboxRubiksCube/contents/splash/images/plasma_d.gif" "$PLYMOUTH_BACKUP/original-rubiks-cube.gif"
fi

# Create documentation
cat > "$PLYMOUTH_BACKUP/README.md" << 'PLYMOUTHREADME'
# Plymouth Gruvbox Rubik's Cube Boot Animation

## Installation Summary
This backup contains a working Plymouth boot animation featuring an animated Gruvbox-themed Rubik's Cube.

## Files Included
- `gruvbox-rubiks/` - Complete Plymouth theme directory
- `original-rubiks-cube.gif` - Source GIF file
- `config/` - System configuration files

## Key Configuration
- **Theme**: gruvbox-rubiks
- **Animation**: 36 frames at 1920x1080, plays once then holds on final frame
- **Frame Rate**: ~15fps (frame_delay = 4)
- **Background**: Gruvbox dark (#282828)
- **Kernel Parameters**: quiet splash loglevel=3

## Restoration Instructions

### Quick Restore (if Plymouth is already installed):
```bash
sudo cp -r gruvbox-rubiks /usr/share/plymouth/themes/
sudo plymouth-set-default-theme -R gruvbox-rubiks
```

### Full Restore (from scratch):
```bash
# 1. Install Plymouth
sudo pacman -S plymouth

# 2. Copy theme
sudo cp -r gruvbox-rubiks /usr/share/plymouth/themes/

# 3. Add Plymouth to mkinitcpio hooks
sudo nano /etc/mkinitcpio.conf
# Add 'plymouth' to HOOKS after 'sd-vconsole' and before 'filesystems'

# 4. Set theme
sudo plymouth-set-default-theme -R gruvbox-rubiks

# 5. Update GRUB
sudo nano /etc/default/grub
# Ensure GRUB_CMDLINE_LINUX_DEFAULT contains 'quiet splash'
sudo grub-mkconfig -o /boot/grub/grub.cfg

# 6. Rebuild initramfs
sudo mkinitcpio -P
```

## Customization

### Adjust Animation Speed
Edit `/usr/share/plymouth/themes/gruvbox-rubiks/gruvbox-rubiks.script`:
- Find: `global.frame_delay = 4;`
- Change to:
  - `3` for faster (~20fps)
  - `5` for slower (~12fps)
  - `6` for much slower (~10fps)
- Then run: `sudo mkinitcpio -P`

### Make Animation Loop
Edit the script file:
- Find the section with `global.animation_complete`
- Change the end condition to reset: `global.current_frame = 0;` instead of holding

## Troubleshooting

### Animation doesn't show
1. Check kernel parameters: `cat /proc/cmdline`
   - Must contain 'quiet splash'
2. Check Plymouth is in initramfs: `lsinitcpio /boot/initramfs-linux.img | grep plymouth`
3. Check logs: `journalctl -b | grep plymouth`

### Animation too fast/slow
Adjust `frame_delay` as described above.

### Resolution issues
Frames are 1920x1080. For different resolutions, regenerate frames from the original GIF.

## Credits
- Original GIF: Gruvbox Rubik's Cube animation
- Theme: Created for CachyOS with Hyprland
- Color Scheme: Gruvbox Dark
PLYMOUTHREADME

echo -e "${GREEN}  ✓ Plymouth backup complete${NC}"
echo ""

# ============================================================================
# DOLPHIN GRUVBOX THEMING BACKUP
# ============================================================================
echo -e "${YELLOW}[2/6] Backing up Dolphin Gruvbox Theming...${NC}"

DOLPHIN_BACKUP="$BACKUP_DIR/dolphin"
mkdir -p "$DOLPHIN_BACKUP"

# Dolphin configuration files
echo "  - Backing up Dolphin configuration..."
if [ -d "/home/david/.config/dolphinrc" ] || [ -f "/home/david/.config/dolphinrc" ]; then
    cp -r /home/david/.config/dolphin* "$DOLPHIN_BACKUP/" 2>/dev/null || true
fi
cp /home/david/.config/kdeglobals "$DOLPHIN_BACKUP/" 2>/dev/null || true

# Color scheme files
echo "  - Backing up color schemes..."
mkdir -p "$DOLPHIN_BACKUP/color-schemes"
cp /home/david/.local/share/color-schemes/*.colors "$DOLPHIN_BACKUP/color-schemes/" 2>/dev/null || true

# GTK/Qt theme configurations
echo "  - Backing up theme configurations..."
mkdir -p "$DOLPHIN_BACKUP/themes"
cp /home/david/.config/gtk-3.0/settings.ini "$DOLPHIN_BACKUP/themes/" 2>/dev/null || true
cp /home/david/.config/gtk-4.0/settings.ini "$DOLPHIN_BACKUP/themes/" 2>/dev/null || true
cp /home/david/.config/Kvantum/kvantum.kvconfig "$DOLPHIN_BACKUP/themes/" 2>/dev/null || true
cp -r /home/david/.config/Kvantum/Gruvbox* "$DOLPHIN_BACKUP/themes/" 2>/dev/null || true

# Create Dolphin documentation
cat > "$DOLPHIN_BACKUP/README.md" << 'DOLPHINREADME'
# Dolphin File Manager - Gruvbox Theming

## Configuration Summary
This backup contains Dolphin configuration with Gruvbox color scheme integration.

## Files Included
- `dolphinrc` - Main Dolphin configuration
- `kdeglobals` - KDE global settings (color scheme)
- `color-schemes/` - Custom color scheme files
- `themes/` - GTK/Qt/Kvantum theme configurations

## Key Settings
- **Color Scheme**: Gruvbox Dark
- **Icon Theme**: Gruvbox-compatible icons
- **Widget Style**: Kvantum with Gruvbox theme

## Restoration Instructions

### Restore Dolphin Configuration:
```bash
# Copy configuration files
cp dolphinrc ~/.config/
cp kdeglobals ~/.config/

# Copy color schemes
mkdir -p ~/.local/share/color-schemes
cp color-schemes/*.colors ~/.local/share/color-schemes/

# Copy theme files
cp themes/settings.ini ~/.config/gtk-3.0/ 2>/dev/null || true
cp themes/settings.ini ~/.config/gtk-4.0/ 2>/dev/null || true
cp -r themes/Gruvbox* ~/.config/Kvantum/ 2>/dev/null || true
cp themes/kvantum.kvconfig ~/.config/Kvantum/ 2>/dev/null || true

# Restart Dolphin
killall dolphin
dolphin &
```

## Notes
- Ensure Kvantum and required icon themes are installed
- Color scheme should be consistent with your system-wide Gruvbox setup
- Some settings may require logging out and back in to take full effect
DOLPHINREADME

echo -e "${GREEN}  ✓ Dolphin theming backup complete${NC}"
echo ""

# ============================================================================
# SYSTEM CONFIGURATION BACKUP
# ============================================================================
echo -e "${YELLOW}[3/6] Backing up related system configurations...${NC}"

SYSTEM_BACKUP="$BACKUP_DIR/system"
mkdir -p "$SYSTEM_BACKUP"

echo "  - Backing up initramfs configuration..."
cp /etc/mkinitcpio.conf "$SYSTEM_BACKUP/"
ls /etc/mkinitcpio.d/*.preset > "$SYSTEM_BACKUP/installed-kernels.txt"

echo "  - Backing up bootloader configuration..."
cp /etc/default/grub "$SYSTEM_BACKUP/"
cp /boot/grub/grub.cfg "$SYSTEM_BACKUP/" 2>/dev/null || true

echo "  - Recording package information..."
pacman -Q | grep -E "plymouth|kvantum|dolphin|qt|gtk" > "$SYSTEM_BACKUP/relevant-packages.txt"

echo -e "${GREEN}  ✓ System configuration backup complete${NC}"
echo ""

# ============================================================================
# CREATE RESTORATION SCRIPT
# ============================================================================
echo -e "${YELLOW}[4/6] Creating restoration script...${NC}"

cat > "$BACKUP_DIR/RESTORE.sh" << 'RESTORESCRIPT'
#!/bin/bash

echo "=== Gruvbox Plymouth + Dolphin Restoration Script ==="
echo ""
echo "This will restore:"
echo "  1. Plymouth Gruvbox Rubik's Cube boot animation"
echo "  2. Dolphin file manager Gruvbox theming"
echo ""

read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Restore Plymouth
echo "[1/3] Restoring Plymouth theme..."
sudo cp -r "$SCRIPT_DIR/plymouth/gruvbox-rubiks" /usr/share/plymouth/themes/
sudo plymouth-set-default-theme gruvbox-rubiks
sudo mkinitcpio -P

# Restore Dolphin
echo "[2/3] Restoring Dolphin configuration..."
cp "$SCRIPT_DIR/dolphin/dolphinrc" ~/.config/ 2>/dev/null || true
cp "$SCRIPT_DIR/dolphin/kdeglobals" ~/.config/ 2>/dev/null || true
mkdir -p ~/.local/share/color-schemes
cp "$SCRIPT_DIR/dolphin/color-schemes"/*.colors ~/.local/share/color-schemes/ 2>/dev/null || true

# Copy theme files
mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0 ~/.config/Kvantum
cp "$SCRIPT_DIR/dolphin/themes/settings.ini" ~/.config/gtk-3.0/ 2>/dev/null || true
cp "$SCRIPT_DIR/dolphin/themes/settings.ini" ~/.config/gtk-4.0/ 2>/dev/null || true
cp -r "$SCRIPT_DIR/dolphin/themes/Gruvbox"* ~/.config/Kvantum/ 2>/dev/null || true

# Completion
echo "[3/3] Complete!"
echo ""
echo "Plymouth theme restored. Reboot to see boot animation."
echo "Dolphin configuration restored. Restart Dolphin or log out/in."
echo ""
RESTORESCRIPT

chmod +x "$BACKUP_DIR/RESTORE.sh"

echo -e "${GREEN}  ✓ Restoration script created${NC}"
echo ""

# ============================================================================
# CREATE BTRFS SNAPSHOT
# ============================================================================
echo -e "${YELLOW}[5/6] Creating Btrfs snapshot...${NC}"

SNAPSHOT_NAME="gruvbox-complete-plymouth-dolphin-$(date +%Y-%m-%d)"
SNAPSHOT_DESC="Complete Gruvbox setup: Plymouth boot animation + Dolphin theming - $(date +%Y-%m-%d)"

if command -v snapper &>/dev/null; then
    echo "  - Creating snapshot with Snapper..."
    snapper -c root create --description "$SNAPSHOT_DESC" --cleanup-algorithm number --print-number
    echo -e "${GREEN}  ✓ Btrfs snapshot created${NC}"
else
    echo -e "${YELLOW}  ⚠ Snapper not found, skipping automatic snapshot${NC}"
    echo "  - You can manually create a snapshot with:"
    echo "    sudo snapper -c root create --description \"$SNAPSHOT_DESC\""
fi

echo ""

# ============================================================================
# GENERATE SUMMARY
# ============================================================================
echo -e "${YELLOW}[6/6] Generating backup summary...${NC}"

cat > "$BACKUP_DIR/BACKUP-INFO.txt" << EOF
=============================================================================
GRUVBOX PLYMOUTH + DOLPHIN BACKUP SUMMARY
=============================================================================
Created: $(date)
Backup Location: $BACKUP_DIR

CONTENTS:
---------
1. Plymouth Boot Animation
   - Theme: Gruvbox Rubik's Cube
   - 36 frames at 1920x1080
   - Single play-through, holds on final frame
   - Location: plymouth/gruvbox-rubiks/

2. Dolphin File Manager Theming
   - Gruvbox color scheme integration
   - Kvantum theme configuration
   - Location: dolphin/

3. System Configuration
   - Bootloader settings
   - Initramfs configuration
   - Package list
   - Location: system/

4. Documentation
   - README.md files in each directory
   - Detailed restoration instructions
   - Troubleshooting guides

5. Restoration Script
   - RESTORE.sh - Automated restoration
   - Run from this directory

QUICK RESTORE:
--------------
cd "$BACKUP_DIR"
sudo ./RESTORE.sh

MANUAL RESTORATION:
-------------------
See README.md files in plymouth/ and dolphin/ directories

BTRFS SNAPSHOT:
---------------
$(if command -v snapper &>/dev/null; then echo "Created with Snapper"; else echo "Not created (Snapper not available)"; fi)
Description: $SNAPSHOT_DESC

BACKUP SIZE:
------------
$(du -sh "$BACKUP_DIR" | cut -f1)

=============================================================================
EOF

cat "$BACKUP_DIR/BACKUP-INFO.txt"

# Set proper ownership
chown -R david:david "$BACKUP_DIR"

echo ""
echo -e "${GREEN}=== Backup Complete! ===${NC}"
echo ""
echo -e "Backup location: ${BLUE}$BACKUP_DIR${NC}"
echo ""
echo "What's been backed up:"
echo "  ✓ Plymouth Gruvbox Rubik's Cube boot animation (complete theme + config)"
echo "  ✓ Dolphin Gruvbox theming (config + color schemes + Kvantum)"
echo "  ✓ System configuration (GRUB, mkinitcpio, packages)"
echo "  ✓ Documentation and restoration scripts"
echo "  ✓ Btrfs snapshot (if Snapper available)"
echo ""
echo "To restore on another system or after reinstall:"
echo "  cd $BACKUP_DIR"
echo "  sudo ./RESTORE.sh"
echo ""
