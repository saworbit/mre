#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Bot Memory Manager - Automated Waypoint Persistence System
Modern Reaper Enhancements (MRE) - Phase 5 Tool

Extracts, analyzes, optimizes, and persists bot learning data from Quake matches.
Converts qconsole.log dumps into production-ready QuakeC code.

Usage:
    python bot_memory_manager.py extract    # Extract from latest log
    python bot_memory_manager.py merge      # Merge with existing data
    python bot_memory_manager.py optimize   # Clean up and optimize
    python bot_memory_manager.py generate   # Create .qc files
    python bot_memory_manager.py auto       # Run full pipeline
"""

import re
import json
import os
import sys
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass, asdict
from collections import defaultdict

# Fix Windows console encoding for UTF-8
if sys.platform == 'win32':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except:
        pass  # Fallback: use ASCII symbols


@dataclass
class WaypointNode:
    """Represents a single waypoint with learning data"""
    origin: Tuple[float, float, float]
    traffic_score: float
    danger_scent: float
    last_updated: str
    sessions_seen: int = 1

    def to_qc(self) -> str:
        """Generate QuakeC spawn call"""
        origin_str = f"'{self.origin[0]} {self.origin[1]} {self.origin[2]}'"
        return f"    SpawnSavedWaypoint({origin_str}, {self.traffic_score:.1f}, {self.danger_scent:.1f});"


class BotMemoryManager:
    """Manages bot memory extraction, analysis, and optimization"""

    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.log_path = project_root / "launch" / "quake-spasm" / "qconsole.log"
        self.memory_dir = project_root / "bot_memory"
        self.memory_dir.mkdir(exist_ok=True)

    def extract_from_log(self) -> Optional[Dict[str, List[WaypointNode]]]:
        """Extract waypoint data from qconsole.log"""
        print("📖 Reading qconsole.log...")

        if not self.log_path.exists():
            print(f"❌ Log file not found: {self.log_path}")
            return None

        with open(self.log_path, 'r', encoding='utf-8', errors='ignore') as f:
            log_content = f.read()

        # Find all waypoint dump sections
        dump_pattern = r'// ===== CUT HERE: START WAYPOINTS =====(.+?)// ===== CUT HERE: END WAYPOINTS ====='
        dumps = re.findall(dump_pattern, log_content, re.DOTALL)

        if not dumps:
            print("⚠️  No waypoint dumps found in log. Use 'impulse 100' in-game to dump waypoints.")
            return None

        print(f"✅ Found {len(dumps)} waypoint dump(s)")

        # Extract map name from log
        map_match = re.search(r'SpawnServer: (\w+)', log_content)
        mapname = map_match.group(1) if map_match else "unknown"

        # Parse the most recent dump (last one in log)
        latest_dump = dumps[-1]
        nodes = self._parse_waypoint_dump(latest_dump)

        print(f"📊 Extracted {len(nodes)} waypoints from map '{mapname}'")

        return {mapname: nodes}

    def _parse_waypoint_dump(self, dump_text: str) -> List[WaypointNode]:
        """Parse waypoint spawn calls from dump text"""
        nodes = []

        # Match: SpawnSavedWaypoint('X Y Z', traffic, danger);
        pattern = r"SpawnSavedWaypoint\('([^']+)',\s*([\d.]+),\s*([\d.]+)\)"

        for match in re.finditer(pattern, dump_text):
            origin_str, traffic, danger = match.groups()
            x, y, z = map(float, origin_str.split())

            nodes.append(WaypointNode(
                origin=(x, y, z),
                traffic_score=float(traffic),
                danger_scent=float(danger),
                last_updated=datetime.now().isoformat()
            ))

        return nodes

    def save_memory(self, map_data: Dict[str, List[WaypointNode]]):
        """Save extracted waypoints to JSON"""
        for mapname, nodes in map_data.items():
            memory_file = self.memory_dir / f"{mapname}.json"

            data = {
                "map": mapname,
                "last_updated": datetime.now().isoformat(),
                "total_nodes": len(nodes),
                "nodes": [asdict(node) for node in nodes]
            }

            with open(memory_file, 'w') as f:
                json.dump(data, f, indent=2)

            print(f"💾 Saved {len(nodes)} nodes to {memory_file.name}")

    def load_memory(self, mapname: str) -> List[WaypointNode]:
        """Load existing waypoint data for a map"""
        memory_file = self.memory_dir / f"{mapname}.json"

        if not memory_file.exists():
            return []

        with open(memory_file, 'r') as f:
            data = json.load(f)

        nodes = [
            WaypointNode(
                origin=tuple(n['origin']),
                traffic_score=n['traffic_score'],
                danger_scent=n['danger_scent'],
                last_updated=n['last_updated'],
                sessions_seen=n.get('sessions_seen', 1)
            )
            for n in data['nodes']
        ]

        print(f"📂 Loaded {len(nodes)} existing nodes for {mapname}")
        return nodes

    def merge_nodes(self, old_nodes: List[WaypointNode], new_nodes: List[WaypointNode]) -> List[WaypointNode]:
        """Merge old and new waypoints with intelligent averaging"""
        print("🔀 Merging waypoint data...")

        # Create spatial index for matching (within 16 units = same node)
        MERGE_THRESHOLD = 16.0
        merged = {}

        # Add old nodes to index
        for node in old_nodes:
            key = self._spatial_key(node.origin)
            merged[key] = node

        # Merge or add new nodes
        for new_node in new_nodes:
            key = self._spatial_key(new_node.origin)

            if key in merged:
                # Merge: weighted average favoring recent data
                old = merged[key]
                weight_old = 0.6  # Give 60% weight to historical data
                weight_new = 0.4  # 40% to new session

                merged[key] = WaypointNode(
                    origin=new_node.origin,  # Use more recent position
                    traffic_score=old.traffic_score * weight_old + new_node.traffic_score * weight_new,
                    danger_scent=old.danger_scent * weight_old + new_node.danger_scent * weight_new,
                    last_updated=datetime.now().isoformat(),
                    sessions_seen=old.sessions_seen + 1
                )
            else:
                # New node
                merged[key] = new_node

        result = list(merged.values())
        print(f"✅ Merged to {len(result)} nodes ({len(old_nodes)} old + {len(new_nodes)} new)")
        return result

    def _spatial_key(self, origin: Tuple[float, float, float]) -> Tuple[int, int, int]:
        """Create spatial hash key for node proximity matching"""
        GRID_SIZE = 32  # 32-unit grid cells
        return (
            int(origin[0] // GRID_SIZE),
            int(origin[1] // GRID_SIZE),
            int(origin[2] // GRID_SIZE)
        )

    def optimize_nodes(self, nodes: List[WaypointNode]) -> List[WaypointNode]:
        """Optimize waypoint set by removing low-value nodes"""
        print("⚙️  Optimizing waypoint data...")

        initial_count = len(nodes)

        # Remove nodes with very low traffic AND low danger (not useful)
        MIN_TRAFFIC = 5.0
        MIN_DANGER = 2.0

        optimized = [
            node for node in nodes
            if node.traffic_score >= MIN_TRAFFIC or node.danger_scent >= MIN_DANGER
        ]

        # Normalize scores to prevent inflation over many sessions
        if optimized:
            max_traffic = max(n.traffic_score for n in optimized)
            max_danger = max(n.danger_scent for n in optimized)

            # Scale to 0-100 range
            for node in optimized:
                if max_traffic > 0:
                    node.traffic_score = (node.traffic_score / max_traffic) * 100
                if max_danger > 0:
                    node.danger_scent = (node.danger_scent / max_danger) * 100

        removed = initial_count - len(optimized)
        print(f"🗑️  Removed {removed} low-value nodes ({len(optimized)} remain)")

        return optimized

    def generate_qc_file(self, mapname: str, nodes: List[WaypointNode]) -> Path:
        """Generate production-ready QuakeC file"""
        print(f"📝 Generating QuakeC code for {mapname}...")

        # Calculate statistics
        avg_traffic = sum(n.traffic_score for n in nodes) / len(nodes) if nodes else 0
        avg_danger = sum(n.danger_scent for n in nodes) / len(nodes) if nodes else 0

        # Sort by traffic (highways first) for better readability
        sorted_nodes = sorted(nodes, key=lambda n: n.traffic_score, reverse=True)

        # Generate file content
        output = []
        output.append("// ===== AUTO-GENERATED BOT MEMORY =====")
        output.append(f"// Map: {mapname}")
        output.append(f"// Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        output.append(f"// Total Nodes: {len(nodes)}")
        output.append(f"// Avg Traffic: {avg_traffic:.1f}")
        output.append(f"// Avg Danger: {avg_danger:.1f}")
        output.append("// Format: SpawnSavedWaypoint(origin, traffic_score, danger_scent)")
        output.append("")
        output.append(f"void() Load{mapname.upper()}Memory =")
        output.append("{")

        # High-traffic nodes first (top 10)
        if len(sorted_nodes) > 10:
            output.append("    // === HIGH TRAFFIC ROUTES (Top 10) ===")
            for node in sorted_nodes[:10]:
                output.append(node.to_qc())
            output.append("")
            output.append("    // === REMAINING NODES ===")
            for node in sorted_nodes[10:]:
                output.append(node.to_qc())
        else:
            for node in sorted_nodes:
                output.append(node.to_qc())

        output.append("};")
        output.append("// ===== END AUTO-GENERATED =====")

        # Write to reaper_mre/maps/ directory
        maps_dir = self.project_root / "reaper_mre" / "maps"
        maps_dir.mkdir(exist_ok=True)

        qc_file = maps_dir / f"{mapname}_memory.qc"
        with open(qc_file, 'w') as f:
            f.write('\n'.join(output))

        print(f"✅ Generated {qc_file.name} ({len(nodes)} nodes)")
        return qc_file

    def print_stats(self, mapname: str, nodes: List[WaypointNode]):
        """Print analysis statistics"""
        if not nodes:
            return

        print(f"\n📊 STATISTICS FOR {mapname.upper()}")
        print("=" * 50)
        print(f"Total Waypoints: {len(nodes)}")
        print(f"Avg Traffic Score: {sum(n.traffic_score for n in nodes) / len(nodes):.1f}")
        print(f"Avg Danger Scent: {sum(n.danger_scent for n in nodes) / len(nodes):.1f}")

        # Top 5 highways
        by_traffic = sorted(nodes, key=lambda n: n.traffic_score, reverse=True)[:5]
        print("\n🛣️  TOP 5 HIGHWAYS (Most Traveled):")
        for i, node in enumerate(by_traffic, 1):
            print(f"  {i}. Traffic: {node.traffic_score:5.1f} at {node.origin}")

        # Top 5 danger zones
        by_danger = sorted(nodes, key=lambda n: n.danger_scent, reverse=True)[:5]
        print("\n☠️  TOP 5 DANGER ZONES (Most Deaths):")
        for i, node in enumerate(by_danger, 1):
            print(f"  {i}. Danger: {node.danger_scent:5.1f} at {node.origin}")

        # Multi-session nodes
        veteran_nodes = [n for n in nodes if n.sessions_seen > 1]
        if veteran_nodes:
            print(f"\n🎖️  VETERAN NODES: {len(veteran_nodes)} nodes seen in multiple sessions")
            max_sessions = max(n.sessions_seen for n in veteran_nodes)
            print(f"   Max sessions: {max_sessions}")

        print("=" * 50)

    def run_auto_pipeline(self):
        """Run complete extraction → merge → optimize → generate pipeline"""
        print("\n🚀 STARTING AUTOMATED BOT MEMORY PIPELINE")
        print("=" * 60)

        # Step 1: Extract
        extracted = self.extract_from_log()
        if not extracted:
            print("❌ No data to process. Run 'impulse 100' in-game first.")
            return

        for mapname, new_nodes in extracted.items():
            print(f"\n📍 Processing map: {mapname}")

            # Step 2: Load existing
            old_nodes = self.load_memory(mapname)

            # Step 3: Merge
            if old_nodes:
                merged = self.merge_nodes(old_nodes, new_nodes)
            else:
                merged = new_nodes
                print("🆕 First-time extraction (no existing data)")

            # Step 4: Optimize
            optimized = self.optimize_nodes(merged)

            # Step 5: Save
            self.save_memory({mapname: optimized})

            # Step 6: Generate QC
            qc_file = self.generate_qc_file(mapname, optimized)

            # Step 7: Stats
            self.print_stats(mapname, optimized)

            print(f"\n✅ PIPELINE COMPLETE FOR {mapname}")
            print(f"📁 QuakeC file: {qc_file}")
            print(f"📁 JSON backup: {self.memory_dir / f'{mapname}.json'}")
            print("\nNext steps:")
            print(f"  1. Add to progs.src: maps/{mapname}_memory.qc")
            print(f"  2. Call from worldspawn: if (mapname == \"{mapname}\") Load{mapname.upper()}Memory();")
            print(f"  3. Recompile and test!")


def main():
    """CLI entry point"""
    if len(sys.argv) < 2:
        print(__doc__)
        return

    command = sys.argv[1].lower()
    project_root = Path(__file__).parent.parent  # tools/ -> root

    manager = BotMemoryManager(project_root)

    if command == "auto":
        manager.run_auto_pipeline()
    elif command == "extract":
        data = manager.extract_from_log()
        if data:
            manager.save_memory(data)
    elif command == "stats":
        mapname = sys.argv[2] if len(sys.argv) > 2 else "dm4"
        nodes = manager.load_memory(mapname)
        manager.print_stats(mapname, nodes)
    else:
        print(f"Unknown command: {command}")
        print("Use: auto, extract, or stats")


if __name__ == "__main__":
    main()
