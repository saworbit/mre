
// FIX: Removed halfwalkmove - the 0.05s sub-frame timing caused network
// interpolation issues ("jumpy" strafing). Movement now happens in single
// frames with velocity set for smooth client-side prediction.

float (float s_yaw, float s_dist) botwalkmove = {

   local vector move_dir;
   local vector check_pos;
   local float contents;

   self.oldorigin = self.origin;

   // FIX: Knockback / Rocket Jump Support
   // If the bot is airborne with significant velocity (explosion knockback, rocket jump),
   // do not override velocity with walking speed. Let physics take over.
   // Threshold 350 is above normal run speed (~320) but catches rocket jumps (~600+)
   if ( !(self.flags & FL_ONGROUND) ) {

      if ( vlen(self.velocity) > 350 ) {

         return ( FALSE );

      }

   }

   // FIX: Respect knockback physics
   // MOVETYPE_STEP ignores velocity for movement, so we must explicitly
   // apply knockback displacement during the knockback window
   if ( (time < (self.knockback_time + 0.400)) ) {

      // Apply velocity-based movement manually (frametime ~= 0.1)
      // Scale down to prevent excessive distance
      setorigin (self, (self.origin + (self.velocity * 0.050)));
      return ( FALSE );

   }

   // FIX: Smarter Lift Logic - wait on platforms instead of walking off
   // If we are ON a plat, wait for it to move us
   if ( (self.flags & FL_ONGROUND) ) {

      if ( (self.groundentity.classname == "func_plat") || (self.groundentity.classname == "plat") ) {

         // If the plat is moving UP or at TOP, wait for it
         if ( (self.groundentity.state == STATE_UP) || (self.groundentity.state == STATE_TOP) ) {

            self.velocity = '0 0 0';
            return ( TRUE );

         }

         // If plat is at BOTTOM, wait for it to trigger and rise
         if ( (self.groundentity.state == STATE_BOTTOM) ) {

            self.velocity = '0 0 0';
            return ( TRUE );

         }

      }

   }

   // FIX: Hazard Avoidance - check for lava/slime before moving
   // Project where we are going
   makevectors ('0 1 0' * s_yaw);
   check_pos = (self.origin + (v_forward * (s_dist + 16.000)));

   // Check floor at target position (drop down 24 units to check ground)
   check_pos_z = (check_pos_z - 24.000);
   contents = pointcontents (check_pos);

   // If the target is lethal, REFUSE TO MOVE
   // CONTENT_LAVA = -3, CONTENT_SLIME = -4
   if ( (contents == CONTENT_LAVA) || (contents == CONTENT_SLIME) ) {

      // Allow movement only if we have Pentagram (invulnerability) or Suit (slime only)
      if ( !(self.items & IT_INVULNERABILITY) ) {

         if ( !((self.items & IT_SUIT) && (contents == CONTENT_SLIME)) ) {

            return ( FALSE );

         }

      }

   }

   // Standard walkmove for actual position change
   if ( !walkmove (s_yaw, s_dist) ) {

      // FIX: Door Interaction - if we hit a door, trigger it and back up
      traceline (self.origin, (self.origin + (v_forward * 32.000)), FALSE, self);

      if ( (trace_ent.classname == "func_door") || (trace_ent.classname == "func_door_rotating") ) {

         // Trigger the door if it has a use function
         if ( trace_ent.use ) {

            trace_ent.use ();

         }

         // Back up slightly to let it open
         self.velocity = (v_forward * -200.000);

      }

      return ( FALSE );

   }

   // FIX: Set velocity to help client-side interpolation
   // Without this, walkmove updates position instantly causing "teleport" feel
   makevectors ('0 1 0' * s_yaw);
   self.velocity_x = (v_forward_x * s_dist * 10.000);
   self.velocity_y = (v_forward_y * s_dist * 10.000);

   return ( TRUE );

};
float (float dist) teleptest = {

   local vector start;
   local vector up;
   local vector target;

   up = self.origin;
   start = self.origin;
   if ( (dist < FALSE) ) {

      up_z = ((self.absmin_z + dist) - TRUE);

   } else {

      up_z = ((self.absmax_z + dist) + TRUE);

   }
   traceline (start,up,FALSE,self);
   if ( (trace_fraction < TRUE) ) {

      return ( FALSE );

   }
   start_x = (start_x + FL_INWATER);
   start_y = (start_y + FL_INWATER);
   up_x = (up_x + FL_INWATER);
   up_y = (up_y + FL_INWATER);
   traceline (start,up,FALSE,self);
   if ( (trace_fraction < TRUE) ) {

      return ( FALSE );

   }
   start_x = (start_x - FL_MONSTER);
   up_x = (up_x - FL_MONSTER);
   traceline (start,up,FALSE,self);
   if ( (trace_fraction < TRUE) ) {

      return ( FALSE );

   }
   start_y = (start_y - FL_MONSTER);
   up_y = (up_y - FL_MONSTER);
   traceline (start,up,FALSE,self);
   if ( (trace_fraction < TRUE) ) {

      return ( FALSE );

   }
   start_x = (start_x + FL_MONSTER);
   up_x = (up_x + FL_MONSTER);
   traceline (start,up,FALSE,self);
   if ( (trace_fraction < TRUE) ) {

      return ( FALSE );

   }
   start = self.origin;
   start_z = up_z;
   up = start;
   start_x = (start_x + FL_INWATER);
   up_x = (up_x - FL_INWATER);
   traceline (start,up,FALSE,self);
   if ( (trace_fraction < TRUE) ) {

      return ( FALSE );

   }
   start = self.origin;
   start_z = up_z;
   up = start;
   start_y = (start_y + FL_INWATER);
   up_y = (up_y - FL_INWATER);
   traceline (start,up,FALSE,self);
   if ( (trace_fraction < TRUE) ) {

      return ( FALSE );

   }

   // FIX: Additional checks to prevent "flashing" from teleporting into bad positions
   // Check headroom at target position (player height is ~56 units)
   target = self.origin;
   target_z = (target_z + dist);
   up = target;
   up_z = (up_z + 32.000);
   traceline (target, up, TRUE, self);
   if ( (trace_fraction < TRUE) ) {

      return ( FALSE );

   }

   // Check floor footing at target - must hit something (not void)
   up = target;
   up_z = (up_z - 24.000);
   traceline (target, up, TRUE, self);
   if ( (trace_fraction == TRUE) ) {

      // Falling into void - don't teleport
      return ( FALSE );

   }

   return ( TRUE );

};
float (float dist) waterupz = {

   local vector start;
   local vector up;

   if ( !teleptest (dist) ) {

      return ( FALSE );

   }
   up = self.origin;
   up_z = (up_z + dist);
   setorigin (self,up);
   return ( TRUE );

};
float (float dist) waterdownz = {

   local vector up;
   local vector start;

   if ( !teleptest ((CONTENT_EMPTY * dist)) ) {

      return ( FALSE );

   }
   up = self.origin;
   up_z = (up_z - dist);
   setorigin (self,up);
   return ( TRUE );

};
float (vector jmpv) Botjump = {

   if ( (self.flags & FL_ONGROUND) ) {

      self.flags = (self.flags - FL_ONGROUND);
    }
    sound (self, CHAN_BODY, "player/plyrjmp8.wav", 1, ATTN_NORM);
    self.velocity = jmpv;
    return ( TRUE );
 };

