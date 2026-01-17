
// FIX: Removed halfwalkmove - the 0.05s sub-frame timing caused network
// interpolation issues ("jumpy" strafing). Movement now happens in single
// frames with velocity set for smooth client-side prediction.

// Forward declarations for functions used before they're defined
void (float dist) Botmovetogoal;
void () ChangeYaw;
float () FacingIdeal;
void (float shotcount, vector dir, vector spread) FireBullets;

// FIX: Platform riding - handles func_train (DM2 lava platforms) and func_plat
// Returns TRUE if bot should wait/ride, FALSE to continue with normal movement
float () BotCheckPlatformRide = {

   local entity plat;

   if ( !(self.flags & FL_ONGROUND) ) {
      self.riding_platform = world;
      return ( FALSE );
   }

   plat = self.groundentity;

   // Check if standing on any moving platform (MOVETYPE_PUSH)
   if ( plat.movetype != MOVETYPE_PUSH ) {
      self.riding_platform = world;
      return ( FALSE );
   }

   // func_train: horizontal moving platforms (DM2 lava room)
   // Inherit platform velocity to prevent sliding off
   if ( plat.classname == "train" ) {
      self.velocity = plat.velocity;
      self.riding_platform = plat;
      // Stay on the platform - don't try to walk
      return ( TRUE );
   }

   // func_plat: vertical lifts - wait for them to move us
   if ( (plat.classname == "func_plat") || (plat.classname == "plat") ) {
      // If the plat is moving UP or at TOP, wait for it
      if ( (plat.state == STATE_UP) || (plat.state == STATE_TOP) ) {
         self.velocity = '0 0 0';
         return ( TRUE );
      }
      // If plat is at BOTTOM, wait for it to trigger and rise
      if ( plat.state == STATE_BOTTOM ) {
         self.velocity = '0 0 0';
         return ( TRUE );
      }
   }

   return ( FALSE );

};

// FIX: Find a button that triggers the given door
// Returns button entity or world if none found
entity (entity blocking_door) BotFindButton = {

   local entity btn;
   local entity best;
   local float best_dist;
   local float dist;

   // Door must have a targetname to be triggered by a button
   if ( !blocking_door.targetname ) {
      return ( world );
   }

   best = world;
   best_dist = 100000;

   // Search for func_button entities whose target matches door's targetname
   btn = find (world, classname, "func_button");
   while ( btn ) {

      if ( btn.target == blocking_door.targetname ) {

         dist = vlen (btn.origin - self.origin);
         if ( dist < best_dist ) {
            best = btn;
            best_dist = dist;
         }

      }
      btn = find (btn, classname, "func_button");

   }

   return ( best );

};

// FIX: Attempt to solve a blocked door by finding and activating its button
// Returns TRUE if bot is now handling the door, FALSE if no solution
float (entity door) BotSolveDoor = {

   local entity btn;
   local vector btn_center;

   // Only handle doors that need external triggers
   if ( !door.targetname ) {
      return ( FALSE );
   }

   // Find the button
   btn = BotFindButton (door);

   if ( !btn ) {
      return ( FALSE );  // No button found
   }

   // Store state
   self.blocking_door = door;
   self.target_button = btn;

   // Redirect goal to button location
   if ( self.goalentity.classname == "BotTarget" ) {
      btn_center = (btn.absmin + btn.absmax) * 0.5;
      setorigin (self.goalentity, btn_center);
      self.goalentity.goalentity = btn;
   }

   // Mark that we're solving a button puzzle
   self.lefty = self.lefty | SOLVE_BUTTON;
   self.search_time = time + 8;  // Give 8 seconds to solve

   return ( TRUE );

};

// FIX: Handle button interaction each frame when in SOLVE_BUTTON mode
// Called from ai_botseek when SOLVE_BUTTON flag is set
void (float dist) BotHandleButton = {

   local entity btn;
   local float btn_dist;
   local vector btn_center;

   btn = self.target_button;

   // Button gone or already pressed?
   if ( !btn || btn.state != STATE_BOTTOM ) {
      // Clear button solving mode
      self.lefty = self.lefty - (self.lefty & SOLVE_BUTTON);
      self.blocking_door = world;
      self.target_button = world;
      return;
   }

   btn_center = (btn.absmin + btn.absmax) * 0.5;
   btn_dist = vlen (btn_center - self.origin);

   // Shootable button (has health)
   if ( btn.health > 0 ) {

      if ( btn_dist < 500 ) {

         // Close enough to shoot - face and fire
         self.ideal_yaw = vectoyaw (btn_center - self.origin);
         ChangeYaw ();

         // Check if we're facing the button (within ~15 degrees)
         if ( FacingIdeal () ) {
            // Fire at the button using shotgun
            local vector dir;
            dir = normalize (btn_center - (self.origin + self.view_ofs));
            FireBullets (4, dir, '0.04 0.04 0');
            self.attack_finished = time + 0.5;
         }

      } else {

         // Move closer to the button
         Botmovetogoal (dist);

      }
      return;

   }

   // Touch-triggered button - walk to it
   if ( btn_dist > 32 ) {
      Botmovetogoal (dist);
   }
   // When close enough, the button's touch function will trigger it

};

