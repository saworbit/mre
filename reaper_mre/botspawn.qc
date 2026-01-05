
void () AddAnotherBot;

void () initBotLevel =
{
   local float num;
   local float offset;
   local float i;
   local entity e;
   local string tmp;

   NOISEQUEUE = noisetarget ();
   num = ((serverflags & BOTS) / SECRET_YES_SHOOT);
   serverflags = ((serverflags - (serverflags & BOTS)) - INITLEVEL);
   NUMBOTS = CAM_IDLE;
   NUMPATHS = CAM_IDLE;
   NUMPATHERS = CAM_IDLE;
   offset = SPAWNFLAG_SUPERSPIKE;
   while ((num > CAM_IDLE))
   {
      num = (num - SPAWNFLAG_SUPERSPIKE);
      if (((NUMBOTS < MOVETYPE_FLY) && !(serverflags & DEDICATED)))
      {
         skill = ((0.100 * (parm10 & (offset * SVC_INTERMISSION))) / offset);
      } //end if
      offset = (offset * DOOR_TOGGLE);
      AddAnotherBot ();
   } //end while
   if ((serverflags & TEAMFLAG))
   {
      if (!teamplay)
      {
         serverflags = (serverflags - TEAMFLAG);
         serverflags = (serverflags - (serverflags & TEAMBOTS));
         return ;
      } //end if

   } //end if
   else
   {
      if (teamplay)
      {
         serverflags = (serverflags + TEAMFLAG);
         serverflags = (serverflags - (serverflags & TEAMBOTS));
         return ;
      } //end if
   } //end if
   if (!teamplay)
   {
      return ;
   } //end if
   num = ((serverflags & TEAMBOTS) / FL_ITEM);
   if ((num == CAM_IDLE))
   {
      return ;
   } //end if
   e = find (world,classname,"player");
   while (e)
   {
      i = CAM_IDLE;
      offset = SPAWNFLAG_SUPERSPIKE;
      while ((i < num))
      {
         i = (i + SPAWNFLAG_SUPERSPIKE);
         if (((i < MOVETYPE_TOSS) && !(serverflags & DEDICATED)))
         {
            skill = ((0.100 * (parm11 & (offset * SVC_FINALE))) / offset);
         } //end if
         offset = (offset * DOOR_TOGGLE);
         addTeamBots (e,SPAWNFLAG_SUPERSPIKE);
      } //end while
      e = find (e,classname,"player");
   } //end while
   if ((serverflags & DEDICATED))
   {
      serverflags = (serverflags - DEDICATED);
   } //end if
}; //end of the function initBotLevel