float (vector jmpv) Botwaterjump = {

   if ( (self.flags & FL_ONGROUND) ) {

      self.flags = (self.flags - FL_ONGROUND);

   }
   if ( !waterupz (45.000) ) {

      return ( FALSE );

   }
   jmpv_z = 200.000;
   self.velocity = jmpv;
   if ( (self.flags & FL_SWIM) ) {

      self.flags = (self.flags - FL_SWIM);

   }
   if ( (self.flags & FL_INWATER) ) {

      self.flags = (self.flags - FL_INWATER);

   }
   self.teleport_time = (time + 0.700);
      return ( TRUE );

};
float (entity targ) Swimto;
float (vector spot) CheckLavaOrLow = {

   local float lnd;
   local float boost;
   local vector spot2;

   lnd = pointcontents (spot);
   if ( ((lnd == CONTENT_LAVA) || (lnd == CONTENT_SLIME)) ) {

      return ( TRUE );

   }
   spot2 = spot;
   spot2_z = (spot_z + FL_CLIENT);
   lnd = pointcontents (spot2);
   if ( ((lnd == CONTENT_LAVA) || (lnd == CONTENT_SLIME)) ) {

      return ( TRUE );

   }
   if ( (lnd != CONTENT_WATER) ) {

      boost = (MAXJUMP + TRUE);
      if ( (self.goalentity.goalentity.classname == "func_button") ) {

         boost = ((boost + self.maxs_z) - TRUE);

      }
      if ( ((spot_z + boost) < self.goalentity.origin_z) ) {

         return ( TRUE );

      }

   } else {

      traceline (spot2,self.goalentity.absmin,TRUE,self);
      if ( trace_inopen ) {

         if ( ((spot_z + 45.000) > self.goalentity.origin_z) ) {

            return ( FALSE );

         }
         return ( TRUE );

      }
      if ( (trace_fraction == TRUE) ) {

         return ( FALSE );

      }
      return ( TRUE );

   }
   return ( FALSE );

};
float (vector middle) checkLanding = {

   local float goodcnt;
   local vector spot;
   local vector center;

   center = middle;
   spot = middle;
   spot_x = (spot_x + MOVETYPE_TOSS);
   if ( (pointcontents (spot) == CONTENT_SOLID) ) {

      center_x = (center_x - MOVETYPE_TOSS);

   }
   spot_x = (spot_x - 12.000);
   if ( (pointcontents (spot) == CONTENT_SOLID) ) {

      center_x = (center_x + MOVETYPE_TOSS);

   }
   spot = middle;
   spot_y = (spot_y + MOVETYPE_TOSS);
   if ( (pointcontents (spot) == CONTENT_SOLID) ) {

      center_y = (center_y - MOVETYPE_TOSS);

   }
   spot_y = (spot_y - 12.000);
   if ( (pointcontents (spot) == CONTENT_SOLID) ) {

      center_y = (center_y + MOVETYPE_TOSS);

   }
   spot = center;
   spot_z = dropline (spot);
   goodcnt = MOVETYPE_FLY;
   if ( CheckLavaOrLow (spot) ) {

      return ( FALSE );

   }
   spot = center;
   spot_x = (spot_x + MOVETYPE_TOSS);
   spot_z = dropline (spot);
   if ( CheckLavaOrLow (spot) ) {

      goodcnt = (goodcnt - TRUE);

   }
   spot = center;
   spot_x = (spot_x - MOVETYPE_TOSS);
   spot_z = dropline (spot);
   if ( CheckLavaOrLow (spot) ) {

      goodcnt = (goodcnt - TRUE);

   }
   spot = center;
   spot_y = (spot_y + MOVETYPE_TOSS);
   spot_z = dropline (spot);
   if ( CheckLavaOrLow (spot) ) {

      goodcnt = (goodcnt - TRUE);

   }
   spot = center;
   spot_y = (spot_y - MOVETYPE_TOSS);
   spot_z = dropline (spot);
   if ( CheckLavaOrLow (spot) ) {

      goodcnt = (goodcnt - TRUE);

   }
   if ( (goodcnt > MOVETYPE_WALK) ) {

      return ( TRUE );

   }
   return ( FALSE );

};
float (float dist) JumpUpToPush = {

   local float len;
   local vector botxy;
   local vector goalxy;
   local vector xydir;
   local vector jumpv;

   botxy = self.origin;
   botxy_z = FALSE;
   goalxy = self.goalentity.origin;
   goalxy_z = FALSE;
   xydir = normalize ((goalxy - botxy));
   len = vlen ((goalxy - botxy));
   if ( (len < 25.000) ) {

      jumpv = (xydir * KINDA_WANT);
      jumpv_z = 270.000;
      Botjump (jumpv);
      return ( TRUE );

   }
   if ( (len < 80.000) ) {

      jumpv = (xydir * (len / LEVELJUMPTIME));
      jumpv_z = 270.000;
      Botjump (jumpv);
      return ( TRUE );

   }
   return ( FALSE );

};
float /* Warning: Could not determine return type */ (float vz, float dist, float imagine) Bot_tryjump = {

   local float timetofloor;
   local float tvel;
   local float dis;
   local float diffz;
   local float diffxy;
   local float NOTLAND;
   local float lnd;
   local float len;
   local float depth;
   local float wlevel;
   local float velz;
   local float ht;
   local float frac;
   local float safety;
   local vector botxy;
   local vector goalxy;
   local vector xydir;
   local vector top;
   local vector bottom;
   local vector jumpv;
   local vector newtop;
   local vector newbottom;
   local vector back;
   local vector front;
   local vector dir;
   local vector start;
   local string tmp;
   local entity botTarget;

   if ( !(self.flags & (FL_ONGROUND + FL_SWIM)) ) {

      return ( FALSE );

   }
   wlevel = CheckWaterLevel ();
   if ( (wlevel > FL_SWIM) ) {

      return ( FALSE );

   }
   if ( !FacingIdeal () ) {

      ChangeYaw ();
      if ( !FacingIdeal () ) {

         ChangeYaw ();
         if ( !FacingIdeal () ) {

            ChangeYaw ();

         }

      }

   }
   makevectors (self.angles);
   start = (self.origin + (FL_INWATER * v_forward));
   botTarget = self.goalentity;
   velz = vz;
   if ( (wlevel >= TRUE) ) {

      if ( (velz > 200.000) ) {

         velz = 200.000;

      }

   }
   if ( (wlevel == FL_SWIM) ) {

      if ( (botTarget.origin_z < self.origin_z) ) {

         return ( FALSE );

      }
      start_z = (start_z + 45.000);

   }
   botxy = self.origin;
   botxy_z = FALSE;
   diffz = ((start_z - botTarget.origin_z) + TRUE);
   if ( (diffz < (CONTENT_EMPTY * MAXJUMP)) ) {

      if ( (botTarget.goalentity.classname != "trigger_push") ) {

         return ( FALSE );

      } else {

         if ( (diffz < FALSE) ) {

            if ( JumpUpToPush (dist) ) {

               return ( TRUE );

            }

         }

      }

   }
   dis = dist;
   goalxy = botTarget.origin;
   if ( (botTarget.goalentity.classname == "train") ) {

      goalxy = (goalxy + (LEVELJUMPTIME * botTarget.goalentity.velocity));

   }
   lnd = pointcontents (goalxy);
   if ( ((lnd == CONTENT_LAVA) || (lnd == CONTENT_SLIME)) ) {

      return ( FALSE );

   }
   goalxy_z = FALSE;
   xydir = normalize ((goalxy - botxy));
   diffxy = vlen ((goalxy - botxy));
   if ( (wlevel == FL_SWIM) ) {

      if ( (diffxy > (MOVETYPE_WALK * BOTSPEED)) ) {

         diffxy = (MOVETYPE_WALK * BOTSPEED);

      }

   }
   bottom = (start + self.view_ofs);
   top = (bottom + (xydir * dis));
   top_z = (top_z + (0.100 * (velz - GRAVITY)));
   traceline (bottom,top,TRUE,self);
   if ( (trace_fraction != TRUE) ) {

      if ( (velz > (GRAVITY + 180.000)) ) {

         return ( Bot_tryjump ((velz - GRAVITY),dist,imagine) );

      } else {

         return ( FALSE );

      }

   }
   bottom = (start - (FL_INWATER * v_forward));
   bottom_z = (bottom_z + self.mins_z);
   top = (bottom + ((xydir * dis) * FL_SWIM));
   top_z = ((top_z + (0.200 * (velz - GRAVITY))) - (0.100 * GRAVITY));
   traceline (bottom,top,TRUE,self);
   if ( (trace_fraction != TRUE) ) {

      if ( (diffxy > (1.900 * BOTSPEED)) ) {

         diffxy = (1.900 * BOTSPEED);

      }
      top = (bottom + (xydir * dis));
      top_z = ((top_z + (0.200 * (velz - GRAVITY))) - (0.100 * GRAVITY));
      traceline (bottom,top,TRUE,self);
      if ( (trace_fraction != TRUE) ) {

         if ( (diffxy > (0.900 * BOTSPEED)) ) {

            diffxy = (0.900 * BOTSPEED);

         }
         velz = 290.000;

      }

   }
   timetofloor = FALSE;
   tvel = velz;
   if ( (diffz < FALSE) ) {

      timetofloor = 0.300;

   } else {

      while ( (diffz > FALSE) ) {

         timetofloor = (timetofloor + 0.100);
         tvel = (tvel - GRAVITY);
         diffz = (diffz + (tvel * 0.100));

      }
      timetofloor = (timetofloor - (diffz / tvel));

   }
   if ( (diffxy < ((dis * MOVETYPE_BOUNCE) * timetofloor)) ) {

      jumpv = (xydir * (diffxy / timetofloor));

   } else {

      jumpv = (xydir * (MOVETYPE_BOUNCE * dis));
      if ( imagine ) {

         return ( FALSE );

      }

   }
   tvel = velz;
   bottom = start;
   bottom_z = (bottom_z + self.mins_z);
   ht = (self.view_ofs_z - self.mins_z);
   NOTLAND = TRUE;
   safety = FALSE;  // safety counter for void falls
   while ( NOTLAND ) {

      // Prevent infinite loop if bot jumps into void
      safety = (safety + TRUE);
      if ( (safety > 100.000) ) {

         return ( FALSE );

      }
      tvel = (tvel - GRAVITY);
      newbottom = (bottom + (jumpv * 0.100));
      newbottom_z = (newbottom_z + (tvel * 0.100));
      traceline (bottom,newbottom,TRUE,self);
      frac = trace_fraction;
      if ( (trace_fraction == TRUE) ) {

         newtop = newbottom;
         top = bottom;
         top_z = (top_z + ht);
         newtop_z = (newtop_z + ht);
         traceline (top,newtop,TRUE,self);
         if ( (trace_fraction == TRUE) ) {

            traceline (newbottom,newtop,TRUE,self);

         }
         if ( (trace_fraction == TRUE) ) {

            top = (top + (FL_INWATER * v_right));
            newtop = (newtop + (FL_INWATER * v_right));
            traceline (top,newtop,TRUE,self);

         }
         if ( (trace_fraction == TRUE) ) {

            top = (top - (FL_MONSTER * v_right));
            newtop = (newtop - (FL_MONSTER * v_right));
            traceline (top,newtop,TRUE,self);

         }
         if ( (trace_fraction != TRUE) ) {

            frac = 0.100;

         }

      }
      if ( (trace_fraction != TRUE) ) {

         dir = normalize ((newbottom - bottom));
         len = vlen ((newbottom - bottom));
         newbottom = (bottom + ((dir * len) * frac));
         newbottom_z = (newbottom_z + KINDA_WANT);
         if ( !checkLanding ((newbottom - (FL_INWATER * v_forward))) ) {

            return ( FALSE );

         }
         NOTLAND = FALSE;

      }
      if ( NOTLAND ) {

         if ( CheckLavaOrLow (newbottom) ) {

            return ( FALSE );

         }

      }
      lnd = pointcontents (newbottom);
      if ( (lnd == CONTENT_WATER) ) {

         NOTLAND = FALSE;

      }
      bottom = newbottom;

   }
   jumpv_z = velz;
   if ( imagine ) {

      if ( (wlevel == FL_SWIM) ) {

         return ( teleptest (45.000) );

      }
      return ( TRUE );

   }
   if ( (wlevel == FL_SWIM) ) {

      return ( Botwaterjump (jumpv) );

   }
   if ( (newbottom_z < (self.absmin_z - MAXJUMP)) ) {

      clearCache (self);

   }
   return ( Botjump (jumpv) );

};
float (float dist) waterupdown = {

   local float wlevel;
   local float dis;
   local float rnd;
   local float zbottom;

   dis = KINDA_WANT;
   wlevel = CheckWaterLevel ();
   if ( (wlevel < FL_SWIM) ) {

      return ( FALSE );

   }
   if ( (self.absmin_z > self.goalentity.origin_z) ) {

      if ( (dis > KINDA_WANT) ) {

         dis = KINDA_WANT;

      }
      if ( waterdownz (dis) ) {

         return ( TRUE );

      }
      if ( waterdownz ((dis * 0.500)) ) {

         return ( TRUE );

      }
      if ( waterdownz ((dis * 0.200)) ) {

         return ( TRUE );

      }

   }
   if ( (wlevel == MOVETYPE_WALK) ) {

      if ( (self.absmin_z < self.goalentity.origin_z) ) {

         dis = (self.goalentity.origin_z - self.absmin_z);
         if ( (dis > KINDA_WANT) ) {

            dis = KINDA_WANT;

         }
         if ( waterupz (dis) ) {

            return ( TRUE );

         }
         if ( waterupz ((dis * 0.500)) ) {

            return ( TRUE );

         }
         if ( waterupz ((dis * 0.200)) ) {

            return ( TRUE );

         }

      }

   }
   return ( FALSE );

};

