//-------------------------------------------------
//
// Generic Special Actions And Anims
// kyeman 2007
//
//-------------------------------------------------

#include <a_samp>
#include <core>
#include <float>
#include <zcmd>
#pragma tabsize 0

#include "../include/gl_common.inc"

new gPlayerUsingLoopingAnim[MAX_PLAYERS];
new gPlayerAnimLibsPreloaded[MAX_PLAYERS];

new Text:txtAnimHelper;

//-------------------------------------------------

OnePlayAnim(playerid,animlib[],animname[], Float:Speed, looping, lockx, locky, lockz, lp)
{
	ApplyAnimation(playerid, animlib, animname, Speed, looping, lockx, locky, lockz, lp);
}

//-------------------------------------------------

LoopingAnim(playerid,animlib[],animname[], Float:Speed, looping, lockx, locky, lockz, lp)
{
    gPlayerUsingLoopingAnim[playerid] = 1;
    ApplyAnimation(playerid, animlib, animname, Speed, looping, lockx, locky, lockz, lp);
    TextDrawShowForPlayer(playerid,txtAnimHelper);
}

//-------------------------------------------------

StopLoopingAnim(playerid)
{
	gPlayerUsingLoopingAnim[playerid] = 0;
    ApplyAnimation(playerid, "CARRY", "crry_prtial", 4.0, 0, 0, 0, 0, 0);
}

//-------------------------------------------------

PreloadAnimLib(playerid, animlib[])
{
	ApplyAnimation(playerid,animlib,"null",0.0,0,0,0,0,0);
}

//-------------------------------------------------

// ********** CALLBACKS **********

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(!gPlayerUsingLoopingAnim[playerid]) return;

	if(IsKeyJustDown(KEY_SPRINT,newkeys,oldkeys)) {
	    StopLoopingAnim(playerid);
        TextDrawHideForPlayer(playerid,txtAnimHelper);
    }
}

//------------------------------------------------

public OnPlayerDeath(playerid, killerid, reason)
{
	// if they die whilst performing a looping anim, we should reset the state
	if(gPlayerUsingLoopingAnim[playerid]) {
        gPlayerUsingLoopingAnim[playerid] = 0;
        TextDrawHideForPlayer(playerid,txtAnimHelper);
	}

 	return 1;
}

//-------------------------------------------------

public OnPlayerSpawn(playerid)
{
	if(!gPlayerAnimLibsPreloaded[playerid]) {
   		PreloadAnimLib(playerid,"BOMBER");
   		PreloadAnimLib(playerid,"RAPPING");
    	PreloadAnimLib(playerid,"SHOP");
   		PreloadAnimLib(playerid,"BEACH");
   		PreloadAnimLib(playerid,"SMOKING");
    	PreloadAnimLib(playerid,"FOOD");
    	PreloadAnimLib(playerid,"ON_LOOKERS");
    	PreloadAnimLib(playerid,"DEALER");
		PreloadAnimLib(playerid,"CRACK");
		PreloadAnimLib(playerid,"CARRY");
		PreloadAnimLib(playerid,"COP_AMBIENT");
		PreloadAnimLib(playerid,"PARK");
		PreloadAnimLib(playerid,"INT_HOUSE");
		PreloadAnimLib(playerid,"FOOD");
		gPlayerAnimLibsPreloaded[playerid] = 1;
	}
	return 1;
}

//-------------------------------------------------

public OnPlayerConnect(playerid)
{
    gPlayerUsingLoopingAnim[playerid] = 0;
	gPlayerAnimLibsPreloaded[playerid] = 0;
	
	return 1;
}
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) return 0;
//-------------------------------------------------

public OnFilterScriptInit()
{
	// Init our text display
	txtAnimHelper = TextDrawCreate(610.0, 400.0,
	"~r~~k~~PED_SPRINT~ ~w~to stop the animation");
	TextDrawUseBox(txtAnimHelper, 0);
	TextDrawFont(txtAnimHelper, 2);
	TextDrawSetShadow(txtAnimHelper,0); // no shadow
    TextDrawSetOutline(txtAnimHelper,1); // thickness 1
    TextDrawBackgroundColor(txtAnimHelper,0x000000FF);
    TextDrawColor(txtAnimHelper,0xFFFFFFFF);
    TextDrawAlignment(txtAnimHelper,3); // align right
}

