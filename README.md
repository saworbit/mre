# Reapbot (Reaper Bot reboot)

We are rebooting the classic Reaper Bot from the original source and fixing
the community-reported issues first. The goal is a stable, fair, and readable
baseline that we can extend in small, testable steps.

## Status

**18 community issues addressed** - see [CHANGELOG.md](CHANGELOG.md) for details.

### Fixed
- Crashes: SP edict overflow, MP route recursion, scoreboard overflow
- Movement: Jumpy strafing, water flashing, stuck in place, lift/door handling
- Hazards: Lava/slime avoidance, explosive self-damage, LG water discharge
- Fairness: Target selection, vacuum pickup, camping, skill-based aim jitter
- Aiming: Predictive lead capping

### Investigated (Not Found)
- "Extra SNG ammo" - bots use same ammo as players
- "Firing faster" - bots use identical attack timings

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