// =========================================================================
// SENSOR FUSION STEERING SYSTEM
// =========================================================================

// UTILITY: Detects "Death Drops" (Lava, Slime, or The Void)
// Returns TRUE if the spot is dangerous.
float (vector spot) BotDetectHazard = {

   local vector down;
   local float content;

   // 1. Look down 48 units (simulates looking over a ledge)
   down = spot;
   down_z = down_z - 48;

   traceline (spot, down, TRUE, self);

   // 2. Check for Void (Sky/Empty space below)
   // If trace_fraction is 1.0, we hit nothing. That's a cliff.
   if ( trace_fraction == 1.0 ) {
      return TRUE;
   }

   // 3. Check for Liquid Hazards (Lava/Slime)
   content = pointcontents (trace_endpos);
   if ( (content == CONTENT_LAVA) || (content == CONTENT_SLIME) ) {
      return TRUE;
   }

   // 4. Check for Sky brushes (falling out of map)
   if ( content == CONTENT_SKY ) {
      return TRUE;
   }

   return FALSE;

};

// CORE: Vector-Based Steering (Sensor Fusion)
// Instead of turning, we calculate forces:
// Goal Force + Wall Repulsion + Hazard Repulsion = Final Flow Angle
float (float ideal_yaw, float speed_factor) BotSteer = {

   local vector steer_dir;  // The final accumulation vector
   local vector feeler;     // Temp vector for whisker directions
   local vector start, end_pos;
   local vector fwd, rt;
   local float dist;

   // Configuration
   // Look further ahead when moving fast (Speed * 0.1s prediction)
   dist = 50 + (speed_factor * 25);
   start = self.origin + '0 0 16';  // Waist height sensor origin

   // 1. PRIMARY FORCE: The Desire to reach the goal
   // We start with the direction the AI *wants* to go.
   makevectors ('0 1 0' * ideal_yaw);
   fwd = v_forward;
   rt = v_right;
   steer_dir = fwd;

   // 2. SENSOR 1: The "Center Whisker" (Head-on Collision)
   end_pos = start + (fwd * dist);
   traceline (start, end_pos, TRUE, self);

   if ( trace_fraction < 1.0 ) {
      // HIT WALL: Add strong repulsion perpendicular to the wall
      // trace_plane_normal is the vector pointing OUT of the wall.
      // We multiply by 3.0 to overpower the "Desire" force.
      steer_dir = steer_dir + (trace_plane_normal * 3.0);
   } else if ( BotDetectHazard (end_pos) ) {
      // HIT HAZARD: Cliff/Lava ahead!
      // Apply "Braking Force" (Negative forward) + Random Jitter to break deadlock
      steer_dir = steer_dir + (fwd * -4.0);
      steer_dir_x = steer_dir_x + (random () * 2 - 1);  // Slight noise to help turn
   }

   // 3. SENSOR 2: The "Left Whisker" (-45 degrees)
   // Manually construct -45 deg vector relative to forward/right
   feeler = (fwd * 0.7) - (rt * 0.7);
   end_pos = start + (feeler * (dist * 0.8));  // Slightly shorter than center

   traceline (start, end_pos, TRUE, self);
   if ( trace_fraction < 1.0 ) {
      // Hit Left Wall -> Push Right (along normal)
      steer_dir = steer_dir + (trace_plane_normal * 1.5);
   } else if ( BotDetectHazard (end_pos) ) {
      // Hazard Left -> Push Right hard
      steer_dir = steer_dir + (rt * 2.0);
   }

   // 4. SENSOR 3: The "Right Whisker" (+45 degrees)
   feeler = (fwd * 0.7) + (rt * 0.7);
   end_pos = start + (feeler * (dist * 0.8));

   traceline (start, end_pos, TRUE, self);
   if ( trace_fraction < 1.0 ) {
      // Hit Right Wall -> Push Left (along normal)
      steer_dir = steer_dir + (trace_plane_normal * 1.5);
   } else if ( BotDetectHazard (end_pos) ) {
      // Hazard Right -> Push Left hard
      steer_dir = steer_dir + (rt * -2.0);
   }

   // 5. RESOLVE FORCES
   // Normalize the result to get a clean direction
   steer_dir = normalize (steer_dir);

   // Convert back to Yaw angle
   return vectoyaw (steer_dir);

};

