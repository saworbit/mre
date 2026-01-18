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

// Broadcast a noise event to all bots
void (entity source, vector org, float volume, float type) Bot_BroadcastNoise = {

   local entity bot;
   local float dist;
   local float real_vol;
   local float tr_allsolid;
   local float tr_startsolid;
   local float tr_fraction;
   local vector tr_endpos;
   local vector tr_plane_normal;
   local float tr_plane_dist;
   local entity tr_ent;
   local float tr_inopen;
   local float tr_inwater;

   // Save trace globals
   tr_allsolid = trace_allsolid;
   tr_startsolid = trace_startsolid;
   tr_fraction = trace_fraction;
   tr_endpos = trace_endpos;
   tr_plane_normal = trace_plane_normal;
   tr_plane_dist = trace_plane_dist;
   tr_ent = trace_ent;
   tr_inopen = trace_inopen;
   tr_inwater = trace_inwater;

   bot = find (world, classname, "dmbot");
   while ( bot ) {
      if ( (bot.health > FALSE) && (bot != source) ) {
         // 1. Distance
         dist = vlen (org - bot.origin);

         // 2. Occlusion
         traceline (org, (bot.origin + bot.view_ofs), TRUE, source);
         if ( (trace_fraction == TRUE) ) {
            real_vol = volume;
         } else {
            real_vol = (volume * 0.500);
         }

         // 3. Hearing check
         if ( (dist < real_vol) ) {
            bot.heard_sound_time = time;
            bot.heard_sound_loc = org;
            bot.heard_sound_type = type;
         }
      }
      bot = find (bot, classname, "dmbot");
   }

   // Restore trace globals
   trace_allsolid = tr_allsolid;
   trace_startsolid = tr_startsolid;
   trace_fraction = tr_fraction;
   trace_endpos = tr_endpos;
   trace_plane_normal = tr_plane_normal;
   trace_plane_dist = tr_plane_dist;
   trace_ent = tr_ent;
   trace_inopen = tr_inopen;
   trace_inwater = tr_inwater;

};
