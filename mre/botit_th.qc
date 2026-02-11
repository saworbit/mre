entity bodyque_head;
entity bot_list_head;

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
void () BotHuntTarget;
void () Player_AutoWaypoint;
void (entity node) MarkDanger;
void () MaintainGraph;
void () DecayEpisodes;

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
void (entity player, entity button) BotMarkMandatoryWaypoint;
entity (entity chaser) FindMandatoryWaypoint;
void () Specter_Toggle;
void () Specter_CycleFocus;
void () Specter_Replay;
void () Specter_Reset;
void (entity bot) Specter_ReplayRecord;

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
.float target_scan_time;    // Throttle: target acquisition scans
.float goodies_scan_time;   // Throttle: item scan loops
.float ripple_interact_time;// Throttle: ripple interact scans
.float nudge_time;          // Throttle: proactive nudge checks
.float nav_predict_time;    // Throttle: nav rollouts (decoupled from combat)
.float ripple_near_idx;     // Cached nearby ripple node index
.vector ripple_near_pos;    // Cached ripple node position
.float ripple_near_count;   // Cached vortex_count at time of cache
.float pather;
.float pathtype;
.float visited_id;  // cycle detection for route caching
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
.float dmg_dealt;
.float post_kill_time;
float NORMALSCORE    = 1.000;
float MYSCORE    = 2.000;
float MUST_HAVE    = 100.000;
float WANT    = 35.000;
float KINDA_WANT    = 20.000;
float DONT_WANT    = 0.000;
float CANTURN    = 1.000;
float NOTURN    = 2.000;
float SEARCH_RADIUS    = 1200.000;
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
float SOLVE_BUTTON  = 4096.000;  // Button puzzle solving mode
float AI_STATE_NONE    = 0.000;
float AI_STATE_GOODY    = 1.000;
float AI_STATE_RETREAT    = 2.000;
float AI_STATE_ATTACK    = 3.000;
float AI_STATE_CHASE    = 4.000;
float AI_STATE_INVESTIGATE = 6.000; // Investigating a sound
float AI_STATE_AMBUSH    = 7.000;   // Setting up a trap (Mastermind)
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
float route_search_id;  // unique ID per route cache search (cycle detection)
float graph_decay_next; // Next time to run path decay (global throttle)
vector REBOUNDSPOT;
float REBOUND;
float TELEFRAGFLAG;
entity NOISEQUEUE;
float HELPING;
float NAMEBOTS;
float user_strafe_bias[32];  // Slayer Eclipse: per-user strafe bias
float gj_horiz_tune[4];      // Grenade jump horizontal tuning per purpose
float gj_vert_tune[4];       // Grenade jump vertical tuning per purpose
float glj_angle_tune[4];     // GLJ launch angle tuning per purpose

// --- SPECTER GAZE (cinematic spectator) ---
void () Specter_ViewUpdate;
float specter_active;
float specter_focus;
float specter_last_focus;
float specter_force_until;
float specter_last_switch;
entity specter_owner;
entity specter_view_ent;
entity specter_cams[4];
entity specter_targets[4];
float specter_scores[4];
float specter_idle_since;
float specter_focus_drama;

// --- AUDITORY SYSTEM ---
float NOISE_GENERIC = 0.000;
float NOISE_ITEM    = 1.000; // Pickup sound
float NOISE_WATER   = 2.000; // Splash/Swim
float NOISE_WEAPON  = 3.000; // Gunfire
float NOISE_STEP    = 4.000; // Footsteps

void (entity noisemaker, entity noiseobject) signalnoise;
float (entity e) hearnoise;
entity () noisetarget;
void (entity source, vector org, float volume, float type) Bot_BroadcastNoise;

// =============================================================================
// ADAPTIVE TACTICS: Opponent Profile Model (Intelligence Pass #8)
// 4-slot per-enemy tracker using exponential moving averages.
// Tracks aggression, weapon preference, and threat level per opponent.
// =============================================================================

// Find profile slot for this enemy (-1 if not tracked)
float (entity en) OppSlot = {
   if ( self.opp_ent_0 == en ) return 0;
   if ( self.opp_ent_1 == en ) return 1;
   if ( self.opp_ent_2 == en ) return 2;
   if ( self.opp_ent_3 == en ) return 3;
   return -1;
};

// Find or create slot (LRU eviction: shift 2→3, 1→2, new→1)
float (entity en) OppSlotOrEvict = {
   local float s;
   s = OppSlot(en);
   if ( s >= 0 ) return s;
   // Evict slot 3, shift down
   self.opp_ent_3 = self.opp_ent_2;
   self.opp_aggro_3 = self.opp_aggro_2;
   self.opp_weap_3 = self.opp_weap_2;
   self.opp_threat_3 = self.opp_threat_2;
   self.opp_ent_2 = self.opp_ent_1;
   self.opp_aggro_2 = self.opp_aggro_1;
   self.opp_weap_2 = self.opp_weap_1;
   self.opp_threat_2 = self.opp_threat_1;
   self.opp_ent_1 = en;
   self.opp_aggro_1 = 0.5;
   self.opp_weap_1 = 0;
   self.opp_threat_1 = 0.5;
   return 1;
};

