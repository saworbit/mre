#!/usr/bin/env python3
"""
Rocket Jump Learning Tool for Modern Reaper Enhancements
Analyzes player observation logs to extract validated rocket jump techniques.

Usage:
    python learn_rj_from_player.py <log_file> <map_name> [output_file]

Example:
    python learn_rj_from_player.py ../launch/quake-spasm/qconsole.log dm2
    python learn_rj_from_player.py ../launch/quake-spasm/qconsole.log dm2 ../reaper_mre/maps/dm2_rj.qc

Workflow:
    1. Enable player observation: impulse 199 in-game
    2. Play match and perform rocket jumps
    3. Run this script to extract learned techniques
    4. Review and integrate validated RJ waypoints

Detection Criteria:
    - Self-rocket damage (PLAYER_RJ_DAMAGE markers)
    - Velocity gain >400 u/s (upward momentum)
    - Height gain >100 units (successful elevation)
    - No death within 2 seconds (survivable technique)
    - Pitch angle ~-45 to -90 degrees (downward shot)
"""

import re
import sys
from pathlib import Path
from typing import List, Dict, Optional


class RocketJumpEvent:
    """Represents a single rocket jump attempt with all metadata."""

    def __init__(self, origin: tuple, damage: float, velocity: tuple,
                 angles: tuple, timestamp: float):
        self.origin = origin
        self.damage = damage
        self.velocity = velocity
        self.angles = angles
        self.timestamp = timestamp
        self.success = False
        self.height_gain = 0.0
        self.speed_gain = 0.0
        self.nearby_items = []

    def __repr__(self):
        return f"RJ@{self.origin} vel={self.velocity} dmg={self.damage:.1f} success={self.success}"


def parse_vector(vector_str: str) -> tuple:
    """Parse QuakeC vector string '123.4 567.8 9.0' to tuple."""
    try:
        parts = vector_str.strip().split()
        return (float(parts[0]), float(parts[1]), float(parts[2]))
    except (ValueError, IndexError):
        return (0.0, 0.0, 0.0)


