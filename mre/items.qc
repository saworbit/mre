
void () W_SetCurrentAmmo;

void () SUB_regen = {

   self.model = self.mdl;
   self.solid = SOLID_TRIGGER;
   if ( cvar("developer") && (self.classname == "item_artifact_super_damage") ) {
      dprint ("[QuadSpawn] origin=");
      dprint (vtos(self.origin));
      dprint ("\n");
   }
   sound (self,CHAN_VOICE,"items/itembk2.wav",TRUE,ATTN_NORM);
   setorigin (self,self.origin);

};

void () noclass = {

   dprint ("noclass spawned at");
   dprint (vtos (self.origin));
   dprint ("\n");
   remove (self);

};

void () PlaceItem = {

   local float oldz;

   self.mdl = self.model;
   self.flags = FL_ITEM;
   self.solid = SOLID_TRIGGER;
   self.movetype = MOVETYPE_TOSS;
   self.velocity = VEC_ORIGIN;
   self.origin_z = (self.origin_z + MOVETYPE_TOSS);
   oldz = self.origin_z;
   if ( !droptofloor () ) {

      dprint ("Bonus item fell out of level at ");
      dprint (vtos (self.origin));
      dprint ("\n");
      remove (self);
      return ;

   }

};

void () StartItem = {

   self.nextthink = (time + 0.200);
   self.think = PlaceItem;

};
float (entity e, float healamount, float ignore) T_Heal = {

   if ( (e.health <= FALSE) ) {

      return ( FALSE );

   }
   if ( (!ignore && (e.health >= other.max_health)) ) {

      return ( FALSE );

   }
   healamount = ceil (healamount);
   e.health = (e.health + healamount);
   if ( (!ignore && (e.health >= other.max_health)) ) {

      e.health = other.max_health;

   }
   if ( (e.health > 250.000) ) {

      e.health = 250.000;

   }
   return ( TRUE );

};
float H_ROTTEN    = 1.000;
float H_MEGA    = 2.000;
.float healamount;

void () health_touch;

void () item_megahealth_rot;

void () item_health = {

   self.touch = health_touch;
   self.th_weight = healthweight;
   if ( (self.spawnflags & H_ROTTEN) ) {

      precache_model ("maps/b_bh10.bsp");
      precache_sound ("items/r_item1.wav");
      setmodel (self,"maps/b_bh10.bsp");
      self.noise = "items/r_item1.wav";
      self.healamount = 15.000;
      self.healtype = FALSE;

   } else {

      if ( (self.spawnflags & H_MEGA) ) {

         precache_model ("maps/b_bh100.bsp");
         precache_sound ("items/r_item2.wav");
         setmodel (self,"maps/b_bh100.bsp");
         self.noise = "items/r_item2.wav";
         self.healamount = MUST_HAVE;
         self.healtype = FL_SWIM;
         self.th_cache = cachepowerup;
         self.th_update = updatepowerup;

      } else {

         precache_model ("maps/b_bh25.bsp");
         precache_sound ("items/health1.wav");
         setmodel (self,"maps/b_bh25.bsp");
         self.noise = "items/health1.wav";
         self.healamount = 25.000;
         self.healtype = TRUE;

      }

   }
   setsize (self,VEC_ORIGIN,'32.000 32.000 56.000');
   StartItem ();

};

void () health_touch = {

   local string s;

   if ( (other.classname != "player") ) {

      if ( (other.classname != "dmbot") ) {

         return ;

      }

   }
   if ( (self.healtype == FL_SWIM) ) {

      if ( (other.health >= 250.000) ) {

         return ;

      }
      if ( !T_Heal (other,self.healamount,TRUE) ) {

         return ;

      }

   } else {

      if ( !T_Heal (other,self.healamount,FALSE) ) {

         return ;

      }

   }
   if ( (other.classname == "dmbot") ) {

      bot_toucheditem ();

   }
   if ( (other.classname == "player") ) {

      sprint (other,"You receive ");
      s = ftos (self.healamount);
      sprint (other,s);
      sprint (other," health\n");

   }
   sound (other,CHAN_ITEM,self.noise,TRUE,ATTN_NORM);
   if ( (other.classname == "player") ) {

      stuffcmd (other,"bf\n");

   }
   self.model = string_null;
   self.solid = SOLID_NOT;
   if ( (self.healtype == FL_SWIM) ) {

      other.items = (other.items | IT_SUPERHEALTH);
      self.nextthink = (time + MOVETYPE_FLY);
      self.think = item_megahealth_rot;
      self.owner = other;
      if ( other.movetarget.movetarget ) {

         cacheRoute (other.movetarget,other.movetarget.movetarget,FALSE,self);

      }

   } else {

      if ( (deathmatch != FL_SWIM) ) {

         if ( deathmatch ) {

            self.nextthink = (time + KINDA_WANT);

         }
         self.think = SUB_regen;

      }

   }
   activator = other;
   SUB_UseTargets ();

};

void () item_megahealth_rot = {

   other = self.owner;
   if ( (other.health > other.max_health) ) {

      other.health = (other.health - TRUE);
      self.nextthink = (time + TRUE);
      return ;

   }
   other.items = (other.items - (other.items & IT_SUPERHEALTH));
   if ( (deathmatch == TRUE) ) {

      self.nextthink = (time + KINDA_WANT);
      self.think = SUB_regen;

   }

};

