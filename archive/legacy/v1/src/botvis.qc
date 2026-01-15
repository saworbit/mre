float (entity targ) botrange = {

   local vector spot1;
   local vector spot2;
   local float mel;
   local float r;

   spot1 = (self.origin + self.view_ofs);
   spot2 = (targ.origin + targ.view_ofs);
   r = vlen ((spot1 - spot2));
   mel = ((180.000 - (self.health * 0.500)) - (self.armorvalue * self.armortype));
   if ( (self.items & IT_QUAD) ) {

      mel = (FL_SWIM * mel);

   }
   if ( (teamplay == TRUE) ) {

      mel = 60.000;

   }
   if ( (r < mel) ) {

      return ( RANGE_MELEE );

   } else {

      if ( (r < SEARCH_RADIUS) ) {

         return ( RANGE_NEAR );

      } else {

         if ( (r < 1000.000) ) {

            return ( RANGE_MID );

         }

      }

   }
   return ( RANGE_FAR );

};
float (entity targ) infrontofbot = {

   local vector vec;
   local vector xydir;
   local float fov;
   local float dot;
   local float lnd;

   if ( (self.skil == MOVETYPE_WALK) ) {

      return ( TRUE );

   }
   lnd = pointcontents ((self.origin + self.view_ofs));
   if ( (lnd != CONTENT_WATER) ) {

      if ( (self.skil < FL_SWIM) ) {

         xydir = (targ.origin - self.origin);
         xydir_z = FALSE;
         dot = vlen (xydir);
         fov = ((targ.origin_z - self.origin_z) * (FL_SWIM - (0.750 * self.skil)));
         if ( (fov < FALSE) ) {

            fov = (-0.800 * fov);

         }
         if ( ((fov > 150.000) && (dot < fov)) ) {

            return ( FALSE );

         }

      }

   }
   makevectors (self.angles);
   vec = normalize ((targ.origin - self.origin));
   dot = (vec * v_forward);
   fov = (0.700 - (self.skil * 0.280));
   if ( (dot > fov) ) {

      return ( TRUE );

   }
   if ( (lnd == CONTENT_WATER) ) {

      if ( (dot > FALSE) ) {

         return ( TRUE );

      }

   }
   return ( FALSE );

};
float (entity targ) Swimto = {

   local vector spot1;
   local vector spot2;
   local float lnd;

   spot1 = (self.origin + self.view_ofs);
   spot2 = targ.absmin;
   lnd = pointcontents (spot2);
   if ( (lnd != CONTENT_WATER) ) {

      if ( (spot2_z > (spot1_z + MAXJUMP)) ) {

         return ( FALSE );

      }

   }
   traceline (spot1,spot2,TRUE,self);
   if ( (trace_fraction == TRUE) ) {

      return ( TRUE );

   }
   if ( (trace_ent == targ) ) {

      return ( TRUE );

   }
   return ( FALSE );

};
float (entity targ) Spotvisible = {

   local vector spot1;
   local vector spot2;
   local string t1;

   spot1 = (self.origin + self.view_ofs);
   spot2 = ((targ.absmin + targ.absmax) * 0.500);
   traceline (spot1,spot2,TRUE,self);
   if ( (trace_fraction == TRUE) ) {

      return ( TRUE );

   }
   if ( (trace_ent == targ) ) {

      return ( TRUE );

   }
   return ( FALSE );

};
float (entity targ) enemyvisible = {

   local vector spot1;
   local vector spot2;

   if ( visible (targ) ) {

      return ( TRUE );

   }
   spot1 = (self.origin + self.view_ofs);
   spot2 = targ.origin;
   traceline (spot1,spot2,TRUE,self);
   if ( (trace_inopen && trace_inwater) ) {

      return ( FALSE );

   }
   if ( (trace_fraction == TRUE) ) {

      return ( TRUE );

   }
   return ( FALSE );

};
float (entity targ) Platvisible = {

   local vector spot1;
   local vector spot2;
   local string t1;

   spot1 = (self.origin + self.view_ofs);
   spot2 = ((targ.absmin + targ.absmax) * 0.500);
   spot2_z = (targ.absmax_z + MOVETYPE_WALK);
   traceline (spot1,spot2,TRUE,self);
   if ( (trace_fraction == TRUE) ) {

      return ( TRUE );

   }
   if ( (trace_ent == targ) ) {

      return ( TRUE );

   }
   return ( FALSE );

};
float (vector spot) dropline = {

   local float drop;
   local vector spot2;
   local string tmp;

   spot2 = spot;
   spot2_z = (spot2_z - 500.000);
   traceline (spot,spot2,TRUE,self);
   drop = (spot_z - (trace_fraction * 500.000));
   return ( drop );

};
float (entity a, entity b, float bmaxjump) BotWalkable = {

   local vector spot1;
   local vector dir;
   local vector borg;
   local float tests;
   local float okpath;
   local float flr;
   local float goalheight;

   if ( (b.pathtype != DROPPED) ) {

      borg = ((b.absmin + b.absmax) * 0.500);
      borg_z = (b.absmin_z + TRUE);

   } else {

      borg = b.origin;

   }
   spot1 = a.origin;
   dir = normalize ((borg - a.origin));
   dir = (((dir * LEVELJUMPTIME) * BOTSPEED) * 6.500);
   tests = vlen ((borg - a.origin));
   tests = (tests / ((LEVELJUMPTIME * BOTSPEED) * 6.500));
   if ( (b.pathtype == DROPPED) ) {

      goalheight = (borg_z + self.mins_z);

   } else {

      goalheight = borg_z;

   }
   while ( (tests > TRUE) ) {

      okpath = TRUE;
      spot1 = (spot1 + dir);
      tests = (tests - TRUE);
      flr = dropline (spot1);
      if ( ((flr + bmaxjump) < goalheight) ) {

         spot1 = (spot1 - (dir * 0.500));
         flr = dropline (spot1);
         if ( ((flr + bmaxjump) < goalheight) ) {

            okpath = FALSE;

         }
         spot1 = (spot1 + dir);
         tests = (tests - 0.500);
         flr = dropline (spot1);
         if ( ((flr + bmaxjump) < goalheight) ) {

            if ( !okpath ) {

               return ( FALSE );

            }
            spot1 = (spot1 + (dir * 0.500));
            tests = (tests - 0.500);
            flr = dropline (spot1);
            if ( ((flr + bmaxjump) < goalheight) ) {

               return ( FALSE );

            }

         }

      }

   }
   return ( TRUE );

};
float (entity a, entity b) IsUpstream;
float /* Warning: Could not determine return type */ (entity a, entity b, float truereach) Reachable = {

   local vector spot1;
   local vector spot2;
   local vector borg;
   local float lnd;
   local float vel;
   local float diffz;
   local float diffxy;
   local float rng;
   local float maxzd;
   local float bmaxjump;
   local float brad;
   local string tmp;

   if ( truereach ) {

      bmaxjump = MAXJUMP;

   } else {

      bmaxjump = (0.600 * MAXJUMP);

   }
   if ( (b.pathtype != DROPPED) ) {

      borg = ((b.absmin + b.absmax) * 0.500);
      borg_z = (b.absmin_z + TRUE);

   } else {

      if ( (a.pathtype == DROPPED) ) {

         if ( IsUpstream (a,b) ) {

            return ( TRUE );

         }

      }
      borg = b.origin;

   }
   spot1 = a.origin;
   spot2 = borg;
   if ( (b.pathtype != DROPPED) ) {

      spot2_z = ((b.absmin_z + b.absmax_z) * 0.500);

   }
   rng = vlen ((spot2 - spot1));
   if ( truereach ) {

      if ( (rng > SEARCH_RADIUS) ) {

         return ( FALSE );

      }

   } else {

      if ( (rng > (SEARCH_RADIUS - (FL_SWIM * BOTSPEED))) ) {

         return ( FALSE );

      }

   }
   lnd = pointcontents (a.origin);
   if ( (lnd != CONTENT_WATER) ) {

      spot1_z = ((dropline (spot1) + self.view_ofs_z) - self.mins_z);

   }
   traceline (spot1,spot2,TRUE,a);
   spot2 = borg;
   if ( (lnd == CONTENT_WATER) ) {

      if ( !trace_inopen ) {

         if ( (trace_fraction == TRUE) ) {

            return ( TRUE );

         }
         if ( truereach ) {

            return ( TRUE );

         }

      }
      if ( truereach ) {

         maxzd = 45.000;
         lnd = pointcontents ((a.origin + self.view_ofs));
         if ( (lnd == CONTENT_WATER) ) {

            maxzd = (maxzd + self.view_ofs_z);

         }
         if ( (spot2_z < (a.origin_z + maxzd)) ) {

            if ( (trace_fraction == TRUE) ) {

               return ( TRUE );

            }
            spot1_z = spot2_z;
            traceline (spot1,spot2,TRUE,a);
            if ( (trace_fraction == TRUE) ) {

               return ( TRUE );

            }

         }

      }

   }
   if ( (trace_fraction != TRUE) ) {

      return ( FALSE );

   }
   spot1 = a.origin;
   if ( (spot2_z > (spot1_z + bmaxjump)) ) {

      return ( FALSE );

   }
   spot1 = a.origin;
   spot1_z = FALSE;
   spot2 = borg;
   spot2_z = FALSE;
   diffxy = vlen ((spot2 - spot1));
   diffxy = (diffxy - ((LEVELJUMPTIME * BOTSPEED) * MOVETYPE_BOUNCE));
   if ( (diffxy < FALSE) ) {

      return ( TRUE );

   }
   vel = FALSE;
   diffz = (a.origin_z - borg_z);
   while ( (diffz > FALSE) ) {

      diffxy = (diffxy - BOTSPEED);
      vel = (vel - GRAVITY);
      diffz = (diffz + (0.100 * vel));

   }
   if ( (diffxy < FALSE) ) {

      return ( TRUE );

   }
   return ( BotWalkable (a,b,bmaxjump) );

};
float /* Warning: Could not determine return type */ (entity a, entity b) BotReachable = {

   return ( Reachable (a,b,FALSE) );

};
float /* Warning: Could not determine return type */ (entity b) TrueReachable = {

   return ( Reachable (self,b,TRUE) );

};
