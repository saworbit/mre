// bot_learn.qc: Phantom Apprenticeship + Ethereal Rollouts

void (vector pos, vector vel, float air_left, float action_id, vector fwd, vector right, float use_trace) ShadowSimStep;
float (vector pos, vector vel, float air_left, vector goal_pos, float use_trace, float blocked, float hazard_bias, float water_bias) ShadowReward;
float (entity foe) Slayer_IsUser;
float (entity foe) Slayer_UserHash;

void () PhantomThink;
void (entity ph) Spectral_EndEpisode;
void () Spectral_AbortEpisode;
void (vector start, vector end) Vortex_RecordEpisode;
void (vector entry, vector exit) Vortex_FuseTeleChain;
float (vector pos) Vortex_FindNode;
void (float idx, float amt) Vortex_BoostUsage;
void (vector pos) Vortex_RefineLiftPhase;
float (entity e) Ripple_InteractType;
void (vector start, vector end, vector ripple_pos, float rtype) Ripple_FuseChain;
float (float armor) Quantum_RJDamage;
float (float armor) Quantum_GJDamage;
float (float armor) Quantum_GLJDamage;
void (vector start, vector end, vector leap_pos, float risk) Quantum_FuseLeap;

#ifdef QS_V6
#define MAX_EPISODES 32
#else
#define MAX_EPISODES 50
#endif
#define EPISODE_DURATION 10.000
#define DECAY_RATE 0.100
#define ALLURE_BASE 50.000
#define SIM_DEPTH_PHANTOM 4.000
#define SIM_BEAM_PHANTOM 3
#define REWARD_THRESH 20.000
#define VISIT_HASH_SCALE 256
#define SPECTRAL_NEG -999999.000

#define RJ_PURPOSE_LAVA 0.000
#define RJ_PURPOSE_VAULT 1.000
#define RJ_PURPOSE_HIGH 2.000
#define RJ_PURPOSE_FLAT 3.000

vector spectral_start[MAX_EPISODES];
vector spectral_end[MAX_EPISODES];
float spectral_reward[MAX_EPISODES];
float spectral_viability[MAX_EPISODES];
float spectral_maneuver[MAX_EPISODES];
float spectral_hash[MAX_EPISODES];
float spectral_count;
float spectral_decay_next;

float spectral_visit[VISIT_HASH_SCALE];

vector er_pos[SIM_BEAM_PHANTOM];
vector er_vel[SIM_BEAM_PHANTOM];
float er_air[SIM_BEAM_PHANTOM];
float er_reward[SIM_BEAM_PHANTOM];
float er_count;

vector er_next_pos[SIM_BEAM_PHANTOM];
vector er_next_vel[SIM_BEAM_PHANTOM];
float er_next_air[SIM_BEAM_PHANTOM];
float er_next_reward[SIM_BEAM_PHANTOM];
float er_next_count;

float (vector pos) Spectral_AllureBias = {
   local float i;
   local float dist;
   local float sum;

   if ( (spectral_count <= 0.000) ) {
      return 0.000;
   }

   sum = 0.000;
   i = 0.000;
   while ( i < spectral_count ) {
      dist = vlen (pos - spectral_start[i]);
      if ( (dist < 256.000) ) {
         sum = (sum + ((spectral_reward[i] * spectral_viability[i]) / (dist + 64.000)));
      }
      dist = vlen (pos - spectral_end[i]);
      if ( (dist < 256.000) ) {
         sum = (sum + ((spectral_reward[i] * spectral_viability[i]) / (dist + 64.000)));
      }
      i = (i + TRUE);
   }

   return (sum * 0.010);
};

float (float v) Spectral_WrapIndex = {
   local float wrap;
   wrap = floor (v / VISIT_HASH_SCALE);
   return (v - (wrap * VISIT_HASH_SCALE));
};

float (vector v) Spectral_HashVec = {
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
   return Spectral_WrapIndex (h);
};

