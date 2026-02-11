# Changelog

## Unreleased

### Overview
- Rebooting Reaper Bot from a clean baseline.
- Focusing first on community-reported issues.

### Bugfixes (Post-Pass #8)
- **Fix: Retreat faces enemy** (`bot_ai.qc`). `ai_botretreat()` now faces the enemy and
  fires while backpedaling, instead of turning its back and running away. Uses raw
  `walkmove()` for backward movement (same fix as kite). Safety-item blending and zigzag
  strafe still work but only affect movement direction, not facing. `CheckBotAttack()`
  called at end so bots shoot during retreat.
- **Fix: THIRD_PARTY_WAIT removed** (`bot_ai.qc`). The hard `return` in THIRD_PARTY_WAIT
  suppressed ALL combat when 2+ enemies were visible. With 3 bots this was almost always
  true, causing bots to stand still and not shoot. Multi-threat awareness still works
  through aggression score (-0.25/-0.15 penalty).
- **Fix: Kite "running on the spot"** (`bot_ai.qc`). Kite mode used `botwalkmove()` whose
  BotSteer whiskers fight backward movement. Replaced with raw `walkmove()` plus ±45°/±90°
  fallback escapes. Bots now backpedal smoothly while facing and shooting the enemy.
- **Fix: Stuck Doctor jump spam** (`botmove.qc`, `defs.qc`). Added 2-second cooldown
  (`stuck_jump_cd` field) to prevent bots jumping on the spot repeatedly when movement is
  blocked. Previously had no cooldown — every frame that walkmove failed, bot jumped again.

### Intelligence Pass #8 (Adaptive Tactics)
Seven adaptive tactics systems that give bots cross-system game sense and opponent modeling:
- **Opponent profiling** (`botit_th.qc`, `defs.qc`). 4-slot LRU opponent tracker stores
  per-enemy EMA for aggression (velocity dot product), weapon (last observed `IT_*`),
  and threat (kill/death record). `OppUpdate()` blends on each enemy sighting;
  `OppRecordResult()` updates threat on kills/deaths. Alpha=0.3 EMA smoothing prevents
  oscillation. LRU eviction shifts oldest profiles when all slots are full.
- **Counter-weapon selection** (`botfight.qc`). After existing weapon scoring, reads
  enemy weapon via `OppGetWeap()` (falls back to `enemy.weapon`) and adds counter
  bonuses: RL +15 vs LG, LG +15 vs RL, SNG +10 vs SSG/SG, SSG +10 vs GL. Skill 2+
  gate. Re-evaluates best weapon after counter bonuses applied.
- **Continuous aggression score** (`bot_ai.qc`). `BotAggressionScore()` returns 0.0-1.0
  based on: effective HP (base), weapon quality (±0.15), powerups (±0.3-1.0), opponent
  profile (threat/aggression EMA ±0.09-0.1), enemy health (+0.2 if <25), score pressure
  (±0.1), multi-threat (-0.15-0.25), match phase (±0.1-0.15), skill dampening, and
  hysteresis EMA (0.7/0.3 blend). Replaces binary `RunAway()` call with three-tier
  response: <0.25 full retreat, 0.25-0.45 kite (retreat + fire at 0.6x speed), ≥0.45 fight.
- **Multi-threat awareness** (`bot_ai.qc`). `visible_threats` counter piggybacks both
  player and bot scan loops in `BotFindTarget` at zero extra cost. Third-party patience:
  if 2+ visible threats and target is fighting someone else (health >40), bot waits up
  to 2s before engaging. Feeds into aggression score as -0.25 (2 enemies) or -0.15 (3+).
- **Match phase detection** (`bot_ai.qc`, `botgoal.qc`). `BotUpdateMatchPhase()` scans
  all players/bots for total and max frags, compares against `cvar("fraglimit")`.
  Phase 0 (SCRAMBLE): total frags <10, +20 weight for RL/LG weapons. Phase 1 (CONTROL):
  mid-game, +15 for armor2/armorInv. Phase 2 (ENDGAME): max frags within 5 of fraglimit,
  +30 for Quad/Pent. Throttled to 1 update/second.
