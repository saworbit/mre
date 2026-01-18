float (entity targ) botrange;

// Reflex dodge: evade incoming rockets/grenades
void () BotReflexDodge = {

   local entity missile;
   local vector dir;
   local vector side_dir;

   if ( time < self.last_dodge_time ) {
      return ;
   }

   missile = findradius (self.origin,500.000);
   while ( missile ) {
      if ( (missile.classname == "missile") || (missile.classname == "grenade") || (missile.model == "progs/missile.mdl") ) {
         if ( vlen (missile.velocity) > 10.000 ) {
            dir = normalize ((self.origin - missile.origin));
            if ( (normalize (missile.velocity) * dir) > 0.800 ) {
               self.last_dodge_time = (time + 1.500);
               if ( cvar ("developer") ) {
                  dprint ("Bot attempting DODGE!\n");
               }
               side_dir_x = missile.velocity_y;
               side_dir_y = -missile.velocity_x;
               side_dir_z = 0;
               side_dir = normalize (side_dir);
               if ( (random () > 0.500) ) {
                  side_dir = (side_dir * -1.000);
               }
               self.velocity = (self.velocity + (side_dir * 350.000));
               self.button2 = TRUE;
               return ;
            }
         }
      }
      missile = missile.chain;
   }

};

// =============================================================================
// TACTICAL INTELLIGENCE (Mastermind Update)
// Predictive state estimation and proactive combat behaviors
// =============================================================================

// Predict where the enemy will be based on last known position and velocity
// Accounts for gravity if they were airborne
vector (float lead_time) BotPredictPosition = {

   local vector pred;

   // Basic linear prediction: Origin + (Velocity * Time)
   pred = self.lastseenpos + (self.last_enemy_vel * lead_time);

   // If they were jumping/falling, apply gravity to prediction
   // Quake gravity is ~800 units/sec^2
   if ( self.last_enemy_vel_z != 0 ) {
      pred_z = pred_z - (0.5 * 800 * lead_time * lead_time);
      // Don't predict through floor - clamp to reasonable depth
      if ( pred_z < self.lastseenpos_z - 100 ) {
         pred_z = self.lastseenpos_z - 20;
      }
   }

   return pred;

};

// Pre-fire/Blind fire at corners when enemy just disappeared
// Creates "did I just see that?" moments when bot fires rockets at corners
void () BotBlindFire = {

   local vector aim_at;
   local float dist;
   local float time_since_seen;

   // Need an enemy we recently lost sight of
   if ( !self.enemy ) return;
   if ( enemyvisible(self.enemy) ) return;

   // Only pre-fire if we saw them less than 2 seconds ago
   time_since_seen = time - self.last_seen_time;
   if ( time_since_seen > 2.0 ) return;

   // Cooldown to prevent spam
   if ( time < self.blind_fire_time ) return;

   // Distance check - too close is dangerous, too far is wasteful
   dist = vlen (self.lastseenpos - self.origin);
   if ( dist < 100 || dist > 600 ) return;

   // THE CORNER SHOT: Rocket/Grenade only (splash damage around corners)
   if ( self.weapon == IT_ROCKET_LAUNCHER || self.weapon == IT_GRENADE_LAUNCHER ) {

      // Predict where they went
      aim_at = BotPredictPosition (time_since_seen * 0.5);

      // Aim at feet for splash damage
      aim_at_z = aim_at_z - 24;

      // Check if we have line of sight to the predicted spot
      traceline (self.origin + self.view_ofs, aim_at, TRUE, self);

      // 15% chance per frame to suppress fire (skill-scaled)
      // Higher skill = more likely to pre-fire
      if ( random() < (0.05 + self.skil * 0.03) ) {

         local vector aim_angles;
         aim_angles = vectoangles (aim_at - self.origin);
         self.v_angle_y = aim_angles_y;
         self.v_angle_x = aim_angles_x;
         self.button0 = TRUE;
         self.blind_fire_time = time + 0.8;  // Cooldown

         if ( cvar("developer") ) {
            dprint ("[");
            dprint (self.netname);
            dprint ("] PREFIRE: Suppressing corner at ");
            dprint (vtos(aim_at));
            dprint ("\n");
         }
      }
   }

};

