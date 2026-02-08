// ai_ripple.qc: Ripple Oracles - Causal Interactable Symphony

void (vector pos, vector vel, float air_left, float action_id, vector fwd, vector right, float use_trace) ShadowSimStep;
float (vector pos, vector vel, float air_left, vector goal_pos, float use_trace, float blocked, float hazard_bias, float water_bias) ShadowReward;

float (vector pos) Vortex_FindNode;
float (vector pos, float ntype) Vortex_AddNode;
void (float idx) Vortex_LinkNearby;
void (float n1, float n2) Vortex_AddEdgeOneWay;
void (float idx, float amt) Vortex_BoostUsage;
float (float idx) Vortex_IndexValid;

#ifdef QS_V6
#define VORTEX_MAX_NODES 256
#else
#define VORTEX_MAX_NODES 512
#endif
#define VORTEX_NODE_GROUND 0.000

#define RIPPLE_TYPE_NONE 0.000
#define RIPPLE_TYPE_SHOOT 1.000
#define RIPPLE_TYPE_TOUCH 2.000

#define RIPPLE_PULSE_DIRS 8.000
#define RIPPLE_PULSE_DIST 128.000
#define RIPPLE_GOAL_RANGE 512.000
#define RIPPLE_PROBE_THROTTLE 0.400
#define RIPPLE_ACTION_RANGE 128.000
#define RIPPLE_NEG -999999.000

#define MAELSTROM_BEAM 6
#define MAELSTROM_DEPTH_BASE 12.000
#define MAELSTROM_DEPTH_MAX 16.000
#define MAELSTROM_VISIT_HASH 256

#define FLAG_DOOR_OPEN 1.000
#define FLAG_PLAT_RAISED 2.000

#ifdef QS_V6
#define MCTS_NODES 256
#else
#define MCTS_NODES 512
#endif
#define MCTS_CHILDREN 4.000
#define MCTS_UCT_C 1.400
#define MCTS_ROLL_DEPTH 6.000
#define MCTS_ITER_BASE 80.000
#define MCTS_ITER_PER_SKILL 12.000
#define MCTS_ITER_MAX 512.000
#define MCTS_THROTTLE 0.400
#define MCTS_EARLY_VISITS 30.000
#define MCTS_EARLY_REWARD 120.000
#define MCTS_SUCCESS_REWARD 50.000

#define RJ_ACTION_BASE 16.000
#define RJ_ACTIONS 8.000
#define RJ_IMPULSE 1600.000
#define RJ_DAMAGE 80.000
#define RJ_MIN_HEALTH 30.000
#define RJ_COOLDOWN 5.000
#define RJ_PROBE_THROTTLE 0.125

#define LEAP_TYPE_RJ 0.000
#define LEAP_TYPE_GJ 1.000
#define LEAP_TYPE_GLJ 2.000

#define GJ_ACTION_BASE 24.000
#define GJ_ACTIONS 8.000
#define GJ_IMPULSE 1000.000
#define GJ_DAMAGE 120.000
#define GJ_MIN_HEALTH 40.000
#define GJ_FUSE_TIME 2.500
#define GJ_SIM_STEPS 8.000
#define GJ_BOUNCE_DAMP 0.600
#define GJ_THROW_SPEED 600.000

#define GLJ_ACTION_BASE 32.000
#define GLJ_ACTIONS 8.000
#define GLJ_IMPULSE 1050.000
#define GLJ_DAMAGE 110.000
#define GLJ_MIN_HEALTH 40.000
#define GLJ_FUSE_TIME 2.800
#define GLJ_SIM_STEPS 9.000
#define GLJ_BOUNCE_DAMP 0.620
#define GLJ_THROW_SPEED 800.000

#define RJ_PURPOSE_LAVA 0.000
#define RJ_PURPOSE_VAULT 1.000
#define RJ_PURPOSE_HIGH 2.000
#define RJ_PURPOSE_FLAT 3.000

vector mr_pos[MAELSTROM_BEAM];
vector mr_vel[MAELSTROM_BEAM];
float mr_air[MAELSTROM_BEAM];
float mr_reward[MAELSTROM_BEAM];
float mr_flags[MAELSTROM_BEAM];
float mr_count;

vector mr_next_pos[MAELSTROM_BEAM];
vector mr_next_vel[MAELSTROM_BEAM];
float mr_next_air[MAELSTROM_BEAM];
float mr_next_reward[MAELSTROM_BEAM];
float mr_next_flags[MAELSTROM_BEAM];
float mr_next_count;

float ripple_visit[MAELSTROM_VISIT_HASH];

vector mcts_pos[MCTS_NODES];
vector mcts_vel[MCTS_NODES];
float mcts_air[MCTS_NODES];
float mcts_flags[MCTS_NODES];
float mcts_reward[MCTS_NODES];
float mcts_visits[MCTS_NODES];
float mcts_health[MCTS_NODES];
float mcts_armor[MCTS_NODES];
float mcts_parent[MCTS_NODES];
float mcts_depth[MCTS_NODES];
float mcts_child0[MCTS_NODES];
float mcts_child1[MCTS_NODES];
float mcts_child2[MCTS_NODES];
float mcts_child3[MCTS_NODES];

float mcts_root;
float mcts_next_node;
float mcts_last_probe;
float mcts_last_goal_node;
float mcts_last_success;

float mcts_best_reward;
float mcts_best_flags;
vector mcts_best_pos;
float mcts_best_depth;

vector mcts_goal_pos;
vector mcts_probe_pos;
float mcts_rtype;
vector mcts_fwd;
vector mcts_rgt;

float rj_last_probe;
float rj_last_goal_node;
float rj_last_success;
float rj_best_reward;
vector rj_best_pos;
float rj_best_depth;
vector rj_goal_pos;
vector rj_probe_pos;
vector rj_fwd;
vector rj_rgt;

float (float v) Ripple_WrapIndex = {
   local float wrap;
   wrap = floor (v / MAELSTROM_VISIT_HASH);
   return (v - (wrap * MAELSTROM_VISIT_HASH));
};

float (vector v) Ripple_HashVec = {
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
   return Ripple_WrapIndex (h);
};

float (vector pos, float flags) Ripple_HashState = {
   local float h;
   h = Ripple_HashVec (pos) + (flags * 19.000);
   return Ripple_WrapIndex (h);
};

vector (float idx) Ripple_PulseDir = {

   if ( idx == 0.000 ) return '64 0 0';
   if ( idx == 1.000 ) return '0 64 0';
   if ( idx == 2.000 ) return '-64 0 0';
   if ( idx == 3.000 ) return '0 -64 0';
   if ( idx == 4.000 ) return '45 45 0';
   if ( idx == 5.000 ) return '-45 45 0';
   if ( idx == 6.000 ) return '-45 -45 0';
   return '45 -45 0';

};

float (entity e) Ripple_InteractType = {

   if ( !e ) {
      return RIPPLE_TYPE_NONE;
   }
   if ( e.classname == "func_button" ) {
      if ( e.health > 0.000 ) {
         return RIPPLE_TYPE_SHOOT;
      }
      return RIPPLE_TYPE_TOUCH;
   }
   if ( (e.classname == "door") || (e.classname == "func_door") || (e.classname == "func_door_rotating") ) {
      return RIPPLE_TYPE_SHOOT;
   }
   if ( (e.classname == "func_plat") || (e.classname == "plat") || (e.classname == "func_train") || (e.classname == "train") ) {
      return RIPPLE_TYPE_TOUCH;
   }
   return RIPPLE_TYPE_NONE;
};

float (float rtype) Ripple_FlagForType = {
   if ( rtype == RIPPLE_TYPE_SHOOT ) {
      return FLAG_DOOR_OPEN;
   }
   if ( rtype == RIPPLE_TYPE_TOUCH ) {
      return FLAG_PLAT_RAISED;
   }
   return 0.000;
};

float (float node, float slot) Ripple_MCTSGetChild = {
   if ( slot == 0.000 ) return mcts_child0[node];
   if ( slot == 1.000 ) return mcts_child1[node];
   if ( slot == 2.000 ) return mcts_child2[node];
   return mcts_child3[node];
};

void (float node, float slot, float val) Ripple_MCTSSetChild = {
   if ( slot == 0.000 ) mcts_child0[node] = val;
   else if ( slot == 1.000 ) mcts_child1[node] = val;
   else if ( slot == 2.000 ) mcts_child2[node] = val;
   else mcts_child3[node] = val;
};

void (float idx, vector pos, vector vel, float air, float flags, float parent, float depth) Ripple_MCTSInitNode = {
   mcts_pos[idx] = pos;
   mcts_vel[idx] = vel;
   mcts_air[idx] = air;
   mcts_flags[idx] = flags;
   mcts_health[idx] = 0.000;
   mcts_armor[idx] = 0.000;
   mcts_parent[idx] = parent;
   mcts_depth[idx] = depth;
   mcts_reward[idx] = 0.000;
   mcts_visits[idx] = 0.000;
   mcts_child0[idx] = -1.000;
   mcts_child1[idx] = -1.000;
   mcts_child2[idx] = -1.000;
   mcts_child3[idx] = -1.000;
};

float (float node) Ripple_MCTSHasUnexpanded = {
   if ( mcts_child0[node] < 0.000 ) return ( TRUE );
   if ( mcts_child1[node] < 0.000 ) return ( TRUE );
   if ( mcts_child2[node] < 0.000 ) return ( TRUE );
   if ( mcts_child3[node] < 0.000 ) return ( TRUE );
   return ( FALSE );
};

