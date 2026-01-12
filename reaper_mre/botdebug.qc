// Structured debug telemetry for bot frame decisions.
// Guarded by bot_dbg_trace_enabled to keep overhead low when off.

float BOT_DBG_TRACE_LEN = 256.000;
float BOT_DBG_EVENT_LEN = 64.000;
float BOT_DBG_MAX_CLIENTS = 1.000;
float BOT_DBG_SPIN_YAW = 25.000;
float BOT_DBG_SPIN_TICKS = 10.000;
float BOT_DBG_AIM_FLIP_LIMIT = 6.000;

float DBG_FLAG_STUCK = 1.000;
float DBG_FLAG_UNSTICK = 2.000;
float DBG_FLAG_ELEVATOR = 4.000;
float DBG_FLAG_AMBUSH = 8.000;
float DBG_FLAG_HAS_ENEMY = 16.000;
float DBG_FLAG_HAS_LOS = 32.000;

float DBG_STUCK_NORMAL = 0.000;
float DBG_STUCK_UNSTICK = 1.000;

float DBG_INTENT_FIGHT = 1.000;
float DBG_INTENT_CHASE = 2.000;
float DBG_INTENT_RESUPPLY = 3.000;
float DBG_INTENT_EXPLORE = 4.000;
float DBG_INTENT_UNSTICK = 5.000;
float DBG_INTENT_HOLD = 6.000;

string bot_dbg_build = "mre-loopfix-2026-01-11d";

entity bot_dbg_focus;
float bot_dbg_focus_id;

float dbg_trace_time[256];
float dbg_trace_tick[256];
float dbg_trace_intent[256];
float dbg_trace_intent_pri[256];
float dbg_trace_intent_until[256];
vector dbg_trace_goal_org[256];
entity dbg_trace_goal_ent[256];
float dbg_trace_aim_owner[256];
float dbg_trace_aim_mode[256];
float dbg_trace_yaw[256];
float dbg_trace_pitch[256];
float dbg_trace_ideal_yaw[256];
float dbg_trace_ideal_pitch[256];
float dbg_trace_yaw_error[256];
float dbg_trace_yaw_delta[256];
float dbg_trace_move_mode[256];
float dbg_trace_move_style[256];
float dbg_trace_move_speed[256];
float dbg_trace_flags[256];

float dbg_event_time[64];
float dbg_event_tick[64];
float dbg_event_type[64];
float dbg_event_a[64];
float dbg_event_b[64];
float dbg_event_reason_code[64];
string dbg_event_reason[64];
entity dbg_event_ent_a[64];
entity dbg_event_ent_b[64];

float (entity bot) Bot_DbgTraceBase =
{
   if (!bot)
   {
      return (-1.000);
   } //end if
   if (!bot_dbg_focus)
   {
      bot_dbg_focus = bot;
      bot_dbg_focus_id = bot.fClientNo;
      bot.dbg_trace_head = 0.000;
      bot.dbg_event_head = 0.000;
   } //end if
   if (!bot_dbg_focus)
   {
      return (-1.000);
   } //end if
   if ((bot != bot_dbg_focus))
   {
      return (-1.000);
   } //end if
   return (0.000);
}; //end of the function Bot_DbgTraceBase

float (entity bot) Bot_DbgEventBase =
{
   if (!bot)
   {
      return (-1.000);
   } //end if
   if (!bot_dbg_focus)
   {
      bot_dbg_focus = bot;
      bot_dbg_focus_id = bot.fClientNo;
      bot.dbg_trace_head = 0.000;
      bot.dbg_event_head = 0.000;
   } //end if
   if (!bot_dbg_focus)
   {
      return (-1.000);
   } //end if
   if ((bot != bot_dbg_focus))
   {
      return (-1.000);
   } //end if
   return (0.000);
}; //end of the function Bot_DbgEventBase

entity (float id) Bot_DbgFindBotById =
{
   local entity bot;

   if ((id < 1.000))
   {
      return (world);
   } //end if
   bot = findbot (world);
   while (bot)
   {
      if ((bot.fClientNo == id))
      {
         return (bot);
      } //end if
      bot = findbot (bot);
   } //end while
   return (world);
}; //end of the function Bot_DbgFindBotById

entity (entity ply) Bot_DbgPickTargetFromView =
{
   local vector start;
   local vector endpos;

   if (!ply)
   {
      return (world);
   } //end if
   start = (ply.origin + ply.view_ofs);
   makevectors (ply.v_angle);
   endpos = (start + (v_forward * 2048.000));
   traceline (start,endpos,TRUE,ply);
   if ((trace_ent && trace_ent.isbot))
   {
      return (trace_ent);
   } //end if
   return (world);
}; //end of the function Bot_DbgPickTargetFromView

