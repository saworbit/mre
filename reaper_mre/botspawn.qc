
void () AddAnotherBot;

// Helper function to find bots (since they now use classname "player")
// Returns next bot entity after 'start', or world if none found
entity (entity start) findbot =
{
   local entity e;

   e = find (start,classname,"player");
   while (e)
   {
      if (e.isbot)
      {
         return (e);
      } //end if
      e = find (e,classname,"player");
   } //end while
   return (world);
}; //end of the function findbot

void () initBotLevel =
{
   local float num;
   local float offset;
   local float i;
   local entity e;
   local string tmp;

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

   self.classname = "player";  // Use "player" so engine applies colors correctly
   self.isbot = TRUE;  // Mark as bot (distinguishes from real players)
   self.flags = (self.flags | FL_CLIENT);
   self.colormap = (self.fClientNo + SPAWNFLAG_SUPERSPIKE);
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
   if (((!self.goalentity) || (self.goalentity == world) || (self.goalentity.classname != "BotTarget")))
   {
      if ((self.goalentity && (self.goalentity != world) && (self.goalentity.classname != "BotTarget")))
      {
         remove (self.goalentity);
      } //end if
      self.goalentity = botmovetarget ();
      self.goalentity.goalentity = world;
   } //end if
   Bot_RequestGoal (self,100.000,0.000,world,self.origin,R_SPAWN_IDLE,"spawn idle");
   SetNewParms ();
   DecodeLevelParms ();
   W_SetCurrentAmmo ();
   self.nav_search_time = time;
   self.combat_search_time = (time - TRUE);
   self.noise_target = world;
   self.noise_expires = time;
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
   // Initialize spawn aim via PID so only the aim controller writes angles.
   self.ideal_yaw = spwn.angles_y;
   self.ideal_pitch = spwn.angles_x;
   self.aim_hold_yaw = self.ideal_yaw;
   self.aim_hold_pitch = self.ideal_pitch;
   self.aim_hold_set_yaw = TRUE;
   self.aim_hold_set_pitch = TRUE;
   self.pid_last_update = 0.000;
   Bot_UpdateAimPID ();
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
   if ((self.goalentity && (self.goalentity.classname == "BotTarget")))
   {
      setorigin (self.goalentity,self.origin);
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
            self.nav_search_time = (self.nav_search_time + 5.000);
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
   if (((self.personality == FALSE) && (self.netname == "")))
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

void () Bot_EntryLine =
{
   local string msg;

   msg = "joins the fight.";
   if ((self.netname == "Reaper"))
   {
      msg = "Fear the reaper.";
   } //end if
   else if ((self.netname == "Omicron"))
   {
      msg = "AAS online.";
   } //end if
   else if ((self.netname == "Toxic"))
   {
      msg = "gg ez";
   } //end if
   else if ((self.netname == "Karen"))
   {
      msg = "I want to speak to the owner.";
   } //end if
   else if ((self.netname == "Bozo"))
   {
      msg = "Honk honk!";
   } //end if
   else if ((self.netname == "Camper"))
   {
      msg = "I'll be waiting.";
   } //end if
   else if ((self.netname == "Terminator"))
   {
      msg = "Terminated.";
   } //end if
   else if ((self.netname == "Rusty"))
   {
      msg = "Still warming up.";
   } //end if
   else if ((self.netname == "Thresh"))
   {
      msg = "No mercy.";
   } //end if
   else if ((self.netname == "Romero"))
   {
      msg = "Got any shrooms?";
   } //end if
   else if ((self.netname == "Carmack"))
   {
      msg = "Fixed in the next build.";
   } //end if
   else if ((self.netname == "American"))
   {
      msg = "America!";
   } //end if
   else if ((self.netname == "Drooly"))
   {
      msg = "Where am I?";
   } //end if
   else if ((self.netname == "Derang"))
   {
      msg = "You're all doomed.";
   } //end if
   else if ((self.netname == "Wanton"))
   {
      msg = "Bring it on.";
   } //end if
   else if ((self.netname == "Chatter"))
   {
      msg = "Let's talk.";
   } //end if
   else if ((self.netname == "Frik"))
   {
      msg = "Generating waypoints...";
   } //end if
   else if ((self.netname == "MrElusive"))
   {
      msg = "Calculating paths.";
   } //end if
   else if ((self.netname == "Gladiator"))
   {
      msg = "Railgun ready.";
   } //end if
   else if ((self.netname == "Eraser"))
   {
      msg = "Learning routes.";
   } //end if
   else if ((self.netname == "Zeus"))
   {
      msg = "Bow before me.";
   } //end if
   else if ((self.netname == "Oak"))
   {
      msg = "Take cover.";
   } //end if
   else if ((self.netname == "Frog"))
   {
      msg = "Ribbit.";
   } //end if
   else if ((self.netname == "Cthon"))
   {
      msg = "From the depths.";
   } //end if
   else if ((self.netname == "Eliminator"))
   {
      msg = "Target acquired.";
   } //end if
   else if ((self.netname == "TheTutor"))
   {
      msg = "Class is in session.";
   } //end if
   else if ((self.netname == "Jumbot"))
   {
      msg = "Calculating nodes...";
   } //end if
   else if ((self.netname == "Ace"))
   {
      msg = "Ace is the place.";
   } //end if
   else if ((self.netname == "DoomGuy"))
   {
      msg = "Rip and tear.";
   } //end if
   else if ((self.netname == "Ranger"))
   {
      msg = "Ranger reporting.";
   } //end if
   else if ((self.netname == "Bitterman"))
   {
      msg = "Still alive.";
   } //end if
   else if ((self.netname == "TankJr"))
   {
      msg = "Heavy armor online.";
   } //end if
   else if ((self.netname == "Crash"))
   {
      msg = "Let's crash the party.";
   } //end if
   else if ((self.netname == "Phobos"))
   {
      msg = "Fear me.";
   } //end if
   else if ((self.netname == "Slash"))
   {
      msg = "Let's slash.";
   } //end if
   else if ((self.netname == "Anarki"))
   {
      msg = "Adrenaline injected.";
   } //end if

   bprint (self.netname);
   bprint (": ");
   bprint (msg);
   bprint ("\n");
}; //end of the function Bot_EntryLine

void () SpawnNewBot =
{
   PutBotInServer ();
   Bot_EntryLine ();
}; //end of the function SpawnNewBot
entity () AddBot =
{
   local entity newbot;
   local entity oldself;
   local string mycolor;
   local float plycolor;

   newbot = spawn ();
   oldself = self;
   self = newbot;
   self.think = SpawnNewBot;
   self.nextthink = (time + (12.000 * random ()));
   // Default bots to nightmare skill (toughest) at spawn.
   self.skil = 3.000;
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

// =========================================================
// BOT CHARACTER PROFILES - THE ULTIMATE COLLECTION
// =========================================================
void (entity bot, float index) Bot_AssignIdentity =
{
   local float WHITE;
   local float BROWN;
   local float BLUE;
   local float GREEN;
   local float RED;
   local float GOLD;
   local float PURPLE;
   local float GREY;
   local float YELLOW;
   local float id;

   WHITE = 0.000;
   BROWN = 1.000;
   BLUE = 2.000;
   GREEN = 3.000;
   RED = 4.000;
   GOLD = 7.000;
   PURPLE = 8.000;
   GREY = 11.000;
   YELLOW = 12.000;

   id = index - (floor (index / 36.000) * 36.000);
   if ((id == 0.000))
   {
      id = 36.000;
   } //end if

   bot.personality = PERS_PRO;
   bot.skil = 3.000;

   if ((id == 1.000))
   {
      bot.netname = "Reaper";
      bot.fShirt = RED;
      bot.fPants = 0.000;
      bot.personality = PERS_PRO;
   } //end if
   else
   {
      if ((id == 2.000))
      {
         bot.netname = "Omicron";
         bot.fShirt = BLUE;
         bot.fPants = YELLOW;
         bot.personality = PERS_PRO;
      } //end if
      else
      {
         if ((id == 3.000))
         {
            bot.netname = "Toxic";
            bot.fShirt = GREEN;
            bot.fPants = PURPLE;
            bot.personality = PERS_RAGER;
         } //end if
         else
         {
            if ((id == 4.000))
            {
               bot.netname = "Karen";
               bot.fShirt = PURPLE;
               bot.fPants = WHITE;
               bot.personality = PERS_RAGER;
            } //end if
            else
            {
               if ((id == 5.000))
               {
                  bot.netname = "Bozo";
                  bot.fShirt = RED;
                  bot.fPants = YELLOW;
                  bot.personality = PERS_MEMELORD;
                  bot.skil = 1.000;
               } //end if
               else
               {
                  if ((id == 6.000))
                  {
                     bot.netname = "Camper";
                     bot.fShirt = GREEN;
                     bot.fPants = BROWN;
                     bot.personality = PERS_CAMPER;
                  } //end if
                  else
                  {
                     if ((id == 7.000))
                     {
                        bot.netname = "Terminator";
                        bot.fShirt = GREY;
                        bot.fPants = GREY;
                        bot.personality = PERS_PRO;
                     } //end if
                     else
                     {
                        if ((id == 8.000))
                        {
                           bot.netname = "Rusty";
                           bot.fShirt = BROWN;
                           bot.fPants = BROWN;
                           bot.personality = PERS_NOOB;
                           bot.skil = 0.000;
                        } //end if
                        else
                        {
                           if ((id == 9.000))
                           {
                              bot.netname = "Thresh";
                              bot.fShirt = RED;
                              bot.fPants = BLUE;
                              bot.personality = PERS_PRO;
                           } //end if
                           else
                           {
                              if ((id == 10.000))
                              {
                                 bot.netname = "Romero";
                                 bot.fShirt = 0.000;
                                 bot.fPants = 0.000;
                                 bot.personality = PERS_MEMELORD;
                              } //end if
                              else
                              {
                                 if ((id == 11.000))
                                 {
                                    bot.netname = "Carmack";
                                    bot.fShirt = WHITE;
                                    bot.fPants = BLUE;
                                    bot.personality = PERS_PRO;
                                 } //end if
                                 else
                                 {
                                    if ((id == 12.000))
                                    {
                                       bot.netname = "American";
                                       bot.fShirt = RED;
                                       bot.fPants = WHITE;
                                       bot.personality = PERS_CAMPER;
                                    } //end if
                                    else
                                    {
                                       if ((id == 13.000))
                                       {
                                          bot.netname = "Drooly";
                                          bot.fShirt = 13.000;
                                          bot.fPants = 13.000;
                                          bot.personality = PERS_NOOB;
                                          bot.skil = 0.000;
                                       } //end if
                                       else
                                       {
                                          if ((id == 14.000))
                                          {
                                             bot.netname = "Derang";
                                             bot.fShirt = YELLOW;
                                             bot.fPants = RED;
                                             bot.personality = PERS_RAGER;
                                          } //end if
                                          else
                                          {
                                             if ((id == 15.000))
                                             {
                                                bot.netname = "Wanton";
                                                bot.fShirt = PURPLE;
                                                bot.fPants = PURPLE;
                                                bot.personality = PERS_PRO;
                                             } //end if
                                             else
                                             {
                                                if ((id == 16.000))
                                                {
                                                   bot.netname = "Chatter";
                                                   bot.fShirt = GOLD;
                                                   bot.fPants = GOLD;
                                                   bot.personality = PERS_MEMELORD;
                                                } //end if
                                                else
                                                {
                                                   if ((id == 17.000))
                                                   {
                                                      bot.netname = "Frik";
                                                      bot.fShirt = WHITE;
                                                      bot.fPants = RED;
                                                      bot.personality = PERS_MEMELORD;
                                                   } //end if
                                                   else
                                                   {
                                                      if ((id == 18.000))
                                                      {
                                                         bot.netname = "MrElusive";
                                                         bot.fShirt = GREY;
                                                         bot.fPants = 0.000;
                                                         bot.personality = PERS_PRO;
                                                      } //end if
                                                      else
                                                      {
                                                         if ((id == 19.000))
                                                         {
                                                            bot.netname = "Gladiator";
                                                            bot.fShirt = GOLD;
                                                            bot.fPants = RED;
                                                            bot.personality = PERS_PRO;
                                                         } //end if
                                                         else
                                                         {
                                                            if ((id == 20.000))
                                                            {
                                                               bot.netname = "Eraser";
                                                               bot.fShirt = BLUE;
                                                               bot.fPants = WHITE;
                                                               bot.personality = PERS_PRO;
                                                            } //end if
                                                            else
                                                            {
                                                               if ((id == 21.000))
                                                               {
                                                                  bot.netname = "Zeus";
                                                                  bot.fShirt = WHITE;
                                                                  bot.fPants = GOLD;
                                                                  bot.personality = PERS_PRO;
                                                               } //end if
                                                               else
                                                               {
                                                                  if ((id == 22.000))
                                                                  {
                                                                     bot.netname = "Oak";
                                                                     bot.fShirt = BROWN;
                                                                     bot.fPants = GREEN;
                                                                     bot.personality = PERS_CAMPER;
                                                                  } //end if
                                                                  else
                                                                  {
                                                                     if ((id == 23.000))
                                                                     {
                                                                        bot.netname = "Frog";
                                                                        bot.fShirt = GREEN;
                                                                        bot.fPants = YELLOW;
                                                                        bot.personality = PERS_MEMELORD;
                                                                     } //end if
                                                                     else
                                                                     {
                                                                        if ((id == 24.000))
                                                                        {
                                                                           bot.netname = "Cthon";
                                                                           bot.fShirt = RED;
                                                                           bot.fPants = 0.000;
                                                                           bot.personality = PERS_RAGER;
                                                                        } //end if
                                                                        else
                                                                        {
                                                                           if ((id == 25.000))
                                                                           {
                                                                              bot.netname = "Eliminator";
                                                                              bot.fShirt = 0.000;
                                                                              bot.fPants = RED;
                                                                              bot.personality = PERS_PRO;
                                                                           } //end if
                                                                           else
                                                                           {
                                                                              if ((id == 26.000))
                                                                              {
                                                                                 bot.netname = "TheTutor";
                                                                                 bot.fShirt = WHITE;
                                                                                 bot.fPants = BROWN;
                                                                                 bot.personality = PERS_CAMPER;
                                                                              } //end if
                                                                              else
                                                                              {
                                                                                 if ((id == 27.000))
                                                                                 {
                                                                                    bot.netname = "Jumbot";
                                                                                    bot.fShirt = BLUE;
                                                                                    bot.fPants = BLUE;
                                                                                    bot.personality = PERS_NOOB;
                                                                                    bot.skil = 1.000;
                                                                                 } //end if
                                                                                 else
                                                                                 {
                                                                                    if ((id == 28.000))
                                                                                    {
                                                                                       bot.netname = "Ace";
                                                                                       bot.fShirt = GREEN;
                                                                                       bot.fPants = 0.000;
                                                                                       bot.personality = PERS_PRO;
                                                                                    } //end if
                                                                                    else
                                                                                    {
                                                                                       if ((id == 29.000))
                                                                                       {
                                                                                          bot.netname = "DoomGuy";
                                                                                          bot.fShirt = GREEN;
                                                                                          bot.fPants = GREEN;
                                                                                          bot.personality = PERS_PRO;
                                                                                       } //end if
                                                                                       else
                                                                                       {
                                                                                          if ((id == 30.000))
                                                                                          {
                                                                                             bot.netname = "Ranger";
                                                                                             bot.fShirt = BROWN;
                                                                                             bot.fPants = GOLD;
                                                                                             bot.personality = PERS_PRO;
                                                                                          } //end if
                                                                                          else
                                                                                          {
                                                                                             if ((id == 31.000))
                                                                                             {
                                                                                                bot.netname = "Bitterman";
                                                                                                bot.fShirt = GREY;
                                                                                                bot.fPants = GREEN;
                                                                                                bot.personality = PERS_CAMPER;
                                                                                             } //end if
                                                                                             else
                                                                                             {
                                                                                                if ((id == 32.000))
                                                                                                {
                                                                                                   bot.netname = "TankJr";
                                                                                                   bot.fShirt = RED;
                                                                                                   bot.fPants = RED;
                                                                                                   bot.personality = PERS_RAGER;
                                                                                                } //end if
                                                                                                else
                                                                                                {
                                                                                                   if ((id == 33.000))
                                                                                                   {
                                                                                                      bot.netname = "Crash";
                                                                                                      bot.fShirt = PURPLE;
                                                                                                      bot.fPants = PURPLE;
                                                                                                      bot.personality = PERS_NOOB;
                                                                                                      bot.skil = 1.000;
                                                                                                   } //end if
                                                                                                   else
                                                                                                   {
                                                                                                      if ((id == 34.000))
                                                                                                      {
                                                                                                         bot.netname = "Phobos";
                                                                                                         bot.fShirt = GOLD;
                                                                                                         bot.fPants = GREEN;
                                                                                                         bot.personality = PERS_PRO;
                                                                                                      } //end if
                                                                                                      else
                                                                                                      {
                                                                                                         if ((id == 35.000))
                                                                                                         {
                                                                                                            bot.netname = "Slash";
                                                                                                            bot.fShirt = BLUE;
                                                                                                            bot.fPants = 0.000;
                                                                                                            bot.personality = PERS_MEMELORD;
                                                                                                         } //end if
                                                                                                         else
                                                                                                         {
                                                                                                            if ((id == 36.000))
                                                                                                            {
                                                                                                               bot.netname = "Anarki";
                                                                                                               bot.fShirt = RED;
                                                                                                               bot.fPants = YELLOW;
                                                                                                               bot.personality = PERS_MEMELORD;
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
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
   } //end if

}; //end of the function Bot_AssignIdentity

void () AddAnotherBot =
{
   local entity newbot;
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
   newbot.fClientNo = cno;
   newbot.team = 99.000;

   NUMBOTS = (NUMBOTS + SPAWNFLAG_SUPERSPIKE);

   if (!teamplay)
   {
      // Randomize bot identity selection (1-36 bot profiles)
      // Avoid duplicates by checking last 8 spawns
      local float random_id;
      local float attempts;
      local float is_duplicate;
      local string debug_str;

      attempts = 0.000;
      is_duplicate = TRUE;

      // Try up to 20 times to find a bot not in recent history
      while (((attempts < 20.000) && is_duplicate))
      {
         random_id = (floor ((random () * 36.000)) + SPAWNFLAG_SUPERSPIKE);

         // Check if this ID was used recently
         is_duplicate = FALSE;
         if ((random_id == LAST_BOT_ID_0)) is_duplicate = TRUE;
         if ((random_id == LAST_BOT_ID_1)) is_duplicate = TRUE;
         if ((random_id == LAST_BOT_ID_2)) is_duplicate = TRUE;
         if ((random_id == LAST_BOT_ID_3)) is_duplicate = TRUE;
         if ((random_id == LAST_BOT_ID_4)) is_duplicate = TRUE;
         if ((random_id == LAST_BOT_ID_5)) is_duplicate = TRUE;
         if ((random_id == LAST_BOT_ID_6)) is_duplicate = TRUE;
         if ((random_id == LAST_BOT_ID_7)) is_duplicate = TRUE;

         attempts = (attempts + SPAWNFLAG_SUPERSPIKE);
      } //end while

      // Update history (ring buffer)
      LAST_BOT_ID_7 = LAST_BOT_ID_6;
      LAST_BOT_ID_6 = LAST_BOT_ID_5;
      LAST_BOT_ID_5 = LAST_BOT_ID_4;
      LAST_BOT_ID_4 = LAST_BOT_ID_3;
      LAST_BOT_ID_3 = LAST_BOT_ID_2;
      LAST_BOT_ID_2 = LAST_BOT_ID_1;
      LAST_BOT_ID_1 = LAST_BOT_ID_0;
      LAST_BOT_ID_0 = random_id;

      dprint ("Random bot ID: ");
      debug_str = ftos (random_id);
      dprint (debug_str);
      dprint (" (attempts: ");
      debug_str = ftos (attempts);
      dprint (debug_str);
      dprint (")\n");

      Bot_AssignIdentity (newbot,random_id);
      newbot.colormap = (newbot.fClientNo + SPAWNFLAG_SUPERSPIKE);
      if (NAMEBOTS)
      {
         newbot.teamname = self.netname;
      } //end if
      else
      {
         newbot.teamname = "";
      } //end if
   } //end if
   else
   {
      newbot.colormap = (cno + SPAWNFLAG_SUPERSPIKE);
      newbot.fShirt = SPAWNFLAG_LASER;
      newbot.fPants = SPAWNFLAG_LASER;
      newbot.netname = "Grunt";
      newbot.personality = PERS_PRO;
      newbot.teamname = newbot.netname;
   } //end if

   if (!teamplay)
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

   if ((NUMBOTS == SPAWNFLAG_SUPERSPIKE))
   {
      newbot.nextthink = (time + 0.100);
   } //end if
   if ((NUMBOTS < SECRET_YES_SHOOT))
   {
      serverflags = ((serverflags - (serverflags & BOTS)) + (SECRET_YES_SHOOT * NUMBOTS));
   } //end if
}; //end of the function AddAnotherBot

void (entity ply, float n) addTeamBots =
{
   local entity newbot;
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
   e = findbot (world);
   while ((i > CAM_IDLE))
   {
      while (((e != world) && (e.team != ply.team)))
      {
         e = findbot (e);
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

   e = findbot (world);
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
      e = findbot (e);
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

   e = findbot (world);
   while (e)
   {
      if ((e.colormap == self.colormap))
      {
         e.team = self.team;
      } //end if
      e = findbot (e);
   } //end while
}; //end of the function UpdateTeamColors
