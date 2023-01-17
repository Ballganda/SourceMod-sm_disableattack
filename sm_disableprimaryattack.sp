#include <sourcemod>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define NAME "[CS:S]sm_disableprimaryattack"
#define AUTHOR "BallGanda"
#define DESCRIPTION "sm_disableprimaryattack diabled ability to use primary attack"
#define PLUGIN_VERSION "0.0.b1"
#define URL "https://github.com/Ballganda/SourceMod-sm_disableprimaryattack"

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
//int m_flNextSecondaryAttack = '\0';
int m_flNextPrimaryAttack = '\0';

bool ScopeReset = false;

public void OnPluginStart()
{
	CheckGameVersion();

	RegAdminCmd("sm_disableprimaryattack", smAbout, ADMFLAG_BAN, "sm_disableprimaryattack info in console");

	CreateConVar("sm_disableprimaryattack_version", PLUGIN_VERSION, NAME, FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_cvEnablePlugin = CreateConVar("sm_disablescope_enable", "1", "sm_disablescope_enable enables the plugin <1|0>");
	g_cvDisableInAir = CreateConVar("sm_disablescope_inair", "0", "Disable Scope when the player is jumping/off ground <1|0>");
	g_cvDisableOnGround = CreateConVar("sm_disablescope_onground", "1", "Disable Scope when the player is on ground <1|0>");
	
	AutoExecConfig(true, "sm_disableprimaryattack");
	
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
}

public Action OnPreThink(int client)
{
	if(!g_cvEnablePlugin.BoolValue)
	{
		return Plugin_Handled;
	}
	
	int activeWeapon;
	activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	DisablePrimaryAttack(client, ActiveWeapon);
	}
	return Plugin_Continue;
}

stock void DisablePrimaryAttack(int client, int entityNumber)
{
	if (ScopeReset && !g_cvDisableOnGround.BoolValue && (GetEntityFlags(client) & FL_ONGROUND))
	{
		SetEntDataFloat(entityNumber, m_flNextSecondaryAttack, GetGameTime() - 1.0);
		ScopeReset = false;
	}
	
	if (g_cvDisableOnGround.BoolValue && (GetEntityFlags(client) & FL_ONGROUND))
	{
		SetEntDataFloat(entityNumber, m_flNextSecondaryAttack, GetGameTime() + 2.0);
		ScopeReset = true;
		int fov;
		GetEntProp(client, Prop_Send, "m_iFOV", fov);
		if (fov < 90)
		{
			SetEntProp(client, Prop_Send, "m_iFOV", 90);
		}
	}
	
	if (ScopeReset && !g_cvDisableInAir.BoolValue && !(GetEntityFlags(client) & FL_ONGROUND))
	{
		SetEntDataFloat(entityNumber, m_flNextSecondaryAttack, GetGameTime() - 1.0);
		ScopeReset = false;
	}
	
	if (g_cvDisableInAir.BoolValue && !(GetEntityFlags(client) & FL_ONGROUND))
	{
		SetEntDataFloat(entityNumber, m_flNextSecondaryAttack, GetGameTime() + 2.0);
		ScopeReset = true;
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
	PrintToConsole(client, "sm_disablescope_enable <1|0>");
	PrintToConsole(client, "sm_disablescope_inair <1|0>");
	PrintToConsole(client, "sm_disablescope_onground <1|0>");
	return Plugin_Continue;
}
