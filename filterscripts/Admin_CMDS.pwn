//Created by Bar Harel
#define FILTERSCRIPT
#include <a_samp>
#undef MAX_PLAYERS
#define MAX_PLAYERS (30)
#define MaxPing 1400
#include "../include/gl_common.inc"
#include <core>
#include <a_players>
#include <YSI\y_iterate>
#include <YSI\y_ini>
#include <zcmd>
#include <sscanf2>
#include "../include/lookup.inc"

native WP_Hash(buffer[],len,const str[]); // Whirlpool native, add it at the top of your script under includes

#define UserPath "Users/%s.ini" //Will define user's account path. In this case, we will save it in Scriptfiles/Users. So create a file inside of your Scriptfiles folder called Users
#define BanPathL "Bans/%s.ini"
#define WhitePathL "Whitelist/%s.ini"
#define IPBanPathL "Bans/%s.ini"
#define Col_Red 0xff0000ff
#define COLOR_RED 0xff0000ff
#define Col_Blue 0x0000ffff
#define Col_LightBlue 0x6666ffff
#define Col_Orange 0xffa200ff
#define Col_LightOrange 0xffcb00ff
#define Col_Green 0x00ff00ff
#define Col_Yellow 0xffff00ff
#define Col_Pink 0xffb6e6ff
#define Col_Gray 0xAAAAAAAA

native IsValidVehicle(vehicleid);

new WeaponNames[47][] =
{
	{"Unarmed"},{"Brass Knuckles"},{"Golf Club"},{"Nite Stick"},{"Knife"},{"Baseball Bat"},{"Shovel"},{"Pool Cue"},{"Katana"},{"Chainsaw"},{"Purple Dildo"},
	{"Small White Vibrator"},{"Large White Vibrator"},{"Silver Vibrator"},{"Flowers"},{"Cane"},{"Grenade"},{"Tear Gas"},{"Molotov Cocktail"},
	{""},{""},{""}, // Empty spots for ID 19-20-21 (invalid weapon id's)
	{"9mm"},{"Silenced 9mm"},{"Desert Eagle"},{"Shotgun"},{"Sawn-off Shotgun"},{"Combat Shotgun"},{"Micro SMG"},{"MP5"},{"AK-47"},{"M4"},{"Tec9"},
	{"Country Rifle"},{"Sniper Rifle"},{"Rocket Launcher"},{"HS Rocket Launcher"},{"Flamethrower"},{"Minigun"},{"Satchel Charge"},{"Detonator"},
	{"Spraycan"},{"Fire Extinguisher"},{"Camera"},{"Nightvision Goggles"},{"Thermal Goggles"},{"Parachute"}
};

enum dialogs
{
	Dialog_adcmds = 100,
	Dialog_PassReset
}

enum PlayerPunish
{
    frtime, //freeze time
	reporter, //reporter id, -1 if not reported
	askerid, //ID of the person who asked, -1 if clear
	responderid, //ID of the person who responded, -1 if clear, -2 if question open
	jailtime, //jail time
	timerid, //punishment timer id
	mutedtimer, //mute timer
	ticks, //for anti-spam
	warns, //Warn amounts
	warntime, //Last warn issued
	HackCounter,
	Text3D:duty3did,
	Float:healthbefore, //Health before punishment
	bool:stealth, //admin stealth mode
	bool:needjail,
	bool:undercovered, //Flag undercovered account
	bool:specialpriv, //to avoid autoban
	bool:muted, //Is player muted?
	bool:alive, //For anti-hack
	bool:duty3d,
	fakeadmin //Hehe
}
new pPun[MAX_PLAYERS][PlayerPunish], LastIP[16], bool:proxystate, IPamount = 0, bool:ServerFreezeActive;

stock Path(playerid) //Will create a new stock so we can easily use it later to load/save user's data in user's path
{
    new str[128],name[MAX_PLAYER_NAME];
    GetPlayerName(playerid,name,sizeof(name));
    format(str,sizeof(str),UserPath,name);
    return str;
}
stock BanPath(playerid) //Will create a new stock so we can easily use it later to load/save user's data in user's path
{
    new str[128],name[MAX_PLAYER_NAME];
    GetPlayerName(playerid,name,sizeof(name));
    format(str,sizeof(str),BanPathL,name);
    return str;
}
stock IPBanPath(IP[])
{
	new str[128];
	format(str, 128, IPBanPathL, IP);
	return str;
}
stock WhitePath(name[])
{
	new str[128];
	format(str, 128, WhitePathL, name);
	return str;
}
forward loadaccount_user(playerid, name[], value[]); //forwarding a new function to load user's data
//Now we will use our own function that we have created above
public loadaccount_user(playerid, name[], value[])
{
    INI_Int("frtime", pPun[playerid][frtime]); 
	INI_Bool("undercoveredacc", pPun[playerid][undercovered]); 
	INI_Int("fakelevel", pPun[playerid][fakeadmin]);
	INI_Int("Warns", pPun[playerid][warns]); //Save an account undercovered state
	INI_Int("LastWarn", pPun[playerid][warntime]); //Save an account undercovered state
    return 1;
}
forward HackCheck();
//Script start

forward unmutetimer(playerid);
public unmutetimer(playerid){
	pPun[playerid][muted] = false;
	SendClientMessage(playerid, Col_Yellow, "You have been unmuted.");
	return 1;
}
forward timercheck(playerid);
public timercheck(playerid){
	new formatted[128];
	if (pPun[playerid][frtime]>1) {
		pPun[playerid][frtime]--;
		return 1;
	}else if (pPun[playerid][frtime] == 1){
		pPun[playerid][frtime]--;
		TogglePlayerControllable(playerid, 1);
		SendClientMessage(playerid, Col_Yellow, "You have been unfrozen.");
		return 1;
	}else if (pPun[playerid][jailtime]>1) {
		pPun[playerid][jailtime]--;
		format(formatted, 128, "Jail time left~n~%d", pPun[playerid][jailtime]);
		GameTextForPlayer(playerid, formatted, 1300, 6);
		if(!pPun[playerid][needjail] && GetPlayerInterior(playerid) == 0 && GetPVarInt(playerid, "Admin") < 1 && !pPun[playerid][specialpriv]){
			SetPlayerInterior(playerid, 6);
			SetPlayerPos(playerid,264.7426,77.7752,1001.0391);
			pPun[playerid][HackCounter]++;
			if (pPun[playerid][HackCounter] > 1){
				BanPlayer(-1, playerid, "teleportation hacks");
				pPun[playerid][jailtime] = 0;
			}
			return 0;
		}
		return 1;
	}else if (pPun[playerid][jailtime] == 1){
		pPun[playerid][jailtime]--;
		CallRemoteFunction("SetPlayerOCT", "i", playerid);
		SendClientMessage(playerid, Col_Yellow, "You have been unjailed.");
		new pname[MAX_PLAYER_NAME];
		GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
		format(formatted, 128, "%s(%d) has been released from jail.", pname, playerid);
		SendClientMessageToAll(Col_LightOrange, formatted);
		SetPlayerInterior(playerid, 6);
		SetPlayerPos(playerid, 264.0510,82.0633,1001.0391);
		return 1;
	}
	SetPVarInt(playerid, "active punish", 0);
	SetPlayerHealth(playerid, pPun[playerid][healthbefore]);
	KillTimer(pPun[playerid][timerid]);
	pPun[playerid][HackCounter] = 0;
	return 1;
}
forward adjailplayer(playerid, time, reason[]);
public adjailplayer(playerid, time, reason[]){
	new pname[MAX_PLAYER_NAME], formatted[128], Float:phealth;
	GetPlayerHealth(playerid, phealth);
	if (phealth <= 100) pPun[playerid][healthbefore] = phealth;
	SetPlayerTeam(playerid, 1);
	SetPlayerHealth(playerid, 99999);
	SetPlayerWantedLevel(playerid, 0);
	SetPlayerColor(playerid, 0xFFFFFFFF);
	pPun[playerid][needjail] = true;
	SetPVarInt(playerid, "active punish", 1);
	ResetPlayerWeapons(playerid);
	SetPlayerInterior(playerid, 6);
	SetPlayerPos(playerid,264.7426,77.7752,1001.0391);
	pPun[playerid][jailtime] = time;
	GetPlayerName(playerid,pname,MAX_PLAYER_NAME);
	format(formatted, 128, "%s has been jailed for %i seconds for %s.", pname, time, reason);
	SendClientMessageToAll(Col_Yellow, formatted);
	TogglePlayerControllable(playerid, 1);
	KillTimer(pPun[playerid][timerid]);
	pPun[playerid][timerid] = SetTimerEx("timercheck", 1000, true, "i", playerid);
}
forward adjailplayerinternal(playerid, time, internalmsg);
public adjailplayerinternal(playerid, time, internalmsg){
	new tempstring[30];
	switch (internalmsg){
		case 0: tempstring = "leaving in jail";
	}
	adjailplayer(playerid, time, tempstring);
	return 1;
}
stock adfrplayer(target, time)
{
	new Float:phealth;
	GetPlayerHealth(target, phealth);
	if (phealth <= 100) pPun[target][healthbefore] = phealth;
	SetPlayerHealth(target, 99999);
	TogglePlayerControllable(target, 0);
	pPun[target][frtime] = time;
	SetPVarInt(target, "active punish", 1);
	KillTimer(pPun[target][timerid]);
	pPun[target][timerid] = SetTimerEx("timercheck", 1000, true, "i", target);
	return 1;
}
forward KickF(playerid);
public KickF(playerid)
{
	Kick(playerid);
	return true;
}
public OnFilterScriptInit()
{
	print("\n--------------------------------------");
	print(" Admin CMDS Filterscript by Bar Harel");
	print("--------------------------------------\n");
	for (new i = 0; i < MAX_PLAYERS; i++){//initialize
		pPun[i][reporter] = -1;
		pPun[i][timerid] = -1;
		pPun[i][responderid] = -1;
		pPun[i][askerid] = -1;
	}
	//Anti-Hack timer
	SetTimer("HackCheck", 4132, true);
	return 1;
}

