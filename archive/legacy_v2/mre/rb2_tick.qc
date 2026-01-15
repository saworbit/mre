// Reapbot v2 single-tick control loop.
void () BotCheckPowerups;
void () BotWaterMove;
void () NextLevel;
void () IntermissionThink;
void () RB2_InitBotState =
{
   self.rb2_last_tick_time = -1.000;
   self.rb2_intent = RB2_INTENT_IDLE;
   self.rb2_intent_reason = "init";
   self.rb2_enemy = world;
   self.rb2_enemy_seen_time = 0.000;
   self.rb2_has_enemy = 0.000;
   self.rb2_cmd_move = '0.000 0.000 0.000';
   self.rb2_cmd_aim = '0.000 0.000 0.000';
   self.rb2_cmd_attack = 0.000;
   self.rb2_trace_index = 0.000;
   self.rb2_trace_count = 0.000;
}; //end of the function RB2_InitBotState

void () RB2_PerceptionUpdate =
{
   if ((self.enemy && (self.enemy.health > 0.000)))
   {
      self.rb2_enemy = self.enemy;
      self.rb2_has_enemy = 1.000;
      self.rb2_enemy_seen_time = time;
      return;
   } //end if

   self.rb2_enemy = world;
   self.rb2_has_enemy = 0.000;
}; //end of the function RB2_PerceptionUpdate

void (float intent, string reason) RB2_SetIntent =
{
   self.rb2_intent = intent;
   self.rb2_intent_reason = reason;
}; //end of the function RB2_SetIntent

void () RB2_Decide =
{
   // Milestone 1: no-op baseline.
   RB2_SetIntent (RB2_INTENT_IDLE,"idle");
}; //end of the function RB2_Decide

void () RB2_Apply =
{
   if ((self.rb2_intent == RB2_INTENT_IDLE))
   {
      self.rb2_cmd_attack = 0.000;
      self.rb2_cmd_move = '0.000 0.000 0.000';
      self.velocity_x = 0.000;
      self.velocity_y = 0.000;
   } //end if
}; //end of the function RB2_Apply

void () RB2_Tick =
{
   if ((self.rb2_last_tick_time == time))
   {
      return;
   } //end if
   self.rb2_last_tick_time = time;

   RB2_PerceptionUpdate ();
   RB2_Decide ();
   RB2_Apply ();

   if (rb2_trace_enabled)
   {
      RB2_TracePush (self,self.rb2_intent_reason);
   } //end if
}; //end of the function RB2_Tick

void () RB2_PostThinkCommon =
{
   local float fraglimit;

   BotCheckPowerups ();
   BotWaterMove ();
   fraglimit = cvar ("fraglimit");
   if ((fraglimit && (self.frags >= fraglimit)))
   {
      NextLevel ();
      self.button0 = TRUE;
      self.think = IntermissionThink;
      self.nextthink = (time + MOVETYPE_FLY);
      return;
   } //end if
}; //end of the function RB2_PostThinkCommon

void () RB2_BotThink =
{
   RB2_Tick ();
   RB2_PostThinkCommon ();
   self.think = RB2_BotThink;
   self.nextthink = (time + 0.100);
}; //end of the function RB2_BotThink

void (entity attacker, float damage) RB2_BotPain =
{
   RB2_Tick ();
   RB2_PostThinkCommon ();
   self.think = RB2_BotThink;
   self.nextthink = (time + 0.100);
}; //end of the function RB2_BotPain
