// Forward declaration for enhanced rocket jump (used in Bot_tryjump before definition)
float() bot_rocket_jump;
// Forward declaration for problem solver (defined in bot_ai.qc)
entity(entity door_ent) FindButtonForDoor;
void(entity door_ent) Bot_SolveBlockedDoor;
// Forward declaration for breadcrumb waypoints (defined in botroute.qc)
void(vector org, float traffic, float danger, string trig_target) SpawnSavedWaypoint;
// Forward declaration for live learning RJ waypoints (defined in botroute.qc)
void(vector org, vector angles, float velocity_gain, string rj_type_str) SpawnLearnedRJ_Live;
// Forward declaration for ledge risk (defined later in this file)
float(entity bot, vector pos, vector dir) Bot_LedgeRisk;
// Forward declaration for loop detection (defined later in this file)
float(entity bot) Loop_InLoop;
// Forward declaration for unstick entry (defined later in this file)
void (float reason_code, string reason) Bot_EnterUnstick;
// Forward declaration for hazard escape (defined later in this file)
void (float dist) Bot_HazardEscapeThink;
// Forward declaration for terrain escape picker (defined later in this file)
vector (entity bot) Bot_PickTerrainEscape;
// Forward declaration for directional fail memory (defined later in this file)
void (entity bot, vector dir) RecordDirectionalFail;
// Forward declaration for ground height sampling (defined later in this file)
float (entity bot, vector p) SampleGroundHeight;

// Progress-based stuck detection + unstick mode tuning
float BOT_MODE_NORMAL = 0.000;
float BOT_MODE_UNSTICK = 1.000;
float BOT_MODE_COOLDOWN = 2.000;
float BOT_MODE_COMBAT = 3.000;
float BOT_LOS_NONE = 0.000;
float BOT_LOS_FEET = 1.000;
float BOT_LOS_TORSO = 2.000;
float BOT_LOS_HEAD = 3.000;

// Intent escalation: High-level behavioral intents
float BOT_INTENT_FIGHT = 1.000;      // Engaging visible enemy (LOS required)
float BOT_INTENT_CHASE = 2.000;      // Pursuing enemy without LOS (last known pos)
float BOT_INTENT_RESUPPLY = 3.000;   // Seeking health/armor/ammo items
float BOT_INTENT_EXPLORE = 4.000;    // Roaming for pickups or enemy contact
float BOT_INTENT_UNSTICK = 5.000;    // Escape stuck state or reposition
float BOT_INTENT_HOLD = 6.000;       // Hold position (ambush/wait)
float BOT_INTENT_UPDATE_HZ = 4.000;  // Intent evaluation frequency (4Hz)

float STUCK_PROGRESS_INTERVAL = 0.200;
float STUCK_PROGRESS_DIST = 12.000;  // Horizontal progress threshold
float STUCK_PROGRESS_VERT = 8.000;   // Vertical progress threshold (stairs)
float STUCK_TIME_LIMIT = 1.000;
float STUCK_SCORE_THRESH = 5.000;
float STUCK_PUSH_SPEED = 20.000;
float STUCK_PUSH_DIST = 40.000;

float (float yaw, float dist) Bot_WalkMove =
{
   local float prev_yaw;
   local float prev_pitch;
   local float prev_roll;
   local float moved;

   if (!self.move_apply_active)
   {
      if ((bot_debug_enabled && !self.dbg_walkmove_warned))
      {
         bprint ("[");
         bprint (self.netname);
         bprint ("] walkmove outside controller\n");
         self.dbg_walkmove_warned = TRUE;
      } //end if
   } //end if
   prev_yaw = self.angles_y;
   prev_pitch = self.angles_x;
   prev_roll = self.angles_z;
   moved = walkmove (yaw,dist);
   if ((bot_debug_enabled && !self.dbg_walkmove_angle_warned))
   {
      if (((self.angles_y != prev_yaw) || (self.angles_x != prev_pitch) || (self.angles_z != prev_roll)))
      {
         bprint ("[");
         bprint (self.netname);
         bprint ("] walkmove changed angles\n");
         self.dbg_walkmove_angle_warned = TRUE;
      } //end if
   } //end if
   return (moved);
}; //end of the function Bot_WalkMove

// PHASE 4 REFACTOR: CanRocketJumpHeight, CanCrossGap moved to botmath.qc

void () halfwalkmove =
{
   self.move_apply_active = TRUE;
   Bot_WalkMove (self.strafeyaw,self.strafedist);
   self.move_apply_active = FALSE;
   self.think = self.strafethink;
   self.nextthink = (time + 0.050);
}; //end of the function halfwalkmove
float (float s_yaw, float s_dist) botwalkmove =
{
   local float halfdist;

   self.oldorigin = self.origin;
   if ((self.skil > SPAWNFLAG_LASER))
   {
      halfdist = (0.650 * s_dist);

   } //end if
   else
   {
      halfdist = (0.550 * s_dist);
   } //end if
   if (self.move_apply_active)
   {
      if (!Bot_WalkMove (s_yaw,halfdist))
      {
         return (FALSE);
      } //end if
      // Apply the second half immediately so movement stays inside the controller tick.
      Bot_WalkMove (s_yaw,halfdist);
      return (TRUE);
   } //end if
   if (!Bot_WalkMove (s_yaw,halfdist))
   {
      return (FALSE);
   } //end if
   self.strafethink = self.think;
   self.strafeyaw = s_yaw;
   self.strafedist = halfdist;
   self.think = halfwalkmove;
   self.nextthink = (time + 0.050);
   return (TRUE);
}; //end of the function botwalkmove
float (float dist) teleptest =
{
   local vector start;
   local vector up;

   up = self.origin;
   start = self.origin;
   if ((dist < FALSE))
   {
      up_z = ((self.absmin_z + dist) - SPAWNFLAG_SUPERSPIKE);

   } //end if
   else
   {
      up_z = ((self.absmax_z + dist) + SPAWNFLAG_SUPERSPIKE);
   } //end if
   traceline (start,up,FALSE,self);
   if ((trace_fraction < SPAWNFLAG_SUPERSPIKE))
   {
      return (FALSE);
   } //end if
   start_x = (start_x + SECRET_YES_SHOOT);
   start_y = (start_y + SECRET_YES_SHOOT);
   up_x = (up_x + SECRET_YES_SHOOT);
   up_y = (up_y + SECRET_YES_SHOOT);
   traceline (start,up,FALSE,self);
   if ((trace_fraction < SPAWNFLAG_SUPERSPIKE))
   {
      return (FALSE);
   } //end if
   start_x = (start_x - DOOR_TOGGLE);
   up_x = (up_x - DOOR_TOGGLE);
   traceline (start,up,FALSE,self);
   if ((trace_fraction < SPAWNFLAG_SUPERSPIKE))
   {
      return (FALSE);
   } //end if
   start_y = (start_y - DOOR_TOGGLE);
   up_y = (up_y - DOOR_TOGGLE);
   traceline (start,up,FALSE,self);
   if ((trace_fraction < SPAWNFLAG_SUPERSPIKE))
   {
      return (FALSE);
   } //end if
   start_x = (start_x + DOOR_TOGGLE);
   up_x = (up_x + DOOR_TOGGLE);
   traceline (start,up,FALSE,self);
   if ((trace_fraction < SPAWNFLAG_SUPERSPIKE))
   {
      return (FALSE);
   } //end if
   start = self.origin;
   start_z = up_z;
   up = start;
   start_x = (start_x + SECRET_YES_SHOOT);
   up_x = (up_x - SECRET_YES_SHOOT);
   traceline (start,up,FALSE,self);
   if ((trace_fraction < SPAWNFLAG_SUPERSPIKE))
   {
      return (FALSE);
   } //end if
   start = self.origin;
   start_z = up_z;
   up = start;
   start_y = (start_y + SECRET_YES_SHOOT);
   up_y = (up_y - SECRET_YES_SHOOT);
   traceline (start,up,FALSE,self);
   if ((trace_fraction < SPAWNFLAG_SUPERSPIKE))
   {
      return (FALSE);
   } //end if
   return (TRUE);
}; //end of the function teleptest
float (float dist) waterupz =
{
   local vector start;
   local vector up;

   if (!teleptest (dist))
   {
      return (FALSE);
   } //end if
   up = self.origin;
   up_z = (up_z + dist);
   setorigin (self,up);
   return (TRUE);
}; //end of the function waterupz
float (float dist) waterdownz =
{
   local vector up;
   local vector start;

   if (!teleptest ((CONTENT_EMPTY * dist)))
   {
      return (FALSE);
   } //end if
   up = self.origin;
   up_z = (up_z - dist);
   setorigin (self,up);
   return (TRUE);
}; //end of the function waterdownz
float (vector jmpv) Botjump =
{
   local float vol;

   if ((self.flags & FL_ONGROUND))
   {
      self.flags = (self.flags - FL_ONGROUND);
   } //end if
   self.velocity = jmpv;
   if ((jmpv_z > 200.000))
   {
      vol = (SPAWNFLAG_SUPERSPIKE * (0.700 + (random () * 0.300)));
      sound (self,CHAN_BODY,"player/plyrjmp8.wav",vol,ATTN_NORM);
   } //end if
   return (TRUE);
}; //end of the function Botjump
float (vector jmpv) Botwaterjump =
{
   if ((self.flags & FL_ONGROUND))
   {
      self.flags = (self.flags - FL_ONGROUND);
   } //end if
   if (!waterupz (45.000))
   {
      return (FALSE);
   } //end if
   jmpv_z = 200.000;
   self.velocity = jmpv;
   if ((self.flags & FL_SWIM))
   {
      self.flags = (self.flags - FL_SWIM);
   } //end if
   if ((self.flags & FL_INWATER))
   {
      self.flags = (self.flags - FL_INWATER);
   } //end if
   self.teleport_time = (time + 0.700);
   return (TRUE);
}; //end of the function Botwaterjump

// ===== TWEAK #1 HELPER: Train path prediction (path_corner chain traversal) =====
// Predicts where a train will be at future time by traversing its path_corner chain.
// Two-pass algorithm: (1) calculate total path distance for cycling, (2) interpolate
// position along chain based on time. Handles looping paths via modulo arithmetic,
// detects cycles with first_corner tracking, and limits to 10 segments for safety.
vector (entity train, float t_future) predict_train_pos =
{
   local entity curr;
   local entity first_corner;
   local float dist_accum;
   local float total_dist;
   local float train_speed;
   local vector last_pos;
   local vector next_pos;
   local float seg_dist;
   local float seg_count;
   local float t_mod;
   local float dist_limit;
   local float dist_future;
   local float looped;
   local float truncated;

   if (!train) return train.origin;

   train_speed = vlen(train.velocity);
   if (train_speed < 1)
   {
      if (train.speed)
      {
         train_speed = train.speed;
      }
      else
      {
         train_speed = 100; // Default fallback
      }
   }

   curr = find(world, targetname, train.target); // First path_corner in chain
   first_corner = curr; // Save for loop detection/cycling
   if (!curr) return train.origin;

   last_pos = train.origin;
   dist_accum = 0;
   total_dist = 0;
   seg_count = 0;
   dist_limit = (train_speed * t_future);
   looped = FALSE;
   truncated = FALSE;

   // First pass: accumulate total chain distance (for cycling)
   while (curr && seg_count < 10) {
      next_pos = curr.origin;
      seg_dist = vlen(next_pos - last_pos);
      total_dist = (total_dist + seg_dist);

      last_pos = next_pos;
      if ((total_dist > dist_limit))
      {
         break;
      } //end if
      curr = find(world, targetname, curr.target);
      if (curr == first_corner)
      {
         looped = TRUE;
         break;
      } //end if
      seg_count = (seg_count + 1);
   }

   if ((seg_count >= 10))
   {
      truncated = TRUE;
   } //end if

   if (total_dist == 0) return train.origin; // No path length? Static

   dist_future = (train_speed * t_future);
   if ((looped && !truncated))
   {
      // Modulo time for cycling paths
      t_mod = t_future - (floor(t_future / (total_dist / train_speed)) * (total_dist / train_speed));
      dist_future = (train_speed * t_mod);
   } //end if
   else
   {
      if ((dist_future > total_dist))
      {
         dist_future = total_dist;
      } //end if
   } //end if

   // Second pass: traverse to find interpolated position
   curr = first_corner; // Reset to start
   last_pos = train.origin;
   dist_accum = 0;
   seg_count = 0;

   while (curr && seg_count < 10) {
      next_pos = curr.origin;
      seg_dist = vlen(next_pos - last_pos);

      if ((dist_accum + seg_dist) >= dist_future) {
         // Interpolate within this segment
         local float remainder = dist_future - dist_accum;
         local vector dir = normalize(next_pos - last_pos);
         return last_pos + (dir * remainder);
      }

      dist_accum = (dist_accum + seg_dist);
      last_pos = next_pos;
      curr = find(world, targetname, curr.target);
      seg_count = (seg_count + 1);
   }

   return last_pos; // Fallback: end of chain or error
}; //end of the function predict_train_pos
// ===== END TWEAK #1 HELPER =====

float (entity targ) Swimto;
float (vector spot) CheckLavaOrLow =
{
   local float lnd;
   local float boost;
   local vector spot2;

   lnd = pointcontents (spot);
   if (((lnd == CONTENT_LAVA) || (lnd == CONTENT_SLIME)))
   {
      return (TRUE);
   } //end if
   spot2 = spot;
   spot2_z = (spot_z + SPAWNFLAG_LASER);
   lnd = pointcontents (spot2);
   if (((lnd == CONTENT_LAVA) || (lnd == CONTENT_SLIME)))
   {
      return (TRUE);
   } //end if
   if ((lnd != CONTENT_WATER))
   {
      boost = (MAXJUMP + SPAWNFLAG_SUPERSPIKE);
      if ((self.goalentity.goalentity.classname == "func_button"))
      {
         boost = ((boost + self.maxs_z) - SPAWNFLAG_SUPERSPIKE);
      } //end if
      if (((spot_z + boost) < self.goalentity.origin_z))
      {
         return (TRUE);
      } //end if

   } //end if
   else
   {
      traceline (spot2,self.goalentity.absmin,SPAWNFLAG_SUPERSPIKE,self);
      if (trace_inopen)
      {
         if (((spot_z + 45.000) > self.goalentity.origin_z))
         {
            return (FALSE);
         } //end if
         return (TRUE);
      } //end if
      if ((trace_fraction == SPAWNFLAG_SUPERSPIKE))
      {
         return (FALSE);
      } //end if
      return (TRUE);
   } //end if
   return (FALSE);
}; //end of the function CheckLavaOrLow
float (vector middle) checkLanding =
{
   local float goodcnt;
   local vector spot;
   local vector center;

   center = middle;
   spot = middle;
   spot_x = (spot_x + CAM_NOCLIP);
   if ((pointcontents (spot) == CONTENT_SOLID))
   {
      center_x = (center_x - CAM_NOCLIP);
   } //end if
   spot_x = (spot_x - 12.000);
   if ((pointcontents (spot) == CONTENT_SOLID))
   {
      center_x = (center_x + CAM_NOCLIP);
   } //end if
   spot = middle;
   spot_y = (spot_y + CAM_NOCLIP);
   if ((pointcontents (spot) == CONTENT_SOLID))
   {
      center_y = (center_y - CAM_NOCLIP);
   } //end if
   spot_y = (spot_y - 12.000);
   if ((pointcontents (spot) == CONTENT_SOLID))
   {
      center_y = (center_y + CAM_NOCLIP);
   } //end if
   spot = center;
   spot_z = dropline (spot);
   goodcnt = MOVETYPE_FLY;
   if (CheckLavaOrLow (spot))
   {
      return (FALSE);
   } //end if
   spot = center;
   spot_x = (spot_x + CAM_NOCLIP);
   spot_z = dropline (spot);
   if (CheckLavaOrLow (spot))
   {
      goodcnt = (goodcnt - SPAWNFLAG_SUPERSPIKE);
   } //end if
   spot = center;
   spot_x = (spot_x - CAM_NOCLIP);
   spot_z = dropline (spot);
   if (CheckLavaOrLow (spot))
   {
      goodcnt = (goodcnt - SPAWNFLAG_SUPERSPIKE);
   } //end if
   spot = center;
   spot_y = (spot_y + CAM_NOCLIP);
   spot_z = dropline (spot);
   if (CheckLavaOrLow (spot))
   {
      goodcnt = (goodcnt - SPAWNFLAG_SUPERSPIKE);
   } //end if
   spot = center;
   spot_y = (spot_y - CAM_NOCLIP);
   spot_z = dropline (spot);
   if (CheckLavaOrLow (spot))
   {
      goodcnt = (goodcnt - SPAWNFLAG_SUPERSPIKE);
   } //end if
   if ((goodcnt > CAM_FOLLOW))
   {
      return (TRUE);
   } //end if
   return (FALSE);
}; //end of the function checkLanding
float (float dist) JumpUpToPush =
{
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
   if ((len < 25.000))
   {
      jumpv = (xydir * LOOPTIME);
      jumpv_z = 270.000;
      Botjump (jumpv);
      return (TRUE);
   } //end if
   if ((len < 80.000))
   {
      jumpv = (xydir * (len / LEVELJUMPTIME));
      jumpv_z = 270.000;
      Botjump (jumpv);
      return (TRUE);
   } //end if
   return (FALSE);
}; //end of the function JumpUpToPush
float /* ERROR: Could not determine return type */ (float vz, float dist, float imagine) Bot_tryjump =
{
   local float timetofloor;
   local float tvel;
   local float sim_interval;
   local float dis;
   local float diffz;
   local float diffxy;
   local float NOTLAND;
   local float lnd;
   local float wlevel;
   local float velz;
   local float ht;
   local vector botxy;
   local vector goalxy;
   local vector xydir;
   local vector top;
   local vector bottom;
   local vector jumpv;
   local vector newbottom;
   local vector start;
   local vector move_angles;
   local entity botTarget;

   // ===== PHASE 3 FIX: ROCKET JUMP FAILURE RECOVERY =====
   // Check if RJ verification is pending
   if ((self.rj_verify_time && (time > self.rj_verify_time)))
   {
      self.rj_verify_time = CAM_IDLE;
      // If we didn't get vertical lift (failed jump), reset cooldown
      if ((self.velocity_z < 50.000))
      {
         self.rj_cooldown = time; // Reset cooldown immediately for retry
      } //end if
   } //end if
   // ===== END PHASE 3 FIX =====

   if (!(self.flags & (FL_ONGROUND + FL_SWIM)))
   {
      return (FALSE);
   } //end if
   wlevel = CheckWaterLevel ();
   if ((wlevel > SPAWNFLAG_LASER))
   {
      return (FALSE);
   } //end if
   // Lightning-gun evade burst: add jump bias when focused by hitscan.
   if ((self.evade_mode == 2.000))
   {
      if ((self.skil > 2.000))
      {
         if ((random () < 0.300))
         {
            vz = (vz + 100.000);
            // If vertical velocity has been steady, add an extra boost to break beams.
            if ((fabs ((self.self_vel_hist1_z - self.self_vel_hist2_z)) < 50.000))
            {
               vz = (vz * 1.200);
            } //end if
         } //end if
      } //end if
   } //end if
   move_angles = self.angles;
   move_angles_x = 0.000;
   move_angles_y = self.ideal_yaw;
   move_angles_z = 0.000;
   makevectors (move_angles);
   start = (self.origin + (SECRET_YES_SHOOT * v_forward));
   botTarget = self.goalentity;
   velz = vz;
   if ((wlevel >= SPAWNFLAG_SUPERSPIKE))
   {
      if ((velz > 200.000))
      {
         velz = 200.000;
      } //end if
   } //end if
   if ((wlevel == SPAWNFLAG_LASER))
   {
      if ((botTarget.origin_z < self.origin_z))
      {
         return (FALSE);
      } //end if
      start_z = (start_z + 45.000);
   } //end if
   botxy = self.origin;
   botxy_z = FALSE;
   diffz = ((start_z - botTarget.origin_z) + SPAWNFLAG_SUPERSPIKE);
   if ((diffz < (CONTENT_EMPTY * MAXJUMP)))
   {
      if ((botTarget.goalentity.classname != "trigger_push"))
      {
         return (FALSE);

      } //end if
      else
      {
         if ((diffz < FALSE))
         {
            if (JumpUpToPush (dist))
            {
               return (TRUE);
            } //end if
         } //end if
      } //end if
   } //end if

   // ===== SMART RJ TRIGGER: Physics-Based Rocket Jump Decision =====
   // If target is too high for normal jump (>MAXJUMP), check if RJ is physically possible.
   // Uses precise physics calculation (V₀²/2g) instead of arbitrary 1.5× threshold.
   // Prevents bots from attempting impossible RJs (e.g., 500-unit walls).
   // REFACTOR: Added check for Horizontal Speed/Gaps (dis > 350) to trigger dynamic RJs
   if ((diffz > MAXJUMP) || ((dis > 350.000) && (self.weapon == IT_ROCKET_LAUNCHER)))
   {
      if (((self.ammo_rockets > 0) && (self.skil > 2.000)))
      {
         // MATH CHECK: Can we actually reach this height with RJ?
         if (CanRocketJumpHeight (diffz))
         {
            // Physics says YES - attempt rocket jump
            if (bot_rocket_jump ())
            {
               return (TRUE);
            } //end if
         } //end if
         // else: Physics says NO - target is impossible, don't try
      } //end if
   } //end if
   // ===== END SMART RJ TRIGGER =====

   dis = dist;
   goalxy = botTarget.origin;
   // ===== TWEAK #3: Jump arc train prediction (velocity guess → path chain) =====
   // When jump target is a train, predict its position along path_corner chain at
   // jump landing time (LEVELJUMPTIME ≈ 0.6s) instead of simple velocity guess.
   // Ensures bot jumps to where train will be, not where it is—precise mid-air sync.
   if ((botTarget.goalentity.classname == "train"))
   {
      goalxy = predict_train_pos(botTarget.goalentity, LEVELJUMPTIME);
   } //end if
   // ===== END TWEAK #3 =====
   lnd = pointcontents (goalxy);
   if (((lnd == CONTENT_LAVA) || (lnd == CONTENT_SLIME)))
   {
      return (FALSE);
   } //end if
   goalxy_z = FALSE;
   xydir = normalize ((goalxy - botxy));
   diffxy = vlen ((goalxy - botxy));
   if ((wlevel == SPAWNFLAG_LASER))
   {
      if ((diffxy > (CAM_FOLLOW * BOTSPEED)))
      {
         diffxy = (CAM_FOLLOW * BOTSPEED);
      } //end if
   } //end if
   bottom = (start + self.view_ofs);
   top = (bottom + (xydir * dis));
   top_z = (top_z + (0.100 * (velz - GRAVITY)));
   traceline (bottom,top,SPAWNFLAG_SUPERSPIKE,self);
   if ((trace_fraction != SPAWNFLAG_SUPERSPIKE))
   {
      if ((velz > (GRAVITY + 180.000)))
      {
         return (Bot_tryjump ((velz - GRAVITY),dist,imagine));

      } //end if
      else
      {
         return (FALSE);
      } //end if
   } //end if
   bottom = (start - (SECRET_YES_SHOOT * v_forward));
   bottom_z = (bottom_z + self.mins_z);
   top = (bottom + ((xydir * dis) * SPAWNFLAG_LASER));
   top_z = ((top_z + (0.200 * (velz - GRAVITY))) - (0.100 * GRAVITY));
   traceline (bottom,top,SPAWNFLAG_SUPERSPIKE,self);
   if ((trace_fraction != SPAWNFLAG_SUPERSPIKE))
   {
      if ((diffxy > (1.900 * BOTSPEED)))
      {
         diffxy = (1.900 * BOTSPEED);
      } //end if
      top = (bottom + (xydir * dis));
      top_z = ((top_z + (0.200 * (velz - GRAVITY))) - (0.100 * GRAVITY));
      traceline (bottom,top,SPAWNFLAG_SUPERSPIKE,self);
      if ((trace_fraction != SPAWNFLAG_SUPERSPIKE))
      {
         if ((diffxy > (0.900 * BOTSPEED)))
         {
            diffxy = (0.900 * BOTSPEED);
         } //end if
         velz = 290.000;
      } //end if
   } //end if
   timetofloor = FALSE;
   tvel = velz;
   if ((diffz < FALSE))
   {
      timetofloor = 0.300;

   } //end if
   else
   {
      while ((diffz > FALSE))
      {
         timetofloor = (timetofloor + 0.100);
         tvel = (tvel - GRAVITY);
         diffz = (diffz + (tvel * 0.100));
      } //end while
      timetofloor = (timetofloor - (diffz / tvel));
   } //end if
   if ((diffxy < ((dis * MOVETYPE_BOUNCE) * timetofloor)))
   {
      jumpv = (xydir * (diffxy / timetofloor));

   } //end if
   else
   {
      jumpv = (xydir * (MOVETYPE_BOUNCE * dis));
      if (imagine)
      {
         return (FALSE);
      } //end if
   } //end if
   tvel = velz;
   bottom = start;
   bottom_z = (bottom_z + self.mins_z);
   ht = (self.view_ofs_z - self.mins_z);
   NOTLAND = TRUE;
   sim_interval = 0.100; // 100ms steps
   while (NOTLAND)
   {
      tvel = (tvel - (GRAVITY * sim_interval));
      newbottom = (bottom + (jumpv * sim_interval));
      newbottom_z = (newbottom_z + (tvel * sim_interval));
      traceline (bottom,newbottom,TRUE,self);
      if ((trace_fraction < 1.000))
      {
         if ((trace_plane_normal_z > 0.700))
         {
            newbottom = trace_endpos;
            newbottom_z = trace_endpos_z;
            NOTLAND = FALSE;
         } //end if
         else
         {
            return (FALSE);
         } //end if
      } //end if
      if (NOTLAND)
      {
         lnd = pointcontents (newbottom);
         if ((lnd <= CONTENT_SLIME))
         {
            return (FALSE);
         } //end if
         bottom = newbottom;
         if ((bottom_z < (self.origin_z - 500.000)))
         {
            return (FALSE);
         } //end if
      } //end if
      else
      {
         bottom = newbottom;
      } //end if
   } //end while
   jumpv_z = velz;
   if (imagine)
   {
      if ((wlevel == SPAWNFLAG_LASER))
      {
         return (teleptest (45.000));
      } //end if
      return (TRUE);
   } //end if
   if ((wlevel == SPAWNFLAG_LASER))
   {
      return (Botwaterjump (jumpv));
   } //end if
   if ((newbottom_z < (self.absmin_z - MAXJUMP)))
   {
      clearCache (self);
   } //end if
   return (Botjump (jumpv));
}; //end of the function Bot_tryjump

