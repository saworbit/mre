# Feeler Steering + Breadcrumb Waypoints Design

**Date**: 2026-01-06
**Goal**: Self-improving room escape and exploration system
**Problem**: Bots get stuck in rooms and can't find exits efficiently (no waypoint coverage)

---

## 🎯 **Core Concept**

**Two-part system**:

### **Part 1: Feeler Steering** (Local Navigation When Lost)
- 8-direction clearest-path scanning when bot is stuck/lost
- Moves toward clearest direction (likely the exit/doorway)
- Replaces random wandering with intelligent exploration
- **Does NOT replace waypoint navigation** - only activates when waypoints unavailable

### **Part 2: Breadcrumb Waypoints** (Map Learning)
- Drop waypoints as bot explores using feeler steering
- Creates trails: room center → exit
- Future bots use breadcrumbs to navigate rooms efficiently
- Breadcrumbs persist via DumpWaypoints and become permanent waypoints

**Result**: First bot struggles to find exit (feeler mode), but drops breadcrumbs. Next bots follow the trail!

---

## 📊 **Current MRE System Analysis**

### Waypoint System (botroute.qc)
- **343 static waypoints** on dm4 (manually placed in maps/dm4.qc)
- **Waypoint format**: `SpawnSavedWaypoint(origin, traffic, danger, target)`
  - `traffic_score`: How often bots use this route (learned from gameplay)
  - `danger_scent`: Death/damage history at this location
  - `target`: Smart Triggers (Phase 6) - button→door links
- **A* pathfinding**: Finds optimal path between waypoints
- **DumpWaypoints**: Exports all waypoints to console (impulse 100)

### Stuck Detection (botmove.qc line 1466)
- **Stuck counter**: Increments when `walkmove()` fails
- **Desperate escape** (stuck_count > 5):
  1. Train surf (if on moving train)
  2. Rocket jump (if skill > 2 and has rockets)
  3. Super jump (fallback, always works)
- **74 stuck events** per 8-minute session (validation logs)

### Problem Cases
1. **Waypoint gap**: Bot spawns far from waypoints → wanders randomly
2. **Unexplored room**: Bot enters room with no waypoint coverage → stuck
3. **Exit finding**: Bot in room center, door 200 units away, no waypoints → can't find exit
4. **Manual coverage**: 343 waypoints on dm4 can't cover every room/corridor

---

## 🔧 **Feeler Steering Design**

### When to Activate Feeler Mode

**Trigger Conditions** (any of):
1. **Stuck detection**: `stuck_count > 3` (before desperate escape at count=6)
2. **No nearby waypoints**: Nearest BotPath > 128 units away
3. **Lost mode**: No enemy, no goal, wandering randomly

**Deactivation Conditions** (any of):
1. **Waypoint found**: Within 64 units of a BotPath node
2. **Goal visible**: Enemy/item/waypoint in line-of-sight
3. **Escape successful**: Velocity sustained for 2+ seconds

### Feeler Scanning (8-Direction Clearest Path)

**Function**: `Bot_FindClearestDirection(entity bot) : float yaw`

**Implementation**:
```c
// Scan 8 directions from bot's current position
// Returns yaw of clearest direction (longest trace)

vector start = self.origin + '0 0 24';  // Waist height
float best_yaw = self.ideal_yaw;  // Default: keep current heading
float best_dist = 0;

for (i = 0; i < 8; i++) {
   float scan_yaw = i * 45;  // 0°, 45°, 90°, 135°, 180°, 225°, 270°, 315°

   // Convert yaw to direction vector
   self.v_angle_y = scan_yaw;
   makevectors(self.v_angle);

   // Trace 200 units in this direction
   traceline(start, start + v_forward * 200, TRUE, self);

   // Score = distance traveled (longer = more open)
   float score = trace_fraction * 200;

   // Bonus: Prefer directions that match our goal heading (if we have one)
   if (self.enemy || self.movetarget) {
      float goal_yaw = vectoyaw(goal.origin - self.origin);
      float angle_diff = abs(AngleDelta(scan_yaw, goal_yaw));

      // Reduce score for directions away from goal
      score = score * (1.0 - angle_diff / 180);
   }

   if (score > best_dist) {
      best_dist = score;
      best_yaw = scan_yaw;
   }
}

return best_yaw;
```

