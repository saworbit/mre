
void () player_pain;

void () player_stand1;

void (vector org) spawn_tfog;

void (vector org, entity death_owner) spawn_tdeath;

// Forward declaration for chat system (defined in botchat.qc)
void (float ctx, entity targ) BotChat;
float modelindex_eyes /* = 0.000 */;
float modelindex_player /* = 0.000 */;
float intermission_running /* = 0.000 */;
float intermission_exittime /* = 0.000 */;

void () info_intermission =
{
}; //end of the function info_intermission

void () SetChangeParms =
{
   local float offset;
   local float toffset;
   local float team1;
   local float nb;
   local float nt;
   local entity e;

   self.items = (self.items - (self.items & (((((IT_KEY1 | IT_KEY2) | IT_INVISIBILITY) | IT_INVULNERABILITY) | IT_SUIT) | IT_QUAD)));
   if ((self.health > MUST_HAVE))
   {
      self.health = MUST_HAVE;
   } //end if
   if ((self.health < 50.000))
   {
      self.health = 50.000;
   } //end if
   parm1 = self.items;
   parm2 = self.health;
   parm3 = self.armorvalue;
   if ((self.ammo_shells < 25.000))
   {
      parm4 = 25.000;

   } //end if
   else
   {
      parm4 = self.ammo_shells;
   } //end if
   parm5 = self.ammo_nails;
   parm6 = self.ammo_rockets;
   parm7 = self.ammo_cells;
   parm8 = self.weapon;
   parm9 = (self.armortype * MUST_HAVE);
   if (SKINSMODE)
   {
      parm4 = ((parm4 + (self.skin * FL_ONGROUND)) + (IT_ARMOR2 * SKINSMODE));
   } //end if
   e = find (world,classname,"dmbot");
   offset = WEAPON_SHOTGUN;
   toffset = WEAPON_SHOTGUN;
   parm10 = CAM_IDLE;
   parm11 = CAM_IDLE;
   team1 = MUST_HAVE;
   nb = CAM_IDLE;
   nt = CAM_IDLE;
   while (e)
   {
      if ((e.team == 99.000))
      {
         nb = (nb + TRUE);
         if ((nb < MOVETYPE_TOSS))
         {
            parm10 = (parm10 + (((offset * e.skil) * MOVETYPE_BOUNCE) & (offset * SVC_FINALE)));
            offset = (offset * FL_MONSTER);
         } //end if

      } //end if
      else
      {
         if ((team1 == MUST_HAVE))
         {
            team1 = e.team;
         } //end if
         if ((e.team == team1))
         {
            nt = (nt + TRUE);
            if ((nt < MOVETYPE_TOSS))
            {
               parm11 = (parm11 + (((toffset * e.skil) * MOVETYPE_BOUNCE) & (toffset * SVC_FINALE)));
               toffset = (toffset * FL_MONSTER);
            } //end if
         } //end if
      } //end if
      e = find (e,classname,"dmbot");
   } //end while
}; //end of the function SetChangeParms

void () SetNewParms =
{
   parm1 = (IT_SHOTGUN | IT_AXE);
   parm2 = MUST_HAVE;
   parm3 = FALSE;
   parm4 = 25.000;
   parm5 = FALSE;
   parm6 = FALSE;
   parm7 = FALSE;
   parm8 = TRUE;
   parm9 = FALSE;
}; //end of the function SetNewParms

void () DecodeLevelParms =
{
   local float skinno;

   if ((parm4 > 511.000))
   {
      SKINSMODE = ((parm4 & 49152.000) / IT_ARMOR2);
      skinno = (parm4 & 7680.000);
      parm4 = (parm4 & 511.000);
      skinChange (self,skinno);
   } //end if
   self.items = parm1;
   self.health = parm2;
   self.armorvalue = parm3;
   self.ammo_shells = parm4;
   self.ammo_nails = parm5;
   self.ammo_rockets = parm6;
   self.ammo_cells = parm7;
   self.weapon = parm8;
   self.armortype = (parm9 * 0.010);
}; //end of the function DecodeLevelParms
entity () FindIntermission =
{
   local entity spot;
   local float cyc;

   spot = find (world,classname,"info_intermission");
   if (spot)
   {
      cyc = (random () * MOVETYPE_STEP);
      while ((cyc > TRUE))
      {
         spot = find (spot,classname,"info_intermission");
         if (!spot)
         {
            spot = find (spot,classname,"info_intermission");
         } //end if
         cyc = (cyc - TRUE);
      } //end while
      return (spot);
   } //end if
   spot = find (world,classname,"info_player_start");
   if (spot)
   {
      return (spot);
   } //end if
   spot = find (world,classname,"testplayerstart");
   if (spot)
   {
      return (spot);
   } //end if
   objerror ("FindIntermission: no spot");
}; //end of the function FindIntermission
string nextmap /* = "" */;

void () GotoNextMap =
{
   if (cvar ("samelevel"))
   {
      changelevel (mapname);

   } //end if
   else
   {
      changelevel (nextmap);
   } //end if
}; //end of the function GotoNextMap

