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
| `121` | **Telemetry Toggle** | ✅ Yes | Enable/disable structured per-tick telemetry |
| `122` | **Telemetry Trace Dump** | ✅ Yes | Dump per-tick trace ring buffer |
| `123` | **Telemetry Event Dump** | ✅ Yes | Dump event ring buffer (changes only) |

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

**Telemetry Quick Start:**
```
impulse 121       // Enable structured telemetry
set bot_dbg_id 2  // (Optional) focus bot by client id
set bot_dbg_n 120 // (Optional) number of trace ticks to dump
impulse 122       // Dump trace
impulse 123       // Dump events
```

**Telemetry Cvars:**
- `bot_dbg_id` - Bot client id to dump (0 = aim at a bot or first bot)
- `bot_dbg_n` - Trace entries to dump (default 120)
- `bot_dbg_event_n` - Event entries to dump (default 20)

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

### Projectile Prediction Visualization

When `impulse 95` bot debug mode is enabled, bots display **visual particle trails** showing their projectile aim predictions in real-time.

**What You See:**

- **Blue particles** = Perfect aim (nightmare bots, skill 3)
  - Shows exact quadratic prediction with moving platform compensation
  - 10-particle trail from bot to predicted impact point
  - Particle cluster at impact location

- **Yellow particles** = Degraded aim (lower-skill bots, skills 0-2)
  - Shows aim after skill-based random offset is applied
  - Demonstrates intentional inaccuracy for difficulty scaling
  - Larger spread indicates lower skill level

**Usage:**
```
impulse 95        // Enable bot debug (also enables prediction viz)
// Watch bots fire rockets - you'll see colored particle trails
impulse 95        // Disable debug when done
```

**When to Use:**
- **Debug accuracy issues**: Verify bots are aiming correctly
- **Test platform compensation**: Confirm bots lead targets on moving trains/lifts
- **Analyze skill progression**: Compare blue (perfect) vs yellow (degraded) aim
- **Performance tuning**: Ensure prediction runs every frame without lag

**Technical Details:**
- Blue particles: Color 203 (bright blue in Quake palette)
- Yellow particles: Color 224 (bright yellow in Quake palette)
- Trail: 10 particles spaced evenly along aim vector
- Impact: 5-10 particles at predicted hit location
- Duration: ~5 seconds (standard Quake particle lifetime)

**Example Scenario:**

```
// Test moving platform compensation on DM2
map dm2
skill 3
impulse 208       // Spawn nightmare bot
impulse 95        // Enable debug visualization
// Watch bot shoot rockets at enemies riding the train
// Blue particles should lead the train's movement perfectly
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

**AI Director Features (2026-01-10 Upgrades):**
- **Motion Smoothing**: Frametime-based interpolation eliminates jitter
  - Camera movement decoupled from bot physics tick rate
  - Smooth factors: 2.0 (death), 4.0 (flyby), 10.0 (combat)
  - Angle tracking with 8× frametime multiplier for responsive action
- **Occlusion Awareness**: Only tracks visible action
  - Traces line-of-sight before scoring targets
  - Invisible bots get score=0 (no wall-staring!)
  - Exception: Quad/high-frag leaders (15+) still considered with -500 penalty
- **Intelligent Framing**: Probes multiple positions for clear shots
  - Over-the-shoulder (right): 150u back, 40u up, 40u right
  - Over-the-shoulder (left): If right blocked by wall
  - High angle fallback: 80u up, 60u back for cramped spaces
- **Action Scoring**: Prioritizes exciting moments
  - Combat intensity, mid-range fights (100-600u), rocket launcher usage
  - Fast movement (bunny hops, rocket jumps)
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

### Influence Map Visualization

| Impulse | Function | Usage | Description |
|---------|----------|-------|-------------|
| `120` | **Show Influence Map** | Any time | Visualizes danger/interest zones on waypoint network |

**Usage:**
```
impulse 120       // Display influence map for 5 seconds
developer 1       // Enable to see detailed influence calculations
```

**What it shows:**
- **Red particles**: Danger zones (recent explosions and deaths)
- **Green particles**: Interest zones (powerups and strategic points)
- **Particle intensity**: Scales with influence strength (0-100)

**Visual Output:**
- Particles spawn at waypoint locations with active influence
- Particle count: 5-50 per waypoint (scales with influence level)
- Duration: 5 seconds (particles fade naturally)
- Only shows waypoints with significant influence (>5 threshold)

**Console Output:**
```
===========================================
  INFLUENCE MAP VISUALIZATION
