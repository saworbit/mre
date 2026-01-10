// ===== INFLUENCE MAP SYSTEM: Graph-Based Tactical Awareness =====
// Implements dynamic danger/interest scoring on the waypoint graph for tactical pathfinding.
// Uses lazy decay (event-driven updates) instead of per-frame calculations for performance.
// Bots route around danger zones (explosions, deaths) and toward interest points (powerups).

// ===== HELPER: Find Closest Waypoint to Position =====
// Scans all BotPath entities to find the nearest waypoint to a given location.
// Used to apply influence at explosion/death sites.
entity (vector org) FindClosestWaypoint =
{
   local entity best;
   local entity e;
   local float best_dist;
   local float dist;

   best = world;
   best_dist = 999999.000;  // Large initial value

   e = find (world,classname,"BotPath");
   while (e)
   {
      dist = vlen ((e.origin - org));
      if ((dist < best_dist))
      {
         best_dist = dist;
         best = e;
      } //end if
      e = find (e,classname,"BotPath");
   } //end while

   return (best);
}; //end of the function FindClosestWaypoint

// ===== CORE: Get Current Danger with Lazy Decay =====
// Returns the current danger value for a waypoint, applying time-based decay.
// Decay formula: Linear drop of 10 points per second (simpler than exponential).
// Optimization: If waypoint hasn't been updated in 10+ seconds, danger is 0.
float (entity wp) Influence_GetDanger =
{
   local float decay_time;
   local float decayed_value;

   if ((!wp))
   {
      return (0.000);
   } //end if

   if ((wp.infl_danger <= 1.000))
   {
      return (0.000);
   } //end if

   decay_time = (time - wp.infl_last_update);

   // Optimization: If very old (10+ seconds), danger has fully decayed
   if ((decay_time > 10.000))
   {
      wp.infl_danger = 0.000;
      return (0.000);
   } //end if

   // Linear decay: -10 points per second
   // (Simpler than exponential pow() for QuakeC performance)
   decayed_value = (wp.infl_danger - (decay_time * 10.000));

   if ((decayed_value < 0.000))
   {
      decayed_value = 0.000;
   } //end if

   // Update stored value with decayed amount (lazy update)
   wp.infl_danger = decayed_value;
   wp.infl_last_update = time;

   return (decayed_value);
}; //end of the function Influence_GetDanger

// ===== CORE: Get Current Interest with Lazy Decay =====
// Returns the current interest value for a waypoint, applying time-based decay.
// Interest decays slower than danger (5 points/sec vs 10 points/sec).
float (entity wp) Influence_GetInterest =
{
   local float decay_time;
   local float decayed_value;

   if ((!wp))
   {
      return (0.000);
   } //end if

   if ((wp.infl_interest <= 1.000))
   {
      return (0.000);
   } //end if

   decay_time = (time - wp.infl_last_update);

   // Optimization: If very old (20+ seconds), interest has fully decayed
   if ((decay_time > 20.000))
   {
      wp.infl_interest = 0.000;
      return (0.000);
   } //end if

   // Linear decay: -5 points per second (slower than danger)
   decayed_value = (wp.infl_interest - (decay_time * 5.000));

   if ((decayed_value < 0.000))
   {
      decayed_value = 0.000;
   } //end if

   // Update stored value with decayed amount (lazy update)
   wp.infl_interest = decayed_value;
   wp.infl_last_update = time;

   return (decayed_value);
}; //end of the function Influence_GetInterest

