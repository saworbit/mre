float (float v) anglemod;

void () knight_atk1;

void () knight_runatk1;

void () ogre_smash1;

void () ogre_swing1;

void () sham_smash1;

void () sham_swingr1;

void () sham_swingl1;
float () DemonCheckAttack;

void (float side) Demon_Melee;

void (vector dest3) ChooseTurn;

void () ai_face;
float enemy_vis /* = 0.000 */;
float enemy_infront /* = 0.000 */;
float enemy_range /* = 0.000 */;
float enemy_yaw /* = 0.000 */;

void () knight_attack =
{
   local float len;

   len = vlen (((self.enemy.origin + self.enemy.view_ofs) - (self.origin + self.view_ofs)));
   if ((len < 80.000))
   {
      knight_atk1 ();

   } //end if
   else
   {
      knight_runatk1 ();
   } //end if
}; //end of the function knight_attack
float () CheckAttack =
{
   local vector spot1;
   local vector spot2;
   local entity targ;
   local float chance;

   targ = self.enemy;
   spot1 = (self.origin + self.view_ofs);
   spot2 = (targ.origin + targ.view_ofs);
   traceline (spot1,spot2,FALSE,self);
   if ((trace_ent != targ))
   {
      return (FALSE);
   } //end if
   if ((trace_inopen && trace_inwater))
   {
      return (FALSE);
   } //end if
   if ((enemy_range == RANGE_MELEE))
   {
      if (self.th_melee)
      {
         if ((self.classname == "monster_knight"))
         {
            knight_attack ();

         } //end if
         else
         {
            self.th_melee ();
         } //end if
         return (TRUE);
      } //end if
   } //end if
   if (!self.th_missile)
   {
      return (FALSE);
   } //end if
   if ((time < self.attack_finished))
   {
      return (FALSE);
   } //end if
   if ((enemy_range == RANGE_FAR))
   {
      return (FALSE);
   } //end if
   if ((enemy_range == RANGE_MELEE))
   {
      chance = 0.900;
      self.attack_finished = FALSE;

   } //end if
   else
   {
      if ((enemy_range == RANGE_NEAR))
      {
         if (self.th_melee)
         {
            chance = 0.200;

         } //end if
         else
         {
            chance = 0.400;
         } //end if

      } //end if
      else
      {
         if ((enemy_range == RANGE_MID))
         {
            if (self.th_melee)
            {
               chance = 0.050;

            } //end if
            else
            {
               chance = 0.100;
            } //end if

         } //end if
         else
         {
            chance = FALSE;
         } //end if
      } //end if
   } //end if
   if ((random () < chance))
   {
      self.th_missile ();
      SUB_AttackFinished ((FL_SWIM * random ()));
      return (TRUE);
   } //end if
   return (FALSE);
}; //end of the function CheckAttack

void () ai_face =
{
   self.ideal_yaw = vectoyaw ((self.enemy.origin - self.origin));
   ChangeYaw ();
}; //end of the function ai_face
float (entity targ) range;

void (float d) ai_charge =
{
   ai_face ();
   movetogoal (d);
}; //end of the function ai_charge

void () ai_charge_side =
{
   local vector dtemp;
   local float heading;

   self.ideal_yaw = vectoyaw ((self.enemy.origin - self.origin));
   ChangeYaw ();
   makevectors (self.angles);
   dtemp = (self.enemy.origin - (SVC_INTERMISSION * v_right));
   heading = vectoyaw ((dtemp - self.origin));
   walkmove (heading,KINDA_WANT);
}; //end of the function ai_charge_side

void () ai_melee =
{
   local vector delta;
   local float ldmg;

   if (!self.enemy)
   {
      return ;
   } //end if
   delta = (self.enemy.origin - self.origin);
   if ((vlen (delta) > 60.000))
   {
      return ;
   } //end if
   ldmg = (((random () + random ()) + random ()) * MOVETYPE_WALK);
   T_Damage (self.enemy,self,self,ldmg);
}; //end of the function ai_melee

