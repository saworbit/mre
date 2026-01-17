
// Forward declarations for functions used before they're defined
float (float minweight) aibot_checkforGoodies;

void () endEnemy = {

   local entity olden;

   olden = self.enemy;
   if ( (self.lefty & GETGOODY) ) {

      self.lefty = (self.lefty - GETGOODY);

   }
   if ( (self.lefty & MULTIENEMY) ) {

      self.lefty = (self.lefty - MULTIENEMY);

   }
   self.enemy = world;
   self.think = self.th_walk;
   self.nextthink = (time + 0.100);
   self.search_time = (time - TRUE);
   self.enemyrun = FALSE;
   self.goalentity.goalentity = self.goalentity;
   if ( (olden.classname == "player") ) {

      if ( (olden.enemy == self) ) {

         olden.enemy = world;

      }

   }

};

void () CallForHelp = {

   local entity e;
   local entity p;
   local entity tmp;
   local float d;

   HELPING = TRUE;
   e = find (world,classname,"dmbot");
   while ( e ) {

      if ( (e != self) ) {

         if ( (e.team == self.team) ) {

            if ( (e.enemy == world) ) {

               if ( (e.health > 80.000) ) {

                  if ( (e.items & ((((IT_ROCKET_LAUNCHER + IT_LIGHTNING) + IT_SUPER_NAILGUN) + IT_SUPER_SHOTGUN) + IT_GRENADE_LAUNCHER)) ) {

                     p = BestChaseRoute (e,self.enemy);
                     traceline (e.origin,self.enemy.origin,TRUE,e);
                     if ( ((trace_fraction == TRUE) || (p.enemycache == self.enemy)) ) {

                        if ( VERBOSEBOT ) {

                           dprint (e.teamname);
                           dprint (e.netname);
                           dprint (" coming to help!\n");

                        }
                        e.enemy = self.enemy;
                        tmp = self;
                        self = e;
                        BotFoundTarget ();
                        if ( (self.goalentity.classname != "BotTarget") ) {

                           objerror ("bad bot target in bot_ai! 1\n");

                        }
                        setorigin (self.goalentity,p.origin);
                        self = tmp;

                     }

                  }

               }

            }

         }

      }
      e = find (e,classname,"dmbot");

   }
   HELPING = FALSE;

};
float () RunAway = {

   local float weap;

   if ( (self.items & IT_INVULNERABILITY) ) {

      return ( FALSE );

   }
   if ( (self.enemy.items & IT_INVULNERABILITY) ) {

      return ( TRUE );

   }
   if ( (self.enemy.health < WANT) ) {

      return ( FALSE );

   }
   weap = W_BestHeldWeapon ();
   if ( (weap & (IT_ROCKET_LAUNCHER + IT_LIGHTNING)) ) {

      return ( FALSE );

   }
   if ( (self.items & IT_QUAD) ) {

      if ( ((self.health + (self.armorvalue * self.armortype)) > 50.000) ) {

         return ( FALSE );

      }

   }
   if ( (self.health < 15.000) ) {

      return ( TRUE );

   }
   if ( (weap & ((IT_SHOTGUN + IT_AXE) + IT_NAILGUN)) ) {

      if ( (self.enemy.items & IT_QUAD) ) {

         return ( TRUE );

      }
      if ( (self.enemy.weapon & ((IT_ROCKET_LAUNCHER + IT_LIGHTNING) + IT_SUPER_NAILGUN)) ) {

         return ( TRUE );

      }

   }
   if ( (self.lefty & MULTIENEMY) ) {

      if ( (self.health < 10.000) ) {

         return ( TRUE );

      }

   }
   return ( FALSE );

};

void () BotHuntTarget = {

   if ( VERBOSEBOT ) {

      dprint (self.teamname);
      dprint (self.netname);
      dprint (": Go kick ");
      dprint (self.enemy.teamname);
      dprint (self.enemy.netname);
      dprint ("'s ass!\n");

   }
   self.enemyrun = FALSE;
   self.strafetime = FALSE;
   if ( (self.lefty & ONTRAIN) ) {

      self.lefty = (self.lefty - ONTRAIN);

   }
   self.goalentity.goalentity = self.enemy;
   if ( (self.enemy.enemy == world) ) {

      self.enemy.enemy = self;

   }
   if ( (self.goalentity.classname != "BotTarget") ) {

      objerror ("bad bot target in bot_ai! 2\n");

   }
   setorigin (self.goalentity,self.enemy.origin);
   self.think = self.th_run;
   self.strafeonly = FALSE;
   self.ideal_yaw = vectoyaw ((self.enemy.origin - self.origin));
   self.lefty = ((self.lefty - (self.lefty & LOCAL_TIME)) + MOVETYPE_TOSS);
   self.nextthink = (time + 0.100);
   self.attack_finished = ((time + 0.700) - (0.200 * self.skil));
   self.search_time = (time + MOVETYPE_PUSH);
   clearCache (self);
   if ( teamplay ) {

      if ( !HELPING ) {

         CallForHelp ();

      }

   }

};

