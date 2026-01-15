
void () movetarget_f;

void () t_movetarget;

void () knight_walk1;

void () knight_bow6;

void () knight_bow1;
entity sight_entity;
float sight_entity_time /* = 0.000 */;
float (float v) anglemod =
{
   while ((v >= 360.000))
   {
      v = (v - 360.000);
   } //end while
   while ((v < FALSE))
   {
      v = (v + 360.000);
   } //end while
   return (v);
}; //end of the function anglemod

void () movetarget_f =
{
   if (!self.targetname)
   {
      objerror ("monster_movetarget: no targetname");
   } //end if
   self.solid = SOLID_TRIGGER;
   self.touch = t_movetarget;
   setsize (self,'-8.000 -8.000 -8.000','8.000 8.000 8.000');
}; //end of the function movetarget_f

void () path_corner =
{
   movetarget_f ();
}; //end of the function path_corner

void () t_movetarget =
{
   local entity temp;

   if ((other.movetarget != self))
   {
      return ;
   } //end if
   if (other.enemy)
   {
      return ;
   } //end if
   temp = self;
   self = other;
   other = temp;
   if ((self.classname == "monster_ogre"))
   {
      sound (self,CHAN_VOICE,"ogre/ogdrag.wav",TRUE,ATTN_IDLE);
   } //end if
   self.movetarget = find (world,targetname,other.target);
   self.goalentity = find (world,targetname,other.target);
   self.ideal_yaw = vectoyaw ((self.goalentity.origin - self.origin));
   if (!self.movetarget)
   {
      self.pausetime = (time + 999999.000);
      self.th_stand ();
      return ;
   } //end if
}; //end of the function t_movetarget
float (entity targ) range =
{
   local vector spot1;
   local vector spot2;
   local float r;

   spot1 = (self.origin + self.view_ofs);
   spot2 = (targ.origin + targ.view_ofs);
   r = vlen ((spot1 - spot2));
   if ((r < 120.000))
   {
      return (RANGE_MELEE);
   } //end if
   if ((r < 500.000))
   {
      return (RANGE_NEAR);
   } //end if
   if ((r < 1000.000))
   {
      return (RANGE_MID);
   } //end if
   return (RANGE_FAR);
}; //end of the function range
float (entity targ) visible =
{
   local vector spot1;
   local vector spot2;

   spot1 = (self.origin + self.view_ofs);
   spot2 = (targ.origin + targ.view_ofs);
   traceline (spot1,spot2,TRUE,self);
   if ((trace_inopen && trace_inwater))
   {
      return (FALSE);
   } //end if
   if ((trace_fraction == TRUE))
   {
      return (TRUE);
   } //end if
   return (FALSE);
}; //end of the function visible
float (entity targ) infront =
{
   local vector vec;
   local float dot;

   makevectors (self.angles);
   vec = normalize ((targ.origin - self.origin));
   dot = (vec * v_forward);
   if ((dot > 0.300))
   {
      return (TRUE);
   } //end if
   return (FALSE);
}; //end of the function infront

void () HuntTarget =
{
   self.goalentity = self.enemy;
   self.think = self.th_run;
   self.ideal_yaw = vectoyaw ((self.enemy.origin - self.origin));
   self.nextthink = (time + 0.100);
   SUB_AttackFinished (TRUE);
}; //end of the function HuntTarget

