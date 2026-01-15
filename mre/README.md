# Reapbot (clean slate)

This workspace is the clean baseline for rebuilding Reaper Bot in small,
reviewable steps. The first focus is to address community-reported issues
before adding new behavior.

## Focus
- Start small and keep the bot stable.
- Tackle community callouts first.
- Keep changes incremental and testable.

## Community issues
See `mre/COMMUNITY_ISSUES.md` for the prioritized list drawn from historical
community reports.

## Build
```
cd c:\reaperai\mre
..\tools\fteqcc_win64\fteqcc64.exe -O3 progs.src
```

`progs.src` in this baseline outputs to `c:\reaperai\progs.dat`. Deploy it to:
`c:\reaperai\launch\quake-spasm\mre\progs.dat`

## Run
```
c:\reaperai\launch\quake-spasm\launch_reapbot_v2.bat 8 dm4
```

## References
- `mre/COMMUNITY_ISSUES.md`
- `mre/SOURCES.md`
- `mre/CHANGELOG.md`