// Check if pending enemy reaction time has elapsed
// Returns TRUE if bot should now engage, FALSE otherwise
float () Bot_CheckReaction = {

   local float delay;

   if ( !self.pending_enemy ) {

      return ( FALSE );

   }

   // Clear if target died or disappeared
   if ( (self.pending_enemy.health <= FALSE) ) {

      self.pending_enemy = world;
      return ( FALSE );

   }

   // Calculate skill-based delay (200ms at skill 0, 0ms at skill 4+)
   delay = (0.200 - (self.skil * 0.050));
   if ( (delay < FALSE) ) {

      delay = FALSE;

   }

   // Check if reaction time has passed
   if ( (time >= (self.reaction_time + delay)) ) {

      // Promote pending to active enemy
      self.enemy = self.pending_enemy;
      self.pending_enemy = world;
      BotHuntTarget ();
      return ( TRUE );

   }

   return ( FALSE );

};

float () BotFoundTarget = {

   if ( (self.enemy == world) ) {

      return ( FALSE );

   }
   if ( teamplay ) {

      if ( (self.enemy.team == self.team) ) {

         self.enemy = world;
         return ( FALSE );

      }

   }
   if ( (self.deadflag != DEAD_NO) ) {

      self.enemy = world;
      return ( FALSE );

   }
   if ( (self.enemy.deadflag != DEAD_NO) ) {

      self.enemy = world;
      return ( FALSE );

   }
   if ( ((self.enemy.classname != "player") && (self.enemy.classname != "dmbot")) ) {

      self.enemy = world;
      return ( FALSE );

   }
   if ( (self.enemy == self) ) {

      self.enemy = world;
      return ( FALSE );

   }

   // High-skill bots (4+) react instantly
   if ( (self.skil >= 4.000) ) {

      BotHuntTarget ();
      return ( TRUE );

   }

   // Lower skill bots: delay reaction time
   // Store enemy as pending, will promote after delay elapses
   self.pending_enemy = self.enemy;
   self.reaction_time = time;
   self.enemy = world;
   return ( FALSE );

};

void (entity en2) secondEnemy = {

   if ( (self.enemy.classname != "player") ) {

      if ( (en2.classname == "player") ) {

         endEnemy ();
         self.enemy = en2;
         BotFoundTarget ();
         return ;

      }

   }
   if ( !enemyvisible (self.enemy) ) {

      endEnemy ();
      self.enemy = en2;
      BotFoundTarget ();

   }
   if ( (en2.weapon & (IT_LIGHTNING + IT_ROCKET_LAUNCHER)) ) {

      if ( !(self.enemy.weapon & (IT_LIGHTNING + IT_ROCKET_LAUNCHER)) ) {

         endEnemy ();
         self.enemy = en2;
         BotFoundTarget ();

      }

   }

};
float () BotfindBot = {

   local float n;
   local entity bots;

   if ( !self.lastbot ) {

      self.lastbot = find (world,classname,"dmbot");

   }
   n = MOVETYPE_STEP;
   while ( (n > FALSE) ) {

      n = (n - TRUE);
      bots = self.lastbot;
      if ( (!teamplay || (self.team != bots.team)) ) {

         if ( (bots != self) ) {

            if ( (bots != self.enemy) ) {

               if ( visible (bots) ) {

                  if ( (bots.health > FALSE) ) {

                     self.enemy = bots;
                     return ( BotFoundTarget () );

                  }

               }

            }

         }

      }
      self.lastbot = find (bots,classname,"dmbot");
      if ( !self.lastbot ) {

         self.lastbot = find (world,classname,"dmbot");

      }

   }
   return ( FALSE );

};

