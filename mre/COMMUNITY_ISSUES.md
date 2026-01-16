# Community issues to tackle first

This list is pulled from the community reports linked in `mre/SOURCES.md`.
Items are grouped by theme and phrased as fixable targets.

## Stability and reliability
- ~~Crashes to DOS after a few minutes in single player.~~ **Fixed:** Edict overflow
  from uncapped waypoint spawns. SP maps have 400-500 entities, leaving little
  headroom for the bot's 140-waypoint limit. Reduced to 50 in SP. (b23_reaper.md)
- ~~Multiplayer lockups after short sessions.~~ **Fixed:** Three issues: (1) exponential
  recursion in route caching (6^12 worst case) solved with cycle detection,
  (2) infinite loop in jump simulation when falling into void solved with safety
  counter, and (3) scoreboard overflow crash when adding bots beyond maxplayers
  (FindGood changed to 0-indexed + guard added). (b23_reaper.md)

## Movement and combat feel
- ~~Jumpy/teleport-like strafing makes aiming difficult.~~ **Fixed:** Removed
  `halfwalkmove` sub-frame timing (0.05s) and added velocity setting after
  `walkmove` calls for smooth client-side interpolation. (b23_reaper.md)
- ~~Bots appear to "flash" in and out of existence during fights.~~ **Fixed:**
  Added stricter checks in `teleptest` for headroom and floor footing before
  allowing water teleportation via `setorigin`. (b23_reaper.md)
- ~~Bots can become stuck running in a small area while still dealing damage.~~
  **Fixed:** Added position delta check in `ai_botseek` to detect when bot hasn't
  moved; forces faster goal timeout and occasional jump attempts. (b23_reaper.md)
- ~~Camper-like behavior when bots stay near best weapons due to incentive/memory bias.~~
  **Fixed:** Modified `itemweight` to return DONT_WANT for weapons the bot already
  owns when ammo is sufficient. (fandom)

## Fairness and cheating perception
- ~~Community perception that bots "cheat" or act unnaturally at low skill.~~ **Fixed:**
  Increased skill-based aim jitter in `botaim()` from 0.06 to 0.15 per skill level
  (max ~25° error at skill 0 vs ~10° before). Added vertical aim error. Low-skill bots
  now miss noticeably more often. (b23_reaper.md)
- ~~"Disappearing/vanishing weapons" bug suggests pickups from too far away.~~ **Fixed:**
  Added 48-unit distance check in `t_botmovetarget` so bots must be close to items
  before goal completion triggers. (mrelusive)
- ~~Reports that bots grab weapons from far away and fire faster than a player.~~ **Fixed/Not Found:**
  Grab-from-far fixed by 48-unit distance check. Fire rate investigated: bots use
  identical attack_finished timings as players (0.5s shotgun, 0.7s SSG, 0.8s RL,
  etc.) and low-skill bots add extra delay via `addt`. No faster firing found. (fandom)
- ~~Reports that bots gang up on players instead of fighting each other.~~ **Fixed:**
  Rewrote `BotFindTarget` to iterate all targets and pick closest, instead of using
  `checkclient()` which returned humans first due to entity slot order. (fandom)
- ~~Extra SNG ammo to compensate for aiming is viewed as unfair.~~ **Not Found:**
  Searched all weapon pickup, spawn, and firing code - no bot-specific ammo bonus
  exists in this baseline. Bots consume identical ammo as players (2 nails/shot SNG).
  Complaint may have been about older versions or perceived effectiveness. (fandom)

## Presentation and UX
- Bot frags not shown properly on the scoreboard. (mrelusive)
- ~~Loud/incorrect respawn splash sound and incorrect jump sound.~~ **Not Found:**
  Investigated spawn code - bots use teleport sounds (`misc/r_tele*.wav`) not water
  splash. Jump sound in `Botjump` uses correct `player/plyrjmp8.wav`. (mrelusive)
- ~~Floating-after-respawn bug noted in patched builds.~~ **Not Found:** Bot spawn
  already sets `MOVETYPE_STEP` which applies gravity correctly. (mrelusive)
- Score display requires impulse and can end level before player sees results. (fandom)
- ~~Limited Observer mode could allow a bot to attack an invulnerable player.~~ **Fixed:**
  Added `MOVETYPE_NOCLIP` and `deadflag` checks to `BotValidTarget()` in bot_ai.qc.
  Bots now ignore spectators/observers and dead/dying players. (fandom)
- Color/scoreboard messages do not display outside DOS/GLQuake limitations. (fandom)

## Physics and interaction
- Bots not affected by explosion knockback ("bounce the Reaper"). (mrelusive)
- Odd teleporting and items found in odd locations reported in 0.8/0.81 history. (fandom)

## Skins and visuals
- MultiSkin support reported as unreliable in earlier versions. (fandom)

## Compatibility gaps
- Complaints that bots spam sv_aim warnings when non-default. (fandom)
