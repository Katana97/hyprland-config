# Complete Guide: Gruvbox Multi-Color Theme for end-4 (Waffle Panels)

## What You Have Now
- **Panel Family:** "ii" (Material You based)
- **Problem:** Material You auto-generates colors from wallpaper, hard to get exact Gruvbox palette
- **Solution:** Switch to "waffle" panel family for manual color control

## What We'll Do
1. Switch from "ii" to "waffle" panels
2. Add official Gruvbox color palette to Looks.qml
3. Apply multi-color Gruvbox across UI elements
4. Keep it reversible with backups

---

## STEP 1: Create Backup (CRITICAL - DON'T SKIP!)

```bash
# Create timestamped backup
BACKUP_DIR="$HOME/.config/quickshell-backup-waffle-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r ~/.config/quickshell "$BACKUP_DIR/"
cp -r ~/.config/hypr "$BACKUP_DIR/"

echo "✅ Backup created at: $BACKUP_DIR"

# Create restore script
cat > "$BACKUP_DIR/RESTORE.sh" << 'EOF'
#!/bin/bash
echo "⚠️  WARNING: This will restore your config to the backup state"
read -p "Continue? (yes/no): " confirm
if [ "$confirm" = "yes" ]; then
    cp -r "$(dirname "$0")/quickshell" ~/.config/
    cp -r "$(dirname "$0")/hypr" ~/.config/
    pkill qs && sleep 2 && qs -c ii &
    echo "✅ Restored!"
else
    echo "❌ Cancelled."
fi
EOF
chmod +x "$BACKUP_DIR/RESTORE.sh"
```

---

## STEP 2: Switch to Waffle Panels

### Check Current Panel Family

```bash
# See what panels are currently loading
grep "PanelLoader" ~/.config/quickshell/ii/shell.qml | head -5
```

You'll see lines like `PanelLoader { identifier: "iiBar"...` (these are "ii" panels)

### Option A: Through Settings App (Easiest)

1. Press `Super + I` to open Settings
2. Look for "Interface" or "Panel" settings
3. Find "Panel Family" option
4. Change from "ii" to "waffle"
5. Restart: `pkill qs && qs -c ii &`

### Option B: Edit Config File Manually

```bash
# Check if there's a panel family setting
grep -i "panelFamily" ~/.config/illogical-impulse/config.json

# If it exists, edit it:
nano ~/.config/illogical-impulse/config.json
# Change: "panelFamily": "ii" → "panelFamily": "waffle"

# If it doesn't exist, we need to modify shell.qml
```

### Option C: Modify shell.qml Directly

```bash
# Backup shell.qml first
cp ~/.config/quickshell/ii/shell.qml ~/.config/quickshell/ii/shell.qml.backup

# Edit shell.qml
nano ~/.config/quickshell/ii/shell.qml
```

Find the section with `PanelLoader` entries. You'll see two groups:
- One group has `identifier: "ii..."`  (ii panels)
- Another group has `identifier: "waffle..."` (waffle panels)

**Comment out the ii panels and uncomment waffle panels**, or vice versa.

Look for lines like:
```qml
// ii panels (currently active)
PanelLoader { identifier: "iiBar"; ... }

// waffle panels (currently inactive)
// PanelLoader { identifier: "waffleBar"; ... }
```

Change to:
```qml
// ii panels (now inactive)
// PanelLoader { identifier: "iiBar"; ... }

// waffle panels (now active)
PanelLoader { identifier: "waffleBar"; ... }
```

**Save and restart:**
```bash
pkill qs
sleep 2
qs -c ii &
```

---

## STEP 3: Verify Waffle Panels Are Active

Your bar should look different - more Windows 11 style.

```bash
# Verify waffle Looks.qml exists
ls -l ~/.config/quickshell/ii/modules/waffle/looks/Looks.qml
```

---

## STEP 4: Add Gruvbox Colors to Looks.qml

### Official Gruvbox Dark Palette

```
# Backgrounds
bg0_hard:    #1d2021
bg0:         #282828
bg1:         #3c3836
bg2:         #504945
bg3:         #665c54
bg4:         #7c6f64

# Foregrounds
fg0:         #fbf1c7
fg1:         #ebdbb2
fg2:         #d5c4a1
fg3:         #bdae93
fg4:         #a89984

# Bright Accents (THE COLORFUL ONES!)
red:         #fb4934
green:       #b8bb26
yellow:      #fabd2f
blue:        #83a598
purple:      #d3869b
aqua:        #8ec07c
orange:      #fe8019  (primary accent)
gray:        #928374
```

