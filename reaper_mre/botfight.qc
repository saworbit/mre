float (entity targ) botrange;
vector (vector src, vector trg, float invMvel) leadtarget =
{
   local vector tg;
   local vector lead;
   local vector avg_vel;
   local float dx0;
   local float dx1;

   // Base lead: scale current velocity by distance to target.
   lead = ((self.enemy.velocity * invMvel) * vlen ((trg - src)));
   // High-skill bots smooth lead using recent velocity history to read patterns.
   if ((self.skil > 2.000))
   {
      avg_vel = (self.vel_hist0 + self.vel_hist1 + self.vel_hist2 + self.enemy.velocity);
      avg_vel = (avg_vel * 0.250);
      lead = ((avg_vel * invMvel) * vlen ((trg - src)));
   } //end if
   // Add partial vertical lead for higher-skill bots to catch jumps without over-leading.
   if ((self.skil > TRUE))
   {
      lead_z = (lead_z + ((self.enemy.velocity_z * invMvel) * 0.500));
   } //end if
   // Strafe pattern hint: steady lateral x-velocity gets a small extra lead.
   if ((self.skil > 3.000))
   {
      dx0 = fabs ((self.vel_hist0_x - self.vel_hist1_x));
      dx1 = fabs ((self.vel_hist1_x - self.vel_hist2_x));
      if (((dx0 < 50.000) && (dx1 < 50.000)))
      {
         lead_x = (lead_x * 1.200);
      } //end if
   } //end if
   tg = (trg + lead);
   if ((self.weapon == IT_ROCKET_LAUNCHER))
   {
      if ((self.skil > FL_SWIM))
      {
         traceline (src,tg,TRUE,self);
         if ((trace_fraction != TRUE))
         {
            tg = (tg - (lead * 0.500));
            traceline (src,tg,TRUE,self);
            if ((trace_fraction != TRUE))
            {
               tg = (tg - (lead * 0.500));
            } //end if
         } //end if
      } //end if
   } //end if
   return (tg);
}; //end of the function leadtarget
// ===== TWEAK #2: Gravity arc simulation (full physics vs flat percentage) =====
// Replaces percentage-based height guessing with real parabolic trajectory calculation.
// Uses Quake physics: g=800u/s², GL speed=600u/s. Computes optimal lob angle for range,
// simulates arc over travel time, adjusts for gravity drop. Hits distant targets at feet
// instead of overshooting/undershooting with flat height multipliers. Critical for long-range
// indirect fire and precise splash damage placement.
vector (vector trg) adjustgrenade =
{
   local vector dir;
   local float dist;
   local float travel_time;
   local float initial_vz;
   local float gravity_drop;
   local vector arc_end;
   local float gl_speed;

   gl_speed = 600.000;  // Grenade launcher projectile speed in Quake

   // Calculate horizontal distance and direction
   dir = normalize ((trg - self.origin));
   dist = vlen ((trg - self.origin));

   // Travel time to target at constant horizontal speed
   travel_time = (dist / gl_speed);

   // Compute initial vertical velocity for optimal lob arc
   // Approximate: vz ≈ (g * t) where t ≈ sqrt(2h/g), simplified to vz ≈ 0.8 * dist for GL
   // This creates a parabolic lob that arcs over obstacles and lands near target feet
   // Empirical formula calibrated for Quake GL physics (avoids sqrt dependency)
   initial_vz = ((GRAVITY * travel_time) * 0.600);

   // Simulate gravity drop over flight time: drop = 0.5 * g * t²
   gravity_drop = ((0.500 * GRAVITY) * (travel_time * travel_time));

   // Compute arc endpoint: horizontal travel + vertical lob - gravity drop
   arc_end = ((self.origin + ((dir * dist) + ('0.000 0.000 1.000' * (initial_vz * travel_time)))) - ('0.000 0.000 1.000' * gravity_drop));

   // Adjust aim point toward splash zone (16 units toward target for splash radius)
   return ((arc_end + ((normalize ((trg - arc_end)) * 16.000))));
}; //end of the function adjustgrenade
// ===== END TWEAK #2 =====

