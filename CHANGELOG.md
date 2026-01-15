# Changelog

## Unreleased
- Rebooting Reaper Bot from a clean baseline.
- Focusing first on community-reported issues.
- Fixed: Single player crash to DOS caused by edict overflow (waypoint cap reduced to 50 in SP).
- Fixed: Multiplayer lockups from exponential route cache recursion (added cycle detection).
- Fixed: Potential hang from infinite jump simulation into void (added safety counter).
- Fixed: Crash when adding bots beyond maxplayers (scoreboard overflow guard).
- Fixed: Jumpy/teleport-like strafing (removed sub-frame timing, added velocity for interpolation).
- Fixed: "Flashing" bots near water (stricter teleptest checks).
- Fixed: Bots getting stuck running in place (position delta detection + jump attempts).
- Fixed: Camper behavior near best weapons (ignore owned weapons when ammo sufficient).
- Fixed: Suicidal explosive firing (switch weapons when enemy <150 units).
- Fixed: Thunderbolt water discharge (switch weapons when in water).
- Improved: Predictive aiming (capped lead time to 0.5s to prevent over-leading).
- Fixed: Bots walking into lava/slime (hazard avoidance with powerup awareness).
- Fixed: Bots walking off lifts mid-ride (platform state detection).
- Fixed: Bots stuck at closed doors (trigger door and back up to let it open).
- Updated development and launch docs for the `mre/` layout.
- CI now builds from `mre/` via `ci/build_mre.ps1`.
- Archived legacy docs/tools/launch assets and old logs under `archive/legacy/clean_slate/`.
