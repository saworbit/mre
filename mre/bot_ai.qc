
// Forward declarations for functions used before they're defined
float (float minweight) aibot_checkforGoodies;
float (float ideal_yaw, float speed_factor) BotSteer;
void () BotReflexDodge;
void () BotCheckCuriosity;  // Curiosity system (defined in botmove.qc)
void () BotBlindFire;       // Tactical: Pre-fire at corners (defined in botfight.qc)
float () BotCheckEnvironmentKill;  // Tactical: Displacement kills (defined in botfight.qc)
void () BotDirectFire;      // Direct fire without animation (defined in botfight.qc)
float () W_BestBotWeapon;   // Weapon scoring (defined in botfight.qc)
void () W_SetCurrentAmmo;   // Update ammo display (defined in weapons.qc)
float (vector spot) BotDetectHazard;  // Hazard check (defined in botmove.qc)
void (entity enemy, float dist) BotShadowCombatThink; // Shadow Puppets combat (ai_predict.qc)
void (entity source, vector org, float volume, float type) Bot_BroadcastNoise;
void () Bot_AnalyzeSound;
entity () Spectral_FindPlayer;
entity (entity target) SpawnPhantom;
void () MirageTick;
float (entity foe) Slayer_UserBias;
float (entity foe) Slayer_IsUser;
float () Slayer_GodMode;

// =============================================================================
// SENSORY AWARENESS: Sound-based alerting system
// Bots can "hear" combat sounds and investigate them
// =============================================================================

// Alert all bots within hearing range to a sound
// source_loc: where the sound originated
// volume: hearing range in units (1000 for rockets, 800 for grenades, 600 for SNG)
// priority: importance of the sound (100 = weapon fire, 50 = item pickup)
void (vector source_loc, float volume, float priority) Bot_AlertNoise = {

   local entity bot;
   local float dist;
   local float effective_dist;

   // FIX: Removed redundant Bot_BroadcastNoise call — it did a second bot-list walk
   // with a different (simpler) hearing model. We now set heard_sound_* fields directly
   // in this single loop, using the better wall-attenuation model.

   // OPT: Walk cached bot linked list instead of find()
   bot = bot_list_head;
   while ( bot ) {
      if ( (bot.health > FALSE) && (bot != self) ) {
         // Calculate distance (cheap cull before LOS trace)
         dist = vlen (source_loc - bot.origin);
         if ( dist > volume ) {
            bot = bot.bot_next;
            continue ;
         }

         // Simple wall attenuation: sounds through walls are harder to hear
         traceline (bot.origin + bot.view_ofs, source_loc, TRUE, bot);
         if ( (trace_fraction < TRUE) ) {
            // Sound is blocked by geometry - reduce effective hearing
            effective_dist = dist * 1.5;
         } else {
            effective_dist = dist;
         }

         // If within hearing range
         if ( (effective_dist < volume) ) {
            // Set heard_sound fields (previously done by Bot_BroadcastNoise)
            bot.heard_sound_time = time;
            bot.heard_sound_loc = source_loc;
            bot.heard_sound_type = NOISE_WEAPON;
            bot.heard_sound_weapon = self.weapon;

            // Only distract if not fighting a visible enemy
            if ( (bot.enemy == world) || !enemyvisible (bot.enemy) ) {
               // Only update if this sound is more important or more recent
               if ( (priority >= bot.noise_priority) || (time > (bot.noise_time + 2.0)) ) {
                  bot.noise_target = source_loc;
                  bot.noise_time = time;
                  bot.noise_priority = priority;
                  bot.investigating = TRUE;

                  if ( cached_developer ) {
                     dprint ("[");
                     dprint (bot.netname);
                     dprint ("] HEARD: Combat at ");
                     dprint (vtos(source_loc));
                     dprint ("\n");
                  }
               }
            }
         }
      }
      bot = bot.bot_next;
   }

};

// Analyze the most recent heard sound and infer intent
void () Bot_AnalyzeSound = {

   local float sound_age;
   local float dist;

   if ( (self.heard_sound_time <= FALSE) ) {
      return ;
   }
   sound_age = time - self.heard_sound_time;
   if ( (sound_age > 2.000) ) {
      // FIX: Clear investigating flag when sound expires — prevents permanent investigate state
      self.investigating = FALSE;
      return ;
   }
   if ( self.enemy && enemyvisible (self.enemy) ) {
      return ;
   }
   // ADAPTIVE TACTICS: Weapon sound inference
   // Infer enemy weapon from sound and adjust investigation caution
   if ( (self.heard_sound_type == NOISE_WEAPON) ) {
      if ( self.skil >= 2 ) {
         local float heard_dist;
         heard_dist = vlen(self.heard_sound_loc - self.origin);
         if ( heard_dist < 800 ) {
            local float heard_weap;
            heard_weap = self.heard_sound_weapon;

            // RL/GL heard nearby while weak: cautious investigation
            if ( (heard_weap == IT_ROCKET_LAUNCHER || heard_weap == IT_GRENADE_LAUNCHER) && self.eff_hp < 60 ) {
               self.noise_target = self.heard_sound_loc;
               self.noise_time = time;
               self.noise_priority = 30;  // low priority = cautious
               self.investigating = TRUE;
               return;
            }
            // Weak weapon heard while strong: aggressive push
            if ( (heard_weap & (IT_SHOTGUN + IT_NAILGUN + IT_AXE)) && self.eff_hp > 80 && (self.items & (IT_ROCKET_LAUNCHER + IT_LIGHTNING)) ) {
               self.noise_target = self.heard_sound_loc;
               self.noise_time = time;
               self.noise_priority = 90;  // high priority = push
               self.investigating = TRUE;
               return;
            }
            // Default: investigate normally
            self.noise_target = self.heard_sound_loc;
            self.noise_time = time;
            self.noise_priority = 50;
            self.investigating = TRUE;
         }
      }
      return;
   }
   if ( (self.heard_sound_type == NOISE_ITEM) ) {
      if ( (self.health > 80.000) && (self.items & IT_ROCKET_LAUNCHER) ) {
         self.noise_target = self.heard_sound_loc;
         self.noise_time = time;
         self.noise_priority = 80.000;
         self.investigating = TRUE;
      } else {
         self.ideal_yaw = vectoyaw (self.origin - self.heard_sound_loc);
         ChangeYaw ();
      }
      return ;
   }
   if ( (self.heard_sound_type == NOISE_WATER) ) {
      self.noise_target = self.heard_sound_loc;
      self.noise_time = time;
      self.noise_priority = 70.000;
      self.investigating = TRUE;
      self.ideal_yaw = vectoyaw (self.heard_sound_loc - self.origin);
      ChangeYaw ();
      dist = vlen (self.heard_sound_loc - self.origin);
      if ( (self.items & IT_ROCKET_LAUNCHER) && (dist < 600.000) ) {
         self.v_angle_y = self.ideal_yaw;
         BotDirectFire ();
      }
      return ;
   }
   if ( (self.heard_sound_type == NOISE_STEP) ) {
      self.noise_target = self.heard_sound_loc;
      self.noise_time = time;
      self.noise_priority = 40.000;
      self.investigating = TRUE;
      return ;
   }

   self.ideal_yaw = vectoyaw (self.heard_sound_loc - self.origin);
   ChangeYaw ();

};

