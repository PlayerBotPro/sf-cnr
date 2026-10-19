/*
 * Irresistible Gaming 2018
 * Developed by Lorenc
 * Module: radio.inc
 * Purpose: radio related feature
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Error Checking ** */
#if !defined VIP_REGULAR
	#error "This module requires a V.I.P system!"
#endif

/* ** Variables ** */
enum E_RADIO_DATA
{
	E_NAME                    		[ 16 ],
	E_URL                           [ 60 ]
};

static stock
	g_RadioData[ ] [ E_RADIO_DATA ] =
	{
	    { "国家",		"http://sc3c-sjc.1.fm:7806" },
		{ "电子的", 	"http://useless.streams.enation.fm:8000" },
		{ "金属", 			"http://ice.somafm.com/metal" },
		{ "嘻哈音乐",       	"http://www.stationzilla.com/stationzilla.m3u" },
		{ "流行音乐", 			"http://listen.radionomy.com/airradiofreestyleslow" },
		{ "雷鬼音乐", 		"http://whatisland.macchiatomedia.org:8118" },
		{ "岩石", 			"http://sorradio.org:5005/live" },
		{ "果酱 1.FM",		"http://sc1c-sjc.1.fm:8052" },
		{ "XLTRAX 调频", 		"http://xltrax.com:8000" },
		{ "凹槽沙拉", 	"http://ice.somafm.com/groovesalad" },
		{ ".977 点击数",      "http://7609.live.streamtheworld.com:80/977_HITS_SC" }
	},
	g_RadioStations					[ 190 ] = ""COL_GREY"自定义网址 "COL_GOLD"[V.I.P]"COL_WHITE"\n",
	bool: p_UsingRadio				[ MAX_PLAYERS char ]
;

/* ** Hooks ** */
hook OnGameModeInit( )
{
	// format radio station string
    for( new i = 0; i < sizeof( g_RadioData ); i++ ) {
	    format( g_RadioStations, sizeof( g_RadioStations ), "%s%s\n", g_RadioStations, g_RadioData[ i ] [ E_NAME ] );
	}
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( ( dialogid == DIALOG_RADIO ) && response )
	{
		if ( listitem == 0 )
		{
			if ( GetPlayerVIPLevel( playerid ) < VIP_REGULAR )
				return SendError( playerid, "你必须是 VIP 才能使用此功能,才能成为一次访问 "COL_GREY"donate.irresistiblegaming.com" ), 1;

            ShowPlayerDialog(playerid, DIALOG_RADIO_CUSTOM, DIALOG_STYLE_INPUT, "{FFFFFF}定制收音机", ""COL_WHITE"输入下面的 URL,直播将开始.\n\n"COL_ORANGE"如果没有回复,请注意.这可能是一个无效的 URL.", "溪流", "返回");
			return 1;
		}
	   	p_UsingRadio{ playerid } = true;
	   	StopAudioStreamForPlayer( playerid );
	   	PlayAudioStreamForPlayer( playerid, g_RadioData[ listitem - 1 ] [ E_URL ] );
	    SendServerMessage( playerid, "如果无线电没有响应,则它一定处于离线状态.使用 "COL_GREY"/stopradio"COL_WHITE" 停止广播." );
	}
	else if ( dialogid == DIALOG_RADIO_CUSTOM )
	{
		if ( !response ) return cmd_radio( playerid, "" );
	   	p_UsingRadio{ playerid } = true;
	   	StopAudioStreamForPlayer( playerid );
	   	PlayAudioStreamForPlayer( playerid, inputtext );
	    SendServerMessage( playerid, "如果无线电没有响应,则它一定处于离线状态.使用 "COL_GREY"/stopradio"COL_WHITE" 停止广播." );
	}
	return 1;
}

hook OnPlayerDisconnect( playerid, reason ) {
	p_UsingRadio{ playerid } = false;
	return 1;
}

/* ** Commands ** */
CMD:radio( playerid, params[ ] )
{
    ShowPlayerDialog(playerid, DIALOG_RADIO, DIALOG_STYLE_LIST, "{FFFFFF}广播电台 - 列表", g_RadioStations, "选择", "关闭");
	return 1;
}

CMD:stopradio( playerid, params[ ] )
{
	if ( IsPlayerUsingRadio( playerid ) ) p_UsingRadio{ playerid } = false;
    StopAudioStreamForPlayer( playerid );
	return 1;
}

/* ** Functions ** */
stock IsPlayerUsingRadio( playerid ) return p_UsingRadio{ playerid };
