
void () InitBodyQue;

void () clientInitMaxClients;

// Forward declaration for portal awareness (defined in botroute.qc)
void () LinkTeleporters;

// Forward declaration for chat system (defined in botchat.qc)
void () InitChatSystem;

void () main =
{
   dprint ("main function\n");
   precache_file ("progs.dat");
   precache_file ("gfx.wad");
   precache_file ("quake.rc");
   precache_file ("default.cfg");
   precache_file ("end1.bin");
   precache_file2 ("end2.bin");
   precache_file ("demo1.dem");
   precache_file ("demo2.dem");
   precache_file ("demo3.dem");
   precache_file ("gfx/palette.lmp");
   precache_file ("gfx/colormap.lmp");
   precache_file2 ("gfx/pop.lmp");
   precache_file ("gfx/complete.lmp");
   precache_file ("gfx/inter.lmp");
   precache_file ("gfx/ranking.lmp");
   precache_file ("gfx/vidmodes.lmp");
   precache_file ("gfx/finale.lmp");
   precache_file ("gfx/conback.lmp");
   precache_file ("gfx/qplaque.lmp");
   precache_file ("gfx/menudot1.lmp");
   precache_file ("gfx/menudot2.lmp");
   precache_file ("gfx/menudot3.lmp");
   precache_file ("gfx/menudot4.lmp");
   precache_file ("gfx/menudot5.lmp");
   precache_file ("gfx/menudot6.lmp");
   precache_file ("gfx/menuplyr.lmp");
   precache_file ("gfx/bigbox.lmp");
   precache_file ("gfx/dim_modm.lmp");
   precache_file ("gfx/dim_drct.lmp");
   precache_file ("gfx/dim_ipx.lmp");
   precache_file ("gfx/dim_tcp.lmp");
   precache_file ("gfx/dim_mult.lmp");
   precache_file ("gfx/mainmenu.lmp");
   precache_file ("gfx/box_tl.lmp");
   precache_file ("gfx/box_tm.lmp");
   precache_file ("gfx/box_tr.lmp");
   precache_file ("gfx/box_ml.lmp");
   precache_file ("gfx/box_mm.lmp");
   precache_file ("gfx/box_mm2.lmp");
   precache_file ("gfx/box_mr.lmp");
   precache_file ("gfx/box_bl.lmp");
   precache_file ("gfx/box_bm.lmp");
   precache_file ("gfx/box_br.lmp");
   precache_file ("gfx/sp_menu.lmp");
   precache_file ("gfx/ttl_sgl.lmp");
   precache_file ("gfx/ttl_main.lmp");
   precache_file ("gfx/ttl_cstm.lmp");
   precache_file ("gfx/mp_menu.lmp");
   precache_file ("gfx/netmen1.lmp");
   precache_file ("gfx/netmen2.lmp");
   precache_file ("gfx/netmen3.lmp");
   precache_file ("gfx/netmen4.lmp");
   precache_file ("gfx/netmen5.lmp");
   precache_file ("gfx/sell.lmp");
   precache_file ("gfx/help0.lmp");
   precache_file ("gfx/help1.lmp");
   precache_file ("gfx/help2.lmp");
   precache_file ("gfx/help3.lmp");
   precache_file ("gfx/help4.lmp");
   precache_file ("gfx/help5.lmp");
   precache_file ("gfx/pause.lmp");
   precache_file ("gfx/loading.lmp");
   precache_file ("gfx/p_option.lmp");
   precache_file ("gfx/p_load.lmp");
   precache_file ("gfx/p_save.lmp");
   precache_file ("gfx/p_multi.lmp");
   precache_sound ("misc/menu1.wav");
   precache_sound ("misc/menu2.wav");
   precache_sound ("misc/menu3.wav");
   precache_sound ("ambience/water1.wav");
   precache_sound ("ambience/wind2.wav");
   precache_file ("maps/start.bsp");
   precache_file ("maps/e1m1.bsp");
   precache_file ("maps/e1m2.bsp");
   precache_file ("maps/e1m3.bsp");
   precache_file ("maps/e1m4.bsp");
   precache_file ("maps/e1m5.bsp");
   precache_file ("maps/e1m6.bsp");
   precache_file ("maps/e1m7.bsp");
   precache_file ("maps/e1m8.bsp");
   precache_file2 ("gfx/pop.lmp");
   precache_file2 ("maps/e2m1.bsp");
   precache_file2 ("maps/e2m2.bsp");
   precache_file2 ("maps/e2m3.bsp");
   precache_file2 ("maps/e2m4.bsp");
   precache_file2 ("maps/e2m5.bsp");
   precache_file2 ("maps/e2m6.bsp");
   precache_file2 ("maps/e2m7.bsp");
   precache_file2 ("maps/e3m1.bsp");
   precache_file2 ("maps/e3m2.bsp");
   precache_file2 ("maps/e3m3.bsp");
   precache_file2 ("maps/e3m4.bsp");
   precache_file2 ("maps/e3m5.bsp");
   precache_file2 ("maps/e3m6.bsp");
   precache_file2 ("maps/e3m7.bsp");
   precache_file2 ("maps/e4m1.bsp");
   precache_file2 ("maps/e4m2.bsp");
   precache_file2 ("maps/e4m3.bsp");
   precache_file2 ("maps/e4m4.bsp");
   precache_file2 ("maps/e4m5.bsp");
   precache_file2 ("maps/e4m6.bsp");
   precache_file2 ("maps/e4m7.bsp");
   precache_file2 ("maps/e4m8.bsp");
   precache_file2 ("maps/end.bsp");
   precache_file2 ("maps/dm1.bsp");
   precache_file2 ("maps/dm2.bsp");
   precache_file2 ("maps/dm3.bsp");
   precache_file2 ("maps/dm4.bsp");
   precache_file2 ("maps/dm5.bsp");
   precache_file2 ("maps/dm6.bsp");
}; //end of the function main
entity lastspawn;