// Simplified version for quick calls (uses default priority)
void (vector source_loc, float volume) Bot_AlertNoiseSimple = {

   Bot_AlertNoise (source_loc, volume, 100);

};

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
   self.dmg_dealt = 0;
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

   HELPING = TRUE;
   e = bot_list_head;  // OPT: cached bot linked list
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
      e = e.bot_next;

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

      // Even armed bots should flee when critically wounded
      if ( self.eff_hp > 40.000 ) {
         return ( FALSE );
      }
      // Below 40 eff HP with good weapon: coin flip to survive
      if ( random () < 0.600 ) {
         return ( TRUE );
      }
      return ( FALSE );

   }
   if ( (self.items & IT_QUAD) ) {

      if ( self.eff_hp > 25.000 ) {

         return ( FALSE );

      }

   }
   // Quad holders don't gradually retreat - fight to the death
   if ( (self.items & IT_QUAD) ) {
      return ( FALSE );
   }
   // Gradual retreat: probability increases as effective health drops
   if ( (self.eff_hp < 60.000) ) {
      local float retreat_chance;
      retreat_chance = ((60.000 - self.eff_hp) / 60.000);
      // Score pressure: losing bots fight harder, winning bots play safer
      if ( self.enemy ) {
         local float score_diff;
         score_diff = self.frags - self.enemy.frags;
         if ( score_diff < -5 ) {
            retreat_chance = retreat_chance * 0.500;
         } else if ( score_diff > 5 ) {
            retreat_chance = retreat_chance * 1.300;
         }
      }
      if ( (random () < retreat_chance) ) {
         return ( TRUE );
      }
   }
   if ( (weap & ((IT_SHOTGUN + IT_AXE) + IT_NAILGUN)) ) {

      if ( (self.enemy.items & IT_QUAD) ) {

         return ( TRUE );

      }
      if ( (self.enemy.weapon & ((IT_ROCKET_LAUNCHER + IT_LIGHTNING) + IT_SUPER_NAILGUN)) ) {

         return ( TRUE );

      }

   }
   // Even with good weapons, flee enemy Quad if not tanky
   if ( (self.enemy.items & IT_QUAD) ) {
      if ( self.eff_hp < 80.000 ) {
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
   self.combat_entry_time = time;
   self.push_start_aggro = self.aggression;  // PASS #13: Track aggro at engagement start
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
   // FIX: Removed excessive attack_finished delay (was 0.7-0.1s per skill).
   // Bot_CheckReaction already gates first shot via fire_delay (0.0-0.3s).
   // The old 0.7s at skill 0 caused ~1s of staring before first shot.
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
   local float dist;

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

   // Distance-aware response: react faster when the target is close
   dist = vlen (self.pending_enemy.origin - self.origin);
   if ( dist < 150.000 ) {
      delay = (delay * 0.250);
   } else if ( dist < 300.000 ) {
      delay = (delay * 0.500);
   }

   // Recent noise: tighten reaction window slightly
   if ( (self.noise_priority >= 50.000) && (time < (self.noise_time + 0.300)) ) {
      delay = (delay * 0.500);
   }

   // Check if reaction time has passed
   if ( (time >= (self.reaction_time + delay)) ) {

      // Promote pending to active enemy
      self.enemy = self.pending_enemy;
      self.pending_enemy = world;
      // Delay first shot — skill 0: 300ms, skill 4+: 0ms
      local float fire_delay;
      fire_delay = (0.300 - (self.skil * 0.075));
      if ( fire_delay > FALSE ) {
         self.attack_finished = (time + fire_delay);
      }
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
   // FIX: Added return + else guards to prevent fall-through causing double-switch
   if ( !enemyvisible (self.enemy) ) {

      endEnemy ();
      self.enemy = en2;
      BotFoundTarget ();
      return ;

   }
   else if ( (en2.weapon & (IT_LIGHTNING + IT_ROCKET_LAUNCHER)) ) {

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

      self.lastbot = bot_list_head;  // OPT: cached bot linked list

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
      self.lastbot = bots.bot_next;  // OPT: walk linked list
      if ( !self.lastbot ) {

         self.lastbot = bot_list_head;  // OPT: wrap around

      }

   }
   return ( FALSE );

};

// FIX: Helper function to validate if a target is attackable
// Encapsulates all the checks from original BotFindTarget
float (entity targ) BotValidTarget = {

   local float dist;

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

   // Early distance cull before expensive visibility checks
   dist = vlen (targ.origin - self.origin);
   if ( (dist > 1200.000) && !hearnoise (targ) ) {

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

// Helper: compute threat-aware score for target selection
// Lower score = higher priority target
float (entity head, float dist) BotThreatScore = {

   local float adj_dist;
   local float ehp;
   local float shp;
   local vector dir_to_me;
   local float face_dot;

   adj_dist = dist;
   ehp = (head.health + (head.armorvalue * head.armortype));
   shp = self.eff_hp;  // OPT: use cached value
   // Prefer weaker enemies
   if ( (ehp < shp) && (shp > 0.000) ) {
      adj_dist = (dist * (0.500 + (ehp / (shp * 2.000))));
   }
   // Avoid powerup carriers
   if ( head.items & IT_QUAD ) {
      adj_dist = (adj_dist * 1.500);
   }
   if ( head.items & IT_INVULNERABILITY ) {
      adj_dist = (adj_dist * 3.000);
   }
   // Threat scoring: weapon danger + facing angle
   dir_to_me = normalize (self.origin - head.origin);
   makevectors (head.angles);
   face_dot = (dir_to_me * v_forward);
   if ( (face_dot > 0.700) ) {
      adj_dist = (adj_dist - (100 * face_dot));
   }
   if ( (head.weapon == IT_ROCKET_LAUNCHER) || (head.weapon == IT_LIGHTNING) ) {
      adj_dist = (adj_dist - 80);
   } else if ( (head.weapon == IT_SUPER_NAILGUN) ) {
      adj_dist = (adj_dist - 40);
   }

   // FIX #5: Target deconfliction — penalize targets already engaged by other bots
   // Prevents all bots from ganging up on the same enemy, spreads aggression
   local entity other_bot;
   other_bot = bot_list_head;
   while ( other_bot ) {
      if ( (other_bot != self) && (other_bot.enemy == head) && (other_bot.health > 0) ) {
         adj_dist = adj_dist + 200;
      }
      other_bot = other_bot.bot_next;
   }

   // PASS #13: Grudge override — massive priority boost for revenge target
   if ( head == self.grudge_target )
      adj_dist = adj_dist - 200;

   return ( adj_dist );

};

// Target acquisition: use checkclient() for players and cached bot list to avoid full entity scans
float /* Warning: Could not determine return type */ () BotFindTarget = {

   local entity head;
   local entity best;
   local float dist;
   local float best_dist;
   local float limit;
   local float scan_cap;
   local float throttle;
   local float throttle_override;

   // Throttle redundant scans in the same frame/tick (skill-scaled)
   throttle_override = cvar ("bot_target_throttle");
   if ( (throttle_override > 0.000) ) {
      throttle = throttle_override;
   } else {
      throttle = (0.050 - (self.skil * 0.005));
   }
   if ( (throttle < 0.020) ) throttle = 0.020;
   if ( (throttle > 0.050) ) throttle = 0.050;
   if ( (self.enemy == world) && (self.last_seen_time > 0.000) && (time < (self.last_seen_time + 0.600)) ) {
      throttle = FALSE; // recent contact: don't delay reacquire
   }
   if ( (self.noise_priority >= 50.000) && (time < (self.noise_time + 0.300)) ) {
      throttle = FALSE; // recent noise: tighten reacquire window
   }
   if ( (throttle > FALSE) && (time < self.target_scan_time) ) {
      return ( FALSE );
   }
   if ( throttle > FALSE ) {
      self.target_scan_time = (time + throttle);
   } else {
      self.target_scan_time = time;
   }

   best = world;
   best_dist = 100000;

   // ADAPTIVE TACTICS: Reset visible threat counter for multi-threat awareness
   self.visible_threats = 0;

   // Target momentum: new target must beat current by 150u margin
   if ( (self.enemy != world) && (self.enemy.health > 0) ) {
      best_dist = vlen (self.enemy.origin - self.origin) - 150;
      // Finish the kill: don't switch off near-dead enemy
      if ( (self.enemy.health + (self.enemy.armorvalue * self.enemy.armortype)) < 20 ) {
         best_dist = best_dist - 300;
      }
   }

   // Scan human players via checkclient (fast, avoids full entity walk).
   limit = fMaxClients;
   if ( (limit < TRUE) ) {

      limit = 16.000;

   }
   // Time-slice checkclient: scan a capped subset each call
   scan_cap = (4.000 + floor (self.skil));
   if ( (scan_cap > 8.000) ) {
      scan_cap = 8.000;
   }
   if ( (scan_cap > limit) ) {
      scan_cap = limit;
   }
   while ( (scan_cap > FALSE) ) {

      scan_cap = (scan_cap - TRUE);
      head = checkclient ();
      if ( head ) {

         if ( BotValidTarget (head) ) {

            dist = vlen (head.origin - self.origin);
            // Only count nearby threats (600u) for multi-threat aggression penalty.
            // Seeing bots across the map shouldn't make you feel outnumbered.
            if ( dist < 600 )
               self.visible_threats = self.visible_threats + 1;
            local float score;
            score = BotThreatScore (head, dist);
            if ( score < best_dist ) {

               best_dist = score;
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
         // Only count nearby threats (600u) for multi-threat aggression penalty
         if ( dist < 600 )
            self.visible_threats = self.visible_threats + 1;
         local float score2;
         score2 = BotThreatScore (head, dist);
         if ( score2 < best_dist ) {

            best_dist = score2;
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
   local float flow_yaw;

   // 0. CURIOSITY: Check if we're looking at something shootable
   // This lets bots discover secrets and open doors
   BotCheckCuriosity ();

   // 1. Scan for items to give them purpose (Greedy Roaming)
   // Low weight threshold so they lazily pick up nearby stuff
   if ( aibot_checkforGoodies (20.000) ) {
      return;
   }

   // 2. If no items, pick a random direction occasionally
   // Change direction every 1-3 seconds or if hitting a wall
   if ( (self.search_time < time) || !walkmove (self.ideal_yaw, 0.000) ) {
      // FIX #14: During CONTROL phase, bias roaming toward nearest item spawn
      if ( self.match_phase == 1 && self.skil >= 2 ) {
         local entity scan;
         local float best_idist;
         local entity best_item;
         best_idist = 99999;
         best_item = world;
         scan = findradius (self.origin, 1500);
         while ( scan ) {
            if ( scan.solid == SOLID_TRIGGER && (scan.flags & FL_ITEM) ) {
               local float idist;
               idist = vlen (scan.origin - self.origin);
               if ( idist < best_idist ) {
                  best_idist = idist;
                  best_item = scan;
               }
            }
            scan = scan.chain;
         }
         if ( best_item != world ) {
            self.ideal_yaw = vectoyaw (best_item.origin - self.origin);
         } else {
            self.ideal_yaw = random () * 360;
         }
      } else {
         self.ideal_yaw = random () * 360;
      }
      self.search_time = time + 1 + (random () * 2);
      ChangeYaw ();
   }

   // 3. Smoothly rotate towards interest points (slight look wander)
   if ( random () < 0.100 ) {
      self.ideal_yaw = self.ideal_yaw + (random () * 30) - 15;
      ChangeYaw ();
   }

   // 4. ROBUST FLOW MOVEMENT with human speed variance
   // Get the steering suggestion (0.6 = slower speed factor for roaming)
   local float orig_yaw;
   orig_yaw = self.ideal_yaw;
   flow_yaw = BotSteer (self.ideal_yaw, 0.6);

   // If whiskers suggest a new direction (obstacle avoidance), accept it
   if ( flow_yaw != self.ideal_yaw ) {
      self.ideal_yaw = flow_yaw;
      ChangeYaw ();
   }

   // Base roaming speed with mood-based variance (180-240 range)
   local float roam_speed;
   roam_speed = 180.000 + (random () * 60.000);

   // Slow down near corners (whiskers adjusted direction)
   if ( flow_yaw != orig_yaw ) {
      roam_speed = roam_speed * 0.700;
   }

   // Occasional micro-pause (2% chance): human "listening" behavior
   if ( random () < 0.020 ) {
      roam_speed = roam_speed * 0.200;
      // Look around during pause
      self.ideal_yaw = self.ideal_yaw + (random () * 60.000) - 30.000;
      ChangeYaw ();
   }

   roam_dist = roam_speed * BOT_IDLE_THINK;

   // Call robust movement function with the steered angle
   if ( !botwalkmove (self.ideal_yaw, roam_dist) ) {
      // If we STILL hit something despite steering (dead end),
      // force a full direction change immediately
      self.search_time = time - 1;
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

   if ( (self.shadow_combat_time > time) && (self.shadow_combat_yaw != 9999.000) ) {
      self.ideal_yaw = self.shadow_combat_yaw;
   } else {
      self.ideal_yaw = vectoyaw ((self.enemy.origin - self.origin));
   }
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
   local float user_bias;

   trn = turn;

   // PASS #13: Decision hesitation — temporary movement freeze
   if ( time < self.hesitation_time ) {
      // Bot is hesitating — hold position but keep fighting
      if ( self.attack_state == AS_MELEE ) aibot_run_melee ();
      CheckBotAttack ();
      return;
   }

   // PASS #13: Mid-push abort — aggression dropped significantly since engagement started
   // Safety: hesitation_time doubles as cooldown — only triggers when fully expired (+1s gap)
   if ( self.push_start_aggro > 0 && self.hesitation_time < time - 1.0 ) {
      if ( self.aggression < self.push_start_aggro - 0.2 ) {
         // "Oh crap" moment — ~1% per frame chance to freeze briefly
         if ( random() < 0.01 ) {
            self.hesitation_time = time + 0.2 + random() * 0.2;
            self.push_start_aggro = 0;
         }
      }
   }

   // PASS #13: Spawn awareness — glance toward spawn points after a kill
   if ( time < self.spawn_watch_time && self.skil >= 3 && !self.enemy ) {
      if ( random() < 0.01 ) {
         local entity sw_sp;
         local entity sw_best;
         local float sw_d, sw_best_d;
         sw_best = world;
         sw_best_d = 1200;
         sw_sp = find (world, classname, "info_player_deathmatch");
         while ( sw_sp ) {
            sw_d = vlen (sw_sp.origin - self.origin);
            if ( sw_d < sw_best_d && sw_d > 100 ) {
               traceline (self.origin + self.view_ofs, sw_sp.origin, TRUE, self);
               if ( trace_fraction == 1.0 ) {
                  sw_best_d = sw_d;
                  sw_best = sw_sp;
               }
            }
            sw_sp = find (sw_sp, classname, "info_player_deathmatch");
         }
         if ( sw_best != world )
            self.ideal_yaw = vectoyaw (sw_best.origin - self.origin);
      }
   }

   // Combat entry stutter: brief hesitation when first engaging
   // Humans need a moment to process a new combat encounter
   if ( (self.combat_entry_time > FALSE) && (time < (self.combat_entry_time + 0.200)) ) {
      local float entry_frac;
      entry_frac = ((time - self.combat_entry_time) / 0.200);
      dist = (dist * (0.400 + (entry_frac * 0.600)));
   }

   // OPT: Compute enemy delta once, cache distance for W_BestHeldWeapon reuse
   local vector enemy_delta;
   enemy_delta = self.enemy.origin - self.origin;
   self.cached_enemy_dist = vlen (enemy_delta);
   self.ideal_yaw = vectoyaw (enemy_delta);
   ChangeYaw ();

   // Weapon-range engagement: gentle nudge toward optimal distance
   // ADAPTIVE TACTICS: Distance also adapts to enemy's weapon and aggression
   if ( self.enemy ) {
      local float opt_dist;
      local float cur_dist;
      opt_dist = 400;
      if ( self.weapon == IT_LIGHTNING ) opt_dist = 250;
      else if ( self.weapon == IT_SUPER_NAILGUN ) opt_dist = 350;
      else if ( self.weapon == IT_ROCKET_LAUNCHER ) opt_dist = 500;
      else if ( self.weapon == IT_SUPER_SHOTGUN ) opt_dist = 200;

      // Adapt distance based on enemy weapon (skill 2+)
      if ( self.skil >= 2 ) {
         local float en_weap_dist;
         en_weap_dist = self.enemy.weapon;
         // Enemy has LG: stay far (outside effective LG range ~450u)
         if ( en_weap_dist == IT_LIGHTNING )
            opt_dist = opt_dist + 100;
         // Enemy has RL: close gap (rockets easier to dodge up close)
         else if ( en_weap_dist == IT_ROCKET_LAUNCHER )
            opt_dist = opt_dist - 80;
         // Enemy has SSG: maintain distance (SSG falls off fast)
         else if ( en_weap_dist == IT_SUPER_SHOTGUN )
            opt_dist = opt_dist + 60;
         // Enemy has weak weapons: push aggressively
         else if ( en_weap_dist & (IT_SHOTGUN + IT_AXE + IT_NAILGUN) )
            opt_dist = opt_dist - 100;

         // Modulate by aggression score
         opt_dist = opt_dist + (0.5 - self.aggression) * 150;

         if ( opt_dist < 100 ) opt_dist = 100;
         if ( opt_dist > 800 ) opt_dist = 800;
      }

      cur_dist = self.cached_enemy_dist;  // OPT: reuse cached distance
      if ( cur_dist > (opt_dist + 100) ) {
         botwalkmove(self.ideal_yaw, dist * 0.300);
      } else if ( cur_dist < (opt_dist - 100) ) {
         // FIX: raw walkmove for backward movement — botwalkmove whiskers fight it
         local float back_yaw;
         back_yaw = vectoyaw(self.origin - self.enemy.origin);
         if ( !walkmove(back_yaw, dist * 0.300) )
            if ( !walkmove(back_yaw + 45, dist * 0.200) )
               walkmove(back_yaw - 45, dist * 0.200);
      }
   }

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
   // FIX #12: Widened cover traces (32u→80u) for realistic cover-seeking
   cover_left = (self.origin - (v_right * 80.000));
   cover_right = (self.origin + (v_right * 80.000));
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
   weap = W_BestHeldWeapon ();

   // ADAPTIVE TACTICS: Cautious aggression modulates strafe willingness
   // Low aggression → bias toward backing off (higher rdir = more evasive)
   if ( self.aggression < 0.5 ) {
      rdir = rdir + (0.5 - self.aggression) * 0.8;
   }

   // Splash-safe spacing: bias to backpedal/strafe before firing RL/GL at close range
   if ( ((weap == IT_ROCKET_LAUNCHER) || (weap == IT_GRENADE_LAUNCHER)) && enemyvisible (self.enemy) ) {
      if ( (self.cached_enemy_dist < 180.000) ) {
         // FIX: raw walkmove for backward movement — botwalkmove whiskers fight it
         local float splash_back;
         splash_back = self.ideal_yaw + 180;
         if ( walkmove(splash_back, dis) ) {
            return ;
         }
         if ( walkmove(splash_back + 45, dis * 0.700) ) {
            return ;
         }
         if ( walkmove(splash_back - 45, dis * 0.700) ) {
            return ;
         }
         rdir = (rdir + 1.000);
      }
   }

   // Slayer Eclipse: dodge matrix bias for learned user strafes
   if ( self.enemy && Slayer_IsUser (self.enemy) && (cvar ("user_learn") > FALSE) ) {
      user_bias = Slayer_UserBias (self.enemy);
      if ( (user_bias > 0.200) ) {
         self.lefty = (self.lefty | STRAFE_DIR);
         rdir = (rdir + 0.300);
      } else if ( (user_bias < -0.200) ) {
         self.lefty = (self.lefty - (self.lefty & STRAFE_DIR));
         rdir = (rdir + 0.300);
      }
   }
   if ( (rng == RANGE_NEAR) ) {

      rdir = (rdir + 0.800);

   } else {

      if ( (rng == RANGE_MELEE) ) {

         rdir = (rdir + 1.200);
         rnd = random ();
         // OPT: weap already set from W_BestHeldWeapon() above
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
            // FIX: raw walkmove for backward movement — botwalkmove whiskers fight it
            local float melee_back;
            melee_back = self.ideal_yaw + 180;
            if ( walkmove(melee_back, dis) ) {
               return ;
            }
            if ( walkmove(melee_back + 45, dis * 0.700) ) {
               return ;
            }
            if ( walkmove(melee_back - 45, dis * 0.700) ) {
               return ;
            }
         }

      } else {

         if ( (rng == RANGE_MID) ) {

            // OPT: weap already set from W_BestHeldWeapon() above
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
   // PASS #11 (#4): Anti-tracking strafe reversal — if taking sustained hitscan damage, reverse NOW
   if ( self.skil >= 3 && self.enemy && self.hp_delta > 20 ) {
      if ( self.enemy.weapon == IT_LIGHTNING || self.enemy.weapon == IT_SUPER_NAILGUN ) {
         // Force immediate direction reversal
         if ( (self.lefty & STRAFE_DIR) ) {
            self.lefty = (self.lefty - STRAFE_DIR);
         } else {
            self.lefty = (self.lefty + STRAFE_DIR);
         }
         self.strafe_hold_until = time + 0.150 + (random () * 0.200);
         self.strafetime = FALSE;
      }
   }

   // Strafe commitment: hold direction for a committed burst
   // Humans commit to a direction, not jitter every frame
   if ( (time > self.strafe_hold_until) ) {
      local float hold_dur;
      hold_dur = (0.300 + (self.skil * 0.060));
      hold_dur = (hold_dur * (0.700 + (random () * 0.600)));
      self.strafe_hold_until = (time + hold_dur);
      rnd = random ();
      if ( (rnd > 0.550) ) {
         if ( (self.lefty & STRAFE_DIR) ) {
            self.lefty = (self.lefty - STRAFE_DIR);
         } else {
            self.lefty = (self.lefty + STRAFE_DIR);
         }
      }
      self.strafetime = FALSE;
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
   // Circle strafing: skilled bots orbit at tighter angles
   if ( (self.skil >= 5) ) {
      local float circle_ofs;
      circle_ofs = 60 + (random() * 15);
      if ( (ofs < 0) ) circle_ofs = 0 - circle_ofs;
      ofs = circle_ofs;
   } else if ( (self.skil >= 3) ) {
      local float circle_ofs2;
      circle_ofs2 = 75 + (random() * 10);
      if ( (ofs < 0) ) circle_ofs2 = 0 - circle_ofs2;
      ofs = circle_ofs2;
   }
   // Elevation preference: bias strafing toward higher ground
   if ( self.enemy && (self.skil >= 2) ) {
      local vector left_pos, right_pos;
      local float left_z, right_z;
      makevectors(self.angles);
      left_pos = self.origin + (v_right * -80);
      right_pos = self.origin + (v_right * 80);
      traceline(left_pos, left_pos - '0 0 200', TRUE, self);
      left_z = trace_endpos_z;
      traceline(right_pos, right_pos - '0 0 200', TRUE, self);
      right_z = trace_endpos_z;
      if ( (left_z > (right_z + 16)) && (ofs > 0) ) {
         ofs = 0 - ofs;
      } else if ( (right_z > (left_z + 16)) && (ofs < 0) ) {
         ofs = 0 - ofs;
      }
   }

   // PASS #11 (#9): Weapon-specific movement patterns
   if ( self.skil >= 3 && self.enemy ) {
      if ( self.weapon == IT_LIGHTNING && self.cached_enemy_dist < 500 ) {
         // LG tracking stance: reduce lateral movement for better beam accuracy
         dis = dis * 0.600;
         if ( ofs > 0 ) ofs = ofs * 0.500;
         else ofs = ofs * 0.500;
      } else if ( self.weapon == IT_ROCKET_LAUNCHER ) {
         // RL peeking: wider strafe for cover-shoot rhythm
         if ( ofs > 0 ) ofs = ofs * 1.100;
         else ofs = ofs * 1.100;
      } else if ( self.weapon == IT_SUPER_SHOTGUN && self.cached_enemy_dist > 300 ) {
         // SSG gap-close: bias toward enemy
         rdir = rdir - 0.500;
      }
   }

   // PASS #11 (#7): Hazard-safe strafing — verify chosen direction won't kill us
   if ( self.skil >= 1 && self.enemy ) {
      local vector strafe_test;
      makevectors ('0 1 0' * (self.ideal_yaw + ofs));
      strafe_test = self.origin + (v_forward * 64);
      if ( BotDetectHazard (strafe_test) ) {
         ofs = 0 - ofs;  // Reverse
         makevectors ('0 1 0' * (self.ideal_yaw + ofs));
         strafe_test = self.origin + (v_forward * 64);
         if ( BotDetectHazard (strafe_test) ) {
            ofs = 0;  // Both sides dangerous — move toward enemy instead
         }
      }
   }

   // PASS #11 (#10): Proactive combat jumps — vary vertical profile
   if ( self.skil >= 3 && (self.flags & FL_ONGROUND) && self.enemy ) {
      local float jump_chance;
      jump_chance = 0.020;
      if ( self.enemy.weapon == IT_ROCKET_LAUNCHER )
         jump_chance = 0.060;
      else if ( self.enemy.weapon == IT_GRENADE_LAUNCHER )
         jump_chance = 0.040;
      // Don't jump while using LG (breaks tracking)
      if ( self.weapon == IT_LIGHTNING )
         jump_chance = jump_chance * 0.300;
      if ( random () < jump_chance && time > self.last_dodge_time ) {
         self.velocity_z = self.velocity_z + 270;
         self.button2 = TRUE;
         self.flags = self.flags - (self.flags & FL_ONGROUND);
         self.last_dodge_time = time + 0.600;
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
   local float enemy_yaw;
   local float move_yaw;
   local float strafe_ofs;

   if ( !self.enemy ) {

      return ;

   }
   away_dir = (self.origin - self.enemy.origin);
   away_yaw = vectoyaw (away_dir);
   enemy_yaw = vectoyaw (self.enemy.origin - self.origin);

   // Face the enemy — real players backpedal while shooting,
   // they don't turn their back during retreat
   self.ideal_yaw = enemy_yaw;
   ChangeYaw ();

   // Movement direction starts as directly away from enemy
   move_yaw = away_yaw;

   // PASS #11 (#1): Escape Rocket Jump — trade HP for velocity when cornered
   if ( self.skil >= 4 && (self.items & IT_ROCKET_LAUNCHER) && self.ammo_rockets >= 1 ) {
      if ( self.eff_hp > 50 && self.eff_hp < 90 && self.cached_enemy_dist < 400 ) {
         // Only if cornered — all escape directions blocked
         if ( !walkmove(away_yaw, 1) && !walkmove(away_yaw + 45, 1) && !walkmove(away_yaw - 45, 1) ) {
            if ( time > self.last_rj_time + 3.0 ) {
               // Fire rocket at own feet and jump
               self.v_angle_x = 80;
               self.v_angle_y = away_yaw;
               local float saved_weap;
               saved_weap = self.weapon;
               self.weapon = IT_ROCKET_LAUNCHER;
               W_SetCurrentAmmo ();
               BotDirectFire ();
               self.weapon = saved_weap;
               W_SetCurrentAmmo ();
               self.button2 = TRUE;
               self.velocity_z = self.velocity_z + 270;
               self.last_rj_time = time;
               return;
            }
         }
      }
   }

   // OPT: Retreat item scan throttled to 0.5s — reuse cached result
   local entity safe_item;
   safe_item = world;
   if ( self.retreat_safe_item && self.retreat_safe_item.solid == SOLID_TRIGGER ) {
      safe_item = self.retreat_safe_item;  // cached result still valid
   }
   if ( time >= self.retreat_scan_time ) {
      local float safe_dist;
      safe_dist = 600;
      safe_item = world;
      local entity scan;
      scan = findradius(self.origin, 600);
      while ( scan ) {
         if ( (scan.flags & FL_ITEM) ) {
            if ( (scan.classname == "item_health") || (scan.classname == "item_armor1") || (scan.classname == "item_armor2") || (scan.classname == "item_armorInv") ) {
               if ( (scan.solid == SOLID_TRIGGER) ) {
                  local float sd;
                  sd = vlen(scan.origin - self.origin);
                  if ( (sd < safe_dist) ) {
                     safe_dist = sd;
                     safe_item = scan;
                  }
               }
            }
         }
         scan = scan.chain;
      }
      self.retreat_safe_item = safe_item;
      self.retreat_scan_time = time + 0.500;
   }
   if ( safe_item != world ) {
      local float safe_yaw;
      safe_yaw = vectoyaw(safe_item.origin - self.origin);
      local float yaw_diff;
      yaw_diff = safe_yaw - move_yaw;
      while ( yaw_diff > 180 ) yaw_diff = yaw_diff - 360;
      while ( yaw_diff < -180 ) yaw_diff = yaw_diff + 360;
      move_yaw = move_yaw + (yaw_diff * 0.400);
   }

   // FIX #17: Retreat teleporter awareness — scan for nearby teleporters as escape
   if ( self.skil >= 2 && safe_item == world ) {
      local entity tele;
      tele = findradius (self.origin, 400);
      while ( tele ) {
         if ( tele.classname == "trigger_teleport" ) {
            if ( visible (tele) ) {
               move_yaw = vectoyaw ((tele.absmin + tele.absmax) * 0.500 - self.origin);
               break;
            }
         }
         tele = tele.chain;
      }
   }

   // Zigzag while retreating: alternate 30-degree offsets
   strafe_ofs = 30;
   if ( (self.lefty & STRAFE_DIR) ) {
      strafe_ofs = -30;
   }
   self.strafetime = (self.strafetime + 0.100);
   if ( (self.strafetime > (0.400 + (random () * 0.200))) ) {
      self.strafetime = FALSE;
      if ( (self.lefty & STRAFE_DIR) ) {
         self.lefty = (self.lefty - STRAFE_DIR);
      } else {
         self.lefty = (self.lefty + STRAFE_DIR);
      }
   }

   // Move using raw walkmove — botwalkmove's BotSteer whiskers
   // fight backward movement causing "running on the spot"
   if ( !walkmove((move_yaw + strafe_ofs), dist) ) {
      if ( !walkmove(move_yaw, dist) ) {
         if ( !walkmove((away_yaw + 45), (dist * 0.7)) ) {
            if ( !walkmove((away_yaw - 45), (dist * 0.7)) ) {
               if ( !walkmove((away_yaw + 90), (dist * 0.5)) )
                  walkmove((away_yaw - 90), (dist * 0.5));
            }
         }
      }
   }

   // Shoot while retreating — real players fire while backpedaling
   // FIX: CheckBotAttack only sets attack_state flag — must also process it
   // via aibot_run_melee() to actually fire (matches goody-path pattern)
   if ( self.attack_state == AS_MELEE ) {
      aibot_run_melee ();
   }
   CheckBotAttack ();
};

void (float state, string label) BotLogAI = {

   if ( (self.last_ai_state == state) ) {

      return ;

   }
   // FIX: Track when state changes for hysteresis
   self.last_ai_state_time = time;
   self.last_ai_state = state;

   if ( (cached_developer <= 0.000) ) {

      return ;

   }
   dprint ("[");
   dprint (self.netname);
   dprint ("] AI: ");
   dprint (label);
   dprint ("\n");

};

// =============================================================================
// STRATEGIC AI: Sound Investigation
// =============================================================================

// Check if bot should investigate a sound they heard
// Returns TRUE if bot is now investigating, FALSE otherwise
float (float dist) BotAI_CheckSoundInvestigation = {

   local float noise_age;
   local float dist_to_noise;
   local vector dir_to_noise;

   // Must have heard something recently
   if ( !self.investigating ) {
      return ( FALSE );
   }

   // How long ago did we hear it?
   noise_age = time - self.noise_time;

   // Sounds older than 4 seconds are stale
   if ( (noise_age > 4.0) ) {
      self.investigating = FALSE;
      return ( FALSE );
   }

   // Don't investigate if we have a visible enemy
   if ( self.enemy && enemyvisible(self.enemy) ) {
      self.investigating = FALSE;
      return ( FALSE );
   }

   // Calculate distance to noise source
   dist_to_noise = vlen (self.noise_target - self.origin);

   // If we're close enough, we've "arrived" at the investigation point
   if ( (dist_to_noise < 64) ) {
      self.investigating = FALSE;
      // Do a quick look around
      self.ideal_yaw = self.ideal_yaw + 90;
      ChangeYaw ();
      return ( FALSE );
   }

   // Move toward the noise
   BotLogAI (AI_STATE_INVESTIGATE, "INVESTIGATING");
   dir_to_noise = self.noise_target - self.origin;
   self.ideal_yaw = vectoyaw (dir_to_noise);

   // Hearing error: humans can't pinpoint exact sound direction
   // Error scales with distance, inversely with skill
   // Uses noise_time as stable seed so error doesn't jitter per frame
   local float hear_err;
   local float err_seed;
   hear_err = (35.000 - (self.skil * 4.000));
   if ( hear_err < 6.000 ) hear_err = 6.000;
   hear_err = (hear_err * (0.500 + (dist_to_noise * 0.001)));
   if ( hear_err > 45.000 ) hear_err = 45.000;
   err_seed = (self.noise_time * 100.000);
   err_seed = (err_seed - floor (err_seed));
   self.ideal_yaw = (self.ideal_yaw + ((err_seed - 0.500) * hear_err * 2.000));

   ChangeYaw ();

   // Look around while investigating (slight head movement)
   if ( (random () < 0.3) ) {
      self.v_angle_y = self.ideal_yaw + (random () * 40) - 20;
   }

   // FIX #13: Sound-driven aggression — modulate movement speed by noise_priority
   // High priority (90+ = aggressive push) → full speed
   // Low priority (30 = cautious) → slower, careful approach
   local float inv_speed;
   inv_speed = 0.600 + (self.noise_priority * 0.004);
   if ( inv_speed > 1.000 ) inv_speed = 1.000;
   if ( inv_speed < 0.500 ) inv_speed = 0.500;
   botwalkmove (self.ideal_yaw, dist * inv_speed);

   // PASS #11 (#8): GL area denial — bounce grenades toward sound source while approaching
   if ( self.skil >= 3 && (self.weapon & IT_GRENADE_LAUNCHER) && self.ammo_rockets >= 3 ) {
      if ( dist_to_noise > 200 && dist_to_noise < 600 && random () < 0.150 ) {
         local vector gl_aim;
         gl_aim = vectoangles (self.noise_target - self.origin);
         self.v_angle_y = gl_aim_y;
         self.v_angle_x = gl_aim_x;
         BotDirectFire ();
      }
   }

   // Only log once when investigation starts (check investigating flag)
   // The flag is set AFTER this check, so first call logs, subsequent don't
   if ( cached_developer && !self.investigating ) {
      dprint ("[");
      dprint (self.netname);
      dprint ("] INVESTIGATING: Moving to ");
      dprint (vtos(self.noise_target));
      dprint ("\n");
   }
   self.investigating = TRUE;  // Mark as actively investigating

   return ( TRUE );

};

// Main strategic decision function - called early in the AI loop
// Returns TRUE if strategic behavior took over, FALSE to continue normal AI
float (float dist) BotAI_Strategic = {

   // 1. AUDITORY INFERENCE: React to item/water/step sounds
   Bot_AnalyzeSound ();

   // 2. AUDITORY INVESTIGATION: If idle, go check out sounds
   //    This makes bots hunt players based on weapon fire
   if ( BotAI_CheckSoundInvestigation (dist) ) {
      return ( TRUE );
   }

   return ( FALSE );

};

// Slayer Eclipse: rush contested powerups when we can preempt enemy ETA
float () BotRivalPowerupRush = {

   local entity scan;
   local entity best;
   local float eta_self;
   local float eta_enemy;
   local float best_eta;

   if ( !self.enemy ) {
      return ( FALSE );
   }
   if ( (self.lefty & GETGOODY) ) {
      return ( FALSE );
   }
   if ( !Slayer_GodMode () && (self.skil < 5.000) ) {
      return ( FALSE );
   }
   if ( (self.health <= 50.000) ) {
      return ( FALSE );
   }

   best = world;
   best_eta = 999999.000;
   scan = findradius (self.enemy.origin, 600.000);
   while ( scan ) {
      if ( (scan.classname == "item_artifact_super_damage") || (scan.classname == "item_artifact_invulnerability") ) {
         if ( visible (scan) ) {
            eta_self = (vlen (scan.origin - self.origin) / 350.000);
            eta_enemy = (vlen (scan.origin - self.enemy.origin) / 350.000);
            // Skill-scaled ETA margin: higher skill = more aggressive rush
            local float eta_margin;
            eta_margin = (1.000 + (self.skil * 0.125));
            if ( (eta_self < (eta_enemy + eta_margin)) && (eta_self < best_eta) ) {
               best_eta = eta_self;
               best = scan;
            }
         }
      }
      scan = scan.chain;
   }

   if ( best != world ) {
      if ( (self.goalentity.classname != "BotTarget") ) {
         objerror ("bad bot target in bot_ai! 9\n");
      }
      self.goalentity.goalentity = best;
      setorigin (self.goalentity,best.origin);
      self.lefty = (self.lefty | GETGOODY);
      self.goody_time = (time + 1.500);
      return ( TRUE );
   }

   return ( FALSE );

};

// =============================================================================
// ADAPTIVE TACTICS: Continuous Aggression Score (Intelligence Pass #8)
// Returns 0.0 (full retreat) to 1.0 (full aggression)
// Replaces binary RunAway() with smooth spectrum modulated by:
// own HP/weapon, opponent profile, score, multi-threat, match phase
// =============================================================================
float () BotAggressionScore = {
   local float aggro;
   local float weap;

   // OPT: use cached eff_hp field directly

   // Base: health-mapped (eff_hp 0-120 → aggro 0.1-0.9)
   aggro = self.eff_hp / 120;
   if ( aggro > 0.9 ) aggro = 0.9;
   if ( aggro < 0.1 ) aggro = 0.1;

   // Weapon quality boost
   weap = W_BestHeldWeapon();
   if ( weap & (IT_ROCKET_LAUNCHER + IT_LIGHTNING) )
      aggro = aggro + 0.15;
   else if ( weap & (IT_SUPER_NAILGUN + IT_SUPER_SHOTGUN) )
      aggro = aggro + 0.05;
   else if ( weap & (IT_SHOTGUN + IT_AXE + IT_NAILGUN) )
      aggro = aggro - 0.15;

   // Powerup overrides
   if ( self.items & IT_QUAD ) aggro = aggro + 0.3;
   // FIX: Invulnerability = unconditional max aggression. Applied after ALL
   // modifiers below to prevent erosion by threat/damage/phase penalties.
   local float force_max_aggro;
   force_max_aggro = FALSE;
   if ( self.items & IT_INVULNERABILITY ) force_max_aggro = TRUE;
   if ( self.enemy ) {
      if ( self.enemy.items & IT_QUAD ) aggro = aggro - 0.3;
      if ( self.enemy.items & IT_INVULNERABILITY ) aggro = aggro - 0.5;

      // Opponent profile: reduce aggression against high-threat enemies
      local float en_threat;
      en_threat = OppGetThreat(self.enemy);
      aggro = aggro + (0.5 - en_threat) * 0.3;

      // Counter-aggression: passive enemy → push, aggressive enemy → cautious
      local float en_aggro;
      en_aggro = OppGetAggro(self.enemy);
      if ( en_aggro < 0.3 ) aggro = aggro + 0.1;
      else if ( en_aggro > 0.7 ) aggro = aggro - 0.05;

      // Enemy nearly dead: finish them
      if ( self.enemy.health < 25 ) aggro = aggro + 0.2;

      // Score pressure: losing → fight harder, winning → play safer
      local float score_diff;
      score_diff = self.frags - self.enemy.frags;
      if ( score_diff < -5 ) aggro = aggro + 0.1;
      else if ( score_diff > 5 ) aggro = aggro - 0.1;
   }

   // Multi-threat: retreat pressure from multiple visible enemies
   if ( self.visible_threats >= 2 )
      aggro = aggro - 0.25;
   if ( self.visible_threats >= 3 )
      aggro = aggro - 0.15;

   // PASS #11 (#3): Taking-fire panic — heavy recent damage forces defensive play
   if ( self.hp_delta > 30 )
      aggro = aggro - 0.25;
   else if ( self.hp_delta > 15 )
      aggro = aggro - 0.10;

   // Match phase modulation
   if ( self.match_phase == 0 )
      aggro = aggro + 0.1;  // SCRAMBLE: push for weapons
   else if ( self.match_phase == 2 ) {
      // ENDGAME: protect lead or take risks
      if ( self.enemy ) {
         local float lead;
         lead = self.frags - self.enemy.frags;
         if ( lead >= 3 ) aggro = aggro - 0.15;
         else if ( lead <= -3 ) aggro = aggro + 0.15;
      }
   }

   // PASS #13: Psychological momentum — kill streaks embolden, death streaks tilt
   local float mom_offset;
   mom_offset = (self.momentum - 0.5) * 0.3;  // -0.15 to +0.15
   aggro = aggro + mom_offset;

   // PASS #13: Personality base aggression offset
   aggro = aggro + self.personality_aggro;

   // PASS #13: Overconfidence — high momentum partially negates multi-threat penalty
   if ( self.momentum > 0.8 && self.visible_threats >= 2 )
      aggro = aggro + 0.15;

   // Skill dampening: low-skill bots are less extreme
   aggro = 0.5 + (aggro - 0.5) * (0.5 + self.skil * 0.05);

   // FIX: Invulnerability override — applied after all modifiers to prevent erosion
   if ( force_max_aggro ) aggro = 1.0;

   // Clamp
   if ( aggro > 1.0 ) aggro = 1.0;
   if ( aggro < 0.0 ) aggro = 0.0;

   // Hysteresis: smooth with previous value to prevent jitter
   self.aggression = self.aggression * 0.7 + aggro * 0.3;

   return self.aggression;
};

// =============================================================================
// ADAPTIVE TACTICS: Match Phase Detection (Intelligence Pass #8)
// 3-phase tactical overlay: SCRAMBLE → CONTROL → ENDGAME
// Throttled to 1 recalculation per second
// =============================================================================
void () BotUpdateMatchPhase = {
   local float total_frags;
   local float max_frags;
   local float fl;
   local entity e;

   if ( time < self.phase_update_time ) return;
   self.phase_update_time = time + 1.0;

   total_frags = 0;
   max_frags = 0;

   // Sum frags across all players and bots
   e = find(world, classname, "player");
   while ( e ) {
      total_frags = total_frags + e.frags;
      if ( e.frags > max_frags ) max_frags = e.frags;
      e = find(e, classname, "player");
   }
   e = bot_list_head;  // OPT: cached bot linked list
   while ( e ) {
      total_frags = total_frags + e.frags;
      if ( e.frags > max_frags ) max_frags = e.frags;
      e = e.bot_next;
   }

   // Phase thresholds
   // FIX: Check ENDGAME first — someone 1 frag from winning must override
   // SCRAMBLE even in low-total-frag games (e.g., 2-player 11 vs -2)
   fl = cvar("fraglimit");
   if ( fl > 0 && max_frags >= (fl - 5) ) {
      self.match_phase = 2;  // ENDGAME: someone near frag limit
   } else if ( total_frags < 10 ) {
      self.match_phase = 0;  // SCRAMBLE: first kills, weapon rush
   } else {
      self.match_phase = 1;  // CONTROL: mid-game item dominance
   }
};

void (float dist) BotAI_Main = {

   // FIX: Stop AI if dead - prevents overriding death animation frames
   if ( self.deadflag != DEAD_NO ) {
      return;
   }

   // OPT: Cache effective HP once per think (used by RunAway, aggression, etc.)
   self.eff_hp = self.health + (self.armorvalue * self.armortype);

   // PASS #11: Track damage rate — how much HP lost per second
   if ( time > self.hp_snapshot_time + 1.0 ) {
      self.hp_delta = self.hp_snapshot - self.eff_hp;
      if ( self.hp_delta < 0 ) self.hp_delta = 0;  // healed, not damaged
      self.hp_snapshot = self.eff_hp;
      self.hp_snapshot_time = time;
   }

   // Mirage Minds: entropy biasing
   MirageTick ();

   // ADAPTIVE TACTICS: Update match phase (throttled)
   BotUpdateMatchPhase();

   // PASS #13: Momentum decay toward 0.5 (neutral) — slow, 10s interval
   if ( time > self.momentum_decay_time + 10 ) {
      self.momentum_decay_time = time;
      if ( self.momentum > 0.52 ) self.momentum = self.momentum - 0.01;
      else if ( self.momentum < 0.48 ) self.momentum = self.momentum + 0.01;
   }

   // Weapon confidence decay: 10% per minute prevents stale preferences
   if ( time > (self.confidence_decay_time + 60.000) ) {
      self.confidence_decay_time = time;
      self.confidence_rl = (self.confidence_rl * 0.900);
      self.confidence_lg = (self.confidence_lg * 0.900);
      self.confidence_gl = (self.confidence_gl * 0.900);
      self.confidence_sg = (self.confidence_sg * 0.900);
      self.confidence_sng = (self.confidence_sng * 0.900);
   }

   // Phantom Apprenticeship: occasionally shadow a player
   if ( !self.phantom && (random () < 0.030) && (time > (self.last_phantom + 30.000)) ) {
      local entity ply;
      ply = Spectral_FindPlayer ();
      if ( ply ) {
         self.phantom = SpawnPhantom (ply);
         self.last_phantom = time;
      }
   }

   local float rng;
   local float oldrng;

   // Reflex dodge before normal combat/path logic
   if ( self.health > 0 ) {
      BotReflexDodge ();
   }

   if ( (self.enemy.deadflag != DEAD_NO) ) {

      self.post_kill_time = time + 2.000;

      // PASS #11 (#5): Spawn control — rush nearest visible spawn point after kill
      if ( self.skil >= 4 && self.eff_hp > 60 ) {
         local entity sp;
         local entity best_sp;
         local float sp_dist, best_sp_dist;
         best_sp = world;
         best_sp_dist = 800;
         sp = find (world, classname, "info_player_deathmatch");
         while ( sp ) {
            sp_dist = vlen (sp.origin - self.origin);
            if ( sp_dist < best_sp_dist && sp_dist > 100 ) {
               traceline (self.origin + self.view_ofs, sp.origin, TRUE, self);
               if ( trace_fraction == 1.0 ) {
                  best_sp_dist = sp_dist;
                  best_sp = sp;
               }
            }
            sp = find (sp, classname, "info_player_deathmatch");
         }
         if ( best_sp != world ) {
            self.goalentity.goalentity = best_sp;
            setorigin (self.goalentity, best_sp.origin);
            self.search_time = time + 3.0;
            self.ideal_yaw = vectoyaw (best_sp.origin - self.origin);
         }
      }

      // PASS #13: Spawn awareness — watch spawn points after a kill
      if ( self.skil >= 3 ) {
         self.spawn_watch_time = time + 3.0;
         // Grudge intensification: killed grudge target = watch longer
         if ( self.enemy == self.grudge_target )
            self.spawn_watch_time = time + 5.0;
      }

      BotLogAI (AI_STATE_NONE, "NO_ENEMY");
      endEnemy ();
      return ;

   }
   if ( !self.enemy ) {

      // OPT: Post-kill scavenge — use cached loot if still valid
      if ( (self.post_kill_time > time) ) {
         local entity loot;
         loot = self.post_kill_loot;
         // Only re-scan if cached loot is gone (picked up)
         if ( !loot || loot.solid != SOLID_TRIGGER ) {
            local float loot_dist;
            loot = world;
            loot_dist = 300;
            local entity sc;
            sc = findradius(self.origin, 300);
            while ( sc ) {
               if ( (sc.flags & FL_ITEM) && (sc.solid == SOLID_TRIGGER) ) {
                  local float ld;
                  ld = vlen(sc.origin - self.origin);
                  // FIX #15: Backpack priority — killed player's backpack has their weapons
                  if ( sc.classname == "backpack" ) {
                     ld = ld * 0.500;
                  }
                  if ( (ld < loot_dist) ) {
                     loot_dist = ld;
                     loot = sc;
                  }
               }
               sc = sc.chain;
            }
            self.post_kill_loot = loot;
         }
         if ( loot != world ) {
            self.goalentity.goalentity = loot;
            setorigin(self.goalentity, loot.origin);
            self.search_time = self.post_kill_time;
         }
      }
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
      // Tactical Intelligence: track enemy velocity for prediction
      self.last_enemy_vel = self.enemy.velocity;
      // ADAPTIVE TACTICS: Update opponent profile (aggression, weapon, threat EMA)
      OppUpdate(self.enemy);
      // Clear ambush state when we can see them
      self.ambush_ready = FALSE;
      // Shadow Puppets: combat rollout guidance
      BotShadowCombatThink (self.enemy, rng);
      // Slayer Eclipse: preempt contested powerups
      if ( BotRivalPowerupRush () ) {
         BotLogAI (AI_STATE_GOODY, "GOODY");
         ai_botgetGoody (dist);
         return ;
      }

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
   // FIX: Saturating increment — prevents counter bits bleeding into flag bits
   if ( (self.lefty & LOCAL_TIME) < LOCAL_TIME )
      self.lefty = (self.lefty + TRUE);

   // ADAPTIVE TACTICS: Continuous aggression spectrum (replaces binary RunAway)
   // aggro < 0.25 = full retreat, 0.25-0.45 = cautious kite, >= 0.45 = fight
   local float aggro;
   aggro = BotAggressionScore();

   // PASS #11 (#6): Quad Rampage — with Quad, max aggression, skip item detours, hunt enemies
   // FIX: Applied AFTER BotAggressionScore so it can't be recalculated away
   if ( (self.items & IT_QUAD) && self.health > 0 ) {
      // Force max aggression — every second of Quad must be spent fighting
      aggro = 1.0;
      self.aggression = 1.0;
      // If no visible enemy, aggressively hunt
      if ( !self.enemy || !enemyvisible (self.enemy) ) {
         BotFindTarget ();
      }
      // Never retreat or grab items during Quad — fall through to attack
   }

   // Multi-threat awareness is handled by BotAggressionScore() which applies
   // -0.25/-0.15 penalty for 2+/3+ visible threats. No need for a hard
   // THIRD_PARTY_WAIT return — that suppresses all combat and causes oscillation.

   // PASS #13: Third-party lurk — hold back when two enemies are actively fighting
   // TIGHTENED: requires 3+ visible threats, skill 5+, low aggression, AND enemy must
   // be actively engaged with someone else. Never suppresses fire — just holds distance.
   // Previous version triggered in nearly all multi-bot games and suppressed combat.
   if ( self.visible_threats >= 3 && self.skil >= 5 && self.enemy ) {
      if ( self.enemy.enemy && self.enemy.enemy != self && self.enemy.enemy.health > 0 ) {
         if ( self.eff_hp > 80 && aggro < 0.55 ) {
            // Enter or maintain lurk (lurk_time == 0 means ready,
            // -1 means exhausted/cooldown — prevents immediate re-entry after timeout)
            if ( self.lurk_time == 0 )
               self.lurk_time = time;

            // Lurk timeout: 3s max, then fall through to normal combat
            if ( self.lurk_time > 0 && time < self.lurk_time + 3 ) {
               self.third_party_time = time;
               BotLogAI (AI_STATE_INVESTIGATE, "LURK");
               // Hold further back (0.5x distance) but ALWAYS allow firing
               aibot_run_slide (dist * 0.500, NOTURN);
               if ( self.attack_state == AS_MELEE ) aibot_run_melee ();
               CheckBotAttack ();
               return ;
            } else {
               self.lurk_time = -1;  // Timeout expired — cooldown prevents re-entry
            }
         }
      } else {
         self.lurk_time = 0;  // Conditions no longer met
      }
   }

   if ( aggro < 0.45 ) {

      self.lefty = (self.lefty - (self.lefty & LOCAL_TIME));
      self.lastseenpos = self.goalentity.origin;

      // FIX: State-dependent hysteresis to prevent oscillation
      local float hyst;
      hyst = 0.500;
      if ( self.last_ai_state == AI_STATE_RETREAT ) hyst = 1.500;
      else if ( self.last_ai_state == AI_STATE_GOODY ) hyst = 0.800;
      else if ( self.last_ai_state == AI_STATE_ATTACK ) {
         hyst = 1.000 + (self.dmg_dealt * 0.500);
         if ( hyst > 3.000 ) hyst = 3.000;
      }
      if ( ((self.last_ai_state == AI_STATE_GOODY) || (self.last_ai_state == AI_STATE_RETREAT) || (self.last_ai_state == AI_STATE_ATTACK)) && (time < (self.last_ai_state_time + hyst)) ) {

         // Continue current state without re-evaluating
         if ( (self.last_ai_state == AI_STATE_GOODY) ) {

            ai_botgetGoody (dist);
            return ;

         } else if ( (self.last_ai_state == AI_STATE_RETREAT) ) {

            ai_botretreat (dist);
            return ;

         }
         // ATTACK hysteresis: skip goody/retreat, fall through

      } else {

         if ( aggro < 0.25 ) {
            // Full retreat
            if ( aibot_checkforGoodies (DONT_WANT) ) {
               BotLogAI (AI_STATE_GOODY, "GOODY");
               ai_botgetGoody (dist);
               return ;
            }
            BotLogAI (AI_STATE_RETREAT, "RETREAT");
            ai_botretreat (dist);
            return ;
         } else {
            // Cautious kite: face enemy while backing away slowly
            // Uses raw walkmove() — botwalkmove()'s BotSteer whiskers
            // fight backward movement causing "running on the spot"
            BotLogAI (AI_STATE_RETREAT, "KITE");
            local vector kite_away;
            local float kite_away_yaw;
            local float kite_enemy_yaw;
            kite_away = self.origin - self.enemy.origin;
            kite_away_yaw = vectoyaw(kite_away);
            kite_enemy_yaw = vectoyaw(self.enemy.origin - self.origin);
            // Face the enemy so we can actually shoot
            self.ideal_yaw = kite_enemy_yaw;
            ChangeYaw();
            // Move backward using raw walkmove (no BotSteer interference)
            if ( !walkmove(kite_away_yaw, dist * 0.6) ) {
               // Try angled escapes if direct backpedal is blocked
               if ( !walkmove(kite_away_yaw + 45, dist * 0.5) )
                  if ( !walkmove(kite_away_yaw - 45, dist * 0.5) )
                     // Corner: try perpendicular strafe
                     if ( !walkmove(kite_away_yaw + 90, dist * 0.5) )
                        walkmove(kite_away_yaw - 90, dist * 0.5);
            }
            // FIX: Process attack flag to actually fire during kite
            if ( self.attack_state == AS_MELEE ) {
               aibot_run_melee ();
            }
            CheckBotAttack ();
            return ;
         }

      }

   }
   enemy_infront = infrontofbot (self.enemy);
   enemy_yaw = vectoyaw ((self.enemy.origin - self.origin));
   if ( !enemy_vis ) {

      // =================================================================
      // PASS #13: Corner ambush — pre-position at corners while investigating
      // When approaching a tight corner during sound investigation, 15% chance
      // to stop short, pre-aim at the opening, and wait with a strong weapon.
      // Safety: 5s timeout prevents permanent freeze if enemy never appears.
      // =================================================================
      if ( self.ambush_ready && time > self.ambush_start_time + 5.0 ) {
         self.ambush_ready = FALSE;
         if ( cached_developer ) {
            dprint ("[");
            dprint (self.netname);
            dprint ("] CORNER AMBUSH: Timeout - resuming\n");
         }
      }
      if ( self.investigating && self.skil >= 3 && !self.ambush_ready ) {
         makevectors (self.angles);
         traceline (self.origin, self.origin + v_forward * 100, TRUE, self);
         if ( trace_fraction < 0.5 ) {
            // Wall ahead — check if side is open (corner geometry)
            local vector saved_vr;
            saved_vr = v_right;
            traceline (self.origin, self.origin + saved_vr * 100, TRUE, self);
            if ( trace_fraction > 0.8 ) {
               // Corner detected: wall ahead, open to the side
               if ( random() < 0.15 ) {
                  self.ambush_ready = TRUE;
                  self.ambush_start_time = time;
                  self.ideal_yaw = vectoyaw (saved_vr);
                  // Select best ambush weapon
                  if ( self.items & IT_ROCKET_LAUNCHER && self.ammo_rockets >= 1 )
                     self.weapon = IT_ROCKET_LAUNCHER;
                  else if ( self.items & IT_SUPER_SHOTGUN && self.ammo_shells >= 2 )
                     self.weapon = IT_SUPER_SHOTGUN;
                  if ( cached_developer ) {
                     dprint ("[");
                     dprint (self.netname);
                     dprint ("] CORNER AMBUSH: Pre-positioning at corner\n");
                  }
               }
            }
         }
      }

      // =================================================================
      // TACTICAL INTELLIGENCE: THE TRAP (Ambush Logic)
      // When low health and being chased, set up an ambush instead of
      // running. Stop, aim at the entry point, and wait with SSG/RL.
      // =================================================================
      // OPT: use cached eff_hp
      if ( self.eff_hp < 50 && self.health > 0 && self.enemy ) {

         // Calculate if enemy is chasing us (dot product check)
         local vector dir_to_bot;
         local float chasing;
         dir_to_bot = normalize (self.origin - self.lastseenpos);
         chasing = normalize(self.last_enemy_vel) * dir_to_bot;

         if ( chasing > 0.4 ) {
            // They are chasing! Set the trap.

            // Timeout: skill-scaled (skill 0: 2s, skill 10: 5s)
            if ( self.ambush_ready && time > self.ambush_start_time + (2.000 + self.skil * 0.300) ) {
               self.ambush_ready = FALSE;
               if ( cached_developer ) {
                  dprint ("[");
                  dprint (self.netname);
                  dprint ("] AMBUSH: Timeout - resuming normal behavior\n");
               }
            }

            if ( !self.ambush_ready ) {
               // Start the ambush
               self.ambush_ready = TRUE;
               self.ambush_start_time = time;

               // Switch to "Punisher" weapon (SSG or RL)
               if ( self.items & IT_SUPER_SHOTGUN && self.ammo_shells >= 2 ) {
                  self.weapon = IT_SUPER_SHOTGUN;
               } else if ( self.items & IT_ROCKET_LAUNCHER && self.ammo_rockets >= 1 ) {
                  self.weapon = IT_ROCKET_LAUNCHER;
               }

               if ( cached_developer ) {
                  dprint ("[");
                  dprint (self.netname);
                  dprint ("] AMBUSH: Setting trap! Waiting with ");
                  if ( self.weapon == IT_SUPER_SHOTGUN ) {
                     dprint ("SSG");
                  } else if ( self.weapon == IT_ROCKET_LAUNCHER ) {
                     dprint ("RL");
                  } else {
                     dprint ("current weapon");
                  }
                  dprint ("\n");
               }
            }

            // Execute the ambush: STOP and AIM
            self.velocity = '0 0 0';
            self.ideal_yaw = vectoyaw (self.lastseenpos - self.origin);
            self.v_angle_y = self.ideal_yaw;
            ChangeYaw ();

            // NERVOUS TRIGGER: If they're very close, pre-fire!
            if ( vlen(self.lastseenpos - self.origin) < 200 ) {
               if ( time - self.last_seen_time < 1.5 ) {
                  // Don't pre-fire explosives at close range (splash suicide)
                  if ( !((self.weapon == IT_ROCKET_LAUNCHER) || (self.weapon == IT_GRENADE_LAUNCHER)) ) {
                     BotDirectFire ();
                     if ( cached_developer && random() < 0.1 ) {
                        dprint ("[");
                        dprint (self.netname);
                        dprint ("] AMBUSH: Nervous trigger!\n");
                     }
                  }
               }
            }

            BotLogAI (AI_STATE_AMBUSH, "AMBUSH");
            return;
         }
      }

      // Object Permanence: continue engaging last known position
      local float memory_duration;
      memory_duration = (0.500 + (self.skil * 0.300));
      if ( (memory_duration > 3.000) )
         memory_duration = 3.000;
      if ( Slayer_GodMode () ) {
         memory_duration = 5.000;
      }

      if ( (time < (self.last_seen_time + memory_duration)) ) {

         // Still in memory window - fire at last known position
         BotLogAI (AI_STATE_ATTACK, "MEMORY_ATTACK");

         // TACTICAL: Try pre-firing at corners (suppressive fire)
         BotBlindFire ();

         // Shadow Puppets: tactical repositioning during memory phase
         if ( self.enemy && (self.enemy != world) ) {
            local float mdist;
            mdist = vlen (self.lastseenpos - self.origin);
            BotShadowCombatThink (self.enemy, mdist);
         }

         // FIX: Process stale melee flag before CheckBotAttack (matches other sites)
         if ( self.attack_state == AS_MELEE ) {
            aibot_run_melee ();
         }
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
   // FIX: Survival override - keep moving if drowning
   if ( (self.waterlevel >= 3.000) && (self.air_finished < (time + 4.000)) ) {
      BotLogAI (AI_STATE_RETREAT, "DROWN");
      aibot_run_slide (dist,CANTURN);
      return ;
   }
   if ( (self.attack_state == AS_MELEE) ) {

      BotLogAI (AI_STATE_ATTACK, "MELEE");
      aibot_run_melee ();

   }
   BotLogAI (AI_STATE_ATTACK, "ATTACK");

   // Track engagement commitment (time spent firing at enemy)
   if ( self.enemy ) {
      self.dmg_dealt = self.dmg_dealt + frametime;
   }

   // PASS #11 (#2): Mid-fight weapon re-evaluation — switch as range changes
   if ( self.skil >= 2 && self.enemy && time > self.weapon_eval_time ) {
      self.weapon_eval_time = time + 0.500;
      local float new_weap;
      new_weap = W_BestBotWeapon ();
      if ( new_weap != self.weapon && new_weap != IT_AXE ) {
         self.weapon = new_weap;
         W_SetCurrentAmmo ();
      }
   }

   // OPT: Throttle displacement kill check to 0.3s (expensive: tracelines + pointcontents)
   local float env_kill;
   env_kill = FALSE;
   if ( time >= self.env_kill_time ) {
      self.env_kill_time = time + 0.300;
      env_kill = BotCheckEnvironmentKill ();
   }
   if ( !env_kill ) {
      CheckBotAttack ();
   }

   aibot_run_slide (dist,CANTURN);
   return ;

};

void () aibot_setupchase = {

   local entity pth;

   self.think = bot_chase;
   if ( TrueReachable (self.goalentity) ) {

      return ;

   }
   // FIX: Use continuous aggression score instead of binary RunAway()
   // Unifies chase with attack state's retreat logic (prevents oscillation)
   if ( self.aggression < 0.35 ) {

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
   // FIX #20: Chase path prediction — aim at predicted position instead of last known
   if ( self.last_enemy_vel != '0 0 0' && self.skil >= 2 ) {
      local float chase_lead;
      chase_lead = time - self.last_seen_time;
      if ( chase_lead > 0 && chase_lead < 2.000 ) {
         local vector pred_chase;
         pred_chase = BotPredictPosition (chase_lead * 0.500);
         if ( (self.goalentity.classname == "BotTarget") ) {
            setorigin (self.goalentity, pred_chase);
         }
      }
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
   // FIX: Saturating increment — prevents counter bits bleeding into flag bits
   if ( (self.lefty & LOCAL_TIME) < LOCAL_TIME )
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
   local float best;
   local float weight;
   local float minimum;
   local float scan_radius;
   local float goodies_throttle;
   local float combat_radius;

   // FIX: Do not forage for items if drowning
   if ( (self.air_finished < (time + 5.000)) && (self.waterlevel >= 3.000) ) {
      return ( FALSE );
   }

   if ( (self.air_finished < (time + MOVETYPE_FLYMISSILE)) ) {

      goForAir ();
      self.lefty = (self.lefty | GETGOODY);
      self.goody_time = (time + MOVETYPE_WALK);
      return ( TRUE );

   }
   AFRAID = RunAway ();

   // Throttle expensive item scans when not panicking
   if ( !AFRAID ) {
      goodies_throttle = cvar ("bot_goodies_throttle");
      if ( (goodies_throttle <= FALSE) ) {
         goodies_throttle = 0.200;
      }
      if ( time < self.goodies_scan_time ) {
         return ( FALSE );
      }
      self.goodies_scan_time = (time + goodies_throttle);
   }

   scan_radius = SEARCH_RADIUS;
   if ( self.enemy && (self.enemy != world) && enemyvisible (self.enemy) ) {
      combat_radius = cvar ("bot_goodies_combat_radius");
      if ( (combat_radius <= FALSE) ) {
         combat_radius = 400.000;
      }
      scan_radius = (combat_radius + (self.skil * 20.000));
      if ( self.health < 40.000 ) {
         scan_radius = SEARCH_RADIUS;
      }
      if ( scan_radius > SEARCH_RADIUS ) {
         scan_radius = SEARCH_RADIUS;
      }
   }

   botTarget = self.goalentity;
   e = findradius (self.origin,scan_radius);
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

                        // SIXTH SENSE: 360-degree awareness for close items
                        // Bots "sense" nearby items even if not looking at them
                        local float dist_to_item;
                        local float can_see_item;
                        local float sixth_sense_triggered;

                        dist_to_item = vlen (e.origin - self.origin);
                        can_see_item = FALSE;
                        sixth_sense_triggered = FALSE;

                        // Very close items (< 300 units): 360-degree awareness
                        // Only need basic LOS check, ignore facing angle
                        if ( dist_to_item < 300 ) {
                           traceline (self.origin + self.view_ofs, e.origin, TRUE, self);
                           if ( trace_fraction == 1.0 ) {
                              can_see_item = TRUE;
                              sixth_sense_triggered = TRUE;
                              // Proximity boost: closer = more weight
                              weight = weight + ((300 - dist_to_item) * 0.1);

                              // Log when sixth sense detects item not in front (with cooldown)
                              // Use blind_fire_time as cooldown to prevent spam when walking past items
                              if ( cached_developer && !infrontofbot(e) && (weight > WANT) && (time > self.blind_fire_time) ) {
                                 dprint ("[");
                                 dprint (self.netname);
                                 dprint ("] SIXTH_SENSE: Detected ");
                                 dprint (e.classname);
                                 dprint (" behind me (");
                                 dprint (ftos(floor(dist_to_item)));
                                 dprint (" units)\n");
                                 self.blind_fire_time = time + 1.0;  // 1 second cooldown
                              }
                           }
                        }
                        // Medium distance (< 800): standard vision
                        else if ( dist_to_item < 800 ) {
                           if ( visible (e) && infrontofbot (e) ) {
                              can_see_item = TRUE;
                           }
                        }
                        // Far away: ignore to save CPU and prevent cross-map wandering

                        // If we can't see the item at all, reduce weight significantly
                        if ( !can_see_item && (dist_to_item > 300) ) {
                           weight = weight * 0.3;
                        }

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
   // Threat abort: abandon item grab if taking heavy fire while low
   if ( self.enemy && enemyvisible (self.enemy) ) {
      local float threat_dist;
      threat_dist = vlen (self.enemy.origin - self.origin);
      if ( (self.health < 40.000) && (threat_dist < 400.000) ) {
         ai_endgetGoody (dist);
         return;
      }
   }
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
