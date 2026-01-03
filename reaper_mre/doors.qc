float DOOR_START_OPEN    = 1.000;
float DOOR_DONT_LINK    = 4.000;
float DOOR_GOLD_KEY    = 8.000;
float DOOR_SILVER_KEY    = 16.000;
float DOOR_TOGGLE    = 32.000;

void () door_go_down;

void () door_go_up;

void () door_blocked =
{
   T_Damage (other,self,self,self.dmg);
   if ((self.wait >= FALSE))
   {
      if ((self.state == STATE_DOWN))
      {
         door_go_up ();

      } //end if
      else
      {
         door_go_down ();
      } //end if
   } //end if
}; //end of the function door_blocked

void () door_hit_top =
{
   sound (self,CHAN_VOICE,self.noise1,TRUE,ATTN_NORM);
   self.state = STATE_TOP;
   if ((self.spawnflags & DOOR_TOGGLE))
   {
      return ;
   } //end if
   self.think = door_go_down;
   self.nextthink = (self.ltime + self.wait);
}; //end of the function door_hit_top

void () door_hit_bottom =
{
   sound (self,CHAN_VOICE,self.noise1,TRUE,ATTN_NORM);
   self.state = STATE_BOTTOM;
}; //end of the function door_hit_bottom

void () door_go_down =
{
   sound (self,CHAN_VOICE,self.noise2,TRUE,ATTN_NORM);
   if (self.max_health)
   {
      self.takedamage = DAMAGE_YES;
      self.health = self.max_health;
   } //end if
   self.state = STATE_DOWN;
   SUB_CalcMove (self.pos1,self.speed,door_hit_bottom);
}; //end of the function door_go_down

void () door_go_up =
{
   if ((self.state == STATE_UP))
   {
      return ;
   } //end if
   if ((self.state == STATE_TOP))
   {
      self.nextthink = (self.ltime + self.wait);
      return ;
   } //end if
   sound (self,CHAN_VOICE,self.noise2,TRUE,ATTN_NORM);
   self.state = STATE_UP;
   SUB_CalcMove (self.pos2,self.speed,door_hit_top);
   SUB_UseTargets ();
}; //end of the function door_go_up

void () door_fire =
{
   local entity oself;
   local entity starte;

   if ((self.owner != self))
   {
      objerror ("door_fire: self.owner != self");
   } //end if
   if (self.items)
   {
      sound (self,CHAN_VOICE,self.noise4,TRUE,ATTN_NORM);
   } //end if
   self.message = string_null;
   oself = self;
   if ((self.spawnflags & DOOR_TOGGLE))
   {
      if (((self.state == STATE_UP) || (self.state == STATE_TOP)))
      {
         starte = self;
         do
         {
            door_go_down ();
            self = self.enemy;
         } while (((self != starte) && (self != world)));
         self = oself;
         return ;
      } //end if
   } //end if
   starte = self;
   do
   {
      door_go_up ();
      self = self.enemy;
   } while (((self != starte) && (self != world)));
   self = oself;
}; //end of the function door_fire

void () door_use =
{
   local entity oself;

   signalnoise (other,self);
   if ((other.classname == "dmbot"))
   {
      bot_touched ();
   } //end if
   self.message = "";
   self.owner.message = "";
   self.enemy.message = "";
   oself = self;
   self = self.owner;
   door_fire ();
   self = oself;
}; //end of the function door_use

void () door_trigger_touch =
{
   if ((other.health <= FALSE))
   {
      return ;
   } //end if
   if ((time < self.attack_finished))
   {
      return ;
   } //end if
   self.attack_finished = (time + TRUE);
   activator = other;
   self = self.owner;
   door_use ();
}; //end of the function door_trigger_touch

void () door_killed =
{
   local entity oself;

   oself = self;
   self = self.owner;
   self.health = self.max_health;
   self.takedamage = DAMAGE_NO;
   door_use ();
   self = oself;
}; //end of the function door_killed

