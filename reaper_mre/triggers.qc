entity stemp;
entity otemp;
entity s;
entity old;

void () trigger_reactivate =
{
   self.solid = SOLID_TRIGGER;
}; //end of the function trigger_reactivate
float SPAWNFLAG_NOMESSAGE    = 1.000;
float SPAWNFLAG_NOTOUCH    = 1.000;

void () multi_wait =
{
   if (self.max_health)
   {
      self.health = self.max_health;
      self.takedamage = DAMAGE_YES;
      self.solid = SOLID_BBOX;
   } //end if
}; //end of the function multi_wait

void () multi_trigger =
{
   if ((self.nextthink > time))
   {
      return ;
   } //end if
   if ((self.classname == "trigger_secret"))
   {
      if ((self.enemy.classname != "player"))
      {
         if ((self.enemy.classname != "dmbot"))
         {
            return ;
         } //end if
      } //end if
      found_secrets = (found_secrets + TRUE);
      WriteByte (MSG_ALL,SVC_FOUNDSECRET);
   } //end if
   if (self.noise)
   {
      sound (self,CHAN_VOICE,self.noise,TRUE,ATTN_NORM);
   } //end if
   self.takedamage = DAMAGE_NO;
   activator = self.enemy;
   if ((activator.classname == "dmbot"))
   {
      bot_triggered (activator);
   } //end if
   SUB_UseTargets ();
   if ((self.wait > FALSE))
   {
      self.think = multi_wait;
      self.nextthink = (time + self.wait);

   } //end if
   else
   {
      self.touch = SUB_Null;
      self.nextthink = (time + 0.100);
      self.think = SUB_Remove;
   } //end if
}; //end of the function multi_trigger

void () multi_killed =
{
   self.enemy = damage_attacker;
   multi_trigger ();
}; //end of the function multi_killed

void () multi_use =
{
   self.enemy = activator;
   multi_trigger ();
}; //end of the function multi_use

void () multi_touch =
{
   if ((other.classname != "player"))
   {
      if ((other.classname != "dmbot"))
      {
         return ;
      } //end if
   } //end if
   if ((other.classname == "dmbot"))
   {
      self.enemy = other;
      bot_touched ();
      multi_trigger ();
      return ;
   } //end if
   if ((self.movedir != VEC_ORIGIN))
   {
      makevectors (other.angles);
      if (((v_forward * self.movedir) < FALSE))
      {
         return ;
      } //end if
   } //end if
   self.enemy = other;
   multi_trigger ();
}; //end of the function multi_touch

void () trigger_multiple =
{
   if ((self.sounds == TRUE))
   {
      precache_sound ("misc/secret.wav");
      self.noise = "misc/secret.wav";

   } //end if
   else
   {
      if ((self.sounds == FL_SWIM))
      {
         precache_sound ("misc/talk.wav");
         self.noise = "misc/talk.wav";

      } //end if
      else
      {
         if ((self.sounds == MOVETYPE_WALK))
         {
            precache_sound ("misc/trigger1.wav");
            self.noise = "misc/trigger1.wav";
         } //end if
      } //end if
   } //end if
   if (!self.wait)
   {
      self.wait = 0.200;
   } //end if
   self.use = multi_use;
   self.th_weight = triggerweight;
   self.istrigger = TRUE;
   InitTrigger ();
   if (self.health)
   {
      if ((self.spawnflags & SPAWNFLAG_NOTOUCH))
      {
         objerror ("health and notouch don't make sense\n");
      } //end if
      self.max_health = self.health;
      self.th_die = multi_killed;
      self.takedamage = DAMAGE_YES;
      self.solid = SOLID_BBOX;
      setorigin (self,self.origin);

   } //end if
   else
   {
      if (!(self.spawnflags & SPAWNFLAG_NOTOUCH))
      {
         self.touch = multi_touch;
      } //end if
   } //end if
}; //end of the function trigger_multiple

void () trigger_once =
{
   self.wait = CONTENT_EMPTY;
   trigger_multiple ();
}; //end of the function trigger_once

void () trigger_relay =
{
   self.use = SUB_UseTargets;
}; //end of the function trigger_relay

