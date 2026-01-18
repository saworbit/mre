 float fActiveClients;
.float fClientNo;
.float id;

// Forward declaration for Darwin Update (defined in botroute.qc)
void (entity node, float amount) ModulateNodeWeight;



// Returns 0-indexed client slot (0-15), or -1 if full
// Changed from 1-indexed to 0-indexed to match Quake protocol expectations
float () FindGood =
{
 if (!(fActiveClients & 1))
    { fActiveClients = fActiveClients | 1; return 0; }

 else if (!(fActiveClients & 2))
    { fActiveClients = fActiveClients | 2; return 1; }

 else if (!(fActiveClients & 4))
    { fActiveClients = fActiveClients | 4; return 2; }

 else if (!(fActiveClients & 8))
    { fActiveClients = fActiveClients | 8; return 3; }

 else if (!(fActiveClients & 16))
    { fActiveClients = fActiveClients | 16; return 4; }

 else if (!(fActiveClients & 32))
    { fActiveClients = fActiveClients | 32; return 5; }

 else if (!(fActiveClients & 64))
    { fActiveClients = fActiveClients | 64; return 6; }

 else if (!(fActiveClients & 128))
    { fActiveClients = fActiveClients | 128; return 7; }

 else if (!(fActiveClients & 256))
    { fActiveClients = fActiveClients | 256; return 8; }

 else if (!(fActiveClients & 512))
    { fActiveClients = fActiveClients | 512; return 9; }

 else if (!(fActiveClients & 1024))
    { fActiveClients = fActiveClients | 1024; return 10; }

 else if (!(fActiveClients & 2048))
    { fActiveClients = fActiveClients | 2048; return 11; }

 else if (!(fActiveClients & 4096))
    { fActiveClients = fActiveClients | 4096; return 12; }

 else if (!(fActiveClients & 8192))
    { fActiveClients = fActiveClients | 8192; return 13; }

 else if (!(fActiveClients & 16384))
    { fActiveClients = fActiveClients | 16384; return 14; }

 else if (!(fActiveClients & 32768))
    { fActiveClients = fActiveClients | 32768; return 15; }

 else return -1;
};   

// Clears a 0-indexed client slot (was 1-indexed, now 0-indexed to match FindGood)
void(float abba) MakeGood =
{
  local float ackbar;

  ackbar = 1;
  // abba is now 0-indexed, so don't subtract 1
  while (abba > 0)
        {
         ackbar = ackbar * 2;
         abba = abba - 1;
        }

 fActiveClients = fActiveClients - (fActiveClients & ackbar);
};

void(entity object) Update_Frags =
{
 WriteByte( MSG_ALL, MSG_UPDATEFRAGS );
 WriteByte( MSG_ALL, object.id );
 WriteShort( MSG_ALL, object.frags );
};

void (entity attacker, float damage) player_pain;

void () player_stand1;

void (vector org) spawn_tfog;

void (vector org, entity death_owner) spawn_tdeath;

void (entity killer, entity killed) countkill;

void () initscore;

void (entity ply, float n) removeTeamBots;

void (entity ply, float n) addTeamBots;
float modelindex_eyes /* = 0.000 */;
float modelindex_player /* = 0.000 */;
float intermission_running /* = 0.000 */;
float intermission_exittime /* = 0.000 */;

void () info_intermission = {


};

void () SetChangeParms = {

   local float offset;
   local float toffset;
   local float team1;
   local float nb;
   local float nt;
   local entity e;

   self.items = (self.items - (self.items & (((((IT_KEY1 | IT_KEY2) | IT_INVISIBILITY) | IT_INVULNERABILITY) | IT_SUIT) | IT_QUAD)));
   if ( (self.health > MUST_HAVE) ) {

      self.health = MUST_HAVE;

   }
   if ( (self.health < 50.000) ) {

      self.health = 50.000;

   }
   parm1 = self.items;
   parm2 = self.health;
   parm3 = self.armorvalue;
   if ( (self.ammo_shells < 25.000) ) {

      parm4 = 25.000;

   } else {

      parm4 = self.ammo_shells;

   }
   parm5 = self.ammo_nails;
   parm6 = self.ammo_rockets;
   parm7 = self.ammo_cells;
   parm8 = self.weapon;
   parm9 = (self.armortype * MUST_HAVE);
   if ( SKINSMODE ) {

      parm4 = ((parm4 + (self.skin * FL_ONGROUND)) + (IT_ARMOR2 * SKINSMODE));

   }
   e = find (world,classname,"dmbot");
   offset = TRUE;
   toffset = TRUE;
   parm10 = FALSE;
   parm11 = FALSE;
   team1 = MUST_HAVE;
   nb = FALSE;
   nt = FALSE;
   while ( e ) {

      if ( (e.team == 99.000) ) {

         nb = (nb + TRUE);
         if ( (nb < MOVETYPE_TOSS) ) {

            parm10 = (parm10 + (((offset * e.skil) * MOVETYPE_BOUNCE) & (offset * SVC_FINALE)));
            offset = (offset * FL_MONSTER);

         }

      } else {

         if ( (team1 == MUST_HAVE) ) {

            team1 = e.team;

         }
         if ( (e.team == team1) ) {

            nt = (nt + TRUE);
            if ( (nt < MOVETYPE_TOSS) ) {

               parm11 = (parm11 + (((toffset * e.skil) * MOVETYPE_BOUNCE) & (toffset * SVC_FINALE)));
               toffset = (toffset * FL_MONSTER);

            }

         }

      }
      e = find (e,classname,"dmbot");

   }

};

void () SetNewParms = {

   parm1 = (IT_SHOTGUN | IT_AXE);
   parm2 = MUST_HAVE;
   parm3 = FALSE;
   parm4 = 25.000;
   parm5 = FALSE;
   parm6 = FALSE;
   parm7 = FALSE;
   parm8 = TRUE;
   parm9 = FALSE;

};

