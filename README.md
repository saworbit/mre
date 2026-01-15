# Reapbot (Reaper Bot reboot)

We are rebooting the classic Reaper Bot from the original source and fixing
the community-reported issues first. The goal is a stable, fair, and readable
baseline that we can extend in small, testable steps.

## Plan
- Start from the clean baseline in `mre/`.
- Tackle issues in `mre/COMMUNITY_ISSUES.md` in order.
- Keep changes small, rebuild often, and document each fix.

## Docs
- `mre/COMMUNITY_ISSUES.md`
- `mre/SOURCES.md`
- `mre/CHANGELOG.md`

## Build
```
cd c:\reaperai\mre
..\tools\fteqcc_win64\fteqcc64.exe -O3 progs.src
```

Deploy to:
`c:\reaperai\launch\quake-spasm\mre\progs.dat`

## Run
```
c:\reaperai\launch\quake-spasm\launch_reapbot_v2.bat 8 dm4
```