void () SightSound =
{
   local float rsnd;

   if ((self.classname == "monster_ogre"))
   {
      sound (self,CHAN_VOICE,"ogre/ogwake.wav",TRUE,ATTN_NORM);

   } //end if
   else
   {
      if ((self.classname == "monster_knight"))
      {
         sound (self,CHAN_VOICE,"knight/ksight.wav",TRUE,ATTN_NORM);

      } //end if
      else
      {
         if ((self.classname == "monster_shambler"))
         {
            sound (self,CHAN_VOICE,"shambler/ssight.wav",TRUE,ATTN_NORM);

         } //end if
         else
         {
            if ((self.classname == "monster_demon1"))
            {
               sound (self,CHAN_VOICE,"demon/sight2.wav",TRUE,ATTN_NORM);

            } //end if
            else
            {
               if ((self.classname == "monster_wizard"))
               {
                  sound (self,CHAN_VOICE,"wizard/wsight.wav",TRUE,ATTN_NORM);

               } //end if
               else
               {
                  if ((self.classname == "monster_zombie"))
                  {
                     sound (self,CHAN_VOICE,"zombie/z_idle.wav",TRUE,ATTN_NORM);

                  } //end if
                  else
                  {
                     if ((self.classname == "monster_dog"))
                     {
                        sound (self,CHAN_VOICE,"dog/dsight.wav",TRUE,ATTN_NORM);

                     } //end if
                     else
                     {
                        if ((self.classname == "monster_hell_knight"))
                        {
                           sound (self,CHAN_VOICE,"hknight/sight1.wav",TRUE,ATTN_NORM);

                        } //end if
                        else
                        {
                           if ((self.classname == "monster_tarbaby"))
                           {
                              sound (self,CHAN_VOICE,"blob/sight1.wav",TRUE,ATTN_NORM);

                           } //end if
                           else
                           {
                              if ((self.classname == "monster_vomit"))
                              {
                                 sound (self,CHAN_VOICE,"vomitus/v_sight1.wav",TRUE,ATTN_NORM);

                              } //end if
                              else
                              {
                                 if ((self.classname == "monster_enforcer"))
                                 {
                                    rsnd = rint ((random () * MOVETYPE_WALK));
                                    if ((rsnd == TRUE))
                                    {
                                       sound (self,CHAN_VOICE,"enforcer/sight1.wav",TRUE,ATTN_NORM);

                                    } //end if
                                    else
                                    {
                                       if ((rsnd == FL_SWIM))
                                       {
                                          sound (self,CHAN_VOICE,"enforcer/sight2.wav",TRUE,ATTN_NORM);

                                       } //end if
                                       else
                                       {
                                          if ((rsnd == FALSE))
                                          {
                                             sound (self,CHAN_VOICE,"enforcer/sight3.wav",TRUE,ATTN_NORM);

                                          } //end if
                                          else
                                          {
                                             sound (self,CHAN_VOICE,"enforcer/sight4.wav",TRUE,ATTN_NORM);
                                          } //end if
                                       } //end if
                                    } //end if

                                 } //end if
                                 else
                                 {
                                    if ((self.classname == "monster_army"))
                                    {
                                       sound (self,CHAN_VOICE,"soldier/sight1.wav",TRUE,ATTN_NORM);

                                    } //end if
                                    else
                                    {
                                       if ((self.classname == "monster_shalrath"))
                                       {
                                          sound (self,CHAN_VOICE,"shalrath/sight.wav",TRUE,ATTN_NORM);
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
}; //end of the function SightSound

void () FoundTarget =
{
   if ((self.enemy.classname == "player"))
   {
      sight_entity = self;
      sight_entity_time = time;
   } //end if
   self.show_hostile = (time + TRUE);
   SightSound ();
   HuntTarget ();
}; //end of the function FoundTarget
float () FindTarget =
{
   local entity client;
   local float r;

   client = world;
   if (coop)
   {
      client = find_bot ();
   } //end if
   if (!client)
   {
      client = checkclient ();
   } //end if
   if ((client == self.enemy))
   {
      return (FALSE);
   } //end if
   if ((client.flags & FL_NOTARGET))
   {
      return (FALSE);
   } //end if
   if ((client.items & IT_INVISIBILITY))
   {
      return (FALSE);
   } //end if
   r = range (client);
   if ((r == RANGE_FAR))
   {
      return (FALSE);
   } //end if
   if (!visible (client))
   {
      return (FALSE);
   } //end if
   if ((r == RANGE_NEAR))
   {
      if (((client.show_hostile < time) && !infront (client)))
      {
         return (FALSE);
      } //end if

   } //end if
   else
   {
      if ((r == RANGE_MID))
      {
         if (!infront (client))
         {
            return (FALSE);
         } //end if
      } //end if
   } //end if
   self.enemy = client;
    if (((self.enemy.classname != "player") && (self.enemy.classname != "dmbot")))
    {
       self.enemy = self.enemy.enemy;
       if (((self.enemy.classname != "player") && (self.enemy.classname != "dmbot")))
       {
          self.enemy = world;
          return (FALSE);
       } //end if
       FoundTarget ();
       return (TRUE);
    } //end if
    FoundTarget ();
    return (TRUE);
}; //end of the function FindTarget

void (float dist) ai_forward =
{
   walkmove (self.angles_y,dist);
}; //end of the function ai_forward

void (float dist) ai_back =
{
   walkmove ((self.angles_y + 180.000),dist);
}; //end of the function ai_back

void (float dist) ai_pain =
{
   ai_back (dist);
}; //end of the function ai_pain

void (float dist) ai_painforward =
{
   walkmove (self.ideal_yaw,dist);
}; //end of the function ai_painforward

void (float dist) ai_walk =
{
   local vector mtemp;

   movedist = dist;
   if ((self.classname == "monster_dragon"))
   {
      movetogoal (dist);
      return ;
   } //end if
   if (FindTarget ())
   {
      return ;
   } //end if
   movetogoal (dist);
}; //end of the function ai_walk

void () ai_stand =
{
   if (FindTarget ())
   {
      return ;
   } //end if
   if ((time > self.pausetime))
   {
      self.th_walk ();
      return ;
   } //end if
}; //end of the function ai_stand

void () ai_turn =
{
   if (FindTarget ())
   {
      return ;
   } //end if
   ChangeYaw ();
}; //end of the function ai_turn

void (vector dest3) ChooseTurn =
{
   local vector dir;
   local vector newdir;

   dir = (self.origin - dest3);
   newdir_x = trace_plane_normal_y;
   newdir_y = (FALSE - trace_plane_normal_x);
   newdir_z = FALSE;
   if (((dir * newdir) > FALSE))
   {
      dir_x = (FALSE - trace_plane_normal_y);
      dir_y = trace_plane_normal_x;

   } //end if
   else
   {
      dir_x = trace_plane_normal_y;
      dir_y = (FALSE - trace_plane_normal_x);
   } //end if
   dir_z = FALSE;
   self.ideal_yaw = vectoyaw (dir);
}; //end of the function ChooseTurn
float () FacingIdeal =
{
   local float delta;

   delta = anglemod ((self.angles_y - self.ideal_yaw));
   if (((delta > 45.000) && (delta < 315.000)))
   {
      return (FALSE);
   } //end if
   return (TRUE);
}; //end of the function FacingIdeal

float () CheckAnyAttack =
{
   if (!enemy_vis)
   {
      return (FALSE);
   } //end if
   return (FALSE);
}; //end of the function CheckAnyAttack

void () ai_run_melee =
{
   self.ideal_yaw = enemy_yaw;
   ChangeYaw ();
   if (FacingIdeal ())
   {
      self.th_melee ();
      self.attack_state = AS_STRAIGHT;
   } //end if
}; //end of the function ai_run_melee

void () ai_run_missile =
{
   self.ideal_yaw = enemy_yaw;
   ChangeYaw ();
   if (FacingIdeal ())
   {
      self.th_missile ();
      self.attack_state = AS_STRAIGHT;
   } //end if
}; //end of the function ai_run_missile

void () ai_run_slide =
{
   local float ofs;

   self.ideal_yaw = enemy_yaw;
   ChangeYaw ();
   if (self.lefty)
   {
      ofs = 90.000;

   } //end if
   else
   {
      ofs = -90.000;
   } //end if
   if (walkmove ((self.ideal_yaw + ofs),movedist))
   {
      return ;
   } //end if
   self.lefty = (TRUE - self.lefty);
   walkmove ((self.ideal_yaw - ofs),movedist);
}; //end of the function ai_run_slide

void (float dist) ai_run =
{
   local vector delta;
   local float axis;
   local float direct;
   local float ang_rint;
   local float ang_floor;
   local float ang_ceil;

   movedist = dist;
   if ((self.enemy.health <= FALSE))
   {
      self.enemy = world;
      if ((self.oldenemy.health > FALSE))
      {
         self.enemy = self.oldenemy;
         HuntTarget ();

      } //end if
      else
      {
         if (self.movetarget)
         {
            self.th_walk ();

         } //end if
         else
         {
            self.th_stand ();
         } //end if
         return ;
      } //end if
   } //end if
   self.show_hostile = (time + TRUE);
   enemy_vis = visible (self.enemy);
   if (enemy_vis)
   {
      self.search_time = (time + MOVETYPE_FLY);
   } //end if
   if (((coop || deathmatch) && (self.search_time < time)))
   {
      if (FindTarget ())
      {
         return ;
      } //end if
   } //end if
   enemy_infront = infront (self.enemy);
   enemy_range = range (self.enemy);
   enemy_yaw = vectoyaw ((self.enemy.origin - self.origin));
   if ((self.attack_state == AS_MISSILE))
   {
      ai_run_missile ();
      return ;
   } //end if
   if ((self.attack_state == AS_MELEE))
   {
      ai_run_melee ();
      return ;
   } //end if
   if (CheckAnyAttack ())
   {
      return ;
   } //end if
   if ((self.attack_state == AS_SLIDING))
   {
      ai_run_slide ();
      return ;
   } //end if
   movetogoal (dist);
}; //end of the function ai_run
