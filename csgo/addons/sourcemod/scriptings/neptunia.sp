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
int g_iClientModel[MAXPLAYERS+1][4];

public Plugin myinfo = 
{
	name = "Neptunia Model for CSGO",
	author = "maoling ( xQy )",
	description = "",
	version = "1.2",
	url = "http://steamcommunity.com/id/_xQy_/"
};

public void OnPluginStart()
{
	LoadModelsData();
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
	
	RegConsoleCmd("sm_nep", Command_Menu);
	RegConsoleCmd("sm_neptunia", Command_Menu);
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
		g_eModel[g_iModels][iTeam] = KvGetNum(m_hKV, "team", 0);
		
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
	for(int x; x < 4; ++x)
		g_iClientModel[client][x] = -1;
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
	
	PreSetClientModel(client, GetClientTeam(client), false);

	return Plugin_Stop;
}

public Action Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Continue;

	PreSetClientModel(client, GetEventInt(event, "team"), true);

	return Plugin_Continue;
}

void PreSetClientModel(int client, int team, bool reset)
{
	if(g_iClientModel[client][team] == -1)
	{
		PrintToChat(client, "[\x0EPlaneptune\x01]  Type \x04!nep \x01in chat to select models")
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
	SetEntProp(client, Prop_Send, "m_nSkin", 0);
	SetEntProp(client, Prop_Data, "m_nSkin", 0);
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
			ResetPlayerArms(client);
		}
	}
}


// re fix arms is not true
stock void ResetPlayerArms(int client)
{
	int iWeapon;
	
	char szWeapon[4][32];
	
	for(int slot; slot < 4; ++slot)
	{
		iWeapon = -1;
		if((iWeapon = GetPlayerWeaponSlot(client, slot)) != -1 && IsValidEntity(iWeapon))
		{
			GetEdictClassname(iWeapon, szWeapon[slot], 32);

			switch(GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex"))
			{
				case 60: strcopy(szWeapon[slot], 32, "weapon_m4a1_silencer");
				case 61: strcopy(szWeapon[slot], 32, "weapon_usp_silencer");
				case 63: strcopy(szWeapon[slot], 32, "weapon_cz75a");
				case 64: strcopy(szWeapon[slot], 32, "weapon_revolver");
			}

			RemovePlayerItem(client, iWeapon);
			AcceptEntityInput(iWeapon, "Kill");
		}
	}

	Handle pack;
	CreateDataTimer(0.5, Timer_ResetPlayerArms, pack);
	WritePackCell(pack, GetClientUserId(client));
	WritePackString(pack, szWeapon[0]);
	WritePackString(pack, szWeapon[1]);
	WritePackString(pack, szWeapon[2]);
	WritePackString(pack, szWeapon[3]);
}

public Action Timer_ResetPlayerArms(Handle timer, Handle pack)
{
	int client;
	char szWeapon[4][32];
	
	ResetPack(pack);
	client = GetClientOfUserId(ReadPackCell(pack));
	ReadPackString(pack, szWeapon[0], 32);
	ReadPackString(pack, szWeapon[1], 32);
	ReadPackString(pack, szWeapon[2], 32);
	ReadPackString(pack, szWeapon[3], 32);
	
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	for(int slot; slot < 4; ++slot)
	{
		if(strlen(szWeapon[slot]) > 7)
			GivePlayerItem(client, szWeapon[slot]);
	}
}

public Action Command_Menu(int client, int args)
{
	BuildMenuToClient(client);
}

void BuildMenuToClient(int client)
{
	Handle menu = CreateMenu(MenuHandler_MainMenu);
	
	char m_szItem[128], m_szCT[128], m_szTE[128];
	
	if(g_iClientModel[client][3] < 0)
		strcopy(m_szCT, 128, "none");
	else
		strcopy(m_szCT, 128, g_eModel[g_iClientModel[client][3]][szName]);
	
	if(g_iClientModel[client][2] < 0)
		strcopy(m_szTE, 128, "none");
	else
		strcopy(m_szTE, 128, g_eModel[g_iClientModel[client][2]][szName]);

	Format(m_szItem, 128, "[Planeptune] - Select Your Model\n \nCurrent CT: %s\nCurrent TE: %s \n ", m_szCT, m_szTE);
	SetMenuTitle(menu, m_szItem, client);
	
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
	
	char m_szItem[128];
	Format(m_szItem, 128, "[Planeptune] - Select Your Model\n ");
	SetMenuTitle(menu, m_szItem, client);
	
	char m_szId[4];
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
			
			int m_id = StringToInt(info);

			g_iClientModel[client][g_eModel[m_id][iTeam]] = m_id;
			
			PrintToChat(client, "[\x0EPlaneptune\x01]  You have selected \x0C%s \x01as your model", g_eModel[m_id][szName]);
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