entity () Bot_DbgResolveTarget =
{
   local float id;
   local entity bot;

   id = cvar ("bot_dbg_id");
   if ((id > 0.000))
   {
      bot = Bot_DbgFindBotById (id);
      if (bot)
      {
         return (bot);
      } //end if
   } //end if
   bot = Bot_DbgPickTargetFromView (self);
   if (bot)
   {
      return (bot);
   } //end if
   return (findbot (world));
}; //end of the function Bot_DbgResolveTarget

void () Bot_DbgSetFocus =
{
   local entity bot;

   bot = Bot_DbgResolveTarget ();
   if (!bot)
   {
      bot_dbg_focus = world;
      bot_dbg_focus_id = 0.000;
      return;
   } //end if
   bot_dbg_focus = bot;
   bot_dbg_focus_id = bot.fClientNo;
   bot.dbg_trace_head = 0.000;
   bot.dbg_event_head = 0.000;
}; //end of the function Bot_DbgSetFocus

void (float intent) Bot_DbgPrintIntent =
{
   if ((intent == DBG_INTENT_FIGHT)) { bprint ("FIGHT"); return; }
   if ((intent == DBG_INTENT_CHASE)) { bprint ("CHASE"); return; }
   if ((intent == DBG_INTENT_RESUPPLY)) { bprint ("RESUPPLY"); return; }
   if ((intent == DBG_INTENT_EXPLORE)) { bprint ("EXPLORE"); return; }
   if ((intent == DBG_INTENT_UNSTICK)) { bprint ("UNSTICK"); return; }
   if ((intent == DBG_INTENT_HOLD)) { bprint ("HOLD"); return; }
   bprint (ftos (intent));
}; //end of the function Bot_DbgPrintIntent

void (float code) Bot_DbgPrintReason =
{
   if ((code == R_NONE)) { bprint ("NONE"); return; }
   if ((code == R_COMBAT_SEEN_ENEMY)) { bprint ("COMBAT_SEEN"); return; }
   if ((code == R_COMBAT_TAKING_DAMAGE)) { bprint ("COMBAT_HIT"); return; }
   if ((code == R_COMBAT_HUNT_TARGET)) { bprint ("COMBAT_HUNT"); return; }
   if ((code == R_COMBAT_ENEMY_TOUCHED)) { bprint ("COMBAT_TOUCH"); return; }
   if ((code == R_SOUND_HEARD)) { bprint ("SOUND"); return; }
   if ((code == R_IDLE_SCAN)) { bprint ("IDLE_SCAN"); return; }
   if ((code == R_TRIGGER_BUTTON)) { bprint ("TRIGGER_BTN"); return; }
   if ((code == R_TRIGGERED)) { bprint ("TRIGGERED"); return; }
   if ((code == R_NAV_ITEM_PICKUP)) { bprint ("NAV_ITEM"); return; }
   if ((code == R_NAV_ROAM)) { bprint ("NAV_ROAM"); return; }
   if ((code == R_NAV_GLOBAL)) { bprint ("NAV_GLOBAL"); return; }
   if ((code == R_GOAL_CHOOSE)) { bprint ("GOAL_CHOOSE"); return; }
   if ((code == R_GOAL_CHOOSE_PATH)) { bprint ("GOAL_PATH"); return; }
   if ((code == R_GOAL_AIR_SEEK)) { bprint ("GOAL_AIR"); return; }
   if ((code == R_GOAL_STACK)) { bprint ("GOAL_STACK"); return; }
   if ((code == R_GOAL_FIXATE_RESET)) { bprint ("FIXATE_RESET"); return; }
   if ((code == R_GOAL_FIXATE_AVOID)) { bprint ("FIXATE_AVOID"); return; }
   if ((code == R_GOAL_PLAT_RESET)) { bprint ("PLAT_RESET"); return; }
   if ((code == R_SPAWN_IDLE)) { bprint ("SPAWN_IDLE"); return; }
   if ((code == R_GOAL_GOODY_PICK)) { bprint ("GOODY_PICK"); return; }
   if ((code == R_GOAL_GOODY_FALLBACK)) { bprint ("GOODY_FALLBACK"); return; }
   if ((code == R_GOAL_GOODY_END)) { bprint ("GOODY_END"); return; }
   if ((code == R_GOAL_GOODY_RESET)) { bprint ("GOODY_RESET"); return; }
   if ((code == R_AMBUSH)) { bprint ("AMBUSH"); return; }
   if ((code == R_UNSTICK_NO_PROGRESS)) { bprint ("UNSTICK_NOPROG"); return; }
   if ((code == R_UNSTICK_TERRAIN)) { bprint ("UNSTICK_TERRAIN"); return; }
   if ((code == R_UNSTICK_LOOP)) { bprint ("UNSTICK_LOOP"); return; }
   bprint (ftos (code));
}; //end of the function Bot_DbgPrintReason

