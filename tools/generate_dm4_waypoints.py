#!/usr/bin/env python3
import re

# Read the qconsole.log
with open(r'c:\reaperai\launch\quake-spasm\qconsole.log', 'r') as f:
    lines = f.readlines()

# Extract all SpawnSavedWaypoint lines
waypoints = []
for line in lines:
    if 'SpawnSavedWaypoint' in line:
        # Extract the SpawnSavedWaypoint call
        match = re.search(r"SpawnSavedWaypoint\([^)]+\)", line)
        if match:
            wp = match.group(0)
            # Replace double apostrophes with single quotes
            wp = wp.replace("''", "'")
            waypoints.append(wp)

# Get the last 343 waypoints (the latest complete dump)
waypoints = waypoints[-343:]

# Generate the dm4.qc file
output = """// ===== DM4 WAYPOINTS (343 nodes - merged from gameplay) =====
// Generated from bot navigation data
// Expanded from 181 base waypoints + 162 discovered routes

void() LoadMapWaypoints_dm4 =
{
"""

for wp in waypoints:
    output += f"    {wp};\n"

output += """};
// ===== END DM4 WAYPOINTS =====
"""

# Write to dm4.qc
with open(r'c:\reaperai\reaper_mre\maps\dm4.qc', 'w') as f:
    f.write(output)

print(f"Generated dm4.qc with {len(waypoints)} waypoints")
