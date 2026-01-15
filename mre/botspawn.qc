
void () AddAnotherBot;

void () initBotLevel = {

   local float num;
   local float offset;
   local float i;
   local entity e;
   local string tmp;

   NOISEQUEUE = noisetarget ();
   num = ((serverflags & BOTS) / FL_INWATER);
   serverflags = ((serverflags - (serverflags & BOTS)) - INITLEVEL);
   NUMBOTS = FALSE;
   NUMPATHS = FALSE;
   NUMPATHERS = FALSE;
   offset = TRUE;
   while ( (num > FALSE) ) {

      num = (num - TRUE);
      if ( ((NUMBOTS < MOVETYPE_FLY) && !(serverflags & DEDICATED)) ) {

         skill = ((0.100 * (parm10 & (offset * SVC_FINALE))) / offset);

      }
      offset = (offset * FL_MONSTER);
      AddAnotherBot ();

   }
   if ( (serverflags & TEAMFLAG) ) {

      if ( !teamplay ) {

         serverflags = (serverflags - TEAMFLAG);
         serverflags = (serverflags - (serverflags & TEAMBOTS));
         return ;

      }

   } else {

      if ( teamplay ) {

         serverflags = (serverflags + TEAMFLAG);
         serverflags = (serverflags - (serverflags & TEAMBOTS));
         return ;

      }

   }
   if ( !teamplay ) {

      return ;

   }
   num = ((serverflags & TEAMBOTS) / FL_ITEM);
   if ( (num == FALSE) ) {

      return ;

   }
   e = find (world,classname,"player");
   while ( e ) {

      i = FALSE;
      offset = TRUE;
      while ( (i < num) ) {

         i = (i + TRUE);
         if ( ((i < MOVETYPE_TOSS) && !(serverflags & DEDICATED)) ) {

            skill = ((0.100 * (parm11 & (offset * SVC_FINALE))) / offset);

         }
         offset = (offset * FL_MONSTER);
         addTeamBots (e,TRUE);

      }
      e = find (e,classname,"player");

   }
   if ( (serverflags & DEDICATED) ) {

      serverflags = (serverflags - DEDICATED);

   }

};

void () setBotGravity = {

   local float newmax;
   local float vel;
   local float sk;
   local string tmp;

   GRAVITY = (cvar ("sv_gravity") * 0.100);
   dprint ("Gravity accel is ");
   tmp = ftos (GRAVITY);
   dprint (tmp);
   dprint ("\n");
   newmax = FALSE;
   vel = 270.000;
   MAXJUMP = CONTENT_EMPTY;
   while ( (newmax > MAXJUMP) ) {

      vel = (vel - GRAVITY);
      MAXJUMP = newmax;
      newmax = (newmax + (vel * 0.100));

   }
   MAXJUMP = (MAXJUMP - TRUE);
   dprint ("Max jump height is ");
   tmp = ftos (MAXJUMP);
   dprint (tmp);
   dprint ("\n");
   LEVELJUMPTIME = FALSE;
   vel = 270.000;
   newmax = FALSE;
   while ( (newmax > CONTENT_EMPTY) ) {

      LEVELJUMPTIME = (LEVELJUMPTIME + 0.100);
      vel = (vel - GRAVITY);
      newmax = (newmax + (vel * 0.100));

   }
   LEVELJUMPTIME = (LEVELJUMPTIME - (newmax / vel));
   dprint ("Level jump time is ");
   tmp = ftos (LEVELJUMPTIME);
   dprint (tmp);
   dprint ("\n");
   newmax = FALSE;
   vel = 200.000;
   GRENADEMAXHEIGHT = CONTENT_EMPTY;
   while ( (newmax > GRENADEMAXHEIGHT) ) {

      vel = (vel - GRAVITY);
      GRENADEMAXHEIGHT = newmax;
      newmax = (newmax + (vel * 0.100));

   }
   dprint ("Max grenade height is ");
   tmp = ftos (GRENADEMAXHEIGHT);
   dprint (tmp);
   dprint ("\n");
   INVGRENADELEVELDIST = (((0.100 * FL_SWIM) * (200.000 - GRAVITY)) / GRAVITY);
   INVGRENADELEVELDIST = (TRUE / (INVGRENADELEVELDIST * SEARCH_RADIUS));
   dprint ("inverse grenade level distance is ");
   tmp = ftos (INVGRENADELEVELDIST);
   dprint (tmp);
   dprint ("\n");
   BOTSPEED = (cvar ("sv_maxspeed") / MOVETYPE_BOUNCE);

};

