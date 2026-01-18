
// FIX: Removed halfwalkmove - the 0.05s sub-frame timing caused network
// interpolation issues ("jumpy" strafing). Movement now happens in single
// frames with velocity set for smooth client-side prediction.

// Forward declarations for functions used before they're defined
void (float dist) Botmovetogoal;
void () ChangeYaw;
float () FacingIdeal;
void (float shotcount, vector dir, vector spread) FireBullets;
void (vector org, float traffic, float danger, string tgt) SpawnSavedWaypoint;
float (entity next_node, float dist) BotExecuteLink;
float (float vz, float dist, float imagine) Bot_tryjump;
float (vector jmpv) Botwaterjump;

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

// =============================================================================
// CURIOSITY SYSTEM: Bots can "solve" maps by shooting shootable objects
// This helps bots discover secrets and open doors they couldn't otherwise
// =============================================================================

// Check if the bot is looking at something interesting they should shoot
// Called during idle/wandering phases to discover secrets
void () BotCheckCuriosity = {

   local vector scan_start;
   local vector scan_end;
   local entity tr_ent;

   // Cooldown check - don't spam curiosity checks
   if ( (time < self.button_search_time) ) {
      return;
   }
   self.button_search_time = time + 0.5;

   // Don't be curious if we're busy fighting
   if ( self.enemy && enemyvisible(self.enemy) ) {
      return;
   }

   // Trace forward from eye level
   makevectors (self.v_angle);
   scan_start = self.origin + self.view_ofs;
   scan_end = scan_start + (v_forward * 300);

   traceline (scan_start, scan_end, FALSE, self);
   tr_ent = trace_ent;

   if ( !tr_ent ) {
      return;
   }

   // Is it a shootable button?
   if ( (tr_ent.classname == "func_button") && (tr_ent.health > 0) ) {

      // Shoot the button!
      self.button0 = TRUE;

      if ( cvar("developer") ) {
         dprint ("[");
         dprint (self.netname);
         dprint ("] CURIOSITY: Shooting button!\n");
      }
      return;

   }

   // Is it a shootable door (secret)?
   if ( (tr_ent.classname == "func_door") && (tr_ent.health > 0) ) {

      // Might be a secret door - shoot it!
      self.button0 = TRUE;

      if ( cvar("developer") ) {
         dprint ("[");
         dprint (self.netname);
         dprint ("] CURIOSITY: Shooting possible secret!\n");
      }
      return;

   }

   // Is it a shootable wall (some maps use this)?
   if ( (tr_ent.classname == "func_wall") && (tr_ent.health > 0) ) {

      self.button0 = TRUE;

      if ( cvar("developer") ) {
         dprint ("[");
         dprint (self.netname);
         dprint ("] CURIOSITY: Shooting wall target!\n");
      }
      return;

   }

};

// =========================================================================
// SENSOR FUSION STEERING (V2: With Step-Over & Liquid Handling)
// =========================================================================

// HELPER: Check if a "wall" is actually just a small step we can climb
// Returns TRUE if the obstacle is low enough to step over (< 22 units)
float (vector hit_pos, vector dir) BotIsStep = {

   local vector step_high;

   // Look 22 units above the hit point (standard step is 18, we give clearance)
   step_high = hit_pos;
   step_high_z = hit_pos_z + 22;

   // Trace forward at knee height
   traceline (step_high, step_high + (dir * 16), TRUE, self);

   // If this upper trace is clear (1.0), it's a low obstacle (stairs/water lip).
   // The walkmove function will naturally step up the ledge.
   if ( trace_fraction == 1.0 ) {
      return TRUE;
   }

   return FALSE;

};

