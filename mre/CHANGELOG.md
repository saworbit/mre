# Changelog

## Unreleased
- Clean baseline restored in `mre/`.
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
- Legacy changelog archived at `archive/legacy/v1/CHANGELOG_MRE.md`.
- Development guide refreshed for the reboot.
- Legacy docs/tools/launch artifacts archived at `archive/legacy/clean_slate/`.
