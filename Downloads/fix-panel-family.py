#!/usr/bin/env python3
"""Add panelFamily conditions to PanelLoader entries in shell.qml"""

from pathlib import Path
import re

SHELL_FILE = Path.home() / ".config/quickshell/ii/shell.qml"

# Backup
backup = SHELL_FILE.with_suffix(".qml.pre-panel-fix")
content = SHELL_FILE.read_text()
backup.write_text(content)
print(f"📦 Backup: {backup}")

lines = content.split('\n')
new_lines = []

for line in lines:
    # Check if it's a PanelLoader line
    if 'PanelLoader { identifier:' in line:
        # Extract the identifier
        match = re.search(r'identifier: "(\w+)"', line)
        if match:
            identifier = match.group(1)
            
            # Add condition based on prefix
            if identifier.startswith('ii'):
                # ii panels - only load when panelFamily is "ii"
                if 'extraCondition:' in line:
                    # Already has extraCondition, AND it with panelFamily check
                    line = re.sub(
                        r'extraCondition: ([^;]+);',
                        r'extraCondition: Config.options.panelFamily === "ii" && (\1);',
                        line
                    )
                else:
                    # No extraCondition, add one
                    line = re.sub(
                        r'(identifier: "\w+")',
                        r'\1; extraCondition: Config.options.panelFamily === "ii"',
                        line
                    )
            
            elif identifier.startswith('w'):
                # waffle panels - only load when panelFamily is "waffle"
                if 'extraCondition:' in line:
                    line = re.sub(
                        r'extraCondition: ([^;]+);',
                        r'extraCondition: Config.options.panelFamily === "waffle" && (\1);',
                        line
                    )
                else:
                    line = re.sub(
                        r'(identifier: "\w+")',
                        r'\1; extraCondition: Config.options.panelFamily === "waffle"',
                        line
                    )
    
    new_lines.append(line)

# Write back
SHELL_FILE.write_text('\n'.join(new_lines))

print("✅ Added panelFamily conditions to all PanelLoaders")
print("\n🔄 Restart Quickshell:")
print("   pkill -9 qs && sleep 2 && qs -c ii &")