// FIX: Helper function to validate if a target is attackable
// Encapsulates all the checks from original BotFindTarget
float (entity targ) BotValidTarget = {

   // Can't target self
   if ( targ == self ) {

      return ( FALSE );

   }

   // Can't target already-targeted enemy (prevents switching)
   if ( targ == self.enemy ) {

      return ( FALSE );

   }

   // Skip observer/peeper entities
   if ( targ.classname == "peeper" ) {

      return ( FALSE );

   }

   // FIX: Skip observers in noclip mode (spectators)
   if ( targ.movetype == MOVETYPE_NOCLIP ) {

      return ( FALSE );

   }

   // FIX: Skip dead/dying players explicitly
   if ( targ.deadflag != DEAD_NO ) {

      return ( FALSE );

   }

   // Skip dead targets
   if ( targ.health <= FALSE ) {

      return ( FALSE );

   }

   // Teamplay - skip teammates
   if ( teamplay ) {

      if ( self.team == targ.team ) {

         return ( FALSE );

      }

   }

   // Skip notarget flagged entities
   if ( targ.flags & FL_NOTARGET ) {

      return ( FALSE );

   }

   // Must be visible
   if ( !enemyvisible (targ) ) {

      return ( FALSE );

   }

   // Must be in front OR audible
   if ( !infrontofbot (targ) ) {

      if ( !hearnoise (targ) ) {

         return ( FALSE );

      }

   }

   // Skip invisible enemies (Ring of Shadows)
   if ( targ.items & IT_INVISIBILITY ) {

      return ( FALSE );

   }

   // Low skill bots sometimes fail to notice targets
   if ( self.skil < TRUE ) {

      if ( (random () * MUST_HAVE) > 25.000 ) {

         return ( FALSE );

      }

   }

   return ( TRUE );

};

// Target acquisition: use checkclient() for players and cached bot list to avoid full entity scans
float /* Warning: Could not determine return type */ () BotFindTarget = {

   local entity head;
   local entity best;
   local float dist;
   local float best_dist;
   local float limit;

   best = world;
   best_dist = 100000;

   // Scan human players via checkclient (fast, avoids full entity walk).
   limit = fMaxClients;
   if ( (limit < TRUE) ) {

      limit = 16.000;

   }
   while ( (limit > FALSE) ) {

      limit = (limit - TRUE);
      head = checkclient ();
      if ( head ) {

         if ( BotValidTarget (head) ) {

            dist = vlen (head.origin - self.origin);
            if ( dist < best_dist ) {

               best_dist = dist;
               best = head;

            }

         }

      }

   }

   // Scan cached bot list.
   head = bot_list_head;
   while ( head ) {

      if ( (head.classname == "dmbot") && BotValidTarget (head) ) {

         dist = vlen (head.origin - self.origin);
         if ( dist < best_dist ) {

            best_dist = dist;
            best = head;

         }

      }
      head = head.bot_next;

   }

   if ( best == world ) {

      return ( FALSE );

   }

   self.enemy = best;
   return ( BotFoundTarget () );

};

// FIX: Humanized roaming behavior for idle bots
// Instead of standing frozen, bots wander, look around, and scavenge items
float BOT_IDLE_THINK = 0.100;

void () BotRoam = {

   local float roam_dist;

   // 1. Scan for items to give them purpose (Greedy Roaming)
   // Low weight threshold so they lazily pick up nearby stuff
   if ( aibot_checkforGoodies (20.000) ) {
      return;
   }

   // 2. If no items, pick a random direction occasionally
   // Change direction every 1-3 seconds or if hitting a wall
   if ( (self.search_time < time) || !walkmove (self.ideal_yaw, 0.000) ) {
      self.ideal_yaw = (random () * 360.000);
      self.search_time = (time + 1.000 + (random () * 2.000));
      ChangeYaw ();
   }

   // 3. Smoothly rotate towards interest points (slight look wander)
   if ( (random () < 0.100) ) {
      self.ideal_yaw = (self.ideal_yaw + (random () * 30.000) - 15.000);
      ChangeYaw ();
   }

   // 4. Move forward at casual trot speed (~200 vs 350 run speed)
   roam_dist = (200.000 * BOT_IDLE_THINK);

   // Call robust movement function
   if ( !botwalkmove (self.ideal_yaw, roam_dist) ) {
      // If blocked, pick new direction for next frame
      self.search_time = (time - 1.000);
   }

};

void () ai_botstand = {

   // Check for enemies first (high alert)
   if ( BotFindTarget () ) {
      return;
   }

   // Otherwise, look alive
   BotRoam ();

};

void () ai_botturn = {

   if ( BotFindTarget () ) {
      return;
   }

   // Roam instead of just turning in place
   BotRoam ();

};

void () aibot_run_melee = {

   self.ideal_yaw = vectoyaw ((self.enemy.origin - self.origin));
   ChangeYaw ();
   if ( FacingIdeal () ) {

      self.attack_state = AS_STRAIGHT;
      self.th_melee ();

   }

};

