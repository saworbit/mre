// ai_apex.qc: HPA* over Vortex Navmesh

float (vector pos) GetCursePenalty;
vector (vector start, vector goal) Vortex_NextStep;
float () Vortex_Ready;
void (float c1, float c2, float ptype) Apex_AddPortalTyped;

#define VORTEX_MAX_NODES 512
#define VORTEX_MAX_CONN 8
#define VORTEX_NODE_LIFT 3.000

#define APEX_MAX_CLUSTERS 64
#define APEX_MAX_PORTALS 256
#define APEX_BUILD_THROTTLE 10.000
#define APEX_MIN_NODES 100.000

#define APEX_PORTAL_NORMAL 0.000
#define APEX_PORTAL_LIFT 1.000
#define APEX_PORTAL_TELE 2.000

vector apex_center[APEX_MAX_CLUSTERS];
float apex_radius[APEX_MAX_CLUSTERS];
float apex_cluster_count;
float apex_cluster_of_node[VORTEX_MAX_NODES];
float apex_portals[APEX_MAX_CLUSTERS * APEX_MAX_PORTALS];
float apex_portal_count[APEX_MAX_CLUSTERS];
float apex_portal_type[APEX_MAX_CLUSTERS * APEX_MAX_PORTALS];
float apex_last_build;
float apex_last_vnode_count;

float apex_g[APEX_MAX_CLUSTERS];
float apex_f[APEX_MAX_CLUSTERS];
float apex_came[APEX_MAX_CLUSTERS];
float apex_state[APEX_MAX_CLUSTERS];
float apex_open[APEX_MAX_CLUSTERS];
float apex_open_count;

void () Apex_Reset = {

   apex_cluster_count = 0.000;
   apex_last_build = 0.000;
   apex_last_vnode_count = 0.000;

};

float (vector pos) Apex_FindCluster = {

   local float i;
   local float best;
   local float best_i;
   local float dist;

   if ( apex_cluster_count <= 0.000 ) {
      return ( -1.000 );
   }

   best = 999999.000;
   best_i = -1.000;
   i = 0.000;
   while ( i < apex_cluster_count ) {
      dist = vlen (pos - apex_center[i]);
      if ( dist < best ) {
         best = dist;
         best_i = i;
      }
      i = (i + TRUE);
   }

   return ( best_i );

};

void (float c1, float c2) Apex_AddPortal = {

   Apex_AddPortalTyped (c1, c2, APEX_PORTAL_NORMAL);

};

void (float c1, float c2, float ptype) Apex_AddPortalTyped = {

   local float i;
   local float base1;
   local float base2;

   if ( (c1 < 0.000) || (c2 < 0.000) ) {
      return;
   }
   if ( c1 == c2 ) {
      return;
   }

   base1 = (c1 * APEX_MAX_PORTALS);
   i = 0.000;
   while ( i < apex_portal_count[c1] ) {
      if ( apex_portals[base1 + i] == c2 ) {
         if ( ptype > apex_portal_type[base1 + i] ) {
            apex_portal_type[base1 + i] = ptype;
         }
         return;
      }
      i = (i + TRUE);
   }
   if ( apex_portal_count[c1] < APEX_MAX_PORTALS ) {
      apex_portals[base1 + apex_portal_count[c1]] = c2;
      apex_portal_type[base1 + apex_portal_count[c1]] = ptype;
      apex_portal_count[c1] = (apex_portal_count[c1] + TRUE);
   }

   base2 = (c2 * APEX_MAX_PORTALS);
   i = 0.000;
   while ( i < apex_portal_count[c2] ) {
      if ( apex_portals[base2 + i] == c1 ) {
         if ( ptype > apex_portal_type[base2 + i] ) {
            apex_portal_type[base2 + i] = ptype;
         }
         return;
      }
      i = (i + TRUE);
   }
   if ( apex_portal_count[c2] < APEX_MAX_PORTALS ) {
      apex_portals[base2 + apex_portal_count[c2]] = c1;
      apex_portal_type[base2 + apex_portal_count[c2]] = ptype;
      apex_portal_count[c2] = (apex_portal_count[c2] + TRUE);
   }

};

