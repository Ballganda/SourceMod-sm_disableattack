#include <sourcemod>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define NAME "[CS:S]sm_disableattack"
#define AUTHOR "BallGanda"
#define DESCRIPTION "sm_disableattack diabled ability to use primary attack"
#define PLUGIN_VERSION "0.0.b3"
#define URL "https://github.com/Ballganda/SourceMod-sm_disableattack"

ConVar g_cvEnablePlugin = null;
ConVar g_cvDisablePrimary = null;
ConVar g_cvDisableSecondary = null;
ConVar g_cvDisableInAir = null;
ConVar g_cvDisableOnGround = null;
ConVar g_cvDelayReset = null;

bool UnblockPrimary[MAXPLAYERS + 1];
bool UnblockSecondary[MAXPLAYERS + 1];

public void OnPluginStart()
{
	CheckGameVersion();

	RegAdminCmd("sm_disableattack", smAbout, ADMFLAG_BAN, "sm_disableattack info in console");

	CreateConVar("sm_disableattack_version", PLUGIN_VERSION, NAME, FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_cvEnablePlugin = CreateConVar("sm_disableattack_enable", "1", "sm_disableattack_enable enables the plugin <1|0>", _, true, 0.0, true, 1.0);
	g_cvDisablePrimary = CreateConVar("sm_disableattack_primary", "1", "Disable primary attack <1|0>", _, true, 0.0, true, 1.0);
	g_cvDisableSecondary = CreateConVar("sm_disableattack_Secondary", "1", "Disable secondary <1|0>", _, true, 0.0, true, 1.0);
	g_cvDisableInAir = CreateConVar("sm_disableattack_inair", "0", "Disable attack jumping/off ground <1|0>", _, true, 0.0, true, 1.0);
	g_cvDisableOnGround = CreateConVar("sm_disableattack_onground", "1", "Disable attack on ground <1|0>", _, true, 0.0, true, 1.0);
	g_cvDelayReset = CreateConVar("sm_disableattack_DelayReset", "0.25", "Delay reset attack float <-1.0|1.0>", _, true, -1.0, true, 1.0);
	
	AutoExecConfig(true, "sm_disableattack");

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_PreThink, OnPreThink);
	UnblockPrimary[client] = false;
	UnblockSecondary[client] = false;
}

public Action OnPreThink(int client)
{
	if(!g_cvEnablePlugin.BoolValue)
	{
		return Plugin_Handled;
	}
	
	int activeWeapon;
	activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(activeWeapon))
	{
		return Plugin_Continue;
	}
	
	if (g_cvDisablePrimary.BoolValue)
	{
		DisablePrimaryAttack(client, activeWeapon);
	}
	
	if (g_cvDisableSecondary.BoolValue)
	{
		DisableSecondaryAttack(client, activeWeapon);
	}
	
	return Plugin_Continue;
}

stock void DisablePrimaryAttack(int client, int entityNumber)
{
	int IsOnGround = (GetEntityFlags(client) & FL_ONGROUND);
	char attacktype[] = "m_flNextPrimaryAttack";
	if (UnblockPrimary[client] && !g_cvDisableOnGround.BoolValue && IsOnGround)
	{
		UnblockAttack(client, entityNumber, attacktype[0]);
	}
	
	if (g_cvDisableOnGround.BoolValue && IsOnGround)
	{
		Blockattack(client, entityNumber, attacktype[0]);
	}
	
	if (UnblockPrimary[client] && !g_cvDisableInAir.BoolValue && !IsOnGround)
	{
		UnblockAttack(client, entityNumber, attacktype[0]);
	}
	
	if (g_cvDisableInAir.BoolValue && !IsOnGround)
	{
		Blockattack(client, entityNumber, attacktype[0]);
	}
}

stock void DisableSecondaryAttack(int client, int entityNumber)
{
	int IsOnGround = (GetEntityFlags(client) & FL_ONGROUND);
	char attacktype[] = "m_flNextSecondaryAttack";
	
	if (UnblockSecondary[client] && !g_cvDisableOnGround.BoolValue && IsOnGround)
	{
		UnblockAttack(client, entityNumber, attacktype[0]);
	}
	
	if (g_cvDisableOnGround.BoolValue && IsOnGround)
	{
		Blockattack(client, entityNumber, attacktype[0]);
	}
	
	if (UnblockSecondary[client] && !g_cvDisableInAir.BoolValue && !IsOnGround)
	{
		UnblockAttack(client, entityNumber, attacktype[0]);
	}
	
	if (g_cvDisableInAir.BoolValue && !IsOnGround)
	{
		Blockattack(client, entityNumber, attacktype[0]);
	}
}

stock void Blockattack(int client, int entityNumber, const char[] attacktype)
{
	SetEntPropFloat(entityNumber, Prop_Send, attacktype, GetGameTime() + 2.0);
	
	if (StrEqual(attacktype, "m_flNextPrimaryAttack"))
	{
		UnblockPrimary[client] = true;
	}
	
	if (StrEqual(attacktype, "m_flNextSecondaryAttack"))
	{
		UnblockSecondary[client] = true;
		int fov;
		GetEntProp(client, Prop_Send, "m_iFOV", fov);
		if (fov < 90)
		{
			SetEntProp(client, Prop_Send, "m_iFOV", 90);
		}
	}
}

stock void UnblockAttack(int client, int entityNumber, const char[] attacktype)
{
	SetEntPropFloat(entityNumber, Prop_Send, attacktype, GetGameTime() + g_cvDelayReset.FloatValue);
	
	if (StrEqual(attacktype, "m_flNextPrimaryAttack"))
	{
		UnblockPrimary[client] = false;
	}
	
	if (StrEqual(attacktype, "m_flNextSecondaryAttack"))
	{
		UnblockSecondary[client] = false;
	}
}

void CheckGameVersion()
{
	if(GetEngineVersion() != Engine_CSS)
	{
		SetFailState("Only CS:S Supported");
	}
}

stock bool IsClientValid(int client)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		return true;
	}
	return false;
}

public Plugin myinfo = {
	name = NAME,
	author = AUTHOR,
	description = DESCRIPTION,
	version = PLUGIN_VERSION,
	url = URL
}

public Action smAbout(int client, int args)
{
	PrintToConsole(client, "");
	PrintToConsole(client, "Plugin Name.......: %s", NAME);
	PrintToConsole(client, "Plugin Author.....: %s", AUTHOR);
	PrintToConsole(client, "Plugin Description: %s", DESCRIPTION);
	PrintToConsole(client, "Plugin Version....: %s", PLUGIN_VERSION);
	PrintToConsole(client, "Plugin URL........: %s", URL);
	PrintToConsole(client, "List of cvars: ");
	PrintToConsole(client, "sm_disableattack_enable <1|0>");
	PrintToConsole(client, "sm_disableattack_primary <1|0>");
	PrintToConsole(client, "sm_disableattack_Secondary <1|0>");
	PrintToConsole(client, "sm_disableattack_inair <1|0>");
	PrintToConsole(client, "sm_disableattack_onground <1|0>");
	PrintToConsole(client, "sm_disableattack_DelayReset <-1.0|1.0>");
	return Plugin_Continue;
}