void (float dist, float turn) aibot_run_slide = {

   local float ofs;
   local float rdir;
   local float rng;
   local float rnd;
   local float dis;
   local float trn;
   local float weap;
   local vector cover_angles;
   local vector enemy_view;
   local vector cover_left;
   local vector cover_right;
   local float cover_bias;
   local float cover_thresh;
   local float left_frac;
   local float right_frac;

   trn = turn;
   self.ideal_yaw = vectoyaw ((self.enemy.origin - self.origin));
   ChangeYaw ();
   ofs = 90.000;
   dis = dist;
   self.strafeonly = (self.strafeonly - TRUE);
   if ( (self.strafeonly > FALSE) ) {

      trn = NOTURN;

   }
   cover_bias = FALSE;
   cover_thresh = 0.900;
   cover_angles_x = FALSE;
   cover_angles_y = self.ideal_yaw;
   cover_angles_z = FALSE;
   makevectors (cover_angles);
   enemy_view = (self.enemy.origin + self.enemy.view_ofs);
   cover_left = (self.origin - (v_right * 32.000));
   cover_right = (self.origin + (v_right * 32.000));
   left_frac = TRUE;
   right_frac = TRUE;
   traceline (enemy_view,cover_left,TRUE,self.enemy);
   left_frac = trace_fraction;
   traceline (enemy_view,cover_right,TRUE,self.enemy);
   right_frac = trace_fraction;
   if ( ((left_frac < cover_thresh) || (right_frac < cover_thresh)) ) {

      if ( (left_frac < right_frac) ) {

         cover_bias = CONTENT_EMPTY;

      } else {

         cover_bias = TRUE;

      }

   }
   rdir = (random () * MOVETYPE_WALK);
   rng = botrange (self.enemy);
   if ( (rng == RANGE_NEAR) ) {

      rdir = (rdir + 0.800);

   } else {

      if ( (rng == RANGE_MELEE) ) {

         rdir = (rdir + 1.200);
         rnd = random ();
         weap = W_BestHeldWeapon ();
         if ( (weap == IT_ROCKET_LAUNCHER) ) {

            rnd = FALSE;

         } else {

            if ( (weap == IT_GRENADE_LAUNCHER) ) {

               rnd = FALSE;

            } else {

               if ( (self.enemyrun > MOVETYPE_STEP) ) {

                  rnd = TRUE;

               } else {

                  if ( (weap == IT_AXE) ) {

                     rnd = TRUE;

                  } else {

                     if ( (self.enemy.weapon == IT_ROCKET_LAUNCHER) ) {

                        rnd = TRUE;

                     }

                  }

               }

            }

         }
         if ( (rnd < 0.300) ) {

            if ( botwalkmove ((self.ideal_yaw + 180.000),dis) ) {

               return ;

            }

         }

      } else {

         if ( (rng == RANGE_MID) ) {

            weap = W_BestHeldWeapon ();
            if ( (weap == IT_LIGHTNING) ) {

               rdir = (rdir - MOVETYPE_WALK);

            } else {

               rdir = (rdir - TRUE);

            }

         } else {

            if ( (rng == RANGE_FAR) ) {

               rdir = (rdir - 2.500);

            }

         }

      }

   }
   if ( (self.weapon == IT_AXE) ) {

      rdir = FALSE;

   } else {

      if ( (self.weapon == IT_ROCKET_LAUNCHER) ) {

         rdir = (rdir + 1.500);

      } else {

         if ( (self.weapon == IT_GRENADE_LAUNCHER) ) {

            rdir = (rdir + 1.500);

         }

      }

   }
   if ( (self.enemy.weapon == IT_ROCKET_LAUNCHER) ) {

      rdir = (rdir + 1.500);

   } else {

      if ( (self.enemy.weapon == IT_LIGHTNING) ) {

         rdir = (rdir + 1.500);

      }

   }
   if ( (self.enemyrun > FL_CLIENT) ) {

      rdir = (rdir - FL_SWIM);

   } else {

      if ( (self.origin_z > (self.enemy.origin_z + 130.000)) ) {

         rdir = ((rdir + 1.100) + random ());
         if ( (rdir >= 1.500) ) {

            trn = NOTURN;

         }
         if ( (self.weapon == IT_AXE) ) {

            trn = turn;
            rdir = FALSE;

         }

      }

   }
   if ( (rdir < 1.500) ) {

      if ( (trn == CANTURN) ) {

         Botmovetogoal (dis);
         return ;

      }
      if ( botwalkmove (self.ideal_yaw,dis) ) {

         return ;

      }
      ofs = 90.000;

   } else {

      if ( (rdir < 2.400) ) {

         ofs = 45.000;

      }

   }
   if ( (self.skil == FALSE) ) {

      return ;

   }
   self.strafetime = (self.strafetime + 0.100);
   if ( (self.skil < FL_SWIM) ) {

      if ( (self.skil < TRUE) ) {

         dis = (0.700 * dis);

      }
      if ( (self.strafetime == 0.100) ) {

         rnd = (random () * MOVETYPE_STEP);
         if ( (self.skil >= TRUE) ) {

            rnd = ((rnd - self.skil) + 0.500);

         }
         if ( (rnd > self.skil) ) {

            self.strafetime = FALSE;
            return ;

         }

      }

   }
   if ( (self.strafetime > 0.400) ) {

      rnd = (random () * FL_SWIM);
      if ( (rnd > 1.870) ) {

         if ( (self.lefty & STRAFE_DIR) ) {

            self.lefty = (self.lefty - STRAFE_DIR);

         } else {

            self.lefty = (self.lefty + STRAFE_DIR);

         }
         self.strafetime = FALSE;
         return ;

      }

   }
   if ( (self.lefty & STRAFE_DIR) ) {

      ofs = (CONTENT_EMPTY * ofs);

   }
   if ( (cover_bias != FALSE) ) {

      if ( ((cover_bias > FALSE) && (ofs < FALSE)) || ((cover_bias < FALSE) && (ofs > FALSE)) ) {

         ofs = (CONTENT_EMPTY * ofs);

      }
      if ( (ofs < FALSE) ) {

         if ( !(self.lefty & STRAFE_DIR) ) {

            self.lefty = (self.lefty + STRAFE_DIR);

         }

      } else {

         if ( (self.lefty & STRAFE_DIR) ) {

            self.lefty = (self.lefty - STRAFE_DIR);

         }

      }

   }
   if ( botwalkmove ((self.ideal_yaw + ofs),dis) ) {

      return ;

   }
   self.strafetime = FALSE;
   if ( (self.lefty & STRAFE_DIR) ) {

      self.lefty = (self.lefty - STRAFE_DIR);

   } else {

      self.lefty = (self.lefty + STRAFE_DIR);

   }
   if ( ((ofs == 90.000) || (ofs == -90.000)) ) {

      rnd = random ();
      if ( (rnd < 0.050) ) {

         if ( (trn == CANTURN) ) {

            Botmovetogoal (dis);
            return ;

         }

      }
      if ( (rnd < 0.500) ) {

         walkmove ((self.ideal_yaw + 180.000),(dis * 0.500));

      }
      return ;

   }
   botwalkmove (self.ideal_yaw,dis);

};

