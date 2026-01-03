float (entity targ) botrange =
{
   local vector spot1;
   local vector spot2;
   local float mel;
   local float r;

   spot1 = (self.origin + self.view_ofs);
   spot2 = (targ.origin + targ.view_ofs);
   r = vlen ((spot1 - spot2));
   mel = ((180.000 - (self.health * 0.500)) - (self.armorvalue * self.armortype));
   if ((self.items & IT_QUAD))
   {
      mel = (FL_SWIM * mel);
   } //end if
   if ((teamplay == TRUE))
   {
      mel = 60.000;
   } //end if
   if ((r < mel))
   {
      return (RANGE_MELEE);

   } //end if
   else
   {
      if ((r < SEARCH_RADIUS))
      {
         return (RANGE_NEAR);

      } //end if
      else
      {
         if ((r < 1000.000))
         {
            return (RANGE_MID);
         } //end if
      } //end if
   } //end if
   return (RANGE_FAR);
}; //end of the function botrange
float (entity targ) infrontofbot =
{
   local vector vec;
   local vector xydir;
   local float fov;
   local float dot;
   local float lnd;
   local float idle_scan;

   if ((self.skil == MOVETYPE_WALK))
   {
      return (TRUE);
   } //end if
   lnd = pointcontents ((self.origin + self.view_ofs));
   if ((lnd != CONTENT_WATER))
   {
      if ((self.skil < FL_SWIM))
      {
         xydir = (targ.origin - self.origin);
         xydir_z = FALSE;
         dot = vlen (xydir);
         fov = ((targ.origin_z - self.origin_z) * (FL_SWIM - (0.750 * self.skil)));
         if ((fov < FALSE))
         {
            fov = (-0.800 * fov);
         } //end if
         if (((fov > 150.000) && (dot < fov)))
         {
            return (FALSE);
         } //end if
      } //end if
   } //end if
   // Idle scan: occasionally yaw sweep when no enemy to widen sightlines.
   idle_scan = CAM_IDLE;
   if (!self.enemy)
   {
      if ((random () < 0.100))
      {
         self.angles_y = (self.angles_y + ((random () - 0.500) * 90.000));
         idle_scan = TRUE;
      } //end if
   } //end if
   makevectors (self.angles);
   vec = normalize ((targ.origin - self.origin));
   dot = (vec * v_forward);
   fov = (0.700 - (self.skil * 0.280));
   if (idle_scan)
   {
      fov = (fov * 1.500);
   } //end if
   if ((dot > fov))
   {
      return (TRUE);
   } //end if
   if ((lnd == CONTENT_WATER))
   {
      if ((dot > FALSE))
      {
         return (TRUE);
      } //end if
   } //end if
   return (FALSE);
}; //end of the function infrontofbot
float (entity targ) Swimto =
{
   local vector spot1;
   local vector spot2;
   local float lnd;

   spot1 = (self.origin + self.view_ofs);
   spot2 = targ.absmin;
   lnd = pointcontents (spot2);
   if ((lnd != CONTENT_WATER))
   {
      if ((spot2_z > (spot1_z + MAXJUMP)))
      {
         return (FALSE);
      } //end if
   } //end if
   traceline (spot1,spot2,TRUE,self);
   if ((trace_fraction == TRUE))
   {
      return (TRUE);
   } //end if
   if ((trace_ent == targ))
   {
      return (TRUE);
   } //end if
   return (FALSE);
}; //end of the function Swimto
float (entity targ) Spotvisible =
{
   local vector spot1;
   local vector spot2;
   local vector peek1;
   local vector peek2;
   local vector rightdir;
   local string t1;

   spot1 = (self.origin + self.view_ofs);
   spot2 = ((targ.absmin + targ.absmax) * 0.500);
   traceline (spot1,spot2,TRUE,self);
   if ((trace_fraction == TRUE))
   {
      return (TRUE);
   } //end if
   if ((trace_ent == targ))
   {
      return (TRUE);
   } //end if
   // Corner peek: offset the target point to the right/left to simulate a lean.
   if ((trace_fraction < TRUE))
   {
      makevectors (self.angles);
      rightdir = v_right;
      peek1 = (spot2 + (rightdir * 16.000));
      traceline (spot1,peek1,TRUE,self);
      if (((trace_fraction == TRUE) || (trace_ent == targ)))
      {
         return (TRUE);
      } //end if
      peek2 = (spot2 - (rightdir * 16.000));
      traceline (spot1,peek2,TRUE,self);
      if (((trace_fraction == TRUE) || (trace_ent == targ)))
      {
         return (TRUE);
      } //end if
   } //end if
   return (FALSE);
}; //end of the function Spotvisible
float (entity targ) enemyvisible =
{
   local vector spot1;
   local vector spot2;
   local vector peek1;
   local vector peek2;
   local vector rightdir;

   if (visible (targ))
   {
      return (TRUE);
   } //end if
   spot1 = (self.origin + self.view_ofs);
   spot2 = targ.origin;
   traceline (spot1,spot2,TRUE,self);
   if ((trace_inopen && trace_inwater))
   {
      return (FALSE);
   } //end if
   if ((trace_fraction == TRUE))
   {
      return (TRUE);
   } //end if
   // Corner peek: try small right/left offsets before giving up LOS.
   if ((trace_fraction < TRUE))
   {
      makevectors (self.angles);
      rightdir = v_right;
      peek1 = (spot2 + (rightdir * 16.000));
      traceline (spot1,peek1,TRUE,self);
      if (((trace_fraction == TRUE) || (trace_ent == targ)))
      {
         return (TRUE);
      } //end if
      peek2 = (spot2 - (rightdir * 16.000));
      traceline (spot1,peek2,TRUE,self);
      if (((trace_fraction == TRUE) || (trace_ent == targ)))
      {
         return (TRUE);
      } //end if
   } //end if
   return (FALSE);
}; //end of the function enemyvisible
float (entity targ) Platvisible =
{
   local vector spot1;
   local vector spot2;
   local string t1;

   spot1 = (self.origin + self.view_ofs);
   spot2 = ((targ.absmin + targ.absmax) * 0.500);
   spot2_z = (targ.absmax_z + MOVETYPE_WALK);
   traceline (spot1,spot2,TRUE,self);
   if ((trace_fraction == TRUE))
   {
      return (TRUE);
   } //end if
   if ((trace_ent == targ))
   {
      return (TRUE);
   } //end if
   return (FALSE);
}; //end of the function Platvisible
float (vector spot) dropline =
{
   local float drop;
   local vector spot2;
   local string tmp;

   spot2 = spot;
   spot2_z = (spot2_z - 500.000);
   traceline (spot,spot2,TRUE,self);
   drop = (spot_z - (trace_fraction * 500.000));
   return (drop);
}; //end of the function dropline
float (entity a, entity b, float bmaxjump) BotWalkable =
{
   local vector spot1;
   local vector dir;
   local vector borg;
   local float tests;
   local float okpath;
   local float flr;
   local float goalheight;

   if ((b.pathtype != DROPPED))
   {
      borg = ((b.absmin + b.absmax) * 0.500);
      borg_z = (b.absmin_z + TRUE);

   } //end if
   else
   {
      borg = b.origin;
   } //end if
   // Multi-trace path: double sample density (halve dir, double tests) for precise physics.
   // Dense samples detect lips/walls/clips mid-route that sparse checks miss—fewer stuck spots.
   spot1 = a.origin;
   dir = normalize ((borg - a.origin));
   dir = (((dir * LEVELJUMPTIME) * BOTSPEED) * 6.500);
   tests = vlen ((borg - a.origin));
   tests = (tests / ((LEVELJUMPTIME * BOTSPEED) * 6.500));

   // Double sample density: halve step size, double iterations.
   dir = (dir * 0.500);
   tests = (tests * FL_SWIM);

   if ((b.pathtype == DROPPED))
   {
      goalheight = (borg_z + self.mins_z);

   } //end if
   else
   {
      goalheight = borg_z;
   } //end if
   while ((tests > TRUE))
   {
      local vector next_spot;

      okpath = TRUE;
      next_spot = (spot1 + dir);

      // Collision trace: detect solid BSP walls/obstacles mid-path (vs over-optimistic air-only checks).
      traceline (spot1,next_spot,TRUE,a);
      if ((trace_fraction < TRUE))
      {
         if ((trace_ent.solid == SOLID_BSP))
         {
            return (FALSE);
         } //end if
      } //end if

      spot1 = next_spot;
      tests = (tests - TRUE);
      flr = dropline (spot1);
      if (((flr + bmaxjump) < goalheight))
      {
         spot1 = (spot1 - (dir * 0.500));
         flr = dropline (spot1);
         if (((flr + bmaxjump) < goalheight))
         {
            okpath = FALSE;
         } //end if
         spot1 = (spot1 + dir);
         tests = (tests - 0.500);
         flr = dropline (spot1);
         if (((flr + bmaxjump) < goalheight))
         {
            if (!okpath)
            {
               return (FALSE);
            } //end if
            spot1 = (spot1 + (dir * 0.500));
            tests = (tests - 0.500);
            flr = dropline (spot1);
            if (((flr + bmaxjump) < goalheight))
            {
               return (FALSE);
            } //end if
         } //end if
      } //end if
   } //end while
   return (TRUE);
}; //end of the function BotWalkable
float (entity a, entity b) IsUpstream;
float /* ERROR: Could not determine return type */ (entity a, entity b, float truereach) Reachable =
{
   local vector spot1;
   local vector spot2;
   local vector borg;
   local vector quick_dir;
   local vector quick_end;
   local float lnd;
   local float vel;
   local float diffz;
   local float diffxy;
   local float rng;
   local float maxzd;
   local float bmaxjump;
   local float brad;
   local string tmp;

   if (truereach)
   {
      bmaxjump = MAXJUMP;

   } //end if
   else
   {
      bmaxjump = (0.600 * MAXJUMP);
   } //end if
   if ((b.pathtype != DROPPED))
   {
      borg = ((b.absmin + b.absmax) * 0.500);
      borg_z = (b.absmin_z + TRUE);

   } //end if
   else
   {
      if ((a.pathtype == DROPPED))
      {
         if (IsUpstream (a,b))
         {
            return (TRUE);
         } //end if
      } //end if
      borg = b.origin;
   } //end if
   spot1 = a.origin;
   spot2 = borg;
   if ((b.pathtype != DROPPED))
   {
      spot2_z = ((b.absmin_z + b.absmax_z) * 0.500);
   } //end if
   rng = vlen ((spot2 - spot1));
   if (truereach)
   {
      if ((rng > SEARCH_RADIUS))
      {
         return (FALSE);
      } //end if

   } //end if
   else
   {
      if ((rng > (SEARCH_RADIUS - (FL_SWIM * BOTSPEED))))
      {
         return (FALSE);
      } //end if
   } //end if
   // Quick reject: if recently stuck, skip this goal and avoid immediate blocks.
   if (self.stuck_time)
   {
      if (((time - self.stuck_time) < 2.000))
      {
         return (FALSE);
      } //end if
   } //end if
   quick_dir = normalize ((spot2 - spot1));
   quick_end = (spot1 + (quick_dir * 64.000));
   traceline (spot1,quick_end,TRUE,a);
   if ((trace_fraction < TRUE))
   {
      if ((trace_ent != world))
      {
         if ((trace_ent.solid != SOLID_BSP))
         {
            return (FALSE);
         } //end if
      } //end if
   } //end if
   lnd = pointcontents (a.origin);
   if ((lnd != CONTENT_WATER))
   {
      spot1_z = ((dropline (spot1) + self.view_ofs_z) - self.mins_z);
   } //end if
   traceline (spot1,spot2,TRUE,a);
   spot2 = borg;

   // ===== TWEAK #4: Train reachability prediction (static check → path sync) =====
   // When checking if train is reachable, predict where it will be when bot arrives
   // (travel time = distance / BOTSPEED) using path_corner chain. Prevents false
   // "unreachable" rejections when timing is actually correct—bot won't chase static
   // train position, will aim for future intercept point.
   if ((b.classname == "train"))
   {
      spot2 = predict_train_pos(b, (vlen((spot1 - b.origin)) / BOTSPEED));
      traceline(spot1, spot2, TRUE, a);
   } //end if
   // ===== END TWEAK #4 =====

   if ((lnd == CONTENT_WATER))
   {
      if (!trace_inopen)
      {
         if ((trace_fraction == TRUE))
         {
            return (TRUE);
         } //end if
         if (truereach)
         {
            return (TRUE);
         } //end if
      } //end if
      if (truereach)
      {
         maxzd = 45.000;
         lnd = pointcontents ((a.origin + self.view_ofs));
         if ((lnd == CONTENT_WATER))
         {
            maxzd = (maxzd + self.view_ofs_z);
         } //end if
         if ((spot2_z < (a.origin_z + maxzd)))
         {
            if ((trace_fraction == TRUE))
            {
               return (TRUE);
            } //end if
            spot1_z = spot2_z;
            traceline (spot1,spot2,TRUE,a);
            if ((trace_fraction == TRUE))
            {
               return (TRUE);
            } //end if
         } //end if
      } //end if
   } //end if
   if ((trace_fraction != TRUE))
   {
      return (FALSE);
   } //end if
   spot1 = a.origin;
   if ((spot2_z > (spot1_z + bmaxjump)))
   {
      return (FALSE);
   } //end if
   spot1 = a.origin;
   spot1_z = FALSE;
   spot2 = borg;
   spot2_z = FALSE;
   diffxy = vlen ((spot2 - spot1));
   diffxy = (diffxy - ((LEVELJUMPTIME * BOTSPEED) * MOVETYPE_BOUNCE));

   // Strafe momentum: account for ground velocity carryover into air (30% of xy speed).
   // Simulates running jumps reaching farther than standing jumps—fixes "moron short" on speed.
   // Uses bot's current ground velocity projected over estimated flight time.
   local vector gnd_vel;
   local float xy_boost;
   local float timetofloor;

   gnd_vel = self.velocity;
   gnd_vel_z = FALSE;
   xy_boost = (vlen (gnd_vel) * 0.300);

   // Estimate time to floor: basic sqrt(2*height/g) approximation for flight time.
   diffz = (a.origin_z - borg_z);
   if ((diffz > FALSE))
   {
      timetofloor = (diffz / (GRAVITY * LEVELJUMPTIME));
   } //end if
   else
   {
      timetofloor = LEVELJUMPTIME;
   } //end if

   diffxy = (diffxy - (xy_boost * (timetofloor / LEVELJUMPTIME)));

   if ((diffxy < FALSE))
   {
      return (TRUE);
   } //end if
   // Finer arc simulation: 0.05s steps (vs old 0.1s) for smoother parabolic prediction.
   // Halves timestep → double iterations, catches low arcs & momentum better, fewer overjump errors.
   // Physics: Quake g=800u/s² → GRAVITY=80/0.1s → 40/0.05s; BOTSPEED similarly halved per step.
   vel = FALSE;
   diffz = (a.origin_z - borg_z);
   while ((diffz > FALSE))
   {
      diffxy = (diffxy - (BOTSPEED * 0.500));
      vel = (vel - (GRAVITY * 0.500));
      diffz = (diffz + (0.050 * vel));
   } //end while
   if ((diffxy < FALSE))
   {
      return (TRUE);
   } //end if
   return (BotWalkable (a,b,bmaxjump));
}; //end of the function Reachable
float /* ERROR: Could not determine return type */ (entity a, entity b) BotReachable =
{
   return (Reachable (a,b,FALSE));
}; //end of the function BotReachable
float /* ERROR: Could not determine return type */ (entity b) TrueReachable =
{
   return (Reachable (self,b,TRUE));
}; //end of the function TrueReachable
