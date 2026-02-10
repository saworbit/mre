# Development Guide (Reapbot reboot)

This repo is a clean reboot of the Reaper Bot. The authoritative source lives
under `mre/`, and we fix community-reported issues first.

## Active code location (do not edit legacy)
All active, working code lives in `mre/` only:
https://github.com/saworbit/mre/tree/master/mre
Everything under `archive/` is legacy reference material. Do not edit or build
from `archive/`.

Design and implementation spec: `REAPER_BOT_REBOOT_SPEC.md`

## Layout
- `mre/` - Clean baseline QuakeC sources.
- `launch/quake-spasm/mre/` - Local runtime folder (progs.dat deploy target).
- `ci/` - CI build scripts and artifacts.
- `archive/` - Legacy materials and historical docs (read-only reference).
  - Legacy docs/tools/launch assets were moved to `archive/legacy/clean_slate/`.

## Build
Preferred (auto-downloads fteqcc if missing, deploys to QuakeSpasm):
```
cd c:\reaperai
powershell -ExecutionPolicy Bypass -File ci\build_mre.ps1
```

Manual compile (if you already have fteqcc):
```
cd c:\reaperai\mre
..\tools\fteqcc_win64\fteqcc64.exe -O3 -Tq1 -DQS_V6 -Wall -Wno-mundane progs.src
```
Manual builds write `c:\reaperai\progs.dat` (the parent folder).
Copy it to the runtime folder:
```
copy c:\reaperai\progs.dat c:\reaperai\launch\quake-spasm\mre\progs.dat /Y
```
Spec-aligned strict compile flags:
```
$env:FTEQCC_FLAGS = "-O2 -Werror -Tq1 -DQS_V6 -Wall -Wno-mundane"
powershell -ExecutionPolicy Bypass -File ci\build_mre.ps1
```

Known build warnings (FTEQCC, `-Wall -Wno-mundane`): 35 total.
- **F302 (uninitialised variable)**: 10 unique warnings — all false positives from guarded
  branches the compiler cannot correlate (e.g., variable set inside `if (dmbot)`, used
  inside a separate `if (dmbot)` block). No real bugs remain.
- **F322 (if-string tests null)**: 12 warnings — standard Quake idiom `if(self.target)`,
  intentional null checks. Suppress with `-Wno-F322` if desired.

## Deploy
The build script copies to:
`c:\reaperai\launch\quake-spasm\mre\progs.dat`

## Run
```
c:\reaperai\launch\quake-spasm\launch_reapbot_v2.bat 8 dm4
```
Verified working (QuakeSpasm):
```
c:\reaperai\launch\quake-spasm>quakespasm.exe -game mre -condebug +developer 1 -listen 8 +maxplayers 8 +deathmatch 1 +map dm2
```

Note: QuakeSpasm requires `progs.dat` version 6. The build script defaults to
`-Tq1 -DQS_V6` to produce a version 6 binary. If you see:
`Host_Error: progs.dat has wrong version number (7 should be 6)`,
you built without `-DQS_V6` or exceeded QS limits. Rebuild with the QS_V6
flags or use FTEQW (included) or another enhanced QCVM instead:
```
cd c:\reaperai\launch\fteqw_win64
fteqw64.exe -basedir c:\reaperai\launch\quake-spasm -game mre -condebug +developer 1 -listen 8 +maxplayers 8 +deathmatch 1 +map dm2
```

## Test (full command + logging)
From `c:\reaperai\launch\quake-spasm`:
```
quakespasm-sdl12.exe -game mre -condebug +developer 1 -listen 8 +maxplayers 8 +deathmatch 1 +map dm4
```
Log output: `c:\reaperai\launch\quake-spasm\qconsole.log`

### Stability suite (cmd-safe)
Run the batch via `cmd` (the quick-mode message uses an `if (...)` block):
```
cmd /c c:\reaperai\ci\test_stability.bat --quick
cmd /c c:\reaperai\ci\test_stability.bat
```

Note: If `quakespasm.exe` is missing or zero bytes, use `quakespasm-sdl12.exe`
or copy/rename it to `quakespasm.exe`.

