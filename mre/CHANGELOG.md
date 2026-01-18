# Changelog

## Unreleased
- Clean baseline restored in `mre/`.
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
  weighting and node priority bias A* routing, danger scents steer bots away
  from lethal nodes, and graph decay lets paths be forgotten over time.
- Feature: Retrospective learning + path optimization (`botroute.qc`, `items.qc`,
  `defs.qc`). Tracks a 5-node trail, rewards winning paths via `node_priority`,
  and creates shortcut links when line-of-sight exists.
- Feature: Teacher Mode debugging (`weapons.qc`). `impulse 102` shows `BotPath`
  nodes with bubble sprites/particles; `impulse 103` hides them.
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
- Fixed: Potential infinite loop in jump simulation (`botmove.qc`). The
  `Bot_tryjump` while loop could hang if simulating a fall into void where
  traceline never hits ground. Added safety counter (100 iterations max).
- Fixed: Scoreboard overflow crash (`client.qc`, `botspawn.qc`). The `FindGood()`
  function returned 1-indexed slots (1-16) but protocol expects 0-indexed (0-15).
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
