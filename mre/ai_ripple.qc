// ai_ripple.qc: Ripple Oracles - Simplified button solving + beam-search leaps

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

#define FLAG_DOOR_OPEN 1.000
#define FLAG_PLAT_RAISED 2.000

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

// Beam search state for RJ solving (4 candidates)
#define RJ_BEAM 4
vector rjb_pos[RJ_BEAM];
vector rjb_vel[RJ_BEAM];
float rjb_air[RJ_BEAM];
float rjb_reward[RJ_BEAM];
float rjb_health[RJ_BEAM];
float rjb_armor[RJ_BEAM];
float rjb_count;

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

float ripple_last_probe;
float ripple_last_goal_node;
float ripple_last_success;

// ============================================================================
// Utility functions
// ============================================================================

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

// ============================================================================
// Simplified button solving: trace-and-record heuristic
// ============================================================================

float (vector probe_pos, vector goal_pos, float rtype) Ripple_SolveButton = {
   local float entry;
   local float post;
   local vector eye;
   local vector target;

   // Throttle: don't re-probe same goal too fast
   if ( (ripple_last_probe > 0.000) && (time < (ripple_last_probe + RIPPLE_PROBE_THROTTLE)) ) {
      return ( ripple_last_success );
   }
   ripple_last_probe = time;
   ripple_last_success = FALSE;

   // Check if we can see the interactable from here
   eye = self.origin + '0 0 32';
   traceline (eye, probe_pos, TRUE, self);
   if ( (trace_fraction < 0.900) && (trace_ent.classname != "func_button") && (trace_ent.classname != "func_door") ) {
      // Can't see button - not solvable from here
      return ( FALSE );
   }

   // Estimate post-interaction position: goal if reachable, else offset past button
   target = goal_pos;

   // Record in Vortex navmesh
   entry = Vortex_FindNode (probe_pos);
   if ( entry < 0.000 ) {
      if ( vortex_count < VORTEX_MAX_NODES ) {
         entry = Vortex_AddNode (probe_pos, VORTEX_NODE_GROUND);
         Vortex_LinkNearby (entry);
      }
   }
   post = Vortex_FindNode (target);
   if ( post < 0.000 ) {
      if ( vortex_count < VORTEX_MAX_NODES ) {
         post = Vortex_AddNode (target, VORTEX_NODE_GROUND);
         Vortex_LinkNearby (post);
      }
   }
   if ( (entry >= 0.000) && (post >= 0.000) ) {
      vortex_ripple_type[entry] = rtype;
      vortex_ripple_target[entry] = post;
      vortex_ripple_cost[entry] = 0.500;
      vortex_ripple_steps[entry] = 1.000;
      vortex_ripple_flags[entry] = Ripple_FlagForType (rtype);
      vortex_ripple_pos[entry] = probe_pos;
      Vortex_AddEdgeOneWay (entry, post);
      Vortex_BoostUsage (entry, 5.000);
      ripple_last_success = TRUE;
   }

   return ( ripple_last_success );
};

// ============================================================================
// Physics: armor scaling, damage calculations
// ============================================================================

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

// ============================================================================
// Physics: RJ/GJ/GLJ coefficient tables and simulation
// ============================================================================

float (float purpose, float vtype) Quantum_HorizCoeff = {
   if ( purpose == RJ_PURPOSE_LAVA ) {
      if ( vtype == 0.000 ) return 1.400;
      if ( vtype == 1.000 ) return 1.000;
      if ( vtype == 2.000 ) return 0.800;
      return 1.100;
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
      if ( vtype == 1.000 ) return 1.500;
      return 1.200;
   }
   if ( purpose == RJ_PURPOSE_HIGH ) {
      if ( vtype == 2.000 ) return 1.400;
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
      if ( vtype == 0.000 ) base = 1.500;
      else if ( vtype == 1.000 ) base = 1.100;
      else if ( vtype == 2.000 ) base = 0.900;
      else base = 1.000;
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
      if ( parity == 0.000 ) return RJ_ACTION_BASE;
      return (RJ_ACTION_BASE + 1.000);
   }
   if ( slot == 1.000 ) {
      if ( parity == 0.000 ) return (RJ_ACTION_BASE + 4.000);
      return (RJ_ACTION_BASE + 5.000);
   }
   if ( slot == 2.000 ) {
      if ( parity == 0.000 ) return (RJ_ACTION_BASE + 2.000);
      return (RJ_ACTION_BASE + 3.000);
   }
   if ( parity == 0.000 ) return (RJ_ACTION_BASE + 6.000);
   return (RJ_ACTION_BASE + 7.000);
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

      vel = (vel + (strafe_dir * (80.000 * air_mult)));
   }

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

