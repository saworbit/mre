Do-it-yourself Reaper

I am sure most of you know this already, but I will tell you how to obtain the Reaper Source code.

First - download the Reaper Bot ver 0.81. I have it here. (164 KB)
Second - download the proqcc compiler/decompiler. I have it here. (87 KB)
Third - download the rip011a.txt file. I have it here. (34 KB) This text file will instruct you on how to decompile and create a readable, compilable Reaper source.
If this seems like too much work, here is the patched Reaper Bot progs.dat file (compressed down to 161 KB).
UPDATE: 2-19-98

The progs.dat file posted above is a newly patched version that corrects the following problems with the Reaper:

 

Reapers on the Scoreboard - finally got around to adding this much wanted feature of the bots and player frag totals both appearing on screen. Here is a screenshot. (40 KB)
Disappearing Weapons - fixed this bug as well as, ensured your not automatically switched to another weapon while you still have one rocket or grenade left.
Floating Gibs and Backpacks - fragged players and bots body parts/backpacks now float on the top of all liquid surfaces. Bobbing Bot heads, Very Cool!
Bounce the Reaper - added the ability of the Reaper to be "bounced" around by rocket or grenade explosions.
Corrected Reaper Sounds - reduced the damn "splash noise" the Bot makes at respawn and the Reaper also now makes the correct sound when jumping.
Chase Cam - added the "chase cam" that allows you the option to view the action from a completely different perspective. Note: I included a readme.txt file to help explain how you can adjust the camera angle anyway you want.
UPDATE: I fixed the progs.dat file, uploaded here on 2-18-98, which caused the Reaper to continue floating after respawn, so if you are having this problem download the new progs.dat file.
Here is the decompiled Reaper Bot Source code (compressed down to 107 KB). Just unzip and you will be able to get a look at the code inside any file by simply opening it with a text editor.

---

## Modern Reaper Enhancements (MRE)

This repository contains an enhanced version of the classic Reaper bot with modern AI improvements:

**Latest: Enhanced Rocket Jump System** (2026-01)
- Full RJ mechanics: Health checks, 2s cooldown, pitch/yaw control, synchronized jump timing
- Smart high-ledge trigger: Proactive RJ when height >1.5× normal jump (skill >2 only)
- Safe unstuck upgrade: Enhanced RJ replaces crude fire (prevents suicide/spam)
- Pro movement: Bots RJ to unreachable platforms like human speedrunners

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