// ===== EVENT HANDLER: Add Danger to Location =====
// Paints danger influence at a specific location and propagates to neighbors.
// Called by explosion events, bot deaths, and enemy fire detection.
void (vector org, float amount) Influence_AddDanger =
{
   local entity wp;
   local entity neighbor;
   local float current_danger;

   wp = FindClosestWaypoint (org);

   if ((wp == world))
   {
      return ;  // No waypoint network, skip influence
   } //end if

   // Update decay first so we add to the current real value
   current_danger = Influence_GetDanger (wp);

   wp.infl_danger = (current_danger + amount);
   if ((wp.infl_danger > 100.000))
   {
      wp.infl_danger = 100.000;  // Cap at 100
   } //end if
   wp.infl_last_update = time;

   // ===== SPATIAL PROPAGATION: Spread to Neighbors =====
   // Propagate 50% of danger to linked neighbors (falloff)
   // This creates "danger zones" instead of single-point spikes
   local float falloff_amount;
   falloff_amount = (amount * 0.500);

   if ((falloff_amount > 5.000))  // Only propagate if significant
   {
      // Propagate to movetarget (primary link)
      if (wp.movetarget)
      {
         neighbor = wp.movetarget;
         current_danger = Influence_GetDanger (neighbor);
         neighbor.infl_danger = (current_danger + falloff_amount);
         if ((neighbor.infl_danger > 100.000))
         {
            neighbor.infl_danger = 100.000;
         } //end if
         neighbor.infl_last_update = time;
      } //end if

      // Propagate to secondary links (movetarget2, movetarget3, movetarget4)
      if (wp.movetarget2)
      {
         neighbor = wp.movetarget2;
         current_danger = Influence_GetDanger (neighbor);
         neighbor.infl_danger = (current_danger + falloff_amount);
         if ((neighbor.infl_danger > 100.000))
         {
            neighbor.infl_danger = 100.000;
         } //end if
         neighbor.infl_last_update = time;
      } //end if

      if (wp.movetarget3)
      {
         neighbor = wp.movetarget3;
         current_danger = Influence_GetDanger (neighbor);
         neighbor.infl_danger = (current_danger + falloff_amount);
         if ((neighbor.infl_danger > 100.000))
         {
            neighbor.infl_danger = 100.000;
         } //end if
         neighbor.infl_last_update = time;
      } //end if

      if (wp.movetarget4)
      {
         neighbor = wp.movetarget4;
         current_danger = Influence_GetDanger (neighbor);
         neighbor.infl_danger = (current_danger + falloff_amount);
         if ((neighbor.infl_danger > 100.000))
         {
            neighbor.infl_danger = 100.000;
         } //end if
         neighbor.infl_last_update = time;
      } //end if
   } //end if
}; //end of the function Influence_AddDanger

// ===== EVENT HANDLER: Add Interest to Location =====
// Paints interest influence at a specific location (powerups, strategic points).
// Called by item spawn events and combat sound detection.
void (vector org, float amount) Influence_AddInterest =
{
   local entity wp;
   local float current_interest;

   wp = FindClosestWaypoint (org);

   if ((wp == world))
   {
      return ;  // No waypoint network, skip influence
   } //end if

   // Update decay first so we add to the current real value
   current_interest = Influence_GetInterest (wp);

   wp.infl_interest = (current_interest + amount);
   if ((wp.infl_interest > 100.000))
   {
      wp.infl_interest = 100.000;  // Cap at 100
   } //end if
   wp.infl_last_update = time;

   // Note: Interest typically doesn't propagate to neighbors
   // (Powerups are point targets, not area effects)
}; //end of the function Influence_AddInterest

// ===== DEBUG VISUALIZATION: Show Influence Map =====
// Draws colored particles at waypoints to visualize danger/interest levels.
// Red = Danger, Green = Interest (intensity based on value)
// Triggered by impulse 120 (player command)
void () Influence_ShowMap =
{
   local entity wp;
   local float danger;
   local float interest;
   local float particle_count;

   bprint ("\n");
   bprint ("===========================================\n");
   bprint ("  INFLUENCE MAP VISUALIZATION\n");
   bprint ("===========================================\n");
   bprint ("Red particles = Danger zones (explosions/deaths)\n");
   bprint ("Green particles = Interest zones (powerups/sounds)\n");
   bprint ("Particle intensity = Influence strength (0-100)\n");
   bprint ("\n");

   wp = find (world,classname,"BotPath");
   while (wp)
   {
      // Get current influence values (with lazy decay)
      danger = Influence_GetDanger (wp);
      interest = Influence_GetInterest (wp);

      // Visualize danger (red particles)
      if ((danger > 5.000))  // Only show significant danger
      {
         // Particle count scales with danger level (5-50 particles)
         particle_count = (danger * 0.500);
         if ((particle_count < 5.000))
         {
            particle_count = 5.000;
         } //end if
         if ((particle_count > 50.000))
         {
            particle_count = 50.000;
         } //end if

         // Spawn red particles (color 73 = bright red)
         particle (wp.origin,'0.000 0.000 50.000',73.000,particle_count);
      } //end if

      // Visualize interest (green particles)
      if ((interest > 5.000))  // Only show significant interest
      {
         // Particle count scales with interest level (5-50 particles)
         particle_count = (interest * 0.500);
         if ((particle_count < 5.000))
         {
            particle_count = 5.000;
         } //end if
         if ((particle_count > 50.000))
         {
            particle_count = 50.000;
         } //end if

         // Spawn green particles (color 115 = bright green)
         particle (wp.origin,'0.000 0.000 50.000',115.000,particle_count);
      } //end if

      wp = find (wp,classname,"BotPath");
   } //end while

   bprint ("Influence map displayed for 5 seconds.\n");
   bprint ("\n");
}; //end of the function Influence_ShowMap

// ===== END INFLUENCE MAP SYSTEM =====
