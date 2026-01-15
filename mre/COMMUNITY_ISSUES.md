# Community issues to tackle first

This list is pulled from the community reports linked in `mre/SOURCES.md`.
Items are grouped by theme and phrased as fixable targets.

## Stability and reliability
- ~~Crashes to DOS after a few minutes in single player.~~ **Fixed:** Edict overflow
  from uncapped waypoint spawns. SP maps have 400-500 entities, leaving little
  headroom for the bot's 140-waypoint limit. Reduced to 50 in SP. (b23_reaper.md)
- Multiplayer lockups after short sessions. (b23_reaper.md)

## Movement and combat feel
- Jumpy/teleport-like strafing makes aiming difficult. (b23_reaper.md)
- Bots appear to "flash" in and out of existence during fights. (b23_reaper.md)
- Bots can become stuck running in a small area while still dealing damage. (b23_reaper.md)
- Camper-like behavior when bots stay near best weapons due to incentive/memory bias. (fandom)

## Fairness and cheating perception
- Community perception that bots "cheat" or act unnaturally at low skill. (b23_reaper.md)
- "Disappearing/vanishing weapons" bug suggests pickups from too far away. (mrelusive)
- Reports that bots grab weapons from far away and fire faster than a player. (fandom)
- Reports that bots gang up on players instead of fighting each other. (fandom)
- Extra SNG ammo to compensate for aiming is viewed as unfair. (fandom)

## Presentation and UX
- Bot frags not shown properly on the scoreboard. (mrelusive)
- Loud/incorrect respawn splash sound and incorrect jump sound. (mrelusive)
- Floating-after-respawn bug noted in patched builds. (mrelusive)
- Score display requires impulse and can end level before player sees results. (fandom)
- Limited Observer mode could allow a bot to attack an invulnerable player; fixed in later versions. (fandom)
- Color/scoreboard messages do not display outside DOS/GLQuake limitations. (fandom)

## Physics and interaction
- Bots not affected by explosion knockback ("bounce the Reaper"). (mrelusive)
- Bots not affected by beartraps in Painkeep. (pkbot.txt)
- Odd teleporting and items found in odd locations reported in 0.8/0.81 history. (fandom)

## Skins and visuals
- No multiskins and no damage skins (Painkeep integration report). (pkbot.txt)
- MultiSkin support reported as unreliable in earlier versions. (fandom)

## Compatibility gaps
- Only default Quake weapons used in Painkeep merge. (pkbot.txt)
- Complaints that bots spam sv_aim warnings when non-default. (fandom)

## Pending
- Quake Fandom page content is blocked by a client challenge in this environment.
  Text callouts were provided by the user and summarized above.