// ============================================================================
// Leap type selection and dispatch
// ============================================================================

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

// ============================================================================
// Flat beam search for rocket/grenade jumps (replaces MCTS)
// ============================================================================

float (vector probe_pos, vector goal_pos, float purpose) Quantum_RJBeam = {
   local float b;
   local float step;
   local float action_id;
   local vector pos;
   local vector vel;
   local float air;
   local float reward;
   local float hp;
   local float armor;
   local float dmg;
   local float dist;
   local float start_dist;
   local float best_b;
   local float best_reward;
   local float entry;
   local float post;
   local float goal_node;
   local float leap_type;
   local float leap_risk;

   // Throttle
   goal_node = Vortex_FindNode (goal_pos);
   if ( (rj_last_probe > 0.000) && (time < (rj_last_probe + RJ_PROBE_THROTTLE)) && (goal_node == rj_last_goal_node) && (goal_node >= 0.000) ) {
      return ( rj_last_success );
   }
   rj_last_probe = time;
   rj_last_goal_node = goal_node;
   rj_last_success = FALSE;

   rj_goal_pos = goal_pos;
   rj_probe_pos = probe_pos;
   rj_best_reward = -999999.000;
   rj_best_pos = self.origin;

   rj_fwd = normalize (goal_pos - self.origin);
   if ( (vlen (rj_fwd) < 0.010) ) {
      rj_fwd = '1 0 0';
   }
   rj_rgt_x = -rj_fwd_y;
   rj_rgt_y = rj_fwd_x;
   rj_rgt_z = 0.000;
   rj_rgt = normalize (rj_rgt);

   start_dist = vlen (goal_pos - self.origin);

   // Evaluate RJ_BEAM candidates, each with a different action
   b = 0.000;
   while ( b < RJ_BEAM ) {
      action_id = Quantum_LeapPickAction (purpose);
      pos = self.origin;
      vel = self.velocity;
      air = (self.air_finished - time);
      if ( air < FALSE ) air = FALSE;
      if ( air > 12.000 ) air = 12.000;
      hp = self.health;
      armor = self.armorvalue;
      reward = 0.000;

      // Apply leap damage
      dmg = Quantum_LeapDamage (armor, action_id);
      hp = (hp - dmg);
      armor = (armor - (dmg * 0.500));
      if ( armor < 0.000 ) armor = 0.000;
      if ( hp < Quantum_LeapMinHealth (action_id) ) {
         rjb_reward[b] = -500.000;
         b = (b + TRUE);
         continue;
      }

      // Simulate flight steps (skill-scaled: 6 at skill 0, 12 at skill 10)
      local float max_steps;
      max_steps = (6.000 + floor (self.skil * 0.600));
      step = 0.000;
      while ( step < max_steps ) {
         if ( step == 0.000 ) {
            Quantum_LeapSimStep (pos, vel, air, action_id, rj_fwd, rj_rgt, purpose);
         } else {
            // After initial impulse, just coast with gravity
            Quantum_LeapSimStep (pos, vel, air, 0.000, rj_fwd, rj_rgt, purpose);
         }
         pos = sp_out_pos;
         vel = sp_out_vel;
         air = sp_out_air;

         dist = vlen (rj_goal_pos - pos);
         reward = (reward + ShadowReward (pos, vel, air, rj_goal_pos, TRUE, sp_out_blocked, 1.000, 1.000));
         reward = (reward + ((start_dist - dist) * 0.250));

         if ( sp_out_blocked && (step > 0.000) ) {
            break;
         }
         step = (step + TRUE);
      }

      rjb_pos[b] = pos;
      rjb_reward[b] = reward;
      b = (b + TRUE);
   }

   // Find best candidate
   best_b = -1.000;
   best_reward = -999999.000;
   b = 0.000;
   while ( b < RJ_BEAM ) {
      if ( rjb_reward[b] > best_reward ) {
         best_reward = rjb_reward[b];
         best_b = b;
      }
      b = (b + TRUE);
   }

   if ( (best_b >= 0.000) && (best_reward > 50.000) ) {
      rj_best_reward = best_reward;
      rj_best_pos = rjb_pos[best_b];

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

// ============================================================================
// Detection and execution entry points (unchanged signatures)
// ============================================================================

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

   return Quantum_RJBeam (self.origin, goal_pos, purpose);
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
      // Quantum leap: physics applied directly (velocity + damage), no projectile needed
      self.last_rj = time;
      self.velocity = (self.velocity + (dir * RJ_IMPULSE));
      self.velocity_z = (self.velocity_z + 272.000);
      self.health = (self.health - Quantum_RJDamage (self.armorvalue));
   } else if ( leap_type == LEAP_TYPE_GJ ) {
      action_id = Quantum_GJActionForSlot (slot, cur);
      impulse = Quantum_GJImpulse (self.origin, fwd, rgt, purpose, action_id);
      self.weapon = IT_GRENADE_LAUNCHER;
      self.button2 = TRUE;
      self.last_rj = time;
      self.velocity = (self.velocity + impulse);
      self.health = (self.health - Quantum_GJDamage (self.armorvalue));
   } else {
      action_id = Quantum_GLJActionForSlot (slot, cur);
      impulse = Quantum_GLJImpulse (self.origin, fwd, rgt, purpose, action_id);
      self.weapon = IT_GRENADE_LAUNCHER;
      self.button2 = TRUE;
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

// ============================================================================
// Button detection: simplified (replaces Maelstrom MCTS + beam search)
// ============================================================================

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
         if ( Ripple_SolveButton (trace_ent.origin, goal_pos, rtype) ) {
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
         if ( Ripple_SolveButton (trace_ent.origin, goal_pos, rtype) ) {
            return ( TRUE );
         }
      }
      d = (d + TRUE);
   }

   return ( FALSE );
};

