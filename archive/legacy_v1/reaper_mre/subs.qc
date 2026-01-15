
void () SUB_Null =
{
}; //end of the function SUB_Null

void (entity attacker, float damage) SUB_NullPain =
{
}; //end of the function SUB_NullPain

void () SUB_Remove =
{
   remove (self);
}; //end of the function SUB_Remove

void () SetMovedir =
{
   if ((self.angles == '0.000 -1.000 0.000'))
   {
      self.movedir = '0.000 0.000 1.000';

   } //end if
   else
   {
      if ((self.angles == '0.000 -2.000 0.000'))
      {
         self.movedir = '0.000 0.000 -1.000';

      } //end if
      else
      {
         makevectors (self.angles);
         self.movedir = v_forward;
      } //end if
   } //end if
   self.angles = VEC_ORIGIN;
}; //end of the function SetMovedir

void () InitTrigger =
{
   if ((self.angles != VEC_ORIGIN))
   {
      SetMovedir ();
   } //end if
   self.solid = SOLID_TRIGGER;
   setmodel (self,self.model);
   self.movetype = MOVETYPE_NONE;
   self.modelindex = FALSE;
   self.model = "";
}; //end of the function InitTrigger

void (entity ent, vector tdest, float tspeed, void() func) SUB_CalcMoveEnt =
{
   local entity stemp;

   stemp = self;
   self = ent;
   SUB_CalcMove (tdest,tspeed,func);
   self = stemp;
}; //end of the function SUB_CalcMoveEnt

void (vector tdest, float tspeed, void() func) SUB_CalcMove =
{
   local vector vdestdelta;
   local float len;
   local float traveltime;

   if (!tspeed)
   {
      objerror ("No speed is defined!");
   } //end if
   self.think1 = func;
   self.finaldest = tdest;
   self.think = SUB_CalcMoveDone;
   if ((tdest == self.origin))
   {
      self.velocity = VEC_ORIGIN;
      self.nextthink = (self.ltime + 0.100);
      return ;
   } //end if
   vdestdelta = (tdest - self.origin);
   len = vlen (vdestdelta);
   traveltime = (len / tspeed);
   if ((traveltime < 0.100))
   {
      self.velocity = VEC_ORIGIN;
      self.nextthink = (self.ltime + 0.100);
      return ;
   } //end if
   self.nextthink = (self.ltime + traveltime);
   self.velocity = (vdestdelta * (TRUE / traveltime));
}; //end of the function SUB_CalcMove

void () SUB_CalcMoveDone =
{
   setorigin (self,self.finaldest);
   self.velocity = VEC_ORIGIN;
   self.nextthink = CONTENT_EMPTY;
   if (self.think1)
   {
      self.think1 ();
   } //end if
}; //end of the function SUB_CalcMoveDone

void (entity ent, vector destangle, float tspeed, void() func) SUB_CalcAngleMoveEnt =
{
   local entity stemp;

   stemp = self;
   self = ent;
   SUB_CalcAngleMove (destangle,tspeed,func);
   self = stemp;
}; //end of the function SUB_CalcAngleMoveEnt

void (vector destangle, float tspeed, void() func) SUB_CalcAngleMove =
{
   local vector destdelta;
   local float len;
   local float traveltime;

   if (!tspeed)
   {
      objerror ("No speed is defined!");
   } //end if
   destdelta = (destangle - self.angles);
   len = vlen (destdelta);
   traveltime = (len / tspeed);
   self.nextthink = (self.ltime + traveltime);
   self.avelocity = (destdelta * (TRUE / traveltime));
   self.think1 = func;
   self.finalangle = destangle;
   self.think = SUB_CalcAngleMoveDone;
}; //end of the function SUB_CalcAngleMove

void () SUB_CalcAngleMoveDone =
{
   self.angles = self.finalangle;
   self.avelocity = VEC_ORIGIN;
   self.nextthink = CONTENT_EMPTY;
   if (self.think1)
   {
      self.think1 ();
   } //end if
}; //end of the function SUB_CalcAngleMoveDone

void () DelayThink =
{
   activator = self.enemy;
   SUB_UseTargets ();
   remove (self);
}; //end of the function DelayThink

void () SUB_UseTargets =
{
   local entity t;
   local entity stemp;
   local entity otemp;
   local entity act;

   if (self.delay)
   {
      t = spawn ();
      t.classname = "DelayedUse";
      t.nextthink = (time + self.delay);
      t.think = DelayThink;
      t.enemy = activator;
      t.message = self.message;
      t.killtarget = self.killtarget;
      t.target = self.target;
      return ;
   } //end if
   if (((activator.classname == "player") && (self.message != "")))
   {
      centerprint (activator,self.message);
      if (!self.noise)
      {
         sound (activator,CHAN_VOICE,"misc/talk.wav",TRUE,ATTN_NORM);
      } //end if
   } //end if
   if (self.killtarget)
   {
      t = world;
      do
      {
         t = find (t,targetname,self.killtarget);
         if (!t)
         {
            return ;
         } //end if
         remove (t);
      } while (TRUE);
   } //end if
   if (self.target)
   {
      act = activator;
      t = world;
      do
      {
         t = find (t,targetname,self.target);
         if (!t)
         {
            return ;
         } //end if
         stemp = self;
         otemp = other;
         self = t;
         other = stemp;
         if ((self.use != SUB_Null))
         {
            if (self.use)
            {
               self.use ();
            } //end if
         } //end if
         self = stemp;
         other = otemp;
         activator = act;
      } while (TRUE);
   } //end if
}; //end of the function SUB_UseTargets

void (float normal) SUB_AttackFinished =
{
   self.cnt = FALSE;
   if ((skill != MOVETYPE_WALK))
   {
      self.attack_finished = (time + normal);
   } //end if
}; //end of the function SUB_AttackFinished

void (void() thinkst) SUB_CheckRefire =
{
   if ((skill != MOVETYPE_WALK))
   {
      return ;
   } //end if
   if ((self.cnt == TRUE))
   {
      return ;
   } //end if
   if (!visible (self.enemy))
   {
      return ;
   } //end if
   self.cnt = TRUE;
   self.think = thinkst;
}; //end of the function SUB_CheckRefire
