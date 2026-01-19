# Known Issues

## 1. Bot knockback embedding (regression watch)
- **Status:** Addressed by switching `dmbot` to `MOVETYPE_BOUNCE` on knockback and removing the manual traceline teleport in `botmove.qc`. Movement returns to `MOVETYPE_STEP` once grounded or slow.
- **Verify:** Build from `mre/`, deploy the resulting `progs.dat` into `launch/quake-spasm/mre/`, then test on tight maps (dm4/dm6). If a bot still embeds, capture the map name and log.
- **Fallback:** If it still happens, restart the map or `impulse 102` to clear the stuck bot.

## 2. Knockback logging missing
- **Status:** Added developer-only `KNOCKBACK` logs in `BotPostThink` when knockback is recent.
- **Confirm:** Run with `+developer 1 +condebug 1` and check `launch/quake-spasm/qconsole.log` for `[BotName] KNOCKBACK: vel=... type=...` lines near impacts.
- **Tip:** Delete `qconsole.log` before the run so you can easily spot new lines at the end.

## 3. "Bot should be dead!" log line
- **Status:** Fixed. `BotPostThink` now returns immediately for deadflagged bots to avoid the noisy log line during telefrags/gibs.

## 4. Quad pickup at respawn without proximity
- **Status:** Fixed. Ensured a BotPath node is dropped at Quad/Pent spawns so timing rushes always route through breadcrumbs.
- **Verify:** Run `dm2` with `+developer 1 +condebug 1`, time Quad, and confirm bots path normally instead of beelining.
