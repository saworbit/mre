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

### Botmovetogoal (Primary Movement)

```
Botmovetogoal(dist)                    [botmove.qc:1066]
  │
  ├─> ChangeYaw()                      [turn toward goal]
  │
  ├─> [if in water]
  │     ├─> CheckWaterLevel()
  │     └─> BotUnderwaterMove(dist)
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

### Low-Level Movement

```
botwalkmove(yaw, dist)                 [botmove.qc:6]
  └─> walkmove(yaw, dist)              [engine builtin]

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
| 2026-01-16 | Initial architecture mapping for clean baseline |
