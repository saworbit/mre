
void () bot_start = [ 12.000, bot_walk ] {

   local string tmp;

   BotPostThink ();
   droptofloor ();
   self.nextthink = ((time + 0.200) + (0.200 * random ()));
   if ( (self.skil < MOVETYPE_WALK) ) {

      self.nextthink = (self.nextthink + (0.100 * (MOVETYPE_WALK - self.skil)));

   }

};

void () bot_stand1 = [ 12.000, bot_walk ] {

   ai_botstand ();
   BotPostThink ();

};

void () bot_walk = [ 6.000, bot_walk ] {

   self.weaponframe = FALSE;
   if ( (self.weapon == IT_AXE) ) {

      if ( (self.walkframe == MOVETYPE_TOSS) ) {

         self.walkframe = FALSE;

      }
      self.frame = (FALSE + self.walkframe);

   } else {

      if ( (self.walkframe == MOVETYPE_TOSS) ) {

         self.walkframe = FALSE;

      }
      self.frame = (self.frame + self.walkframe);

   }
   self.walkframe = (self.walkframe + TRUE);
   ai_botseek (BOTSPEED);
   BotPostThink ();

};

void () bot_run = [ 6.000, bot_run ] {

   self.weaponframe = FALSE;
   if ( (self.weapon == IT_AXE) ) {

      if ( (self.walkframe == MOVETYPE_TOSS) ) {

         self.walkframe = FALSE;

      }
      self.frame = (FALSE + self.walkframe);

   } else {

      if ( (self.walkframe == MOVETYPE_TOSS) ) {

         self.walkframe = FALSE;

      }
      self.frame = (self.frame + self.walkframe);

   }
   self.walkframe = (self.walkframe + TRUE);
   BotAI_Main (BOTSPEED);
   BotPostThink ();

};

void () bot_chase = [ 6.000, bot_chase ] {

   self.weaponframe = FALSE;
   if ( (self.weapon == IT_AXE) ) {

      if ( (self.walkframe == MOVETYPE_TOSS) ) {

         self.walkframe = FALSE;

      }
      self.frame = (FALSE + self.walkframe);

   } else {

      if ( (self.walkframe == MOVETYPE_TOSS) ) {

         self.walkframe = FALSE;

      }
      self.frame = (self.frame + self.walkframe);

   }
   self.walkframe = (self.walkframe + TRUE);
   aibot_chase (BOTSPEED);
   BotPostThink ();

};

void () bot_shot1 = [ 113.000, bot_shot2 ] {

   self.weaponframe = TRUE;
   self.effects = (self.effects | EF_MUZZLEFLASH);

};

void () bot_shot2 = [ 114.000, bot_shot3 ] {

   self.weaponframe = FL_SWIM;
   if ( (self.skil > 0.900) ) {

      BotAI_Main (BOTSPEED);

   }
   BotPostThink ();

};

void () bot_shot3 = [ 115.000, bot_shot4 ] {

   self.weaponframe = MOVETYPE_WALK;
   if ( (self.skil > FALSE) ) {

      BotAI_Main (BOTSPEED);

   }
   BotPostThink ();

};

void () bot_shot4 = [ 116.000, bot_shot5 ] {

   self.weaponframe = MOVETYPE_STEP;
   if ( (self.skil > FALSE) ) {

      BotAI_Main (BOTSPEED);

   } else {

      BotAI_Main ((BOTSPEED * 0.500));

   }
   BotPostThink ();

};

void () bot_shot5 = [ 117.000, bot_shot6 ] {

   self.weaponframe = MOVETYPE_FLY;
   BotAI_Main (BOTSPEED);
   BotPostThink ();

};

void () bot_shot6 = [ 118.000, bot_run ] {

   self.weaponframe = MOVETYPE_TOSS;
   BotAI_Main (BOTSPEED);
   BotPostThink ();

};

void () bot_trigger1 = [ 113.000, bot_trigger2 ] {

   self.weaponframe = TRUE;
   self.effects = (self.effects | EF_MUZZLEFLASH);

};

void () bot_trigger2 = [ 114.000, bot_trigger3 ] {

   self.weaponframe = FL_SWIM;
   ai_botseek (BOTSPEED);
   BotPostThink ();

};

void () bot_trigger3 = [ 115.000, bot_trigger4 ] {

   self.weaponframe = MOVETYPE_WALK;
   ai_botseek (BOTSPEED);
   BotPostThink ();

};

void () bot_trigger4 = [ 116.000, bot_trigger5 ] {

   self.weaponframe = MOVETYPE_STEP;
   ai_botseek (BOTSPEED);
   BotPostThink ();

};

