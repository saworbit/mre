entity bodyque_head;

.float LoggedIn;

void (entity bot) bot_triggered;

void (entity killer, entity killed) countkill;

void () initscore;

void (entity ply, float n) removeTeamBots;

void (entity ply, float n) addTeamBots;

void (entity e, float newskin) skinChange;

void () NewCarriedPath;

void () initBotLevel;
float () CheckDropPath;

void () DropBotPath;
float () BotFoundTarget;

void (entity en2) secondEnemy;

void () endEnemy;

void () bot_touched;

void () enemy_touched;

void (entity node, entity targ, float len, entity item) cacheRoute;

void () bot_toucheditem;

void (entity a, entity b) addTarget;
vector () botaim;

void () botImpulseCommand;

void () setBotGravity;

void (vector tdest, float tspeed, void() func) SUB_CalcMove;

void (entity ent, vector tdest, float tspeed, void() func) SUB_CalcMoveEnt;

void (vector destangle, float tspeed, void() func) SUB_CalcAngleMove;

void () SUB_CalcMoveDone;

void () SUB_CalcAngleMoveDone;

void () SUB_Null;

void () SUB_UseTargets;

void () SUB_Remove;

void (entity targ, entity inflictor, entity attacker, float damage) T_Damage;
float (entity e, float healamount, float ignore) T_Heal;
float (entity targ, entity inflictor) CanDamage;
.float(entity e) th_weight;
.float(entity node, float len, entity item) th_cache;
.void() th_update;
.float istrigger;
.float healtype;
.float playerkills;
.float playerdeaths;
.float botkills;
.float botdeaths;
.float suicides;
.vector lastseenpos;
.float enemyrun;
.float goody_time;
.float strafetime;
.float strafeonly;
.void() strafethink;
.float strafeyaw;
.float strafedist;
.entity movetarget2;
.entity movetarget3;
.entity movetarget4;
.entity movetarget5;
.entity movetarget6;
.entity lastbot;
.float lasttime;
.float pather;
.float pathtype;
.float skil;
.float rocketlen;
.entity rocketcache;
.float lightninglen;
.entity lightningcache;
.float armorlen;
.entity armorcache;
.float pendinglen;
.entity pendingcache;
.float naillen;
.entity nailcache;
.float grenadelen;
.entity grenadecache;
.float poweruplen;
.entity powerupcache;
.float enemylen;
.entity enemycache;
.float endpoint;
.string teamname;
float NORMALSCORE    = 1.000;
float MYSCORE    = 2.000;
float MUST_HAVE    = 100.000;
float WANT    = 35.000;
float KINDA_WANT    = 20.000;
float DONT_WANT    = 0.000;
float CANTURN    = 1.000;
float NOTURN    = 2.000;
float SEARCH_RADIUS    = 600.000;
float LOOPTIME    = 20.000;
float MAXPATHERS    = 16.000;
float DROPPED    = 2.000;
float CARRIED    = 1.000;
float NEVERTARGET    = 3.000;
float REGULARTARGET    = 0.000;
float TELEPORT    = 4.000;
float BOTS    = 240.000;
float TEAMBOTS    = 3840.000;
float RESTRICT    = 4096.000;
float SUPERRESTRICT    = 8192.000;
float TEAMFLAG    = 16384.000;
float INITLEVEL    = 32768.000;
float DEDICATED    = 4194304.000;
float LOCAL_TIME    = 7.000;
float STRAFE_DIR    = 16.000;
float FAR_SEEK    = 32.000;
float WATERUPDOWN    = 64.000;
float NODROP    = 128.000;
float RUNAWAY    = 256.000;
float GETGOODY    = 512.000;
float ONTRAIN    = 1024.000;
float MULTIENEMY    = 2048.000;
float VERBOSEBOT;
float BOTSPEED;
float NUMBOTS;
float GRAVITY;
float MAXJUMP;
float INVGRENADELEVELDIST;
float GRENADEMAXHEIGHT;
float LEVELJUMPTIME;
float NUMPATHS;
float NUMGIBS;
float NUMPATHERS;
float SKINSMODE;
float RECURSEDEPTH;
vector REBOUNDSPOT;
float REBOUND;
float TELEFRAGFLAG;
entity NOISEQUEUE;
float HELPING;
float NAMEBOTS;

void (entity noisemaker, entity noiseobject) signalnoise;
float (entity e) hearnoise;
entity () noisetarget;