**Key Features**:
- ✅ **Finds doorways**: Traces toward open areas (doorways = longer trace)
- ✅ **Goal-biased**: Prefers directions toward enemy/item if visible
- ✅ **Simple**: 8 traces (45° apart) = low CPU cost
- ✅ **Deterministic**: Same room → same exit direction

### Movement Execution

**When feeler mode active**:
```c
if (feeler_mode_active) {
   float clear_yaw = Bot_FindClearestDirection(self);
   self.ideal_yaw = clear_yaw;
   changeyaw();  // Smooth turn toward clearest direction
   walkmove(self.ideal_yaw, 10);  // Move forward slowly (exploration pace)
}
```

**Speed**: Slow (50% normal speed) to avoid overshooting exits

**Turn rate**: Normal `changeyaw()` smoothing (already exists)

---

## 🍞 **Breadcrumb Waypoint System**

### When to Drop Breadcrumbs

**Trigger Condition**:
- Feeler mode active (bot is exploring)
- AND distance from last breadcrumb > 64 units

**Implementation**:
```c
// Entity field in defs.qc
.vector last_breadcrumb_pos;  // Track where we last dropped a crumb

// In feeler steering code (botmove.qc)
if (feeler_mode_active) {
   float dist_from_last = vlen(self.origin - self.last_breadcrumb_pos);

   if (dist_from_last > 64 || self.last_breadcrumb_pos == '0 0 0') {
      Bot_DropBreadcrumb(self);
      self.last_breadcrumb_pos = self.origin;
   }
}
```

### Breadcrumb Creation

**Function**: `Bot_DropBreadcrumb(entity bot)`

**Implementation**:
```c
void() Bot_DropBreadcrumb = {
   // Use existing SpawnSavedWaypoint function!
   // Format: SpawnSavedWaypoint(origin, traffic, danger, target)

   // Mark breadcrumbs with low traffic score (0.1) to distinguish from main paths
   SpawnSavedWaypoint(self.origin, 0.1, 0.0, "");

   // Optional: Debug logging at LOG_VERBOSE level
   if (bot_debug_enabled && bot_debug_level >= LOG_VERBOSE) {
      bprint("["); bprint(self.netname);
      bprint("] BREADCRUMB: Dropped at ");
      bprint(vtos(self.origin)); bprint("\n");
   }
}
```

**Breadcrumb Properties**:
- `classname = "BotPath"` (same as normal waypoints)
- `pathtype = DROPPED` (eligible for DumpWaypoints export)
- `traffic_score = 0.1` (low value = exploration path, not main route)
- `danger_scent = 0.0` (no danger history yet)
- `target = ""` (no button link)

**Why this works**:
- ✅ **Uses existing waypoint system** - no new entity type needed
- ✅ **Automatically exported** via DumpWaypoints (impulse 100)
- ✅ **A* pathfinding compatible** - bots can route through breadcrumbs
- ✅ **Persists between sessions** - copy DumpWaypoints output to maps/dm4.qc

### Breadcrumb Lifecycle

**1. Initial Exploration** (First bot in unfamiliar room)
- Bot enters room with no waypoints nearby
- Feeler mode activates (nearest waypoint > 128u)
- Bot scans 8 directions, finds clearest path (toward door)
- Moves toward door, dropping breadcrumbs every 64 units
- Trail created: Room center → Doorway

**2. Immediate Reuse** (Later in same session)
- Second bot enters same room
- Breadcrumbs now exist (spawned by first bot)
- A* pathfinding finds route through breadcrumbs
- Bot follows trail → exits efficiently (no feeler mode needed!)

**3. Permanent Learning** (Next session)
- At end of session, admin runs `impulse 100` (DumpWaypoints)
- Console outputs all waypoints including breadcrumbs
- Admin copies output to `maps/dm4.qc` (replaces old waypoint data)
- Next session loads with breadcrumbs as permanent waypoints
- Room navigation solved permanently!

---

## 🔗 **Integration with MRE Systems**

### Integration Point 1: Stuck Detection (botmove.qc)

**Current flow** (line 1466):
```c
if (stuck_count > 5) {
   // Desperate escape: train surf, rocket jump, super jump
}
stuck_count++;
```

