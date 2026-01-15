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
            # QuakeC escapes single quotes by doubling them in console output
            # Convert: ''x y z'' -> 'x y z' (coordinate strings use single quotes)
            # Convert: '' (empty string) -> "" (target parameter uses double quotes)
            wp = wp.replace("''", "'")
            # Fix empty string target parameter: ', ')' -> ', "")'
            wp = wp.replace(", ')", ', "")')
            waypoints.append(wp)

# Get the last 452 waypoints (the latest complete dump)
waypoints = waypoints[-452:]

# Generate the dm4.qc file
output = """// ===== DM4 WAYPOINTS (452 nodes - merged from gameplay) =====
// Generated from bot navigation data - PHASE 7: Active Projectile Dodging
// Expanded from 343 base waypoints + 109 discovered routes during Phase 7 testing
// Format: SpawnSavedWaypoint(origin, traffic_score, danger_scent, target)

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