void () DecodeLevelParms = {

   local float skinno;

   if ( (parm4 > 511.000) ) {

      SKINSMODE = ((parm4 & 49152.000) / IT_ARMOR2);
      skinno = (parm4 & 7680.000);
      parm4 = (parm4 & 511.000);
      skinChange (self,skinno);

   }
   self.items = parm1;
   self.health = parm2;
   self.armorvalue = parm3;
   self.ammo_shells = parm4;
   self.ammo_nails = parm5;
   self.ammo_rockets = parm6;
   self.ammo_cells = parm7;
   self.weapon = parm8;
   self.armortype = (parm9 * 0.010);

};
entity () FindIntermission = {

   local entity spot;
   local float cyc;

   spot = find (world,classname,"info_intermission");
   if ( spot ) {

      cyc = (random () * MOVETYPE_STEP);
      while ( (cyc > TRUE) ) {

         spot = find (spot,classname,"info_intermission");
         if ( !spot ) {

            spot = find (spot,classname,"info_intermission");

         }
         cyc = (cyc - TRUE);

      }
      return ( spot );

   }
   spot = find (world,classname,"info_player_start");
   if ( spot ) {

      return ( spot );

   }
   spot = find (world,classname,"testplayerstart");
   if ( spot ) {

      return ( spot );

   }
   objerror ("FindIntermission: no spot");
   return ( world );

};
string nextmap /* = "" */;

void () GotoNextMap = {

   if ( cvar ("samelevel") ) {

      changelevel (mapname);

   } else {

      changelevel (nextmap);

   }

};

void () ExitIntermission = {

   if ( deathmatch ) {

      GotoNextMap ();
      return ;

   }
   intermission_exittime = (time + TRUE);
   intermission_running = (intermission_running + TRUE);
   if ( (intermission_running == FL_SWIM) ) {

      if ( (world.model == "maps/e1m7.bsp") ) {

         WriteByte (MSG_ALL,SVC_CDTRACK);
         WriteByte (MSG_ALL,FL_SWIM);
         WriteByte (MSG_ALL,MOVETYPE_WALK);
         if ( !cvar ("registered") ) {

            WriteByte (MSG_ALL,SVC_FINALE);
            WriteString (MSG_ALL,"As the corpse of the monstrous entity\nChthon sinks back into the lava whence\nit rose, you grip the Rune of Earth\nMagic tightly. Now that you have\nconquered the Dimension of the Doomed,\nrealm of Earth Magic, you are ready to\ncomplete your task in...");

         } else {

            WriteByte (MSG_ALL,SVC_FINALE);
            WriteString (MSG_ALL,"As the corpse of the monstrous entity\nChthon sinks back into the lava whence\nit rose, you grip the Rune of Earth\nMagic tightly. Now that you have\nconquered the Dimension of the Doomed,\nrealm of Earth Magic, you are ready to\ncomplete your task. A...");

         }
         return ;

      } else {

         if ( (world.model == "maps/e2m6.bsp") ) {

            WriteByte (MSG_ALL,SVC_CDTRACK);
            WriteByte (MSG_ALL,FL_SWIM);
            WriteByte (MSG_ALL,MOVETYPE_WALK);
            WriteByte (MSG_ALL,SVC_FINALE);
            WriteString (MSG_ALL,"The Rune of Black Magic throbs evilly in\nyour hand and whispers dark thoughts\ninto your brain. You learn the inmost\nlore of the Hell-Mother; Shub-Niggurath!\nYou now know that she is behind all the\nterrible plotting which has led to so\nmuch death...");
            return ;

         } else {

            if ( (world.model == "maps/e3m6.bsp") ) {

               WriteByte (MSG_ALL,SVC_CDTRACK);
               WriteByte (MSG_ALL,FL_SWIM);
               WriteByte (MSG_ALL,MOVETYPE_WALK);
               WriteByte (MSG_ALL,SVC_FINALE);
               WriteString (MSG_ALL,"The charred viscera of diabolic horrors\nbubble viscously as you seize the Rune\nof Hell Magic. Its heat scorches your\nhand, and its terrible secrets blight\nyour mind. Gathering the shreds of your\ncourage, you shake the devil's shackles\nfrom your ...");
               return ;

            } else {

               if ( (world.model == "maps/e4m7.bsp") ) {

                  WriteByte (MSG_ALL,SVC_CDTRACK);
                  WriteByte (MSG_ALL,FL_SWIM);
                  WriteByte (MSG_ALL,MOVETYPE_WALK);
                  WriteByte (MSG_ALL,SVC_FINALE);
                  WriteString (MSG_ALL,"Despite the awful might of the Elder\nWorld, you have achieved the Rune of\nElder Magic, capstone of all types of\narcane wisdom. Beyond good and evil,\nbeyond life and death, the Rune\npulsates, heavy with import. Patient and\npotent, the Elder Being...");
                  return ;

               }

            }

         }

      }
      GotoNextMap ();

   }
   if ( (intermission_running == MOVETYPE_WALK) ) {

      if ( !cvar ("registered") ) {

         WriteByte (MSG_ALL,SVC_SELLSCREEN);
         return ;

      }
      if ( ((serverflags & 15.000) == 15.000) ) {

         WriteByte (MSG_ALL,SVC_FINALE);
         WriteString (MSG_ALL,"Now, you have all four Runes. You sense\ntremendous invisible forces moving to\nunseal ancient barriers. Shub-Niggurath\nhad hoped to use the Runes Herself to\nclear off the Earth, but now instead,\nyou will use them to enter her home and\nconfront he...");
         return ;

      }

   }
   GotoNextMap ();

};

void () IntermissionThink = {

   if ( (time < intermission_exittime) ) {

      return ;

   }
   if ( ((!self.button0 && !self.button1) && !self.button2) ) {

      return ;

   }
   ExitIntermission ();

};

