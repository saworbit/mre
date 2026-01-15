
void () hknight_char_a1;

void () hknight_run1;

void () hk_idle_sound;

void (float offset) hknight_shot =
{
   local vector offang;
   local vector org;
   local vector vec;

   offang = vectoangles ((self.enemy.origin - self.origin));
   offang_y = (offang_y + (offset * MOVETYPE_TOSS));
   makevectors (offang);
   org = (((self.origin + self.mins) + (self.size * 0.500)) + (v_forward * KINDA_WANT));
   vec = normalize (v_forward);
   vec_z = ((FALSE - vec_z) + ((random () - 0.500) * 0.100));
   launch_spike (org,vec);
   newmis.classname = "knightspike";
   setmodel (newmis,"progs/k_spike.mdl");
   setsize (newmis,VEC_ORIGIN,VEC_ORIGIN);
   newmis.velocity = (vec * 300.000);
   sound (self,CHAN_WEAPON,"hknight/attack1.wav",TRUE,ATTN_NORM);
}; //end of the function hknight_shot

void () CheckForCharge =
{
   if (!enemy_vis)
   {
      return ;
   } //end if
   if ((time < self.attack_finished))
   {
      return ;
   } //end if
   if ((fabs ((self.origin_z - self.enemy.origin_z)) > KINDA_WANT))
   {
      return ;
   } //end if
   if ((vlen ((self.origin - self.enemy.origin)) < 80.000))
   {
      return ;
   } //end if
   SUB_AttackFinished (FL_SWIM);
   hknight_char_a1 ();
}; //end of the function CheckForCharge

void () CheckContinueCharge =
{
   if ((time > self.attack_finished))
   {
      SUB_AttackFinished (MOVETYPE_WALK);
      hknight_run1 ();
      return ;
   } //end if
   if ((random () > 0.500))
   {
      sound (self,CHAN_WEAPON,"knight/sword2.wav",TRUE,ATTN_NORM);

   } //end if
   else
   {
      sound (self,CHAN_WEAPON,"knight/sword1.wav",TRUE,ATTN_NORM);
   } //end if
}; //end of the function CheckContinueCharge

void () hknight_stand1 = [0.000, hknight_stand2]
{
   ai_stand ();
}; //end of the function hknight_stand1

void () hknight_stand2 = [1.000, hknight_stand3]
{
   ai_stand ();
}; //end of the function hknight_stand2

void () hknight_stand3 = [2.000, hknight_stand4]
{
   ai_stand ();
}; //end of the function hknight_stand3

void () hknight_stand4 = [3.000, hknight_stand5]
{
   ai_stand ();
}; //end of the function hknight_stand4

void () hknight_stand5 = [4.000, hknight_stand6]
{
   ai_stand ();
}; //end of the function hknight_stand5

void () hknight_stand6 = [5.000, hknight_stand7]
{
   ai_stand ();
}; //end of the function hknight_stand6

void () hknight_stand7 = [6.000, hknight_stand8]
{
   ai_stand ();
}; //end of the function hknight_stand7

void () hknight_stand8 = [7.000, hknight_stand9]
{
   ai_stand ();
}; //end of the function hknight_stand8

void () hknight_stand9 = [8.000, hknight_stand1]
{
   ai_stand ();
}; //end of the function hknight_stand9

void () hknight_walk1 = [9.000, hknight_walk2]
{
   hk_idle_sound ();
   ai_walk (FL_SWIM);
}; //end of the function hknight_walk1

void () hknight_walk2 = [10.000, hknight_walk3]
{
   ai_walk (MOVETYPE_FLY);
}; //end of the function hknight_walk2

void () hknight_walk3 = [11.000, hknight_walk4]
{
   ai_walk (MOVETYPE_FLY);
}; //end of the function hknight_walk3

void () hknight_walk4 = [12.000, hknight_walk5]
{
   ai_walk (MOVETYPE_STEP);
}; //end of the function hknight_walk4

void () hknight_walk5 = [13.000, hknight_walk6]
{
   ai_walk (MOVETYPE_STEP);
}; //end of the function hknight_walk5

void () hknight_walk6 = [14.000, hknight_walk7]
{
   ai_walk (FL_SWIM);
}; //end of the function hknight_walk6

void () hknight_walk7 = [15.000, hknight_walk8]
{
   ai_walk (FL_SWIM);
}; //end of the function hknight_walk7