void (float mode) Bot_DbgPrintMoveMode =
{
   if ((mode == BOT_MOVE_NONE)) { bprint ("NONE"); return; }
   if ((mode == BOT_MOVE_STAND)) { bprint ("STAND"); return; }
   if ((mode == BOT_MOVE_SEEK)) { bprint ("SEEK"); return; }
   if ((mode == BOT_MOVE_RUN)) { bprint ("RUN"); return; }
   if ((mode == BOT_MOVE_CHASE)) { bprint ("CHASE"); return; }
   if ((mode == BOT_MOVE_CHARGE)) { bprint ("CHARGE"); return; }
   if ((mode == BOT_MOVE_NAILCHARGE)) { bprint ("NAILCHARGE"); return; }
   bprint (ftos (mode));
}; //end of the function Bot_DbgPrintMoveMode

void (float style) Bot_DbgPrintMoveStyle =
{
   if ((style == BOT_MOVE_STYLE_NONE)) { bprint ("NONE"); return; }
   if ((style == BOT_MOVE_STYLE_HOLD)) { bprint ("HOLD"); return; }
   if ((style == BOT_MOVE_STYLE_ADVANCE)) { bprint ("ADVANCE"); return; }
   if ((style == BOT_MOVE_STYLE_RETREAT)) { bprint ("RETREAT"); return; }
   if ((style == BOT_MOVE_STYLE_STRAFE)) { bprint ("STRAFE"); return; }
   bprint (ftos (style));
}; //end of the function Bot_DbgPrintMoveStyle

void (float owner) Bot_DbgPrintAimOwner =
{
   if ((owner == AIM_OWNER_NONE)) { bprint ("NONE"); return; }
   if ((owner == AIM_OWNER_COMBAT)) { bprint ("COMBAT"); return; }
   if ((owner == AIM_OWNER_NAV)) { bprint ("NAV"); return; }
   if ((owner == AIM_OWNER_IDLE)) { bprint ("IDLE"); return; }
   if ((owner == AIM_OWNER_SOUND)) { bprint ("SOUND"); return; }
   if ((owner == AIM_OWNER_UNSTICK)) { bprint ("UNSTICK"); return; }
   bprint (ftos (owner));
}; //end of the function Bot_DbgPrintAimOwner

void (float mode) Bot_DbgPrintAimMode =
{
   if ((mode == 1.000)) { bprint ("Y"); return; }
   if ((mode == 2.000)) { bprint ("P"); return; }
   if ((mode == 3.000)) { bprint ("YP"); return; }
   bprint (ftos (mode));
}; //end of the function Bot_DbgPrintAimMode

void (entity goal) Bot_DbgPrintGoalEnt =
{
   if (!goal || (goal == world))
   {
      bprint ("none");
      return ;
   } //end if
   bprint (goal.classname);
   if ((goal.isbot || (goal.classname == "player")))
   {
      bprint ("#");
      bprint (ftos (goal.fClientNo));
   } //end if
}; //end of the function Bot_DbgPrintGoalEnt

void (float flags) Bot_DbgPrintFlags =
{
   local float wrote;

   if (!flags)
   {
      bprint ("none");
      return ;
   } //end if
   wrote = FALSE;
   if ((flags & DBG_FLAG_STUCK))
   {
      bprint ("stuck");
      wrote = TRUE;
   } //end if
   if ((flags & DBG_FLAG_UNSTICK))
   {
      if (wrote) bprint (",");
      bprint ("unstick");
      wrote = TRUE;
   } //end if
   if ((flags & DBG_FLAG_ELEVATOR))
   {
      if (wrote) bprint (",");
      bprint ("elev");
      wrote = TRUE;
   } //end if
   if ((flags & DBG_FLAG_AMBUSH))
   {
      if (wrote) bprint (",");
      bprint ("ambush");
      wrote = TRUE;
   } //end if
   if ((flags & DBG_FLAG_HAS_ENEMY))
   {
      if (wrote) bprint (",");
      bprint ("enemy");
      wrote = TRUE;
   } //end if
   if ((flags & DBG_FLAG_HAS_LOS))
   {
      if (wrote) bprint (",");
      bprint ("los");
   } //end if
}; //end of the function Bot_DbgPrintFlags

void (entity bot, float event_type, float a, float b, float reason_code, string reason) Bot_DbgEvent =
{
   local float base;
   local float idx;

   if (!bot_dbg_trace_enabled)
   {
      return ;
   } //end if
   if (!bot || !bot.isbot)
   {
      return ;
   } //end if
   base = Bot_DbgEventBase (bot);
   if ((base < 0.000))
   {
      return ;
   } //end if

   idx = (base + bot.dbg_event_head);
   dbg_event_time[idx] = time;
   dbg_event_tick[idx] = bot.dbg_tick;
   dbg_event_type[idx] = event_type;
   dbg_event_a[idx] = a;
   dbg_event_b[idx] = b;
   dbg_event_reason_code[idx] = reason_code;
   dbg_event_reason[idx] = reason;
   dbg_event_ent_a[idx] = world;
   dbg_event_ent_b[idx] = world;

   bot.dbg_event_head = (bot.dbg_event_head + 1.000);
   if ((bot.dbg_event_head >= BOT_DBG_EVENT_LEN))
   {
      bot.dbg_event_head = 0.000;
   } //end if
}; //end of the function Bot_DbgEvent