## Logging notes
If `+developer 1` is enabled and `sv_aim` is not `0.93`, the bot spawner prints
a one-time note with the current `sv_aim` value. Set `sv_aim 0.93` to match the
baseline bot aiming behavior.
Knockback debug lines include `[BotName] KNOCKBACK: ...` while bouncing and
`[BotName] KNOCKBACK_END` when the bot returns to step movement.
Full think-logic traces are available in `BotAI_Main` when `developer` is on.
Logs emit `[BotName] AI: <STATE>` only when the bot's high-level state changes
(GOODY/RETREAT/ATTACK/CHASE/NO_ENEMY).
Feeler exploration logs are developer-only: `Activating FEELER mode` and
`[BotName] BREADCRUMB: Dropped at ...` appear when feeler mode triggers and
bots drop breadcrumbs. Player learning logs appear as
`[Player] BREADCRUMB: Learned waypoint at ...`.
Reflex dodge logs appear as `Bot DODGE: power=<N>` with the graded impulse value.
Quad debug logs appear as `[QuadSpawn]` when the item respawns and
`[QuadTouch] accept/blocked/reject` when a player or bot tries to pick it up.
Teleport traces appear as `[Teleport]` for bot teleporter use, and large
position jumps log as `[BotWarp]`.
Telechain fusions log as `Tele chain: entry <id> exit <id>` when `developer` is on.
Auditory inference uses virtual noise events (NOISE_ITEM/WATER/STEP/WEAPON);
combat hearing still logs `[BotName] HEARD: Combat at ...` when `developer` is on.
Teacher Mode visualization uses `impulse 102` to show BotPath nodes and
`impulse 103` to hide them. Spectral learning uses `impulse 104` to print the
current episode count.

Debug logging defaults (set in `mre/Autoexec.cfg`):
- `developer 0`
- `shadow_debug 0`
- `shadow_nav_debug 0`
- `shadow_combat_debug 0`
Set these to `1` as needed for diagnostics.

Performance throttles (behavior-neutral, CPU-focused):
- Target acquisition scans are time-sliced per bot (skill-scaled) and bypassed briefly after recent contact.
- Item scans (`aibot_checkforGoodies`) are throttled when not panicking and use a smaller radius during active combat.
- Proactive nudge lookahead is throttled and skips when shadow nav already ran (nav-only timestamp).
- Ripple interact scans are throttled when no nearby ripple node is cached, and cached nodes are reused when close.
- Hazard checks in steering are skipped at very low movement speeds to cut redundant traces.

Optional tuning cvars for these throttles:
- `bot_target_throttle` (float): override target scan throttle (seconds).
- `bot_goodies_throttle` (float): override item scan throttle (seconds).
- `bot_goodies_combat_radius` (float): item scan radius when fighting (units).
- `bot_nudge_throttle` (float): override proactive nudge throttle (seconds).
- `bot_ripple_throttle` (float): override ripple interact scan throttle (seconds).
- `bot_hazard_min_speed` (float): minimum speed for full hazard checks (units/sec).

Gameplay tuning notes:
- Reaction delay is distance-aware (closer targets = faster reactions), with a brief tighten after recent combat noise.
- Close-range RL/GL handling biases a backpedal/strafe to reduce self-splash.

## Shadow Puppets tuning (cvars)
These are runtime knobs for the combat rollout system:
- `sv_shadow_nav` (0/1): master enable for navigation rollouts
- `sv_shadow_combat` (0/1): master enable for combat rollouts
- `shadow_throttle` (float): shared rollout throttle in seconds (default 0.2)
- `shadow_debug` (0/1): master debug switch (enables both nav + combat logs)
- `shadow_combat_debug` (0/1): print rollout decisions (requires `+developer 1`)
- `shadow_combat_depth` (>0): override combat rollout depth (ticks)
- `shadow_combat_beam` (>0): override combat beam width
- `shadow_combat_fire_bias` (float): reward bias for fire actions (positive = more aggressive)

Navigation rollout knobs:
- `shadow_nav_debug` (0/1): print nav rollout decisions (requires `+developer 1`)
- `shadow_nav_depth` (>0): override nav rollout depth (ticks)
- `shadow_nav_beam` (>0): override nav beam width
- `shadow_nav_hazard_bias` (float): scales hazard penalties (lava/slime/cliffs)
- `shadow_nav_water_bias` (float): scales water penalties

Defaults for `sv_shadow_nav`, `sv_shadow_combat`, `shadow_throttle`, and `shadow_debug`
are set in `mre/Autoexec.cfg`.

Notes:
- Combat rollout uses a capped action sample per depth (skill-scaled, capped at 16) and beam search.
- Navigation rollout uses a beam search with hazard/water penalties and a 5Hz throttle.

