entity self;
entity other;
entity world;
float time /* = 0.000 */;
float frametime /* = 0.000 */;
float force_retouch /* = 0.000 */;
string mapname /* = "" */;
float deathmatch /* = 0.000 */;
float coop /* = 0.000 */;
float teamplay /* = 0.000 */;
float serverflags /* = 0.000 */;
float total_secrets /* = 0.000 */;
float total_monsters /* = 0.000 */;
float found_secrets /* = 0.000 */;
float killed_monsters /* = 0.000 */;
float parm1 /* = 0.000 */;
float parm2 /* = 0.000 */;
float parm3 /* = 0.000 */;
float parm4 /* = 0.000 */;
float parm5 /* = 0.000 */;
float parm6 /* = 0.000 */;
float parm7 /* = 0.000 */;
float parm8 /* = 0.000 */;
float parm9 /* = 0.000 */;
float parm10 /* = 0.000 */;
float parm11 /* = 0.000 */;
float parm12 /* = 0.000 */;
float parm13 /* = 0.000 */;
float parm14 /* = 0.000 */;
float parm15 /* = 0.000 */;
float parm16 /* = 0.000 */;
vector v_forward /* = '0.000 0.000 0.000' */;
vector v_up /* = '0.000 0.000 0.000' */;
vector v_right /* = '0.000 0.000 0.000' */;
float trace_allsolid /* = 0.000 */;
float trace_startsolid /* = 0.000 */;
float trace_fraction /* = 0.000 */;
vector trace_endpos /* = '0.000 0.000 0.000' */;
vector trace_plane_normal /* = '0.000 0.000 0.000' */;
float trace_plane_dist /* = 0.000 */;
entity trace_ent;
float trace_inopen /* = 0.000 */;
float trace_inwater /* = 0.000 */;
entity msg_entity;

void () main;

void () StartFrame;

void () PlayerPreThink;

void () PlayerPostThink;

void () ClientKill;

void () ClientConnect;

void () PutClientInServer;

void () ClientDisconnect;

void () SetNewParms;

