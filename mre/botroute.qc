
void (entity ent, entity node) UpdateTrail;

void () t_botpath = {

   if ( (other.classname != "dmbot") ) {

      return ;

   }
   if ( (other.movetarget == self) ) {

      other.last_waypoint = self;
      UpdateTrail (other, self);
      return ;

   }
   bot_toucheditem ();
   addTarget (other.movetarget.movetarget,self);
   other.movetarget.movetarget = self;
   other.last_waypoint = self;
   UpdateTrail (other, self);

};
entity () botpath = {

   local entity targ;

   targ = spawn ();
   targ.classname = "BotPath";
   targ.solid = SOLID_TRIGGER;
   targ.movetarget = world;
   targ.touch = t_botpath;
   setsize (targ,'-4.000 -4.000 -4.000','4.000 4.000 4.000');
   return ( targ );

};
float (entity a, entity b) IsUpstream = {

   if ( (b.movetarget == a) ) {

      return ( TRUE );

   }
   if ( (b.movetarget2 == a) ) {

      return ( TRUE );

   }
   if ( (b.movetarget3 == a) ) {

      return ( TRUE );

   }
   if ( (b.movetarget4 == a) ) {

      return ( TRUE );

   }
   if ( (b.movetarget5 == a) ) {

      return ( TRUE );

   }
   if ( (b.movetarget6 == a) ) {

      return ( TRUE );

   }
   return ( FALSE );

};

void (entity node, entity targ, float len, entity item) cacheRouteTarget;

void (entity a, entity b, float recurse) updateRouteCache = {

   RECURSEDEPTH = recurse;
   if ( (b.rocketlen > FALSE) ) {

      cacheRouteTarget (b,a,b.rocketlen,b.rocketcache);

   }
   if ( (b.lightninglen > FALSE) ) {

      cacheRouteTarget (b,a,b.lightninglen,b.lightningcache);

   }
   if ( (b.armorlen > FALSE) ) {

      cacheRouteTarget (b,a,b.armorlen,b.armorcache);

   }
   if ( (b.poweruplen > FALSE) ) {

      cacheRouteTarget (b,a,b.poweruplen,b.powerupcache);

   }
   if ( (b.naillen > FALSE) ) {

      cacheRouteTarget (b,a,b.naillen,b.nailcache);

   }
   if ( (b.grenadelen > FALSE) ) {

      cacheRouteTarget (b,a,b.grenadelen,b.grenadecache);

   }

};

void (entity a, entity b) addTarget = {

   if ( (a == b) ) {

      return ;

   }
   if ( (b.movetarget == a) ) {

      return ;

   }
   if ( !a ) {

      return ;

   } else {

      if ( (b.movetarget2 == a) ) {

         updateRouteCache (a,b,FL_INWATER);
         return ;

      } else {

         if ( (b.movetarget3 == a) ) {

            updateRouteCache (a,b,FL_INWATER);
            return ;

         } else {

            if ( (b.movetarget4 == a) ) {

               updateRouteCache (a,b,FL_INWATER);
               return ;

            } else {

               if ( (b.movetarget5 == a) ) {

                  updateRouteCache (a,b,FL_INWATER);
                  return ;

               } else {

                  if ( (b.movetarget6 == a) ) {

                     updateRouteCache (a,b,FL_INWATER);
                     return ;

                  }

               }

            }

         }

      }

   }
   if ( !b.movetarget ) {

      b.movetarget = a;

   } else {

      if ( !b.movetarget2 ) {

         b.movetarget2 = a;

      } else {

         if ( !b.movetarget3 ) {

            b.movetarget3 = a;

         } else {

            if ( !b.movetarget4 ) {

               b.movetarget4 = a;

            } else {

               if ( !b.movetarget5 ) {

                  b.movetarget5 = a;

               } else {

                  if ( !b.movetarget6 ) {

                     b.movetarget6 = a;

                  }

               }

            }

         }

      }

   }
   updateRouteCache (a,b,MOVETYPE_BOUNCE);

};
float () FindAPath;

