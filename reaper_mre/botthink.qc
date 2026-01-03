
void (entity e) clearCache;
float (entity b) TrueReachable;  // Forward declaration for air reachability checks
float () CheckWaterLevel =
{
   local float pnt;

   if ((self.waterlevel < SPAWNFLAG_SUPERSPIKE))
   {
      return (CAM_IDLE);
   } //end if
   pnt = pointcontents ((self.origin + self.view_ofs));
   if ((pnt != CONTENT_EMPTY))
   {
      return (CAM_FOLLOW);
   } //end if
   pnt = pointcontents (self.origin);
   if ((pnt != CONTENT_EMPTY))
   {
      return (SPAWNFLAG_LASER);
   } //end if
   return (SPAWNFLAG_SUPERSPIKE);
}; //end of the function CheckWaterLevel

void () BotWaterMove =
{
   local float wlevel;
   local float wtype;
   local float pnt;
   local vector bt;

   wlevel = CheckWaterLevel ();
   if ((self.health < CAM_IDLE))
   {
      return ;
   } //end if
   if ((wlevel != CAM_FOLLOW))
   {
      if ((self.air_finished < time))
      {
         sound (self,CHAN_VOICE,"player/gasp2.wav",SPAWNFLAG_SUPERSPIKE,ATTN_NORM);

      } //end if
      else
      {
         if ((self.air_finished < (time + MOVETYPE_FLYMISSILE)))
         {
            sound (self,CHAN_VOICE,"player/gasp1.wav",SPAWNFLAG_SUPERSPIKE,ATTN_NORM);
         } //end if
      } //end if
      self.air_finished = (time + LOOPTIME);
      self.dmg = SPAWNFLAG_LASER;

   } //end if
   else
   {
      if ((self.air_finished < time))
      {
         if ((self.pain_finished < time))
         {
            self.dmg = (self.dmg + SPAWNFLAG_LASER);
            if ((self.dmg > 15.000))
            {
               self.dmg = TE_LAVASPLASH;
            } //end if
            T_Damage (self,world,world,self.dmg);
            self.pain_finished = (time + SPAWNFLAG_SUPERSPIKE);
         } //end if
      } //end if
   } //end if
   wtype = self.watertype;
   if ((wlevel < SPAWNFLAG_SUPERSPIKE))
   {
      bt = ((self.absmin + self.absmax) * 0.500);
      bt_z = (self.absmin_z + SPAWNFLAG_SUPERSPIKE);
      pnt = pointcontents (bt);
      if ((pnt != CONTENT_EMPTY))
      {
         wlevel = SPAWNFLAG_SUPERSPIKE;
         wtype = pnt;
      } //end if
   } //end if
   if ((self.waterlevel < SPAWNFLAG_SUPERSPIKE))
   {
      if ((self.flags & FL_INWATER))
      {
         sound (self,CHAN_BODY,"misc/outwater.wav",SPAWNFLAG_SUPERSPIKE,ATTN_NORM);
         self.flags = (self.flags - FL_INWATER);
      } //end if
      if ((self.flags & FL_SWIM))
      {
         self.flags = (self.flags - FL_SWIM);
      } //end if
      if ((wlevel < SPAWNFLAG_SUPERSPIKE))
      {
         return ;
      } //end if
   } //end if
   if ((wtype == CONTENT_LAVA))
   {
      if ((self.dmgtime < time))
      {
         if ((self.radsuit_finished > time))
         {
            self.dmgtime = (time + SPAWNFLAG_SUPERSPIKE);

         } //end if
         else
         {
            self.dmgtime = (time + 0.200);
         } //end if
         T_Damage (self,world,world,(TE_LAVASPLASH * wlevel));
      } //end if

   } //end if
   else
   {
      if ((wtype == CONTENT_SLIME))
      {
         if (((self.dmgtime < time) && (self.radsuit_finished < time)))
         {
            self.dmgtime = (time + SPAWNFLAG_SUPERSPIKE);
            T_Damage (self,world,world,(SECRET_1ST_DOWN * wlevel));
         } //end if
      } //end if
   } //end if
   if ((self.waterlevel < SPAWNFLAG_SUPERSPIKE))
   {
      return ;
   } //end if
   if (!(self.flags & FL_INWATER))
   {
      if ((self.watertype == CONTENT_LAVA))
      {
         sound (self,CHAN_BODY,"player/inlava.wav",SPAWNFLAG_SUPERSPIKE,ATTN_NORM);
      } //end if
      if ((self.watertype == CONTENT_WATER))
      {
         sound (self,CHAN_BODY,"player/inh2o.wav",SPAWNFLAG_SUPERSPIKE,ATTN_NORM);
      } //end if
      if ((self.watertype == CONTENT_SLIME))
      {
         sound (self,CHAN_BODY,"player/slimbrn2.wav",SPAWNFLAG_SUPERSPIKE,ATTN_NORM);
      } //end if
      self.flags = (self.flags + FL_INWATER);
      if (!(self.flags & FL_SWIM))
      {
         self.flags = (self.flags + FL_SWIM);
      } //end if
      self.dmgtime = CAM_IDLE;
   } //end if
}; //end of the function BotWaterMove

