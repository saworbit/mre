
void () ChangePitch;
.float ideal_pitch;
float current_pitch /* = 0.000 */;
float () CheckWaterLevel;
float (entity targ) visible;
float (entity targ) infront;

void () fuck_thud =
{
   local float tol;

   tol = -80.000;
   tol = ((tol * cvar ("sv_gravity")) / 800.000);
   if ((self.flags & FL_ONGROUND))
   {
      if ((self.velocity_z < tol))
      {
         self.flags = (self.flags - (self.flags & FL_ONGROUND));
         self.velocity_z = tol;
      } //end if
   } //end if
}; //end of the function fuck_thud

void () fix_watertype_bug =
{
   local entity bot;

   bot = find (world,classname,"dmbot");
   while (bot)
   {
      bot.watertype = MSG_BROADCAST;
      bot = find (bot,classname,"dmbot");
   } //end while
}; //end of the function fix_watertype_bug
entity () find_bot =
{
   local float dist;
   local float best_dist;
   local entity head;
   local entity selected;

   selected = world;
   best_dist = 9999.000;
   head = find (world,classname,"dmbot");
   while (head)
   {
      dist = vlen ((self.origin - head.origin));
      infront (head);
      visible (head);
      if (((visible (head) && visible (head)) && (dist < best_dist)))
      {
         best_dist = dist;
         selected = head;
      } //end if
      head = find (head,classname,"dmbot");
   } //end while
   return (selected);
}; //end of the function find_bot
entity () find_monster =
{
   local float dist;
   local float best_dist;
   local entity head;
   local entity selected;

   selected = world;
   best_dist = 9999.000;
   head = findradius (self.origin,SEARCH_RADIUS);
   while (head)
   {
      dist = vlen ((self.origin - head.origin));
      infront (head);
      visible (head);
      if ((((visible (head) && visible (head)) && (dist < best_dist)) && (head.flags & FL_MONSTER)))
      {
         best_dist = dist;
         selected = head;
      } //end if
      head = head.chain;
   } //end while
   return (selected);
}; //end of the function find_monster

void (entity me) set_bot_suicide_frame =
{
   if ((me.model != "progs/player.mdl"))
   {
      return ;
   } //end if
   me.frame = 60.000;
   me.solid = SOLID_NOT;
   me.movetype = MOVETYPE_TOSS;
   me.deadflag = DEAD_DEAD;
   me.nextthink = CONTENT_EMPTY;
}; //end of the function set_bot_suicide_frame
