# Impulse Commands Reference

**Modern Reaper Enhancements (MRE)** - Complete impulse command guide

All impulse commands are entered in the Quake console using the format:
```
impulse <number>
```

---

## 🎮 Core Gameplay

### Weapon Selection (Standard Quake)

| Impulse | Weapon | Notes |
|---------|--------|-------|
| `1` | Axe | Melee weapon |
| `2` | Shotgun (SG) | Always available |
| `3` | Super Shotgun (SSG) | Close range |
| `4` | Nailgun (NG) | Rapid fire |
| `5` | Super Nailgun (SNG) | High DPS |
| `6` | Grenade Launcher (GL) | Area denial |
| `7` | Rocket Launcher (RL) | Explosive damage |
| `8` | Lightning Gun (LG) | Instant hitscan |

---

## 🤖 Bot Management

### Bot Control

| Impulse | Function | Description |
|---------|----------|-------------|
| `208` | **Add Bot** | Spawns a new bot with random name and skill |

**Usage:**
```
impulse 208
```

**Notes:**
- Bots spawn with random skill levels (50% novice, 20% intermediate, 20% advanced, 10% expert)
- Requires `maxplayers` slots available
- Bot names: Cheater, Drooly, Wanton, Assmunch, etc.

---

## 🐛 Debug System

### Debug Logging

| Impulse | Function | Player Only? | Description |
|---------|----------|--------------|-------------|
| `95` | **Debug Toggle** | ✅ Yes | Enable/disable bot debug logging |
| `96` | **Verbosity Cycle** | ✅ Yes | Cycle through 6 verbosity levels |
| `97` | **Feeler Debug** | ✅ Yes | Toggle feeler steering exploration logs |

### Debug Verbosity Levels (impulse 96)

Press `impulse 96` repeatedly to cycle through:

1. **LOG_OFF (0)** - No logging
2. **LOG_CRITICAL (1)** - Stuck/failures only
3. **LOG_NORMAL (2)** - Target/goal changes *(default)*
4. **LOG_TACTICAL (3)** - + Weapon switches, combos, profiling
5. **LOG_VERBOSE (4)** - + Movement, routing, perception
6. **LOG_DEBUG (5)** - Everything (very spammy!)

**Quick Start:**
```
impulse 95    // Turn on logging
impulse 96    // Cycle to LOG_TACTICAL (recommended for combat analysis)
```

**Console Output Examples:**

**LOG_NORMAL:**
```
[BotName] TARGET: EnemyName (score=850, HP=45, dist=320u)
[BotName] GOAL: item_rockets (score=500, dist=180u)
```

**LOG_TACTICAL:**
```
[Cheater] WEAPON: GL → SSG (GL-suicide-prevent)
[Wanton] COMBO: RL → LG (Juggler shaft-combo)
[Drooly] PROFILE: player is AGGRESSIVE (8.7) → Retreat & Trap
```

**LOG_VERBOSE:**
```
[Assmunch] HEAR: Wanton (weapon-fire)
[Cheater] FEELER: Exploration mode activated (no waypoints nearby)
```

---

## 📹 AI Cameraman (Spectator System)

### Camera Activation

| Impulse | Function | Requires Bots? | Description |
|---------|----------|----------------|-------------|
| `99` | **Enter AI Director** | ✅ Yes | Converts player to AI-controlled camera |
| `98` | **Exit Camera** | No | Return to player mode |

### Camera Modes (requires impulse 99 first!)

| Impulse | Mode | Description |
|---------|------|-------------|
| `50` | **Flyby** | Cinematic orbiting camera |
| `51` | **Follow** | Over-shoulder tracking |
| `53` | **Free-flight** | Manual camera control |
| `60` | **Toggle Info** | Show/hide HUD info |
| `61` | **Cycle Player** | Switch to next bot |
| `99` | **AI Director** | Return to auto-tracking mode |

### Complete Camera Workflow

**Step 1: Setup**
```
skill 3           // Set difficulty
impulse 208       // Spawn bots (repeat 3-4 times for good action)
```

**Step 2: Activate Camera**
```
impulse 99        // Enter AI Director mode
```

You should see:
```
===========================================
  AI CAMERAMAN ACTIVATED (impulse 99)
===========================================
Auto-tracking most exciting action!

Controls:
  impulse 50 = Flyby mode (cinematic)
  impulse 51 = Follow mode (over-shoulder)
  impulse 53 = Free-flight camera
  impulse 60 = Toggle info display
  impulse 61 = Cycle to next player
  impulse 98 = EXIT camera (return to player)
  impulse 99 = Return to AI Director
```

**Step 3: Control Camera**
```
impulse 50        // Switch to cinematic flyby
impulse 51        // Switch to follow mode
impulse 61        // Cycle between bots
impulse 99        // Back to AI auto-tracking
```

**Step 4: Exit**
```
impulse 98        // Return to player
```

**AI Director Features:**
- Automatically tracks most exciting action
- Scores combat intensity, health drama, powerup plays
- Smooth flyby transitions between targets
- Re-evaluates best target every 2 seconds

---

## 🗺️ Navigation & Learning

### Waypoint Management

| Impulse | Function | Usage | Description |
|---------|----------|-------|-------------|
| `100` | **Dump Waypoints** | Any time | Exports navigation network to console |

**Usage:**
```
// After playing for 5-10 minutes:
impulse 100
quit

// Then extract from qconsole.log
python tools/bot_memory_manager.py auto
```

