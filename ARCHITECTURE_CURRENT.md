# Architecture: Current State (Clean Baseline)

This document maps the bot control flow architecture to help identify and untangle
the control loops during the reboot process.

## Overview

Reapbot uses Quake's **frame-function system** for bot control. Each bot entity has
a `.think` function that executes once per server frame (~10Hz). These frame
functions chain together, creating an animation/behavior state machine.

**Key insight**: There is ONE control loop per bot - the `.think` function. All AI
decisions happen within that single execution path.

---

## Entry Points

### Engine-Called Functions

| Function | File | Called For | Purpose |
|----------|------|------------|---------|
| `StartFrame()` | `world.qc:232` | Once per frame | Global frame setup (cvars, framecount) |
| `PlayerPreThink()` | `client.qc:1120` | Players only | Pre-physics player logic |
| `PlayerPostThink()` | `client.qc:1339` | Players only | Post-physics player logic |
| `self.think()` | (per entity) | All entities | Entity-specific behavior |

**Important**: `PlayerPreThink` and `PlayerPostThink` are NOT called for bots.
Bots run entirely through their `.think` function.

### Bot Initialization Chain

```
impulse 100 (or addbot command)
  └─> initBotLevel()           [botspawn.qc]
        └─> AddAnotherBot()
              └─> AddBot()     [spawns entity]
                    └─> SpawnNewBot()
                          └─> PutBotInServer()
                                └─> self.think = bot_start
                                └─> self.nextthink = time + 0.1
```

---

## Call Graph: Frame Functions

### Who Calls What?

The Quake engine calls `self.think()` for each bot entity. The assigned function
executes, then sets `self.think` to the next frame function.

```
Quake Engine (every ~0.1s per bot)
  │
  └─> self.think()  [current frame function]
        │
        ├─> Animation update (self.frame = X)
        ├─> AI behavior function (ai_botseek, ai_botrun, etc.)
        │     └─> Movement (Botmovetogoal)
        │     └─> Combat (CheckBotAttack)
        ├─> BotPostThink()  [cleanup/physics]
        │
        └─> Chain to next: self.think = next_frame_func
```

### Frame Function State Machine (`dmbot.qc`)

```
bot_start ──────────────────────────────────────┐
    │                                           │
    v                                           │
bot_stand1 ◄──── (no enemy, idle) ◄─────────────┤
    │                                           │
    v                                           │
bot_walk ◄────── (seeking goal) ◄───────────────┤
    │                                           │
    v                                           │
bot_run ◄─────── (enemy visible, attacking) ◄───┤
    │                                           │
    v                                           │
bot_chase ◄───── (enemy lost, pursuing) ◄───────┤
    │                                           │
    v                                           │
bot_shot*/bot_nail*/bot_axe* ─── (firing) ──────┘
```

Each frame function follows this pattern:
```c
void() bot_run = [ $frame, bot_run ]  // animation frame, next think
{
    ai_botrun(20);      // AI + movement
    BotPostThink();     // cleanup
};
```

---

## Call Graph: AI Functions

### AI Decision Layer (`bot_ai.qc`, `botgoal.qc`)

```
Frame Function (bot_run, bot_chase, etc.)
  │
  ├─> ai_botseek(dist)        [no enemy - seek items/waypoints]
  │     ├─> BotFindTarget()
  │     ├─> aibot_chooseGoal()
  │     └─> Botmovetogoal(dist)
  │
  ├─> ai_botrun(dist)         [enemy visible - attack]
  │     ├─> BotFindTarget()
  │     ├─> aibot_setupchase()
  │     ├─> Botmovetogoal(dist)
  │     └─> CheckBotAttack()
  │
  ├─> aibot_chase(dist)       [enemy lost - pursue]
  │     ├─> Botmovetogoal(dist)
  │     └─> CheckReboundAttack()
  │
  ├─> ai_botcharge(dist)      [aggressive close-range]
  │     └─> aibot_run_slide()
  │
  └─> aibot_run_melee()       [melee range]
        └─> th_melee()
```

### Reflex Dodge

- `BotReflexDodge` runs at the top of `BotAI_Main` to evade incoming rockets/grenades with a short cooldown.

### Target Acquisition

```
BotFindTarget()               [bot_ai.qc]
  ├─> Iterates all entities
  ├─> BotValidTarget() checks:
  │     ├─> Not dead (deadflag)
  │     ├─> Not observer (MOVETYPE_NOCLIP)
  │     ├─> Not same team
  │     └─> Visible (traceline)
  └─> Returns closest valid enemy
```

---

## Call Graph: Movement (`botmove.qc`)

### Sensor Fusion Steering System