float (vector start, vector end) Spectral_HashPair = {
   local float h1;
   local float h2;
   local float h;

   h1 = Spectral_HashVec (start);
   h2 = Spectral_HashVec (end);
   h = (h1 * 31.000) + h2;
   return Spectral_WrapIndex (h);
};

void () Spectral_ResetNext = {
   local float i;

   i = 0.000;
   while ( i < SIM_BEAM_PHANTOM ) {
      er_next_reward[i] = SPECTRAL_NEG;
      i = (i + TRUE);
   }
   er_next_count = 0.000;
};

void (vector pos, vector vel, float air, float reward, float beam_w) Spectral_ConsiderCandidate = {
   local float i;
   local float j;
   local float last;

   last = (beam_w - TRUE);
   if ( (er_next_count >= beam_w) && (reward <= er_next_reward[last]) ) {
      return ;
   }

   i = 0.000;
   while ( i < beam_w ) {
      if ( (reward > er_next_reward[i]) ) {
         j = last;
         while ( j > i ) {
            er_next_pos[j] = er_next_pos[j - TRUE];
            er_next_vel[j] = er_next_vel[j - TRUE];
            er_next_air[j] = er_next_air[j - TRUE];
            er_next_reward[j] = er_next_reward[j - TRUE];
            j = (j - TRUE);
         }
         er_next_pos[i] = pos;
         er_next_vel[i] = vel;
         er_next_air[i] = air;
         er_next_reward[i] = reward;
         if ( (er_next_count < beam_w) ) {
            er_next_count = (er_next_count + TRUE);
         }
         return ;
      }
      i = (i + TRUE);
   }

   if ( (er_next_count < beam_w) ) {
      er_next_pos[er_next_count] = pos;
      er_next_vel[er_next_count] = vel;
      er_next_air[er_next_count] = air;
      er_next_reward[er_next_count] = reward;
      er_next_count = (er_next_count + TRUE);
   }
};

float (vector start, vector goal, float maneuver) EtherealRollout = {
   local float depth;
   local float beam_w;
   local float d;
   local float b;
   local float a;
   local float action;
   local float reward;
   local float hash;
   local vector fwd;
   local vector rgt;
   local float sum;

   if ( (maneuver == 2.000) ) {
      if ( vlen (goal - start) > 500.000 ) {
         return 100.000;
      }
      traceline (start, goal, TRUE, world);
      if ( (trace_fraction == 1.000) ) {
         return 100.000;
      }
      return -100.000;
   }

   depth = SIM_DEPTH_PHANTOM;
   depth = (depth + floor(skill * 0.500));
   if ( (depth > 8.000) ) {
      depth = 8.000;
   }

   beam_w = SIM_BEAM_PHANTOM;
   if ( (beam_w < TRUE) ) {
      beam_w = TRUE;
   }

   fwd = normalize (goal - start);
   if ( (vlen(fwd) < 0.010) ) {
      fwd = '1 0 0';
   }
   rgt_x = -fwd_y;
   rgt_y = fwd_x;
   rgt_z = 0.000;
   rgt = normalize (rgt);

   // FIX: Clear visit table to prevent inter-bot pollution from previous rollouts
   local float ci;
   ci = 0;
   while ( ci < VISIT_HASH_SCALE ) {
      spectral_visit[ci] = 0;
      ci = ci + 1;
   }

   er_pos[0] = start;
   er_vel[0] = '0 0 0';
   er_air[0] = 12.000;
   sp_out_onlift = FALSE;
   er_reward[0] = ShadowReward (start, er_vel[0], er_air[0], goal, 0.000, 0.000, 1.000, 1.000);
   er_count = TRUE;

   d = TRUE;
   while ( d <= depth ) {
      Spectral_ResetNext ();
      b = 0.000;
      while ( b < er_count ) {
         hash = Spectral_HashVec (er_pos[b]);
         if ( (spectral_visit[hash] > (time - TRUE)) ) {
            b = (b + TRUE);
            continue ;
         }
         spectral_visit[hash] = time;

         a = 0.000;
         while ( a < 4.000 ) {
            action = 0.000;
            if ( (a == 0.000) ) {
               action = 0.000;
               if ( (maneuver == 1.000) ) {
                  action = 4.000;
               } else if ( (maneuver == 3.000) ) {
                  action = 7.000;
               }
            } else if ( (a == 1.000) ) {
               action = 4.000;
            } else if ( (a == 2.000) ) {
               action = 1.000;
            } else {
               action = 2.000;
            }

            ShadowSimStep (er_pos[b], er_vel[b], er_air[b], action, fwd, rgt, TRUE);
            sp_out_vel_x = (sp_out_vel_x + (random () * 10.000) - 5.000);
            sp_out_vel_y = (sp_out_vel_y + (random () * 10.000) - 5.000);
            reward = ShadowReward (sp_out_pos, sp_out_vel, sp_out_air, goal, 0.000, sp_out_blocked, 1.000, 1.000);
            Spectral_ConsiderCandidate (sp_out_pos, sp_out_vel, sp_out_air, reward, beam_w);

            a = (a + TRUE);
         }
         b = (b + TRUE);
      }

      er_count = er_next_count;
      if ( (er_count <= FALSE) ) {
         return -999.000;
      }
      b = 0.000;
      while ( b < er_count ) {
         er_pos[b] = er_next_pos[b];
         er_vel[b] = er_next_vel[b];
         er_air[b] = er_next_air[b];
         er_reward[b] = er_next_reward[b];
         b = (b + TRUE);
      }
      d = (d + TRUE);
   }

   sum = 0.000;
   b = 0.000;
   while ( b < er_count ) {
      sum = (sum + er_reward[b]);
      b = (b + TRUE);
   }
   return (sum / er_count);
};