void (entity bot, entity old_goal, entity new_goal, float pri, float reason_code, string reason) Bot_DbgEventGoalChange =
{
   local float base;
   local float idx;

   if (!bot_dbg_trace_enabled)
   {
      return ;
   } //end if
   if (!bot || !bot.isbot)
   {
      return ;
   } //end if
   base = Bot_DbgEventBase (bot);
   if ((base < 0.000))
   {
      return ;
   } //end if

   idx = (base + bot.dbg_event_head);
   dbg_event_time[idx] = time;
   dbg_event_tick[idx] = bot.dbg_tick;
   dbg_event_type[idx] = DBG_EVT_GOAL_CHANGE;
   dbg_event_a[idx] = pri;
   dbg_event_b[idx] = 0.000;
   dbg_event_reason_code[idx] = reason_code;
   dbg_event_reason[idx] = reason;
   dbg_event_ent_a[idx] = old_goal;
   dbg_event_ent_b[idx] = new_goal;

   bot.dbg_event_head = (bot.dbg_event_head + 1.000);
   if ((bot.dbg_event_head >= BOT_DBG_EVENT_LEN))
   {
      bot.dbg_event_head = 0.000;
   } //end if
}; //end of the function Bot_DbgEventGoalChange

void (entity bot, float count) Bot_DbgDumpTrace =
{
   local float base;
   local float start;
   local float i;
   local float idx;
   local float head;
   local entity goal;

   if (!bot || !bot.isbot)
   {
      bprint ("[DBG] no bot selected\n");
      return ;
   } //end if
   base = Bot_DbgTraceBase (bot);
   if ((base < 0.000))
   {
      bprint ("[DBG] bot out of range\n");
      return ;
   } //end if
   if ((count <= 0.000))
   {
      count = 120.000;
   } //end if
   if ((count > BOT_DBG_TRACE_LEN))
   {
      count = BOT_DBG_TRACE_LEN;
   } //end if

   head = bot.dbg_trace_head;
   start = (head - count);
   if ((start < 0.000))
   {
      start = (start + BOT_DBG_TRACE_LEN);
   } //end if

   bprint ("[DBG] TRACE DUMP ");
   bprint (bot.netname);
   bprint (" (");
   bprint (ftos (count));
   bprint (" ticks)\n");

   i = 0.000;
   while ((i < count))
   {
      idx = (start + i);
      if ((idx >= BOT_DBG_TRACE_LEN))
      {
         idx = (idx - BOT_DBG_TRACE_LEN);
      } //end if
      idx = (base + idx);

      bprint ("[TRACE] tick=");
      bprint (ftos (dbg_trace_tick[idx]));
      bprint (" time=");
      bprint (ftos (dbg_trace_time[idx]));
      bprint (" intent=");
      Bot_DbgPrintIntent (dbg_trace_intent[idx]);
      bprint (" pri=");
      bprint (ftos (dbg_trace_intent_pri[idx]));
      bprint (" until=");
      bprint (ftos (dbg_trace_intent_until[idx]));
      bprint (" goal=");
      goal = dbg_trace_goal_ent[idx];
      Bot_DbgPrintGoalEnt (goal);
      bprint (" org=");
      bprint (vtos (dbg_trace_goal_org[idx]));
      bprint (" aim=");
      Bot_DbgPrintAimOwner (dbg_trace_aim_owner[idx]);
      bprint ("/");
      Bot_DbgPrintAimMode (dbg_trace_aim_mode[idx]);
      bprint (" yaw=");
      bprint (ftos (dbg_trace_yaw[idx]));
      bprint (" pitch=");
      bprint (ftos (dbg_trace_pitch[idx]));
      bprint (" ideal=");
      bprint (ftos (dbg_trace_ideal_yaw[idx]));
      bprint ("/");
      bprint (ftos (dbg_trace_ideal_pitch[idx]));
      bprint (" err=");
      bprint (ftos (dbg_trace_yaw_error[idx]));
      bprint (" dy=");
      bprint (ftos (dbg_trace_yaw_delta[idx]));
      bprint (" move=");
      Bot_DbgPrintMoveMode (dbg_trace_move_mode[idx]);
      bprint ("/");
      Bot_DbgPrintMoveStyle (dbg_trace_move_style[idx]);
      bprint (" spd=");
      bprint (ftos (dbg_trace_move_speed[idx]));
      bprint (" flags=");
      Bot_DbgPrintFlags (dbg_trace_flags[idx]);
      bprint ("\n");

      i = (i + 1.000);
   } //end while
}; //end of the function Bot_DbgDumpTrace