// Spawn a saved waypoint for breadcrumbs/exploration.
// NOTE: traffic/danger fields are not wired in MRE yet.
void (vector org, float traffic, float danger, string tgt) SpawnSavedWaypoint = {

   local entity node;

   node = botpath ();
   setorigin (node, org);
   node.pathtype = DROPPED;
   node.classname = "BotPath";

};

// --- Dynamic Waypoint Management ---

entity (vector org) SpawnLearnedWaypoint = {

   local entity node;

   node = spawn ();
   node.classname = "BotPath";
   node.solid = SOLID_TRIGGER;
   node.movetarget = world;
   node.touch = t_botpath;
   setorigin (node, org);
   setsize (node, '-16 -16 -16', '16 16 16');
   node.pathtype = DROPPED;
   NUMPATHS = (NUMPATHS + TRUE);
   return ( node );

};

// Robust linking with type and usage increment
void (entity src, entity dst, float type) LinkNodes = {

   if ( (src == dst) ) {
      return ;
   }
   if ( !src || !dst ) {
      return ;
   }

   if ( (src.movetarget == dst) ) {
      if ( (src.link_type1 == LINK_WALK) && (type != LINK_WALK) ) {
         src.link_type1 = type;
      }
      src.link_usage1 = (src.link_usage1 + TRUE);
      return ;
   }
   if ( (src.movetarget2 == dst) ) {
      if ( (src.link_type2 == LINK_WALK) && (type != LINK_WALK) ) {
         src.link_type2 = type;
      }
      src.link_usage2 = (src.link_usage2 + TRUE);
      return ;
   }
   if ( (src.movetarget3 == dst) ) {
      if ( (src.link_type3 == LINK_WALK) && (type != LINK_WALK) ) {
         src.link_type3 = type;
      }
      src.link_usage3 = (src.link_usage3 + TRUE);
      return ;
   }
   if ( (src.movetarget4 == dst) ) {
      if ( (src.link_type4 == LINK_WALK) && (type != LINK_WALK) ) {
         src.link_type4 = type;
      }
      src.link_usage4 = (src.link_usage4 + TRUE);
      return ;
   }
   if ( (src.movetarget5 == dst) ) {
      if ( (src.link_type5 == LINK_WALK) && (type != LINK_WALK) ) {
         src.link_type5 = type;
      }
      src.link_usage5 = (src.link_usage5 + TRUE);
      return ;
   }
   if ( (src.movetarget6 == dst) ) {
      if ( (src.link_type6 == LINK_WALK) && (type != LINK_WALK) ) {
         src.link_type6 = type;
      }
      src.link_usage6 = (src.link_usage6 + TRUE);
      return ;
   }

   if ( !src.movetarget ) {
      src.movetarget = dst;
      src.link_type1 = type;
      src.link_usage1 = TRUE;
      return ;
   }
   if ( !src.movetarget2 ) {
      src.movetarget2 = dst;
      src.link_type2 = type;
      src.link_usage2 = TRUE;
      return ;
   }
   if ( !src.movetarget3 ) {
      src.movetarget3 = dst;
      src.link_type3 = type;
      src.link_usage3 = TRUE;
      return ;
   }
   if ( !src.movetarget4 ) {
      src.movetarget4 = dst;
      src.link_type4 = type;
      src.link_usage4 = TRUE;
      return ;
   }
   if ( !src.movetarget5 ) {
      src.movetarget5 = dst;
      src.link_type5 = type;
      src.link_usage5 = TRUE;
      return ;
   }
   if ( !src.movetarget6 ) {
      src.movetarget6 = dst;
      src.link_type6 = type;
      src.link_usage6 = TRUE;
      return ;
   }

};

// --- Retrospective Learning ---

// Trail tracking: shift history buffer when touching/dropping a node
void (entity ent, entity node) UpdateTrail = {

   if ( !ent || !node || (node == world) ) {
      return ;
   }
   if ( (ent.trail_node1 == node) ) {
      return ;
   }

   ent.trail_node5 = ent.trail_node4;
   ent.trail_node4 = ent.trail_node3;
   ent.trail_node3 = ent.trail_node2;
   ent.trail_node2 = ent.trail_node1;
   ent.trail_node1 = node;

};