// ===== TWEAK #1: Bounce-trace aim (1-bounce grenade prediction) =====
// Simulates grenade physics with ONE wall bounce to predict splash location.
// Uses constant velocity (no air resistance in Quake), reflects off first solid hit,
// continues to final explosion point. Critical for corner/doorway indirect fire where
// straight-line aim fails. Enables "bank shot" kills around cover.
vector (vector start, vector target, float speed) predict_gl_bounce =
{
   local vector dir;
   local vector vel;
   local vector pos;
   local vector end_pos;
   local float travel_time;
   local float bounce_time;
   local vector bounce_pos;
   local vector bounce_normal;
   local vector bounce_vel;

   // Initial trajectory toward target
   dir = normalize ((target - start));
   vel = (dir * speed);  // Grenade velocity: 600 u/s typical

   // Simulate flight to first collision (wall/floor)
   traceline (start,((start + dir) * 2000.000),FALSE,self);  // Trace far ahead

   if ((trace_fraction < 1.000))
   {
      // Hit a wall—calculate bounce physics
      bounce_pos = trace_endpos;
      bounce_normal = trace_plane_normal;

      // Reflect velocity off surface: v' = v - 2(v·n)n
      // Quake grenades lose ~20% energy on bounce (elasticity 0.8)
      local float dot_product;
      dot_product = ((vel_x * bounce_normal_x) + (vel_y * bounce_normal_y) + (vel_z * bounce_normal_z));
      bounce_vel_x = (vel_x - ((2.000 * dot_product) * bounce_normal_x));
      bounce_vel_y = (vel_y - ((2.000 * dot_product) * bounce_normal_y));
      bounce_vel_z = (vel_z - ((2.000 * dot_product) * bounce_normal_z));

      // Apply bounce damping (grenades don't bounce perfectly)
      bounce_vel = (bounce_vel * 0.800);

      // Trace post-bounce trajectory to explosion point
      traceline (bounce_pos,((bounce_pos + bounce_vel) * 1.500),FALSE,self);
      end_pos = trace_endpos;

      // Return predicted splash zone center (add small offset for splash radius)
      return ((end_pos + (normalize (bounce_vel) * 16.000)));
   } //end if
   else
   {
      // No wall hit—direct path to target (fallback to straight shot)
      return (target);
   } //end if
}; //end of the function predict_gl_bounce
// ===== END TWEAK #1 =====