float (float root) Ripple_MCTSSelect = {
   local float node;
   local float best;
   local float best_score;
   local float c;
   local float child;
   local float score;
   local float cv;
   local float exploit;
   local float explore;
   local float guard;

   node = root;
   guard = 0.000;
   while ( guard < 64.000 ) {
      if ( mcts_visits[node] <= 0.000 ) {
         return node;
      }
      if ( (mcts_next_node < MCTS_NODES) && Ripple_MCTSHasUnexpanded (node) ) {
         return node;
      }

      best = -1.000;
      best_score = RIPPLE_NEG;
      c = 0.000;
      while ( c < MCTS_CHILDREN ) {
         child = Ripple_MCTSGetChild (node, c);
         if ( child >= 0.000 ) {
            cv = mcts_visits[child];
            if ( cv <= 0.000 ) {
               score = 999999.000;
            } else {
               exploit = (mcts_reward[child] / cv);
               explore = (MCTS_UCT_C / (cv + 1.000));
               score = (exploit + explore);
            }
            if ( score > best_score ) {
               best_score = score;
               best = child;
            }
         }
         c = (c + TRUE);
      }
      if ( best < 0.000 ) {
         return node;
      }
      node = best;
      guard = (guard + TRUE);
   }
   return node;
};

float (float node) Ripple_MCTSExpand = {
   local float created;
   local float a;
   local float child;
   local vector pos;
   local vector vel;
   local float air;
   local float flags;
   local float blocked;

   created = 0.000;
   a = 0.000;
   while ( a < MCTS_CHILDREN ) {
      if ( mcts_next_node >= MCTS_NODES ) {
         return (created > 0.000);
      }
      child = Ripple_MCTSGetChild (node, a);
      if ( child < 0.000 ) {
         pos = mcts_pos[node];
         vel = mcts_vel[node];
         air = mcts_air[node];
         flags = mcts_flags[node];
         blocked = FALSE;

         if ( a == 0.000 ) {
            ShadowSimStep (pos, vel, air, 0.000, mcts_fwd, mcts_rgt, TRUE);
            pos = sp_out_pos;
            vel = sp_out_vel;
            air = sp_out_air;
            blocked = sp_out_blocked;
         } else if ( a == 3.000 ) {
            vel = (vel * 0.500);
         } else {
            vel = (vel * 0.700);
         }

         if ( (vlen (pos - mcts_probe_pos) < RIPPLE_ACTION_RANGE) ) {
            if ( (a == 1.000) && (mcts_rtype == RIPPLE_TYPE_SHOOT) ) {
               flags = (flags | FLAG_DOOR_OPEN);
            } else if ( (a == 2.000) && (mcts_rtype == RIPPLE_TYPE_TOUCH) ) {
               flags = (flags | FLAG_PLAT_RAISED);
            }
         }

         if ( blocked ) {
            // Mild penalty for immediately blocked expansion
            flags = (flags + 0.000);
         }

         Ripple_MCTSInitNode (mcts_next_node, pos, vel, air, flags, node, (mcts_depth[node] + TRUE));
         Ripple_MCTSSetChild (node, a, mcts_next_node);
         mcts_next_node = (mcts_next_node + TRUE);
         created = (created + TRUE);
      }
      a = (a + TRUE);
   }

   return (created > 0.000);
};

float (float node) Ripple_MCTSRollout = {
   local vector pos;
   local vector vel;
   local float air;
   local float flags;
   local float reward;
   local float step;
   local float a;
   local float blocked;
   local float r;

   pos = mcts_pos[node];
   vel = mcts_vel[node];
   air = mcts_air[node];
   flags = mcts_flags[node];
   reward = 0.000;

   step = 0.000;
   while ( step < MCTS_ROLL_DEPTH ) {
      a = floor (random () * 4.000);
      blocked = FALSE;

      if ( a == 0.000 ) {
         ShadowSimStep (pos, vel, air, 0.000, mcts_fwd, mcts_rgt, TRUE);
         pos = sp_out_pos;
         vel = sp_out_vel;
         air = sp_out_air;
         blocked = sp_out_blocked;
      } else if ( a == 3.000 ) {
         vel = (vel * 0.500);
      } else {
         vel = (vel * 0.700);
      }

      if ( (vlen (pos - mcts_probe_pos) < RIPPLE_ACTION_RANGE) ) {
         if ( (a == 1.000) && (mcts_rtype == RIPPLE_TYPE_SHOOT) ) {
            flags = (flags | FLAG_DOOR_OPEN);
         } else if ( (a == 2.000) && (mcts_rtype == RIPPLE_TYPE_TOUCH) ) {
            flags = (flags | FLAG_PLAT_RAISED);
         }
      }

      r = ShadowReward (pos, vel, air, mcts_goal_pos, TRUE, blocked, 1.000, 1.000);
      reward = (reward + r);
      if ( (flags & (FLAG_DOOR_OPEN + FLAG_PLAT_RAISED)) == 0.000 ) {
         reward = (reward - 50.000);
      } else {
         reward = (reward + 10.000);
      }
      if ( reward < -200.000 ) {
         break;
      }
      step = (step + TRUE);
   }

   if ( (flags > 0.000) && (reward > mcts_best_reward) ) {
      mcts_best_reward = reward;
      mcts_best_flags = flags;
      mcts_best_pos = pos;
      mcts_best_depth = (mcts_depth[node] + step);
   }

   return reward;
};

void (float node, float reward) Ripple_MCTSBackprop = {
   while ( node >= 0.000 ) {
      mcts_visits[node] = (mcts_visits[node] + TRUE);
      mcts_reward[node] = (mcts_reward[node] + reward);
      node = mcts_parent[node];
   }
};

float (vector probe_pos, vector goal_pos, float rtype) Ripple_MaelstromMCTS = {
   local float iters;
   local float iter;
   local float node;
   local float rollout_r;
   local float best_child;
   local float best_val;
   local float c;
   local float child;
   local float val;
   local float entry;
   local float post;
   local float air_left;
   local float goal_node;
   local float iter_used;

   goal_node = Vortex_FindNode (goal_pos);
   if ( (mcts_last_probe > 0.000) && (time < (mcts_last_probe + MCTS_THROTTLE)) && (goal_node == mcts_last_goal_node) && (goal_node >= 0.000) ) {
      return ( mcts_last_success );
   }

   mcts_last_probe = time;
   mcts_last_goal_node = goal_node;
   mcts_last_success = FALSE;
   mcts_best_reward = RIPPLE_NEG;
   mcts_best_flags = 0.000;
   mcts_best_pos = self.origin;
   mcts_best_depth = 0.000;

   mcts_goal_pos = goal_pos;
   mcts_probe_pos = probe_pos;
   mcts_rtype = rtype;

   mcts_fwd = normalize (goal_pos - self.origin);
   if ( (vlen (mcts_fwd) < 0.010) ) {
      mcts_fwd = '1 0 0';
   }
   mcts_rgt_x = -mcts_fwd_y;
   mcts_rgt_y = mcts_fwd_x;
   mcts_rgt_z = 0.000;
   mcts_rgt = normalize (mcts_rgt);

   air_left = (self.air_finished - time);
   if ( (air_left < FALSE) ) air_left = FALSE;
   if ( (air_left > 12.000) ) air_left = 12.000;

   mcts_root = 0.000;
   mcts_next_node = 1.000;
   Ripple_MCTSInitNode (mcts_root, self.origin, '0 0 0', air_left, 0.000, -1.000, 0.000);

   iters = (MCTS_ITER_BASE + floor (self.skil * MCTS_ITER_PER_SKILL));
   if ( (vlen (probe_pos - self.origin) > 192.000) ) {
      iters = (iters + 50.000);
   }
   if ( iters > MCTS_ITER_MAX ) {
      iters = MCTS_ITER_MAX;
   }
   if ( iters < 1.000 ) {
      iters = 1.000;
   }

   iter = 0.000;
   while ( iter < iters ) {
      node = Ripple_MCTSSelect (mcts_root);
      if ( Ripple_MCTSExpand (node) ) {
         rollout_r = Ripple_MCTSRollout (node);
         Ripple_MCTSBackprop (node, rollout_r);
      } else {
         rollout_r = Ripple_MCTSRollout (node);
         Ripple_MCTSBackprop (node, rollout_r);
      }
      if ( (mcts_visits[mcts_root] > MCTS_EARLY_VISITS) && (mcts_best_reward > MCTS_EARLY_REWARD) ) {
         break;
      }
      iter = (iter + TRUE);
   }

   best_child = -1.000;
   best_val = RIPPLE_NEG;
   c = 0.000;
   while ( c < MCTS_CHILDREN ) {
      child = Ripple_MCTSGetChild (mcts_root, c);
      if ( (child >= 0.000) && (mcts_visits[child] > 0.000) ) {
         val = (mcts_reward[child] / mcts_visits[child]);
         if ( val > best_val ) {
            best_val = val;
            best_child = child;
         }
      }
      c = (c + TRUE);
   }

   if ( (best_child >= 0.000) && (mcts_best_reward > MCTS_SUCCESS_REWARD) && (mcts_best_flags > 0.000) ) {
      entry = Vortex_FindNode (probe_pos);
      if ( entry < 0.000 ) {
         if ( vortex_count < VORTEX_MAX_NODES ) {
            entry = Vortex_AddNode (probe_pos, VORTEX_NODE_GROUND);
            Vortex_LinkNearby (entry);
         }
      }
      post = Vortex_FindNode (mcts_best_pos);
      if ( post < 0.000 ) {
         if ( vortex_count < VORTEX_MAX_NODES ) {
            post = Vortex_AddNode (mcts_best_pos, VORTEX_NODE_GROUND);
            Vortex_LinkNearby (post);
         }
      }
      if ( (entry >= 0.000) && (post >= 0.000) ) {
         iter_used = iter;
         if ( iter_used < 1.000 ) iter_used = 1.000;
         vortex_ripple_type[entry] = rtype;
         vortex_ripple_target[entry] = post;
         vortex_ripple_cost[entry] = (mcts_visits[best_child] / iter_used);
         vortex_ripple_steps[entry] = mcts_best_depth;
         if ( vortex_ripple_steps[entry] < 1.000 ) vortex_ripple_steps[entry] = 1.000;
         vortex_ripple_flags[entry] = mcts_best_flags;
         vortex_ripple_pos[entry] = probe_pos;
         Vortex_AddEdgeOneWay (entry, post);
         Vortex_BoostUsage (entry, 5.000);
         mcts_last_success = TRUE;
      }
   }

   return ( mcts_last_success );
};

