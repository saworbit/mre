float CAM_IDLE    = 0.000;
float CAM_FIXED    = 1.000;
float CAM_FLYBY    = 2.000;
float CAM_FOLLOW    = 3.000;
float CAM_HAND    = 4.000;
float CAM_FREE    = 5.000;
float CAM_NOCLIP    = 6.000;
float CAM_DEATH    = 7.000;
float CAM_DIRECTOR = 8.000;  // AI Cameraman mode - auto-tracks best action
entity (entity ent) CamCycle =
{
   if ((ent == world))
   {
      self.cnt = REGULARTARGET;
   } //end if
   if ((self.cnt == REGULARTARGET))
   {
      ent = find (ent,classname,"player");
      if ((ent == world))
      {
         self.cnt = CARRIED;
      } //end if
   } //end if
   if ((self.cnt == CARRIED))
   {
      ent = find (ent,classname,"dmbot");
   } //end if
   return (ent);
}; //end of the function CamCycle

// ===== AI CAMERAMAN: Action Scoring System =====
// Rates each bot by "excitement level" for intelligent camera tracking
float (entity ent) CamActionScore =
{
   local float score;
   local float dist_to_action;

   score = 0;

   // Dead/invalid entities get no score
   if (!ent || ent.deadflag != DEAD_NO || ent.health <= 0)
   {
      return 0;
   }

   // COMBAT BONUS: Currently in a fight
   if (ent.enemy != world && ent.enemy.health > 0)
   {
      score = score + 300;  // Active combat = high priority

      // Close-quarters combat is more exciting
      dist_to_action = vlen(ent.origin - ent.enemy.origin);
      if (dist_to_action < 250)
      {
         score = score + 200;  // CQC bonus
      }

      // Low health combat = desperation (very exciting!)
      if (ent.health < 40)
      {
         score = score + 150;  // Underdog bonus
      }
      if (ent.enemy.health < 40)
      {
         score = score + 100;  // Finishing blow bonus
      }
   }

   // MOVEMENT BONUS: High-skill movement
   if (vlen(ent.velocity) > 400)
   {
      score = score + 80;  // Fast movement (bunny hopping, rocket jumps)
   }

   // POWERUP BONUS: Has quad/pent/ring
   if (ent.items & IT_QUAD)
   {
      score = score + 250;  // Quad damage = carnage potential
   }
   if (ent.items & IT_INVULNERABILITY)
   {
      score = score + 150;  // Pentagram = unstoppable
   }
   if (ent.items & IT_INVISIBILITY)
   {
      score = score + 100;  // Ring = stealth plays
   }

   // WEAPON BONUS: Has rockets (high action potential)
   if (ent.weapon == IT_ROCKET_LAUNCHER && ent.ammo_rockets > 0)
   {
      score = score + 50;
   }
   if (ent.weapon == IT_LIGHTNING && ent.ammo_cells > 5)
   {
      score = score + 40;
   }

   // TACTICAL BONUS: Show off Fear Engine routing (MRE feature!)
   // Bots making tactical decisions based on danger/traffic
   if (ent.classname == "dmbot")
   {
      // If bot is wounded and avoiding combat (tactical retreat)
      if (ent.health < 50 && !ent.enemy)
      {
         score = score + 120;  // Survival tactics = interesting AI
      }

      // If bot is seeking powerup (strategic play)
      if (ent.goalentity && ent.goalentity.classname == "item_artifact_super_damage")
      {
         score = score + 150;  // Quad pursuit
      }
   }

   // LEADER BONUS: Top scorer gets attention
   if (ent.frags > 5)
   {
      score = score + (ent.frags * 10);  // Scale with skill
   }

   // STREAK BONUS: High frag count = hot action
   if (ent.frags > 10)
   {
      score = score + 100;  // High scorer!
   }

   return score;
}; //end of the function CamActionScore

void (entity ent) CamVectors =
{
   if ((ent.classname == "player"))
   {
      makevectors (ent.v_angle);

   } //end if
   else
   {
      makevectors (ent.angles);
   } //end if
}; //end of the function CamVectors
void (entity client, string s1) camcenterprint1 = #73; 
void (entity client, string s1, string s2) camcenterprint2 = #73; 
void (entity client, string s1, string s2, string s3) camcenterprint3 = #73; 
void (entity client, string s1, string s2, string s3, string s4) camcenterprint4 = #73; 
void (entity client, string s1, string s2, string s3, string s4, string s5) camcenterprint5 = #73; 
void (entity client, string s1, string s2, string s3, string s4, string s5, string s6) camcenterprint6 = #73; 
void (entity client, string s1, string s2, string s3, string s4, string s5, string s6, string s7) camcenterprint7 = #73; 