void () ai_melee_side =
{
   local vector delta;
   local float ldmg;

   if (!self.enemy)
   {
      return ;
   } //end if
   ai_charge_side ();
   delta = (self.enemy.origin - self.origin);
   if ((vlen (delta) > 60.000))
   {
      return ;
   } //end if
   if (!CanDamage (self.enemy,self))
   {
      return ;
   } //end if
   ldmg = (((random () + random ()) + random ()) * MOVETYPE_WALK);
   T_Damage (self.enemy,self,self,ldmg);
}; //end of the function ai_melee_side
float () SoldierCheckAttack =
{
   local vector spot1;
   local vector spot2;
   local entity targ;
   local float chance;

   targ = self.enemy;
   spot1 = (self.origin + self.view_ofs);
   spot2 = (targ.origin + targ.view_ofs);
   traceline (spot1,spot2,FALSE,self);
   if ((trace_inopen && trace_inwater))
   {
      return (FALSE);
   } //end if
   if ((trace_ent != targ))
   {
      return (FALSE);
   } //end if
   if ((time < self.attack_finished))
   {
      return (FALSE);
   } //end if
   if ((enemy_range == RANGE_FAR))
   {
      return (FALSE);
   } //end if
   if ((enemy_range == RANGE_MELEE))
   {
      chance = 0.900;

   } //end if
   else
   {
      if ((enemy_range == RANGE_NEAR))
      {
         chance = 0.400;

      } //end if
      else
      {
         if ((enemy_range == RANGE_MID))
         {
            chance = 0.050;

         } //end if
         else
         {
            chance = FALSE;
         } //end if
      } //end if
   } //end if
   if ((random () < chance))
   {
      self.th_missile ();
      SUB_AttackFinished ((TRUE + random ()));
      if ((random () < 0.300))
      {
         self.lefty = !self.lefty;
      } //end if
      return (TRUE);
   } //end if
   return (FALSE);
}; //end of the function SoldierCheckAttack
float () ShamCheckAttack =
{
   local vector spot1;
   local vector spot2;
   local entity targ;
   local float chance;

   if ((enemy_range == RANGE_MELEE))
   {
      if (CanDamage (self.enemy,self))
      {
         self.attack_state = AS_MELEE;
         return (TRUE);
      } //end if
   } //end if
   if ((time < self.attack_finished))
   {
      return (FALSE);
   } //end if
   if (!enemy_vis)
   {
      return (FALSE);
   } //end if
   targ = self.enemy;
   spot1 = (self.origin + self.view_ofs);
   spot2 = (targ.origin + targ.view_ofs);
   if ((vlen ((spot1 - spot2)) > SEARCH_RADIUS))
   {
      return (FALSE);
   } //end if
   traceline (spot1,spot2,FALSE,self);
   if ((trace_inopen && trace_inwater))
   {
      return (FALSE);
   } //end if
   if ((trace_ent != targ))
   {
      return (FALSE);
   } //end if
   if ((enemy_range == RANGE_FAR))
   {
      return (FALSE);
   } //end if
   self.attack_state = AS_MISSILE;
   SUB_AttackFinished ((FL_SWIM + (FL_SWIM * random ())));
   return (TRUE);
}; //end of the function ShamCheckAttack
float () OgreCheckAttack =
{
   local vector spot1;
   local vector spot2;
   local entity targ;
   local float chance;

   if ((enemy_range == RANGE_MELEE))
   {
      if (CanDamage (self.enemy,self))
      {
         self.attack_state = AS_MELEE;
         return (TRUE);
      } //end if
   } //end if
   if ((time < self.attack_finished))
   {
      return (FALSE);
   } //end if
   if (!enemy_vis)
   {
      return (FALSE);
   } //end if
   targ = self.enemy;
   spot1 = (self.origin + self.view_ofs);
   spot2 = (targ.origin + targ.view_ofs);
   traceline (spot1,spot2,FALSE,self);
   if ((trace_inopen && trace_inwater))
   {
      return (FALSE);
   } //end if
   if ((trace_ent != targ))
   {
      return (FALSE);
   } //end if
   if ((time < self.attack_finished))
   {
      return (FALSE);
   } //end if
   if ((enemy_range == RANGE_FAR))
   {
      return (FALSE);

   } //end if
   else
   {
      if ((enemy_range == RANGE_NEAR))
      {
         chance = 0.100;

      } //end if
      else
      {
         if ((enemy_range == RANGE_MID))
         {
            chance = 0.050;

         } //end if
         else
         {
            chance = FALSE;
         } //end if
      } //end if
   } //end if
   self.attack_state = AS_MISSILE;
   SUB_AttackFinished ((TRUE + (FL_SWIM * random ())));
   return (TRUE);
}; //end of the function OgreCheckAttack