// Check if we can knock the enemy into a hazard (lava/slime)
// The "Smart" bot aims at feet to push enemies backward into danger
float () BotCheckEnvironmentKill = {

   local vector check_spot;
   local float hazard_found;

   // Need a visible enemy and knockback weapon
   if ( !self.enemy ) return FALSE;
   if ( !enemyvisible(self.enemy) ) return FALSE;
   if ( !(self.items & (IT_ROCKET_LAUNCHER | IT_GRENADE_LAUNCHER)) ) return FALSE;

   // Check 100 units behind the enemy for hazards
   makevectors (self.enemy.angles);
   check_spot = self.enemy.origin - (v_forward * 100);
   check_spot_z = check_spot_z - 64;  // Look down for floor hazard

   hazard_found = FALSE;
   if ( pointcontents(check_spot) == CONTENT_LAVA ) {
      hazard_found = TRUE;
   } else if ( pointcontents(check_spot) == CONTENT_SLIME ) {
      hazard_found = TRUE;
   }

   // Also check directly behind (cliff edge into hazard)
   if ( !hazard_found ) {
      check_spot = self.enemy.origin - (v_forward * 80);
      traceline (check_spot, check_spot - '0 0 128', TRUE, world);
      if ( trace_fraction == 1.0 ) {
         // Cliff detected - check what's below
         check_spot_z = check_spot_z - 128;
         if ( pointcontents(check_spot) == CONTENT_LAVA || pointcontents(check_spot) == CONTENT_SLIME ) {
            hazard_found = TRUE;
         }
      }
   }

   if ( hazard_found ) {
      // Aim at enemy's FEET to knock them backward
      self.v_angle_x = 20;  // Pitch down
      self.button0 = TRUE;

      if ( cvar("developer") ) {
         dprint ("[");
         dprint (self.netname);
         dprint ("] DISPLACEMENT: Attempting hazard knockback!\n");
      }
      return TRUE;
   }

   return FALSE;

};

