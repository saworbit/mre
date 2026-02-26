// Shadow Puppets: Predictive rollout beam search for movement steering
// Lightweight lookahead to reduce hazards and dead-ends

float (vector pos) Spectral_AllureBias;
float (vector pos) GetCursePenalty;

float SHADOW_MAX_DEPTH = 12.000;
float SHADOW_MAX_BEAM = 5.000;
float SHADOW_DT = 0.100;
float SHADOW_GRAVITY = 80.000;   // Approx 800 * 0.1s
float SHADOW_NEG = -999999.000;

// Combat Crucible (dual-rollout)
#ifdef QS_V6
#define SHADOW_COMBAT_BEAM_MAX 12
#else
#define SHADOW_COMBAT_BEAM_MAX 20
#endif
#define USER_HASH_SCALE 32
float SHADOW_COMBAT_MAX_DEPTH = 15.000;
float SHADOW_COMBAT_MAX_BEAM = SHADOW_COMBAT_BEAM_MAX;
float SHADOW_COMBAT_NEG = -999999.000;

// Silent Specters: stealthy unstuck rollouts
#define SILENT_UNSTUCK_DEPTH 4
#define SILENT_UNSTUCK_BEAM 3
#define SILENT_VISIT_HASH 256
float SILENT_NOISE_PENALTY = 200.000;

float silent_visit[SILENT_VISIT_HASH];
vector su_pos[SILENT_UNSTUCK_BEAM];
vector su_vel[SILENT_UNSTUCK_BEAM];
float su_air[SILENT_UNSTUCK_BEAM];
float su_reward[SILENT_UNSTUCK_BEAM];
float su_count;

vector su_next_pos[SILENT_UNSTUCK_BEAM];
vector su_next_vel[SILENT_UNSTUCK_BEAM];
float su_next_air[SILENT_UNSTUCK_BEAM];
float su_next_reward[SILENT_UNSTUCK_BEAM];
float su_next_count;

// Slayer Eclipse: user pattern hashing + god mode toggle
float (entity foe) Slayer_IsUser = {

   if ( !foe ) {
      return ( FALSE );
   }
   if ( (foe.classname != "player") ) {
      return ( FALSE );
   }
   return ( TRUE );

};

float (float v) Slayer_WrapUserIndex = {

   local float wrap;
   wrap = floor (v / USER_HASH_SCALE);
   return (v - (wrap * USER_HASH_SCALE));

};

float (entity foe) Slayer_UserHash = {

   local float hx;
   local float hy;
   local float h;

   if ( !foe ) {
      return ( FALSE );
   }
   hx = floor (foe.origin_x / 32.000);
   hy = floor (foe.origin_y / 32.000);
   h = (hx * 37.000) + (hy * 57.000);
   if ( (h < 0.000) ) {
      h = -h;
   }
   return Slayer_WrapUserIndex (h);

};

float (entity foe) Slayer_UserBias = {

   local float h;
   local float bias;

   if ( (cvar ("user_learn") <= FALSE) ) {
      return ( FALSE );
   }
   if ( !Slayer_IsUser (foe) ) {
      return ( FALSE );
   }
   h = Slayer_UserHash (foe);
   if ( (h < FALSE) || (h >= USER_HASH_SCALE) ) {
      return ( FALSE );
   }
   bias = user_strafe_bias[h];
   if ( (bias > 1.000) ) bias = 1.000;
   if ( (bias < -1.000) ) bias = -1.000;
   return ( bias );

};

float () Slayer_GodMode = {

   if ( (cvar ("sv_slayer_god") > FALSE) ) {
      return ( TRUE );
   }
   if ( (self.skil >= 10.000) ) {
      return ( TRUE );
   }
   return ( FALSE );

};

// Current beam states
vector sp_c_pos1; vector sp_c_vel1; float sp_c_air1; float sp_c_reward1; float sp_c_action1;
vector sp_c_pos2; vector sp_c_vel2; float sp_c_air2; float sp_c_reward2; float sp_c_action2;
vector sp_c_pos3; vector sp_c_vel3; float sp_c_air3; float sp_c_reward3; float sp_c_action3;
vector sp_c_pos4; vector sp_c_vel4; float sp_c_air4; float sp_c_reward4; float sp_c_action4;
vector sp_c_pos5; vector sp_c_vel5; float sp_c_air5; float sp_c_reward5; float sp_c_action5;

// Next beam states
vector sp_n_pos1; vector sp_n_vel1; float sp_n_air1; float sp_n_reward1; float sp_n_action1;
vector sp_n_pos2; vector sp_n_vel2; float sp_n_air2; float sp_n_reward2; float sp_n_action2;
vector sp_n_pos3; vector sp_n_vel3; float sp_n_air3; float sp_n_reward3; float sp_n_action3;
vector sp_n_pos4; vector sp_n_vel4; float sp_n_air4; float sp_n_reward4; float sp_n_action4;
vector sp_n_pos5; vector sp_n_vel5; float sp_n_air5; float sp_n_reward5; float sp_n_action5;

// Candidate temp
vector sp_tmp_pos; vector sp_tmp_vel; float sp_tmp_air; float sp_tmp_reward; float sp_tmp_action;

// Sim outputs
vector sp_out_pos; vector sp_out_vel; float sp_out_air; float sp_out_blocked;
float sp_out_onlift;
float sp_out_lift_velz;

// Combat beams (bot + enemy)
vector cb_bpos[SHADOW_COMBAT_BEAM_MAX];
vector cb_bvel[SHADOW_COMBAT_BEAM_MAX];
float cb_bair[SHADOW_COMBAT_BEAM_MAX];
float cb_bhp[SHADOW_COMBAT_BEAM_MAX];
float cb_bammo[SHADOW_COMBAT_BEAM_MAX];
float cb_reward[SHADOW_COMBAT_BEAM_MAX];
float cb_action[SHADOW_COMBAT_BEAM_MAX];

vector cb_epos[SHADOW_COMBAT_BEAM_MAX];
vector cb_evel[SHADOW_COMBAT_BEAM_MAX];
float cb_eair[SHADOW_COMBAT_BEAM_MAX];
float cb_ehp[SHADOW_COMBAT_BEAM_MAX];
float cb_eammo[SHADOW_COMBAT_BEAM_MAX];

vector cbn_bpos[SHADOW_COMBAT_BEAM_MAX];
vector cbn_bvel[SHADOW_COMBAT_BEAM_MAX];
float cbn_bair[SHADOW_COMBAT_BEAM_MAX];
float cbn_bhp[SHADOW_COMBAT_BEAM_MAX];
float cbn_bammo[SHADOW_COMBAT_BEAM_MAX];
float cbn_reward[SHADOW_COMBAT_BEAM_MAX];
float cbn_action[SHADOW_COMBAT_BEAM_MAX];

vector cbn_epos[SHADOW_COMBAT_BEAM_MAX];
vector cbn_evel[SHADOW_COMBAT_BEAM_MAX];
float cbn_eair[SHADOW_COMBAT_BEAM_MAX];
float cbn_ehp[SHADOW_COMBAT_BEAM_MAX];
float cbn_eammo[SHADOW_COMBAT_BEAM_MAX];

vector cb_tmp_bpos; vector cb_tmp_bvel; float cb_tmp_bair; float cb_tmp_bhp; float cb_tmp_bammo;
vector cb_tmp_epos; vector cb_tmp_evel; float cb_tmp_eair; float cb_tmp_ehp; float cb_tmp_eammo;
float cb_tmp_reward; float cb_tmp_action;

vector cb_out_bpos; vector cb_out_bvel; float cb_out_bair; float cb_out_bhp; float cb_out_bammo;
vector cb_out_epos; vector cb_out_evel; float cb_out_eair; float cb_out_ehp; float cb_out_eammo;
float cb_out_blocked;

float cb_start_bhp;
float cb_start_ehp;
float cb_best_action;

void () ShadowResetNext = {

   sp_n_reward1 = SHADOW_NEG; sp_n_action1 = -1.000;
   sp_n_reward2 = SHADOW_NEG; sp_n_action2 = -1.000;
   sp_n_reward3 = SHADOW_NEG; sp_n_action3 = -1.000;
   sp_n_reward4 = SHADOW_NEG; sp_n_action4 = -1.000;
   sp_n_reward5 = SHADOW_NEG; sp_n_action5 = -1.000;

};

