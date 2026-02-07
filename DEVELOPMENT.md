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
..\tools\fteqcc_win64\fteqcc64.exe -O3 progs.src
```
Manual builds write `c:\reaperai\progs.dat` (the parent folder).
Copy it to the runtime folder:
```
copy c:\reaperai\progs.dat c:\reaperai\launch\quake-spasm\mre\progs.dat /Y
```
Spec-aligned strict compile flags:
```
$env:FTEQCC_FLAGS = "-O2 -Werror"
powershell -ExecutionPolicy Bypass -File ci\build_mre.ps1
```

Known build warnings (FTEQCC, non-bot): none currently.

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
Reflex dodge logs appear as `Bot attempting DODGE!`.
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
- Combat rollout uses a capped action sample per depth (skill-scaled) and beam search.
- Navigation rollout uses a beam search with hazard/water penalties and a 5Hz throttle.

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

## Vortex Navmesh + Apex HPA* (dynamic path mesh)
Vortex is a lightweight, incremental navmesh built at runtime and validated by
phantom episodes. Apex adds a small HPA* abstraction layer for large maps.

Key integration points:
- `mre/ai_vortex.qc`: mesh nodes/edges, flood build, A* cost bias (cursed + usage)
- `mre/ai_apex.qc`: cluster graph over Vortex, used by `Apex_VortexNext`
- `mre/world.qc`: `Vortex_Reset`/`Apex_Reset` on map load, `Vortex_Frame`/`Apex_Frame` each `StartFrame`
- `mre/bot_learn.qc`: `Vortex_RecordEpisode` when a phantom episode succeeds
- `mre/botgoal.qc`: `Vortex_ApplyGoal` injects a mesh waypoint only when the goal is obstructed

Compile-time tuning knobs:
- `VORTEX_MAX_NODES`, `VORTEX_MAX_CONN`, `VORTEX_TRACE_BUDGET`, `VORTEX_BUILD_THROTTLE`
- `VORTEX_MIN_READY`, `VORTEX_DECAY_THROTTLE`
- `VORTEX_TELE_CHAIN_MAX`, `VORTEX_TELE_WARP_DIST`, `VORTEX_TELE_COST`
- `VORTEX_LIFT_SAMPLE_THROTTLE`
- `APEX_BUILD_THROTTLE`, `APEX_MIN_NODES`

## Vortex Telechains + Apex Lifts (teleport + platform fusion)
- Telechains: large warps (>500u) are detected via phantom tele events and fused
  into one-way tele edges; chain depth is limited to prevent loops.
- Lifts: nodes are sampled against `func_plat`/`func_train`, with a wait penalty
  based on the lift cycle; Apex clusters mark lift portals as low-cost edges.
- Rollout sim grants a small reward when riding lifts to encourage stable platform usage.

## Mirage Minds tuning (cvars)
- `sv_mirage` (0/1): master enable for persona-driven humanization
- `mirage_debug` (0/1): log persona/entropy (requires `+developer 1`)

Defaults for `sv_mirage` and `mirage_debug` are set in `mre/Autoexec.cfg`.

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

## Legacy docs
The previous MRE development guide is archived at `archive/legacy/v1/DEVELOPMENT_MRE.md`.