vector (vector src, vector trg, float invMvel) leadtarget = {

   local vector tg;
   local vector lead;
   local float lead_time;
   local float dist;

   // FIX: Improved predictive aiming with time cap
   // Calculate time to impact = distance * inverse_velocity
   dist = vlen ((trg - src));
   lead_time = (dist * invMvel);

   // Cap prediction to 0.5 seconds to prevent excessive leading at long range
   if ( (lead_time > 0.500) ) {

      lead_time = 0.500;

   }

   lead = (self.enemy.velocity * lead_time);
   tg = (trg + lead);
   if ( (self.weapon == IT_ROCKET_LAUNCHER) ) {

      if ( (self.skil > FL_SWIM) ) {

         traceline (src,tg,TRUE,self);
         if ( (trace_fraction != TRUE) ) {

            tg = (tg - (lead * 0.500));
            traceline (src,tg,TRUE,self);
            if ( (trace_fraction != TRUE) ) {

               tg = (tg - (lead * 0.500));

            }

         }

      }

   }
   return ( tg );

};
vector (vector trg) adjustgrenade = {

   local vector tg;
   local vector tgxy;
   local vector selfxy;
   local vector lead;
   local float xypct;

   tg = trg;
   tgxy = tg;
   tgxy_z = FALSE;
   selfxy = self.origin;
   selfxy_z = FALSE;
   xypct = (vlen ((tgxy - selfxy)) * INVGRENADELEVELDIST);
   if ( (xypct > TRUE) ) {

      if ( (xypct < 12.000) ) {

         tg_z = (tg_z + (GRENADEMAXHEIGHT * (xypct - TRUE)));

      }

   } else {

      tg_z = (tg_z - (GRENADEMAXHEIGHT * (TRUE - xypct)));

   }
   return ( tg );

};
vector () botaim = {

   local vector dir;
   local vector tg;
   local vector lead;
   local vector src;
   local float sk;
   local float rnd;

   if ( REBOUND ) {

      tg = REBOUNDSPOT;

   } else {

      src = self.origin;
      if ( (self.weapon & ((IT_ROCKET_LAUNCHER + IT_SUPER_NAILGUN) + IT_NAILGUN)) ) {

         src = (src + '0.000 0.000 16.000');

      }
      // Object Permanence: aim at last seen position when not visible
      if ( !enemyvisible (self.enemy) ) {

         local float mem_dur;
         mem_dur = (0.500 + (self.skil * 0.250));
         if ( (mem_dur > 1.500) )
            mem_dur = 1.500;
         if ( (time < (self.last_seen_time + mem_dur)) ) {

            tg = self.lastseenpos;

         } else {

            tg = self.enemy.origin;

         }

      } else {

         tg = self.enemy.origin;

      }
      traceline (src,tg,TRUE,self);
      if ( (trace_fraction != TRUE) ) {

         tg = (tg + self.enemy.view_ofs);

      }
      if ( (self.skil > TRUE) ) {

         if ( (self.weapon & IT_ROCKET_LAUNCHER) ) {

            tg = leadtarget (src,tg,0.001);
            if ( (self.origin_z >= self.enemy.origin_z) ) {

               rnd = ((random () * 3.500) + TRUE);
               if ( (self.skil > rnd) ) {

                  tg_z = ((tg_z + self.enemy.mins_z) + FL_SWIM);
                  traceline (src,tg,TRUE,self);
                  if ( (trace_fraction != TRUE) ) {

                     tg_z = ((tg_z - self.enemy.mins_z) - MOVETYPE_WALK);

                  }

               }

            }

         } else {

            if ( (self.weapon & IT_GRENADE_LAUNCHER) ) {

               tg = leadtarget (src,tg,0.002);

            } else {

               if ( ((self.weapon & IT_SUPER_NAILGUN) || (self.weapon & IT_NAILGUN)) ) {

                  rnd = (random () * 0.002);
                  tg = leadtarget (src,tg,rnd);

               }

            }

         }

      }

   }
   if ( (self.weapon == IT_GRENADE_LAUNCHER) ) {

      tg = adjustgrenade (tg);

   }
   sk = self.skil;
   if ( (self.weapon == IT_LIGHTNING) ) {

      if ( (sk > 2.500) ) {

         sk = 2.500;

      }

   }
   if ( (sk < MOVETYPE_WALK) ) {

      lead = (self.enemy.origin - self.enemy.oldorigin);
      lead = (((lead * (MOVETYPE_WALK - sk)) * 3.500) * (random () - 0.500));
      tg = (tg + lead);

   }
   dir = normalize ((tg - self.origin));

   // FIX: Skill-based Aim Jitter - low-skill bots should miss more
   // Skill 3+ = perfect aim, Skill 0 = ~25 degree max error
   // Previous code used 0.06 multiplier (~10 deg max) which was barely noticeable
   if ( (sk < MOVETYPE_WALK) ) {

      dir = (dir + (((MOVETYPE_WALK - sk) * crandom ()) * '0.150 0.000 0.000'));
      dir = (dir + (((MOVETYPE_WALK - sk) * crandom ()) * '0.000 0.150 0.000'));
      dir = (dir + (((MOVETYPE_WALK - sk) * crandom ()) * '0.000 0.000 0.100'));

   }
   dir = normalize (dir);
   return ( dir );

};
float () CheckBotAttack = {

   local vector spot1;
   local vector spot2;
   local entity targ;

   targ = self.enemy;
   if ( (time < self.attack_finished) ) {

      return ( FALSE );

   }
   spot1 = (self.origin + self.view_ofs);
   spot2 = (targ.origin + targ.view_ofs);
   traceline (spot1,spot2,FALSE,self);
   if ( (trace_ent != targ) ) {

      return ( FALSE );

   }
   if ( (trace_inopen && trace_inwater) ) {

      spot2 = targ.origin;
      traceline (spot1,spot2,FALSE,self);
      if ( (trace_inopen && trace_inwater) ) {

         return ( FALSE );

      }

   }
   self.attack_state = AS_MELEE;
   return ( TRUE );

};
float () W_BestBotWeapon = {

   local float it;
   local float rng;
   local float wlevel;
   local float dist;

   it = self.items;
   dist = FALSE;
   if ( self.enemy ) {

      dist = vlen ((self.enemy.origin - self.origin));

   } else {

      dist = 500.000;  // Assume mid-range when roaming

   }
   rng = botrange (self.enemy);

   // --- CLOSE QUARTERS COMBAT (< 150 units) ---
   // Prioritize high DPS non-explosive weapons to avoid suicide
   if ( (dist < 150.000) ) {

      // Super Nailgun: best close-range DPS, no splash
      if ( ((self.ammo_nails >= FL_SWIM) && (it & IT_SUPER_NAILGUN)) ) {

         return ( IT_SUPER_NAILGUN );

      }
      // Super Shotgun: excellent close-range burst
      if ( ((self.ammo_shells >= FL_SWIM) && (it & IT_SUPER_SHOTGUN)) ) {

         return ( IT_SUPER_SHOTGUN );

      }
      // Thunderbolt: devastating if not in water
      if ( ((self.ammo_cells >= TRUE) && (it & IT_LIGHTNING)) ) {

         wlevel = CheckWaterLevel ();
         if ( (wlevel < FL_SWIM) ) {

            return ( IT_LIGHTNING );

         }

      }
      // Nailgun: decent fallback
      if ( ((self.ammo_nails >= TRUE) && (it & IT_NAILGUN)) ) {

         return ( IT_NAILGUN );

      }
      // Shotgun: last ranged option before axe
      if ( ((self.ammo_shells >= TRUE) && (it & IT_SHOTGUN)) ) {

         return ( IT_SHOTGUN );

      }
      // Only use explosives at close range with Quad (risk is worth it)
      if ( (self.items & IT_QUAD) ) {

         if ( ((self.ammo_rockets >= TRUE) && (it & IT_ROCKET_LAUNCHER)) ) {

            return ( IT_ROCKET_LAUNCHER );

         }

      }
      // Axe as last resort at close range
      return ( IT_AXE );

   }

   // --- STANDARD COMBAT (>= 150 units) ---

   // Thunderbolt: best DPS at close-mid range, check water safety
   if ( ((self.ammo_cells >= TRUE) && (it & IT_LIGHTNING)) ) {

      if ( ((rng == RANGE_MELEE) || (rng == RANGE_NEAR)) ) {

         wlevel = CheckWaterLevel ();
         if ( (wlevel < FL_SWIM) ) {

            return ( IT_LIGHTNING );

         }
         if ( (self.items & IT_INVULNERABILITY) ) {

            return ( IT_LIGHTNING );

         }

      }

   }

   // Rocket Launcher: high burst damage, safe at this range
   if ( ((self.ammo_rockets >= TRUE) && (it & IT_ROCKET_LAUNCHER)) ) {

      return ( IT_ROCKET_LAUNCHER );

   }

   // Super Nailgun: reliable at all ranges
   if ( ((self.ammo_nails >= FL_SWIM) && (it & IT_SUPER_NAILGUN)) ) {

      return ( IT_SUPER_NAILGUN );

   }

   // Grenade Launcher: good at mid-range (150-600 units), bad at long range
   if ( ((self.ammo_rockets >= TRUE) && (it & IT_GRENADE_LAUNCHER)) ) {

      if ( (dist < 600.000) ) {

         if ( (self.enemy.origin_z < (self.origin_z + 175.000)) ) {

            return ( IT_GRENADE_LAUNCHER );

         }

      }

   }

   // Prefer nails over shotguns at long range (> 500 units)
   if ( (dist > 500.000) ) {

      if ( ((self.ammo_nails >= TRUE) && (it & IT_NAILGUN)) ) {

         return ( IT_NAILGUN );

      }

   }

   // Super Shotgun: reliable mid-range fallback
   if ( ((self.ammo_shells >= FL_SWIM) && (it & IT_SUPER_SHOTGUN)) ) {

      return ( IT_SUPER_SHOTGUN );

   }

   // Nailgun
   if ( ((self.ammo_nails >= TRUE) && (it & IT_NAILGUN)) ) {

      return ( IT_NAILGUN );

   }

   // Shotgun
   if ( ((self.ammo_shells >= TRUE) && (it & IT_SHOTGUN)) ) {

      return ( IT_SHOTGUN );

   }

   return ( IT_AXE );

};
float () W_BestHeldWeapon = {

   local float it;
   local float wlevel;
   local float dist;

   it = self.items;
   dist = FALSE;
   if ( self.enemy ) {

      dist = vlen ((self.enemy.origin - self.origin));

   } else {

      dist = 500.000;  // Assume mid-range when roaming

   }

   // --- CLOSE QUARTERS (< 150 units) ---
   // Called from W_BotAttack as safety fallback, prioritize non-explosives
   if ( (dist < 150.000) ) {

      // Super Nailgun: best close-range DPS
      if ( ((self.ammo_nails >= FL_SWIM) && (it & IT_SUPER_NAILGUN)) ) {

         return ( IT_SUPER_NAILGUN );

      }
      // Super Shotgun: excellent close-range burst
      if ( ((self.ammo_shells >= FL_SWIM) && (it & IT_SUPER_SHOTGUN)) ) {

         return ( IT_SUPER_SHOTGUN );

      }
      // Thunderbolt: devastating if not in water
      if ( ((self.ammo_cells >= TRUE) && (it & IT_LIGHTNING)) ) {

         wlevel = CheckWaterLevel ();
         if ( (wlevel < FL_SWIM) ) {

            return ( IT_LIGHTNING );

         }

      }
      // Nailgun: decent fallback
      if ( ((self.ammo_nails >= TRUE) && (it & IT_NAILGUN)) ) {

         return ( IT_NAILGUN );

      }
      // Shotgun
      if ( ((self.ammo_shells >= TRUE) && (it & IT_SHOTGUN)) ) {

         return ( IT_SHOTGUN );

      }
      // Only explosives at close range with Quad
      if ( (self.items & IT_QUAD) ) {

         if ( ((self.ammo_rockets >= TRUE) && (it & IT_ROCKET_LAUNCHER)) ) {

            return ( IT_ROCKET_LAUNCHER );

         }

      }
      return ( IT_AXE );

   }

   // --- STANDARD (>= 150 units) ---

   // Thunderbolt: check water safety
   if ( ((self.ammo_cells >= TRUE) && (it & IT_LIGHTNING)) ) {

      wlevel = CheckWaterLevel ();
      if ( (wlevel < FL_SWIM) ) {

         return ( IT_LIGHTNING );

      }
      if ( (self.items & IT_INVULNERABILITY) ) {

         return ( IT_LIGHTNING );

      }

   }

   // Rocket Launcher: safe at this range
   if ( ((self.ammo_rockets >= TRUE) && (it & IT_ROCKET_LAUNCHER)) ) {

      return ( IT_ROCKET_LAUNCHER );

   }

   // Super Nailgun
   if ( ((self.ammo_nails >= FL_SWIM) && (it & IT_SUPER_NAILGUN)) ) {

      return ( IT_SUPER_NAILGUN );

   }

   // Grenade Launcher: mid-range only (< 600 units)
   if ( ((self.ammo_rockets >= TRUE) && (it & IT_GRENADE_LAUNCHER)) ) {

      if ( (dist < 600.000) ) {

         if ( (self.enemy.origin_z < (self.origin_z + 175.000)) ) {

            return ( IT_GRENADE_LAUNCHER );

         }

      }

   }

   // Prefer nails at long range
   if ( (dist > 500.000) ) {

      if ( ((self.ammo_nails >= TRUE) && (it & IT_NAILGUN)) ) {

         return ( IT_NAILGUN );

      }

   }

   // Super Shotgun
   if ( ((self.ammo_shells >= FL_SWIM) && (it & IT_SUPER_SHOTGUN)) ) {

      return ( IT_SUPER_SHOTGUN );

   }

   // Nailgun
   if ( ((self.ammo_nails >= TRUE) && (it & IT_NAILGUN)) ) {

      return ( IT_NAILGUN );

   }

   // Shotgun
   if ( ((self.ammo_shells >= TRUE) && (it & IT_SHOTGUN)) ) {

      return ( IT_SHOTGUN );

   }

   return ( IT_AXE );

};