// Path optimization: if we can see past the middle node, create a shortcut
void (entity n_start, entity n_mid, entity n_end) OptimizePathSegment = {

   if ( !n_start || !n_mid || !n_end ) {
      return ;
   }

   traceline (n_start.origin, n_end.origin, TRUE, n_start);
   if ( (trace_fraction == 1.0) ) {
      LinkNodes (n_start, n_end, LINK_WALK);
      if ( (n_start.movetarget == n_end) ) {
         n_start.link_usage1 = (n_start.link_usage1 + 50.000);
      } else if ( (n_start.movetarget2 == n_end) ) {
         n_start.link_usage2 = (n_start.link_usage2 + 50.000);
      } else if ( (n_start.movetarget3 == n_end) ) {
         n_start.link_usage3 = (n_start.link_usage3 + 50.000);
      } else if ( (n_start.movetarget4 == n_end) ) {
         n_start.link_usage4 = (n_start.link_usage4 + 50.000);
      } else if ( (n_start.movetarget5 == n_end) ) {
         n_start.link_usage5 = (n_start.link_usage5 + 50.000);
      } else if ( (n_start.movetarget6 == n_end) ) {
         n_start.link_usage6 = (n_start.link_usage6 + 50.000);
      }
      if ( cvar("developer") ) {
         dprint ("AI Optimized: Created shortcut!\n");
      }
   }

};

// Reward propagation: boost priority and optimize recent trail
void (entity player, float reward_val) BackPropagateReward = {

   local float decay;

   if ( !player ) {
      return ;
   }

   decay = 1.000;
   if ( player.trail_node1 ) {
      player.trail_node1.node_priority = (player.trail_node1.node_priority + (reward_val * decay));
      player.trail_node1.link_usage1 = (player.trail_node1.link_usage1 + 10.000);
   }
   decay = (decay * 0.800);
   if ( player.trail_node2 ) {
      player.trail_node2.node_priority = (player.trail_node2.node_priority + (reward_val * decay));
   }
   decay = (decay * 0.800);
   if ( player.trail_node3 ) {
      player.trail_node3.node_priority = (player.trail_node3.node_priority + (reward_val * decay));
   }
   decay = (decay * 0.800);
   if ( player.trail_node4 ) {
      player.trail_node4.node_priority = (player.trail_node4.node_priority + (reward_val * decay));
   }
   decay = (decay * 0.800);
   if ( player.trail_node5 ) {
      player.trail_node5.node_priority = (player.trail_node5.node_priority + (reward_val * decay));
   }

   OptimizePathSegment (player.trail_node3, player.trail_node2, player.trail_node1);
   OptimizePathSegment (player.trail_node4, player.trail_node3, player.trail_node2);
   OptimizePathSegment (player.trail_node5, player.trail_node4, player.trail_node3);

};

