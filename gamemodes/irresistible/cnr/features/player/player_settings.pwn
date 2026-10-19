/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\player_settings.pwn
 * Purpose: player settings that can be easily configured via /controlpanel (/cp)
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_SETTINGS 				( 13 )

#define SETTING_BAILOFFERS 			( 0 )
#define SETTING_EVENT_TP			( 1 )
#define SETTING_GANG_INVITES		( 2 )
#define SETTING_CHAT_PREFIXES		( 3 )
#define SETTING_RANSOMS				( 4 )
#define SETTING_CHAT_ID 			( 5 )
#define SETTING_CONNECTION_LOG 		( 6 )
#define SETTING_HITMARKER 			( 7 )
#define SETTING_VIPSKIN 			( 8 )
#define SETTING_COINS_BAR	 		( 9 )
#define SETTING_TOP_DONOR 			( 10 )
#define SETTING_WEAPON_PICKUP 		( 11 )
#define SETTING_HIDE_GAMB_MSG		( 12 )

/* ** Variables ** */
static stock
	g_PlayerSettings 				[ MAX_SETTINGS ] [ 24 ] = {
		{ "防止保释" }, { "防止事件传送" }, { "防止帮派邀请" }, { "防止聊天前缀" }, { "拒绝赎金请求" },
		{ "在聊天中显示用户 ID" }, { "显示连接日志" }, { "显示命中标记" }, { "设置 VIP 皮肤" }, { "隐藏总金币栏" }, { "隐藏最后的捐赠者文本" },
		{ "手动拾取武器" }, { "隐藏赌博获胜消息" }
	},
	bool: p_PlayerSettings 			[ MAX_PLAYERS ] [ MAX_SETTINGS char ]
;

/* ** Hooks ** */
hook OnPlayerRegister( playerid )
{
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_CP_MENU && response )
	{
		if ( IsPlayerInEvent( playerid ) ) {
			return SendError( playerid, "你无法在活动中修改你的玩家设置." );
		}

		if ( listitem == 0 ) {
			return ShowPlayerAccountGuard( playerid );
		}

		new
			settingid = listitem - 1;

		if ( settingid == SETTING_VIPSKIN && p_VIPLevel[ playerid ] < VIP_REGULAR ) {
			return SendError( playerid, "你还不是 VIP, 请前往以下地址开通: "COL_GREY"donate.sfcnr.com" );
		}

		// setting is being toggled ... then
		if ( ! p_PlayerSettings[ playerid ] { settingid } == true )
		{
			if ( settingid == SETTING_VIPSKIN ) {
				SyncObject( playerid );
				ClearAnimations( playerid );
				SetPlayerSkin( playerid, p_LastSkin[ playerid ] );
			}

			else if ( settingid == SETTING_COINS_BAR || settingid == SETTING_TOP_DONOR ) {
			 	HidePlayerTogglableTextdraws( playerid, .force = false );
 				ShowPlayerTogglableTextdraws( playerid, .force = false );
			}
		}
		else // setting is not being toggled
		{
			if ( settingid == SETTING_COINS_BAR || settingid == SETTING_TOP_DONOR ) {
			 	HidePlayerTogglableTextdraws( playerid, .force = false );
 				ShowPlayerTogglableTextdraws( playerid, .force = false );
			}
		}

		TogglePlayerSetting( playerid, settingid, ! p_PlayerSettings[ playerid ] { settingid } );
		SendServerMessage( playerid, ""COL_ORANGE"%s"COL_WHITE"已设为 %s. 更改可能在出生或重新登录后生效.", g_PlayerSettings[ settingid ], p_PlayerSettings[ playerid ] { settingid } ? ( "启用" ) : ( "禁用" ) );

	    if ( ! strmatch( inputtext, "ignore" )) {
	   		cmd_cp( playerid, "" ); // Redirect to control panel again...
	    }
	}
	return 1;
}

hook OnPlayerConnect( playerid ) {
	for ( new i = 0; i < MAX_SETTINGS; i ++ ) {
		p_PlayerSettings[ playerid ] { i } = false;
	}
	return 1;
}

