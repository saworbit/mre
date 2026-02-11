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
   // Low health duel: dramatic tension
   if ( (bot.health > FALSE) && (bot.health < 30.000) && bot.enemy ) {
      d = (d + 6.000);
   }
   // Recent combat: hold camera for active fighter
   if ( (bot.frags > FALSE) && (time < (bot.last_ai_state_time + 2.000)) && (bot.last_ai_state == AI_STATE_ATTACK) ) {
      d = (d + 4.000);
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

void (entity cam, entity tgt) Specter_ChaseCam = {

   local vector start;
   local vector endpos;

   if ( !cam || !tgt ) {
      return ;
   }
   start = (tgt.origin + tgt.view_ofs);
   makevectors (tgt.angles);
   endpos = (start - (v_forward * 64.000));
   endpos = (endpos + (v_up * 16.000));
   traceline (start, endpos, TRUE, world);
   cam.origin = trace_endpos;
   cam.angles = vectoangles (tgt.origin - cam.origin);

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

// Called from PlayerPreThink every server frame (like CCam)
void () Specter_ViewUpdate = {

   local float dt;
   local float damp;
   local float c;
   local entity cam;
   local entity tgt;
   local vector look_at;
   local vector ang;
   local vector delta;

   if ( !specter_active ) {
      return ;
   }
   if ( (specter_owner != self) ) {
      return ;
   }
   if ( !specter_view_ent ) {
      return ;
   }

   cam = specter_view_ent;

   // Non-camera view entities (chase mode, bot fallback, player fallback)
   if ( (cam.classname != "specter_cam") ) {
      Specter_SetView (self, cam);
      setorigin (self, cam.origin);
      return ;
   }

   // --- Frame-rate independent damping ---
   dt = frametime;
   if ( (dt <= 0.000) || (dt > 0.200) ) {
      dt = 0.014;
   }
   damp = (cam.speed * dt * 10.000);
   if ( (damp > 1.000) ) {
      damp = 1.000;
   }
   if ( (damp < 0.010) ) {
      damp = 0.010;
   }

   // --- Smooth position interpolation ---
   cam.origin = (cam.origin + ((cam.pos1 - cam.origin) * damp));

   // --- Position validation ---
   c = pointcontents (cam.origin);
   if ( (c == CONTENT_SOLID) || (c == CONTENT_SKY) ) {
      cam.origin = cam.pos1;
   }
   if ( cam.enemy ) {
      if ( (vlen (cam.origin - cam.enemy.origin) > 1024.000) ) {
         cam.origin = cam.pos1;
      }
   }

   // Link camera for BSP PVS
   setorigin (cam, cam.origin);

   // --- Angles from geometry (no lerp = no wrapping bugs) ---
   tgt = cam.enemy;
   if ( tgt ) {
      look_at = (tgt.origin + '0 0 16');
   } else {
      look_at = cam.pos2;
   }

   delta = (look_at - cam.origin);
   if ( (vlen (delta) > 1.000) ) {
      ang = vectoangles (delta);
   } else {
      ang = cam.angles;
   }

   // Combat tilt
   if ( (cam.cnt == 1.000) ) {
      ang_x = (ang_x - 10.000);
   }
   ang_z = 0.000;
   cam.angles = ang;

   // Send view + angles to client
   Specter_SetView (self, cam);

   // Move player for PVS
   setorigin (self, cam.origin);

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

   bot = bot_list_head;  // OPT: cached bot linked list
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
      bot = bot.bot_next;
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
   local vector safe;
   local vector delta;
   local float max_pred;

   if ( !cam || !tgt ) {
      return ;
   }

   // Chase mode: Think handles view binding, nothing to position here
   if ( cvar ("specter_chase") > FALSE ) {
      return ;
   }

   // --- Prediction ---
   eta = Specter_GetETA (event);
   accel = (tgt.velocity - tgt.old_vel);
   accel = (accel * 10.000); // approx 0.1s delta
   pred_pos = (tgt.origin + (tgt.velocity * eta));
   pred_pos = (pred_pos + (accel * (eta * eta * 0.500 * SPECTER_KALMAN_GAIN)));
   // Clamp prediction to stay near target (teleports can push far)
   max_pred = 400.000;
   delta = (pred_pos - tgt.origin);
   if ( (vlen (delta) > max_pred) ) {
      pred_pos = (tgt.origin + (normalize (delta) * max_pred));
   }

   // --- Occlusion fan ---
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

   // --- Desired camera position ---
   damp = Specter_GetDamp (event);
   camdist = Specter_GetCamDist (event);
   camdist = (camdist + Specter_Bound (0.000,(6.000 - (drama * 0.100)),6.000));
   // Pull camera closer when view is occluded (instead of post-push)
   if ( (occlusion < 0.700) ) {
      camdist = (camdist * (0.400 + (occlusion * 0.857)));
      if ( (camdist < 32.000) ) {
         camdist = 32.000;
      }
   }
   height = 16.000;
   if ( (event == 1.000) ) {
      height = 8.000;
   }
   makevectors (ideal_ang);
   desired = (pred_pos - (v_forward * camdist));
   desired = (desired + (v_up * height));

   // Keep camera inside the map: trace from target to desired position
   traceline (pred_pos, desired, TRUE, world);
   safe = desired;
   if ( (trace_fraction < 1.000) ) {
      safe = (trace_endpos + (trace_plane_normal * 8.000));
   }
   // Reject positions in the void (no floor below)
   traceline (safe, safe - '0 0 1024', TRUE, world);
   if ( trace_fraction == 1.000 ) {
      safe = (pred_pos + '0 0 24');
   }
   // Reject if safe landed in solid or sky
   if ( (pointcontents (safe) == CONTENT_SOLID) || (pointcontents (safe) == CONTENT_SKY) ) {
      safe = (pred_pos + '0 0 24');
   }

   // --- Store targets for ViewUpdate (per-frame interpolation) ---
   cam.pos1 = safe;
   cam.pos2 = pred_pos;
   cam.enemy = tgt;
   cam.speed = damp;
   cam.cnt = event;

   // Ghost trail when occluded (decorative, stays in Think)
   if ( (occlusion < 0.700) ) {
      Specter_SpawnGhostTrail (cam.origin,pred_pos,6.000);
   }
   if ( (event == 2.000) ) {
      Specter_SpawnGhostTrail (tgt.origin,pred_pos,5.000);
   }

};

float (entity cam, entity tgt) Specter_CamInvalid = {

   local float c;
   local float tr_allsolid;
   local float tr_startsolid;
   local float tr_fraction;
   local vector tr_endpos;
   local vector tr_plane_normal;
   local float tr_plane_dist;
   local entity tr_ent;
   local float tr_inopen;
   local float tr_inwater;

   if ( !cam || !tgt ) {
      return ( TRUE );
   }
   c = pointcontents (cam.origin);
   if ( (c == CONTENT_SOLID) || (c == CONTENT_SKY) ) {
      return ( TRUE );
   }
   if ( vlen (cam.origin - tgt.origin) > 1024.000 ) {
      return ( TRUE );
   }
   // Void check: no floor within 1024 units
   tr_allsolid = trace_allsolid;
   tr_startsolid = trace_startsolid;
   tr_fraction = trace_fraction;
   tr_endpos = trace_endpos;
   tr_plane_normal = trace_plane_normal;
   tr_plane_dist = trace_plane_dist;
   tr_ent = trace_ent;
   tr_inopen = trace_inopen;
   tr_inwater = trace_inwater;

   traceline (cam.origin, cam.origin - '0 0 1024', TRUE, world);
   if ( trace_fraction == 1.000 ) {
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
      return ( TRUE );
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
   return ( FALSE );

};

void () Specter_Think = {

   local float i;
   local float event;
   local float focus_idx;
   local float focus_event;
   local entity cam;
   local entity tgt;
   local float chase;

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
         cam.pos1 = specter_owner.origin;
         cam.pos2 = specter_owner.origin;
         cam.enemy = world;
         cam.speed = 0.500;
         cam.cnt = 0.000;
      }
      i = (i + TRUE);
   }

   chase = cvar ("specter_chase");
   focus_idx = 0.000;
   if ( chase > FALSE ) {
      // Chase mode: keep a stable target, avoid random switching
      if ( (specter_focus < 0.000) || (specter_focus >= SPECTER_MAX_CAMS) || (specter_targets[specter_focus] == world) ) {
         specter_focus = 0.000;
         specter_last_switch = time;
      }
      if ( (specter_targets[specter_focus] == world) ) {
         focus_idx = -1.000;
      } else {
         focus_idx = specter_focus;
      }
      // Allow a slow swap to the top target if current focus died
      if ( (focus_idx < 0.000) && (specter_targets[0] != world) ) {
         specter_focus = 0.000;
         specter_last_switch = time;
         focus_idx = specter_focus;
      }
   } else if ( (specter_force_until > time) ) {
      focus_idx = specter_focus;
   } else {
      if ( (specter_targets[0] == world) ) {
         focus_idx = -1.000;
      } else {
         focus_idx = specter_focus;
         // Validate current focus
         if ( (focus_idx < 0.000) || (focus_idx >= SPECTER_MAX_CAMS) || (specter_targets[focus_idx] == world) ) {
            focus_idx = 0.000;
            specter_focus = 0.000;
            specter_last_switch = time;
         }

         // Compute focused bot drama for differential checks
         specter_focus_drama = Specter_Drama (specter_targets[focus_idx]);

         // Event-triggered switch: much more exciting bot steals focus
         if ( (time > (specter_last_switch + 1.500)) ) {
            i = 0.000;
            while ( (i < SPECTER_MAX_CAMS) ) {
               if ( (i != focus_idx) && (specter_targets[i] != world) ) {
                  if ( (specter_scores[i] > (specter_focus_drama + 5.000)) ) {
                     focus_idx = i;
                     specter_focus = focus_idx;
                     specter_last_switch = time;
                     specter_idle_since = time;
                     break;
                  }
               }
               i = (i + TRUE);
            }
         }

         // Boredom switch: idle too long, switch to highest drama
         if ( (specter_focus_drama > 2.000) ) {
            specter_idle_since = time;
         }
         if ( (time > (specter_idle_since + 5.000)) && (time > (specter_last_switch + 1.500)) ) {
            if ( (specter_targets[0] != world) && (focus_idx != 0.000) ) {
               focus_idx = 0.000;
               specter_focus = 0.000;
               specter_last_switch = time;
               specter_idle_since = time;
            }
         }
      }
   }

   // Determine view entity — Specter_ViewUpdate sends it every server frame
   if ( chase > FALSE ) {
      if ( (focus_idx >= 0.000) && specter_targets[focus_idx] ) {
         specter_view_ent = specter_targets[focus_idx];
      } else {
         specter_view_ent = specter_owner;
      }
   } else {
      if ( (focus_idx >= 0.000) && specter_cams[focus_idx] ) {
         if ( specter_targets[focus_idx] && Specter_CamInvalid (specter_cams[focus_idx], specter_targets[focus_idx]) ) {
            specter_view_ent = specter_targets[focus_idx];
         } else {
            specter_view_ent = specter_cams[focus_idx];
         }
      } else {
         specter_view_ent = specter_owner;
      }
   }
   if ( (focus_idx != specter_last_focus) ) {
      specter_last_switch = time;
      specter_last_focus = focus_idx;
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
   self.specter_prev_origin = self.origin;

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
      setmodel (cam, "progs/eyes.mdl");
      setsize (cam, '0 0 0', '0 0 0');
      cam.origin = self.origin;
      cam.angles = self.angles;
      cam.pos1 = self.origin;
      cam.pos2 = self.origin;
      cam.enemy = world;
      cam.speed = 0.500;
      cam.ltime = time;
      cam.cnt = 0.000;
      setorigin (cam, cam.origin);
      specter_cams[i] = cam;
      i = (i + TRUE);
   }
   if ( specter_cams[0] ) {
      specter_cams[0].think = Specter_Think;
      specter_cams[0].nextthink = (time + SPECTER_BASE_THINK);
   }
   specter_view_ent = specter_cams[0];
   specter_idle_since = time;
   specter_focus_drama = 0.000;
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
      setorigin (specter_owner, specter_owner.specter_prev_origin);
      specter_owner.movetype = specter_owner.specter_prev_movetype;
      specter_owner.solid = specter_owner.specter_prev_solid;
      specter_owner.takedamage = specter_owner.specter_prev_takedamage;
      specter_owner.flags = specter_owner.specter_prev_flags;
      W_SetCurrentAmmo ();
      sprint (specter_owner,"Specter Gaze: OFF\n");
   }
   specter_active = FALSE;
   specter_owner = world;
   specter_view_ent = world;
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

   local entity cam;
   local entity tgt;

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
   specter_idle_since = time;

   cam = specter_cams[specter_focus];
   tgt = specter_targets[specter_focus];

   if ( cam ) {
      // Snap camera near target to avoid stale position
      if ( tgt ) {
         cam.origin = (tgt.origin + '0 0 48');
         cam.pos1 = cam.origin;
         cam.enemy = tgt;
      }
      setorigin (cam, cam.origin);
      specter_view_ent = cam;
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
   specter_view_ent = world;
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
