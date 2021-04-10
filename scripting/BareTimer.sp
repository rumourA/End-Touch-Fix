#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

#pragma newdecls required

float Time[MAXPLAYERS +1];
bool ShouldTime[MAXPLAYERS + 1];
bool LateLoad;

public Plugin myinfo =
{
	name = "Barebones Timer",
	author = "rumour",
	description = "This is just a very simple example and does not account for tick fraction",
	version = "",
	url = ""
};

public void OnPluginStart()
{	
	if(LateLoad)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				OnClientPutInServer(i);
			}
		}
		
		int triggers = 0;
		while ((triggers = FindEntityByClassname(triggers, "trigger_multiple")) != -1)
		{
			SDKHook(triggers, SDKHook_StartTouch, Zone_StartTouch);
			SDKHook(triggers, SDKHook_EndTouch, Zone_EndTouch);
		}
		LateLoad = false;
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	LateLoad = late;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_PostThinkPost, PostThinkPost);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrContains(classname, "trigger_") != -1)
	{
		SDKHook(entity, SDKHook_StartTouch, Zone_StartTouch);
		SDKHook(entity, SDKHook_EndTouch, Zone_EndTouch);
	}
}

public Action Zone_StartTouch(int entity, int other)
{
	char trigger_name[255];
	GetEntPropString(entity, Prop_Data, "m_iName", trigger_name, sizeof(trigger_name));
	
	if(StrEqual(trigger_name, "timer_end"))
	{
		PrintToChat(other, "Hit End %f", Time[other]);
		ShouldTime[other] = false;
	}
	
	return Plugin_Continue;
}

public Action Zone_EndTouch(int entity, int other)
{
	char trigger_name[255];
	GetEntPropString(entity, Prop_Data, "m_iName", trigger_name, sizeof(trigger_name));
	
	if(StrEqual(trigger_name, "timer_start"))
	{
		PrintToChat(other, "Left Start");
		ShouldTime[other] = true;
		Time[other] = 0.0;
	}
	
	return Plugin_Continue;
}

public Action PostThinkPost(int client)
{
	SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
	
	if(ShouldTime[client])
	{
		Time[client] += GetTickInterval();
	}
	
	return Plugin_Continue;
}
