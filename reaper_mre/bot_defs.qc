// ---------------------------------------------------------
// SHARED BOT PROTOTYPES (Eliminates copy-paste errors)
// ---------------------------------------------------------

// Bot finder helper functions (since bots now use classname "player")
entity (entity start) findbot;  // Find next bot after start entity

float () CheckWaterLevel;
float (entity target) Bot_IsAvoidedTarget;
void () CheckForHazards;
float () bot_rocket_jump;
void (float dist) ai_botrun;
void (float dist) ai_botseek;
float (entity e) itemweight;

// Projectile Prediction System (botmath.qc)
vector (vector perfect_aim, float skill_level) DegradeAimBySkill;
void (vector aim_dir, entity targ, float range, float is_degraded) ShowPredictionDebug;

// PID Aiming Controller (botmath.qc)
float (float ang) Math_AngleDiff;
float (entity bot, float current_ang, float ideal_ang, float dt, float axis_idx) Math_PID;
void (float req_yaw, float req_pitch, float set_yaw, float set_pitch) Bot_RequestAim;
void () Bot_UpdateAimPID;

// Goal Arbitration (botgoal.qc)
void (entity owner, float pri, float commit_secs, entity ent, vector org, string reason) Bot_RequestGoal;

// Intent Requests (botmove.qc)
void (entity bot, float intent, float pri, float commit_secs, string reason) Bot_RequestIntent;

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
