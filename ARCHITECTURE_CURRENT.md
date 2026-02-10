# Architecture: Current State (Clean Baseline)

This document maps the bot control flow architecture to help identify and untangle
the control loops during the reboot process.

## Overview

Reapbot uses Quake's **frame-function system** for bot control. Each bot entity has
a `.think` function that executes once per server frame (~10Hz). These frame
functions chain together, creating an animation/behavior state machine.

**Key insight**: There is ONE control loop per bot - the `.think` function. All AI
decisions happen within that single execution path.

## Spec Alignment

For the design and implementation specification aligned to this codebase, see
`REAPER_BOT_REBOOT_SPEC.md`. This document remains the authoritative call graph
and control-flow reference.

---

## Entry Points

### Engine-Called Functions

| Function | File | Called For | Purpose |
|----------|------|------------|---------|
| `StartFrame()` | `world.qc:232` | Once per frame | Global frame setup (cvars, framecount, graph + learning decay, Vortex frame) |
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

**Silent Specters (unstuck)** lives inside `ai_botseek` (`mre/botgoal.qc`):
when a bot stalls for ~2s, it runs a short, quiet rollout (`SilentUnstuck`) and
marks a local cursed node (`CurseNode`). Cursed decay is global in `StartFrame`.

**Vortex Navmesh (dynamic mesh)** lives in `ai_vortex.qc`:
- `Vortex_Frame()` incrementally floods nodes/edges each `StartFrame`.
- `ai_botseek` calls `Vortex_ApplyGoal()` only when the current goal is obstructed,
  inserting a short-lived mesh waypoint while keeping normal BotPath routing as baseline.
- Phantom episodes validate mesh edges via `Vortex_RecordEpisode()` in `bot_learn.qc`.

**Vortex Telechains + Lift Routing** extend the mesh with teleport and platform logic:
- Telechains fuse one-way tele edges when a phantom observes a large warp (>500u).
- Tele edges are low-cost in Vortex A*.
- Lift nodes are sampled from `func_plat`/`func_train` and add a wait-cost based on cycle timing.

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

`Botmovetogoal` now includes a 1‑tick lookahead nudge (`BotProactiveNudge`) to
avoid dead-ends before committing to movement.

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


### Navigation Learning + Spectral Learning

- Player auto-waypoints: `Player_AutoWaypoint` drops `BotPath` nodes during movement and links them with typed edges (walk/jump/drop/platform/rocket jump).
- Usage weighting: `cacheRouteTarget` biases A* routing toward heavily used links.
- Graph maintenance: `MaintainGraph` decays usage and danger scent over time.
- Spectral learning: `ApplySpectralBoost` softly reduces A* cost when spectral episodes align with a link.

### Teacher Mode Debugging

- `impulse 102` reveals `BotPath` nodes with bubble sprites and particles for jump links.
- `impulse 103` hides the debug sprites again.
- `impulse 104` prints current spectral episode count.


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

- Bunny hop: `BotBunnyHop` adds variable-rhythm strafe-jumps (0.28-0.50s, 10-22deg, 30-50 accel) when safe.
- Velocity blending: Direction changes lerp over 2-3 frames (blend_rate 0.6-0.85) instead of instant snap.
- S-curve turns: `BotClampYaw` uses Hermite smoothstep for "whip and settle" turn profile.
- Graduated edge friction: `BotApplyEdgeFriction` uses two-tier braking (64u=0.92, 32u=0.70).
- Platform fidgeting: `BotCheckPlatformRide` adds micro-drift and look-around while riding lifts.
- Swim clumsiness: `BotSwim` adds pitch wobble and sluggish velocity blend in water.

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

Virtual sound events (item pickups, water splashes, footsteps) are broadcast via
`Bot_BroadcastNoise` and interpreted by `Bot_AnalyzeSound` to trigger pursuit,
aiming, or avoidance behavior based on sound type.

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

## Call Graph: Mastermind Update (Tactical Combat)

### Pre-Fire (Corner Suppression)

Bots shoot at corners where enemies just disappeared:

```
BotBlindFire()                         [botfight.qc]
  │
  ├─> [checks]
  │     ├─> Has enemy?
  │     ├─> Enemy NOT visible?
  │     ├─> Saw them < 2 seconds ago?
  │     ├─> Has RL or GL?
  │     └─> Distance 100-600 units?
  │
  ├─> BotPredictPosition(time_since_seen * 0.5)
  │     ├─> Linear extrapolation: lastseenpos + (velocity * time)
  │     └─> Apply gravity if jumping/falling
  │
  ├─> [if random() < skill-scaled chance]
  │     ├─> Aim at predicted position (feet for splash)
  │     └─> self.button0 = TRUE (fire!)
  │
  └─> Set cooldown (0.8s)
```