void (float dist) strafemove = {

   local float ofs;
   local float rnd;
   local float move_yaw;

   // FIX: Respect knockback physics
   // MOVETYPE_STEP ignores velocity, so apply displacement manually
   if ( (time < (self.knockback_time + 0.400)) ) {

      setorigin (self, (self.origin + (self.velocity * 0.050)));
      return ;

   }

   if ( (self.flags & FL_SWIM) ) {

      if ( waterupdown (dist) ) {

         return ;

      }

   }
   ofs = 90.000;
   rnd = random ();
   if ( self.enemy ) {

      self.strafeonly = MOVETYPE_FLY;
      if ( (self.lefty & STRAFE_DIR) ) {

         ofs = (CONTENT_EMPTY * ofs);

      }

   } else {

      if ( (rnd < 0.500) ) {

         ofs = (CONTENT_EMPTY * ofs);

      }

   }
   move_yaw = (self.ideal_yaw + ofs);
   if ( walkmove (move_yaw, dist) ) {

      // FIX: Set velocity for smooth client interpolation
      makevectors ('0 1 0' * move_yaw);
      self.velocity_x = (v_forward_x * dist * 10.000);
      self.velocity_y = (v_forward_y * dist * 10.000);
      return ;

   }
   if ( self.enemy ) {

      return ;

   }
   ofs = (CONTENT_EMPTY * ofs);
   move_yaw = (self.ideal_yaw + ofs);
   if ( walkmove (move_yaw, dist) ) {

      // FIX: Set velocity for smooth client interpolation
      makevectors ('0 1 0' * move_yaw);
      self.velocity_x = (v_forward_x * dist * 10.000);
      self.velocity_y = (v_forward_y * dist * 10.000);
      return ;

   }
   if ( (self.flags & (FL_INWATER + FL_ONGROUND)) ) {

      self.search_time = (self.search_time - 0.300);

   }

};

