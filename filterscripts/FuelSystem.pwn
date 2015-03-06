//By [GCnR]TrollMan
//Optimized by [GCnR]GamEraser (Bar Harel)

#include <a_samp>
#include <streamer>
#include <YSI\y_iterate>
#include <zcmd>
#include <sscanf2>
#pragma tabsize 0

#undef MAX_PLAYERS
#define MAX_PLAYERS 30
#define MaxFuelStations 11
#define GasStationDialog 12211
#define FuelDialog 12212
#define TextUpdateTime 120 //in ms
#define Col_Red 0xff0000ff
#define Col_Green 0x00ff00ff

native IsValidVehicle(vehicleid);

forward UpdateFuel();
forward RestoreFuel(vehicleid);

enum PlayerInfo{
	alive,
	pState,
	CurrentVeh,
	bool:ReduceFuel,
	bool:NeedUpdate,
	bool:LowFuelShown
}

new Fuel[MAX_VEHICLES], pInfo[MAX_PLAYERS][PlayerInfo], CheckPoint[MaxFuelStations], MapIcon[MaxFuelStations], UpdateFuelTimer, Text:Box1TextDraw, Text:Box2TextDraw[MAX_PLAYERS], Text:ServerNameTextDraw, Text:ServerIPTextDraw, Text:VehicleHealthTextDraw[MAX_PLAYERS], Text:VehicleSpeedTextDraw[MAX_PLAYERS], Text:VehicleFuelTextDraw[MAX_PLAYERS], Text:LowFuelText;