//-------------------------------------------------
CMD:animlist(playerid)
{
	SendClientMessage(playerid,0xAFAFAFAA,"Available Animations:");
	SendClientMessage(playerid,0xAFAFAFAA,"/handsup /drunk /bomb /getarrested /laugh /lookout /robman");
	SendClientMessage(playerid,0xAFAFAFAA,"/crossarms /lay /hide /vomit /eat /wave /taichi");
	SendClientMessage(playerid,0xAFAFAFAA,"/deal /crack /smokem /smokef /groundsit /chat /dance /f**ku");
	return 1;
}
CMD:handsup(playerid)
{
	if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT || GetPlayerState(playerid) == SPECIAL_ACTION_CUFFED) return 1;
	SetPlayerSpecialAction(playerid,SPECIAL_ACTION_HANDSUP);
	return 1;
}
CMD:cellin(playerid)
{
	if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT || GetPlayerState(playerid) == SPECIAL_ACTION_CUFFED) return 1;
	SetPlayerSpecialAction(playerid,SPECIAL_ACTION_USECELLPHONE);
	return 1;
}
    
CMD:cellout(playerid)
{
	if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT || GetPlayerState(playerid) == SPECIAL_ACTION_CUFFED) return 1;
	SetPlayerSpecialAction(playerid,SPECIAL_ACTION_STOPUSECELLPHONE);
	return 1;
}
CMD:drunk(playerid)
{
	if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT || GetPlayerState(playerid) == SPECIAL_ACTION_CUFFED) return 1;
	LoopingAnim(playerid,"PED","WALK_DRUNK",4.0,1,1,1,1,0);
	return 1;
}
CMD:bomb(playerid)
{
	if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT || GetPlayerState(playerid) == SPECIAL_ACTION_CUFFED) return 1;
	ClearAnimations(playerid);
	OnePlayAnim(playerid, "BOMBER", "BOM_Plant", 4.0, 0, 0, 0, 0, 0); // Place Bomb
	return 1;
}
CMD:getarrested(playerid)
{
	if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT || GetPlayerState(playerid) == SPECIAL_ACTION_CUFFED) return 1;
	LoopingAnim(playerid,"ped", "ARRESTgun", 4.0, 0, 1, 1, 1, -1); // Gun Arrest
	return 1;
}
CMD:laugh(playerid)
{
	if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT || GetPlayerState(playerid) == SPECIAL_ACTION_CUFFED) return 1;
	OnePlayAnim(playerid, "RAPPING", "Laugh_01", 4.0, 0, 0, 0, 0, 0); // Laugh
	return 1;
}
CMD:lookout(playerid)
{
	if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT || GetPlayerState(playerid) == SPECIAL_ACTION_CUFFED) return 1;
    OnePlayAnim(playerid, "SHOP", "ROB_Shifty", 4.0, 0, 0, 0, 0, 0); // Rob Lookout
	return 1;
}
CMD:robman(playerid)
{
	if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT || GetPlayerState(playerid) == SPECIAL_ACTION_CUFFED) return 1;
	LoopingAnim(playerid, "SHOP", "ROB_Loop_Threat", 4.0, 1, 0, 0, 0, 0); // Rob
	return 1;
}
CMD:crossarms(playerid)
{
	if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT || GetPlayerState(playerid) == SPECIAL_ACTION_CUFFED) return 1;
    LoopingAnim(playerid, "COP_AMBIENT", "Coplook_loop", 4.0, 0, 1, 1, 1, -1); // Arms crossed
	return 1;
}
CMD:lay(playerid)
{
	if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT || GetPlayerState(playerid) == SPECIAL_ACTION_CUFFED) return 1;
    LoopingAnim(playerid,"BEACH", "bather", 4.0, 1, 0, 0, 0, 0); // Lay down
	return 1;
}
CMD:hide(playerid)
{
	if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT || GetPlayerState(playerid) == SPECIAL_ACTION_CUFFED) return 1;
    LoopingAnim(playerid, "ped", "cower", 3.0, 1, 0, 0, 0, 0); // Taking Cover
	return 1;
}
CMD:vomit(playerid)
{
	if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT || GetPlayerState(playerid) == SPECIAL_ACTION_CUFFED) return 1;
    OnePlayAnim(playerid, "FOOD", "EAT_Vomit_P", 3.0, 0, 0, 0, 0, 0); // Vomit BAH!
	return 1;
}
CMD:eat(playerid)
{
	if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT || GetPlayerState(playerid) == SPECIAL_ACTION_CUFFED) return 1;
    OnePlayAnim(playerid, "FOOD", "EAT_Burger", 3.0, 0, 0, 0, 0, 0); // Eat Burger
	return 1;
}
CMD:wave(playerid)
{
	if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT || GetPlayerState(playerid) == SPECIAL_ACTION_CUFFED) return 1;
    LoopingAnim(playerid, "ON_LOOKERS", "wave_loop", 4.0, 1, 0, 0, 0, 0); // Wave
	return 1;
}
CMD:slapass(playerid)
{
	if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT || GetPlayerState(playerid) == SPECIAL_ACTION_CUFFED) return 1;
    OnePlayAnim(playerid, "SWEET", "sweet_ass_slap", 4.0, 0, 0, 0, 0, 0); // Ass Slapping
	return 1;
}
CMD:deal(playerid)
{
	if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT || GetPlayerState(playerid) == SPECIAL_ACTION_CUFFED) return 1;
    OnePlayAnim(playerid, "DEALER", "DEALER_DEAL", 4.0, 0, 0, 0, 0, 0); // Deal Drugs
	return 1;
}
CMD:crack(playerid)
{
	if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT || GetPlayerState(playerid) == SPECIAL_ACTION_CUFFED) return 1;
    LoopingAnim(playerid, "CRACK", "crckdeth2", 4.0, 1, 0, 0, 0, 0); // Dieing of Crack
	return 1;
}
CMD:smokem(playerid)
{
	if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT || GetPlayerState(playerid) == SPECIAL_ACTION_CUFFED) return 1;
    LoopingAnim(playerid,"SMOKING", "M_smklean_loop", 4.0, 1, 0, 0, 0, 0); // Smoke
	return 1;
}
CMD:smokef(playerid)
{
	if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT || GetPlayerState(playerid) == SPECIAL_ACTION_CUFFED) return 1;
    LoopingAnim(playerid, "SMOKING", "F_smklean_loop", 4.0, 1, 0, 0, 0, 0); // Female Smoking
	return 1;
}
CMD:groundsit(playerid)
{
	if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT || GetPlayerState(playerid) == SPECIAL_ACTION_CUFFED) return 1;
    LoopingAnim(playerid,"BEACH", "ParkSit_M_loop", 4.0, 1, 0, 0, 0, 0); // Sit
	return 1;
}
CMD:chat(playerid)
{
	if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT || GetPlayerState(playerid) == SPECIAL_ACTION_CUFFED) return 1;
	OnePlayAnim(playerid,"PED","IDLE_CHAT",4.0,0,0,0,0,0);
    return 1;
}
CMD:fucku(playerid)
{
	if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT || GetPlayerState(playerid) == SPECIAL_ACTION_CUFFED) return 1;
	OnePlayAnim(playerid,"PED","fucku",4.0,0,0,0,0,0);
    return 1;
}
CMD:taichi(playerid)
{
	if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT || GetPlayerState(playerid) == SPECIAL_ACTION_CUFFED) return 1;
	LoopingAnim(playerid,"PARK","Tai_Chi_Loop",4.0,1,0,0,0,0);
    return 1;
}
CMD:chairsit(playerid)
{
	if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT || GetPlayerState(playerid) == SPECIAL_ACTION_CUFFED) return 1;
	LoopingAnim(playerid,"BAR","dnk_stndF_loop",4.0,1,0,0,0,0);
    return 1;
}
    
    /* Would allow people to troll... but would be cool as a script
	   controlled function
    // Bed Sleep R
    if(strcmp(cmd, "/inbedright", true) == 0) {
		 LoopingAnim(playerid,"INT_HOUSE","BED_Loop_R",4.0,1,0,0,0,0);
         return 1;
    }
    // Bed Sleep L
    if(strcmp(cmd, "/inbedleft", true) == 0) {
		 LoopingAnim(playerid,"INT_HOUSE","BED_Loop_L",4.0,1,0,0,0,0);
         return 1;
    }*/

	// START DANCING
CMD:dance(playerid, params[])
{
	if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT || GetPlayerState(playerid) == SPECIAL_ACTION_CUFFED) return 1;
	if(!strlen(params) || strlen(params) > 2) {
		SendClientMessage(playerid,0xFF0000FF,"USAGE: /dance [style 1-4]");
		return 1;
	}
	new dancestyle = strval(params);
	if(dancestyle < 1 || dancestyle > 4) {
		SendClientMessage(playerid,0xFF0000FF,"USAGE: /dance [style 1-4]");
		return 1;
	}	
	if(dancestyle == 1) {
		SetPlayerSpecialAction(playerid,SPECIAL_ACTION_DANCE1);
	} else if(dancestyle == 2) {
		SetPlayerSpecialAction(playerid,SPECIAL_ACTION_DANCE2);
	} else if(dancestyle == 3) {
		SetPlayerSpecialAction(playerid,SPECIAL_ACTION_DANCE3);
	} else if(dancestyle == 4) {
		SetPlayerSpecialAction(playerid,SPECIAL_ACTION_DANCE4);
	}
	return 1;
}
//-------------------------------------------------
// EOF