void () execute_changelevel = {

   local entity pos;

   intermission_running = TRUE;
   if ( deathmatch ) {

      intermission_exittime = (time + MOVETYPE_FLY);

   } else {

      intermission_exittime = (time + FL_SWIM);

   }
   WriteByte (MSG_ALL,SVC_CDTRACK);
   WriteByte (MSG_ALL,MOVETYPE_WALK);
   WriteByte (MSG_ALL,MOVETYPE_WALK);
   pos = FindIntermission ();
   other = find (world,classname,"player");
   while ( (other != world) ) {

      other.view_ofs = VEC_ORIGIN;
      other.v_angle = pos.mangle;
      other.angles = pos.mangle;
      other.fixangle = TRUE;
      other.nextthink = (time + 0.500);
      other.takedamage = DAMAGE_NO;
      other.solid = SOLID_NOT;
      other.movetype = MOVETYPE_NONE;
      other.modelindex = FALSE;
      setorigin (other,pos.origin);
      other = find (other,classname,"player");

   }
   WriteByte (MSG_ALL,SVC_INTERMISSION);
   serverflags = (serverflags | INITLEVEL);

};

void () changelevel_touch = {

   if ( (other.classname != "player") ) {

      return ;

   }
   if ( cvar ("noexit") ) {

      T_Damage (other,self,self,50000.000);
      return ;

   }
   bprint (other.teamname);
   bprint (other.netname);
   bprint (" exited the level\n");
   nextmap = self.map;
   SUB_UseTargets ();
   if ( ((self.spawnflags & TRUE) && (deathmatch == FALSE)) ) {

      GotoNextMap ();
      return ;

   }
   self.touch = SUB_Null;
   self.think = execute_changelevel;
   self.nextthink = (time + 0.100);

};

void () trigger_changelevel = {

   if ( !self.map ) {

      objerror ("chagnelevel trigger doesn't have map");

   }
   InitTrigger ();
   self.touch = changelevel_touch;

};

void () set_suicide_frame;

void () respawn = {

   if ( coop ) {

      CopyToBodyQue (self);
      setspawnparms (self);
      PutClientInServer ();

   } else {

      if ( deathmatch ) {

         CopyToBodyQue (self);
         SetNewParms ();
         PutClientInServer ();

      } else {

         localcmd ("restart\n");

      }

   }

};

void () ClientKill = {

   bprint (self.netname);
   bprint (" suicides\n");
   set_suicide_frame ();
   self.modelindex = modelindex_player;
   self.frags = (self.frags - FL_SWIM);
   countkill (self,self);
   respawn ();

};
float (vector v) CheckSpawnPoint = {

   return ( FALSE );

};
entity () SelectSpawnPoint = {

   local entity spot;
   local float rnd;

   spot = find (world,classname,"testplayerstart");
   if ( spot ) {

      return ( spot );

   }
   if ( coop ) {

      lastspawn = find (lastspawn,classname,"info_player_coop");
      if ( (lastspawn == world) ) {

         lastspawn = find (lastspawn,classname,"info_player_start");

      }
      if ( (lastspawn != world) ) {

         return ( lastspawn );

      }

   } else {

      if ( deathmatch ) {

         lastspawn = find (lastspawn,classname,"info_player_deathmatch");
         rnd = random ();
         if ( (rnd > 0.330) ) {

            lastspawn = find (lastspawn,classname,"info_player_deathmatch");

         }
         if ( (rnd > 0.660) ) {

            lastspawn = find (lastspawn,classname,"info_player_deathmatch");

         }
         if ( (lastspawn == world) ) {

            lastspawn = find (lastspawn,classname,"info_player_deathmatch");

         }
         if ( (lastspawn != world) ) {

            return ( lastspawn );

         }

      }

   }
   if ( serverflags ) {

      spot = find (world,classname,"info_player_start2");
      if ( spot ) {

         return ( spot );

      }

   }
   spot = find (world,classname,"info_player_start");
   if ( !spot ) {

      error ("PutClientInServer: no info_player_start on level");

   }
   return ( spot );

};

void () PlayerDie;

void () PutClientInServer = {

   local entity spot;
   floaterDisable (self);
   local float dedflags;

   
   self.classname = "player";
   self.health = MUST_HAVE;
   self.takedamage = DAMAGE_AIM;
   self.solid = SOLID_SLIDEBOX;
   self.movetype = MOVETYPE_WALK;
   self.show_hostile = FALSE;
   self.max_health = MUST_HAVE;
   self.flags = FL_CLIENT;
   self.air_finished = (time + 12.000);
   self.dmg = FL_SWIM;
   self.super_damage_finished = FALSE;
   self.radsuit_finished = FALSE;
   self.invisible_finished = FALSE;
   self.invincible_finished = FALSE;
   self.effects = FALSE;
   self.invincible_time = FALSE;
   DecodeLevelParms ();
   W_SetCurrentAmmo ();
    if ( self.aflag ) {

    CCamChasePlayer ();

    }
   
  
   self.attack_finished = time;
   self.th_pain = player_pain;
   self.th_die = PlayerDie;
   self.th_cache = cacheenemy;
   self.deadflag = DEAD_NO;
   self.pausetime = FALSE;
   spot = SelectSpawnPoint ();
   self.origin = (spot.origin + '0.000 0.000 1.000');
   self.angles = spot.angles;
   self.fixangle = TRUE;
   setmodel (self,"progs/eyes.mdl");
   modelindex_eyes = self.modelindex;
   setmodel (self,"progs/player.mdl");
   modelindex_player = self.modelindex;
   setsize (self,VEC_HULL_MIN,VEC_HULL_MAX);
   self.view_ofs = '0.000 0.000 22.000';
   self.old_waterlevel = self.waterlevel;
   if ( (self.movetarget == world) ) {

      NewCarriedPath ();

   }
   setorigin (self.movetarget,self.origin);
   self.movetarget.movetarget = world;
   self.pathtype = NEVERTARGET;
   if ( !self.pather ) {

      NUMPATHERS = (NUMPATHERS + TRUE);

   }
   self.pather = TRUE;
   player_stand1 ();
   if ( (deathmatch || coop) ) {

      makevectors (self.angles);
      spawn_tfog ((self.origin + (v_forward * KINDA_WANT)));

   }
   spawn_tdeath (self.origin,self);
   dedflags = cvar ("temp1");
   if ( (dedflags & DEDICATED) ) {

      serverflags = (dedflags | INITLEVEL);
      cvar_set ("temp1","0");

   }
   if ( (serverflags & INITLEVEL) ) {

      initBotLevel ();

   }

};

