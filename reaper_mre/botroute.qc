
void () t_botpath =
{
   if ((other.classname != "dmbot"))
   {
      return ;
   } //end if
   if ((other.movetarget == self))
   {
      return ;
   } //end if
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
float () FindAPath =
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
}; //end of the function FindAPath
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
   self.movetarget.movetarget = oldpath;

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
      rng = 250.000;
   } //end if
   rng = ((rng + len) + LOOPTIME);
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
               rng = (rng * 1.500);
               self.reroute_time = (time + 0.500);
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
   dprint ("\n\n// ===== CUT HERE: START WAYPOINTS =====\n");
   dprint ("void() LoadMapWaypoints =\n{\n");

   head = find (world,classname,"BotPath");
   while (head)
   {
      // Only dump dropped paths (ignore teleporter nodes or dynamic temps)
      if ((head.pathtype == DROPPED))
      {
         dprint ("    SpawnSavedWaypoint('");
         dprint (vtos (head.origin));
         dprint ("');\n");
         count = (count + 1.000);
      } //end if
      head = find (head,classname,"BotPath");
   } //end while

   dprint ("};\n");
   dprint ("// ===== CUT HERE: END WAYPOINTS =====\n");
   dprint ("// Total Nodes: ");
   dprint (ftos (count));
   dprint ("\n\n");
}; //end of the function DumpWaypoints
// ===== END PERSISTENCE SYSTEM =====