// ===== ENHANCED ROCKET JUMP: Dynamic Directional Logic =====
// Calculates optimal pitch/yaw to propel bot TOWARD the target.
// - High Ledge? Aim nearly straight down (85°) for maximum vertical pop.
// - Wide Gap? Aim shallower (45°) to convert explosion force into forward speed.
float() bot_rocket_jump =
{
   local vector jumpv;
   local vector dir;
   local float dist;
   local float pitch_aim;
   local vector aim_angles;
   local vector aim_dir;

   // 1. Safety Checks
   if ((self.ammo_rockets < 1)) return (FALSE);
   if (!(self.items & IT_ROCKET_LAUNCHER)) return (FALSE);
   if ((self.health < 40.000)) return (FALSE); // Prevent suicide (lowered to 40 for gap crossing)
   if ((time < self.rj_cooldown)) return (FALSE); // 2s cooldown
   if (!self.goalentity) return (FALSE); // Need a target for directional RJ

   // 2. Calculate Geometry
   // We need to know where the goal is relative to us
   dir = normalize((self.goalentity.origin - self.origin));
   dist = vlen((self.goalentity.origin - self.origin));

   // 2b. Ceiling Clearance Check (from link-based RJ system)
   // Prevents RJ in tight spaces where upward blast would hit ceiling and kill bot
   traceline(self.origin, self.origin + '0.000 0.000 96.000', TRUE, self);
   if (trace_fraction < 1.000)
   {
      // Blocked by ceiling—abort RJ to prevent suicide
      return (FALSE);
   } //end if

   // 2c. Check for Learned RJ Waypoint (Player Observation Learning)
   // If there's a learned RJ waypoint nearby, use its exact pitch angle
   local entity learned_rj;
   local float use_learned_angle;
   use_learned_angle = FALSE;

   learned_rj = findradius(self.origin, 128.000);  // Search 128u radius
   while (learned_rj)
   {
      if ((learned_rj.classname == "BotPath") && learned_rj.rj_learned)
      {
         // Found a learned RJ waypoint! Use its pitch angle
         pitch_aim = learned_rj.rj_pitch;
         use_learned_angle = TRUE;

         // DEBUG: Print when bot uses learned RJ
         bprint(self.netname);
         bprint(" using learned RJ: pitch=");
         bprint(ftos(pitch_aim));
         bprint("° (expected vel=");
         bprint(ftos(learned_rj.rj_velocity_gain));
         bprint(" u/s)\n");

         learned_rj = world;  // Break loop
      }
      else
      {
         learned_rj = learned_rj.chain;
      }
   } //end while

   // 3. Dynamic Pitch Selection (LEARNED FROM PLAYER OBSERVATION)
   // Player data shows -29.5° is optimal (not -85° "bind-like" vertical)
   // Shallower angles = less damage, more forward momentum, smoother movement
   // OLD: -85° default (70-100+ HP damage, suicide risk)
   // NEW: -30° to -35° base (19-51 HP damage, efficient like player)

   // Only calculate pitch if we didn't find a learned RJ waypoint
   if (!use_learned_angle)
   {
      // Default: Player-learned efficient angle (-35° base, not -85° suicide angle)
      pitch_aim = -35.000;

      // High-skill bots use even shallower angle (matches observed -29.5° player technique)
      if ((self.skil > 3.000))
      {
         pitch_aim = -30.000; // Pro player angle from observation data
      } //end if

      // Health-aware: Go shallower when hurt (minimize damage)
      if ((self.health < 75.000))
      {
         pitch_aim = -25.000; // Gentle RJ when already weak
      } //end if

      // Gap crossing: Use slightly steeper angle for more vertical lift
      // Only for targets that are both far AND significantly higher
      if (((dist > 300.000) && ((self.goalentity.origin_z - self.origin_z) > 64.000)))
      {
         pitch_aim = -45.000; // More vertical for high+far targets (keep old gap angle)
      } //end if
   } //end if
   // else: use the learned pitch angle from the nearby RJ waypoint

   // 4. Compute Aim Angles (without writing view angles)
   // Pitch: look down/back based on calculated need
   aim_angles_x = pitch_aim;

   // Yaw: Face exactly OPPOSITE to the target direction
   // This ensures the explosion pushes us directly toward the goal
   aim_angles_y = (vectoyaw (dir) + 180.000);
   aim_angles_z = 0.000;

   makevectors (aim_angles);
   aim_dir = v_forward;

   Bot_RequestAim (aim_angles_y,pitch_aim,TRUE,TRUE,AIM_OWNER_NAV,R_NONE,"rocket jump");
   self.botaim_override = aim_dir;
   self.botaim_override_active = TRUE;

   // 5. Execute Sequence
   W_FireRocket (); // Fire at the calculated angle
   self.botaim_override_active = FALSE;
   self.botaim_override = '0.000 0.000 0.000';

   // Synchronized jump to catch blast
   // Base vertical jump + heavy kick from the explosion direction
   jumpv = '0.000 0.000 270.000';

   // Add forward momentum relative to where we want to go (aim_dir is pointing back)
   // We invert v_forward because we are looking backwards
   // AGGRESSIVE LEAP: Tripled from -120 to -320 (running speed) to clear wide gaps like DM2 Quad
   jumpv = (jumpv + (aim_dir * -320.000));

   Botjump (jumpv);

   // 6. Cleanup: Set cooldown (prevents spam) and reset stuck counter (successful escape)
   self.rj_cooldown = (time + 2.000);
   self.stuck_count = 0;
   self.stuck_score = 0.000;
   self.stuck_mode = BOT_MODE_NORMAL;
   self.last_progress_time = time;
   self.last_origin = self.origin;
   self.progress_check_time = (time + STUCK_PROGRESS_INTERVAL);

   // PHASE 3 FIX: Verify success in 0.1 seconds (failure recovery)
   self.rj_verify_time = (time + 0.100);

   return (TRUE);
}; //end of the function bot_rocket_jump
// ===== END ENHANCED ROCKET JUMP =====

// ===== PHASE 9: GROUND HAZARD DETECTION (Layer 1 - Proactive Safety) =====
// Adapted from FrikBot's "Look Before You Leap" system - prevents bots from casually
// walking into lava pools, broken bridges, and cliff edges. Complements existing Phase 4
// mid-air hazard avoidance (reactive aerial steering) with ground-level prevention.
// Two-layer defense: Layer 1 (this) stops hazard entry, Layer 2 (Phase 4) saves airborne bots.
void () CheckForHazards =
{
   local vector spot;
   local float gap_depth;
   local float content_type;
   local vector left_spot, right_spot;
   local float left_gap, right_gap;
   local vector land_spot;
   local float land_content;
   local float escape_yaw;
   local vector escape_dir;
   local vector escape_probe;
   local float escape_height;
   local float escape_drop;
   local float base_yaw;
   local vector look_angles;
   local vector goal_dir;
   local vector vel_dir;
   local float vel_len;

   // Only check if we are on the ground
   if (!(self.flags & FL_ONGROUND))
   {
      return ;
   } //end if
   if ((self.hazard_escape_until > time))
   {
      return ;
   } //end if
   if ((self.stuck_mode == BOT_MODE_UNSTICK))
   {
      return ;
   } //end if
   if ((self.fg_driver == FG_DRV_TERRAIN))
   {
      return ;
   } //end if

   vel_dir = self.velocity;
   vel_dir_z = 0.000;
   vel_len = vlen (vel_dir);
   if ((((self.move_mode == BOT_MOVE_NONE) || (self.move_mode == BOT_MOVE_STAND)) && (vel_len < 20.000)))
   {
      return ;
   } //end if

   base_yaw = self.ideal_yaw;
   if ((self.fg_driver != FG_DRV_NONE) && (vlen (self.fg_goalDir) > 0.000))
   {
      base_yaw = vectoyaw (self.fg_goalDir);
   } //end if
   else if ((vel_len > 20.000))
   {
      base_yaw = vectoyaw (vel_dir);
   } //end if
   else if (self.move_target)
   {
      goal_dir = (self.move_target.origin - self.origin);
      if ((vlen (goal_dir) > 1.000))
      {
         base_yaw = vectoyaw (goal_dir);
      } //end if
   } //end else if
   else if ((vlen (self.move_target_org) > 1.000))
   {
      goal_dir = (self.move_target_org - self.origin);
      if ((vlen (goal_dir) > 1.000))
      {
         base_yaw = vectoyaw (goal_dir);
      } //end if
   } //end else if
   else if (self.goalentity)
   {
      goal_dir = (self.goalentity.origin - self.origin);
      if ((vlen (goal_dir) > 1.000))
      {
         base_yaw = vectoyaw (goal_dir);
      } //end if
   } //end else
   look_angles = self.angles;
   look_angles_x = 0.000;
   look_angles_y = base_yaw;
   look_angles_z = 0.000;

   // 1. Look ahead (based on ideal_yaw - where bot is trying to move)
   makevectors (look_angles);
   spot = (self.origin + (v_forward * 60.000));  // Look 60 units ahead
   spot_z = self.origin_z;

   // 2. Look Down (trace 250 units to find floor or void)
   traceline (spot,(spot - '0.000 0.000 250.000'),TRUE,self);

   // 3. Analyze what we found
   gap_depth = (self.origin_z - trace_endpos_z);
   content_type = pointcontents (trace_endpos);

   // CASE A: The "Gap" (Empty space or very deep drop)
   if (((trace_fraction == 1.000) || (gap_depth > 60.000)))
   {
      // ===== DECORATIVE HOLE FILTER: Check gap width =====
      // Player bounding box is 32x32 units, so gaps <40 units wide can't be fallen through.
      // Trace to the left and right to see if this is a narrow decorative hole (grate, drain, etc.)
      left_spot = (spot + (v_right * -20.000));  // 20 units left
      left_spot_z = self.origin_z;
      traceline (left_spot,(left_spot - '0.000 0.000 250.000'),TRUE,self);
      left_gap = (self.origin_z - trace_endpos_z);

      right_spot = (spot + (v_right * 20.000));  // 20 units right
      right_spot_z = self.origin_z;
      traceline (right_spot,(right_spot - '0.000 0.000 250.000'),TRUE,self);
      right_gap = (self.origin_z - trace_endpos_z);

      // If BOTH left and right traces hit solid floor (gap_depth < 20), this is a narrow hole.
      // The bot's 32x32 bounding box can't fit through, so treat it as solid floor.
      if (((left_gap < 20.000) && (right_gap < 20.000)))
      {
         return;  // Not a real hazard (decorative hole), continue walking
      } //end if
      // ===================================================

      // There is a dropoff ahead!

      // Is it a "Death Pit" (Slime/Lava/Void)?
      if (((content_type <= CONTENT_SLIME) || (trace_fraction == 1.000)))
      {
         // [SOFT STOP] Decelerate rapidly instead of freezing (prevents stuttering)
         // 1. Cut velocity by 90% (rapid friction)
         self.velocity = (self.velocity * 0.100);

         // 2. Add a tiny backward nudge to unstick from the edge lip
         self.velocity = (self.velocity + (v_forward * -50.000));

         // 3. Force immediate rotation away from the hazard
         if ((self.hazard_escape_until <= time))
         {
            if (((self.stuck_mode == BOT_MODE_UNSTICK) || (self.stuck_score > 1.000)))
            {
               self.ideal_yaw = base_yaw;
               escape_dir = Bot_PickTerrainEscape (self);
            } //end if
            else
            {
               escape_yaw = (base_yaw + 135.000);
               if ((random () < 0.500))
               {
                  escape_yaw = (base_yaw - 135.000);
               } //end if
               look_angles_y = escape_yaw;
               makevectors (look_angles);
               escape_dir = v_forward;
            } //end else
            escape_probe = (self.origin + (escape_dir * 96.000));
            escape_height = SampleGroundHeight (self,escape_probe);
            escape_drop = (self.origin_z - escape_height);
            if (((escape_height < -90000.000) || (escape_drop > 64.000)))
            {
               escape_dir = -v_forward;
            } //end if
            escape_yaw = vectoyaw (escape_dir);
            RecordDirectionalFail (self,escape_dir);
            self.hazard_escape_yaw = escape_yaw;
            self.hazard_escape_until = (time + 1.200);
            self.bad_spot_origin = self.origin;
            self.bad_spot_radius = 220.000;
            self.bad_spot_expire_time = (time + 10.000);
            FG_Request (self,95.000,FG_DRV_TERRAIN,escape_dir,1.200);
         if (((self.stuck_mode != BOT_MODE_UNSTICK) && ((self.stuck_score > 1.000) || ((time - self.last_progress_time) > 0.600))))
         {
            Bot_EnterUnstick (R_UNSTICK_TERRAIN,"edge hazard");
            self.escape_until_time = self.hazard_escape_until;
            self.is_retracing = FALSE;
         } //end if
      } //end if
      if (((time - self.hazard_edge_time) < 3.000))
      {
         if ((vlen (self.origin - self.hazard_edge_origin) < 96.000))
         {
            self.hazard_edge_count = (self.hazard_edge_count + 1.000);
         } //end if
         else
         {
            self.hazard_edge_count = 1.000;
            self.hazard_edge_origin = self.origin;
         } //end else
      } //end if
      else
      {
         self.hazard_edge_count = 1.000;
         self.hazard_edge_origin = self.origin;
      } //end else
      self.hazard_edge_time = time;
      if ((self.hazard_edge_count >= 3.000))
      {
         self.bad_spot_origin = self.origin;
         self.bad_spot_radius = 320.000;
         self.bad_spot_expire_time = (time + 20.000);
         self.stuck_score = (STUCK_SCORE_THRESH + 1.000);
         if ((self.stuck_mode != BOT_MODE_UNSTICK))
         {
            Bot_EnterUnstick (R_UNSTICK_TERRAIN,"edge hazard loop");
         } //end if
         self.hazard_edge_count = 0.000;
      } //end if
      if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
      {
         if ((self.hazard_log_time <= time))
         {
            bprint ("[");
               bprint (self.netname);
               bprint ("] HAZARD: Edge Catch (soft stop)\n");
               self.hazard_log_time = (time + 0.500);
            } //end if
         } //end if
         return ;
      } //end if

      // Is it a jumpable gap? (only if moving fast enough)
      if ((vlen (self.velocity) > 200.000))
      {
         self.button2 = 1.000;  // Jump key
      } //end if
   } //end if

   // CASE B: The "Hazard Floor" (Walking directly into lava/slime)
   else
   {
      if ((content_type <= CONTENT_SLIME))
      {
         // The floor ahead is lava/slime
         // Only jump if there appears to be safe ground to land on.
         land_spot = (spot + (v_forward * 120.000));
         land_spot_z = self.origin_z;
         traceline (land_spot,(land_spot - '0.000 0.000 250.000'),TRUE,self);
         if ((trace_fraction == 1.000))
         {
            // [SOFT STOP] Decelerate rapidly instead of freezing
            self.velocity = (self.velocity * 0.100);
            self.velocity = (self.velocity + (v_forward * -50.000));

            if ((self.hazard_escape_until <= time))
            {
               if (((self.stuck_mode == BOT_MODE_UNSTICK) || (self.stuck_score > 1.000)))
               {
                  self.ideal_yaw = base_yaw;
                  escape_dir = Bot_PickTerrainEscape (self);
               } //end if
               else
               {
                  escape_yaw = (base_yaw + 135.000);
                  if ((random () < 0.500))
                  {
                     escape_yaw = (base_yaw - 135.000);
                  } //end if
                  look_angles_y = escape_yaw;
                  makevectors (look_angles);
                  escape_dir = v_forward;
               } //end else
               escape_probe = (self.origin + (escape_dir * 96.000));
               escape_height = SampleGroundHeight (self,escape_probe);
               escape_drop = (self.origin_z - escape_height);
               if (((escape_height < -90000.000) || (escape_drop > 64.000)))
               {
                  escape_dir = -v_forward;
               } //end if
               escape_yaw = vectoyaw (escape_dir);
               RecordDirectionalFail (self,escape_dir);
               self.hazard_escape_yaw = escape_yaw;
               self.hazard_escape_until = (time + 1.200);
               self.bad_spot_origin = self.origin;
               self.bad_spot_radius = 220.000;
               self.bad_spot_expire_time = (time + 10.000);
               FG_Request (self,95.000,FG_DRV_TERRAIN,escape_dir,1.200);
               if (((self.stuck_mode != BOT_MODE_UNSTICK) && ((self.stuck_score > 1.000) || ((time - self.last_progress_time) > 0.600))))
               {
                  Bot_EnterUnstick (R_UNSTICK_TERRAIN,"edge hazard");
                  self.escape_until_time = self.hazard_escape_until;
                  self.is_retracing = FALSE;
               } //end if
            } //end if
            if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
            {
               if ((self.hazard_log_time <= time))
               {
                  bprint ("[");
                  bprint (self.netname);
                  bprint ("] HAZARD: Blocked jump (no landing, soft stop)\n");
                  self.hazard_log_time = (time + 0.500);
               } //end if
            } //end if
            return ;
         } //end if
         land_content = pointcontents (trace_endpos);
         if (((land_content == CONTENT_LAVA) || (land_content == CONTENT_SLIME)))
         {
            // [SOFT STOP] Decelerate rapidly instead of freezing
            self.velocity = (self.velocity * 0.100);
            self.velocity = (self.velocity + (v_forward * -50.000));
            if ((self.hazard_escape_until <= time))
            {
               if (((self.stuck_mode == BOT_MODE_UNSTICK) || (self.stuck_score > 1.000)))
               {
                  self.ideal_yaw = base_yaw;
                  escape_dir = Bot_PickTerrainEscape (self);
               } //end if
               else
               {
                  escape_yaw = (base_yaw + 135.000);
                  if ((random () < 0.500))
                  {
                     escape_yaw = (base_yaw - 135.000);
                  } //end if
                  look_angles_y = escape_yaw;
                  makevectors (look_angles);
                  escape_dir = v_forward;
               } //end else
               escape_probe = (self.origin + (escape_dir * 96.000));
               escape_height = SampleGroundHeight (self,escape_probe);
               escape_drop = (self.origin_z - escape_height);
               if (((escape_height < -90000.000) || (escape_drop > 64.000)))
               {
                  escape_dir = -v_forward;
               } //end if
               escape_yaw = vectoyaw (escape_dir);
               RecordDirectionalFail (self,escape_dir);
               self.hazard_escape_yaw = escape_yaw;
               self.hazard_escape_until = (time + 1.200);
               self.bad_spot_origin = self.origin;
               self.bad_spot_radius = 220.000;
               self.bad_spot_expire_time = (time + 10.000);
               FG_Request (self,95.000,FG_DRV_TERRAIN,escape_dir,1.200);
               if (((self.stuck_mode != BOT_MODE_UNSTICK) && ((self.stuck_score > 1.000) || ((time - self.last_progress_time) > 0.600))))
               {
                  Bot_EnterUnstick (R_UNSTICK_TERRAIN,"edge hazard");
                  self.escape_until_time = self.hazard_escape_until;
                  self.is_retracing = FALSE;
               } //end if
            } //end if
            if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
            {
               if ((self.hazard_log_time <= time))
               {
                  bprint ("[");
                  bprint (self.netname);
                  bprint ("] HAZARD: Blocked jump (unsafe landing)\n");
                  self.hazard_log_time = (time + 0.500);
               } //end if
            } //end if
            return ;
         } //end if
         self.button2 = 1.000;  // Try to jump over it
      } //end if
   } //end if
}; //end of the function CheckForHazards
// ===== END PHASE 9: GROUND HAZARD DETECTION =====

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

// ===== PHASE 11: WATER SURVIVAL (Drowning Prevention) =====
// Detects when bot is underwater and running out of air, forcing surface swim.
// Prevents bots from suffocating in deep water by checking air_finished field.
// Inspired by FrikBot's "Up Periscope" logic, adapted to Reaper's movement system.
void() CheckWaterSurvival =
{
   // Are we fully underwater?
   if (self.waterlevel > 2)
   {
      // Are we running out of air? (air_finished is standard QuakeC field)
      // Check 2 seconds before drowning to give time to surface
      if (time > self.air_finished - 2)
      {
         // Trace upward to see if there's air above us
         traceline(self.origin, self.origin + '0 0 600', TRUE, self);

         if (trace_inopen)
         {
            // AIR DETECTED ABOVE - SURFACE NOW!
            // Force upward swim using jump button (same as player surfacing)
            self.button2 = 1;

            // Add upward velocity to help break surface
            if ((self.velocity_z < 150.000))
            {
               self.velocity_z = 200.000;
            } //end if

            // Look up slightly to assist physics engine
            Bot_RequestAim (self.angles_y,-45.000,FALSE,TRUE,AIM_OWNER_NAV,R_NONE,"water surface");

            // Optional: Clear any combat/movement commands while surfacing
            // (comment out if we want bots to shoot while drowning - less realistic)
            // self.button0 = 0;
         }
      }
   }
};
// ===== END PHASE 11: WATER SURVIVAL =====

float (float dist) waterupdown =
{
   local float wlevel;
   local float dis;
   local float rnd;
   local float zbottom;

   dis = LOOPTIME;
   wlevel = CheckWaterLevel ();
   if ((wlevel < SPAWNFLAG_LASER))
   {
      return (FALSE);
   } //end if
   if ((self.absmin_z > self.goalentity.origin_z))
   {
      if ((dis > LOOPTIME))
      {
         dis = LOOPTIME;
      } //end if
      if (waterdownz (dis))
      {
         return (TRUE);
      } //end if
      if (waterdownz ((dis * 0.500)))
      {
         return (TRUE);
      } //end if
      if (waterdownz ((dis * 0.200)))
      {
         return (TRUE);
      } //end if
   } //end if
   if ((wlevel == CAM_FOLLOW))
   {
      if ((self.absmin_z < self.goalentity.origin_z))
      {
         dis = (self.goalentity.origin_z - self.absmin_z);
         if ((dis > LOOPTIME))
         {
            dis = LOOPTIME;
         } //end if
         if (waterupz (dis))
         {
            return (TRUE);
         } //end if
         if (waterupz ((dis * 0.500)))
         {
            return (TRUE);
         } //end if
         if (waterupz ((dis * 0.200)))
         {
            return (TRUE);
         } //end if
      } //end if
   } //end if
   return (FALSE);
}; //end of the function waterupdown

