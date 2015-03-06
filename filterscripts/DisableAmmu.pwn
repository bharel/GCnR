// Idea and original system by aNdReSk along with older script :)
// Special thanks to BP13 and [HiC]TheKiller for perfectioning it!

#include <a_samp>
forward AMMUTIMER(playerid);

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{

if (!IsPlayerInAnyVehicle(playerid)){  // <<<< this is so Transfender doesn't get fucked up!

	if(oldinteriorid == 0 && newinteriorid == 1)
	{
		SetTimerEx("AMMUTIMER",1000,0, "i", playerid);
	}
	if(oldinteriorid == 0 && newinteriorid == 6)
	{
		SetTimerEx("AMMUTIMER",1000,0, "i", playerid);
 	}
	if(oldinteriorid == 0 && newinteriorid == 4)
	{
		SetTimerEx("AMMUTIMER",1000,0, "i", playerid);
	}
}

return 1;
}

public AMMUTIMER(playerid)
{
	SetPlayerShopName(playerid,"FDPIZA");
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) return 0;