void (entity bot, float count) Bot_DbgDumpEvents =
{
   local float base;
   local float start;
   local float i;
   local float idx;
   local float head;
   local float etype;
   local entity ent_a;
   local entity ent_b;

   if (!bot || !bot.isbot)
   {
      bprint ("[DBG] no bot selected\n");
      return ;
   } //end if
   base = Bot_DbgEventBase (bot);
   if ((base < 0.000))
   {
      bprint ("[DBG] bot out of range\n");
      return ;
   } //end if
   if ((count <= 0.000))
   {
      count = 20.000;
   } //end if
   if ((count > BOT_DBG_EVENT_LEN))
   {
      count = BOT_DBG_EVENT_LEN;
   } //end if

   head = bot.dbg_event_head;
   start = (head - count);
   if ((start < 0.000))
   {
      start = (start + BOT_DBG_EVENT_LEN);
   } //end if

   bprint ("[DBG] EVENT DUMP ");
   bprint (bot.netname);
   bprint (" (");
   bprint (ftos (count));
   bprint (" events)\n");

   i = 0.000;
   while ((i < count))
   {
      idx = (start + i);
      if ((idx >= BOT_DBG_EVENT_LEN))
      {
         idx = (idx - BOT_DBG_EVENT_LEN);
      } //end if
      idx = (base + idx);
      etype = dbg_event_type[idx];

      bprint ("[EVT] tick=");
      bprint (ftos (dbg_event_tick[idx]));
      bprint (" time=");
      bprint (ftos (dbg_event_time[idx]));
      bprint (" ");

      if ((etype == DBG_EVT_GOAL_CHANGE))
      {
         bprint ("GOAL_CHANGE old=");
         ent_a = dbg_event_ent_a[idx];
         ent_b = dbg_event_ent_b[idx];
         Bot_DbgPrintGoalEnt (ent_a);
         bprint (" new=");
         Bot_DbgPrintGoalEnt (ent_b);
         bprint (" pri=");
         bprint (ftos (dbg_event_a[idx]));
      } //end if
      else if ((etype == DBG_EVT_AIM_OWNER_CHANGE))
      {
         bprint ("AIM_OWNER_CHANGE ");
         Bot_DbgPrintAimOwner (dbg_event_a[idx]);
         bprint (" -> ");
         Bot_DbgPrintAimOwner (dbg_event_b[idx]);
      } //end if
      else if ((etype == DBG_EVT_INTENT_CHANGE))
      {
         bprint ("INTENT_CHANGE ");
         Bot_DbgPrintIntent (dbg_event_a[idx]);
         bprint (" -> ");
         Bot_DbgPrintIntent (dbg_event_b[idx]);
      } //end if
      else if ((etype == DBG_EVT_UNSTICK_ENTER))
      {
         bprint ("UNSTICK_ENTER");
      } //end if
      else if ((etype == DBG_EVT_UNSTICK_EXIT))
      {
         bprint ("UNSTICK_EXIT");
      } //end if
      else if ((etype == DBG_EVT_APPLY_COUNT))
      {
         bprint ("APPLY_COUNT ");
         bprint (ftos (dbg_event_a[idx]));
      } //end if
      else if ((etype == DBG_EVT_ANGLES_OVERRIDE))
      {
         bprint ("ANGLES_OVERRIDE dy=");
         bprint (ftos (dbg_event_a[idx]));
         bprint (" dp=");
         bprint (ftos (dbg_event_b[idx]));
      } //end if
      else
      {
         bprint ("EVENT ");
         bprint (ftos (etype));
      } //end else

      if (dbg_event_reason_code[idx])
      {
         bprint (" code=");
         Bot_DbgPrintReason (dbg_event_reason_code[idx]);
      } //end if
      if (dbg_event_reason[idx])
      {
         bprint (" reason=");
         bprint (dbg_event_reason[idx]);
      } //end if
      bprint ("\n");

      i = (i + 1.000);
   } //end while
}; //end of the function Bot_DbgDumpEvents

void () Bot_DbgDumpTraceCmd =
{
   local entity bot;
   local float count;

   bot = bot_dbg_focus;
   if (!bot)
   {
      Bot_DbgSetFocus ();
      bot = bot_dbg_focus;
   } //end if
   if (!bot)
   {
      bot = Bot_DbgResolveTarget ();
   } //end if
   if (!bot)
   {
      bprint ("No bot found for telemetry trace.\n");
      return;
   } //end if
   count = cvar ("bot_dbg_n");
   Bot_DbgDumpTrace (bot,count);
}; //end of the function Bot_DbgDumpTraceCmd

