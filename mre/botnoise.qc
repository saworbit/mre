entity () noisetarget = {

   local entity targ;

   targ = spawn ();
   targ.classname = "NoiseTarget";
   targ.solid = SOLID_NOT;
   setsize (targ,'-8.000 -8.000 -8.000','8.000 8.000 8.000');
   return ( targ );

};

void () removenoise = {

   NOISEQUEUE.goalentity = world;
   NOISEQUEUE.movetarget = world;

};

void (entity noisemaker, entity noiseobject) signalnoise = {

   if ( (noisemaker.classname != "player") ) {

      return ;

   }
   if ( !NOISEQUEUE ) {

      return ;

   }
   NOISEQUEUE.goalentity = noisemaker;
   NOISEQUEUE.movetarget = noiseobject;
   NOISEQUEUE.think = removenoise;
   NOISEQUEUE.nextthink = (time + TRUE);

};
float (entity e) hearnoise = {

   local float rnd;

   if ( (self.skil < TRUE) ) {

      return ( FALSE );

   }
   if ( (self.skil < FL_SWIM) ) {

      rnd = (random () + 0.900);
      if ( (self.skil < rnd) ) {

         return ( FALSE );

      }

   }
   if ( (NOISEQUEUE.goalentity == e) ) {

      dprint (self.teamname);
      dprint (self.classname);
      dprint (" heard ");
      dprint (NOISEQUEUE.goalentity.netname);
      if ( (NOISEQUEUE.movetarget.classname == "player") ) {

         dprint (" shoot\n");

      } else {

         dprint (" trigger ");
         dprint (NOISEQUEUE.movetarget.classname);
         dprint ("\n");

      }
      return ( TRUE );

   }
   return ( FALSE );

};
float (entity e) heardistantnoise = {

   return ( FALSE );

};
