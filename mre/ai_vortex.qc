// ai_vortex.qc: Vortex Navmesh - Incremental Dynamic Learning Mesh

float (vector start, vector goal, float maneuver) EtherealRollout;
float (vector pos) GetCursePenalty;
float (vector spot) dropline;
vector (vector start, vector goal) Apex_VortexNext;
float (vector spot) BotDetectHazard;
void (vector pos) CurseNode;
float (float idx, float at_time) Vortex_LiftWaitAt;
void () Vortex_Seed;
float () RippleDetect;
float (float idx) Vortex_IndexValid;

#ifdef QS_V6
#define VORTEX_MAX_NODES 256
#define VORTEX_MAX_EDGES 2048
#else
#define VORTEX_MAX_NODES 512
#define VORTEX_MAX_EDGES 4096
#endif
#define VORTEX_MAX_CONN 8
#define VORTEX_BUILD_THROTTLE 1.000
#define VORTEX_TRACE_BUDGET 20.000
#define VORTEX_NODE_RADIUS 32.000
#define VORTEX_ADD_RADIUS 64.000
#define VORTEX_MIN_READY 50.000
#define VORTEX_DECAY_THROTTLE 10.000

#define VORTEX_NODE_GROUND 0.000
#define VORTEX_NODE_TELE 1.000
#define VORTEX_NODE_ITEM 2.000
#define VORTEX_NODE_LIFT 3.000

#define VORTEX_TELE_CHAIN_MAX 5.000
#define VORTEX_TELE_COST 10.000
#define VORTEX_TELE_WARP_DIST 500.000
#define VORTEX_LIFT_SAMPLE_THROTTLE 5.000
#define VORTEX_LIFT_UP_START 0.000
#define VORTEX_LIFT_UP_END 0.250

vector vortex_pos[VORTEX_MAX_NODES];
float vortex_conn[VORTEX_MAX_EDGES];
float vortex_conn_count[VORTEX_MAX_NODES];
float vortex_type[VORTEX_MAX_NODES];
float vortex_usage[VORTEX_MAX_NODES];
float vortex_tele_exit[VORTEX_MAX_NODES];
float vortex_lift_cycle[VORTEX_MAX_NODES];
float vortex_lift_phase[VORTEX_MAX_NODES];
float vortex_lift_up_start[VORTEX_MAX_NODES];
float vortex_lift_up_end[VORTEX_MAX_NODES];
float vortex_ripple_type[VORTEX_MAX_NODES];
float vortex_ripple_target[VORTEX_MAX_NODES];
float vortex_ripple_cost[VORTEX_MAX_NODES];
float vortex_ripple_steps[VORTEX_MAX_NODES];
float vortex_ripple_flags[VORTEX_MAX_NODES];
vector vortex_ripple_pos[VORTEX_MAX_NODES];
float vortex_leap_target[VORTEX_MAX_NODES];
float vortex_leap_cost[VORTEX_MAX_NODES];
float vortex_leap_risk[VORTEX_MAX_NODES];
vector vortex_leap_pos[VORTEX_MAX_NODES];
float vortex_count;
float vortex_last_build;
float vortex_last_decay;
float vortex_last_lift_sample;
float vortex_lift_index;
float vortex_flood_index;
float vortex_flood_dir;
float vortex_seeded;

float vortex_g[VORTEX_MAX_NODES];
float vortex_f[VORTEX_MAX_NODES];
float vortex_came[VORTEX_MAX_NODES];
float vortex_state[VORTEX_MAX_NODES];
float vortex_open[VORTEX_MAX_NODES];
float vortex_open_count;

float (float idx) Vortex_IndexValid = {
   if ( idx < 0.000 ) return ( FALSE );
   if ( idx >= VORTEX_MAX_NODES ) return ( FALSE );
   return ( TRUE );
};

vector (float idx) Vortex_Dir = {

   if ( idx == 0.000 ) return '200 0 0';
   if ( idx == 1.000 ) return '0 200 0';
   if ( idx == 2.000 ) return '-200 0 0';
   if ( idx == 3.000 ) return '0 -200 0';
   if ( idx == 4.000 ) return '141 141 0';
   if ( idx == 5.000 ) return '-141 141 0';
   if ( idx == 6.000 ) return '-141 -141 0';
   return '141 -141 0';

};

float (float v, float mod) Vortex_Mod = {

   local float wrap;

   if ( mod <= 0.000 ) {
      return v;
   }
   wrap = floor (v / mod);
   return (v - (wrap * mod));

};

void () Vortex_Reset = {

   vortex_count = 0.000;
   vortex_last_build = 0.000;
   vortex_last_decay = 0.000;
   vortex_last_lift_sample = 0.000;
   vortex_lift_index = 0.000;
   vortex_flood_index = 0.000;
   vortex_flood_dir = 0.000;
   vortex_seeded = FALSE;

};

float (vector pos) Vortex_FindNode = {

   local float i;
   local vector delta;
   local float radius2;

   i = 0.000;
   radius2 = (VORTEX_NODE_RADIUS * VORTEX_NODE_RADIUS);
   while ( i < vortex_count ) {
      delta = (vortex_pos[i] - pos);
      if ( ((delta * delta) < radius2) ) {
         return ( i );
      }
      i = (i + TRUE);
   }
   return ( -1.000 );

};