float (float s_yaw, float s_dist) botwalkmove = {

   local float flow_yaw;
   local float moved;
   local vector jump_check;

   self.oldorigin = self.origin;

   // Bounce mode (knockback) - don't interfere
   if ( self.movetype == MOVETYPE_BOUNCE ) {
      return FALSE;
   }

   // Knockback / Rocket Jump Support
   // If airborne with significant velocity, let physics take over
   if ( !(self.flags & FL_ONGROUND) ) {
      if ( vlen (self.velocity) > 350 ) {
         return FALSE;
      }
   }

   // Platform riding - handles func_train (DM2) and func_plat
   if ( BotCheckPlatformRide () ) {
      return TRUE;
   }

   // --- EXECUTE SENSOR FUSION ---
   // Calculate the best path through the geometry using vector-based steering
   // This handles walls AND hazards (lava, slime, cliffs) in one unified system
   flow_yaw = BotSteer (s_yaw, 1.0);

   // Try to move using the calculated Flow Angle
   moved = walkmove (flow_yaw, s_dist);

   if ( moved ) {
      // MOVEMENT SUCCESS

      // 1. Velocity Matching (Fixes teleport/jitter)
      makevectors ('0 1 0' * flow_yaw);
      self.velocity_x = v_forward_x * s_dist * 10.0;
      self.velocity_y = v_forward_y * s_dist * 10.0;

      // 2. Ground Glue (Fixes z-axis jitter on stairs/ramps)
      if ( self.flags & FL_ONGROUND ) {
         self.velocity_z = -20;
      }

      // 3. Visual Turn Smoothing
      // If the Flow Angle differs significantly from intention,
      // update the bot's facing so it "looks into the turn"
      if ( fabs (flow_yaw - self.ideal_yaw) > 5 ) {
         self.ideal_yaw = flow_yaw;
         ChangeYaw ();
      }

      return TRUE;
   }

   // MOVEMENT FAILED (Stuck or blocked)

   // Door Interaction - check if we hit a door
   makevectors ('0 1 0' * flow_yaw);
   traceline (self.origin, self.origin + (v_forward * 32), FALSE, self);

   if ( (trace_ent.classname == "func_door") || (trace_ent.classname == "func_door_rotating") ) {

      // Check if door requires a button (has targetname on owner)
      local entity door_master;
      door_master = trace_ent;
      if ( trace_ent.owner ) {
         door_master = trace_ent.owner;
      }

      if ( door_master.targetname ) {
         // Door needs external trigger - try to find its button
         if ( BotSolveDoor (door_master) ) {
            self.velocity = v_forward * -100;
            return FALSE;
         }
      }

      // Auto-open door - trigger it directly if it has a use function
      if ( trace_ent.use ) {
         trace_ent.use ();
      }

      // Back up slightly to let it open
      self.velocity = v_forward * -200;
      return FALSE;

   }

   // The Stuck Doctor:
   // If stuck against a low obstacle or weird geometry, try to JUMP over it
   if ( self.flags & FL_ONGROUND ) {

      // Check if the spot slightly above and ahead is clear
      jump_check = self.origin + (v_forward * 32);
      jump_check_z = jump_check_z + 18;  // Step height + margin

      if ( pointcontents (jump_check) == CONTENT_EMPTY ) {
         // Jump to clear the obstacle
         self.velocity_z = 270;
         self.flags = self.flags - FL_ONGROUND;
         sound (self, CHAN_BODY, "player/plyrjmp8.wav", 1, ATTN_NORM);
         return FALSE;
      }

   }

   // Reset velocity so client prediction doesn't slide us into the wall
   self.velocity_x = 0;
   self.velocity_y = 0;

   return FALSE;

};
float (float dist) teleptest = {

   local vector start;
   local vector up;
   local vector target;

   up = self.origin;
   start = self.origin;
   if ( (dist < FALSE) ) {

      up_z = ((self.absmin_z + dist) - TRUE);

   } else {

      up_z = ((self.absmax_z + dist) + TRUE);

   }
   traceline (start,up,FALSE,self);
   if ( (trace_fraction < TRUE) ) {

      return ( FALSE );

   }
   start_x = (start_x + FL_INWATER);
   start_y = (start_y + FL_INWATER);
   up_x = (up_x + FL_INWATER);
   up_y = (up_y + FL_INWATER);
   traceline (start,up,FALSE,self);
   if ( (trace_fraction < TRUE) ) {

      return ( FALSE );

   }
   start_x = (start_x - FL_MONSTER);
   up_x = (up_x - FL_MONSTER);
   traceline (start,up,FALSE,self);
   if ( (trace_fraction < TRUE) ) {

      return ( FALSE );

   }
   start_y = (start_y - FL_MONSTER);
   up_y = (up_y - FL_MONSTER);
   traceline (start,up,FALSE,self);
   if ( (trace_fraction < TRUE) ) {

      return ( FALSE );

   }
   start_x = (start_x + FL_MONSTER);
   up_x = (up_x + FL_MONSTER);
   traceline (start,up,FALSE,self);
   if ( (trace_fraction < TRUE) ) {

      return ( FALSE );

   }
   start = self.origin;
   start_z = up_z;
   up = start;
   start_x = (start_x + FL_INWATER);
   up_x = (up_x - FL_INWATER);
   traceline (start,up,FALSE,self);
   if ( (trace_fraction < TRUE) ) {

      return ( FALSE );

   }
   start = self.origin;
   start_z = up_z;
   up = start;
   start_y = (start_y + FL_INWATER);
   up_y = (up_y - FL_INWATER);
   traceline (start,up,FALSE,self);
   if ( (trace_fraction < TRUE) ) {

      return ( FALSE );

   }

   // FIX: Additional checks to prevent "flashing" from teleporting into bad positions
   // Check headroom at target position (player height is ~56 units)
   target = self.origin;
   target_z = (target_z + dist);
   up = target;
   up_z = (up_z + 32.000);
   traceline (target, up, TRUE, self);
   if ( (trace_fraction < TRUE) ) {

      return ( FALSE );

   }

   // Check floor footing at target - must hit something (not void)
   up = target;
   up_z = (up_z - 24.000);
   traceline (target, up, TRUE, self);
   if ( (trace_fraction == TRUE) ) {

      // Falling into void - don't teleport
      return ( FALSE );

   }

   return ( TRUE );

};
float (float dist) waterupz = {

   local vector start;
   local vector up;

   if ( !teleptest (dist) ) {

      return ( FALSE );

   }
   up = self.origin;
   up_z = (up_z + dist);
   setorigin (self,up);
   return ( TRUE );

};
float (float dist) waterdownz = {

   local vector up;
   local vector start;

   if ( !teleptest ((CONTENT_EMPTY * dist)) ) {

      return ( FALSE );

   }
   up = self.origin;
   up_z = (up_z - dist);
   setorigin (self,up);
   return ( TRUE );

};
float (vector jmpv) Botjump = {

   if ( (self.flags & FL_ONGROUND) ) {

      self.flags = (self.flags - FL_ONGROUND);
    }
    sound (self, CHAN_BODY, "player/plyrjmp8.wav", 1, ATTN_NORM);
    self.velocity = jmpv;
    return ( TRUE );
 };

