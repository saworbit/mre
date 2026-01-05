# Development Guide - Modern Reaper Enhancements (MRE)

## QuakeC Development Best Practices

This guide documents common pitfalls, best practices, and important conventions for developing MRE.

---

## 🚨 Critical Issues to Avoid

### 1. System Globals Section (progdefs.h error)

**ISSUE:** Adding global variables before `void end_sys_globals;` in `defs.qc` causes runtime crash.

**Error Message:**
```
Host_Error: progs.dat system vars have been modified, progdefs.h is out of date
```

**Root Cause:**
The Quake engine expects system globals (defined before `end_sys_globals`) to match a fixed memory layout in `progdefs.h`. Adding, removing, or reordering these globals breaks the engine's memory expectations.

**What Happened (Historical):**
```c
// ❌ WRONG - Added bot_debug_enabled BEFORE end_sys_globals in defs.qc
.entity groundentity;
float bot_debug_enabled;  // This line broke the engine!
void end_sys_globals;
```

Build compiled successfully (458,974 bytes) but failed to load in Quake with progdefs.h error at line 46.

**The Fix:**
```c
// ✅ CORRECT - Add mod globals in botit_th.qc AFTER end_sys_globals
// In defs.qc - keep system globals untouched:
.entity groundentity;
void end_sys_globals;  // DO NOT ADD/REMOVE/REORDER ANYTHING ABOVE THIS LINE!

// In botit_th.qc - add mod-specific globals here:
float bot_debug_enabled;  // Safe location for new globals
```

**Safe Locations for New Globals:**
1. **`reaper_mre/botit_th.qc`** (lines 1-20) - Preferred for mod-specific globals
2. **After `end_sys_fields` marker in `defs.qc`** - For new entity fields (`.float` / `.entity` / `.vector`)

**How to Recognize System Globals Section:**
```c
// defs.qc structure:
entity self;              // System globals start here
entity other;
entity world;
// ... more system globals ...
void end_sys_globals;     // System globals END here - DO NOT MODIFY ABOVE!

// Safe area starts here - can add entity fields:
.float health;
.entity enemy;
// ... custom entity fields OK here ...
void end_sys_fields;      // Entity fields end here

// botit_th.qc - Safe for mod globals:
float bot_debug_enabled;
float SKINSMODE;
// ... custom globals OK here ...
```

**When You See This Error:**
1. Check recent changes to `defs.qc` before `end_sys_globals`
2. Move any new globals to `botit_th.qc` (lines 1-20)
3. Move any new entity fields to after `end_sys_fields` in `defs.qc`
4. Recompile with FTEQCC
5. Redeploy `progs.dat`

**Prevention:**
- Never touch `defs.qc` lines 1-47 (before `end_sys_globals`)
- Add forward declarations in `botit_th.qc` instead
- Comment any globals with their purpose and location

---

### 2. Impulse Command Scope (Player vs Bot Execution)

**ISSUE:** Impulse commands in `ImpulseCommands()` execute for ALL entities (players + bots), not just the human player.

**What Happened (Historical):**
```c
// ❌ WRONG - Bot AI can execute this during think cycle
if ((self.impulse == 95.000))
{
    bot_debug_enabled = !bot_debug_enabled;  // Global flag toggled by bots!
}
```

User entered `impulse 95` to enable debug logging (worked), then later tried to disable it. Between the two commands, a bot entity executed `impulse 95` during its think cycle (`PlayerPostThink()` → `W_WeaponFrame()` → `ImpulseCommands()`), toggling the global flag back. User appeared unable to disable logging.

**The Fix:**
```c
// ✅ CORRECT - Restrict to human player only
if ((self.impulse == 95.000) && (self.classname == "player"))
{
    bot_debug_enabled = !bot_debug_enabled;  // Only player can toggle
}
```

**Entity Classes:**
- `classname == "player"` → Human player
- `classname == "dmbot"` → Reaper bot
- `classname == "watcher"` → Spectator mode
- `classname == "KasCam"` → Camera spectator

**When to Use Player-Only Check:**
- Console commands (developer tools)
- Debug toggles
- Admin functions
- UI state changes (anything affecting global state)

**When Bots CAN Execute:**
- Weapon switching (impulse 1-8)
- Bot-specific commands (impulse 208 for addbot)
- Normal gameplay impulses