void () bot_trigger5 = [ 117.000, bot_trigger6 ] {

   self.weaponframe = MOVETYPE_FLY;
   ai_botseek (BOTSPEED);
   BotPostThink ();

};

void () bot_trigger6 = [ 118.000, bot_walk ] {

   self.weaponframe = MOVETYPE_TOSS;
   ai_botseek (BOTSPEED);
   BotPostThink ();

};

void () bot_axe1 = [ 119.000, bot_axe2 ] {

   self.weaponframe = TRUE;

};

void () bot_axe2 = [ 120.000, bot_axe3 ] {

   self.weaponframe = FL_SWIM;
   BotAI_Main (BOTSPEED);
   BotPostThink ();

};

void () bot_axe3 = [ 121.000, bot_axe4 ] {

   self.weaponframe = MOVETYPE_WALK;
   W_FireAxe ();
   BotPostThink ();

};

void () bot_axe4 = [ 122.000, bot_run ] {

   self.weaponframe = MOVETYPE_STEP;
   BotAI_Main (BOTSPEED);
   BotPostThink ();

};

void () bot_axeb1 = [ 125.000, bot_axeb2 ] {

   self.weaponframe = MOVETYPE_FLY;

};

void () bot_axeb2 = [ 126.000, bot_axeb3 ] {

   self.weaponframe = MOVETYPE_TOSS;
   BotAI_Main (BOTSPEED);
   BotPostThink ();

};

void () bot_axeb3 = [ 127.000, bot_axeb4 ] {

   self.weaponframe = MOVETYPE_PUSH;
   W_FireAxe ();
   BotAI_Main (BOTSPEED);
   BotPostThink ();

};

void () bot_axeb4 = [ 128.000, bot_run ] {

   self.weaponframe = FL_CLIENT;
   BotAI_Main (BOTSPEED);
   BotPostThink ();

};

void () bot_axec1 = [ 131.000, bot_axec2 ] {

   self.weaponframe = TRUE;

};

void () bot_axec2 = [ 132.000, bot_axec3 ] {

   self.weaponframe = FL_SWIM;
   BotAI_Main (BOTSPEED);
   BotPostThink ();

};

void () bot_axec3 = [ 133.000, bot_axec4 ] {

   self.weaponframe = MOVETYPE_WALK;
   W_FireAxe ();
   BotAI_Main (BOTSPEED);
   BotPostThink ();

};

void () bot_axec4 = [ 134.000, bot_run ] {

   self.weaponframe = MOVETYPE_STEP;
   BotAI_Main (BOTSPEED);
   BotPostThink ();

};

void () bot_axed1 = [ 137.000, bot_axed2 ] {

   self.weaponframe = MOVETYPE_FLY;

};

void () bot_axed2 = [ 138.000, bot_axed3 ] {

   self.weaponframe = MOVETYPE_TOSS;
   BotAI_Main (BOTSPEED);
   BotPostThink ();

};

void () bot_axed3 = [ 139.000, bot_axed4 ] {

   self.weaponframe = MOVETYPE_PUSH;
   W_FireAxe ();
   BotAI_Main (BOTSPEED);
   BotPostThink ();

};

void () bot_axed4 = [ 140.000, bot_run ] {

   self.weaponframe = FL_CLIENT;
   BotAI_Main (BOTSPEED);
   BotPostThink ();

};

void () dmbot_melee = {

   self.weapon = W_BestBotWeapon ();
   W_BotAttack ();

};

void () bot_nail1 = [ 103.000, bot_nail2 ] {

   self.effects = (self.effects | EF_MUZZLEFLASH);
   self.weaponframe = (self.weaponframe + TRUE);
   if ( (self.weaponframe == MOVETYPE_FLYMISSILE) ) {

      self.weaponframe = TRUE;

   }
   SuperDamageSound ();
   W_FireSpikes (MOVETYPE_STEP);
   ai_botnailcharge (BOTSPEED);
   self.attack_finished = (time + 0.200);
   BotPostThink ();

};

void () bot_nail2 = [ 104.000, bot_nail1 ] {

   self.effects = (self.effects | EF_MUZZLEFLASH);
   self.weaponframe = (self.weaponframe + TRUE);
   if ( (self.weaponframe == MOVETYPE_FLYMISSILE) ) {

      self.weaponframe = TRUE;

   }
   SuperDamageSound ();
   W_FireSpikes (CONTENT_SLIME);
   ai_botnailcharge (BOTSPEED);
   self.attack_finished = (time + 0.200);
   BotPostThink ();

};