void () ExitIntermission =
{
   if (deathmatch)
   {
      GotoNextMap ();
      return ;
   } //end if
   intermission_exittime = (time + TRUE);
   intermission_running = (intermission_running + TRUE);
   if ((intermission_running == FL_SWIM))
   {
      if ((world.model == "maps/e1m7.bsp"))
      {
         WriteByte (MSG_ALL,SVC_CDTRACK);
         WriteByte (MSG_ALL,FL_SWIM);
         WriteByte (MSG_ALL,MOVETYPE_WALK);
         if (!cvar ("registered"))
         {
            WriteByte (MSG_ALL,SVC_FINALE);
            WriteString (MSG_ALL,"As the corpse of the monstrous entity\nChthon sinks back into the lava whence\nit rose, you grip the Rune of Earth\nMagic tightly. Now that you have\nconquered the Dimension of the Doomed,\nrealm of Earth Magic, you are ready to\ncomplete your t...");

         } //end if
         else
         {
            WriteByte (MSG_ALL,SVC_FINALE);
            WriteString (MSG_ALL,"As the corpse of the monstrous entity\nChthon sinks back into the lava whence\nit rose, you grip the Rune of Earth\nMagic tightly. Now that you have\nconquered the Dimension of the Doomed,\nrealm of Earth Magic, you are ready to\ncomplete your t...");
         } //end if
         return ;

      } //end if
      else
      {
         if ((world.model == "maps/e2m6.bsp"))
         {
            WriteByte (MSG_ALL,SVC_CDTRACK);
            WriteByte (MSG_ALL,FL_SWIM);
            WriteByte (MSG_ALL,MOVETYPE_WALK);
            WriteByte (MSG_ALL,SVC_FINALE);
            WriteString (MSG_ALL,"The Rune of Black Magic throbs evilly in\nyour hand and whispers dark thoughts\ninto your brain. You learn the inmost\nlore of the Hell-Mother; Shub-Niggurath!\nYou now know that she is behind all the\nterrible plotting which has led to so\nmuch...");
            return ;

         } //end if
         else
         {
            if ((world.model == "maps/e3m6.bsp"))
            {
               WriteByte (MSG_ALL,SVC_CDTRACK);
               WriteByte (MSG_ALL,FL_SWIM);
               WriteByte (MSG_ALL,MOVETYPE_WALK);
               WriteByte (MSG_ALL,SVC_FINALE);
               WriteString (MSG_ALL,"The charred viscera of diabolic horrors\nbubble viscously as you seize the Rune\nof Hell Magic. Its heat scorches your\nhand, and its terrible secrets blight\nyour mind. Gathering the shreds of your\ncourage, you shake the devil's shackles\nfrom...");
               return ;

            } //end if
            else
            {
               if ((world.model == "maps/e4m7.bsp"))
               {
                  WriteByte (MSG_ALL,SVC_CDTRACK);
                  WriteByte (MSG_ALL,FL_SWIM);
                  WriteByte (MSG_ALL,MOVETYPE_WALK);
                  WriteByte (MSG_ALL,SVC_FINALE);
                  WriteString (MSG_ALL,"Despite the awful might of the Elder\nWorld, you have achieved the Rune of\nElder Magic, capstone of all types of\narcane wisdom. Beyond good and evil,\nbeyond life and death, the Rune\npulsates, heavy with import. Patient and\npotent, the Elder...");
                  return ;
               } //end if
            } //end if
         } //end if
      } //end if
      GotoNextMap ();
   } //end if
   if ((intermission_running == MOVETYPE_WALK))
   {
      if (!cvar ("registered"))
      {
         WriteByte (MSG_ALL,SVC_SELLSCREEN);
         return ;
      } //end if
      if (((serverflags & 15.000) == 15.000))
      {
         WriteByte (MSG_ALL,SVC_FINALE);
         WriteString (MSG_ALL,"Now, you have all four Runes. You sense\ntremendous invisible forces moving to\nunseal ancient barriers. Shub-Niggurath\nhad hoped to use the Runes Herself to\nclear off the Earth, but now instead,\nyou will use them to enter her home and\nconfr...");
         return ;
      } //end if
   } //end if
   GotoNextMap ();
}; //end of the function ExitIntermission

void () IntermissionThink =
{
   if ((time < intermission_exittime))
   {
      return ;
   } //end if
   if (((!self.button0 && !self.button1) && !self.button2))
   {
      return ;
   } //end if
   ExitIntermission ();
}; //end of the function IntermissionThink

void () execute_changelevel =
{
   local entity pos;

   intermission_running = TRUE;
   if (deathmatch)
   {
      intermission_exittime = (time + CAM_FREE);

   } //end if
   else
   {
      intermission_exittime = (time + WEAPON_ROCKET);
   } //end if
   WriteByte (MSG_ALL,SVC_CDTRACK);
   WriteByte (MSG_ALL,CAM_FOLLOW);
   WriteByte (MSG_ALL,CAM_FOLLOW);
   pos = FindIntermission ();
   other = find (world,classname,"player");
   while ((other != world))
   {
      other.view_ofs = VEC_ORIGIN;
      other.v_angle = pos.mangle;
      other.angles = pos.mangle;
      other.fixangle = TRUE;
      other.nextthink = (time + 0.500);
      other.takedamage = DAMAGE_NO;
      other.solid = SOLID_NOT;
      other.movetype = MOVETYPE_NONE;
      other.modelindex = CAM_IDLE;
      setorigin (other,pos.origin);
      other = find (other,classname,"player");
   } //end while
   WriteByte (MSG_ALL,SVC_INTERMISSION);
   serverflags = (serverflags | INITLEVEL);
}; //end of the function execute_changelevel

void () changelevel_touch =
{
   local entity pos;

   if ((self.classname == "watcher"))
   {
      if ((other.classname != "player"))
      {
         return ;
      } //end if
   } //end if
   if (cvar ("noexit"))
   {
      T_Damage (other,self,self,50000.000);
      return ;
   } //end if
   bprint (other.teamname);
   bprint (other.netname);
   bprint (" exited the level\n");
   nextmap = self.map;
   SUB_UseTargets ();
   if (((self.spawnflags & TRUE) && (deathmatch == FALSE)))
   {
      GotoNextMap ();
      return ;
   } //end if
   self.touch = SUB_Null;
   self.think = execute_changelevel;
   self.nextthink = (time + 0.100);
}; //end of the function changelevel_touch

void () trigger_changelevel =
{
   if (!self.map)
   {
      objerror ("changelevel trigger doesn't have map");
   } //end if
   InitTrigger ();
   self.touch = changelevel_touch;
}; //end of the function trigger_changelevel

void () set_suicide_frame;

void () respawn =
{
   if (coop)
   {
      CopyToBodyQue (self);
      setspawnparms (self);
      PutClientInServer ();

   } //end if
   else
   {
      if (deathmatch)
      {
         CopyToBodyQue (self);
         SetNewParms ();
         PutClientInServer ();

      } //end if
      else
      {
         localcmd ("restart\n");
      } //end if
   } //end if
}; //end of the function respawn