void () armor_touch = {

   local float type;
   local float value;
   local float bit;

   if ( (other.health <= FALSE) ) {

      return ;

   }
   if ( (other.classname != "player") ) {

      if ( (other.classname != "dmbot") ) {

         return ;

      }

   }
   if ( (self.classname == "item_armor1") ) {

      type = 0.300;
      value = MUST_HAVE;
      bit = IT_ARMOR1;

   }
   if ( (self.classname == "item_armor2") ) {

      type = 0.600;
      value = 150.000;
      bit = IT_ARMOR2;
      if ( other.movetarget.movetarget ) {

         cacheRoute (other.movetarget,other.movetarget.movetarget,FALSE,self);

      }

   }
   if ( (self.classname == "item_armorInv") ) {

      type = 0.800;
      value = 200.000;
      bit = IT_ARMOR3;
      if ( other.movetarget.movetarget ) {

         cacheRoute (other.movetarget,other.movetarget.movetarget,FALSE,self);

      }

   }
   if ( ((other.armortype * other.armorvalue) >= (type * value)) ) {

      return ;

   }
   other.armortype = type;
   other.armorvalue = value;
   other.items = ((other.items - (other.items & ((IT_ARMOR1 | IT_ARMOR2) | IT_ARMOR3))) + bit);
   self.solid = SOLID_NOT;
   self.model = string_null;
   if ( (deathmatch == TRUE) ) {

      self.nextthink = (time + KINDA_WANT);

   }
   self.think = SUB_regen;
   if ( (other.classname == "dmbot") ) {

      bot_toucheditem ();

   }
   if ( (other.classname == "player") ) {

      sprint (other,"You got armor\n");

   }
   sound (other,CHAN_ITEM,"items/armor1.wav",TRUE,ATTN_NORM);
   if ( (other.classname == "player") ) {

      stuffcmd (other,"bf\n");

   }
   activator = other;
   SUB_UseTargets ();

};

void () item_armor1 = {

   self.touch = armor_touch;
   precache_model ("progs/armor.mdl");
   setmodel (self,"progs/armor.mdl");
   self.skin = FALSE;
   self.armorvalue = MUST_HAVE;
   setsize (self,'-16.000 -16.000 0.000','16.000 16.000 56.000');
   self.th_weight = armorweight;
   StartItem ();

};

void () item_armor2 = {

   self.touch = armor_touch;
   precache_model ("progs/armor.mdl");
   setmodel (self,"progs/armor.mdl");
   self.skin = TRUE;
   self.armorvalue = 150.000;
   setsize (self,'-16.000 -16.000 0.000','16.000 16.000 56.000');
   self.th_weight = armorweight;
   self.th_cache = cachearmor;
   self.th_update = updatearmor;
   StartItem ();

};

void () item_armorInv = {

   self.touch = armor_touch;
   precache_model ("progs/armor.mdl");
   setmodel (self,"progs/armor.mdl");
   self.skin = FL_SWIM;
   self.armorvalue = 200.000;
   setsize (self,'-16.000 -16.000 0.000','16.000 16.000 56.000');
   self.th_weight = armorweight;
   self.th_cache = cachearmor;
   self.th_update = updatearmor;
   StartItem ();

};

void () bound_other_ammo = {

   if ( (other.ammo_shells > MUST_HAVE) ) {

      other.ammo_shells = MUST_HAVE;

   }
   if ( (other.ammo_nails > 200.000) ) {

      other.ammo_nails = 200.000;

   }
   if ( (other.ammo_rockets > MUST_HAVE) ) {

      other.ammo_rockets = MUST_HAVE;

   }
   if ( (other.ammo_cells > MUST_HAVE) ) {

      other.ammo_cells = MUST_HAVE;

   }

};
float (float w) RankForWeapon = {

   if ( (w == IT_LIGHTNING) ) {

      return ( TRUE );

   }
   if ( (w == IT_ROCKET_LAUNCHER) ) {

      return ( FL_SWIM );

   }
   if ( (w == IT_SUPER_NAILGUN) ) {

      return ( MOVETYPE_WALK );

   }
   if ( (w == IT_GRENADE_LAUNCHER) ) {

      return ( MOVETYPE_STEP );

   }
   if ( (w == IT_SUPER_SHOTGUN) ) {

      return ( MOVETYPE_FLY );

   }
   if ( (w == IT_NAILGUN) ) {

      return ( MOVETYPE_TOSS );

   }
   return ( MOVETYPE_PUSH );

};

void (float old, float new) Deathmatch_Weapon = {

   local float or;
   local float nr;

   or = RankForWeapon (self.weapon);
   nr = RankForWeapon (new);
   if ( (nr < or) ) {

      self.weapon = new;

   }

};
float () W_BestWeapon;

void (entity picker, entity item) BoostLinkUsageForPickup = {

   local entity wp;
   local entity best;
   local float best_dist;
   local float dist;

   if ( !picker.last_waypoint || (picker.last_waypoint == world) ) {
      return ;
   }

   best = world;
   best_dist = 99999.000;
   wp = findradius (item.origin,100.000);
   while ( wp ) {
      if ( (wp.classname == "BotPath") ) {
         dist = vlen ((wp.origin - item.origin));
         if ( (dist < best_dist) ) {
            best_dist = dist;
            best = wp;
         }
      }
      wp = wp.chain;
   }

   if ( !best || (best == world) ) {
      return ;
   }

   if ( (picker.last_waypoint.movetarget == best) ) {
      picker.last_waypoint.link_usage1 = (picker.last_waypoint.link_usage1 + 10.000);
   } else if ( (picker.last_waypoint.movetarget2 == best) ) {
      picker.last_waypoint.link_usage2 = (picker.last_waypoint.link_usage2 + 10.000);
   } else if ( (picker.last_waypoint.movetarget3 == best) ) {
      picker.last_waypoint.link_usage3 = (picker.last_waypoint.link_usage3 + 10.000);
   } else if ( (picker.last_waypoint.movetarget4 == best) ) {
      picker.last_waypoint.link_usage4 = (picker.last_waypoint.link_usage4 + 10.000);
   } else if ( (picker.last_waypoint.movetarget5 == best) ) {
      picker.last_waypoint.link_usage5 = (picker.last_waypoint.link_usage5 + 10.000);
   } else if ( (picker.last_waypoint.movetarget6 == best) ) {
      picker.last_waypoint.link_usage6 = (picker.last_waypoint.link_usage6 + 10.000);
   }

};