void () bot_light1 = [ 105.000, bot_light2 ] {

   self.effects = (self.effects | EF_MUZZLEFLASH);
   self.weaponframe = (self.weaponframe + TRUE);
   if ( (self.weaponframe == MOVETYPE_FLY) ) {

      self.weaponframe = TRUE;

   }
   SuperDamageSound ();
   W_FireLightning ();
   ai_botnailcharge (BOTSPEED);
   self.attack_finished = (time + 0.200);
   BotPostThink ();

};

void () bot_light2 = [ 106.000, bot_light1 ] {

   self.effects = (self.effects | EF_MUZZLEFLASH);
   self.weaponframe = (self.weaponframe + TRUE);
   if ( (self.weaponframe == MOVETYPE_FLY) ) {

      self.weaponframe = TRUE;

   }
   SuperDamageSound ();
   W_FireLightning ();
   ai_botnailcharge (BOTSPEED);
   self.attack_finished = (time + 0.200);
   BotPostThink ();

};

void () bot_rocket1 = [ 107.000, bot_rocket2 ] {

   self.weaponframe = TRUE;
   self.effects = (self.effects | EF_MUZZLEFLASH);
   BotPostThink ();

};

void () bot_rocket2 = [ 108.000, bot_rocket3 ] {

   self.weaponframe = FL_SWIM;
   if ( (self.skil > FL_SWIM) ) {

      ai_botcharge (BOTSPEED);

   }
   BotPostThink ();

};

void () bot_rocket3 = [ 109.000, bot_rocket4 ] {

   self.weaponframe = MOVETYPE_WALK;
   if ( (self.skil > TRUE) ) {

      ai_botcharge (BOTSPEED);

   }
   BotPostThink ();

};

void () bot_rocket4 = [ 110.000, bot_rocket5 ] {

   self.weaponframe = MOVETYPE_STEP;
   if ( (self.skil > TRUE) ) {

      ai_botcharge (BOTSPEED);

   }
   BotPostThink ();

};

void () bot_rocket5 = [ 111.000, bot_rocket6 ] {

   self.weaponframe = MOVETYPE_FLY;
   if ( (self.skil > FALSE) ) {

      ai_botcharge (BOTSPEED);

   }
   BotPostThink ();

};

void () bot_rocket6 = [ 112.000, bot_run ] {

   self.weaponframe = MOVETYPE_TOSS;
   ai_botcharge (BOTSPEED);
   BotPostThink ();

};

void () bot_rebound1 = [ 107.000, bot_rebound2 ] {

   self.weaponframe = TRUE;
   self.effects = (self.effects | EF_MUZZLEFLASH);
   BotPostThink ();

};

void () bot_rebound2 = [ 108.000, bot_rebound3 ] {

   self.weaponframe = FL_SWIM;
   BotPostThink ();

};

void () bot_rebound3 = [ 109.000, bot_rebound4 ] {

   self.weaponframe = MOVETYPE_WALK;
   BotPostThink ();

};

void () bot_rebound4 = [ 110.000, bot_rebound5 ] {

   self.weaponframe = MOVETYPE_STEP;
   aibot_chase (BOTSPEED);
   BotPostThink ();

};

void () bot_rebound5 = [ 111.000, bot_rebound6 ] {

   self.weaponframe = MOVETYPE_FLY;
   aibot_chase (BOTSPEED);
   BotPostThink ();

};

void () bot_rebound6 = [ 112.000, bot_chase ] {

   self.weaponframe = MOVETYPE_TOSS;
   aibot_chase (BOTSPEED);
   BotPostThink ();

};

void () bot_pain1 = [ 35.000, bot_pain2 ] {

   PainSound ();
   self.weaponframe = FALSE;

};

void () bot_pain2 = [ 36.000, bot_pain3 ] {

   /* Warning: Fields and functions must be global */
   local float r;

   r = ((MOVETYPE_STEP * random ()) + self.skil);
   if ( (r > FL_SWIM) ) {

      BotAI_Main (BOTSPEED);

   } else {

      ai_botcharge (BOTSPEED);

   }
   BotPostThink ();

};

void () bot_pain3 = [ 37.000, bot_pain4 ] {

   if ( (self.skil >= TRUE) ) {

      BotAI_Main (BOTSPEED);

   } else {

      ai_botcharge (BOTSPEED);

   }
   BotPostThink ();

};

void () bot_pain4 = [ 38.000, bot_pain5 ] {

   if ( (self.skil > FALSE) ) {

      BotAI_Main (BOTSPEED);

   } else {

      ai_botcharge (BOTSPEED);

   }
   BotPostThink ();

};