void (float idx, float amt) Vortex_BoostUsage = {

   if ( !Vortex_IndexValid (idx) ) {
      return;
   }
   vortex_usage[idx] = (vortex_usage[idx] + amt);
   if ( vortex_usage[idx] > 100.000 ) {
      vortex_usage[idx] = 100.000;
   }

};

float (vector pos, float ntype) Vortex_AddNode = {

   local float idx;

   if ( vortex_count >= VORTEX_MAX_NODES ) {
      return ( -1.000 );
   }
   idx = vortex_count;
   vortex_count = (vortex_count + TRUE);
   vortex_pos[idx] = pos;
   vortex_conn_count[idx] = 0.000;
   vortex_type[idx] = ntype;
   vortex_usage[idx] = 1.000;
   vortex_tele_exit[idx] = -1.000;
   vortex_lift_cycle[idx] = 0.000;
   vortex_lift_phase[idx] = 0.000;
   vortex_lift_up_start[idx] = VORTEX_LIFT_UP_START;
   vortex_lift_up_end[idx] = VORTEX_LIFT_UP_END;
   vortex_ripple_type[idx] = 0.000;
   vortex_ripple_target[idx] = -1.000;
   vortex_ripple_cost[idx] = 0.000;
   vortex_ripple_steps[idx] = 0.000;
   vortex_ripple_flags[idx] = 0.000;
   vortex_ripple_pos[idx] = '0 0 0';
   vortex_leap_target[idx] = -1.000;
   vortex_leap_cost[idx] = 0.000;
   vortex_leap_risk[idx] = 0.000;
   vortex_leap_pos[idx] = '0 0 0';
   if ( ntype == VORTEX_NODE_ITEM ) {
      vortex_usage[idx] = 2.000;
   } else if ( ntype == VORTEX_NODE_TELE ) {
      vortex_usage[idx] = 3.000;
   } else if ( ntype == VORTEX_NODE_LIFT ) {
      vortex_usage[idx] = 2.000;
   }
   return ( idx );

};

float (float n1, float n2) Vortex_HasEdge = {

   local float i;
   local float base;

   if ( (n1 < 0.000) || (n2 < 0.000) ) {
      return ( FALSE );
   }
   base = (n1 * VORTEX_MAX_CONN);
   i = 0.000;
   while ( i < vortex_conn_count[n1] ) {
      if ( vortex_conn[base + i] == n2 ) {
         return ( TRUE );
      }
      i = (i + TRUE);
   }
   return ( FALSE );

};

void (float n1, float n2) Vortex_AddEdge = {

   local float viab;
   local float base1;
   local float base2;

   if ( (n1 < 0.000) || (n2 < 0.000) ) {
      return;
   }
   if ( (n1 == n2) ) {
      return;
   }
   if ( Vortex_HasEdge (n1, n2) ) {
      return;
   }

   viab = EtherealRollout (vortex_pos[n1], vortex_pos[n2], 0.000);
   if ( viab < 10.000 ) {
      return;
   }

   if ( vortex_conn_count[n1] < VORTEX_MAX_CONN ) {
      base1 = (n1 * VORTEX_MAX_CONN);
      vortex_conn[base1 + vortex_conn_count[n1]] = n2;
      vortex_conn_count[n1] = (vortex_conn_count[n1] + TRUE);
   }
   if ( vortex_conn_count[n2] < VORTEX_MAX_CONN ) {
      base2 = (n2 * VORTEX_MAX_CONN);
      vortex_conn[base2 + vortex_conn_count[n2]] = n1;
      vortex_conn_count[n2] = (vortex_conn_count[n2] + TRUE);
   }

};

void (float n1, float n2) Vortex_AddEdgeOneWay = {

   local float base1;

   if ( (n1 < 0.000) || (n2 < 0.000) ) {
      return;
   }
   if ( (n1 == n2) ) {
      return;
   }
   if ( Vortex_HasEdge (n1, n2) ) {
      return;
   }
   if ( vortex_conn_count[n1] < VORTEX_MAX_CONN ) {
      base1 = (n1 * VORTEX_MAX_CONN);
      vortex_conn[base1 + vortex_conn_count[n1]] = n2;
      vortex_conn_count[n1] = (vortex_conn_count[n1] + TRUE);
   }

};

void (float idx) Vortex_LinkNearby = {

   local float i;
   local float dist;

   if ( idx < 0.000 ) {
      return;
   }
   i = 0.000;
   while ( i < vortex_count ) {
      if ( i != idx ) {
         dist = vlen (vortex_pos[i] - vortex_pos[idx]);
         if ( dist < 256.000 ) {
            Vortex_AddEdge (idx, i);
         }
      }
      i = (i + TRUE);
   }

};

float (float node) Vortex_TeleChainDepth = {

   local float depth;
   local float cur;
   local float prev;

   depth = 0.000;
   cur = node;
   while ( depth < VORTEX_TELE_CHAIN_MAX ) {
      prev = vortex_came[cur];
      if ( prev < 0.000 ) {
         break;
      }
      if ( vortex_tele_exit[prev] != cur ) {
         break;
      }
      depth = (depth + TRUE);
      cur = prev;
   }
   return depth;

};

