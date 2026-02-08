# Reapbot (Reaper Bot reboot)

This workspace is the clean baseline for rebuilding Reaper Bot. We are fixing
the community-reported issues first, then iterating from there in small steps.

## Quick Start

### Build
```powershell
.\ci\build_mre.ps1
```
This compiles `mre/` and deploys `progs.dat` to `launch/quake-spasm/mre/`.

### Run
```batch
cd launch\quake-spasm
launch_reapbot_v2.bat 8 dm4
```
Arguments: `[maxplayers] [map]` (defaults: 8, dm4)

### In-Game Commands
- `impulse 100` - Add a bot (standard convention)
- `impulse 205` - Add a bot (original Reaper command)
- `impulse 102` - Remove a bot
- `impulse 104` - Dump spectral episode count
- `skill 0-10` - Set bot difficulty (0=easy, 3=nightmare, 4+=god mode)

## Testing

### Automated Stability Tests (Recommended)

Run before every release to catch regressions:

```powershell
# From repo root
.\ci\test_stability.bat          # Full tests (~4 min)
.\ci\test_stability.bat --quick  # Quick tests (~2 min)
```
If running from `cmd`, use:
```batch
cmd /c c:\reaperai\ci\test_stability.bat
cmd /c c:\reaperai\ci\test_stability.bat --quick
```
Tests automatically check for:
- Edict overflow (SP crash)
- Runaway loops (MP lockup)
- Route recursion hangs
- Scoreboard overflow crash

### Manual Testing Checklist

For visual/behavioral verification:

#### Stability (Automated above, but verify visually if needed)
- [ ] **SP Crash**: Load `e1m1` in singleplayer, add 2 bots, play 5+ minutes
- [ ] **MP Lockup**: Host 8-bot DM on `dm4`, play 10+ minutes
- [ ] **Scoreboard Overflow**: Try adding bots beyond maxplayers limit

### Movement Quality
- [ ] **Smooth Strafing**: Watch bots strafe - no teleporting/jitter
- [ ] **No Flashing**: Fight bots near water - no flickering in/out
- [ ] **Unstuck**: Bots don't run in place indefinitely
- [ ] **Silent Unstuck**: Bots escape with strafe/pause; jumps stay rare near enemies
- [ ] **Cursed Nodes**: Repeated stuck corners are avoided after a few failures
- [ ] **Vortex Navmesh**: After ~30-60s, bots route around blocked LOS using dynamic mesh nodes
- [ ] **Vortex Telechains**: Teleporter chains are detected (dm2/dm4), exits are predictable, and bots avoid cursed exits
- [ ] **Lift Riding**: Bots wait on platforms, don't walk off mid-ride
- [ ] **Apex Lifts**: Bots time lifts, chain lift paths, and don't spam jump on platforms
- [ ] **Oracle Rides**: Bots sync approach speed to catch lift up-phases (reduced wait)
- [ ] **Door Opening**: Bots trigger doors and wait for them to open
- [ ] **Ripple Oracles**: Bots probe blocked goals, shoot/touch buttons or plats, and chain cascades
- [ ] **Hazard Avoidance**: Bots refuse to walk into lava/slime
- [ ] **Wall Flow**: Bots curve smoothly around corners (no stop-turn-go)
- [ ] **Cliff Awareness**: Bots steer away from ledges before reaching them
- [ ] **Mirage Arcs**: Bots show slight yaw arcs and micro-goal drift (persona layer)

### Combat Fairness
- [ ] **Aim Jitter**: Skill 0 bots miss noticeably (~25° error)
- [ ] **Reaction Time**: Skill 0 bots have ~200ms delay before engaging (surprise attacks work)
- [ ] **Object Permanence**: Bots continue firing at doorways briefly after you break LOS
- [ ] **Feints**: Bots occasionally pause fire briefly at close range (mirage persona)
- [ ] **Knockback**: Bots get pushed by rockets/explosions (not rooted in place)
- [ ] **Retreat**: Low-health bots without nearby goodies back off to break LOS
- [ ] **No Vacuum Pickup**: Items don't vanish until bot reaches them
- [ ] **Target Selection**: Bots fight each other, not just humans
- [ ] **Safe Explosives**: Bots switch weapons at close range (<150 units)
- [ ] **Water Safety**: Bots don't discharge lightning gun in water
- [ ] **No Camping**: Bots don't linger at weapons they already own
- [ ] **Observer Safety**: Bots ignore spectators (noclip players)

### Aiming
- [ ] **Lead Capping**: Bots don't over-lead at long range
- [ ] **Skill Scaling**: Higher skill = better aim (test skill 0 vs 3)

### Physics
- [ ] **Knockback**: Bots get pushed by rocket explosions ("bounce the Reaper")
- [ ] **Backpacks**: Dropped backpacks don't appear inside walls/void

## Docs
- `mre/COMMUNITY_ISSUES.md` - Issue tracker with fix status
- `mre/SOURCES.md` - Research sources
- `mre/CHANGELOG.md` - Detailed change log

## Test Maps
- `dm4` - The Bad Place (standard DM, good for combat testing)
- `dm2` - Claustrophobopolis (teleporters + lava platforms, good for telechains/lifts)
- `dm3` - The Abandoned Base (tight corridors, good for wall-flow steering)
- `dm6` - The Dark Zone (has water, good for water/flash tests)
- `e1m1` - Slipgate Complex (SP map, good for edict limit testing)
- `e1m5` - Gloom Keep (has lava, good for hazard avoidance)
- `e2m6` - The Dismal Oubliette (has lifts, good for platform testing)
