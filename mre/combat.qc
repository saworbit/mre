
void () T_MissileTouch;

void () info_player_start;

void (entity targ, entity attacker) ClientObituary;

void () monster_death_use;
float (entity targ, entity inflictor) CanDamage = {

   if ( (targ.movetype == MOVETYPE_PUSH) ) {

      traceline (inflictor.origin,(0.500 * (targ.absmin + targ.absmax)),TRUE,self);
      if ( (trace_fraction == TRUE) ) {

         return ( TRUE );

      }
      if ( (trace_ent == targ) ) {

         return ( TRUE );

      }
      return ( FALSE );

   }
   traceline (inflictor.origin,targ.origin,TRUE,self);
   if ( (trace_fraction == TRUE) ) {

      return ( TRUE );

   }
   traceline (inflictor.origin,(targ.origin + '15.000 15.000 0.000'),TRUE,self);
   if ( (trace_fraction == TRUE) ) {

      return ( TRUE );

   }
   traceline (inflictor.origin,(targ.origin + '-15.000 -15.000 0.000'),TRUE,self);
   if ( (trace_fraction == TRUE) ) {

      return ( TRUE );

   }
   traceline (inflictor.origin,(targ.origin + '-15.000 15.000 0.000'),TRUE,self);
   if ( (trace_fraction == TRUE) ) {

      return ( TRUE );

   }
   traceline (inflictor.origin,(targ.origin + '15.000 -15.000 0.000'),TRUE,self);
   if ( (trace_fraction == TRUE) ) {

      return ( TRUE );

   }
   return ( FALSE );

};

void (entity targ, entity attacker) Killed = {

   local entity oself;

   oself = self;
   self = targ;
   if ( (self.health < -99.000) ) {

      self.health = -99.000;

   }
   if ( ((self.movetype == MOVETYPE_PUSH) || (self.movetype == MOVETYPE_NONE)) ) {

      self.th_die ();
      self = oself;
      return ;

   }
   self.enemy = attacker;
   if ( (self.flags & FL_MONSTER) ) {

      floaterEnable( self, -18 );
      killed_monsters = (killed_monsters + TRUE);
      WriteByte (MSG_ALL,SVC_KILLEDMONSTER);

   }
   ClientObituary (self,attacker);
   self.takedamage = DAMAGE_NO;
   self.touch = SUB_Null;
   monster_death_use ();
   self.th_die ();
   self = oself;

};

