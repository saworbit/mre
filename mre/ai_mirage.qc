// ai_mirage.qc: Mirage Minds - Humanization facade

float (vector pos) BotDetectHazard;
vector (float n) chooseRoamTarget;
vector () Spectral_PickEndpoint;

float MIRAGE_ENTROPY_MAX = 1.000;
float MIRAGE_HEAT_GRID = 64.000;
float MIRAGE_HEAT_MAX = 128.000;

float PERSONA_CURIOUS = 0.000;
float PERSONA_EXPLORATORY = 1.000;
float PERSONA_CUNNING = 2.000;
float PERSONA_TACTICAL = 3.000;
float PERSONA_STRATEGIC = 4.000;

vector mirage_heat_pos[128];
float mirage_heat_val[128];
float mirage_heat_time[128];
float mirage_heat_count;
float mirage_heat_decay_next;

float () Mirage_Enabled = {
   if ( (cvar ("sv_mirage") > FALSE) ) {
      return ( TRUE );
   }
   return ( FALSE );
};

float (float base_yaw, float target_yaw, float strength) Mirage_BlendYaw = {

   local float delta;

   delta = (target_yaw - base_yaw);
   while ( delta > 180.000 ) {
      delta = (delta - 360.000);
   }
   while ( delta < -180.000 ) {
      delta = (delta + 360.000);
   }

   base_yaw = (base_yaw + (delta * strength));

   while ( base_yaw < FALSE ) {
      base_yaw = (base_yaw + 360.000);
   }
   while ( base_yaw >= 360.000 ) {
      base_yaw = (base_yaw - 360.000);
   }

   return ( base_yaw );

};

vector (vector minv, vector maxv) Mirage_RandVec = {

   local vector v;

   v_x = (minv_x + (random () * (maxv_x - minv_x)));
   v_y = (minv_y + (random () * (maxv_y - minv_y)));
   v_z = (minv_z + (random () * (maxv_z - minv_z)));

   return ( v );

};

void (vector pos, float val) Mirage_AddHeat = {

   local float i;
   local float idx;
   local float best;
   local float best_i;

   if ( (val <= FALSE) ) {
      return;
   }

   idx = -1.000;
   i = 0.000;
   while ( i < mirage_heat_count ) {
      if ( (vlen (mirage_heat_pos[i] - pos) < MIRAGE_HEAT_GRID) ) {
         idx = i;
         break;
      }
      i = (i + TRUE);
   }

   if ( idx < FALSE ) {
      if ( (mirage_heat_count < MIRAGE_HEAT_MAX) ) {
         idx = mirage_heat_count;
         mirage_heat_count = (mirage_heat_count + TRUE);
      } else {
         best = mirage_heat_val[0];
         best_i = 0.000;
         i = TRUE;
         while ( i < mirage_heat_count ) {
            if ( mirage_heat_val[i] < best ) {
               best = mirage_heat_val[i];
               best_i = i;
            }
            i = (i + TRUE);
         }
         idx = best_i;
      }
   }

   mirage_heat_pos[idx] = pos;
   mirage_heat_val[idx] = (mirage_heat_val[idx] + val);
   mirage_heat_time[idx] = time;

};

void () Mirage_HeatDecay = {

   local float i;

   if ( (time < mirage_heat_decay_next) ) {
      return;
   }
   mirage_heat_decay_next = (time + 10.000);

   i = 0.000;
   while ( i < mirage_heat_count ) {
      if ( (time > (mirage_heat_time[i] + 30.000)) ) {
         mirage_heat_val[i] = (mirage_heat_val[i] * 0.900);
      }
      if ( (mirage_heat_val[i] < 10.000) ) {
         mirage_heat_pos[i] = mirage_heat_pos[mirage_heat_count - TRUE];
         mirage_heat_val[i] = mirage_heat_val[mirage_heat_count - TRUE];
         mirage_heat_time[i] = mirage_heat_time[mirage_heat_count - TRUE];
         mirage_heat_count = (mirage_heat_count - TRUE);
      } else {
         i = (i + TRUE);
      }
   }

};

vector () Mirage_FindHotspot = {

   local float i;
   local float best;
   local vector best_pos;

   best = 0.000;
   best_pos = '0 0 0';

   i = 0.000;
   while ( i < mirage_heat_count ) {
      if ( mirage_heat_val[i] > best ) {
         best = mirage_heat_val[i];
         best_pos = mirage_heat_pos[i];
      }
      i = (i + TRUE);
   }

   return ( best_pos );

};

void (vector pos, float ttl, float safe_check) Mirage_SetGoal = {

   if ( (safe_check > FALSE) ) {
      if ( BotDetectHazard (pos) ) {
         return;
      }
   }
   self.mirage_goal = pos;
   self.mirage_goal_time = (time + ttl);

};

void (float bias, float ttl) Mirage_SetYawBias = {

   self.mirage_yaw_bias = bias;
   self.mirage_yaw_time = (time + ttl);

};

void () MirageCurious = {

   local float age;
   local vector jitter;

   if ( self.enemy && enemyvisible (self.enemy) ) {
      return;
   }

   if ( (self.heard_sound_time > FALSE) ) {
      age = (time - self.heard_sound_time);
      if ( (age < 1.500) && (random () < 0.400) ) {
         jitter = Mirage_RandVec ('-32 -32 -16', '32 32 16');
         Mirage_SetGoal ((self.heard_sound_loc + jitter), 0.600, TRUE);
         Mirage_SetYawBias (((random () * 20.000) - 10.000) * self.mood_entropy, 0.400);
      }
   }

};