void (vector start, vector end, float reward, float viability, float maneuver) Spectral_AddEpisode = {
   local float hash;
   local float i;
   local float slot;
   local float score;
   local float low_score;
   local float low_idx;

   if ( (reward <= 0.000) || (viability < REWARD_THRESH) ) {
      return ;
   }

   hash = Spectral_HashPair (start, end);
   i = 0.000;
   while ( i < spectral_count ) {
      if ( (spectral_hash[i] == hash) ) {
         return ;
      }
      i = (i + TRUE);
   }

   if ( (spectral_count < MAX_EPISODES) ) {
      slot = spectral_count;
      spectral_count = (spectral_count + TRUE);
   } else {
      low_score = (spectral_reward[0] * spectral_viability[0]);
      low_idx = 0.000;
      i = TRUE;
      while ( i < spectral_count ) {
         score = (spectral_reward[i] * spectral_viability[i]);
         if ( (score < low_score) ) {
            low_score = score;
            low_idx = i;
         }
         i = (i + TRUE);
      }
      if ( ((reward * viability) <= low_score) ) {
         return ;
      }
      slot = low_idx;
   }

   spectral_start[slot] = start;
   spectral_end[slot] = end;
   spectral_reward[slot] = reward;
   spectral_viability[slot] = viability;
   spectral_maneuver[slot] = maneuver;
   spectral_hash[slot] = hash;
};

float (entity node, entity targ) ApplySpectralBoost = {
   local float boost;
   local float i;

   if ( (spectral_count <= 0.000) ) {
      return 0.000;
   }

   boost = 0.000;
   i = 0.000;
   while ( i < spectral_count ) {
      if ( (vlen (spectral_start[i] - node.origin) < 128.000) &&
           (vlen (spectral_end[i] - targ.origin) < 128.000) ) {
         boost = (boost + ((spectral_reward[i] * spectral_viability[i]) / 10000.000));
      }
      i = (i + TRUE);
   }

   return (boost * ALLURE_BASE);
};

