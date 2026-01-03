.float watertype2;
float last_time_left /* = 0.000 */;
.float fClientNo;
float fActiveClients /* = 0.000 */;
float fMaxClients /* = 0.000 */;
entity bodyque_head;
.float LoggedIn;

void () setWatcherMode;

void (entity bot) bot_triggered;

void (entity killer, entity killed) countkill;

void () initscore;

void (entity ply, float n) removeTeamBots;

void (entity ply, float n) addTeamBots;

void (entity e, float newskin) skinChange;

void () NewCarriedPath;

void () initBotLevel;
float () CheckDropPath;

void () DropBotPath;

void () DumpWaypoints;

float () BotFoundTarget;

void (entity en2) secondEnemy;

void () endEnemy;

void () bot_touched;

void () enemy_touched;

void (entity node, entity targ, float len, entity item) cacheRoute;

void () bot_toucheditem;

void (entity a, entity b) addTarget;
vector () botaim;

void () botImpulseCommand;

void () setBotGravity;

void (vector tdest, float tspeed, void() func) SUB_CalcMove;

void (entity ent, vector tdest, float tspeed, void() func) SUB_CalcMoveEnt;

void (vector destangle, float tspeed, void() func) SUB_CalcAngleMove;

void () SUB_CalcMoveDone;

void () SUB_CalcAngleMoveDone;

void () SUB_Null;

void () SUB_UseTargets;

void () SUB_Remove;

