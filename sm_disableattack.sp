#include <sourcemod>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define NAME "[CS:S]sm_disableattack"
#define AUTHOR "BallGanda"
#define DESCRIPTION "sm_disableattack diabled ability to use primary attack"
#define PLUGIN_VERSION "0.0.b1"
#define URL "https://github.com/Ballganda/SourceMod-sm_disableattack"

public Plugin myinfo = {
	name = NAME,
	author = AUTHOR,
	description = DESCRIPTION,
	version = PLUGIN_VERSION,
	url = URL
}

ConVar g_cvEnablePlugin = null;
ConVar g_cvDisableInAir = null;
ConVar g_cvDisableOnGround = null;

// '\0' is null 
int m_flNextSecondaryAttack = '\0';
int m_flNextPrimaryAttack = '\0';

bool ResetPrimary[MAXPLAYERS + 1];
bool ResetSecondary[MAXPLAYERS + 1];

public void OnPluginStart()
{
	CheckGameVersion();

	RegAdminCmd("sm_disableattack", smAbout, ADMFLAG_BAN, "sm_disableattack info in console");

	CreateConVar("sm_disableattack_version", PLUGIN_VERSION, NAME, FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_cvEnablePlugin = CreateConVar("sm_disableattack_enable", "1", "sm_disablescope_enable enables the plugin <1|0>");
	g_cvDisablePrimary = CreateConVar("sm_disableattack_inair", "1", "Disable Scope when the player is jumping/off ground <1|0>");
	g_cvDisableSecondary = CreateConVar("sm_disableattack_inair", "0", "Disable Scope when the player is jumping/off ground <1|0>");
	g_cvDisableInAir = CreateConVar("sm_disableattack_inair", "0", "Disable Scope when the player is jumping/off ground <1|0>");
	g_cvDisableOnGround = CreateConVar("sm_disableattack_onground", "1", "Disable Scope when the player is on ground <1|0>");
	
	AutoExecConfig(true, "sm_disableattack");
	
	//Get the offset for m_flNextPrimaryAttack
	m_flNextPrimaryAttack = FindSendPropInfo("CBaseCombatWeapon", "m_flNextPrimaryAttack");

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
	ResetPrimary[client] = false;
    ResetSecondary[client] = false;
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
	
	if (g_cvDisablePrimary)
	{
		DisablePrimaryAttack(client, activeWeapon);
	}
	
	if (g_cvDisablePrimary)
	{
		DisableSecondaryAttack(client, activeWeapon);
	}
	
	return Plugin_Continue;
}

stock void DisablePrimaryAttack(int client, int entityNumber)
{
	bool IsOnGround = GetEntityFlags(client) & FL_ONGROUND;
	
	if (ResetPrimary[client] && !g_cvDisableOnGround.BoolValue && IsOnGround)
	{
		SetEntDataFloat(entityNumber, m_flNextPrimaryAttack, GetGameTime() - 1.0);
		ResetPrimary[client] = false;
	}
	
	if (g_cvDisableOnGround.BoolValue && IsOnGround)
	{
		SetEntDataFloat(entityNumber, m_flNextPrimaryAttack, GetGameTime() + 2.0);
		ResetPrimary[client] = true;
	}
	
	if (ResetPrimary[client] && !g_cvDisableInAir.BoolValue && !IsOnGround)
	{
		SetEntDataFloat(entityNumber, m_flNextPrimaryAttack, GetGameTime() - 1.0);
		ResetPrimary[client] = false;
	}
	
	if (g_cvDisableInAir.BoolValue && !IsOnGround)
	{
		SetEntDataFloat(entityNumber, m_flNextPrimaryAttack, GetGameTime() + 2.0);
		ResetPrimary[client] = true;
	}
}

stock void DisableSecondaryAttack(int client, int entityNumber)
{
	bool IsOnGround = GetEntityFlags(client) & FL_ONGROUND;
	
	if (ResetSecondary[client] && !g_cvDisableOnGround.BoolValue && IsOnGround)
	{
		SetEntDataFloat(entityNumber, m_flNextSecondaryAttack, GetGameTime() - 1.0);
		ResetSecondary[client] = false;
	}
	
	if (g_cvDisableOnGround.BoolValue && IsOnGround)
	{
		SetEntDataFloat(entityNumber, m_flNextSecondaryAttack, GetGameTime() + 2.0);
		ResetSecondary[client] = true;
		int fov;
		GetEntProp(client, Prop_Send, "m_iFOV", fov);
		if (fov < 90)
		{
			SetEntProp(client, Prop_Send, "m_iFOV", 90);
		}
	}
	
	if (ResetSecondary[client] && !g_cvDisableInAir.BoolValue && !IsOnGround)
	{
		SetEntDataFloat(entityNumber, m_flNextSecondaryAttack, GetGameTime() - 1.0);
		ResetSecondary[client] = false;
	}
	
	if (g_cvDisableInAir.BoolValue && !IsOnGround)
	{
		SetEntDataFloat(entityNumber, m_flNextSecondaryAttack, GetGameTime() + 2.0);
		ResetSecondary[client] = true;
		int fov;
		GetEntProp(client, Prop_Send, "m_iFOV", fov);
		if (fov < 90)
		{
			SetEntProp(client, Prop_Send, "m_iFOV", 90);
		}
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
	PrintToConsole(client, "sm_disableattack_inair <1|0>");
	PrintToConsole(client, "sm_disableattack_onground <1|0>");
	return Plugin_Continue;
}
