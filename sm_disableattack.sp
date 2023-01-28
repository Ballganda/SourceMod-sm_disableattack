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
ConVar g_cvDisablePrimary = null;
ConVar g_cvDisableSecondary = null;
ConVar g_cvDisableInAir = null;
ConVar g_cvDisableOnGround = null;
ConVar g_cvDelayReset = null;

// '\0' is null 
//int m_flNextPrimaryAttack = '\0';
//int m_flNextSecondaryAttack = '\0';
//int m_flTimeWeaponIdle = '\0';

bool ResetPrimary[MAXPLAYERS + 1];
bool SetPrimary[MAXPLAYERS + 1];
bool ResetSecondary[MAXPLAYERS + 1];

public void OnPluginStart()
{
	CheckGameVersion();

	RegAdminCmd("sm_disableattack", smAbout, ADMFLAG_BAN, "sm_disableattack info in console");

	CreateConVar("sm_disableattack_version", PLUGIN_VERSION, NAME, FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_cvEnablePlugin = CreateConVar("sm_disableattack_enable", "1", "sm_disableattack_enable enables the plugin <1|0>");
	g_cvDisablePrimary = CreateConVar("sm_disableattack_primary", "1", "Disable primary attack <1|0>");
	g_cvDisableSecondary = CreateConVar("sm_disableattack_Secondary", "1", "Disable secondary <1|0>");
	g_cvDisableInAir = CreateConVar("sm_disableattack_inair", "0", "Disable attack jumping/off ground <1|0>");
	g_cvDisableOnGround = CreateConVar("sm_disableattack_onground", "1", "Disable attack on ground <1|0>");
	g_cvDelayReset = CreateConVar("sm_disableattack_DelayReset", "0.25", "Delay reset attack float <-1.0|1.0>");
	
	AutoExecConfig(true, "sm_disableattack");
	
	//Get the offset for m_flNextPrimaryAttack m_flNextPrimaryAttack
	//m_flNextPrimaryAttack = FindSendPropInfo("CBaseCombatWeapon", "m_flNextPrimaryAttack");
	//m_flNextSecondaryAttack = FindSendPropInfo("CBaseCombatWeapon", "m_flNextSecondaryAttack");
	//m_flTimeWeaponIdle = FindSendPropInfo("CBaseCombatWeapon", "m_flTimeWeaponIdle");
	//m_iShotsFired = FindSendPropInfo("CCSPlayer", "m_iShotsFired");

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
	SetPrimary[client] = true;
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
	
	// if (GetEntProp(activeWeapon, Prop_Send, "m_iClip1") == 30)
	// {
		// PrintToChat(client, "reloaded"); //for debug
		// SetPrimary[client] = true;
	// }
	
	if (g_cvDisablePrimary.BoolValue)
	{
		DisablePrimaryAttack(client, activeWeapon);
	}
	
	if (g_cvDisableSecondary.BoolValue)
	{
		//DisableSecondaryAttack(client, activeWeapon);
	}
	
	return Plugin_Continue;
}

stock void DisablePrimaryAttack(int client, int entityNumber)
{
	int IsOnGround = (GetEntityFlags(client) & FL_ONGROUND);
	if (ResetPrimary[client] && !g_cvDisableOnGround.BoolValue && IsOnGround)
	{
		ResetPrimaryattack(client, entityNumber);
	}
	
	if (g_cvDisableOnGround.BoolValue && IsOnGround && SetPrimary[client])
	{
		SetPrimaryattack(client, entityNumber);
	}
	
	if (ResetPrimary[client] && !g_cvDisableInAir.BoolValue && !IsOnGround)
	{
		ResetPrimaryattack(client, entityNumber);
	}
	
	if (g_cvDisableInAir.BoolValue && !IsOnGround)
	{
		SetPrimaryattack(client, entityNumber);
	}
}

stock Action SetPrimaryattack(int client, int entityNumber)
{
	SetEntPropFloat(entityNumber, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 2.0);
	ResetPrimary[client] = true;
	return Plugin_Continue;
}

void ResetPrimaryattack(int client, int entityNumber)
{
	SetEntPropFloat(entityNumber, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + g_cvDelayReset.FloatValue);
	ResetPrimary[client] = false;
	SetPrimary[client] = true;
}

//int cnt = 0;
public Action OnPlayerRunCmd(int client, int& buttons)
{
	int IsOnGround = (GetEntityFlags(client) & FL_ONGROUND);
	
	if ((buttons & IN_RELOAD) && IsOnGround && SetPrimary[client])
	{
		PrintToChat(client, "Force reload"); //for debug
		buttons &= ~IN_ATTACK;
		int entityNumber = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (!IsValidEntity(entityNumber))
		{
			return Plugin_Continue;
		}
		SetEntPropFloat(entityNumber, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() - 1.0);
		//SetEntProp(int entity, PropType type, const char[] prop, any value, int size = 4, int element = 0)
		//SetEntProp(client, Prop_Send, m_iShotsFired, 1, int size = 4, int element = 0)
		//SetEntData(client, m_iShotsFired, 1);
		
		buttons |= IN_RELOAD;
		SetPrimary[client] = false;
		CreateTimer(0.1, reloadtimersetprimary, client);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action reloadtimersetprimary(Handle timer, int client)
{
	PrintToChat(client, "reloaded"); //for debug
	SetPrimary[client] = true;
	return Plugin_Continue;
}



// stock void DisableSecondaryAttack(int client, int entityNumber)
// {
	// if (ResetSecondary[client] && !g_cvDisableOnGround.BoolValue && (GetEntityFlags(client) & FL_ONGROUND))
	// {
		// SetEntDataFloat(entityNumber, m_flNextSecondaryAttack, GetGameTime() - 1.0);
		// ResetSecondary[client] = false;
	// }
	
	// if (g_cvDisableOnGround.BoolValue && (GetEntityFlags(client) & FL_ONGROUND))
	// {
		// SetEntDataFloat(entityNumber, m_flNextSecondaryAttack, GetGameTime() + 2.0);
		// ResetSecondary[client] = true;
		// int fov;
		// GetEntProp(client, Prop_Send, "m_iFOV", fov);
		// if (fov < 90)
		// {
			// SetEntProp(client, Prop_Send, "m_iFOV", 90);
		// }
	// }
	
	// if (ResetSecondary[client] && !g_cvDisableInAir.BoolValue && !(GetEntityFlags(client) & FL_ONGROUND))
	// {
		// SetEntDataFloat(entityNumber, m_flNextSecondaryAttack, GetGameTime() - 1.0);
		// ResetSecondary[client] = false;
	// }
	
	// if (g_cvDisableInAir.BoolValue && !(GetEntityFlags(client) & FL_ONGROUND))
	// {
		// SetEntDataFloat(entityNumber, m_flNextSecondaryAttack, GetGameTime() + 2.0);
		// ResetSecondary[client] = true;
		// int fov;
		// GetEntProp(client, Prop_Send, "m_iFOV", fov);
		// if (fov < 90)
		// {
			// SetEntProp(client, Prop_Send, "m_iFOV", 90);
		// }
	// }
// }

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
