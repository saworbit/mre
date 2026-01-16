# Reapbot (Reaper Bot reboot)

We are rebooting the classic Reaper Bot from the original source and fixing
the community-reported issues first. The goal is a stable, fair, and readable
baseline that we can extend in small, testable steps.

## Status

**28 community issues addressed + 2 new features** - see [CHANGELOG.md](CHANGELOG.md) for details.

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

## Run
```batch
cd launch\quake-spasm
launch_reapbot_v2.bat 8 dm4
```

## Docs
- [mre/README.md](mre/README.md) - Quick start and testing checklist
- [mre/COMMUNITY_ISSUES.md](mre/COMMUNITY_ISSUES.md) - Issue tracker
- [mre/CHANGELOG.md](mre/CHANGELOG.md) - Detailed changes
- [mre/SOURCES.md](mre/SOURCES.md) - Research sources