// ===== BONUS TWEAK #5: Active Combat Hopping + Wall Sliding =====
// The Ultimate Movement Function:
// 1. Slides along walls (prevents getting stuck)
// 2. Bunny-hops in combat (harder to hit)
// 3. Stabilizes aim when using Lightning Gun (no jumping)
void (float dist) strafemove =
{
   local float ofs;
   local float pat_var;
   local vector move_dir;
   local vector wall_normal;
   local vector slide_dir;
   local float slide_yaw;
   local vector org_start;
   local float abs_pat_var;
   local float do_jump; // NEW: Jump decision flag
   local vector move_angles;

   if ((self.flags & FL_SWIM))
   {
      if (waterupdown (dist))
      {
         return ;
      } //end if
   } //end if

   // Weapon-aware evasion: set dodge mode from the enemy's current weapon.
   self.evade_mode = 0;
   if (self.enemy)
   {
      if ((self.enemy != world))
      {
         if ((self.enemy.weapon == IT_ROCKET_LAUNCHER))
         {
            self.evade_mode = TRUE;
         } //end if
         else
         {
            if ((self.enemy.weapon == IT_LIGHTNING))
            {
               self.evade_mode = 2.000;
            } //end if
         } //end if
      } //end if
   } //end if

   ofs = 90.000;
   // Wider strafe arcs when evading, scaled by skill for less predictability.
   if ((self.evade_mode && (self.skil > TRUE)))
   {
      ofs = (ofs * (TRUE + (random () * 0.500)));
   } //end if

   // Track recent self-velocity in a small ring buffer for zigzag timing.
   if ((self.self_vel_hist_idx == 0))
   {
      self.self_vel_hist0 = self.velocity;
   } //end if
   else
   {
      if ((self.self_vel_hist_idx == TRUE))
      {
         self.self_vel_hist1 = self.velocity;
      } //end if
      else
      {
         self.self_vel_hist2 = self.velocity;
      } //end if
   } //end else
   self.self_vel_hist_idx = (self.self_vel_hist_idx + TRUE);
   if ((self.self_vel_hist_idx > 2.000))
   {
      self.self_vel_hist_idx = 0;
   } //end if

   // Zigzag logic: if speed changed enough recently, flip strafe direction vs rockets.
   if (((self.evade_mode == TRUE) && (self.skil > TRUE)))
   {
      pat_var = ((vlen (self.self_vel_hist0) - vlen (self.self_vel_hist2)) / 100.000);

      // Manual absolute value (QuakeC has no fabs)
      abs_pat_var = pat_var;
      if ((abs_pat_var < 0.000))
      {
         abs_pat_var = (abs_pat_var * -1.000);
      } //end if

      if ((abs_pat_var > 0.500))
      {
         ofs = (-1 * ofs);
      } //end if
   } //end if

   // ===== SMOOTHING: Strafe Hysteresis (Anti-Vibration) =====
   // Force the bot to commit to a strafe direction for at least 0.5 seconds
   // unless hitting a solid wall. This prevents seizure-like left-right vibration.
   if ((time < self.strafe_state_time))
   {
       // We are locked in.
       // Only break lock if we are literally stuck (velocity near 0)
       if ((vlen (self.velocity) > 20.000))
       {
           // Force the 'ofs' to match our locked direction
           if ((self.strafe_dir_lock == 1.000))
           {
               ofs = 90.000;
           } //end if
           else
           {
               ofs = -90.000;
           } //end if
       } //end if
   } //end if
   // =======================================

   // --- NEW: Combat & Navigation Jumping (Bunny Hopping) ---
   // Instead of only walking, we now actively try to jump to gain speed (Tweak #1)
   // and dodge attacks, just like a human player.
   do_jump = FALSE;

   // Only jump if on ground and high enough skill
   if (((self.flags & FL_ONGROUND) && (self.skil > 1)))
   {
       // 1. LG Stability: Don't jump if firing Lightning Gun (needs smooth tracking)
       // Jumping with LG creates "bouncing aiming" which is bad for hitscan.
       if ((self.weapon != IT_LIGHTNING))
       {
           // 2. Projectile Evasion: If enemy has RL/GL, jump frequently to throw off splash damage
           if ((self.evade_mode == TRUE))
           {
               if ((random () < 0.200)) do_jump = TRUE;
           } //end if
           // 3. General Combat/Travel: Occasional hops to maintain speed/unpredictability
           else
           {
               // Patrol/Travel: Hop less often to avoid noise
               if (!self.enemy)
               {
                   if ((random () < 0.050)) do_jump = TRUE;
               } //end if
               // Combat: Hop more often
               else
               {
                   if ((random () < 0.100)) do_jump = TRUE;
               } //end if
           } //end if
       } //end if
   } //end if

   // Execute Jump
   if (do_jump)
   {
       // 270 is standard jump velocity
       if (Bot_tryjump (270.000,dist,FALSE)) return ;
   } //end if
   // --- END NEW JUMP LOGIC ---

   // No-enemy patrol: wander logic
   if (!self.enemy)
   {
      self.ideal_yaw = (self.ideal_yaw + ((random () - 0.500) * 180.000));
      Bot_WalkMove (self.ideal_yaw,dist);
      return ;
   } //end if

   self.strafeonly = MOVETYPE_FLY;
   if ((self.lefty & STRAFE_DIR))
   {
      ofs = (-1 * ofs);
   } //end if

   // ===== SMOOTHING: Direction Change Tracking =====
   // Check if we are changing strafe direction, and reset commitment timer
   if ((self.strafe_dir_lock == 0.000)) // Init
   {
       self.strafe_state_time = (time + 0.500);
       if ((ofs > 0.000))
       {
           self.strafe_dir_lock = 1.000;
       } //end if
       else
       {
           self.strafe_dir_lock = -1.000;
       } //end if
   } //end if
   else
   {
       if (((ofs > 0.000) && (self.strafe_dir_lock == -1.000)) || ((ofs < 0.000) && (self.strafe_dir_lock == 1.000)))
       {
           // We are flipping. Reset timer.
           self.strafe_state_time = (time + 0.500);
           if ((ofs > 0.000))
           {
               self.strafe_dir_lock = 1.000;
           } //end if
           else
           {
               self.strafe_dir_lock = -1.000;
           } //end if
       } //end if
   } //end if
   // =======================================

   // --- Attempt Primary Move ---
   if (Bot_WalkMove ((self.ideal_yaw + ofs),dist))
   {
      return ;
   } //end if

   // ===== STAIR SMOOTHING: Enhanced Step Climbing =====
   // If blocked, check if it's just a low step (stairs/debris).
   // Trace 30 units (above step height) to see if path is clear at knee level.
   local vector step_trace_dest;
   local vector dir;
   local float angle_rad;

   // Calculate direction vector from ideal_yaw + ofs
   angle_rad = ((self.ideal_yaw + ofs) * (3.14159 / 180.000)); // Convert to radians

   // Manual vector construction (QuakeC doesn't have cos/sin, use makevectors workaround)
   move_angles = self.angles;
   move_angles_x = 0.000;
   move_angles_y = (self.ideal_yaw + ofs);
   move_angles_z = 0.000;
   makevectors (move_angles);
   dir = v_forward;
   dir_z = 0.000;
   dir = normalize(dir);

   step_trace_dest = (self.origin + (dir * dist));
   step_trace_dest_z = (self.origin_z + 30.000); // Check higher for multi-step stairs

   // Trace forward at knee height
   traceline((self.origin + '0.000 0.000 30.000'), step_trace_dest, TRUE, self);

     if ((trace_fraction == 1.000))
     {
        // Knee-height is clear! The blockage is below our knees (a step).
        // Give a proper hop to clear stairs smoothly.
        // Allow consecutive hops for multi-step stairs.
        if ((self.flags & FL_ONGROUND))
        {
           self.velocity_z = 270.000; // Full hop velocity (matches standard jump)
           self.flags = (self.flags - FL_ONGROUND);
           return ;
        } //end if
     } //end if
   // =======================================

   // --- SLIDE LOGIC #1 (from Step 4) ---
   move_angles_y = (self.ideal_yaw + ofs);
   makevectors (move_angles);
   org_start = self.origin;
   traceline(org_start, org_start + (v_forward * 16), TRUE, self);

   if (trace_fraction < 1.0)
   {
       move_dir = v_forward;
       wall_normal = trace_plane_normal;
       slide_dir = move_dir - (wall_normal * (move_dir * wall_normal));
       slide_dir = normalize(slide_dir);
       slide_yaw = vectoyaw(slide_dir);
       if (Bot_WalkMove(slide_yaw, dist)) return ;

       // ===== PROBLEM SOLVER: Enhanced Door/Button Logic =====
       // If we are stuck against a closed door, activate the solver.
       if ((trace_ent.classname == "func_door"))
       {
          // Is the door closed/closing? (State 0=Closed, 1=Opening, 2=Open, 3=Closing)
          if ((trace_ent.state == 0.000))
          {
             Bot_SolveBlockedDoor (trace_ent);
             return ;
          } //end if
       } //end if

       // ===== PROBLEM SOLVER: Teleporter Pad Navigation =====
       // If blocked and there's a nearby teleporter, navigate directly onto it
       // This prevents bots from shuffling around the edges of teleporter pads
       local entity nearby_tele;
       nearby_tele = findradius (self.origin,128.000);
       while (nearby_tele)
       {
          if ((nearby_tele.classname == "trigger_teleport"))
          {
             // Found a nearby teleporter - aim for its center
             self.ideal_yaw = vectoyaw ((nearby_tele.origin - self.origin));
             Bot_RequestAim (self.ideal_yaw,0.000,TRUE,FALSE,AIM_OWNER_NAV,R_NAV_ROAM,"teleport pad");
             // Give a small jump to help navigate onto the trigger volume
             if ((self.flags & FL_ONGROUND))
             {
                self.velocity_z = 200.000;
             } //end if
             return ;
          } //end if
          nearby_tele = nearby_tele.chain;
       } //end while
       // ===== END PROBLEM SOLVER =====
   }

   if (self.enemy)
   {
      return ;
   } //end if

   // Try alternate direction
   ofs = (-1 * ofs);
   if (Bot_WalkMove ((self.ideal_yaw + ofs),dist))
   {
      return ;
   } //end if

   // --- SLIDE LOGIC #2 (from Step 4) ---
   move_angles_y = (self.ideal_yaw + ofs);
   makevectors (move_angles);
   traceline(org_start, org_start + (v_forward * 16), TRUE, self);

   if (trace_fraction < 1.0)
   {
       move_dir = v_forward;
       wall_normal = trace_plane_normal;
       slide_dir = move_dir - (wall_normal * (move_dir * wall_normal));
       slide_dir = normalize(slide_dir);
       slide_yaw = vectoyaw(slide_dir);
       if (Bot_WalkMove(slide_yaw, dist)) return ;
   }

   if ((self.flags & (FL_INWATER + FL_ONGROUND)))
   {
      self.nav_search_time = (self.nav_search_time - 0.300);
   } //end if
}; //end of the function strafemove
// ===== END BONUS TWEAK #5 =====

// ============================================================
// SMOOTHING: "Analog" Turning (Mouse Smoothing)
// ============================================================
// Pro players adjust turn speed dynamically: slow micro-adjustments
// when tracking, fast flicks when acquiring new targets.
// This replaces robotic constant-speed turns with human-like smoothing.
// ============================================================
void() Bot_SmoothTurn =
{
    if ((!self.enemy && !self.aim_req_set_yaw))
    {
        Bot_RequestAim (self.ideal_yaw,0.000,TRUE,FALSE,AIM_OWNER_NAV,R_NAV_ROAM,"nav turn");
    } //end if
}; //end of the function Bot_SmoothTurn
// ============================================================

void (float dist, float wlevel) BotUnderwaterMove =
{
   local float rng;
   local float oldrng;
   local float rnd;

   rnd = random ();
   if ((rnd < 0.750))
   {
      oldrng = vlen ((self.origin - self.goalentity.origin));
      movetogoal (dist);
      rng = vlen ((self.origin - self.goalentity.origin));
      if ((oldrng > rng))
      {
         return ;
      } //end if
      if ((wlevel == SPAWNFLAG_LASER))
      {
         if (Bot_tryjump (200.000,dist,FALSE))
         {
            return ;
         } //end if
      } //end if
   } //end if
   strafemove (dist);
}; //end of the function BotUnderwaterMove
float (float dist) trysidestep =
{
   local vector dir;
   local vector start;
   local vector move_angles;

   dir = (self.goalentity.origin - self.origin);
   dir_z = FALSE;
   dir = normalize (dir);
   start = self.origin;
   start_z = (self.origin_z + (self.view_ofs_z * 0.500));
   traceline (start,(start + (BOTSPEED * dir)),FALSE,self);
   if ((trace_fraction != SPAWNFLAG_SUPERSPIKE))
   {
      strafemove ((dist * 0.600));
      return (TRUE);
   } //end if
   move_angles = self.angles;
   move_angles_x = 0.000;
   move_angles_y = self.ideal_yaw;
   move_angles_z = 0.000;
   makevectors (move_angles);
   start = (start + (v_right * 15.000));
   traceline (start,(start + (BOTSPEED * dir)),FALSE,self);
   if ((trace_fraction != SPAWNFLAG_SUPERSPIKE))
   {
      if (Bot_WalkMove ((self.ideal_yaw - 90.000),(dist * 0.600)))
      {
         return (TRUE);
      } //end if
   } //end if
   start = (start - (v_right * SVC_INTERMISSION));
   traceline (start,(start + (BOTSPEED * dir)),FALSE,self);
   if ((trace_fraction != TRUE))
   {
      if (Bot_WalkMove ((self.ideal_yaw + 90.000),(dist * 0.600)))
      {
         return (TRUE);
      } //end if
   } //end if
   // Escalate: jump or diagonal/backpedal to clear corners and lips.
   if (Bot_tryjump (270.000,dist,FALSE))
   {
      return (TRUE);
   } //end if
   if (Bot_WalkMove ((self.ideal_yaw + 135.000),(dist * 0.400)))
   {
      return (TRUE);
   } //end if
   if (Bot_WalkMove ((self.ideal_yaw - 135.000),(dist * 0.400)))
   {
      return (TRUE);
   } //end if
   if (Bot_WalkMove ((self.ideal_yaw + 180.000),(dist * 0.500)))
   {
      return (TRUE);
   } //end if

   // ===== TWEAK #5: Desperate unstuck via train/rocket/super (strafe → exploit) =====
   // After 5+ stuck attempts, escalate to "human exploit" tactics: train surf (boost off
   // moving train momentum), rocket jump (blast out backward), or super jump (350u leap).
   // Resets counter after escape. Prevents infinite spin-death in geometry traps.
   if (((self.stuck_count > 5) && (self.stuck_mode == BOT_MODE_NORMAL)))
   {
      // ===== STUCK DETECTION LOGGING (LOG_CRITICAL+) =====
      if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
      {
         bprint ("[");
         bprint (self.netname);
         bprint ("] STUCK: Desperate escape (count=");
         bprint (ftos (self.stuck_count));
         bprint (")\n");
      } //end if
      // ===== END STUCK LOGGING =====

      // Check if standing on a moving train—surf away with velocity boost
      local vector train_check;
      local entity ground_ent;
      train_check = self.origin;
      train_check_z = (train_check_z - 32.000);  // Trace 32 units down
      traceline(self.origin, train_check, TRUE, self);
      ground_ent = trace_ent;

      if ((ground_ent.classname == "train"))
      {
         // ===== UNSTUCK METHOD LOGGING (LOG_CRITICAL+) =====
         if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
         {
            bprint ("[");
            bprint (self.netname);
            bprint ("] UNSTUCK: Train surf escape\n");
         } //end if
         // ===== END UNSTUCK LOGGING =====
         // Boost velocity with train momentum (1.5x multiplier for escape power)
         self.velocity = (self.velocity + (ground_ent.velocity * 1.500));
         self.stuck_count = 0;
         self.stuck_score = 0.000;
         self.last_progress_time = time;
         self.last_origin = self.origin;
         self.progress_check_time = (time + STUCK_PROGRESS_INTERVAL);
         return (TRUE);
      } //end if

      // No train—try enhanced rocket jump if available
      if (bot_rocket_jump ())
      {
         // ===== UNSTUCK METHOD LOGGING (LOG_CRITICAL+) =====
         if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
         {
            bprint ("[");
            bprint (self.netname);
            bprint ("] UNSTUCK: Rocket jump escape\n");
         } //end if
         // ===== END UNSTUCK LOGGING =====
         return (TRUE);
      } //end if

      // No rockets—try super jump instead
      // ===== UNSTUCK METHOD LOGGING (LOG_CRITICAL+) =====
      if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
      {
         bprint ("[");
         bprint (self.netname);
         bprint ("] UNSTUCK: Super jump escape\n");
      } //end if
      // ===== END UNSTUCK LOGGING =====
      Bot_tryjump (350.000,dist,FALSE);  // High jump attempt
      self.stuck_count = 0;
      self.stuck_score = 0.000;
      self.last_progress_time = time;
      self.last_origin = self.origin;
      self.progress_check_time = (time + STUCK_PROGRESS_INTERVAL);
      return (TRUE);
   } //end if
   self.stuck_count = (self.stuck_count + 1);  // Track failed sidestep
   // ===== END TWEAK #5 =====

   return (FALSE);
}; //end of the function trysidestep
float (float dist) testmove =
{
   local float rng;
   local float oldrng;

   oldrng = vlen ((self.origin - self.goalentity.origin));
   movetogoal (dist);
   rng = vlen ((self.origin - self.goalentity.origin));
   if ((rng < oldrng))
   {
      return (TRUE);
   } //end if
   return (FALSE);
}; //end of the function testmove

void (float dist) BotmovetoWindTunnel =
{
   if (testmove (dist))
   {
      return ;
   } //end if
   if (trysidestep (dist))
   {
      return ;
   } //end if
   if (Bot_tryjump (270.000,dist,FALSE))
   {
      return ;
   } //end if
   strafemove ((dist * 0.500));
   return ;
}; //end of the function BotmovetoWindTunnel

void (float dist) BotmovetoVisiblegoal =
{
   if (Bot_WalkMove (self.ideal_yaw,SPAWNFLAG_LASER))
   {
      botwalkmove (self.ideal_yaw,(dist - SPAWNFLAG_LASER));
      return ;
   } //end if
   if (Bot_WalkMove ((self.ideal_yaw + 45.000),SPAWNFLAG_LASER))
   {
      movetogoal ((dist - SPAWNFLAG_LASER));
      return ;
   } //end if
   if (Bot_WalkMove ((self.ideal_yaw - 45.000),SPAWNFLAG_LASER))
   {
      movetogoal ((dist - SPAWNFLAG_LASER));
      return ;
   } //end if
   if (trysidestep (dist))
   {
      return ;
   } //end if
   if (Bot_tryjump (270.000,dist,FALSE))
   {
      return ;
   } //end if
   strafemove ((dist * 0.500));
   return ;
}; //end of the function BotmovetoVisiblegoal

// ===== FEELER STEERING: Local Navigation and Movement Polish =====

// Global for returning speed scale from feeler function
float feeler_speed_scale;

// Helper: Clamp value between min and max
float (float x, float lo, float hi) Clamp =
{
   if ((x < lo))
   {
      return (lo);
   } //end if
   if ((x > hi))
   {
      return (hi);
   } //end if
   return (x);
}; //end of the function Clamp

// Helper: Wrap angle delta to [-180, 180]
float (float a, float b) AngleDelta =
{
   local float d;
   d = (a - b);
   while ((d > 180.000))
   {
      d = (d - 360.000);
   } //end while
   while ((d < -180.000))
   {
      d = (d + 360.000);
   } //end while
   return (d);
}; //end of the function AngleDelta

// Dynamic feeler range: longer lookahead when moving fast, shorter when stuck.
float (entity bot, float mode) Bot_FeelerRange =
{
   local float spd;
   local float range;

   spd = vlen (bot.velocity);
   range = (96.000 + (spd * 0.350) - (bot.stuck_score * 24.000));
   if ((mode == BOT_MODE_UNSTICK))
   {
      range = (range * 0.800);
   } //end if
   return (Clamp (range,64.000,256.000));
}; //end of the function Bot_FeelerRange

// Dynamic feeler count: fewer probes when cruising, more when stuck or in combat.
float (entity bot, float mode) Bot_FeelerCandidateCount =
{
   local float count;

   count = 5.000;
   if ((mode == BOT_MODE_COMBAT))
   {
      count = 7.000;
   } //end if
   if ((mode == BOT_MODE_UNSTICK))
   {
      count = 8.000;
   } //end if
   if ((bot.stuck_score > 1.000))
   {
      count = 8.000;
   } //end if
   return (count);
}; //end of the function Bot_FeelerCandidateCount

// Traversal strafe-jumping: build speed on long, clear runs between waypoints.
float (float dist, float base_yaw) Bot_TraversalStrafe =
{
   local vector start;
   local vector end;
   local vector dir;
   local vector trace_angles;
   local float clear_dist;
   local float dist_to_goal;
   local float side;
   local float travel_yaw;
   local vector jumpv;
   local float ledge_penalty;

   if ((self.enemy != world))
   {
      return (FALSE);
   } //end if
   if (self.feeler_mode_active)
   {
      return (FALSE);
   } //end if
   if ((self.skil <= 2.000))
   {
      return (FALSE);
   } //end if
   if ((self.flags & FL_INWATER))
   {
      return (FALSE);
   } //end if
   if (self.elevator_wait_state)
   {
      return (FALSE);
   } //end if
   dist_to_goal = vlen ((self.goalentity.origin - self.origin));
   if ((dist_to_goal < 240.000))
   {
      return (FALSE);
   } //end if

   trace_angles_x = 0.000;
   trace_angles_y = base_yaw;
   trace_angles_z = 0.000;
   makevectors (trace_angles);
   dir = v_forward;
   start = (self.origin + '0.000 0.000 24.000');
   end = (start + (dir * 320.000));
   traceline (start,end,TRUE,self);
   clear_dist = (trace_fraction * 320.000);
   if ((clear_dist < 300.000))
   {
      return (FALSE);
   } //end if

   ledge_penalty = Bot_LedgeRisk (self,(self.origin + (dir * 96.000)),dir);
   if ((ledge_penalty > 0.000))
   {
      return (FALSE);
   } //end if

   side = self.travel_bhop_side;
   if (!side)
   {
      side = 1.000;
   } //end if
   if ((time > self.travel_bhop_flip_time))
   {
      side = (-1.000 * side);
      self.travel_bhop_flip_time = (time + (0.350 + (random () * 0.150)));
   } //end if
   self.travel_bhop_side = side;

   travel_yaw = (base_yaw + (side * 12.000));
   self.ideal_yaw = travel_yaw;

   if ((self.flags & FL_ONGROUND))
   {
      if ((time > self.travel_bhop_jump_time))
      {
         trace_angles_x = 0.000;
         trace_angles_y = travel_yaw;
         trace_angles_z = 0.000;
         makevectors (trace_angles);
         jumpv = (v_forward * BOTSPEED);
         jumpv_z = 270.000;
         Botjump (jumpv);
         self.travel_bhop_jump_time = (time + 0.400);
         return (TRUE);
      } //end if
      if (Bot_WalkMove ((base_yaw + (side * 25.000)),dist))
      {
         return (TRUE);
      } //end if
      return (FALSE);
   } //end if
   return (TRUE);
}; //end of the function Bot_TraversalStrafe

// FEELER STEERING: 5-trace corridor centring and cornering
// Returns yaw bias (degrees to adjust heading)
// Sets global feeler_speed_scale (0.0-1.0)
// [VERTICAL AWARENESS] Helper: Check if a point is over safe ground
// Returns: 1.0 if safe, < 1.0 if hazard/void
float (vector p, entity bot) Bot_CheckFloorQuality =
{
   local vector down;
   local float depth;

   down = p;
   down_z = (down_z - 256.000);  // Look down 256 units

   traceline (p,down,TRUE,bot);

   // 1. VOID CHECK: If we hit nothing, it's a deep pit
   if ((trace_fraction == 1.000))
   {
      return (0.000);
   } //end if

   // 2. HAZARD CHECK: If we hit lava/slime, it's a death trap
   if ((pointcontents (trace_endpos) <= CONTENT_SLIME))
   {
      return (0.000);
   } //end if

   // 3. DEPTH CHECK: Slight penalty for big drops, but DON'T block them
   // Flow and aggression > minor fall damage. Being stuck = predictable = dead.
   depth = (p_z - trace_endpos_z);
   if ((depth > 64.000))
   {
      return (0.800);  // Slight penalty, but freely passable
   } //end if

   return (1.000);  // Safe ground
}; //end of the function Bot_CheckFloorQuality

// [VERTICAL AWARENESS] Enhanced Feeler Steering with Cliff Detection
// Now treats cliffs/voids as walls in the steering system (prediction vs reaction)
float (entity bot, float base_yaw, float dt) Bot_SampleFeelers =
{
   local vector start;
   local vector fwd;
   local vector right;
   local float f;
   local float fl;
   local float fr;
   local float l;
   local float r;
   local float f_qual;
   local float fl_qual;
   local float fr_qual;
   local float l_qual;
   local float r_qual;
   local float bias;
   local float yaw_bias;
   local float range;
   local float diag_len;
   local float diag_side;
   local float side_len;
   local vector trace_angles;

   yaw_bias = 0.000;
   feeler_speed_scale = 1.000;

   // Trace origin: waist height reads walls reliably
   start = (bot.origin + '0.000 0.000 24.000');

   range = Bot_FeelerRange (bot,BOT_MODE_NORMAL);
   diag_len = (range * 0.780);
   diag_side = (diag_len * 0.500);
   side_len = (range * 0.300);

   // Use base_yaw as reference direction (goal heading), not current yaw
   trace_angles_x = 0.000;
   trace_angles_y = base_yaw;
   trace_angles_z = 0.000;
   makevectors (trace_angles);

   fwd = v_forward;
   right = v_right;

   // --- TRACE 1: Forward ---
   traceline (start,(start + (fwd * range)),TRUE,bot);
   f = trace_fraction;
   // If wall is clear, check floor
   if ((f == 1.000))
   {
      f_qual = Bot_CheckFloorQuality (trace_endpos,bot);
   } //end if
   else
   {
      f_qual = 1.000;  // Wall collision handles itself
   } //end else

   // --- TRACE 2: Forward-Left ---
   traceline (start,(start + ((fwd * diag_len) + (right * -diag_side))),TRUE,bot);
   fl = trace_fraction;
   if ((fl == 1.000))
   {
      fl_qual = Bot_CheckFloorQuality (trace_endpos,bot);
   } //end if
   else
   {
      fl_qual = 1.000;
   } //end else

   // --- TRACE 3: Forward-Right ---
   traceline (start,(start + ((fwd * diag_len) + (right * diag_side))),TRUE,bot);
   fr = trace_fraction;
   if ((fr == 1.000))
   {
      fr_qual = Bot_CheckFloorQuality (trace_endpos,bot);
   } //end if
   else
   {
      fr_qual = 1.000;
   } //end else

   // --- TRACE 4: Left (Side) ---
   traceline (start,(start + (right * -side_len)),TRUE,bot);
   l = trace_fraction;
   if ((l == 1.000))
   {
      l_qual = Bot_CheckFloorQuality (trace_endpos,bot);
   } //end if
   else
   {
      l_qual = 1.000;
   } //end else

   // --- TRACE 5: Right (Side) ---
   traceline (start,(start + (right * side_len)),TRUE,bot);
   r = trace_fraction;
   if ((r == 1.000))
   {
      r_qual = Bot_CheckFloorQuality (trace_endpos,bot);
   } //end if
   else
   {
      r_qual = 1.000;
   } //end else

   // --- CALCULATE BIAS ---
   // We combine Wall Fraction with Floor Quality.
   // Effective score = trace_fraction * floor_quality
   // If floor is bad (0.0), effective score becomes 0.0 (blocked).

   bias = 0.000;

   // Corridor / Ledge Centering
   // If Left is void (l_qual=0) and Right is safe (r_qual=1), we steer Right.
   bias = (bias + (((l * l_qual) - (r * r_qual)) * 22.000));

   // Cornering / Cliff Avoidance
   bias = (bias + (((fl * fl_qual) - (fr * fr_qual)) * 28.000));

   // Imminent Collision / Cliff Edge
   // If forward is blocked by wall OR void
   if (((f * f_qual) < 0.550))
   {
      // Pick the safer diagonal
      if (((fl * fl_qual) < (fr * fr_qual)))
      {
         bias = (bias + 35.000);
      } //end if
      else
      {
         bias = (bias - 35.000);
      } //end else
      feeler_speed_scale = 0.600;  // Slow down
   } //end if

   // Clamp raw bias so it cannot dominate intent
   yaw_bias = Clamp (bias,-45.000,45.000);

   // Smooth turn: cap degrees per tick (anti-robotic)
   local float max_turn;
   max_turn = (120.000 * dt);  // 120 deg/sec
   yaw_bias = Clamp (yaw_bias,(-1.000 * max_turn),max_turn);

   return (yaw_bias);
}; //end of the function Bot_SampleFeelers

void (entity bot) Bot_UpdateRecentPositions =
{
   if ((bot.recent_pos_idx == 0.000))
   {
      bot.recent_pos0 = bot.origin;
   } //end if
   else
   {
      if ((bot.recent_pos_idx == 1.000))
      {
         bot.recent_pos1 = bot.origin;
      } //end if
      else
      {
         if ((bot.recent_pos_idx == 2.000))
         {
            bot.recent_pos2 = bot.origin;
         } //end if
         else
         {
            if ((bot.recent_pos_idx == 3.000))
            {
               bot.recent_pos3 = bot.origin;
            } //end if
            else
            {
               if ((bot.recent_pos_idx == 4.000))
               {
                  bot.recent_pos4 = bot.origin;
               } //end if
               else
               {
                  bot.recent_pos5 = bot.origin;
               } //end if
            } //end else
         } //end else
      } //end else
   } //end else

   bot.recent_pos_idx = (bot.recent_pos_idx + 1.000);
   if ((bot.recent_pos_idx > 5.000))
   {
      bot.recent_pos_idx = 0.000;
   } //end if
}; //end of the function Bot_UpdateRecentPositions

