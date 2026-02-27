
void (float dist) BotAI_Main;

void () bot_chase;

void () bot_trigger1;

void () aibot_chooseGoal;
float (entity targ) BotValidTarget;
float /* Warning: Could not determine return type */ () BotFindTarget;

// Forward declarations for button solving (defined in botmove.qc)
void (float dist) BotHandleButton;

// Forward declaration for strategic AI (defined in bot_ai.qc)
float (float dist) BotAI_Strategic;

// Forward declaration for Darwin Update (defined in botroute.qc)
void (entity node, float amount) ModulateNodeWeight;
vector () SilentUnstuck;
void (vector pos) CurseNode;
float () Vortex_ApplyGoal;

void () shoottarget = {

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
   if ( (botTarget.goalentity.classname == "door") ) {

      self.search_time = (time + FL_CLIENT);

   }

};

void (float dist) ai_botseek = {

   local entity botTarget;
   local vector dir;
   local float rng;
   local float oldrng;
   local float stuck_dist;

   // Check if pending enemy reaction time has elapsed
   if ( Bot_CheckReaction () ) {

      aibot_setupchase ();
      return ;

   }

   if ( self.enemy ) {

      aibot_setupchase ();
      return ;

   }
   if ( BotFindTarget () ) {

      self.lefty = (self.lefty | FAR_SEEK);
      return ;

   }

   // STRATEGIC AI: Sound investigation and proactive behavior
   // This runs when we have no enemy, keeping bots active
   if ( BotAI_Strategic (dist) ) {
      return;
   }

   // FIX: Handle button solving mode (with timeout — search_time check
   // is below us so we must enforce it here to prevent infinite pursuit)
   if ( self.lefty & SOLVE_BUTTON ) {
      if ( self.search_time < time ) {
         // Timed out — clear button solving and pick a new goal
         self.lefty = self.lefty - (self.lefty & SOLVE_BUTTON);
         self.blocking_door = world;
         self.target_button = world;
      } else {
         BotHandleButton (dist);
         return;
      }
   }

   // FIX: Platform wait - if waiting for a platform, stay put
   // Safety cap: never wait more than 5s total (prevents stale/corrupt values)
   if ( self.platform_wait_time > time ) {
      if ( self.platform_wait_time > (time + 5) )
         self.platform_wait_time = time + 5;
      self.velocity = '0 0 0';
      return;
   }
   self.platform_wait_time = 0;  // Clear stale/expired values

   // Silent Specters: Stealthy stuck recovery with quiet rollouts
   stuck_dist = vlen (self.origin - self.oldorigin);
   if ( (stuck_dist < 5.000) && (vlen(self.velocity) < 100) ) {

      // Track how long we've been stuck
      if ( self.stuck_time == 0 ) {
         self.stuck_time = time;  // Start stuck timer
         self.stuck_count = 0;
      }

      local float stuck_duration;
      local vector escape;
      stuck_duration = time - self.stuck_time;

      // Silent recovery after 2s of low movement
      if ( stuck_duration > 2.000 ) {
         self.stuck_count = (self.stuck_count + TRUE);

         // Learn the local stuck zone
         CurseNode (self.origin);

         escape = SilentUnstuck ();
         if ( escape != '0 0 0' ) {
            self.velocity = escape;
            self.stuck_time = time;  // Reset timer after a nudge
         } else {
            // Ultra-fallback: micro-pause + strafe
            makevectors (self.angles);
            if ( (random () < 0.500) ) {
               self.velocity = (v_right * 200.000);
            } else {
               self.velocity = (v_right * -200.000);
            }
            self.nextthink = (time + 0.300);
         }

         // If we're still stuck after a few attempts, force a goal change
         if ( self.stuck_count > 2 ) {
            self.search_time = time - 1;

            if ( cached_developer ) {
               dprint("[");
               dprint(self.netname);
               dprint("] STUCK: forcing goal change after ");
               dprint(ftos(stuck_duration));
               dprint("s\n");
            }

            // DARWIN: Learn from navigation failure
            if ( self.last_waypoint && self.last_waypoint != world ) {
               ModulateNodeWeight (self.last_waypoint, -30);
               if ( cached_developer ) {
                  dprint("[");
                  dprint(self.netname);
                  dprint("] DARWIN: Learned BROKEN LINK\n");
               }
            }

            self.stuck_time = 0;
            self.stuck_count = 0;

            // Activate feeler mode to search for an exit
            if ( !self.feeler_mode_active ) {
               self.feeler_mode_active = TRUE;
               self.feeler_start_time = time;
               if ( cached_developer ) {
                  dprint("Activating FEELER mode\n");
               }
            }
         }
      } else {
         // Normal stuck handling - reduce search time faster
         self.search_time = (self.search_time - 0.150);

         // Rare jump when stuck (<5%)
         if ( (random () < 0.050) ) {
            Bot_tryjump (270.000, dist, FALSE);
         }
      }

   } else {
      // Moving normally - clear stuck timer
      self.stuck_time = 0;
      self.stuck_count = 0;
   }

   botTarget = self.goalentity;
   if ( (time < self.search_time) ) {

      if ( (botTarget.goalentity.classname == "train") ) {

         dir = ((botTarget.goalentity.absmin + botTarget.goalentity.absmax) * 0.500);
         dir_z = (botTarget.goalentity.absmax_z + TRUE);
         setorigin (botTarget,dir);

      }
      if ( (botTarget.goalentity.solid != SOLID_NOT) ) {

         // Vortex Navmesh: apply dynamic mesh steering when goal is obstructed
         Vortex_ApplyGoal ();

         oldrng = vlen ((botTarget.origin - self.origin));
         Botmovetogoal (dist);
         rng = vlen ((botTarget.origin - self.origin));
         if ( (rng >= oldrng) ) {

            self.search_time = (self.search_time - 0.400);
            if ( (botTarget.goalentity == botTarget) ) {

               self.search_time = time;

            }

         }
         return ;

      }

   }
   aibot_chooseGoal ();
   if ( (botTarget.goalentity.takedamage == DAMAGE_YES) ) {

      shoottarget ();

   }
   Botmovetogoal (dist);

};
float (entity e) thingweight = {

   local float weight;
   local float OK_HIGH;
   local float recent;
   local float waittime;

   weight = DONT_WANT;
   OK_HIGH = FALSE;
   if ( (self.flags & FL_SWIM) ) {

      OK_HIGH = Swimto (e);

   }
   if ( (e.lastbot == self) ) {

      recent = (e.lasttime > (time - FL_CLIENT));
      if ( !recent ) {

         waittime = (time - (LOOPTIME * random ()));
         recent = (e.lasttime > waittime);

      }
      if ( recent ) {

         return ( DONT_WANT );

      }

   }
   if ( e.th_weight ) {

      weight = e.th_weight (e);

   } else {

      e.pathtype = NEVERTARGET;

   }
   if ( (weight > DONT_WANT) ) {

      if ( !OK_HIGH ) {

         if ( (e.absmin_z > (self.origin_z + MAXJUMP)) ) {

            weight = DONT_WANT;

         }

      }

   }
   return ( weight );

};
float (entity e) trigweight = {

   local float weight;

   weight = DONT_WANT;
   if ( (e.lastbot == self) ) {

      if ( (e.lasttime > (time - FL_CLIENT)) ) {

         return ( DONT_WANT );

      }

   }
   if ( e.th_weight ) {

      weight = e.th_weight (e);

   } else {

      e.pathtype = NEVERTARGET;

   }
   return ( weight );

};
float (entity e) itemweight = {

   local float weight;
   local float OK_HIGH;

   weight = DONT_WANT;
   OK_HIGH = FALSE;
   if ( (self.flags & FL_SWIM) ) {

      OK_HIGH = Swimto (e);

   }
   if ( (e.lastbot == self) ) {

      if ( (e.lasttime > (time - MOVETYPE_FLY)) ) {

         return ( DONT_WANT );

      }

   }
   if ( e.th_weight ) {

      weight = e.th_weight (e);

   } else {

      e.pathtype = NEVERTARGET;

   }

   // FIX: Anti-camping - ignore weapons we already have unless low on ammo
   // This prevents bots from staying near best weapons
   if ( (e.classname == "weapon_supernailgun") ) {

      if ( (self.items & IT_SUPER_NAILGUN) ) {

         if ( (self.ammo_nails > 50.000) ) {

            return ( DONT_WANT );

         }

      }

   }
   if ( (e.classname == "weapon_grenadelauncher") ) {

      if ( (self.items & IT_GRENADE_LAUNCHER) ) {

         if ( (self.ammo_rockets > 10.000) ) {

            return ( DONT_WANT );

         }

      }

   }
   if ( (e.classname == "weapon_rocketlauncher") ) {

      if ( (self.items & IT_ROCKET_LAUNCHER) ) {

         if ( (self.ammo_rockets > 10.000) ) {

            return ( DONT_WANT );

         }

      }

   }
   if ( (e.classname == "weapon_lightning") ) {

      if ( (self.items & IT_LIGHTNING) ) {

         if ( (self.ammo_cells > 50.000) ) {

            return ( DONT_WANT );

         }

      }

   }

   if ( (weight > DONT_WANT) ) {

      if ( !OK_HIGH ) {

         if ( (e.absmin_z > (self.origin_z + MAXJUMP)) ) {

            weight = DONT_WANT;

         }

      }

   }
   if ( (weight > DONT_WANT) ) {

      if ( !TrueReachable (e) ) {

         weight = DONT_WANT;

      }

   }
   return ( weight );

};
vector (float n) chooseRoamTarget = {

   local float len;
   local float r;
   local float d;
   local float m;
   local float lnd;
   local vector dir;
   local vector below;
   local vector bestorg;

   bestorg = self.origin;
   d = random ();
   if ( (d < 0.800) ) {

      r = random ();
      m = TRUE;
      if ( (r < 0.500) ) {

         m = CONTENT_EMPTY;

      }
      bestorg_x = (bestorg_x + (m * ((700.000 * random ()) + 50.000)));

   }
   if ( (d > 0.200) ) {

      r = random ();
      m = TRUE;
      if ( (r < 0.500) ) {

         m = CONTENT_EMPTY;

      }
      bestorg_y = (bestorg_y + (m * ((700.000 * random ()) + 50.000)));

   }
   bestorg_z = (((bestorg_z + ((MOVETYPE_WALK * MAXJUMP) * random ())) - (FL_SWIM * MAXJUMP)) - TRUE);
   traceline (self.origin,bestorg,TRUE,self);
   dir = normalize ((bestorg - self.origin));
   len = vlen ((bestorg - self.origin));
   bestorg = (self.origin + (dir * ((len * trace_fraction) - KINDA_WANT)));
   below = bestorg;
   below_z = (dropline (below) + TRUE);
   lnd = pointcontents (below);
   if ( (lnd != CONTENT_EMPTY) ) {

      if ( (lnd != CONTENT_WATER) ) {

         if ( (n < MOVETYPE_PUSH) ) {

            return ( chooseRoamTarget ((n + TRUE)) );

         }

      }

   }
   below = (bestorg - (SVC_INTERMISSION * dir));
   below_z = (dropline (below) + TRUE);
   lnd = pointcontents (below);
   if ( (lnd != CONTENT_EMPTY) ) {

      if ( (lnd != CONTENT_WATER) ) {

         if ( (n < MOVETYPE_PUSH) ) {

            return ( chooseRoamTarget ((n + TRUE)) );

         }

      }

   }
   r = (n + (random () * MOVETYPE_WALK));
   if ( ((bestorg_z > self.origin_z) || (r > MOVETYPE_FLY)) ) {

      bestorg_z = (below_z - self.mins_z);

   }
   len = vlen ((bestorg - self.origin));
   if ( (len < KINDA_WANT) ) {

      if ( (n < MOVETYPE_PUSH) ) {

         return ( chooseRoamTarget ((n + TRUE)) );

      }

   }
   return ( bestorg );

};
float (entity e) cacheweight = {

   local float weight;
   local float tw;
   local float dis;
   local float it;

   weight = FALSE;
   if ( (e.lastbot == self) ) {

      if ( (e.lasttime > (time - FL_SWIM)) ) {

         return ( weight );

      }

   }
   dis = vlen ((self.origin - e.origin));
   it = self.items;
   e.pendingcache = world;
   e.pendinglen = FALSE;
   if ( e.rocketcache ) {

      if ( ((e.rocketcache.solid == SOLID_TRIGGER) || (e.rocketcache.nextthink < (time + MOVETYPE_STEP))) ) {

         if ( ((self.rocketcache != e.rocketcache) || (self.rocketlen > e.rocketlen)) ) {

            weight = ((1000000.000 - e.rocketlen) - (FL_SWIM * dis));
            if ( (it & IT_ROCKET_LAUNCHER) ) {

               weight = (weight * 0.500);

            }
            e.pendingcache = e.rocketcache;
            e.pendinglen = e.rocketlen;

         }

      }

   }
   if ( e.lightningcache ) {

      if ( ((e.lightningcache.solid == SOLID_TRIGGER) || (e.lightningcache.nextthink < (time + MOVETYPE_STEP))) ) {

         if ( ((self.lightningcache != e.lightningcache) || (self.lightninglen > e.lightninglen)) ) {

            tw = ((1000000.000 - e.lightninglen) - (FL_SWIM * dis));
            if ( (it & IT_LIGHTNING) ) {

               tw = (tw * 0.500);

            }
            if ( (tw > weight) ) {

               weight = tw;
               e.pendingcache = e.lightningcache;
               e.pendinglen = e.lightninglen;

            }

         }

      }

   }
   if ( (self.armorvalue < 101.000) ) {

      if ( e.armorcache ) {

         if ( ((e.armorcache.solid == SOLID_TRIGGER) || (e.armorcache.nextthink < (time + MOVETYPE_STEP))) ) {

            if ( ((self.armorcache != e.armorcache) || (self.armorlen > e.armorlen)) ) {

               tw = ((1000000.000 - e.armorlen) - (FL_SWIM * dis));
               if ( (tw > weight) ) {

                  weight = tw;
                  e.pendingcache = e.armorcache;
                  e.pendinglen = e.armorlen;

               }

            }

         }

      }

   }
   if ( e.nailcache ) {

      if ( ((e.nailcache.solid == SOLID_TRIGGER) || (e.nailcache.nextthink < (time + FL_SWIM))) ) {

         if ( ((self.nailcache != e.nailcache) || (self.naillen > e.naillen)) ) {

            tw = ((1000000.000 - e.naillen) - (FL_SWIM * dis));
            if ( (it & IT_SUPER_NAILGUN) ) {

               tw = (tw * 0.500);

            }
            if ( (tw > (weight + 2500.000)) ) {

               weight = tw;
               e.pendingcache = e.nailcache;
               e.pendinglen = e.naillen;

            }

         }

      }

   }
   if ( e.grenadecache ) {

      if ( ((e.grenadecache.solid == SOLID_TRIGGER) || (e.grenadecache.nextthink < (time + FL_SWIM))) ) {

         if ( ((self.grenadecache != e.grenadecache) || (self.grenadelen > e.grenadelen)) ) {

            tw = ((1000000.000 - e.grenadelen) - (FL_SWIM * dis));
            if ( (it & IT_GRENADE_LAUNCHER) ) {

               tw = (tw * 0.500);

            }
            if ( (tw > (weight + 2500.000)) ) {

               weight = tw;
               e.pendingcache = e.grenadecache;
               e.pendinglen = e.grenadelen;

            }

         }

      }

   }
   if ( e.powerupcache ) {

      if ( (e.powerupcache.solid == SOLID_TRIGGER) ) {

         if ( ((self.powerupcache != e.powerupcache) || (self.poweruplen > e.poweruplen)) ) {

            tw = ((1000000.000 - e.poweruplen) - (FL_SWIM * dis));
            if ( (tw > weight) ) {

               weight = tw;
               e.pendingcache = e.powerupcache;
               e.pendinglen = e.poweruplen;

            }

         }

      }

   }
   return ( weight );

};
float (entity e) pathweight = {

   local float weight;
   local vector org;

   weight = DONT_WANT;
   if ( TrueReachable (e) ) {

      weight = cacheweight (e);
      if ( (weight > FALSE) ) {

         return ( weight );

      }
      org = e.origin;
      weight = vlen ((self.origin - org));
      weight = ((50.000 * SEARCH_RADIUS) - weight);
      if ( (e.lastbot == self) ) {

         if ( (e.lasttime > (time - MOVETYPE_TOSS)) ) {

            weight = DONT_WANT;

         } else {

            if ( (e.lasttime > (time - LOOPTIME)) ) {

               weight = ((weight - (FL_SWIM * SEARCH_RADIUS)) - (((45.000 * SEARCH_RADIUS) * ((LOOPTIME + e.lasttime) - time)) / LOOPTIME));

            }

         }

      } else {

         if ( teamplay ) {

            if ( (e.lastbot.team == self.team) ) {

               if ( (e.lasttime > (time - 1.200)) ) {

                  weight = DONT_WANT;

               } else {

                  if ( (e.lasttime > (time - FL_SWIM)) ) {

                     weight = (weight - SEARCH_RADIUS);

                  }

               }

            }

         }

      }

   }
   return ( weight );

};

