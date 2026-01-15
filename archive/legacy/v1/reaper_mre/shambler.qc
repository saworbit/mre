
void () sham_stand1 = [0.000, sham_stand2]
{
   ai_stand ();
}; //end of the function sham_stand1

void () sham_stand2 = [1.000, sham_stand3]
{
   ai_stand ();
}; //end of the function sham_stand2

void () sham_stand3 = [2.000, sham_stand4]
{
   ai_stand ();
}; //end of the function sham_stand3

void () sham_stand4 = [3.000, sham_stand5]
{
   ai_stand ();
}; //end of the function sham_stand4

void () sham_stand5 = [4.000, sham_stand6]
{
   ai_stand ();
}; //end of the function sham_stand5

void () sham_stand6 = [5.000, sham_stand7]
{
   ai_stand ();
}; //end of the function sham_stand6

void () sham_stand7 = [6.000, sham_stand8]
{
   ai_stand ();
}; //end of the function sham_stand7

void () sham_stand8 = [7.000, sham_stand9]
{
   ai_stand ();
}; //end of the function sham_stand8

void () sham_stand9 = [8.000, sham_stand10]
{
   ai_stand ();
}; //end of the function sham_stand9

void () sham_stand10 = [9.000, sham_stand11]
{
   ai_stand ();
}; //end of the function sham_stand10

void () sham_stand11 = [10.000, sham_stand12]
{
   ai_stand ();
}; //end of the function sham_stand11

void () sham_stand12 = [11.000, sham_stand13]
{
   ai_stand ();
}; //end of the function sham_stand12

void () sham_stand13 = [12.000, sham_stand14]
{
   ai_stand ();
}; //end of the function sham_stand13

void () sham_stand14 = [13.000, sham_stand15]
{
   ai_stand ();
}; //end of the function sham_stand14

void () sham_stand15 = [14.000, sham_stand16]
{
   ai_stand ();
}; //end of the function sham_stand15

void () sham_stand16 = [15.000, sham_stand17]
{
   ai_stand ();
}; //end of the function sham_stand16

void () sham_stand17 = [16.000, sham_stand1]
{
   ai_stand ();
}; //end of the function sham_stand17

void () sham_walk1 = [17.000, sham_walk2]
{
   ai_walk (MOVETYPE_BOUNCE);
}; //end of the function sham_walk1

void () sham_walk2 = [18.000, sham_walk3]
{
   ai_walk (MOVETYPE_FLYMISSILE);
}; //end of the function sham_walk2

void () sham_walk3 = [19.000, sham_walk4]
{
   ai_walk (MOVETYPE_FLYMISSILE);
}; //end of the function sham_walk3

void () sham_walk4 = [20.000, sham_walk5]
{
   ai_walk (MOVETYPE_FLY);
}; //end of the function sham_walk4

void () sham_walk5 = [21.000, sham_walk6]
{
   ai_walk (MOVETYPE_TOSS);
}; //end of the function sham_walk5

void () sham_walk6 = [22.000, sham_walk7]
{
   ai_walk (12.000);
}; //end of the function sham_walk6

void () sham_walk7 = [23.000, sham_walk8]
{
   ai_walk (FL_CLIENT);
}; //end of the function sham_walk7

void () sham_walk8 = [24.000, sham_walk9]
{
   ai_walk (MOVETYPE_WALK);
}; //end of the function sham_walk8

void () sham_walk9 = [25.000, sham_walk10]
{
   ai_walk (MSG_UPDATENAME);
}; //end of the function sham_walk9

void () sham_walk10 = [26.000, sham_walk11]
{
   ai_walk (MOVETYPE_FLYMISSILE);
}; //end of the function sham_walk10

void () sham_walk11 = [27.000, sham_walk12]
{
   ai_walk (MOVETYPE_PUSH);
}; //end of the function sham_walk11