public OnFilterScriptInit()
{
	for(new VehicleID; VehicleID != MAX_VEHICLES; VehicleID++) Fuel[VehicleID] = 100;
	for(new i; i != MAX_PLAYERS; i++) pInfo[i][CurrentVeh] = -1;
	SetTimer("UpdatePlayers", TextUpdateTime, true);
	UpdateFuelTimer = SetTimer("UpdateFuel", 18875, true);
	
	CheckPoint[0] = CreateDynamicCP(1003.9382, -941.1201, 42.1797, 5.0, -1, 0, -1, 100.0); // LS[0]
	MapIcon[0] = CreateDynamicMapIcon(1003.9382, -941.1201, 42.1797, 27, 0xFFFFFFFF, -1, 0, -1, 350.0, MAPICON_LOCAL); // LS[0]

	CheckPoint[1] = CreateDynamicCP(1936.5411, -1772.5061, 13.3828, 5.0, -1, 0, -1, 100.0); // LS[1]
	MapIcon[1] = CreateDynamicMapIcon(1936.5411, -1772.5061, 13.3828, 27, 0xFFFFFFFF, -1, 0, -1, 350.0, MAPICON_LOCAL); // LS[1]
	
	CheckPoint[2] = CreateDynamicCP(659.2138, -566.0687, 16.3359, 5.0, -1, 0, -1, 100.0); // LS[2]
	MapIcon[2] = CreateDynamicMapIcon(659.2138, -566.0687, 16.3359, 27, 0xFFFFFFFF, -1, 0, -1, 350.0, MAPICON_LOCAL); // LS[2]
	
	CheckPoint[3] = CreateDynamicCP(-91.0037, -1167.5679, 2.4382, 5.0, -1, 0, -1, 100.0); // LS[3]
	MapIcon[3] = CreateDynamicMapIcon(-91.0037, -1167.5679, 2.4382, 27, 0xFFFFFFFF, -1, 0, -1, 350.0, MAPICON_LOCAL); // LS[3]
	
	CheckPoint[4] = CreateDynamicCP(-1675.6666, 413.5979, 7.1797, 5.0, -1, 0, -1, 100.0); // SF[0]
	MapIcon[4] = CreateDynamicMapIcon(-1675.6666, 413.5979, 7.1797, 27, 0xFFFFFFFF, -1, 0, -1, 350.0, MAPICON_LOCAL); // SF[0]

	CheckPoint[5] = CreateDynamicCP(-2416.0007, 975.1663, 45.2969, 5.0, -1, 0, -1, 100.0); // SF[1]
	MapIcon[5] = CreateDynamicMapIcon(-2416.0007, 975.1663, 45.2969, 27, 0xFFFFFFFF, -1, 0, -1, 350.0, MAPICON_LOCAL); // SF[1]
	
	CheckPoint[6] = CreateDynamicCP(2202.4763, 2476.6968, 10.8203, 5.0, -1, 0, -1, 100.0); // LV[0]
	MapIcon[6] = CreateDynamicMapIcon(2202.4763, 2476.6968, 10.8203, 27, 0xFFFFFFFF, -1, 0, -1, 350.0, MAPICON_LOCAL); // LV[0]

	CheckPoint[7] = CreateDynamicCP(-1469.2552, 1864.2220, 32.2024, 5.0, -1, 0, -1, 100.0); //LV[1]
	MapIcon[7] = CreateDynamicMapIcon(-1469.2552, 1864.2220, 32.2024, 27, 0xFFFFFFFF, -1, 0, -1, 350.0, MAPICON_LOCAL); // LV[1]
	
	CheckPoint[8] = CreateDynamicCP(-1328.1338, 2677.4810, 49.6475, 5.0, -1, 0, -1, 100.0); //LV[2]
	MapIcon[8] = CreateDynamicMapIcon(-1328.1338, 2677.4810, 49.6475, 27, 0xFFFFFFFF, -1, 0, -1, 350.0, MAPICON_LOCAL); // LV[2]
	
	CheckPoint[9] = CreateDynamicCP(2116.6438, 920.1750, 10.4064, 5.0, -1, 0, -1, 100.0); //LV[3]
	MapIcon[9] = CreateDynamicMapIcon(2116.6438, 920.1750, 10.4064, 27, 0xFFFFFFFF, -1, 0, -1, 350.0, MAPICON_LOCAL); // LV[3]
	
	CheckPoint[10] = CreateDynamicCP(1597.3470, 2198.9255, 10.4015, 5.0, -1, 0, -1, 100.0); //LV[4]
	MapIcon[10] = CreateDynamicMapIcon(1597.3470, 2198.9255, 10.4015, 27, 0xFFFFFFFF, -1, 0, -1, 350.0, MAPICON_LOCAL); // LV[4]

	Box1TextDraw = TextDrawCreate(642.000000, 437.000000, "_");
	TextDrawBackgroundColor(Box1TextDraw, 255);
	TextDrawFont(Box1TextDraw, 1);
	TextDrawLetterSize(Box1TextDraw, 0.500000, 1.000000);
	TextDrawColor(Box1TextDraw, 724249480);
	TextDrawSetOutline(Box1TextDraw, 0);
	TextDrawSetProportional(Box1TextDraw, 1);
	TextDrawSetShadow(Box1TextDraw, 1);
	TextDrawUseBox(Box1TextDraw, 1);
	TextDrawBoxColor(Box1TextDraw, 724249480);
	TextDrawTextSize(Box1TextDraw, -3.000000, 0.000000);
	TextDrawSetSelectable(Box1TextDraw, 0);

	ServerNameTextDraw = TextDrawCreate(2.000000, 436.000000, "Game's Cops And Robbers");
	TextDrawBackgroundColor(ServerNameTextDraw, 255);
	TextDrawFont(ServerNameTextDraw, 0);
	TextDrawLetterSize(ServerNameTextDraw, 0.500000, 1.000000);
	TextDrawColor(ServerNameTextDraw, -1);
	TextDrawSetOutline(ServerNameTextDraw, 1);
	TextDrawSetProportional(ServerNameTextDraw, 1);
	TextDrawSetSelectable(ServerNameTextDraw, 0);
	
	ServerIPTextDraw = TextDrawCreate(519.300000, 437.300000, "www.gcnr.net");
	TextDrawBackgroundColor(ServerIPTextDraw, 255);
	TextDrawFont(ServerIPTextDraw, 3);
	TextDrawLetterSize(ServerIPTextDraw, 0.390000, 0.850000);
	TextDrawColor(ServerIPTextDraw, -1);
	TextDrawSetOutline(ServerIPTextDraw, 1);
	TextDrawSetProportional(ServerIPTextDraw, 1);
	TextDrawSetSelectable(ServerIPTextDraw, 0);
	
	LowFuelText = TextDrawCreate(278.5 ,395 , "**Low Fuel**");
	TextDrawFont(LowFuelText , 1);
	TextDrawLetterSize(LowFuelText , 0.6, 4.2);
	TextDrawColor(LowFuelText , 0xff0000FF);
	TextDrawSetOutline(LowFuelText , false);
	TextDrawSetProportional(LowFuelText , true);
	TextDrawSetShadow(LowFuelText , 1);
	 
	for (new playerid; playerid < MAX_PLAYERS; playerid++){
	 
		Box2TextDraw[playerid] = TextDrawCreate(642.000000, 399.000000, "_");
		TextDrawBackgroundColor(Box2TextDraw[playerid], 255);
		TextDrawFont(Box2TextDraw[playerid], 1);
		TextDrawLetterSize(Box2TextDraw[playerid], 0.000000, 3.699999);
		TextDrawColor(Box2TextDraw[playerid], 724249480);
		TextDrawSetOutline(Box2TextDraw[playerid], 0);
		TextDrawSetProportional(Box2TextDraw[playerid], 1);
		TextDrawSetShadow(Box2TextDraw[playerid], 1);
		TextDrawUseBox(Box2TextDraw[playerid], 1);
		TextDrawBoxColor(Box2TextDraw[playerid], 724249480);
		TextDrawTextSize(Box2TextDraw[playerid], 585.000000, 0.000000);
		TextDrawSetSelectable(Box2TextDraw[playerid], 0);

		VehicleHealthTextDraw[playerid] = TextDrawCreate(590.000000, 400.000000, "Health : ~g~100");
		TextDrawBackgroundColor(VehicleHealthTextDraw[playerid], 255);
		TextDrawFont(VehicleHealthTextDraw[playerid], 1);
		TextDrawLetterSize(VehicleHealthTextDraw[playerid], 0.200000, 1.000000);
		TextDrawColor(VehicleHealthTextDraw[playerid], -1);
		TextDrawSetOutline(VehicleHealthTextDraw[playerid], 1);
		TextDrawSetProportional(VehicleHealthTextDraw[playerid], 1);
		TextDrawSetSelectable(VehicleHealthTextDraw[playerid], 0);

		VehicleSpeedTextDraw[playerid] = TextDrawCreate(590.000000, 412.000000, "Speed : ~r~ 0");
		TextDrawBackgroundColor(VehicleSpeedTextDraw[playerid], 255);
		TextDrawFont(VehicleSpeedTextDraw[playerid], 1);
		TextDrawLetterSize(VehicleSpeedTextDraw[playerid], 0.200000, 1.000000);
		TextDrawColor(VehicleSpeedTextDraw[playerid], -1);
		TextDrawSetOutline(VehicleSpeedTextDraw[playerid], 1);
		TextDrawSetProportional(VehicleSpeedTextDraw[playerid], 1);
		TextDrawSetSelectable(VehicleSpeedTextDraw[playerid], 0);
		
		VehicleFuelTextDraw[playerid] = TextDrawCreate(590.000000, 424.000000, "Fuel : ~g~100");
		TextDrawBackgroundColor(VehicleFuelTextDraw[playerid], 255);
		TextDrawFont(VehicleFuelTextDraw[playerid], 1);
		TextDrawLetterSize(VehicleFuelTextDraw[playerid], 0.200000, 1.000000);
		TextDrawColor(VehicleFuelTextDraw[playerid], -1);
		TextDrawSetOutline(VehicleFuelTextDraw[playerid], 1);
		TextDrawSetProportional(VehicleFuelTextDraw[playerid], 1);
		TextDrawSetSelectable(VehicleFuelTextDraw[playerid], 0);
		
	}
	return 1;
}

