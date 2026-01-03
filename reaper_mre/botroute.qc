
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

void (entity node, entity targ, float len, entity item) cacheRouteTarget;

void (entity a, entity b, float recurse) updateRouteCache =
{
   RECURSEDEPTH = recurse;
   if ((b.rocketlen > FALSE))
   {
      cacheRouteTarget (b,a,b.rocketlen,b.rocketcache);
   } //end if
   if ((b.lightninglen > FALSE))
   {
      cacheRouteTarget (b,a,b.lightninglen,b.lightningcache);
   } //end if
   if ((b.armorlen > FALSE))
   {
      cacheRouteTarget (b,a,b.armorlen,b.armorcache);
   } //end if
   if ((b.poweruplen > FALSE))
   {
      cacheRouteTarget (b,a,b.poweruplen,b.powerupcache);
   } //end if
   if ((b.naillen > FALSE))
   {
      cacheRouteTarget (b,a,b.naillen,b.nailcache);
   } //end if
   if ((b.grenadelen > FALSE))
   {
      cacheRouteTarget (b,a,b.grenadelen,b.grenadecache);
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

   // Find nearest BotPath to bot (start node)
   start_node = world;
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

   // ===== PLATFORM MASTERY: Platform Tagging =====
   // Check what we are standing on. If it's a lift/train, mark this node.
   traceline (self.origin,(self.origin - '0.000 0.000 64.000'),TRUE,self);
   if ((((trace_ent.classname == "func_plat") || (trace_ent.classname == "func_train")) || (trace_ent.classname == "func_door")))
   {
      oldpath.is_platform_node = TRUE;
   } //end if
   // ==============================================

   NUMPATHS = (NUMPATHS + SPAWNFLAG_SUPERSPIKE);
}; //end of the function DropBotPath

void (entity node, float len, entity item) cacheRouteMsg;

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

void (entity node, entity targ, float len, entity item) cacheRouteTarget =
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
   RECURSEDEPTH = (RECURSEDEPTH + SPAWNFLAG_LASER);
   if ((RECURSEDEPTH < 24.000))
   {
      cacheRouteMsg (targ,rng,item);

   } //end if
   else
   {
      node.endpoint = TRUE;
   } //end if
   RECURSEDEPTH = (RECURSEDEPTH - SPAWNFLAG_LASER);
}; //end of the function cacheRouteTarget