- **Weapon sound inference** (`botnoise.qc`, `bot_ai.qc`). `Bot_BroadcastNoise` stores
  `heard_sound_weapon` when type is NOISE_WEAPON. `Bot_AnalyzeSound` NOISE_WEAPON handler
  (was empty return) now classifies: RL/GL heard + weak (<60 eff HP) → cautious (priority
  30), weak weapon heard + strong → aggressive push (priority 90), default → normal (50).
- **Adaptive engagement distance** (`bot_ai.qc`). Optimal combat distance modulated by
  enemy weapon: +100u vs LG (stay outside effective range), -80u vs RL (close gap for
  easier dodge), +60u vs SSG (falls off fast), -100u vs weak weapons (push). Further
  scaled by aggression: `opt_dist + (0.5 - aggression) * 150`. Clamped 100-800u, skill 2+.
  Strafe evasiveness increases when aggression is low.

### Intelligence Pass #7 (Problem-Solving — Planned)
Seven cross-system "game sense" improvements proposed during review. All seven were
implemented as part of Intelligence Pass #8 (Adaptive Tactics) above, with expanded
scope including opponent profiling and match phase detection.

### Intelligence Pass #6 (Navigation Humanization)
- **Bunny hop rhythm variance** (`botmove.qc`). Replaced fixed 0.4s/15deg/40accel
  with variable hop_interval (0.28-0.50s, skill-narrowed), strafe_angle (10-22deg,
  skill-converges to ~15 optimal), and accel_boost (30-50 ground, 8-16 air). Higher
  skill = tighter, more consistent rhythm.
- **Velocity momentum blending** (`botmove.qc`). Replaced instant velocity snapping
  in `botwalkmove` with lerp-based direction changes: `blend_rate = 0.6 + skill*0.03`
  (cap 0.85). Direction changes blend over 2-3 frames instead of instant 90-degree
  snaps. Creates human-like momentum on turns.
- **S-curve turn acceleration** (`botmove.qc`). Added Hermite smoothstep
  (`3t^2 - 2t^3`) to `BotClampYaw`. Small residual angles decelerate, large angles
  ramp up — creates the "whip and settle" pattern humans exhibit with mouse
  acceleration. Turn speed modulated from 30% to 100% of max based on the curve.
- **Graduated edge friction** (`botmove.qc`). Replaced single 32-unit binary check
  with two-distance graduated braking in `BotApplyEdgeFriction`: far check (64u) =
  0.92 gentle brake, near check (32u) = 0.70 heavy brake. Natural early deceleration
  instead of an abrupt last-second stop.
- **Platform fidgeting** (`botmove.qc`). Replaced `velocity = '0 0 0'` in
  `BotCheckPlatformRide` with micro-drift (±10 units/s random) and 5% chance per
  frame to look around (±20 deg yaw). Bots shift weight and glance while riding
  lifts instead of standing perfectly still.
- **Roaming speed variation** (`bot_ai.qc`). Replaced fixed `200 * BOT_IDLE_THINK`
  in `BotRoam` with variable 180-240 speed, 0.7x corner slowdown (when whiskers
  detected obstacle), and 2% micro-pause with look-around. Eliminates the constant
  metronome pace of idle wandering.
- **Swimming clumsiness** (`botmove.qc`). Added triangle-wave pitch wobble
  (`±(8 - skill)` degrees, ~2s period) and sluggish velocity blend
  (`0.4 + skill*0.04`, cap 0.75) in `BotSwim`. Replaces instant velocity assignment
  with gradual convergence — bots wallow in water instead of laser-tracking targets.