void (entity ent, string tit) CamReport =
{
   local string s2;
   local string s3;

   if ((ent.frags < CARRIED))
   {
      s2 = "no";

   } //end if
   else
   {
      s2 = ftos (ent.frags);
   } //end if
   if ((ent.frags != CARRIED))
   {
      s3 = " frags";

   } //end if
   else
   {
      s3 = " frag";
   } //end if
   camcenterprint6 (self,tit,"\n\n\n",ent.netname," - ",s2,s3);
}; //end of the function CamReport
float (float num) CamSqrt =
{
   local float apr;

   if ((num < 0.001))
   {
      return (REGULARTARGET);
   } //end if
   if ((num > CARRIED))
   {
      apr = num;

   } //end if
   else
   {
      apr = CARRIED;
   } //end if
   do
   {
      apr = ((num + (apr * apr)) / (DROPPED * apr));
   } while ((fabs (((apr * apr) - num)) > (num * 0.001)));
   return (apr);
}; //end of the function CamSqrt
float (float a) CamReAngle =
{
   while ((a > 180.000))
   {
      a = (a - 360.000);
   } //end while
   while ((a < -180.000))
   {
      a = (a + 360.000);
   } //end while
   return (a);
}; //end of the function CamReAngle
float /* ERROR: Could not determine return type */ (vector vec) CamVisible =
{
   traceline (self.origin,vec,TRUE,self);
   return (((trace_fraction == CARRIED) && !(trace_inopen && trace_inwater)));
}; //end of the function CamVisible
float /* ERROR: Could not determine return type */ (entity ent) CamVisibleEnt =
{
   local vector vec;

   if (CamVisible (ent.origin))
   {
      return (TRUE);
   } //end if
   vec = ent.origin;
   vec_z = ent.absmin_z;
   if (CamVisible (vec))
   {
      return (TRUE);
   } //end if
   vec_z = (ent.absmax_z - EF_DIMLIGHT);
   return (CamVisible (vec));
}; //end of the function CamVisibleEnt
entity () CamShoot =
{
   local entity ent;
   local entity entx;
   local vector vec;
   local float d1;
   local float dx;

   makevectors (self.v_angle);
   entx = world;
   ent = CamCycle (world);
   dx = REGULARTARGET;
   while ((ent != world))
   {
      if ((ent.deadflag == DEAD_NO))
      {
         vec = (ent.origin - self.origin);
         vec = normalize (vec);
         d1 = (((v_forward_x * vec_x) + (v_forward_y * vec_y)) + (v_forward_z * vec_z));
         if ((d1 > dx))
         {
            if (CamVisible (ent.origin))
            {
               entx = ent;
               dx = d1;
            } //end if
         } //end if
      } //end if
      ent = CamCycle (ent);
   } //end while
   return (entx);
}; //end of the function CamShoot
float /* ERROR: Could not determine return type */ (float d, float a) CamHurry =
{
   local float dd;
   local float t;
   local float tt;

   if ((d < REGULARTARGET))
   {
      a = (REGULARTARGET - a);
   } //end if
   t = frametime;
   tt = CamSqrt ((d / a));
   if ((t > tt))
   {
      return (d);

   } //end if
   else
   {
      return (((a * t) * ((DROPPED * tt) - t)));
   } //end if
}; //end of the function CamHurry
vector (float s, float v, float a) CamSmooth =
{
   local float dt;
   local float t1;
   local float t2;
   local float v2;
   local float as;
   local float sv2;
   local float b;
   local vector vec;

   s = CamReAngle (s);
   v2 = (v / DROPPED);
   as = (a * s);
   sv2 = (v2 * v2);
   dt = frametime;
   if ((fabs (as) < sv2))
   {
      b = (v > REGULARTARGET);

   } //end if
   else
   {
      b = (s > REGULARTARGET);
   } //end if
   if (b)
   {
      t2 = (CamSqrt (((sv2 + as) / DROPPED)) / a);
      a = (REGULARTARGET - a);

   } //end if
   else
   {
      t2 = (CamSqrt (((sv2 - as) / DROPPED)) / a);
   } //end if
   t1 = (t2 - (v2 / a));
   if ((t1 > dt))
   {
      s = ((((a * dt) + v) * dt) + s);
      v = (((a * dt) * DROPPED) + v);

   } //end if
   else
   {
      s = ((((a * t1) + v) * t1) + s);
      v = (((a * t1) * DROPPED) + v);
      t1 = (dt - t1);
      if ((t1 < t2))
      {
         s = (((v - (a * t1)) * t1) + s);
         v = (v - ((a * t1) * DROPPED));

      } //end if
      else
      {
         s = REGULARTARGET;
         v = REGULARTARGET;
      } //end if
   } //end if
   vec_x = s;
   vec_y = v;
   return (vec);
}; //end of the function CamSmooth
float /* ERROR: Could not determine return type */ (vector vec) TryFlybyVector =
{
   local vector orig;
   local vector vec1;
   local float vl;

   vec1 = normalize (vec);
   vec = (700.000 * vec1);
   vec1 = (CAM_FREE * vec1);
   orig = self.enemy.origin;
   orig_z = (self.enemy.absmax_z - EF_DIMLIGHT);
   traceline (orig,(orig + vec),FALSE,self.enemy);
   if ((trace_ent != world))
   {
      return (1111.000);
   } //end if
   if ((trace_inopen && trace_inwater))
   {
      return (1111.000);
   } //end if
   trace_endpos = (trace_endpos - vec1);
   if ((pointcontents (trace_endpos) == CONTENT_SOLID))
   {
      return (1111.000);
   } //end if
   vl = vlen ((self.enemy.origin - trace_endpos));
   if ((vl < 50.000))
   {
      return (1111.000);
   } //end if
   return (fabs ((333.000 - vl)));
}; //end of the function TryFlybyVector

void (float speedv, float speeda) CamUpdatePos =
{
   local vector vec;
   local vector v1;
   local float vl;

   traceline (self.origin,self.dest,TRUE,self);
   if ((trace_fraction != CARRIED))
   {
      speedv = REGULARTARGET;
      speeda = REGULARTARGET;
   } //end if
   if ((speedv == REGULARTARGET))
   {
      setorigin (self,self.dest);

   } //end if
   else
   {
      vec = (self.dest - self.origin);
      vl = vlen (vec);
      vec = normalize (vec);
      vl = CamHurry (vl,speedv);
      vec = (vl * vec);
      setorigin (self,(self.origin + vec));
   } //end if
   self.fixangle = TRUE;
   self.movetype = MOVETYPE_NONE;
   if ((self.state != CAM_DEATH))
   {
      vec = vectoangles ((self.dest1 - self.dest));

   } //end if
   else
   {
      vec = vectoangles ((self.dest1 - self.origin));
   } //end if
   vec_z = REGULARTARGET;
   vec_x = CamReAngle ((360.000 - vec_x));
   vec_y = CamReAngle (vec_y);
   if ((vec_x > 70.000))
   {
      vec_x = 70.000;

   } //end if
   else
   {
      if ((vec_x < -70.000))
      {
         vec_x = -70.000;
      } //end if
   } //end if
   if ((speeda == REGULARTARGET))
   {
      self.angles = vec;
      self.mangle = VEC_ORIGIN;

   } //end if
   else
   {
      v1 = CamSmooth ((self.angles_x - vec_x),self.mangle_x,speeda);
      self.mangle_x = v1_y;
      self.angles_x = (vec_x + v1_x);
      v1 = CamSmooth ((self.angles_y - vec_y),self.mangle_y,speeda);
      self.mangle_y = v1_y;
      self.angles_y = (vec_y + v1_x);
      self.angles_x = CamReAngle (self.angles_x);
      self.angles_y = CamReAngle (self.angles_y);
   } //end if
   self.v_angle = self.angles;
}; //end of the function CamUpdatePos

void () CamSetAuto =
{
   self.dest = self.origin;
   makevectors (self.v_angle);
   self.dest1 = (self.origin + v_forward);
   CamUpdatePos (REGULARTARGET,REGULARTARGET);
}; //end of the function CamSetAuto

