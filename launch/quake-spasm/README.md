# Quake Spasm launch space

This folder bundles Quake Spasm binaries with the Steam `id1` data so you can launch Quake from this repository without re-downloading the base game.

## Contents
- `quakespasm.exe`, `quakespasm-sdl12.exe`, `SDL.dll`, `SDL2.dll`, and codec DLLs – Windows x64 QuakeSpasm build placed in this folder for direct launch.
- `win32` – unpacked Windows x86 build (`quakespasm-0.96.3_windows`) if you need 32-bit.
- `quake-spasm-linux` – ELF executable from the jarokuczi `pre-alpha` release (Linux build). Run it from WSL/WSL2 or any Linux shell.
- `id1/PAK0.PAK` and `id1/PAK1.PAK` – Steam `id1` pack files copied from `C:\Program Files (x86)\Steam\steamapps\common\Quake\id1`.

## Running

### Linux / WSL
1. Open your Linux shell or WSL terminal.
2. `cd /mnt/c/reaperai/launch/quake-spasm` (adjust to your repo path).
3. `./quake-spasm-linux` (Quake Spasm finds the `id1` directory automatically).

### Windows
1. Open PowerShell or `cmd`.
2. `cd C:\reaperai\launch\quake-spasm` (or `cd C:\reaperai\launch\quake-spasm\win32` for the 32-bit build).
3. Run `quakespasm.exe` (or `quakespasm-sdl12.exe` if you prefer SDL 1.2). Quake Spasm will look for `.\id1`, which already resides next to the executable.

The Windows archives ship with their own DLLs (`SDL.dll`, `SDL2.dll`, codec libraries) and documentation (`Quakespasm.txt`, `LICENSE.txt`, etc.), so no additional setup is required beyond the `id1` data.

### Reaper Bot mod
1. Keep `launch\quake-spasm\RPBOT` next to the Windows binaries; it already contains `Autoexec.cfg`, `Reaprb80.txt`, and the freshly compiled `PROGS.DAT`/`progs.dat`.
2. Run `quakespasm.exe -game RPBOT` (or add `-game RPBOT` when launching via shortcut) from the folder that contains the executable; Quake Spasm loads the mod from `RPBOT` and references the `id1` folder alongside it.
3. If adding bots triggers `Host_error: CL_ParseServerMessage: Svc_updatename ) Max_scoreboard`, restart with more slots. Example:
   `quakespasm.exe -game RPBOT -listen 8 +maxplayers 8 +deathmatch 1 +map dm4`

### Reaper MRE mod
1. The recompiled MRE build lives in `launch\quake-spasm\reaper_mre` with `progs.dat`.
2. Run `quakespasm.exe -basedir C:\reaperai\launch\quake-spasm -game reaper_mre` from `launch\quake-spasm` to load it.
3. Default bots spawn at skill 3 (nightmare). You can run `skill 3` to confirm; use `bot_skill_adapt 1` to enable streak-based scaling, then `addbot <name> 5` for max skill bots.
4. CI artifact copy: `C:\reaperai\ci\reaper_mre\progs.dat`.
5. **Elevator Navigation Testing** (NEW 2026-01-08):
   - Enable debug logging: `impulse 95` (toggle bot debug ON), then `impulse 96` twice to cycle to LOG_TACTICAL verbosity
   - Best test map: `map dm4` (has 452 waypoints + Yellow Armor elevator at ~1792, 384, -168)
   - Expected elevator messages in console:
     - `[BotName] ELEVATOR: Waiting at '1792.0 384.0 -168.0'` (bot waiting for platform)
     - `[BotName] ELEVATOR: Boarding (waited 2.3s)` (platform arrived, bot boards)
     - `[BotName] ELEVATOR: Timeout (30.1s), replanning` (platform never came, finding alternate route)
     - `A*: Elevator blocked at '...' (platform at top)` (A* skipping elevator, using stairs)
   - See `ELEVATOR_TEST_GUIDE.md` in repo root for detailed testing protocol
   - See `CRITICAL_FINDING.md` for log analysis showing 108-stuck-loop at DM2 elevator (evidence system is needed)