**Output Format:**
```
======================================
WAYPOINT DUMP (timestamp)
======================================
// ===== CUT HERE: WAYPOINTS FOR THIS MAP =====
SpawnSavedWaypoint('-272 160 -152', 45.3, 12.1);
SpawnSavedWaypoint('128 -64 24', 89.2, 67.4);
// ... more waypoints
// ===== CUT HERE: END WAYPOINTS =====
// Total Nodes: 127
======================================
```

---

## 🎓 Player Observation Learning

### Technique Recording

| Impulse | Function | Player Only? | Description |
|---------|----------|--------------|-------------|
| `199` | **Observation Mode** | ✅ Yes | Record player techniques for bot learning |

**Phase 1: Offline Learning**
```
impulse 199       // Enable observation
// Perform rocket jumps to strategic locations
impulse 199       // Disable observation
quit

// Extract learned techniques
python tools/learn_rj_from_player.py qconsole.log dm4
```

**Phase 2: Live Learning**
```
impulse 199       // Enable observation
// Bots learn rocket jump techniques in REAL-TIME!
// No Python script needed - instant waypoint spawning
```

**Console Feedback:**
```
PLAYER OBSERVATION: ENABLED
  Recording player techniques for bot learning:
  - Rocket jump detection (self-damage events)
  - Position, velocity, angles, timing
  - Strategic context (nearby items, goals)

Live Learning: Bots learned rocket jump from Player (pitch=-29.5°, vel=234.8 u/s, total=3/50)
Live Learning: Bots learned rocket jump from Player (pitch=-32.1°, vel=256.3 u/s, total=4/50)
```

**Memory Limit:** 50 learned RJ waypoints per map (auto-removes oldest)

---

## 🎯 Quick Reference by Use Case

### "I want to watch bots fight"
```
skill 3
impulse 208       // Spawn bot 1
impulse 208       // Spawn bot 2
impulse 208       // Spawn bot 3
impulse 208       // Spawn bot 4
impulse 99        // AI camera spectator mode
```

### "I want to analyze bot behavior"
```
impulse 95        // Enable debug logging
impulse 96        // Cycle to LOG_TACTICAL
impulse 96        // Or cycle to LOG_VERBOSE for full detail
// Play for 5 minutes
quit
// Analyze logs
python tools/analyze_bot_logs.py qconsole.log
```

### "I want to teach bots new techniques"
```
impulse 199       // Enable observation
// Perform rocket jumps or trick jumps
// Bots learn automatically (live mode)
impulse 199       // Disable when done
```

### "I want to save navigation data"
```
// Play with bots for 10+ minutes
impulse 100       // Dump waypoints
quit
// Extract and merge
python tools/bot_memory_manager.py auto
```

### "I want to debug stuck bots"
```
impulse 95        // Enable logging
impulse 96        // Cycle to LOG_CRITICAL (shows stuck events)
impulse 97        // Enable feeler debug (exploration tracking)
// Observe bot behavior
```

---

## ⚠️ Important Notes

### Player-Only Impulses

These impulses are **restricted to human players** only (bots cannot trigger them):

- `95` - Debug toggle
- `96` - Verbosity cycling
- `97` - Feeler debug
- `199` - Observation mode

**Why?** These modify global state and should only be controlled by the human player.

### Camera Prerequisites

**CRITICAL:** You MUST spawn bots BEFORE activating camera mode:

```
❌ WRONG:
impulse 99        // No bots spawned - nothing to watch!
impulse 50        // Won't work yet

✅ CORRECT:
impulse 208       // Spawn bots first
impulse 208       // Spawn more bots
impulse 99        // Now camera works
impulse 50        // Flyby mode active
```

### Impulse Range Limits

Quake engine truncates impulses to 8-bit (0-255):
- ✅ `impulse 99` - Valid (within range)
- ✅ `impulse 208` - Valid (within range)
- ❌ `impulse 300` - Gets truncated to `44` (300 % 256)

All MRE impulses are within the safe 0-255 range.

---

## 📊 Impulse Summary Table

| Range | Category | Count | Description |
|-------|----------|-------|-------------|
| 1-8 | Weapons | 8 | Standard Quake weapon selection |
| 95-97 | Debug | 3 | Logging controls (player-only) |
| 50-61, 98-99 | Camera | 8 | AI Cameraman spectator system |
| 100 | Navigation | 1 | Waypoint dump |
| 199 | Learning | 1 | Player observation mode (player-only) |
| 208 | Bots | 1 | Add bot |

**Total Custom Impulses:** 14 (plus 8 standard weapon impulses)

---

## 🔗 See Also

- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Full development guide with debug pipeline
- **[CHANGELOG.md](CHANGELOG.md)** - Feature history and implementation details
- **[PLAYER_OBSERVATION_LEARNING.md](PLAYER_OBSERVATION_LEARNING.md)** - In-depth learning system guide
- **[WAYPOINT_DUMP_GUIDE.md](WAYPOINT_DUMP_GUIDE.md)** - Navigation system details
- **[tools/analyze_bot_logs.py](tools/analyze_bot_logs.py)** - Log analysis tool
- **[tools/bot_memory_manager.py](tools/bot_memory_manager.py)** - Waypoint extraction tool

---

**Last Updated:** 2026-01-07
**Project:** Modern Reaper Enhancements (MRE)
**Build:** 492,994 bytes (Fuzzy Logic)
