
void () W_SetCurrentAmmo;

void () SUB_regen =
{
   self.model = self.mdl;
   self.solid = SOLID_TRIGGER;
   sound (self,CHAN_VOICE,"items/itembk2.wav",CAM_FIXED,ATTN_NORM);
   setorigin (self,self.origin);
}; //end of the function SUB_regen

void () noclass =
{
   dprint ("noclass spawned at");
   dprint (vtos (self.origin));
   dprint ("\n");
   remove (self);
}; //end of the function noclass

void () PlaceItem =
{
   local float oldz;

   self.mdl = self.model;
   self.flags = FL_ITEM;
   self.solid = SOLID_TRIGGER;
   self.movetype = MOVETYPE_TOSS;
   self.velocity = VEC_ORIGIN;
   self.origin_z = (self.origin_z + MOVETYPE_TOSS);
   oldz = self.origin_z;
   if (!droptofloor (0, 0))
   {
      dprint ("Bonus item fell out of level at ");
      dprint (vtos (self.origin));
      dprint ("\n");
      remove (self);
      return ;
   } //end if
}; //end of the function PlaceItem

void () StartItem =
{
   self.nextthink = (time + 0.200);
   self.think = PlaceItem;
}; //end of the function StartItem
float (entity e, float healamount, float ignore) T_Heal =
{
   if ((e.health <= CAM_IDLE))
   {
      return (FALSE);
   } //end if
   if ((!ignore && (e.health >= other.max_health)))
   {
      return (FALSE);
   } //end if
   healamount = ceil (healamount);
   e.health = (e.health + healamount);
   if ((!ignore && (e.health >= other.max_health)))
   {
      e.health = other.max_health;
   } //end if
   if ((e.health > 250.000))
   {
      e.health = 250.000;
   } //end if
   return (TRUE);
}; //end of the function T_Heal
float H_ROTTEN    = 1.000;
float H_MEGA    = 2.000;
.float healamount;

void () health_touch;

void () item_megahealth_rot;

void () item_health =
{
   self.touch = health_touch;
   self.th_weight = healthweight;
   if ((self.spawnflags & H_ROTTEN))
   {
      precache_model ("maps/b_bh10.bsp");
      precache_sound ("items/r_item1.wav");
      setmodel (self,"maps/b_bh10.bsp");
      self.noise = "items/r_item1.wav";
      self.healamount = 15.000;
      self.healtype = FALSE;

   } //end if
   else
   {
      if ((self.spawnflags & H_MEGA))
      {
         precache_model ("maps/b_bh100.bsp");
         precache_sound ("items/r_item2.wav");
         setmodel (self,"maps/b_bh100.bsp");
         self.noise = "items/r_item2.wav";
         self.healamount = MUST_HAVE;
         self.healtype = H_MEGA;
         self.th_cache = cachepowerup;
         self.th_update = updatepowerup;

      } //end if
      else
      {
         precache_model ("maps/b_bh25.bsp");
         precache_sound ("items/health1.wav");
         setmodel (self,"maps/b_bh25.bsp");
         self.noise = "items/health1.wav";
         self.healamount = 25.000;
         self.healtype = TRUE;
      } //end if
   } //end if
   setsize (self,VEC_ORIGIN,'32.000 32.000 56.000');
   StartItem ();
}; //end of the function item_health

void () health_touch =
{
   local float amount;
   local string s;

   if ((other.classname != "player"))
   {
      if ((other.classname != "dmbot"))
      {
         return ;
      } //end if
   } //end if
   if ((self.healtype == H_MEGA))
   {
      if ((other.health >= 250.000))
      {
         return ;
      } //end if
      if (!T_Heal (other,self.healamount,TRUE))
      {
         return ;
      } //end if

   } //end if
   else
   {
      if (!T_Heal (other,self.healamount,FALSE))
      {
         return ;
      } //end if
   } //end if
   if ((other.classname == "dmbot"))
   {
      bot_toucheditem ();
   } //end if
   if ((other.classname == "player"))
   {
      sprint (other,"You receive ");
      s = ftos (self.healamount);
      sprint (other,s);
      sprint (other," health\n");
   } //end if
   sound (other,CHAN_ITEM,self.noise,TRUE,ATTN_NORM);
   if ((other.classname == "player"))
   {
      stuffcmd (other,"bf\n");
   } //end if
   self.model = string_null;
   self.solid = SOLID_NOT;
   if ((self.healtype == H_MEGA))
   {
      other.items = (other.items | IT_SUPERHEALTH);
      self.nextthink = (time + MOVETYPE_FLY);
      self.think = item_megahealth_rot;
      self.owner = other;
      if (other.movetarget.movetarget)
      {
         cacheRoute (other.movetarget,other.movetarget.movetarget,FALSE,self);
      } //end if

   } //end if
   else
   {
      if ((deathmatch != H_MEGA))
      {
         if (deathmatch)
         {
            self.nextthink = (time + LOOPTIME);
         } //end if
         self.think = SUB_regen;
      } //end if
   } //end if
   activator = other;
   SUB_UseTargets ();
}; //end of the function health_touch