void (float dist) ai_botgetGoody;

void (float dist) ai_botcharge = {

   local float rng;
   local float oldrng;

   if ( (self.lefty & GETGOODY) ) {

      ai_botgetGoody (dist);
      return ;

   }
   if ( enemyvisible (self.enemy) ) {

      rng = vlen ((self.enemy.origin - self.origin));
      oldrng = vlen ((self.goalentity.origin - self.origin));
      if ( (self.goalentity.classname != "BotTarget") ) {

         objerror ("bad bot target in bot_ai! 3\n");

      }
      setorigin (self.goalentity,self.enemy.origin);
      if ( (self.enemyrun > FALSE) ) {

         self.enemyrun = (self.enemyrun - TRUE);

      }
      if ( (rng > (oldrng + MOVETYPE_BOUNCE)) ) {

         self.enemyrun = (self.enemyrun + FL_SWIM);

      }

   }
   aibot_run_slide (dist,NOTURN);

};

void (float dist) ai_botnailcharge = {

   local float rnd;

   if ( !enemyvisible (self.enemy) ) {

      self.think = self.th_run;

   }
   if ( !FacingIdeal () ) {

      self.think = self.th_run;

   }
   if ( (self.enemy.deadflag != DEAD_NO) ) {

      endEnemy ();
      return ;

   }
   ai_botcharge (dist);

};
float (float minweight) aibot_checkforGoodies;

void (float dist) ai_botretreat = {

   local vector away_dir;
   local float away_yaw;

   if ( !self.enemy ) {

      return ;

   }
   away_dir = (self.origin - self.enemy.origin);
   away_yaw = vectoyaw (away_dir);
   self.ideal_yaw = away_yaw;
   ChangeYaw ();
   if ( botwalkmove (self.ideal_yaw, dist) ) {

      return ;

   }
   if ( botwalkmove ((away_yaw + 45.000), (dist * 0.700)) ) {

      return ;

   }
   if ( botwalkmove ((away_yaw - 45.000), (dist * 0.700)) ) {

      return ;

   }
   if ( botwalkmove ((away_yaw + 90.000), (dist * 0.500)) ) {

      return ;

   }
   if ( botwalkmove ((away_yaw - 90.000), (dist * 0.500)) ) {

      return ;

   }

};

void (float state, string label) BotLogAI = {

   if ( (self.last_ai_state == state) ) {

      return ;

   }
   // FIX: Track when state changes for hysteresis
   self.last_ai_state_time = time;
   self.last_ai_state = state;

   if ( (cvar ("developer") <= 0.000) ) {

      return ;

   }
   dprint ("[");
   dprint (self.netname);
   dprint ("] AI: ");
   dprint (label);
   dprint ("\n");

};

