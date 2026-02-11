# Changelog

## Unreleased
- Clean baseline restored in `mre/`.
- Fix: **Retreat faces enemy** (`bot_ai.qc`). `ai_botretreat()` faces enemy and fires
  while backpedaling using raw `walkmove()`. No more turning back to run away.
- Fix: **THIRD_PARTY_WAIT removed** (`bot_ai.qc`). Hard return suppressed all combat
  when 2+ enemies visible. Multi-threat still works via aggression score penalty.
- Fix: **Kite running on the spot** (`bot_ai.qc`). Raw `walkmove()` replaces
  `botwalkmove()` in kite mode — BotSteer whiskers fought backward movement.
- Fix: **Stuck Doctor jump spam** (`botmove.qc`, `defs.qc`). 2s cooldown on stuck
  jumps via `stuck_jump_cd` field. No more repeated jumping when movement blocked.
- Enhancement: **Opponent profiling** (`botit_th.qc`, `defs.qc`). 4-slot LRU opponent
  tracker with EMA (alpha=0.3) for per-enemy aggression, weapon, and threat. Functions:
  `OppSlot`, `OppSlotOrEvict`, `OppUpdate`, `OppGetAggro/Threat/Weap`, `OppRecordResult`.
- Enhancement: **Counter-weapon selection** (`botfight.qc`). Reads enemy weapon via
  `OppGetWeap()` and adds counter bonuses: RL +15 vs LG, LG +15 vs RL, SNG +10 vs
  SSG/SG, SSG +10 vs GL. Skill 2+ gate.
- Enhancement: **Continuous aggression score** (`bot_ai.qc`). `BotAggressionScore()`
  returns 0.0-1.0 based on HP, weapons, powerups, opponent profile, score pressure,
  multi-threat, and match phase. Replaces binary `RunAway()` call: <0.25 retreat,
  0.25-0.45 kite (fire while backing at 0.6x speed), ≥0.45 fight. EMA hysteresis
  (0.7/0.3 blend) prevents oscillation.
- Enhancement: **Multi-threat awareness** (`bot_ai.qc`). `visible_threats` counter in
  `BotFindTarget` scan loops. Third-party patience: 2+ enemies + target fighting
  someone else → wait 2s. Feeds -0.25/-0.15 into aggression score.
- Enhancement: **Match phase detection** (`bot_ai.qc`, `botgoal.qc`).
  `BotUpdateMatchPhase()` detects SCRAMBLE/CONTROL/ENDGAME from total/max frags vs
  fraglimit. Item weight modulation: +20 weapons (early), +15 armor (mid), +30
  powerups (late). Aggression boost in SCRAMBLE, lead-dependent in ENDGAME.
- Enhancement: **Weapon sound inference** (`botnoise.qc`, `bot_ai.qc`).
  `heard_sound_weapon` stored on NOISE_WEAPON events. Handler classifies: RL heard +
  weak → cautious (priority 30), weak weapon + strong → push (priority 90).
- Enhancement: **Adaptive engagement distance** (`bot_ai.qc`). Optimal range modulated
  by enemy weapon (+100u vs LG, -80u vs RL, +60u vs SSG, -100u vs weak) and aggression
  score. Clamped 100-800u, skill 2+. Strafe evasiveness increases when aggression is low.
- Enhancement: **Bunny hop rhythm variance** (`botmove.qc`). Variable hop timing
  (0.28-0.50s), strafe angle (10-22deg), and accel (30-50 ground, 8-16 air). All
  skill-scaled: higher skill = tighter variance toward optimal values.
- Enhancement: **Velocity momentum blending** (`botmove.qc`). Direction changes
  lerp over 2-3 frames via `blend_rate = 0.6 + skill*0.03` (cap 0.85) instead of
  instant velocity snapping. Creates human-like momentum on turns.
- Enhancement: **S-curve turn acceleration** (`botmove.qc`). Hermite smoothstep
  (`3t^2 - 2t^3`) added to `BotClampYaw` for ease-in-out "whip and settle" turn
  profile. Small residual angles decelerate, large angles ramp up.
- Enhancement: **Graduated edge friction** (`botmove.qc`). Two-tier braking in
  `BotApplyEdgeFriction`: far (64u) = 0.92 gentle brake, near (32u) = 0.70 heavy
  brake. Replaces single binary 32u check.
- Enhancement: **Platform fidgeting** (`botmove.qc`). Micro-drift (±10u/s) and 5%
  look-around while riding lifts in `BotCheckPlatformRide`. Replaces motionless
  standing.
- Enhancement: **Roaming speed variation** (`bot_ai.qc`). Variable 180-240 speed,
  0.7x corner slowdown, and 2% micro-pauses in `BotRoam`. Replaces fixed 200 speed.
- Enhancement: **Swimming clumsiness** (`botmove.qc`). Triangle-wave pitch wobble
  (±(8-skill) deg, ~2s period) and sluggish velocity blend (0.4+skill*0.04, cap
  0.75) in `BotSwim`. Replaces instant velocity assignment.
- Simplification: **Removed Apex HPA\*** (`ai_apex.qc` deleted, forward declarations and
  calls removed from `world.qc`, entry removed from `progs.src`). Vortex A* handles all
  maps without a second abstraction layer.
- Simplification: **Mirage Minds** stripped of persona system (5 personas, persona switching,
  heat maps, micro-goals, `Mirage_AddHeat`). Now entropy-only: mood drift, yaw jitter,
  pitch jitter, glance-aways, and hold-fire feints. Removed forward declarations and
  call sites from `items.qc` and `client.qc`.
