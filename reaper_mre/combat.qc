
void () T_MissileTouch;

void () info_player_start;

void (entity targ, entity attacker) ClientObituary;

void () monster_death_use;
// Forward declaration for live learning RJ waypoints (defined in botroute.qc)
void (vector org, vector angles, float velocity_gain, string rj_type_str) SpawnLearnedRJ_Live;
float (entity targ, entity inflictor) CanDamage =
{
   if ((targ.movetype == MOVETYPE_PUSH))
   {
      traceline (inflictor.origin,(0.500 * (targ.absmin + targ.absmax)),TRUE,self);
      if ((trace_fraction == TRUE))
      {
         return (TRUE);
      } //end if
      if ((trace_ent == targ))
      {
         return (TRUE);
      } //end if
      return (FALSE);
   } //end if
   traceline (inflictor.origin,targ.origin,TRUE,self);
   if ((trace_fraction == TRUE))
   {
      return (TRUE);
   } //end if
   traceline (inflictor.origin,(targ.origin + '15.000 15.000 0.000'),TRUE,self);
   if ((trace_fraction == TRUE))
   {
      return (TRUE);
   } //end if
   traceline (inflictor.origin,(targ.origin + '-15.000 -15.000 0.000'),TRUE,self);
   if ((trace_fraction == TRUE))
   {
      return (TRUE);
   } //end if
   traceline (inflictor.origin,(targ.origin + '-15.000 15.000 0.000'),TRUE,self);
   if ((trace_fraction == TRUE))
   {
      return (TRUE);
   } //end if
   traceline (inflictor.origin,(targ.origin + '15.000 -15.000 0.000'),TRUE,self);
   if ((trace_fraction == TRUE))
   {
      return (TRUE);
   } //end if
   return (FALSE);
}; //end of the function CanDamage

void (entity targ, entity attacker) Killed =
{
   local entity oself;

   oself = self;
   self = targ;
   if ((self.health < -99.000))
   {
      self.health = -99.000;
   } //end if
   if (((self.movetype == MOVETYPE_PUSH) || (self.movetype == MOVETYPE_NONE)))
   {
      self.th_die ();
      self = oself;
      return ;
   } //end if
   self.enemy = attacker;
   if ((self.flags & FL_MONSTER))
   {
      killed_monsters = (killed_monsters + TRUE);
      WriteByte (MSG_ALL,SVC_KILLEDMONSTER);
   } //end if
   ClientObituary (self,attacker);
   self.takedamage = DAMAGE_NO;
   self.touch = SUB_Null;
   monster_death_use ();

   // ===== DANGER & GLORY: Semantic Map Learning =====
   // 1. MARK DANGER (Victim died here)
   if ((self.isbot))
   {
      local entity d_node;
      d_node = findradius (self.origin,200.000);

      while (d_node)
      {
         if ((d_node.classname == "BotPath"))
         {
            // Stain this node with death!
            d_node.danger_scent = (d_node.danger_scent + 10.000);
            d_node.scent_time = time;

            // Bot chat: "This place is cursed!"
            if (((d_node.danger_scent > 30.000) && (random () < 0.200)))
            {
               bprint (self.netname);
               bprint (": Stay away from the ");
               bprint (d_node.classname);
               bprint ("!\n");
            } //end if

            d_node = world;
         } //end if
         else
         {
            d_node = d_node.chain;
         } //end if
      } //end while
   } //end if

   // 2. MARK GLORY (Attacker got a kill here)
   if ((((attacker.isbot) && (attacker != world)) && (attacker != self)))
   {
      local entity g_node;
      g_node = findradius (attacker.origin,150.000);

      while (g_node)
      {
         if ((g_node.classname == "BotPath"))
         {
            // Mark this as a Sniper Spot!
            g_node.glory_score = (g_node.glory_score + 10.000);
            g_node.scent_time = time;
            g_node = world;
         } //end if
         else
         {
            g_node = g_node.chain;
         } //end if
      } //end while
   } //end if
   // ===============================================

   self.th_die ();
   self = oself;
}; //end of the function Killed