void () ClientKill =
{
   if ((self.classname == "KasCam"))
   {
      if ((self.classname == "watcher"))
      {
         return ;
      } //end if
   } //end if
   bprint (self.netname);
   bprint (" suicides\n");
   set_suicide_frame ();
   self.modelindex = modelindex_player;
   self.frags = (self.frags - FL_SWIM);
   countkill (self,self);
   respawn ();
}; //end of the function ClientKill
float (float v_x, float v_y, float v_z) CheckSpawnPoint =
{
   return (FALSE);
}; //end of the function CheckSpawnPoint
entity () SelectSpawnPoint =
{
   local entity spot;
   local float rnd;

   spot = find (world,classname,"testplayerstart");
   if (spot)
   {
      return (spot);
   } //end if
   if (coop)
   {
      lastspawn = find (lastspawn,classname,"info_player_coop");
      if ((lastspawn == world))
      {
         lastspawn = find (lastspawn,classname,"info_player_start");
      } //end if
      if ((lastspawn != world))
      {
         return (lastspawn);
      } //end if

   } //end if
   else
   {
      if (deathmatch)
      {
         if ((teamplay != TE_LIGHTNING1))
         {
            lastspawn = find (lastspawn,classname,"info_player_deathmatch");
            if ((lastspawn == world))
            {
               lastspawn = find (lastspawn,classname,"info_player_deathmatch");
            } //end if

         } //end if
         else
         {
            while ((lastspawn.team != self.team))
            {
               lastspawn = find (lastspawn,classname,"info_player_teamplay");
               if ((lastspawn == world))
               {
                  lastspawn = find (lastspawn,classname,"info_player_teamplay");
               } //end if
            } //end while
         } //end if
         if ((lastspawn != world))
         {
            return (lastspawn);
         } //end if
      } //end if
   } //end if
   if (serverflags)
   {
      spot = find (world,classname,"info_player_start2");
      if (spot)
      {
         return (spot);
      } //end if
   } //end if
   spot = find (world,classname,"info_player_start");
   if (!spot)
   {
      error ("PutClientInServer: no info_player_start on level");
   } //end if
   return (spot);
}; //end of the function SelectSpawnPoint

void () PlayerDie;

void () PutClientInServer =
{
   local entity spot;
   local float dedflags;

   self.classname = "player";
   self.health = MUST_HAVE;
   self.takedamage = DAMAGE_AIM;
   self.solid = SOLID_SLIDEBOX;
   self.movetype = MOVETYPE_WALK;
   self.show_hostile = FALSE;
   self.max_health = MUST_HAVE;
   self.flags = FL_CLIENT;
   self.air_finished = (time + 12.000);
   self.dmg = FL_SWIM;
   self.super_damage_finished = FALSE;
   self.radsuit_finished = FALSE;
   self.invisible_finished = FALSE;
   self.invincible_finished = FALSE;
   self.effects = FALSE;
   self.invincible_time = FALSE;
   Stack_Clear();  // Clear goal stack on respawn (Phase 8: Target Stack)
   DecodeLevelParms ();
   W_SetCurrentAmmo ();
   self.attack_finished = time;
   self.th_pain = player_pain;
   self.th_die = PlayerDie;
   self.th_cache = cacheenemy;
   self.deadflag = DEAD_NO;
   self.pausetime = FALSE;
   spot = SelectSpawnPoint ();
   self.oldorigin = (spot.origin + '0.000 0.000 1.000');
   self.origin = (spot.origin + '0.000 0.000 1.000');
   self.angles = spot.angles;
   self.fixangle = TRUE;
   setmodel (self,"progs/eyes.mdl");
   modelindex_eyes = self.modelindex;
   setmodel (self,"progs/player.mdl");
   modelindex_player = self.modelindex;
   setsize (self,VEC_HULL_MIN,VEC_HULL_MAX);
   self.view_ofs = '0.000 0.000 22.000';
   self.velocity = VEC_ORIGIN;
   if ((self.movetarget == world))
   {
      NewCarriedPath ();
   } //end if
   setorigin (self.movetarget,self.origin);
   self.movetarget.movetarget = world;
   self.pathtype = NEVERTARGET;
   if (!self.pather)
   {
      NUMPATHERS = (NUMPATHERS + TRUE);
   } //end if
   self.pather = TRUE;
   player_stand1 ();
   if ((deathmatch || coop))
   {
      makevectors (self.angles);
      spawn_tfog ((self.origin + (v_forward * KINDA_WANT)));
   } //end if
   spawn_tdeath (self.origin,self);
   dedflags = cvar ("temp1");
   if ((dedflags & DEDICATED))
   {
      serverflags = (dedflags | INITLEVEL);
      cvar_set ("temp1","0");
   } //end if
   if ((serverflags & INITLEVEL))
   {
      initBotLevel ();
   } //end if

   // ===== SHADOW SYSTEM: Init Player Learning =====
   // Give the player a "path carrier" so they can drop breadcrumbs like a bot.
   // This allows bots to learn map routes simply by watching the human play.
   if (!self.movetarget)
   {
      self.movetarget = spawn();
      self.movetarget.classname = "BotPath";
      self.movetarget.pathtype = CARRIED;
      setorigin(self.movetarget, self.origin);
   }
   // Reset any flags
   self.lefty = 0;
   // ===============================================
}; //end of the function PutClientInServer

void () info_player_start =
{
}; //end of the function info_player_start

void () info_player_start2 =
{
}; //end of the function info_player_start2

void () testplayerstart =
{
}; //end of the function testplayerstart

void () info_player_deathmatch =
{
}; //end of the function info_player_deathmatch

void () info_player_coop =
{
}; //end of the function info_player_coop

void (entity c) PrintClientScore =
{
   if (((c.frags > -10.000) && (c.frags < FALSE)))
   {
      bprint (" ");

   } //end if
   else
   {
      if ((c.frags >= FALSE))
      {
         if ((c.frags < MUST_HAVE))
         {
            bprint (" ");
         } //end if
         if ((c.frags < MOVETYPE_BOUNCE))
         {
            bprint (" ");
         } //end if
      } //end if
   } //end if
}; //end of the function PrintClientScore