- Simplification: **Ripple Oracles** stripped of MCTS tree search (`Ripple_MaelstromMCTS`
  removed). Now uses heuristic trace probes with flat beam-search fallback
  (`Ripple_MaelstromSim`). Same cascade fusion, far less code and globals.
- Simplification: **Slayer Eclipse** cleaned up. Removed hardcoded username checks
  (`slywall`/`Shane`) from `Slayer_IsUser()`. `user_learn` cvar now applies to any
  connected player.
- Navigation fix: **Distance-weighted goal selection** (`botgoal.qc`). Closer items
  score up to +20 bonus in `aibot_chooseGoal`. Was pure weight comparison with no
  distance factor, causing bots to ignore nearby items.
- Navigation fix: **Doubled search radius** (`botit_th.qc`). `SEARCH_RADIUS` increased
  from 600 to 1200 units. Bots detect items much further away.
- Navigation fix: **Goal-aware bunny hop** (`botmove.qc`). No-enemy hopping now gated
  by `vlen(goalentity.origin - self.origin) > 600`. Prevents chaotic bouncing when
  closing in on items.
- Enhancement: **Strafe timing jitter** (`bot_ai.qc`). Strafe flip threshold multiplied
  by `0.75 + random() * 0.50` each cycle for ±25% variation. Was fixed, learnable rhythm.
- Enhancement: **Weapon distance scoring** (`botfight.qc`). RL penalized at long range
  (-10 at >500u, -25 at >800u). SNG gets +15 bonus at mid range (300-700u). Bots show
  weapon variety instead of always picking RL.
- Enhancement: **Splash risk override** (`botfight.qc`). Bots keep RL/GL at close range
  when enemy health < 30 or bot has IT_INVULNERABILITY. Was always swapping to safe weapon.
- Enhancement: **Target switching momentum** (`bot_ai.qc`). New targets must beat current
  enemy distance by 150u. Near-dead enemies (<20 effective HP) get 300u extra loyalty.
  Bots commit to kills instead of ADHD flipping.
- Enhancement: **State-dependent hysteresis** (`bot_ai.qc`). RETREAT locks 1.5s, GOODY
  0.8s, ATTACK 1.0s. Was flat 0.5s for GOODY/RETREAT only. ATTACK hysteresis prevents
  retreat-flipping mid-fight.
- Enhancement: **Effective HP health weight** (`botit_th.qc`). `healthweight` urgency
  now requires `self.health < 60 && eff < 100` (eff = health + armor * armortype).
  Armored bots fight instead of chasing health packs.
- Enhancement: **Ammo urgency** (`botit_th.qc`). `rocketweight` boosts to MUST_HAVE-1
  when bot has RL and <5 rockets. `cellweight` same for LG and <10 cells.
- Enhancement: **Retreat strafing** (`bot_ai.qc`). `ai_botretreat` zigzags at ±30°
  offsets using STRAFE_DIR alternation with 0.4-0.6s flip timing. Was straight backpedal.
- Enhancement: **Goal commitment time** (`botgoal.qc`). `search_time` reduced from
  `time + 4.0` to `time + 2.5`. Bots re-evaluate goals 60% faster.
- Enhancement: **Skill-scaled turn speed** (`botmove.qc`). `BotClampYaw` max turn
  scales from 18°/frame (skill 0) to 30°/frame (skill 10) via
  `BOT_MAX_TURN_SPEED + skil * 1.2`. Was flat 18° for all skills.
- Enhancement: **Quad hyper-aggression** (`bot_ai.qc`). Quad holders retreat only
  below 25 eff HP (was 50) and skip gradual retreat entirely. Pushes aggressively
  during Quad.
- Enhancement: **Enemy Quad caution** (`bot_ai.qc`). Bots with <80 eff HP flee
  enemy Quad even with good weapons. Only tanky bots stand and fight 4x damage.
- Enhancement: **Fast-kill hitscan boost** (`botfight.qc`). When enemy health <25,
  bots switch from RL/GL to LG or SNG for reliable finishing.
- Enhancement: **Weapon-range engagement** (`bot_ai.qc`). Bots drift toward optimal
  distance for current weapon (LG: 250u, SNG: 350u, RL: 500u, SSG: 200u) with
  30%-strength pre-step before strafing.
- Enhancement: **Score pressure adaptation** (`bot_ai.qc`). Losing bots (-5 frags)
  halve retreat probability. Winning bots (+5 frags) increase retreat by 30%.
- Enhancement: **Velocity-based stuck guard** (`botgoal.qc`). Stuck detection now
  requires low position delta AND low velocity (<100). Eliminates false triggers
  during jumps, lifts, and swimming.
- Enhancement: **Skill-scaled search timeout** (`botgoal.qc`). Goal lock time scales
  from 3.5s (skill 0) to 1.5s (skill 10) via `1.5 + (10 - skil) * 0.2`.
- Enhancement: **Speed-scaled whisker distance** (`botmove.qc`). Obstacle lookahead
  uses actual velocity instead of walkmove input: `50 + vlen(velocity) * 0.125`.
- Enhancement: **Effective HP armor weight** (`botit_th.qc`). `armorweight` uses
  effective HP (value * type) derived from classname. Red armor correctly beats
  green. Low-health bots get +20 armor urgency.
- Enhancement: **Ambush weapon safety** (`bot_ai.qc`). Nervous trigger pre-fire
  suppressed for RL/GL at close range (<200u). Prevents splash suicide during ambush.