// Call this in PlayerPostThink to learn from humans
void () Player_AutoWaypoint = {

   local entity e;
   local entity near_node;
   local float best_dist;
   local float dist;
   local float type;
   local float dist_moved;
   local float yaw_change;
   local float drop_ok;
   local float old_trace_fraction;
   local vector old_trace_endpos;
   local entity old_trace_ent;
   local vector old_trace_plane_normal;
   local float old_trace_inopen;
   local float old_trace_inwater;

   // Save trace globals
   old_trace_fraction = trace_fraction;
   old_trace_endpos = trace_endpos;
   old_trace_ent = trace_ent;
   old_trace_plane_normal = trace_plane_normal;
   old_trace_inopen = trace_inopen;
   old_trace_inwater = trace_inwater;

   // 1. Find nearest existing waypoint
   near_node = world;
   best_dist = 99999.000;
   e = findradius (self.origin,96.000);
   while ( e ) {
      if ( (e.classname == "BotPath") ) {
         dist = vlen ((e.origin - self.origin));
         if ( (dist < best_dist) ) {
            traceline (self.origin + self.view_ofs, e.origin, TRUE, self);
            if ( (trace_fraction == 1.0) ) {
               best_dist = dist;
               near_node = e;
            }
         }
   }
   e = e.chain;
   }

   // 2. Improved drop logic (distance/turn based)
   if ( (self.last_breadcrumb_pos == '0 0 0') ) {
      dist_moved = 99999.000;
      yaw_change = 0.000;
   } else {
      dist_moved = vlen ((self.origin - self.last_breadcrumb_pos));
      yaw_change = (self.v_angle_y - self.last_breadcrumb_yaw);
      while ( yaw_change > 180.000 ) {
         yaw_change = (yaw_change - 360.000);
      }
      while ( yaw_change < -180.000 ) {
         yaw_change = (yaw_change + 360.000);
      }
      yaw_change = fabs (yaw_change);
   }
   drop_ok = FALSE;
   if ( (dist_moved > 48.000) || ((dist_moved > 32.000) && (yaw_change > 45.000)) ) {
      drop_ok = TRUE;
   }

   // 3. Create a node if spacing/turning warrants it and we're not too close to another
   if ( drop_ok ) {
      if ( !near_node || (best_dist > 32.000) ) {
         // Cap waypoints to avoid edict overflow
         if ( (!deathmatch && (NUMPATHS > 50.000)) || (NUMPATHS > 140.000) ) {
            // no spawn
         } else if ( (self.flags & FL_ONGROUND) || (self.waterlevel > TRUE) ) {
            near_node = SpawnLearnedWaypoint (self.origin);
            self.last_breadcrumb_pos = self.origin;
            self.last_breadcrumb_yaw = self.v_angle_y;
            if ( cvar("developer") ) {
               dprint ("[");
               dprint (self.netname);
               dprint ("] BREADCRUMB: Learned waypoint at ");
               dprint (vtos (self.origin));
               dprint ("\n");
            }
         }
      }
   }

   // 3. Link logic
   if ( self.last_waypoint && near_node && (self.last_waypoint != near_node) ) {
      type = LINK_WALK;

      if ( self.is_jumping ) {
         type = LINK_JUMP;
         if ( (self.origin_z < (self.jump_origin_z - 64.000)) ) {
            type = LINK_DROP;
         }
      } else if ( (self.origin_z < (self.last_waypoint.origin_z - 64.000)) ) {
         type = LINK_DROP;
      } else if ( self.groundentity ) {
         if ( (self.groundentity.classname == "func_plat") || (self.groundentity.classname == "func_train") ) {
            type = LINK_PLAT;
         }
      }
      // Rocket jump detection (heuristic)
      if ( (self.weapon == IT_ROCKET_LAUNCHER) ) {
         if ( (!(self.flags & FL_ONGROUND)) && (self.waterlevel == 0) ) {
            if ( (self.velocity_z > 250.000) && (self.v_angle_x > 45.000) ) {
               if ( (time > (self.last_rj_time + 1.000)) ) {
                  type = LINK_ROCKETJUMP;
                  self.last_rj_time = time;
                  if ( cvar("developer") ) {
                     dprint ("Learned ROCKET JUMP path!\n");
                  }
               }
            }
         }
      }

      LinkNodes (self.last_waypoint, near_node, type);
   }

   // 4. Update trail if we touched/dropped a node
   if ( near_node ) {
      UpdateTrail (self, near_node);
      if ( (self.last_breadcrumb_pos == '0 0 0') ) {
         self.last_breadcrumb_pos = self.origin;
         self.last_breadcrumb_yaw = self.v_angle_y;
      }
   }

   // 5. Update state
   if ( near_node ) {
      near_node.node_traffic = (near_node.node_traffic + TRUE);
      self.last_waypoint = near_node;
      self.last_waypoint_time = time;
   }

   // Track jumping state
   if ( (!(self.flags & FL_ONGROUND)) && (self.waterlevel == 0) ) {
      if ( !self.is_jumping ) {
         self.is_jumping = TRUE;
         self.jump_origin = self.origin;
      }
   } else {
      self.is_jumping = FALSE;
   }

   // Restore trace globals
   trace_fraction = old_trace_fraction;
   trace_endpos = old_trace_endpos;
   trace_ent = old_trace_ent;
   trace_plane_normal = old_trace_plane_normal;
   trace_inopen = old_trace_inopen;
   trace_inwater = old_trace_inwater;

};

