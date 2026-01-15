// Reapbot v2 core constants and per-bot state fields.
float RB2_INTENT_IDLE = 0.000;
float RB2_INTENT_MOVE = 1.000;
float RB2_INTENT_AIM  = 2.000;
float RB2_INTENT_FIGHT = 3.000;

// Debug toggles (player-controlled via impulses).
float rb2_debug_enabled;
float rb2_trace_enabled;

// Ring buffer size for per-tick trace messages.
float RB2_TRACE_MAX = 8.000;

// === Per-bot v2 state ===
.float rb2_last_tick_time;
.float rb2_intent;
.string rb2_intent_reason;
.entity rb2_enemy;
.float rb2_enemy_seen_time;
.float rb2_has_enemy;
.vector rb2_cmd_move;
.vector rb2_cmd_aim;
.float rb2_cmd_attack;

// Trace ring buffer (strings).
.float rb2_trace_index;
.float rb2_trace_count;
.string rb2_trace0;
.string rb2_trace1;
.string rb2_trace2;
.string rb2_trace3;
.string rb2_trace4;
.string rb2_trace5;
.string rb2_trace6;
.string rb2_trace7;