void () setBotGravity =
{
   local float newmax;
   local float vel;
   local float sk;
   local string tmp;
   local float rawgrav;
   local float guard;

   // PHASE 1 FIX: Dynamic Physics Initialization
   // Read server gravity instead of hardcoding 800
   rawgrav = cvar ("sv_gravity");
   if ((rawgrav <= CAM_IDLE))
   {
      rawgrav = 800.000; // Safety fallback for unset servers
   } //end if
   GRAVITY = (rawgrav * 0.100);
   dprint ("sv_gravity raw is ");
   tmp = ftos (rawgrav);
   dprint (tmp);
   dprint ("\n");
   if ((GRAVITY <= CAM_IDLE))
   {
      dprint ("Gravity accel clamped to 80\n");
      GRAVITY = 80.000;
   } //end if
   dprint ("Gravity accel is ");
   tmp = ftos (GRAVITY);
   dprint (tmp);
   dprint ("\n");

   // Initialize standard Quake run speed
   BOTSPEED = 320.000;

   // Reset global timers to prevent stale state from previous maps
   WAYPOINT_DUMP_TIME = CAM_IDLE;
   ASTAR_SEARCH_ID = CAM_IDLE;
   newmax = CAM_IDLE;
   vel = 270.000;
   MAXJUMP = CONTENT_EMPTY;
   // Guard loop iterations so bad gravity or const globals can't trigger a runaway loop.
   guard = CAM_IDLE;
   while ((newmax > MAXJUMP))
   {
      vel = (vel - GRAVITY);
      MAXJUMP = newmax;
      newmax = (newmax + (vel * 0.100));
      guard = (guard + SPAWNFLAG_SUPERSPIKE);
      if ((guard > 1000.000))
      {
         dprint ("setBotGravity: MAXJUMP loop bailout\n");
         newmax = MAXJUMP;
      } //end if
   } //end while
   // Loop diagnostics help confirm gravity math during startup.
   dprint ("Max jump loop iters is ");
   tmp = ftos (guard);
   dprint (tmp);
   dprint ("\n");
   MAXJUMP = (MAXJUMP - SPAWNFLAG_SUPERSPIKE);
   dprint ("Max jump height is ");
   tmp = ftos (MAXJUMP);
   dprint (tmp);
   dprint ("\n");
   LEVELJUMPTIME = CAM_IDLE;
   vel = 270.000;
   newmax = CAM_IDLE;
   // Track iteration count to expose bad math before it becomes a crash.
   guard = CAM_IDLE;
   while ((newmax > CONTENT_EMPTY))
   {
      LEVELJUMPTIME = (LEVELJUMPTIME + 0.100);
      vel = (vel - GRAVITY);
      newmax = (newmax + (vel * 0.100));
      guard = (guard + SPAWNFLAG_SUPERSPIKE);
      if ((guard > 1000.000))
      {
         dprint ("setBotGravity: LEVELJUMPTIME loop bailout\n");
         newmax = CONTENT_EMPTY;
      } //end if
   } //end while
   // Emit loop counts for quick log inspection during QA.
   dprint ("Level jump loop iters is ");
   tmp = ftos (guard);
   dprint (tmp);
   dprint ("\n");
   LEVELJUMPTIME = (LEVELJUMPTIME - (newmax / vel));
   dprint ("Level jump time is ");
   tmp = ftos (LEVELJUMPTIME);
   dprint (tmp);
   dprint ("\n");
   newmax = CAM_IDLE;
   vel = 200.000;
   GRENADEMAXHEIGHT = CONTENT_EMPTY;
   // Final guard to keep grenade math from hanging the server.
   guard = CAM_IDLE;
   while ((newmax > GRENADEMAXHEIGHT))
   {
      vel = (vel - GRAVITY);
      GRENADEMAXHEIGHT = newmax;
      newmax = (newmax + (vel * 0.100));
      guard = (guard + SPAWNFLAG_SUPERSPIKE);
      if ((guard > 1000.000))
      {
         dprint ("setBotGravity: GRENADEMAXHEIGHT loop bailout\n");
         newmax = GRENADEMAXHEIGHT;
      } //end if
   } //end while
   // Log grenade loop iterations for easier debugging.
   dprint ("Grenade max loop iters is ");
   tmp = ftos (guard);
   dprint (tmp);
   dprint ("\n");
   dprint ("Max grenade height is ");
   tmp = ftos (GRENADEMAXHEIGHT);
   dprint (tmp);
   dprint ("\n");
   INVGRENADELEVELDIST = (((0.100 * SPAWNFLAG_LASER) * (200.000 - GRAVITY)) / GRAVITY);
   INVGRENADELEVELDIST = (SPAWNFLAG_SUPERSPIKE / (INVGRENADELEVELDIST * SEARCH_RADIUS));
   dprint ("inverse grenade level distance is ");
   tmp = ftos (INVGRENADELEVELDIST);
   dprint (tmp);
   dprint ("\n");
   BOTSPEED = (cvar ("sv_maxspeed") / TE_LAVASPLASH);
}; //end of the function setBotGravity

void () PutBotInServer;
float () numplayers;
float (entity e) totalscore;