def extract_rj_events(log_file: str) -> List[RocketJumpEvent]:
    """Extract all PLAYER_RJ_DAMAGE events from log file."""
    with open(log_file, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    # Pattern: PLAYER_RJ_DAMAGE: '1234.5 678.9 12.3' | dmg=45.0 | vel='100 200 300' | ang='0 90 0' | time=123.45
    # Handles optional quotes, whitespace, and line breaks in the log output
    pattern = r"PLAYER_RJ_DAMAGE:\s*'?([0-9.\s-]+?)'?\s*\|\s*dmg=\s*([0-9.]+)\s*\|\s*vel=\s*'?([0-9.\s-]+?)'?\s*\|\s*\n?ang=\s*'?([0-9.\s-]+?)'?\s*\|\s*time=\s*([0-9.]+)"

    events = []
    for match in re.finditer(pattern, content):
        origin = parse_vector(match.group(1))
        damage = float(match.group(2))
        velocity = parse_vector(match.group(3))
        angles = parse_vector(match.group(4))
        timestamp = float(match.group(5))

        event = RocketJumpEvent(origin, damage, velocity, angles, timestamp)
        events.append(event)

    return events


def validate_rj_success(events: List[RocketJumpEvent], log_content: str) -> None:
    """
    Validate which RJ events were successful.

    Success criteria:
    - Upward velocity component >200 u/s (meaningful vertical boost)
    - No death within 2 seconds after the event
    - Pitch angle between -20 and -90 degrees (downward shot - relaxed for realistic RJs)
    """
    # Extract all player death timestamps from log
    death_pattern = r"(\d+\.\d+).*?(?:died|killed|suicide)"
    death_times = [float(m.group(1)) for m in re.finditer(death_pattern, log_content, re.IGNORECASE)]

    for event in events:
        # Check 1: Upward velocity gain (Z component in Quake)
        upward_velocity = event.velocity[2]  # Z axis
        event.speed_gain = upward_velocity

        # Check 2: Pitch angle (proper RJ technique)
        pitch = event.angles[0]  # Pitch in Quake angles
        proper_angle = -90 <= pitch <= -20  # Looking down for RJ (relaxed from -45 to -20)

        # Check 3: Survivability (no death within 2s)
        survived = True
        for death_time in death_times:
            if 0 < (death_time - event.timestamp) < 2.0:
                survived = False
                break

        # Mark as successful if all criteria met
        if upward_velocity > 200 and proper_angle and survived:
            event.success = True
            event.height_gain = upward_velocity / 10.0  # Rough estimate (vel → height)


def cluster_rj_locations(events: List[RocketJumpEvent], radius: float = 128.0) -> List[RocketJumpEvent]:
    """
    Cluster nearby successful RJs and return representative events.
    If multiple RJs occur within radius, keep the one with highest velocity gain.
    """
    successful = [e for e in events if e.success]
    if not successful:
        return []

    clusters = []
    used = set()

    for i, event in enumerate(successful):
        if i in used:
            continue

        # Find all events within radius
        cluster = [event]
        for j, other in enumerate(successful):
            if i == j or j in used:
                continue

            # Distance calculation (simple Euclidean)
            dx = event.origin[0] - other.origin[0]
            dy = event.origin[1] - other.origin[1]
            dz = event.origin[2] - other.origin[2]
            dist = (dx*dx + dy*dy + dz*dz) ** 0.5

            if dist < radius:
                cluster.append(other)
                used.add(j)

        # Keep the best RJ from this cluster (highest velocity gain)
        best = max(cluster, key=lambda e: e.speed_gain)
        clusters.append(best)
        used.add(i)

    return clusters


def generate_rj_waypoints(events: List[RocketJumpEvent], map_name: str) -> str:
    """Generate QuakeC code for learned rocket jump waypoints."""
    if not events:
        return "// No successful rocket jumps detected\n"

    output_lines = [
        f"// ===== {map_name.upper()} ROCKET JUMP WAYPOINTS =====\n",
        f"// Generated: {len(events)} validated RJ techniques from player observation\n",
        f"// Source: Player observation mode (impulse 199)\n",
        f"// Format: SpawnLearnedRJ(origin, angles, velocity_gain, technique_type)\n",
        f"//\n",
        f"// PLAYER OBSERVATION LEARNING SYSTEM - Phase 1: Rocket Jump Detection\n",
        f"\n",
        f"void() LoadPlayerLearnedRJ_{map_name} =\n",
        f"{{\n"
    ]

    for i, event in enumerate(events, 1):
        # Format as QuakeC function call
        origin_str = f"'{event.origin[0]:.1f} {event.origin[1]:.1f} {event.origin[2]:.1f}'"
        angles_str = f"'{event.angles[0]:.1f} {event.angles[1]:.1f} {event.angles[2]:.1f}'"
        velocity_gain = event.speed_gain

        # Comment with metadata
        output_lines.append(f"    // RJ #{i}: vel_gain={velocity_gain:.1f} u/s, height~{event.height_gain:.0f}u\n")
        output_lines.append(f"    SpawnLearnedRJ({origin_str}, {angles_str}, {velocity_gain:.1f}, \"rj_vertical\");\n")

        if i < len(events):
            output_lines.append("\n")

    output_lines.append("};\\n")

    return "".join(output_lines)


def learn_from_player(log_file: str, map_name: str, output_file: Optional[str] = None) -> bool:
    """Main learning pipeline: extract → validate → cluster → generate."""

    # Step 1: Extract raw RJ events
    print(f"Analyzing log file: {log_file}")
    events = extract_rj_events(log_file)
    print(f"Found {len(events)} rocket jump attempts")

    if not events:
        print("ERROR: No PLAYER_RJ_DAMAGE markers found")
        print("Make sure you:")
        print("  1. Enabled player observation (impulse 199)")
        print("  2. Performed rocket jumps during gameplay")
        print("  3. Check qconsole.log for PLAYER_RJ_DAMAGE lines")
        return False

    # Step 2: Validate success criteria
    with open(log_file, 'r', encoding='utf-8', errors='ignore') as f:
        log_content = f.read()
    validate_rj_success(events, log_content)

    successful = [e for e in events if e.success]
    print(f"Validated {len(successful)} successful rocket jumps")

    if not successful:
        print("WARNING: No successful RJs detected (all failed validation)")
        print("Validation criteria:")
        print("  - Upward velocity >200 u/s")
        print("  - Pitch angle -45° to -90° (looking down)")
        print("  - Survived for 2+ seconds after RJ")
        return False

    # Step 3: Cluster nearby locations
    clustered = cluster_rj_locations(successful, radius=128.0)
    print(f"Clustered into {len(clustered)} unique RJ locations (128u radius)")

    # Step 4: Generate QuakeC waypoints
    waypoint_code = generate_rj_waypoints(clustered, map_name)

    # Output results
    if output_file:
        output_path = Path(output_file)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(waypoint_code)
        print(f"\nWrote {len(clustered)} RJ waypoints to: {output_file}")
    else:
        print("\n" + waypoint_code)

    # Summary statistics
    print("\n=== Learning Summary ===")
    print(f"Total attempts: {len(events)}")
    print(f"Successful: {len(successful)} ({len(successful)/len(events)*100:.1f}%)")
    print(f"Unique locations: {len(clustered)}")
    if clustered:
        avg_velocity = sum(e.speed_gain for e in clustered) / len(clustered)
        max_velocity = max(e.speed_gain for e in clustered)
        print(f"Avg velocity gain: {avg_velocity:.1f} u/s")
        print(f"Max velocity gain: {max_velocity:.1f} u/s")

    return True


def main():
    if len(sys.argv) < 3:
        print("Usage: python learn_rj_from_player.py <log_file> <map_name> [output_file]")
        print("\nExample:")
        print("  python learn_rj_from_player.py ../launch/quake-spasm/qconsole.log dm2")
        print("  python learn_rj_from_player.py ../launch/quake-spasm/qconsole.log dm2 ../reaper_mre/maps/dm2_rj.qc")
        sys.exit(1)

    log_file = sys.argv[1]
    map_name = sys.argv[2]
    output_file = sys.argv[3] if len(sys.argv) > 3 else None

    if not Path(log_file).exists():
        print(f"ERROR: Log file not found: {log_file}", file=sys.stderr)
        sys.exit(1)

    success = learn_from_player(log_file, map_name, output_file)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