## Slayer Eclipse (combat escalation)
Runtime knobs for high-skill combat escalation:
- `sv_slayer_god` (0/1): force skill 10, max combat depth/beam, and perfect aim
- `mc_samples` (int): Monte Carlo lead samples for projectile aim (default 20)
- `user_learn` (0/1): enable per-user strafe bias learning (applies to any connected player)

Notes:
- God mode expands combat rollout depth/beam and removes aim randomness.
- User strafe bias feeds enemy action modeling and dodge direction bias.
- Rival powerup ETA rush triggers at skill 8+ (or god mode) when health > 50, the powerup is visible, and a preempt is possible.
- God mode forces `shadow_throttle` to `0.1`.
- Monte Carlo lead checks LOS and falls back to a simple lead if obstructed.

## Silent Specters + Cursed Nodes (unstuck + learning)
Silent unstuck rollouts are implemented in `mre/ai_predict.qc` as `SilentUnstuck`.
They use a short beam search (depth 4, beam 3) over quiet actions, with a jump
penalty when enemies are nearby. Proactive 1-tick lookahead nudges live in
`mre/botmove.qc` (`BotProactiveNudge`).

Compile-time tuning knobs:
- `SILENT_UNSTUCK_DEPTH`, `SILENT_UNSTUCK_BEAM`, `SILENT_NOISE_PENALTY` in `mre/ai_predict.qc`

Cursed Nodes are a compact stuck-learning mesh in `mre/ai_mirage.qc`:
- `CURSED_MAX`, `CURSED_GRID`, `CURSED_MAX_PENALTY`, `CURSED_DECAY`
- Decay runs via `StartFrame` (`world.qc`), reset on map load (`worldspawn`)
- Penalties bias both rollouts (`ShadowReward`) and route cost (`botroute.qc`)

## Vortex Navmesh (dynamic path mesh)
Vortex is a lightweight, incremental navmesh built at runtime and validated by
phantom episodes.

Key integration points:
- `mre/ai_vortex.qc`: mesh nodes/edges, flood build, A* cost bias (cursed + usage)
- `mre/world.qc`: `Vortex_Reset` on map load, `Vortex_Frame` each `StartFrame`
- `mre/bot_learn.qc`: `Vortex_RecordEpisode` when a phantom episode succeeds
- `mre/botgoal.qc`: `Vortex_ApplyGoal` injects a mesh waypoint only when the goal is obstructed

Compile-time tuning knobs:
- `VORTEX_MAX_NODES`, `VORTEX_MAX_CONN`, `VORTEX_TRACE_BUDGET`, `VORTEX_BUILD_THROTTLE`
- `VORTEX_MIN_READY`, `VORTEX_DECAY_THROTTLE`
- `VORTEX_TELE_CHAIN_MAX`, `VORTEX_TELE_WARP_DIST`, `VORTEX_TELE_COST`
- `VORTEX_LIFT_SAMPLE_THROTTLE`, `VORTEX_LIFT_UP_START`, `VORTEX_LIFT_UP_END`

## Ripple Oracles (causal interactables)
Ripple Oracles predicts button/door/plat sequences when a goal is blocked, using
heuristic trace probes and a beam-search fallback. Successful cascades are fused
into the Vortex graph as one-way ripple edges with explicit interact positions.

Key integration points:
- `mre/ai_ripple.qc`: heuristic trace probes + beam-search fallback
  (`Ripple_MaelstromSim`), probe pulses, and ripple fusing.
- `mre/ai_vortex.qc`: ripple fields on nodes, A* cost bias for ripple edges, and
  path reconstruction redirect to the interactable position.
- `mre/botmove.qc`: `Ripple_TryInteract()` fires/touches when near a ripple node.
- `mre/bot_learn.qc`: phantom episodes can fuse ripple chains from player actions.
- `mre/defs.qc`: per-bot `ripple_probe_time` throttle.

Behavior summary:
- When LOS to the goal is blocked, `RippleDetect()` pulses around the block to
  find interactables and runs trace probes to evaluate shoot/touch/wait sequences.
- The best cascade fuses a ripple edge: `ripple_pos` is the interact waypoint,
  `ripple_target` is the post-effect node, and A* adds a cost penalty for the
  interaction delay.