void () info_player_start = {


};

void () info_player_start2 = {


};

void () testplayerstart = {


};

void () info_player_deathmatch = {


};

void () info_player_coop = {


};

void (entity c) PrintClientScore = {

   if ( ((c.frags > -10.000) && (c.frags < FALSE)) ) {

      bprint (" ");

   } else {

      if ( (c.frags >= FALSE) ) {

         if ( (c.frags < MUST_HAVE) ) {

            bprint (" ");

         }
         if ( (c.frags < MOVETYPE_BOUNCE) ) {

            bprint (" ");

         }

      }

   }

};

void () DumpScore = {

   local entity e;
   local entity sort;
   local entity walk;

   if ( world.chain ) {

      error ("DumpScore: world.chain is set");

   }
   e = find (world,classname,"player");
   sort = world;
   while ( e ) {

      if ( !sort ) {

         sort = e;
         e.chain = world;

      } else {

         if ( (e.frags > sort.frags) ) {

            e.chain = sort;
            sort = e;

         } else {

            walk = sort;
            do {

               if ( !walk.chain ) {

                  e.chain = world;
                  walk.chain = e;

               } else {

                  if ( (walk.chain.frags < e.frags) ) {

                     e.chain = walk.chain;
                     walk.chain = e;

                  } else {

                     walk = walk.chain;

                  }

               }

            } while ( (walk.chain != e) );

         }

      }
      e = find (e,classname,"player");

   }
   bprint ("\n");
   while ( sort ) {

      PrintClientScore (sort);
      sort = sort.chain;

   }
   bprint ("\n");

};

void () NextLevel = {

   local entity o;

   o = find (world,classname,"trigger_changelevel");
   if ( (!o || (mapname == "start")) ) {

      o = spawn ();
      o.map = mapname;

   }
   nextmap = o.map;
   if ( (o.nextthink < time) ) {

      o.think = execute_changelevel;
      o.nextthink = (time + 0.100);

   }

};

void () CheckRules = {

   local float timelimit;
   local float fraglimit;

   if ( gameover ) {

      return ;

   }
   timelimit = (cvar ("timelimit") * 60.000);
   fraglimit = cvar ("fraglimit");
   if ( (timelimit && (time >= timelimit)) ) {

      NextLevel ();
      return ;

   }
   if ( (fraglimit && (self.frags >= fraglimit)) ) {

      NextLevel ();
      return ;

   }

};

void () PlayerDeathThink = {

   local float forward;

   if ( (self.flags & FL_ONGROUND) ) {

      forward = vlen (self.velocity);
      forward = (forward - KINDA_WANT);
      if ( (forward <= FALSE) ) {

         self.velocity = VEC_ORIGIN;

      } else {

         self.velocity = (forward * normalize (self.velocity));

      }

   }
   if ( (self.deadflag == DEAD_DEAD) ) {

      if ( ((self.button2 || self.button1) || self.button0) ) {

         return ;

      }
      self.deadflag = DEAD_RESPAWNABLE;
      return ;

   }
   if ( ((!self.button2 && !self.button1) && !self.button0) ) {

      return ;

   }
   self.button0 = FALSE;
   self.button1 = FALSE;
   self.button2 = FALSE;
   respawn ();

};

void () PlayerJump = {

   if ( (self.flags & FL_WATERJUMP) ) {

      return ;

   }
   if ( (self.waterlevel >= FL_SWIM) ) {

      if ( (self.watertype == CONTENT_WATER) ) {

         self.velocity_z = MUST_HAVE;

      } else {

         if ( (self.watertype == CONTENT_SLIME) ) {

            self.velocity_z = 80.000;

         } else {

            self.velocity_z = 50.000;

         }

      }
      if ( (self.swim_flag < time) ) {

         self.swim_flag = (time + TRUE);
         if ( (random () < 0.500) ) {

            sound (self,CHAN_BODY,"misc/water1.wav",TRUE,ATTN_NORM);

         } else {

            sound (self,CHAN_BODY,"misc/water2.wav",TRUE,ATTN_NORM);

         }

      }
      return ;

   }
   if ( !(self.flags & FL_ONGROUND) ) {

      return ;

   }
   if ( !(self.flags & FL_JUMPRELEASED) ) {

      return ;

   }
   self.flags = (self.flags - (self.flags & FL_JUMPRELEASED));
   self.flags = (self.flags - FL_ONGROUND);
   self.button2 = FALSE;
   sound (self,CHAN_BODY,"player/plyrjmp8.wav",TRUE,ATTN_NORM);
   self.velocity_z = (self.velocity_z + 270.000);
    
};
.float dmgtime;

