#!/usr/bin/env python3
"""Replace Material You m3colors with Gruvbox colors in Appearance.qml"""

from pathlib import Path
import re

APPEARANCE_FILE = Path.home() / ".config/quickshell/ii/modules/common/Appearance.qml"

# Backup
backup = APPEARANCE_FILE.with_suffix(".qml.gruvbox-backup")
content = APPEARANCE_FILE.read_text()
backup.write_text(content)
print(f"📦 Backup: {backup}")

# Gruvbox Material You mappings
gruvbox_m3 = {
    # Backgrounds - using Gruvbox bg colors
    "m3background": "#282828",           # bg0
    "m3onBackground": "#ebdbb2",         # fg1
    "m3surface": "#282828",              # bg0
    "m3surfaceDim": "#1d2021",          # bg0_hard
    "m3surfaceBright": "#3c3836",       # bg1
    "m3surfaceContainerLowest": "#1d2021",  # bg0_hard
    "m3surfaceContainerLow": "#32302f",     # between bg0_hard and bg1
    "m3surfaceContainer": "#3c3836",        # bg1
    "m3surfaceContainerHigh": "#504945",    # bg2
    "m3surfaceContainerHighest": "#665c54", # bg3
    "m3onSurface": "#ebdbb2",           # fg1
    "m3surfaceVariant": "#504945",      # bg2
    "m3onSurfaceVariant": "#d5c4a1",    # fg2
    "m3inverseSurface": "#ebdbb2",      # fg1
    "m3inverseOnSurface": "#282828",    # bg0
    "m3outline": "#928374",             # gray
    "m3outlineVariant": "#665c54",      # bg3
    "m3shadow": "#000000",
    "m3scrim": "#000000",
    "m3surfaceTint": "#fe8019",         # orange
    
    # Primary - Gruvbox Orange
    "m3primary": "#fe8019",             # orange
    "m3onPrimary": "#282828",           # bg0
    "m3primaryContainer": "#504945",    # bg2
    "m3onPrimaryContainer": "#fbf1c7",  # fg0
    "m3inversePrimary": "#fe8019",      # orange
    
    # Secondary - Gruvbox Green
    "m3secondary": "#b8bb26",           # green
    "m3onSecondary": "#282828",         # bg0
    "m3secondaryContainer": "#504945",  # bg2
    "m3onSecondaryContainer": "#fbf1c7", # fg0
    
    # Tertiary - Gruvbox Aqua
    "m3tertiary": "#8ec07c",            # aqua
    "m3onTertiary": "#282828",          # bg0
    "m3tertiaryContainer": "#504945",   # bg2
    "m3onTertiaryContainer": "#fbf1c7", # fg0
    
    # Error - Gruvbox Red
    "m3error": "#fb4934",               # red
    "m3onError": "#282828",             # bg0
    "m3errorContainer": "#cc2412",      # dark red
    "m3onErrorContainer": "#fbf1c7",    # fg0
    
    # Fixed variants - lighter versions
    "m3primaryFixed": "#fabd2f",        # yellow
    "m3primaryFixedDim": "#fe8019",     # orange
    "m3onPrimaryFixed": "#282828",      # bg0
    "m3onPrimaryFixedVariant": "#3c3836", # bg1
    
    "m3secondaryFixed": "#d3869b",      # purple
    "m3secondaryFixedDim": "#b8bb26",   # green
    "m3onSecondaryFixed": "#282828",    # bg0
    "m3onSecondaryFixedVariant": "#3c3836", # bg1
    
    "m3tertiaryFixed": "#8ec07c",       # aqua
    "m3tertiaryFixedDim": "#8ec07c",    # aqua
    "m3onTertiaryFixed": "#282828",     # bg0
    "m3onTertiaryFixedVariant": "#3c3836", # bg1
    
    # Success (keep existing or use green)
    "m3success": "#b8bb26",             # green
    "m3onSuccess": "#282828",           # bg0
}

# Replace each m3color property
for prop, color in gruvbox_m3.items():
    # Match: property color m3background: "#141313"
    pattern = f'property color {prop}: "[^"]*"'
    replacement = f'property color {prop}: "{color}"'
    content = re.sub(pattern, replacement, content)

# Write back
APPEARANCE_FILE.write_text(content)

print("✅ Replaced Material You colors with Gruvbox")
print("\n🔄 Restart Quickshell:")
print("   rm -rf ~/.cache/quickshell/ && pkill -9 qs && sleep 2 && qs -c ii &")