public OnFilterScriptExit()
{
	for(new VehicleID = 0; VehicleID < MAX_VEHICLES; VehicleID++)
	{
		if(IsValidVehicle(VehicleID))
		{
			Fuel[VehicleID] = 0;
		}
	}
	for(new ID = 0; ID < MaxFuelStations; ID++)
	{
		if(IsValidDynamicCP(ID))
		{
			DestroyDynamicCP(ID);
		}
		if(IsValidDynamicMapIcon(ID))
		{
		    DestroyDynamicMapIcon(ID);
		}
	}
	for(new PlayerID = 0; PlayerID < MAX_PLAYERS; PlayerID++)
	{
		TextDrawDestroy(Box2TextDraw[PlayerID]);
		TextDrawDestroy(VehicleHealthTextDraw[PlayerID]);
		TextDrawDestroy(VehicleSpeedTextDraw[PlayerID]);
		TextDrawDestroy(VehicleFuelTextDraw[PlayerID]);
	}
	KillTimer(UpdateFuelTimer);
	TextDrawDestroy(Box1TextDraw);
	TextDrawDestroy(ServerNameTextDraw);
	TextDrawDestroy(ServerIPTextDraw);
	return 1;
}

public OnPlayerConnect(playerid)
{
	TextDrawShowForPlayer(playerid, Box1TextDraw);
	TextDrawShowForPlayer(playerid, ServerNameTextDraw);
	TextDrawShowForPlayer(playerid, ServerIPTextDraw);
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	pInfo[playerid][alive] = false;
	pInfo[playerid][CurrentVeh] = -1;
	TextDrawHideForPlayer(playerid, Box1TextDraw);
	TextDrawHideForPlayer(playerid, ServerNameTextDraw);
	TextDrawHideForPlayer(playerid, ServerIPTextDraw);
	return 1;
}

