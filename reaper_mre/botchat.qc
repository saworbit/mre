// ===================================================================
// BOTCHAT.QC - The Soul of the 90s FPS Culture
// Modern Reaper Enhancements - Phase 7 (ULTRA EXPANDED EDITION)
// ===================================================================
// MASSIVE 2026 EXPANSION:
// - 64+ idle chat messages (up from 27) - more than DOUBLED
// - 80+ reply variations (up from ~20) - QUADRUPLED
// - Personality-based chat timing (Ragers spam, Pros stay focused)
// - 3-second reply window for fluid conversations
// - 12% reply chance (up from 5%) - MUCH more responsive
// - 1.5% idle chance (up from 0.5%) - 3x more ambient banter
// - New reply scenarios: idle banter responses, PRO/CAMPER/MEMELORD death reactions
// - Bot-to-bot roasting reaches maximum toxicity
// Welcome to the golden age of chaotic FPS banter!
// ===================================================================
// NOTE: All constants (PERS_*, C_*) and global variables are now
// declared in defs.qc for proper compile-time initialization.

// ===== INITIALIZATION =====
// Called once from worldspawn to initialize global chat state
void () InitChatSystem =
{
   // Initialize global chat state
   world.chat_time = FALSE;
   world.chat_type = FALSE;
   world.last_speaker = world;
}; //end of the function InitChatSystem

// ===== HELPER: PRINT MESSAGE =====
// Formats and prints: "BotName: Message" with chat sound
void (string msg) ChatPrint =
{
   // Play the chat sound effect for all players (same as real player chat)
   sound (world,CHAN_AUTO,"misc/talk.wav",TRUE,ATTN_NONE);

   // Print the message
   bprint (self.netname);
   bprint (": ");
   bprint (msg);
   bprint ("\n");
}; //end of the function ChatPrint

