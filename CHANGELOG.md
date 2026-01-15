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
- Updated development and launch docs for the `mre/` layout.
- CI now builds from `mre/` via `ci/build_mre.ps1`.
- Archived legacy docs/tools/launch assets and old logs under `archive/legacy/clean_slate/`.
