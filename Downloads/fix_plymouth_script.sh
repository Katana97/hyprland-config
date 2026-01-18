#!/bin/bash

set -e

echo "=== Fixing Plymouth Animation Script ==="
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

THEME_DIR="/usr/share/plymouth/themes/gruvbox-rubiks"

echo "The issue is likely in the Plymouth script syntax."
echo "Creating a corrected script..."
echo ""

# Backup the old script
cp "$THEME_DIR/gruvbox-rubiks.script" "$THEME_DIR/gruvbox-rubiks.script.backup"

# Create a new, working script with proper Plymouth syntax
cat > "$THEME_DIR/gruvbox-rubiks.script" << 'SCRIPTEOF'
# Gruvbox Rubiks Cube Plymouth Theme Script

# Background color - Gruvbox dark
Window.SetBackgroundTopColor(0.156, 0.156, 0.156);
Window.SetBackgroundBottomColor(0.156, 0.156, 0.156);

# Animation setup
global.frame_count = 36;
global.current_frame = 0;
global.frame_images = [];

# Load all frames
for (i = 0; i < global.frame_count; i++)
{
    if (i < 10)
        filename = "frame_00" + i + ".png";
    else if (i < 100)
        filename = "frame_0" + i + ".png";
    else
        filename = "frame_" + i + ".png";
    
    global.frame_images[i] = Image(filename);
}

# Create and position the sprite
global.sprite = Sprite();
global.sprite.SetImage(global.frame_images[0]);

# Center the animation
global.sprite.SetX(Window.GetX() + Window.GetWidth()  / 2 - global.frame_images[0].GetWidth()  / 2);
global.sprite.SetY(Window.GetY() + Window.GetHeight() / 2 - global.frame_images[0].GetHeight() / 2);
global.sprite.SetZ(10);
global.sprite.SetOpacity(1);

# Animation refresh
global.progress = 0;

fun refresh_callback ()
{
    # Update animation frame (change every 2 ticks for ~30fps)
    global.progress++;
    if (global.progress % 2 == 0)
    {
        global.current_frame++;
        if (global.current_frame >= global.frame_count)
            global.current_frame = 0;
        
        global.sprite.SetImage(global.frame_images[global.current_frame]);
    }
}

Plymouth.SetRefreshFunction(refresh_callback);

# Boot progress (optional)
fun progress_callback (duration, progress)
{
    # You can add a progress bar here if desired
}

Plymouth.SetBootProgressFunction(progress_callback);

# Display messages
global.message_sprite = Sprite();

fun message_callback (text)
{
    if (text == "")
    {
        global.message_sprite.SetImage(NULL);
        return;
    }
    
    image = Image.Text(text, 0.867, 0.627, 0.133);  # Gruvbox yellow
    global.message_sprite.SetImage(image);
    global.message_sprite.SetX(Window.GetX() + Window.GetWidth()  / 2 - image.GetWidth()  / 2);
    global.message_sprite.SetY(Window.GetY() + Window.GetHeight() * 0.9);
    global.message_sprite.SetZ(10000);
}

Plymouth.SetMessageFunction(message_callback);

# Display password prompt
fun display_password_callback (prompt, bullets)
{
    if (prompt == "")
    {
        global.message_sprite.SetImage(NULL);
        return;
    }
    
    prompt_text = Image.Text(prompt, 0.867, 0.627, 0.133);
    bullets_text = Image.Text(bullets, 1.0, 1.0, 1.0);
    
    combined_image = prompt_text;
    
    global.message_sprite.SetImage(combined_image);
    global.message_sprite.SetX(Window.GetX() + Window.GetWidth() / 2 - combined_image.GetWidth() / 2);
    global.message_sprite.SetY(Window.GetY() + Window.GetHeight() * 0.9);
    global.message_sprite.SetZ(10000);
}

Plymouth.SetDisplayPasswordFunction(display_password_callback);

# Quit callback
fun quit_callback ()
{
    global.sprite.SetOpacity(0);
}

Plymouth.SetQuitFunction(quit_callback);
SCRIPTEOF

echo -e "${GREEN}✓${NC} Created new Plymouth script"
echo ""

# Set proper permissions
chmod 644 "$THEME_DIR/gruvbox-rubiks.script"

echo "Rebuilding initramfs with new script..."
mkinitcpio -P

echo ""
echo -e "${GREEN}=== Fix Complete! ===${NC}"
echo ""
echo "Changes made:"
echo "  - Replaced Plymouth script with syntax-corrected version"
echo "  - Old script backed up to: gruvbox-rubiks.script.backup"
echo "  - Rebuilt initramfs"
echo ""
echo "Key fixes in the new script:"
echo "  - Proper global variable usage"
echo "  - Corrected filename generation for frames"
echo "  - Fixed sprite positioning methods (SetX/SetY instead of SetPosition)"
echo "  - Proper refresh callback structure"
echo "  - Added password prompt support"
echo ""
echo "Reboot to see the animation!"
echo ""