void () ShadowPromoteNext = {

   sp_c_pos1 = sp_n_pos1; sp_c_vel1 = sp_n_vel1; sp_c_air1 = sp_n_air1; sp_c_reward1 = sp_n_reward1; sp_c_action1 = sp_n_action1;
   sp_c_pos2 = sp_n_pos2; sp_c_vel2 = sp_n_vel2; sp_c_air2 = sp_n_air2; sp_c_reward2 = sp_n_reward2; sp_c_action2 = sp_n_action2;
   sp_c_pos3 = sp_n_pos3; sp_c_vel3 = sp_n_vel3; sp_c_air3 = sp_n_air3; sp_c_reward3 = sp_n_reward3; sp_c_action3 = sp_n_action3;
   sp_c_pos4 = sp_n_pos4; sp_c_vel4 = sp_n_vel4; sp_c_air4 = sp_n_air4; sp_c_reward4 = sp_n_reward4; sp_c_action4 = sp_n_action4;
   sp_c_pos5 = sp_n_pos5; sp_c_vel5 = sp_n_vel5; sp_c_air5 = sp_n_air5; sp_c_reward5 = sp_n_reward5; sp_c_action5 = sp_n_action5;

};

void () ShadowConsiderCandidate = {

   if ( (sp_tmp_reward > sp_n_reward1) ) {

      sp_n_pos5 = sp_n_pos4; sp_n_vel5 = sp_n_vel4; sp_n_air5 = sp_n_air4; sp_n_reward5 = sp_n_reward4; sp_n_action5 = sp_n_action4;
      sp_n_pos4 = sp_n_pos3; sp_n_vel4 = sp_n_vel3; sp_n_air4 = sp_n_air3; sp_n_reward4 = sp_n_reward3; sp_n_action4 = sp_n_action3;
      sp_n_pos3 = sp_n_pos2; sp_n_vel3 = sp_n_vel2; sp_n_air3 = sp_n_air2; sp_n_reward3 = sp_n_reward2; sp_n_action3 = sp_n_action2;
      sp_n_pos2 = sp_n_pos1; sp_n_vel2 = sp_n_vel1; sp_n_air2 = sp_n_air1; sp_n_reward2 = sp_n_reward1; sp_n_action2 = sp_n_action1;

      sp_n_pos1 = sp_tmp_pos; sp_n_vel1 = sp_tmp_vel; sp_n_air1 = sp_tmp_air; sp_n_reward1 = sp_tmp_reward; sp_n_action1 = sp_tmp_action;
      return;

   }
   if ( (sp_tmp_reward > sp_n_reward2) ) {

      sp_n_pos5 = sp_n_pos4; sp_n_vel5 = sp_n_vel4; sp_n_air5 = sp_n_air4; sp_n_reward5 = sp_n_reward4; sp_n_action5 = sp_n_action4;
      sp_n_pos4 = sp_n_pos3; sp_n_vel4 = sp_n_vel3; sp_n_air4 = sp_n_air3; sp_n_reward4 = sp_n_reward3; sp_n_action4 = sp_n_action3;
      sp_n_pos3 = sp_n_pos2; sp_n_vel3 = sp_n_vel2; sp_n_air3 = sp_n_air2; sp_n_reward3 = sp_n_reward2; sp_n_action3 = sp_n_action2;

      sp_n_pos2 = sp_tmp_pos; sp_n_vel2 = sp_tmp_vel; sp_n_air2 = sp_tmp_air; sp_n_reward2 = sp_tmp_reward; sp_n_action2 = sp_tmp_action;
      return;

   }
   if ( (sp_tmp_reward > sp_n_reward3) ) {

      sp_n_pos5 = sp_n_pos4; sp_n_vel5 = sp_n_vel4; sp_n_air5 = sp_n_air4; sp_n_reward5 = sp_n_reward4; sp_n_action5 = sp_n_action4;
      sp_n_pos4 = sp_n_pos3; sp_n_vel4 = sp_n_vel3; sp_n_air4 = sp_n_air3; sp_n_reward4 = sp_n_reward3; sp_n_action4 = sp_n_action3;

      sp_n_pos3 = sp_tmp_pos; sp_n_vel3 = sp_tmp_vel; sp_n_air3 = sp_tmp_air; sp_n_reward3 = sp_tmp_reward; sp_n_action3 = sp_tmp_action;
      return;

   }
   if ( (sp_tmp_reward > sp_n_reward4) ) {

      sp_n_pos5 = sp_n_pos4; sp_n_vel5 = sp_n_vel4; sp_n_air5 = sp_n_air4; sp_n_reward5 = sp_n_reward4; sp_n_action5 = sp_n_action4;

      sp_n_pos4 = sp_tmp_pos; sp_n_vel4 = sp_tmp_vel; sp_n_air4 = sp_tmp_air; sp_n_reward4 = sp_tmp_reward; sp_n_action4 = sp_tmp_action;
      return;

   }
   if ( (sp_tmp_reward > sp_n_reward5) ) {

      sp_n_pos5 = sp_tmp_pos; sp_n_vel5 = sp_tmp_vel; sp_n_air5 = sp_tmp_air; sp_n_reward5 = sp_tmp_reward; sp_n_action5 = sp_tmp_action;
      return;

   }

};

void (vector pos, vector vel, float air_left, float action_id, vector fwd, vector right, float use_trace) ShadowSimStep = {

   local vector delta;
   local vector newpos;
   local float contents;
   local entity lift;

   delta = '0.000 0.000 0.000';
   if ( (action_id == 0.000) ) {
      delta = (fwd * 400.000);
   } else if ( (action_id == 1.000) ) {
      delta = (right * -300.000);
   } else if ( (action_id == 2.000) ) {
      delta = (right * 300.000);
   } else if ( (action_id == 3.000) ) {
      delta = (fwd * -200.000);
   } else if ( (action_id == 4.000) ) {
      delta = (fwd * 400.000);
      vel_z = (vel_z + 270.000);
   } else if ( (action_id == 5.000) ) {
      delta = ((right * -300.000) + (fwd * 200.000));
      vel_z = (vel_z + 270.000);
   } else if ( (action_id == 6.000) ) {
      delta = ((right * 300.000) + (fwd * 200.000));
      vel_z = (vel_z + 270.000);
   } else if ( (action_id == 7.000) ) {
      delta = (fwd * 300.000);
   }

   // Basic accel + gravity
   vel = (vel * 0.90) + (delta * 0.10);
   vel_z = (vel_z - SHADOW_GRAVITY);

   newpos = (pos + (vel * SHADOW_DT));
   sp_out_blocked = FALSE;

   if ( (use_trace > FALSE) ) {
      traceline ((pos + '0.000 0.000 16.000'), (newpos + '0.000 0.000 16.000'), TRUE, self);
      if ( (trace_fraction < TRUE) ) {
         newpos = (trace_endpos - '0.000 0.000 16.000');
         vel = '0.000 0.000 0.000';
         sp_out_blocked = TRUE;
      }
   }

   contents = pointcontents (newpos);
   if ( (contents == CONTENT_WATER) ) {
      air_left = (air_left - SHADOW_DT);
      if ( (air_left < FALSE) ) {
         air_left = FALSE;
      }
      vel = (vel * 0.800);
   } else {
      air_left = 12.000;
   }

   sp_out_onlift = FALSE;
   sp_out_lift_velz = 0.000;
   traceline ((newpos + '0.000 0.000 16.000'), (newpos - '0.000 0.000 64.000'), TRUE, self);
   lift = trace_ent;
   if ( lift && ((lift.classname == "func_plat") || (lift.classname == "plat") || (lift.classname == "func_train") || (lift.classname == "train")) ) {
      vel = lift.velocity + (normalize (lift.origin - newpos) * 80.000);
      sp_out_onlift = TRUE;
      sp_out_lift_velz = lift.velocity_z;
   }

   sp_out_pos = newpos;
   sp_out_vel = vel;
   sp_out_air = air_left;

};

float (vector pos, vector vel, float air_left, vector goal_pos, float use_trace, float blocked, float hazard_bias, float water_bias) ShadowReward = {

   local float dist;
   local float r;
   local float contents;

   dist = vlen ((goal_pos - pos));
   r = (1000.000 / (dist + 1.000));

   // Collision penalty
   if ( blocked ) {
      r = (r - (1200.000 * hazard_bias));
   }

   contents = pointcontents (pos);
   if ( (contents == CONTENT_LAVA) ) {
      r = (r - (5000.000 * hazard_bias));
   } else if ( (contents == CONTENT_SLIME) ) {
      r = (r - (3500.000 * hazard_bias));
   } else if ( (contents == CONTENT_WATER) ) {
      if ( (air_left < 3.000) ) {
         r = (r - (600.000 * water_bias));
      } else {
         r = (r - (100.000 * water_bias));
      }
   }

   if ( (use_trace > FALSE) ) {
      traceline (pos, (pos - '0.000 0.000 96.000'), TRUE, self);
      if ( (trace_fraction == TRUE) ) {
         // Cliff/void
         r = (r - (1200.000 * hazard_bias));
      } else if ( (trace_plane_normal_z < 0.700) ) {
         // Steep drop or ledge
         r = (r - (500.000 * hazard_bias));
      } else {
         contents = pointcontents (trace_endpos);
         if ( (contents == CONTENT_LAVA) || (contents == CONTENT_SLIME) ) {
            r = (r - (5000.000 * hazard_bias));
         }
      }
   }

   // Spectral learning bias
   r = (r + Spectral_AllureBias (pos));

   // Cursed nodes: repel known stuck spots
   r = (r - (GetCursePenalty (pos) * 50.000));

   // Stagnation penalty
   if ( (vlen (vel) < 60.000) ) {
      r = (r - 200.000);
   }

   if ( sp_out_onlift ) {
      if ( sp_out_lift_velz > 1.000 ) {
         r = (r + 200.000);
      } else if ( sp_out_lift_velz < -1.000 ) {
         r = (r - 50.000);
      } else {
         r = (r + 100.000);
      }
   }

   return ( r );

};

