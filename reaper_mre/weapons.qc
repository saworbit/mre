
void () player_run;

void (vector org, vector vel, float damage) SpawnBlood;

void () SuperDamageSound;

void () W_Precache =
{
   precache_sound ("weapons/r_exp3.wav");
   precache_sound ("weapons/rocket1i.wav");
   precache_sound ("weapons/sgun1.wav");
   precache_sound ("weapons/guncock.wav");
   precache_sound ("weapons/ric1.wav");
   precache_sound ("weapons/ric2.wav");
   precache_sound ("weapons/ric3.wav");
   precache_sound ("weapons/spike2.wav");
   precache_sound ("weapons/tink1.wav");
   precache_sound ("weapons/grenade.wav");
   precache_sound ("weapons/bounce.wav");
   precache_sound ("weapons/shotgn2.wav");
}; //end of the function W_Precache
float /* ERROR: Could not determine return type */ () crandom =
{
   return ((WEAPON_ROCKET * (random () - 0.500)));
}; //end of the function crandom

void () W_FireAxe =
{
   local vector source;
   local vector dir;
   local vector org;

   source = (self.origin + '0.000 0.000 16.000');
   dir = v_forward;
   if ((self.classname == "dmbot"))
   {
      dir = botaim ();
   } //end if
   traceline (source,(source + (dir * WATERUPDOWN)),CAM_IDLE,self);
   if ((trace_fraction == TRUE))
   {
      return ;
   } //end if
   org = (trace_endpos - (dir * WEAPON_SPIKES));
   if (trace_ent.takedamage)
   {
      trace_ent.axhitme = TRUE;
      if ((trace_ent.takedamage == DAMAGE_AIM))
      {
         SpawnBlood (org,VEC_ORIGIN,LOOPTIME);
      } //end if
      T_Damage (trace_ent,self,self,LOOPTIME);
   } //end if
   if ((trace_ent.takedamage != DAMAGE_AIM))
   {
      sound (self,CHAN_WEAPON,"player/axhit2.wav",WEAPON_SHOTGUN,ATTN_NORM);
      WriteByte (MSG_BROADCAST,SVC_TEMPENTITY);
      WriteByte (MSG_BROADCAST,TE_GUNSHOT);
      WriteCoord (MSG_BROADCAST,org_x);
      WriteCoord (MSG_BROADCAST,org_y);
      WriteCoord (MSG_BROADCAST,org_z);
   } //end if
}; //end of the function W_FireAxe
vector () wall_velocity =
{
   local vector vel;

   vel = normalize (self.velocity);
   vel = normalize (((vel + (v_up * (random () - 0.500))) + (v_right * (random () - 0.500))));
   vel = (vel + (WEAPON_ROCKET * trace_plane_normal));
   vel = (vel * 200.000);
   return (vel);
}; //end of the function wall_velocity

void (vector org, vector vel) SpawnMeatSpray =
{
   local entity missile;
   local entity mpuff;

   missile = spawn ();
   missile.owner = self;
   missile.movetype = MOVETYPE_BOUNCE;
   missile.solid = SOLID_NOT;
   makevectors (self.angles);
   missile.velocity = vel;
   missile.velocity_z = ((missile.velocity_z + 250.000) + (50.000 * random ()));
   missile.avelocity = '3000.000 1000.000 2000.000';
   missile.nextthink = (time + WEAPON_SHOTGUN);
   missile.think = SUB_Remove;
   setmodel (missile,"progs/zom_gib.mdl");
   setsize (missile,VEC_ORIGIN,VEC_ORIGIN);
   setorigin (missile,org);
}; //end of the function SpawnMeatSpray

void (vector org, vector vel, float damage) SpawnBlood =
{
   particle (org,(vel * 0.100),73.000,(damage * WEAPON_ROCKET));
}; //end of the function SpawnBlood

void (float damage) spawn_touchblood =
{
   local vector vel;

   vel = (wall_velocity () * 0.200);
   SpawnBlood ((self.origin + (vel * 0.010)),vel,damage);
}; //end of the function spawn_touchblood

void (vector org, vector vel) SpawnChunk =
{
   particle (org,(vel * 0.020),CAM_IDLE,TE_LAVASPLASH);
}; //end of the function SpawnChunk
entity multi_ent;
float multi_damage /* = 0.000 */;

void () ClearMultiDamage =
{
   multi_ent = world;
   multi_damage = CAM_IDLE;
}; //end of the function ClearMultiDamage

void () ApplyMultiDamage =
{
   if (!multi_ent)
   {
      return ;
   } //end if
   T_Damage (multi_ent,self,self,multi_damage);
}; //end of the function ApplyMultiDamage

void (entity hit, float damage) AddMultiDamage =
{
   if (!hit)
   {
      return ;
   } //end if
   if ((hit != multi_ent))
   {
      ApplyMultiDamage ();
      multi_damage = damage;
      multi_ent = hit;

   } //end if
   else
   {
      multi_damage = (multi_damage + damage);
   } //end if
}; //end of the function AddMultiDamage

