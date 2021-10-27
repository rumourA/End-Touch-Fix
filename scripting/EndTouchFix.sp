#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

#pragma newdecls required

#define EFL_CHECK_UNTOUCH (1<<24)

Handle PhysicsCheckForEntityUntouch;
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
	RegPluginLibrary("endtouchfix");
	return APLRes_Success;
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
	if(GetCheckUntouch(client))
	{
		SDKCall(PhysicsCheckForEntityUntouch, client);
	}	
	
	return Plugin_Continue;
}
