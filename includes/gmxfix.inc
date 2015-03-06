/*----------------------------------------------------------------------------*\
					=====================================
					 gmxfix - Consistent callback orders 
					=====================================
Description:
	Provides six new RCON commands to end modes with OnGameModeExit and
	OnPlayerDisconnect called in consistent orders:
	
	gmx1
	exit1
	changemode1
	
	All have OnGameModeExit called first.
	
	gmx2
	exit2
	changemode2
	
	All have OnGameModeExit called second.
	
	Note that ALL scripts must include this if you want it to work.
	
	The new disconnect reasons are:
	
	101 - gmx called
	102 - exit called
	103 - changemode called
	
	If you want to treat them all the same then fair enough.
Legal:
	Version: MPL 1.1
	
	The contents of this file are subject to the Mozilla Public License Version 
	1.1 (the "License"); you may not use this file except in compliance with 
	the License. You may obtain a copy of the License at 
	http://www.mozilla.org/MPL/
	
	Software distributed under the License is distributed on an "AS IS" basis,
	WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
	for the specific language governing rights and limitations under the
	License.
	
	The Original Code is the SA:MP gmxfix script
	
	The Initial Developer of the Original Code is Alex "Y_Less" Cole.
	Portions created by the Initial Developer are Copyright (C) 2008
	the Initial Developer. All Rights Reserved.
	
	Very special thanks to:
		Thiadmer - PAWN.
		Kye/Kalcor - SA:MP.
		SA:MP Team past, present and future - SA:MP.
Version:
	1.0
Changelog:
	24/04/11:
		First version
\*----------------------------------------------------------------------------*/

// These two are mutually exclusive.
//#tryinclude <YSI\y_amx>
//#tryinclude <YSI\y_scripting>

//#if defined _inc_y_amx


//#elseif defined _inc_y_scripting

// No YSI, do this the slow way.  Technically you could copy all the relevant
// code from the YSI scripting libraries, but then what's the point of making
// and releasing powerful libraries?
static
	YSI_g_sDisableCalls = 0,
	YSI_g_sCallbackFlags = 0;

#if defined _ALS_OnGameModeExit || defined _ALS_OnPlayerDisconnect || defined _ALS_OnRconCommand || defined _ALS_OnGameModeInit || defined _inc_a_samp
	#error gmxfix.inc must be your FIRST include!
#endif

#include <a_samp>
//#include <foreach>

public OnGameModeExit()
{
	//printf("ogme called");
	if (YSI_g_sDisableCalls & 1)
	{
		return 0;
	}
	else
	{
		return CallLocalFunction("gmxfix_OnGameModeExit", "");
	}
}

#define OnGameModeExit gmxfix_OnGameModeExit
#define _ALS_OnGameModeExit

forward OnGameModeExit();

public OnGameModeInit()
{
	YSI_g_sCallbackFlags |= (funcidx("gmxfix_OnPlayerDisconnect") == -1) ? 0 : 1;
	YSI_g_sCallbackFlags |= (funcidx("gmxfix_OnRconCommand") == -1) ? 0 : 2;
	return CallLocalFunction("gmxfix_OnGameModeInit", "");
}

#define OnGameModeInit gmxfix_OnGameModeInit
#define _ALS_OnGameModeInit

forward OnGameModeInit();

public OnPlayerDisconnect(playerid, reason)
{
	//printf("opdc called");
	if (YSI_g_sDisableCalls & 2)
	{
		return 0;
	}
	else if (YSI_g_sCallbackFlags & 1)
	{
		return CallLocalFunction("gmxfix_OnPlayerDisconnect", "ii", playerid, reason);
	}
	else
	{
		return 1;
	}
}

#define OnPlayerDisconnect gmxfix_OnPlayerDisconnect
#define _ALS_OnPlayerDisconnect

forward OnPlayerDisconnect(playerid, reason);