- Rocket jump beam depth scales by skill: `6 + floor(skil * 0.6)` (6 at skill 0,
  12 at skill 10).

Compile-time tuning knobs (ai_ripple.qc):
- Probe/throttle: `RIPPLE_PROBE_THROTTLE`,
  `RIPPLE_PULSE_DIRS`, `RIPPLE_PULSE_DIST`, `RIPPLE_GOAL_RANGE`,
  `RIPPLE_ACTION_RANGE`

Decay:
- Deep ripple edges are pruned when usage is low (see `Vortex_Decay`).

## Grenade Vortex (GJ/GLJ Leap Oracle)
Grenade Vortex extends Quantum Leaps with grenade-jump (GJ) and grenade-launch
bounce jump (GLJ) actions when rockets are scarce or the purpose demands a
softer arc. GJ/GLJ are simulated inside the same beam-search rollout used for
rocket jumps, with bounce-aware fuse timing and purpose-tuned launch vectors.

Key integration points:
- `mre/ai_ripple.qc`: GJ/GLJ actions (24-39), bounce sim, and mixed RJ/GJ/GLJ
  beam-search priors.
- `mre/botmove.qc`: unchanged call sites (`Quantum_RJDetect`, `Quantum_TryLeap`)
  now select RJ/GJ/GLJ based on ammo/health/purpose.
- `mre/bot_learn.qc`: phantom episodes tune GJ horiz/vert coeffs and GLJ launch
  angles, and fuse grenade leap edges into Vortex.

Notes:
- GJ/GLJ use grenade launcher ammo (`ammo_rockets`) and are disabled if the
  bot lacks `IT_GRENADE_LAUNCHER`.
- Health gating: RJ >= `RJ_MIN_HEALTH`, GJ/GLJ >= `GJ_MIN_HEALTH`.

## Vortex Telechains + Lift Routing (teleport + platform fusion)
- Telechains: large warps (>500u) are detected via phantom tele events and fused
  into one-way tele edges; chain depth is limited to prevent loops.
- Lifts: nodes are sampled against `func_plat`/`func_train`, with a wait penalty
  based on the lift cycle in Vortex A*.
- Oracle Rides: ETA-based wait cost, movement sync to catch lift up-phases, and
  phase refinement from successful lift rides.
- Rollout sim grants a lift reward with bias for upward motion to encourage stable rides.

## Mirage Minds tuning (cvars)
- `sv_mirage` (0/1): master enable for entropy-driven humanization
- `mirage_debug` (0/1): log entropy state (requires `+developer 1`)

Mirage uses an entropy model (no personas or heat maps):
- `mood_entropy` drifts randomly, dampened when enemy is visible (focus up).
- High entropy triggers yaw jitter, pitch jitter, glance-aways, and hold-fire feints.
- Pitch bias is applied to aiming via `mirage_pitch_bias` field.
- Cursed Nodes (stuck-learning mesh) remain integrated in `ai_mirage.qc`.

Defaults for `sv_mirage` and `mirage_debug` are set in `mre/Autoexec.cfg`.

## Humanization pass (intelligence pass #5)
Seven changes to reduce robotic tells and improve organic behavior.

### 1. Aim spring model (`botfight.qc`, `botaim()`)
Replaces per-frame snap-to-target+noise with a spring-dampened tracking system.
The aim direction smoothly chases the target with velocity and damping, producing
organic tracking curves instead of jittery corrections.
- Stiffness: 12 (skill 0) to 32 (skill 5) — controls chase speed.
- Damping: 8 (skill 0) to 18 (skill 5) — prevents oscillation.
- Uses `time - last_aim_time` for frame-rate independent delta.
- Micro-noise (0.003 scale) replaces old exponential jitter (0.012 scale).
- Slayer god mode bypasses the spring for perfect snap tracking.
- Fields: `.aim_velocity`, `.last_aim_dir`, `.last_aim_time`.

### 2. Graded dodge response (`botfight.qc`, `BotReflexDodge()`)
Dodge impulse now scales with threat proximity instead of a flat 350u push.
- Close threats (200u): 450u impulse. Distant threats (450u): 200u impulse.
- Variable cooldown: 1.0–1.8s proportional to dodge strength.
- Strong-side bias driven by `mood_entropy` (low entropy = consistent side).