void () SetChangeParms;
void end_sys_globals;
.float modelindex;
.vector absmin;
.vector absmax;
.float ltime;
.float movetype;
.float solid;
.vector origin;
.vector oldorigin;
.vector velocity;
.vector angles;
.vector avelocity;
.vector punchangle;
.string classname;
.string model;
.float frame;
.float skin;
.float effects;
.vector mins;
.vector maxs;
.vector size;
.void() touch;
.void() use;
.void() think;
.void() blocked;
.float nextthink;
.entity groundentity;
.float health;
.float frags;
.float weapon;
.string weaponmodel;
.float weaponframe;
.float currentammo;
.float ammo_shells;
.float ammo_nails;
.float ammo_rockets;
.float ammo_cells;
.float items;
.float takedamage;
.entity chain;
.float deadflag;
.vector view_ofs;
.float button0;
.float button1;
.float button2;
.float impulse;
.float fixangle;
.vector v_angle;
.float idealpitch;
.string netname;
.entity enemy;
.float flags;
.float colormap;
.float team;
.float max_health;
.float teleport_time;
.float armortype;
.float armorvalue;
.float waterlevel;
.float watertype;
.float ideal_yaw;
.float yaw_speed;
.entity aiment;
.entity goalentity;
.float spawnflags;
.string target;
.string targetname;
.float dmg_take;
.float dmg_save;
.entity dmg_inflictor;
.entity owner;
.vector movedir;
.string message;
.float sounds;
.string noise;
.string noise1;
.string noise2;
.string noise3;
void end_sys_fields;
.float old_waterlevel;
.float is_mandatory;
.float mandatory_until;
.entity bot_next;
.float bot;                 // Spec compatibility: 1 = bot entity
.float last_ai_state;
.float last_ai_state_time;  // FIX: Time when AI state last changed (hysteresis)
.float shadow_next_time;    // Shadow Puppets throttle timer
.float shadow_jump_time;    // Shadow Puppets jump hint (short-lived)
.float shadow_combat_time;  // Shadow Puppets combat hint expiry
.float shadow_combat_yaw;   // Shadow Puppets combat steer
.float shadow_combat_fire;  // Shadow Puppets combat fire hint
.float shadow_combat_weapon;// Shadow Puppets combat weapon hint
.float shadow_combat_next_time; // Shadow Puppets combat throttle timer
.float shadow_nav_debug_time;   // Shadow Puppets nav debug throttle
.float last_predict;        // Shared rollout throttle timestamp
.float shadow_beam;         // Per-bot beam override
.float shadow_depth;        // Per-bot depth override
float FALSE    = 0.000;
float TRUE    = 1.000;
float FL_FLY    = 1.000;
float FL_SWIM    = 2.000;
float FL_CLIENT    = 8.000;
float FL_INWATER    = 16.000;
float FL_MONSTER    = 32.000;
float FL_GODMODE    = 64.000;
float FL_NOTARGET    = 128.000;
float FL_ITEM    = 256.000;
float FL_ONGROUND    = 512.000;
float FL_PARTIALGROUND    = 1024.000;
float FL_WATERJUMP    = 2048.000;
float FL_JUMPRELEASED    = 4096.000;
float MOVETYPE_NONE    = 0.000;
float MOVETYPE_WALK    = 3.000;
float MOVETYPE_STEP    = 4.000;
float MOVETYPE_FLY    = 5.000;
float MOVETYPE_TOSS    = 6.000;
float MOVETYPE_PUSH    = 7.000;
float MOVETYPE_NOCLIP    = 8.000;
float MOVETYPE_FLYMISSILE    = 9.000;
float MOVETYPE_BOUNCE    = 10.000;
float MOVETYPE_BOUNCEMISSILE    = 11.000;
float SOLID_NOT    = 0.000;
float SOLID_TRIGGER    = 1.000;
float SOLID_BBOX    = 2.000;
float SOLID_SLIDEBOX    = 3.000;
float SOLID_BSP    = 4.000;
float RANGE_MELEE    = 0.000;
float RANGE_NEAR    = 1.000;
float RANGE_MID    = 2.000;
float RANGE_FAR    = 3.000;
float DEAD_NO    = 0.000;
float DEAD_DYING    = 1.000;
float DEAD_DEAD    = 2.000;
float DEAD_RESPAWNABLE    = 3.000;
float DAMAGE_NO    = 0.000;
float DAMAGE_YES    = 1.000;
float DAMAGE_AIM    = 2.000;
float IT_AXE    = 4096.000;
float IT_SHOTGUN    = 1.000;
float IT_SUPER_SHOTGUN    = 2.000;
float IT_NAILGUN    = 4.000;
float IT_SUPER_NAILGUN    = 8.000;
float IT_GRENADE_LAUNCHER    = 16.000;
float IT_ROCKET_LAUNCHER    = 32.000;
float IT_LIGHTNING    = 64.000;
float IT_EXTRA_WEAPON    = 128.000;
float IT_SHELLS    = 256.000;
float IT_NAILS    = 512.000;
float IT_ROCKETS    = 1024.000;
float IT_CELLS    = 2048.000;
float IT_ARMOR1    = 8192.000;
float IT_ARMOR2    = 16384.000;
float IT_ARMOR3    = 32768.000;
float IT_SUPERHEALTH    = 65536.000;
float IT_KEY1    = 131072.000;
float IT_KEY2    = 262144.000;
float IT_INVISIBILITY    = 524288.000;
float IT_INVULNERABILITY    = 1048576.000;
float IT_SUIT    = 2097152.000;
float IT_QUAD    = 4194304.000;
float CONTENT_EMPTY    = -1.000;
float CONTENT_SOLID    = -2.000;
float CONTENT_WATER    = -3.000;
float CONTENT_SLIME    = -4.000;
float CONTENT_LAVA    = -5.000;
float CONTENT_SKY    = -6.000;
float STATE_TOP    = 0.000;
float STATE_BOTTOM    = 1.000;
float STATE_UP    = 2.000;
float STATE_DOWN    = 3.000;
vector VEC_ORIGIN    = '0.000 0.000 0.000';
vector VEC_HULL_MIN    = '-16.000 -16.000 -24.000';
vector VEC_HULL_MAX    = '16.000 16.000 32.000';
vector VEC_HULL2_MIN    = '-32.000 -32.000 -24.000';
vector VEC_HULL2_MAX    = '32.000 32.000 64.000';
float SVC_TEMPENTITY    = 23.000;
float SVC_KILLEDMONSTER    = 27.000;
float SVC_FOUNDSECRET    = 28.000;
float SVC_INTERMISSION    = 30.000;
float SVC_FINALE    = 31.000;
float SVC_CDTRACK    = 32.000;
float SVC_SELLSCREEN    = 33.000;
float TE_SPIKE    = 0.000;
float TE_SUPERSPIKE    = 1.000;
float TE_GUNSHOT    = 2.000;
float TE_EXPLOSION    = 3.000;
float TE_TAREXPLOSION    = 4.000;
float TE_LIGHTNING1    = 5.000;
float TE_LIGHTNING2    = 6.000;
float TE_WIZSPIKE    = 7.000;
float TE_KNIGHTSPIKE    = 8.000;
float TE_LIGHTNING3    = 9.000;
float TE_LAVASPLASH    = 10.000;
float TE_TELEPORT    = 11.000;
float CHAN_AUTO    = 0.000;
float CHAN_WEAPON    = 1.000;
float CHAN_VOICE    = 2.000;
float CHAN_ITEM    = 3.000;
float CHAN_BODY    = 4.000;
float ATTN_NONE    = 0.000;
float ATTN_NORM    = 1.000;
float ATTN_IDLE    = 2.000;
float ATTN_STATIC    = 3.000;
float UPDATE_GENERAL    = 0.000;
float UPDATE_STATIC    = 1.000;
float UPDATE_BINARY    = 2.000;
float UPDATE_TEMP    = 3.000;
float EF_BRIGHTFIELD    = 1.000;
float EF_MUZZLEFLASH    = 2.000;
float EF_BRIGHTLIGHT    = 4.000;
float EF_DIMLIGHT    = 8.000;
float MSG_BROADCAST    = 0.000;
float MSG_ONE    = 1.000;
float MSG_ALL    = 2.000;
float MSG_INIT    = 3.000;
float movedist /* = 0.000 */;
float gameover /* = 0.000 */;
string string_null /* = "" */;
entity newmis;
entity activator;
entity damage_attacker;
float framecount /* = 0.000 */;
float skill /* = 0.000 */;
.string wad;
.string map;
.float worldtype;
.string killtarget;
.float light_lev;
.float style;
.void() th_stand;
.void() th_walk;
.void() th_run;
.void() th_missile;
.void() th_melee;
.void(entity attacker, float damage) th_pain;
.void() th_die;
.entity oldenemy;
.float speed;
.float lefty;
.float search_time;
.float attack_state;
float AS_STRAIGHT    = 1.000;
float AS_SLIDING    = 2.000;
float AS_MELEE    = 3.000;
float AS_MISSILE    = 4.000;
.float walkframe;
.float attack_finished;
.float pain_finished;