- Enhancement: **Exponential aim jitter** (`botfight.qc`). Replaced linear
  `(3 - sk) * 0.15` with `((5 - sk)^2) * 0.012`. Skill 0 = ~30 deg, skill 3 = ~5 deg,
  skill 5+ = 0. Also adds Z-axis (pitch) jitter at 60% of horizontal.
- Enhancement: **Reaction fire delay** (`bot_ai.qc`). When promoting `pending_enemy` to
  `enemy`, sets `attack_finished = time + (0.300 - skil * 0.075)`. Skill 0 = 300ms delay,
  skill 4+ = instant. Previously only gated *seeing* the enemy, not firing.
- Enhancement: **Non-linear shadow depth** (`botspawn.qc`). Changed from
  `6 + floor(skill)` to `3 + floor(skill^2 * 0.13)`. Skill 0 = 3, skill 5 = 6,
  skill 10 = 16. Shadow beam similarly rescaled.
- Enhancement: **Gradual retreat** (`bot_ai.qc`). Replaced hard `health < 15` cutoff with
  probability curve: `eff_hp = health + armor * armortype`, retreat chance =
  `(60 - eff_hp) / 60`. At 60 HP: 0% retreat, at 30: 50%, at 0: 100%.
- Enhancement: **Ambush armor awareness** (`bot_ai.qc`). Threshold now uses effective HP
  (50) instead of raw health (40). Timeout scales by skill: `2.0 + skil * 0.3` (2-5s).
- Enhancement: **Adaptive strafe timing** (`bot_ai.qc`). Strafe direction switch threshold
  changed from fixed 0.4s to `0.3 + skil * 0.04` (0.3-0.7s). High-skill bots hold good
  directions longer.
- Enhancement: **Multi-axis MirageTick** (`ai_mirage.qc`). Added pitch jitter (vertical
  drift when entropy > 0.4), glance-aways (skill 3+ briefly look off-target, 3% chance),
  and variable hold-fire duration (0.2-0.3s instead of fixed 0.25s). New fields:
  `mirage_pitch_bias`, `mirage_glance_time`.
- Enhancement: **Mirage pitch bias** (`botfight.qc`). Pitch bias from MirageTick applied
  to aim direction as `pitch_bias * 0.010 * '0 0 1'` for vertical tracking imperfection.
- Enhancement: **Ammo-aware weapon switching** (`botfight.qc`). Before splash safety
  checks, switches weapon when ammo is critically low: RL/GL <= 1 rocket, LG <= 5 cells,
  SNG <= 5 nails. Prevents firing until empty.
- Enhancement: **Combat bunny hopping** (`botmove.qc`). No enemy → always hop.
  Enemy > 400u → always hop. Skill 4+, enemy > 200u, retreating (RUNAWAY flag) → hop.
  Previously disabled all hopping when any enemy was within 200u.
- Enhancement: **Blind fire memory** (`botfight.qc`). Tracks consecutive missed pre-fires
  via `blind_fire_miss` and `blind_fire_spot` fields. After 2 misses at the same spot
  (within 100u), blacklists it for 10s. Resets to 0 when enemy becomes visible again.
- Enhancement: **GETGOODY threat abort** (`bot_ai.qc`). When grabbing items, aborts if
  enemy is visible, within 400u, and bot health < 40. Calls `ai_endgetGoody` to
  resume combat.
- Enhancement: **Vortex slime avoidance** (`ai_vortex.qc`). Added `CONTENT_SLIME` to
  navmesh edge hazard checks alongside `CONTENT_LAVA`, `CONTENT_SOLID`, `CONTENT_SKY`.
- Enhancement: **Specter drama enhancement** (`ai_specter.qc`). Low-health duels
  (health < 30 + has enemy) add +6 drama. Recent combat (attack state within 2s) adds
  +4 drama. Improves camera focus on dramatic moments.
- Enhancement: **Skill-scaled RJ depth** (`ai_ripple.qc`). Rocket jump beam simulation
  steps changed from fixed 8 to `6 + floor(skil * 0.6)` (6 at skill 0, 12 at skill 10).
- Enhancement: **Powerup spawn timing** (`botgoal.qc`). Skill 3+ bots anticipate items
  about to respawn within 10s window. Powerups (Quad/Pent) get up to MUST_HAVE weight,
  regular items get KINDA_WANT, linearly scaled by time remaining.
- Enhancement: **Threat-scored targeting** (`bot_ai.qc`). Target selection now considers
  weapon danger and facing angle. Enemies aiming at the bot (dot > 0.7) get -100 distance
  bonus. RL/LG wielders get -80, SNG gets -40.
- Enhancement: **Circle strafing** (`bot_ai.qc`). Skill 5+ bots orbit at 60-75° (tight
  flanking), skill 3-4 at 75-85° (slight tightening), skill 0-2 unchanged at 90°.
- Enhancement: **Retreat toward safety** (`bot_ai.qc`). Retreating bots scan findradius(600)
  for health/armor items and blend 40% toward the nearest one instead of running blindly.
- Enhancement: **Elevation preference** (`bot_ai.qc`). Skill 2+ bots trace downward from
  left/right strafe positions and bias toward higher ground (16u threshold, 2 traces/frame).
- Enhancement: **Engagement commitment** (`bot_ai.qc`, `botit_th.qc`). ATTACK hysteresis
  scales with fight duration: `1.0 + dmg_dealt * 0.5`, capped at 3.0s. Bots in prolonged
  fights commit harder instead of switching targets.
- Enhancement: **Post-kill scavenge** (`bot_ai.qc`). After killing an enemy, bots spend
  2s scanning for nearby items (backpacks, health) within 300u before resuming normal goals.