void (float dist) BotAI_Main = {

   local vector delta;
   local float axis;
   local float rng;
   local float oldrng;
   local float direct;
   local float ang_rint;
   local float ang_floor;
   local float ang_ceil;

   if ( (self.enemy.deadflag != DEAD_NO) ) {

      BotLogAI (AI_STATE_NONE, "NO_ENEMY");
      endEnemy ();
      return ;

   }
   if ( !self.enemy ) {

      BotLogAI (AI_STATE_NONE, "NO_ENEMY");
      endEnemy ();
      return ;

   }
   if ( (self.lefty & GETGOODY) ) {

      BotLogAI (AI_STATE_GOODY, "GOODY");
      ai_botgetGoody (dist);
      return ;

   }
   enemy_vis = enemyvisible (self.enemy);
   if ( (enemy_vis || Spotvisible (self.enemy)) ) {

      rng = vlen ((self.enemy.origin - self.origin));
      oldrng = vlen ((self.goalentity.origin - self.origin));
      if ( (self.enemyrun > FALSE) ) {

         self.enemyrun = (self.enemyrun - TRUE);

      }
      if ( (rng > (oldrng + MOVETYPE_BOUNCE)) ) {

         self.enemyrun = (self.enemyrun + FL_SWIM);

      }
      if ( (self.goalentity.classname != "BotTarget") ) {

         objerror ("bad bot target in bot_ai! 4\n");

      }
      setorigin (self.goalentity,self.enemy.origin);
      self.search_time = (time + MOVETYPE_PUSH);
      // Object Permanence: track when enemy was last seen
      self.last_seen_time = time;
      self.lastseenpos = self.enemy.origin;

   }
   if ( (self.search_time < time) ) {

      BotLogAI (AI_STATE_NONE, "SEARCH_EXPIRED");
      endEnemy ();
      BotFindTarget ();
      return ;

   }
   if ( ((self.lefty & LOCAL_TIME) > MOVETYPE_FLY) ) {

      self.lefty = (self.lefty - (self.lefty & LOCAL_TIME));
      self.lastseenpos = self.goalentity.origin;
      if ( aibot_checkforGoodies (DONT_WANT) ) {

         BotLogAI (AI_STATE_GOODY, "GOODY");
         ai_botgetGoody (dist);
         return ;

      }

   }
   self.lefty = (self.lefty + TRUE);
   if ( RunAway () ) {

      self.lefty = (self.lefty - (self.lefty & LOCAL_TIME));
      self.lastseenpos = self.goalentity.origin;

      // FIX: Hysteresis - stay in GOODY/RETREAT for minimum 0.5s to prevent oscillation
      if ( ((self.last_ai_state == AI_STATE_GOODY) || (self.last_ai_state == AI_STATE_RETREAT)) && (time < (self.last_ai_state_time + 0.500)) ) {

         // Continue current state without re-evaluating
         if ( (self.last_ai_state == AI_STATE_GOODY) ) {

            ai_botgetGoody (dist);

         } else {

            ai_botretreat (dist);

         }
         return ;

      }

      if ( aibot_checkforGoodies (DONT_WANT) ) {

         BotLogAI (AI_STATE_GOODY, "GOODY");
         ai_botgetGoody (dist);
         return ;

      }
      BotLogAI (AI_STATE_RETREAT, "RETREAT");
      ai_botretreat (dist);
      return ;

   }
   enemy_infront = infrontofbot (self.enemy);
   enemy_yaw = vectoyaw ((self.enemy.origin - self.origin));
   if ( !enemy_vis ) {

      // Object Permanence: continue engaging last known position
      local float memory_duration;
      memory_duration = (0.500 + (self.skil * 0.250));
      if ( (memory_duration > 1.500) )
         memory_duration = 1.500;

      if ( (time < (self.last_seen_time + memory_duration)) ) {

         // Still in memory window - fire at last known position
         BotLogAI (AI_STATE_ATTACK, "MEMORY_ATTACK");
         CheckBotAttack ();
         aibot_run_slide (dist,CANTURN);
         return ;

      }
      // Memory expired - chase
      BotLogAI (AI_STATE_CHASE, "CHASE");
      aibot_setupchase ();
      Botmovetogoal (dist);
      return ;

   }
   if ( (self.attack_state == AS_MELEE) ) {

      BotLogAI (AI_STATE_ATTACK, "MELEE");
      aibot_run_melee ();

   }
   BotLogAI (AI_STATE_ATTACK, "ATTACK");
   CheckBotAttack ();
   aibot_run_slide (dist,CANTURN);
   return ;

};