void () respawnBot =
{
   local string m;
   local float n;
   local float o;
   local entity e;

   CopyToBodyQue (self);
   if (!teamplay)
   {
      if ((serverflags & TEAMBOTS))
      {
         n = (NUMBOTS + numplayers ());
         o = ((serverflags & TEAMBOTS) / FL_ITEM);
         if (((o < n) || (self.team != 99.000)))
         {
            self.nextthink = (time + SPAWNFLAG_SUPERSPIKE);
            if ((self.team == 99.000))
            {
               NUMBOTS = (NUMBOTS - SPAWNFLAG_SUPERSPIKE);
            } //end if
            remove (self.movetarget);
            remove (self.goalentity);
            self.think = SUB_Remove;
            if (self.pather)
            {
               NUMPATHERS = (NUMPATHERS - SPAWNFLAG_SUPERSPIKE);
            } //end if
            if ((self.team != 99.000))
            {
               m = ": I'm going to find a team server.\n";

            } //end if
            else
            {
               if ((totalscore (self) < CAM_IDLE))
               {
                  m = ": I'm tired of getting fucked.  I'm off\n";

               } //end if
               else
               {
                  if ((totalscore (self) > MUST_HAVE))
                  {
                     m = ": I'm going to find some real bots\n";

                  } //end if
                  else
                  {
                     m = ": This server's too anal.  I'm off\n";
                  } //end if
               } //end if
            } //end if
            bprint (self.teamname);
            bprint (self.netname);
            bprint (m);
            bprint (self.teamname);
            bprint (self.netname);
            bprint (" pussed out with ");
            m = ftos (self.frags);
            bprint (m);
            bprint (" frags\n");
            return ;
         } //end if
      } //end if

   } //end if
   else
   {
      if ((self.team != 99.000))
      {
         e = find (world,classname,"player");
         while (e)
         {
            if ((e.team == self.team))
            {
               PutBotInServer ();
               return ;
            } //end if
            e = find (e,classname,"player");
         } //end while
         bprint (self.teamname);
         bprint (self.netname);
         bprint (": Going off to join the girl scouts\n");
         bprint (self.teamname);
         bprint (self.netname);
         bprint (" wimped out with ");
         m = ftos (self.frags);
         bprint (m);
         bprint (" frags\n");
         return ;

      } //end if
      else
      {
         if ((SKINSMODE == SPAWNFLAG_LASER))
         {
            skinChange (self,15.000);
         } //end if
      } //end if
   } //end if
   PutBotInServer ();
}; //end of the function respawnBot

void () bot_pain;

void () BotDie;

void () bot_stand1;

void () bot_walk;

void () bot_run;

void () bot_start;

void () dmbot_melee;
entity () botmovetarget;