void () Apex_BuildClusters = {

   local float desired;
   local float step;
   local float i;
   local float c;
   local float best;
   local float best_c;
   local float dist;
   local float node;
   local float base;
   local float n;
   local float neigh;
   local float ptype;

   if ( !Vortex_Ready () ) {
      apex_cluster_count = 0.000;
      return;
   }
   if ( vortex_count < APEX_MIN_NODES ) {
      apex_cluster_count = 0.000;
      return;
   }

   desired = floor (vortex_count / 12.000);
   if ( desired < 8.000 ) {
      desired = 8.000;
   }
   if ( desired > APEX_MAX_CLUSTERS ) {
      desired = APEX_MAX_CLUSTERS;
   }

   step = floor (vortex_count / desired);
   if ( step < TRUE ) {
      step = TRUE;
   }

   apex_cluster_count = 0.000;
   i = 0.000;
   while ( (i < vortex_count) && (apex_cluster_count < desired) ) {
      apex_center[apex_cluster_count] = vortex_pos[i];
      apex_radius[apex_cluster_count] = 512.000;
      apex_portal_count[apex_cluster_count] = 0.000;
      apex_cluster_count = (apex_cluster_count + TRUE);
      i = (i + step);
   }

   i = 0.000;
   while ( i < vortex_count ) {
      best = 999999.000;
      best_c = 0.000;
      c = 0.000;
      while ( c < apex_cluster_count ) {
         dist = vlen (vortex_pos[i] - apex_center[c]);
         if ( dist < best ) {
            best = dist;
            best_c = c;
         }
         c = (c + TRUE);
      }
      apex_cluster_of_node[i] = best_c;
      i = (i + TRUE);
   }

   i = 0.000;
   while ( i < vortex_count ) {
      node = i;
      base = (node * VORTEX_MAX_CONN);
      n = 0.000;
      while ( n < vortex_conn_count[node] ) {
         neigh = vortex_conn[base + n];
         if ( neigh >= 0.000 ) {
            if ( apex_cluster_of_node[node] != apex_cluster_of_node[neigh] ) {
               ptype = APEX_PORTAL_NORMAL;
               if ( vortex_tele_exit[node] == neigh ) {
                  ptype = APEX_PORTAL_TELE;
               } else if ( (vortex_type[node] == VORTEX_NODE_LIFT) || (vortex_type[neigh] == VORTEX_NODE_LIFT) ) {
                  ptype = APEX_PORTAL_LIFT;
               }
               Apex_AddPortalTyped (apex_cluster_of_node[node], apex_cluster_of_node[neigh], ptype);
            }
         }
         n = (n + TRUE);
      }
      i = (i + TRUE);
   }

};

