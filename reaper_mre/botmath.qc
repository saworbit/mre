// ===== BOT MATH: Mathematical Solvers Suite =====
// PHASE 4 REFACTOR: Separated from botfight.qc and botmove.qc
// Contains all physics-based decision-making functions.
// Clean separation of math from combat/movement logic.

// ===== SQRT APPROXIMATION: Newton-Raphson Method =====
// QuakeC has no built-in sqrt(), so we implement it via iterative approximation.
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
// Uses quadratic formula to compute time-to-intercept accounting for perpendicular velocity.
// Formula: t = [-b ± sqrt(b² - 4ac)] / 2a, where a = v² - s², b = 2(D·v), c = |D|²
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

   // ===== MOVING PLATFORM COMPENSATION =====
   // If target is standing on a moving entity (train, door, platform),
   // add the platform's velocity to the target's velocity for accurate prediction.
   // Without this, bots miss targets riding trains/elevators.
   v = targ.velocity;

   if ((targ.flags & FL_ONGROUND) && targ.groundentity)
   {
      // Check if standing on a moving platform
      if ((targ.groundentity.classname == "func_train") ||
          (targ.groundentity.classname == "func_door") ||
          (targ.groundentity.classname == "func_plat"))
      {
         // Add platform velocity to target velocity (relative motion)
         v = (v + targ.groundentity.velocity);
      } //end if
   } //end if
   // ===== END MOVING PLATFORM COMPENSATION =====

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

// ===== SKILL-BASED ACCURACY DEGRADATION =====
// Adds random inaccuracy to aim based on bot skill level.
// Makes lower-skill bots miss more often, creating human-like imperfection.
// Skill 0-1: 30-40% accuracy (large random offset)
// Skill 2: 85% accuracy (small random offset)
// Skill 3: 100% accuracy (perfect aim, no offset)
vector (vector perfect_aim, float skill_level) DegradeAimBySkill =
{
   local vector offset;
   local float max_offset;
   local vector degraded_aim;

   // Skill 3: Perfect aim (no degradation)
   if ((skill_level >= 3.000))
   {
      return (perfect_aim);
   } //end if

   // Calculate max offset based on skill
   // Skill 0: 70 units offset at 500u range (~8° cone of error)
   // Skill 1: 50 units offset at 500u range (~6° cone of error)
   // Skill 2: 15 units offset at 500u range (~2° cone of error)
   if ((skill_level < 1.000))
   {
      max_offset = 70.000;
   } //end if
   else if ((skill_level < 2.000))
   {
      max_offset = 50.000;
   } //end if
   else
   {
      max_offset = 15.000;
   } //end if

   // Generate random offset in 3D
   // Each axis gets random value between -max_offset and +max_offset
   offset_x = ((random () * max_offset * 2.000) - max_offset);
   offset_y = ((random () * max_offset * 2.000) - max_offset);
   offset_z = ((random () * max_offset * 2.000) - max_offset);

   // Add offset to perfect aim vector
   // Scale perfect_aim to ~500 units for consistent offset behavior
   degraded_aim = ((perfect_aim * 500.000) + offset);

   // Return normalized degraded aim
   return (normalize (degraded_aim));
}; //end of the function DegradeAimBySkill
// ===== END SKILL-BASED ACCURACY DEGRADATION =====

// ===== PREDICTION DEBUG VISUALIZATION =====
// Shows predicted impact point and aim cone for debugging prediction accuracy.
// Spawns colored particles at intercept point for visual feedback.
// Blue = Perfect prediction, Yellow = Degraded aim (skill-based inaccuracy)
void (vector aim_dir, entity targ, float range, float is_degraded) ShowPredictionDebug =
{
   local vector impact_point;
   local float particle_color;
   local float particle_count;

   // Only show if bot debug is enabled
   if (!bot_debug_enabled)
   {
      return ;
   } //end if

   // Calculate predicted impact point
   impact_point = (self.origin + (aim_dir * range));

   // Choose particle color based on whether aim was degraded
   if (is_degraded)
   {
      particle_color = 224.000; // Yellow (degraded aim)
      particle_count = 10.000;
   } //end if
   else
   {
      particle_color = 203.000; // Blue (perfect aim)
      particle_count = 15.000;
   } //end if

   // Spawn particles at predicted impact point
   particle (impact_point,'0.000 0.000 30.000',particle_color,particle_count);

   // Draw line of sight (small particles along aim vector)
   local vector step;
   local float i;
   step = (aim_dir * 50.000);
   i = 0.000;
   while ((i < 10.000))
   {
      particle ((self.origin + (step * i)),'0.000 0.000 10.000',particle_color,2.000);
      i = (i + 1.000);
   } //end while
}; //end of the function ShowPredictionDebug
// ===== END PREDICTION DEBUG VISUALIZATION =====

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