void () DumpScore =
{
   local entity e;
   local entity sort;
   local entity walk;

   if (world.chain)
   {
      error ("DumpScore: world.chain is set");
   } //end if
   e = find (world,classname,"player");
   sort = world;
   while (e)
   {
      if (!sort)
      {
         sort = e;
         e.chain = world;

      } //end if
      else
      {
         if ((e.frags > sort.frags))
         {
            e.chain = sort;
            sort = e;

         } //end if
         else
         {
            walk = sort;
            do
            {
               if (!walk.chain)
               {
                  e.chain = world;
                  walk.chain = e;

               } //end if
               else
               {
                  if ((walk.chain.frags < e.frags))
                  {
                     e.chain = walk.chain;
                     walk.chain = e;

                  } //end if
                  else
                  {
                     walk = walk.chain;
                  } //end if
               } //end if
            } while ((walk.chain != e));
         } //end if
      } //end if
      e = find (e,classname,"player");
   } //end while
   bprint ("\n");
   while (sort)
   {
      PrintClientScore (sort);
      sort = sort.chain;
   } //end while
   bprint ("\n");
}; //end of the function DumpScore

void () NextLevel =
{
   local entity o;

   o = find (world,classname,"trigger_changelevel");
   if ((!o || (mapname == "start")))
   {
      o = spawn ();
      o.map = mapname;
   } //end if
   nextmap = o.map;
   if ((o.nextthink < time))
   {
      o.think = execute_changelevel;
      o.nextthink = (time + 0.100);
   } //end if
}; //end of the function NextLevel

void () CheckRules =
{
   local float time_left;
   local float timelimit;
   local float fraglimit;

   if (gameover)
   {
      return ;
   } //end if
   timelimit = (cvar ("timelimit") * 60.000);
   fraglimit = cvar ("fraglimit");
   if ((timelimit && (time >= timelimit)))
   {
      NextLevel ();
      return ;
   } //end if
   if ((fraglimit && (self.frags >= fraglimit)))
   {
      NextLevel ();
      return ;
   } //end if
   if (timelimit)
   {
      time_left = rint ((timelimit - time));
      if (((time_left == 120.000) && (last_time_left != time_left)))
      {
         last_time_left = 120.000;
         bprint ("2 minutes remain in the match\n");
      } //end if
      if (((time_left == 60.000) && (last_time_left != time_left)))
      {
         last_time_left = 60.000;
         bprint ("1 minute remains in the match\n");
      } //end if
      if (((time_left == SVC_INTERMISSION) && (last_time_left != time_left)))
      {
         last_time_left = SVC_INTERMISSION;
         bprint ("30 seconds remain in the match\n");
      } //end if
      if (((time_left == TE_LAVASPLASH) && (last_time_left != time_left)))
      {
         last_time_left = TE_LAVASPLASH;
         bprint ("10 seconds remain in the match\n");
      } //end if
      if ((((time_left < TE_LAVASPLASH) && (time_left > CAM_IDLE)) && (last_time_left != time_left)))
      {
         last_time_left = time_left;
         bprint (ftos (time_left));
         bprint (" second");
         if ((time_left > WEAPON_SHOTGUN))
         {
            bprint ("s");
         } //end if
         bprint ("\n");
      } //end if
      if (((time_left == CAM_IDLE) && (last_time_left != time_left)))
      {
         last_time_left = CAM_IDLE;
         bprint ("The match is over\n");
      } //end if
   } //end if
}; //end of the function CheckRules

void () PlayerDeathThink =
{
   local entity old_self;
   local float forward;

   if ((self.flags & FL_ONGROUND))
   {
      forward = vlen (self.velocity);
      forward = (forward - KINDA_WANT);
      if ((forward <= FALSE))
      {
         self.velocity = VEC_ORIGIN;

      } //end if
      else
      {
         self.velocity = (forward * normalize (self.velocity));
      } //end if
   } //end if
   if ((self.deadflag == DEAD_DEAD))
   {
      if (((self.button2 || self.button1) || self.button0))
      {
         return ;
      } //end if
      self.deadflag = DEAD_RESPAWNABLE;
      return ;
   } //end if
   if (((!self.button2 && !self.button1) && !self.button0))
   {
      return ;
   } //end if
   self.button0 = FALSE;
   self.button1 = FALSE;
   self.button2 = FALSE;
   respawn ();
}; //end of the function PlayerDeathThink

void () PlayerJump =
{
   local float start_x;
   local float start_y;
   local float start_z;
   local float end_x;
   local float end_y;
   local float end_z;

   if ((self.flags & FL_WATERJUMP))
   {
      return ;
   } //end if
   if ((self.waterlevel >= WEAPON_ROCKET))
   {
      if ((self.watertype == CONTENT_WATER))
      {
         self.velocity_z = MUST_HAVE;

      } //end if
      else
      {
         if ((self.watertype == CONTENT_SLIME))
         {
            self.velocity_z = 80.000;

         } //end if
         else
         {
            self.velocity_z = 50.000;
         } //end if
      } //end if
      if ((self.swim_flag < time))
      {
         self.swim_flag = (time + WEAPON_SHOTGUN);
         if ((random () < 0.500))
         {
            sound (self,CHAN_BODY,"misc/water1.wav",WEAPON_SHOTGUN,ATTN_NORM);

         } //end if
         else
         {
            sound (self,CHAN_BODY,"misc/water2.wav",WEAPON_SHOTGUN,ATTN_NORM);
         } //end if
      } //end if
      return ;
   } //end if
   if (!(self.flags & FL_ONGROUND))
   {
      return ;
   } //end if
   if (!(self.flags & FL_JUMPRELEASED))
   {
      return ;
   } //end if
   self.flags = (self.flags - (self.flags & FL_JUMPRELEASED));
   self.flags = (self.flags - FL_ONGROUND);
   self.button2 = FALSE;
   sound (self,CHAN_BODY,"player/plyrjmp8.wav",WEAPON_SHOTGUN,ATTN_NORM);
   self.velocity_z = (self.velocity_z + 270.000);
}; //end of the function PlayerJump
.float dmgtime;