void () PutBotInServer =
{
   local entity spwn;
   local vector spot;
   local string tmp;
   local float aimvar;
   local entity item;
   local float cache_len;

   self.classname = "dmbot";
   self.health = MUST_HAVE;
   self.takedamage = DAMAGE_AIM;
   self.solid = SOLID_SLIDEBOX;
   self.movetype = MOVETYPE_STEP;
   self.show_hostile = FALSE;
   self.max_health = MUST_HAVE;
   self.air_finished = (time + SVC_INTERMISSION);
   self.dmg = SPAWNFLAG_SUPERSPIKE;
   self.super_damage_finished = FALSE;
   self.radsuit_finished = FALSE;
   self.invisible_finished = FALSE;
   self.invincible_finished = FALSE;
   self.effects = FALSE;
   self.invincible_time = CAM_IDLE;
   self.yaw_speed = (45.000 + (25.000 * self.skil));
   self.lefty = STRAFE_DIR;
   if ((self.goalentity == world))
   {
      self.goalentity = botmovetarget ();
   } //end if
   self.goalentity.goalentity = world;
   SetNewParms ();
   DecodeLevelParms ();
   W_SetCurrentAmmo ();
   self.search_time = time;
   self.attack_finished = time;
   self.th_pain = bot_pain;
   self.th_die = BotDie;
   self.th_stand = bot_stand1;
   self.th_walk = bot_walk;
   self.th_run = bot_run;
   self.th_melee = dmbot_melee;
   self.th_cache = cacheenemy;
   self.touch = fuck_thud;
   self.think = bot_start;
   self.nextthink = (time + 0.100);
   self.enemy = world;
   self.pathtype = NEVERTARGET;
   self.deadflag = DEAD_NO;
   self.pausetime = CAM_IDLE;
   spwn = SelectSpawnPoint ();
   spot = (spwn.origin + '0.000 0.000 1.000');
   self.origin = spot;
   setorigin (self,spot);
   self.angles = spwn.angles;
   self.fixangle = SPAWNFLAG_SUPERSPIKE;
   setmodel (self,"progs/eyes.mdl");
   modelindex_eyes = self.modelindex;
   setmodel (self,"progs/player.mdl");
   modelindex_player = self.modelindex;
   setsize (self,VEC_HULL_MIN,VEC_HULL_MAX);
   if ((self.movetarget == world))
   {
      NewCarriedPath ();

   } //end if
   else
   {
      setorigin (self.movetarget,self.origin);
   } //end if
   self.movetarget.movetarget = world;
   clearCache (self);
   // Skill-based memory: high-skill bots start with map knowledge at spawn.
   self.has_memory = CAM_IDLE;
   if ((self.skil > 2.000))
   {
      self.has_memory = SPAWNFLAG_SUPERSPIKE;
   } //end if
   if (self.has_memory)
   {
      // Pre-cache high-impact powerups with a short path length to simulate recall.
      cache_len = 100.000;
      item = find (world,classname,"item_artifact_super_damage");
      while (item)
      {
         cacheRoute (self.movetarget,item,cache_len,item);
         item = find (item,classname,"item_artifact_super_damage");
      } //end while
      item = find (world,classname,"item_artifact_invulnerability");
      while (item)
      {
         cacheRoute (self.movetarget,item,cache_len,item);
         item = find (item,classname,"item_artifact_invulnerability");
      } //end while
      item = find (world,classname,"item_artifact_invisibility");
      while (item)
      {
         cacheRoute (self.movetarget,item,cache_len,item);
         item = find (item,classname,"item_artifact_invisibility");
      } //end while
      // Pre-cache key weapons so veteran bots route toward early fight control.
      item = find (world,classname,"weapon_rocketlauncher");
      while (item)
      {
         cacheRoute (self.movetarget,item,cache_len,item);
         item = find (item,classname,"weapon_rocketlauncher");
      } //end while
      item = find (world,classname,"weapon_lightning");
      while (item)
      {
         cacheRoute (self.movetarget,item,cache_len,item);
         item = find (item,classname,"weapon_lightning");
      } //end while
      item = find (world,classname,"weapon_supernailgun");
      while (item)
      {
         cacheRoute (self.movetarget,item,cache_len,item);
         item = find (item,classname,"weapon_supernailgun");
      } //end while
   } //end if
   // Memory bots bias their first goal toward cached rocket control.
   if (self.has_memory)
   {
      if (self.movetarget)
      {
         if (self.movetarget.rocketcache)
         {
            setorigin (self.goalentity,self.movetarget.rocketcache.origin);
            self.search_time = (self.search_time + 5.000);
         } //end if
      } //end if
   } //end if
   if (self.pather)
   {
      NUMPATHERS = (NUMPATHERS - SPAWNFLAG_SUPERSPIKE);
      self.pather = CAM_IDLE;
   } //end if
   if ((NUMPATHERS < MAXPATHERS))
   {
      self.pather = SPAWNFLAG_SUPERSPIKE;
      NUMPATHERS = (NUMPATHERS + SPAWNFLAG_SUPERSPIKE);
   } //end if
   self.view_ofs = '0.000 0.000 22.000';

   // ===== CHAT HOOK: PERSONALITY ASSIGNMENT =====
   // Assign personality type to bot on spawn
   if ((self.personality == FALSE))
   {
      local float r;

      r = random ();

      // Specific personalities for known names
      if ((self.netname == "Reaper"))
      {
         self.personality = PERS_PRO;
      }
      else
      {
         if ((self.netname == "Sloth"))
         {
            self.personality = PERS_CAMPER;
         }
         else
         {
            if ((self.netname == "Hater"))
            {
               self.personality = PERS_RAGER;
            }
            else
            {
               // Random distribution for other bots
               if ((r < 0.200))
               {
                  self.personality = PERS_RAGER;
               }
               else
               {
                  if ((r < 0.400))
                  {
                     self.personality = PERS_PRO;
                  }
                  else
                  {
                     if ((r < 0.600))
                     {
                        self.personality = PERS_NOOB;
                     }
                     else
                     {
                        if ((r < 0.800))
                        {
                           self.personality = PERS_MEMELORD;
                        }
                        else
                        {
                           self.personality = PERS_NONE; // Standard/Camper behavior
                        } //end if
                     } //end if
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
   } //end if

   // Set initial chat cooldown (2-5 seconds after spawn before first chat)
   self.chat_cooldown = (time + (2.000 + (random () * 3.000)));
   // =============================================

   makevectors (self.angles);
   spawn_tfog ((self.origin + (v_forward * LOOPTIME)));
   spawn_tdeath (self.origin,self);
   if ((BOTSPEED < SECRET_YES_SHOOT))
   {
      dprint ("Feeling kind of gay today (SV_MAXSPEED = ");
      tmp = ftos ((BOTSPEED * TE_LAVASPLASH));
      dprint (tmp);
      dprint ("\n");
   } //end if
   aimvar = cvar ("sv_aim");
   if ((aimvar != SPAWNFLAG_SUPERSPIKE))
   {
      dprint ("Seems like a nice day to die\n");
   } //end if
   msgUpdateNameToAll (self.fClientNo,self.netname);
   msgUpdateColorsToAll (self.fClientNo,self.fShirt,self.fPants);
   msgUpdateFragsToAll (self.fClientNo,self.frags);
}; //end of the function PutBotInServer

void () SpawnNewBot =
{
   local string tmp;

   PutBotInServer ();
   bprint (self.netname);
   tmp = ftos (self.skil);
   bprint (" (iq ");
   bprint (tmp);
   bprint (") is reformed Thanks Chris.\n");
}; //end of the function SpawnNewBot
entity () AddBot =
{
   local entity newbot;
   local entity oldself;
   local string mycolor;
   local float plycolor;
   local float ran_skill;

   newbot = spawn ();
   oldself = self;
   self = newbot;
   self.think = SpawnNewBot;
   self.nextthink = (time + (12.000 * random ()));
   // ===== BUGFIX: Skill Assignment Logic (2026-01-06) =====
   // Previous logic had impossible conditions (e.g., x > 0.5 AND x <= 0.2)
   // Result: ALL bots spawned with skill=1, breaking Juggler/RJ/advanced features
   ran_skill = crandom ();
   // Convert crandom() range (-1.0 to 1.0) to normalized range (0.0 to 1.0)
   ran_skill = ((ran_skill + 1.000) * 0.500);

   // Skill distribution with CORRECT conditional logic:
   // 50% skill 1.0 (novice), 20% skill 1.5, 20% skill 2.0, 5% skill 2.5, 5% skill 3.0
   if ((ran_skill <= 0.500))
   {
      self.skil = 1.000;  // 50% - Novice
   } //end if
   else
   {
      if ((ran_skill <= 0.700))
      {
         self.skil = 1.500;  // 20% - Below average (0.5-0.7)
      } //end if
      else
      {
         if ((ran_skill <= 0.900))
         {
            self.skil = 2.000;  // 20% - Average (0.7-0.9) - JUGGLER UNLOCKED!
         } //end if
         else
         {
            if ((ran_skill <= 0.950))
            {
               self.skil = 2.500;  // 5% - Above average (0.9-0.95)
            } //end if
            else
            {
               self.skil = 3.000;  // 5% - Expert (0.95-1.0)
            } //end if
         } //end if
      } //end if
   } //end else
   // ===== END BUGFIX =====
   initscore ();
   self = oldself;
   return (newbot);
}; //end of the function AddBot
float () numplayers =
{
   local entity e;
   local float n;

   n = CAM_IDLE;
   e = find (world,classname,"player");
   while (e)
   {
      n = (n + SPAWNFLAG_SUPERSPIKE);
      e = find (e,classname,"player");
   } //end while
   return (n);
}; //end of the function numplayers

void () AddAnotherBot =
{
   local entity newbot;
   local entity tmp;
   local float n;
   local string st;
   local float cno;

   cno = clientNextAvailable ();
   if ((cno == CONTENT_EMPTY))
   {
      bprint ("Unable to spawn bot.  Server is full.\n");
      return ;
   } //end if
   clientSetUsed (cno);
   self.impulse = CAM_IDLE;
   if (!teamplay)
   {
      if ((serverflags & TEAMBOTS))
      {
         n = (NUMBOTS + numplayers ());
         if (((serverflags & TEAMBOTS) < n))
         {
            dprint ("Can't add bot - exceeds bound\n");
            return ;
         } //end if
      } //end if
   } //end if
   newbot = AddBot ();
   newbot.colormap = CAM_IDLE;
   newbot.fClientNo = cno;
   if (!teamplay)
   {
      newbot.colormap = (cno + SPAWNFLAG_SUPERSPIKE);
      newbot.fShirt = floor ((random () * MSG_UPDATENAME));
      newbot.fPants = floor ((random () * MSG_UPDATENAME));
   } //end if
   if (teamplay)
   {
      newbot.colormap = (cno + SPAWNFLAG_SUPERSPIKE);
      newbot.fShirt = SPAWNFLAG_LASER;
      newbot.fPants = SPAWNFLAG_LASER;

   } //end if
   else
   {
      if ((SKINSMODE == SPAWNFLAG_SUPERSPIKE))
      {
         skinChange (newbot,NUMBOTS);

      } //end if
      else
      {
         if ((SKINSMODE == SPAWNFLAG_LASER))
         {
            st = ftos (((newbot.skil & CAM_FOLLOW) + SPAWNFLAG_SUPERSPIKE));
            dprint (st);
            dprint ("= skil skin\n");
            skinChange (newbot,((newbot.skil & CAM_FOLLOW) + SPAWNFLAG_SUPERSPIKE));
         } //end if
      } //end if
   } //end if
   newbot.team = 99.000;
   if (NAMEBOTS)
   {
      newbot.teamname = self.netname;

   } //end if
   else
   {
      if ((newbot.skil < SPAWNFLAG_SUPERSPIKE))
      {
         newbot.teamname = "";

      } //end if
      else
      {
         if ((newbot.skil < SPAWNFLAG_LASER))
         {
            newbot.teamname = "";

         } //end if
         else
         {
            if ((newbot.skil < CAM_FOLLOW))
            {
               newbot.teamname = "";

            } //end if
            else
            {
               newbot.teamname = "";
            } //end if
         } //end if
      } //end if
   } //end if
   NUMBOTS = (NUMBOTS + SPAWNFLAG_SUPERSPIKE);
   if ((NUMBOTS == SPAWNFLAG_SUPERSPIKE))
   {
      newbot.nextthink = (time + 0.100);
   } //end if
   if ((NUMBOTS < SECRET_YES_SHOOT))
   {
      serverflags = ((serverflags - (serverflags & BOTS)) + (SECRET_YES_SHOOT * NUMBOTS));
   } //end if
   if ((NUMBOTS == SPAWNFLAG_SUPERSPIKE))
   {
      newbot.netname = "Cheater";

   } //end if
   else
   {
      if ((NUMBOTS == SPAWNFLAG_LASER))
      {
         newbot.netname = "Assmunch";

      } //end if
      else
      {
         if ((NUMBOTS == CAM_FOLLOW))
         {
            newbot.netname = "Wanton";

         } //end if
         else
         {
            if ((NUMBOTS == SECRET_1ST_DOWN))
            {
               newbot.netname = "Drooly";

            } //end if
            else
            {
               if ((NUMBOTS == CAM_FREE))
               {
                  newbot.netname = "Rapier";

               } //end if
               else
               {
                  if ((NUMBOTS == CAM_NOCLIP))
                  {
                     newbot.netname = "Derang";

                  } //end if
                  else
                  {
                     if ((NUMBOTS == CAM_DEATH))
                     {
                        newbot.netname = "Hater";

                     } //end if
                     else
                     {
                        if ((NUMBOTS == SECRET_NO_SHOOT))
                        {
                           newbot.netname = "Angry";

                        } //end if
                        else
                        {
                           if ((NUMBOTS == TE_LIGHTNING3))
                           {
                              newbot.netname = "Lust";

                           } //end if
                           else
                           {
                              if ((NUMBOTS == TE_LAVASPLASH))
                              {
                                 newbot.netname = "Slut";

                              } //end if
                              else
                              {
                                 if ((NUMBOTS == TE_TELEPORT))
                                 {
                                    newbot.netname = "Pride";

                                 } //end if
                                 else
                                 {
                                    if ((NUMBOTS == 12.000))
                                    {
                                       newbot.netname = "Malice";

                                    } //end if
                                    else
                                    {
                                       if ((NUMBOTS == MSG_UPDATENAME))
                                       {
                                          newbot.netname = "Envy";

                                       } //end if
                                       else
                                       {
                                          if ((NUMBOTS == MSG_UPDATEFRAGS))
                                          {
                                             newbot.netname = "Sloth";

                                          } //end if
                                          else
                                          {
                                             if ((NUMBOTS == 15.000))
                                             {
                                                newbot.netname = "Onerus";
                                             } //end if
                                          } //end if
                                       } //end if
                                    } //end if
                                 } //end if
                              } //end if
                           } //end if
                        } //end if
                     } //end if
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
   } //end if
}; //end of the function AddAnotherBot

void (entity ply, float n) addTeamBots =
{
   local entity newbot;
   local entity tmp;
   local float i;
   local float cno;

   i = n;
   while ((i > CAM_IDLE))
   {
      cno = clientNextAvailable ();
      if ((cno == CONTENT_EMPTY))
      {
         bprint ("Unable to spawn bot.  Server is full.\n");
         return ;
      } //end if
      clientSetUsed (cno);
   } //end while
   newbot = AddBot ();
   newbot.colormap = ply.colormap;
   newbot.team = ply.team;
   newbot.teamname = ply.netname;
   newbot.fClientNo = cno;
   newbot.fShirt = (newbot.team - SPAWNFLAG_SUPERSPIKE);
   newbot.fPants = (newbot.team - SPAWNFLAG_SUPERSPIKE);
   msgUpdateNameToAll (newbot.fClientNo,newbot.netname);
   msgUpdateColorsToAll (newbot.fClientNo,newbot.fShirt,newbot.fPants);
   msgUpdateFragsToAll (newbot.fClientNo,newbot.frags);
   i = (i - SPAWNFLAG_SUPERSPIKE);
}; //end of the function addTeamBots

void (entity ply, float n) removeTeamBots =
{
   local float i;
   local entity e;

   i = n;
   e = find (world,classname,"dmbot");
   while ((i > CAM_IDLE))
   {
      while (((e != world) && (e.team != ply.team)))
      {
         e = find (e,classname,"dmbot");
      } //end while
      if (!e)
      {
         return ;
      } //end if
      if (e.pather)
      {
         NUMPATHERS = (NUMPATHERS - SPAWNFLAG_SUPERSPIKE);
      } //end if
      remove (e.movetarget);
      remove (e.goalentity);
      remove (e);
      i = (i - SPAWNFLAG_SUPERSPIKE);
   } //end while
}; //end of the function removeTeamBots

void () removeAllBots =
{
   local entity e;

   e = find (world,classname,"dmbot");
   while (e)
   {
      if (!e)
      {
         return ;
      } //end if
      if (e.pather)
      {
         NUMPATHERS = (NUMPATHERS - SPAWNFLAG_SUPERSPIKE);
      } //end if
      remove (e.movetarget);
      remove (e.goalentity);
      remove (e);
      e = find (e,classname,"dmbot");
   } //end while
   NUMBOTS = CAM_IDLE;
   dprint ("All bots removed.\n");
}; //end of the function removeAllBots

void (float n) SetMaxBots =
{
   local float t;
   local string tmp;

   self.impulse = CAM_IDLE;
   if ((serverflags & TEAMFLAG))
   {
      dprint ("Entering bounded deathmatch mode\n");
      serverflags = ((serverflags - TEAMFLAG) - (serverflags & TEAMBOTS));
   } //end if
   dprint ("Max bots + players set to ");
   tmp = ftos (n);
   dprint (tmp);
   dprint ("\n");
   serverflags = ((serverflags - (serverflags & TEAMBOTS)) + (n * FL_ITEM));
   t = numplayers ();
   while (((NUMBOTS + t) < n))
   {
      AddAnotherBot ();
   } //end while
}; //end of the function SetMaxBots

void (float n) SetTeamBots =
{
   local float t;
   local entity e;
   local string tmp;

   self.impulse = CAM_IDLE;
   if (!(serverflags & TEAMFLAG))
   {
      dprint ("Entering bot team mode\n");
      serverflags = ((serverflags + TEAMFLAG) - (serverflags & TEAMBOTS));
   } //end if
   dprint ("Bots per player team set to ");
   tmp = ftos (n);
   dprint (tmp);
   dprint ("\n");
   t = ((serverflags & TEAMBOTS) / FL_ITEM);
   serverflags = ((serverflags - (serverflags & TEAMBOTS)) + (n * FL_ITEM));
   if ((t < n))
   {
      e = find (world,classname,"player");
      t = (n - t);
      while (e)
      {
         addTeamBots (e,t);
         e = find (e,classname,"player");
      } //end while
      return ;
   } //end if
   if ((t > n))
   {
      e = find (world,classname,"player");
      while (e)
      {
         t = (t - n);
         removeTeamBots (e,t);
         e = find (e,classname,"player");
      } //end while
      return ;
   } //end if
}; //end of the function SetTeamBots

void () UpdateTeamColors =
{
   local entity e;

   e = find (world,classname,"dmbot");
   while (e)
   {
      if ((e.colormap == self.colormap))
      {
         e.team = self.team;
      } //end if
      e = find (e,classname,"dmbot");
   } //end while
}; //end of the function UpdateTeamColors
