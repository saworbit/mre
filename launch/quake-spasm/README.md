# Quake Spasm launch space

This folder holds Quake Spasm binaries plus the `id1` data for local testing.

## Windows quick start
```
cd C:\reaperai\launch\quake-spasm
launch_reapbot_v2.bat 8 dm4
```

## Manual launch
```
quakespasm.exe -basedir C:\reaperai\launch\quake-spasm -game mre -listen 8 +maxplayers 8 +deathmatch 1 +map dm4
```

## Files
- `mre\progs.dat` - current build output to test.
- Legacy RPBOT assets are archived at `archive/legacy/clean_slate/launch/quake-spasm/RPBOT`.

## Legacy
The previous MRE-focused launch notes are archived at
`archive/legacy/v1/README_LAUNCH_MRE.md`.