// HAZARD CHECK: Returns TRUE if the spot is LETHAL (Lava/Slime/Void)
// Explicitly ignores Water so bots can swim/wade through pools.
float (vector spot) BotDetectHazard = {

   local vector down;
   local float content;

   // 1. Check content at the spot itself first
   content = pointcontents (spot);

   // If we're looking at water, that's safe (bot can swim)
   if ( content == CONTENT_WATER ) {
      return FALSE;
   }

   // 2. Look down 256 units to find the floor (deeper than before for water pools)
   down = spot;
   down_z = down_z - 256;

   traceline (spot, down, TRUE, self);

   // 3. VOID CHECK: If we hit nothing in 256 units, it's a huge drop -> HAZARD
   if ( trace_fraction == 1.0 ) {
      return TRUE;
   }

   // 4. CONTENT CHECK at floor - LETHAL only
   content = pointcontents (trace_endpos);

   if ( content == CONTENT_LAVA ) {
      return TRUE;
   }
   if ( content == CONTENT_SLIME ) {
      return TRUE;
   }
   if ( content == CONTENT_SKY ) {
      return TRUE;  // Don't fall out of the map
   }

   return FALSE;

};

// CORE: Vector-Based Steering (Sensor Fusion)
// Calculates forces: Goal Force + Wall Repulsion + Hazard Repulsion
// Now ignores climbable steps so bots don't get stuck at water lips
float (float ideal_yaw, float speed_factor) BotSteer = {

   local vector steer_dir;
   local vector feeler;
   local vector start, end_pos;
   local vector fwd, rt;
   local float dist;

   // Look ahead based on speed
   dist = 50 + (speed_factor * 25);
   start = self.origin + '0 0 16';  // Waist height sensor origin

   // 1. PRIMARY FORCE: The Desire to reach the goal
   makevectors ('0 1 0' * ideal_yaw);
   fwd = v_forward;
   rt = v_right;
   steer_dir = fwd;

   // 2. SENSOR 1: Center Whisker (head-on collision)
   end_pos = start + (fwd * dist);
   traceline (start, end_pos, TRUE, self);

   if ( trace_fraction < 1.0 ) {
      // HIT OBJECT: Is it a wall or a step?
      if ( !BotIsStep (trace_endpos, fwd) ) {
         // Real wall -> Add strong repulsion perpendicular to wall
         steer_dir = steer_dir + (trace_plane_normal * 3.0);
      }
   } else if ( BotDetectHazard (end_pos) ) {
      // CLIFF/LAVA ahead -> Brake & Turn
      steer_dir = steer_dir + (fwd * -4.0);
      steer_dir_x = steer_dir_x + (random () * 2 - 1);  // Slight noise to help turn
   }

   // 3. SENSOR 2: Left Whisker (-45 degrees)
   feeler = (fwd * 0.7) - (rt * 0.7);
   end_pos = start + (feeler * (dist * 0.8));

   traceline (start, end_pos, TRUE, self);
   if ( trace_fraction < 1.0 ) {
      if ( !BotIsStep (trace_endpos, feeler) ) {
         // Real wall -> Push right (along normal)
         steer_dir = steer_dir + (trace_plane_normal * 1.5);
      }
   } else if ( BotDetectHazard (end_pos) ) {
      // Hazard left -> Push right hard
      steer_dir = steer_dir + (rt * 2.0);
   }

   // 4. SENSOR 3: Right Whisker (+45 degrees)
   feeler = (fwd * 0.7) + (rt * 0.7);
   end_pos = start + (feeler * (dist * 0.8));

   traceline (start, end_pos, TRUE, self);
   if ( trace_fraction < 1.0 ) {
      if ( !BotIsStep (trace_endpos, feeler) ) {
         // Real wall -> Push left (along normal)
         steer_dir = steer_dir + (trace_plane_normal * 1.5);
      }
   } else if ( BotDetectHazard (end_pos) ) {
      // Hazard right -> Push left hard
      steer_dir = steer_dir + (rt * -2.0);
   }

   // 5. RESOLVE FORCES
   steer_dir = normalize (steer_dir);

   return vectoyaw (steer_dir);

};

// =========================================================================
// HUMANIZED PHYSICS (Inspired by FrikBot & Frogbot)
// =========================================================================

// TURN SPEED LIMITING: Cap angular velocity at 180 deg/sec
// Inspired by FrikBot's mouse velocity emulation
// Makes bots feel more human - no instant 180° snaps
float BOT_MAX_TURN_SPEED = 18;  // 180 deg/sec at 0.1s frame = 18 deg/frame