float (float idx) Vortex_LiftWait = {
   return Vortex_LiftWaitAt (idx, time);

};

float (float idx, float at_time) Vortex_LiftWaitAt = {

   local float cycle;
   local float phase;
   local float start;
   local float end;
   local float wait;

   if ( idx < 0.000 ) {
      return 0.000;
   }
   cycle = vortex_lift_cycle[idx];
   if ( cycle <= 0.000 ) {
      return 0.000;
   }
   start = vortex_lift_up_start[idx];
   end = vortex_lift_up_end[idx];
   if ( end <= start ) {
      start = VORTEX_LIFT_UP_START;
      end = VORTEX_LIFT_UP_END;
   }
   phase = Vortex_Mod ((at_time - vortex_lift_phase[idx]), cycle);
   if ( phase < 0.000 ) {
      phase = 0.000;
   }
   phase = (phase / cycle);
   if ( (phase >= start) && (phase <= end) ) {
      return 0.000;
   }
   if ( phase < start ) {
      wait = ((start - phase) * cycle);
   } else {
      wait = (((1.000 - phase) + start) * cycle);
   }
   return wait;

};

float (float cur, float next) Vortex_LiftWaitETA = {

   local float dist;
   local float speed;
   local float eta;

   if ( (cur < 0.000) || (next < 0.000) ) {
      return 0.000;
   }
   dist = vlen (vortex_pos[next] - vortex_pos[cur]);
   speed = BOTSPEED;
   if ( speed < 10.000 ) {
      speed = 32.000;
   }
   eta = (dist / (speed * 10.000));
   return Vortex_LiftWaitAt (next, (time + eta));

};

float (vector from, vector to, float base_dist) Vortex_LiftSyncDist = {

   local float idx;
   local float dist;
   local float cycle;
   local float speed;
   local float eta;
   local float wait;
   local float target_eta;
   local float desired_dist;

   if ( base_dist <= 0.000 ) {
      return base_dist;
   }
   idx = Vortex_FindNode (to);
   if ( idx < 0.000 ) {
      return base_dist;
   }
   if ( vortex_type[idx] != VORTEX_NODE_LIFT ) {
      return base_dist;
   }
   dist = vlen (to - from);
   if ( (dist < 1.000) || (dist > 256.000) ) {
      return base_dist;
   }
   cycle = vortex_lift_cycle[idx];
   if ( cycle <= 0.000 ) {
      return base_dist;
   }
   speed = (base_dist * 10.000);
   if ( speed < 50.000 ) {
      speed = 50.000;
   }
   eta = (dist / speed);
   wait = Vortex_LiftWaitAt (idx, (time + eta));
   if ( wait < 0.050 ) {
      return base_dist;
   }
   target_eta = (eta + wait);
   if ( target_eta <= 0.000 ) {
      return base_dist;
   }
   desired_dist = ((dist / target_eta) / 10.000);
   if ( desired_dist < (base_dist * 0.500) ) {
      desired_dist = (base_dist * 0.500);
   }
   if ( desired_dist > base_dist ) {
      desired_dist = base_dist;
   }
   return desired_dist;

};

void (vector pos) Vortex_RefineLiftPhase = {

   local float idx;

   if ( !vortex_seeded ) {
      Vortex_Seed ();
   }
   idx = Vortex_FindNode (pos);
   if ( idx < 0.000 ) {
      return;
   }
   if ( vortex_type[idx] != VORTEX_NODE_LIFT ) {
      return;
   }
   vortex_lift_phase[idx] = time;
   vortex_lift_up_start[idx] = VORTEX_LIFT_UP_START;
   vortex_lift_up_end[idx] = VORTEX_LIFT_UP_END;

};

void (string cname, float ntype) Vortex_SeedClass = {

   local entity e;
   local float idx;
   local vector pos;

   e = find (world, classname, cname);
   while ( e ) {
      pos = e.origin;
      idx = Vortex_FindNode (pos);
      if ( idx < 0.000 ) {
         Vortex_AddNode (pos, ntype);
      }
      e = find (e, classname, cname);
   }

};