void () DecayEpisodes = {
   local float i;

   if ( (time < spectral_decay_next) ) {
      return ;
   }
   spectral_decay_next = (time + 60.000);

   i = 0.000;
   while ( i < spectral_count ) {
      spectral_reward[i] = (spectral_reward[i] * (1.000 - DECAY_RATE));
      if ( (spectral_reward[i] < 10.000) || (spectral_viability[i] < 10.000) ) {
         spectral_start[i] = spectral_start[spectral_count - TRUE];
         spectral_end[i] = spectral_end[spectral_count - TRUE];
         spectral_reward[i] = spectral_reward[spectral_count - TRUE];
         spectral_viability[i] = spectral_viability[spectral_count - TRUE];
         spectral_maneuver[i] = spectral_maneuver[spectral_count - TRUE];
         spectral_hash[i] = spectral_hash[spectral_count - TRUE];
         spectral_count = (spectral_count - TRUE);
      } else {
         i = (i + TRUE);
      }
   }
};

vector () Spectral_PickEndpoint = {

   local float idx;

   if ( (spectral_count <= 0.000) ) {
      return '0 0 0';
   }

   idx = floor (random () * spectral_count);
   if ( (idx < FALSE) ) {
      idx = FALSE;
   }
   if ( (idx >= spectral_count) ) {
      idx = (spectral_count - TRUE);
   }

   return spectral_end[idx];

};

entity () Spectral_FindPlayer = {
   local entity p;
   local entity pick;
   local float count;

   count = 0.000;
   p = find (world, classname, "player");
   while ( p ) {
      if ( (p.health > 0.000) ) {
         count = (count + TRUE);
         if ( (random () < (1.000 / count)) ) {
            pick = p;
         }
      }
      p = find (p, classname, "player");
   }
   return pick;
};

entity (entity target) SpawnPhantom = {
   local entity ph;

   if ( !target ) {
      return world;
   }

   ph = spawn ();
   ph.classname = "bot_phantom";
   ph.phantom_owner = self;
   ph.movetype = MOVETYPE_NONE;
   ph.solid = SOLID_NOT;
   ph.model = string_null;
   ph.origin = target.origin;
   ph.phantom_target = target;
   ph.episode_time = (time + EPISODE_DURATION);
   if ( (cvar ("user_learn") > FALSE) && Slayer_IsUser (target) ) {
      ph.episode_time = (ph.episode_time + 5.000);
   }
   ph.episode_start = target.origin;
   ph.last_sim_time = FALSE;
   ph.sim_maneuver = 0.000;
   ph.tele_entry = '0 0 0';
   ph.tele_exit = '0 0 0';
   ph.tele_chain_time = 0.000;
   ph.think = PhantomThink;
   ph.nextthink = (time + 0.100);

   self.phantom = ph;
   return ph;
};

void () Spectral_AbortEpisode = {
   local entity owner;

   owner = self.phantom_owner;
   if ( owner ) {
      owner.phantom = world;
   }
   remove (self);
};

