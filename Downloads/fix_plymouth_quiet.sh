#!/bin/bash

set -e

echo "=== Fixing Plymouth Boot Animation ==="
echo ""

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}"
   exit 1
fi

echo -e "${YELLOW}The issue: Your kernel boot parameters have 'splash' but missing 'quiet'${NC}"
echo "Without 'quiet', kernel messages cover the Plymouth animation."
echo ""

# Backup GRUB config
echo "Creating backup of GRUB config..."
cp /etc/default/grub /etc/default/grub.plymouth_fix_backup

# Check current config
echo "Current GRUB_CMDLINE_LINUX_DEFAULT:"
grep "^GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub
echo ""

# Fix: Add 'quiet' before 'splash'
echo "Adding 'quiet' to kernel parameters..."
sed -i "s/splash/quiet splash/" /etc/default/grub

# Show new config
echo "New GRUB_CMDLINE_LINUX_DEFAULT:"
grep "^GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub
echo ""

# Regenerate GRUB config
echo "Regenerating GRUB configuration..."
grub-mkconfig -o /boot/grub/grub.cfg

echo ""
echo -e "${GREEN}=== Fix Complete! ===${NC}"
echo ""
echo "Changes made:"
echo "  - Added 'quiet' to kernel boot parameters"
echo "  - Backup saved at: /etc/default/grub.plymouth_fix_backup"
echo ""
echo "On your next reboot, you should see the Gruvbox Rubik's Cube animation!"
echo ""
echo "What 'quiet' does:"
echo "  - Suppresses most kernel messages during boot"
echo "  - Allows Plymouth to display the graphical boot screen"
echo "  - Essential for a clean boot animation experience"
echo ""