void () Vortex_Seed = {

   if ( vortex_seeded ) {
      return;
   }

   Vortex_SeedClass ("info_player_deathmatch", VORTEX_NODE_GROUND);
   Vortex_SeedClass ("info_player_start", VORTEX_NODE_GROUND);
   Vortex_SeedClass ("info_player_coop", VORTEX_NODE_GROUND);
   Vortex_SeedClass ("info_player_team1", VORTEX_NODE_GROUND);
   Vortex_SeedClass ("info_player_team2", VORTEX_NODE_GROUND);

   Vortex_SeedClass ("info_teleport_destination", VORTEX_NODE_TELE);
   Vortex_SeedClass ("trigger_teleport", VORTEX_NODE_TELE);

   Vortex_SeedClass ("weapon_supershotgun", VORTEX_NODE_ITEM);
   Vortex_SeedClass ("weapon_nailgun", VORTEX_NODE_ITEM);
   Vortex_SeedClass ("weapon_supernailgun", VORTEX_NODE_ITEM);
   Vortex_SeedClass ("weapon_grenadelauncher", VORTEX_NODE_ITEM);
   Vortex_SeedClass ("weapon_rocketlauncher", VORTEX_NODE_ITEM);
   Vortex_SeedClass ("weapon_lightning", VORTEX_NODE_ITEM);

   Vortex_SeedClass ("item_shells", VORTEX_NODE_ITEM);
   Vortex_SeedClass ("item_nails", VORTEX_NODE_ITEM);
   Vortex_SeedClass ("item_rockets", VORTEX_NODE_ITEM);
   Vortex_SeedClass ("item_cells", VORTEX_NODE_ITEM);
   Vortex_SeedClass ("item_health", VORTEX_NODE_ITEM);
   Vortex_SeedClass ("item_armor1", VORTEX_NODE_ITEM);
   Vortex_SeedClass ("item_armor2", VORTEX_NODE_ITEM);
   Vortex_SeedClass ("item_armor3", VORTEX_NODE_ITEM);

   Vortex_SeedClass ("item_artifact_invulnerability", VORTEX_NODE_ITEM);
   Vortex_SeedClass ("item_artifact_invisibility", VORTEX_NODE_ITEM);
   Vortex_SeedClass ("item_artifact_super_damage", VORTEX_NODE_ITEM);
   Vortex_SeedClass ("item_artifact_envirosuit", VORTEX_NODE_ITEM);

   vortex_seeded = TRUE;

};

void () Vortex_SampleLifts = {

   local float i;
   local float budget;
   local entity lift;
   local float travel;
   local float cycle;

   if ( time < (vortex_last_lift_sample + VORTEX_LIFT_SAMPLE_THROTTLE) ) {
      return;
   }
   vortex_last_lift_sample = time;

   if ( vortex_count <= 0.000 ) {
      return;
   }

   budget = 20.000;
   while ( budget > 0.000 ) {
      if ( vortex_lift_index >= vortex_count ) {
         vortex_lift_index = 0.000;
      }
      i = vortex_lift_index;
      if ( vortex_type[i] == VORTEX_NODE_TELE ) {
         vortex_lift_index = (vortex_lift_index + TRUE);
         budget = (budget - TRUE);
         continue;
      }
      if ( vortex_type[i] == VORTEX_NODE_ITEM ) {
         vortex_lift_index = (vortex_lift_index + TRUE);
         budget = (budget - TRUE);
         continue;
      }
      traceline (vortex_pos[i] + '0 0 32', vortex_pos[i] - '0 0 128', TRUE, world);
      lift = trace_ent;
      if ( lift && ((lift.classname == "func_plat") || (lift.classname == "plat") || (lift.classname == "func_train") || (lift.classname == "train")) ) {
         vortex_type[i] = VORTEX_NODE_LIFT;
         travel = vlen (lift.pos1 - lift.pos2);
         cycle = 0.000;
         if ( (lift.speed > 1.000) && (travel > 1.000) ) {
            cycle = ((travel / lift.speed) * 2.000) + 3.000;
         }
         if ( cycle <= 0.000 ) {
            cycle = lift.wait;
         }
         if ( cycle <= 0.000 ) {
            cycle = 4.000;
         }
         vortex_lift_cycle[i] = cycle;
         vortex_lift_phase[i] = time;
         if ( (lift.state == STATE_TOP) || (lift.state == STATE_DOWN) ) {
            vortex_lift_phase[i] = (time - (cycle * 0.500));
         }
         if ( vortex_lift_up_end[i] <= vortex_lift_up_start[i] ) {
            vortex_lift_up_start[i] = VORTEX_LIFT_UP_START;
            vortex_lift_up_end[i] = VORTEX_LIFT_UP_END;
         }
         if ( vortex_usage[i] < 2.000 ) {
            vortex_usage[i] = 2.000;
         }
      }
      vortex_lift_index = (vortex_lift_index + TRUE);
      budget = (budget - TRUE);
   }

};

void (vector entry_pos, vector exit_pos) Vortex_FuseTeleChain = {

   local vector entry_floor;
   local vector exit_floor;
   local float entry_idx;
   local float exit_idx;
   local float contents;
   local entity scan;

   if ( vlen (exit_pos - entry_pos) < VORTEX_TELE_WARP_DIST ) {
      return;
   }
   if ( !vortex_seeded ) {
      Vortex_Seed ();
   }

   entry_floor = entry_pos;
   entry_floor_z = (dropline (entry_floor) + 1.000);
   exit_floor = exit_pos;
   exit_floor_z = (dropline (exit_floor) + 1.000);

   contents = pointcontents (exit_floor);
   if ( (contents == CONTENT_SOLID) || (contents == CONTENT_SKY) ) {
      return;
   }

   entry_idx = Vortex_FindNode (entry_floor);
   if ( entry_idx < 0.000 ) {
      if ( vortex_count < VORTEX_MAX_NODES ) {
         entry_idx = Vortex_AddNode (entry_floor, VORTEX_NODE_TELE);
         Vortex_LinkNearby (entry_idx);
      }
   }
   exit_idx = Vortex_FindNode (exit_floor);
   if ( exit_idx < 0.000 ) {
      if ( vortex_count < VORTEX_MAX_NODES ) {
         exit_idx = Vortex_AddNode (exit_floor, VORTEX_NODE_GROUND);
         Vortex_LinkNearby (exit_idx);
      }
   }

   if ( (entry_idx < 0.000) || (exit_idx < 0.000) ) {
      return;
   }

   vortex_type[entry_idx] = VORTEX_NODE_TELE;
   if ( (vortex_tele_exit[entry_idx] < 0.000) || (vortex_tele_exit[entry_idx] == exit_idx) ) {
      vortex_tele_exit[entry_idx] = exit_idx;
      Vortex_AddEdgeOneWay (entry_idx, exit_idx);
   } else {
      return;
   }
   Vortex_BoostUsage (entry_idx, 5.000);
   Vortex_BoostUsage (exit_idx, 20.000);

   if ( BotDetectHazard (exit_floor) ) {
      CurseNode (exit_floor);
   } else {
      scan = findradius (exit_floor, 128.000);
      while ( scan ) {
         if ( scan.classname == "item_artifact_super_damage" ) {
            Vortex_BoostUsage (exit_idx, 30.000);
            break;
         }
         scan = scan.chain;
      }
   }

   if ( cvar ("developer") ) {
      dprint ("Tele chain: entry ");
      dprint (ftos (entry_idx));
      dprint (" exit ");
      dprint (ftos (exit_idx));
      dprint ("\n");
   }

};