// Reaction time simulation
.entity pending_enemy;     // Enemy spotted, awaiting reaction
.float reaction_time;      // When pending_enemy was first seen
float () Bot_CheckReaction; // Forward declaration

// Knockback physics
.float knockback_time;     // When entity last received knockback
.float knockback_log_time; // Debounce: when knockback was last logged (prevents spam)

// Platform riding (DM2 lava fix)
.entity riding_platform;     // Platform entity bot is riding (func_train)
.float platform_wait_time;   // Time to wait for approaching platform

// Button solving (door puzzles)
.entity blocking_door;       // Door blocking our path
.entity target_button;       // Button to press/shoot
// Rocket jump oracle
.float last_rj;              // Last rocket jump time (cooldown)
.float rj_purpose;           // Purpose enum for RJ tuning (lava/vault/high/flat)
.float rj_probe_time;        // Cooldown for RJ probes

// Stuck detection
.float stuck_time;           // Time when bot became stuck (0 = not stuck)
.float stuck_count;          // Count of consecutive stuck recovery attempts
.vector obstruction_normal;  // Wall normal when stuck (for velocity decomposition)
// Feeler steering / breadcrumbs
.float feeler_mode_active;   // TRUE when using feeler navigation
.float feeler_start_time;    // When feeler mode was activated
.vector last_breadcrumb_pos; // Position of last dropped breadcrumb
.float last_breadcrumb_yaw;  // Yaw at last breadcrumb drop
// Spectral learning (phantom episodes)
.entity phantom;           // Active phantom owned by this bot
.entity phantom_target;    // Phantom's tracked target
.entity phantom_owner;     // Phantom's owner bot
.vector episode_start;     // Episode start position
.float episode_time;       // Episode end time
  .float last_sim_time;      // Last rollout time
  .float sim_maneuver;       // 0=walk,1=jump,2=tele,3=swim
  .vector tele_entry;        // Phantom-detected tele entry
  .vector tele_exit;         // Phantom-detected tele exit
  .float tele_chain_time;    // Time of last tele detect
  .float last_phantom;       // Cooldown for spawning a phantom
  // Vortex navmesh steering cache
  .vector vortex_path_goal;  // Cached goal for Vortex pathing
  .vector vortex_path_next;  // Next Vortex waypoint
  .float vortex_path_time;   // Last Vortex path compute time
