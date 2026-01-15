
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
   BotHuntTarget ();
   return ( TRUE );

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
float /* Warning: Could not determine return type */ () BotFindTarget = {

   local entity client;
   local float len;
   local float bw;

   client = checkclient ();
   if ( !client ) {

      return ( BotfindBot () );

   }
   if ( (client.classname == "peeper") ) {

      return ( BotfindBot () );

   }
   if ( (client == self.enemy) ) {

      return ( FALSE );

   }
   if ( teamplay ) {

      if ( (self.team == client.team) ) {

         return ( BotfindBot () );

      }

   }
   if ( (client.flags & FL_NOTARGET) ) {

      return ( BotfindBot () );

   }
   if ( !enemyvisible (client) ) {

      return ( BotfindBot () );

   }
   if ( !infrontofbot (client) ) {

      if ( !hearnoise (client) ) {

         return ( BotfindBot () );

      }

   }
   if ( ((self.origin_z > (client.origin_z + 120.000)) || ((self.origin_z + 120.000) < client.origin_z)) ) {

      self.enemy = client;
      if ( RunAway () ) {

         self.enemy = world;
         return ( BotfindBot () );

      }

   }
   if ( (client.items & IT_INVISIBILITY) ) {

      return ( BotfindBot () );

   }
   if ( (self.skil < TRUE) ) {

      len = (random () * MUST_HAVE);
      if ( (len > 25.000) ) {

         return ( FALSE );

      }

   }
   self.enemy = client;
   return ( BotFoundTarget () );

};

void () ai_botstand = {

   if ( BotFindTarget () ) {

      return ;

   }

};

void () ai_botturn = {

   if ( BotFindTarget () ) {

      return ;

   }
   ChangeYaw ();

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

   trn = turn;
   self.ideal_yaw = vectoyaw ((self.enemy.origin - self.origin));
   ChangeYaw ();
   ofs = 90.000;
   dis = dist;
   self.strafeonly = (self.strafeonly - TRUE);
   if ( (self.strafeonly > FALSE) ) {

      trn = NOTURN;

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

void (float dist) ai_botrun = {

   local vector delta;
   local float axis;
   local float rng;
   local float oldrng;
   local float direct;
   local float ang_rint;
   local float ang_floor;
   local float ang_ceil;

   if ( (self.enemy.deadflag != DEAD_NO) ) {

      endEnemy ();
      return ;

   }
   if ( !self.enemy ) {

      endEnemy ();
      return ;

   }
   if ( (self.lefty & GETGOODY) ) {

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

   }
   if ( (self.search_time < time) ) {

      endEnemy ();
      BotFindTarget ();
      return ;

   }
   if ( ((self.lefty & LOCAL_TIME) > MOVETYPE_FLY) ) {

      self.lefty = (self.lefty - (self.lefty & LOCAL_TIME));
      self.lastseenpos = self.goalentity.origin;
      if ( aibot_checkforGoodies (DONT_WANT) ) {

         ai_botgetGoody (dist);
         return ;

      }

   }
   self.lefty = (self.lefty + TRUE);
   if ( RunAway () ) {

      self.lefty = (self.lefty - (self.lefty & LOCAL_TIME));
      self.lastseenpos = self.goalentity.origin;
      if ( aibot_checkforGoodies (DONT_WANT) ) {

         ai_botgetGoody (dist);
         return ;

      }

   }
   enemy_infront = infrontofbot (self.enemy);
   enemy_yaw = vectoyaw ((self.enemy.origin - self.origin));
   if ( !enemy_vis ) {

      aibot_setupchase ();
      Botmovetogoal (dist);
      return ;

   }
   if ( (self.attack_state == AS_MELEE) ) {

      aibot_run_melee ();

   }
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
