#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#define CVAR_FLAGS		FCVAR_NOTIFY

#define SERVER_INDEX 0
#define NO_INDEX 	-1
#define NO_PLAYER 	-2
#define BLUE_INDEX 	 2
#define RED_INDEX 	 3
#define MAX_COLORS 	 6
#define MAX_MESSAGE_LENGTH 254

bool   g_bSMNotity;
int    g_iTextMsg, g_iPZDmgMsg, g_iConVar, g_iDeath, g_iIncapacitated, g_iDisconnect, g_iDefibrillator;
ConVar g_hTextMsg, g_hPZDmgMsg, g_hConVar, g_hDeath, g_hIncapacitated, g_hDisconnect, g_hDefibrillator, g_cvSMNotity;

#define PLUGIN_VERSION 	"1.1.2"
/* 感谢 sorallll 提供 TextMsg 和 PZDmgMsg */
public Plugin myinfo =
{
	name = "[L4D2] PZDmgMsg(屏蔽游戏自带的部分提示)",
	author = "豆瓣酱な, 修改:GJken", 
	description = "屏蔽游戏自带的部分提示",
	version = PLUGIN_VERSION,
	url = "N/A"
};


public void OnPluginStart()
{
	g_hTextMsg = CreateConVar("l4d2_text_msg", "1", "屏蔽游戏自带的闲置提示 0=显示, 1=屏蔽", CVAR_FLAGS);
	g_hPZDmgMsg = CreateConVar("l4d2_PZDmg_msg", "1", "屏蔽游戏自带的其它提示 0=显示, 1=屏蔽", CVAR_FLAGS);
	g_hConVar = CreateConVar("l4d2_server_cvar", "1", "屏蔽游戏自带的ConVar更改提示 0=显示, 1=屏蔽", CVAR_FLAGS);
	g_hDeath = CreateConVar("l4d2_player_death", "1", "屏蔽游戏自带的玩家死亡提示 0=显示, 1=屏蔽", CVAR_FLAGS);
	g_hIncapacitated = CreateConVar("l4d2_player_incapacitated", "1", "屏蔽游戏自带的玩家倒下提示 0=显示, 1=屏蔽", CVAR_FLAGS);
	g_hDisconnect = CreateConVar("l4d2_player_disconnect", "1", "屏蔽游戏自带的玩家离开提示 0=显示, 1=屏蔽", CVAR_FLAGS);
	g_hDefibrillator = CreateConVar("l4d2_defibrillator_used", "1", "屏蔽游戏自带的使用电击器提示 0=显示, 1=屏蔽", CVAR_FLAGS);
	g_cvSMNotity = CreateConVar("l4d2_sourcemod_sm_notify_admin", "0", "屏蔽sourcemod平台自带的SM提示 1=只向管理员显示, 0=对所有人屏蔽", CVAR_FLAGS);

	AutoExecConfig(true, "l4d2_PZDmgMsg");

	g_hTextMsg.AddChangeHook(ConVarChanged);
	g_hPZDmgMsg.AddChangeHook(ConVarChanged);
	g_hConVar.AddChangeHook(ConVarChanged);
	g_hDeath.AddChangeHook(ConVarChanged);
	g_cvSMNotity.AddChangeHook(ConVarChanged);

	g_hIncapacitated.AddChangeHook(ConVarChanged);
	g_hDisconnect.AddChangeHook(ConVarChanged);
	g_hDefibrillator.AddChangeHook(ConVarChanged);
	
	HookUserMessage(GetUserMessageId("TextMsg"), IsTextMsg, true);//屏蔽游戏自带的闲置提示
	HookUserMessage(GetUserMessageId("PZDmgMsg"), IsPZDmgMsg, true);//屏蔽游戏自带的其它提示
	HookEvent("server_cvar", Event_ServerCvar, EventHookMode_Pre);//屏蔽游戏自带的ConVar更改提示
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);//屏蔽游戏自带的玩家死亡提示(好像会导致游戏自带的结算界面统计出问题).
	HookEvent("player_incapacitated", Event_PayerIncapacitated, EventHookMode_Pre);//屏蔽游戏自带的玩家倒下提示
	HookEvent("defibrillator_used", Event_DefibrillatorUsed, EventHookMode_Pre);//屏蔽游戏自带的使用电击器提示
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);//屏蔽游戏自带的玩家离开提示
	HookUserMessage(GetUserMessageId("TextMsg"), smTextMsg, true);//屏蔽sourcemod平台自带的SM提示
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

