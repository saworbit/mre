
void () plat_center_touch;

void () plat_outside_touch;

void () plat_trigger_use;

void () plat_go_up;

void () plat_go_down;

void () plat_crush;
float PLAT_LOW_TRIGGER    = 1.000;

void () plat_spawn_inside_trigger =
{
   local entity trigger;
   local vector tmin;
   local vector tmax;

   trigger = spawn ();
   trigger.touch = plat_center_touch;
   trigger.movetype = MOVETYPE_NONE;
   trigger.solid = SOLID_TRIGGER;
   trigger.enemy = self;
   tmin = (self.mins + '25.000 25.000 0.000');
   tmax = (self.maxs - '25.000 25.000 -8.000');
   tmin_z = (tmax_z - ((self.pos1_z - self.pos2_z) + FL_CLIENT));
   if ((self.spawnflags & PLAT_LOW_TRIGGER))
   {
      tmax_z = (tmin_z + FL_CLIENT);
   } //end if
   if ((self.size_x <= 50.000))
   {
      tmin_x = ((self.mins_x + self.maxs_x) / SILENT);
      tmax_x = (tmin_x + TRUE);
   } //end if
   if ((self.size_y <= 50.000))
   {
      tmin_y = ((self.mins_y + self.maxs_y) / SILENT);
      tmax_y = (tmin_y + TRUE);
   } //end if
   setsize (trigger,tmin,tmax);
}; //end of the function plat_spawn_inside_trigger

void () plat_hit_top =
{
   sound (self,CHAN_VOICE,self.noise1,TRUE,ATTN_NORM);
   self.state = STATE_TOP;
   self.think = plat_go_down;
   self.nextthink = (self.ltime + MOVETYPE_WALK);
   if ((self.lastbot.goalentity.goalentity == self))
   {
      if ((self.lasttime > (time - MOVETYPE_BOUNCE)))
      {
         self.lastbot.search_time = time;
         self.lastbot.goalentity.goalentity = self.lastbot.goalentity;
      } //end if
   } //end if
}; //end of the function plat_hit_top

void () plat_hit_bottom =
{
   sound (self,CHAN_VOICE,self.noise1,TRUE,ATTN_NORM);
   self.state = STATE_BOTTOM;
   if ((self.lastbot.goalentity.goalentity == self))
   {
      if ((self.lasttime > (time - MOVETYPE_BOUNCE)))
      {
         self.lastbot.search_time = (time + 0.500);
         self.lastbot.goalentity.goalentity = self.lastbot.goalentity;
      } //end if
   } //end if
}; //end of the function plat_hit_bottom

void () plat_go_down =
{
   sound (self,CHAN_VOICE,self.noise,TRUE,ATTN_NORM);
   self.state = STATE_DOWN;
   SUB_CalcMove (self.pos2,self.speed,plat_hit_bottom);
}; //end of the function plat_go_down

void () plat_go_up =
{
   sound (self,CHAN_VOICE,self.noise,TRUE,ATTN_NORM);
   self.state = STATE_UP;
   SUB_CalcMove (self.pos1,self.speed,plat_hit_top);
}; //end of the function plat_go_up

void () plat_center_touch =
{
   if ((other.classname != "player"))
   {
      if ((other.classname != "dmbot"))
      {
         return ;
      } //end if
   } //end if
   if ((other.health <= FALSE))
   {
      return ;
   } //end if
   self = self.enemy;
   if ((self.state == STATE_BOTTOM))
   {
      if ((other.classname == "dmbot"))
      {
         if ((other.goalentity.goalentity == self))
         {
            other.search_time = (time + MOVETYPE_TOSS);
         } //end if
      } //end if
      plat_go_up ();

   } //end if
   else
   {
      if ((self.state == STATE_TOP))
      {
         if ((other.classname == "dmbot"))
         {
            if ((other.goalentity.goalentity == self))
            {
               other.search_time = time;
            } //end if
         } //end if
         self.nextthink = (self.ltime + TRUE);
      } //end if
   } //end if
}; //end of the function plat_center_touch

void () plat_outside_touch =
{
   if ((other.classname != "player"))
   {
      if ((other.classname != "dmbot"))
      {
         return ;
      } //end if
   } //end if
   if ((other.health <= FALSE))
   {
      return ;
   } //end if
   self = self.enemy;
   if ((self.state == STATE_TOP))
   {
      if ((other.classname == "dmbot"))
      {
         if ((other.goalentity.goalentity == self))
         {
            other.search_time = (time + MOVETYPE_TOSS);
         } //end if
      } //end if
      plat_go_down ();
   } //end if
}; //end of the function plat_outside_touch

void () plat_trigger_use =
{
   if (self.think)
   {
      return ;
   } //end if
   plat_go_down ();
}; //end of the function plat_trigger_use

void () plat_crush =
{
   T_Damage (other,self,self,TRUE);
   if ((self.state == STATE_UP))
   {
      plat_go_down ();

   } //end if
   else
   {
      if ((self.state == STATE_DOWN))
      {
         plat_go_up ();

      } //end if
      else
      {
         objerror ("plat_crush: bad self.state\n");
      } //end if
   } //end if
}; //end of the function plat_crush

void () plat_use =
{
   self.use = SUB_Null;
   if ((self.state != STATE_UP))
   {
      objerror ("plat_use: not in up state");
   } //end if
   plat_go_down ();
}; //end of the function plat_use

