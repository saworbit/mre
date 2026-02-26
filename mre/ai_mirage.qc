// ai_mirage.qc: Mirage Minds - Simplified humanization + cursed node learning

float MIRAGE_ENTROPY_MAX = 1.000;

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

void () MirageTick = {

   local float delta;

   // OPT: Use cached cvar instead of hash lookup every tick
   if ( (cached_sv_mirage <= FALSE) ) {
      return;
   }

   if ( (time < self.mirage_next_time) ) {
      return;
   }
   self.mirage_next_time = (time + 0.100);

   // Drift mood_entropy randomly based on skill
   delta = ((random () * (0.100 + (self.skil * 0.020))) - 0.050);
   self.mood_entropy = (self.mood_entropy + delta);
   if ( (self.mood_entropy < FALSE) ) {
      self.mood_entropy = FALSE;
   }
   if ( (self.mood_entropy > MIRAGE_ENTROPY_MAX) ) {
      self.mood_entropy = MIRAGE_ENTROPY_MAX;
   }

   // Dampen entropy when enemy is visible (focus up)
   if ( self.enemy && enemyvisible (self.enemy) ) {
      self.mood_entropy = (self.mood_entropy * 0.950);
   }

   // Occasional yaw jitter when entropy is high
   if ( (self.mood_entropy > 0.500) && (random () < 0.150) ) {
      self.mirage_yaw_bias = ((random () * 30.000) - 15.000) * self.mood_entropy;
      self.mirage_yaw_time = (time + 0.400);
   }

   // Pitch jitter: slight vertical drift (humans don't hold perfect pitch)
   if ( (self.mood_entropy > 0.400) && (random () < 0.120) ) {
      self.mirage_pitch_bias = ((random () * 10.000) - 5.000) * self.mood_entropy;
   } else {
      self.mirage_pitch_bias = (self.mirage_pitch_bias * 0.900);
   }

   // Glance-away: briefly look off-target (high-skill human behavior)
   if ( (self.skil >= 3.000) && self.enemy && (self.mood_entropy > 0.600) && (random () < 0.030) ) {
      self.mirage_glance_time = (time + 0.150 + (random () * 0.150));
      self.mirage_yaw_bias = ((random () * 60.000) - 30.000);
      self.mirage_yaw_time = self.mirage_glance_time;
   }

   // Occasional hold-fire feint when in combat with high entropy
   if ( (self.mood_entropy > 0.700) && self.enemy && (random () < 0.080) ) {
      self.mirage_hold_fire_time = (time + 0.200 + (random () * 0.100));
   }

};

// ============================================================================
// Cursed Nodes: Adaptive Stuck-Learning Mesh
// ============================================================================

#define CURSED_MAX 256
#define CURSED_GRID 32.000
#define CURSED_MAX_PENALTY 20.000
#define CURSED_DECAY 0.950

float cursed_count;
float cursed_decay_next;
float cursed_hash[CURSED_MAX];
float cursed_penalty[CURSED_MAX];
float cursed_time[CURSED_MAX];

float (vector pos) Cursed_NodeHash = {

   local float hx;
   local float hy;
   local float hz;
   local float h;

   hx = floor (pos_x / CURSED_GRID);
   hy = floor (pos_y / CURSED_GRID);
   hz = floor (pos_z / 64.000);
   // FIX: Distinct primes for X/Y — same multiplier caused symmetric positions to collide
   h = (hx * 37.000) + (hy * 53.000) + (hz * 17.000);
   if ( (h < 0.000) ) {
      h = -h;
   }
   return ( h );

};

float (vector pos) Cursed_Find = {

   local float i;
   local float h;

   h = Cursed_NodeHash (pos);
   i = 0.000;
   while ( i < cursed_count ) {
      if ( cursed_hash[i] == h ) {
         return ( i );
      }
      i = (i + TRUE);
   }
   return ( -1.000 );

};

void () Cursed_Reset = {

   cursed_count = 0.000;
   cursed_decay_next = FALSE;

};

void (vector pos) CurseNode = {

   local float idx;
   local float i;
   local float oldest_time;
   local float oldest_idx;

   idx = Cursed_Find (pos);
   if ( idx < FALSE ) {
      if ( cursed_count < CURSED_MAX ) {
         idx = cursed_count;
         cursed_count = (cursed_count + TRUE);
      } else {
         oldest_time = cursed_time[0];
         oldest_idx = 0.000;
         i = TRUE;
         while ( i < cursed_count ) {
            if ( cursed_time[i] < oldest_time ) {
               oldest_time = cursed_time[i];
               oldest_idx = i;
            }
            i = (i + TRUE);
         }
         idx = oldest_idx;
      }
      cursed_penalty[idx] = 0.000;
   }

   cursed_hash[idx] = Cursed_NodeHash (pos);
   cursed_penalty[idx] = (cursed_penalty[idx] + 2.000);
   if ( cursed_penalty[idx] > CURSED_MAX_PENALTY ) {
      cursed_penalty[idx] = CURSED_MAX_PENALTY;
   }
   cursed_time[idx] = time;

};

float (vector pos) GetCursePenalty = {

   local float idx;
   local float scale;

   idx = Cursed_Find (pos);
   if ( idx < FALSE ) {
      return ( 0.000 );
   }

   scale = 1.000;
   if ( self && (self.classname == "dmbot") ) {
      scale = (self.skil / 10.000);
   } else if ( skill > FALSE ) {
      scale = (skill / 10.000);
   }
   return (cursed_penalty[idx] * scale);

};

void () DecayCursed = {

   local float i;

   if ( time < cursed_decay_next ) {
      return;
   }
   cursed_decay_next = (time + 60.000);

   i = 0.000;
   while ( i < cursed_count ) {
      if ( time > (cursed_time[i] + 60.000) ) {
         cursed_penalty[i] = (cursed_penalty[i] * CURSED_DECAY);
         if ( cursed_penalty[i] < 1.000 ) {
            cursed_hash[i] = cursed_hash[cursed_count - TRUE];
            cursed_penalty[i] = cursed_penalty[cursed_count - TRUE];
            cursed_time[i] = cursed_time[cursed_count - TRUE];
            cursed_count = (cursed_count - TRUE);
            continue;
         }
      }
      i = (i + TRUE);
   }

};
