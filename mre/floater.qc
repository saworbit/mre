

/*
==============================================================================
FLOATER.QC by Alan Kivlin &lte-mail: alan.kivin@cyberiacafe.co.uk>

Description of the Modification
-------------------------------

Routines for making an entity float to the surface of water.

A floater will sink depending on its falling velocity, it will then float
to the surface where it will bob up and down for around 30 seconds and 
finally it will sink until it hits the ground.

Sometimes you'll find a floater will retain its avelocity, making it 
spin around while bobbing - I didn't code for anything like this. Also an 
entity will sometimes keep it's velocity_x or velocity_y.

--------------------------------------

(C) 1997 Alan Kivlin.

Authors MAY use this modification as a basis for other
publicly available work.
^^^^^^^^
==============================================================================
*/

// last frame processed
float fFloaterLastFrame;

// "floating" when the entity is a floater
.string sFloating;

// origin offset when checking for water
.float fOriginOffset;

// floater state flags
float FS_FALLING   = 1;
float FS_SURFACING = 2;
float FS_FLOATING  = 3;
float FS_SINKING   = 4;

// maximum number of active floaters
float FLOATER_MAXIMUM = 32;

//----------------------------------------------------------------------------

// returns TRUE if in WATER, SLIME or LAVA
float( entity ent ) floaterInWater;

// makes the entity float

void( entity ent, float offset ) floaterEnable;

// stops the entity from floating
void( entity ent ) floaterDisable;

// controls the floating of the floaters
void() floaterPreThink;

//----------------------------------------------------------------------------

/*
==============================================================================
floaterInWater

returns TRUE if in WATER, SLIME or LAVA
==============================================================================
*/

float( entity ent ) floaterInWater =
{
   local vector where;
   local float contents;

   where = ent.origin;
   where_z = where_z + ent.fOriginOffset;

   contents = pointcontents( where );

   if( contents >= -5 && contents <= -3 )
      // is in WATER (-3), SLIME (-4) or LAVA (-5)
      return TRUE;

   return FALSE;
};

/*
==============================================================================
floaterEnable

makes the entity float
==============================================================================
*/

void( entity ent, float offset ) floaterEnable =
{
   local float floatercount;
   local entity floater, oldest;

   oldest = floater = find( world, sFloating, "floating" );

   while( floater )
   {
      floatercount = floatercount + 1;

      if( floater.ltime <= oldest.ltime )
         oldest = floater;

      floater = find( floater, sFloating, "floating" );
   }

   if( floatercount == FLOATER_MAXIMUM )
      floaterDisable( oldest );

   ent.sFloating = "floating";
   ent.state = FS_FALLING;
   ent.speed = 0;

   // save origin offset, used when checking for water
   ent.fOriginOffset = offset;

   // time to start sinking
   ent.ltime = time + 30 + random() * 5;

   if( floaterInWater( ent ) )
   {
      // MOVETYPE_TOSS in water
      ent.movetype = MOVETYPE_TOSS;

      // set inwater flag
      ent.flags = ent.flags | FL_INWATER;
   }
   else
   {
      // MOVETYPE_BOUNCE out of water
      ent.movetype = MOVETYPE_BOUNCE;

      // reset inwater flag
      ent.flags = ent.flags - ( ent.flags & FL_INWATER );
   }
};

/*
==============================================================================
floaterDisable

stops the entity from floating
==============================================================================
*/

void( entity ent ) floaterDisable =
{
   // stop floating
   ent.sFloating = string_null;
};

/*
==============================================================================
floaterPreThink

controls the floating of the floaters
==============================================================================
*/

void() floaterPreThink =
{
   local entity ent;

   if( fFloaterLastFrame == framecount )
      // already processed this frame
      return;

   // set last frame so we don't process a frame more than once
   fFloaterLastFrame = framecount;

   ent = find( world, sFloating, "floating" );

   while( ent )
   {
      if( ( ent.state == FS_FLOATING ) && ( ent.flags & FL_ONGROUND ) )
      {
         // if we are on the ground then we should be falling, this occurs
         // when the floater is on a moving platform that has left the water
         ent.state = FS_FALLING;
         ent.speed = 0;
      }

      if( ent.state == FS_FLOATING )
      {
         if( ent.speed > 0 )
            // floating up
            ent.velocity_z = ent.speed * ( 1 + frametime * 8 );
         else
            // floating down
            ent.velocity_z = 0;
      }
      else if( ent.state == FS_SURFACING )
      {
         if( ent.velocity_z > 0 )
            // keep surfacing to a constant speed
            ent.velocity_z = ent.speed;
         else if( floaterInWater( ent ) )
            // can't reach the surface so make it sink
            ent.state = FS_SINKING;
      }
      else if( ent.state == FS_SINKING )
         if( ent.flags & FL_ONGROUND )
            // sunk to the bottom
            floaterDisable( ent );
         else
            // sink slowly
            ent.velocity_z = 0;

      if( floaterInWater( ent ) )
      {
         if( ! ( ent.flags & FL_INWATER ) )
         {
            // MOVETYPE_TOSS in water
            ent.movetype = MOVETYPE_TOSS;

            // set inwater flag
            ent.flags = ent.flags | FL_INWATER;

            if( ent.state == FS_FLOATING )
               // start floating up
               ent.speed = 72 + random() * 16;
            else if( ent.state == FS_FALLING )
               // play enter water sound
               sound( ent, CHAN_BODY, "player/h2ojump.wav", 1, ATTN_NORM );
         }

         if( ent.state == FS_FALLING )
         {
            if( ! ent.speed )
            {
               if( ent.velocity_z < 0 )
                  // set maximum falling speed before floater should surface
                  ent.speed = ent.velocity_z * 8;
            }

            if( ( ent.velocity_z <= ent.speed ) || ( ent.flags & FL_ONGROUND ) )
            {
               // start surfacing
               ent.state = FS_SURFACING;
               ent.speed = 128 + random() * 32;

               ent.velocity_z = ent.speed;
               ent.velocity_x = 0;
               ent.velocity_y = 0;
            }
         }
      }
      else
      {
         if( ( ent.flags & FL_INWATER ) )
         {
            // MOVETYPE_BOUNCE out of water
            ent.movetype = MOVETYPE_BOUNCE;

            // reset inwater flag
            ent.flags = ent.flags - FL_INWATER;

            if( ent.state == FS_FLOATING )
               // start floating down
               ent.speed = 0;
            else if( ent.state == FS_SINKING )
            {
               // floater has sunk out of the water
               ent.state = FS_FALLING;
               ent.speed = 0;
            }

            if( ent.state == FS_FALLING )
               // play leave water sound
               sound( ent, CHAN_BODY, "player/h2ojump.wav", 1, ATTN_NORM );
         }

         if( ent.state == FS_SURFACING )
         {
            // once its surfaced, make it jump out
            ent.velocity_z = ent.speed * 1.5;

            // start floating down
            ent.state = FS_FLOATING;
            ent.speed = 0;
         }
      }

      if( ent.ltime <= time )
      {
         if( ent.flags & FL_INWATER )
         {
            // floater has taken in too much water so sink to the bottom
            ent.state = FS_SINKING;
            ent.ltime = time + 10 + random() * 5;
         }
      }

      // stop quake from making a splash sound
      // ent.watertype = 0;

      // physics movement won't happen otherwise
      ent.flags = ent.flags - ( ent.flags & FL_ONGROUND );

      ent = find( ent, sFloating, "floating" );
   }
};