void () hknight_walk8 = [16.000, hknight_walk9]
{
   ai_walk (MOVETYPE_WALK);
}; //end of the function hknight_walk8

void () hknight_walk9 = [17.000, hknight_walk10]
{
   ai_walk (MOVETYPE_WALK);
}; //end of the function hknight_walk9

void () hknight_walk10 = [18.000, hknight_walk11]
{
   ai_walk (MOVETYPE_STEP);
}; //end of the function hknight_walk10

void () hknight_walk11 = [19.000, hknight_walk12]
{
   ai_walk (MOVETYPE_WALK);
}; //end of the function hknight_walk11

void () hknight_walk12 = [20.000, hknight_walk13]
{
   ai_walk (MOVETYPE_STEP);
}; //end of the function hknight_walk12

void () hknight_walk13 = [21.000, hknight_walk14]
{
   ai_walk (MOVETYPE_TOSS);
}; //end of the function hknight_walk13

void () hknight_walk14 = [22.000, hknight_walk15]
{
   ai_walk (FL_SWIM);
}; //end of the function hknight_walk14

void () hknight_walk15 = [23.000, hknight_walk16]
{
   ai_walk (FL_SWIM);
}; //end of the function hknight_walk15

void () hknight_walk16 = [24.000, hknight_walk17]
{
   ai_walk (MOVETYPE_STEP);
}; //end of the function hknight_walk16

void () hknight_walk17 = [25.000, hknight_walk18]
{
   ai_walk (MOVETYPE_WALK);
}; //end of the function hknight_walk17

void () hknight_walk18 = [26.000, hknight_walk19]
{
   ai_walk (MOVETYPE_WALK);
}; //end of the function hknight_walk18

void () hknight_walk19 = [27.000, hknight_walk20]
{
   ai_walk (MOVETYPE_WALK);
}; //end of the function hknight_walk19

void () hknight_walk20 = [28.000, hknight_walk1]
{
   ai_walk (FL_SWIM);
}; //end of the function hknight_walk20

void () hknight_run1 = [29.000, hknight_run2]
{
   hk_idle_sound ();
   ai_run (KINDA_WANT);
   CheckForCharge ();
}; //end of the function hknight_run1

void () hknight_run2 = [30.000, hknight_run3]
{
   ai_run (25.000);
}; //end of the function hknight_run2

void () hknight_run3 = [31.000, hknight_run4]
{
   ai_run (18.000);
}; //end of the function hknight_run3

void () hknight_run4 = [32.000, hknight_run5]
{
   ai_run (FL_INWATER);
}; //end of the function hknight_run4

void () hknight_run5 = [33.000, hknight_run6]
{
   ai_run (MSG_UPDATEFRAGS);
}; //end of the function hknight_run5

void () hknight_run6 = [34.000, hknight_run7]
{
   ai_run (25.000);
}; //end of the function hknight_run6

void () hknight_run7 = [35.000, hknight_run8]
{
   ai_run (21.000);
}; //end of the function hknight_run7

void () hknight_run8 = [36.000, hknight_run1]
{
   ai_run (MSG_UPDATENAME);
}; //end of the function hknight_run8

void () hknight_pain1 = [37.000, hknight_pain2]
{
   sound (self,CHAN_VOICE,"hknight/pain1.wav",TRUE,ATTN_NORM);
}; //end of the function hknight_pain1

void () hknight_pain2 = [38.000, hknight_pain3]
{
}; //end of the function hknight_pain2

void () hknight_pain3 = [39.000, hknight_pain4]
{
}; //end of the function hknight_pain3

void () hknight_pain4 = [40.000, hknight_pain5]
{
}; //end of the function hknight_pain4

void () hknight_pain5 = [41.000, hknight_run1]
{
}; //end of the function hknight_pain5

void () hknight_die1 = [42.000, hknight_die2]
{
   ai_forward (MOVETYPE_BOUNCE);
}; //end of the function hknight_die1

void () hknight_die2 = [43.000, hknight_die3]
{
   ai_forward (FL_CLIENT);
}; //end of the function hknight_die2

void () hknight_die3 = [44.000, hknight_die4]
{
   self.solid = SOLID_NOT;
   ai_forward (MOVETYPE_PUSH);
}; //end of the function hknight_die3

