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

// ===== SQRT APPROXIMATION: Newton-Raphson Method =====
// QuakeC doesn't have built-in sqrt(), so implement fast approximation.
// Uses Newton's method: x_new = 0.5 * (x + n/x)
// Converges quickly (3-4 iterations for good accuracy).
float (float n) qc_sqrt =
{
   local float x;
   local float x_new;
   local float epsilon;

   // Handle edge cases
   if ((n <= FALSE))
   {
      return (FALSE);
   } //end if

   if ((n == TRUE))
   {
      return (TRUE);
   } //end if

   // Initial guess: n/2 (simple but works)
   x = (n * 0.500);

   // Newton-Raphson iteration (4 iterations = good accuracy)
   epsilon = 0.001;

   // Iteration 1
   x_new = (0.500 * (x + (n / x)));
   if ((fabs ((x_new - x)) < epsilon))
   {
      return (x_new);
   } //end if
   x = x_new;

   // Iteration 2
   x_new = (0.500 * (x + (n / x)));
   if ((fabs ((x_new - x)) < epsilon))
   {
      return (x_new);
   } //end if
   x = x_new;

   // Iteration 3
   x_new = (0.500 * (x + (n / x)));
   if ((fabs ((x_new - x)) < epsilon))
   {
      return (x_new);
   } //end if
   x = x_new;

   // Iteration 4 (final)
   x_new = (0.500 * (x + (n / x)));
   return (x_new);
}; //end of the function qc_sqrt
// ===== END SQRT APPROXIMATION =====

// ===== ORACLE AIMING: Quadratic Prediction (Perfect Interception) =====
// Solves the interception problem: where to aim a projectile to hit a moving target.
// Uses quadratic equation to find exact time-to-intercept based on:
// - Projectile speed (e.g., 1000 u/s for rockets)
// - Enemy velocity (current movement vector)
// - Relative position (distance and direction to target)
// This is mathematically perfect aim that accounts for perpendicular strafing.
// Much more accurate than simple linear leading for skilled bots.
vector (entity targ, float proj_speed) PredictAim =
{
   local vector D;
   local vector v;
   local float a;
   local float b;
   local float c;
   local float det;
   local float t1;
   local float t2;
   local float t;
   local vector aim_spot;
   local float sqrt_det;

   // Calculate relative position vector (D = target - shooter)
   D = (targ.origin - self.origin);

   // Adjust for target height (aim at chest/center, not origin floor)
   D_z = (D_z + ((targ.mins_z + targ.maxs_z) * 0.500));

   // Get target velocity
   v = targ.velocity;

   // ===== QUADRATIC EQUATION SETUP =====
   // Solving: t^2 * (v^2 - s^2) + t * (2 * D·v) + |D|^2 = 0
   // Where: v = enemy velocity, s = projectile speed, D = relative position

   // Coefficient a: (v·v - s^2)
   a = ((v_x * v_x) + (v_y * v_y) + (v_z * v_z)) - (proj_speed * proj_speed);

   // Coefficient b: 2 * (D·v)
   b = (2.000 * ((D_x * v_x) + (D_y * v_y) + (D_z * v_z)));

   // Coefficient c: |D|^2
   c = ((D_x * D_x) + (D_y * D_y) + (D_z * D_z));

   // ===== SOLVE DETERMINANT =====
   det = ((b * b) - (4.000 * a * c));

   // Impossible shot (imaginary solution) - just aim straight at them
   if ((det < FALSE))
   {
      return (normalize (D));
   } //end if

   // ===== SOLVE FOR TIME (t) =====
   sqrt_det = qc_sqrt (det);

   // Two possible solutions (quadratic formula)
   t1 = (((- b) + sqrt_det) / (2.000 * a));
   t2 = (((- b) - sqrt_det) / (2.000 * a));

   // Pick the smallest positive time (soonest intercept in future)
   if (((t1 < FALSE) && (t2 < FALSE)))
   {
      // Both solutions are in the past - just aim straight
      return (normalize (D));
   } //end if

   if ((t1 < FALSE))
   {
      t = t2;
   } //end if
   else
   {
      if ((t2 < FALSE))
      {
         t = t1;
      } //end if
      else
      {
         // Both positive - pick smaller (sooner intercept)
         if ((t1 < t2))
         {
            t = t1;
         } //end if
         else
         {
            t = t2;
         } //end if
      } //end if
   } //end if

   // ===== CALCULATE INTERCEPT POINT =====
   // Where the enemy will be at time t: origin + velocity * t
   aim_spot = (targ.origin + (v * t));

   // Return normalized direction vector to intercept point
   return (normalize ((aim_spot - self.origin)));
}; //end of the function PredictAim
// ===== END ORACLE AIMING =====

