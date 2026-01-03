
void () T_MissileTouch;

void () info_player_start;

void (entity targ, entity attacker) ClientObituary;

void () monster_death_use;
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
   if ((((inflictor != world) && (targ.movetype == MOVETYPE_STEP)) && (targ.classname == "dmbot")))
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
   if ((self.classname == "dmbot"))
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