void (float dist, float wlevel) BotUnderwaterMove = {

   local float rng;
   local float oldrng;
   local float rnd;

   rnd = random ();
   if ( (rnd < 0.750) ) {

      oldrng = vlen ((self.origin - self.goalentity.origin));
      movetogoal (dist);
      rng = vlen ((self.origin - self.goalentity.origin));
      if ( (oldrng > rng) ) {

         return ;

      }
      if ( (wlevel == FL_SWIM) ) {

         if ( Bot_tryjump (200.000,dist,FALSE) ) {

            return ;

         }

      }

   }
   strafemove (dist);

};
float (float dist) trysidestep = {

   local vector dir;
   local vector start;

   dir = (self.goalentity.origin - self.origin);
   dir_z = FALSE;
   dir = normalize (dir);
   start = self.origin;
   start_z = (self.origin_z + (self.view_ofs_z * 0.500));
   traceline (start,(start + (BOTSPEED * dir)),FALSE,self);
   if ( (trace_fraction != TRUE) ) {

      strafemove ((dist * 0.600));
      return ( TRUE );

   }
   makevectors (self.angles);
   start = (start + (v_right * 15.000));
   traceline (start,(start + (BOTSPEED * dir)),FALSE,self);
   if ( (trace_fraction != TRUE) ) {

      if ( walkmove ((self.ideal_yaw - 90.000),(dist * 0.600)) ) {

         return ( TRUE );

      }

   }
   start = (start - (v_right * SVC_INTERMISSION));
   traceline (start,(start + (BOTSPEED * dir)),FALSE,self);
   if ( (trace_fraction != TRUE) ) {

      if ( walkmove ((self.ideal_yaw + 90.000),(dist * 0.600)) ) {

         return ( TRUE );

      }

   }
   return ( FALSE );

};
float (float dist) testmove = {

   local float rng;
   local float oldrng;

   oldrng = vlen ((self.origin - self.goalentity.origin));
   movetogoal (dist);
   rng = vlen ((self.origin - self.goalentity.origin));
   if ( (rng < oldrng) ) {

      return ( TRUE );

   }
   return ( FALSE );

};