void () door_touch =
{
   local vector org;

   if (((other.classname != "player") && (other.classname != "dmbot")))
   {
      return ;
   } //end if
   if ((self.owner.attack_finished > time))
   {
      return ;
   } //end if
   self.owner.attack_finished = (time + FL_SWIM);
   if ((self.owner.message != ""))
   {
      if ((other.classname == "player"))
      {
         centerprint (other,self.owner.message);
      } //end if
      sound (other,CHAN_VOICE,"misc/talk.wav",TRUE,ATTN_NORM);
   } //end if
   if ((other.enemy.classname == "dmbot"))
   {
      enemy_touched ();
   } //end if
   if ((other.classname == "dmbot"))
   {
      bot_touched ();
   } //end if
   if (!self.items)
   {
      return ;
   } //end if
   if (((self.items & other.items) != self.items))
   {
      if ((self.owner.items == IT_KEY1))
      {
         if ((world.worldtype == FL_SWIM))
         {
            centerprint (other,"You need the silver keycard");
            sound (self,CHAN_VOICE,self.noise3,TRUE,ATTN_NORM);

         } //end if
         else
         {
            if ((world.worldtype == TRUE))
            {
               centerprint (other,"You need the silver runekey");
               sound (self,CHAN_VOICE,self.noise3,TRUE,ATTN_NORM);

            } //end if
            else
            {
               if ((world.worldtype == FALSE))
               {
                  centerprint (other,"You need the silver key");
                  sound (self,CHAN_VOICE,self.noise3,TRUE,ATTN_NORM);
               } //end if
            } //end if
         } //end if

      } //end if
      else
      {
         if ((world.worldtype == FL_SWIM))
         {
            centerprint (other,"You need the gold keycard");
            sound (self,CHAN_VOICE,self.noise3,TRUE,ATTN_NORM);

         } //end if
         else
         {
            if ((world.worldtype == TRUE))
            {
               centerprint (other,"You need the gold runekey");
               sound (self,CHAN_VOICE,self.noise3,TRUE,ATTN_NORM);

            } //end if
            else
            {
               if ((world.worldtype == FALSE))
               {
                  centerprint (other,"You need the gold key");
                  sound (self,CHAN_VOICE,self.noise3,TRUE,ATTN_NORM);
               } //end if
            } //end if
         } //end if
      } //end if
      return ;
   } //end if
   other.items = (other.items - self.items);
   self.touch = SUB_Null;
   if (self.enemy)
   {
      self.enemy.touch = SUB_Null;
   } //end if
   door_use ();
}; //end of the function door_touch
entity (vector fmins, vector fmaxs) spawn_field =
{
   local entity trigger;
   local vector t1;
   local vector t2;

   trigger = spawn ();
   trigger.movetype = MOVETYPE_NONE;
   trigger.solid = SOLID_TRIGGER;
   trigger.owner = self;
   trigger.touch = door_trigger_touch;
   t1 = fmins;
   t2 = fmaxs;
   setsize (trigger,(t1 - '60.000 60.000 8.000'),(t2 + '60.000 60.000 8.000'));
   return (trigger);
}; //end of the function spawn_field
float (entity e1, entity e2) EntitiesTouching =
{
   if ((e1.mins_x > e2.maxs_x))
   {
      return (FALSE);
   } //end if
   if ((e1.mins_y > e2.maxs_y))
   {
      return (FALSE);
   } //end if
   if ((e1.mins_z > e2.maxs_z))
   {
      return (FALSE);
   } //end if
   if ((e1.maxs_x < e2.mins_x))
   {
      return (FALSE);
   } //end if
   if ((e1.maxs_y < e2.mins_y))
   {
      return (FALSE);
   } //end if
   if ((e1.maxs_z < e2.mins_z))
   {
      return (FALSE);
   } //end if
   return (TRUE);
}; //end of the function EntitiesTouching

