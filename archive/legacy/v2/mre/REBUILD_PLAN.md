# Reapbot v2 Rebuild Plan

## Milestone 0: Project skeleton + build
**Scope**
- Create `mre/` workspace, build manifest, and v2 core files.
- Wire minimal debug/trace toggles.

**Acceptance criteria**
- `mre/progs.src` builds without errors.
- `RB2_Tick` compiles and can be called from bot think.
- Debug toggles (impulse 230/231/232) print status or dump trace.

## Milestone 1: Connect to game loop + no-op bot
**Scope**
- Single tick loop runs once per frame per bot.
- No movement/aim/attack output (idle only).

**Acceptance criteria**
- Bots spawn and stay idle without errors.
- `RB2_Tick` runs once per frame (guarded by `rb2_last_tick_time`).
- Trace buffer shows per-tick entries when enabled.

## Milestone 2: Basic movement
**Scope**
- Add a simple Move intent and apply forward movement toward a target point.
- No pathfinding, only straight-line movement and simple obstacle checks.

**Acceptance criteria**
- Bots can move toward a fixed test target.
- Movement output comes only from `RB2_Apply`.
- No legacy movement systems are called.

## Milestone 3: Basic aiming
**Scope**
- Add Aim intent and aim command output.
- Use simple target selection (nearest visible enemy).

**Acceptance criteria**
- Bots rotate to face a visible enemy.
- Aim updates happen only in Apply_Command.
- Debug dump shows chosen aim target and reason.

## Milestone 4: Basic combat
**Scope**
- Fire control with simple cooldown gating.
- Use distance thresholds for weapon selection (initially one weapon).

**Acceptance criteria**
- Bots fire at visible targets with stable aim.
- No aim jitter from multiple writers.
- Trace shows intent and attack decisions per tick.

## Milestone 5: Navigation / waypointing
**Scope**
- Introduce waypoint memory or lightweight nav hints.
- Keep navigation separated from decision and apply stages.

**Acceptance criteria**
- Bots can reach key items or positions via waypoints.
- Navigation does not write movement directly (only intent).
- Movement decisions remain deterministic and traceable.
