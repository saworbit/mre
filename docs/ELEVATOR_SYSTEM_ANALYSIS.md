# Elevator Navigation System Analysis & Implementation Plan

**Date**: 2026-01-07
**Issue**: Bots path through elevator shafts when platforms are absent
**Root Cause**: A* pathfinding doesn't check platform presence before routing
**Proposed Solution**: Obot-style two-node elevator system with dynamic traversal checks

---

## Part 1: Existing Safeguards Analysis

### What Currently Exists (Partial Mitigation)

#### ✅ Safeguard 1: "Elevator Patience" (botmove.qc:2098-2124)
**Status**: REACTIVE - Activates after bot reaches shaft

```qc
if (Botgoal.is_platform_node) {
    if (Botgoal.origin_z > self.origin_z + 64) {
        if (vlen(flat_dist) < 200) {
            // We are at shaft. WAIT here.
            self.velocity = '0 0 0';
            self.ideal_pitch = -45;  // Look up
            self.stuck_count = 0;    // Reset stuck timer
        }
    }
}
```

**What It Does**:
- Detects when bot arrives at bottom of shaft
- Stops bot from falling into pit
- Looks up at platform (human-like behavior)
- Resets stuck timers to prevent panic teleport

**Limitation**: Bot has already committed to this path. If there's no floor at the shaft bottom, bot takes fall damage before this triggers.

---

#### ✅ Safeguard 2: "Ride Platform Auto-Follow" (botthink.qc:539-556)
**Status**: REACTIVE - Helps bot stay on platform once aboard

```qc
traceline(self.origin - '0 0 32', self.origin, TRUE, self);
if (trace_ent && (trace_ent.classname == "func_plat" || trace_ent.classname == "func_train")) {
    // Standing on moving platform—inherit its velocity for smooth ride
    self.velocity = self.velocity + trace_ent.velocity;
    self.flags = self.flags | FL_ONGROUND;

    // Adjust goal to follow platform motion
    if (self.goalentity == trace_ent) {
        self.goalentity.origin = trace_ent.origin;
    }
}
```

**What It Does**:
- Detects when bot is standing on moving platform
- Inherits platform velocity (prevents sliding off)
- Adjusts goal position to match platform movement
- Maintains FL_ONGROUND flag for stability

**Limitation**: Only works AFTER bot successfully boards platform. Doesn't help with initial approach.

---

#### ✅ Safeguard 3: "Platform Prediction" (botmove.qc:2171-2213)
**Status**: REACTIVE - Improves aim after bot commits to platform

```qc
if (g_ent && (g_ent.classname == "func_plat" || g_ent.classname == "func_train")) {
    dist_to_goal = vlen(Botgoal.origin - self.origin);
    travel_time = dist_to_goal / 200;  // Bot speed ~200 u/s

    if (g_ent.classname == "func_train") {
        pred_pos = predict_train_pos(g_ent, travel_time);
    } else {
        // For plats: use velocity + state prediction
        pred_pos = g_ent.origin + g_ent.velocity * travel_time;

        if (g_ent.state == STATE_UP) {
            pred_pos = g_ent.pos2;  // Will be at top
        } else if (g_ent.state == STATE_DOWN) {
            pred_pos = g_ent.pos1;  // Will be at bottom
        }
    }

    self.ideal_yaw = vectoyaw(pred_pos - self.origin);
}
```

**What It Does**:
- Predicts where platform will be when bot arrives
- Uses `STATE_UP`/`STATE_DOWN` for func_plat
- Uses `predict_train_pos()` for func_train (path_corner chain)
- Aims at predicted intercept point instead of current position

**Limitation**: Doesn't prevent pathfinding through absent platforms. Only helps timing AFTER route is chosen.

---

#### ⚠️ Safeguard 4: "CheckForHazards" (botmove.qc:907-988)
**Status**: PARTIAL - Detects pits, but not elevator-specific

