/**
 ** CSGO Model Source by maoling( xQy )
 ** CSGO Plugin by maoling( xQy ) 
 ** Steam: http://steamcommunity.com/id/_xQy_/
*/

#include <sourcemod>
#include <sdktools>
#include <fpvm_interface>

#define g_szModelView	"models/maoling/weapon/neptunia/awp/neptune/awp.mdl"
#define g_szModelDrop	"models/maoling/weapon/neptunia/awp/neptune/awp_w_dropped.mdl"
#define g_szModelWrold	"models/maoling/weapon/neptunia/awp/neptune/awp_w.mdl"

int g_iModelCacheW = -1;
int g_iModelCacheV = -1;
int g_iModelCacheD = -1;

bool g_bEquipAwp[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "Neptunia Awp for CSGO",
	author = "maoling ( xQy )",
	description = "",
	version = "1.5r1",
	url = "http://steamcommunity.com/id/_xQy_/"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_awp", Command_Awp);
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

public void OnMapStart()
{
	PreparingAllModels();
	AddTextrureToDownoadTable()
}

public void PreparingAllModels()
{
	g_iModelCacheV = PrecacheModel(g_szModelView, true);
	g_iModelCacheW = PrecacheModel(g_szModelWrold, true);
	g_iModelCacheD = PrecacheModel(g_szModelDrop, true);
}

public void AddTextrureToDownoadTable()
{
	AddFileToDownloadsTable("models/maoling/weapon/neptunia/awp/neptune/awp.mdl");
	AddFileToDownloadsTable("models/maoling/weapon/neptunia/awp/neptune/awp.ani");
	AddFileToDownloadsTable("models/maoling/weapon/neptunia/awp/neptune/awp.vvd");
	AddFileToDownloadsTable("models/maoling/weapon/neptunia/awp/neptune/awp.dx90.vtx");
	AddFileToDownloadsTable("models/maoling/weapon/neptunia/awp/neptune/awp_w.mdl");
	AddFileToDownloadsTable("models/maoling/weapon/neptunia/awp/neptune/awp_w.vvd");
	AddFileToDownloadsTable("models/maoling/weapon/neptunia/awp/neptune/awp_w.dx90.vtx");
	AddFileToDownloadsTable("models/maoling/weapon/neptunia/awp/neptune/awp_w_dropped.mdl");
	AddFileToDownloadsTable("models/maoling/weapon/neptunia/awp/neptune/awp_w_dropped.vvd");
	AddFileToDownloadsTable("models/maoling/weapon/neptunia/awp/neptune/awp_w_dropped.dx90.vtx");
	
	AddFileToDownloadsTable("materials/maoling/weapon/neptunia/awp/neptune/awp.vmt");
	AddFileToDownloadsTable("materials/maoling/weapon/neptunia/awp/neptune/awp.vtf");
	AddFileToDownloadsTable("materials/maoling/weapon/neptunia/awp/neptune/awp_exponent.vtf");
	AddFileToDownloadsTable("materials/maoling/weapon/neptunia/awp/neptune/scope_awp.vmt");
	AddFileToDownloadsTable("materials/maoling/weapon/neptunia/awp/neptune/scope_awp.vtf");
	AddFileToDownloadsTable("materials/maoling/weapon/neptunia/awp/neptune/scope_awp_normal.vtf");
	AddFileToDownloadsTable("materials/maoling/weapon/neptunia/awp/neptune/scope_normal.vtf");
}

public void OnClientPutInServer(int client)
{
	g_bEquipAwp[client] = false;
}

public Action Command_Awp(int client, int args)
{
	if(!client || !IsClientInGame(client))
		return Plugin_Handled;

	if(g_bEquipAwp[client])
	{
		g_bEquipAwp[client] = false;
		PrintToChat(client, "[\x0EPlaneptune\x01]  You unEquipped Neptune`s Awp");
		FPVMI_RemoveViewModelToClient(client, "weapon_awp");
		FPVMI_RemoveWorldModelToClient(client, "weapon_awp");
		FPVMI_RemoveDropModelToClient(client, "weapon_awp");
	}
	else
	{
		g_bEquipAwp[client] = true;
		PrintToChat(client, "[\x0EPlaneptune\x01]  You Equipped Neptune`s Awp");
		FPVMI_SetClientModel(client, "weapon_awp", g_iModelCacheV, g_iModelCacheW, g_szModelDrop);
	}
	
	return Plugin_Handled;
}