float (entity bot, vector pos) Bot_IsRecentlyVisited =
{
   if ((vlen (bot.recent_pos0) > 0.000))
   {
      if ((vlen (pos - bot.recent_pos0) < 72.000)) return (TRUE);
   } //end if
   if ((vlen (bot.recent_pos1) > 0.000))
   {
      if ((vlen (pos - bot.recent_pos1) < 72.000)) return (TRUE);
   } //end if
   if ((vlen (bot.recent_pos2) > 0.000))
   {
      if ((vlen (pos - bot.recent_pos2) < 72.000)) return (TRUE);
   } //end if
   if ((vlen (bot.recent_pos3) > 0.000))
   {
      if ((vlen (pos - bot.recent_pos3) < 72.000)) return (TRUE);
   } //end if
   if ((vlen (bot.recent_pos4) > 0.000))
   {
      if ((vlen (pos - bot.recent_pos4) < 72.000)) return (TRUE);
   } //end if
   if ((vlen (bot.recent_pos5) > 0.000))
   {
      if ((vlen (pos - bot.recent_pos5) < 72.000)) return (TRUE);
   } //end if
   return (FALSE);
}; //end of the function Bot_IsRecentlyVisited

// Directional fail memory: Coarse position quantization (32-unit grid)
vector (vector p) CoarsePos =
{
   local vector cp;

   cp_x = (floor (p_x / 32.000) * 32.000);
   cp_y = (floor (p_y / 32.000) * 32.000);
   cp_z = (floor (p_z / 32.000) * 32.000);
   return (cp);
}; //end of the function CoarsePos

// Directional fail memory: Record failed approach (position + yaw bucket)
void (entity bot, vector dir) RecordDirectionalFail =
{
   local vector cp;
   local float yaw;
   local float expire;

   local float dy;
   local float near;

   cp = CoarsePos (bot.origin);
   yaw = vectoyaw (dir);
   while ((yaw < 0.000))
   {
      yaw = (yaw + 360.000);
   } //end while
   while ((yaw >= 360.000))
   {
      yaw = (yaw - 360.000);
   } //end while
   expire = (time + 20.000);  // 20 second TTL - matches goal avoidance duration

   // Check for duplicates - don't waste buffer slots
   if ((bot.fail_until0 > time))
   {
      near = (vlen (cp - bot.fail_pos0) < 96.000);
      dy = fabs (yaw - bot.fail_yaw0);
      if ((dy > 180.000)) dy = (360.000 - dy);
      if ((near && (dy < 30.000))) return;
   } //end if
   if ((bot.fail_until1 > time))
   {
      near = (vlen (cp - bot.fail_pos1) < 96.000);
      dy = fabs (yaw - bot.fail_yaw1);
      if ((dy > 180.000)) dy = (360.000 - dy);
      if ((near && (dy < 30.000))) return;
   } //end if
   if ((bot.fail_until2 > time))
   {
      near = (vlen (cp - bot.fail_pos2) < 96.000);
      dy = fabs (yaw - bot.fail_yaw2);
      if ((dy > 180.000)) dy = (360.000 - dy);
      if ((near && (dy < 30.000))) return;
   } //end if
   if ((bot.fail_until3 > time))
   {
      near = (vlen (cp - bot.fail_pos3) < 96.000);
      dy = fabs (yaw - bot.fail_yaw3);
      if ((dy > 180.000)) dy = (360.000 - dy);
      if ((near && (dy < 30.000))) return;
   } //end if
   if ((bot.fail_until4 > time))
   {
      near = (vlen (cp - bot.fail_pos4) < 96.000);
      dy = fabs (yaw - bot.fail_yaw4);
      if ((dy > 180.000)) dy = (360.000 - dy);
      if ((near && (dy < 30.000))) return;
   } //end if
   if ((bot.fail_until5 > time))
   {
      near = (vlen (cp - bot.fail_pos5) < 96.000);
      dy = fabs (yaw - bot.fail_yaw5);
      if ((dy > 180.000)) dy = (360.000 - dy);
      if ((near && (dy < 30.000))) return;
   } //end if

   if ((bot_debug_enabled && (bot_debug_level >= LOG_VERBOSE)))
   {
      bprint ("[");
      bprint (bot.netname);
      bprint ("] FAIL-MEM: Record yaw=");
      bprint (ftos (yaw));
      bprint ("° at (");
      bprint (ftos (cp_x));
      bprint (",");
      bprint (ftos (cp_y));
      bprint (")\n");
   } //end if

   bot.fail_head = (bot.fail_head + 1.000);
   if ((bot.fail_head > 5.000))
   {
      bot.fail_head = 0.000;
   } //end if

   if ((bot.fail_head == 0.000))
   {
      bot.fail_pos0 = cp;
      bot.fail_yaw0 = yaw;
      bot.fail_until0 = expire;
   } //end if
   if ((bot.fail_head == 1.000))
   {
      bot.fail_pos1 = cp;
      bot.fail_yaw1 = yaw;
      bot.fail_until1 = expire;
   } //end if
   if ((bot.fail_head == 2.000))
   {
      bot.fail_pos2 = cp;
      bot.fail_yaw2 = yaw;
      bot.fail_until2 = expire;
   } //end if
   if ((bot.fail_head == 3.000))
   {
      bot.fail_pos3 = cp;
      bot.fail_yaw3 = yaw;
      bot.fail_until3 = expire;
   } //end if
   if ((bot.fail_head == 4.000))
   {
      bot.fail_pos4 = cp;
      bot.fail_yaw4 = yaw;
      bot.fail_until4 = expire;
   } //end if
   if ((bot.fail_head == 5.000))
   {
      bot.fail_pos5 = cp;
      bot.fail_yaw5 = yaw;
      bot.fail_until5 = expire;
   } //end if
}; //end of the function RecordDirectionalFail

// Directional fail memory: Get penalty for approaching from this direction
float (entity bot, vector dir) GetDirectionalPenalty =
{
   local vector cp;
   local float yaw;
   local float dy;
   local float penalty;
   local float near;

   cp = CoarsePos (bot.origin);
   yaw = vectoyaw (dir);
   while ((yaw < 0.000))
   {
      yaw = (yaw + 360.000);
   } //end while
   while ((yaw >= 360.000))
   {
      yaw = (yaw - 360.000);
   } //end while

   penalty = 0.000;

   // Check all 6 fail entries
   if ((bot.fail_until0 > time))
   {
      near = (vlen (cp - bot.fail_pos0) < 96.000);
      dy = fabs (yaw - bot.fail_yaw0);
      if ((dy > 180.000))
      {
         dy = (360.000 - dy);
      } //end if
      if ((near && (dy < 30.000)))
      {
         penalty = 500.000;
      } //end if
   } //end if
   if ((bot.fail_until1 > time))
   {
      near = (vlen (cp - bot.fail_pos1) < 96.000);
      dy = fabs (yaw - bot.fail_yaw1);
      if ((dy > 180.000))
      {
         dy = (360.000 - dy);
      } //end if
      if ((near && (dy < 30.000)))
      {
         penalty = 500.000;
      } //end if
   } //end if
   if ((bot.fail_until2 > time))
   {
      near = (vlen (cp - bot.fail_pos2) < 96.000);
      dy = fabs (yaw - bot.fail_yaw2);
      if ((dy > 180.000))
      {
         dy = (360.000 - dy);
      } //end if
      if ((near && (dy < 30.000)))
      {
         penalty = 500.000;
      } //end if
   } //end if
   if ((bot.fail_until3 > time))
   {
      near = (vlen (cp - bot.fail_pos3) < 96.000);
      dy = fabs (yaw - bot.fail_yaw3);
      if ((dy > 180.000))
      {
         dy = (360.000 - dy);
      } //end if
      if ((near && (dy < 30.000)))
      {
         penalty = 500.000;
      } //end if
   } //end if
   if ((bot.fail_until4 > time))
   {
      near = (vlen (cp - bot.fail_pos4) < 96.000);
      dy = fabs (yaw - bot.fail_yaw4);
      if ((dy > 180.000))
      {
         dy = (360.000 - dy);
      } //end if
      if ((near && (dy < 30.000)))
      {
         penalty = 500.000;
      } //end if
   } //end if
   if ((bot.fail_until5 > time))
   {
      near = (vlen (cp - bot.fail_pos5) < 96.000);
      dy = fabs (yaw - bot.fail_yaw5);
      if ((dy > 180.000))
      {
         dy = (360.000 - dy);
      } //end if
      if ((near && (dy < 30.000)))
      {
         penalty = 500.000;
      } //end if
   } //end if

   if ((penalty > 0.000))
   {
      if ((bot_debug_enabled && (bot_debug_level >= LOG_VERBOSE)))
      {
         bprint ("[");
         bprint (bot.netname);
         bprint ("] FAIL-MEM: Penalty -");
         bprint (ftos (penalty));
         bprint (" for yaw=");
         bprint (ftos (yaw));
         bprint ("°\n");
      } //end if
   } //end if

   return (penalty);
}; //end of the function GetDirectionalPenalty

// ===== SHALLOW WATER TRAP ESCAPE =====
// Detects and escapes "ankle water" boundary oscillation traps.
// In Quake, shallow water areas (waterlevel == 1) with recessed lips cause bots
// to get stuck bouncing at the boundary, unable to step out cleanly.

// Sample ground height at a point using downward trace
float (entity bot, vector p) SampleGroundHeight =
{
   local vector start;
   local vector end;

   start = (p + '0.000 0.000 48.000');
   end = (p - '0.000 0.000 256.000');

   traceline (start,end,TRUE,bot);
   if ((trace_fraction == 1.000))
   {
      return (-99999.000);  // No ground found
   } //end if

   return (trace_endpos_z);
}; //end of the function SampleGroundHeight

// Pick best water escape direction using "highest ground" gradient heuristic
// Samples 7 directions, prefers higher ground (step out) with directional fail memory
vector (entity bot) PickWaterEscapeDir =
{
   local float angles[7];
   local float i;
   local float best_score;
   local float score;
   local vector best_dir;
   local vector dir;
   local vector sample_point;
   local float range;
   local float clear;
   local float h;
   local float mem_penalty;
   local vector start;
   local vector end;
   local vector trace_angles;

   // 7-ray pattern: center + symmetric spread
   angles[0] = 0.000;
   angles[1] = -25.000;
   angles[2] = 25.000;
   angles[3] = -60.000;
   angles[4] = 60.000;
   angles[5] = -90.000;
   angles[6] = 90.000;

   range = 160.000;  // Medium probe distance
   best_score = -99999.000;

   // Default to forward if all else fails
   trace_angles_x = 0.000;
   trace_angles_y = bot.ideal_yaw;
   trace_angles_z = 0.000;
   makevectors (trace_angles);
   best_dir = v_forward;

   i = 0.000;
   while ((i < 7.000))
   {
      // Calculate direction vector
      trace_angles_x = 0.000;
      trace_angles_y = (bot.ideal_yaw + angles[i]);
      trace_angles_z = 0.000;
      makevectors (trace_angles);
      dir = v_forward;

      // Check clearance in this direction
      start = (bot.origin + '0.000 0.000 22.000');
      end = (start + (dir * range));
      traceline (start,end,TRUE,bot);
      clear = trace_fraction;

      // Skip if heavily blocked
      if ((clear < 0.600))
      {
         i = (i + 1.000);
         continue;
      } //end if

      // Sample point at traced distance
      sample_point = (bot.origin + (dir * (range * clear)));

      // Get ground height (prefer higher = step out)
      h = SampleGroundHeight (bot,sample_point);

      // Check directional fail memory
      mem_penalty = GetDirectionalPenalty (bot,dir);

      // Score: height (scaled down) + clearance - fail memory
      score = ((h * 0.010) + clear - (mem_penalty * 0.001600));

      if ((score > best_score))
      {
         best_score = score;
         best_dir = dir;
      } //end if

      i = (i + 1.000);
   } //end while

   if ((bot_debug_enabled && (bot_debug_level >= LOG_VERBOSE)))
   {
      bprint ("[");
      bprint (bot.netname);
      bprint ("] WATER-ESCAPE: Best direction yaw=");
      bprint (ftos (vectoyaw (best_dir)));
      bprint ("° score=");
      bprint (ftos (best_score));
      bprint ("\n");
   } //end if

   return (best_dir);
}; //end of the function PickWaterEscapeDir

// Detect shallow water trap condition
float (entity bot) IsShallowWaterTrap =
{
   // Must be in ankle water
   if ((bot.waterlevel != 1.000))
   {
      return (FALSE);
   } //end if

   // Must be making no progress for 1.8 seconds
   if (((time - bot.last_progress_time) > 1.800))
   {
      return (TRUE);
   } //end if

   return (FALSE);
}; //end of the function IsShallowWaterTrap

// Main handler: triggers escape behavior and sets commit window
void (entity bot) HandleWaterTrap =
{
   local vector escape;

   if (!IsShallowWaterTrap (bot))
   {
      return ;
   } //end if

   if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
   {
      bprint ("[");
      bprint (bot.netname);
      bprint ("] WATER-TRAP: Detected at ");
      bprint (vtos (bot.origin));
      bprint (" (waterlevel=");
      bprint (ftos (bot.waterlevel));
      bprint (", no progress for ");
      bprint (ftos (time - bot.last_progress_time));
      bprint ("s)\n");
   } //end if

   // Break any existing commit so we can choose new escape line
   bot.feeler_commit_until = 0.000;

   // Pick escape direction using highest ground heuristic
   escape = PickWaterEscapeDir (bot);

   // Record this attempt in directional fail memory
   RecordDirectionalFail (bot,escape);

   // Commit hard for 1.2 seconds to avoid boundary jitter
   bot.feeler_commit_dir = escape;
   bot.feeler_commit_until = (time + 1.200);

   if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
   {
      bprint ("[");
      bprint (bot.netname);
      bprint ("] WATER-TRAP: Escape commit yaw=");
      bprint (ftos (vectoyaw (escape)));
      bprint ("° until t=");
      bprint (ftos (bot.feeler_commit_until));
      bprint ("\n");
   } //end if
}; //end of the function HandleWaterTrap

// ===== END SHALLOW WATER TRAP ESCAPE =====

// ===== FLOW GOVERNOR: Priority-Based Arbitration =====
// Prevents competing control loops by arbitrating who controls movement.
// Each subsystem "requests control" with a priority and a short commit window.
// Only one driver owns the bot's movement goal at a time (highest priority wins).
//
// Drivers (priority, highest wins):
//   100 - Terrain trap resolver (water, lips, micro-basins, greebles)
//    90 - Loop breaker (behavioral loops)
//    80 - Vertical reposition (no LOS + big dz, prevents vertical stalemates)
//    60 - Intent director (fight, chase, resupply, explore, unstick)
//    40 - Route memory (anchor pull from waypoints)
//    20 - Default roam (fallback)
//
// TraceFlow always does the steering, but it steers toward the Governor's goal.

// Release expired control and reset governor state
void (entity bot) FG_Tick =
{
   if ((time >= bot.fg_until))
   {
      bot.fg_pri = 0.000;
      bot.fg_driver = FG_DRV_NONE;
      bot.fg_goalDir = '0.000 0.000 0.000';
   } //end if
}; //end of the function FG_Tick

// Request control with a priority and a short commit window.
// Higher priority overrides lower; equal priority does not churn while committed.
void (entity bot, float pri, float drv, vector goalDir, float secs) FG_Request =
{
   local vector flat_dir;

   // Flatten goal direction (ignore vertical component)
   flat_dir = goalDir;
   flat_dir_z = 0.000;
   if ((vlen (flat_dir) > 0.010))
   {
      flat_dir = normalize (flat_dir);
   } //end if
   else
   {
      flat_dir = '1.000 0.000 0.000';
   } //end else

   // If current driver is committed and higher priority, deny request
   if (((time < bot.fg_until) && (bot.fg_pri > pri)))
   {
      return ;
   } //end if

   // If equal priority and still committed, deny (prevents churn)
   // Allow the same driver to refresh its request without losing control.
   if (((time < bot.fg_until) && (bot.fg_pri == pri) && (bot.fg_driver != drv)))
   {
      return ;
   } //end if

   // Grant control to this driver
   bot.fg_pri = pri;
   bot.fg_driver = drv;
   bot.fg_goalDir = flat_dir;
   bot.fg_until = (time + secs);

   // Break steering commit so the new driver takes effect immediately
   bot.feeler_commit_until = 0.000;

   if ((bot_debug_enabled && (bot_debug_level >= LOG_VERBOSE)))
   {
      bprint ("[");
      bprint (bot.netname);
      bprint ("] FG: Driver ");
      bprint (ftos (drv));
      bprint (" took control (pri=");
      bprint (ftos (pri));
      bprint (", until t=");
      bprint (ftos (bot.fg_until));
      bprint (")\n");
   } //end if
}; //end of the function FG_Request

// ===== END FLOW GOVERNOR CORE =====

// ===== GENERAL TERRAIN TRAP RESOLVER =====
// Handles movement pathologies that break all three layers (waypoints, intent, steering):
// - Shallow water (waterlevel 1)
// - Recessed lips/step-ups
// - Micro-basins and greebles
// - Any "moving but not progressing" trap
//
// This is a FAILSAFE LAYER that temporarily overrides intent and navigation.

// Detect terrain trap condition (generalized beyond just water)
float (entity bot) Bot_IsTerrainTrap =
{
   // No progress check: Must have been stuck for a bit
   if ((time - bot.last_progress_time) < 1.500)
   {
      return (FALSE);
   } //end if

   // Shallow water trap (DM2 ankle water)
   if ((bot.waterlevel == 1.000))
   {
      return (TRUE);
   } //end if

   // General micro-trap heuristic: moving (velocity > 40) but not making progress (stuck_score > 1)
   // Catches lips, greebles, micro-basins, and other geometry pathologies
   if (((vlen (bot.velocity) > 40.000) && (bot.stuck_score > 1.000)))
   {
      return (TRUE);
   } //end if

   return (FALSE);
}; //end of the function Bot_IsTerrainTrap

// Pick escape direction using exit gradient (height + openness + memory)
// Reuses SampleGroundHeight and GetDirectionalPenalty from water trap code
vector (entity bot) Bot_PickTerrainEscape =
{
   local float angles[7];
   local float i;
   local float best_score;
   local float score;
   local vector best_dir;
   local vector dir;
   local vector probe;
   local float clear;
   local float height;
   local float mem_penalty;
   local vector start;
   local vector end;
   local float range;
   local float drop;
   local vector trace_angles;

   // 7-ray pattern: center + symmetric spread
   angles[0] = 0.000;
   angles[1] = -30.000;
   angles[2] = 30.000;
   angles[3] = -60.000;
   angles[4] = 60.000;
   angles[5] = -90.000;
   angles[6] = 90.000;

   range = 160.000;  // Probe distance
   best_score = -99999.000;

   // Default to forward if all else fails
   trace_angles_x = 0.000;
   trace_angles_y = bot.ideal_yaw;
   trace_angles_z = 0.000;
   makevectors (trace_angles);
   best_dir = v_forward;

   i = 0.000;
   while ((i < 7.000))
   {
      // Calculate direction vector
      trace_angles_x = 0.000;
      trace_angles_y = (bot.ideal_yaw + angles[i]);
      trace_angles_z = 0.000;
      makevectors (trace_angles);
      dir = v_forward;

      // Check clearance in this direction (swept trace)
      start = (bot.origin + '0.000 0.000 22.000');
      end = (start + (dir * range));
      traceline (start,end,TRUE,bot);
      clear = trace_fraction;

      // Skip if heavily blocked (need at least 60% clearance)
      if ((clear < 0.600))
      {
         i = (i + 1.000);
         continue;
      } //end if

      // Sample point at traced distance
      probe = (bot.origin + (dir * (range * clear)));

      // Get ground height (prefer higher = climbing out of trap)
      height = SampleGroundHeight (bot,probe);

      // Check directional fail memory
      mem_penalty = GetDirectionalPenalty (bot,dir);

      // Score formula:
      //   clear         = openness (0.6-1.0)
      //   height * 0.01 = prefer higher ground (scaled down)
      //   mem * -1.2    = avoid previously failed directions
      score = (clear + (height * 0.010) - (mem_penalty * 1.200));
      if ((height < -90000.000))
      {
         i = (i + 1.000);
         continue;
      } //end if
      drop = (bot.origin_z - height);
      if ((drop > 64.000))
      {
         i = (i + 1.000);
         continue;
      } //end if
      if ((drop > 24.000))
      {
         score = (score - ((drop - 24.000) * 0.030));
      } //end if

      if ((score > best_score))
      {
         best_score = score;
         best_dir = dir;
      } //end if

      i = (i + 1.000);
   } //end while

   if ((bot_debug_enabled && (bot_debug_level >= LOG_VERBOSE)))
   {
      bprint ("[");
      bprint (bot.netname);
      bprint ("] TERRAIN-TRAP: Best escape yaw=");
      bprint (ftos (vectoyaw (best_dir)));
      bprint ("° score=");
      bprint (ftos (best_score));
      bprint ("\n");
   } //end if

   return (best_dir);
}; //end of the function Bot_PickTerrainEscape

// Main terrain trap handler: hard override with commit window
void (entity bot) Bot_HandleTerrainTrap =
{
   local vector escape;

   if (!Bot_IsTerrainTrap (bot))
   {
      return ;
   } //end if
   if (bot.is_retracing)
   {
      return ;
   } //end if
   if (((bot.stuck_mode == BOT_MODE_UNSTICK) && (time < bot.escape_until_time)))
   {
      return ;
   } //end if
   if ((bot.stuck_mode == BOT_MODE_COOLDOWN))
   {
      return ;
   } //end if
   if ((time < bot.escape_cooldown_time))
   {
      return ;
   } //end if
   if (((bot.fg_driver == FG_DRV_TERRAIN) && (time < bot.fg_until)))
   {
      return ;
   } //end if

   if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
   {
      bprint ("[");
      bprint (bot.netname);
      bprint ("] TERRAIN-TRAP: Detected at ");
      bprint (vtos (bot.origin));
      bprint (" (waterlevel=");
      bprint (ftos (bot.waterlevel));
      bprint (", velocity=");
      bprint (ftos (vlen (bot.velocity)));
      bprint (", stuck_score=");
      bprint (ftos (bot.stuck_score));
      bprint (", no progress for ");
      bprint (ftos (time - bot.last_progress_time));
      bprint ("s)\n");
   } //end if

   // Pick escape direction using exit gradient
   escape = Bot_PickTerrainEscape (bot);

   // Record this attempt in directional fail memory
   RecordDirectionalFail (bot,escape);

   // Mark this spot as hazardous and reset progress so we don't thrash here.
   bot.bad_spot_origin = bot.origin;
   bot.bad_spot_radius = 256.000;
   bot.bad_spot_expire_time = (time + 15.000);
   bot.stuck_score = 0.000;
   bot.last_progress_time = time;
   bot.last_origin = bot.origin;
   bot.progress_check_time = (time + STUCK_PROGRESS_INTERVAL);

   // Request control from Flow Governor (priority 100 - highest)
   // Governor handles commit window and breaks conflicting commits
   FG_Request (bot,100.000,FG_DRV_TERRAIN,escape,1.200);

   // Force a bounded unstick window with a stable escape direction
   if ((bot.stuck_mode != BOT_MODE_UNSTICK))
   {
      Bot_EnterUnstick (R_UNSTICK_TERRAIN,"terrain trap");
   } //end if
   bot.escape_until_time = (time + 1.200);
   bot.is_retracing = FALSE;
   bot.escape_dir = escape;
   bot.last_escape_dir = escape;
   bot.best_dir = escape;
   bot.best_ideal_yaw = vectoyaw (escape);
   bot.best_forward_scale = 1.000;
   bot.best_strafe_bias = 0.000;
   bot.best_wants_jump = FALSE;
   bot.best_blocked = FALSE;
   bot.best_step_ok = FALSE;
   bot.feeler_commit_dir = escape;
   bot.feeler_commit_until = bot.escape_until_time;

   if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
   {
      bprint ("[");
      bprint (bot.netname);
      bprint ("] TERRAIN-TRAP: Escape commit yaw=");
      bprint (ftos (vectoyaw (escape)));
      bprint ("° until t=");
      bprint (ftos (bot.escape_until_time));
      bprint ("\n");
   } //end if
}; //end of the function Bot_HandleTerrainTrap

// ===== END GENERAL TERRAIN TRAP RESOLVER =====

// ===== INTENT ESCALATION: Prevents Stuck-in-Valid-Behavior =====
// Stops bots from infinite loops in "correct" behaviors that don't produce results.
// Examples: endless chasing (lost enemy), resupply loops (can't reach items),
// vertical stalemates (fight with no LOS), explore wandering (no pickups).
//
// Each intent has success signals and timeouts. If intent fails for too long,
// escalate to next-best intent and commit briefly.

void (entity bot, float mode, float style, float pri, float commit_secs, entity target, vector org, float speed) Bot_RequestMove =
{
   local entity oldself;

   if (!bot)
   {
      return ;
   } //end if
   if ((bot.frame_begin_time != time))
   {
      oldself = self;
      self = bot;
      Bot_FrameBegin ();
      self = oldself;
   } //end if
   if (bot.move_apply_active)
   {
      if (bot.move_req_pending_set)
      {
         if ((pri < bot.move_req_pending_pri))
         {
            return ;
         } //end if
         if ((pri == bot.move_req_pending_pri))
         {
            if ((mode != bot.move_req_pending_mode))
            {
               return ;
            } //end if
         } //end if
      } //end if
      bot.move_req_pending_set = TRUE;
      bot.move_req_pending_mode = mode;
      bot.move_req_pending_style = style;
      bot.move_req_pending_pri = pri;
      bot.move_req_pending_commit_secs = commit_secs;
      bot.move_req_pending_target = target;
      bot.move_req_pending_org = org;
      bot.move_req_pending_speed = speed;
      return ;
   } //end if

   if ((pri < bot.move_req_pri))
   {
      return ;
   } //end if
   if ((pri == bot.move_req_pri))
   {
      if ((mode != bot.move_req_mode))
      {
         return ;
      } //end if
   } //end if

   bot.move_req_mode = mode;
   bot.move_req_style = style;
   bot.move_req_pri = pri;
   bot.move_req_commit_secs = commit_secs;
   bot.move_req_target = target;
   bot.move_req_org = org;
   bot.move_req_speed = speed;
}; //end of the function Bot_RequestMove