void () sham_walk12 = [28.000, sham_walk1]
{
   ai_walk (MOVETYPE_PUSH);
   if ((random () > 0.800))
   {
      sound (self,CHAN_VOICE,"shambler/sidle.wav",TRUE,ATTN_IDLE);
   } //end if
}; //end of the function sham_walk12

void () sham_run1 = [29.000, sham_run2]
{
   ai_run (KINDA_WANT);
}; //end of the function sham_run1

void () sham_run2 = [30.000, sham_run3]
{
   ai_run (24.000);
}; //end of the function sham_run2

void () sham_run3 = [31.000, sham_run4]
{
   ai_run (KINDA_WANT);
}; //end of the function sham_run3

void () sham_run4 = [32.000, sham_run5]
{
   ai_run (KINDA_WANT);
}; //end of the function sham_run4

void () sham_run5 = [33.000, sham_run6]
{
   ai_run (24.000);
}; //end of the function sham_run5

void () sham_run6 = [34.000, sham_run1]
{
   ai_run (KINDA_WANT);
   if ((random () > 0.800))
   {
      sound (self,CHAN_VOICE,"shambler/sidle.wav",TRUE,ATTN_IDLE);
   } //end if
}; //end of the function sham_run6

void () sham_smash1 = [35.000, sham_smash2]
{
   sound (self,CHAN_VOICE,"shambler/melee1.wav",TRUE,ATTN_NORM);
   ai_charge (FL_SWIM);
}; //end of the function sham_smash1

void () sham_smash2 = [36.000, sham_smash3]
{
   ai_charge (MOVETYPE_TOSS);
}; //end of the function sham_smash2

void () sham_smash3 = [37.000, sham_smash4]
{
   ai_charge (MOVETYPE_TOSS);
}; //end of the function sham_smash3

void () sham_smash4 = [38.000, sham_smash5]
{
   ai_charge (MOVETYPE_FLY);
}; //end of the function sham_smash4

void () sham_smash5 = [39.000, sham_smash6]
{
   ai_charge (MOVETYPE_STEP);
}; //end of the function sham_smash5

void () sham_smash6 = [40.000, sham_smash7]
{
   ai_charge (TRUE);
}; //end of the function sham_smash6

void () sham_smash7 = [41.000, sham_smash8]
{
   ai_charge (FALSE);
}; //end of the function sham_smash7

void () sham_smash8 = [42.000, sham_smash9]
{
   ai_charge (FALSE);
}; //end of the function sham_smash8

void () sham_smash9 = [43.000, sham_smash10]
{
   ai_charge (FALSE);
}; //end of the function sham_smash9

void () sham_smash10 = [44.000, sham_smash11]
{
   /* ERROR: Fields and functions must be global */
   local vector delta;
   local float ldmg;

   if (!self.enemy)
   {
      return ;
   } //end if
   ai_charge (FALSE);
   delta = (self.enemy.origin - self.origin);
   if ((vlen (delta) > MUST_HAVE))
   {
      return ;
   } //end if
   if (!CanDamage (self.enemy,self))
   {
      return ;
   } //end if
   ldmg = (((random () + random ()) + random ()) * 40.000);
   T_Damage (self.enemy,self,self,ldmg);
   sound (self,CHAN_VOICE,"shambler/smack.wav",TRUE,ATTN_NORM);
   SpawnMeatSpray ((self.origin + (v_forward * FL_INWATER)),((crandom () * MUST_HAVE) * v_right));
   SpawnMeatSpray ((self.origin + (v_forward * FL_INWATER)),((crandom () * MUST_HAVE) * v_right));
}; //end of the function sham_smash10

void () sham_smash11 = [45.000, sham_smash12]
{
   ai_charge (MOVETYPE_FLY);
}; //end of the function sham_smash11

void () sham_smash12 = [46.000, sham_run1]
{
   ai_charge (MOVETYPE_STEP);
}; //end of the function sham_smash12