void () bot_axe1;

void () bot_axeb1;

void () bot_axec1;

void () bot_axed1;

void () bot_shot1;

void () bot_nail1;

void () bot_light1;

void () bot_rocket1;

void () W_BotAttack = {

   local float r;
   local float addt;

   if ( !W_CheckNoAmmo () ) {

      return ;

   }
   if ( (time < self.attack_finished) ) {

      return ;

   }

   // FIX: Splash Damage Safety - don't fire explosives at close range
   // Rockets/grenades at <150 units will likely kill or heavily damage self
   if ( (self.weapon == IT_ROCKET_LAUNCHER) || (self.weapon == IT_GRENADE_LAUNCHER) ) {

      if ( (vlen ((self.enemy.origin - self.origin)) < 150.000) ) {

         // Switch to a safer weapon instead of suiciding
         self.weapon = W_BestHeldWeapon ();
         W_SetCurrentAmmo ();
         return ;

      }

   }

   // FIX: Thunderbolt Water Safety - discharging in water is instant death
   if ( (self.weapon == IT_LIGHTNING) ) {

      if ( (self.waterlevel >= FL_SWIM) ) {

         // Switch weapon - don't suicide by discharge
         self.weapon = W_BestHeldWeapon ();
         W_SetCurrentAmmo ();
         return ;

      }

   }

   addt = FALSE;
   if ( (self.skil < MOVETYPE_WALK) ) {

      addt = (((MOVETYPE_WALK - self.skil) * random ()) * 0.350);

   }
   if ( (self.skil < TRUE) ) {

      addt = (addt + (random () * 0.300));

   }
   makevectors (self.v_angle);
   self.show_hostile = (time + TRUE);
   if ( (self.weapon == IT_AXE) ) {

      sound (self,CHAN_WEAPON,"weapons/ax1.wav",TRUE,ATTN_NORM);
      r = random ();
      if ( (r < 0.250) ) {

         bot_axe1 ();

      } else {

         if ( (r < 0.500) ) {

            bot_axeb1 ();

         } else {

            if ( (r < 0.750) ) {

               bot_axec1 ();

            } else {

               bot_axed1 ();

            }

         }

      }
      self.attack_finished = ((time + 0.500) + addt);

   } else {

      if ( (self.weapon == IT_SHOTGUN) ) {

         bot_shot1 ();
         W_FireShotgun ();
         self.attack_finished = ((time + 0.500) + addt);

      } else {

         if ( (self.weapon == IT_SUPER_SHOTGUN) ) {

            bot_shot1 ();
            W_FireSuperShotgun ();
            self.attack_finished = ((time + 0.700) + addt);

         } else {

            if ( (self.weapon == IT_NAILGUN) ) {

               self.think = bot_nail1;

            } else {

               if ( (self.weapon == IT_SUPER_NAILGUN) ) {

                  self.think = bot_nail1;

               } else {

                  if ( (self.weapon == IT_GRENADE_LAUNCHER) ) {

                     bot_rocket1 ();
                     W_FireGrenade ();
                     self.attack_finished = ((time + 0.600) + addt);

                  } else {

                     if ( (self.weapon == IT_ROCKET_LAUNCHER) ) {

                        bot_rocket1 ();
                        W_FireRocket ();
                        self.attack_finished = ((time + 0.800) + addt);

                     } else {

                        if ( (self.weapon == IT_LIGHTNING) ) {

                           self.think = bot_light1;
                           self.attack_finished = (time + 0.100);
                           sound (self,CHAN_AUTO,"weapons/lstart.wav",TRUE,ATTN_NORM);

                        }

                     }

                  }

               }

            }

         }

      }

   }

};