```qc
void() CheckForHazards = {
    if (!(self.flags & FL_ONGROUND)) {
        return;  // Only check when on ground
    }

    // Look 60 units ahead
    spot = self.origin + v_forward * 60;
    traceline(spot, spot - '0 0 250', TRUE, self);

    gap_depth = self.origin_z - trace_endpos_z;

    // CASE A: Gap or deep drop (>60 units)
    if (trace_fraction == 1 || gap_depth > 60) {
        // Decorative hole filter (checks left/right for narrow grates)
        if (left_gap < 20 && right_gap < 20) {
            return;  // Not a real hazard
        }

        // Death pit? (slime/lava/void)
        if (content_type <= CONTENT_SLIME || trace_fraction == 1) {
            self.velocity = '0 0 0';  // STOP!
            return;
        }

        // Jumpable gap?
        if (vlen(self.velocity) > 200) {
            self.button2 = 1;  // Jump
        }
    }
}
```

**What It Does**:
- Looks 60 units ahead for pits/lava
- Filters out decorative holes (grates <40u wide)
- Stops bot before death pits (slime/lava/void)
- Triggers jump for gaps when moving fast

**Limitation**:
- **Only looks 60 units ahead** (elevator shafts are often >200u wide)
- **Only checks when FL_ONGROUND** (doesn't help during walkmove() decisions)
- **Doesn't distinguish elevator shafts from normal pits**
- If bot approaches shaft slowly (<200 u/s), won't jump

---

#### ❌ Safeguard 5: "Platform Node Tagging" (botroute.qc:600-605)
**Status**: METADATA ONLY - No behavioral impact

```qc
// ===== PLATFORM MASTERY: Platform Tagging =====
if (trace_ent.classname == "func_plat" || trace_ent.classname == "func_train" || trace_ent.classname == "func_door") {
    oldpath.is_platform_node = TRUE;
}
```

**What It Does**:
- Tags waypoints that sit on platforms with `is_platform_node = TRUE`
- Enables "Elevator Patience" logic to detect platform nodes

**Limitation**: **NO PATHFINDING INTEGRATION!** A* treats tagged nodes identically to normal nodes. The tag is only used AFTER pathfinding completes.

---

### Critical Gap Identified

**The Problem**: All existing safeguards are **REACTIVE** (activate after bot commits to path).

#### Failure Scenario

```
Map Layout (E1M1 elevator):
┌─────────────┐ ← Platform at TOP (pos2)
│  Quad Dmg   │ ← Waypoint C (is_platform_node=TRUE)
└─────────────┘
       │
       │  200u empty shaft
       │
       ▼
┌─────────────┐ ← Waypoint B (bottom of shaft)
│   Bot here  │
└─────────────┘
```

**Step-by-Step Failure**:

1. **A* Pathfinding** (botroute.qc:1108+):
   - Bot at waypoint A, wants Quad at waypoint C
   - A* finds path: A → B → C
   - **Node B has `is_platform_node = TRUE`** but A* doesn't check platform position
   - **Platform is at top (pos2)**, shaft is empty
   - A* returns valid path (doesn't know shaft is empty)

2. **Bot Moves to Waypoint B**:
   - Follows A* path to waypoint B (shaft entrance)
   - **CheckForHazards() activates** (looks 60u ahead)
   - Shaft is 200u wide → **detection fails** (only sees 60u)
   - Bot continues forward into shaft

3. **Bot Reaches Shaft Edge**:
   - One of two outcomes:
     - **If shaft has floor below**: Bot walks into shaft, stops, waits (Elevator Patience kicks in)
     - **If shaft is bottomless pit**: Bot falls, takes damage, stuck recovery attempts

4. **Elevator Patience Activates** (botmove.qc:2101):
   - **Too late** - bot already in bad position
   - Stops bot, looks up, resets stuck timer
   - Bot waits for platform to return to bottom

**Damage Assessment**:
- ❌ Wasted time (bot standing idle in shaft)
- ❌ Fall damage if shaft is deep
- ❌ Looks stupid (walks into obvious empty shaft)
- ❌ Vulnerable (sitting duck while waiting)

---

### Why Existing Safeguards Fail

| Safeguard | Timing | Platform Check | Pathfinding Integration | Prevents Shaft Entry |
|-----------|--------|----------------|-------------------------|---------------------|
| Elevator Patience | After arrival | ✅ Yes (height check) | ❌ No | ❌ No |
| Ride Platform | After boarding | ✅ Yes (groundentity) | ❌ No | ❌ No |
| Platform Prediction | During approach | ⚠️ Partial (state) | ❌ No | ❌ No |
| CheckForHazards | During movement | ❌ No (generic pit) | ❌ No | ⚠️ Partial (60u range) |
| Platform Tagging | Map load | ❌ No | ❌ No | ❌ No |

**Root Cause**: **No PROACTIVE pathfinding filter**. A* needs to ask: *"Is this platform node traversable RIGHT NOW?"*

---

## Part 2: Obot-Style Two-Node Elevator System

### Architecture Overview

**Core Principle**: Treat elevators as **conditional connections** in the waypoint graph.

```
Standard Waypoint Connection:
   A ←──→ B    (always traversable)

Elevator Connection:
   A ←──?──→ B    (traversable only if platform present)
```

### The Two Node Types

#### Node 1: **WAIT_NODE** (Bottom/Entry Point)
**Purpose**: Safe waiting position at elevator entrance

**Location**:
- Ground floor at elevator entrance
- **NOT in the shaft** (safe zone ~64u from edge)
- Horizontal with bottom platform position

**Properties**:
```qc
.float node_type = NODE_WAIT;        // Special node type
.entity platform_entity;              // Link to actual func_plat
.vector platform_wait_pos;            // Where to stand while waiting (pos1)
.vector platform_board_pos;           // Where platform will be when boardable (pos1)
```

**Behavior**:
- **A* traversal check**: "Is platform at bottom position (pos1)?"
  - YES → Treat as normal node (cost = distance)
  - NO → Treat as **BLOCKED** (cost = 99999 or skip)
- **Movement behavior**: If bot arrives and platform absent, enter WAIT state
  - Stop movement
  - Look up at shaft
  - Monitor platform position
  - Board when platform arrives

#### Node 2: **EXIT_NODE** (Top/Destination Point)
**Purpose**: Elevator exit point at top

**Location**:
- Top floor at elevator exit
- Platform position when at pos2 (top)

**Properties**:
```qc
.float node_type = NODE_EXIT;         // Special node type
.entity platform_entity;              // Link to actual func_plat
.entity wait_node_pair;               // Link back to WAIT_NODE
```

**Behavior**:
- **A* traversal check**: Depends on WAIT_NODE status
  - If WAIT_NODE is traversable → This is reachable (via elevator)
  - If WAIT_NODE is blocked → This is BLOCKED (platform elsewhere)
- **Movement behavior**: Standard waypoint (no special logic needed)

---

### Dynamic Traversal Logic

**Key Insight**: Elevators have **state-dependent reachability**.

#### Platform State Detection

```qc
// NEW FUNCTION: Check if platform is at specific position
float(entity plat, vector target_pos) IsPlatformAt = {
    float dist = vlen(plat.origin - target_pos);

    // Platform within 32 units of target position?
    if (dist < 32) {
        return TRUE;
    }

    return FALSE;
};

// NEW FUNCTION: Check if WAIT_NODE is traversable
float(entity wait_node) CanTraverseElevator = {
    entity plat = wait_node.platform_entity;

    if (!plat) {
        return FALSE;  // No platform linked (error)
    }

    // Is platform at bottom position (pos1)?
    if (IsPlatformAt(plat, wait_node.platform_board_pos)) {
        return TRUE;  // Platform present, safe to path through
    }

    // Optional: Check if platform is coming down
    if (plat.state == STATE_DOWN) {
        // Platform descending - could wait for it
        return TRUE;  // Treat as traversable (bot will wait)
    }

    return FALSE;  // Platform at top or moving up, find alternate route
};
```

#### A* Integration Point

**Current Code** (botroute.qc:1200-1253):
```qc
// Check all movetarget links
neighbor = lowest.movetarget;
if (neighbor) {
    // Calculate edge cost
    edge_cost = vlen(neighbor.origin - lowest.origin);

    // Add danger scent, traffic penalties...
    // (existing tactical pathfinding)

    // Update neighbor and add to open set
}
```

**NEW Code** (with elevator check):
```qc
// Check all movetarget links
neighbor = lowest.movetarget;
if (neighbor) {
    // ===== ELEVATOR SYSTEM: Dynamic Traversal Check =====
    if (neighbor.node_type == NODE_WAIT) {
        // This is an elevator entrance - check if platform present
        if (!CanTraverseElevator(neighbor)) {
            // Platform absent - SKIP this neighbor entirely
            continue;  // Don't add to open set
        }
    }
    // ===== END ELEVATOR SYSTEM =====

    // Calculate edge cost
    edge_cost = vlen(neighbor.origin - lowest.origin);

    // (rest of existing code)
}
```

**Result**: A* automatically skips elevator paths when platforms are absent!

---

### Wait State Behavior

**When bot arrives at WAIT_NODE and platform is absent:**

```qc
// In botmove.qc main movement loop
if (Botgoal.node_type == NODE_WAIT) {
    entity plat = Botgoal.platform_entity;

    // Is platform here?
    if (!IsPlatformAt(plat, Botgoal.platform_board_pos)) {
        // Platform absent - enter WAIT state
        self.elevator_wait_state = TRUE;
        self.elevator_wait_node = Botgoal;
        self.elevator_wait_start = time;

        // Stop movement
        self.velocity = '0 0 0';

        // Look up at shaft (human-like)
        self.ideal_pitch = -45;
        ChangePitch();

        // Reset stuck timers (we're intentionally waiting)
        self.stuck_count = 0;
        self.stuck_time = 0;

        return;  // Don't try to move
    }

    // Platform arrived!
    if (self.elevator_wait_state) {
        // Board the platform
        self.elevator_wait_state = FALSE;

        // Optional: Debug log
        if (bot_debug_level >= LOG_TACTICAL) {
            bprint("["); bprint(self.netname); bprint("] ELEVATOR: Boarding\n");
        }
    }
}
```

**Timeout Handling** (prevent infinite waits):
```qc
// If waiting too long (30+ seconds), replan route
if (self.elevator_wait_state) {
    if (time - self.elevator_wait_start > 30) {
        // Timeout - find alternate route
        self.elevator_wait_state = FALSE;
        FindAPath();  // Force re-pathfind (will skip this elevator)
    }
}
```

---

### Automatic Node Pair Creation

**During waypoint generation** (when bot drops breadcrumb on platform):

```qc
// In botroute.qc breadcrumb drop logic
if (trace_ent.classname == "func_plat") {
    entity plat = trace_ent;

    // Determine if we're at bottom or top
    float at_bottom = IsPlatformAt(plat, plat.pos1);
    float at_top = IsPlatformAt(plat, plat.pos2);

    if (at_bottom) {
        // Create WAIT_NODE at current position
        entity wait_node = SpawnSavedWaypoint(self.origin, 0.1, 0, "");
        wait_node.node_type = NODE_WAIT;
        wait_node.platform_entity = plat;
        wait_node.platform_wait_pos = plat.pos1;
        wait_node.platform_board_pos = plat.pos1;

        // Find or create EXIT_NODE at top
        entity exit_node = FindNearbyNode(plat.pos2, 64);
        if (!exit_node) {
            exit_node = SpawnSavedWaypoint(plat.pos2, 0.1, 0, "");
            exit_node.node_type = NODE_EXIT;
            exit_node.platform_entity = plat;
        }

        // Link the pair
        wait_node.wait_node_pair = exit_node;
        exit_node.wait_node_pair = wait_node;

        // Connect in waypoint graph
        ConnectNodes(wait_node, exit_node);
    }
}
```

---

## Part 3: Implementation Plan

### Phase 1: Core Infrastructure (2-3 hours)

#### 1.1 Entity Fields (defs.qc)
```qc
// ===== ELEVATOR NAVIGATION SYSTEM =====
// Node type constants
float NODE_STANDARD   = 0;  // Normal waypoint
float NODE_WAIT       = 1;  // Elevator wait node (bottom)
float NODE_EXIT       = 2;  // Elevator exit node (top)

// Platform state constants (Quake engine standard)
float STATE_TOP       = 0;  // At top position (pos1)
float STATE_BOTTOM    = 1;  // At bottom position (pos2)
float STATE_UP        = 2;  // Moving to top
float STATE_DOWN      = 3;  // Moving to bottom

// Waypoint node fields
.float node_type;              // NODE_WAIT, NODE_EXIT, or NODE_STANDARD
.entity platform_entity;       // Link to func_plat/func_train
.vector platform_wait_pos;     // Where to stand while waiting (pos1)
.vector platform_board_pos;    // Where platform is when boardable (pos1)
.entity wait_node_pair;        // Link to paired node (WAIT ↔ EXIT)

// Bot elevator state
.float elevator_wait_state;    // TRUE if waiting for elevator
.entity elevator_wait_node;    // Which WAIT_NODE we're at
.float elevator_wait_start;    // When we started waiting (for timeout)
```

#### 1.2 Platform Detection Functions (botroute.qc)
```qc
// Check if platform is at specific position (within 32 units)
float(entity plat, vector target_pos) IsPlatformAt = {
    if (!plat) return FALSE;

    float dist = vlen(plat.origin - target_pos);
    return (dist < 32);
};

// Check if elevator WAIT_NODE is traversable right now
float(entity wait_node) CanTraverseElevator = {
    if (wait_node.node_type != NODE_WAIT) {
        return TRUE;  // Not an elevator node, always traversable
    }

    entity plat = wait_node.platform_entity;
    if (!plat) {
        return FALSE;  // No platform linked (error state)
    }

    // Platform at bottom position?
    if (IsPlatformAt(plat, wait_node.platform_board_pos)) {
        return TRUE;  // Safe to path through
    }

    // Platform descending?
    if (plat.state == STATE_DOWN) {
        return TRUE;  // Will arrive soon, treat as traversable
    }

    return FALSE;  // Platform elsewhere, find alternate route
};

// Find elevator nodes near a position
entity(vector pos, float radius) FindElevatorNode = {
    entity e = find(world, classname, "BotPath");
    entity closest = world;
    float best_dist = radius;

    while (e) {
        if (e.node_type == NODE_WAIT || e.node_type == NODE_EXIT) {
            float dist = vlen(e.origin - pos);
            if (dist < best_dist) {
                best_dist = dist;
                closest = e;
            }
        }
        e = find(e, classname, "BotPath");
    }

    return closest;
};
```

---

### Phase 2: A* Integration (2 hours)

#### 2.1 Modify A* Neighbor Processing (botroute.qc:1200+)

**Insert elevator check before edge cost calculation:**

```qc
// ===== A* PATHFINDING: Process Neighbors =====
// (existing code line 1198+)

// Check movetarget neighbor
neighbor = lowest.movetarget;
if (neighbor) {
    if ((neighbor.search_id != ASTAR_SEARCH_ID) || (neighbor.closed_next != neighbor)) {

        // ===== ELEVATOR SYSTEM: Dynamic Traversal Check =====
        if (neighbor.node_type == NODE_WAIT) {
            // This is an elevator entrance - check if platform present
            if (!CanTraverseElevator(neighbor)) {
                // Platform absent - skip this path entirely
                // Don't add to open set, don't calculate costs
                // A* will find alternate route automatically
                goto skip_movetarget;  // Skip to next neighbor
            }
        }
        // ===== END ELEVATOR SYSTEM =====

        // ===== TACTICAL PATHFINDING: The "Fear" Engine =====
        // (existing edge cost calculation)
        edge_cost = vlen(neighbor.origin - lowest.origin);
        // ... danger scent, traffic penalties ...

        // (existing code to update neighbor and add to open set)
    }
}
skip_movetarget:  // Jump here if elevator blocked

// Repeat for movetarget2, movetarget3, etc.
// (insert same check for each neighbor link)
```

**IMPORTANT**: Insert check at 6 locations (one for each movetarget1-6).

---

#### 2.2 Add Debug Logging (optional)

```qc
// In CanTraverseElevator function
if (!IsPlatformAt(plat, wait_node.platform_board_pos)) {
    // Platform absent - log rejection
    if (bot_debug_level >= LOG_VERBOSE) {
        bprint("A*: Elevator blocked at ");
        bprint(vtos(wait_node.origin));
        bprint(" (platform at top)\n");
    }
    return FALSE;
}
```

---

### Phase 3: Movement Behavior (3 hours)

#### 3.1 Elevator Wait State (botmove.qc:2098+)

**Replace existing "Elevator Patience" logic** with comprehensive wait system:

```qc
// ===== ELEVATOR SYSTEM: Wait State Management =====
// Replaces old "Elevator Patience" (line 2098-2124)

if (Botgoal.node_type == NODE_WAIT) {
    entity plat = Botgoal.platform_entity;

    if (!plat) {
        // Error: WAIT_NODE has no platform linked
        // Abandon this goal and replan
        FindAPath();
        return;
    }

    // Check if platform is present
    if (!IsPlatformAt(plat, Botgoal.platform_board_pos)) {
        // Platform absent - enter WAIT state

        if (!self.elevator_wait_state) {
            // Just started waiting
            self.elevator_wait_state = TRUE;
            self.elevator_wait_node = Botgoal;
            self.elevator_wait_start = time;

            // Debug log
            if (bot_debug_level >= LOG_TACTICAL) {
                bprint("["); bprint(self.netname);
                bprint("] ELEVATOR: Waiting at ");
                bprint(vtos(Botgoal.origin)); bprint("\n");
            }
        }

        // Wait behavior
        self.velocity = '0 0 0';  // Stop
        self.ideal_pitch = -45;   // Look up at shaft
        ChangePitch();

        // Reset stuck timers (intentional wait)
        self.stuck_count = 0;
        self.stuck_time = 0;

        // Timeout check (prevent infinite waits)
        if (time - self.elevator_wait_start > 30) {
            // Waited too long - replan route
            if (bot_debug_level >= LOG_TACTICAL) {
                bprint("["); bprint(self.netname);
                bprint("] ELEVATOR: Timeout, replanning\n");
            }

            self.elevator_wait_state = FALSE;
            FindAPath();  // Find alternate route
        }

        return;  // Don't move
    }

    // Platform arrived!
    if (self.elevator_wait_state) {
        // Reset wait state
        self.elevator_wait_state = FALSE;

        // Debug log
        if (bot_debug_level >= LOG_TACTICAL) {
            bprint("["); bprint(self.netname);
            bprint("] ELEVATOR: Boarding (waited ");
            bprint(ftos(time - self.elevator_wait_start));
            bprint("s)\n");
        }
    }

    // Platform present - proceed with normal movement
}
// ===== END ELEVATOR SYSTEM =====
```

---

#### 3.2 Platform Boarding Behavior

**Enhance existing "Ride Platform Auto-Follow"** (botthink.qc:539+):

```qc
// ===== TWEAK #4: Ride platform auto-follow (enhanced) =====
traceline(self.origin - '0 0 32', self.origin, TRUE, self);
if (trace_ent && (trace_ent.classname == "func_plat" || trace_ent.classname == "func_train")) {
    // Standing on moving platform—inherit its velocity
    self.velocity = self.velocity + trace_ent.velocity;
    self.flags = self.flags | FL_ONGROUND;

    // Adjust goal to follow platform motion
    if (self.goalentity == trace_ent) {
        self.goalentity.origin = trace_ent.origin;
    }

    // ===== NEW: Elevator boarding confirmation =====
    if (self.elevator_wait_state) {
        // We were waiting for this platform - now aboard!
        self.elevator_wait_state = FALSE;

        // Debug log
        if (bot_debug_level >= LOG_TACTICAL) {
            bprint("["); bprint(self.netname);
            bprint("] ELEVATOR: Aboard, riding to top\n");
        }
    }
    // ===== END NEW =====
}
```

---

### Phase 4: Automatic Node Creation (2 hours)

#### 4.1 Detect Elevators During Waypoint Drop

**Enhance breadcrumb drop** (botroute.qc ~550-605):

```qc
// In CheckDropPath / breadcrumb drop section
if (trace_ent.classname == "func_plat") {
    entity plat = trace_ent;

    // Tag as platform node (existing code)
    oldpath.is_platform_node = TRUE;

    // ===== NEW: Auto-create elevator node pair =====

    // Determine if we're at bottom or top
    float at_bottom = IsPlatformAt(plat, plat.pos1);
    float at_top = IsPlatformAt(plat, plat.pos2);

    if (at_bottom) {
        // We're at bottom - create/update WAIT_NODE
        entity wait_node = FindElevatorNode(plat.pos1, 64);

        if (!wait_node) {
            // Create new WAIT_NODE
            wait_node = SpawnSavedWaypoint(self.origin, 0.1, 0, "");
            wait_node.node_type = NODE_WAIT;
            wait_node.platform_entity = plat;
            wait_node.platform_wait_pos = plat.pos1;
            wait_node.platform_board_pos = plat.pos1;

            // Debug log
            if (bot_debug_level >= LOG_VERBOSE) {
                bprint("ELEVATOR: Created WAIT_NODE at ");
                bprint(vtos(wait_node.origin)); bprint("\n");
            }
        }

        // Find or create EXIT_NODE at top
        entity exit_node = FindElevatorNode(plat.pos2, 64);

        if (!exit_node) {
            // Create EXIT_NODE at top position
            exit_node = SpawnSavedWaypoint(plat.pos2, 0.1, 0, "");
            exit_node.node_type = NODE_EXIT;
            exit_node.platform_entity = plat;

            // Debug log
            if (bot_debug_level >= LOG_VERBOSE) {
                bprint("ELEVATOR: Created EXIT_NODE at ");
                bprint(vtos(exit_node.origin)); bprint("\n");
            }
        }

        // Link the pair (bidirectional)
        wait_node.wait_node_pair = exit_node;
        exit_node.wait_node_pair = wait_node;

        // Ensure waypoint graph connection exists
        // (A* will use CanTraverseElevator to validate)
        if (!NodesConnected(wait_node, exit_node)) {
            ConnectNodes(wait_node, exit_node);
        }
    }
    else if (at_top) {
        // We're at top - create/update EXIT_NODE
        // (mirror logic of at_bottom case)
    }
    // ===== END NEW =====
}
```

---

#### 4.2 DumpWaypoints Export

**Modify waypoint export** to include node_type metadata:

```qc
// In DumpWaypoints function (existing code)
bprint("SpawnSavedWaypoint('");
bprint(vtos(e.origin));
bprint("', ");
bprint(ftos(e.traffic_score));
bprint(", ");
bprint(ftos(e.danger_scent));
bprint(", \"");
bprint(e.target);
bprint("\"");

// ===== NEW: Export node_type and platform links =====
if (e.node_type == NODE_WAIT) {
    bprint(", NODE_WAIT, \"");
    bprint(e.platform_entity.targetname);  // Platform ID
    bprint("\"");
}
else if (e.node_type == NODE_EXIT) {
    bprint(", NODE_EXIT, \"");
    bprint(e.platform_entity.targetname);
    bprint("\"");
}
// ===== END NEW =====

bprint(");\n");
```

**Result**: Waypoint files will include elevator metadata for next session.

---

### Phase 5: Testing & Validation (2-3 hours)

#### Test Map: E1M1 (Has classic elevator to Quad)

**Test Scenario 1: Platform at Bottom**
1. Spawn bot near elevator entrance
2. Place Quad on upper level (waypoint C)
3. Observe: Does A* find path through elevator?
4. Expected: YES (platform present, node traversable)
5. Expected: Bot boards elevator, rides to top, gets Quad

**Test Scenario 2: Platform at Top**
1. Start with platform at top
2. Spawn bot near elevator entrance
3. Place Quad on upper level
4. Observe: Does A* skip elevator path?
5. Expected: YES (platform absent, node blocked)
6. Expected: Bot finds alternate route (stairs/teleporter)

**Test Scenario 3: Wait State**
1. Manually route bot to elevator via impulse commands
2. Platform starts at top
3. Observe: Does bot enter WAIT state?
4. Expected: Bot stops, looks up, waits
5. Call elevator (player triggers it)
6. Expected: Bot boards when platform arrives

**Test Scenario 4: Timeout**
1. Force bot to wait at elevator
2. DON'T call elevator
3. Wait 30 seconds
4. Expected: Bot abandons elevator, replans route

**Test Scenario 5: Auto Node Creation**
1. Delete all elevator waypoints from dm4.qc
2. Play session, bots explore elevator
3. Run impulse 100 (DumpWaypoints)
4. Expected: Console shows WAIT_NODE and EXIT_NODE pairs
5. Reload map with new waypoints
6. Expected: Bots use elevator correctly without re-exploring

---

### Success Criteria

✅ **A* skips elevator paths when platform absent**
✅ **A* includes elevator paths when platform present**
✅ **Bots wait patiently at elevator entrance (don't enter shaft)**
✅ **Bots board elevator when it arrives**
✅ **Bots ride elevator to destination**
✅ **Bots timeout and replan if elevator never arrives**
✅ **Auto-created elevator nodes export correctly**
✅ **Reloaded elevator nodes work without manual editing**

---

## Implementation Priority

### CRITICAL (Do First)
1. **Phase 1.1**: Entity fields (5 min)
2. **Phase 1.2**: Platform detection functions (30 min)
3. **Phase 2.1**: A* integration (1 hour)
4. **Phase 3.1**: Elevator wait state (1 hour)

**Result**: Bots won't walk into empty elevator shafts. This fixes the core issue.

### HIGH (Do Next)
5. **Phase 3.2**: Platform boarding (30 min)
6. **Phase 4.1**: Auto node creation (1.5 hours)

**Result**: Bots learn elevators automatically, no manual waypoint editing.

### MEDIUM (Polish)
7. **Phase 2.2**: Debug logging (20 min)
8. **Phase 4.2**: DumpWaypoints export (30 min)
9. **Phase 5**: Testing (2-3 hours)

**Total Estimated Time**: 7-9 hours for full implementation

---

## Alternative: Quick Fix (1 hour)

If full implementation is too complex, here's a minimal fix:

**Just add platform check to A* neighbor processing:**

```qc
// In botroute.qc AStarSolve, line 1200+
neighbor = lowest.movetarget;
if (neighbor) {
    // ===== QUICK FIX: Skip platform nodes when platform absent =====
    if (neighbor.is_platform_node) {
        // Find the platform entity
        entity plat = find(world, classname, "func_plat");
        while (plat) {
            // Is platform near this waypoint?
            if (vlen(plat.origin - neighbor.origin) < 64) {
                // Found the platform - is it here?
                if (vlen(plat.origin - plat.pos1) > 32) {
                    // Platform not at bottom - skip this path
                    goto skip_neighbor;
                }
                break;  // Platform at bottom, proceed
            }
            plat = find(plat, classname, "func_plat");
        }
    }
    // ===== END QUICK FIX =====

    // (existing edge cost calculation)
}
skip_neighbor:
```

**Pros**:
- Fixes the core issue (bots won't path through absent elevators)
- 1 hour implementation
- Minimal code changes

**Cons**:
- No wait state (bots will repath if elevator not available)
- No auto node creation
- Performance cost (finds platform every A* iteration)

---

## Conclusion

**Current State**: Bots have reactive safeguards (Elevator Patience, Ride Platform), but no proactive pathfinding filter. They walk into empty elevator shafts.

**Obot's Insight**: Treat elevators as conditional connections. A* should check platform presence BEFORE routing through elevator nodes.

**Recommended Solution**: Implement full two-node system (WAIT_NODE + EXIT_NODE) with dynamic traversal checks in A* pathfinding.

**Expected Result**: Bots behave intelligently around elevators:
- Wait patiently when platform absent (like humans)
- Board smoothly when platform arrives
- Learn elevator locations automatically
- Never walk into empty shafts

---

**Next Steps**: Review this plan, then proceed to Part 3 (Code Implementation).
