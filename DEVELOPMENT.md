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

## 📖 Additional Resources

- **FTEQCC Documentation**: https://fte.triptohell.info/moodles/qc/
- **Quake C Reference**: https://www.inside3d.com/qctut/
- **Reaper Bot History**: See original `Reaprb80.txt` in launch/quake-spasm/RPBOT/
- **MRE Changelog**: See `CHANGELOG.md` for full feature history

---

**Last Updated:** 2026-01-05
**Maintainer:** reaperai project
**License:** GPL (matches original Reaper Bot)
