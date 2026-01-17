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
  │           ├─> BotSwim()           [if waterlevel >= 2]
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
- Breadcrumbs: `Bot_DropBreadcrumb` calls `SpawnSavedWaypoint` (pathtype `DROPPED`) every 64 units while exploring.


### Low-Level Movement

```
botwalkmove(yaw, dist)                 [botmove.qc:513]
  │
  ├─> [pre-checks: bounce mode, airborne knockback, platform ride]
  │     └─> BotAirSteer(yaw)           [mid-air course correction]
  │
  ├─> [if waterlevel >= 2]
  │     ├─> BotSwim()                 [3D swim control]
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

## Version History

| Date | Change |
|------|--------|
| 2026-01-20 | Added feeler steering + breadcrumb exploration mode |
| 2026-01-19 | Added 3D swim engine (BotSwim) with critical-health surfacing logic |
| 2026-01-18 | Added humanized physics system (turn limiting, air steering, edge friction, wall sliding) |
| 2026-01-17 | Added sensor fusion steering system documentation |
| 2026-01-16 | Initial architecture mapping for clean baseline |