void () weapon_touch = {

   local float hadammo;
   local float best;
   local float new;
   local float old;
   local entity stemp;
   local float leave;

 
  
   if ( (other.classname == "peeper") ) {

      return ;

   }
  if  ( (other.classname != "player" && other.classname != "dmbot") ) {

         return ;

      }

   
   stemp = self;
   self = other;
   if ( (self.classname == "player") ) {

      best = W_BestWeapon ();

   }
   self = stemp;
   if ( ((deathmatch == FL_SWIM) || coop) ) {

      leave = TRUE;

   } else {

      leave = FALSE;

   }
   if ( (self.classname == "weapon_nailgun") ) {

      if ( (leave && (other.items & IT_NAILGUN)) ) {

         return ;

      }
      hadammo = other.ammo_nails;
      new = IT_NAILGUN;
      other.ammo_nails = (other.ammo_nails + SVC_INTERMISSION);

   } else {

      if ( (self.classname == "weapon_supernailgun") ) {

         if ( (leave && (other.items & IT_SUPER_NAILGUN)) ) {

            return ;

         }
         hadammo = other.ammo_rockets;
         new = IT_SUPER_NAILGUN;
         other.ammo_nails = (other.ammo_nails + SVC_INTERMISSION);
         if ( other.movetarget.movetarget ) {

            cacheRoute (other.movetarget,other.movetarget.movetarget,FALSE,self);

         }

      } else {

         if ( (self.classname == "weapon_supershotgun") ) {

            if ( (leave && (other.items & IT_SUPER_SHOTGUN)) ) {

               return ;

            }
            hadammo = other.ammo_rockets;
            new = IT_SUPER_SHOTGUN;
            other.ammo_shells = (other.ammo_shells + MOVETYPE_FLY);

         } else {

            if ( (self.classname == "weapon_rocketlauncher") ) {

               if ( (leave && (other.items & IT_ROCKET_LAUNCHER)) ) {

                  return ;

               }
               hadammo = other.ammo_rockets;
               new = IT_ROCKET_LAUNCHER;
               other.ammo_rockets = (other.ammo_rockets + MOVETYPE_FLY);
               if ( other.movetarget.movetarget ) {

                  cacheRoute (other.movetarget,other.movetarget.movetarget,FALSE,self);

               }
               // EPISODIC LEARNING: RL is a major weapon
               if ( other.classname == "player" && !hadammo ) {
                  LockInPowerupPath (other, "Weapon");
               }

            } else {

               if ( (self.classname == "weapon_grenadelauncher") ) {

                  if ( (leave && (other.items & IT_GRENADE_LAUNCHER)) ) {

                     return ;

                  }
                  hadammo = other.ammo_rockets;
                  new = IT_GRENADE_LAUNCHER;
                  other.ammo_rockets = (other.ammo_rockets + MOVETYPE_FLY);
                  if ( other.movetarget.movetarget ) {

                     cacheRoute (other.movetarget,other.movetarget.movetarget,FALSE,self);

                  }

               } else {

                  if ( (self.classname == "weapon_lightning") ) {

                     if ( (leave && (other.items & IT_LIGHTNING)) ) {

                        return ;

                     }
                     hadammo = other.ammo_rockets;
                     new = IT_LIGHTNING;
                     other.ammo_cells = (other.ammo_cells + 15.000);
                     if ( other.movetarget.movetarget ) {

                        cacheRoute (other.movetarget,other.movetarget.movetarget,FALSE,self);

                     }
                     // EPISODIC LEARNING: LG is a major weapon
                     if ( other.classname == "player" && !hadammo ) {
                        LockInPowerupPath (other, "Weapon");
                     }

                  } else {

                     objerror ("weapon_touch: unknown classname");

                  }

               }

            }

         }

      }

   }
   if ( (other.classname == "player") ) {

      sprint (other,"You got the ");
      sprint (other,self.netname);
      sprint (other,"\n");

   }
   sound (other,CHAN_ITEM,"weapons/pkup.wav",TRUE,ATTN_NORM);
   if ( (other.classname == "player") ) {

      stuffcmd (other,"bf\n");

   }
   bound_other_ammo ();
   old = other.items;
   other.items = (other.items | new);
   stemp = self;
   self = other;
   if ( !deathmatch ) {

      self.weapon = new;

   } else {

      Deathmatch_Weapon (old,new);

   }
   W_SetCurrentAmmo ();
   self = stemp;
   if ( (other.classname == "player") ) {
      BoostLinkUsageForPickup (other,self);
      if ( (new == IT_ROCKET_LAUNCHER) || (new == IT_LIGHTNING) ) {
         BackPropagateReward (other, 100.000);
         if ( cvar("developer") ) {
            dprint ("Learned path to Power Weapon!\n");
         }
      } else {
         BackPropagateReward (other, 20.000);
      }
   }
   if ( leave ) {

      return ;

   }
   self.model = string_null;
   self.solid = SOLID_NOT;
   if ( (deathmatch == TRUE) ) {

      self.nextthink = (time + SVC_INTERMISSION);

   }
   self.think = SUB_regen;
   activator = other;
   SUB_UseTargets ();

};