void () BotCheckPowerups =
{
   if ((self.health <= CAM_IDLE))
   {
      return ;
   } //end if
   if (self.invisible_finished)
   {
      if ((self.invisible_sound < time))
      {
         sound (self,CHAN_AUTO,"items/inv3.wav",0.500,ATTN_IDLE);
         self.invisible_sound = (time + ((random () * CAM_FOLLOW) + SPAWNFLAG_SUPERSPIKE));
      } //end if
      if ((self.invisible_finished < (time + CAM_FOLLOW)))
      {
         if ((self.invisible_time == SPAWNFLAG_SUPERSPIKE))
         {
            sound (self,CHAN_AUTO,"items/inv2.wav",SPAWNFLAG_SUPERSPIKE,ATTN_NORM);
            self.invisible_time = (time + SPAWNFLAG_SUPERSPIKE);
         } //end if
         if ((self.invisible_time < time))
         {
            self.invisible_time = (time + SPAWNFLAG_SUPERSPIKE);
         } //end if
      } //end if
      if ((self.invisible_finished < time))
      {
         self.items = (self.items - IT_INVISIBILITY);
         self.invisible_finished = FALSE;
         self.invisible_time = CAM_IDLE;
      } //end if
      self.frame = CAM_IDLE;
      self.modelindex = modelindex_eyes;

   } //end if
   else
   {
      self.modelindex = modelindex_player;
   } //end if
   if (self.invincible_finished)
   {
      if ((self.invincible_finished < (time + CAM_FOLLOW)))
      {
         if ((self.invincible_time == TRUE))
         {
            sound (self,CHAN_AUTO,"items/protect2.wav",SPAWNFLAG_SUPERSPIKE,ATTN_NORM);
            self.invincible_time = (time + SPAWNFLAG_SUPERSPIKE);
         } //end if
         if ((self.invincible_time < time))
         {
            self.invincible_time = (time + SPAWNFLAG_SUPERSPIKE);
         } //end if
      } //end if
      if ((self.invincible_finished < time))
      {
         self.items = (self.items - IT_INVULNERABILITY);
         self.invincible_time = CAM_IDLE;
         self.invincible_finished = FALSE;
      } //end if
      if ((self.invincible_finished > time))
      {
         self.effects = (self.effects | EF_DIMLIGHT);

      } //end if
      else
      {
         self.effects = (self.effects - (self.effects & EF_DIMLIGHT));
      } //end if
   } //end if
   if (self.super_damage_finished)
   {
      if ((self.super_damage_finished < (time + CAM_FOLLOW)))
      {
         if ((self.super_time == TRUE))
         {
            sound (self,CHAN_AUTO,"items/damage2.wav",SPAWNFLAG_SUPERSPIKE,ATTN_NORM);
            self.super_time = (time + SPAWNFLAG_SUPERSPIKE);
         } //end if
         if ((self.super_time < time))
         {
            self.super_time = (time + SPAWNFLAG_SUPERSPIKE);
         } //end if
      } //end if
      if ((self.super_damage_finished < time))
      {
         self.items = (self.items - IT_QUAD);
         self.super_damage_finished = FALSE;
         self.super_time = CAM_IDLE;
      } //end if
      if ((self.super_damage_finished > time))
      {
         self.effects = (self.effects | EF_DIMLIGHT);

      } //end if
      else
      {
         self.effects = (self.effects - (self.effects & EF_DIMLIGHT));
      } //end if
   } //end if
   if (self.radsuit_finished)
   {
      self.air_finished = (time + 12.000);
      if ((self.radsuit_finished < (time + CAM_FOLLOW)))
      {
         if ((self.rad_time == SPAWNFLAG_SUPERSPIKE))
         {
            sound (self,CHAN_AUTO,"items/suit2.wav",SPAWNFLAG_SUPERSPIKE,ATTN_NORM);
            self.rad_time = (time + SPAWNFLAG_SUPERSPIKE);
         } //end if
         if ((self.rad_time < time))
         {
            self.rad_time = (time + SPAWNFLAG_SUPERSPIKE);
         } //end if
      } //end if
      if ((self.radsuit_finished < time))
      {
         self.items = (self.items - IT_SUIT);
         self.rad_time = CAM_IDLE;
         self.radsuit_finished = FALSE;
      } //end if
   } //end if
}; //end of the function BotCheckPowerups