void () MirageExploratory = {

   local vector offset;
   local vector roam;

   if ( self.enemy && enemyvisible (self.enemy) ) {
      return;
   }

   if ( self.goalentity && (self.goalentity != world) ) {
      if ( random () < 0.600 ) {
         offset = Mirage_RandVec ('-64 -64 -32', '64 64 32');
         offset = (offset * self.mood_entropy);
         Mirage_SetGoal ((self.goalentity.origin + offset), 0.500, FALSE);
      }
   }

   if ( (random () < 0.100) ) {
      roam = chooseRoamTarget (0.000);
      Mirage_SetGoal (roam, 0.700, TRUE);
   }

};

void () MirageCunning = {

   local float dist;
   local vector dir;
   local vector cand;
   local vector probe;

   if ( self.enemy && enemyvisible (self.enemy) ) {
      dist = vlen (self.enemy.origin - self.origin);
      if ( (dist < 450.000) ) {
         dir = normalize (self.origin - self.enemy.origin);
         if ( (vlen (dir) < 0.100) ) {
            dir = '1 0 0';
         }
         Mirage_SetGoal ((self.origin + (dir * (80.000 + (random () * 80.000)))), 0.350, FALSE);
         Mirage_SetYawBias (((random () * 40.000) - 20.000) * (0.500 + self.mood_entropy), 0.500);
         if ( (random () < 0.350) ) {
            self.mirage_hold_fire_time = (time + 0.250);
         }
      }
   }

   if ( self.enemy && (self.health < 50.000) ) {
      dir = normalize (self.origin - self.enemy.origin);
      cand = (self.origin + (dir * 120.000));
      probe = cand;
      probe_z = (probe_z - 48.000);
      traceline (cand, probe, TRUE, self);
      if ( (trace_fraction < TRUE) ) {
         traceline ((self.enemy.origin + self.enemy.view_ofs), cand, TRUE, self.enemy);
         if ( (trace_fraction < 0.900) ) {
            Mirage_SetGoal (cand, 0.600, TRUE);
         }
      }
   }

};

void () MirageTactical = {

   local vector hot;

   if ( self.enemy && enemyvisible (self.enemy) ) {
      return;
   }

   if ( mirage_heat_count > 0.000 ) {
      hot = Mirage_FindHotspot ();
      if ( (random () < 0.500) ) {
         Mirage_SetGoal (hot, 0.800, TRUE);
      }
   }

};

void () MirageStrategic = {

   local vector epi;
   local vector jitter;

   if ( (random () < 0.300) ) {
      epi = Spectral_PickEndpoint ();
      if ( (epi != '0 0 0') ) {
         jitter = Mirage_RandVec ('-32 -32 -16', '32 32 16');
         Mirage_SetGoal ((epi + jitter), 0.900, TRUE);
         Mirage_SetYawBias (((random () * 30.000) - 15.000) * self.mood_entropy, 0.500);
      }
   }

   if ( (self.heard_sound_time > FALSE) ) {
      if ( (time - self.heard_sound_time) < 1.000 ) {
         self.mood_entropy = (self.mood_entropy + 0.100);
         if ( (self.mood_entropy > MIRAGE_ENTROPY_MAX) ) {
            self.mood_entropy = MIRAGE_ENTROPY_MAX;
         }
      }
   }

};

void () MirageTick = {

   local float delta;

   if ( !Mirage_Enabled () ) {
      return;
   }

   if ( (time < self.mirage_next_time) ) {
      return;
   }
   self.mirage_next_time = (time + 0.100);

   Mirage_HeatDecay ();

   delta = ((random () * (0.100 + (self.skil * 0.020))) - 0.050);
   self.mood_entropy = (self.mood_entropy + delta);
   if ( (self.mood_entropy < FALSE) ) {
      self.mood_entropy = FALSE;
   }
   if ( (self.mood_entropy > MIRAGE_ENTROPY_MAX) ) {
      self.mood_entropy = MIRAGE_ENTROPY_MAX;
   }

   if ( self.enemy && enemyvisible (self.enemy) ) {
      self.mood_entropy = (self.mood_entropy * 0.950);
   }

   if ( time > self.mirage_persona_time ) {
      if ( (self.mood_entropy > 0.700) && (random () < 0.250) ) {
         self.persona_state = (self.persona_state + TRUE);
      } else if ( (self.mood_entropy < 0.300) && (random () < 0.300) ) {
         self.persona_state = PERSONA_TACTICAL;
      }
      if ( (self.persona_state > PERSONA_STRATEGIC) ) {
         self.persona_state = PERSONA_CURIOUS;
      }
      self.mirage_persona_time = (time + 0.800 + (random () * 0.400));
   }

   if ( self.persona_state == PERSONA_CURIOUS ) {
      MirageCurious ();
   } else if ( self.persona_state == PERSONA_EXPLORATORY ) {
      MirageExploratory ();
   } else if ( self.persona_state == PERSONA_CUNNING ) {
      MirageCunning ();
   } else if ( self.persona_state == PERSONA_TACTICAL ) {
      MirageTactical ();
   } else {
      MirageStrategic ();
   }

   if ( cvar("mirage_debug") && cvar("developer") ) {
      if ( random () < 0.050 ) {
         dprint ("[");
         dprint (self.netname);
         dprint ("] MIRAGE: persona=");
         dprint (ftos(self.persona_state));
         dprint (" entropy=");
         dprint (ftos(self.mood_entropy));
         dprint ("\n");
      }
   }

};
