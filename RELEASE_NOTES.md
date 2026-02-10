# Reapbot v1.0.0 - The Community Reboot

**The classic Reaper Bot, rebuilt from source with 28 community-reported issues fixed.**

Reaper Bot was one of the first and most popular Quake 1 bots, but accumulated bugs and quirks over the years that frustrated players. This release addresses every major complaint from the community while preserving the bot's original character.

---

## What's Fixed

### Stability (No More Crashes)
- **Single-player crash to DOS** - Edict overflow from waypoints now capped properly
- **Multiplayer lockups** - Fixed exponential route recursion (was 6^12 worst case)
- **Scoreboard overflow crash** - Guard added when adding bots beyond maxplayers
- **Infinite loop in void** - Safety counter prevents hang during jump simulation

### Movement (Smooth and Natural)
- **Jumpy/teleport strafing** - Removed sub-frame timing that broke interpolation
- **"Flashing" near water** - Stricter teleport checks prevent visual glitches
- **Stuck running in place** - Position delta detection + jump attempts to escape
- **Walking off lifts** - Platform state detection keeps bots on moving lifts
- **Stuck at doors** - Bots now trigger doors and back up to let them open

### Fairness (No More "Cheater" Bots)
- **Ganging up on players** - Target selection now picks closest enemy, not first human
- **Vacuum pickup** - Items no longer vanish before bot reaches them (48-unit check)
- **Low-skill felt like cheaters** - Aim jitter increased from ~10° to ~25° at skill 0
- **Camping best weapons** - Bots ignore owned weapons when ammo is sufficient

### Combat Safety (Smarter Decisions)
- **Suicidal explosives** - Switch weapons when enemy is within 150 units
- **Thunderbolt in water** - Switch weapons to avoid self-discharge
- **Walking into lava/slime** - Hazard avoidance with powerup awareness
- **Attacking observers** - Bots now ignore spectators and dead players

### Physics (Proper Interactions)
- **Explosion knockback** - Bots can now be bounced by rockets (velocity preserved when airborne)
- **Backpack spawning** - No longer spawn inside walls or void

### Aiming
- **Over-leading targets** - Predictive aim capped at 0.5s to prevent wild shots

### Compatibility
- **sv_aim warning spam** - Now warns once per map instead of every bot spawn

---

## New Features

### High Skill Levels (skill 0-10)
The original skill cap of 3 has been raised to 10. Skills 4+ are "god mode" bots with perfect aim and faster reactions - great for training or challenge runs.

```
skill 5    // Set before adding bots
```

### Quick-Add Bot (impulse 100)
Standard convention from Frogbot and other bots. Type `impulse 100` in console to instantly add a bot.

```
impulse 100    // Add one bot immediately
```

### Specter Gaze (Cinematic Spectator)
Watch bot matches with a smooth, film-like camera system.

- `impulse 105` to toggle, `impulse 106` to cycle focus
- Two-layer architecture: Think computes ideal positions, ViewUpdate interpolates at ~72fps
- Drama-driven auto-switching: cameras follow the most exciting bot (no random cuts)
- Chase mode (`specter_chase 1`) for first-person through bot's eyes
- Geometry-based angle computation eliminates jitter and wrapping bugs

### Vortex Telechains + Lift Routing (Reboot Extensions)
- **Telechains**: bots detect teleporter warps and fuse one-way tele edges, enabling safe multi-tele flanks while avoiding cursed exits.
- **Lift Routing**: timed platform nodes add wait-cost biasing for smoother lift routing.

### Intelligence Update (Skill-Differentiated Humanization)
Bots now feel like different-skilled human players rather than identical machines.

- **Aim**: Exponential jitter scaling (skill 0 = ~30 deg miss, skill 5+ = perfect). Pitch jitter from Mirage Minds adds vertical tracking imperfection.
- **Reactions**: First shot delayed after spotting enemy (skill 0 = 300ms, skill 4+ = instant).
- **Prediction**: Non-linear depth curve (skill 0 = 3 steps, skill 10 = 16 steps).
- **Retreat**: Gradual probability curve based on effective health (health + armor), not hard cutoff. Zigzag strafing while retreating (±30° weave).
- **Combat**: Ammo-aware weapon switching, blind fire memory, item grab threat abort. Weapon distance scoring (RL penalized at range, SNG mid-range bonus). Splash risk override (finish kills at close range). Target commitment (150u momentum, near-dead loyalty). Fast-kill hitscan boost (LG/SNG to finish <25 HP enemies). Ambush weapon safety (no RL/GL pre-fire at close range).
- **Powerups**: Quad holders fight to the death (skip retreat). Bots with <80 eff HP flee enemy Quad. Score pressure: losing bots (-5 frags) fight harder, winning bots play safer.
- **Range**: Weapon-range engagement nudges bots toward optimal distance (LG: 250u, SNG: 350u, RL: 500u, SSG: 200u).
- **Movement**: Adaptive strafe timing with ±25% jitter, combat bunny hopping for skilled bots, skill-scaled ambush patience and turn speed (18-30°/frame). Speed-scaled whisker distance for smoother high-speed navigation.
- **Items**: Distance-weighted goal selection, doubled search radius (1200u), effective HP health weight (armored bots fight), ammo urgency for RL/LG. Skill-scaled goal re-evaluation (1.5-3.5s). Effective HP armor weight (red armor correctly valued over green).
- **Humanization**: Multi-axis Mirage Minds with pitch jitter, glance-aways, and variable hold-fire feints.
- **Camera**: Specter Gaze enhanced with low-health duel and recent combat drama bonuses.

---

## Investigated Issues (Not Found / Already Working)

These community complaints were investigated but no bugs were found in the baseline code:

- **"Extra SNG ammo"** - Bots use identical ammo as players (2 nails/shot)
- **"Firing faster"** - Bots use identical attack timings as players
- **"Respawn splash sound"** - Spawn uses correct teleport sounds
- **"Floating after respawn"** - Spawn already uses MOVETYPE_STEP
- **"Bot frags not shown"** - MSG_UPDATEFRAGS messages sent correctly; likely fixed by 0-index fix

---

## Non-Issues (Engine/Content)

These are not bot bugs:

- **Score display at intermission** - Standard Quake behavior
- **Scoreboard colors** - Engine limitation, modern ports handle correctly
- **MultiSkin unreliable** - Code works; requires player.mdl with 16 skins

---

## Quick Start

### Build
```powershell
.\ci\build_mre.ps1
```

### Run
```batch
cd launch\quake-spasm
launch_reapbot_v2.bat 8 dm4
```

### In-Game Commands
| Command | Description |
|---------|-------------|
| `impulse 100` | Add one bot |
| `impulse 105` | Toggle Specter Gaze (cinematic spectator) |
| `impulse 106` | Cycle Specter camera focus |
| `impulse 205` | Remove one bot |
| `impulse 200` | Cycle observer mode |
| `skill 0-10` | Set bot difficulty (before adding) |
| `specter_chase 1` | First-person chase mode (use with Specter) |

---

## Credits

- **Steven Polge** - Original Reaper Bot author
- **Community** - Bug reports and testing over 25+ years
- **This reboot** - Systematic fix of all reported issues

---

## Links

- [Full Changelog](CHANGELOG.md)
- [Issue Tracker](mre/COMMUNITY_ISSUES.md)
- [Research Sources](mre/SOURCES.md)