void () goForAir = {

   local vector bestorg;
   local entity botTarget;

   if ( VERBOSEBOT ) {

      dprint (self.teamname);
      dprint (self.netname);
      dprint (" needs air!\n");

   }
   bestorg = self.origin;
   bestorg_z = (bestorg_z + 800.000);
   traceline (self.origin,bestorg,TRUE,self);
   if ( !trace_inopen ) {

      bestorg = chooseRoamTarget (TRUE);
      bestorg_z = (bestorg_z + 200.000);

   }
   botTarget = self.goalentity;
   botTarget.goalentity = botTarget;
   if ( (self.goalentity.classname != "BotTarget") ) {

      objerror ("bad bot target in botgoal! 1\n");

   }
   setorigin (botTarget,bestorg);

};

void (entity item) ageCache = {

   if ( self.rocketcache ) {

      self.rocketlen = (self.rocketlen + TRUE);

   }
   if ( self.lightningcache ) {

      self.lightninglen = (self.lightninglen + TRUE);

   }
   if ( self.armorcache ) {

      self.armorlen = (self.armorlen + TRUE);

   }
   if ( self.powerupcache ) {

      self.poweruplen = (self.poweruplen + TRUE);

   }
   if ( self.nailcache ) {

      self.naillen = (self.naillen + TRUE);

   }
   if ( self.grenadecache ) {

      self.grenadelen = (self.grenadelen + TRUE);

   }
   if ( (item.solid == SOLID_TRIGGER) ) {

      if ( (self.rocketcache == item) ) {

         self.rocketlen = TRUE;

      } else {

         if ( (self.lightningcache == item) ) {

            self.lightninglen = TRUE;

         } else {

            if ( (self.armorcache == item) ) {

               self.armorlen = TRUE;

            } else {

               if ( (self.powerupcache == item) ) {

                  self.poweruplen = TRUE;

               } else {

                  if ( (self.nailcache == item) ) {

                     self.naillen = TRUE;

                  } else {

                     if ( (self.grenadecache == item) ) {

                        self.grenadelen = TRUE;

                     }

                  }

               }

            }

         }

      }

   }

};

