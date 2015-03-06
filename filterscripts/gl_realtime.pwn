//
// Keeps the in game time synced to the server's time and
// draws the current time on the player's hud using a textdraw/
// (1 minute = 1 minute real world time)
//
//  (c) 2009-2012 SA-MP Team
// Modified by Bar Harel for 1 minute = 5 seconds.
#define FILTERSCRIPT
#include <a_samp>
#include <YSI\y_iterate>
#include <zcmd>
#include <sscanf2>
#pragma tabsize 0
#define Col_Red 0xff0000ff
#define Col_Green 0x00ff00ff

//--------------------------------------------------

new Text:txtTimeDisp;
new hour=0, minute=0;
new timestr[32];

forward UpdateTimeAndWeather();

//--------------------------------------------------

// new fine_weather_ids[] = {1,2,3,4,5,6,7,12,13,14,15,17,18};
// new foggy_weather_ids[] = {9,19};
// new wet_weather_ids[] = {8};

// stock UpdateWorldWeather()
// {
	// new next_weather_prob = random(100);
	// if(next_weather_prob < 90) 		SetWeather(fine_weather_ids[random(sizeof(fine_weather_ids))]);
	// else if(next_weather_prob <95) SetWeather(wet_weather_ids[random(sizeof(wet_weather_ids))]);
	// else							SetWeather(foggy_weather_ids[random(sizeof(foggy_weather_ids))]);
// }

//--------------------------------------------------

//new last_weather_update=0;

public UpdateTimeAndWeather()
{
	// Update time
    //gettime(hour, minute);
	minute++;
	if (minute == 60){
		hour++;
		minute = 0;
	}
	if (hour == 24) hour = 0;
   	format(timestr,32,"%02d:%02d",hour,minute);
   	TextDrawSetString(txtTimeDisp,timestr);
   	SetWorldTime(hour);
	foreach(new i : Player){
	    if(GetPlayerState(i) != PLAYER_STATE_NONE) {
	        SetPlayerTime(i,hour,minute);
		 }
	}
	
	// if(last_weather_update == 0) {
	    // UpdateWorldWeather();
	// }
	// last_weather_update++;
	// if(last_weather_update == 500) {
	    // last_weather_update = 0;
	// }
}

//--------------------------------------------------

public OnGameModeInit()
{
	// Init our text display
	txtTimeDisp = TextDrawCreate(605.0,25.0,"00:00");
	TextDrawUseBox(txtTimeDisp, 0);
	TextDrawFont(txtTimeDisp, 3);
	TextDrawSetShadow(txtTimeDisp,0); // no shadow
    TextDrawSetOutline(txtTimeDisp,2); // thickness 1
    TextDrawBackgroundColor(txtTimeDisp,0x000000FF);
    TextDrawColor(txtTimeDisp,0xFFFFFFFF);
    TextDrawAlignment(txtTimeDisp,3);
	TextDrawLetterSize(txtTimeDisp,0.5,1.5);
	
	UpdateTimeAndWeather();
	SetTimer("UpdateTimeAndWeather",5002,1);

	return 1;
}

//--------------------------------------------------

public OnPlayerSpawn(playerid)
{
	TextDrawShowForPlayer(playerid,txtTimeDisp);
	SetPlayerTime(playerid,hour,minute);
	
	return 1;
}

COMMAND:adtime(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 3) return 0;
	new hours, minutes;
	if (sscanf(params, "ii", hours, minutes)) return SendClientMessage(playerid, Col_Red, "USAGE: /adtime [hours] [minutes]");
	if (hours > 23 || hours < 0 || minutes > 59 || minutes < 0) return SendClientMessage(playerid, Col_Red, "Error: hours can be 0-23 and minutes 0-59");
	hour = hours;
	minute = minutes;
	return 1;
}
//--------------------------------------------------

public OnPlayerDeath(playerid, killerid, reason)
{
    TextDrawHideForPlayer(playerid,txtTimeDisp);
 	return 1;
}

//--------------------------------------------------

public OnPlayerConnect(playerid)
{
    SetPlayerTime(playerid,hour,minute);
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) return 0;
//--------------------------------------------------