void (entity targ, entity inflictor, entity attacker, float damage) T_Damage =
{
   local vector dir;
   local entity oldself;
   local float save;
   local float take;

   if (!targ.takedamage)
   {
      return ;
   } //end if
   damage_attacker = attacker;
   if ((attacker.super_damage_finished > time))
   {
      damage = (damage * MOVETYPE_STEP);
   } //end if
   save = ceil ((targ.armortype * damage));
   if ((save >= targ.armorvalue))
   {
      save = targ.armorvalue;
      targ.armortype = FALSE;
      targ.items = (targ.items - (targ.items & ((IT_ARMOR1 | IT_ARMOR2) | IT_ARMOR3)));
   } //end if
   targ.armorvalue = (targ.armorvalue - save);
   take = ceil ((damage - save));

   // ===== PLAYER OBSERVATION: Rocket Jump Detection =====
   // Learn RJ techniques when player has enabled observation mode (impulse 199)
   if ((((targ.classname == "player") && targ.observer_mode) && (attacker == targ)))
   {
      // Check for rocket/grenade (MOVETYPE_FLYMISSILE or MOVETYPE_BOUNCE)
      if (((inflictor != world) && ((inflictor.movetype == MOVETYPE_FLYMISSILE) || (inflictor.movetype == MOVETYPE_BOUNCE))))
      {
         // ===== VALIDATE FIRST - Avoid spam from combat splash =====
         local float upward_velocity;
         local float pitch;
         local float is_valid_rj;
         local entity nearby_rj;
         local float has_duplicate;

         // Validation 1: Check upward velocity (meaningful vertical boost)
         // Threshold: 150 u/s catches shallow-angle RJs (efficient technique) while filtering combat splash
         upward_velocity = targ.velocity_z;  // Z component is vertical in Quake
         is_valid_rj = FALSE;

         if (upward_velocity > 150.000)
         {
            // Validation 2: Check pitch angle (proper RJ technique)
            pitch = targ.angles_x;
            if ((pitch >= -90.000) && (pitch <= -20.000))
            {
               // Validation 3: Check for duplicates (don't spawn if one exists nearby)
               has_duplicate = FALSE;
               nearby_rj = findradius(targ.origin, 128.000);
               while (nearby_rj)
               {
                  if ((nearby_rj.classname == "BotPath") && nearby_rj.rj_learned)
                  {
                     has_duplicate = TRUE;
                     nearby_rj = world;  // Break loop
                  }
                  else
                  {
                     nearby_rj = nearby_rj.chain;
                  }
               } //end while

               if (!has_duplicate)
               {
                  // ===== VALID RJ - Log for offline parser (Phase 1) =====
                  bprint ("PLAYER_RJ_DAMAGE: ");
                  bprint (vtos (targ.origin));
                  bprint (" | dmg=");
                  bprint (ftos (take));
                  bprint (" | vel=");
                  bprint (vtos (targ.velocity));
                  bprint (" | ang=");
                  bprint (vtos (targ.angles));
                  bprint (" | time=");
                  bprint (ftos (time));
                  bprint ("\n");

                  // ===== LIVE LEARNING - Spawn waypoint (Phase 2) =====
                  SpawnLearnedRJ_Live(targ.origin, targ.angles, upward_velocity, "rj_vertical");

                  // Console feedback
                  bprint("Live Learning: Bots learned rocket jump from ");
                  bprint(targ.netname);
                  bprint(" (pitch=");
                  bprint(ftos(pitch));
                  bprint("°, vel=");
                  bprint(ftos(upward_velocity));
                  bprint(" u/s, total=");
                  bprint(ftos(learned_rj_count));
                  bprint("/");
                  bprint(ftos(LEARNED_RJ_MAX));
                  bprint(")\n");

                  is_valid_rj = TRUE;
               } //end if
            } //end if
         } //end if
         // ===========================================================
      } //end if
   } //end if
   // ==================================================

   if ((targ.flags & FL_CLIENT))
   {
      targ.dmg_take = (targ.dmg_take + take);
      targ.dmg_save = (targ.dmg_save + save);
      targ.dmg_inflictor = inflictor;
   } //end if
   if (((inflictor != world) && (targ.movetype == MOVETYPE_WALK)))
   {
      dir = (targ.origin - ((inflictor.absmin + inflictor.absmax) * 0.500));
      dir = normalize (dir);
      targ.velocity = (targ.velocity + ((dir * damage) * EF_DIMLIGHT));
   } //end if
   if ((((inflictor != world) && (targ.movetype == MOVETYPE_STEP)) && (targ.isbot)))
   {
      dir = (targ.origin - ((inflictor.absmin + inflictor.absmax) * 0.500));
      dir = normalize (dir);
      targ.flags = (targ.flags - (targ.flags & FL_ONGROUND));
      targ.velocity = (targ.velocity + ((dir * damage) * EF_DIMLIGHT));
   } //end if
   if ((targ.flags & FL_GODMODE))
   {
      return ;
   } //end if
   if ((targ.invincible_finished >= time))
   {
      if ((self.invincible_sound < time))
      {
         sound (targ,CHAN_ITEM,"items/protect3.wav",TRUE,ATTN_NORM);
         self.invincible_sound = (time + FL_SWIM);
      } //end if
      return ;
   } //end if
   if ((((teamplay == TRUE) && (targ.team > FALSE)) && (targ.team == attacker.team)))
   {
      return ;
   } //end if
   targ.health = (targ.health - take);
   if ((targ.health <= FALSE))
   {
      Killed (targ,attacker);
      return ;
   } //end if
   oldself = self;
   self = targ;
   if ((self.isbot))
   {
      if ((attacker != world))
      {
         if ((inflictor != world))
         {
            if (((attacker != self) && !coop))
            {
               if (self.enemy)
               {
                  secondEnemy (attacker);

               } //end if
               else
               {
                  self.enemy = attacker;
                  BotFoundTarget ();
               } //end if
            } //end if
         } //end if
      } //end if

   } //end if
   else
   {
      if (((self.flags & FL_MONSTER) && (attacker != world)))
      {
         if (((self != attacker) && (attacker != self.enemy)))
         {
            if (((self.classname != attacker.classname) || (self.classname == "monster_army")))
            {
               if ((self.enemy.classname == "player"))
               {
                  self.oldenemy = self.enemy;
               } //end if
               self.enemy = attacker;
               FoundTarget ();
            } //end if
         } //end if
      } //end if
   } //end if
   if (self.th_pain)
   {
      self.th_pain (attacker,take);
      if ((skill == MOVETYPE_WALK))
      {
         self.pain_finished = (time + MOVETYPE_FLY);
      } //end if
   } //end if
   self = oldself;
}; //end of the function T_Damage

