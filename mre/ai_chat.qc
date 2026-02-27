// =============================================================================
// AI_CHAT.QC -- Intelligence Pass #13: Chat/Taunt System + Item Timer Helpers
//
// Gives bots contextual chat messages and major item respawn tracking.
// Chat is probability-gated, personality-scaled, and cooldown-throttled.
// =============================================================================

// =============================================================================
// CHAT SYSTEM
// =============================================================================

// Pick a random chat message for the given event type and skill level.
// Returns the chosen string via bprint (QuakeC has no string variables).
// self = the bot that is chatting.
void (entity bot, float chat_event) BotChat = {

// Cooldown check -- min 4s between messages per bot
   if ( time < bot.chat_cooldown ) return;

   // Probability gate per event type
   local float chance;
   if ( chat_event == CHAT_KILL )       chance = 0.30;
   else if ( chat_event == CHAT_DEATH ) chance = 0.15;
   else if ( chat_event == CHAT_POWERUP ) chance = 0.25;
   else if ( chat_event == CHAT_ESCAPE ) chance = 0.10;
   else if ( chat_event == CHAT_SPAWN )  chance = 0.05;
   else return;

   // Personality and mood modulation
   chance = chance * bot.personality_chat;
   // High entropy (unfocused/chaotic) = chattier
   if ( bot.mood_entropy > 0.6 ) chance = chance * 1.3;
   // High momentum (on a roll) = chattier
   if ( bot.momentum > 0.7 ) chance = chance * 1.2;

   if ( random() > chance ) return;

   // Select message -- use random index and skill-based variant
   local float idx;
   local string msg;
   msg = "";

   if ( chat_event == CHAT_KILL ) {
      idx = floor(random() * 10);
      if ( bot.skil >= 5 ) {
         // Terse, cocky
         if ( idx < 2 )      msg = "lol";
         else if ( idx < 4 ) msg = "ez";
         else if ( idx < 5 ) msg = ".";
         else if ( idx < 6 ) msg = "later";
         else if ( idx < 7 ) msg = "free";
         else if ( idx < 8 ) msg = "sit down";
         else if ( idx < 9 ) msg = "rekt";
         else                msg = "bye";
      } else if ( bot.skil >= 3 ) {
         // Normal
         if ( idx < 2 )      msg = "haha";
         else if ( idx < 3 ) msg = "nice fight";
         else if ( idx < 4 ) msg = "too slow";
         else if ( idx < 5 ) msg = "gg no re";
         else if ( idx < 6 ) msg = "later";
         else if ( idx < 7 ) msg = "get rekt";
         else if ( idx < 8 ) msg = "lol";
         else if ( idx < 9 ) msg = "eat it";
         else                msg = "bye";
      } else {
         // Low skill -- surprised they got a kill
         if ( idx < 2 )      msg = "haha yes";
         else if ( idx < 3 ) msg = "wait i got one";
         else if ( idx < 5 ) msg = "lol";
         else if ( idx < 6 ) msg = "did i do that";
         else if ( idx < 7 ) msg = "finally";
         else if ( idx < 8 ) msg = "wooo";
         else if ( idx < 9 ) msg = "take that";
         else                msg = "boom";
      }
   } else if ( chat_event == CHAT_DEATH ) {
      idx = floor(random() * 8);
      if ( bot.skil >= 5 ) {
         if ( idx < 2 )      msg = "nice";
         else if ( idx < 3 ) msg = "ok";
         else if ( idx < 4 ) msg = "...";
         else if ( idx < 5 ) msg = "lag";
         else if ( idx < 6 ) msg = "whatever";
         else if ( idx < 7 ) msg = "lucky";
         else                msg = "again";
      } else if ( bot.skil >= 3 ) {
         if ( idx < 2 )      msg = "nice shot";
         else if ( idx < 3 ) msg = "fair enough";
         else if ( idx < 4 ) msg = "ouch";
         else if ( idx < 5 ) msg = "ow";
         else if ( idx < 6 ) msg = "again?";
         else if ( idx < 7 ) msg = "bs";
         else                msg = "wow";
      } else {
         if ( idx < 2 )      msg = "how??";
         else if ( idx < 3 ) msg = "wait what";
         else if ( idx < 4 ) msg = "ugh";
         else if ( idx < 5 ) msg = "not again";
         else if ( idx < 6 ) msg = "come on";
         else if ( idx < 7 ) msg = "thats cheap";
         else                msg = "hax";
      }
      // Grudge-specific messages override
      if ( bot.grudge_deaths >= 3 && random() < 0.4 ) {
         idx = floor(random() * 4);
         if ( idx < 1 )      msg = "im coming for you";
         else if ( idx < 2 ) msg = "you again";
         else if ( idx < 3 ) msg = "thats it";
         else                msg = "ok its personal now";
      }
   } else if ( chat_event == CHAT_POWERUP ) {
      idx = floor(random() * 6);
      if ( idx < 1 )      msg = "mine";
      else if ( idx < 2 ) msg = "quad time";
      else if ( idx < 3 ) msg = "lets go";
      else if ( idx < 4 ) msg = "haha yes";
      else if ( idx < 5 ) msg = "dont run";
      else                msg = "oh yes";
   } else if ( chat_event == CHAT_ESCAPE ) {
      idx = floor(random() * 5);
      if ( idx < 1 )      msg = "nope";
      else if ( idx < 2 ) msg = "cya";
      else if ( idx < 3 ) msg = "too close";
      else if ( idx < 4 ) msg = "phew";
      else                msg = "not today";
   } else if ( chat_event == CHAT_SPAWN ) {
      idx = floor(random() * 4);
      if ( idx < 1 )      msg = "here we go";
      else if ( idx < 2 ) msg = "round 2";
      else if ( idx < 3 ) msg = "ok lets go";
      else                msg = "back";
   }

   if ( msg == "" ) return;

   // Emit chat message via bprint
   bprint (bot.netname);
   bprint (": ");
   bprint (msg);
   bprint ("\n");

   // Set cooldown (4-10s, random variance)
   bot.chat_cooldown = time + 4 + random() * 6;
};