void () CamGoIdle =
{
   CamSetAuto ();
   self.state = CAM_IDLE;
   self.pausetime = (time + DROPPED);
   self.search_time = time;
   self.dest2 = self.dest1;
   self.enemy = self;
}; //end of the function CamGoIdle

void () CamGoDeath =
{
   if (self.aflag)
   {
      CamReport (self.enemy,"R.I.P.");
   } //end if
   self.mangle = VEC_ORIGIN;
   self.dest = self.origin;
   self.state = CAM_DEATH;
   self.pausetime = (time + CARRIED);
   self.movetarget = world;
   self.search_time = (time + CAM_FREE);
}; //end of the function CamGoDeath
vector (entity ent) CamFlybyTarget =
{
   local vector vec;

   vec = ent.origin;
   vec_z = (ent.absmax_z - EF_DIMLIGHT);
   return (vec);
}; //end of the function CamFlybyTarget

void (entity newtarg) CamInitFlybyMode =
{
   local float f;
   local float max;
   local vector vec;
   local vector vec2;
   local vector trg;
   local entity ent;

   self.pausetime = (time + 0.400);
   if ((self.enemy != newtarg))
   {
      self.enemy = newtarg;
      if ((self.movetarget != self.enemy))
      {
         if (self.aflag)
         {
            CamReport (self.enemy,"Now taking");
         } //end if
         self.movetarget = newtarg;
      } //end if
   } //end if
   vec = self.enemy.angles;
   vec_x = REGULARTARGET;
   vec_y = REGULARTARGET;
   makevectors (vec);
   v_forward = (NEVERTARGET * v_forward);
   max = 1000.000;
   f = TryFlybyVector (((v_up + v_forward) + v_right));
   if ((f < max))
   {
      max = f;
      vec = trace_endpos;
   } //end if
   f = TryFlybyVector (((v_up - v_forward) + v_right));
   if ((f < max))
   {
      max = f;
      vec = trace_endpos;
   } //end if
   f = TryFlybyVector (((v_up + v_forward) - v_right));
   if ((f < max))
   {
      max = f;
      vec = trace_endpos;
   } //end if
   f = TryFlybyVector (((v_up - v_forward) - v_right));
   if ((f < max))
   {
      max = f;
      vec = trace_endpos;
   } //end if
   if ((max >= 1000.000))
   {
      f = TryFlybyVector ((v_up + v_forward));
      if ((f < max))
      {
         max = f;
         vec = trace_endpos;
      } //end if
      f = TryFlybyVector ((v_up - v_forward));
      if ((f < max))
      {
         max = f;
         vec = trace_endpos;
      } //end if
      f = TryFlybyVector ((v_up + v_right));
      if ((f < max))
      {
         max = f;
         vec = trace_endpos;
      } //end if
      f = TryFlybyVector ((v_up - v_right));
      if ((f < max))
      {
         max = f;
         vec = trace_endpos;
      } //end if
   } //end if
   if ((max >= 1000.000))
   {
      f = TryFlybyVector ((v_forward + v_right));
      if ((f < max))
      {
         max = f;
         vec = trace_endpos;
      } //end if
      f = TryFlybyVector ((v_forward - v_right));
      if ((f < max))
      {
         max = f;
         vec = trace_endpos;
      } //end if
      f = TryFlybyVector (((VEC_ORIGIN - v_forward) + v_right));
      if ((f < max))
      {
         max = f;
         vec = trace_endpos;
      } //end if
      f = TryFlybyVector (((VEC_ORIGIN - v_forward) - v_right));
      if ((f < max))
      {
         max = f;
         vec = trace_endpos;
      } //end if
   } //end if
   if ((max >= 1000.000))
   {
      f = TryFlybyVector (v_forward);
      if ((f < max))
      {
         max = f;
         vec = trace_endpos;
      } //end if
      f = TryFlybyVector (v_right);
      if ((f < max))
      {
         max = f;
         vec = trace_endpos;
      } //end if
      f = TryFlybyVector ((VEC_ORIGIN - v_forward));
      if ((f < max))
      {
         max = f;
         vec = trace_endpos;
      } //end if
      f = TryFlybyVector ((VEC_ORIGIN - v_right));
      if ((f < max))
      {
         max = f;
         vec = trace_endpos;
      } //end if
   } //end if
   if ((max >= 1000.000))
   {
      f = TryFlybyVector ((((VEC_ORIGIN - v_up) + v_forward) + v_right));
      if ((f < max))
      {
         max = f;
         vec = trace_endpos;
      } //end if
      f = TryFlybyVector ((((VEC_ORIGIN - v_up) - v_forward) + v_right));
      if ((f < max))
      {
         max = f;
         vec = trace_endpos;
      } //end if
      f = TryFlybyVector ((((VEC_ORIGIN - v_up) + v_forward) - v_right));
      if ((f < max))
      {
         max = f;
         vec = trace_endpos;
      } //end if
      f = TryFlybyVector ((((VEC_ORIGIN - v_up) - v_forward) - v_right));
      if ((f < max))
      {
         max = f;
         vec = trace_endpos;
      } //end if
   } //end if
   if ((max >= 1000.000))
   {
      f = TryFlybyVector (((VEC_ORIGIN - v_up) + v_forward));
      if ((f < max))
      {
         max = f;
         vec = trace_endpos;
      } //end if
      f = TryFlybyVector (((VEC_ORIGIN - v_up) + v_right));
      if ((f < max))
      {
         max = f;
         vec = trace_endpos;
      } //end if
      f = TryFlybyVector (((VEC_ORIGIN - v_up) - v_forward));
      if ((f < max))
      {
         max = f;
         vec = trace_endpos;
      } //end if
      f = TryFlybyVector (((VEC_ORIGIN - v_up) - v_right));
      if ((f < max))
      {
         max = f;
         vec = trace_endpos;
      } //end if
   } //end if
   if ((max >= 1000.000))
   {
      CamGoIdle ();
      self.pausetime = (time + DROPPED);
      return ;
   } //end if
   self.dest1 = CamFlybyTarget (self.enemy);
   self.dest = vec;
   self.state = CAM_FLYBY;
   self.lip = (1.500 * vlen ((self.dest - self.dest1)));
   if ((self.lip < 500.000))
   {
      self.lip = 500.000;
   } //end if
   CamUpdatePos (REGULARTARGET,REGULARTARGET);
}; //end of the function CamInitFlybyMode
vector () GetFollowCam =
{
   local vector vec;
   local vector vec2;

   CamVectors (self.enemy);
   vec = (self.enemy.origin + ((self.enemy.maxs_z + CAM_HAND) * v_up));
   traceline (self.enemy.origin,vec,FALSE,self);
   vec = (trace_endpos - normalize (vec));
   vec2 = (-100.000 * v_forward);
   traceline (vec,(vec + vec2),TRUE,self);
   vec2 = (trace_endpos - normalize (vec2));
   if (CamVisible (vec2))
   {
      return (vec2);

   } //end if
   else
   {
      return (vec);
   } //end if
}; //end of the function GetFollowCam
vector () GetFollowTrg =
{
   local vector vec;

   if ((self.enemy.deadflag == DEAD_NO))
   {
      CamVectors (self.enemy);
      vec = (self.enemy.origin + (MULTIENEMY * v_forward));

   } //end if
   else
   {
      vec = self.enemy.origin;
   } //end if
   return (vec);
}; //end of the function GetFollowTrg