void (float damage, vector dir) TraceAttack =
{
   local vector vel;
   local vector org;

   vel = normalize (((dir + (v_up * crandom ())) + (v_right * crandom ())));
   vel = (vel + (WEAPON_ROCKET * trace_plane_normal));
   vel = (vel * 200.000);
   org = (trace_endpos - (dir * WEAPON_SPIKES));
   if (trace_ent.takedamage)
   {
      SpawnBlood (org,(vel * 0.200),damage);
      AddMultiDamage (trace_ent,damage);

   } //end if
   else
   {
      WriteByte (MSG_BROADCAST,SVC_TEMPENTITY);
      WriteByte (MSG_BROADCAST,TE_GUNSHOT);
      WriteCoord (MSG_BROADCAST,org_x);
      WriteCoord (MSG_BROADCAST,org_y);
      WriteCoord (MSG_BROADCAST,org_z);
   } //end if
}; //end of the function TraceAttack

void (float shotcount, vector dir, vector spread) FireBullets =
{
   local vector direction;
   local vector src;

   makevectors (self.v_angle);
   src = (self.origin + (v_forward * TE_LAVASPLASH));
   src_z = (self.absmin_z + (self.size_z * 0.700));
   ClearMultiDamage ();
   while ((shotcount > CAM_IDLE))
   {
      direction = ((dir + ((crandom () * spread_x) * v_right)) + ((crandom () * spread_y) * v_up));
      traceline (src,(src + (direction * MULTIENEMY)),CAM_IDLE,self);
      if ((trace_fraction != TRUE))
      {
         TraceAttack (MOVETYPE_STEP,direction);
      } //end if
      shotcount = (shotcount - WEAPON_SHOTGUN);
   } //end while
   ApplyMultiDamage ();
}; //end of the function FireBullets

void () W_FireShotgun =
{
   local vector dir;

   sound (self,CHAN_WEAPON,"weapons/guncock.wav",WEAPON_SHOTGUN,ATTN_NORM);
   self.punchangle_x = CONTENT_SOLID;
   self.ammo_shells = (self.ammo_shells - WEAPON_SHOTGUN);
   self.currentammo = (self.ammo_shells - WEAPON_SHOTGUN);
   if ((self.classname == "dmbot"))
   {
      dir = botaim ();

   } //end if
   else
   {
      dir = aim (self,100000.000);
   } //end if
   FireBullets (CAM_NOCLIP,dir,'0.040 0.040 0.000');
}; //end of the function W_FireShotgun

void () W_FireSuperShotgun =
{
   local vector dir;

   if ((self.currentammo == WEAPON_SHOTGUN))
   {
      W_FireShotgun ();
      return ;
   } //end if
   sound (self,CHAN_WEAPON,"weapons/shotgn2.wav",WEAPON_SHOTGUN,ATTN_NORM);
   self.punchangle_x = CONTENT_SLIME;
   self.ammo_shells = (self.ammo_shells - WEAPON_ROCKET);
   self.currentammo = (self.ammo_shells - WEAPON_ROCKET);
   dir = aim (self,100000.000);
   if ((self.classname == "dmbot"))
   {
      dir = botaim ();
   } //end if
   FireBullets (14.000,dir,'0.140 0.080 0.000');
}; //end of the function W_FireSuperShotgun

void () s_explode1 = [0.000, s_explode2]
{
}; //end of the function s_explode1

void () s_explode2 = [1.000, s_explode3]
{
}; //end of the function s_explode2

void () s_explode3 = [2.000, s_explode4]
{
}; //end of the function s_explode3

void () s_explode4 = [3.000, s_explode5]
{
}; //end of the function s_explode4

void () s_explode5 = [4.000, s_explode6]
{
}; //end of the function s_explode5

void () s_explode6 = [5.000, SUB_Remove]
{
}; //end of the function s_explode6

void () BecomeExplosion =
{
   self.movetype = MOVETYPE_NONE;
   self.velocity = VEC_ORIGIN;
   self.touch = SUB_Null;
   setmodel (self,"progs/s_explod.spr");
   self.solid = SOLID_NOT;
   s_explode1 ();
}; //end of the function BecomeExplosion

void () T_MissileTouch =
{
   local float damg;

   if ((other == self.owner))
   {
      return ;
   } //end if
   if ((pointcontents (self.origin) == CONTENT_SKY))
   {
      remove (self);
      return ;
   } //end if
   damg = (MUST_HAVE + (random () * KINDA_WANT));
   if (other.health)
   {
      if ((other.classname == "monster_shambler"))
      {
         damg = (damg * 0.500);
      } //end if
      T_Damage (other,self,self.owner,damg);
   } //end if
   T_RadiusDamage (self,self.owner,120.000,other);
   self.origin = (self.origin - (WEAPON_ROCKET * normalize (self.velocity)));
   WriteByte (MSG_BROADCAST,SVC_TEMPENTITY);
   WriteByte (MSG_BROADCAST,TE_EXPLOSION);
   WriteCoord (MSG_BROADCAST,self.origin_x);
   WriteCoord (MSG_BROADCAST,self.origin_y);
   WriteCoord (MSG_BROADCAST,self.origin_z);
   BecomeExplosion ();
}; //end of the function T_MissileTouch

