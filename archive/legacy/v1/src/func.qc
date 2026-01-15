/*  float (entity targ) infront */


void () fuck_thud = {

   local float tol;

   tol = -80.000;
   tol = ((tol * cvar ("sv_gravity")) / 800.000);
   if ( (self.flags & FL_ONGROUND) ) {

      if ( (self.velocity_z < tol) ) {

         self.flags = (self.flags - (self.flags & FL_ONGROUND));
         self.velocity_z = tol;

      }

   }

};