float (vector jmpv) Botwaterjump = {

   if ( (self.flags & FL_ONGROUND) ) {

      self.flags = (self.flags - FL_ONGROUND);

   }
   if ( !waterupz (45.000) ) {

      return ( FALSE );

   }
   jmpv_z = 200.000;
   self.velocity = jmpv;
   if ( (self.flags & FL_SWIM) ) {

      self.flags = (self.flags - FL_SWIM);

   }
   if ( (self.flags & FL_INWATER) ) {

      self.flags = (self.flags - FL_INWATER);

   }
   self.teleport_time = (time + 0.700);
      return ( TRUE );

};
float (entity targ) Swimto;
float (vector spot) CheckLavaOrLow = {

   local float lnd;
   local float boost;
   local vector spot2;

   lnd = pointcontents (spot);
   if ( ((lnd == CONTENT_LAVA) || (lnd == CONTENT_SLIME)) ) {

      return ( TRUE );

   }
   spot2 = spot;
   spot2_z = (spot_z + FL_CLIENT);
   lnd = pointcontents (spot2);
   if ( ((lnd == CONTENT_LAVA) || (lnd == CONTENT_SLIME)) ) {

      return ( TRUE );

   }
   if ( (lnd != CONTENT_WATER) ) {

      boost = (MAXJUMP + TRUE);
      if ( (self.goalentity.goalentity.classname == "func_button") ) {

         boost = ((boost + self.maxs_z) - TRUE);

      }
      if ( ((spot_z + boost) < self.goalentity.origin_z) ) {

         return ( TRUE );

      }

   } else {

      traceline (spot2,self.goalentity.absmin,TRUE,self);
      if ( trace_inopen ) {

         if ( ((spot_z + 45.000) > self.goalentity.origin_z) ) {

            return ( FALSE );

         }
         return ( TRUE );

      }
      if ( (trace_fraction == TRUE) ) {

         return ( FALSE );

      }
      return ( TRUE );

   }
   return ( FALSE );

};
float (vector middle) checkLanding = {

   local float goodcnt;
   local vector spot;
   local vector center;

   center = middle;
   spot = middle;
   spot_x = (spot_x + MOVETYPE_TOSS);
   if ( (pointcontents (spot) == CONTENT_SOLID) ) {

      center_x = (center_x - MOVETYPE_TOSS);

   }
   spot_x = (spot_x - 12.000);
   if ( (pointcontents (spot) == CONTENT_SOLID) ) {

      center_x = (center_x + MOVETYPE_TOSS);

   }
   spot = middle;
   spot_y = (spot_y + MOVETYPE_TOSS);
   if ( (pointcontents (spot) == CONTENT_SOLID) ) {

      center_y = (center_y - MOVETYPE_TOSS);

   }
   spot_y = (spot_y - 12.000);
   if ( (pointcontents (spot) == CONTENT_SOLID) ) {

      center_y = (center_y + MOVETYPE_TOSS);

   }
   spot = center;
   spot_z = dropline (spot);
   goodcnt = MOVETYPE_FLY;
   if ( CheckLavaOrLow (spot) ) {

      return ( FALSE );

   }
   spot = center;
   spot_x = (spot_x + MOVETYPE_TOSS);
   spot_z = dropline (spot);
   if ( CheckLavaOrLow (spot) ) {

      goodcnt = (goodcnt - TRUE);

   }
   spot = center;
   spot_x = (spot_x - MOVETYPE_TOSS);
   spot_z = dropline (spot);
   if ( CheckLavaOrLow (spot) ) {

      goodcnt = (goodcnt - TRUE);

   }
   spot = center;
   spot_y = (spot_y + MOVETYPE_TOSS);
   spot_z = dropline (spot);
   if ( CheckLavaOrLow (spot) ) {

      goodcnt = (goodcnt - TRUE);

   }
   spot = center;
   spot_y = (spot_y - MOVETYPE_TOSS);
   spot_z = dropline (spot);
   if ( CheckLavaOrLow (spot) ) {

      goodcnt = (goodcnt - TRUE);

   }
   if ( (goodcnt > MOVETYPE_WALK) ) {

      return ( TRUE );

   }
   return ( FALSE );

};
float (float dist) JumpUpToPush = {

   local float len;
   local vector botxy;
   local vector goalxy;
   local vector xydir;
   local vector jumpv;

   botxy = self.origin;
   botxy_z = FALSE;
   goalxy = self.goalentity.origin;
   goalxy_z = FALSE;
   xydir = normalize ((goalxy - botxy));
   len = vlen ((goalxy - botxy));
   if ( (len < 25.000) ) {

      jumpv = (xydir * KINDA_WANT);
      jumpv_z = 270.000;
      Botjump (jumpv);
      return ( TRUE );

   }
   if ( (len < 80.000) ) {

      jumpv = (xydir * (len / LEVELJUMPTIME));
      jumpv_z = 270.000;
      Botjump (jumpv);
      return ( TRUE );

   }
   return ( FALSE );

};
float /* Warning: Could not determine return type */ (float vz, float dist, float imagine) Bot_tryjump = {

   local float timetofloor;
   local float tvel;
   local float dis;
   local float diffz;
   local float diffxy;
   local float NOTLAND;
   local float lnd;
   local float len;
   local float depth;
   local float wlevel;
   local float velz;
   local float ht;
   local float frac;
   local float safety;
   local vector botxy;
   local vector goalxy;
   local vector xydir;
   local vector top;
   local vector bottom;
   local vector jumpv;
   local vector newtop;
   local vector newbottom;
   local vector back;
   local vector front;
   local vector dir;
   local vector start;
   local string tmp;
   local entity botTarget;

   if ( !(self.flags & (FL_ONGROUND + FL_SWIM)) ) {

      return ( FALSE );

   }
   wlevel = CheckWaterLevel ();
   if ( (wlevel > FL_SWIM) ) {

      return ( FALSE );

   }
   if ( !FacingIdeal () ) {

      ChangeYaw ();
      if ( !FacingIdeal () ) {

         ChangeYaw ();
         if ( !FacingIdeal () ) {

            ChangeYaw ();

         }

      }

   }
   makevectors (self.angles);
   start = (self.origin + (FL_INWATER * v_forward));
   botTarget = self.goalentity;
   velz = vz;
   if ( (wlevel >= TRUE) ) {

      if ( (velz > 200.000) ) {

         velz = 200.000;

      }

   }
   if ( (wlevel == FL_SWIM) ) {

      if ( (botTarget.origin_z < self.origin_z) ) {

         return ( FALSE );

      }
      start_z = (start_z + 45.000);

   }
   botxy = self.origin;
   botxy_z = FALSE;
   diffz = ((start_z - botTarget.origin_z) + TRUE);
   if ( (diffz < (CONTENT_EMPTY * MAXJUMP)) ) {

      if ( (botTarget.goalentity.classname != "trigger_push") ) {

         return ( FALSE );

      } else {

         if ( (diffz < FALSE) ) {

            if ( JumpUpToPush (dist) ) {

               return ( TRUE );

            }

         }

      }

   }
   dis = dist;
   goalxy = botTarget.origin;
   if ( (botTarget.goalentity.classname == "train") ) {

      goalxy = (goalxy + (LEVELJUMPTIME * botTarget.goalentity.velocity));

   }
   lnd = pointcontents (goalxy);
   if ( ((lnd == CONTENT_LAVA) || (lnd == CONTENT_SLIME)) ) {

      return ( FALSE );

   }
   goalxy_z = FALSE;
   xydir = normalize ((goalxy - botxy));
   diffxy = vlen ((goalxy - botxy));
   if ( (wlevel == FL_SWIM) ) {

      if ( (diffxy > (MOVETYPE_WALK * BOTSPEED)) ) {

         diffxy = (MOVETYPE_WALK * BOTSPEED);

      }

   }
   bottom = (start + self.view_ofs);
   top = (bottom + (xydir * dis));
   top_z = (top_z + (0.100 * (velz - GRAVITY)));
   traceline (bottom,top,TRUE,self);
   if ( (trace_fraction != TRUE) ) {

      if ( (velz > (GRAVITY + 180.000)) ) {

         return ( Bot_tryjump ((velz - GRAVITY),dist,imagine) );

      } else {

         return ( FALSE );

      }

   }
   bottom = (start - (FL_INWATER * v_forward));
   bottom_z = (bottom_z + self.mins_z);
   top = (bottom + ((xydir * dis) * FL_SWIM));
   top_z = ((top_z + (0.200 * (velz - GRAVITY))) - (0.100 * GRAVITY));
   traceline (bottom,top,TRUE,self);
   if ( (trace_fraction != TRUE) ) {

      if ( (diffxy > (1.900 * BOTSPEED)) ) {

         diffxy = (1.900 * BOTSPEED);

      }
      top = (bottom + (xydir * dis));
      top_z = ((top_z + (0.200 * (velz - GRAVITY))) - (0.100 * GRAVITY));
      traceline (bottom,top,TRUE,self);
      if ( (trace_fraction != TRUE) ) {

         if ( (diffxy > (0.900 * BOTSPEED)) ) {

            diffxy = (0.900 * BOTSPEED);

         }
         velz = 290.000;

      }

   }
   timetofloor = FALSE;
   tvel = velz;
   if ( (diffz < FALSE) ) {

      timetofloor = 0.300;

   } else {

      while ( (diffz > FALSE) ) {

         timetofloor = (timetofloor + 0.100);
         tvel = (tvel - GRAVITY);
         diffz = (diffz + (tvel * 0.100));

      }
      timetofloor = (timetofloor - (diffz / tvel));

   }
   if ( (diffxy < ((dis * MOVETYPE_BOUNCE) * timetofloor)) ) {

      jumpv = (xydir * (diffxy / timetofloor));

   } else {

      jumpv = (xydir * (MOVETYPE_BOUNCE * dis));
      if ( imagine ) {

         return ( FALSE );

      }

   }
   tvel = velz;
   bottom = start;
   bottom_z = (bottom_z + self.mins_z);
   ht = (self.view_ofs_z - self.mins_z);
   NOTLAND = TRUE;
   safety = FALSE;  // safety counter for void falls
   while ( NOTLAND ) {

      // Prevent infinite loop if bot jumps into void
      safety = (safety + TRUE);
      if ( (safety > 100.000) ) {

         return ( FALSE );

      }
      tvel = (tvel - GRAVITY);
      newbottom = (bottom + (jumpv * 0.100));
      newbottom_z = (newbottom_z + (tvel * 0.100));
      traceline (bottom,newbottom,TRUE,self);
      frac = trace_fraction;
      if ( (trace_fraction == TRUE) ) {

         newtop = newbottom;
         top = bottom;
         top_z = (top_z + ht);
         newtop_z = (newtop_z + ht);
         traceline (top,newtop,TRUE,self);
         if ( (trace_fraction == TRUE) ) {

            traceline (newbottom,newtop,TRUE,self);

         }
         if ( (trace_fraction == TRUE) ) {

            top = (top + (FL_INWATER * v_right));
            newtop = (newtop + (FL_INWATER * v_right));
            traceline (top,newtop,TRUE,self);

         }
         if ( (trace_fraction == TRUE) ) {

            top = (top - (FL_MONSTER * v_right));
            newtop = (newtop - (FL_MONSTER * v_right));
            traceline (top,newtop,TRUE,self);

         }
         if ( (trace_fraction != TRUE) ) {

            frac = 0.100;

         }

      }
      if ( (trace_fraction != TRUE) ) {

         dir = normalize ((newbottom - bottom));
         len = vlen ((newbottom - bottom));
         newbottom = (bottom + ((dir * len) * frac));
         newbottom_z = (newbottom_z + KINDA_WANT);
         if ( !checkLanding ((newbottom - (FL_INWATER * v_forward))) ) {

            return ( FALSE );

         }
         NOTLAND = FALSE;

      }
      if ( NOTLAND ) {

         if ( CheckLavaOrLow (newbottom) ) {

            return ( FALSE );

         }

      }
      lnd = pointcontents (newbottom);
      if ( (lnd == CONTENT_WATER) ) {

         NOTLAND = FALSE;

      }
      bottom = newbottom;

   }
   jumpv_z = velz;
   if ( imagine ) {

      if ( (wlevel == FL_SWIM) ) {

         return ( teleptest (45.000) );

      }
      return ( TRUE );

   }
   if ( (wlevel == FL_SWIM) ) {

      return ( Botwaterjump (jumpv) );

   }
   if ( (newbottom_z < (self.absmin_z - MAXJUMP)) ) {

      clearCache (self);

   }
   return ( Botjump (jumpv) );

};
float (float dist) waterupdown = {

   local float wlevel;
   local float dis;
   local float rnd;
   local float zbottom;

   dis = KINDA_WANT;
   wlevel = CheckWaterLevel ();
   if ( (wlevel < FL_SWIM) ) {

      return ( FALSE );

   }
   if ( (self.absmin_z > self.goalentity.origin_z) ) {

      if ( (dis > KINDA_WANT) ) {

         dis = KINDA_WANT;

      }
      if ( waterdownz (dis) ) {

         return ( TRUE );

      }
      if ( waterdownz ((dis * 0.500)) ) {

         return ( TRUE );

      }
      if ( waterdownz ((dis * 0.200)) ) {

         return ( TRUE );

      }

   }
   if ( (wlevel == MOVETYPE_WALK) ) {

      if ( (self.absmin_z < self.goalentity.origin_z) ) {

         dis = (self.goalentity.origin_z - self.absmin_z);
         if ( (dis > KINDA_WANT) ) {

            dis = KINDA_WANT;

         }
         if ( waterupz (dis) ) {

            return ( TRUE );

         }
         if ( waterupz ((dis * 0.500)) ) {

            return ( TRUE );

         }
         if ( waterupz ((dis * 0.200)) ) {

            return ( TRUE );

         }

      }

   }
   return ( FALSE );

};