void () WaterMove =
{
   if ((self.movetype == MOVETYPE_NOCLIP))
   {
      return ;
   } //end if
   if ((self.health <= CAM_IDLE))
   {
      return ;
   } //end if
   if ((self.waterlevel != CAM_FOLLOW))
   {
      if ((self.air_finished < time))
      {
         sound (self,CHAN_VOICE,"player/gasp2.wav",TRUE,ATTN_NORM);

      } //end if
      else
      {
         if ((self.air_finished < (time + MOVETYPE_FLYMISSILE)))
         {
            sound (self,CHAN_VOICE,"player/gasp1.wav",TRUE,ATTN_NORM);
         } //end if
      } //end if
      self.air_finished = (time + 12.000);
      self.dmg = WEAPON_ROCKET;

   } //end if
   else
   {
      if ((self.air_finished < time))
      {
         if ((self.pain_finished < time))
         {
            self.dmg = (self.dmg + WEAPON_ROCKET);
            if ((self.dmg > 15.000))
            {
               self.dmg = TE_LAVASPLASH;
            } //end if
            T_Damage (self,world,world,self.dmg);
            self.pain_finished = (time + TRUE);
         } //end if
      } //end if
   } //end if
   if (!self.waterlevel)
   {
      if ((self.flags & FL_INWATER))
      {
         sound (self,CHAN_BODY,"misc/outwater.wav",0.300,ATTN_NORM);
         self.flags = (self.flags - FL_INWATER);
      } //end if
      return ;
   } //end if
   if ((self.watertype == CONTENT_LAVA))
   {
      if ((self.dmgtime < time))
      {
         if ((self.radsuit_finished > time))
         {
            self.dmgtime = (time + TRUE);

         } //end if
         else
         {
            self.dmgtime = (time + 0.200);
         } //end if
         T_Damage (self,world,world,(MOVETYPE_BOUNCE * self.waterlevel));
      } //end if

   } //end if
   else
   {
      if ((self.watertype == CONTENT_SLIME))
      {
         if (((self.dmgtime < time) && (self.radsuit_finished < time)))
         {
            self.dmgtime = (time + TRUE);
            T_Damage (self,world,world,(MOVETYPE_STEP * self.waterlevel));
         } //end if
      } //end if
   } //end if
   if (!(self.flags & FL_INWATER))
   {
      if ((self.watertype == CONTENT_LAVA))
      {
         sound (self,CHAN_BODY,"player/inlava.wav",0.300,ATTN_NORM);
      } //end if
      if ((self.watertype == CONTENT_WATER))
      {
         sound (self,CHAN_BODY,"player/inh2o.wav",0.300,ATTN_NORM);
      } //end if
      if ((self.watertype == CONTENT_SLIME))
      {
         sound (self,CHAN_BODY,"player/slimbrn2.wav",0.300,ATTN_NORM);
      } //end if
      self.flags = (self.flags + FL_INWATER);
      self.dmgtime = FALSE;
   } //end if
   if (!(self.flags & FL_WATERJUMP))
   {
      self.velocity = (self.velocity - (((0.800 * self.waterlevel) * frametime) * self.velocity));
   } //end if
}; //end of the function WaterMove

void () CheckWaterJump =
{
   local vector start;
   local vector end;

   makevectors (self.angles);
   start = self.origin;
   start_z = (start_z + FL_CLIENT);
   v_forward_z = FALSE;
   normalize (v_forward);
   end = (start + (v_forward * 24.000));
   traceline (start,end,TRUE,self);
   if ((trace_fraction < TRUE))
   {
      start_z = ((start_z + self.maxs_z) - FL_CLIENT);
      end = (start + (v_forward * 24.000));
      self.movedir = (trace_plane_normal * -50.000);
      traceline (start,end,TRUE,self);
      if ((trace_fraction == TRUE))
      {
         self.flags = (self.flags | FL_WATERJUMP);
         self.velocity_z = 225.000;
         self.flags = (self.flags - (self.flags & FL_JUMPRELEASED));
         self.teleport_time = (time + WEAPON_ROCKET);
         return ;
      } //end if
   } //end if
}; //end of the function CheckWaterJump

void () PlayerPreThink =
{
   local float mspeed;
   local float aspeed;
   local float r;

   if (intermission_running)
   {
      IntermissionThink ();
      return ;
   } //end if
   if ((self.view_ofs == VEC_ORIGIN))
   {
      return ;
   } //end if
   makevectors (self.v_angle);
   CheckRules ();
   WaterMove ();
   if ((self.waterlevel == WEAPON_ROCKET))
   {
      CheckWaterJump ();
   } //end if
   if ((self.deadflag >= DEAD_DEAD))
   {
      PlayerDeathThink ();
      return ;
   } //end if
   if ((self.deadflag == DEAD_DYING))
   {
      return ;
   } //end if
   if (self.button2)
   {
      PlayerJump ();

   } //end if
   else
   {
      self.flags = (self.flags | FL_JUMPRELEASED);
   } //end if
   if ((time < self.pausetime))
   {
      self.velocity = VEC_ORIGIN;
   } //end if
}; //end of the function PlayerPreThink