void () Vortex_Flood = {

   local float trace_budget;
   local float cur;
   local float dir;
   local vector start;
   local vector offset;
   local vector endpos;
   local float contents;
   local float tidx;
   local vector floorpos;

   if ( time < (vortex_last_build + VORTEX_BUILD_THROTTLE) ) {
      return;
   }
   if ( vortex_count >= VORTEX_MAX_NODES ) {
      return;
   }

   if ( vortex_count <= 0.000 ) {
      vortex_seeded = FALSE;
   }
   if ( !vortex_seeded ) {
      Vortex_Seed ();
   }
   if ( vortex_count <= 0.000 ) {
      vortex_last_build = time;
      return;
   }

   trace_budget = VORTEX_TRACE_BUDGET;
   while ( trace_budget > 0.000 ) {
      if ( vortex_flood_index >= vortex_count ) {
         vortex_flood_index = 0.000;
      }

      cur = vortex_flood_index;
      dir = vortex_flood_dir;

      start = vortex_pos[cur];
      offset = Vortex_Dir (dir);
      traceline (start, (start + offset), TRUE, world);
      if ( trace_fraction > 0.700 ) {
         endpos = trace_endpos;
         contents = pointcontents (endpos);
         if ( (contents != CONTENT_LAVA) && (contents != CONTENT_SOLID) && (contents != CONTENT_SKY) ) {
            floorpos = endpos;
            floorpos_z = (dropline (endpos) + 1.000);
            tidx = Vortex_FindNode (floorpos);
            if ( tidx < 0.000 ) {
               if ( vortex_count < VORTEX_MAX_NODES ) {
                  tidx = Vortex_AddNode (floorpos, VORTEX_NODE_GROUND);
                  if ( tidx >= 0.000 ) {
                     Vortex_AddEdge (cur, tidx);
                  }
               }
            } else {
               Vortex_AddEdge (cur, tidx);
            }
         }
      }

      vortex_flood_dir = (vortex_flood_dir + TRUE);
      if ( vortex_flood_dir >= 8.000 ) {
         vortex_flood_dir = 0.000;
         vortex_flood_index = (vortex_flood_index + TRUE);
      }
      trace_budget = (trace_budget - TRUE);
   }

   vortex_last_build = time;

};

float (float cur, float next) Vortex_EdgeCost = {

   local float cost;
   local float usage;
   local float wait;
   local float chain;
   local float impatience;

   if ( !Vortex_IndexValid (cur) || !Vortex_IndexValid (next) ) {
      return ( 999999.000 );
   }

   if ( vortex_tele_exit[cur] == next ) {
      cost = VORTEX_TELE_COST;
      cost = (cost + GetCursePenalty (vortex_pos[next]));
      chain = Vortex_TeleChainDepth (cur);
      if ( chain >= VORTEX_TELE_CHAIN_MAX ) {
         cost = (cost + 1000.000);
      }
      return ( cost );
   }

   cost = vlen (vortex_pos[next] - vortex_pos[cur]);
   cost = (cost + GetCursePenalty (vortex_pos[next]));

   if ( (vortex_ripple_type[cur] > 0.000) && (vortex_ripple_target[cur] == next) ) {
      cost = (cost + (vortex_ripple_cost[cur] * vortex_ripple_steps[cur] * 20.000));
   }
   if ( (vortex_leap_target[cur] >= 0.000) && (vortex_leap_target[cur] == next) ) {
      cost = (cost + (vortex_leap_cost[cur] * 20.000));
      if ( self.health < (vortex_leap_risk[cur] * 1.200) ) {
         cost = (cost + 500.000);
      } else {
         cost = (cost - 200.000);
      }
   }

   if ( vortex_type[next] == VORTEX_NODE_LIFT ) {
      wait = Vortex_LiftWaitETA (cur, next);
      impatience = (1.000 - (self.skil * 0.080));
      if ( impatience < 0.200 ) {
         impatience = 0.200;
      }
      cost = (cost + (wait * impatience));
   }

   usage = vortex_usage[next];
   if ( usage < 0.100 ) {
      usage = 0.100;
   }
   cost = (cost / usage);

   return ( cost );

};

