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

// Influence Map System (ai_influence.qc)
entity (vector org) FindClosestWaypoint;
float (entity wp) Influence_GetDanger;
float (entity wp) Influence_GetInterest;
void (vector org, float amount) Influence_AddDanger;
void (vector org, float amount) Influence_AddInterest;
void () Influence_ShowMap;
// ---------------------------------------------------------