### Edit Looks.qml

```bash
# Backup first
cp ~/.config/quickshell/ii/modules/waffle/looks/Looks.qml ~/.config/quickshell/ii/modules/waffle/looks/Looks.qml.backup

# Edit
nano ~/.config/quickshell/ii/modules/waffle/looks/Looks.qml
```

### Find the `QtObject {` section at the top (around line 10)

Add this RIGHT AFTER `id: root`:

```qml
QtObject {
    id: root
    
    // === GRUVBOX COLOR PALETTE ===
    readonly property var gruvbox: ({
        // Backgrounds
        bg0_hard: "#1d2021",
        bg0: "#282828",
        bg1: "#3c3836",
        bg2: "#504945",
        bg3: "#665c54",
        bg4: "#7c6f64",
        
        // Foregrounds
        fg0: "#fbf1c7",
        fg1: "#ebdbb2",
        fg2: "#d5c4a1",
        fg3: "#bdae93",
        fg4: "#a89984",
        
        // Bright Accent Colors
        red: "#fb4934",
        green: "#b8bb26",
        yellow: "#fabd2f",
        blue: "#83a598",
        purple: "#d3869b",
        aqua: "#8ec07c",
        orange: "#fe8019",
        gray: "#928374"
    })
    
    // ... rest of existing code
```

### Find `darkColors` object (around line 30-80)

Replace it with Gruvbox colors:

```qml
readonly property var darkColors: ({
    // Panel backgrounds
    bgPanelFooter: gruvbox.bg0,
    bgPanelBody: gruvbox.bg1,
    bgPanelSeparator: gruvbox.bg0_hard,
    
    // Standard backgrounds
    bg0: gruvbox.bg0,
    bg0Base: gruvbox.bg0,
    bg1: gruvbox.bg1,
    bg1Base: gruvbox.bg1,
    bg2: gruvbox.bg2,
    bg2Base: gruvbox.bg2,
    
    // Foreground colors
    fg: gruvbox.fg1,
    subfg: gruvbox.fg4,
    
    // PRIMARY ACCENT - Orange (main Gruvbox accent)
    accent: gruvbox.orange,
    accentFg: gruvbox.bg0,
    
    // === MULTI-COLOR ACCENTS - THE KEY PART! ===
    accentRed: gruvbox.red,
    accentGreen: gruvbox.green,
    accentYellow: gruvbox.yellow,
    accentBlue: gruvbox.blue,
    accentPurple: gruvbox.purple,
    accentAqua: gruvbox.aqua,
    accentOrange: gruvbox.orange,
    accentGray: gruvbox.gray,
    
    // Hover states
    bg0Hover: gruvbox.bg2,
    bg1Hover: gruvbox.bg3,
    bg2Hover: gruvbox.bg4,
    
    // Borders
    border: gruvbox.bg3,
    borderHover: gruvbox.gray,
    
    // Controls & Icons
    controlBg: gruvbox.bg3,
    inactiveIcon: gruvbox.bg4,
    
    // UI elements
    scrollbar: gruvbox.bg2,
    scrollbarHover: gruvbox.bg3,
    selection: gruvbox.bg3
})
```

**Save the file (Ctrl+O, Enter, Ctrl+X in nano)**

---

## STEP 5: Apply Multi-Colors to UI Elements

Now that we have the colors defined, let's use them!

### Common Places to Apply Multi-Colors:

#### Workspace Indicators (Rainbow Colors!)

Find workspace/taskbar components in:
```bash
~/.config/quickshell/ii/modules/waffle/bar/
```

Look for workspace button/indicator files. Add:

```qml
// Workspace color mapping
readonly property var workspaceColors: [
    Looks.colors.accentRed,      // Workspace 1
    Looks.colors.accentOrange,   // Workspace 2
    Looks.colors.accentYellow,   // Workspace 3
    Looks.colors.accentGreen,    // Workspace 4
    Looks.colors.accentAqua,     // Workspace 5
    Looks.colors.accentBlue,     // Workspace 6
    Looks.colors.accentPurple,   // Workspace 7
]

// In the workspace indicator:
border.color: workspaceColors[workspaceId - 1] || Looks.colors.accent
```

#### System Status Icons

Battery indicator:
```qml
color: {
    if (batteryCharging) return Looks.colors.accentGreen
    if (batteryLevel < 20) return Looks.colors.accentRed
    if (batteryLevel < 50) return Looks.colors.accentYellow
    return Looks.colors.fg
}
```