void (float mode, float dist) Bot_RequestMoveMode =
{
   local float style;
   local entity targ;
   local vector org;

   if ((self.frame_begin_time != time))
   {
      Bot_FrameBegin ();
   } //end if

   style = BOT_MOVE_STYLE_ADVANCE;
   targ = self.goalentity;
   org = self.origin;
   if (targ)
   {
      org = targ.origin;
   } //end if

   if ((mode == BOT_MOVE_STAND))
   {
      style = BOT_MOVE_STYLE_HOLD;
      targ = world;
      org = self.origin;
   } //end if
   else if (((mode == BOT_MOVE_CHARGE) || (mode == BOT_MOVE_NAILCHARGE)))
   {
      style = BOT_MOVE_STYLE_STRAFE;
      targ = self.enemy;
      if (targ)
      {
         org = targ.origin;
      } //end if
   } //end if
   else if (((mode == BOT_MOVE_CHASE) || (mode == BOT_MOVE_RUN)))
   {
      targ = self.enemy;
      if (targ)
      {
         org = targ.origin;
      } //end if
   } //end if

   Bot_RequestMove (self,mode,style,50.000,0.200,targ,org,dist);
}; //end of the function Bot_RequestMoveMode

void (entity bot, float intent, float pri, float commit_secs, float reason_code, string reason) Bot_RequestIntent =
{
   local entity oldself;

   if (!bot)
   {
      return ;
   } //end if
   if ((bot.frame_begin_time != time))
   {
      oldself = self;
      self = bot;
      Bot_FrameBegin ();
      self = oldself;
   } //end if
   if (bot.move_apply_active)
   {
      if (bot.intent_req_pending_set)
      {
         if ((pri < bot.intent_req_pending_pri))
         {
            return ;
         } //end if
         if ((pri == bot.intent_req_pending_pri))
         {
            if ((intent != bot.intent_req_pending))
            {
               return ;
            } //end if
         } //end if
      } //end if
      bot.intent_req_pending_set = TRUE;
      bot.intent_req_pending = intent;
      bot.intent_req_pending_pri = pri;
      bot.intent_req_pending_commit_secs = commit_secs;
      bot.intent_req_pending_reason = reason;
      bot.intent_req_pending_reason_code = reason_code;
      return ;
   } //end if

   if ((pri < bot.intent_req_pri))
   {
      return ;
   } //end if
   if ((pri == bot.intent_req_pri))
   {
      if ((intent != bot.intent_req))
      {
         return ;
      } //end if
   } //end if

   bot.intent_req = intent;
   bot.intent_req_pri = pri;
   bot.intent_req_commit_secs = commit_secs;
   bot.intent_req_reason = reason;
   bot.intent_req_reason_code = reason_code;
}; //end of the function Bot_RequestIntent

float (entity bot) Bot_EffectiveIntent =
{
   local float intent;
   local float req_intent;

   if (!bot)
   {
      return (BOT_INTENT_EXPLORE);
   } //end if

   intent = bot.bot_intent;
   req_intent = bot.intent_req;
   if (req_intent)
   {
      if ((time < bot.intent_request_until))
      {
         if ((bot.intent_req_pri < bot.intent_request_pri))
         {
            req_intent = 0.000;
         } //end if
         else if ((bot.intent_req_pri == bot.intent_request_pri))
         {
            if ((bot.intent_req != bot.intent_request))
            {
               req_intent = 0.000;
            } //end if
         } //end if
      } //end if
   } //end if

   if (req_intent)
   {
      intent = req_intent;
   } //end if
   else if ((time < bot.intent_request_until))
   {
      intent = bot.intent_request;
   } //end if

   return (intent);
}; //end of the function Bot_EffectiveIntent

float (float intent) Bot_IntentMinCommit =
{
   if ((intent == BOT_INTENT_FIGHT))
   {
      return (0.750);
   } //end if
   if ((intent == BOT_INTENT_CHASE))
   {
      return (0.750);
   } //end if
   if ((intent == BOT_INTENT_RESUPPLY))
   {
      return (1.000);
   } //end if
   if ((intent == BOT_INTENT_EXPLORE))
   {
      return (1.250);
   } //end if
   if ((intent == BOT_INTENT_UNSTICK))
   {
      return (0.500);
   } //end if
   if ((intent == BOT_INTENT_HOLD))
   {
      return (0.500);
   } //end if
   return (0.750);
}; //end of the function Bot_IntentMinCommit

void () Bot_UpdateIntentDecision =
{
   local float prev_intent;
   local float candidate_intent;

   if ((time < self.bot_intent_next_update))
   {
      return ;
   } //end if
   self.bot_intent_next_update = (time + (1.000 / BOT_INTENT_UPDATE_HZ));

   if ((self.stuck_mode == BOT_MODE_UNSTICK))
   {
      self.bot_intent = BOT_INTENT_UNSTICK;
      self.bot_intent_start = time;
      self.bot_intent_fail = 0.000;
      return ;
   } //end if

   prev_intent = self.bot_intent;
   candidate_intent = Bot_EffectiveIntent (self);

   if (candidate_intent)
   {
      self.bot_intent = candidate_intent;
   } //end if
   else if ((self.enemy && (self.enemy.health > 0.000)))
   {
      if (((time - self.bot_last_enemy_seen) < 1.500))
      {
         self.bot_intent = BOT_INTENT_FIGHT;
      } //end if
      else
      {
         self.bot_intent = BOT_INTENT_CHASE;
      } //end else
   } //end if
   else
   {
      if (((self.health < 50.000) || (self.armorvalue < 25.000) || (self.currentammo < 5.000)))
      {
         self.bot_intent = BOT_INTENT_RESUPPLY;
      } //end if
      else
      {
         self.bot_intent = BOT_INTENT_EXPLORE;
      } //end else
   } //end else

   if ((self.bot_intent != prev_intent))
   {
      self.bot_intent_start = time;
      self.bot_intent_fail = 0.000;
   } //end if

   if ((self.intent_req || (time < self.intent_request_until)))
   {
      self.bot_intent_fail = 0.000;
   } //end if
   else
   {
      Bot_UpdateIntentFail (self);
      Bot_EscalateIntent (self);
   } //end else
}; //end of the function Bot_UpdateIntentDecision

// Check if current intent is succeeding (has valid success signal)
float (entity bot) Bot_IntentSucceeded =
{
   // RESUPPLY: success if we picked something up recently
   if ((bot.bot_intent == BOT_INTENT_RESUPPLY))
   {
      if (((time - bot.bot_last_pickup) < 2.000))
      {
         return (TRUE);
      } //end if
      return (FALSE);
   } //end if

   // EXPLORE: success if we picked something up OR made meaningful progress
   if ((bot.bot_intent == BOT_INTENT_EXPLORE))
   {
      if (((time - bot.bot_last_pickup) < 3.000))
      {
         return (TRUE);
      } //end if
      if (((time - bot.last_progress_time) < 1.000))
      {
         return (TRUE);
      } //end if
      return (FALSE);
   } //end if

   // CHASE: success if we reacquired LOS recently
   if ((bot.bot_intent == BOT_INTENT_CHASE))
   {
      if (((time - bot.bot_last_enemy_seen) < 1.500))
      {
         return (TRUE);
      } //end if
      return (FALSE);
   } //end if

   // FIGHT: success if enemy is visible recently
   if ((bot.bot_intent == BOT_INTENT_FIGHT))
   {
      if ((bot.enemy && ((time - bot.bot_last_enemy_seen) < 1.000)))
      {
         return (TRUE);
      } //end if
      // No LOS: fight is probably failing unless very brief
      return (FALSE);
   } //end if

   // UNSTICK: success if we are moving again
   if ((bot.bot_intent == BOT_INTENT_UNSTICK))
   {
      if (((time - bot.last_progress_time) < 0.800))
      {
         return (TRUE);
      } //end if
      return (FALSE);
   } //end if

   // HOLD: always valid while committed
   if ((bot.bot_intent == BOT_INTENT_HOLD))
   {
      return (TRUE);
   } //end if

   return (FALSE);
}; //end of the function Bot_IntentSucceeded

// Get timeout threshold for current intent
float (entity bot) Bot_IntentTimeout =
{
   if ((bot.bot_intent == BOT_INTENT_FIGHT))    return (2.500);  // If can't see them, reposition quickly
   if ((bot.bot_intent == BOT_INTENT_CHASE))    return (4.000);
   if ((bot.bot_intent == BOT_INTENT_RESUPPLY)) return (5.000);
   if ((bot.bot_intent == BOT_INTENT_EXPLORE))  return (6.000);
   if ((bot.bot_intent == BOT_INTENT_UNSTICK))  return (2.000);
   if ((bot.bot_intent == BOT_INTENT_HOLD))     return (1.000);
   return (5.000);
}; //end of the function Bot_IntentTimeout

// Update intent fail score (accumulate when failing, decay when succeeding)
void (entity bot) Bot_UpdateIntentFail =
{
   // Decay if succeeding
   if (Bot_IntentSucceeded (bot))
   {
      bot.bot_intent_fail = (bot.bot_intent_fail - 0.250);
      if ((bot.bot_intent_fail < 0.000))
      {
         bot.bot_intent_fail = 0.000;
      } //end if
      return ;
   } //end if

   // Accumulate when failing
   bot.bot_intent_fail = (bot.bot_intent_fail + 0.250);

   // Spike if loop detected (behavioral pathology)
   if (Loop_InLoop (bot))
   {
      bot.bot_intent_fail = (bot.bot_intent_fail + 0.750);
   } //end if

   // Spike if hard stuck (movement pathology)
   if (((time - bot.last_progress_time) > STUCK_TIME_LIMIT))
   {
      bot.bot_intent_fail = (bot.bot_intent_fail + 0.750);
   } //end if
}; //end of the function Bot_UpdateIntentFail

// Escalate to next-best intent when current intent fails for too long
void (entity bot) Bot_EscalateIntent =
{
   local float timeout;
   local vector trace_angles;

   if ((bot.bot_intent == BOT_INTENT_HOLD))
   {
      return ;
   } //end if

   timeout = Bot_IntentTimeout (bot);

   // If we just entered the intent, give it a chance
   if (((time - bot.bot_intent_start) < 1.000))
   {
      return ;
   } //end if

   // Escalate if fail score high OR we've exceeded timeout with no success
   if (((bot.bot_intent_fail < 2.000) && ((time - bot.bot_intent_start) < timeout)))
   {
      return ;
   } //end if

   // Reset fail score and start time on escalation
   bot.bot_intent_fail = 0.000;
   bot.bot_intent_start = time;

   if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
   {
      bprint ("[");
      bprint (bot.netname);
      bprint ("] INTENT-ESCALATE: ");
   } //end if

   // ===== ESCALATION GRAPH: Switch gears based on current intent =====

   // FIGHT → UNSTICK (reposition if LOS lost, vertical stalemate)
   if ((bot.bot_intent == BOT_INTENT_FIGHT))
   {
      bot.bot_intent = BOT_INTENT_UNSTICK;
      if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
      {
         bprint ("FIGHT → UNSTICK (reposition)\n");
      } //end if
      return ;
   } //end if

   // CHASE → RESUPPLY/EXPLORE (lost enemy, give up pursuit)
   if ((bot.bot_intent == BOT_INTENT_CHASE))
   {
      // If low resources, resupply
      if (((bot.health < 50.000) || (bot.armorvalue < 25.000) || (bot.currentammo < 5.000)))
      {
         bot.bot_intent = BOT_INTENT_RESUPPLY;
         if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
         {
            bprint ("CHASE → RESUPPLY (lost enemy, low resources)\n");
         } //end if
      } //end if
      else
      {
         bot.bot_intent = BOT_INTENT_EXPLORE;
         if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
         {
            bprint ("CHASE → EXPLORE (lost enemy)\n");
         } //end if
      } //end else
      return ;
   } //end if

   // RESUPPLY → EXPLORE (can't reach items, leave area)
   if ((bot.bot_intent == BOT_INTENT_RESUPPLY))
   {
      bot.bot_intent = BOT_INTENT_EXPLORE;
      if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
      {
         bprint ("RESUPPLY → EXPLORE (can't reach items)\n");
      } //end if
      return ;
   } //end if

   // EXPLORE → UNSTICK (no pickups, force exit line)
   if ((bot.bot_intent == BOT_INTENT_EXPLORE))
   {
      bot.bot_intent = BOT_INTENT_UNSTICK;
      if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
      {
         bprint ("EXPLORE → UNSTICK (no progress)\n");
      } //end if
      return ;
   } //end if

   // UNSTICK → EXPLORE (still stuck, record fail and try different escape)
   if ((bot.bot_intent == BOT_INTENT_UNSTICK))
   {
      // Record current direction as failed approach
      trace_angles_x = 0.000;
      trace_angles_y = bot.ideal_yaw;
      trace_angles_z = 0.000;
      makevectors (trace_angles);
      RecordDirectionalFail (bot,v_forward);
      // Try exploring
      bot.bot_intent = BOT_INTENT_EXPLORE;
      if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
      {
         bprint ("UNSTICK → EXPLORE (escape failed)\n");
      } //end if
      return ;
   } //end if
}; //end of the function Bot_EscalateIntent

// Hook for item pickup (updates success signal)
void (entity bot) Bot_OnPickup =
{
   bot.bot_last_pickup = time;
   // Reduce fail score (picking up items = progress)
   bot.bot_intent_fail = (bot.bot_intent_fail - 1.000);
   if ((bot.bot_intent_fail < 0.000))
   {
      bot.bot_intent_fail = 0.000;
   } //end if
}; //end of the function Bot_OnPickup

// Hook for enemy sighting (updates success signal)
void (entity bot) Bot_OnEnemySeen =
{
   bot.bot_last_enemy_seen = time;
   // Reduce fail score (seeing enemy = progress)
   bot.bot_intent_fail = (bot.bot_intent_fail - 0.500);
   if ((bot.bot_intent_fail < 0.000))
   {
      bot.bot_intent_fail = 0.000;
   } //end if
}; //end of the function Bot_OnEnemySeen

// Intent Director Driver: Translates high-level intent into movement goal
void (entity bot) Intent_Driver =
{
   local vector goal;
   local vector fwd;
   local vector trace_angles;

   goal = '0.000 0.000 0.000';

   // Translate intent to goal direction
   if ((bot.bot_intent == BOT_INTENT_FIGHT))
   {
      // Move toward enemy
      if ((bot.enemy && (bot.enemy.health > 0.000)))
      {
         goal = (bot.enemy.origin - bot.origin);
         goal_z = 0.000;
         if ((vlen (goal) > 0.010))
         {
            goal = normalize (goal);
         } //end if
      } //end if
   } //end if
   else
   {
      if ((bot.bot_intent == BOT_INTENT_CHASE))
      {
         // Move toward last known enemy position (use enemy or feeler best)
         if ((bot.enemy && (bot.enemy.health > 0.000)))
         {
            goal = (bot.enemy.origin - bot.origin);
            goal_z = 0.000;
            if ((vlen (goal) > 0.010))
            {
               goal = normalize (goal);
            } //end if
         } //end if
      } //end if
      else
      {
         if ((bot.bot_intent == BOT_INTENT_UNSTICK))
         {
            // Use feeler best direction (computed in Bot_Feelers_Evaluate)
            if ((vlen (bot.best_dir) > 0.010))
            {
               goal = bot.best_dir;
            } //end if
            else
            {
               // Fallback to forward
               trace_angles_x = 0.000;
               trace_angles_y = bot.ideal_yaw;
               trace_angles_z = 0.000;
               makevectors (trace_angles);
               goal = v_forward;
            } //end else
         } //end if
         else
         {
            // EXPLORE or RESUPPLY: use feeler best direction
            if ((vlen (bot.best_dir) > 0.010))
            {
               goal = bot.best_dir;
            } //end if
            else
            {
               // Fallback to forward
               trace_angles_x = 0.000;
               trace_angles_y = bot.ideal_yaw;
               trace_angles_z = 0.000;
               makevectors (trace_angles);
               goal = v_forward;
            } //end else
         } //end else
      } //end else
   } //end else

   // If we have a valid goal, request control (priority 60)
   if ((vlen (goal) > 0.010))
   {
      FG_Request (bot,60.000,FG_DRV_INTENT,goal,0.500);
   } //end if
}; //end of the function Intent_Driver

// ===== END INTENT ESCALATION =====

// ===== VERTICAL TACTICS: FIXES STALEMATE UNDER/OVER PLATFORMS =====

// Check if bot has line-of-sight to enemy
float (entity bot, entity e) VT_HasLOS =
{
   local vector start;
   local vector end;

   start = (bot.origin + '0.000 0.000 16.000');
   end = (e.origin + '0.000 0.000 16.000');
   traceline (start,end,TRUE,bot);
   return ((trace_fraction == 1.000));
}; //end of the function VT_HasLOS

// Detect when vertical mode should activate (significant Z separation + no LOS)
float (entity bot, entity e) VT_VerticalMode =
{
   local float dz;
   local float xy;
   local vector d;

   d = (e.origin - bot.origin);
   dz = d_z;
   d_z = 0.000;
   xy = vlen (d);

   // Trigger if vertical separation > 96 units
   if ((fabs (dz) < 96.000))
   {
      return (FALSE);
   } //end if

   // Close XY and no LOS = classic "under platform" trap
   if (((xy < 160.000) && !VT_HasLOS (bot,e)))
   {
      return (TRUE);
   } //end if

   // Also trigger if no progress while vertically separated and no LOS
   if ((((time - bot.last_progress_time) > 1.500) && !VT_HasLOS (bot,e)))
   {
      return (TRUE);
   } //end if

   return (FALSE);
}; //end of the function VT_VerticalMode

// Calculate vertical penalty for candidate move direction
float (entity bot, entity e, vector moveDir) VT_VertPenalty =
{
   local vector d;
   local float dz;
   local float xy;
   local float desired;
   local float after_xy;
   local vector p;
   local float before_err;
   local float after_err;

   d = (e.origin - bot.origin);
   dz = d_z;
   d_z = 0.000;
   xy = vlen (d);

   // Predict 0.4s ahead along moveDir (flatten Z for XY distance)
   local vector flat_dir;
   flat_dir = moveDir;
   flat_dir_z = 0.000;
   flat_dir = normalize (flat_dir);
   p = (bot.origin + (flat_dir * 160.000));  // 160 units probe
   d = (e.origin - p);
   d_z = 0.000;
   after_xy = vlen (d);

   if (((fabs (dz) > 96.000) && !VT_HasLOS (bot,e)))
   {
      // Big penalty for going "more under" (reducing XY when already too close)
      if (((xy < 160.000) && (after_xy < xy)))
      {
         return (1.000);  // 100 penalty points (scaled by 100 in scoring)
      } //end if

      // Encourage moving toward a ring distance to get angles
      desired = 256.000;
      before_err = fabs ((xy - desired));
      after_err = fabs ((after_xy - desired));

      if ((after_err < before_err))
      {
         return (-0.500);  // Negative = reward (50 bonus points)
      } //end if
   } //end if

   return (0.000);
}; //end of the function VT_VertPenalty

// Pick vertical reposition direction (tangential strafe to find angle)
vector (entity bot, entity e) VT_PickRepositionDir =
{
   local vector toE;
   local vector dirToE;
   local vector tangL;
   local vector tangR;
   local float xy;
   local float desired;
   local vector outDir;
   local vector c1;
   local vector c2;
   local float clearL;
   local float clearR;
   local vector start;
   local vector end;
   local vector trace_angles;

   toE = (e.origin - bot.origin);
   toE_z = 0.000;

   // Fallback if enemy is exactly on top (rare)
   if ((vlen (toE) < 0.010))
   {
      trace_angles_x = 0.000;
      trace_angles_y = bot.ideal_yaw;
      trace_angles_z = 0.000;
      makevectors (trace_angles);
      tangR_x = -v_forward_y;
      tangR_y = v_forward_x;
      tangR_z = 0.000;
      return (normalize (tangR));
   } //end if

   dirToE = normalize (toE);
   xy = vlen (toE);
   desired = 256.000;

   // Tangents around enemy bearing (left and right strafe)
   tangL_x = -dirToE_y;
   tangL_y = dirToE_x;
   tangL_z = 0.000;
   tangR_x = dirToE_y;
   tangR_y = -dirToE_x;
   tangR_z = 0.000;
   tangL = normalize (tangL);
   tangR = normalize (tangR);

   // If too close, favor moving out plus tangent
   if ((xy < desired))
   {
      outDir = -dirToE;  // away from enemy in XY

      // Blend outward and tangent, pick whichever is clearer
      c1 = ((outDir + (tangL * 0.700)) * 0.700);
      c2 = ((outDir + (tangR * 0.700)) * 0.700);
      c1 = normalize (c1);
      c2 = normalize (c2);

      // Check clearance for both candidates
      start = (bot.origin + '0.000 0.000 22.000');
      end = (start + (c1 * 160.000));
      traceline (start,end,TRUE,bot);
      clearL = trace_fraction;

      end = (start + (c2 * 160.000));
      traceline (start,end,TRUE,bot);
      clearR = trace_fraction;

      if ((clearR > clearL))
      {
         return (c2);
      } //end if

      return (c1);
   } //end if

   // Already at good distance: just strafe around to find LOS
   // Check clearance and pick clearer tangent
   start = (bot.origin + '0.000 0.000 22.000');
   end = (start + (tangL * 160.000));
   traceline (start,end,TRUE,bot);
   clearL = trace_fraction;

   end = (start + (tangR * 160.000));
   traceline (start,end,TRUE,bot);
   clearR = trace_fraction;

   if ((clearR > clearL))
   {
      return (tangR);
   } //end if

   return (tangL);
}; //end of the function VT_PickRepositionDir

// Vertical Reposition Driver: Request control when vertical stalemate detected
void (entity bot) VT_Driver =
{
   local vector reposition_dir;

   if (!bot.enemy)
   {
      return ;
   } //end if

   if ((bot.enemy.health <= 0.000))
   {
      return ;
   } //end if

   if (!VT_VerticalMode (bot,bot.enemy))
   {
      return ;
   } //end if

   // Pick tangential reposition direction
   reposition_dir = VT_PickRepositionDir (bot,bot.enemy);

   // Request control from Flow Governor (priority 80)
   FG_Request (bot,80.000,FG_DRV_VERTICAL,reposition_dir,1.000);
}; //end of the function VT_Driver

// ===== END VERTICAL TACTICS =====

// ===== BEHAVIORAL LOOP DETECTION: STOPS REPETITIVE CIRCLES =====

// Create signature for current bot state (position cell + yaw bucket)
float (entity bot) Loop_MakeSig =
{
   local vector p;
   local float yawb;
   local float cellx;
   local float celly;
   local float move_yaw;
   local vector goal_dir;

   // Use 32-unit grid (same as CoarsePos)
   p = CoarsePos (bot.origin);
   cellx = (p_x / 32.000);
   celly = (p_y / 32.000);

   // Yaw bucket: 0-11 (30 degree buckets)
   // Use movement yaw (goal/driver) instead of view yaw to avoid aim-driven loops.
   move_yaw = bot.ideal_yaw;
   if ((bot.fg_driver != FG_DRV_NONE) && (vlen (bot.fg_goalDir) > 0.000))
   {
      move_yaw = vectoyaw (bot.fg_goalDir);
   } //end if
   else if (bot.goalentity)
   {
      goal_dir = (bot.goalentity.origin - bot.origin);
      if ((vlen (goal_dir) > 1.000))
      {
         move_yaw = vectoyaw (goal_dir);
      } //end if
   } //end else

   yawb = floor ((move_yaw / 30.000));
   while ((yawb < 0.000))
   {
      yawb = (yawb + 12.000);
   } //end while
   while ((yawb >= 12.000))
   {
      yawb = (yawb - 12.000);
   } //end while

   // Pack into float signature (cheap and dirty)
   return (((cellx * 100000.000) + (celly * 100.000)) + yawb);
}; //end of the function Loop_MakeSig

// Push current signature to buffer (call every 0.25s)
void (entity bot) Loop_PushSig =
{
   local float s;

   if (bot.is_retracing)
   {
      return ;
   } //end if
   if ((bot.stuck_mode != BOT_MODE_NORMAL))
   {
      return ;
   } //end if
   if ((bot.hazard_escape_until > time))
   {
      return ;
   } //end if
   if ((time < bot.loop_sig_time))
   {
      return ;
   } //end if

   bot.loop_sig_time = (time + 0.250);

   s = Loop_MakeSig (bot);

   // Ring buffer shift
   bot.loop_sig5 = bot.loop_sig4;
   bot.loop_sig4 = bot.loop_sig3;
   bot.loop_sig3 = bot.loop_sig2;
   bot.loop_sig2 = bot.loop_sig1;
   bot.loop_sig1 = bot.loop_sig0;
   bot.loop_sig0 = s;
   if ((bot.loop_sig_count < 6.000))
   {
      bot.loop_sig_count = (bot.loop_sig_count + 1.000);
   } //end if
}; //end of the function Loop_PushSig

void (entity bot) Loop_ResetSig =
{
   bot.loop_sig0 = 0.000;
   bot.loop_sig1 = 0.000;
   bot.loop_sig2 = 0.000;
   bot.loop_sig3 = 0.000;
   bot.loop_sig4 = 0.000;
   bot.loop_sig5 = 0.000;
   bot.loop_sig_count = 0.000;
   bot.loop_sig_time = (time + 0.750);
}; //end of the function Loop_ResetSig

