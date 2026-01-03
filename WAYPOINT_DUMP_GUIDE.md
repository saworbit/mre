# Auto Waypoint Dump Guide

## Overview

The Auto Waypoint Dump system periodically saves bot navigation waypoints to the console during gameplay. This allows you to capture the learned pathfinding network for later use or analysis.

## How It Works

- Bots and players drop waypoint "breadcrumbs" as they move around maps
- The system can automatically dump these waypoints to the console at regular intervals
- Output is in QuakeC code format, ready to be compiled into static waypoints

## Quick Start

### 1. Enable Console Logging

Before launching the game, you need to enable console logging to capture the waypoint output:

**Option A: Command Line**
```bash
cd launch/quake-spasm
quakespasm.exe -condebug +map dm4 +waypoint_dump_interval 60
```

**Option B: In-Game Console**
```
con_logcenterprint 1        // Enable logging of bprint messages
log_file waypoints.txt      // Set log filename (engine-specific)
waypoint_dump_interval 60   // Dump waypoints every 60 seconds
```

### 2. Play the Game

- Let bots play for several minutes to build up waypoint coverage
- The system will automatically dump waypoints at your configured interval
- Watch for the dump messages in the console

### 3. Extract the Waypoints

After playing, open your console log file (usually `qconsole.log` or the file you specified):

Look for sections marked with:
```
======================================
AUTO WAYPOINT DUMP (123.45s)
======================================
// ===== CUT HERE: WAYPOINTS FOR THIS MAP =====
...waypoint data...
// ===== CUT HERE: END WAYPOINTS =====
// Total Nodes: 87
======================================
END AUTO DUMP
======================================
```

Copy everything between the `CUT HERE` markers.

## Configuration

### Console Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `waypoint_dump_interval` | 0 (disabled) | Seconds between auto dumps (0 = off, 60 = every 60s) |

### Recommended Settings

**For Training Runs (Learning New Maps):**
```
waypoint_dump_interval 120  // Dump every 2 minutes
```

**For Quick Tests:**
```
waypoint_dump_interval 30   // Dump every 30 seconds
```

**To Disable:**
```
waypoint_dump_interval 0    // Turn off auto dumping
```

## Manual Dump (Alternative)

If you don't want automatic dumps, you can manually trigger a waypoint dump via console command or impulse (if implemented). Currently, the automatic system is the primary method.

## Output Format

The dumped waypoints are in QuakeC format:
```c
// Node 0: DROPPED (regular floor waypoint)
node = spawn();
node.origin = '1234.5 678.9 -42.0';
node.classname = "BotPath";
node.pathtype = DROPPED;
// ... linking logic ...
```

This can be compiled into a map-specific waypoint file to provide pre-baked navigation.

## Tips

1. **Let it Run**: The longer bots/players explore, the better coverage you get
2. **Multiple Dumps**: Later dumps contain more nodes as the network grows
3. **Console Buffer**: Some engines have limited console buffers - use `con_logcenterprint 1` to ensure capture
4. **File Size**: Large maps can generate thousands of waypoints - plan accordingly

## Troubleshooting

**"I don't see any dumps!"**
- Check that `waypoint_dump_interval` is > 0
- Verify console logging is enabled (`con_logcenterprint 1`)
- Make sure the map has loaded and bots are active

**"The console output is truncated!"**
- Enable file logging with `-condebug` launch flag
- Check your Quake engine's console buffer size settings

**"Too many dumps filling my console!"**
- Increase the interval: `waypoint_dump_interval 300` (5 minutes)
- Or disable: `waypoint_dump_interval 0`

## Advanced: Compiling Static Waypoints

Once you have a good waypoint dump:

1. Extract the waypoint code from the console log
2. Create a new file: `reaper_mre/waypoints_dm4.qc` (or your map name)
3. Paste the extracted code
4. Add initialization logic to spawn these nodes on map load
5. Include the file in `progs.src`
6. Recompile

This gives you instant pathfinding without needing to learn the map each time.

## Example Session

```bash
# Launch with auto dump every 60 seconds
quakespasm.exe -condebug +map dm4 +deathmatch 1 +waypoint_dump_interval 60

# In console (optional tweaks):
impulse 100        // Spawn bots
wait 300           // Let them play for 5 minutes
quit               // Exit

# Check qconsole.log for dump output
```

## See Also

- `botroute.qc` - Contains the `DumpWaypoints()` function
- `world.qc` - Contains the auto dump logic in `StartFrame()`
- `CHANGELOG.md` - Full feature history