void () W_FireRocket =
{
   local entity missile;
   local entity mpuff;
   local vector bfwd;

   self.ammo_rockets = (self.ammo_rockets - WEAPON_SHOTGUN);
   self.currentammo = (self.ammo_rockets - WEAPON_SHOTGUN);
   sound (self,CHAN_WEAPON,"weapons/sgun1.wav",TRUE,ATTN_NORM);
   self.punchangle_x = CONTENT_SOLID;
   missile = spawn ();
   missile.owner = self;
   missile.movetype = MOVETYPE_FLYMISSILE;
   missile.solid = SOLID_BBOX;
   makevectors (self.v_angle);
   if ((self.classname == "dmbot"))
   {
      missile.velocity = botaim ();
      bfwd = botaim ();
      bfwd_z = FALSE;

   } //end if
   else
   {
      missile.velocity = aim (self,1000.000);
   } //end if
   missile.velocity = (missile.velocity * 1000.000);
   missile.angles = vectoangles (missile.velocity);
   missile.touch = T_MissileTouch;
   missile.nextthink = (time + MOVETYPE_FLY);
   missile.think = SUB_Remove;
   setmodel (missile,"progs/missile.mdl");
   setsize (missile,VEC_ORIGIN,VEC_ORIGIN);
   if ((self.classname == "dmbot"))
   {
      setorigin (missile,((self.origin + (bfwd * WEAPON_ROCKET)) + '0.000 0.000 16.000'));

   } //end if
   else
   {
      setorigin (missile,((self.origin + (v_forward * WEAPON_ROCKET)) + '0.000 0.000 16.000'));
   } //end if
}; //end of the function W_FireRocket

void (vector p1, vector p2, entity from, float damage) LightningDamage =
{
   local entity e1;
   local entity e2;
   local vector f;

   f = (p2 - p1);
   normalize (f);
   f_x = (FALSE - f_y);
   f_y = f_x;
   f_z = FALSE;
   f = (f * FL_INWATER);
   e2 = world;
   e1 = world;
   traceline (p1,p2,FALSE,self);
   if (trace_ent.takedamage)
   {
      particle (trace_endpos,'0.000 0.000 100.000',225.000,(damage * WEAPON_SPIKES));
      T_Damage (trace_ent,from,from,damage);
      if (((self.classname == "player") || (self.classname == "dmbot")))
      {
         if (((other.classname == "player") || (other.classname == "dmbot")))
         {
            trace_ent.velocity_z = (trace_ent.velocity_z + 400.000);
         } //end if
      } //end if
   } //end if
   e1 = trace_ent;
   traceline ((p1 + f),(p2 + f),FALSE,self);
   if (((trace_ent != e1) && trace_ent.takedamage))
   {
      particle (trace_endpos,'0.000 0.000 100.000',225.000,(damage * WEAPON_SPIKES));
      T_Damage (trace_ent,from,from,damage);
   } //end if
   e2 = trace_ent;
   traceline ((p1 - f),(p2 - f),FALSE,self);
   if ((((trace_ent != e1) && (trace_ent != e2)) && trace_ent.takedamage))
   {
      particle (trace_endpos,'0.000 0.000 100.000',225.000,(damage * WEAPON_SPIKES));
      T_Damage (trace_ent,from,from,damage);
   } //end if
}; //end of the function LightningDamage

void () W_FireLightning =
{
   local vector dir;
   local vector org;
   local float wlevel;

   if ((self.ammo_cells < WEAPON_SHOTGUN))
   {
      self.weapon = W_BestWeapon ();
      W_SetCurrentAmmo ();
      if ((self.classname == "dmbot"))
      {
         self.think = self.th_run;
      } //end if
      return ;
   } //end if
   if ((self.classname == "dmbot"))
   {
      wlevel = CheckWaterLevel ();
      if ((wlevel > WEAPON_SHOTGUN))
      {
         T_RadiusDamage (self,self,(WANT * self.ammo_cells),world);
         self.ammo_cells = FALSE;
         W_SetCurrentAmmo ();
         return ;
      } //end if

   } //end if
   else
   {
      if ((self.waterlevel > WEAPON_SHOTGUN))
      {
         T_RadiusDamage (self,self,(WANT * self.ammo_cells),world);
         self.ammo_cells = FALSE;
         W_SetCurrentAmmo ();
         return ;
      } //end if
   } //end if
   if ((self.t_width < time))
   {
      sound (self,CHAN_WEAPON,"weapons/lhit.wav",WEAPON_SHOTGUN,ATTN_NORM);
      self.t_width = (time + 0.600);
   } //end if
   self.punchangle_x = CONTENT_SOLID;
   self.ammo_cells = (self.ammo_cells - WEAPON_SHOTGUN);
   self.currentammo = (self.ammo_cells - WEAPON_SHOTGUN);
   org = (self.origin + '0.000 0.000 16.000');
   dir = v_forward;
   if ((self.classname == "dmbot"))
   {
      dir = botaim ();
   } //end if
   traceline (org,(org + (dir * SEARCH_RADIUS)),WEAPON_SHOTGUN,self);
   WriteByte (MSG_BROADCAST,SVC_TEMPENTITY);
   WriteByte (MSG_BROADCAST,TE_LIGHTNING2);
   WriteEntity (MSG_BROADCAST,self);
   WriteCoord (MSG_BROADCAST,org_x);
   WriteCoord (MSG_BROADCAST,org_y);
   WriteCoord (MSG_BROADCAST,org_z);
   WriteCoord (MSG_BROADCAST,trace_endpos_x);
   WriteCoord (MSG_BROADCAST,trace_endpos_y);
   WriteCoord (MSG_BROADCAST,trace_endpos_z);
   LightningDamage (self.origin,(trace_endpos + (dir * WEAPON_SPIKES)),self,SVC_INTERMISSION);
}; //end of the function W_FireLightning