void () resetCache = {

   self.pendingcache = world;
   self.pendinglen = FALSE;
   if ( self.rocketcache ) {

      if ( (self.rocketcache.solid == SOLID_NOT) ) {

         self.rocketcache = world;
         self.rocketlen = FALSE;

      }

   }
   if ( self.lightningcache ) {

      if ( (self.lightningcache.solid == SOLID_NOT) ) {

         self.lightningcache = world;
         self.lightninglen = FALSE;

      }

   }
   if ( self.armorcache ) {

      if ( (self.armorcache.solid == SOLID_NOT) ) {

         self.armorcache = world;
         self.armorlen = FALSE;

      }

   }
   if ( self.powerupcache ) {

      if ( (self.powerupcache.solid == SOLID_NOT) ) {

         self.powerupcache = world;
         self.poweruplen = FALSE;

      }

   }
   if ( self.nailcache ) {

      if ( (self.nailcache.solid == SOLID_NOT) ) {

         self.nailcache = world;
         self.naillen = FALSE;

      }

   }
   if ( self.grenadecache ) {

      if ( (self.grenadecache.solid == SOLID_NOT) ) {

         self.grenadecache = world;
         self.grenadelen = FALSE;

      }

   }

};

void () updateBotCache = {

   if ( self.pendingcache.th_update ) {

      self.pendingcache.th_update ();

   } else {

      if ( cached_developer ) {
         dprint ("Error - no think update for ");
         dprint (self.pendingcache.classname);
         dprint ("\n");
      }

   }
   self.pendingcache = world;
   self.pendinglen = FALSE;

};

