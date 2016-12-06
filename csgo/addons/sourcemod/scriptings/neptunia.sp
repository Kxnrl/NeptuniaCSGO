/**
 ** Model by ComplieHeart
 ** CSGO by Valve
 ** Ripped by maoling( xQy ) and jh10001
 ** CSGO Model Source by maoling( xQy )
 ** CSGO Plugin by maoling( xQy ) 
 ** Steam: http://steamcommunity.com/id/_xQy_/
*/

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

enum Models
{
	String:szName[128],
	String:szModel[128],
	String:szArms[128],
	iModel,
	iTeam,
}

int g_iModels;
Models g_eModel[24][Models];
int g_iClientModel[MAXPLAYERS+1][2];
int g_iAdminTarget[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "Neptunia Model for CSGO",
	author = "maoling ( xQy )",
	description = "",
	version = "1.5r1",
	url = "http://steamcommunity.com/id/_xQy_/"
};

public void OnPluginStart()
{
	LoadModelsData();
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
	
	RegConsoleCmd("sm_nep", Command_Menu);
	RegConsoleCmd("sm_neptunia", Command_Menu);
	
	RegAdminCmd("nmdmin", Command_Admin, ADMFLAG_BAN);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		strcopy(error, err_max, "Current Game is not supported!");
		return APLRes_Failure;
	}
	
	return APLRes_Success;
}

void LoadModelsData()
{
	char m_szFile[64];
	BuildPath(Path_SM, m_szFile, 64, "configs/neptunia.models");
	
	Handle m_hKV = CreateKeyValues("Neptunia");
	FileToKeyValues(m_hKV, m_szFile);
	
	if(!KvGotoFirstSubKey(m_hKV))
	{
		SetFailState("Failed to read configs/neptunia.models");
		return;
	}
	
	do
	{
		KvGetSectionName(m_hKV, g_eModel[g_iModels][szName], 128);
		KvGetString(m_hKV, "model", g_eModel[g_iModels][szModel], 128);
		KvGetString(m_hKV, "arms", g_eModel[g_iModels][szArms], 128);
		g_eModel[g_iModels][iTeam] = KvGetNum(m_hKV, "team", 0)-2;
		
		if(!FileExists(g_eModel[g_iModels][szModel]))
			continue;

		g_iModels++;
	}
	while (KvGotoNextKey(m_hKV));

	CloseHandle(m_hKV);
}

public void OnMapStart()
{
	PreparingAllModels();
	AddTextrureToDownoadTable()
}

public void PreparingAllModels()
{
	for(int i = 0; i < g_iModels; ++i)
	{
		g_eModel[i][iModel] = PrecacheModel(g_eModel[i][szModel], true);
		AddFileToDownloadsTable2(g_eModel[i][szModel], false);
		
		if(g_eModel[i][szArms][0] != 0 && FileExists(g_eModel[i][szArms]))
		{
			PrecacheModel(g_eModel[i][szArms], true);
			AddFileToDownloadsTable2(g_eModel[i][szArms], true);
		}
	}
}

stock void AddFileToDownloadsTable2(const char[] szMDL, bool arms)
{
	char m_szPath[128], m_szVTX[128], m_szVVD[128], m_szPHY[128];
	
	strcopy(m_szPath, 128, szMDL);
	ReplaceString(m_szPath, 128, ".mdl", "");
	
	strcopy(m_szVTX, 128, m_szPath);
	StrCat(m_szVTX, 128, ".dx90.vtx");
	AddFileToDownloadsTable(m_szVTX);
	
	strcopy(m_szVVD, 128, m_szPath);
	StrCat(m_szVVD, 128, ".vvd");
	AddFileToDownloadsTable(m_szVVD);
	
	if(!arms)
	{
		strcopy(m_szPHY, 128, m_szPath);
		StrCat(m_szPHY, 128, ".phy");
		AddFileToDownloadsTable(m_szPHY);
	}

	AddFileToDownloadsTable(szMDL);
}

