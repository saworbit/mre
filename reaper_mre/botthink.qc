
void (entity e) clearCache;
float (entity b) TrueReachable;  // Forward declaration for air reachability checks
void (float ctx, entity targ) BotChat;  // Forward declaration for chat system (defined in botchat.qc)

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
         self.items = (self.items - (self.items & IT_INVISIBILITY));
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
         self.items = (self.items - (self.items & IT_INVULNERABILITY));
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
         self.items = (self.items - (self.items & IT_QUAD));
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
         self.items = (self.items - (self.items & IT_SUIT));
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
   local float desired_yaw;
   local float current_pitch;
   local float diff;
   local float time_delta;
   local float turn_dps;
   local float turn_speed;
   local float abs_diff;

   // 1. Early exit if no enemy
   if (!self.enemy)
   {
      self.last_aim_time = time;
      return;
   }

   // ===== HUMAN REACTION TIME: Block Aiming During Delay =====
   // Don't aim at enemy until reaction time has passed
   if ((time < self.reaction_finished))
   {
      self.last_aim_time = time;
      return;
   }
   // ===== END HUMAN REACTION TIME =====

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
   desired_yaw = los_angles_y;

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

   // Slew Rate: How many degrees can we turn this tick?
   // Skill 0 (Easy): 150 deg/s (Lazy tracking)
   // Skill 3 (Nightmare): 450 deg/s (Snappy but not instant)
   time_delta = (time - self.last_aim_time);
   if ((time_delta <= 0.000))
   {
      time_delta = 0.100;
   } //end if
   if ((time_delta > 0.200))
   {
      time_delta = 0.200;
   } //end if
   self.last_aim_time = time;
   turn_dps = (150.000 + (self.skil * 100.000));
   turn_speed = (turn_dps * time_delta);

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

   // 5. Apply Final Aim Request (PID updates actual angles)
   Bot_RequestAim (desired_yaw,current_pitch,TRUE,TRUE,AIM_OWNER_COMBAT,R_COMBAT_SEEN_ENEMY,"combat");

   // NOTE: We do not call ChangeYaw/ChangePitch; PID applies view angles.
}; //end of the function checkyaw
// ===== END ENHANCED AIM =====

void () Bot_FrameBegin =
{
   local float yaw_delta;
   local float pitch_delta;

   self.frame_begin_time = time;
   self.dbg_tick = (self.dbg_tick + 1.000);
   if (bot_dbg_trace_enabled)
   {
      if (((self.dbg_apply_time > 0.000) && (time > self.dbg_apply_time)))
      {
         yaw_delta = Math_AngleDiff ((self.angles_y - self.dbg_apply_yaw));
         pitch_delta = (self.angles_x - self.dbg_apply_pitch);
         if (((fabs (yaw_delta) > 2.000) || (fabs (pitch_delta) > 2.000)))
         {
            Bot_DbgEvent (self,DBG_EVT_ANGLES_OVERRIDE,yaw_delta,pitch_delta,R_NONE,"post-apply");
            if ((bot_debug_enabled && (time >= self.dbg_angles_override_time)))
            {
               bprint ("[");
               bprint (self.netname);
               bprint ("] angles overridden dy=");
               bprint (ftos (yaw_delta));
               bprint (" dp=");
               bprint (ftos (pitch_delta));
               bprint ("\n");
               self.dbg_angles_override_time = (time + 1.000);
            } //end if
         } //end if
      } //end if
   } //end if
   self.goal_req_ent = world;
   self.goal_req_org = '0.000 0.000 0.000';
   self.goal_req_pri = -1.000;
   self.goal_req_commit_secs = 0.000;
   self.goal_req_reason = string_null;
   self.goal_req_reason_code = R_NONE;
   if (self.goal_req_pending_set)
   {
      self.goal_req_ent = self.goal_req_pending_ent;
      self.goal_req_org = self.goal_req_pending_org;
      self.goal_req_pri = self.goal_req_pending_pri;
      self.goal_req_commit_secs = self.goal_req_pending_commit_secs;
      self.goal_req_reason = self.goal_req_pending_reason;
      self.goal_req_reason_code = self.goal_req_pending_reason_code;
      self.goal_req_pending_set = FALSE;
   } //end if

   self.intent_req = 0.000;
   self.intent_req_pri = 0.000;
   self.intent_req_commit_secs = 0.000;
   self.intent_req_reason = string_null;
   self.intent_req_reason_code = R_NONE;
   if (self.intent_req_pending_set)
   {
      self.intent_req = self.intent_req_pending;
      self.intent_req_pri = self.intent_req_pending_pri;
      self.intent_req_commit_secs = self.intent_req_pending_commit_secs;
      self.intent_req_reason = self.intent_req_pending_reason;
      self.intent_req_reason_code = self.intent_req_pending_reason_code;
      self.intent_req_pending_set = FALSE;
   } //end if

   self.aim_req_set_yaw = FALSE;
   self.aim_req_set_pitch = FALSE;
   self.aim_req_owner = AIM_OWNER_NONE;
   self.aim_req_mode = 0.000;
   self.aim_req_reason = string_null;
   self.aim_req_reason_code = R_NONE;

   self.move_req_mode = BOT_MOVE_NONE;
   self.move_req_style = BOT_MOVE_STYLE_NONE;
   self.move_req_pri = 0.000;
   self.move_req_commit_secs = 0.000;
   self.move_req_target = world;
   self.move_req_org = '0.000 0.000 0.000';
   self.move_req_speed = 0.000;
   if (self.move_req_pending_set)
   {
      self.move_req_mode = self.move_req_pending_mode;
      self.move_req_style = self.move_req_pending_style;
      self.move_req_pri = self.move_req_pending_pri;
      self.move_req_commit_secs = self.move_req_pending_commit_secs;
      self.move_req_target = self.move_req_pending_target;
      self.move_req_org = self.move_req_pending_org;
      self.move_req_speed = self.move_req_pending_speed;
      self.move_req_pending_set = FALSE;
   } //end if

   self.dbg_apply_count_this_tick = 0.000;
   self.dbg_apply_tick_time = time;
}; //end of the function Bot_FrameBegin