// ===== ARTILLERY SOLVER: Perfect Grenade Arc (Quadratic Equation) =====
// Solves projectile motion equation to find optimal grenade aim point.
// Uses full quadratic solution: θ = (v² ± sqrt(v⁴ - g(g·x² + 2·y·v²))) / (g·x)
// Returns optimal aim vector. Returns world origin if shot impossible.
// High-skill bots (skill > 2) use this for perfect mortar-style grenade arcs.
vector (vector target_pos) SolveGrenadeArc =
{
   local vector v_diff;
   local float dx;
   local float dy;
   local float v;
   local float g;
   local float term1;
   local float root;
   local float tan_angle; // tan(θ) instead of θ
   local vector dir;
   local float t;
   local vector aim_point;

   // Calculate horizontal distance and height difference
   v_diff = (target_pos - self.origin);
   dy = v_diff_z; // Height difference (vertical)
   v_diff_z = FALSE;
   dx = vlen (v_diff); // Horizontal distance
   dir = normalize (v_diff); // Horizontal direction

   // Quake physics constants
   v = 600.000; // Grenade speed (units/second)
   g = 800.000; // Gravity (units/second²)

   // Quadratic discriminant: v⁴ - g(g·x² + 2·y·v²)
   term1 = ((((v * v) * v) * v) - (g * (((g * dx) * dx) + (((2.000 * dy) * v) * v))));

   // Check if shot is possible (discriminant must be non-negative)
   if ((term1 < FALSE))
   {
      // Impossible shot: use fallback aim
      return ('0.000 0.000 0.000'); // Signal failure with zero vector
   } //end if

   // Take square root of discriminant
   root = qc_sqrt (term1);

   // Two solutions: high arc (+ root) or low arc (- root)
   // Use LOW ARC for direct combat: tan(θ) = (v² - sqrt) / (g·x)
   tan_angle = ((((v * v) - root) / (g * dx))); // tan(θ)

   // Calculate flight time from horizontal distance
   // For low arc: t ≈ x / (v × cos(θ)) ≈ x / v (approximation for small angles)
   t = (dx / v);

   // Calculate vertical offset needed: z_offset = tan(θ) × dx
   local float z_offset;
   z_offset = (tan_angle * dx);

   // Construct aim point: horizontal direction × distance + vertical offset
   aim_point = ((self.origin + (dir * dx)) + ('0.000 0.000 1.000' * z_offset));

   return (aim_point);
}; //end of the function SolveGrenadeArc
// ===== END ARTILLERY SOLVER =====

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
            // ===== ORACLE AIMING: Use quadratic prediction for high-skill bots =====
            // Skill > 2: Use perfect interception math (PredictAim)
            // Skill <= 2: Use simple linear leading (leadtarget)
            if ((self.skil > 2.000))
            {
               // Perfect aim: solves quadratic equation for exact intercept
               // Rocket speed: 1000 units/second
               local vector aim_dir;
               aim_dir = PredictAim (self.enemy,1000.000);

               // Convert direction back to target point for floor shooting logic
               tg = (src + (aim_dir * vlen ((self.enemy.origin - src))));
            } //end if
            else
            {
               // Standard linear leading for lower-skill bots
               tg = leadtarget (src,tg,0.001);
            } //end if
            // ===== END ORACLE AIMING =====

            // ===== SPLASH MASTERY: Floor Shooting (The 'Floor Frag') =====
            // Don't aim at chest—aim at feet. Rockets that hit the floor always splash,
            // even if direct-body trace misses. Forces guaranteed 80+ splash damage.
            if ((self.enemy.flags & FL_ONGROUND))
            {
               // Aim slightly INTO floor beneath enemy to guarantee ground detonation
               // (-4 units ensures rocket hits solid ground, not air above feet)
               tg_z = (self.enemy.absmin_z - 4.000);

               // Validate shot will actually hit something near enemy (120u = splash radius)
               traceline (src,tg,TRUE,self);
               if ((trace_fraction != TRUE))
               {
                  local float splash_dist;
                  splash_dist = vlen ((trace_endpos - self.enemy.origin));

                  // If blockage is too far from enemy, fall back to chest aim
                  if ((splash_dist > 120.000))
                  {
                     tg_z = (self.enemy.origin_z + (self.enemy.view_ofs_z * 0.500));
                  } //end if
               } //end if
            } //end if
            else
            {
               // Enemy airborne: use standard chest/splash randomization
               splash_z = (self.enemy.mins_z + (random () * (self.enemy.view_ofs_z - self.enemy.mins_z)));
               tg_z = (tg_z + splash_z);
            } //end if
            // ===== END SPLASH MASTERY: Floor Shooting =====

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
   // ===== ARTILLERY SOLVER: Skill-based Grenade Aiming =====
   if ((self.weapon == IT_GRENADE_LAUNCHER))
   {
      if ((self.skil > 2.000))
      {
         // High-skill bots use perfect quadratic arc calculation
         local vector arc_aim;
         arc_aim = SolveGrenadeArc (tg);

         // If shot is possible (non-zero vector), use Artillery Solver
         if ((arc_aim != '0.000 0.000 0.000'))
         {
            // Use the mathematically perfect aim point
            tg = arc_aim;
         } //end if
         else
         {
            // Impossible shot - fall back to approximate arc
            tg = adjustgrenade (tg);
         } //end if
      } //end if
      else
      {
         // Low-skill bots use approximate arc (adjustgrenade)
         tg = adjustgrenade (tg);
      } //end if
   } //end if
   // ===== END ARTILLERY SOLVER =====
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
      // ===== SPLASH MASTERY: Corner Clipping (Indirect Splash) =====
      // Can't see enemy directly, but can we splash them around a corner?
      // If holding splash weapon (RL/GL), allow firing if trace hits wall/floor near enemy.
      if ((self.weapon & (IT_ROCKET_LAUNCHER + IT_GRENADE_LAUNCHER)))
      {
         local float wall_dist;

         // Did we hit a wall/floor instead of the enemy?
         if ((trace_fraction < TRUE))
         {
            // Check distance from wall hit to enemy position
            wall_dist = vlen ((trace_endpos - targ.origin));

            // If wall is close to enemy (110u = splash radius minus safety margin), shoot it!
            if ((wall_dist < 110.000))
            {
               self.attack_state = AS_MISSILE;
               return (TRUE);
            } //end if

            // Try aiming at feet for floor splash
            spot2 = targ.origin;
            spot2_z = (targ.absmin_z + 8.000);
            traceline (spot1,spot2,TRUE,self);

            if ((trace_fraction < TRUE))
            {
               wall_dist = vlen ((trace_endpos - targ.origin));
               if ((wall_dist < 110.000))
               {
                  self.attack_state = AS_MISSILE;
                  return (TRUE);
               } //end if
            } //end if
         } //end if
      } //end if
      // ===== END SPLASH MASTERY: Corner Clipping =====

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

   // ===== SPLASH MASTERY: Suicide Prevention (Safety Check) =====
   // Don't use Rocket Launcher at point-blank range—prioritize safe weapons first.
   // If enemy is in melee range, use SSG/SNG/LG to avoid rocket suicide.
   if ((rng == RANGE_MELEE))
   {
      // Prefer Super Shotgun at melee range (safe, high burst damage)
      if (((self.ammo_shells >= 2.000) && (it & IT_SUPER_SHOTGUN)))
      {
         return (IT_SUPER_SHOTGUN);
      } //end if

      // Prefer Super Nailgun at melee range (safe, high DPS)
      if (((self.ammo_nails >= 10.000) && (it & IT_SUPER_NAILGUN)))
      {
         return (IT_SUPER_NAILGUN);
      } //end if

      // Prefer Lightning Gun at melee range (safe, instant damage)
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

      // Only use rockets if no safe alternatives (last resort)
      // Fall through to standard weapon logic below
   } //end if
   // ===== END SPLASH MASTERY: Suicide Prevention =====

   if ((rng != RANGE_MELEE))
   {
      // Ammo conservation: require a deeper rocket stack before committing to RL.
      if (((self.ammo_rockets >= (3.000 + (self.skil * 2.000))) && (it & IT_ROCKET_LAUNCHER)))
      {
         return (IT_ROCKET_LAUNCHER);
      } //end if
   } //end if

   // ===== FINISHER LOGIC: Don't Waste Rockets on Near-Dead Enemies =====
   // If enemy is very weak (< 20 HP) and close, prioritize shotgun or axe over rockets.
   // This saves ammo and prevents wasting a rocket on a target with 5 HP.
   if (((self.enemy.health < 20.000) && (rng < RANGE_NEAR)))
   {
      // Use Shotgun for reliable hitscan finish
      if ((it & IT_SHOTGUN))
      {
         return (IT_SHOTGUN);
      } //end if
      // Fall through to axe if no shotgun
   } //end if
   // ===== END FINISHER LOGIC =====

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

   // ===== HUMAN REACTION TIME: Block Firing During Delay =====
   // Don't fire at enemy until reaction time has passed
   if ((time < self.reaction_finished)) return;
   // ===== END HUMAN REACTION TIME =====

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
