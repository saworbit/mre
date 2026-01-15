# Modern Reaper Enhancements - Bot Developer's Wishlist

This document captures the fundamental engine limitations of Quake (and conservative ports like QuakeSpasm) that constrain advanced AI development, contrasting them with the capabilities needed to achieve truly modern bot behaviors.

## Context: What We're Building

Modern Reaper Enhancements (MRE) pushes QuakeC to its limits with:
- **Mathematical physics solvers** (artillery, rocket jump, gap crossing)
- **A\* pathfinding** (industry-standard graph search)
- **Traffic heatmaps** (learning which routes are popular)
- **Danger scent** (remembering where deaths occur)
- **Oracle aiming** (quadratic time-to-intercept prediction)
- **Personality-driven chat** (5 distinct bot personalities with context-aware responses)

But we're hitting walls...

---

## 1. Navigation & Pathfinding (The Performance Bottleneck)

### Current Limitation

**A\* in QuakeC:**
- Writing A\* pathfinding in QuakeC is like calculating a spreadsheet by hand
- Eats up the instruction limit (runaway loop errors) and kills FPS
- Each search iteration burns precious QuakeC cycles

**Node Limits:**
- We use physical entities (`classname "BotPath"`) for waypoints
- This hits the engine's `MAX_EDICTS` limit quickly on large maps
- Can't have dense navigation meshes for complex geometry

### The Wish

**Engine-Side Navigation Mesh:**
```c
// Builtin function for instant pathfinding
vector path_next(vector start, vector goal)
```
Returns the next waypoint directly from C++ at native speed.

**Builtin A\*:**
If full NavMesh is too much, at least a fast A\* solver:
```c
entity find_path(entity start_node, entity end_node)
```

**Impact:** Eliminate runaway loops, support 1000+ node graphs, enable dynamic path replanning every frame.

---

## 2. Persistence & File I/O (The "Soul" System)

### Current Limitation

**Amnesia:**
- When the map changes, bots forget everything
- The "Traffic Heatmap" and "Danger Scent" are lost instantly
- No continuity between matches

**No File Access:**
- Standard QuakeC cannot write to files
- Cannot save learned data between sessions
- Bots can't "remember" map knowledge

### The Wish

**File Read/Write Access:**
```c
float fopen(string filename, float mode)
void fputs(float filehandle, string text)
string fgets(float filehandle)
void fclose(float filehandle)
```

**Use Case:**
Bots learn that the hallway in dm4 is a death trap and avoid it in the next game, effectively "learning" the meta over weeks of play. Save `.mem` files with:
- Preferred routes (traffic scores)
- Danger zones (death locations)
- Item timing patterns
- Player behavior patterns

**Current Workaround:** Manual qconsole.log extraction with Python scripts (`bot_memory_manager.py`)

---

## 3. Debugging & Visualization (The "Matrix" View)

### Current Limitation

**Invisible Logic:**
- Can't see the path bots are trying to take
- Can't visualize "danger" values of nodes
- No way to see what the bot is "thinking"

**Guesswork:**
- Debugging why a bot is stuck requires guessing which traceline failed
- Must spam console with `dprint()` and parse logs manually

### The Wish

**3D Debug Drawing:**
```c
void R_DrawLine(vector start, vector end, float color, float lifetime)
void R_DrawText(vector origin, string text, float lifetime)
void R_DrawSphere(vector origin, float radius, float color)
```

**Use Case:**
- Green line showing A\* path
- Red line showing bot's aim vector
- Yellow spheres at danger nodes
- Blue text showing current goal state
- Instantly debug navigation without console spam

---

## 4. Physics & Prediction (The Aiming Solver)

### Current Limitation

**Hardcoded Constants:**
- We manually set `GRAVITY = 800`
- If a server uses `sv_gravity 600`, our grenade aim breaks
- No way to query actual physics parameters