void () Bot_Arbitrate =
{
   local float same_goal;
   local float style;
   local float min_commit;

   if ((self.goal_req_pri >= 0.000))
   {
      same_goal = FALSE;
      if ((self.goal_req_ent == self.goalentity))
      {
         same_goal = TRUE;
      } //end if
      if ((self.goalentity && (self.goal_req_ent == self.goalentity.goalentity)))
      {
         same_goal = TRUE;
      } //end if

      if ((time < self.goal_commit_until))
      {
         if ((self.goal_req_pri < self.goal_priority))
         {
            same_goal = -1.000;
         } //end if
         else if ((self.goal_req_pri == self.goal_priority))
         {
            if (!same_goal)
            {
               same_goal = -1.000;
            } //end if
         } //end if
      } //end if

      if ((same_goal == -1.000))
      {
         if (bot_debug_enabled)
         {
            if ((time >= self.dbg_overruled_goal_time))
            {
               bprint ("[");
               bprint (self.netname);
               bprint ("] OVERRULED goal pri=");
               bprint (ftos (self.goal_req_pri));
               bprint (" reason=");
               bprint (self.goal_req_reason);
               bprint ("\n");
               self.dbg_overruled_goal_time = (time + 1.000);
            } //end if
         } //end if
      } //end if

      if ((same_goal != -1.000))
      {
         min_commit = Bot_GoalMinCommit (self,self.goal_req_reason_code);
         if ((self.goal_req_commit_secs < min_commit))
         {
            self.goal_req_commit_secs = min_commit;
         } //end if
         self.goal_priority = self.goal_req_pri;
         self.goal_commit_until = (time + self.goal_req_commit_secs);
         self.goal_reason = self.goal_req_reason;
         self.goal_reason_code = self.goal_req_reason_code;

         if (self.goal_req_ent)
         {
            if ((((self.goalentity == world) || (!self.goalentity)) && (self.goal_req_ent.classname == "BotTarget")))
            {
               self.goalentity = self.goal_req_ent;
            } //end if
            else if (!((self.goalentity == world) || (!self.goalentity)))
            {
               self.goalentity.goalentity = self.goal_req_ent;
               setorigin (self.goalentity,self.goal_req_org);
            } //end else
         } //end if
      } //end if
   } //end if

   if (self.intent_req)
   {
      if ((time < self.intent_request_until))
      {
         if ((self.intent_req_pri < self.intent_request_pri))
         {
            self.intent_req = 0.000;
         } //end if
         else if ((self.intent_req_pri == self.intent_request_pri))
         {
            if ((self.intent_req != self.intent_request))
            {
               self.intent_req = 0.000;
            } //end if
         } //end if
      } //end if

      if (!self.intent_req)
      {
         if (bot_debug_enabled)
         {
            if ((time >= self.dbg_overruled_intent_time))
            {
               bprint ("[");
               bprint (self.netname);
               bprint ("] OVERRULED intent pri=");
               bprint (ftos (self.intent_req_pri));
               bprint (" reason=");
               bprint (self.intent_req_reason);
               bprint ("\n");
               self.dbg_overruled_intent_time = (time + 1.000);
            } //end if
         } //end if
      } //end if

      if (self.intent_req)
      {
         min_commit = Bot_IntentMinCommit (self.intent_req);
         if ((self.intent_req_commit_secs < min_commit))
         {
            self.intent_req_commit_secs = min_commit;
         } //end if
         self.intent_request = self.intent_req;
         self.intent_request_pri = self.intent_req_pri;
         self.intent_request_until = (time + self.intent_req_commit_secs);
         self.intent_reason = self.intent_req_reason;
         self.intent_reason_code = self.intent_req_reason_code;
      } //end if
   } //end if

   if (self.move_req_mode)
   {
      if ((time < self.move_commit_until))
      {
         if ((self.move_req_pri < self.move_priority))
         {
            self.move_req_mode = BOT_MOVE_NONE;
         } //end if
         else if ((self.move_req_pri == self.move_priority))
         {
            if ((self.move_req_mode != self.move_mode))
            {
               self.move_req_mode = BOT_MOVE_NONE;
            } //end if
         } //end if
      } //end if

      if (!self.move_req_mode)
      {
         if (bot_debug_enabled)
         {
            if ((time >= self.dbg_overruled_move_time))
            {
               bprint ("[");
               bprint (self.netname);
               bprint ("] OVERRULED move pri=");
               bprint (ftos (self.move_req_pri));
               bprint ("\n");
               self.dbg_overruled_move_time = (time + 1.000);
            } //end if
         } //end if
      } //end if

      if (self.move_req_mode)
      {
         style = self.move_req_style;
         if (!style)
         {
            if ((self.move_req_mode == BOT_MOVE_STAND))
            {
               style = BOT_MOVE_STYLE_HOLD;
            } //end if
            else if (((self.move_req_mode == BOT_MOVE_CHARGE) || (self.move_req_mode == BOT_MOVE_NAILCHARGE)))
            {
               style = BOT_MOVE_STYLE_STRAFE;
            } //end if
            else
            {
               style = BOT_MOVE_STYLE_ADVANCE;
            } //end else
         } //end if

         self.move_mode = self.move_req_mode;
         self.move_style = style;
         self.move_priority = self.move_req_pri;
         self.move_commit_until = (time + self.move_req_commit_secs);
         self.move_target = self.move_req_target;
         self.move_target_org = self.move_req_org;
         self.move_speed = self.move_req_speed;
      } //end if
   } //end if
   else if ((time > self.move_commit_until))
   {
      self.move_mode = BOT_MOVE_STAND;
      self.move_style = BOT_MOVE_STYLE_HOLD;
      self.move_speed = 0.000;
   } //end else
}; //end of the function Bot_Arbitrate