The bot uses vector-based steering instead of reactive collision handling.
Three "whisker" rays detect walls and hazards, then force vectors are summed
to produce smooth curves around obstacles.

```
BotSteer(ideal_yaw, speed_factor)      [botmove.qc:232]
  │
  ├─> makevectors(ideal_yaw)           [get forward/right vectors]
  │
  ├─> SENSOR 1: Center Whisker
  │     ├─> traceline(forward * dist)
  │     ├─> [if wall] += trace_plane_normal * 3.0
  │     └─> [if hazard] += forward * -4.0 + jitter
  │
  ├─> SENSOR 2: Left Whisker (-45°)
  │     ├─> traceline(forward-right * dist*0.8)
  │     ├─> [if wall] += trace_plane_normal * 1.5
  │     └─> [if hazard] += right * 2.0
  │
  ├─> SENSOR 3: Right Whisker (+45°)
  │     ├─> traceline(forward+right * dist*0.8)
  │     ├─> [if wall] += trace_plane_normal * 1.5
  │     └─> [if hazard] += right * -2.0
  │
  └─> normalize(steer_dir) -> vectoyaw() -> return flow_yaw
```

```
BotDetectHazard(spot)                  [botmove.qc:197]
  │
  ├─> content = pointcontents(spot)    [ignore CONTENT_WATER]
  ├─> traceline(spot, spot - '0 0 256') [look down 256 units]
  │
  ├─> [if trace_fraction == 1.0]       [cliff/void]
  │     └─> return TRUE
  │
  ├─> [if CONTENT_LAVA or CONTENT_SLIME]
  │     └─> return TRUE
  │
  └─> [if CONTENT_SKY]                 [falling out of map]
        └─> return TRUE
```

### Botmovetogoal (Primary Movement)

```
Botmovetogoal(dist)                    [botmove.qc:1304]
  │
  ├─> ChangeYaw()                      [turn toward goal]
  │
  ├─> [if in water]
  │     ├─> CheckWaterLevel()
  │     └─> BotUnderwaterMove(dist)
  │           ├─> BotSwim()           [velocity-based swim + oxygen check]
  │           └─> BotCheckWaterJump()
  │
  ├─> [if goal is wind tunnel]
  │     └─> BotmovetoWindTunnel(dist)
  │
  ├─> [if goal visible]
  │     └─> BotmovetoVisiblegoal(dist)
  │           ├─> botwalkmove()
  │           └─> Bot_tryjump()
  │
  └─> [fallback]
        └─> strafemove(dist * 0.8)
```

### Feeler Steering + Breadcrumbs (Exploration)

- Activation: `ai_botseek` enables `feeler_mode_active` after > 1.5s stuck time.
- Steering: `Bot_FindClearestDirection` runs an 8-way traceline scan and overrides flow yaw for up to 10s.
- Breadcrumbs: `Bot_DropBreadcrumb` calls `SpawnSavedWaypoint` (pathtype `DROPPED`) every ~48 units while exploring.


### Navigation Learning + Retrospective Learning

- Player auto-waypoints: `Player_AutoWaypoint` drops `BotPath` nodes during movement and links them with typed edges (walk/jump/drop/platform/rocket jump).
- Usage weighting: `cacheRouteTarget` biases A* routing toward heavily used links and high-priority nodes.
- Retrospective rewards: `UpdateTrail` tracks last 5 nodes; `BackPropagateReward` boosts `node_priority` and `link_usage` when items are picked up.
- Path optimization: `OptimizePathSegment` links around intermediate nodes if line-of-sight exists, creating shortcuts.
- Graph maintenance: `MaintainGraph` decays usage and danger scent over time.

### Teacher Mode Debugging

- `impulse 102` reveals `BotPath` nodes with bubble sprites and particles for high priority or jump links.
- `impulse 103` hides the debug sprites again.


### Smooth Steering (Anti-Jitter)

Averages steering over 3 frames to prevent pathfinder/whisker oscillation:

```
BotSmoothSteer(target_yaw)             [botmove.qc]
  │
  ├─> Update circular buffer (smooth_yaw_0/1/2)
  │
  ├─> BotAverageAngles(yaw0, yaw1, yaw2)
  │     ├─> Convert each angle to unit vector
  │     ├─> Sum vectors (handles 0/360 wraparound)
  │     └─> Convert back to angle via vectoyaw()
  │
  ├─> Clamp delta to ±15°/frame
  │
  └─> Return smoothed yaw
```

Called from `botwalkmove()` after sensor fusion but before `walkmove()`.

### Low-Level Movement

- Bunny hop: `BotBunnyHop` adds a strafe-jump style velocity boost on long, straight runs when safe.