void () GrenadeExplode =
{
   T_RadiusDamage (self,self.owner,120.000,world);
   WriteByte (MSG_BROADCAST,SVC_TEMPENTITY);
   WriteByte (MSG_BROADCAST,TE_EXPLOSION);
   WriteCoord (MSG_BROADCAST,self.origin_x);
   WriteCoord (MSG_BROADCAST,self.origin_y);
   WriteCoord (MSG_BROADCAST,self.origin_z);
   BecomeExplosion ();
}; //end of the function GrenadeExplode

void () GrenadeTouch =
{
   if ((other == self.owner))
   {
      return ;
   } //end if
   if ((other.takedamage == DAMAGE_AIM))
   {
      GrenadeExplode ();
      return ;
   } //end if
   sound (self,CHAN_WEAPON,"weapons/bounce.wav",TRUE,ATTN_NORM);
   if ((self.velocity == VEC_ORIGIN))
   {
      self.avelocity = VEC_ORIGIN;
   } //end if
}; //end of the function GrenadeTouch

void () W_FireGrenade =
{
   local entity missile;
   local entity mpuff;

   self.ammo_rockets = (self.ammo_rockets - WEAPON_SHOTGUN);
   self.currentammo = (self.ammo_rockets - WEAPON_SHOTGUN);
   sound (self,CHAN_WEAPON,"weapons/grenade.wav",TRUE,ATTN_NORM);
   self.punchangle_x = CONTENT_SOLID;
   missile = spawn ();
   missile.owner = self;
   missile.movetype = MOVETYPE_BOUNCE;
   missile.solid = SOLID_BBOX;
   missile.classname = "grenade";
   makevectors (self.v_angle);
   if (self.v_angle_x)
   {
      missile.velocity = ((((v_forward * SEARCH_RADIUS) + (v_up * 200.000)) + ((crandom () * v_right) * TE_LAVASPLASH)) + ((crandom () * v_up) * TE_LAVASPLASH));

   } //end if
   else
   {
      if ((self.classname == "dmbot"))
      {
         missile.velocity = botaim ();
         missile.velocity = (missile.velocity * SEARCH_RADIUS);
         missile.velocity_z = (missile.velocity_z + 200.000);

      } //end if
      else
      {
         missile.velocity = aim (self,10000.000);
         missile.velocity = (missile.velocity * SEARCH_RADIUS);
         missile.velocity_z = 200.000;
      } //end if
   } //end if
   missile.avelocity = '300.000 300.000 300.000';
   missile.angles = vectoangles (missile.velocity);
   missile.touch = GrenadeTouch;
   missile.nextthink = (time + 2.500);
   missile.think = GrenadeExplode;
   setmodel (missile,"progs/grenade.mdl");
   setsize (missile,VEC_ORIGIN,VEC_ORIGIN);
   setorigin (missile,self.origin);
}; //end of the function W_FireGrenade

void () spike_touch;

void () superspike_touch;

void (vector org, vector dir) launch_spike =
{
   newmis = spawn ();
   newmis.owner = self;
   newmis.movetype = MOVETYPE_FLYMISSILE;
   newmis.solid = SOLID_BBOX;
   newmis.angles = vectoangles (dir);
   newmis.touch = spike_touch;
   newmis.classname = "spike";
   newmis.think = SUB_Remove;
   newmis.nextthink = (time + CAM_NOCLIP);
   setmodel (newmis,"progs/spike.mdl");
   setsize (newmis,VEC_ORIGIN,VEC_ORIGIN);
   setorigin (newmis,org);
   newmis.velocity = (dir * 1000.000);
}; //end of the function launch_spike

void () W_FireSuperSpikes =
{
   local vector dir;
   local entity old;

   sound (self,CHAN_WEAPON,"weapons/spike2.wav",TRUE,ATTN_NORM);
   self.attack_finished = (time + 0.200);
   self.ammo_nails = (self.ammo_nails - WEAPON_ROCKET);
   self.currentammo = (self.ammo_nails - WEAPON_ROCKET);
   dir = aim (self,1000.000);
   if ((self.classname == "dmbot"))
   {
      dir = botaim ();
   } //end if
   launch_spike ((self.origin + '0.000 0.000 16.000'),dir);
   newmis.touch = superspike_touch;
   setmodel (newmis,"progs/s_spike.mdl");
   setsize (newmis,VEC_ORIGIN,VEC_ORIGIN);
   self.punchangle_x = CONTENT_SOLID;
}; //end of the function W_FireSuperSpikes