void (float side) ShamClaw =
{
   local vector delta;
   local float ldmg;

   if (!self.enemy)
   {
      return ;
   } //end if
   ai_charge (MOVETYPE_BOUNCE);
   delta = (self.enemy.origin - self.origin);
   if ((vlen (delta) > MUST_HAVE))
   {
      return ;
   } //end if
   ldmg = (((random () + random ()) + random ()) * KINDA_WANT);
   T_Damage (self.enemy,self,self,ldmg);
   sound (self,CHAN_VOICE,"shambler/smack.wav",TRUE,ATTN_NORM);
   if (side)
   {
      makevectors (self.angles);
      SpawnMeatSpray ((self.origin + (v_forward * FL_INWATER)),(side * v_right));
   } //end if
}; //end of the function ShamClaw

void () sham_swingl1 = [56.000, sham_swingl2]
{
   sound (self,CHAN_VOICE,"shambler/melee2.wav",TRUE,ATTN_NORM);
   ai_charge (MOVETYPE_FLY);
}; //end of the function sham_swingl1

void () sham_swingl2 = [57.000, sham_swingl3]
{
   ai_charge (MOVETYPE_WALK);
}; //end of the function sham_swingl2

void () sham_swingl3 = [58.000, sham_swingl4]
{
   ai_charge (MOVETYPE_PUSH);
}; //end of the function sham_swingl3

void () sham_swingl4 = [59.000, sham_swingl5]
{
   ai_charge (MOVETYPE_WALK);
}; //end of the function sham_swingl4

void () sham_swingl5 = [60.000, sham_swingl6]
{
   ai_charge (MOVETYPE_PUSH);
}; //end of the function sham_swingl5

void () sham_swingl6 = [61.000, sham_swingl7]
{
   ai_charge (MOVETYPE_FLYMISSILE);
}; //end of the function sham_swingl6

void () sham_swingl7 = [62.000, sham_swingl8]
{
   ai_charge (MOVETYPE_FLY);
   ShamClaw (250.000);
}; //end of the function sham_swingl7

void () sham_swingl8 = [63.000, sham_swingl9]
{
   ai_charge (MOVETYPE_STEP);
}; //end of the function sham_swingl8

void () sham_swingl9 = [64.000, sham_run1]
{
   ai_charge (FL_CLIENT);
   if ((random () < 0.500))
   {
      self.think = sham_swingr1;
   } //end if
}; //end of the function sham_swingl9

void () sham_swingr1 = [47.000, sham_swingr2]
{
   sound (self,CHAN_VOICE,"shambler/melee1.wav",TRUE,ATTN_NORM);
   ai_charge (TRUE);
}; //end of the function sham_swingr1

void () sham_swingr2 = [48.000, sham_swingr3]
{
   ai_charge (FL_CLIENT);
}; //end of the function sham_swingr2

void () sham_swingr3 = [49.000, sham_swingr4]
{
   ai_charge (MSG_UPDATEFRAGS);
}; //end of the function sham_swingr3

void () sham_swingr4 = [50.000, sham_swingr5]
{
   ai_charge (MOVETYPE_PUSH);
}; //end of the function sham_swingr4

void () sham_swingr5 = [51.000, sham_swingr6]
{
   ai_charge (MOVETYPE_WALK);
}; //end of the function sham_swingr5

void () sham_swingr6 = [52.000, sham_swingr7]
{
   ai_charge (MOVETYPE_TOSS);
}; //end of the function sham_swingr6

void () sham_swingr7 = [53.000, sham_swingr8]
{
   ai_charge (MOVETYPE_TOSS);
   ShamClaw (-250.000);
}; //end of the function sham_swingr7

void () sham_swingr8 = [54.000, sham_swingr9]
{
   ai_charge (MOVETYPE_WALK);
}; //end of the function sham_swingr8

void () sham_swingr9 = [55.000, sham_run1]
{
   ai_charge (TRUE);
   ai_charge (MOVETYPE_BOUNCE);
   if ((random () < 0.500))
   {
      self.think = sham_swingl1;
   } //end if
}; //end of the function sham_swingr9

