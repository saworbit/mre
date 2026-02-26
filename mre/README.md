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
- `impulse 105` - Toggle Specter Gaze (cinematic spectator camera)
- `impulse 106` - Cycle Specter camera focus to next bot
- `specter_chase 1` - First-person chase mode (through bot's eyes)
- `specter_chase 0` - Cinematic third-person mode (default)
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
- [ ] **Lift Riding**: Bots wait on moving/descending platforms, don't walk off mid-ride
- [ ] **Lift Timeout**: Bots don't wait forever on stopped platforms (bail after 2-5s)
- [ ] **Lift Routing**: Bots time lifts and don't spam jump on platforms
- [ ] **Train Bail-Out**: Bots leave stopped func_trains after 2s (DM2 lava room)
- [ ] **Door Opening**: Bots trigger doors and wait for them to open
- [ ] **Button Solving**: Bots find and activate buttons to open doors (8s timeout)
- [ ] **Ripple Oracles**: Bots probe blocked goals, shoot/touch buttons or plats, and chain cascades
- [ ] **Hazard Avoidance**: Bots refuse to walk into lava/slime
- [ ] **Wall Flow**: Bots curve smoothly around corners (no stop-turn-go)
- [ ] **Cliff Awareness**: Bots steer away from ledges before reaching them
- [ ] **Stair Climbing**: Bots navigate 24u step heights on custom maps (not just standard 18u)
- [ ] **Feeler Recovery**: Stuck bots enter feeler mode, then pick a new goal (not repeat same path)
- [ ] **Mirage Arcs**: Bots show slight yaw/pitch drift and occasional glance-aways (entropy layer)
- [ ] **Specter Gaze**: `impulse 105` toggles cinematic camera, smooth tracking, auto-switching on action
- [ ] **Specter Chase**: `specter_chase 1` gives first-person through bot's eyes
- [ ] **Specter Cycle**: `impulse 106` cycles focus, camera snaps then smoothly settles
- [ ] **Specter Off**: `impulse 105` again returns player to original position

### Navigation Humanization
- [ ] **Bunny Hop Variance**: Watch bots hop - timing and strafe angles vary per hop (not metronomic)
- [ ] **Momentum Blending**: Bots don't snap-turn instantly - direction changes have visible momentum
- [ ] **S-Curve Turns**: Bots accelerate into turns and decelerate out ("whip and settle" pattern)
- [ ] **Graduated Edge Braking**: Bots slow down early near edges instead of abrupt last-second stop
- [ ] **Platform Fidgeting**: Bots shift slightly and look around while riding lifts (not frozen)
- [ ] **Roaming Speed Variance**: Idle bots vary speed, slow at corners, occasionally micro-pause
- [ ] **Swim Clumsiness**: Bots wobble in pitch and respond sluggishly when swimming

### Adaptive Tactics
- [ ] **Opponent Profiling**: Bots track per-enemy aggression/weapon/threat over time (check with developer logs)
- [ ] **Counter-Weapons**: Bots pick RL vs LG users, LG vs RL users, SNG vs shotgunners, GL included (skill 2+)
- [ ] **Aggression Spectrum**: Low-health bots kite/retreat while facing enemy and shooting (not turning back to run)
- [ ] **Multi-Threat Awareness**: 2+ visible enemies reduce aggression score (bots retreat/kite more, no hard freeze)
- [ ] **Match Phase**: Early game bots rush weapons, mid-game prioritize armor, endgame chase powerups
- [ ] **Endgame Trigger**: Someone near fraglimit → ENDGAME even in small games (not stuck in SCRAMBLE)
- [ ] **Sound Threat Model**: Bots infer enemy weapons from sounds and adjust caution accordingly
- [ ] **Sound Cleanup**: Sound investigation expires cleanly after 2s (no permanent investigate state)
- [ ] **Adaptive Distance**: Bots keep range vs LG users, close gap vs RL users, push vs weak weapons
- [ ] **Quad Rampage**: Quad bots are always max-aggressive, never retreat or grab items
- [ ] **Invuln Aggression**: Invulnerable bots are always max-aggressive (immune to threat/damage penalties)

### Combat Fairness
- [ ] **Aim Jitter**: Skill 0 bots miss noticeably (~30° error), skill 5+ near-perfect
- [ ] **Reaction Time**: Skill 0 bots have ~300ms delay before first shot (surprise attacks work)
- [ ] **Object Permanence**: Bots continue firing at doorways briefly after you break LOS
- [ ] **Feints**: Bots occasionally pause fire briefly at close range (mirage entropy)
- [ ] **Pitch Jitter**: Bots show slight vertical aim drift (not laser-locked pitch)
- [ ] **Glance-Aways**: Skill 3+ bots briefly look off-target during high entropy
- [ ] **Knockback**: Bots get pushed by rockets/explosions (not rooted in place)
- [ ] **Gradual Retreat**: Low-health bots retreat probabilistically based on effective health
- [ ] **Ammo Switching**: Bots switch weapons before running dry (not after)
- [ ] **Blind Fire Memory**: Pre-fire stops after 2 consecutive misses at same corner
- [ ] **Blind Fire Walls**: Pre-fire checks trace_fraction, doesn't rocket into walls
- [ ] **Item Grab Abort**: Low-health bots abandon item pickups when under fire
- [ ] **No Vacuum Pickup**: Items don't vanish until bot reaches them
- [ ] **Target Selection**: Bots fight each other, not just humans
- [ ] **Target Switching**: secondEnemy doesn't double-switch (clean else guards)
- [ ] **Safe Explosives**: Bots switch weapons at close range (<150 units)
- [ ] **Invuln Close-Range RL**: Invulnerable bots use RL at melee (not just axe)
- [ ] **Env-Kill Direction**: Bots push enemies toward hazards using knockback direction (not enemy facing)
- [ ] **Water Safety**: Bots don't discharge lightning gun in water
- [ ] **No Camping**: Bots don't linger at weapons they already own
- [ ] **Observer Safety**: Bots ignore spectators (noclip players)
- [ ] **Combat Bunny Hop**: Skilled bots hop (roam: skill 3+, far combat: skill 3+, retreat: skill 4+)
- [ ] **Circle Strafing**: Skill 5+ bots orbit tighter (60-75°) during combat
- [ ] **Elevation Preference**: Bots prefer strafing toward higher ground
- [ ] **Threat Targeting**: Bots prioritize enemies aiming at them with dangerous weapons
- [ ] **Post-Kill Scavenge**: Bots pick up backpacks/items for 2s after a kill
- [ ] **Powerup Timing**: Skill 3+ bots pre-position for powerups about to spawn
- [ ] **Ambush Silence**: Ambushing bots don't jump (no position giveaway)
- [ ] **Clean Respawn**: Bots start fresh each life (no stale sounds, damage, or investigation state)

### Aiming
- [ ] **Lead Capping**: Bots don't over-lead at long range
- [ ] **Skill Scaling**: Higher skill = better aim (test skill 0 vs 3)

### Physics
- [ ] **Knockback**: Bots get pushed by rocket explosions ("bounce the Reaper")
- [ ] **Backpacks**: Dropped backpacks don't appear inside walls/void

### Performance (Optimization Pass #9 + Review #12)
- [ ] **No Behavior Change**: All optimizations are behavior-neutral (identical gameplay)
- [ ] **Build Clean**: Compiles with 0 errors, 35 warnings (all pre-existing)
- [ ] **Stability**: Run 8-bot DM on dm4 for 10+ minutes — no crashes, lockups, or new warnings
- [ ] **Missile List**: Bots still dodge rockets/grenades correctly (BotReflexDodge)
- [ ] **Bot Scanning**: Sound propagation, ally alerts, match phase detection still work
- [ ] **Unified Sound**: Single-loop hearing model (Bot_AlertNoise sets both heard_sound + noise fields)
- [ ] **Retreat Caching**: Low-health bots still retreat toward health/armor items
- [ ] **Scavenge Caching**: Bots still pick up items after kills (2s window)
- [ ] **Edge Friction**: Bots still brake near edges (no falling off cliffs)
- [ ] **Angle Smoothing**: 3-frame angle averaging still eliminates jitter
- [ ] **Cached Cvars**: `cached_developer` and `cached_sv_mirage` set once per frame
- [ ] **EnemiesNear**: Uses bot_list_head walk, not findradius
- [ ] **Spectral Visit**: Rollouts start clean (no inter-bot pollution)
- [ ] **Breadcrumb Cap**: SpawnSavedWaypoint respects NUMPATHS >= 140 limit

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