void (float dist) BotmovetoWindTunnel = {

   if ( testmove (dist) ) {

      return ;

   }
   if ( trysidestep (dist) ) {

      return ;

   }
   if ( Bot_tryjump (270.000,dist,FALSE) ) {

      return ;

   }
   strafemove ((dist * 0.500));
   return ;

};

void (float dist) BotmovetoVisiblegoal = {

   if ( walkmove (self.ideal_yaw,FL_CLIENT) ) {

      botwalkmove (self.ideal_yaw,(dist - FL_CLIENT));
      return ;

   }
   if ( walkmove ((self.ideal_yaw + 45.000),FL_CLIENT) ) {

      movetogoal ((dist - FL_CLIENT));
      return ;

   }
   if ( walkmove ((self.ideal_yaw - 45.000),FL_CLIENT) ) {

      movetogoal ((dist - FL_CLIENT));
      return ;

   }
   if ( trysidestep (dist) ) {

      return ;

   }
   if ( Bot_tryjump (270.000,dist,FALSE) ) {

      return ;

   }
   strafemove ((dist * 0.500));
   return ;

};

void (float dist) Botmovetogoal = {

   local entity Botgoal;
   local float wlevel;

   self.oldorigin = self.origin;
   Botgoal = self.goalentity;
   self.ideal_yaw = vectoyaw ((Botgoal.origin - self.origin));
   ChangeYaw ();
   if ( (self.flags & FL_INWATER) ) {

      wlevel = CheckWaterLevel ();
      if ( (wlevel > TRUE) ) {

         BotUnderwaterMove ((dist * 0.800),wlevel);
         return ;

      }

   }
   if ( (Botgoal.goalentity.classname == "trigger_push") ) {

      BotmovetoWindTunnel (dist);
      return ;

   }
   if ( Spotvisible (Botgoal) ) {

      BotmovetoVisiblegoal (dist);
      return ;

   }
   if ( testmove (dist) ) {

      return ;

   }
   strafemove ((dist * 0.800));
   return ;

};
