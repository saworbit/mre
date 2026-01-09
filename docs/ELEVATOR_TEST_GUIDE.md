# Elevator System Test Guide

**Date**: 2026-01-07
**Build**: 496,890 bytes

---

## Quick Test (5 minutes)

### Step 1: Load DM4
```
map dm4
```
**Why DM4?**
- Has 452 pre-loaded waypoints (bots can navigate)
- Has Yellow Armor elevator (func_plat at coords ~1792, 384, -168)
- Has complete waypoint coverage

### Step 2: Spawn Bots
```
impulse 100    (spawns 8 bots)
```

### Step 3: Enable Debug Logging
```
impulse 95     (enable bot debug)
impulse 96     (cycle to LOG_TACTICAL - shows elevator events)
```

### Step 4: Watch Console
Look for these messages:
```
[BotName] ELEVATOR: Waiting at '1792.0 384.0 -168.0'
[BotName] ELEVATOR: Boarding (waited 2.5s)
[BotName] ELEVATOR: Aboard, riding to top (waited 2.5s)
```

**OR** (if platform at top when bot arrives):
```
A*: Elevator blocked at '...' (platform at top)
[BotName] A*: Path found via stairs (alternate route)
```

---

## Expected Behavior

### Scenario A: Platform at Bottom
1. Bot pathfinds to Yellow Armor (on upper platform)
2. A* finds path through elevator (platform present)
3. Bot walks to elevator entrance
4. **No wait needed** - platform already there
5. Bot boards elevator
6. Console: `[Bot] ELEVATOR: Boarding (waited 0.0s)`
7. Bot rides to top
8. Bot exits at upper level
9. Bot gets Yellow Armor

### Scenario B: Platform at Top
1. Bot pathfinds to Yellow Armor
2. A* checks elevator entrance → Platform absent
3. **A* SKIPS elevator path** (this is the key feature!)
4. A* finds alternate route (stairs/ramps)
5. Bot takes alternate route
6. Console: `A*: Elevator blocked at '...' (platform at top)`
7. Bot reaches Yellow Armor via alternate path

### Scenario C: Bot Waits for Elevator
1. Manually route bot to elevator (set goal nearby)
2. Platform starts at top
3. Bot reaches elevator entrance
4. Platform absent → Enter wait state
5. Console: `[Bot] ELEVATOR: Waiting at '...'`
6. **Bot stops moving** (velocity = 0)
7. **Bot looks up** (pitch = -45°)
8. Stuck timers reset (no panic teleport)
9. **Call elevator** (player triggers it or wait for timeout)
10. Platform descends to bottom
11. Console: `[Bot] ELEVATOR: Boarding (waited 5.2s)`
12. Bot boards and rides to top

### Scenario D: Timeout
1. Bot waits at elevator entrance
2. Platform never comes
3. After **30 seconds**:
   - Console: `[Bot] ELEVATOR: Timeout (30.1s), replanning`
   - Bot abandons elevator
   - A* finds alternate route
   - Bot takes stairs/ramps instead

---

## Current Map Compatibility

| Map | Waypoints | Elevators | Status |
|-----|-----------|-----------|--------|
| **DM4** | ✅ 452 | ✅ Yellow Armor | **USE THIS** |
| **DM2** | ✅ 362 | ⚠️ None | Navigation works, no elevators |
| **E1M1** | ❌ None | ✅ Quad elevator | Can't test (no waypoints) |
| **E1M2** | ❌ None | ✅ Multiple | Can't test (no waypoints) |
| **DM3** | ❌ None | ❌ None | Can't test (no waypoints, no elevators) |

---

## Why E1M1 Didn't Work