float (float start, float goal) Vortex_AStar = {

   local float i;
   local float cur;
   local float best;
   local float best_i;
   local float neighbor;
   local float base;
   local float n;
   local float tentative;
   local float iter;

   if ( (start < 0.000) || (goal < 0.000) ) {
      return ( FALSE );
   }

   i = 0.000;
   while ( i < vortex_count ) {
      vortex_g[i] = 999999.000;
      vortex_f[i] = 999999.000;
      vortex_came[i] = -1.000;
      vortex_state[i] = 0.000;
      i = (i + TRUE);
   }

   vortex_open_count = TRUE;
   vortex_open[0] = start;
   vortex_g[start] = 0.000;
   vortex_f[start] = vlen (vortex_pos[goal] - vortex_pos[start]);
   vortex_state[start] = 1.000;

   iter = 0.000;
   while ( vortex_open_count > 0.000 ) {
      iter = (iter + TRUE);
      if ( iter > 256.000 ) {
         break;
      }

      best = 999999.000;
      best_i = -1.000;
      i = 0.000;
      while ( i < vortex_open_count ) {
         cur = vortex_open[i];
         if ( vortex_f[cur] < best ) {
            best = vortex_f[cur];
            best_i = i;
         }
         i = (i + TRUE);
      }
      if ( best_i < 0.000 ) {
         break;
      }
      cur = vortex_open[best_i];
      vortex_open_count = (vortex_open_count - TRUE);
      vortex_open[best_i] = vortex_open[vortex_open_count];
      vortex_state[cur] = 2.000;

      if ( cur == goal ) {
         return ( TRUE );
      }

      base = (cur * VORTEX_MAX_CONN);
      n = 0.000;
      while ( n < vortex_conn_count[cur] ) {
         neighbor = vortex_conn[base + n];
         if ( neighbor < 0.000 ) {
            n = (n + TRUE);
            continue;
         }
         if ( !Vortex_IndexValid (neighbor) ) {
            n = (n + TRUE);
            continue;
         }
         if ( vortex_state[neighbor] == 2.000 ) {
            n = (n + TRUE);
            continue;
         }

         tentative = (vortex_g[cur] + Vortex_EdgeCost (cur, neighbor));
         if ( tentative < vortex_g[neighbor] ) {
            vortex_came[neighbor] = cur;
            vortex_g[neighbor] = tentative;
            vortex_f[neighbor] = tentative + vlen (vortex_pos[goal] - vortex_pos[neighbor]);
            if ( vortex_state[neighbor] != 1.000 ) {
               if ( vortex_open_count < VORTEX_MAX_NODES ) {
                  vortex_open[vortex_open_count] = neighbor;
                  vortex_open_count = (vortex_open_count + TRUE);
                  vortex_state[neighbor] = 1.000;
               }
            }
         }
         n = (n + TRUE);
      }
   }

   return ( FALSE );

};

vector (float start, float goal) Vortex_Reconstruct = {

   local float cur;
   local float prev;

   if ( start == goal ) {
      return ( vortex_pos[goal] );
   }

   cur = goal;
   if ( !Vortex_IndexValid (cur) ) {
      return ( '0 0 0' );
   }
   prev = vortex_came[cur];
   if ( prev < 0.000 ) {
      return ( '0 0 0' );
   }

   while ( (prev != start) && (prev >= 0.000) ) {
      cur = prev;
      prev = vortex_came[cur];
   }

   if ( Vortex_IndexValid (vortex_leap_target[cur]) ) {
      if ( vortex_came[vortex_leap_target[cur]] == cur ) {
         if ( vortex_leap_pos[cur] != '0 0 0' ) {
            return ( vortex_leap_pos[cur] );
         }
      }
   }
   if ( vortex_ripple_type[cur] > 0.000 ) {
      if ( Vortex_IndexValid (vortex_ripple_target[cur]) ) {
         if ( vortex_came[vortex_ripple_target[cur]] == cur ) {
            if ( vortex_ripple_pos[cur] != '0 0 0' ) {
               return ( vortex_ripple_pos[cur] );
            }
         }
      }
   }

   return ( vortex_pos[cur] );

};

vector (vector start_pos, vector goal_pos) Vortex_NextStep = {

   local float s;
   local float g;
   local vector next;

   s = Vortex_FindNode (start_pos);
   if ( s < 0.000 ) {
      if ( vortex_count < VORTEX_MAX_NODES ) {
         s = Vortex_AddNode (start_pos, VORTEX_NODE_GROUND);
         Vortex_LinkNearby (s);
      }
   }
   g = Vortex_FindNode (goal_pos);
   if ( g < 0.000 ) {
      if ( vortex_count < VORTEX_MAX_NODES ) {
         g = Vortex_AddNode (goal_pos, VORTEX_NODE_GROUND);
         Vortex_LinkNearby (g);
      }
   }

   if ( (s < 0.000) || (g < 0.000) ) {
      return ( '0 0 0' );
   }
   if ( !Vortex_AStar (s, g) ) {
      return ( '0 0 0' );
   }

   next = Vortex_Reconstruct (s, g);
   if ( next != '0 0 0' ) {
      Vortex_BoostUsage (s, 0.500);
      Vortex_BoostUsage (g, 0.500);
   }
   return ( next );

};