float (float target_yaw) BotClampYaw = {

   local float delta;
   local float clamped_yaw;

   // Calculate shortest angle difference
   delta = target_yaw - self.last_yaw;

   // Normalize to -180..180
   while ( delta > 180 ) {
      delta = delta - 360;
   }
   while ( delta < -180 ) {
      delta = delta + 360;
   }

   // Clamp the delta to max turn speed
   if ( delta > BOT_MAX_TURN_SPEED ) {
      delta = BOT_MAX_TURN_SPEED;
   } else if ( delta < (0 - BOT_MAX_TURN_SPEED) ) {
      delta = 0 - BOT_MAX_TURN_SPEED;
   }

   // Calculate clamped yaw
   clamped_yaw = self.last_yaw + delta;

   // Normalize to 0..360
   while ( clamped_yaw < 0 ) {
      clamped_yaw = clamped_yaw + 360;
   }
   while ( clamped_yaw >= 360 ) {
      clamped_yaw = clamped_yaw - 360;
   }

   // Store for next frame
   self.last_yaw = clamped_yaw;

   return clamped_yaw;

};

// =============================================================================
// SMOOTH STEERING (Low-Pass Filter / Anti-Jitter)
// Averages steering decisions over 3 frames to prevent oscillation
// =============================================================================

// Helper: Average angles while handling 0/360 wraparound
// Uses vector addition to properly blend angles near the discontinuity
float (float y1, float y2, float y3) BotAverageAngles = {

   local vector v1, v2, v3, sum;

   // Convert each angle to a unit vector
   makevectors ('0 1 0' * y1);
   v1 = v_forward;
   makevectors ('0 1 0' * y2);
   v2 = v_forward;
   makevectors ('0 1 0' * y3);
   v3 = v_forward;

   // Sum the vectors and convert back to angle
   sum = v1 + v2 + v3;

   // Handle degenerate case (all vectors cancel out)
   if ( vlen (sum) < 0.01 ) {
      return y1;  // Just use most recent
   }

   return vectoyaw (sum);

};

// Smooth steering: Buffer desired angles and average over 3 frames
// This absorbs single-frame "panic" spikes from whiskers
float (float target_yaw) BotSmoothSteer = {

   local float smoothed;
   local float delta;
   local float raw_delta;

   // 1. Update circular buffer with new target
   self.smooth_idx = self.smooth_idx + 1;
   if ( self.smooth_idx > 2 ) {
      self.smooth_idx = 0;
   }

   // Store in appropriate slot (QuakeC doesn't support array syntax)
   if ( self.smooth_idx == 0 ) {
      self.smooth_yaw_0 = target_yaw;
   } else if ( self.smooth_idx == 1 ) {
      self.smooth_yaw_1 = target_yaw;
   } else {
      self.smooth_yaw_2 = target_yaw;
   }

   // 2. Average the last 3 frames (0.3 seconds at 10Hz)
   // This absorbs frame-to-frame oscillations
   smoothed = BotAverageAngles (self.smooth_yaw_0, self.smooth_yaw_1, self.smooth_yaw_2);

   // 3. Apply turn speed clamping (max 20 deg/frame for weightier feel)
   delta = smoothed - self.last_yaw;

   // Normalize to -180..180
   while ( delta > 180 ) {
      delta = delta - 360;
   }
   while ( delta < -180 ) {
      delta = delta + 360;
   }

   // Save raw delta before clamping for logging
   raw_delta = delta;

   // Clamp delta - slightly lower than BotClampYaw for smoother turns
   if ( delta > 15 ) {
      delta = 15;
   } else if ( delta < -15 ) {
      delta = -15;
   }

   // Log when smoothing significantly dampens jitter (clamped > 5 degrees)
   if ( cvar("developer") && (fabs(raw_delta) > 20) && (fabs(raw_delta - delta) > 5) ) {
      dprint ("[");
      dprint (self.netname);
      dprint ("] SMOOTH: Dampened ");
      dprint (ftos(floor(raw_delta)));
      dprint ("° to ");
      dprint (ftos(floor(delta)));
      dprint ("°\n");
   }

   smoothed = self.last_yaw + delta;

   // Normalize to 0..360
   while ( smoothed < 0 ) {
      smoothed = smoothed + 360;
   }
   while ( smoothed >= 360 ) {
      smoothed = smoothed - 360;
   }

   // Store for next frame
   self.last_yaw = smoothed;

   return smoothed;

};