**Poor Motion Prediction:**
- To hit a strafing player, we use a janky ring buffer of past positions (`vel_hist`)
- Extrapolation is imprecise and lags behind reality

### The Wish

**Physics Query API:**
```c
// Where will this entity be in X seconds?
vector predict_position(entity e, float time)

// Where will this projectile land?
vector predict_projectile(vector origin, vector velocity, float type)

// Query actual physics values
float get_gravity()
float get_friction()
```

**Use Case:**
- Perfect grenade lobs that adapt to custom server settings
- Accurate lightning gun leading on moving targets
- Rocket jump calculations that work on low-gravity servers

---

## 5. Sensory Inputs (Beyond "Line of Sight")

### Current Limitation

**Binary Vision:**
- `checkclient()` or `visible()` just tells us "Yes/No"
- Doesn't tell us *what* the bot sees (e.g., "I see his left arm")
- Can't distinguish between "barely visible" and "full view"

**Vague Sound:**
- `hearnoise` gives rough direction but no details
- Can't differentiate between footsteps, weapon fire, and powerup pickups

### The Wish

**Detailed Raycasts:**
```c
// Returns surface normal, texture type, hit entity
trace_t trace_detailed(vector start, vector end, float flags)
```

**Use Case:**
- Know if a floor is slime/lava before stepping on it
- Detect "head visible but body hidden" for tactical decisions
- React to specific surfaces (metal, water, slime)

**Auditory Events:**
```c
// Hook when sounds are played nearby
void OnSoundPlayed(entity source, string soundname, float volume)
```

**Use Case:**
- Hearing a "quad damage" pickup tells the bot Quad was taken (even if out of sight)
- React to weapon fire sounds to predict enemy position
- Detect teleporter sounds to anticipate enemy flanking

---

## 6. String Manipulation (The Chat System)

### Current Limitation