float () Vortex_Ready = {

   if ( vortex_count >= VORTEX_MIN_READY ) {
      return ( TRUE );
   }
   return ( FALSE );

};

void (vector start, vector end) Vortex_RecordEpisode = {

   local float s;
   local float e;

   s = Vortex_FindNode (start);
   if ( s < 0.000 ) {
      if ( vortex_count < VORTEX_MAX_NODES ) {
         s = Vortex_AddNode (start, VORTEX_NODE_GROUND);
         Vortex_LinkNearby (s);
      }
   }
   e = Vortex_FindNode (end);
   if ( e < 0.000 ) {
      if ( vortex_count < VORTEX_MAX_NODES ) {
         e = Vortex_AddNode (end, VORTEX_NODE_GROUND);
         Vortex_LinkNearby (e);
      }
   }

   if ( (s < 0.000) || (e < 0.000) ) {
      return;
   }

   Vortex_AddEdge (s, e);
   Vortex_BoostUsage (s, 10.000);
   Vortex_BoostUsage (e, 10.000);

};

float () Vortex_ApplyGoal = {

   local entity goal;
   local vector goal_pos;
   local vector next;

   if ( !self.goalentity || (self.goalentity == world) ) {
      return ( FALSE );
   }
   if ( self.feeler_mode_active ) {
      return ( FALSE );
   }
   goal = self.goalentity.goalentity;
   if ( !goal || (goal == world) ) {
      return ( FALSE );
   }
   if ( goal.classname == "BotPath" ) {
      return ( FALSE );
   }
   if ( (goal.classname == "train") || (goal.classname == "plat") || (goal.classname == "func_plat") ) {
      return ( FALSE );
   }

   if ( !Vortex_Ready () ) {
      return ( FALSE );
   }

   goal_pos = goal.origin;
   traceline (self.origin, goal_pos, TRUE, self);
   if ( trace_fraction == 1.000 ) {
      return ( FALSE );
   }
   RippleDetect ();

   if ( (time < (self.vortex_path_time + 0.500)) && (vlen (self.vortex_path_goal - goal_pos) < 64.000) ) {
      next = self.vortex_path_next;
   } else {
      next = Apex_VortexNext (self.origin, goal_pos);
      self.vortex_path_goal = goal_pos;
      self.vortex_path_next = next;
      self.vortex_path_time = time;
   }

   if ( next == '0 0 0' ) {
      return ( FALSE );
   }

   setorigin (self.goalentity, next);
   return ( TRUE );

};