void () Bot_DbgDumpEventsCmd =
{
   local entity bot;
   local float count;

   bot = bot_dbg_focus;
   if (!bot)
   {
      Bot_DbgSetFocus ();
      bot = bot_dbg_focus;
   } //end if
   if (!bot)
   {
      bot = Bot_DbgResolveTarget ();
   } //end if
   if (!bot)
   {
      bprint ("No bot found for telemetry events.\n");
      return;
   } //end if
   count = cvar ("bot_dbg_event_n");
   if ((count <= 0.000))
   {
      count = cvar ("bot_dbg_n");
   } //end if
   Bot_DbgDumpEvents (bot,count);
}; //end of the function Bot_DbgDumpEventsCmd

void () Bot_DbgToggle =
{
   bot_dbg_trace_enabled = !bot_dbg_trace_enabled;
   bprint ("\n");
   if (bot_dbg_trace_enabled)
   {
      Bot_DbgSetFocus ();
      bprint ("===========================================\n");
      bprint ("  BOT TELEMETRY ENABLED\n");
      bprint ("===========================================\n");
      bprint ("Build: ");
      bprint (bot_dbg_build);
      bprint ("\n");
      if (bot_dbg_focus)
      {
         bprint ("Focus bot: ");
         bprint (ftos (bot_dbg_focus_id));
         bprint (" ");
         bprint (bot_dbg_focus.netname);
         bprint ("\n");
      } //end if
      bprint ("Use impulse 122 to dump trace, 123 for events.\n");
      bprint ("Set cvars: bot_dbg_id, bot_dbg_n, bot_dbg_event_n\n");
   } //end if
   else
   {
      bprint ("Bot telemetry DISABLED.\n");
   } //end else
   bprint ("\n");
}; //end of the function Bot_DbgToggle

float (float reason_code) Bot_DbgGoalOwner =
{
   if (((reason_code == R_COMBAT_SEEN_ENEMY) || (reason_code == R_COMBAT_TAKING_DAMAGE)))
   {
      return (1.000);
   } //end if
   if (((reason_code == R_COMBAT_HUNT_TARGET) || (reason_code == R_COMBAT_ENEMY_TOUCHED)))
   {
      return (1.000);
   } //end if
   if (((reason_code == R_TRIGGER_BUTTON) || (reason_code == R_TRIGGERED)))
   {
      return (2.000);
   } //end if
   if (((reason_code == R_NAV_ITEM_PICKUP) || (reason_code == R_NAV_ROAM)))
   {
      return (3.000);
   } //end if
   if (((reason_code == R_NAV_GLOBAL) || (reason_code == R_GOAL_CHOOSE)))
   {
      return (3.000);
   } //end if
   if (((reason_code == R_GOAL_CHOOSE_PATH) || (reason_code == R_GOAL_AIR_SEEK)))
   {
      return (3.000);
   } //end if
   if (((reason_code == R_GOAL_GOODY_PICK) || (reason_code == R_GOAL_GOODY_FALLBACK)))
   {
      return (3.000);
   } //end if
   if (((reason_code == R_GOAL_GOODY_END) || (reason_code == R_GOAL_GOODY_RESET)))
   {
      return (3.000);
   } //end if
   if ((reason_code == R_GOAL_STACK))
   {
      return (4.000);
   } //end if
   if (((reason_code == R_GOAL_FIXATE_RESET) || (reason_code == R_GOAL_FIXATE_AVOID)))
   {
      return (5.000);
   } //end if
   if ((reason_code == R_SPAWN_IDLE))
   {
      return (6.000);
   } //end if
   if (((reason_code == R_UNSTICK_NO_PROGRESS) || (reason_code == R_UNSTICK_TERRAIN)))
   {
      return (7.000);
   } //end if
   if ((reason_code == R_UNSTICK_LOOP))
   {
      return (7.000);
   } //end if
   return (0.000);
}; //end of the function Bot_DbgGoalOwner

void (float owner) Bot_DbgPrintMoveOwner =
{
   if ((owner == FG_DRV_TERRAIN)) { bprint ("TERRAIN"); return ; }
   if ((owner == FG_DRV_LOOP)) { bprint ("LOOP"); return ; }
   if ((owner == FG_DRV_VERTICAL)) { bprint ("VERTICAL"); return ; }
   if ((owner == FG_DRV_INTENT)) { bprint ("INTENT"); return ; }
   if ((owner == FG_DRV_ROUTE)) { bprint ("ROUTE"); return ; }
   if ((owner == FG_DRV_ROAM)) { bprint ("ROAM"); return ; }
   if ((owner == FG_DRV_NONE))
   {
      bprint ("NAV");
      return ;
   } //end if
   bprint ("MOVE");
}; //end of the function Bot_DbgPrintMoveOwner

