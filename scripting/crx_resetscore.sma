#include <amxmodx>
#include <cstrike>
#include <fun>

#define PLUGIN_NAME "Resetscore System"
#define PLUGIN_VERSION "1.1"
#define PLUGIN_AUTHOR "OciXCrom"

#define sReset "buttons/bell1.wav"
#define sResetAll "buttons/lightswitch2.wav"

enum Color
{
	NORMAL = 1, // clients scr_concolor cvar color
	GREEN, // Green Color
	TEAM_COLOR, // Red, grey, blue
	GREY, // grey
	RED, // Red
	BLUE, // Blue
}

new TeamName[][] = 
{
	"",
	"TERRORIST",
	"CT",
	"SPECTATOR"
}


new const g_Commands[][] = {
	"say /rs",
	"say /resetscore",
	"say_team /rs",
	"say_team /resetscore"
}

new cvar_prefix, cvar_alive, cvar_viponly, cvar_vipflag, cvar_limit, cvar_resetkills, cvar_resetdeaths, cvar_resetmoney, cvar_notifyall, cvar_sound, cvar_chat, cvar_adverttime
new limit[33], advert

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_cvar("ResetscoreSystem", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	
	cvar_prefix = 			register_cvar("resetscore_prefix", 			"!g[!tResetscore System!g]")
	cvar_alive = 			register_cvar("resetscore_alive", 			"1")
	cvar_viponly = 			register_cvar("resetscore_viponly", 		"0")
	cvar_vipflag = 			register_cvar("resetscore_vipflag", 		"b")
	cvar_limit =			register_cvar("resetscore_limit", 			"0")
	cvar_resetkills = 		register_cvar("resetscore_resetkills", 		"1")
	cvar_resetdeaths = 		register_cvar("resetscore_resetdeaths", 	"1")
	cvar_resetmoney = 		register_cvar("resetscore_resetmoney",		"0")
	cvar_notifyall = 		register_cvar("resetscore_notifyall", 		"1")
	cvar_sound = 			register_cvar("resetscore_sound", 			"1")
	cvar_chat = 			register_cvar("resetscore_chat", 			"0")
	cvar_adverttime = 		register_cvar("resetscore_adverttime", 		"120")
	
	for(new i = 0; i < sizeof(g_Commands); i++)
		register_clcmd(g_Commands[i], "cmd_resetscore")
}

public plugin_cfg()
{
	advert = get_pcvar_num(cvar_adverttime)
	if(advert > 0) set_task(float(advert), "rs_advertise", 2222, "", 0, "b", 0)
}

public cmd_resetscore(id)
{
	static szPrefix[100]
	szPrefix = get_prefix()
	
	static cmd_limit
	cmd_limit = get_pcvar_num(cvar_limit)
	
	if(!get_pcvar_num(cvar_alive) && is_user_alive(id))
	{
		ColorChat(id, TEAM_COLOR, "%s ^1You can't ^3reset ^1your ^4score ^1while you are ^3alive^1.", szPrefix)
		return PLUGIN_HANDLED
	}
	
	if(get_pcvar_num(cvar_viponly) == 1 && !user_has_flag(id, cvar_vipflag))
	{
		new flag_vip[2]
		get_pcvar_string(cvar_vipflag, flag_vip, charsmax(flag_vip))
		
		ColorChat(id, TEAM_COLOR, "%s ^1Flag ^3%s ^1is neeeded to ^4reset your score^1.", szPrefix, flag_vip)
		return PLUGIN_HANDLED
	}
	
	if(cmd_limit > 0)
	{
		if(limit[id] == cmd_limit)
		{
			ColorChat(id, TEAM_COLOR, "%s ^1You can ^4reset your score ^1only ^3%i ^1times per map.", szPrefix, cmd_limit)
			return PLUGIN_HANDLED
		}
		
		if(limit[id] < cmd_limit)
			limit[id]++
	}
	
	new limit_left = cmd_limit - limit[id]
	
	switch(get_pcvar_num(cvar_notifyall))
	{
		case 0:
		{
			if(cmd_limit > 0)
			{
				if(limit_left == 0) ColorChat(id, TEAM_COLOR, "%s ^1You have just ^3reset ^1your ^4score^1. You ^3can't ^1use this command anymore.", szPrefix)
				else ColorChat(id, TEAM_COLOR, "%s ^1You have just ^3reset ^1your ^4score^1. You can do this ^3%i ^1more time%s.", szPrefix, limit_left, (limit_left == 1) ? "" : "s")
			}
			else ColorChat(id, TEAM_COLOR, "%s ^1You have just ^3reset ^1your ^4score^1.", szPrefix)
		}
		case 1:
		{
			new name[32]
			get_user_name(id, name, charsmax(name))
			
			if(cmd_limit > 0) ColorChat(0, TEAM_COLOR, "%s ^1Player ^3%s ^1has just ^4reset his score ^1[^4Limit: ^3%i^1/^3%i^1]", szPrefix, name, limit[id], cmd_limit)
			else ColorChat(0, TEAM_COLOR, "%s ^1Player ^3%s ^1has just ^4reset his score^1.", szPrefix, name)
		}
	}
	
	switch(get_pcvar_num(cvar_sound))
	{
		case 1: client_cmd(id, "spk %s", sReset)
		case 2: client_cmd(0, "spk %s", sResetAll)
	}
	
	resetscore(id)
	return (get_pcvar_num(cvar_chat) == 1) ? PLUGIN_CONTINUE : PLUGIN_HANDLED
}

