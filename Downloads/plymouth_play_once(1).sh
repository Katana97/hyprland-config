#!/bin/bash

set -e

echo "=== Plymouth Animation: Play Once and Hold ==="
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

echo "Modifying animation to play once and hold on final frame..."
echo ""

# Backup current script
cp "$THEME_DIR/gruvbox-rubiks.script" "$THEME_DIR/gruvbox-rubiks.script.looping_backup"

# Create new script that plays once
cat > "$THEME_DIR/gruvbox-rubiks.script" << 'SCRIPTEOF'
# Gruvbox Rubiks Cube Plymouth Theme Script

# Background color - Gruvbox dark
Window.SetBackgroundTopColor(0.156, 0.156, 0.156);
Window.SetBackgroundBottomColor(0.156, 0.156, 0.156);

# Animation setup
global.frame_count = 36;
global.current_frame = 0;
global.frame_images = [];
global.animation_complete = 0;  # Flag to track if animation has finished

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

# Animation refresh - play once then hold
global.progress = 0;
global.frame_delay = 4;  # ~15fps for smooth animation

fun refresh_callback ()
{
    # Only animate if we haven't finished
    if (global.animation_complete == 0)
    {
        global.progress++;
        
        if (global.progress % global.frame_delay == 0)
        {
            global.current_frame++;
            
            # Check if we've reached the end
            if (global.current_frame >= global.frame_count)
            {
                # Animation complete - stay on last frame
                global.current_frame = global.frame_count - 1;
                global.animation_complete = 1;
            }
            
            global.sprite.SetImage(global.frame_images[global.current_frame]);
        }
    }
    # If animation is complete, do nothing (stays on last frame)
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

echo -e "${GREEN}✓${NC} Modified script to play once and hold on last frame"
echo ""

# Set proper permissions
chmod 644 "$THEME_DIR/gruvbox-rubiks.script"

echo "Rebuilding initramfs..."
mkinitcpio -P

echo ""
echo -e "${GREEN}=== Modification Complete! ===${NC}"
echo ""
echo "Animation behavior:"
echo "  ✓ Plays through all 36 frames once (~2.4 seconds at 15fps)"
echo "  ✓ Holds on the final frame (completed cube) until login appears"
echo "  ✓ Works for both boot and shutdown (each gets one playthrough)"
echo ""
echo "The Rubik's Cube will solve itself once, then stay solved!"
echo ""
echo "If you want to adjust the speed further:"
echo "  - Slower: Change frame_delay to 5 or 6 in the script"
echo "  - Faster: Change frame_delay to 3 or 2 in the script"
echo "  - Then run: sudo mkinitcpio -P"
echo ""
echo "Reboot to see the single-play animation!"
echo ""