### Simplification (System Cleanup)
- Removed **Apex HPA\*** hierarchical clustering (`ai_apex.qc` deleted, references removed from `world.qc`, `progs.src`). The Vortex A* mesh handles all maps without a second abstraction layer.
- Simplified **Mirage Minds**: removed persona system (5 personas, persona switching, heat maps, micro-goals). Now entropy-only with yaw/pitch jitter, glance-aways, and hold-fire feints.
- Simplified **Ripple Oracles**: removed MCTS tree search. Now uses heuristic trace probes with flat beam-search fallback. Same cascade fusion, far less code.
- Cleaned up **Slayer Eclipse**: removed hardcoded username checks (`slywall`/`Shane`). `user_learn` now applies to any connected player.

### Navigation Fix (3 Changes)
- **Distance-weighted goal selection** (`botgoal.qc`): items closer to bot score up to +20 bonus. Was pure weight comparison ignoring distance.
- **Doubled search radius** (`botit_th.qc`): `SEARCH_RADIUS` increased from 600 to 1200 units. Bots see items much further away.
- **Goal-aware bunny hop** (`botmove.qc`): bots only hop when >600u from goal. Prevents chaotic bouncing near items.

### Intelligence Pass #2 (10 Enhancements)
- **Strafe timing jitter** (`bot_ai.qc`): strafe flip timing varies ±25% each cycle. Was fixed, learnable rhythm.
- **Weapon distance scoring** (`botfight.qc`): RL penalized at long range (-10 at 500u, -25 at 800u). SNG gets +15 bonus at mid range (300-700u). Bots show weapon variety.
- **Splash risk override** (`botfight.qc`): bots keep RL/GL at close range to finish near-dead enemies (<30 HP) or when holding Pentagram. Was always swapping off.
- **Target switching momentum** (`bot_ai.qc`): new targets must be 150u closer to steal focus. Near-dead enemies (<20 eff HP) get extra 300u loyalty. Bots commit to kills.
- **State-dependent hysteresis** (`bot_ai.qc`): RETREAT locks 1.5s, GOODY 0.8s, ATTACK 1.0s. Was flat 0.5s for GOODY/RETREAT only. Eliminates attack-retreat-attack stutter.
- **Effective HP health weight** (`botit_th.qc`): health urgency requires both health < 60 AND effective HP < 100. Armored bots fight instead of chasing health packs.
- **Ammo urgency** (`botit_th.qc`): RL bots with <5 rockets and LG bots with <10 cells urgently seek ammo (MUST_HAVE priority).
- **Retreat strafing** (`bot_ai.qc`): retreating bots zigzag at ±30° offsets using STRAFE_DIR alternation. Was straight backpedal.
- **Goal commitment time** (`botgoal.qc`): reduced from 4s to 2.5s lock. Bots re-evaluate goals 60% faster.
- **Skill-scaled turn speed** (`botmove.qc`): max turn speed scales from 18°/frame (skill 0) to 30°/frame (skill 10). Was flat 18° for all.

### Intelligence Pass #3 (10 Enhancements)
- **Quad hyper-aggression** (`bot_ai.qc`): Quad holders retreat only below 25 eff HP (was 50) and skip gradual retreat entirely. Bots push aggressively during Quad instead of wasting it.
- **Enemy Quad caution** (`bot_ai.qc`): bots with <80 eff HP flee enemy Quad even with good weapons. Only tanky bots stand and fight 4x damage.
- **Fast-kill hitscan boost** (`botfight.qc`): when enemy health <25, bots switch from RL/GL to LG or SNG for reliable finishing. Prevents whiffed rockets on near-dead targets.
- **Weapon-range engagement** (`bot_ai.qc`): bots drift toward optimal distance for current weapon (LG: 250u, SNG: 350u, RL: 500u, SSG: 200u). 30%-strength pre-step before strafing.
- **Score pressure adaptation** (`bot_ai.qc`): losing bots (-5 frags) halve retreat probability. Winning bots (+5 frags) increase retreat by 30%. Score affects aggression.
- **Velocity-based stuck guard** (`botgoal.qc`): stuck detection requires both low position delta AND low velocity (<100). Eliminates false triggers during jumps, lifts, and swimming.
- **Skill-scaled search timeout** (`botgoal.qc`): goal lock time scales from 3.5s (skill 0) to 1.5s (skill 10). High-skill bots adapt goals faster; low-skill bots stay committed.
- **Speed-scaled whisker distance** (`botmove.qc`): obstacle lookahead uses actual velocity instead of walkmove input. Faster bots see obstacles further ahead (50u stopped, 112u bunny hopping).
- **Effective HP armor weight** (`botit_th.qc`): armor evaluation uses effective HP (value * type) derived from classname. Red 200 (160 eff) correctly beats green 100 (30 eff). Low-health bots get +20 armor urgency.
- **Ambush weapon safety** (`bot_ai.qc`): nervous trigger pre-fire suppressed for RL/GL at close range (<200u). LG/SNG/SSG still pre-fire safely. Prevents splash suicide during ambush.