void () LinkDoors =
{
   local entity t;
   local entity starte;
   local vector cmins;
   local vector cmaxs;

   if (self.enemy)
   {
      return ;
   } //end if
   if ((self.spawnflags & MOVETYPE_STEP))
   {
      self.enemy = self;
      self.owner = self;
      return ;
   } //end if
   cmins = self.mins;
   cmaxs = self.maxs;
   starte = self;
   t = self;
   do
   {
      self.owner = starte;
      if (self.health)
      {
         starte.health = self.health;
      } //end if
      if (self.targetname)
      {
         starte.targetname = self.targetname;
      } //end if
      if ((self.message != ""))
      {
         starte.message = self.message;
      } //end if
      t = find (t,classname,self.classname);
      if (!t)
      {
         self.enemy = starte;
         self = self.owner;
         if (self.health)
         {
            return ;
         } //end if
         if (self.targetname)
         {
            return ;
         } //end if
         if (self.items)
         {
            return ;
         } //end if
         self.owner.trigger_field = spawn_field (cmins,cmaxs);
         return ;
      } //end if
      if (EntitiesTouching (self,t))
      {
         if (t.enemy)
         {
            objerror ("cross connected doors");
         } //end if
         self.enemy = t;
         self = t;
         if ((t.mins_x < cmins_x))
         {
            cmins_x = t.mins_x;
         } //end if
         if ((t.mins_y < cmins_y))
         {
            cmins_y = t.mins_y;
         } //end if
         if ((t.mins_z < cmins_z))
         {
            cmins_z = t.mins_z;
         } //end if
         if ((t.maxs_x > cmaxs_x))
         {
            cmaxs_x = t.maxs_x;
         } //end if
         if ((t.maxs_y > cmaxs_y))
         {
            cmaxs_y = t.maxs_y;
         } //end if
         if ((t.maxs_z > cmaxs_z))
         {
            cmaxs_z = t.maxs_z;
         } //end if
      } //end if
   } while (TRUE);
}; //end of the function LinkDoors

void () func_door =
{
   if ((world.worldtype == FALSE))
   {
      precache_sound ("doors/medtry.wav");
      precache_sound ("doors/meduse.wav");
      self.noise3 = "doors/medtry.wav";
      self.noise4 = "doors/meduse.wav";

   } //end if
   else
   {
      if ((world.worldtype == TRUE))
      {
         precache_sound ("doors/runetry.wav");
         precache_sound ("doors/runeuse.wav");
         self.noise3 = "doors/runetry.wav";
         self.noise4 = "doors/runeuse.wav";

      } //end if
      else
      {
         if ((world.worldtype == FL_SWIM))
         {
            precache_sound ("doors/basetry.wav");
            precache_sound ("doors/baseuse.wav");
            self.noise3 = "doors/basetry.wav";
            self.noise4 = "doors/baseuse.wav";

         } //end if
         else
         {
            dprint ("no worldtype set!\n");
         } //end if
      } //end if
   } //end if
   if ((self.sounds == FALSE))
   {
      precache_sound ("misc/null.wav");
      precache_sound ("misc/null.wav");
      self.noise1 = "misc/null.wav";
      self.noise2 = "misc/null.wav";
   } //end if
   if ((self.sounds == TRUE))
   {
      precache_sound ("doors/drclos4.wav");
      precache_sound ("doors/doormv1.wav");
      self.noise1 = "doors/drclos4.wav";
      self.noise2 = "doors/doormv1.wav";
   } //end if
   if ((self.sounds == FL_SWIM))
   {
      precache_sound ("doors/hydro1.wav");
      precache_sound ("doors/hydro2.wav");
      self.noise2 = "doors/hydro1.wav";
      self.noise1 = "doors/hydro2.wav";
   } //end if
   if ((self.sounds == MOVETYPE_WALK))
   {
      precache_sound ("doors/stndr1.wav");
      precache_sound ("doors/stndr2.wav");
      self.noise2 = "doors/stndr1.wav";
      self.noise1 = "doors/stndr2.wav";
   } //end if
   if ((self.sounds == MOVETYPE_STEP))
   {
      precache_sound ("doors/ddoor1.wav");
      precache_sound ("doors/ddoor2.wav");
      self.noise1 = "doors/ddoor2.wav";
      self.noise2 = "doors/ddoor1.wav";
   } //end if
   SetMovedir ();
   self.max_health = self.health;
   self.solid = SOLID_BSP;
   self.movetype = MOVETYPE_PUSH;
   setorigin (self,self.origin);
   setmodel (self,self.model);
   self.classname = "door";
   self.blocked = door_blocked;
   self.use = door_use;
   if ((self.spawnflags & DOOR_SILVER_KEY))
   {
      self.items = IT_KEY1;
   } //end if
   if ((self.spawnflags & DOOR_GOLD_KEY))
   {
      self.items = IT_KEY2;
   } //end if
   if (!self.speed)
   {
      self.speed = MUST_HAVE;
   } //end if
   if (!self.wait)
   {
      self.wait = MOVETYPE_WALK;
   } //end if
   if (!self.lip)
   {
      self.lip = FL_CLIENT;
   } //end if
   if (!self.dmg)
   {
      self.dmg = FL_SWIM;
   } //end if
   self.pos1 = self.origin;
   self.pos2 = (self.pos1 + (self.movedir * (fabs ((self.movedir * self.size)) - self.lip)));
   if ((self.spawnflags & DOOR_START_OPEN))
   {
      setorigin (self,self.pos2);
      self.pos2 = self.pos1;
      self.pos1 = self.origin;
   } //end if
   self.state = STATE_BOTTOM;
   if (self.health)
   {
      self.takedamage = DAMAGE_YES;
      self.th_die = door_killed;
   } //end if
   if (self.items)
   {
      self.wait = CONTENT_EMPTY;
   } //end if
   self.touch = door_touch;
   self.th_weight = doorweight;
   self.think = LinkDoors;
   self.nextthink = (self.ltime + 0.100);
}; //end of the function func_door