void (entity ph) Spectral_EndEpisode = {
   local entity owner;
   local entity goal;
   local float reward;
   local float viability;
   local float maneuver;
   local float hash;
   local float i;
   local float lidx;
   local float h;
   local float lateral;
   local vector vel;
   local vector rgt;
   local float rtype;
   local vector delta;
   local vector flat;
   local vector mid;
   local float vert;
   local float horiz;
   local float purpose;
   local float is_glj;

   owner = ph.phantom_owner;
   if ( owner ) {
      owner.phantom = world;
   }

   if ( !ph.phantom_target ) {
      remove (ph);
      return ;
   }

   reward = 0.000;
   goal = ph.phantom_target.goalentity;
   if ( goal ) {
      if ( (goal.classname == "item_artifact_super_damage") || (goal.classname == "item_artifact_invulnerability") ) {
         reward = 500.000;
      } else if ( (goal.classname == "item_artifact_invisibility") ) {
         reward = 400.000;
      } else if ( (goal.classname == "weapon_rocketlauncher") || (goal.classname == "weapon_lightning") ) {
         reward = 200.000;
      }
   }
   if ( (reward <= 0.000) ) {
      if ( (ph.phantom_target.frags > owner.frags) ) {
         reward = 300.000;
      }
   }
   if ( (reward <= 0.000) ) {
      remove (ph);
      return ;
   }

   maneuver = ph.sim_maneuver;
   if ( maneuver == 2.000 ) {
      if ( (ph.tele_chain_time > 0.000) && (vlen (ph.tele_exit - ph.tele_entry) > 500.000) ) {
         Vortex_FuseTeleChain (ph.tele_entry, ph.tele_exit);
      }
      remove (ph);
      return ;
   }
   viability = EtherealRollout (ph.episode_start, ph.origin, maneuver);
   if ( (viability < REWARD_THRESH) ) {
      remove (ph);
      return ;
   }

   // Vortex Navmesh: phantom trail validates a dynamic edge
   Vortex_RecordEpisode (ph.episode_start, ph.origin);

   // Ripple Oracles: learn interactable chains from phantom episodes
   makevectors (ph.phantom_target.angles);
   traceline (ph.episode_start - (v_forward * 64.000), ph.episode_start + (v_forward * 64.000), TRUE, ph);
   if ( trace_ent ) {
      rtype = Ripple_InteractType (trace_ent);
      if ( (rtype > 0.000) ) {
         Ripple_FuseChain (ph.episode_start, ph.origin, trace_ent.origin, rtype);
      }
   }

   // Quantum Leaps: distill rocket/grenade jump arcs from phantoms
   delta = (ph.origin - ph.episode_start);
   if ( (fabs (delta_z) > 128.000) && (vlen (delta) > 256.000) ) {
      if ( (ph.phantom_target.weapon == IT_ROCKET_LAUNCHER) && ph.phantom_target.button0 && ph.phantom_target.button2 ) {
         Quantum_FuseLeap (ph.episode_start, ph.origin, ph.episode_start, Quantum_RJDamage (ph.phantom_target.armorvalue));
      } else if ( (ph.phantom_target.weapon == IT_GRENADE_LAUNCHER) && ph.phantom_target.button0 && ph.phantom_target.button2 ) {
         vert = fabs (delta_z);
         flat = delta;
         flat_z = 0.000;
         horiz = vlen (flat);
         mid = ph.episode_start;
         if ( vlen (delta) > 0.010 ) {
            mid = (ph.episode_start + (normalize (delta) * 128.000));
         }
         purpose = RJ_PURPOSE_FLAT;
         if ( (pointcontents (mid) == CONTENT_LAVA) || (pointcontents (mid) == CONTENT_SLIME) ) {
            purpose = RJ_PURPOSE_LAVA;
         } else if ( vert > (horiz * 0.500) ) {
            purpose = RJ_PURPOSE_VAULT;
         } else if ( vert > 256.000 ) {
            purpose = RJ_PURPOSE_HIGH;
         }
         is_glj = (vert > (horiz * 0.600));
         if ( is_glj ) {
            glj_angle_tune[purpose] = (glj_angle_tune[purpose] + 0.030);
            if ( glj_angle_tune[purpose] > 0.300 ) glj_angle_tune[purpose] = 0.300;
            Quantum_FuseLeap (ph.episode_start, ph.origin, ph.episode_start, Quantum_GLJDamage (ph.phantom_target.armorvalue));
         } else {
            gj_horiz_tune[purpose] = (gj_horiz_tune[purpose] + 0.040);
            gj_vert_tune[purpose] = (gj_vert_tune[purpose] + 0.040);
            if ( gj_horiz_tune[purpose] > 0.400 ) gj_horiz_tune[purpose] = 0.400;
            if ( gj_vert_tune[purpose] > 0.500 ) gj_vert_tune[purpose] = 0.500;
            Quantum_FuseLeap (ph.episode_start, ph.origin, ph.episode_start, Quantum_GJDamage (ph.phantom_target.armorvalue));
         }
      }
   }

   hash = Spectral_HashPair (ph.episode_start, ph.origin);
   i = 0.000;
   while ( i < spectral_count ) {
      if ( (spectral_hash[i] == hash) ) {
         remove (ph);
         return ;
      }
      i = (i + TRUE);
   }

   Spectral_AddEpisode (ph.episode_start, ph.origin, reward, viability, maneuver);

   // Lift ride glory
   traceline (ph.origin + '0 0 32', ph.origin - '0 0 64', TRUE, world);
   if ( trace_ent && ((trace_ent.classname == "func_plat") || (trace_ent.classname == "plat") || (trace_ent.classname == "func_train") || (trace_ent.classname == "train")) ) {
      lidx = Vortex_FindNode (ph.origin);
      if ( lidx >= 0.000 ) {
         Vortex_RefineLiftPhase (ph.origin);
         Vortex_BoostUsage (lidx, 30.000);
      }
   }

   // Slayer Eclipse: distill user strafe bias from phantom target
   if ( (cvar ("user_learn") > FALSE) && Slayer_IsUser (ph.phantom_target) ) {
      vel = ph.phantom_target.velocity;
      if ( (vlen (vel) > 10.000) ) {
         makevectors (ph.phantom_target.angles);
         rgt = v_right;
         lateral = (normalize (vel) * rgt);
         h = Slayer_UserHash (ph.phantom_target);
         if ( (h >= 0.000) && (h < 32.000) ) {
            user_strafe_bias[h] = (user_strafe_bias[h] + (lateral * 0.200));
            if ( (user_strafe_bias[h] > 1.000) ) user_strafe_bias[h] = 1.000;
            if ( (user_strafe_bias[h] < -1.000) ) user_strafe_bias[h] = -1.000;
         }
      }
   }

   remove (ph);
};