void () func_plat =
{
   local entity t;

   if (!self.t_length)
   {
      self.t_length = 80.000;
   } //end if
   if (!self.t_width)
   {
      self.t_width = MOVETYPE_BOUNCE;
   } //end if
   if ((self.sounds == FALSE))
   {
      self.sounds = SILENT;
   } //end if
   if ((self.sounds == TRUE))
   {
      precache_sound ("plats/plat1.wav");
      precache_sound ("plats/plat2.wav");
      self.noise = "plats/plat1.wav";
      self.noise1 = "plats/plat2.wav";
   } //end if
   if ((self.sounds == SILENT))
   {
      precache_sound ("plats/medplat1.wav");
      precache_sound ("plats/medplat2.wav");
      self.noise = "plats/medplat1.wav";
      self.noise1 = "plats/medplat2.wav";
   } //end if
   self.mangle = self.angles;
   self.angles = VEC_ORIGIN;
   self.classname = "plat";
   self.solid = SOLID_BSP;
   self.movetype = MOVETYPE_PUSH;
   setorigin (self,self.origin);
   setmodel (self,self.model);
   setsize (self,self.mins,self.maxs);
   self.th_weight = platweight;
   self.blocked = plat_crush;
   if (!self.speed)
   {
      self.speed = 150.000;
   } //end if
   self.pos1 = self.origin;
   self.pos2 = self.origin;
   if (self.height)
   {
      self.pos2_z = (self.origin_z - self.height);

   } //end if
   else
   {
      self.pos2_z = ((self.origin_z - self.size_z) + FL_CLIENT);
   } //end if
   self.use = plat_trigger_use;
   plat_spawn_inside_trigger ();
   if (self.targetname)
   {
      self.state = STATE_UP;
      self.use = plat_use;

   } //end if
   else
   {
      setorigin (self,self.pos2);
      self.state = STATE_BOTTOM;
   } //end if
}; //end of the function func_plat

void () train_next;

void () func_train_find;

void () train_blocked =
{
   if ((time < self.attack_finished))
   {
      return ;
   } //end if
   self.attack_finished = (time + 0.500);
   T_Damage (other,self,self,self.dmg);
}; //end of the function train_blocked

void () train_use =
{
   if ((self.think != func_train_find))
   {
      return ;
   } //end if
   train_next ();
}; //end of the function train_use

void () train_wait =
{
   if (self.wait)
   {
      self.nextthink = (self.ltime + self.wait);
      sound (self,CHAN_VOICE,self.noise,TRUE,ATTN_NORM);

   } //end if
   else
   {
      self.nextthink = (self.ltime + 0.100);
   } //end if
   self.think = train_next;
}; //end of the function train_wait

void () train_next =
{
   local entity targ;
   local float rnd;

   targ = find (world,targetname,self.target);
   self.target = targ.target;
   if (!self.target)
   {
      objerror ("train_next: no next target");
   } //end if
   if (targ.wait)
   {
      self.wait = targ.wait;

   } //end if
   else
   {
      self.wait = FALSE;
   } //end if
   sound (self,CHAN_VOICE,self.noise1,TRUE,ATTN_NORM);
   SUB_CalcMove ((targ.origin - self.mins),self.speed,train_wait);
}; //end of the function train_next

void () func_train_find =
{
   local entity targ;

   targ = find (world,targetname,self.target);
   self.target = targ.target;
   setorigin (self,(targ.origin - self.mins));
   if (!self.targetname)
   {
      self.nextthink = (self.ltime + 0.100);
      self.think = train_next;
   } //end if
}; //end of the function func_train_find

void () func_train =
{
   if (!self.speed)
   {
      self.speed = MUST_HAVE;
   } //end if
   if (!self.target)
   {
      objerror ("func_train without a target");
   } //end if
   if (!self.dmg)
   {
      self.dmg = SILENT;
   } //end if
   if ((self.sounds == FALSE))
   {
      self.noise = "misc/null.wav";
      precache_sound ("misc/null.wav");
      self.noise1 = "misc/null.wav";
      precache_sound ("misc/null.wav");
   } //end if
   if ((self.sounds == TRUE))
   {
      self.noise = "plats/train2.wav";
      precache_sound ("plats/train2.wav");
      self.noise1 = "plats/train1.wav";
      precache_sound ("plats/train1.wav");
   } //end if
   self.cnt = TRUE;
   self.solid = SOLID_BSP;
   self.movetype = MOVETYPE_PUSH;
   self.blocked = train_blocked;
   self.use = train_use;
   self.classname = "train";
   self.th_weight = platweight;
   setmodel (self,self.model);
   setsize (self,self.mins,self.maxs);
   setorigin (self,self.origin);
   self.nextthink = (self.ltime + 0.100);
   self.think = func_train_find;
}; //end of the function func_train

void () misc_teleporttrain =
{
   if (!self.speed)
   {
      self.speed = MUST_HAVE;
   } //end if
   if (!self.target)
   {
      objerror ("func_train without a target");
   } //end if
   self.cnt = TRUE;
   self.solid = SOLID_NOT;
   self.movetype = MOVETYPE_PUSH;
   self.blocked = train_blocked;
   self.use = train_use;
   self.avelocity = '100.000 200.000 300.000';
   self.noise = "misc/null.wav";
   precache_sound ("misc/null.wav");
   self.noise1 = "misc/null.wav";
   precache_sound ("misc/null.wav");
   precache_model2 ("progs/teleport.mdl");
   setmodel (self,"progs/teleport.mdl");
   setsize (self,self.mins,self.maxs);
   setorigin (self,self.origin);
   self.nextthink = (self.ltime + 0.100);
   self.think = func_train_find;
}; //end of the function misc_teleporttrain
