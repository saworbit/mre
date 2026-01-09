
void () endEnemy =
{
   local entity olden;

   olden = self.enemy;
   if ((self.lefty & GETGOODY))
   {
      self.lefty = (self.lefty - (self.lefty & GETGOODY));
   } //end if
   if ((self.lefty & MULTIENEMY))
   {
      self.lefty = (self.lefty - (self.lefty & MULTIENEMY));
   } //end if
   self.enemy = world;
   // Streak credit: count a kill if the last enemy actually died.
   if (olden)
   {
      if ((olden.deadflag != DEAD_NO))
      {
         self.kill_streak = (self.kill_streak + TRUE);
         // Keep taunt momentum in sync with hot streaks.
         self.taunt_streak = self.kill_streak;
      } //end if
   } //end if
   self.think = self.th_walk;
   self.nextthink = (time + 0.100);
   self.combat_search_time = (time - TRUE);
   self.enemyrun = FALSE;
   Stack_Pop_Safe();  // Restore previous goal from stack (Phase 8: Target Stack)
   if ((olden.classname == "player"))
   {
      if ((olden.enemy == self))
      {
         olden.enemy = world;
      } //end if
   } //end if
}; //end of the function endEnemy

// ===== PHASE 8: Target Stack (Brain Memory) =====
// LIFO stack for goal management - bots remember interrupted goals
// and restore them after combat instead of forgetting and wandering.

// Stack_Push: Save current goal and push onto stack (LIFO order)
// Called when: Bot spots enemy while pursuing item/location
void () Stack_Push =
{
   // Shift stack: level 2 → level 3, level 1 → level 2
   self.goal_stack3 = self.goal_stack2;
   self.goal_stack2 = self.goal_stack1;
   // Save current goal to level 1 (top of stack)
   self.goal_stack1 = self.goalentity.goalentity;
}; //end of Stack_Push

// Stack_Pop: Restore previous goal from stack (LIFO order)
// Called when: Combat ends, restore pre-combat goal
void () Stack_Pop =
{
   // Restore goal from level 1 (top of stack)
   self.goalentity.goalentity = self.goal_stack1;
   // Shift stack down: level 2 → level 1, level 3 → level 2
   self.goal_stack1 = self.goal_stack2;
   self.goal_stack2 = self.goal_stack3;
   self.goal_stack3 = world;  // Clear deepest level
}; //end of Stack_Pop

// Stack_Clear: Wipe all stack entries
// Called when: Bot respawns after death
void () Stack_Clear =
{
   self.goal_stack1 = world;
   self.goal_stack2 = world;
   self.goal_stack3 = world;
}; //end of Stack_Clear

// Stack_Pop_Safe: Pop and validate goals until valid one found or stack empty
// Skips invalid goals (picked up items, dead enemies, removed entities)
// Called when: Combat ends, need to restore valid pre-combat goal
void () Stack_Pop_Safe =
{
   local entity tempgoal;
   local float valid_goal_found;

   valid_goal_found = FALSE;

   // Try up to 3 times (depth of stack)
   while ((!valid_goal_found) && (self.goal_stack1 != world))
   {
      tempgoal = self.goal_stack1;
      Stack_Pop();  // Pop goal from stack

      // Validate goal is still worth pursuing
      if (tempgoal != world)
      {
         // Skip if entity was removed
         if (tempgoal.classname == "")
         {
            continue;  // Try next stack entry
         }
         // Skip if item already picked up
         if ((tempgoal.flags & FL_ITEM))
         {
            if (tempgoal.model == "")
            {
               continue;  // Item picked up, try next stack entry
            }
         }
         // Skip if enemy is dead
         if ((tempgoal.classname == "player") || (tempgoal.classname == "dmbot"))
         {
            if (tempgoal.deadflag != DEAD_NO)
            {
               continue;  // Enemy dead, try next stack entry
            }
         }
         // Goal is valid! Restore it
         self.goalentity.goalentity = tempgoal;
         valid_goal_found = TRUE;
      }
   }

   // If no valid goal found in stack, fall back to choosing new goal
   if (!valid_goal_found)
   {
      self.goalentity.goalentity = self.goalentity;  // Reset to idle
   }
}; //end of Stack_Pop_Safe

float (entity target) Bot_IsAvoidedTarget;

// ===== PROJECTILE PREDICTION: Navigation Leading (2026-01-06) =====
// Predicts where enemy will be based on projectile travel time.
// Used for body orientation (ideal_yaw) so bot faces the predicted position.
// Includes wall-clamping to prevent aiming into walls (Obot-inspired).
//
// Parameters:
//   target: Entity to predict (enemy)
//   proj_speed: Projectile speed in units/second (1000 for rockets, 600 for grenades, 0 for hitscan)
//
// Returns: Predicted position vector (or current position if prediction invalid)
vector (entity target, float proj_speed) PredictEnemyPositionForNav =
{
   local vector predicted_pos;
   local float travel_time;
   local float distance;
   local vector direction;
   local float saved_trace_allsolid;
   local float saved_trace_startsolid;
   local float saved_trace_fraction;
   local vector saved_trace_endpos;
   local vector saved_trace_plane_normal;
   local float saved_trace_plane_dist;
   local entity saved_trace_ent;
   local float saved_trace_inopen;
   local float saved_trace_inwater;
   local float nav_trace_fraction;
   local vector nav_trace_endpos;

   // Sanity check
   if (!target || target == world)
   {
      return self.origin;  // No target, return self position
   }

   // For hitscan weapons (proj_speed = 0), no prediction needed
   if (proj_speed <= 0)
   {
      return target.origin;
   }

   // Calculate distance to target
   distance = vlen(target.origin - self.origin);

   // Calculate travel time = distance / speed
   travel_time = distance / proj_speed;

   // Clamp travel time to reasonable values (max 2 seconds prediction)
   if (travel_time > 2.0)
   {
      travel_time = 2.0;
   }

   // Predict future position: current_pos + (velocity * travel_time)
   predicted_pos = target.origin + (target.velocity * travel_time);

   // ===== WALL-CLAMPING (Obot-inspired) =====
   // Don't aim at positions behind walls - validate with traceline
   saved_trace_allsolid = trace_allsolid;
   saved_trace_startsolid = trace_startsolid;
   saved_trace_fraction = trace_fraction;
   saved_trace_endpos = trace_endpos;
   saved_trace_plane_normal = trace_plane_normal;
   saved_trace_plane_dist = trace_plane_dist;
   saved_trace_ent = trace_ent;
   saved_trace_inopen = trace_inopen;
   saved_trace_inwater = trace_inwater;
   traceline(self.origin, predicted_pos, TRUE, self);
   nav_trace_fraction = trace_fraction;
   nav_trace_endpos = trace_endpos;
   trace_allsolid = saved_trace_allsolid;
   trace_startsolid = saved_trace_startsolid;
   trace_fraction = saved_trace_fraction;
   trace_endpos = saved_trace_endpos;
   trace_plane_normal = saved_trace_plane_normal;
   trace_plane_dist = saved_trace_plane_dist;
   trace_ent = saved_trace_ent;
   trace_inopen = saved_trace_inopen;
   trace_inwater = saved_trace_inwater;

   // If trace hit something before reaching predicted position, the path is blocked
   if (nav_trace_fraction < 1.0)
   {
      // Check if the blockage is close to the target (within splash radius ~120 units)
      local float block_dist;
      block_dist = vlen(nav_trace_endpos - target.origin);

      if (block_dist > 120.0)
      {
         // Blockage is far from target - prediction would aim at wall
         // Fall back to current enemy position (conservative aiming)
         return target.origin;
      }
      else
      {
         // Blockage is near target - use the impact point (wall splash)
         return nav_trace_endpos;
      }
   }

   // ===== BOUNDARY CLAMPING =====
   // Ensure prediction doesn't go outside reasonable bounds
   // (Prevents wild predictions if enemy has extreme velocity)
   local float pred_distance;
   pred_distance = vlen(predicted_pos - target.origin);

   // If prediction is more than 500 units from current position, clamp it
   if (pred_distance > 500.0)
   {
      // Clamp to 500 unit sphere around current position
      direction = normalize(predicted_pos - target.origin);
      predicted_pos = target.origin + (direction * 500.0);
   }

   return predicted_pos;
}; //end of PredictEnemyPositionForNav
// ===== END PROJECTILE PREDICTION =====

// ===== PHASE 7: Threat Scoring for Projectile Dodge Prioritization =====
// Calculates enemy threat score based on health, armor, weapon, and powerups.
// Higher score = more dangerous enemy = prioritize dodging their projectiles.
// Returns: Threat score (0 = not a player, higher = more dangerous)
float (entity e) bot_size_player =
{
   if ((e.classname != "player"))
   {
      return (0.000);
   } //end if

   // Base threat from health + armor
   local float sz;
   sz = (e.health + e.armorvalue);

   // Weapon multipliers (more dangerous weapons = higher threat)
   if ((e.weapon == IT_LIGHTNING))
   {
      sz = (sz * 1.500);
   } //end if
   else
   {
      if ((e.weapon == IT_ROCKET_LAUNCHER))
      {
         sz = (sz * 1.300);
      } //end if
      else
      {
         if ((e.weapon == IT_SUPER_NAILGUN))
         {
            sz = (sz * 1.200);
         } //end if
      } //end if
   } //end if

   // Powerup multipliers (quad/pent = extreme threat)
   if ((e.items & IT_QUAD))
   {
      sz = (sz * 4.000);
   } //end if
   if ((e.items & IT_INVULNERABILITY))
   {
      sz = (sz * 2.000);
   } //end if

   return (sz);
}; //end of the function bot_size_player

