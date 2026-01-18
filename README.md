# Reapbot (Reaper Bot reboot)

We are rebooting the classic Reaper Bot from the original source and fixing
the community-reported issues first. The goal is a stable, fair, and readable
baseline that we can extend in small, testable steps.

## Active code (do not edit legacy)
All active, working code lives in `mre/` only:
https://github.com/saworbit/mre/tree/master/mre
Everything under `archive/` is legacy reference material. Do not edit or build
from `archive/`.

## Status

**28+ community issues addressed + expanded navigation features** - see [CHANGELOG.md](CHANGELOG.md) for details.

### Fixed
- Crashes: SP edict overflow, MP route recursion, scoreboard overflow
- Movement: Jumpy strafing, water flashing, stuck in place, lift/door handling
- Hazards: Lava/slime avoidance, explosive self-damage, LG water discharge
- Fairness: Target selection, vacuum pickup, camping, skill-based aim jitter, observer targeting
- Physics: Explosion knockback, backpack spawning
- Compatibility: sv_aim warning spam
- Aiming: Predictive lead capping

### New Features
- High skill levels unlocked (skill 0-10, was 0-3) - skill 4+ = "god mode" bots
- Impulse 100 quick-add bot (standard convention from Frogbot)
- Velocity-based 3D swimming (oxygen-aware surfacing and pitch steering)
- Feeler steering + breadcrumbs (escape scans and dropped BotPath waypoints)
- Navigation learning (link types, usage weighting, danger/decay, rocket jumps)
- Retrospective learning + path optimization (trail rewards and shortcut links)
- Teacher Mode debug impulses (102 show / 103 hide bot learning nodes)

### Investigated (Likely Fixed / Not Found)
- "Bot frags not shown" - MSG_UPDATEFRAGS sent correctly, likely fixed by 0-index fix
- "Extra SNG ammo" - bots use same ammo as players
- "Firing faster" - bots use identical attack timings
- "Respawn splash sound" - spawn uses correct teleport sounds
- "Floating after respawn" - spawn already uses MOVETYPE_STEP

### Non-Issues (Engine/Content)
- Score display at intermission - standard Quake behavior
- Scoreboard colors - engine limitation, modern ports handle correctly
- MultiSkin unreliable - code works, requires player.mdl with 16 skins

## Build
```powershell
.\ci\build_mre.ps1
```
This compiles `mre/`, writes `progs.dat` into `ci/mre/progs.dat`, and deploys the same copy to `launch/quake-spasm/mre/progs.dat` so the runtime directory stays in-sync with the build.
Manual build (fteqcc) + deploy:
```powershell
cd c:\reaperai\mre
..\tools\fteqcc_win64\fteqcc64.exe -O3 progs.src
copy c:\reaperai\progs.dat c:\reaperai\launch\quake-spasm\mre\progs.dat /Y
```

## Run
```batch
cd launch\quake-spasm
launch_reapbot_v2.bat 8 dm4
```
Manual command with logging:
```batch
quakespasm.exe -game mre -condebug +developer 1 -listen 8 +maxplayers 8 +deathmatch 1 +map dm4
```

## Test
```powershell
# Full stability regression tests (~4 minutes)
.\ci\test_stability.bat

# Quick tests (~2 minutes)
.\ci\test_stability.bat --quick
```
Command to run stability regression tests: `.\ci\test_stability.bat` (add `--quick` for shorter runs).

Automated tests check for: edict overflow, runaway loops, route recursion, scoreboard overflow.

## Docs
- [ARCHITECTURE_CURRENT.md](ARCHITECTURE_CURRENT.md) - Control flow and call graph
- [mre/README.md](mre/README.md) - Quick start and testing checklist
- [mre/COMMUNITY_ISSUES.md](mre/COMMUNITY_ISSUES.md) - Issue tracker
- [mre/CHANGELOG.md](mre/CHANGELOG.md) - Detailed changes
- [mre/SOURCES.md](mre/SOURCES.md) - Research sources
- [KNOWN_ISSUES.md](KNOWN_ISSUES.md) - Current regressions (bots clipping, logging gaps) and reproduction notes