**Prevention:**
- Always ask: "Should bots be able to trigger this?"
- For global state changes, add `&& (self.classname == "player")`
- For per-entity state, ensure entity field usage (`.float` not `float`)
- Test with multiple bots to verify toggle behavior

---

### 3. Impulse Truncation (8-bit Limit)

**ISSUE:** Quake engine truncates impulse values to 8-bit range (0-255). Values >255 get reduced via modulo.

**What Happened (Historical):**
```c
// User entered: impulse 400
// Engine received: 400 % 256 = 144
// Result: Wrong impulse handler executed (or no handler)
```

Camera activation impulse 400 never worked because engine silently converted it to 144.

**The Fix:**
Use impulses in 0-255 range:
```c
// ✅ CORRECT - All camera controls remapped to safe range
impulse 50  = Flyby mode (was 300)
impulse 51  = Follow mode (was 301)
impulse 53  = Free-flight (was 303)
impulse 60  = Toggle info (was 310)
impulse 61  = Cycle player (was 317)
impulse 98  = EXIT camera (was 400)
impulse 99  = AI Director (was 400)
```

**Safe Impulse Ranges:**
- **1-8**: Weapon switching (reserved by Quake)
- **10-50**: Mod gameplay features
- **50-99**: Advanced features (camera, debug tools)
- **100-199**: Bot management
- **200-255**: Future expansion

**Prevention:**
- Always use impulses ≤255
- Document impulse assignments in code comments
- Test impulses in-game to verify they trigger correctly

---

## 🛠️ Build & Deploy Workflow

### Compilation
```bash
# Option 1: Direct compile (manual)
cd c:\reaperai\reaper_mre
..\tools\fteqcc_win64\fteqcc64.exe -O3 progs.src

# Option 2: CI script (recommended - includes validation)
powershell -File c:\reaperai\ci\build_reaper_mre.ps1
```

### Deployment Locations
```bash
# Source build output:
c:\reaperai\reaper_mre\progs.dat

# Launch location (for testing):
c:\reaperai\launch\quake-spasm\reaper_mre\progs.dat

# CI artifact (for GitHub Actions):
c:\reaperai\ci\reaper_mre\progs.dat

# Deploy command:
copy c:\reaperai\ci\reaper_mre\progs.dat c:\reaperai\launch\quake-spasm\reaper_mre\progs.dat /Y
```

### Testing
```bash
# Launch with debug logging:
cd c:\reaperai\launch\quake-spasm
quakespasm.exe -basedir C:\reaperai\launch\quake-spasm -game reaper_mre -condebug +developer 1 +sv_gravity 800 -listen 8 +maxplayers 8 +deathmatch 1 +map dm4

# Or use batch script:
launch_reaper_mre.bat 8 dm4

# Check logs:
c:\reaperai\launch\quake-spasm\qconsole.log
```

---

## 📝 Code Conventions

### Forward Declarations
Always declare cross-file functions in `botit_th.qc`:
```c
// botit_th.qc
void () CamClientInit;   // Defined in kascam.qc
void () CamClientExit;   // Defined in kascam.qc
```

### Entity Fields vs Globals
```c
// Entity field (per-bot state) - prefix with dot
.float juggler_cooldown;   // Each bot has own cooldown timer

// Global variable (shared state) - no dot prefix
float bot_debug_enabled;   // One flag for entire game
```

### Commenting Style
```c
// ===== SECTION HEADER (Feature Name) =====
// Brief description of what this code does

void () MyFunction =
{
   // Implementation comments in sentence case
   local float my_var;

   // Explain non-obvious logic
   if (complex_condition)
   {
      // Why we do this...
   }
};
```

---

## 🐛 Debugging Tips

### Enable Console Logging
```bash
quakespasm.exe -condebug +developer 1
```

### Bot Debug Output (impulse 95)
Shows real-time decision making:
```
[BotName] TARGET: EnemyName (score=X, HP=Y, dist=Zu)
[BotName] GOAL: item_name (score=X, dist=Yu)
```

### Common Warnings (Safe to Ignore)
```
- F314: Implicit cast from void() to void(entity attacker, float damage)
- Q302: Variable no references (unused locals)
- F210: Sound not directly precached (precached elsewhere)
- Q206: Not all control paths return a value (intentional in some AI functions)
```