void () WaterMove = {

   if ( (self.movetype == MOVETYPE_NOCLIP) ) {

      return ;

   }
   if ( (self.health <= FALSE) ) {

      return ;

   }
   if ( (self.waterlevel != MOVETYPE_WALK) ) {

      if ( (self.air_finished < time) ) {

         sound (self,CHAN_VOICE,"player/gasp2.wav",TRUE,ATTN_NORM);

      } else {

         if ( (self.air_finished < (time + MOVETYPE_FLYMISSILE)) ) {

            sound (self,CHAN_VOICE,"player/gasp1.wav",TRUE,ATTN_NORM);

         }

      }
      self.air_finished = (time + 12.000);
      self.dmg = FL_SWIM;

   } else {

      if ( (self.air_finished < time) ) {

         if ( (self.pain_finished < time) ) {

            self.dmg = (self.dmg + FL_SWIM);
            if ( (self.dmg > 15.000) ) {

               self.dmg = MOVETYPE_BOUNCE;

            }
            T_Damage (self,world,world,self.dmg);
            self.pain_finished = (time + TRUE);

         }

      }

   }
   if ( !self.waterlevel ) {

      if ( (self.flags & FL_INWATER) ) {

         sound (self,CHAN_BODY,"misc/outwater.wav",TRUE,ATTN_NORM);
         self.flags = (self.flags - FL_INWATER);

      }
      return ;

   }
   if ( (self.watertype == CONTENT_LAVA) ) {

      if ( (self.dmgtime < time) ) {

         if ( (self.radsuit_finished > time) ) {

            self.dmgtime = (time + TRUE);

         } else {

            self.dmgtime = (time + 0.200);

         }
         T_Damage (self,world,world,(MOVETYPE_BOUNCE * self.waterlevel));

      }

   } else {

      if ( (self.watertype == CONTENT_SLIME) ) {

         if ( ((self.dmgtime < time) && (self.radsuit_finished < time)) ) {

            self.dmgtime = (time + TRUE);
            T_Damage (self,world,world,(MOVETYPE_STEP * self.waterlevel));

         }

      }

   }
   if ( !(self.flags & FL_INWATER) ) {

      if ( (self.watertype == CONTENT_LAVA) ) {

         sound (self,CHAN_BODY,"player/inlava.wav",TRUE,ATTN_NORM);

      }
      if ( (self.watertype == CONTENT_WATER) ) {

         sound (self,CHAN_BODY,"player/inh2o.wav",TRUE,ATTN_NORM);

      }
      if ( (self.watertype == CONTENT_SLIME) ) {

         sound (self,CHAN_BODY,"player/slimbrn2.wav",TRUE,ATTN_NORM);

      }
      self.flags = (self.flags + FL_INWATER);
      self.dmgtime = FALSE;

   }
   if ( !(self.flags & FL_WATERJUMP) ) {

      self.velocity = (self.velocity - (((0.800 * self.waterlevel) * frametime) * self.velocity));

   }

};

void () CheckWaterJump = {

   local vector start;
   local vector end;

   makevectors (self.angles);
   start = self.origin;
   start_z = (start_z + FL_CLIENT);
   v_forward_z = FALSE;
   normalize (v_forward);
   end = (start + (v_forward * 24.000));
   traceline (start,end,TRUE,self);
   if ( (trace_fraction < TRUE) ) {

      start_z = ((start_z + self.maxs_z) - FL_CLIENT);
      end = (start + (v_forward * 24.000));
      self.movedir = (trace_plane_normal * -50.000);
      traceline (start,end,TRUE,self);
      if ( (trace_fraction == TRUE) ) {

         self.flags = (self.flags | FL_WATERJUMP);
         self.velocity_z = 225.000;
         self.flags = (self.flags - (self.flags & FL_JUMPRELEASED));
         self.teleport_time = (time + FL_SWIM);
         return ;

      }

   }

};

void () PlayerPreThink = {

   floaterPreThink();

   if ( intermission_running ) {

      IntermissionThink ();
      return ;

   }
   if ( (self.view_ofs ==  '0 0 0') ) {

      return ;

}

 if ( self.aflag ) {

    CCamChasePlayer ();

   }

   makevectors (self.v_angle);
   CheckRules ();
   WaterMove ();
   if ( (self.waterlevel == FL_SWIM) ) {

      CheckWaterJump ();

   }
   if ( (self.deadflag >= DEAD_DEAD) ) {

      PlayerDeathThink ();
      return ;

   }
   if ( (self.deadflag == DEAD_DYING) ) {

      return ;

   }
   if ( self.button2 ) {

      PlayerJump ();

   } else {

      self.flags = (self.flags | FL_JUMPRELEASED);

   }
   if ( (time < self.pausetime) ) {

      self.velocity = VEC_ORIGIN;

   }

};

void () CheckPowerups = {

   if ( (self.health <= FALSE) ) {

      return ;

   }
   if ( self.invisible_finished ) {

      if ( (self.invisible_sound < time) ) {

         sound (self,CHAN_AUTO,"items/inv3.wav",0.500,ATTN_IDLE);
         self.invisible_sound = (time + ((random () * MOVETYPE_WALK) + TRUE));

      }
      if ( (self.invisible_finished < (time + MOVETYPE_WALK)) ) {

         if ( (self.invisible_time == TRUE) ) {

            sprint (self,"Ring of Shadows magic is fading\n");
            stuffcmd (self,"bf\n");
            sound (self,CHAN_AUTO,"items/inv2.wav",TRUE,ATTN_NORM);
            self.invisible_time = (time + TRUE);

         }
         if ( (self.invisible_time < time) ) {

            self.invisible_time = (time + TRUE);
            stuffcmd (self,"bf\n");

         }

      }
      if ( (self.invisible_finished < time) ) {

         self.items = (self.items - IT_INVISIBILITY);
         self.invisible_finished = FALSE;
         self.invisible_time = FALSE;

      }
      self.frame = FALSE;
      self.modelindex = modelindex_eyes;

   } else {

      self.modelindex = modelindex_player;

   }
   if ( self.invincible_finished ) {

      if ( (self.invincible_finished < (time + MOVETYPE_WALK)) ) {

         if ( (self.invincible_time == TRUE) ) {

            sprint (self,"Protection is almost burned out\n");
            stuffcmd (self,"bf\n");
            sound (self,CHAN_AUTO,"items/protect2.wav",TRUE,ATTN_NORM);
            self.invincible_time = (time + TRUE);

         }
         if ( (self.invincible_time < time) ) {

            self.invincible_time = (time + TRUE);
            stuffcmd (self,"bf\n");

         }

      }
      if ( (self.invincible_finished < time) ) {

         self.items = (self.items - IT_INVULNERABILITY);
         self.invincible_time = FALSE;
         self.invincible_finished = FALSE;

      }
      if ( (self.invincible_finished > time) ) {

         self.effects = (self.effects | EF_DIMLIGHT);

      } else {

         self.effects = (self.effects - (self.effects & EF_DIMLIGHT));

      }

   }
   if ( self.super_damage_finished ) {

      if ( (self.super_damage_finished < (time + MOVETYPE_WALK)) ) {

         if ( (self.super_time == TRUE) ) {

            sprint (self,"Quad Damage is wearing off\n");
            stuffcmd (self,"bf\n");
            sound (self,CHAN_AUTO,"items/damage2.wav",TRUE,ATTN_NORM);
            self.super_time = (time + TRUE);

         }
         if ( (self.super_time < time) ) {

            self.super_time = (time + TRUE);
            stuffcmd (self,"bf\n");

         }

      }
      if ( (self.super_damage_finished < time) ) {

         self.items = (self.items - IT_QUAD);
         self.super_damage_finished = FALSE;
         self.super_time = FALSE;

      }
      if ( (self.super_damage_finished > time) ) {

         self.effects = (self.effects | EF_DIMLIGHT);

      } else {

         self.effects = (self.effects - (self.effects & EF_DIMLIGHT));

      }

   }
   if ( self.radsuit_finished ) {

      self.air_finished = (time + 12.000);
      if ( (self.radsuit_finished < (time + MOVETYPE_WALK)) ) {

         if ( (self.rad_time == TRUE) ) {

            sprint (self,"Air supply in Biosuit expiring\n");
            stuffcmd (self,"bf\n");
            sound (self,CHAN_AUTO,"items/suit2.wav",TRUE,ATTN_NORM);
            self.rad_time = (time + TRUE);

         }
         if ( (self.rad_time < time) ) {

            self.rad_time = (time + TRUE);
            stuffcmd (self,"bf\n");

         }

      }
      if ( (self.radsuit_finished < time) ) {

         self.items = (self.items - IT_SUIT);
         self.rad_time = FALSE;
         self.radsuit_finished = FALSE;

      }

   }

};