===========================================
Red particles = Danger zones (explosions/deaths)
Green particles = Interest zones (powerups/sounds)
Particle intensity = Influence strength (0-100)

Influence map displayed for 5 seconds.
```

**When to use:**
- **Debug tactical pathfinding**: See why bots route around certain areas
- **Verify danger propagation**: Check that explosions create proper danger zones
- **Test health-based bravery**: Low-HP bots should avoid red zones
- **Performance analysis**: Ensure influence decay is working (old zones should fade)

**Technical Details:**
- **Red particles**: Color 73 (bright red in Quake palette)
- **Green particles**: Color 115 (bright green in Quake palette)
- **Particle velocity**: `'0 0 50'` (upward drift for visibility)
- **Threshold**: Only displays waypoints with influence >5.0
- **Lazy decay**: Values recalculated on visualization (shows current state)

**Example Scenarios:**

**1. Rocket Explosion Zone**
```
// Fire rockets at choke point
impulse 120       // Shows red particle cloud at explosion site
                  // Danger spreads to neighbor waypoints with 50% falloff
                  // Wounded bots (HP<50) will route around this zone
```

**2. Death Location Avoidance**
```
// Bot dies in corridor
impulse 120       // Shows red particles at death location (30 influence)
                  // High-HP bots (HP>80) mostly ignore it
                  // Low-HP bots (HP<50) treat it as impassable
```

**3. Powerup Interest (Future)**
```
// Quad damage spawns
impulse 120       // Shows green particles at powerup location
                  // Bots prioritize paths toward green zones
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

### "I want to test projectile prediction and accuracy"
```
map dm2           // DM2 has moving train platforms
skill 3           // Nightmare bots (perfect aim)
impulse 208       // Spawn bot 1
impulse 208       // Spawn bot 2
impulse 95        // Enable debug (shows blue prediction particles)
// Watch blue trails perfectly lead targets on moving trains

skill 0           // Switch to easy bots (degraded aim)
impulse 208       // Spawn easy bot
// Compare yellow trails (intentional inaccuracy) vs blue trails
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
- `121` - Telemetry toggle
- `122` - Telemetry trace dump
- `123` - Telemetry event dump
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
| 95-97, 121-123 | Debug | 6 | Logging + telemetry controls (player-only) |
| 50-61, 98-99 | Camera | 8 | AI Cameraman spectator system |
| 100 | Navigation | 1 | Waypoint dump |
| 199 | Learning | 1 | Player observation mode (player-only) |
| 208 | Bots | 1 | Add bot |

**Total Custom Impulses:** 17 (plus 8 standard weapon impulses)

---

## 🔗 See Also

- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Full development guide with debug pipeline
- **[CHANGELOG.md](CHANGELOG.md)** - Feature history and implementation details
- **[PLAYER_OBSERVATION_LEARNING.md](PLAYER_OBSERVATION_LEARNING.md)** - In-depth learning system guide
- **[WAYPOINT_DUMP_GUIDE.md](WAYPOINT_DUMP_GUIDE.md)** - Navigation system details
- **[tools/analyze_bot_logs.py](tools/analyze_bot_logs.py)** - Log analysis tool
- **[tools/bot_memory_manager.py](tools/bot_memory_manager.py)** - Waypoint extraction tool

---

**Last Updated:** 2026-01-10
**Project:** Modern Reaper Enhancements (MRE)
**Build:** 492,994 bytes (Fuzzy Logic)
