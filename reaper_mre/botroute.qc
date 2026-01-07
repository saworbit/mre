
void () t_botpath =
{
   if ((other.classname != "dmbot") && (other.classname != "player"))
   {
      return ;
   } //end if
   if ((other.movetarget == self))
   {
      return ;
   } //end if

   // ===== STREET SMARTS: Traffic Counter =====
   // Count every time a bot OR player steps here.
   // Cap at 100 to prevent overflow/math issues.
   if (self.traffic_score < 100)
   {
      self.traffic_score = self.traffic_score + 1;
   }
   // ==========================================

   bot_toucheditem ();
   addTarget (other.movetarget.movetarget,self);
   other.movetarget.movetarget = self;
}; //end of the function t_botpath
entity () botpath =
{
   local entity targ;

   targ = spawn ();
   targ.classname = "BotPath";
   targ.solid = SOLID_TRIGGER;
   targ.movetarget = world;
   targ.touch = t_botpath;
   setsize (targ,'-4.000 -4.000 -4.000','4.000 4.000 4.000');
   return (targ);
}; //end of the function botpath
float (entity a, entity b) IsUpstream =
{
   if ((b.movetarget == a))
   {
      return (TRUE);
   } //end if
   if ((b.movetarget2 == a))
   {
      return (TRUE);
   } //end if
   if ((b.movetarget3 == a))
   {
      return (TRUE);
   } //end if
   if ((b.movetarget4 == a))
   {
      return (TRUE);
   } //end if
   if ((b.movetarget5 == a))
   {
      return (TRUE);
   } //end if
   if ((b.movetarget6 == a))
   {
      return (TRUE);
   } //end if
   return (FALSE);
}; //end of the function IsUpstream

// PHASE 2 FIX: Add depth parameter for recursion safety
void (entity node, entity targ, float len, entity item, float depth) cacheRouteTarget;

void (entity a, entity b, float recurse) updateRouteCache =
{
   // PHASE 2 FIX: Pass depth as parameter instead of using global RECURSEDEPTH
   if ((b.rocketlen > FALSE))
   {
      cacheRouteTarget (b,a,b.rocketlen,b.rocketcache,recurse);
   } //end if
   if ((b.lightninglen > FALSE))
   {
      cacheRouteTarget (b,a,b.lightninglen,b.lightningcache,recurse);
   } //end if
   if ((b.armorlen > FALSE))
   {
      cacheRouteTarget (b,a,b.armorlen,b.armorcache,recurse);
   } //end if
   if ((b.poweruplen > FALSE))
   {
      cacheRouteTarget (b,a,b.poweruplen,b.powerupcache,recurse);
   } //end if
   if ((b.naillen > FALSE))
   {
      cacheRouteTarget (b,a,b.naillen,b.nailcache,recurse);
   } //end if
   if ((b.grenadelen > FALSE))
   {
      cacheRouteTarget (b,a,b.grenadelen,b.grenadecache,recurse);
   } //end if
}; //end of the function updateRouteCache