// EDGE FRICTION: Apply extra friction when approaching ledges
// Inspired by FrikBot's dropoff friction doubling
// Prevents bots from sliding off edges
float BOT_EDGE_FRICTION = 0.7;  // Multiplier (1.0 = full speed, 0.5 = half)

void () BotApplyEdgeFriction = {

   local vector ahead;
   local vector down;

   // Only apply when on ground with horizontal velocity
   if ( !(self.flags & FL_ONGROUND) ) {
      return;
   }

   // Look 32 units ahead in movement direction
   if ( vlen (self.velocity) < 50 ) {
      return;  // Not moving fast enough to worry
   }

   ahead = self.origin + (normalize (self.velocity) * 32);
   down = ahead;
   down_z = down_z - 48;  // Look down for ground

   traceline (ahead, down, TRUE, self);

   // If no ground ahead, apply extra friction
   if ( trace_fraction == 1.0 ) {
      // Edge detected - slow down
      self.velocity_x = self.velocity_x * BOT_EDGE_FRICTION;
      self.velocity_y = self.velocity_y * BOT_EDGE_FRICTION;
   }

};

// AIR STEERING: Limited air control during/after knockback
// Inspired by Frogbot's AIR_ACCELERATION flag
// Allows course corrections while airborne instead of being helpless
float BOT_MAX_AIR_ACCEL = 30;  // Cap air acceleration at 30 units/frame (like Frogbot)

void (float desired_yaw) BotAirSteer = {

   local vector wish_dir;
   local float current_speed;
   local float accel;

   // Only allow air steering during knockback recovery
   if ( !BOT_AIR_CONTROL ) {
      return;
   }

   // Must have active knockback
   if ( self.knockback_time < time ) {
      return;
   }

   // Must be airborne
   if ( self.flags & FL_ONGROUND ) {
      return;
   }

   // Calculate desired direction
   makevectors ('0 1 0' * desired_yaw);
   wish_dir = v_forward;

   // Get current horizontal speed
   current_speed = self.velocity_x * wish_dir_x + self.velocity_y * wish_dir_y;

   // Calculate acceleration (capped)
   accel = BOT_MAX_AIR_ACCEL;

   // Don't exceed max air speed (~320 for Quake)
   if ( (current_speed + accel) > 320 ) {
      accel = 320 - current_speed;
   }

   if ( accel <= 0 ) {
      return;
   }

   // Apply limited air acceleration
   self.velocity_x = self.velocity_x + (wish_dir_x * accel);
   self.velocity_y = self.velocity_y + (wish_dir_y * accel);

};

// VELOCITY DECOMPOSITION: Slide along walls when blocked
// Inspired by Frogbot's obstruction handling
// Separates velocity into normal (blocked) and tangent (preserved) components
void () BotDecomposeVelocity = {

   local vector hor_vel;
   local vector hor_dir;
   local vector parallel_vel;

   // Need a known obstruction normal from previous collision
   if ( self.obstruction_normal == '0 0 0' ) {
      return;
   }

   // Get horizontal velocity
   hor_vel = self.velocity;
   hor_vel_z = 0;

   if ( vlen (hor_vel) < 10 ) {
      self.obstruction_normal = '0 0 0';
      return;
   }

   // Project velocity onto wall plane (remove normal component)
   // parallel = velocity - normal * (velocity dot normal)
   hor_dir = normalize (hor_vel);
   parallel_vel = hor_vel - (self.obstruction_normal * (hor_vel * self.obstruction_normal));

   // Apply the sliding velocity
   self.velocity_x = parallel_vel_x;
   self.velocity_y = parallel_vel_y;

   // Clear obstruction after processing
   self.obstruction_normal = '0 0 0';

};

