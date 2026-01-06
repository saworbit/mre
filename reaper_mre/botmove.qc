// Forward declaration for enhanced rocket jump (used in Bot_tryjump before definition)
float() bot_rocket_jump;
// Forward declaration for problem solver (defined in bot_ai.qc)
entity(entity door_ent) FindButtonForDoor;
// Forward declaration for breadcrumb waypoints (defined in botroute.qc)
void(vector org, float traffic, float danger, string trig_target) SpawnSavedWaypoint;
// Forward declaration for live learning RJ waypoints (defined in botroute.qc)
void(vector org, vector angles, float velocity_gain, string rj_type_str) SpawnLearnedRJ_Live;

// PHASE 4 REFACTOR: CanRocketJumpHeight, CanCrossGap moved to botmath.qc

void () halfwalkmove =
{
   walkmove (self.strafeyaw,self.strafedist);
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
   if (!walkmove (s_yaw,halfdist))
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
// detects cycles with first_corner tracking, and limits to 64 segments for safety.
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

   // First pass: accumulate total chain distance (for cycling)
   while (curr && seg_count < 64) {  // PHASE 4 FIX: Max 64 segments (was 16) for complex train paths
      next_pos = curr.origin;
      seg_dist = vlen(next_pos - last_pos);
      total_dist = (total_dist + seg_dist);

      last_pos = next_pos;
      curr = find(world, targetname, curr.target);
      if (curr == first_corner) break; // Loop detected: stop to avoid infinite
      seg_count = (seg_count + 1);
   }

   if (total_dist == 0) return train.origin; // No path length? Static

   // Modulo time for cycling paths
   t_mod = t_future - (floor(t_future / (total_dist / train_speed)) * (total_dist / train_speed));
   local float dist_future = train_speed * t_mod;

   // Second pass: traverse to find interpolated position
   curr = first_corner; // Reset to start
   last_pos = train.origin;
   dist_accum = 0;
   seg_count = 0;

   while (curr && seg_count < 64) {  // PHASE 4 FIX: Max 64 segments (was 16)
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
   if (!FacingIdeal ())
   {
      ChangeYaw ();
      if (!FacingIdeal ())
      {
         ChangeYaw ();
         if (!FacingIdeal ())
         {
            ChangeYaw ();
         } //end if
      } //end if
   } //end if
   makevectors (self.angles);
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
   while (NOTLAND)
   {
      tvel = (tvel - GRAVITY);
      newbottom = (bottom + (jumpv * 0.100));
      newbottom_z = (newbottom_z + (tvel * 0.100));
      traceline (bottom,newbottom,SPAWNFLAG_SUPERSPIKE,self);
      frac = trace_fraction;

      // ===== TWEAK #2: Jump arc platform collision (ground sim → mid-air predict) =====
      // Detects platforms during jump arc simulation so bots recognize plats/trains as
      // valid landing surfaces—enables precise platform timing without ground-only bias.
      // Re-traces downward to confirm solid surface (not edge/lip) before accepting.
      if (((trace_ent.classname == "func_plat") || (trace_ent.classname == "func_train")))
      {
         // Hit platform surface during arc—verify it's solid collision (not edge)
         traceline (bottom,(bottom - '0.000 0.000 8.000'),TRUE,self);
         if ((trace_fraction < 1.000))
         {
            // Platform is reachable via jump—treat as valid landing
            return (TRUE);
         } //end if
      } //end if
      // ===== END TWEAK #2 =====

      if ((trace_fraction == SPAWNFLAG_SUPERSPIKE))
      {
         newtop = newbottom;
         top = bottom;
         top_z = (top_z + ht);
         newtop_z = (newtop_z + ht);
         traceline (top,newtop,SPAWNFLAG_SUPERSPIKE,self);
         if ((trace_fraction == SPAWNFLAG_SUPERSPIKE))
         {
            traceline (newbottom,newtop,SPAWNFLAG_SUPERSPIKE,self);
         } //end if
         if ((trace_fraction == SPAWNFLAG_SUPERSPIKE))
         {
            top = (top + (SECRET_YES_SHOOT * v_right));
            newtop = (newtop + (SECRET_YES_SHOOT * v_right));
            traceline (top,newtop,SPAWNFLAG_SUPERSPIKE,self);
         } //end if
         if ((trace_fraction == SPAWNFLAG_SUPERSPIKE))
         {
            top = (top - (DOOR_TOGGLE * v_right));
            newtop = (newtop - (DOOR_TOGGLE * v_right));
            traceline (top,newtop,SPAWNFLAG_SUPERSPIKE,self);
         } //end if
         if ((trace_fraction != SPAWNFLAG_SUPERSPIKE))
         {
            frac = 0.100;
         } //end if
      } //end if
      if ((trace_fraction != SPAWNFLAG_SUPERSPIKE))
      {
         dir = normalize ((newbottom - bottom));
         len = vlen ((newbottom - bottom));
         newbottom = (bottom + ((dir * len) * frac));
         newbottom_z = (newbottom_z + LOOPTIME);
         if (!checkLanding ((newbottom - (SECRET_YES_SHOOT * v_forward))))
         {
            return (FALSE);
         } //end if
         NOTLAND = FALSE;
      } //end if
      if (NOTLAND)
      {
         if (CheckLavaOrLow (newbottom))
         {
            return (FALSE);
         } //end if
      } //end if
      lnd = pointcontents (newbottom);
      if ((lnd == CONTENT_WATER))
      {
         NOTLAND = FALSE;
      } //end if
      bottom = newbottom;
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
   local vector old_angles;
   local vector jumpv;
   local vector dir;
   local float dist;
   local float pitch_aim;

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

   // Save current view to restore later
   old_angles = self.angles;

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

         // Optional: Print debug message
         // bprint(self.netname);
         // bprint(" using learned RJ: pitch=");
         // bprint(ftos(pitch_aim));
         // bprint("\n");

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

   // 4. Set Aim Angles
   // Pitch: look down/back based on calculated need
   self.angles_x = pitch_aim;

   // Yaw: Face exactly OPPOSITE to the target direction
   // This ensures the explosion pushes us directly toward the goal
   self.angles_y = (vectoyaw(dir) + 180.000);

   ChangePitch ();
   ChangeYaw ();

   // 5. Execute Sequence
   makevectors (self.angles);
   W_FireRocket (); // Fire at the calculated angle

   // Synchronized jump to catch blast
   // Base vertical jump + heavy kick from the explosion direction
   jumpv = '0.000 0.000 270.000';

   // Add forward momentum relative to where we want to go (v_forward is pointing back)
   // We invert v_forward because we are looking backwards
   // AGGRESSIVE LEAP: Tripled from -120 to -320 (running speed) to clear wide gaps like DM2 Quad
   jumpv = (jumpv + (v_forward * -320.000));

   Botjump (jumpv);

   // 6. Cleanup
   // Restore original aim immediately so bot doesn't lose track of enemies
   self.angles = old_angles;
   ChangePitch ();
   ChangeYaw ();

   // Set cooldown (prevents spam) and reset stuck counter (successful escape)
   self.rj_cooldown = (time + 2.000);
   self.stuck_count = 0;

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

   // Only check if we are on the ground
   if (!(self.flags & FL_ONGROUND))
   {
      return ;
   } //end if

   // 1. Look ahead (based on ideal_yaw - where bot is trying to move)
   makevectors (self.angles);
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
         // STOP! Don't run in!
         self.velocity = '0.000 0.000 0.000';
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
         self.button2 = 1.000;  // Try to jump over it
      } //end if
   } //end if
}; //end of the function CheckForHazards
// ===== END PHASE 9: GROUND HAZARD DETECTION =====

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
            self.velocity_z = 200;

            // Look up slightly to assist physics engine
            self.v_angle_x = -45;

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
      walkmove (self.ideal_yaw,dist);
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
   if (walkmove ((self.ideal_yaw + ofs),dist))
   {
      return ;
   } //end if

   // ===== STAIR SMOOTHING: The "Step Up" =====
   // If blocked, check if it's just a low step (stairs/debris).
   // Trace 22 units (above step height) to see if path is clear at knee level.
   local vector step_trace_dest;
   local vector dir;
   local float angle_rad;

   // Calculate direction vector from ideal_yaw + ofs
   angle_rad = ((self.ideal_yaw + ofs) * (3.14159 / 180.000)); // Convert to radians

   // Manual vector construction (QuakeC doesn't have cos/sin, use makevectors workaround)
   self.angles_y = (self.ideal_yaw + ofs);
   makevectors(self.angles);
   dir = v_forward;
   dir_z = 0.000;
   dir = normalize(dir);

   step_trace_dest = (self.origin + (dir * dist));
   step_trace_dest_z = (self.origin_z + 22.000); // Check slightly above standard step height (18)

   // Trace forward at knee height
   traceline((self.origin + '0.000 0.000 22.000'), step_trace_dest, TRUE, self);

   if ((trace_fraction == 1.000))
   {
      // Knee-height is clear! The blockage is below our knees (a step).
      // Nudge the bot UP so it can slide over it.
      // We don't jump (too high), we just pop velocity to clear the friction.
      if ((self.flags & FL_ONGROUND))
      {
         self.velocity_z = 210.000; // Small hop (just enough to clear stairs)
         self.flags = (self.flags - FL_ONGROUND);
         return ;
      } //end if
   } //end if
   // =======================================

   // --- SLIDE LOGIC #1 (from Step 4) ---
   self.angles_y = self.ideal_yaw + ofs;
   makevectors(self.angles);
   org_start = self.origin;
   traceline(org_start, org_start + (v_forward * 16), TRUE, self);

   if (trace_fraction < 1.0)
   {
       move_dir = v_forward;
       wall_normal = trace_plane_normal;
       slide_dir = move_dir - (wall_normal * (move_dir * wall_normal));
       slide_dir = normalize(slide_dir);
       slide_yaw = vectoyaw(slide_dir);
       if (walkmove(slide_yaw, dist)) return ;

       // ===== PROBLEM SOLVER: Obstacle Solver (Door/Button Logic) =====
       // If we are blocked by a door, find the switch!
       // Check what we hit
       if ((trace_ent.classname == "func_door"))
       {
          // Is the door closed/closing? (State 0=Closed, 1=Opening, 2=Open, 3=Closing)
          if ((trace_ent.state == 0.000))
          {
             // PROBLEM: Locked Door.
             // SOLUTION: Find the button.
             local entity key_button;
             key_button = FindButtonForDoor (trace_ent);
             if (key_button)
             {
                // Found the specific button that opens THIS door.
                // Override current goal to go press it.
                if ((self.goalentity != key_button))
                {
                   self.goalentity = key_button;
                   // Retarget navigation immediately
                   return ;
                } //end if
             } //end if
             else
             {
                // No button? Maybe it's a shoot-to-open door?
                if ((trace_ent.health > 0.000))
                {
                   // Attack the door!
                   self.enemy = trace_ent;
                   self.th_missile ();
                } //end if
             } //end if
          } //end if
       } //end if
       // ===== END PROBLEM SOLVER: Obstacle Solver =====
   }

   if (self.enemy)
   {
      return ;
   } //end if

   // Try alternate direction
   ofs = (-1 * ofs);
   if (walkmove ((self.ideal_yaw + ofs),dist))
   {
      return ;
   } //end if

   // --- SLIDE LOGIC #2 (from Step 4) ---
   self.angles_y = self.ideal_yaw + ofs;
   makevectors(self.angles);
   traceline(org_start, org_start + (v_forward * 16), TRUE, self);

   if (trace_fraction < 1.0)
   {
       move_dir = v_forward;
       wall_normal = trace_plane_normal;
       slide_dir = move_dir - (wall_normal * (move_dir * wall_normal));
       slide_dir = normalize(slide_dir);
       slide_yaw = vectoyaw(slide_dir);
       if (walkmove(slide_yaw, dist)) return ;
   }

   if ((self.flags & (FL_INWATER + FL_ONGROUND)))
   {
      self.search_time = (self.search_time - 0.300);
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
    local float delta;

    // Calculate difference between current angle and ideal angle
    delta = anglemod (self.ideal_yaw - self.angles_y);
    if ((delta > 180.000))
    {
        delta = (delta - 360.000);
    } //end if

    // DYNAMIC SPEED
    // If delta is small (< 10 degrees), turn SLOWLY (smooth tracking)
    if ((fabs (delta) < 10.000))
    {
        self.yaw_speed = 5.000; // Very smooth, mouse-like micro-adjustments
    } //end if
    // If delta is medium (cornering), use normal speed
    else
    {
        if ((fabs (delta) < 45.000))
        {
            self.yaw_speed = 20.000;
        } //end if
        // If delta is huge (180 flick), turn FAST
        else
        {
            self.yaw_speed = 45.000; // Snap turn
        } //end if
    } //end if

    ChangeYaw ();
    self.yaw_speed = 20.000; // Reset to default for other calculations
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
   makevectors (self.angles);
   start = (start + (v_right * 15.000));
   traceline (start,(start + (BOTSPEED * dir)),FALSE,self);
   if ((trace_fraction != SPAWNFLAG_SUPERSPIKE))
   {
      if (walkmove ((self.ideal_yaw - 90.000),(dist * 0.600)))
      {
         return (TRUE);
      } //end if
   } //end if
   start = (start - (v_right * SVC_INTERMISSION));
   traceline (start,(start + (BOTSPEED * dir)),FALSE,self);
   if ((trace_fraction != TRUE))
   {
      if (walkmove ((self.ideal_yaw + 90.000),(dist * 0.600)))
      {
         return (TRUE);
      } //end if
   } //end if
   // Escalate: jump or diagonal/backpedal to clear corners and lips.
   if (Bot_tryjump (270.000,dist,FALSE))
   {
      return (TRUE);
   } //end if
   if (walkmove ((self.ideal_yaw + 135.000),(dist * 0.400)))
   {
      return (TRUE);
   } //end if
   if (walkmove ((self.ideal_yaw - 135.000),(dist * 0.400)))
   {
      return (TRUE);
   } //end if
   if (walkmove ((self.ideal_yaw + 180.000),(dist * 0.500)))
   {
      return (TRUE);
   } //end if

   // ===== TWEAK #5: Desperate unstuck via train/rocket/super (strafe → exploit) =====
   // After 5+ stuck attempts, escalate to "human exploit" tactics: train surf (boost off
   // moving train momentum), rocket jump (blast out backward), or super jump (350u leap).
   // Resets counter after escape. Prevents infinite spin-death in geometry traps.
   if ((self.stuck_count > 5))
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
   if (walkmove (self.ideal_yaw,SPAWNFLAG_LASER))
   {
      botwalkmove (self.ideal_yaw,(dist - SPAWNFLAG_LASER));
      return ;
   } //end if
   if (walkmove ((self.ideal_yaw + 45.000),SPAWNFLAG_LASER))
   {
      movetogoal ((dist - SPAWNFLAG_LASER));
      return ;
   } //end if
   if (walkmove ((self.ideal_yaw - 45.000),SPAWNFLAG_LASER))
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

// FEELER STEERING: 5-trace corridor centring and cornering
// Returns yaw bias (degrees to adjust heading)
// Sets global feeler_speed_scale (0.0-1.0)
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
   local float bias;
   local float yaw_bias;

   yaw_bias = 0.000;
   feeler_speed_scale = 1.000;

   // Trace origin: waist height reads walls reliably
   start = (bot.origin + '0.000 0.000 24.000');

   // Use base_yaw as reference direction (goal heading), not current yaw
   bot.v_angle_x = 0.000;
   bot.v_angle_y = base_yaw;
   bot.v_angle_z = 0.000;
   makevectors (bot.v_angle);

   fwd = v_forward;
   right = v_right;

   // 5 feeler traces: forward, forward-left, forward-right, left, right
   traceline (start,(start + (fwd * 180.000)),TRUE,bot);
   f = trace_fraction;

   traceline (start,(start + ((fwd * 140.000) + (right * -70.000))),TRUE,bot);
   fl = trace_fraction;

   traceline (start,(start + ((fwd * 140.000) + (right * 70.000))),TRUE,bot);
   fr = trace_fraction;

   traceline (start,(start + (right * -55.000)),TRUE,bot);
   l = trace_fraction;

   traceline (start,(start + (right * 55.000)),TRUE,bot);
   r = trace_fraction;

   bias = 0.000;

   // Corridor centring: if left wall close, steer right (and vice versa)
   bias = (bias + ((l - r) * 22.000));

   // Cornering: if front-left blocked more than front-right, steer right
   bias = (bias + ((fl - fr) * 28.000));

   // Imminent collision: forward blocked, pick clearer diagonal aggressively
   if ((f < 0.550))
   {
      if ((fl < fr))
      {
         bias = (bias + 35.000);
      } //end if
      else
      {
         bias = (bias - 35.000);
      } //end else
      feeler_speed_scale = 0.600;  // Slow down approaching walls
   } //end if

   // Clamp raw bias so it cannot dominate intent
   yaw_bias = Clamp (bias,-45.000,45.000);

   // Smooth turn: cap degrees per tick (anti-robotic)
   local float max_turn;
   max_turn = (120.000 * dt);  // 120 deg/sec
   yaw_bias = Clamp (yaw_bias,(-1.000 * max_turn),max_turn);

   return (yaw_bias);
}; //end of the function Bot_SampleFeelers