void (float owner) Bot_DbgPrintGoalOwner =
{
   if ((owner == 1.000)) { bprint ("COMBAT"); return ; }
   if ((owner == 2.000)) { bprint ("TRIGGER"); return ; }
   if ((owner == 3.000)) { bprint ("NAV"); return ; }
   if ((owner == 4.000)) { bprint ("STACK"); return ; }
   if ((owner == 5.000)) { bprint ("FIXATE"); return ; }
   if ((owner == 6.000)) { bprint ("SPAWN"); return ; }
   if ((owner == 7.000)) { bprint ("UNSTICK"); return ; }
   bprint ("GOAL");
}; //end of the function Bot_DbgPrintGoalOwner

void (entity bot) Bot_DbgOwnerLog =
{
   local float move_owner;
   local float goal_owner;
   local float state_owner;
   local float do_log;

   if (!bot_debug_enabled)
   {
      return ;
   } //end if
   if (!bot || !bot.isbot)
   {
      return ;
   } //end if

   move_owner = bot.fg_driver;
   goal_owner = Bot_DbgGoalOwner (bot.goal_reason_code);
   state_owner = Bot_EffectiveIntent (bot);

   do_log = FALSE;
   if ((move_owner != bot.dbg_owner_move))
   {
      do_log = TRUE;
   } //end if
   else if ((bot.aim_owner != bot.dbg_owner_aim))
   {
      do_log = TRUE;
   } //end if
   else if ((goal_owner != bot.dbg_owner_goal))
   {
      do_log = TRUE;
   } //end if
   else if ((state_owner != bot.dbg_owner_state))
   {
      do_log = TRUE;
   } //end if
   else if (((time - bot.dbg_owner_last_log_time) >= 1.000))
   {
      do_log = TRUE;
   } //end if

   if (!do_log)
   {
      return ;
   } //end if

   bprint ("[");
   bprint (bot.netname);
   bprint ("] OWN tick=");
   bprint (ftos (bot.dbg_tick));
   bprint (" move=");
   Bot_DbgPrintMoveOwner (move_owner);
   bprint (" aim=");
   Bot_DbgPrintAimOwner (bot.aim_owner);
   bprint (" goal=");
   Bot_DbgPrintGoalOwner (goal_owner);
   bprint (" state=");
   Bot_DbgPrintIntent (state_owner);
   bprint (" reason=");
   bprint (ftos (bot.goal_reason_code));
   bprint ("\n");

   bot.dbg_owner_move = move_owner;
   bot.dbg_owner_aim = bot.aim_owner;
   bot.dbg_owner_goal = goal_owner;
   bot.dbg_owner_state = state_owner;
   bot.dbg_owner_last_log_time = time;
}; //end of the function Bot_DbgOwnerLog

