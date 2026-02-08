// ai_specter.qc: Specter Gaze Swarm - cinematic spectator system

#define SPECTER_MAX_CAMS 4
#define SPECTER_BASE_THINK 0.100
#define SPECTER_REPLAY_DT 1.000
#define SPECTER_KALMAN_GAIN 0.300

float (float lo, float val, float hi) Specter_Bound = {

   if ( (val < lo) ) {
      return ( lo );
   }
   if ( (val > hi) ) {
      return ( hi );
   }
   return ( val );

};

float (entity bot) Specter_EventType = {

   if ( !bot ) {
      return ( 0.000 );
   }
   if ( (bot.last_ai_state == AI_STATE_ATTACK) || (bot.last_ai_state == AI_STATE_AMBUSH) ) {
      return ( 1.000 ); // Fight
   }
   if ( (time < (bot.last_rj_time + 1.000)) ) {
      return ( 2.000 ); // RJ/GLJ
   }
   if ( (time < (bot.ripple_probe_time + 0.200)) || bot.target_button ) {
      return ( 3.000 ); // Ripple / button sequence
   }
   if ( bot.groundentity && ((bot.groundentity.classname == "func_plat") || (bot.groundentity.classname == "func_train")) ) {
      return ( 4.000 ); // Platform ride
   }
   return ( 0.000 );

};

float (entity bot) Specter_Drama = {

   local float d;
   local float event;

   if ( !bot ) {
      return ( -9999.000 );
   }
   d = (TRUE + bot.mood_entropy);
   event = Specter_EventType (bot);
   if ( (bot.last_ai_state == AI_STATE_ATTACK) || (bot.last_ai_state == AI_STATE_AMBUSH) ) {
      d = (d + 10.000);
   }
   if ( (time < (bot.last_rj_time + 1.000)) ) {
      d = (d + 8.000);
   }
   if ( (time < (bot.ripple_probe_time + 0.200)) || bot.target_button ) {
      d = (d + 7.000);
   }
   if ( bot.groundentity && ((bot.groundentity.classname == "func_plat") || (bot.groundentity.classname == "func_train")) ) {
      d = (d + 5.000);
   }
   if ( (bot.frags > FALSE) ) {
      d = (d + (bot.frags * 0.100));
   }
   if ( (event == 0.000) ) {
      d = (d + 0.500);
   }
   return ( d );

};

float (float event) Specter_GetETA = {

   if ( (event == 1.000) ) return ( 0.150 );
   if ( (event == 2.000) ) return ( 0.400 );
   if ( (event == 3.000) ) return ( 0.250 );
   if ( (event == 4.000) ) return ( 0.300 );
   return ( 0.500 );

};

float (float event) Specter_GetDamp = {

   if ( (event == 1.000) ) return ( 0.250 );
   if ( (event == 2.000) ) return ( 0.350 );
   if ( (event == 3.000) ) return ( 0.300 );
   if ( (event == 4.000) ) return ( 0.400 );
   return ( 0.500 );

};

float (float event) Specter_GetThinkRate = {

   if ( (event == 1.000) ) return ( 0.050 );
   if ( (event == 2.000) ) return ( 0.080 );
   if ( (event == 3.000) ) return ( 0.100 );
   if ( (event == 4.000) ) return ( 0.120 );
   return ( 0.200 );

};

float (float event) Specter_GetCamDist = {

   if ( (event == 1.000) ) return ( 64.000 );
   if ( (event == 2.000) ) return ( 80.000 );
   if ( (event == 3.000) ) return ( 88.000 );
   if ( (event == 4.000) ) return ( 96.000 );
   return ( 104.000 );

};

float (float event) Specter_GetFanRays = {

   if ( (event == 1.000) ) return ( 3.000 );
   if ( (event == 2.000) ) return ( 2.000 );
   if ( (event == 3.000) ) return ( 2.000 );
   return ( 1.000 );

};

void (vector start, vector end, float count) Specter_SpawnGhostTrail = {

   local float i;
   local vector step;

   if ( (start == VEC_ORIGIN) || (end == VEC_ORIGIN) ) {
      return ;
   }
   if ( (count < 1.000) ) {
      return ;
   }
   step = (end - start);
   step = (step * (TRUE / count));
   i = 0.000;
   while ( (i < count) ) {
      particle ((start + (step * i)),'0 0 8',140.000,TRUE);
      i = (i + TRUE);
   }

};

