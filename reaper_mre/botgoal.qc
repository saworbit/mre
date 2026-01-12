
void (float dist) ai_botrun;

void () bot_chase;

void () bot_trigger1;

void () aibot_chooseGoal;
float /* ERROR: Could not determine return type */ () BotFindTarget;
void (entity bot, vector dir) RecordDirectionalFail;  // Directional fail memory (defined in botmove.qc)

float (entity target) Bot_IsAvoidedTarget =
{
   if (!target)
   {
      return (FALSE);
   } //end if
   if (target.avoid_until)
   {
      if ((time < target.avoid_until))
      {
         return (TRUE);
      } //end if
      target.avoid_until = 0.000;
   } //end if

   if (self.avoid_target0)
   {
      if ((time >= self.avoid_target_time0))
      {
         self.avoid_target0 = world;
         self.avoid_target_time0 = 0.000;
      } //end if
      else
      {
         if ((self.avoid_target0 == target)) return (TRUE);
      } //end else
   } //end if
   if (self.avoid_target1)
   {
      if ((time >= self.avoid_target_time1))
      {
         self.avoid_target1 = world;
         self.avoid_target_time1 = 0.000;
      } //end if
      else
      {
         if ((self.avoid_target1 == target)) return (TRUE);
      } //end else
   } //end if
   if (self.avoid_target2)
   {
      if ((time >= self.avoid_target_time2))
      {
         self.avoid_target2 = world;
         self.avoid_target_time2 = 0.000;
      } //end if
      else
      {
         if ((self.avoid_target2 == target)) return (TRUE);
      } //end else
   } //end if
   if (self.avoid_target3)
   {
      if ((time >= self.avoid_target_time3))
      {
         self.avoid_target3 = world;
         self.avoid_target_time3 = 0.000;
      } //end if
      else
      {
         if ((self.avoid_target3 == target)) return (TRUE);
      } //end else
   } //end if

   return (FALSE);
}; //end of the function Bot_IsAvoidedTarget

void (entity target, float ttl) Bot_AddAvoidTarget =
{
   local float best_time;
   local float idx;

   if (!target)
   {
      return ;
   } //end if
   target.avoid_until = (time + ttl);

   if ((self.avoid_target0 == target))
   {
      self.avoid_target_time0 = (time + ttl);
      return ;
   } //end if
   if ((self.avoid_target1 == target))
   {
      self.avoid_target_time1 = (time + ttl);
      return ;
   } //end if
   if ((self.avoid_target2 == target))
   {
      self.avoid_target_time2 = (time + ttl);
      return ;
   } //end if
   if ((self.avoid_target3 == target))
   {
      self.avoid_target_time3 = (time + ttl);
      return ;
   } //end if

   idx = 0.000;
   if ((!self.avoid_target0) || (self.avoid_target_time0 <= time)) idx = 0.000;
   else if ((!self.avoid_target1) || (self.avoid_target_time1 <= time)) idx = 1.000;
   else if ((!self.avoid_target2) || (self.avoid_target_time2 <= time)) idx = 2.000;
   else if ((!self.avoid_target3) || (self.avoid_target_time3 <= time)) idx = 3.000;
   else
   {
      best_time = self.avoid_target_time0;
      idx = 0.000;
      if ((self.avoid_target_time1 < best_time)) { best_time = self.avoid_target_time1; idx = 1.000; }
      if ((self.avoid_target_time2 < best_time)) { best_time = self.avoid_target_time2; idx = 2.000; }
      if ((self.avoid_target_time3 < best_time)) { best_time = self.avoid_target_time3; idx = 3.000; }
   } //end else

   if ((idx == 0.000))
   {
      self.avoid_target0 = target;
      self.avoid_target_time0 = (time + ttl);
   } //end if
   else if ((idx == 1.000))
   {
      self.avoid_target1 = target;
      self.avoid_target_time1 = (time + ttl);
   } //end if
   else if ((idx == 2.000))
   {
      self.avoid_target2 = target;
      self.avoid_target_time2 = (time + ttl);
   } //end if
   else
   {
      self.avoid_target3 = target;
      self.avoid_target_time3 = (time + ttl);
   } //end else
}; //end of the function Bot_AddAvoidTarget

void (entity owner, float pri, float commit_secs, entity ent, vector org, float reason_code, string reason) Bot_RequestGoal =
{
   local entity oldself;

   if (!owner)
   {
      return ;
   } //end if
   if ((owner.frame_begin_time != time))
   {
      oldself = self;
      self = owner;
      Bot_FrameBegin ();
      self = oldself;
   } //end if
   if (owner.move_apply_active)
   {
      if (owner.goal_req_pending_set)
      {
         if ((pri < owner.goal_req_pending_pri))
         {
            return ;
         } //end if
         if ((pri == owner.goal_req_pending_pri))
         {
            if ((ent != owner.goal_req_pending_ent))
            {
               return ;
            } //end if
         } //end if
      } //end if
      owner.goal_req_pending_set = TRUE;
      owner.goal_req_pending_pri = pri;
      owner.goal_req_pending_commit_secs = commit_secs;
      owner.goal_req_pending_ent = ent;
      owner.goal_req_pending_org = org;
      owner.goal_req_pending_reason = reason;
      owner.goal_req_pending_reason_code = reason_code;
      return ;
   } //end if

   if ((owner.goal_req_pri >= 0.000))
   {
      if ((pri < owner.goal_req_pri))
      {
         return ;
      } //end if
      if ((pri == owner.goal_req_pri))
      {
         if ((ent != owner.goal_req_ent))
         {
            return ;
         } //end if
      } //end if
   } //end if

   owner.goal_req_pri = pri;
   owner.goal_req_commit_secs = commit_secs;
   owner.goal_req_ent = ent;
   owner.goal_req_org = org;
   owner.goal_req_reason = reason;
   owner.goal_req_reason_code = reason_code;
}; //end of the function Bot_RequestGoal

float (entity bot, float reason_code) Bot_GoalMinCommit =
{
   if (((reason_code == R_TRIGGER_BUTTON) || (reason_code == R_TRIGGERED)))
   {
      return (0.800);
   } //end if
   if (((reason_code == R_COMBAT_SEEN_ENEMY) || (reason_code == R_COMBAT_TAKING_DAMAGE)))
   {
      return (0.600);
   } //end if
   if (((reason_code == R_COMBAT_HUNT_TARGET) || (reason_code == R_COMBAT_ENEMY_TOUCHED)))
   {
      return (0.600);
   } //end if
   if ((reason_code == R_GOAL_STACK))
   {
      return (0.400);
   } //end if
   if (((reason_code == R_GOAL_FIXATE_RESET) || (reason_code == R_GOAL_FIXATE_AVOID)))
   {
      return (0.500);
   } //end if
   if (bot)
   {
      return (Bot_IntentMinCommit (Bot_EffectiveIntent (bot)));
   } //end if
   return (0.750);
}; //end of the function Bot_GoalMinCommit

float (vector org) Bot_GoalNoise =
{
   local float n;

   n = ((org_x * 0.013) + (org_y * 0.017) + (org_z * 0.019));
   if ((n < 0.000))
   {
      n = (n * -1.000);
   } //end if
   n = (n - floor (n));
   return (n);
}; //end of the function Bot_GoalNoise

void () Bot_CheckGoalFixation =
{
   local entity goal;
   local float dist;

   if (!self.goalentity)
   {
      return ;
   } //end if
   goal = self.goalentity.goalentity;
   if (!goal)
   {
      return ;
   } //end if
   if ((goal == self.goalentity))
   {
      return ;
   } //end if
   if ((goal == self.enemy))
   {
      return ;
   } //end if
   if ((goal.classname == "player"))
   {
      return ;
   } //end if
   if ((goal.classname == "BotPath"))
   {
      return ;
   } //end if
   if ((goal.solid == SOLID_NOT) && (goal.modelindex == 0.000))
   {
      Bot_RequestGoal (self,70.000,0.500,self.goalentity,self.goalentity.origin,R_GOAL_FIXATE_RESET,"fixate reset");
      self.nav_search_time = time;
      self.last_goal_progress_time = time;
      self.last_goal_dist = 999999.000;
      return ;
   } //end if

   if ((self.last_goal_entity != goal))
   {
      self.last_goal_entity = goal;
      self.last_goal_dist = vlen ((goal.origin - self.origin));
      self.last_goal_progress_time = time;
      return ;
   } //end if

   dist = vlen ((goal.origin - self.origin));
   if ((dist < (self.last_goal_dist - 8.000)))
   {
      self.last_goal_dist = dist;
      self.last_goal_progress_time = time;
      return ;
   } //end if

   if (((time - self.last_goal_progress_time) > 1.500))
   {
      Bot_AddAvoidTarget (goal,20.000);  // Avoid for 20s - if we can't reach it after trying multiple angles, stay away longer
      // Record directional failure: remember this approach angle didn't work
      RecordDirectionalFail (self,normalize (goal.origin - self.origin));
      if ((bot_debug_enabled && (bot_debug_level >= LOG_TACTICAL)))
      {
         bprint ("[");
         bprint (self.netname);
         bprint ("] FIXATE: Avoid goal ");
         bprint (goal.classname);
         bprint ("\n");
      } //end if
      self.last_goal_progress_time = time;
      self.last_goal_dist = 999999.000;
      Bot_RequestGoal (self,70.000,0.500,self.goalentity,self.goalentity.origin,R_GOAL_FIXATE_AVOID,"fixate avoid");
      self.nav_search_time = time;
   } //end if
}; //end of the function Bot_CheckGoalFixation