void () trigger_secret =
{
   total_secrets = (total_secrets + TRUE);
   self.wait = CONTENT_EMPTY;
   if (!self.message)
   {
      self.message = "You found a secret area!";
   } //end if
   if (!self.sounds)
   {
      self.sounds = TRUE;
   } //end if
   if ((self.sounds == TRUE))
   {
      precache_sound ("misc/secret.wav");
      self.noise = "misc/secret.wav";

   } //end if
   else
   {
      if ((self.sounds == FL_SWIM))
      {
         precache_sound ("misc/talk.wav");
         self.noise = "misc/talk.wav";
      } //end if
   } //end if
   trigger_multiple ();
}; //end of the function trigger_secret

void () counter_use =
{
   local string junk;

   self.count = (self.count - TRUE);
   if ((self.count < FALSE))
   {
      return ;
   } //end if
   if ((self.count != FALSE))
   {
      if (((activator.classname == "player") && ((self.spawnflags & SPAWNFLAG_NOMESSAGE) == FALSE)))
      {
         if ((self.count >= MOVETYPE_STEP))
         {
            centerprint (activator,"There are more to go...");

         } //end if
         else
         {
            if ((self.count == MOVETYPE_WALK))
            {
               centerprint (activator,"Only 3 more to go...");

            } //end if
            else
            {
               if ((self.count == FL_SWIM))
               {
                  centerprint (activator,"Only 2 more to go...");

               } //end if
               else
               {
                  centerprint (activator,"Only 1 more to go...");
               } //end if
            } //end if
         } //end if
      } //end if
      return ;
   } //end if
   if (((activator.classname == "player") && ((self.spawnflags & SPAWNFLAG_NOMESSAGE) == FALSE)))
   {
      centerprint (activator,"Sequence completed!");
   } //end if
   self.enemy = activator;
   multi_trigger ();
}; //end of the function counter_use

void () trigger_counter =
{
   self.wait = CONTENT_EMPTY;
   if (!self.count)
   {
      self.count = FL_SWIM;
   } //end if
   self.use = counter_use;
}; //end of the function trigger_counter
float PLAYER_ONLY    = 1.000;
float SILENT    = 2.000;

void () play_teleport =
{
   local float v;
   local string tmpstr;

   v = (random () * MOVETYPE_FLY);
   if ((v < TRUE))
   {
      tmpstr = "misc/r_tele1.wav";

   } //end if
   else
   {
      if ((v < FL_SWIM))
      {
         tmpstr = "misc/r_tele2.wav";

      } //end if
      else
      {
         if ((v < MOVETYPE_WALK))
         {
            tmpstr = "misc/r_tele3.wav";

         } //end if
         else
         {
            if ((v < MOVETYPE_STEP))
            {
               tmpstr = "misc/r_tele4.wav";

            } //end if
            else
            {
               tmpstr = "misc/r_tele5.wav";
            } //end if
         } //end if
      } //end if
   } //end if
   sound (self,CHAN_VOICE,tmpstr,TRUE,ATTN_NORM);
   remove (self);
}; //end of the function play_teleport

void (vector org) spawn_tfog =
{
   s = spawn ();
   s.origin = org;
   s.nextthink = (time + 0.200);
   s.think = play_teleport;
   signalnoise (other,s);
   WriteByte (MSG_BROADCAST,SVC_TEMPENTITY);
   WriteByte (MSG_BROADCAST,TE_TELEPORT);
   WriteCoord (MSG_BROADCAST,org_x);
   WriteCoord (MSG_BROADCAST,org_y);
   WriteCoord (MSG_BROADCAST,org_z);
}; //end of the function spawn_tfog

void () tdeath_touch =
{
   if ((other == self.owner))
   {
      return ;
   } //end if
   if (((other.classname == "player") || (other.classname == "dmbot")))
   {
      if ((other.invincible_finished > time))
      {
         self.classname = "teledeath2";
      } //end if
      if ((self.owner.classname != "player"))
      {
         if ((self.owner.classname != "dmbot"))
         {
            T_Damage (self.owner,self,self,50000.000);
            return ;
         } //end if
      } //end if
   } //end if
   if (other.health)
   {
      T_Damage (other,self,self,50000.000);
   } //end if
}; //end of the function tdeath_touch