void () fd_secret_move1;

void () fd_secret_move2;

void () fd_secret_move3;

void () fd_secret_move4;

void () fd_secret_move5;

void () fd_secret_move6;

void () fd_secret_done;
float SECRET_OPEN_ONCE    = 1.000;
float SECRET_1ST_LEFT    = 2.000;
float SECRET_1ST_DOWN    = 4.000;
float SECRET_NO_SHOOT    = 8.000;
float SECRET_YES_SHOOT    = 16.000;

void () fd_secret_use =
{
   local float temp;

   self.health = 10000.000;
   if ((self.origin != self.oldorigin))
   {
      return ;
   } //end if
   self.message = string_null;
   SUB_UseTargets ();
   if (!(self.spawnflags & SECRET_NO_SHOOT))
   {
      self.th_pain = SUB_Null;
      self.takedamage = DAMAGE_NO;
   } //end if
   self.velocity = VEC_ORIGIN;
   sound (self,CHAN_VOICE,self.noise1,TRUE,ATTN_NORM);
   self.nextthink = (self.ltime + 0.100);
   temp = (TRUE - (self.spawnflags & SECRET_1ST_LEFT));
   makevectors (self.mangle);
   if (!self.t_width)
   {
      if ((self.spawnflags & SECRET_1ST_DOWN))
      {
         self.t_width = fabs ((v_up * self.size));

      } //end if
      else
      {
         self.t_width = fabs ((v_right * self.size));
      } //end if
   } //end if
   if (!self.t_length)
   {
      self.t_length = fabs ((v_forward * self.size));
   } //end if
   if ((self.spawnflags & SECRET_1ST_DOWN))
   {
      self.dest1 = (self.origin - (v_up * self.t_width));

   } //end if
   else
   {
      self.dest1 = (self.origin + (v_right * (self.t_width * temp)));
   } //end if
   self.dest2 = (self.dest1 + (v_forward * self.t_length));
   SUB_CalcMove (self.dest1,self.speed,fd_secret_move1);
   sound (self,CHAN_VOICE,self.noise2,TRUE,ATTN_NORM);
}; //end of the function fd_secret_use

void () fd_secret_move1 =
{
   self.nextthink = (self.ltime + TRUE);
   self.think = fd_secret_move2;
   sound (self,CHAN_VOICE,self.noise3,TRUE,ATTN_NORM);
}; //end of the function fd_secret_move1

void () fd_secret_move2 =
{
   sound (self,CHAN_VOICE,self.noise2,TRUE,ATTN_NORM);
   SUB_CalcMove (self.dest2,self.speed,fd_secret_move3);
}; //end of the function fd_secret_move2

