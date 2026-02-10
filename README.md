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
- Powerups: Line-of-sight required for pickups (prevents through-wall grabs)
- Physics: Explosion knockback, backpack spawning
- Compatibility: sv_aim warning spam
- Aiming: Predictive lead capping

### New Features
- High skill levels unlocked (skill 0-10, was 0-3) - skill 4+ = "god mode" bots
- Impulse 100 quick-add bot (standard convention from Frogbot)
- Velocity-based 3D swimming (oxygen-aware surfacing and pitch steering)
- Feeler steering + breadcrumbs (escape scans and dropped BotPath waypoints)
- Navigation learning (link types, usage weighting, danger/decay, rocket jumps)
- Silent Specters (stealth unstuck rollouts; jump noise minimized, enemy-aware penalty)
- Cursed Nodes (adaptive stuck-learning mesh with decay, biases rollouts + routing)
- Phantom Apprenticeship (spectral episodes with rollout validation, soft A* bias, decay; no teleport shortcuts or golden locks)
- **Vortex Navmesh** (incremental dynamic navmesh seeded from spawns/items, phantom-validated edges, cursed/glory-biased costs; no pre-bake)
- **Vortex Telechains** (teleporter warp detection and one-way quantum edges; chain-safe, hazard-aware, low-cost path fusion)
- **Ripple Oracles** (heuristic interactable prediction with beam-search fallback; fuses button/plat/door cascades as ripple edges)
- **Grenade Vortex (GJ/GLJ)**: Grenade jumps and bounce-jumps integrated into Quantum Leaps with ammo-aware priors, purpose-tuned arcs, and phantom auto-tuning
- Mirage Minds (entropy-driven humanization with yaw/pitch jitter, glance-aways, and feint pauses)
- Teacher Mode debug impulses (102 show / 103 hide bot learning nodes, 104 dump spectral episodes)
- Speed Demon update (bunny hopping on straight runs and reflex projectile dodging)
- **Predator Update**: Strategic intelligence upgrade
  - Sound Navigation: Bots hear combat, item pickups, water splashes, and footsteps (with occlusion) and investigate
  - Curiosity: Bots shoot shootable buttons/doors/walls to discover secrets
- **Smooth Steering**: 3-frame angle averaging prevents jitter from pathfinder/whisker oscillation
- **Sixth Sense**: 360-degree awareness for items within 300 units (no facing check needed)
- **High-Value Item Focus**: Direct drive to powerups when close (<200 units) prevents strafing past
- **Proactive Lookahead**: 1-tick movement sim nudges bots away from dead-ends
- **Mastermind Update**: Proactive tactical combat
  - Pre-Fire: Bots shoot rockets at corners where you just disappeared
  - The Trap: Low-health bots stop running and ambush chasers with SSG/RL
  - Displacement: Bots knock enemies into lava/slime using splash damage
- **Darwin Update**: Adaptive self-learning through reinforcement
  - Natural Selection: Bots mark death locations as dangerous (avoided) and kill locations as glorious (attractive)
  - Weapon Specialization: Bots develop personal weapon preferences based on success/failure history
  - Stuck Learning: Navigation failures mark problematic nodes as difficult
  - Decay System: Danger fades fast (courage) while glory fades slow (nostalgia)
- **Specter Gaze**: Cinematic spectator camera system
  - Two-layer architecture: heavy math at Think rate, smooth interpolation every server frame (~72fps)
  - Drama-driven auto-switching (no random cuts — cameras follow the action)
  - Enhanced drama scoring: low-health duels and recent combat bonuses
  - Chase mode for first-person through bot's eyes
  - Toggle: `impulse 105`, cycle focus: `impulse 106`, chase: `specter_chase 1`