void () bot_pain5 = [ 39.000, bot_pain6 ] {

   if ( (self.skil > FL_SWIM) ) {

      BotAI_Main (BOTSPEED);

   } else {

      ai_botcharge (BOTSPEED);

   }
   BotPostThink ();

};

void () bot_pain6 = [ 40.000, bot_run ] {

   BotAI_Main (BOTSPEED);
   BotPostThink ();

};

void () bot_axpain1 = [ 29.000, bot_axpain2 ] {

   PainSound ();
   self.weaponframe = FALSE;
   BotPostThink ();

};

void () bot_axpain2 = [ 30.000, bot_axpain3 ] {

   /* Warning: Fields and functions must be global */
   local float r;

   r = ((MOVETYPE_STEP * random ()) + self.skil);
   if ( (r > FL_SWIM) ) {

      BotAI_Main (BOTSPEED);

   } else {

      ai_botcharge (BOTSPEED);

   }
   BotPostThink ();

};

void () bot_axpain3 = [ 31.000, bot_axpain4 ] {

   if ( (self.skil >= TRUE) ) {

      BotAI_Main (BOTSPEED);

   }
   BotPostThink ();

};

void () bot_axpain4 = [ 32.000, bot_axpain5 ] {

   ai_botcharge (BOTSPEED);
   BotPostThink ();

};

void () bot_axpain5 = [ 33.000, bot_axpain6 ] {

   BotAI_Main (BOTSPEED);
   BotPostThink ();

};

void () bot_axpain6 = [ 34.000, bot_run ] {

   BotAI_Main (BOTSPEED);
   BotPostThink ();

};

void () bot_pain = {

   if ( self.weaponframe ) {

      return ;

   }
   if ( (self.invisible_finished > time) ) {

      return ;

   }
   if ( (self.weapon == IT_AXE) ) {

      bot_axpain1 ();

   } else {

      bot_pain1 ();

   }

};

void () bot_diea1;

void () bot_dieb1;

void () bot_diec1;

void () bot_died1;

void () bot_diee1;

void () bot_die_ax1;

void () BotDead = {

   self.nextthink = ((time + 0.300) + ((random () * (NUMBOTS + MOVETYPE_WALK)) * 0.100));
   if ( teamplay ) {

      self.nextthink = (self.nextthink + random ());

   }
   if ( TELEFRAGFLAG ) {

      self.nextthink = (self.nextthink + (MOVETYPE_FLY * random ()));
      TELEFRAGFLAG = FALSE;

   }
   self.think = respawnBot;
   self.deadflag = DEAD_DEAD;

};

void () BotDie = {

   local float i;

   if ( (self.deadflag != DEAD_NO) ) {

      return ;

   }
   self.items = (self.items - (self.items & IT_INVISIBILITY));
   self.invisible_finished = FALSE;
   self.invincible_finished = FALSE;
   self.super_damage_finished = FALSE;
   self.radsuit_finished = FALSE;
   self.modelindex = modelindex_player;
   DropBackpack ();
   self.weaponmodel = "";
   self.view_ofs = '0.000 0.000 -8.000';
   self.deadflag = DEAD_DYING;
   self.solid = SOLID_NOT;
   self.flags = (self.flags - (self.flags & FL_ONGROUND));
   self.movetype = MOVETYPE_TOSS;
   if ( (self.velocity_z < MOVETYPE_BOUNCE) ) {

      self.velocity_z = (self.velocity_z + (random () * 300.000));

   }
   if ( (self.health < -40.000) ) {

      GibPlayer ();
      BotDead ();
      return ;

   }
   DeathSound ();
   self.angles_x = FALSE;
   self.angles_z = FALSE;
   if ( (self.weapon == IT_AXE) ) {

      bot_die_ax1 ();
      return ;

   }
   i = cvar ("temp1");
   if ( !i ) {

      i = (TRUE + floor ((random () * MOVETYPE_TOSS)));

   }
   if ( (i == TRUE) ) {

      bot_diea1 ();

   } else {

      if ( (i == FL_SWIM) ) {

         bot_dieb1 ();

      } else {

         if ( (i == MOVETYPE_WALK) ) {

            bot_diec1 ();

         } else {

            if ( (i == MOVETYPE_STEP) ) {

               bot_died1 ();

            } else {

               bot_diee1 ();

            }

         }

      }

   }

};

void () bot_diea1 = [ 50.000, bot_diea2 ] {


};

void () bot_diea2 = [ 51.000, bot_diea3 ] {


};

void () bot_diea3 = [ 52.000, bot_diea4 ] {


};

void () bot_diea4 = [ 53.000, bot_diea5 ] {


};