void (entity viewer, entity cam) Specter_SetView = {

   if ( !viewer ) {
      return ;
   }
   if ( !cam ) {
      cam = viewer;
   }
   msg_entity = viewer;
   WriteByte (MSG_ONE,5);
   WriteEntity (MSG_ONE,cam);
   WriteByte (MSG_ONE,10);
   WriteAngle (MSG_ONE,cam.angles_x);
   WriteAngle (MSG_ONE,cam.angles_y);
   WriteAngle (MSG_ONE,cam.angles_z);
   viewer.weaponmodel = "";

};

void () Specter_AssignTargets = {

   local float i;
   local float j;
   local float drama;
   local entity bot;

   i = 0.000;
   while ( (i < SPECTER_MAX_CAMS) ) {
      specter_targets[i] = world;
      specter_scores[i] = -9999.000;
      i = (i + TRUE);
   }

   bot = find (world,classname,"dmbot");
   while ( bot ) {
      if ( (bot.health > FALSE) ) {
         drama = Specter_Drama (bot);
         i = 0.000;
         while ( (i < SPECTER_MAX_CAMS) ) {
            if ( (drama > specter_scores[i]) ) {
               j = (SPECTER_MAX_CAMS - TRUE);
               while ( (j > i) ) {
                  specter_scores[j] = specter_scores[j - TRUE];
                  specter_targets[j] = specter_targets[j - TRUE];
                  j = (j - TRUE);
               }
               specter_scores[i] = drama;
               specter_targets[i] = bot;
               break;
            }
            i = (i + TRUE);
         }
      }
      bot = find (bot,classname,"dmbot");
   }

};

void (entity cam, entity tgt, float drama, float event) Specter_UpdateCam = {

   local float eta;
   local float damp;
   local float camdist;
   local float height;
   local float rays;
   local float occlusion;
   local float yaw_off;
   local float pitch_off;
   local float r;
   local vector accel;
   local vector pred_pos;
   local vector ideal_ang;
   local vector test_ang;
   local vector desired;

   if ( !cam || !tgt ) {
      return ;
   }

   eta = Specter_GetETA (event);
   accel = (tgt.velocity - tgt.old_vel);
   accel = (accel * 10.000); // approx 0.1s delta
   pred_pos = (tgt.origin + (tgt.velocity * eta));
   pred_pos = (pred_pos + (accel * (eta * eta * 0.500 * SPECTER_KALMAN_GAIN)));

   ideal_ang = vectoangles (pred_pos - cam.origin);

   rays = Specter_GetFanRays (event);
   occlusion = 0.000;
   r = 0.000;
   while ( (r < rays) ) {
      yaw_off = 0.000;
      pitch_off = 0.000;
      if ( (rays > TRUE) ) {
         yaw_off = (((r / (rays - TRUE)) - 0.500) * 20.000);
         pitch_off = (fabs (yaw_off) * 0.500);
      }
      test_ang = ideal_ang;
      test_ang_x = (test_ang_x + pitch_off);
      test_ang_y = (test_ang_y + yaw_off);
      makevectors (test_ang);
      traceline (cam.origin,(pred_pos + (v_forward * 64.000)),TRUE,world);
      occlusion = (occlusion + trace_fraction);
      r = (r + TRUE);
   }
   occlusion = (occlusion / rays);

   damp = Specter_GetDamp (event);
   camdist = Specter_GetCamDist (event);
   camdist = (camdist + Specter_Bound (0.000,(6.000 - (drama * 0.100)),6.000));
   height = 16.000;
   if ( (event == 1.000) ) {
      height = 8.000;
   }
   makevectors (ideal_ang);
   desired = (pred_pos - (v_forward * camdist));
   desired = (desired + (v_up * height));
   cam.origin = ((cam.origin * (1.000 - damp)) + (desired * damp));

   if ( (occlusion < 0.700) ) {
      cam.origin = (cam.origin + (v_forward * (camdist * (0.700 - occlusion))));
      Specter_SpawnGhostTrail (cam.origin,pred_pos,6.000);
   }

   ideal_ang = vectoangles (pred_pos - cam.origin);
   cam.angles_x = ((cam.angles_x * (1.000 - damp)) + (ideal_ang_x * damp));
   cam.angles_y = ((cam.angles_y * (1.000 - damp)) + (ideal_ang_y * damp));
   cam.angles_z = 0.000;

   if ( (event == 1.000) ) {
      cam.angles_x = (cam.angles_x - 10.000);
   }
   if ( (event == 2.000) ) {
      Specter_SpawnGhostTrail (tgt.origin,pred_pos,5.000);
   }

};