- **Intelligence Update**: Skill-differentiated humanization
  - Exponential aim jitter (skill 0 = ~30 deg, skill 5+ = perfect)
  - Reaction fire delay gates first shot after spotting enemy (skill 0 = 300ms, skill 4+ = instant)
  - Non-linear prediction depth (skill 0 = 3 steps, skill 5 = 6, skill 10 = 16)
  - Gradual retreat based on effective health (health + armor), not hard cutoff
  - Ambush uses effective health and skill-scaled patience (2-5s timeout)
  - Adaptive strafe timing (high skill holds good directions longer)
  - Multi-axis humanization: pitch jitter, glance-aways, variable hold-fire
  - Ammo-aware weapon switching (preemptive switch before running dry)
  - Combat bunny hopping (skilled bots hop while retreating mid-range)
  - Blind fire memory (stops pre-firing corners after 2 consecutive misses)
  - Item grab threat abort (abandons pickups when under fire at low health)
  - Vortex slime avoidance and skill-scaled rocket jump depth

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
..\tools\fteqcc_win64\fteqcc64.exe -O3 -Tq1 -DQS_V6 progs.src
copy c:\reaperai\progs.dat c:\reaperai\launch\quake-spasm\mre\progs.dat /Y
```
Note: `progs.dat` currently exceeds the 32k global limit, so an enhanced QCVM/engine is required at runtime.

## Run
```batch
cd launch\quake-spasm
launch_reapbot_v2.bat 8 dm4
```
Manual command with logging:
```batch
quakespasm-sdl12.exe -game mre -condebug +developer 1 -listen 8 +maxplayers 8 +deathmatch 1 +map dm4
```

If QuakeSpasm reports `progs.dat has wrong version number (7 should be 6)`,
run via the bundled FTEQW engine instead:
```batch
cd c:\reaperai\launch\fteqw_win64
fteqw64.exe -basedir c:\reaperai\launch\quake-spasm -game mre -condebug +developer 1 -listen 8 +maxplayers 8 +deathmatch 1 +map dm4
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
- [REAPER_BOT_REBOOT_SPEC.md](REAPER_BOT_REBOOT_SPEC.md) - Design and implementation spec (aligned)
- [mre/README.md](mre/README.md) - Quick start and testing checklist
- [mre/COMMUNITY_ISSUES.md](mre/COMMUNITY_ISSUES.md) - Issue tracker
- [mre/CHANGELOG.md](mre/CHANGELOG.md) - Detailed changes
- [mre/SOURCES.md](mre/SOURCES.md) - Research sources
- [KNOWN_ISSUES.md](KNOWN_ISSUES.md) - Current regressions (bots clipping, logging gaps) and reproduction notes

## Shadow Puppets (Predictive Rollouts)
The reboot now includes predictive rollout systems for navigation and combat:
- **Navigation Shadow Puppets**: short-horizon beam search to avoid hazards and dead-ends.
- **Combat Crucible**: dual-rollout combat oracle that selects a first action using beam search.

Runtime cvars (see `DEVELOPMENT.md` for full details):
- `shadow_debug` (0/1) master debug
- `shadow_nav_*` and `shadow_combat_*` tuning knobs

## Mirage Minds (Humanization Layer)
- `sv_mirage` (0/1) master enable
- `mirage_debug` (0/1) developer logs
- Entropy-driven: mood drift, yaw jitter, pitch jitter, glance-aways, hold-fire feints
- No personas or heat maps — lightweight entropy model only

## Vortex Navmesh (Dynamic Learning Mesh)
- Incremental mesh: flood-fill from spawns/items builds nodes and edges over time (no pre-bake).
- Phantom episodes validate edges; cursed nodes add cost; glory usage attracts paths.
- Mesh only takes over when a direct line to the goal is blocked; normal BotPath routing remains the baseline.
- Slime and lava both treated as hazards in navmesh edge validation.

## Vortex Telechains (Teleport Fusion)
- Detects large teleporter warps and fuses one-way "quantum" edges between entry/exit nodes.
- Chaining is permitted with loop limits; hazard exits are cursed, powerups boost usage.
- Tele edges are low-cost in Vortex A*.
- Lift nodes are sampled from `func_plat`/`func_train` with wait-cost biasing.

## Ripple Oracles (Causal Interactables)
- When goals are blocked, Ripple probes nearby interactables (buttons/doors/plats).
- Heuristic trace + beam-search simulate shoot/touch/wait cascades and fuse one-way ripple edges.
- Vortex pathing can redirect to the interactable position before resuming the goal.
- Rocket jump beam depth scales by skill (6 steps at skill 0, 12 at skill 10).

## Grenade Vortex (GJ/GLJ Leaps)
- Extends Quantum Leaps with grenade jumps (GJ) and bounce-aware GLJ actions.
- Beam-search rollouts sample RJ/GJ/GLJ based on ammo, health, and purpose (lava/vault/high).
- Phantom episodes auto-tune GJ horiz/vert coeffs and GLJ launch angles.