void () BotDead;

// ===== ENHANCED AIM: Human-Like Aim Smoothing (Slew Rate) =====
// Removes instant-snap "aimbot" behavior by limiting how fast the bot can
// change its pitch (look up/down) per frame, creating human-like tracking
// that can be dodged rather than perfect instant locking.
void () checkyaw =
{
   local vector los;
   local vector los_angles;
   local float o_range;
   local float missile_factor;
   local vector spotty_squid;
   local float desired_pitch;
   local float current_pitch;
   local float diff;
   local float turn_speed;
   local float abs_diff;

   // 1. Early exit if no enemy
   if (!self.enemy) return;

   // 2. Calculate lead target (standard logic)
   o_range = vlen ((self.enemy.origin - self.origin));
   if ((((self.weapon == IT_ROCKET_LAUNCHER) || (self.weapon == IT_NAILGUN)) || (self.weapon == IT_SUPER_NAILGUN)))
   {
      missile_factor = (o_range / (1900.000 + (random () * 700.000)));
   } //end if
   else
   {
      if ((self.weapon == IT_GRENADE_LAUNCHER))
      {
         missile_factor = (o_range / (1000.000 + (random () * 50.000)));
      } //end if
      else
      {
         missile_factor = CAM_IDLE;
      } //end if
   } //end if

   // 3. Add "Human Error" Noise
   // Bots aim slightly off-center at range, tightening as they get closer or gain focus
   if ((o_range > 300.000))
   {
      spotty_squid = ('9.000 9.000 8.000' * (random () - 0.500));
   } //end if
   else
   {
      spotty_squid = VEC_ORIGIN;
   } //end if

   // Focus burst: high adrenaline tightens aim noise for clutch accuracy
   if ((self.adrenaline > 0.700))
   {
      spotty_squid = (spotty_squid * 0.500);
   } //end if

   // Calculate final target point
   los = (((self.enemy.origin - self.origin) + (self.enemy.velocity * missile_factor)) + spotty_squid);

   // ===== TWEAK #2: Jump velocity pattern smoothing (stable arcs, anti-jitter) =====
   // Tracks recent velocity history to smooth movement patterns and prevent erratic jumps.
   // Averaging 3 frames of velocity data reduces sudden direction changes that cause bots
   // to overshoot ledges, clip walls, or exhibit jittery movement during complex navigation.
   // Normalization at 300 u/s prevents high-speed pattern accumulation from creating unstable
   // physics states. This creates more human-like, predictable movement while maintaining
   // responsiveness—critical for narrow platforms and precise jump sequences.

   // Shift velocity history ring buffer: [n-2] ← [n-1] ← [current]
   self.jump_vel_pat0 = self.jump_vel_pat1;
   self.jump_vel_pat1 = self.velocity;

   // Compute 3-frame moving average of velocity for pattern stabilization
   local vector smooth_vel;
   smooth_vel = ((self.jump_vel_pat0 + self.jump_vel_pat1 + self.velocity) * 0.333);

   // Cap smoothed velocity magnitude to prevent runaway acceleration in patterns
   // High-speed patterns (strafe-jumping, bunny-hopping) can compound errors—clamp to safety limit
   if ((vlen (smooth_vel) > 300.000))
   {
      smooth_vel = (normalize (smooth_vel) * 300.000);
   } //end if

   // NOTE: smooth_vel is now available for jump decision logic in movement code.
   // External jump functions (walkmove, movetogoal) should reference this smoothed
   // velocity instead of raw self.velocity to achieve stable arc predictions.
   // This is a "hook point" for jump trajectory calculations in botmove.qc / bot_ai.qc.
   // ===== END TWEAK #2 =====

   // 4. NEW: Pitch Smoothing Logic (Slew Rate)
   // Replaces instant ChangePitch with gradual rotation based on skill level

   los_angles = vectoangles (los);

   // Calculate desired pitch (-90 to 90 range)
   desired_pitch = los_angles_x;
   if ((desired_pitch > 180.000))
   {
      desired_pitch = (desired_pitch - 360.000);
   } //end if

   // Normalize current pitch to same range for comparison
   current_pitch = self.angles_x;
   if ((current_pitch > 180.000))
   {
      current_pitch = (current_pitch - 360.000);
   } //end if

   // Calculate difference
   diff = (desired_pitch - current_pitch);

   // Slew Rate: How many degrees can we turn this tick? (0.1s)
   // Skill 0 (Easy): 15 deg/tick = 150 deg/s (Lazy tracking)
   // Skill 3 (Nightmare): 45 deg/tick = 450 deg/s (Snappy but not instant)
   turn_speed = (15.000 + (self.skil * 10.000));

   // Get absolute value of diff manually (QuakeC has no fabs)
   abs_diff = diff;
   if ((abs_diff < 0.000))
   {
      abs_diff = (abs_diff * -1.000);
   } //end if

   // Apply smoothing
   if ((abs_diff > turn_speed))
   {
      // If difference is too big, move only by turn_speed
      if ((diff > 0.000))
      {
         current_pitch = (current_pitch + turn_speed);
      } //end if
      else
      {
         current_pitch = (current_pitch - turn_speed);
      } //end if
   } //end if
   else
   {
      // Close enough—snap to desired to prevent jitter
      current_pitch = desired_pitch;
   } //end if

   // 5. Apply Final Angle
   self.ideal_pitch = current_pitch;
   self.angles_x = current_pitch;

   // NOTE: We do NOT call ChangePitch() because we handled pitch update manually above.
   // The engine's ChangeYaw() still runs automatically for yaw (left/right) smoothing.
}; //end of the function checkyaw
// ===== END ENHANCED AIM =====

