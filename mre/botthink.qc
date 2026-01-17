
void (entity e) clearCache;
float () CheckWaterLevel = {

   local float pnt;

   if ( (self.waterlevel < TRUE) ) {

      return ( FALSE );

   }
   pnt = pointcontents ((self.origin + self.view_ofs));
   if ( (pnt != CONTENT_EMPTY) ) {

      return ( MOVETYPE_WALK );

   }
   pnt = pointcontents (self.origin);
   if ( (pnt != CONTENT_EMPTY) ) {

      return ( FL_SWIM );

   }
   return ( TRUE );

};

void () BotWaterMove = {

   local float wlevel;
   local float wtype;
   local float pnt;
   local vector bt;

   wlevel = CheckWaterLevel ();
   if ( (self.health < FALSE) ) {

      return ;

   }
   if ( (wlevel != MOVETYPE_WALK) ) {

      if ( (self.air_finished < time) ) {

         sound (self,CHAN_VOICE,"player/gasp2.wav",TRUE,ATTN_NORM);

      } else {

         if ( (self.air_finished < (time + MOVETYPE_FLYMISSILE)) ) {

            sound (self,CHAN_VOICE,"player/gasp1.wav",TRUE,ATTN_NORM);

         }

      }
      self.air_finished = (time + KINDA_WANT);
      self.dmg = FL_SWIM;

   } else {

      if ( (self.air_finished < time) ) {

         if ( (self.pain_finished < time) ) {

            self.dmg = (self.dmg + FL_SWIM);
            if ( (self.dmg > 15.000) ) {

               self.dmg = MOVETYPE_BOUNCE;

            }
            T_Damage (self,world,world,self.dmg);
            self.pain_finished = (time + TRUE);

         }

      }

   }
   wtype = self.watertype;
   if ( (wlevel < TRUE) ) {

      bt = ((self.absmin + self.absmax) * 0.500);
      bt_z = (self.absmin_z + TRUE);
      pnt = pointcontents (bt);
      if ( (pnt != CONTENT_EMPTY) ) {

         wlevel = TRUE;
         wtype = pnt;

      }

   }
   if ( (self.waterlevel < TRUE) ) {

      if ( (self.flags & FL_INWATER) ) {

         sound (self,CHAN_BODY,"misc/outwater.wav",TRUE,ATTN_NORM);
         self.flags = (self.flags - FL_INWATER);

      }
      if ( (self.flags & FL_SWIM) ) {

         self.flags = (self.flags - FL_SWIM);

      }
      if ( (wlevel < TRUE) ) {

         return ;

      }

   }
   if ( (wtype == CONTENT_LAVA) ) {

      if ( (self.dmgtime < time) ) {

         if ( (self.radsuit_finished > time) ) {

            self.dmgtime = (time + TRUE);

         } else {

            self.dmgtime = (time + 0.200);

         }
         T_Damage (self,world,world,(MOVETYPE_BOUNCE * wlevel));

      }

   } else {

      if ( (wtype == CONTENT_SLIME) ) {

         if ( ((self.dmgtime < time) && (self.radsuit_finished < time)) ) {

            self.dmgtime = (time + TRUE);
            T_Damage (self,world,world,(MOVETYPE_STEP * wlevel));

         }

      }

   }
   if ( (self.waterlevel < TRUE) ) {

      return ;

   }
   if ( !(self.flags & FL_INWATER) ) {

      if ( (self.watertype == CONTENT_LAVA) ) {

         sound (self,CHAN_BODY,"player/inlava.wav",TRUE,ATTN_NORM);

      }
      if ( (self.watertype == CONTENT_WATER) ) {

         sound (self,CHAN_BODY,"player/inh2o.wav",TRUE,ATTN_NORM);

      }
      if ( (self.watertype == CONTENT_SLIME) ) {

         sound (self,CHAN_BODY,"player/slimbrn2.wav",TRUE,ATTN_NORM);

      }
      self.flags = (self.flags + FL_INWATER);
      if ( !(self.flags & FL_SWIM) ) {

         self.flags = (self.flags + FL_SWIM);

      }
      self.dmgtime = FALSE;

   }

};