// ===== PHASE 7: Active Projectile Dodging =====
// Scans for incoming grenades/missiles and executes perpendicular evasion.
// Prioritizes grenades over rockets, factors in owner threat level.
// Adapted from FrikBot with Reaper movement system integration.
// Returns: TRUE if dodging, FALSE if no threat detected
float () bot_dodge_stuff =
{
   local entity head;
   local entity item;
   local float bestrating;
   local float rating;
   local float dist;
   local float type_weight;
   local vector org;
   local vector dir_to_bot;
   local vector vel_dir;
   local vector norm;
   local float dodge_dir;
   local float angle_diff;

   if (((self.enemy == world) && (self.health > 80.000)))
   {
      return (FALSE);
   } //end if

   bestrating = 0.000;
   item = world;

   head = findradius (self.origin, 500.000);
   while (head)
   {
      if (((head.classname == "missile") || (head.classname == "grenade")))
      {
         if ((head.owner != self))
         {
            vel_dir = normalize (head.velocity);
            dir_to_bot = normalize ((self.origin - head.origin));
            if (((vel_dir * dir_to_bot) > 0.300))
            {
               org = (head.origin - self.origin);
               dist = vlen (org);
               if ((dist > 1.000))
               {
                  if ((head.classname == "grenade"))
                  {
                     type_weight = 1.000;
                  } //end if
                  else
                  {
                     type_weight = 0.500;
                  } //end if
                  rating = (type_weight / dist);
                  if ((head.owner != world))
                  {
                     rating = (rating * bot_size_player (head.owner));
                  } //end if
                  if ((rating > bestrating))
                  {
                     bestrating = rating;
                     item = head;
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
      head = head.chain;
   } //end while

   if ((item == world))
   {
      self.avoid = world;
      return (FALSE);
   } //end if

   if ((self.avoid == item))
   {
      return (TRUE);
   } //end if

   norm = normalize (item.velocity);
   if ((random () > 0.500))
   {
      dodge_dir = (vectoyaw (norm) + 90.000);
   } //end if
   else
   {
      dodge_dir = (vectoyaw (norm) - 90.000);
   } //end if

   angle_diff = anglemod ((dodge_dir - self.angles_y));

   if ((angle_diff < 180.000))
   {
      if (!(self.lefty & STRAFE_DIR))
      {
         self.lefty = (self.lefty | STRAFE_DIR);
      } //end if
   } //end if
   else
   {
      if ((self.lefty & STRAFE_DIR))
      {
         self.lefty = (self.lefty - (self.lefty & STRAFE_DIR));
      } //end if
   } //end if

   self.avoid = item;

   return (TRUE);
}; //end of the function bot_dodge_stuff
// ===== END PHASE 7: Active Projectile Dodging =====

// ===== PROBLEM SOLVER: Button/Door Solver =====
// Finds the button that triggers the given door entity.
// Returns world if no button found (might be shootable or auto-opening).
entity (entity door_ent) FindButtonForDoor =
{
   if ((door_ent.targetname == ""))
   {
      return (world);
   } //end if
   local entity b;
   b = find (world,target,door_ent.targetname);
   // Scan for buttons that target this door
   while (b)
   {
      if ((b.classname == "func_button"))
      {
         // Found it! This button opens the door.
         return (b);
      } //end if
      b = find (b,target,door_ent.targetname);
   } //end while
   return (world);
}; //end of the function FindButtonForDoor
// ===== END PROBLEM SOLVER: Button/Door Solver =====

void () CallForHelp =
{
   local entity e;
   local entity p;
   local entity tmp;
   local float d;
   local float saved_trace_allsolid;
   local float saved_trace_startsolid;
   local float saved_trace_fraction;
   local vector saved_trace_endpos;
   local vector saved_trace_plane_normal;
   local float saved_trace_plane_dist;
   local entity saved_trace_ent;
   local float saved_trace_inopen;
   local float saved_trace_inwater;
   local float help_trace_fraction;
   local float saved_enemy_vis;

   if (((self.health >= 30.000) && (random () >= 0.100)))
   {
      return ;
   } //end if

   HELPING = TRUE;
   e = find (world,classname,"dmbot");
   while (e)
   {
      if ((e != self))
      {
         if ((e.team == self.team))
         {
            if ((e.enemy == world))
            {
               if ((e.health > 80.000))
               {
                     if ((e.items & ((((IT_ROCKET_LAUNCHER + IT_LIGHTNING) + IT_SUPER_NAILGUN) + IT_SUPER_SHOTGUN) + IT_GRENADE_LAUNCHER)))
                     {
                         p = BestChaseRoute (e,self.enemy);
                        saved_trace_allsolid = trace_allsolid;
                        saved_trace_startsolid = trace_startsolid;
                        saved_trace_fraction = trace_fraction;
                        saved_trace_endpos = trace_endpos;
                        saved_trace_plane_normal = trace_plane_normal;
                        saved_trace_plane_dist = trace_plane_dist;
                        saved_trace_ent = trace_ent;
                        saved_trace_inopen = trace_inopen;
                        saved_trace_inwater = trace_inwater;
                        traceline (e.origin,self.enemy.origin,TRUE,e);
                        help_trace_fraction = trace_fraction;
                        trace_allsolid = saved_trace_allsolid;
                        trace_startsolid = saved_trace_startsolid;
                        trace_fraction = saved_trace_fraction;
                        trace_endpos = saved_trace_endpos;
                        trace_plane_normal = saved_trace_plane_normal;
                        trace_plane_dist = saved_trace_plane_dist;
                        trace_ent = saved_trace_ent;
                        trace_inopen = saved_trace_inopen;
                        trace_inwater = saved_trace_inwater;
                        if (((help_trace_fraction == TRUE) || (p.enemycache == self.enemy)))
                        {
                           if (VERBOSEBOT)
                           {
                              dprint (e.teamname);
                           dprint (e.netname);
                           dprint (" coming to help!\n");
                        } //end if
                        e.enemy = self.enemy;
                        saved_enemy_vis = enemy_vis;
                        tmp = self;
                        self = e;
                        BotFoundTarget ();
                        if ((self.goalentity.classname != "BotTarget"))
                        {
                           objerror ("bad bot target in bot_ai! 1\n");
                        } //end if
                        setorigin (self.goalentity,p.origin);
                        self = tmp;
                        enemy_vis = saved_enemy_vis;
                     } //end if
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
      e = find (e,classname,"dmbot");
   } //end while
   HELPING = FALSE;
}; //end of the function CallForHelp
float () RunAway =
{
   local float runawayspeakchance;
   local float weap;

   runawayspeakchance = random ();
   if ((self.items & IT_INVULNERABILITY))
   {
      return (FALSE);
   } //end if
   if ((self.enemy.items & IT_INVULNERABILITY))
   {
      return (TRUE);
   } //end if
   if ((self.enemy.health < 55.000))
   {
      return (FALSE);
   } //end if
   weap = W_BestHeldWeapon ();
   if ((weap & (IT_ROCKET_LAUNCHER + IT_LIGHTNING)))
   {
      return (FALSE);
   } //end if
   if ((self.items & IT_QUAD))
   {
      if (((self.health + (self.armorvalue * self.armortype)) > 50.000))
      {
         return (FALSE);
      } //end if
   } //end if
   if ((self.health < 15.000))
   {
      return (TRUE);
   } //end if
   if ((weap & ((IT_SHOTGUN + IT_AXE) + IT_NAILGUN)))
   {
      if ((self.enemy.items & IT_QUAD))
      {
         return (FALSE);
      } //end if
      if ((self.enemy.weapon & ((IT_ROCKET_LAUNCHER + IT_LIGHTNING) + IT_SUPER_NAILGUN)))
      {
         return (FALSE);
      } //end if
   } //end if
   if ((self.lefty & MULTIENEMY))
   {
      if ((self.health < TE_LAVASPLASH))
      {
         return (TRUE);
      } //end if
   } //end if
   return (FALSE);
}; //end of the function RunAway

float () Bot_ValidateEnemy =
{
   if ((!self.enemy) || (self.enemy == world))
   {
      return (FALSE);
   } //end if
   if (((self.enemy.classname != "player") && (self.enemy.classname != "dmbot")))
   {
      endEnemy ();
      return (FALSE);
   } //end if
   if (((self.enemy.health <= 0.000) || (self.enemy.deadflag != DEAD_NO)))
   {
      endEnemy ();
      return (FALSE);
   } //end if
   return (TRUE);
}; //end of the function Bot_ValidateEnemy

void () BotHuntTarget =
{
   local vector predicted_pos;
   local float proj_speed;

   self.enemyrun = FALSE;
   self.strafetime = FALSE;
   if ((self.lefty & ONTRAIN))
   {
      self.lefty = (self.lefty - (self.lefty & ONTRAIN));
   } //end if
   Stack_Push();  // Save current goal before redirecting to enemy (Phase 8: Target Stack)
   self.goalentity.goalentity = self.enemy;
   if ((self.enemy.enemy == world))
   {
      self.enemy.enemy = self;
   } //end if
   if ((self.goalentity.classname != "BotTarget"))
   {
      objerror ("bad bot target in bot_ai! 2\n");
   } //end if
   setorigin (self.goalentity,self.enemy.origin);
   self.think = self.th_run;
   self.strafeonly = FALSE;

   // ===== PROJECTILE PREDICTION: Weapon-based Leading =====
   // Determine projectile speed based on current weapon
   if ((self.weapon & IT_ROCKET_LAUNCHER))
   {
      proj_speed = 1000.0;  // Rockets: 1000 u/s
   }
   else if ((self.weapon & IT_GRENADE_LAUNCHER))
   {
      proj_speed = 600.0;   // Grenades: 600 u/s (arc ballistic)
   }
   else if ((self.weapon & IT_SUPER_NAILGUN) || (self.weapon & IT_NAILGUN))
   {
      proj_speed = 1000.0;  // Nails: 1000 u/s (fast projectiles)
   }
   else
   {
      proj_speed = 0.0;     // Hitscan weapons (shotgun, LG): instant
   }

   // Get predicted enemy position
   predicted_pos = PredictEnemyPositionForNav(self.enemy, proj_speed);

   // Aim body toward predicted position (not current position!)
   self.ideal_yaw = vectoyaw ((predicted_pos - self.origin));
   // ===== END PROJECTILE PREDICTION =====

   self.lefty = ((self.lefty - (self.lefty & LOCAL_TIME)) + MOVETYPE_TOSS);
   self.nextthink = (time + 0.100);
   self.attack_finished = ((time + 0.700) - (0.200 * self.skil));
   self.combat_search_time = (time + MOVETYPE_PUSH);
   clearCache (self);
   if (teamplay)
   {
      if (!HELPING)
      {
         CallForHelp ();
      } //end if
   } //end if
}; //end of the function BotHuntTarget
float () BotFoundTarget =
{
   local float huntspeakchance;

   huntspeakchance = random ();
   if ((self.enemy == world))
   {
      return (FALSE);
   } //end if
   if (teamplay)
   {
      if ((self.enemy.team == self.team))
      {
         self.enemy = world;
         return (FALSE);
      } //end if
   } //end if
   if ((self.deadflag != DEAD_NO))
   {
      self.enemy = world;
      return (FALSE);
   } //end if
   if ((self.enemy.deadflag != DEAD_NO))
   {
      self.enemy = world;
      return (FALSE);
   } //end if
   if (((self.enemy.classname != "player") && (self.enemy.classname != "dmbot")))
   {
      self.enemy = world;
      return (FALSE);
   } //end if
   if ((self.enemy == self))
   {
      self.enemy = world;
      return (FALSE);
   } //end if
   BotHuntTarget ();

   // ===== HUMAN REACTION TIME: Simulated Input Lag =====
   // Add delay before bot can aim/fire at newly acquired enemy.
   // Easy bots (skill 0) get 0.4s delay, Nightmare bots (skill 3) get ~0.1s delay.
   // Prevents instant snap-to-target "aimbot" behavior that feels inhuman.
   self.reaction_finished = (time + (0.100 + (random () * 0.200 * (4.000 - self.skil))));
   // ===== END HUMAN REACTION TIME =====

   // Reset streaks on a fresh target so each engagement starts neutral.
   self.kill_streak = CAM_IDLE;
   self.death_streak = CAM_IDLE;
   self.taunt_streak = CAM_IDLE;
   return (TRUE);
}; //end of the function BotFoundTarget

void (entity en2) secondEnemy =
{
   if ((self.enemy.classname != "player"))
   {
      if ((en2.classname == "player"))
      {
         endEnemy ();
         self.enemy = en2;
         BotFoundTarget ();
         return ;
      } //end if
   } //end if
   if (!enemyvisible (self.enemy))
   {
      endEnemy ();
      self.enemy = en2;
      BotFoundTarget ();
   } //end if
   if ((en2.weapon & (IT_LIGHTNING + IT_ROCKET_LAUNCHER)))
   {
      if (!(self.enemy.weapon & (IT_LIGHTNING + IT_ROCKET_LAUNCHER)))
      {
         endEnemy ();
         self.enemy = en2;
         BotFoundTarget ();
      } //end if
   } //end if
}; //end of the function secondEnemy
float () BotfindBot =
{
   local float n;
   local entity bots;

   if (!self.lastbot)
   {
      self.lastbot = find (world,classname,"dmbot");
   } //end if
   n = MOVETYPE_STEP;
   while ((n > FALSE))
   {
      n = (n - TRUE);
      bots = self.lastbot;
      if ((!teamplay || (self.team != bots.team)))
      {
         if ((bots != self))
         {
            if ((bots != self.enemy))
            {
               if (visible (bots))
               {
                  if ((bots.health > FALSE))
                  {
                     self.enemy = bots;
                     return (BotFoundTarget ());
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
      self.lastbot = find (bots,classname,"dmbot");
      if (!self.lastbot)
      {
         self.lastbot = find (world,classname,"dmbot");
      } //end if
   } //end while
   return (FALSE);
}; //end of the function BotfindBot

// ============================================================
// FFA AWARENESS: "Best Target" Scanner (The FFA Fix)
// ============================================================
// Scans ALL visible enemies and picks the one that makes the most sense to kill.
// PRIORITIES:
// 1. Someone shooting me (Threat - self-defense)
// 2. Someone dying (Vulture - easy kill)
// 3. Someone close (Convenience - target of opportunity)
// This replaces the "first visible enemy" logic with intelligent multi-target scoring.
// ============================================================
entity() FindBestEnemy =
{
    local entity head;
    local entity best_enemy;
    local float score;
    local float best_score;
    local float dist;

    best_enemy = world;
    best_score = -1.000; // Minimum threshold

    // SCAN PLAYERS
    head = find (world,classname,"player");
    while (head)
    {
        if ((head != self) && (head.health > 0.000) && !(head.flags & FL_NOTARGET))
        {
            if (enemyvisible (head))
            {
                // Base Score: 1000 max, drops with distance
                dist = vlen (head.origin - self.origin);
                score = (1000.000 - dist);

                // MODIFIER 1: The "Vulture" (Low Health Priority)
                // FUZZY LOGIC: Smooth curve replaces hard threshold at 40 HP.
                // Old: if HP < 40 then +500 (cliff edge)
                // New: Quadratic curve from 0 (full HP) to 500 (0 HP)
                // HP=100: 0 bonus, HP=50: ~125 bonus, HP=25: ~280 bonus, HP=0: 500 bonus
                local float vulture_bonus;
                vulture_bonus = (500.000 * inverse_smooth_curve (head.health, 0.000, 100.000, 2.000));
                score = (score + vulture_bonus);

                // MODIFIER 2: The "Self-Defense" (Attacker Priority)
                // If this guy is currently shooting me, he is #1 priority.
                if ((head.enemy == self))
                {
                    score = (score + 800.000);
                } //end if

                // MODIFIER 3: Angle check (Don't snap 180 degrees unless necessary)
                if (!infrontofbot (head))
                {
                    score = (score * 0.500);
                } //end if

                // Pick the winner
                if ((score > best_score))
                {
                    best_score = score;
                    best_enemy = head;
                } //end if
            } //end if
        } //end if
        head = find (head,classname,"player");
    } //end while

    // SCAN BOTS (Don't forget to check other bots!)
    head = find (world,classname,"dmbot");
    while (head)
    {
        if ((head != self) && (head.health > 0.000))
        {
            if (enemyvisible (head))
            {
                // Same scoring logic...
                dist = vlen (head.origin - self.origin);
                score = (1000.000 - dist);

                // FUZZY LOGIC: Smooth vulture bonus (same as player scan)
                vulture_bonus = (500.000 * inverse_smooth_curve (head.health, 0.000, 100.000, 2.000));
                score = (score + vulture_bonus);

                if ((head.enemy == self))
                {
                    score = (score + 800.000);
                } //end if

                if (!infrontofbot (head))
                {
                    score = (score * 0.500);
                } //end if

                if ((score > best_score))
                {
                    best_score = score;
                    best_enemy = head;
                } //end if
            } //end if
        } //end if
        head = find (head,classname,"dmbot");
    } //end while

    // ===== DEBUG LOGGING: Target Selection (Change-Only) =====
    // Only log when target CHANGES (reduces spam from 90% to ~5% of lines)
    if (bot_debug_enabled && (best_enemy != self.last_logged_enemy))
    {
        bprint ("[");
        bprint (self.netname);
        bprint ("] TARGET: ");

        if (best_enemy != world)
        {
            bprint (best_enemy.netname);
            bprint (" (score=");
            bprint (ftos(best_score));
            bprint (", HP=");
            bprint (ftos(best_enemy.health));
            bprint (", dist=");
            bprint (ftos(vlen(best_enemy.origin - self.origin)));
            bprint ("u)\n");
        }
        else
        {
            bprint ("None visible\n");
        }

        // Remember what we logged
        self.last_logged_enemy = best_enemy;
    } //end if

    return best_enemy;
}; //end of the function FindBestEnemy
// ============================================================

float /* ERROR: Could not determine return type */ () BotFindTarget =
{
   local entity client;
   local float len;

   // ===== FFA FIX: Use "Best Target" Scanner =====
   // Instead of picking the first visible enemy (checkclient),
   // scan ALL visible enemies and pick the best one based on:
   // - Distance (closer = better)
   // - Health (lower = easier kill)
   // - Threat (attacking me = highest priority)
   client = FindBestEnemy ();

   if (client)
   {
      // Found a "Best" enemy!

      // Check for teamplay (don't attack teammates)
      if (teamplay)
      {
         if ((self.team == client.team))
         {
            return (BotfindBot ());
         } //end if
      } //end if

      // Check for invisibility
      if ((client.items & IT_INVISIBILITY))
      {
         return (BotfindBot ());
      } //end if

      // Skill-based randomness: Low-skill bots sometimes miss targets
      if ((self.skil < TRUE))
      {
         len = (random () * MUST_HAVE);
         // Streak-biased search: hot streak tightens threshold, cold streak loosens it.
         if ((self.kill_streak > 2.000))
         {
            len = (len * 0.500);
         } //end if
         else
         {
            if ((self.death_streak > 2.000))
            {
               len = (len * 2.000);
            } //end if
         } //end else
         if ((len > 25.000))
         {
            return (FALSE);
         } //end if
      } //end if

      // If we found a "Best" enemy, and it's different from our current one...
      if ((client != self.enemy))
      {
         // SWITCH!
         self.enemy = client;
         return (BotFoundTarget ());
      } //end if

      // If it's the same enemy, just keep fighting (return TRUE to say "we have a target")
      return (TRUE);
   } //end if

   // No good target found, try finding a bot target
   return (BotfindBot ());
}; //end of the function BotFindTarget

// ===== SIMULATED PERCEPTION: The Hearing Module =====
// Detects nearby enemies that are invisible but "audible" through noise-making actions.
// In real Quake, players hear weapon fire, footsteps, jumps, and powerup hums.
// Bots use this to pre-aim at doorways where enemies approach, mimicking human awareness.
void () BotListen =
{
   local entity head;
   local float dist;
   local float heard;
   local float audible_range;
   local float spam_range;
   local float spam_min_range;

   // Only listen when idle (don't interfere with active combat)
   if ((self.enemy != world))
   {
      return ;
   } //end if
   audible_range = 800.000;
   spam_range = 800.000;
   spam_min_range = 160.000;

   // Scan for players first
   head = find (world,classname,"player");
   while (head)
   {
      if ((head != self) && (head.health > FALSE))
      {
         if (!visible (head))
         {
            // Only react to invisible enemies (hearing through walls)
            dist = vlen ((head.origin - self.origin));

            // Sound travel limit (Quake sounds drop off around 500-800u)
            if ((dist < audible_range))
            {
               heard = FALSE;

               // NOISE SOURCE 1: Weapon fire (LOUD - unmistakable)
               if ((head.weaponframe > FALSE))
               {
                  heard = TRUE;
               } //end if

               // NOISE SOURCE 2: Jumping/Landing (medium volume)
               if (!(head.flags & FL_ONGROUND))
               {
                  heard = TRUE;
               } //end if

               // NOISE SOURCE 3: Fast movement (running footsteps)
               if ((vlen (head.velocity) > 200.000))
               {
                  heard = TRUE;
               } //end if

               // NOISE SOURCE 4: Powerups (Quad/Pent hum is VERY loud!)
               if ((head.items & (IT_QUAD | IT_INVULNERABILITY)))
               {
                  if ((dist < 800.000))
                  {
                     heard = TRUE;
                  } //end if
               } //end if

               if (heard)
               {
                  // SMART REACTION: Don't target (can't shoot walls).
                  // Instead, FACE the sound source so we're ready when they appear.
                  self.ideal_yaw = vectoyaw ((head.origin - self.origin));
                  ChangeYaw ();

                  // Suppressive fire: spam splash weapons at heard locations (corner denial).
                  if (((dist < spam_range) && (dist > spam_min_range)) && (self.ammo_rockets > FALSE))
                  {
                     if (((self.weapon == IT_ROCKET_LAUNCHER) || (self.weapon == IT_GRENADE_LAUNCHER)))
                     {
                        if ((time > self.attack_finished))
                        {
                           self.button0 = TRUE;
                           self.attack_finished = (time + 0.600);
                        } //end if
                     } //end if
                  } //end if

                  return ;
               } //end if
            } //end if
         } //end if
      } //end if
      head = find (head,classname,"player");
   } //end while

   // Scan for bots (same logic as players)
   head = find (world,classname,"dmbot");
   while (head)
   {
      if ((head != self) && (head.health > FALSE))
      {
         if (!visible (head))
         {
            dist = vlen ((head.origin - self.origin));

            if ((dist < audible_range))
            {
               heard = FALSE;

               // Same noise detection as players
               if ((head.weaponframe > FALSE))
               {
                  heard = TRUE;
               } //end if
               if (!(head.flags & FL_ONGROUND))
               {
                  heard = TRUE;
               } //end if
               if ((vlen (head.velocity) > 200.000))
               {
                  heard = TRUE;
               } //end if
               if ((head.items & (IT_QUAD | IT_INVULNERABILITY)))
               {
                  if ((dist < 800.000))
                  {
                     heard = TRUE;
                  } //end if
               } //end if

               if (heard)
               {
                  self.ideal_yaw = vectoyaw ((head.origin - self.origin));
                  ChangeYaw ();

                  if (((dist < spam_range) && (dist > spam_min_range)) && (self.ammo_rockets > FALSE))
                  {
                     if (((self.weapon == IT_ROCKET_LAUNCHER) || (self.weapon == IT_GRENADE_LAUNCHER)))
                     {
                        if ((time > self.attack_finished))
                        {
                           self.button0 = TRUE;
                           self.attack_finished = (time + 0.600);
                        } //end if
                     } //end if
                  } //end if

                  return ;
               } //end if
            } //end if
         } //end if
      } //end if
      head = find (head,classname,"dmbot");
   } //end while
}; //end of the function BotListen

void () ai_botstand =
{
   BotListen ();
   if (BotFindTarget ())
   {
      return ;
   } //end if
}; //end of the function ai_botstand

void () ai_botturn =
{
   BotListen ();
   if (BotFindTarget ())
   {
      return ;
   } //end if
   ChangeYaw ();
}; //end of the function ai_botturn

void () aibot_run_melee =
{
   self.ideal_yaw = vectoyaw ((self.enemy.origin - self.origin));
   ChangeYaw ();
   if (FacingIdeal ())
   {
      self.attack_state = AS_STRAIGHT;
      self.th_melee ();
   } //end if
}; //end of the function aibot_run_melee

void (float dist, float turn) aibot_run_slide =
{
   local float ofs;
   local float rdir;
   local float rng;
   local float rnd;
   local float dis;
   local float trn;
   local float weap;
   local vector predicted_pos;
   local float proj_speed;
   local vector diff;
   local vector aim;
   local vector ang;
   local float dz;
   local float dh;
   local float pitch;
   local float need_repos;
   local float base_yaw;
   local float enemy_vis_local;
   local float vert_disadvantage;
   local float vert_recent_vis;

   trn = turn;

   // ===== PROJECTILE PREDICTION: Strafe Aiming =====
   // Determine projectile speed based on current weapon
   if ((self.weapon & IT_ROCKET_LAUNCHER))
   {
      proj_speed = 1000.0;  // Rockets: 1000 u/s
   }
   else if ((self.weapon & IT_GRENADE_LAUNCHER))
   {
      proj_speed = 600.0;   // Grenades: 600 u/s (arc ballistic)
   }
   else if ((self.weapon & IT_SUPER_NAILGUN) || (self.weapon & IT_NAILGUN))
   {
      proj_speed = 1000.0;  // Nails: 1000 u/s (fast projectiles)
   }
   else
   {
      proj_speed = 0.0;     // Hitscan weapons (shotgun, LG): instant
   }

   predicted_pos = PredictEnemyPositionForNav(self.enemy, proj_speed);
   self.ideal_yaw = vectoyaw ((predicted_pos - self.origin));
   // ===== END PROJECTILE PREDICTION =====

   // ===== COMBAT REPOSITION: Avoid chasing directly under/over targets =====
   enemy_vis_local = enemyvisible (self.enemy);
   if (enemy_vis_local)
   {
      self.combat_no_los_time = 0.000;
      self.combat_last_enemy_seen = time;
   } //end if
   else
   {
      if (!self.combat_no_los_time)
      {
         self.combat_no_los_time = time;
      } //end if
   } //end else

   diff = (self.enemy.origin - self.origin);
   dz = diff_z;
   diff_z = 0.000;
   dh = vlen (diff);

   aim = ((self.enemy.origin + self.enemy.view_ofs) - (self.origin + self.view_ofs));
   ang = vectoangles (aim);
   pitch = fabs (ang_x);

   if ((self.waterlevel > 1.000))
   {
      if ((dz > 64.000))
      {
         self.button2 = 1.000;
      } //end if
   } //end if

   vert_recent_vis = enemy_vis_local;
   if ((!vert_recent_vis && self.combat_last_enemy_seen))
   {
      if (((time - self.combat_last_enemy_seen) < 1.000))
      {
         vert_recent_vis = TRUE;
      } //end if
   } //end if

   vert_disadvantage = FALSE;
   if (((dz > 128.000) && vert_recent_vis))
   {
      vert_disadvantage = TRUE;
   } //end if
   if (((dz > 96.000) && (pitch > 35.000)))
   {
      vert_disadvantage = TRUE;
   } //end if
   if (((dz > 96.000) && !enemy_vis_local))
   {
      if ((self.combat_no_los_time && ((time - self.combat_no_los_time) > 0.700)))
      {
         vert_disadvantage = TRUE;
      } //end if
   } //end if

   if (vert_disadvantage)
   {
      self.combat_vert_disadvantage = TRUE;
      if (!self.combat_vert_start_time)
      {
         self.combat_vert_start_time = time;
         self.combat_elevate_until = (time + (1.200 + (random () * 0.400)));
         self.combat_elevate_start_z = self.origin_z;
         if ((bot_debug_enabled && (bot_debug_level >= LOG_TACTICAL)))
         {
            bprint ("[");
            bprint (self.netname);
            bprint ("] ELEVATE: Enter\n");
         } //end if
      } //end if
      if ((self.combat_elevate_until && (self.origin_z >= (self.combat_elevate_start_z + 64.000))))
      {
         self.combat_elevate_until = 0.000;
         if ((bot_debug_enabled && (bot_debug_level >= LOG_TACTICAL)))
         {
            bprint ("[");
            bprint (self.netname);
            bprint ("] ELEVATE: Reached band\n");
         } //end if
      } //end if
   } //end if
   else
   {
      if (self.combat_vert_disadvantage)
      {
         self.combat_vert_disadvantage = FALSE;
         self.combat_vert_start_time = 0.000;
         self.combat_elevate_until = 0.000;
         self.combat_elevate_start_z = 0.000;
      } //end if
   } //end else

   if ((self.combat_break_until && (time > self.combat_break_until)))
   {
      self.combat_break_until = 0.000;
      if ((bot_debug_enabled && (bot_debug_level >= LOG_TACTICAL)))
      {
         bprint ("[");
         bprint (self.netname);
         bprint ("] BREAK: Exit\n");
      } //end if
   } //end if

   if ((self.combat_break_until && !vert_disadvantage && enemy_vis_local && (pitch < 25.000)))
   {
      self.combat_break_until = 0.000;
      if ((bot_debug_enabled && (bot_debug_level >= LOG_TACTICAL)))
      {
         bprint ("[");
         bprint (self.netname);
         bprint ("] BREAK: Exit (clear)\n");
      } //end if
   } //end if

   if ((vert_disadvantage && (time > self.combat_break_cooldown_time)))
   {
      if ((self.combat_vert_start_time && ((time - self.combat_vert_start_time) > 1.200)))
      {
         if (((pitch > 35.000) || (!enemy_vis_local) || (dz > 96.000)))
         {
            self.combat_break_until = (time + (1.000 + (random () * 1.000)));
            self.combat_break_cooldown_time = (time + 0.600);
            self.combat_break_side = -1.000;
            if ((random () < 0.500))
            {
               self.combat_break_side = 1.000;
            } //end if
            if ((bot_debug_enabled && (bot_debug_level >= LOG_TACTICAL)))
            {
               bprint ("[");
               bprint (self.netname);
               bprint ("] BREAK: Enter\n");
            } //end if
         } //end if
      } //end if
   } //end if

   if ((self.combat_break_until && (time <= self.combat_break_until)))
   {
      base_yaw = vectoyaw ((self.enemy.origin - self.origin));
      Bot_Feelers_Evaluate (self,BOT_MODE_COMBAT,self.combat_break_side,base_yaw);
      Bot_ApplyFeelerMove (dist,BOT_MODE_COMBAT);
      return ;
   } //end if

   if ((self.combat_vert_disadvantage && (time <= self.combat_elevate_until)))
   {
      base_yaw = vectoyaw ((self.enemy.origin - self.origin));
      Bot_Feelers_Evaluate (self,BOT_MODE_COMBAT,0.000,base_yaw);
      Bot_ApplyFeelerMove (dist,BOT_MODE_COMBAT);
      return ;
   } //end if

   if ((self.teleport_time > time))
   {
      if ((time > self.combat_repos_cooldown_time))
      {
         self.combat_repos_until = (time + 0.600);
         self.combat_repos_side = -1.000;
         if ((random () < 0.500))
         {
            self.combat_repos_side = 1.000;
         } //end if
         base_yaw = vectoyaw ((self.enemy.origin - self.origin));
         Bot_Feelers_Evaluate (self,BOT_MODE_COMBAT,self.combat_repos_side,base_yaw);
         Bot_ApplyFeelerMove (dist,BOT_MODE_COMBAT);
         return ;
      } //end if
   } //end if

   need_repos = FALSE;
   if ((!vert_disadvantage && (dz > 96.000) && (dh < 128.000)))
   {
      need_repos = TRUE;
   } //end if
   if ((!vert_disadvantage && (fabs (dz) > 96.000) && (pitch > 30.000)))
   {
      need_repos = TRUE;
   } //end if
   if ((!vert_disadvantage && (fabs (dz) > 96.000) && !enemy_vis_local))
   {
      if ((self.combat_no_los_time && ((time - self.combat_no_los_time) > 0.400)))
      {
         need_repos = TRUE;
      } //end if
   } //end if

   if ((self.combat_repos_until && (time > self.combat_repos_until)))
   {
      self.combat_repos_until = 0.000;
      self.combat_repos_cooldown_time = (time + 0.400);
      if ((bot_debug_enabled && (bot_debug_level >= LOG_TACTICAL)))
      {
         bprint ("[");
         bprint (self.netname);
         bprint ("] REPOS: Exit\n");
      } //end if
   } //end if

   if ((need_repos && (time > self.combat_repos_until) && (time > self.combat_repos_cooldown_time)))
   {
      self.combat_repos_until = (time + (0.600 + (random () * 0.600)));
      self.combat_repos_side = -1.000;
      if ((random () < 0.500))
      {
         self.combat_repos_side = 1.000;
      } //end if

      base_yaw = vectoyaw ((self.enemy.origin - self.origin));
      Bot_Feelers_Evaluate (self,BOT_MODE_COMBAT,self.combat_repos_side,base_yaw);

      if ((bot_debug_enabled && (bot_debug_level >= LOG_TACTICAL)))
      {
         bprint ("[");
         bprint (self.netname);
         bprint ("] REPOS: Enter (score=");
         bprint (ftos (self.best_score));
         bprint (", pitch=");
         bprint (ftos (pitch));
         bprint (", dz=");
         bprint (ftos (dz));
         bprint (", dh=");
         bprint (ftos (dh));
         bprint (")\n");
      } //end if
   } //end if

   if ((self.combat_repos_until && (time <= self.combat_repos_until)))
   {
      Bot_ApplyFeelerMove (dist,BOT_MODE_COMBAT);
      return ;
   } //end if
   // ===== END COMBAT REPOSITION =====

   ChangeYaw ();
   ofs = 90.000;
   dis = dist;
   self.strafeonly = (self.strafeonly - TRUE);
   if ((self.strafeonly > FALSE))
   {
      trn = NOTURN;
   } //end if
   rdir = (random () * MOVETYPE_WALK);
   rng = botrange (self.enemy);
   if ((rng == RANGE_NEAR))
   {
      rdir = (rdir + 0.800);

   } //end if
   else
   {
      if ((rng == RANGE_MELEE))
      {
         rdir = (rdir + 1.200);
         rnd = random ();
         weap = W_BestHeldWeapon ();
         if ((weap == IT_ROCKET_LAUNCHER))
         {
            rnd = FALSE;

         } //end if
         else
         {
            if ((weap == IT_GRENADE_LAUNCHER))
            {
               rnd = FALSE;

            } //end if
            else
            {
               if ((self.enemyrun > MOVETYPE_STEP))
               {
                  rnd = TRUE;

               } //end if
               else
               {
                  if ((weap == IT_AXE))
                  {
                     rnd = TRUE;

                  } //end if
                  else
                  {
                     if ((self.enemy.weapon == IT_ROCKET_LAUNCHER))
                     {
                        rnd = TRUE;
                     } //end if
                  } //end if
               } //end if
            } //end if
         } //end if
         if ((rnd < 0.300))
         {
            if (botwalkmove ((self.ideal_yaw + 180.000),dis))
            {
               return ;
            } //end if
         } //end if

      } //end if
      else
      {
         if ((rng == RANGE_MID))
         {
            weap = W_BestHeldWeapon ();
            if ((weap == IT_LIGHTNING))
            {
               rdir = (rdir - MOVETYPE_WALK);

            } //end if
            else
            {
               rdir = (rdir - TRUE);
            } //end if

         } //end if
         else
         {
            if ((rng == RANGE_FAR))
            {
               rdir = (rdir - 2.500);
            } //end if
         } //end if
      } //end if
   } //end if
   if ((self.weapon == IT_AXE))
   {
      rdir = FALSE;

   } //end if
   else
   {
      if ((self.weapon == IT_ROCKET_LAUNCHER))
      {
         rdir = (rdir + 1.500);

      } //end if
      else
      {
         if ((self.weapon == IT_GRENADE_LAUNCHER))
         {
            rdir = (rdir + 1.500);
         } //end if
      } //end if
   } //end if
   if ((self.enemy.weapon == IT_ROCKET_LAUNCHER))
   {
      rdir = (rdir + 1.500);

   } //end if
   else
   {
      if ((self.enemy.weapon == IT_LIGHTNING))
      {
         rdir = (rdir + 1.500);
      } //end if
   } //end if
   if ((self.enemyrun > FL_CLIENT))
   {
      rdir = (rdir - FL_SWIM);

   } //end if
   else
   {
      if ((self.origin_z > (self.enemy.origin_z + 130.000)))
      {
         rdir = ((rdir + 1.100) + random ());
         if ((rdir >= 1.500))
         {
            trn = NOTURN;
         } //end if
         if ((self.weapon == IT_AXE))
         {
            trn = turn;
            rdir = FALSE;
         } //end if
      } //end if
   } //end if
   if ((rdir < 1.500))
   {
      if ((trn == CANTURN))
      {
         Botmovetogoal (dis);
         return ;
      } //end if
      if (botwalkmove (self.ideal_yaw,dis))
      {
         return ;
      } //end if
      ofs = 90.000;

   } //end if
   else
   {
      if ((rdir < 2.400))
      {
         ofs = 45.000;
      } //end if
   } //end if
   if ((self.skil == FALSE))
   {
      return ;
   } //end if
   self.strafetime = (self.strafetime + 0.100);
   if ((self.skil < SPAWNFLAG_LASER))
   {
      if ((self.skil < SPAWNFLAG_SUPERSPIKE))
      {
         dis = (0.700 * dis);
      } //end if
      if ((self.strafetime == 0.100))
      {
         rnd = (random () * MOVETYPE_STEP);
         if ((self.skil >= SPAWNFLAG_SUPERSPIKE))
         {
            rnd = ((rnd - self.skil) + 0.500);
         } //end if
         if ((rnd > self.skil))
         {
            self.strafetime = FALSE;
            return ;
         } //end if
      } //end if
   } //end if

   // ===== PHASE 7: Active Projectile Dodging =====
   // Check for incoming projectiles and dodge if threat detected
   // Takes priority over circle strafing for survival
   if (bot_dodge_stuff ())
   {
      // Projectile dodge in progress - skip circle strafing this frame
      // The dodge system has already set self.lefty STRAFE_DIR for evasion
      return ;
   } //end if
   // ===== END PHASE 7: Dodge Check =====

   // ===== CUNNING AI: Circle Strafing (Orbit Mode) =====
   // OLD: Flipped direction every 0.4s (erratic zigzag)
   // NEW: Commit to direction for 1.5s to create smooth circular orbit around enemy
   if ((self.strafetime > 1.500))
   {
      // Only flip direction if we hit a wall or randomly after a long time
      rnd = (random () * SPAWNFLAG_LASER);
      if ((rnd > 1.870))
      {
         if ((self.lefty & STRAFE_DIR))
         {
            self.lefty = (self.lefty - (self.lefty & STRAFE_DIR));

         } //end if
         else
         {
            self.lefty = (self.lefty + STRAFE_DIR);
         } //end if
         self.strafetime = FALSE;
         return ;
      } //end if
   } //end if

   // Force the strafe angle to be tangential (Circle)
   // 90 degrees = perfect circle.
   // 80 degrees = slight spiral IN towards enemy (aggressive)
   ofs = 80.000;
   // ===== END CUNNING AI: Circle Strafing =====

   if ((self.lefty & STRAFE_DIR))
   {
      ofs = (CONTENT_EMPTY * ofs);
   } //end if
   if (botwalkmove ((self.ideal_yaw + ofs),dis))
   {
      return ;
   } //end if

   // ===== VERTICAL PURSUIT FIX: Ledge Jumping =====
   // If strafing failed (blocked by wall or ledge) and enemy is BELOW us,
   // try jumping to pursue. (Fixes getting stuck on dm4 top ledges)
   if ((self.enemy.origin_z < (self.origin_z - 32.000)))
   {
      // Only jump if facing roughly towards the enemy
      if (infrontofbot (self.enemy))
      {
         // Attempt a forward jump (300 u/s) to clear the ledge
         if (Bot_tryjump (300.000,dis,FALSE))
         {
            return ;
         } //end if
      } //end if
   } //end if
   // ===============================================

   self.strafetime = FALSE;
   if ((self.lefty & STRAFE_DIR))
   {
      self.lefty = (self.lefty - (self.lefty & STRAFE_DIR));

   } //end if
   else
   {
      self.lefty = (self.lefty + STRAFE_DIR);
   } //end if
   if (((ofs == 90.000) || (ofs == -90.000)))
   {
      rnd = random ();
      if ((rnd < 0.050))
      {
         if ((trn == CANTURN))
         {
            Botmovetogoal (dis);
            return ;
         } //end if
      } //end if
      if ((rnd < 0.500))
      {
         walkmove ((self.ideal_yaw + 180.000),(dis * 0.500));
      } //end if
      return ;
   } //end if
   botwalkmove (self.ideal_yaw,dis);
}; //end of the function aibot_run_slide

void (float dist) ai_botgetGoody;

void (float dist) ai_botcharge =
{
   local float rng;
   local float oldrng;

   if ((self.lefty & GETGOODY))
   {
      ai_botgetGoody (dist);
      return ;
   } //end if
   if (enemyvisible (self.enemy))
   {
      rng = vlen ((self.enemy.origin - self.origin));
      oldrng = vlen ((self.goalentity.origin - self.origin));
      if ((self.goalentity.classname != "BotTarget"))
      {
         objerror ("bad bot target in bot_ai! 3\n");
      } //end if
      setorigin (self.goalentity,self.enemy.origin);
      if ((self.enemyrun > FALSE))
      {
         self.enemyrun = (self.enemyrun - TRUE);
      } //end if
      if ((rng > (oldrng + MOVETYPE_BOUNCE)))
      {
         self.enemyrun = (self.enemyrun + FL_SWIM);
      } //end if
   } //end if
   aibot_run_slide (dist,NOTURN);
}; //end of the function ai_botcharge

void (float dist) ai_botnailcharge =
{
   local float rnd;

   if (!enemyvisible (self.enemy))
   {
      self.think = self.th_run;
   } //end if
   if (!FacingIdeal ())
   {
      self.think = self.th_run;
   } //end if
   if ((self.enemy.deadflag != DEAD_NO))
   {
      endEnemy ();
      return ;
   } //end if
   ai_botcharge (dist);
}; //end of the function ai_botnailcharge
float (float minweight) aibot_checkforGoodies;

void (float dist) ai_botrun =
{
   local vector delta;
   local float axis;
   local float rng;
   local float oldrng;
   local float direct;
   local float ang_rint;
   local float ang_floor;
   local float ang_ceil;
   local float kd_ratio;
   local float los_class;

   if ((self.enemy.deadflag != DEAD_NO))
   {
      endEnemy ();
      return ;
   } //end if
   // Streak-based skill tuning: adjust up on hot streaks, down on slumps.
   if (bot_skill_adapt)
   {
      kd_ratio = (self.kill_streak - self.death_streak);
      if ((kd_ratio > 3.000))
      {
         self.skil = (self.skil + 0.500);
         if ((self.skil > 4.000))
         {
            self.skil = 4.000;
         } //end if
      } //end if
      else
      {
         if ((kd_ratio < -3.000))
         {
            self.skil = (self.skil - 0.500);
            if ((self.skil < 1.000))
            {
               self.skil = 1.000;
            } //end if
         } //end if
      } //end else
      if ((fabs (kd_ratio) > 3.000))
      {
         self.kill_streak = CAM_IDLE;
         self.death_streak = CAM_IDLE;
         self.taunt_streak = CAM_IDLE;
      } //end if
   } //end if
   if (!self.enemy)
   {
      endEnemy ();
      return ;
   } //end if
   if ((self.lefty & GETGOODY))
   {
      ai_botgetGoody (dist);
      return ;
   } //end if
   enemy_vis = enemyvisible (self.enemy);
   if ((enemy_vis || Spotvisible (self.enemy)))
   {
      rng = vlen ((self.enemy.origin - self.origin));
      oldrng = vlen ((self.goalentity.origin - self.origin));
      if ((self.enemyrun > FALSE))
      {
         self.enemyrun = (self.enemyrun - TRUE);
      } //end if
      if ((rng > (oldrng + MOVETYPE_BOUNCE)))
      {
         self.enemyrun = (self.enemyrun + FL_SWIM);
      } //end if
      if ((self.goalentity.classname != "BotTarget"))
      {
         objerror ("bad bot target in bot_ai! 4\n");
      } //end if
      setorigin (self.goalentity,self.enemy.origin);

      // ===== THE PROFILER: Opponent Aggression Tracking =====
      // Track enemy movement patterns to adapt tactics dynamically.
      // Aggressive players rush in → bot sets traps and retreats.
      // Passive players camp → bot pushes aggressively to flush them out.
      if ((self.last_enemy_dist > 0.000))
      {
         // Are they getting closer to us?
         if ((rng < self.last_enemy_dist))
         {
            // Enemy is APPROACHING (aggressive behavior)
            self.enemy.aggression_score = (self.enemy.aggression_score + 0.100);
         } //end if
         else
         {
            // Enemy is RETREATING or CAMPING (passive behavior)
            self.enemy.aggression_score = (self.enemy.aggression_score - 0.050);
         } //end else

         // Cap aggression score to 0-10 range
         if ((self.enemy.aggression_score > 10.000))
         {
            self.enemy.aggression_score = 10.000;
         } //end if
         if ((self.enemy.aggression_score < 0.000))
         {
            self.enemy.aggression_score = 0.000;
         } //end if
      } //end if

      // Store current distance for next frame comparison
      self.last_enemy_dist = rng;
      // ======================================================

      // Cache visible enemy velocity to extend chase prediction past line-of-sight breaks.
      self.last_enemy_vel = self.enemy.velocity;
      self.combat_search_time = (time + MOVETYPE_PUSH);

      // ===== FFA FIX: The "Swivel Turret" (Dynamic Target Switching) =====
      // In FFA, don't commit to a duel. If a new, better target appears
      // (like someone running up behind us or a weak enemy nearby), SWITCH.
      // This runs during combat (not just when idle) for multi-opponent awareness.
      if ((time > self.scan_time))
      {
         local entity better_target;
         local float switch_justified;
         local float curr_dist;
         local float new_dist;

         better_target = FindBestEnemy ();

         if ((better_target != world) && (better_target != self.enemy))
         {
            // ===== HYSTERESIS: Require clear advantage before switching =====
            // Prevents flip-flopping between similar targets (fixes high switching rate)
            switch_justified = FALSE;

            // REASON 1: New target is attacking us (self-defense - always switch)
            if ((better_target.enemy == self))
            {
               switch_justified = TRUE;
            } //end if

            // REASON 2: New target is MUCH closer (300+ units)
            curr_dist = vlen (self.enemy.origin - self.origin);
            new_dist = vlen (better_target.origin - self.origin);
            if ((new_dist < (curr_dist - 300.000)))
            {
               switch_justified = TRUE;
            } //end if

            // REASON 3: New target is MUCH weaker (30+ HP less)
            if ((better_target.health < (self.enemy.health - 30.000)))
            {
               switch_justified = TRUE;
            } //end if

            // Only switch if we have a clear reason
            if (switch_justified)
            {
               // Prevent rapid flip-flopping unless it's immediate self-defense.
               if ((better_target.enemy != self))
               {
                  if ((self.last_target_switch_time && ((time - self.last_target_switch_time) < 1.600)))
                  {
                     switch_justified = FALSE;
                  } //end if
               } //end if
            } //end if

            // Only switch if we have a clear reason
            if (switch_justified)
            {
               self.enemy = better_target;
               BotFoundTarget (); // Play shout sound, reset reaction time
               self.last_target_switch_time = time;
            } //end if
         } //end if

         self.scan_time = (time + 3.000); // Check every 3.0s to reduce churn
      } //end if
      // ===================================================
   } //end if
   if ((self.combat_search_time < time))
   {
      endEnemy ();
      BotFindTarget ();
      return ;
   } //end if
   if (((self.lefty & LOCAL_TIME) > MOVETYPE_FLY))
   {
      self.lefty = (self.lefty - (self.lefty & LOCAL_TIME));
      self.lastseenpos = self.goalentity.origin;
      if (aibot_checkforGoodies (DONT_WANT))
      {
         ai_botgetGoody (dist);
         return ;
      } //end if
   } //end if

   // ===== THE PROFILER: Tactical Adaptations =====
   // Adapt combat strategy based on opponent's profiled aggression level
   if ((self.enemy != world))
   {
      // AGAINST AGGRESSIVE ENEMIES (score > 7.0): Retreat & Set Traps
      // These are rushers who charge in - back up and punish their aggression
      if ((self.enemy.aggression_score > 7.000))
      {
         // Increase retreat tendency by boosting enemyrun
         // (Higher enemyrun makes RunAway() trigger more easily)
         self.enemyrun = (self.enemyrun + 2.000);

         // Drop grenades more frequently when retreating from rushers
         // (Parting Gift logic below will execute if we do retreat)

         // ===== PROFILING DEBUG LOGGING (LOG_TACTICAL+) =====
         if ((bot_debug_enabled && (bot_debug_level >= LOG_TACTICAL)))
         {
            bprint ("[");
            bprint (self.netname);
            bprint ("] PROFILE: ");
            bprint (self.enemy.netname);
            bprint (" is AGGRESSIVE (");
            bprint (ftos (self.enemy.aggression_score));
            bprint (") → Retreat & Trap\n");
         } //end if
         // ==================================================
      } //end if
      // AGAINST PASSIVE ENEMIES (score < 3.0): Flush Them Out
      // These are campers/cautious players - charge in aggressively
      else
      {
         if ((self.enemy.aggression_score < 3.000))
         {
            // Reduce retreat tendency - force aggressive push
            self.enemyrun = (self.enemyrun - 1.000);
            if ((self.enemyrun < 0.000))
            {
               self.enemyrun = 0.000;
            } //end if

            // ===== PROFILING DEBUG LOGGING (LOG_TACTICAL+) =====
            if ((bot_debug_enabled && (bot_debug_level >= LOG_TACTICAL)))
            {
               bprint ("[");
               bprint (self.netname);
               bprint ("] PROFILE: ");
               bprint (self.enemy.netname);
               bprint (" is PASSIVE (");
               bprint (ftos (self.enemy.aggression_score));
               bprint (") → Push Aggressively\n");
            } //end if
            // ==================================================
         } //end if
      } //end else
   } //end if
   // ==============================================

   self.lefty = (self.lefty + TRUE);
   if (RunAway ())
   {
      // ===== CUNNING AI: The "Parting Gift" (Retreat Trap) =====
      // When running away, drop a grenade behind to blow up pursuers
      if ((self.items & IT_GRENADE_LAUNCHER))
      {
         if ((self.ammo_rockets >= 1.000))
         {
            // Only do this occasionally (don't waste all ammo)
            if ((time > self.attack_finished))
            {
               if ((random () < 0.100))
               {
                  // Face the enemy (or behind us)
                  self.ideal_yaw = vectoyaw ((self.enemy.origin - self.origin));
                  ChangeYaw ();

                  // Look DOWN (grenade at feet)
                  self.angles_x = 80.000;
                  makevectors (self.angles);

                  // Fire grenade at our own feet (or slightly towards enemy)
                  W_FireGrenade ();

                  self.attack_finished = (time + 1.000);
               } //end if
            } //end if
         } //end if
      } //end if
      // ===== END CUNNING AI: Retreat Trap =====

      self.lefty = (self.lefty - (self.lefty & LOCAL_TIME));
      self.lastseenpos = self.goalentity.origin;
      if (aibot_checkforGoodies (DONT_WANT))
      {
         ai_botgetGoody (dist);
         return ;
      } //end if
   } //end if
   enemy_infront = infrontofbot (self.enemy);
   enemy_yaw = vectoyaw ((self.enemy.origin - self.origin));
   if (!enemy_vis)
   {
      aibot_setupchase ();
      Botmovetogoal (dist);
      return ;
   } //end if
   if ((self.attack_state == AS_MELEE))
   {
      aibot_run_melee ();
   } //end if
   if ((self.combat_break_until > time))
   {
      los_class = BOT_LOS_NONE;
      if (enemy_vis)
      {
         los_class = Bot_LOSClassFrom (self,self.origin,self.enemy);
      } //end if
      if ((enemy_vis && (los_class >= BOT_LOS_TORSO)))
      {
         CheckBotAttack ();
      } //end if
      else
      {
         if ((self.attack_finished < time))
         {
            self.attack_finished = (time + 0.200);
         } //end if
      } //end else
   } //end if
   else
   {
      CheckBotAttack ();
   } //end else
   aibot_run_slide (dist,CANTURN);
   return ;
}; //end of the function ai_botrun

void () aibot_setupchase =
{
   local entity pth;

   self.think = bot_chase;
   if (TrueReachable (self.goalentity))
   {
      return ;
   } //end if
   if (RunAway ())
   {
      self.lefty = (self.lefty - (self.lefty & LOCAL_TIME));
      aibot_checkforGoodies ((WANT - TRUE));
      self.lastseenpos = self.goalentity.origin;
      return ;
   } //end if
   pth = BestChaseRoute (self,self.enemy);
   if ((self.goalentity.classname != "BotTarget"))
   {
      objerror ("bad bot target in bot_ai! 1\n");
   } //end if
   if ((pth != self.enemy))
   {
      setorigin (self.goalentity,pth.origin);
   } //end if
   self.combat_search_time = (time + MOVETYPE_TOSS);
}; //end of the function aibot_setupchase

void (float dist) aibot_chase =
{
   local entity olden;
   local float weap;
   local float rnd;

   if ((self.enemy.deadflag != DEAD_NO))
   {
      endEnemy ();
      return ;
   } //end if
   if ((self.lefty & GETGOODY))
   {
      ai_botgetGoody (dist);
      return ;
   } //end if
   enemy_vis = enemyvisible (self.enemy);
   rnd = random ();
   if ((rnd < 0.900))
   {
      enemy_vis = enemy_vis;
   } //end if
   if (enemy_vis)
   {
      if ((self.goalentity.classname != "BotTarget"))
      {
         objerror ("bad bot target in bot_ai! 1\n");
      } //end if
      setorigin (self.goalentity,self.enemy.origin);
      self.combat_search_time = (time + MOVETYPE_FLY);
      self.think = self.th_run;
      Botmovetogoal (dist);
      return ;
   } //end if
   // If LOS breaks, push the chase target forward using last seen velocity.
   if ((!enemy_vis) && (self.skil > TRUE))
   {
      setorigin (self.goalentity,(self.goalentity.origin + (self.last_enemy_vel * 0.200)));
      self.combat_search_time = (self.combat_search_time + 0.100);
   } //end if
   if (RunAway ())
   {
      if ((self.combat_search_time < time))
      {
         endEnemy ();
         return ;
      } //end if
      self.lefty = (self.lefty - (self.lefty & LOCAL_TIME));
      if (aibot_checkforGoodies ((WANT - TRUE)))
      {
         ai_botgetGoody (dist);
         self.lastseenpos = self.goalentity.origin;
         return ;
      } //end if
   } //end if
   if ((self.enemy.items & IT_INVISIBILITY))
   {
      if ((self.skil < MOVETYPE_WALK))
      {
         endEnemy ();
         return ;
      } //end if
   } //end if
   if (((self.lefty & LOCAL_TIME) > MOVETYPE_FLY))
   {
      self.lastseenpos = self.goalentity.origin;
      self.lefty = (self.lefty - (self.lefty & LOCAL_TIME));
      if (aibot_checkforGoodies ((MUST_HAVE - MOVETYPE_WALK)))
      {
         ai_botgetGoody (dist);
         return ;
      } //end if
   } //end if
   self.lefty = (self.lefty + TRUE);
   olden = self.enemy;
   if (BotFindTarget ())
   {
      if ((olden.enemy == self))
      {
         olden.enemy = world;
      } //end if
      return ;
   } //end if
   if ((self.combat_search_time < time))
   {
      endEnemy ();
      return ;
   } //end if
   if (CheckReboundAttack ())
   {
      return ;
   } //end if
   Botmovetogoal (dist);
}; //end of the function aibot_chase
float (float minweight) aibot_checkforGoodies =
{
   local entity e;
   local entity botTarget;
   local float AFRAID;
   local float steps;
   local float best;
   local float weight;
   local float goody_yaw;
   local float lnd;
   local float weap;
   local float minimum;
   local vector spot;

   if ((self.air_finished < (time + MOVETYPE_FLYMISSILE)))
   {
      goForAir ();
      self.lefty = (self.lefty | GETGOODY);
      self.goody_time = (time + MOVETYPE_WALK);
      return (TRUE);
   } //end if
   AFRAID = RunAway ();
   botTarget = self.goalentity;
   e = findradius (self.origin,SEARCH_RADIUS);
   best = DONT_WANT;
   while (e)
   {
      if (Bot_IsAvoidedTarget (e))
      {
         e = e.chain;
         continue;
      } //end if
      weight = DONT_WANT;
      if ((e.origin_z > (self.origin_z + (0.700 * MAXJUMP))))
      {
         weight = DONT_WANT;

      } //end if
      else
      {
         if (((e.pathtype == DROPPED) || (e.pathtype == TELEPORT)))
         {
            weight = DONT_WANT;
            if (AFRAID)
            {
               weight = RunAwayWeight (e);
            } //end if

         } //end if
         else
         {
            if ((e.pathtype != REGULARTARGET))
            {
               weight = DONT_WANT;

            } //end if
            else
            {
               // ===== TIMEKEEPER: Pre-Rotation to Powerup Spawns =====
               // Pro players camp powerup spawns 5-10 seconds before they appear.
               // Check if this is an invisible powerup that's about to spawn.
               if ((e.solid != SOLID_TRIGGER))
               {
                  // Item is invisible (already taken)
                  // Check if it's a high-value powerup about to respawn
                  if ((((e.classname == "item_artifact_super_damage") || (e.classname == "item_artifact_invulnerability")) || (e.classname == "item_artifact_invisibility")))
                  {
                     // Is it scheduled to spawn soon?
                     if (((e.predicted_spawn > time) && (e.predicted_spawn < (time + 10.000))))
                     {
                        // YES! Camp the spawn point like a pro player
                        // Massive weight to override combat and other goals
                        weight = (MUST_HAVE + 500.000);
                     } //end if
                     else
                     {
                        weight = DONT_WANT;
                     } //end if
                  } //end if
                  else
                  {
                     weight = DONT_WANT;
                  } //end if

               } //end if
               else
               {
                  if (!e.istrigger)
                  {
                     weight = itemweight (e);
                     if ((weight < MUST_HAVE))
                     {
                        if ((((e.origin_z < self.enemy.absmin_z) && (e.origin_z < self.absmin_z)) && !AFRAID))
                        {
                           weight = DONT_WANT;
                        } //end if
                     } //end if
                  } //end if
               } //end if
               // ===== END TIMEKEEPER =====
            } //end if
         } //end if
      } //end if
      if ((weight > best))
      {
         botTarget.goalentity = e;
         best = weight;
      } //end if
      e = e.chain;
   } //end while
   minimum = minweight;
   if ((self.skil < TRUE))
   {
      if ((minimum < (WANT + FL_SWIM)))
      {
         minimum = (WANT + FL_SWIM);
      } //end if
   } //end if
   if ((best > DONT_WANT))
   {
      if (((best > minimum) || AFRAID))
      {
         if ((botTarget.classname != "BotTarget"))
         {
            objerror ("bad bot target in bot_ai! 6\n");
         } //end if
         setorigin (botTarget,botTarget.goalentity.origin);
         self.lefty = (self.lefty | GETGOODY);
         self.goody_time = (time + MOVETYPE_WALK);
         return (TRUE);
      } //end if
   } //end if
   botTarget.goalentity = self.enemy;
   return (FALSE);
}; //end of the function aibot_checkforGoodies

void (float dist) ai_endgetGoody =
{
   if ((self.lefty & GETGOODY))
   {
      self.lefty = (self.lefty - (self.lefty & GETGOODY));
   } //end if
   if ((self.goalentity.classname != "BotTarget"))
   {
      objerror ("bad bot target in bot_ai! 7\n");
   } //end if
   setorigin (self.goalentity,self.lastseenpos);
   self.goalentity.goalentity = self.enemy;
   if (enemyvisible (self.enemy))
   {
      self.lastseenpos = self.enemy.origin;
      if ((self.attack_finished < time))
      {
         if ((self.attack_state == AS_MELEE))
         {
            aibot_run_melee ();
         } //end if
         CheckBotAttack ();
      } //end if
   } //end if
   Botmovetogoal (dist);
}; //end of the function ai_endgetGoody

void (float dist) ai_botgetGoody =
{
   local float goody_yaw;
   local float dis;
   local float weap;

   self.combat_search_time = (self.combat_search_time + 0.100);
   if ((time > self.goody_time))
   {
      ai_endgetGoody (dist);
      return ;
   } //end if
   if ((self.goalentity.goalentity.solid == SOLID_NOT))
   {
      ai_endgetGoody (dist);
      return ;
   } //end if
   if (!Spotvisible (self.goalentity.goalentity))
   {
      if ((self.air_finished > MOVETYPE_FLYMISSILE))
      {
         ai_endgetGoody (dist);
         return ;
      } //end if
   } //end if
   goody_yaw = vectoyaw ((self.goalentity.origin - self.origin));
   if (enemyvisible (self.enemy))
   {
      self.lastseenpos = self.enemy.origin;
      weap = W_BestBotWeapon ();
      if ((((self.enemy.items & IT_INVULNERABILITY) || (self.skil < TRUE)) || (weap == IT_AXE)))
      {
         self.ideal_yaw = goody_yaw;
         ChangeYaw ();

      } //end if
      else
      {
         if ((self.attack_finished < time))
         {
            // ===== PROJECTILE PREDICTION: Main Combat Aiming =====
            local vector predicted_pos;
            local float proj_speed;

            // Determine projectile speed based on current weapon
            if ((self.weapon & IT_ROCKET_LAUNCHER))
            {
               proj_speed = 1000.0;  // Rockets: 1000 u/s
            }
            else if ((self.weapon & IT_GRENADE_LAUNCHER))
            {
               proj_speed = 600.0;   // Grenades: 600 u/s (arc ballistic)
            }
            else if ((self.weapon & IT_SUPER_NAILGUN) || (self.weapon & IT_NAILGUN))
            {
               proj_speed = 1000.0;  // Nails: 1000 u/s (fast projectiles)
            }
            else
            {
               proj_speed = 0.0;     // Hitscan weapons (shotgun, LG): instant
            }

            predicted_pos = PredictEnemyPositionForNav(self.enemy, proj_speed);
            self.ideal_yaw = vectoyaw ((predicted_pos - self.origin));
            // ===== END PROJECTILE PREDICTION =====

            ChangeYaw ();
            if ((self.attack_state == AS_MELEE))
            {
               aibot_run_melee ();
            } //end if
            CheckBotAttack ();
         } //end if
      } //end if
   } //end if
   if ((self.air_finished < MOVETYPE_TOSS))
   {
      waterupz (SVC_TEMPENTITY);
      return ;
   } //end if
   if ((self.flags & FL_SWIM))
   {
      if (waterupdown (dist))
      {
         return ;
      } //end if
   } //end if
   dis = vlen ((self.origin - self.goalentity.origin));
   if ((dis > dist))
   {
      dis = dist;

   } //end if
   else
   {
      if ((self.goalentity.goalentity.pathtype == DROPPED))
      {
         ai_endgetGoody (dist);
         return ;
      } //end if
   } //end if
   if (botwalkmove (goody_yaw,dis))
   {
      return ;
   } //end if
   if (Bot_tryjump (270.000,dist,FALSE))
   {
      return ;
   } //end if
   if ((self.lefty & GETGOODY))
   {
      self.lefty = (self.lefty - (self.lefty & GETGOODY));
   } //end if
   if ((self.goalentity.classname != "BotTarget"))
   {
      objerror ("bad bot target in bot_ai! 8\n");
   } //end if
   setorigin (self.goalentity,self.lastseenpos);
   self.goalentity.goalentity = self.enemy;
}; //end of the function ai_botgetGoody