float (float start_c, float goal_c) Apex_NextCluster = {

   local float i;
   local float cur;
   local float best;
   local float best_i;
   local float base;
   local float p;
   local float neigh;
   local float tentative;
   local float ptype;
   local float iter;

   if ( (start_c < 0.000) || (goal_c < 0.000) ) {
      return ( -1.000 );
   }
   if ( start_c == goal_c ) {
      return ( start_c );
   }

   i = 0.000;
   while ( i < apex_cluster_count ) {
      apex_g[i] = 999999.000;
      apex_f[i] = 999999.000;
      apex_came[i] = -1.000;
      apex_state[i] = 0.000;
      i = (i + TRUE);
   }

   apex_open_count = TRUE;
   apex_open[0] = start_c;
   apex_g[start_c] = 0.000;
   apex_f[start_c] = vlen (apex_center[goal_c] - apex_center[start_c]);
   apex_state[start_c] = 1.000;

   iter = 0.000;
   while ( apex_open_count > 0.000 ) {
      iter = (iter + TRUE);
      if ( iter > 128.000 ) {
         break;
      }

      best = 999999.000;
      best_i = -1.000;
      i = 0.000;
      while ( i < apex_open_count ) {
         cur = apex_open[i];
         if ( apex_f[cur] < best ) {
            best = apex_f[cur];
            best_i = i;
         }
         i = (i + TRUE);
      }
      if ( best_i < 0.000 ) {
         break;
      }
      cur = apex_open[best_i];
      apex_open_count = (apex_open_count - TRUE);
      apex_open[best_i] = apex_open[apex_open_count];
      apex_state[cur] = 2.000;

      if ( cur == goal_c ) {
         break;
      }

      base = (cur * APEX_MAX_PORTALS);
      p = 0.000;
      while ( p < apex_portal_count[cur] ) {
         neigh = apex_portals[base + p];
         if ( apex_state[neigh] == 2.000 ) {
            p = (p + TRUE);
            continue;
         }
         ptype = apex_portal_type[base + p];
         tentative = (apex_g[cur] + vlen (apex_center[neigh] - apex_center[cur]));
         if ( ptype == APEX_PORTAL_TELE ) {
            tentative = (apex_g[cur] + 20.000);
         } else if ( ptype == APEX_PORTAL_LIFT ) {
            tentative = (apex_g[cur] + 30.000);
         }
         tentative = (tentative + GetCursePenalty (apex_center[neigh]));
         if ( tentative < apex_g[neigh] ) {
            apex_came[neigh] = cur;
            apex_g[neigh] = tentative;
            apex_f[neigh] = tentative + vlen (apex_center[goal_c] - apex_center[neigh]);
            if ( apex_state[neigh] != 1.000 ) {
               if ( apex_open_count < APEX_MAX_CLUSTERS ) {
                  apex_open[apex_open_count] = neigh;
                  apex_open_count = (apex_open_count + TRUE);
                  apex_state[neigh] = 1.000;
               }
            }
         }
         p = (p + TRUE);
      }
   }

   cur = goal_c;
   if ( apex_came[cur] < 0.000 ) {
      return ( -1.000 );
   }
   while ( (apex_came[cur] != start_c) && (apex_came[cur] >= 0.000) ) {
      cur = apex_came[cur];
   }

   return ( cur );

};

vector (vector start, vector goal) Apex_VortexNext = {

   local float start_c;
   local float goal_c;
   local float next_c;
   local vector target;

   if ( apex_cluster_count <= 0.000 ) {
      return Vortex_NextStep (start, goal);
   }
   start_c = Apex_FindCluster (start);
   goal_c = Apex_FindCluster (goal);
   if ( (start_c < 0.000) || (goal_c < 0.000) ) {
      return Vortex_NextStep (start, goal);
   }
   if ( start_c == goal_c ) {
      return Vortex_NextStep (start, goal);
   }

   next_c = Apex_NextCluster (start_c, goal_c);
   if ( next_c < 0.000 ) {
      return Vortex_NextStep (start, goal);
   }

   target = apex_center[next_c];
   return Vortex_NextStep (start, target);

};

void () Apex_MaybeRebuild = {

   local float diff;

   if ( time < (apex_last_build + APEX_BUILD_THROTTLE) ) {
      return;
   }
   if ( vortex_count < APEX_MIN_NODES ) {
      apex_cluster_count = 0.000;
      apex_last_build = time;
      apex_last_vnode_count = vortex_count;
      return;
   }
   diff = (vortex_count - apex_last_vnode_count);
   if ( diff < 0.000 ) {
      diff = -diff;
   }
   if ( diff < 20.000 ) {
      apex_last_build = time;
      return;
   }

   Apex_BuildClusters ();
   apex_last_build = time;
   apex_last_vnode_count = vortex_count;

};

void () Apex_Frame = {

   Apex_MaybeRebuild ();

};