void () worldspawn =
{
   clientInitMaxClients ();
   lastspawn = world;
   InitBodyQue ();
   CamSpawn ();
   // Initialize chat system constants and globals
   InitChatSystem ();
   // Initialize noise queue entity (used by legacy hearing logic)
   NOISEQUEUE = noisetarget ();
   // Initialize player observation learning system (Phase 2: Live Learning)
   // Clean up any existing learned RJ waypoints from previous sessions
   local entity old_rj;
   old_rj = find(world, classname, "BotPath");
   while (old_rj)
   {
      if (old_rj.rj_learned)
      {
         local entity next_ent;
         next_ent = find(old_rj, classname, "BotPath");
         remove(old_rj);
         old_rj = next_ent;
      }
      else
      {
         old_rj = find(old_rj, classname, "BotPath");
      }
   }
   // Reset counters
   learned_rj_count = 0.000;
   LEARNED_RJ_MAX = 50.000;  // Cap at 50 learned RJ waypoints per map
   learned_rj_head = world;
   // PHASE 1 FIX: Don't override sv_gravity - read server's value instead
   // Special maps can set their own gravity in worldspawn if needed
   // setBotGravity() will read whatever the server has configured
   W_Precache ();
   precache_sound ("demon/dland2.wav");
   precache_sound ("misc/h2ohit1.wav");
   precache_sound ("items/itembk2.wav");
   precache_sound ("player/plyrjmp8.wav");
   precache_sound ("player/land.wav");
   precache_sound ("player/land2.wav");
   precache_sound ("player/drown1.wav");
   precache_sound ("player/drown2.wav");
   precache_sound ("player/gasp1.wav");
   precache_sound ("player/gasp2.wav");
   precache_sound ("player/h2odeath.wav");
   precache_sound ("misc/talk.wav");
   precache_sound ("player/teledth1.wav");
   precache_sound ("misc/r_tele1.wav");
   precache_sound ("misc/r_tele2.wav");
   precache_sound ("misc/r_tele3.wav");
   precache_sound ("misc/r_tele4.wav");
   precache_sound ("misc/r_tele5.wav");
   precache_sound ("weapons/lock4.wav");
   precache_sound ("weapons/pkup.wav");
   precache_sound ("items/armor1.wav");
   precache_sound ("weapons/lhit.wav");
   precache_sound ("weapons/lstart.wav");
   precache_sound ("items/damage3.wav");
   precache_sound ("misc/power.wav");
   precache_sound ("player/gib.wav");
   precache_sound ("player/udeath.wav");
   precache_sound ("player/tornoff2.wav");
   precache_sound ("player/pain1.wav");
   precache_sound ("player/pain2.wav");
   precache_sound ("player/pain3.wav");
   precache_sound ("player/pain4.wav");
   precache_sound ("player/pain5.wav");
   precache_sound ("player/pain6.wav");
   precache_sound ("player/death1.wav");
   precache_sound ("player/death2.wav");
   precache_sound ("player/death3.wav");
   precache_sound ("player/death4.wav");
   precache_sound ("player/death5.wav");
   precache_sound ("weapons/ax1.wav");
   precache_sound ("player/axhit1.wav");
   precache_sound ("player/axhit2.wav");
   precache_sound ("player/h2ojump.wav");
   precache_sound ("player/slimbrn2.wav");
   precache_sound ("player/inh2o.wav");
   precache_sound ("player/inlava.wav");
   precache_sound ("misc/outwater.wav");
   precache_sound ("player/lburn1.wav");
   precache_sound ("player/lburn2.wav");
   precache_sound ("misc/water1.wav");
   precache_sound ("misc/water2.wav");
   precache_model ("progs/player.mdl");
   precache_model ("progs/eyes.mdl");
   precache_model ("progs/h_player.mdl");
   precache_model ("progs/gib1.mdl");
   precache_model ("progs/gib2.mdl");
   precache_model ("progs/gib3.mdl");
   precache_model ("progs/s_bubble.spr");
   precache_model ("progs/s_explod.spr");
   precache_model ("progs/s_light.spr");
   precache_model ("progs/v_axe.mdl");
   precache_model ("progs/v_shot.mdl");
   precache_model ("progs/v_nail.mdl");
   precache_model ("progs/v_rock.mdl");
   precache_model ("progs/v_shot2.mdl");
   precache_model ("progs/v_nail2.mdl");
   precache_model ("progs/v_rock2.mdl");
   precache_model ("progs/bolt.mdl");
   precache_model ("progs/bolt2.mdl");
   precache_model ("progs/bolt3.mdl");
   precache_model ("progs/lavaball.mdl");
   precache_model ("progs/missile.mdl");
   precache_model ("progs/grenade.mdl");
   precache_model ("progs/spike.mdl");
   precache_model ("progs/s_spike.mdl");
   precache_model ("progs/backpack.mdl");
   precache_model ("progs/zom_gib.mdl");
   precache_model ("progs/v_light.mdl");
   setBotGravity ();
   lightstyle (FALSE,"m");
   lightstyle (TRUE,"mmnmmommommnonmmonqnmmo");
   lightstyle (FL_SWIM,"abcdefghijklmnopqrstuvwxyzyxwvutsrqponmlkjihgfedcba");
   lightstyle (MOVETYPE_WALK,"mmmmmaaaaammmmmaaaaaabcdefgabcdefg");
   lightstyle (MOVETYPE_STEP,"mamamamamama");
   lightstyle (MOVETYPE_FLY,"jklmnopqrstuvwxyzyxwvutsrqponmlkj");
   lightstyle (MOVETYPE_TOSS,"nmonqnmomnmomomno");
   lightstyle (MOVETYPE_PUSH,"mmmaaaabcdefgmmmmaaaammmaamm");
   lightstyle (FL_CLIENT,"mmmaaammmaaammmabcdefaaaammmmabcdefmmmaaaa");
   lightstyle (MOVETYPE_FLYMISSILE,"aaaaaaaazzzzzzzz");
   lightstyle (MOVETYPE_BOUNCE,"mmamammmmammamamaaamammma");
   lightstyle (MOVETYPE_BOUNCEMISSILE,"abcdefghijklmnopqrrqponmlkjihgfedcba");
   lightstyle (63.000,"a");
}; //end of the function worldspawn

