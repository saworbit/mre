# 🤖 Modern Reaper Enhancements (MRE)

> **Bringing 90s Quake bots into the modern era with advanced AI, physics-based navigation, and human-like combat tactics**

[![Build](https://img.shields.io/badge/build-passing-brightgreen)]() [![Quake](https://img.shields.io/badge/Quake-1-brown)]() [![Bot AI](https://img.shields.io/badge/AI-Enhanced-blue)]()

**📂 Active Development:** All modern enhancements are in [`reaper_mre/`](https://github.com/saworbit/mre/tree/master/reaper_mre) — this is the primary codebase for MRE features.

---

## 🎯 What is MRE?

Modern Reaper Enhancements is a heavily upgraded version of the classic **Reaper Bot** for Quake 1. Born from the legendary 1998 bot, MRE adds sophisticated AI systems, realistic physics navigation, and advanced combat tactics that make bots play like skilled human players.

### ✨ Why MRE?

- 🧠 **Smarter AI** — Advanced decision-making, tactical positioning, and adaptive difficulty
- 🚀 **Physics Mastery** — Rocket jumps, train surfing, platform prediction, and more
- 🎮 **Human-like Play** — Predictive aim, weapon conservation, and strategic powerup denial
- ⚡ **Modern Code** — Clean QuakeC with extensive documentation and modular design
- 🏆 **Competitive Ready** — Skill-based mechanics from novice to pro-level play

---

## 🎬 Latest Features (2026-01)

### 🚀 Enhanced Rocket Jump System

Bots now execute **proper rocket jumps** with professional-level control:

- ✅ **Health checks** — Won't suicide if HP < 50
- ⏱️ **2-second cooldown** — Prevents spam and maintains balance
- 🎯 **Directional aim control** — Dynamic pitch: 85° for high ledges, 45° for long gaps; yaw aims toward goal
- ⚡ **Synchronized timing** — Jump perfectly timed with rocket blast
- 🏔️ **Smart triggers** — Auto-RJ when ledges exceed 1.5× normal jump height (skill >2)
- 🆘 **Safe unstuck escape** — Replaces dangerous "turn and fire" with controlled RJ

**Result:** Bots reach unreachable platforms just like human speedrunners! 🏃‍♂️💨

### 🚂 Train Navigation Enhancements

Advanced **path_corner chain prediction** for moving platforms:

- 🔗 **Multi-segment pathing** — Two-pass algorithm traverses entire train routes
- 🎯 **Future position prediction** — Bots intercept trains where they *will be*, not where they are
- 🌀 **Loop detection** — Handles cycling paths with modulo arithmetic
- 🏄 **Train surfing** — Desperate unstuck detects trains beneath bot, boosts escape velocity (1.5×)
- 📐 **Precise timing** — Jump arc prediction uses path chains for mid-air train sync

**Result:** Human-like timing for vertical/horizontal train navigation! 🚂✨

---

## 🛠️ Complete Feature Suite

### 🧭 Advanced Navigation

| Feature | Description |
|---------|-------------|
| 📊 **Platform Prediction** | Velocity + state forecasting for timed jumps on moving plats |
| 🎯 **Jump Arc Collision** | Mid-air platform detection for precise airborne landings |
| 🔘 **Button Shoot + Wait** | Auto-fires shootables, monitors door state for fluid secrets |
| 🛗 **Ride Auto-Follow** | Velocity inheritance + goal tracking for seamless platform travel |
| 🆘 **Desperate Unstuck** | Escalates to rocket jump/super jump after 5+ stuck attempts |

### ⚔️ Combat Mastery

| Feature | Description |
|---------|-------------|
| 💣 **Grenade Bounce Prediction** | 1-bounce physics for wall-bank shots and corner kills |
| 🌈 **Gravity Arc Simulation** | Full parabolic trajectory for long-range lobs |
| 🎯 **Predictive Aim** | Splash height variance + vertical lead + velocity smoothing |
| 🎬 **Human-Like Aim Smoothing** | Pitch slew rate system (150-450°/s by skill) replaces aimbot snap-lock |
| 🛡️ **Self-Risk Validation** | Aborts GL fire if self-splash risk < 128u |
| 🔫 **Weapon-Aware Evasion** | Rocket zigzags, strafe flips, LG jump bias |
| 🧱 **Wall Sliding + Combat Hopping** | Vector slide + active bunny-hopping (20% vs RL, 10% combat, LG stable) |

### 🧠 Tactical AI

| Feature | Description |
|---------|-------------|
| 📊 **Risk-Aware Scoring** | Need-based item boosts minus threat penalty (proximity -80 max) |
| 🎒 **Smart Backpack Scavenging** | Intelligent prioritization when starving for weapons/ammo (3000 weight if missing RL/LG) |
| ⚔️ **Weapon Counter-Tactics** | Rock-paper-scissors logic: RL counters LG (knockback), LG counters RL (hitscan) |
| 🗺️ **Global Scavenger Hunt** | Map-wide item scan when alone (RL/LG/RA/Mega prioritization vs random wander) |
| 🧩 **Problem Solver** | Dynamic obstacle solving: RJ for high items, button-door linking, shootable detection |
| 🏆 **Powerup Denial** | Amplified aggression when leading or enemy weak (<40 HP) |
| 🔄 **Adaptive Goals** | Health when hurt, denial when leading, smart roam patterns |
| 💰 **Weapon Conservation** | Rocket economy, Quad/Pent counters, ammo awareness |
| 🔥 **Adrenaline Focus** | Tighter aim + faster think cycles under pressure |
| 🧩 **Spawn Memory** | High-skill bots pre-cache key routes at spawn |
| 📈 **Streak Tuning** | Dynamic difficulty based on kill/death streaks |

### 🏃 Physics Systems

| Feature | Description |
|---------|-------------|
| 🐰 **Bunny Hop Mechanics** | Skill-based strafe-jump acceleration (skill >2, +12 u/s boost, 600 u/s cap) |
| 🎢 **Jump Smoothing** | 3-frame moving average eliminates jittery trajectories |
| 🪂 **Mid-Air Correction** | 20% velocity damping when trajectory becomes unreachable |
| 🎯 **Finer Arc Simulation** | 0.05s timesteps for precise parabolic prediction |
| 🏃 **Strafe Momentum** | 30% velocity carryover simulates realistic running jumps |
| 🚧 **Multi-Trace Validation** | 2× sampling density catches walls/clips sparse checks miss |

---

## 🚀 Quick Start

### Prerequisites

- 🎮 Quake 1 (registered version with `id1/PAK0.PAK` and `PAK1.PAK`)
- 🪟 Windows (x64 or x86)

### One-Click Launch

1. **Navigate to launch directory:**
   ```bash
   cd launch/quake-spasm
   ```

2. **Run the launcher:**
   ```bash
   launch_reaper_mre.bat 8 dm4
   ```
   *(8 players on DM4 — adjust as needed)*

3. **Enjoy!** 🎮

### Custom Launch

```bash
launch_reaper_mre.bat [maxplayers] [map]

# Examples:
launch_reaper_mre.bat 4 dm2    # 4 players on The Claustrophobopolis
launch_reaper_mre.bat 6 dm6    # 6 players on The Dark Zone
launch_reaper_mre.bat 16 dm3   # 16-player chaos on The Abandoned Base
```

---

## 🏗️ Building from Source

### Directory Structure

```
reaper_mre/              ← Active development (QuakeC source)
├── botmove.qc          ← Movement, navigation, rocket jumps, train prediction
├── botfight.qc         ← Combat AI, weapon selection, predictive aim
├── botthink.qc         ← Physics systems, air control, velocity management
├── botit_th.qc         ← Entity fields, bot state tracking
├── botvis.qc           ← Visibility, reachability, pathfinding
├── botgoal.qc          ← Goal selection, item scoring, tactics
├── progs.src           ← Build manifest (entry point for compiler)
└── ...                 ← Additional QuakeC modules

tools/fteqcc_win64/
└── fteqcc64.exe        ← Compiler binary

launch/quake-spasm/
├── reaper_mre/         ← Deployed progs.dat (build artifact)
├── launch_reaper_mre.bat  ← Quick launch script
└── quakespasm.exe      ← Quake engine
```

---

### Full Build Workflow

#### Step 1: Compile Source

**Command:**
```bash
cd c:\reaperai
tools\fteqcc_win64\fteqcc64.exe -O3 reaper_mre\progs.src
```

**What it does:**
- Compiles all `reaper_mre/*.qc` files into `reaper_mre/progs.dat`
- `-O3` flag enables maximum optimization
- Output: ~380 KB binary

**Expected output:**
```
Compiling progs.dat
...
Successfull compile! (with warnings)
```

---

#### Step 2: Deploy Build Artifact

**Commands:**
```bash
# Deploy to test environment
copy reaper_mre\progs.dat launch\quake-spasm\reaper_mre\progs.dat /Y

# Deploy to CI validation directory
copy reaper_mre\progs.dat ci\reaper_mre\progs.dat /Y
```

**What it does:**
- Copies compiled `progs.dat` to runtime directories
- `/Y` flag suppresses overwrite confirmation
- Creates deployable artifact for testing

---

#### Step 3: Launch and Test

**Normal Play (recommended):**
```bash
cd launch\quake-spasm
launch_reaper_mre.bat 8 dm4
```
- Starts 8-player deathmatch on DM4
- Uses standard game settings
- No console output

**Debug Mode (verbose logging):**
```bash
cd launch\quake-spasm
quakespasm.exe -basedir . -game reaper_mre -listen 8 +map dm4 +skill 3 +deathmatch 1 +maxplayers 8 +impulse 208
```
- `-listen 8` = Run as listen server (keeps game running for observation)
- `+skill 3` = Expert bots (full AI capabilities)
- `+impulse 208` = Spawns bots via console command
- Logs output to `qconsole.log`

**Console Commands (in-game):**
```
skill 3           // Set difficulty (0-3, higher = smarter)
impulse 100       // Add 1 bot
impulse 101       // Add bots until maxplayers
impulse 102       // Remove 1 bot
impulse 208       // Mass-spawn bots
```

---

#### Step 4: Verify Functionality

**Check console log:**
```bash
type launch\quake-spasm\qconsole.log
```

**Expected indicators of success:**
- `Programs occupy 376K` (confirms progs.dat loaded)
- Bot spawn messages: `Cheater (iq 1) is reformed Thanks Chris.`
- No `Host Error` messages
- Expected warnings only (missing music files, IPX disabled)

**Test rocket jumps:**
- Watch skill 3 bots on DM3/DM4
- Should see bots rocket-jumping to high ledges
- No suicide deaths at low HP

**Test train navigation:**
- DM6 has moving trains
- Bots should intercept trains mid-movement
- No "stuck" loops near trains

---

### CI Pipeline (Automated Build)

#### GitHub Actions Workflow

**File:** `.github/workflows/ci.yml`

**Trigger:** Every push to repository

**Build steps:**
1. **Compile:** Run `fteqcc64.exe -O3 reaper_mre\progs.src`
2. **Validate:** Check build size (~380 KB)
3. **Archive:** Upload `reaper_mre-progs.dat` as artifact
4. **Status:** Report success/failure

**Artifact download:**
- Go to [Actions tab](https://github.com/saworbit/mre/actions)
- Click latest workflow run
- Download `reaper_mre-progs.dat` from artifacts

**Integration:**
```bash
# Download artifact from CI
curl -L -o progs.dat https://github.com/saworbit/mre/actions/runs/[RUN_ID]/artifacts/[ARTIFACT_ID]

# Deploy to local test environment
copy progs.dat launch\quake-spasm\reaper_mre\progs.dat /Y
```

---

### Complete Development Workflow

This section documents the full end-to-end development cycle for implementing and testing features.

#### Prerequisites Check

**Required files and tools:**
```
c:\reaperai\
├── tools\fteqcc_win64\fteqcc64.exe   ← Compiler (must exist)
├── reaper_mre\*.qc                   ← Source files (active development)
├── reaper_mre\progs.src              ← Build manifest
├── launch\quake-spasm\               ← Test environment
│   ├── quakespasm.exe                ← Engine binary
│   ├── id1\PAK0.PAK                  ← Game data (required)
│   ├── id1\PAK1.PAK                  ← Game data (required)
│   └── reaper_mre\                   ← Deployment target
└── ci\reaper_mre\                    ← CI validation target
```

**Verify setup:**
```bash
# Check compiler exists
dir tools\fteqcc_win64\fteqcc64.exe

# Check source files
dir reaper_mre\*.qc

# Check engine
dir launch\quake-spasm\quakespasm.exe

# Check game data
dir launch\quake-spasm\id1\*.PAK
```

---

#### Workflow: Making Code Changes

**Step 1: Edit QuakeC source files**

Edit files in `reaper_mre/` directory:
- `botmove.qc` — Movement, navigation, jumps, trains
- `botfight.qc` — Combat, weapons, aim
- `botthink.qc` — Physics, air control
- `botvis.qc` — Visibility, reachability
- `botgoal.qc` — Item scoring, tactics
- `botit_th.qc` — Entity fields (add `.float` variables here)

**QuakeC syntax constraints:**
- No ternary operators: Use `if/else` blocks
- No compound assignment: `x = x + 1` not `x += 1`
- No increment: `x = x + 1` not `x++`
- Forward declarations required: If function A calls function B before B is defined, add `float() B;` at top

**Step 2: Compile the source**

```bash
# Change to project root
cd c:\reaperai

# Run compiler with optimization
tools\fteqcc_win64\fteqcc64.exe -O3 reaper_mre\progs.src
```

**Success indicators:**
```
Compiling progs.dat
<compilation output>
Successfull compile! (with warnings)
```

**Expected output file:**
- Location: `reaper_mre\progs.dat`
- Size: ~380 KB (376-384 KB range)
- Warnings: Expected (missing precache, unused variables)
- Errors: Must be 0 for success

**Failure indicators:**
- `error: <message>` lines in output
- No `progs.dat` file created
- Build stops before "Successfull compile!"

**Step 3: Deploy to test environments**

```bash
# Deploy to primary test location
copy reaper_mre\progs.dat launch\quake-spasm\reaper_mre\progs.dat /Y

# Deploy to CI validation location
copy reaper_mre\progs.dat ci\reaper_mre\progs.dat /Y
```

**Success indicators:**
- `1 file(s) copied.` for each copy command
- Files exist at target locations

**Verify deployment:**
```bash
# Check file sizes match
dir reaper_mre\progs.dat
dir launch\quake-spasm\reaper_mre\progs.dat
dir ci\reaper_mre\progs.dat
```

---

#### Workflow: Testing Changes

**Quick test (normal play):**

```bash
# Navigate to test environment
cd launch\quake-spasm

# Launch with standard settings
launch_reaper_mre.bat 8 dm4
```

**Parameters:**
- `8` — Max players (2-16)
- `dm4` — Map name (dm2, dm3, dm4, dm5, dm6)

**What happens:**
- Quake engine launches in window
- Map loads with 8 player slots
- Bots spawn automatically
- No console log output

**Debug test (verbose logging):**

```bash
# Navigate to test environment
cd launch\quake-spasm

# Launch with debug flags
quakespasm.exe -basedir . -game reaper_mre -listen 8 +map dm4 +skill 3 +deathmatch 1 +maxplayers 8 +impulse 208
```

**Debug flags explained:**
- `-basedir .` — Use current directory as Quake root
- `-game reaper_mre` — Load reaper_mre mod
- `-listen 8` — Run as listen server (keeps game running for observation, prevents "server is full" exit)
- `+map dm4` — Auto-load DM4 map
- `+skill 3` — Expert difficulty (enables all AI features)
- `+deathmatch 1` — Deathmatch mode
- `+maxplayers 8` — 8 player slots
- `+impulse 208` — Mass-spawn bots command

**What happens:**
- Console output written to `qconsole.log`
- Verbose loading information displayed
- Bot spawn messages logged
- All errors/warnings captured

**In-game console commands:**

```
skill 0           // Novice bots (IQ 1.0)
skill 1           // Intermediate (IQ 1.5)
skill 2           // Advanced (IQ 2.0)
skill 3           // Expert (IQ 3.0, full features)

impulse 100       // Add 1 bot
impulse 101       // Fill server with bots
impulse 102       // Remove 1 bot
impulse 208       // Mass-spawn bots
```

---

#### Workflow: Verifying Functionality

**Step 1: Check console log**

```bash
type launch\quake-spasm\qconsole.log
```

**Success indicators:**
```
Quake 1.09 (c) id Software
...
execing quake.rc
...
Programs occupy 376K.
...
Cheater (iq 1) is reformed Thanks Chris.
Cheat (iq 1) is reformed Thanks Chris.
<more bot spawn messages>
```

**Failure indicators:**
- `Host Error: <message>` — Critical failure, progs.dat didn't load
- `SV_Error: <message>` — Runtime error in QuakeC code
- No bot spawn messages — Bots not spawning
- `Bad entity field` — Field definition error in botit_th.qc

**Expected warnings (safe to ignore):**
```
Couldn't load gfx/ipx.cfg.
CD track 2 not found
Couldn't exec config.cfg
```

**Step 2: Test specific features**

**Rocket jumps (skill 3 required):**
- Maps: DM3, DM4 (have high ledges)
- Watch bots near high platforms
- Should see upward rocket blast + jump
- Verify no suicide at low HP (<50)
- Check cooldown (2 seconds between RJs)

**Train navigation:**
- Map: DM6 (has func_train entities)
- Watch bots near moving platforms
- Should intercept trains at future positions
- No "stuck" loops near trains
- Bots should ride trains smoothly

**Platform prediction:**
- Maps: DM3, DM5 (have moving platforms)
- Watch bots jump onto rising/falling platforms
- Precise mid-air landings
- Follow platform motion after landing

**Combat AI:**
- Skill 3 bots should use all weapons tactically
- Grenade launcher lobs at distant targets
- Rocket conservation (don't spam)
- Evasion patterns vs enemy rockets

**Step 3: Performance check**

**Verify no stuck loops:**
- Watch bots for 2-3 minutes
- Should not spin in corners
- Should escape geometry traps (rocket jump, super jump)
- Movement should be fluid

**Verify FPS stability:**
- Check console: `host_framerate` command
- Should maintain ~60 FPS with 8 bots
- No stuttering or freezes

---

#### Workflow: Documentation Updates

**After verifying features work, update documentation:**

**Step 1: Update source code comments**

Add comments in `.qc` files:
```quakec
// ============================================================
// Feature Name
// ============================================================
// Description of what this function/section does
// Parameters: self = bot entity
// Returns: TRUE if success, FALSE if failure
// ============================================================
float() example_function =
{
    // Implementation
};
```

Example: See `bot_rocket_jump()` in [botmove.qc:627-667](reaper_mre/botmove.qc#L627-L667)

**Step 2: Update CHANGELOG.md**

Add entry to "## Unreleased" section:

```markdown
## Unreleased

- **Feature category name** for [navigation|combat|tactics|physics]:
  - **Implementation detail** in `reaper_mre/file.qc`: Technical description with function names, algorithms, mechanics. Explain what problem it solves and how.
  - **Integration point** in `reaper_mre/file.qc`: Where/how feature integrates with existing systems.
  - Added `.float field_name` field in `reaper_mre/botit_th.qc` for [purpose].
```

**Step 3: Update README.md**

Add to appropriate feature table:

```markdown
| Feature | Description |
|---------|-------------|
| 🆕 **Your Feature** | Concise description of capability and benefit |
```

Update if needed:
- Quick Start section — if launch process changed
- Skill Levels table — if bot behavior changed
- Testing Maps — if map-specific features added

**Step 4: Verify documentation**

```bash
# Check markdown renders correctly
type README.md
type CHANGELOG.md

# Verify file references
dir reaper_mre\botmove.qc
dir reaper_mre\botit_th.qc
```

---

#### Workflow: Git Commit and Push

**Step 1: Check status**

```bash
git status
```

**Expected changes:**
- Modified: `reaper_mre/*.qc` files
- Modified: `CHANGELOG.md`
- Modified: `README.md`
- Untracked: None (reaper_mre/*.qc should be tracked)

**Note:** `progs.dat` files should NOT appear (ignored by .gitignore)

**Step 2: Stage changes**

```bash
# Stage source code
git add reaper_mre/

# Stage documentation
git add CHANGELOG.md README.md

# Verify staged files
git status
```

**Step 3: Create commit**

```bash
git commit -m "Add [feature name]: [brief description]

[Detailed description paragraph explaining what was added, why, and what problem it solves]

Technical changes:
- Enhanced [file.qc] with [specific function/logic]
- Added [field name] to botit_th.qc for [purpose]
- Updated [system] to integrate with [new feature]
"
```

**Good commit message example:**
```
Add enhanced rocket jump system: safe controlled navigation

Replaced crude "turn and fire" rocket jump with sophisticated system featuring health checks (<50 HP suicide prevention), 2-second cooldown, precise pitch/yaw control (90° down + 180° backward), and synchronized jump timing.

Technical changes:
- Implemented bot_rocket_jump() in botmove.qc with safety checks
- Added .float rj_cooldown field to botit_th.qc for spam prevention
- Enhanced Bot_tryjump() to trigger RJ for high ledges (>1.5× MAXJUMP)
- Upgraded desperate unstuck to use enhanced RJ instead of crude fire
```

**Step 4: Push to GitHub**

```bash
git push origin master
```

**Success indicators:**
```
Enumerating objects: X, done.
Counting objects: 100% (X/X), done.
Delta compression using up to Y threads
Compressing objects: 100% (X/X), done.
Writing objects: 100% (X/X), Z KiB | Z MiB/s, done.
Total X (delta Y), (reused Z) (delta W)
To https://github.com/saworbit/mre
   abc1234..def5678  master -> master
```

**Step 5: Verify GitHub Actions CI**

1. Go to [GitHub Actions](https://github.com/saworbit/mre/actions)
2. Check latest workflow run
3. Verify "Build Reaper MRE" workflow succeeded
4. Download artifact `reaper_mre-progs.dat` to verify build

---

#### Quick Reference: Common Tasks

**Rebuild after code change:**
```bash
cd c:\reaperai
tools\fteqcc_win64\fteqcc64.exe -O3 reaper_mre\progs.src
copy reaper_mre\progs.dat launch\quake-spasm\reaper_mre\progs.dat /Y
```

**Quick test:**
```bash
cd launch\quake-spasm
launch_reaper_mre.bat 8 dm4
```

**Debug test:**
```bash
cd launch\quake-spasm
quakespasm.exe -basedir . -game reaper_mre -listen 8 +map dm4 +skill 3 +deathmatch 1 +maxplayers 8 +impulse 208
```

**Check logs:**
```bash
type launch\quake-spasm\qconsole.log
```

**Full workflow (one command block):**
```bash
cd c:\reaperai && tools\fteqcc_win64\fteqcc64.exe -O3 reaper_mre\progs.src && copy reaper_mre\progs.dat launch\quake-spasm\reaper_mre\progs.dat /Y && copy reaper_mre\progs.dat ci\reaper_mre\progs.dat /Y
```

---

### Documentation Update Workflow

**After adding new features:**

1. **Update source code comments:**
   - Add `// =====` section headers in `.qc` files
   - Document function purpose, parameters, return values
   - Example: See `bot_rocket_jump()` in `reaper_mre/botmove.qc:627-667`

2. **Update CHANGELOG.md:**
   ```markdown
   ## Unreleased

   - **Feature name** for category:
     - **Implementation** in `file.qc`: Description with technical details...
   ```

3. **Update README.md:**
   - Add feature to appropriate table (Navigation/Combat/Tactical/Physics)
   - Update Quick Start if workflow changes
   - Update skill level descriptions if behavior changes

4. **Test and verify:**
   - Compile → Deploy → Launch → Test
   - Check `qconsole.log` for errors
   - Verify feature works as documented

5. **Commit:**
   ```bash
   git add reaper_mre/ CHANGELOG.md README.md
   git commit -m "Add [feature]: [description]"
   git push
   ```

---

## 📚 Documentation

- 📖 **[CHANGELOG.md](CHANGELOG.md)** — Detailed feature history
- 🎮 **[launch/quake-spasm/README.md](launch/quake-spasm/README.md)** — Testing guide + console commands
- 📜 **[Readme.txt](Readme.txt)** — Historical archive + feature summary

---

## 🎯 Skill Levels

Bots adapt their behavior based on skill setting (`skill 0-3`):

| Skill | IQ | Behavior |
|-------|-----|----------|
| **0** | 1.0 | 🟢 Novice — Basic navigation, simple aim |
| **1** | 1.5 | 🟡 Intermediate — Item awareness, better prediction |
| **2** | 2.0 | 🟠 Advanced — Powerup denial, evasion tactics |
| **3** | 3.0 | 🔴 Expert — Rocket jumps, spawn memory, adrenaline bursts |

**Set in-game:**
```
skill 3           // Max difficulty
impulse 100       // Add bot
impulse 102       // Remove bot
```

---

## 🧪 Testing Maps

| Map | Name | Best For | Players |
|-----|------|----------|---------|
| **dm2** | Claustrophobopolis | 🎯 Close combat, powerup denial | 4-6 |
| **dm3** | Abandoned Base | 🏃 Movement, platform navigation | 6-8 |
| **dm4** | The Bad Place | ⚔️ All-around combat, rocket jumps | 8-12 |
| **dm5** | The Cistern | 🌊 Water navigation, vertical play | 4-8 |
| **dm6** | The Dark Zone | 🔫 Long-range combat, train timing | 6-10 |

---

## 🤝 Contributing

Contributions are welcome! Please:

1. 🍴 Fork the repository
2. 🌿 Create a feature branch (`git checkout -b feature/amazing-ai`)
3. 💾 Commit your changes (`git commit -m 'Add amazing AI feature'`)
4. 📤 Push to the branch (`git push origin feature/amazing-ai`)
5. 🎉 Open a Pull Request

---

## 📜 License

This project builds upon the classic **Reaper Bot** (1998) with modern enhancements.

- 🤖 **Original Reaper Bot:** Public domain / community project
- ✨ **MRE Enhancements:** See repository license

---

## 🙏 Credits

- 🎮 **Original Reaper Bot** — Steven Polge & community (1998)
- 🤖 **Omicron Bot** — Mr Elusive (AI architecture inspiration)
- 🔧 **FTEQCC Compiler** — FTE QuakeWorld team
- 🎨 **QuakeSpasm Engine** — QuakeSpasm developers
- 🧠 **MRE AI Systems** — Modern enhancements (2026)

---

## 🔗 Links

- 📦 **GitHub Releases:** [Latest progs.dat builds](https://github.com/saworbit/mre/releases)
- 🐛 **Issue Tracker:** [Report bugs](https://github.com/saworbit/mre/issues)
- 💬 **Discussions:** [Share strategies](https://github.com/saworbit/mre/discussions)
- 📊 **CI Status:** [Build pipeline](https://github.com/saworbit/mre/actions)

---

<div align="center">

**Made with ❤️ for the Quake community**

🎮 *"Frag like it's 1996... with 2026 AI"* 🤖

[⬆ Back to Top](#-modern-reaper-enhancements-mre)

</div>
