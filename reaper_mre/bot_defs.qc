// ---------------------------------------------------------
// SHARED BOT PROTOTYPES (Eliminates copy-paste errors)
// ---------------------------------------------------------

// Movement controller modes/styles (single-writer movement).
float BOT_MOVE_NONE = 0.000;
float BOT_MOVE_STAND = 1.000;
float BOT_MOVE_SEEK = 2.000;
float BOT_MOVE_RUN = 3.000;
float BOT_MOVE_CHASE = 4.000;
float BOT_MOVE_CHARGE = 5.000;
float BOT_MOVE_NAILCHARGE = 6.000;

float BOT_MOVE_STYLE_NONE = 0.000;
float BOT_MOVE_STYLE_HOLD = 1.000;
float BOT_MOVE_STYLE_ADVANCE = 2.000;
float BOT_MOVE_STYLE_RETREAT = 3.000;
float BOT_MOVE_STYLE_STRAFE = 4.000;

// Aim ownership (debug/arbiter)
float AIM_OWNER_NONE = 0.000;
float AIM_OWNER_COMBAT = 1.000;
float AIM_OWNER_NAV = 2.000;
float AIM_OWNER_IDLE = 3.000;
float AIM_OWNER_SOUND = 4.000;
float AIM_OWNER_UNSTICK = 5.000;

// Debug telemetry events
float DBG_EVT_GOAL_CHANGE = 1.000;
float DBG_EVT_AIM_OWNER_CHANGE = 2.000;
float DBG_EVT_INTENT_CHANGE = 3.000;
float DBG_EVT_UNSTICK_ENTER = 4.000;
float DBG_EVT_UNSTICK_EXIT = 5.000;
float DBG_EVT_APPLY_COUNT = 6.000;

// Reason codes (keep small, shared taxonomy)
float R_NONE = 0.000;
float R_COMBAT_SEEN_ENEMY = 1.000;
float R_COMBAT_TAKING_DAMAGE = 2.000;
float R_COMBAT_HUNT_TARGET = 3.000;
float R_COMBAT_ENEMY_TOUCHED = 4.000;
float R_SOUND_HEARD = 5.000;
float R_IDLE_SCAN = 6.000;
float R_TRIGGER_BUTTON = 7.000;
float R_TRIGGERED = 8.000;
float R_NAV_ITEM_PICKUP = 9.000;
float R_NAV_ROAM = 10.000;
float R_NAV_GLOBAL = 11.000;
float R_GOAL_CHOOSE = 12.000;
float R_GOAL_CHOOSE_PATH = 13.000;
float R_GOAL_AIR_SEEK = 14.000;
float R_GOAL_STACK = 15.000;
float R_GOAL_FIXATE_RESET = 16.000;
float R_GOAL_FIXATE_AVOID = 17.000;
float R_GOAL_PLAT_RESET = 18.000;
float R_SPAWN_IDLE = 19.000;
float R_GOAL_GOODY_PICK = 20.000;
float R_GOAL_GOODY_FALLBACK = 21.000;
float R_GOAL_GOODY_END = 22.000;
float R_GOAL_GOODY_RESET = 23.000;
float R_AMBUSH = 24.000;
float R_UNSTICK_NO_PROGRESS = 25.000;
float R_UNSTICK_TERRAIN = 26.000;
float R_UNSTICK_LOOP = 27.000;

// Bot finder helper functions (since bots now use classname "player")
entity (entity start) findbot;  // Find next bot after start entity

float () CheckWaterLevel;
float (entity target) Bot_IsAvoidedTarget;
void () CheckForHazards;
float () bot_rocket_jump;
void (float dist) ai_botrun;
void (float dist) ai_botseek;
void () ai_botstand;
void (float dist) ai_botcharge;
void (float dist) ai_botnailcharge;
void (float dist) aibot_chase;
float (entity e) itemweight;

// Projectile Prediction System (botmath.qc)
vector (vector perfect_aim, float skill_level) DegradeAimBySkill;
void (vector aim_dir, entity targ, float range, float is_degraded) ShowPredictionDebug;

// PID Aiming Controller (botmath.qc)
float (float ang) Math_AngleDiff;
float (entity bot, float current_ang, float ideal_ang, float dt, float axis_idx) Math_PID;
void (float req_yaw, float req_pitch, float set_yaw, float set_pitch, float owner, float reason_code, string reason) Bot_RequestAim;
void () Bot_UpdateAimPID;

// Goal Arbitration (botgoal.qc)
void (entity owner, float pri, float commit_secs, entity ent, vector org, float reason_code, string reason) Bot_RequestGoal;

// Intent Requests (botmove.qc)
void (entity bot, float intent, float pri, float commit_secs, float reason_code, string reason) Bot_RequestIntent;
void (entity bot, float mode, float style, float pri, float commit_secs, entity target, vector org, float speed) Bot_RequestMove;
void (float mode, float dist) Bot_RequestMoveMode;
float (float yaw, float dist) Bot_WalkMove;
void () Bot_MoveControllerApply;

// Frame structure (botthink.qc)
void () Bot_FrameBegin;
void () Bot_Arbitrate;
void () Bot_FrameApply;

// Debug telemetry (botdebug.qc)
void (entity bot) Bot_DbgTraceTick;
void (entity bot, float event_type, float a, float b, float reason_code, string reason) Bot_DbgEvent;
void () Bot_DbgToggle;
void () Bot_DbgDumpTraceCmd;
void () Bot_DbgDumpEventsCmd;

// LOS helper (botmove.qc)
float (entity bot, vector pos, entity target) Bot_LOSClassFrom;

// Influence Map System (ai_influence.qc)
entity (vector org) FindClosestWaypoint;
float (entity wp) Influence_GetDanger;
float (entity wp) Influence_GetInterest;
void (vector org, float amount) Influence_AddDanger;
void (vector org, float amount) Influence_AddInterest;
void () Influence_ShowMap;

// Dynamic Breadcrumbing System (botmove.qc)
void () Breadcrumb_Update;
vector () Breadcrumb_GetRecoverySpot;

// Terrain Trap Resolver (botmove.qc)
float (entity bot) Bot_IsTerrainTrap;
vector (entity bot) Bot_PickTerrainEscape;
void (entity bot) Bot_HandleTerrainTrap;

// Intent Escalation (botmove.qc)
float (entity bot) Bot_IntentSucceeded;
float (entity bot) Bot_IntentTimeout;
void (entity bot) Bot_UpdateIntentFail;
void (entity bot) Bot_EscalateIntent;
void (entity bot) Bot_OnPickup;
void (entity bot) Bot_OnEnemySeen;
void (entity bot) Intent_Driver;

// Flow Governor (botmove.qc)
void (entity bot) FG_Tick;
void (entity bot, float pri, float drv, vector goalDir, float secs) FG_Request;

// Vertical Reposition Driver (botmove.qc)
float (entity bot, entity e) VT_HasLOS;
float (entity bot, entity e) VT_VerticalMode;
vector (entity bot, entity e) VT_PickRepositionDir;
void (entity bot) VT_Driver;
// ---------------------------------------------------------