void () StartFrame =
{
   local float dump_interval;

   teamplay = cvar ("teamplay");
   skill = cvar ("skill");
   framecount = (framecount + TRUE);
   if ((framecount == 1.000))
   {
      if ((skill < 3.000))
      {
         cvar_set ("skill","3");
         skill = 3.000;
      } //end if
   } //end if
   bot_skill_adapt = cvar ("bot_skill_adapt");

   // ===== PORTAL AWARENESS: Link Teleporters Once =====
   // Run this on frame 5 to ensure all entities are spawned
   if ((framecount == 5.000))
   {
      LinkTeleporters ();
      dprint ("Bots have linked teleporter networks.\n");

      // Load saved waypoints for this map (if available)
      local string map;
      map = mapname;
      bprint ("Checking for waypoints: mapname = '");
      bprint (map);
      bprint ("'\n");
      if ((map == "dm4"))
      {
         LoadMapWaypoints_dm4 ();
         bprint ("Loaded 452 waypoints for DM4\n");
         LoadPlayerLearnedRJ_dm4 ();  // Load learned RJ waypoints for DM4
      } //end if
      else if ((map == "dm2"))
      {
         LoadMapWaypoints_dm2 ();
         bprint ("Loaded 362 waypoints for DM2\n");
         // TEMPORARY: Disabled Phase 1 waypoints to allow Phase 2 live learning
         // LoadPlayerLearnedRJ_dm2 ();  // Load learned RJ waypoints for DM2
      } //end if
      else
      {
         bprint ("No waypoint file for map: ");
         bprint (map);
         bprint ("\n");
      } //end else
   } //end if
   // ===== END PORTAL AWARENESS =====

   // ===== AUTO WAYPOINT DUMP: Periodic Console Dump =====
   // Check console var "waypoint_dump_interval" (0=disabled, >0=seconds between dumps)
   // Example: "waypoint_dump_interval 60" = dump every 60 seconds
   dump_interval = cvar ("waypoint_dump_interval");
   if ((dump_interval > FALSE))
   {
      // Initialize timer on first check
      if ((WAYPOINT_DUMP_TIME == FALSE))
      {
         WAYPOINT_DUMP_TIME = (time + dump_interval);
         bprint ("Auto waypoint dump enabled: dumping every ");
         bprint (ftos (dump_interval));
         bprint (" seconds.\n");
         bprint ("Console logging recommended. Set 'con_logcenterprint 1' to capture output.\n");
      } //end if

      // Time to dump?
      if ((time >= WAYPOINT_DUMP_TIME))
      {
         bprint ("\n");
         bprint ("======================================\n");
         bprint ("AUTO WAYPOINT DUMP (");
         bprint (ftos (time));
         bprint ("s)\n");
         bprint ("======================================\n");
         DumpWaypoints ();
         bprint ("======================================\n");
         bprint ("END AUTO DUMP\n");
         bprint ("======================================\n");
         bprint ("\n");

         // Schedule next dump
         WAYPOINT_DUMP_TIME = (time + dump_interval);
      } //end if
   } //end if
   else
   {
      // Disabled: reset timer
      WAYPOINT_DUMP_TIME = FALSE;
   } //end if
   // ===== END AUTO WAYPOINT DUMP =====

   // ===== PHASE 1 FIX: TRAFFIC HEATMAP DECAY =====
   // Every 60 seconds, reduce traffic_score by 10% to prevent saturation
   // Without decay, all nodes eventually become "highways" and the heatmap loses meaning
   if ((time > (last_traffic_decay_time + 60.000)))
   {
      local entity node;

      node = find (world,classname,"BotPath");
      while (node)
      {
         if ((node.traffic_score > FALSE))
         {
            node.traffic_score = floor ((node.traffic_score * 0.900));
         } //end if
         node = find (node,classname,"BotPath");
      } //end while
      last_traffic_decay_time = time;
   } //end if
   // ===== END TRAFFIC HEATMAP DECAY =====
}; //end of the function StartFrame