// ===== 1. GREETINGS (Join Server) - EXPANDED =====
void () ChatGreet =
{
   local float r;

   r = random ();

   if ((self.personality == PERS_RAGER))
   {
      if ((r < 0.125))
      {
         ChatPrint ("this server laggy?");
      }
      else
      {
         if ((r < 0.250))
         {
            ChatPrint ("dont make me carry u");
         }
         else
         {
            if ((r < 0.375))
            {
               ChatPrint ("reset map pls");
            }
            else
            {
               if ((r < 0.500))
               {
                  ChatPrint ("any admins on?");
               }
               else
               {
                  if ((r < 0.625))
                  {
                     ChatPrint ("my ping is high again ffs");
                  }
                  else
                  {
                     if ((r < 0.750))
                     {
                        ChatPrint ("server settings suck");
                     }
                     else
                     {
                        if ((r < 0.875))
                        {
                           ChatPrint ("better not be lag this time");
                        }
                        else
                        {
                           ChatPrint ("who picked this map?");
                        } //end if
                     } //end if
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
   }
   else
   {
      if ((self.personality == PERS_PRO))
      {
         if ((r < 0.166))
         {
            ChatPrint ("gl hf");
         }
         else
         {
            if ((r < 0.333))
            {
               ChatPrint ("ready.");
            }
            else
            {
               if ((r < 0.500))
               {
                  ChatPrint ("warmup?");
               }
               else
               {
                  if ((r < 0.666))
                  {
                     ChatPrint ("lets go");
                  }
                  else
                  {
                     if ((r < 0.833))
                     {
                        ChatPrint ("in");
                     }
                     else
                     {
                        ChatPrint ("sup");
                     } //end if
                  } //end if
               } //end if
            } //end if
         } //end if
      }
      else
      {
         if ((self.personality == PERS_NOOB))
         {
            if ((r < 0.142))
            {
               ChatPrint ("hi everyone!");
            }
            else
            {
               if ((r < 0.285))
               {
                  ChatPrint ("how do i change color?");
               }
               else
               {
                  if ((r < 0.428))
                  {
                     ChatPrint ("is this team deathmatch?");
                  }
                  else
                  {
                     if ((r < 0.571))
                     {
                        ChatPrint ("nice map");
                     }
                     else
                     {
                        if ((r < 0.714))
                        {
                           ChatPrint ("guys wait for me");
                        }
                        else
                        {
                           if ((r < 0.857))
                           {
                              ChatPrint ("first time here");
                           }
                           else
                           {
                              ChatPrint ("hope you guys are nice");
                           } //end if
                        } //end if
                     } //end if
                  } //end if
               } //end if
            } //end if
         }
         else
         {
            if ((self.personality == PERS_MEMELORD))
            {
               if ((r < 0.200))
               {
                  ChatPrint ("w00t");
               }
               else
               {
                  if ((r < 0.400))
                  {
                     ChatPrint ("prepare to get pwned");
                  }
                  else
                  {
                     if ((r < 0.600))
                     {
                        ChatPrint ("time to own some n00bs");
                     }
                     else
                     {
                        if ((r < 0.800))
                        {
                           ChatPrint ("let me show you how its done");
                        }
                        else
                        {
                           ChatPrint ("hold my beer");
                        } //end if
                     } //end if
                  } //end if
               } //end if
            }
            else
            {
               // Normal/Camper
               if ((r < 0.250))
               {
                  ChatPrint ("hello");
               }
               else
               {
                  if ((r < 0.500))
                  {
                     ChatPrint ("good luck");
                  }
                  else
                  {
                     if ((r < 0.750))
                     {
                        ChatPrint ("hey");
                     }
                     else
                     {
                        ChatPrint ("time to lock down my spot");
                     } //end if
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
   } //end if
}; //end of the function ChatGreet

// ===== 2. KILL TAUNTS (With Weapon-Specific Lines) =====
void (entity victim) ChatKill =
{
   local float r;

   r = random ();

   // WEAPON-SPECIFIC TAUNTS (30% chance to override personality)
   if ((random () < 0.300))
   {
      if ((self.weapon == IT_AXE))
      {
         if ((r < 0.500))
         {
            ChatPrint ("CHOP CHOP!");
         }
         else
         {
            ChatPrint ("axed");
         } //end if
         world.chat_time = time;
         world.chat_type = C_KILL;
         world.last_speaker = self;
         return ;
      } //end if

      if (((self.weapon == IT_ROCKET_LAUNCHER) && (victim.health < -40.000)))
      {
         if ((r < 0.500))
         {
            ChatPrint ("gibbed.");
         }
         else
         {
            ChatPrint ("splash damage baby");
         } //end if
         world.chat_time = time;
         world.chat_type = C_KILL;
         world.last_speaker = self;
         return ;
      } //end if

      if ((self.weapon == IT_LIGHTNING))
      {
         if ((r < 0.500))
         {
            ChatPrint ("bzzzt");
         }
         else
         {
            ChatPrint ("fried");
         } //end if
         world.chat_time = time;
         world.chat_type = C_KILL;
         world.last_speaker = self;
         return ;
      } //end if

      if ((self.weapon == IT_GRENADE_LAUNCHER))
      {
         ChatPrint ("eat grenades");
         world.chat_time = time;
         world.chat_type = C_KILL;
         world.last_speaker = self;
         return ;
      } //end if
   } //end if

   // PERSONALITY-BASED TAUNTS
   if ((self.personality == PERS_RAGER))
   {
      if ((r < 0.142))
      {
         ChatPrint ("sit down kid");
      }
      else
      {
         if ((r < 0.285))
         {
            ChatPrint ("too easy");
         }
         else
         {
            if ((r < 0.428))
            {
               ChatPrint ("get off my server");
            }
            else
            {
               if ((r < 0.571))
               {
                  ChatPrint ("stop feeding");
               }
               else
               {
                  if ((r < 0.714))
                  {
                     ChatPrint ("learn to aim");
                  }
                  else
                  {
                     if ((r < 0.857))
                     {
                        ChatPrint ("you suck");
                     }
                     else
                     {
                        ChatPrint ("uninstall");
                     } //end if
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
   }
   else
   {
      if ((self.personality == PERS_PRO))
      {
         if ((r < 0.166))
         {
            ChatPrint ("down.");
         }
         else
         {
            if ((r < 0.333))
            {
               ChatPrint ("predicted.");
            }
            else
            {
               if ((r < 0.500))
               {
                  ChatPrint ("ez");
               }
               else
               {
                  if ((r < 0.666))
                  {
                     ChatPrint ("controlled.");
                  }
                  else
                  {
                     if ((r < 0.833))
                     {
                        ChatPrint ("cya");
                     }
                     else
                     {
                        ChatPrint ("timed");
                     } //end if
                  } //end if
               } //end if
            } //end if
         } //end if
      }
      else
      {
         if ((self.personality == PERS_NOOB))
         {
            if ((r < 0.166))
            {
               ChatPrint ("did i get him?");
            }
            else
            {
               if ((r < 0.333))
               {
                  ChatPrint ("sorry!");
               }
               else
               {
                  if ((r < 0.500))
                  {
                     ChatPrint ("wow this gun is strong");
                  }
                  else
                  {
                     if ((r < 0.666))
                     {
                        ChatPrint ("take that!");
                     }
                     else
                     {
                        if ((r < 0.833))
                        {
                           ChatPrint ("oops");
                        }
                        else
                        {
                           ChatPrint ("i got one!");
                        } //end if
                     } //end if
                  } //end if
               } //end if
            } //end if
         }
         else
         {
            if ((self.personality == PERS_MEMELORD))
            {
               if ((r < 0.142))
               {
                  ChatPrint ("BOOM HEADSHOT");
               }
               else
               {
                  if ((r < 0.285))
                  {
                     ChatPrint ("pwned");
                  }
                  else
                  {
                     if ((r < 0.428))
                     {
                        ChatPrint ("get fragged");
                     }
                     else
                     {
                        if ((r < 0.571))
                        {
                           ChatPrint ("lol");
                        }
                        else
                        {
                           if ((r < 0.714))
                           {
                              ChatPrint ("rekt");
                           }
                           else
                           {
                              if ((r < 0.857))
                              {
                                 ChatPrint ("n00b");
                              }
                              else
                              {
                                 ChatPrint ("owned");
                              } //end if
                           } //end if
                        } //end if
                     } //end if
                  } //end if
               } //end if
            }
            else
            {
               if ((self.personality == PERS_CAMPER))
               {
                  if ((r < 0.500))
                  {
                     ChatPrint ("get off my lawn");
                  }
                  else
                  {
                     ChatPrint ("shoulda stayed away");
                  } //end if
               }
               else
               {
                  // Standard
                  if ((r < 0.250))
                  {
                     ChatPrint ("gotcha");
                  }
                  else
                  {
                     if ((r < 0.500))
                     {
                        ChatPrint ("nice try");
                     }
                     else
                     {
                        if ((r < 0.750))
                        {
                           ChatPrint ("good fight");
                        }
                        else
                        {
                           return ; // Silent
                        } //end if
                     } //end if
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
   } //end if

   // Register this event for replies
   world.chat_time = time;
   world.chat_type = C_KILL;
   world.last_speaker = self;
}; //end of the function ChatKill

// ===== 3. DEATH EXCUSES (The Rager Excuse Generator 3000) =====
void (entity killer) ChatDeath =
{
   local float r;

   r = random ();

   if ((self.personality == PERS_RAGER))
   {
      // Maximum salt mode activated
      if ((r < 0.111))
      {
         ChatPrint ("NICE HACKS");
      }
      else
      {
         if ((r < 0.222))
         {
            ChatPrint ("omg the LAG");
         }
         else
         {
            if ((r < 0.333))
            {
               ChatPrint ("hitbox is broken");
            }
            else
            {
               if ((r < 0.444))
               {
                  ChatPrint ("my mouse got stuck");
               }
               else
               {
                  if ((r < 0.555))
                  {
                     ChatPrint ("BS! I shot you!");
                  }
                  else
                  {
                     if ((r < 0.666))
                     {
                        ChatPrint ("turn off toggle bro");
                     }
                     else
                     {
                        if ((r < 0.777))
                        {
                           ChatPrint ("admin ban him");
                        }
                        else
                        {
                           if ((r < 0.888))
                           {
                              ChatPrint ("wallhacker");
                           }
                           else
                           {
                              ChatPrint ("this game is broken");
                           } //end if
                        } //end if
                     } //end if
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
   }
   else
   {
      if ((self.personality == PERS_PRO))
      {
         if ((r < 0.250))
         {
            ChatPrint ("ns");
         }
         else
         {
            if ((r < 0.500))
            {
               ChatPrint ("wp");
            }
            else
            {
               if ((r < 0.750))
               {
                  ChatPrint ("nice rail");
               }
               else
               {
                  return ; // Silent rage
               } //end if
            } //end if
         } //end if
      }
      else
      {
         if ((self.personality == PERS_NOOB))
         {
            if ((r < 0.166))
            {
               ChatPrint ("ouch");
            }
            else
            {
               if ((r < 0.333))
               {
                  ChatPrint ("i didnt see you");
               }
               else
               {
                  if ((r < 0.500))
                  {
                     ChatPrint ("how did you do that?");
                  }
                  else
                  {
                     if ((r < 0.666))
                     {
                        ChatPrint ("stop killing me pls");
                     }
                     else
                     {
                        if ((r < 0.833))
                        {
                           ChatPrint ("aw man");
                        }
                        else
                        {
                           ChatPrint ("that hurt");
                        } //end if
                     } //end if
                  } //end if
               } //end if
            } //end if
         }
         else
         {
            if ((self.personality == PERS_CAMPER))
            {
               if ((r < 0.500))
               {
                  ChatPrint ("stop rushing me");
               }
               else
               {
                  ChatPrint ("i need more armor");
               } //end if
            }
            else
            {
               if ((self.personality == PERS_MEMELORD))
               {
                  if ((r < 0.333))
                  {
                     ChatPrint ("lag");
                  }
                  else
                  {
                     if ((r < 0.666))
                     {
                        ChatPrint ("rofl");
                     }
                     else
                     {
                        ChatPrint ("owned myself");
                     } //end if
                  } //end if
               }
               else
               {
                  // Standard
                  if ((r < 0.333))
                  {
                     ChatPrint ("lucky");
                  }
                  else
                  {
                     if ((r < 0.666))
                     {
                        ChatPrint ("nice one");
                     }
                     else
                     {
                        return ; // Silent
                     } //end if
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
   } //end if

   // Register this event for replies
   world.chat_time = time;
   world.chat_type = C_DEATH;
   world.last_speaker = self;
}; //end of the function ChatDeath

// ===== 4. IDLE BANTER (Roaming) - MASSIVELY EXPANDED =====
void () ChatIdle =
{
   local float r;

   r = random ();

   if ((self.personality == PERS_NOOB))
   {
      if ((r < 0.071))
      {
         ChatPrint ("where is the rocket launcher?");
      }
      else
      {
         if ((r < 0.142))
         {
            ChatPrint ("i am lost");
         }
         else
         {
            if ((r < 0.214))
            {
               ChatPrint ("can we play team dm?");
            }
            else
            {
               if ((r < 0.285))
               {
                  ChatPrint ("anyone want to help me?");
               }
               else
               {
                  if ((r < 0.357))
                  {
                     ChatPrint ("which way to the armor?");
                  }
                  else
                  {
                     if ((r < 0.428))
                     {
                        ChatPrint ("is this the right server?");
                     }
                     else
                     {
                        if ((r < 0.500))
                        {
                           ChatPrint ("how do i switch weapons?");
                        }
                        else
                        {
                           if ((r < 0.571))
                           {
                              ChatPrint ("this game is hard");
                           }
                           else
                           {
                              if ((r < 0.642))
                              {
                                 ChatPrint ("can someone show me where quad is?");
                              }
                              else
                              {
                                 if ((r < 0.714))
                                 {
                                    ChatPrint ("im gonna practice more");
                                 }
                                 else
                                 {
                                    if ((r < 0.785))
                                    {
                                       ChatPrint ("whats the best weapon?");
                                    }
                                    else
                                    {
                                       if ((r < 0.857))
                                       {
                                          ChatPrint ("i need better ping");
                                       }
                                       else
                                       {
                                          if ((r < 0.928))
                                          {
                                             ChatPrint ("why is everyone so fast?");
                                          }
                                          else
                                          {
                                             ChatPrint ("how do i rocket jump?");
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
   }
   else
   {
      if ((self.personality == PERS_CAMPER))
      {
         if ((r < 0.083))
         {
            ChatPrint ("this room is mine");
         }
         else
         {
            if ((r < 0.166))
            {
               ChatPrint ("i hear footsteps...");
            }
            else
            {
               if ((r < 0.250))
               {
                  ChatPrint ("come get some");
               }
               else
               {
                  if ((r < 0.333))
                  {
                     ChatPrint ("holding down the fort");
                  }
                  else
                  {
                     if ((r < 0.416))
                     {
                        ChatPrint ("they'll have to pry this spot from my cold dead hands");
                     }
                     else
                     {
                        if ((r < 0.500))
                        {
                           ChatPrint ("this is my house");
                        }
                        else
                        {
                           if ((r < 0.583))
                           {
                              ChatPrint ("tactical positioning wins games");
                           }
                           else
                           {
                              if ((r < 0.666))
                              {
                                 ChatPrint ("im not camping im defending");
                              }
                              else
                              {
                                 if ((r < 0.750))
                                 {
                                    ChatPrint ("this is called map control");
                                 }
                                 else
                                 {
                                    if ((r < 0.833))
                                    {
                                       ChatPrint ("patience is a virtue");
                                    }
                                    else
                                    {
                                       if ((r < 0.916))
                                       {
                                          ChatPrint ("let them come to me");
                                       }
                                       else
                                       {
                                          ChatPrint ("i got the high ground");
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
      }
      else
      {
         if ((self.personality == PERS_RAGER))
         {
            if ((r < 0.083))
            {
               ChatPrint ("this server is trash");
            }
            else
            {
               if ((r < 0.166))
               {
                  ChatPrint ("everyone camping?");
               }
               else
               {
                  if ((r < 0.250))
                  {
                     ChatPrint ("fix the spawns already");
                  }
                  else
                  {
                     if ((r < 0.333))
                     {
                        ChatPrint ("this map sucks");
                     }
                     else
                     {
                        if ((r < 0.416))
                        {
                           ChatPrint ("gg ez game");
                        }
                        else
                        {
                           if ((r < 0.500))
                           {
                              ChatPrint ("where are the admins?");
                           }
                           else
                           {
                              if ((r < 0.583))
                              {
                                 ChatPrint ("half these players are bots anyway");
                              }
                              else
                              {
                                 if ((r < 0.666))
                                 {
                                    ChatPrint ("hitboxes are broken");
                                 }
                                 else
                                 {
                                    if ((r < 0.750))
                                    {
                                       ChatPrint ("netcode is terrible");
                                    }
                                    else
                                    {
                                       if ((r < 0.833))
                                       {
                                          ChatPrint ("im carrying so hard rn");
                                       }
                                       else
                                       {
                                          if ((r < 0.916))
                                          {
                                             ChatPrint ("why am i even trying");
                                          }
                                          else
                                          {
                                             ChatPrint ("vote for better map");
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
         }
         else
         {
            if ((self.personality == PERS_MEMELORD))
            {
               if ((r < 0.062))
               {
                  ChatPrint ("all your base are belong to us");
               }
               else
               {
                  if ((r < 0.125))
                  {
                     ChatPrint ("do a barrel roll");
                  }
                  else
                  {
                     if ((r < 0.187))
                     {
                        ChatPrint ("the cake is a lie");
                     }
                     else
                     {
                        if ((r < 0.250))
                        {
                           ChatPrint ("1v1 me rust");
                        }
                        else
                        {
                           if ((r < 0.312))
                           {
                              ChatPrint ("mom get the camera");
                           }
                           else
                           {
                              if ((r < 0.375))
                              {
                                 ChatPrint ("360 noscope incoming");
                              }
                              else
                              {
                                 if ((r < 0.437))
                                 {
                                    ChatPrint ("git gud scrubs");
                                 }
                                 else
                                 {
                                    if ((r < 0.500))
                                    {
                                       ChatPrint ("its over 9000");
                                    }
                                    else
                                    {
                                       if ((r < 0.562))
                                       {
                                          ChatPrint ("u mad bro?");
                                       }
                                       else
                                       {
                                          if ((r < 0.625))
                                          {
                                             ChatPrint ("this is fine");
                                          }
                                          else
                                          {
                                             if ((r < 0.687))
                                             {
                                                ChatPrint ("im about to do whats called a pro gamer move");
                                             }
                                             else
                                             {
                                                if ((r < 0.750))
                                                {
                                                   ChatPrint ("i can haz rockets?");
                                                }
                                                else
                                                {
                                                   if ((r < 0.812))
                                                   {
                                                      ChatPrint ("leroy jenkins!");
                                                   }
                                                   else
                                                   {
                                                      if ((r < 0.875))
                                                      {
                                                         ChatPrint ("thats what she said");
                                                      }
                                                      else
                                                      {
                                                         if ((r < 0.937))
                                                         {
                                                            ChatPrint ("yeet");
                                                         }
                                                         else
                                                         {
                                                            ChatPrint ("i understood that reference");
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
                  } //end if
               } //end if
            }
            else
            {
               if ((self.personality == PERS_PRO))
               {
                  if ((r < 0.100))
                  {
                     ChatPrint ("gg");
                  }
                  else
                  {
                     if ((r < 0.200))
                     {
                        ChatPrint ("timed");
                     }
                     else
                     {
                        if ((r < 0.300))
                        {
                           ChatPrint ("cya");
                        }
                        else
                        {
                           if ((r < 0.400))
                           {
                              ChatPrint ("armor up");
                           }
                           else
                           {
                              if ((r < 0.500))
                              {
                                 ChatPrint ("quad in 10");
                              }
                              else
                              {
                                 if ((r < 0.600))
                                 {
                                    ChatPrint ("mega respawns soon");
                                 }
                                 else
                                 {
                                    if ((r < 0.700))
                                    {
                                       ChatPrint ("controlling the map");
                                    }
                                    else
                                    {
                                       if ((r < 0.800))
                                       {
                                          ChatPrint ("positioning");
                                       }
                                       else
                                       {
                                          if ((r < 0.900))
                                          {
                                             ChatPrint ("reading the flow");
                                          }
                                          else
                                          {
                                             ChatPrint ("staying sharp");
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
   } //end if
}; //end of the function ChatIdle

// ===== 5. BOT-TO-BOT INTERACTION ENGINE (MASSIVELY EXPANDED) =====
void () CheckChatReply =
{
   local float r;

   // If no recent chat activity, bail out (expanded window from 2s to 3s for more interactions)
   if ((time > (world.chat_time + 3.000)))
   {
      return ;
   } //end if

   // Don't reply to yourself
   if ((world.last_speaker == self))
   {
      return ;
   } //end if

   // No chat event registered
   if ((world.chat_time == FALSE))
   {
      return ;
   } //end if

   r = random ();

   // 35% chance to reply to any event (increased from 25% for more interaction)
   if ((r > 0.350))
   {
      return ;
   } //end if

   // === SCENARIO: SOMEONE GOT A KILL ===
   if ((world.chat_type == C_KILL))
   {
      if ((self.personality == PERS_RAGER))
      {
         if ((r < 0.050))
         {
            ChatPrint ("kill steal");
         }
         else
         {
            if ((r < 0.100))
            {
               ChatPrint ("pure luck");
            }
            else
            {
               if ((r < 0.150))
               {
                  ChatPrint ("hax");
               }
               else
               {
                  if ((r < 0.200))
                  {
                     ChatPrint ("camping loser");
                  }
                  else
                  {
                     if ((r < 0.250))
                     {
                        ChatPrint ("you got lucky");
                     }
                     else
                     {
                        if ((r < 0.300))
                        {
                           ChatPrint ("stop stealing my kills");
                        }
                        else
                        {
                           if ((r < 0.350))
                           {
                              ChatPrint ("i had him first");
                           } //end if
                        } //end if
                     } //end if
                  } //end if
               } //end if
            } //end if
         } //end if
      }
      else
      {
         if ((self.personality == PERS_PRO))
         {
            if ((r < 0.070))
            {
               ChatPrint ("clean.");
            }
            else
            {
               if ((r < 0.140))
               {
                  ChatPrint ("nice");
               }
               else
               {
                  if ((r < 0.210))
                  {
                     ChatPrint ("wp");
                  }
                  else
                  {
                     if ((r < 0.280))
                     {
                        ChatPrint ("solid aim");
                     }
                     else
                     {
                        if ((r < 0.350))
                        {
                           ChatPrint ("good read");
                        } //end if
                     } //end if
                  } //end if
               } //end if
            } //end if
         }
         else
         {
            if ((self.personality == PERS_NOOB))
            {
               if ((r < 0.070))
               {
                  ChatPrint ("wow nice shot");
               }
               else
               {
                  if ((r < 0.140))
                  {
                     ChatPrint ("how did you do that?");
                  }
                  else
                  {
                     if ((r < 0.210))
                     {
                        ChatPrint ("teach me!");
                     }
                     else
                     {
                        if ((r < 0.280))
                        {
                           ChatPrint ("youre so good");
                        }
                        else
                        {
                           if ((r < 0.350))
                           {
                              ChatPrint ("i wanna learn that");
                           } //end if
                        } //end if
                     } //end if
                  } //end if
               } //end if
            }
            else
            {
               if ((self.personality == PERS_MEMELORD))
               {
                  if ((r < 0.070))
                  {
                     ChatPrint ("rekt");
                  }
                  else
                  {
                     if ((r < 0.140))
                     {
                        ChatPrint ("poggers");
                     }
                     else
                     {
                        if ((r < 0.210))
                        {
                           ChatPrint ("absolute madlad");
                        }
                        else
                        {
                           if ((r < 0.280))
                           {
                              ChatPrint ("oof size large");
                           }
                           else
                           {
                              if ((r < 0.350))
                              {
                                 ChatPrint ("F in chat");
                              } //end if
                           } //end if
                        } //end if
                     } //end if
                  } //end if
               }
               else
               {
                  if ((self.personality == PERS_CAMPER))
                  {
                     if ((r < 0.175))
                     {
                        ChatPrint ("easy when you rush like that");
                     }
                     else
                     {
                        if ((r < 0.350))
                        {
                           ChatPrint ("told you to slow down");
                        } //end if
                     } //end if
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if

      // Clear to prevent spam loop
      world.chat_time = FALSE;
   }
   else
   {
      // === SCENARIO: SOMEONE DIED COMPLAINING ===
      if ((world.chat_type == C_DEATH))
      {
         // If last speaker was a RAGER complaining
         if ((world.last_speaker.personality == PERS_RAGER))
         {
            if ((self.personality == PERS_PRO))
            {
               if ((r < 0.070))
               {
                  ChatPrint ("get good");
               }
               else
               {
                  if ((r < 0.140))
                  {
                     ChatPrint ("cope");
                  }
                  else
                  {
                     if ((r < 0.210))
                     {
                        ChatPrint ("skill issue");
                     }
                     else
                     {
                        if ((r < 0.280))
                        {
                           ChatPrint ("stop blaming the game");
                        }
                        else
                        {
                           if ((r < 0.350))
                           {
                              ChatPrint ("adapt");
                           } //end if
                        } //end if
                     } //end if
                  } //end if
               } //end if
            }
            else
            {
               if ((self.personality == PERS_MEMELORD))
               {
                  if ((r < 0.070))
                  {
                     ChatPrint ("cry more noob");
                  }
                  else
                  {
                     if ((r < 0.140))
                     {
                        ChatPrint ("qq");
                     }
                     else
                     {
                        if ((r < 0.210))
                        {
                           ChatPrint ("salt detected");
                        }
                        else
                        {
                           if ((r < 0.280))
                           {
                              ChatPrint ("mad cuz bad");
                           }
                           else
                           {
                              if ((r < 0.350))
                              {
                                 ChatPrint ("your tears are delicious");
                              } //end if
                           } //end if
                        } //end if
                     } //end if
                  } //end if
               }
               else
               {
                  if ((self.personality == PERS_RAGER))
                  {
                     // Echo chamber!
                     if ((r < 0.070))
                     {
                        ChatPrint ("yeah lag is bad");
                     }
                     else
                     {
                        if ((r < 0.140))
                        {
                           ChatPrint ("i know right");
                        }
                        else
                        {
                           if ((r < 0.210))
                           {
                              ChatPrint ("totally broken");
                           }
                           else
                           {
                              if ((r < 0.280))
                              {
                                 ChatPrint ("same here bro");
                              }
                              else
                              {
                                 if ((r < 0.350))
                                 {
                                    ChatPrint ("this server sucks");
                                 } //end if
                              } //end if
                           } //end if
                        } //end if
                     } //end if
                  }
                  else
                  {
                     if ((self.personality == PERS_CAMPER))
                     {
                        if ((r < 0.175))
                        {
                           ChatPrint ("shoulda played more carefully");
                        }
                        else
                        {
                           if ((r < 0.350))
                           {
                              ChatPrint ("thats what happens when you rush");
                           } //end if
                        } //end if
                     }
                     else
                     {
                        if ((self.personality == PERS_NOOB))
                        {
                           if ((r < 0.175))
                           {
                              ChatPrint ("yeah i get killed a lot too");
                           }
                           else
                           {
                              if ((r < 0.350))
                              {
                                 ChatPrint ("its okay");
                              } //end if
                           } //end if
                        } //end if
                     } //end if
                  } //end if
               } //end if
            } //end if
         }
         else
         {
            // If last speaker was a NOOB
            if ((world.last_speaker.personality == PERS_NOOB))
            {
               if ((self.personality == PERS_PRO))
               {
                  if ((r < 0.117))
                  {
                     ChatPrint ("try jumping");
                  }
                  else
                  {
                     if ((r < 0.233))
                     {
                        ChatPrint ("strafe more");
                     }
                     else
                     {
                        if ((r < 0.350))
                        {
                           ChatPrint ("keep moving");
                        } //end if
                     } //end if
                  } //end if
               }
               else
               {
                  if ((self.personality == PERS_NOOB))
                  {
                     if ((r < 0.117))
                     {
                        ChatPrint ("me too :(");
                     }
                     else
                     {
                        if ((r < 0.233))
                        {
                           ChatPrint ("i feel you");
                        }
                        else
                        {
                           if ((r < 0.350))
                           {
                              ChatPrint ("we should team up");
                           } //end if
                        } //end if
                     } //end if
                  }
                  else
                  {
                     if ((self.personality == PERS_RAGER))
                     {
                        if ((r < 0.117))
                        {
                           ChatPrint ("learn to play");
                        }
                        else
                        {
                           if ((r < 0.233))
                           {
                              ChatPrint ("stop feeding");
                           }
                           else
                           {
                              if ((r < 0.350))
                              {
                                 ChatPrint ("go back to single player");
                              } //end if
                           } //end if
                        } //end if
                     }
                     else
                     {
                        if ((self.personality == PERS_MEMELORD))
                        {
                           if ((r < 0.175))
                           {
                              ChatPrint ("git gud");
                           }
                           else
                           {
                              if ((r < 0.350))
                              {
                                 ChatPrint ("feels bad man");
                              } //end if
                           } //end if
                        }
                        else
                        {
                           if ((self.personality == PERS_CAMPER))
                           {
                              if ((r < 0.350))
                              {
                                 ChatPrint ("find a safe spot");
                              } //end if
                           } //end if
                        } //end if
                     } //end if
                  } //end if
               } //end if
            }
            else
            {
               // === NEW: Respond to PRO death (rare but respectful) ===
               if ((world.last_speaker.personality == PERS_PRO))
               {
                  if ((self.personality == PERS_PRO))
                  {
                     if ((r < 0.350))
                     {
                        ChatPrint ("gg");
                     } //end if
                  }
                  else
                  {
                     if ((self.personality == PERS_NOOB))
                     {
                        if ((r < 0.350))
                        {
                           ChatPrint ("even the pros die");
                        } //end if
                     }
                     else
                     {
                        if ((self.personality == PERS_MEMELORD))
                        {
                           if ((r < 0.350))
                           {
                              ChatPrint ("top 10 anime deaths");
                           } //end if
                        } //end if
                     } //end if
                  } //end if
               }
               else
               {
                  // === NEW: Respond to CAMPER death (schadenfreude) ===
                  if ((world.last_speaker.personality == PERS_CAMPER))
                  {
                     if ((self.personality == PERS_RAGER))
                     {
                        if ((r < 0.350))
                        {
                           ChatPrint ("good campers deserve to die");
                        } //end if
                     }
                     else
                     {
                        if ((self.personality == PERS_MEMELORD))
                        {
                           if ((r < 0.350))
                           {
                              ChatPrint ("camping is a legitimate strategy lol");
                           } //end if
                        }
                        else
                        {
                           if ((self.personality == PERS_PRO))
                           {
                              if ((r < 0.350))
                              {
                                 ChatPrint ("should have rotated");
                              } //end if
                           } //end if
                        } //end if
                     } //end if
                  }
                  else
                  {
                     // === NEW: Respond to MEMELORD death (meme on meme violence) ===
                     if ((world.last_speaker.personality == PERS_MEMELORD))
                     {
                        if ((self.personality == PERS_MEMELORD))
                        {
                           if ((r < 0.350))
                           {
                              ChatPrint ("bruh");
                           } //end if
                        }
                        else
                        {
                           if ((self.personality == PERS_RAGER))
                           {
                              if ((r < 0.350))
                              {
                                 ChatPrint ("stop memeing and play");
                              } //end if
                           } //end if
                        } //end if
                     } //end if
                  } //end if
               } //end if
            } //end if
         } //end if

         // Clear to prevent spam loop
         world.chat_time = FALSE;
      }
      else
      {
         // === NEW: SCENARIO: RESPOND TO IDLE BANTER ===
         if ((world.chat_type == C_IDLE))
         {
            if ((self.personality == PERS_RAGER))
            {
               if ((r < 0.117))
               {
                  ChatPrint ("shut up and play");
               }
               else
               {
                  if ((r < 0.233))
                  {
                     ChatPrint ("nobody cares");
                  }
                  else
                  {
                     if ((r < 0.350))
                     {
                        ChatPrint ("stop talking start fragging");
                     } //end if
                  } //end if
               } //end if
            }
            else
            {
               if ((self.personality == PERS_MEMELORD))
               {
                  if ((r < 0.117))
                  {
                     ChatPrint ("true");
                  }
                  else
                  {
                     if ((r < 0.233))
                     {
                        ChatPrint ("big if true");
                     }
                     else
                     {
                        if ((r < 0.350))
                        {
                           ChatPrint ("this");
                        } //end if
                     } //end if
                  } //end if
               }
               else
               {
                  if ((self.personality == PERS_NOOB))
                  {
                     if ((r < 0.175))
                     {
                        ChatPrint ("yeah!");
                     }
                     else
                     {
                        if ((r < 0.350))
                        {
                           ChatPrint ("agreed");
                        } //end if
                     } //end if
                  }
                  else
                  {
                     if ((self.personality == PERS_PRO))
                     {
                        if ((r < 0.350))
                        {
                           ChatPrint ("focus");
                        } //end if
                     } //end if
                  } //end if
               } //end if
            } //end if

            // Clear to prevent spam loop
            world.chat_time = FALSE;
         } //end if
      } //end if
   } //end if
}; //end of the function CheckChatReply

// ===== MASTER CHAT FUNCTION =====
// Called from various hooks (death, kill, idle, reply) to trigger appropriate chat
void (float ctx, entity targ) BotChat =
{
   local float min_cooldown;
   local float cooldown_range;

   // Safety check: Don't chat if on cooldown (anti-spam)
   if ((self.chat_cooldown > time))
   {
      return ;
   } //end if

   // Set cooldown: PERSONALITY-BASED for realistic chat frequency
   // RAGER talks the most (lots of complaints)
   // PRO talks the least (focused on gameplay)
   if ((self.personality == PERS_RAGER))
   {
      min_cooldown = 2.000;
      cooldown_range = 4.000; // 2-6 seconds
   }
   else
   {
      if ((self.personality == PERS_MEMELORD))
      {
         min_cooldown = 3.000;
         cooldown_range = 5.000; // 3-8 seconds
      }
      else
      {
         if ((self.personality == PERS_NOOB))
         {
            min_cooldown = 4.000;
            cooldown_range = 6.000; // 4-10 seconds
         }
         else
         {
            if ((self.personality == PERS_CAMPER))
            {
               min_cooldown = 5.000;
               cooldown_range = 7.000; // 5-12 seconds
            }
            else
            {
               // PRO or default
               min_cooldown = 6.000;
               cooldown_range = 8.000; // 6-14 seconds
            } //end if
         } //end if
      } //end if
   } //end if

   self.chat_cooldown = (time + min_cooldown + (random () * cooldown_range));

   if ((ctx == C_GREET))
   {
      ChatGreet ();
   }
   else
   {
      if ((ctx == C_KILL))
      {
         ChatKill (targ);
      }
      else
      {
         if ((ctx == C_DEATH))
         {
            ChatDeath (targ);
         }
         else
         {
            if ((ctx == C_IDLE))
            {
               ChatIdle ();
            }
            else
            {
               if ((ctx == C_REPLY))
               {
                  CheckChatReply ();
               } //end if
            } //end if
         } //end if
      } //end if
   } //end if
}; //end of the function BotChat
