#!/usr/bin/env python3
"""
Waypoint Parser for Modern Reaper Enhancements
Extracts waypoint dumps from qconsole.log and converts to proper QuakeC format.

Usage:
    python parse_waypoints.py <log_file> <map_name> [output_file]

Example:
    python parse_waypoints.py ../launch/quake-spasm/qconsole.log dm2
    python parse_waypoints.py ../launch/quake-spasm/qconsole.log dm2 ../reaper_mre/maps/dm2.qc

Output format:
    - Vectors use single quotes: '1234.5 678.9 12.3'
    - Strings use double quotes: "target_name" or ""
"""

import re
import sys
from pathlib import Path


def extract_waypoints(log_file):
    """Extract waypoint data between CUT HERE markers."""
    with open(log_file, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    # Find the waypoint section
    start_marker = "// ===== CUT HERE: START WAYPOINTS ====="
    end_marker = "// ===== CUT HERE: END WAYPOINTS ====="

    start_idx = content.rfind(start_marker)  # Use rfind to get the LAST occurrence
    end_idx = content.rfind(end_marker)

    if start_idx == -1 or end_idx == -1:
        print("ERROR: Waypoint markers not found in log file", file=sys.stderr)
        print("Make sure you ran 'impulse 100' in-game to dump waypoints", file=sys.stderr)
        return None

    waypoint_section = content[start_idx:end_idx + len(end_marker)]
    return waypoint_section


def fix_quote_syntax(waypoint_line):
    """
    Convert waypoint line from dump format to proper QuakeC format.

    Input:  SpawnSavedWaypoint(''1234 567 89'', 42, 0, '')
    Output: SpawnSavedWaypoint('1234 567 89', 42, 0, "")
    """
    # Replace double single-quotes around vectors with single quotes
    line = re.sub(r"''(\s*[0-9.\s-]+?)\s*''", r"'\1'", waypoint_line)

    # Replace double single-quotes for empty target with double quotes
    line = line.replace(", '')", ', "")')

    return line


def parse_waypoints(log_file, map_name, output_file=None):
    """Parse waypoints and generate QuakeC file."""

    # Extract raw waypoint data
    waypoint_section = extract_waypoints(log_file)
    if not waypoint_section:
        return False

    # Extract stats from footer
    total_match = re.search(r'// Total Nodes:\s*(\d+)', waypoint_section)
    traffic_match = re.search(r'// Avg Traffic Score:\s*([\d.]+)', waypoint_section)
    danger_match = re.search(r'// Avg Danger Scent:\s*([\d.]+)', waypoint_section)

    total_nodes = int(total_match.group(1)) if total_match else 0
    avg_traffic = float(traffic_match.group(1)) if traffic_match else 0.0
    avg_danger = float(danger_match.group(1)) if danger_match else 0.0

    print(f"Found {total_nodes} waypoints")
    print(f"Avg Traffic Score: {avg_traffic:.1f}")
    print(f"Avg Danger Scent: {avg_danger:.1f}")

    # Extract waypoint lines (SpawnSavedWaypoint calls)
    waypoint_lines = re.findall(r'    SpawnSavedWaypoint\([^)]+\);', waypoint_section)

    if len(waypoint_lines) != total_nodes:
        print(f"WARNING: Found {len(waypoint_lines)} waypoint lines but expected {total_nodes}", file=sys.stderr)

    # Generate output file content
    output_lines = [
        f"// ===== {map_name.upper()} WAYPOINTS =====\n",
        f"// Generated: {total_nodes} nodes from bot traffic analysis\n",
        f"// Avg Traffic Score: {avg_traffic:.1f}\n",
        f"// Avg Danger Scent: {avg_danger:.1f}\n",
        f"// Format: SpawnSavedWaypoint(origin, traffic_score, danger_scent, target)\n",
        f"//\n",
        f"// PHASE 6: Smart Triggers (Target Linking for Button->Door Logic)\n",
        f"\n",
        f"void() LoadMapWaypoints_{map_name} =\n",
        f"{{\n"
    ]

    # Fix quote syntax for each waypoint
    for line in waypoint_lines:
        fixed_line = fix_quote_syntax(line)
        output_lines.append(fixed_line + '\n')

    output_lines.append("};\n")

    # Write output
    if output_file:
        output_path = Path(output_file)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with open(output_path, 'w', encoding='utf-8') as f:
            f.writelines(output_lines)
        print(f"\nWrote {total_nodes} waypoints to: {output_file}")
    else:
        # Print to stdout
        print("\n" + "".join(output_lines))

    return True


def main():
    if len(sys.argv) < 3:
        print("Usage: python parse_waypoints.py <log_file> <map_name> [output_file]")
        print("\nExample:")
        print("  python parse_waypoints.py ../launch/quake-spasm/qconsole.log dm2")
        print("  python parse_waypoints.py ../launch/quake-spasm/qconsole.log dm2 ../reaper_mre/maps/dm2.qc")
        sys.exit(1)

    log_file = sys.argv[1]
    map_name = sys.argv[2]
    output_file = sys.argv[3] if len(sys.argv) > 3 else None

    if not Path(log_file).exists():
        print(f"ERROR: Log file not found: {log_file}", file=sys.stderr)
        sys.exit(1)

    success = parse_waypoints(log_file, map_name, output_file)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