void () sham_melee =
{
   local float chance;

   chance = random ();
   if (((chance > 0.600) || (self.health == SEARCH_RADIUS)))
   {
      sham_smash1 ();

   } //end if
   else
   {
      if ((chance > 0.300))
      {
         sham_swingr1 ();

      } //end if
      else
      {
         sham_swingl1 ();
      } //end if
   } //end if
}; //end of the function sham_melee

void () CastLightning =
{
   local vector org;
   local vector dir;

   self.effects = (self.effects | EF_MUZZLEFLASH);
   ai_face ();
   org = (self.origin + '0.000 0.000 40.000');
   dir = ((self.enemy.origin + '0.000 0.000 16.000') - org);
   dir = normalize (dir);
   traceline (org,(self.origin + (dir * SEARCH_RADIUS)),TRUE,self);
   WriteByte (MSG_BROADCAST,SVC_TEMPENTITY);
   WriteByte (MSG_BROADCAST,TE_LIGHTNING1);
   WriteEntity (MSG_BROADCAST,self);
   WriteCoord (MSG_BROADCAST,org_x);
   WriteCoord (MSG_BROADCAST,org_y);
   WriteCoord (MSG_BROADCAST,org_z);
   WriteCoord (MSG_BROADCAST,trace_endpos_x);
   WriteCoord (MSG_BROADCAST,trace_endpos_y);
   WriteCoord (MSG_BROADCAST,trace_endpos_z);
   LightningDamage (org,trace_endpos,self,MOVETYPE_BOUNCE);
}; //end of the function CastLightning

void () sham_magic1 = [65.000, sham_magic2]
{
   ai_face ();
   sound (self,CHAN_WEAPON,"shambler/sattck1.wav",TRUE,ATTN_NORM);
}; //end of the function sham_magic1

void () sham_magic2 = [66.000, sham_magic3]
{
   ai_face ();
}; //end of the function sham_magic2

void () sham_magic3 = [67.000, sham_magic4]
{
   /* ERROR: Fields and functions must be global */
   local entity o;

   ai_face ();
   self.nextthink = (self.nextthink + 0.200);
   self.effects = (self.effects | EF_MUZZLEFLASH);
   ai_face ();
   self.owner = spawn ();
   o = self.owner;
   setmodel (o,"progs/s_light.mdl");
   setorigin (o,self.origin);
   o.angles = self.angles;
   o.nextthink = (time + 0.700);
   o.think = SUB_Remove;
}; //end of the function sham_magic3

void () sham_magic4 = [68.000, sham_magic5]
{
   self.effects = (self.effects | EF_MUZZLEFLASH);
   self.owner.frame = TRUE;
}; //end of the function sham_magic4

void () sham_magic5 = [69.000, sham_magic6]
{
   self.effects = (self.effects | EF_MUZZLEFLASH);
   self.owner.frame = FL_SWIM;
}; //end of the function sham_magic5

void () sham_magic6 = [70.000, sham_magic9]
{
   remove (self.owner);
   CastLightning ();
   sound (self,CHAN_WEAPON,"shambler/sboom.wav",TRUE,ATTN_NORM);
}; //end of the function sham_magic6

void () sham_magic9 = [73.000, sham_magic10]
{
   CastLightning ();
}; //end of the function sham_magic9

void () sham_magic10 = [74.000, sham_magic11]
{
   CastLightning ();
}; //end of the function sham_magic10

void () sham_magic11 = [75.000, sham_magic12]
{
   if ((skill == MOVETYPE_WALK))
   {
      CastLightning ();
   } //end if
}; //end of the function sham_magic11

void () sham_magic12 = [76.000, sham_run1]
{
}; //end of the function sham_magic12

void () sham_pain1 = [77.000, sham_pain2]
{
}; //end of the function sham_pain1

void () sham_pain2 = [78.000, sham_pain3]
{
}; //end of the function sham_pain2