void () Specter_Think = {

   local float i;
   local float event;
   local float focus_idx;
   local float focus_event;
   local entity cam;
   local entity tgt;

   if ( !specter_active ) {
      self.nextthink = (time + SPECTER_BASE_THINK);
      return ;
   }
   if ( !specter_owner || (specter_owner.classname != "player") ) {
      Specter_Reset ();
      return ;
   }

   Specter_AssignTargets ();

   i = 0.000;
   while ( (i < SPECTER_MAX_CAMS) ) {
      cam = specter_cams[i];
      tgt = specter_targets[i];
      if ( cam && tgt ) {
         event = Specter_EventType (tgt);
         Specter_UpdateCam (cam,tgt,specter_scores[i],event);
      } else if ( cam ) {
         cam.origin = specter_owner.origin;
         cam.angles = specter_owner.angles;
      }
      i = (i + TRUE);
   }

   focus_idx = 0.000;
   if ( (specter_force_until > time) ) {
      focus_idx = specter_focus;
   } else {
      if ( (specter_targets[0] == world) ) {
         focus_idx = -1.000;
      } else {
         focus_idx = 0.000;
         if ( (time > (specter_last_switch + 2.000)) && (random () < 0.150) ) {
            if ( (specter_targets[1] != world) ) {
               focus_idx = 1.000;
            }
         }
         specter_focus = focus_idx;
      }
   }

   if ( (focus_idx >= 0.000) && specter_cams[focus_idx] ) {
      if ( (specter_last_focus != focus_idx) ) {
         Specter_SetView (specter_owner,specter_cams[focus_idx]);
         specter_last_focus = focus_idx;
         specter_last_switch = time;
      }
   }

   focus_event = 0.000;
   if ( (focus_idx >= 0.000) && specter_targets[focus_idx] ) {
      focus_event = Specter_EventType (specter_targets[focus_idx]);
   }
   self.nextthink = (time + Specter_GetThinkRate (focus_event));

};

void () Specter_Spawn = {

   local float i;
   local entity cam;

   specter_active = TRUE;
   specter_owner = self;
   specter_focus = 0.000;
   specter_last_focus = -1.000;
   specter_force_until = 0.000;
   specter_last_switch = 0.000;

   self.specter_prev_movetype = self.movetype;
   self.specter_prev_solid = self.solid;
   self.specter_prev_takedamage = self.takedamage;
   self.specter_prev_flags = self.flags;

   self.movetype = MOVETYPE_NOCLIP;
   self.solid = SOLID_NOT;
   self.takedamage = DAMAGE_NO;
   self.flags = (self.flags | FL_NOTARGET);

   i = 0.000;
   while ( (i < SPECTER_MAX_CAMS) ) {
      cam = spawn ();
      cam.classname = "specter_cam";
      cam.movetype = MOVETYPE_NONE;
      cam.solid = SOLID_NOT;
      cam.owner = self;
      cam.origin = self.origin;
      cam.angles = self.angles;
      specter_cams[i] = cam;
      i = (i + TRUE);
   }
   if ( specter_cams[0] ) {
      specter_cams[0].think = Specter_Think;
      specter_cams[0].nextthink = (time + SPECTER_BASE_THINK);
   }
   Specter_SetView (self,specter_cams[0]);
   sprint (self,"Specter Gaze: ON\n");

};

void () Specter_Kill = {

   local float i;

   i = 0.000;
   while ( (i < SPECTER_MAX_CAMS) ) {
      if ( specter_cams[i] ) {
         remove (specter_cams[i]);
         specter_cams[i] = world;
      }
      i = (i + TRUE);
   }
   if ( specter_owner ) {
      Specter_SetView (specter_owner,specter_owner);
      specter_owner.movetype = specter_owner.specter_prev_movetype;
      specter_owner.solid = specter_owner.specter_prev_solid;
      specter_owner.takedamage = specter_owner.specter_prev_takedamage;
      specter_owner.flags = specter_owner.specter_prev_flags;
      W_SetCurrentAmmo ();
      sprint (specter_owner,"Specter Gaze: OFF\n");
   }
   specter_active = FALSE;
   specter_owner = world;
   specter_focus = 0.000;
   specter_last_focus = -1.000;
   specter_force_until = 0.000;
   specter_last_switch = 0.000;

};