**New flow** (feeler mode inserted):
```c
if (stuck_count > 3) {  // ⬅️ Earlier trigger (count=4)
   // ===== FEELER MODE: Exploration Escape =====
   if (!feeler_mode_active) {
      feeler_mode_active = TRUE;
      feeler_start_time = time;
   }

   // Use feeler steering to find exit
   float clear_yaw = Bot_FindClearestDirection(self);
   self.ideal_yaw = clear_yaw;
   changeyaw();

   if (walkmove(self.ideal_yaw, 10)) {
      // Movement succeeded - drop breadcrumb
      Bot_DropBreadcrumb(self);
      stuck_count = 0;  // Reset counter (moving again)
      return TRUE;
   }
   // ===== END FEELER MODE =====
}

if (stuck_count > 5) {
   // Feeler failed - escalate to desperate escape
   // (train surf, rocket jump, super jump)
}
stuck_count++;
```

**Result**: Feeler mode tries first (stuck_count 4-5), desperate escape is fallback (stuck_count 6+)

### Integration Point 2: Waypoint Navigation (botroute.qc)

**No changes needed!** Breadcrumbs use existing waypoint system:
- `SpawnSavedWaypoint()` creates breadcrumbs
- `FindAPath()` A* pathfinding includes breadcrumbs automatically
- `DumpWaypoints()` exports breadcrumbs with normal waypoints

### Integration Point 3: Goal Selection (botgoal.qc)

**When to activate feeler mode**:
```c
// In goal selection logic (botgoal.qc)
if (no_goal_found || nearest_waypoint > 128) {
   // Lost - activate feeler mode to explore
   feeler_mode_active = TRUE;
}
```

**Deactivate when goal found**:
```c
if (goal_acquired || nearest_waypoint < 64) {
   // Back on track - disable feeler mode
   feeler_mode_active = FALSE;
}
```

---

## 📁 **Required Code Changes**

### 1. Entity Fields (defs.qc)

Add feeler state tracking:
```c
// ===== FEELER STEERING + BREADCRUMBS =====
.float feeler_mode_active;      // TRUE when using feeler navigation
.float feeler_start_time;        // When feeler mode was activated
.vector last_breadcrumb_pos;     // Position of last dropped breadcrumb
```

### 2. Feeler Steering Functions (botmove.qc)

**New functions**:
- `float Bot_FindClearestDirection(entity bot)` - 8-direction scan, returns best yaw
- `void Bot_DropBreadcrumb()` - Spawns breadcrumb waypoint at current position
- `float Bot_ShouldActivateFeeler()` - Check if lost/stuck, no waypoints nearby

**Modified functions**:
- `trysidestep()` - Insert feeler mode before desperate escape (line 1466)

### 3. Debug Logging (botmove.qc)

Add LOG_VERBOSE events:
```c
[BotName] FEELER: Activated (no waypoints nearby)
[BotName] FEELER: Clearest direction = 135° (SE)
[BotName] BREADCRUMB: Dropped at '1024 512 64'
[BotName] FEELER: Deactivated (waypoint found)
```

---

## 📊 **Expected Results**

### Immediate Benefits (Same Session)

**Before Feeler System**:
- Bot enters unfamiliar room
- Wanders randomly (no waypoints)
- Gets stuck in corner
- Desperate escape: super jump (74 events per session)

**With Feeler System**:
- Bot enters unfamiliar room
- Feeler mode activates (no waypoints nearby)
- Scans 8 directions → finds doorway (clearest path)
- Moves toward door, dropping breadcrumbs
- **Next bot follows breadcrumbs → instant navigation!**

**Expected stuck reduction**: 74 → 30 events per session (60% reduction)

### Long-Term Benefits (After DumpWaypoints)

**Self-Improving Map Coverage**:
- Session 1: 343 waypoints (manual placement)
- Session 2: 343 + ~50 breadcrumbs (exploration trails)
- Session 3: 343 + ~80 breadcrumbs (more rooms explored)
- Session 10: 343 + ~200 breadcrumbs (**full map coverage!**)

**Emergent Behavior**:
- Bots "teach" the waypoint network new routes
- Rare rooms/corridors get coverage automatically
- No manual waypoint placement needed for new maps (just play!)

---

## 🎮 **Testing Plan**

### Phase 1: Feeler Steering Only (No Breadcrumbs)

**Goal**: Validate that 8-direction scan finds exits

**Test**:
1. Spawn bot in room with no waypoints (use `setpos` console command)
2. Enable LOG_VERBOSE logging (impulse 96)
3. Observe bot behavior:
   - Does feeler mode activate?
   - Does 8-direction scan find doorway?
   - Does bot move toward exit?
4. Check logs for FEELER events

**Success Criteria**:
- ✅ Bot finds exit within 5 seconds
- ✅ Bot moves toward clearest direction (not random)
- ✅ Logs show scan results and chosen direction