**Problem**: E1M1 has no waypoint file
**Result**: Game loads, but bots can't navigate
**What happens**:
1. Map loads: ✅
2. Server spawns: ✅
3. Client connects: ✅
4. **No waypoints load** (only dm4/dm2 have LoadMapWaypoints)
5. Bots spawn but have no navigation graph
6. Bots just stand still or wander randomly
7. **Looks like game hung** (but it's just bots doing nothing)

**Solution**: Use DM4 instead

---

## Why DM3 Showed No Elevator Activity

**Problem**: DM3 has no elevators!
**Map**: "The Abandoned Base" - lava-themed arena
**Entities**: No func_plat or func_train
**Result**: Bots can't go to elevators because there aren't any

**Also**: DM3 has no waypoints, so bots couldn't navigate anyway

---

## Advanced Testing: Auto Node Creation

**Goal**: Test self-learning elevator node creation

### Step 1: Delete Elevator Waypoints
Currently, DM4 waypoints include elevator nodes. To test auto-creation:
1. Edit `maps/dm4.qc`
2. Find waypoints near elevator (~1792, 384, -168)
3. Comment them out
4. Recompile and deploy

### Step 2: Let Bots Explore
1. Enable LOG_VERBOSE: `impulse 96` (cycle twice from LOG_TACTICAL)
2. Spawn bots: `impulse 100`
3. Watch console for:
```
ELEVATOR: Created WAIT_NODE at '1792.0 384.0 -168.0'
ELEVATOR: Created EXIT_NODE at '1792.0 384.0 -88.0'
```

### Step 3: Verify Auto-Creation
1. Run `impulse 100` (DumpWaypoints) - **WARNING: Spams console!**
2. Look for elevator nodes in output:
```
SpawnSavedWaypoint('1792.0 384.0 -168.0', 0.1, 0, "", NODE_WAIT, "plat_name")
SpawnSavedWaypoint('1792.0 384.0 -88.0', 0.1, 0, "", NODE_EXIT, "plat_name")
```

---

## Troubleshooting

### "Bot debug enabled but no ELEVATOR messages"
**Cause**: Bots aren't using elevator (either platform present or alternate route used)
**Fix**:
- Verify elevator exists: `noclip` then fly to coords ~1792, 384
- Check if Yellow Armor is goal (bots need reason to go there)
- Try placing Quad on upper platform to lure bots

### "Bots walk into empty shaft"
**Cause**: Waypoint doesn't have `node_type = NODE_WAIT` set
**Fix**:
- Check if waypoint has proper node_type
- Or let bots auto-create nodes (remove manual waypoints near elevator)

### "Bots wait forever at elevator"
**Cause**: Platform broken (stuck at top)
**Fix**:
- Check platform entity (should cycle pos1 ↔ pos2)
- Verify timeout triggers after 30s (check console)

### "Game hangs on E1M1/DM3"
**Cause**: No waypoints = no bot navigation
**Fix**: **Use DM4** instead (has waypoints)

---

## Console Command Reference

```
map dm4                 // Load DM4 (has waypoints + elevator)
impulse 100             // Spawn 8 bots
impulse 95              // Toggle bot debug logging
impulse 96              // Cycle verbosity (CRITICAL → TACTICAL → VERBOSE)
noclip                  // Fly around to inspect elevator
notarget                // Bots ignore you (easier observation)
god                     // Don't die while testing
```

---

## Expected Console Output (Success)

**Elevator Wait + Boarding**:
```
[Assmunch] GOAL: item_armor2 (score=5168.0, dist=832.0u)
[Assmunch] ELEVATOR: Waiting at '1792.0 384.0 -168.0'
(2.3 seconds pass - platform descends)
[Assmunch] ELEVATOR: Boarding (waited 2.3s)
[Assmunch] ELEVATOR: Aboard, riding to top (waited 2.3s)
[Assmunch] GOAL: item_armor2 reached
```

**A* Elevator Blocking**:
```
[Cheater] GOAL: item_armor2 (score=4555.9, dist=944.1u)
A*: Elevator blocked at '1792.0 384.0 -168.0' (platform at top)
[Cheater] A*: Path found via ramp (12 nodes)
(Bot takes stairs instead)
[Cheater] GOAL: item_armor2 reached
```

**Timeout**:
```
[Wanton] ELEVATOR: Waiting at '1792.0 384.0 -168.0'
(30 seconds pass - platform never comes)
[Wanton] ELEVATOR: Timeout (30.1s), replanning
[Wanton] A*: Path found via ramp (12 nodes)
```

---

## File Locations

- **Test Map**: `c:\reaperai\launch\quake-spasm\id1\maps\dm4.bsp`
- **Waypoints**: `c:\reaperai\reaper_mre\maps\dm4.qc` (LoadMapWaypoints_dm4)
- **Console Log**: `c:\reaperai\launch\quake-spasm\qconsole.log`
- **Elevator Code**:
  - Detection: `botroute.qc:1100-1183`
  - A* Integration: `botroute.qc:1285-1602`
  - Wait State: `botmove.qc:2098-2219`
  - Boarding: `botthink.qc:556-576`
  - Auto-Creation: `botroute.qc:600-738`

---

## Next Steps

1. ✅ **Load DM4** and spawn bots
2. ✅ **Enable LOG_TACTICAL** debug logging
3. ✅ **Watch for elevator messages** in console
4. ⏸️ **Observe bot behavior** around Yellow Armor elevator
5. ⏸️ **Test timeout** (prevent elevator from descending)
6. ⏸️ **Test auto-creation** (delete elevator waypoints)

---

**Last Updated**: 2026-01-07
**Build**: 496,890 bytes
**Recommended Map**: DM4 (has waypoints + elevator)