void (entity node) MarkDanger = {

   if ( !node || (node == world) ) {
      return ;
   }
   node.danger_cost = (node.danger_cost + 1000.000);
   node.node_traffic = (node.node_traffic * 0.500);
   if ( cvar("developer") ) {
      dprint ("Node marked dangerous!\n");
   }

};

void () MaintainGraph = {

   local entity node;

   if ( (time < graph_decay_next) ) {
      return ;
   }
   graph_decay_next = (time + 10.000);

   node = find (world,classname,"BotPath");
   while ( node ) {
      // Decay usage toward baseline
      if ( (node.link_usage1 > 1.000) ) {
         node.link_usage1 = (node.link_usage1 * 0.900);
         if ( (node.link_usage1 < 1.000) ) node.link_usage1 = 1.000;
      }
      if ( (node.link_usage2 > 1.000) ) {
         node.link_usage2 = (node.link_usage2 * 0.900);
         if ( (node.link_usage2 < 1.000) ) node.link_usage2 = 1.000;
      }
      if ( (node.link_usage3 > 1.000) ) {
         node.link_usage3 = (node.link_usage3 * 0.900);
         if ( (node.link_usage3 < 1.000) ) node.link_usage3 = 1.000;
      }
      if ( (node.link_usage4 > 1.000) ) {
         node.link_usage4 = (node.link_usage4 * 0.900);
         if ( (node.link_usage4 < 1.000) ) node.link_usage4 = 1.000;
      }
      if ( (node.link_usage5 > 1.000) ) {
         node.link_usage5 = (node.link_usage5 * 0.900);
         if ( (node.link_usage5 < 1.000) ) node.link_usage5 = 1.000;
      }
      if ( (node.link_usage6 > 1.000) ) {
         node.link_usage6 = (node.link_usage6 * 0.900);
         if ( (node.link_usage6 < 1.000) ) node.link_usage6 = 1.000;
      }

      // Decay danger scent
      if ( (node.danger_cost > 0.000) ) {
         node.danger_cost = (node.danger_cost - 100.000);
         if ( (node.danger_cost < 0.000) ) {
            node.danger_cost = 0.000;
         }
      }

      node = find (node,classname,"BotPath");
   }

};

float () FindAltPath = {

   local entity e;
   local entity carriedPath;
   local entity bestPath;
   local float dropPath;
   local float bestrng;
   local float rng;

   if ( (self.lefty & NODROP) ) {

      self.lefty = (self.lefty - NODROP);
      return ( FindAPath () );

   }
   e = findradius (self.origin,SEARCH_RADIUS);
   bestrng = 1000.000;
   dropPath = TRUE;
   carriedPath = self.movetarget;
   bestPath = carriedPath.movetarget;
   while ( e ) {

      if ( (e.pathtype == DROPPED) ) {

         rng = vlen ((e.origin - self.origin));
         if ( (rng < bestrng) ) {

            if ( BotReachable (e,self) ) {

               if ( BotReachable (carriedPath.movetarget,e) ) {

                  addTarget (carriedPath.movetarget,e);
                  bestPath = e;
                  bestrng = rng;
                  dropPath = FALSE;

               }

            }

         }

      }
      e = e.chain;

   }
   carriedPath.movetarget = bestPath;
   return ( dropPath );

};
float () FindAPath = {

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
   while ( e ) {

      if ( (e.pathtype == DROPPED) ) {

         rng = vlen ((e.origin - self.origin));
         if ( (rng < bestrng) ) {

            if ( BotReachable (e,self) ) {

               addTarget (carriedPath.movetarget,e);
               bestPath = e;
               bestrng = rng;
               dropPath = FALSE;

            }

         }

      }
      e = e.chain;

   }
   carriedPath.movetarget = bestPath;
   return ( dropPath );

};
float () CheckDropPath = {

   local entity carriedPath;
   local entity upstreamPath;
   local float rng;
   local float lnd;
   local float OK_HIGH;
   local string tmp;

   // Cap waypoints strictly in Single Player to prevent edict overflow
   // SP maps have many more entities (monsters, triggers) leaving fewer slots
   if ( !deathmatch && (NUMPATHS > 50.000) ) {

      return ( FALSE );

   }
   if ( (NUMPATHS > 140.000) ) {

      return ( FALSE );

   }
   carriedPath = self.movetarget;
   upstreamPath = carriedPath.movetarget;
   lnd = pointcontents (carriedPath.origin);
   if ( (lnd == CONTENT_EMPTY) ) {

      rng = dropline (carriedPath.origin);
      if ( (rng < (carriedPath.origin_z - SVC_FOUNDSECRET)) ) {

         if ( !(carriedPath.flags & (FL_ONGROUND + FL_INWATER)) ) {

            return ( FALSE );

         }

      }
      lnd = pointcontents (((carriedPath.origin + self.mins) + '0.000 0.000 1.000'));
      if ( (lnd != CONTENT_EMPTY) ) {

         if ( (lnd != CONTENT_WATER) ) {

            self.lefty = (self.lefty | NODROP);
            return ( FALSE );

         }

      }

   } else {

      if ( (lnd != CONTENT_WATER) ) {

         self.lefty = (self.lefty | NODROP);
         return ( FALSE );

      }

   }
   if ( ((trace_ent.classname == "plat") || (trace_ent.classname == "train")) ) {

      if ( trace_ent.think ) {

         self.lefty = (self.lefty | NODROP);
         return ( FALSE );

      }

   }
   if ( (self.teleport_time > time) ) {

      self.lefty = (self.lefty | NODROP);
      if ( (self.teleport_time > (time + 0.500)) ) {

         return ( FALSE );

      }
      if ( (self.lefty & NODROP) ) {

         self.lefty = (self.lefty - NODROP);

      }
      return ( FindAPath () );

   }
   if ( !upstreamPath ) {

      return ( FindAPath () );

   }
   if ( !BotReachable (upstreamPath,self) ) {

      if ( (upstreamPath.origin_z > (self.origin_z + MAXJUMP)) ) {

         return ( FindAPath () );

      }
      return ( FindAltPath () );

   }
   return ( FALSE );

};