void () CheckPowerups =
{
   if ((self.health <= FALSE))
   {
      return ;
   } //end if
   if (self.invisible_finished)
   {
      if ((self.invisible_sound < time))
      {
         sound (self,CHAN_AUTO,"items/inv3.wav",0.500,ATTN_IDLE);
         self.invisible_sound = (time + ((random () * MOVETYPE_WALK) + TRUE));
      } //end if
      if ((self.invisible_finished < (time + MOVETYPE_WALK)))
      {
         if ((self.invisible_time == TRUE))
         {
            sprint (self,"Ring of Shadows magic is fading\n");
            stuffcmd (self,"bf\n");
            sound (self,CHAN_AUTO,"items/inv2.wav",TRUE,ATTN_NORM);
            self.invisible_time = (time + TRUE);
         } //end if
         if ((self.invisible_time < time))
         {
            self.invisible_time = (time + TRUE);
            stuffcmd (self,"bf\n");
         } //end if
      } //end if
      if ((self.invisible_finished < time))
      {
         self.items = (self.items - IT_INVISIBILITY);
         self.invisible_finished = FALSE;
         self.invisible_time = FALSE;
      } //end if
      self.frame = FALSE;
      self.modelindex = modelindex_eyes;

   } //end if
   else
   {
      self.modelindex = modelindex_player;
   } //end if
   if (self.invincible_finished)
   {
      if ((self.invincible_finished < (time + MOVETYPE_WALK)))
      {
         if ((self.invincible_time == TRUE))
         {
            sprint (self,"Protection is almost burned out\n");
            stuffcmd (self,"bf\n");
            sound (self,CHAN_AUTO,"items/protect2.wav",TRUE,ATTN_NORM);
            self.invincible_time = (time + TRUE);
         } //end if
         if ((self.invincible_time < time))
         {
            self.invincible_time = (time + TRUE);
            stuffcmd (self,"bf\n");
         } //end if
      } //end if
      if ((self.invincible_finished < time))
      {
         self.items = (self.items - IT_INVULNERABILITY);
         self.invincible_time = FALSE;
         self.invincible_finished = FALSE;
      } //end if
      if ((self.invincible_finished > time))
      {
         self.effects = (self.effects | EF_DIMLIGHT);

      } //end if
      else
      {
         self.effects = (self.effects - (self.effects & EF_DIMLIGHT));
      } //end if
   } //end if
   if (self.super_damage_finished)
   {
      if ((self.super_damage_finished < (time + MOVETYPE_WALK)))
      {
         if ((self.super_time == TRUE))
         {
            sprint (self,"Quad Damage is wearing off\n");
            stuffcmd (self,"bf\n");
            sound (self,CHAN_AUTO,"items/damage2.wav",TRUE,ATTN_NORM);
            self.super_time = (time + TRUE);
         } //end if
         if ((self.super_time < time))
         {
            self.super_time = (time + TRUE);
            stuffcmd (self,"bf\n");
         } //end if
      } //end if
      if ((self.super_damage_finished < time))
      {
         self.items = (self.items - IT_QUAD);
         self.super_damage_finished = FALSE;
         self.super_time = FALSE;
      } //end if
      if ((self.super_damage_finished > time))
      {
         self.effects = (self.effects | EF_DIMLIGHT);

      } //end if
      else
      {
         self.effects = (self.effects - (self.effects & EF_DIMLIGHT));
      } //end if
   } //end if
   if (self.radsuit_finished)
   {
      self.air_finished = (time + 12.000);
      if ((self.radsuit_finished < (time + MOVETYPE_WALK)))
      {
         if ((self.rad_time == TRUE))
         {
            sprint (self,"Air supply in Biosuit expiring\n");
            stuffcmd (self,"bf\n");
            sound (self,CHAN_AUTO,"items/suit2.wav",TRUE,ATTN_NORM);
            self.rad_time = (time + TRUE);
         } //end if
         if ((self.rad_time < time))
         {
            self.rad_time = (time + TRUE);
            stuffcmd (self,"bf\n");
         } //end if
      } //end if
      if ((self.radsuit_finished < time))
      {
         self.items = (self.items - IT_SUIT);
         self.rad_time = FALSE;
         self.radsuit_finished = FALSE;
      } //end if
   } //end if
}; //end of the function CheckPowerups

void () PlayerPostThink =
{
   local float mspeed;
   local float aspeed;
   local float r;

   if (((self.classname == "KasCam") && !intermission_running))
   {
      CamThink ();
      return ;
   } //end if
   if ((self.view_ofs == VEC_ORIGIN))
   {
      return ;
   } //end if
   if (self.deadflag)
   {
      return ;
   } //end if

   // ===== SHADOW SYSTEM: Record Path =====
   // If the player is alive and moving, try to drop a waypoint.
   // We use the same 'CheckDropPath' logic bots use to ensure valid spacing.

   // ===== ACTION BREADCRUMBS: Jump Detection (The "Leap of Faith") =====
   // If player presses Jump (button2) while on ground, they are initiating a jump.
   // We must drop a "Jump Node" HERE so the bot knows to jump from this exact spot.
   if ((self.button2) && (self.flags & FL_ONGROUND))
   {
      // Force a drop immediately (bypass search_time throttling)
      // This ensures the node is exactly at the ledge/takeoff point.
      if (CheckDropPath())
      {
         DropBotPath();

         // Tag the node we just dropped!
         if (self.movetarget.movetarget) // The 'oldpath' we just dropped
         {
            self.movetarget.movetarget.action_flag = 1; // 1 = JUMP

            // Optional: Visual confirmation
            // bprint("Jump Node Recorded!\n");
         }
      }
      // Add a small delay so we don't spam multiple jump nodes for one jump
      self.search_time = time + 0.5;
   }
   // ===== STANDARD RECORDING: Walking =====
   else if (self.health > 0 && (self.flags & FL_ONGROUND))
   {
      // Check every 0.1 seconds (throttle to save CPU)
      if (time > self.search_time)
      {
         // Reuse the bot logic!
         // CheckDropPath ensures we don't drop nodes too close together.
         if (CheckDropPath())
         {
            DropBotPath();

            // Optional: Visual feedback for you (Development mode)
            // bprint("Node Dropped!\n");
         }
         self.search_time = time + 0.1;
      }
   }
   // ======================================

   self.movetarget.flags = self.flags;
   setorigin (self.movetarget,self.origin);
   W_WeaponFrame ();
   if ((((self.jump_flag < -300.000) && (self.flags & FL_ONGROUND)) && (self.health > FALSE)))
   {
      if ((self.watertype == CONTENT_WATER))
      {
         sound (self,CHAN_BODY,"player/h2ojump.wav",CAM_IDLE,ATTN_NORM);

      } //end if
      else
      {
         if ((self.jump_flag < -650.000))
         {
            T_Damage (self,world,world,MOVETYPE_FLY);
            sound (self,CHAN_VOICE,"player/land2.wav",TRUE,ATTN_NORM);
            self.deathtype = "falling";

         } //end if
         else
         {
            sound (self,CHAN_VOICE,"player/land.wav",TRUE,ATTN_NORM);
         } //end if
      } //end if
      self.jump_flag = FALSE;
   } //end if
   if (!(self.flags & FL_ONGROUND))
   {
      self.jump_flag = self.velocity_z;
   } //end if
   CheckPowerups ();
}; //end of the function PlayerPostThink