- Performance: **Traceline stagger** (`botmove.qc`). BotSteer alternates left/right whiskers
  each frame using `self.lefty` bit. Saves ~8 traces per server frame across 8 bots.
- Enhancement: **Ambush jump suppression** (`botmove.qc`). Bots in AI_STATE_AMBUSH no longer
  jump, preventing position giveaway during ambush setups.
- Tuning: **Skill-gated bunny hop** (`botmove.qc`). Roaming hop requires skill 5+ (was all
  skills). Far-combat hop (enemy >400u) requires skill 3+ (was all skills). Mid-range retreat
  hop unchanged at skill 4+. Low-skill bots now walk like normal players.
- Feature: **Specter Gaze** cinematic spectator camera (`ai_specter.qc`, `client.qc`,
  `botit_th.qc`, `defs.qc`). Two-layer architecture: Think (50-200ms) computes ideal
  camera positions via orbital + velocity prediction; ViewUpdate (every server frame
  ~72fps) interpolates with frame-rate-independent damping and geometry-based angles.
  Drama-driven auto-switching (5+ point differential, 5s boredom timeout, 1.5s cooldown).
  Chase mode via `specter_chase` cvar. Toggle: `impulse 105`, cycle: `impulse 106`.
- Fixed: Specter camera entities missing `setmodel` (engine skips entities without
  `modelindex`), missing `setorigin` (stale BSP area links), and player PVS not
  relocated to camera position.
- Fixed: Specter `SVC_SETANGLE` only sent on focus change — player mouse overrode view
  angles between updates. Moved to per-frame `PlayerPreThink` hook (same pattern as CCam).
- Fixed: `botgoal.qc:pathweight` computed distance to world origin `'0 0 0'` instead of
  target entity (missing `org = e.origin`).
- Fixed: `botgoal.qc:RunAwayWeight` used uninitialised `weight` when enemy had clear LOS
  to escape route (added `weight = 0` default).
- Fixed: `client.qc:ClientObituary` could print garbage death messages for unknown weapon
  types (added fallback `" was killed by "` strings).
- Build: Enabled `-Wall -Wno-mundane` in default FTEQCC flags. Reduced warnings from
  43 to 35 after fixing 3 real bugs (remaining are false positives from guarded branches).
- Feature: Phantom Apprenticeship / Spectral Learning (`bot_learn.qc`, `bot_ai.qc`,
  `botroute.qc`, `defs.qc`). Bots shadow players with low-cost phantoms:
  - Spectral episodes capture short maneuver segments (jump/tele/swim/walk).
  - Ethereal rollouts validate episodes using ShadowSimStep/ShadowReward.
  - A* cost bias uses soft allure with decay (no hard locks or teleport shortcuts).
  - Impulse 104 prints episode count for quick debugging.
- Feature: Mirage Minds humanization layer (`ai_mirage.qc`, `bot_ai.qc`, `botmove.qc`,
  `botfight.qc`, `defs.qc`). Adds entropy-driven yaw/pitch jitter, glance-aways, and
  feint pauses without overriding core AI.
- Feature: Silent Specters unstuck rollouts (`ai_predict.qc`, `botgoal.qc`,
  `botmove.qc`). Quiet 12-action beam search for unsticking with enemy-aware
  jump penalties; fallback ladder prefers strafe/pause and keeps jumps rare.
- Feature: Cursed Nodes adaptive stuck-learning mesh (`ai_mirage.qc`, `botgoal.qc`,
  `ai_predict.qc`, `botroute.qc`, `world.qc`). Quantized grid penalties decay over
  time and bias both rollouts and route cost away from repeated stuck zones.
- Feature: **Vortex Navmesh** (`ai_vortex.qc`, `bot_learn.qc`, `botgoal.qc`,
  `world.qc`, `defs.qc`). Incremental dynamic mesh seeded from spawns/items with
  phantom-validated edges, cursed/glory-biased costs, and decay culling (no pre-bake).
- Feature: **Vortex Telechains** (`ai_vortex.qc`, `bot_learn.qc`).
  Detects teleporter warps (>500u), fuses one-way quantum edges between entry/exit
  nodes, and allows chain-limited low-cost tele routing. Hazard exits are cursed;
  strong exits gain usage/glory boosts.
- Feature: **Lift Routing** (`ai_vortex.qc`, `ai_predict.qc`, `botmove.qc`,
  `bot_learn.qc`). Samples lift nodes (func_plat/func_train), adds ETA-based
  wait-cost biasing in Vortex A*, rewards lift rides (upward bias) in rollouts,
  syncs approach speed to lift phases, and refines lift phase timing from
  successful rides.
- Feature: **Ripple Oracles** (`ai_ripple.qc`, `ai_vortex.qc`, `botmove.qc`,
  `bot_learn.qc`, `defs.qc`). When LOS to a goal is blocked, probes nearby
  interactables (buttons/doors/plats), runs heuristic trace probes with beam-search
  fallback to simulate shoot/touch/wait cascades, and fuses ripple edges into Vortex
  with explicit interact positions. Decays deep, unused ripple edges.
- Removed: Legacy episodic learning (golden locks, teleport shortcuts, LOS shortcutting, trail rewards).
- Removed: Broken map-control timing rushes (auto-drop BotPath at powerup spawns,
  spawn-time beelines, and hard lock boosts).
- Updated: Shadow Puppets Nexus (shared nav/combat throttle, cvar gates, per-bot beam/depth overrides, spectral reward bias).
- Feature: Slayer Eclipse combat escalation (`ai_predict.qc`, `botfight.qc`, `bot_ai.qc`,
  `bot_learn.qc`, `botspawn.qc`, `botit_th.qc`). Adds 20-wide combat beams,
  Monte Carlo lead, per-user strafe bias learning + dodge biasing, rival powerup
  ETA rush, and god-mode toggles (`sv_slayer_god`, `mc_samples`, `user_learn`).