void () weapon_supershotgun = {

   precache_model ("progs/g_shot.mdl");
   setmodel (self,"progs/g_shot.mdl");
   self.weapon = IT_SUPER_SHOTGUN;
   self.netname = "Double-barrelled Shotgun";
   self.touch = weapon_touch;
   setsize (self,'-16.000 -16.000 0.000','16.000 16.000 56.000');
   self.th_weight = ssgweight;
   StartItem ();

};

void () weapon_nailgun = {

   precache_model ("progs/g_nail.mdl");
   setmodel (self,"progs/g_nail.mdl");
   self.weapon = IT_NAILGUN;
   self.netname = "nailgun";
   self.touch = weapon_touch;
   setsize (self,'-16.000 -16.000 0.000','16.000 16.000 56.000');
   self.th_weight = nailgunweight;
   StartItem ();

};

void () weapon_supernailgun = {

   precache_model ("progs/g_nail2.mdl");
   setmodel (self,"progs/g_nail2.mdl");
   self.weapon = IT_SUPER_NAILGUN;
   self.netname = "Super Nailgun";
   self.touch = weapon_touch;
   setsize (self,'-16.000 -16.000 0.000','16.000 16.000 56.000');
   self.th_weight = supernailweight;
   self.th_cache = cachenail;
   self.th_update = updatenail;
   StartItem ();

};

void () weapon_grenadelauncher = {

   precache_model ("progs/g_rock.mdl");
   setmodel (self,"progs/g_rock.mdl");
   self.weapon = MOVETYPE_WALK;
   self.netname = "Grenade Launcher";
   self.touch = weapon_touch;
   setsize (self,'-16.000 -16.000 0.000','16.000 16.000 56.000');
   self.th_weight = glauncherweight;
   self.th_cache = cachegrenade;
   self.th_update = updategrenade;
   StartItem ();

};

void () weapon_rocketlauncher = {

   precache_model ("progs/g_rock2.mdl");
   setmodel (self,"progs/g_rock2.mdl");
   self.weapon = MOVETYPE_WALK;
   self.netname = "Rocket Launcher";
   self.touch = weapon_touch;
   setsize (self,'-16.000 -16.000 0.000','16.000 16.000 56.000');
   self.th_weight = rlauncherweight;
   self.th_cache = cacherocket;
   self.th_update = updaterocket;
   StartItem ();

};

void () weapon_lightning = {

   precache_model ("progs/g_light.mdl");
   setmodel (self,"progs/g_light.mdl");
   self.weapon = MOVETYPE_WALK;
   self.netname = "Thunderbolt";
   self.touch = weapon_touch;
   setsize (self,'-16.000 -16.000 0.000','16.000 16.000 56.000');
   self.th_weight = lightningweight;
   self.th_cache = cachelightning;
   self.th_update = updatelightning;
   StartItem ();

};

void () ammo_touch = {

   local entity stemp;
   local float best;

   if ( (other.classname != "player") ) {

      if ( (other.classname != "dmbot") ) {

         return ;

      }

   }
   if ( (other.health <= FALSE) ) {

      return ;

   }
   stemp = self;
   self = other;
   best = W_BestWeapon ();
   self = stemp;
   if ( (self.weapon == TRUE) ) {

      if ( (other.ammo_shells >= MUST_HAVE) ) {

         return ;

      }
      other.ammo_shells = (other.ammo_shells + self.aflag);

   }
   if ( (self.weapon == FL_SWIM) ) {

      if ( (other.ammo_nails >= 200.000) ) {

         return ;

      }
      other.ammo_nails = (other.ammo_nails + self.aflag);

   }
   if ( (self.weapon == MOVETYPE_WALK) ) {

      if ( (other.ammo_rockets >= MUST_HAVE) ) {

         return ;

      }
      other.ammo_rockets = (other.ammo_rockets + self.aflag);

   }
   if ( (self.weapon == MOVETYPE_STEP) ) {

      if ( (other.ammo_cells >= 200.000) ) {

         return ;

      }
      other.ammo_cells = (other.ammo_cells + self.aflag);

   }
   if ( (other.classname == "dmbot") ) {

      bot_toucheditem ();

   }
   bound_other_ammo ();
   if ( (other.classname == "player") ) {

      sprint (other,"You got the ");
      sprint (other,self.netname);
      sprint (other,"\n");

   }
   sound (other,CHAN_ITEM,"weapons/lock4.wav",TRUE,ATTN_NORM);
   if ( (other.classname == "player") ) {

      stuffcmd (other,"bf\n");

   }
   if ( (other.weapon == best) ) {

      stemp = self;
      self = other;
      self.weapon = W_BestWeapon ();
      W_SetCurrentAmmo ();
      self = stemp;

   }
   stemp = self;
   self = other;
   W_SetCurrentAmmo ();
   self = stemp;
   if ( (other.classname == "player") ) {
      BoostLinkUsageForPickup (other,self);
      BackPropagateReward (other, 500.000);
      if ( cvar("developer") ) {
         dprint ("Learned CRITICAL path to Powerup!\n");
      }
   }
   self.model = string_null;
   self.solid = SOLID_NOT;
   if ( (deathmatch == TRUE) ) {

      self.nextthink = (time + SVC_INTERMISSION);

   }
   self.think = SUB_regen;
   activator = other;
   SUB_UseTargets ();

};
float WEAPON_BIG2    = 1.000;

