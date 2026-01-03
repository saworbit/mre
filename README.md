# 🤖 Modern Reaper Enhancements (MRE)

> **Bringing 90s Quake bots into the modern era with advanced AI, physics-based navigation, and human-like combat tactics**

[![Build](https://img.shields.io/badge/build-passing-brightgreen)]() [![Quake](https://img.shields.io/badge/Quake-1-brown)]() [![Bot AI](https://img.shields.io/badge/AI-Enhanced-blue)]()

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
- 🎯 **Precise aim control** — 90° pitch down + 180° backward for optimal arc
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
| 🛡️ **Self-Risk Validation** | Aborts GL fire if self-splash risk < 128u |
| 🔫 **Weapon-Aware Evasion** | Rocket zigzags, strafe flips, LG jump bias |

### 🧠 Tactical AI

| Feature | Description |
|---------|-------------|
| 📊 **Risk-Aware Scoring** | Need-based item boosts minus threat penalty (proximity -80 max) |
| 🏆 **Powerup Denial** | Amplified aggression when leading or enemy weak (<40 HP) |
| 🔄 **Adaptive Goals** | Health when hurt, denial when leading, smart roam patterns |
| 💰 **Weapon Conservation** | Rocket economy, Quad/Pent counters, ammo awareness |
| 🔥 **Adrenaline Focus** | Tighter aim + faster think cycles under pressure |
| 🧩 **Spawn Memory** | High-skill bots pre-cache key routes at spawn |
| 📈 **Streak Tuning** | Dynamic difficulty based on kill/death streaks |

### 🏃 Physics Systems

| Feature | Description |
|---------|-------------|
| 🌪️ **Air Velocity Clamp** | Skill-scaled caps (320-400 u/s) prevent bunny-hop exploits |
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

### Compile MRE

1. **Navigate to project root:**
   ```bash
   cd c:\reaperai
   ```

2. **Run the compiler:**
   ```bash
   tools\fteqcc_win64\fteqcc64.exe -O3 reaper_mre\progs.src
   ```

3. **Deploy to test environment:**
   ```bash
   copy reaper_mre\progs.dat launch\quake-spasm\reaper_mre\progs.dat /Y
   ```

4. **Launch and test:**
   ```bash
   cd launch\quake-spasm
   launch_reaper_mre.bat 8 dm4
   ```

### CI Pipeline

GitHub Actions automatically compiles `progs.dat` on every push:

- 📦 **Artifact:** `reaper_mre-progs.dat`
- 🔍 **Size:** ~380 KB (optimized with `-O3`)
- ✅ **Status:** Check [Actions tab](../../actions)

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
- 🔧 **FTEQCC Compiler** — FTE QuakeWorld team
- 🎨 **QuakeSpasm Engine** — QuakeSpasm developers
- 🧠 **MRE AI Systems** — Modern enhancements (2026)

---

## 🔗 Links

- 📦 **GitHub Releases:** [Latest progs.dat builds](../../releases)
- 🐛 **Issue Tracker:** [Report bugs](../../issues)
- 💬 **Discussions:** [Share strategies](../../discussions)
- 📊 **CI Status:** [Build pipeline](../../actions)

---

<div align="center">

**Made with ❤️ for the Quake community**

🎮 *"Frag like it's 1996... with 2026 AI"* 🤖

[⬆ Back to Top](#-modern-reaper-enhancements-mre)

</div>