void () item_megahealth_rot =
{
   other = self.owner;
   if ((other.health > other.max_health))
   {
      other.health = (other.health - H_ROTTEN);
      self.nextthink = (time + H_ROTTEN);
      return ;
   } //end if
   other.items = (other.items - (other.items & IT_SUPERHEALTH));
   if ((deathmatch != H_MEGA))
   {
      self.nextthink = (time + KINDA_WANT);
      self.think = SUB_regen;
   } //end if
}; //end of the function item_megahealth_rot

void () armor_touch =
{
   local float type;
   local float value;
   local float bit;

   if ((other.health <= FALSE))
   {
      return ;
   } //end if
   if ((other.classname != "player"))
   {
      if ((other.classname != "dmbot"))
      {
         return ;
      } //end if
   } //end if
   if ((self.classname == "item_armor1"))
   {
      type = 0.300;
      value = MUST_HAVE;
      bit = IT_ARMOR1;
   } //end if
   if ((self.classname == "item_armor2"))
   {
      type = 0.600;
      value = 150.000;
      bit = IT_ARMOR2;
      if (other.movetarget.movetarget)
      {
         cacheRoute (other.movetarget,other.movetarget.movetarget,FALSE,self);
      } //end if
   } //end if
   if ((self.classname == "item_armorInv"))
   {
      type = 0.800;
      value = 200.000;
      bit = IT_ARMOR3;
      if (other.movetarget.movetarget)
      {
         cacheRoute (other.movetarget,other.movetarget.movetarget,FALSE,self);
      } //end if
   } //end if
   if (((other.armortype * other.armorvalue) >= (type * value)))
   {
      return ;
   } //end if
   other.armortype = type;
   other.armorvalue = value;
   other.items = ((other.items - (other.items & ((IT_ARMOR1 | IT_ARMOR2) | IT_ARMOR3))) + bit);
   self.solid = SOLID_NOT;
   self.model = string_null;
   if (((deathmatch == TRUE) || (deathmatch == CAM_FOLLOW)))
   {
      self.nextthink = (time + LOOPTIME);
   } //end if
   self.think = SUB_regen;
   if ((other.classname == "dmbot"))
   {
      bot_toucheditem ();
   } //end if
   if ((other.classname == "player"))
   {
      sprint (other,"You got armor\n");
   } //end if
   sound (other,CHAN_ITEM,"items/armor1.wav",TRUE,ATTN_NORM);
   if ((other.classname == "player"))
   {
      stuffcmd (other,"bf\n");
   } //end if
   activator = other;
   SUB_UseTargets ();
}; //end of the function armor_touch

void () item_armor1 =
{
   self.touch = armor_touch;
   precache_model ("progs/armor.mdl");
   setmodel (self,"progs/armor.mdl");
   self.skin = FALSE;
   self.armorvalue = MUST_HAVE;
   setsize (self,'-16.000 -16.000 0.000','16.000 16.000 56.000');
   self.th_weight = armorweight;
   StartItem ();
}; //end of the function item_armor1

void () item_armor2 =
{
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
}; //end of the function item_armor2

void () item_armorInv =
{
   self.touch = armor_touch;
   precache_model ("progs/armor.mdl");
   setmodel (self,"progs/armor.mdl");
   self.skin = H_MEGA;
   self.armorvalue = 200.000;
   setsize (self,'-16.000 -16.000 0.000','16.000 16.000 56.000');
   self.th_weight = armorweight;
   self.th_cache = cachearmor;
   self.th_update = updatearmor;
   StartItem ();
}; //end of the function item_armorInv