// Mirage Minds (persona/entropy humanization)
.float mood_entropy;       // 0..1 persona variance
.vector mirage_goal;       // Short-lived bias goal
.float mirage_goal_time;   // Goal expiry time
.float mirage_yaw_bias;    // Temporary yaw bias (degrees)
.float mirage_yaw_time;    // Yaw bias expiry time
.float mirage_next_time;   // Throttle timer
.float mirage_hold_fire_time; // Feint: pause firing
.float mirage_pitch_bias;    // Temporary pitch bias (degrees)
.float mirage_glance_time;   // Glance-away expiry
.float blind_fire_miss;      // Consecutive missed blind fires
.vector blind_fire_spot;     // Last blind fire target
.float confidence_decay_time; // Last confidence decay tick
// Specter Gaze (cinematic spectator)
.vector old_vel;           // Velocity from prior think (for Specter prediction)
.vector replay_pos0;
.vector replay_pos1;
.vector replay_pos2;
.vector replay_pos3;
.vector replay_pos4;
.vector replay_pos5;
.vector replay_pos6;
.vector replay_pos7;
.vector replay_pos8;
.vector replay_pos9;
.float replay_next_time;   // Next time to sample replay buffer
.float specter_prev_movetype;
.float specter_prev_solid;
.float specter_prev_takedamage;
.float specter_prev_flags;
.vector specter_prev_origin;
.float specter_marked;
// Advanced movement mechanics
.float strafe_state;         // 0=None, 1=Left, 2=Right
.float strafe_timer;         // Rhythm keeper
.float last_dodge_time;      // Reflex cooldown
// Navigation learning & link types
float LINK_WALK     = 0;
float LINK_JUMP     = 1; // Requires jump
float LINK_DROP     = 2; // Safe to fall
float LINK_PLAT     = 3; // Requires waiting for/riding platform
float LINK_TELE     = 4; // Teleporter
float LINK_ROCKETJUMP = 5; // Requires rocket jump
float LINK_LADDER     = 6; // Vertical water/ladder logic
// Parallel fields to movetarget1..6
.float link_type1; .float link_usage1;
.float link_type2; .float link_usage2;
.float link_type3; .float link_usage3;
.float link_type4; .float link_usage4;
.float link_type5; .float link_usage5;
.float link_type6; .float link_usage6;
// Player/bot traversal tracking
.entity last_waypoint;       // The last node the player/bot was near
.float last_waypoint_time;   // When they were there
.vector jump_origin;         // Where the player started their jump
.float is_jumping;           // Flag to track air traversal
.float whiskers_allowed;     // Allow steering sensors for special links
// Graph weighting & scents
.float danger_cost;          // "Scent" of death here (increases path cost)
.float last_decay_time;      // For forgetting old paths
.float node_traffic;         // Total visits (heat map)