void () PlayerPostThink = {

   if ( (self.view_ofs == VEC_ORIGIN) ) {

      return ;

   }
   if ( self.deadflag ) {

      return ;

   }
   if ( CheckDropPath () ) {

      DropBotPath ();

   }
   self.movetarget.flags = self.flags;
   setorigin (self.movetarget,self.origin);
   W_WeaponFrame ();
   // Auditory system: water entry/exit splash
   if ( (self.waterlevel > FALSE) && (self.old_waterlevel == FALSE) ) {
      Bot_BroadcastNoise (self, self.origin, 800.000, NOISE_WATER);
   } else {
      if ( (self.waterlevel == FALSE) && (self.old_waterlevel > FALSE) ) {
         Bot_BroadcastNoise (self, self.origin, 800.000, NOISE_WATER);
      }
   }
   // Auditory system: footsteps (running on ground)
   if ( ((self.flags & FL_ONGROUND) && (vlen (self.velocity) > 250.000)) ) {
      if ( (time > self.noise_time) ) {
         Bot_BroadcastNoise (self, self.origin, 400.000, NOISE_STEP);
         self.noise_time = (time + 0.400);
      }
   }
   if ( (((self.jump_flag < -300.000) && (self.flags & FL_ONGROUND)) && (self.health > FALSE)) ) {

      if ( (self.watertype == CONTENT_WATER) ) {

         sound (self,CHAN_BODY,"player/h2ojump.wav",TRUE,ATTN_NORM);

      } else {

         if ( (self.jump_flag < -650.000) ) {

            T_Damage (self,world,world,MOVETYPE_FLY);
            sound (self,CHAN_VOICE,"player/land2.wav",TRUE,ATTN_NORM);
            self.deathtype = "falling";

         } else {

            sound (self,CHAN_VOICE,"player/land.wav",TRUE,ATTN_NORM);

         }

      }
      self.jump_flag = FALSE;

   }
   if ( !(self.flags & FL_ONGROUND) ) {

      self.jump_flag = self.velocity_z;

   }
   CheckPowerups ();
   if ( !intermission_running ) {
      Player_AutoWaypoint ();
   }
   self.old_waterlevel = self.waterlevel;

};

void () printIntro = {

   local float num;
   local float skinno;

   if ( teamplay ) {

      if ( (parm4 > 511.000) ) {

         SKINSMODE = ((parm4 & 49152.000) / IT_ARMOR2);
         skinno = (parm4 & 7680.000);
         parm4 = (parm4 & 511.000);
         skinChange (self,skinno);

      }
      num = ((serverflags & TEAMBOTS) / FL_ITEM);
      if ( (num > FALSE) ) {

         addTeamBots (self,num);

      }
      centerprint (self,"House of the Reformed Reaper Bot");

   } else {

      centerprint (self,"House of the Reformed Reaper Bot");

   }

};

void () ClientConnect = {

   bprint (self.netname);
   bprint (" entered the game\n");
   self.id = FindGood();
   self.impulse = 204.000;
   initscore ();
   if ( intermission_running ) {

      ExitIntermission ();

   }

};

void () ClientDisconnect = {

   if ( gameover ) {

      return ;

   }
   bprint (self.teamname);
   bprint (self.netname);
   bprint (" left the game with ");
   MakeGood(self.id);
   bprint (ftos (self.frags));
   bprint (" frags\n");
   sound (self,CHAN_BODY,"player/tornoff2.wav",TRUE,ATTN_NONE);
   self.classname = "nobody";
   set_suicide_frame ();

};