void () PutBotInServer;
float () numplayers;
float (entity e) totalscore;

void () respawnBot = {

   local string m;
   local float n;
   local float o;
   local entity e;

   CopyToBodyQue (self);
   if ( !teamplay ) {

      if ( (serverflags & TEAMBOTS) ) {

         n = (NUMBOTS + numplayers ());
         o = ((serverflags & TEAMBOTS) / FL_ITEM);
         if ( ((o < n) || (self.team != 99.000)) ) {

            self.nextthink = (time + TRUE);
            if ( (self.team == 99.000) ) {

               NUMBOTS = (NUMBOTS - TRUE);

            }
            remove (self.movetarget);
            remove (self.goalentity);
            self.think = SUB_Remove;
            if ( self.pather ) {

               NUMPATHERS = (NUMPATHERS - TRUE);

            }
            if ( (self.team != 99.000) ) {

               m = ": I'm going to find a team server.\n";

            } else {

               if ( (totalscore (self) < FALSE) ) {

                  m = ": I'm tired of getting fragged.  I'm off\n";

               } else {

                  if ( (totalscore (self) > MUST_HAVE) ) {

                     m = ": I'm going to find some real competition\n";

                  } else {

                     m = ": This server's too crowded.  I'm off\n";

                  }

               }

            }
            bprint (self.teamname);
            bprint (self.netname);
            bprint (m);
            bprint (self.teamname);
            bprint (self.netname);
            bprint (" left the game with ");
            m = ftos (self.frags);
            bprint (m);
            bprint (" frags\n");
            return ;

         }

      }

   } else {

      if ( (self.team != 99.000) ) {

         e = find (world,classname,"player");
         while ( e ) {

            if ( (e.team == self.team) ) {

               PutBotInServer ();
               return ;

            }
            e = find (e,classname,"player");

         }
         bprint (self.teamname);
         bprint (self.netname);
         bprint (": Going off to join my team\n");
         bprint (self.teamname);
         bprint (self.netname);
         bprint (" left the game with ");
         m = ftos (self.frags);
         bprint (m);
         bprint (" frags\n");
         return ;

      } else {

         if ( (SKINSMODE == FL_SWIM) ) {

            skinChange (self,15.000);

         }

      }

   }
   PutBotInServer ();

};

void () bot_pain;

void () BotDie;

void () bot_stand1;

void () bot_walk;

void () bot_run;

void () bot_start;

void () dmbot_melee;
entity () botmovetarget;