void () hknight_die4 = [45.000, hknight_die5]
{
}; //end of the function hknight_die4

void () hknight_die5 = [46.000, hknight_die6]
{
}; //end of the function hknight_die5

void () hknight_die6 = [47.000, hknight_die7]
{
}; //end of the function hknight_die6

void () hknight_die7 = [48.000, hknight_die8]
{
}; //end of the function hknight_die7

void () hknight_die8 = [49.000, hknight_die9]
{
   ai_forward (MOVETYPE_BOUNCE);
}; //end of the function hknight_die8

void () hknight_die9 = [50.000, hknight_die10]
{
   ai_forward (MOVETYPE_BOUNCEMISSILE);
}; //end of the function hknight_die9

void () hknight_die10 = [51.000, hknight_die11]
{
}; //end of the function hknight_die10

void () hknight_die11 = [52.000, hknight_die12]
{
}; //end of the function hknight_die11

void () hknight_die12 = [53.000, hknight_die12]
{
}; //end of the function hknight_die12

void () hknight_dieb1 = [54.000, hknight_dieb2]
{
}; //end of the function hknight_dieb1

void () hknight_dieb2 = [55.000, hknight_dieb3]
{
}; //end of the function hknight_dieb2

void () hknight_dieb3 = [56.000, hknight_dieb4]
{
   self.solid = SOLID_NOT;
}; //end of the function hknight_dieb3

void () hknight_dieb4 = [57.000, hknight_dieb5]
{
}; //end of the function hknight_dieb4

void () hknight_dieb5 = [58.000, hknight_dieb6]
{
}; //end of the function hknight_dieb5

void () hknight_dieb6 = [59.000, hknight_dieb7]
{
}; //end of the function hknight_dieb6

void () hknight_dieb7 = [60.000, hknight_dieb8]
{
}; //end of the function hknight_dieb7

void () hknight_dieb8 = [61.000, hknight_dieb9]
{
}; //end of the function hknight_dieb8

void () hknight_dieb9 = [62.000, hknight_dieb9]
{
}; //end of the function hknight_dieb9

void () hknight_die =
{
   if ((self.health < -40.000))
   {
      sound (self,CHAN_VOICE,"player/udeath.wav",TRUE,ATTN_NORM);
      ThrowHead ("progs/h_hellkn.mdl",self.health);
      ThrowGib ("progs/gib1.mdl",self.health);
      ThrowGib ("progs/gib2.mdl",self.health);
      ThrowGib ("progs/gib3.mdl",self.health);
      return ;
   } //end if
   sound (self,CHAN_VOICE,"hknight/death1.wav",TRUE,ATTN_NORM);
   if ((random () > 0.500))
   {
      hknight_die1 ();

   } //end if
   else
   {
      hknight_dieb1 ();
   } //end if
}; //end of the function hknight_die

void () hknight_magica1 = [79.000, hknight_magica2]
{
   ai_face ();
}; //end of the function hknight_magica1

void () hknight_magica2 = [80.000, hknight_magica3]
{
   ai_face ();
}; //end of the function hknight_magica2

void () hknight_magica3 = [81.000, hknight_magica4]
{
   ai_face ();
}; //end of the function hknight_magica3

void () hknight_magica4 = [82.000, hknight_magica5]
{
   ai_face ();
}; //end of the function hknight_magica4

void () hknight_magica5 = [83.000, hknight_magica6]
{
   ai_face ();
}; //end of the function hknight_magica5

void () hknight_magica6 = [84.000, hknight_magica7]
{
   ai_face ();
}; //end of the function hknight_magica6

void () hknight_magica7 = [85.000, hknight_magica8]
{
   hknight_shot (CONTENT_SOLID);
}; //end of the function hknight_magica7

void () hknight_magica8 = [86.000, hknight_magica9]
{
   hknight_shot (CONTENT_EMPTY);
}; //end of the function hknight_magica8

void () hknight_magica9 = [87.000, hknight_magica10]
{
   hknight_shot (FALSE);
}; //end of the function hknight_magica9

void () hknight_magica10 = [88.000, hknight_magica11]
{
   hknight_shot (TRUE);
}; //end of the function hknight_magica10

void () hknight_magica11 = [89.000, hknight_magica12]
{
   hknight_shot (FL_SWIM);
}; //end of the function hknight_magica11

