## Historical Archive

### Do-it-yourself Reaper (Original 1998 Instructions)

This section preserved for historical reference. See README.md for modern MRE setup.

Original instructions for obtaining and decompiling the Reaper Bot v0.81 source code:
- Reaper Bot ver 0.81 (164 KB)
- proqcc compiler/decompiler (87 KB)
- rip011a.txt decompilation guide (34 KB)

1998 patch notes included scoreboard display, weapon switching fixes, floating gibs/backpacks,
rocket bounce physics, corrected sounds, and chase cam feature.

---

## Modern Reaper Enhancements (MRE)

This repository contains an enhanced version of the classic Reaper bot with modern AI improvements:

**Latest: Enhanced Rocket Jump System** (2026-01)
- Directional RJ mechanics: Dynamic geometry-based aim (85° pitch for high ledges, 45° for gaps), yaw aims toward goal
- Aggressive leap: 3× forward velocity (-320 u/s) enables gap crossing to DM2 Quad and similar platforms
- Enhanced reachability: Recognizes items up to 450u high as reachable, actively seeks and RJs to them
- Smart high-ledge trigger: Proactive RJ when height >1.5× normal jump (skill >2 only)
- Safe unstuck upgrade: Enhanced RJ replaces crude fire (prevents suicide/spam)
- Pro movement: Context-aware high jumps and long jumps like human speedrunners
- Health checks (no suicide <40 HP), 2s cooldown (prevents spam), synchronized jump timing

**Previous: Platform Mastery System** (2026-01)
- Enable learning on elevators: Removed restriction preventing breadcrumb drops on moving platforms
- Platform node tagging: Detects and tags nodes on func_plat/func_train via downward traceline (64u)
- Platform awareness: pathweight ignores height restrictions for platform nodes (no "too high" rejections)
- Elevator patience: Bots wait at lift shafts (>64u high, <200u distance), look up, reset stuck timers

**Previous: Navigation Persistence System** (2026-01)
- Smart spacing optimization: 250u distance + LOS checks prevent node clumping (clean navigation networks)
- Brain dump exporter: Export learned waypoints to console (impulse 100) for manual persistence
- Waypoint loader: Import saved nodes to "bake" map knowledge (instant memory between sessions)
- Console command hookup: impulse 100 triggers dump with user-friendly broadcast messages

**Previous: Train Navigation Enhancements** (2026-01)
- Path_corner chain traversal: Two-pass algorithm predicts train positions along multi-segment paths
- Train path prediction: Movement/jump/reachability systems use path chain instead of velocity guess
- Train surf escape: Desperate unstuck detects trains beneath bot, boosts with momentum (1.5x)
- Precise train timing: Bots intercept moving trains at future positions (human-like coordination)

**Previous: Advanced Navigation Suite** (2026-01)
- Platform prediction: Velocity + state-based position forecasting for timed jumps (moving plats/trains)
- Jump arc platform landing: Mid-air platform detection enables precise airborne platform targeting
- Button shoot + wait: Auto-fires visible shootables, monitors door state for fluid secret navigation
- Ride platform auto-follow: Velocity inheritance + goal tracking for seamless vertical travel
- Desperate unstuck: Rocket jump/super jump escape after 5+ stuck attempts (human exploits)

**Recent AI Enhancements:**
- Air physics suite: Velocity clamp (320-400 u/s), jump smoothing, mid-air correction
- Physics navigation: 0.05s arc timesteps, strafe momentum, 2x trace density
- Grenade launcher mastery: Bounce prediction, gravity arc physics, self-risk validation
- Tactical decision-making: Risk-aware item scoring, conditional denial rush, stuck rotation
- Predictive aim with splash height variance, vertical lead, and velocity-history smoothing
- Human-like aim smoothing: Pitch slew rate (150-450°/s by skill) replaces aimbot snap-lock
- Wall sliding + combat hopping: Vector slide movement plus active bunny-hopping (skill >1)
- Smart backpack scavenging: Bots prioritize dropped backpacks (3000 weight if missing RL/LG, +2000 when ammo-starved)
- Weapon counter-tactics: Rock-paper-scissors logic (RL counters LG with knockback, LG counters RL with hitscan)
- Global scavenger hunt: Map-wide item scan when alone (RL/LG/RA/Mega prioritization vs random wander)
- Problem solver: Dynamic obstacle solving (RJ for high items, button-door linking, shootable detection)
- Spawn camping: Timer-based item control (camps RL/Quad/RA/Mega respawns <10s, waits at spawn points)
- Circle strafing: Smooth 1.5s orbital movement (80° spiral-in, harder to predict)
- Retreat trap: Drops grenade when fleeing (10% chance) to punish pursuers
- Ambush mode: Investigates combat sounds (1000u range) for opportunistic third-party kills
- Portal awareness: Teleporter shortcuts (auto-register, wormhole linking, exploration priority)
- Splash damage mastery: Floor shooting (aim at feet for guaranteed splash), corner clipping (indirect splash around obstacles), suicide prevention (safe weapons at melee range)
- Powerup denial logic for quad/pent/ring contesting (now amplified when leading/enemy weak)
- Adaptive goal selection (health when hurt, denial when leading)
- Weapon conservation (rocket economy, Quad/Pent counters)
- Adrenaline mechanics (tighter aim + faster think cycles under pressure)
- Spawn memory (high-skill bots pre-cache key routes)
- Streak-based skill tuning (dynamic difficulty)
- Route caching with blockage detection and velocity-shift replans
- Weapon-aware evasion (rocket dodges, strafe flips, LG jump bias)
- Movement recovery (stuck detection with escalating sidesteps)
- Enhanced vision (corner-peek traces, idle scan sweeps)

**Quick Start:**
1. Navigate to `launch/quake-spasm`
2. Run `launch_reaper_mre.bat 8 dm4` for instant 8-player deathmatch
3. See `CHANGELOG.md` for full feature history
4. See `launch/quake-spasm/README.md` for detailed testing guide