void () CamHandJump =
{
   makevectors (self.v_angle);
   traceline (self.origin,(self.origin + (2000.000 * v_forward)),TRUE,self);
   self.dest = (trace_endpos - (CAM_FREE * normalize ((trace_endpos - self.origin))));
   self.dest1 = self.origin;
   CamUpdatePos (REGULARTARGET,REGULARTARGET);
}; //end of the function CamHandJump
entity (float n) CamGetPos =
{
   local entity ent;

   ent = find (world,classname,"CamSavedPos");
   while (((n > REGULARTARGET) && (ent != world)))
   {
      ent = find (ent,classname,"CamSavedPos");
      n = (n - CARRIED);
   } //end while
   return (ent);
}; //end of the function CamGetPos

void (float n) CamSavePos =
{
   local entity ent;

   ent = CamGetPos (n);
   if ((ent != world))
   {
      ent.angles = self.angles;
      ent.v_angle = self.v_angle;
      setorigin (ent,self.origin);
   } //end if
}; //end of the function CamSavePos

void (float n) CamLoadPos =
{
   local entity ent;

   if ((((self.state == CAM_HAND) || (self.state == CAM_FREE)) || (self.state == CAM_NOCLIP)))
   {
      ent = CamGetPos (n);
      if ((ent != world))
      {
         self.fixangle = TRUE;
         self.angles = ent.angles;
         self.v_angle = ent.v_angle;
         setorigin (self,ent.origin);
      } //end if
   } //end if
}; //end of the function CamLoadPos

