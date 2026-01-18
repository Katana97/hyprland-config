#!/usr/bin/env python3
"""Fix gruvbox object syntax from JavaScript to proper QML QtObject"""

import re
from pathlib import Path

LOOKS_FILE = Path.home() / ".config/quickshell/ii/modules/waffle/looks/Looks.qml"

# Backup
backup = LOOKS_FILE.with_suffix(".qml.pre-syntax-fix")
with open(LOOKS_FILE, 'r') as f:
    content = f.read()
    
with open(backup, 'w') as f:
    f.write(content)

print(f"📦 Backup created: {backup}")

# New gruvbox definition with proper QML syntax
NEW_GRUVBOX = '''    // === GRUVBOX COLOR PALETTE ===
    readonly property QtObject gruvbox: QtObject {
        // Backgrounds
        readonly property color bg0_hard: "#1d2021"
        readonly property color bg0: "#282828"
        readonly property color bg1: "#3c3836"
        readonly property color bg2: "#504945"
        readonly property color bg3: "#665c54"
        readonly property color bg4: "#7c6f64"
        
        // Foregrounds
        readonly property color fg0: "#fbf1c7"
        readonly property color fg1: "#ebdbb2"
        readonly property color fg2: "#d5c4a1"
        readonly property color fg3: "#bdae93"
        readonly property color fg4: "#a89984"
        
        // Bright Accent Colors
        readonly property color red: "#fb4934"
        readonly property color green: "#b8bb26"
        readonly property color yellow: "#fabd2f"
        readonly property color blue: "#83a598"
        readonly property color purple: "#d3869b"
        readonly property color aqua: "#8ec07c"
        readonly property color orange: "#fe8019"
        readonly property color gray: "#928374"
    }
'''

# Pattern to match the old gruvbox object (JavaScript syntax)
# Matches from "readonly property var gruvbox:" to the closing "})"
pattern = r'    // === GRUVBOX COLOR PALETTE ===\s+readonly property var gruvbox:.*?\}\)'

# Replace with new QtObject syntax
new_content = re.sub(pattern, NEW_GRUVBOX.rstrip(), content, flags=re.DOTALL)

# Write back
with open(LOOKS_FILE, 'w') as f:
    f.write(new_content)

print("✅ Fixed gruvbox object syntax from JavaScript to QML QtObject")
print("\n🔄 Now restart Quickshell:")
print("   pkill -9 qs && sleep 2 && qs -c ii &")
