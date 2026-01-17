# Known Issues

## 1. Bot collision escapes
- **Symptom:** Bots can still be pushed (rocket knockback or player hits) into solid geometry and end up stuck inside ceilings or walls.
- **Repro:** In `dm4` (or other tight level), damage a bot with a rocket so it bounces into a nearby wall/ceiling; occasionally the trace checks run during knockback still leave the bot inside solid and it never recovers.
- **Current workaround:** Restart the map or `impulse 102` to clear the stuck bot.
- **Next steps:** Need better trace resolution when applying `knockback_time` movement to stop the bot before colliding.

## 2. Logging/console output missing during the clip
- **Symptom:** `launch/quake-spasm/qconsole.log` does not show the collision moment even when `condebug` or `developer` is toggled.
- **Confirmed working sequence:** Launch from `launch/quake-spasm` with the same `mre/progs.dat` produced by `.\ci\build_mre.ps1`, then run `quakespasm.exe -game mre +condebug 1 +developer 1 -listen 8 +maxplayers 8 +deathmatch 1 +map dm4`.
- **Tip:** Delete `qconsole.log` before the run to ensure the file grows; use the `+developer 1` / `+condebug 1` startup switches so verbose output enters the log (once running, `-condebug` will replay the toggle if needed); after reproducing the bug, inspect the end of `qconsole.log`.
- **Next steps:** Investigate whether the traceline tracing during knockback is toggled off in this build or if the log output is being redirected elsewhere.
