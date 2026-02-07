# Reaper Bot Reboot: Design and Implementation Specification (Aligned)

This document is the project-aligned version of the reboot specification. It maps
spec concepts and names to the current MRE implementation in `mre/`, and provides
source references for the authoritative code.

## Architecture Overview

The bot AI follows a layered architecture with a single per-bot think loop:

- Perception layer
  - Visual: `BotFindTarget` and `BotValidTarget` in `mre/bot_ai.qc`
  - Auditory: `Bot_BroadcastNoise`, `Bot_AlertNoise`, `Bot_AnalyzeSound` in
    `mre/botnoise.qc` and `mre/bot_ai.qc`
  - Environmental: `BotDetectHazard`, `CheckWaterLevel` in `mre/botmove.qc`
    and `mre/botthink.qc`
- Decision layer
  - High-level states tracked via `AI_STATE_*` (see `mre/botit_th.qc`) and
    logged by `BotLogAI` in `mre/bot_ai.qc`
  - Core combat loop in `BotAI_Main` (`mre/bot_ai.qc`)
  - Seek/roam loop in `ai_botseek` and `BotRoam` (`mre/botgoal.qc`, `mre/bot_ai.qc`)
- Navigation layer
  - Physics-driven steering with whiskers and hazard repulsion (`BotSteer`,
    `BotDetectHazard`) in `mre/botmove.qc`
  - Dynamic waypoints, cached routes, danger/glory weighting in `mre/botroute.qc`
- Action layer
  - Low-level movement impulses via `Botmovetogoal`, `botwalkmove`,
    `BotUnderwaterMove` in `mre/botmove.qc`
  - Attack impulses via `W_BotAttack` in `mre/botfight.qc`
- Learning layer
  - Route caching and reinforcement (danger/glory, usage weighting) in
    `mre/botroute.qc`
  - Vortex Navmesh + Apex HPA* (dynamic mesh, phantom-validated edges,
    hierarchical abstraction) in `mre/ai_vortex.qc` and `mre/ai_apex.qc`
  - Vortex Telechains + Apex Lifts (teleport fusion and timed platform routing)
    in `mre/ai_vortex.qc`, `mre/bot_learn.qc`, and `mre/ai_apex.qc`
  - Weapon confidence adaptation in `mre/botfight.qc`
  - Cursed Nodes stuck-learning mesh and decay in `mre/ai_mirage.qc`
  - Silent Specters unstuck rollouts in `mre/ai_predict.qc` and `mre/botgoal.qc`

The engine calls the current `self.think` function for each bot entity at
~10Hz. Frame functions in `mre/dmbot.qc` delegate to `ai_botseek` (seek/roam)
and `BotAI_Main` (combat), which implement the decision layer.

## Key Components (Repository Mapping)

- Bot initialization: `mre/botspawn.qc` (`AddBot`, `PutBotInServer`)
  - Sets `.bot = 1` and `.skil` for bot skill (spec `.skill` maps to `.skil`)
- AI core: `mre/bot_ai.qc`, `mre/botgoal.qc`, `mre/dmbot.qc`
- Seeking/pathfinding: `mre/botgoal.qc`, `mre/botroute.qc`
- Dynamic navmesh: `mre/ai_vortex.qc`, `mre/ai_apex.qc` (with hooks in
  `mre/bot_learn.qc`, `mre/botgoal.qc`, `mre/world.qc`)
- Telechains + lift sampling: `mre/ai_vortex.qc`, `mre/ai_predict.qc`,
  `mre/bot_learn.qc`, `mre/ai_apex.qc`
- Movement/hazards/water: `mre/botmove.qc`, `mre/botthink.qc`
- Combat/prediction/displacement: `mre/botfight.qc`
- Rollout prediction: `mre/ai_predict.qc` (Shadow Puppets + Combat Crucible)
- Weapons selection: `mre/botfight.qc` (`W_BestWeapon`, `W_BestHeldWeapon`)
- Utilities and signals:
  - Visibility/FOV: `mre/botvis.qc`
  - Sound events: `mre/botnoise.qc`
  - Impulses/debug: `mre/botimp.qc`

