# Changelog

## Unreleased

### Overview
- Rebooting Reaper Bot from a clean baseline.
- Focusing first on community-reported issues.

### Features
- Platform riding for func_train (DM2 lava fix - bots inherit platform velocity).
- Platform wait logic (bots wait for approaching platforms over lava).
- Intelligent button interaction (bots find and shoot/touch buttons to open doors).
- Sensor fusion steering (vector-based whisker system for fluid navigation around walls and hazards).
- Humanized physics (turn clamp, air steering, edge friction, wall sliding).
- Velocity-based 3D swimming (oxygen-aware surfacing, pitch steering, direct velocity control).
- Feeler steering + breadcrumbs (8-way scan escape + dropped BotPath waypoints).
- Navigation learning + link types (player-learned links with usage weighting, danger scents, decay, and rocket-jump traversal).
- Silent Specters (stealth unstuck rollouts: quiet maneuvers, jump penalty when enemies are near, minimal jump noise).
- Cursed Nodes (adaptive stuck-learning mesh with decay; integrated into rollouts and route cost).
- Phantom Apprenticeship (spectral episodes with rollout validation, soft A* bias, decay; no teleport shortcuts or golden locks).
- **Vortex Navmesh + Apex HPA\***: incremental dynamic mesh seeded from spawns/items, phantom-validated edges, cursed/glory-biased costs, decay culling, and hierarchical clustering for large maps (no pre-bake).
- **Vortex Telechains**: teleporter warp detection + one-way quantum edges, chain-limited A* fusion, hazard cursing, and glory boosts for strong exits.
- **Apex Lifts**: lift detection/sampling with wait-cost biasing in Vortex and low-cost lift portals in Apex HPA*.
- Mirage Minds (persona-driven humanization with entropy, micro-goals, heatmap denial, and feint pauses).
- Teacher Mode debugging (impulse 102 show / 103 hide BotPath nodes with particles).
- Speed Demon update (bunny hopping on straight runs and reflex projectile dodging).
- Humanized idle behavior (BotRoam makes bots wander and scavenge instead of freezing).
- Unlocked high skill levels (skill 0-10, was 0-3).
- Added impulse 100 quick-add bot (standard convention).
- Added tactical retreat fallback when running away and no goodies are found.
- **Predator Update**: Sound Navigation and Curiosity
  - Sensory Awareness (Hearing): Bots hear combat sounds and investigate (rockets, grenades, explosions).
  - Curiosity (Solving): Bots shoot shootable buttons, doors, and walls to discover secrets.
- Auditory system: Virtual sound events for item pickups, water splashes, and footsteps with occlusion; bots infer and investigate.
- Shadow Puppets Nexus: Shared nav/combat throttle, cvar gates (`sv_shadow_nav`, `sv_shadow_combat`, `shadow_throttle`), per-bot beam/depth overrides, spectral reward bias.
- **Darwin Update**: Adaptive reinforcement learning
  - Natural Selection: Death locations get danger penalty (+500), kill locations get glory boost (+10).
  - Weapon Specialization: Bots develop personal weapon preferences (-10 to +10 confidence per weapon).
  - Stuck Learning: Navigation failures mark nodes as difficult (-100 penalty).
  - Decay System: Danger decays fast (×0.8), glory decays slow (×0.9) every 10 seconds.
  - A* Integration: Glory reduces path cost (up to 30%), danger increases path cost.