### 3. Weapon switch fumble (`botfight.qc`, `W_BotAttack()`)
Brief fire delay after any weapon change (including auto-switches from ammo
awareness). Simulates the human need to re-settle aim on a new weapon.
- Delay: 50–250ms, skill-scaled (0.250 - skill * 0.040, min 0.050).
- Randomized ±20% per switch for variance.
- Fields: `.weapon_switch_time`, `.weapon_prev`.

### 4. Strafe commitment (`bot_ai.qc`, `aibot_run_slide()`)
Replaces per-frame random strafe switching with committed directional bursts.
- Hold duration: 0.3–0.6s, skill-scaled (0.300 + skill * 0.060).
- 45% chance to maintain current direction on re-roll (bias toward holds).
- Uses `strafe_hold_until` timestamp instead of accumulating `strafetime`.
- Field: `.strafe_hold_until`.

### 5. Combat entry stutter (`bot_ai.qc`, `aibot_run_slide()` + `BotHuntTarget()`)
200ms movement speed ramp when first engaging a new enemy. Movement scales from
40% to 100% over the window, simulating a human's brief processing delay.
- Set in `BotHuntTarget()` when combat begins.
- Applied at the top of `aibot_run_slide()` using linear interpolation.
- Field: `.combat_entry_time`.

### 6. Sound direction error (`bot_ai.qc`, `BotAI_CheckSoundInvestigation()`)
Bots no longer path perfectly to heard sounds. Hearing error is applied to the
investigation yaw, causing bots to arrive slightly off-target.
- Error range: 6° (skill 8+) to 35° (skill 0), capped at 45°.
- Scales with distance (further = harder to localize).
- Uses `noise_time * 100` as a stable pseudo-random seed to avoid per-frame jitter.

### 7. Threat score refactor (`bot_ai.qc`, `BotFindTarget()`)
Extracted ~80 lines of duplicated threat scoring into `BotThreatScore()` helper.
Both the player scanning loop and the bot scanning loop now call the shared
function. No behavioral change — pure code deduplication.

## Navigation humanization (intelligence pass #6)
Seven movement systems to eliminate robotic navigation tells, all skill-scaled.

### 1. Bunny hop rhythm variance (`botmove.qc`, `BotBunnyHop()`)
Replaces fixed 0.4s/15deg/40accel with per-hop randomized values:
- Hop interval: 0.30-0.50s, narrowed by `skill * 0.008` (min 0.28s).
- Strafe angle: 10-22deg, skill-converges toward ~15 optimal.
- Accel boost: 30-50 (ground), 8-16 (air).

### 2. Velocity momentum blending (`botmove.qc`, `botwalkmove()`)
Direction changes lerp over 2-3 frames instead of instant velocity snap:
- `blend_rate = 0.6 + skill * 0.03` (cap 0.85).
- Applied to X/Y velocity in `botwalkmove` after `makevectors`.

### 3. S-curve turn acceleration (`botmove.qc`, `BotClampYaw()`)
Hermite smoothstep (`3t^2 - 2t^3`) modulates max turn speed:
- `turn_fraction = abs_delta / max_turn` (clamped to 1).
- `max_turn *= 0.3 + turn_fraction * 0.7` — small residuals decelerate, large angles ramp up.
- Creates "whip and settle" mouse acceleration pattern.

### 4. Graduated edge friction (`botmove.qc`, `BotApplyEdgeFriction()`)
Two-distance braking replaces single binary check:
- Far (64u ahead): 0.92 friction — gentle early brake.
- Near (32u ahead): 0.70 friction — heavy brake.
- One extra traceline per frame vs. the original.

### 5. Platform fidgeting (`botmove.qc`, `BotCheckPlatformRide()`)
Replaces `velocity = '0 0 0'` with idle animation:
- Micro-drift: `(random() - 0.5) * 20` on X/Y.
- 5% chance per frame: yaw += random ±20 deg + `ChangeYaw()`.

### 6. Roaming speed variation (`bot_ai.qc`, `BotRoam()`)
Replaces fixed 200 speed with mood-based variance:
- Base: 180-240 random per frame.
- Corner slowdown: 0.7x when whiskers detected obstacle.
- 2% micro-pause: 0.2x speed + ±30 deg look-around.

### 7. Swimming clumsiness (`botmove.qc`, `BotSwim()`)
Pitch wobble + sluggish velocity response:
- Triangle wave: ±(8 - skill) deg, ~2s period.
- Velocity blend: `swim_blend = 0.4 + skill * 0.04` (cap 0.75).
- All three axes (X/Y/Z) blend toward target velocity.