void (float dist) strafemove = {

   local float ofs;
   local float rnd;
   local float move_yaw;

   if ( (self.movetype == MOVETYPE_BOUNCE) ) {

      return ;

   }

   if ( (self.flags & FL_SWIM) ) {

      if ( waterupdown (dist) ) {

         return ;

      }

   }
   ofs = 90.000;
   rnd = random ();
   if ( self.enemy ) {

      self.strafeonly = MOVETYPE_FLY;
      if ( (self.lefty & STRAFE_DIR) ) {

         ofs = (CONTENT_EMPTY * ofs);

      }

   } else {

      if ( (rnd < 0.500) ) {

         ofs = (CONTENT_EMPTY * ofs);

      }

   }
   move_yaw = (self.ideal_yaw + ofs);
   if ( walkmove (move_yaw, dist) ) {

      // FIX: Set velocity for smooth client interpolation
      makevectors ('0 1 0' * move_yaw);
      self.velocity_x = (v_forward_x * dist * 10.000);
      self.velocity_y = (v_forward_y * dist * 10.000);
      return ;

   }
   if ( self.enemy ) {

      return ;

   }
   ofs = (CONTENT_EMPTY * ofs);
   move_yaw = (self.ideal_yaw + ofs);
   if ( walkmove (move_yaw, dist) ) {

      // FIX: Set velocity for smooth client interpolation
      makevectors ('0 1 0' * move_yaw);
      self.velocity_x = (v_forward_x * dist * 10.000);
      self.velocity_y = (v_forward_y * dist * 10.000);
      return ;

   }
   if ( (self.flags & (FL_INWATER + FL_ONGROUND)) ) {

      self.search_time = (self.search_time - 0.300);

   }

};