Volume indicator:
```qml
color: muted ? Looks.colors.accentRed : Looks.colors.accentAqua
```

Network indicator:
```qml
color: connected ? Looks.colors.accentGreen : Looks.colors.accentRed
```

---

## STEP 6: Clear Cache and Restart

```bash
# Clear QML cache
rm -rf ~/.cache/quickshell/qmlcache/
rm -rf ~/.cache/quickshell/qtpipelinecache-*

# Restart quickshell
pkill qs
sleep 2
qs -c ii &
```

**Your bar should now have Gruvbox colors!**

---

## STEP 7: Optional - Hyprland Window Borders

Add colorful window borders in `~/.config/hypr/hyprland.conf`:

```conf
# Add at the end of the file (after your GPU settings!)

# === GRUVBOX WINDOW BORDERS ===
general {
    col.active_border = rgb(fe8019) rgb(fb4934) 45deg  # Orange to Red
    col.inactive_border = rgb(3c3836)                   # bg1
}

# App-specific borders
windowrulev2 = bordercolor rgb(b8bb26), class:^(kitty)$      # Green - Terminal
windowrulev2 = bordercolor rgb(83a598), class:^(firefox)$    # Blue - Browser
windowrulev2 = bordercolor rgb(d3869b), class:^(code)$       # Purple - Editor
windowrulev2 = bordercolor rgb(fabd2f), class:^(thunar)$     # Yellow - Files
windowrulev2 = bordercolor rgb(8ec07c), class:^(mpv)$        # Aqua - Media
```

Reload:
```bash
hyprctl reload
```

---

## STEP 8: GTK/Qt Application Theming

For complete Gruvbox across all apps:

```bash
# Install Gruvbox GTK theme
yay -S gruvbox-material-gtk-theme-git
yay -S gruvbox-plus-icon-theme-git

# Apply
gsettings set org.gnome.desktop.interface gtk-theme 'Gruvbox-Material-Dark'
gsettings set org.gnome.desktop.interface icon-theme 'Gruvbox-Plus-Dark'
```

---

## Troubleshooting

### Colors Don't Change After Restart

```bash
# Make sure cache is cleared
rm -rf ~/.cache/quickshell/qmlcache/

# Check for syntax errors in Looks.qml
cat ~/.config/quickshell/ii/modules/waffle/looks/Looks.qml | grep -A 5 "gruvbox:"

# Restart with verbose output
pkill qs
qs -c ii
# Watch for errors in output
```

### Waffle Panels Don't Load

```bash
# Check shell.qml for waffle panel loaders
grep "waffle" ~/.config/quickshell/ii/shell.qml

# Make sure they're not commented out
```

### Want to Go Back to "ii" Panels

```bash
# Run your restore script
$BACKUP_DIR/RESTORE.sh

# Or manually restore
cp -r ~/.config/quickshell-backup-*/quickshell ~/.config/
pkill qs && qs -c ii &
```

---

## Quick Reference: File Locations

```
Waffle theming:
~/.config/quickshell/ii/modules/waffle/looks/Looks.qml

Waffle components:
~/.config/quickshell/ii/modules/waffle/bar/
~/.config/quickshell/ii/modules/waffle/actionCenter/

Panel selection:
~/.config/quickshell/ii/shell.qml
~/.config/illogical-impulse/config.json

Hyprland config:
~/.config/hypr/hyprland.conf
```

---

## Summary

✅ **Backup created** - can always restore  
✅ **Switched to waffle panels** - easier color control  
✅ **Added Gruvbox palette** to Looks.qml  
✅ **Multi-color accents** available for use  
✅ **Applied to UI elements** - workspaces, status, etc.  
✅ **Window borders** color-coded by app  
✅ **GTK apps** themed with Gruvbox  

---

## Next Steps / Customization

- Modify individual component colors in `~/.config/quickshell/ii/modules/waffle/`
- Adjust transparency in Looks.qml (lines 20-23)
- Create more workspace colors
- Color-code different widget states
- Add Gruvbox to terminal (kitty.conf)

---

## Need to Undo Everything?

```bash
# Find your backup
ls -d ~/.config/quickshell-backup-*

# Run restore script
~/.config/quickshell-backup-YYYYMMDD_HHMMSS/RESTORE.sh
```

Done! You have a beautiful, authentic Gruvbox multi-color theme! 🎨