void () item_shells = {

   self.touch = ammo_touch;
   if ( (self.spawnflags & WEAPON_BIG2) ) {

      precache_model ("maps/b_shell1.bsp");
      setmodel (self,"maps/b_shell1.bsp");
      self.aflag = 40.000;

   } else {

      precache_model ("maps/b_shell0.bsp");
      setmodel (self,"maps/b_shell0.bsp");
      self.aflag = KINDA_WANT;

   }
   self.weapon = TRUE;
   self.netname = "shells";
   setsize (self,VEC_ORIGIN,'32.000 32.000 56.000');
   self.th_weight = shellweight;
   StartItem ();

};

void () item_spikes = {

   self.touch = ammo_touch;
   if ( (self.spawnflags & WEAPON_BIG2) ) {

      precache_model ("maps/b_nail1.bsp");
      setmodel (self,"maps/b_nail1.bsp");
      self.aflag = 50.000;

   } else {

      precache_model ("maps/b_nail0.bsp");
      setmodel (self,"maps/b_nail0.bsp");
      self.aflag = 25.000;

   }
   self.weapon = FL_SWIM;
   self.netname = "nails";
   setsize (self,VEC_ORIGIN,'32.000 32.000 56.000');
   self.th_weight = nailweight;
   StartItem ();

};

void () item_rockets = {

   self.touch = ammo_touch;
   if ( (self.spawnflags & WEAPON_BIG2) ) {

      precache_model ("maps/b_rock1.bsp");
      setmodel (self,"maps/b_rock1.bsp");
      self.aflag = MOVETYPE_BOUNCE;

   } else {

      precache_model ("maps/b_rock0.bsp");
      setmodel (self,"maps/b_rock0.bsp");
      self.aflag = MOVETYPE_FLY;

   }
   self.weapon = MOVETYPE_WALK;
   self.netname = "rockets";
   setsize (self,VEC_ORIGIN,'32.000 32.000 56.000');
   self.th_weight = rocketweight;
   StartItem ();

};

void () item_cells = {

   self.touch = ammo_touch;
   if ( (self.spawnflags & WEAPON_BIG2) ) {

      precache_model ("maps/b_batt1.bsp");
      setmodel (self,"maps/b_batt1.bsp");
      self.aflag = 12.000;

   } else {

      precache_model ("maps/b_batt0.bsp");
      setmodel (self,"maps/b_batt0.bsp");
      self.aflag = MOVETYPE_TOSS;

   }
   self.weapon = MOVETYPE_STEP;
   self.netname = "cells";
   setsize (self,VEC_ORIGIN,'32.000 32.000 56.000');
   self.th_weight = cellweight;
   StartItem ();

};
float WEAPON_SHOTGUN    = 1.000;
float WEAPON_ROCKET    = 2.000;
float WEAPON_SPIKES    = 4.000;
float WEAPON_BIG    = 8.000;

void () item_weapon = {

   self.touch = ammo_touch;
   if ( (self.spawnflags & WEAPON_SHOTGUN) ) {

      if ( (self.spawnflags & WEAPON_BIG) ) {

         precache_model ("maps/b_shell1.bsp");
         setmodel (self,"maps/b_shell1.bsp");
         self.aflag = 40.000;

      } else {

         precache_model ("maps/b_shell0.bsp");
         setmodel (self,"maps/b_shell0.bsp");
         self.aflag = KINDA_WANT;

      }
      self.weapon = TRUE;
      self.netname = "shells";

   }
   if ( (self.spawnflags & WEAPON_SPIKES) ) {

      if ( (self.spawnflags & WEAPON_BIG) ) {

         precache_model ("maps/b_nail1.bsp");
         setmodel (self,"maps/b_nail1.bsp");
         self.aflag = 40.000;

      } else {

         precache_model ("maps/b_nail0.bsp");
         setmodel (self,"maps/b_nail0.bsp");
         self.aflag = KINDA_WANT;

      }
      self.weapon = FL_SWIM;
      self.netname = "spikes";

   }
   if ( (self.spawnflags & WEAPON_ROCKET) ) {

      if ( (self.spawnflags & WEAPON_BIG) ) {

         precache_model ("maps/b_rock1.bsp");
         setmodel (self,"maps/b_rock1.bsp");
         self.aflag = MOVETYPE_BOUNCE;

      } else {

         precache_model ("maps/b_rock0.bsp");
         setmodel (self,"maps/b_rock0.bsp");
         self.aflag = MOVETYPE_FLY;

      }
      self.weapon = MOVETYPE_WALK;
      self.netname = "rockets";

   }
   setsize (self,VEC_ORIGIN,'32.000 32.000 56.000');
   StartItem ();

};

void () key_touch = {

   if ( (other.classname != "player") ) {

      if ( (other.classname != "dmbot") ) {

         return ;

      }

   }
   if ( (other.health <= FALSE) ) {

      return ;

   }
   if ( (other.items & self.items) ) {

      return ;

   }
   if ( (other.classname == "player") ) {

      sprint (other,"You got the ");
      sprint (other,self.netname);
      sprint (other,"\n");

   }
   sound (other,CHAN_ITEM,self.noise,TRUE,ATTN_NORM);
   if ( (other.classname == "player") ) {

      stuffcmd (other,"bf\n");

   }
   other.items = (other.items | self.items);
   if ( !coop ) {

      self.solid = SOLID_NOT;
      self.model = string_null;

   }
   activator = other;
   SUB_UseTargets ();

};

void () key_setsounds = {

   if ( (world.worldtype == FALSE) ) {

      precache_sound ("misc/medkey.wav");
      self.noise = "misc/medkey.wav";

   }
   if ( (world.worldtype == TRUE) ) {

      precache_sound ("misc/runekey.wav");
      self.noise = "misc/runekey.wav";

   }
   if ( (world.worldtype == FL_SWIM) ) {

      precache_sound2 ("misc/basekey.wav");
      self.noise = "misc/basekey.wav";

   }

};

