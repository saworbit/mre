# Development Guide (Reapbot reboot)

This repo is a clean reboot of the Reaper Bot. The authoritative source lives
under `mre/`, and we fix community-reported issues first.

## Layout
- `mre/` - Clean baseline QuakeC sources.
- `launch/quake-spasm/mre/` - Local runtime folder (progs.dat deploy target).
- `ci/` - CI build scripts and artifacts.
- `archive/` - Legacy materials and historical docs.

## Build
Prerequisite: `tools\fteqcc_win64\fteqcc64.exe`
```
cd c:\reaperai\mre
..\tools\fteqcc_win64\fteqcc64.exe -O3 progs.src
```

Note: `mre/progs.src` outputs to `c:\reaperai\progs.dat` (the parent folder).

## Deploy
```
copy c:\reaperai\progs.dat c:\reaperai\launch\quake-spasm\mre\progs.dat /Y
```

## Run
```
c:\reaperai\launch\quake-spasm\launch_reapbot_v2.bat 8 dm4
```

## CI
```
powershell -File c:\reaperai\ci\build_mre.ps1
```
CI publishes: `c:\reaperai\ci\mre\progs.dat`

## Critical QuakeC gotchas
1) **System globals**: never modify anything before `end_sys_globals` in `defs.qc`.
2) **Impulse scope**: guard global toggles with `self.classname == "player"`.
3) **Trace globals**: `traceline()` overwrites `trace_*` globally; save/restore in helpers.
4) **Bitmask clears**: use masked subtraction (`var = var - (var & FLAG)`).

## Legacy docs
The previous MRE development guide is archived at `archive/legacy_v1/DEVELOPMENT_MRE.md`.
