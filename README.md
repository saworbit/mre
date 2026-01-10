# 🤖 Modern Reaper Enhancements (MRE)

> **Bringing 90s Quake bots into the modern era with advanced AI, physics-based navigation, and human-like combat tactics**

[![Build](https://img.shields.io/badge/build-passing-brightgreen)]() [![Quake](https://img.shields.io/badge/Quake-1-brown)]() [![Bot AI](https://img.shields.io/badge/AI-Enhanced-blue)]()

**📂 Active Development:** All modern enhancements are in [`reaper_mre/`](https://github.com/saworbit/mre/tree/master/reaper_mre) — this is the primary codebase for MRE features.

---

## What is MRE?

Modern Reaper Enhancements is a heavily upgraded version of the classic **Reaper Bot** for Quake 1. Born from the legendary 1998 bot, MRE adds sophisticated AI systems, realistic physics navigation, and advanced combat tactics that make bots play like skilled human players.

### Why MRE?

- **Smarter AI** - Advanced decision-making, tactical positioning, and adaptive difficulty
- **Physics Mastery** - Rocket jumps, train surfing, platform prediction, and more
- **Human-like Play** - Predictive aim, weapon conservation, and strategic powerup denial
- **Modern Code** - Clean QuakeC with extensive documentation and modular design
- **Competitive Ready** - Skill-based mechanics from novice to pro-level play

---

## Latest Features (2026-01)

### Graph-Based Influence Map System (2026-01-10)

**NEW:** Bots now use tactical pathfinding with real-time danger/interest awareness!

The Influence Map System adds a dynamic tactical layer on top of the waypoint navigation graph. Instead of always taking the shortest path, bots now evaluate routes based on recent explosions, deaths, and powerup locations. High-health bots charge through danger zones while wounded bots route around them.

**Before:**
- ❌ Bots always take shortest path (Dijkstra algorithm)
- ❌ No awareness of danger zones (explosion sites, death locations)
- ❌ Repeatedly run through active combat hotspots
- ❌ Tactical decisions only at waypoint selection, not pathfinding

**After:**
- ✅ Waypoint-based danger/interest scoring (0-100 range)
- ✅ Lazy decay optimization (explosions fade over 10 seconds, interest over 20 seconds)
- ✅ Spatial propagation to neighbor waypoints (creates "danger zones")
- ✅ Health-based bravery: Low HP avoids danger like walls, high HP ignores it
- ✅ Visual debugging via `impulse 120` (red = danger, green = interest)

**How it works:**

**1. Event Hooks (Real-Time Influence)**
- **Explosions**: When rocket/grenade explodes, add danger influence = `damage × 0.5` at impact point
- **Deaths**: When bot/player dies, add danger influence = `30` at death location
- **Spatial Propagation**: Danger spreads to neighbor waypoints with 50% falloff

**2. Lazy Decay (Performance Optimization)**
- Influence values stored on waypoints, only recalculated when queried
- **Danger decay**: -10 points per second, cutoff at 10 seconds
- **Interest decay**: -5 points per second, cutoff at 20 seconds
- Zero frame overhead when no influence events active

**3. Health-Based Bravery (Tactical Decision-Making)**
- **Low HP** (<50 HP): 10× multiplier → danger zones become impassable walls
- **Medium HP** (50-80 HP): 2× multiplier → normal danger avoidance
- **High HP** (>80 HP): 0.5× multiplier → charges through danger zones

**4. A* Pathfinding Integration**
```
edge_cost += (current_danger × bravery_multiplier)
```
- Wounded bot: 50 danger × 10 = +500 cost (blocks path)
- Healthy bot: 50 danger × 0.5 = +25 cost (minor penalty)

**Usage:**
```
impulse 120       // Show influence map (red particles = danger, green = interest)
developer 1       // Enable to see influence calculations in console
```

**Debug Output (Console):**
```
Influence map displayed for 5 seconds.
Red particles = Danger zones (explosions/deaths)
Green particles = Interest zones (powerups/sounds)
Particle intensity = Influence strength (0-100)
```

**Technical Details:**
- **Graph-based**: Uses existing waypoint network, not 2D grid (performance)
- **Linear decay**: Simpler than exponential for QuakeC performance
- **FindClosestWaypoint()**: O(N) scan of all BotPaths to apply influence
- **Propagation**: Spreads to movetarget1-4 neighbors with 50% falloff
- **Particle visualization**: Red (color 73), green (color 115), count scales 5-50

### Door Solver System (2026-01-10)

**NEW:** Bots intelligently distinguish between "Touch" buttons and "Shoot" buttons!

The Door Solver System adds intelligent button/door handling. Bots now understand the difference between shootable buttons (requiring aim and fire) and touch buttons (requiring navigation). This eliminates false navigation to remote-activated buttons and enables proper door puzzle solving.

**Before:**
- ❌ Bots navigate to ALL buttons, even shootable ones
- ❌ No remote door activation via shooting buttons
- ❌ Simple emergency brake when blocked by door
- ❌ Can't solve button→door puzzles

**After:**
- ✅ Three-case logic: Destructible door → attack it, Shootable button → aim and fire, Touch button → navigate to it
- ✅ Line-of-sight checks before shooting
- ✅ Goal stack preservation (saves current goal, resumes after door opens)
- ✅ Proper aim calculation with pitch/yaw adjustment

**How it works:**

**1. Find Button for Blocked Door**
- When bot collides with door/plat/train, call `FindButtonForDoor(door_ent)`
- Returns the button entity that targets this specific door

**2. Three-Case Decision Logic**

**Case A: No Button Found (Destructible Door)**
```c
if (button == world && door.health > 0)
{
   self.enemy = door;
   self.th_missile();  // Attack the door directly
}
```

**Case B: Shootable Button (Remote Activation)**
```c
if (button.health > 0)
{
   traceline(self.origin + view_ofs, button.origin, TRUE, self);
   if (trace_fraction == 1.0)  // Can see button
   {
      aim_ang = vectoangles(button.origin - self.origin);
      self.ideal_yaw = aim_ang_y;
      self.ideal_pitch = aim_ang_x;
      ChangeYaw(); ChangePitch();
      self.button0 = 1;  // Fire!
   }
}
```

**Case C: Touch Button (Navigation Required)**
```c
Stack_Push();  // Save current goal
self.goalentity = button;  // Navigate to button
```

**Usage:**
- Just play! System activates automatically when bot encounters doors
- Watch bots shoot distant buttons instead of running to them
- Bots save their current goal and resume after opening doors

**Technical Details:**
- **Button discovery**: `FindButtonForDoor()` searches all entities with matching `target` field
- **LOS check**: `traceline()` prevents shooting through walls
- **Aim calculation**: `vectoangles()` converts position delta to angles
- **Goal preservation**: Stack-based goal management prevents forgetting original objective

### Stair/Teleporter Navigation Fixes (2026-01-10)

**NEW:** Bots smoothly climb stairs without getting stuck and actively navigate onto teleporter pads!

Two critical navigation fixes eliminate stuck issues on steps and spawn pads. Enhanced stair climbing with proper hop velocity handles multi-step configurations, while vertical stuck detection prevents false triggers during climbing. Teleporter pad navigation actively centers bots on trigger volumes.

**Before:**
- ❌ Bots get stuck on consecutive stairs (hop velocity too weak)
- ❌ Stuck detection falsely triggers during vertical movement
- ❌ Bots shuffle around edges of teleporter pads without entering

**After:**
- ✅ Increased trace height (22→30 units) detects taller stairs
- ✅ Increased hop velocity (210→270 units) enables smooth multi-step climbing
- ✅ Vertical progress tracking (8 unit threshold) counts climbing as valid progress
- ✅ Active teleporter navigation aims for center and gives small hop

**How it works:**

**1. Enhanced Stair Smoothing**
```c
// Check 30 units up (was 22) for multi-step detection
step_trace_dest_z = self.origin_z + 30.0;
traceline(self.origin + '0 0 30', step_trace_dest, TRUE, self);

if (trace_fraction == 1.0)  // Knee-height clear
{
   self.velocity_z = 270.0;  // Full jump hop (was 210)
}
```
- **Taller detection**: 30-unit trace catches multi-step stairs
- **Proper hop**: 270 velocity matches standard jump for consecutive steps

**2. Vertical Stuck Detection**
```c
// Check both horizontal AND vertical progress
horiz_moved = vlen(self.origin_xy - self.last_origin_xy);
vert_moved = fabs(self.origin_z - self.last_origin_z);

if (horiz_moved > 12.0 || vert_moved > 8.0)  // EITHER counts
{
   self.last_progress_time = time;  // Not stuck!
}
```
- **Before**: Only horizontal movement counted → stair climbing = "stuck"
- **After**: Vertical movement counts too → stair climbing = valid progress

**3. Teleporter Pad Navigation**
```c
// When blocked, search nearby for teleporter
nearby_tele = findradius(self.origin, 128.0);
while (nearby_tele)
{
   if (nearby_tele.classname == "trigger_teleport")
   {
      // Aim for center and hop onto it
      self.ideal_yaw = vectoyaw(nearby_tele.origin - self.origin);
      ChangeYaw();
      self.velocity_z = 200.0;  // Small hop onto trigger
      return;
   }
}
```
- **Pattern detection**: Finds teleporter within 128 units when stuck
- **Active navigation**: Aims for center, gives hop to enter trigger volume
- **Immediate return**: Prevents other stuck handling from interfering

**Debug Output (LOG_CRITICAL):**
```
[Toxic] STAIR-SMOOTH: Detected multi-step at (2176,512), hop=270
[Karen] VERT-PROGRESS: Moved 12u vertically (counts as progress)
[Wanton] TELE-NAV: Aiming for trigger_teleport at (512,256)
```

**Technical Details:**
- **Stair trace height**: 30 units (matches player step_height + margin)
- **Hop velocity**: 270 units (standard jump, enables 2-3 consecutive steps)
- **Vertical threshold**: 8 units (balances noise vs real climbing)
- **Horizontal threshold**: 12 units (reduced from 16 to balance with vertical)
- **Teleporter radius**: 128 units (catches nearby pads without false positives)

### Projectile Prediction Enhancements (2026-01-10)

**NEW:** Bots now accurately hit targets on moving platforms with skill-based accuracy!

The Projectile Prediction System has been enhanced with moving platform compensation and skill-based accuracy degradation. All bots now use the quadratic prediction solver (previously only nightmare bots), but lower-skill bots get random inaccuracy added to create human-like miss rates.

**Before:**
- ❌ Bots miss targets riding moving trains/platforms
- ❌ Sharp discontinuity: Skill 0-2 use simple leading, Skill 3 use quadratic
- ❌ No visual feedback for prediction quality
- ❌ Lower-skill bots are "dumb" (wrong algorithm), not "inaccurate"

**After:**
- ✅ Moving platform velocity compensation (trains, elevators, doors)
- ✅ All skill levels use quadratic prediction (enables platform support)
- ✅ Smooth accuracy progression: 35% → 42% → 85% → 100%
- ✅ Debug visualization shows prediction quality (blue=perfect, yellow=degraded)

**How it works:**

**1. Moving Platform Compensation**
```c
if ((targ.flags & FL_ONGROUND) && targ.groundentity)
{
    if (groundentity is func_train/func_door/func_plat)
    {
        v = targ.velocity + groundentity.velocity;  // Add platform motion
    }
}
```
- Detects when target is standing on moving entity
- Adds platform velocity to target's walking velocity
- Quadratic solver predicts intercept with combined motion
- Result: Perfect rockets on DM2 trains, E1M1 platforms, elevators

**2. Skill-Based Accuracy Degradation**
```c
// Skill 0: 70u offset (~8° cone, 35% accuracy)
// Skill 1: 50u offset (~6° cone, 42% accuracy)
// Skill 2: 15u offset (~2° cone, 85% accuracy)
// Skill 3: 0u offset (perfect aim, 100% accuracy)
```
- Perfect aim calculated via quadratic solver
- Random 3D offset added based on skill level
- Offset scales with distance (consistent angular error)
- Result: Lower-skill bots miss realistically, nightmare bots rarely miss

**3. Debug Visualization** (`impulse 95` required)
- **Blue particles**: Perfect prediction path (nightmare bots)
- **Yellow particles**: Degraded aim path (lower-skill bots)
- **Particle trail**: 10 particles from bot to predicted impact point
- **Impact marker**: Cluster of particles at predicted hit location

**Usage:**
```
impulse 95        // Enable bot debug mode
map dm2           // Load DM2 (has moving train)
impulse 208       // Spawn bots (×4)
noclip            // Fly around to see particle trails
```

**Debug Output (Console):**
```
Blue particle trail → Nightmare bot shooting at moving target
Yellow particle trail → Novice bot shooting with random offset
Impact cluster → Where rocket will hit (if prediction correct)
```

**Accuracy by Skill Level:**

| Skill | Offset | Cone | Accuracy | Usage |
|-------|--------|------|----------|-------|
| 0 | 70 units | ~8° | 35% | Novice (easy to beat) |
| 1 | 50 units | ~6° | 42% | Beginner (learning) |
| 2 | 15 units | ~2° | 85% | Skilled (challenging) |
| 3 | 0 units | 0° | 100% | Nightmare (perfect) |

**Moving Platform Scenarios:**

**DM2 Train:**
- Old: Rockets miss players riding train (only compensates walking)
- New: Rockets lead train velocity + player strafe (full motion)

**E1M1 Platform Lift:**
- Old: Bots shoot where target was, not where they're going
- New: Bots predict lift velocity and intercept perfectly

**Technical Details:**
- **Platform detection**: Checks `groundentity.classname` for func_train/door/plat
- **Velocity addition**: `v = targ.velocity + groundentity.velocity`
- **Quadratic solver**: Already implemented in `PredictAim()` (botmath.qc:69-174)
- **Degradation formula**: `degraded_aim = normalize((perfect_aim × 500) + random_offset)`
- **Particle colors**: Blue=203 (perfect), Yellow=224 (degraded)

### Dynamic Breadcrumbing System (2026-01-10)

**NEW:** Bots now have short-term position memory for intelligent stuck recovery!

The Dynamic Breadcrumbing System gives bots a "Hansel & Gretel" trail of recent valid positions. When stuck in geometry, knocked off-path by explosions, or wedged in corners, bots can backtrack to a known safe location instead of running into walls repeatedly.

**Before:**
- ❌ Bots stuck in corners run forward endlessly (feeler escape only moves forward)
- ❌ Bots knocked off ledges stand below staring at unreachable waypoints
- ❌ Explosion knockback puts bots in geometry traps with no reverse option
- ❌ Only forward-facing escape attempts (8-direction feeler scan)

**After:**
- ✅ Bots remember last 5 valid positions (~2.5 seconds of history)
- ✅ Stuck recovery first tries backtracking, then feeler escape
- ✅ Corner wedges: walks back to position 1 second ago (known valid spot)
- ✅ Ledge falls: retraces to ramp/stairs used recently
- ✅ Complements existing feeler system (not a replacement)

**How it works:**

**1. Position Recording** (Automatic, 2Hz rate)
```
Every 0.5 seconds during normal movement:
  - Check if bot is on ground (not falling)
  - Check if position is safe (not in lava/slime)
  - Store position in ring buffer (5 slots)
  - Overwrite oldest position when full
```
- **Coverage**: Last 5 positions = ~2.5 seconds of movement history
- **Safety**: Only records safe, grounded positions (no hazards)
- **Performance**: 2Hz rate limit (not per-frame overhead)

**2. Stuck Detection & Recovery**
```
When bot gets stuck:
  1. Scan breadcrumb ring buffer for valid recovery spot
  2. Check line-of-sight to each breadcrumb (can't path through walls)
  3. Find nearest reachable breadcrumb (>64 units away, not too close)
  4. If found: Enter "retrace mode" and walk back to that position
  5. If not found: Fall back to feeler-based forward escape
```

**3. Retrace Mode**
```
While in retrace mode:
  - Bot aims toward rescue spot (ideal_yaw)
  - Exits when moving fast again (velocity >200 u/s)
  - Exits when timeout expires (0.6-1.2 seconds)
  - Returns to normal navigation after escape
```

**Real-World Scenarios:**

**Corner Wedge Escape:**
```
Bot wedged in corner geometry → Can't move forward
  1. Breadcrumb system finds position from 1 second ago
  2. Bot enters retrace mode, turns around
  3. Walks back to that known-valid position
  4. Resumes normal navigation from safe spot
```

**Ledge Fall Recovery:**
```
Bot falls off catwalk → Standing below, can't reach waypoint above
  1. Breadcrumb finds position on catwalk from 2 seconds ago
  2. Bot realizes "I was up there recently, how did I get there?"
  3. Backtracks toward ramp/stairs used to reach catwalk
  4. Successfully navigates back up
```

**Explosion Knockback:**
```
Bot knocked into geometry trap by rocket → Normal path blocked
  1. Breadcrumb finds pre-explosion position
  2. Bot backtracks to where it was before knockback
  3. Avoids running into new walls from displacement
  4. Returns to familiar navigation area
```

**Debug Output** (`impulse 95` for LOG_CRITICAL):
```
[BotName] UNSTICK: Breadcrumb backtrack to '64 128 24' (dist=187.3)
[BotName] UNSTICK: Breadcrumb retrace complete (vel=234.5)
```

**Technical Details:**
- **Ring buffer**: 5 vector fields (crumb_pos_0 through crumb_pos_4)
- **Sample rate**: 0.5 seconds (2Hz) via crumb_timer field
- **Distance threshold**: Ignores breadcrumbs <64 units (too close, useless)
- **LOS check**: Traceline ensures breadcrumb is reachable (not behind walls)
- **Exit velocity**: Retrace ends when bot velocity >200 u/s (moving freely)
- **Timeout**: 0.6-1.2 seconds max retrace duration (prevents infinite backtrack)
- **Complementary**: Works alongside feeler escape (breadcrumb first, feeler fallback)

**Usage:**
```
impulse 95        // Enable bot debug (shows backtrack attempts)
impulse 208       // Spawn bots (×4)
// Play for a few minutes, bots will get stuck occasionally
// Console shows: "UNSTICK: Breadcrumb backtrack to..." when activated
```

**Why 5 positions?**
- **2.5 seconds of history** (5 × 0.5s samples) is enough to escape local geometry traps
- **Not too much memory** (5 vectors = 60 bytes per bot)
- **Covers common scenarios**: Corner wedges (1s ago), ledge falls (2s ago), knockbacks (1-2s ago)

**Integration with Existing Systems:**
- **Feeler Escape**: Breadcrumb backtracking is tried FIRST, feeler forward escape is FALLBACK
- **Progress Tracking**: Breadcrumb recording happens during `Bot_ProgressTick()` (automatic)
- **Bad Spot Avoidance**: Breadcrumbs complement the bad_spot memory system (different timescales)
- **Unstick Mode**: Retrace mode is a new substage of BOT_MODE_UNSTICK

### Randomized Bot Spawning (2026-01-10)

**NEW:** Bot spawning is now randomized with duplicate avoidance for variety in matches!

When using `impulse 205` (spawn 1 bot) or `impulse 208` (spawn 4 bots), the system now randomly selects from the full roster of 36 bot personalities instead of always spawning them in sequential order.

**Before:**
- ❌ Always spawned bots in same order: Reaper → Omicron → Toxic → Karen...
- ❌ Predictable matchups every session
- ❌ Same bot colors and personalities every time

**After:**
- ✅ Random selection from 36 bot profiles on each spawn
- ✅ Duplicate avoidance checks last 8 spawns (prevents immediate repeats)
- ✅ Retry logic (up to 20 attempts) ensures variety
- ✅ Different matchups every session for fresh gameplay

**How it works:**
1. Player uses `impulse 205` or `impulse 208` to spawn bot(s)
2. System generates random ID (1-36) for each bot
3. Checks last 8 spawns to avoid immediate duplicates
4. Retries random selection if duplicate found (max 20 attempts)
5. Assigns randomly selected identity (name, colors, personality, skill)

**Example spawn sequences:**
- Session 1: Thresh → Camper → DoomGuy → Omicron
- Session 2: Zeus → Frog → Terminator → Slash
- Session 3: Bitterman → Toxic → Oak → Gladiator

**Technical Details:**
- **Random selection**: `random() * 36.0` generates uniform distribution across all bot IDs
- **Duplicate tracking**: 8-entry ring buffer maintains spawn history
- **Retry limit**: 20 attempts prevents infinite loops if roster exhausted
- **Identity mapping**: `Bot_AssignIdentity()` maps ID to name/colors/personality/skill
- **Debug output**: `dprint()` shows selected ID and retry attempts (requires `developer 1`)

### Directional Fail Memory (2026-01-10)

**NEW:** Bots remember failed approach angles and avoid repeating the same mistakes!

The Directional Fail Memory system tracks position + yaw combinations that led to stuck situations or unreachable goals. Bots now avoid retrying failed approaches, eliminating the classic "staring at armor behind bars" loop.

**Before:**
- ❌ Bots repeatedly try the same angle at bars/corners
- ❌ Loop indefinitely between 2-3 failed directions
- ❌ Fixate on unreachable items every 5 seconds

**After:**
- ✅ 6-entry ring buffer tracks failed approaches (32-unit grid, 30° yaw buckets)
- ✅ -500 point penalty for previously failed directions (strong avoidance with "last resort" fallback)
- ✅ 20-second memory duration (TTL) prevents rapid re-selection of unreachable goals
- ✅ Duplicate prevention stops wasting buffer slots on same failures
- ✅ Works in both goal fixation (bars/greebles) and unstick scenarios (corners/tight spaces)

**How it works:**
1. Bot tries approaching item at 90° → Gets stuck/fixated
2. System records: `(position: 2144,-2176) + (yaw: 90°) → FAIL`
3. Bot tries 45° → Also fails → Recorded
4. Bot evaluates feelers: 90° gets -500 penalty, 45° gets -500 penalty
5. Bot tries 135° instead → Success! Escapes area

**Debug Output (LOG_VERBOSE):**
```
[Karen] FAIL-MEM: Record yaw=95° at (2144,-2176)
[Karen] FIXATE: Avoid goal item_armor2
[Karen] FAIL-MEM: Penalty -500 for yaw=105°  ← Within 30° bucket
```

**Technical Details:**
- **Position quantization**: 32-unit grid prevents noise
- **Yaw bucketing**: 30° buckets catch similar angles (85° and 95° both penalized)
- **Proximity check**: 96-unit radius determines "same location"
- **Heavy penalty**: -500 points (typical feeler scores 150-400) strongly discourages retries
- **Fallback safety**: Bots can still pick penalized directions if ALL options are bad (prevents stuck detection death spiral)

### Shallow Water Trap Escape (2026-01-10)

**NEW:** Bots detect and escape "ankle water" boundary oscillation using gradient-based pathfinding!

In Quake, shallow water areas (waterlevel == 1) with recessed lips cause bots to get stuck bouncing at the boundary, unable to step out cleanly. This is especially common on classic maps like DM2.

**The Problem:**
- ❌ Bots enter shallow water, hit recessed exit lip
- ❌ waterlevel flickers between 0↔1 causing boundary jitter
- ❌ Movement code can't reliably step over small lip
- ❌ Bot oscillates forever at water's edge

**The Solution:**
- ✅ Detects pattern: `waterlevel == 1` + no progress for 1.8s
- ✅ Samples 7 directions using "highest ground" heuristic
- ✅ Integrates with directional fail memory (avoids previously failed escape attempts)
- ✅ Commits to escape direction for 1.2 seconds (prevents boundary re-entry jitter)
- ✅ Conditional gating: Only checks when bot is actually in water (zero overhead on dry land)

**How it works:**
1. Bot stuck in ankle water for 1.8s → Pattern detected
2. System samples 7 directions, traces ground height 160 units ahead
3. Scores each direction: `height × 0.01 + clearance - fail_memory × 0.0016`
4. Picks direction with highest ground (likely exit path)
5. Records attempt in fail memory, commits for 1.2s to avoid jitter
6. If still stuck after commit expires, tries different direction next time

**Debug Output (LOG_CRITICAL):**
```
[Toxic] WATER-TRAP: Detected at (2176,-448) (waterlevel=1, no progress for 2.1s)
[Toxic] WATER-ESCAPE: Best direction yaw=45° score=1.82
[Toxic] WATER-TRAP: Escape commit yaw=45° until t=125.4
```

**Technical Details:**
- **Ground sampling**: Traces down 256 units to find floor height
- **7-ray pattern**: 0°, ±25°, ±60°, ±90° from current heading
- **Clearance threshold**: Skips directions with <60% clearance
- **Commit duration**: 1.2 seconds prevents boundary re-entry
- **Performance**: Conditional check (`waterlevel > 0`) keeps dry-land overhead at zero

### AI Cameraman Upgrades (2026-01-10)

**NEW:** Spectator camera now features smooth motion interpolation, occlusion awareness, and intelligent framing!

The AI Director (`impulse 99`) has been upgraded from simple attachment logic to cinematic-quality camera work with three major improvements.

**The Problems:**
- ❌ Camera jitters when bot physics updates at different rate than framerate
- ❌ Camera tracks bots behind walls (stares at boring geometry)
- ❌ Camera clips into walls in tight corridors (over-the-shoulder view buried in geometry)

**The Solutions:**
- ✅ **Motion Smoothing**: Exponential decay interpolation decouples camera from bot physics tick rate
- ✅ **Occlusion Awareness**: Visibility checks prevent tracking bots behind walls
- ✅ **Intelligent Framing**: Multi-candidate positioning probes for clear viewing angles

**How it works:**

**1. Motion Smoothing (Anti-Jitter)**
- Camera position interpolates using `CamLerpVector()` with frametime-based smoothing
- Angle tracking uses 8× frametime multiplier for responsive action tracking
- Smoothness varies by mode:
  - Fixed/Death: 2.0 (slow, dramatic drifts)
  - Flyby: 4.0 (cinematic follow)
  - Combat: 10.0 (fast action tracking)

**2. Occlusion Awareness (No Wall-Staring)**
- `CamActionScore()` traces line-of-sight from camera to bot before scoring
- Can't see target → score = 0 (forces director to pick visible action)
- Exception: Quad-wielding or high-frag leaders (15+ frags) get -500 penalty but still considered
- Mid-range combat (100-600u) gets +100 bonus for cinematic value
- Rocket launcher combat gets +50 priority

**3. Intelligent Framing (Smart Positioning)**
- `CamFlybyTarget()` probes 3 candidate positions:
  1. Over-the-shoulder (right): 150u behind, 40u up, 40u right
  2. Over-the-shoulder (left): If right is blocked by wall
  3. High angle (fallback): 80u up, 60u back for cramped spaces
- If ceiling hit, backs off 10u from wall to avoid clipping

**Usage:**
```
impulse 208       // Spawn bots (repeat 3-4×)
impulse 99        // AI Director (auto-tracking with occlusion awareness)
impulse 50        // Flyby mode (cinematic orbiting with smart positioning)
impulse 51        // Follow mode (over-shoulder with smooth interpolation)
```

**Technical Details:**
- **Frametime-based interpolation**: `f = smooth_speed × frametime` (clamped to 1.0)
- **Angle normalization**: `CamReAngle()` prevents 0°→360° wrap-around snapping
- **Pitch clamping**: ±80° prevents awkward upside-down views
- **LOS trace**: `traceline(camera, bot, TRUE, camera)` checks occlusion
- **Multi-candidate probing**: `traceline(bot, candidate_pos, TRUE, bot)` finds clear shots

### Vertical Tactics: Platform Stalemate Fix (2026-01-10)

**NEW:** Bots no longer get stuck in vertical alignment loops under/over enemies on platforms!

Classic problem: Two bots separated vertically (one on platform, one below) both try to minimize horizontal distance, resulting in perfect X/Y stacking with zero tactical value. Neither can shoot cleanly, both become predictable.

**The Problem:**
- ❌ Bot A on platform, Bot B below → both move to minimize XY distance
- ❌ Both end up at same X/Y coordinates with only Z separation
- ❌ Platform geometry blocks line-of-sight for both bots
- ❌ No one repositions → stalemate continues indefinitely
- ❌ Decision system keeps reselecting "get closer" because XY error metric doesn't punish vertical obstruction

**The Solution:**
- ✅ **Vertical Mode Detection**: Triggers when Z separation >96u AND no line-of-sight
- ✅ **Alignment Penalty**: Moving closer when already under/over enemy gets -100 penalty
- ✅ **Ring Distance Reward**: Moving toward 256u "angle distance" gets +50 bonus
- ✅ **Integrated Scoring**: Vertical penalty applied in combat feeler evaluation

**How it works:**
1. `VT_VerticalMode()` checks: `fabs(dz) > 96u` AND `!HasLOS()` → Vertical tactics active
2. For each movement candidate, `VT_VertPenalty()` predicts XY distance after move
3. If moving closer when already <160u away → Apply -100 penalty (scaled to -100pts in scoring)
4. If moving toward 256u "ring distance" → Apply +50 reward (optimal angle positioning)
5. Bot backs off to get shooting angles instead of camping under platform

**Debug Output (LOG_TACTICAL):**
```
[Wanton] VERTICAL-MODE: Active (dz=128u, no LOS)
[Wanton] VERT-PENALTY: -100 for moving closer (XY 140u → 110u)
[Wanton] VERT-REWARD: +50 for angle positioning (XY 140u → 245u)
```

**Technical Details:**
- **LOS check**: `traceline(bot+16u, enemy+16u, TRUE, bot)` at waist height
- **Prediction**: Flattens moveDir to XY plane, projects 160u ahead
- **Ring distance**: 256u empirically determined as optimal for most weapons
- **Integration**: Runs after pitch/under/rocket penalties in `Bot_Feelers_Evaluate()`

### Behavioral Loop Detection (2026-01-10)

**NEW:** Bots detect and break repetitive movement patterns (circles, bouncing, yaw flips)!

Classic problem: Bots get into behavioral loops where they repeat the same actions despite making no progress. Common patterns include tiny circles, repeated yaw flips (90°↔270°), and edge bouncing.

**The Problem:**
- ❌ Bot circles in same 64u area repeating identical moves
- ❌ Yaw flips between two angles every 0.5s (180° oscillation)
- ❌ Bounces into same edge/corner repeatedly
- ❌ Decision system thinks it's "trying" but has no hard signal of behavioral repetition
- ❌ Stuck detection only triggers on position freeze, not movement loops

**The Solution:**
- ✅ **State Signature Buffer**: 6-sample ring buffer tracks position cell + yaw bucket every 0.25s
- ✅ **Loop Detection**: 4/6 matching signatures = behavioral loop detected
- ✅ **Forced Unstick**: Triggers unstuck mode for 1.2s to escape pattern
- ✅ **Fail Memory Integration**: Records failed direction before breaking loop

**How it works:**
1. Every 0.25s, `Loop_PushSig()` creates signature from bot state:
   - Position: 32-unit grid cell (e.g., `2144,-2176`)
   - Yaw: 30° bucket (0-11, e.g., yaw 95° → bucket 3)
   - Packed into float: `cellX × 100000 + cellY × 100 + yawBucket`
2. `Loop_InLoop()` checks if 4+ of last 6 signatures match
3. If loop detected → `Loop_BreakLoop()`:
   - Records current direction as failed approach
   - Forces `BOT_MODE_UNSTICK` for 1.2s
   - Clears feeler commit to allow new direction selection
4. Unstuck system takes over, picks escape route

**Debug Output (LOG_CRITICAL):**
```
[Cheater] LOOP-BREAK: Detected repetitive behavior at (2144,-2176), forcing reposition
[Cheater] FAIL-MEM: Record yaw=95° at (2144,-2176)
```

**Technical Details:**
- **Signature interval**: 0.25s prevents noise from micro-movements
- **Grid quantization**: 32-unit cells match directional fail memory resolution
- **Yaw buckets**: 30° buckets (12 total) catch similar angles
- **Detection threshold**: 4/6 same = 67% repetition (1.5s window)
- **Integration**: Called in `Botmovetogoal()` right after progress tick

### Vertical Awareness: Smooth Cliff Navigation (2026-01-10)

**NEW:** Bots treat cliffs/voids as obstacles during steering (prediction vs reaction) and use soft emergency braking!

Classic problem: Feeler steering only sees horizontal walls, treats cliffs as "open space" until emergency brake triggers. This causes stuttering/vibration at edges as bot alternates between "move forward" and "STOP" commands.

**The Problem:**
- ❌ Feelers trace horizontal clearance, don't check floor below
- ❌ Cliff edge appears as "clear path" to steering system
- ❌ Bot moves forward → CheckForHazards sees void → `velocity = 0 0 0` (freeze)
- ❌ Next frame: steering says "go" → hazard check says "stop" → vibration loop
- ❌ Camera jitters, bot appears indecisive, stuck at edges

**The Solution:**
- ✅ **Floor Quality Check**: After each feeler trace, checks ground 256u below endpoint
- ✅ **Steer-Repulsive Voids**: Cliffs get quality = 0.0 (treated as walls in steering)
- ✅ **Passable Drops**: Big drops (>64u) get quality = 0.8 (slight penalty, freely passable)
- ✅ **Soft Emergency Brake**: Decelerate 90% + backward nudge instead of freeze

**How it works:**

**1. Predictive Cliff Detection (`Bot_CheckFloorQuality`)**
- For each feeler endpoint (if horizontal trace was clear):
  - Trace down 256u to find floor
  - **Void/Death Pit**: `return 0.0` (lava, slime, or no floor)
  - **Big Drop** (>64u): `return 0.8` (minor fall damage OK, flow > caution)
  - **Safe Ground**: `return 1.0`
- Effective score: `trace_fraction × floor_quality`
  - `1.0 × 0.0 = 0.0 < 0.55` → Blocked (void)
  - `1.0 × 0.8 = 0.8 > 0.55` → Passable (drop)
  - `1.0 × 1.0 = 1.0 > 0.55` → Clear (level)

**2. Smooth Edge Handling (`CheckForHazards`)**
- Old: `velocity = '0 0 0'` → Hard freeze → stuttering
- New:
  ```c
  velocity = velocity × 0.1       // 90% deceleration
  velocity += v_forward × -50     // Backward nudge
  ```
- Result: Bot "catches itself" at edge with momentum preserved

**Why This Works:**
- **Prediction**: Bot sees cliff 200u ahead, steers away naturally (like corridor walls)
- **Reaction**: If emergency brake still triggers, soft deceleration prevents freeze
- **Camera**: Continuous curve motion instead of stop-and-go snapping
- **Flow**: Minor fall damage (drops >64u) < being predictable sitting duck

**Debug Output (LOG_CRITICAL):**
```
[Toxic] HAZARD: Edge Catch (soft stop)
```

**Technical Details:**
- **Floor trace depth**: 256u matches standard hazard check depth
- **Drop threshold**: 64u (fall damage ~10-15 HP, acceptable tradeoff for mobility)
- **Quality tuning**: 0.8 chosen to pass 0.55 threshold while still penalizing vs level ground
- **Soft brake**: 0.1 multiplier leaves 10% velocity for smooth physics response
- **Integration**: Floor quality checked in `Bot_SampleFeelers()`, soft brake in `CheckForHazards()`

### Combat Reposition + Verticality-Aware Pursuit (2026-01-08)

**NEW:** Bots stop "shadow chasing" directly under higher targets and reposition to shootable angles.

This update separates combat movement from distance chasing. When the enemy is above/below and LOS/pitch is poor, bots enter a short reposition window, using scored feeler candidates that account for LOS, pitch, and under-target penalties.

**Before:**
- Bots minimized 2D distance and stood directly under enemies
- Poor pitch/LOS led to stalled fights and bad deaths

**After:**
- Under-target penalty prevents standing beneath elevated enemies
- LOS + pitch scoring rewards shootable positions
- Short reposition commits (0.6-1.2s) to avoid thrash
- Weapon-aware range bias keeps engagements in effective bands
- Vertical disadvantage triggers elevation-seeking feelers and a short break-contact fallback
- Multi-point LOS scoring, ledge risk penalty, pad/lift memory, and post-teleport bias refine local picks
- Hazard-aware feeler scoring and jump landing checks prevent lava hops without a safe landing, with escape bias from hazard edges (logs when blocked)
- Goal fixation avoidance skips unreachable items and blends steering for smoother local turns
- Hazard bad-spot marking and small goal-selection jitter reduce lava-edge loops

**Debug Output (LOG_TACTICAL+):**
```
[Wanton] REPOS: Enter (score=457.6, pitch=308, dz=-320, dh=281.2)
[Wanton] REPOS: Exit
```

### Unified Feeler Scoring + Progress-Based Unstick (2026-01-08)

**NEW:** Feelers now return scored candidates with action hints; the controller only commits to a choice.

**Highlights:**
- Ranked candidate scoring (clearance, widen, future space, loop/bad-spot penalties)
- Jump/step/tight-gap hints from feelers
- Progress-based stuck detection with short commit windows + cooldown (0.2s tick / 16u threshold / 1.0s limit)
- Target switching cooldown (1.6s) + scan interval tuning (3.0s) to reduce churn
- Goal fixation avoidance (1.5s stall / 5s TTL) for unreachable items

**Debug Output (LOG_CRITICAL+):**
```
[Drooly] UNSTICK: Enter mode (score=297.6, age=0.8, jump=0, tight=0, clear=160, widen=120, heat=0)
[Drooly] UNSTICK: Exit to cooldown
```

### Obot-Style Elevator Navigation System (2026-01-08)

**NEW:** Bots now intelligently handle elevator platforms with dynamic pathfinding!

The Elevator Navigation System implements Obot's proven two-node architecture to solve the classic "bot walks into empty elevator shaft" problem. Bots now check if platforms are present BEFORE pathfinding through shafts, wait patiently for elevators to arrive, and automatically learn elevator locations during gameplay.

**Before Elevator System:**
- ❌ Bots pathfind through empty elevator shafts and fall to death
- ❌ No awareness of platform position (top vs bottom)
- ❌ Stuck in infinite loops trying to reach elevated items
- ❌ Manual waypoint creation required for every elevator

**After Elevator System:**
- ✅ Platform presence check before A* pathfinding (prevents shaft falls)
- ✅ Wait state management (stops and waits for platform to arrive)
- ✅ Automatic alternate route finding (takes stairs when elevator at top)
- ✅ Auto-discovery system (learns elevator locations through exploration)
- ✅ 30-second timeout with replanning (prevents infinite waiting)

**How it works:**

**Two-Node Architecture:**
- **WAIT_NODE**: Placed at elevator bottom (entry point)
- **EXIT_NODE**: Placed at elevator top (exit point)
- **Dynamic traversal**: A* only paths through WAIT_NODE if platform is present

**Platform Detection:**
- `IsPlatformAt()`: Checks if func_plat is within 32 units of target position
- `CanTraverseElevator()`: Validates platform at bottom OR moving down
- Integrated at all 6 A* neighbor checks for complete coverage

**Wait State Management:**
- Bot reaches WAIT_NODE → checks platform presence
- If absent: stops movement, looks up, waits patiently
- Resets stuck timers (prevents panic teleport during wait)
- Boards when platform arrives, times out after 30 seconds
- Timeout triggers replanning to find alternate routes (stairs/ramps)

**Auto-Discovery:**
- Bot drops breadcrumb on func_plat → detects position (top/bottom)
- Creates WAIT_NODE at pos1, EXIT_NODE at pos2
- Links pair bidirectionally for A* traversal
- Future bots use learned nodes automatically

**Three Elevator Scenarios:**
1. 🟢 **Platform at bottom**: Bot walks on immediately, rides to top
2. 🔵 **Platform at top**: A* skips elevator, finds stairs/alternate route
3. 🟡 **Platform absent**: Bot waits at entrance, boards when arrives, timeout → replan

**Debug Output:**
```
[Assmunch] ELEVATOR: Waiting at '1792.0 384.0 -168.0'
(2.3 seconds pass)
[Assmunch] ELEVATOR: Boarding (waited 2.3s)
[Assmunch] ELEVATOR: Aboard, riding to top
```

**Testing:**
- Enable debug: `impulse 95` → `impulse 96` (cycle to LOG_TACTICAL)
- Best test map: DM4 (452 waypoints + Yellow Armor elevator)
- See [ELEVATOR_TEST_GUIDE.md](docs/ELEVATOR_TEST_GUIDE.md) for detailed protocol

**Evidence from Logs:**
Log analysis from DM2 revealed Wanton bot stuck 108 times (35+ consecutive) trying to reach Yellow Armor on unmapped elevator. Pattern shows "Train surf escape" (train under elevator) and "burst into flames" (lava death), confirming classic elevator shaft problem. See [CRITICAL_FINDING.md](docs/CRITICAL_FINDING.md) for full analysis.

**Integration:**
- Platform detection in [botroute.qc:1100-1183](reaper_mre/botroute.qc#L1100-L1183)
- A* integration in [botroute.qc:1285-1602](reaper_mre/botroute.qc#L1285-L1602)
- Wait state in [botmove.qc:2098-2219](reaper_mre/botmove.qc#L2098-L2219)
- Auto-creation in [botroute.qc:600-738](reaper_mre/botroute.qc#L600-L738)

**Result:** Bots handle elevators like skilled human players! Platform presence checks prevent shaft falls, wait state management enables patient boarding, A* blocking finds alternate routes automatically, and auto-discovery learns new elevators during gameplay. Eliminates stuck loops at elevator locations. Build size: 496,890 bytes (+3,896 bytes). 🛗🤖✅

### 🎯 The Profiler: Opponent Behavior Tracking (2026-01-06)

**NEW:** Bots now analyze and adapt to opponent playstyles in real-time!

The Profiler tracks enemy movement patterns to build aggression profiles. Bots learn whether opponents are aggressive rushers or passive campers, then adapt their tactics dynamically mid-match.

**Before The Profiler:**
- ❌ Fixed combat tactics (same approach vs all enemies)
- ❌ No adaptation to opponent behavior
- ❌ Bots couldn't counter specific playstyles

**After The Profiler:**
- ✅ Tracks enemy aggression (0-10 score based on approach/retreat patterns)
- ✅ Adapts tactics: Retreat & trap vs rushers, push aggressively vs campers
- ✅ Human-like strategic awareness (learns playstyles mid-match)
- ✅ Debug logging shows profiling decisions at LOG_TACTICAL level

**How it works:**

**Aggression Tracking:**
- Monitors distance changes frame-by-frame
- Enemy approaching → +0.1 aggression (rusher behavior)
- Enemy retreating/camping → -0.05 aggression (passive behavior)
- Score range: 0 (passive camper) to 10 (aggressive rusher)

**Tactical Adaptations:**
- **vs Aggressive (>7.0)**: Increase retreat probability, set grenade traps, punish rushers
- **vs Passive (<3.0)**: Force aggressive push, flush out campers, prevent stalemates
- **vs Neutral (3.0-7.0)**: Standard combat tactics (no adaptation)

**Example Scenarios:**
- 🏃 **Aggressive Player**: Constantly charging → Bot backs up, drops grenades, punishes aggression
- 🏰 **Camping Player**: Hiding in corners → Bot pushes aggressively, flushes them out
- ⚖️ **Balanced Player**: Mixed tactics → Bot uses standard combat AI

**Debug Output:**
```
[Cheater] PROFILE: Assmunch is AGGRESSIVE (8.7) → Retreat & Trap
[Drooly] PROFILE: Wanton is PASSIVE (2.1) → Push Aggressively
```

**Integration:**
- Profiling in [bot_ai.qc:1405-1436](reaper_mre/bot_ai.qc#L1405-L1436)
- Tactical adaptation in [bot_ai.qc:1510-1566](reaper_mre/bot_ai.qc#L1510-L1566)
- Entity fields in [defs.qc:154-155](reaper_mre/defs.qc#L154-L155)

**Result:** Bots exhibit human-like tactical adaptation! They learn opponent behavior during matches and counter it strategically. Rushers face traps, campers get flushed out. Creates dynamic, adaptive combat instead of fixed AI patterns. Build size: 464,034 bytes (+1,000 bytes). 🎯🧠✅

### 🎥 AI Cameraman: Director Mode (2026-01-05)

**NEW:** Intelligent spectator camera that automatically tracks the most exciting action!

The AI Cameraman is a smart cinematographer that understands Quake combat. It automatically switches between bots based on real-time "excitement scoring" - prioritizing close-quarters battles, underdog scenarios, powerup plays, and high-skill movement. Perfect for spectating bot matches hands-free!

**Before AI Cameraman:**
- ❌ Manual camera control required (impulse commands, target cycling)
- ❌ Missing action while watching wrong player
- ❌ No awareness of combat intensity or drama
- ❌ Static spectator modes (noclip, follow single player)

**After AI Cameraman:**
- ✅ Fully automatic action tracking (set it and forget it!)
- ✅ AI scores every bot by excitement level every 2 seconds
- ✅ Smooth cinematic transitions between targets
- ✅ Shows off MRE's advanced AI (Fear Engine, FFA logic, combos)

**How it works:**

**Action Scoring System:**
The AI rates each bot's "excitement level" based on multiple factors:
- 🔥 **Active combat**: +300 for fighting, +200 bonus for close-quarters (<250u)
- 💀 **Health drama**: +150 if bot is wounded (<40 HP), +100 if enemy is low
- 🚀 **Movement skill**: +80 for fast movement (>400 u/s bunny hopping/rocket jumps)
- ⚡ **Powerup potential**: +250 quad damage, +150 pentagram, +100 invisibility ring
- 🎯 **Weapon loadout**: +50 for rockets, +40 for lightning gun
- 🧠 **Tactical AI**: +120 for survival tactics (wounded bots avoiding combat = interesting!)
- 🏆 **Leader status**: +10 per frag for high scorers
- 🔥 **Hot streak**: +100 bonus for 10+ frags

**Example Scenarios:**
- **CQC Duel**: Bot A vs Bot B at 200u range → Bot A scores 500+ (combat + CQC) → Camera tracks the fight
- **Underdog Drama**: Wounded bot (25 HP) fleeing through corridors → Scores 450 (health drama + tactical retreat) → Camera follows survival attempt
- **Quad Rampage**: Bot picks up quad damage → Scores 550+ (quad + combat) → Camera showcases carnage
- **Pro Movement**: Bot bunny hopping at 500 u/s while rocket jumping → Scores 380 (movement skill) → Camera highlights skills

**AI Director Logic:**
Every 2 seconds, the camera:
1. Scans ALL players and bots
2. Calculates excitement score for each
3. Switches to highest-scoring target
4. Uses smooth flyby positioning for cinematic tracking
5. Shows target name on screen (optional)

**Activation:**
```
# IMPORTANT: Spawn bots first with "impulse 208", THEN activate camera!
impulse 99     # Become AI Cameraman spectator (instant activation!)
```

**Manual Override Controls:**
```
impulse 50     # Flyby mode (cinematic tracking)
impulse 51     # Follow mode (over-shoulder)
impulse 53     # Free-flight camera (fly around freely)
impulse 60     # Toggle info display
impulse 61     # Cycle to next player
impulse 98     # EXIT camera (return to player mode)
impulse 99     # Return to AI Director mode
```

**Integration:**
- Director mode in [kascam.qc:9](reaper_mre/kascam.qc#L9)
- Action scoring in [kascam.qc:31-129](reaper_mre/kascam.qc#L31-L129)
- AI think loop in [kascam.qc:1627-1702](reaper_mre/kascam.qc#L1627-L1702)
- CamThink integration in [kascam.qc:1749-1755](reaper_mre/kascam.qc#L1749-L1755)
- Activation in [weapons.qc:1387-1391](reaper_mre/weapons.qc#L1387-L1391)

**Result:** The world's first AI-powered Quake spectator camera! Automatically tracks exciting combat, underdog stories, powerup plays, and pro movement. Shows off MRE's advanced AI features (Fear Engine tactical routing, FFA target selection, weapon combos). Set it and watch the bots battle like a tournament broadcast! Build size: 457,342 bytes (+2,480 bytes). 🎬🤖✅

### 🐛 Bot Debug Logging Toggle Fix (2026-01-05)

**BUGFIX:** impulse 95 debug toggle now works reliably! Fixed interference from bot AI think cycles.

**The Problem:**
Users couldn't disable debug logging after enabling it. Entering `impulse 95` to toggle off appeared to do nothing - debug output continued flooding the console.

**Root Cause:**
- `ImpulseCommands()` executes for ALL entities (players + bots)
- Bots run the same call chain: `PlayerPostThink()` → `W_WeaponFrame()` → `ImpulseCommands()`
- `bot_debug_enabled` is a **global flag** (not per-entity)
- When bot AI executed `impulse 95` during its think cycle, it toggled the global flag
- User would enable → bot would disable → user tried to disable but actually enabled again
- Result: Flag appeared stuck in "on" state

**The Fix:**
Added player-only check in [weapons.qc:1387](reaper_mre/weapons.qc#L1387):
```c
if ((self.impulse == 95.000) && (self.classname == "player"))
```

Now only human players (`classname == "player"`) can toggle debug logging. Bots (`classname == "dmbot"`) are excluded from this impulse.

**Bot Debug Logging Usage:**
```
impulse 95     # Toggle bot decision logging on/off
```

Debug output shows:
- `[BotName] TARGET: EnemyName (score=X, HP=Y, dist=Zu)` - Target selection decisions
- `[BotName] GOAL: item_name (score=X, dist=Yu)` - Goal selection decisions
- Useful for analyzing AI behavior, finding bugs, and tuning bot intelligence

**Result:** Debug toggle now works perfectly! Developers can enable logging for AI analysis, then cleanly disable it when done. No more bot interference. Build size: 458,998 bytes (+24 bytes). 🐛🔧✅

### Trace Global Clobber Fix (2026-01-10)

**BUGFIX:** Helper tracelines now preserve the engine `trace_*` globals instead of overwriting caller state.

**The Problem:**
QuakeC exposes a single set of global `trace_*` variables (fraction/endpos/ent/etc.). Helper functions in `bot_ai.qc` and `botgoal.qc` were running `traceline()` and unintentionally overwriting trace data that movement/combat code expected to still be valid.

**The Fix:**
Each helper now caches the current `trace_*` values, performs its own `traceline()`, copies the results it needs into local variables, and restores the original globals before returning.

**Result:** Movement and collision logic no longer sees stale trace results after prediction or goal helper calls.

### Utility Definition Consolidation (2026-01-10)

**MAINTENANCE:** Shared helpers are now defined once to avoid compile-order ambiguities.

**What changed:**
- `CheckWaterLevel` now has a single definition in `botmove.qc` (movement utilities).
- The duplicate body was removed from `botthink.qc`.
- Existing prototypes (e.g., in `func.qc`) continue to cover cross-file calls.

**Result:** No duplicate symbol risk and clearer ownership of shared utility functions.

### Shared Bot Prototypes (2026-01-10)

**MAINTENANCE:** Added a single prototype header to prevent forward-declaration drift.

**The Fix:**
`bot_defs.qc` centralizes shared function prototypes and is included early in `progs.src`.

**Result:** Cleaner cross-file dependencies and fewer duplicate-definition errors.

### Train Prediction Loop Cap (2026-01-10)

**OPTIMIZATION:** predict_train_pos now limits chain traversal to avoid per-frame O(N) scans.

**The Fix:**
Traversal caps at 10 segments and breaks once the time horizon is covered; looping modulo is only used when a loop is detected and the chain isn't truncated.

**Result:** Prevents thundering-herd spikes when multiple bots target trains at once.

### Noise Push Dispatch (2026-01-10)

**BUGFIX:** Noise events are pushed directly to bots instead of overwriting a global queue.

**The Fix:**
`signalnoise` now fans out to nearby bots immediately and stores the source in each bot’s `noise_target`.

**Result:** Bots hear overlapping events in the same frame reliably.

### CallForHelp Throttle + State Guard (2026-01-10)

**OPTIMIZATION:** Team help scans now run less often and avoid leaking global state.

**The Fix:**
`CallForHelp` is gated unless bots are low on health or pass a 10% random check, and it restores `enemy_vis` after temporary `self` swaps.

**Result:** Reduced CPU spikes in teamplay without cross-bot state bleed.

### NOISEQUEUE Worldspawn Init (2026-01-10)

**BUGFIX:** Noise queue initialization now occurs at worldspawn instead of bot spawn.

**The Fix:**
`NOISEQUEUE = noisetarget()` runs in `world.qc` so early match noises are not dropped when bots haven't spawned yet.

**Result:** Bots hear the first sounds reliably, even before any bot spawns.

### Lefty Bitmask Safety (2026-01-10)

**BUGFIX:** Clearing `self.lefty` flags now uses masked subtraction to avoid corrupting unrelated bits.

**The Problem:**
`self.lefty` is a bitmask. Some clears used raw subtraction, which can borrow across bits when the flag is not set.

**The Fix:**
Clear flags via `self.lefty = (self.lefty - (self.lefty & FLAG))` for `GETGOODY`, `MULTIENEMY`, `STRAFE_DIR`, and `ONTRAIN`.

**Result:** No spurious state flips when clearing flags.

### newmis Spawn Safety (2026-01-10)

**BUGFIX:** Projectile spawns now capture the spawned entity locally instead of relying on the global `newmis`.

**The Problem:**
`spawn()` writes to the global `newmis`. If a nested call spawns another entity, `newmis` can be overwritten before the outer function finishes configuring its projectile.

**The Fix:**
`launch_spike` now returns the spawned entity and the calling code uses that local reference for all configuration.

**Result:** Spike and superspike setup no longer risks configuring the wrong entity.

### Delta-Time Aim Smoothing (2026-01-10)

**OPTIMIZATION:** Pitch slew rate now scales by time delta to avoid frame-rate dependent aiming.

**The Problem:**
Fixed degrees-per-tick turning slows down in real time when server FPS drops.

**The Fix:**
`checkyaw` now computes degrees-per-second and multiplies by elapsed time since the last aim update.

**Result:** Bots keep consistent turn speed even under server load.

### Bot_tryjump Gravity Scaling (2026-01-10)

**BUGFIX:** Jump arc simulation now scales gravity by timestep so bots don't under-estimate jump distances.

**The Problem:**
`Bot_tryjump` subtracted full `GRAVITY` each 0.1s step, effectively simulating 10x gravity.

**The Fix:**
The arc loop now applies `GRAVITY * dt`, uses a single step trace with slope gating, and keeps hazard checks in the loop.

**Result:** Bots correctly recognize reachable gaps and ledges during jump planning.

### Projectile Dodge Scan Optimization (2026-01-10)

**OPTIMIZATION:** Projectile evasion now limits scans to nearby entities and skips work when idle/healthy.

**The Fix:**
`bot_dodge_stuff` uses `findradius` around the bot (500u) and gates scans when no enemy and high health.

**Result:** Lower per-frame cost while keeping dodge behavior effective in combat.

### Goal Removal Guard (2026-01-10)

**BUGFIX:** Bots now abandon item goals that were removed or hidden between selection and pursuit.

**The Fix:**
Item weighting rejects entities with `solid == SOLID_NOT` and `modelindex == 0`, and fixation logic immediately drops such goals.

**Result:** Fewer stale-goal chases after pickups or entity removal.

### Split Search Timers (2026-01-10)

**BUGFIX:** Combat persistence and navigation patience no longer share the same timer.

**The Fix:**
Bots now track `combat_search_time` for enemy chase persistence and `nav_search_time` for item/path patience, preventing cross‑clobbering between systems.

**Result:** Bots don’t forget enemies early or abandon goals due to unrelated timer updates.

### Powerup Bitmask Safety (2026-01-10)

**BUGFIX:** Powerup expirations now clear `self.items` using masked subtraction to prevent bitmask corruption.

**The Fix:**
`botthink.qc` clears `IT_INVISIBILITY`, `IT_INVULNERABILITY`, `IT_QUAD`, and `IT_SUIT` with `self.items - (self.items & FLAG)`.

**Result:** No accidental item state corruption when a flag is already cleared.

### Pitch Jitter Guard (2026-01-10)

**OPTIMIZATION:** Pitch updates are now gated to avoid fighting engine interpolation.

**The Fix:**
`checkyaw` only writes `angles_x` when the pitch delta exceeds 0.5 degrees and sets `fixangle` on those updates.

**Result:** Smoother pitch in spectator views and demos with less micro‑snap jitter.

### Phantom Enemy Validation (2026-01-10)

**BUGFIX:** Bots now validate `self.enemy` each frame to avoid targeting reused entity slots.

**The Fix:**
`Bot_ValidateEnemy` clears enemies that are not `player`/`dmbot` or are dead, and `BotPostThink` calls it before combat logic.

**Result:** No more chasing rockets or stale entities after disconnect/reuse.

### 🏎️ Movement Smoothing Suite (2026-01-05)

**NEW:** Three distinct smoothing upgrades transform robotic movement into human-like fluidity!

Bots now move like skilled players with corner cutting, smooth strafing, and dynamic turn speeds. Eliminates robotic jerks and vibrations.

**Before Smoothing:**
- ❌ Bots hit waypoints → turn 90° → robotic cornering
- ❌ Combat strafing creates seizure-like left-right vibration
- ❌ Constant 20°/frame turn speed (aimbot-like snapping)

**After Smoothing:**
- ✅ Corner cutting: Bots curve through doorways like racing drivers
- ✅ Smooth strafing: 0.5s commitment arcs instead of frame-jitter
- ✅ Analog turning: Slow tracking (5°/frame), fast flicks (45°/frame)

**How it works:**

**1. The Racing Line (Corner Smoothing)**
- 🏁 **Lookahead blending** → When within 120u of waypoint, checks for next node
- 🎯 **Aim interpolation** → Blends 70% current + 30% next waypoint
- 🏎️ **Early turning** → Starts curve before reaching waypoint (like racing apexes)
- 🚪 **Smooth corners** → Curves through doorways instead of hitting frames

**2. Strafe Hysteresis (Anti-Vibration)**
- 🔒 **Direction commitment** → Locks strafe direction for 0.5 seconds
- 🛑 **Smart breakout** → Only breaks lock if stuck (velocity <20 u/s)
- 📊 **Flip tracking** → Monitors direction changes, resets timer on flips
- 🎯 **Smooth arcs** → Combat strafing becomes fluid arcs, not jitter

**3. Analog Turning (Mouse Smoothing)**
- 🎯 **Micro-adjustments** → <10° angles: 5°/frame (smooth tracking)
- 🔄 **Medium turns** → 10-45° angles: 20°/frame (normal cornering)
- ⚡ **Snap turns** → >45° angles: 45°/frame (fast acquisition)
- 🖱️ **Human-like** → Mimics mouse acceleration patterns

**Integration:**
- Racing Line in [botmove.qc:1523-1551](reaper_mre/botmove.qc#L1523-L1551)
- Strafe Hysteresis in [botmove.qc:1100-1120, 1178-1208](reaper_mre/botmove.qc#L1100-L1208)
- Analog Turning in [botmove.qc:1286-1327](reaper_mre/botmove.qc#L1286-L1327)
- New fields in [defs.qc:331-332](reaper_mre/defs.qc#L331-L332)

**Result:** Bots move like pros! Corner smoothing creates racing-line navigation, strafe hysteresis eliminates vibration, analog turning provides natural aim. Professional-grade movement fluidity. Build size: 453,342 bytes (+888 bytes). 🏎️✨✅

### 🧠 The Fear Engine: Tactical Pathfinding (2026-01-05)

**NEW:** Danger-aware A* pathfinding chooses safest routes instead of just shortest!

Bots now avoid death zones and adapt routing based on health. Wounded bots take safe detours, healthy bots seek combat zones. Emerges from death experience.

**Before Fear Engine:**
- ❌ A* always chose shortest path (pure distance)
- ❌ Bots repeatedly died in same dangerous corridors
- ❌ No learning from death zones
- ❌ Weak/strong bots used identical routes

**After Fear Engine:**
- ✅ A* considers danger + traffic (tactical cost)
- ✅ Bots route around high-death areas
- ✅ Learn from deaths (danger scent accumulation)
- ✅ Health-adaptive routing (weak avoid, strong seek)

**How it works:**

**Tactical Edge Cost Formula:**
```
base_cost = distance(current → neighbor)
+ danger_penalty = danger_scent × 10.0
+ traffic_modifier = traffic_score × (health < 50 HP ? +5.0 : -2.0)
= total_edge_cost (used in A* pathfinding)
```

**Danger Scent Penalty:**
- 📈 **Learning from deaths** → Each bot death increments danger_scent at death location
- 🚫 **Route avoidance** → +10.0 cost per death makes path "artificially longer"
- 🗺️ **Example**: Hallway with 3 deaths = +30 cost → Bot takes longer flank route instead

**Traffic Score (Health-Adaptive):**
- 💪 **Strong bots (≥50 HP)** → Seek traffic areas (-2.0 cost = map control)
- 🩹 **Weak bots (<50 HP)** → Avoid traffic areas (+5.0 cost = survival)
- 🎯 **Strategic positioning** → Condition-based routing creates emergent tactics

**Example Behaviors:**
- 🏥 **Wounded bot**: Needs health pack 200u away through high-traffic corridor (+50 traffic penalty = 250 cost) OR 300u detour through quiet back route (300 cost) → Takes detour for safety
- 💪 **Healthy bot**: Seeks Red Armor 400u away through active combat zone (-20 traffic bonus = 380 cost) → Aggressively pursues map control
- ☠️ **Death zone**: Lava pit corridor killed 5 bots (+50 danger penalty) → All bots route around despite being shorter

**Integration:**
- A* modification in [botroute.qc:1207-1231, 1262-1280, 1308-1326, 1353-1371, 1398-1416, 1443-1461](reaper_mre/botroute.qc#L1207-L1461)
- Applied to all 6 neighbor checks in AStarSolve function
- Uses existing danger_scent and traffic_score waypoint fields

**Result:** Bots exhibit survival instincts! Avoid death zones, adapt routes to health condition, learn from experience. Transforms A* from blind distance optimizer to tactical risk-aware navigator. Build size: 454,862 bytes (+912 bytes). 🧠🗺️✅

### 🎯 The FFA Fix: Best Target Logic (2026-01-05)

**NEW:** Intelligent multi-opponent awareness for Free-For-All deathmatch!

Bots now scan ALL visible enemies and pick the best target based on distance, health, and threat level. Replaces "first visible enemy" with smart scoring system.

**Before FFA Fix:**
- ❌ Picked first visible enemy (random selection)
- ❌ Committed to duel (tunnel vision)
- ❌ Ignored better targets nearby
- ❌ Only scanned when idle

**After FFA Fix:**
- ✅ Scans all enemies, picks BEST target (intelligent)
- ✅ Switches targets mid-combat (opportunistic)
- ✅ Prioritizes attackers (self-defense)
- ✅ Steals kills from weak enemies (vulture mode)

**How it works:**

**Target Scoring System:**
- 📏 **Base score** → 1000 - distance (closer = higher priority)
- 💀 **Vulture bonus** → +500 for enemies <40 HP (easy kill)
- 🛡️ **Self-defense bonus** → +800 for enemies attacking bot (highest priority)
- 🔄 **Angle penalty** → ×0.5 for enemies behind (avoids 180° snap turns)

**Swivel Turret (Dynamic Switching):**
- 🔍 **Combat scanning** → Re-evaluates targets every 1.5 seconds DURING fights (optimized via data-driven tuning)
- 🎯 **Opportunistic** → Abandons duel if better target appears (with hysteresis to prevent flip-flopping)
- ⚡ **Adaptive** → Switches to closer/weaker/attacking enemies

**Example Behaviors:**
- 🦅 **Vulture**: Player A (80 HP) fighting Player B (15 HP) → Bot switches to Player B (+500 bonus) for kill-steal
- 🛡️ **Self-Defense**: Bot dueling enemy at 300u → Player shoots bot from behind → Bot switches (+800 attacker bonus)
- 💡 **Opportunistic**: Bot fighting at 400u → Weak enemy (30 HP) appears at 200u → Bot switches (closer + vulture)

**Integration:**
- Scanner in [bot_ai.qc:619-740](reaper_mre/bot_ai.qc#L619-L740)
- Target selection in [bot_ai.qc:743-811](reaper_mre/bot_ai.qc#L743-L811)
- Swivel Turret in [bot_ai.qc:1275-1320](reaper_mre/bot_ai.qc#L1275-L1320)
- New field in [defs.qc:333](reaper_mre/defs.qc#L333)

**Data-Driven Optimization:**
MRE uses scientific bot tuning via debug logging (impulse 95) and Python log analysis. Initial analyzer results showed excessive target switching (109/bot) and low engagement (14.1%). Implemented scan frequency reduction (0.5s → 1.5s) and hysteresis logic. **Validated results:** Target switching reduced 40% (109 → 64.8/bot), engagement increased 4.3× (14.1% → 60.5%). Bots now fight 60% of the time instead of 14%. See [DEVELOPMENT.md](DEVELOPMENT.md#-data-driven-improvement-pipeline) for complete pipeline documentation.

**Result:** Bots play FFA like pros! Intelligent target selection, opportunistic kill-stealing, self-defense priority. Optimized through data-driven tuning for better target commitment. Transforms bots from duelists (single-target tunnel vision) to opportunists (adaptive multi-target awareness). Build size: 459,246 bytes (+832 bytes). 🎯🔄✅

### 🎯 The Juggler: Weapon Combo System (2026-01-05)

**NEW:** High-skill bots now execute tournament-level weapon combos! Rocket → Lightning Gun/SSG combos exploit knockback physics.

Mimics iconic "shaft combo" from competitive Quake: fire rocket at close range to knock enemy airborne, instantly switch to hitscan weapon (LG/SSG), track helpless opponent who cannot dodge while mid-air. Only high-skill bots (skill >2) execute this pro-level mechanic.

**Before The Juggler:**
- ❌ Bots only used single-weapon attacks (no combo chains)
- ❌ Rocket knockback advantage wasted—no follow-up damage
- ❌ Combat felt robotic—fire, wait, fire, wait (no dynamic adaptation)

**After The Juggler:**
- ✅ Rocket fire triggers instant weapon switch at close-mid range (<400u)
- ✅ Prefers Lightning Gun (10+ cells) for hitscan tracking, falls back to SSG (5+ shells)
- ✅ Reduces attack cooldown to 0.1s for instant combo execution
- ✅ 2-second cooldown prevents spam while allowing combos during sustained fights

**How it works:**
1. 🚀 **Rocket fire** → Bot fires rocket at enemy within 400 units
2. 💥 **Knockback physics** → Enemy gets launched airborne by rocket explosion
3. ⚡ **Instant switch** → Bot switches to LG/SSG via impulse (`self.impulse = 8` for LG)
4. 🎯 **Quick follow-up** → Attack cooldown reduced to 0.1s (from 0.8s) for instant combo
5. 🔒 **Cooldown gate** → 2-second cooldown prevents continuous weapon switching

**Example Behavior:**
- ⚡ **Rocket → LG combo:** Enemy at 350u → Bot fires rocket → Enemy airborne from knockback → Bot switches to LG → Tracks with hitscan while enemy helpless → Devastating DPS chain
- 💥 **Rocket → SSG combo:** Low on cells but 5+ shells → Rocket → SSG burst → Reliable fallback when LG unavailable

**Skill-based gating:** Low-skill bots (≤2) fire rockets normally. High-skill bots (>2) execute combos, creating clear difficulty progression. Preserves game balance while adding tournament-level depth for challenging opponents.

**Integration:** Combo detection in [botfight.qc:838-872](reaper_mre/botfight.qc#L838-L872) runs immediately after rocket fire. Cooldown tracking in [defs.qc:330](reaper_mre/defs.qc#L330).

**Result:** High-skill bots now fight like tournament players! Rocket → LG/SSG combos transform combat from static weapon usage to dynamic combo chains. Exploits knockback physics for guaranteed follow-up damage. Build size: 452,454 bytes (+332 bytes). 🎯⚡✅

### ⏰ The Timekeeper: Strategic Powerup Control (2026-01-05)

**NEW:** Bots now predict powerup spawn times and pre-rotate to spawn points like tournament players!

Standard bots only chase visible items (reactive). The Timekeeper makes bots memorize spawn timers and camp spawn points 5-10 seconds before powerups appear (proactive), emulating pro Quake play.

**Before Timekeeper:**
- ❌ Bots only pursued visible powerups (opportunistic control)
- ❌ Ignored empty spawn points even when quad/pent about to spawn
- ❌ No spawn timing memory—played like casual players

**After Timekeeper:**
- ✅ Tracks powerup respawn times: Quad = 60s, Pent/Ring = 300s
- ✅ Detects invisible powerups scheduled to spawn within 10 seconds
- ✅ Assigns massive weight (`MUST_HAVE + 500`) to override combat goals
- ✅ Bots abandon fights and run to empty spawn points before items appear

**How it works:**
1. 📝 **Spawn tracking** → When powerup picked up, stores respawn time in `.predicted_spawn` field
2. 🔍 **Invisible item scanning** → Item scanner checks invisible powerups (quad/pent/ring)
3. ⏱️ **10-second window** → If `predicted_spawn < time + 10`, powerup spawning soon
4. 🎯 **Priority override** → Assigns +500 weight bonus to force camping behavior
5. 🏃 **Pre-rotation** → Bot stops fighting, runs to spawn point, camps until item appears

**Example Behavior:**
- ⚡ Quad spawns in 8 seconds → Bot sees empty spawn point → +500 weight → Abandons combat → Runs to quad spawn → Waits → Grabs quad as it appears
- 🛡️ Pent timer at 4 seconds → Bot ignores nearby rockets → Pre-rotates to pent spawn → Secures pentagram before enemies arrive

**Integration:** Pre-rotation logic in [bot_ai.qc:1394-1435](reaper_mre/bot_ai.qc#L1394-L1435) runs during item scanning. Spawn times set in [items.qc:1087, 1093](reaper_mre/items.qc#L1087-L1093) during powerup pickup.

**Result:** Bots now control powerups like skilled humans! They memorize spawn timers, pre-rotate to spawns, and camp strategic positions instead of wandering randomly. Transforms powerup control from luck-based to skill-based. Build size: 452,122 bytes (+336 bytes). ⏰🎯✅

### 🚀 Rocket Jump Ceiling Safety Check (2026-01-05)

**NEW:** Bots no longer commit suicide by rocket jumping into low ceilings!

Added 96-unit ceiling clearance check before RJ execution to prevent blast damage in tight spaces.

**Before Ceiling Check:**
- ❌ Bots would RJ in low-ceiling corridors
- ❌ Rocket blast hits ceiling, full damage reflects to bot
- ❌ Instant death from environmental suicide

**After Ceiling Check:**
- ✅ Traces 96 units upward before executing RJ
- ✅ Aborts RJ if ceiling detected (`trace_fraction < 1.0`)
- ✅ Bot finds alternate route or waits for better positioning

**How it works:**
1. 🔍 **Upward trace** → `traceline(origin, origin + '0 0 96', TRUE, self)` before RJ
2. 🚫 **Abort on blocked** → If `trace_fraction < 1.0`, ceiling detected within 96 units
3. ✅ **Safe execution** → Only executes RJ when clear vertical space confirmed
4. 🛡️ **Stacks with safety** → Combines with existing health check (>40 HP), ammo check, 2s cooldown

**Why 96 units:** Rocket splash radius is ~120 units, but vertical blast component needs clearance. 96-unit check provides safety margin for typical rooms while avoiding false positives on high ceilings.

**Integration:** Ceiling check in [botmove.qc:787-794](reaper_mre/botmove.qc#L787-L794) runs immediately before pitch/yaw selection in `bot_rocket_jump()` function.

**Result:** Bots survive RJ attempts in confined spaces! Low-ceiling RJs are aborted, preventing environmental suicides. Complements existing RJ safety gates for comprehensive protection. Build size: 452,122 bytes (+8 lines). 🚀🛡️✅

### 🌊 PHASE 11: Water Survival (Drowning Prevention) (2026-01-05)

**NEW:** Bots now detect drowning and emergency-surface when running out of air underwater!

Phase 11 adapts FrikBot's "Up Periscope" logic to add missing air management to Reaper's water navigation suite:

**Before Phase 11:**
- ❌ Bots had NO air_finished checking anywhere in the codebase
- ❌ Bots would drown in deep water zones (e23m6, e4m8, etc.)
- ❌ Existing water code (BotUnderwaterMove, waterupdown) only handled navigation, not survival

**After Phase 11:**
- ✅ Detects when fully underwater (`waterlevel > 2`) AND air running low (`time > air_finished - 2`)
- ✅ Traces upward 600 units to check if air exists above (`trace_inopen`)
- ✅ Forces emergency surface swim when drowning imminent
- ✅ Checks 2 seconds before drowning to give time to surface

**How it works:**
1. 🤿 **Underwater detection** → Checks if bot is fully submerged (waterlevel > 2)
2. 💨 **Air check** → Detects when air will run out in 2 seconds (air_finished - 2)
3. 🔍 **Air trace** → Scans 600 units upward to see if air exists above
4. 🏊 **Emergency surface** → Forces upward swim using:
   - `button2 = 1` (jump/swim button - same as human player)
   - `velocity_z = 200` (adds upward velocity)
   - `v_angle_x = -45` (looks up to assist physics)
5. 🔁 **Every frame** → Runs in movement pipeline after hazard checks

**Integration:** CheckWaterSurvival() runs at the start of Botmovetogoal() (line 1475) immediately after CheckForHazards(), ensuring drowning bots get instant surfacing response before other movement systems execute.

**Result:** Bots now survive deep water! When air runs low, bots immediately detect air above and force emergency swim to surface. Prevents suffocation deaths in water-heavy maps. Complements existing water navigation with critical air management layer. Build size: 451,282 bytes (no size change from Phase 10). 🌊💨✅

### 🏥 PHASE 10: Graduated Need Assessment (2026-01-05)

**NEW:** Bots now exhibit human-like desperation for health and armor when hurt!

Phase 10 replaces Reaper's linear health scaling (weak +15 max bonus) with FrikBot's aggressive graduated thresholds for realistic survival instincts:

**Before Phase 10 (Linear Scaling):**
- ❌ Bot at 20 HP gets only +15 weight for health items
- ❌ Bot at 10 HP might still chase Rocket Launcher instead of health
- ❌ Naked bot (0 armor) has same item priorities as armored bot

**After Phase 10 (Graduated Thresholds):**
- ✅ Bot at <20 HP gets **+150 weight** for health items (10× improvement!)
- ✅ Bot at <50 HP gets **+50 weight** for health items
- ✅ Naked bot (<50 armor) gets up to **+40 weight** for armor items
- ✅ Megahealth always gets **+50 bonus** even at full HP

**How it works:**
1. 🩸 **Critical Health (<20 HP)** → +150 weight → Health dominates all scoring
2. 🤕 **Low Health (<50 HP)** → +50 weight → Health prioritized over weapons
3. 💎 **Megahealth Bonus** → +50 weight → Always valuable (stacks with health bonuses)
4. 🛡️ **Low Armor (<50)** → Up to +40 weight → Scales from naked to moderate armor
5. 🧠 **Preserved Intelligence** → All existing systems intact (Risk-aware, Bully mode, RJ reachability)

**Example Behavior:**
- 💀 Bot at 15 HP near health pack → **+150 weight** → Ignores distant RL, beelines for health
- 🔥 Bot at 40 HP finds megahealth → **+50 (low HP) + +50 (mega bonus) = +100 total** → High priority
- 🏃 Naked bot sees Green Armor → **+40 weight** → Seeks armor before combat items

**Integration:** FrikBot's granular thresholds enhance Reaper's existing sophisticated scoring (threat assessment, smart backpack scavenging, RJ reachability) instead of replacing it. Best-of-both-worlds item AI!

**Result:** Bots make survival-first decisions like human players! Critical health bots frantically seek healing, naked bots prioritize armor acquisition, megahealth attracts even healthy bots. Build size: 451,282 bytes (+192 bytes). 🏥🛡️✅

### 🌋 PHASE 9: Ground Hazard Detection (2026-01-05)

**NEW:** Bots now proactively avoid lava pools, gaps, and cliff edges with ground-level hazard scanning!

Phase 9 implements FrikBot's "Look Before You Leap" system as **Layer 1** of a two-layer hazard defense:
- **Layer 1 (Phase 9)** — PROACTIVE ground checks prevent hazard entry before movement
- **Layer 2 (Phase 4)** — REACTIVE aerial steering saves bots already in flight

**How it works:**
1. 🔍 **Look ahead** — Traces 60 units forward based on movement direction (`ideal_yaw`)
2. ⬇️ **Look down** — Traces 250 units downward to find floor (or void)
3. 🧪 **Analyze floor** — Uses `pointcontents()` to detect CONTENT_LAVA (-5) or CONTENT_SLIME (-4)
4. 🛑 **Stop at death pits** — Zeroes velocity when detecting void or lava/slime pit (prevents cliff deaths)
5. 🏃 **Auto-jump gaps** — Triggers jump when detecting >60u gap while moving fast (>200 u/s)
6. 🦘 **Jump over hazards** — Triggers jump when detecting lava/slime floor directly ahead

**Hazard Detection Cases:**
- ⚫ **Death Pit (Void)** → `trace_fraction == 1.0` → STOP! Zero velocity
- 🌋 **Lava/Slime Pit** → Deep gap + hazard content → STOP! Zero velocity
- 🕳️ **Jumpable Gap** → >60u deep, safe floor, moving fast → AUTO-JUMP!
- 🔥 **Hazard Floor** → Lava/slime at ground level → JUMP OVER IT!

**Integration:** CheckForHazards() runs at the start of Botmovetogoal() (line 1432) every frame before physics movement, ensuring bots check ground safety before committing to movement direction.

**Result:** Bots no longer casually walk into lava pools or fall off cliffs! Proactive ground scanning complements Phase 4's mid-air system for comprehensive hazard avoidance. Build size: 451,090 bytes (+424 bytes). 🛡️🌋✅

### 🧠 PHASE 8: Target Stack (Brain Memory) (2026-01-05)

**NEW:** Bots now remember interrupted goals across combat encounters!

Before Phase 8, bots would **forget** what they were doing when an enemy appeared:
- ❌ Bot pursuing Mega Health → spots enemy → fights → **forgets Mega Health** → wanders aimlessly

After Phase 8, bots have **actual memory** that persists through combat:
- ✅ Bot pursuing Mega Health → spots enemy → **saves Mega to stack** → fights → **restores Mega from stack** → resumes pursuit!

**Technical Implementation:**
- 🗂️ **3-deep LIFO goal stack** — Remembers up to 3 levels of interrupted goals (`.goal_stack1`, `.goal_stack2`, `.goal_stack3`)
- 💾 **Stack_Push()** — Saves current goal when enemy spotted, shifts stack downward
- 🔄 **Stack_Pop_Safe()** — Restores previous goal with validation (skips picked-up items, dead enemies)
- 🆕 **Stack_Clear()** — Wipes stack on bot respawn for fresh start
- 🎯 **Smart integration** — BotHuntTarget() pushes goals, endEnemy() pops them

**Multi-Level Interruptions:**
Handles complex scenarios like combat → combat → combat. Bot pursuing RA → enemy #1 spotted → **saves RA** → enemy #2 spotted → **saves enemy #1** → kills enemy #2 → **restores enemy #1** → kills enemy #1 → **restores RA** → gets RA!

**Result:** Bots complete missions instead of getting distracted! No more wandering aimlessly after fights. Massive intelligence upgrade that makes bots feel purposeful and goal-oriented. Build size: 450,666 bytes (+912 bytes). 🧠💾✅

### 🚀 Critical Rocket Jump Fixes (2026-01-04)

**FIXED:** Bots were firing rockets into the sky instead of at their feet!

Two critical bugs have been eliminated:

- ❌ **Bug #1: Wrong pitch in bot_rocket_jump()** — Used positive pitch (+85°, +45°) which made bots look UP instead of DOWN
- ❌ **Bug #2: Wrong pitch in "Vertical Solve" RJ** — Line 1491 used +80° (looking UP) instead of -80° (looking DOWN) — **THIS WAS THE MAIN BUG!**

**What's Fixed:**
- 🎯 **Correct pitch angles** — Changed to NEGATIVE values (-85°, -45°, -80°) for proper downward aim
- 🚀 **Both RJ systems work** — Smart trigger (skill >2) AND vertical solve (all skills) now execute correctly
- 📏 **Extended range** — Horizontal trigger range tripled (100u → 300u) for proactive RJ attempts
- 🏃 **Horizontal mobility** — Added distance check (>350u) to enable RJ for gaps and speed boosts, not just walls

**Result:** Bots now rocket jump like pros! Looking DOWN at feet, firing rockets at ground, getting proper blast propulsion upward! 🎯🚀✅

### 🌋 Mid-Air Hazard Avoidance (2026-01-04)

**NEW:** Bots detect and avoid landing in lava/slime during jumps!

- 🔮 **Trajectory prediction** — 0.15s lookahead predicts landing position
- 📍 **Hazard detection** — Traces downward 128u, checks `pointcontents()` for CONTENT_LAVA/SLIME
- 🔄 **Emergency steering** — Rotates velocity 90° perpendicular for sideways air-drift escape
- 💨 **Momentum preservation** — Maintains vertical component (90% speed) while steering away

**Result:** No more DM4 lava deaths! Bots air-steer away from hazards mid-jump instead of blindly landing in death! 🛡️💧

### 🗺️ DM4 Waypoint System Integration (2026-01-04)

**NEW:** Bots instantly know DM4 layout with 452 pre-loaded waypoints!

- 📦 **452 waypoints** — Expanded from 343 base + 109 routes discovered during Phase 7 testing
- ⚡ **Auto-loading** — Waypoints load automatically at frame 5 (after entity spawn)
- 🐍 **Python extraction tool** — `generate_dm4_waypoints.py` automates waypoint merging from logs with proper QuakeC string escape handling
- 🔧 **Build integration** — `maps/dm4.qc` compiled into progs.dat via progs.src

**How to verify:**
```bash
# Check console output after map load:
# "Loaded 452 waypoints for DM4"
```

**Result:** Bots have instant map knowledge! No learning period—they know all routes, shortcuts, and secrets immediately! 🧠💾

### 🎯 PHASE 6: Smart Triggers (2026-01-04)

**NEW:** Bots proactively solve button→door puzzles with waypoint target linking!

- 🔗 **Waypoint target linking** — Waypoints remember associated buttons/levers via 4th parameter: `SpawnSavedWaypoint('x y z', traffic, danger, "button_name")`
- 🎯 **Proactive button shooting** — Bots auto-fire buttons BEFORE hitting locked doors (no more running into walls!)
- 🧠 **Learning system** — When bots manually press buttons during gameplay, target links save to waypoint dumps
- 🔄 **Self-improving navigation** — Future bots automatically know button sequences from past discoveries
- 🔍 **Smart detection** — Checks button state (`STATE_BOTTOM`), verifies line-of-sight, aims with `vectoyaw()`, fires when ready

**How it works:**
1. Bot approaches waypoint with target link (e.g., `"secret_button"`)
2. Uses `find(world, targetname, Botgoal.target)` to locate button entity
3. Checks if button is unpressed and visible
4. Aims at button and shoots (`button0 = 1`)
5. Door opens smoothly—no collision with locked doors!

**Result:** Emergent secret-solving! Bots learn button→door sequences from gameplay and share knowledge through waypoint files. Creates human-like puzzle-solving without hardcoded solutions! 🚪🎯

### 💬 Personality-Driven Chat System (ULTRA EXPANDED)

Bots now **talk like real 90s FPS players** with 5 distinct personalities and bot-to-bot interactions:

- 🎭 **5 Unique Personalities** — RAGER (toxic), PRO (tactical), NOOB (confused), CAMPER (defensive), MEMELORD (chaotic)
- 💬 **144+ Messages** — 64+ idle comments, 80+ context-aware replies (kill/death/banter)
- 🔁 **Bot-to-Bot Banter** — 12% reply chance creates fluid conversations between bots
- ⏱️ **Realistic Timing** — Personality-based cooldowns (RAGERs spam 2-6s, PROs focus 6-14s)
- 🎯 **Context-Aware** — Different messages for kills, deaths, idle roaming, and replies
- 🔊 **Chat Sound** — Plays misc/talk.wav to signal messages (engine limitation workaround)

**Personality Examples:**
- 🔥 RAGER: "lag much?", "nice aimbot", "camping noob", "where are the admins?"
- 🎯 PRO: "gg", "armor up", "quad in 10", "controlling the map"
- 🤷 NOOB: "how do i rocket jump?", "oops", "this game is hard", "wrong weapon again"
- 🏰 CAMPER: "tactical positioning wins games", "im not camping im defending"
- 😂 MEMELORD: "git gud scrubs", "yeet", "u mad bro?", "this is fine", "leroy jenkins!"

**Result:** Bot chat feels like authentic 90s Quake servers! Personalities create hilarious rivalries and toxic banter! 🎮💬🔥

### 🧮 Mathematical Solvers Suite

Nightmare bots use **physics equations** for decision-making instead of heuristic guesses:

- 🎯 **Artillery Solver** — Solves projectile motion equation for perfect grenade arcs (tan(θ) = (v² - sqrt(discriminant)) / (g·x))
- 🚀 **Calculated Rocket Jump** — Physics check: max_h = V₀² / (2g) ≈ 189 units, prevents impossible RJ attempts
- 🌉 **Gap Solver** — Calculates horizontal range: t = sqrt(2h/g), d = v×t, prevents suicidal cliff runs
- ⚡ **Skill-based** — Skill > 2 uses perfect math, ≤2 uses heuristics (difficulty progression)

**Result:** High-skill bots calculate before acting! Grenade arcs through windows with mathematical certainty! RJs only when physics says possible! No more deaths from blind cliff runs! **"Heuristics are for behavior, equations are for capability."** 🧠📐

### 🎯 Oracle Aiming (Quadratic Prediction)

Nightmare bots use **mathematically perfect interception physics**:

- 🧮 **Quadratic solver** — Solves t² equation to find exact time-to-intercept
- 🎯 **Perfect leading** — Accounts for perpendicular strafing (no more circle-strafe exploits)
- 📐 **Physics-based** — Uses actual projectile speed (1000 u/s rockets) + enemy velocity
- ⚡ **Skill-gated** — Skill > 2 uses Oracle, ≤2 uses simple leading (difficulty curve preserved)

**Result:** High-skill bots hit strafing players with pro-level accuracy! Feels like fighting QuakeWorld veterans who master interception math! 🚀🔥

### 🗺️ A* Pathfinding (Optimal Route Solver)

Nightmare bots use **industry-standard graph search** for guaranteed optimal paths:

- 🧭 **True A* algorithm** — f = g + h, finds mathematically shortest path
- 🔗 **Linked list sets** — Open/Closed sets via entity chains (no array limits)
- 🆔 **Search ID system** — Instant state invalidation (no expensive clearing)
- 🎮 **16M op budget** — Leverages Quakespasm's massive instruction limit (50k iterations)
- ⚡ **Skill-based** — Skill > 2 uses A*, ≤2 uses greedy search (difficulty progression)

**Result:** High-skill bots never get stuck in local minima! A* guarantees optimal routes, discovers brilliant shortcuts greedy search misses—active and integrated! 🧠✨

### 💾 Auto Waypoint Dump (Periodic Persistence)

Automatically **capture learned navigation** to build persistent navmeshes:

- ⏰ **Periodic dumps** — Set `waypoint_dump_interval 60` to auto-dump every 60 seconds
- 📝 **Console output** — Dumps to console in QuakeC format (use `-condebug` to capture)
- 🗺️ **Learning as you play** — Bots/players drop breadcrumbs → system saves them periodically
- 📋 **Copy-paste ready** — Extract between CUT HERE markers, compile into static waypoints

**Result:** Play the game, let bots explore. System auto-saves navigation every N seconds. Copy output to create instant pre-baked navmeshes! 🤖💾

**Usage:** See [`WAYPOINT_DUMP_GUIDE.md`](WAYPOINT_DUMP_GUIDE.md) for full instructions.

### 🏔️ The Cliff Fix (One-Way Paths)

Bots now understand **drops they can't climb back up**:

- ⬇️ **Height-based linking** — Only links backward if <40 units (climbable stairs)
- 🚫 **Cliff detection** — DM2 Quad ledge drops become one-way (no upward link)
- 🏊 **Swimming exception** — Underwater paths link both ways (can swim up)
- 🔄 **Smart routing** — Finds alternate routes or uses rocket jumps instead

**Result:** No more bots running into cliff walls trying to walk up! They use proper routes or physics exploits to reach high ledges! 🧗‍♂️✨

### 🧱 Broken Path Pruning (Obstacle Discrimination)

Bots now **intelligently classify obstacles**:

- 🚧 **Wall detection** — Infinite cost for world geometry (permanently prunes broken paths)
- 🚪 **Door penalty** — +300 unit wait penalty (patient but not stuck)
- 📦 **Dynamic obstacles** — 1.5× penalty for monsters/boxes (temporary blockage)
- 🎯 **Smart classification** — Walls (infinite) > Doors (+300) > Monsters (1.5×)

**Result:** Broken paths get pruned instantly! Bots stop trying to run through solid walls and find working routes! 🗺️🔧

### 🌋 Hazard Costing (Lava Avoidance)

Bots now **avoid deadly hazards**:

- 🔥 **Midpoint check** — Detects lava/slime on path segments (+5000 penalty)
- 🛡️ **Safety priority** — Takes any safe detour before hazardous route
- 🏝️ **Last resort** — Only uses lava paths when NO other option exists
- 🧠 **Smart survival** — Routes around E1M3 lava like human players

**Result:** Bots take safe routes around hazards instead of suicidal shortest-path through lava! 🚶‍♂️💧

### 💪 Bully Mode (Aggressive Item Control)

Powered-up bots **dominate territory** instead of playing cautious:

- 🎯 **Inverted threat** — Enemy near item = BONUS when bot has Quad OR (100+ HP + RL)
- 💥 **Tactical baiting** — "Come get some!" behavior when stacked (seeks combat near items)
- 🏃 **Advantage pressing** — Rushes contested items instead of fleeing (leverages superior firepower)
- 🛡️ **Fallback caution** — Weak/unpowered bots still avoid threats (smart context awareness)

**Result:** Bot with Quad rushes Red Armor spawn even when enemy camps it—uses power advantage to dominate territory! 💪🔥

### 😠 Nemesis System (Grudge Tracking)

Bots now **take revenge** after being killed:

- 🎯 **Personal vendetta** — Tracks who killed this bot (30-second grudge timer)
- 🔥 **Revenge priority** — +2000 weight boost to hunt killer (ignores items/objectives)
- 💀 **Respawn hunting** — Bot A frags Bot B → Bot B hunts Bot A for 30s
- 🎮 **Human-like grudges** — Creates personal rivalries instead of emotionless combat

**Result:** Bots ignore Quad Damage to chase down their killer—revenge-driven AI that feels genuinely emotional! 😡⚔️

### 🌀 Folded Space Pathing (Instant Teleporters)

Bots now **master teleporter shortcuts**:

- ⚡ **Near-zero cost** — Teleporter routes cost 10 units vs 250 (instant travel)
- 🗺️ **Wormhole routing** — Bots see map as "folded space" with shortcuts
- 🏃 **Speedrun optimization** — Teleports across E1M7 instead of walking 800 units
- 🧠 **Brilliant shortcuts** — Discovers cross-map routes humans might miss

**Result:** Bots exploit teleporter networks like pro speedrunners—arrives first via "free" instant travel! 🚀✨

### ⏱️ Optimized Spawn Camping (4-Second Window)

Bots now use **mobile timing** instead of passive camping:

- 🏃 **Aggressive roaming** — Patrols area instead of standing idle (4s window vs 10s)
- 🎯 **Last-second dash** — Engages combat, then rushes spawn 3s before item appears
- 🎮 **Human-like timing** — Looks like timing practice instead of sentry duty
- 💀 **Harder to kill** — Mobile presence instead of predictable camping spot

**Result:** Bots patrol Quad area fighting, then dash to exact position 3 seconds before spawn—mobile control! ⚡🎯

### ⏱️ Human Reaction Time (No More Aimbots)

Bots now have **realistic input lag** when spotting enemies:

- 🧠 **Reaction delay** — Easy bots: 0.4s delay, Nightmare bots: 0.1s delay (skill-based scaling)
- 👀 **No instant snap** — Bots stare blankly for brief moment before tracking (human "oh shit" processing)
- 🔫 **Delayed firing** — Can't shoot until reaction time expires (no instant first-shot advantage)
- 🎯 **Fair engagement** — You get 0.1-0.4s window to react when rounding corners (feels like human opponents)
- 🤖 **Anti-aimbot** — Eliminates robotic instant-lock behavior that screams "I'm a bot"

**Result:** Bots feel human! No more perfect snap-aim-fire when surprised—they need to process "enemy spotted" like real players! 🎮🧑‍🤝‍🧑

### 🎯 Enhanced Ambush Behavior (The Camp Master)

Strong bots now **set ambushes** instead of blindly chasing:

- 🔊 **Sound detection** — Hears combat within 1000u (rocket fire, weapon sounds)
- 💪 **Confidence check** — Only healthy bots (>80 HP) with good weapons (RL/SNG/LG) ambush
- 🛑 **Stop and wait** — Freezes movement, faces sound source, holds position for 1.5s
- 🚪 **Corner camping** — Lets you round corner into their crosshairs instead of charging
- 🏃 **Fallback behavior** — Weak/unarmed bots still investigate by moving (tactical flexibility)

**Result:** Deadly corner campers! Hear fight → bot stops → aims at doorway → waits for you. Genuinely threatening! 😱🎯

### 🦘 Dynamic Stuck Wiggle (Spam Jump Unstuck)

Bots **immediately hop** when stalled instead of freezing:

- 📉 **Velocity detection** — Checks if speed <10 u/s while grounded (before 1s timeout)
- ⚡ **Instant response** — 20% chance per frame to micro-jump (220 u/s hop with sound)
- 🧱 **Clears obstacles** — Unstucks from lips, corners, steps without waiting
- 🎮 **Human-like** — Looks like player spam-jumping to wiggle free (not patient robot)

**Result:** No more 1-second freeze when hitting walls! Bots jump immediately like frantic humans trying to unstuck! 🦘✨

### 🎯 Finisher Logic (Ammo Conservation)

Bots now **save rockets** for healthy enemies:

- 💀 **Execution detection** — Identifies weak enemies (<20 HP) at close range (<RANGE_NEAR)
- 🔫 **Shotgun finisher** — Switches to hitscan shotgun for reliable kill on weak targets
- 🪓 **Axe fallback** — Uses melee if no shotgun (existing <40 HP logic)
- 💰 **Ammo economy** — Doesn't waste 25-damage rockets on 5 HP enemies

**Result:** Smart ammo management! Bots finish weak enemies with cheap weapons like pro players! 💸🎯

### 💥 Floor Shooting Tweak (Guaranteed Splash)

Rocket **floor shots** now reliably detonate at feet:

- 📐 **Improved aim** — Changed from `absmin_z + 8` (above feet) to `absmin_z - 4` (INTO floor)
- 💥 **Guaranteed detonation** — Rocket hits solid ground instead of air gap above feet
- 🎯 **Max splash damage** — Forces explosion at feet level (80+ damage guaranteed)
- 🏆 **Pro technique** — Exploits splash mechanics like human speedrunners

**Result:** Floor shots always detonate! Consistent splash damage when enemy is grounded—bots master splash physics! 💥🎯

### 🪜 Stair Smoothing (The "Step Up")

Bots now **glide smoothly** over stairs and debris:

- 🔍 **Step detection** — Traces at knee height (22u) when blocked to detect low obstacles vs walls
- 🎈 **Micro-hop** — 210 u/s vertical pop (smaller than jump) lifts bot just enough to clear step friction
- 🏃 **Fluid navigation** — No more stuttering on jagged stairs, crate piles, or uneven terrain
- 📦 **Handles DM6 crates** — Smoothly ascends multi-step obstacles without stuck loops
- 🎯 **Human-like** — Mimics how players naturally run up stairs without manual jumping

**Result:** Stairs become highways, not obstacles! Bots navigate vertical terrain with professional fluidity! 🎢✨

### 🚫 Fat Trace (Anti-Cookie Jar)

Bots recognize when they're **too fat to fit** through gaps:

- 👁️ **Shoulder width checking** — Dual traces at ±14u (matching 16u bot radius) detect narrow passages
- 🚧 **Bar detection** — Recognizes when center vision fits but body cannot (grates, bars, cages)
- 📏 **Distance awareness** — Only rejects if blockage close (<64u), allows pathfinding around distant obstacles
- 🎯 **Realistic collision** — No more staring at Red Armor through grates or Quad behind bars
- 🧠 **Smart filtering** — Ignores physically impossible goals, focuses on reachable items

**Result:** No more "cookie jar syndrome"! Bots understand physical constraints like humans! 🍪🚪

### 🎯 Action Breadcrumbs (The "Jump" Scent)

Teach bots **exact movement sequences** through demonstration:

- 🏃 **Jump tagging** — When you jump, waypoint is tagged with action_flag=1 (forced immediate drop at takeoff point)
- 🎬 **Action execution** — Bots detect jump nodes and execute 270 u/s jump when within 64u of trigger point
- 📍 **Precise timing** — 0.5s cooldown prevents spam, captures exact takeoff position for parkour sequences
- 🎮 **Teach by playing** — Jump onto DM2 train → bot learns to jump there. Hop crate stairs → bot replicates sequence
- 🧗 **Complex choreography** — Every gap you jump, every ledge you hop, bots will follow with identical timing

**Result:** You're now a movement choreographer! Program bot parkour by simply playing the game—no manual scripting needed! 🎭🎪

### 👤 The Shadow System (Player Learning)

Bots learn **directly from you** as you play:

- 🎓 **Human as teacher** — Player drops breadcrumbs like a bot (BotPath movetarget on spawn)
- 📍 **Automatic waypoint creation** — PlayerPostThink drops nodes every 0.1s when alive + grounded
- 🤝 **Shared navigation network** — Player nodes integrate instantly into bot pathfinding (no separate graph)
- ⚡ **Instant knowledge transfer** — Run complex route once → nearby bots see nodes → bots follow same path immediately
- 🎯 **Teaches by example** — Secret jumps, trick shots, optimal routes learned through observation, not manual editing

**Result:** You become the Master Teacher—bots inherit your advanced movement patterns in real-time! 🎮🧠

### 🚦 Street Smarts (Traffic Heatmaps)

Nodes learn **who goes where**, creating emergent tactical flow:

- 📊 **Traffic tracking** — Each node counts touches (capped at 100), creating "Main Street" vs "Back Alley" distinction
- ⚔️ **Hunting mode** — Healthy bots (>80 HP, no enemy) seek high-traffic nodes (+20× bonus) to find fights
- 🏃 **Fleeing mode** — Wounded bots (<40 HP) avoid high-traffic nodes (-50× penalty), take quiet back routes
- 🌀 **Organic evolution** — Early game: random wander. Mid game: atrium becomes "Hot Zone". Late game: Injured bot auto-routes through ventilation shafts to health pack
- 🧠 **Emergent tactics** — No explicit "danger zone" code—bots naturally learn where combat happens and adapt pathing accordingly

**Result:** Bots exhibit human-like map awareness—chase fights when aggressive, sneak when vulnerable! 🔥🎭

### 🚀 Enhanced Rocket Jump System

Bots now execute **proper rocket jumps** with professional-level control:

- ✅ **FIXED: Correct pitch angles** — Changed to NEGATIVE values (-85°, -45°, -80°) for looking DOWN at feet instead of UP at sky (2026-01-04 critical bugfix)
- ✅ **Health checks** — Won't suicide if HP < 40 (lowered for aggressive play)
- ⏱️ **2-second cooldown** — Prevents spam and maintains balance
- 🎯 **Directional aim control** — Dynamic pitch: -85° for high ledges, -45° for long gaps; yaw aims toward goal
- ⚡ **Synchronized timing** — Jump perfectly timed with rocket blast
- 🚀 **Aggressive leap** — 3× forward velocity (-320 u/s) enables gap crossing to DM2 Quad and similar platforms
- 🏔️ **Smart triggers** — Auto-RJ when ledges exceed 1.5× normal jump height (skill >2)
- 📏 **Extended range** — Horizontal trigger range 300u (tripled from 100u), distance trigger >350u for horizontal mobility
- 🎯 **Enhanced reachability** — Recognizes items up to 450u high as reachable, actively seeks and RJs to them
- 🆘 **Safe unstuck escape** — Replaces dangerous "turn and fire" with controlled RJ

**Result:** Bots reach unreachable platforms just like human speedrunners! RJ system now works correctly with proper downward aim! 🏃‍♂️💨✅

### 🚂 Train Navigation Enhancements

Advanced **path_corner chain prediction** for moving platforms:

- 🔗 **Multi-segment pathing** — Two-pass algorithm traverses entire train routes
- 🎯 **Future position prediction** — Bots intercept trains where they *will be*, not where they are
- 🌀 **Loop detection** — Handles cycling paths with modulo arithmetic
- 🏄 **Train surfing** — Desperate unstuck detects trains beneath bot, boosts escape velocity (1.5×)
- 📐 **Precise timing** — Jump arc prediction uses path chains for mid-air train sync

**Result:** Human-like timing for vertical/horizontal train navigation! 🚂✨

---

## 🛠️ Complete Feature Suite

### 🧭 Advanced Navigation

| Feature | Description |
|---------|-------------|
| 💾 **Smart Spacing** | 250u distance + LOS checks prevent node clumping for clean navigation networks |
| 📤 **Brain Dump** | Export learned waypoints to console (impulse 100) for manual persistence |
| 📥 **Waypoint Loader** | Import saved nodes to "bake" map knowledge—bots remember instantly |
| 🗺️ **DM4 Waypoint Integration** | 452 pre-loaded waypoints (343 base + 109 from Phase 7), auto-loads at frame 5 (2026-01-05) |
| 🐍 **Python Extraction Tool** | Automates waypoint merging from qconsole.log via generate_dm4_waypoints.py (2026-01-04) |
| ☠️ **Danger & Glory** | Learns death zones (avoid) and power positions (seek)—emergent tactical evolution |
| 🛗 **Platform Mastery** | Learns elevator paths, waits patiently at lift shafts, uses DM2 lift intelligently |
| 📊 **Platform Prediction** | Velocity + state forecasting for timed jumps on moving plats |
| 🎯 **Jump Arc Collision** | Mid-air platform detection for precise airborne landings |
| 🔘 **Button Shoot + Wait** | Auto-fires shootables, monitors door state for fluid secrets |
| 🎯 **Smart Triggers (Phase 6)** | Waypoint target linking—bots auto-shoot buttons before locked doors, learn sequences from gameplay (2026-01-04) |
| 🛗 **Ride Auto-Follow** | Velocity inheritance + goal tracking for seamless platform travel |
| 🆘 **Desperate Unstuck** | Escalates to rocket jump/super jump after 5+ stuck attempts |
| 🏔️ **Ledge Jump Pursuit** | Detects enemies 32+ units below, executes forward jump to chase down ledges (2026-01-04) |

### ⚔️ Combat Mastery

| Feature | Description |
|---------|-------------|
| 💣 **Grenade Bounce Prediction** | 1-bounce physics for wall-bank shots and corner kills |
| 🌈 **Gravity Arc Simulation** | Full parabolic trajectory for long-range lobs |
| 🎯 **Predictive Aim** | Splash height variance + vertical lead + velocity smoothing |
| 🎬 **Human-Like Aim Smoothing** | Pitch slew rate system (150-450°/s by skill) replaces aimbot snap-lock |
| 🛡️ **Self-Risk Validation** | Aborts GL fire if self-splash risk < 128u |
| 💣 **GL Close-Range Safety** | Auto-switches GL→SSG/SNG/LG when enemy <200u to prevent suicide grenades (arc math fails at close range) |
| 🎯 **Floor Shooting (RL)** | Aims at enemy feet instead of chest for guaranteed splash damage (80+ even on miss) |
| 🧱 **Corner Clipping (RL/GL)** | Fires splash weapons at walls/floors within 110u of hidden enemies |
| 🛡️ **Suicide Prevention (RL)** | Prioritizes SSG/SNG/LG at melee range to avoid point-blank rocket deaths |
| 🔫 **Active Projectile Dodging** | Scans for grenades/missiles within 240u, calculates perpendicular escape vectors, prioritizes threats by owner skill + distance (Phase 7: FrikBot-inspired) |
| 🧱 **Wall Sliding + Combat Hopping** | Vector slide + active bunny-hopping (20% vs RL, 10% combat, LG stable) |

### 🧠 Tactical AI

| Feature | Description |
|---------|-------------|
| 🎯 **The Profiler** | Opponent behavior tracking: Analyzes enemy movement patterns (approach/retreat) to build aggression profiles (0-10 score). Adapts tactics dynamically—retreat & trap vs rushers (>7.0), push aggressively vs campers (<3.0). Human-like playstyle adaptation mid-match (2026-01-06) |
| 👂 **Simulated Perception** | Hearing module: Detects invisible enemies through walls via noise (weapon fire, footsteps >200 u/s, jumps, quad/pent hum). Pre-aims at doorways where enemies approach (800u range). Adds suppressive RL/GL spam at heard locations (160-800u) to punish loud hallway play (2026-01-10) |
| 🎯 **The FFA Fix** | Intelligent multi-target awareness: Scans all enemies, scores by distance/health/threat, switches mid-combat for better targets. Vulture mode (+500 for <40 HP), self-defense (+800 for attackers), 1.5s re-scan with hysteresis (data-driven optimization, 2026-01-05) |
| 🧠 **Target Stack (Phase 8)** | 3-deep LIFO goal memory—bots remember interrupted missions across combat (pursuing Mega → enemy → fight → **restore Mega**) |
| 📊 **Risk-Aware Scoring** | Need-based item boosts minus threat penalty (proximity -80 max) |
| 🎒 **Smart Backpack Scavenging** | Intelligent prioritization when starving for weapons/ammo (3000 weight if missing RL/LG) |
| ⚔️ **Weapon Counter-Tactics** | Rock-paper-scissors logic: RL counters LG (knockback), LG counters RL (hitscan) |
| 🗺️ **Global Scavenger Hunt** | Map-wide item scan when alone (RL/LG/RA/Mega prioritization vs random wander) |
| 🧩 **Problem Solver** | Dynamic obstacle solving: RJ for high items, button-door linking, shootable detection |
| ⏰ **Spawn Camping** | Timer-based item control: camps RL/Quad/RA/Mega respawns (<10s), waits at spawn points |
| 🌀 **Circle Strafing** | Smooth 1.5s orbital movement (80° spiral-in) replaces erratic zigzag for disorientation |
| 💣 **Retreat Trap** | Drops grenade when fleeing (10% chance) to punish aggressive pursuers |
| 🔍 **Ambush Mode** | Investigates combat sounds (1000u range) for third-party opportunistic kills |
| 🌐 **Portal Awareness** | Recognizes teleporters as shortcuts, plans routes through them, seeks them as "mystery boxes" |
| 🏆 **Powerup Denial** | Amplified aggression when leading or enemy weak (<40 HP) |
| 🔄 **Adaptive Goals** | Health when hurt, denial when leading, smart roam patterns |
| 💰 **Weapon Conservation** | Rocket economy, Quad/Pent counters, ammo awareness |
| 🔥 **Adrenaline Focus** | Tighter aim + faster think cycles under pressure |
| 🧩 **Spawn Memory** | High-skill bots pre-cache key routes at spawn |
| 📈 **Streak Tuning** | Dynamic difficulty based on kill/death streaks |

### 🏃 Physics Systems

| Feature | Description |
|---------|-------------|
| 🏎️ **The Racing Line** | Corner smoothing: Blends aim 70% current + 30% next waypoint within 120u for smooth curves through doorways (2026-01-05) |
| 🎯 **Strafe Hysteresis** | Anti-vibration: 0.5s direction commitment prevents seizure-like jitter, creates smooth combat arcs (2026-01-05) |
| 🖱️ **Analog Turning** | Dynamic yaw speed: 5°/frame tracking, 20°/frame cornering, 45°/frame flicks for human-like aim (2026-01-05) |
| 🐰 **Bunny Hop Mechanics** | Skill-based strafe-jump acceleration (skill >2, +12 u/s boost, 600 u/s cap) plus traversal strafe-jumping on long clear runs |
| 🎢 **Jump Smoothing** | 3-frame moving average eliminates jittery trajectories |
| 🪂 **Mid-Air Correction** | 20% velocity damping when trajectory becomes unreachable |
| 🌋 **Mid-Air Hazard Avoidance** | 0.15s trajectory prediction + 90° emergency steering away from lava/slime (2026-01-04) |
| 🎯 **Finer Arc Simulation** | 0.05s timesteps for precise parabolic prediction |
| 🏃 **Strafe Momentum** | 30% velocity carryover simulates realistic running jumps |
| 🚧 **Multi-Trace Validation** | 2× sampling density catches walls/clips sparse checks miss |
| 📏 **Horizontal Reachability** | Recognizes distant items (>350u) as RJ-accessible, applies 1.3× weight multiplier (2026-01-04) |

---

## 🚀 Quick Start

### Prerequisites

- 🎮 Quake 1 (registered version with `id1/PAK0.PAK` and `PAK1.PAK`)
- 🪟 Windows (x64 or x86)

### One-Click Launch

1. **Navigate to launch directory:**
   ```bash
   cd launch/quake-spasm
   ```

2. **Run the launcher:**
   ```bash
   launch_reaper_mre.bat 8 dm4
   ```
   *(8 players on DM4 — adjust as needed)*

3. **Verify waypoint loading (optional):**
   - Check console output for "Loaded 452 waypoints for DM4"
   - Confirms bots have instant map knowledge! 🗺️

4. **Enjoy!** 🎮

### Custom Launch

```bash
launch_reaper_mre.bat [maxplayers] [map]

# Examples:
launch_reaper_mre.bat 4 dm2    # 4 players on The Claustrophobopolis
launch_reaper_mre.bat 6 dm6    # 6 players on The Dark Zone
launch_reaper_mre.bat 16 dm3   # 16-player chaos on The Abandoned Base
```

---

## 🎮 Impulse Commands Reference

MRE includes a comprehensive set of impulse commands for bot management, debugging, camera control, and testing. All commands are entered in the console (press `` ` `` or `~` to open).

### 📋 Core Bot Commands

| Command | Function | Description |
|---------|----------|-------------|
| `impulse 208` | **Spawn 4 Bots** | Adds 4 bots to the match (quickest way to start a bot game) |
| `impulse 205` | **Add 1 Bot** | Adds a single bot to the current match |
| `impulse 211` | **Remove All Bots** | Removes all bots from the match |

**Example Usage:**
```
impulse 208        # Spawn 4 bots instantly
impulse 205        # Add one more bot (now 5 total)
impulse 211        # Remove all bots (back to player-only)
```

---

### 🐛 Debug & Analysis Commands

| Command | Function | Description |
|---------|----------|-------------|
| `impulse 95` | **Debug Toggle** | Enable/disable ALL bot debug logging |
| `impulse 96` | **Verbosity Cycle** | Cycle through debug verbosity levels (OFF → CRITICAL → NORMAL → TACTICAL → VERBOSE → DEBUG) |
| `impulse 97` | **Feeler Debug Toggle** | Enable/disable feeler steering exploration logging (only prints when exploration mode is active) |

**Debug Verbosity Levels:**
- **OFF (0)**: No logging
- **CRITICAL (1)**: Stuck/failures/suicides only
- **NORMAL (2)**: Target/goal changes
- **TACTICAL (3)**: Weapon switches, combos, dodges, profiling
- **VERBOSE (4)**: Movement, routing, perception
- **DEBUG (5)**: Everything (very spammy!)

**Example Debug Session:**
```
impulse 95         # Enable debug logging (starts at OFF → goes to CRITICAL)
impulse 96         # Cycle to NORMAL (target/goal changes)
impulse 96         # Cycle to TACTICAL (weapon/combos/profiling)
impulse 97         # Enable feeler exploration logging
# Play for a while...
impulse 95         # Disable debug logging
```
Note: feeler logs only appear when bots enter exploration mode (no nearby waypoints). On waypoint-dense maps like DM4, you may not see FEELER/BREADCRUMB output unless bots reach unmapped areas.

**Log Output Examples:**
```
[Cheater] TARGET: Drooly (score=624.4, HP=100, dist=551.2u)
[Cheater] PROFILE: Drooly is PASSIVE (  2.3) → Push Aggressively
[Cheater] WEAPON: GL → SSG (GL-suicide-prevent)
[Wanton] COMBO: RL → LG (Juggler shaft-combo)
[Drooly] STUCK: Desperate escape (count=6)
[Drooly] UNSTUCK: Rocket jump escape
[Assmunch] FEELER: Exploration mode activated (no waypoints nearby)
[Assmunch] BREADCRUMB: Dropped at '1024 512 64'
```

**Important:** All debug logs are saved to `qconsole.log` in your Quake directory for post-match analysis!

---

### 🎥 AI Cameraman Commands

| Command | Function | Description |
|---------|----------|-------------|
| `impulse 99` | **AI Director Mode** | Activate AI Cameraman (auto-tracks exciting action) |
| `impulse 98` | **Exit Camera** | Return to player mode (exits spectator) |
| `impulse 50` | **Flyby Mode** | Cinematic tracking (smooth camera flyby) |
| `impulse 51` | **Follow Mode** | Over-shoulder tracking (follows target closely) |
| `impulse 53` | **Free Flight** | Fly around freely (manual camera control) |
| `impulse 60` | **Toggle Info** | Show/hide target name display |
| `impulse 61` | **Next Target** | Manually cycle to next player/bot |

**AI Cameraman Workflow:**
```
# 1. Spawn bots FIRST (important!)
impulse 208        # Spawn 4 bots

# 2. Activate AI Cameraman
impulse 99         # Become spectator, AI director takes over

# 3. Watch the action! Camera auto-switches to exciting moments

# 4. Manual override (optional)
impulse 50         # Switch to flyby mode
impulse 61         # Cycle to next target
impulse 99         # Return to AI director mode

# 5. Return to player
impulse 98         # Exit camera, become player again
```

**What the AI Tracks:**
- 🔥 Active combat (CQC battles prioritized)
- 💀 Underdog scenarios (wounded bots fleeing)
- ⚡ Powerup plays (quad/pent rampages)
- 🚀 Pro movement (rocket jumps, bunny hopping)
- 🏆 Leader highlights (high-scoring bots)

---

### 🗺️ Waypoint & Navigation Commands

| Command | Function | Description |
|---------|----------|-------------|
| `impulse 100` | **Dump Waypoints** | Export all waypoints to console (for map authors) |
| `impulse 13` | **Watcher Mode** | Enter waypoint editing mode (advanced use) |

**Waypoint Dumping Workflow:**
```
impulse 100        # Dump waypoints to console
# Check console output for waypoint data
# Copy from qconsole.log to save waypoints
```

**Note:** Waypoints are automatically loaded for supported maps (DM1-DM6, E1M1-E1M8). Dumping is useful for:
- Map authors creating new waypoint files
- Debugging navigation issues
- Saving breadcrumb waypoints from feeler exploration mode

---

### 🎨 Customization Commands

| Command | Function | Description |
|---------|----------|-------------|
| `impulse 200` | **Next Skin** | Cycle bot skin forward (player customization) |
| `impulse 201` | **Previous Skin** | Cycle bot skin backward |
| `impulse 202` | **Skins Mode** | Toggle skin randomization mode |

**Example:**
```
impulse 200        # Cycle to next skin (try different colors)
impulse 202        # Enable random skins for all bots
```

---

### 📊 Information & Scoring Commands

| Command | Function | Description |
|---------|----------|-------------|
| `impulse 204` | **Show Intro** | Display bot introduction message |
| `impulse 210` | **My Scores** | Display player scores (personal stats) |
| `impulse 220` | **All Scores** | Display all player/bot scores (full scoreboard) |
| `impulse 222` | **Top Scores** | Display top scores (leaderboard) |
| `impulse 221` | **Update Colors** | Refresh team colors (teamplay mode) |

---

### 🔧 Advanced/Testing Commands

| Command | Function | Description |
|---------|----------|-------------|
| `impulse 100-115` | **Set Bot Count** | Set exact number of bots (e.g., `impulse 104` = 4 bots) |
| `impulse 214` | **Bot Gravity** | Toggle bot gravity settings (testing) |
| `impulse 215` | **Verbose Mode** | Enable verbose bot output (legacy debug) |
| `impulse 217` | **Path Count** | Print number of waypoint paths (diagnostic) |
| `impulse 117` | **Pather Count** | Print number of active pathfinders (diagnostic) |
| `impulse 118` | **Bot Count** | Print number of active bots (diagnostic) |
| `impulse 119` | **Server Flags** | Print current server flags (diagnostic) |
| `impulse 218` | **Restrict Mode** | Enable restricted mode (limits commands) |
| `impulse 219` | **Super Restrict** | Enable super restricted mode (further limits) |
| `impulse 223` | **Invulnerability** | Give player invulnerability (cheat/testing) |

**Testing Example:**
```
impulse 223        # Make yourself invulnerable
impulse 104        # Spawn exactly 4 bots
impulse 217        # Check waypoint path count
impulse 118        # Check active bot count
```

---

### ⌨️ Standard Quake Impulses (Still Work!)

MRE is fully compatible with standard Quake impulse commands:

| Command | Function |
|---------|----------|
| `impulse 1` | Axe |
| `impulse 2` | Shotgun |
| `impulse 3` | Super Shotgun |
| `impulse 4` | Nailgun |
| `impulse 5` | Super Nailgun |
| `impulse 6` | Grenade Launcher |
| `impulse 7` | Rocket Launcher |
| `impulse 8` | Lightning Gun |
| `impulse 10` | Next Weapon |
| `impulse 12` | Previous Weapon |

---

### 💡 Quick Reference Cheat Sheet

**Starting a Bot Match:**
```
impulse 208        # Spawn 4 bots
impulse 95         # Enable debug logging
impulse 96         # Cycle to TACTICAL verbosity
# Play and watch the logs!
```

**Spectating with AI Camera:**
```
impulse 208        # Spawn bots first!
impulse 99         # Activate AI Cameraman
# Sit back and watch the action
impulse 98         # Return to player when done
```

**Debugging Navigation:**
```
impulse 97         # Enable feeler exploration logging
impulse 95         # Enable main debug logging
impulse 96         # Cycle to VERBOSE
# Watch bots navigate, check for stuck events
impulse 100        # Dump waypoints to see coverage
```

**Post-Match Analysis:**
```
# After playing, check qconsole.log for detailed logs
# Look for patterns in STUCK events, PROFILE decisions, WEAPON switches
# Use data to validate bot behavior and tune AI
```

---

## 🏗️ Building from Source

### Directory Structure

```
reaper_mre/              ← Active development (QuakeC source)
├── botmove.qc          ← Movement, navigation, rocket jumps, train prediction
├── botfight.qc         ← Combat AI, weapon selection, predictive aim
├── botthink.qc         ← Physics systems, air control, velocity management
├── botit_th.qc         ← Entity fields, bot state tracking
├── botvis.qc           ← Visibility, reachability, pathfinding
├── botgoal.qc          ← Goal selection, item scoring, tactics
├── progs.src           ← Build manifest (entry point for compiler)
└── ...                 ← Additional QuakeC modules

tools/fteqcc_win64/
└── fteqcc64.exe        ← Compiler binary

launch/quake-spasm/
├── reaper_mre/         ← Deployed progs.dat (build artifact)
├── launch_reaper_mre.bat  ← Quick launch script
└── quakespasm.exe      ← Quake engine
```

---

### Full Build Workflow

#### Step 1: Compile Source

**Command:**
```bash
cd c:\reaperai
tools\fteqcc_win64\fteqcc64.exe -O3 reaper_mre\progs.src
```

**What it does:**
- Compiles all `reaper_mre/*.qc` files into `reaper_mre/progs.dat`
- `-O3` flag enables maximum optimization
- Output: ~380 KB binary

**Expected output:**
```
Compiling progs.dat
...
Successfull compile! (with warnings)
```

---

#### Step 2: Deploy Build Artifact

**Commands:**
```bash
# Deploy to test environment
copy reaper_mre\progs.dat launch\quake-spasm\reaper_mre\progs.dat /Y

# Deploy to CI validation directory
copy reaper_mre\progs.dat ci\reaper_mre\progs.dat /Y
```

**What it does:**
- Copies compiled `progs.dat` to runtime directories
- `/Y` flag suppresses overwrite confirmation
- Creates deployable artifact for testing

---

#### Step 3: Launch and Test

**Normal Play (recommended):**
```bash
cd launch\quake-spasm
launch_reaper_mre.bat 8 dm4
```
- Starts 8-player deathmatch on DM4
- Uses standard game settings
- No console output

**Debug Mode (verbose logging):**
```bash
cd launch\quake-spasm
quakespasm.exe -basedir . -game reaper_mre -listen 8 +map dm4 +skill 3 +deathmatch 1 +maxplayers 8 +impulse 208
```
- `-listen 8` = Run as listen server (keeps game running for observation)
- `+skill 3` = Expert bots (full AI capabilities)
- `+impulse 208` = Spawns bots via console command
- Logs output to `qconsole.log`

**Console Commands (in-game):**
```
skill 3           // Set difficulty (0-3, higher = smarter)
impulse 100       // Add 1 bot
impulse 101       // Add bots until maxplayers
impulse 102       // Remove 1 bot
impulse 208       // Mass-spawn bots
```

---

#### Step 4: Verify Functionality

**Check console log:**
```bash
type launch\quake-spasm\qconsole.log
```

**Expected indicators of success:**
- `Programs occupy 376K` (confirms progs.dat loaded)
- Bot spawn messages: `Cheater (iq 1) is reformed Thanks Chris.`
- No `Host Error` messages
- Expected warnings only (missing music files, IPX disabled)

**Test rocket jumps:**
- Watch skill 3 bots on DM3/DM4
- Should see bots rocket-jumping to high ledges
- No suicide deaths at low HP

**Test train navigation:**
- DM6 has moving trains
- Bots should intercept trains mid-movement
- No "stuck" loops near trains

---

### CI Pipeline (Automated Build)

#### GitHub Actions Workflow

**File:** `.github/workflows/ci.yml`

**Trigger:** Every push to repository

**Build steps:**
1. **Compile:** Run `fteqcc64.exe -O3 reaper_mre\progs.src`
2. **Validate:** Check build size (~380 KB)
3. **Archive:** Upload `reaper_mre-progs.dat` as artifact
4. **Status:** Report success/failure

**Artifact download:**
- Go to [Actions tab](https://github.com/saworbit/mre/actions)
- Click latest workflow run
- Download `reaper_mre-progs.dat` from artifacts

**Integration:**
```bash
# Download artifact from CI
curl -L -o progs.dat https://github.com/saworbit/mre/actions/runs/[RUN_ID]/artifacts/[ARTIFACT_ID]

# Deploy to local test environment
copy progs.dat launch\quake-spasm\reaper_mre\progs.dat /Y
```

---

### Complete Development Workflow

This section documents the full end-to-end development cycle for implementing and testing features.

#### Prerequisites Check

**Required files and tools:**
```
c:\reaperai\
├── tools\fteqcc_win64\fteqcc64.exe   ← Compiler (must exist)
├── reaper_mre\*.qc                   ← Source files (active development)
├── reaper_mre\progs.src              ← Build manifest
├── launch\quake-spasm\               ← Test environment
│   ├── quakespasm.exe                ← Engine binary
│   ├── id1\PAK0.PAK                  ← Game data (required)
│   ├── id1\PAK1.PAK                  ← Game data (required)
│   └── reaper_mre\                   ← Deployment target
└── ci\reaper_mre\                    ← CI validation target
```

**Verify setup:**
```bash
# Check compiler exists
dir tools\fteqcc_win64\fteqcc64.exe

# Check source files
dir reaper_mre\*.qc

# Check engine
dir launch\quake-spasm\quakespasm.exe

# Check game data
dir launch\quake-spasm\id1\*.PAK
```

---

#### Workflow: Making Code Changes

**Step 1: Edit QuakeC source files**

Edit files in `reaper_mre/` directory:
- `botmove.qc` — Movement, navigation, jumps, trains
- `botfight.qc` — Combat, weapons, aim
- `botthink.qc` — Physics, air control
- `botvis.qc` — Visibility, reachability
- `botgoal.qc` — Item scoring, tactics
- `botit_th.qc` — Entity fields (add `.float` variables here)

**QuakeC syntax constraints:**
- No ternary operators: Use `if/else` blocks
- No compound assignment: `x = x + 1` not `x += 1`
- No increment: `x = x + 1` not `x++`
- Forward declarations required: If function A calls function B before B is defined, add `float() B;` at top

**Step 2: Compile the source**

```bash
# Change to project root
cd c:\reaperai

# Run compiler with optimization
tools\fteqcc_win64\fteqcc64.exe -O3 reaper_mre\progs.src
```

**Success indicators:**
```
Compiling progs.dat
<compilation output>
Successfull compile! (with warnings)
```

**Expected output file:**
- Location: `reaper_mre\progs.dat`
- Size: ~380 KB (376-384 KB range)
- Warnings: Expected (missing precache, unused variables)
- Errors: Must be 0 for success

**Failure indicators:**
- `error: <message>` lines in output
- No `progs.dat` file created
- Build stops before "Successfull compile!"

**Step 3: Deploy to test environments**

```bash
# Deploy to primary test location
copy reaper_mre\progs.dat launch\quake-spasm\reaper_mre\progs.dat /Y

# Deploy to CI validation location
copy reaper_mre\progs.dat ci\reaper_mre\progs.dat /Y
```

**Success indicators:**
- `1 file(s) copied.` for each copy command
- Files exist at target locations

**Verify deployment:**
```bash
# Check file sizes match
dir reaper_mre\progs.dat
dir launch\quake-spasm\reaper_mre\progs.dat
dir ci\reaper_mre\progs.dat
```

---

#### Workflow: Testing Changes

**Quick test (normal play):**

```bash
# Navigate to test environment
cd launch\quake-spasm

# Launch with standard settings
launch_reaper_mre.bat 8 dm4
```

**Parameters:**
- `8` — Max players (2-16)
- `dm4` — Map name (dm2, dm3, dm4, dm5, dm6)

**What happens:**
- Quake engine launches in window
- Map loads with 8 player slots
- Bots spawn automatically
- No console log output

**Debug test (verbose logging):**

```bash
# Navigate to test environment
cd launch\quake-spasm

# Launch with debug flags
quakespasm.exe -basedir . -game reaper_mre -listen 8 +map dm4 +skill 3 +deathmatch 1 +maxplayers 8 +impulse 208
```

**Debug flags explained:**
- `-basedir .` — Use current directory as Quake root
- `-game reaper_mre` — Load reaper_mre mod
- `-listen 8` — Run as listen server (keeps game running for observation, prevents "server is full" exit)
- `+map dm4` — Auto-load DM4 map
- `+skill 3` — Expert difficulty (enables all AI features)
- `+deathmatch 1` — Deathmatch mode
- `+maxplayers 8` — 8 player slots
- `+impulse 208` — Mass-spawn bots command

**What happens:**
- Console output written to `qconsole.log`
- Verbose loading information displayed
- Bot spawn messages logged
- All errors/warnings captured

**In-game console commands:**

```
skill 0           // Novice bots (IQ 1.0)
skill 1           // Intermediate (IQ 1.5)
skill 2           // Advanced (IQ 2.0)
skill 3           // Expert (IQ 3.0, full features)

impulse 100       // Add 1 bot
impulse 101       // Fill server with bots
impulse 102       // Remove 1 bot
impulse 208       // Mass-spawn bots
```

---

#### Workflow: Verifying Functionality

**Step 1: Check console log**

```bash
type launch\quake-spasm\qconsole.log
```

**Success indicators:**
```
Quake 1.09 (c) id Software
...
execing quake.rc
...
Programs occupy 376K.
...
Cheater (iq 1) is reformed Thanks Chris.
Cheat (iq 1) is reformed Thanks Chris.
<more bot spawn messages>
```

**Failure indicators:**
- `Host Error: <message>` — Critical failure, progs.dat didn't load
- `SV_Error: <message>` — Runtime error in QuakeC code
- No bot spawn messages — Bots not spawning
- `Bad entity field` — Field definition error in botit_th.qc

**Expected warnings (safe to ignore):**
```
Couldn't load gfx/ipx.cfg.
CD track 2 not found
Couldn't exec config.cfg
```

**Step 2: Test specific features**

**Rocket jumps (skill 3 required):**
- Maps: DM3, DM4 (have high ledges)
- Watch bots near high platforms
- Should see upward rocket blast + jump
- Verify no suicide at low HP (<50)
- Check cooldown (2 seconds between RJs)

**Train navigation:**
- Map: DM6 (has func_train entities)
- Watch bots near moving platforms
- Should intercept trains at future positions
- No "stuck" loops near trains
- Bots should ride trains smoothly

**Platform prediction:**
- Maps: DM3, DM5 (have moving platforms)
- Watch bots jump onto rising/falling platforms
- Precise mid-air landings
- Follow platform motion after landing

**Combat AI:**
- Skill 3 bots should use all weapons tactically
- Grenade launcher lobs at distant targets
- Rocket conservation (don't spam)
- Evasion patterns vs enemy rockets

**Step 3: Performance check**

**Verify no stuck loops:**
- Watch bots for 2-3 minutes
- Should not spin in corners
- Should escape geometry traps (rocket jump, super jump)
- Movement should be fluid

**Verify FPS stability:**
- Check console: `host_framerate` command
- Should maintain ~60 FPS with 8 bots
- No stuttering or freezes

---

#### Workflow: Documentation Updates

**After verifying features work, update documentation:**

**Step 1: Update source code comments**

Add comments in `.qc` files:
```quakec
// ============================================================
// Feature Name
// ============================================================
// Description of what this function/section does
// Parameters: self = bot entity
// Returns: TRUE if success, FALSE if failure
// ============================================================
float() example_function =
{
    // Implementation
};
```

Example: See `bot_rocket_jump()` in [botmove.qc:627-667](reaper_mre/botmove.qc#L627-L667)

**Step 2: Update CHANGELOG.md**

Add entry to "## Unreleased" section:

```markdown
## Unreleased

- **Feature category name** for [navigation|combat|tactics|physics]:
  - **Implementation detail** in `reaper_mre/file.qc`: Technical description with function names, algorithms, mechanics. Explain what problem it solves and how.
  - **Integration point** in `reaper_mre/file.qc`: Where/how feature integrates with existing systems.
  - Added `.float field_name` field in `reaper_mre/botit_th.qc` for [purpose].
```

**Step 3: Update README.md**

Add to appropriate feature table:

```markdown
| Feature | Description |
|---------|-------------|
| 🆕 **Your Feature** | Concise description of capability and benefit |
```

Update if needed:
- Quick Start section — if launch process changed
- Skill Levels table — if bot behavior changed
- Testing Maps — if map-specific features added

**Step 4: Verify documentation**

```bash
# Check markdown renders correctly
type README.md
type CHANGELOG.md

# Verify file references
dir reaper_mre\botmove.qc
dir reaper_mre\botit_th.qc
```

---

#### Workflow: Git Commit and Push

**Step 1: Check status**

```bash
git status
```

**Expected changes:**
- Modified: `reaper_mre/*.qc` files
- Modified: `CHANGELOG.md`
- Modified: `README.md`
- Untracked: None (reaper_mre/*.qc should be tracked)

**Note:** `progs.dat` files should NOT appear (ignored by .gitignore)

**Step 2: Stage changes**

```bash
# Stage source code
git add reaper_mre/

# Stage documentation
git add CHANGELOG.md README.md

# Verify staged files
git status
```

**Step 3: Create commit**

```bash
git commit -m "Add [feature name]: [brief description]

[Detailed description paragraph explaining what was added, why, and what problem it solves]

Technical changes:
- Enhanced [file.qc] with [specific function/logic]
- Added [field name] to botit_th.qc for [purpose]
- Updated [system] to integrate with [new feature]
"
```

**Good commit message example:**
```
Add enhanced rocket jump system: safe controlled navigation

Replaced crude "turn and fire" rocket jump with sophisticated system featuring health checks (<50 HP suicide prevention), 2-second cooldown, precise pitch/yaw control (90° down + 180° backward), and synchronized jump timing.

Technical changes:
- Implemented bot_rocket_jump() in botmove.qc with safety checks
- Added .float rj_cooldown field to botit_th.qc for spam prevention
- Enhanced Bot_tryjump() to trigger RJ for high ledges (>1.5× MAXJUMP)
- Upgraded desperate unstuck to use enhanced RJ instead of crude fire
```

**Step 4: Push to GitHub**

```bash
git push origin master
```

**Success indicators:**
```
Enumerating objects: X, done.
Counting objects: 100% (X/X), done.
Delta compression using up to Y threads
Compressing objects: 100% (X/X), done.
Writing objects: 100% (X/X), Z KiB | Z MiB/s, done.
Total X (delta Y), (reused Z) (delta W)
To https://github.com/saworbit/mre
   abc1234..def5678  master -> master
```

**Step 5: Verify GitHub Actions CI**

1. Go to [GitHub Actions](https://github.com/saworbit/mre/actions)
2. Check latest workflow run
3. Verify "Build Reaper MRE" workflow succeeded
4. Download artifact `reaper_mre-progs.dat` to verify build

---

#### Quick Reference: Common Tasks

**Rebuild after code change:**
```bash
cd c:\reaperai
tools\fteqcc_win64\fteqcc64.exe -O3 reaper_mre\progs.src
copy reaper_mre\progs.dat launch\quake-spasm\reaper_mre\progs.dat /Y
```

**Quick test:**
```bash
cd launch\quake-spasm
launch_reaper_mre.bat 8 dm4
```

**Debug test:**
```bash
cd launch\quake-spasm
quakespasm.exe -basedir . -game reaper_mre -listen 8 +map dm4 +skill 3 +deathmatch 1 +maxplayers 8 +impulse 208
```

**Check logs:**
```bash
type launch\quake-spasm\qconsole.log
```

**Full workflow (one command block):**
```bash
cd c:\reaperai && tools\fteqcc_win64\fteqcc64.exe -O3 reaper_mre\progs.src && copy reaper_mre\progs.dat launch\quake-spasm\reaper_mre\progs.dat /Y && copy reaper_mre\progs.dat ci\reaper_mre\progs.dat /Y
```

---

### Documentation Update Workflow

**After adding new features:**

1. **Update source code comments:**
   - Add `// =====` section headers in `.qc` files
   - Document function purpose, parameters, return values
   - Example: See `bot_rocket_jump()` in `reaper_mre/botmove.qc:627-667`

2. **Update CHANGELOG.md:**
   ```markdown
   ## Unreleased

   - **Feature name** for category:
     - **Implementation** in `file.qc`: Description with technical details...
   ```

3. **Update README.md:**
   - Add feature to appropriate table (Navigation/Combat/Tactical/Physics)
   - Update Quick Start if workflow changes
   - Update skill level descriptions if behavior changes

4. **Test and verify:**
   - Compile → Deploy → Launch → Test
   - Check `qconsole.log` for errors
   - Verify feature works as documented

5. **Commit:**
   ```bash
   git add reaper_mre/ CHANGELOG.md README.md
   git commit -m "Add [feature]: [description]"
   git push
   ```

---

## 📚 Documentation

- 📖 **[CHANGELOG.md](CHANGELOG.md)** — Detailed feature history
- 🎮 **[launch/quake-spasm/README.md](launch/quake-spasm/README.md)** — Testing guide + console commands
- 📜 **[Readme.txt](Readme.txt)** — Historical archive + feature summary

---

## 🎯 Skill Levels

Bots adapt their behavior based on skill setting (`skill 0-3`):
Default: Bots spawn at skill 3 (nightmare), and the mod forces the server `skill` cvar to at least 3 so the scoreboard matches. To allow dynamic scaling, set `bot_skill_adapt 1` (enables 1.0-4.0).

| Skill | IQ | Behavior |
|-------|-----|----------|
| **0** | 1.0 | 🟢 Novice — Basic navigation, simple aim |
| **1** | 1.5 | 🟡 Intermediate — Item awareness, better prediction |
| **2** | 2.0 | 🟠 Advanced — Powerup denial, evasion tactics |
| **3** | 3.0 | 🔴 Expert — Rocket jumps, spawn memory, adrenaline bursts |

**Set in-game:**
```
skill 3           // Max difficulty
bot_skill_adapt 1 // Optional: enable streak-based skill scaling
impulse 100       // Add bot
impulse 102       // Remove bot
```

---

## 🧪 Testing Maps

| Map | Name | Best For | Players |
|-----|------|----------|---------|
| **dm2** | Claustrophobopolis | 🎯 Close combat, powerup denial | 4-6 |
| **dm3** | Abandoned Base | 🏃 Movement, platform navigation | 6-8 |
| **dm4** | The Bad Place | ⚔️ All-around combat, rocket jumps, hazard avoidance, 452 waypoints! | 8-12 |
| **dm5** | The Cistern | 🌊 Water navigation, vertical play | 4-8 |
| **dm6** | The Dark Zone | 🔫 Long-range combat, train timing | 6-10 |

---

## 🤝 Contributing

Contributions are welcome! Please:

1. 🍴 Fork the repository
2. 🌿 Create a feature branch (`git checkout -b feature/amazing-ai`)
3. 💾 Commit your changes (`git commit -m 'Add amazing AI feature'`)
4. 📤 Push to the branch (`git push origin feature/amazing-ai`)
5. 🎉 Open a Pull Request

---

## 📜 License

This project builds upon the classic **Reaper Bot** (1998) with modern enhancements.

- 🤖 **Original Reaper Bot:** Public domain / community project
- ✨ **MRE Enhancements:** MIT License (see `LICENSE`)

---

## Known Issues (2026-01)

- **Bot model colors appear identical in-world** even though the scoreboard shows distinct colors.

  **What we tried:**
  1. Restored `colormap = fClientNo + 1`, removed shirt/pants colormap packing, enforced `FL_CLIENT` on bot spawn
  2. Verified colors are sent via `msgUpdateColorsToAll()` with proper shirt/pants values
  3. Changed bot classname from "dmbot" to "player" (since engine applies colors to "player" entities)
     - Added `.isbot` flag to distinguish bots from real players
     - Created `findbot()` helper function to iterate bots (since `find(world, classname, "dmbot")` no longer works)
     - Protected all network commands (`stuffcmd`, `sprint`) to skip bots (prevents "Parm 0 not a client" crash)
     - Updated 100+ references across codebase from classname checks to `isbot` checks

  **Result:** Scoreboard colors correct, no crashes, but in-world model colors still identical

  **Suspected causes:**
  - Engine setting that disables model colors (`r_nocolors 1` / `r_noskins 1`)
  - Player model (`progs/player.mdl`) may not have proper color ranges defined
  - Engine may require additional network message for in-world color updates beyond `MSG_UPDATECOLORS`

---
## 🙏 Credits

- 📦 **Original Reaper Bot** — Steven Polge & community (1998)
- 🤖 **FrikBot** — Ryan "Frik" Smith
- 🧠 **Omicron Bot** — Jan Paul van Waveren † (Mr Elusive) — AI architecture inspiration
- 🎮 **Quake 1 Team** — id Software (1996)
- 👥 **Quake Community** — mappers, modders, server admins, and players
- 🔨 **FTEQCC Compiler** — FTE QuakeWorld team
- 🎮 **QuakeSpasm Engine** — QuakeSpasm developers
- 🤖 **MRE AI Systems** — Modern enhancements (2026)

---
## 🔗 Links

- 📦 **GitHub Releases:** [Latest progs.dat builds](https://github.com/saworbit/mre/releases)
- 🐛 **Issue Tracker:** [Report bugs](https://github.com/saworbit/mre/issues)
- 💬 **Discussions:** [Share strategies](https://github.com/saworbit/mre/discussions)
- 📊 **CI Status:** [Build pipeline](https://github.com/saworbit/mre/actions)

---

<div align="center">

**Made with ❤️ for the Quake community**

🎮 *"Frag like it's 1996... with 2026 AI"* 🤖

[⬆ Back to Top](#-modern-reaper-enhancements-mre)

</div>