public void AddTextrureToDownoadTable()
{
	char m_szFile[64];
	BuildPath(Path_SM, m_szFile, 64, "configs/neptunia.texture");
	Handle m_hFile = OpenFile(m_szFile, "r");
	
	if(!m_hFile)
	{
		LogError("\n Failed to read configs/neptunia.texture  \n Downloader will not work.");
		return;
	}
	
	char m_szBuffer[256];
	int strLen;
	
	//Credits: sm_downloader by SWAT 88
	while(ReadFileLine(m_hFile, m_szBuffer, 256))
	{	
		strLen = strlen(m_szBuffer);
		if(m_szBuffer[strLen-1] == '\n')
			m_szBuffer[--strLen] = '\0';

		TrimString(m_szBuffer);

		if(!StrEqual(m_szBuffer, "", false))
			AddFileToDownloadsTable(m_szBuffer);

		if(IsEndOfFile(m_hFile))
			break;
	}
}

public void OnClientPostAdminCheck(int client)
{
		g_iClientModel[client][0] = -1;
		g_iClientModel[client][1] = -1;
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
	
	PreSetClientModel(client, GetClientTeam(client)-2, false);

	return Plugin_Stop;
}

public Action Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Continue;

	PreSetClientModel(client, GetEventInt(event, "team")-2, true);

	return Plugin_Continue;
}

void PreSetClientModel(int client, int team, bool reset)
{
	if(g_iClientModel[client][team] == -1)
	{
		PrintToChat(client, "[\x0ENeptunia\x01]  Type \x04!nep \x01in chat to select models")
		return;
	}

	if(g_eModel[g_iClientModel[client][team]][iTeam] == team)
	{
		SetClientModel(client, team);
		SetClientArms(client, team, reset);
	}
}

stock void SetClientModel(int client, int team)
{
	SetEntityModel(client, g_eModel[g_iClientModel[client][team]][szModel]);
}

stock void SetClientArms(int client, int team, bool reset)
{
	char currentmodel[128];
	GetEntPropString(client, Prop_Send, "m_szArmsModel", currentmodel, 128);
	
	if(g_eModel[g_iClientModel[client][team]][szArms][0] != 0 && !StrEqual(currentmodel, g_eModel[g_iClientModel[client][team]][szArms]))
	{
		SetEntPropString(client, Prop_Send, "m_szArmsModel", g_eModel[g_iClientModel[client][team]][szArms]);
		
		if(reset)
		{
			CreateTimer(0.5, Timer_FixPlayerArms, GetClientUserId(client));
		}
	}
}

public Action Timer_FixPlayerArms(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client))
		PreSetClientModel(client, GetClientTeam(client)-2, false);
}

public Action Command_Menu(int client, int args)
{
	BuildMenuToClient(client);
}

void BuildMenuToClient(int client)
{
	Handle menu = CreateMenu(MenuHandler_MainMenu);
	
	char m_szItem[128];

	SetMenuTitle(menu, "[Neptunia] - Select Your Model\n ");
	
	if(g_iClientModel[client][1] < 0)
		strcopy(m_szItem, 128, "none");
	else
		Format(m_szItem, 128, "Current CT: %s", g_eModel[g_iClientModel[client][1]][szName]);

	AddMenuItem(menu, "", m_szItem, ITEMDRAW_DISABLED);
	
	if(g_iClientModel[client][0] < 0)
		strcopy(m_szItem, 128, "none");
	else
		Format(m_szItem, 128, "Current TE: %s", g_eModel[g_iClientModel[client][0]][szName]);
	
	AddMenuItem(menu, "", m_szItem, ITEMDRAW_DISABLED);
	
	AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
	
	AddMenuItem(menu, "3", "Select CT Model", ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "2", "Select TE Model", ITEMDRAW_DEFAULT);
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 10);
}

public int MenuHandler_MainMenu(Handle menu, MenuAction action, int client, int itemNum) 
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			GetMenuItem(menu, itemNum, info, 32);
			
			BuildSelectMenuToClient(client, StringToInt(info));
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

void BuildSelectMenuToClient(int client, int team)
{
	Handle menu = CreateMenu(MenuHandler_SelectMenu);
	
	char m_szItem[128], m_szId[4];
	Format(m_szItem, 128, "[Neptunia] - Select Your Model\n ");
	SetMenuTitle(menu, m_szItem, client);

	for(int mdl; mdl < g_iModels; ++mdl)
	{
		if(g_eModel[mdl][iTeam] == team)
		{
			IntToString(mdl, m_szId, 4);
			
			if(g_iClientModel[client][team] == mdl)
			{
				char szCurrent[256];
				Format(szCurrent, 256, "%s (Current Selected)", g_eModel[mdl][szName]);
				AddMenuItem(menu, m_szId, szCurrent, ITEMDRAW_DISABLED);
			}
			else
			{
				AddMenuItem(menu, m_szId, g_eModel[mdl][szName], ITEMDRAW_DEFAULT);
			}
		}
	}
	
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 10);
}