// ============================================================================
// Button interaction execution (unchanged)
// ============================================================================

float () Ripple_TryInteract = {
   local float cur;
   local float i;
   local vector rpos;
   local float ripple_throttle;

   cur = -1.000;
   if ( self.ripple_near_count != vortex_count ) {
      self.ripple_near_idx = -1.000;
   }
   if ( Vortex_IndexValid (self.ripple_near_idx) ) {
      if ( vlen (vortex_ripple_pos[self.ripple_near_idx] - self.ripple_near_pos) > 1.000 ) {
         self.ripple_near_idx = -1.000;
      } else if ( (vortex_ripple_type[self.ripple_near_idx] > 0.000) && (vortex_ripple_pos[self.ripple_near_idx] != '0 0 0') ) {
         if ( (vlen (vortex_ripple_pos[self.ripple_near_idx] - self.origin) < 128.000) ) {
            cur = self.ripple_near_idx;
         }
      }
   }

   if ( cur < 0.000 ) {
      cur = Vortex_FindNode (self.origin);
   }
   if ( !Vortex_IndexValid (cur) ) {
      cur = -1.000;
   }
   if ( cur >= 0.000 ) {
      if ( (vortex_ripple_type[cur] <= 0.000) || (vortex_ripple_pos[cur] == '0 0 0') ) {
         cur = -1.000;
      }
   }
   if ( cur < 0.000 ) {
      ripple_throttle = cvar ("bot_ripple_throttle");
      if ( (ripple_throttle <= FALSE) ) {
         ripple_throttle = 0.200;
      }
      if ( time < self.ripple_interact_time ) {
         return ( FALSE );
      }
      self.ripple_interact_time = (time + ripple_throttle);

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
   self.ripple_near_idx = cur;
   self.ripple_near_pos = vortex_ripple_pos[cur];
   self.ripple_near_count = vortex_count;
   rpos = vortex_ripple_pos[cur];
   if ( (vlen (rpos - self.origin) > 96.000) ) {
      return ( FALSE );
   }

   if ( vortex_ripple_type[cur] == RIPPLE_TYPE_SHOOT ) {
      BotDirectFire ();
      return ( TRUE );
   }
   if ( vortex_ripple_type[cur] == RIPPLE_TYPE_TOUCH ) {
      self.button2 = FALSE;
      return ( TRUE );
   }
   return ( FALSE );
};

// ============================================================================
// Fuse functions: record discoveries into Vortex navmesh (unchanged)
// ============================================================================

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