public rs_advertise()
	ColorChat(0, TEAM_COLOR, "%s ^1Type ^3/rs ^1or ^3/resetscore ^1to ^4reset your score^1.", get_prefix())

resetscore(id)
{
	if(get_pcvar_num(cvar_resetkills) == 1) set_user_frags(id, 0)
	if(get_pcvar_num(cvar_resetdeaths) == 1) cs_set_user_deaths(id, 0)
	if(get_pcvar_num(cvar_resetmoney) == 1) cs_set_user_money(id, get_cvar_num("mp_startmoney"))
}

stock get_prefix()
{
	static szPrefix[100]
	get_pcvar_string(cvar_prefix, szPrefix, charsmax(szPrefix))
	
	replace_all(szPrefix, charsmax(szPrefix), "!n", "^1")
	replace_all(szPrefix, charsmax(szPrefix), "!t", "^3")
	replace_all(szPrefix, charsmax(szPrefix), "!g", "^4")
	
	return szPrefix
}

stock user_has_flag(id, cvar)
{
	new flags[32]
	get_flags(get_user_flags(id), flags, charsmax(flags))
	
	new vip_flag[2]
	get_pcvar_string(cvar, vip_flag, charsmax(vip_flag))
	
	return (contain(flags, vip_flag) != -1) ? true : false
}

public plugin_precache()
{
	precache_sound(sReset)
	precache_sound(sResetAll)
}

/* ColorChat */

ColorChat(id, Color:type, const msg[], {Float,Sql,Result,_}:...)
{
	static message[256];

	switch(type)
	{
		case NORMAL: // clients scr_concolor cvar color
		{
			message[0] = 0x01;
		}
		case GREEN: // Green
		{
			message[0] = 0x04;
		}
		default: // White, Red, Blue
		{
			message[0] = 0x03;
		}
	}

	vformat(message[1], 251, msg, 4);

	// Make sure message is not longer than 192 character. Will crash the server.
	message[192] = '^0';

	static team, ColorChange, index, MSG_Type;
	
	if(id)
	{
		MSG_Type = MSG_ONE;
		index = id;
	} else {
		index = FindPlayer();
		MSG_Type = MSG_ALL;
	}
	
	team = get_user_team(index);
	ColorChange = ColorSelection(index, MSG_Type, type);

	ShowColorMessage(index, MSG_Type, message);
		
	if(ColorChange)
	{
		Team_Info(index, MSG_Type, TeamName[team]);
	}
}

ShowColorMessage(id, type, message[])
{
	message_begin(type, get_user_msgid("SayText"), _, id);
	write_byte(id)		
	write_string(message);
	message_end();	
}

Team_Info(id, type, team[])
{
	message_begin(type, get_user_msgid("TeamInfo"), _, id);
	write_byte(id);
	write_string(team);
	message_end();

	return 1;
}

ColorSelection(index, type, Color:Type)
{
	switch(Type)
	{
		case RED:
		{
			return Team_Info(index, type, TeamName[1]);
		}
		case BLUE:
		{
			return Team_Info(index, type, TeamName[2]);
		}
		case GREY:
		{
			return Team_Info(index, type, TeamName[0]);
		}
	}

	return 0;
}

FindPlayer()
{
	static i;
	i = -1;

	while(i <= get_maxplayers())
	{
		if(is_user_connected(++i))
		{
			return i;
		}
	}

	return -1;
}