### Phase 2: Breadcrumb Dropping

**Goal**: Validate breadcrumbs spawn correctly

**Test**:
1. Enable feeler mode in unfamiliar room
2. Watch bot move toward exit
3. Check for breadcrumb waypoints (use `noclip` to fly around, look for entities)
4. Count breadcrumbs dropped (should be ~3-5 for 200u room)

**Success Criteria**:
- ✅ Breadcrumbs spawn every 64 units
- ✅ Breadcrumb classname = "BotPath"
- ✅ Breadcrumb traffic_score = 0.1
- ✅ Logs show BREADCRUMB events

### Phase 3: Breadcrumb Reuse

**Goal**: Validate second bot uses breadcrumbs

**Test**:
1. First bot explores room, drops breadcrumbs
2. Spawn second bot in same room
3. Observe: Does second bot follow breadcrumb trail?
4. Check: Does A* pathfinding route through breadcrumbs?

**Success Criteria**:
- ✅ Second bot doesn't activate feeler mode (uses breadcrumbs instead)
- ✅ Second bot exits room faster than first bot
- ✅ A* pathfinding includes breadcrumb nodes

### Phase 4: DumpWaypoints Persistence

**Goal**: Validate breadcrumbs export and reload

**Test**:
1. Play session with feeler mode, drop ~20 breadcrumbs
2. Run `impulse 100` (DumpWaypoints)
3. Copy console output to test file
4. Reload map
5. Verify breadcrumbs loaded correctly

**Success Criteria**:
- ✅ DumpWaypoints includes breadcrumbs
- ✅ Breadcrumb format matches normal waypoints
- ✅ Reloaded map has breadcrumb entities
- ✅ Bots use reloaded breadcrumbs

### Phase 5: Full Session Test

**Goal**: Measure stuck reduction

**Test**:
1. Play 10-minute deathmatch on dm4
2. Enable LOG_CRITICAL (stuck events only)
3. Let bots explore naturally
4. Count stuck events and breadcrumbs dropped

**Success Criteria**:
- ✅ Stuck events reduced from 74 to <40 per session
- ✅ Breadcrumbs dropped in unfamiliar areas
- ✅ Second bot entering same area uses breadcrumbs
- ✅ No crashes or infinite loops

---

## ⚠️ **Potential Issues and Solutions**

### Issue 1: Breadcrumb Spam

**Problem**: Bot drops too many breadcrumbs (every frame)

**Solution**: Distance check (64 unit minimum spacing)
```c
if (vlen(self.origin - self.last_breadcrumb_pos) > 64) {
   Bot_DropBreadcrumb(self);
}
```

### Issue 2: Feeler Mode Never Deactivates

**Problem**: Bot stuck in feeler mode forever

**Solution**: Timeout after 10 seconds
```c
if (time - feeler_start_time > 10.0) {
   feeler_mode_active = FALSE;  // Give up, try desperate escape
}
```

### Issue 3: Breadcrumbs in Bad Locations

**Problem**: Breadcrumbs dropped in dead ends or traps

**Solution**: Mark breadcrumbs with danger_scent when bot dies nearby
```c
// In bot death code (combat.qc)
entity nearby_crumb = find_radius(self.origin, 128, "BotPath");
if (nearby_crumb && nearby_crumb.traffic_score == 0.1) {
   nearby_crumb.danger_scent = 10.0;  // Warn future bots
}
```

### Issue 4: Entity Limit

**Problem**: Too many breadcrumbs (QuakeC has ~600 entity limit)

**Solution**: Breadcrumb culling after 100 spawned
```c
float breadcrumb_count = 0;

void() Bot_DropBreadcrumb = {
   breadcrumb_count++;

   if (breadcrumb_count > 100) {
      // Find oldest breadcrumb (lowest traffic) and remove it
      entity oldest = find_lowest_traffic_breadcrumb();
      remove(oldest);
      breadcrumb_count--;
   }

   SpawnSavedWaypoint(self.origin, 0.1, 0.0, "");
}
```

### Issue 5: Conflict with Desperate Escape

**Problem**: Feeler mode and super jump both active

**Solution**: Clear priority order
```c
if (stuck_count > 3 && stuck_count <= 5) {
   // Feeler mode (gentle exploration)
   Bot_FeelerSteering();
}
else if (stuck_count > 5) {
   // Desperate escape (train surf, RJ, super jump)
   Bot_DesperateEscape();
}
```