void () PhantomThink = {
   local float dist_delta;
   local float viability;
   local vector prev_pos;

   if ( !self.phantom_target ) {
      Spectral_AbortEpisode ();
      return ;
   }
   if ( (self.phantom_target.deadflag != DEAD_NO) ) {
      Spectral_AbortEpisode ();
      return ;
   }
   if ( (time > self.episode_time) ) {
      Spectral_EndEpisode (self);
      return ;
   }

   prev_pos = self.origin;
   dist_delta = vlen (self.phantom_target.origin - prev_pos);
   if ( (dist_delta > 500.000) && (self.phantom_target.teleport_time > time) ) {
      self.tele_entry = prev_pos;
      self.tele_exit = self.phantom_target.origin;
      self.tele_chain_time = time;
      Vortex_FuseTeleChain (prev_pos, self.phantom_target.origin);
   }
   if ( (dist_delta > 500.000) ) {
      self.sim_maneuver = 2.000;
   } else if ( (self.phantom_target.velocity_z > 200.000) ) {
      self.sim_maneuver = 1.000;
   } else if ( (self.phantom_target.waterlevel >= 2.000) ) {
      self.sim_maneuver = 3.000;
   } else {
      self.sim_maneuver = 0.000;
   }

   if ( (time > (self.last_sim_time + 0.500)) ) {
      viability = EtherealRollout (self.origin, self.phantom_target.origin, self.sim_maneuver);
      if ( (viability < REWARD_THRESH) && (random () < 0.700) ) {
         Spectral_AbortEpisode ();
         return ;
      }
      self.last_sim_time = time;
   }

   self.origin = self.phantom_target.origin;
   self.nextthink = (time + 0.100);
};

void () Spectral_DebugDump = {
   sprint (self, "#Episodes: ");
   sprint (self, ftos(spectral_count));
   sprint (self, "\n");
};
