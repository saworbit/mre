
void () button_return;

void () button_wait =
{
   self.state = STATE_TOP;
   self.nextthink = (self.ltime + self.wait);
   self.think = button_return;
   activator = self.enemy;
   SUB_UseTargets ();
   self.frame = TRUE;
}; //end of the function button_wait

void () button_done =
{
   self.state = STATE_BOTTOM;
}; //end of the function button_done

void () button_return =
{
   self.state = STATE_DOWN;
   SUB_CalcMove (self.pos1,self.speed,button_done);
   self.frame = FALSE;
   if (self.health)
   {
      self.takedamage = DAMAGE_YES;
   } //end if
}; //end of the function button_return

void () button_blocked =
{
}; //end of the function button_blocked

void () button_fire =
{
   if (((self.state == STATE_UP) || (self.state == STATE_TOP)))
   {
      return ;
   } //end if
   sound (self,CHAN_VOICE,self.noise,TRUE,ATTN_NORM);
   self.state = STATE_UP;
   SUB_CalcMove (self.pos2,self.speed,button_wait);
}; //end of the function button_fire

void () button_use =
{
   self.enemy = activator;
   if ((other.isbot))
   {
      bot_triggered (other);
   } //end if
   button_fire ();
}; //end of the function button_use

void () button_touch =
{
   local vector org;

   if ((other.classname != "player"))
   {
      if ((other.classname != "dmbot"))
      {
         return ;
      } //end if
   } //end if
   self.enemy = other;
   if ((other.isbot))
   {
      bot_triggered (other);
   } //end if
   button_fire ();
}; //end of the function button_touch

void () button_killed =
{
   self.enemy = damage_attacker;
   self.health = self.max_health;
   self.takedamage = DAMAGE_NO;
   if ((other.isbot))
   {
      bot_triggered (other);
   } //end if
   button_fire ();
}; //end of the function button_killed

void () func_button =
{
   local float gtemp;
   local float ftemp;

   if ((self.sounds == FALSE))
   {
      precache_sound ("buttons/airbut1.wav");
      self.noise = "buttons/airbut1.wav";
   } //end if
   if ((self.sounds == TRUE))
   {
      precache_sound ("buttons/switch21.wav");
      self.noise = "buttons/switch21.wav";
   } //end if
   if ((self.sounds == FL_SWIM))
   {
      precache_sound ("buttons/switch02.wav");
      self.noise = "buttons/switch02.wav";
   } //end if
   if ((self.sounds == MOVETYPE_WALK))
   {
      precache_sound ("buttons/switch04.wav");
      self.noise = "buttons/switch04.wav";
   } //end if
   SetMovedir ();
   self.movetype = MOVETYPE_PUSH;
   self.solid = SOLID_BSP;
   setmodel (self,self.model);
   self.blocked = button_blocked;
   self.use = button_use;
   self.th_weight = buttonweight;
   if (self.health)
   {
      self.max_health = self.health;
      self.th_die = button_killed;
      self.takedamage = DAMAGE_YES;

   } //end if
   else
   {
      self.touch = button_touch;
   } //end if
   if (!self.speed)
   {
      self.speed = 40.000;
   } //end if
   if (!self.wait)
   {
      self.wait = TRUE;
   } //end if
   if (!self.lip)
   {
      self.lip = MOVETYPE_STEP;
   } //end if
   self.state = STATE_BOTTOM;
   self.pos1 = self.origin;
   self.pos2 = (self.pos1 + (self.movedir * (fabs ((self.movedir * self.size)) - self.lip)));
}; //end of the function func_button