void (float ox) W_FireSpikes =
{
   local vector dir;
   local entity old;

   makevectors (self.v_angle);
   if (((self.ammo_nails >= WEAPON_ROCKET) && (self.weapon == IT_SUPER_NAILGUN)))
   {
      W_FireSuperSpikes ();
      return ;
   } //end if
   if ((self.ammo_nails < WEAPON_SHOTGUN))
   {
      self.weapon = W_BestWeapon ();
      W_SetCurrentAmmo ();
      if ((self.classname == "dmbot"))
      {
         self.think = self.th_run;
      } //end if
      return ;
   } //end if
   sound (self,CHAN_WEAPON,"weapons/rocket1i.wav",WEAPON_SHOTGUN,ATTN_NORM);
   self.attack_finished = (time + 0.200);
   self.ammo_nails = (self.ammo_nails - WEAPON_SHOTGUN);
   self.currentammo = (self.ammo_nails - WEAPON_SHOTGUN);
   dir = aim (self,1000.000);
   if ((self.classname == "dmbot"))
   {
      dir = botaim ();
   } //end if
   launch_spike (((self.origin + '0.000 0.000 16.000') + (v_right * ox)),dir);
   self.punchangle_x = CONTENT_SOLID;
}; //end of the function W_FireSpikes
.float hit_z;

void () spike_touch =
{
   local float rand;

   if ((other == self.owner))
   {
      return ;
   } //end if
   if ((other.solid == SOLID_TRIGGER))
   {
      return ;
   } //end if
   if ((pointcontents (self.origin) == CONTENT_SKY))
   {
      remove (self);
      return ;
   } //end if
   if (other.takedamage)
   {
      if ((other.takedamage == DAMAGE_AIM))
      {
         spawn_touchblood (TE_LIGHTNING3);
      } //end if
      T_Damage (other,self,self.owner,TE_LIGHTNING3);
   } //end if
   if ((other.takedamage != DAMAGE_AIM))
   {
      WriteByte (MSG_BROADCAST,SVC_TEMPENTITY);
      if ((self.classname == "wizspike"))
      {
         WriteByte (MSG_BROADCAST,TE_WIZSPIKE);

      } //end if
      else
      {
         if ((self.classname == "knightspike"))
         {
            WriteByte (MSG_BROADCAST,TE_KNIGHTSPIKE);

         } //end if
         else
         {
            WriteByte (MSG_BROADCAST,TE_SPIKE);
         } //end if
      } //end if
      WriteCoord (MSG_BROADCAST,self.origin_x);
      WriteCoord (MSG_BROADCAST,self.origin_y);
      WriteCoord (MSG_BROADCAST,self.origin_z);
   } //end if
   remove (self);
}; //end of the function spike_touch

void () superspike_touch =
{
   local float rand;

   if ((other == self.owner))
   {
      return ;
   } //end if
   if ((other.solid == SOLID_TRIGGER))
   {
      return ;
   } //end if
   if ((pointcontents (self.origin) == CONTENT_SKY))
   {
      remove (self);
      return ;
   } //end if
   if (other.takedamage)
   {
      if ((other.takedamage == DAMAGE_AIM))
      {
         spawn_touchblood (18.000);
      } //end if
      T_Damage (other,self,self.owner,18.000);
   } //end if
   if ((other.takedamage != DAMAGE_AIM))
   {
      WriteByte (MSG_BROADCAST,SVC_TEMPENTITY);
      WriteByte (MSG_BROADCAST,TE_SUPERSPIKE);
      WriteCoord (MSG_BROADCAST,self.origin_x);
      WriteCoord (MSG_BROADCAST,self.origin_y);
      WriteCoord (MSG_BROADCAST,self.origin_z);
   } //end if
   remove (self);
}; //end of the function superspike_touch