void (entity targ, entity inflictor, entity attacker, float damage) T_Damage;
float (entity e, float healamount, float ignore) T_Heal;
float (entity targ, entity inflictor) CanDamage;
.float(entity e) th_weight;
.float(entity node, float len, entity item) th_cache;
.void() th_update;
.float istrigger;
.float healtype;
.float playerkills;
.float playerdeaths;
.float botkills;
.float fShirt;
.float fPants;
.float botdeaths;
.float suicides;
// Cached enemy velocity used for predictive chase when LOS drops.
.vector last_enemy_vel;
.vector lastseenpos;
.float enemyrun;
// Cooldown for route blockage checks to avoid constant replans.
.float reroute_time;
// Tracks target velocity for route replans after sharp movement shifts.
.vector route_vel_last;
// Ring buffer for recent enemy velocities (pattern-aware aiming).
.vector vel_hist0;
.vector vel_hist1;
.vector vel_hist2;
.float vel_hist_idx;
// Tracks enemy speed patterns for goal interception.
.vector enemy_vel_pat0;
.vector enemy_vel_pat1;
// Marks when bots should bias goals toward intercepting fast movers.
.float intercept_flag;
// Tracks consecutive kills and deaths for adaptive difficulty tuning.
.float kill_streak;
.float death_streak;
// Tracks taunt momentum (usually mirrors kill streaks).
.float taunt_streak;
.float goody_time;
.float strafetime;
.float strafeonly;
.void() strafethink;
.float strafeyaw;
.float strafedist;
// Tracks when the bot last made progress so we can detect stuck loops.
.float stuck_time;
// Retry counter for stuck rotation logic (0-7 cycle, triggers angle rotation and cache clear).
.float stuck_count;
// Rocket jump cooldown timer: prevents spam RJ (2s delay between attempts).
.float rj_cooldown;
// Button shoot wait timer: tracks when bot last shot a button/shootable to pause for door opening.
.float button_wait_time;
// Weapon-aware evasion mode: 0 = none, 1 = zigzag (rockets), 2 = jump (lightning).
.float evade_mode;
// Ring buffer for the bot's own recent velocity (dodging pattern control).
.vector self_vel_hist0;
.vector self_vel_hist1;
.vector self_vel_hist2;
.float self_vel_hist_idx;
// Adrenaline focus level (0.0-1.0) used to tighten aim and speed reactions.
.float adrenaline;
// Skill-based memory flag for pre-cached route knowledge at spawn.
.float has_memory;
// Ring buffer for jump velocity pattern smoothing (prevents erratic air movement).
.vector jump_vel_pat0;
.vector jump_vel_pat1;
.entity movetarget2;
.entity movetarget3;
.entity movetarget4;
.entity movetarget5;
.entity movetarget6;
.entity lastbot;
// Tracks whether the bot is comfortably leading and should play denial-first.
.float lead_score;
// Flags that current goal requires special movement (rocket jump for high items).
.float check_climb;
// Remembers the last breadcrumb node dropped for smart spacing optimization.
.entity last_dropped_node;
.float lasttime;
.float pather;
.float pathtype;
// Marks paths tied to contested powerups so bots can try denial/intercepts.
.float deny_flag;
// Marks path nodes sitting on moving platforms (func_plat/func_train) for elevator logic.
.float is_platform_node;
// Semantic map learning: danger scent (how many bots died here - avoid).
.float danger_scent;
// Semantic map learning: glory score (how many kills happened here - attract).
.float glory_score;
// Semantic map learning: last update time for scent fading.
.float scent_time;
// Traffic heatmap: how many times anyone has touched this node (main street vs back alley).
.float traffic_score;
// Action Breadcrumbs: what the player did at this node (0=walk, 1=jump, 2=wait).
.float action_flag;
// Human Reaction Time: timestamp when bot can start aiming/firing after acquiring new enemy.
.float reaction_finished;
// Nemesis System: tracks who killed this bot for revenge seeking.
.entity nemesis;
.float nemesis_time;
.float skil;
.float rocketlen;
.entity rocketcache;
.float lightninglen;
.entity lightningcache;
.float armorlen;
.entity armorcache;
.float pendinglen;
.entity pendingcache;
.float naillen;
.entity nailcache;
.float grenadelen;
.entity grenadecache;
.float poweruplen;
.entity powerupcache;
.float enemylen;
.entity enemycache;
.float endpoint;
.string teamname;
float NORMALSCORE    = 1.000;
float MYSCORE    = 2.000;
float MUST_HAVE    = 100.000;
float WANT    = 35.000;
float KINDA_WANT    = 20.000;
float DONT_WANT    = 0.000;
float CANTURN    = 1.000;
float NOTURN    = 2.000;
float SEARCH_RADIUS    = 600.000;
float LOOPTIME    = 20.000;
float MAXPATHERS    = 16.000;
float DROPPED    = 2.000;
float CARRIED    = 1.000;
float NEVERTARGET    = 3.000;
float REGULARTARGET    = 0.000;
float TELEPORT    = 4.000;
float BOTS    = 240.000;
float TEAMBOTS    = 3840.000;
float RESTRICT    = 4096.000;
float SUPERRESTRICT    = 8192.000;
float TEAMFLAG    = 16384.000;
float INITLEVEL    = 32768.000;
float DEDICATED    = 4194304.000;
float LOCAL_TIME    = 7.000;
float STRAFE_DIR    = 16.000;
float FAR_SEEK    = 32.000;
float WATERUPDOWN    = 64.000;
float NODROP    = 128.000;
float RUNAWAY    = 256.000;
float GETGOODY    = 512.000;
float ONTRAIN    = 1024.000;
float MULTIENEMY    = 2048.000;
// Runtime bot globals: keep them uninitialized so FTEQCC treats them as mutable,
// otherwise zero initializers can turn them into consts and break updates at runtime.
float VERBOSEBOT;
float BOTSPEED;
float NUMBOTS;
float GRAVITY;
float MAXJUMP;
float INVGRENADELEVELDIST;
float GRENADEMAXHEIGHT;
float LEVELJUMPTIME;
float NUMPATHS;
float NUMGIBS;
float NUMPATHERS;
float SKINSMODE;
float RECURSEDEPTH;
vector REBOUNDSPOT;
float REBOUND;
float TELEFRAGFLAG;
entity NOISEQUEUE;
float HELPING;
float NAMEBOTS;
// Auto waypoint dump: tracks when to dump waypoints to console (0 = disabled, >0 = time of next dump)
float WAYPOINT_DUMP_TIME;

void (entity noisemaker, entity noiseobject) signalnoise;
float (entity e) hearnoise;
entity () noisetarget;
float (entity targ) Spotvisible;
float (entity targ) Platvisible;
float (vector spot) dropline;