void (vector org, entity death_owner) spawn_tdeath =
{
   local entity death;

   death = spawn ();
   death.classname = "teledeath";
   death.movetype = MOVETYPE_NONE;
   death.solid = SOLID_TRIGGER;
   death.angles = VEC_ORIGIN;
   setsize (death,(death_owner.mins - '1.000 1.000 1.000'),(death_owner.maxs + '1.000 1.000 1.000'));
   setorigin (death,org);
   death.touch = tdeath_touch;
   death.nextthink = (time + 0.200);
   death.think = SUB_Remove;
   death.owner = death_owner;
   force_retouch = FL_SWIM;
}; //end of the function spawn_tdeath

void () teleport_touch =
{
   local entity t;
   local vector org;

   if (self.targetname)
   {
      if ((self.nextthink < time))
      {
         return ;
      } //end if
   } //end if
   if ((self.spawnflags & PLAYER_ONLY))
   {
      if ((other.classname != "player"))
      {
         if ((other.classname != "dmbot"))
         {
            return ;
         } //end if
      } //end if
   } //end if
   if (((other.health <= FALSE) || (other.solid != SOLID_SLIDEBOX)))
   {
      return ;
   } //end if
   SUB_UseTargets ();
   spawn_tfog (other.origin);
   t = find (world,targetname,self.target);
   if (!t)
   {
      objerror ("couldn't find target");
   } //end if
   makevectors (t.mangle);
   org = (t.origin + (FL_MONSTER * v_forward));
   spawn_tfog (org);
   spawn_tdeath (t.origin,other);
   if ((other.enemy.classname == "dmbot"))
   {
      enemy_touched ();
   } //end if
   if (!other.health)
   {
      other.origin = t.origin;
      other.velocity = ((v_forward * other.velocity_x) + (v_forward * other.velocity_y));
      return ;
   } //end if
   setorigin (other,t.origin);
   other.angles = t.mangle;
   if (other.movetarget.movetarget)
   {
      addTarget (other.movetarget.movetarget,self);
      other.movetarget.movetarget = self;
   } //end if
   if ((other.classname == "dmbot"))
   {
      bot_touched ();
   } //end if
   if (((other.classname == "player") || (other.classname == "dmbot")))
   {
      other.fixangle = TRUE;
      other.teleport_time = (time + 0.700);
      if ((other.flags & FL_ONGROUND))
      {
         other.flags = (other.flags - FL_ONGROUND);
      } //end if
      other.velocity = (v_forward * 300.000);
   } //end if
   other.flags = (other.flags - (other.flags & FL_ONGROUND));
}; //end of the function teleport_touch

void () info_teleport_destination =
{
   self.mangle = self.angles;
   self.angles = VEC_ORIGIN;
   self.model = "";
   self.origin = (self.origin + '0.000 0.000 27.000');
   if (!self.targetname)
   {
      objerror ("no targetname");
   } //end if
}; //end of the function info_teleport_destination

void () teleport_use =
{
   self.nextthink = (time + 0.200);
   force_retouch = FL_SWIM;
   self.think = SUB_Null;
}; //end of the function teleport_use

void () trigger_teleport =
{
   local vector o;

   InitTrigger ();
   self.touch = teleport_touch;
   self.istrigger = TRUE;
   self.pathtype = TELEPORT;
   if (!self.target)
   {
      objerror ("no target");
   } //end if
   self.use = teleport_use;
   if (!(self.spawnflags & SILENT))
   {
      precache_sound ("ambience/hum1.wav");
      o = ((self.mins + self.maxs) * 0.500);
      ambientsound (o,"ambience/hum1.wav",0.500,ATTN_STATIC);
   } //end if
}; //end of the function trigger_teleport

void () trigger_skill_touch =
{
   return ;
   cvar_set ("skill",self.message);
}; //end of the function trigger_skill_touch

void () trigger_setskill =
{
   InitTrigger ();
   self.touch = trigger_skill_touch;
   self.istrigger = TRUE;
   self.pathtype = TELEPORT;
}; //end of the function trigger_setskill