void () hknight_magica12 = [90.000, hknight_magica13]
{
   hknight_shot (MOVETYPE_WALK);
}; //end of the function hknight_magica12

void () hknight_magica13 = [91.000, hknight_magica14]
{
   ai_face ();
}; //end of the function hknight_magica13

void () hknight_magica14 = [92.000, hknight_run1]
{
   ai_face ();
}; //end of the function hknight_magica14

void () hknight_magicb1 = [93.000, hknight_magicb2]
{
   ai_face ();
}; //end of the function hknight_magicb1

void () hknight_magicb2 = [94.000, hknight_magicb3]
{
   ai_face ();
}; //end of the function hknight_magicb2

void () hknight_magicb3 = [95.000, hknight_magicb4]
{
   ai_face ();
}; //end of the function hknight_magicb3

void () hknight_magicb4 = [96.000, hknight_magicb5]
{
   ai_face ();
}; //end of the function hknight_magicb4

void () hknight_magicb5 = [97.000, hknight_magicb6]
{
   ai_face ();
}; //end of the function hknight_magicb5

void () hknight_magicb6 = [98.000, hknight_magicb7]
{
   ai_face ();
}; //end of the function hknight_magicb6

void () hknight_magicb7 = [99.000, hknight_magicb8]
{
   hknight_shot (CONTENT_SOLID);
}; //end of the function hknight_magicb7

void () hknight_magicb8 = [100.000, hknight_magicb9]
{
   hknight_shot (CONTENT_EMPTY);
}; //end of the function hknight_magicb8

void () hknight_magicb9 = [101.000, hknight_magicb10]
{
   hknight_shot (FALSE);
}; //end of the function hknight_magicb9

void () hknight_magicb10 = [102.000, hknight_magicb11]
{
   hknight_shot (TRUE);
}; //end of the function hknight_magicb10

void () hknight_magicb11 = [103.000, hknight_magicb12]
{
   hknight_shot (FL_SWIM);
}; //end of the function hknight_magicb11

void () hknight_magicb12 = [104.000, hknight_magicb13]
{
   hknight_shot (MOVETYPE_WALK);
}; //end of the function hknight_magicb12

void () hknight_magicb13 = [105.000, hknight_run1]
{
   ai_face ();
}; //end of the function hknight_magicb13

void () hknight_magicc1 = [155.000, hknight_magicc2]
{
   ai_face ();
}; //end of the function hknight_magicc1

void () hknight_magicc2 = [156.000, hknight_magicc3]
{
   ai_face ();
}; //end of the function hknight_magicc2

void () hknight_magicc3 = [157.000, hknight_magicc4]
{
   ai_face ();
}; //end of the function hknight_magicc3

void () hknight_magicc4 = [158.000, hknight_magicc5]
{
   ai_face ();
}; //end of the function hknight_magicc4

void () hknight_magicc5 = [159.000, hknight_magicc6]
{
   ai_face ();
}; //end of the function hknight_magicc5

void () hknight_magicc6 = [160.000, hknight_magicc7]
{
   hknight_shot (CONTENT_SOLID);
}; //end of the function hknight_magicc6

void () hknight_magicc7 = [161.000, hknight_magicc8]
{
   hknight_shot (CONTENT_EMPTY);
}; //end of the function hknight_magicc7

void () hknight_magicc8 = [162.000, hknight_magicc9]
{
   hknight_shot (FALSE);
}; //end of the function hknight_magicc8

void () hknight_magicc9 = [163.000, hknight_magicc10]
{
   hknight_shot (TRUE);
}; //end of the function hknight_magicc9

void () hknight_magicc10 = [164.000, hknight_magicc11]
{
   hknight_shot (FL_SWIM);
}; //end of the function hknight_magicc10

void () hknight_magicc11 = [165.000, hknight_run1]
{
   hknight_shot (MOVETYPE_WALK);
}; //end of the function hknight_magicc11

void () hknight_char_a1 = [63.000, hknight_char_a2]
{
   ai_charge (KINDA_WANT);
}; //end of the function hknight_char_a1

void () hknight_char_a2 = [64.000, hknight_char_a3]
{
   ai_charge (25.000);
}; //end of the function hknight_char_a2

void () hknight_char_a3 = [65.000, hknight_char_a4]
{
   ai_charge (18.000);
}; //end of the function hknight_char_a3