float (vector pos, vector vel, float air_left, vector goal_pos, vector fwd, vector right, float use_trace) ShadowLookaheadReward = {

   local float tr_allsolid;
   local float tr_startsolid;
   local float tr_fraction;
   local vector tr_endpos;
   local vector tr_plane_normal;
   local float tr_plane_dist;
   local entity tr_ent;
   local float tr_inopen;
   local float tr_inwater;
   local float reward;

   tr_allsolid = trace_allsolid;
   tr_startsolid = trace_startsolid;
   tr_fraction = trace_fraction;
   tr_endpos = trace_endpos;
   tr_plane_normal = trace_plane_normal;
   tr_plane_dist = trace_plane_dist;
   tr_ent = trace_ent;
   tr_inopen = trace_inopen;
   tr_inwater = trace_inwater;

   ShadowSimStep (pos, vel, air_left, 0.000, fwd, right, use_trace);
   reward = ShadowReward (sp_out_pos, sp_out_vel, sp_out_air, goal_pos, use_trace, sp_out_blocked, 1.000, 1.000);

   trace_allsolid = tr_allsolid;
   trace_startsolid = tr_startsolid;
   trace_fraction = tr_fraction;
   trace_endpos = tr_endpos;
   trace_plane_normal = tr_plane_normal;
   trace_plane_dist = tr_plane_dist;
   trace_ent = tr_ent;
   trace_inopen = tr_inopen;
   trace_inwater = tr_inwater;

   return ( reward );

};

float () EnemiesNear = {

   local entity scan;
   local float dist;

   // OPT: Walk bot linked list instead of findradius (avoids full entity scan)
   scan = bot_list_head;
   while ( scan ) {
      if ( (scan != self) && (scan.health > 0.000) ) {
         dist = vlen (scan.origin - self.origin);
         if ( dist < 800 && visible (scan) ) {
            return ( TRUE );
         }
      }
      scan = scan.bot_next;
   }
   // Also check human players
   scan = find (world, classname, "player");
   while ( scan ) {
      if ( (scan != self) && (scan.health > 0.000) ) {
         dist = vlen (scan.origin - self.origin);
         if ( dist < 800 && visible (scan) ) {
            return ( TRUE );
         }
      }
      scan = find (scan, classname, "player");
   }
   return ( FALSE );

};

float (float v) Silent_WrapIndex = {

   local float wrap;
   wrap = floor (v / SILENT_VISIT_HASH);
   return (v - (wrap * SILENT_VISIT_HASH));

};

float (vector v) Silent_HashVec = {

   local float hx;
   local float hy;
   local float hz;
   local float h;

   hx = floor (v_x / 32.000);
   hy = floor (v_y / 32.000);
   hz = floor (v_z / 32.000);
   h = (hx * 37.000) + (hy * 57.000) + (hz * 17.000);
   if ( (h < 0.000) ) {
      h = -h;
   }
   return Silent_WrapIndex (h);

};

void () Silent_ResetNext = {

   local float i;

   i = 0.000;
   while ( i < SILENT_UNSTUCK_BEAM ) {
      su_next_reward[i] = SHADOW_NEG;
      i = (i + TRUE);
   }
   su_next_count = 0.000;

};

void (vector pos, vector vel, float air, float reward, float beam_w) Silent_ConsiderCandidate = {

   local float i;
   local float j;
   local float last;

   last = (beam_w - TRUE);
   if ( (su_next_count >= beam_w) && (reward <= su_next_reward[last]) ) {
      return ;
   }

   i = 0.000;
   while ( i < beam_w ) {
      if ( (reward > su_next_reward[i]) ) {
         j = last;
         while ( j > i ) {
            su_next_pos[j] = su_next_pos[j - TRUE];
            su_next_vel[j] = su_next_vel[j - TRUE];
            su_next_air[j] = su_next_air[j - TRUE];
            su_next_reward[j] = su_next_reward[j - TRUE];
            j = (j - TRUE);
         }
         su_next_pos[i] = pos;
         su_next_vel[i] = vel;
         su_next_air[i] = air;
         su_next_reward[i] = reward;
         if ( (su_next_count < beam_w) ) {
            su_next_count = (su_next_count + TRUE);
         }
         return ;
      }
      i = (i + TRUE);
   }

   if ( (su_next_count < beam_w) ) {
      su_next_pos[su_next_count] = pos;
      su_next_vel[su_next_count] = vel;
      su_next_air[su_next_count] = air;
      su_next_reward[su_next_count] = reward;
      su_next_count = (su_next_count + TRUE);
   }

};