// Detect if bot is in behavioral loop (4/6 signatures same)
float (entity bot) Loop_InLoop =
{
   local float s;
   local float count;

   if ((bot.loop_sig_count < 4.000))
   {
      return (FALSE);
   } //end if

   s = bot.loop_sig0;
   count = 0.000;

   if ((bot.loop_sig0 == s)) count = (count + 1.000);
   if ((bot.loop_sig1 == s)) count = (count + 1.000);
   if ((bot.loop_sig2 == s)) count = (count + 1.000);
   if ((bot.loop_sig3 == s)) count = (count + 1.000);
   if ((bot.loop_sig4 == s)) count = (count + 1.000);
   if ((bot.loop_sig5 == s)) count = (count + 1.000);

   // 4/6 same = likely loop
   if ((count >= 4.000))
   {
      return (TRUE);
   } //end if

   return (FALSE);
}; //end of the function Loop_InLoop

// Force breaker action to escape behavioral loop
void (entity bot) Loop_BreakLoop =
{
   local vector fwd_dir;
   local vector trace_angles;

   if (bot.is_retracing)
   {
      return ;
   } //end if
   if ((bot.stuck_mode == BOT_MODE_UNSTICK))
   {
      return ;
   } //end if
   if ((bot.stuck_mode == BOT_MODE_COOLDOWN))
   {
      return ;
   } //end if
   if ((time < bot.escape_cooldown_time))
   {
      return ;
   } //end if
   if ((bot.hazard_escape_until > time))
   {
      return ;
   } //end if
   if ((time < bot.loop_break_until))
   {
      return ;
   } //end if
   if (((bot.fg_driver == FG_DRV_TERRAIN) && (time < bot.fg_until)))
   {
      return ;
   } //end if

   if (!Loop_InLoop (bot))
   {
      return ;
   } //end if

   if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
   {
      bprint ("[");
      bprint (bot.netname);
      bprint ("] LOOP-BREAK: Detected repetitive behavior at ");
      bprint (vtos (bot.origin));
      bprint (", forcing reposition\n");
   } //end if

   bot.loop_break_until = (time + 8.000);
   bot.loop_break_origin = bot.origin;
   Loop_ResetSig (bot);

   // Record current forward as a fail
   trace_angles_x = 0.000;
   trace_angles_y = bot.ideal_yaw;
   trace_angles_z = 0.000;
   makevectors (trace_angles);
   fwd_dir = v_forward;
   RecordDirectionalFail (bot,fwd_dir);

   // Request control from Flow Governor (priority 90)
   // Use forward direction as initial goal (steering will refine)
   FG_Request (bot,90.000,FG_DRV_LOOP,fwd_dir,1.200);

   // Force unstick mode for a moment with a fresh escape plan
   Bot_EnterUnstick (R_UNSTICK_LOOP,"loop break");
   bot.escape_until_time = (time + 1.200);
}; //end of the function Loop_BreakLoop

// ===== END BEHAVIORAL LOOP DETECTION =====

float (entity bot, vector dir, float dist) Bot_JumpFeasibleSimple =
{
   local vector start;
   local vector end;
   local float content_type;

   // Headroom check
   start = bot.origin;
   end = (start + '0.000 0.000 48.000');
   traceline (start,end,TRUE,bot);
   if ((trace_fraction < 1.000))
   {
      return (FALSE);
   } //end if

   // Forward clearance at jump height
   start = (bot.origin + '0.000 0.000 24.000');
   end = (start + (dir * dist));
   traceline (start,end,TRUE,bot);
   if ((trace_fraction < 1.000))
   {
      return (FALSE);
   } //end if

   // Landing zone check
   start = (bot.origin + (dir * dist) + '0.000 0.000 18.000');
   end = (start + '0.000 0.000 -64.000');
   traceline (start,end,TRUE,bot);
   if ((trace_fraction == 1.000))
   {
      return (FALSE);
   } //end if
   content_type = pointcontents (trace_endpos);
   if (((content_type == CONTENT_LAVA) || (content_type == CONTENT_SLIME)))
   {
      return (FALSE);
   } //end if

   return (TRUE);
}; //end of the function Bot_JumpFeasibleSimple

float (entity bot, vector dir, float dist) Bot_JumpFeasibleArc =
{
   local float i;
   local float steps;
   local float step;
   local float t;
   local float speed;
   local vector start;
   local vector prev;
   local vector pos;
   local vector vel;
   local float content_type;

   steps = 6.000;
   step = 0.100;
   speed = 300.000;

   start = (bot.origin + '0.000 0.000 24.000');
   vel = (dir * speed);
   vel_z = 270.000;
   prev = start;

   i = 1.000;
   while ((i <= steps))
   {
      t = (i * step);
      pos = (start + (vel * t));
      pos_z = (start_z + (vel_z * t) - (0.500 * 800.000 * t * t));

      traceline (prev,pos,TRUE,bot);
      if ((trace_fraction < 1.000))
      {
         return (FALSE);
      } //end if

      prev = pos;
      i = (i + 1.000);
   } //end while

   // Confirm we can land on something
   traceline (pos,(pos + '0.000 0.000 -64.000'),TRUE,bot);
   if ((trace_fraction == 1.000))
   {
      return (FALSE);
   } //end if
   content_type = pointcontents (trace_endpos);
   if (((content_type == CONTENT_LAVA) || (content_type == CONTENT_SLIME)))
   {
      return (FALSE);
   } //end if

   return (TRUE);
}; //end of the function Bot_JumpFeasibleArc

float (entity bot, vector dir, float dist) Bot_JumpFeasible =
{
   local float yaw;
   local vector testdir;
   local vector trace_angles;

   if (!Bot_JumpFeasibleSimple (bot,dir,dist))
   {
      return (FALSE);
   } //end if

   if (Bot_JumpFeasibleArc (bot,dir,dist))
   {
      return (TRUE);
   } //end if

   // Allow slight air-control variants
   yaw = vectoyaw (dir);

   trace_angles_x = 0.000;
   trace_angles_y = (yaw + 20.000);
   trace_angles_z = 0.000;
   makevectors (trace_angles);
   testdir = v_forward;
   if (Bot_JumpFeasibleArc (bot,testdir,dist)) return (TRUE);

   trace_angles_y = (yaw - 20.000);
   makevectors (trace_angles);
   testdir = v_forward;
   if (Bot_JumpFeasibleArc (bot,testdir,dist)) return (TRUE);

   return (FALSE);
}; //end of the function Bot_JumpFeasible

float (entity bot, vector pos) Bot_FloorHeight =
{
   local vector start;
   local vector end;

   start = (pos + '0.000 0.000 24.000');
   end = (pos + '0.000 0.000 -256.000');
   traceline (start,end,TRUE,bot);
   if ((trace_fraction == 1.000))
   {
      return (pos_z);
   } //end if
   return (trace_endpos_z);
}; //end of the function Bot_FloorHeight

float (entity bot, vector pos, entity target) Bot_LOSClassFrom =
{
   local vector start;
   local float has_feet;
   local float has_torso;
   local float has_head;

   start = (pos + bot.view_ofs);

   traceline (start,(target.origin + '0.000 0.000 8.000'),TRUE,bot);
   has_feet = (trace_fraction == 1.000);
   traceline (start,(target.origin + target.view_ofs),TRUE,bot);
   has_torso = (trace_fraction == 1.000);
   traceline (start,(target.origin + '0.000 0.000 40.000'),TRUE,bot);
   has_head = (trace_fraction == 1.000);

   if (has_head) return (BOT_LOS_HEAD);
   if (has_torso) return (BOT_LOS_TORSO);
   if (has_feet) return (BOT_LOS_FEET);
   return (BOT_LOS_NONE);
}; //end of the function Bot_LOSClassFrom

float (float los_class) Bot_LOSScore =
{
   if ((los_class == BOT_LOS_HEAD)) return (320.000);
   if ((los_class == BOT_LOS_TORSO)) return (280.000);
   if ((los_class == BOT_LOS_FEET)) return (80.000);
   return (-220.000);
}; //end of the function Bot_LOSScore

float (entity bot, vector pos, vector dir) Bot_LedgeRisk =
{
   local vector ahead;
   local float z_here;
   local float z_ahead;
   local float drop_low;
   local float drop_high;
   local float caution;

   ahead = (pos + (dir * 48.000));
   traceline ((ahead + '0.000 0.000 24.000'),(ahead + '0.000 0.000 -256.000'),TRUE,bot);
   if ((trace_fraction == 1.000))
   {
      return (260.000);
   } //end if
   if ((trace_plane_normal_z < 0.700))
   {
      return (200.000);
   } //end if
   caution = Clamp ((bot.stuck_score * 8.000),0.000,32.000);
   drop_low = Clamp ((64.000 - caution),32.000,64.000);
   drop_high = Clamp ((128.000 - (caution * 2.000)),64.000,128.000);
   z_here = Bot_FloorHeight (bot,pos);
   z_ahead = trace_endpos_z;
   if (((z_here - z_ahead) > drop_high))
   {
      return (220.000);
   } //end if
   if (((z_here - z_ahead) > drop_low))
   {
      return (120.000);
   } //end if
   return (0.000);
}; //end of the function Bot_LedgeRisk

float (entity bot, vector pos) Bot_PadBonus =
{
   local float dist;

   if (!bot.last_pad_time)
   {
      return (0.000);
   } //end if
   if (((time - bot.last_pad_time) > 10.000))
   {
      return (0.000);
   } //end if
   dist = vlen ((bot.last_pad_origin - pos));
   if ((dist < 256.000)) return (120.000);
   if ((dist < 512.000)) return (60.000);
   return (0.000);
}; //end of the function Bot_PadBonus

float (entity bot, vector pos) Bot_LiftBonus =
{
   local float dist;

   if (!bot.last_lift_time)
   {
      return (0.000);
   } //end if
   if (((time - bot.last_lift_time) > 12.000))
   {
      return (0.000);
   } //end if
   dist = vlen ((bot.last_lift_origin - pos));
   if ((dist < 256.000)) return (90.000);
   if ((dist < 512.000)) return (40.000);
   return (0.000);
}; //end of the function Bot_LiftBonus

float (float base_yaw, float idx, float wall_side) Bot_CandidateYaw =
{
   local float sign;

   sign = 1.000;
   if ((wall_side < 0.000))
   {
      sign = -1.000;
   } //end if

   if ((idx == 0.000)) return (base_yaw);
   if ((idx == 1.000)) return (base_yaw + (35.000 * sign));
   if ((idx == 2.000)) return (base_yaw - (35.000 * sign));
   if ((idx == 3.000)) return (base_yaw + (90.000 * sign));
   if ((idx == 4.000)) return (base_yaw - (90.000 * sign));
   if ((idx == 5.000)) return (base_yaw + (145.000 * sign));
   if ((idx == 6.000)) return (base_yaw - (145.000 * sign));
   return (base_yaw + 180.000);
}; //end of the function Bot_CandidateYaw

void (entity bot, float mode, float wall_side, float base_yaw) Bot_Feelers_Evaluate =
{
   local float i;
   local float scan_yaw;
   local vector dir;
   local vector side;
   local vector start;
   local vector end;
   local vector base_fwd;
   local vector base_right;
   local float clear_dist;
   local float widen_score;
   local float future_score;
   local float score;
   local float heat_penalty;
   local float jump_ok;
   local float step_ok;
   local float tight_gap;
   local float blocked;
   local vector probe;
   local float side_bias;
   local float forward_scale;
   local float strafe_bias;
   local float same_dir;
   local vector cand_pos;
   local vector aim;
   local vector flat;
   local vector ang;
   local float los_score;
   local float pitch_penalty;
   local float under_penalty;
   local float range_penalty;
   local float dz;
   local float dh;
   local float dist_enemy;
   local float pitch;
   local float los_class;
   local float ledge_penalty;
   local float rocket_penalty;
   local float pad_bonus;
   local float lift_bonus;
   local float post_teleport;
   local float hazard_penalty;
   local float content_type;
   local float base_floor_z;
   local float cand_floor_z;
   local float dz_floor;
   local float elevation_bonus;
   local float break_contact;
   local float elevate_active;
   local float directional_fail;
   local vector second_dir;
   local float second_score;
   local vector blended_dir;
   local float blended_len;
   local float cand_count;
   local float forward_len;
   local float future_len;
   local float side_offset;
   local float clear_frac;
   local float center_frac;
   local float left_frac;
   local float right_frac;
   local vector trace_angles;

   bot.best_score = -99999.000;
   bot.best_dir = '1.000 0.000 0.000';
   bot.best_wants_jump = FALSE;
   bot.best_step_ok = FALSE;
   bot.best_tight_gap = FALSE;
   bot.best_blocked = FALSE;
   bot.best_clear_dist = 0.000;
   bot.best_widen_score = 0.000;
   bot.best_heat_penalty = 0.000;
   bot.best_ideal_yaw = base_yaw;
   bot.best_forward_scale = 1.000;
   bot.best_strafe_bias = 0.000;
   second_dir = '0.000 0.000 0.000';
   second_score = -99999.000;

   trace_angles_x = 0.000;
   trace_angles_y = base_yaw;
   trace_angles_z = 0.000;
   makevectors (trace_angles);
   base_fwd = v_forward;
   base_right = v_right;
   base_floor_z = Bot_FloorHeight (bot,bot.origin);
   break_contact = (bot.combat_break_until > time);
   elevate_active = (bot.combat_vert_disadvantage && (time <= bot.combat_elevate_until));
   post_teleport = (bot.teleport_time > time);
   forward_len = Bot_FeelerRange (bot,mode);
   future_len = (forward_len * 0.400);
   side_offset = fabs (bot.mins_x);
   if ((bot.maxs_x > side_offset))
   {
      side_offset = bot.maxs_x;
   } //end if
   side_offset = (side_offset - 2.000);
   side_offset = Clamp (side_offset,16.000,32.000);
   cand_count = Bot_FeelerCandidateCount (bot,mode);

   i = 0.000;
   while ((i < cand_count))
   {
      scan_yaw = Bot_CandidateYaw (base_yaw,i,wall_side);

      trace_angles_x = 0.000;
      trace_angles_y = scan_yaw;
      trace_angles_z = 0.000;
      makevectors (trace_angles);
      dir = v_forward;
      side = v_right;

      start = (bot.origin + '0.000 0.000 24.000');
      end = (start + (dir * forward_len));
      traceline (start,end,TRUE,bot);
      center_frac = trace_fraction;

      traceline ((start + (side * side_offset)),(start + (side * side_offset) + (dir * forward_len)),TRUE,bot);
      left_frac = trace_fraction;
      traceline ((start - (side * side_offset)),(start - (side * side_offset) + (dir * forward_len)),TRUE,bot);
      right_frac = trace_fraction;

      clear_frac = center_frac;
      if ((left_frac < clear_frac)) clear_frac = left_frac;
      if ((right_frac < clear_frac)) clear_frac = right_frac;
      if ((bot.stuck_score > 1.000))
      {
         traceline ((start + '0.000 0.000 12.000'),(start + '0.000 0.000 12.000' + (dir * forward_len)),TRUE,bot);
         if ((trace_fraction < clear_frac)) clear_frac = trace_fraction;
      } //end if

      clear_dist = (clear_frac * forward_len);
      blocked = (clear_dist < 24.000);

      widen_score = ((left_frac + right_frac) * 60.000);

      probe = (bot.origin + (dir * (forward_len * 0.200)));
      traceline (probe,(probe + (dir * future_len)),TRUE,bot);
      future_score = (trace_fraction * future_len);

      traceline ((bot.origin + '0.000 0.000 22.000'),(bot.origin + '0.000 0.000 22.000' + (dir * (forward_len * 0.200))),TRUE,bot);
      step_ok = (trace_fraction == 1.000);

      tight_gap = FALSE;
      if (((clear_dist < (forward_len * 0.400)) || (widen_score < 40.000)))
      {
         tight_gap = TRUE;
      } //end if

      jump_ok = FALSE;
      if ((bot.flags & FL_ONGROUND))
      {
         if (Bot_JumpFeasible (bot,dir,140.000))
         {
            jump_ok = TRUE;
         } //end if
      } //end if

      heat_penalty = 0.000;
      probe = (bot.origin + (dir * 96.000));
      if ((bot.bad_spot_expire_time > time))
      {
         if ((vlen (probe - bot.bad_spot_origin) < bot.bad_spot_radius))
         {
            heat_penalty = (heat_penalty + 80.000);
         } //end if
      } //end if
      if (Bot_IsRecentlyVisited (bot,probe))
      {
         heat_penalty = (heat_penalty + 60.000);
      } //end if
      if ((vlen (bot.last_escape_dir) > 0.000))
      {
         same_dir = ((normalize (bot.last_escape_dir)) * dir);
         if ((same_dir > 0.950))
         {
            heat_penalty = (heat_penalty + 30.000);
         } //end if
      } //end if
      score = (clear_dist + (widen_score * 0.600) + (future_score * 0.400));

      // Directional fail memory: Heavy penalty for previously failed approaches
      // Use as "last resort" - bot can still pick it if ALL options are bad
      directional_fail = GetDirectionalPenalty (bot,dir);
      score = (score - directional_fail);
      if (tight_gap)
      {
         score = (score - 15.000);
      } //end if
      if ((blocked && !step_ok))
      {
         score = (score - 120.000);
      } //end if

      side_bias = 0.000;
      if ((wall_side > 0.000))
      {
         side_bias = ((dir * base_right) * 20.000);
      } //end if
      else
      {
         if ((wall_side < 0.000))
         {
            side_bias = ((dir * base_right) * -20.000);
         } //end if
      } //end else
      score = (score + side_bias);

      if ((mode == BOT_MODE_COMBAT))
      {
         if ((bot.enemy && (bot.enemy != world)))
         {
            cand_pos = (bot.origin + (dir * 192.000));

            los_class = Bot_LOSClassFrom (bot,cand_pos,bot.enemy);
            los_score = Bot_LOSScore (los_class);
            if (break_contact)
            {
               if ((los_class == BOT_LOS_NONE))
               {
                  los_score = (los_score + 60.000);
               } //end if
               else
               {
                  if ((los_class >= BOT_LOS_TORSO))
                  {
                     los_score = (los_score - 40.000);
                  } //end if
               } //end else
            } //end if

            aim = ((bot.enemy.origin + bot.enemy.view_ofs) - (cand_pos + bot.view_ofs));
            ang = vectoangles (aim);
            pitch = fabs (ang_x);
            pitch_penalty = 0.000;
            if ((pitch > 45.000))
            {
               pitch_penalty = 120.000;
            } //end if
            else
            {
               if ((pitch > 30.000))
               {
                  pitch_penalty = 60.000;
               } //end if
            } //end else
            if (((bot.weapon == IT_LIGHTNING) || (bot.weapon == IT_SUPER_NAILGUN)))
            {
               pitch_penalty = (pitch_penalty * 1.250);
            } //end if
            else
            {
               if ((bot.weapon == IT_ROCKET_LAUNCHER))
               {
                  pitch_penalty = (pitch_penalty * 0.900);
               } //end if
            } //end else

            flat = (bot.enemy.origin - cand_pos);
            dz = flat_z;
            flat_z = 0.000;
            dh = vlen (flat);
            under_penalty = 0.000;
            if (((dz > 128.000) && (dh < 96.000)))
            {
               under_penalty = 400.000;
            } //end if
            else
            {
               if (((dz > 96.000) && (dh < 128.000)))
               {
                  under_penalty = 250.000;
               } //end if
            } //end else

            if ((bot.weapon == IT_ROCKET_LAUNCHER))
            {
               under_penalty = (under_penalty + 120.000);
            } //end if
            else
            {
               if ((bot.weapon == IT_LIGHTNING))
               {
                  under_penalty = (under_penalty + 60.000);
               } //end if
            } //end else
            if (break_contact)
            {
               if ((under_penalty > 0.000))
               {
                  under_penalty = (under_penalty + 120.000);
               } //end if
            } //end if
            rocket_penalty = 0.000;
            if (((bot.weapon == IT_ROCKET_LAUNCHER) || (bot.weapon == IT_GRENADE_LAUNCHER)))
            {
               if (((dz > 96.000) && (dh < 256.000)))
               {
                  rocket_penalty = (rocket_penalty + 180.000);
               } //end if
               if (((dz > 128.000) && (dh < 160.000)))
               {
                  rocket_penalty = (rocket_penalty + 220.000);
               } //end if
            } //end if

            dist_enemy = vlen ((bot.enemy.origin - cand_pos));
            range_penalty = 0.000;
            if ((bot.weapon == IT_LIGHTNING))
            {
               if ((dist_enemy > 350.000))
               {
                  range_penalty = (range_penalty + 80.000);
               } //end if
               if ((dist_enemy < 80.000))
               {
                  range_penalty = (range_penalty + 40.000);
               } //end if
            } //end if
            else
            {
               if ((bot.weapon == IT_ROCKET_LAUNCHER))
               {
                  if ((dist_enemy < 120.000))
                  {
                     range_penalty = (range_penalty + 200.000);
                  } //end if
                  if ((dist_enemy > 700.000))
                  {
                     range_penalty = (range_penalty + 40.000);
                  } //end if
               } //end if
               else
               {
                  if (((bot.weapon == IT_SUPER_SHOTGUN) || (bot.weapon == IT_SHOTGUN)))
                  {
                     if ((dist_enemy < 100.000))
                     {
                        range_penalty = (range_penalty + 60.000);
                     } //end if
                     if ((dist_enemy > 600.000))
                     {
                        range_penalty = (range_penalty + 60.000);
                     } //end if
                  } //end if
                  else
                  {
                     if (((bot.weapon == IT_SUPER_NAILGUN) || (bot.weapon == IT_NAILGUN)))
                     {
                        if ((dist_enemy < 120.000))
                        {
                           range_penalty = (range_penalty + 30.000);
                        } //end if
                        if ((dist_enemy > 600.000))
                        {
                           range_penalty = (range_penalty + 50.000);
                        } //end if
                     } //end if
                  } //end else
               } //end else
            } //end else

      score = (score + los_score);
      score = (score - pitch_penalty);
      score = (score - under_penalty);
      score = (score - rocket_penalty);
      score = (score - range_penalty);

      // Vertical tactics: Penalize moving under/over enemy when Z-separated and no LOS
      if (VT_VerticalMode (bot,bot.enemy))
      {
         local float vert_penalty;
         vert_penalty = VT_VertPenalty (bot,bot.enemy,dir);
         score = (score - (vert_penalty * 100.000));  // Scale penalty to scoring range
      } //end if
   } //end if

   score = (score - (heat_penalty * 0.500));
         if (break_contact)
         {
            score = (score + (widen_score * 0.400));
            score = (score - ((dir * base_fwd) * 40.000));
         } //end if
         if (post_teleport)
         {
            score = (score + (widen_score * 0.300));
            score = (score - (heat_penalty * 0.300));
         } //end if
         if (elevate_active)
         {
            if ((!blocked && step_ok))
            {
               cand_floor_z = Bot_FloorHeight (bot,cand_pos);
               dz_floor = (cand_floor_z - base_floor_z);
               elevation_bonus = 0.000;
               if ((dz_floor > 64.000))
               {
                  elevation_bonus = 120.000;
               } //end if
               else
               {
                  if ((dz_floor > 32.000))
                  {
                     elevation_bonus = 70.000;
                  } //end if
                  else
                  {
                     if ((dz_floor > 16.000))
                     {
                        elevation_bonus = 35.000;
                     } //end if
                  } //end else
               } //end else
               score = (score + elevation_bonus);
               if (jump_ok)
               {
                  score = (score + 50.000);
               } //end if
               pad_bonus = Bot_PadBonus (bot,cand_pos);
               lift_bonus = Bot_LiftBonus (bot,cand_pos);
               score = (score + pad_bonus + lift_bonus);
            } //end if
         } //end if

      ledge_penalty = Bot_LedgeRisk (bot,cand_pos,dir);
      if (break_contact)
      {
         ledge_penalty = (ledge_penalty * 0.600);
      } //end if
      score = (score - ledge_penalty);

      hazard_penalty = 0.000;
      traceline ((cand_pos + '0.000 0.000 24.000'),(cand_pos + '0.000 0.000 -256.000'),TRUE,bot);
      if ((trace_fraction == 1.000))
      {
         hazard_penalty = 400.000;
      } //end if
      else
      {
         content_type = pointcontents (trace_endpos);
         if (((content_type == CONTENT_LAVA) || (content_type == CONTENT_SLIME)))
         {
            hazard_penalty = 600.000;
         } //end if
      } //end else
      score = (score - hazard_penalty);
   } //end if
      else
      {
         if ((mode == BOT_MODE_UNSTICK))
         {
            score = (score - heat_penalty);
            score = (score + ((1.000 - (dir * base_fwd)) * 20.000));
            if (jump_ok)
            {
               score = (score + 80.000);
            } //end if
         } //end if
         else
         {
            score = (score - (heat_penalty * 0.500));
            if (((dir * base_fwd) < 0.000))
            {
               score = (score - 10.000);
            } //end if
         } //end else
      } //end else

      if ((score > bot.best_score))
      {
         second_score = bot.best_score;
         second_dir = bot.best_dir;
         bot.best_score = score;
         bot.best_dir = dir;
         bot.best_wants_jump = (jump_ok && ((mode == BOT_MODE_UNSTICK) || (mode == BOT_MODE_COMBAT)));
         bot.best_step_ok = step_ok;
         bot.best_tight_gap = tight_gap;
         bot.best_blocked = blocked;
         bot.best_clear_dist = clear_dist;
         bot.best_widen_score = widen_score;
         bot.best_heat_penalty = heat_penalty;
         bot.best_ideal_yaw = vectoyaw (dir);

         forward_scale = 1.000;
         if (tight_gap)
         {
            forward_scale = 0.600;
         } //end if
         else
         {
            if ((clear_dist < 80.000))
            {
               forward_scale = 0.800;
            } //end if
         } //end else
         bot.best_forward_scale = forward_scale;

         strafe_bias = 0.000;
         if ((mode == BOT_MODE_UNSTICK))
         {
            if ((wall_side > 0.000)) strafe_bias = 30.000;
            if ((wall_side < 0.000)) strafe_bias = -30.000;
         } //end if
         else
         {
            if ((mode == BOT_MODE_COMBAT))
            {
               if ((wall_side > 0.000)) strafe_bias = 20.000;
               if ((wall_side < 0.000)) strafe_bias = -20.000;
            } //end if
         } //end else
         bot.best_strafe_bias = strafe_bias;
      } //end if
      else
      {
         if ((score > second_score))
         {
            second_score = score;
            second_dir = dir;
         } //end if
      } //end else

      i = (i + 1.000);
   } //end while
   if ((second_score > -99998.000))
   {
      if ((second_score > (bot.best_score - 80.000)))
      {
         blended_dir = ((bot.best_dir * 0.700) + (second_dir * 0.300));
         blended_len = vlen (blended_dir);
         if ((blended_len > 0.100))
         {
            bot.best_dir = (blended_dir / blended_len);
            bot.best_ideal_yaw = vectoyaw (bot.best_dir);
         } //end if
      } //end if
   } //end if
   if ((mode == BOT_MODE_NORMAL))
   {
      if ((time < bot.feeler_commit_until))
      {
         if (((bot.best_dir * bot.feeler_commit_dir) > 0.850))
         {
            bot.best_dir = bot.feeler_commit_dir;
            bot.best_ideal_yaw = vectoyaw (bot.best_dir);
         } //end if
         else
         {
            bot.feeler_commit_dir = bot.best_dir;
            bot.feeler_commit_until = (time + 0.600);
         } //end else
      } //end if
      else
      {
         bot.feeler_commit_dir = bot.best_dir;
         bot.feeler_commit_until = (time + 0.600);
      } //end else
   } //end if
}; //end of the function Bot_Feelers_Evaluate