public OnRconCommand(cmd[])
{
	if (!strcmp(cmd, "gmx1"))
	{
		//printf("OGME");
		CallRemoteFunction("OnGameModeExit", "");
		//printf("OPDC");
		for (new playerid = 0; playerid != MAX_PLAYERS; ++playerid) if (IsPlayerConnected(playerid))
		{
			// Special leave reason.
			CallRemoteFunction("OnPlayerDisconnect", "ii", playerid, 101);
		}
		CallRemoteFunction("gmxfix_BlockAll", "");
		GameModeExit();
		CallRemoteFunction("gmxfix_UnblockAll", "");
		return 1;
	}
	else if (!strcmp(cmd, "gmx2"))
	{
		//printf("OPDC");
		for (new playerid = 0; playerid != MAX_PLAYERS; ++playerid) if (IsPlayerConnected(playerid))
		//foreach (Players, playerid)
		{
			// Special leave reason.
			CallRemoteFunction("OnPlayerDisconnect", "ii", playerid, 101);
		}
		//printf("OGME");
		CallRemoteFunction("OnGameModeExit", "");
		CallRemoteFunction("gmxfix_BlockAll", "");
		GameModeExit();
		CallRemoteFunction("gmxfix_UnblockAll", "");
		return 1;
	}
	else if (!strcmp(cmd, "exit1"))
	{
		//printf("OGME");
		CallRemoteFunction("OnGameModeExit", "");
		//printf("OPDC");
		for (new playerid = 0; playerid != MAX_PLAYERS; ++playerid) if (IsPlayerConnected(playerid))
		{
			// Special leave reason.
			CallRemoteFunction("OnPlayerDisconnect", "ii", playerid, 102);
		}
		CallRemoteFunction("gmxfix_BlockAll", "");
		//CallRemoteFunction("gmxfix_BlockAll", "");
		SendRconCommand("exit");
		CallRemoteFunction("gmxfix_UnblockAll", "");
		return 1;
	}
	else if (!strcmp(cmd, "exit2"))
	{
		//printf("OPDC");
		for (new playerid = 0; playerid != MAX_PLAYERS; ++playerid) if (IsPlayerConnected(playerid))
		//foreach (Players, playerid)
		{
			// Special leave reason.
			CallRemoteFunction("OnPlayerDisconnect", "ii", playerid, 102);
		}
		//printf("OGME");
		CallRemoteFunction("OnGameModeExit", "");
		CallRemoteFunction("gmxfix_BlockAll", "");
		SendRconCommand("exit");
		CallRemoteFunction("gmxfix_UnblockAll", "");
		return 1;
	}
	else if (!strcmp(cmd, "changemode1 ", false, 12))
	{
		//printf("OGME");
		CallRemoteFunction("OnGameModeExit", "");
		//printf("OPDC");
		for (new playerid = 0; playerid != MAX_PLAYERS; ++playerid) if (IsPlayerConnected(playerid))
		{
			// Special leave reason.
			CallRemoteFunction("OnPlayerDisconnect", "ii", playerid, 103);
		}
		CallRemoteFunction("gmxfix_BlockAll", "");
		format(cmd, strlen(cmd), "changemode %s", cmd[12]);
		SendRconCommand(cmd);
		CallRemoteFunction("gmxfix_UnblockAll", "");
		return 1;
	}
	else if (!strcmp(cmd, "changemode2 ", false, 12))
	{
		//printf("OPDC");
		for (new playerid = 0; playerid != MAX_PLAYERS; ++playerid) if (IsPlayerConnected(playerid))
		//foreach (Players, playerid)
		{
			// Special leave reason.
			CallRemoteFunction("OnPlayerDisconnect", "ii", playerid, 103);
		}
		//printf("OGME");
		CallRemoteFunction("OnGameModeExit", "");
		CallRemoteFunction("gmxfix_BlockAll", "");
		format(cmd, strlen(cmd), "changemode %s", cmd[12]);
		SendRconCommand(cmd);
		CallRemoteFunction("gmxfix_UnblockAll", "");
		return 1;
	}
	else if (YSI_g_sCallbackFlags & 2)
	{
		return CallLocalFunction("gmxfix_OnRconCommand", "s", cmd);
	}
	else
	{
		return 0;
	}
}

#define OnRconCommand gmxfix_OnRconCommand
#define _ALS_OnRconCommand

forward OnRconCommand(cmd[]);

forward gmxfix_BlockAll();

public gmxfix_BlockAll()
{
	YSI_g_sDisableCalls = 3;
}

forward gmxfix_UnblockAll();

public gmxfix_UnblockAll()
{
	YSI_g_sDisableCalls = 0;
}

//#endif