void () shoottarget =
{
   local vector dir;
   local entity botTarget;

   botTarget = self.goalentity;
   bot_trigger1 ();
   sound (self,CHAN_WEAPON,"weapons/guncock.wav",TRUE,ATTN_NORM);
   dir = ((botTarget.goalentity.absmin + botTarget.goalentity.absmax) * 0.500);
   dir = normalize ((dir - self.origin));
   FireBullets (MOVETYPE_TOSS,dir,'0.040 0.040 0.000');
   self.attack_finished = (time + 0.500);
   self.enemy = world;
   if ((botTarget.goalentity.classname == "door"))
   {
      self.nav_search_time = (time + FL_CLIENT);
   } //end if
}; //end of the function shoottarget

void () Bot_DecideGoal =
{
   local entity botTarget;
   local vector dir;

   if (self.enemy)
   {
      aibot_setupchase ();
   } //end if
   if (BotFindTarget ())
   {
      self.lefty = (self.lefty | FAR_SEEK);
      return ;
   } //end if
   botTarget = self.goalentity;
   if (!botTarget)
   {
      return ;
   } //end if
   Bot_CheckGoalFixation ();
   if ((time < self.nav_search_time))
   {
      if ((botTarget.goalentity.classname == "train"))
      {
         dir = ((botTarget.goalentity.absmin + botTarget.goalentity.absmax) * 0.500);
         dir_z = (botTarget.goalentity.absmax_z + TRUE);
         setorigin (botTarget,dir);
      } //end if
      if ((botTarget.goalentity.solid != SOLID_NOT))
      {
         return ;
      } //end if
   } //end if
   aibot_chooseGoal ();
}; //end of the function Bot_DecideGoal