void () trigger_onlyregistered_touch =
{
   if ((other.classname != "player"))
   {
      if ((other.classname != "dmbot"))
      {
         return ;
      } //end if
   } //end if
   if ((self.attack_finished > time))
   {
      return ;
   } //end if
   self.attack_finished = (time + FL_SWIM);
   if (cvar ("registered"))
   {
      self.message = "";
      SUB_UseTargets ();
      remove (self);

   } //end if
   else
   {
      if ((other.classname != "dmbot"))
      {
         if ((self.message != ""))
         {
            centerprint (other,self.message);
            sound (other,CHAN_BODY,"misc/talk.wav",TRUE,ATTN_NORM);
         } //end if
      } //end if
   } //end if
}; //end of the function trigger_onlyregistered_touch

void () trigger_onlyregistered =
{
   precache_sound ("misc/talk.wav");
   InitTrigger ();
   self.touch = trigger_onlyregistered_touch;
   self.istrigger = TRUE;
   self.th_weight = triggerweight;
}; //end of the function trigger_onlyregistered

void () hurt_on =
{
   self.solid = SOLID_TRIGGER;
   self.nextthink = CONTENT_EMPTY;
}; //end of the function hurt_on

void () hurt_touch =
{
   if (other.takedamage)
   {
      self.solid = SOLID_NOT;
      T_Damage (other,self,self,self.dmg);
      self.think = hurt_on;
      self.nextthink = (time + TRUE);
   } //end if
   return ;
}; //end of the function hurt_touch

void () trigger_hurt =
{
   InitTrigger ();
   self.touch = hurt_touch;
   if (!self.dmg)
   {
      self.dmg = MOVETYPE_FLY;
   } //end if
}; //end of the function trigger_hurt
float PUSH_ONCE    = 1.000;

void () trigger_push_touch =
{
   if ((other.classname == "grenade"))
   {
      other.velocity = ((self.speed * self.movedir) * MOVETYPE_BOUNCE);

   } //end if
   else
   {
      if ((other.health > FALSE))
      {
         other.velocity = ((self.speed * self.movedir) * MOVETYPE_BOUNCE);
         if ((other.classname == "player"))
         {
            if ((other.fly_sound < time))
            {
               other.fly_sound = (time + 1.500);
               sound (other,CHAN_AUTO,"ambience/windfly.wav",TRUE,ATTN_NORM);
            } //end if

         } //end if
         else
         {
            if ((other.classname == "dmbot"))
            {
               if (((self.movedir_x < 0.100) && (self.movedir_y < 0.100)))
               {
                  other.velocity_x = ((other.velocity_x + (80.000 * random ())) - 40.000);
                  other.velocity_y = ((other.velocity_y + (80.000 * random ())) - 40.000);
               } //end if
               if ((other.fly_sound < time))
               {
                  other.fly_sound = (time + 1.500);
                  sound (other,CHAN_AUTO,"ambience/windfly.wav",TRUE,ATTN_NORM);
               } //end if
            } //end if
         } //end if
         if ((other.enemy.classname == "dmbot"))
         {
            enemy_touched ();
         } //end if
      } //end if
   } //end if
   if ((self.spawnflags & PUSH_ONCE))
   {
      remove (self);
   } //end if
}; //end of the function trigger_push_touch

void () trigger_push =
{
   InitTrigger ();
   precache_sound ("ambience/windfly.wav");
   self.touch = trigger_push_touch;
   self.istrigger = TRUE;
   self.th_weight = trigpushweight;
   if (!self.speed)
   {
      self.speed = 1000.000;
   } //end if
}; //end of the function trigger_push

void () trigger_monsterjump_touch =
{
   if (((other.flags & ((FL_MONSTER | FL_FLY) | FL_SWIM)) != FL_MONSTER))
   {
      return ;
   } //end if
   other.velocity_x = (self.movedir_x * self.speed);
   other.velocity_y = (self.movedir_y * self.speed);
   if (!(other.flags & FL_ONGROUND))
   {
      return ;
   } //end if
   other.flags = (other.flags - FL_ONGROUND);
   other.velocity_z = self.height;
}; //end of the function trigger_monsterjump_touch

void () trigger_monsterjump =
{
   if (!self.speed)
   {
      self.speed = 200.000;
   } //end if
   if (!self.height)
   {
      self.height = 200.000;
   } //end if
   if ((self.angles == VEC_ORIGIN))
   {
      self.angles = '0.000 360.000 0.000';
   } //end if
   InitTrigger ();
   self.touch = trigger_monsterjump_touch;
}; //end of the function trigger_monsterjump