void () secret_touch;
float (entity e) doorweight =
{
   local float weight;

   weight = KINDA_WANT;
   if (e.owner.targetname)
   {
      weight = DONT_WANT;

   } //end if
   else
   {
      if ((e.touch == secret_touch))
      {
         weight = KINDA_WANT;

      } //end if
      else
      {
         if ((e.state == STATE_TOP))
         {
            weight = DONT_WANT;

         } //end if
         else
         {
            if ((e.state == STATE_UP))
            {
               weight = KINDA_WANT;
            } //end if
         } //end if
      } //end if
   } //end if
   if (!Spotvisible (e))
   {
      weight = DONT_WANT;
   } //end if
   return (weight);
}; //end of the function doorweight
float (entity e) buttonweight =
{
   local float weight;

   weight = DONT_WANT;
   if ((e.state == STATE_BOTTOM))
   {
      if (Spotvisible (e))
      {
         weight = (KINDA_WANT + TRUE);
      } //end if
   } //end if
   return (weight);
}; //end of the function buttonweight
float (entity e) platweight =
{
   local float weight;

   weight = KINDA_WANT;
   if (!Platvisible (e))
   {
      if (!Spotvisible (e))
      {
         weight = DONT_WANT;
      } //end if
   } //end if
   return (weight);
}; //end of the function platweight
float (entity e) trigpushweight =
{
   local float weight;
   local vector spot;
   local vector org;

   weight = DONT_WANT;
   org = ((e.absmin + e.absmax) * 0.500);
   org_z = (e.absmin_z + TRUE);
   spot = org;
   spot_z = self.origin_z;
   traceline (self.origin,spot,TRUE,self);
   if ((trace_fraction == TRUE))
   {
      traceline (spot,org,TRUE,self);
      if ((trace_fraction == TRUE))
      {
         spot_z = dropline (org);
         if ((self.absmin_z > spot_z))
         {
            spot_z = self.absmin_z;
         } //end if
         if ((org_z < (((self.maxs_z - self.mins_z) + spot_z) + MAXJUMP)))
         {
            weight = KINDA_WANT;
         } //end if
      } //end if
   } //end if
   return (weight);
}; //end of the function trigpushweight
float (entity e) triggerweight =
{
   local float weight;
   local float rnd;

   weight = (KINDA_WANT - FL_SWIM);
   rnd = random ();
   if ((rnd < 0.250))
   {
      weight = WANT;
   } //end if
   if (!Spotvisible (e))
   {
      weight = DONT_WANT;
   } //end if
   return (weight);
}; //end of the function triggerweight
float (entity e) backpackweight =
{
   local float lnd;
   local float weight;

   weight = WANT;
   lnd = pointcontents ((e.absmin + '0.000 0.000 1.000'));
   if ((e.items & (IT_ROCKET_LAUNCHER + IT_LIGHTNING)))
   {
      weight = (MUST_HAVE - TRUE);
   } //end if
   if (((lnd == CONTENT_LAVA) || (lnd == CONTENT_SLIME)))
   {
      weight = DONT_WANT;
   } //end if
   return (weight);
}; //end of the function backpackweight
float (entity e) healthweight =
{
   local float weight;

   weight = WANT;
   if ((self.health < 60.000))
   {
      weight = (MUST_HAVE - TRUE);

   } //end if
   else
   {
      if ((e.healtype == FL_SWIM))
      {
         weight = MUST_HAVE;

      } //end if
      else
      {
         if ((self.health > 99.000))
         {
            weight = DONT_WANT;
         } //end if
      } //end if
   } //end if
   return (weight);
}; //end of the function healthweight
float (entity e) nailweight =
{
   local float weight;

   weight = (WANT - TRUE);
   if ((self.ammo_nails > 199.000))
   {
      weight = DONT_WANT;

   } //end if
   else
   {
      if ((self.ammo_nails > 120.000))
      {
         weight = (KINDA_WANT - FL_SWIM);
      } //end if
   } //end if
   return (weight);
}; //end of the function nailweight
float (entity e) shellweight =
{
   local float weight;

   weight = (WANT - TRUE);
   if ((self.ammo_shells > 99.000))
   {
      weight = DONT_WANT;

   } //end if
   else
   {
      if ((self.ammo_shells > 50.000))
      {
         weight = (KINDA_WANT - FL_SWIM);
      } //end if
   } //end if
   return (weight);
}; //end of the function shellweight
float (entity e) cellweight =
{
   local float weight;

   weight = WANT;
   if ((self.ammo_cells > 99.000))
   {
      weight = DONT_WANT;
   } //end if
   return (weight);
}; //end of the function cellweight
float (entity e) rocketweight =
{
   local float weight;

   weight = WANT;
   if ((self.ammo_rockets > 99.000))
   {
      weight = DONT_WANT;
   } //end if
   return (weight);
}; //end of the function rocketweight
float (entity e) rlauncherweight =
{
   local float weight;

   weight = (WANT + FL_SWIM);
   if (!(self.items & IT_ROCKET_LAUNCHER))
   {
      weight = MUST_HAVE;
   } //end if
   return (weight);
}; //end of the function rlauncherweight
float (entity e) lightningweight =
{
   local float weight;

   weight = (WANT + FL_SWIM);
   if (!(self.items & IT_LIGHTNING))
   {
      weight = MUST_HAVE;
   } //end if
   return (weight);
}; //end of the function lightningweight
float (entity e) glauncherweight =
{
   local float weight;

   weight = (WANT + TRUE);
   if (!(self.items & IT_GRENADE_LAUNCHER))
   {
      weight = (MUST_HAVE - TRUE);
   } //end if
   return (weight);
}; //end of the function glauncherweight
float (entity e) nailgunweight =
{
   return (WANT);
}; //end of the function nailgunweight
float (entity e) supernailweight =
{
   local float weight;

   weight = (WANT + TRUE);
   if (!(self.items & IT_SUPER_NAILGUN))
   {
      weight = (MUST_HAVE - TRUE);
   } //end if
   return (weight);
}; //end of the function supernailweight
float (entity e) ssgweight =
{
   return (WANT);
}; //end of the function ssgweight
float (entity e) armorweight =
{
   local float weight;

   weight = (e.armorvalue - self.armorvalue);
   return (weight);
}; //end of the function armorweight
float (entity e) artifactweight =
{
   local float weight;

   weight = (MUST_HAVE + FL_SWIM);
   if ((e.classname == "item_artifact_envirosuit"))
   {
      weight = WANT;
   } //end if
   return (weight);
}; //end of the function artifactweight
float (entity node, float len, entity item) cacherocket =
{
   if ((node.rocketlen > FALSE))
   {
      if ((len >= node.rocketlen))
      {
         return (FALSE);
      } //end if
   } //end if
   node.rocketlen = len;
   node.rocketcache = item;
   return (TRUE);
}; //end of the function cacherocket
float (entity node, float len, entity item) cachelightning =
{
   if ((node.lightninglen > FALSE))
   {
      if ((len >= node.lightninglen))
      {
         return (FALSE);
      } //end if
   } //end if
   node.lightninglen = len;
   node.lightningcache = item;
   return (TRUE);
}; //end of the function cachelightning
float (entity node, float len, entity item) cachearmor =
{
   if ((node.armorlen > FALSE))
   {
      if ((len >= node.armorlen))
      {
         return (FALSE);
      } //end if
   } //end if
   node.armorlen = len;
   node.armorcache = item;
   return (TRUE);
}; //end of the function cachearmor
float (entity node, float len, entity item) cachenail =
{
   if ((node.naillen > FALSE))
   {
      if ((len >= node.naillen))
      {
         return (FALSE);
      } //end if
   } //end if
   node.naillen = len;
   node.nailcache = item;
   return (TRUE);
}; //end of the function cachenail
float (entity node, float len, entity item) cachegrenade =
{
   if ((node.grenadelen > FALSE))
   {
      if ((len >= node.grenadelen))
      {
         return (FALSE);
      } //end if
   } //end if
   node.grenadelen = len;
   node.grenadecache = item;
   return (TRUE);
}; //end of the function cachegrenade
float (entity node, float len, entity item) cachepowerup =
{
   if ((node.poweruplen > FALSE))
   {
      if ((len >= node.poweruplen))
      {
         return (FALSE);
      } //end if
   } //end if
   node.poweruplen = len;
   node.powerupcache = item;
   return (TRUE);
}; //end of the function cachepowerup
float (entity node, float len, entity item) cacheenemy =
{
   if ((node.enemylen > FALSE))
   {
      if ((len >= node.enemylen))
      {
         return (FALSE);
      } //end if
   } //end if
   node.enemylen = len;
   node.enemycache = item;
   return (TRUE);
}; //end of the function cacheenemy

void () updaterocket =
{
   self.rocketcache = self.pendingcache;
   self.rocketlen = self.pendinglen;
}; //end of the function updaterocket

void () updatelightning =
{
   self.lightningcache = self.pendingcache;
   self.lightninglen = self.pendinglen;
}; //end of the function updatelightning

void () updatearmor =
{
   self.armorcache = self.pendingcache;
   self.armorlen = self.pendinglen;
}; //end of the function updatearmor

void () updatepowerup =
{
   self.powerupcache = self.pendingcache;
   self.poweruplen = self.pendinglen;
}; //end of the function updatepowerup

void () updatenail =
{
   self.nailcache = self.pendingcache;
   self.naillen = self.pendinglen;
}; //end of the function updatenail

void () updategrenade =
{
   self.grenadecache = self.pendingcache;
   self.grenadelen = self.pendinglen;
}; //end of the function updategrenade