void (float idx) Vortex_RemoveNode = {

   local float last;
   local float i;
   local float base;
   local float c;
   local float moved;
   local float old_exit;

   last = (vortex_count - TRUE);
   if ( last < 0.000 ) {
      return;
   }
   moved = last;
   if ( idx == last ) {
      moved = -1.000;
   }

   if ( idx != last ) {
      vortex_pos[idx] = vortex_pos[last];
      vortex_conn_count[idx] = vortex_conn_count[last];
      vortex_type[idx] = vortex_type[last];
      vortex_usage[idx] = vortex_usage[last];
      vortex_tele_exit[idx] = vortex_tele_exit[last];
      vortex_lift_cycle[idx] = vortex_lift_cycle[last];
      vortex_lift_phase[idx] = vortex_lift_phase[last];
      vortex_lift_up_start[idx] = vortex_lift_up_start[last];
      vortex_lift_up_end[idx] = vortex_lift_up_end[last];
      vortex_ripple_type[idx] = vortex_ripple_type[last];
      vortex_ripple_target[idx] = vortex_ripple_target[last];
      vortex_ripple_cost[idx] = vortex_ripple_cost[last];
      vortex_ripple_steps[idx] = vortex_ripple_steps[last];
      vortex_ripple_flags[idx] = vortex_ripple_flags[last];
      vortex_ripple_pos[idx] = vortex_ripple_pos[last];
      vortex_leap_target[idx] = vortex_leap_target[last];
      vortex_leap_cost[idx] = vortex_leap_cost[last];
      vortex_leap_risk[idx] = vortex_leap_risk[last];
      vortex_leap_pos[idx] = vortex_leap_pos[last];

      base = (idx * VORTEX_MAX_CONN);
      c = 0.000;
      while ( c < vortex_conn_count[idx] ) {
         vortex_conn[base + c] = vortex_conn[(last * VORTEX_MAX_CONN) + c];
         c = (c + TRUE);
      }
   }

   vortex_count = last;

   i = 0.000;
   while ( i < vortex_count ) {
      old_exit = vortex_tele_exit[i];
      if ( moved >= 0.000 ) {
         if ( old_exit == moved ) {
            vortex_tele_exit[i] = idx;
         } else if ( old_exit == idx ) {
            vortex_tele_exit[i] = -1.000;
         }
      } else {
         if ( old_exit == idx ) {
            vortex_tele_exit[i] = -1.000;
         }
      }
      if ( vortex_ripple_target[i] >= 0.000 ) {
         if ( moved >= 0.000 ) {
            if ( vortex_ripple_target[i] == moved ) {
               vortex_ripple_target[i] = idx;
            } else if ( vortex_ripple_target[i] == idx ) {
               vortex_ripple_target[i] = -1.000;
               vortex_ripple_type[i] = 0.000;
               vortex_ripple_steps[i] = 0.000;
               vortex_ripple_cost[i] = 0.000;
               vortex_ripple_flags[i] = 0.000;
               vortex_ripple_pos[i] = '0 0 0';
            }
         } else {
            if ( vortex_ripple_target[i] == idx ) {
               vortex_ripple_target[i] = -1.000;
               vortex_ripple_type[i] = 0.000;
               vortex_ripple_steps[i] = 0.000;
               vortex_ripple_cost[i] = 0.000;
               vortex_ripple_flags[i] = 0.000;
               vortex_ripple_pos[i] = '0 0 0';
            }
         }
      }
      if ( vortex_leap_target[i] >= 0.000 ) {
         if ( moved >= 0.000 ) {
            if ( vortex_leap_target[i] == moved ) {
               vortex_leap_target[i] = idx;
            } else if ( vortex_leap_target[i] == idx ) {
               vortex_leap_target[i] = -1.000;
               vortex_leap_cost[i] = 0.000;
               vortex_leap_risk[i] = 0.000;
               vortex_leap_pos[i] = '0 0 0';
            }
         } else {
            if ( vortex_leap_target[i] == idx ) {
               vortex_leap_target[i] = -1.000;
               vortex_leap_cost[i] = 0.000;
               vortex_leap_risk[i] = 0.000;
               vortex_leap_pos[i] = '0 0 0';
            }
         }
      }
      if ( vortex_tele_exit[i] == i ) {
         vortex_tele_exit[i] = -1.000;
      }
      if ( vortex_ripple_target[i] == i ) {
         vortex_ripple_target[i] = -1.000;
         vortex_ripple_type[i] = 0.000;
         vortex_ripple_steps[i] = 0.000;
         vortex_ripple_cost[i] = 0.000;
         vortex_ripple_flags[i] = 0.000;
         vortex_ripple_pos[i] = '0 0 0';
      }
      if ( vortex_leap_target[i] == i ) {
         vortex_leap_target[i] = -1.000;
         vortex_leap_cost[i] = 0.000;
         vortex_leap_risk[i] = 0.000;
         vortex_leap_pos[i] = '0 0 0';
      }
      base = (i * VORTEX_MAX_CONN);
      c = 0.000;
      while ( c < vortex_conn_count[i] ) {
         if ( (moved >= 0.000) && (vortex_conn[base + c] == moved) ) {
            vortex_conn[base + c] = idx;
            c = (c + TRUE);
            continue;
         }
         if ( vortex_conn[base + c] == idx ) {
            vortex_conn_count[i] = (vortex_conn_count[i] - TRUE);
            vortex_conn[base + c] = vortex_conn[base + vortex_conn_count[i]];
            continue;
         }
         c = (c + TRUE);
      }
      i = (i + TRUE);
   }

};

void () Vortex_Decay = {

   local float i;

   if ( time < (vortex_last_decay + VORTEX_DECAY_THROTTLE) ) {
      return;
   }
   vortex_last_decay = time;

   i = 0.000;
   while ( i < vortex_count ) {
      vortex_usage[i] = (vortex_usage[i] * 0.990);
      if ( (vortex_type[i] == VORTEX_NODE_TELE) && (vortex_tele_exit[i] >= 0.000) && (vortex_usage[i] < 0.500) ) {
         vortex_tele_exit[i] = -1.000;
      }
      if ( (vortex_leap_target[i] >= 0.000) && (vortex_usage[i] < 0.200) ) {
         vortex_leap_target[i] = -1.000;
         vortex_leap_cost[i] = 0.000;
         vortex_leap_risk[i] = 0.000;
         vortex_leap_pos[i] = '0 0 0';
      }
      if ( (vortex_ripple_type[i] > 0.000) && (vortex_ripple_steps[i] > 5.000) && (vortex_usage[i] < 0.500) ) {
         vortex_ripple_type[i] = 0.000;
         vortex_ripple_target[i] = -1.000;
         vortex_ripple_cost[i] = 0.000;
         vortex_ripple_steps[i] = 0.000;
         vortex_ripple_flags[i] = 0.000;
         vortex_ripple_pos[i] = '0 0 0';
      }
      if ( (vortex_ripple_type[i] > 0.000) && (vortex_usage[i] < 0.050) ) {
         vortex_ripple_type[i] = 0.000;
         vortex_ripple_target[i] = -1.000;
         vortex_ripple_cost[i] = 0.000;
         vortex_ripple_steps[i] = 0.000;
         vortex_ripple_flags[i] = 0.000;
         vortex_ripple_pos[i] = '0 0 0';
      }
      if ( (vortex_usage[i] < 0.100) && (vortex_conn_count[i] < 2.000) && (vortex_count > VORTEX_MIN_READY) ) {
         Vortex_RemoveNode (i);
         continue;
      }
      i = (i + TRUE);
   }

};

void () Vortex_Frame = {

   Vortex_Flood ();
   Vortex_SampleLifts ();
   Vortex_Decay ();

};