void () printIntro =
{
   local float num;
   local float skinno;
   local entity e;

   e = find (world,classname,"worldspawn");
   if (teamplay)
   {
      if ((parm4 > 511.000))
      {
         SKINSMODE = ((parm4 & 49152.000) / IT_ARMOR2);
         skinno = (parm4 & 7680.000);
         parm4 = (parm4 & 511.000);
         skinChange (self,skinno);
      } //end if
      num = ((serverflags & TEAMBOTS) / FL_ITEM);
      if ((num > FALSE))
      {
         addTeamBots (self,num);
      } //end if
      centerprint (self,"Habitat of the Reformed Reaper Bot");

   } //end if
   else
   {
      centerprint (self,"Habitat of the Reformed Reaper Bot");
   } //end if
}; //end of the function printIntro

void () ClientConnect =
{
   /* ERROR: No local name with offset 7303 */
   /* ERROR: No local name with offset 7305 */
   /* ERROR: No local name with offset 7306 */
   /* ERROR: No local name with offset 7307 */
   /* ERROR: No local name with offset 7308 */
   /* ERROR: No local name with offset 7309 */
   /* ERROR: No local name with offset 7310 */
   local string tmp;
   local float num;
   local entity bot;

   if (((self.netname == "CamClient") || (self.netname == "")))
   {
      self.impulse = 250.000;

   } //end if
   else
   {
      bprint (self.netname);
      bprint (" entered the game\n");
   } //end if
   self.fClientNo = (self.colormap - CARRIED);
   if (clientIsActive (self.fClientNo))
   {
      botInvalidClientNo (self.fClientNo);
   } //end if
   clientSetUsed (self.fClientNo);
   bot = find (world,classname,"dmbot");
   while (bot)
   {
      msgUpdateNameToPlayer (self,bot.fClientNo,bot.netname);
      msgUpdateColorsToPlayer (self,bot.fClientNo,bot.fShirt,bot.fPants);
      msgUpdateFragsToPlayer (self,bot.fClientNo,bot.frags);
      bot = find (bot,classname,"dmbot");
   } //end while
   bprint (self.netname);
   bprint (" entered the game\n");
   self.impulse = 204.000;
   initscore ();
   if (intermission_running)
   {
      ExitIntermission ();
   } //end if
}; //end of the function ClientConnect

void () ClientDisconnect =
{
   local float num;

   if (gameover)
   {
      return ;
   } //end if
   if (CamDisconnect ())
   {
      clientSetFree (self.fClientNo);
      bprint (self.teamname);
      bprint (self.netname);
      bprint (" left the game with ");
      bprint (ftos (self.frags));
      bprint (" frags\n");
      sound (self,CHAN_BODY,"player/tornoff2.wav",TRUE,ATTN_NONE);
      self.classname = "nobody";
      set_suicide_frame ();
   } //end if
}; //end of the function ClientDisconnect