public OnFilterScriptExit()
{
	return 1;
}

stock SendToAdmins(color, level, text[]){
	foreach (new i : Player){
	    if (GetPVarInt(i, "Admin") >= level){
	        SendClientMessage(i, color, text);
     	}
    }
    return 1;
}
public OnLookupComplete(playerid)
{
	if(proxystate==true && IsProxyUser(playerid))
	{
		Kick(playerid);
		return 0;
	}
	return 1;
}
public OnPlayerConnect(playerid)
{
	new pIP[16];
	GetPlayerIp(playerid, pIP, 16);
	if(strcmp(pIP, LastIP) == 0) IPamount++;
	else IPamount = 0;
	LastIP = pIP;
	if (IPamount == 8 || (proxystate=true && IsProxyUser(playerid)))
	{
		new formatted[30];
		format(formatted, 30, "banip %s", pIP);
		SendRconCommand(formatted);
		Kick(playerid);
		return 0;
	}
	ResetPlayerWeapons(playerid); //For anti-hacks
	ResetPlayerMoney(playerid);
	if(fexist(Path(playerid))) INI_ParseFile(Path(playerid),"loadaccount_%s", .bExtra = true, .extra = playerid); //Will load user's data using INI_Parsefile.
    return 1;
}
public OnPlayerText(playerid, text[])
{
	if(pPun[playerid][muted]){
		SendClientMessage(playerid, Col_Red, "You are muted.");
		return 0;
	}
	if (pPun[playerid][ticks] > GetTickCount()){
		SendClientMessage(playerid, Col_Red, "Slow down cowboy, please wait a little between messages.");
		/* pPun[playerid][muted] = true;
		new pname[MAX_PLAYER_NAME], formatted[128];
		GetPlayerName(playerid,pname,MAX_PLAYER_NAME);
		BanReason = "Spamming (autoban)";
		SetTimerEx("BanExF", 1000, false, "i", playerid);
		for (new i; i < 100; i++) SendClientMessageToAll(0xFFFFFF00, " ");
		format(formatted, 128, "%s has been banned for spamming.", pname);
		SendClientMessageToAll(Col_Red, formatted);
		SendClientMessage(playerid, Col_Pink, "Think you were banned unfairly? Post an unban request at gcnr.tk"); */
		return 0;
	}
	pPun[playerid][ticks] = GetTickCount() + 255;
	return 1;
}
public OnPlayerCommandReceived(playerid, cmdtext[]){
	if (pPun[playerid][ticks] > GetTickCount()){
		SendClientMessage(playerid, Col_Red, "Slow down cowboy, please wait a little between commands.");
		/* pPun[playerid][muted] = true;
		new pname[MAX_PLAYER_NAME], formatted[128];
		GetPlayerName(playerid,pname,MAX_PLAYER_NAME);
		BanReason = "Spamming (autoban)";
		SetTimerEx("BanExF", 1000, false, "i", playerid);
		for (new i; i < 100; i++) SendClientMessageToAll(0xFFFFFF00, " ");
		format(formatted, 128, "%s has been banned for spamming.", pname);
		SendClientMessageToAll(Col_Red, formatted);
		SendClientMessage(playerid, Col_Pink, "Think you were banned unfairly? Post an unban request at gcnr.tk"); */
		return 0;
	}
	pPun[playerid][ticks] = GetTickCount() + 205;
	return 1;
}
public OnPlayerGiveDamage(playerid, damagedid, Float:amount, weaponid)
{
	if (ServerFreezeActive && GetPVarInt(playerid, "Admin") > 3 && GetPVarInt(damagedid, "active punish") != 1) adjailplayer(damagedid, 160, "Severe Deathmatch");
	return 1;
}
public OnPlayerSpawn(playerid){
	if (pPun[playerid][frtime] == -2){ //-2 is punish evading.
		pPun[playerid][frtime] = 0;
		SetTimerEx("adjailplayerinternal", 6000, false, "iii", playerid, 300, 0);
	}
	pPun[playerid][alive] = true;
	return 1;
}
public OnRconLoginAttempt(ip[], password[], success)
{
	if(!success){
		new pip[16];
		foreach (new i : Player) //Loop through all players
		{
			GetPlayerIp(i, pip, sizeof(pip));
			if(!strcmp(ip, pip, true)) //If a player's IP is the IP that failed the login
			{
				SendClientMessage(i, 0xFFFFFFFF, "oops."); //Send a message
				SetTimerEx("KickF", 1000, false, "i", i);
			}
		}
	}
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) return 0;