public void OnConfigsExecuted()
{
	GetCvars();
}

void GetCvars()
{
	g_iTextMsg = g_hTextMsg.IntValue;
	g_iPZDmgMsg = g_hPZDmgMsg.IntValue;
	g_iConVar = g_hConVar.IntValue;
	g_iDeath = g_hDeath.IntValue;
	g_iIncapacitated = g_hIncapacitated.IntValue;
	g_iDisconnect = g_hDisconnect.IntValue;
	g_iDefibrillator = g_hDefibrillator.IntValue;
	g_bSMNotity = g_cvSMNotity.BoolValue;
}

//屏蔽游戏自带的其它提示
public Action IsPZDmgMsg(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init) 
{
	if(g_iPZDmgMsg == 0)
		return Plugin_Continue;
	return Plugin_Handled;
}

//屏蔽游戏自带的闲置提示
public Action IsTextMsg(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init) 
{
	if(g_iTextMsg == 0)
		return Plugin_Continue;
	
	static char sMsg[254];
	msg.ReadString(sMsg, sizeof sMsg);

	if (strcmp(sMsg, "\x03#L4D_idle_spectator") == 0) //聊天栏提示:XXX 现已闲置
		return Plugin_Handled;
	return Plugin_Continue;
}

//屏蔽游戏自带的ConVar更改提示
public Action Event_ServerCvar(Event event, const char[] name, bool dontBroadcast)
{
	if(g_iConVar == 0)
		return Plugin_Continue;
	return Plugin_Handled;
}

//屏蔽sourcemod平台自带的SM提示
Action smTextMsg(UserMsg msg_id, BfRead msg, const int[] players, int num, bool reliable, bool init)
{
	static char buffer[254];
	msg.ReadString(buffer, sizeof buffer);

	if (StrContains(buffer, "\x03[SM]") == 0) {//聊天栏以[SM]开头的消息
		if (g_bSMNotity) {
			DataPack dPack = new DataPack();
			dPack.WriteCell(num);
			for (int i; i < num; i++)
				dPack.WriteCell(players[i]);

			dPack.WriteString(buffer);
			RequestFrame(NextFrame_SMMessage, dPack);
		}

		return Plugin_Handled;
	}

	return Plugin_Continue;
}

void NextFrame_SMMessage(DataPack dPack)
{
	dPack.Reset();
	int num = dPack.ReadCell();
	int[] players = new int[num];

	int client, count;
	for (int i; i < num; i++) {
		client = dPack.ReadCell();
		if (IsClientInGame(client) && !IsFakeClient(client) && CheckCommandAccess(client, "", ADMFLAG_ROOT))
			players[count++] = client;
	}

	if (!count) {
		delete dPack;
		return;
	}

	char buffer[254];
	dPack.ReadString(buffer, sizeof buffer);
	delete dPack;

	ReplaceStringEx(buffer, sizeof buffer, "[SM]", "\x04[SM]\x05");
	BfWrite bf = view_as<BfWrite>(StartMessage("SayText2", players, count, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS));
	bf.WriteByte(-1);
	bf.WriteByte(true);
	bf.WriteString(buffer);
	EndMessage();
}


//屏蔽游戏自带的玩家死亡提示(好像会导致游戏自带的结算界面统计出问题).
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	if(g_iDeath == 0)
		return;
	event.BroadcastDisabled = true;
}

//屏蔽游戏自带的玩家倒下提示
public void Event_PayerIncapacitated(Event event, const char[] name, bool dontBroadcast) 
{
	if(g_iIncapacitated == 0)
		return;
	event.BroadcastDisabled = true;
}

//屏蔽游戏自带的玩家离开提示
public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast) 
{
	if(g_iDisconnect == 0)
		return;
	event.BroadcastDisabled = true;
}

//屏蔽游戏自带的使用电击器提示
public void Event_DefibrillatorUsed(Event event, const char[] name, bool dontBroadcast) 
{
	if(g_iDefibrillator == 0)
		return;
	event.BroadcastDisabled = true;
}