void () NewCarriedPath = {

   self.movetarget = botpath ();
   self.movetarget.pathtype = CARRIED;
   setorigin (self.movetarget,self.origin);

};

void () DropBotPath = {

   local string tmp;
   local entity oldpath;
   local float drop;

   oldpath = self.movetarget;
   if ( oldpath.movetarget ) {

      if ( (oldpath.origin_z > ((oldpath.movetarget.origin_z + (MAXJUMP * 0.600)) - TRUE)) ) {

         drop = (((oldpath.movetarget.origin_z - oldpath.origin_z) + (MAXJUMP * 0.600)) - TRUE);
         if ( (drop < (self.mins_z + FL_SWIM)) ) {

            drop = (self.mins_z + FL_SWIM);

         }
         oldpath.origin_z = (oldpath.origin_z + drop);

      }

   }
   NewCarriedPath ();
   oldpath.pathtype = DROPPED;
   self.movetarget.movetarget = oldpath;
   NUMPATHS = (NUMPATHS + TRUE);

};

void (entity node, float len, entity item) cacheRouteMsg;

void (entity node, entity targ, float len, entity item) cacheRouteTarget = {

   local float rng;
   local float weight;

   // Cycle detection: skip if already visited in this search
   if ( (targ.visited_id == route_search_id) ) {

      return ;

   }
   targ.visited_id = route_search_id;

   rng = vlen ((node.origin - targ.origin));
   if ( (targ.pathtype == TELEPORT) ) {

      rng = 250.000;

   }
   // Usage weighting: prefer frequently used links
   weight = 1.000;
   if ( (node.movetarget == targ) ) {
      weight = (1.000 + (node.link_usage1 * 0.100));
   } else if ( (node.movetarget2 == targ) ) {
      weight = (1.000 + (node.link_usage2 * 0.100));
   } else if ( (node.movetarget3 == targ) ) {
      weight = (1.000 + (node.link_usage3 * 0.100));
   } else if ( (node.movetarget4 == targ) ) {
      weight = (1.000 + (node.link_usage4 * 0.100));
   } else if ( (node.movetarget5 == targ) ) {
      weight = (1.000 + (node.link_usage5 * 0.100));
   } else if ( (node.movetarget6 == targ) ) {
      weight = (1.000 + (node.link_usage6 * 0.100));
   }
   // Priority weighting: high-value nodes become "shorter"
   if ( (targ.node_priority > 0.000) ) {
      weight = (weight + (targ.node_priority * 0.050));
   }
   if ( (weight > 10.000) ) {
      weight = 10.000;
   }
   rng = (rng / weight);
   rng = (rng + targ.danger_cost);
   rng = ((rng + len) + KINDA_WANT);
   RECURSEDEPTH = (RECURSEDEPTH + FL_SWIM);
   if ( (RECURSEDEPTH < 24.000) ) {

      cacheRouteMsg (targ,rng,item);

   } else {

      node.endpoint = TRUE;

   }
   RECURSEDEPTH = (RECURSEDEPTH - FL_SWIM);

};