## Detailed Implementations (Pointers to Real Code)

### 1. Bot AI Core (mre/bot_ai.qc)

- Perception and state transitions are managed in `BotAI_Main` and `ai_botseek`.
- Auditory inference and investigation are handled by:
  - `Bot_AnalyzeSound`
  - `BotAI_CheckSoundInvestigation`

Relevant functions:
- `mre/bot_ai.qc`: `BotAI_Main`, `Bot_AnalyzeSound`, `BotAI_CheckSoundInvestigation`
- `mre/botgoal.qc`: `ai_botseek`, `BotRoam`

### 2. Seeking and Pathfinding (mre/botgoal.qc, mre/botroute.qc)

- Stuck detection is implemented in `ai_botseek` (time + distance checks) with
  Silent Specters rollouts, feeler mode, and Darwin learning on failure.
- Cursed Nodes apply a decaying penalty to repeated stuck zones and bias both
  rollouts and route cost.
- Dynamic waypoints are created and linked in `mre/botroute.qc` (`botpath`,
  `DropBotPath`, `LinkNodes`, `FindAPath`).
- Route weighting incorporates node priority, link usage, and danger cost.
- Vortex Navmesh injects a temporary mesh waypoint when the current goal is
  obstructed (`Vortex_ApplyGoal` in `mre/ai_vortex.qc`), and phantom episodes
  validate mesh edges (`Vortex_RecordEpisode` in `mre/bot_learn.qc`).
- Telechains detect large warps (>500u) during phantom tracking and fuse
  one-way tele edges (`Vortex_FuseTeleChain` in `mre/ai_vortex.qc`), while
  lift nodes are sampled and given wait-cost biasing in Vortex A*.

### 3. Movement and Hazards (mre/botmove.qc)

- Steering and obstacle avoidance: `BotSteer`, `BotTraceWhisker`
- Hazard repulsion: `BotDetectHazard`
- Water control: `BotUnderwaterMove`, `Botwaterjump`, `waterupdown`
- Proactive 1-tick lookahead nudge: `BotProactiveNudge`

### 4. Combat (mre/botfight.qc)

- Predictive aiming: `leadtarget`, `BotPredictPosition`
- Tactical behaviors: ambush, blind fire, displacement kills
- Dodge and evasive movement integrated with combat loop
- **Combat Crucible**: dual-rollout combat oracle in `mre/ai_predict.qc`
  - Beam search over short horizons to choose first action
  - Skill-scaled depth/beam; hazard-aware and ammo-sensitive

### 5. Weapons (mre/botfight.qc)

- Weapon selection via weighted scoring in `W_BestWeapon`
- Water safety checks for lightning gun (avoid self-kill in water)

## Build and Testing

- Build (preferred): `ci/build_mre.ps1`
  - Default flags: `-O3`
  - Spec-aligned strict flags: set `FTEQCC_FLAGS="-O2 -Werror"`
- Manual compile:
  - `mre/`: `..\tools\fteqcc_win64\fteqcc64.exe -O3 progs.src`
- Run (QuakeSpasm example):
  - `quakespasm.exe -game mre +deathmatch 1 +map dm4 +skill 3 +maxplayers 4`
- Tests: `ci/test_stability.bat` (full), `ci/test_stability.bat --quick`

## Known Issues and Extensions

- Current regressions and notes are tracked in `KNOWN_ISSUES.md`.
- Extensions:
  - Multi-bot coordination and squad tactics
  - Waypoint ML or map annotation tools
  - Higher-order strategy goals (area control, denial, escort)

## Alignment Notes

- Spec module names map to existing files:
  - `ai_botseek.qc` -> `mre/botgoal.qc`
  - `botwpn.qc` -> weapon selection in `mre/botfight.qc`
  - `botmisc.qc` -> utilities spread across `mre/botvis.qc`, `mre/botnoise.qc`,
    `mre/botimp.qc`, `mre/botroute.qc`
- Entity fields:
  - `.skil` remains the canonical skill field.
  - `.bot` is a boolean compatibility marker for bot entities.