void (entity targ, entity attacker) ClientObituary =
{
   local float rnum;
   local string deathstring;
   local string deathstring2;

   rnum = random ();
   if (((targ.classname == "player") || (targ.classname == "dmbot")))
   {
      if ((attacker.classname == "teledeath"))
      {
         bprint (targ.teamname);
         bprint (targ.netname);
         bprint (" was telefragged by ");
         bprint (attacker.owner.teamname);
         bprint (attacker.owner.netname);
         bprint ("\n");
         if ((attacker.owner.classname == "dmbot"))
         {
            TELEFRAGFLAG = TRUE;
         } //end if
         attacker.owner.frags = (attacker.owner.frags + TRUE);
         countkill (attacker.owner,targ);
         if ((attacker.owner.classname == "dmbot"))
         {
            msgUpdateFragsToAll (attacker.owner.fClientNo,attacker.owner.frags);
         } //end if
         return ;
      } //end if
      if ((attacker.classname == "teledeath2"))
      {
         bprint ("Satan's power deflects ");
         bprint (targ.teamname);
         bprint (targ.netname);
         bprint ("'s telefrag\n");
         countkill (targ,targ);
         targ.frags = (targ.frags - TRUE);
         if ((targ.classname == "dmbot"))
         {
            msgUpdateFragsToAll (targ.fClientNo,targ.frags);
         } //end if
         return ;
      } //end if
      if (((attacker.classname == "player") || (attacker.classname == "dmbot")))
      {
         if ((targ == attacker))
         {
            attacker.frags = (attacker.frags - TRUE);
            if ((attacker.classname == "dmbot"))
            {
               msgUpdateFragsToAll (attacker.fClientNo,attacker.frags);
            } //end if
            countkill (attacker,attacker);
            bprint (targ.teamname);
            bprint (targ.netname);
            if (((targ.weapon == FL_GODMODE) && (targ.waterlevel > TRUE)))
            {
               bprint (" discharges into the water.\n");
               return ;
            } //end if
            if ((targ.weapon == FL_INWATER))
            {
               bprint (" tries to put the pin back in\n");

            } //end if
            else
            {
               if (rnum)
               {
                  bprint (" hates his life\n");

               } //end if
               else
               {
                  bprint (" proves how stupid he is\n");
               } //end if
            } //end if
            return ;

         } //end if
         else
         {
            if ((deathmatch == TE_LIGHTNING1))
            {
               targ.frags = (targ.frags - CARRIED);
               if ((targ.classname == "dmbot"))
               {
                  msgUpdateFragsToAll (targ.fClientNo,targ.frags);
               } //end if

            } //end if
            else
            {
               if ((deathmatch != TE_LIGHTNING1))
               {
                  dprint (ftos (attacker.frags));
                  dprint ("\n");
                  attacker.frags = (attacker.frags + TRUE);
                  if ((attacker.classname == "dmbot"))
                  {
                     msgUpdateFragsToAll (attacker.fClientNo,attacker.frags);
                  } //end if
               } //end if
            } //end if
            countkill (attacker,targ);

            // ===== CHAT HOOK: KILL =====
            // If attacker is a bot (and not suicide), taunt victim (35% chance)
            if ((attacker.classname == "dmbot"))
            {
               local entity oself;

               oself = self;
               self = attacker; // Switch context to bot
               if ((random () < 0.350))
               {
                  BotChat (FL_SWIM,targ); // FL_SWIM = C_KILL = 2
               } //end if
               self = oself; // Restore context
            } //end if
            // ===========================

            rnum = attacker.weapon;
            if ((rnum == IT_AXE))
            {
               deathstring = " was ax-raped by ";
               deathstring2 = "\n";
            } //end if
            if ((rnum == IT_SHOTGUN))
            {
               deathstring = " suckled on ";
               deathstring2 = "'s bigstick\n";
            } //end if
            if ((rnum == IT_SUPER_SHOTGUN))
            {
               deathstring = " swallowed 2 loads of ";
               deathstring2 = "'s lovejuice\n";
            } //end if
            if ((rnum == IT_NAILGUN))
            {
               deathstring = " was pentrated by ";
               deathstring2 = "\n";
            } //end if
            if ((rnum == IT_SUPER_NAILGUN))
            {
               deathstring = " lost his virginity to ";
               deathstring2 = "\n";
            } //end if
            if ((rnum == IT_GRENADE_LAUNCHER))
            {
               deathstring = " eats ";
               deathstring2 = "'s bigboy\n";
               if ((targ.health < -40.000))
               {
                  deathstring = " was analized by ";
                  deathstring2 = "'s funrod\n";
               } //end if
            } //end if
            if ((rnum == IT_ROCKET_LAUNCHER))
            {
               deathstring = " rides ";
               deathstring2 = "'s meatrocket\n";
               if ((targ.health < -40.000))
               {
                  deathstring = " was impregnated by ";
                  deathstring2 = "'s meatrocket\n";
               } //end if
            } //end if
            if ((rnum == IT_LIGHTNING))
            {
               deathstring = " loves ";
               if ((attacker.waterlevel > TRUE))
               {
                  deathstring2 = "'s cums\n";

               } //end if
               else
               {
                  deathstring2 = "'s shaft\n";
               } //end if
            } //end if
            bprint (targ.teamname);
            bprint (targ.netname);
            bprint (deathstring);
            bprint (attacker.teamname);
            bprint (attacker.netname);
            bprint (deathstring2);
         } //end if
         return ;

      } //end if
      else
      {
         targ.frags = (targ.frags - TRUE);
         rnum = targ.watertype;
         countkill (targ,targ);
         if ((targ.classname == "dmbot"))
         {
            msgUpdateFragsToAll (targ.fClientNo,targ.frags);
         } //end if
         bprint (targ.teamname);
         bprint (targ.netname);
         if ((rnum == CONTENT_WATER))
         {
            if ((random () < 0.500))
            {
               bprint (" sleeps with trailer trash\n");

            } //end if
            else
            {
               bprint (" sucks it down\n");
            } //end if
            return ;

         } //end if
         else
         {
            if ((rnum == CONTENT_SLIME))
            {
               if ((random () < 0.500))
               {
                  bprint (" gulped a load of slime\n");

               } //end if
               else
               {
                  bprint (" can't exist on slime alone\n");
               } //end if
               return ;

            } //end if
            else
            {
               if ((rnum == CONTENT_LAVA))
               {
                  if ((targ.health < -15.000))
                  {
                     bprint (" burst into flames\n");
                     return ;
                  } //end if
                  if ((random () < 0.500))
                  {
                     bprint (" turned into hot slag\n");

                  } //end if
                  else
                  {
                     bprint (" visits the Volcano God\n");
                  } //end if
                  return ;
               } //end if
            } //end if
         } //end if
         if ((attacker.flags & FL_MONSTER))
         {
            if ((attacker.classname == "monster_army"))
            {
               bprint (" was shot by a Grunt\n");
            } //end if
            if ((attacker.classname == "monster_demon1"))
            {
               bprint (" was eviscerated by a Fiend\n");
            } //end if
            if ((attacker.classname == "monster_dog"))
            {
               bprint (" was mauled by a Rottweiler\n");
            } //end if
            if ((attacker.classname == "monster_dragon"))
            {
               bprint (" was fried by a Dragon\n");
            } //end if
            if ((attacker.classname == "monster_enforcer"))
            {
               bprint (" was blasted by an Enforcer\n");
            } //end if
            if ((attacker.classname == "monster_fish"))
            {
               bprint (" was fed to the Rotfish\n");
            } //end if
            if ((attacker.classname == "monster_hell_knight"))
            {
               bprint (" was slain by a Death Knight\n");
            } //end if
            if ((attacker.classname == "monster_knight"))
            {
               bprint (" was slashed by a Knight\n");
            } //end if
            if ((attacker.classname == "monster_ogre"))
            {
               bprint (" was destroyed by an Ogre\n");
            } //end if
            if ((attacker.classname == "monster_oldone"))
            {
               bprint (" became one with Shub-Niggurath\n");
            } //end if
            if ((attacker.classname == "monster_shalrath"))
            {
               bprint (" was exploded by a Vore\n");
            } //end if
            if ((attacker.classname == "monster_shambler"))
            {
               bprint (" was smashed by a Shambler\n");
            } //end if
            if ((attacker.classname == "monster_tarbaby"))
            {
               bprint (" was slimed by a Spawn\n");
            } //end if
            if ((attacker.classname == "monster_vomit"))
            {
               bprint (" was vomited on by a Vomitus\n");
            } //end if
            if ((attacker.classname == "monster_wizard"))
            {
               bprint (" was scragged by a Scrag\n");
            } //end if
            if ((attacker.classname == "monster_zombie"))
            {
               bprint (" joins the Zombies\n");
            } //end if
            return ;
         } //end if
         if ((attacker.classname == "explo_box"))
         {
            bprint (" blew up\n");
            return ;
         } //end if
         if (((attacker.solid == SOLID_BSP) && (attacker != world)))
         {
            bprint (" was squished\n");
            return ;
         } //end if
         if ((targ.deathtype == "falling"))
         {
            targ.deathtype = "";
            bprint (" fell to his death\n");
            return ;
         } //end if
         if (((attacker.classname == "trap_shooter") || (attacker.classname == "trap_spikeshooter")))
         {
            bprint (" was spiked\n");
            return ;
         } //end if
         if ((attacker.classname == "fireball"))
         {
            bprint (" ate a lavaball\n");
            return ;
         } //end if
         if ((attacker.classname == "trigger_changelevel"))
         {
            bprint (" tried to leave\n");
            return ;
         } //end if
         bprint (" died\n");
      } //end if
   } //end if
}; //end of the function ClientObituary