## Specter Gaze (cinematic spectator camera)
Two-layer spectator camera system in `mre/ai_specter.qc`, hooked into `PlayerPreThink`
via `mre/client.qc`.

### Usage
- `impulse 105` — Toggle Specter Gaze on/off
- `impulse 106` — Cycle camera focus to next bot (5s force-lock)
- `specter_chase 1` — First-person chase mode (through bot's eyes)
- `specter_chase 0` — Cinematic third-person mode (default)

### Architecture
- **Think** (50-200ms): Heavy math in `Specter_UpdateCam`. Computes ideal camera
  position, stores results on camera entity fields (`pos1`=position target,
  `pos2`=look-at fallback, `speed`=damp rate, `enemy`=tracked bot, `cnt`=event type).
- **ViewUpdate** (every server frame ~72fps): Lightweight per-frame interpolation in
  `Specter_ViewUpdate`, called from `PlayerPreThink`. Frame-rate-independent damping,
  geometry-based angles via `vectoangles`, position validation, BSP link updates via
  `setorigin`, PVS player relocation, and `SVC_SETVIEW` + `SVC_SETANGLE` every frame.

### Auto-switching
- **Drama-driven**: Switches when another bot's drama score exceeds the focused bot by 5+ points.
- **Boredom**: Switches after 5 seconds of idle focus (drama < 2).
- **Cooldown**: 1.5s minimum between auto-switches.
- **No random switching** — purely event-driven.

### Key fields (repurposed on `specter_cam` entities)
| Field | Camera use |
|-------|------------|
| `.pos1` | Ideal camera position (lerp target) |
| `.pos2` | Predicted look-at fallback |
| `.enemy` | Tracked bot entity |
| `.speed` | Base damping rate |
| `.cnt` | Event type (0=idle, 1=combat, 2=rocket jump, 3=flag, 4=death) |

### Globals (in `botit_th.qc`)
- `specter_view_ent` — Current view entity (camera or bot for chase mode)
- `specter_idle_since` — When focused bot last had meaningful drama
- `specter_focus_drama` — Cached drama score for differential switching

## Linting and static analysis
The default build flags include `-Wall -Wno-mundane` for compile-time warnings.

### FTEQCC flags (current compiler)
| Flag | Purpose |
|------|---------|
| `-Wall` | Enable all standard warnings |
| `-Wno-mundane` | Suppress trivial noise |
| `-Werror` | Treat warnings as errors (CI gate) |
| `-Wno-F322` | Suppress `if(string)` null-vs-empty warnings |

### Strictness flags (optional)
| Flag | Purpose |
|------|---------|
| `-Ftypeexplicit` | Require explicit type casts |
| `-Fsubscope` | Variables scoped to blocks |
| `-Fifstring` | Warn on `if(string)` without comparison |
| `-Fifvector` | Warn on `if(vector)` without comparison |
| `-Fvectorlogic` | Warn on logic operators applied to vectors |

### GMQCC (alternative compiler, optional second-pass linter)
GMQCC provides richer diagnostics: `-Wunused-variable`, `-Wunreachable-code`,
`-Wlocal-shadows`, `-Wmissing-return-values`, `-Weffectless-statement`. Can be
run as a check-only pass without replacing FTEQCC for the actual build.

## CI
```
powershell -ExecutionPolicy Bypass -File c:\reaperai\ci\build_mre.ps1
```
CI publishes: `c:\reaperai\ci\mre\progs.dat`

## Critical QuakeC gotchas
1) **System globals**: never modify anything before `end_sys_globals` in `defs.qc`.
   If you see `Host_Error: progs.dat system vars have been modified, progdefs.h is out of date`,
   move any new globals into `mre/botit_th.qc` (safe global area) and keep new entity
   fields after `end_sys_fields` in `defs.qc`, then rebuild and redeploy.
2) **Impulse scope**: guard global toggles with `self.classname == "player"`.
3) **Trace globals**: `traceline()` overwrites `trace_*` globally; save/restore in helpers.
4) **Bitmask clears**: use masked subtraction (`var = var - (var & FLAG)`).
5) **Globals size**: `progs.dat` currently exceeds the 32k global limit; an enhanced QCVM/engine is required at runtime.

## Legacy docs
The previous MRE development guide is archived at `archive/legacy/v1/DEVELOPMENT_MRE.md`.
