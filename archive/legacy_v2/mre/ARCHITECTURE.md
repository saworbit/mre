# Reapbot v2 Architecture

## Goals
- Single authoritative control loop per tick.
- Clear ownership of state.
- Pluggable decision logic without competing brains.
- Deterministic, debuggable behavior.

## Data flow (single tick)
```
Bot_Tick
  ├─ Perception_Update   (inputs, traces, visibility)
  ├─ Memory_Update       (BotState only)
  ├─ Decide              (BotState -> Intent)
  ├─ Act                 (Intent -> Command)
  └─ Apply_Command       (write outputs once)
```

## Core data model
- BotState (single source of truth, per-bot fields)
  - Perception snapshot (visible enemy, last seen time, sound cues)
  - Memory (cooldowns, last intent, last goal, timers)
  - Derived state (threat level, navigation mode)
- Intent (lightweight, per-tick decision output)
  - Examples: Idle, MoveTo, AimAt, Fight
- Command (final output, written once per tick)
  - Move: forward/side, desired speed
  - Aim: yaw/pitch
  - Action: attack/use/jump

## Interface boundaries
1) Perception
   - Only reads engine state and traces.
   - Writes to Perception fields in BotState.
2) World state / memory
   - Updates BotState from Perception.
   - No movement or aim writes.
3) Decision
   - Single function per tick: `Decide(state) -> intent`.
   - No side-effects outside intent selection.
4) Action selection
   - `Intent -> Command` mapping.
   - The only place that writes movement/aim/fire outputs.

## Debug and trace
- Structured logging: one-line decision summary with intent + key factors.
- Per-tick trace buffer (ring buffer) with enable + dump.
- Debug toggles are player-only to avoid bot-triggered flips.

## File layout (v2)
- `rb2_defs.qc`: v2 constants and BotState fields.
- `rb2_log.qc`: logging + trace ring buffer.
- `rb2_tick.qc`: tick loop, perception/decision/apply pipeline.
- `botthink.qc`: thin wrapper calling the v2 tick and shared post-think checks.
- `botspawn.qc`: bootstraps v2 state and assigns v2 think.

## Determinism rules
- One tick entry point (`RB2_Tick`) per frame.
- No module writes outputs except Apply_Command.
- All cross-module data flows through BotState fields.
