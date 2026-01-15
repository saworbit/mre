
void () monster_use =
{
   if (self.enemy)
   {
      return ;
   } //end if
   if ((self.health <= FALSE))
   {
      return ;
   } //end if
   if ((activator.items & IT_INVISIBILITY))
   {
      return ;
   } //end if
   if ((activator.flags & FL_NOTARGET))
   {
      return ;
   } //end if
   if ((activator.classname != "player"))
   {
      return ;
   } //end if
   self.enemy = activator;
   self.nextthink = (time + 0.100);
   self.think = FoundTarget;
}; //end of the function monster_use

void () monster_death_use =
{
   local entity ent;
   local entity otemp;
   local entity stemp;

   if ((self.flags & FL_FLY))
   {
      self.flags = (self.flags - FL_FLY);
   } //end if
   if ((self.flags & FL_SWIM))
   {
      self.flags = (self.flags - FL_SWIM);
   } //end if
   if (!self.target)
   {
      return ;
   } //end if
   activator = self.enemy;
   SUB_UseTargets ();
}; //end of the function monster_death_use

void () walkmonster_start_go =
{
   local string stemp;
   local entity etemp;

   self.origin_z = (self.origin_z + TRUE);
   droptofloor (0, 0);
   if (!walkmove (FALSE,FALSE))
   {
      dprint ("walkmonster in wall at: ");
      dprint (vtos (self.origin));
      dprint ("\n");
   } //end if
   self.takedamage = DAMAGE_AIM;
   self.ideal_yaw = (self.angles * '0.000 1.000 0.000');
   if (!self.yaw_speed)
   {
      self.yaw_speed = KINDA_WANT;
   } //end if
   self.view_ofs = '0.000 0.000 25.000';
   self.use = monster_use;
   self.flags = (self.flags | FL_MONSTER);
   if (self.target)
   {
      self.movetarget = find (world,targetname,self.target);
      self.goalentity = find (world,targetname,self.target);
      self.ideal_yaw = vectoyaw ((self.goalentity.origin - self.origin));
      if (!self.movetarget)
      {
         dprint ("Monster can't find target at ");
         dprint (vtos (self.origin));
         dprint ("\n");
      } //end if
      if ((self.movetarget.classname == "path_corner"))
      {
         self.th_walk ();

      } //end if
      else
      {
         self.pausetime = 100000000.000;
      } //end if
      self.th_stand ();

   } //end if
   else
   {
      self.pausetime = 100000000.000;
      self.th_stand ();
   } //end if
   self.nextthink = (self.nextthink + (random () * 0.500));
}; //end of the function walkmonster_start_go

void () walkmonster_start =
{
   self.nextthink = (self.nextthink + (random () * 0.500));
   self.think = walkmonster_start_go;
   total_monsters = (total_monsters + TRUE);
}; //end of the function walkmonster_start

void () flymonster_start_go =
{
   self.takedamage = DAMAGE_AIM;
   self.ideal_yaw = (self.angles * '0.000 1.000 0.000');
   if (!self.yaw_speed)
   {
      self.yaw_speed = MOVETYPE_BOUNCE;
   } //end if
   self.view_ofs = '0.000 0.000 25.000';
   self.use = monster_use;
   self.flags = (self.flags | FL_FLY);
   self.flags = (self.flags | FL_MONSTER);
   if (!walkmove (FALSE,FALSE))
   {
      dprint ("flymonster in wall at: ");
      dprint (vtos (self.origin));
      dprint ("\n");
   } //end if
   if (self.target)
   {
      self.movetarget = find (world,targetname,self.target);
      self.goalentity = find (world,targetname,self.target);
      if (!self.movetarget)
      {
         dprint ("Monster can't find target at ");
         dprint (vtos (self.origin));
         dprint ("\n");
      } //end if
      if ((self.movetarget.classname == "path_corner"))
      {
         self.th_walk ();

      } //end if
      else
      {
         self.pausetime = 100000000.000;
      } //end if
      self.th_stand ();

   } //end if
   else
   {
      self.pausetime = 100000000.000;
      self.th_stand ();
   } //end if
}; //end of the function flymonster_start_go

void () flymonster_start =
{
   self.nextthink = (self.nextthink + (random () * 0.500));
   self.think = flymonster_start_go;
   total_monsters = (total_monsters + TRUE);
}; //end of the function flymonster_start

void () swimmonster_start_go =
{
   if (deathmatch)
   {
      remove (self);
      return ;
   } //end if
   self.takedamage = DAMAGE_AIM;
   total_monsters = (total_monsters + TRUE);
   self.ideal_yaw = (self.angles * '0.000 1.000 0.000');
   if (!self.yaw_speed)
   {
      self.yaw_speed = MOVETYPE_BOUNCE;
   } //end if
   self.view_ofs = '0.000 0.000 10.000';
   self.use = monster_use;
   self.flags = (self.flags | FL_SWIM);
   self.flags = (self.flags | FL_MONSTER);
   if (self.target)
   {
      self.movetarget = find (world,targetname,self.target);
      self.goalentity = find (world,targetname,self.target);
      if (!self.movetarget)
      {
         dprint ("Monster can't find target at ");
         dprint (vtos (self.origin));
         dprint ("\n");
      } //end if
      self.ideal_yaw = vectoyaw ((self.goalentity.origin - self.origin));
      self.th_walk ();

   } //end if
   else
   {
      self.pausetime = 100000000.000;
      self.th_stand ();
   } //end if
   self.nextthink = (self.nextthink + (random () * 0.500));
}; //end of the function swimmonster_start_go

void () swimmonster_start =
{
   self.nextthink = (self.nextthink + (random () * 0.500));
   self.think = swimmonster_start_go;
   total_monsters = (total_monsters + TRUE);
}; //end of the function swimmonster_start