void () bot_rebound1;
float () CheckReboundAttack = {

   local vector spot1;
   local vector spot2;
   local vector dir;
   local float dist;
   local float mel;

   if ( (self.skil < TRUE) ) {

      return ( FALSE );

   }
   if ( (self.attack_finished > time) ) {

      return ( FALSE );

   }
   if ( !(self.items & (IT_ROCKET_LAUNCHER + IT_GRENADE_LAUNCHER)) ) {

      return ( FALSE );

   }
   if ( (self.ammo_rockets < MOVETYPE_WALK) ) {

      return ( FALSE );

   }
   spot1 = self.origin;
   spot2 = self.goalentity.origin;
   traceline (spot1,spot2,FALSE,self);
   if ( (trace_fraction < TRUE) ) {

      return ( FALSE );

   }
   dir = normalize ((self.goalentity.origin - self.origin));
   spot2 = (spot2 + (200.000 * dir));
   traceline (spot1,spot2,TRUE,self);
   if ( (trace_fraction == TRUE) ) {

      if ( (self.origin_z < self.goalentity.origin_z) ) {

         return ( FALSE );

      }
      spot2 = self.goalentity.origin;
      spot2_z = (dropline (spot2) + MOVETYPE_WALK);
      traceline (spot1,spot2,TRUE,self);
      if ( (trace_fraction != TRUE) ) {

         return ( FALSE );

      }

   } else {

      spot2 = (self.goalentity.origin + ((200.000 * dir) * trace_fraction));

   }
   dist = vlen ((self.enemy.origin - spot2));
   mel = 200.000;
   if ( (self.items & IT_QUAD) ) {

      mel = (FL_SWIM * mel);

   }
   if ( (dist > mel) ) {

      return ( FALSE );

   }
   dist = vlen ((self.origin - spot2));
   mel = ((280.000 - (self.health * 0.500)) - (self.armorvalue * self.armortype));
   if ( (self.items & IT_QUAD) ) {

      mel = (FL_SWIM * mel);

   }
   if ( (dist < mel) ) {

      return ( FALSE );

   }
   REBOUNDSPOT = spot2;
   REBOUND = TRUE;
   self.ideal_yaw = vectoyaw ((spot2 - self.origin));
   ChangeYaw ();
   bot_rebound1 ();
   if ( (self.items & IT_ROCKET_LAUNCHER) ) {

      W_FireRocket ();

   } else {

      REBOUNDSPOT = (spot2 + (random () * '12.000 12.000 12.000'));
      W_FireGrenade ();

   }
   self.attack_finished = (time + TRUE);
   if ( (self.skil < FL_SWIM) ) {

      self.attack_finished = (time + 1.500);

   }
   REBOUND = FALSE;

};