```
botwalkmove(yaw, dist)                 [botmove.qc:513]
  │
  ├─> [pre-checks: bounce mode, airborne knockback, platform ride]
  │     └─> BotAirSteer(yaw)           [mid-air course correction]
  │
  ├─> [velocity-based swim + oxygen check]
  │     ├─> BotSwim()                 [velocity-based swim control]
  │     └─> BotCheckWaterJump()
  ├─> [if feeler_mode_active]
  │     └─> flow_yaw = Bot_FindClearestDirection()
  ├─> [else] flow_yaw = BotSteer(yaw, 1.0)    [sensor fusion steering]
  │
  ├─> flow_yaw = BotClampYaw(flow_yaw) [turn speed limiting: 180°/sec cap]
  │
  ├─> walkmove(flow_yaw, dist)         [engine builtin]
  │
  ├─> [if moved]
  │     ├─> velocity matching          [client interpolation fix]
  │     ├─> Bot_DropBreadcrumb()     [if feeler_mode_active]
  │     ├─> ground glue (velocity_z=-20) [anti-jitter on ramps]
  │     ├─> BotApplyEdgeFriction()     [0.7x friction near ledges]
  │     └─> visual turn smoothing      [face into turns]
  │
  ├─> [if door hit]
  │     ├─> BotSolveDoor()             [button puzzle solver]
  │     └─> trace_ent.use()            [trigger door]
  │
  ├─> [if wall collision]
  │     ├─> store obstruction_normal   [wall direction]
  │     ├─> BotDecomposeVelocity()     [project to slide along wall]
  │     └─> walkmove(slide_yaw)        [attempt wall slide]
  │
  └─> [if stuck]
        └─> Stuck Doctor: jump if clear above [velocity_z=270]

Bot_tryjump()                          [botmove.qc]
  └─> Sets velocity.z for jump

strafemove(dist)                       [botmove.qc]
  └─> botwalkmove() with offset angle
```

---

## Call Graph: BotPostThink (`botthink.qc`)

### Who Calls BotPostThink?

Every frame function in `dmbot.qc` calls `BotPostThink()` at the end:

- `bot_start`, `bot_stand1`, `bot_walk`, `bot_run`, `bot_chase`
- `bot_shot1`-`bot_shot6`, `bot_trigger1`-`bot_trigger6`
- `bot_nail1`, `bot_nail2`, `bot_light1`, `bot_light2`
- `bot_axe*` variants
- (All weapon/animation frame functions)

### What Does BotPostThink Call?

```
BotPostThink()                         [botthink.qc:325]
  │
  ├─> CheckDropPath()                  [path cleanup]
  │     └─> DropBotPath()
  │
  ├─> [if dead]
  │     ├─> GibPlayer()
  │     └─> BotDead()
  │
  ├─> BotCheckPowerups()               [powerup expiration]
  │
  ├─> BotWaterMove()                   [water damage/sounds]
  │
  └─> NextLevel()                      [fraglimit check]
```

---

## Key Files

| File | Lines | Purpose |
|------|-------|---------|
| `dmbot.qc` | ~500 | Frame functions, animation state machine |
| `bot_ai.qc` | ~1400 | Combat AI, target selection, attack logic |
| `botgoal.qc` | ~400 | Goal selection, item seeking |
| `botmove.qc` | ~1100 | Movement execution, pathfinding |
| `botthink.qc` | ~400 | Post-think cleanup, powerups, water |
| `botspawn.qc` | ~300 | Bot creation, initialization |
| `botnav.qc` | ~600 | Waypoint/navigation system |
| `botweap.qc` | ~300 | Weapon selection logic |

---

## Control Loop Summary

**There is ONE control loop per bot:**

```
┌─────────────────────────────────────────────────────────┐
│                    PER-FRAME EXECUTION                  │
├─────────────────────────────────────────────────────────┤
│  1. Engine calls bot.think()                            │
│  2. Frame function runs:                                │
│     a. Update animation frame                           │
│     b. AI decision (seek/run/chase/charge)              │
│     c. Movement execution (Botmovetogoal)               │
│     d. Combat checks (CheckBotAttack)                   │
│     e. BotPostThink cleanup                             │
│  3. Set next think function and time                    │
│  4. Engine applies physics                              │
└─────────────────────────────────────────────────────────┘
```

**No competing loops detected.** The architecture is clean:
- One `.think()` per bot per frame
- AI functions are mutually exclusive branches (seek OR run OR chase)
- Movement methods are situational (walk OR strafe OR jump)

---

## Potential Refactoring Targets

While no redundant loops exist, these areas could be simplified:

