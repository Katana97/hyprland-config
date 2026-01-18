#!/bin/bash

echo "=== Plymouth Boot Animation Diagnostics ==="
echo ""

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m'

# Check current theme
echo -e "${BLUE}[1] Current Plymouth Theme:${NC}"
plymouth-set-default-theme
echo ""

# Check if theme files exist
echo -e "${BLUE}[2] Theme Files Check:${NC}"
THEME_DIR="/usr/share/plymouth/themes/gruvbox-rubiks"
if [ -d "$THEME_DIR" ]; then
    echo -e "${GREEN}✓${NC} Theme directory exists: $THEME_DIR"
    echo "Files in theme directory:"
    ls -lh "$THEME_DIR" | head -20
    echo ""
    echo "Total PNG frames: $(ls -1 $THEME_DIR/frame_*.png 2>/dev/null | wc -l)"
else
    echo -e "${RED}✗${NC} Theme directory not found!"
fi
echo ""

# Check theme configuration files
echo -e "${BLUE}[3] Theme Configuration:${NC}"
if [ -f "$THEME_DIR/gruvbox-rubiks.plymouth" ]; then
    echo -e "${GREEN}✓${NC} Plymouth config exists"
    cat "$THEME_DIR/gruvbox-rubiks.plymouth"
else
    echo -e "${RED}✗${NC} Plymouth config missing!"
fi
echo ""

if [ -f "$THEME_DIR/gruvbox-rubiks.script" ]; then
    echo -e "${GREEN}✓${NC} Script file exists"
    echo "First 30 lines of script:"
    head -30 "$THEME_DIR/gruvbox-rubiks.script"
else
    echo -e "${RED}✗${NC} Script file missing!"
fi
echo ""

# Check kernel parameters
echo -e "${BLUE}[4] Kernel Boot Parameters:${NC}"
cat /proc/cmdline
echo ""
if grep -q "quiet splash" /proc/cmdline; then
    echo -e "${GREEN}✓${NC} 'quiet splash' found in kernel parameters"
else
    echo -e "${YELLOW}⚠${NC} 'quiet splash' NOT found in kernel parameters"
fi
echo ""

# Check mkinitcpio configuration
echo -e "${BLUE}[5] Mkinitcpio Configuration:${NC}"
if grep -q "plymouth" /etc/mkinitcpio.conf; then
    echo -e "${GREEN}✓${NC} Plymouth hook found in mkinitcpio.conf"
    echo "HOOKS line:"
    grep "^HOOKS=" /etc/mkinitcpio.conf
else
    echo -e "${RED}✗${NC} Plymouth hook NOT found in mkinitcpio.conf"
fi
echo ""

# Check GRUB configuration
echo -e "${BLUE}[6] GRUB Configuration:${NC}"
if [ -f /etc/default/grub ]; then
    echo "GRUB_CMDLINE_LINUX_DEFAULT:"
    grep "^GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub
    echo ""
    if grep -q "quiet splash" /etc/default/grub; then
        echo -e "${GREEN}✓${NC} 'quiet splash' in GRUB config"
    else
        echo -e "${YELLOW}⚠${NC} 'quiet splash' NOT in GRUB config"
    fi
fi
echo ""

# Check Plymouth logs
echo -e "${BLUE}[7] Recent Plymouth/Boot Logs:${NC}"
if command -v journalctl &>/dev/null; then
    echo "Last boot Plymouth messages:"
    journalctl -b -1 | grep -i plymouth | tail -20 || echo "No Plymouth messages found"
    echo ""
    echo "Current boot Plymouth messages:"
    journalctl -b 0 | grep -i plymouth | tail -20 || echo "No Plymouth messages found"
fi
echo ""

# Check image dimensions
echo -e "${BLUE}[8] Frame Image Check:${NC}"
if [ -f "$THEME_DIR/frame_000.png" ]; then
    if command -v identify &>/dev/null; then
        DIMS=$(identify -format "%wx%h" "$THEME_DIR/frame_000.png")
        echo "Frame dimensions: $DIMS"
        
        # Get screen resolution
        if command -v xrandr &>/dev/null && [ -n "$DISPLAY" ]; then
            echo "Current display resolution:"
            xrandr | grep "primary\|connected" | head -3
        fi
    fi
else
    echo -e "${RED}✗${NC} First frame (frame_000.png) not found"
fi
echo ""

# Check for errors in script
echo -e "${BLUE}[9] Script Syntax Check:${NC}"
if [ -f "$THEME_DIR/gruvbox-rubiks.script" ]; then
    # Check for common issues
    if grep -q "NUM_FRAMES_PLACEHOLDER" "$THEME_DIR/gruvbox-rubiks.script"; then
        echo -e "${RED}✗${NC} Frame count placeholder not replaced!"
    else
        echo -e "${GREEN}✓${NC} Frame count appears to be set"
        grep "frame_count =" "$THEME_DIR/gruvbox-rubiks.script"
    fi
fi
echo ""

# Test Plymouth functionality
echo -e "${BLUE}[10] Plymouth Functionality Test:${NC}"
echo "Testing if Plymouth can be started..."
if sudo plymouthd --help &>/dev/null; then
    echo -e "${GREEN}✓${NC} Plymouth daemon is accessible"
else
    echo -e "${RED}✗${NC} Plymouth daemon may have issues"
fi
echo ""

echo "=== Diagnostics Complete ==="
echo ""
echo -e "${YELLOW}Recommendations:${NC}"
echo "1. If 'quiet splash' is missing from kernel params, GRUB config needs updating"
echo "2. If Plymouth hook is missing from mkinitcpio, it needs to be added"
echo "3. If frame count placeholder exists, the script had an issue"
echo "4. Check journalctl output above for specific Plymouth errors"
echo ""
