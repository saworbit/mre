# Reapbot v1 (MRE) Postmortem

## What is broken
- Conflicting movement and aim outputs show up as runtime warnings and jitter: `walkmove outside controller`, `apply count > 1`, and `angles overridden` logs indicate multiple writers fighting the same outputs. (See `archive/legacy_v1/reaper_mre/botmove.qc`, `archive/legacy_v1/reaper_mre/botthink.qc`)
- Stuck recovery loops keep re-triggering (unstick re-rolls, hazard retries, loop breakers) without stable escape, resulting in bots oscillating or freezing in place. (`archive/legacy_v1/reaper_mre/botmove.qc`)
- Arbitration churn frequently overrules goals, intents, and moves, leading to short-lived commitments and non-deterministic behavior between ticks. (`archive/legacy_v1/reaper_mre/botthink.qc`)
- Angle control is non-deterministic: PID aim writes angles, while other code paths still write angles later in the tick. This causes aim drift or snapback. (`archive/legacy_v1/reaper_mre/botmath.qc`, `archive/legacy_v1/reaper_mre/botthink.qc`)
- No automated tests are present; failure modes are found only by runtime logs and in-game behavior.

## Likely root causes
- Multiple control loops with overlapping authority (Flow Governor, move controller, intent escalation, goal arbitration) act on the same outputs in the same tick. (`archive/legacy_v1/reaper_mre/botmove.qc`, `archive/legacy_v1/reaper_mre/botthink.qc`)
- Per-tick state is reset from multiple modules; `Bot_FrameBegin` is called from disparate subsystems, creating ordering dependencies and accidental state loss. (`archive/legacy_v1/reaper_mre/botgoal.qc`, `archive/legacy_v1/reaper_mre/botmove.qc`, `archive/legacy_v1/reaper_mre/botmath.qc`)
- State duplication and ambiguous ownership: goal/intent/move requests plus pending queues, each with its own commit windows, allow several subsystems to think they own the bot in the same frame. (`archive/legacy_v1/reaper_mre/botit_th.qc`, `archive/legacy_v1/reaper_mre/botthink.qc`)
- Global trace globals are overwritten by helper traces, corrupting caller decisions mid-frame. (`DEVELOPMENT.md`, “Trace Globals Are Shared”)
- Debug instrumentation reveals symptoms but is entangled with control flow, making it hard to reason about correctness.

## Lessons learned
- Enforce one authoritative tick loop and one writer per output (movement, aim, fire).
- Keep per-tick state in one place and update it exactly once per frame.
- Separate perception, decision, and action stages; avoid hidden side-effects in helpers.
- Keep trace state local and restore globals after helper traces.
- Avoid mixing arbitration layers; prefer a single decision function and explicit command output.

## Salvageable components
### Safe to salvage
- Math utilities and pure functions (e.g., `qc_sqrt`, `PredictAim`, angle helpers) from `archive/legacy_v1/reaper_mre/botmath.qc`.
- Small, isolated helpers that do not mutate global state (vector math, scalar clamps).
- Base QuakeC gameplay code outside of bot logic (weapons, items, world).
- Simple logging patterns if kept side-effect free.

### Not safe to salvage
- Flow Governor and multi-priority arbitration layers. (`archive/legacy_v1/reaper_mre/botmove.qc`)
- Per-tick request queues and pending-request handoffs for goal/intent/move. (`archive/legacy_v1/reaper_mre/botthink.qc`, `archive/legacy_v1/reaper_mre/botit_th.qc`)
- PID aim integration that competes with other writers, even if “fixed” by `fixangle`.
- Unstick/loop-breaking systems tightly coupled to the old arbitration system.
- Any logic that writes outputs outside of the single authoritative tick.
