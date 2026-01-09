
void () t_botmovetarget;
entity (entity chaser, entity en) BestChaseRoute;
entity () botmovetarget =
{
   local entity targ;

   targ = spawn ();
   targ.classname = "BotTarget";
   targ.solid = SOLID_TRIGGER;
   targ.movetarget = world;
   targ.touch = t_botmovetarget;
   setsize (targ,'-4.000 -4.000 0.000','4.000 4.000 8.000');
   return (targ);
}; //end of the function botmovetarget

void () t_botmovetarget =
{
   local vector in;
   local entity tmp;
   local entity pth;
   local float rnd;

   if ((other.goalentity != self))
   {
      return ;
   } //end if
   if ((self.classname != "BotTarget"))
   {
      objerror ("bad bot target in bot_touch! 1\n");
   } //end if
   if ((self.goalentity.classname != "player"))
   {
      if (VERBOSEBOT)
      {
         dprint (other.teamname);
         dprint (other.netname);
         dprint (" got to ");
         dprint (self.goalentity.classname);
         dprint ("\n");
      } //end if
      other.lefty = (other.lefty - (other.lefty & LOCAL_TIME));
      if ((self.goalentity.classname == "door"))
      {
         if ((self.goalentity.use == fd_secret_use))
         {
            return ;
         } //end if
      } //end if
      if ((self.goalentity.classname == "train"))
      {
         if (!(other.lefty & ONTRAIN))
         {
            other.lefty = (other.lefty | ONTRAIN);
            other.nav_search_time = (time + TRUE);
         } //end if
         return ;
      } //end if
      if ((self.goalentity.classname != "func_button"))
      {
         if ((other.lefty & GETGOODY))
         {
         other.goody_time = time;

         } //end if
         else
         {
            other.nav_search_time = time;
         } //end if
         return ;
      } //end if
      tmp = self;
      self = self.goalentity;
      button_touch ();
      self = tmp;
      clearCache (other);
      other.nav_search_time = (time + MOVETYPE_WALK);
      other.nextthink = (time + 0.300);
      return ;
   } //end if
   if (VERBOSEBOT)
   {
      dprint (other.teamname);
      dprint (other.netname);
      dprint ("tracking ");
      dprint (self.goalentity.teamname);
      dprint (self.goalentity.netname);
      dprint ("\n");
   } //end if
   pth = BestChaseRoute (other,self.goalentity);
   rnd = ((2000.000 + (random () * 1000.000)) + (other.skil * SEARCH_RADIUS));
   rnd = (rnd - vlen ((other.origin - pth.origin)));
   if ((rnd < pth.enemylen))
   {
      other.combat_search_time = (time - TRUE);
      return ;
   } //end if
   random ();
   random ();
   random ();
   random ();
   rnd = (random () * (other.skil + TRUE));
   if ((rnd < 0.100))
   {
      other.combat_search_time = (time - TRUE);
      return ;
   } //end if
   if ((self.classname != "BotTarget"))
   {
      objerror ("bad bot target in bot_touch! 2\n");
   } //end if
   setorigin (self,pth.origin);
   other.combat_search_time = (time + MOVETYPE_STEP);
}; //end of the function t_botmovetarget

void () bot_toucheditem =
{
   if ((other.goalentity.goalentity == self))
   {
      if (VERBOSEBOT)
      {
         dprint (other.teamname);
         dprint (other.netname);
         dprint (" got to ");
         dprint (self.classname);
         dprint ("\n");
      } //end if
      other.lefty = (other.lefty - (other.lefty & LOCAL_TIME));
      other.nav_search_time = (time - TRUE);
   } //end if
}; //end of the function bot_toucheditem

void (entity bot) bot_triggered =
{
   local vector org;
   local entity Botgoal;

   Botgoal = bot.goalentity;
   if ((Botgoal.goalentity != self))
   {
      return ;
   } //end if
   Botgoal.goalentity = find (world,targetname,self.target);
   if ((Botgoal.goalentity.classname == "light"))
   {
      bot.nav_search_time = time;
      return ;
   } //end if
   if (Botgoal.goalentity)
   {
      bot.nav_search_time = (time + MOVETYPE_WALK);
      org = ((Botgoal.goalentity.absmax + Botgoal.goalentity.absmin) * 0.500);
      org_z = (Botgoal.goalentity.absmin_z + TRUE);
      if ((Botgoal.classname != "BotTarget"))
      {
         objerror ("bad bot target in bot_touch! 3\n");
      } //end if
      setorigin (Botgoal,org);
      Botgoal.goalentity.lastbot = bot;
      Botgoal.goalentity.lasttime = time;
      if (VERBOSEBOT)
      {
         dprint ("now Bot will go after the triggered ");
         dprint (Botgoal.goalentity.classname);
         dprint ("\n");
      } //end if
   } //end if
}; //end of the function bot_triggered

void () aibot_setupchase;

void () bot_touched =
{
   local entity tmp;

   tmp = self;
   self = other.goalentity;
   if ((self.classname != "BotTarget"))
   {
      objerror ("bad bot target in bot_touch! 4\n");
   } //end if
   if ((self.goalentity == tmp))
   {
      t_botmovetarget ();

   } //end if
   else
   {
      if ((self.goalentity.classname == "door"))
      {
         if ((tmp.classname == "door"))
         {
            t_botmovetarget ();
         } //end if
      } //end if
   } //end if
   self = tmp;
}; //end of the function bot_touched

void () enemy_touched =
{
   local entity tmp;
   local vector org;

   if (VERBOSEBOT)
   {
      dprint (other.enemy.teamname);
      dprint (other.enemy.netname);
      dprint (" chasing ");
      dprint (other.teamname);
      dprint (other.netname);
      dprint (" through ");
      dprint (self.classname);
      dprint ("!\n");
   } //end if
   org = ((self.absmax + self.absmin) * 0.500);
   org_z = (self.absmin_z + TRUE);
   if ((self.classname == "door"))
   {
      org = other.origin;
   } //end if
   tmp = self;
   self = other.enemy;
   if ((self.enemy != other))
   {
      self = tmp;
      return ;
   } //end if
   if ((tmp.classname == "trigger_push"))
   {
      endEnemy ();
      self.combat_search_time = (time + MOVETYPE_STEP);
      if ((self.goalentity.classname != "BotTarget"))
      {
         objerror ("bad bot target in bot_touch! 5\n");
      } //end if
      setorigin (self.goalentity,org);
      self = tmp;
      return ;
   } //end if
   if ((self.goalentity.classname != "BotTarget"))
   {
      objerror ("ERROR - bad bot target!\n");
   } //end if
   setorigin (self.goalentity,org);
   self.goalentity.goalentity = self.enemy;
   self.combat_search_time = (time + MOVETYPE_STEP);
   if ((self.lefty & GETGOODY))
   {
      self.lefty = (self.lefty - GETGOODY);
   } //end if
   aibot_setupchase ();
   self = tmp;
}; //end of the function enemy_touched