void (float dist, float mode) Bot_ApplyFeelerMove =
{
   local float move_dist;
   local float strafe_yaw;
   local float alt_yaw;

   move_dist = dist;
   if (self.best_forward_scale)
   {
      move_dist = (dist * self.best_forward_scale);
   } //end if

   self.ideal_yaw = self.best_ideal_yaw;

   if ((self.best_wants_jump && (self.flags & FL_ONGROUND)))
   {
      Bot_tryjump (270.000,dist,FALSE);
   } //end if
   else
   {
      if ((self.best_blocked && self.best_step_ok && (self.flags & FL_ONGROUND)))
      {
         Bot_tryjump (210.000,dist,FALSE);
      } //end if
   } //end else

   strafe_yaw = (self.best_ideal_yaw + self.best_strafe_bias);
   if (!Bot_WalkMove (strafe_yaw,move_dist))
   {
      if (!Bot_WalkMove (self.best_ideal_yaw,move_dist))
      {
         alt_yaw = (self.best_ideal_yaw - self.best_strafe_bias);
         Bot_WalkMove (alt_yaw,(move_dist * 0.800));
      } //end if
   } //end if
}; //end of the function Bot_ApplyFeelerMove

void (float base_yaw) Bot_PickEscapePlan =
{
   Bot_Feelers_Evaluate (self,BOT_MODE_UNSTICK,self.wall_side_pref,base_yaw);
   self.escape_dir = self.best_dir;
   self.last_escape_dir = self.best_dir;
}; //end of the function Bot_PickEscapePlan

void (float reason_code, string reason) Bot_EnterUnstick =
{
   local float base_yaw;
   local float age;
   local float is_loop_break;
   local vector trace_angles;

   if ((self.stuck_mode == BOT_MODE_UNSTICK))
   {
      return ;
   } //end if

   self.unstick_reason_code = reason_code;
   self.unstick_reason = reason;

   // Mark repeated stuck spots as temporary bad zones.
   if ((self.last_stuck_time))
   {
      if (((time - self.last_stuck_time) < 3.000))
      {
         if ((vlen (self.origin - self.last_stuck_origin) < 96.000))
         {
            self.bad_spot_origin = self.origin;
            self.bad_spot_radius = 192.000;
            self.bad_spot_expire_time = (time + 15.000);
         } //end if
      } //end if
   } //end if

   self.last_stuck_origin = self.origin;
   self.last_stuck_time = time;

   self.stuck_mode = BOT_MODE_UNSTICK;
   self.escape_until_time = (time + (0.600 + (random () * 0.600)));
   self.stuck_time = time;
   self.stuck_count = 0;
   self.unstick_start_origin = self.origin;
   self.unstick_start_time = time;
   self.unstick_fail_count = 0.000;
   self.unstick_rethink_time = (time + 0.200);
   self.unstick_rethink_count = 0.000;
   self.wall_side_pref = -1.000;
   if ((random () < 0.500))
   {
      self.wall_side_pref = 1.000;
   } //end if

   base_yaw = self.ideal_yaw;
   if ((self.fg_driver != FG_DRV_NONE) && (vlen (self.fg_goalDir) > 0.000))
   {
      base_yaw = vectoyaw (self.fg_goalDir);
   } //end if
   else if (self.goalentity)
   {
      local vector goal_dir;
      goal_dir = (self.goalentity.origin - self.origin);
      if ((vlen (goal_dir) > 1.000))
      {
         base_yaw = vectoyaw (goal_dir);
      } //end if
   } //end else
   if ((self.hazard_escape_until > time))
   {
      base_yaw = self.hazard_escape_yaw;
   } //end if

   is_loop_break = FALSE;
   if (((reason_code == R_UNSTICK_LOOP) || (time < self.loop_break_until)))
   {
      is_loop_break = TRUE;
   } //end if

   // Record directional failure: this approach got us stuck
   trace_angles_x = 0.000;
   trace_angles_y = base_yaw;
   trace_angles_z = 0.000;
   makevectors (trace_angles);
   RecordDirectionalFail (self,v_forward);

   // === BREADCRUMB BACKTRACKING: Try to recover by retracing steps ===
   // Attempt to find a recent valid position to backtrack to before
   // using feeler-based forward escape plan.
   local vector rescue_spot;
   local vector repeat_spot;
   rescue_spot = Breadcrumb_GetRecoverySpot ();
   if (is_loop_break)
   {
      rescue_spot = self.origin;
   } //end if

   if (self.last_retrace_time)
   {
      if (((time - self.last_retrace_time) < 6.000))
      {
         if ((vlen ((rescue_spot - self.last_retrace_pos)) < 128.000))
         {
            repeat_spot = rescue_spot;
            rescue_spot = self.origin;
            if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
            {
               bprint ("[");
               bprint (self.netname);
               bprint ("] UNSTICK: Skip repeated breadcrumb\n");
            } //end if
            if ((repeat_spot != '0.000 0.000 0.000'))
            {
               self.bad_spot_origin = repeat_spot;
               self.bad_spot_radius = 192.000;
               self.bad_spot_expire_time = (time + 8.000);
            } //end if
         } //end if
      } //end if
   } //end if

   // If we found a valid breadcrumb (not the current origin), enter retrace mode
   if (((rescue_spot != self.origin) && (rescue_spot != '0.000 0.000 0.000')))
   {
      self.is_retracing = TRUE;
      self.old_goal_pos = self.origin;  // Save where we're stuck
      self.last_retrace_pos = rescue_spot;
      self.last_retrace_time = time;

      if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
      {
         bprint ("[");
         bprint (self.netname);
         bprint ("] UNSTICK: Breadcrumb backtrack to ");
         bprint (vtos (rescue_spot));
         bprint (" (dist=");
         bprint (ftos (vlen ((rescue_spot - self.origin))));
         bprint (")\n");
      } //end if

      // Override movement to target the rescue spot
      // We use ideal_yaw to steer toward the breadcrumb
      local vector aim_dir;
      aim_dir = normalize ((rescue_spot - self.origin));
      self.ideal_yaw = vectoyaw (aim_dir);

      return ;  // Skip feeler escape plan, we're backtracking
   } //end if
   // === END BREADCRUMB BACKTRACKING ===

   // If no valid breadcrumb found, use traditional feeler-based escape
   if (is_loop_break)
   {
      base_yaw = (base_yaw + 180.000);
      if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
      {
         bprint ("[");
         bprint (self.netname);
         bprint ("] UNSTICK: Loop escape (feeler)\n");
      } //end if
   } //end if
   Bot_PickEscapePlan (base_yaw);

   if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
   {
      age = (time - self.last_progress_time);
      bprint ("[");
      bprint (self.netname);
      bprint ("] UNSTICK: Enter mode (score=");
      bprint (ftos (self.best_score));
      bprint (", age=");
      bprint (ftos (age));
      bprint (", jump=");
      bprint (ftos (self.best_wants_jump));
      bprint (", tight=");
      bprint (ftos (self.best_tight_gap));
      bprint (", clear=");
      bprint (ftos (self.best_clear_dist));
      bprint (", widen=");
      bprint (ftos (self.best_widen_score));
      bprint (", heat=");
      bprint (ftos (self.best_heat_penalty));
      bprint (")\n");
   } //end if
}; //end of the function Bot_EnterUnstick

// ===== DYNAMIC BREADCRUMBING: Short-Term Position Memory for Backtracking =====
// Records current position into the ring buffer for stuck recovery.
// Rate-limited to 2Hz (every 0.5 seconds) and only records safe positions.
void () Breadcrumb_Update =
{
   // 1. Rate Limit (2Hz is sufficient for 2.5 second history)
   if ((time < self.crumb_timer))
   {
      return ;
   } //end if
   self.crumb_timer = (time + 0.500);

   // 2. Safety Checks - Only record valid, safe positions
   // Don't record if we are in lava, slime, or falling through air
   if (!(self.flags & FL_ONGROUND))
   {
      return ;
   } //end if

   local float content;
   content = pointcontents (self.origin);
   if ((content <= CONTENT_SLIME))
   {
      return ;
   } //end if

   // 3. Write to Buffer (Hardcoded cyclic switch for vanilla QC compatibility)
   // Ring buffer overwrites oldest position when full
   if ((self.crumb_index == 0.000))
   {
      self.crumb_pos_0 = self.origin;
   } //end if
   else
   {
      if ((self.crumb_index == 1.000))
      {
         self.crumb_pos_1 = self.origin;
      } //end if
      else
      {
         if ((self.crumb_index == 2.000))
         {
            self.crumb_pos_2 = self.origin;
         } //end if
         else
         {
            if ((self.crumb_index == 3.000))
            {
               self.crumb_pos_3 = self.origin;
            } //end if
            else
            {
               if ((self.crumb_index == 4.000))
               {
                  self.crumb_pos_4 = self.origin;
               } //end if
            } //end if
         } //end if
      } //end if
   } //end if

   // 4. Advance Index (Wrap around 0-4)
   self.crumb_index = (self.crumb_index + 1.000);
   if ((self.crumb_index > 4.000))
   {
      self.crumb_index = 0.000;
   } //end if
}; //end of the function Breadcrumb_Update

// Find the nearest reachable breadcrumb for stuck recovery.
// Returns position of a recent valid location the bot can backtrack to.
// Prefers crumbs that are visible (LOS check) and not too close (useless).
vector () Breadcrumb_GetRecoverySpot =
{
   local float i;
   local vector cand;
   local float best_dist;
   local vector best_pos;
   local float d;

   best_dist = 9999.000;
   best_pos = self.origin;  // Fallback if no valid crumbs

   // Loop through all 5 crumbs
   // We search for the nearest *reachable* crumb (not necessarily furthest)
   // This safely unwinds the stuck path step-by-step
   i = 0.000;
   while ((i < 5.000))
   {
      // Extract value from ring buffer
      if ((i == 0.000))
      {
         cand = self.crumb_pos_0;
      } //end if
      else
      {
         if ((i == 1.000))
         {
            cand = self.crumb_pos_1;
         } //end if
         else
         {
            if ((i == 2.000))
            {
               cand = self.crumb_pos_2;
            } //end if
            else
            {
               if ((i == 3.000))
               {
                  cand = self.crumb_pos_3;
               } //end if
               else
               {
                  cand = self.crumb_pos_4;
               } //end if
            } //end if
         } //end if
      } //end if

      // Ignore empty/zero vectors (buffer not full yet)
   if ((cand != '0.000 0.000 0.000'))
   {
      if ((self.bad_spot_expire_time > time))
      {
         if ((vlen (cand - self.bad_spot_origin) < self.bad_spot_radius))
         {
               i = (i + 1.000);
               continue;
            } //end if
         } //end if
      if (self.last_retrace_time)
      {
         if (((time - self.last_retrace_time) < 6.000))
         {
            if ((vlen ((cand - self.last_retrace_pos)) < 128.000))
            {
               i = (i + 1.000);
               continue;
            } //end if
         } //end if
         } //end if

         // Check if we can see it (don't path through the wall that stuck us)
         traceline ((self.origin + '0.000 0.000 24.000'),(cand + '0.000 0.000 24.000'),TRUE,self);

         if ((trace_fraction == 1.000))
         {
            d = vlen ((cand - self.origin));

            // We want a crumb that is NOT too close (useless) but reachable
            if (((d > 64.000) && (d < best_dist)))
            {
               best_dist = d;
               best_pos = cand;
            } //end if
         } //end if
      } //end if

      i = (i + 1.000);
   } //end while

   return (best_pos);
}; //end of the function Breadcrumb_GetRecoverySpot

// Find the furthest reachable breadcrumb for loop recovery.
// Prefers a larger rewind to break oscillations (loop-break mode).
vector () Breadcrumb_GetRecoverySpotFar =
{
   local float i;
   local vector cand;
   local float best_dist;
   local vector best_pos;
   local float d;

   best_dist = 0.000;
   best_pos = self.origin;  // Fallback if no valid crumbs

   i = 0.000;
   while ((i < 5.000))
   {
      if ((i == 0.000))
      {
         cand = self.crumb_pos_0;
      } //end if
      else
      {
         if ((i == 1.000))
         {
            cand = self.crumb_pos_1;
         } //end if
         else
         {
            if ((i == 2.000))
            {
               cand = self.crumb_pos_2;
            } //end if
            else
            {
               if ((i == 3.000))
               {
                  cand = self.crumb_pos_3;
               } //end if
               else
               {
                  cand = self.crumb_pos_4;
               } //end if
            } //end if
         } //end if
      } //end else

      if ((cand != '0.000 0.000 0.000'))
      {
         if ((self.bad_spot_expire_time > time))
         {
            if ((vlen (cand - self.bad_spot_origin) < self.bad_spot_radius))
            {
               i = (i + 1.000);
               continue;
            } //end if
         } //end if
      if (self.last_retrace_time)
      {
         if (((time - self.last_retrace_time) < 6.000))
         {
            if ((vlen ((cand - self.last_retrace_pos)) < 128.000))
            {
               i = (i + 1.000);
               continue;
            } //end if
         } //end if
      } //end if

         traceline ((self.origin + '0.000 0.000 24.000'),(cand + '0.000 0.000 24.000'),TRUE,self);
         if ((trace_fraction == 1.000))
         {
            d = vlen ((cand - self.origin));
            if (((d > 96.000) && (d > best_dist)))
            {
               best_dist = d;
               best_pos = cand;
            } //end if
         } //end if
      } //end if

      i = (i + 1.000);
   } //end while

   return (best_pos);
}; //end of the function Breadcrumb_GetRecoverySpotFar
// ===== END BREADCRUMBING =====

void (float dist) Bot_UnstickThink =
{
   local float escape_progress;

   // === BREADCRUMB RETRACE MODE: Exit conditions ===
   if (self.is_retracing)
   {
      if ((self.unstick_reason_code == R_UNSTICK_LOOP))
      {
         // Loop break: keep retracing until timeout or we actually reach the target.
         if ((time > self.escape_until_time))
         {
            self.is_retracing = FALSE;
            self.stuck_mode = BOT_MODE_COOLDOWN;
            self.escape_cooldown_time = (time + 0.600);
            self.stuck_score = 0.000;
            self.last_progress_time = time;
            self.last_origin = self.origin;
            self.progress_check_time = (time + STUCK_PROGRESS_INTERVAL);

            if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
            {
               bprint ("[");
               bprint (self.netname);
               bprint ("] UNSTICK: Breadcrumb retrace complete (vel=");
               bprint (ftos (vlen (self.velocity)));
               bprint (")\n");
            } //end if

            return ;
         } //end if
         if ((vlen ((self.origin - self.last_retrace_pos)) < 48.000))
         {
            self.is_retracing = FALSE;
            self.stuck_mode = BOT_MODE_COOLDOWN;
            self.escape_cooldown_time = (time + 0.600);
            self.stuck_score = 0.000;
            self.last_progress_time = time;
            self.last_origin = self.origin;
            self.progress_check_time = (time + STUCK_PROGRESS_INTERVAL);

            if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
            {
               bprint ("[");
               bprint (self.netname);
               bprint ("] UNSTICK: Breadcrumb retrace complete (vel=");
               bprint (ftos (vlen (self.velocity)));
               bprint (")\n");
            } //end if

            return ;
         } //end if
      } //end if
      else
      {
         // Exit retrace mode if timer expires OR we're moving fast again
         if (((time > self.escape_until_time) || (vlen (self.velocity) > 200.000)))
         {
            self.is_retracing = FALSE;
            self.stuck_mode = BOT_MODE_COOLDOWN;
            self.escape_cooldown_time = (time + 0.600);
            self.stuck_score = 0.000;
            self.last_progress_time = time;
            self.last_origin = self.origin;
            self.progress_check_time = (time + STUCK_PROGRESS_INTERVAL);

            if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
            {
               bprint ("[");
               bprint (self.netname);
               bprint ("] UNSTICK: Breadcrumb retrace complete (vel=");
               bprint (ftos (vlen (self.velocity)));
               bprint (")\n");
            } //end if

            return ;
         } //end if
      } //end else

      // Continue retracing - move toward rescue spot using feelers so we
      // keep steering around obstacles instead of standing still.
      local vector retrace_dir;
      local float retrace_yaw;
      retrace_dir = (self.last_retrace_pos - self.origin);
      retrace_dir_z = 0.000;
      retrace_yaw = self.ideal_yaw;
      if ((vlen (retrace_dir) > 1.000))
      {
         retrace_yaw = vectoyaw (retrace_dir);
      } //end if
      self.ideal_yaw = retrace_yaw;
      CheckForHazards ();
      if ((self.hazard_escape_until > time))
      {
         Bot_HazardEscapeThink (dist);
         return ;
      } //end if
      Bot_Feelers_Evaluate (self,BOT_MODE_UNSTICK,self.wall_side_pref,retrace_yaw);
      Bot_ApplyFeelerMove (dist,BOT_MODE_UNSTICK);
      return ;
   } //end if
   // === END BREADCRUMB RETRACE MODE ===

   self.ideal_yaw = self.best_ideal_yaw;
   CheckForHazards ();
   if ((self.hazard_escape_until > time))
   {
      Bot_HazardEscapeThink (dist);
      return ;
   } //end if

   if (((time >= self.unstick_rethink_time) && ((time - self.last_progress_time) > 0.400)))
   {
      local float base_yaw;
      local vector rescue_spot;

      if ((vlen (self.escape_dir) > 0.010))
      {
         RecordDirectionalFail (self,self.escape_dir);
      } //end if

      self.unstick_rethink_count = (self.unstick_rethink_count + 1.000);
      if ((self.unstick_rethink_count > 3.000))
      {
         self.unstick_rethink_count = 0.000;
      } //end if

      if ((self.unstick_rethink_count == 3.000))
      {
         rescue_spot = Breadcrumb_GetRecoverySpotFar ();
         if (((rescue_spot != self.origin) && (rescue_spot != '0.000 0.000 0.000')))
         {
            self.is_retracing = TRUE;
            self.old_goal_pos = self.origin;
            self.last_retrace_pos = rescue_spot;
            self.last_retrace_time = time;
            self.escape_until_time = (time + 1.200);
            self.bad_spot_origin = self.origin;
            self.bad_spot_radius = 320.000;
            self.bad_spot_expire_time = (time + 20.000);

            if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
            {
               bprint ("[");
               bprint (self.netname);
               bprint ("] UNSTICK: Reroll fallback retrace to ");
               bprint (vtos (rescue_spot));
               bprint ("\n");
            } //end if
            return ;
         } //end if
      } //end if

      base_yaw = self.best_ideal_yaw;
      if ((self.unstick_rethink_count == 1.000))
      {
         base_yaw = (base_yaw + 90.000);
      } //end if
      else
      {
         if ((self.unstick_rethink_count == 2.000))
         {
            base_yaw = (base_yaw - 90.000);
         } //end if
         else
         {
            if ((self.unstick_rethink_count == 3.000))
            {
               base_yaw = (base_yaw + 180.000);
            } //end if
         } //end else
      } //end else

      Bot_PickEscapePlan (base_yaw);
      self.ideal_yaw = self.best_ideal_yaw;
      self.escape_until_time = (time + 0.600);
      self.feeler_commit_dir = self.best_dir;
      self.feeler_commit_until = self.escape_until_time;
      self.unstick_rethink_time = (time + 0.250);

      if ((bot_debug_enabled && (bot_debug_level >= LOG_VERBOSE)))
      {
         bprint ("[");
         bprint (self.netname);
         bprint ("] UNSTICK: Reroll escape yaw=");
         bprint (ftos (self.best_ideal_yaw));
         bprint ("\n");
      } //end if
   } //end if

   // Standard unstick timeout
   if ((time > self.escape_until_time))
   {
      escape_progress = vlen ((self.origin - self.unstick_start_origin));
      if ((escape_progress < 24.000))
      {
         self.unstick_fail_count = (self.unstick_fail_count + 1.000);
         self.unstick_rethink_time = time;
         self.escape_until_time = (time + 0.600);

         if ((self.unstick_fail_count >= 2.000))
         {
            self.bad_spot_origin = self.origin;
            self.bad_spot_radius = 320.000;
            self.bad_spot_expire_time = (time + 20.000);
            clearCache (self);
            FindAPath ();
            self.stuck_mode = BOT_MODE_COOLDOWN;
            self.escape_cooldown_time = (time + 0.600);
            self.stuck_score = 0.000;
            self.last_progress_time = time;
            self.last_origin = self.origin;
            self.progress_check_time = (time + STUCK_PROGRESS_INTERVAL);
            if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
            {
               bprint ("[");
               bprint (self.netname);
               bprint ("] UNSTICK: Timeout without progress, forcing replan\n");
            } //end if
         } //end if
         return ;
      } //end if
      self.unstick_fail_count = 0.000;
      self.stuck_mode = BOT_MODE_COOLDOWN;
      self.escape_cooldown_time = (time + 0.600);
      self.stuck_score = 0.000;
      self.last_progress_time = time;
      self.last_origin = self.origin;
      self.progress_check_time = (time + STUCK_PROGRESS_INTERVAL);
      if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
      {
         bprint ("[");
         bprint (self.netname);
         bprint ("] UNSTICK: Exit to cooldown\n");
      } //end if
      return ;
   } //end if
   Bot_ApplyFeelerMove (dist,BOT_MODE_UNSTICK);
   return ;
}; //end of the function Bot_UnstickThink

void (float dist) Bot_HazardEscapeThink =
{
   local float mode;

   if ((time > self.hazard_escape_until))
   {
      self.hazard_escape_until = 0.000;
      return ;
   } //end if
   mode = BOT_MODE_NORMAL;
   if ((self.stuck_mode == BOT_MODE_UNSTICK))
   {
      mode = BOT_MODE_UNSTICK;
   } //end if
   Bot_Feelers_Evaluate (self,mode,self.wall_side_pref,self.hazard_escape_yaw);
   Bot_ApplyFeelerMove (dist,mode);
   return ;
}; //end of the function Bot_HazardEscapeThink

void (float dist) Bot_ProgressTick =
{
   local float moved;

   if (self.elevator_wait_state)
   {
      self.stuck_score = 0.000;
      self.last_progress_time = time;
      self.last_origin = self.origin;
      self.progress_check_time = (time + STUCK_PROGRESS_INTERVAL);
      return ;
   } //end if

   if ((!self.last_progress_time))
   {
      self.last_origin = self.origin;
      self.last_progress_time = time;
      self.progress_check_time = (time + STUCK_PROGRESS_INTERVAL);
      return ;
   } //end if

   if ((time < self.progress_check_time))
   {
      return ;
   } //end if

   self.progress_check_time = (time + STUCK_PROGRESS_INTERVAL);

   // === BREADCRUMB MAINTENANCE: Record position history for stuck recovery ===
   Breadcrumb_Update ();

   // Check both horizontal and vertical movement (important for stairs!)
   local vector horiz_delta;
   local float horiz_moved;
   local float vert_moved;

   horiz_delta = (self.origin - self.last_origin);
   horiz_delta_z = 0.000;  // Ignore vertical component for horizontal check
   horiz_moved = vlen (horiz_delta);
   vert_moved = fabs ((self.origin_z - self.last_origin_z));

   // Consider progress made if EITHER horizontal OR vertical movement exceeds threshold
   // This prevents false stuck triggers when climbing stairs (vertical progress counts!)
   if (((horiz_moved > STUCK_PROGRESS_DIST) || (vert_moved > STUCK_PROGRESS_VERT)))
   {
      self.last_progress_time = time;
      if ((self.stuck_score > 0.000))
      {
         self.stuck_score = (self.stuck_score - 1.000);
      } //end if
      self.last_origin = self.origin;
      Bot_UpdateRecentPositions (self);
   } //end if
   else
   {
      self.stuck_score = (self.stuck_score + 1.000);
   } //end else

   // Pushing into something: on ground, low speed, but still trying to move.
   if (((self.flags & FL_ONGROUND) && (vlen (self.velocity) < STUCK_PUSH_SPEED) && (dist > STUCK_PUSH_DIST)))
   {
      self.stuck_score = (self.stuck_score + 1.000);
   } //end if

   if ((self.stuck_mode == BOT_MODE_COOLDOWN))
   {
      if ((time > self.escape_cooldown_time))
      {
         self.stuck_mode = BOT_MODE_NORMAL;
         if ((bot_debug_enabled && (bot_debug_level >= LOG_CRITICAL)))
         {
            bprint ("[");
            bprint (self.netname);
            bprint ("] UNSTICK: Cooldown ended\n");
         } //end if
      } //end if
   } //end if

   if ((self.stuck_mode == BOT_MODE_NORMAL))
   {
      if (((self.stuck_score > STUCK_SCORE_THRESH) || ((time - self.last_progress_time) > STUCK_TIME_LIMIT)))
      {
         Bot_EnterUnstick (R_UNSTICK_NO_PROGRESS,"no progress");
      } //end if
   } //end if
}; //end of the function Bot_ProgressTick