float (float armor) Quantum_ArmorScale = {
   local float scale;
   scale = (1.000 - (armor / 100.000));
   if ( scale < 0.400 ) {
      scale = 0.400;
   }
   if ( scale > 1.000 ) {
      scale = 1.000;
   }
   return scale;
};

float (float armor) Quantum_RJDamage = {
   return (RJ_DAMAGE * Quantum_ArmorScale (armor));
};

float (float armor) Quantum_GJDamage = {
   return (GJ_DAMAGE * Quantum_ArmorScale (armor));
};

float (float armor) Quantum_GLJDamage = {
   return (GLJ_DAMAGE * Quantum_ArmorScale (armor));
};

float (float purpose, float vtype) Quantum_HorizCoeff = {
   if ( purpose == RJ_PURPOSE_LAVA ) {
      if ( vtype == 0.000 ) return 1.400; // Fwd
      if ( vtype == 1.000 ) return 1.000; // Strafe
      if ( vtype == 2.000 ) return 0.800; // Back
      return 1.100; // Wait
   }
   if ( purpose == RJ_PURPOSE_VAULT ) {
      if ( vtype == 0.000 ) return 1.100;
      if ( vtype == 1.000 ) return 1.000;
      if ( vtype == 2.000 ) return 0.900;
      return 1.000;
   }
   if ( purpose == RJ_PURPOSE_HIGH ) {
      if ( vtype == 0.000 ) return 1.000;
      if ( vtype == 1.000 ) return 1.000;
      if ( vtype == 2.000 ) return 1.200;
      return 1.000;
   }
   // Flat default
   if ( vtype == 0.000 ) return 1.200;
   if ( vtype == 1.000 ) return 1.100;
   if ( vtype == 2.000 ) return 0.900;
   return 1.000;
};

float (float purpose, float vtype) Quantum_VertCoeff = {
   if ( purpose == RJ_PURPOSE_LAVA ) {
      if ( vtype == 1.000 ) return 1.000;
      return 1.000;
   }
   if ( purpose == RJ_PURPOSE_VAULT ) {
      if ( vtype == 1.000 ) return 1.500; // Strafe vault
      return 1.200;
   }
   if ( purpose == RJ_PURPOSE_HIGH ) {
      if ( vtype == 2.000 ) return 1.400; // Back climb
      return 1.300;
   }
   return 1.100;
};

float (float purpose, float right_bias) Quantum_AirMult = {
   if ( purpose == RJ_PURPOSE_LAVA ) {
      if ( right_bias > 0.000 ) return 1.300;
      return 1.000;
   }
   if ( purpose == RJ_PURPOSE_VAULT ) {
      if ( right_bias > 0.000 ) return 1.100;
      return 1.200;
   }
   if ( purpose == RJ_PURPOSE_HIGH ) {
      return 1.100;
   }
   return 1.000;
};

float (float purpose, float vtype) Quantum_GJHorizCoeff = {
   local float base;
   base = 1.000;
   if ( purpose == RJ_PURPOSE_LAVA ) {
      if ( vtype == 0.000 ) base = 1.500; // Fwd
      else if ( vtype == 1.000 ) base = 1.100; // Str
      else if ( vtype == 2.000 ) base = 0.900; // Back
      else base = 1.000; // Up
   } else if ( purpose == RJ_PURPOSE_VAULT ) {
      if ( vtype == 0.000 ) base = 1.200;
      else if ( vtype == 1.000 ) base = 1.000;
      else if ( vtype == 2.000 ) base = 1.100;
      else base = 0.900;
   } else if ( purpose == RJ_PURPOSE_HIGH ) {
      if ( vtype == 0.000 ) base = 1.000;
      else if ( vtype == 1.000 ) base = 1.500;
      else if ( vtype == 2.000 ) base = 1.600;
      else base = 0.800;
   } else {
      if ( vtype == 0.000 ) base = 1.200;
      else if ( vtype == 1.000 ) base = 1.000;
      else if ( vtype == 2.000 ) base = 0.900;
      else base = 0.800;
   }
   if ( (purpose >= 0.000) && (purpose <= RJ_PURPOSE_FLAT) ) {
      base = (base + gj_horiz_tune[purpose]);
   }
   if ( base < 0.600 ) base = 0.600;
   if ( base > 2.000 ) base = 2.000;
   return base;
};

float (float purpose, float vtype) Quantum_GJVertCoeff = {
   local float base;
   base = 1.000;
   if ( purpose == RJ_PURPOSE_LAVA ) {
      if ( vtype == 3.000 ) base = 1.200;
      else base = 1.000;
   } else if ( purpose == RJ_PURPOSE_VAULT ) {
      if ( (vtype == 1.000) || (vtype == 3.000) ) base = 1.700;
      else base = 1.200;
   } else if ( purpose == RJ_PURPOSE_HIGH ) {
      if ( (vtype == 2.000) || (vtype == 3.000) ) base = 1.500;
      else base = 1.300;
   } else {
      if ( vtype == 3.000 ) base = 1.300;
      else base = 1.100;
   }
   if ( (purpose >= 0.000) && (purpose <= RJ_PURPOSE_FLAT) ) {
      base = (base + gj_vert_tune[purpose]);
   }
   if ( base < 0.800 ) base = 0.800;
   if ( base > 2.200 ) base = 2.200;
   return base;
};

float (float purpose, float right_bias) Quantum_GJAirMult = {
   if ( purpose == RJ_PURPOSE_LAVA ) {
      if ( right_bias > 0.000 ) return 1.250;
      return 0.850;
   }
   if ( purpose == RJ_PURPOSE_VAULT ) {
      if ( right_bias > 0.000 ) return 1.100;
      return 1.250;
   }
   if ( purpose == RJ_PURPOSE_HIGH ) {
      return 1.150;
   }
   return 1.000;
};

float (float purpose) Quantum_GJBounceMult = {
   local float base;
   if ( purpose == RJ_PURPOSE_LAVA ) return 0.650;
   if ( purpose == RJ_PURPOSE_VAULT ) return 0.800;
   if ( purpose == RJ_PURPOSE_HIGH ) return 0.700;
   base = 0.700;
   return base;
};

float (float purpose, float vtype) Quantum_GLHorizCoeff = {
   local float base;
   // Approx cos for 42/48/35/68 degrees
   if ( vtype == 0.000 ) base = 0.743;
   else if ( vtype == 1.000 ) base = 0.669;
   else if ( vtype == 2.000 ) base = 0.819;
   else base = 0.374;
   if ( purpose == RJ_PURPOSE_VAULT ) base = (base * 0.950);
   if ( purpose == RJ_PURPOSE_HIGH ) base = (base * 0.900);
   if ( (purpose >= 0.000) && (purpose <= RJ_PURPOSE_FLAT) ) {
      base = (base - (glj_angle_tune[purpose] * 0.500));
   }
   if ( base < 0.200 ) base = 0.200;
   return base;
};

float (float purpose, float vtype) Quantum_GLVertCoeff = {
   local float base;
   // Approx sin for 42/48/35/68 degrees
   if ( vtype == 0.000 ) base = 0.669;
   else if ( vtype == 1.000 ) base = 0.743;
   else if ( vtype == 2.000 ) base = 0.574;
   else base = 0.927;
   if ( purpose == RJ_PURPOSE_VAULT ) base = (base * 1.050);
   if ( purpose == RJ_PURPOSE_HIGH ) base = (base * 1.100);
   if ( (purpose >= 0.000) && (purpose <= RJ_PURPOSE_FLAT) ) {
      base = (base + glj_angle_tune[purpose]);
   }
   if ( base < 0.400 ) base = 0.400;
   if ( base > 1.300 ) base = 1.300;
   return base;
};

float (float purpose) Quantum_GLJBounceMult = {
   if ( purpose == RJ_PURPOSE_LAVA ) return 0.720;
   if ( purpose == RJ_PURPOSE_VAULT ) return 0.780;
   if ( purpose == RJ_PURPOSE_HIGH ) return 0.740;
   return 0.750;
};

float (float slot, float node) Quantum_RJActionForSlot = {
   local float parity;
   parity = (node - (floor (node / 2.000) * 2.000));
   if ( slot == 0.000 ) {
      if ( parity == 0.000 ) return RJ_ACTION_BASE;      // FwdL
      return (RJ_ACTION_BASE + 1.000);                                // FwdR
   }
   if ( slot == 1.000 ) {
      if ( parity == 0.000 ) return (RJ_ACTION_BASE + 4.000); // StrL
      return (RJ_ACTION_BASE + 5.000);                                   // StrR
   }
   if ( slot == 2.000 ) {
      if ( parity == 0.000 ) return (RJ_ACTION_BASE + 2.000); // BkL
      return (RJ_ACTION_BASE + 3.000);                                   // BkR
   }
   if ( parity == 0.000 ) return (RJ_ACTION_BASE + 6.000); // WaitL
   return (RJ_ACTION_BASE + 7.000);                                     // WaitR
};