### Fixes
- Single player crash to DOS caused by edict overflow (waypoint cap reduced to 50 in SP).
- Multiplayer lockups from exponential route cache recursion (added cycle detection).
- Potential hang from infinite jump simulation into void (added safety counter).
- Crash when adding bots beyond maxplayers (scoreboard overflow guard).
- Crash from graph decay writing to world entity (decay throttling moved to global).
- Projectile dodge detection missing rocket classname (rockets now tagged as missiles).
- Jumpy/teleport-like strafing (removed sub-frame timing, added velocity for interpolation).
- "Flashing" bots near water (stricter teleptest checks).
- Bots getting stuck running in place (time-based tracking, 1.5s forced goal change, 20% jump chance).
- Camper behavior near best weapons (ignore owned weapons when ammo sufficient).
- Suicidal explosive firing (switch weapons when enemy <150 units).
- Thunderbolt water discharge (switch weapons when in water).
- Bots walking into lava/slime (hazard avoidance with powerup awareness).
- Bots walking off lifts mid-ride (platform state detection).
- Bots stuck at closed doors (trigger door and back up to let it open).
- Bots ganging up on players (closest-target selection now uses checkclient + cached bot list).
- "Vacuum pickup" where items vanished before bot reached them (added distance check).
- Bots "stealing" powerups from players waiting at spawn points (only Direct drive when item exists).
- Powerups could be picked through walls/adjacent rooms (added line-of-sight check on touch).
- Button-triggered paths can now be enforced via mandatory waypoints when players press buttons (prevents A* from skipping required detours).
- Low-skill bots felt like cheaters (increased aim jitter from ~10?? to ~25?? max at skill 0).
- Bots attacking observers/spectators (added MOVETYPE_NOCLIP and deadflag checks).
- Bots not affected by explosion knockback (velocity preservation when airborne).
- Bot knockback now uses bounce physics to avoid embedding; restores step mode when settled.
- Suppressed `Bot should be dead!` log spam by skipping BotPostThink on dead bots.
- Zero-velocity knockback causing stuck/jittery bots (require velocity > 50 before entering MOVETYPE_BOUNCE AND resetting knockback timer - prevents recovery timer from being reset by zero-velocity hits).
- GOODY/RETREAT AI oscillation (added 0.5s hysteresis to prevent rapid state flipping).
- Stale knockback/AI state after respawn (reset values in PutBotInServer).
- Bots quitting mid-match (respawn loop no longer removes bots for crowding/score).
- Backpacks spawning in unreachable locations (CONTENT_SOLID/SKY check).
- sv_aim warning spam (one-time flag per map).
- Reverted: BotDead frame reset removed to preserve death animations (gibbed head frame warnings are cosmetic).

### Improvements
- Movement smoothing (Z-axis ground glue, zero velocity on collision, consistent 0.1s think timing).
- Sensor fusion steering V2 (step-over obstacles and water-safe hazard detection).
- Predictive aiming (capped lead time to 0.5s to prevent over-leading).
- Proactive 1-tick lookahead nudges away from dead-ends during Botmovetogoal.
- sv_aim warning now prints the current value and expected baseline.
- Pain reflex triggers immediate bot reaction when taking damage from a player/bot.
- Added a developer-only `KNOCKBACK_END` log when bots return to step movement.
- Added developer-only AI state logging in `BotAI_Main` (logs only on state changes).
- KNOCKBACK log now filters zero-velocity entries and debounces duplicates (0.05s) to reduce console spam.
- Range-based weapon selection with close-quarters combat logic (< 150 units: SNG > SSG > LG > NG > SG, explosives only with Quad; standard range: LG > RL > SNG > GL mid-range only > SSG; long range: prefer nails over shotguns).
- Removed legacy episodic learning (golden path locks, teleport shortcuts, LOS shortcutting, trail rewards).
- Removed broken map-control timing rushes (auto-drop BotPath at powerup spawns, spawn-time beelines, and golden lock boosts).

### Refactors and Optimization
- Centralized run logic via `BotAI_Main` during shot/axe frames to reduce tunnel vision.
- BotFindTarget scans players via checkclient and bots via cached bot list to avoid full entity walks.

### Investigated (Not Found)
- "Extra SNG ammo" complaint (not found in baseline - bots use same ammo as players).
- "Firing faster" complaint (not found - bots use identical attack timings as players).
- "Respawn splash sound" (not found - spawn uses correct teleport sounds).
- "Floating after respawn" (not found - spawn already uses MOVETYPE_STEP).

### Docs and CI
- Updated development and launch docs for the `mre/` layout.
- CI now builds from `mre/` via `ci/build_mre.ps1`.
- Archived legacy docs/tools/launch assets and old logs under `archive/legacy/clean_slate/`.