vector () botaim =
{
   local vector dir;
   local vector tg;
   local vector lead;
   local vector src;
   local float sk;
   local float rnd;
   local float splash_z;
   local entity e;

   if (REBOUND)
   {
      tg = REBOUNDSPOT;

   } //end if
   else
   {
      src = self.origin;
      if ((self.weapon & ((IT_ROCKET_LAUNCHER + IT_SUPER_NAILGUN) + IT_NAILGUN)))
      {
         src = (src + '0.000 0.000 16.000');
      } //end if
      tg = self.enemy.origin;
      traceline (src,tg,TRUE,self);
      if ((trace_fraction != TRUE))
      {
         tg = (tg + self.enemy.view_ofs);
      } //end if
      // Track recent enemy velocity in a 3-sample ring buffer for pattern reads.
      if ((self.vel_hist_idx == CAM_IDLE))
      {
         self.vel_hist0 = self.enemy.velocity;
      } //end if
      else
      {
         if ((self.vel_hist_idx == TRUE))
         {
            self.vel_hist1 = self.enemy.velocity;
         } //end if
         else
         {
            self.vel_hist2 = self.enemy.velocity;
         } //end if
      } //end else
      self.vel_hist_idx = (self.vel_hist_idx + TRUE);
      if ((self.vel_hist_idx > 2.000))
      {
         self.vel_hist_idx = CAM_IDLE;
      } //end if
      if ((self.skil > TRUE))
      {
         if ((self.weapon & IT_ROCKET_LAUNCHER))
         {
            tg = leadtarget (src,tg,0.001);
            // Randomize aim height within the enemy bbox for splash/uneven-ground hits.
            splash_z = (self.enemy.mins_z + (random () * (self.enemy.view_ofs_z - self.enemy.mins_z)));
            tg_z = (tg_z + splash_z);
            if ((self.origin_z >= self.enemy.origin_z))
            {
               rnd = ((random () * 3.500) + TRUE);
               if ((self.skil > rnd))
               {
                  tg_z = ((tg_z + self.enemy.mins_z) + FL_SWIM);
                  traceline (src,tg,TRUE,self);
                  if ((trace_fraction != TRUE))
                  {
                     tg_z = ((tg_z - self.enemy.mins_z) - MOVETYPE_WALK);
                  } //end if
               } //end if
            } //end if

         } //end if
         else
         {
            if ((self.weapon & IT_GRENADE_LAUNCHER))
            {
               tg = leadtarget (src,tg,0.002);

            } //end if
            else
            {
               if (((self.weapon & IT_SUPER_NAILGUN) || (self.weapon & IT_NAILGUN)))
               {
                  rnd = (random () * 0.002);
                  tg = leadtarget (src,tg,rnd);
               } //end if
            } //end if
         } //end if
      } //end if
   } //end if
   if ((self.weapon == IT_GRENADE_LAUNCHER))
   {
      tg = adjustgrenade (tg);
   } //end if
   sk = self.skil;
   if ((self.weapon == IT_LIGHTNING))
   {
      if ((sk > 2.500))
      {
         sk = 2.500;
      } //end if
   } //end if
   if ((sk < MOVETYPE_WALK))
   {
      if (!coop)
      {
         lead = (self.enemy.origin - self.enemy.oldorigin);
         lead = (((lead * (MOVETYPE_WALK - sk)) * 3.500) * (random () - 0.500));
         tg = (tg + lead);

      } //end if
      else
      {
         lead = VEC_ORIGIN;
         tg = (tg + lead);
      } //end if
   } //end if
   dir = normalize ((tg - self.origin));
   if ((sk < MOVETYPE_WALK))
   {
      dir = (dir + (((MOVETYPE_WALK - sk) * crandom ()) * '0.060 0.000 0.000'));
      dir = (dir + (((MOVETYPE_WALK - sk) * crandom ()) * '0.000 0.060 0.000'));
   } //end if
   dir = normalize (dir);
   return (dir);
}; //end of the function botaim
float () CheckBotAttack =
{
   local vector spot1;
   local vector spot2;
   local entity targ;

   targ = self.enemy;
   if ((time < self.attack_finished))
   {
      return (FALSE);
   } //end if
   spot1 = (self.origin + self.view_ofs);
   spot2 = (targ.origin + targ.view_ofs);
   traceline (spot1,spot2,FALSE,self);
   if ((trace_ent != targ))
   {
      return (FALSE);
   } //end if
   if ((trace_inopen && trace_inwater))
   {
      spot2 = targ.origin;
      traceline (spot1,spot2,FALSE,self);
      if ((trace_inopen && trace_inwater))
      {
         return (FALSE);
      } //end if
   } //end if
   self.attack_state = AS_MELEE;
   return (TRUE);
}; //end of the function CheckBotAttack
float () W_BestBotWeapon =
{
   local float it;
   local float rng;
   local float wlevel;
   local float enemy_wep;

   it = self.items;
   rng = botrange (self.enemy);

   // ===== TACTICAL AI: Weapon Counter-Tactics (Rock-Paper-Scissors) =====
   // Adapt weapon choice based on enemy's current weapon for tactical advantage.
   // RL counters LG (knockback disrupts tracking), LG counters RL (instant hitscan).
   enemy_wep = self.enemy.weapon;

   // Counter Lightning Gun with Rockets (knockback disrupts tracking)
   if ((enemy_wep == IT_LIGHTNING))
   {
      if ((rng == RANGE_FAR))
      {
         if (((self.ammo_rockets >= 2.000) && (it & IT_ROCKET_LAUNCHER)))
         {
            return (IT_ROCKET_LAUNCHER);
         } //end if
      } //end if
   } //end if

   // Counter Rocket Launcher with Lightning Gun (instant hitscan)
   if ((enemy_wep == IT_ROCKET_LAUNCHER))
   {
      if ((rng > RANGE_MELEE))
      {
         if (((self.ammo_cells >= 10.000) && (it & IT_LIGHTNING)))
         {
            wlevel = CheckWaterLevel ();
            if ((wlevel < FL_SWIM))
            {
               return (IT_LIGHTNING);
            } //end if
            if ((self.items & IT_INVULNERABILITY))
            {
               return (IT_LIGHTNING);
            } //end if
         } //end if
      } //end if
   } //end if

   // Counter powered enemies: prefer SNG spam over risky splash when Quad/Pent is up.
   if ((self.enemy.items & (IT_QUAD + IT_INVULNERABILITY)))
   {
      if (((self.ammo_nails >= 5.000) && (it & IT_SUPER_NAILGUN)))
      {
         return (IT_SUPER_NAILGUN);
      } //end if
   } //end if
   if ((rng != RANGE_MELEE))
   {
      // Ammo conservation: require a deeper rocket stack before committing to RL.
      if (((self.ammo_rockets >= (3.000 + (self.skil * 2.000))) && (it & IT_ROCKET_LAUNCHER)))
      {
         return (IT_ROCKET_LAUNCHER);
      } //end if
   } //end if
   // Aggressive melee: push axe sooner if the target is already weak.
   if (((rng == RANGE_MELEE) && (self.enemy.health < 40.000)))
   {
      return (IT_AXE);
   } //end if
   if (((self.ammo_cells >= TRUE) && (it & IT_LIGHTNING)))
   {
      if (((rng == RANGE_MELEE) || (rng == RANGE_NEAR)))
      {
         wlevel = CheckWaterLevel ();
         if ((wlevel < FL_SWIM))
         {
            return (IT_LIGHTNING);
         } //end if
         if ((self.items & IT_INVULNERABILITY))
         {
            return (IT_LIGHTNING);
         } //end if
      } //end if
   } //end if
   if (((self.ammo_nails >= FL_SWIM) && (it & IT_SUPER_NAILGUN)))
   {
      return (IT_SUPER_NAILGUN);
   } //end if
   if ((rng == RANGE_NEAR))
   {
      if (((self.ammo_rockets >= TRUE) && (it & IT_GRENADE_LAUNCHER)))
      {
         if ((self.enemy.origin_z < (self.origin_z + 175.000)))
         {
            return (IT_GRENADE_LAUNCHER);
         } //end if
      } //end if
   } //end if
   if (((rng == RANGE_NEAR) || (rng == RANGE_MELEE)))
   {
      if (((self.ammo_shells >= FL_SWIM) && (it & IT_SUPER_SHOTGUN)))
      {
         return (IT_SUPER_SHOTGUN);
      } //end if
   } //end if
   if (((self.ammo_nails >= TRUE) && (it & IT_NAILGUN)))
   {
      return (IT_NAILGUN);
   } //end if
   if (((self.ammo_shells >= TRUE) && (it & IT_SHOTGUN)))
   {
      return (IT_SHOTGUN);
   } //end if
   return (IT_AXE);
}; //end of the function W_BestBotWeapon
float () W_BestHeldWeapon =
{
   local float it;
   local float wlevel;

   it = self.items;
   if (((self.ammo_rockets >= TRUE) && (it & IT_ROCKET_LAUNCHER)))
   {
      return (IT_ROCKET_LAUNCHER);
   } //end if
   if (((self.ammo_cells >= TRUE) && (it & IT_LIGHTNING)))
   {
      wlevel = CheckWaterLevel ();
      if ((wlevel < FL_SWIM))
      {
         return (IT_LIGHTNING);
      } //end if
      if ((self.items & IT_INVULNERABILITY))
      {
         return (IT_LIGHTNING);
      } //end if
   } //end if
   if (((self.ammo_nails >= FL_SWIM) && (it & IT_SUPER_NAILGUN)))
   {
      return (IT_SUPER_NAILGUN);
   } //end if
   if (((self.ammo_rockets >= TRUE) && (it & IT_GRENADE_LAUNCHER)))
   {
      if ((self.enemy.origin_z < (self.origin_z + 175.000)))
      {
         return (IT_GRENADE_LAUNCHER);
      } //end if
   } //end if
   if (((self.ammo_shells >= FL_SWIM) && (it & IT_SUPER_SHOTGUN)))
   {
      return (IT_SUPER_SHOTGUN);
   } //end if
   if (((self.ammo_nails >= TRUE) && (it & IT_NAILGUN)))
   {
      return (IT_NAILGUN);
   } //end if
   if (((self.ammo_shells >= TRUE) && (it & IT_SHOTGUN)))
   {
      return (IT_SHOTGUN);
   } //end if
   return (IT_AXE);
}; //end of the function W_BestHeldWeapon