void (entity node, entity targ, float len, entity item) cacheRoute = {

   route_search_id = (route_search_id + TRUE);  // new search ID for cycle detection
   RECURSEDEPTH = TRUE;
   cacheRouteTarget (node,targ,len,item);
   if ( (other.classname == "dmbot") ) {

      if ( (other.rocketcache == item) ) {

         clearCache (other);

      } else {

         if ( (other.lightningcache == item) ) {

            clearCache (other);

         } else {

            if ( (other.armorcache == item) ) {

               clearCache (other);

            } else {

               if ( (other.powerupcache == item) ) {

                  clearCache (other);

               } else {

                  if ( (other.nailcache == item) ) {

                     clearCache (other);

                  } else {

                     if ( (other.grenadecache == item) ) {

                        clearCache (other);

                     }

                  }

               }

            }

         }

      }

   }

};

void (entity node, float len, entity item) cacheRouteMsg = {

   if ( item.th_cache ) {

      if ( !item.th_cache (node,len,item) ) {

         return ;

      }

   } else {

      return ;

   }
   if ( node.movetarget ) {

      cacheRouteTarget (node,node.movetarget,len,item);

   }
   if ( node.movetarget2 ) {

      cacheRouteTarget (node,node.movetarget2,len,item);

   }
   if ( node.movetarget3 ) {

      cacheRouteTarget (node,node.movetarget3,len,item);

   }
   if ( node.movetarget4 ) {

      cacheRouteTarget (node,node.movetarget4,len,item);

   }
   if ( node.movetarget5 ) {

      cacheRouteTarget (node,node.movetarget5,len,item);

   }
   if ( node.movetarget6 ) {

      cacheRouteTarget (node,node.movetarget6,len,item);

   }

};

void (entity e) clearCache = {

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

};

void (entity en) RouteToEnemy = {

   local entity e;

   RECURSEDEPTH = FL_CLIENT;
   e = find (world,classname,"BotPath");
   while ( e ) {

      e.enemycache = world;
      e.endpoint = FALSE;
      e = find (e,classname,"BotPath");

   }
   if ( en.movetarget ) {

      if ( en.movetarget.movetarget ) {

         cacheRouteTarget (en.movetarget,en.movetarget.movetarget,FALSE,en);
         e = find (world,classname,"BotPath");
         while ( e ) {

            if ( e.endpoint ) {

               if ( (e.enemycache == en) ) {

                  RECURSEDEPTH = FL_CLIENT;
                  if ( e.movetarget ) {

                     cacheRouteTarget (e,e.movetarget,e.enemylen,en);

                  }
                  if ( e.movetarget2 ) {

                     cacheRouteTarget (e,e.movetarget2,e.enemylen,en);

                  }
                  if ( e.movetarget3 ) {

                     cacheRouteTarget (e,e.movetarget3,e.enemylen,en);

                  }
                  if ( e.movetarget4 ) {

                     cacheRouteTarget (e,e.movetarget4,e.enemylen,en);

                  }
                  if ( e.movetarget5 ) {

                     cacheRouteTarget (e,e.movetarget5,e.enemylen,en);

                  }
                  if ( e.movetarget6 ) {

                     cacheRouteTarget (e,e.movetarget6,e.enemylen,en);

                  }

               }

            }
            e = find (e,classname,"BotPath");

         }

      }

   }

};
