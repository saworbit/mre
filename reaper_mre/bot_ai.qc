
void () endEnemy =
{
   local entity olden;

   olden = self.enemy;
   if ((self.lefty & GETGOODY))
   {
      self.lefty = (self.lefty - GETGOODY);
   } //end if
   if ((self.lefty & MULTIENEMY))
   {
      self.lefty = (self.lefty - MULTIENEMY);
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
   self.search_time = (time - TRUE);
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
   // Only dodge if we have an enemy (in combat mode)
   if ((self.enemy == world))
   {
      return (FALSE);
   } //end if

   local entity item;
   local float bestdist;
   local float bestrating;
   local float rating;
   local float dist;
   local vector org;

   bestdist = 10000.000;
   bestrating = 0.000;
   item = world;

   // ===== SCAN FOR GRENADES (highest priority) =====
   local entity grenade;
   grenade = find (world,classname,"grenade");
   while ((grenade != world))
   {
      // Only dodge grenades moving toward us
      org = (((grenade.origin + (grenade.velocity * 0.150)) - self.origin) - (self.velocity * 0.150));
      if (((vlen (org) < vlen ((grenade.origin - self.origin))) && (vlen (org) < 240.000)))
      {
         // Calculate threat rating based on distance and owner
         dist = vlen (org);
         rating = (1.000 / dist);
         if ((grenade.owner != world))
         {
            rating = (rating * bot_size_player (grenade.owner));
         } //end if

         // Track most threatening grenade
         if ((rating > bestrating))
         {
            bestrating = rating;
            bestdist = dist;
            item = grenade;
         } //end if
      } //end if
      grenade = find (grenade,classname,"grenade");
   } //end while

   // ===== SCAN FOR MISSILES (lower priority than grenades) =====
   local entity missile;
   missile = find (world,classname,"missile");
   while ((missile != world))
   {
      // Only dodge missiles moving toward us
      org = (((missile.origin + (missile.velocity * 0.150)) - self.origin) - (self.velocity * 0.150));
      if (((vlen (org) < vlen ((missile.origin - self.origin))) && (vlen (org) < 240.000)))
      {
         // Calculate threat rating based on distance and owner
         dist = vlen (org);
         rating = (0.500 / dist);
         if ((missile.owner != world))
         {
            rating = (rating * bot_size_player (missile.owner));
         } //end if

         // Track most threatening missile
         if ((rating > bestrating))
         {
            bestrating = rating;
            bestdist = dist;
            item = missile;
         } //end if
      } //end if
      missile = find (missile,classname,"missile");
   } //end while

   // ===== NO THREAT DETECTED =====
   if ((item == world))
   {
      self.avoid = world;
      return (FALSE);
   } //end if

   // ===== EXECUTE DODGE MOVEMENT =====
   // Already dodging this projectile - don't recalculate
   if ((self.avoid == item))
   {
      return (TRUE);
   } //end if

   // Calculate perpendicular escape vector based on projectile velocity
   local vector norm;
   local float dodge_dir;

   norm = normalize (item.velocity);
   // Choose left or right perpendicular based on which side is safer
   // Perpendicular vector: rotate 90° either direction
   if ((random () > 0.500))
   {
      dodge_dir = (vectoyaw (norm) + 90.000);
   } //end if
   else
   {
      dodge_dir = (vectoyaw (norm) - 90.000);
   } //end if

   // ===== REAPER MOVEMENT ADAPTATION =====
   // Set strafe direction using Reaper's lefty flag system
   // Determine which perpendicular direction to dodge based on angle
   local float angle_diff;
   angle_diff = anglemod ((dodge_dir - self.angles_y));

   if ((angle_diff < 180.000))
   {
      // Dodge to the right - set STRAFE_DIR flag
      if (!(self.lefty & STRAFE_DIR))
      {
         self.lefty = (self.lefty | STRAFE_DIR);
      } //end if
   } //end if
   else
   {
      // Dodge to the left - clear STRAFE_DIR flag
      if ((self.lefty & STRAFE_DIR))
      {
         self.lefty = (self.lefty - STRAFE_DIR);
      } //end if
   } //end if

   // Mark this projectile as being actively dodged
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
                     traceline (e.origin,self.enemy.origin,TRUE,e);
                     if (((trace_fraction == TRUE) || (p.enemycache == self.enemy)))
                     {
                        if (VERBOSEBOT)
                        {
                           dprint (e.teamname);
                           dprint (e.netname);
                           dprint (" coming to help!\n");
                        } //end if
                        e.enemy = self.enemy;
                        tmp = self;
                        self = e;
                        BotFoundTarget ();
                        if ((self.goalentity.classname != "BotTarget"))
                        {
                           objerror ("bad bot target in bot_ai! 1\n");
                        } //end if
                        setorigin (self.goalentity,p.origin);
                        self = tmp;
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
      // OLD CHAT REMOVED - using botchat.qc personality system
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
      // OLD CHAT REMOVED - using botchat.qc personality system
      return (TRUE);
   } //end if
   if ((weap & ((IT_SHOTGUN + IT_AXE) + IT_NAILGUN)))
   {
      if ((self.enemy.items & IT_QUAD))
      {
         // OLD CHAT REMOVED - using botchat.qc personality system
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
         // OLD CHAT REMOVED - using botchat.qc personality system
         return (TRUE);
      } //end if
   } //end if
   return (FALSE);
}; //end of the function RunAway

void () BotHuntTarget =
{
   self.enemyrun = FALSE;
   self.strafetime = FALSE;
   if ((self.lefty & ONTRAIN))
   {
      self.lefty = (self.lefty - ONTRAIN);
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
   self.ideal_yaw = vectoyaw ((self.enemy.origin - self.origin));
   self.lefty = ((self.lefty - (self.lefty & LOCAL_TIME)) + MOVETYPE_TOSS);
   self.nextthink = (time + 0.100);
   self.attack_finished = ((time + 0.700) - (0.200 * self.skil));
   self.search_time = (time + MOVETYPE_PUSH);
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
   // OLD CHAT SYSTEM REMOVED - Replaced by botchat.qc personality system
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
float /* ERROR: Could not determine return type */ () BotFindTarget =
{
   local entity client;
   local float len;
   local float bw;

   client = checkclient ();
   if (!client)
   {
      return (BotfindBot ());
   } //end if
   if ((client.classname == "watcher"))
   {
      return (BotfindBot ());
   } //end if
   if ((client == self.enemy))
   {
      return (FALSE);
   } //end if
   if (teamplay)
   {
      if ((self.team == client.team))
      {
         return (BotfindBot ());
      } //end if
   } //end if
   if ((client.flags & FL_NOTARGET))
   {
      return (BotfindBot ());
   } //end if
   if (!enemyvisible (client))
   {
      return (BotfindBot ());
   } //end if
   if (!infrontofbot (client))
   {
      if (!hearnoise (client))
      {
         return (BotfindBot ());
      } //end if
   } //end if
   if (((self.origin_z > (client.origin_z + 120.000)) || ((self.origin_z + 120.000) < client.origin_z)))
   {
      self.enemy = client;
      if (RunAway ())
      {
         self.enemy = world;
         return (BotfindBot ());
      } //end if
   } //end if
   if ((client.items & IT_INVISIBILITY))
   {
      return (BotfindBot ());
   } //end if
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
   self.enemy = client;
   return (BotFoundTarget ());
}; //end of the function BotFindTarget

void () ai_botstand =
{
   if (BotFindTarget ())
   {
      return ;
   } //end if
}; //end of the function ai_botstand

void () ai_botturn =
{
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

   trn = turn;
   self.ideal_yaw = vectoyaw ((self.enemy.origin - self.origin));
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
            self.lefty = (self.lefty - STRAFE_DIR);

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
      self.lefty = (self.lefty - STRAFE_DIR);

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

   if ((self.enemy.deadflag != DEAD_NO))
   {
      endEnemy ();
      return ;
   } //end if
   // Streak-based skill tuning: adjust up on hot streaks, down on slumps.
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
      // Cache visible enemy velocity to extend chase prediction past line-of-sight breaks.
      self.last_enemy_vel = self.enemy.velocity;
      self.search_time = (time + MOVETYPE_PUSH);
   } //end if
   if ((self.search_time < time))
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

                  // OLD CHAT REMOVED - using botchat.qc personality system

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
   CheckBotAttack ();
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
   self.search_time = (time + MOVETYPE_TOSS);
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
      self.search_time = (time + MOVETYPE_FLY);
      self.think = self.th_run;
      Botmovetogoal (dist);
      return ;
   } //end if
   // If LOS breaks, push the chase target forward using last seen velocity.
   if ((!enemy_vis) && (self.skil > TRUE))
   {
      setorigin (self.goalentity,(self.goalentity.origin + (self.last_enemy_vel * 0.200)));
      self.search_time = (self.search_time + 0.100);
   } //end if
   if (RunAway ())
   {
      if ((self.search_time < time))
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
   if ((self.search_time < time))
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
               if ((e.solid != SOLID_TRIGGER))
               {
                  weight = DONT_WANT;

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
      self.lefty = (self.lefty - GETGOODY);
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

   self.search_time = (self.search_time + 0.100);
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
            self.ideal_yaw = vectoyaw ((self.enemy.origin - self.origin));
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
      self.lefty = (self.lefty - GETGOODY);
   } //end if
   if ((self.goalentity.classname != "BotTarget"))
   {
      objerror ("bad bot target in bot_ai! 8\n");
   } //end if
   setorigin (self.goalentity,self.lastseenpos);
   self.goalentity.goalentity = self.enemy;
}; //end of the function ai_botgetGoody
