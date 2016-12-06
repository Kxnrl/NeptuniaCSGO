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
#include <fpvm_interface>

#pragma newdecls required

enum Models
{
	String:szName[128],
	String:szModelV[128],
	String:szModelW[128],
	String:szModelD[128],
	iCacheV,
	iCacheW
}

int g_eModel[12][Models];
int g_iModels;
int g_iClientModel[MAXPLAYERS+1];
int g_iAdminTarget[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "Neptunia Sword for CSGO",
	author = "maoling ( xQy )",
	description = "",
	version = "1.5r1",
	url = "http://steamcommunity.com/id/_xQy_/"
};

public void OnPluginStart()
{
	LoadModelsData();
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);

	//I am not sure use custom weapon will get TOKEN(GSLT) ban? but sword is safe.
	RegConsoleCmd("sm_sword", Command_Sword);
	RegConsoleCmd("sm_knife", Command_Sword);
	RegConsoleCmd("sm_nsword", Command_Sword);
	
	RegAdminCmd("nsadmin", Command_Admin, ADMFLAG_BAN);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(!FindPluginByFile("fpvm_interface.smx"))
	{
		strcopy(error, err_max, "FPVMI is not installed!  https://github.com/Franc1sco/First-Person-View-Models-Interface");
		return APLRes_Failure;
	}

	return APLRes_Success;
}

void LoadModelsData()
{
	char m_szFile[64];
	BuildPath(Path_SM, m_szFile, 64, "configs/neptunia.sword.models");
	
	Handle m_hKV = CreateKeyValues("Neptunia");
	FileToKeyValues(m_hKV, m_szFile);
	
	if(!KvGotoFirstSubKey(m_hKV))
	{
		SetFailState("Failed to read configs/neptunia.sword.models");
		return;
	}

	do
	{
		KvGetSectionName(m_hKV, g_eModel[g_iModels][szName], 128);
		KvGetString(m_hKV, "vmodel", g_eModel[g_iModels][szModelV], 128);
		KvGetString(m_hKV, "wmodel", g_eModel[g_iModels][szModelW], 128);
		KvGetString(m_hKV, "dmodel", g_eModel[g_iModels][szModelD], 128);
		
		if(!FileExists(g_eModel[g_iModels][szModelV]))
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
		g_eModel[i][iCacheV] = PrecacheModel(g_eModel[i][szModelV], true);
		AddFileToDownloadsTable2(g_eModel[i][szModelV], true);
		
		if(g_eModel[i][szModelW][0] != 0 && FileExists(g_eModel[i][szModelW]))
		{
			if((g_eModel[i][iCacheW] = PrecacheModel(g_eModel[i][szModelW], true)) == 0)
				g_eModel[i][iCacheW] = -1;

			AddFileToDownloadsTable2(g_eModel[i][szModelW], false);
		}
		
		// hmm. i dont make drop model, but may be in the future...
		if(g_eModel[i][szModelW][0] != 0 && FileExists(g_eModel[i][szModelW]) && !IsModelPrecached(g_eModel[i][szModelD]))
		{
			PrecacheModel(g_eModel[i][szModelD], true);
			AddFileToDownloadsTable2(g_eModel[i][szModelD], false);
		}
	}
}

stock void AddFileToDownloadsTable2(const char[] szMDL, bool view)
{
	char m_szPath[128], m_szVTX[128], m_szVVD[128], m_szANI[128], m_szPHY[128];
	
	strcopy(m_szPath, 128, szMDL);
	ReplaceString(m_szPath, 128, ".mdl", "");
	
	strcopy(m_szVTX, 128, m_szPath);
	StrCat(m_szVTX, 128, ".dx90.vtx");
	AddFileToDownloadsTable(m_szVTX);
	
	strcopy(m_szVVD, 128, m_szPath);
	StrCat(m_szVVD, 128, ".vvd");
	AddFileToDownloadsTable(m_szVVD);
	
	if(view)
	{
		strcopy(m_szANI, 128, m_szPath);
		StrCat(m_szANI, 128, ".ani");
		AddFileToDownloadsTable(m_szANI);
	}
	else
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
	BuildPath(Path_SM, m_szFile, 64, "configs/neptunia.sword.texture");
	Handle m_hFile = OpenFile(m_szFile, "r");
	
	if(!m_hFile)
	{
		LogError("\n Failed to read configs/neptunia.sword.texture  \n Downloader will not work.");
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
	g_iClientModel[client] = -1;
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client) || g_iClientModel[client] > -1)
		return Plugin_Stop;
	
	PrintToChat(client, "[\x0EPlaneptune\x01]  Type \x04!nsword \x01in chat to select sword");

	return Plugin_Stop;
}