// =========================================================================
// NEW: PHYSICS-BASED SWIMMING
// =========================================================================

float (float desired_speed) BotSwim = {

   local vector aim_dir;
   local vector target_org;
   local vector wall_normal;
   local vector swim_angles;
   local float heading;

   // 1. SURVIVAL: Oxygen check
   if ( self.air_finished < (time + 5.000) ) {
      if ( (pointcontents (self.origin + '0 0 32') == CONTENT_WATER) || (pointcontents (self.origin + '0 0 32') == CONTENT_SLIME) ) {
         self.velocity_z = 220.000;
         if ( (self.velocity_x == 0.000) && (self.velocity_y == 0.000) ) {
            makevectors ('0 1 0' * self.ideal_yaw);
            self.velocity_x = v_forward_x * 50.000;
            self.velocity_y = v_forward_y * 50.000;
         }
         return ( TRUE );
      }
   }

   // 2. TARGET ACQUISITION
   if ( self.goalentity ) {
      target_org = self.goalentity.origin;
      target_org_z = target_org_z + (self.goalentity.view_ofs_z * 0.500);
   } else {
      makevectors (self.angles);
      target_org = self.origin + (v_forward * 100.000);
   }

   // 3. CALCULATE 3D DIRECTION (Pitch + Yaw)
   aim_dir = normalize ((target_org - self.origin));
   swim_angles = vectoangles (aim_dir);
   heading = vectoyaw (aim_dir);
   self.ideal_yaw = BotClampYaw (heading);
   self.angles = swim_angles;
   self.angles_y = self.ideal_yaw;

   // 4. APPLY PHYSICS VELOCITY
   self.velocity = (aim_dir * desired_speed);

   // 5. OBSTACLE AVOIDANCE (Whisker slide)
   traceline (self.origin, self.origin + (aim_dir * 32.000), TRUE, self);
   if ( (trace_fraction < 1.0) ) {
      wall_normal = trace_plane_normal;
      self.velocity = self.velocity - (wall_normal * (self.velocity * wall_normal));
      if ( (wall_normal_z < 0.200) ) {
         self.velocity_z = (self.velocity_z + 80.000);
      }
   }

   return ( TRUE );

};

// Helper: Attempt to jump out of water if near surface
void () BotCheckWaterJump = {

   local vector start;
   local vector end;

   // Only jump if we are close to the surface (waterlevel 2 or 3) and moving up
   if ( self.velocity_z > 50 ) {
      start = self.origin;
      end = start;
      end_z = end_z + 32;

      // Look up. If we see empty air, jump out.
      if ( pointcontents (end) == CONTENT_EMPTY ) {
         self.velocity_z = 300;
         self.flags = self.flags - FL_ONGROUND;
      }
   }

};

// --- FEELER STEERING & BREADCRUMBS ---

// Scan 8 directions to find the clearest path (longest traceline)
float (entity bot) Bot_FindClearestDirection = {

   local vector start;
   local float best_yaw;
   local float best_dist;
   local float i;
   local float scan_yaw;
   local float score;
   local float goal_yaw;
   local float diff;

   start = bot.origin + '0 0 24';  // Waist height
   best_yaw = bot.ideal_yaw;
   best_dist = 0;

   i = 0;
   while ( i < 8 ) {
      scan_yaw = i * 45;

      makevectors ('0 1 0' * scan_yaw);
      traceline (start, start + (v_forward * 200), TRUE, bot);
      score = trace_fraction * 200;

      // Bias toward the goal if we have one
      if ( bot.goalentity && (bot.goalentity != world) ) {
         goal_yaw = vectoyaw (bot.goalentity.origin - bot.origin);
         diff = scan_yaw - goal_yaw;
         while ( diff > 180 ) {
            diff = diff - 360;
         }
         while ( diff < -180 ) {
            diff = diff + 360;
         }
         diff = fabs (diff);
         score = score * (1.0 - (diff / 360));
      }

      if ( score > best_dist ) {
         best_dist = score;
         best_yaw = scan_yaw;
      }

      i = i + 1;
   }

   return best_yaw;

};