public OnPlayerSpawn(playerid)
{
	pInfo[playerid][alive] = true;
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	pInfo[playerid][pState] = newstate;
	if(newstate == PLAYER_STATE_DRIVER || newstate == PLAYER_STATE_PASSENGER)
	{
		pInfo[playerid][CurrentVeh] = GetPlayerVehicleID(playerid);
		TextDrawShowForPlayer(playerid, Box2TextDraw[playerid]);
		TextDrawShowForPlayer(playerid, VehicleHealthTextDraw[playerid]);
		TextDrawShowForPlayer(playerid, VehicleSpeedTextDraw[playerid]);
		TextDrawShowForPlayer(playerid, VehicleFuelTextDraw[playerid]);
		new FuelInString[17];
		if(Fuel[pInfo[playerid][CurrentVeh]] >= 50){
			format(FuelInString, 17, "Fuel : ~g~%i", Fuel[pInfo[playerid][CurrentVeh]]);
		}else if(Fuel[pInfo[playerid][CurrentVeh]] <= 49 && Fuel[pInfo[playerid][CurrentVeh]] >= 26){
			format(FuelInString, 17, "Fuel : ~y~%i", Fuel[pInfo[playerid][CurrentVeh]]);
		}else{
			format(FuelInString, 17, "Fuel : ~r~%i", Fuel[pInfo[playerid][CurrentVeh]]);
			TextDrawShowForPlayer(playerid, LowFuelText);
			pInfo[playerid][LowFuelShown] = true;
		}
		TextDrawSetString(VehicleFuelTextDraw[playerid], FuelInString);
	}else if(oldstate == PLAYER_STATE_DRIVER || oldstate == PLAYER_STATE_PASSENGER){
		pInfo[playerid][CurrentVeh] = -1;
		TextDrawHideForPlayer(playerid, Box2TextDraw[playerid]);
		TextDrawHideForPlayer(playerid, VehicleHealthTextDraw[playerid]);
		TextDrawHideForPlayer(playerid, VehicleSpeedTextDraw[playerid]);
		TextDrawHideForPlayer(playerid, VehicleFuelTextDraw[playerid]);
		if (pInfo[playerid][LowFuelShown]) TextDrawHideForPlayer(playerid, LowFuelText), pInfo[playerid][LowFuelShown] = false;
	}
	return 1;
}