void (entity node, entity targ, float len, entity item) cacheRoute =
{
   RECURSEDEPTH = SPAWNFLAG_SUPERSPIKE;
   cacheRouteTarget (node,targ,len,item);
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

void (entity node, float len, entity item) cacheRouteMsg =
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
   if (node.movetarget)
   {
      if ((bestlen > FALSE))
      {
         if ((len + h) < bestlen)
         {
            cacheRouteTarget (node,node.movetarget,len,item);
         } //end if
      } //end if
      else
      {
         cacheRouteTarget (node,node.movetarget,len,item);
      } //end else
   } //end if
   if (node.movetarget2)
   {
      if ((bestlen > FALSE))
      {
         if ((len + h) < bestlen)
         {
            cacheRouteTarget (node,node.movetarget2,len,item);
         } //end if
      } //end if
      else
      {
         cacheRouteTarget (node,node.movetarget2,len,item);
      } //end else
   } //end if
   if (node.movetarget3)
   {
      if ((bestlen > FALSE))
      {
         if ((len + h) < bestlen)
         {
            cacheRouteTarget (node,node.movetarget3,len,item);
         } //end if
      } //end if
      else
      {
         cacheRouteTarget (node,node.movetarget3,len,item);
      } //end else
   } //end if
   if (node.movetarget4)
   {
      if ((bestlen > FALSE))
      {
         if ((len + h) < bestlen)
         {
            cacheRouteTarget (node,node.movetarget4,len,item);
         } //end if
      } //end if
      else
      {
         cacheRouteTarget (node,node.movetarget4,len,item);
      } //end else
   } //end if
   if (node.movetarget5)
   {
      if ((bestlen > FALSE))
      {
         if ((len + h) < bestlen)
         {
            cacheRouteTarget (node,node.movetarget5,len,item);
         } //end if
      } //end if
      else
      {
         cacheRouteTarget (node,node.movetarget5,len,item);
      } //end else
   } //end if
   if (node.movetarget6)
   {
      if ((bestlen > FALSE))
      {
         if ((len + h) < bestlen)
         {
            cacheRouteTarget (node,node.movetarget6,len,item);
         } //end if
      } //end if
      else
      {
         cacheRouteTarget (node,node.movetarget6,len,item);
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

   RECURSEDEPTH = SECRET_NO_SHOOT;
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
         cacheRouteTarget (en.movetarget,en.movetarget.movetarget,FALSE,en);
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
                  RECURSEDEPTH = FL_CLIENT;
                  if (e.movetarget)
                  {
                     cacheRouteTarget (e,e.movetarget,e.enemylen,en);
                  } //end if
                  if (e.movetarget2)
                  {
                     cacheRouteTarget (e,e.movetarget2,e.enemylen,en);
                  } //end if
                  if (e.movetarget3)
                  {
                     cacheRouteTarget (e,e.movetarget3,e.enemylen,en);
                  } //end if
                  if (e.movetarget4)
                  {
                     cacheRouteTarget (e,e.movetarget4,e.enemylen,en);
                  } //end if
                  if (e.movetarget5)
                  {
                     cacheRouteTarget (e,e.movetarget5,e.enemylen,en);
                  } //end if
                  if (e.movetarget6)
                  {
                     cacheRouteTarget (e,e.movetarget6,e.enemylen,en);
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
         if (((neighbor.search_id != ASTAR_SEARCH_ID) || (neighbor.closed_next != neighbor)))
         {
            // Calculate edge cost (Euclidean distance)
            edge_cost = vlen ((neighbor.origin - lowest.origin));
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
         if (((neighbor.search_id != ASTAR_SEARCH_ID) || (neighbor.closed_next != neighbor)))
         {
            edge_cost = vlen ((neighbor.origin - lowest.origin));
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
         if (((neighbor.search_id != ASTAR_SEARCH_ID) || (neighbor.closed_next != neighbor)))
         {
            edge_cost = vlen ((neighbor.origin - lowest.origin));
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
         if (((neighbor.search_id != ASTAR_SEARCH_ID) || (neighbor.closed_next != neighbor)))
         {
            edge_cost = vlen ((neighbor.origin - lowest.origin));
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
         if (((neighbor.search_id != ASTAR_SEARCH_ID) || (neighbor.closed_next != neighbor)))
         {
            edge_cost = vlen ((neighbor.origin - lowest.origin));
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
         if (((neighbor.search_id != ASTAR_SEARCH_ID) || (neighbor.closed_next != neighbor)))
         {
            edge_cost = vlen ((neighbor.origin - lowest.origin));
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
void (vector org) SpawnSavedWaypoint =
{
   local entity node;

   node = spawn ();
   node.classname = "BotPath";
   node.origin = org;
   node.pathtype = DROPPED;  // Treat as a standard learned path
   node.solid = SOLID_TRIGGER;
   setsize (node,'-4 -4 -4','4 4 4');

   // Optional: link it loosely to the network?
   // Usually, the bots will "adopt" these nodes when they run near them
   // via the standard 'FindAPath' logic.
}; //end of the function SpawnSavedWaypoint

// 2. THE EXPORTER
// Call this via console (e.g. 'impulse 100') to dump everything.
// Outputs QuakeC code to console that can be copied and saved.
void () DumpWaypoints =
{
   local entity head;
   local float count;

   count = 0.000;
   bprint ("\n\n// ===== CUT HERE: START WAYPOINTS =====\n");
   bprint ("void() LoadMapWaypoints =\n{\n");

   head = find (world,classname,"BotPath");
   while (head)
   {
      // Only dump dropped paths (ignore teleporter nodes or dynamic temps)
      if ((head.pathtype == DROPPED))
      {
         bprint ("    SpawnSavedWaypoint('");
         bprint (vtos (head.origin));
         bprint ("');\n");
         count = (count + 1.000);
      } //end if
      head = find (head,classname,"BotPath");
   } //end while

   bprint ("};\n");
   bprint ("// ===== CUT HERE: END WAYPOINTS =====\n");
   bprint ("// Total Nodes: ");
   bprint (ftos (count));
   bprint ("\n\n");
}; //end of the function DumpWaypoints
// ===== END PERSISTENCE SYSTEM =====