### Critical Errors (Must Fix)
```
- Unknown field "X" in class "entity" → Field not defined in defs.qc
- Undefined function "X" → Missing forward declaration in botit_th.qc
- progdefs.h out of date → System globals modified (see Section 1 above)
```

---

## 📚 File Structure

```
reaper_mre/
├── defs.qc          # System globals, entity fields, constants (DO NOT MODIFY LINES 1-47!)
├── botit_th.qc      # Forward declarations, mod globals (SAFE for new globals)
├── weapons.qc       # Weapon logic, ImpulseCommands
├── kascam.qc        # Camera system
├── botmove.qc       # Movement AI
├── botgoal.qc       # Goal selection
├── bot_ai.qc        # Target selection, combat AI
├── botfight.qc      # Weapon selection, attack logic
├── botroute.qc      # A* pathfinding
└── progs.src        # Build manifest
```

---

## 🎯 Feature Development Checklist

Before submitting new features:

- [ ] Code compiles without errors (`FTEQCC -O3`)
- [ ] Tested in-game with 8 bots on dm4/dm6
- [ ] No system globals modified (defs.qc lines 1-47 untouched)
- [ ] Forward declarations added to botit_th.qc if needed
- [ ] Player-only check added to impulse commands if modifying global state
- [ ] Impulse values ≤255 if adding new impulse commands
- [ ] Documentation updated (README.md + CHANGELOG.md)
- [ ] Comments explain non-obvious logic
- [ ] Build size noted in CHANGELOG (check progs.dat bytes)
- [ ] Committed with clear message explaining "why" not just "what"

---

## 📊 Data-Driven Improvement Pipeline

MRE uses a scientific approach to bot tuning: measure behavior → analyze patterns → implement targeted fixes → validate improvements.

### The Pipeline

**Step 1: Instrument & Collect**
```bash
# Enable debug logging in-game
impulse 95

# Play test match (8 bots, 5 minutes)
cd c:\reaperai\launch\quake-spasm
launch_reaper_mre.bat 8 dm4

# Let bots play for 5 minutes, then exit Quake
# Debug logs saved to: qconsole.log
```

**Step 2: Analyze Patterns**
```bash
# Run log analyzer
python c:\reaperai\tools\analyze_bot_logs.py c:\reaperai\launch\quake-spasm\qconsole.log

# Example output:
# Combat engagement rate: 14.1% (bots idle 86% of time)
# Target switches: 109 per bot (EXCESSIVE)
# Goal diversity: 94% rockets/armor only
```

**Step 3: Identify Issues**

The analyzer suggests improvements based on thresholds:
- **Low engagement (<20%)**: Increase movement speed, improve vision range, add goal bias toward high-traffic areas
- **High switching (>20/bot)**: Increase target commitment time, add hysteresis to target scoring
- **Low switching (<3/bot)**: Decrease scan_time interval, lower selection thresholds
- **Low goal diversity (<5 unique)**: Increase weight for underutilized items, add randomization

**Step 4: Implement Targeted Fixes**

Example: High target switching (109/bot)
```c
// BEFORE (bot_ai.qc:1287)
self.scan_time = (time + 0.500); // Check twice a second

// AFTER
self.scan_time = (time + 1.500); // Check every 1.5s (3x reduction)

// ADD HYSTERESIS (bot_ai.qc:1286-1316)
// Only switch if new target has clear advantage:
// - Attacking us (self-defense)
// - 300+ units closer (proximity)
// - 30+ HP weaker (easy kill)
```

**Step 5: Validate Improvements**
```bash
# Compile changes
cd c:\reaperai\reaper_mre
..\tools\fteqcc_win64\fteqcc64.exe -O3 progs.src

# Deploy
copy progs.dat ..\launch\quake-spasm\reaper_mre\progs.dat /Y

# Play test match with impulse 95 enabled
# Re-run analyzer on new logs
python ..\tools\analyze_bot_logs.py ..\launch\quake-spasm\qconsole.log

# Compare metrics:
# OLD: 109 switches per bot, 14.1% engagement
# NEW: 64.8 switches per bot (40% reduction), 60.5% engagement (4.3× increase) ✓
```

