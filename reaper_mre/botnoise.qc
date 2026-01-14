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
   local entity bot;
   local vector diff;
   local vector existing_diff;
   local float dist_sq;
   local float existing_dist_sq;
   local float range_sq;

   if ((noisemaker.classname != "player"))
   {
      return ;
   } //end if

   range_sq = 1000000.000; // 1000u radius squared
   bot = findbot (world);
   while (bot)
   {
      diff = (bot.origin - noisemaker.origin);
      dist_sq = ((diff_x * diff_x) + (diff_y * diff_y));
      dist_sq = (dist_sq + (diff_z * diff_z));
      if ((dist_sq < range_sq))
      {
         if ((bot.noise_expires > time))
         {
            existing_diff = (bot.origin - bot.noise_target.origin);
            existing_dist_sq = ((existing_diff_x * existing_diff_x) + (existing_diff_y * existing_diff_y));
            existing_dist_sq = (existing_dist_sq + (existing_diff_z * existing_diff_z));
            if ((dist_sq < existing_dist_sq))
            {
               bot.noise_target = noisemaker;
               bot.noise_expires = (time + 2.000);
            } //end if
         } //end if
         else
         {
            bot.noise_target = noisemaker;
            bot.noise_expires = (time + 2.000);
         } //end else
      } //end if
      bot = findbot (bot);
   } //end while
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
      // ===== SIMULATED PERCEPTION (HEARING) LOGGING (LOG_VERBOSE+) =====
      if ((bot_debug_enabled && (bot_debug_level >= LOG_VERBOSE)))
      {
         bprint ("[");
         bprint (self.netname);
         bprint ("] HEAR: ");
         bprint (NOISEQUEUE.goalentity.netname);
         if ((NOISEQUEUE.movetarget.classname == "player"))
         {
            bprint (" (weapon-fire)\n");
         } //end if
         else
         {
            bprint (" (");
            bprint (NOISEQUEUE.movetarget.classname);
            bprint (")\n");
         } //end if
      } //end if
      // ===== END HEARING LOGGING =====
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