Called from `ai_botrun()` during MEMORY_ATTACK state.

### The Trap (Ambush)

Low-health bots set up ambushes instead of running:

```
[in ai_botrun, when enemy not visible]   [bot_ai.qc]
  │
  ├─> [if health < 40 AND enemy exists]
  │     │
  │     ├─> Calculate: is enemy chasing?
  │     │     └─> dot(enemy_velocity, dir_to_bot) > 0.4
  │     │
  │     ├─> [if chasing]
  │     │     ├─> Set ambush_ready = TRUE
  │     │     ├─> Switch to SSG or RL
  │     │     ├─> STOP: velocity = '0 0 0'
  │     │     ├─> AIM: face lastseenpos
  │     │     │
  │     │     ├─> [if enemy very close < 200]
  │     │     │     └─> NERVOUS TRIGGER: button0 = TRUE
  │     │     │
  │     │     └─> [timeout after 4 seconds]
  │     │
  │     └─> return (skip normal behavior)
```

### Displacement Kill

Knock enemies into hazards:

```
BotCheckEnvironmentKill()              [botfight.qc]
  │
  ├─> [checks]
  │     ├─> Has enemy and can see them?
  │     └─> Has RL or GL?
  │
  ├─> Check behind enemy for hazards
  │     ├─> 100 units behind: pointcontents for LAVA/SLIME
  │     └─> Check for cliff edge into hazard
  │
  ├─> [if hazard found]
  │     ├─> Aim at enemy's feet (pitch down)
  │     └─> self.button0 = TRUE (knockback!)
  │
  └─> return TRUE/FALSE
```

Called from `ai_botrun()` before normal `CheckBotAttack()`.

---

## Call Graph: Phantom Apprenticeship

### Phantom Spawn

Bots occasionally spawn a phantom to shadow a player and capture an episode:

```
BotAI_Main(dist)                         [bot_ai.qc]
  |
  |-> [random + cooldown]
      |-> Spectral_FindPlayer()         [bot_learn.qc]
      |-> SpawnPhantom(player)          [bot_learn.qc]
```

### Episode Capture + Ethereal Rollout

The phantom tracks the target and validates maneuvers via rollout sims:

```
PhantomThink()                           [bot_learn.qc]
  |
  |-> Detect maneuver (jump/tele/swim/walk)
  |-> If large warp (>500u) and teleport_time active, fuse tele edge
  |-> [every 0.5s]
      |-> EtherealRollout(start, goal, maneuver)
          |-> ShadowSimStep()           [ai_predict.qc]
          |-> ShadowReward()            [ai_predict.qc]
      |-> [if viability < threshold] abort
```

### Episode Commit

Validated episodes are compacted into the spectral buffer:

```
Spectral_EndEpisode(ph)                  [bot_learn.qc]
  |
  |-> Determine reward (goalentity or kill proxy)
  |-> EtherealRollout()                  [bot_learn.qc]
  |-> Spectral_AddEpisode()              [bot_learn.qc]
```

### A* Cost Bias (Soft Allure)

Spectral episodes bias routing without hard locks or teleport shortcuts:

```
cacheRouteTarget(node, targ, ...)        [botroute.qc]
  |
  |-> ApplySpectralBoost(node, targ)     [bot_learn.qc]
  |-> rng = rng - boost (clamped)
```

### Decay

Episodes fade automatically to keep the graph lean:

```
StartFrame()                             [world.qc]
  |
  |-> DecayEpisodes()                    [bot_learn.qc]
      |-> 60s throttle, reward/viability decay
```

---

## Call Graph: Mirage Minds (Humanization Layer)

Mirage adds a lightweight entropy layer that biases movement and aiming
without replacing existing AI states.

```
BotAI_Main(dist)                         [bot_ai.qc]
  |
  |-> MirageTick()                       [ai_mirage.qc]
      |-> update mood_entropy (drift + dampen when enemy visible)
      |-> yaw jitter (entropy > 0.5, 15% chance)
      |-> pitch jitter (entropy > 0.4, 12% chance, stored in mirage_pitch_bias)
      |-> glance-away (skill 3+, entropy > 0.6, 3% chance)
      |-> hold-fire feint (entropy > 0.7, 8% chance)
```

```
Botmovetogoal(dist)                      [botmove.qc]
  |
  |-> Mirage_BlendYaw()                  [ai_mirage.qc]
      |-> blend ideal_yaw toward mirage yaw bias
```

```
botaim()                                 [botfight.qc]
  |
  |-> [after skill jitter]
      |-> apply mirage_pitch_bias * 0.010 to aim Z-axis
```

---

## Call Graph: Darwin Update (Adaptive Learning)

### Negative Reinforcement (Death Learning)

When a bot dies, it learns that the death location is dangerous:

```
ClientObituary(targ, attacker)             [client.qc]
  │
  ├─> [if targ is "dmbot"]
  │     │
  │     ├─> findradius(targ.origin, 250)   [find nearest BotPath]
  │     │
  │     ├─> ModulateNodeWeight(node, -500) [mark dangerous]
  │     │
  │     └─> [Weapon Learning]
  │           ├─> targ.weapon == IT_ROCKET_LAUNCHER → confidence_rl -= 1
  │           ├─> targ.weapon == IT_LIGHTNING       → confidence_lg -= 1
  │           ├─> targ.weapon == IT_GRENADE_LAUNCHER → confidence_gl -= 1
  │           └─> targ.weapon == IT_SHOTGUN/SSG     → confidence_sg -= 1
  │
  └─> [Decay happens later in MaintainGraph()]
```

### Positive Reinforcement (Kill Learning)

When a bot gets a kill, it learns that the location is a good hunting ground:

```
ClientObituary(targ, attacker)             [client.qc]
  │
  ├─> [if attacker is "dmbot"]
  │     │
  │     ├─> findradius(attacker.origin, 250)
  │     │
  │     ├─> ModulateNodeWeight(node, +10)  [mark glorious]
  │     │
  │     └─> [Weapon Learning]
  │           ├─> attacker.weapon == IT_ROCKET_LAUNCHER → confidence_rl += 1
  │           ├─> attacker.weapon == IT_LIGHTNING       → confidence_lg += 1
  │           ├─> attacker.weapon == IT_GRENADE_LAUNCHER → confidence_gl += 1
  │           └─> attacker.weapon == IT_SHOTGUN/SSG     → confidence_sg += 1
  │
  └─> Confidence clamped to [-10, +10]
```

### Stuck Learning (Navigation Failure)

When a bot gets stuck trying to traverse a path:

```
ai_botseek(dist)                           [botgoal.qc]
  │
  ├─> [if stuck_duration > 1.5 seconds]
  │     │
  │     ├─> ModulateNodeWeight(last_waypoint, -100)
  │     │
  │     └─> dprint("DARWIN: Learned BROKEN LINK")
  │
  └─> Activate feeler mode to escape
```

### A* Path Cost Integration

The Darwin learning affects pathfinding in cacheRouteTarget:

```
cacheRouteTarget(node, targ, len, item)    [botroute.qc]
  │
  ├─> rng = base_distance / usage_weight
  │
  ├─> rng = rng + targ.danger_cost         [DANGER: add cost]
  │
  ├─> [if targ.glory_level > 0]            [GLORY: reduce cost]
  │     └─> rng = rng * (1.0 - glory * 0.01)  [up to 30% reduction]
  │
  └─> continue A* pathfinding with modified cost
```

### Decay System

Both danger and glory decay over time to allow relearning:

```
MaintainGraph()                            [botroute.qc]
  │                                        [called from StartFrame every 10s]
  ├─> [for each BotPath node]
  │     │
  │     ├─> danger_cost *= 0.8             [fast decay - courage]
  │     │     └─> if < 10 → set to 0
  │     │
  │     └─> glory_level *= 0.9             [slow decay - nostalgia]
  │           └─> if < 1 → set to 0
  │
  └─> [Continue to next node]
```

### Weapon Selection with Confidence

Bots apply their learned weapon preferences:

```
W_BestBotWeapon()                          [botfight.qc]
  │
  ├─> [Calculate base scores]
  │     ├─> LG: base 100
  │     ├─> RL: base 90
  │     ├─> SNG: base 80
  │     ├─> GL: base 70 (mid-range only)
  │     └─> SSG: base 60
  │
  ├─> [Apply confidence multipliers]
  │     ├─> LG: score += confidence_lg * 5
  │     ├─> RL: score += confidence_rl * 8  [biggest impact]
  │     ├─> GL: score += confidence_gl * 6
  │     └─> SSG: score += confidence_sg * 4
  │
  └─> Return weapon with highest score
```

---

## Call Graph: Specter Gaze (Cinematic Spectator)

Two-layer spectator camera: heavy Think computes targets, lightweight ViewUpdate
interpolates every server frame.

### Layer 1: Think (50-200ms, heavy math)

```
Specter_Think()                          [ai_specter.qc]
  │
  ├─> Specter_AssignTargets()            [rank bots by drama score]
  │     ├─> Find all "dmbot" entities
  │     ├─> Specter_Drama(bot) per bot
  │     └─> Sort top 4 into specter_targets[] + specter_scores[]
  │
  ├─> [for each camera]
  │     ├─> Specter_EventType(tgt)       [0=idle, 1=combat, 2=rj, 3=flag, 4=death]
  │     └─> Specter_UpdateCam(cam, tgt, score, event)
  │           ├─> Orbital + velocity prediction + trace for safe position
  │           └─> Store: cam.pos1, cam.pos2, cam.speed, cam.enemy, cam.cnt
  │
  ├─> [Auto-switch focus]
  │     ├─> Drama differential: switch if rival > focus + 5 points
  │     ├─> Boredom: switch if idle > 5 seconds
  │     └─> Cooldown: 1.5s minimum between switches
  │
  └─> Set specter_view_ent for ViewUpdate
```