6. Predictive bot aiming (splash height variance, vertical lead, velocity-history smoothing with strafe-pattern overlead, chase extrapolation) scales with skill; `+map dm6` is a good stress test for movers.
7. Powerup denial logic now boosts quad/pent/ring contesting; `+map dm2` is a good test for quad denial.
8. Adaptive goal logic now prefers health when hurt and leans into denial when leading; `+map dm3` is a good mixed-item test.
9. Weapon choice now conserves rockets, counters Quad/Pent with SNG, and goes melee earlier on weak targets; `+map dm6` with `impulse 208` is a good stress test.
10. Adrenaline logic now tightens aim noise and speeds think cycles when low HP or in close fights; `+map dm2` is a good close-quarters test.
11. High-skill bots now spawn with memory (pre-cached routes to key powerups/weapons) and bias their first goal toward rocket control; `+map dm1` is a good spawn-route test.
12. Streak-based tuning (enable with `bot_skill_adapt 1`) nudges skill up/down based on kill/death streaks and biases target acquisition; `+map dm4` is a good multi-fight test.
13. Route caching now checks mid-route blockage, reacts to target velocity shifts, and prunes poor branches with a light heuristic; `+map dm5` is a good dynamic reroute test.
14. Goal selection now boosts items near low-HP enemies and predicts fast enemy paths for intercepts; `+map dm2` is a good chase/finish test.
15. Weapon-aware evasion now widens rocket dodges, flips strafe direction on self-velocity shifts, and adds lightning-gun jump bias; `+map dm7` is a good projectile evasion test.
16. Noise-based taunts now trigger on hot streaks (varied lines) and death streak complaints on gib noises; `+map dm1` is a good low-pop test for bprint output.
17. Movement recovery now detects stuck loops, escalates sidesteps (jump/diagonal/backpedal), and adds idle patrol wandering; `+map e1m1` is a good corner/idle test.
18. Vision now includes corner-peek traces, idle scan yaw sweeps, and stuck-time quick rejection; `+map dm4` is a good corner/LOS test.
19. **Physics-accurate navigation** now uses finer arc simulation (0.05s vs 0.1s timesteps), strafe momentum carryover (30% ground velocity), and multi-trace path validation (2x sample density + collision detection); `+map e1m1` (tight stairs) and `+map e1m2` (ramps) are good jump precision tests.
20. **Grenade launcher mastery** now predicts 1-bounce wall shots (0.8 elasticity reflection), uses full gravity arc physics (g×t×0.6 lob velocity), and validates self-risk (<128u splash) to prevent frag-suicide; `+map dm3` (crates/corridors) is a good bank-shot test, `give 6` for GL.
21. **Tactical AI** now scores items by need (RL/Quad/low ammo +100-200) minus threat (enemy proximity -80 max), amplifies powerup denial when leading (+0.15) or enemy weak (+0.2), and rotates 45° on stuck attempts with cache-clear on loop; `+map dm4` is a good tactical decision test.
22. **Air physics suite** now clamps horizontal air speed (320-400 u/s skill-scaled), smooths jump velocity patterns (3-frame avg, 300 u/s cap), and dampens mid-air velocity 20% when goal unreachable; `+map e1m3` (castle falls/jumps) is a good air control test.

### One-click launch (Windows)
Run `launch_rpbot.bat` from `launch\quake-spasm` to start the mod with a safe default:
`launch_rpbot.bat [maxplayers] [map]`

Example:
`launch_rpbot.bat 8 dm4`

For the MRE build, use:
`launch_reaper_mre.bat 8 dm4`

If you see a "can't find pak files" error, make sure you launch through the scripts (they set `-basedir` explicitly) or add `-basedir C:\reaperai\launch\quake-spasm` to your manual command.

### Debug logging (MRE)
If the MRE build crashes, enable console logging and developer output so the crash context is captured:
`quakespasm.exe -basedir C:\reaperai\launch\quake-spasm -game reaper_mre -condebug +developer 1 +sv_gravity 800 -listen 8 +maxplayers 8 +deathmatch 1 +map dm4`

