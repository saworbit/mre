
void () t_botpath = {

   if ( (other.classname != "dmbot") ) {

      return ;

   }
   if ( (other.movetarget == self) ) {

      return ;

   }
   bot_toucheditem ();
   addTarget (other.movetarget.movetarget,self);
   other.movetarget.movetarget = self;

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

   // Cycle detection: skip if already visited in this search
   if ( (targ.visited_id == route_search_id) ) {

      return ;

   }
   targ.visited_id = route_search_id;

   rng = vlen ((node.origin - targ.origin));
   if ( (targ.pathtype == TELEPORT) ) {

      rng = 250.000;

   }
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