void () item_key1 = {

   if ( (world.worldtype == FALSE) ) {

      precache_model ("progs/w_s_key.mdl");
      setmodel (self,"progs/w_s_key.mdl");
      self.netname = "silver key";

   } else {

      if ( (world.worldtype == TRUE) ) {

         precache_model ("progs/m_s_key.mdl");
         setmodel (self,"progs/m_s_key.mdl");
         self.netname = "silver runekey";

      } else {

         if ( (world.worldtype == FL_SWIM) ) {

            precache_model2 ("progs/b_s_key.mdl");
            setmodel (self,"progs/b_s_key.mdl");
            self.netname = "silver keycard";

         }

      }

   }
   key_setsounds ();
   self.touch = key_touch;
   self.items = IT_KEY1;
   setsize (self,VEC_HULL_MIN,VEC_HULL_MAX);
   StartItem ();

};

void () item_key2 = {

   if ( (world.worldtype == FALSE) ) {

      precache_model ("progs/w_g_key.mdl");
      setmodel (self,"progs/w_g_key.mdl");
      self.netname = "gold key";

   }
   if ( (world.worldtype == TRUE) ) {

      precache_model ("progs/m_g_key.mdl");
      setmodel (self,"progs/m_g_key.mdl");
      self.netname = "gold runekey";

   }
   if ( (world.worldtype == FL_SWIM) ) {

      precache_model2 ("progs/b_g_key.mdl");
      setmodel (self,"progs/b_g_key.mdl");
      self.netname = "gold keycard";

   }
   key_setsounds ();
   self.touch = key_touch;
   self.items = IT_KEY2;
   setsize (self,VEC_HULL_MIN,VEC_HULL_MAX);
   StartItem ();

};

void () sigil_touch = {

   if ( (other.classname != "player") ) {

      return ;

   }
   if ( (other.health <= FALSE) ) {

      return ;

   }
   centerprint (other,"You got the rune!");
   sound (other,CHAN_ITEM,self.noise,TRUE,ATTN_NORM);
   stuffcmd (other,"bf\n");
   self.solid = SOLID_NOT;
   self.model = string_null;
   serverflags = (serverflags | (self.spawnflags & 15.000));
   self.classname = "";
   activator = other;
   SUB_UseTargets ();

};

void () item_sigil = {

   if ( !self.spawnflags ) {

      objerror ("no spawnflags");

   }
   precache_sound ("misc/runekey.wav");
   self.noise = "misc/runekey.wav";
   if ( (self.spawnflags & TRUE) ) {

      precache_model ("progs/end1.mdl");
      setmodel (self,"progs/end1.mdl");

   }
   if ( (self.spawnflags & FL_SWIM) ) {

      precache_model2 ("progs/end2.mdl");
      setmodel (self,"progs/end2.mdl");

   }
   if ( (self.spawnflags & MOVETYPE_STEP) ) {

      precache_model2 ("progs/end3.mdl");
      setmodel (self,"progs/end3.mdl");

   }
   if ( (self.spawnflags & FL_CLIENT) ) {

      precache_model2 ("progs/end4.mdl");
      setmodel (self,"progs/end4.mdl");

   }
   self.touch = sigil_touch;
   setsize (self,VEC_HULL_MIN,VEC_HULL_MAX);
   StartItem ();

};