void () PutBotInServer = {

   local entity spwn;
   local vector spot;
   local string tmp;
   local float aimvar;

   self.classname = "dmbot";
   self.health = MUST_HAVE;
   self.takedamage = DAMAGE_AIM;
   self.solid = SOLID_SLIDEBOX;
   self.movetype = MOVETYPE_STEP;
   self.show_hostile = FALSE;
   self.max_health = MUST_HAVE;
   self.air_finished = (time + SVC_INTERMISSION);
   self.dmg = TRUE;
   self.super_damage_finished = FALSE;
   self.radsuit_finished = FALSE;
   self.invisible_finished = FALSE;
   self.invincible_finished = FALSE;
   self.effects = FALSE;
   self.invincible_time = FALSE;
   self.yaw_speed = (45.000 + (25.000 * self.skil));
   self.lefty = STRAFE_DIR;
   if ( (self.goalentity == world) ) {

      self.goalentity = botmovetarget ();

   }
   self.goalentity.goalentity = world;
   SetNewParms ();
   DecodeLevelParms ();
   W_SetCurrentAmmo ();
   self.search_time = time;
   self.attack_finished = time;
   self.th_pain = bot_pain;
   self.th_die = BotDie;
   self.th_stand = bot_stand1;
   self.th_walk = bot_walk;
   self.th_run = bot_run;
   self.th_melee = dmbot_melee;
   self.th_cache = cacheenemy;
   self.touch = fuck_thud;
   self.think = bot_start;
   self.nextthink = (time + 0.100);
   self.enemy = world;
   self.pathtype = NEVERTARGET;
   self.deadflag = DEAD_NO;
   self.pausetime = FALSE;
   spwn = SelectSpawnPoint ();
   spot = (spwn.origin + '0.000 0.000 1.000');
   self.origin = spot;
   setorigin (self,spot);
   self.angles = spwn.angles;
   self.fixangle = TRUE;
   setmodel (self,"progs/eyes.mdl");
   modelindex_eyes = self.modelindex;
   setmodel (self,"progs/player.mdl");
   modelindex_player = self.modelindex;
   setsize (self,VEC_HULL_MIN,VEC_HULL_MAX);
   if ( (self.movetarget == world) ) {

      NewCarriedPath ();

   } else {

      setorigin (self.movetarget,self.origin);

   }
   self.movetarget.movetarget = world;
   clearCache (self);
   if ( self.pather ) {

      NUMPATHERS = (NUMPATHERS - TRUE);
      self.pather = FALSE;

   }
   if ( (NUMPATHERS < MAXPATHERS) ) {

      self.pather = TRUE;
      NUMPATHERS = (NUMPATHERS + TRUE);

   }
   self.view_ofs = '0.000 0.000 22.000';
   makevectors (self.angles);
   spawn_tfog ((self.origin + (v_forward * KINDA_WANT)));
   spawn_tdeath (self.origin,self);
   if ( (BOTSPEED < FL_MONSTER) ) {

      dprint ("Feeling kind of slow today (SV_MAXSPEED = ");
      tmp = ftos ((BOTSPEED * MOVETYPE_BOUNCE));
      dprint (tmp);
      dprint ("\n");

   }
   aimvar = cvar ("sv_aim");
   if ( (aimvar != 0.930) ) {

      dprint ("Seems like sv_aim isn't 0.93\n");

   }

};

void () SpawnNewBot = {

   local string tmp;

   PutBotInServer ();
   bprint (self.teamname);
   bprint (self.netname);
   tmp = ftos (self.skil);
   bprint (" (skill ");
   bprint (tmp);
   bprint (") entered the game.\n");

};
entity () AddBot = {

   local entity newbot;
   local entity oldself;
   local string mycolor;
   local float plycolor;

   newbot = spawn ();
   oldself = self;
   self = newbot;
   self.think = SpawnNewBot;
   self.nextthink = (time + (12.000 * random ()));
   self.skil = skill;
   if ( (self.skil < FALSE) ) {

      self.skil = FALSE;

   } else {

      if ( (self.skil > MOVETYPE_WALK) ) {

         self.skil = MOVETYPE_WALK;

      }

   }
   initscore ();
   self = oldself;
   return ( newbot );

};
float () numplayers = {

   local entity e;
   local float n;

   n = FALSE;
   e = find (world,classname,"player");
   while ( e ) {

      n = (n + TRUE);
      e = find (e,classname,"player");

   }
   return ( n );

};