void () aibot_setupchase = {

   local entity pth;

   self.think = bot_chase;
   if ( TrueReachable (self.goalentity) ) {

      return ;

   }
   if ( RunAway () ) {

      self.lefty = (self.lefty - (self.lefty & LOCAL_TIME));
      aibot_checkforGoodies ((WANT - TRUE));
      self.lastseenpos = self.goalentity.origin;
      return ;

   }
   pth = BestChaseRoute (self,self.enemy);
   if ( (self.goalentity.classname != "BotTarget") ) {

      objerror ("bad bot target in bot_ai! 1\n");

   }
   if ( (pth != self.enemy) ) {

      setorigin (self.goalentity,pth.origin);

   }
   self.search_time = (time + MOVETYPE_TOSS);

};

void (float dist) aibot_chase = {

   local entity olden;
   local float weap;
   local float rnd;

   if ( (self.enemy.deadflag != DEAD_NO) ) {

      endEnemy ();
      return ;

   }
   if ( (self.lefty & GETGOODY) ) {

      ai_botgetGoody (dist);
      return ;

   }
   enemy_vis = enemyvisible (self.enemy);
   rnd = random ();
   if ( (rnd < 0.900) ) {

      enemy_vis = enemy_vis;

   }
   if ( enemy_vis ) {

      if ( (self.goalentity.classname != "BotTarget") ) {

         objerror ("bad bot target in bot_ai! 1\n");

      }
      setorigin (self.goalentity,self.enemy.origin);
      self.search_time = (time + MOVETYPE_FLY);
      self.think = self.th_run;
      Botmovetogoal (dist);
      return ;

   }
   if ( RunAway () ) {

      if ( (self.search_time < time) ) {

         endEnemy ();
         return ;

      }
      self.lefty = (self.lefty - (self.lefty & LOCAL_TIME));
      if ( aibot_checkforGoodies ((WANT - TRUE)) ) {

         ai_botgetGoody (dist);
         self.lastseenpos = self.goalentity.origin;
         return ;

      }

   }
   if ( (self.enemy.items & IT_INVISIBILITY) ) {

      if ( (self.skil < MOVETYPE_WALK) ) {

         endEnemy ();
         return ;

      }

   }
   if ( ((self.lefty & LOCAL_TIME) > MOVETYPE_FLY) ) {

      self.lastseenpos = self.goalentity.origin;
      self.lefty = (self.lefty - (self.lefty & LOCAL_TIME));
      if ( aibot_checkforGoodies ((MUST_HAVE - MOVETYPE_WALK)) ) {

         ai_botgetGoody (dist);
         return ;

      }

   }
   self.lefty = (self.lefty + TRUE);
   olden = self.enemy;
   if ( BotFindTarget () ) {

      if ( (olden.enemy == self) ) {

         olden.enemy = world;

      }
      return ;

   }
   if ( (self.search_time < time) ) {

      endEnemy ();
      return ;

   }
   if ( CheckReboundAttack () ) {

      return ;

   }
   Botmovetogoal (dist);

};
float (float minweight) aibot_checkforGoodies = {

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

   if ( (self.air_finished < (time + MOVETYPE_FLYMISSILE)) ) {

      goForAir ();
      self.lefty = (self.lefty | GETGOODY);
      self.goody_time = (time + MOVETYPE_WALK);
      return ( TRUE );

   }
   AFRAID = RunAway ();
   botTarget = self.goalentity;
   e = findradius (self.origin,SEARCH_RADIUS);
   best = DONT_WANT;
   while ( e ) {

      weight = DONT_WANT;
      if ( (e.origin_z > (self.origin_z + (0.700 * MAXJUMP))) ) {

         weight = DONT_WANT;

      } else {

         if ( ((e.pathtype == DROPPED) || (e.pathtype == TELEPORT)) ) {

            weight = DONT_WANT;
            if ( AFRAID ) {

               weight = RunAwayWeight (e);

            }

         } else {

            if ( (e.pathtype != REGULARTARGET) ) {

               weight = DONT_WANT;

            } else {

               if ( (e.solid != SOLID_TRIGGER) ) {

                  weight = DONT_WANT;

               } else {

                  if ( !e.istrigger ) {

                     weight = itemweight (e);
                     if ( (weight > DONT_WANT) ) {

                        // Boost survival goodies when we are wounded or running away.
                        local float health_deficit;
                        local float armor_deficit;

                        health_deficit = (self.max_health - self.health);
                        if ( (health_deficit > 0.000) && (e.healamount > 0.000) ) {

                           if ( (health_deficit > 60.000) ) {

                              health_deficit = 60.000;

                           }
                           weight = (weight + (health_deficit * 0.300));

                        }
                        armor_deficit = (e.armorvalue - self.armorvalue);
                        if ( (armor_deficit > 0.000) ) {

                           if ( (armor_deficit > 120.000) ) {

                              armor_deficit = 120.000;

                           }
                           weight = (weight + (armor_deficit * 0.250));

                        }
                        if ( AFRAID ) {

                           if ( ((e.healamount > 0.000) || (armor_deficit > 0.000)) ) {

                              weight = (weight + (KINDA_WANT * 0.400));

                           }
                           weight = (weight + (0.050 * vlen ((self.enemy.origin - e.origin))));

                        }

                     }
                     if ( (weight < MUST_HAVE) ) {

                        if ( (((e.origin_z < self.enemy.absmin_z) && (e.origin_z < self.absmin_z)) && !AFRAID) ) {

                           weight = DONT_WANT;

                        }

                     }

                  }

               }

            }

         }

      }
      if ( (weight > best) ) {

         botTarget.goalentity = e;
         best = weight;

      }
      e = e.chain;

   }
   minimum = minweight;
   if ( (self.skil < TRUE) ) {

      if ( (minimum < (WANT + FL_SWIM)) ) {

         minimum = (WANT + FL_SWIM);

      }

   }
   if ( (best > DONT_WANT) ) {

      if ( ((best > minimum) || AFRAID) ) {

         if ( (botTarget.classname != "BotTarget") ) {

            objerror ("bad bot target in bot_ai! 6\n");

         }
         setorigin (botTarget,botTarget.goalentity.origin);
         self.lefty = (self.lefty | GETGOODY);
         self.goody_time = (time + MOVETYPE_WALK);
         return ( TRUE );

      }

   }
   botTarget.goalentity = self.enemy;
   return ( FALSE );

};