void () CamImpulses =
{
   local float c;
   local entity ent;
   local string s;

   if ((self.impulse == MUST_HAVE))
   {
      self.goalentity = world;
      CamGoIdle ();

   } //end if
   else
   {
      if (((self.impulse > MUST_HAVE) && (self.impulse < 150.000)))
      {
         self.goalentity = world;
         c = (self.impulse - MUST_HAVE);
         ent = world;
         do
         {
            ent = CamCycle (ent);
            c = (c - CARRIED);
         } while (((c > REGULARTARGET) && (ent != world)));
         if ((ent != world))
         {
            if ((ent.deadflag == DEAD_NO))
            {
               CamInitFlybyMode (ent);
               self.delay = (time + TE_LAVASPLASH);
               self.search_time = (time + 60.000);
            } //end if
         } //end if

      } //end if
      else
      {
         if (((self.impulse >= 180.000) && (self.impulse <= 189.000)))
         {
            c = (self.impulse - 180.000);
            CamSavePos (c);

         } //end if
         else
         {
            if (((self.impulse >= 190.000) && (self.impulse <= 199.000)))
            {
               c = (self.impulse - 190.000);
               CamLoadPos (c);

            } //end if
            else
            {
               if ((self.impulse == 300.000))
               {
                  if ((self.enemy != self))
                  {
                     CamInitFlybyMode (self.enemy);

                  } //end if
                  else
                  {
                     ent = CamShoot ();
                     if ((ent != world))
                     {
                        CamInitFlybyMode (ent);
                        self.delay = (time + TE_LAVASPLASH);
                        self.search_time = (time + 60.000);
                     } //end if
                  } //end if

               } //end if
               else
               {
                  if ((self.impulse == 301.000))
                  {
                     if ((self.enemy != self))
                     {
                        self.state = CAM_FOLLOW;

                     } //end if
                     else
                     {
                        ent = CamShoot ();
                        if ((ent != world))
                        {
                           self.enemy = ent;
                           self.movetarget = ent;
                           if (self.aflag)
                           {
                              CamReport (self.enemy,"Now Taking");
                           } //end if
                           self.state = CAM_FOLLOW;
                           self.search_time = (time + 60.000);
                           self.mangle = VEC_ORIGIN;
                        } //end if
                     } //end if

                  } //end if
                  else
                  {
                     if ((self.impulse == 302.000))
                     {
                        if (((self.state != CAM_FLYBY) && (self.state != CAM_FIXED)))
                        {
                           CamHandJump ();
                        } //end if
                        self.state = CAM_HAND;
                        self.movetype = MOVETYPE_NONE;
                        self.enemy = self;
                        self.movetarget = world;

                     } //end if
                     else
                     {
                        if ((self.impulse == 303.000))
                        {
                           self.state = CAM_FREE;
                           self.movetype = MOVETYPE_FLY;
                           self.enemy = self;
                           self.movetarget = world;

                        } //end if
                        else
                        {
                           if ((self.impulse == 304.000))
                           {
                              self.state = CAM_NOCLIP;
                              self.enemy = self;
                              self.movetarget = world;
                              self.movetype = MOVETYPE_NOCLIP;

                           } //end if
                           else
                           {
                              if ((self.impulse == 305.000))
                              {
                                 if (((self.state == CAM_FLYBY) || (self.state == CAM_HAND)))
                                 {
                                    CamSetAuto ();
                                    self.state = CAM_FIXED;
                                    self.enemy = self;
                                    self.movetarget = world;
                                    self.search_time = (time + 100000.000);
                                    self.pausetime = (time + NEVERTARGET);
                                 } //end if

                              } //end if
                              else
                              {
                                 if ((self.impulse == 310.000))
                                 {
                                    self.aflag = !self.aflag;

                                 } //end if
                                 else
                                 {
                                    if ((self.impulse == 311.000))
                                    {
                                       bprint ("Current camera position: ");
                                       bprint (vtos (self.origin));
                                       bprint ("\n");

                                    } //end if
                                    else
                                    {
                                       if ((self.impulse == 312.000))
                                       {
                                          self.aflag = TRUE;

                                       } //end if
                                       else
                                       {
                                          if ((self.impulse == 313.000))
                                          {
                                             self.aflag = FALSE;

                                          } //end if
                                          else
                                          {
                                             if ((self.impulse == 314.000))
                                             {
                                                self.attack_state = TRUE;

                                             } //end if
                                             else
                                             {
                                                if ((self.impulse == 315.000))
                                                {
                                                   self.attack_state = FALSE;

                                                } //end if
                                                else
                                                {
                                                   if ((self.impulse == 316.000))
                                                   {
                                                      if ((self.enemy != self))
                                                      {
                                                         self.goalentity = self.enemy;
                                                      } //end if

                                                   } //end if
                                                   else
                                                   {
                                                      if ((self.impulse == 317.000))
                                                      {
                                                         if ((self.enemy != self))
                                                         {
                                                            ent = CamCycle (world);
                                                            while (((ent != world) && (ent != self.enemy)))
                                                            {
                                                               ent = CamCycle (ent);
                                                            } //end while
                                                            if ((ent != world))
                                                            {
                                                               c = TRUE;
                                                               while (c)
                                                               {
                                                                  ent = CamCycle (ent);
                                                                  if ((ent == world))
                                                                  {
                                                                     ent = CamCycle (ent);
                                                                  } //end if
                                                                  if ((ent == world))
                                                                  {
                                                                     c = FALSE;

                                                                  } //end if
                                                                  else
                                                                  {
                                                                     if ((ent.deadflag == DEAD_NO))
                                                                     {
                                                                        if ((self.goalentity != world))
                                                                        {
                                                                           self.goalentity = ent;
                                                                        } //end if
                                                                        CamInitFlybyMode (ent);
                                                                        self.delay = (time + TE_LAVASPLASH);
                                                                        self.search_time = (time + 60.000);
                                                                        c = FALSE;
                                                                     } //end if
                                                                  } //end if
                                                               } //end while
                                                            } //end if
                                                         } //end if
                                                      } //end if
                                                   } //end if
                                                } //end if
                                             } //end if
                                          } //end if
                                       } //end if
                                    } //end if
                                 } //end if
                              } //end if
                           } //end if
                        } //end if
                     } //end if
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
   } //end if

   // ===== AI CAMERAMAN: Return to Director Mode =====
   if ((self.impulse == 400.000))
   {
      bprint ("AI Cameraman re-activated!\n");
      self.state = CAM_DIRECTOR;
      self.enemy = self;
      self.search_time = time;  // Start scanning immediately
      self.aflag = TRUE;  // Enable target announcements
   } //end if

   self.impulse = REGULARTARGET;
}; //end of the function CamImpulses

void () CamUpdValues =
{
   local float it;

   if ((((self.enemy != self) && (self.enemy.classname != "bodyque")) && (self.enemy.health > REGULARTARGET)))
   {
      it = (((IT_INVISIBILITY | IT_INVULNERABILITY) | IT_SUIT) | IT_QUAD);
      self.items = ((self.enemy.items | it) - it);
      self.health = self.enemy.health;
      self.armorvalue = self.enemy.armorvalue;
      self.ammo_shells = self.enemy.ammo_shells;
      self.ammo_nails = self.enemy.ammo_nails;
      self.ammo_rockets = self.enemy.ammo_rockets;
      self.ammo_cells = self.enemy.ammo_cells;
      self.weapon = self.enemy.weapon;
      self.currentammo = self.enemy.currentammo;

   } //end if
   else
   {
      self.items = REGULARTARGET;
      self.health = 111.000;
      self.armorvalue = 111.000;
      self.ammo_shells = 111.000;
      self.ammo_nails = 111.000;
      self.ammo_rockets = 111.000;
      self.ammo_cells = 111.000;
      self.weapon = IT_AXE;
      self.currentammo = 111.000;
   } //end if
}; //end of the function CamUpdValues
float (entity ent) CamHealthVal =
{
   local float alldmg;

   alldmg = (ent.health / (CAM_FIXED - ent.armortype));
   if ((alldmg > (ent.health + ent.armorvalue)))
   {
      alldmg = (ent.health + ent.armorvalue);
   } //end if
   return (alldmg);
}; //end of the function CamHealthVal

void () CamIdleThink =
{
   local entity ent;
   local entity ent2;
   local vector vec;
   local vector vec2;
   local float p1;
   local float p2;
   local float pa;
   local float pb;

   ent2 = self;
   if ((self.movetarget != world))
   {
      if ((self.movetarget.deadflag == DEAD_NO))
      {
         ent2 = self.movetarget;
      } //end if
   } //end if
   p2 = CONTENT_EMPTY;
   p1 = (CAM_FREE * random ());
   if ((self.goalentity != world))
   {
      if ((self.goalentity.deadflag == DEAD_NO))
      {
         ent2 = self.goalentity;

      } //end if
      else
      {
         ent2 = self;
      } //end if

   } //end if
   else
   {
      if ((p1 < CAM_FIXED))
      {
         ent = CamCycle (world);
         while ((ent != world))
         {
            if (((ent != self.movetarget) && (ent.deadflag == DEAD_NO)))
            {
               p1 = CamHealthVal (ent);
               if ((p2 < p1))
               {
                  ent2 = ent;
                  p2 = p1;
               } //end if
            } //end if
            ent = CamCycle (ent);
         } //end while

      } //end if
      else
      {
         if ((p1 < CAM_FLYBY))
         {
            ent = CamCycle (world);
            while ((ent != world))
            {
               if (((ent != self.movetarget) && (ent.deadflag == DEAD_NO)))
               {
                  p1 = ent.frags;
                  if ((p1 < REGULARTARGET))
                  {
                     p1 = REGULARTARGET;
                  } //end if
                  if ((p2 < p1))
                  {
                     ent2 = ent;
                     p2 = p1;
                  } //end if
               } //end if
               ent = CamCycle (ent);
            } //end while

         } //end if
         else
         {
            p2 = REGULARTARGET;
            ent = CamCycle (world);
            while ((ent != world))
            {
               if (((ent != self.movetarget) && (ent.deadflag == DEAD_NO)))
               {
                  p2 = (p2 + CAM_FIXED);
               } //end if
               ent = CamCycle (ent);
            } //end while
            if ((p2 > REGULARTARGET))
            {
               p2 = (p2 * random ());
               ent = world;
               do
               {
                  do
                  {
                     ent = CamCycle (ent);
                  } while (((ent == self.movetarget) || (ent.deadflag != DEAD_NO)));
                  p2 = (p2 - CAM_FIXED);
               } while ((p2 > REGULARTARGET));
               if ((ent != world))
               {
                  ent2 = ent;
               } //end if
            } //end if
         } //end if
      } //end if
   } //end if
   if ((ent2 != self))
   {
      CamInitFlybyMode (ent2);
      self.delay = (time + TE_LAVASPLASH);
      self.search_time = (time + 60.000);

   } //end if
   else
   {
      self.enemy = self;
      traceline (self.dest,self.dest1,TRUE,self);
      self.dest1 = trace_endpos;
      vec_x = ((40.000 * random ()) - LOOPTIME);
      vec_y = (360.000 * random ());
      vec_z = REGULARTARGET;
      pa = vec_y;
      if ((self.origin != self.dest))
      {
         vec2 = (self.origin - self.dest);
         vec2 = vectoangles (vec2);
         pb = vec2_y;

      } //end if
      else
      {
         pb = REGULARTARGET;
      } //end if
      pa = CamReAngle (pa);
      makevectors (vec);
      vec = (2000.000 * v_forward);
      p2 = vlen ((self.dest2 - self.dest));
      if ((fabs (CamReAngle ((pa - pb))) > 60.000))
      {
         vec2 = (self.dest + vec);
         traceline (self.dest,vec2,TRUE,self);
         vec2 = trace_endpos;
         p1 = vlen ((vec2 - self.dest));
         if ((p1 > p2))
         {
            self.dest2 = vec2;
            p2 = p1;
         } //end if
      } //end if
      pa = (pa + 180.000);
      pa = CamReAngle (pa);
      if ((fabs (CamReAngle ((pa - pb))) > 60.000))
      {
         vec2 = (self.dest - vec);
         traceline (self.dest,vec2,TRUE,self);
         vec2 = trace_endpos;
         p1 = vlen ((vec2 - self.dest));
         if ((p1 > p2))
         {
            self.dest2 = vec2;
            p2 = p1;
         } //end if
      } //end if
      if ((self.pausetime < time))
      {
         self.pausetime = ((time + NEVERTARGET) + (CAM_FLYBY * random ()));
         self.dest1 = self.dest2;
      } //end if
      if ((self.search_time < time))
      {
         vec = (self.dest - self.dest1);
         vec = ((CAM_FREE + (50.000 * random ())) * normalize (vec));
         vec = (self.dest1 + vec);
         traceline (self.origin,vec,TRUE,self);
         if ((trace_fraction == CAM_FIXED))
         {
            self.dest = vec;
            self.dest2 = self.dest1;
            self.search_time = ((time + EF_DIMLIGHT) + (CAM_FREE * random ()));

         } //end if
         else
         {
            self.dest2 = self.dest;
            self.search_time = ((time + CAM_FIXED) + random ());
         } //end if
      } //end if
   } //end if
}; //end of the function CamIdleThink

void () CamFlyByThink =
{
   local float p0;
   local float p1;
   local float grad;
   local float p;
   local vector vec;
   local entity ent;
   local float ok;

   if ((self.enemy.deadflag != DEAD_NO))
   {
      if ((time < SVC_FINALE))
      {
         CamGoIdle ();
         return ;
      } //end if
      CamGoDeath ();
      return ;
   } //end if
   p1 = vlen ((self.dest - self.enemy.origin));
   CamVisibleEnt (self.enemy);
   CamVisibleEnt (self.enemy);
   if (((CamVisibleEnt (self.enemy) && (self.lip > p1)) || (self.pausetime > time)))
   {
      self.dest1 = CamFlybyTarget (self.enemy);

   } //end if
   else
   {
      CamInitFlybyMode (self.enemy);
   } //end if
   if (self.attack_state)
   {
      self.state = CAM_FOLLOW;
      return ;

   } //end if
   else
   {
      p1 = vlen ((self.enemy.origin - self.origin));
      if ((p1 < 170.000))
      {
         grad = fabs ((self.enemy.angles_y - self.angles_y));
         if ((grad > 180.000))
         {
            grad = (360.000 - grad);
         } //end if
         if ((grad < SVC_INTERMISSION))
         {
            vec = GetFollowCam ();
            if (CamVisible (vec))
            {
               self.state = CAM_FOLLOW;
               return ;
            } //end if
         } //end if
      } //end if
   } //end if
   if ((self.goalentity == world))
   {
      p0 = REGULARTARGET;
      p1 = REGULARTARGET;
      if ((self.delay < time))
      {
         ent = CamCycle (world);
         while ((ent != world))
         {
            p0 = (p0 + CAM_FIXED);
            if ((ent.deadflag == DEAD_NO))
            {
               p = vlen ((ent.origin - self.origin));
               if ((p < 1500.000))
               {
                  if (CamVisible (ent.origin))
                  {
                     p1 = (p1 + CAM_FIXED);
                  } //end if
               } //end if
            } //end if
            ent = CamCycle (ent);
         } //end while
      } //end if
      if ((p0 < CAM_HAND))
      {
         p0 = CAM_FLYBY;

      } //end if
      else
      {
         if ((p0 < EF_DIMLIGHT))
         {
            p0 = NEVERTARGET;

         } //end if
         else
         {
            p0 = CAM_HAND;
         } //end if
      } //end if
      if ((p1 > p0))
      {
         self.enemy = self;
         self.movetarget = world;
         self.state = CAM_FIXED;
         self.search_time = (time + 15.000);
         self.pausetime = (time + NEVERTARGET);
         return ;
      } //end if
   } //end if
   if ((self.search_time < time))
   {
      CamGoIdle ();
   } //end if
}; //end of the function CamFlyByThink

void () CamFollowThink =
{
   local entity ent;
   local vector vec;

   if ((self.enemy.deadflag != DEAD_NO))
   {
      if ((time < SVC_FINALE))
      {
         CamGoIdle ();
         return ;
      } //end if
      CamGoDeath ();
      return ;

   } //end if
   else
   {
      if (CamVisibleEnt (self.enemy))
      {
         self.dest = GetFollowCam ();
         self.dest1 = GetFollowTrg ();
         if ((pointcontents (self.dest) == CONTENT_SOLID))
         {
            CamInitFlybyMode (self.enemy);
         } //end if

      } //end if
      else
      {
         CamInitFlybyMode (self.enemy);
      } //end if
   } //end if
   if ((self.search_time < time))
   {
      CamGoIdle ();
   } //end if
}; //end of the function CamFollowThink

void () CamFixedThink =
{
   local vector vec;
   local entity ent;
   local float cang;
   local float a;
   local float cscr;
   local float maxscr;
   local float minscr;
   local float maxlo;
   local float minhi;
   local vector scrv;
   local vector hiv;
   local vector lov;
   local float c;

   cang = self.v_angle_y;
   cscr = REGULARTARGET;
   maxscr = -45.000;
   minscr = 45.000;
   maxlo = -181.000;
   minhi = 181.000;
   scrv = VEC_ORIGIN;
   c = REGULARTARGET;
   ent = CamCycle (world);
   while ((ent != world))
   {
      if ((ent.deadflag == DEAD_NO))
      {
         a = vlen ((ent.origin - self.origin));
         if ((a < 1500.000))
         {
            if (CamVisible (ent.origin))
            {
               c = (c + CAM_FIXED);
               vec = vectoangles ((ent.origin - self.origin));
               a = (vec_y - cang);
               while ((a > 180.000))
               {
                  a = (a - 360.000);
               } //end while
               while ((a < -180.000))
               {
                  a = (a + 360.000);
               } //end while
               if ((fabs (a) < 45.000))
               {
                  cscr = (cscr + CAM_FIXED);
                  scrv = (scrv + ent.origin);
                  if ((a < minscr))
                  {
                     minscr = a;
                  } //end if
                  if ((a > maxscr))
                  {
                     maxscr = a;
                  } //end if

               } //end if
               else
               {
                  if ((a > REGULARTARGET))
                  {
                     if ((a < minhi))
                     {
                        minhi = a;
                        hiv = ent.origin;
                     } //end if

                  } //end if
                  else
                  {
                     if ((a > maxlo))
                     {
                        maxlo = a;
                        lov = ent.origin;
                     } //end if
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
      ent = CamCycle (ent);
   } //end while
   if ((c > REGULARTARGET))
   {
      if ((c > CAM_FIXED))
      {
         self.pausetime = (time + NEVERTARGET);
      } //end if
      if ((cscr < c))
      {
         if ((((cscr == REGULARTARGET) || ((maxscr - maxlo) <= 90.000)) || ((minhi - minscr) <= 90.000)))
         {
            cscr = (cscr + CAM_FIXED);
            if (((maxscr - maxlo) > (minhi - minscr)))
            {
               scrv = (scrv + hiv);

            } //end if
            else
            {
               scrv = (scrv + lov);
            } //end if
         } //end if
      } //end if
      scrv_x = (scrv_x / cscr);
      scrv_y = (scrv_y / cscr);
      scrv_z = (scrv_z / cscr);
      self.dest1 = scrv;
   } //end if
   self.dest = self.origin;
   if (((self.pausetime < time) || (self.search_time < time)))
   {
      CamGoIdle ();
   } //end if
}; //end of the function CamFixedThink

void () CamDeathThink =
{
   local float f;

   if ((self.search_time < time))
   {
      CamGoIdle ();
      return ;
   } //end if
   if ((self.enemy != self))
   {
      f = vlen ((self.origin - self.dest));
      if (((f > CAM_FIXED) || (self.mangle != VEC_ORIGIN)))
      {
         f = (time + 0.500);
         if ((self.pausetime < f))
         {
            self.pausetime = f;
         } //end if
      } //end if
   } //end if
   if ((time > self.pausetime))
   {
      CamGoIdle ();

   } //end if
   else
   {
      if ((self.enemy != self))
      {
         self.dest1 = self.enemy.origin;
      } //end if
   } //end if
   if ((self.enemy != self))
   {
      traceline (self.origin,self.dest1,TRUE,self);
      if ((trace_fraction != CAM_FIXED))
      {
         if ((self.enemy.velocity == VEC_ORIGIN))
         {
            CamGoIdle ();

         } //end if
         else
         {
            CamInitFlybyMode (self.enemy);
            self.state = CAM_DEATH;
            self.pausetime = (time + CAM_FLYBY);
         } //end if
      } //end if
      if ((self.enemy.velocity != VEC_ORIGIN))
      {
         self.pausetime = (time + CAM_FLYBY);
      } //end if
   } //end if
   if ((vlen ((self.dest - self.dest1)) > 60.000))
   {
      self.dest = (self.dest - self.dest1);
      self.dest = normalize (self.dest);
      self.dest = ((59.000 * self.dest) + self.dest1);
   } //end if
}; //end of the function CamDeathThink

// ===== AI CAMERAMAN: Director Mode Think Function =====
// Automatically tracks the most exciting action based on scoring
void () CamDirectorThink =
{
   local entity best_target;
   local entity scan_ent;
   local float best_score;
   local float current_score;

   // Re-evaluate targets every 2 seconds or when current target dies
   if (time < self.search_time && self.enemy != world && self.enemy.deadflag == DEAD_NO)
   {
      // Keep tracking current target with flyby camera
      self.dest1 = CamFlybyTarget(self.enemy);
      if (!CamVisibleEnt(self.enemy))
      {
         // Lost sight, force re-evaluation
         self.search_time = time;
      }
      return;
   }

   // SCAN ALL ENTITIES for best action
   best_target = world;
   best_score = 0;

   // Scan players
   scan_ent = find(world, classname, "player");
   while (scan_ent)
   {
      current_score = CamActionScore(scan_ent);
      if (current_score > best_score)
      {
         best_score = current_score;
         best_target = scan_ent;
      }
      scan_ent = find(scan_ent, classname, "player");
   }

   // Scan bots
   scan_ent = find(world, classname, "dmbot");
   while (scan_ent)
   {
      current_score = CamActionScore(scan_ent);
      if (current_score > best_score)
      {
         best_score = current_score;
         best_target = scan_ent;
      }
      scan_ent = find(scan_ent, classname, "dmbot");
   }

   // If we found an exciting target, switch to them
   if (best_target != world && best_target != self.enemy)
   {
      // Smooth transition via flyby mode
      CamInitFlybyMode(best_target);
      self.state = CAM_DIRECTOR;  // Stay in director mode

      // Show what's happening (optional: disable if too spammy)
      if (self.aflag)  // Only if camera reports enabled
      {
         local string msg;
         msg = "AI Camera: Tracking ";
         camcenterprint2(self, msg, best_target.netname);
      }

      // Check again in 2 seconds
      self.search_time = time + 2.0;
   }
   else if (best_target == world)
   {
      // No action found, go idle and scan again soon
      self.search_time = time + 1.0;
   }
}; //end of the function CamDirectorThink

void () CamThink =
{
   CamUpdValues ();
   self.velocity = VEC_ORIGIN;
   self.avelocity = VEC_ORIGIN;
   if ((self.state == CAM_IDLE))
   {
      CamIdleThink ();
      CamUpdatePos (CAM_FIXED,80.000);

   } //end if
   else
   {
      if ((self.state == CAM_FLYBY))
      {
         CamFlyByThink ();
         CamUpdatePos (REGULARTARGET,500.000);

      } //end if
      else
      {
         if ((self.state == CAM_FOLLOW))
         {
            CamFollowThink ();
            CamUpdatePos (800.000,1000.000);

         } //end if
         else
         {
            if ((self.state == CAM_FIXED))
            {
               CamFixedThink ();
               CamUpdatePos (REGULARTARGET,80.000);

            } //end if
            else
            {
               if ((self.state == CAM_DEATH))
               {
                  CamDeathThink ();
                  CamUpdatePos (MUST_HAVE,150.000);

               } //end if
               else
               {
                  if ((self.state == CAM_DIRECTOR))
                  {
                     // AI CAMERAMAN MODE - Auto-track best action!
                     CamDirectorThink ();
                     // Use flyby positioning for smooth tracking
                     CamUpdatePos (REGULARTARGET,500.000);
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
   } //end if
   CamImpulses ();
}; //end of the function CamThink

void () CamClientInit =
{
   local entity ent;

   self.classname = "KasCam";
   setmodel (self,string_null);
   self.weaponmodel = string_null;
   setsize (self,VEC_ORIGIN,VEC_ORIGIN);
   self.velocity = VEC_ORIGIN;
   self.view_ofs = VEC_ORIGIN;
   self.movetype = MOVETYPE_NONE;
   self.solid = SOLID_NOT;
   self.takedamage = DAMAGE_NO;
   self.fixangle = TRUE;
   self.nextthink = CONTENT_EMPTY;
   self.colormap = REGULARTARGET;
   self.effects = REGULARTARGET;
   self.rad_time = CAM_FIXED;
   self.radsuit_finished = REGULARTARGET;
   self.invincible_time = REGULARTARGET;
   self.invincible_finished = REGULARTARGET;
   self.invisible_time = REGULARTARGET;
   self.invisible_finished = REGULARTARGET;
   self.super_time = REGULARTARGET;
   self.super_damage_finished = REGULARTARGET;
   self.dest = self.origin;
   makevectors (self.v_angle);
   self.dest1 = (self.dest + (MUST_HAVE * v_forward));
   self.enemy = self;
   self.movetarget = world;
   self.goalentity = world;
   self.aflag = TRUE;
   self.mangle = VEC_ORIGIN;
   self.pausetime = time;
   self.delay = time;
   self.attack_state = FALSE;

   // ===== START IN AI CAMERAMAN MODE =====
   self.state = CAM_DIRECTOR;
   self.enemy = self;
   self.search_time = time;  // Start scanning immediately
   self.dest2 = self.dest1;

   bprint ("\n");
   bprint ("===========================================\n");
   bprint ("  AI CAMERAMAN ACTIVATED (impulse 400)\n");
   bprint ("===========================================\n");
   bprint ("Auto-tracking most exciting action!\n");
   bprint ("\n");
   bprint ("Controls:\n");
   bprint ("  impulse 300 = Flyby mode (manual target)\n");
   bprint ("  impulse 301 = Follow mode\n");
   bprint ("  impulse 303 = Free-flight camera\n");
   bprint ("  impulse 310 = Toggle info display\n");
   bprint ("  impulse 317 = Cycle to next player\n");
   bprint ("  impulse 400 = Return to AI Director\n");
   bprint ("\n");
}; //end of the function CamClientInit

void () CamSpawn =
{
   local float i;
   local entity ent;
   local entity start;

   start = find (world,classname,"info_player_start");
   i = TE_LAVASPLASH;
   while ((i > REGULARTARGET))
   {
      ent = spawn ();
      ent.classname = "CamSavedPos";
      ent.angles = start.angles;
      ent.v_angle = start.v_angle;
      setorigin (ent,start.origin);
      i = (i - CAM_FIXED);
   } //end while
}; //end of the function CamSpawn
float () CamDisconnect =
{
   local entity cam;
   local entity oself;

   if ((self.classname == "KasCam"))
   {
      bprint ("Camera deactivated\n");
      return (FALSE);

   } //end if
   else
   {
      cam = find (world,classname,"KasCam");
      while (cam)
      {
         if ((cam.enemy == self))
         {
            oself = self;
            self = cam;
            CamGoIdle ();
            self = oself;
         } //end if
         if ((cam.movetarget == self))
         {
            cam.movetarget = world;
         } //end if
         cam = find (cam,classname,"KasCam");
      } //end while
      return (TRUE);
   } //end if
}; //end of the function CamDisconnect

void (entity ent, entity que) CamCopyBody =
{
   local entity oself;
   local entity cam;

   cam = find (world,classname,"KasCam");
   while (cam)
   {
      if ((ent == cam.enemy))
      {
         if ((cam.state != CAM_DEATH))
         {
            oself = self;
            self = cam;
            CamGoDeath ();
            self = oself;
         } //end if
         cam.enemy = que;

      } //end if
      else
      {
         if ((que == cam.enemy))
         {
            cam.enemy = cam;
         } //end if
      } //end if
      cam = find (cam,classname,"KasCam");
   } //end while
}; //end of the function CamCopyBody