void () Bot_DropBreadcrumb = {

   // Only drop if we have moved far enough from the last one
   if ( (self.last_breadcrumb_pos != '0 0 0') && (vlen (self.origin - self.last_breadcrumb_pos) < 48) ) {
      return;
   }

   // Use the saved waypoint helper
   SpawnSavedWaypoint (self.origin, 0.1, 0.0, "");
   self.last_breadcrumb_pos = self.origin;

   if ( cvar("developer") ) {
      dprint ("[");
      dprint (self.netname);
      dprint ("] BREADCRUMB: Dropped at ");
      dprint (vtos (self.origin));
      dprint ("\n");
   }

};

float (entity next_node, float dist) BotExecuteLink = {

   local float type;

   self.whiskers_allowed = TRUE;

   if ( !next_node || (next_node == world) ) {
      return ( FALSE );
   }
   if ( !self.last_waypoint || (self.last_waypoint == world) ) {
      return ( FALSE );
   }

   type = LINK_WALK;
   if ( (self.last_waypoint.movetarget == next_node) ) {
      type = self.last_waypoint.link_type1;
   } else if ( (self.last_waypoint.movetarget2 == next_node) ) {
      type = self.last_waypoint.link_type2;
   } else if ( (self.last_waypoint.movetarget3 == next_node) ) {
      type = self.last_waypoint.link_type3;
   } else if ( (self.last_waypoint.movetarget4 == next_node) ) {
      type = self.last_waypoint.link_type4;
   } else if ( (self.last_waypoint.movetarget5 == next_node) ) {
      type = self.last_waypoint.link_type5;
   } else if ( (self.last_waypoint.movetarget6 == next_node) ) {
      type = self.last_waypoint.link_type6;
   }

   if ( type == LINK_JUMP ) {
      self.whiskers_allowed = FALSE;
      self.ideal_yaw = vectoyaw ((next_node.origin - self.origin));
      ChangeYaw ();
      Bot_tryjump (270.000, dist, FALSE);
      return ( TRUE );
   }
   if ( type == LINK_DROP ) {
      self.whiskers_allowed = FALSE;
      self.ideal_yaw = vectoyaw ((next_node.origin - self.origin));
      ChangeYaw ();
      return ( FALSE );
   }
   if ( type == LINK_ROCKETJUMP ) {
      if ( (self.items & IT_ROCKET_LAUNCHER) ) {
         if ( (self.ammo_rockets > 0.000) && (self.health > 50.000) ) {
            self.weapon = IT_ROCKET_LAUNCHER;
            self.v_angle_x = 80.000;
            self.v_angle_y = vectoyaw ((next_node.origin - self.origin));
            self.ideal_yaw = self.v_angle_y;
            ChangeYaw ();
            self.button0 = TRUE;
            self.button2 = TRUE;
            self.whiskers_allowed = FALSE;
            return ( TRUE );
         }
      }
      return ( FALSE );
   }
   if ( type == LINK_PLAT ) {
      // Simplified platform wait: pause if the link is clearly above us
      if ( next_node.origin_z > (self.origin_z + 16.000) ) {
         self.velocity = '0 0 0';
         return ( TRUE );
      }
      self.whiskers_allowed = TRUE;
      return ( FALSE );
   }

   return ( FALSE );

};

// --- ADVANCED MOVEMENT MECHANICS ---
void (entity bot, float desired_yaw) BotBunnyHop = {

   local float strafe_angle;

   if ( !bot ) {
      return ;
   }
   if ( vlen (bot.velocity) < 200.000 ) {
      return ;
   }

   // Air control: simulate strafe-jump acceleration
   if ( !(bot.flags & FL_ONGROUND) ) {
      makevectors ('0 1 0' * desired_yaw);
      bot.velocity = (bot.velocity + (v_forward * 12.000));
      if ( (vlen (bot.velocity) > 550.000) ) {
         bot.velocity = (normalize (bot.velocity) * 550.000);
      }
      return ;
   }

   // Rhythm: alternate strafe direction and jump
   if ( time > bot.strafe_timer ) {
      if ( (bot.strafe_state == 1.000) ) {
         bot.strafe_state = 2.000;
      } else {
         bot.strafe_state = 1.000;
      }
      bot.strafe_timer = (time + 0.400);
      bot.button2 = TRUE;

      strafe_angle = 15.000;
      if ( (bot.strafe_state == 1.000) ) {
         bot.v_angle_y = (desired_yaw + strafe_angle);
      } else {
         bot.v_angle_y = (desired_yaw - strafe_angle);
      }

      makevectors ('0 1 0' * desired_yaw);
      bot.velocity = (bot.velocity + (v_forward * 40.000));
      if ( (vlen (bot.velocity) > 550.000) ) {
         bot.velocity = (normalize (bot.velocity) * 550.000);
      }
   }

};