// EMA update: alpha=0.3 blends new observation with history
// Called each time enemy is visible in BotAI_Main
void (entity en) OppUpdate = {
   local float s;
   local float aggro;
   local vector to_me;

   s = OppSlotOrEvict(en);

   // Aggression = how much they push toward us
   to_me = normalize(self.origin - en.origin);
   aggro = normalize(en.velocity) * to_me;
   aggro = (aggro + 1) * 0.5;  // normalize -1..1 to 0..1

   // Apply EMA (alpha=0.3: responsive but stable)
   if ( s == 0 ) {
      self.opp_aggro_0 = self.opp_aggro_0 * 0.7 + aggro * 0.3;
      self.opp_weap_0 = en.weapon;
   } else if ( s == 1 ) {
      self.opp_aggro_1 = self.opp_aggro_1 * 0.7 + aggro * 0.3;
      self.opp_weap_1 = en.weapon;
   } else if ( s == 2 ) {
      self.opp_aggro_2 = self.opp_aggro_2 * 0.7 + aggro * 0.3;
      self.opp_weap_2 = en.weapon;
   } else {
      self.opp_aggro_3 = self.opp_aggro_3 * 0.7 + aggro * 0.3;
      self.opp_weap_3 = en.weapon;
   }
};

// Query: get aggression EMA for a specific enemy
float (entity en) OppGetAggro = {
   local float s;
   s = OppSlot(en);
   if ( s == 0 ) return self.opp_aggro_0;
   if ( s == 1 ) return self.opp_aggro_1;
   if ( s == 2 ) return self.opp_aggro_2;
   if ( s == 3 ) return self.opp_aggro_3;
   return 0.5;  // unknown = neutral
};

// Query: get threat EMA for a specific enemy
float (entity en) OppGetThreat = {
   local float s;
   s = OppSlot(en);
   if ( s == 0 ) return self.opp_threat_0;
   if ( s == 1 ) return self.opp_threat_1;
   if ( s == 2 ) return self.opp_threat_2;
   if ( s == 3 ) return self.opp_threat_3;
   return 0.5;  // unknown = average
};

// Query: get last observed weapon for a specific enemy
float (entity en) OppGetWeap = {
   local float s;
   s = OppSlot(en);
   if ( s == 0 ) return self.opp_weap_0;
   if ( s == 1 ) return self.opp_weap_1;
   if ( s == 2 ) return self.opp_weap_2;
   if ( s == 3 ) return self.opp_weap_3;
   return 0;  // unknown
};

// Update threat EMA on kill/death events
// winner killed loser: winner sees loser as less threatening,
// loser sees winner as more threatening
void (entity winner, entity loser) OppRecordResult = {
   local float s;
   local entity saved;
   saved = self;

   // Winner's view of loser: threat decreases (I beat them)
   self = winner;
   s = OppSlot(loser);
   if ( s >= 0 ) {
      if ( s == 0 ) self.opp_threat_0 = self.opp_threat_0 * 0.7 + 0.2 * 0.3;
      else if ( s == 1 ) self.opp_threat_1 = self.opp_threat_1 * 0.7 + 0.2 * 0.3;
      else if ( s == 2 ) self.opp_threat_2 = self.opp_threat_2 * 0.7 + 0.2 * 0.3;
      else self.opp_threat_3 = self.opp_threat_3 * 0.7 + 0.2 * 0.3;
   }

   // Loser's view of winner: threat increases (they beat me)
   self = loser;
   s = OppSlot(winner);
   if ( s >= 0 ) {
      if ( s == 0 ) self.opp_threat_0 = self.opp_threat_0 * 0.7 + 0.8 * 0.3;
      else if ( s == 1 ) self.opp_threat_1 = self.opp_threat_1 * 0.7 + 0.8 * 0.3;
      else if ( s == 2 ) self.opp_threat_2 = self.opp_threat_2 * 0.7 + 0.8 * 0.3;
      else self.opp_threat_3 = self.opp_threat_3 * 0.7 + 0.8 * 0.3;
   }

   self = saved;
};

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
   local float eff;

   weight = WANT;
   eff = (self.health + (self.armorvalue * self.armortype));
   if ( (self.health < 60.000) && (eff < 100.000) ) {

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

   } else if ( (self.items & IT_LIGHTNING) && (self.ammo_cells < 10) ) {
      weight = (MUST_HAVE - TRUE);
   }
   return ( weight );

};
float (entity e) rocketweight = {

   local float weight;

   weight = WANT;
   if ( (self.ammo_rockets > 99.000) ) {

      weight = DONT_WANT;

   } else if ( (self.items & IT_ROCKET_LAUNCHER) && (self.ammo_rockets < 5) ) {
      weight = (MUST_HAVE - TRUE);
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
   local float new_eff, old_eff;
   local float new_type;
   new_type = 0.300;
   if ( (e.classname == "item_armor2") )
      new_type = 0.600;
   else if ( (e.classname == "item_armorInv") )
      new_type = 0.800;
   new_eff = (e.armorvalue * new_type);
   old_eff = (self.armorvalue * self.armortype);
   weight = (new_eff - old_eff);
   if ( (self.health < 50) ) {
      weight = weight + 20;
   }
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