float (float slot, float node) Quantum_GJActionForSlot = {
   local float parity;
   parity = (node - (floor (node / 2.000) * 2.000));
   return (GJ_ACTION_BASE + (slot * 2.000) + parity);
};

float (float slot, float node) Quantum_GLJActionForSlot = {
   local float parity;
   parity = (node - (floor (node / 2.000) * 2.000));
   return (GLJ_ACTION_BASE + (slot * 2.000) + parity);
};

void (vector pos, vector vel, float air_left, float action_id, vector fwd, vector rgt, float purpose) Quantum_RJSimStep = {
   local vector impulse;
   local vector strafe_dir;
   local vector newpos;
   local float horiz_c;
   local float vert_c;
   local float air_mult;
   local float contents;
   local float rj_var;
   local float right_bias;
   local float wait_scale;

   impulse = '0 0 0';
   wait_scale = 1.000;

   if ( action_id >= RJ_ACTION_BASE ) {
      rj_var = 0.000;
      if ( (action_id == (RJ_ACTION_BASE + 4.000)) || (action_id == (RJ_ACTION_BASE + 5.000)) ) {
         rj_var = 1.000;
      } else if ( (action_id == (RJ_ACTION_BASE + 2.000)) || (action_id == (RJ_ACTION_BASE + 3.000)) ) {
         rj_var = 2.000;
      } else if ( (action_id == (RJ_ACTION_BASE + 6.000)) || (action_id == (RJ_ACTION_BASE + 7.000)) ) {
         rj_var = 3.000;
         wait_scale = 0.750;
      }

      if ( (action_id == RJ_ACTION_BASE) || (action_id == (RJ_ACTION_BASE + 2.000)) || (action_id == (RJ_ACTION_BASE + 4.000)) || (action_id == (RJ_ACTION_BASE + 6.000)) ) {
         strafe_dir = (rgt * -1.000);
         right_bias = 0.000;
      } else {
         strafe_dir = rgt;
         right_bias = 1.000;
      }

      horiz_c = Quantum_HorizCoeff (purpose, rj_var);
      vert_c = Quantum_VertCoeff (purpose, rj_var);
      air_mult = Quantum_AirMult (purpose, right_bias);

      impulse = (fwd * horiz_c) + (strafe_dir * 1.200) + ('0 0 1' * vert_c);
      impulse = normalize (impulse);
      vel = (vel + (impulse * RJ_IMPULSE * wait_scale));
      vel_z = (vel_z + 272.000);

      // Small post-RJ air-strafe bias
      vel = (vel + (strafe_dir * (80.000 * air_mult)));
   }

   // Basic accel + gravity (mirrors ShadowSimStep style)
   vel = (vel * 0.900);
   vel_z = (vel_z - SHADOW_GRAVITY);

   newpos = (pos + (vel * SHADOW_DT));
   sp_out_blocked = FALSE;

   traceline ((pos + '0 0 16'), (newpos + '0 0 16'), TRUE, self);
   if ( (trace_fraction < TRUE) ) {
      newpos = (trace_endpos - '0 0 16');
      vel = '0 0 0';
      sp_out_blocked = TRUE;
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

   sp_out_pos = newpos;
   sp_out_vel = vel;
   sp_out_air = air_left;
};

vector (vector start_pos, vector start_vel, float fuse_time, float steps, float bounce_damp, float max_bounces) Quantum_GrenadeExplodePos = {
   local vector pos;
   local vector vel;
   local vector next;
   local float step;
   local float dt;
   local float decay;
   local float bounces;
   local float dotv;

   pos = start_pos;
   vel = start_vel;
   if ( steps < 1.000 ) steps = 1.000;
   dt = (fuse_time / steps);
   if ( dt <= 0.000 ) dt = SHADOW_DT;
   decay = (0.400 / steps);
   if ( decay < 0.000 ) decay = 0.000;
   if ( bounce_damp < 0.200 ) bounce_damp = 0.200;
   if ( bounce_damp > 0.900 ) bounce_damp = 0.900;

   bounces = 0.000;
   step = 0.000;
   while ( step < steps ) {
      vel = (vel * (1.000 - decay));
      vel_z = (vel_z - (SHADOW_GRAVITY * (dt / SHADOW_DT)));
      next = (pos + (vel * dt));
      traceline (pos, next, TRUE, self);
      if ( trace_fraction < 1.000 ) {
         pos = trace_endpos;
         dotv = (vel_x * trace_plane_normal_x) + (vel_y * trace_plane_normal_y) + (vel_z * trace_plane_normal_z);
         vel = (vel - (trace_plane_normal * (2.000 * dotv)));
         vel = (vel * bounce_damp);
         bounces = (bounces + TRUE);
         if ( (max_bounces >= 0.000) && (bounces >= max_bounces) ) {
            break;
         }
      } else {
         pos = next;
      }
      step = (step + TRUE);
   }
   return pos;
};

vector (vector pos, vector fwd, vector rgt, float purpose, float action_id) Quantum_GJImpulse = {
   local float idx;
   local float gj_var;
   local float parity;
   local vector strafe_dir;
   local float horiz_c;
   local float vert_c;
   local vector gren_dir;
   local vector gren_pos;
   local vector gren_vel;
   local vector explode_pos;
   local vector impulse;

   idx = (action_id - GJ_ACTION_BASE);
   if ( idx < 0.000 ) idx = 0.000;
   gj_var = floor (idx / 2.000);
   parity = (idx - (gj_var * 2.000));
   if ( parity == 0.000 ) {
      strafe_dir = (rgt * -1.000);
   } else {
      strafe_dir = rgt;
   }

   horiz_c = Quantum_GJHorizCoeff (purpose, gj_var);
   vert_c = Quantum_GJVertCoeff (purpose, gj_var);
   gren_dir = (fwd * horiz_c) + (strafe_dir * 1.100) + ('0 0 1' * vert_c);
   if ( vlen (gren_dir) < 0.010 ) gren_dir = fwd;
   gren_dir = normalize (gren_dir);

   gren_pos = pos + (fwd * 16.000) + '0 0 32';
   gren_vel = (gren_dir * GJ_THROW_SPEED);
   explode_pos = Quantum_GrenadeExplodePos (gren_pos, gren_vel, GJ_FUSE_TIME, GJ_SIM_STEPS, GJ_BOUNCE_DAMP, 3.000);

   impulse = normalize (pos - explode_pos);
   if ( vlen (impulse) < 0.010 ) impulse = '0 0 1';
   impulse = (impulse * (GJ_IMPULSE * Quantum_GJBounceMult (purpose)));
   return impulse;
};

vector (vector pos, vector fwd, vector rgt, float purpose, float action_id) Quantum_GLJImpulse = {
   local float idx;
   local float glj_var;
   local float parity;
   local vector strafe_dir;
   local float horiz_c;
   local float vert_c;
   local vector gren_dir;
   local vector gren_pos;
   local vector gren_vel;
   local vector explode_pos;
   local vector impulse;
   local float max_bounces;

   idx = (action_id - GLJ_ACTION_BASE);
   if ( idx < 0.000 ) idx = 0.000;
   glj_var = floor (idx / 2.000);
   parity = (idx - (glj_var * 2.000));
   if ( parity == 0.000 ) {
      strafe_dir = (rgt * -1.000);
   } else {
      strafe_dir = rgt;
   }

   horiz_c = Quantum_GLHorizCoeff (purpose, glj_var);
   vert_c = Quantum_GLVertCoeff (purpose, glj_var);
   gren_dir = (fwd * horiz_c) + (strafe_dir * 0.600) + ('0 0 1' * vert_c);
   if ( vlen (gren_dir) < 0.010 ) gren_dir = fwd;
   gren_dir = normalize (gren_dir);

   max_bounces = 2.000;
   if ( glj_var == 2.000 ) max_bounces = 1.000;
   if ( glj_var == 3.000 ) max_bounces = 1.000;

   gren_pos = pos + '0 0 24';
   gren_vel = (gren_dir * GLJ_THROW_SPEED);
   explode_pos = Quantum_GrenadeExplodePos (gren_pos, gren_vel, GLJ_FUSE_TIME, GLJ_SIM_STEPS, GLJ_BOUNCE_DAMP, max_bounces);

   impulse = normalize (pos - explode_pos);
   if ( vlen (impulse) < 0.010 ) impulse = '0 0 1';
   impulse = (impulse * (GLJ_IMPULSE * Quantum_GLJBounceMult (purpose)));
   return impulse;
};

void (vector pos, vector vel, float air_left, float action_id, vector fwd, vector rgt, float purpose) Quantum_GJSimStep = {
   local float idx;
   local float gj_var;
   local float parity;
   local vector strafe_dir;
   local float right_bias;
   local vector impulse;
   local float air_mult;
   local vector newpos;
   local float contents;

   idx = (action_id - GJ_ACTION_BASE);
   if ( idx < 0.000 ) idx = 0.000;
   gj_var = floor (idx / 2.000);
   parity = (idx - (gj_var * 2.000));
   if ( parity == 0.000 ) {
      strafe_dir = (rgt * -1.000);
      right_bias = 0.000;
   } else {
      strafe_dir = rgt;
      right_bias = 1.000;
   }

   impulse = Quantum_GJImpulse (pos, fwd, rgt, purpose, action_id);
   vel = (vel + impulse);

   air_mult = Quantum_GJAirMult (purpose, right_bias);
   vel = (vel + (strafe_dir * (80.000 * air_mult)));

   vel = (vel * 0.900);
   vel_z = (vel_z - SHADOW_GRAVITY);

   newpos = (pos + (vel * SHADOW_DT));
   sp_out_blocked = FALSE;

   traceline ((pos + '0 0 16'), (newpos + '0 0 16'), TRUE, self);
   if ( (trace_fraction < TRUE) ) {
      newpos = (trace_endpos - '0 0 16');
      vel = '0 0 0';
      sp_out_blocked = TRUE;
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

   sp_out_pos = newpos;
   sp_out_vel = vel;
   sp_out_air = air_left;
};

void (vector pos, vector vel, float air_left, float action_id, vector fwd, vector rgt, float purpose) Quantum_GLJSimStep = {
   local float idx;
   local float glj_var;
   local float parity;
   local vector strafe_dir;
   local float right_bias;
   local vector impulse;
   local float air_mult;
   local vector newpos;
   local float contents;

   idx = (action_id - GLJ_ACTION_BASE);
   if ( idx < 0.000 ) idx = 0.000;
   glj_var = floor (idx / 2.000);
   parity = (idx - (glj_var * 2.000));
   if ( parity == 0.000 ) {
      strafe_dir = (rgt * -1.000);
      right_bias = 0.000;
   } else {
      strafe_dir = rgt;
      right_bias = 1.000;
   }

   impulse = Quantum_GLJImpulse (pos, fwd, rgt, purpose, action_id);
   vel = (vel + impulse);
   vel_z = (vel_z + 272.000);

   air_mult = Quantum_GJAirMult (purpose, right_bias);
   vel = (vel + (strafe_dir * (80.000 * air_mult)));

   vel = (vel * 0.900);
   vel_z = (vel_z - SHADOW_GRAVITY);

   newpos = (pos + (vel * SHADOW_DT));
   sp_out_blocked = FALSE;

   traceline ((pos + '0 0 16'), (newpos + '0 0 16'), TRUE, self);
   if ( (trace_fraction < TRUE) ) {
      newpos = (trace_endpos - '0 0 16');
      vel = '0 0 0';
      sp_out_blocked = TRUE;
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

   sp_out_pos = newpos;
   sp_out_vel = vel;
   sp_out_air = air_left;
};

float (float action_id) Quantum_LeapMinHealth = {
   if ( action_id >= GLJ_ACTION_BASE ) return GLJ_MIN_HEALTH;
   if ( action_id >= GJ_ACTION_BASE ) return GJ_MIN_HEALTH;
   return RJ_MIN_HEALTH;
};

float (float armor, float action_id) Quantum_LeapDamage = {
   if ( action_id >= GLJ_ACTION_BASE ) return Quantum_GLJDamage (armor);
   if ( action_id >= GJ_ACTION_BASE ) return Quantum_GJDamage (armor);
   return Quantum_RJDamage (armor);
};

void (vector pos, vector vel, float air_left, float action_id, vector fwd, vector rgt, float purpose) Quantum_LeapSimStep = {
   if ( action_id >= GLJ_ACTION_BASE ) {
      Quantum_GLJSimStep (pos, vel, air_left, action_id, fwd, rgt, purpose);
      return;
   }
   if ( action_id >= GJ_ACTION_BASE ) {
      Quantum_GJSimStep (pos, vel, air_left, action_id, fwd, rgt, purpose);
      return;
   }
   Quantum_RJSimStep (pos, vel, air_left, action_id, fwd, rgt, purpose);
};

float (float purpose) Quantum_LeapPickType = {
   local float rj_w;
   local float gj_w;
   local float glj_w;
   local float sum;
   local float pick;
   local float has_rj;
   local float has_gj;

   has_rj = ((self.items & IT_ROCKET_LAUNCHER) && (self.ammo_rockets >= TRUE));
   has_gj = ((self.items & IT_GRENADE_LAUNCHER) && (self.ammo_rockets >= TRUE));

   rj_w = 0.000;
   gj_w = 0.000;
   glj_w = 0.000;

   if ( has_rj && (self.health >= RJ_MIN_HEALTH) ) {
      rj_w = 0.600;
   }
   if ( has_gj && (self.health >= GJ_MIN_HEALTH) ) {
      gj_w = 0.250;
      glj_w = 0.250;
   }

   if ( self.ammo_rockets < 3.000 ) {
      rj_w = (rj_w * 0.350);
      gj_w = (gj_w * 1.600);
      glj_w = (glj_w * 1.300);
   }
   if ( purpose == RJ_PURPOSE_LAVA ) {
      gj_w = (gj_w * 1.400);
      glj_w = (glj_w * 0.800);
   } else if ( purpose == RJ_PURPOSE_VAULT ) {
      glj_w = (glj_w * 1.400);
   } else if ( purpose == RJ_PURPOSE_HIGH ) {
      glj_w = (glj_w * 1.200);
   }

   sum = (rj_w + gj_w + glj_w);
   if ( sum <= 0.000 ) {
      return LEAP_TYPE_RJ;
   }
   pick = (random () * sum);
   if ( pick < rj_w ) return LEAP_TYPE_RJ;
   if ( pick < (rj_w + gj_w) ) return LEAP_TYPE_GJ;
   return LEAP_TYPE_GLJ;
};

float (float purpose) Quantum_LeapBestType = {
   local float rj_w;
   local float gj_w;
   local float glj_w;
   local float best;
   local float best_type;
   local float has_rj;
   local float has_gj;

   has_rj = ((self.items & IT_ROCKET_LAUNCHER) && (self.ammo_rockets >= TRUE));
   has_gj = ((self.items & IT_GRENADE_LAUNCHER) && (self.ammo_rockets >= TRUE));

   rj_w = 0.000;
   gj_w = 0.000;
   glj_w = 0.000;

   if ( has_rj && (self.health >= RJ_MIN_HEALTH) ) {
      rj_w = 0.600;
   }
   if ( has_gj && (self.health >= GJ_MIN_HEALTH) ) {
      gj_w = 0.250;
      glj_w = 0.250;
   }

   if ( self.ammo_rockets < 3.000 ) {
      rj_w = (rj_w * 0.350);
      gj_w = (gj_w * 1.600);
      glj_w = (glj_w * 1.300);
   }
   if ( purpose == RJ_PURPOSE_LAVA ) {
      gj_w = (gj_w * 1.400);
      glj_w = (glj_w * 0.800);
   } else if ( purpose == RJ_PURPOSE_VAULT ) {
      glj_w = (glj_w * 1.400);
   } else if ( purpose == RJ_PURPOSE_HIGH ) {
      glj_w = (glj_w * 1.200);
   }

   best = rj_w;
   best_type = LEAP_TYPE_RJ;
   if ( gj_w > best ) {
      best = gj_w;
      best_type = LEAP_TYPE_GJ;
   }
   if ( glj_w > best ) {
      best = glj_w;
      best_type = LEAP_TYPE_GLJ;
   }
   return best_type;
};

float (float slot, float node, float purpose) Quantum_LeapActionForSlot = {
   local float ltype;
   ltype = Quantum_LeapPickType (purpose);
   if ( ltype == LEAP_TYPE_GJ ) return Quantum_GJActionForSlot (slot, node);
   if ( ltype == LEAP_TYPE_GLJ ) return Quantum_GLJActionForSlot (slot, node);
   return Quantum_RJActionForSlot (slot, node);
};

float (float purpose) Quantum_LeapPickAction = {
   local float ltype;
   local float action_id;

   ltype = Quantum_LeapPickType (purpose);
   if ( ltype == LEAP_TYPE_GJ ) {
      action_id = (GJ_ACTION_BASE + floor (random () * GJ_ACTIONS));
      return action_id;
   }
   if ( ltype == LEAP_TYPE_GLJ ) {
      action_id = (GLJ_ACTION_BASE + floor (random () * GLJ_ACTIONS));
      return action_id;
   }
   action_id = (RJ_ACTION_BASE + floor (random () * RJ_ACTIONS));
   return action_id;
};

float (vector start_pos, vector goal_pos) Quantum_LeapPurpose = {
   local vector delta;
   local vector flat;
   local vector mid;
   local float vert;
   local float horiz;
   local float purpose;

   delta = (goal_pos - start_pos);
   vert = fabs (delta_z);
   flat = delta;
   flat_z = 0.000;
   horiz = vlen (flat);

   mid = start_pos;
   if ( vlen (delta) > 0.010 ) {
      mid = (start_pos + (normalize (delta) * 128.000));
   }

   purpose = RJ_PURPOSE_FLAT;
   if ( (pointcontents (mid) == CONTENT_LAVA) || (pointcontents (mid) == CONTENT_SLIME) ) {
      purpose = RJ_PURPOSE_LAVA;
   } else if ( vert > (horiz * 0.500) ) {
      purpose = RJ_PURPOSE_VAULT;
   } else if ( vert > 256.000 ) {
      purpose = RJ_PURPOSE_HIGH;
   }
   return purpose;
};

float (float node) Quantum_MCTSSelect = {
   return Ripple_MCTSSelect (node);
};

float (float node, float purpose) Quantum_MCTSExpand = {
   local float created;
   local float a;
   local float action_id;
   local vector pos;
   local vector vel;
   local float air;
   local float flags;
   local float health;
   local float armor;
   local float dmg;

   created = 0.000;
   a = 0.000;
   while ( a < MCTS_CHILDREN ) {
      if ( mcts_next_node >= MCTS_NODES ) {
         return (created > 0.000);
      }
      if ( Ripple_MCTSGetChild (node, a) < 0.000 ) {
         action_id = Quantum_LeapActionForSlot (a, node, purpose);
         pos = mcts_pos[node];
         vel = mcts_vel[node];
         air = mcts_air[node];
         flags = mcts_flags[node];
         health = mcts_health[node];
         armor = mcts_armor[node];

         dmg = Quantum_LeapDamage (armor, action_id);
         health = (health - dmg);
         armor = (armor - (dmg * 0.500));
         if ( armor < 0.000 ) armor = 0.000;

         Quantum_LeapSimStep (pos, vel, air, action_id, rj_fwd, rj_rgt, purpose);
         pos = sp_out_pos;
         vel = sp_out_vel;
         air = sp_out_air;

         Ripple_MCTSInitNode (mcts_next_node, pos, vel, air, flags, node, (mcts_depth[node] + TRUE));
         mcts_health[mcts_next_node] = health;
         mcts_armor[mcts_next_node] = armor;
         Ripple_MCTSSetChild (node, a, mcts_next_node);

         if ( health < Quantum_LeapMinHealth (action_id) ) {
            mcts_reward[mcts_next_node] = -500.000;
            mcts_visits[mcts_next_node] = 1.000;
         }

         mcts_next_node = (mcts_next_node + TRUE);
         created = (created + TRUE);
      }
      a = (a + TRUE);
   }

   return (created > 0.000);
};

float (float node, float purpose, float start_dist) Quantum_MCTSRollout = {
   local vector pos;
   local vector vel;
   local float air;
   local float reward;
   local float step;
   local float action_id;
   local float health;
   local float armor;
   local float dmg;
   local float dist;

   pos = mcts_pos[node];
   vel = mcts_vel[node];
   air = mcts_air[node];
   health = mcts_health[node];
   armor = mcts_armor[node];
   reward = 0.000;

   step = 0.000;
   while ( step < MCTS_ROLL_DEPTH ) {
      action_id = Quantum_LeapPickAction (purpose);
      dmg = Quantum_LeapDamage (armor, action_id);
      health = (health - dmg);
      armor = (armor - (dmg * 0.500));
      if ( armor < 0.000 ) armor = 0.000;
      if ( health < Quantum_LeapMinHealth (action_id) ) {
         reward = (reward - 300.000);
         break;
      }

      Quantum_LeapSimStep (pos, vel, air, action_id, rj_fwd, rj_rgt, purpose);
      pos = sp_out_pos;
      vel = sp_out_vel;
      air = sp_out_air;

      dist = vlen (rj_goal_pos - pos);
      reward = (reward + ShadowReward (pos, vel, air, rj_goal_pos, TRUE, sp_out_blocked, 1.000, 1.000));
      reward = (reward + ((start_dist - dist) * 0.250));

      step = (step + TRUE);
   }

   if ( reward > rj_best_reward ) {
      rj_best_reward = reward;
      rj_best_pos = pos;
      rj_best_depth = (mcts_depth[node] + step);
   }
   return reward;
};

void (float node, float reward) Quantum_MCTSBackprop = {
   Ripple_MCTSBackprop (node, reward);
};

float (vector probe_pos, vector goal_pos, float purpose) Quantum_RJMCTS = {
   local float iters;
   local float iter;
   local float node;
   local float rollout_r;
   local float best_child;
   local float best_val;
   local float child;
   local float c;
   local float val;
   local float entry;
   local float post;
   local float air_left;
   local float start_dist;
   local float goal_node;
   local float leap_type;
   local float leap_risk;

   goal_node = Vortex_FindNode (goal_pos);
   if ( (rj_last_probe > 0.000) && (time < (rj_last_probe + RJ_PROBE_THROTTLE)) && (goal_node == rj_last_goal_node) && (goal_node >= 0.000) ) {
      return ( rj_last_success );
   }
   rj_last_probe = time;
   rj_last_goal_node = goal_node;
   rj_last_success = FALSE;

   rj_goal_pos = goal_pos;
   rj_probe_pos = probe_pos;
   rj_best_reward = RIPPLE_NEG;
   rj_best_pos = self.origin;
   rj_best_depth = 0.000;

   rj_fwd = normalize (goal_pos - self.origin);
   if ( (vlen (rj_fwd) < 0.010) ) {
      rj_fwd = '1 0 0';
   }
   rj_rgt_x = -rj_fwd_y;
   rj_rgt_y = rj_fwd_x;
   rj_rgt_z = 0.000;
   rj_rgt = normalize (rj_rgt);

   air_left = (self.air_finished - time);
   if ( (air_left < FALSE) ) air_left = FALSE;
   if ( (air_left > 12.000) ) air_left = 12.000;

   mcts_root = 0.000;
   mcts_next_node = 1.000;
   Ripple_MCTSInitNode (mcts_root, self.origin, self.velocity, air_left, 0.000, -1.000, 0.000);
   mcts_health[mcts_root] = self.health;
   mcts_armor[mcts_root] = self.armorvalue;

   iters = 120.000;
   iters = (iters + floor (self.skil * 12.000));
   if ( iters > 240.000 ) iters = 240.000;

   start_dist = vlen (goal_pos - self.origin);
   iter = 0.000;
   while ( iter < iters ) {
      node = Quantum_MCTSSelect (mcts_root);
      if ( Quantum_MCTSExpand (node, purpose) ) {
         rollout_r = Quantum_MCTSRollout (node, purpose, start_dist);
         Quantum_MCTSBackprop (node, rollout_r);
      } else {
         rollout_r = Quantum_MCTSRollout (node, purpose, start_dist);
         Quantum_MCTSBackprop (node, rollout_r);
      }
      if ( (mcts_visits[mcts_root] > 30.000) && (rj_best_reward > 120.000) ) {
         break;
      }
      iter = (iter + TRUE);
   }

   best_child = -1.000;
   best_val = RIPPLE_NEG;
   c = 0.000;
   while ( c < MCTS_CHILDREN ) {
      child = Ripple_MCTSGetChild (mcts_root, c);
      if ( (child >= 0.000) && (mcts_visits[child] > 0.000) ) {
         val = (mcts_reward[child] / mcts_visits[child]);
         if ( val > best_val ) {
            best_val = val;
            best_child = child;
         }
      }
      c = (c + TRUE);
   }

   if ( (best_child >= 0.000) && (rj_best_reward > 50.000) ) {
      entry = Vortex_FindNode (probe_pos);
      if ( entry < 0.000 ) {
         if ( vortex_count < VORTEX_MAX_NODES ) {
            entry = Vortex_AddNode (probe_pos, VORTEX_NODE_GROUND);
            Vortex_LinkNearby (entry);
         }
      }
      post = Vortex_FindNode (rj_best_pos);
      if ( post < 0.000 ) {
         if ( vortex_count < VORTEX_MAX_NODES ) {
            post = Vortex_AddNode (rj_best_pos, VORTEX_NODE_GROUND);
            Vortex_LinkNearby (post);
         }
      }
      if ( (entry >= 0.000) && (post >= 0.000) ) {
         vortex_leap_target[entry] = post;
         leap_type = Quantum_LeapBestType (purpose);
         leap_risk = Quantum_RJDamage (self.armorvalue);
         if ( leap_type == LEAP_TYPE_GJ ) {
            leap_risk = Quantum_GJDamage (self.armorvalue);
         } else if ( leap_type == LEAP_TYPE_GLJ ) {
            leap_risk = Quantum_GLJDamage (self.armorvalue);
         }
         vortex_leap_cost[entry] = leap_risk;
         vortex_leap_risk[entry] = leap_risk;
         vortex_leap_pos[entry] = probe_pos;
         Vortex_AddEdgeOneWay (entry, post);
         Vortex_BoostUsage (entry, 5.000);
         rj_last_success = TRUE;
      }
   }

   return ( rj_last_success );
};

float () Quantum_RJDetect = {
   local entity goal;
   local vector goal_pos;
   local vector delta;
   local float vert;
   local float horiz;
   local float purpose;
   local vector flat;
   local float has_rj;
   local float has_gj;

   if ( (time < self.rj_probe_time) ) {
      return ( FALSE );
   }
   self.rj_probe_time = time + RJ_PROBE_THROTTLE;

   if ( !self.goalentity || (self.goalentity == world) ) {
      return ( FALSE );
   }
   if ( self.enemy && enemyvisible (self.enemy) ) {
      return ( FALSE );
   }
   if ( self.feeler_mode_active ) {
      return ( FALSE );
   }
   if ( time < (self.last_rj + RJ_COOLDOWN) ) {
      return ( FALSE );
   }
   has_rj = ((self.items & IT_ROCKET_LAUNCHER) && (self.ammo_rockets >= TRUE));
   has_gj = ((self.items & IT_GRENADE_LAUNCHER) && (self.ammo_rockets >= TRUE));
   if ( !has_rj && !has_gj ) {
      return ( FALSE );
   }
   if ( self.health < (RJ_MIN_HEALTH + 5.000) ) {
      return ( FALSE );
   }
   if ( !has_rj && (self.health < GJ_MIN_HEALTH) ) {
      return ( FALSE );
   }

   goal = self.goalentity;
   if ( (goal.classname == "BotTarget") && goal.goalentity ) {
      goal = goal.goalentity;
   }
   if ( !goal || (goal == world) ) {
      return ( FALSE );
   }

   goal_pos = goal.origin;
   delta = (goal_pos - self.origin);
   vert = fabs (delta_z);
   flat = delta;
   flat_z = 0.000;
   horiz = vlen (flat);
   if ( (vert < 128.000) && (horiz < 256.000) ) {
      return ( FALSE );
   }

   purpose = Quantum_LeapPurpose (self.origin, goal_pos);
   self.rj_purpose = purpose;

   return Quantum_RJMCTS (self.origin, goal_pos, purpose);
};

float () Quantum_TryLeap = {
   local float cur;
   local float i;
   local vector lpos;
   local vector dir;
   local vector goal_pos;
   local vector fwd;
   local vector rgt;
   local float purpose;
   local float has_rj;
   local float has_gj;
   local float leap_type;
   local float slot;
   local float action_id;
   local vector impulse;

   if ( time < (self.last_rj + RJ_COOLDOWN) ) {
      return ( FALSE );
   }
   if ( self.enemy && enemyvisible (self.enemy) ) {
      return ( FALSE );
   }
   has_rj = ((self.items & IT_ROCKET_LAUNCHER) && (self.ammo_rockets >= TRUE));
   has_gj = ((self.items & IT_GRENADE_LAUNCHER) && (self.ammo_rockets >= TRUE));
   if ( !has_rj && !has_gj ) {
      return ( FALSE );
   }
   if ( self.health < (RJ_MIN_HEALTH + 5.000) ) {
      return ( FALSE );
   }
   if ( !has_rj && (self.health < GJ_MIN_HEALTH) ) {
      return ( FALSE );
   }

   cur = Vortex_FindNode (self.origin);
   if ( !Vortex_IndexValid (cur) ) {
      cur = -1.000;
   }
   if ( cur >= 0.000 ) {
      if ( (vortex_leap_target[cur] < 0.000) || (vortex_leap_pos[cur] == '0 0 0') ) {
         cur = -1.000;
      }
   }
   if ( cur < 0.000 ) {
      i = 0.000;
      while ( (i < vortex_count) && (i < VORTEX_MAX_NODES) ) {
         if ( (vortex_leap_target[i] >= 0.000) && (vortex_leap_pos[i] != '0 0 0') ) {
            if ( (vlen (vortex_leap_pos[i] - self.origin) < 64.000) ) {
               cur = i;
               break;
            }
         }
         i = (i + TRUE);
      }
   }
   if ( cur < 0.000 ) {
      return ( FALSE );
   }

   lpos = vortex_leap_pos[cur];
   if ( (vlen (lpos - self.origin) > 64.000) ) {
      return ( FALSE );
   }

   if ( !Vortex_IndexValid (vortex_leap_target[cur]) ) {
      return ( FALSE );
   }
   goal_pos = vortex_pos[vortex_leap_target[cur]];
   if ( vlen (goal_pos - self.origin) < 0.010 ) {
      if ( self.goalentity ) {
         goal_pos = self.goalentity.origin;
      } else {
         goal_pos = (self.origin + '64 0 0');
      }
   }

   purpose = Quantum_LeapPurpose (self.origin, goal_pos);
   leap_type = Quantum_LeapBestType (purpose);
   if ( !has_rj && (leap_type == LEAP_TYPE_RJ) ) {
      leap_type = LEAP_TYPE_GJ;
   }
   if ( !has_gj && (leap_type != LEAP_TYPE_RJ) ) {
      leap_type = LEAP_TYPE_RJ;
   }
   if ( (leap_type != LEAP_TYPE_RJ) && (self.health < GJ_MIN_HEALTH) ) {
      leap_type = LEAP_TYPE_RJ;
   }
   if ( (leap_type == LEAP_TYPE_RJ) && (self.health < RJ_MIN_HEALTH) ) {
      return ( FALSE );
   }

   fwd = normalize (goal_pos - self.origin);
   if ( vlen (fwd) < 0.010 ) {
      fwd = '1 0 0';
   }
   rgt_x = -fwd_y;
   rgt_y = fwd_x;
   rgt_z = 0.000;
   rgt = normalize (rgt);

   if ( purpose == RJ_PURPOSE_VAULT ) {
      slot = 1.000;
   } else if ( purpose == RJ_PURPOSE_HIGH ) {
      slot = 3.000;
   } else {
      slot = 0.000;
   }

   if ( leap_type == LEAP_TYPE_RJ ) {
      dir = fwd;
      self.weapon = IT_ROCKET_LAUNCHER;
      self.button2 = TRUE;
      self.button0 = TRUE;
      self.last_rj = time;
      self.velocity = (self.velocity + (dir * RJ_IMPULSE));
      self.velocity_z = (self.velocity_z + 272.000);
      self.health = (self.health - Quantum_RJDamage (self.armorvalue));
   } else if ( leap_type == LEAP_TYPE_GJ ) {
      action_id = Quantum_GJActionForSlot (slot, cur);
      impulse = Quantum_GJImpulse (self.origin, fwd, rgt, purpose, action_id);
      self.weapon = IT_GRENADE_LAUNCHER;
      self.button2 = TRUE;
      self.button0 = TRUE;
      self.last_rj = time;
      self.velocity = (self.velocity + impulse);
      self.health = (self.health - Quantum_GJDamage (self.armorvalue));
   } else {
      action_id = Quantum_GLJActionForSlot (slot, cur);
      impulse = Quantum_GLJImpulse (self.origin, fwd, rgt, purpose, action_id);
      self.weapon = IT_GRENADE_LAUNCHER;
      self.button2 = TRUE;
      self.button0 = TRUE;
      self.last_rj = time;
      self.velocity = (self.velocity + impulse);
      self.velocity_z = (self.velocity_z + 272.000);
      self.health = (self.health - Quantum_GLJDamage (self.armorvalue));
   }

   if ( self.health < 1.000 ) {
      self.health = 1.000;
   }
   return ( TRUE );
};

void () Ripple_ResetNext = {
   local float i;

   i = 0.000;
   while ( i < MAELSTROM_BEAM ) {
      mr_next_reward[i] = RIPPLE_NEG;
      i = (i + TRUE);
   }
   mr_next_count = 0.000;
};

void (vector pos, vector vel, float air, float reward, float flags, float beam_w) Ripple_ConsiderCandidate = {
   local float i;
   local float j;
   local float last;

   last = (beam_w - TRUE);
   if ( (mr_next_count >= beam_w) && (reward <= mr_next_reward[last]) ) {
      return ;
   }

   i = 0.000;
   while ( i < beam_w ) {
      if ( (reward > mr_next_reward[i]) ) {
         j = last;
         while ( j > i ) {
            mr_next_pos[j] = mr_next_pos[j - TRUE];
            mr_next_vel[j] = mr_next_vel[j - TRUE];
            mr_next_air[j] = mr_next_air[j - TRUE];
            mr_next_reward[j] = mr_next_reward[j - TRUE];
            mr_next_flags[j] = mr_next_flags[j - TRUE];
            j = (j - TRUE);
         }
         mr_next_pos[i] = pos;
         mr_next_vel[i] = vel;
         mr_next_air[i] = air;
         mr_next_reward[i] = reward;
         mr_next_flags[i] = flags;
         if ( (mr_next_count < beam_w) ) {
            mr_next_count = (mr_next_count + TRUE);
         }
         return ;
      }
      i = (i + TRUE);
   }

   if ( (mr_next_count < beam_w) ) {
      mr_next_pos[mr_next_count] = pos;
      mr_next_vel[mr_next_count] = vel;
      mr_next_air[mr_next_count] = air;
      mr_next_reward[mr_next_count] = reward;
      mr_next_flags[mr_next_count] = flags;
      mr_next_count = (mr_next_count + TRUE);
   }
};

float (vector probe_pos, vector goal_pos, float rtype) Ripple_MaelstromSim = {
   local float depth;
   local float beam_w;
   local float d;
   local float b;
   local float a;
   local float action;
   local float reward;
   local float flags;
   local float hash;
   local float air_left;
   local vector fwd;
   local vector rgt;
   local vector pos;
   local vector vel;
   local float air;
   local float blocked;
   local float entry;
   local float post;
   local float i;
   local float best_idx;
   local float best_reward;

   depth = MAELSTROM_DEPTH_BASE + floor (self.skil * 0.330);
   if ( (depth > MAELSTROM_DEPTH_MAX) ) {
      depth = MAELSTROM_DEPTH_MAX;
   }

   beam_w = MAELSTROM_BEAM;
   if ( (beam_w < TRUE) ) {
      beam_w = TRUE;
   }

   fwd = normalize (goal_pos - self.origin);
   if ( (vlen (fwd) < 0.010) ) {
      fwd = '1 0 0';
   }
   rgt_x = -fwd_y;
   rgt_y = fwd_x;
   rgt_z = 0.000;
   rgt = normalize (rgt);

   air_left = (self.air_finished - time);
   if ( (air_left < FALSE) ) {
      air_left = FALSE;
   }
   if ( (air_left > 12.000) ) {
      air_left = 12.000;
   }

   mr_pos[0] = self.origin;
   mr_vel[0] = '0 0 0';
   mr_air[0] = air_left;
   mr_reward[0] = ShadowReward (mr_pos[0], mr_vel[0], mr_air[0], goal_pos, TRUE, FALSE, 1.000, 1.000);
   mr_flags[0] = 0.000;
   mr_count = TRUE;

   d = TRUE;
   while ( d <= depth ) {
      Ripple_ResetNext ();
      b = 0.000;
      while ( b < mr_count ) {
         hash = Ripple_HashState (mr_pos[b], mr_flags[b]);
         if ( (ripple_visit[hash] > (time - TRUE)) ) {
            b = (b + TRUE);
            continue ;
         }
         ripple_visit[hash] = time;

         a = 0.000;
         while ( a < 4.000 ) {
            action = a;

            pos = mr_pos[b];
            vel = mr_vel[b];
            air = mr_air[b];
            blocked = FALSE;

            if ( action == 3.000 ) {
               vel = (vel * 0.500);
            } else {
               ShadowSimStep (pos, vel, air, 0.000, fwd, rgt, TRUE);
               pos = sp_out_pos;
               vel = sp_out_vel;
               air = sp_out_air;
               blocked = sp_out_blocked;
            }

            reward = mr_reward[b];
            flags = mr_flags[b];

            if ( (vlen (pos - probe_pos) < RIPPLE_ACTION_RANGE) ) {
               if ( (rtype == RIPPLE_TYPE_SHOOT) && (action == 1.000) ) {
                  flags = (flags | FLAG_DOOR_OPEN);
                  reward = (reward + 150.000);
                  pos_z = (pos_z + 32.000);
               } else if ( (rtype == RIPPLE_TYPE_TOUCH) && (action == 2.000) ) {
                  flags = (flags | FLAG_PLAT_RAISED);
                  reward = (reward + 200.000);
                  pos_z = (pos_z + 64.000);
               }
            }

            reward = (reward + ShadowReward (pos, vel, air, goal_pos, TRUE, blocked, 1.000, 1.000));
            if ( (flags & (FLAG_DOOR_OPEN + FLAG_PLAT_RAISED)) == 0.000 ) {
               reward = (reward - (100.000 * d));
            }

            Ripple_ConsiderCandidate (pos, vel, air, reward, flags, beam_w);
            a = (a + TRUE);
         }
         b = (b + TRUE);
      }

      mr_count = mr_next_count;
      if ( (mr_count <= FALSE) ) {
         return ( FALSE );
      }
      i = 0.000;
      while ( i < mr_count ) {
         mr_pos[i] = mr_next_pos[i];
         mr_vel[i] = mr_next_vel[i];
         mr_air[i] = mr_next_air[i];
         mr_reward[i] = mr_next_reward[i];
         mr_flags[i] = mr_next_flags[i];
         i = (i + TRUE);
      }

      d = (d + TRUE);
   }

   best_idx = -1.000;
   best_reward = RIPPLE_NEG;
   i = 0.000;
   while ( i < mr_count ) {
      if ( (mr_flags[i] > 0.000) && (mr_reward[i] > best_reward) ) {
         best_reward = mr_reward[i];
         best_idx = i;
      }
      i = (i + TRUE);
   }

   if ( (best_idx >= 0.000) && (best_reward > 100.000) ) {
      entry = Vortex_FindNode (probe_pos);
      if ( entry < 0.000 ) {
         if ( vortex_count < VORTEX_MAX_NODES ) {
            entry = Vortex_AddNode (probe_pos, VORTEX_NODE_GROUND);
            Vortex_LinkNearby (entry);
         }
      }
      post = Vortex_FindNode (mr_pos[best_idx]);
      if ( post < 0.000 ) {
         if ( vortex_count < VORTEX_MAX_NODES ) {
            post = Vortex_AddNode (mr_pos[best_idx], VORTEX_NODE_GROUND);
            Vortex_LinkNearby (post);
         }
      }

      if ( (entry >= 0.000) && (post >= 0.000) ) {
         vortex_ripple_type[entry] = rtype;
         vortex_ripple_target[entry] = post;
         vortex_ripple_cost[entry] = (depth * 0.100);
         vortex_ripple_steps[entry] = depth;
         vortex_ripple_flags[entry] = mr_flags[best_idx];
         vortex_ripple_pos[entry] = probe_pos;
         Vortex_AddEdgeOneWay (entry, post);
         Vortex_BoostUsage (entry, 5.000);
         return ( TRUE );
      }
   }

   return ( FALSE );
};

float () RippleDetect = {
   local entity goal;
   local vector goal_pos;
   local vector eye;
   local vector block_pos;
   local vector dir;
   local float d;
   local float rtype;

   if ( (time < self.ripple_probe_time) ) {
      return ( FALSE );
   }
   self.ripple_probe_time = time + RIPPLE_PROBE_THROTTLE;

   if ( !self.goalentity || (self.goalentity == world) ) {
      return ( FALSE );
   }

   goal = self.goalentity;
   if ( (goal.classname == "BotTarget") && goal.goalentity ) {
      goal = goal.goalentity;
   }
   if ( !goal || (goal == world) ) {
      return ( FALSE );
   }

   if ( (vlen (goal.origin - self.origin) > RIPPLE_GOAL_RANGE) ) {
      return ( FALSE );
   }
   if ( self.enemy && enemyvisible (self.enemy) ) {
      return ( FALSE );
   }
   if ( self.feeler_mode_active ) {
      return ( FALSE );
   }

   goal_pos = goal.origin;
   eye = self.origin + '0 0 32';
   traceline (eye, goal_pos, TRUE, self);
   if ( trace_fraction == 1.000 ) {
      return ( FALSE );
   }

   if ( trace_ent ) {
      rtype = Ripple_InteractType (trace_ent);
      if ( (rtype > 0.000) ) {
         if ( Ripple_MaelstromMCTS (trace_ent.origin, goal_pos, rtype) ) {
            return ( TRUE );
         }
         if ( Ripple_MaelstromSim (trace_ent.origin, goal_pos, rtype) ) {
            return ( TRUE );
         }
      }
   }

   block_pos = trace_endpos + '0 0 16';
   d = 0.000;
   while ( d < RIPPLE_PULSE_DIRS ) {
      dir = Ripple_PulseDir (d);
      traceline (block_pos, (block_pos + (dir * (RIPPLE_PULSE_DIST / 64.000))), TRUE, self);
      rtype = Ripple_InteractType (trace_ent);
      if ( (rtype > 0.000) ) {
         if ( Ripple_MaelstromMCTS (trace_ent.origin, goal_pos, rtype) ) {
            return ( TRUE );
         }
         if ( Ripple_MaelstromSim (trace_ent.origin, goal_pos, rtype) ) {
            return ( TRUE );
         }
      }
      d = (d + TRUE);
   }

   return ( FALSE );
};

float () Ripple_TryInteract = {
   local float cur;
   local float i;
   local vector rpos;

   cur = Vortex_FindNode (self.origin);
   if ( !Vortex_IndexValid (cur) ) {
      cur = -1.000;
   }
   if ( cur >= 0.000 ) {
      if ( (vortex_ripple_type[cur] <= 0.000) || (vortex_ripple_pos[cur] == '0 0 0') ) {
         cur = -1.000;
      }
   }
   if ( cur < 0.000 ) {
      // Throttle full ripple scans when no nearby node is cached
      if ( time < self.ripple_interact_time ) {
         return ( FALSE );
      }
      self.ripple_interact_time = (time + 0.200);

      i = 0.000;
      while ( (i < vortex_count) && (i < VORTEX_MAX_NODES) ) {
         if ( (vortex_ripple_type[i] > 0.000) && (vortex_ripple_pos[i] != '0 0 0') ) {
            if ( (vlen (vortex_ripple_pos[i] - self.origin) < 96.000) ) {
               cur = i;
               break;
            }
         }
         i = (i + TRUE);
      }
   }
   if ( cur < 0.000 ) {
      return ( FALSE );
   }
   rpos = vortex_ripple_pos[cur];
   if ( (vlen (rpos - self.origin) > 96.000) ) {
      return ( FALSE );
   }

   if ( vortex_ripple_type[cur] == RIPPLE_TYPE_SHOOT ) {
      self.button0 = TRUE;
      return ( TRUE );
   }
   if ( vortex_ripple_type[cur] == RIPPLE_TYPE_TOUCH ) {
      self.button2 = FALSE;
      return ( TRUE );
   }
   return ( FALSE );
};

void (vector start, vector end, vector ripple_pos, float rtype) Ripple_FuseChain = {
   local float sidx;
   local float eidx;
   local float flags;

   sidx = Vortex_FindNode (start);
   if ( (sidx < 0.000) && (vortex_count < VORTEX_MAX_NODES) ) {
      sidx = Vortex_AddNode (start, VORTEX_NODE_GROUND);
      Vortex_LinkNearby (sidx);
   }
   eidx = Vortex_FindNode (end);
   if ( (eidx < 0.000) && (vortex_count < VORTEX_MAX_NODES) ) {
      eidx = Vortex_AddNode (end, VORTEX_NODE_GROUND);
      Vortex_LinkNearby (eidx);
   }
   if ( (sidx < 0.000) || (eidx < 0.000) ) {
      return;
   }

   flags = Ripple_FlagForType (rtype);
   vortex_ripple_type[sidx] = rtype;
   vortex_ripple_target[sidx] = eidx;
   vortex_ripple_cost[sidx] = 0.200;
   vortex_ripple_steps[sidx] = 1.000;
   vortex_ripple_flags[sidx] = flags;
   vortex_ripple_pos[sidx] = ripple_pos;
   Vortex_AddEdgeOneWay (sidx, eidx);
   Vortex_BoostUsage (sidx, 20.000);
};

void (vector start, vector end, vector leap_pos, float risk) Quantum_FuseLeap = {
   local float sidx;
   local float eidx;

   sidx = Vortex_FindNode (start);
   if ( (sidx < 0.000) && (vortex_count < VORTEX_MAX_NODES) ) {
      sidx = Vortex_AddNode (start, VORTEX_NODE_GROUND);
      Vortex_LinkNearby (sidx);
   }
   eidx = Vortex_FindNode (end);
   if ( (eidx < 0.000) && (vortex_count < VORTEX_MAX_NODES) ) {
      eidx = Vortex_AddNode (end, VORTEX_NODE_GROUND);
      Vortex_LinkNearby (eidx);
   }
   if ( (sidx < 0.000) || (eidx < 0.000) ) {
      return;
   }

   vortex_leap_target[sidx] = eidx;
   vortex_leap_cost[sidx] = risk;
   vortex_leap_risk[sidx] = risk;
   vortex_leap_pos[sidx] = leap_pos;
   Vortex_AddEdgeOneWay (sidx, eidx);
   Vortex_BoostUsage (sidx, 30.000);
};