void () bodyque =
{
}; //end of the function bodyque

void () InitBodyQue =
{
   local entity e;

   bodyque_head = spawn ();
   bodyque_head.classname = "bodyque";
   bodyque_head.owner = spawn ();
   bodyque_head.owner.classname = "bodyque";
   bodyque_head.owner.owner = spawn ();
   bodyque_head.owner.owner.classname = "bodyque";
   bodyque_head.owner.owner.owner = spawn ();
   bodyque_head.owner.owner.owner.classname = "bodyque";
   bodyque_head.owner.owner.owner.owner = bodyque_head;
}; //end of the function InitBodyQue

void (entity ent) CopyToBodyQue =
{
   bodyque_head.angles = ent.angles;
   bodyque_head.model = ent.model;
   bodyque_head.modelindex = ent.modelindex;
   bodyque_head.frame = ent.frame;
   bodyque_head.colormap = ent.colormap;
   bodyque_head.movetype = ent.movetype;
   bodyque_head.velocity = ent.velocity;
   bodyque_head.flags = FALSE;
   if (SKINSMODE)
   {
      bodyque_head.skin = ent.skin;
   } //end if
   setorigin (bodyque_head,ent.origin);
   setsize (bodyque_head,ent.mins,ent.maxs);
   bodyque_head = bodyque_head.owner;
   CamCopyBody (ent,bodyque_head);
}; //end of the function CopyToBodyQue
