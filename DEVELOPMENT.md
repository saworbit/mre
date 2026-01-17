# Development Guide (Reapbot reboot)

This repo is a clean reboot of the Reaper Bot. The authoritative source lives
under `mre/`, and we fix community-reported issues first.

## Active code location (do not edit legacy)
All active, working code lives in `mre/` only:
https://github.com/saworbit/mre/tree/master/mre
Everything under `archive/` is legacy reference material. Do not edit or build
from `archive/`.

## Layout
- `mre/` - Clean baseline QuakeC sources.
- `launch/quake-spasm/mre/` - Local runtime folder (progs.dat deploy target).
- `ci/` - CI build scripts and artifacts.
- `archive/` - Legacy materials and historical docs (read-only reference).
  - Legacy docs/tools/launch assets were moved to `archive/legacy/clean_slate/`.

## Build
Preferred (auto-downloads fteqcc if missing, deploys to QuakeSpasm):
```
cd c:\reaperai
powershell -ExecutionPolicy Bypass -File ci\build_mre.ps1
```

Manual compile (if you already have fteqcc):
```
cd c:\reaperai\mre
..\tools\fteqcc_win64\fteqcc64.exe -O3 progs.src
```
Manual builds write `c:\reaperai\progs.dat` (the parent folder).
Copy it to the runtime folder:
```
copy c:\reaperai\progs.dat c:\reaperai\launch\quake-spasm\mre\progs.dat /Y
```

## Deploy
The build script copies to:
`c:\reaperai\launch\quake-spasm\mre\progs.dat`

## Run
```
c:\reaperai\launch\quake-spasm\launch_reapbot_v2.bat 8 dm4
```

## Test (full command + logging)
From `c:\reaperai\launch\quake-spasm`:
```
quakespasm.exe -game mre -condebug +developer 1 -listen 8 +maxplayers 8 +deathmatch 1 +map dm4
```
Log output: `c:\reaperai\launch\quake-spasm\qconsole.log`

## CI
```
powershell -ExecutionPolicy Bypass -File c:\reaperai\ci\build_mre.ps1
```
CI publishes: `c:\reaperai\ci\mre\progs.dat`

## Critical QuakeC gotchas
1) **System globals**: never modify anything before `end_sys_globals` in `defs.qc`.
2) **Impulse scope**: guard global toggles with `self.classname == "player"`.
3) **Trace globals**: `traceline()` overwrites `trace_*` globally; save/restore in helpers.
4) **Bitmask clears**: use masked subtraction (`var = var - (var & FLAG)`).

## Legacy docs
The previous MRE development guide is archived at `archive/legacy/v1/DEVELOPMENT_MRE.md`.