void (entity inflictor, entity attacker, float damage, entity ignore) T_RadiusDamage =
{
   local float points;
   local entity head;
   local vector org;

   head = findradius (inflictor.origin,(damage + 40.000));
   while (head)
   {
      if ((head != ignore))
      {
         if (head.takedamage)
         {
            org = (head.origin + ((head.mins + head.maxs) * 0.500));
            points = (0.500 * vlen ((inflictor.origin - org)));
            if ((points < FALSE))
            {
               points = FALSE;
            } //end if
            points = (damage - points);
            if ((head == attacker))
            {
               points = (points * 0.500);
            } //end if
            if ((points > FALSE))
            {
               if (CanDamage (head,inflictor))
               {
                  if ((head.classname == "monster_shambler"))
                  {
                     T_Damage (head,inflictor,attacker,(points * 0.500));

                  } //end if
                  else
                  {
                     T_Damage (head,inflictor,attacker,points);
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
      head = head.chain;
   } //end while
}; //end of the function T_RadiusDamage

void (entity attacker, float damage) T_BeamDamage =
{
   local float points;
   local entity head;

   head = findradius (attacker.origin,(damage + 40.000));
   while (head)
   {
      if (head.takedamage)
      {
         points = (0.500 * vlen ((attacker.origin - head.origin)));
         if ((points < FALSE))
         {
            points = FALSE;
         } //end if
         points = (damage - points);
         if ((head == attacker))
         {
            points = (points * 0.500);
         } //end if
         if ((points > FALSE))
         {
            if (CanDamage (head,attacker))
            {
               if ((head.classname == "monster_shambler"))
               {
                  T_Damage (head,attacker,attacker,(points * 0.500));

               } //end if
               else
               {
                  T_Damage (head,attacker,attacker,points);
               } //end if
            } //end if
         } //end if
      } //end if
      head = head.chain;
   } //end while
}; //end of the function T_BeamDamage