void (entity targ, entity inflictor, entity attacker, float damage) T_Damage = {

   local vector dir;
   local entity oldself;
   local float save;
   local float take;

   if ( !targ.takedamage ) {

      return ;

   }
   damage_attacker = attacker;
   if ( (attacker.super_damage_finished > time) ) {

      damage = (damage * MOVETYPE_STEP);

   }
   save = ceil ((targ.armortype * damage));
   if ( (save >= targ.armorvalue) ) {

      save = targ.armorvalue;
      targ.armortype = FALSE;
      targ.items = (targ.items - (targ.items & ((IT_ARMOR1 | IT_ARMOR2) | IT_ARMOR3)));

   }
   targ.armorvalue = (targ.armorvalue - save);
   take = ceil ((damage - save));
   if ( (targ.flags & FL_CLIENT) ) {

      targ.dmg_take = (targ.dmg_take + take);
      targ.dmg_save = (targ.dmg_save + save);
      targ.dmg_inflictor = inflictor;

   }
   if  ((inflictor != world) && ((targ.classname == "player") || (targ.classname == "dmbot"))) {

      dir = (targ.origin - ((inflictor.absmin + inflictor.absmax) * 0.500));
      dir = normalize (dir);
      targ.velocity = (targ.velocity + ((dir * damage) * FL_CLIENT));
      targ.knockback_time = time;  // Track when knockback was applied
      if ( (targ.classname == "dmbot") ) {

         targ.movetype = MOVETYPE_BOUNCE;
         if ( ((attacker.classname == "player") || (attacker.classname == "dmbot")) && (attacker != targ) && (targ.enemy != attacker) ) {

            oldself = self;
            self = targ;
            self.enemy = attacker;
            self.pending_enemy = world;
            self.reaction_time = FALSE;
            BotHuntTarget ();
            self = oldself;

         }

      }

   }
   if ( (targ.flags & FL_GODMODE) ) {

      return ;

   }
   if ( (targ.invincible_finished >= time) ) {

      if ( (self.invincible_sound < time) ) {

         sound (targ,CHAN_ITEM,"items/protect3.wav",TRUE,ATTN_NORM);
         self.invincible_sound = (time + FL_SWIM);

      }
      return ;

   }
   if ( (((teamplay == TRUE) && (targ.team > FALSE)) && (targ.team == attacker.team)) ) {

      return ;

   }
   targ.health = (targ.health - take);
   if ( (targ.health <= FALSE) ) {

      Killed (targ,attacker);
      return ;

   }
   oldself = self;
   self = targ;
   if ( (self.classname == "dmbot") ) {

      if ( (attacker != world) ) {

         if ( (inflictor != world) ) {

            if ( (attacker != self) ) {

               if ( self.enemy ) {

                  secondEnemy (attacker);

               } else {

                  self.enemy = attacker;
                  BotFoundTarget ();

               }

            }

         }

      }

   } else {

      if ( ((self.flags & FL_MONSTER) && (attacker != world)) ) {

         if ( ((self != attacker) && (attacker != self.enemy)) ) {

            if ( ((self.classname != attacker.classname) || (self.classname == "monster_army")) ) {

               if ( (self.enemy.classname == "player") ) {

                  self.oldenemy = self.enemy;

               }
               self.enemy = attacker;
               FoundTarget ();

            }

         }

      }

   }
   if ( self.th_pain ) {

      self.th_pain (attacker,take);
      if ( (skill == MOVETYPE_WALK) ) {

         self.pain_finished = (time + MOVETYPE_FLY);

      }

   }
   self = oldself;

};

void (entity inflictor, entity attacker, float damage, entity ignore) T_RadiusDamage = {

   local float points;
   local entity head;
   local vector org;

   head = findradius (inflictor.origin,(damage + 40.000));
   while ( head ) {

      if ( (head != ignore) ) {

         if ( head.takedamage ) {

            org = (head.origin + ((head.mins + head.maxs) * 0.500));
            points = (0.500 * vlen ((inflictor.origin - org)));
            if ( (points < FALSE) ) {

               points = FALSE;

            }
            points = (damage - points);
            if ( (head == attacker) ) {

               points = (points * 0.500);

            }
            if ( (points > FALSE) ) {

               if ( CanDamage (head,inflictor) ) {

                  if ( (head.classname == "monster_shambler") ) {

                     T_Damage (head,inflictor,attacker,(points * 0.500));

                  } else {

                     T_Damage (head,inflictor,attacker,points);

                  }

               }

            }

         }

      }
      head = head.chain;

   }

};

void (entity attacker, float damage) T_BeamDamage = {

   local float points;
   local entity head;

   head = findradius (attacker.origin,(damage + 40.000));
   while ( head ) {

      if ( head.takedamage ) {

         points = (0.500 * vlen ((attacker.origin - head.origin)));
         if ( (points < FALSE) ) {

            points = FALSE;

         }
         points = (damage - points);
         if ( (head == attacker) ) {

            points = (points * 0.500);

         }
         if ( (points > FALSE) ) {

            if ( CanDamage (head,attacker) ) {

               if ( (head.classname == "monster_shambler") ) {

                  T_Damage (head,attacker,attacker,(points * 0.500));

               } else {

                  T_Damage (head,attacker,attacker,points);

               }

            }

         }

      }
      head = head.chain;

   }

};