void () bot_diea5 = [ 54.000, bot_diea6 ] {


};

void () bot_diea6 = [ 55.000, bot_diea7 ] {


};

void () bot_diea7 = [ 56.000, bot_diea8 ] {


};

void () bot_diea8 = [ 57.000, bot_diea9 ] {


};

void () bot_diea9 = [ 58.000, bot_diea10 ] {


};

void () bot_diea10 = [ 59.000, bot_diea11 ] {


};

void () bot_diea11 = [ 60.000, bot_diea11 ] {

   BotDead ();

};

void () bot_dieb1 = [ 61.000, bot_dieb2 ] {


};

void () bot_dieb2 = [ 62.000, bot_dieb3 ] {


};

void () bot_dieb3 = [ 63.000, bot_dieb4 ] {


};

void () bot_dieb4 = [ 64.000, bot_dieb5 ] {


};

void () bot_dieb5 = [ 65.000, bot_dieb6 ] {


};

void () bot_dieb6 = [ 66.000, bot_dieb7 ] {


};

void () bot_dieb7 = [ 67.000, bot_dieb8 ] {


};

void () bot_dieb8 = [ 68.000, bot_dieb9 ] {


};

void () bot_dieb9 = [ 69.000, bot_dieb9 ] {

   BotDead ();

};

void () bot_diec1 = [ 70.000, bot_diec2 ] {


};

void () bot_diec2 = [ 71.000, bot_diec3 ] {


};

void () bot_diec3 = [ 72.000, bot_diec4 ] {


};

void () bot_diec4 = [ 73.000, bot_diec5 ] {


};

void () bot_diec5 = [ 74.000, bot_diec6 ] {


};

void () bot_diec6 = [ 75.000, bot_diec7 ] {


};

void () bot_diec7 = [ 76.000, bot_diec8 ] {


};

void () bot_diec8 = [ 77.000, bot_diec9 ] {


};

void () bot_diec9 = [ 78.000, bot_diec10 ] {


};

void () bot_diec10 = [ 79.000, bot_diec11 ] {


};

void () bot_diec11 = [ 80.000, bot_diec12 ] {


};

void () bot_diec12 = [ 81.000, bot_diec13 ] {


};

void () bot_diec13 = [ 82.000, bot_diec14 ] {


};

void () bot_diec14 = [ 83.000, bot_diec15 ] {


};

void () bot_diec15 = [ 84.000, bot_diec15 ] {

   BotDead ();

};

void () bot_died1 = [ 85.000, bot_died2 ] {


};

void () bot_died2 = [ 86.000, bot_died3 ] {


};

void () bot_died3 = [ 87.000, bot_died4 ] {


};

void () bot_died4 = [ 88.000, bot_died5 ] {


};

void () bot_died5 = [ 89.000, bot_died6 ] {


};

void () bot_died6 = [ 90.000, bot_died7 ] {


};

void () bot_died7 = [ 91.000, bot_died8 ] {


};

void () bot_died8 = [ 92.000, bot_died9 ] {


};

void () bot_died9 = [ 93.000, bot_died9 ] {

   BotDead ();

};

void () bot_diee1 = [ 94.000, bot_diee2 ] {


};

void () bot_diee2 = [ 95.000, bot_diee3 ] {


};

void () bot_diee3 = [ 96.000, bot_diee4 ] {


};

void () bot_diee4 = [ 97.000, bot_diee5 ] {


};

void () bot_diee5 = [ 98.000, bot_diee6 ] {


};

void () bot_diee6 = [ 99.000, bot_diee7 ] {


};

void () bot_diee7 = [ 100.000, bot_diee8 ] {


};

void () bot_diee8 = [ 101.000, bot_diee9 ] {


};

void () bot_diee9 = [ 102.000, bot_diee9 ] {

   BotDead ();

};

void () bot_die_ax1 = [ 41.000, bot_die_ax2 ] {


};

void () bot_die_ax2 = [ 42.000, bot_die_ax3 ] {


};

void () bot_die_ax3 = [ 43.000, bot_die_ax4 ] {


};

void () bot_die_ax4 = [ 44.000, bot_die_ax5 ] {


};

void () bot_die_ax5 = [ 45.000, bot_die_ax6 ] {


};

void () bot_die_ax6 = [ 46.000, bot_die_ax7 ] {


};

void () bot_die_ax7 = [ 47.000, bot_die_ax8 ] {


};

void () bot_die_ax8 = [ 48.000, bot_die_ax9 ] {


};

void () bot_die_ax9 = [ 49.000, bot_die_ax9 ] {

   BotDead ();

};
