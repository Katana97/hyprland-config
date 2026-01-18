#!/bin/bash

set -e

echo "=== Plymouth Boot Animation Cleanup & Setup ==="
echo ""

# Colours for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Colour

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}"
   exit 1
fi

# Step 1: Clean up any existing attempts
echo -e "${YELLOW}[1/6] Cleaning up previous attempts...${NC}"
rm -rf /usr/share/plymouth/themes/gruvbox-rubiks 2>/dev/null || true
rm -rf /usr/share/plymouth/themes/gruvbox 2>/dev/null || true

# Step 2: Ensure Plymouth is installed
echo -e "${YELLOW}[2/6] Checking Plymouth installation...${NC}"
if ! pacman -Q plymouth &>/dev/null; then
    echo "Installing Plymouth..."
    pacman -S --noconfirm plymouth
else
    echo "Plymouth is already installed"
fi

# Step 3: Find the GIF file
echo -e "${YELLOW}[3/6] Locating your Gruvbox Rubik's Cube GIF...${NC}"
GIF_PATH=""
SEARCH_LOCATIONS=(
    "/home/david/Downloads/GruvboxRubiksCube/contents/splash/images/plasma_d.gif"
    "/home/david/Downloads/plasma_d.gif"
    "/home/david/Downloads/gruvbox*.gif"
)

for location in "${SEARCH_LOCATIONS[@]}"; do
    if [ -f "$location" ] || compgen -G "$location" > /dev/null 2>&1; then
        GIF_PATH=$(ls $location 2>/dev/null | head -1)
        break
    fi
done

if [ -z "$GIF_PATH" ]; then
    echo -e "${RED}ERROR: Could not find plasma_d.gif${NC}"
    echo "Please place your GIF file at: /home/david/Downloads/plasma_d.gif"
    exit 1
fi

echo "Found GIF at: $GIF_PATH"

# Step 4: Convert GIF to PNG frames
echo -e "${YELLOW}[4/6] Converting GIF to PNG frames...${NC}"
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Extract frames using ImageMagick
convert "$GIF_PATH" -coalesce frame_%03d.png

# Count frames
FRAME_COUNT=$(ls frame_*.png | wc -l)
echo "Extracted $FRAME_COUNT frames"

# Get image dimensions
DIMENSIONS=$(identify -format "%wx%h" frame_000.png)
echo "Image dimensions: $DIMENSIONS"

# Step 5: Create Plymouth theme
echo -e "${YELLOW}[5/6] Creating Plymouth theme...${NC}"
THEME_DIR="/usr/share/plymouth/themes/gruvbox-rubiks"
mkdir -p "$THEME_DIR"

# Copy frames to theme directory
cp frame_*.png "$THEME_DIR/"

# Create the theme configuration file
cat > "$THEME_DIR/gruvbox-rubiks.plymouth" << 'PLYMOUTHEOF'
[Plymouth Theme]
Name=Gruvbox Rubiks Cube
Description=Animated Gruvbox-themed Rubik's Cube boot splash
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/gruvbox-rubiks
ScriptFile=/usr/share/plymouth/themes/gruvbox-rubiks/gruvbox-rubiks.script
PLYMOUTHEOF

# Create the animation script
cat > "$THEME_DIR/gruvbox-rubiks.script" << 'SCRIPTEOF'
# Gruvbox Rubiks Cube Plymouth Theme Script

# Set up the background (Gruvbox dark background colour)
Window.SetBackgroundTopColor(0.156, 0.156, 0.156);    # #282828
Window.SetBackgroundBottomColor(0.156, 0.156, 0.156); # #282828

# Load all animation frames
frame_count = NUM_FRAMES_PLACEHOLDER;
for (i = 0; i < frame_count; i++) {
    frame_filename = "frame_" + String(i).PadZeros(3) + ".png";
    frames[i] = Image(frame_filename);
}

# Create sprite for animation
animation_sprite = Sprite();
animation_sprite.SetPosition(Window.GetWidth() / 2 - frames[0].GetWidth() / 2,
                             Window.GetHeight() / 2 - frames[0].GetHeight() / 2,
                             10000);