// --- DARWIN UPDATE: Adaptive Learning ---
// Node-level learning (BotPath entities)
.float glory_level;          // Kills happened here - attracts bots
.float last_event_time;      // For decaying danger/glory values

// Bot-level weapon confidence (-10 to +10)
// Positive = bot is confident, negative = bot avoids
.float confidence_rl;        // Rocket Launcher
.float confidence_lg;        // Lightning Gun
.float confidence_gl;        // Grenade Launcher
.float confidence_sg;        // Shotgun/Super Shotgun

// Rocket jump detection
.float last_rj_time;         // To debounce RJ detection

// --- SENSORY AWARENESS (Hearing) ---
.vector noise_target;        // Where the sound came from
.float  noise_time;          // When we heard it
.float  investigating;       // Are we currently checking out a noise?
.float  noise_priority;      // How important is this sound? (weapon > item)
.float  heard_sound_type;    // What did we hear?
.float  heard_sound_time;    // When?
.vector heard_sound_loc;     // Where?

// --- CURIOSITY (Solving) ---
.float  button_search_time;  // Cooldown for looking for buttons
// --- RIPPLE ORACLES (Causal interactables) ---
.float  ripple_probe_time;   // Cooldown for ripple probe scans

// Turn speed limiting (inspired by FrikBot mouse emulation)
.float last_yaw;             // Previous frame's yaw for delta calculation
.vector last_frame_origin;   // Debug: track per-frame movement for warp detection

// --- SMOOTH STEERING (Anti-Jitter) ---
// 3-frame circular buffer for angle smoothing (low-pass filter)
.float smooth_yaw_0;         // Buffer slot 0
.float smooth_yaw_1;         // Buffer slot 1
.float smooth_yaw_2;         // Buffer slot 2
.float smooth_idx;           // Current buffer index (0-2)

// Humanization: Aim spring dynamics (human-like tracking inertia)
.vector aim_velocity;         // Aim tracking velocity (spring model)
.vector last_aim_dir;         // Previous aim direction (spring state)
.float last_aim_time;         // Last time aim spring was updated

// Humanization: Strafe commitment
.float strafe_hold_until;     // Time until current strafe direction is committed

// Humanization: Combat entry stutter
.float combat_entry_time;     // When combat engagement started

// Humanization: Weapon switch fumble
.float weapon_switch_time;    // Fire delay after weapon switch
.float weapon_prev;           // Previous weapon (for detecting switches)

// Air control (inspired by Frogbot AIR_ACCELERATION)
float BOT_AIR_CONTROL = 1;   // Flag: allow limited air steering after knockback

// Object permanence (target memory)
.float last_seen_time;     // When enemy was last visible
float (entity targ) enemyvisible; // Forward declaration

