#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

#pragma newdecls required

#define EFL_CHECK_UNTOUCH (1<<24)
#define WINDOWS 1

Handle PhysicsCheckForEntityUntouch;
Address PhysicsMarkEntityAsTouched;
int OS;
bool LateLoad;

public Plugin myinfo =
{
	name = "EndTouch Fix",
	author = "rumour, mev",
	description = "Checks EntityUntouch on PostThink instead of server frames",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	GameData game_data = new GameData("endtouch.games");
	
	if(game_data == null)
	{
		SetFailState("Failed to load game_data");
	}
	
	OS = game_data.GetOffset("OS");
	
	PhysicsMarkEntityAsTouched = game_data.GetAddress("PhysicsMarkEntityAsTouchedAddress");
	
	StartPrepSDKCall(SDKCall_Entity);
	if(!PrepSDKCall_SetFromConf(game_data, SDKConf_Signature, "PhysicsCheckForEntityUntouch"))
	{
		SetFailState("Failed to get PhysicsCheckForEntityUntouch");
	}
	
	PhysicsCheckForEntityUntouch = EndPrepSDKCall();
	
	delete game_data;
	
	if(LateLoad)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				OnClientPutInServer(i);
			}
		}
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	LateLoad = late;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_PostThink, PostThink);
}

bool GetCheckUntouch(int client)
{
	int flags = GetEntProp(client, Prop_Data, "m_iEFlags");
	return (flags & EFL_CHECK_UNTOUCH) != 0;
}

public Action PostThink(int client)
{
	int disable_touch_funcs;
	
	if(OS == WINDOWS)
	{
		disable_touch_funcs = LoadFromAddress(PhysicsMarkEntityAsTouched + view_as<Address>(0x3430B2), NumberType_Int8);
	}
	else
	{
		disable_touch_funcs = LoadFromAddress(PhysicsMarkEntityAsTouched + view_as<Address>(0x7E4064), NumberType_Int8);
	}
	
	if(!disable_touch_funcs)
	{
		if(GetCheckUntouch(client))
		{
			SDKCall(PhysicsCheckForEntityUntouch, client);
		}
	}
	
	return Plugin_Continue;
}