void (entity a, entity b) addTarget =
{
   if ((a == b))
   {
      return ;
   } //end if
   if ((b.movetarget == a))
   {
      return ;
   } //end if
   if (!a)
   {
      return ;

   } //end if
   else
   {
      if ((b.movetarget2 == a))
      {
         updateRouteCache (a,b,SECRET_YES_SHOOT);
         return ;

      } //end if
      else
      {
         if ((b.movetarget3 == a))
         {
            updateRouteCache (a,b,SECRET_YES_SHOOT);
            return ;

         } //end if
         else
         {
            if ((b.movetarget4 == a))
            {
               updateRouteCache (a,b,SECRET_YES_SHOOT);
               return ;

            } //end if
            else
            {
               if ((b.movetarget5 == a))
               {
                  updateRouteCache (a,b,SECRET_YES_SHOOT);
                  return ;

               } //end if
               else
               {
                  if ((b.movetarget6 == a))
                  {
                     updateRouteCache (a,b,SECRET_YES_SHOOT);
                     return ;
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
   } //end if
   if (!b.movetarget)
   {
      b.movetarget = a;

   } //end if
   else
   {
      if (!b.movetarget2)
      {
         b.movetarget2 = a;

      } //end if
      else
      {
         if (!b.movetarget3)
         {
            b.movetarget3 = a;

         } //end if
         else
         {
            if (!b.movetarget4)
            {
               b.movetarget4 = a;

            } //end if
            else
            {
               if (!b.movetarget5)
               {
                  b.movetarget5 = a;

               } //end if
               else
               {
                  if (!b.movetarget6)
                  {
                     b.movetarget6 = a;
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
   } //end if
   updateRouteCache (a,b,TE_LAVASPLASH);
}; //end of the function addTarget
float () FindAPath;
float () FindAPath_Greedy;
float () FindAPath_AStar;
entity (entity start, entity goal) AStarSolve;
float () FindAltPath =
{
   local entity e;
   local entity carriedPath;
   local entity bestPath;
   local float dropPath;
   local float bestrng;
   local float rng;

   if ((self.lefty & NODROP))
   {
      self.lefty = (self.lefty - NODROP);
      return (FindAPath ());
   } //end if
   e = findradius (self.origin,SEARCH_RADIUS);
   bestrng = 1000.000;
   dropPath = TRUE;
   carriedPath = self.movetarget;
   bestPath = carriedPath.movetarget;
   while (e)
   {
      if ((e.pathtype == DROPPED))
      {
         rng = vlen ((e.origin - self.origin));
         if ((rng < bestrng))
         {
            if (BotReachable (e,self))
            {
               if (BotReachable (carriedPath.movetarget,e))
               {
                  addTarget (carriedPath.movetarget,e);
                  bestPath = e;
                  bestrng = rng;
                  dropPath = FALSE;
                  // If this path is flagged for denial and the enemy is close, offset toward their velocity.
                  if (bestPath.deny_flag)
                  {
                     if (self.enemy)
                     {
                        if ((vlen ((self.enemy.origin - bestPath.origin)) < 400.000))
                        {
                           bestPath.origin = (bestPath.origin + (normalize (self.enemy.velocity) * 50.000));
                        } //end if
                     } //end if
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
      e = e.chain;
   } //end while
   carriedPath.movetarget = bestPath;
   return (dropPath);
}; //end of the function FindAltPath
// ===== A* INTEGRATION: Smart Path Selection =====
// High-skill bots (skill > 2) use A* for optimal routing.
// Low-skill bots use greedy search for human-like mistakes.
float () FindAPath_AStar =
{
   local entity start_node;
   local entity goal_node;
   local entity path_result;
   local entity first_step;
   local entity e;
   local float best_start_dist;
   local float best_goal_dist;
   local float dist;
   local entity carriedPath;
   local entity goal_entity;

   carriedPath = self.movetarget;
   goal_entity = self.goalentity.goalentity;

   // If no goal, fall back to greedy
   if (!goal_entity)
   {
      return (FindAPath_Greedy ());
   } //end if

   // ===== PHASE 2 FIX: A* START NODE CACHING =====
   // Check cached node first to avoid expensive findradius() calls (O(N) → O(1))
   start_node = world;
   if (self.current_node)
   {
      // Is the cached node still valid and close? (within 250 units)
      if ((vlen ((self.current_node.origin - self.origin)) < 250.000))
      {
         // Verify visibility to ensure we haven't walked through a wall
         traceline (self.origin,self.current_node.origin,TRUE,self);
         if ((trace_fraction == TRUE))
         {
            start_node = self.current_node;
         } //end if
      } //end if
   } //end if

   // Fallback: If cache missed, do the expensive search
   if (!start_node)
   {
      best_start_dist = 999999.000;
      e = findradius (self.origin,(SEARCH_RADIUS * 2.000));
      while (e)
      {
         if ((e.pathtype == DROPPED))
         {
            dist = vlen ((e.origin - self.origin));
            if ((dist < best_start_dist))
            {
               if (BotReachable (e,self))
               {
                  start_node = e;
                  best_start_dist = dist;
               } //end if
            } //end if
         } //end if
         e = e.chain;
      } //end while

      // Update cache for next time
      self.current_node = start_node;
   } //end if
   // ===== END PHASE 2 FIX =====

   // Find nearest BotPath to goal (goal node)
   goal_node = world;
   best_goal_dist = 999999.000;
   e = findradius (goal_entity.origin,(SEARCH_RADIUS * 2.000));
   while (e)
   {
      if ((e.pathtype == DROPPED))
      {
         dist = vlen ((e.origin - goal_entity.origin));
         if ((dist < best_goal_dist))
         {
            goal_node = e;
            best_goal_dist = dist;
         } //end if
      } //end if
      e = e.chain;
   } //end while

   // If we have both nodes, try A*
   if ((start_node && goal_node))
   {
      path_result = AStarSolve (start_node,goal_node);

      if (path_result)
      {
         // Success! Walk backwards from goal to find first step
         first_step = path_result;
         while (first_step.parent_node)
         {
            if ((first_step.parent_node == start_node))
            {
               // Found the first step from start
               carriedPath.movetarget = first_step;
               return (FALSE); // Path found
            } //end if
            first_step = first_step.parent_node;
         } //end while

         // Fallback: if we reached here, just use the start node
         carriedPath.movetarget = start_node;
         return (FALSE);
      } //end if
   } //end if

   // A* failed or no nodes found - fall back to greedy
   return (FindAPath_Greedy ());
}; //end of the function FindAPath_AStar

// Greedy pathfinding (original algorithm)
float () FindAPath_Greedy =
{
   local float dropPath;
   local float bestrng;
   local float rng;
   local entity e;
   local entity carriedPath;
   local entity bestPath;

   carriedPath = self.movetarget;
   dropPath = TRUE;
   e = findradius (self.origin,SEARCH_RADIUS);
   bestrng = 1000.000;
   bestPath = carriedPath.movetarget;
   while (e)
   {
      if ((e.pathtype == DROPPED))
      {
         rng = vlen ((e.origin - self.origin));
         if ((rng < bestrng))
         {
            if (BotReachable (e,self))
            {
               addTarget (carriedPath.movetarget,e);
               bestPath = e;
               bestrng = rng;
               dropPath = FALSE;
               // If this path is flagged for denial and the enemy is close, offset toward their velocity.
               if (bestPath.deny_flag)
               {
                  if (self.enemy)
                  {
                     if ((vlen ((self.enemy.origin - bestPath.origin)) < 400.000))
                     {
                        bestPath.origin = (bestPath.origin + (normalize (self.enemy.velocity) * 50.000));
                     } //end if
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
      e = e.chain;
   } //end while
   carriedPath.movetarget = bestPath;
   return (dropPath);
}; //end of the function FindAPath_Greedy

// Skill-based path selection: A* for high-skill, greedy for low-skill
float () FindAPath =
{
   // High-skill bots (Nightmare difficulty) use A* for optimal routing
   if ((self.skil > 2.000))
   {
      return (FindAPath_AStar ());
   } //end if

   // Low-skill bots use greedy search (more human-like, makes mistakes)
   return (FindAPath_Greedy ());
}; //end of the function FindAPath
// ===== END A* INTEGRATION =====
float () CheckDropPath =
{
   local entity carriedPath;
   local entity upstreamPath;
   local float rng;
   local float lnd;
   local float OK_HIGH;
   local string tmp;

   if ((NUMPATHS > 180.000))
   {
      return (FALSE);
   } //end if

   // ===== SMART SPACING: Optimization (Clean Breadcrumbs) =====
   // If we have a previous node, and we are still close to it AND can see it,
   // don't drop a new one yet. This creates clean lines instead of clumps.
   if (self.last_dropped_node)
   {
      // If node still exists (hasn't been cleaned up)
      if ((self.last_dropped_node.classname == "BotPath"))
      {
         // Distance check (250 units is a good stride)
         if ((vlen ((self.origin - self.last_dropped_node.origin)) < 250.000))
         {
            // Line of Sight check
            traceline (self.origin,self.last_dropped_node.origin,TRUE,self);
            if ((trace_fraction == 1.000))
            {
               // We are close and can see the last node. No need for another.
               // Extend the "carried" timer so we don't give up too soon.
               return (FALSE);
            } //end if
         } //end if
      } //end if
   } //end if
   // ===== END SMART SPACING =====

   carriedPath = self.movetarget;
   upstreamPath = carriedPath.movetarget;
   lnd = pointcontents (carriedPath.origin);
   if ((lnd == CONTENT_EMPTY))
   {
      rng = dropline (carriedPath.origin);
      if ((rng < (carriedPath.origin_z - SVC_FOUNDSECRET)))
      {
         if (!(carriedPath.flags & (FL_ONGROUND + SECRET_YES_SHOOT)))
         {
            return (FALSE);
         } //end if
      } //end if
      lnd = pointcontents (((carriedPath.origin + self.mins) + '0.000 0.000 1.000'));
      if ((lnd != CONTENT_EMPTY))
      {
         if ((lnd != CONTENT_WATER))
         {
            self.lefty = (self.lefty | NODROP);
            return (FALSE);
         } //end if
      } //end if

   } //end if
   else
   {
      if ((lnd != CONTENT_WATER))
      {
         self.lefty = (self.lefty | NODROP);
         return (FALSE);
      } //end if
   } //end if
   // ===== PLATFORM MASTERY: Enable Learning on Elevators =====
   // REMOVED RESTRICTION: Old code prevented breadcrumb drops on moving platforms.
   // We WANT bots to map elevator paths so they can learn to use lifts!
   // OLD CODE (DISABLED):
   // if (((trace_ent.classname == "plat") || (trace_ent.classname == "train")))
   // {
   //    if (trace_ent.think)
   //    {
   //       self.lefty = (self.lefty | NODROP);
   //       return (FALSE);
   //    } //end if
   // } //end if
   // ===== END PLATFORM MASTERY =====
   if ((self.teleport_time > time))
   {
      self.lefty = (self.lefty | NODROP);
      if ((self.teleport_time > (time + 0.500)))
      {
         return (FALSE);
      } //end if
      if ((self.lefty & NODROP))
      {
         self.lefty = (self.lefty - NODROP);
      } //end if
      return (FindAPath ());
   } //end if
   if (!upstreamPath)
   {
      return (FindAPath ());
   } //end if
   if (!BotReachable (upstreamPath,self))
   {
      if ((upstreamPath.origin_z > (self.origin_z + MAXJUMP)))
      {
         return (FindAPath ());
      } //end if
      return (FindAltPath ());
   } //end if
   return (FALSE);
}; //end of the function CheckDropPath

void () NewCarriedPath =
{
   self.movetarget = botpath ();
   self.movetarget.pathtype = CARRIED;
   setorigin (self.movetarget,self.origin);
}; //end of the function NewCarriedPath

void () DropBotPath =
{
   local string tmp;
   local entity oldpath;
   local float drop;

   oldpath = self.movetarget;
   if (oldpath.movetarget)
   {
      if ((oldpath.origin_z > ((oldpath.movetarget.origin_z + (MAXJUMP * 0.600)) - SPAWNFLAG_SUPERSPIKE)))
      {
         drop = (((oldpath.movetarget.origin_z - oldpath.origin_z) + (MAXJUMP * 0.600)) - SPAWNFLAG_SUPERSPIKE);
         if ((drop < (self.mins_z + SPAWNFLAG_LASER)))
         {
            drop = (self.mins_z + SPAWNFLAG_LASER);
         } //end if
         oldpath.origin_z = (oldpath.origin_z + drop);
      } //end if
   } //end if
   NewCarriedPath ();
   oldpath.pathtype = DROPPED;

   // ===== THE CLIFF FIX: One-Way Paths =====
   // Only link BACK (Bottom -> Top) if it is a shallow step or we can swim.
   // 18 units is step height. 45 is max jump. Use 40 to be safe.
   // This prevents bots from trying to walk up cliffs they jumped down.
   if ((self.flags & FL_SWIM) || ((oldpath.origin_z - self.movetarget.origin_z) < 40.000))
   {
      // Safe to link backward (climbable step or underwater)
      self.movetarget.movetarget = oldpath;
   } //end if
   else
   {
      // It's a drop! One-way street. Do not link back up the cliff.
      self.movetarget.movetarget = world;
   } //end if
   // ===== END CLIFF FIX =====

   // ===== SMART SPACING: Remember this node for spacing optimization =====
   self.last_dropped_node = oldpath;
   // ====================================================================

   // ===== ELEVATOR SYSTEM: Auto Node Creation =====
   // Check what we are standing on. If it's a lift/train, create elevator node pairs.
   traceline (self.origin,(self.origin - '0.000 0.000 64.000'),TRUE,self);
   if ((((trace_ent.classname == "func_plat") || (trace_ent.classname == "func_train")) || (trace_ent.classname == "func_door")))
   {
      // Legacy compatibility: Mark as platform node
      oldpath.is_platform_node = TRUE;

      // ===== NEW: Auto-create elevator node pairs =====
      if ((trace_ent.classname == "func_plat"))
      {
         local entity plat;
         local entity wait_node;
         local entity exit_node;
         local float at_bottom;
         local float at_top;

         plat = trace_ent;

         // Determine if we're at bottom or top position
         at_bottom = IsPlatformAt (plat,plat.pos1);
         at_top = IsPlatformAt (plat,plat.pos2);

         if (at_bottom)
         {
            // We're at bottom - create/update WAIT_NODE
            wait_node = FindElevatorNode (plat.pos1,64.000);

            if (!wait_node)
            {
               // Create new WAIT_NODE at current position
               wait_node = oldpath;  // Use the breadcrumb we just dropped
               wait_node.node_type = NODE_WAIT;
               wait_node.platform_entity = plat;
               wait_node.platform_wait_pos = plat.pos1;
               wait_node.platform_board_pos = plat.pos1;

               // Debug log
               if (((bot_debug_enabled && (bot_debug_level >= LOG_VERBOSE))))
               {
                  bprint ("ELEVATOR: Created WAIT_NODE at ");
                  bprint (vtos (wait_node.origin));
                  bprint ("\n");
               } //end if
            } //end if

            // Find or create EXIT_NODE at top
            exit_node = FindElevatorNode (plat.pos2,64.000);

            if (!exit_node)
            {
               // Create EXIT_NODE at top position
               // Spawn a new waypoint entity at the platform's top position
               exit_node = botpath ();
               setorigin (exit_node,plat.pos2);
               exit_node.pathtype = DROPPED;
               exit_node.node_type = NODE_EXIT;
               exit_node.platform_entity = plat;
               exit_node.traffic_score = 0.100;  // Low traffic (breadcrumb)

               // Debug log
               if (((bot_debug_enabled && (bot_debug_level >= LOG_VERBOSE))))
               {
                  bprint ("ELEVATOR: Created EXIT_NODE at ");
                  bprint (vtos (exit_node.origin));
                  bprint ("\n");
               } //end if
            } //end if

            // Link the pair (bidirectional)
            wait_node.wait_node_pair = exit_node;
            exit_node.wait_node_pair = wait_node;

            // Connect in waypoint graph (for A* pathfinding)
            // Use movetarget link to connect WAIT → EXIT
            if ((wait_node.movetarget == world))
            {
               wait_node.movetarget = exit_node;
            } //end if
         } //end if
         else if (at_top)
         {
            // We're at top - create/update EXIT_NODE
            exit_node = FindElevatorNode (plat.pos2,64.000);

            if (!exit_node)
            {
               // Create new EXIT_NODE at current position
               exit_node = oldpath;  // Use the breadcrumb we just dropped
               exit_node.node_type = NODE_EXIT;
               exit_node.platform_entity = plat;

               // Debug log
               if (((bot_debug_enabled && (bot_debug_level >= LOG_VERBOSE))))
               {
                  bprint ("ELEVATOR: Created EXIT_NODE at ");
                  bprint (vtos (exit_node.origin));
                  bprint ("\n");
               } //end if
            } //end if

            // Find or create WAIT_NODE at bottom
            wait_node = FindElevatorNode (plat.pos1,64.000);

            if (!wait_node)
            {
               // Create WAIT_NODE at bottom position
               wait_node = botpath ();
               setorigin (wait_node,plat.pos1);
               wait_node.pathtype = DROPPED;
               wait_node.node_type = NODE_WAIT;
               wait_node.platform_entity = plat;
               wait_node.platform_wait_pos = plat.pos1;
               wait_node.platform_board_pos = plat.pos1;
               wait_node.traffic_score = 0.100;  // Low traffic (breadcrumb)

               // Debug log
               if (((bot_debug_enabled && (bot_debug_level >= LOG_VERBOSE))))
               {
                  bprint ("ELEVATOR: Created WAIT_NODE at ");
                  bprint (vtos (wait_node.origin));
                  bprint ("\n");
               } //end if
            } //end if

            // Link the pair (bidirectional)
            exit_node.wait_node_pair = wait_node;
            wait_node.wait_node_pair = exit_node;

            // Connect in waypoint graph
            if ((wait_node.movetarget == world))
            {
               wait_node.movetarget = exit_node;
            } //end if
         } //end if
      } //end if
      // ===== END AUTO-CREATE =====
   } //end if
   // ===== END ELEVATOR SYSTEM =====

   NUMPATHS = (NUMPATHS + SPAWNFLAG_SUPERSPIKE);
}; //end of the function DropBotPath

// PHASE 2 FIX: Add depth parameter for recursion safety
void (entity node, float len, entity item, float depth) cacheRouteMsg;

// Helper: Check if bot's current enemy is weak (<40 HP) without variable shadowing
float () BotHasWeakEnemy =
{
   if ((self.classname != "dmbot"))
   {
      return (FALSE);
   } //end if
   if (!self.enemy)
   {
      return (FALSE);
   } //end if
   if ((self.enemy == world))
   {
      return (FALSE);
   } //end if
   if ((self.enemy.health < 40.000))
   {
      return (TRUE);
   } //end if
   return (FALSE);
}; //end of the function BotHasWeakEnemy

// PHASE 2 FIX: Accept depth parameter for recursion safety
void (entity node, entity targ, float len, entity item, float depth) cacheRouteTarget =
{
   local float rng;
   local entity enemy;
   local float enemy_dist;
   local float dist;
   local float has_weak_enemy;  // Flag: bot's enemy is weak (<40 HP)

   // Check bot's enemy status via helper (avoids .enemy field shadowing by local var)
   has_weak_enemy = BotHasWeakEnemy ();

   rng = vlen ((node.origin - targ.origin));
   if ((targ.pathtype == TELEPORT))
   {
      // ===== FOLDED SPACE: Instant Teleporters =====
      // Teleporters are instant shortcuts (0 distance cost).
      // This makes bots see the map as "folded" and find brilliant shortcuts.
      // OLD: rng = 250.000; (discouraged teleporter use)
      rng = 10.000; // Near-zero cost (instant travel)
      // ===== END FOLDED SPACE =====
   } //end if
   rng = ((rng + len) + LOOPTIME);

   // ===== HAZARD COSTING: Lava Avoidance =====
   // Check midpoint of the path segment for liquid hazards.
   // Bots should avoid routing through lava/slime unless there's no other way.
   local vector mid;
   local float mid_cont;
   mid = ((node.origin + targ.origin) * 0.500);
   mid_cont = pointcontents (mid);

   if (((mid_cont == CONTENT_LAVA) || (mid_cont == CONTENT_SLIME)))
   {
      // Massive penalty for unsafe routes (+5000).
      // Bots will only choose this if there is NO other way.
      rng = (rng + 5000.000);
   } //end if
   // ===== END HAZARD COSTING =====

   // Blockage check: if the path is obstructed mid-route, inflate cost and cool down.
   if ((self.classname == "dmbot"))
   {
      if ((time > self.reroute_time))
      {
         traceline (node.origin,targ.origin,TRUE,self);
         if ((trace_fraction < TRUE))
         {
            if ((trace_ent.classname != "BotPath"))
            {
               // ===== BROKEN PATH PRUNING: Obstacle Discrimination =====
               // Different penalties for different obstacles instead of flat 1.5x
               if ((trace_ent == world))
               {
                  // Hit a WALL (static level geometry) - path is broken!
                  // Make it effectively infinite cost to prune this bad link
                  rng = 100000.000;
               } //end if
               else
               {
                  if (((trace_ent.classname == "func_door") || (trace_ent.classname == "func_door_rotating")))
                  {
                     // It's just a door - add wait penalty (+300 units)
                     rng = (rng + 300.000);
                     self.reroute_time = (time + 0.500);
                  } //end if
                  else
                  {
                     // Some other blockage (monster, box) - mild penalty
                     rng = (rng * 1.500);
                     self.reroute_time = (time + 0.500);
                  } //end if
               } //end if
               // ===== END BROKEN PATH PRUNING =====
            } //end if
         } //end if
      } //end if
   } //end if

   // Powerup denial weighting: tighten route cost when an enemy is already nearby.
   if (((item.classname == "item_artifact_super_damage") || (item.classname == "item_artifact_invulnerability")) || (item.classname == "item_artifact_invisibility"))
   {
      enemy_dist = 999999.000;
      enemy = findradius (item.origin,SEARCH_RADIUS);
      while (enemy)
      {
         if (((enemy.classname == "player") || (enemy.classname == "dmbot")))
         {
            dist = vlen ((enemy.origin - item.origin));
            if ((dist < enemy_dist))
            {
               enemy_dist = dist;
            } //end if
         } //end if
         enemy = enemy.chain;
      } //end while
      if ((enemy_dist < SEARCH_RADIUS))
      {
         // ===== TWEAK #2: Conditional denial rush (lead/weak enemy aggression) =====
         // Base denial: reduce route cost when enemy is near powerup (encourages interception)
         local float denial_mult;
         denial_mult = 0.200;  // Default denial weight multiplier

         // Aggression boost: if bot is leading or enemy is weak, amplify denial rush
         // Leading = safe to contest; weak enemy = finish opportunity
         if ((self.lead_score > 0.000))
         {
            // Bot is ahead—more aggressive powerup denial (steal from losers)
            denial_mult = (denial_mult + 0.150);  // Boost to 0.35 total
         } //end if
         if (has_weak_enemy)
         {
            // Enemy is weak (<40 HP)—rush powerup to secure kill advantage
            denial_mult = (denial_mult + 0.200);  // Boost by +0.2 (stacks with lead)
         } //end if

         // Apply scaled denial: closer enemy = lower cost (more attractive route)
         // With bonuses, denial can reach 0.55 multiplier for ultra-aggressive contests
         rng = (rng - ((SEARCH_RADIUS - enemy_dist) * denial_mult));
         // ===== END TWEAK #2 =====

         if ((rng < TRUE))
         {
            rng = TRUE;
         } //end if
      } //end if
   } //end if
   // PHASE 2 FIX: Use depth parameter instead of global RECURSEDEPTH
   if ((depth < 24.000))
   {
      cacheRouteMsg (targ,rng,item,(depth + SPAWNFLAG_LASER));

   } //end if
   else
   {
      node.endpoint = TRUE;
   } //end if
}; //end of the function cacheRouteTarget

void (entity node, entity targ, float len, entity item) cacheRoute =
{
   // PHASE 2 FIX: Pass depth = 1 to start recursion
   cacheRouteTarget (node,targ,len,item,SPAWNFLAG_SUPERSPIKE);
   if ((other.classname == "dmbot"))
   {
      if ((other.rocketcache == item))
      {
         clearCache (other);

      } //end if
      else
      {
         if ((other.lightningcache == item))
         {
            clearCache (other);

         } //end if
         else
         {
            if ((other.armorcache == item))
            {
               clearCache (other);

            } //end if
            else
            {
               if ((other.powerupcache == item))
               {
                  clearCache (other);

               } //end if
               else
               {
                  if ((other.nailcache == item))
                  {
                     clearCache (other);

                  } //end if
                  else
                  {
                     if ((other.grenadecache == item))
                     {
                        clearCache (other);
                     } //end if
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
   } //end if
}; //end of the function cacheRoute

// PHASE 2 FIX: Accept depth parameter for recursion safety
void (entity node, float len, entity item, float depth) cacheRouteMsg =
{
   local float h;
   local float bestlen;

   if (item.th_cache)
   {
      if (!item.th_cache (node,len,item))
      {
         return ;
      } //end if

   } //end if
   else
   {
      return ;
   } //end if
   // Heuristic underestimate to prune unpromising branches (A*-lite).
   h = (vlen ((node.origin - item.origin)) * 0.800);
   bestlen = FALSE;
   if ((item.th_cache == cachepowerup))
   {
      bestlen = node.poweruplen;
   } //end if
   else
   {
      if ((item.th_cache == cacherocket))
      {
         bestlen = node.rocketlen;
      } //end if
      else
      {
         if ((item.th_cache == cachelightning))
         {
            bestlen = node.lightninglen;
         } //end if
         else
         {
            if ((item.th_cache == cachearmor))
            {
               bestlen = node.armorlen;
            } //end if
            else
            {
               if ((item.th_cache == cachenail))
               {
                  bestlen = node.naillen;
               } //end if
               else
               {
                  if ((item.th_cache == cachegrenade))
                  {
                     bestlen = node.grenadelen;
                  } //end if
                  else
                  {
                     if ((item.th_cache == cacheenemy))
                     {
                        bestlen = node.enemylen;
                     } //end if
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
   } //end if
   // PHASE 2 FIX: Pass depth to all recursive calls
   if (node.movetarget)
   {
      if ((bestlen > FALSE))
      {
         if ((len + h) < bestlen)
         {
            cacheRouteTarget (node,node.movetarget,len,item,depth);
         } //end if
      } //end if
      else
      {
         cacheRouteTarget (node,node.movetarget,len,item,depth);
      } //end else
   } //end if
   if (node.movetarget2)
   {
      if ((bestlen > FALSE))
      {
         if ((len + h) < bestlen)
         {
            cacheRouteTarget (node,node.movetarget2,len,item,depth);
         } //end if
      } //end if
      else
      {
         cacheRouteTarget (node,node.movetarget2,len,item,depth);
      } //end else
   } //end if
   if (node.movetarget3)
   {
      if ((bestlen > FALSE))
      {
         if ((len + h) < bestlen)
         {
            cacheRouteTarget (node,node.movetarget3,len,item,depth);
         } //end if
      } //end if
      else
      {
         cacheRouteTarget (node,node.movetarget3,len,item,depth);
      } //end else
   } //end if
   if (node.movetarget4)
   {
      if ((bestlen > FALSE))
      {
         if ((len + h) < bestlen)
         {
            cacheRouteTarget (node,node.movetarget4,len,item,depth);
         } //end if
      } //end if
      else
      {
         cacheRouteTarget (node,node.movetarget4,len,item,depth);
      } //end else
   } //end if
   if (node.movetarget5)
   {
      if ((bestlen > FALSE))
      {
         if ((len + h) < bestlen)
         {
            cacheRouteTarget (node,node.movetarget5,len,item,depth);
         } //end if
      } //end if
      else
      {
         cacheRouteTarget (node,node.movetarget5,len,item,depth);
      } //end else
   } //end if
   if (node.movetarget6)
   {
      if ((bestlen > FALSE))
      {
         if ((len + h) < bestlen)
         {
            cacheRouteTarget (node,node.movetarget6,len,item,depth);
         } //end if
      } //end if
      else
      {
         cacheRouteTarget (node,node.movetarget6,len,item,depth);
      } //end else
   } //end if
}; //end of the function cacheRouteMsg

void (entity e) clearCache =
{
   e.rocketcache = world;
   e.lightningcache = world;
   e.armorcache = world;
   e.nailcache = world;
   e.grenadecache = world;
   e.powerupcache = world;
   e.rocketlen = FALSE;
   e.lightninglen = FALSE;
   e.armorlen = FALSE;
   e.naillen = FALSE;
   e.grenadelen = FALSE;
   e.poweruplen = FALSE;
   e.endpoint = FALSE;
}; //end of the function clearCache

void (entity en) RouteToEnemy =
{
   local entity e;
   local vector last_vel;

   // PHASE 2 FIX: No need for global RECURSEDEPTH, pass as parameter
   e = find (world,classname,"BotPath");
   while (e)
   {
      e.enemycache = world;
      e.endpoint = FALSE;
      // Reset denial hints before recalculating enemy-driven intercepts.
      e.deny_flag = FALSE;
      e = find (e,classname,"BotPath");
   } //end while
   if (en.movetarget)
   {
      if (en.movetarget.movetarget)
      {
         cacheRouteTarget (en.movetarget,en.movetarget.movetarget,FALSE,en,SECRET_NO_SHOOT);
         // Velocity shift replan: if the target changes speed sharply, bump cached paths.
         last_vel = en.route_vel_last;
         en.route_vel_last = en.velocity;
         if ((self.skil > TRUE))
         {
            if ((vlen (last_vel) > CAM_IDLE))
            {
               if ((vlen ((last_vel - en.velocity)) > 100.000))
               {
                  e = find (world,classname,"BotPath");
                  while (e)
                  {
                     if ((e.enemycache == en))
                     {
                        e.enemylen = (e.enemylen * 1.200);
                     } //end if
                     e = find (e,classname,"BotPath");
                  } //end while
               } //end if
            } //end if
         } //end if
         e = find (world,classname,"BotPath");
         while (e)
         {
            if (e.endpoint)
            {
               if ((e.enemycache == en))
               {
                  // PHASE 2 FIX: Pass depth parameter instead of global
                  if (e.movetarget)
                  {
                     cacheRouteTarget (e,e.movetarget,e.enemylen,en,FL_CLIENT);
                  } //end if
                  if (e.movetarget2)
                  {
                     cacheRouteTarget (e,e.movetarget2,e.enemylen,en,FL_CLIENT);
                  } //end if
                  if (e.movetarget3)
                  {
                     cacheRouteTarget (e,e.movetarget3,e.enemylen,en,FL_CLIENT);
                  } //end if
                  if (e.movetarget4)
                  {
                     cacheRouteTarget (e,e.movetarget4,e.enemylen,en,FL_CLIENT);
                  } //end if
                  if (e.movetarget5)
                  {
                     cacheRouteTarget (e,e.movetarget5,e.enemylen,en,FL_CLIENT);
                  } //end if
                  if (e.movetarget6)
                  {
                     cacheRouteTarget (e,e.movetarget6,e.enemylen,en,FL_CLIENT);
                  } //end if
               } //end if
            } //end if
            e = find (e,classname,"BotPath");
         } //end while
      } //end if
   } //end if
   // Flag powerup routes for denial when the enemy is close enough to contest them.
   if (en)
   {
      e = find (world,classname,"BotPath");
      while (e)
      {
         if (e.powerupcache)
         {
            if (((e.powerupcache.classname == "item_artifact_super_damage") || (e.powerupcache.classname == "item_artifact_invulnerability")) || (e.powerupcache.classname == "item_artifact_invisibility"))
            {
               if ((vlen ((en.origin - e.powerupcache.origin)) < 400.000))
               {
                  e.deny_flag = TRUE;
               } //end if
            } //end if
         } //end if
         e = find (e,classname,"BotPath");
      } //end while
   } //end if
}; //end of the function RouteToEnemy

// ===== ELEVATOR NAVIGATION SYSTEM: Platform Detection Functions =====
// Check if platform is at specific position (within 32 units)
float (entity plat, vector target_pos) IsPlatformAt =
{
   if (!plat)
   {
      return (FALSE);
   } //end if

   local float dist;
   dist = vlen ((plat.origin - target_pos));

   // Platform within 32 units of target position?
   if ((dist < 32.000))
   {
      return (TRUE);
   } //end if

   return (FALSE);
}; //end of the function IsPlatformAt

// Check if elevator WAIT_NODE is traversable right now
float (entity wait_node) CanTraverseElevator =
{
   // Not an elevator node? Always traversable
   if ((wait_node.node_type != NODE_WAIT))
   {
      return (TRUE);
   } //end if

   local entity plat;
   plat = wait_node.platform_entity;

   if (!plat)
   {
      // No platform linked - error state, treat as blocked
      return (FALSE);
   } //end if

   // Is platform at bottom position (boardable)?
   if (IsPlatformAt (plat,wait_node.platform_board_pos))
   {
      return (TRUE);  // Safe to path through
   } //end if

   // Is platform descending? (Will arrive soon)
   if ((plat.state == STATE_DOWN))
   {
      return (TRUE);  // Treat as traversable (bot will wait)
   } //end if

   // Platform elsewhere (at top or moving up)
   return (FALSE);  // Find alternate route
}; //end of the function CanTraverseElevator

// Find elevator nodes near a position
entity (vector pos, float radius) FindElevatorNode =
{
   local entity e;
   local entity closest;
   local float best_dist;
   local float dist;

   e = find (world,classname,"BotPath");
   closest = world;
   best_dist = radius;

   while (e)
   {
      if (((e.node_type == NODE_WAIT) || (e.node_type == NODE_EXIT)))
      {
         dist = vlen ((e.origin - pos));
         if ((dist < best_dist))
         {
            best_dist = dist;
            closest = e;
         } //end if
      } //end if
      e = find (e,classname,"BotPath");
   } //end while

   return (closest);
}; //end of the function FindElevatorNode
// ===== END ELEVATOR SYSTEM =====

// ===== A* PATHFINDING: Optimal Route Solver =====
// Universal pathfinding algorithm that finds the lowest-cost path from start to goal.
// Uses f-score (g + h) to prioritize promising routes.
// Implements Open/Closed sets as linked lists using open_next/closed_next fields.
// Search_id system avoids expensive entity clearing between searches.
//
// Returns: First node in the path (walk self.parent_node chain to reconstruct full path)
//          world if no path exists
entity (entity start, entity goal) AStarSolve =
{
   local entity current;
   local entity neighbor;
   local entity lowest;
   local entity open_set;
   local entity closed_set;
   local float lowest_f;
   local float tentative_g;
   local float new_f;
   local float loop_count;
   local float edge_cost;
   local entity temp;
   local entity prev;

   // Increment global search ID (invalidates old search data)
   ASTAR_SEARCH_ID = (ASTAR_SEARCH_ID + TRUE);

   // Initialize start node
   start.g_score = FALSE;
   start.h_score = vlen ((goal.origin - start.origin));
   start.f_score = start.h_score;
   start.parent_node = world;
   start.search_id = ASTAR_SEARCH_ID;

   // Open set begins with start node
   open_set = start;
   start.open_next = world;
   closed_set = world;

   loop_count = FALSE;

   // Main A* loop (16M op budget allows ~50k iterations safely)
   while ((open_set && (loop_count < 50000.000)))
   {
      loop_count = (loop_count + TRUE);

      // ===== FIND LOWEST F IN OPEN SET =====
      lowest = world;
      lowest_f = 999999.000;
      current = open_set;

      while (current)
      {
         if ((current.f_score < lowest_f))
         {
            lowest_f = current.f_score;
            lowest = current;
         } //end if
         current = current.open_next;
      } //end while

      if (!lowest)
      {
         // No path found
         return (world);
      } //end if

      // ===== GOAL CHECK =====
      if ((lowest == goal))
      {
         // Path found! Return first node (caller reconstructs via parent_node chain)
         return (goal);
      } //end if

      // ===== MOVE FROM OPEN TO CLOSED =====
      // Remove lowest from open_set
      if ((open_set == lowest))
      {
         // Lowest is head of list
         open_set = lowest.open_next;
      } //end if
      else
      {
         // Find and unlink lowest from middle/end of list
         prev = open_set;
         while ((prev.open_next && (prev.open_next != lowest)))
         {
            prev = prev.open_next;
         } //end while
         if (prev.open_next)
         {
            prev.open_next = lowest.open_next;
         } //end if
      } //end if

      // Add to closed_set
      lowest.closed_next = closed_set;
      closed_set = lowest;

      // ===== PROCESS NEIGHBORS =====
      // Check all movetarget links (up to 6 neighbors per node)
      neighbor = lowest.movetarget;
      if (neighbor)
      {
         // ===== ELEVATOR SYSTEM: Dynamic Traversal Check =====
         if ((neighbor.node_type == NODE_WAIT))
         {
            // This is an elevator entrance - check if platform present
            if (!CanTraverseElevator (neighbor))
            {
               // Platform absent - skip this path entirely
               // A* will find alternate route automatically
               neighbor = world;  // Skip to next neighbor check
            } //end if
         } //end if
         // ===== END ELEVATOR SYSTEM =====
      } //end if

      if (neighbor)
      {
         if (((neighbor.search_id != ASTAR_SEARCH_ID) || (neighbor.closed_next != neighbor)))
         {
            // ===== TACTICAL PATHFINDING: The "Fear" Engine =====
            // Calculate base edge cost (Euclidean distance)
            edge_cost = vlen ((neighbor.origin - lowest.origin));

            // PENALTY: Danger Scent (death zones)
            // If bots die here often, artificially increase the "length" of this path.
            // Multiplier 10.0 means 1 death makes the path seem 10 units longer.
            if ((neighbor.danger_scent > 0.000))
            {
               edge_cost = (edge_cost + (neighbor.danger_scent * 10.000));
            } //end if

            // BONUS/PENALTY: Traffic Score (adaptive based on health)
            // Strong bots (≥50 HP): Seek traffic (map control) → REDUCE cost
            // Weak bots (<50 HP): Avoid traffic (danger) → INCREASE cost
            if ((neighbor.traffic_score > 0.000))
            {
               if ((self.health < 50.000))
               {
                  edge_cost = (edge_cost + (neighbor.traffic_score * 5.000)); // Avoid fight
               } //end if
               else
               {
                  edge_cost = (edge_cost - (neighbor.traffic_score * 2.000)); // Seek fight
               } //end if
            } //end if
            // ===================================================

            tentative_g = (lowest.g_score + edge_cost);

            // Better path found OR node not yet visited?
            if (((neighbor.search_id != ASTAR_SEARCH_ID) || (tentative_g < neighbor.g_score)))
            {
               // Update node costs
               neighbor.parent_node = lowest;
               neighbor.g_score = tentative_g;
               neighbor.h_score = vlen ((goal.origin - neighbor.origin));
               neighbor.f_score = (neighbor.g_score + neighbor.h_score);
               neighbor.search_id = ASTAR_SEARCH_ID;

               // Add to open set if not already there
               if ((neighbor.search_id != ASTAR_SEARCH_ID))
               {
                  neighbor.open_next = open_set;
                  open_set = neighbor;
               } //end if
            } //end if
         } //end if
      } //end if

      // Repeat for movetarget2
      neighbor = lowest.movetarget2;
      if (neighbor)
      {
         // ===== ELEVATOR SYSTEM: Dynamic Traversal Check =====
         if ((neighbor.node_type == NODE_WAIT))
         {
            if (!CanTraverseElevator (neighbor))
            {
               neighbor = world;
            } //end if
         } //end if
         // ===== END ELEVATOR SYSTEM =====
      } //end if

      if (neighbor)
      {
         if (((neighbor.search_id != ASTAR_SEARCH_ID) || (neighbor.closed_next != neighbor)))
         {
            // ===== TACTICAL PATHFINDING: The "Fear" Engine =====
            edge_cost = vlen ((neighbor.origin - lowest.origin));

            if ((neighbor.danger_scent > 0.000))
            {
               edge_cost = (edge_cost + (neighbor.danger_scent * 10.000));
            } //end if

            if ((neighbor.traffic_score > 0.000))
            {
               if ((self.health < 50.000))
               {
                  edge_cost = (edge_cost + (neighbor.traffic_score * 5.000));
               } //end if
               else
               {
                  edge_cost = (edge_cost - (neighbor.traffic_score * 2.000));
               } //end if
            } //end if
            // ===================================================

            tentative_g = (lowest.g_score + edge_cost);

            if (((neighbor.search_id != ASTAR_SEARCH_ID) || (tentative_g < neighbor.g_score)))
            {
               neighbor.parent_node = lowest;
               neighbor.g_score = tentative_g;
               neighbor.h_score = vlen ((goal.origin - neighbor.origin));
               neighbor.f_score = (neighbor.g_score + neighbor.h_score);
               neighbor.search_id = ASTAR_SEARCH_ID;

               if ((neighbor.search_id != ASTAR_SEARCH_ID))
               {
                  neighbor.open_next = open_set;
                  open_set = neighbor;
               } //end if
            } //end if
         } //end if
      } //end if

      // Repeat for movetarget3-6 (same pattern)
      neighbor = lowest.movetarget3;
      if (neighbor)
      {
         // ===== ELEVATOR SYSTEM: Dynamic Traversal Check =====
         if ((neighbor.node_type == NODE_WAIT))
         {
            if (!CanTraverseElevator (neighbor))
            {
               neighbor = world;
            } //end if
         } //end if
         // ===== END ELEVATOR SYSTEM =====
      } //end if

      if (neighbor)
      {
         if (((neighbor.search_id != ASTAR_SEARCH_ID) || (neighbor.closed_next != neighbor)))
         {
            // ===== TACTICAL PATHFINDING: The "Fear" Engine =====
            edge_cost = vlen ((neighbor.origin - lowest.origin));

            if ((neighbor.danger_scent > 0.000))
            {
               edge_cost = (edge_cost + (neighbor.danger_scent * 10.000));
            } //end if

            if ((neighbor.traffic_score > 0.000))
            {
               if ((self.health < 50.000))
               {
                  edge_cost = (edge_cost + (neighbor.traffic_score * 5.000));
               } //end if
               else
               {
                  edge_cost = (edge_cost - (neighbor.traffic_score * 2.000));
               } //end if
            } //end if
            // ===================================================

            tentative_g = (lowest.g_score + edge_cost);

            if (((neighbor.search_id != ASTAR_SEARCH_ID) || (tentative_g < neighbor.g_score)))
            {
               neighbor.parent_node = lowest;
               neighbor.g_score = tentative_g;
               neighbor.h_score = vlen ((goal.origin - neighbor.origin));
               neighbor.f_score = (neighbor.g_score + neighbor.h_score);
               neighbor.search_id = ASTAR_SEARCH_ID;

               if ((neighbor.search_id != ASTAR_SEARCH_ID))
               {
                  neighbor.open_next = open_set;
                  open_set = neighbor;
               } //end if
            } //end if
         } //end if
      } //end if

      neighbor = lowest.movetarget4;
      if (neighbor)
      {
         // ===== ELEVATOR SYSTEM: Dynamic Traversal Check =====
         if ((neighbor.node_type == NODE_WAIT))
         {
            if (!CanTraverseElevator (neighbor))
            {
               neighbor = world;
            } //end if
         } //end if
         // ===== END ELEVATOR SYSTEM =====
      } //end if

      if (neighbor)
      {
         if (((neighbor.search_id != ASTAR_SEARCH_ID) || (neighbor.closed_next != neighbor)))
         {
            // ===== TACTICAL PATHFINDING: The "Fear" Engine =====
            edge_cost = vlen ((neighbor.origin - lowest.origin));

            if ((neighbor.danger_scent > 0.000))
            {
               edge_cost = (edge_cost + (neighbor.danger_scent * 10.000));
            } //end if

            if ((neighbor.traffic_score > 0.000))
            {
               if ((self.health < 50.000))
               {
                  edge_cost = (edge_cost + (neighbor.traffic_score * 5.000));
               } //end if
               else
               {
                  edge_cost = (edge_cost - (neighbor.traffic_score * 2.000));
               } //end if
            } //end if
            // ===================================================

            tentative_g = (lowest.g_score + edge_cost);

            if (((neighbor.search_id != ASTAR_SEARCH_ID) || (tentative_g < neighbor.g_score)))
            {
               neighbor.parent_node = lowest;
               neighbor.g_score = tentative_g;
               neighbor.h_score = vlen ((goal.origin - neighbor.origin));
               neighbor.f_score = (neighbor.g_score + neighbor.h_score);
               neighbor.search_id = ASTAR_SEARCH_ID;

               if ((neighbor.search_id != ASTAR_SEARCH_ID))
               {
                  neighbor.open_next = open_set;
                  open_set = neighbor;
               } //end if
            } //end if
         } //end if
      } //end if

      neighbor = lowest.movetarget5;
      if (neighbor)
      {
         // ===== ELEVATOR SYSTEM: Dynamic Traversal Check =====
         if ((neighbor.node_type == NODE_WAIT))
         {
            if (!CanTraverseElevator (neighbor))
            {
               neighbor = world;
            } //end if
         } //end if
         // ===== END ELEVATOR SYSTEM =====
      } //end if

      if (neighbor)
      {
         if (((neighbor.search_id != ASTAR_SEARCH_ID) || (neighbor.closed_next != neighbor)))
         {
            // ===== TACTICAL PATHFINDING: The "Fear" Engine =====
            edge_cost = vlen ((neighbor.origin - lowest.origin));

            if ((neighbor.danger_scent > 0.000))
            {
               edge_cost = (edge_cost + (neighbor.danger_scent * 10.000));
            } //end if

            if ((neighbor.traffic_score > 0.000))
            {
               if ((self.health < 50.000))
               {
                  edge_cost = (edge_cost + (neighbor.traffic_score * 5.000));
               } //end if
               else
               {
                  edge_cost = (edge_cost - (neighbor.traffic_score * 2.000));
               } //end if
            } //end if
            // ===================================================

            tentative_g = (lowest.g_score + edge_cost);

            if (((neighbor.search_id != ASTAR_SEARCH_ID) || (tentative_g < neighbor.g_score)))
            {
               neighbor.parent_node = lowest;
               neighbor.g_score = tentative_g;
               neighbor.h_score = vlen ((goal.origin - neighbor.origin));
               neighbor.f_score = (neighbor.g_score + neighbor.h_score);
               neighbor.search_id = ASTAR_SEARCH_ID;

               if ((neighbor.search_id != ASTAR_SEARCH_ID))
               {
                  neighbor.open_next = open_set;
                  open_set = neighbor;
               } //end if
            } //end if
         } //end if
      } //end if

      neighbor = lowest.movetarget6;
      if (neighbor)
      {
         // ===== ELEVATOR SYSTEM: Dynamic Traversal Check =====
         if ((neighbor.node_type == NODE_WAIT))
         {
            if (!CanTraverseElevator (neighbor))
            {
               neighbor = world;
            } //end if
         } //end if
         // ===== END ELEVATOR SYSTEM =====
      } //end if

      if (neighbor)
      {
         if (((neighbor.search_id != ASTAR_SEARCH_ID) || (neighbor.closed_next != neighbor)))
         {
            // ===== TACTICAL PATHFINDING: The "Fear" Engine =====
            edge_cost = vlen ((neighbor.origin - lowest.origin));

            if ((neighbor.danger_scent > 0.000))
            {
               edge_cost = (edge_cost + (neighbor.danger_scent * 10.000));
            } //end if

            if ((neighbor.traffic_score > 0.000))
            {
               if ((self.health < 50.000))
               {
                  edge_cost = (edge_cost + (neighbor.traffic_score * 5.000));
               } //end if
               else
               {
                  edge_cost = (edge_cost - (neighbor.traffic_score * 2.000));
               } //end if
            } //end if
            // ===================================================

            tentative_g = (lowest.g_score + edge_cost);

            if (((neighbor.search_id != ASTAR_SEARCH_ID) || (tentative_g < neighbor.g_score)))
            {
               neighbor.parent_node = lowest;
               neighbor.g_score = tentative_g;
               neighbor.h_score = vlen ((goal.origin - neighbor.origin));
               neighbor.f_score = (neighbor.g_score + neighbor.h_score);
               neighbor.search_id = ASTAR_SEARCH_ID;

               if ((neighbor.search_id != ASTAR_SEARCH_ID))
               {
                  neighbor.open_next = open_set;
                  open_set = neighbor;
               } //end if
            } //end if
         } //end if
      } //end if
   } //end while

   // Loop limit reached or open set exhausted - no path
   return (world);
}; //end of the function AStarSolve
// ===== END A* PATHFINDING =====

// ===== PORTAL AWARENESS: Wormhole Linking =====
// Connects teleporter nodes to their destination nodes.
// Creates instant-travel paths that bots can plan routes through.
void () LinkTeleporters =
{
   local entity tele_node;
   local entity dest_ent;
   local entity dest_node;

   // Find all special teleporter nodes created in triggers.qc
   tele_node = find (world,classname,"BotTeleporter");

   while (tele_node)
   {
      // 1. Find where this teleporter goes (info_teleport_destination)
      dest_ent = find (world,targetname,tele_node.target);

      if (dest_ent)
      {
         // 2. Spawn a node at the EXIT if one doesn't exist
         // (Ensures bot can pathfind FROM the exit)
         dest_node = spawn ();
         dest_node.classname = "BotPath";
         dest_node.origin = dest_ent.origin;
         dest_node.pathtype = REGULARTARGET;
         dest_node.solid = SOLID_TRIGGER;
         setsize (dest_node,'-16 -16 -16','16 16 16');

         // 3. HARDWIRE THE LINK
         // Tell the bot: "If you are at tele_node, your next step is dest_node"
         tele_node.movetarget = dest_node;

         // 4. Zero Cost (Instant Travel)
         // Teleports are free/instant - no distance penalty
         // The pathfinding system will see this as a very short walk
      } //end if

      // Convert back to standard BotPath so normal logic uses it
      tele_node.classname = "BotPath";

      tele_node = find (tele_node,classname,"BotTeleporter");
   } //end while
}; //end of the function LinkTeleporters
// ===== END PORTAL AWARENESS =====

// ===== PERSISTENCE SYSTEM: Brain Dump (Memory Between Sessions) =====

// 1. THE LOADER
// You will paste the console output into a file that calls this function.
// This spawns a saved waypoint at the specified coordinates.
// PHASE 6 ENHANCEMENT: Added target linking for button->door smart triggers
void (vector org, float traffic, float danger, string trig_target) SpawnSavedWaypoint =
{
   local entity node;

   node = spawn ();
   node.classname = "BotPath";
   node.origin = org;
   node.pathtype = DROPPED;  // Treat as a standard learned path
   node.solid = SOLID_TRIGGER;
   setsize (node,'-4 -4 -4','4 4 4');

   // PHASE 5: Restore learned experience scores
   node.traffic_score = traffic;  // How often bots use this route
   node.danger_scent = danger;    // Death/damage history at this location

   // PHASE 6: Restore the smart trigger link (for button/door sequences)
   if (trig_target != "")
   {
      node.target = trig_target;
      // Optional: Visualize linked nodes for debugging
      // node.effects = EF_DIMLIGHT;
   } //end if

   // Optional: link it loosely to the network?
   // Usually, the bots will "adopt" these nodes when they run near them
   // via the standard 'FindAPath' logic.
}; //end of the function SpawnSavedWaypoint

// ===== PLAYER OBSERVATION LEARNING: Learned Rocket Jump Waypoints =====
// Spawns a special waypoint that tells bots HOW to rocket jump at this location.
// Unlike regular waypoints, RJ waypoints store pitch angle and expected velocity.
void (vector org, vector angles, float velocity_gain, string rj_type_str) SpawnLearnedRJ =
{
   local entity node;

   node = spawn ();
   node.classname = "BotPath";
   node.origin = org;
   node.pathtype = DROPPED;  // Treat as learned path (same as traffic waypoints)
   node.solid = SOLID_TRIGGER;
   setsize (node,'-8 -8 -8','8 8 8');  // Slightly larger trigger for RJ waypoints

   // Mark this as a learned RJ waypoint
   node.rj_learned = TRUE;
   node.rj_pitch = angles_x;  // Store the learned pitch angle
   node.rj_velocity_gain = velocity_gain;  // Expected vertical velocity gain
   node.rj_type = rj_type_str;  // Technique type ("rj_vertical", "rj_gap", etc.)

   // Optional: Give RJ waypoints high traffic score (bots should seek these)
   node.traffic_score = 50.000;  // Medium-high priority (proven technique)

   // Optional: Visual debug marker (uncomment to see RJ waypoints in-game)
   // node.effects = EF_BRIGHTLIGHT;
}; //end of the function SpawnLearnedRJ

// ===== PHASE 2: LIVE LEARNING - Memory Management =====
// Spawns a learned RJ waypoint with automatic memory management.
// If limit is reached, removes the oldest learned RJ first.
void (vector org, vector angles, float velocity_gain, string rj_type_str) SpawnLearnedRJ_Live =
{
   local entity node;
   local entity oldest;
   local entity current;

   // Check if we're at the limit
   if (learned_rj_count >= LEARNED_RJ_MAX)
   {
      // Find and remove the oldest learned RJ waypoint
      oldest = learned_rj_head;
      if (oldest != world)
      {
         // Remove from linked list
         learned_rj_head = oldest.rj_next;

         // Remove the entity
         remove(oldest);
         learned_rj_count = learned_rj_count - 1.000;

         bprint("Live Learning: Removed oldest RJ waypoint (limit: ");
         bprint(ftos(LEARNED_RJ_MAX));
         bprint(")\n");
      }
   } //end if

   // Create the new learned RJ waypoint
   node = spawn ();
   node.classname = "BotPath";
   node.origin = org;
   node.pathtype = DROPPED;
   node.solid = SOLID_TRIGGER;
   setsize (node,'-8 -8 -8','8 8 8');

   // Mark as learned RJ
   node.rj_learned = TRUE;
   node.rj_pitch = angles_x;
   node.rj_velocity_gain = velocity_gain;
   node.rj_type = rj_type_str;
   node.rj_learn_time = time;  // Timestamp for aging
   node.traffic_score = 50.000;

   // Add to end of linked list (oldest at head, newest at tail)
   node.rj_next = world;
   if (learned_rj_head == world)
   {
      learned_rj_head = node;
   }
   else
   {
      // Find the tail and append
      current = learned_rj_head;
      while (current.rj_next != world)
      {
         current = current.rj_next;
      }
      current.rj_next = node;
   }

   learned_rj_count = learned_rj_count + 1.000;
}; //end of the function SpawnLearnedRJ_Live
// =====================================================================

// 2. THE EXPORTER (PHASE 5: Now includes traffic/danger scores)
// Call this via console (e.g. 'impulse 100') to dump everything.
// Outputs QuakeC code to console that can be copied and saved.
void () DumpWaypoints =
{
   local entity head;
   local float count;
   local float total_traffic;
   local float total_danger;

   count = 0.000;
   total_traffic = 0.000;
   total_danger = 0.000;

   bprint ("\n\n// ===== CUT HERE: START WAYPOINTS =====\n");
   bprint ("// PHASE 6: Smart Triggers (Target Linking for Button->Door Logic)\n");
   bprint ("// Format: SpawnSavedWaypoint(origin, traffic_score, danger_scent, target)\n");
   bprint ("void() LoadMapWaypoints =\n{\n");

   head = find (world,classname,"BotPath");
   while (head)
   {
      // Only dump dropped paths (ignore teleporter nodes or dynamic temps)
      if ((head.pathtype == DROPPED))
      {
         bprint ("    SpawnSavedWaypoint('");
         bprint (vtos (head.origin));
         bprint ("', ");
         bprint (ftos (head.traffic_score));
         bprint (", ");
         bprint (ftos (head.danger_scent));
         bprint (", ''");

         // PHASE 6: Save the target string (for button/door linking)
         if (head.target != "")
         {
            bprint (head.target);
         }
         //end if

         bprint ("');\n");
         // NOTE: Output uses '' for target strings - post-process with:
         // python -c "import re; ..." to convert '' to \"\" for correct QuakeC syntax

         count = (count + 1.000);
         total_traffic = (total_traffic + head.traffic_score);
         total_danger = (total_danger + head.danger_scent);
      } //end if
      head = find (head,classname,"BotPath");
   } //end while

   bprint ("};\n");
   bprint ("// ===== CUT HERE: END WAYPOINTS =====\n");
   bprint ("// Total Nodes: ");
   bprint (ftos (count));
   bprint ("\n");

   // Prevent division by zero if no waypoints found
   if (count > 0)
   {
      bprint ("// Avg Traffic Score: ");
      bprint (ftos ((total_traffic / count)));
      bprint ("\n");
      bprint ("// Avg Danger Scent: ");
      bprint (ftos ((total_danger / count)));
      bprint ("\n");
   }
   else
   {
      bprint ("// WARNING: No waypoints with pathtype=DROPPED found!\n");
      bprint ("// Did you load a map waypoint file (e.g., LoadMapWaypoints_dm4)?\n");
   }

   bprint ("\n");
}; //end of the function DumpWaypoints
// ===== END PERSISTENCE SYSTEM =====