public Action Command_Sword(int client, int args)
{
	BuildMenuToClient(client);
}

void BuildMenuToClient(int client)
{
	Handle menu = CreateMenu(MenuHandler_MainMenu);
	
	char m_szItem[128], m_szId[4];
	
	if(g_iClientModel[client] < 0)
		strcopy(m_szItem, 128, "none");
	else
		strcopy(m_szItem, 128, g_eModel[g_iClientModel[client]][szName]);

	Format(m_szItem, 128, "[Planeptune] - Select Your Sword\n \nCurrent: %s\n ", m_szItem);
	SetMenuTitle(menu, m_szItem, client);

	for(int id; id < g_iModels; ++id)
	{
		IntToString(id, m_szId, 4);
		
		if(g_iClientModel[client] == id)
		{
			char szCurrent[256];
			Format(szCurrent, 256, "%s (Current Selected)", g_eModel[id][szName]);
			AddMenuItem(menu, m_szId, szCurrent, ITEMDRAW_DISABLED);
		}
		else
		{
			AddMenuItem(menu, m_szId, g_eModel[id][szName], ITEMDRAW_DEFAULT);
		}
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int MenuHandler_MainMenu(Handle menu, MenuAction action, int client, int itemNum) 
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			GetMenuItem(menu, itemNum, info, 32);
			
			int m_iId = StringToInt(info);
			
			g_iClientModel[client] = m_iId;
			
			FPVMI_SetClientModel(client, "weapon_knife", g_eModel[m_iId][iCacheV], g_eModel[m_iId][iCacheW], g_eModel[m_iId][szModelD]);
			
			PrintToChat(client, "[\x0EPlaneptune\x01]  You have selected \x0C%s \x01as your sword", g_eModel[m_iId][szName]);
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public Action Command_Admin(int client, int args)
{
	Handle menu = CreateMenu(MenuHandler_AdminMenu);
	
	g_iAdminTarget[client] = 0;
	
	char m_szItem[128];
	Format(m_szItem, 128, "[Planeptune] - Select Client\n ");
	SetMenuTitle(menu, m_szItem, client);
	
	for(int target = 1; target <= MaxClients; ++target)
	{
		if(!IsClientInGame(target))
			continue;
		
		int m_iTeam = GetClientTeam(target);
		
		if(m_iTeam <= 1)
			continue;
		
		char m_szId[4];

		GetClientName(target, m_szItem, 128);
		
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
				PrintToChat(client, "[\x0EPlaneptune\x01]  \x04Target is not in Game.");
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
	Format(m_szItem, 128, "[Planeptune] - Select %N Model\n ", g_iAdminTarget[client]);
	SetMenuTitle(menu, m_szItem, client);

	int target = GetClientOfUserId(g_iAdminTarget[client]);
	for(int id; id < g_iModels; ++id)
	{
		IntToString(id, m_szId, 4);
		
		if(g_iClientModel[target] == id)
		{
			char szCurrent[256];
			Format(szCurrent, 256, "%s (Current Selected)", g_eModel[id][szName]);
			AddMenuItem(menu, m_szId, szCurrent, ITEMDRAW_DISABLED);
		}
		else
		{
			AddMenuItem(menu, m_szId, g_eModel[id][szName], ITEMDRAW_DEFAULT);
		}
	}

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
				PrintToChat(client, "[\x0EPlaneptune\x01]  \x04Target is not in Game.");
				g_iAdminTarget[client] = 0;
				return;
			}

			g_iClientModel[client] = m_Id;
			
			FPVMI_SetClientModel(client, "weapon_knife", g_eModel[m_Id][iCacheV], g_eModel[m_Id][iCacheW], g_eModel[m_Id][szModelD]);

			PrintToChat(client, "[\x0EPlaneptune\x01]  Set %N model as [\x04%s\x01] successful!", target, g_eModel[m_Id][szName]);
			
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