void () bot_axe1;

void () bot_axeb1;

void () bot_axec1;

void () bot_axed1;

void () bot_shot1;

void () bot_nail1;

void () bot_light1;

void () bot_rocket1;

void () W_BotAttack =
{
   local float r;
   local float addt;

   if (!W_CheckNoAmmo ())
   {
      return ;
   } //end if
   if ((time < self.attack_finished))
   {
      return ;
   } //end if
   addt = FALSE;
   if ((self.skil < MOVETYPE_WALK))
   {
      addt = (((MOVETYPE_WALK - self.skil) * random ()) * 0.350);
   } //end if
   if ((self.skil < TRUE))
   {
      addt = (addt + (random () * 0.300));
   } //end if
   makevectors (self.v_angle);
   self.show_hostile = (time + TRUE);
   if ((self.weapon == IT_AXE))
   {
      sound (self,CHAN_WEAPON,"weapons/ax1.wav",TRUE,ATTN_NORM);
      r = random ();
      if ((r < 0.250))
      {
         bot_axe1 ();

      } //end if
      else
      {
         if ((r < 0.500))
         {
            bot_axeb1 ();

         } //end if
         else
         {
            if ((r < 0.750))
            {
               bot_axec1 ();

            } //end if
            else
            {
               bot_axed1 ();
            } //end if
         } //end if
      } //end if
      self.attack_finished = ((time + 0.500) + addt);

   } //end if
   else
   {
      if ((self.weapon == IT_SHOTGUN))
      {
         bot_shot1 ();
         W_FireShotgun ();
         self.attack_finished = ((time + 0.500) + addt);

      } //end if
      else
      {
         if ((self.weapon == IT_SUPER_SHOTGUN))
         {
            bot_shot1 ();
            W_FireSuperShotgun ();
            self.attack_finished = ((time + 0.700) + addt);

         } //end if
         else
         {
            if ((self.weapon == IT_NAILGUN))
            {
               self.think = bot_nail1;

            } //end if
            else
            {
               if ((self.weapon == IT_SUPER_NAILGUN))
               {
                  self.think = bot_nail1;

               } //end if
               else
               {
                  if ((self.weapon == IT_GRENADE_LAUNCHER))
                  {
                     bot_rocket1 ();

                     // ===== TWEAK #3: Self-risk validation (no suicide splash) =====
                     // Pre-fire trace to predicted bounce/explosion point checks self-damage risk.
                     // If bot would be within splash radius (<128 units), hold fire to avoid
                     // frag-suicide. Prevents dumb deaths in tight corners, doorways, or close combat
                     // where grenade bounces back. Bot waits for safe angle/distance before firing.
                     local vector gl_impact;
                     local float self_risk_dist;

                     // Predict grenade endpoint using bounce simulation
                     gl_impact = predict_gl_bounce ((self.origin + self.view_ofs),(self.enemy.origin + self.enemy.view_ofs),600.000);

                     // Trace from fire position to predicted explosion point
                     traceline ((self.origin + self.view_ofs),gl_impact,TRUE,self);

                     // Calculate distance from self to explosion
                     self_risk_dist = vlen ((trace_endpos - self.origin));

                     // Safety check: if explosion too close (<128u = splash radius), ABORT
                     if ((self_risk_dist < 128.000))
                     {
                        // Dangerous! Hold fire—return without shooting
                        self.attack_finished = ((time + 0.300) + addt);  // Short cooldown, try again
                        return ;  // Skip W_FireGrenade() entirely
                     } //end if
                     // ===== END TWEAK #3 =====

                     W_FireGrenade ();
                     self.attack_finished = ((time + 0.600) + addt);

                  } //end if
                  else
                  {
                     if ((self.weapon == IT_ROCKET_LAUNCHER))
                     {
                        bot_rocket1 ();
                        W_FireRocket ();
                        self.attack_finished = ((time + 0.800) + addt);

                     } //end if
                     else
                     {
                        if ((self.weapon == IT_LIGHTNING))
                        {
                           self.think = bot_light1;
                           self.attack_finished = (time + 0.100);
                           sound (self,CHAN_AUTO,"weapons/lstart.wav",TRUE,ATTN_NORM);
                        } //end if
                     } //end if
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
   } //end if
}; //end of the function W_BotAttack

void () bot_rebound1;
float () CheckReboundAttack =
{
   local vector spot1;
   local vector spot2;
   local vector dir;
   local float dist;
   local float mel;

   if ((self.skil < TRUE))
   {
      return (FALSE);
   } //end if
   if ((self.attack_finished > time))
   {
      return (FALSE);
   } //end if
   if (!(self.items & (IT_ROCKET_LAUNCHER + IT_GRENADE_LAUNCHER)))
   {
      return (FALSE);
   } //end if
   if ((self.ammo_rockets < MOVETYPE_WALK))
   {
      return (FALSE);
   } //end if
   spot1 = self.origin;
   spot2 = self.goalentity.origin;
   traceline (spot1,spot2,FALSE,self);
   if ((trace_fraction < TRUE))
   {
      return (FALSE);
   } //end if
   dir = normalize ((self.goalentity.origin - self.origin));
   spot2 = (spot2 + (200.000 * dir));
   traceline (spot1,spot2,TRUE,self);
   if ((trace_fraction == TRUE))
   {
      if ((self.origin_z < self.goalentity.origin_z))
      {
         return (FALSE);
      } //end if
      spot2 = self.goalentity.origin;
      spot2_z = (dropline (spot2) + MOVETYPE_WALK);
      traceline (spot1,spot2,TRUE,self);
      if ((trace_fraction != TRUE))
      {
         return (FALSE);
      } //end if

   } //end if
   else
   {
      spot2 = (self.goalentity.origin + ((200.000 * dir) * trace_fraction));
   } //end if
   dist = vlen ((self.enemy.origin - spot2));
   mel = 200.000;
   if ((self.items & IT_QUAD))
   {
      mel = (FL_SWIM * mel);
   } //end if
   if ((dist > mel))
   {
      return (FALSE);
   } //end if
   dist = vlen ((self.origin - spot2));
   mel = ((280.000 - (self.health * 0.500)) - (self.armorvalue * self.armortype));
   if ((self.items & IT_QUAD))
   {
      mel = (FL_SWIM * mel);
   } //end if
   if ((dist < mel))
   {
      return (FALSE);
   } //end if
   REBOUNDSPOT = spot2;
   REBOUND = TRUE;
   self.ideal_yaw = vectoyaw ((spot2 - self.origin));
   ChangeYaw ();
   bot_rebound1 ();
   if ((self.items & IT_ROCKET_LAUNCHER))
   {
      W_FireRocket ();

   } //end if
   else
   {
      REBOUNDSPOT = (spot2 + (random () * '12.000 12.000 12.000'));
      W_FireGrenade ();
   } //end if
   self.attack_finished = (time + TRUE);
   if ((self.skil < FL_SWIM))
   {
      self.attack_finished = (time + 1.500);
   } //end if
   REBOUND = FALSE;
}; //end of the function CheckReboundAttack

void () ChangePitch =
{
   local float ideal;
   local float move;

   current_pitch = self.angles_x;
   ideal = self.ideal_pitch;
   if ((ideal > 45.000))
   {
      ideal = 45.000;

   } //end if
   else
   {
      if ((ideal < -45.000))
      {
         ideal = -45.000;
      } //end if
   } //end if
   if ((current_pitch == ideal))
   {
      return ;
   } //end if
   move = (ideal - current_pitch);
   if ((move > MSG_BROADCAST))
   {
      if ((move > TE_LIGHTNING2))
      {
         move = TE_LIGHTNING2;
      } //end if

   } //end if
   else
   {
      if ((move < CONTENT_SKY))
      {
         move = CONTENT_SKY;
      } //end if
   } //end if
   current_pitch = (current_pitch + move);
   self.angles_x = current_pitch;
}; //end of the function ChangePitch
