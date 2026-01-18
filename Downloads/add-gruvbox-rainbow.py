#!/usr/bin/env python3
"""Add Gruvbox rainbow workspaces and colored status indicators"""

from pathlib import Path
import re

# Gruvbox color palette
GRUVBOX = {
    'red': '#fb4934',
    'orange': '#fe8019', 
    'yellow': '#fabd2f',
    'green': '#b8bb26',
    'aqua': '#8ec07c',
    'blue': '#83a598',
    'purple': '#d3869b',
}

WORKSPACE_FILE = Path.home() / ".config/quickshell/ii/modules/ii/bar/Workspaces.qml"

# Backup
backup = WORKSPACE_FILE.with_suffix(".qml.pre-rainbow")
content = WORKSPACE_FILE.read_text()
backup.write_text(content)
print(f"📦 Backup: {backup}")

# Find the section where workspace colors are defined
# We need to add a color array and modify the active workspace color

# Add Gruvbox workspace colors array at the top of the file, after imports
imports_end = content.find('Rectangle {')
if imports_end != -1:
    gruvbox_colors = '''
    // === GRUVBOX RAINBOW WORKSPACE COLORS ===
    readonly property var gruvboxWorkspaceColors: [
        "#fb4934",  // Workspace 1: Red
        "#fe8019",  // Workspace 2: Orange
        "#fabd2f",  // Workspace 3: Yellow
        "#b8bb26",  // Workspace 4: Green
        "#8ec07c",  // Workspace 5: Aqua
        "#83a598",  // Workspace 6: Blue
        "#d3869b",  // Workspace 7: Purple
        "#fb4934",  // Workspace 8: Red (cycle repeats)
        "#fe8019",  // Workspace 9: Orange
        "#fabd2f",  // Workspace 10: Yellow
    ]
    
'''
    content = content[:imports_end] + gruvbox_colors + content[imports_end:]

# Replace the active workspace color line
# Old: color: Appearance.colors.colPrimary
# New: color: gruvboxWorkspaceColors[monitor?.activeWorkspace?.id - 1] || Appearance.colors.colPrimary

content = re.sub(
    r'color: Appearance\.colors\.colPrimary(\s+anchors)',
    r'color: gruvboxWorkspaceColors[(monitor?.activeWorkspace?.id ?? 1) - 1] || Appearance.colors.colPrimary\1',
    content
)

WORKSPACE_FILE.write_text(content)
print("✅ Added rainbow workspace colors")

print("\n🎨 Workspace colors:")
print("  1: Red")
print("  2: Orange") 
print("  3: Yellow")
print("  4: Green")
print("  5: Aqua")
print("  6: Blue")
print("  7: Purple")
print("  (cycles for workspaces 8-10)")

print("\n🔄 Restart Quickshell to see changes:")
print("   pkill -9 qs && sleep 2 && qs -c ii &")
