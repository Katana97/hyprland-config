#!/usr/bin/env python3
"""
Apply Gruvbox color theme to waffle Looks.qml
This script modifies the Looks.qml file to use authentic Gruvbox colors
"""

import os
import sys
from datetime import datetime
from pathlib import Path

# File paths
LOOKS_FILE = Path.home() / ".config/quickshell/ii/modules/waffle/looks/Looks.qml"

# Gruvbox palette to insert after "id: root"
GRUVBOX_PALETTE = '''
    // === GRUVBOX COLOR PALETTE ===
    readonly property var gruvbox: ({
        // Backgrounds
        "bg0_hard": "#1d2021",
        "bg0": "#282828",
        "bg1": "#3c3836",
        "bg2": "#504945",
        "bg3": "#665c54",
        "bg4": "#7c6f64",
        
        // Foregrounds
        "fg0": "#fbf1c7",
        "fg1": "#ebdbb2",
        "fg2": "#d5c4a1",
        "fg3": "#bdae93",
        "fg4": "#a89984",
        
        // Bright Accent Colors
        "red": "#fb4934",
        "green": "#b8bb26",
        "yellow": "#fabd2f",
        "blue": "#83a598",
        "purple": "#d3869b",
        "aqua": "#8ec07c",
        "orange": "#fe8019",
        "gray": "#928374"
    })
'''

# Gruvbox darkColors replacement
GRUVBOX_DARKCOLORS = '''    darkColors: QtObject {
        id: darkColors
        
        // === GRUVBOX DARK COLORS ===
        // Panel backgrounds
        property color bgPanelBody: gruvbox.bg1
        property color bgPanelSeparator: gruvbox.bg0_hard
        
        // Layer backgrounds
        property color bg0: gruvbox.bg0
        property color bg0Border: gruvbox.bg3
        property color bg1Base: gruvbox.bg1
        property color bg1: gruvbox.bg1
        property color bg1Hover: gruvbox.bg2
        property color bg1Active: gruvbox.bg3
        property color bg1Border: gruvbox.bg3
        property color bg2Base: gruvbox.bg2
        property color bg2: gruvbox.bg2
        property color bg2Hover: gruvbox.bg3
        property color bg2Active: gruvbox.bg1
        property color bg2Border: gruvbox.bg3
        
        // Foreground colors
        property color subfg: gruvbox.fg4
        property color fg: gruvbox.fg1
        property color fg1: gruvbox.fg2
        property color inactiveIcon: gruvbox.bg4
        
        // Controls
        property color controlBgInactive: gruvbox.bg3
        property color controlBg: gruvbox.bg4
        property color controlBgHover: gruvbox.gray
        property color controlFg: gruvbox.fg1
        
        // Special
        property color accentUnfocused: gruvbox.gray
        property color link: gruvbox.blue
        property color inputBg: ColorUtils.transparentize(gruvbox.bg1, 0.5)
    }
'''

# Multi-color accents to add
GRUVBOX_ACCENTS = '''        
        // === GRUVBOX MULTI-COLOR ACCENTS ===
        property color accentRed: gruvbox.red
        property color accentGreen: gruvbox.green
        property color accentYellow: gruvbox.yellow
        property color accentBlue: gruvbox.blue
        property color accentPurple: gruvbox.purple
        property color accentAqua: gruvbox.aqua
        property color accentOrange: gruvbox.orange
        property color accentGray: gruvbox.gray
'''

def main():
    print("🎨 Applying Gruvbox Theme to Looks.qml")
    print("=" * 50)
    
    # Check if file exists
    if not LOOKS_FILE.exists():
        print(f"❌ Error: {LOOKS_FILE} not found!")
        sys.exit(1)
    
    # Create backup
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_file = LOOKS_FILE.with_suffix(f".qml.backup-{timestamp}")
    print(f"📦 Creating backup: {backup_file}")
    
    with open(LOOKS_FILE, 'r') as f:
        content = f.read()
    
    with open(backup_file, 'w') as f:
        f.write(content)
    
    lines = content.split('\n')
    new_lines = []
    i = 0
    in_darkcolors = False
    darkcolors_depth = 0
    skip_until_closing = False
    
    while i < len(lines):
        line = lines[i]
        
        # Step 1: Add Gruvbox palette after "id: root"
        if '    id: root' in line and 'gruvbox' not in content:
            new_lines.append(line)
            new_lines.append(GRUVBOX_PALETTE)
            print("✅ Added Gruvbox palette")
            i += 1
            continue
        
        # Step 2: Replace darkColors section
        if 'darkColors: QtObject {' in line:
            new_lines.append(GRUVBOX_DARKCOLORS)
            print("✅ Replaced darkColors with Gruvbox")
            in_darkcolors = True
            darkcolors_depth = 1
            i += 1
            continue
        
        if in_darkcolors:
            if '{' in line:
                darkcolors_depth += line.count('{')
            if '}' in line:
                darkcolors_depth -= line.count('}')
            
            if darkcolors_depth == 0:
                in_darkcolors = False
            i += 1
            continue
        
        # Step 3: Add multi-color accents after accentHover
        if 'property color accentHover: Appearance.colors.colPrimaryHover' in line and 'accentRed' not in content:
            new_lines.append(line)
            new_lines.append(GRUVBOX_ACCENTS)
            print("✅ Added multi-color accent properties")
            i += 1
            continue
        
        new_lines.append(line)
        i += 1
    
    # Write modified content
    with open(LOOKS_FILE, 'w') as f:
        f.write('\n'.join(new_lines))
    
    print("\n✅ Gruvbox theme applied successfully!")
    print(f"\n📝 Backup saved at: {backup_file}")
    print("\n🔄 Now restart Quickshell:")
    print("   pkill qs && sleep 2 && qs -c ii &")
    print(f"\n🔙 To restore original:")
    print(f"   cp {backup_file} {LOOKS_FILE}")

if __name__ == "__main__":
    main()