void () CycleWeaponReverseCommand =
{
   local float it;
   local float am;

   it = self.items;
   self.impulse = CAM_IDLE;
   while (WEAPON_SHOTGUN)
   {
      am = CAM_IDLE;
      if ((self.weapon == IT_LIGHTNING))
      {
         self.weapon = IT_ROCKET_LAUNCHER;
         if ((self.ammo_rockets < WEAPON_SHOTGUN))
         {
            am = WEAPON_SHOTGUN;
         } //end if

      } //end if
      else
      {
         if ((self.weapon == IT_ROCKET_LAUNCHER))
         {
            self.weapon = IT_GRENADE_LAUNCHER;
            if ((self.ammo_rockets < WEAPON_SHOTGUN))
            {
               am = WEAPON_SHOTGUN;
            } //end if

         } //end if
         else
         {
            if ((self.weapon == IT_GRENADE_LAUNCHER))
            {
               self.weapon = IT_SUPER_NAILGUN;
               if ((self.ammo_nails < WEAPON_ROCKET))
               {
                  am = WEAPON_SHOTGUN;
               } //end if

            } //end if
            else
            {
               if ((self.weapon == IT_SUPER_NAILGUN))
               {
                  self.weapon = IT_NAILGUN;
                  if ((self.ammo_nails < WEAPON_SHOTGUN))
                  {
                     am = WEAPON_SHOTGUN;
                  } //end if

               } //end if
               else
               {
                  if ((self.weapon == IT_NAILGUN))
                  {
                     self.weapon = IT_SUPER_SHOTGUN;
                     if ((self.ammo_shells < WEAPON_ROCKET))
                     {
                        am = WEAPON_SHOTGUN;
                     } //end if

                  } //end if
                  else
                  {
                     if ((self.weapon == IT_SUPER_SHOTGUN))
                     {
                        self.weapon = IT_SHOTGUN;
                        if ((self.ammo_shells < WEAPON_SHOTGUN))
                        {
                           am = WEAPON_SHOTGUN;
                        } //end if

                     } //end if
                     else
                     {
                        if ((self.weapon == IT_SHOTGUN))
                        {
                           self.weapon = IT_AXE;

                        } //end if
                        else
                        {
                           if ((self.weapon == IT_AXE))
                           {
                              self.weapon = IT_LIGHTNING;
                              if ((self.ammo_cells < WEAPON_SHOTGUN))
                              {
                                 am = WEAPON_SHOTGUN;
                              } //end if
                           } //end if
                        } //end if
                     } //end if
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
      if (((it & self.weapon) && (am == CAM_IDLE)))
      {
         W_SetCurrentAmmo ();
         return ;
      } //end if
   } //end while
}; //end of the function CycleWeaponReverseCommand

void () W_SetCurrentAmmo =
{
   if ((self.classname == "player"))
   {
      player_run ();
   } //end if
   self.items = (self.items - (self.items & (((IT_SHELLS | IT_NAILS) | IT_ROCKETS) | IT_CELLS)));
   self.weaponmodel = "";
   if ((self.weapon == IT_AXE))
   {
      self.currentammo = CAM_IDLE;
      if ((self.aflag != TRUE))
      {
         self.weaponmodel = "progs/v_axe.mdl";
      } //end if
      self.weaponframe = CAM_IDLE;

   } //end if
   else
   {
      if ((self.weapon == IT_SHOTGUN))
      {
         self.currentammo = self.ammo_shells;
         if ((self.aflag != TRUE))
         {
            self.weaponmodel = "progs/v_shot.mdl";
         } //end if
         self.weaponframe = CAM_IDLE;
         self.items = (self.items | IT_SHELLS);

      } //end if
      else
      {
         if ((self.weapon == IT_SUPER_SHOTGUN))
         {
            self.currentammo = self.ammo_shells;
            if ((self.aflag != TRUE))
            {
               self.weaponmodel = "progs/v_shot2.mdl";
            } //end if
            self.weaponframe = CAM_IDLE;
            self.items = (self.items | IT_SHELLS);

         } //end if
         else
         {
            if ((self.weapon == IT_NAILGUN))
            {
               self.currentammo = self.ammo_nails;
               if ((self.aflag != TRUE))
               {
                  self.weaponmodel = "progs/v_nail.mdl";
               } //end if
               self.weaponframe = CAM_IDLE;
               self.items = (self.items | IT_NAILS);

            } //end if
            else
            {
               if ((self.weapon == IT_SUPER_NAILGUN))
               {
                  self.currentammo = self.ammo_nails;
                  if ((self.aflag != TRUE))
                  {
                     self.weaponmodel = "progs/v_nail2.mdl";
                  } //end if
                  self.weaponframe = CAM_IDLE;
                  self.items = (self.items | IT_NAILS);

               } //end if
               else
               {
                  if ((self.weapon == IT_GRENADE_LAUNCHER))
                  {
                     self.currentammo = self.ammo_rockets;
                     if ((self.aflag != TRUE))
                     {
                        self.weaponmodel = "progs/v_rock.mdl";
                     } //end if
                     self.weaponframe = CAM_IDLE;
                     self.items = (self.items | IT_ROCKETS);

                  } //end if
                  else
                  {
                     if ((self.weapon == IT_ROCKET_LAUNCHER))
                     {
                        self.currentammo = self.ammo_rockets;
                        if ((self.aflag != TRUE))
                        {
                           self.weaponmodel = "progs/v_rock2.mdl";
                        } //end if
                        self.weaponframe = CAM_IDLE;
                        self.items = (self.items | IT_ROCKETS);

                     } //end if
                     else
                     {
                        if ((self.weapon == IT_LIGHTNING))
                        {
                           self.currentammo = self.ammo_cells;
                           if ((self.aflag != TRUE))
                           {
                              self.weaponmodel = "progs/v_light.mdl";
                           } //end if
                           self.weaponframe = CAM_IDLE;
                           self.items = (self.items | IT_CELLS);

                        } //end if
                        else
                        {
                           self.currentammo = CAM_IDLE;
                           self.weaponmodel = "";
                           self.weaponframe = CAM_IDLE;
                        } //end if
                     } //end if
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
   } //end if
}; //end of the function W_SetCurrentAmmo
float () W_BestWeapon =
{
   local float it;

   it = self.items;
   if (((self.ammo_nails >= TRUE) && (it & IT_SUPER_NAILGUN)))
   {
      return (IT_SUPER_NAILGUN);

   } //end if
   else
   {
      if (((self.ammo_nails >= WEAPON_ROCKET) && (it & IT_NAILGUN)))
      {
         return (IT_NAILGUN);

      } //end if
      else
      {
         if (((self.ammo_shells >= WEAPON_ROCKET) && (it & IT_SUPER_SHOTGUN)))
         {
            return (IT_SUPER_SHOTGUN);

         } //end if
         else
         {
            if (((self.ammo_cells >= TRUE) && (it & IT_LIGHTNING)))
            {
               return (IT_LIGHTNING);

            } //end if
            else
            {
               if (((self.ammo_shells >= TRUE) && (it & IT_SHOTGUN)))
               {
                  return (IT_SHOTGUN);
               } //end if
            } //end if
         } //end if
      } //end if
   } //end if
   return (IT_AXE);
}; //end of the function W_BestWeapon
float () W_CheckNoAmmo =
{
   if ((self.currentammo > FALSE))
   {
      return (TRUE);
   } //end if
   if ((self.weapon == IT_AXE))
   {
      return (TRUE);
   } //end if
   self.weapon = W_BestWeapon ();
   W_SetCurrentAmmo ();
   return (FALSE);
}; //end of the function W_CheckNoAmmo

void () player_axe1;

void () player_axeb1;

void () player_axec1;

void () player_axed1;

void () player_shot1;

void () player_nail1;

void () player_light1;

void () player_rocket1;

void () W_Attack =
{
   local float r;

   if (!W_CheckNoAmmo ())
   {
      return ;
   } //end if
   makevectors (self.v_angle);
   self.show_hostile = (time + TRUE);
   signalnoise (self,self);
   if ((self.weapon == IT_AXE))
   {
      sound (self,CHAN_WEAPON,"weapons/ax1.wav",TRUE,ATTN_NORM);
      r = random ();
      if ((r < 0.250))
      {
         player_axe1 ();

      } //end if
      else
      {
         if ((r < 0.500))
         {
            player_axeb1 ();

         } //end if
         else
         {
            if ((r < 0.750))
            {
               player_axec1 ();

            } //end if
            else
            {
               player_axed1 ();
            } //end if
         } //end if
      } //end if
      self.attack_finished = (time + 0.500);

   } //end if
   else
   {
      if ((self.weapon == IT_SHOTGUN))
      {
         player_shot1 ();
         W_FireShotgun ();
         self.attack_finished = (time + 0.500);

      } //end if
      else
      {
         if ((self.weapon == IT_SUPER_SHOTGUN))
         {
            player_shot1 ();
            W_FireSuperShotgun ();
            self.attack_finished = (time + 0.700);

         } //end if
         else
         {
            if ((self.weapon == IT_NAILGUN))
            {
               player_nail1 ();

            } //end if
            else
            {
               if ((self.weapon == IT_SUPER_NAILGUN))
               {
                  player_nail1 ();

               } //end if
               else
               {
                  if ((self.weapon == IT_GRENADE_LAUNCHER))
                  {
                     player_rocket1 ();
                     W_FireGrenade ();
                     self.attack_finished = (time + 0.600);

                  } //end if
                  else
                  {
                     if ((self.weapon == IT_ROCKET_LAUNCHER))
                     {
                        player_rocket1 ();
                        W_FireRocket ();
                        self.attack_finished = (time + 0.800);

                     } //end if
                     else
                     {
                        if ((self.weapon == IT_LIGHTNING))
                        {
                           player_light1 ();
                           self.attack_finished = (time + 0.100);
                           sound (self,CHAN_AUTO,"weapons/lstart.wav",TRUE,ATTN_NORM);
                        } //end if
                     } //end if
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
   } //end if
}; //end of the function W_Attack

void () W_ChangeWeapon =
{
   local float it;
   local float am;
   local float fl;

   it = self.items;
   am = FALSE;
   if ((self.impulse == WEAPON_SHOTGUN))
   {
      fl = IT_AXE;

   } //end if
   else
   {
      if ((self.impulse == WEAPON_ROCKET))
      {
         fl = IT_SHOTGUN;
         if ((self.ammo_shells < WEAPON_SHOTGUN))
         {
            am = TRUE;
         } //end if

      } //end if
      else
      {
         if ((self.impulse == MOVETYPE_WALK))
         {
            fl = IT_SUPER_SHOTGUN;
            if ((self.ammo_shells < WEAPON_ROCKET))
            {
               am = TRUE;
            } //end if

         } //end if
         else
         {
            if ((self.impulse == WEAPON_SPIKES))
            {
               fl = IT_NAILGUN;
               if ((self.ammo_nails < WEAPON_SHOTGUN))
               {
                  am = TRUE;
               } //end if

            } //end if
            else
            {
               if ((self.impulse == MOVETYPE_FLY))
               {
                  fl = IT_SUPER_NAILGUN;
                  if ((self.ammo_nails < WEAPON_ROCKET))
                  {
                     am = TRUE;
                  } //end if

               } //end if
               else
               {
                  if ((self.impulse == CAM_NOCLIP))
                  {
                     fl = IT_GRENADE_LAUNCHER;
                     if ((self.ammo_rockets < WEAPON_SHOTGUN))
                     {
                        am = TRUE;
                     } //end if

                  } //end if
                  else
                  {
                     if ((self.impulse == MOVETYPE_PUSH))
                     {
                        fl = IT_ROCKET_LAUNCHER;
                        if ((self.ammo_rockets < WEAPON_SHOTGUN))
                        {
                           am = TRUE;
                        } //end if

                     } //end if
                     else
                     {
                        if ((self.impulse == WEAPON_ROCKET))
                        {
                           fl = IT_LIGHTNING;
                           if ((self.ammo_cells < WEAPON_SHOTGUN))
                           {
                              am = TRUE;
                           } //end if
                        } //end if
                     } //end if
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
   } //end if
   self.impulse = FALSE;
   if (!(self.items & fl))
   {
      sprint (self,"no weapon.\n");
      return ;
   } //end if
   if (am)
   {
      sprint (self,"not enough ammo.\n");
      return ;
   } //end if
   self.weapon = fl;
   W_SetCurrentAmmo ();
}; //end of the function W_ChangeWeapon

void () CheatCommand =
{
   if ((deathmatch || coop))
   {
      return ;
   } //end if
   self.ammo_rockets = MUST_HAVE;
   self.ammo_nails = 200.000;
   self.ammo_shells = MUST_HAVE;
   self.items = (((((((((self.items | IT_AXE) | IT_SHOTGUN) | IT_SUPER_SHOTGUN) | IT_NAILGUN) | IT_SUPER_NAILGUN) | IT_GRENADE_LAUNCHER) | IT_ROCKET_LAUNCHER) | IT_KEY1) | IT_KEY2);
   self.ammo_cells = 200.000;
   self.items = (self.items | IT_LIGHTNING);
   self.weapon = IT_ROCKET_LAUNCHER;
   self.impulse = CAM_IDLE;
   W_SetCurrentAmmo ();
}; //end of the function CheatCommand

void () CycleWeaponCommand =
{
   local float it;
   local float am;

   it = self.items;
   self.impulse = CAM_IDLE;
   while (TRUE)
   {
      am = FALSE;
      if ((self.weapon == IT_LIGHTNING))
      {
         self.weapon = IT_AXE;

      } //end if
      else
      {
         if ((self.weapon == IT_AXE))
         {
            self.weapon = IT_SHOTGUN;
            if ((self.ammo_shells < TRUE))
            {
               am = TRUE;
            } //end if

         } //end if
         else
         {
            if ((self.weapon == IT_SHOTGUN))
            {
               self.weapon = IT_SUPER_SHOTGUN;
               if ((self.ammo_shells < WEAPON_ROCKET))
               {
                  am = TRUE;
               } //end if

            } //end if
            else
            {
               if ((self.weapon == IT_SUPER_SHOTGUN))
               {
                  self.weapon = IT_NAILGUN;
                  if ((self.ammo_nails < WEAPON_SHOTGUN))
                  {
                     am = TRUE;
                  } //end if

               } //end if
               else
               {
                  if ((self.weapon == IT_NAILGUN))
                  {
                     self.weapon = IT_SUPER_NAILGUN;
                     if ((self.ammo_nails < WEAPON_ROCKET))
                     {
                        am = TRUE;
                     } //end if

                  } //end if
                  else
                  {
                     if ((self.weapon == IT_SUPER_NAILGUN))
                     {
                        self.weapon = IT_GRENADE_LAUNCHER;
                        if ((self.ammo_rockets < WEAPON_SHOTGUN))
                        {
                           am = TRUE;
                        } //end if

                     } //end if
                     else
                     {
                        if ((self.weapon == IT_GRENADE_LAUNCHER))
                        {
                           self.weapon = IT_ROCKET_LAUNCHER;
                           if ((self.ammo_rockets < WEAPON_SHOTGUN))
                           {
                              am = TRUE;
                           } //end if

                        } //end if
                        else
                        {
                           if ((self.weapon == IT_ROCKET_LAUNCHER))
                           {
                              self.weapon = IT_LIGHTNING;
                              if ((self.ammo_cells < WEAPON_SHOTGUN))
                              {
                                 am = TRUE;
                              } //end if
                           } //end if
                        } //end if
                     } //end if
                  } //end if
               } //end if
            } //end if
         } //end if
      } //end if
      if (((self.items & self.weapon) && (am == FALSE)))
      {
         W_SetCurrentAmmo ();
         return ;
      } //end if
   } //end while
}; //end of the function CycleWeaponCommand

void () QuadCheat =
{
   if ((deathmatch || coop))
   {
      return ;
   } //end if
   self.super_time = TRUE;
   self.super_damage_finished = (time + SVC_INTERMISSION);
   self.items = (self.items | IT_QUAD);
   dprint ("quad cheat\n");
}; //end of the function QuadCheat

void () ImpulseCommands =
{
   local string tmp;

   if (((self.impulse >= WEAPON_SHOTGUN) && (self.impulse <= WEAPON_BIG)))
   {
      W_ChangeWeapon ();
   } //end if
   if ((self.impulse == TE_LAVASPLASH))
   {
      CycleWeaponCommand ();
   } //end if
   if ((self.impulse == 12.000))
   {
      CycleWeaponReverseCommand ();
   } //end if
   if ((self.impulse == 13.000))
   {
      setWatcherMode ();

   } //end if
   else
   {
      if ((self.impulse == 100.000))
      {
         bprint ("Dumping Waypoints to Console...\n");
         DumpWaypoints ();
         bprint ("Check your console log/condump!\n");

      } //end if
      else
      {
         botImpulseCommand ();
      } //end if
   } //end if
   self.impulse = CAM_IDLE;
}; //end of the function ImpulseCommands

void () W_WeaponFrame =
{
   if ((time < self.attack_finished))
   {
      return ;
   } //end if
   if (self.impulse)
   {
      ImpulseCommands ();
   } //end if
   if ((self.classname == "watcher"))
   {
      return ;
   } //end if
   if (self.button0)
   {
      SuperDamageSound ();
      W_Attack ();
   } //end if
}; //end of the function W_WeaponFrame

void () SuperDamageSound =
{
   if ((self.super_damage_finished > time))
   {
      if ((self.super_sound < time))
      {
         self.super_sound = (time + TRUE);
         sound (self,CHAN_BODY,"items/damage3.wav",TRUE,ATTN_NORM);
      } //end if
   } //end if
   return ;
}; //end of the function SuperDamageSound