void (entity targ, entity attacker) ClientObituary = {

   local float rnum;
   local string deathstring;
   local string deathstring2;
   local entity near_node;
   local entity e;
   local float best_dist;
   local float dist;

   rnum = random ();
   if ( ((targ.classname == "player") || (targ.classname == "dmbot")) ) {

      if ( (attacker.classname == "teledeath") ) {

         bprint (targ.teamname);
         bprint (targ.netname);
         bprint (" was telefragged by ");
         bprint (attacker.owner.teamname);
         bprint (attacker.owner.netname);
         bprint ("\n");
      if ( (attacker.owner.classname == "dmbot") ) {

            TELEFRAGFLAG = TRUE;

         }
         attacker.owner.frags = (attacker.owner.frags + TRUE);
         countkill (attacker.owner,targ);
          if (attacker.owner.classname == "dmbot")
              {
               WriteByte( MSG_ALL, MSG_UPDATEFRAGS );
               WriteByte( MSG_ALL, attacker.owner.id );
               WriteShort( MSG_ALL, attacker.owner.frags );
              }

         return ;

      }
      if ( (attacker.classname == "teledeath2") ) {

         bprint ("Satan's power deflects ");
         bprint (targ.teamname);
         bprint (targ.netname);
         bprint ("'s telefrag\n");
         countkill (targ,targ);
         targ.frags = (targ.frags - TRUE);
          if (targ.classname == "dmbot")
              {
               WriteByte( MSG_ALL, MSG_UPDATEFRAGS );
               WriteByte( MSG_ALL, targ.id );
               WriteShort( MSG_ALL, targ.frags );
              }

         return ;

      }
      if ( ((attacker.classname == "player") || (attacker.classname == "dmbot")) ) {

         if ( (targ == attacker) ) {

            attacker.frags = (attacker.frags - TRUE);
          if (attacker.classname == "dmbot")
              {
               WriteByte( MSG_ALL, MSG_UPDATEFRAGS );
               WriteByte( MSG_ALL, attacker.id );
               WriteShort( MSG_ALL, attacker.frags );
              }

            countkill (attacker,attacker);
            bprint (targ.teamname);
            bprint (targ.netname);
            if ( ((targ.weapon == FL_GODMODE) && (targ.waterlevel > TRUE)) ) {

               bprint (" discharges into the water.\n");
               return ;

            }
            if ( (targ.weapon == FL_INWATER) ) {

               bprint (" tries to put the pin back in\n");

            } else {

               if ( rnum ) {

                  bprint (" becomes bored with life\n");

               } else {

                  bprint (" checks if his weapon is loaded\n");

               }

            }
            return ;

         } else {

            attacker.frags = (attacker.frags + TRUE);

          if (attacker.classname == "dmbot")
              {
               WriteByte( MSG_ALL, MSG_UPDATEFRAGS );
               WriteByte( MSG_ALL, attacker.id );
               WriteShort( MSG_ALL, attacker.frags );
              }

            countkill (attacker,targ);
            if ( (attacker.classname == "dmbot") ) {
               if ( !(attacker.flags & FL_ONGROUND) ) {
                  attacker.strafe_timer = (time + 2.000);
               }

               // ============================================================
               // DARWIN UPDATE: POSITIVE REINFORCEMENT (The Winner)
               // Mark this location as glorious and boost weapon confidence
               // ============================================================
               local entity victor_node;
               local entity node_search;
               local float node_dist;
               local float best_node_dist;

               victor_node = world;
               best_node_dist = 99999;
               node_search = findradius (attacker.origin, 250);
               while ( node_search ) {
                  if ( node_search.classname == "BotPath" ) {
                     node_dist = vlen (node_search.origin - attacker.origin);
                     if ( node_dist < best_node_dist ) {
                        best_node_dist = node_dist;
                        victor_node = node_search;
                     }
                  }
                  node_search = node_search.chain;
               }

               // Mark killzone as glorious
               if ( victor_node && victor_node != world ) {
                  ModulateNodeWeight (victor_node, 10);
               }

               // WEAPON LEARNING: "I got a kill with this weapon!"
               if ( attacker.weapon == IT_ROCKET_LAUNCHER ) {
                  attacker.confidence_rl = attacker.confidence_rl + 1;
                  if ( attacker.confidence_rl > 10 ) attacker.confidence_rl = 10;
               } else if ( attacker.weapon == IT_LIGHTNING ) {
                  attacker.confidence_lg = attacker.confidence_lg + 1;
                  if ( attacker.confidence_lg > 10 ) attacker.confidence_lg = 10;
               } else if ( attacker.weapon == IT_GRENADE_LAUNCHER ) {
                  attacker.confidence_gl = attacker.confidence_gl + 1;
                  if ( attacker.confidence_gl > 10 ) attacker.confidence_gl = 10;
               } else if ( attacker.weapon == IT_SHOTGUN || attacker.weapon == IT_SUPER_SHOTGUN ) {
                  attacker.confidence_sg = attacker.confidence_sg + 1;
                  if ( attacker.confidence_sg > 10 ) attacker.confidence_sg = 10;
               }
            }

            // ============================================================
            // DARWIN UPDATE: NEGATIVE REINFORCEMENT (The Loser)
            // Bot lost with this weapon - reduce confidence
            // ============================================================
            if ( (targ.classname == "dmbot") ) {
               if ( targ.weapon == IT_ROCKET_LAUNCHER ) {
                  targ.confidence_rl = targ.confidence_rl - 1;
                  if ( targ.confidence_rl < -10 ) targ.confidence_rl = -10;
               } else if ( targ.weapon == IT_LIGHTNING ) {
                  targ.confidence_lg = targ.confidence_lg - 1;
                  if ( targ.confidence_lg < -10 ) targ.confidence_lg = -10;
               } else if ( targ.weapon == IT_GRENADE_LAUNCHER ) {
                  targ.confidence_gl = targ.confidence_gl - 1;
                  if ( targ.confidence_gl < -10 ) targ.confidence_gl = -10;
               } else if ( targ.weapon == IT_SHOTGUN || targ.weapon == IT_SUPER_SHOTGUN ) {
                  targ.confidence_sg = targ.confidence_sg - 1;
                  if ( targ.confidence_sg < -10 ) targ.confidence_sg = -10;
               }
            }

            rnum = attacker.weapon;
            if ( (rnum == IT_AXE) ) {

               deathstring = " was ax-murdered by ";
               deathstring2 = "\n";

            }
            if ( (rnum == IT_SHOTGUN) ) {

               deathstring = " chewed on ";
               deathstring2 = "'s boomstick\n";

            }
            if ( (rnum == IT_SUPER_SHOTGUN) ) {

               deathstring = " ate 2 loads of ";
               deathstring2 = "'s buckshot\n";

            }
            if ( (rnum == IT_NAILGUN) ) {

               deathstring = " was nailed by ";
               deathstring2 = "\n";

            }
            if ( (rnum == IT_SUPER_NAILGUN) ) {

               deathstring = " was punctured by ";
               deathstring2 = "\n";

            }
            if ( (rnum == IT_GRENADE_LAUNCHER) ) {

               deathstring = " eats ";
               deathstring2 = "'s pineapple\n";
               if ( (targ.health < -40.000) ) {

                  deathstring = " was gibbed by ";
                  deathstring2 = "'s grenade\n";

               }

            }
            if ( (rnum == IT_ROCKET_LAUNCHER) ) {

               deathstring = " rides ";
               deathstring2 = "'s rocket\n";
               if ( (targ.health < -40.000) ) {

                  deathstring = " was gibbed by ";
                  deathstring2 = "'s rocket\n";

               }

            }
            if ( (rnum == IT_LIGHTNING) ) {

               deathstring = " accepts ";
               if ( (attacker.waterlevel > TRUE) ) {

                  deathstring2 = "'s discharge\n";

               } else {

                  deathstring2 = "'s shaft\n";

               }

            }
            bprint (targ.teamname);
            bprint (targ.netname);
            bprint (deathstring);
            bprint (attacker.teamname);
            bprint (attacker.netname);
            bprint (deathstring2);

         }
         return ;

      } else {

         targ.frags = (targ.frags - TRUE);
          if (targ.classname == "dmbot")
              {
               WriteByte( MSG_ALL, MSG_UPDATEFRAGS );
               WriteByte( MSG_ALL, targ.id );
               WriteShort( MSG_ALL, targ.frags );
              }

         rnum = targ.watertype;
         countkill (targ,targ);
         bprint (targ.teamname);
         bprint (targ.netname);
         if ( (rnum == CONTENT_WATER) ) {

            if ( (random () < 0.500) ) {

               bprint (" sleeps with the fishes\n");

            } else {

               bprint (" sucks it down\n");

            }
            return ;

         } else {

            if ( (rnum == CONTENT_SLIME) ) {

               if ( (random () < 0.500) ) {

                  bprint (" gulped a load of slime\n");

               } else {

                  bprint (" can't exist on slime alone\n");

               }
               return ;

            } else {

               if ( (rnum == CONTENT_LAVA) ) {

                  if ( (targ.health < -15.000) ) {

                     bprint (" burst into flames\n");
                     return ;

                  }
                  if ( (random () < 0.500) ) {

                     bprint (" turned into hot slag\n");

                  } else {

                     bprint (" visits the Volcano God\n");

                  }
                  return ;

               }

            }

         }
         if ( (attacker.flags & FL_MONSTER) ) {

            if ( (attacker.classname == "monster_army") ) {

               bprint (" was shot by a Grunt\n");

            }
            if ( (attacker.classname == "monster_demon1") ) {

               bprint (" was eviscerated by a Fiend\n");

            }
            if ( (attacker.classname == "monster_dog") ) {

               bprint (" was mauled by a Rottweiler\n");

            }
            if ( (attacker.classname == "monster_dragon") ) {

               bprint (" was fried by a Dragon\n");

            }
            if ( (attacker.classname == "monster_enforcer") ) {

               bprint (" was blasted by an Enforcer\n");

            }
            if ( (attacker.classname == "monster_fish") ) {

               bprint (" was fed to the Rotfish\n");

            }
            if ( (attacker.classname == "monster_hell_knight") ) {

               bprint (" was slain by a Death Knight\n");

            }
            if ( (attacker.classname == "monster_knight") ) {

               bprint (" was slashed by a Knight\n");

            }
            if ( (attacker.classname == "monster_ogre") ) {

               bprint (" was destroyed by an Ogre\n");

            }
            if ( (attacker.classname == "monster_oldone") ) {

               bprint (" became one with Shub-Niggurath\n");

            }
            if ( (attacker.classname == "monster_shalrath") ) {

               bprint (" was exploded by a Vore\n");

            }
            if ( (attacker.classname == "monster_shambler") ) {

               bprint (" was smashed by a Shambler\n");

            }
            if ( (attacker.classname == "monster_tarbaby") ) {

               bprint (" was slimed by a Spawn\n");

            }
            if ( (attacker.classname == "monster_vomit") ) {

               bprint (" was vomited on by a Vomitus\n");

            }
            if ( (attacker.classname == "monster_wizard") ) {

               bprint (" was scragged by a Scrag\n");

            }
            if ( (attacker.classname == "monster_zombie") ) {

               bprint (" joins the Zombies\n");

            }
            return ;

         }
         if ( (attacker.classname == "explo_box") ) {

            bprint (" blew up\n");
            return ;

         }
         if ( ((attacker.solid == SOLID_BSP) && (attacker != world)) ) {

            bprint (" was squished\n");
            return ;

         }
         if ( (targ.deathtype == "falling") ) {

            targ.deathtype = "";
            bprint (" fell to his death\n");
            return ;

         }
         if ( ((attacker.classname == "trap_shooter") || (attacker.classname == "trap_spikeshooter")) ) {

            bprint (" was spiked\n");
            return;

         }
         if ( (attacker.classname == "fireball") ) {

            bprint (" ate a lavaball\n");
            return ;

         }
         if ( (attacker.classname == "trigger_changelevel") ) {

            bprint (" tried to leave\n");
            return ;

         }
         bprint (" died\n");

      }
      // DARWIN: Mark nearby waypoint as dangerous for bots
      // This teaches bots to avoid death locations
      if ( targ.classname == "dmbot" ) {
         near_node = world;
         best_dist = 99999.000;
         e = findradius (targ.origin, 250);
         while ( e ) {
            if ( (e.classname == "BotPath") ) {
               dist = vlen ((e.origin - targ.origin));
               if ( (dist < best_dist) ) {
                  best_dist = dist;
                  near_node = e;
               }
            }
            e = e.chain;
         }
         if ( near_node && (near_node != world) ) {
            // Use Darwin's ModulateNodeWeight for adaptive learning
            ModulateNodeWeight (near_node, -500);  // Massive danger penalty
         }
      }

   }

};



