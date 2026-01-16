# Changelog

## Unreleased
- Clean baseline restored in `mre/`.
- Added: Reaction time simulation (`bot_ai.qc`, `botgoal.qc`). Bots now have a
  skill-based delay before engaging newly-spotted enemies. Skill 0 = 200ms delay,
  Skill 3 = 50ms, Skill 4+ = instant. Makes low-skill bots feel more human-like
  when surprised.
- Added: Object permanence (`bot_ai.qc`, `botfight.qc`). When line of sight breaks,
  bots continue firing at the last known position for a skill-based duration
  (Skill 0 = 0.5s, Skill 4 = 1.5s). Prevents robotic instant-stop behavior when
  target crosses a doorframe.
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
- Fixed: Bots getting stuck running in place (`botgoal.qc`). Added position delta
  check in `ai_botseek` that forces faster goal timeout when bot hasn't moved, with
  occasional jump attempts to dislodge.
- Fixed: Camper behavior near best weapons (`botgoal.qc`). Modified `itemweight` to
  ignore weapons the bot already owns when ammo is sufficient (>50 nails/cells,
  >10 rockets).
- Fixed: Suicidal rocket/grenade firing (`botfight.qc`). Added safety check in
  `W_BotAttack` to switch weapons when enemy is within 150 units instead of
  firing explosives at point-blank range.
- Fixed: Thunderbolt water discharge suicide (`botfight.qc`). Added safety check
  to switch weapons when in water (waterlevel >= 2) instead of instant-death
  discharge.
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