void () hknight_char_a4 = [66.000, hknight_char_a5]
{
   ai_charge (FL_INWATER);
}; //end of the function hknight_char_a4

void () hknight_char_a5 = [67.000, hknight_char_a6]
{
   ai_charge (MSG_UPDATEFRAGS);
}; //end of the function hknight_char_a5

void () hknight_char_a6 = [68.000, hknight_char_a7]
{
   ai_charge (KINDA_WANT);
   ai_melee ();
}; //end of the function hknight_char_a6

void () hknight_char_a7 = [69.000, hknight_char_a8]
{
   ai_charge (21.000);
   ai_melee ();
}; //end of the function hknight_char_a7

void () hknight_char_a8 = [70.000, hknight_char_a9]
{
   ai_charge (MSG_UPDATENAME);
   ai_melee ();
}; //end of the function hknight_char_a8

void () hknight_char_a9 = [71.000, hknight_char_a10]
{
   ai_charge (KINDA_WANT);
   ai_melee ();
}; //end of the function hknight_char_a9

void () hknight_char_a10 = [72.000, hknight_char_a11]
{
   ai_charge (KINDA_WANT);
   ai_melee ();
}; //end of the function hknight_char_a10

void () hknight_char_a11 = [73.000, hknight_char_a12]
{
   ai_charge (18.000);
   ai_melee ();
}; //end of the function hknight_char_a11

void () hknight_char_a12 = [74.000, hknight_char_a13]
{
   ai_charge (FL_INWATER);
}; //end of the function hknight_char_a12

void () hknight_char_a13 = [75.000, hknight_char_a14]
{
   ai_charge (MSG_UPDATEFRAGS);
}; //end of the function hknight_char_a13

void () hknight_char_a14 = [76.000, hknight_char_a15]
{
   ai_charge (25.000);
}; //end of the function hknight_char_a14

void () hknight_char_a15 = [77.000, hknight_char_a16]
{
   ai_charge (21.000);
}; //end of the function hknight_char_a15

void () hknight_char_a16 = [78.000, hknight_run1]
{
   ai_charge (MSG_UPDATENAME);
}; //end of the function hknight_char_a16

void () hknight_char_b1 = [106.000, hknight_char_b2]
{
   CheckContinueCharge ();
   ai_charge (SVC_TEMPENTITY);
   ai_melee ();
}; //end of the function hknight_char_b1

void () hknight_char_b2 = [107.000, hknight_char_b3]
{
   ai_charge (MSG_UPDATECOLORS);
   ai_melee ();
}; //end of the function hknight_char_b2

void () hknight_char_b3 = [108.000, hknight_char_b4]
{
   ai_charge (12.000);
   ai_melee ();
}; //end of the function hknight_char_b3

void () hknight_char_b4 = [109.000, hknight_char_b5]
{
   ai_charge (22.000);
   ai_melee ();
}; //end of the function hknight_char_b4

void () hknight_char_b5 = [110.000, hknight_char_b6]
{
   ai_charge (18.000);
   ai_melee ();
}; //end of the function hknight_char_b5

void () hknight_char_b6 = [111.000, hknight_char_b1]
{
   ai_charge (FL_CLIENT);
   ai_melee ();
}; //end of the function hknight_char_b6

void () hknight_slice1 = [112.000, hknight_slice2]
{
   ai_charge (MOVETYPE_FLYMISSILE);
}; //end of the function hknight_slice1

void () hknight_slice2 = [113.000, hknight_slice3]
{
   ai_charge (MOVETYPE_TOSS);
}; //end of the function hknight_slice2

void () hknight_slice3 = [114.000, hknight_slice4]
{
   ai_charge (MSG_UPDATENAME);
}; //end of the function hknight_slice3

void () hknight_slice4 = [115.000, hknight_slice5]
{
   ai_charge (MOVETYPE_STEP);
}; //end of the function hknight_slice4

void () hknight_slice5 = [116.000, hknight_slice6]
{
   ai_charge (MOVETYPE_PUSH);
   ai_melee ();
}; //end of the function hknight_slice5

void () hknight_slice6 = [117.000, hknight_slice7]
{
   ai_charge (15.000);
   ai_melee ();
}; //end of the function hknight_slice6