void () AddAnotherBot = {

   local entity newbot;
   local entity tmp;
   local float n;
   local string st;

   self.impulse = FALSE;
   if ( !teamplay ) {

      if ( (serverflags & TEAMBOTS) ) {

         n = (NUMBOTS + numplayers ());
         if ( ((serverflags & TEAMBOTS) < n) ) {

            dprint ("Can't add bot - exceeds bound\n");
            return ;

         }

      }

   }



   newbot = AddBot ();
newbot.id = FindGood();
   // Guard: if no scoreboard slots available, remove bot and abort
   if ( (newbot.id == -1.000) ) {

      bprint ("Server full - cannot add bot\n");
      remove (newbot);
      NUMBOTS = (NUMBOTS - TRUE);
      return ;

   }
   // Guard: slot must be < fMaxClients (maxplayers) for network protocol
   if ( (newbot.id >= fMaxClients) ) {

      bprint ("Server full - max players reached\n");
      MakeGood (newbot.id);
      remove (newbot);
      NUMBOTS = (NUMBOTS - TRUE);
      return ;

   }
newbot.colormap = newbot.id + 1;
   newbot.colormap = FALSE;
   if ( teamplay ) {

      skinChange (newbot,15.000);

   } else {

      if ( (SKINSMODE == TRUE) ) {

         skinChange (newbot,NUMBOTS);

      } else {

         if ( (SKINSMODE == FL_SWIM) ) {

            st = ftos (((newbot.skil & MOVETYPE_WALK) + TRUE));
            dprint (st);
            dprint ("= skil skin\n");
            skinChange (newbot,((newbot.skil & MOVETYPE_WALK) + TRUE));

         }

      }

   }
   newbot.team = 99.000;
   if ( NAMEBOTS ) {

      newbot.teamname = self.netname;

   } else {

      if ( (newbot.skil < TRUE) ) {

         newbot.teamname = "";

      } else {

         if ( (newbot.skil < FL_SWIM) ) {

            newbot.teamname = "";

         } else {

            if ( (newbot.skil < MOVETYPE_WALK) ) {

               newbot.teamname = "";

            } else {

               newbot.teamname = "";

            }

         }

      }

   }
   NUMBOTS = (NUMBOTS + TRUE);
   if ( (NUMBOTS == TRUE) ) {

      newbot.nextthink = (time + 0.100);

   }
   if ( (NUMBOTS < FL_INWATER) ) {

      serverflags = ((serverflags - (serverflags & BOTS)) + (FL_INWATER * NUMBOTS));

   }
   if ( (NUMBOTS == TRUE) ) {

      newbot.netname = "Cheater";

   } else {

      if ( (NUMBOTS == FL_SWIM) ) {

         newbot.netname = "Dumbass";

      } else {

         if ( (NUMBOTS == MOVETYPE_WALK) ) {

            newbot.netname = "Weenie";

         } else {

            if ( (NUMBOTS == MOVETYPE_STEP) ) {

               newbot.netname = "Doofus";

            } else {

               if ( (NUMBOTS == MOVETYPE_FLY) ) {

                  newbot.netname = "Reject";

               } else {

                  if ( (NUMBOTS == MOVETYPE_TOSS) ) {

                     newbot.netname = "6";

                  } else {

                     if ( (NUMBOTS == MOVETYPE_PUSH) ) {

                        newbot.netname = "7";

                     } else {

                        if ( (NUMBOTS == FL_CLIENT) ) {

                           newbot.netname = "8";

                        } else {

                           if ( (NUMBOTS == MOVETYPE_FLYMISSILE) ) {

                              newbot.netname = "9";

                           } else {

                              if ( (NUMBOTS == MOVETYPE_BOUNCE) ) {

                                 newbot.netname = "10";

                              } else {

                                 if ( (NUMBOTS == MOVETYPE_BOUNCEMISSILE) ) {

                                    newbot.netname = "11";

                                 } else {

                                    if ( (NUMBOTS == 12.000) ) {

                                       newbot.netname = "12";

                                    } else {

                                       if ( (NUMBOTS == 13.000) ) {

                                          newbot.netname = "13";

                                       } else {

                                          if ( (NUMBOTS == 14.000) ) {

                                             newbot.netname = "14";

                                          } else {

                                             if ( (NUMBOTS == 15.000) ) {

                                                newbot.netname = "15";

                                             }

                                          }

                                       }

                                    }

                                 }

                              }

                           }

                        }

                     }

                  }

               }

            }

         }

      }

   }
 local float r, top, bottom;
   r = random();
   top = (random () * 10);
   top = ceil(top);
   if (top == 10)
      {
       if (r > 0.9) top = 10;
       else if (r > 0.8) top = 11;
       else if (r < 0.4) top = 12;
       else top = 13;
      }
   bottom = (random () * 10);
   bottom = ceil(bottom);
   if (bottom == 10)
      {
       if (r > 0.9) bottom = 10;
       else if (r > 0.8) bottom = 11;
       else if (r < 0.4) bottom = 12;
       else bottom = 13;
      }


WriteByte( MSG_ALL, MSG_UPDATENAME );
WriteByte( MSG_ALL, newbot.id );
WriteString( MSG_ALL, newbot.netname );

WriteByte( MSG_ALL, MSG_UPDATECOLORS );
WriteByte( MSG_ALL, newbot.id );
WriteByte( MSG_ALL, top * 16 + bottom );

WriteByte( MSG_ALL, MSG_UPDATEFRAGS );
WriteByte( MSG_ALL, newbot.id );
WriteShort( MSG_ALL, newbot.frags );

};

