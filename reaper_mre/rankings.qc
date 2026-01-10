float (float clientno) clientBitFlag;
float (float clientno) clientIsActive;

void (float clientno) clientSetUsed;

void (float clientno) clientSetFree;
float () clientNextAvailable;

void () botConnect;

void (entity bot) botDisconnect;

void (float clientno) botInvalidClientNo;
float MSG_UPDATENAME    = 13.000;
float MSG_UPDATEFRAGS    = 14.000;
float MSG_UPDATECOLORS    = 17.000;

void (entity player, float clientno, string clientname) msgUpdateNameToPlayer;

void (entity player, float clientno, float clientshirt, float clientpants) msgUpdateColorsToPlayer;

void (entity player, float clientno, float clientfrags) msgUpdateFragsToPlayer;

void (float clientno, string clientname) msgUpdateNameToAll;

void (float clientno, float clientshirt, float clientpants) msgUpdateColorsToAll;

void (float clientno, float clientfrags) msgUpdateFragsToAll;

void () clientInitMaxClients =
{
   local entity ent;

   ent = nextent (world);
   dprint ("Counting Clients");
   while ((ent.classname != "worldspawn"))
   {
      fMaxClients = (fMaxClients + CARRIED);
      dprint (ftos (fMaxClients));
      dprint ("\n");
      ent = nextent (ent);
   } //end while
}; //end of the function clientInitMaxClients
float (float clientno) clientBitFlag =
{
   local float bitflag;

   bitflag = CARRIED;
   while ((clientno > MSG_BROADCAST))
   {
      bitflag = (bitflag * WEAPON_ROCKET);
      clientno = (clientno - CARRIED);
   } //end while
   return (bitflag);
}; //end of the function clientBitFlag
float (float clientno) clientIsActive =
{
   if ((fActiveClients & clientBitFlag (clientno)))
   {
      return (TRUE);
   } //end if
   return (FALSE);
}; //end of the function clientIsActive

void (float clientno) clientSetUsed =
{
   fActiveClients = (fActiveClients | clientBitFlag (clientno));
}; //end of the function clientSetUsed

void (float clientno) clientSetFree =
{
   fActiveClients = (fActiveClients - (fActiveClients & clientBitFlag (clientno)));
}; //end of the function clientSetFree
float () clientNextAvailable =
{
   local float clientno;

   clientno = MSG_BROADCAST;
   while ((clientno < fMaxClients))
   {
      if (!clientIsActive (clientno))
      {
         return (clientno);
      } //end if
      clientno = (clientno + CARRIED);
   } //end while
   return (CONTENT_EMPTY);
}; //end of the function clientNextAvailable

void () botConnect =
{
   local float clientno;
   local entity bot;

   clientno = clientNextAvailable ();
   if ((clientno == CONTENT_EMPTY))
   {
      bprint ("Unable to connect a bot, server is full.\n");
      return ;
   } //end if
   clientSetUsed (clientno);
   bot = spawn ();
   bot.fClientNo = clientno;
   bot.colormap = (clientno + CARRIED);
   bot.fShirt = floor ((random () * MSG_UPDATENAME));
   bot.fPants = floor ((random () * MSG_UPDATENAME));
   msgUpdateNameToAll (bot.fClientNo,bot.netname);
   msgUpdateColorsToAll (bot.fClientNo,bot.fShirt,bot.fPants);
   msgUpdateFragsToAll (bot.fClientNo,bot.frags);
   bprint (bot.netname);
   bprint (" entered the game\n");
}; //end of the function botConnect

void (entity bot) botDisconnect =
{
   if ((bot.fClientNo != CONTENT_EMPTY))
   {
      msgUpdateNameToAll (bot.fClientNo,string_null);
      msgUpdateColorsToAll (bot.fClientNo,MSG_BROADCAST,MSG_BROADCAST);
      msgUpdateFragsToAll (bot.fClientNo,MSG_BROADCAST);
      clientSetFree (bot.fClientNo);
      bot.fClientNo = CONTENT_EMPTY;
   } //end if
   bprint (bot.netname);
   bprint (" left the game with ");
   bprint (ftos (bot.frags));
   bprint (" frags\n");
   sound (bot,CHAN_BODY,"player/tornoff2.wav",CARRIED,ATTN_NONE);
}; //end of the function botDisconnect

void (float clientno) botInvalidClientNo =
{
   local entity bot;

   bot = findbot (world);
   while (bot)
   {
      if ((bot.fClientNo == clientno))
      {
         clientno = clientNextAvailable ();
         if ((clientno != CONTENT_EMPTY))
         {
            clientSetUsed (clientno);
            bot.fClientNo = clientno;
            bot.colormap = (bot.fClientNo + CARRIED);
            msgUpdateNameToAll (bot.fClientNo,bot.netname);
            msgUpdateColorsToAll (bot.fClientNo,bot.fShirt,bot.fPants);
            msgUpdateFragsToAll (bot.fClientNo,bot.frags);

         } //end if
         else
         {
            remove (bot);
         } //end if
         return ;
      } //end if
      bot = findbot (bot);
   } //end while
}; //end of the function botInvalidClientNo

void (entity player, float clientno, string clientname) msgUpdateNameToPlayer =
{
   msgUpdateNameToAll (clientno,clientname);
   return ;
   msg_entity = player;
   WriteByte (MSG_ONE,MSG_UPDATENAME);
   WriteByte (MSG_ONE,clientno);
   WriteString (MSG_ONE,clientname);
}; //end of the function msgUpdateNameToPlayer

void (entity player, float clientno, float clientshirt, float clientpants) msgUpdateColorsToPlayer =
{
   msgUpdateColorsToAll (clientno,clientshirt,clientpants);
   return ;
   msg_entity = player;
   WriteByte (MSG_ONE,MSG_UPDATECOLORS);
   WriteByte (MSG_ONE,clientno);
   WriteByte (MSG_ONE,((clientshirt * STRAFE_DIR) + clientpants));
}; //end of the function msgUpdateColorsToPlayer

void (entity player, float clientno, float clientfrags) msgUpdateFragsToPlayer =
{
   msgUpdateFragsToAll (clientno,clientfrags);
   return ;
   msg_entity = player;
   WriteByte (MSG_ONE,MSG_UPDATEFRAGS);
   WriteByte (MSG_ONE,clientno);
   WriteShort (MSG_ONE,clientfrags);
}; //end of the function msgUpdateFragsToPlayer

void (float clientno, string clientname) msgUpdateNameToAll =
{
   WriteByte (MSG_ALL,MSG_UPDATENAME);
   WriteByte (MSG_ALL,clientno);
   WriteString (MSG_ALL,clientname);
}; //end of the function msgUpdateNameToAll

void (float clientno, float clientshirt, float clientpants) msgUpdateColorsToAll =
{
   WriteByte (MSG_ALL,MSG_UPDATECOLORS);
   WriteByte (MSG_ALL,clientno);
   WriteByte (MSG_ALL,((clientshirt * STRAFE_DIR) + clientpants));
}; //end of the function msgUpdateColorsToAll

void (float clientno, float clientfrags) msgUpdateFragsToAll =
{
   WriteByte (MSG_ALL,MSG_UPDATEFRAGS);
   WriteByte (MSG_ALL,clientno);
   WriteShort (MSG_ALL,clientfrags);
}; //end of the function msgUpdateFragsToAll