void () Bot_FrameApply =
{
   local float saved_ideal_yaw;
   local float saved_ideal_pitch;
   local float aim_yaw;
   local float aim_pitch;

   self.dbg_apply_count_this_tick = (self.dbg_apply_count_this_tick + 1.000);
   if ((self.dbg_apply_count_this_tick > 1.000))
   {
      if (bot_debug_enabled)
      {
         bprint ("[");
         bprint (self.netname);
         bprint ("] apply count > 1\n");
      } //end if
      Bot_DbgEvent (self,DBG_EVT_APPLY_COUNT,self.dbg_apply_count_this_tick,0.000,R_NONE,"apply count");
   } //end if

   Bot_MoveControllerApply ();

   if (!self.aim_hold_set_yaw)
   {
      self.aim_hold_yaw = self.angles_y;
      self.aim_hold_set_yaw = TRUE;
   } //end if
   if (!self.aim_hold_set_pitch)
   {
      self.aim_hold_pitch = self.angles_x;
      self.aim_hold_set_pitch = TRUE;
   } //end if

   // Capture movement-updated ideal angles before aim overrides.
   saved_ideal_yaw = self.ideal_yaw;
   saved_ideal_pitch = self.ideal_pitch;

   aim_yaw = self.aim_hold_yaw;
   aim_pitch = self.aim_hold_pitch;
   if (self.aim_req_set_yaw)
   {
      aim_yaw = self.aim_req_yaw;
   } //end if
   if (self.aim_req_set_pitch)
   {
      aim_pitch = self.aim_req_pitch;
   } //end if
   if ((self.aim_req_set_yaw || self.aim_req_set_pitch))
   {
      self.aim_owner = self.aim_req_owner;
      self.aim_mode = self.aim_req_mode;
      self.aim_reason = self.aim_req_reason;
      self.aim_reason_code = self.aim_req_reason_code;
   } //end if

   self.aim_final_yaw = aim_yaw;
   self.aim_final_pitch = aim_pitch;

   self.ideal_yaw = aim_yaw;
   self.ideal_pitch = aim_pitch;

   Bot_UpdateAimPID ();

   self.dbg_apply_yaw = self.angles_y;
   self.dbg_apply_pitch = self.angles_x;
   self.dbg_apply_time = time;

   self.ideal_yaw = saved_ideal_yaw;
   self.ideal_pitch = saved_ideal_pitch;
}; //end of the function Bot_FrameApply