**Step 6: Commit with Data**
```bash
git add reaper_mre/bot_ai.qc
git commit -m "Bot Behavior Tuning: Fix High Target Switching (Data-Driven)

Analyzed bot debug logs with Python analyzer tool and implemented
targeted fixes for performance issues identified through data analysis.

Log Analysis Results:
- Target switching: 109 switches per bot (excessive flip-flopping)

Fixes Implemented:
- Reduced scan_time from 0.5s to 1.5s (3x reduction)
- Added hysteresis (require clear advantage before switching)

Expected: 109 → ~36 switches per bot (67% reduction)
Build: 459,246 bytes"
```

### Real-World Example: Target Switching Fix (2026-01-05)

**Problem Identified:**
- Analyzer showed 109 target switches per bot (excessive)
- Bots flip-flopping between similar-score targets
- Combat effectiveness reduced by distraction

**Root Cause Analysis:**
- `scan_time = 0.5s` → bots re-evaluate targets twice per second
- No hysteresis → small score differences cause switches
- Result: Constant target changes, incomplete kills

**Data-Driven Fixes:**
1. **Reduced scan frequency**: 0.5s → 1.5s (3× longer commitment)
2. **Added hysteresis**: Require clear advantage (attacking, closer, weaker)

**Actual Results (Validated 2026-01-05):**
- Target switching: 109 → 64.8 per bot (40% reduction)
- Combat effectiveness: Significantly improved (bots complete more kills)
- Engagement rate: 14.1% → 60.5% (4.3× increase!) ⭐ **Key win**

**Validation Method:**
- Play test with impulse 95 enabled
- Re-run analyzer on new logs
- Compare switching metrics before/after
- **Outcome:** Pipeline validated - data-driven approach works!

### Debug Logging Reference

**Current Logging:**
- `[BotName] TARGET: EnemyName (score=X, HP=Y, dist=Zu)` - When target changes
- `[BotName] GOAL: item_name (score=X, dist=Yu)` - When goal changes

**Change-Only Logging:**
- Uses entity fields `.last_logged_enemy` and `.last_logged_goal`
- Only logs when target/goal CHANGES (reduces spam from 90% to ~5%)
- Implemented in bot_ai.qc:711-737 and botgoal.qc:1225-1251

**Adding New Debug Logging:**
```c
// In bot_ai.qc or botgoal.qc
if (bot_debug_enabled && (important_decision_made))
{
   bprint ("[");
   bprint (self.netname);
   bprint ("] EVENT: ");
   bprint (event_description);
   bprint ("\n");
}
```

### Analyzer Tool Features

**Pattern Extraction:**
- Target selection patterns (combat vs idle time)
- Goal selection patterns (item diversity)
- Switching frequency (per-bot and aggregate)
- Engagement rate (combat vs searching)

**Metrics Calculated:**
- Total decision events
- Combat engagement percentage
- Target/goal switch counts
- Average switches per bot
- Goal type distribution
- Target score statistics (avg/max/min)

**Threshold-Based Suggestions:**
- Engagement <20% → Speed/vision improvements
- Switching >20/bot → Commitment/hysteresis fixes
- Switching <3/bot → Scan interval/threshold adjustments
- Goal diversity <5 → Weight/randomization tuning

### Benefits of Data-Driven Approach

**Before:**
- ❌ Gut-feeling tuning ("this feels slow")
- ❌ Guessing at parameter values
- ❌ No validation of changes
- ❌ Regression risk

**After:**
- ✅ Quantified problems ("109 switches per bot")
- ✅ Root cause analysis (scan_time too short)
- ✅ Targeted fixes (increase to 1.5s, add hysteresis)
- ✅ Measurable validation (compare metrics)
- ✅ Confidence in improvements

---

## 📖 Additional Resources

- **FTEQCC Documentation**: https://fte.triptohell.info/moodles/qc/
- **Quake C Reference**: https://www.inside3d.com/qctut/
- **Reaper Bot History**: See original `Reaprb80.txt` in launch/quake-spasm/RPBOT/
- **MRE Changelog**: See `CHANGELOG.md` for full feature history

---

**Last Updated:** 2026-01-05
**Maintainer:** reaperai project
**License:** GPL (matches original Reaper Bot)