void () bound_other_ammo =
{
   if ((other.ammo_shells > MUST_HAVE))
   {
      other.ammo_shells = MUST_HAVE;
   } //end if
   if ((other.ammo_nails > 200.000))
   {
      other.ammo_nails = 200.000;
   } //end if
   if ((other.ammo_rockets > MUST_HAVE))
   {
      other.ammo_rockets = MUST_HAVE;
   } //end if
   if ((other.ammo_cells > MUST_HAVE))
   {
      other.ammo_cells = MUST_HAVE;
   } //end if
}; //end of the function bound_other_ammo
float (entity ent, float w) RankForWeapon =
{
   if (((w == IT_LIGHTNING) && (ent.waterlevel <= H_ROTTEN)))
   {
      return (H_ROTTEN);
   } //end if
   if ((w == IT_ROCKET_LAUNCHER))
   {
      return (H_MEGA);
   } //end if
   if ((w == IT_SUPER_NAILGUN))
   {
      return (CAM_FOLLOW);
   } //end if
   if ((w == IT_GRENADE_LAUNCHER))
   {
      return (CAM_HAND);
   } //end if
   if ((w == IT_SUPER_SHOTGUN))
   {
      return (CAM_FREE);
   } //end if
   if ((w == IT_NAILGUN))
   {
      return (CAM_NOCLIP);
   } //end if
   return (CAM_DEATH);
}; //end of the function RankForWeapon

void (entity ent, float new) Deathmatch_Weapon =
{
   local float or;
   local float nr;

   or = RankForWeapon (ent,ent.weapon);
   nr = RankForWeapon (ent,new);
   if ((nr < or))
   {
      ent.weapon = new;
   } //end if
}; //end of the function Deathmatch_Weapon
float () W_BestWeapon;

