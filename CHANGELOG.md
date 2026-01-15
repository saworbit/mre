# Changelog

## Unreleased
- Rebooting Reaper Bot from a clean baseline.
- Focusing first on community-reported issues.
- Fixed: Single player crash to DOS caused by edict overflow (waypoint cap reduced to 50 in SP).
- Fixed: Multiplayer lockups from exponential route cache recursion (added cycle detection).
- Fixed: Potential hang from infinite jump simulation into void (added safety counter).
- Fixed: Crash when adding bots beyond maxplayers (scoreboard overflow guard).
- Updated development and launch docs for the `mre/` layout.
- CI now builds from `mre/` via `ci/build_mre.ps1`.
- Archived legacy docs/tools/launch assets and old logs under `archive/legacy/clean_slate/`.