- Feature: Smooth steering anti-jitter (`botmove.qc`, `defs.qc`). Bots now average
  steering decisions over 3 frames (0.3s at 10Hz) to prevent oscillation between
  pathfinder and whisker steering. `BotSmoothSteer()` uses a circular buffer with
  `BotAverageAngles()` helper that properly handles 0/360 wraparound via vector
  addition. Turn speed clamped to 15°/frame for smooth curves.
- Feature: Sixth Sense item awareness (`bot_ai.qc`). Bots now have 360-degree
  awareness for items within 300 units - they "sense" nearby items even when not
  looking at them. Uses `traceline()` for LOS check instead of `infrontofbot()`.
  Items detected via sixth sense get a proximity weight boost (closer = more
  attractive). Items beyond 300 units still require standard forward-facing vision.
- Feature: Auditory inference system (`botnoise.qc`, `bot_ai.qc`, `client.qc`,
  `items.qc`, `defs.qc`). Bots hear item pickups, water splashes, and footsteps
  with simple occlusion and react to the sound type.
- Feature: High-value item focus (`botmove.qc`). When within 200 units of a powerup
  or major weapon (RL, LG, Quad, Pent, Mega Health, Red Armor), bots enter "direct
  drive" mode - they stop complex steering and walk straight toward the item. This
  prevents bots from strafing past valuable items due to whisker deflection.
- Improved: Reduced INVESTIGATING log spam (`bot_ai.qc`). Sound investigation logging
  now only fires on first frame of investigation instead of continuously.
- Feature: Mastermind Update - Tactical Intelligence (`botfight.qc`, `bot_ai.qc`,
  `defs.qc`, `botspawn.qc`, `botit_th.qc`). Three "proactive" combat behaviors:
  - **Pre-Fire (Corner Suppression)**: `BotBlindFire()` shoots rockets/grenades at
    corners where enemy just disappeared. Uses `BotPredictPosition()` to estimate
    where target went based on last velocity. Creates "did I just see that?" moments.
  - **The Trap (Ambush)**: When low health (<40) and being chased but lost sight,
    bot stops running, switches to SSG/RL, aims at entry point, and waits. Nervous
    trigger pre-fires when enemy is close. 4-second timeout prevents camping forever.
  - **Displacement Kill**: `BotCheckEnvironmentKill()` detects hazards (lava/slime)
    behind the enemy and aims at their feet to knock them backward into danger.
  - Tracks enemy velocity (`last_enemy_vel`) for prediction when line of sight breaks
  - New AI state `AI_STATE_AMBUSH` for trap behavior tracking
  - Developer logging: PREFIRE, AMBUSH, DISPLACEMENT tags
- Feature: Darwin Update - Adaptive Reinforcement Learning (`botroute.qc`, `client.qc`,
  `botfight.qc`, `botgoal.qc`, `defs.qc`). Bots learn from their own experience:
  - **Natural Selection**: Deaths mark nearby nodes as dangerous (+500 danger_cost),
    kills mark nodes as glorious (+10 glory_level). `ModulateNodeWeight()` handles
    both positive and negative reinforcement.
  - **Danger Avoidance**: A* pathfinding adds danger_cost to path distances, making
    bots naturally avoid recent death locations.
  - **Glory Seeking**: Nodes with glory reduce path cost by up to 30%, attracting
    bots to proven kill zones.
  - **Weapon Specialization**: Bots track confidence (-10 to +10) for RL, LG, GL,
    and SG/SSG. Kills boost confidence (+1), deaths reduce it (-1). `W_BestBotWeapon()`
    now uses scoring with confidence multipliers.
  - **Stuck Learning**: Navigation failures (2+ seconds stuck) mark nodes as difficult
    (-100 danger). Bots eventually try alternate routes.
  - **Decay System**: In `MaintainGraph()`, danger decays fast (×0.8) for courage,
    glory decays slow (×0.9) for nostalgia. Prevents permanent map "scars".
  - Developer logging: DARWIN tags for node weight changes, weapon confidence updates
- Feature: Platform riding for func_train (`botmove.qc`). Bots now properly ride
  horizontal moving platforms (like DM2 lava room) by inheriting platform velocity.
  Added `BotCheckPlatformRide()` function that detects MOVETYPE_PUSH entities and
  prevents sliding off while platforms are moving.
- Feature: Platform wait logic (`botmove.qc`). When lava/slime is ahead, bots now
  scan for approaching func_train entities and wait for them instead of refusing
  to move. Uses `platform_wait_time` field for 3-second timeout.
- Feature: Intelligent button interaction (`botmove.qc`, `botgoal.qc`). Bots can
  now find and activate buttons that trigger blocked doors:
  - `BotFindButton()` searches for func_button entities whose target matches the
    door's targetname
  - `BotSolveDoor()` sets up button as the new goal with SOLVE_BUTTON flag
  - `BotHandleButton()` shoots buttons with health > 0 or walks to touch-triggered
    buttons
  - Integrates into door collision handling to detect doors needing external triggers
- Added: Reaction time simulation (`bot_ai.qc`, `botgoal.qc`). Bots now have a
  skill-based delay before engaging newly-spotted enemies. Skill 0 = 200ms delay,
  Skill 3 = 50ms, Skill 4+ = instant. Makes low-skill bots feel more human-like
  when surprised.