// --- TACTICAL INTELLIGENCE (Mastermind Update) ---
// Predictive state estimation for "thinking" combat
.vector last_enemy_vel;      // Enemy velocity when we last saw them
.float  ambush_ready;        // Are we waiting in a trap?
.vector predict_pos;         // Calculated future position of enemy
.float  blind_fire_time;     // Cooldown for suppressive fire
.float  ambush_start_time;   // When we started the ambush (for timeout)
.float invincible_finished;
.float invisible_finished;
.float super_damage_finished;
.float radsuit_finished;
.float invincible_time;
.float invincible_sound;
.float invisible_time;
.float invisible_sound;
.float super_time;
.float super_sound;
.float rad_time;
.float fly_sound;
.float axhitme;
.float show_hostile;
.float jump_flag;
.float swim_flag;
.float air_finished;
.float bubble_count;
.string deathtype;
.string mdl;
.vector mangle;
.float t_length;
.float t_width;
.vector dest;
.vector dest1;
.vector dest2;
.float wait;
.float delay;
.entity trigger_field;
.string noise4;
.float pausetime;
.entity movetarget;
.float aflag;
.float dmg;
.float cnt;
.void() think1;
.vector finaldest;
.vector finalangle;
.float count;
.float lip;
.float state;
.vector pos1;
.vector pos2;
.float height;
.float waitmin;
.float waitmax;
.float distance;
.float volume;
void (vector ang) makevectors = #1; 
void (entity e, vector o) setorigin = #2; 
void (entity e, string m) setmodel = #3; 
void (entity e, vector min, vector max) setsize = #4; 
void () break = #6; 
float () random = #7; 
void (entity e, float chan, string samp, float vol, float atten) sound = #8; 
vector (vector v) normalize = #9; 
void (string e) error = #10; 
void (string e) objerror = #11; 
float (vector v) vlen = #12; 
float (vector v) vectoyaw = #13; 
entity () spawn = #14; 
void (entity e) remove = #15; 
void (vector v1, vector v2, float nomonsters, entity forent) traceline = #16; 
entity () checkclient = #17; 
entity (entity start, .string fld, string match) find = #18; 
string (string s) precache_sound = #19; 
string (string s) precache_model = #20; 
void (entity client, string s) stuffcmd = #21; 
entity (vector org, float rad) findradius = #22; 
void (string s) bprint = #23; 
void (entity client, string s) sprint = #24; 
void (string s) dprint = #25; 
string (float f) ftos = #26; 
string (vector v) vtos = #27; 
void () coredump = #28; 
void () traceon = #29; 
void () traceoff = #30; 
void (entity e) eprint = #31; 
float (float yaw, float dist) walkmove = #32; 
float () droptofloor = #34; 
void (float style, string value) lightstyle = #35; 
float (float v) rint = #36; 
float (float v) floor = #37; 
float (float v) ceil = #38; 
float (entity e) checkbottom = #40; 
float (vector v) pointcontents = #41; 
float (float f) fabs = #43; 
vector (entity e, float speed) aim = #44; 
float (string s) cvar = #45; 
void (string s) localcmd = #46; 
entity (entity e) nextent = #47; 
void (vector o, vector d, float color, float count) particle = #48; 
void () ChangeYaw = #49; 
vector (vector v) vectoangles = #51; 
void (float to, float f) WriteByte = #52; 
void (float to, float f) WriteChar = #53; 
void (float to, float f) WriteShort = #54; 
void (float to, float f) WriteLong = #55; 
void (float to, float f) WriteCoord = #56; 
void (float to, float f) WriteAngle = #57; 
void (float to, string s) WriteString = #58; 
void (float to, entity s) WriteEntity = #59; 
void (float step) movetogoal = #67; 
string (string s) precache_file = #68; 
void () makestatic = #69; 
void (string s) changelevel = #70; 
void (string var, string val) cvar_set = #72; 
void (entity client, string s) centerprint = #73; 
void (vector pos, string samp, float vol, float atten) ambientsound = #74; 
string (string s) precache_model2 = #75; 
string (string s) precache_sound2 = #76; 
string (string s) precache_file2 = #77; 
void (entity e) setspawnparms = #78; 
.vector camview;