1. **Frame function proliferation**: Many near-identical frame functions in `dmbot.qc`
   could potentially share common logic.

2. **AI function overlap**: `ai_botrun` and `aibot_chase` have similar structure;
   could be unified with a state parameter.

3. **Movement dispatch**: `Botmovetogoal` has multiple conditional branches that
   could be refactored into a cleaner dispatch pattern.

4. **BotPostThink coupling**: Called from every frame function; could potentially
   be moved to a central location if Quake's entity system allowed it.

---

## Call Graph: Predator Update (Strategic AI)

### Map Control (Timing)

Bots track powerup respawn times and rush to spawns before they appear:

```
powerup_touch()                        [items.qc]
  └─> Updates global timers:
        ├─> next_quad_time = time + 60  (Quad Damage)
        ├─> next_pent_time = time + 300 (Pentagram)
        └─> next_ring_time = time + 300 (Ring of Shadows)

BotAI_CheckPowerupTiming()             [bot_ai.qc]
  │
  ├─> [if Quad spawns in <10s]
  │     ├─> Check distance to spawn
  │     └─> Redirect goal to Quad spawn
  │
  └─> [if Pent spawns in <15s]
        └─> Redirect goal to Pent spawn
```

### Sensory Awareness (Hearing)

Bots can "hear" combat sounds and investigate them:

```
W_FireRocket / W_FireGrenade / GrenadeExplode / T_MissileTouch
  └─> Bot_AlertNoise(origin, volume, priority)
        │
        ├─> Find all bots in hearing range
        ├─> Apply wall attenuation (blocked = 1.5x distance)
        └─> Set bot.noise_target, bot.noise_time, bot.investigating

BotAI_CheckSoundInvestigation(dist)    [bot_ai.qc]
  │
  ├─> [if investigating && no visible enemy]
  │     ├─> Move toward noise_target
  │     └─> Look around while moving
  │
  └─> [if arrived at noise location]
        └─> Clear investigating flag
```

### Curiosity (Solving)

Bots shoot shootable objects they discover:

```
BotCheckCuriosity()                    [botmove.qc]
  │
  ├─> traceline(forward * 300)
  │
  ├─> [if func_button with health > 0]
  │     └─> self.button0 = TRUE (fire!)
  │
  ├─> [if func_door with health > 0]
  │     └─> self.button0 = TRUE (secret?)
  │
  └─> [if func_wall with health > 0]
        └─> self.button0 = TRUE
```

Called from `BotRoam()` during idle wandering.

### Sixth Sense (Item Awareness)

Bots detect nearby items even when facing away:

```
aibot_checkforGoodies()                [bot_ai.qc]
  │
  ├─> [for each item entity]
  │     │
  │     ├─> dist_to_item = vlen(item - self)
  │     │
  │     ├─> [if dist < 300]           [SIXTH SENSE range]
  │     │     ├─> traceline(self, item)  [LOS only, no facing check]
  │     │     ├─> weight += (300 - dist) * 0.1  [proximity boost]
  │     │     └─> can_see = TRUE
  │     │
  │     ├─> [else if dist < 800]      [standard vision]
  │     │     └─> visible() && infrontofbot()
  │     │
  │     └─> [else]                    [too far - ignore]
```

### High-Value Item Focus

Direct drive to powerups bypasses complex steering:

```
botwalkmove()                          [botmove.qc]
  │
  ├─> [if goal is high-value item]
  │     │  (RL, LG, Quad, Pent, Mega, Red Armor)
  │     │
  │     └─> [if dist < 200]
  │           ├─> Calculate direct_yaw to item
  │           ├─> walkmove(direct_yaw)  [bypass steering]
  │           └─> return TRUE
  │
  └─> [else: normal sensor fusion steering]
```

---

## Version History

| Date | Change |
|------|--------|
| 2026-01-18 | Added Smooth Steering, Sixth Sense, and High-Value Item Focus |
| 2026-01-18 | Added Predator Update (map timing, sound navigation, curiosity) |
| 2026-01-22 | Added reflex dodge and bunny hop mechanics |
| 2026-01-21 | Added navigation learning, retrospective rewards, and Teacher Mode debugging |
| 2026-01-21 | Updated swim control to velocity-based oxygen-aware swimming |
| 2026-01-20 | Added feeler steering + breadcrumb exploration mode |
| 2026-01-19 | Added 3D swim engine (BotSwim) with pitch steering and direct velocity control |
| 2026-01-18 | Added humanized physics system (turn limiting, air steering, edge friction, wall sliding) |
| 2026-01-17 | Added sensor fusion steering system documentation |
| 2026-01-16 | Initial architecture mapping for clean baseline |