hook OnPlayerLogin( playerid )
{
	format( szNormalString, sizeof( szNormalString ), "SELECT * FROM `SETTINGS` WHERE `USER_ID`=%d", GetPlayerAccountID( playerid ) );
	mysql_function_query( dbHandle, szNormalString, true, "OnSettingsLoad", "d", playerid );
	return 1;
}

hook OnPlayerLoadTextdraws( playerid ) {
	ShowPlayerTogglableTextdraws( playerid );
	return 1;
}

hook OnPlayerUnloadTextdraws( playerid ) {
	HidePlayerTogglableTextdraws( playerid );
	return 1;
}

/* ** SQL Threads ** */
thread OnSettingsLoad( playerid )
{
	if ( !IsPlayerConnected( playerid ) )
		return 0;

	new
		rows = cache_get_row_count( );

	if ( rows )
	{
		new
			i = -1;

		while( ++ i < rows )
		{
			new
				settingid = cache_get_field_content_int( i, "SETTING_ID", dbHandle );

			if ( settingid < MAX_SETTINGS ) // Must be something wrong otherwise...
				p_PlayerSettings[ playerid ] { settingid } = true;
		}
	}
	return 1;
}

/* ** Commands ** */
CMD:cp( playerid, params[ ] ) return cmd_controlpanel( playerid, params );
CMD:settings( playerid, params[ ] ) return cmd_controlpanel( playerid, params );
CMD:controlpanel( playerid, params[ ] )
{
	szLargeString = ""COL_WHITE"设置\t"COL_WHITE"状态\n"COL_GREY"账号安全防护\t"COL_ORANGE">>>\n";

	for( new i = 0; i < MAX_SETTINGS; i++ ) {
		format( szLargeString, sizeof( szLargeString ), "%s%s\t%s\n", szLargeString, g_PlayerSettings[ i ], p_PlayerSettings[ playerid ] { i } ? ( ""#COL_GREEN"是" ) : ( ""#COL_RED"否" ) );
	}

	ShowPlayerDialog( playerid, DIALOG_CP_MENU, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}控制面板", szLargeString, "选择", "取消" );
	return 1;
}

/* ** Functions ** */
static stock ShowPlayerTogglableTextdraws( playerid, bool: force = false )
{
	// Current Coins
	if ( ! IsPlayerSettingToggled( playerid, SETTING_COINS_BAR ) || force ) {
		TextDrawShowForPlayer( playerid, g_CurrentCoinsTD );
		PlayerTextDrawShow( playerid, p_CoinsTD[ playerid ] );
	}

	// Top donor
	if ( ! IsPlayerSettingToggled( playerid, SETTING_TOP_DONOR ) || force ) {
		TextDrawShowForPlayer( playerid, g_TopDonorTD );
	}
}

static stock HidePlayerTogglableTextdraws( playerid, bool: force = true )
{
	// Current Coins
	if ( IsPlayerSettingToggled( playerid, SETTING_COINS_BAR ) || force ) {
		TextDrawHideForPlayer( playerid, g_CurrentCoinsTD );
		PlayerTextDrawHide( playerid, p_CoinsTD[ playerid ] );
	}

	// Top donor
	if ( IsPlayerSettingToggled( playerid, SETTING_TOP_DONOR ) || force ) {
		TextDrawHideForPlayer( playerid, g_TopDonorTD );
	}
}

stock TogglePlayerSetting( playerid, settingid, bool: toggle )
{
	if ( ( p_PlayerSettings[ playerid ] { settingid } = toggle ) == true ) {
		mysql_single_query( sprintf( "INSERT INTO `SETTINGS`(`USER_ID`, `SETTING_ID`) VALUES (%d, %d)", p_AccountID[ playerid ], settingid ) );
	} else {
		mysql_single_query( sprintf( "DELETE FROM `SETTINGS` WHERE `USER_ID`=%d AND `SETTING_ID`=%d", p_AccountID[ playerid ], settingid ) );
	}
	return 1;
}

stock IsPlayerSettingToggled( playerid, settingid ) {
	return p_PlayerSettings[ playerid ] { settingid };
}

stock IsPlayerVIPSkinToggled( playerid ) {
	return p_PlayerSettings[ playerid ] { SETTING_VIPSKIN };
}