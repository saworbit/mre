
void (entity e, float newskin) skinChange = {

   local entity b;

   if ( !SKINSMODE ) {

      e.skin = FALSE;
      return ;

   }
   if ( (newskin < FALSE) ) {

      newskin = 15.000;

   }
   if ( (newskin > 15.000) ) {

      newskin = FALSE;

   }
   e.skin = newskin;
   if ( teamplay ) {

      if ( (e.classname == "player") ) {

         b = find (world,classname,"dmbot");
         while ( b ) {

            if ( (b.team == e.team) ) {

               b.skin = e.skin;

            }
            b = find (b,classname,"dmbot");

         }

      }

   }

};

void () removeSkins = {

   local entity e;

   SKINSMODE = FALSE;
   e = find (world,classname,"player");
   while ( e ) {

      e.skin = FALSE;
      e = find (e,classname,"player");

   }
   e = find (world,classname,"dmbot");
   while ( e ) {

      e.skin = FALSE;
      e = find (e,classname,"dmbot");

   }

};

void () setSkinsMode = {

   if ( (SKINSMODE == FL_SWIM) ) {

      removeSkins ();
      dprint ("Skins mode turned off\n");
      return ;

   }
   SKINSMODE = (SKINSMODE + TRUE);
   if ( (SKINSMODE == TRUE) ) {

      dprint ("Skins mode activated\n");

   } else {

      dprint ("Skill-based skins mode activated\n");

   }

};

void () Peeper = {

   dprint ("Make ");
   dprint (self.netname);
   dprint (" an observer\n");
   self.classname = "peeper";
   self.frame = FALSE;
   self.modelindex = modelindex_eyes;
   self.takedamage = DAMAGE_NO;

};

void () NoPeeper = {

   dprint (self.netname);
   dprint (" back to normal\n");
   self.classname = "player";
   self.modelindex = modelindex_player;
   self.takedamage = DAMAGE_AIM;

};

void () setPeeperMode = {

   if ( (self.classname == "peeper") ) {

      NoPeeper ();
      return ;

   }
   Peeper ();

};

void () setVerboseMode = {

   VERBOSEBOT = !VERBOSEBOT;

};

void () setNamingMode = {

   NAMEBOTS = !NAMEBOTS;

};

void () botRestrictedCommand = {

   local string tmp;

   if ( (self.impulse == 202.000) ) {

      setSkinsMode ();

   } else {

      if ( (self.impulse == 205.000) ) {

         AddAnotherBot ();

      } else {

         if ( ((self.impulse > 99.000) && (self.impulse < 116.000)) ) {

            if ( teamplay ) {

               SetTeamBots ((self.impulse - MUST_HAVE));

            } else {

               SetMaxBots ((self.impulse - MUST_HAVE));

            }

         } else {

            if ( (self.impulse == 208.000) ) {

               AddAnotherBot ();
               AddAnotherBot ();
               AddAnotherBot ();
               AddAnotherBot ();

            } else {

               if ( (self.impulse == 211.000) ) {

                  removeAllBots ();

               } else {

                  if ( (self.impulse == 212.000) ) {

                     setPeeperMode ();

                  } else {

                     if ( (self.impulse == 214.000) ) {

                        setBotGravity ();

                     } else {

                        if ( (self.impulse == 215.000) ) {

                           setVerboseMode ();

                        } else {

                           if ( (self.impulse == 217.000) ) {

                              tmp = ftos (NUMPATHS);
                              dprint (tmp);
                              dprint (" botpaths placed\n");

                           } else {

                              if ( (self.impulse == 117.000) ) {

                                 tmp = ftos (NUMPATHERS);
                                 dprint (tmp);
                                 dprint (" botpathers\n");

                              } else {

                                 if ( (self.impulse == 118.000) ) {

                                    tmp = ftos (NUMBOTS);
                                    dprint (tmp);
                                    dprint (" active bots\n");

                                 } else {

                                    if ( (self.impulse == 119.000) ) {

                                       tmp = ftos (serverflags);
                                       dprint (tmp);
                                       dprint (" server flags\n");

                                    } else {

                                       if ( (self.impulse == 218.000) ) {

                                          serverflags = (serverflags | RESTRICT);
                                          dprint ("Restricted mode set\n");

                                       } else {

                                          if ( (self.impulse == 219.000) ) {

                                             serverflags = (serverflags | SUPERRESTRICT);
                                             dprint ("Super Restricted mode set\n");

                                          }

                                       }

                                    }

                                 }

                              }

                           }

                        }

                     }

                  }

               }

            }

         }

      }

   }

};

void () botImpulseCommand = {

   // FIX: impulse 100 = quick add bot (standard convention from Frogbot, etc.)
   if ( (self.impulse == 100) ) {

      AddAnotherBot ();

   } else if ( (self.impulse == 200.000) ) {

      skinChange (self,(self.skin + TRUE));

   } else {

      if ( (self.impulse == 201.000) ) {

         skinChange (self,(self.skin - TRUE));

      } else {

         if ( (self.impulse == 204.000) ) {

            printIntro ();

         } else {

            if ( (self.impulse == 210.000) ) {

               PrintScores (MYSCORE);

            } else {

               if ( (self.impulse == 220.000) ) {

                  PrintScores (NORMALSCORE);

               } else {

                  if ( (self.impulse == 221.000) ) {

                     UpdateTeamColors ();

                  } else {

                     if ( (self.impulse == 222.000) ) {

                        PrintTopScores ();

                     } else {

                        if ( (self.impulse == 223.000) ) {

                           self.items = (self.items | IT_INVULNERABILITY);
                           self.invincible_finished = (time + SVC_INTERMISSION);

                        } else {

                           if ( !(serverflags & SUPERRESTRICT) ) {

                              if ( (!(serverflags & RESTRICT) || (self.colormap == TRUE)) ) {

                                 botRestrictedCommand ();

                              }

                           }

                        }

                     }

                  }

               }

            }

         }

      }

   }

};