public OnPlayerUpdate(playerid)
{
	if (pInfo[playerid][NeedUpdate]){
		pInfo[playerid][NeedUpdate] = false;
		if(pInfo[playerid][alive] && pInfo[playerid][CurrentVeh] != -1)
		{
			if(pInfo[playerid][ReduceFuel] && pInfo[playerid][pState] == PLAYER_STATE_DRIVER) Fuel[pInfo[playerid][CurrentVeh]]--, pInfo[playerid][ReduceFuel] = false;
			OnPlayerVehicleUpdate(playerid);
		}
	}
	return 1;
}
stock OnPlayerVehicleUpdate(playerid)
{
	/*Health*/
	new VehicleHealthInInteger, formatted[17], Float:VehicleHealth;
	GetVehicleHealth(pInfo[playerid][CurrentVeh], VehicleHealth);
	VehicleHealthInInteger = floatround(VehicleHealth);
	if(VehicleHealthInInteger >= 500){
		format(formatted, 17, "Health : ~g~%i", VehicleHealthInInteger);
	}else if(VehicleHealthInInteger <= 499 && VehicleHealthInInteger >= 251){
		format(formatted, 17, "Health : ~y~%i", VehicleHealthInInteger);
	}else{
		format(formatted, 17, "Health : ~r~%i", VehicleHealthInInteger);
	}
	TextDrawSetString(VehicleHealthTextDraw[playerid], formatted);
	/*Health*/
	 
	/*Speed*/
	if(GetVehicleVelocityEx(pInfo[playerid][CurrentVeh]) == 0)
	{
		format(formatted, 17, "Speed : ~r~0");
	}
	else
	{
		format(formatted, 17, "Speed : ~g~%i", GetVehicleVelocityEx(pInfo[playerid][CurrentVeh]));
	}
	TextDrawSetString(VehicleSpeedTextDraw[playerid], formatted);
	/*Speed*/
	return 1;
}
COMMAND:adfuel(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 3) return 0;
	new target;
	if (sscanf(params, "I(-1)", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /adfuel [playerid]");
	new VehicleParams[7];
	if (target == -1){
		target = playerid;
		Fuel[pInfo[target][CurrentVeh]] = 100;
		GetVehicleParamsEx(pInfo[target][CurrentVeh], VehicleParams[0], VehicleParams[1], VehicleParams[2], VehicleParams[3], VehicleParams[4], VehicleParams[5], VehicleParams[6]);
		SetVehicleParamsEx(pInfo[target][CurrentVeh], 1, VehicleParams[1], VehicleParams[2], VehicleParams[3], VehicleParams[4], VehicleParams[5], VehicleParams[6]);
		SendClientMessage(playerid, Col_Green, "Fuel added.");
	}else{
		Fuel[pInfo[target][CurrentVeh]] = 100;
		GetVehicleParamsEx(pInfo[target][CurrentVeh], VehicleParams[0], VehicleParams[1], VehicleParams[2], VehicleParams[3], VehicleParams[4], VehicleParams[5], VehicleParams[6]);
		SetVehicleParamsEx(pInfo[target][CurrentVeh], 1, VehicleParams[1], VehicleParams[2], VehicleParams[3], VehicleParams[4], VehicleParams[5], VehicleParams[6]);
		SendClientMessage(target, Col_Green, "Fuel added by admin.");
		SendClientMessage(playerid, Col_Green, "Fuel added to target player.");
	}
	TextDrawSetString(VehicleFuelTextDraw[target], "Fuel : ~g~100");
	return 1;
}
public RestoreFuel(vehicleid){
	new VehicleParams[7];
	Fuel[vehicleid] = 100;
	GetVehicleParamsEx(vehicleid, VehicleParams[0], VehicleParams[1], VehicleParams[2], VehicleParams[3], VehicleParams[4], VehicleParams[5], VehicleParams[6]);
	SetVehicleParamsEx(vehicleid, 1, VehicleParams[1], VehicleParams[2], VehicleParams[3], VehicleParams[4], VehicleParams[5], VehicleParams[6]);
	return 1;
}
public UpdateFuel()
{
	new FuelInString[17];
	foreach (new i : Player)
	{
		if(pInfo[i][pState] == PLAYER_STATE_DRIVER){
			if(Fuel[pInfo[i][CurrentVeh]] > 1){
				Fuel[pInfo[i][CurrentVeh]] --;
				if(Fuel[pInfo[i][CurrentVeh]] >= 50){
					format(FuelInString, 17, "Fuel : ~g~%i", Fuel[pInfo[i][CurrentVeh]]);
				}else if(Fuel[pInfo[i][CurrentVeh]] <= 49 && Fuel[pInfo[i][CurrentVeh]] >= 26){
					format(FuelInString, 17, "Fuel : ~y~%i", Fuel[pInfo[i][CurrentVeh]]);
				}else{
					format(FuelInString, 17, "Fuel : ~r~%i", Fuel[pInfo[i][CurrentVeh]]);
					if (!pInfo[i][LowFuelShown]) TextDrawShowForPlayer(i, LowFuelText), pInfo[i][LowFuelShown] = true;
				}
				TextDrawSetString(VehicleFuelTextDraw[i], FuelInString);
			}else if(Fuel[pInfo[i][CurrentVeh]] == 1){
				Fuel[pInfo[i][CurrentVeh]]--;
				new VehicleParams[7];
				GetVehicleParamsEx(pInfo[i][CurrentVeh], VehicleParams[0], VehicleParams[1], VehicleParams[2], VehicleParams[3], VehicleParams[4], VehicleParams[5], VehicleParams[6]);
				if(VehicleParams[0] == -1 || VehicleParams[0] == 1){
					SendClientMessage(i, 0xFFFFFFFF, "No Fuel, Engine Shutdown!");
					SetVehicleParamsEx(pInfo[i][CurrentVeh], false, VehicleParams[1], VehicleParams[2], VehicleParams[3], VehicleParams[4], VehicleParams[5], VehicleParams[6]);
				}
				GameTextForPlayer(i, "Out Of Fuel", 5, 3000);
				TextDrawSetString(VehicleFuelTextDraw[i], "Fuel : ~r~0");
			}
			Fuel[pInfo[i][CurrentVeh]] ++;
			pInfo[i][ReduceFuel] = true;
		}else if(pInfo[i][pState] == PLAYER_STATE_PASSENGER){
			if(Fuel[pInfo[i][CurrentVeh]] >= 50){
				format(FuelInString, 17, "Fuel : ~g~%i", Fuel[pInfo[i][CurrentVeh]]);
				if (pInfo[i][LowFuelShown]) TextDrawHideForPlayer(i, LowFuelText), pInfo[i][LowFuelShown] = false;
			}else if(Fuel[pInfo[i][CurrentVeh]] <= 49 && Fuel[pInfo[i][CurrentVeh]] >= 26){
				format(FuelInString, 17, "Fuel : ~y~%i", Fuel[pInfo[i][CurrentVeh]]);
				if (pInfo[i][LowFuelShown]) TextDrawHideForPlayer(i, LowFuelText), pInfo[i][LowFuelShown] = false;
			}else{
				format(FuelInString, 17, "Fuel : ~r~%i", Fuel[pInfo[i][CurrentVeh]]);
				if (!pInfo[i][LowFuelShown]) TextDrawShowForPlayer(i, LowFuelText), pInfo[i][LowFuelShown] = true;
			}
			TextDrawSetString(VehicleFuelTextDraw[i], FuelInString);
		}
	}
	return 1;
}

public OnPlayerEnterDynamicCP(playerid, checkpointid)
{
	if(pInfo[playerid][pState] == PLAYER_STATE_DRIVER){
		for(new i; i != MaxFuelStations; i++){
			if(checkpointid == CheckPoint[i]){
				SetVehicleVelocity(pInfo[playerid][CurrentVeh], 0.0, 0.0, 0.0);
				SendClientMessage(playerid, 0xFFFFFFFF, "Welcome to the fuel station.");
				ShowPlayerDialog(playerid, GasStationDialog, DIALOG_STYLE_LIST, "{FF0000}Fuel Station", "{FFFFFF}Repair vehicle\t{00FF00}$2500{FFFFFF}\nRe-fuel vehicle\t{00FF00}$14 per litre", "Select", "Close");
				break;
			}
		}
	}
	return 1;
}

public OnPlayerLeaveDynamicCP(playerid, checkpointid)
{
	if(pInfo[playerid][pState] == PLAYER_STATE_DRIVER){
		for(new i; i != MaxFuelStations; i++){
			if(checkpointid == CheckPoint[i]){
				SendClientMessage(playerid, 0xFFFFFFFF, "You have left the fuel station, {FF0000}have a nice day!");
				break;
			}
		}
	}
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if(dialogid == GasStationDialog){
        if(!response) return 1;
		if(listitem == 0){
			new Float:VehicleHealth;
			GetVehicleHealth(pInfo[playerid][CurrentVeh], VehicleHealth);
			if(VehicleHealth < float(1000)){
				if(CallRemoteFunction("GetPMoney", "i", playerid) >= 2500){
					CallRemoteFunction("AddPMoney", "ii", playerid, -2500);
					RepairVehicle(pInfo[playerid][CurrentVeh]);
					SendClientMessage(playerid, 0xFFFFFFFF, "Vehicle repaired for {00FF00}$2500.");
					ShowPlayerDialog(playerid, GasStationDialog, DIALOG_STYLE_LIST, "{FF0000}Fuel Station", "{FFFFFF}Repair vehicle\t{00FF00}$2500{FFFFFF}\nRe-fuel vehicle\t{00FF00}$14 per litre", "Select", "Close");
				}else{
					SendClientMessage(playerid, 0xFFFFFFFF, "Not enough cash, {FF0000}stranger.");
					ShowPlayerDialog(playerid, GasStationDialog, DIALOG_STYLE_LIST, "{FF0000}Fuel Station", "{FFFFFF}Repair vehicle\t{00FF00}$2500{FFFFFF}\nRe-fuel vehicle\t{00FF00}$14 per litre", "Select", "Close");
				}
			}else{
				SendClientMessage(playerid, 0xFFFFFFFF, "Your vehicle is in a perfect state, {FF0000}stranger.");
				ShowPlayerDialog(playerid, GasStationDialog, DIALOG_STYLE_LIST, "{FF0000}Fuel Station", "{FFFFFF}Repair vehicle\t{00FF00}$2500{FFFFFF}\nRe-fuel vehicle\t{00FF00}$14 per litre", "Select", "Close");
			}
		}else if(listitem == 1){
			ShowPlayerDialog(playerid, FuelDialog, DIALOG_STYLE_INPUT, "{FF0000}Fuel Station", "{FFFFFF}How many litres do you want to add to your tank? (100 for full tank)", "Add", "Back");
		}
        return 1;
    }else if(dialogid == FuelDialog){
        if(!response) return ShowPlayerDialog(playerid, GasStationDialog, DIALOG_STYLE_LIST, "{FF0000}Fuel Station", "{FFFFFF}Repair vehicle\t{00FF00}$2500{FFFFFF}\nRe-fuel vehicle\t{00FF00}$14 per litre", "Select", "Close");
		if(IsNumeric(inputtext)){
			new Entry = strval(inputtext);
			if(Entry <= 0) return SendClientMessage(playerid, 0xFFFFFFFF, "You must enter a proper number {FF0000}stranger."), ShowPlayerDialog(playerid, FuelDialog, DIALOG_STYLE_INPUT, "{FF0000}Fuel Station", "{FFFFFF}How many litres do you want to add to your tank? (100 for full tank)", "Add", "Back");
			if (Entry == 100){
				Entry = 100-Fuel[pInfo[playerid][CurrentVeh]];
				if (!Entry) return SendClientMessage(playerid, 0xFFFFFFFF, "Your tank is full {FF0000}stranger."), ShowPlayerDialog(playerid, FuelDialog, DIALOG_STYLE_INPUT, "{FF0000}Fuel Station", "{FFFFFF}How many litres do you want to add to your tank? (100 for full tank)", "Add", "Back");
			}
			if(Entry + Fuel[pInfo[playerid][CurrentVeh]] > 100) return SendClientMessage(playerid, 0xFFFFFFFF, "Your vehicle tank can't hold more than 100 litres, {FF0000}stranger."), ShowPlayerDialog(playerid, FuelDialog, DIALOG_STYLE_INPUT, "{FF0000}Fuel Station", "{FFFFFF}How many litres do you want to add to your tank? (100 for full tank)", "Add", "Back");
			new formatted[128], total = Entry*14;
			if(total > CallRemoteFunction("GetPMoney", "i", playerid)){
				format(formatted, 128, "You need {00FF00}$%i{FFFFFF} to refuel {00FF00}%i{FFFFFF} litres, {FF0000}stranger.", total, Entry);
				SendClientMessage(playerid, 0xFFFFFFFF, formatted);
				ShowPlayerDialog(playerid, FuelDialog, DIALOG_STYLE_INPUT, "{FF0000}Fuel Station", "{FFFFFF}How many litres do you want to add to your tank? (100 for full tank)", "Add", "Back");
				return 1;
			}
			CallRemoteFunction("AddPMoney", "ii", playerid, -total);
			Fuel[pInfo[playerid][CurrentVeh]] += Entry;
			new FuelInString[17];
			if(Fuel[pInfo[playerid][CurrentVeh]] >= 50){
				format(FuelInString, 17, "Fuel : ~g~%i", Fuel[pInfo[playerid][CurrentVeh]]);
				if (pInfo[playerid][LowFuelShown]) TextDrawHideForPlayer(playerid, LowFuelText), pInfo[playerid][LowFuelShown] = false;
			}else if(Fuel[pInfo[playerid][CurrentVeh]] <= 49 && Fuel[pInfo[playerid][CurrentVeh]] >= 26){
				format(FuelInString, 17, "Fuel : ~y~%i", Fuel[pInfo[playerid][CurrentVeh]]);
				if (pInfo[playerid][LowFuelShown]) TextDrawHideForPlayer(playerid, LowFuelText), pInfo[playerid][LowFuelShown] = false;
			}else{
				format(FuelInString, 17, "Fuel : ~r~%i", Fuel[pInfo[playerid][CurrentVeh]]);
				if (!pInfo[playerid][LowFuelShown]) TextDrawShowForPlayer(playerid, LowFuelText), pInfo[playerid][LowFuelShown] = true;
			}
			TextDrawSetString(VehicleFuelTextDraw[playerid], FuelInString);
			if (Entry == 1) FuelInString = "";
			else FuelInString = "s";
			format(formatted, 128, "Added {00FF00}%i {FFFFFF}litre%s to your tank for {00FF00}$%i.", Entry, FuelInString,total);
			SendClientMessage(playerid, 0xFFFFFFFF, formatted);
			ShowPlayerDialog(playerid, GasStationDialog, DIALOG_STYLE_LIST, "{FF0000}Fuel Station", "{FFFFFF}Repair vehicle\t{00FF00}$2500{FFFFFF}\nRe-fuel vehicle\t{00FF00}$14 per litre", "Select", "Close");
			new bool:VehiclePMs[7];
			GetVehicleParamsEx(pInfo[playerid][CurrentVeh], VehiclePMs[0], VehiclePMs[1], VehiclePMs[2], VehiclePMs[3], VehiclePMs[4], VehiclePMs[5], VehiclePMs[6]);
			SetVehicleParamsEx(pInfo[playerid][CurrentVeh], 1, VehiclePMs[1], VehiclePMs[2], VehiclePMs[3], VehiclePMs[4], VehiclePMs[5], VehiclePMs[6]);
		}else{
			SendClientMessage(playerid, 0xFFFFFFFF, "You must enter a number, {FF0000}stranger.");
			ShowPlayerDialog(playerid, FuelDialog, DIALOG_STYLE_INPUT, "{FF0000}Fuel Station", "{FFFFFF}How many litres do you want to add to your tank? (100 for full tank)", "Add", "Back");
		}
		return 1;
	}
    return 0;
}

public OnVehicleSpawn(vehicleid) return Fuel[vehicleid] = 100, 1;

forward UpdatePlayers();
public UpdatePlayers() foreach(new i : Player) pInfo[i][NeedUpdate] = true;

stock GetVehicleVelocityEx(VehicleID)
{
    new Float:Velocity[3];
    GetVehicleVelocity(VehicleID, Velocity[0], Velocity[1], Velocity[2]);
	return floatround(floatsqroot(floatpower(Velocity[0],2) + floatpower(Velocity[1],2) + floatpower(Velocity[2],2)) * 100 * 1.609);
}
stock IsNumeric(String[])
{
	new StringLegnth = strlen(String);
    for(new Character = 0; Character < StringLegnth; Character++){
        if(String[Character] > '9' || String[Character] < '0'){
			return false;
		}
    }
    return true;
}