void (entity ply, float n) addTeamBots = {

   local entity newbot;
   local entity tmp;
   local float i;

   i = n;
   while ( (i > FALSE) ) {

      newbot = AddBot ();
      newbot.colormap = ply.colormap;
      newbot.team = ply.team;
      newbot.teamname = ply.netname;
      skinChange (newbot,ply.skin);
      if ( (newbot.skil < TRUE) ) {

         newbot.netname = "";

      } else {

         if ( (newbot.skil < FL_SWIM) ) {

            newbot.netname = "1Bot";

         } else {

            if ( (newbot.skil < MOVETYPE_WALK) ) {

               newbot.netname = "2Bot";

            } else {

               newbot.netname = "3Bot";

            }

         }

      }
      i = (i - TRUE);

   }

};

void (entity ply, float n) removeTeamBots = {

   local float i;
   local entity e;

   i = n;
   e = find (world,classname,"dmbot");
   while ( (i > FALSE) ) {

      while ( ((e != world) && (e.team != ply.team)) ) {

         e = find (e,classname,"dmbot");

      }
      if ( !e ) {

         return ;

      }
      if ( e.pather ) {

         NUMPATHERS = (NUMPATHERS - TRUE);

      }
      remove (e.movetarget);
      remove (e.goalentity);
      remove (e);
      i = (i - TRUE);

   }

};

void () removeAllBots = {

   local entity e;

   e = find (world,classname,"dmbot");
   while ( e ) {

      if ( !e ) {

         return ;

      }
      if ( e.pather ) {

         NUMPATHERS = (NUMPATHERS - TRUE);

      }
      remove (e.movetarget);
      remove (e.goalentity);
      remove (e);
      e = find (e,classname,"dmbot");

   }
   NUMBOTS = FALSE;
   dprint ("All bots removed.\n");

};

void (float n) SetMaxBots = {

   local float t;
   local string tmp;

   self.impulse = FALSE;
   if ( (serverflags & TEAMFLAG) ) {

      dprint ("Entering bounded deathmatch mode\n");
      serverflags = ((serverflags - TEAMFLAG) - (serverflags & TEAMBOTS));

   }
   dprint ("Max bots + players set to ");
   tmp = ftos (n);
   dprint (tmp);
   dprint ("\n");
   serverflags = ((serverflags - (serverflags & TEAMBOTS)) + (n * FL_ITEM));
   t = numplayers ();
   while ( ((NUMBOTS + t) < n) ) {

      AddAnotherBot ();

   }

};

void (float n) SetTeamBots = {

   local float t;
   local entity e;
   local string tmp;

   self.impulse = FALSE;
   if ( !(serverflags & TEAMFLAG) ) {

      dprint ("Entering bot team mode\n");
      serverflags = ((serverflags + TEAMFLAG) - (serverflags & TEAMBOTS));

   }
   dprint ("Bots per player team set to ");
   tmp = ftos (n);
   dprint (tmp);
   dprint ("\n");
   t = ((serverflags & TEAMBOTS) / FL_ITEM);
   serverflags = ((serverflags - (serverflags & TEAMBOTS)) + (n * FL_ITEM));
   if ( (t < n) ) {

      e = find (world,classname,"player");
      t = (n - t);
      while ( e ) {

         addTeamBots (e,t);
         e = find (e,classname,"player");

      }
      return ;

   }
   if ( (t > n) ) {

      e = find (world,classname,"player");
      while ( e ) {

         t = (t - n);
         removeTeamBots (e,t);
         e = find (e,classname,"player");

      }
      return ;

   }

};

void () UpdateTeamColors = {

   local entity e;

   e = find (world,classname,"dmbot");
   while ( e ) {

      if ( (e.colormap == self.colormap) ) {

         e.team = self.team;

      }
      e = find (e,classname,"dmbot");

   }

};