// FEELER ESCAPE: 8-direction scan to find clearest path when stuck/lost
// Returns yaw of clearest direction (longest unobstructed trace)
float (entity bot, float base_yaw) Bot_FindClearestDirection =
{
   local vector start;
   local float best_yaw;
   local float best_score;
   local float i;
   local float scan_yaw;
   local vector dir;
   local float score;

   start = (bot.origin + '0.000 0.000 24.000');
   best_score = -1.000;
   best_yaw = base_yaw;

   // Scan 8 directions (0°, 45°, 90°, 135°, 180°, 225°, 270°, 315°)
   i = 0.000;
   while ((i < 8.000))
   {
      scan_yaw = (base_yaw + (i * 45.000));

      bot.v_angle_x = 0.000;
      bot.v_angle_y = scan_yaw;
      bot.v_angle_z = 0.000;
      makevectors (bot.v_angle);
      dir = v_forward;

      // Trace 160 units in this direction
      traceline (start,(start + (dir * 160.000)),TRUE,bot);

      // Score = distance traveled (longer = more open = likely exit)
      score = (trace_fraction * 160.000);

      if ((score > best_score))
      {
         best_score = score;
         best_yaw = scan_yaw;
      } //end if

      i = (i + 1.000);
   } //end while

   return (best_yaw);
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
   local vector prev_origin;

   prev_origin = self.oldorigin;
   self.oldorigin = self.origin;

   // ===== PHASE 9: PROACTIVE HAZARD CHECK (Before Movement) =====
   // Check ground ahead for gaps, lava, and death pits BEFORE committing to movement.
   // This prevents bots from casually walking into hazards (Layer 1 - Prevention).
   // Phase 4's mid-air system (Layer 2) handles aerial hazards during flight.
   CheckForHazards ();
   // =============================================================

   // ===== PHASE 11: WATER SURVIVAL CHECK (Drowning Prevention) =====
   // Check if bot is underwater and running out of air, force surface if needed.
   // This prevents bots from suffocating in deep water zones.
   CheckWaterSurvival ();
   // =============================================================

   // ===== DYNAMIC STUCK WIGGLE: Micro-Jump on Velocity Stall =====
   // If the bot is trying to move but velocity is near zero, don't wait 1 second.
   // Try an immediate micro-jump to clear small geometry lips/steps.
   // This prevents bots from standing still for a full second before reacting.
   if (((vlen (self.velocity) < 10.000) && (self.flags & FL_ONGROUND)))
   {
      // Try a micro-jump (20% chance to avoid spamming every frame)
      if ((random () < 0.200))
      {
         self.velocity_z = 220.000;  // Small hop
         sound (self,CHAN_BODY,"player/plyrjmp8.wav",1.000,ATTN_NORM);
      } //end if
   } //end if
   // ===== END DYNAMIC STUCK WIGGLE =====

   // Stuck detection: if we haven't moved 10 units in 1s, clear caches and replan.
   if ((vlen ((self.origin - prev_origin)) < 10.000))
   {
      if (!self.stuck_time)
      {
         self.stuck_time = time;
      } //end if
      if (((time - self.stuck_time) > 1.000))
      {
         clearCache (self);
         // Start a short cooldown so we avoid immediately picking the same bad goal.
         self.stuck_time = time;
         return ;
      } //end if
   } //end if
   else
   {
      self.stuck_time = CAM_IDLE;
   } //end if
   Botgoal = self.goalentity;

   // ===== SMOOTHING: The "Racing Line" (Corner Smoothing) =====
   // Pro players don't hit waypoints then turn 90°. They "cut the corner,"
   // starting the turn before reaching the waypoint by blending aim toward next node.
   local vector aim_point;
   aim_point = Botgoal.origin;

   // If we are getting close to the current node (within 120 units),
   // and that node has a target (the next node in the chain)...
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

   self.ideal_yaw = vectoyaw ((aim_point - self.origin));

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
         self.ideal_yaw = vectoyaw(Botgoal.origin - self.origin);
         ChangeYaw();

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
               ChangeYaw ();

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

   // ===== PLATFORM MASTERY: Elevator Patience =====
   // If our next step is a platform node, and it's high above us,
   // it means the lift is UP and we are DOWN. We must WAIT.
   if (Botgoal.is_platform_node)
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
            self.ideal_pitch = -45.000;
            ChangePitch ();

            // Reset stuck timers so we don't panic-teleport
            self.stuck_time = 0.000;
            self.stuck_count = 0.000;

            return ;
         } //end if
      } //end if
   } //end if
   // ===============================================

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
                     // Execute rocket jump!
                     // Look straight DOWN (NEGATIVE pitch = down, positive = up!)
                     self.angles_x = -80.000;
                     makevectors (self.angles);
                     // Fire!
                     W_FireRocket ();
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
      ChangeYaw ();
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
      ChangeYaw ();

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