void () powerup_touch = {

   local float dist;
   local float tr_allsolid;
   local float tr_startsolid;
   local float tr_fraction;
   local vector tr_endpos;
   local vector tr_plane_normal;
   local float tr_plane_dist;
   local entity tr_ent;
   local float tr_inopen;
   local float tr_inwater;

   if ( (other.classname != "player") ) {

      if ( (other.classname != "dmbot") ) {

         return ;

      }

   }
   if ( (other.health <= FALSE) ) {

      return ;

   }
   dist = vlen (other.origin - self.origin);
   // Guard against ghost touches (e.g., bot target overlap far from item).
   if ( (dist > 96.000) ) {
      if ( cvar("developer") && (self.classname == "item_artifact_super_damage") ) {
         dprint ("[QuadTouch] reject dist=");
         dprint (ftos(floor(dist)));
         dprint (" bot=");
         dprint (other.netname);
         dprint (" bot_org=");
         dprint (vtos(other.origin));
         dprint (" quad_org=");
         dprint (vtos(self.origin));
         dprint ("\n");
      }

      return ;

   }
   // Prevent picking through thin walls/doors by requiring line-of-sight to the item.
   tr_allsolid = trace_allsolid;
   tr_startsolid = trace_startsolid;
   tr_fraction = trace_fraction;
   tr_endpos = trace_endpos;
   tr_plane_normal = trace_plane_normal;
   tr_plane_dist = trace_plane_dist;
   tr_ent = trace_ent;
   tr_inopen = trace_inopen;
   tr_inwater = trace_inwater;
   traceline ((self.origin + '0 0 16'),(other.origin + other.view_ofs),FALSE,self);
   if ( trace_startsolid || trace_allsolid || (trace_ent != other) ) {
      if ( cvar("developer") && (self.classname == "item_artifact_super_damage") ) {
         dprint ("[QuadTouch] blocked dist=");
         dprint (ftos(floor(dist)));
         dprint (" frac=");
         dprint (ftos(trace_fraction));
         dprint (" startsolid=");
         dprint (ftos(trace_startsolid));
         dprint (" allsolid=");
         dprint (ftos(trace_allsolid));
         dprint (" ent=");
         if ( trace_ent ) {
            dprint (trace_ent.classname);
         } else {
            dprint ("none");
         }
         dprint (" bot=");
         dprint (other.netname);
         dprint (" bot_org=");
         dprint (vtos(other.origin));
         dprint (" quad_org=");
         dprint (vtos(self.origin));
         dprint ("\n");
      }
      trace_allsolid = tr_allsolid;
      trace_startsolid = tr_startsolid;
      trace_fraction = tr_fraction;
      trace_endpos = tr_endpos;
      trace_plane_normal = tr_plane_normal;
      trace_plane_dist = tr_plane_dist;
      trace_ent = tr_ent;
      trace_inopen = tr_inopen;
      trace_inwater = tr_inwater;
      return ;
   }
   trace_allsolid = tr_allsolid;
   trace_startsolid = tr_startsolid;
   trace_fraction = tr_fraction;
   trace_endpos = tr_endpos;
   trace_plane_normal = tr_plane_normal;
   trace_plane_dist = tr_plane_dist;
   trace_ent = tr_ent;
   trace_inopen = tr_inopen;
   trace_inwater = tr_inwater;
   if ( cvar("developer") && (self.classname == "item_artifact_super_damage") ) {
      dprint ("[QuadTouch] accept dist=");
      dprint (ftos(floor(dist)));
      dprint (" bot=");
      dprint (other.netname);
      dprint (" bot_org=");
      dprint (vtos(other.origin));
      dprint (" quad_org=");
      dprint (vtos(self.origin));
      dprint ("\n");
   }
   if ( (other.classname == "player") ) {

      sprint (other,"You got the ");
      sprint (other,self.netname);
      sprint (other,"\n");

   }
   if ( deathmatch ) {

      self.mdl = self.model;
      if ( ((self.classname == "item_artifact_invulnerability") || (self.classname == "item_artifact_invisibility")) ) {

         self.nextthink = (time + (60.000 * MOVETYPE_FLY));

      } else {

         self.nextthink = (time + 60.000);

      }
      self.think = SUB_regen;

   }
   sound (other,CHAN_VOICE,self.noise,TRUE,ATTN_NORM);
   if ( (other.classname == "player") ) {

      stuffcmd (other,"bf\n");

   }
   self.solid = SOLID_NOT;
   other.items = (other.items | self.items);
   if ( (other.classname == "player") ) {
      BoostLinkUsageForPickup (other,self);
   }
   self.model = string_null;
   if ( (self.classname == "item_artifact_envirosuit") ) {

      other.rad_time = TRUE;
      other.radsuit_finished = (time + SVC_INTERMISSION);
      // MAP CONTROL: Track biosuit respawn (60s)
      next_suit_time = time + 60;

   }
   if ( (self.classname == "item_artifact_invulnerability") ) {

      other.invincible_time = TRUE;
      other.invincible_finished = (time + SVC_INTERMISSION);
      if ( other.movetarget.movetarget ) {

         cacheRoute (other.movetarget,other.movetarget.movetarget,FALSE,self);

      }
      // MAP CONTROL: Track Pentagram respawn (5 minutes)
      next_pent_time = time + 300;
      pent_spawn_ent = self;
      if ( cvar("developer") ) {
         bprint("Bots learned: Pent spawns in 300s\n");
      }
      // EPISODIC LEARNING: Lock in the path used to get here
      if ( other.classname == "player" ) {
         LockInPowerupPath (other, "Pent");
      }

   }
   if ( (self.classname == "item_artifact_invisibility") ) {

      other.invisible_time = TRUE;
      other.invisible_finished = (time + SVC_INTERMISSION);
      if ( other.movetarget.movetarget ) {

         cacheRoute (other.movetarget,other.movetarget.movetarget,FALSE,self);

      }
      // MAP CONTROL: Track Ring respawn (5 minutes)
      next_ring_time = time + 300;
      ring_spawn_ent = self;
      if ( cvar("developer") ) {
         bprint("Bots learned: Ring spawns in 300s\n");
      }
      // EPISODIC LEARNING: Lock in the path used to get here
      if ( other.classname == "player" ) {
         LockInPowerupPath (other, "Ring");
      }

   }
   if ( (self.classname == "item_artifact_super_damage") ) {

      other.super_time = TRUE;
      other.super_damage_finished = (time + SVC_INTERMISSION);
      if ( other.movetarget.movetarget ) {

         cacheRoute (other.movetarget,other.movetarget.movetarget,FALSE,self);

      }
      // MAP CONTROL: Track Quad respawn (60s)
      next_quad_time = time + 60;
      quad_spawn_ent = self;
      if ( cvar("developer") ) {
         bprint("Bots learned: Quad spawns in 60s\n");
      }
      // EPISODIC LEARNING: Lock in the path used to get here
      if ( other.classname == "player" ) {
         LockInPowerupPath (other, "Quad");
      }

   }
   activator = other;
   SUB_UseTargets ();

};

void () item_artifact_invulnerability = {

   self.touch = powerup_touch;
   precache_model ("progs/invulner.mdl");
   precache_sound ("items/protect.wav");
   precache_sound ("items/protect2.wav");
   precache_sound ("items/protect3.wav");
   self.noise = "items/protect.wav";
   setmodel (self,"progs/invulner.mdl");
   self.netname = "Pentagram of Protection";
   self.items = IT_INVULNERABILITY;
   setsize (self,VEC_HULL_MIN,VEC_HULL_MAX);
   self.th_weight = artifactweight;
   self.th_cache = cachepowerup;
   self.th_update = updatepowerup;
   StartItem ();

};