void () hknight_slice7 = [118.000, hknight_slice8]
{
   ai_charge (FL_CLIENT);
   ai_melee ();
}; //end of the function hknight_slice7

void () hknight_slice8 = [119.000, hknight_slice9]
{
   ai_charge (FL_SWIM);
   ai_melee ();
}; //end of the function hknight_slice8

void () hknight_slice9 = [120.000, hknight_slice10]
{
   ai_melee ();
}; //end of the function hknight_slice9

void () hknight_slice10 = [121.000, hknight_run1]
{
   ai_charge (MOVETYPE_WALK);
}; //end of the function hknight_slice10

void () hknight_smash1 = [122.000, hknight_smash2]
{
   ai_charge (TRUE);
}; //end of the function hknight_smash1

void () hknight_smash2 = [123.000, hknight_smash3]
{
   ai_charge (MSG_UPDATENAME);
}; //end of the function hknight_smash2

void () hknight_smash3 = [124.000, hknight_smash4]
{
   ai_charge (MOVETYPE_FLYMISSILE);
}; //end of the function hknight_smash3

void () hknight_smash4 = [125.000, hknight_smash5]
{
   ai_charge (MOVETYPE_BOUNCEMISSILE);
}; //end of the function hknight_smash4

void () hknight_smash5 = [126.000, hknight_smash6]
{
   ai_charge (MOVETYPE_BOUNCE);
   ai_melee ();
}; //end of the function hknight_smash5

void () hknight_smash6 = [127.000, hknight_smash7]
{
   ai_charge (MOVETYPE_PUSH);
   ai_melee ();
}; //end of the function hknight_smash6

void () hknight_smash7 = [128.000, hknight_smash8]
{
   ai_charge (12.000);
   ai_melee ();
}; //end of the function hknight_smash7

void () hknight_smash8 = [129.000, hknight_smash9]
{
   ai_charge (FL_SWIM);
   ai_melee ();
}; //end of the function hknight_smash8

void () hknight_smash9 = [130.000, hknight_smash10]
{
   ai_charge (MOVETYPE_WALK);
   ai_melee ();
}; //end of the function hknight_smash9

void () hknight_smash10 = [131.000, hknight_smash11]
{
   ai_charge (FALSE);
}; //end of the function hknight_smash10

void () hknight_smash11 = [132.000, hknight_run1]
{
   ai_charge (FALSE);
}; //end of the function hknight_smash11

void () hknight_watk1 = [133.000, hknight_watk2]
{
   ai_charge (FL_SWIM);
}; //end of the function hknight_watk1

void () hknight_watk2 = [134.000, hknight_watk3]
{
   ai_charge (FALSE);
}; //end of the function hknight_watk2

void () hknight_watk3 = [135.000, hknight_watk4]
{
   ai_charge (FALSE);
}; //end of the function hknight_watk3

void () hknight_watk4 = [136.000, hknight_watk5]
{
   ai_melee ();
}; //end of the function hknight_watk4

void () hknight_watk5 = [137.000, hknight_watk6]
{
   ai_melee ();
}; //end of the function hknight_watk5

void () hknight_watk6 = [138.000, hknight_watk7]
{
   ai_melee ();
}; //end of the function hknight_watk6

void () hknight_watk7 = [139.000, hknight_watk8]
{
   ai_charge (TRUE);
}; //end of the function hknight_watk7

void () hknight_watk8 = [140.000, hknight_watk9]
{
   ai_charge (MOVETYPE_STEP);
}; //end of the function hknight_watk8

void () hknight_watk9 = [141.000, hknight_watk10]
{
   ai_charge (MOVETYPE_FLY);
}; //end of the function hknight_watk9

void () hknight_watk10 = [142.000, hknight_watk11]
{
   ai_charge (MOVETYPE_WALK);
   ai_melee ();
}; //end of the function hknight_watk10

void () hknight_watk11 = [143.000, hknight_watk12]
{
   ai_charge (FL_SWIM);
   ai_melee ();
}; //end of the function hknight_watk11

void () hknight_watk12 = [144.000, hknight_watk13]
{
   ai_charge (FL_SWIM);
   ai_melee ();
}; //end of the function hknight_watk12

void () hknight_watk13 = [145.000, hknight_watk14]
{
   ai_charge (FALSE);
}; //end of the function hknight_watk13