### Intelligence Update (12 Enhancements)
- **Exponential aim jitter** (`botfight.qc`): skill 0 = ~30 deg max error, skill 3 = ~5 deg, skill 5+ = perfect. Was linear ~8 deg max. Also adds Z-axis (pitch) jitter.
- **Reaction fire delay** (`bot_ai.qc`): first shot delayed after spotting enemy (skill 0 = 300ms, skill 4+ = instant). Previously only gated seeing, not firing.
- **Non-linear shadow depth** (`botspawn.qc`): prediction depth now `3 + floor(skill^2 * 0.13)` — skill 0 = 3 steps, skill 5 = 6, skill 10 = 16. Was linear `6 + skill`.
- **Gradual retreat** (`bot_ai.qc`): probability curve using effective health (health + armor * armortype). At 60 eff HP: 0% retreat, at 30: 50%, at 0: 100%. Was hard cutoff at health < 15.
- **Ambush armor awareness** (`bot_ai.qc`): threshold uses effective HP (50), timeout scales by skill (2-5s). Was health < 40 with fixed 4s timeout.
- **Adaptive strafe timing** (`bot_ai.qc`): high-skill bots hold good strafe directions longer (0.3-0.7s vs fixed 0.4s).
- **Multi-axis MirageTick** (`ai_mirage.qc`): added pitch jitter (vertical drift), glance-aways (skill 3+ briefly look off-target), variable hold-fire duration.
- **Ammo-aware weapon switching** (`botfight.qc`): bots preemptively switch weapons before running dry (RL/GL <= 1 rocket, LG <= 5 cells, SNG <= 5 nails).
- **Combat bunny hopping** (`botmove.qc`): bots hop when enemy is far (>400u), skilled bots (4+) hop while retreating mid-range.
- **Blind fire memory** (`botfight.qc`): tracks consecutive missed pre-fires. After 2 misses at the same spot, blacklists it for 10s. Resets on enemy contact.
- **GETGOODY threat abort** (`bot_ai.qc`): bots abandon item grabs when health < 40 and enemy is visible within 400 units.
- **Vortex slime avoidance** (`ai_vortex.qc`): CONTENT_SLIME added to navmesh hazard checks.
- **Specter drama enhancement** (`ai_specter.qc`): low-health duels (+6 drama) and recent combat (+4 drama) bonuses improve camera focus.
- **Skill-scaled RJ depth** (`ai_ripple.qc`): rocket jump simulation steps scale from 6 (skill 0) to 12 (skill 10). Was fixed at 8.
- **Mirage pitch bias** (`botfight.qc`): pitch bias from MirageTick applied to aiming for vertical tracking imperfection.