- Added: Object permanence (`bot_ai.qc`, `botfight.qc`). When line of sight breaks,
  bots continue firing at the last known position for a skill-based duration
  (Skill 0 = 0.5s, Skill 4 = 1.5s). Prevents robotic instant-stop behavior when
  target crosses a doorframe.
- Feature: Humanized idle behavior (`bot_ai.qc`). Bots no longer freeze when idle.
  New `BotRoam()` function makes them wander, look around, and scavenge nearby
  items. Replaces empty `ai_botstand` and turret-like `ai_botturn` behaviors.
- Improved: Movement smoothing (`botmove.qc`). Added Z-axis "ground glue" to prevent
  floaty jitter on ramps/stairs. Zero velocity on collision prevents client-side
  prediction sliding into walls.
- Feature: Sensor fusion steering V2 (`botmove.qc`, `bot_ai.qc`). Bots now use vector-
  based steering instead of reactive if/else collision handling:
  - `BotDetectHazard()` looks ahead for cliffs, lava, slime, and sky brushes
    (explicitly ignores water so bots can wade through shallow pools)
  - `BotIsStep()` helper checks if obstacles are low enough to step over (<22 units),
    preventing bots from treating water lips and stairs as walls
  - `BotSteer()` casts 3 whisker rays (center, left-45°, right-45°) and calculates
    force vectors: goal attraction + wall repulsion + hazard repulsion
  - Forces are summed and normalized for mathematically smooth curves around corners
  - Visual turn smoothing updates bot facing when steering differs from intention
  - "Stuck Doctor" routine attempts jump when blocked by low obstacles
  - `BotRoam()` now uses sensor fusion for fluid idle wandering
- Feature: Humanized physics system (`botmove.qc`, `defs.qc`). Inspired by FrikBot
  and Frogbot techniques, adds five improvements for more realistic bot movement:
  - **Turn speed limiting**: `BotClampYaw()` caps angular velocity at 180 deg/sec
    (18 deg/frame). Bots can no longer instantly snap to new directions - they
    smoothly rotate like human players. Uses `last_yaw` field for delta tracking.
  - **Mid-air steering**: `BotAirSteer()` allows limited course corrections while
    airborne during knockback recovery. When `knockback_time` is active and bot is
    flying, applies up to 30 units/frame of air acceleration toward desired direction.
    Lets bots recover/redirect after being rocketed instead of being helpless.
  - **Air acceleration limiting**: All air acceleration capped at 30 units/frame,
    matching QuakeWorld client physics. Prevents unrealistic instant direction
    changes while airborne.
  - **Edge friction**: `BotApplyEdgeFriction()` applies 0.7x friction multiplier
    when ground trace fails 32 units ahead, detecting ledges/dropoffs. Prevents
    bots from sliding off edges at high speed - they slow down before the drop.
  - **Velocity decomposition**: `BotDecomposeVelocity()` stores wall normal on
    collision via `obstruction_normal` field, then projects velocity onto wall
    plane to calculate sliding direction. Bots now slide along walls instead of
    stopping dead, reducing stuck states.
- Feature: Velocity-based 3D swimming (`botmove.qc`, `bot_ai.qc`). When submerged
  (waterlevel >= 2), bots drive velocity in 3D with pitch steering and wall sliding.
  Oxygen-aware surfacing overrides combat and item foraging when air is low.
- Feature: Feeler steering + breadcrumbs (`botmove.qc`, `botroute.qc`, `botgoal.qc`,
  `defs.qc`). When stuck, bots enter feeler mode to scan 8 directions for the
  clearest exit and drop `BotPath` breadcrumbs every ~48 units for future routing.
- Feature: Navigation learning + link types (`botroute.qc`, `client.qc`,
  `items.qc`, `defs.qc`, `botmove.qc`, `world.qc`). Players auto-drop/attach
  waypoints with link types (walk/jump/drop/platform/rocket jump), link usage
  weighting biases A* routing, danger scents steer bots away from lethal nodes,
  and graph decay lets paths be forgotten over time.
- Feature: Teacher Mode debugging (`weapons.qc`). `impulse 102` shows `BotPath`
  nodes with bubble sprites/particles; `impulse 103` hides them; `impulse 104`
  prints spectral episode count.
- Feature: Mandatory action nodes for buttons (`buttons.qc`, `botroute.qc`). Player
  button presses mark the nearest waypoint as mandatory for a short window so bots
  don't skip required detours (e.g., DM2 gate button).
- Feature: Speed Demon update (`botmove.qc`, `botfight.qc`, `bot_ai.qc`). Adds
  bunny hopping on straight runs and reflex dodging of incoming rockets/grenades.
- Fixed: Bots getting stuck on shallow water pool edges (`botmove.qc`). The whisker
  collision sensors were detecting small lips (8-16 units) as walls and steering bots
  away, trapping them on "islands". Added `BotIsStep()` to check if obstacles are
  climbable, allowing `walkmove()` to naturally step over them.
- Fixed: Death animation ending with bot standing holding axe (`dmbot.qc`).
  The `BotDead()` function was resetting `self.frame = 0` before `CopyToBodyQue()`
  copied the corpse, causing dead bots to display standing frame instead of death
  pose. Removed the frame reset - corpses now correctly retain their death animation
  frame. Frame functions reverted to original `[ frame, next ]` syntax.
- Improved: Consistent think timing (`botthink.qc`). `BotPostThink` enforces minimum
  0.1s think interval to match velocity calculations (dist * 10), eliminating
  network interpolation "judder" from variable frame rates.
