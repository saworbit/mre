
void (entity e, float newskin) skinChange =
{
   local entity b;

   if (!SKINSMODE)
   {
      e.skin = FALSE;
      return ;
   } //end if
   if ((newskin < FALSE))
   {
      newskin = 15.000;
   } //end if
   if ((newskin > 15.000))
   {
      newskin = FALSE;
   } //end if
   e.skin = newskin;
   if (teamplay)
   {
      if ((e.classname == "player"))
      {
         b = find (world,classname,"dmbot");
         while (b)
         {
            if ((b.team == e.team))
            {
               b.skin = e.skin;
            } //end if
            b = find (b,classname,"dmbot");
         } //end while
      } //end if
   } //end if
}; //end of the function skinChange

void () removeSkins =
{
   local entity e;

   SKINSMODE = FALSE;
   e = find (world,classname,"player");
   while (e)
   {
      e.skin = FALSE;
      e = find (e,classname,"player");
   } //end while
   e = find (world,classname,"dmbot");
   while (e)
   {
      e.skin = FALSE;
      e = find (e,classname,"dmbot");
   } //end while
}; //end of the function removeSkins

void () setSkinsMode =
{
   if ((SKINSMODE == FL_SWIM))
   {
      removeSkins ();
      dprint ("Skins mode turned off\n");
      return ;
   } //end if
   SKINSMODE = (SKINSMODE + TRUE);
   if ((SKINSMODE == TRUE))
   {
      dprint ("Skins mode activated\n");

   } //end if
   else
   {
      dprint ("Skill-based skins mode activated\n");
   } //end if
}; //end of the function setSkinsMode

void () Watcher =
{
   dprint (self.netname);
   dprint (" likes to watch\n");
   self.classname = "watcher";
   self.solid = SOLID_NOT;
   self.movetype = MOVETYPE_NOCLIP;
   self.deadflag = DEAD_NO;
   self.frame = CAM_IDLE;
   self.modelindex = modelindex_eyes;
   self.takedamage = DAMAGE_NO;
}; //end of the function Watcher

void () NoWatcher =
{
   dprint (self.netname);
   dprint (" wants to play\n");
   self.classname = "player";
   self.health = CAM_IDLE;
   self.solid = SOLID_NOT;
   self.movetype = MOVETYPE_TOSS;
   self.deadflag = DEAD_DEAD;
   self.modelindex = modelindex_player;
   setsize (self,VEC_HULL_MIN,VEC_HULL_MAX);
   self.flags = (self.flags & FL_ONGROUND);
   self.frame = 60.000;
   respawn ();
}; //end of the function NoWatcher

void () setWatcherMode =
{
   if ((self.classname == "watcher"))
   {
      NoWatcher ();
      return ;
   } //end if
   Watcher ();
}; //end of the function setWatcherMode

void () setVerboseMode =
{
   VERBOSEBOT = !VERBOSEBOT;
}; //end of the function setVerboseMode

void () setNamingMode =
{
   NAMEBOTS = !NAMEBOTS;
}; //end of the function setNamingMode

void () botRestrictedCommand =
{
   local string tmp;

   if ((self.impulse == 202.000))
   {
      setSkinsMode ();

   } //end if
   else
   {
      if ((self.impulse == 205.000))
      {
         AddAnotherBot ();

      } //end if
      else
      {
         if (((self.impulse > 99.000) && (self.impulse < 116.000)))
         {
            if (teamplay)
            {
               SetTeamBots ((self.impulse - MUST_HAVE));

            } //end if
            else
            {
               SetMaxBots ((self.impulse - MUST_HAVE));
            } //end if

         } //end if
         else
         {
            if ((self.impulse == 208.000))
            {
               AddAnotherBot ();
               AddAnotherBot ();
               AddAnotherBot ();
               AddAnotherBot ();

            } //end if
            else
            {
               if ((self.impulse == 211.000))
               {
                  removeAllBots ();

               } //end if
               else
               {
                  if ((self.impulse == 214.000))
                  {
                     setBotGravity ();

                  } //end if
                  else
                  {
                     if ((self.impulse == 215.000))
                     {
                        setVerboseMode ();

                     } //end if
                     else
                     {
                        if ((self.impulse == 217.000))
                        {
                           tmp = ftos (NUMPATHS);
                           dprint (tmp);
                           dprint (" botpaths placed\n");

                        } //end if
                        else
                        {
                           if ((self.impulse == 117.000))
                           {
                              tmp = ftos (NUMPATHERS);
                              dprint (tmp);
                              dprint (" botpathers\n");

                           } //end if
                           else
                           {
                              if ((self.impulse == 118.000))
                              {
                                 tmp = ftos (NUMBOTS);
                                 dprint (tmp);
                                 dprint (" active bots\n");

                              } //end if
                              else
                              {
                                 if ((self.impulse == 119.000))
                                 {
                                    tmp = ftos (serverflags);
                                    dprint (tmp);
                                    dprint (" server flags\n");

                                 } //end if
                                 else
                                 {
                                    if ((self.impulse == 218.000))
                                    {
                                       serverflags = (serverflags | RESTRICT);
                                       dprint ("Restricted mode set\n");

                                    } //end if
                                    else
                                    {
                                       if ((self.impulse == 219.000))
                                       {
                                          serverflags = (serverflags | SUPERRESTRICT);
                                          dprint ("Super Restricted mode set\n");
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
}; //end of the function botRestrictedCommand

void () botImpulseCommand =
{
   if ((self.impulse == 200.000))
   {
      skinChange (self,(self.skin + TRUE));

   } //end if
   else
   {
      if ((self.impulse == 201.000))
      {
         skinChange (self,(self.skin - TRUE));

      } //end if
      else
      {
         if ((self.impulse == 204.000))
         {
            printIntro ();

         } //end if
         else
         {
            if ((self.impulse == 210.000))
            {
               PrintScores (MYSCORE);

            } //end if
            else
            {
               if ((self.impulse == 220.000))
               {
                  PrintScores (NORMALSCORE);

               } //end if
               else
               {
                  if ((self.impulse == 221.000))
                  {
                     UpdateTeamColors ();

                  } //end if
                  else
                  {
                     if ((self.impulse == 222.000))
                     {
                        PrintTopScores (NORMALSCORE);

                     } //end if
                     else
                     {
                        if ((self.impulse == 223.000))
                        {
                           self.items = (self.items | IT_INVULNERABILITY);
                           self.invincible_finished = (time + SVC_INTERMISSION);

                        } //end if
                        else
                        {
                           if (!(serverflags & SUPERRESTRICT))
                           {
                              if ((!(serverflags & RESTRICT) || (self.colormap == TRUE)))
                              {
                                 botRestrictedCommand ();
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
}; //end of the function botImpulseCommand