void () weapon_touch =
{
   local float hadammo;
   local float new;
   local float best;
   local entity stemp;
   local float leave;
   local float donttake;

   if (((other.classname != "player") && (other.classname != "dmbot")))
   {
      return ;
   } //end if
   stemp = self;
   self = other;
   if ((self.classname == "player"))
   {
      best = W_BestWeapon ();
   } //end if
   self = stemp;
   if (((deathmatch >= H_MEGA) || coop))
   {
      leave = TRUE;

   } //end if
   else
   {
      leave = FALSE;
   } //end if
   if ((self.classname == "weapon_nailgun"))
   {
      if ((leave && (other.items & IT_NAILGUN)))
      {
         return ;
      } //end if
      hadammo = other.ammo_nails;
      new = IT_NAILGUN;
      other.ammo_nails = (other.ammo_nails + SVC_INTERMISSION);

   } //end if
   else
   {
      if ((self.classname == "weapon_supernailgun"))
      {
         if ((leave && (other.items & IT_SUPER_NAILGUN)))
         {
            return ;
         } //end if
         hadammo = other.ammo_rockets;
         new = IT_SUPER_NAILGUN;
         other.ammo_nails = (other.ammo_nails + SVC_INTERMISSION);
         if (other.movetarget.movetarget)
         {
            cacheRoute (other.movetarget,other.movetarget.movetarget,FALSE,self);
         } //end if

      } //end if
      else
      {
         if ((self.classname == "weapon_supershotgun"))
         {
            if ((leave && (other.items & IT_SUPER_SHOTGUN)))
            {
               return ;
            } //end if
            hadammo = other.ammo_rockets;
            new = IT_SUPER_SHOTGUN;
            other.ammo_shells = (other.ammo_shells + TE_LIGHTNING1);

         } //end if
         else
         {
            if ((self.classname == "weapon_rocketlauncher"))
            {
               if ((leave && (other.items & IT_ROCKET_LAUNCHER)))
               {
                  return ;
               } //end if
               hadammo = other.ammo_rockets;
               new = IT_ROCKET_LAUNCHER;
               other.ammo_rockets = (other.ammo_rockets + CAM_FREE);
               if (other.movetarget.movetarget)
               {
                  cacheRoute (other.movetarget,other.movetarget.movetarget,CAM_IDLE,self);
               } //end if

            } //end if
            else
            {
               if ((self.classname == "weapon_grenadelauncher"))
               {
                  if ((leave && (other.items & IT_GRENADE_LAUNCHER)))
                  {
                     return ;
                  } //end if
                  hadammo = other.ammo_rockets;
                  new = IT_GRENADE_LAUNCHER;
                  other.ammo_rockets = (other.ammo_rockets + CAM_FREE);
                  if (other.movetarget.movetarget)
                  {
                     cacheRoute (other.movetarget,other.movetarget.movetarget,CAM_IDLE,self);
                  } //end if

               } //end if
               else
               {
                  if ((self.classname == "weapon_lightning"))
                  {
                     if ((leave && (other.items & IT_LIGHTNING)))
                     {
                        return ;
                     } //end if
                     hadammo = other.ammo_rockets;
                     new = IT_LIGHTNING;
                     other.ammo_cells = (other.ammo_cells + 15.000);
                     if (other.movetarget.movetarget)
                     {
                        cacheRoute (other.movetarget,other.movetarget.movetarget,CAM_IDLE,self);
                     } //end if

                  } //end if
                  else
                  {
                     objerror ("weapon_touch: unknown classname");
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
   } //end if
   if ((other.classname == "player"))
   {
      sprint (other,"You got the ");
      sprint (other,self.netname);
      sprint (other,"\n");
   } //end if
   sound (other,CHAN_ITEM,"weapons/pkup.wav",H_ROTTEN,ATTN_NORM);
   if ((other.classname == "player"))
   {
      stuffcmd (other,"bf\n");
   } //end if
   bound_other_ammo ();
   if (!(other.items & new))
   {
      Deathmatch_Weapon (other,new);
   } //end if
   other.items = (other.items | new);
   stemp = self;
   self = other;
   if ((other.weapon == best))
   {
      self.weapon = W_BestWeapon ();
   } //end if
   W_SetCurrentAmmo ();
   self = stemp;
   if (leave)
   {
      return ;
   } //end if
   self.model = string_null;
   self.solid = SOLID_NOT;
   if (((deathmatch == H_ROTTEN) || (deathmatch == CAM_FOLLOW)))
   {
      self.nextthink = (time + SVC_INTERMISSION);
   } //end if
   self.think = SUB_regen;
   activator = other;
   SUB_UseTargets ();
}; //end of the function weapon_touch

void () weapon_supershotgun =
{
   precache_model ("progs/g_shot.mdl");
   setmodel (self,"progs/g_shot.mdl");
   self.weapon = IT_SUPER_SHOTGUN;
   self.netname = "Double-barrelled Shotgun";
   self.touch = weapon_touch;
   setsize (self,'-16.000 -16.000 0.000','16.000 16.000 56.000');
   self.th_weight = ssgweight;
   StartItem ();
}; //end of the function weapon_supershotgun

void () weapon_nailgun =
{
   precache_model ("progs/g_nail.mdl");
   setmodel (self,"progs/g_nail.mdl");
   self.weapon = IT_NAILGUN;
   self.netname = "nailgun";
   self.touch = weapon_touch;
   setsize (self,'-16.000 -16.000 0.000','16.000 16.000 56.000');
   self.th_weight = nailgunweight;
   StartItem ();
}; //end of the function weapon_nailgun

void () weapon_supernailgun =
{
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
}; //end of the function weapon_supernailgun

void () weapon_grenadelauncher =
{
   precache_model ("progs/g_rock.mdl");
   setmodel (self,"progs/g_rock.mdl");
   self.weapon = CAM_FOLLOW;
   self.netname = "Grenade Launcher";
   self.touch = weapon_touch;
   setsize (self,'-16.000 -16.000 0.000','16.000 16.000 56.000');
   self.th_weight = glauncherweight;
   self.th_cache = cachegrenade;
   self.th_update = updategrenade;
   StartItem ();
}; //end of the function weapon_grenadelauncher

void () weapon_rocketlauncher =
{
   precache_model ("progs/g_rock2.mdl");
   setmodel (self,"progs/g_rock2.mdl");
   self.weapon = CAM_FOLLOW;
   self.netname = "Rocket Launcher";
   self.touch = weapon_touch;
   setsize (self,'-16.000 -16.000 0.000','16.000 16.000 56.000');
   self.th_weight = rlauncherweight;
   self.th_cache = cacherocket;
   self.th_update = updaterocket;
   StartItem ();
}; //end of the function weapon_rocketlauncher

void () weapon_lightning =
{
   precache_model ("progs/g_light.mdl");
   setmodel (self,"progs/g_light.mdl");
   self.weapon = CAM_FOLLOW;
   self.netname = "Thunderbolt";
   self.touch = weapon_touch;
   setsize (self,'-16.000 -16.000 0.000','16.000 16.000 56.000');
   self.th_weight = lightningweight;
   self.th_cache = cachelightning;
   self.th_update = updatelightning;
   StartItem ();
}; //end of the function weapon_lightning

void () ammo_touch =
{
   local entity stemp;
   local float best;

   if ((other.classname != "player"))
   {
      if ((other.classname != "dmbot"))
      {
         return ;
      } //end if
   } //end if
   if ((other.health <= CAM_IDLE))
   {
      return ;
   } //end if
   stemp = self;
   self = other;
   best = W_BestWeapon ();
   self = stemp;
   if ((self.weapon == H_ROTTEN))
   {
      if ((other.ammo_shells >= MUST_HAVE))
      {
         return ;
      } //end if
      other.ammo_shells = (other.ammo_shells + self.aflag);
   } //end if
   if ((self.weapon == H_MEGA))
   {
      if ((other.ammo_nails >= 200.000))
      {
         return ;
      } //end if
      other.ammo_nails = (other.ammo_nails + self.aflag);
   } //end if
   if ((self.weapon == CAM_FOLLOW))
   {
      if ((other.ammo_rockets >= MUST_HAVE))
      {
         return ;
      } //end if
      other.ammo_rockets = (other.ammo_rockets + self.aflag);
   } //end if
   if ((self.weapon == CAM_HAND))
   {
      if ((other.ammo_cells >= 200.000))
      {
         return ;
      } //end if
      other.ammo_cells = (other.ammo_cells + self.aflag);
   } //end if
   if ((other.classname == "dmbot"))
   {
      bot_toucheditem ();
   } //end if
   bound_other_ammo ();
   if ((other.classname == "player"))
   {
      sprint (other,"You got the ");
      sprint (other,self.netname);
      sprint (other,"\n");
   } //end if
   sound (other,CHAN_ITEM,"weapons/lock4.wav",H_ROTTEN,ATTN_NORM);
   if ((other.classname == "player"))
   {
      stuffcmd (other,"bf\n");
   } //end if
   if ((other.weapon == best))
   {
      self.weapon = W_BestWeapon ();
   } //end if
   W_SetCurrentAmmo ();
   self = stemp;
   self.model = string_null;
   self.solid = SOLID_NOT;
   if (((deathmatch == H_ROTTEN) || (deathmatch == CAM_FOLLOW)))
   {
      self.nextthink = (time + SVC_INTERMISSION);
   } //end if
   self.think = SUB_regen;
   activator = other;
   SUB_UseTargets ();
}; //end of the function ammo_touch
float WEAPON_BIG2    = 1.000;

void () item_shells =
{
   self.touch = ammo_touch;
   if ((self.spawnflags & WEAPON_BIG2))
   {
      precache_model ("maps/b_shell1.bsp");
      setmodel (self,"maps/b_shell1.bsp");
      self.aflag = 40.000;

   } //end if
   else
   {
      precache_model ("maps/b_shell0.bsp");
      setmodel (self,"maps/b_shell0.bsp");
      self.aflag = KINDA_WANT;
   } //end if
   self.weapon = WEAPON_BIG2;
   self.netname = "shells";
   setsize (self,VEC_ORIGIN,'32.000 32.000 56.000');
   self.th_weight = shellweight;
   StartItem ();
}; //end of the function item_shells

void () item_spikes =
{
   self.touch = ammo_touch;
   if ((self.spawnflags & WEAPON_BIG2))
   {
      precache_model ("maps/b_nail1.bsp");
      setmodel (self,"maps/b_nail1.bsp");
      self.aflag = 50.000;

   } //end if
   else
   {
      precache_model ("maps/b_nail0.bsp");
      setmodel (self,"maps/b_nail0.bsp");
      self.aflag = 25.000;
   } //end if
   self.weapon = H_MEGA;
   self.netname = "nails";
   setsize (self,VEC_ORIGIN,'32.000 32.000 56.000');
   self.th_weight = nailweight;
   StartItem ();
}; //end of the function item_spikes

void () item_rockets =
{
   self.touch = ammo_touch;
   if ((self.spawnflags & WEAPON_BIG2))
   {
      precache_model ("maps/b_rock1.bsp");
      setmodel (self,"maps/b_rock1.bsp");
      self.aflag = TE_LAVASPLASH;

   } //end if
   else
   {
      precache_model ("maps/b_rock0.bsp");
      setmodel (self,"maps/b_rock0.bsp");
      self.aflag = MOVETYPE_FLY;
   } //end if
   self.weapon = CAM_FOLLOW;
   self.netname = "rockets";
   setsize (self,VEC_ORIGIN,'32.000 32.000 56.000');
   self.th_weight = rocketweight;
   StartItem ();
}; //end of the function item_rockets

void () item_cells =
{
   self.touch = ammo_touch;
   if ((self.spawnflags & WEAPON_BIG2))
   {
      precache_model ("maps/b_batt1.bsp");
      setmodel (self,"maps/b_batt1.bsp");
      self.aflag = 12.000;

   } //end if
   else
   {
      precache_model ("maps/b_batt0.bsp");
      setmodel (self,"maps/b_batt0.bsp");
      self.aflag = MOVETYPE_TOSS;
   } //end if
   self.weapon = CAM_HAND;
   self.netname = "cells";
   setsize (self,VEC_ORIGIN,'32.000 32.000 56.000');
   self.th_weight = cellweight;
   StartItem ();
}; //end of the function item_cells
float WEAPON_SHOTGUN    = 1.000;
float WEAPON_ROCKET    = 2.000;
float WEAPON_SPIKES    = 4.000;
float WEAPON_BIG    = 8.000;

void () item_weapon =
{
   self.touch = ammo_touch;
   if ((self.spawnflags & WEAPON_SHOTGUN))
   {
      if ((self.spawnflags & WEAPON_BIG))
      {
         precache_model ("maps/b_shell1.bsp");
         setmodel (self,"maps/b_shell1.bsp");
         self.aflag = 40.000;

      } //end if
      else
      {
         precache_model ("maps/b_shell0.bsp");
         setmodel (self,"maps/b_shell0.bsp");
         self.aflag = KINDA_WANT;
      } //end if
      self.weapon = WEAPON_SHOTGUN;
      self.netname = "shells";
   } //end if
   if ((self.spawnflags & WEAPON_SPIKES))
   {
      if ((self.spawnflags & WEAPON_BIG))
      {
         precache_model ("maps/b_nail1.bsp");
         setmodel (self,"maps/b_nail1.bsp");
         self.aflag = 40.000;

      } //end if
      else
      {
         precache_model ("maps/b_nail0.bsp");
         setmodel (self,"maps/b_nail0.bsp");
         self.aflag = LOOPTIME;
      } //end if
      self.weapon = WEAPON_ROCKET;
      self.netname = "spikes";
   } //end if
   if ((self.spawnflags & WEAPON_ROCKET))
   {
      if ((self.spawnflags & WEAPON_BIG))
      {
         precache_model ("maps/b_rock1.bsp");
         setmodel (self,"maps/b_rock1.bsp");
         self.aflag = TE_LAVASPLASH;

      } //end if
      else
      {
         precache_model ("maps/b_rock0.bsp");
         setmodel (self,"maps/b_rock0.bsp");
         self.aflag = MOVETYPE_FLY;
      } //end if
      self.weapon = CAM_FOLLOW;
      self.netname = "rockets";
   } //end if
   setsize (self,VEC_ORIGIN,'32.000 32.000 56.000');
   StartItem ();
}; //end of the function item_weapon

void () key_touch =
{
   local entity stemp;
   local float best;

   if ((other.classname != "player"))
   {
      if ((other.classname != "dmbot"))
      {
         return ;
      } //end if
   } //end if
   if ((other.health <= CAM_IDLE))
   {
      return ;
   } //end if
   if ((other.items & self.items))
   {
      return ;
   } //end if
   if ((other.classname == "player"))
   {
      sprint (other,"You got the ");
      sprint (other,self.netname);
      sprint (other,"\n");
   } //end if
   sound (other,CHAN_ITEM,self.noise,WEAPON_SHOTGUN,ATTN_NORM);
   if ((other.classname == "player"))
   {
      stuffcmd (other,"bf\n");
   } //end if
   other.items = (other.items | self.items);
   if (!coop)
   {
      self.solid = SOLID_NOT;
      self.model = string_null;
   } //end if
   activator = other;
   SUB_UseTargets ();
}; //end of the function key_touch

void () key_setsounds =
{
   if ((world.worldtype == CAM_IDLE))
   {
      precache_sound ("misc/medkey.wav");
      self.noise = "misc/medkey.wav";
   } //end if
   if ((world.worldtype == WEAPON_SHOTGUN))
   {
      precache_sound ("misc/runekey.wav");
      self.noise = "misc/runekey.wav";
   } //end if
   if ((world.worldtype == WEAPON_ROCKET))
   {
      precache_sound2 ("misc/basekey.wav");
      self.noise = "misc/basekey.wav";
   } //end if
}; //end of the function key_setsounds

void () item_key1 =
{
   if ((world.worldtype == CAM_IDLE))
   {
      precache_model ("progs/w_s_key.mdl");
      setmodel (self,"progs/w_s_key.mdl");
      self.netname = "silver key";

   } //end if
   else
   {
      if ((world.worldtype == WEAPON_SHOTGUN))
      {
         precache_model ("progs/m_s_key.mdl");
         setmodel (self,"progs/m_s_key.mdl");
         self.netname = "silver runekey";

      } //end if
      else
      {
         if ((world.worldtype == WEAPON_ROCKET))
         {
            precache_model2 ("progs/b_s_key.mdl");
            setmodel (self,"progs/b_s_key.mdl");
            self.netname = "silver keycard";
         } //end if
      } //end if
   } //end if
   key_setsounds ();
   self.touch = key_touch;
   self.items = IT_KEY1;
   setsize (self,VEC_HULL_MIN,VEC_HULL_MAX);
   StartItem ();
}; //end of the function item_key1

void () item_key2 =
{
   if ((world.worldtype == CAM_IDLE))
   {
      precache_model ("progs/w_g_key.mdl");
      setmodel (self,"progs/w_g_key.mdl");
      self.netname = "gold key";
   } //end if
   if ((world.worldtype == WEAPON_SHOTGUN))
   {
      precache_model ("progs/m_g_key.mdl");
      setmodel (self,"progs/m_g_key.mdl");
      self.netname = "gold runekey";
   } //end if
   if ((world.worldtype == WEAPON_ROCKET))
   {
      precache_model2 ("progs/b_g_key.mdl");
      setmodel (self,"progs/b_g_key.mdl");
      self.netname = "gold keycard";
   } //end if
   key_setsounds ();
   self.touch = key_touch;
   self.items = IT_KEY2;
   setsize (self,VEC_HULL_MIN,VEC_HULL_MAX);
   StartItem ();
}; //end of the function item_key2

void () sigil_touch =
{
   local entity stemp;
   local float best;

   if ((other.classname != "player"))
   {
      return ;
   } //end if
   if ((other.health <= CAM_IDLE))
   {
      return ;
   } //end if
   centerprint (other,"You got the rune!");
   sound (other,CHAN_ITEM,self.noise,TRUE,ATTN_NORM);
   stuffcmd (other,"bf\n");
   self.solid = SOLID_NOT;
   self.model = string_null;
   serverflags = (serverflags | (self.spawnflags & 15.000));
   self.classname = "";
   activator = other;
   SUB_UseTargets ();
}; //end of the function sigil_touch

void () item_sigil =
{
   if (!self.spawnflags)
   {
      objerror ("no spawnflags");
   } //end if
   precache_sound ("misc/runekey.wav");
   self.noise = "misc/runekey.wav";
   if ((self.spawnflags & WEAPON_SHOTGUN))
   {
      precache_model ("progs/end1.mdl");
      setmodel (self,"progs/end1.mdl");
   } //end if
   if ((self.spawnflags & WEAPON_ROCKET))
   {
      precache_model2 ("progs/end2.mdl");
      setmodel (self,"progs/end2.mdl");
   } //end if
   if ((self.spawnflags & CAM_FOLLOW))
   {
      precache_model2 ("progs/end3.mdl");
      setmodel (self,"progs/end3.mdl");
   } //end if
   if ((self.spawnflags & WEAPON_BIG))
   {
      precache_model2 ("progs/end4.mdl");
      setmodel (self,"progs/end4.mdl");
   } //end if
   self.touch = sigil_touch;
   setsize (self,VEC_HULL_MIN,VEC_HULL_MAX);
   StartItem ();
}; //end of the function item_sigil

void () powerup_touch =
{
   local entity stemp;
   local float best;

   if ((other.classname != "player"))
   {
      if ((other.classname != "dmbot"))
      {
         return ;
      } //end if
   } //end if
   if ((other.health <= CAM_IDLE))
   {
      return ;
   } //end if
   if ((other.classname == "player"))
   {
      sprint (other,"You got the ");
      sprint (other,self.netname);
      sprint (other,"\n");
   } //end if
   if (deathmatch)
   {
      self.mdl = self.model;
      if (((self.classname == "item_artifact_invulnerability") || (self.classname == "item_artifact_invisibility")))
      {
         self.nextthink = (time + (60.000 * CAM_FREE));

      } //end if
      else
      {
         self.nextthink = (time + 60.000);
      } //end if
      self.think = SUB_regen;
   } //end if
   sound (other,CHAN_VOICE,self.noise,TRUE,ATTN_NORM);
   if ((other.classname == "player"))
   {
      stuffcmd (other,"bf\n");
   } //end if
   self.solid = SOLID_NOT;
   other.items = (other.items | self.items);
   self.model = string_null;
   if ((self.classname == "item_artifact_envirosuit"))
   {
      other.rad_time = WEAPON_SHOTGUN;
      other.radsuit_finished = (time + SVC_INTERMISSION);
   } //end if
   if ((self.classname == "item_artifact_invulnerability"))
   {
      other.invincible_time = WEAPON_SHOTGUN;
      other.invincible_finished = (time + SVC_INTERMISSION);
      if (other.movetarget.movetarget)
      {
         cacheRoute (other.movetarget,other.movetarget.movetarget,FALSE,self);
      } //end if
   } //end if
   if ((self.classname == "item_artifact_invisibility"))
   {
      other.invisible_time = WEAPON_SHOTGUN;
      other.invisible_finished = (time + SVC_INTERMISSION);
      if (other.movetarget.movetarget)
      {
         cacheRoute (other.movetarget,other.movetarget.movetarget,CAM_IDLE,self);
      } //end if
   } //end if
   if ((self.classname == "item_artifact_super_damage"))
   {
      other.super_time = WEAPON_SHOTGUN;
      other.super_damage_finished = (time + SVC_INTERMISSION);
      if (other.movetarget.movetarget)
      {
         cacheRoute (other.movetarget,other.movetarget.movetarget,CAM_IDLE,self);
      } //end if
   } //end if
   activator = other;
   SUB_UseTargets ();
}; //end of the function powerup_touch

void () item_artifact_invulnerability =
{
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
}; //end of the function item_artifact_invulnerability

void () item_artifact_envirosuit =
{
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
}; //end of the function item_artifact_envirosuit

void () item_artifact_invisibility =
{
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
}; //end of the function item_artifact_invisibility

void () item_artifact_super_damage =
{
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
}; //end of the function item_artifact_super_damage

void () BackpackTouch =
{
   local string s;
   local float best;
   local float new;
   local entity stemp;
   local float acount;

   if ((other.classname != "player"))
   {
      if ((other.classname != "dmbot"))
      {
         return ;
      } //end if
   } //end if
   if ((other.classname == "dmbot"))
   {
      bot_toucheditem ();
   } //end if
   if ((other.health <= CAM_IDLE))
   {
      return ;
   } //end if
   stemp = self;
   self = other;
   best = W_BestWeapon ();
   self = stemp;
   other.ammo_shells = (other.ammo_shells + self.ammo_shells);
   other.ammo_nails = (other.ammo_nails + self.ammo_nails);
   other.ammo_rockets = (other.ammo_rockets + self.ammo_rockets);
   other.ammo_cells = (other.ammo_cells + self.ammo_cells);
   new = self.items;
   if (!new)
   {
      new = other.weapon;
   } //end if
   if (!(other.items & new))
   {
      Deathmatch_Weapon (other,new);
   } //end if
   other.items = (other.items | new);
   bound_other_ammo ();
   if ((other.classname == "player"))
   {
      sprint (other,"You get ");
      if (self.ammo_shells)
      {
         s = ftos (self.ammo_shells);
         sprint (other,s);
         sprint (other," shells  ");
      } //end if
      if (self.ammo_nails)
      {
         s = ftos (self.ammo_nails);
         sprint (other,s);
         sprint (other," nails ");
      } //end if
      if (self.ammo_rockets)
      {
         s = ftos (self.ammo_rockets);
         sprint (other,s);
         sprint (other," rockets  ");
      } //end if
      if (self.ammo_cells)
      {
         s = ftos (self.ammo_cells);
         sprint (other,s);
         sprint (other," cells  ");
      } //end if
      sprint (other,"\n");
   } //end if
   sound (other,CHAN_ITEM,"weapons/lock4.wav",TRUE,ATTN_NORM);
   if ((other.classname == "player"))
   {
      stuffcmd (other,"bf\n");
   } //end if
   if ((other.weapon == best))
   {
      stemp = self;
      self = other;
      self.weapon = W_BestWeapon ();
      self = stemp;
   } //end if
   remove (self);
   self = other;
   W_SetCurrentAmmo ();
}; //end of the function BackpackTouch

void () DropBackpack =
{
   local entity item;

   if (!(((self.ammo_shells + self.ammo_nails) + self.ammo_rockets) + self.ammo_cells))
   {
      return ;
   } //end if
   item = spawn ();
   item.origin = (self.origin - '0.000 0.000 24.000');
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
}; //end of the function DropBackpack