### Features
- **Specter Gaze** cinematic spectator camera (`ai_specter.qc`, `client.qc`, `botit_th.qc`, `defs.qc`).
  - Toggle with `impulse 105`, cycle focus with `impulse 106`.
  - Two-layer architecture: Think (50-200ms) computes ideal camera positions; ViewUpdate (every server frame ~72fps) interpolates smoothly with frame-rate-independent damping.
  - Geometry-based angles (`vectoangles`) eliminate angle-wrapping bugs entirely.
  - Drama-driven auto-switching: cameras cut to the most exciting bot (5+ drama differential) or switch on boredom (5s idle). No random switching.
  - Chase mode (`specter_chase 1`) for first-person through bot's eyes.
  - Camera entities use `progs/eyes.mdl` + `setorigin` for proper BSP/PVS visibility.
  - Player entity relocated to camera position each frame for correct PVS computation.
  - `SVC_SETVIEW` + `SVC_SETANGLE` sent every server frame from `PlayerPreThink` (same pattern as working CCam).
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
- **Vortex Navmesh**: incremental dynamic mesh seeded from spawns/items, phantom-validated edges, cursed/glory-biased costs, and decay culling (no pre-bake).
- **Vortex Telechains**: teleporter warp detection + one-way quantum edges, chain-limited A* fusion, hazard cursing, and glory boosts for strong exits.
- **Lift Routing**: lift detection/sampling with wait-cost biasing in Vortex A*.
- **Ripple Oracles**: causal interactable prediction for buttons/doors/plats using heuristic trace probes with beam-search fallback, ripple edge fusion into Vortex.
- Mirage Minds (entropy-driven humanization with yaw/pitch jitter, glance-aways, and feint pauses).
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
- **Specter Gaze camera fixes**: Added `setmodel` on camera entities (engine requires `modelindex` to transmit entity data). Added `setorigin` for BSP area link updates. Relocated player entity to camera position for PVS. Moved `SVC_SETVIEW`/`SVC_SETANGLE` to per-frame `PlayerPreThink` hook (was only sent on focus change, causing player mouse to override view angles between updates).
- **Uninitialised variable bugs** (found via `-Wall`):
  - `botgoal.qc:pathweight` computed distance to world origin `'0 0 0'` instead of target entity (missing `org = e.origin`).
  - `botgoal.qc:RunAwayWeight` used uninitialised `weight` when enemy had clear LOS (added `weight = 0` default).
  - `client.qc:ClientObituary` could print garbage death messages for unknown weapon types (added fallback strings).
- Combat rollout action cap now hard-limited to 16 to prevent overflowed action IDs.
- Monte Carlo lead now respects LOS and falls back to a simple lead when obstructed.
- Rival powerup rush now gates on health > 50 and visible powerups to avoid short-circuiting combat.
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
- God mode now forces `shadow_throttle` to `0.1` for consistent rollout cadence.
- Reduced per-user strafe bias hash scale to 32 to trim global usage.
- Movement smoothing (Z-axis ground glue, zero velocity on collision, consistent 0.1s think timing).
- Sensor fusion steering V2 (step-over obstacles and water-safe hazard detection).
- Predictive aiming (capped lead time to 0.5s to prevent over-leading).
- Proactive 1-tick lookahead nudges away from dead-ends during Botmovetogoal.
- Distance-aware reaction delay for closer targets to reduce sluggishness.
- Splash-safe spacing bias for RL/GL at close range.
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
- Time-sliced target acquisition and throttled item/ripple/nudge scans to reduce per-frame trace load.
- Noise alerts skip LOS traces for out-of-range bots; Vortex node lookup uses squared distance.
- Steering hazard checks reduced at low speed to cut redundant hazard traces.
- Nav rollout throttling decoupled from combat; target scan throttle now skill-scaled with recent-contact bypass.
- Ripple interact now reuses a cached nearby node when possible; combat item scans use a smaller radius.
- Optional cvars added to tune bot scan/steer throttles without rebuilds.

### Investigated (Not Found)
- "Extra SNG ammo" complaint (not found in baseline - bots use same ammo as players).
- "Firing faster" complaint (not found - bots use identical attack timings as players).
- "Respawn splash sound" (not found - spawn uses correct teleport sounds).
- "Floating after respawn" (not found - spawn already uses MOVETYPE_STEP).

### Docs and CI
- Updated development and launch docs for the `mre/` layout.
- CI now builds from `mre/` via `ci/build_mre.ps1`.
- Enabled `-Wall -Wno-mundane` in default build flags for static analysis (43 -> 35 warnings after bug fixes; remaining are false positives from guarded branches).
- Archived legacy docs/tools/launch assets and old logs under `archive/legacy/clean_slate/`.