void (float dist, float wlevel) BotUnderwaterMove = {

   local float rng;
   local float oldrng;
   local float rnd;

   rnd = random ();
   if ( (rnd < 0.750) ) {

      oldrng = vlen ((self.origin - self.goalentity.origin));
      movetogoal (dist);
      rng = vlen ((self.origin - self.goalentity.origin));
      if ( (oldrng > rng) ) {

         return ;

      }
      if ( (wlevel == FL_SWIM) ) {

         if ( Bot_tryjump (200.000,dist,FALSE) ) {

            return ;

         }

      }

   }
   strafemove (dist);

};
float (float dist) trysidestep = {

   local vector dir;
   local vector start;

   dir = (self.goalentity.origin - self.origin);
   dir_z = FALSE;
   dir = normalize (dir);
   start = self.origin;
   start_z = (self.origin_z + (self.view_ofs_z * 0.500));
   traceline (start,(start + (BOTSPEED * dir)),FALSE,self);
   if ( (trace_fraction != TRUE) ) {

      strafemove ((dist * 0.600));
      return ( TRUE );

   }
   makevectors (self.angles);
   start = (start + (v_right * 15.000));
   traceline (start,(start + (BOTSPEED * dir)),FALSE,self);
   if ( (trace_fraction != TRUE) ) {

      if ( walkmove ((self.ideal_yaw - 90.000),(dist * 0.600)) ) {

         return ( TRUE );

      }

   }
   start = (start - (v_right * SVC_INTERMISSION));
   traceline (start,(start + (BOTSPEED * dir)),FALSE,self);
   if ( (trace_fraction != TRUE) ) {

      if ( walkmove ((self.ideal_yaw + 90.000),(dist * 0.600)) ) {

         return ( TRUE );

      }

   }
   return ( FALSE );

};
float (float dist) testmove = {

   local float rng;
   local float oldrng;

   oldrng = vlen ((self.origin - self.goalentity.origin));
   movetogoal (dist);
   rng = vlen ((self.origin - self.goalentity.origin));
   if ( (rng < oldrng) ) {

      return ( TRUE );

   }
   return ( FALSE );

};