void () hknight_watk14 = [146.000, hknight_watk15]
{
   ai_charge (FALSE);
}; //end of the function hknight_watk14

void () hknight_watk15 = [147.000, hknight_watk16]
{
   ai_charge (FALSE);
}; //end of the function hknight_watk15

void () hknight_watk16 = [148.000, hknight_watk17]
{
   ai_charge (TRUE);
}; //end of the function hknight_watk16

void () hknight_watk17 = [149.000, hknight_watk18]
{
   ai_charge (TRUE);
   ai_melee ();
}; //end of the function hknight_watk17

void () hknight_watk18 = [150.000, hknight_watk19]
{
   ai_charge (MOVETYPE_WALK);
   ai_melee ();
}; //end of the function hknight_watk18

void () hknight_watk19 = [151.000, hknight_watk20]
{
   ai_charge (MOVETYPE_STEP);
   ai_melee ();
}; //end of the function hknight_watk19

void () hknight_watk20 = [152.000, hknight_watk21]
{
   ai_charge (MOVETYPE_TOSS);
}; //end of the function hknight_watk20

void () hknight_watk21 = [153.000, hknight_watk22]
{
   ai_charge (MOVETYPE_PUSH);
}; //end of the function hknight_watk21

void () hknight_watk22 = [154.000, hknight_run1]
{
   ai_charge (MOVETYPE_WALK);
}; //end of the function hknight_watk22

void () hk_idle_sound =
{
   if ((random () < 0.200))
   {
      sound (self,CHAN_VOICE,"hknight/idle.wav",TRUE,ATTN_NORM);
   } //end if
}; //end of the function hk_idle_sound

void (entity attacker, float damage) hknight_pain =
{
   if ((self.pain_finished > time))
   {
      return ;
   } //end if
   sound (self,CHAN_VOICE,"hknight/pain1.wav",TRUE,ATTN_NORM);
   if (((time - self.pain_finished) > MOVETYPE_FLY))
   {
      hknight_pain1 ();
      self.pain_finished = (time + TRUE);
      return ;
   } //end if
   if (((random () * SVC_INTERMISSION) > damage))
   {
      return ;
   } //end if
   self.pain_finished = (time + TRUE);
   hknight_pain1 ();
}; //end of the function hknight_pain
float hknight_type /* = 0.000 */;

void () hknight_melee =
{
   hknight_type = (hknight_type + TRUE);
   sound (self,CHAN_WEAPON,"hknight/slash1.wav",TRUE,ATTN_NORM);
   if ((hknight_type == TRUE))
   {
      hknight_slice1 ();

   } //end if
   else
   {
      if ((hknight_type == FL_SWIM))
      {
         hknight_smash1 ();

      } //end if
      else
      {
         if ((hknight_type == MOVETYPE_WALK))
         {
            hknight_watk1 ();
            hknight_type = FALSE;
         } //end if
      } //end if
   } //end if
}; //end of the function hknight_melee

void () monster_hell_knight =
{
   if (deathmatch)
   {
      remove (self);
      return ;
   } //end if
   precache_model2 ("progs/hknight.mdl");
   precache_model2 ("progs/k_spike.mdl");
   precache_model2 ("progs/h_hellkn.mdl");
   precache_sound2 ("hknight/attack1.wav");
   precache_sound2 ("hknight/death1.wav");
   precache_sound2 ("hknight/pain1.wav");
   precache_sound2 ("hknight/sight1.wav");
   precache_sound ("hknight/hit.wav");
   precache_sound2 ("hknight/slash1.wav");
   precache_sound2 ("hknight/idle.wav");
   precache_sound2 ("hknight/grunt.wav");
   precache_sound ("knight/sword1.wav");
   precache_sound ("knight/sword2.wav");
   self.solid = SOLID_SLIDEBOX;
   self.movetype = MOVETYPE_STEP;
   setmodel (self,"progs/hknight.mdl");
   setsize (self,VEC_HULL_MIN,'16.000 16.000 40.000');
   self.health = 250.000;
   self.th_stand = hknight_stand1;
   self.th_walk = hknight_walk1;
   self.th_run = hknight_run1;
   self.th_melee = hknight_melee;
   self.th_missile = hknight_magicc1;
   self.th_pain = hknight_pain;
   self.th_die = hknight_die;
   walkmonster_start ();
}; //end of the function monster_hell_knight