### Layer 2: ViewUpdate (every server frame ~72fps, lightweight)

```
PlayerPreThink()                         [client.qc]
  │
  └─> Specter_ViewUpdate()               [ai_specter.qc]
        │
        ├─> [if not specter_cam] → Specter_SetView + setorigin → return
        │
        ├─> Frame-rate independent damp: cam.speed * frametime * 10.0
        │
        ├─> Smooth lerp: cam.origin toward cam.pos1
        │
        ├─> Position validation (solid/sky, distance > 1024)
        │
        ├─> setorigin(cam, cam.origin)   [BSP area links]
        │
        ├─> Angles from geometry: vectoangles(target - camera)
        │     └─> Combat tilt: -10 pitch during fights
        │
        ├─> Specter_SetView(self, cam)   [SVC_SETVIEW + SVC_SETANGLE]
        │
        └─> setorigin(self, cam.origin)  [PVS relocation]
```

### Toggle / Cycle

```
impulse 105  →  Specter_Toggle()         [ai_specter.qc]
                  ├─> Specter_Spawn()    [create 4 cameras, save player origin]
                  └─> Specter_Kill()     [remove cameras, restore player origin]

impulse 106  →  Specter_CycleFocus()     [ai_specter.qc]
                  ├─> Advance specter_focus
                  ├─> Snap camera to target + '0 0 48'
                  └─> Force-lock for 5 seconds
```

---

## Version History

| Date | Change |
|------|--------|
| 2026-02-10 | Intelligence pass #6: Navigation humanization — bunny hop rhythm variance, velocity momentum blending, S-curve turns, graduated edge friction, platform fidgeting, roaming speed variation, swimming clumsiness |
| 2026-02-10 | Intelligence pass #4: Powerup spawn timing, threat-scored targeting, circle strafing, retreat toward safety, elevation preference, engagement commitment, post-kill scavenge, traceline stagger, ambush jump suppression, skill-gated bunny hop |
| 2026-02-10 | Intelligence pass #3: Quad aggression, enemy Quad caution, fast-kill hitscan, weapon-range engagement, score pressure, velocity stuck guard, skill-scaled search timeout, speed-scaled whiskers, effective HP armor weight, ambush weapon safety |
| 2026-02-10 | Intelligence pass #2: strafe jitter, weapon distance scoring, splash risk override, target momentum, state hysteresis, effective HP weights, ammo urgency, retreat strafing, goal commitment, skill-scaled turn speed |
| 2026-02-10 | Navigation fix: distance-weighted goals, doubled search radius, goal-aware bunny hop |
| 2026-02-10 | Removed Apex HPA*, simplified Mirage Minds (entropy-only) and Ripple Oracles (no MCTS), 12 intelligence enhancements |
| 2026-02-09 | Added Specter Gaze cinematic spectator camera system |
| 2026-02-09 | Enabled -Wall -Wno-mundane, fixed 3 uninitialised variable bugs |
| 2026-02-07 | Added Mirage Minds (persona/entropy humanization and heatmap bias) |
| 2026-02-07 | Added Phantom Apprenticeship (spectral episodes with rollout validation and soft A* bias) |
| 2026-02-07 | Added Vortex Telechains (teleport fusion) and Apex Lifts (timed platform routing) |
| 2026-01-18 | Added Darwin Update (adaptive learning, weapon confidence, decay) |
| 2026-01-18 | Added Mastermind Update (pre-fire, ambush, displacement) |
| 2026-01-18 | Added Smooth Steering, Sixth Sense, and High-Value Item Focus |
| 2026-01-18 | Added Predator Update (sound navigation, curiosity) |
| 2026-01-22 | Added reflex dodge and bunny hop mechanics |
| 2026-01-21 | Added navigation learning, retrospective rewards, and Teacher Mode debugging |
| 2026-01-21 | Updated swim control to velocity-based oxygen-aware swimming |
| 2026-01-20 | Added feeler steering + breadcrumb exploration mode |
| 2026-01-19 | Added 3D swim engine (BotSwim) with pitch steering and direct velocity control |
| 2026-01-18 | Added humanized physics system (turn limiting, air steering, edge friction, wall sliding) |
| 2026-01-17 | Added sensor fusion steering system documentation |
| 2026-01-16 | Initial architecture mapping for clean baseline |