void () fd_secret_move3 =
{
   sound (self,CHAN_VOICE,self.noise3,TRUE,ATTN_NORM);
   if ((self.lastbot.goalentity.goalentity == self))
   {
      self.lastbot.search_time = time;
   } //end if
   if (!(self.spawnflags & SECRET_OPEN_ONCE))
   {
      self.nextthink = (self.ltime + self.wait);
      self.think = fd_secret_move4;
   } //end if
}; //end of the function fd_secret_move3

void () fd_secret_move4 =
{
   sound (self,CHAN_VOICE,self.noise2,TRUE,ATTN_NORM);
   SUB_CalcMove (self.dest1,self.speed,fd_secret_move5);
}; //end of the function fd_secret_move4

void () fd_secret_move5 =
{
   self.nextthink = (self.ltime + TRUE);
   self.think = fd_secret_move6;
   sound (self,CHAN_VOICE,self.noise3,TRUE,ATTN_NORM);
}; //end of the function fd_secret_move5

void () fd_secret_move6 =
{
   sound (self,CHAN_VOICE,self.noise2,TRUE,ATTN_NORM);
   SUB_CalcMove (self.oldorigin,self.speed,fd_secret_done);
}; //end of the function fd_secret_move6

void () fd_secret_done =
{
   if ((!self.targetname || (self.spawnflags & SECRET_YES_SHOOT)))
   {
      self.health = 10000.000;
      self.takedamage = DAMAGE_YES;
      self.th_pain = fd_secret_use;
   } //end if
   sound (self,CHAN_VOICE,self.noise3,TRUE,ATTN_NORM);
}; //end of the function fd_secret_done

void () secret_blocked =
{
   if ((time < self.attack_finished))
   {
      return ;
   } //end if
   self.attack_finished = (time + 0.500);
   T_Damage (other,self,self,self.dmg);
}; //end of the function secret_blocked

void () secret_touch =
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
   if (self.message)
   {
      if ((other.classname == "player"))
      {
         centerprint (other,self.message);
      } //end if
      sound (other,CHAN_BODY,"misc/talk.wav",TRUE,ATTN_NORM);
   } //end if
}; //end of the function secret_touch

void () func_door_secret =
{
   if ((self.sounds == FALSE))
   {
      self.sounds = MOVETYPE_WALK;
   } //end if
   if ((self.sounds == TRUE))
   {
      precache_sound ("doors/latch2.wav");
      precache_sound ("doors/winch2.wav");
      precache_sound ("doors/drclos4.wav");
      self.noise1 = "doors/latch2.wav";
      self.noise2 = "doors/winch2.wav";
      self.noise3 = "doors/drclos4.wav";
   } //end if
   if ((self.sounds == FL_SWIM))
   {
      precache_sound ("doors/airdoor1.wav");
      precache_sound ("doors/airdoor2.wav");
      self.noise2 = "doors/airdoor1.wav";
      self.noise1 = "doors/airdoor2.wav";
      self.noise3 = "doors/airdoor2.wav";
   } //end if
   if ((self.sounds == MOVETYPE_WALK))
   {
      precache_sound ("doors/basesec1.wav");
      precache_sound ("doors/basesec2.wav");
      self.noise2 = "doors/basesec1.wav";
      self.noise1 = "doors/basesec2.wav";
      self.noise3 = "doors/basesec2.wav";
   } //end if
   if (!self.dmg)
   {
      self.dmg = FL_SWIM;
   } //end if
   self.mangle = self.angles;
   self.angles = VEC_ORIGIN;
   self.solid = SOLID_BSP;
   self.movetype = MOVETYPE_PUSH;
   self.classname = "door";
   setmodel (self,self.model);
   setorigin (self,self.origin);
   self.touch = secret_touch;
   self.th_weight = doorweight;
   self.blocked = secret_blocked;
   self.speed = 50.000;
   self.use = fd_secret_use;
   if ((!self.targetname || (self.spawnflags & SECRET_YES_SHOOT)))
   {
      self.health = 10000.000;
      self.takedamage = DAMAGE_YES;
      self.th_pain = fd_secret_use;
   } //end if
   self.oldorigin = self.origin;
   if (!self.wait)
   {
      self.wait = MOVETYPE_FLY;
   } //end if
}; //end of the function func_door_secret
