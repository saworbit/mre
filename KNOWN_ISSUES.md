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
- **Symptom:** `Bot should be dead!` appears in `qconsole.log` during heavy combat (often after telefrags/gibs).
- **Impact:** BotPostThink force-gibs the entity, so gameplay continues, but the log line indicates a deadflagged bot reached `BotPostThink`.
- **Next steps:** Add a guard to avoid calling `BotPostThink` from attack frames when `self.deadflag != DEAD_NO`, or early-return at the top of `BotPostThink` without printing unless debugging.