void (entity bot) Bot_DbgTraceTick =
{
   local float base;
   local float idx;
   local float flags;
   local float intent_type;
   local float intent_pri;
   local float intent_until;
   local entity goal;
   local float yaw_error;
   local float yaw_delta;
   local float los_class;

   if (!bot_dbg_trace_enabled)
   {
      return ;
   } //end if
   if (!bot || !bot.isbot)
   {
      return ;
   } //end if
   base = Bot_DbgTraceBase (bot);
   if ((base < 0.000))
   {
      return ;
   } //end if

   flags = 0.000;
   if ((bot.stuck_mode != DBG_STUCK_NORMAL)) { flags = (flags + DBG_FLAG_STUCK); }
   if ((bot.stuck_mode == DBG_STUCK_UNSTICK)) { flags = (flags + DBG_FLAG_UNSTICK); }
   if (bot.elevator_wait_state) { flags = (flags + DBG_FLAG_ELEVATOR); }
   if (((time < bot.intent_request_until) && (bot.intent_request == DBG_INTENT_HOLD)))
   {
      flags = (flags + DBG_FLAG_AMBUSH);
   } //end if
   if ((bot.enemy && (bot.enemy != world)))
   {
      flags = (flags + DBG_FLAG_HAS_ENEMY);
      los_class = Bot_LOSClassFrom (bot,bot.origin,bot.enemy);
      if ((los_class > 0.000))
      {
         flags = (flags + DBG_FLAG_HAS_LOS);
      } //end if
   } //end if

   intent_type = bot.bot_intent;
   intent_pri = 0.000;
   intent_until = 0.000;
   if ((time < bot.intent_request_until))
   {
      intent_type = bot.intent_request;
      intent_pri = bot.intent_request_pri;
      intent_until = bot.intent_request_until;
   } //end if

   goal = world;
   if (bot.goalentity)
   {
      goal = bot.goalentity;
      if (bot.goalentity.goalentity)
      {
         goal = bot.goalentity.goalentity;
      } //end if
   } //end if

   if ((bot.dbg_last_goal_ent != goal))
   {
      Bot_DbgEventGoalChange (bot,bot.dbg_last_goal_ent,goal,bot.goal_priority,bot.goal_reason_code,bot.goal_reason);
      bot.dbg_last_goal_ent = goal;
   } //end if

   if ((bot.aim_owner != bot.dbg_last_aim_owner))
   {
      if (((time - bot.dbg_aim_flip_window_start) > 1.000) || !bot.dbg_aim_flip_window_start)
      {
         bot.dbg_aim_flip_window_start = time;
         bot.dbg_aim_flip_count = 0.000;
      } //end if
      bot.dbg_aim_flip_count = (bot.dbg_aim_flip_count + 1.000);
      Bot_DbgEvent (bot,DBG_EVT_AIM_OWNER_CHANGE,bot.dbg_last_aim_owner,bot.aim_owner,bot.aim_reason_code,bot.aim_reason);
      bot.dbg_last_aim_owner = bot.aim_owner;
   } //end if

   if ((bot.bot_intent != bot.dbg_last_intent))
   {
      Bot_DbgEvent (bot,DBG_EVT_INTENT_CHANGE,bot.dbg_last_intent,bot.bot_intent,bot.intent_reason_code,bot.intent_reason);
      bot.dbg_last_intent = bot.bot_intent;
   } //end if

   if (((bot.stuck_mode == DBG_STUCK_UNSTICK) && (bot.dbg_last_unstick != DBG_STUCK_UNSTICK)))
   {
      Bot_DbgEvent (bot,DBG_EVT_UNSTICK_ENTER,0.000,0.000,bot.unstick_reason_code,bot.unstick_reason);
   } //end if
   if (((bot.stuck_mode != DBG_STUCK_UNSTICK) && (bot.dbg_last_unstick == DBG_STUCK_UNSTICK)))
   {
      Bot_DbgEvent (bot,DBG_EVT_UNSTICK_EXIT,0.000,0.000,bot.unstick_reason_code,"unstick exit");
      bot.unstick_reason_code = R_NONE;
      bot.unstick_reason = string_null;
   } //end if
   bot.dbg_last_unstick = bot.stuck_mode;

   if ((bot.dbg_tick <= 1.000))
   {
      yaw_delta = 0.000;
      bot.dbg_last_yaw = bot.angles_y;
   } //end if
   else
   {
      yaw_delta = Math_AngleDiff ((bot.angles_y - bot.dbg_last_yaw));
      bot.dbg_last_yaw = bot.angles_y;
   } //end else
   yaw_error = Math_AngleDiff ((bot.aim_final_yaw - bot.angles_y));

   idx = (base + bot.dbg_trace_head);
   dbg_trace_time[idx] = time;
   dbg_trace_tick[idx] = bot.dbg_tick;
   dbg_trace_intent[idx] = intent_type;
   dbg_trace_intent_pri[idx] = intent_pri;
   dbg_trace_intent_until[idx] = intent_until;
   if (bot.goalentity)
   {
      dbg_trace_goal_org[idx] = bot.goalentity.origin;
   } //end if
   else
   {
      dbg_trace_goal_org[idx] = bot.origin;
   } //end else
   dbg_trace_goal_ent[idx] = goal;
   dbg_trace_aim_owner[idx] = bot.aim_owner;
   dbg_trace_aim_mode[idx] = bot.aim_mode;
   dbg_trace_yaw[idx] = bot.angles_y;
   dbg_trace_pitch[idx] = bot.angles_x;
   dbg_trace_ideal_yaw[idx] = bot.aim_final_yaw;
   dbg_trace_ideal_pitch[idx] = bot.aim_final_pitch;
   dbg_trace_yaw_error[idx] = yaw_error;
   dbg_trace_yaw_delta[idx] = yaw_delta;
   dbg_trace_move_mode[idx] = bot.move_mode;
   dbg_trace_move_style[idx] = bot.move_style;
   dbg_trace_move_speed[idx] = bot.move_speed;
   dbg_trace_flags[idx] = flags;

   bot.dbg_trace_head = (bot.dbg_trace_head + 1.000);
   if ((bot.dbg_trace_head >= BOT_DBG_TRACE_LEN))
   {
      bot.dbg_trace_head = 0.000;
   } //end if

   Bot_DbgOwnerLog (bot);

   if (fabs (yaw_delta) > BOT_DBG_SPIN_YAW)
   {
      bot.dbg_spin_ticks = (bot.dbg_spin_ticks + 1.000);
   } //end if
   else
   {
      bot.dbg_spin_ticks = 0.000;
   } //end else

   if ((bot_dbg_spin_enabled && ((bot.dbg_spin_ticks > BOT_DBG_SPIN_TICKS) || (bot.dbg_aim_flip_count > BOT_DBG_AIM_FLIP_LIMIT))))
   {
      if ((time >= bot.dbg_spin_trigger_time))
      {
         bprint ("[DBG] SPIN DETECTED: ");
         bprint (bot.netname);
         bprint ("\n");
         Bot_DbgDumpTrace (bot,120.000);
         Bot_DbgDumpEvents (bot,20.000);
         bot.dbg_spin_trigger_time = (time + 1.000);
      } //end if
   } //end if
}; //end of the function Bot_DbgTraceTick