// ===== CALCULATED ROCKET JUMP: Physics Feasibility Check =====
// Calculates maximum height achievable via rocket jump using physics equation.
// Used to prevent bots from attempting impossible jumps (e.g., 500-unit walls).
// Formula: max_height = V₀² / (2g), where V₀ = jump_vel + rocket_boost
// Prevents bots from attempting impossible RJs (e.g., 500-unit walls).
float (float target_height) CanRocketJumpHeight =
{
   local float jump_vel;
   local float rocket_boost;
   local float total_vel;
   local float max_height;
   local float g;

   // Quake physics constants
   jump_vel = 270.000; // Standard jump velocity
   rocket_boost = 280.000; // Rocket explosion boost (approximate, varies with distance)
   g = 800.000; // Gravity

   // Total initial velocity (jump + rocket)
   total_vel = (jump_vel + rocket_boost);

   // Calculate maximum height: h = V₀² / (2g)
   max_height = (((total_vel * total_vel) / (2.000 * g)));

   // Add 20-unit safety margin for precision errors
   max_height = (max_height + 20.000);

   // Check if target is within range
   if ((target_height <= max_height))
   {
      return (TRUE); // Physically possible
   } //end if

   return (FALSE); // Impossible: target too high
}; //end of the function CanRocketJumpHeight
// ===== END CALCULATED ROCKET JUMP =====

// ===== GAP SOLVER: Suicide Prevention (Horizontal Range Check) =====
// Calculates if bot can make a horizontal jump across a gap without falling to death.
// Uses physics: time_to_fall = sqrt(2h/g), max_distance = velocity × time
// Returns TRUE if gap is crossable, FALSE if bot will fall into lava/void.
// Prevents suicidal cliff runs by checking if horizontal speed can cover the gap.
float (float gap_width, float drop_height) CanCrossGap =
{
   local float t;
   local float max_dist;
   local float run_speed;
   local float g;

   // Quake physics constants
   run_speed = 320.000; // Bot running speed (units/second)
   g = 800.000; // Gravity

   // 1. Calculate time to fall: t = sqrt(2h / g) = sqrt(h / 400)
   t = qc_sqrt ((drop_height / 400.000));

   // 2. Calculate max horizontal distance: d = velocity × time
   max_dist = (run_speed * t);

   // 3. Add 20-unit safety buffer (bot collision radius + precision errors)
   max_dist = (max_dist - 20.000);

   // 4. Check if gap is within safe crossing range
   if ((gap_width <= max_dist))
   {
      return (TRUE); // Safe to cross
   } //end if

   return (FALSE); // Too far: bot will fall to death
}; //end of the function CanCrossGap
// ===== END GAP SOLVER =====

// ===== FUZZY LOGIC: Smooth Curve Helpers =====
// Eliminates "cliff edge" behavior in AI decision-making by using continuous curves
// instead of hard thresholds. Creates more organic, human-like transitions.
// Example: Instead of "if HP < 40 then +500", use smooth scaling from 0-500.

// Linear interpolation: blend between a and b based on t (0.0 to 1.0)
// lerp(10, 50, 0.0) = 10, lerp(10, 50, 0.5) = 30, lerp(10, 50, 1.0) = 50
float (float a, float b, float t) lerp =
{
   return (a + ((b - a) * t));
}; //end of lerp

// Clamp value to range [min, max]
// clamp(150, 0, 100) = 100, clamp(-10, 0, 100) = 0, clamp(50, 0, 100) = 50
float (float value, float min_val, float max_val) clamp =
{
   if ((value < min_val))
   {
      return (min_val);
   } //end if
   if ((value > max_val))
   {
      return (max_val);
   } //end if
   return (value);
}; //end of clamp

// Inverse lerp: convert value in range [min, max] to normalized 0-1
// inverse_lerp(30, 10, 50) = 0.5, inverse_lerp(10, 10, 50) = 0.0
float (float value, float min_val, float max_val) inverse_lerp =
{
   local float range;
   range = (max_val - min_val);
   if ((range == 0.000))
   {
      return (0.000); // Avoid divide by zero
   } //end if
   return (clamp (((value - min_val) / range), 0.000, 1.000));
}; //end of inverse_lerp

// Smooth exponential curve: accelerates near edges
// power > 1.0 = accelerating curve (slow start, fast finish)
// power < 1.0 = decelerating curve (fast start, slow finish)
// smooth_curve(50, 0, 100, 2.0) = quadratic acceleration
float (float value, float min_val, float max_val, float power) smooth_curve =
{
   local float t;
   t = inverse_lerp (value, min_val, max_val);

   // Apply power function (t^power)
   // QuakeC has no built-in pow(), so we handle common cases manually
   if ((power == 2.000))
   {
      t = (t * t); // Quadratic
   } //end if
   else if ((power == 3.000))
   {
      t = ((t * t) * t); // Cubic
   } //end if
   else if ((power == 0.500))
   {
      t = qc_sqrt (t); // Square root (deceleration)
   } //end if
   // For other powers, use linear (limitation of QuakeC)

   return (t);
}; //end of smooth_curve

// Inverse smooth curve: 1.0 at min_val, 0.0 at max_val (reversed)
// Used for "desire" calculations where low values = high desire
// Example: Health desire is HIGH when HP is LOW
float (float value, float min_val, float max_val, float power) inverse_smooth_curve =
{
   return ((1.000 - smooth_curve (value, min_val, max_val, power)));
}; //end of inverse_smooth_curve
// ===== END FUZZY LOGIC =====