void () item_artifact_envirosuit = {

   self.touch = powerup_touch;
   precache_model ("progs/suit.mdl");
   precache_sound ("items/suit.wav");
   precache_sound ("items/suit2.wav");
   self.noise = "items/suit.wav";
   setmodel (self,"progs/suit.mdl");
   self.netname = "Biosuit";
   self.items = IT_SUIT;
   setsize (self,VEC_HULL_MIN,VEC_HULL_MAX);
   self.th_weight = artifactweight;
   StartItem ();

};

void () item_artifact_invisibility = {

   self.touch = powerup_touch;
   precache_model ("progs/invisibl.mdl");
   precache_sound ("items/inv1.wav");
   precache_sound ("items/inv2.wav");
   precache_sound ("items/inv3.wav");
   self.noise = "items/inv1.wav";
   setmodel (self,"progs/invisibl.mdl");
   self.netname = "Ring of Shadows";
   self.items = IT_INVISIBILITY;
   setsize (self,VEC_HULL_MIN,VEC_HULL_MAX);
   self.th_weight = artifactweight;
   self.th_cache = cachepowerup;
   self.th_update = updatepowerup;
   StartItem ();

};

void () item_artifact_super_damage = {

   self.touch = powerup_touch;
   precache_model ("progs/quaddama.mdl");
   precache_sound ("items/damage.wav");
   precache_sound ("items/damage2.wav");
   precache_sound ("items/damage3.wav");
   self.noise = "items/damage.wav";
   setmodel (self,"progs/quaddama.mdl");
   self.netname = "Quad Damage";
   self.items = IT_QUAD;
   setsize (self,VEC_HULL_MIN,VEC_HULL_MAX);
   self.th_weight = artifactweight;
   self.th_cache = cachepowerup;
   self.th_update = updatepowerup;
   StartItem ();

};

void () BackpackTouch = {

   local string s;
   local float best;
   local entity stemp;

   if ( (other.classname != "player") ) {

      if ( (other.classname != "dmbot") ) {

         return ;

      }

   }
   if ( (other.classname == "dmbot") ) {

      bot_toucheditem ();

   }
   if ( (other.health <= FALSE) ) {

      return ;

   }
   stemp = self;
   self = other;
   best = W_BestWeapon ();
   self = stemp;
   other.ammo_shells = (other.ammo_shells + self.ammo_shells);
   other.ammo_nails = (other.ammo_nails + self.ammo_nails);
   other.ammo_rockets = (other.ammo_rockets + self.ammo_rockets);
   other.ammo_cells = (other.ammo_cells + self.ammo_cells);
   other.items = (other.items | self.items);
   bound_other_ammo ();
   if ( (other.classname == "player") ) {

      sprint (other,"You get ");
      if ( self.ammo_shells ) {

         s = ftos (self.ammo_shells);
         sprint (other,s);
         sprint (other," shells  ");

      }
      if ( self.ammo_nails ) {

         s = ftos (self.ammo_nails);
         sprint (other,s);
         sprint (other," nails ");

      }
      if ( self.ammo_rockets ) {

         s = ftos (self.ammo_rockets);
         sprint (other,s);
         sprint (other," rockets  ");

      }
      if ( self.ammo_cells ) {

         s = ftos (self.ammo_cells);
         sprint (other,s);
         sprint (other," cells  ");

      }
      sprint (other,"\n");

   }
   sound (other,CHAN_ITEM,"weapons/lock4.wav",TRUE,ATTN_NORM);
   if ( (other.classname == "player") ) {

      stuffcmd (other,"bf\n");

   }
   if ( (other.weapon == best) ) {

      stemp = self;
      self = other;
      self.weapon = W_BestWeapon ();
      self = stemp;

   }
   remove (self);
   self = other;
   W_SetCurrentAmmo ();

};

void () DropBackpack = {

   local entity item;
   local vector spawn_pos;

   if ( !(((self.ammo_shells + self.ammo_nails) + self.ammo_rockets) + self.ammo_cells) ) {

      return ;

   }

   // FIX: Prevent backpacks spawning in unreachable locations (void/walls/sky)
   spawn_pos = (self.origin - '0.000 0.000 24.000');
   if ( (pointcontents(spawn_pos) == CONTENT_SOLID) || (pointcontents(spawn_pos) == CONTENT_SKY) ) {

      // Try spawning at player origin instead
      spawn_pos = self.origin;
      if ( (pointcontents(spawn_pos) == CONTENT_SOLID) || (pointcontents(spawn_pos) == CONTENT_SKY) ) {

         return;  // Player died in invalid location, skip backpack

      }

   }

   item = spawn ();
   item.origin = spawn_pos;
   item.classname = "Backpack";
   item.items = self.weapon;
   item.th_weight = backpackweight;
   item.ammo_shells = self.ammo_shells;
   item.ammo_nails = self.ammo_nails;
   item.ammo_rockets = self.ammo_rockets;
   item.ammo_cells = self.ammo_cells;
   item.velocity_z = 300.000;
   item.velocity_x = (-100.000 + (random () * 200.000));
   item.velocity_y = (-100.000 + (random () * 200.000));
   item.flags = FL_ITEM;
   item.solid = SOLID_TRIGGER;
   item.movetype = MOVETYPE_TOSS;
   setmodel (item,"progs/backpack.mdl");
   setsize (item,'-16.000 -16.000 0.000','16.000 16.000 56.000');
   item.touch = BackpackTouch;
   item.nextthink = (time + 120.000);
   item.think = SUB_Remove;

   floaterEnable ( item, 6 );

};
