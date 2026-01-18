# Development Guide (Reapbot reboot)

This repo is a clean reboot of the Reaper Bot. The authoritative source lives
under `mre/`, and we fix community-reported issues first.

## Active code location (do not edit legacy)
All active, working code lives in `mre/` only:
https://github.com/saworbit/mre/tree/master/mre
Everything under `archive/` is legacy reference material. Do not edit or build
from `archive/`.

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

## Deploy
The build script copies to:
`c:\reaperai\launch\quake-spasm\mre\progs.dat`

## Run
```
c:\reaperai\launch\quake-spasm\launch_reapbot_v2.bat 8 dm4
```

## Test (full command + logging)
From `c:\reaperai\launch\quake-spasm`:
```
quakespasm.exe -game mre -condebug +developer 1 -listen 8 +maxplayers 8 +deathmatch 1 +map dm4
```
Log output: `c:\reaperai\launch\quake-spasm\qconsole.log`

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
`[Player] BREADCRUMB: Learned waypoint at ...`. Retrospective learning prints
`AI Optimized: Created shortcut!` and reward logs like
`Learned path to Power Weapon!` / `Learned CRITICAL path to Powerup!`.
Reflex dodge logs appear as `Bot attempting DODGE!`.
Quad debug logs appear as `[QuadSpawn]` when the item respawns and
`[QuadTouch] accept/blocked/reject` when a player or bot tries to pick it up.
Teleport traces appear as `[Teleport]` for bot teleporter use, and large
position jumps log as `[BotWarp]`.
Teacher Mode visualization uses `impulse 102` to show BotPath nodes and
`impulse 103` to hide them.

## CI
```
powershell -ExecutionPolicy Bypass -File c:\reaperai\ci\build_mre.ps1
```
CI publishes: `c:\reaperai\ci\mre\progs.dat`

## Critical QuakeC gotchas
1) **System globals**: never modify anything before `end_sys_globals` in `defs.qc`.
2) **Impulse scope**: guard global toggles with `self.classname == "player"`.
3) **Trace globals**: `traceline()` overwrites `trace_*` globally; save/restore in helpers.
4) **Bitmask clears**: use masked subtraction (`var = var - (var & FLAG)`).

## Legacy docs
The previous MRE development guide is archived at `archive/legacy/v1/DEVELOPMENT_MRE.md`.