void (float dist) BotmovetoWindTunnel = {

   if ( testmove (dist) ) {

      return ;

   }
   if ( trysidestep (dist) ) {

      return ;

   }
   if ( Bot_tryjump (270.000,dist,FALSE) ) {

      return ;

   }
   strafemove ((dist * 0.500));
   return ;

};

void (float dist) BotmovetoVisiblegoal = {

   if ( walkmove (self.ideal_yaw,FL_CLIENT) ) {

      botwalkmove (self.ideal_yaw,(dist - FL_CLIENT));
      return ;

   }
   if ( walkmove ((self.ideal_yaw + 45.000),FL_CLIENT) ) {

      movetogoal ((dist - FL_CLIENT));
      return ;

   }
   if ( walkmove ((self.ideal_yaw - 45.000),FL_CLIENT) ) {

      movetogoal ((dist - FL_CLIENT));
      return ;

   }
   if ( trysidestep (dist) ) {

      return ;

   }
   if ( Bot_tryjump (270.000,dist,FALSE) ) {

      return ;

   }
   strafemove ((dist * 0.500));
   return ;

};

void (float dist) Botmovetogoal = {

   local entity Botgoal;
   local float wlevel;

   self.oldorigin = self.origin;
   Botgoal = self.goalentity;
   self.ideal_yaw = vectoyaw ((Botgoal.origin - self.origin));
   ChangeYaw ();
   if ( (self.flags & FL_INWATER) ) {

      wlevel = CheckWaterLevel ();
      if ( (wlevel > TRUE) ) {

         BotUnderwaterMove ((dist * 0.800),wlevel);
         return ;

      }

   }
   if ( (Botgoal.goalentity.classname == "trigger_push") ) {

      BotmovetoWindTunnel (dist);
      return ;

   }
   if ( Spotvisible (Botgoal) ) {

      BotmovetoVisiblegoal (dist);
      return ;

   }
   if ( testmove (dist) ) {

      return ;

   }
   strafemove ((dist * 0.800));
   return ;

};