// =========================================================================
// MAIN MOVEMENT FUNCTION
// =========================================================================

float (float s_yaw, float s_dist) botwalkmove = {

   local float flow_yaw;
   local float moved;
   local vector jump_check;
   local float is_straight_path;

   self.oldorigin = self.origin;

   // Bounce mode (knockback) - don't interfere
   if ( self.movetype == MOVETYPE_BOUNCE ) {
      return FALSE;
   }

   // HIGH-VALUE ITEM FOCUS: Direct drive to powerups when close
   // Prevents bot from strafing past valuable items
   if ( self.goalentity && self.goalentity.goalentity ) {
      local entity target_item;
      local float dist_to_item;
      local string itname;

      target_item = self.goalentity.goalentity;
      itname = target_item.classname;

      // Check if it's a high-value item
      if ( (itname == "weapon_rocketlauncher") ||
           (itname == "weapon_lightning") ||
           (itname == "item_artifact_super_damage") ||
           (itname == "item_artifact_invulnerability") ||
           (itname == "item_health") ||
           (itname == "item_armorInv") ) {

         dist_to_item = vlen (target_item.origin - self.origin);

         // When close to powerup, stop complex steering and direct drive
         if ( dist_to_item < 200 ) {
            local vector dir_to_item;
            local float direct_yaw;

            dir_to_item = normalize (target_item.origin - self.origin);
            direct_yaw = vectoyaw (dir_to_item);

            // Log once when focus mode activates (use button_search_time as cooldown)
            if ( cvar("developer") && (time > self.button_search_time) ) {
               dprint ("[");
               dprint (self.netname);
               dprint ("] FOCUS: Direct drive to ");
               dprint (itname);
               dprint (" (");
               dprint (ftos(floor(dist_to_item)));
               dprint (" units)\n");
               self.button_search_time = time + 1.0;  // Don't spam
            }

            // Direct walk toward the item
            if ( walkmove (direct_yaw, s_dist) ) {
               // Set velocity for smooth interpolation
               makevectors ('0 1 0' * direct_yaw);
               self.velocity_x = v_forward_x * s_dist * 10.0;
               self.velocity_y = v_forward_y * s_dist * 10.0;
               if ( self.flags & FL_ONGROUND ) {
                  self.velocity_z = -20;
               }
               return TRUE;
            }
         }
      }
   }

   // Knockback / Rocket Jump Support
   // If airborne with significant velocity, let physics take over
   // BUT allow limited air steering during knockback recovery (Frogbot-style)
   if ( !(self.flags & FL_ONGROUND) ) {
      if ( vlen (self.velocity) > 350 ) {
         // Allow air steering during knockback - bot can course correct
         BotAirSteer (s_yaw);
         return FALSE;
      }
   }

   // Platform riding - handles func_train (DM2) and func_plat
   if ( BotCheckPlatformRide () ) {
      return TRUE;
   }

   // --- WATER LOGIC: Physics-based swim control ---
   // Level 0 = Dry, 1 = Feet, 2 = Waist, 3 = Eyes (Submerged)
   if ( self.waterlevel >= 2 ) {
      if ( (self.waterlevel == 2) && (self.velocity_z > 0.000) ) {
         if ( Botwaterjump (self.velocity) ) {
            return TRUE;
         }
      }
      BotSwim (s_dist * 10.000);
      return TRUE;
   }

   // Bunny hop on long, straight runs
   is_straight_path = FALSE;
   if ( self.goalentity && (self.goalentity != world) ) {
      if ( Spotvisible (self.goalentity) && (vlen (self.goalentity.origin - self.origin) > 300.000) ) {
         is_straight_path = TRUE;
      }
   }
   if ( is_straight_path && (self.health > 50.000) && !self.feeler_mode_active && self.whiskers_allowed ) {
      if ( !self.enemy || (self.enemy == world) || (vlen (self.enemy.origin - self.origin) > 200.000) ) {
         BotBunnyHop (self, s_yaw);
      }
   }

   // --- EXECUTE STEERING ---
   if ( !self.whiskers_allowed ) {
      flow_yaw = s_yaw;
   } else if ( self.feeler_mode_active ) {
      // FEELER MODE: Override normal steering
      if ( time > (self.feeler_start_time + 10) ) {
         self.feeler_mode_active = FALSE;
         flow_yaw = BotSteer (s_yaw, 1.0);
      } else {
         flow_yaw = Bot_FindClearestDirection (self);

         // If we found a clear exit and can see the goal, drop back to normal
         makevectors ('0 1 0' * flow_yaw);
         traceline (self.origin, self.origin + (v_forward * 128), TRUE, self);
         if ( (trace_fraction == 1.0) && self.goalentity && (self.goalentity != world) ) {
            if ( Spotvisible (self.goalentity) ) {
               self.feeler_mode_active = FALSE;
            }
         }
      }
   } else {
      // STANDARD MODE: Sensor fusion
      flow_yaw = BotSteer (s_yaw, 1.0);
   }

   // SMOOTH STEERING (Anti-Jitter)
   // Average over 3 frames to prevent pathfinder/whisker oscillation
   flow_yaw = BotSmoothSteer (flow_yaw);

   // Try to move using the calculated Flow Angle
   moved = walkmove (flow_yaw, s_dist);

   if ( moved ) {
      // MOVEMENT SUCCESS
      // Clear any stored obstruction from previous frame
      self.obstruction_normal = '0 0 0';

      // Drop breadcrumbs while exploring
      if ( self.feeler_mode_active ) {
         Bot_DropBreadcrumb ();
      }

      // 1. Velocity Matching (Fixes teleport/jitter)
      makevectors ('0 1 0' * flow_yaw);
      self.velocity_x = v_forward_x * s_dist * 10.0;
      self.velocity_y = v_forward_y * s_dist * 10.0;

      // 2. Ground Glue (Fixes z-axis jitter on stairs/ramps)
      if ( self.flags & FL_ONGROUND ) {
         self.velocity_z = -20;
      }

      // 3. Edge Friction (FrikBot-inspired)
      // Apply extra friction when approaching ledges to prevent sliding off
      BotApplyEdgeFriction ();

      // 4. Visual Turn Smoothing
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

   // VELOCITY DECOMPOSITION (Frogbot-inspired)
   // Store wall normal for sliding - if we hit a wall, we can slide along it
   if ( trace_fraction < 1.0 ) {
      self.obstruction_normal = trace_plane_normal;
      self.obstruction_normal_z = 0;  // Only horizontal component
      if ( vlen (self.obstruction_normal) > 0.1 ) {
         self.obstruction_normal = normalize (self.obstruction_normal);

         // Try to slide along the wall instead of stopping dead
         BotDecomposeVelocity ();

         // Attempt sliding movement
         if ( vlen (self.velocity) > 20 ) {
            local float slide_yaw;
            slide_yaw = vectoyaw (self.velocity);
            if ( walkmove (slide_yaw, s_dist * 0.5) ) {
               return TRUE;  // Successfully slid along wall
            }
         }
      }
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

   if ( wlevel >= 2 ) {
      BotSwim (dist * 10.000);
      return;
   }

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
   self.whiskers_allowed = TRUE;
   if ( Botgoal.goalentity && (Botgoal.goalentity.classname == "BotPath") ) {
      if ( BotExecuteLink (Botgoal.goalentity, dist) ) {
         return ;
      }
   }
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