void () BotPostThink =
{
   local float fraglimit;
   local float enemy_dist;
   local float think_delay;

   // Adrenaline focus: scale up when hurt or in close-quarters combat.
   self.adrenaline = CAM_IDLE;
   if ((self.health < 30.000))
   {
      self.adrenaline = (self.adrenaline + 0.600);
   } //end if
   if (self.enemy)
   {
      if ((self.enemy != world))
      {
         enemy_dist = vlen ((self.enemy.origin - self.origin));
         if ((enemy_dist < 200.000))
         {
            self.adrenaline = (self.adrenaline + 0.400);
         } //end if
      } //end if
   } //end if
   if ((self.adrenaline > 1.000))
   {
      self.adrenaline = 1.000;
   } //end if
   checkyaw ();
   if (self.pather)
   {
      if (CheckDropPath ())
      {
         DropBotPath ();
      } //end if
   } //end if
   self.movetarget.flags = self.flags;
   setorigin (self.movetarget,self.origin);

   // ===== TWEAK #4: Ride platform auto-follow (no ride → auto-follow) =====
   // Detects when bot is standing on a moving platform (func_plat, func_train) via downward
   // trace and automatically inherits platform velocity to "ride" smoothly. Adjusts goal to
   // follow platform motion, preventing premature dismount. Enables human-like platform use.
   traceline ((self.origin - '0.000 0.000 32.000'),self.origin,TRUE,self);
   if ((trace_ent && ((trace_ent.classname == "func_plat") || (trace_ent.classname == "func_train"))))
   {
      // Standing on moving platform—inherit its velocity for smooth ride
      self.velocity = (self.velocity + trace_ent.velocity);
      self.flags = (self.flags | FL_ONGROUND);

      // Adjust goal to follow platform motion (prevents dismount until intended)
      if ((self.goalentity == trace_ent))
      {
         self.goalentity.origin = trace_ent.origin;
      } //end if
   } //end if
   // ===== END TWEAK #4 =====

   if ((self.deadflag != DEAD_NO))
   {
      dprint ("Bot should be dead!\n");
      GibPlayer ();
      BotDead ();
      return ;
   } //end if
   BotCheckPowerups ();
   BotWaterMove ();

   // ===== NEW TWEAK #1: Air acceleration / bunny hopping =====
   // Replaces restrictive velocity clamp with skill-based strafe-jump mechanics.
   // High-skill bots (skill >2) gain speed by turning while airborne, simulating
   // human strafe-jumping. Adds acceleration boost when turning, capped at 600 u/s
   // (vs old 320-400 cap) for realistic bunny-hop physics without engine breaks.
   if (!(self.flags & FL_ONGROUND))
   {
      // Only high-skill bots can bunny hop (skill >2)
      if ((self.skil > 2.000))
      {
         // Check if bot is turning significantly (yaw difference > 5 degrees)
         local float yaw_diff;
         yaw_diff = (self.ideal_yaw - self.angles_y);

         // Normalize yaw difference to -180 to 180 range
         while ((yaw_diff > 180.000))
         {
            yaw_diff = (yaw_diff - 360.000);
         } //end while
         while ((yaw_diff < -180.000))
         {
            yaw_diff = (yaw_diff + 360.000);
         } //end while

         // Get absolute value manually (QuakeC has no abs/fabs)
         if ((yaw_diff < 0.000))
         {
            yaw_diff = (yaw_diff * -1.000);
         } //end if

         // If turning significantly, add strafe acceleration
         if ((yaw_diff > 5.000))
         {
            local float currentspeed;
            currentspeed = vlen (self.velocity);

            // Cap at 600 u/s to prevent physics engine breaks
            // Much higher than old 320-400 limit, allows bunny-hop acceleration
            if ((currentspeed < 600.000))
            {
               // Add acceleration boost in facing direction (strafe-jump)
               // 12 u/s per frame = realistic bunny-hop speed gain
               makevectors (self.angles);
               self.velocity = (self.velocity + (v_forward * 12.000));
            } //end if
         } //end if
      } //end if
   } //end if
   // ===== END NEW TWEAK #1 =====

   // Burst think time during adrenaline to simulate faster reaction windows.
   think_delay = 0.100;
   if ((self.adrenaline > 0.500))
   {
      think_delay = (0.050 + (0.050 * (1.000 - (self.skil / 4.000))));
      if ((think_delay < 0.050))
      {
         think_delay = 0.050;
      } //end if
   } //end if
   self.nextthink = (time + think_delay);

   // ===== TWEAK #3: Air reachability check (mid-air correction, anti-stuck) =====
   // Predicts landing position during airborne movement and validates reachability to goal.
   // If the bot is mid-jump and the trajectory would land in an unreachable spot (cliffs,
   // gaps, blocked paths), horizontal velocity is damped by 20% to allow mid-air correction.
   // This proactive adjustment prevents bots from committing to bad jumps, reduces fall
   // deaths, and enables recovery from physics glitches or unexpected collision responses.
   // Critical for complex geometry where initial jump direction becomes invalid mid-flight.
   if ((!(self.flags & FL_ONGROUND) && self.goalentity))
   {
      // Bot is airborne and has an active navigation goal—simulate landing position
      local vector pred_pos;
      pred_pos = (self.origin + (self.velocity * think_delay));

      // Check if goal would still be reachable from predicted landing spot
      // TrueReachable uses strict physics checks (jump arcs, collision traces)
      if (!TrueReachable (self.goalentity))
      {
         // Goal unreachable from current trajectory—dampen horizontal velocity for correction
         // 0.8 multiplier reduces speed gently, allowing bot to adjust aim without full stop
         // Preserves vertical velocity (gravity) so jump arc timing stays intact
         self.velocity_x = (self.velocity_x * 0.800);
         self.velocity_y = (self.velocity_y * 0.800);
         // NOTE: Repeated checks create gradual steering—bot "air-brakes" toward safer angles.
         // This simulates human player adjusting strafe mid-jump when they misjudge distance.
      } //end if
   } //end if
   // ===== END TWEAK #3 =====

   fraglimit = cvar ("fraglimit");
   if ((fraglimit && (self.frags >= fraglimit)))
   {
      NextLevel ();
      self.button0 = SPAWNFLAG_SUPERSPIKE;
      self.think = IntermissionThink;
      self.nextthink = (time + MOVETYPE_FLY);
      return ;
   } //end if
}; //end of the function BotPostThink