vector () SilentUnstuck = {

   local float d;
   local float b;
   local float a;
   local float reward;
   local float hash;
   local float air_left;
   local float quiet_penalty;
   local float use_trace;
   local float escape_bias;
   local vector fwd;
   local vector rgt;
   local vector goal_pos;
   local vector escape;
   local float tr_allsolid;
   local float tr_startsolid;
   local float tr_fraction;
   local vector tr_endpos;
   local vector tr_plane_normal;
   local float tr_plane_dist;
   local entity tr_ent;
   local float tr_inopen;
   local float tr_inwater;

   if ( (self.deadflag != DEAD_NO) ) {
      return '0 0 0';
   }

   makevectors (self.angles);
   fwd = v_forward;
   rgt = v_right;

   // Air time left (seconds)
   air_left = (self.air_finished - time);
   if ( (air_left < FALSE) ) {
      air_left = FALSE;
   }
   if ( (air_left > 12.000) ) {
      air_left = 12.000;
   }

   goal_pos = self.oldorigin;
   if ( (vlen (goal_pos - self.origin) < 1.000) ) {
      goal_pos = (self.origin - (fwd * 64.000));
   }

   escape_bias = vlen (self.origin - self.oldorigin);
   if ( (escape_bias < 1.000) ) {
      escape_bias = 1.000;
   }

   quiet_penalty = FALSE;
   if ( EnemiesNear () ) {
      quiet_penalty = SILENT_NOISE_PENALTY;
   }

   su_pos[0] = self.origin;
   su_vel[0] = self.velocity;
   su_air[0] = air_left;
   su_reward[0] = ((100.000 / escape_bias) + TRUE);
   su_count = TRUE;

   tr_allsolid = trace_allsolid;
   tr_startsolid = trace_startsolid;
   tr_fraction = trace_fraction;
   tr_endpos = trace_endpos;
   tr_plane_normal = trace_plane_normal;
   tr_plane_dist = trace_plane_dist;
   tr_ent = trace_ent;
   tr_inopen = trace_inopen;
   tr_inwater = trace_inwater;

   d = TRUE;
   while ( d <= SILENT_UNSTUCK_DEPTH ) {
      Silent_ResetNext ();
      b = 0.000;
      while ( b < su_count ) {
         hash = Silent_HashVec (su_pos[b]);
         if ( (silent_visit[hash] > (time - 0.500)) ) {
            b = (b + TRUE);
            continue ;
         }
         silent_visit[hash] = time;

         a = 0.000;
         while ( a < 8.000 ) {
            use_trace = (d == TRUE);
            ShadowSimStep (su_pos[b], su_vel[b], su_air[b], a, fwd, rgt, use_trace);
            reward = ShadowReward (sp_out_pos, sp_out_vel, sp_out_air, goal_pos, use_trace, sp_out_blocked, 1.000, 1.000);
            if ( (a >= 4.000) ) {
               reward = (reward - quiet_penalty);
            }
            Silent_ConsiderCandidate (sp_out_pos, sp_out_vel, sp_out_air, reward, SILENT_UNSTUCK_BEAM);
            a = (a + TRUE);
         }
         b = (b + TRUE);
      }

      su_count = su_next_count;
      if ( (su_count <= FALSE) ) {
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
         return '0 0 0';
      }
      b = 0.000;
      while ( b < su_count ) {
         su_pos[b] = su_next_pos[b];
         su_vel[b] = su_next_vel[b];
         su_air[b] = su_next_air[b];
         su_reward[b] = su_next_reward[b];
         b = (b + TRUE);
      }
      d = (d + TRUE);
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

   escape = su_vel[0];
   if ( (vlen (escape) < 1.000) ) {
      return '0 0 0';
   }
   return (normalize (escape) * 300.000);

};

// Returns suggested yaw or 9999 if unused
float (vector goal_pos, float dist) BotShadowPuppetYaw = {

   local float depth;
   local float beam_w;
   local float throttle;
   local float a;
   local float d;
   local float debug;
   local float depth_override;
   local float beam_override;
   local float hazard_bias;
   local float water_bias;
   local vector ang;
   local vector fwd;
   local vector right;
   local float air_left;
   local vector dir;
   local float best_action;
   local float tr_allsolid;
   local float tr_startsolid;
   local float tr_fraction;
   local vector tr_endpos;
   local vector tr_plane_normal;
   local float tr_plane_dist;
   local entity tr_ent;
   local float tr_inopen;
   local float tr_inwater;

   // Fast exits
   if ( (cvar ("sv_shadow_nav") <= FALSE) ) {
      return ( 9999.000 );
   }
   if ( (self.deadflag != DEAD_NO) ) {
      return ( 9999.000 );
   }
   if ( !self.goalentity || (self.goalentity == world) ) {
      return ( 9999.000 );
   }
   if ( (dist < 32.000) ) {
      return ( 9999.000 );
   }

   // Throttle (nav-only)
   throttle = cvar ("shadow_throttle");
   if ( (throttle <= FALSE) ) {
      if ( Slayer_GodMode () ) {
         throttle = 0.330;
      } else {
         throttle = (0.200 - (self.skil * 0.010));
         if ( (throttle < 0.100) ) {
            throttle = 0.100;
         }
      }
   } else {
      if ( (throttle < 0.050) ) {
         throttle = 0.050;
      }
   }
   if ( ((self.nav_predict_time + throttle) > time) ) {
      return ( 9999.000 );
   }
   self.nav_predict_time = time;

   debug = cvar ("shadow_nav_debug");
   if ( (cvar ("shadow_debug") > FALSE) ) {
      debug = TRUE;
   }
   depth_override = cvar ("shadow_nav_depth");
   beam_override = cvar ("shadow_nav_beam");
   hazard_bias = cvar ("shadow_nav_hazard_bias");
   water_bias = cvar ("shadow_nav_water_bias");
   if ( (hazard_bias == FALSE) ) hazard_bias = TRUE;
   if ( (water_bias == FALSE) ) water_bias = TRUE;

   // Beam and depth scaling
   if ( (self.shadow_depth > FALSE) ) {
      depth = self.shadow_depth;
   } else {
      depth = (6.000 + floor (self.skil));
   }
   if ( (depth > SHADOW_MAX_DEPTH) ) {
      depth = SHADOW_MAX_DEPTH;
   }
   if ( (depth < 6.000) ) {
      depth = 6.000;
   }

   if ( (self.shadow_beam > FALSE) ) {
      beam_w = self.shadow_beam;
   } else {
      beam_w = (3.000 + floor (self.skil * 0.200));
   }
   if ( (beam_w > SHADOW_MAX_BEAM) ) {
      beam_w = SHADOW_MAX_BEAM;
   }
   if ( (beam_w < 3.000) ) {
      beam_w = 3.000;
   }
   if ( (depth_override > FALSE) ) {
      depth = depth_override;
      if ( (depth > SHADOW_MAX_DEPTH) ) depth = SHADOW_MAX_DEPTH;
      if ( (depth < 2.000) ) depth = 2.000;
   }
   if ( (beam_override > FALSE) ) {
      beam_w = beam_override;
      if ( (beam_w > SHADOW_MAX_BEAM) ) beam_w = SHADOW_MAX_BEAM;
      if ( (beam_w < 1.000) ) beam_w = 1.000;
   }

   // Direction basis toward goal
   ang = '0.000 0.000 0.000';
   ang_y = vectoyaw ((goal_pos - self.origin));
   makevectors (ang);
   fwd = v_forward;
   right = v_right;

   // Air time left (seconds)
   air_left = (self.air_finished - time);
   if ( (air_left < FALSE) ) {
      air_left = FALSE;
   }
   if ( (air_left > 12.000) ) {
      air_left = 12.000;
   }

   tr_allsolid = trace_allsolid;
   tr_startsolid = trace_startsolid;
   tr_fraction = trace_fraction;
   tr_endpos = trace_endpos;
   tr_plane_normal = trace_plane_normal;
   tr_plane_dist = trace_plane_dist;
   tr_ent = trace_ent;
   tr_inopen = trace_inopen;
   tr_inwater = trace_inwater;

   // Depth 1: expand all actions with collision + hazard trace
   ShadowResetNext ();
   a = 0.000;
   while ( (a < 8.000) ) {

      ShadowSimStep (self.origin, self.velocity, air_left, a, fwd, right, TRUE);
      sp_tmp_pos = sp_out_pos;
      sp_tmp_vel = sp_out_vel;
      sp_tmp_air = sp_out_air;
      sp_tmp_reward = ShadowReward (sp_out_pos, sp_out_vel, sp_out_air, goal_pos, TRUE, sp_out_blocked, hazard_bias, water_bias);
      sp_tmp_action = a;
      ShadowConsiderCandidate ();
      a = (a + 1.000);

   }
   ShadowPromoteNext ();

   d = 2.000;
   while ( (d <= depth) ) {

      ShadowResetNext ();

      if ( (beam_w >= 1.000) && (sp_c_reward1 > SHADOW_NEG) ) {
         a = 0.000;
         while ( (a < 8.000) ) {
            ShadowSimStep (sp_c_pos1, sp_c_vel1, sp_c_air1, a, fwd, right, FALSE);
            sp_tmp_pos = sp_out_pos;
            sp_tmp_vel = sp_out_vel;
            sp_tmp_air = sp_out_air;
            sp_tmp_reward = (sp_c_reward1 + ShadowReward (sp_out_pos, sp_out_vel, sp_out_air, goal_pos, FALSE, FALSE, hazard_bias, water_bias));
            sp_tmp_action = sp_c_action1;
            ShadowConsiderCandidate ();
            a = (a + 1.000);
         }
      }
      if ( (beam_w >= 2.000) && (sp_c_reward2 > SHADOW_NEG) ) {
         a = 0.000;
         while ( (a < 8.000) ) {
            ShadowSimStep (sp_c_pos2, sp_c_vel2, sp_c_air2, a, fwd, right, FALSE);
            sp_tmp_pos = sp_out_pos;
            sp_tmp_vel = sp_out_vel;
            sp_tmp_air = sp_out_air;
            sp_tmp_reward = (sp_c_reward2 + ShadowReward (sp_out_pos, sp_out_vel, sp_out_air, goal_pos, FALSE, FALSE, hazard_bias, water_bias));
            sp_tmp_action = sp_c_action2;
            ShadowConsiderCandidate ();
            a = (a + 1.000);
         }
      }
      if ( (beam_w >= 3.000) && (sp_c_reward3 > SHADOW_NEG) ) {
         a = 0.000;
         while ( (a < 8.000) ) {
            ShadowSimStep (sp_c_pos3, sp_c_vel3, sp_c_air3, a, fwd, right, FALSE);
            sp_tmp_pos = sp_out_pos;
            sp_tmp_vel = sp_out_vel;
            sp_tmp_air = sp_out_air;
            sp_tmp_reward = (sp_c_reward3 + ShadowReward (sp_out_pos, sp_out_vel, sp_out_air, goal_pos, FALSE, FALSE, hazard_bias, water_bias));
            sp_tmp_action = sp_c_action3;
            ShadowConsiderCandidate ();
            a = (a + 1.000);
         }
      }
      if ( (beam_w >= 4.000) && (sp_c_reward4 > SHADOW_NEG) ) {
         a = 0.000;
         while ( (a < 8.000) ) {
            ShadowSimStep (sp_c_pos4, sp_c_vel4, sp_c_air4, a, fwd, right, FALSE);
            sp_tmp_pos = sp_out_pos;
            sp_tmp_vel = sp_out_vel;
            sp_tmp_air = sp_out_air;
            sp_tmp_reward = (sp_c_reward4 + ShadowReward (sp_out_pos, sp_out_vel, sp_out_air, goal_pos, FALSE, FALSE, hazard_bias, water_bias));
            sp_tmp_action = sp_c_action4;
            ShadowConsiderCandidate ();
            a = (a + 1.000);
         }
      }
      if ( (beam_w >= 5.000) && (sp_c_reward5 > SHADOW_NEG) ) {
         a = 0.000;
         while ( (a < 8.000) ) {
            ShadowSimStep (sp_c_pos5, sp_c_vel5, sp_c_air5, a, fwd, right, FALSE);
            sp_tmp_pos = sp_out_pos;
            sp_tmp_vel = sp_out_vel;
            sp_tmp_air = sp_out_air;
            sp_tmp_reward = (sp_c_reward5 + ShadowReward (sp_out_pos, sp_out_vel, sp_out_air, goal_pos, FALSE, FALSE, hazard_bias, water_bias));
            sp_tmp_action = sp_c_action5;
            ShadowConsiderCandidate ();
            a = (a + 1.000);
         }
      }

      ShadowPromoteNext ();
      if ( (sp_c_reward1 <= SHADOW_NEG) ) {
         break;
      }

      d = (d + 1.000);

   }

   best_action = sp_c_action1;

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

   if ( (best_action < FALSE) ) {
      return ( 9999.000 );
   }

   // Translate action to direction
   dir = '0.000 0.000 0.000';
   if ( (best_action == 0.000) ) {
      dir = fwd;
   } else if ( (best_action == 1.000) ) {
      dir = (right * -1.000);
   } else if ( (best_action == 2.000) ) {
      dir = right;
   } else if ( (best_action == 3.000) ) {
      dir = (fwd * -1.000);
   } else if ( (best_action == 4.000) ) {
      dir = fwd;
      self.shadow_jump_time = (time + 0.200);
   } else if ( (best_action == 5.000) ) {
      dir = normalize ((right * -1.000) + (fwd * 0.700));
      self.shadow_jump_time = (time + 0.200);
   } else if ( (best_action == 6.000) ) {
      dir = normalize ((right * 1.000) + (fwd * 0.700));
      self.shadow_jump_time = (time + 0.200);
   } else if ( (best_action == 7.000) ) {
      dir = fwd;
   }

   if ( (vlen (dir) < 0.100) ) {
      return ( 9999.000 );
   }

   if ( debug && cvar("developer") && (time > self.shadow_nav_debug_time) ) {
      dprint ("[");
      dprint (self.netname);
      dprint ("] NAV_PUPPET: depth=");
      dprint (ftos (depth));
      dprint (" beam=");
      dprint (ftos (beam_w));
      dprint (" hazard=");
      dprint (ftos (hazard_bias));
      dprint (" water=");
      dprint (ftos (water_bias));
      dprint ("\n");
      self.shadow_nav_debug_time = (time + 0.500);
   }

   return ( vectoyaw (dir) );

};

// =============================================================================
// Combat Crucible: Dual-rollout combat oracle
// =============================================================================

void () ShadowCombatResetNext = {

   local float i;

   i = 0.000;
   while ( i < SHADOW_COMBAT_BEAM_MAX ) {
      cbn_reward[i] = SHADOW_COMBAT_NEG;
      cbn_action[i] = -1.000;
      i = (i + TRUE);
   }

};

void () ShadowCombatPromoteNext = {

   local float i;

   i = 0.000;
   while ( i < SHADOW_COMBAT_BEAM_MAX ) {
      cb_bpos[i] = cbn_bpos[i]; cb_bvel[i] = cbn_bvel[i]; cb_bair[i] = cbn_bair[i]; cb_bhp[i] = cbn_bhp[i]; cb_bammo[i] = cbn_bammo[i]; cb_reward[i] = cbn_reward[i]; cb_action[i] = cbn_action[i];
      cb_epos[i] = cbn_epos[i]; cb_evel[i] = cbn_evel[i]; cb_eair[i] = cbn_eair[i]; cb_ehp[i] = cbn_ehp[i]; cb_eammo[i] = cbn_eammo[i];
      i = (i + TRUE);
   }

};

void (float beam_w) ShadowCombatConsiderCandidate = {

   local float i;
   local float j;
   local float last;

   if ( (beam_w < TRUE) ) {
      return;
   }
   if ( (beam_w > SHADOW_COMBAT_BEAM_MAX) ) {
      beam_w = SHADOW_COMBAT_BEAM_MAX;
   }

   last = (beam_w - TRUE);
   i = 0.000;
   while ( i < beam_w ) {
      if ( (cb_tmp_reward > cbn_reward[i]) ) {
         j = last;
         while ( j > i ) {
            cbn_bpos[j] = cbn_bpos[j - TRUE];
            cbn_bvel[j] = cbn_bvel[j - TRUE];
            cbn_bair[j] = cbn_bair[j - TRUE];
            cbn_bhp[j] = cbn_bhp[j - TRUE];
            cbn_bammo[j] = cbn_bammo[j - TRUE];
            cbn_reward[j] = cbn_reward[j - TRUE];
            cbn_action[j] = cbn_action[j - TRUE];

            cbn_epos[j] = cbn_epos[j - TRUE];
            cbn_evel[j] = cbn_evel[j - TRUE];
            cbn_eair[j] = cbn_eair[j - TRUE];
            cbn_ehp[j] = cbn_ehp[j - TRUE];
            cbn_eammo[j] = cbn_eammo[j - TRUE];
            j = (j - TRUE);
         }

         cbn_bpos[i] = cb_tmp_bpos; cbn_bvel[i] = cb_tmp_bvel; cbn_bair[i] = cb_tmp_bair; cbn_bhp[i] = cb_tmp_bhp; cbn_bammo[i] = cb_tmp_bammo; cbn_reward[i] = cb_tmp_reward; cbn_action[i] = cb_tmp_action;
         cbn_epos[i] = cb_tmp_epos; cbn_evel[i] = cb_tmp_evel; cbn_eair[i] = cb_tmp_eair; cbn_ehp[i] = cb_tmp_ehp; cbn_eammo[i] = cb_tmp_eammo;
         return;
      }
      i = (i + TRUE);
   }

};

float () ShadowCombatEnemyAction = {

   local float eprob0;
   local float eprob1;
   local float eprob2;
   local float eprob3;
   local float bias;
   local float shift;
   local float total;
   local float roll;
   local float eskil;

   eskil = self.skil;
   if ( self.enemy && (self.enemy.classname == "dmbot") ) {
      eskil = self.enemy.skil;
   }
   if ( (eskil < FALSE) ) {
      eskil = FALSE;
   }
   if ( (eskil > 10.000) ) {
      eskil = 10.000;
   }

   // Low skill: 35/15/20/15/15, High skill: 25/15/25/15/20
   local float eprob4;
   if ( (eskil >= 5.000) ) {
      eprob0 = 25.000; // strafe toward / circle
      eprob1 = 15.000; // away
      eprob2 = 25.000; // mirror
      eprob3 = 15.000; // charge/fire
      eprob4 = 20.000; // jump/air-dodge
   } else {
      eprob0 = 35.000;
      eprob1 = 15.000;
      eprob2 = 20.000;
      eprob3 = 15.000;
      eprob4 = 15.000;
   }

   // Slayer Eclipse: bias enemy action model using learned user strafe
   if ( self.enemy && Slayer_IsUser (self.enemy) ) {
      bias = Slayer_UserBias (self.enemy);
      if ( bias != 0.000 ) {
         shift = (bias * 15.000);
         eprob2 = (eprob2 + shift); // left strafe
         eprob3 = (eprob3 - shift); // right strafe + fire
         if ( (eprob2 < 5.000) ) eprob2 = 5.000;
         if ( (eprob3 < 5.000) ) eprob3 = 5.000;
         total = (eprob0 + eprob1 + eprob2 + eprob3 + eprob4);
         if ( (total > 0.000) ) {
            eprob0 = (eprob0 * (100.000 / total));
            eprob1 = (eprob1 * (100.000 / total));
            eprob2 = (eprob2 * (100.000 / total));
            eprob3 = (eprob3 * (100.000 / total));
            eprob4 = (eprob4 * (100.000 / total));
         }
      }
   }

   roll = (random () * 100.000);
   if ( (roll < eprob0) ) return ( 0.000 ); // toward
   roll = (roll - eprob0);
   if ( (roll < eprob1) ) return ( 1.000 ); // away
   roll = (roll - eprob1);
   if ( (roll < eprob2) ) return ( 2.000 ); // mirror
   roll = (roll - eprob2);
   if ( (roll < eprob3) ) return ( 3.000 ); // fire + forward
   return ( 4.000 ); // jump/air-dodge

};

float (float weapon, float dist, float in_water) ShadowCombatWeaponDamage = {

   if ( (weapon == IT_ROCKET_LAUNCHER) ) {
      if ( (dist < 1000.000) ) return ( 100.000 - (dist * 0.040) );
      return ( FALSE );
   }
   if ( (weapon == IT_LIGHTNING) ) {
      if ( in_water ) return ( FALSE );
      if ( (dist < 600.000) ) return ( 30.000 );
      return ( FALSE );
   }
   if ( (weapon == IT_SUPER_SHOTGUN) ) {
      if ( (dist < 500.000) ) return ( 40.000 - (dist * 0.050) );
      return ( FALSE );
   }
   if ( (weapon == IT_SHOTGUN) ) {
      if ( (dist < 500.000) ) return ( 20.000 - (dist * 0.030) );
      return ( FALSE );
   }
   if ( (weapon == IT_SUPER_NAILGUN) ) {
      if ( (dist < 900.000) ) return ( 18.000 );
      return ( FALSE );
   }
   if ( (weapon == IT_NAILGUN) ) {
      if ( (dist < 800.000) ) return ( 12.000 );
      return ( FALSE );
   }
   return ( FALSE );

};

float (float weapon) Slayer_ProjectileSpeed = {

   if ( (weapon == IT_ROCKET_LAUNCHER) ) {
      return ( 1000.000 );
   }
   if ( (weapon == IT_GRENADE_LAUNCHER) ) {
      return ( 600.000 );
   }
   if ( (weapon == IT_SUPER_NAILGUN) || (weapon == IT_NAILGUN) ) {
      return ( 1000.000 );
   }
   return ( 700.000 );

};

vector (entity foe) MonteLead = {

   local vector best_lead;
   local vector sample_vel;
   local vector lead;
   local vector fwd;
   local vector rgt;
   local float max_dmg;
   local float sam;
   local float samples;
   local float dist;
   local float t;
   local float speed;
   local float bias;
   local float in_water;
   local float dmg;
   local float tr_allsolid;
   local float tr_startsolid;
   local float tr_fraction;
   local vector tr_endpos;
   local vector tr_plane_normal;
   local float tr_plane_dist;
   local entity tr_ent;
   local float tr_inopen;
   local float tr_inwater;
   local vector fallback;

   if ( !foe ) {
      return ( self.origin );
   }

   samples = cvar ("mc_samples");
   if ( (samples < TRUE) ) {
      samples = 20.000;
   }
   if ( (samples > 64.000) ) {
      samples = 64.000;
   }

   speed = Slayer_ProjectileSpeed (self.weapon);
   if ( (speed < 1.000) ) {
      speed = 700.000;
   }
   dist = vlen ((foe.origin - self.origin));
   t = (dist / speed);
   if ( (t > 0.600) ) {
      t = 0.600;
   }

   makevectors (foe.angles);
   fwd = v_forward;
   rgt = v_right;
   bias = Slayer_UserBias (foe);

   best_lead = foe.origin;
   max_dmg = SHADOW_COMBAT_NEG;
   sam = 0.000;
   while ( sam < samples ) {
      sample_vel = foe.velocity;
      sample_vel = (sample_vel + (fwd * (random () * 200.000)));
      sample_vel = (sample_vel + (rgt * ((random () - 0.500) * 400.000) * (1.000 + (bias * 0.500))));
      lead = (foe.origin + (sample_vel * t));
      in_water = (pointcontents (self.origin) == CONTENT_WATER);
      dmg = ShadowCombatWeaponDamage (self.weapon, vlen (lead - self.origin), in_water);
      if ( (dmg > max_dmg) ) {
         max_dmg = dmg;
         best_lead = lead;
      }
      sam = (sam + TRUE);
   }

   fallback = (foe.origin + (foe.velocity * t));

   tr_allsolid = trace_allsolid;
   tr_startsolid = trace_startsolid;
   tr_fraction = trace_fraction;
   tr_endpos = trace_endpos;
   tr_plane_normal = trace_plane_normal;
   tr_plane_dist = trace_plane_dist;
   tr_ent = trace_ent;
   tr_inopen = trace_inopen;
   tr_inwater = trace_inwater;

   traceline (self.origin, best_lead, TRUE, self);
   if ( (trace_fraction < TRUE) ) {
      trace_allsolid = tr_allsolid;
      trace_startsolid = tr_startsolid;
      trace_fraction = tr_fraction;
      trace_endpos = tr_endpos;
      trace_plane_normal = tr_plane_normal;
      trace_plane_dist = tr_plane_dist;
      trace_ent = tr_ent;
      trace_inopen = tr_inopen;
      trace_inwater = tr_inwater;
      return ( fallback );
   }

   trace_allsolid = tr_allsolid;
   trace_startsolid = tr_startsolid;
   trace_fraction = tr_fraction;
   trace_endpos = tr_endpos;
   trace_plane_normal = tr_plane_normal;
   trace_plane_dist = tr_plane_dist;
   trace_ent = tr_ent;
   trace_inopen = tr_inopen;
   trace_inwater = tr_inwater;

   return ( best_lead );

};

float (float weapon) ShadowCombatWeaponUsable = {

   if ( (weapon == IT_ROCKET_LAUNCHER) ) {
      return ( (self.items & IT_ROCKET_LAUNCHER) && (self.ammo_rockets >= TRUE) );
   }
   if ( (weapon == IT_LIGHTNING) ) {
      return ( (self.items & IT_LIGHTNING) && (self.ammo_cells >= TRUE) );
   }
   if ( (weapon == IT_SUPER_SHOTGUN) ) {
      return ( (self.items & IT_SUPER_SHOTGUN) && (self.ammo_shells >= FL_SWIM) );
   }
   if ( (weapon == IT_SHOTGUN) ) {
      return ( (self.items & IT_SHOTGUN) && (self.ammo_shells >= TRUE) );
   }
   if ( (weapon == IT_SUPER_NAILGUN) ) {
      return ( (self.items & IT_SUPER_NAILGUN) && (self.ammo_nails >= FL_SWIM) );
   }
   if ( (weapon == IT_NAILGUN) ) {
      return ( (self.items & IT_NAILGUN) && (self.ammo_nails >= TRUE) );
   }
   return ( FALSE );

};

float (entity ent, float weapon) ShadowCombatAmmoForWeapon = {

   if ( !ent ) {
      return ( FALSE );
   }
   if ( (weapon == IT_ROCKET_LAUNCHER) ) {
      return ( ent.ammo_rockets );
   }
   if ( (weapon == IT_LIGHTNING) ) {
      return ( ent.ammo_cells );
   }
   if ( (weapon == IT_SUPER_SHOTGUN) || (weapon == IT_SHOTGUN) ) {
      return ( ent.ammo_shells );
   }
   if ( (weapon == IT_SUPER_NAILGUN) || (weapon == IT_NAILGUN) ) {
      return ( ent.ammo_nails );
   }
   return ( 10.000 );

};

float (vector bpos, vector bvel, float bair, float bhp, float bammo, vector epos, vector evel, float eair, float ehp, vector goal_pos, float use_trace, float blocked) ShadowCombatReward = {

   local float r;
   local float dist;
   local float contents;

   r = FALSE;
   r = (r + ((cb_start_ehp - ehp) * 2.000));
   r = (r - ((cb_start_bhp - bhp) * 3.000));
   dist = vlen ((goal_pos - bpos));
   r = (r + (500.000 / (dist + 1.000)));

   if ( (bhp < 20.000) ) {
      r = (r - 8000.000);
   }
   if ( (ehp < 20.000) ) {
      r = (r + 4000.000);
   }
   if ( blocked ) {
      r = (r - 1200.000);
   }

   contents = pointcontents (bpos);
   if ( (contents == CONTENT_LAVA) ) {
      r = (r - 5000.000);
   } else if ( (contents == CONTENT_SLIME) ) {
      r = (r - 3500.000);
   }
   if ( use_trace ) {
      traceline (bpos, (bpos - '0.000 0.000 96.000'), TRUE, self);
      if ( (trace_fraction == TRUE) ) {
         r = (r - 1200.000);
      } else if ( (trace_plane_normal_z < 0.700) ) {
         r = (r - 500.000);
      }
   }

   if ( (vlen (bvel) < 60.000) ) {
      r = (r - 150.000);
   }
   if ( (bammo < 2.000) ) {
      r = (r - 200.000);
   }

   return ( r );

};

void (vector bpos, vector bvel, float bair, float bhp, float bammo, vector epos, vector evel, float eair, float ehp, float eammo, float action_id, float wpn, float use_trace) ShadowCombatSimStep = {

   local float move_id;
   local float fire_bit;
   local float enemy_act;
   local vector ang;
   local vector efwd;
   local vector eright;
   local float bot_dist;
   local float bot_hit;
   local float bot_dmg;
   local float enemy_hit;
   local float enemy_dmg;
   local float in_water;
   local float ein_water;

   move_id = action_id;
   fire_bit = FALSE;
   if ( (action_id >= 8.000) ) {
      move_id = (action_id - 8.000);
      fire_bit = TRUE;
   }

   // FIX: Save bot's v_forward/v_right before enemy makevectors clobbers them
   local vector bot_fwd, bot_right;
   bot_fwd = v_forward;
   bot_right = v_right;

   // Bot movement (reuse movement sim)
   ShadowSimStep (bpos, bvel, bair, move_id, bot_fwd, bot_right, use_trace);
   cb_out_bpos = sp_out_pos;
   cb_out_bvel = sp_out_vel;
   cb_out_bair = sp_out_air;
   cb_out_bhp = bhp;
   cb_out_bammo = bammo;
   cb_out_blocked = sp_out_blocked;

   // Enemy movement model
   enemy_act = ShadowCombatEnemyAction ();
   ang = '0.000 0.000 0.000';
   ang_y = vectoyaw ((cb_out_bpos - epos));
   makevectors (ang);
   efwd = v_forward;
   eright = v_right;
   // Restore bot vectors for next iteration of the beam loop
   v_forward = bot_fwd;
   v_right = bot_right;
   if ( (enemy_act == 0.000) ) {
      ShadowSimStep (epos, evel, eair, 0.000, efwd, eright, use_trace);
   } else if ( (enemy_act == 1.000) ) {
      ShadowSimStep (epos, evel, eair, 3.000, efwd, eright, use_trace);
   } else if ( (enemy_act == 2.000) ) {
      ShadowSimStep (epos, evel, eair, 1.000, efwd, eright, use_trace);
   } else if ( (enemy_act == 3.000) ) {
      ShadowSimStep (epos, evel, eair, 2.000, efwd, eright, use_trace);
   } else {
      // Jump/air-dodge: forward + jump
      ShadowSimStep (epos, evel, eair, 4.000, efwd, eright, use_trace);
   }
   cb_out_epos = sp_out_pos;
   cb_out_evel = sp_out_vel;
   cb_out_eair = sp_out_air;
   cb_out_ehp = ehp;
   cb_out_eammo = eammo;

   // Bot fire
   if ( fire_bit && (cb_out_bammo > FALSE) ) {
      bot_dist = vlen ((cb_out_epos - cb_out_bpos));
      in_water = (pointcontents (cb_out_bpos) == CONTENT_WATER);
      bot_dmg = ShadowCombatWeaponDamage (wpn, bot_dist, in_water);
      if ( (bot_dmg > FALSE) ) {
         bot_hit = (0.55 + (self.skil * 0.030)) - (bot_dist / 1200.000);
         if ( (bot_hit < 0.100) ) bot_hit = 0.100;
         if ( (bot_hit > 0.900) ) bot_hit = 0.900;
         if ( Slayer_GodMode () ) {
            bot_hit = 1.000;
         }
         if ( (random () < bot_hit) ) {
            cb_out_ehp = (cb_out_ehp - bot_dmg);
            cb_out_bammo = (cb_out_bammo - TRUE);
         }
      }
   }

   // Enemy fire
   if ( (enemy_act == 3.000) && (cb_out_eammo > FALSE) ) {
      bot_dist = vlen ((cb_out_epos - cb_out_bpos));
      ein_water = (pointcontents (cb_out_epos) == CONTENT_WATER);
      enemy_dmg = ShadowCombatWeaponDamage (self.enemy.weapon, bot_dist, ein_water);
      if ( (enemy_dmg > FALSE) ) {
         enemy_hit = 0.45;
         if ( self.enemy && (self.enemy.classname == "dmbot") ) {
            enemy_hit = (0.45 + (self.enemy.skil * 0.020)) - (bot_dist / 1400.000);
         } else {
            enemy_hit = (0.45 + (self.skil * 0.010)) - (bot_dist / 1400.000);
         }
         if ( (enemy_hit < 0.100) ) enemy_hit = 0.100;
         if ( (enemy_hit > 0.850) ) enemy_hit = 0.850;
         if ( self.enemy && (self.enemy.classname == "dmbot") && (self.enemy.skil >= 10.000) && (cvar ("sv_slayer_god") > FALSE) ) {
            enemy_hit = 1.000;
         }
         if ( (random () < enemy_hit) ) {
            cb_out_bhp = (cb_out_bhp - enemy_dmg);
            cb_out_eammo = (cb_out_eammo - TRUE);
         }
      }
   }

};

float (entity enemy, float dist, float wpn, float depth, float beam_w, float fire_bias, float act_limit) ShadowCombatRun = {

   local float d;
   local float a;
   local float b;
   local float use_trace;
   local vector ang;
   local float start_time;
   local float bammo;
   local float eammo;
   local float act_cap;

   if ( (beam_w < TRUE) ) {
      beam_w = TRUE;
   }
   if ( (beam_w > SHADOW_COMBAT_BEAM_MAX) ) {
      beam_w = SHADOW_COMBAT_BEAM_MAX;
   }
   // Skill-scaled action cap (was hardcoded 16)
   local float act_cap_max;
   act_cap_max = (16.000 + floor (self.skil * 2.000));
   if ( act_cap_max > 32.000 ) act_cap_max = 32.000;
   if ( (act_limit > act_cap_max) ) {
      act_limit = act_cap_max;
   }

   // Init
   cb_start_bhp = self.health;
   cb_start_ehp = enemy.health;
   if ( (cb_start_bhp < TRUE) ) cb_start_bhp = TRUE;
   if ( (cb_start_ehp < TRUE) ) cb_start_ehp = TRUE;

   bammo = ShadowCombatAmmoForWeapon (self, wpn);
   eammo = ShadowCombatAmmoForWeapon (enemy, enemy.weapon);

   cb_bpos[0] = self.origin; cb_bvel[0] = self.velocity; cb_bair[0] = (self.air_finished - time); cb_bhp[0] = cb_start_bhp; cb_bammo[0] = bammo; cb_reward[0] = FALSE; cb_action[0] = -1.000;
   cb_epos[0] = enemy.origin; cb_evel[0] = enemy.velocity; cb_eair[0] = (enemy.air_finished - time); cb_ehp[0] = cb_start_ehp; cb_eammo[0] = eammo;

   if ( (cb_bair[0] < FALSE) ) cb_bair[0] = FALSE;
   if ( (cb_eair[0] < FALSE) ) cb_eair[0] = FALSE;

   cb_reward[0] = ShadowCombatReward (cb_bpos[0], cb_bvel[0], cb_bair[0], cb_bhp[0], cb_bammo[0], cb_epos[0], cb_evel[0], cb_eair[0], cb_ehp[0], enemy.origin, TRUE, FALSE);
   cb_action[0] = -1.000;
   b = TRUE;
   while ( b < beam_w ) {
      cb_reward[b] = SHADOW_COMBAT_NEG;
      cb_action[b] = -1.000;
      b = (b + TRUE);
   }
   start_time = time;

   d = 1.000;
   while ( (d <= depth) ) {

      ShadowCombatResetNext ();
      use_trace = FALSE;
      if ( (d == 1.000) ) use_trace = TRUE;
      act_cap = act_limit;
      if ( (act_cap > (beam_w * 4.000)) ) {
         act_cap = (beam_w * 4.000);
      }
      if ( (act_cap < 1.000) ) {
         act_cap = 1.000;
      }

      b = 0.000;
      while ( b < beam_w ) {
         if ( (cb_reward[b] > SHADOW_COMBAT_NEG) ) {
            a = 0.000;
            while ( (a < act_cap) ) {
               ang = '0.000 0.000 0.000';
               ang_y = vectoyaw ((enemy.origin - self.origin));
               makevectors (ang);
               ShadowCombatSimStep (cb_bpos[b], cb_bvel[b], cb_bair[b], cb_bhp[b], cb_bammo[b], cb_epos[b], cb_evel[b], cb_eair[b], cb_ehp[b], cb_eammo[b], a, wpn, use_trace);
               cb_tmp_bpos = cb_out_bpos; cb_tmp_bvel = cb_out_bvel; cb_tmp_bair = cb_out_bair; cb_tmp_bhp = cb_out_bhp;
               cb_tmp_bammo = cb_out_bammo;
               cb_tmp_epos = cb_out_epos; cb_tmp_evel = cb_out_evel; cb_tmp_eair = cb_out_eair; cb_tmp_ehp = cb_out_ehp;
               cb_tmp_eammo = cb_out_eammo;
               cb_tmp_reward = (cb_reward[b] + ShadowCombatReward (cb_out_bpos, cb_out_bvel, cb_out_bair, cb_out_bhp, cb_out_bammo, cb_out_epos, cb_out_evel, cb_out_eair, cb_out_ehp, enemy.origin, use_trace, cb_out_blocked));
               if ( (a >= 8.000) ) {
                  cb_tmp_reward = (cb_tmp_reward + fire_bias);
               }
               cb_tmp_action = cb_action[b];
               if ( (d == 1.000) ) cb_tmp_action = a;
               ShadowCombatConsiderCandidate (beam_w);
               a = (a + 1.000);
               if ( (time > (start_time + 0.050)) ) {
                  break;
               }
            }
         }
         b = (b + TRUE);
         if ( (time > (start_time + 0.050)) ) {
            break;
         }
      }

      ShadowCombatPromoteNext ();
      if ( (cb_reward[0] <= SHADOW_COMBAT_NEG) ) {
         break;
      }
      if ( (time > (start_time + 0.050)) ) {
         break;
      }
      d = (d + 1.000);

   }

   cb_best_action = cb_action[0];
   return ( cb_reward[0] );

};

void (entity enemy, float dist) BotShadowCombatThink = {

   local float throttle;
   local float depth;
   local float beam_w;
   local float best_reward;
   local float best_weapon;
   local float best_action;
   local float reward;
   local float wpn;
   local float depth_override;
   local float beam_override;
   local float fire_bias;
   local float act_limit;
   local float debug;
   local vector ang;
   local vector dir;

   if ( (cvar ("sv_shadow_combat") <= FALSE) ) {
      return;
   }
   if ( !enemy || (enemy == world) ) {
      return;
   }
   if ( enemy.deadflag != DEAD_NO ) {
      return;
   }
   if ( (self.deadflag != DEAD_NO) ) {
      return;
   }
   if ( (dist < 64.000) ) {
      return;
   }

   throttle = cvar ("shadow_throttle");
   if ( (throttle <= FALSE) ) {
      if ( Slayer_GodMode () ) {
         throttle = 0.330;
      } else {
         throttle = (0.200 - (self.skil * 0.010));
         if ( (throttle < 0.100) ) {
            throttle = 0.100;
         }
      }
   } else {
      if ( (throttle < 0.050) ) {
         throttle = 0.050;
      }
   }
   if ( ((self.last_predict + throttle) > time) ) {
      return;
   }
   self.last_predict = time;

   debug = cvar ("shadow_combat_debug");
   if ( (cvar ("shadow_debug") > FALSE) ) {
      debug = TRUE;
   }
   depth_override = cvar ("shadow_combat_depth");
   beam_override = cvar ("shadow_combat_beam");
   fire_bias = cvar ("shadow_combat_fire_bias");

   if ( (self.shadow_depth > FALSE) ) {
      depth = self.shadow_depth;
   } else {
      if ( Slayer_GodMode () ) {
         depth = (8.000 + floor (self.skil * 0.700));
      } else {
         depth = (5.000 + floor (self.skil * 0.700));
      }
   }
   if ( (depth > SHADOW_COMBAT_MAX_DEPTH) ) depth = SHADOW_COMBAT_MAX_DEPTH;
   if ( (depth < 5.000) ) depth = 5.000;

   if ( (self.shadow_beam > FALSE) ) {
      beam_w = self.shadow_beam;
   } else {
      if ( Slayer_GodMode () ) {
         beam_w = (10.000 + floor (self.skil));
      } else {
         beam_w = (2.000 + floor (self.skil * 0.200));
      }
   }
   if ( (beam_w > SHADOW_COMBAT_MAX_BEAM) ) beam_w = SHADOW_COMBAT_MAX_BEAM;
   if ( (beam_w < 2.000) ) beam_w = 2.000;
   if ( Slayer_GodMode () ) {
      act_limit = (12.000 + floor (self.skil));
   } else {
      act_limit = (8.000 * 2.000 * (1.000 + floor (self.skil / 5.000)));
   }
   if ( (act_limit < 8.000) ) act_limit = 8.000;
   // Skill-scaled action cap (was hardcoded 16)
   local float act_cap;
   act_cap = (16.000 + floor (self.skil * 2.000));
   if ( act_cap > 32.000 ) act_cap = 32.000;
   if ( (act_limit > act_cap) ) act_limit = act_cap;
   if ( (depth_override > FALSE) ) {
      depth = depth_override;
      if ( (depth > SHADOW_COMBAT_MAX_DEPTH) ) depth = SHADOW_COMBAT_MAX_DEPTH;
      if ( (depth < 2.000) ) depth = 2.000;
   }
   if ( (beam_override > FALSE) ) {
      beam_w = beam_override;
      if ( (beam_w > SHADOW_COMBAT_MAX_BEAM) ) beam_w = SHADOW_COMBAT_MAX_BEAM;
      if ( (beam_w < 1.000) ) beam_w = 1.000;
   }

   best_reward = SHADOW_COMBAT_NEG;
   best_weapon = FALSE;
   best_action = -1.000;

   // Try prioritized weapons
   wpn = IT_ROCKET_LAUNCHER;
   if ( ShadowCombatWeaponUsable (wpn) ) {
      reward = ShadowCombatRun (enemy, dist, wpn, depth, beam_w, fire_bias, act_limit);
      if ( (reward > best_reward) ) {
         best_reward = reward;
         best_weapon = wpn;
         best_action = cb_best_action;
      }
   }
   wpn = IT_LIGHTNING;
   if ( ShadowCombatWeaponUsable (wpn) ) {
      reward = ShadowCombatRun (enemy, dist, wpn, depth, beam_w, fire_bias, act_limit);
      if ( (reward > best_reward) ) {
         best_reward = reward;
         best_weapon = wpn;
         best_action = cb_best_action;
      }
   }
   wpn = IT_SUPER_SHOTGUN;
   if ( ShadowCombatWeaponUsable (wpn) ) {
      reward = ShadowCombatRun (enemy, dist, wpn, depth, beam_w, fire_bias, act_limit);
      if ( (reward > best_reward) ) {
         best_reward = reward;
         best_weapon = wpn;
         best_action = cb_best_action;
      }
   }

   // Fallback: current weapon
   if ( (best_weapon == FALSE) && ShadowCombatWeaponUsable (self.weapon) ) {
      reward = ShadowCombatRun (enemy, dist, self.weapon, depth, beam_w, fire_bias, act_limit);
      best_reward = reward;
      best_weapon = self.weapon;
      best_action = cb_best_action;
   }

   if ( (best_reward < -1500.000) ) {
      return;
   }
   if ( (best_action < FALSE) ) {
      return;
   }

   // Map action to yaw + fire flag
   ang = '0.000 0.000 0.000';
   ang_y = vectoyaw ((enemy.origin - self.origin));
   makevectors (ang);
   dir = '0.000 0.000 0.000';
   if ( (best_action >= 8.000) ) {
      self.shadow_combat_fire = TRUE;
   } else {
      self.shadow_combat_fire = FALSE;
   }

   if ( (best_action >= 8.000) ) {
      best_action = (best_action - 8.000);
   }
   if ( (best_action == 0.000) ) {
      dir = v_forward;
   } else if ( (best_action == 1.000) ) {
      dir = (v_right * -1.000);
   } else if ( (best_action == 2.000) ) {
      dir = v_right;
   } else if ( (best_action == 3.000) ) {
      dir = (v_forward * -1.000);
   } else if ( (best_action == 4.000) ) {
      dir = v_forward;
   } else if ( (best_action == 5.000) ) {
      dir = normalize ((v_right * -1.000) + (v_forward * 0.700));
   } else if ( (best_action == 6.000) ) {
      dir = normalize ((v_right * 1.000) + (v_forward * 0.700));
   } else if ( (best_action == 7.000) ) {
      dir = v_forward;
   }

   if ( (vlen (dir) < 0.100) ) {
      return;
   }

   self.shadow_combat_yaw = vectoyaw (dir);
   self.shadow_combat_weapon = best_weapon;
   self.shadow_combat_time = (time + 0.250);
   if ( debug && cvar("developer") ) {
      dprint ("[");
      dprint (self.netname);
      dprint ("] COMBAT_PUPPET: reward=");
      dprint (ftos (floor (best_reward)));
      dprint (" depth=");
      dprint (ftos (depth));
      dprint (" beam=");
      dprint (ftos (beam_w));
      dprint (" fire=");
      if ( (self.shadow_combat_fire > FALSE) ) {
         dprint ("1");
      } else {
         dprint ("0");
      }
      dprint (" wpn=");
      dprint (ftos (best_weapon));
      dprint ("\n");
   }

};

float () BotShadowCombatWeapon = {

   if ( (self.shadow_combat_time > time) && (self.shadow_combat_weapon > FALSE) ) {
      if ( ShadowCombatWeaponUsable (self.shadow_combat_weapon) ) {
         return ( self.shadow_combat_weapon );
      }
   }
   return ( FALSE );

};
