# Bot Memory Manager

**Automated waypoint persistence system for Modern Reaper Enhancements (MRE)**

Extracts bot learning data from matches and generates production-ready QuakeC code.

## Quick Start

### 1. Play a Match
```
cd launch\quake-spasm
launch_reaper_mre.bat 8 dm4
```

Play for 5-10 minutes. At the end, type in console:
```
impulse 100
quit
```

### 2. Run Auto-Pipeline
```
cd tools
python bot_memory_manager.py auto
```

This will:
- ✅ Extract waypoints from `qconsole.log`
- ✅ Merge with existing data (if any)
- ✅ Optimize and clean up low-value nodes
- ✅ Generate `reaper_mre/maps/dm4_memory.qc`
- ✅ Show statistics and top routes

### 3. Integrate into Build

Add to `reaper_mre/progs.src` (before `botroute.qc`):
```
maps/dm4_memory.qc
```

Add to `reaper_mre/world.qc` in `worldspawn()`:
```qc
if (mapname == "dm4")
{
   Loaddm4Memory();  // Restore learned experience
}
```

### 4. Recompile
```
cd reaper_mre
..\tools\fteqcc_win64\fteqcc64.exe -O3 progs.src
```

Bots now start with "memories" of popular routes and danger zones!

## Commands

### Auto Pipeline (Recommended)
```bash
python bot_memory_manager.py auto
```
Runs complete extraction → merge → optimize → generate workflow.

### Manual Extraction
```bash
python bot_memory_manager.py extract
```
Extracts from log and saves to `bot_memory/mapname.json`.

### View Statistics
```bash
python bot_memory_manager.py stats dm4
```
Show analysis of saved waypoint data.

## How It Works

### Extraction
Parses `qconsole.log` for waypoint dumps (from `impulse 100` command).

### Merging
Combines new session data with historical data:
- Matches waypoints by proximity (32-unit grid)
- Weighted average: 60% historical + 40% new session
- Tracks sessions_seen counter for veteran nodes

### Optimization
- Removes low-value nodes (traffic < 5 AND danger < 2)
- Normalizes scores to 0-100 range (prevents inflation)
- Prevents memory bloat over many sessions

### Generation
Creates clean `.qc` file with:
- High-traffic routes listed first (top 10)
- Comprehensive statistics in header
- Ready-to-compile QuakeC function

## Data Format

### JSON Storage (`bot_memory/dm4.json`)
```json
{
  "map": "dm4",
  "last_updated": "2026-01-04T16:30:00",
  "total_nodes": 127,
  "nodes": [
    {
      "origin": [-272, 160, -152],
      "traffic_score": 45.3,
      "danger_scent": 12.1,
      "last_updated": "2026-01-04T16:30:00",
      "sessions_seen": 3
    }
  ]
}
```

### QuakeC Output (`maps/dm4_memory.qc`)
```qc
void() Loaddm4Memory =
{
    // === HIGH TRAFFIC ROUTES (Top 10) ===
    SpawnSavedWaypoint('-272 160 -152', 45.3, 12.1);
    SpawnSavedWaypoint('128 -64 24', 89.2, 67.4);
    // ... more nodes
};
```

## Multi-Session Learning

The system **accumulates knowledge** across matches:

**Session 1** (Fresh start):
```
Total: 85 nodes
Avg Traffic: 12.3
Avg Danger: 8.7
```

**Session 5** (Learned patterns):
```
Total: 127 nodes (+42 new routes discovered)
Avg Traffic: 34.5 (highways emerging)
Avg Danger: 18.2 (danger zones identified)
Veteran nodes: 63 (seen in 2+ sessions)
```

**Session 10** (Expert level):
```
Total: 134 nodes (stabilized)
Avg Traffic: 56.8 (clear highways)
Avg Danger: 31.4 (death traps confirmed)
Veteran nodes: 98 (battle-tested routes)
```

## Tips

### Best Practices
1. **Play full matches** (5-10 min) before dumping waypoints
2. **Run auto-pipeline after every session** to accumulate data
3. **Commit `.qc files`** to git for version control
4. **Share map memories** with the community

### Troubleshooting

**"No waypoint dumps found"**
- Make sure you ran `impulse 100` before quitting
- Check `qconsole.log` exists in `launch/quake-spasm/`

**"Low node count"**
- Bots need time to explore the map
- Play on skill 3 for better pathfinding
- Increase match length

**"Scores too high/low"**
- Optimization normalizes to 0-100 range automatically
- If still off, delete `bot_memory/mapname.json` to reset

## Advanced Usage

### Batch Processing Multiple Maps
```bash
# Play dm2, dump waypoints, quit
# Play dm3, dump waypoints, quit
# Play dm4, dump waypoints, quit

python bot_memory_manager.py auto  # Processes all maps at once
```

### Resetting a Map's Memory
```bash
rm bot_memory/dm4.json
rm reaper_mre/maps/dm4_memory.qc
```

### Exporting for Distribution
```bash
# Share your learned map data
zip dm4_botmemory.zip reaper_mre/maps/dm4_memory.qc bot_memory/dm4.json
```

## File Locations

```
reaperai/
├── tools/
│   ├── bot_memory_manager.py      # Main script
│   └── BOT_MEMORY_README.md       # This file
├── bot_memory/                     # JSON backups
│   ├── dm2.json
│   ├── dm3.json
│   └── dm4.json
├── reaper_mre/
│   └── maps/                       # Generated QC files
│       ├── dm2_memory.qc
│       ├── dm3_memory.qc
│       └── dm4_memory.qc
└── launch/quake-spasm/
    └── qconsole.log               # Source data
```

## Requirements

- Python 3.7+ (no external dependencies!)
- QuakeSpasm engine
- MRE mod compiled with Phase 5 waypoint enhancements

---

**Created for Modern Reaper Enhancements - Phase 5: Persistent Bot Memory**
