# Elevator Navigation System - Complete Documentation

**Build Version**: 496,890 bytes
**Implementation Date**: 2026-01-07
**System Type**: Obot-style Two-Node Elevator Navigation
**Code Impact**: +3,896 bytes (+0.8% of total codebase)

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Implementation Details](#implementation-details)
4. [Usage Guide](#usage-guide)
5. [Testing](#testing)
6. [API Reference](#api-reference)
7. [Troubleshooting](#troubleshooting)

---

## Overview

### The Problem

**Before Elevator System**:
- Bots pathfind through elevator shafts regardless of platform position
- A* treats elevator waypoints as always reachable
- Bots walk into empty shafts, fall into pits, take damage
- Reactive "Elevator Patience" logic only activates after bot arrives at shaft

**Example Failure Scenario**:
```
Platform at TOP:
┌─────────┐ ← Platform here (pos2)
│  Item   │ ← Goal waypoint
└─────────┘
     │
     │  200 units (empty shaft)
     │
     ▼
  Bot here ← Bottom waypoint
           (bot walks in, falls into pit)
```

### The Solution

**Obot-Style Two-Node Elevator System**:
- **WAIT_NODE** (bottom): Conditional connection - only traversable when platform present
- **EXIT_NODE** (top): Destination waypoint
- **Dynamic A* traversal**: Checks platform presence BEFORE pathfinding through elevator
- **Proactive waiting**: Bots wait patiently at safe position when platform absent
- **Self-learning**: Bots auto-create elevator node pairs as they explore

**Result**:
```
Platform at TOP:
A* pathfinding:
  "Is platform at WAIT_NODE?" → NO
  → Skip elevator path, find alternate route (stairs/teleporter)

Platform at BOTTOM:
A* pathfinding:
  "Is platform at WAIT_NODE?" → YES
  → Include elevator path in search
  → Bot boards elevator, rides to top
```

---

## Architecture

### Core Components

#### 1. Entity Fields ([botit_th.qc:175-192](c:\reaperai\reaper_mre\botit_th.qc#L175-L192))

**Waypoint Node Fields**:
```qc
.float node_type;              // NODE_STANDARD (0), NODE_WAIT (1), NODE_EXIT (2)
.entity platform_entity;       // Link to func_plat/func_train
.vector platform_wait_pos;     // Where to stand while waiting (pos1)
.vector platform_board_pos;    // Where platform is boardable (pos1)
.entity wait_node_pair;        // Link to paired node (WAIT ↔ EXIT)
```

**Bot State Fields**:
```qc
.float elevator_wait_state;    // TRUE when waiting for elevator
.entity elevator_wait_node;    // Which WAIT_NODE we're waiting at
.float elevator_wait_start;    // Timestamp for timeout detection
```

**Constants**:
```qc
// Node types
float NODE_STANDARD   = 0;     // Normal waypoint
float NODE_WAIT       = 1;     // Elevator wait node (bottom)
float NODE_EXIT       = 2;     // Elevator exit node (top)

// Platform states (from plats.qc)
float STATE_TOP       = 0;     // At top position
float STATE_BOTTOM    = 1;     // At bottom position
float STATE_UP        = 2;     // Moving to top
float STATE_DOWN      = 3;     // Moving to bottom
```

#### 2. Platform Detection ([botroute.qc:1100-1183](c:\reaperai\reaper_mre\botroute.qc#L1100-L1183))

**IsPlatformAt(entity plat, vector target_pos)**
- Checks if platform is at specific position (within 32 units)
- Returns: TRUE if platform present, FALSE otherwise
- Used by: A* pathfinding, wait state logic, auto node creation

**CanTraverseElevator(entity wait_node)**
- Validates if WAIT_NODE is traversable right now
- Checks:
  1. Is platform at bottom position? → YES (traversable)
  2. Is platform descending (STATE_DOWN)? → YES (will arrive soon)
  3. Otherwise → NO (find alternate route)
- Returns: TRUE if traversable, FALSE if blocked
- Used by: A* neighbor processing (6 locations)

**FindElevatorNode(vector pos, float radius)**
- Locates elevator nodes near a position
- Searches for NODE_WAIT or NODE_EXIT within radius
- Returns: Closest elevator node, or world if none found
- Used by: Auto node creation, node pair linking

#### 3. A* Pathfinding Integration ([botroute.qc:1285-1602](c:\reaperai\reaper_mre\botroute.qc#L1285-L1602))

**Elevator Check Pattern** (repeated for movetarget1-6):
```qc
neighbor = lowest.movetarget;
if (neighbor) {
    // ===== ELEVATOR SYSTEM: Dynamic Traversal Check =====
    if (neighbor.node_type == NODE_WAIT) {
        if (!CanTraverseElevator(neighbor)) {
            neighbor = world;  // Skip this neighbor
        }
    }
    // ===== END ELEVATOR SYSTEM =====
}

if (neighbor) {
    // Process neighbor normally (edge cost, etc.)
}
```

**Behavior**:
- A* evaluates each neighbor before adding to open set
- If neighbor is WAIT_NODE and platform absent → Skip (treat as wall)
- A* automatically finds alternate routes (stairs, teleporters, other paths)
- No performance penalty when platform present

#### 4. Wait State Management ([botmove.qc:2098-2219](c:\reaperai\reaper_mre\botmove.qc#L2098-L2219))

**When bot arrives at WAIT_NODE**:
1. **Platform present?** → Proceed normally (board elevator)
2. **Platform absent?** → Enter wait state:
   - Initialize: `elevator_wait_state = TRUE`, record start time
   - Stop movement: `velocity = '0 0 0'`
   - Look up: `ideal_pitch = -45°` (human-like behavior)
   - Reset stuck timers: `stuck_count = 0` (intentional wait, not stuck)
   - Monitor platform: Check every frame if platform arrived
   - Timeout: 30 seconds -> replan route (find alternate path) and mark the wait node as a temporary bad spot (15s) to avoid immediate reselect

**Platform arrives**:
- Reset wait state: `elevator_wait_state = FALSE`
- Log boarding: "ELEVATOR: Boarding (waited X.Xs)"
- Proceed with normal movement (board platform)

**Legacy Compatibility**:
- Fallback for old `is_platform_node` waypoints (no node_type set)
- Uses height-based detection (node >64u above bot = platform at top)
- Will be phased out as maps migrate to NODE_WAIT/NODE_EXIT system

#### 5. Boarding Confirmation ([botthink.qc:556-576](c:\reaperai\reaper_mre\botthink.qc#L556-L576))

**Enhanced "Ride Platform Auto-Follow"**:
```qc
traceline(self.origin - '0 0 32', self.origin, TRUE, self);
if (trace_ent && (trace_ent.classname == "func_plat" || trace_ent.classname == "func_train")) {
    // Inherit platform velocity (smooth ride)
    self.velocity = self.velocity + trace_ent.velocity;
    self.flags = self.flags | FL_ONGROUND;

    // NEW: Boarding confirmation
    if (self.elevator_wait_state) {
        self.elevator_wait_state = FALSE;
        // Log: "ELEVATOR: Aboard, riding to top (waited X.Xs)"
    }
}
```

**Behavior**:
- Detects when bot successfully boards platform (downward trace)
- Confirms transition from waiting → riding
- Inherits platform velocity (prevents sliding off)
- Maintains FL_ONGROUND flag for stability

#### 6. Auto Node Creation ([botroute.qc:600-738](c:\reaperai\reaper_mre\botroute.qc#L600-L738))

**Self-Learning Elevator Mapping**:

When bot drops breadcrumb on `func_plat`:
1. Detect position: At bottom (pos1) or top (pos2)?
2. **At bottom**:
   - Create WAIT_NODE at current position (or use existing)
   - Create EXIT_NODE at top position (or use existing)
   - Link pair: `wait_node.wait_node_pair = exit_node`
   - Connect graph: `wait_node.movetarget = exit_node`
3. **At top**:
   - Create EXIT_NODE at current position (or use existing)
   - Create WAIT_NODE at bottom position (or use existing)
   - Link pair bidirectionally
   - Connect graph

**Properties of auto-created nodes**:
```qc
wait_node.node_type = NODE_WAIT;
wait_node.platform_entity = plat;
wait_node.platform_wait_pos = plat.pos1;
wait_node.platform_board_pos = plat.pos1;
wait_node.traffic_score = 0.1;        // Low traffic (breadcrumb)
wait_node.pathtype = DROPPED;         // Breadcrumb marker
```

**Debug Logging** (LOG_VERBOSE):
```
ELEVATOR: Created WAIT_NODE at '64 128 0'
ELEVATOR: Created EXIT_NODE at '64 128 256'
```

---

## Implementation Details

### File Changes Summary

| File | Lines Changed | Purpose |
|------|---------------|---------|
| [botit_th.qc](c:\reaperai\reaper_mre\botit_th.qc) | +27 | Entity fields, constants |
| [defs.qc](c:\reaperai\reaper_mre\defs.qc) | +5 | Forward declarations |
| [botroute.qc](c:\reaperai\reaper_mre\botroute.qc) | +222 | Detection functions, A* integration, auto-creation |
| [botmove.qc](c:\reaperai\reaper_mre\botmove.qc) | +92 | Wait state management |
| [botthink.qc](c:\reaperai\reaper_mre\botthink.qc) | +21 | Boarding confirmation |
| **Total** | **+367 lines** | **Full elevator system** |

### Code Size Breakdown

| Component | Bytes | Percentage |
|-----------|-------|------------|
| Entity fields + constants | ~400 | 10.3% |
| Platform detection functions | ~900 | 23.1% |
| A* integration (6 neighbors) | ~850 | 21.8% |
| Wait state management | ~1,100 | 28.2% |
| Boarding confirmation | ~300 | 7.7% |
| Auto node creation | ~350 | 9.0% |
| **Total Overhead** | **3,896 bytes** | **+0.8% of codebase** |

### Performance Impact

**A* Pathfinding**:
- **Cost per neighbor check**: ~5-10 ops (node_type check + function call)
- **When platform absent**: Skips neighbor (saves edge cost calculation)
- **When platform present**: +1 function call overhead (IsPlatformAt)
- **Net impact**: Negligible (<1% pathfinding time)

**Wait State**:
- **Active only when waiting**: No overhead during normal movement
- **Frame cost when waiting**: ~20 ops (platform check + timer check)
- **Frequency**: Rare (only at elevator entrances when platform absent)

**Auto Node Creation**:
- **Triggered**: Only when dropping breadcrumbs on platforms
- **Cost**: One-time per elevator (finds/creates node pairs)
- **Frequency**: Very rare (exploration phase only)

---

## Usage Guide

### For Map Creators

**Manual Elevator Node Placement** (optional - auto-creation handles this):

```qc
// In maps/yourmap.qc
void() LoadMapWaypoints_yourmap = {
    local entity wait_node, exit_node;

    // Create WAIT_NODE at elevator bottom
    wait_node = SpawnSavedWaypoint('64 128 0', 0.1, 0, "");
    wait_node.node_type = NODE_WAIT;
    wait_node.platform_entity = find(world, targetname, "elevator1");
    wait_node.platform_wait_pos = wait_node.platform_entity.pos1;
    wait_node.platform_board_pos = wait_node.platform_entity.pos1;

    // Create EXIT_NODE at elevator top
    exit_node = SpawnSavedWaypoint('64 128 256', 0.1, 0, "");
    exit_node.node_type = NODE_EXIT;
    exit_node.platform_entity = wait_node.platform_entity;

    // Link pair
    wait_node.wait_node_pair = exit_node;
    exit_node.wait_node_pair = wait_node;

    // Connect in waypoint graph
    wait_node.movetarget = exit_node;
};
```

**BUT**: Auto-creation makes this unnecessary! Just let bots explore.

### For Server Admins

**Enable Debug Logging**:
```
impulse 95          // Enable bot debug
impulse 96          // Cycle to LOG_TACTICAL (shows elevator events)
impulse 96          // Cycle to LOG_VERBOSE (shows node creation)
```

**Expected Console Output** (LOG_TACTICAL):
```
[BotName] ELEVATOR: Waiting at '64 128 0'
[BotName] ELEVATOR: Boarding (waited 2.5s)
[BotName] ELEVATOR: Aboard, riding to top (waited 2.5s)
```

**Expected Console Output** (LOG_VERBOSE):
```
ELEVATOR: Created WAIT_NODE at '64 128 0'
ELEVATOR: Created EXIT_NODE at '64 128 256'
A*: Elevator blocked at '64 128 0' (platform at top)
```

**Timeout Behavior**:
```
[BotName] ELEVATOR: Timeout (30.1s), replanning
```
(Bot waited 30 seconds, platform never came, finding alternate route)

### For Bot Developers

**Check if bot is waiting for elevator**:
```qc
if (self.elevator_wait_state) {
    // Bot is waiting for elevator
    // self.elevator_wait_node = which WAIT_NODE
    // self.elevator_wait_start = when bot started waiting
    float wait_duration = time - self.elevator_wait_start;
}
```

**Manually trigger elevator wait**:
```qc
// Force bot to wait at specific WAIT_NODE
self.elevator_wait_state = TRUE;
self.elevator_wait_node = some_wait_node;
self.elevator_wait_start = time;
```

**Check if waypoint is elevator node**:
```qc
if (node.node_type == NODE_WAIT) {
    // This is an elevator entrance
    entity plat = node.platform_entity;
    vector bottom_pos = node.platform_board_pos;
}

if (node.node_type == NODE_EXIT) {
    // This is an elevator exit
    entity paired_wait_node = node.wait_node_pair;
}
```

---

## Testing

### Test Scenario 1: Platform at Bottom

**Setup**:
1. Map: E1M1 (has classic elevator to Quad)
2. Platform position: Bottom (pos1)
3. Place Quad on upper level

**Expected Behavior**:
- A* finds path through elevator (platform present)
- Bot walks to WAIT_NODE
- Platform detected present → No wait state
- Bot boards elevator
- Rides to top
- Exits at EXIT_NODE
- Gets Quad

**Debug Output**:
```
[Bot] Goal: Quad Damage (score: 100.0)
[Bot] A*: Path found (5 nodes)
[Bot] ELEVATOR: Boarding (waited 0.0s)
[Bot] ELEVATOR: Aboard, riding to top
```

### Test Scenario 2: Platform at Top

**Setup**:
1. Map: E1M1
2. Platform position: Top (pos2)
3. Place Quad on upper level

**Expected Behavior**:
- A* checks WAIT_NODE → Platform absent
- A* skips elevator path (blocked)
- A* finds alternate route (stairs/teleporter)
- Bot takes alternate route
- Gets Quad without using elevator

**Debug Output**:
```
[Bot] Goal: Quad Damage (score: 100.0)
A*: Elevator blocked at '64 128 0' (platform at top)
[Bot] A*: Path found via stairs (8 nodes)
```

### Test Scenario 3: Wait State

**Setup**:
1. Manually set bot's goal to WAIT_NODE
2. Platform starts at top
3. Observe wait behavior

**Expected Behavior**:
- Bot reaches WAIT_NODE
- Platform absent → Enter wait state
- Bot stops: `velocity = '0 0 0'`
- Bot looks up: `pitch = -45°`
- Stuck timers reset: `stuck_count = 0`
- Wait 30 seconds without calling elevator

**Expected Output**:
```
[Bot] ELEVATOR: Waiting at '64 128 0'
(30 seconds pass)
[Bot] ELEVATOR: Timeout (30.1s), replanning
[Bot] A*: Path found via stairs (8 nodes)
```

### Test Scenario 4: Auto Node Creation

**Setup**:
1. Delete all elevator waypoints from map
2. Spawn bots, let them explore
3. Bots should ride elevator naturally
4. Run `impulse 100` (DumpWaypoints)

**Expected Behavior**:
1. Bot explores, drops breadcrumb on elevator (bottom)
   - Creates WAIT_NODE at current position
   - Creates EXIT_NODE at top position
   - Links pair
2. Bot rides elevator to top
3. Bot drops breadcrumb on elevator (top)
   - Finds existing EXIT_NODE
   - Finds existing WAIT_NODE
   - Verifies link
4. DumpWaypoints shows node pairs in console

**Expected Output**:
```
ELEVATOR: Created WAIT_NODE at '64 128 0'
ELEVATOR: Created EXIT_NODE at '64 128 256'
(later, at top)
ELEVATOR: Created EXIT_NODE at '64 128 256' (already exists, skip)

impulse 100 output:
SpawnSavedWaypoint('64 128 0', 0.1, 0, "", NODE_WAIT, "elevator1")
SpawnSavedWaypoint('64 128 256', 0.1, 0, "", NODE_EXIT, "elevator1")
```

### Success Criteria

✅ A* skips elevator paths when platform absent
✅ A* includes elevator paths when platform present
✅ Bots wait patiently at elevator entrance (don't enter shaft)
✅ Bots board elevator when it arrives
✅ Bots ride elevator to destination
✅ Bots timeout and replan if elevator never arrives
✅ Auto-created elevator nodes work correctly
✅ DumpWaypoints exports elevator nodes with metadata

---

## API Reference

### Functions

#### IsPlatformAt
```qc
float IsPlatformAt(entity plat, vector target_pos)
```
**Purpose**: Check if platform is at specific position
**Parameters**:
- `plat`: The func_plat entity
- `target_pos`: Target position to check (usually pos1 or pos2)
**Returns**: TRUE if platform within 32 units of target, FALSE otherwise
**Example**:
```qc
if (IsPlatformAt(my_elevator, my_elevator.pos1)) {
    bprint("Elevator at bottom\n");
}
```

#### CanTraverseElevator
```qc
float CanTraverseElevator(entity wait_node)
```
**Purpose**: Validate if WAIT_NODE is traversable right now
**Parameters**:
- `wait_node`: The WAIT_NODE to check
**Returns**: TRUE if platform present or descending, FALSE if blocked
**Example**:
```qc
if (CanTraverseElevator(elevator_entrance)) {
    bprint("Can use elevator\n");
} else {
    bprint("Elevator blocked, find alternate route\n");
}
```

#### FindElevatorNode
```qc
entity FindElevatorNode(vector pos, float radius)
```
**Purpose**: Locate elevator nodes near a position
**Parameters**:
- `pos`: Search position
- `radius`: Search radius in units
**Returns**: Closest NODE_WAIT or NODE_EXIT within radius, or world if none
**Example**:
```qc
entity nearby_elevator = FindElevatorNode(self.origin, 128);
if (nearby_elevator) {
    bprint("Found elevator node nearby\n");
}
```

### Constants

```qc
// Node Types
NODE_STANDARD   = 0    // Normal waypoint
NODE_WAIT       = 1    // Elevator wait node (bottom)
NODE_EXIT       = 2    // Elevator exit node (top)

// Platform States (from plats.qc)
STATE_TOP       = 0    // At top position
STATE_BOTTOM    = 1    // At bottom position
STATE_UP        = 2    // Moving to top
STATE_DOWN      = 3    // Moving to bottom
```

### Entity Fields

```qc
// Waypoint fields
.float node_type              // NODE_STANDARD, NODE_WAIT, or NODE_EXIT
.entity platform_entity       // Link to func_plat/func_train
.vector platform_wait_pos     // Where to stand while waiting
.vector platform_board_pos    // Where platform is boardable
.entity wait_node_pair        // Link to paired node

// Bot state fields
.float elevator_wait_state    // TRUE when waiting for elevator
.entity elevator_wait_node    // Which WAIT_NODE we're waiting at
.float elevator_wait_start    // Timestamp when waiting started
```

---

## Troubleshooting

### Issue: Bots still walk into empty elevator shafts

**Diagnosis**:
- Check if waypoints have `node_type` set correctly
- Verify `platform_entity` is linked to correct func_plat
- Enable LOG_VERBOSE, watch for "A*: Elevator blocked" messages

**Fix**:
- Run bots on map to auto-create elevator nodes
- Or manually set `node_type = NODE_WAIT` for bottom waypoints

### Issue: Bots wait forever at elevator

**Diagnosis**:
- Check if platform is stuck (broken map entity)
- Verify platform state machine (should cycle pos1 ↔ pos2)
- Check console for "ELEVATOR: Timeout" messages (should appear after 30s)

**Fix**:
- If timeout not working: Verify `elevator_wait_start` is set correctly
- If platform broken: Fix map entity (check plats.qc trigger logic)

### Issue: Auto node creation not working

**Diagnosis**:
- Check if bots are actually riding elevator
- Verify LOG_VERBOSE shows "ELEVATOR: Created WAIT_NODE" messages
- Check if `IsPlatformAt` returning correct values

**Fix**:
- Ensure bots explore elevator naturally (place items to lure them)
- Verify platform has valid `pos1` and `pos2` vectors
- Check `platform_entity` link is established

### Issue: A* still pathfinds through blocked elevators

**Diagnosis**:
- Verify `CanTraverseElevator` is being called (add debug log)
- Check if `neighbor = world` assignment is actually skipping neighbor
- Verify all 6 movetarget checks are implemented

**Fix**:
- Confirm forward declarations in defs.qc exist
- Check compilation warnings for type mismatches
- Verify `node_type == NODE_WAIT` comparison is working

### Issue: Bots don't board platform when it arrives

**Diagnosis**:
- Check if `elevator_wait_state` is being cleared
- Verify "Ride Platform Auto-Follow" is detecting platform (downward trace)
- Check if platform velocity is being inherited

**Fix**:
- Verify botthink.qc boarding confirmation code is active
- Check if trace_ent is correctly identifying func_plat
- Ensure `self.velocity = self.velocity + trace_ent.velocity` is executing

---

## Advanced Topics

### Integration with Train Navigation

**Current Status**: Auto-creation supports `func_train` detection but doesn't fully implement train path_corner prediction.

**Future Enhancement**:
```qc
if (trace_ent.classname == "func_train") {
    // Similar to func_plat, but use path_corner chain
    // instead of pos1/pos2
    local entity train_stop_1 = plat.target;  // First path_corner
    local entity train_stop_2 = train_stop_1.target;  // Second path_corner

    // Create WAIT_NODE at first stop
    // Create EXIT_NODE at second stop
    // etc.
}
```

### Elevator Chaining (Multi-Level Elevators)

**Scenario**: Elevator with 3+ stops (bottom → middle → top)

**Solution**: Create multiple EXIT_NODE entities, link in chain:
```qc
wait_node.movetarget = exit_node_1;   // Bottom → Middle
exit_node_1.movetarget = exit_node_2;  // Middle → Top
```

**A* will automatically find shortest path** through chain.

### Dynamic Platform Speed Prediction

**Current**: Uses fixed 200 u/s bot speed for travel time estimation

**Enhancement**: Calculate actual platform speed from velocity:
```qc
float platform_speed = vlen(plat.velocity);
float travel_time = dist_to_goal / platform_speed;
```

Use for more accurate `IsPlatformAt` predictions during movement.

---

## Changelog

### Version 1.0 (2026-01-07)
- ✅ Initial implementation
- ✅ Two-node elevator system (WAIT_NODE + EXIT_NODE)
- ✅ Platform presence detection (IsPlatformAt)
- ✅ A* pathfinding integration (6 neighbor checks)
- ✅ Wait state management (30s timeout)
- ✅ Boarding confirmation
- ✅ Auto elevator node creation
- ✅ Legacy compatibility (is_platform_node fallback)
- **Build size**: 496,890 bytes (+3,896 bytes, +0.8%)
- **Compilation**: 36 warnings (all pre-existing)

---

## Credits

**Original Concept**: Obot's Two-Node Elevator System
**Implementation**: Modern Reaper Enhancements (2026)
**Inspiration**: [ELEVATOR_SYSTEM_ANALYSIS.md](c:\reaperai\ELEVATOR_SYSTEM_ANALYSIS.md) - Complete architectural analysis

---

## License

This elevator navigation system is part of Modern Reaper Enhancements (MRE), a derivative work of the Reaper Bot (circa 1996). The implementation follows the original Quake modding community spirit of open-source collaboration and knowledge sharing.

---

**Last Updated**: 2026-01-07
**Documentation Version**: 1.0
**Build Compatibility**: MRE 496,890 bytes and later