void () CopyrightNotice = {

   dprint (" The Quake C modifications included in this archive are Copyright 1996, Steven Polge.");
   dprint ("The original QuakeC source is Copyright 1996, id software.");
   dprint ("You MAY NOT use these modifications as a basis for other publicly or commercially available work.");

};
float (entity targ) Spotvisible;
float (entity targ) Platvisible;
float (vector spot) dropline;

void () secret_touch;
float (entity e) doorweight = {

   local float weight;

   weight = KINDA_WANT;
   if ( e.owner.targetname ) {

      weight = DONT_WANT;

   } else {

      if ( (e.touch == secret_touch) ) {

         weight = KINDA_WANT;

      } else {

         if ( (e.state == STATE_TOP) ) {

            weight = DONT_WANT;

         } else {

            if ( (e.state == STATE_UP) ) {

               weight = KINDA_WANT;

            }

         }

      }

   }
   if ( !Spotvisible (e) ) {

      weight = DONT_WANT;

   }
   return ( weight );

};
float (entity e) buttonweight = {

   local float weight;

   weight = DONT_WANT;
   if ( (e.state == STATE_BOTTOM) ) {

      if ( Spotvisible (e) ) {

         weight = (KINDA_WANT + TRUE);

      }

   }
   return ( weight );

};
float (entity e) platweight = {

   local float weight;

   weight = KINDA_WANT;
   if ( !Platvisible (e) ) {

      if ( !Spotvisible (e) ) {

         weight = DONT_WANT;

      }

   }
   return ( weight );

};
float (entity e) trigpushweight = {

   local float weight;
   local vector spot;
   local vector org;

   weight = DONT_WANT;
   org = ((e.absmin + e.absmax) * 0.500);
   org_z = (e.absmin_z + TRUE);
   spot = org;
   spot_z = self.origin_z;
   traceline (self.origin,spot,TRUE,self);
   if ( (trace_fraction == TRUE) ) {

      traceline (spot,org,TRUE,self);
      if ( (trace_fraction == TRUE) ) {

         spot_z = dropline (org);
         if ( (self.absmin_z > spot_z) ) {

            spot_z = self.absmin_z;

         }
         if ( (org_z < (((self.maxs_z - self.mins_z) + spot_z) + MAXJUMP)) ) {

            weight = KINDA_WANT;

         }

      }

   }
   return ( weight );

};
float (entity e) triggerweight = {

   local float weight;
   local float rnd;

   weight = (KINDA_WANT - FL_SWIM);
   rnd = random ();
   if ( (rnd < 0.250) ) {

      weight = WANT;

   }
   if ( !Spotvisible (e) ) {

      weight = DONT_WANT;

   }
   return ( weight );

};
float (entity e) backpackweight = {

   local float lnd;
   local float weight;

   weight = WANT;
   lnd = pointcontents ((e.absmin + '0.000 0.000 1.000'));
   if ( (e.items & (IT_ROCKET_LAUNCHER + IT_LIGHTNING)) ) {

      weight = (MUST_HAVE - TRUE);

   }
   if ( ((lnd == CONTENT_LAVA) || (lnd == CONTENT_SLIME)) ) {

      weight = DONT_WANT;

   }
   return ( weight );

};
float (entity e) healthweight = {

   local float weight;

   weight = WANT;
   if ( (self.health < 60.000) ) {

      weight = (MUST_HAVE - TRUE);

   } else {

      if ( (e.healtype == FL_SWIM) ) {

         weight = MUST_HAVE;

      } else {

         if ( (self.health > 99.000) ) {

            weight = DONT_WANT;

         }

      }

   }
   return ( weight );

};
float (entity e) nailweight = {

   local float weight;

   weight = (WANT - TRUE);
   if ( (self.ammo_nails > 199.000) ) {

      weight = DONT_WANT;

   } else {

      if ( (self.ammo_nails > 120.000) ) {

         weight = (KINDA_WANT - FL_SWIM);

      }

   }
   return ( weight );

};
float (entity e) shellweight = {

   local float weight;

   weight = (WANT - TRUE);
   if ( (self.ammo_shells > 99.000) ) {

      weight = DONT_WANT;

   } else {

      if ( (self.ammo_shells > 50.000) ) {

         weight = (KINDA_WANT - FL_SWIM);

      }

   }
   return ( weight );

};
float (entity e) cellweight = {

   local float weight;

   weight = WANT;
   if ( (self.ammo_cells > 99.000) ) {

      weight = DONT_WANT;

   }
   return ( weight );

};
float (entity e) rocketweight = {

   local float weight;

   weight = WANT;
   if ( (self.ammo_rockets > 99.000) ) {

      weight = DONT_WANT;

   }
   return ( weight );

};
float (entity e) rlauncherweight = {

   local float weight;

   weight = (WANT + FL_SWIM);
   if ( !(self.items & IT_ROCKET_LAUNCHER) ) {

      weight = MUST_HAVE;

   }
   return ( weight );

};
float (entity e) lightningweight = {

   local float weight;

   weight = (WANT + FL_SWIM);
   if ( !(self.items & IT_LIGHTNING) ) {

      weight = MUST_HAVE;

   }
   return ( weight );

};
float (entity e) glauncherweight = {

   local float weight;

   weight = (WANT + TRUE);
   if ( !(self.items & IT_GRENADE_LAUNCHER) ) {

      weight = (MUST_HAVE - TRUE);

   }
   return ( weight );

};
float (entity e) nailgunweight = {

   return ( WANT );

};
float (entity e) supernailweight = {

   local float weight;

   weight = (WANT + TRUE);
   if ( !(self.items & IT_SUPER_NAILGUN) ) {

      weight = (MUST_HAVE - TRUE);

   }
   return ( weight );

};
float (entity e) ssgweight = {

   return ( WANT );

};
float (entity e) armorweight = {

   local float weight;

   weight = (e.armorvalue - self.armorvalue);
   return ( weight );

};
float (entity e) artifactweight = {

   local float weight;

   weight = (MUST_HAVE + FL_SWIM);
   if ( (e.classname == "item_artifact_envirosuit") ) {

      weight = WANT;

   }
   return ( weight );

};
float (entity node, float len, entity item) cacherocket = {

   if ( (node.rocketlen > FALSE) ) {

      if ( (len >= node.rocketlen) ) {

         return ( FALSE );

      }

   }
   node.rocketlen = len;
   node.rocketcache = item;
   return ( TRUE );

};
float (entity node, float len, entity item) cachelightning = {

   if ( (node.lightninglen > FALSE) ) {

      if ( (len >= node.lightninglen) ) {

         return ( FALSE );

      }

   }
   node.lightninglen = len;
   node.lightningcache = item;
   return ( TRUE );

};
float (entity node, float len, entity item) cachearmor = {

   if ( (node.armorlen > FALSE) ) {

      if ( (len >= node.armorlen) ) {

         return ( FALSE );

      }

   }
   node.armorlen = len;
   node.armorcache = item;
   return ( TRUE );

};
float (entity node, float len, entity item) cachenail = {

   if ( (node.naillen > FALSE) ) {

      if ( (len >= node.naillen) ) {

         return ( FALSE );

      }

   }
   node.naillen = len;
   node.nailcache = item;
   return ( TRUE );

};
float (entity node, float len, entity item) cachegrenade = {

   if ( (node.grenadelen > FALSE) ) {

      if ( (len >= node.grenadelen) ) {

         return ( FALSE );

      }

   }
   node.grenadelen = len;
   node.grenadecache = item;
   return ( TRUE );

};
float (entity node, float len, entity item) cachepowerup = {

   if ( (node.poweruplen > FALSE) ) {

      if ( (len >= node.poweruplen) ) {

         return ( FALSE );

      }

   }
   node.poweruplen = len;
   node.powerupcache = item;
   return ( TRUE );

};
float (entity node, float len, entity item) cacheenemy = {

   if ( (node.enemylen > FALSE) ) {

      if ( (len >= node.enemylen) ) {

         return ( FALSE );

      }

   }
   node.enemylen = len;
   node.enemycache = item;
   return ( TRUE );

};

void () updaterocket = {

   self.rocketcache = self.pendingcache;
   self.rocketlen = self.pendinglen;

};

void () updatelightning = {

   self.lightningcache = self.pendingcache;
   self.lightninglen = self.pendinglen;

};

void () updatearmor = {

   self.armorcache = self.pendingcache;
   self.armorlen = self.pendinglen;

};

void () updatepowerup = {

   self.powerupcache = self.pendingcache;
   self.poweruplen = self.pendinglen;

};

void () updatenail = {

   self.nailcache = self.pendingcache;
   self.naillen = self.pendinglen;

};

void () updategrenade = {

   self.grenadecache = self.pendingcache;
   self.grenadelen = self.pendinglen;

};