void () BotCheckPowerups = {

   if ( (self.health <= FALSE) ) {

      return ;

   }
   if ( self.invisible_finished ) {

      if ( (self.invisible_sound < time) ) {

         sound (self,CHAN_AUTO,"items/inv3.wav",0.500,ATTN_IDLE);
         self.invisible_sound = (time + ((random () * MOVETYPE_WALK) + TRUE));

      }
      if ( (self.invisible_finished < (time + MOVETYPE_WALK)) ) {

         if ( (self.invisible_time == TRUE) ) {

            sound (self,CHAN_AUTO,"items/inv2.wav",TRUE,ATTN_NORM);
            self.invisible_time = (time + TRUE);

         }
         if ( (self.invisible_time < time) ) {

            self.invisible_time = (time + TRUE);

         }

      }
      if ( (self.invisible_finished < time) ) {

         self.items = (self.items - IT_INVISIBILITY);
         self.invisible_finished = FALSE;
         self.invisible_time = FALSE;

      }
      self.frame = FALSE;
      self.modelindex = modelindex_eyes;

   } else {

      self.modelindex = modelindex_player;

   }
   if ( self.invincible_finished ) {

      if ( (self.invincible_finished < (time + MOVETYPE_WALK)) ) {

         if ( (self.invincible_time == TRUE) ) {

            sound (self,CHAN_AUTO,"items/protect2.wav",TRUE,ATTN_NORM);
            self.invincible_time = (time + TRUE);

         }
         if ( (self.invincible_time < time) ) {

            self.invincible_time = (time + TRUE);

         }

      }
      if ( (self.invincible_finished < time) ) {

         self.items = (self.items - IT_INVULNERABILITY);
         self.invincible_time = FALSE;
         self.invincible_finished = FALSE;

      }
      if ( (self.invincible_finished > time) ) {

         self.effects = (self.effects | EF_DIMLIGHT);

      } else {

         self.effects = (self.effects - (self.effects & EF_DIMLIGHT));

      }

   }
   if ( self.super_damage_finished ) {

      if ( (self.super_damage_finished < (time + MOVETYPE_WALK)) ) {

         if ( (self.super_time == TRUE) ) {

            sound (self,CHAN_AUTO,"items/damage2.wav",TRUE,ATTN_NORM);
            self.super_time = (time + TRUE);

         }
         if ( (self.super_time < time) ) {

            self.super_time = (time + TRUE);

         }

      }
      if ( (self.super_damage_finished < time) ) {

         self.items = (self.items - IT_QUAD);
         self.super_damage_finished = FALSE;
         self.super_time = FALSE;

      }
      if ( (self.super_damage_finished > time) ) {

         self.effects = (self.effects | EF_DIMLIGHT);

      } else {

         self.effects = (self.effects - (self.effects & EF_DIMLIGHT));

      }

   }
   if ( self.radsuit_finished ) {

      self.air_finished = (time + 12.000);
      if ( (self.radsuit_finished < (time + MOVETYPE_WALK)) ) {

         if ( (self.rad_time == TRUE) ) {

            sound (self,CHAN_AUTO,"items/suit2.wav",TRUE,ATTN_NORM);
            self.rad_time = (time + TRUE);

         }
         if ( (self.rad_time < time) ) {

            self.rad_time = (time + TRUE);

         }

      }
      if ( (self.radsuit_finished < time) ) {

         self.items = (self.items - IT_SUIT);
         self.rad_time = FALSE;
         self.radsuit_finished = FALSE;

      }

   }

};

void () BotDead;

void () BotPostThink = {

   local float fraglimit;

   if ( self.pather ) {

      if ( CheckDropPath () ) {

         DropBotPath ();

      }

   }
   self.movetarget.flags = self.flags;
   setorigin (self.movetarget,self.origin);
   if ( (self.deadflag != DEAD_NO) ) {

      dprint ("Bot should be dead!\n");
      GibPlayer ();
      BotDead ();
      return ;

   }
   BotCheckPowerups ();
   BotWaterMove ();
   if ( (self.movetype == MOVETYPE_BOUNCE) ) {

      if ( ((self.flags & FL_ONGROUND) || (vlen (self.velocity) < 40.000)) ) {

         self.movetype = MOVETYPE_STEP;
         self.velocity = '0 0 0';

      }
      if ( (cvar ("developer") > 0.000) && (self.knockback_time > (time - 0.100)) ) {

         dprint ("[");
         dprint (self.netname);
         dprint ("] KNOCKBACK: vel=");
         dprint (vtos (self.velocity));
         dprint (" type=");
         dprint (ftos (self.movetype));
         dprint ("\n");

      }

   }
   fraglimit = cvar ("fraglimit");
   if ( (fraglimit && (self.frags >= fraglimit)) ) {

      NextLevel ();
      self.button0 = TRUE;
      self.think = IntermissionThink;
      self.nextthink = (time + MOVETYPE_FLY);
      return ;

   }

};
