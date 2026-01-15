
void () monster_boss = {

   remove (self);
   return ;

};
entity le1;
entity le2;
float lightning_end /* = 0.000 */;

void () lightning_fire = {

   local vector p1;
   local vector p2;

   if ( (time >= lightning_end) ) {

      self = le1;
      door_go_down ();
      self = le2;
      door_go_down ();
      return ;

   }
   p1 = ((le1.mins + le1.maxs) * 0.500);
   p1_z = (le1.absmin_z - FL_INWATER);
   p2 = ((le2.mins + le2.maxs) * 0.500);
   p2_z = (le2.absmin_z - FL_INWATER);
   p2 = (p2 - (normalize ((p2 - p1)) * MUST_HAVE));
   self.nextthink = (time + 0.100);
   self.think = lightning_fire;
   WriteByte (MSG_ALL,SVC_TEMPENTITY);
   WriteByte (MSG_ALL,TE_LIGHTNING3);
   WriteEntity (MSG_ALL,world);
   WriteCoord (MSG_ALL,p1_x);
   WriteCoord (MSG_ALL,p1_y);
   WriteCoord (MSG_ALL,p1_z);
   WriteCoord (MSG_ALL,p2_x);
   WriteCoord (MSG_ALL,p2_y);
   WriteCoord (MSG_ALL,p2_z);

};

void () lightning_use = {

   if ( (lightning_end >= (time + TRUE)) ) {

      return ;

   }
   le1 = find (world,target,"lightning");
   le2 = find (le1,target,"lightning");
   if ( (!le1 || !le2) ) {

      dprint ("missing lightning targets\n");
      return ;

   }
   if ( ((((le1.state != STATE_TOP) && (le1.state != STATE_BOTTOM)) || ((le2.state != STATE_TOP) && (le2.state != STATE_BOTTOM))) || (le1.state != le2.state)) ) {

      return ;

   }
   le1.nextthink = CONTENT_EMPTY;
   le2.nextthink = CONTENT_EMPTY;
   lightning_end = (time + TRUE);
   sound (self,CHAN_VOICE,"misc/power.wav",TRUE,ATTN_NORM);
   lightning_fire ();

};

void () event_lightning = {

   self.use = lightning_use;

};
