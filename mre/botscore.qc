
void () initscore = {

   self.playerkills = FALSE;
   self.playerdeaths = FALSE;
   self.botkills = FALSE;
   self.botdeaths = FALSE;
   self.suicides = FALSE;

};

void (entity killer, entity killed) countkill = {

   local float adj;

   if ( (skill == TRUE) ) {

      adj = 0.800;
      if ( ((killed.playerdeaths + killed.botdeaths) > MOVETYPE_BOUNCE) ) {

         adj = 0.400;

      }
      if ( ((killed.playerdeaths + killed.botdeaths) > KINDA_WANT) ) {

         adj = 0.150;

      }

   }
   if ( (killer == killed) ) {

      killer.suicides = (killer.suicides + TRUE);
      return ;

   }
   if ( (killer.classname == "player") ) {

      killed.playerdeaths = (killed.playerdeaths + TRUE);
      if ( (skill == TRUE) ) {

         if ( (killed.classname == "dmbot") ) {

            killed.skil = (killed.skil + (adj * random ()));
            if ( (killed.skil > MOVETYPE_WALK) ) {

               killed.skil = MOVETYPE_WALK;

            }

         }

      }

   } else {

      if ( (killer.classname == "dmbot") ) {

         killed.botdeaths = (killed.botdeaths + TRUE);
         if ( (skill == TRUE) ) {

            if ( (killed.classname == "player") ) {

               killer.skil = (killer.skil - (adj * random ()));
               if ( (killer.skil < FALSE) ) {

                  killer.skil = FALSE;

               }

            }

         }

      }

   }
   if ( (killed.classname == "player") ) {

      killer.playerkills = (killer.playerkills + TRUE);

   } else {

      if ( (killed.classname == "dmbot") ) {

         killer.botkills = (killer.botkills + TRUE);

      }

   }

};

void (float sc) FPrintScore = {

   local string fs;

   if ( ((sc > -10.000) && (sc < FALSE)) ) {

      sprint (self," ");

   } else {

      if ( (sc >= FALSE) ) {

         if ( (sc < MUST_HAVE) ) {

            sprint (self," ");

         }
         if ( (sc < MOVETYPE_BOUNCE) ) {

            sprint (self," ");

         }

      }

   }
   fs = ftos (sc);
   sprint (self,fs);

};
float (entity e) totalscore = {

   local float sc;

   sc = ((FL_SWIM * ((e.playerkills + e.botkills) - e.suicides)) - (e.playerdeaths + e.botdeaths));
   return ( sc );

};

void (entity e, float scoretype) PrintScoreFor = {

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
   if ( (scoretype == MYSCORE) ) {

      sc = totalscore (e);

   } else {

      sc = e.frags;

   }
   FPrintScore (sc);
   sprint (self," ");
   sprint (self,e.teamname);
   sprint (self,e.netname);
   sprint (self,"\n");

};
entity (float scoretype) SortPlayers = {

   local entity e;
   local entity sort;
   local entity walk;
   local float es;
   local float ss;

   e = find (world,classname,"player");
   sort = world;
   while ( e ) {

      if ( !sort ) {

         sort = e;
         e.chain = world;

      } else {

         if ( (scoretype == MYSCORE) ) {

            es = totalscore (e);
            ss = totalscore (sort);

         } else {

            es = e.frags;
            ss = sort.frags;

         }
         if ( (es > ss) ) {

            e.chain = sort;
            sort = e;

         } else {

            walk = sort;
            ss = totalscore (walk.chain);
            do {

               if ( !walk.chain ) {

                  e.chain = world;
                  walk.chain = e;

               } else {

                  if ( (ss < es) ) {

                     e.chain = walk.chain;
                     walk.chain = e;

                  } else {

                     walk = walk.chain;

                  }

               }

            } while ( (walk.chain != e) );

         }

      }
      e = find (e,classname,"player");

   }
   e = find (world,classname,"dmbot");
   while ( e ) {

      if ( !sort ) {

         sort = e;
         e.chain = world;

      } else {

         if ( (scoretype == MYSCORE) ) {

            es = totalscore (e);
            ss = totalscore (sort);

         } else {

            es = e.frags;
            ss = sort.frags;

         }
         if ( (es > ss) ) {

            e.chain = sort;
            sort = e;

         } else {

            walk = sort;
            do {

               ss = totalscore (walk.chain);
               if ( !walk.chain ) {

                  e.chain = world;
                  walk.chain = e;

               } else {

                  if ( (ss < es) ) {

                     e.chain = walk.chain;
                     walk.chain = e;

                  } else {

                     walk = walk.chain;

                  }

               }

            } while ( (walk.chain != e) );

         }

      }
      e = find (e,classname,"dmbot");

   }
   return ( sort );

};

void (float scoretype) PrintTopScores = {

   local entity sort;
   local float i;

   if ( world.chain ) {

      error ("DumpScore: world.chain is set");

   }
   sort = SortPlayers (NORMALSCORE);
   i = FALSE;
   while ( sort ) {

      i = (i + TRUE);
      sprint (self,sort.teamname);
      sprint (self,sort.netname);
      sprint (self,"  ");
      FPrintScore (sort.frags);
      sprint (self,"\n");
      sort = sort.chain;
      if ( (i == MOVETYPE_WALK) ) {

         sort = world;

      }

   }

};

void (float scoretype) PrintScores = {

   local entity sort;

   if ( world.chain ) {

      error ("DumpScore: world.chain is set");

   }
   sort = SortPlayers (scoretype);
   sprint (self,"Vs. Plyr|Vs. Bots|Suic|Score\n");
   sprint (self,"kill die|kill die|ides|\n");
   sprint (self,"_______________________________\n");
   while ( sort ) {

      PrintScoreFor (sort,scoretype);
      sort = sort.chain;

   }
   sprint (self,"\n");

};
