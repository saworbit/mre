entity () noisetarget =
{
   local entity targ;

   targ = spawn ();
   targ.classname = "NoiseTarget";
   targ.solid = SOLID_NOT;
   setsize (targ,'-8.000 -8.000 -8.000','8.000 8.000 8.000');
   return (targ);
}; //end of the function noisetarget

void () removenoise =
{
   NOISEQUEUE.goalentity = world;
   NOISEQUEUE.movetarget = world;
}; //end of the function removenoise

void () death_taunt =
{
   // Death-complaint taunts escalate on streaks when bots hear gib events.
   if ((self.classname != "dmbot"))
   {
      return ;
   } //end if
   if ((self.death_streak > TRUE))
   {
      bprint (self.netname);
      bprint (": Cheap shot!\n");
      if ((self.death_streak > 3.000))
      {
         bprint (self.netname);
         bprint (": This server's rigged!\n");
      } //end if
   } //end if
}; //end of the function death_taunt

void (entity noisemaker, entity noiseobject) signalnoise =
{
   if ((noisemaker.classname != "player"))
   {
      return ;
   } //end if
   if (!NOISEQUEUE)
   {
      return ;
   } //end if
   NOISEQUEUE.goalentity = noisemaker;
   NOISEQUEUE.movetarget = noiseobject;
   NOISEQUEUE.think = removenoise;
   NOISEQUEUE.nextthink = (time + TRUE);
}; //end of the function signalnoise
float (entity e) hearnoise =
{
   local float rnd;
   local float taunt_roll;
   local string msg;

   if ((self.skil < TRUE))
   {
      return (FALSE);
   } //end if
   if ((self.skil < FL_SWIM))
   {
      rnd = (random () + 0.900);
      if ((self.skil < rnd))
      {
         return (FALSE);
      } //end if
   } //end if
   if ((NOISEQUEUE.goalentity == e))
   {
      dprint (self.teamname);
      dprint (self.classname);
      dprint (" heard ");
      dprint (NOISEQUEUE.goalentity.netname);
      if ((NOISEQUEUE.movetarget.classname == "player"))
      {
         dprint (" shoot\n");

      } //end if
      else
      {
         dprint (" trigger ");
         dprint (NOISEQUEUE.movetarget.classname);
         dprint ("\n");
      } //end if
      // Streak taunts: on hot streaks, occasionally mock the target with varied lines.
      if ((self.taunt_streak > 2.000))
      {
         if ((random () < 0.300))
         {
            taunt_roll = random ();
            if ((taunt_roll < 0.333))
            {
               msg = ": I hear you hiding, coward!";
            } //end if
            else
            {
               if ((taunt_roll < 0.666))
               {
                  msg = ": Another one bites the dust!";
               } //end if
               else
               {
                  msg = ": Keep running, I'll catch up!";
               } //end if
            } //end else
            bprint (self.netname);
            bprint (msg);
            if ((self.taunt_streak > 2.000))
            {
               bprint (" Again!");
            } //end if
            bprint ("\n");
            if ((self.taunt_streak > 4.000))
            {
               bprint (self.netname);
               bprint (": Come out and die like the last ones!\n");
            } //end if
         } //end if
      } //end if
      // If the noise was a gib event, vent on death streaks.
      if ((NOISEQUEUE.movetarget.classname == "gib"))
      {
         death_taunt ();
      } //end if
      return (TRUE);
   } //end if
   return (FALSE);
}; //end of the function hearnoise
float (entity e) heardistantnoise =
{
   return (FALSE);
}; //end of the function heardistantnoise