- Fixed: Bots not pushed by rockets/explosions (`botmove.qc`, `combat.qc`). The
  bot movement code was overwriting knockback velocity every frame. Added
  `knockback_time` tracking so bots respect knockback physics for 0.3s after
  being hit.
- Community issue list in `mre/COMMUNITY_ISSUES.md`.
- Fixed: Edict overflow crash in single player (`botroute.qc`). The bot's dynamic
  waypoint system (NUMPATHS) was capped at 140, which works in deathmatch but
  exhausts the ~600 edict limit in SP maps that already have 400-500 entities.
  Added a 50-waypoint cap when `deathmatch == 0`.
- Fixed: Multiplayer lockups from exponential route caching (`botroute.qc`). The
  `cacheRouteTarget` recursion with 6 neighbors per node and depth 12 could cause
  6^12 operations. Added cycle detection via `visited_id` field to visit each node
  only once per search.
- Fixed: Crash from graph decay writing to world entity (`botroute.qc`). Moved the
  decay throttle to a global `graph_decay_next` timer.
- Fixed: Reflex dodge not triggering on rockets (`weapons.qc`, `botfight.qc`). Rockets
  now set `classname = "missile"` and dodge checks also fall back to the rocket model.
- Fixed: Potential infinite loop in jump simulation (`botmove.qc`). The
  `Bot_tryjump` while loop could hang if simulating a fall into void where
  traceline never hits ground. Added safety counter (100 iterations max).
- Fixed: Scoreboard overflow crash (`client.qc`, `botspawn.qc`). The `FindGood()`
  function returned 1-indexed slots (1-16) but protocol expects 0-indexed (0-15).
- Fixed: Bots "stealing" powerups from players at spawn points (`botmove.qc`). The
  high-value item Focus (Direct drive) code was walking bots into item spawn locations
  even when the item hadn't respawned yet. When the item respawned, the actively-moving
  bot triggered touch before the stationary player. Added `solid == SOLID_TRIGGER` check
  to only Direct drive when the item actually exists.
- Fixed: Powerups could be picked through walls/adjacent rooms (`items.qc`). Added
  a line-of-sight check to `powerup_touch` so items only grant on clear trace.
  Changed to 0-indexed and added guard to check slot < fMaxClients (maxplayers).
- Fixed: Jumpy/teleport-like strafing (`botmove.qc`). Removed `halfwalkmove` which
  caused 0.05s sub-frame updates that confused client interpolation. Added velocity
  setting after `walkmove` calls so clients can predict motion smoothly.
- Fixed: "Flashing" bots near water (`botmove.qc`). Added stricter checks to
  `teleptest` for headroom and floor footing before allowing water teleportation.
- Fixed: Bots getting stuck running in place (`botgoal.qc`). Improved stuck
  detection with time-based tracking via `stuck_time` field. Raised movement
  threshold from 1.0 to 3.0 units to catch subtle stuck states. After 1.5 seconds
  stuck, forces immediate goal change. Increased jump attempt chance from 10% to
  20%. Added developer-only STUCK logging.
- Fixed: Camper behavior near best weapons (`botgoal.qc`). Modified `itemweight` to
  ignore weapons the bot already owns when ammo is sufficient (>50 nails/cells,
  >10 rockets).
- Fixed: Suicidal rocket/grenade firing (`botfight.qc`). Added safety check in
  `W_BotAttack` to switch weapons when enemy is within 150 units instead of
  firing explosives at point-blank range.
- Fixed: Thunderbolt water discharge suicide (`botfight.qc`). Added safety check
  to switch weapons when in water (waterlevel >= 2) instead of instant-death
  discharge.
- Improved: Range-based weapon selection (`botfight.qc`). Rewrote `W_BestBotWeapon`
  and `W_BestHeldWeapon` with comprehensive range-aware logic:
  - Close quarters (< 150 units): Prioritizes SNG > SSG > LG > NG > SG to avoid
    splash damage suicide. Explosives only allowed with Quad (4x damage is worth
    the risk). Falls back to Axe if truly desperate.
  - Standard range (>= 150 units): LG at close-mid range > RL (now safe) > SNG >
    GL (mid-range only, < 600 units) > SSG > NG > SG.
  - Long range (> 500 units): Prefers nails over shotguns due to spread falloff.
  - Bots now actively switch TO better weapons instead of just refusing to fire.
- Improved: Predictive aiming (`botfight.qc`). Added 0.5 second cap on lead time
  in `leadtarget` to prevent excessive over-leading at long range while keeping
  accurate prediction at mid-range.
- Fixed: Bots walking into lava/slime (`botmove.qc`). Added hazard avoidance in
  `botwalkmove` that checks floor contents ahead of movement. Bots now refuse to
  walk into CONTENT_LAVA or CONTENT_SLIME unless protected by Pentagram (any) or
  Biosuit (slime only).
- Fixed: Bots walking off lifts mid-ride (`botmove.qc`). Added platform state
  detection in `botwalkmove` that checks if bot is standing on a func_plat. Bot
  now waits when platform is STATE_UP, STATE_TOP, or STATE_BOTTOM instead of
  walking off.
- Fixed: Bots stuck at closed doors (`botmove.qc`). When walkmove fails, traces
  forward to detect func_door entities. If found, triggers the door's use function
  and backs up to let it open.
- Fixed: Bots ganging up on human players (`bot_ai.qc`). Rewrote `BotFindTarget`
  to iterate through ALL potential targets (both "player" and "dmbot" entities)
  and pick the closest visible one. Previously used `checkclient()` which always
  returned human players first due to entity slot ordering (humans occupy slots
  1-16 before bots). Added `BotValidTarget` helper function for target validation.