---

## 🎯 **Success Metrics**

### Quantitative Goals

| Metric | Before | Target | Measurement |
|--------|--------|--------|-------------|
| **Stuck events** | 74/session | <40/session | LOG_CRITICAL logs |
| **Room escape time** | ~10-15 sec | <5 sec | Manual observation |
| **Waypoint coverage** | 343 (manual) | 500+ (auto) | DumpWaypoints count |
| **Exploration rate** | Random wander | Directed search | Feeler activation rate |

### Qualitative Goals

- ✅ Bots look "smart" when lost (scan → move toward exit)
- ✅ Self-improving navigation (breadcrumbs accumulate over time)
- ✅ Zero manual waypoint placement for new rooms
- ✅ Emergent map learning (bots teach each other via breadcrumbs)

---

## 🚀 **Implementation Roadmap**

### Phase 1: Core Feeler Steering (2-3 hours)

**Tasks**:
1. Add entity fields to defs.qc (feeler_mode_active, etc.)
2. Implement `Bot_FindClearestDirection()` (8-direction scan)
3. Integrate into `trysidestep()` (activate at stuck_count=4)
4. Add debug logging (LOG_VERBOSE)

**Test**: Bot in unfamiliar room → finds exit via feeler steering

### Phase 2: Breadcrumb Dropping (1 hour)

**Tasks**:
1. Implement `Bot_DropBreadcrumb()` (call SpawnSavedWaypoint)
2. Add distance-based dropping (every 64 units)
3. Track last_breadcrumb_pos

**Test**: Bot drops breadcrumbs while exploring → visible in `noclip` mode

### Phase 3: Breadcrumb Reuse (1 hour)

**Tasks**:
1. Verify A* pathfinding includes breadcrumbs (should work automatically)
2. Test second bot follows breadcrumb trail
3. Measure stuck reduction

**Test**: Second bot in same room → uses breadcrumbs → exits faster

### Phase 4: Persistence (30 minutes)

**Tasks**:
1. Test DumpWaypoints exports breadcrumbs correctly
2. Reload map with breadcrumb waypoints
3. Verify breadcrumbs work after reload

**Test**: DumpWaypoints → reload → breadcrumbs persist

### Phase 5: Polish (1-2 hours)

**Tasks**:
1. Add breadcrumb culling (prevent entity spam)
2. Add danger_scent marking (avoid death traps)
3. Add timeout (deactivate feeler after 10s)
4. Tune parameters (scan distance, drop spacing)

**Test**: 10-minute session → stuck events <40, no crashes

**Total Estimated Time**: 5-7 hours

---

## 📝 **Comparison to Original Feeler Concept**

### What We're Using from Original Concept

✅ **8-direction scanning** - clearest path detection
✅ **Deterministic traces** - no physical entities
✅ **Bounded influence** - doesn't override goals
✅ **Cheap performance** - 8 traces, rate limited
✅ **Stuck detection integration** - escape mode trigger

### What We're NOT Using

❌ **Corridor centring** - not needed (waypoints handle this)
❌ **Racing line cornering** - not the problem we're solving
❌ **Speed scaling** - unnecessary complexity
❌ **Continuous steering** - only active when lost

### What We're ADDING (New!)

✨ **Breadcrumb waypoints** - self-improving navigation
✨ **Exploration trails** - bots teach each other
✨ **Waypoint system integration** - works with existing A* pathfinding
✨ **Persistent learning** - DumpWaypoints saves breadcrumbs

---

## 🎓 **Why This Design Works**

### Minimal Disruption
- Uses existing waypoint system (no new entity types)
- Only activates when waypoints unavailable (doesn't replace navigation)
- Integrates with existing stuck detection (feeler → desperate escape)

### Self-Improving
- First bot struggles (drops breadcrumbs)
- Second bot succeeds (follows breadcrumbs)
- Permanent learning (DumpWaypoints persistence)

### Scalable
- Works on any map (not dm4-specific)
- Auto-generates waypoints (no manual placement)
- Breadcrumb culling prevents entity spam

### Human-Like
- Looks intelligent (scans for exits)
- Learns from experience (breadcrumbs)
- Emergent behavior (map knowledge accumulates)

---

**Design Status**: Ready for Implementation
**Next Step**: Phase 1 - Core Feeler Steering (2-3 hours)
**Expected Impact**: 60% stuck reduction, self-improving navigation
**Risk Level**: LOW (non-invasive, uses existing systems)