void () BotPostThink =
{
   local float fraglimit;
   local float enemy_dist;
   local float think_delay;

   if ((self.frame_begin_time != time))
   {
      Bot_FrameBegin ();
   } //end if

   if (self.enemy)
   {
      Bot_ValidateEnemy ();
   } //end if

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

   // ===== CUNNING AI: Ambush (Sound Investigation) =====
   // If idle (roaming) and hear combat/pickup noise, investigate the sound source
   if (!self.enemy)
   {
      if ((self.noise_expires > time) && (self.noise_target != world))
      {
         local entity sound_maker;
         local float d;

         sound_maker = self.noise_target;
         if ((sound_maker != self) && (sound_maker.health > 0.000))
         {
            d = vlen ((sound_maker.origin - self.origin));
            if ((d < 1000.000))
            {
               if (((self.health > 80.000) && (self.items & ((IT_ROCKET_LAUNCHER + IT_SUPER_NAILGUN) + IT_LIGHTNING))))
               {
                  Bot_RequestIntent (self,6.000,70.000,1.500,R_AMBUSH,"ambush");
                  Bot_RequestAim (vectoyaw ((sound_maker.origin - self.origin)),0.000,TRUE,FALSE,AIM_OWNER_SOUND,R_SOUND_HEARD,"sound");
                  self.search_time = (time + 1.500);
               } //end if
               else
               {
                  if ((self.goalentity.classname == "BotTarget"))
                  {
                     setorigin (self.goalentity,sound_maker.origin);
                  } //end if
                  self.search_time = (time + 2.000);
               } //end else
            } //end if
         } //end if
         self.noise_target = world;
         self.noise_expires = time;
      } //end if
      else if ((self.search_time < time))
      {
         local entity sound_maker;
         local float d;

         sound_maker = find (world,classname,"player");
         while (sound_maker)
         {
            if ((sound_maker != self))
            {
               if ((sound_maker.health > 0.000))
               {
                  // Did they make noise recently? (Shooting = attack_finished still active)
                  // attack_finished is set when firing weapons, indicates recent combat
                  if ((sound_maker.attack_finished > time))
                  {
                     d = vlen ((sound_maker.origin - self.origin));
                     // Can we "hear" them? (Within 1000 units, even through walls)
                     if ((d < 1000.000))
                     {
                        // ===== ENHANCED AMBUSH: Stop and Wait =====
                        // If we are healthy and well-armed, STOP and wait for them to come to us
                        // (Real ambush behavior: hear noise → take position → wait)
                        if (((self.health > 80.000) && (self.items & ((IT_ROCKET_LAUNCHER + IT_SUPER_NAILGUN) + IT_LIGHTNING))))
                        {
                           // Request a short hold to set up the ambush
                           Bot_RequestIntent (self,6.000,70.000,1.500,R_AMBUSH,"ambush");

                           // Face the noise source
                           Bot_RequestAim (vectoyaw ((sound_maker.origin - self.origin)),0.000,TRUE,FALSE,AIM_OWNER_SOUND,R_SOUND_HEARD,"sound");

                           // Wait 1.5 seconds for them to round the corner into our line of fire
                           // (Don't move goalentity, just stop and face the sound)
                           self.search_time = (time + 1.500);
                           break;
                        } //end if
                        // ===== END ENHANCED AMBUSH =====

                        // Otherwise, just investigate by moving toward the sound
                        if ((self.goalentity.classname == "BotTarget"))
                        {
                           setorigin (self.goalentity,sound_maker.origin);
                        } //end if

                        // Investigate for 2 seconds
                        self.search_time = (time + 2.000);

                        // Cunning: Don't run straight at them—approach cautiously
                        // (Human behavior: hear shots → move to investigate)
                        break;
                     } //end if
                  } //end if
               } //end if
            } //end if
            sound_maker = find (sound_maker,classname,"player");
         } //end while
      } //end if
   } //end if
   // ===== END CUNNING AI: Ambush =====

   Bot_UpdateIntentDecision ();
   Bot_DecideGoal ();
   checkyaw ();

   Bot_Arbitrate ();
   Bot_FrameApply ();
   Bot_DbgTraceTick (self);

   if (self.pather)
   {
      if (CheckDropPath ())
      {
         DropBotPath ();
      } //end if
   } //end if
   self.movetarget.flags = self.flags;
   setorigin (self.movetarget,self.origin);

   // ===== TWEAK #4: Ride platform auto-follow (enhanced with elevator boarding) =====
   // Detects when bot is standing on a moving platform (func_plat, func_train) via downward
   // trace and automatically inherits platform velocity to "ride" smoothly. Adjusts goal to
   // follow platform motion, preventing premature dismount. Enables human-like platform use.
   traceline ((self.origin - '0.000 0.000 32.000'),self.origin,TRUE,self);
   if ((trace_ent && ((trace_ent.classname == "func_plat") || (trace_ent.classname == "func_train"))))
   {
      // Standing on moving platform—inherit its velocity for smooth ride
      self.velocity = (self.velocity + trace_ent.velocity);
      self.flags = (self.flags | FL_ONGROUND);
      self.last_lift_origin = trace_ent.origin;
      self.last_lift_time = time;

      // Adjust goal to follow platform motion (prevents dismount until intended)
      if ((self.goalentity == trace_ent))
      {
         self.goalentity.origin = trace_ent.origin;
      } //end if

      // ===== ELEVATOR SYSTEM: Boarding Confirmation =====
      // If bot was waiting for this platform, confirm successful boarding
      if (self.elevator_wait_state)
      {
         // We were waiting for elevator and now we're aboard!
         self.elevator_wait_state = FALSE;

         // Debug log
         if (((bot_debug_enabled && (bot_debug_level >= LOG_TACTICAL))))
         {
            local float wait_duration;
            wait_duration = (time - self.elevator_wait_start);

            bprint ("[");
            bprint (self.netname);
            bprint ("] ELEVATOR: Aboard, riding to top (waited ");
            bprint (ftos (wait_duration));
            bprint ("s)\n");
         } //end if
      } //end if
      // ===== END ELEVATOR SYSTEM =====
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
      local vector steer_dir;
      local float hazard_ahead;
      pred_pos = (self.origin + (self.velocity * think_delay));

      // HAZARD AVOIDANCE: Check if landing in lava/slime
      // Trace downward from predicted position to find landing surface
      traceline (pred_pos, (pred_pos - '0.000 0.000 128.000'), TRUE, self);
      hazard_ahead = FALSE;
      if ((trace_fraction < 1.000))
      {
         // Found ground - check if it's hazardous
         local float content;
         content = pointcontents ((trace_endpos + '0.000 0.000 8.000'));
         if (((content == CONTENT_LAVA) || (content == CONTENT_SLIME)))
         {
            hazard_ahead = TRUE;
         } //end if
      } //end if

      // If heading toward hazard, steer perpendicular to current direction
      if (hazard_ahead)
      {
         // Emergency air-steer AWAY from hazard
         // Rotate velocity 90 degrees to side (perpendicular escape)
         steer_dir = '0.000 0.000 0.000';
         steer_dir_x = (0 - self.velocity_y); // Rotate velocity vector 90°
         steer_dir_y = self.velocity_x;
         steer_dir_z = self.velocity_z; // Keep vertical momentum
         self.velocity = (steer_dir * 0.900); // 90% speed to maintain some momentum
      } //end if
      else
      {
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
   } //end if
   // ===== END TWEAK #3 =====

   // ===== CHAT HOOK: IDLE/REPLY (INCREASED RATES) =====
   // Check if bot should reply to recent chat or make idle comment
   // Only when alive
   if ((self.health > FALSE))
   {
      // Reply check (12% per think - MUCH more responsive bot-to-bot banter)
      if ((random () < 0.120))
      {
         BotChat (MOVETYPE_STEP,world); // MOVETYPE_STEP = C_REPLY = 4
      } //end if

      // Idle comment (1.5% per think - 3x more ambient chat)
      if ((random () < 0.015))
      {
         BotChat (MOVETYPE_FLY,world); // MOVETYPE_FLY = C_IDLE = 5
      } //end if
   } //end if
   // =================================

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