**Static Strings:**
- QuakeC string handling is primitive
- No string concatenation operators (`+` doesn't work)
- Must use multiple `bprint()` calls for complex messages

**Memory Intensive:**
- Each string literal consumes permanent storage
- Can't dynamically construct natural-language sentences efficiently

### The Wish

**Dynamic String Buffers:**
```c
string strcat(string a, string b)          // Concatenate
string substring(string s, float pos, float len)
float tokenize(string s)                   // Split on spaces
string argv(float n)                       // Get token N
string sprintf(string fmt, ...)            // Formatted printing
```

**Use Case:**
- Build complex personality-driven chat messages
- Construct contextual taunts ("Nice try with the rockets, %s!")
- Generate natural-sounding bot communication

---

## 7. Chat System Integration (The Missing Piece)

### Documentation Entry: Chat System Limitations

**The Problem: The "Voice" Gap**

While we can make bots act like players, making them speak like players is blocked by a fundamental architectural separation in the Quake engine.

**Player Chat:** When a human types `say "hello"`, the engine (C code) prepends a special flag (ASCII 0x01), wraps it in a specific network message (`svc_print`), and broadcasts it. The client receives this and renders it in **Gold Text** with a "beep" sound.

**Bot Chat:** QuakeC (the scripting language) is sandboxed. It can only use `bprint()`, which sends a generic "Server Message." The client renders this in **White Text** with no sound.

### Technical Constraints

**No Access to Chat Flag:**
- QuakeC strings cannot naturally contain the `0x01` byte required to trigger "Chat Mode" on the client
- Standard compilers treat `\1` as two characters (`\` and `1`), not the binary byte
- Attempted workaround in [botchat.qc:52-54](botchat.qc#L52-L54) failed - escape sequences are literal in QuakeC

**No Message Type Control:**
- We cannot manually instruct the engine to send a "Chat Packet" vs a "Console Packet"
- We are forced through the generic `bprint` pipeline
- No builtin exists for "send as chat message with proper formatting"

**Result:** Without binary hacking, bots always sound like the "Server Admin" (white text) rather than a "Player" (gold text).

### The Wish (Engine Feature Request)

To resolve this without messy binary patching, modern Quake engines need one of the following:

**New Builtin:**
```c
void chatprint(string msg)  // A function that automatically handles the 0x01 prefix and network message type
void bprint_chat(string message)  // Sends message with proper chat formatting
void sprint_chat(entity client, string message)  // Send chat to one player
```

**Escape Sequence Support:**
- Full support for standard C escape sequences (e.g., `\x01`) in the string parser
- Allow manual injection of control bytes for advanced formatting

**Impact:**
- Bot chat indistinguishable from player chat (same color, same format)
- Proper integration with chat history and logging
- No more "close but not quite" workarounds

---

## Summary of "Next Level" Requirements

| Feature | Priority | Solves... |
|---------|----------|-----------|
| **File I/O** | 🟥 CRITICAL | Long-term memory, learning maps, persistent rivalries |
| **A\* Builtin** | 🟧 HIGH | CPU usage, entity limits, smoother movement |
| **3D Debug** | 🟨 MEDIUM | Development speed, diagnosing "stuck" bots |
| **Chat API** | 🟨 MEDIUM | Authentic bot communication, proper formatting |
| **Physics Query** | 🟩 LOW | Adaptive aiming, server compatibility |
| **NavMesh** | ⬜ FUTURE | Removing need for manual waypoints entirely |

---

## Current Workarounds in MRE

Since we're targeting QuakeSpasm for maximum compatibility, we use these alternatives:

### File I/O → Manual Extraction
- **Problem:** No file write access
- **Solution:** `impulse 100` dumps waypoints to `qconsole.log`, then `bot_memory_manager.py` extracts and formats them
- **Limitation:** Requires manual intervention, not automatic

### A\* Performance → Skill Gating
- **Problem:** A\* eats CPU cycles
- **Solution:** Only enable for `skill > 2`, use simpler breadcrumb navigation for lower skills
- **Limitation:** Lower-skill bots can't use advanced pathing

### 3D Debug → Console Spam
- **Problem:** No visual debugging
- **Solution:** Extensive `dprint()` statements and log file analysis
- **Limitation:** Slow, non-visual, tedious

### Chat Color → Sound Only
- **Problem:** Can't replicate chat formatting
- **Solution:** Play `misc/talk.wav` sound effect to signal chat
- **Limitation:** Messages lack the special color/formatting of real player chat

---

## Recommendation for "Modern" Quake

**If you want these features today:** Switch target engine from "Vanilla/QuakeSpasm" to:

- **FTEQW:** Supports file I/O, A\* builtins, 3D debug lines, extended QuakeC
- **DarkPlaces:** Advanced graphics, extended QuakeC, better debugging

**However:** Sticking to QuakeSpasm ensures:
- Maximum compatibility with vanilla Quake
- Works on all platforms without engine-specific quirks
- Honors the "classic Quake" experience

**Our Choice:** QuakeSpasm + clever workarounds = authentic 1996 experience with 2026 AI.

---

## Future Vision: The "Perfect" Bot Engine

Imagine a QuakeC environment with:

1. **Persistent memory** across map changes
2. **Native pathfinding** at C++ speed
3. **Visual debugging** overlays in-game
4. **Physics queries** for perfect prediction
5. **Rich sensory input** (detailed vision, auditory events)
6. **Modern string handling** for natural chat
7. **Proper chat integration** indistinguishable from players

This would enable:
- Bots that **learn** and improve over time
- **Tactical AI** rivaling human players
- **Personality systems** with rich, context-aware communication
- **Dynamic adaptation** to server settings and player behavior
- **Tournament-ready** bots for competitive play

Until then, Modern Reaper Enhancements pushes QuakeC to its absolute limits within the QuakeSpasm constraints. 🚀

---

**Last Updated:** 2026-01-04
**Project:** Modern Reaper Enhancements (MRE)
**Status:** Documenting the ceiling we've hit, and the sky we're aiming for.