void (float dist) ai_endgetGoody = {

   if ( (self.lefty & GETGOODY) ) {

      self.lefty = (self.lefty - GETGOODY);

   }
   if ( (self.goalentity.classname != "BotTarget") ) {

      objerror ("bad bot target in bot_ai! 7\n");

   }
   setorigin (self.goalentity,self.lastseenpos);
   self.goalentity.goalentity = self.enemy;
   if ( enemyvisible (self.enemy) ) {

      self.lastseenpos = self.enemy.origin;
      if ( (self.attack_finished < time) ) {

         if ( (self.attack_state == AS_MELEE) ) {

            aibot_run_melee ();

         }
         CheckBotAttack ();

      }

   }
   Botmovetogoal (dist);

};

void (float dist) ai_botgetGoody = {

   local float goody_yaw;
   local float dis;
   local float weap;

   self.search_time = (self.search_time + 0.100);
   if ( (time > self.goody_time) ) {

      ai_endgetGoody (dist);
      return ;

   }
   if ( (self.goalentity.goalentity.solid == SOLID_NOT) ) {

      ai_endgetGoody (dist);
      return ;

   }
   if ( !Spotvisible (self.goalentity.goalentity) ) {

      if ( (self.air_finished > MOVETYPE_FLYMISSILE) ) {

         ai_endgetGoody (dist);
         return ;

      }

   }
   goody_yaw = vectoyaw ((self.goalentity.origin - self.origin));
   if ( enemyvisible (self.enemy) ) {

      self.lastseenpos = self.enemy.origin;
      weap = W_BestBotWeapon ();
      if ( (((self.enemy.items & IT_INVULNERABILITY) || (self.skil < TRUE)) || (weap == IT_AXE)) ) {

         self.ideal_yaw = goody_yaw;
         ChangeYaw ();

      } else {

         if ( (self.attack_finished < time) ) {

            self.ideal_yaw = vectoyaw ((self.enemy.origin - self.origin));
            ChangeYaw ();
            if ( (self.attack_state == AS_MELEE) ) {

               aibot_run_melee ();

            }
            CheckBotAttack ();

         }

      }

   }
   if ( (self.air_finished < MOVETYPE_TOSS) ) {

      waterupz (SVC_TEMPENTITY);
      return ;

   }
   if ( (self.flags & FL_SWIM) ) {

      if ( waterupdown (dist) ) {

         return ;

      }

   }
   dis = vlen ((self.origin - self.goalentity.origin));
   if ( (dis > dist) ) {

      dis = dist;

   } else {

      if ( (self.goalentity.goalentity.pathtype == DROPPED) ) {

         ai_endgetGoody (dist);
         return ;

      }

   }
   if ( botwalkmove (goody_yaw,dis) ) {

      return ;

   }
   if ( Bot_tryjump (270.000,dist,FALSE) ) {

      return ;

   }
   if ( (self.lefty & GETGOODY) ) {

      self.lefty = (self.lefty - GETGOODY);

   }
   if ( (self.goalentity.classname != "BotTarget") ) {

      objerror ("bad bot target in bot_ai! 8\n");

   }
   setorigin (self.goalentity,self.lastseenpos);
   self.goalentity.goalentity = self.enemy;

};
