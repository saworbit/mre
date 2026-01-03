
void () initscore =
{
   self.playerkills = FALSE;
   self.playerdeaths = FALSE;
   self.botkills = FALSE;
   self.botdeaths = FALSE;
   self.suicides = FALSE;
}; //end of the function initscore

void (entity killer, entity killed) countkill =
{
   local float adj;

   if ((skill == TRUE))
   {
      adj = 0.800;
      if (((killed.playerdeaths + killed.botdeaths) > MOVETYPE_BOUNCE))
      {
         adj = 0.400;
      } //end if
      if (((killed.playerdeaths + killed.botdeaths) > KINDA_WANT))
      {
         adj = 0.150;
      } //end if
   } //end if
   if ((killer == killed))
   {
      killer.suicides = (killer.suicides + TRUE);
      return ;
   } //end if
   if ((killer.classname == "player"))
   {
      killed.playerdeaths = (killed.playerdeaths + TRUE);
      if ((skill == TRUE))
      {
         if ((killed.classname == "dmbot"))
         {
            killed.skil = (killed.skil + (adj * random ()));
            if ((killed.skil > MOVETYPE_WALK))
            {
               killed.skil = MOVETYPE_WALK;
            } //end if
         } //end if
      } //end if

   } //end if
   else
   {
      if ((killer.classname == "dmbot"))
      {
         killed.botdeaths = (killed.botdeaths + TRUE);
         if ((skill == TRUE))
         {
            if ((killed.classname == "player"))
            {
               killer.skil = (killer.skil - (adj * random ()));
               if ((killer.skil < FALSE))
               {
                  killer.skil = FALSE;
               } //end if
            } //end if
         } //end if

         // ===== NEMESIS SYSTEM: Set Grudge =====
         // When a bot kills another bot, the victim holds a grudge for 30 seconds.
         // This creates revenge behavior and makes bot fights feel more personal.
         if ((killed.classname == "dmbot"))
         {
            killed.nemesis = killer;
            killed.nemesis_time = (time + 30.000);
         } //end if
         // ===== END NEMESIS SYSTEM =====
      } //end if
   } //end if
   if ((killed.classname == "player"))
   {
      killer.playerkills = (killer.playerkills + TRUE);

   } //end if
   else
   {
      if ((killed.classname == "dmbot"))
      {
         killer.botkills = (killer.botkills + TRUE);
      } //end if
   } //end if
}; //end of the function countkill

void (float sc) FPrintScore =
{
   local string fs;

   if (((sc > -10.000) && (sc < FALSE)))
   {
      sprint (self," ");

   } //end if
   else
   {
      if ((sc >= FALSE))
      {
         if ((sc < MUST_HAVE))
         {
            sprint (self," ");
         } //end if
         if ((sc < MOVETYPE_BOUNCE))
         {
            sprint (self," ");
         } //end if
      } //end if
   } //end if
   fs = ftos (sc);
   sprint (self,fs);
}; //end of the function FPrintScore
float (entity e) totalscore =
{
   local float sc;

   sc = ((FL_SWIM * ((e.playerkills + e.botkills) - e.suicides)) - (e.playerdeaths + e.botdeaths));
   return (sc);
}; //end of the function totalscore

void (entity e, float scoretype) PrintScoreFor =
{
   local float sc;

   FPrintScore (e.playerkills);
   sprint (self,"  ");
   FPrintScore (e.playerdeaths);
   sprint (self,"|");
   FPrintScore (e.botkills);
   sprint (self,"  ");
   FPrintScore (e.botdeaths);
   sprint (self,"|");
   FPrintScore (e.suicides);
   sprint (self," |");
   if ((scoretype == MYSCORE))
   {
      sc = totalscore (e);

   } //end if
   else
   {
      sc = e.frags;
   } //end if
   FPrintScore (sc);
   sprint (self," ");
   sprint (self,e.teamname);
   sprint (self,e.netname);
   sprint (self,"\n");
}; //end of the function PrintScoreFor
entity (float scoretype) SortPlayers =
{
   local entity e;
   local entity sort;
   local entity walk;
   local float es;
   local float ss;

   e = find (world,classname,"player");
   sort = world;
   while (e)
   {
      if (!sort)
      {
         sort = e;
         e.chain = world;

      } //end if
      else
      {
         if ((scoretype == MYSCORE))
         {
            es = totalscore (e);
            ss = totalscore (sort);

         } //end if
         else
         {
            es = e.frags;
            ss = sort.frags;
         } //end if
         if ((es > ss))
         {
            e.chain = sort;
            sort = e;

         } //end if
         else
         {
            walk = sort;
            ss = totalscore (walk.chain);
            do
            {
               if (!walk.chain)
               {
                  e.chain = world;
                  walk.chain = e;

               } //end if
               else
               {
                  if ((ss < es))
                  {
                     e.chain = walk.chain;
                     walk.chain = e;

                  } //end if
                  else
                  {
                     walk = walk.chain;
                  } //end if
               } //end if
            } while ((walk.chain != e));
         } //end if
      } //end if
      e = find (e,classname,"player");
   } //end while
   e = find (world,classname,"dmbot");
   while (e)
   {
      if (!sort)
      {
         sort = e;
         e.chain = world;

      } //end if
      else
      {
         if ((scoretype == MYSCORE))
         {
            es = totalscore (e);
            ss = totalscore (sort);

         } //end if
         else
         {
            es = e.frags;
            ss = sort.frags;
         } //end if
         if ((es > ss))
         {
            e.chain = sort;
            sort = e;

         } //end if
         else
         {
            walk = sort;
            do
            {
               ss = totalscore (walk.chain);
               if (!walk.chain)
               {
                  e.chain = world;
                  walk.chain = e;

               } //end if
               else
               {
                  if ((ss < es))
                  {
                     e.chain = walk.chain;
                     walk.chain = e;

                  } //end if
                  else
                  {
                     walk = walk.chain;
                  } //end if
               } //end if
            } while ((walk.chain != e));
         } //end if
      } //end if
      e = find (e,classname,"dmbot");
   } //end while
   return (sort);
}; //end of the function SortPlayers

void (float scoretype) PrintTopScores =
{
   local entity sort;
   local float i;

   if (world.chain)
   {
      error ("DumpScore: world.chain is set");
   } //end if
   sort = SortPlayers (NORMALSCORE);
   i = FALSE;
   while (sort)
   {
      i = (i + TRUE);
      sprint (self,sort.teamname);
      sprint (self,sort.netname);
      sprint (self,"  ");
      FPrintScore (sort.frags);
      sprint (self,"\n");
      sort = sort.chain;
      if ((i == MOVETYPE_WALK))
      {
         sort = world;
      } //end if
   } //end while
}; //end of the function PrintTopScores

void (float scoretype) PrintScores =
{
   local entity sort;

   if (world.chain)
   {
      error ("DumpScore: world.chain is set");
   } //end if
   sort = SortPlayers (scoretype);
   sprint (self,"Vs. Plyr|Vs. Bots|Suic|Score\n");
   sprint (self,"kill die|kill die|ides|\n");
   sprint (self,"_______________________________\n");
   while (sort)
   {
      PrintScoreFor (sort,scoretype);
      sort = sort.chain;
   } //end while
   sprint (self,"\n");
}; //end of the function PrintScores