# Animation variables
current_frame = 0;
frame_delay = 0.05; # 50ms between frames for smooth animation
time_since_last_frame = 0;

# Main animation loop
fun refresh_callback() {
    time_since_last_frame += 1;
    
    if (time_since_last_frame >= frame_delay * 50) {
        current_frame = (current_frame + 1) % frame_count;
        animation_sprite.SetImage(frames[current_frame]);
        time_since_last_frame = 0;
    }
}

Plymouth.SetRefreshFunction(refresh_callback);

# Progress bar (optional - Gruvbox colours)
progress_box.image = Image("progress_box.png");
progress_box.sprite = Sprite(progress_box.image);
progress_box.x = Window.GetWidth() / 2 - progress_box.image.GetWidth() / 2;
progress_box.y = Window.GetHeight() * 0.75;
progress_box.sprite.SetPosition(progress_box.x, progress_box.y, 0);

fun progress_callback(duration, progress) {
    if (progress_bar.sprite) progress_bar.sprite.SetOpacity(0);
}

Plymouth.SetBootProgressFunction(progress_callback);

# Message display (for password prompts, etc.)
message_sprite = Sprite();
message_sprite.SetPosition(Window.GetWidth() / 2, Window.GetHeight() * 0.9, 10000);

fun message_callback(text) {
    my_image = Image.Text(text, 0.867, 0.627, 0.133, 1, "Sans 12"); # Gruvbox yellow
    message_sprite.SetImage(my_image);
    message_sprite.SetPosition(Window.GetWidth() / 2 - my_image.GetWidth() / 2,
                               Window.GetHeight() * 0.9,
                               10000);
}

Plymouth.SetMessageFunction(message_callback);
SCRIPTEOF

# Replace the frame count placeholder
sed -i "s/NUM_FRAMES_PLACEHOLDER/$FRAME_COUNT/" "$THEME_DIR/gruvbox-rubiks.script"

# Set correct permissions
chmod 644 "$THEME_DIR"/*.plymouth
chmod 644 "$THEME_DIR"/*.script
chmod 644 "$THEME_DIR"/*.png

echo "Theme created successfully"

# Step 6: Configure system to use the theme
echo -e "${YELLOW}[6/6] Configuring system to use new theme...${NC}"

# Set the default theme
plymouth-set-default-theme -R gruvbox-rubiks

# Update mkinitcpio hooks if needed
if ! grep -q "plymouth" /etc/mkinitcpio.conf; then
    echo "Adding Plymouth to mkinitcpio.conf..."
    # Backup original
    cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.backup
    
    # Add plymouth to HOOKS (after base and udev, before filesystems)
    sed -i 's/\(HOOKS=([^)]*udev[^)]*\))/\1 plymouth)/' /etc/mkinitcpio.conf
fi

# Rebuild initramfs
echo "Rebuilding initramfs..."
mkinitcpio -P

# Update GRUB if using GRUB
if [ -f /boot/grub/grub.cfg ]; then
    echo "Updating GRUB configuration..."
    # Check if quiet splash is already in GRUB_CMDLINE_LINUX_DEFAULT
    if ! grep -q "quiet splash" /etc/default/grub; then
        cp /etc/default/grub /etc/default/grub.backup
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 quiet splash"/' /etc/default/grub
        grub-mkconfig -o /boot/grub/grub.cfg
    fi
fi

# Clean up temp directory
cd /
rm -rf "$TEMP_DIR"

echo ""
echo -e "${GREEN}=== Setup Complete! ===${NC}"
echo ""
echo "Your Gruvbox Rubik's Cube boot animation has been installed."
echo "The animation will appear on your next boot."
echo ""
echo "To test it now without rebooting, run:"
echo "  sudo plymouthd"
echo "  sudo plymouth --show-splash"
echo "  # Wait a few seconds to see the animation"
echo "  sudo plymouth quit"
echo ""
echo "Backups created:"
echo "  - /etc/mkinitcpio.conf.backup"
echo "  - /etc/default/grub.backup (if modified)"
echo ""