// FEELER ESCAPE: 8-direction scan to find clearest path when stuck/lost
// Returns yaw of best-scoring direction (ranked candidates).
float (entity bot, float base_yaw) Bot_FindClearestDirection =
{
   Bot_Feelers_Evaluate (bot,BOT_MODE_NORMAL,0.000,base_yaw);
   return (bot.best_ideal_yaw);
}; //end of the function Bot_FindClearestDirection

// BREADCRUMB WAYPOINTS: Drop exploration trail markers
void () Bot_DropBreadcrumb =
{
   // Use existing SpawnSavedWaypoint function to create breadcrumb
   // Mark with low traffic score (0.1) to distinguish from main routes
   SpawnSavedWaypoint (self.origin,0.100,0.000,"");

   // Update last breadcrumb position
   self.last_breadcrumb_pos = self.origin;

   // Debug logging (toggle with impulse 97)
   if (bot_debug_feeler)
   {
      bprint ("[");
      bprint (self.netname);
      bprint ("] BREADCRUMB: Dropped at ");
      bprint (vtos (self.origin));
      bprint ("\n");
   } //end if
}; //end of the function Bot_DropBreadcrumb

// ===== END FEELER STEERING =====

void (float dist) Botmovetogoal =
{
   local entity Botgoal;
   local float wlevel;

   self.oldorigin = self.origin;

   // ===== PHASE 11: WATER SURVIVAL CHECK (Drowning Prevention) =====
   // Check if bot is underwater and running out of air, force surface if needed.
   // This prevents bots from suffocating in deep water zones.
   CheckWaterSurvival ();
   // =============================================================

   if (((self.stuck_mode != BOT_MODE_UNSTICK) && (time < self.intent_request_until) && (self.intent_request == BOT_INTENT_HOLD)))
   {
      if ((self.bot_intent != BOT_INTENT_HOLD))
      {
         self.bot_intent = BOT_INTENT_HOLD;
         self.bot_intent_start = time;
         self.bot_intent_fail = 0.000;
      } //end if
      self.stuck_score = 0.000;
      self.last_progress_time = time;
      self.last_origin = self.origin;
      self.progress_check_time = (time + STUCK_PROGRESS_INTERVAL);
      return ;
   } //end if

   // ===== DYNAMIC STUCK WIGGLE: Micro-Jump on Velocity Stall =====
   // If the bot is trying to move but velocity is near zero, don't wait 1 second.
   // Try an immediate micro-jump to clear small geometry lips/steps.
   // This prevents bots from standing still for a full second before reacting.
   if (((vlen (self.velocity) < 10.000) && (self.flags & FL_ONGROUND)))
   {
      // Try a micro-jump (20% chance to avoid spamming every frame)
      if (((time > self.wiggle_jump_time) && ((time - self.last_progress_time) > 0.500) && (self.stuck_mode == BOT_MODE_NORMAL) && (random () < 0.150)))
      {
         self.velocity_z = 220.000;  // Small hop
         sound (self,CHAN_BODY,"player/plyrjmp8.wav",1.000,ATTN_NORM);
         self.wiggle_jump_time = (time + 0.600);
      } //end if
   } //end if
   // ===== END DYNAMIC STUCK WIGGLE =====

   // Progress-based stuck detection + unstick mode commit window
   Bot_ProgressTick (dist);

   // ===== FLOW GOVERNOR: Release expired control =====
   // Reset governor state if current driver's commit has expired
   FG_Tick (self);
   // =============================================================

   // ===== BEHAVIORAL LOOP DETECTION =====
   // Push current state signature to buffer (every 0.25s)
   Loop_PushSig (self);

   // ===== TERRAIN TRAP RESOLVER: FIRST failsafe layer =====
   // Detects movement pathologies (shallow water, lips, micro-basins, greebles)
   // and hard-overrides intent/navigation to escape. Runs BEFORE loop breaker
   // because terrain traps can cause loops (but not all loops are terrain traps).
   Bot_HandleTerrainTrap (self);

   // Detect and break repetitive behavioral loops
   Loop_BreakLoop (self);
   // =============================================================

   // ===== FLOW GOVERNOR: Driver Requests (Priority Order) =====
   // Each driver evaluates its condition and requests control if needed.
   // Governor grants control to highest priority driver with active request.
   // Priority order (highest first):
   //   100 - Terrain Trap (already called above)
   //    90 - Loop Breaker (already called above)
   //    80 - Vertical Reposition
   //    60 - Intent Director

   // Vertical Reposition Driver (pri 80)
   VT_Driver (self);

   // Intent Director Driver (pri 60)
   Intent_Driver (self);
   // =============================================================

   if ((self.stuck_mode == BOT_MODE_UNSTICK))
   {
      Bot_UnstickThink (dist);
      return ;
   } //end if

   // ===== SHALLOW WATER TRAP ESCAPE =====
   // Only check if bot is actually in water to avoid frame budget overhead
   // Detects ankle-water boundary oscillation (DM2 water exit, etc.)
   if ((self.waterlevel > 0.000))
   {
      HandleWaterTrap (self);
   } //end if
   // =============================================================

   Botgoal = self.goalentity;

   // ===== FLOW GOVERNOR: Route + Roam requests =====
   // Ensure routing/roam intent participates in arbitration.
   if ((Botgoal && (Botgoal != world)))
   {
      local vector aim_point;
      local vector nav_dir;

      // ===== SMOOTHING: The "Racing Line" (Corner Smoothing) =====
      // Pro players don't hit waypoints then turn 90°. They "cut the corner,"
      // starting the turn before reaching the waypoint by blending aim toward next node.
      aim_point = Botgoal.origin;
      if ((vlen (self.origin - Botgoal.origin) < 120.000))
      {
         if (Botgoal.target)
         {
            local entity next_node;
            next_node = find (world,targetname,Botgoal.target);
            if (next_node)
            {
               // Blend our aim: 70% current node, 30% next node.
               // This causes the bot to curve into the turn early.
               aim_point = ((Botgoal.origin * 0.700) + (next_node.origin * 0.300));
            } //end if
         } //end if
      } //end if
      // =======================================

      nav_dir = (aim_point - self.origin);
      FG_Request (self,40.000,FG_DRV_ROUTE,nav_dir,0.200);
   } //end if
   else
   {
      local vector roam_dir;

      roam_dir = self.velocity;
      if ((vlen (roam_dir) < 1.000))
      {
         makevectors (self.angles);
         roam_dir = v_forward;
      } //end if
      FG_Request (self,20.000,FG_DRV_ROAM,roam_dir,0.200);
   } //end else

   // ===== FLOW GOVERNOR: Use driver goal if active =====
   // If a driver has control, use its goal direction instead of waypoint nav
   if ((self.fg_driver != FG_DRV_NONE))
   {
      // Driver is active: use Flow Governor goal direction
      self.ideal_yaw = vectoyaw (self.fg_goalDir);
   } //end if
   // ============================================================

   // ===== FEELER STEERING: Movement Polish and Exploration =====
   local float base_yaw;
   local float yaw_bias;
   local float dt;
   local entity nearest_waypoint;
   local float nearest_dist;
   local float check_dist;

   base_yaw = self.ideal_yaw;  // Save goal direction
   dt = 0.100;  // Assume 10 Hz think rate

   // Apply feeler steering (corridor centring, cornering, collision avoidance)
   yaw_bias = Bot_SampleFeelers (self,base_yaw,dt);
   self.ideal_yaw = (base_yaw + yaw_bias);

   // Calculate distance to nearest waypoint (used for exploration activation/deactivation)
   nearest_waypoint = find (world,classname,"BotPath");
   nearest_dist = 999999.000;

   while (nearest_waypoint)
   {
      check_dist = vlen ((nearest_waypoint.origin - self.origin));
      if ((check_dist < nearest_dist))
      {
         nearest_dist = check_dist;
      } //end if
      nearest_waypoint = find (nearest_waypoint,classname,"BotPath");
   } //end while

   // Check if we should activate exploration mode (no nearby waypoints)
   if ((!self.feeler_mode_active && (nearest_dist > 128.000)))
   {
      self.feeler_mode_active = TRUE;
      self.feeler_start_time = time;

      // Debug logging (toggle with impulse 97)
      if (bot_debug_feeler)
      {
         bprint ("[");
         bprint (self.netname);
         bprint ("] FEELER: Exploration mode activated (no waypoints nearby)\n");
      } //end if
   } //end if

   // If in exploration mode, use 8-direction scan for exit finding
   if (self.feeler_mode_active)
   {
      local float clear_yaw;
      local float crumb_dist;

      clear_yaw = Bot_FindClearestDirection (self,base_yaw);
      self.ideal_yaw = clear_yaw;

      // Drop breadcrumb waypoint if we've moved far enough
      crumb_dist = vlen ((self.origin - self.last_breadcrumb_pos));
      if (((crumb_dist > 64.000) || (self.last_breadcrumb_pos == '0.000 0.000 0.000')))
      {
         Bot_DropBreadcrumb ();
      } //end if

      // Debug logging (toggle with impulse 97)
      if (bot_debug_feeler)
      {
         bprint ("[");
         bprint (self.netname);
         bprint ("] FEELER: Clearest direction = ");
         bprint (ftos (clear_yaw));
         bprint ("°\n");
      } //end if

      // Deactivate if we found waypoints or timeout (10 seconds)
      if (((nearest_dist < 64.000) || ((time - self.feeler_start_time) > 10.000)))
      {
         self.feeler_mode_active = FALSE;

         // Debug logging (toggle with impulse 97)
         if (bot_debug_feeler)
         {
            bprint ("[");
            bprint (self.netname);
            bprint ("] FEELER: Exploration mode deactivated\n");
         } //end if
      } //end if
   } //end if
   // ===== END FEELER STEERING =====

   // ===== PHASE 9: PROACTIVE HAZARD CHECK (Before Movement) =====
   // Check ground ahead for gaps, lava, and death pits BEFORE committing to movement.
   // This prevents bots from casually walking into hazards (Layer 1 - Prevention).
   // Phase 4's mid-air system (Layer 2) handles aerial hazards during flight.
   CheckForHazards ();
   if (((self.hazard_escape_until > time) && (self.stuck_mode != BOT_MODE_UNSTICK)))
   {
      Bot_HazardEscapeThink (dist);
      return ;
   } //end if
   // =============================================================

   // ===== TRAVERSAL STRAFE-JUMPING =====
   if (Bot_TraversalStrafe (dist,self.ideal_yaw))
   {
      Bot_SmoothTurn ();
      return ;
   } //end if
   // ===== END TRAVERSAL STRAFE-JUMPING =====

   // DYNAMIC YAW SPEED (Analog Turning - See Section 3)
   Bot_SmoothTurn ();

   // ===== ACTION BREADCRUMBS: Execute Jump (The "Trigger") =====
   // Check the scent of the node we are running towards.
   if (Botgoal.action_flag == 1) // It's a JUMP Node!
   {
      local float d;
      d = vlen(Botgoal.origin - self.origin);

      // Are we close enough to the "Takeoff Point"? (within 64 units)
      if (d < 64)
      {
         // Do we have a clear shot?
         // (Optional: Look straight at goal to ensure jump trajectory)
         self.ideal_yaw = vectoyaw (Botgoal.origin - self.origin);
         Bot_RequestAim (self.ideal_yaw,0.000,TRUE,FALSE,AIM_OWNER_NAV,R_NONE,"jump node");

         // EXECUTE JUMP
         // We use the standard jump velocity (270)
         // But we assume the node was placed at a valid jump spot by the player.
         if (self.flags & FL_ONGROUND)
         {
            self.velocity_z = 270;
            self.flags = self.flags - FL_ONGROUND;

            // Bot talk: "Hup!"
            if (random() < 0.1) sound(self, CHAN_VOICE, "player/plyrjmp8.wav", 1, ATTN_NORM);
         }
      }
   }
   // =======================================

   // ===== PHASE 6: SMART TRIGGERS (Proactive Button->Door Solving) =====
   // Check if the waypoint we're approaching has a target link (e.g., button)
   if (Botgoal.target != "")
   {
      local entity trig_ent;
      // Find the entity with matching targetname
      trig_ent = find (world,targetname,Botgoal.target);

      // If we found a button that hasn't been pressed yet
      if ((trig_ent.classname == "func_button"))
      {
         if ((trig_ent.state == STATE_BOTTOM))
         {
            // Do we have line of sight to the button?
            traceline ((self.origin + self.view_ofs),trig_ent.origin,TRUE,self);

            if ((trace_fraction == 1.000))
            {
               // AIM at the button (look up/down and left/right)
               self.ideal_yaw = vectoyaw ((trig_ent.origin - self.origin));
               // Note: pitch aiming would use vectoangles for full 3D aim
               // For now, yaw is enough for most buttons
               Bot_RequestAim (self.ideal_yaw,0.000,TRUE,FALSE,AIM_OWNER_NAV,R_TRIGGER_BUTTON,"button aim");

               // SHOOT! (If attack is ready)
               if ((time > self.attack_finished))
               {
                  self.button0 = 1.000;  // Press fire button
               } //end if
            } //end if
         } //end if
      } //end if
   } //end if
   // ===================================================

   // ===== ELEVATOR SYSTEM: Wait State Management =====
   // Enhanced elevator patience with proper WAIT_NODE detection and timeout handling.
   // Replaces old platform_node check with comprehensive elevator wait state.
   if ((Botgoal.node_type == NODE_WAIT))
   {
      local entity plat;
      plat = Botgoal.platform_entity;

      if (!plat)
      {
         // Error: WAIT_NODE has no platform linked
         // Abandon this goal and replan
         FindAPath ();
         return ;
      } //end if

      // Check if platform is present at boarding position
      if (!IsPlatformAt (plat,Botgoal.platform_board_pos))
      {
         // Platform absent - enter WAIT state

         if (!self.elevator_wait_state)
         {
            // Just started waiting - initialize wait state
            self.elevator_wait_state = TRUE;
            self.elevator_wait_node = Botgoal;
            self.elevator_wait_start = time;

            // Debug log (LOG_TACTICAL level)
            if (((bot_debug_enabled && (bot_debug_level >= LOG_TACTICAL))))
            {
               bprint ("[");
               bprint (self.netname);
               bprint ("] ELEVATOR: Waiting at ");
               bprint (vtos (Botgoal.origin));
               bprint ("\n");
            } //end if
         } //end if

         // Wait behavior
         self.velocity = '0.000 0.000 0.000';  // Stop movement
         Bot_RequestAim (0.000,-45.000,FALSE,TRUE,AIM_OWNER_NAV,R_NAV_ROAM,"elevator wait");

         // Reset stuck timers (this is an intentional wait, not stuck)
         self.stuck_count = 0.000;
         self.stuck_time = 0.000;
         self.stuck_score = 0.000;
         self.stuck_mode = BOT_MODE_NORMAL;
         self.last_progress_time = time;
         self.last_origin = self.origin;
         self.progress_check_time = (time + STUCK_PROGRESS_INTERVAL);

         // Timeout check - prevent infinite waits (30 second limit)
         if (((time - self.elevator_wait_start) > 30.000))
         {
            // Waited too long - replan route (find alternate path)
            if (((bot_debug_enabled && (bot_debug_level >= LOG_TACTICAL))))
            {
               bprint ("[");
               bprint (self.netname);
               bprint ("] ELEVATOR: Timeout (");
               bprint (ftos (time - self.elevator_wait_start));
               bprint ("s), replanning\n");
            } //end if

            // Avoid immediately re-selecting this wait node.
            self.bad_spot_origin = Botgoal.origin;
            self.bad_spot_radius = 256.000;
            self.bad_spot_expire_time = (time + 15.000);

            self.elevator_wait_state = FALSE;
            FindAPath ();  // Force re-pathfind (A* will skip this elevator now)
         } //end if

         return ;  // Don't move while waiting
      } //end if

      // Platform arrived!
      if (self.elevator_wait_state)
      {
         // Reset wait state - platform is here, proceed normally
         self.elevator_wait_state = FALSE;

         // Debug log
         if (((bot_debug_enabled && (bot_debug_level >= LOG_TACTICAL))))
         {
            local float wait_duration;
            wait_duration = (time - self.elevator_wait_start);

            bprint ("[");
            bprint (self.netname);
            bprint ("] ELEVATOR: Boarding (waited ");
            bprint (ftos (wait_duration));
            bprint ("s)\n");
         } //end if
      } //end if

      // Platform present - proceed with normal movement
   } //end if
   // ===== OLD PLATFORM MASTERY: Legacy fallback for is_platform_node =====
   // Kept for backwards compatibility with manually-placed platform waypoints
   // that don't have node_type set. Will be phased out as maps migrate to
   // NODE_WAIT/NODE_EXIT system.
   else if (Botgoal.is_platform_node)
   {
      // Is the node significantly above us? (> 64 units)
      if ((Botgoal.origin_z > (self.origin_z + 64.000)))
      {
         // Are we close to the shaft? (Horizontal distance < 200)
         local vector flat_dist;
         flat_dist = (Botgoal.origin - self.origin);
         flat_dist_z = 0.000;

         if ((vlen (flat_dist) < 200.000))
         {
            // We are at the lift shaft. WAIT here.
            self.velocity = '0.000 0.000 0.000';

            // Look UP at the lift (human behavior)
            Bot_RequestAim (0.000,-45.000,FALSE,TRUE,AIM_OWNER_NAV,R_NAV_ROAM,"lift wait");

            // Reset stuck timers so we don't panic-teleport
            self.stuck_time = 0.000;
            self.stuck_count = 0.000;
            self.stuck_score = 0.000;
            self.stuck_mode = BOT_MODE_NORMAL;
            self.last_progress_time = time;
            self.last_origin = self.origin;
            self.progress_check_time = (time + STUCK_PROGRESS_INTERVAL);

            return ;
         } //end if
      } //end if
   } //end if
   // ===== END ELEVATOR SYSTEM =====

   // ===== PROBLEM SOLVER: Execute Vertical Solve (Rocket Jump for High Items) =====
   // Check if we are near the goal but it's above us (The "Quad Ledge" Scenario)
   local float vert_dist;
   local float horiz_dist;
   vert_dist = (self.goalentity.origin_z - self.origin_z);
   horiz_dist = vlen ((self.goalentity.origin - self.origin));
   // If target is close horizontally (<100) but high vertically (>60)
   // REFACTOR: Increased horiz_dist from 100 to 300 to allow RJs from further away
   if ((horiz_dist < 300.000))
   {
      if ((vert_dist > 60.000))
      {
         // Do we have the tool?
         if ((self.items & IT_ROCKET_LAUNCHER))
         {
            if ((self.ammo_rockets >= 1.000))
            {
               if ((self.health > 50.000))
               {
                  // Check cooldown
                   if ((time > self.rj_cooldown))
                   {
                      if ((self.flags & FL_ONGROUND))
                      {
                         // Execute rocket jump!
                         // Look straight DOWN (NEGATIVE pitch = down, positive = up!)
                         local vector aim_angles;
                         local vector aim_dir;
                         aim_angles = self.angles;
                         aim_angles_x = -80.000;
                         aim_angles_z = 0.000;
                         makevectors (aim_angles);
                         aim_dir = v_forward;
                         Bot_RequestAim (0.000,-80.000,FALSE,TRUE,AIM_OWNER_NAV,R_NONE,"vertical solve");
                         self.botaim_override = aim_dir;
                         self.botaim_override_active = TRUE;
                         // Fire!
                         W_FireRocket ();
                         self.botaim_override_active = FALSE;
                         self.botaim_override = '0.000 0.000 0.000';
                         // Jump!
                         self.velocity_z = 300.000;
                         // Reset cooldown
                         self.rj_cooldown = (time + 2.000);
                         return ;
                      } //end if
                   } //end if
                } //end if
             } //end if
         } //end if
      } //end if
   } //end if
   // ===== END PROBLEM SOLVER: Vertical Solve =====

   // ===== TWEAK #2: Platform/train movement prediction (velocity → path chain) =====
   // Predicts where moving platforms will be when bot arrives. For func_plat, uses state-based
   // prediction (pos1/pos2). For func_train, uses path_corner chain traversal via predict_train_pos
   // to follow the train's actual route through its waypoint network—enables precise timing for
   // complex multi-segment train paths instead of blind velocity guessing.
   entity g_ent;
   g_ent = Botgoal.goalentity;
   if ((g_ent && ((g_ent.classname == "func_plat") || (g_ent.classname == "func_train"))))
   {
      local vector pred_pos;
      local float travel_time;
      local float dist_to_goal;

      dist_to_goal = vlen ((Botgoal.origin - self.origin));
      travel_time = (dist_to_goal / 200.000);  // Bot speed ~200 u/s

      // For trains: use path_corner chain prediction (accurate multi-segment pathing)
      if ((g_ent.classname == "func_train"))
      {
         pred_pos = predict_train_pos(g_ent, travel_time);
      }
      else
      {
         // For plats: use velocity-based prediction with state adjustments
         pred_pos = (g_ent.origin + (g_ent.velocity * travel_time));

         // Adjust for plat state if known (pos1=bottom, pos2=top)
         // STATE_UP=1 (moving to top), STATE_DOWN=2 (moving to bottom)
         if ((g_ent.state == STATE_UP))
         {
            pred_pos = g_ent.pos2;  // Will be at top when bot arrives
         } //end if
         else if ((g_ent.state == STATE_DOWN))
         {
            pred_pos = g_ent.pos1;  // Will be at bottom
         } //end if
      }

      // Re-aim at predicted position instead of current static origin—creates timing magic
      self.ideal_yaw = vectoyaw ((pred_pos - self.origin));
      Bot_RequestAim (self.ideal_yaw,0.000,TRUE,FALSE,AIM_OWNER_NAV,R_NAV_ROAM,"platform predict");
   } //end if
   // ===== END TWEAK #2 =====

   if ((self.flags & FL_INWATER))
   {
      wlevel = CheckWaterLevel ();
      if ((wlevel > SPAWNFLAG_SUPERSPIKE))
      {
         BotUnderwaterMove ((dist * 0.800),wlevel);
         return ;
      } //end if
   } //end if
   if ((Botgoal.goalentity.classname == "trigger_push"))
   {
      BotmovetoWindTunnel (dist);
      return ;
   } //end if
   if (Spotvisible (Botgoal))
   {
      BotmovetoVisiblegoal (dist);
      return ;
   } //end if
   if (testmove (dist))
   {
      // Movement succeeded—reset stuck counter on progress
      self.stuck_count = 0;
      self.stuck_score = 0.000;
      self.last_progress_time = time;
      self.last_origin = self.origin;
      self.progress_check_time = (time + STUCK_PROGRESS_INTERVAL);
      return ;
   } //end if

   // ===== TWEAK #3: Stuck rotate + cache nuke (multi-angle escape) =====
   // Aggressive unstuck: cycles retry counter (0-7), rotates ideal_yaw in 45° increments
   // after 3 failed attempts, and nukes route cache on loop-back to force fresh pathfinding.
   // Prevents corner-stuck "moron loops" where bot repeatedly tries same blocked angle.
   self.stuck_count = (self.stuck_count + 1);
   if ((self.stuck_count >= 8))
   {
      self.stuck_count = 0;  // Wrap to 0 after 7
   } //end if

   if ((self.stuck_count > 3))
   {
      // More than 3 stuck attempts—start aggressive angle rotation
      // Rotate ideal_yaw by 45° × (attempts - 3) to explore new directions
      // Example: attempt 4 = +45°, attempt 5 = +90°, attempt 6 = +135°, attempt 7 = +180°
      self.ideal_yaw = (self.ideal_yaw + (45.000 * (self.stuck_count - 3)));
      Bot_RequestAim (self.ideal_yaw,0.000,TRUE,FALSE,AIM_OWNER_NAV,R_UNSTICK_NO_PROGRESS,"stuck rotate");

      if ((self.stuck_count == 7))
      {
         // Maximum stuck count reached—nuke route cache and force full replan
         // This clears all cached paths forcing the bot to recalculate from scratch
         clearCache (self);
         self.stuck_count = 0;  // Reset counter after cache clear
      } //end if
      return ;  // Exit after rotation attempt—let next think cycle test new angle
   } //end if
   // ===== END TWEAK #3 =====

   // ===== TWEAK #3b: Button wait door-open check (persistent wait → early proceed) =====
   // Monitors door state after shooting button—if door opens (becomes non-solid), clear wait
   // timer early so bot proceeds immediately instead of waiting full 2s. Fluid progression.
   if (((self.button_wait_time > time) && (Botgoal.goalentity.classname == "func_door")))
   {
      if ((pointcontents (Botgoal.goalentity.origin) != CONTENT_SOLID))
      {
         self.button_wait_time = 0;  // Door opened—proceed immediately
      } //end if
   } //end if
   // ===== END TWEAK #3b =====

   strafemove ((dist * 0.800));
   return ;
}; //end of the function Botmovetogoal

void () Bot_MoveControllerApply =
{
   local float dist;
   local float apply_mode;

   self.move_apply_active = TRUE;

   dist = self.move_speed;
   if ((dist <= 0.000))
   {
      dist = BOTSPEED;
   } //end if

   apply_mode = self.move_mode;
   if ((self.stuck_mode == BOT_MODE_UNSTICK))
   {
      if (((apply_mode == BOT_MOVE_NONE) || (apply_mode == BOT_MOVE_STAND)))
      {
         apply_mode = BOT_MOVE_RUN;
      } //end if
   } //end if

   if ((apply_mode == BOT_MOVE_STAND))
   {
      ai_botstand ();
   } //end if
   else if ((apply_mode == BOT_MOVE_SEEK))
   {
      ai_botseek (dist);
   } //end if
   else if ((apply_mode == BOT_MOVE_RUN))
   {
      ai_botrun (dist);
   } //end if
   else if ((apply_mode == BOT_MOVE_CHASE))
   {
      aibot_chase (dist);
   } //end if
   else if ((apply_mode == BOT_MOVE_CHARGE))
   {
      ai_botcharge (dist);
   } //end if
   else if ((apply_mode == BOT_MOVE_NAILCHARGE))
   {
      ai_botnailcharge (dist);
   } //end if
   else
   {
      ai_botstand ();
   } //end else

   self.move_apply_active = FALSE;
}; //end of the function Bot_MoveControllerApply