- Fixed: "Vacuum pickup" appearance (`botsignl.qc`). Added 48-unit distance check
  in `t_botmovetarget` before completing item goals. Previously the BotTarget
  trigger could fire when bot was still far from the actual item, making items
  appear to vanish before the bot reached them.
- Investigated: "Extra SNG ammo" complaint. Searched all weapon pickup, spawn, and
  firing code - no bot-specific ammo bonus exists in this baseline. Bots use
  `SetNewParms()` like players and consume 2 nails/shot via `W_FireSuperSpikes`.
  Marked as "Not Found in Baseline" in COMMUNITY_ISSUES.md.
- Investigated: "Firing faster than humanly possible" complaint. Compared all
  attack_finished timings between W_BotAttack (`botfight.qc`) and W_Attack
  (`weapons.qc`). Bots use identical delays (0.5s SG, 0.7s SSG, 0.6s GL, 0.8s RL,
  0.1s loop for nails/LG). Low-skill bots add `addt` delay making them SLOWER.
  Marked as "Not Found" in COMMUNITY_ISSUES.md.
- Fixed: Low-skill bots felt like cheaters with near-perfect aim (`botfight.qc`).
  Increased skill-based aim jitter in `botaim()` from 0.06 to 0.15 per skill level
  below 3 (max ~25° error at skill 0 vs ~10° before). Added Z-axis (vertical) aim
  error at 0.10 per skill level. Skill 0 bots now miss noticeably more often.
- Fixed: Bots attacking observers/spectators (`bot_ai.qc`). Added `MOVETYPE_NOCLIP`
  and `deadflag` checks to `BotValidTarget()`. Bots now ignore players in spectator
  mode (noclip) and players who are dead/dying, preventing attacks on invulnerable
  observers.
- Fixed: Bots not affected by explosion knockback (`botmove.qc`). Added check at
  start of `botwalkmove()` to preserve velocity when bot is airborne with speed >350.
  Bots can now be "bounced" by rockets and perform rocket jumps correctly.
- Fixed: Backpacks spawning in unreachable locations (`items.qc`). Added
  `CONTENT_SOLID`/`CONTENT_SKY` check in `DropBackpack()`. If spawn position is
  inside a wall or void, tries player origin; if that fails, skips backpack entirely.
- Fixed: Zero-velocity knockback causing stuck/jittery bots (`combat.qc`). Added
  velocity threshold check (> 50 units/sec) before BOTH entering `MOVETYPE_BOUNCE`
  AND resetting `knockback_time`. Previously, zero-velocity hits would reset the
  recovery timer, preventing bots from exiting bounce mode. Bots could become
  stuck in place with jittery/teleport-like movement when hit repeatedly.
- Improved: KNOCKBACK log now filters low-velocity entries (`botthink.qc`). Only
  logs when velocity > 50 units/sec to eliminate zero-velocity noise. Added 0.05s
  debounce via `knockback_log_time` field to prevent duplicate entries from
  multi-projectile hits in the same frame. Reset on spawn in `botspawn.qc`.
- Fixed: GOODY/RETREAT AI oscillation (`bot_ai.qc`). Added 0.5s hysteresis to
  prevent rapid state flipping. When bot is in GOODY or RETREAT state, it stays
  there for minimum 0.5s before re-evaluating. Added `last_ai_state_time` field
  to `defs.qc` to track state change timing.
- Fixed: Stale knockback/AI state after respawn (`botspawn.qc`). Reset
  `knockback_time`, `last_ai_state`, and `last_ai_state_time` to zero in
  `PutBotInServer()` to prevent values from previous life affecting new spawn.
- Fixed: Bots quitting mid-match (`botspawn.qc`). Respawn logic no longer removes
  bots for crowding or poor performance; they rejoin instead of leaving.
- Reverted: Frame reset in `BotDead()` removed - it caused zombie axe corpses.
  The `walkframe` reset in `PutBotInServer()` remains. Frame errors on `h_player.mdl`
  (gibbed head model) are a cosmetic issue that doesn't affect gameplay.
- Fixed: sv_aim warning spam (`botspawn.qc`). Added `sv_aim_warned` flag to only
  print the non-default sv_aim warning once per map instead of every bot spawn.
- Feature: Unlocked high skill levels (`botspawn.qc`, `botscore.qc`). Skill cap
  increased from 3 to 10. Skill 4+ = "god mode" bots with perfect aim and faster
  reactions. Use `skill 4` to `skill 10` for increasingly deadly opponents.
- Feature: Added impulse 100 quick-add bot (`botimp.qc`). Standard convention from
  Frogbot and other popular mods. Type `impulse 100` in console to add one bot.
- Non-Issue: Score display requires impulse - standard Quake intermission behavior.
- Non-Issue: Scoreboard colors outside DOS/GLQuake - engine limitation, not bot code.
- Non-Issue: MultiSkin unreliable - code works, requires player.mdl with 16 skins.
- Investigated: "Respawn splash sound" complaint. Spawn uses teleport sounds
  (`misc/r_tele*.wav`) not water splash. Jump sound is correct (`player/plyrjmp8.wav`).
  Marked as "Not Found" in COMMUNITY_ISSUES.md.
- Investigated: "Floating after respawn" complaint. Bot spawn already sets
  `MOVETYPE_STEP` which applies gravity correctly. Marked as "Not Found".
- Legacy changelog archived at `archive/legacy/v1/CHANGELOG_MRE.md`.
- Development guide refreshed for the reboot.
- Legacy docs/tools/launch artifacts archived at `archive/legacy/clean_slate/`.