void () aibot_chooseGoal = {

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

   botTarget = self.goalentity;
   if ( (self.lefty & FAR_SEEK) ) {

      self.lefty = ((self.lefty - (self.lefty & LOCAL_TIME)) - FAR_SEEK);

   }
   if ( (self.lefty & ONTRAIN) ) {

      self.lefty = (self.lefty - ONTRAIN);

   }
   // FIX: Saturating increment — prevents counter bits bleeding into flag bits
   if ( (self.lefty & LOCAL_TIME) < LOCAL_TIME )
      self.lefty = (self.lefty + TRUE);
   current = botTarget.goalentity;
   self.search_time = (time + 1.500 + ((10.000 - self.skil) * 0.200));
   best = DONT_WANT;
   OK_NOTVIS = FALSE;
   if ( (self.air_finished < (time + MOVETYPE_FLYMISSILE)) ) {

      goForAir ();
      return ;

   }
   if ( ((self.lefty & LOCAL_TIME) < MOVETYPE_FLY) ) {

      e = findradius (self.origin,SEARCH_RADIUS);
      while ( e ) {

         weight = DONT_WANT;
         if ( (e == current) ) {

            weight = DONT_WANT;

         } else {

            if ( e.pathtype ) {

               weight = DONT_WANT;

            } else {

               if ( (e.solid == SOLID_NOT) ) {

                  // FIX #2: Skill 3+ bots anticipate items about to respawn
                  // Travel-aware window: start heading to item when ETA <= travel time + 3s buffer
                  if ( (self.skil >= 3) && (e.think == SUB_regen) && (e.nextthink > 0) ) {
                     local float spawn_eta;
                     local float travel_time;
                     local float timing_window;
                     spawn_eta = e.nextthink - time;
                     travel_time = vlen (((e.absmin + e.absmax) * 0.500) - self.origin) * 0.003333;  // dist / 300 speed
                     timing_window = travel_time + 3;
                     if ( timing_window < 10 ) timing_window = 10;
                     if ( spawn_eta <= timing_window ) {
                        if ( (e.classname == "item_artifact_super_damage") || (e.classname == "item_artifact_invulnerability") ) {
                           weight = 250 * ((timing_window - spawn_eta) / timing_window);
                           if ( weight < MUST_HAVE ) weight = MUST_HAVE;
                        } else {
                           weight = KINDA_WANT * ((timing_window - spawn_eta) / timing_window);
                        }
                        if ( (weight > best) ) {
                           botTarget.goalentity = e;
                           best = weight;
                           bestorg = ((e.absmin + e.absmax) * 0.500);
                        }
                        e = e.chain;
                        continue;
                     }
                  }
                  // PASS #13: Item timer memory — even without nextthink, bots remember pickup times
                  // Adds imprecision based on skill (lower skill = fuzzier memory)
                  if ( self.skil >= 3 ) {
                     local float pickup_time;
                     pickup_time = BotGetItemTimer (self, e);
                     if ( pickup_time > 0 ) {
                        local float mem_eta;
                        local float mem_travel;
                        local float mem_noise;
                        local float noise_range;
                        noise_range = (10 - self.skil * 2);
                        if ( noise_range < 0 ) noise_range = 0;
                        mem_noise = (random() - 0.5) * noise_range;
                        // Standard respawn: 20s for powerups, 20s for armor/mega in DM
                        mem_eta = (pickup_time + 20 + mem_noise) - time;
                        mem_travel = vlen(((e.absmin + e.absmax) * 0.5) - self.origin) * 0.003333;
                        if ( mem_eta > 0 && mem_eta < mem_travel + 5 ) {
                           weight = MUST_HAVE;
                           if ( (weight > best) ) {
                              botTarget.goalentity = e;
                              best = weight;
                              bestorg = ((e.absmin + e.absmax) * 0.500);
                           }
                           e = e.chain;
                           continue;
                        }
                     }
                  }
                  weight = DONT_WANT;

               } else {

                  if ( (e.solid == SOLID_TRIGGER) ) {

                     if ( e.istrigger ) {

                        weight = trigweight (e);

                     } else {

                        weight = itemweight (e);

                     }

                  } else {

                     weight = thingweight (e);

                  }

               }

            }

         }
         if ( (weight > (KINDA_WANT - MOVETYPE_FLY)) ) {

            if ( (weight < (WANT + FL_SWIM)) ) {

               if ( ((e.absmin_z + MAXJUMP) < self.absmin_z) ) {

                  weight = (KINDA_WANT - MOVETYPE_FLY);

               }

            }

         }
         if ( (weight > DONT_WANT) ) {

            org = ((e.absmin + e.absmax) * 0.500);
            org_z = (e.absmin_z + TRUE);
            if ( (((e.classname == "plat") || (e.classname == "func_plat")) || (e.classname == "train")) ) {

               org_z = (e.absmax_z + TRUE);

            }
            // Distance bonus: closer items score higher (up to +20 at point blank)
            d2 = vlen ((self.origin - org));
            weight = (weight + (20.000 * (1.000 - (d2 / SEARCH_RADIUS))));

            // ADAPTIVE TACTICS: Match phase modulates item priorities
            if ( self.match_phase == 0 ) {
               // SCRAMBLE: weapon priority boost
               if ( e.classname == "weapon_rocketlauncher" || e.classname == "weapon_lightning" )
                  weight = weight + 20;
            } else if ( self.match_phase == 1 ) {
               // CONTROL: armor priority for map control
               if ( e.classname == "item_armor2" || e.classname == "item_armorInv" )
                  weight = weight + 15;
            } else if ( self.match_phase == 2 ) {
               // ENDGAME: powerup denial is critical
               if ( e.classname == "item_artifact_super_damage" || e.classname == "item_artifact_invulnerability" )
                  weight = weight + 30;
            }

            if ( (weight == best) ) {

               d1 = vlen ((self.origin - bestorg));
               d2 = vlen ((self.origin - org));
               weight = ((weight + (random () * MOVETYPE_FLY)) - FL_SWIM);
               if ( (d1 < d2) ) {

                  weight = (weight - TRUE);

               }
               if ( (weight > best) ) {

                  weight = best;
                  best = (best - TRUE);

               }

            }
            if ( (weight > best) ) {

               botTarget.goalentity = e;
               best = weight;
               bestorg = org;

            }

         }
         e = e.chain;

      }

   }
   resetCache ();
   if ( (best < (KINDA_WANT - MOVETYPE_WALK)) ) {

      if ( (best > DONT_WANT) ) {

         best = (1000000.000 - 900.000);

      }
      e = findradius (self.origin,SEARCH_RADIUS);
      best = DONT_WANT;
      while ( e ) {

         if ( ((e.pathtype == DROPPED) || (e.pathtype == TELEPORT)) ) {

            if ( (e == current) ) {

               weight = DONT_WANT;

            } else {

               weight = pathweight (e);

            }
            if ( (weight > best) ) {

               best = weight;
               botTarget.goalentity = e;
               self.pendingcache = e.pendingcache;
               self.pendinglen = e.pendinglen;
               bestorg = e.origin;
               if ( !bestorg ) {

                  bestorg = ((e.absmin + e.absmax) * 0.500);
                  bestorg_z = (e.absmin_z + TRUE);

               }
               self.lefty = (self.lefty | FAR_SEEK);

            }

         }
         e = e.chain;

      }

   }
   if ( (best > DONT_WANT) ) {

      if ( self.pendingcache ) {

         updateBotCache ();

      } else {

         if ( (botTarget.goalentity.classname != "BotPath") ) {

            ageCache (botTarget.goalentity);

         }

      }

   }
   if ( (best <= DONT_WANT) ) {

      botTarget.goalentity = botTarget;
      bestorg = chooseRoamTarget (FALSE);
      self.lefty = (self.lefty | FAR_SEEK);
      self.search_time = (time + FL_SWIM);

   }
   if ( VERBOSEBOT ) {

      dprint (self.teamname);
      dprint (self.netname);
      dprint (" going after ");
      dprint (botTarget.goalentity.classname);
      dprint ("\n");

   }
   if ( botTarget.goalentity ) {

      if ( (botTarget.goalentity != botTarget) ) {

         botTarget.goalentity.lastbot = self;
         botTarget.goalentity.lasttime = time;

      }

   }
   if ( (botTarget.goalentity.classname == "func_button") ) {

      bestorg = ((bestorg - botTarget.goalentity.pos2) - (FL_MONSTER * normalize (botTarget.goalentity.pos2)));

   }
   if ( (botTarget.classname != "BotTarget") ) {

      objerror ("bad bot target in botgoal! 2\n");

   }
   setorigin (botTarget,bestorg);

};
float (entity e) RunAwayWeight = {

   local float weight;

   if ( !TrueReachable (e) ) {

      return ( FALSE );

   }
   weight = FALSE;
   traceline ((self.enemy.origin + self.enemy.view_ofs),e.origin,TRUE,self.enemy);
   if ( (trace_fraction != TRUE) ) {

      weight = WANT;

   }
   if ( (trace_inopen && trace_inwater) ) {

      weight = (WANT - MOVETYPE_FLY);

   }
   weight = (weight + (0.100 * vlen ((self.enemy.origin - e.origin))));
   weight = (weight + (KINDA_WANT * random ()));
   return ( weight );

};

void (entity en) RouteToEnemy;
entity (entity chaser, entity en) BestChaseRoute = {

   local entity e;
   local entity p;
   local entity tmp;
   local float weight;
   local float best;
   local entity mandatory;

   if ( (en.classname == "item_artifact_super_damage") || (en.classname == "item_artifact_invulnerability") ) {
      mandatory = FindMandatoryWaypoint (chaser);
      if ( (mandatory != world) ) {
         return ( mandatory );
      }
   }

   RouteToEnemy (en);
   e = findradius (chaser.origin,SEARCH_RADIUS);
   best = 1000000.000;
   p = en;
   tmp = self;
   self = chaser;
   while ( e ) {

      if ( ((e.pathtype == DROPPED) || (e.pathtype == TELEPORT)) ) {

         weight = 1000000.000;
         if ( (e.enemycache == en) ) {

            if ( TrueReachable (e) ) {

               weight = (e.enemylen + (vlen ((self.origin - e.origin)) * 0.500));

            }

         }
         if ( (weight < best) ) {

            best = weight;
            p = e;

         }

      }
      e = e.chain;

   }
   self = tmp;
   return ( p );

};