void () sham_pain3 = [79.000, sham_pain4]
{
}; //end of the function sham_pain3

void () sham_pain4 = [80.000, sham_pain5]
{
}; //end of the function sham_pain4

void () sham_pain5 = [81.000, sham_pain6]
{
}; //end of the function sham_pain5

void () sham_pain6 = [82.000, sham_run1]
{
}; //end of the function sham_pain6

void (entity attacker, float damage) sham_pain =
{
   sound (self,CHAN_VOICE,"shambler/shurt2.wav",TRUE,ATTN_NORM);
   if ((self.health <= FALSE))
   {
      return ;
   } //end if
   if (((random () * 400.000) > damage))
   {
      return ;
   } //end if
   if ((self.pain_finished > time))
   {
      return ;
   } //end if
   self.pain_finished = (time + FL_SWIM);
   sham_pain1 ();
}; //end of the function sham_pain

void () sham_death1 = [83.000, sham_death2]
{
}; //end of the function sham_death1

void () sham_death2 = [84.000, sham_death3]
{
}; //end of the function sham_death2

void () sham_death3 = [85.000, sham_death4]
{
   self.solid = SOLID_NOT;
}; //end of the function sham_death3

void () sham_death4 = [86.000, sham_death5]
{
}; //end of the function sham_death4

void () sham_death5 = [87.000, sham_death6]
{
}; //end of the function sham_death5

void () sham_death6 = [88.000, sham_death7]
{
}; //end of the function sham_death6

void () sham_death7 = [89.000, sham_death8]
{
}; //end of the function sham_death7

void () sham_death8 = [90.000, sham_death9]
{
}; //end of the function sham_death8

void () sham_death9 = [91.000, sham_death10]
{
}; //end of the function sham_death9

void () sham_death10 = [92.000, sham_death11]
{
}; //end of the function sham_death10

void () sham_death11 = [93.000, sham_death11]
{
}; //end of the function sham_death11

void () sham_die =
{
   if ((self.health < -60.000))
   {
      sound (self,CHAN_VOICE,"player/udeath.wav",TRUE,ATTN_NORM);
      ThrowHead ("progs/h_shams.mdl",self.health);
      ThrowGib ("progs/gib1.mdl",self.health);
      ThrowGib ("progs/gib2.mdl",self.health);
      ThrowGib ("progs/gib3.mdl",self.health);
      return ;
   } //end if
   sound (self,CHAN_VOICE,"shambler/sdeath.wav",TRUE,ATTN_NORM);
   sham_death1 ();
}; //end of the function sham_die

void () monster_shambler =
{
   if (deathmatch)
   {
      remove (self);
      return ;
   } //end if
   precache_model ("progs/shambler.mdl");
   precache_model ("progs/s_light.mdl");
   precache_model ("progs/h_shams.mdl");
   precache_model ("progs/bolt.mdl");
   precache_sound ("shambler/sattck1.wav");
   precache_sound ("shambler/sboom.wav");
   precache_sound ("shambler/sdeath.wav");
   precache_sound ("shambler/shurt2.wav");
   precache_sound ("shambler/sidle.wav");
   precache_sound ("shambler/ssight.wav");
   precache_sound ("shambler/melee1.wav");
   precache_sound ("shambler/melee2.wav");
   precache_sound ("shambler/smack.wav");
   self.solid = SOLID_SLIDEBOX;
   self.movetype = MOVETYPE_STEP;
   setmodel (self,"progs/shambler.mdl");
   setsize (self,VEC_HULL2_MIN,VEC_HULL2_MAX);
   self.health = SEARCH_RADIUS;
   self.th_stand = sham_stand1;
   self.th_walk = sham_walk1;
   self.th_run = sham_run1;
   self.th_die = sham_die;
   self.th_melee = sham_melee;
   self.th_missile = sham_magic1;
   self.th_pain = sham_pain;
   walkmonster_start ();
}; //end of the function monster_shambler
