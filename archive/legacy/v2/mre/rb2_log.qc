// Reapbot v2 debug logging and trace helpers.
void (entity bot, string tag, string msg) RB2_Log =
{
   if (!rb2_debug_enabled)
   {
      return;
   } //end if
   if (!bot)
   {
      return;
   } //end if
   bprint ("[");
   bprint (bot.netname);
   bprint ("] ");
   bprint (tag);
   bprint (": ");
   bprint (msg);
   bprint ("\n");
}; //end of the function RB2_Log

void (entity bot, string msg) RB2_TracePush =
{
   local float idx;

   if (!rb2_trace_enabled)
   {
      return;
   } //end if
   if (!bot)
   {
      return;
   } //end if

   idx = bot.rb2_trace_index;
   if ((idx == 0.000)) { bot.rb2_trace0 = msg; }
   else if ((idx == 1.000)) { bot.rb2_trace1 = msg; }
   else if ((idx == 2.000)) { bot.rb2_trace2 = msg; }
   else if ((idx == 3.000)) { bot.rb2_trace3 = msg; }
   else if ((idx == 4.000)) { bot.rb2_trace4 = msg; }
   else if ((idx == 5.000)) { bot.rb2_trace5 = msg; }
   else if ((idx == 6.000)) { bot.rb2_trace6 = msg; }
   else { bot.rb2_trace7 = msg; }

   idx = (idx + 1.000);
   if ((idx >= RB2_TRACE_MAX))
   {
      idx = 0.000;
   } //end if
   bot.rb2_trace_index = idx;

   if ((bot.rb2_trace_count < RB2_TRACE_MAX))
   {
      bot.rb2_trace_count = (bot.rb2_trace_count + 1.000);
   } //end if
}; //end of the function RB2_TracePush

void (entity bot) RB2_TraceDump =
{
   local float count;
   local float idx;
   local float n;

   if (!bot)
   {
      return;
   } //end if
   count = bot.rb2_trace_count;
   if ((count <= 0.000))
   {
      RB2_Log (bot,"RB2","trace empty");
      return;
   } //end if

   idx = (bot.rb2_trace_index - count);
   if ((idx < 0.000))
   {
      idx = (idx + RB2_TRACE_MAX);
   } //end if

   RB2_Log (bot,"RB2","trace dump begin");
   n = 0.000;
   while ((n < count))
   {
      if ((idx == 0.000)) { bprint (bot.rb2_trace0); }
      else if ((idx == 1.000)) { bprint (bot.rb2_trace1); }
      else if ((idx == 2.000)) { bprint (bot.rb2_trace2); }
      else if ((idx == 3.000)) { bprint (bot.rb2_trace3); }
      else if ((idx == 4.000)) { bprint (bot.rb2_trace4); }
      else if ((idx == 5.000)) { bprint (bot.rb2_trace5); }
      else if ((idx == 6.000)) { bprint (bot.rb2_trace6); }
      else { bprint (bot.rb2_trace7); }
      bprint ("\n");

      idx = (idx + 1.000);
      if ((idx >= RB2_TRACE_MAX))
      {
         idx = 0.000;
      } //end if
      n = (n + 1.000);
   } //end while
   RB2_Log (bot,"RB2","trace dump end");
}; //end of the function RB2_TraceDump