// =============================================================================
// ITEM TIMER TRACKING
// =============================================================================

// Called when a major item is picked up -- broadcast to all bots for timer tracking.
// self = the item entity being picked up, other = the picker.
void (entity item) BotBroadcastItemTimer = {
   local entity bot;
   bot = bot_list_head;

   while ( bot ) {
      // Only skill 3+ bots track item timers
      if ( bot.skil >= 3 ) {
         // Find an empty slot or evict LRU (slot 3)
         if ( !bot.item_timer_ent_0 || bot.item_timer_ent_0 == item ) {
            bot.item_timer_ent_0 = item;
            bot.item_timer_time_0 = time;
         } else if ( !bot.item_timer_ent_1 || bot.item_timer_ent_1 == item ) {
            bot.item_timer_ent_1 = item;
            bot.item_timer_time_1 = time;
         } else if ( !bot.item_timer_ent_2 || bot.item_timer_ent_2 == item ) {
            bot.item_timer_ent_2 = item;
            bot.item_timer_time_2 = time;
         } else if ( !bot.item_timer_ent_3 || bot.item_timer_ent_3 == item ) {
            bot.item_timer_ent_3 = item;
            bot.item_timer_time_3 = time;
         } else {
            // All slots full, no match -- LRU evict: shift 3->discard, 2->3, 1->2, 0->1, new->0
            bot.item_timer_ent_3 = bot.item_timer_ent_2;
            bot.item_timer_time_3 = bot.item_timer_time_2;
            bot.item_timer_ent_2 = bot.item_timer_ent_1;
            bot.item_timer_time_2 = bot.item_timer_time_1;
            bot.item_timer_ent_1 = bot.item_timer_ent_0;
            bot.item_timer_time_1 = bot.item_timer_time_0;
            bot.item_timer_ent_0 = item;
            bot.item_timer_time_0 = time;
         }
      }
      bot = bot.bot_next;
   }
};

// Returns the pickup time for a given item from a bot's timer tracker.
// Returns 0 if not tracked.
float (entity bot, entity item) BotGetItemTimer = {
   if ( bot.item_timer_ent_0 == item ) return bot.item_timer_time_0;
   if ( bot.item_timer_ent_1 == item ) return bot.item_timer_time_1;
   if ( bot.item_timer_ent_2 == item ) return bot.item_timer_time_2;
   if ( bot.item_timer_ent_3 == item ) return bot.item_timer_time_3;
   return 0;
};