void () Specter_Toggle = {

   if ( (self.classname != "player") ) {
      return ;
   }
   if ( specter_active ) {
      if ( specter_owner != self ) {
         sprint (self,"Specter Gaze already active.\n");
         return ;
      }
      Specter_Kill ();
      return ;
   }
   Specter_Spawn ();

};

void () Specter_CycleFocus = {

   if ( !specter_active ) {
      return ;
   }
   if ( (specter_owner != self) ) {
      return ;
   }
   specter_focus = (specter_focus + TRUE);
   if ( (specter_focus >= SPECTER_MAX_CAMS) ) {
      specter_focus = 0.000;
   }
   specter_force_until = (time + 5.000);
   if ( specter_cams[specter_focus] ) {
      Specter_SetView (self,specter_cams[specter_focus]);
      specter_last_focus = specter_focus;
   }
   sprint (self,"Specter focus ");
   sprint (self,ftos (specter_focus));
   sprint (self,"\n");

};

void (entity bot) Specter_SpawnReplay = {

   if ( !bot ) {
      return ;
   }
   Specter_SpawnGhostTrail (bot.replay_pos9,bot.replay_pos8,4.000);
   Specter_SpawnGhostTrail (bot.replay_pos8,bot.replay_pos7,4.000);
   Specter_SpawnGhostTrail (bot.replay_pos7,bot.replay_pos6,4.000);
   Specter_SpawnGhostTrail (bot.replay_pos6,bot.replay_pos5,4.000);
   Specter_SpawnGhostTrail (bot.replay_pos5,bot.replay_pos4,4.000);
   Specter_SpawnGhostTrail (bot.replay_pos4,bot.replay_pos3,4.000);
   Specter_SpawnGhostTrail (bot.replay_pos3,bot.replay_pos2,4.000);
   Specter_SpawnGhostTrail (bot.replay_pos2,bot.replay_pos1,4.000);
   Specter_SpawnGhostTrail (bot.replay_pos1,bot.replay_pos0,4.000);

};

void () Specter_Replay = {

   local entity bot;

   if ( !specter_active ) {
      return ;
   }
   if ( (specter_owner != self) ) {
      return ;
   }
   bot = specter_targets[specter_focus];
   if ( !bot ) {
      bot = specter_targets[0];
   }
   if ( !bot ) {
      return ;
   }
   Specter_SpawnReplay (bot);
   sprint (self,"Specter replay: ");
   sprint (self,bot.netname);
   sprint (self,"\n");

};

void () Specter_Reset = {

   local float i;

   i = 0.000;
   while ( (i < SPECTER_MAX_CAMS) ) {
      if ( specter_cams[i] ) {
         remove (specter_cams[i]);
      }
      specter_cams[i] = world;
      i = (i + TRUE);
   }
   specter_active = FALSE;
   specter_owner = world;
   specter_focus = 0.000;
   specter_last_focus = -1.000;
   specter_force_until = 0.000;
   specter_last_switch = 0.000;

};

void (entity bot) Specter_ReplayRecord = {

   if ( !bot ) {
      return ;
   }
   if ( (bot.classname != "dmbot") ) {
      return ;
   }
   if ( (time < bot.replay_next_time) ) {
      return ;
   }
   bot.replay_next_time = (time + SPECTER_REPLAY_DT);
   bot.replay_pos9 = bot.replay_pos8;
   bot.replay_pos8 = bot.replay_pos7;
   bot.replay_pos7 = bot.replay_pos6;
   bot.replay_pos6 = bot.replay_pos5;
   bot.replay_pos5 = bot.replay_pos4;
   bot.replay_pos4 = bot.replay_pos3;
   bot.replay_pos3 = bot.replay_pos2;
   bot.replay_pos2 = bot.replay_pos1;
   bot.replay_pos1 = bot.replay_pos0;
   bot.replay_pos0 = bot.origin;

};