public int MenuHandler_SelectMenu(Handle menu, MenuAction action, int client, int itemNum) 
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			GetMenuItem(menu, itemNum, info, 32);
			
			int m_Id = StringToInt(info);

			g_iClientModel[client][g_eModel[m_Id][iTeam]] = m_Id;
			
			PrintToChat(client, "[\x0ENeptunia\x01]  You have selected \x0C%s \x01as your model", g_eModel[m_Id][szName]);
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
        {
            if(itemNum == MenuCancel_ExitBack)
            {
                BuildMenuToClient(client);
            }
        }
	}
}

public Action Command_Admin(int client, int args)
{
	Handle menu = CreateMenu(MenuHandler_AdminMenu);
	
	g_iAdminTarget[client] = 0;
	
	char m_szItem[128];
	Format(m_szItem, 128, "[Neptunia] - Select Client\n ");
	SetMenuTitle(menu, m_szItem, client);
	
	for(int target = 1; target <= MaxClients; ++target)
	{
		if(!IsClientInGame(target))
			continue;
		
		int m_iTeam = GetClientTeam(target);
		
		if(m_iTeam <= 1)
			continue;
		
		char m_szId[4];

		if(m_iTeam == 2)
			Format(m_szItem, 128, "[TE] %N", target);
		else if(m_iTeam == 3)
			Format(m_szItem, 128, "[CT] %N", target);
		
		IntToString(GetClientUserId(target), m_szId, 4);
		
		AddMenuItem(menu, m_szId, m_szItem, ITEMDRAW_DEFAULT);
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int MenuHandler_AdminMenu(Handle menu, MenuAction action, int client, int itemNum) 
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			GetMenuItem(menu, itemNum, info, 32);
			
			g_iAdminTarget[client] = StringToInt(info);
			
			int target = GetClientOfUserId(g_iAdminTarget[client]);

			if(!target || !IsClientInGame(target))
			{
				PrintToChat(client, "[\x0ENeptunia\x01]  \x04Target is not in Game.");
				g_iAdminTarget[client] = 0;
				return;
			}
			
			BuildAdminMenu(client);
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

void BuildAdminMenu(int client)
{
	Handle menu = CreateMenu(MenuHandler_AdminSelectMenu);
	
	char m_szItem[128], m_szId[4];
	Format(m_szItem, 128, "[Neptunia] - Select %N Model\n ", g_iAdminTarget[client]);
	SetMenuTitle(menu, m_szItem, client);

	int target = GetClientOfUserId(g_iAdminTarget[client]);
	int m_iTeam = GetClientTeam(target)-2;
	for(int mdl; mdl < g_iModels; ++mdl)
	{
		if(g_eModel[mdl][iTeam] == m_iTeam)
		{
			IntToString(mdl, m_szId, 4);
			
			if(g_iClientModel[target][m_iTeam] == mdl)
			{
				char szCurrent[256];
				Format(szCurrent, 256, "%s (Current target Selected)", g_eModel[mdl][szName]);
				AddMenuItem(menu, m_szId, szCurrent, ITEMDRAW_DISABLED);
			}
			else
			{
				AddMenuItem(menu, m_szId, g_eModel[mdl][szName], ITEMDRAW_DEFAULT);
			}
		}
	}
	
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int MenuHandler_AdminSelectMenu(Handle menu, MenuAction action, int client, int itemNum) 
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			GetMenuItem(menu, itemNum, info, 32);
			
			int m_Id = StringToInt(info);
			
			int target = GetClientOfUserId(g_iAdminTarget[client]);
			
			if(!target || !IsClientInGame(target))
			{
				PrintToChat(client, "[\x0ENeptunia\x01]  \x04Target is not in Game.");
				g_iAdminTarget[client] = 0;
				return;
			}

			g_iClientModel[target][g_eModel[m_Id][iTeam]] = m_Id;
			
			PreSetClientModel(target, GetClientTeam(target)-2, true);
			
			PrintToChat(client, "[\x0ENeptunia\x01]  Set %N model successful!", target);
			
			g_iAdminTarget[client] = 0;
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
        {
            if(itemNum == MenuCancel_ExitBack)
            {
                Command_Admin(client, 0);
            }
        }
	}
}