public OnPlayerDisconnect(playerid, reason)
{
	if (pPun[playerid][duty3d]) Delete3DTextLabel(pPun[playerid][duty3did]), pPun[playerid][duty3d] = false;
	KillTimer(pPun[playerid][mutedtimer]);
	KillTimer(pPun[playerid][timerid]);
	if (pPun[playerid][jailtime] > 1) pPun[playerid][frtime] = -2;//>1 is NOT a mistake! used for /adunjail and /unfr
	if(fexist(Path(playerid))){ //To avoid creating blank
		new INI:file = INI_Open(Path(playerid)); //will open their file
		INI_SetTag(file,"Punish Data");//We will set a tag inside of user's account called "Player's Data"
		INI_WriteInt(file, "frtime", pPun[playerid][frtime]); //frtime -2 means player evaded punishment
		INI_WriteBool(file, "undercoveredacc", pPun[playerid][undercovered]); //Save an account undercovered state
		INI_WriteInt(file, "fakelevel", pPun[playerid][fakeadmin]); //Save an account undercovered state
		INI_WriteInt(file, "Warns", pPun[playerid][warns]); //Save an account undercovered state
		INI_WriteInt(file, "LastWarn", pPun[playerid][warntime]); //Save an account undercovered state
		INI_Close(file);//Now after we've done saving their data, we now need to close the file
	}
	pPun[playerid][reporter] = -1;
	pPun[playerid][jailtime] = 0;
	pPun[playerid][frtime] = 0;
	if (pPun[playerid][responderid] > -1) {
		SendClientMessage(pPun[playerid][responderid], Col_Green, "Question was closed due to the player leaving.");
		pPun[pPun[playerid][responderid]][askerid] = -1;
	}
	if (pPun[playerid][askerid] > -1) {
		SendClientMessage(pPun[playerid][askerid], Col_Green, "Question is being transferred to a different admin.");
		pPun[pPun[playerid][askerid]][responderid] = -2;
	}
	pPun[playerid][askerid] = -1;
	pPun[playerid][responderid] = -1;
	pPun[playerid][stealth] = false;
	pPun[playerid][specialpriv] = false;
	pPun[playerid][muted] = false;
	pPun[playerid][undercovered] = false;
	pPun[playerid][alive] = false;
	pPun[playerid][fakeadmin] = 0;
	pPun[playerid][warns] = 0;
	pPun[playerid][warntime] = 0;
	pPun[playerid][HackCounter] = 0;
	return 1;
}
COMMAND:adcmds(playerid, params[])
{
	new target, adlevel = GetPVarInt(playerid, "Admin");
	if (adlevel < 1) return 0;
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /adcmds [rank (1-5)]");
	if (adlevel < target) return SendClientMessage(playerid, Col_Red, "You do not have the permission to view these commands.");
	switch(target){
		case 1:
		{
			new string[396] = "/check\t\tView Questions\n/adtake\t\tTake a question\n/aduntake\tRelease a question\n/adr\t\tRespond to question\n/adclose\tClose a question\n/adann\t\tAnnounce a template message as an admin\n/adannc\t\tAnnounce a custom message as an admin\n/cc\t\tClear the chat\n/adpm\t\tSend an admin PM\n/admsg\t\tSend an admin-channel message\n/adunlock\tUnlock a vehicle\n/adslap\t\tSlap a player";
			ShowPlayerDialog(playerid, dialogs:Dialog_adcmds, 0, "Available Commands for admin level 1:", string, "OK", "");
		}
		case 2:
		{
			new string[590] = "/check\t\tView reports and Questions\n/cr\t\tClear a report\n/ad(un)fr\tFreeze or Unfreeze a player\n/ad(un)jail\tJail or Unjail a player\n/ad(un)mute\tMute or Unmute a player\n/adrules\tForce a player to read the rules\n/adspec\t\tSpectate a player\n/specoff\tStop spectating\n/adstealth\tToggle stealth mode\n/adfakepromote\tUse this against rank beggers\n/adfakedemote\tTo cancel the promotion";
			strcat(string, "\n/goto\t\tGo to a player\n/bring\t\tBring a player\n/return\t\tReturn after /goto");
			ShowPlayerDialog(playerid, dialogs:Dialog_adcmds, 0, "Available Commands for admin level 2:", string, "OK", "");
		}
		case 3:
		{
			new string[550] = "/adkick\t\tKick a player\n/adon\t\tEnter admin mode\n/adoff\t\tExit admin mode\n/adspawnv\tSpawn an admin vehicle\n/addestroy\tDestroy the current vehicle\n/adwep\t\tGive a player weapons\n/adfix\t\tFix a player's vehicle\n/adheal\t\tHeal a player\n/adkill\t\tKill a player\n/adcash\t\tGive a player money\n/jetpack\t\tToggles a jetpack\n/adwanted\tAdd/reduce wanted level.\n/ad(un)warn\t(Un)warn a player.";
			strcat(string, "\n/adtime\t\tChange game time\n/adtag\t\tToggle player's tag\n/adfuel\t\tRestore a vehicle's fuel\n/addisarm\tDisarm a player");
			ShowPlayerDialog(playerid, dialogs:Dialog_adcmds, 0, "Available Commands for admin level 3:", string, "OK", "");
		}
		case 4:
		{
			new string[700] = "/ad(fake)ban\t(Fake) Ban a player permanently\n/adtimeban\tBan a player by time\n/adunban\tUnban a player\n/adipban\tBan a player's IP\n/adspawnperm\tSpawn a normal vehicle\n/adinfo\t\tSee a player's info\n/adseepms\tToggle to see PMs\n/addestroyall\tClear all vehicles\n/ads(un)fr\tFreeze or Unfreeze the entire server.\n/createh\tCreate a house.\n/createx\tCreate a house exit.\n/deleteh\tDelete a house\n/setowner\tChange house owner.";
			strcat(string, "\n/adresethcount\tReset house count and show IDs\n/gotoh\t\tGo to a house\n/adforcetake\tForce take a question from an admin\n/adname\tChange a player's name\n/adblow\t\tCreate an explosion at player position\n/adresetpass\tReset a player's password\n/adresetspawn\tReset a player's spawn location.");
			ShowPlayerDialog(playerid, dialogs:Dialog_adcmds, 0, "Available Commands for admin level 4:", string, "OK", "");
		}
		case 5:
		{
			new string[590] = "/adpromote\tPromote a player\n/addemote\tDemote a player\n/adrestart\tRestart the server\n/adexit\t\tClose the server\n/adrangeban\tRange ban a player (least blocks please)\n/adipdban\tIP ban a player and delete his account\n/adcover\tToggle an account undercovered state\n/adwhitelist\tPlayer is able to evade IP bans.\n/addeleteacc\tDelete your account (Good for undercovered)\n/adclearpass\tClear a player's password\n/proxystate\tCheck for proxy blocking";
			strcat(string, "\n/blockproxy\tBlock all proxy connections\n/unblockproxy\tUnblock proxy connections");
			ShowPlayerDialog(playerid, dialogs:Dialog_adcmds, 0, "Available Commands for admin level 5:", string, "OK", "");
		}
		default: SendClientMessage(playerid, Col_Red, "That rank doesn't exist.");
	}
	return 1;
}
COMMAND:report(playerid, params[])
{	
	new target, reason[128], formatted[128];
	if (sscanf(params, "is[128]", target, reason)) return SendClientMessage(playerid, Col_Red, "USAGE: /report [id] [reason]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	if (pPun[target][reporter] != -1) return SendClientMessage(playerid, Col_Red, "Player has already been reported. Please wait for admins to review the case.");
	pPun[target][reporter] = playerid;
	format(formatted, 128, "ID: %d has been reported by ID: %d for %s.", target, playerid, reason);
	SendToAdmins(0xf2c14cff, 2, formatted);
	format(reason,127,"%s",reason);
	SetPVarString(target, "ReportReason", reason);
	print("New report.");
	SendClientMessage(playerid,0xf2c14cff, "Thanks for reporting. Please wait patiently while admins review your report.");
	return 1;
}
COMMAND:adsfr(playerid)
{
	if (GetPVarInt(playerid, "Admin") < 4) return 0;
	SendClientMessageToAll(Col_Yellow, "***ADMIN SERVER FREEZE***");
	foreach (new i : Player) TogglePlayerControllable(i, 0);
	ServerFreezeActive = true;
	TogglePlayerControllable(playerid, 1);
	GivePlayerWeapon(playerid, 22, 100);
	SetPlayerSpecialAction(playerid, SPECIAL_ACTION_USEJETPACK);
	return 1;
}
COMMAND:adsunfr(playerid)
{
	if (GetPVarInt(playerid, "Admin") < 4) return 0;
	SendClientMessageToAll(Col_Yellow, "***ADMIN SERVER UNFREEZE***");
	foreach (new i : Player) TogglePlayerControllable(i, 1);
	ServerFreezeActive = false;
	if(GetPlayerSpecialAction(playerid) == SPECIAL_ACTION_USEJETPACK) SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);
	return 1;
}
COMMAND:adkill(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 3) return 0;
	new target, pname[MAX_PLAYER_NAME], formatted[128];
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /adkill [player ID]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	GetPlayerName(target, pname, MAX_PLAYER_NAME);
	SetPlayerHealth(target, 0);
	format(formatted, 128, "%s(%d) has been killed by an admin.", pname, target);
	SendClientMessageToAll(Col_Yellow, formatted);
	return 1;
}
COMMAND:goto(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 2) return 0;
	new target;
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /goto [player ID]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	CallRemoteFunction("SGPlayerPos", "ii", playerid, 1);
	new i;
	new Float:temppos[3];
	GetPlayerPos(target, temppos[0], temppos[1], temppos[2]);
	i = GetPlayerInterior(target);
	if(IsPlayerInAnyVehicle(playerid) == 1 && i == 0){
		new vid = GetPlayerVehicleID(playerid);
		SetVehiclePos(vid, temppos[0]+2, temppos[1]+2, temppos[2]+2);
		SetVehicleVirtualWorld(vid, GetPlayerVirtualWorld(target));
		SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(target));
	}else{
		SetPlayerInterior(playerid, i);
		SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(target));
		SetPlayerPos(playerid, temppos[0]+0.1, temppos[1]+0.1, temppos[2]+0.3);
	}
	return 1;
}
COMMAND:return(playerid)
{
	if (GetPVarInt(playerid, "Admin") < 2) return 0;
	CallRemoteFunction("SGPlayerPos", "ii", playerid, 0);
	return 1;
}
COMMAND:bring(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 2) return 0;
	new target;
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /bring [player ID]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	pPun[target][specialpriv] = true;
	CallRemoteFunction("AddHackCounter", "ii", target, -1);
	new i, Float:temppos[3];
	GetPlayerPos(playerid, temppos[0], temppos[1], temppos[2]);
	i = GetPlayerInterior(playerid);
	if(IsPlayerInAnyVehicle(target) == 1 && i == 0){
		SetVehiclePos(GetPlayerVehicleID(target), temppos[0]+2, temppos[1]+2, temppos[2]+2);
	}else{
		SetPlayerInterior(target, i);
		SetPlayerPos(target, temppos[0]+0.1, temppos[1]+0.1, temppos[2]+0.3);
	}
	return 1;
}
COMMAND:adfix(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 3) return 0;
	new target;
	if(sscanf(params, "I(-1)", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /adfix [ID]");
	if (target == -1) {
		RepairVehicle(GetPlayerVehicleID(playerid));
		SendClientMessage(playerid, Col_Green, "Vehicle fixed.");
	}else{
		if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
		if (GetPlayerVehicleID(target) == 0) return SendClientMessage(playerid, Col_Red, "Player is not in a vehicle.");
		RepairVehicle(GetPlayerVehicleID(target));
		SendClientMessage(playerid, Col_Green, "Vehicle fixed.");
		SendClientMessage(target, Col_Green, "Your vehicle has been fixed by an admin.");
	}
	return 1;
}
COMMAND:adunlock(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 1) return 0;
	new vehicleid;
	if (sscanf(params, "i", vehicleid)) return SendClientMessage(playerid, Col_Red, "USAGE: /adunlock (vehicle ID). You can see the vehicle ID using /dl.");
	if (!IsValidVehicle(vehicleid)) return SendClientMessage(playerid, Col_Red, "Wrong ID: Invalid vehicle ID.");
	SetVehicleParamsForPlayer(vehicleid, playerid, 0, 0);
	SendClientMessage(playerid, Col_Green, "You have unlocked that vehicle for yourself. Enter and Exit to unlock for all.");
	return 1;
}
COMMAND:adstealth(playerid)
{
	if (GetPVarInt(playerid, "Admin") < 2) return 0;
	if (pPun[playerid][undercovered]) return SendClientMessage(playerid, Col_Red, "This is an undercovered account.");
	if (pPun[playerid][stealth]){
		pPun[playerid][stealth] = false;
		SendClientMessage(playerid, Col_Red, "Stealth mode deactivated");
	}else {
		pPun[playerid][stealth] = true;
		SendClientMessage(playerid, Col_Green, "Stealth mode activated");
	}
	return 1;
}
COMMAND:admins(playerid)
{
	SendClientMessage(playerid, Col_Green, "Admins online:");
	new formatted[128], pname[MAX_PLAYER_NAME], totalonline=0;
	if (pPun[playerid][fakeadmin] > 0) {
		GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
		format(formatted, 128, "%s(%d) - Level %d", pname, playerid, pPun[playerid][fakeadmin]);
		SendClientMessage(playerid, Col_LightBlue, formatted);
		totalonline++;
	}
	foreach (new i : Player){
	    if (GetPVarInt(i, "Admin") > 0 && ((pPun[i][stealth] != true && pPun[i][undercovered] != true) || GetPVarInt(playerid, "Admin") > 4)){
			GetPlayerName(i, pname, MAX_PLAYER_NAME);
			format(formatted, 128, "%s(%d) - Level %d%s", pname, i, GetPVarInt(i, "Admin"), (pPun[i][undercovered]) ? (" (Undercovered)") : (""));
			SendClientMessage(playerid, Col_LightBlue, formatted);
			totalonline++;
     	}
    }
	format(formatted, 128, "Total admins online: %i", totalonline);
	SendClientMessage(playerid, Col_Green, formatted);
	return 1;
}
COMMAND:adcover(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 5 && !IsPlayerAdmin(playerid)) return 0;
	new target;
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /adcover [player ID]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	if (!pPun[target][undercovered]){
		if (GetPVarInt(target, "Admin") < 1) SendClientMessage(playerid, Col_Orange, "WARNING: target player is NOT an admin.");
		pPun[target][undercovered] = true;
		SendClientMessage(playerid, Col_Green, "Target player is now undercovered.");
	}else{
		pPun[target][undercovered] = false;
		SendClientMessage(playerid, Col_Red, "Target player is no longer undercovered.");
	}
	return 1;
}
COMMAND:cr(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 2) return 0;
	new target;
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /clearreport [reported player ID]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	if (pPun[target][reporter] == -1) return SendClientMessage(playerid, Col_Red, "Player is not reported.");
	pPun[target][reporter] = -1;
	SendClientMessage(playerid, Col_Green, "Report cleared.");
	return 1;
}
COMMAND:adwarn(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 3) return 0;
	new target, reason[128], formatted[128], pname[MAX_PLAYER_NAME];
	if (sscanf(params, "iS(exccesive deathmatching)[128]", target, reason)) return SendClientMessage(playerid, Col_Red, "USAGE: /adwarn [Player ID] [Reason - default 'exccesive deathmatching']");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	if (pPun[target][warntime] < gettime()) pPun[target][warns] = 0;
	pPun[target][warns]++;
	GetPlayerName(target, pname, MAX_PLAYER_NAME);
	format(formatted, 128, "%s(%d) has been warned (%d/3) for %s.", pname, target, pPun[target][warns], reason);
	SendClientMessageToAll(Col_Red, formatted);
	if (pPun[target][warns] >= 3)
	{
		format(formatted, 128, "%s(%d) has been auto-banned for 3 days for having over 3 warnings.", pname, target);
		SendClientMessageToAll(Col_Red, formatted);
		BanPlayer(-1, target, "over 3 warnings", 259200);
	}
	pPun[target][warntime] = gettime() + 2592000; //30 days
	return 1;
}
COMMAND:adunwarn(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 3) return 0;
	new target;
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /adunwarn [Player ID]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	if (pPun[target][warntime] < gettime()) pPun[target][warns] = 0;
	if (pPun[target][warns] == 0) return SendClientMessage(playerid, Col_Red, "Player does not have any warning.");
	pPun[target][warns]--;
	SendClientMessage(playerid, Col_Green, "Warning removed.");
	SendClientMessage(target, Col_Green, "An admin has removed a warning from your account.");
	return 1;
}
COMMAND:jetpack(playerid)
{
	if (GetPVarInt(playerid, "Admin") < 3) return 0;
	if(GetPlayerSpecialAction(playerid) == SPECIAL_ACTION_USEJETPACK) SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);
	else if(GetPlayerSpecialAction(playerid) == SPECIAL_ACTION_NONE) SetPlayerSpecialAction(playerid, SPECIAL_ACTION_USEJETPACK);
	else SendClientMessage(playerid, Col_Red, "You can't use a jetpack while inside an animation.");
	return 1;
}
COMMAND:admute(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 2) return 0;
	new target, time, pname[MAX_PLAYER_NAME], formatted[128];
	if (sscanf(params, "iI(120)", target, time)) return SendClientMessage(playerid, Col_Red, "USAGE: /admute [playerid] [time - default 120 seconds]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	if (pPun[target][muted]) return SendClientMessage(playerid, Col_Red, "Player is already muted.");
	pPun[target][muted] = true;
	pPun[target][mutedtimer] = SetTimerEx("unmutetimer", time*1000, false, "i", target);
	GetPlayerName(target, pname, MAX_PLAYER_NAME);
	format(formatted, 128, "%s(%d) has been muted for %d seconds.", pname, target, time);
	SendClientMessageToAll(Col_Yellow, formatted);
	return 1;
}
COMMAND:addisarm(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 3) return 0;
	new target;
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /addisarm [playerid]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	ResetPlayerWeapons(target);
	SendClientMessage(playerid, Col_Green, "Player has been disarmed.");
	SendClientMessage(target, Col_Pink, "You have been disarmed by an admin.");
	return 1;
}
COMMAND:adunmute(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 2) return 0;
	new target;
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /adunmute [playerid]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	if (!pPun[target][muted]) return SendClientMessage(playerid, Col_Red, "Player is not muted.");
	SendClientMessage(playerid, Col_Green, "Player has been unmuted.");
	SendClientMessage(target, Col_Yellow, "You have been unmuted.");
	pPun[target][muted] = false;
	KillTimer(pPun[target][mutedtimer]);
	return 1;
}
COMMAND:check(playerid)
{
	if (GetPVarInt(playerid, "Admin") < 1) return 0;
	new formatted[128], pname[MAX_PLAYER_NAME];
	if (GetPVarInt(playerid, "Admin") > 1){
		SendClientMessage(playerid,0xf2c14cff, "Open Reports:");
		foreach (new i : Player){
			if(pPun[i][reporter] != -1){
				GetPVarString(i, "ReportReason", formatted, 127);
				format(formatted, 128, "ID: %d has been reported by ID: %d for %s.", i, pPun[i][reporter], formatted);
				SendClientMessage(playerid,0xe9c14cff, formatted);
			}
		}
	}
	SendClientMessage(playerid,Col_LightBlue, "Open Questions:");
	foreach (new i : Player){
		if(pPun[i][responderid] != -1){
			GetPVarString(i, "Question", formatted, 127);
			GetPlayerName(i, pname, MAX_PLAYER_NAME);
			format(formatted, 128, "%s(%d) asked: %s", pname, i, formatted);
			if (pPun[i][responderid] != -2) strcat(formatted, " *Taken*");
			SendClientMessage(playerid,Col_LightBlue, formatted);
		}
	}
	return 1;
}
COMMAND:adann(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 1) return 0;
	new message[128], formatted[128];
	if (sscanf(params, "s[128]", message)) return SendClientMessage(playerid, Col_Red, "USAGE: /adann [template]. Use /adannc for a custom message.");
	if (!strcmp(message, "dm", true)) message = "As a reminder, GCnR is NOT a deathmatch server. Please read /rules before playing.";
	else if (!strcmp(message, "ask", true)) message = "Got a question to ask? Please use /ask and a staff member will assist you shortly.";
	else if (!strcmp(message, "report", true)) message = "Is there a player hacking, spamming or DMing? /report him and we'll take care of the rest.";
	else{
		SendClientMessage(playerid, Col_Red, "Available templates:");
		SendClientMessage(playerid, Col_Red, "DM - For DM announcement");
		SendClientMessage(playerid, Col_Red, "ask - For reminding players how to ask questions");
		SendClientMessage(playerid, Col_Red, "report - For reminding players how to report players");
		return 1;
	}
	format(formatted, 128, "Announcement: %s", message);
	SendClientMessageToAll(Col_LightBlue, formatted);
	return 1;
}
COMMAND:adannc(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 1) return 0;
	new message[128], formatted[128];
	if (sscanf(params, "s[128]", message)) return SendClientMessage(playerid, Col_Red, "USAGE: /adannc [message]");
	format(formatted, 128, "Admin: %s", message);
	SendClientMessageToAll(Col_LightBlue, formatted);
	return 1;
}
COMMAND:adfr(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 2) return 0;
	new target, formatted[128], pname[MAX_PLAYER_NAME], reason[128];
	if (sscanf(params, "dS(deathmatching)[128]", target, reason)) return SendClientMessage(playerid, Col_Red, "USAGE: /adfr [playerid] [reason - default deathmatching]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	GetPlayerName(target,pname,MAX_PLAYER_NAME);
	format(formatted, 128, "%s has been frozen for 15 seconds. Reason: %s. Please read /rules.", pname, reason);
	SendClientMessageToAll(Col_Yellow, formatted);
	adfrplayer(target, 15);
	return 1;
}
COMMAND:admsg(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 1) return 0;
	new message[128], formatted[128], pname[MAX_PLAYER_NAME];
	if (sscanf(params, "s[128]", message)) return SendClientMessage(playerid, Col_Red, "USAGE: /admsg [message]");
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	format(formatted, 128, "(admsg) %s(%d): %s", pname, playerid, message); 
	SendToAdmins(Col_LightOrange, 1, formatted);
	return 1;
}
COMMAND:ask(playerid, params[])
{
	new message[128], formatted[128], pname[MAX_PLAYER_NAME];
	if (sscanf(params, "s[128]", message)) return SendClientMessage(playerid, Col_Red, "USAGE: /ask [message]");
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	switch (pPun[playerid][responderid])
	{
		case -1:
		{
			format(formatted, 128, "Question: %s", message);
			SendClientMessage(playerid, Col_LightBlue, formatted);
			SendClientMessage(playerid, Col_LightBlue, "Please wait patiently for an admin to take you call.");
			format(formatted, 128, "%s(%d) asks: %s", pname, playerid, message); 
			SendToAdmins(Col_LightBlue, 1, formatted);
			SetPVarString(playerid, "Question", message);
			pPun[playerid][responderid] = -2;
			
		}
		case -2: 
		{
			SendClientMessage(playerid, Col_LightBlue, "You have already asked a question, please wait for an admin to respond.");
			format(formatted, 128, "%s(%d) tried to ask a question but already has one in queue.", pname, playerid); 
			SendToAdmins(Col_LightBlue, 1, formatted);
			
		}
		default:
		{
			format(formatted, 128, "%s(%d) to Admin: %s", pname, playerid, message); 
			SendClientMessage(playerid, Col_LightBlue, formatted);
			SendClientMessage(pPun[playerid][responderid], Col_LightBlue, formatted);
			
		}
	}		
	return 1;
}
COMMAND:adtake(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 1) return 0;
	if (pPun[playerid][askerid] != -1) return SendClientMessage(playerid, Col_Red, "You already have a question.");
	new target;
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /adtake [playerid]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	if (pPun[target][responderid] == -1) return SendClientMessage(playerid, Col_Red, "Wrong ID: Player did not ask a question.");
	if (pPun[target][responderid] != -2) return SendClientMessage(playerid, Col_Red, "Someone has already taken that question.");
	SendClientMessage(playerid, Col_Green, "You have taken that question.");
	SendClientMessage(target, Col_Green, "Your question is being reviewed by an admin. Use /ask to respond.");
	pPun[target][responderid] = playerid;
	pPun[playerid][askerid] = target;
	return 1;
}
COMMAND:adforcetake(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 4) return 0;
	if (pPun[playerid][askerid] != -1) return SendClientMessage(playerid, Col_Red, "You already have a question.");
	new target;
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /adtake [playerid]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	if (pPun[target][responderid] == -1) return SendClientMessage(playerid, Col_Red, "Wrong ID: Player did not ask a question.");
	if (pPun[target][responderid] == -2) return SendClientMessage(playerid, Col_Red, "Question was not taken, no need to force-take.");
	SendClientMessage(playerid, Col_Green, "You have force taken that question.");
	SendClientMessage(target, Col_Green, "Your question has been transferred to a different admin.");
	SendClientMessage(pPun[target][responderid], Col_Green, "Your question was forcely taken by a different admin.");
	pPun[pPun[target][responderid]][askerid] = -1;
	pPun[target][responderid] = playerid;
	pPun[playerid][askerid] = target;
	return 1;
}
COMMAND:adclose(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 1) return 0;
	new target;
	if (sscanf(params, "I(-1)", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /adclose [asker ID] By default, it will close your currently taken question.");
	if (target == -1 || pPun[target][responderid] == playerid){
		if (pPun[playerid][askerid] == -1) return SendClientMessage(playerid, Col_Red, "You did not take any question. /adclose [asker ID] to close untaken questions.");
		SendClientMessage(playerid, Col_Green, "You have closed the question.");
		SendClientMessage(pPun[playerid][askerid], Col_Green, "The admin has marked the question as solved.");
		SendClientMessage(pPun[playerid][askerid], Col_Green, "Got another question? Don't hesitate to /ask!");
		pPun[pPun[playerid][askerid]][responderid] = -1;
		pPun[playerid][askerid] = -1;
	}else{
		if (pPun[target][responderid] == -1) return SendClientMessage(playerid, Col_Red, "Player did not ask any question.");
		else if (pPun[target][responderid] != -2) {
			if (GetPVarInt(playerid, "Admin") < 4) return SendClientMessage(playerid, Col_Red, "The question has been taken by an admin.");
			else return SendClientMessage(playerid, Col_Red, "The question has been taken by an admin. Try /adforcetake first.");
		}
		SendClientMessage(playerid, Col_Green, "You have closed the question.");
		SendClientMessage(target, Col_Green, "An admin has closed your question.");
		SendClientMessage(target, Col_Green, "Still have a question? Don't hesitate to /ask!");
		pPun[target][responderid] = -1;
	}
	return 1;
}
COMMAND:aduntake(playerid)
{
	if (GetPVarInt(playerid, "Admin") < 1) return 0;
	if (pPun[playerid][askerid] < 0) return SendClientMessage(playerid, Col_Red, "You do not have any question to transfer.");
	SendClientMessage(pPun[playerid][askerid], Col_Green, "Question is being transferred to a different admin.");
	new pname[MAX_PLAYER_NAME], formatted[128];
	GetPlayerName(pPun[playerid][askerid] , pname, MAX_PLAYER_NAME);
	format(formatted, 128, "%s(%d) question has re-opened.", pname, pPun[playerid][askerid]); 
	pPun[pPun[playerid][askerid]][responderid] = -2;
	pPun[playerid][askerid] = -1;
	SendClientMessage(playerid, Col_Green, "You have re-opened that question.");
	SendToAdmins(Col_LightBlue, 1, formatted);
	return 1;
}
COMMAND:adr(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 1) return 0;
	new message[128], pname[MAX_PLAYER_NAME], formatted[128];
	if (sscanf(params, "s[128]", message)) return SendClientMessage(playerid, Col_Red, "USAGE: /adr [message]");
	if (pPun[playerid][askerid] == -1) return SendClientMessage(playerid, Col_Red, "You did not take any question. Use /adtake.");
	GetPlayerName(pPun[playerid][askerid], pname, MAX_PLAYER_NAME);
	format(formatted, 128, "Admin to %s(%d): %s", pname, pPun[playerid][askerid], message); 
	SendClientMessage(pPun[playerid][askerid], Col_LightBlue, formatted);
	SendClientMessage(playerid, Col_LightBlue, formatted);
	return 1;
}
COMMAND:adpm(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 1) return 0;
	new message[128], formatted[128], pname[MAX_PLAYER_NAME], target;
	if (sscanf(params, "is[128]", target, message)) return SendClientMessage(playerid, Col_Red, "USAGE: /adpm [playerid] [message]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	GetPlayerName(target, pname, MAX_PLAYER_NAME);
	format(formatted, 128, "Admin PM to %s(%d): %s", pname, target, message); 
	SendClientMessage(playerid, Col_LightBlue, formatted);
	format(formatted, 128, "Admin PM: %s", message);
	SendClientMessage(target, Col_LightBlue, formatted);
	return 1;
}
COMMAND:adunfr(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 2) return 0;
	new target;
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /adunfr [playerid]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	pPun[target][frtime] = 1;
	SetPlayerSpecialAction(target, SPECIAL_ACTION_NONE);
	return 1;
}
COMMAND:adjail(playerid, params[])
{	
	if (GetPVarInt(playerid, "Admin") < 2) return 0;
	new target, reason[128], time;
	if (sscanf(params, "iI(60)S(deathmatching)[128]", target, time, reason)) return SendClientMessage(playerid, Col_Red, "USAGE: /adjail [playerid] [time (def - 60)] [reason - default deathmatching]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	strcat(reason, ". Please read /rules");
	adjailplayer(target, time, reason);
	return 1;
}
COMMAND:adheal(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 3) return 0;
	new target;
	if(sscanf(params, "I(-1)", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /adheal [ID]");
	if (!IsPlayerConnected(target) && target != -1) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	if (target == -1) SetPlayerHealth(playerid, 100);
	else {
		SetPlayerHealth(target, 100);
		SendClientMessage(target, Col_Green, "You have been healed by an admin.");
	}
	SendClientMessage(playerid, Col_Green, "Player had been healed.");
	return 1;
}
COMMAND:adunjail(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 2) return 0;
	new target;
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /adunjail [playerid]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	if (pPun[target][jailtime] > 1){
		CallRemoteFunction("SetPlayerOCT", "i", playerid);
		SendClientMessage(target, Col_Yellow, "You have been unjailed.");
		SetPlayerInterior(target, 6);
		SetPlayerPos(target, 264.0510,82.0633,1001.0391);
		pPun[target][jailtime] = 0;
	}
	else{
		if (CallRemoteFunction("unjailp", "i", target) == 0) return SendClientMessage(playerid, Col_Red, "Player is not jailed");
	}
	SendClientMessage(playerid, Col_Green, "Player has been released from jail.");
	return 1;
}
COMMAND:adrules(playerid, params[]) //Force rules
{
	if(GetPVarInt(playerid, "Admin") < 2) return 0;
	new target, pname[MAX_PLAYER_NAME], formatted[128];
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /adrules [playerid]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	GetPlayerName(target, pname, MAX_PLAYER_NAME);
	format(formatted, 128, "%s(%d) has been frozen and forced to read the rules.", pname, target);
	SendClientMessageToAll(Col_Yellow, formatted);
	CallRemoteFunction("ShowRules", "d", target);
	adfrplayer(target, 20);
	return 1;
}
COMMAND:adkick(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 3) return 0;
	new target, formatted[128], reason[128], pname[MAX_PLAYER_NAME];
	if (sscanf(params, "is[128]", target, reason)) return SendClientMessage(playerid, Col_Red, "USAGE: /adkick [playerid] [reason]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	GetPlayerName(target,pname,MAX_PLAYER_NAME);
	format(formatted, 128, "%s has been kicked for %s.", pname, reason);
	SendClientMessageToAll(Col_Red, formatted);
	SetTimerEx("KickF", 1000, false, "i", target);
	return 1;
}
COMMAND:adban(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 4 && !IsPlayerAdmin(playerid)) return 0;
	new target, reason[128], pname[MAX_PLAYER_NAME];
	if (sscanf(params, "is[128]", target, reason)) return SendClientMessage(playerid, Col_Red, "USAGE: /adban [playerid] [reason]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	GetPlayerName(target, pname, MAX_PLAYER_NAME);
	if ((GetPVarInt(target, "Admin") > 2 && !IsPlayerAdmin(playerid) && GetPVarInt(playerid, "Admin") < 5) || !strcmp("[GCnR]GamEraser", pname)) return SendClientMessage(playerid, Col_Red, "Player is an admin!");
	BanPlayer(playerid, target, reason);
	return 1;
}
COMMAND:blockproxy(playerid)
{
	if (GetPVarInt(playerid, "Admin") < 5 && !IsPlayerAdmin(playerid)) return 0;
	proxystate = true;
	SendClientMessage(playerid,Col_Green, "Proxies are now blocked.");
	return 1;
}
COMMAND:unblockproxy(playerid)
{
	if (GetPVarInt(playerid, "Admin") < 5 && !IsPlayerAdmin(playerid)) return 0;
	proxystate = false;
	SendClientMessage(playerid,Col_Green, "Proxies are now unblocked.");
	return 1;
}
COMMAND:proxystate(playerid)
{
	if (GetPVarInt(playerid, "Admin") < 5 && !IsPlayerAdmin(playerid)) return 0;
	if (proxystate == false) SendClientMessage(playerid,Col_Green, "Proxies are currently unblocked.");
	else SendClientMessage(playerid,Col_Green, "Proxies are currently blocked.");
	return 1;
}
COMMAND:adwhitelist(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 5) return 0;
	new target[MAX_PLAYER_NAME], pname[MAX_PLAYER_NAME], formatted[128];
	if(sscanf(params, "s[24]", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /adwhitelist [player name]");
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	format(formatted, 128, "Whitelisted by: %s", pname);
	new File:Whitey = fopen(WhitePath(target));
	fwrite(Whitey, formatted);
	fclose(Whitey);
	format(formatted, 128, "%s has been whitelisted.", target);
	SendClientMessage(playerid, Col_Green, formatted);
	return 1;
}
COMMAND:adunban(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 4 && !IsPlayerAdmin(playerid)) return 0;
	new target[MAX_PLAYER_NAME], formatted[128];
	if (sscanf(params, "s[24]", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /adunban [player name]");
	format(formatted, 128, BanPathL, target);
	if (!fexist(formatted)) return SendClientMessage(playerid, Col_Red, "Ban file not found. Maybe he is IP banned or Range banned?");
	new File:BanFile = fopen(formatted, io_read), tempIP[21], tempS[128];
	fread(BanFile, tempS);
	fread(BanFile, tempIP);
	fclose(BanFile);
	fremove(formatted);
	strdel(tempIP, strlen(tempIP)-2, strlen(tempIP));
	if(fexist(IPBanPath(tempIP))) fremove(IPBanPath(tempIP));
	SendClientMessage(playerid, Col_Green, "Player has been unbanned.");
	return 1;
}
COMMAND:adfakeban(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 4 && !IsPlayerAdmin(playerid)) return 0;
	new target, formatted[128], reason[128], pname[MAX_PLAYER_NAME];
	if (sscanf(params, "is[128]", target, reason)) return SendClientMessage(playerid, Col_Red, "USAGE: /adfakeban [playerid] [reason]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	if (!pPun[target][muted]){
		pPun[target][muted] = true;
		pPun[target][mutedtimer] = SetTimerEx("unmutetimer", 60000, false, "i", target);
	}
	GetPlayerName(target,pname,MAX_PLAYER_NAME);
	format(formatted, 128, "%s has been permanently banned for %s.", pname, reason);
	SendClientMessageToAll(Col_Red, formatted);
	format(formatted, 128, "%s has left the server. (Kicked)", pname);
	SendClientMessageToAll(Col_Gray, formatted);
	return 1;
}
COMMAND:adtag(playerid, params[])
{
	if(GetPVarInt(playerid, "Admin") < 3) return 0;
	new target;
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /adtag [target]");
	new pname[MAX_PLAYER_NAME], formatted[256], File:oldn = fopen(Path(target), io_read), File:newn, oldpath[128]; //for file opener
	oldpath = Path(target);
	GetPlayerName(target, pname, MAX_PLAYER_NAME);
	if (!strcmp(pname, "[GCnR]", true, 6)){
		strdel(pname, 0, 6);
		format(formatted, 256, UserPath, pname);
		if (fexist(formatted)){
			fclose(oldn);
			return SendClientMessage(playerid, Col_Red, "Target file exists.");
		}
		newn = fopen(formatted, io_write);
		while(fread(oldn, formatted)) fwrite(newn, formatted);
		SetPlayerName(target, pname);
		SendClientMessage(playerid, Col_Green, "Tag removed.");
		fclose(oldn), fclose(newn);
		fremove(oldpath);
		SendClientMessage(target, Col_Red, "Your [GCnR] tag has been removed!");
	}else{
		if(strlen(pname) >= 14){
			fclose(oldn);
			return SendClientMessage(playerid, Col_Red, "Target name is too long.");
		}
		strins(pname, "[GCnR]", 0);
		format(formatted, 256, UserPath, pname);
		if (fexist(formatted)){
			fclose(oldn);
			return SendClientMessage(playerid, Col_Red, "Target file exists.");
		}
		newn = fopen(formatted, io_write);
		while(fread(oldn, formatted)) fwrite(newn, formatted);
		SetPlayerName(target, pname);
		SendClientMessage(playerid, Col_Green, "Tag added.");
		fclose(oldn), fclose(newn);
		fremove(oldpath);
		SendClientMessage(target, Col_Green, "You have received a [GCnR] tag!");
	}
	return 1;
}
COMMAND:adname(playerid, params[])
{
	if(GetPVarInt(playerid, "Admin") < 4) return 0;
	new target, newname[MAX_PLAYER_NAME];
	if (sscanf(params, "is[25]", target, newname)) return SendClientMessage(playerid, Col_Red, "USAGE: /adname [target] [name]");
	if (strlen(newname) > 20) return SendClientMessage(playerid, Col_Red, "New name is too long. (max 20 characters)");
	new formatted[256], File:oldn = fopen(Path(target), io_read), File:newn, oldpath[128]; //for file opener
	format(formatted, 256, UserPath, newname);
	if(fexist(formatted)) return fclose(oldn), SendClientMessage(playerid, Col_Red, "Name is already taken. Please choose a different name.");
	oldpath = Path(target); //for deleting old file
	newn = fopen(formatted, io_write);
	while(fread(oldn, formatted)) fwrite(newn, formatted);
	SetPlayerName(target, newname);
	SendClientMessage(playerid, Col_Green, "Player's name was change.");
	fclose(oldn), fclose(newn);
	fremove(oldpath);
	SendClientMessage(target, Col_Green, "Your name has been changed.");
	return 1;
}
COMMAND:me(playerid, params[])
{
	if(pPun[playerid][muted]){
		SendClientMessage(playerid, Col_Red, "You are muted.");
		return 0;
	}
	new pname[MAX_PLAYER_NAME], formatted[128];
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	format(formatted, 128, "*%s %s", pname, params);
	SendClientMessageToAll(Col_Pink, formatted);
	return 1;
}
COMMAND:adblow(playerid, params[])
{
	if(GetPVarInt(playerid, "Admin") < 4) return 0;
	new target, Float:targetpos[3], visible, Float:targetping, Float:targetvelocity[3]; //ping and velocity in order to avoid lag issues
	if (sscanf(params, "iI(0)", target, visible)) return SendClientMessage(playerid, Col_Red, "USAGE: /adblow [target] [optional: 1 for visible explosion]");
	GetPlayerPos(target, targetpos[0], targetpos[1], targetpos[2]);
	targetping = float(GetPlayerPing(target));
	if(targetping > 50.0){
		SendClientMessage(playerid, Col_Orange, "WARNING:Target player has over 50 ping. Trying to evade it, might be inaccurate.");
		if (!IsPlayerInAnyVehicle(target)) GetPlayerVelocity(target, targetvelocity[0], targetvelocity[1], targetvelocity[2]);
		else GetVehicleVelocity(GetPlayerVehicleID(target), targetvelocity[0], targetvelocity[1], targetvelocity[2]);
		targetping = targetping*0.073; //Ping * Lag constant
		targetpos[0] += (targetvelocity[0]*targetping);
		targetpos[1] += (targetvelocity[1]*targetping);
		targetpos[2] += (targetvelocity[2]*targetping);
	}
	if (visible) CreateExplosion(targetpos[0], targetpos[1], targetpos[2], 0,6.5);
	else CreateExplosion(targetpos[0], targetpos[1], targetpos[2], 8,6.5);
	SendClientMessage(playerid, Col_Green, "Player exploded");
	return 1;
}
COMMAND:adtimeban(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 4 && !IsPlayerAdmin(playerid)) return 0;
	new target, formatted[128], reason[128], pname[MAX_PLAYER_NAME], days, hours;
	if (sscanf(params, "iiis[128]", target, days, hours, reason)) return SendClientMessage(playerid, Col_Red, "USAGE: /adtimeban [playerid] [days] [hours] [reason]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	GetPlayerName(target, pname, MAX_PLAYER_NAME);
	if (GetPVarInt(target, "Admin") > 2 && !IsPlayerAdmin(playerid) || !strcmp("[GCnR]GamEraser", pname)) return SendClientMessage(playerid, Col_Red, "Player is an admin!");
	if (days == 0) format(formatted, 128, "%s has been banned for %d hours. Reason: %s", pname, hours, reason);
	else if (hours == 0) format(formatted, 128, "%s has been banned for %d days. Reason: %s", pname, days, reason);
	else format(formatted, 128, "%s has been banned for %d days and %d hours. Reason: %s", pname, days, hours, reason);
	SendClientMessageToAll(Col_Red, formatted);
	BanPlayer(playerid, target, reason, (days*86400 + hours*3600));
	return 1;
}
COMMAND:adrangeban(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 5) return 0;
	new target, formatted[128], reason[128], pname[MAX_PLAYER_NAME], pname2[MAX_PLAYER_NAME], playerIP[18], blocks;
	if (sscanf(params, "iis[128]", target, blocks, reason)) return SendClientMessage(playerid, Col_Red, "USAGE: /adrangeban [playerid] [blocks (1 or 2)] [reason]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	GetPlayerName(target,pname,MAX_PLAYER_NAME);
	GetPlayerName(playerid,pname2,MAX_PLAYER_NAME);
	if (!strcmp("[GCnR]GamEraser", pname)) return SendClientMessage(playerid, Col_Red, "You cannot ban the owner.");
	format(formatted, 128, "%s has been banned for %s.", pname, reason);
	SendClientMessageToAll(Col_Red, formatted);
	GetPlayerIp(target, playerIP, sizeof(playerIP));
	new index;
	if (blocks == 2){
		index = strfind(playerIP, ".", false);
		index += 2;
		index = strfind(playerIP, ".", false, index);
		strdel(playerIP,index,strlen(playerIP));
		format(playerIP,sizeof(playerIP),"%s.*.*",playerIP);
	}else{
		index = strfind(playerIP, ".", false);
		index += 2;
		index = strfind(playerIP, ".", false, index);
		index += 2;
		index = strfind(playerIP, ".", false, index);
		strdel(playerIP,index,strlen(playerIP));
		format(playerIP,sizeof(playerIP),"%s.*",playerIP);
	}
	format(formatted, 128, "banip %s", playerIP);
	SendRconCommand(formatted);
	format (formatted, 128, "%s range banned by: %s", reason, pname2);
	BanEx(target, formatted);
	return 1;
}
COMMAND:adon(playerid)
{
	if (GetPVarInt(playerid, "Admin") < 3) return 0;
	new Float:temphealth;
	GetPlayerHealth(playerid, temphealth);
	if (temphealth <= 100){
		pPun[playerid][healthbefore] = temphealth;
		SetPlayerHealth(playerid, 99999);
	}
	GivePlayerWeapon(playerid, 38, 89999);
	SetPVarInt(playerid, "active punish", 1);
	if(!pPun[playerid][undercovered] && !pPun[playerid][stealth]){
		pPun[playerid][duty3d] = true;
		pPun[playerid][duty3did] = Create3DTextLabel("Admin on Duty", Col_Blue, 0,0,0,30.0,GetPlayerVirtualWorld(playerid), 1);
		Attach3DTextLabelToPlayer(pPun[playerid][duty3did], playerid, 0, 0, 0.5);
		SendClientMessage(playerid, Col_Green, "Admin mode on and shown.");
	}else SendClientMessage(playerid, Col_Green, "Admin mode on but not shown.");
	return 1;
}
COMMAND:adresetpass(playerid, params[]){
	if (GetPVarInt(playerid, "Admin") < 4) return 0;
	new pname[MAX_PLAYER_NAME], formatted[128], Pathstr[128], hashpass[129], RandomPass[9];
	if (sscanf(params, "s[24]", pname)) return SendClientMessage(playerid, Col_Red, "USAGE: /adresetpass [player name]");
    format(Pathstr,128,UserPath,pname);
	if(!fexist(Pathstr)) return SendClientMessage(playerid, Col_Red, "Error: Player does not exist.");
	/*new strLen = 8;
	while(strLen--)
        RandomPass[strLen] = random(2) ? (random(26) + (random(2) ? 'a' : 'A')) : (random(10) + '0');*/
	for(new i=0;i<8;i++) RandomPass[i] = random(2) ? (random(26) + (random(2) ? 'a' : 'A')) : (random(10) + '0'); //Random String
    WP_Hash(hashpass,sizeof(hashpass),RandomPass);
	WP_Hash(hashpass,sizeof(hashpass),hashpass);//Double Hashing (against rainbow tables)
	new INI:file = INI_Open(Pathstr);
	INI_SetTag(file,"Player's Data");
    INI_WriteString(file,"Password",hashpass);
	INI_WriteBool(file,"Passflag",true);
    INI_Close(file);//Now after we've done saving their data, we now need to close the file
	format(formatted, 128, "The player's new password is: %s", RandomPass);
	ShowPlayerDialog(playerid, Dialog_PassReset, DIALOG_STYLE_MSGBOX, "Password reset successfuly", formatted, "Done", "");
	return 1;
}
COMMAND:adclearpass(playerid, params[]){
	if (GetPVarInt(playerid, "Admin") < 5) return 0;
	new pname[MAX_PLAYER_NAME], Pathstr[128];
	if (sscanf(params, "s[24]", pname)) return SendClientMessage(playerid, Col_Red, "USAGE: /adclearpass [player name]");
    format(Pathstr,128,UserPath,pname);
	if(!fexist(Pathstr)) return SendClientMessage(playerid, Col_Red, "Error: Player does not exist.");
	new INI:file = INI_Open(Pathstr);
	INI_SetTag(file,"Player's Data");
    INI_WriteString(file,"Password","0");
	INI_WriteBool(file,"Passflag",false);
    INI_Close(file);//Now after we've done saving their data, we now need to close the file
	SendClientMessage(playerid, Col_Green, "Password cleared successfuly.");
	return 1;
}
COMMAND:adwep(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 3) return 0;
	new target, WepAdd[32], WepID, AmmoAdd;
	if (sscanf(params, "is[32]I(99999)", target, WepAdd, AmmoAdd)) return SendClientMessage(playerid, Col_Red, "USAGE: /adwep [playerid] [weapon name/id] [ammo - default 99999]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	if(!isNumeric(WepAdd)){
		for(new i = 0; i < 47; i++)
        {
			if ( strfind(WeaponNames[i], WepAdd, true) != -1 ){
            WepID = i;
			
			}
        }
		if (WepID == 0) return SendClientMessage(playerid, Col_Red, "You have entered an invalid weapon name.");
	} else {
		WepID=strval(WepAdd);
		if(WepID <0 || WepID > 46) return SendClientMessage(playerid, Col_Red, "You have entered an invalid weapon ID.");
	}
	pPun[target][specialpriv] = true;
	GivePlayerWeapon(target, WepID, AmmoAdd);
	return 1;
}
COMMAND:adoff(playerid)
{
	if (GetPVarInt(playerid, "Admin") < 3) return 0;
	SetPlayerHealth(playerid, pPun[playerid][healthbefore]);
	SetPlayerAmmo(playerid, 38, 0);
	SetPVarInt(playerid, "active punish", 0);
	if (pPun[playerid][duty3d]) Delete3DTextLabel(pPun[playerid][duty3did]), pPun[playerid][duty3d] = false;
	SendClientMessage(playerid, Col_Red, "Admin mode off.");
	return 1;
}
COMMAND:adpromote(playerid, params[])
{
	new target, formatted[128], pname[MAX_PLAYER_NAME];
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	if (GetPVarInt(playerid, "Admin") < 5 && !IsPlayerAdmin(playerid) && strcmp("[GCnR]GamEraser", pname) != 0) return 0;
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /adpromote [playerid]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	new i = 1;
	GetPlayerName(target, pname, MAX_PLAYER_NAME);
	i += GetPVarInt(target, "Admin");
	SetPVarInt(target, "Admin", i);
	format(formatted, 128, "%s has been promoted to admin rank %d!", pname, i);
	SendClientMessage(playerid, Col_Green, formatted);
	format(formatted, 128, "You have been promoted to admin rank %d!", i);
	SendClientMessage(target, Col_Green, formatted);
	CallRemoteFunction("SetADLevel", "ii", target, i);
	return 1;
}
COMMAND:adfakepromote(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 2) return 0;
	new target, formatted[128];
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /adfakepromote [playerid]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	pPun[target][fakeadmin]++;
	format(formatted, 128, "You have been promoted to admin rank %d!", pPun[target][fakeadmin]);
	SendClientMessage(target, Col_Green, formatted);
	format(formatted, 128, "Hehe, nice trick :) (rank %d)", pPun[target][fakeadmin]);
	SendClientMessage(playerid, Col_Green, formatted);
	return 1;
}
COMMAND:adfakedemote(playerid, params[])
{
	if (GetPVarInt(playerid, "Admin") < 2) return 0;
	new target, formatted[128];
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /adfakedemote [playerid]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	pPun[target][fakeadmin]--;
	format(formatted, 128, "You have been demoted to admin rank %d!", pPun[target][fakeadmin]);
	SendClientMessage(target, Col_Red, formatted);
	format(formatted, 128, "Hehe, nice trick :) (rank %d)", pPun[target][fakeadmin]);
	SendClientMessage(playerid, Col_Red, formatted);
	return 1;
}
COMMAND:addemote(playerid, params[])
{
	new target, formatted[128], pname[MAX_PLAYER_NAME];
	GetPlayerName(playerid, pname, MAX_PLAYER_NAME);
	if (GetPVarInt(playerid, "Admin") < 5 && !IsPlayerAdmin(playerid) && strcmp("[GCnR]GamEraser", pname) != 0) return 0;
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /addemote [playerid]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	new i = GetPVarInt(target, "Admin");
	if (!i) return SendClientMessage(playerid, Col_Red, "The guy is already admin level 0, what do you want from him?");
	GetPlayerName(target, pname, MAX_PLAYER_NAME);
	if (!strcmp("[GCnR]GamEraser", pname)) return SendClientMessage(playerid, Col_Red, "You cannot demote the owner.");
	i--;
	SetPVarInt(target, "Admin", i);
	format(formatted, 128, "%s has been demoted to admin rank %d.", pname, i);
	SendClientMessage(playerid, Col_Red, formatted);
	format(formatted, 128, "You have been demoted to admin rank %d.", i);
	SendClientMessage(target, Col_Red, formatted);
	CallRemoteFunction("SetADLevel", "ii", target, i);
	return 1;
}
COMMAND:adspec(playerid, params[])
{
	if(GetPVarInt(playerid, "Admin") < 2) return 0;
	new specplayerid, specvehicleid;
	if (sscanf(params, "i", specplayerid)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /adspec [playerid]");
	if (!IsPlayerConnected(specplayerid)) return SendClientMessage(playerid, COLOR_RED, "Wrong ID: No such player.");
	if(GetPlayerState(playerid) != PLAYER_STATE_SPECTATING) CallRemoteFunction("SGPlayerPos", "ii", playerid, 1);
	SetPVarInt(playerid, "active punish", 1);
	TogglePlayerSpectating(playerid, 1);
	SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(specplayerid));
	if (GetPlayerVehicleID(specplayerid) == 0){
		SetPlayerInterior(playerid,GetPlayerInterior(specplayerid));
		PlayerSpectatePlayer(playerid, specplayerid);
	}else {
		specvehicleid = GetPlayerVehicleID(specplayerid);
		SetPlayerInterior(playerid,GetPlayerInterior(specplayerid));
		PlayerSpectateVehicle(playerid, specvehicleid);
	}
	return 1;
}
COMMAND:specoff(playerid)
{
	if(GetPVarInt(playerid, "Admin") < 2) return 0;
	if (GetPlayerState(playerid) != PLAYER_STATE_SPECTATING) return SendClientMessage(playerid, COLOR_RED, "You are not spectating.");
	TogglePlayerSpectating(playerid, 0);
	SetPVarInt(playerid, "active punish", 0);
	return 1;
}
COMMAND:adslap(playerid, params[])
{
	if(GetPVarInt(playerid, "Admin") < 1) return 0;
	new target, Float:vx = float(random(31)), Float:vy = float(random(31)), Float:vz = float(random(21)), pname[MAX_PLAYER_NAME], formatted[128];
	if (sscanf(params, "i", target)) return SendClientMessage(playerid, Col_Red, "USAGE: /adslap [playerid]");
	if (!IsPlayerConnected(target)) return SendClientMessage(playerid, Col_Red, "Wrong ID: No such player.");
	vx = (vx/100)-0.15;
	vy = (vy/100)-0.15;
	vz = (vz/100)+0.07;
	if(IsPlayerInAnyVehicle(target)) SetVehicleVelocity(GetPlayerVehicleID(target), vx, vy, vz);
	else SetPlayerVelocity(target, vx, vy, vz);
	GetPlayerName(target, pname, MAX_PLAYER_NAME);
	format(formatted, 128, "%s has been slapped by an admin.", pname);
	SendClientMessageToAll(Col_LightOrange, formatted);
	return 1;
}
COMMAND:cc(playerid)
{
	if(GetPVarInt(playerid, "Admin") < 1) return 0;
	for (new i; i < 100; i++) SendClientMessageToAll(0xFFFFFF00, " ");
	return 1;
}
COMMAND:adrestart(playerid)
{
	if(GetPVarInt(playerid, "Admin") < 5) return 0;
	SendRconCommand("gmx");
	return 1;
}
COMMAND:adexit(playerid)
{
	if(GetPVarInt(playerid, "Admin") < 5) return 0;
	SendRconCommand("exit");
	return 1;
}
public OnPlayerUpdate(playerid)
{
	if (pPun[playerid][needjail]) pPun[playerid][needjail] = false;
	return 1;
}
public OnPlayerDeath(playerid, killerid, reason)
{
	pPun[playerid][frtime] = 0;
	pPun[playerid][jailtime] = 0;
	pPun[playerid][alive] = false;
	if (pPun[playerid][duty3d]) Delete3DTextLabel(pPun[playerid][duty3did]), pPun[playerid][duty3d] = false;
	SetPVarInt(playerid, "active punish", 0);
}
public HackCheck(){
	new formatted[128], pname[MAX_PLAYER_NAME];
	foreach (new i : Player){
		if(pPun[i][alive]){
			//Don't allow minigun
			if(((GetPlayerWeapon(i) >= 35 && GetPlayerWeapon(i) <= 39) || GetPlayerSpecialAction(i) == SPECIAL_ACTION_USEJETPACK) && GetPVarInt(i, "Admin") < 3 && !pPun[i][specialpriv]) {
				BanPlayer(-1, i, "weapon hacks");
				return 0;		
			}
			if (GetPlayerPing(i) > MaxPing && GetPlayerPing(i) < 50000){
				GetPlayerName(i,pname,MAX_PLAYER_NAME);
				format(formatted, 128, "%s has been automatically kicked for high ping (over %d).", pname, MaxPing);
				SendClientMessageToAll(Col_Red, formatted);
				SetTimerEx("KickF", 1000, false, "i", i);
				return 0;
			}
		}
	}
	return 1;
}
forward PrintWarns(playerid, target);
public PrintWarns(playerid, target){
	new formatted[128];
	format(formatted, 128, "Warnings: %d", pPun[target][warns]);
	SendClientMessage(playerid, Col_Pink, formatted);
}
stock BanPlayer(banning, target, reason[], btime = -1){
	new pip[16], formatted[128], pname[MAX_PLAYER_NAME], pname2[MAX_PLAYER_NAME];
	GetPlayerName(target,pname,MAX_PLAYER_NAME);
	if (banning != -1) GetPlayerName(banning,pname2,MAX_PLAYER_NAME);
	else pname2 = "Autoban";
	GetPlayerIp(target, pip, 16);
	if(fexist(WhitePath(pname))){
		fremove(WhitePath(pname));
		if(banning != -1) SendClientMessage(banning, Col_Green, "Player was whitelisted. Whitelist removed.");
	}
	if(btime == -1) {
		format(formatted, 128, "%s has been permanently banned for %s.", pname, reason);
		SendClientMessageToAll(Col_Red, formatted);
	}
	else btime += gettime();
	format (formatted, 128, "%d\r\n%s\r\nTime: Permanent. By: %s. Reason: %s", btime, pip, pname2, reason);
	new File:BanFile = fopen(BanPath(target)), File:IPBanFile = fopen(IPBanPath(pip));
	fwrite(BanFile, formatted);
	format(formatted, 128, "Player: %s", pname);
	fwrite(IPBanFile, formatted);
	fclose(BanFile), fclose(IPBanFile);
	SendClientMessage(target, Col_Pink, "Think you were banned unfairly? Post an unban request at gcnr.tk");
	SetTimerEx("KickF", 1000, false, "i", target);
}