void (float dist) ai_botseek =
{
   local entity botTarget;
   local vector dir;
   local float rng;
   local float oldrng;
   botTarget = self.goalentity;
   Bot_CheckGoalFixation ();
   if ((time < self.nav_search_time))
   {
      if ((botTarget.goalentity.classname == "train"))
      {
         dir = ((botTarget.goalentity.absmin + botTarget.goalentity.absmax) * 0.500);
         dir_z = (botTarget.goalentity.absmax_z + TRUE);
         setorigin (botTarget,dir);
      } //end if
      if ((botTarget.goalentity.solid != SOLID_NOT))
      {
         oldrng = vlen ((botTarget.origin - self.origin));
         Botmovetogoal (dist);
         rng = vlen ((botTarget.origin - self.origin));
         if ((rng >= oldrng))
         {
            self.nav_search_time = (self.nav_search_time - 0.400);
            if ((botTarget.goalentity == botTarget))
            {
               self.nav_search_time = time;
            } //end if
         } //end if
         return ;
      } //end if
   } //end if
   
   // ===== TWEAK #3a: Button shoot + wait (shoot once → loop+open check) =====
   // Auto-shoots buttons and shootable triggers, then waits 2s for doors to open—enables
   // fluid secret navigation. Replaces blind ignore with "human button-use" behavior.
   // Only shoots if visible (avoids wasted shots through walls) and sets wait timer.
   if (((botTarget.goalentity.takedamage == DAMAGE_YES) && Spotvisible (botTarget.goalentity)))
   {
      shoottarget ();
      self.button_wait_time = (time + 2.000);  // Wait 2s for door/trigger to activate
   } //end if
   // ===== END TWEAK #3a =====

   Botmovetogoal (dist);
}; //end of the function ai_botseek
float (entity e) thingweight =
{
   local float weight;
   local float OK_HIGH;
   local float recent;
   local float waittime;

   weight = DONT_WANT;
   OK_HIGH = FALSE;
   if ((self.flags & FL_SWIM))
   {
      OK_HIGH = Swimto (e);
   } //end if
   if ((e.lastbot == self))
   {
      recent = (e.lasttime > (time - FL_CLIENT));
      if (!recent)
      {
         waittime = (time - (LOOPTIME * random ()));
         recent = (e.lasttime > waittime);
      } //end if
      if (recent)
      {
         return (DONT_WANT);
      } //end if
   } //end if
   if (e.th_weight)
   {
      weight = e.th_weight (e);

      // ===== NEMESIS SYSTEM: Grudge Bias =====
      // If this is my nemesis and the grudge is fresh, prioritize hunting them down.
      // Massive priority boost makes bots ignore items and seek revenge.
      if ((e == self.nemesis) && (time < self.nemesis_time))
      {
         // Massive priority boost. Ignore items, kill him.
         weight = (weight + 2000.000);
      } //end if
      // ===== END NEMESIS SYSTEM =====

   } //end if
   else
   {
      e.pathtype = NEVERTARGET;
   } //end if
   if ((weight > DONT_WANT))
   {
      if (!OK_HIGH)
      {
         // ===== ENHANCED TWEAK: Rocket Jump Reachability (Gap Crosser) =====
         // If thing is high (up to 450 units), but we have a Rocket Launcher,
         // Health, and Ammo, we MARK IT AS REACHABLE instead of ignoring it.
         local float can_rj;
         can_rj = FALSE;
         if (((self.items & IT_ROCKET_LAUNCHER) && (self.ammo_rockets >= 1.000)))
         {
            if ((self.health >= 40.000))
            {
               can_rj = TRUE;
            } //end if
         } //end if

         if ((e.absmin_z > (self.origin_z + MAXJUMP)))
         {
            // If we can RJ and it's within "Rocket Jump Height" (approx 450u)
            if ((can_rj && (e.absmin_z < (self.origin_z + 450.000))))
            {
               // KEEP weight! (Do nothing, let it pass)
               // Bonus: Boost desire slightly because high things are usually good.
               weight = (weight * 1.200);
            } //end if
            else
            {
               // Truly unreachable
               weight = DONT_WANT;
            } //end if
         } //end if
         // ===== END ENHANCED TWEAK =====
      } //end if
   } //end if
   return (weight);
}; //end of the function thingweight
float (entity e) trigweight =
{
   local float weight;

   weight = DONT_WANT;
   if ((e.lastbot == self))
   {
      if ((e.lasttime > (time - FL_CLIENT)))
      {
         return (DONT_WANT);
      } //end if
   } //end if
   if (e.th_weight)
   {
      weight = e.th_weight (e);

   } //end if
   else
   {
      e.pathtype = NEVERTARGET;
   } //end if
   return (weight);
}; //end of the function trigweight
float (entity e) itemweight =
{
   local float weight;
   local float OK_HIGH;

   weight = DONT_WANT;
   OK_HIGH = FALSE;
   if ((self.flags & FL_SWIM))
   {
      OK_HIGH = Swimto (e);
   } //end if
   if ((e.lastbot == self))
   {
      if ((e.lasttime > (time - MOVETYPE_FLY)))
      {
         return (DONT_WANT);
      } //end if
   } //end if
   // Item already picked up or removed: skip stale goal.
   if ((e.solid == SOLID_NOT) && (e.modelindex == 0.000))
   {
      return (DONT_WANT);
   } //end if
   if (e.th_weight)
   {
      weight = e.th_weight (e);

   } //end if
   else
   {
      e.pathtype = NEVERTARGET;
   } //end if
   // Opportunistic finish: boost items near a weak enemy to press advantage.
   if (self.enemy)
   {
      if ((self.enemy != world))
      {
         if ((self.enemy.health < 40.000))
         {
            if ((vlen ((e.origin - self.enemy.origin)) < 300.000))
            {
               if ((weight > DONT_WANT))
               {
                  weight = (weight + ((40.000 - self.enemy.health) * 2.000));
                  if ((self.skil > 2.000))
                  {
                     weight = (weight + (random () * 50.000));
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
   } //end if
   // ===== PHASE 10: Graduated Need Assessment =====
   // FUZZY LOGIC: Health Urgency Curve (replaces FrikBot hard thresholds)
   // Old: if HP < 20 then +150, else if HP < 50 then +50 (two cliff edges at 20 and 50)
   // New: Cubic curve from 0 (healthy) to 200 (critically wounded)
   // HP=100: 0, HP=50: ~25, HP=20: ~102, HP=0: 200 (smooth desperation gradient)
   // No more sudden jumps - organic decision making across all HP values
   if ((e.classname == "item_health"))
   {
      if ((weight > DONT_WANT))
      {
         // Smooth health urgency: cubic curve accelerates at low HP
         local float health_urgency;
         health_urgency = (200.000 * inverse_smooth_curve (self.health, 0.000, 100.000, 3.000));
         weight = (weight + health_urgency);

         // Megahealth bonus (spawnflags & 2)
         if ((e.spawnflags & 2.000))
         {
            weight = (weight + 50.000);   // Always valuable
         }
      } //end if
   } //end if

   // Low-armor bias: graduated armor need assessment
   if ((self.armorvalue < 50.000))
   {
      if ((e.classname == "item_armor1") || (e.classname == "item_armor2") || (e.classname == "item_armorInv"))
      {
         if ((weight > DONT_WANT))
         {
            weight = (weight + ((50.000 - self.armorvalue) * 0.800));  // Up to +40 when naked
         } //end if
      } //end if
   } //end if

   // ===== TACTICAL AI: Smart Backpack Scavenging =====
   // Bots intelligently prioritize dropped backpacks when starving for weapons/ammo.
   // High reward if missing RL/LG (3000), desperation boost for ammo starvation (+2000).
   // Works with risk-aware logic below to avoid suicide rushes for contested backpacks.
   if ((e.classname == "backpack"))
   {
      weight = 1000.000;

      // High reward if missing RL/LG
      if (!(self.items & (IT_ROCKET_LAUNCHER | IT_LIGHTNING)))
      {
         weight = 3000.000;
      } //end if

      // Desperation for ammo
      if ((self.ammo_rockets < 5.000))
      {
         if ((self.ammo_shells < 10.000))
         {
            if ((self.ammo_nails < 20.000))
            {
               weight = (weight + 2000.000);
            } //end if
         } //end if
      } //end if
   } //end if

   // ===== TWEAK #1: Risk-aware item scoring (smart own/deny) =====
   // Calculates threat (enemy proximity penalty) and need (critical item boost) to make
   // bots grab high-priority items (RL, Quad, low ammo) while avoiding contested zones.
   // Prevents suicide rushes for minor items when enemy controls the area, enables smart
   // item denial when the bot actually needs it. Risk-reward replaces blind item chasing.
   local float threat;
   local float need;

   threat = 0;
   // Threat assessment: subtract weight when visible enemy is near the item
   if (self.enemy)
   {
      if (enemyvisible (self.enemy))
      {
         local float risk_dist;
         risk_dist = vlen ((self.enemy.origin - e.origin));
         if ((risk_dist < 400.000))
         {
            // ===== BULLY MODE: Aggressive Item Control =====
            // If we are stacked (Quad OR (Health > 100 + Rockets)),
            // treat the enemy presence as a BONUS (Bait them!)
            if ((self.items & IT_QUAD) || ((self.health > 100.000) && (self.items & IT_ROCKET_LAUNCHER)))
            {
               // Add weight instead of subtracting!
               // "Come get some!" - Bot wants to fight near items when powerful
               threat = -500.000; // Negative threat = Bonus weight
               // PHASE 3 FIX: Commit to this behavior for 3 seconds
               self.bully_commit_time = (time + 3.000);
            }
            else
            {
               if ((time < self.bully_commit_time))
               {
                  // PHASE 3 FIX: Sustain aggression even if Quad just dropped
                  // Prevents instant decision flipping (hysteresis)
                  threat = -500.000;
               } //end if
               else
               {
                  // Standard behavior: Cautious/Smart avoid
                  // Enemy within 400 units of item—subtract risk penalty (closer = more dangerous)
                  // 0.2 multiplier scales threat: 400u away = 0 penalty, 0u away = 80 penalty
                  threat = ((400.000 - risk_dist) * 0.200);
               } //end if
            }
            // ===== END BULLY MODE =====
         } //end if
      } //end if
   } //end if

   need = 0;
   // Need assessment: boost weight for critical items based on bot's current loadout
   // Rockets critical: boost by 100 if we have <5 (prevents dry RL)
   if ((e.classname == "item_rockets"))
   {
      if ((self.ammo_rockets < 5.000))
      {
         need = 100.000;
      } //end if
   } //end if
   // Quad damage: boost by 150 if we lack Quad or Pentagram (game-changing powerup)
   if ((e.classname == "item_artifact_super_damage"))
   {
      if (!(self.items & (IT_QUAD | IT_INVULNERABILITY)))
      {
         need = 150.000;
      } //end if
   } //end if
   // Rocket launcher: boost by 200 if we don't have one (most critical weapon)
   if ((e.classname == "weapon_rocketlauncher"))
   {
      if (!(self.items & IT_ROCKET_LAUNCHER))
      {
         need = 200.000;
      } //end if
   } //end if
   // Grenade launcher: boost by 100 if we don't have one (strategic weapon)
   if ((e.classname == "weapon_grenadelauncher"))
   {
      if (!(self.items & IT_GRENADE_LAUNCHER))
      {
         need = 100.000;
      } //end if
   } //end if
   // Megahealth: boost by 80 (strategic control point for item denial)
   if ((e.classname == "item_health"))
   {
      if ((e.spawnflags & 2.000))
      {
         // Always valuable for denial, even when healthy
         need = 80.000;
      } //end if
   } //end if

   // Apply risk-reward calculation: add need bonus, subtract threat penalty
   weight = ((weight + need) - threat);

   // Floor clamp: never go below DONT_WANT after risk adjustment
   if ((weight < DONT_WANT))
   {
      weight = DONT_WANT;
   } //end if
   // ===== END TWEAK #1 =====

   // ===== STRATEGIC ITEM CONTROL: Denial & Ambush Multiplier =====
   // High-value items (RL, GL, MH, Quad) should be prioritized for denial when:
   // 1. Leading in score (deny opponent's comeback)
   // 2. Enemy nearby (ambush opportunity - they're likely going for it)
   // This implements the "suspect opponents are going for high value items" strategy.
   if ((weight > DONT_WANT))
   {
      local float is_strategic_item;
      local float denial_multiplier;
      is_strategic_item = FALSE;
      denial_multiplier = 1.000;

      // Identify strategic control points
      if ((e.classname == "weapon_rocketlauncher") || (e.classname == "weapon_grenadelauncher"))
      {
         is_strategic_item = TRUE;
      } //end if
      if ((e.classname == "item_artifact_super_damage") || (e.classname == "item_artifact_invulnerability") || (e.classname == "item_artifact_invisibility"))
      {
         is_strategic_item = TRUE;
      } //end if
      if ((e.classname == "item_health") && (e.spawnflags & 2.000))
      {
         is_strategic_item = TRUE; // Megahealth
      } //end if

      // Apply denial/ambush strategy for strategic items
      if (is_strategic_item)
      {
         // DENIAL: If leading by 5+ frags, boost strategic items by 50% (prevent comeback)
         if ((self.frags >= 5.000))
         {
            if (self.enemy)
            {
               if ((self.frags > (self.enemy.frags + 5.000)))
               {
                  denial_multiplier = 1.500; // 50% boost
               } //end if
            } //end if
         } //end if

         // AMBUSH: If enemy is near item (400-800 units), boost by 30% (they're likely going for it)
         // This is the "find them there" strategy - predict enemy movement toward valuable items
         if (self.enemy)
         {
            local float enemy_item_dist;
            enemy_item_dist = vlen((self.enemy.origin - e.origin));
            if ((enemy_item_dist > 400.000) && (enemy_item_dist < 800.000))
            {
               // Enemy is approaching item - intercept opportunity
               denial_multiplier = (denial_multiplier * 1.300); // Stack with denial if both apply
            } //end if
         } //end if

         // Apply the multiplier
         weight = (weight * denial_multiplier);
      } //end if
   } //end if
   // ===== END STRATEGIC ITEM CONTROL =====

   // ===== PROBLEM SOLVER: Vertical Reachability (Rocket Jump for Items) =====
   // Normally, items >45 units above us are ignored (unreachable).
   // But if we have a Rocket Launcher and Health, we can RJ to them.
   if ((e.origin_z > (self.origin_z + 45.000)))
   {
      // Default: Bot thinks it's impossible
      local float is_reachable;
      is_reachable = FALSE;
      // PROBLEM: Item is too high.
      // SOLUTION: Do we have a Rocket Launcher, Ammo, and HP to survive the jump?
      if ((self.items & IT_ROCKET_LAUNCHER))
      {
         if ((self.ammo_rockets >= 1.000))
         {
            if ((self.health > 100.000))
            {
               // Check if it's within "Rocket Jump Height" (approx 250 units max)
               if (((e.origin_z - self.origin_z) < 250.000))
               {
                  // It IS reachable via physics abuse!
                  is_reachable = TRUE;
                  // BOOST the weight because these items (Quad, Red Armor) are usually critical
                  weight = (weight * 1.500);
               } //end if
            } //end if
         } //end if
      } //end if
      // If we can't solve the height problem, ignore it.
      if (!is_reachable)
      {
         // Only strict reject if it's REALLY high (prevent jumping at ceilings)
         if ((e.origin_z > (self.origin_z + 64.000)))
         {
            return (DONT_WANT);
         } //end if
      } //end if
      else
      {
         // Flag this goal as requiring a special move
         // (We'll detect height in Botmovetogoal and execute RJ)
         self.check_climb = TRUE;
      } //end if
   } //end if
   // ===== END PROBLEM SOLVER: Vertical Reachability =====

   if ((weight > DONT_WANT))
   {
      if (!OK_HIGH)
      {
         // ===== ENHANCED TWEAK: Rocket Jump Reachability (Gap Crosser + Horizontal RJ) =====
         // If item is high (up to 450 units) OR far horizontally (>350 units), but we have
         // a Rocket Launcher, Health, and Ammo, we MARK IT AS REACHABLE instead of ignoring it.
         // This enables bots to reach Quad Damage on DM2, cross gaps on DM3, and use RJ for mobility.
         local float can_rj;
         local float horiz_dist;
         can_rj = FALSE;
         if (((self.items & IT_ROCKET_LAUNCHER) && (self.ammo_rockets >= 1.000)))
         {
            if ((self.health >= 40.000))
            {
               can_rj = TRUE;
            } //end if
         } //end if

         // Calculate horizontal distance to item (ignore Z axis for gap measurement)
         local vector item_xy;
         local vector bot_xy;
         bot_xy = self.origin;
         bot_xy_z = 0;
         item_xy = e.origin;
         item_xy_z = 0;
         horiz_dist = vlen((item_xy - bot_xy));

         // Check VERTICAL reachability (high ledges)
         if ((e.absmin_z > (self.origin_z + MAXJUMP)))
         {
            // If we can RJ and it's within "Rocket Jump Height" (approx 450u)
            if ((can_rj && (e.absmin_z < (self.origin_z + 450.000))))
            {
               // KEEP weight! (Do nothing, let it pass)
               // Bonus: Boost desire slightly because high items are usually good.
               weight = (weight * 1.200);
            } //end if
            else
            {
               // Truly unreachable vertically
               weight = DONT_WANT;
            } //end if
         } //end if

         // Check HORIZONTAL reachability (distant items across gaps or open areas)
         // NEW: With horizontal RJ trigger (dis > 350), distant items become accessible
         if ((horiz_dist > 350.000))
         {
            if (can_rj)
            {
               // Item is far but RJ-accessible for speed/gap crossing
               // Boost weight because bot will use dynamic RJ to reach it
               weight = (weight * 1.300);
            } //end if
            else
            {
               // Too far without RJ capability - reduce priority
               // (Don't set DONT_WANT because pathfinding might find route)
               weight = (weight * 0.700);
            } //end if
         } //end if
         // ===== END ENHANCED TWEAK =====
      } //end if
   } //end if
   if ((weight > DONT_WANT))
   {
      if (!TrueReachable (e))
      {
         weight = DONT_WANT;
      } //end if

      // ===== FAT TRACE: Bar Detection (Anti-Cookie Jar) =====
      // Problem: Center ray sees item through bars, but bot is too fat to fit.
      // Solution: Trace lines from the bot's left and right shoulders.
      // If sides are blocked but center is clear, it's a trap (bars/grate).
      else if (visible (e)) // Only check if we can actually see it
      {
         local vector right_ofs;
         local vector targ_org;
         local float f_right;
         local float f_left;

         makevectors (self.angles); // Get bot orientation
         right_ofs = (v_right * 14.000); // Check 14 units to the side (bot radius is 16)

         // Use item origin for target
         targ_org = e.origin;

         // 1. Right Shoulder Trace
         traceline ((self.origin + right_ofs), (targ_org + right_ofs), TRUE, self);
         f_right = trace_fraction;

         // 2. Left Shoulder Trace
         traceline ((self.origin - right_ofs), (targ_org - right_ofs), TRUE, self);
         f_left = trace_fraction;

         // If either shoulder hits a wall early (while center is visible)
         // trace_fraction < 1.0 means we hit something.
         // trace_ent != e means we didn't hit the item itself.
         if (((f_right < 1.000) && (trace_ent != e)) || ((f_left < 1.000) && (trace_ent != e)))
         {
            // We are too fat to fit!
            // Only reject if the blockage is CLOSE to us (the bars are in our face)
            // If blockage is far away, we might be able to navigate around.
            if ((vlen ((trace_endpos - self.origin)) < 64.000))
            {
               weight = DONT_WANT;
            } //end if
         } //end if
      } //end if
      // ======================================================
   } //end if
   return (weight);
}; //end of the function itemweight
vector (float n) chooseRoamTarget =
{
   local float len;
   local float r;
   local float d;
   local float m;
   local float lnd;
   local vector dir;
   local vector below;
   local vector bestorg;
   local vector deny_dir;
   local float saved_trace_allsolid;
   local float saved_trace_startsolid;
   local float saved_trace_fraction;
   local vector saved_trace_endpos;
   local vector saved_trace_plane_normal;
   local float saved_trace_plane_dist;
   local entity saved_trace_ent;
   local float saved_trace_inopen;
   local float saved_trace_inwater;
   local float roam_trace_fraction;

   // ===== PORTAL AWARENESS: Prioritize Teleporter Exploration =====
   // Bots actively seek out teleporters as "mystery boxes" to explore
   // instead of just wandering randomly - creates map flow and discovery
   if ((random () < 0.300))
   {
      local entity head;
      local float best_dist;
      local entity best_tele;

      best_dist = 9999.000;
      best_tele = world;

      // Scan for nearby teleporter nodes (BotPath with target field)
      head = find (world,classname,"BotPath");
      while (head)
      {
         // Teleporter nodes have a target (destination)
         if ((head.target != ""))
         {
            d = vlen ((head.origin - self.origin));
            // Prefer closer teleporters but not too close (already used)
            if ((d > 100.000))
            {
               if ((d < best_dist))
               {
                  best_dist = d;
                  best_tele = head;
               } //end if
            } //end if
         } //end if
         head = find (head,classname,"BotPath");
      } //end while

      // Found a teleporter? Go there!
      if (best_tele)
      {
         if ((random () < 0.500))
         {
            return (best_tele.origin);
         } //end if
      } //end if
   } //end if
   // ===== END PORTAL AWARENESS =====

   bestorg = self.origin;
   d = random ();
   if ((d < 0.800))
   {
      r = random ();
      m = TRUE;
      if ((r < 0.500))
      {
         m = CONTENT_EMPTY;
      } //end if
      bestorg_x = (bestorg_x + (m * ((700.000 * random ()) + 50.000)));
   } //end if
   if ((d > 0.200))
   {
      r = random ();
      m = TRUE;
      if ((r < 0.500))
      {
         m = CONTENT_EMPTY;
      } //end if
      bestorg_y = (bestorg_y + (m * ((700.000 * random ()) + 50.000)));
   } //end if
   bestorg_z = (((bestorg_z + ((MOVETYPE_WALK * MAXJUMP) * random ())) - (FL_SWIM * MAXJUMP)) - TRUE);
   saved_trace_allsolid = trace_allsolid;
   saved_trace_startsolid = trace_startsolid;
   saved_trace_fraction = trace_fraction;
   saved_trace_endpos = trace_endpos;
   saved_trace_plane_normal = trace_plane_normal;
   saved_trace_plane_dist = trace_plane_dist;
   saved_trace_ent = trace_ent;
   saved_trace_inopen = trace_inopen;
   saved_trace_inwater = trace_inwater;
   traceline (self.origin,bestorg,TRUE,self);
   roam_trace_fraction = trace_fraction;
   trace_allsolid = saved_trace_allsolid;
   trace_startsolid = saved_trace_startsolid;
   trace_fraction = saved_trace_fraction;
   trace_endpos = saved_trace_endpos;
   trace_plane_normal = saved_trace_plane_normal;
   trace_plane_dist = saved_trace_plane_dist;
   trace_ent = saved_trace_ent;
   trace_inopen = saved_trace_inopen;
   trace_inwater = saved_trace_inwater;
   dir = normalize ((bestorg - self.origin));
   len = vlen ((bestorg - self.origin));
   bestorg = (self.origin + (dir * ((len * roam_trace_fraction) - KINDA_WANT)));
   below = bestorg;
   below_z = (dropline (below) + TRUE);
   lnd = pointcontents (below);
   if ((lnd != CONTENT_EMPTY))
   {
      if ((lnd != CONTENT_WATER))
      {
         if ((n < MOVETYPE_PUSH))
         {
            return (chooseRoamTarget ((n + TRUE)));
         } //end if
      } //end if
   } //end if
   below = (bestorg - (SVC_INTERMISSION * dir));
   below_z = (dropline (below) + TRUE);
   lnd = pointcontents (below);
   if ((lnd != CONTENT_EMPTY))
   {
      if ((lnd != CONTENT_WATER))
      {
         if ((n < MOVETYPE_PUSH))
         {
            return (chooseRoamTarget ((n + TRUE)));
         } //end if
      } //end if
   } //end if
   r = (n + (random () * MOVETYPE_WALK));
   if (((bestorg_z > self.origin_z) || (r > MOVETYPE_FLY)))
   {
      bestorg_z = (below_z - self.mins_z);
   } //end if
   len = vlen ((bestorg - self.origin));
   if ((len < KINDA_WANT))
   {
      if ((n < MOVETYPE_PUSH))
      {
         return (chooseRoamTarget ((n + TRUE)));
      } //end if
   } //end if
   // When leading, bias roam toward the enemy to deny spawns/items.
   if (self.lead_score)
   {
      if (self.enemy)
      {
         if ((self.enemy != world))
         {
            deny_dir = (self.enemy.origin - self.origin);
            if ((vlen (deny_dir) > FALSE))
            {
               deny_dir = normalize (deny_dir);
               bestorg = (bestorg + (deny_dir * 100.000));
               if ((self.skil > TRUE))
               {
                  bestorg_z = (bestorg_z + (random () * 50.000));
               } //end if
            } //end if
         } //end if
      } //end if
   } //end if
   return (bestorg);
}; //end of the function chooseRoamTarget
float (entity e) cacheweight =
{
   local float weight;
   local float tw;
   local float dis;
   local float it;

   weight = FALSE;
   if ((e.lastbot == self))
   {
      if ((e.lasttime > (time - FL_SWIM)))
      {
         return (weight);
      } //end if
   } //end if
   dis = vlen ((self.origin - e.origin));
   it = self.items;
   e.pendingcache = world;
   e.pendinglen = FALSE;
   if (e.rocketcache)
   {
      if (((e.rocketcache.solid == SOLID_TRIGGER) || (e.rocketcache.nextthink < (time + MOVETYPE_STEP))))
      {
         if (((self.rocketcache != e.rocketcache) || (self.rocketlen > e.rocketlen)))
         {
            weight = ((1000000.000 - e.rocketlen) - (FL_SWIM * dis));
            if ((it & IT_ROCKET_LAUNCHER))
            {
               weight = (weight * 0.500);
            } //end if
            e.pendingcache = e.rocketcache;
            e.pendinglen = e.rocketlen;
         } //end if
      } //end if
   } //end if
   if (e.lightningcache)
   {
      if (((e.lightningcache.solid == SOLID_TRIGGER) || (e.lightningcache.nextthink < (time + MOVETYPE_STEP))))
      {
         if (((self.lightningcache != e.lightningcache) || (self.lightninglen > e.lightninglen)))
         {
            tw = ((1000000.000 - e.lightninglen) - (FL_SWIM * dis));
            if ((it & IT_LIGHTNING))
            {
               tw = (tw * 0.500);
            } //end if
            if ((tw > weight))
            {
               weight = tw;
               e.pendingcache = e.lightningcache;
               e.pendinglen = e.lightninglen;
            } //end if
         } //end if
      } //end if
   } //end if
   if ((self.armorvalue < 101.000))
   {
      if (e.armorcache)
      {
         if (((e.armorcache.solid == SOLID_TRIGGER) || (e.armorcache.nextthink < (time + MOVETYPE_STEP))))
         {
            if (((self.armorcache != e.armorcache) || (self.armorlen > e.armorlen)))
            {
               tw = ((1000000.000 - e.armorlen) - (FL_SWIM * dis));
               if ((tw > weight))
               {
                  weight = tw;
                  e.pendingcache = e.armorcache;
                  e.pendinglen = e.armorlen;
               } //end if
            } //end if
         } //end if
      } //end if
   } //end if
   if (e.nailcache)
   {
      if (((e.nailcache.solid == SOLID_TRIGGER) || (e.nailcache.nextthink < (time + FL_SWIM))))
      {
         if (((self.nailcache != e.nailcache) || (self.naillen > e.naillen)))
         {
            tw = ((1000000.000 - e.naillen) - (FL_SWIM * dis));
            if ((it & IT_SUPER_NAILGUN))
            {
               tw = (tw * 0.500);
            } //end if
            if ((tw > (weight + 2500.000)))
            {
               weight = tw;
               e.pendingcache = e.nailcache;
               e.pendinglen = e.naillen;
            } //end if
         } //end if
      } //end if
   } //end if
   if (e.grenadecache)
   {
      if (((e.grenadecache.solid == SOLID_TRIGGER) || (e.grenadecache.nextthink < (time + FL_SWIM))))
      {
         if (((self.grenadecache != e.grenadecache) || (self.grenadelen > e.grenadelen)))
         {
            tw = ((1000000.000 - e.grenadelen) - (FL_SWIM * dis));
            if ((it & IT_GRENADE_LAUNCHER))
            {
               tw = (tw * 0.500);
            } //end if
            if ((tw > (weight + 2500.000)))
            {
               weight = tw;
               e.pendingcache = e.grenadecache;
               e.pendinglen = e.grenadelen;
            } //end if
         } //end if
      } //end if
   } //end if
   if (e.powerupcache)
   {
      if ((e.powerupcache.solid == SOLID_TRIGGER))
      {
         if (((self.powerupcache != e.powerupcache) || (self.poweruplen > e.poweruplen)))
         {
            tw = ((1000000.000 - e.poweruplen) - (FL_SWIM * dis));
            if ((tw > weight))
            {
               weight = tw;
               e.pendingcache = e.powerupcache;
               e.pendinglen = e.poweruplen;
            } //end if
         } //end if
      } //end if
   } //end if
   return (weight);
}; //end of the function cacheweight
float (entity e) pathweight =
{
   local float OK_HIGH;
   local float weight;
   local vector org;

   weight = DONT_WANT;

   // ===== PLATFORM MASTERY: Platform Awareness =====
   // If the target node is on a platform, we assume it's reachable
   // even if it's currently high up (the lift will come down).
   if (e.is_platform_node)
   {
      OK_HIGH = TRUE;
   } //end if
   // ================================================

   if (TrueReachable (e))
   {
      weight = cacheweight (e);
      if ((weight > FALSE))
      {
         return (weight);
      } //end if
      weight = vlen ((self.origin - e.origin));
      weight = ((50.000 * SEARCH_RADIUS) - weight);

      // ===== DANGER & GLORY: Semantic Interpretation =====
      // 1. FADE SCENTS: If it's been a while (60s), reduce the intensity
      // This simulates "the coast is clear" or "meta shift".
      if (((time - e.scent_time) > 60.000))
      {
         e.danger_scent = (e.danger_scent * 0.500);
         e.glory_score = (e.glory_score * 0.500);
         e.scent_time = time;
      } //end if

      // 2. FEAR: Subtract weight for Danger (Bots avoid this node)
      // High skill bots respect danger more (survival instinct)
      if ((e.danger_scent > 0.000))
      {
         // e.g. 3 deaths = 30 danger. 30 * 100 = 3000 penalty cost.
         weight = (weight - (e.danger_scent * 100.000));
      } //end if

      // 3. GREED: Add weight for Glory (Bots want to camp here)
      // Only if we are roaming (no enemy) and healthy
      if (((!self.enemy && (self.health > 80.000)) && (e.glory_score > 0.000)))
      {
         // e.g. 5 kills = 50 glory. 50 * 50 = 2500 bonus attraction.
         weight = (weight + (e.glory_score * 50.000));
      } //end if
      // ===================================================

      // ===== STREET SMARTS: Traffic Awareness =====
      // Adjust weight based on Traffic + Intent

      // 1. HUNTING: If we are looking for a fight (healthy, no enemy yet)
      // Prefer High Traffic nodes (The "Highway")
      if (!self.enemy && self.health > 80)
      {
         // Add bonus for busy areas (max +2000 weight)
         weight = weight + (e.traffic_score * 20.0);
      }

      // 2. FLEEING / SNEAKING: If we are hurt
      // Prefer Low Traffic nodes (The "Back Alley")
      else if (self.health < 40)
      {
         // Subtract penalty for busy areas (Avoid the highway!)
         // e.g., Traffic 50 * 50 = -2500 weight.
         weight = weight - (e.traffic_score * 50.0);
      }
      // ============================================

      if ((e.lastbot == self))
      {
         if ((e.lasttime > (time - MOVETYPE_TOSS)))
         {
            weight = DONT_WANT;

         } //end if
         else
         {
            if ((e.lasttime > (time - LOOPTIME)))
            {
               weight = ((weight - (FL_SWIM * SEARCH_RADIUS)) - (((45.000 * SEARCH_RADIUS) * ((LOOPTIME + e.lasttime) - time)) / LOOPTIME));
            } //end if
         } //end if

      } //end if
      else
      {
         if (teamplay)
         {
            if ((e.lastbot.team == self.team))
            {
               if ((e.lasttime > (time - 1.200)))
               {
                  weight = DONT_WANT;

               } //end if
               else
               {
                  if ((e.lasttime > (time - FL_SWIM)))
                  {
                     weight = (weight - SEARCH_RADIUS);
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
   } //end if
   return (weight);
}; //end of the function pathweight

void () goForAir =
{
   local vector bestorg;
   local entity botTarget;
   local float saved_trace_allsolid;
   local float saved_trace_startsolid;
   local float saved_trace_fraction;
   local vector saved_trace_endpos;
   local vector saved_trace_plane_normal;
   local float saved_trace_plane_dist;
   local entity saved_trace_ent;
   local float saved_trace_inopen;
   local float saved_trace_inwater;
   local float air_trace_inopen;

   if (VERBOSEBOT)
   {
      dprint (self.teamname);
      dprint (self.netname);
      dprint (" needs air!\n");
   } //end if
   bestorg = self.origin;
   bestorg_z = (bestorg_z + 800.000);
   saved_trace_allsolid = trace_allsolid;
   saved_trace_startsolid = trace_startsolid;
   saved_trace_fraction = trace_fraction;
   saved_trace_endpos = trace_endpos;
   saved_trace_plane_normal = trace_plane_normal;
   saved_trace_plane_dist = trace_plane_dist;
   saved_trace_ent = trace_ent;
   saved_trace_inopen = trace_inopen;
   saved_trace_inwater = trace_inwater;
   traceline (self.origin,bestorg,TRUE,self);
   air_trace_inopen = trace_inopen;
   trace_allsolid = saved_trace_allsolid;
   trace_startsolid = saved_trace_startsolid;
   trace_fraction = saved_trace_fraction;
   trace_endpos = saved_trace_endpos;
   trace_plane_normal = saved_trace_plane_normal;
   trace_plane_dist = saved_trace_plane_dist;
   trace_ent = saved_trace_ent;
   trace_inopen = saved_trace_inopen;
   trace_inwater = saved_trace_inwater;
   if (!air_trace_inopen)
   {
      bestorg = chooseRoamTarget (TRUE);
      bestorg_z = (bestorg_z + 200.000);
   } //end if
   botTarget = self.goalentity;
   Bot_RequestGoal (self,85.000,0.800,botTarget,bestorg,R_GOAL_AIR_SEEK,"air seek");
   if ((self.goalentity.classname != "BotTarget"))
   {
      objerror ("bad bot target in botgoal! 1\n");
   } //end if
}; //end of the function goForAir

void (entity item) ageCache =
{
   if (self.rocketcache)
   {
      self.rocketlen = (self.rocketlen + TRUE);
   } //end if
   if (self.lightningcache)
   {
      self.lightninglen = (self.lightninglen + TRUE);
   } //end if
   if (self.armorcache)
   {
      self.armorlen = (self.armorlen + TRUE);
   } //end if
   if (self.powerupcache)
   {
      self.poweruplen = (self.poweruplen + TRUE);
   } //end if
   if (self.nailcache)
   {
      self.naillen = (self.naillen + TRUE);
   } //end if
   if (self.grenadecache)
   {
      self.grenadelen = (self.grenadelen + TRUE);
   } //end if
   if ((item.solid == SOLID_TRIGGER))
   {
      if ((self.rocketcache == item))
      {
         self.rocketlen = TRUE;

      } //end if
      else
      {
         if ((self.lightningcache == item))
         {
            self.lightninglen = TRUE;

         } //end if
         else
         {
            if ((self.armorcache == item))
            {
               self.armorlen = TRUE;

            } //end if
            else
            {
               if ((self.powerupcache == item))
               {
                  self.poweruplen = TRUE;

               } //end if
               else
               {
                  if ((self.nailcache == item))
                  {
                     self.naillen = TRUE;

                  } //end if
                  else
                  {
                     if ((self.grenadecache == item))
                     {
                        self.grenadelen = TRUE;
                     } //end if
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
   } //end if
}; //end of the function ageCache

void () resetCache =
{
   self.pendingcache = world;
   self.pendinglen = FALSE;
   if (self.rocketcache)
   {
      if ((self.rocketcache.solid == SOLID_NOT))
      {
         self.rocketcache = world;
         self.rocketlen = FALSE;
      } //end if
   } //end if
   if (self.lightningcache)
   {
      if ((self.lightningcache.solid == SOLID_NOT))
      {
         self.lightningcache = world;
         self.lightninglen = FALSE;
      } //end if
   } //end if
   if (self.armorcache)
   {
      if ((self.armorcache.solid == SOLID_NOT))
      {
         self.armorcache = world;
         self.armorlen = FALSE;
      } //end if
   } //end if
   if (self.powerupcache)
   {
      if ((self.powerupcache.solid == SOLID_NOT))
      {
         self.powerupcache = world;
         self.poweruplen = FALSE;
      } //end if
   } //end if
   if (self.nailcache)
   {
      if ((self.nailcache.solid == SOLID_NOT))
      {
         self.nailcache = world;
         self.naillen = FALSE;
      } //end if
   } //end if
   if (self.grenadecache)
   {
      if ((self.grenadecache.solid == SOLID_NOT))
      {
         self.grenadecache = world;
         self.grenadelen = FALSE;
      } //end if
   } //end if
}; //end of the function resetCache

void () updateBotCache =
{
   if (self.pendingcache.th_update)
   {
      self.pendingcache.th_update ();

   } //end if
   else
   {
      dprint ("Error - no think update for ");
      dprint (self.pendingcache.classname);
      dprint ("\n");
   } //end if
   self.pendingcache = world;
   self.pendinglen = FALSE;
}; //end of the function updateBotCache

// ===== TACTICAL AI: Global Scavenger Hunt =====
// When the bot has no local targets (alone/lost), scan the ENTIRE map
// for high-value items (RL, LG, RA, Mega) and navigate towards them.
// Gives bots "purpose" instead of random bouncing when idle.
entity () FindMapGoal =
{
   local entity head;
   local entity best_ent;
   local float best_val;
   local float val;
   local float d;

   best_ent = world;
   best_val = -1000.000;

   // Pass 1: Rocket Launcher (Priority #1 if we don't have it)
   head = find (world,classname,"weapon_rocketlauncher");
   while (head)
   {
      if ((head.solid != SOLID_NOT))
      {
         // Item is available (spawned)
         d = vlen ((head.origin - self.origin));
         val = (5000.000 - d);
         // Closer is better
         // If we already have it, drastic score penalty (only get it if VERY close)
         if ((self.items & IT_ROCKET_LAUNCHER))
         {
            val = (val - 6000.000);
         } //end if
         if ((val > best_val))
         {
            best_val = val;
            best_ent = head;
         } //end if
      } //end if
      head = find (head,classname,"weapon_rocketlauncher");
   } //end while

   // Pass 2: Lightning Gun (Priority #2)
   head = find (world,classname,"weapon_lightning");
   while (head)
   {
      if ((head.solid != SOLID_NOT))
      {
         d = vlen ((head.origin - self.origin));
         val = (4500.000 - d);
         if ((self.items & IT_LIGHTNING))
         {
            val = (val - 6000.000);
         } //end if
         if ((val > best_val))
         {
            best_val = val;
            best_ent = head;
         } //end if
      } //end if
      head = find (head,classname,"weapon_lightning");
   } //end while

   // Pass 3: Red Armor (Always good if armor is below 100)
   if ((self.armorvalue < 100.000))
   {
      head = find (world,classname,"item_armor2");
      // Red Armor
      while (head)
      {
         if ((head.solid != SOLID_NOT))
         {
            d = vlen ((head.origin - self.origin));
            val = (6000.000 - d);
            // High Priority
            if ((val > best_val))
            {
               best_val = val;
               best_ent = head;
            } //end if
         } //end if
         head = find (head,classname,"item_armor2");
      } //end while
   } //end if

   // Pass 4: Megahealth (if health is below 100)
   if ((self.health < 100.000))
   {
      head = find (world,classname,"item_health");
      while (head)
      {
         // Check healamount to ensure it's a Mega (usually 100)
         if ((head.solid != SOLID_NOT))
         {
            if ((head.healamount > 90.000))
            {
               d = vlen ((head.origin - self.origin));
               val = (5500.000 - d);
               if ((val > best_val))
               {
                  best_val = val;
                  best_ent = head;
               } //end if
            } //end if
         } //end if
         head = find (head,classname,"item_health");
      } //end while
   } //end if

   // ===== DEBUG LOGGING: Goal Selection (Change-Only) =====
   // Only log when goal CHANGES (eliminates repeated spam while traveling)
   if (bot_debug_enabled && (best_ent != self.last_logged_goal))
   {
      bprint ("[");
      bprint (self.netname);
      bprint ("] GOAL: ");

      if (best_ent != world)
      {
         bprint (best_ent.classname);
         bprint (" (score=");
         bprint (ftos(best_val));
         bprint (", dist=");
         bprint (ftos(vlen(best_ent.origin - self.origin)));
         bprint ("u)\n");
      }
      else
      {
         bprint ("None found (best_val=");
         bprint (ftos(best_val));
         bprint (")\n");
      }

      // Remember what we logged
      self.last_logged_goal = best_ent;
   } //end if

   return (best_ent);
}; //end of the function FindMapGoal
// ===== END TACTICAL AI: Global Scavenger Hunt =====

void () aibot_chooseGoal =
{
   local vector org;
   local vector bestorg;
   local float best;
   local float weight;
   local float d1;
   local float d2;
   local float OK_NOTVIS;
   local entity e;
   local entity current;
   local entity botTarget;
   local string tmp;
   local float my_score;
   local float enemy_score;
   local float avg_speed;
   local vector pred_dir;
   local vector pred_pos;
   local float intent;
   local float best_noise;
   local float cand_noise;
   local float select;

   botTarget = self.goalentity;
   // Score-based denial: when leading by 5+, favor denial/safer routing.
   my_score = self.frags;
   enemy_score = CAM_IDLE;
   self.lead_score = FALSE;
   if (self.enemy)
   {
      if ((self.enemy != world))
      {
         enemy_score = self.enemy.frags;
      } //end if
   } //end if
   if ((my_score > (enemy_score + 5.000)))
   {
      self.lead_score = TRUE;
   } //end if
   // Track recent enemy speeds and flag intercept mode on sustained fast movement.
   self.intercept_flag = CAM_IDLE;
   avg_speed = CAM_IDLE;
   if (self.enemy)
   {
      if ((self.enemy != world))
      {
         self.enemy_vel_pat0 = self.enemy_vel_pat1;
         self.enemy_vel_pat1 = self.enemy.velocity;
         avg_speed = ((vlen (self.enemy_vel_pat0) + vlen (self.enemy_vel_pat1)) * 0.500);
         if ((self.skil > TRUE))
         {
            if ((avg_speed > 300.000))
            {
               self.intercept_flag = SPAWNFLAG_SUPERSPIKE;
            } //end if
         } //end if
      } //end if
   } //end if
   if ((self.lefty & FAR_SEEK))
   {
      self.lefty = ((self.lefty - (self.lefty & LOCAL_TIME)) - FAR_SEEK);
   } //end if
   if ((self.lefty & ONTRAIN))
   {
      self.lefty = (self.lefty - ONTRAIN);
   } //end if
   self.lefty = (self.lefty + TRUE);
   current = botTarget.goalentity;
   self.nav_search_time = (time + MOVETYPE_STEP);
   best = DONT_WANT;
   best_noise = -1.000;
   OK_NOTVIS = FALSE;
   if ((self.air_finished < (time + MOVETYPE_FLYMISSILE)))
   {
      goForAir ();
      return ;
   } //end if
   intent = Bot_EffectiveIntent (self);
   if (((intent != BOT_INTENT_RESUPPLY) && (intent != BOT_INTENT_EXPLORE)))
   {
      return ;
   } //end if
   if (((self.lefty & LOCAL_TIME) < MOVETYPE_FLY))
   {
      e = findradius (self.origin,SEARCH_RADIUS);
      while (e)
      {
         if (Bot_IsAvoidedTarget (e))
         {
            e = e.chain;
            continue;
         } //end if
         weight = DONT_WANT;
         if ((e == current))
         {
            weight = DONT_WANT;

         } //end if
         else
         {
            if (e.pathtype)
            {
               weight = DONT_WANT;

            } //end if
            else
            {
               // ===== CUNNING AI: Spawn Camping (Item Timing) =====
               // OLD: Ignored all picked-up items (SOLID_NOT)
               // NEW: Smart bots "camp" high-value items about to respawn
               if ((e.solid == SOLID_NOT))
               {
                  // DEFAULT: Ignore empty spots
                  weight = DONT_WANT;

                  // EXCEPTION: High-Value Item "Spawn Camping"
                  // If a critical item is respawning soon (<10s), treat it as valid target.
                  // Simulates bot "knowing" the timer (heard pickup / tracking cycle).
                  local float is_valuable;
                  is_valuable = FALSE;

                  if ((e.classname == "weapon_rocketlauncher"))
                  {
                     is_valuable = TRUE;
                  } //end if
                  if ((e.classname == "item_artifact_super_damage"))
                  {
                     is_valuable = TRUE;
                  } //end if
                  if ((e.classname == "item_armor2"))
                  {
                     is_valuable = TRUE;
                  } //end if
                  if ((e.classname == "item_health"))
                  {
                     if ((e.healamount > 90.000))
                     {
                        is_valuable = TRUE;
                     } //end if
                  } //end if

                  // Check the timer (nextthink holds respawn time in Quake)
                  if (is_valuable)
                  {
                     if ((e.nextthink > time))
                     {
                        // ===== OPTIMIZED SPAWN CAMPING: 4-Second Window =====
                        // Only commit to camping if it spawns in 4 seconds or less.
                        // Otherwise, keep roaming nearby. Makes bots mobile and harder to predict.
                        // OLD: if ((e.nextthink < (time + 10.000))) // Too long, bot sits idle
                        if ((e.nextthink < (time + 4.000)))
                        // ===== END OPTIMIZED SPAWN CAMPING =====
                        {
                           // It's coming back! Camp it.
                           // Weight increases as spawn time approaches (Don't miss it!)
                           weight = (4000.000 - ((e.nextthink - time) * 100.000));

                           // If we are already there, WAIT (don't run off)
                           if ((vlen ((e.origin - self.origin)) < 100.000))
                           {
                              // Force wait behavior
                              self.nav_search_time = (time + 1.000);
                           } //end if
                        } //end if
                     } //end if
                  } //end if

               } //end if
               // ===== END CUNNING AI: Spawn Camping =====

               if ((weight == DONT_WANT))
               {
                  if ((e.solid == SOLID_TRIGGER))
                  {
                     if (e.istrigger)
                     {
                        weight = trigweight (e);

                     } //end if
                     else
                     {
                        weight = itemweight (e);
                     } //end if

                  } //end if
                  else
                  {
                     weight = thingweight (e);
                  } //end if
               } //end if
            } //end if
         } //end if
         if ((weight > (KINDA_WANT - MOVETYPE_FLY)))
         {
            if ((weight < (WANT + FL_SWIM)))
            {
               if (((e.absmin_z + MAXJUMP) < self.absmin_z))
               {
                  weight = (KINDA_WANT - MOVETYPE_FLY);
               } //end if
            } //end if
         } //end if
         if ((weight > DONT_WANT))
         {
            org = ((e.absmin + e.absmax) * 0.500);
            org_z = (e.absmin_z + TRUE);
            if ((((e.classname == "plat") || (e.classname == "func_plat")) || (e.classname == "train")))
            {
               org_z = (e.absmax_z + TRUE);
            } //end if
            select = FALSE;
            if ((weight > best))
            {
               select = TRUE;
            } //end if
            else if ((weight == best))
            {
               d1 = vlen ((self.origin - bestorg));
               d2 = vlen ((self.origin - org));
               if ((d2 < (d1 - 1.000)))
               {
                  select = TRUE;
               } //end if
               else if ((d1 < (d2 - 1.000)))
               {
                  select = FALSE;
               } //end if
               else
               {
                  cand_noise = Bot_GoalNoise (org);
                  if ((cand_noise > best_noise))
                  {
                     select = TRUE;
                  } //end if
               } //end else
            } //end else
            if (select)
            {
               Bot_RequestGoal (self,60.000,0.000,e,botTarget.origin,R_GOAL_CHOOSE,"choose goal");
               best = weight;
               bestorg = org;
               best_noise = Bot_GoalNoise (org);
               // Predictive intercept: bias the goal toward a fast enemy's path.
               if (self.intercept_flag)
               {
                  if (self.enemy)
                  {
                     if ((self.enemy != world))
                     {
                        if ((e.pathtype == REGULARTARGET))
                        {
                           if ((vlen ((e.origin - self.enemy.origin)) < 500.000))
                           {
                              pred_dir = (self.enemy_vel_pat0 + self.enemy_vel_pat1);
                              if ((vlen (pred_dir) > FALSE))
                              {
                                 pred_dir = normalize (pred_dir);
                                 pred_pos = (self.enemy.origin + (pred_dir * 100.000));
                                 traceline (self.origin,pred_pos,TRUE,self);
                                 if ((trace_fraction == TRUE))
                                 {
                                    bestorg = ((bestorg + pred_pos) * 0.500);
                                 } //end if
                              } //end if
                           } //end if
                        } //end if
                     } //end if
                  } //end if
               } //end if
            } //end if
         } //end if
         e = e.chain;
      } //end while
   } //end if
   resetCache ();
   if ((best < (KINDA_WANT - MOVETYPE_WALK)))
   {
      if ((best > DONT_WANT))
      {
         best = (1000000.000 - 900.000);
      } //end if
      e = findradius (self.origin,SEARCH_RADIUS);
      best = DONT_WANT;
      best_noise = -1.000;
      while (e)
      {
         if (Bot_IsAvoidedTarget (e))
         {
            e = e.chain;
            continue;
         } //end if
         if (((e.pathtype == DROPPED) || (e.pathtype == TELEPORT)))
         {
            if ((e == current))
            {
               weight = DONT_WANT;

            } //end if
            else
            {
               weight = pathweight (e);
            } //end if
            select = FALSE;
            if ((weight > best))
            {
               select = TRUE;
            } //end if
            else if (((weight > DONT_WANT) && (weight == best)))
            {
               d1 = vlen ((self.origin - bestorg));
               d2 = vlen ((self.origin - e.origin));
               if ((d2 < (d1 - 1.000)))
               {
                  select = TRUE;
               } //end if
               else if ((d1 < (d2 - 1.000)))
               {
                  select = FALSE;
               } //end if
               else
               {
                  cand_noise = Bot_GoalNoise (e.origin);
                  if ((cand_noise > best_noise))
                  {
                     select = TRUE;
                  } //end if
               } //end else
            } //end else
            if (select)
            {
               best = weight;
               Bot_RequestGoal (self,60.000,0.000,e,botTarget.origin,R_GOAL_CHOOSE_PATH,"choose path");
               self.pendingcache = e.pendingcache;
               self.pendinglen = e.pendinglen;
               bestorg = e.origin;
               if (!bestorg)
               {
                  bestorg = ((e.absmin + e.absmax) * 0.500);
                  bestorg_z = (e.absmin_z + TRUE);
               } //end if
               best_noise = Bot_GoalNoise (bestorg);
               self.lefty = (self.lefty | FAR_SEEK);
            } //end if
         } //end if
         e = e.chain;
      } //end while
   } //end if
   if ((best > DONT_WANT))
   {
      if (self.pendingcache)
      {
         updateBotCache ();

      } //end if
      else
      {
         if ((botTarget.goalentity.classname != "BotPath"))
         {
            ageCache (botTarget.goalentity);
         } //end if
      } //end if
   } //end if
   // ===== MODIFIED FALLBACK LOGIC: Global Scavenger Hunt =====
   // If no local items or paths found, try GLOBAL SEARCH first.
   // Only revert to random roaming if the map is completely empty of good items.
   if ((best <= DONT_WANT))
   {
      local entity global_item;
      global_item = FindMapGoal ();
      if (global_item)
      {
         // Found a high-value item elsewhere in the map! Go get it.
         Bot_RequestGoal (self,50.000,0.000,global_item,botTarget.origin,R_NAV_GLOBAL,"global goal");
         bestorg = global_item.origin;
         // Give bot more time to travel there before giving up
         self.nav_search_time = (time + 5.000);
      } //end if
      else
      {
         // Map is empty/boring? Fallback to random wander.
         Bot_RequestGoal (self,40.000,0.000,botTarget,botTarget.origin,R_NAV_ROAM,"roam");
         bestorg = chooseRoamTarget (FALSE);
         // Check again soon
         self.nav_search_time = (time + 0.500);
      } //end if
      self.lefty = (self.lefty | FAR_SEEK);
   } //end if
   // ===== END MODIFIED FALLBACK LOGIC =====
   if (VERBOSEBOT)
   {
      dprint (self.teamname);
      dprint (self.netname);
      dprint (" going after ");
      dprint (botTarget.goalentity.classname);
      dprint ("\n");
   } //end if
   if (botTarget.goalentity)
   {
      if ((botTarget.goalentity != botTarget))
      {
         botTarget.goalentity.lastbot = self;
         botTarget.goalentity.lasttime = time;
      } //end if
   } //end if
   if ((botTarget.goalentity.classname == "func_button"))
   {
      bestorg = ((bestorg - botTarget.goalentity.pos2) - (FL_MONSTER * normalize (botTarget.goalentity.pos2)));
   } //end if
   if ((botTarget.classname != "BotTarget"))
   {
      objerror ("bad bot target in botgoal! 2\n");
   } //end if
   setorigin (botTarget,bestorg);
}; //end of the function aibot_chooseGoal
float (entity e) RunAwayWeight =
{
   local float weight;

   if (!TrueReachable (e))
   {
      return (FALSE);
   } //end if
   traceline ((self.enemy.origin + self.enemy.view_ofs),e.origin,TRUE,self.enemy);
   if ((trace_fraction != TRUE))
   {
      weight = WANT;
   } //end if
   if ((trace_inopen && trace_inwater))
   {
      weight = (WANT - MOVETYPE_FLY);
   } //end if
   weight = (weight + (0.100 * vlen ((self.enemy.origin - e.origin))));
   weight = (weight + (KINDA_WANT * random ()));
   return (weight);
}; //end of the function RunAwayWeight

void (entity en) RouteToEnemy;
entity (entity chaser, entity en) BestChaseRoute =
{
   local entity e;
   local entity p;
   local entity tmp;
   local float weight;
   local float best;
   local string ts;

   RouteToEnemy (en);
   e = findradius (chaser.origin,SEARCH_RADIUS);
   best = 1000000.000;
   p = en;
   tmp = self;
   self = chaser;
   while (e)
   {
      if (((e.pathtype == DROPPED) || (e.pathtype == TELEPORT)))
      {
         weight = 1000000.000;
         if ((e.enemycache == en))
         {
            if (TrueReachable (e))
            {
               weight = (e.enemylen + (vlen ((self.origin - e.origin)) * 0.500));
            } //end if
         } //end if
         if ((weight < best))
         {
            best = weight;
            p = e;
         } //end if
      } //end if
      e = e.chain;
   } //end while
   self = tmp;
   return (p);
}; //end of the function BestChaseRoute