The log is written to `C:\reaperai\launch\quake-spasm\qconsole.log`.
Expected warnings include missing music tracks and IPX disabled; those are normal for local tests.

### Latest test (dm2 quad denial)
Recent debug run on dm2 completes startup and gameplay without crashes; no host errors observed in `qconsole.log`.

### Latest test (dm3 adaptive goals)
Recent debug run on dm3 completes startup and gameplay without crashes; no host errors observed in `qconsole.log`.

### Latest test (dm6 weapon selection)
Recent debug run on dm6 completes startup and gameplay without crashes; no host errors observed in `qconsole.log`.

### Latest test (dm2 adrenaline focus)
Recent debug run on dm2 completes startup and gameplay without crashes; no host errors observed in `qconsole.log`.

### Latest test (dm1 spawn memory)
Recent debug run on dm1 completes startup and gameplay without crashes; no host errors observed in `qconsole.log`.

### Latest test (dm4 streak tuning)
Recent debug run on dm4 completes startup and gameplay without crashes; no host errors observed in `qconsole.log`.

### Latest test (dm6 pattern lead)
Recent debug run on dm6 completes startup and gameplay without crashes; no host errors observed in `qconsole.log`.

### Latest test (dm5 reroute heuristics)
Recent debug run on dm5 completes startup and gameplay without crashes; no host errors observed in `qconsole.log`.

### Latest test (dm2 log review)
Recent debug run on dm2 completes startup and gameplay without crashes; no host errors observed in `qconsole.log`. Observed expected warnings (missing music track 0, IPX disabled) and normal gravity diagnostics output.

### Latest test (dm6 log review)
Recent debug run on dm6 completes startup and gameplay without crashes; no host errors observed in `qconsole.log`. Observed expected warnings (missing music track 5, IPX disabled) and normal gravity diagnostics output.

### Physics navigation testing
**Recommended test command** (full debug output with 8 bot slots):
```
C:\reaperai\launch\quake-spasm\quakespasm.exe -basedir C:\reaperai\launch\quake-spasm -game reaper_mre -condebug +developer 1 +sv_gravity 800 -listen 8 +maxplayers 8 +deathmatch 1 +map dm4
```

**Test scenarios for physics improvements:**
- **Finer arc simulation**: `+map e1m1` then spawn bots and observe stair navigation—should see consistent jump clearance without overshoot on tight consecutive ledges.
- **Strafe momentum**: `+map e1m2` then add bots and watch ramp/platform jumps—running bots should reach farther ledges that standing bots can't (realistic momentum carryover).
- **Multi-trace validation**: `+map dm4` or craggy custom maps—bots should avoid paths with mid-route obstacles/clips (fewer stuck-in-wall incidents).

**Quick physics verification** (console commands):
```
skill 3          // Set hard difficulty
addbot reaper 5  // Spawn max-skill bot
impulse 9        // Give all weapons (for testing)
noclip           // Free camera to follow bot jumps
```

Watch bots navigate complex geometry—jumps should look natural, momentum-aware, and collision-conscious.

### CI suggestion
For this repo, a lightweight Windows CI works best:
1. Local compile flow (same steps CI uses):
   - `cd C:\reaperai\reaper_mre`
   - `..\tools\fteqcc_win64\fteqcc64.exe -O3 progs.src`
   - Output: `C:\reaperai\reaper_mre\progs.dat`
2. CI build script (preferred, wraps the above and adds checks):
   - `C:\reaperai\ci\build_reaper_mre.ps1`
   - Verifies compiler exists and `progs.dat` is non-trivial size.
   - Publishes artifact to `C:\reaperai\ci\reaper_mre\progs.dat`.
3. Game test location (manual copy step after any build):
   - Copy `C:\reaperai\reaper_mre\progs.dat` to `C:\reaperai\launch\quake-spasm\reaper_mre\progs.dat`.
4. GitHub Actions:
   - Workflow: `.github/workflows/ci.yml`
   - Runs the PowerShell script and uploads `ci/reaper_mre/progs.dat` as an artifact.
   - This does not update your local `launch/quake-spasm` folder; copy locally if you want to play.
