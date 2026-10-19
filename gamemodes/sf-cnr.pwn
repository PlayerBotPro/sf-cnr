/*
 *
 *      	San Fierro: Cops and Robbers
 *
 * 		Original Creator: Lorenc_
 *		Contributors: Damen, Stev
 *
 *      Thanks to: y_less/zeex/Frosha/Incognito/SA-MP team
 *
 *  Codes:
 *      8hska7082bmahu -> Money Farming Checks
 *      plugins mysql crashdetect sscanf streamer socket Whirlpool regex gvar FileManager profiler FCNPC
*/

#pragma compat 1
#pragma option -d3
#pragma dynamic 7200000

#define DEBUG_MODE

#if defined DEBUG_MODE
	#pragma option -d3
#endif

/* ** SA-MP Includes ** */
#include 							< a_samp >
#include                            < a_http >

/* ** YSI ** */
#include 							< YSI\y_iterate >
#include 							< YSI\y_hooks >
#include                            < YSI\y_va >

/* ** Redefinitions ** */
#undef  MAX_PLAYERS
#define MAX_PLAYERS                 126

/* ** Sundry Includes ** */
#include                            < a_mysql >
#include 							< zcmd >
#include 							< sscanf2 >
#include 							< streamer >
#include                            < regex >
#include                            < gvar >
#include 							< RouteConnector >
#include 							"irresistible\compat\random.pwn"
#include 							"irresistible\compat\calculator.pwn"
#include 							< mapandreas >
#include 							< md-sort >
native WP_Hash						( buffer[ ], len, const str[ ] );
native IsValidVehicle				( vehicleid );
native gpci 						( playerid, serial[ ], len );

#define MAX_EXPLOSIVE_ROUNDS 		( 1024 )

/* ** SF-CNR ** */
#include 							"irresistible\_main.pwn"

/* ** Useful macros ** */
#define Ach_Unlock(%0,%1) 			(%0 >= %1 ?("{6EF83C}"):("{FFFFFF}"))
#define Achievement:: 				ach_


#define MAX_TIME_TIED 				180
#define MAX_VEH_ATTACHED_OBJECTS  	2


/* ** Forwards ** */
public OnPlayerDriveVehicle( playerid, vehicleid );
public OnServerUpdateTimer( );
public OnServerSecondTick( );
public OnPlayerLoadTextdraws( playerid );
public OnPlayerUnloadTextdraws( playerid );

main()
{
	print( "\n" #SERVER_NAME "\n" );
}

public OnGameModeInit()
{
	/* ** Server Variables ** */
	AddServerVariable( "doublexp", "0", GLOBAL_VARTYPE_INT );
	AddServerVariable( "eventbank", "0", GLOBAL_VARTYPE_INT );
	AddServerVariable( "eventhost", "0", GLOBAL_VARTYPE_INT );
	AddServerVariable( "vip_discount", "1.0", GLOBAL_VARTYPE_FLOAT );
	AddServerVariable( "vip_bonus", "0.0", GLOBAL_VARTYPE_FLOAT );
	AddServerVariable( "connectsong", "http://files.sfcnr.com/game_sounds/Stevie%20Wonder%20-%20Skeletons.mp3", GLOBAL_VARTYPE_STRING );
	AddServerVariable( "discordurl", "http://sfcnr.com/discord", GLOBAL_VARTYPE_STRING );

	/* ** Set everyone offline ** */
	mysql_single_query( "UPDATE `USERS` SET `ONLINE` = 0" );

	/* ** Auto Inactive Deletion ** */
#if !defined DEBUG_MODE

	// Delete accounts older than 6 months
	erase( szLargeString );
	strcat( szLargeString, "DELETE a1, a2, a3, a4, a5, a6, a7, a8, a9 FROM `USERS` AS a1 " );
	strcat( szLargeString, "LEFT JOIN `HOUSES` AS a2 ON a2.`OWNER` = a1.`NAME` " );
	strcat( szLargeString, "LEFT JOIN `VEHICLES` AS a3 ON a3.`OWNER` = a1.`ID` " );
	strcat( szLargeString, "LEFT JOIN `FURNITURE` as a4 ON a4.`OWNER` = a1.`ID` " );
	strcat( szLargeString, "LEFT JOIN `APARTMENTS` as a5 ON a5.`OWNER` = a1.`NAME` " );
	strcat( szLargeString, "LEFT JOIN `GATES` as a6 ON a6.`OWNER` = a1.`ID` " );
	strcat( szLargeString, "LEFT JOIN `TOY_UNLOCKS` as a7 ON a7.`USER_ID` = a1.`ID` " );
	strcat( szLargeString, "LEFT JOIN `SETTINGS` as a8 ON a8.`USER_ID` = a1.`ID` " );
	strcat( szLargeString, "LEFT JOIN `TOYS` as a9 ON a9.`USER_ID` = a1.`ID` " );
	strcat( szLargeString, "LEFT JOIN `GARAGES` as a10 ON a10.`OWNER` = a1.`ID` " );
	strcat( szLargeString, "LEFT JOIN `BUSINESSES` as a11 ON a11.`OWNER_ID` = a1.`ID` " );
	strcat( szLargeString, "WHERE UNIX_TIMESTAMP()-a1.`LASTLOGGED` > 11510640000" );
	mysql_function_query( dbHandle, szLargeString, true, "onRemoveInactiveRows", "d", 0 );

	// Reset VIPs
	mysql_function_query( dbHandle, "UPDATE USERS SET VIP_PACKAGE=0, VIP_EXPIRE=0 WHERE UNIX_TIMESTAMP() > VIP_EXPIRE AND VIP_EXPIRE != 0", true, "onRemoveInactiveRows", "d", 1 );

	// Truncate accounts older than 2 months
	mysql_function_query( dbHandle, "UPDATE USERS SET CASH=0,BANKMONEY=0,COINS=0.0 WHERE UNIX_TIMESTAMP()-`LASTLOGGED`>5259487", true, "onRemoveInactiveRows", "d", 2 );

	// Remove inactive homes older than 2 weeks
	mysql_function_query( dbHandle, "DELETE a2,a3 FROM `USERS` a1 " \
									"LEFT JOIN `FURNITURE` a2 on a1.`ID` = a2.`OWNER` "\
									"LEFT JOIN `APARTMENTS` a3 on a1.`NAME` = a3.`OWNER` "\
									"WHERE UNIX_TIMESTAMP()-a1.`LASTLOGGED` > IF(a1.`VIP_PACKAGE` >= 5, 2592000, 1209600)", true, "onRemoveInactiveRows", "d", 3 );

	mysql_function_query( dbHandle, "UPDATE `USERS` a1 JOIN `HOUSES` a2 ON a1.`NAME` = a2.`OWNER` "\
									"SET a2.`NAME`='Home', a2.`OWNER`='No-one', a2.`TX`=" #H_DEFAULT_X ", a2.`TY`=" #H_DEFAULT_Y ", a2.`TZ`=" #H_DEFAULT_Z ", a2.`INTERIOR`=2, a2.`PASSWORD`='N/A', a2.`WEAPONS`='0.0.0.0.0.0.0.', a2.`AMMO`='-1.-1.-1.-1.-1.-1.-1.' "\
									"WHERE UNIX_TIMESTAMP()-a1.`LASTLOGGED` > IF(a1.`VIP_PACKAGE` >= 5, 2592000, 1209600)", true, "onRemoveInactiveRows", "d", 4 );

	// Truncate banned players after 2 weeks
	mysql_function_query( dbHandle, "UPDATE `USERS` a1 JOIN `BANS` a2 ON a1.`NAME` = a2.`NAME` "\
									"SET a1.`BANKMONEY`=0, a1.`CASH`=0 "\
									"WHERE UNIX_TIMESTAMP()-a1.`LASTLOGGED` > IF(a1.`VIP_PACKAGE` >= 5, 2592000, 1209600)", true, "onRemoveInactiveRows", "d", 5 );

	// Update vehicles with inactive garages.
	mysql_function_query( dbHandle, "UPDATE `VEHICLES` v JOIN `GARAGES` g ON g.`ID` = v.`GARAGE` JOIN `USERS` u ON u.`ID` = v.`OWNER` "\
									"SET v.`X`=g.`X`, v.`Y`=g.`Y`, v.`Z`=g.`Z`, v.`GARAGE`=-1 "\
									"WHERE v.`GARAGE` != -1 AND UNIX_TIMESTAMP()-u.`LASTLOGGED` > IF(u.`VIP_PACKAGE` >= 5, 2592000, 1209600)", true, "onRemoveInactiveRows", "d", 6 );

	// remove inactive garages (14d / 31d)
	mysql_function_query( dbHandle, "DELETE g FROM `GARAGES` g JOIN `USERS` u ON u.`ID` = g.`OWNER` WHERE UNIX_TIMESTAMP()-u.`LASTLOGGED` > IF(u.`VIP_PACKAGE` >= 5, 2592000, 1209600)", true, "onRemoveInactiveRows", "d", 7 );

	// remove inactive businesses (14d / 31d)
	mysql_function_query( dbHandle, "DELETE b FROM `BUSINESSES` b JOIN `USERS` u ON u.`ID` = b.`OWNER_ID` WHERE UNIX_TIMESTAMP()-u.`LASTLOGGED` > IF(u.`VIP_PACKAGE` >= 5, 2592000, 1209600)", true, "onRemoveInactiveRows", "d", 8 );

	// remove inactive gates (14d / 31d)
	mysql_function_query( dbHandle, "DELETE g FROM `GATES` g JOIN `USERS` u ON u.`ID` = g.`OWNER` WHERE UNIX_TIMESTAMP()-u.`LASTLOGGED` > IF(u.`VIP_PACKAGE` >= 5, 2592000, 1209600)", true, "onRemoveInactiveRows", "d", 9 );
#endif

	/* ** Timers ** */
	rl_ServerUpdate = SetTimer( "OnServerUpdateTimer", 960, true );
	rl_ZoneUpdate = SetTimer( "OnServerSecondTick", 980, true );

	printf( "[SF-CNR] SF-CnR has been successfully initialized. (Build: %s | Time: %d | Tickcount: %d)", GetServerVersion( ), ( g_ServerUptime = gettime( ) ), GetTickCount( ) );
	return 1;
}

thread onRemoveInactiveRows( type )
{
	new
		iRemoved = cache_affected_rows( );

	if ( iRemoved )
	{
		switch( type )
		{
			case 0: format( szNormalString, 96, "[%s %s] 删除了大约 %d 个不活动行.\r\n", getCurrentDate( ), getCurrentTime( ), iRemoved );
            case 1: format( szNormalString, 96, "[%s %s] 重置大约 %d 个已过去的 VIP 个帐户.\r\n", getCurrentDate( ), getCurrentTime( ), iRemoved );
            case 2: format( szNormalString, 96, "[%s %s] %d 账户周围泛滥.\r\n", getCurrentDate( ), getCurrentTime( ), iRemoved );
            case 3: format( szNormalString, 96, "[%s %s] 冲洗 %d 不活跃业主的家具.\r\n", getCurrentDate( ), getCurrentTime( ), iRemoved );
            case 4: format( szNormalString, 96, "[%s %s] 拍卖了 %d 个闲置房屋. \r\n", getCurrentDate( ), getCurrentTime( ), iRemoved );
            case 5: format( szNormalString, 96, "[%s %s] 在 %d 被禁止的帐户周围刷新. \r\n", getCurrentDate( ), getCurrentTime( ), iRemoved );
            case 6: format( szNormalString, 96, "[%s %s] 从闲置车库重新定位了大约 %d 辆车. \r\n", getCurrentDate( ), getCurrentTime( ), iRemoved );
            case 7: format( szNormalString, 96, "[%s %s] 在 %d 车库周围冲水. \r\n", getCurrentDate( ), getCurrentTime( ), iRemoved );
            case 8: format( szNormalString, 96, "[%s %s] 在 %d 企业周围泛滥. \r\n", getCurrentDate( ), getCurrentTime( ), iRemoved );
            case 9: format( szNormalString, 96, "[%s %s] %d 门周围冲刷. \r\n", getCurrentDate( ), getCurrentTime( ), iRemoved );
	   	}
	    AddFileLogLine( "inactive_rows.txt", szNormalString );

		strreplace( szNormalString, "\r\n", "" );
	    printf( "[INACTIVITY] %s", szNormalString );
	}
	return 1;
}

public OnGameModeExit( )
{
	KillTimer( rl_ServerUpdate );
	KillTimer( rl_ZoneUpdate );
    for( new t; t != MAX_TEXT_DRAWS; t++ ) TextDrawDestroy( Text: t );
	//SendRconCommand( "exit" );
	return 1;
}

public OnServerUpdateTimer( )
{
	static
		iWeapon, iAmmo
	;

	// better to store in a variable as we are getting the timestamp from hardware
	g_iTime = gettime( );

	UpdatePlayerCounters();

	// for hooks
	CallLocalFunction( "OnServerUpdate", "" );

	// Begin iterating all players
	foreach ( new playerid : Player )
	{
		// For modules that wish to update data appropriately
		CallLocalFunction( "OnPlayerUpdateEx", "d", playerid );

		if ( IsPlayerSpawned( playerid ) && p_PlayerLogged{ playerid } )
		{
			iWeapon 	= GetPlayerWeapon( playerid );

		    // Generally Updated textdraws
			PlayerTextDrawSetString( playerid, p_LocationTD[ playerid ], GetPlayerArea( playerid ) );

			// Toggle total coin bar
			if ( ! IsPlayerSettingToggled( playerid, SETTING_COINS_BAR ) )
				PlayerTextDrawSetString( playerid, p_CoinsTD[ playerid ], sprintf( "%05.3f", GetPlayerIrresistibleCoins( playerid ) ) );

			// Decrementing Weed Opacity Label
		    if ( p_WeedLabel[ playerid ] != Text3D: INVALID_3DTEXT_ID )
				UpdateDynamic3DTextLabelText( p_WeedLabel[ playerid ], setAlpha( COLOR_GREEN, floatround( ( float( GetPlayerDrunkLevel( playerid ) ) / 5000.0 ) * 255.0 ) ), "最近很火爆W33D!" );

			// Not near kidnapper then untie
			if ( IsPlayerTied( playerid ) && isNotNearPlayer( playerid, p_TiedBy[ playerid ] ) && ( g_iTime - p_TiedAtTimestamp[ playerid ] ) >= 8 )
				UntiePlayer( playerid );

			// Check if player is near a poker table
			if ( PlayerData[ playerid ] [ E_PLAYER_CURRENT_HANDLE ] != ITER_NONE && ! IsPlayerInRangeOfTable( playerid, PlayerData[ playerid ] [ E_PLAYER_CURRENT_HANDLE ], 3.0 ) )
				Player_CheckPokerGame( playerid, "超出范围" ); // KickPlayerFromTable( playerid );

			// Not near detained player then uncuff
			//if ( IsPlayerDetained( playerid ) && isNotNearPlayer( playerid, p_DetainedBy[ playerid ] ) && ( g_iTime - p_TiedAtTimestamp[ playerid ] ) >= 8 )
			//	Uncuff( playerid );

		 	// Surfing a criminal vehicle
		 	if ( p_WantedLevel[ playerid ] < 6 && p_Class[ playerid ] != CLASS_POLICE )
		 	{
		 		new
		 			surfing_vehicle = GetPlayerSurfingVehicleID( playerid );

		 		if ( surfing_vehicle != INVALID_VEHICLE_ID )
		 		{
		 			new
		 				driverid = GetVehicleDriver( surfing_vehicle );

		 			if ( IsPlayerConnected( driverid ) && p_WantedLevel[ driverid ] > 2 && p_Class[ driverid ] != CLASS_POLICE ) {
		 				GivePlayerWantedLevel( playerid, 6 - p_WantedLevel[ playerid ] );
		 			}
		 		}
		 	}

			new
				aiming_player = GetPlayerTargetPlayer( playerid );

			if ( ! p_WantedLevel[ playerid ] && p_Class[ playerid ] != CLASS_POLICE && g_iTime > p_AimedAtPolice[ playerid ] && IsPlayerConnected( aiming_player ) && ! IsPlayerNPC( aiming_player ) && p_Class[ aiming_player ] == CLASS_POLICE ) {
				GivePlayerWantedLevel( playerid, 6 );
				p_AimedAtPolice[ playerid ] = g_iTime + 10;
				ShowPlayerHelpDialog( playerid, 6000, "你已将武器瞄准执法人员! ~n~~n~~r~~h~你现在被通缉." );
			}

			// AFK Players
			if ( ( GetTickCount( ) - p_AFKTime[ playerid ] ) >= 45000 )
			{
				// AFK Jail
				if ( p_WantedLevel[ playerid ] >= 6 && p_InHouse[ playerid ] == -1 && !IsPlayerAdminOnDuty( playerid ) && !IsPlayerInEntrance( playerid, g_VIPLounge[ CITY_SF ] ) && !IsPlayerInEntrance( playerid, g_VIPLounge[ CITY_LV ] ) && !IsPlayerInEntrance( playerid, g_VIPLounge[ CITY_LS ] ) && !IsPlayerTied( playerid ) && !IsPlayerKidnapped( playerid ) && !IsPlayerCuffed( playerid ) && !IsPlayerTazed( playerid ) && IsPlayerSpawned( playerid ) ) { // && !IsPlayerDetained( playerid )

					if ( !AwardNearestLEO( playerid, 1 ) )
					{
						JailPlayer( playerid, 60, 1 );
                        SendGlobalMessage( -1, ""COL_GOLD"[监狱]{FFFFFF} %s(%d) 已被服务器发送到监狱 60 秒 "COL_LRED"[AFK 通缉]", ReturnPlayerName( playerid ), playerid );
					}
				}

				// AFK Admins
				if ( IsPlayerAdminOnDuty( playerid ) )
					cmd_aod( playerid, "" );
			}

			// Decrementing Wanted Level
			/*if ( p_WantedLevel[ playerid ] > 2 && !IsPlayerAdminOnDuty( playerid ) )
			{
				new
					Float: fDistance = FLOAT_INFINITY, iWanted;

				GetClosestPlayerEx( playerid, CLASS_POLICE, fDistance );

				if ( fDistance >= 500.0 ) {
					if ( GetPVarInt( playerid, "LoseWantedCD" ) < g_iTime ) {
						if ( p_WantedLevel[ playerid ] > 1800 ) 		iWanted = 24;
						else if ( p_WantedLevel[ playerid ] > 1000 ) iWanted = 12;
						else if ( p_WantedLevel[ playerid ] > 500 )	iWanted = 6;
						else if ( p_WantedLevel[ playerid ] > 250 )	iWanted = 4;
						else if ( p_WantedLevel[ playerid ] > 12 ) 	iWanted = 2;
						GivePlayerWantedLevel( playerid, -iWanted );
						SetPVarInt( playerid, "LoseWantedCD", g_iTime + 30 );
					}
				}
			}*/

			// Tied probably?
			if ( IsPlayerTied( playerid ) && g_iTime - p_TimeTiedAt[ playerid ] > MAX_TIME_TIED )
			{
				TogglePlayerControllable( playerid, 1 );
				p_Tied{ playerid } = false;
				Delete3DTextLabel( p_TiedLabel[ playerid ] );
				p_TiedLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
				p_TimeTiedAt[ playerid ] = 0;
				p_Kidnapped{ playerid } = false;
				ShowPlayerHelpDialog( playerid, 1200, "你已经被绑了%s.~n~~n~你的领带松了.", secondstotime( g_iTime - p_TimeTiedAt[ playerid ] ) );
			}

			if ( p_AdminLevel[ playerid ] < 1 )
			{
			    /* ANTICHEAT */
				if ( g_PingLimit > 500 && GetPlayerPing( playerid ) > g_PingLimit && !p_PingImmunity{ playerid } )
				{
					SendGlobalMessage( -1, ""COL_PINK"[反作弊]{FFFFFF} %s(%d) 因 ping 值过高而被踢出 [%d/%d].", ReturnPlayerName( playerid ), playerid, GetPlayerPing( playerid ), g_PingLimit );
				    KickPlayerTimed( playerid );
				}
				if ( GetPlayerSpecialAction( playerid ) == SPECIAL_ACTION_USEJETPACK )
				{
					SendGlobalMessage( -1, ""COL_PINK"[反作弊]{FFFFFF} %s(%d) 因生成喷气背包而被禁止.", ReturnPlayerName( playerid ), playerid );
					AdvancedBan( playerid, "服务器", "喷气背包", ReturnPlayerIP( playerid ) );
				}
				if ( IsWeaponBanned( iWeapon ) ) {
					SendGlobalMessage( -1, ""COL_PINK"[反作弊]{FFFFFF} %s(%d) 因生成非法武器而被禁止.", ReturnPlayerName( playerid ), playerid );
					AdvancedBan( playerid, "服务器", "非法武器", ReturnPlayerIP( playerid ) );
				}
				GetPlayerWeaponData( playerid, 0, iAmmo, iAmmo );
				if ( iAmmo == 1000 ) {
					SendGlobalMessage( -1, ""COL_PINK"[反作弊]{FFFFFF} %s(%d) 因使用自瞄而被封禁.", ReturnPlayerName( playerid ), playerid );
					AdvancedBan( playerid, "服务器", "瞄准机器人", ReturnPlayerIP( playerid ) );
				}
			}

			// samp ac force
			if ( p_forcedAnticheat[ playerid ] > 0 && ! IsPlayerUsingSampAC( playerid ) ) {
				SendGlobalMessage( -1, ""COL_PINK"[反作弊]{FFFFFF} %s(%d) 因禁用 SAMP-AC 而被踢出. "COL_YELLOW"("AC_WEBSITE")", ReturnPlayerName( playerid ), playerid );
				KickPlayerTimed( playerid );
			}
		}
	}
	return Y_HOOKS_CONTINUE_RETURN_1;
}

public OnServerSecondTick( )
{
	// call local function
	CallLocalFunction( "OnServerTickSecond", "" );

	// Looping every 1000 MS
	foreach ( new playerid : Player )
	{
		if ( ! p_PlayerLogged{ playerid } )
			continue;

		// Callback
		CallLocalFunction( "OnPlayerTickSecond", "d", playerid );

		// Increment Variables Whilst Not AFK
		if ( !IsPlayerAFK( playerid ) ) // New addition
		{
			// Increase Time Online
			switch( ++ p_Uptime[ playerid ] )
			{
			    //case 300: 	ShowAchievement( playerid, "You have been online for ~r~5~w~~h~ minutes!", 1 );
			    case 1200: 	ShowAchievement( playerid, "你已在线 ~r~20~w~~h~ 分钟!", 2 );
			    case 3600: 	ShowAchievement( playerid, "你已在线 ~r~1~w~~h~ 小时!", 4 );
			    case 18000: ShowAchievement( playerid, "你已在线 ~r~5~w~~h~ 小时!", 6 );
			    case 36000: ShowAchievement( playerid, "你已在线 ~r~10~w~~h~ 小时!", 8 );
			    case 54000: ShowAchievement( playerid, "你已在线 ~r~15~w~~h~ 小时!", 10 );
			    case 72000: ShowAchievement( playerid, "你已在线 ~r~20~w~~h~ 小时!", 12 );
			    case 86400: ShowAchievement( playerid, "你已在线 ~r~1~w~~h~ 天!", 15 );
			}

		}

		// CIA Visible On Radar after firing a shot
		if ( p_VisibleOnRadar[ playerid ] != 0 && p_VisibleOnRadar[ playerid ] < g_iTime )
			SetPlayerColorToTeam( playerid ), p_VisibleOnRadar[ playerid ] = 0;
	}
	return 1;
}

public OnPlayerRequestClass( playerid, classid )
{
	p_Spawned{ playerid } = false;
	p_InfectedHIV{ playerid } = false;
	TextDrawHideForPlayer( playerid, g_AdminLogTD );
	TextDrawHideForPlayer( playerid, g_WebsiteTD );
	PlayerTextDrawHide( playerid, p_WantedLevelTD[ playerid ] );
	TextDrawHideForPlayer( playerid, g_MotdTD );
	PlayerTextDrawHide( playerid, g_ZoneOwnerTD[ playerid ] );
	TextDrawHideForPlayer( playerid, g_AdminOnDutyTD );
	PlayerTextDrawHide( playerid, p_LocationTD[ playerid ] );
	PlayerTextDrawHide( playerid, p_PlayerRankTD[ playerid ] );
	PlayerTextDrawHide( playerid, p_PlayerRankTextTD[ playerid ] );
	KillTimer( p_TrackingTimer[ playerid ] );
	p_TrackingTimer[ playerid ] = -1;
	PlayerTextDrawHide( playerid, p_TrackPlayerTD[ playerid ] );
	PlayerTextDrawHide( playerid, p_ExperienceTD[ playerid ] );
	TextDrawHideForPlayer( playerid, g_CurrentRankTD );
	TextDrawHideForPlayer( playerid, g_currentXPTD );
	TextDrawHideForPlayer( playerid, g_DoubleXPTD );
	p_MoneyBag{ playerid } = false;
	CallLocalFunction( "OnPlayerUnloadTextdraws", "d", playerid );
	return 1;
}

public OnNpcConnect( npcid )
{
	return Kick( npcid ), 1;
}

public OnPlayerConnect( playerid )
{
	TogglePlayerClock( playerid, 1 );
	SetPlayerColor( playerid, COLOR_GREY );
	ResetPlayerCash( playerid );

	// Reset some variables
	p_Spawned 			{ playerid } = false;
    p_GangID 			[ playerid ] = INVALID_GANG_ID;
	justConnected		{ playerid } = true;
	p_ClassSelection	{ playerid } = false;
	p_UsingRobberySafe	[ playerid ] = -1;

	// reset jails
	jailDoors( playerid, false, false );

	SendClientMessage( playerid, 0xa9c4e4ff, "{FF0000}[警告]{a9c4e4} 本服务器及 GTA 游戏中可能包含成人内容." );
	SendClientMessageFormatted( playerid, 0xa9c4e4ff, "{FF0000}[信息]{a9c4e4} 服务器当前正在版本 %s 上运行.", GetServerVersion( ) );

	if ( IsValidServerVariable( "connectsong" ) )
	{
		GetServerVariableString( "connectsong", szNormalString );
		PlayAudioStreamForPlayer( playerid, szNormalString );
	}
	return 1;
}

public OnLookupComplete( playerid, success )
{
	SendDeathMessage( INVALID_PLAYER_ID, playerid, 200 );

	if ( IsProxyEnabledForPlayer( playerid ) ) {
		format( szNormalString, sizeof( szNormalString ), "%s(%d) 已连接到服务器! (%s)", ReturnPlayerName( playerid ), playerid, GetPlayerCountryName( playerid ) );
	} else {
		format( szNormalString, sizeof( szNormalString ), "%s(%d) 已连接到服务器!", ReturnPlayerName( playerid ), playerid );
	}

	foreach ( new i : Player ) if ( IsPlayerSettingToggled( i, SETTING_CONNECTION_LOG ) ) {
		SendClientMessage( i, COLOR_CONNECT, szNormalString );
	}

	//format( szNormalString, sizeof( szNormalString ), "*%s*", szNormalString );
	//DCC_SendChannelMessage( discordGeneralChan, szNormalString );
	return 1;
}

public OnNpcDisconnect( npcid, reason )
{
	return 1;
}

public OnPlayerDisconnect( playerid, reason )
{
	static
		string[ 64 ], color;

	// Reset player variables
	DisconnectFromGang( playerid );
	dischargeVehicles( playerid );
	CutSpectation( playerid );
	LeavePlayerPaintball( playerid );
    RemovePlayerFromRace( playerid );
	p_Detained		{ playerid } = false;
	p_Tied			{ playerid } = false;
	p_Kidnapped		{ playerid } = false;
	p_Wood          [ playerid ] = 0;
	p_inAlcatraz 	{ playerid } = false;
	p_AlcatrazSpec	[ playerid ] = 0;
	p_Ropes			[ playerid ] = 0;
	p_Scissors      [ playerid ] = 0;
	p_Fires         [ playerid ] = 0;
	p_PingImmunity  { playerid } = 0;
	p_Robberies     [ playerid ] = 0;
	p_HitsComplete  [ playerid ] = 0;
	//p_CopTutorial   { playerid } = 0;
	p_Class			[ playerid ] = 0;
	p_drillStrength [ playerid ] = 0;
	p_RansomAmount	[ playerid ] = 0;
	p_RansomPlacer	[ playerid ] = INVALID_PLAYER_ID;
	p_LabelColor 	[ playerid ] = COLOR_GREY;
	p_Uptime        [ playerid ] = 0;
	p_Muted 		{ playerid } = false;
	p_AdminLog		{ playerid } = false;
	p_AdminLevel	[ playerid ] = 0;
 	p_Warns			[ playerid ] = 0;
	p_CopBanned		{ playerid } = 0;
	p_SpawningCity 	{ playerid } = CITY_SF;
	p_ArmyBanned    { playerid } = 0;
    p_PlayerLogged	{ playerid } = false;
    p_JobSet		{ playerid } = false;
    // p_CitySet 		{ playerid } = false;
	p_MoneyBag		{ playerid } = false;
    p_inPaintBall	{ playerid } = false;
	p_LeftPaintball { playerid } = false;
    p_Job			{ playerid } = 0;
    p_VIPJob 		{ playerid } = 0;
    p_CantUseReport { playerid } = false;
    p_BobbyPins     [ playerid ] = 0;
	p_Spawned		{ playerid } = false;
	p_AdminOnDuty   { playerid } = false;
	p_WantedLevel	[ playerid ] = 0;
	p_Tazed			{ playerid } = false;
	p_Jailed		{ playerid } = false;
	p_AntiEMP       [ playerid ] = 0;
	p_LastVehicle	[ playerid ] = INVALID_VEHICLE_ID;
	p_Cuffed		{ playerid } = false;
	justConnected	{ playerid } = true;
 	p_Muted			{ playerid } = false;
	p_ChatBanned	{ playerid } = false;
	p_ChatBannedBy	[ playerid ] [ 0 ] = '\0';
	p_ChatBanReason [ playerid ] [ 0 ] = '\0';
	p_MetalMelter	[ playerid ] = 0;
	p_LeftCuffed 	{ playerid } = false;
	p_PmResponder	[ playerid ] = INVALID_PLAYER_ID;
	p_ViewingStats  [ playerid ] = INVALID_PLAYER_ID;
	p_Spectating    { playerid } = false;
	p_DetainedBy	[ playerid ] = INVALID_PLAYER_ID;
    p_GangID		[ playerid ] = INVALID_GANG_ID;
	p_InfectedHIV	{ playerid } = false;
	p_OwnedHouses	[ playerid ] = 0;
	p_OwnedVehicles [ playerid ] = 0;
	p_ToggledViewPM	{ playerid } = false;
	p_TogglePBChat	{ playerid } = false;
	p_VIPExpiretime [ playerid ] = 0;
 	p_Kills			[ playerid ] = 0;
	p_Deaths		[ playerid ] = 0;
 	p_VIPLevel		[ playerid ] = 0;
	p_InHouse		[ playerid ] = -1;
	p_InGarage 		[ playerid ] = -1;
	p_CantUseAsk    { playerid } = false;
	p_LastSkin      [ playerid ] = 0;
	p_SecureWallet	{ playerid } = false;
	p_WeedGrams		[ playerid ] = 0;
	p_Arrests		[ playerid ] = 0;
	p_AidsVaccine	{ playerid } = false;
	p_VIPWep1		{ playerid } = 0;
	p_VIPWep2		{ playerid } = 0;
	p_VIPWep3		{ playerid } = 0;
	p_WeaponDealing	{ playerid } = false;
	p_WeaponDealer	[ playerid ] = INVALID_PLAYER_ID;
	p_WeedDealer	[ playerid ] = INVALID_PLAYER_ID;
	p_JailTime		[ playerid ] = 0;
	p_Muted			{ playerid } = false;
	p_Burglaries	[ playerid ] = 0;
	p_MethYielded 	[ playerid ] = 0;
	p_CarsJacked 	[ playerid ] = 0;
	p_BankBlown		[ playerid ] = 0;
	p_JailsBlown	[ playerid ] = 0;
	p_AccountID		[ playerid ] = 0;
	p_DeathMessage	[ playerid ] [ 0 ] = '\0';
	p_Fireworks 	[ playerid ] = 0;
	p_AddedEmail 	{ playerid } = false;
	p_OwnedBusinesses[ playerid ] = 0;
	p_ExplosiveBullets[ playerid ] = 0;
	p_GangSplitProfits[ playerid ] = 0;
	p_QuitToAvoidTimestamp[ playerid ] = 0;
	p_AntiExportCarSpam[ playerid ] = 0;
	p_TruckedCargo[ playerid ] = 0;
	p_PilotMissions[ playerid ] = 0;
	p_LastEnteredEntrance[ playerid ] = -1;
	p_ViewingGangTalk[ playerid ] = -1;
	p_forcedAnticheat[ playerid ] = 0;
	p_PlayerAltBind[ playerid ] = -1;
	p_RconLoginFails{ playerid } = 0;
	p_SpawningKey[ playerid ] [ 0 ] = '\0';
	p_SpawningIndex[ playerid ] = 0;
	p_IncorrectLogins{ playerid } = 0;
	p_VehicleBringCooldown[ playerid ] = 0;
	p_AntiTextSpamCount{ playerid } = 0;
    Delete3DTextLabel( p_AdminLabel[ playerid ] );
    p_AdminLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	Delete3DTextLabel( p_DetainedLabel[ playerid ] );
	p_DetainedLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	Delete3DTextLabel( p_TiedLabel[ playerid ] );
	p_TiedLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	DestroyDynamic3DTextLabel( p_WeedLabel[ playerid ] );
	p_WeedLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	//p_CopTutorialProgress{ playerid } = 0;
	DestroyDynamicRaceCP( p_MiningExport[ playerid ] );
	p_MiningExport[ playerid ] = 0xFFFF;
	p_ContractedAmount[ playerid ] = 0;
	Delete3DTextLabel( p_InfoLabel[ playerid ] );
	p_InfoLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	p_LabelColor[ playerid ] = COLOR_GREY;
    unpause_Player( playerid );
    DestroyAllPlayerC4s( playerid, true );
	KillTimer( p_JailTimer[ playerid ] );
	KillTimer( p_CuffAbuseTimer[ playerid ] );
	ResetPlayerCash( playerid );
	if ( !GetPVarInt( playerid, "banned_connection" ) ) SendDeathMessage( INVALID_PLAYER_ID, playerid, 201 );

	jailDoors( playerid, .remove = true, .set_closed = false );

	switch( reason )
	{
	    case 0: color = COLOR_TIMEOUT, 		format( string, sizeof( string ), "%s(%d) 已从服务器超时!", ReturnPlayerName( playerid ), playerid );
	    case 1: color = COLOR_DISCONNECT, 	format( string, sizeof( string ), "%s(%d) 已离开服务器!", ReturnPlayerName( playerid ), playerid );
	    case 2: color = COLOR_KICK, 		format( string, sizeof( string ), "%s(%d) 已被从服务器中踢出!", ReturnPlayerName( playerid ), playerid );
	}


	for( new i; i < MAX_PLAYERS; i++ )
	{
		if ( IsPlayerConnected( i ) && IsPlayerSettingToggled( i, SETTING_CONNECTION_LOG ) )
		{
			SendClientMessage( i, color, string ); // Send a message to people
		}

		if ( i < MAX_GANGS ) 	p_gangInvited[ playerid ] [ i ] = false;

		p_BlockedPM[ playerid ] [ i ] = false;
	}

	//format( string, sizeof( string ), "*%s*", string );
	//DCC_SendChannelMessage( discordGeneralChan, string );
	return 1;
}

public OnPlayerSpawn( playerid )
{
	new
		iTick = GetTickCount( );

	UpdatePlayerTime( playerid );
	DeletePVar( playerid, "attached_mugshot" );

	PlayerPlaySound( playerid, 0, 0.0, 0.0, 0.0 );

	if ( IsPlayerMovieMode( playerid ) )
	{
		CallLocalFunction( "OnPlayerUnloadTextdraws", "d", playerid );
	}
	else
	{
		ShowPlayerIrresistibleRank( playerid );
		TextDrawShowForPlayer( playerid, g_CurrentRankTD );
		TextDrawShowForPlayer( playerid, g_currentXPTD );
		PlayerTextDrawShow( playerid, p_LocationTD[ playerid ] );
		PlayerTextDrawShow( playerid, p_ExperienceTD[ playerid ] );
		TextDrawShowForPlayer( playerid, g_WebsiteTD );
		TextDrawShowForPlayer( playerid, g_MotdTD );
		PlayerTextDrawShow( playerid, g_ZoneOwnerTD[ playerid ] );
		if ( p_AdminOnDuty{ playerid } ) TextDrawShowForPlayer( playerid, g_AdminOnDutyTD );
		if ( p_AdminLog{ playerid } ) TextDrawShowForPlayer( playerid, g_AdminLogTD );
		if ( IsDoubleXP( ) ) TextDrawShowForPlayer( playerid, g_DoubleXPTD );
		CallLocalFunction( "OnPlayerLoadTextdraws", "d", playerid );
	}

	p_Spawned{ playerid } = true;
	p_InfectedHIV{ playerid } = false;
	p_Kidnapped{ playerid } = false;
	p_ClassSelection{ playerid } = false;
	p_LastEnteredEntrance[ playerid ] = -1;
   	p_Tied{ playerid } = false;
	p_InHouse[ playerid ] = -1;
	p_InGarage[ playerid ] = -1;
	StopSound( playerid );
	CancelEdit( playerid );
	HidePlayerHelpDialog( playerid );

	// Money Bags
	if ( p_MoneyBag{ playerid } && p_Class[ playerid ] != CLASS_POLICE ) // SetPlayerAttachedObject( playerid, 1, 1550, 1, 0.131999, -0.140999, 0.053999, 11.299997, 65.599906, 173.900054, 0.652000, 0.573000, 0.594000 );
		RemovePlayerAttachedObject( playerid, 1 ), SetPlayerAttachedObject( playerid, 1, 1210, 7, 0.302650, -0.002469, -0.193321, 296.124053, 270.396881, 8.941717, 1.000000, 1.000000, 1.000000 );

	// VIP Skin
	if ( IsPlayerSettingToggled( playerid, SETTING_VIPSKIN ) && p_VIPLevel[ playerid ] )
		SetPlayerSkin( playerid, p_LastSkin[ playerid ] );

	if ( justConnected{ playerid } == true )
	{
	    justConnected{ playerid } = false;
	    StopAudioStreamForPlayer( playerid );

	    // Callback
	    if ( ! CallLocalFunction( "OnPlayerFirstSpawn", "d", playerid ) ) {
			return 1; // prevent the player from spawning if the first spawn requires the player not to
		}

	    // Show wanted level
	    if ( p_WantedLevel[ playerid ] )
	    {
			format( szSmallString, sizeof( szSmallString ), "] %d ]", p_WantedLevel[ playerid ] );
			PlayerTextDrawSetString( playerid, p_WantedLevelTD[ playerid ], szSmallString );
			PlayerTextDrawShow( playerid, p_WantedLevelTD[ playerid ] );
	    }

	    // Show welcome messsage
        ShowPlayerHelpDialog( playerid, 10000, "欢迎%s!~n~~n~如果你有任何疑问,~g~/ask!~w~~h~~n~~n~如果你看到有人不公平,请用~r~/report举报他们!~w~~n~~n~祝你玩得开心,别忘了邀请你的朋友! :)", ReturnPlayerName( playerid ) );
	}
	/*else
	{
		// Reset wanted level when a player spawns
		if ( p_LastPlayerState{ playerid } != PLAYER_STATE_SPECTATING )
			ClearPlayerWantedLevel( playerid );
	}*/

	if ( p_Jailed{ playerid } ) // Because some people can still exit the jail and play...
		return SetPlayerHealth( playerid, INVALID_PLAYER_ID ), SetPlayerPosToPrison( playerid );

	if ( IsPlayerInPaintBall( playerid ) )
	{
	    if ( p_Class[ playerid ] != CLASS_CIVILIAN )
	    {
			SendError( playerid, "你必须是平民才能加入 彩弹竞技." );
			LeavePlayerPaintball( playerid );
		    SpawnPlayer( playerid );
			return 1;
		}

		SpawnToPaintball( playerid, p_PaintBallArena{ playerid } );
		return 1;
	}

	#if defined __cloudy_event_system
	else if ( IsPlayerInEvent( playerid ) )
	{
		if( ! EventSettingAllow( 0 ) && g_eventData[ EV_STARTED ] )
		{
			SetPlayerInEvent( playerid ); // respawns player in event.
			return 1;
		}
		else RemovePlayerFromEvent( playerid, true ); // changes the InEvent variable to false.
	}
	#endif

	if ( p_Class[ playerid ] == CLASS_CIVILIAN )
	{
		if ( !p_JobSet{ playerid } )
		{
		    TogglePlayerControllable( playerid, 0 );
		    ShowPlayerJobList( playerid );
		}
		else
		{
			if ( p_LastPlayerState{ playerid } != PLAYER_STATE_SPECTATING )
			{
			    switch( p_Job{ playerid } )
				{
			        case JOB_MUGGER:
			        {
			            GivePlayerWeapon( playerid, 10, 1 );
			            GivePlayerWeapon( playerid, 22, 150 );
			            GivePlayerWeapon( playerid, 25, 30 );
			        }
			        case JOB_KIDNAPPER:
			        {
			            GivePlayerWeapon( playerid, 29, 220 );
			            GivePlayerWeapon( playerid, 30, 400 );
			        }
			        case JOB_TERRORIST:
			        {
			            GivePlayerWeapon( playerid, 33, 50 );
			            GivePlayerWeapon( playerid, 30, 400 );
			        }
			        case JOB_HITMAN:
			        {
			            //GivePlayerWeapon( playerid, 4, 1 );
			            GivePlayerWeapon( playerid, 23, 130 );
			            GivePlayerWeapon( playerid, 34, 30 );
			        }
			        case JOB_WEAPON_DEALER:
			        {
			            GivePlayerWeapon( playerid, 5 , 1 );
			            GivePlayerWeapon( playerid, 22, 150 );
			            GivePlayerWeapon( playerid, 31, 300 );
			        }
			        case JOB_DRUG_DEALER:
			        {
			            GivePlayerWeapon( playerid, 5 , 1 );
			            GivePlayerWeapon( playerid, 22, 150 );
			            GivePlayerWeapon( playerid, 25, 50 );
			        }
			        case JOB_DIRTY_MECHANIC:
			        {
			            GivePlayerWeapon( playerid, 22, 150 );
			            GivePlayerWeapon( playerid, 27, 90 );
					}
			        case JOB_BURGLAR:
			        {
			            GivePlayerWeapon( playerid, 23, 130 );
			            GivePlayerWeapon( playerid, 31, 300 );
					}
			    }
			}
		}
	}

    new
    	bSpectated = ( IsPlayerAdmin( playerid ) && p_LastPlayerState{ playerid } == PLAYER_STATE_SPECTATING );

	if ( !bSpectated )
	{
		if ( GetPlayerClass( playerid ) == CLASS_POLICE ) {
			GivePlayerLeoWeapons( playerid );
		}
	}

	SetPlayerColorToTeam( playerid );
	SetPlayerVirtualWorld( playerid, 0 );

	if ( p_VIPLevel[ playerid ] >= VIP_REGULAR ){
		if ( p_VIPLevel[ playerid ] >= VIP_REGULAR && p_VIPWep1{ playerid } != 0 ) GivePlayerWeapon( playerid, p_VIPWep1{ playerid }, 200 );
		if ( p_VIPLevel[ playerid ] >= VIP_GOLD && p_VIPWep2{ playerid } != 0 ) GivePlayerWeapon( playerid, p_VIPWep2{ playerid }, 200 );
		if ( p_VIPLevel[ playerid ] >= VIP_PLATINUM && p_VIPWep3{ playerid } != 0 ) GivePlayerWeapon( playerid, p_VIPWep3{ playerid }, 200 );
		if ( p_VIPLevel[ playerid ] >= VIP_GOLD ) SetPlayerArmour( playerid, 100.0 ); // Free armour on spawn.
	}

	CallLocalFunction( "SetPlayerRandomSpawn", "d", playerid );

	SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[出生信息]"COL_WHITE" 你花了 %d 毫秒才生成!", ( GetTickCount( ) - iTick ) );
	return 1;
}

public OnPlayerWeaponShot( playerid, weaponid, hittype, hitid, Float: fX, Float: fY, Float: fZ )
{
	if ( p_AdminLevel[ playerid ] < 1 && IsWeaponBanned( weaponid ) ) {
		return 0;
	}

	if ( IsPlayerAFK( playerid ) ) {
		return 0;
	}

	static
		Float: X, Float: Y, Float: Z;

	if ( hittype == BULLET_HIT_TYPE_PLAYER )
	{
		if ( IsPlayerNPC( hitid ) )
			return 1; // fcnpc

		// Cop shoots innocent, they /q - so jail
		#if defined __cloudy_event_system
		if ( p_Class[ playerid ] == CLASS_POLICE && p_WantedLevel[ hitid ] > 2 && ! IsPlayerInEvent( playerid ) && ! IsPlayerInEvent( hitid ) )
		#else
		if ( p_Class[ playerid ] == CLASS_POLICE && p_WantedLevel[ hitid ] > 2 )
		#endif
		{
			p_QuitToAvoidTimestamp[ hitid ] = g_iTime + 3;
		}

		if ( p_Class[ playerid ] == CLASS_POLICE && p_Class[ hitid ] != CLASS_POLICE && !p_WantedLevel[ hitid ] && GetPlayerState( hitid ) != PLAYER_STATE_WASTED && ! IsPlayerInEvent( playerid ) && ! IsPlayerInBattleRoyale( playerid ) )
            return ShowPlayerHelpDialog( playerid, 2000, "你不能伤害无辜平民,你是~b~警察~w~~h~!" ), 0;

		// CIA Exposure when weapon is shot
		if ( p_Class[ playerid ] == CLASS_POLICE && p_inFBI{ playerid } && p_inCIA{ playerid } && !p_inArmy{ playerid } )
			SetPlayerColor( playerid, setAlpha( COLOR_CIA, 0xFF ) ), p_VisibleOnRadar[ playerid ] = g_iTime + 2;

		if ( IsPlayerConnected( hitid ) && p_BulletInvulnerbility[ hitid ] > g_iTime )
            return ShowPlayerHelpDialog( playerid, 2000, "该玩家免疫子弹!" ), 0;

		if ( IsPlayerAdminOnDuty( playerid ) )
			return 0;

		if ( IsPlayerConnected( hitid ) && ( IsPlayerTazed( hitid ) || IsPlayerCuffed( hitid ) || IsPlayerKidnapped( hitid ) || IsPlayerTied( hitid ) || IsPlayerLoadingObjects( hitid ) || IsPlayerAdminOnDuty( hitid ) || IsPlayerSpawnProtected( hitid ) ) )
			return 0;

		if ( IsPlayerSpawnProtected( playerid ) ) {
            return DisablePlayerSpawnProtection( playerid ), SendServerMessage( playerid, "你的重生保护不再有效!" ), 0;
		}
	}

	else if ( hittype == BULLET_HIT_TYPE_VEHICLE )
	{
		new
			Float: Health,
			iModel = GetVehicleModel( hitid )
		;

		g_VehicleLastAttacker[ hitid ] = playerid;
		g_VehicleLastAttacked[ hitid ] = g_iTime;

		// BMX, Bike, Mountain Bike, Train, Train Cargo, Train Passenger, Tram, Freight Box
		if ( iModel != 481 && iModel != 509 && iModel != 510 && iModel != 537 && iModel != 569 && iModel != 570 && iModel != 538 && iModel != 449 && iModel != 590 )
		{
			GetPlayerPos( playerid, X, Y, Z );
			GetVehicleHealth( hitid, Health );

			new
				Float: Damage = GetWeaponDamageFromDistance( weaponid, GetVehicleDistanceFromPoint( hitid, X, Y, Z ) ),
				iDriver = GetVehicleDriver( hitid )
			;

			if ( iDriver == INVALID_PLAYER_ID )
			{
				if ( weaponid == 38 ) Damage *= 20.0;

				switch( GetVehicleModel( hitid ) )
				{
					case 573: Damage /= 6.0; // Dune
					case 508: Damage /= 4.0; // Journey
					case 498: Damage /= 2.0; // Boxville
					case 432: Damage /= 15.0; // Rhino
					case 433, 427: Damage /= 4.0; // barracks/enforcer
					case 601, 428: Damage /= 5.0; // swat tank, securicar
					case 407, 544, 406: Damage /= 2.0; // firetruck a, firetruck b, dumper
				}

				if ( Health >= 250.0 ) {
					SetVehicleHealth( hitid, Health - Damage );
				}
				else
				{
					if ( GetGVarType( "respawning_veh", hitid ) == GLOBAL_VARTYPE_NONE )
				 		SetGVarInt( "respawning_veh", SetTimerEx( "RespawnaVehicle", 9000, false, "d", hitid ), hitid );
				}
			}
			else
			{
				// Disable team vehicle damage
				if ( p_Class[ iDriver ] == CLASS_POLICE && p_Class[ playerid ] == CLASS_POLICE )
					return 0;

				// Can't damage admin on duty vehicles
				if ( IsPlayerAdminOnDuty( iDriver ) )
					return 0;

				// Anti Random Deathmatch
				if ( IsRandomDeathmatch( playerid, iDriver ) && ! IsPlayerInPaintBall( playerid ) && ! IsPlayerInEvent( playerid ) && ! IsPlayerDueling( playerid ) )
					return 0;

				if ( p_WantedLevel[ playerid ] <= 2 && p_Class[ playerid ] != CLASS_POLICE && p_Class[ iDriver ] == CLASS_POLICE && GetPVarInt( playerid, "ShotCopWantedCD" ) < g_iTime )
					SendServerMessage( playerid, "你已经身体接触了一名官员,因此你被通缉." ), GivePlayerWantedLevel( playerid, 6 ), SetPVarInt( playerid, "ShotCopWantedCD", g_iTime + 120 );

				// Cops Cannot Damage Innocent Vehicles, Unless Wanted Players Occupy Alongside Them
				if ( p_Class[ playerid ] == CLASS_POLICE && p_WantedLevel[ iDriver ] == 0 )
				{
					new
						innocentVehicleID = GetPlayerVehicleID( iDriver );

					foreach ( new i : Player ) if ( i != iDriver )
					{
						new
							iTargetVehicle = GetPlayerVehicleID( i );

						if ( iTargetVehicle == innocentVehicleID && GetPlayerWantedLevel( i ) > 0 ) {
							return 1;
						}
					}

					return ShowPlayerHelpDialog( playerid, 2000, "你不能损坏无辜玩家的车辆,除非他们想要玩家在他们身边!" ), 0;
				}
			}
		}
	}

	// Explosive Bullets
	if ( hittype != BULLET_HIT_TYPE_OBJECT ) {
		CreateExplosiveBullet( playerid, hittype, hitid );
	}
    return 1;
}

stock CreateExplosiveBullet( playerid, hittype = BULLET_HIT_TYPE_OBJECT, hitid = INVALID_OBJECT_ID ) {

	if ( IsPlayerInCasino( playerid ) || IsPlayerInPaintBall( playerid ) || IsPlayerInEvent( playerid ) || IsPlayerInMinigame( playerid ) )
		return;

	if ( GetPVarInt( playerid, "explosive_rounds" ) == 1 && p_ExplosiveBullets[ playerid ] > 0 )
	{
		static Float: fromX, Float: fromY, Float: fromZ;
		static Float: toX, Float: toY, Float: toZ;

		if ( GetPlayerLastShotVectors( playerid, fromX, fromY, fromZ, toX, toY, toZ ) )
		{
			// create explosion at the core of the vehicle
			if ( hittype == BULLET_HIT_TYPE_VEHICLE ) {
				GetVehiclePos( hitid, toX, toY, toZ );
			}

			// Cool effect
			new objectid = CreateDynamicObject( 19296, fromX, fromY, fromZ, 0.0, 0.0, 0.0 );
			new milliseconds = MoveDynamicObject( objectid, toX, toY, toZ, 500.0 );
			SetTimerEx( "Timer_DestroyObject", milliseconds + 200, false, "d", objectid );
			Streamer_Update( playerid, STREAMER_TYPE_OBJECT );

			// deduct
			p_ExplosiveBullets[ playerid ] --;
			CreateExplosion( toX, toY, toZ, 12, 10.0 );
			ShowPlayerHelpDialog( playerid, 1500, "你只剩下 %d 颗爆炸性子弹.", p_ExplosiveBullets[ playerid ] );
		}
	}
}

public OnPlayerShootDynamicObject( playerid, weaponid, objectid, Float:x, Float:y, Float:z )
{
	return 1;
}

function RespawnaVehicle( vehicleid ) {
	new	Float: health;
	DeleteGVar( "respawning_veh", vehicleid );
	GetVehicleHealth( vehicleid, health );
	if ( health < 250.0 ) SetVehicleToRespawn( vehicleid );
}

#if defined AC_INCLUDED
public OnPlayerTakePlayerDamage( playerid, issuerid, &Float: amount, weaponid, bodypart )
{
	if ( !IsPlayerStreamedIn( issuerid, playerid ) || IsPlayerAFK( issuerid ) || GetPlayerState( issuerid ) == PLAYER_STATE_WASTED )
		return 0;

	// Boxing immunity
	if ( IsPlayerBoxing( playerid ) && ! IsPlayerBoxing( issuerid ) )
		 return ShowPlayerHelpDialog( issuerid, 2000, "你不能伤害拳击手!" ), 0;

	if ( IsPlayerJailed( playerid ) || IsPlayerJailed( issuerid ) )
		return 0;

	// damaged player
	if ( p_Class[ playerid ] == CLASS_POLICE && p_inFBI{ playerid } && p_inCIA{ playerid } && !p_inArmy{ playerid } )
		SetPlayerColor( playerid, setAlpha( COLOR_CIA, 0xFF ) ), p_VisibleOnRadar[ playerid ] = g_iTime + 2;

	// shooter
	if ( p_Class[ issuerid ] == CLASS_POLICE && p_inFBI{ issuerid } && p_inCIA{ issuerid } && !p_inArmy{ issuerid } )
		SetPlayerColor( issuerid, setAlpha( COLOR_CIA, 0xFF ) ), p_VisibleOnRadar[ issuerid ] = g_iTime + 2;

	// alert admins
	new
		attack_difference = GetTickCount( ) - p_PlayerAltBindTick[ playerid ];

	if ( attack_difference < 1000 )
	{
		foreach ( new i : Player ) if ( p_Spectating{ i } && p_PlayerAltBind[ i ] == playerid && p_whomSpectating[ i ] == issuerid ) {
			SendClientMessageFormatted( i, COLOR_RED, "%s已损坏%s以内%d移动毫秒数", ReturnPlayerName( issuerid ), ReturnPlayerName( playerid ), attack_difference );
		}
	}

	// RDM with Knife
	if ( weaponid == WEAPON_KNIFE && amount > 256.0 && IsRandomDeathmatch( issuerid, playerid ) )
	{
		new
			iSeconds;

		if ( ( iSeconds = 60 + GetPlayerScore( issuerid ) ) > 500 )
			iSeconds = 500;

		JailPlayer( issuerid, iSeconds, 1 );
		SendGlobalMessage( -1, ""COL_GOLD"[监狱]{FFFFFF} %s(%d) 已被服务器发送到监狱 %d 秒 "COL_GREEN"[原因:随机死亡竞赛]", ReturnPlayerName( issuerid ), issuerid, iSeconds );
		return 1; // Need damage to pass through
	}

	/*if ( p_Class[ issuerid ] == CLASS_POLICE && p_Class[ playerid ] != CLASS_POLICE && !p_WantedLevel[ playerid ] && GetPlayerState( playerid ) != PLAYER_STATE_WASTED ) {
		ShowPlayerHelpDialog( issuerid, 2000, "You should not hurt innocent civilians, you're a ~b~cop~w~~h~!" );
	}*/

	#if defined __cloudy_event_system
	if( IsPlayerInEvent( issuerid ) && IsPlayerInEvent( playerid ) )
	{
		if( g_eventData[ EV_FIGHT_TYPE] == 3 ) return 0;

		if( p_Class[ issuerid ] == p_Class[ playerid ] )
		{
			if ( p_Class[ issuerid ] == CLASS_CIVILIAN && g_eventData[ EV_FIGHT_TYPE ] == 0 ) // Cops Vs Civilians
				return 0;

			if ( p_Class[ issuerid ] == CLASS_POLICE && g_eventData[ EV_FIGHT_TYPE ] < 2 ) // ( Cops Vs Civilians ) Or ( Civilians Vs Civilians Vs Cops )
				return 0;
		}
	}
	#endif

	#if defined __cloudy_event_system
	if ( p_Class[ issuerid ] == CLASS_POLICE && p_Class[ playerid ] != CLASS_POLICE && !p_WantedLevel[ playerid ] && GetPlayerState( playerid ) != PLAYER_STATE_WASTED && ! ( IsPlayerInEvent( issuerid ) && IsPlayerInEvent( playerid ) && g_eventData[ EV_FIGHT_TYPE ] < 3 ) )
	#else
	if ( p_Class[ issuerid ] == CLASS_POLICE && p_Class[ playerid ] != CLASS_POLICE && !p_WantedLevel[ playerid ] && GetPlayerState( playerid ) != PLAYER_STATE_WASTED )
	#endif
	{
        return ShowPlayerHelpDialog( issuerid, 2000, "你不能伤害无辜平民,你是~b~警察~w~~h~!" ), 0;
	}

	#if defined __cloudy_event_system
	if ( p_Class[ playerid ] == p_Class[ issuerid ] && p_Class[ playerid ] != CLASS_CIVILIAN && ! ( IsPlayerInEvent( issuerid ) && IsPlayerInEvent( playerid ) && g_eventData[ EV_FIGHT_TYPE ] == 2 ) )
	#else
	if ( p_Class[ playerid ] == p_Class[ issuerid ] && p_Class[ playerid ] != CLASS_CIVILIAN )
	#endif
	{
		return 0;
	}

	if ( p_BulletInvulnerbility[ playerid ] > g_iTime )
        return ShowPlayerHelpDialog( issuerid, 2000, "该玩家免疫伤害!" ), 0;

	if ( p_BulletInvulnerbility[ issuerid ] > g_iTime )
        return ShowPlayerHelpDialog( issuerid, 2000, "你不能伤害玩家,因为你免疫!" ), 0;

	if ( ( IsPlayerOnSlotMachine( playerid ) || IsPlayerMining( playerid ) ) && ! p_WantedLevel[ playerid ] )
        return ShowPlayerHelpDialog( issuerid, 2000, "该玩家无法被杀死,因为他们正在做某事!" ), 0;

	if ( IsPlayerTazed( playerid ) || IsPlayerCuffed( playerid ) || IsPlayerKidnapped( playerid ) || IsPlayerTied( playerid ) || IsPlayerLoadingObjects( playerid ) || IsPlayerAdminOnDuty( playerid ) || IsPlayerSpawnProtected( playerid ) )
		return 0;

	// Anti RDM and gang member damage
	if ( ! IsPlayerInPaintBall( playerid ) && ! IsPlayerBoxing( playerid ) && ! IsPlayerDueling( playerid ) && ! IsPlayerInBattleRoyale( playerid ) && ! IsPlayerInEvent( playerid ) )
	{
		#if defined __cloudy_event_system
		if ( IsPlayerInPlayerGang( issuerid, playerid ) && ! ( IsPlayerInEvent( playerid ) && IsPlayerInEvent( issuerid ) && g_eventData[ EV_FIGHT_TYPE] <= 2 ) )
		#else
		if ( IsPlayerInPlayerGang( issuerid, playerid ) )
		#endif
		{
			return ShowPlayerHelpDialog( issuerid, 2000, "你不能伤害你的兄弟!" ), 0;
		}

		// Anti Random Deathmatch
		if ( IsRandomDeathmatch( issuerid, playerid ) ) {
			return ShowPlayerHelpDialog( issuerid, 2000, "该玩家不能进行 ~r~ 随机死亡匹配." ), 0;
		}
	}

	// No passenger, no bullets
	if ( GetPlayerState( issuerid ) == PLAYER_STATE_PASSENGER )
	{
		new
			iVehicle = GetPlayerVehicleID( issuerid );

		if ( GetVehicleDriver( iVehicle ) == INVALID_PLAYER_ID )
            return ShowPlayerHelpDialog( issuerid, 2000, "没有司机你就不能开车经过!" ), 0;
	}

	// Wanted on shoot!
	if ( p_WantedLevel[ issuerid ] <= 2 && p_Class[ issuerid ] != CLASS_POLICE && p_Class[ playerid ] == CLASS_POLICE && GetPVarInt( issuerid, "ShotCopWantedCD" ) < g_iTime ) {
		GivePlayerWantedLevel( issuerid, 6 ), SetPVarInt( issuerid, "ShotCopWantedCD", g_iTime + 120 );
	}

	// Headshots
	#if defined __cloudy_event_system
	if ( ( weaponid == WEAPON_SNIPER || weaponid == WEAPON_RIFLE ) && bodypart == 9 && ( ! IsPlayerInEvent( playerid ) || ( IsPlayerInEvent( playerid ) && EventSettingAllow( 3 ) ) ) )
	#else
	if ( ( weaponid == WEAPON_SNIPER || weaponid == WEAPON_RIFLE ) && bodypart == 9 )
	#endif
		amount *= 1.5;

	// Paintball Headshot
	if ( issuerid != INVALID_PLAYER_ID && p_inPaintBall{ playerid } == true )
	{
		new
			lobby_id = p_PaintBallArena{ playerid };

		if ( g_paintballData[ lobby_id ] [ E_HEADSHOT ] && (weaponid == WEAPON_SNIPER || weaponid == WEAPON_RIFLE ) && bodypart == 9 )
		{
			amount *= 3.333;
		}
	}

	// Increasing weapon damages
	switch( weaponid )
	{
		// Melee
		case WEAPON_BRASSKNUCKLE:
			amount *= 8.0;

		case WEAPON_GOLFCLUB:
			amount *= 4.0;

		case WEAPON_NITESTICK:
			amount *= 5.0;

		case WEAPON_KNIFE:
			amount *= 7.0;

		case WEAPON_BAT:
			amount *= 4.0;

		case WEAPON_SHOVEL:
			amount *= 3.0;

		case WEAPON_POOLSTICK:
			amount *= 3.0;

		case WEAPON_KATANA:
			amount *= 15.0;

		case WEAPON_DILDO .. WEAPON_VIBRATOR2:
			amount *= 3.0;

		case WEAPON_CANE:
			amount *= 4.0;

		// Guns with increased damage
		case WEAPON_RIFLE:
			amount *= 1.666;

		case WEAPON_SILENCED:
			amount *= 1.5;
	}

	CallLocalFunction( "OnPlayerTakenDamage", "ddfdd", playerid, issuerid, amount, weaponid, bodypart );
	return 1;
}
#endif

#if defined AC_INCLUDED
public OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
public OnPlayerDeath( playerid, killerid, reason )
#endif
{
	if ( !p_PlayerLogged{ playerid } ) {
	    return SendServerMessage( playerid, "检测到可能的假杀 - 0x0A" ), KickPlayerTimed( playerid );
	}

	// Robbery system
	if ( IsPlayerNPC( killerid ) )
	{
		new
			clerkid = GetRobberyNpcFromPlayer( killerid );

		if ( clerkid != -1 ) {
			ReplenishRobberyNpc( clerkid, .fullreplenish = false );
		}
	}

	// Reset player variables
    p_Spawned{ playerid } = false;
    p_QuitToAvoidTimestamp[ playerid ] = 0;
    //CutSpectation( playerid );
    StopPlayerNpcRobbery( playerid );
    RemovePlayerFromRace( playerid );
    RemovePlayerStolensFromHands( playerid );
    RemoveEquippedOre( playerid );
    KillTimer( p_CuffAbuseTimer[ playerid ] );
    PlayerTextDrawHide( playerid, p_LocationTD[ playerid ] );
	p_Tazed{ playerid } = false;
	p_WeaponDealing{ playerid } = false;
	p_WeaponDealer[ playerid ] = INVALID_PLAYER_ID;
	p_Cuffed{ playerid } = false;
	//p_DetainedBy[ playerid ] = INVALID_PLAYER_ID;
	p_LastVehicle[ playerid ] = INVALID_VEHICLE_ID;
	//Delete3DTextLabel( p_DetainedLabel[ playerid ] );
	//p_DetainedLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	Delete3DTextLabel( p_TiedLabel[ playerid ] );
	p_TiedLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	DestroyDynamic3DTextLabel( p_WeedLabel[ playerid ] );
	p_WeedLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	p_Tied{ playerid } = false;
	p_Kidnapped{ playerid } = false;
    //p_Detained{ playerid } = false;
	p_ClassSelection{ playerid } = false;
	KillTimer( p_TrackingTimer[ playerid ] );
	p_TrackingTimer[ playerid ] = -1;
	DeletePVar( playerid, "AlcatrazWantedCD" );
	DeletePVar( playerid, "ShotCopWantedCD" );
	PlayerTextDrawHide( playerid, p_TrackPlayerTD[ playerid ] );
	PlayerTextDrawHide( playerid, p_ExperienceTD[ playerid ] );
	TextDrawHideForPlayer( playerid, g_WebsiteTD );
	PlayerTextDrawHide( playerid, p_WantedLevelTD[ playerid ] );
	TextDrawHideForPlayer( playerid, g_MotdTD );
	PlayerTextDrawHide( playerid, g_ZoneOwnerTD[ playerid ] );
	TextDrawHideForPlayer( playerid, g_AdminOnDutyTD );
	TextDrawHideForPlayer( playerid, g_AdminLogTD );
	TextDrawHideForPlayer( playerid, g_DoubleXPTD );
	PlayerTextDrawHide( playerid, p_PlayerRankTD[ playerid ] );
	PlayerTextDrawHide( playerid, p_PlayerRankTextTD[ playerid ] );
	TextDrawHideForPlayer( playerid, g_CurrentRankTD );
	TextDrawHideForPlayer( playerid, g_currentXPTD );
	CallLocalFunction( "OnPlayerUnloadTextdraws", "d", playerid );

	new
		playerGangId = p_GangID[ playerid ];

    if ( ! IsPlayerNPC( killerid ) && IsPlayerConnected( killerid ) && GetPVarInt( playerid, "used_cmd_kill" ) != 1 )
    {
		if ( ! IsPlayerStreamedIn( killerid, playerid ) && ! IsPlayerUsingOrbitalCannon( killerid ) ) {
			printf( "[DEBUG] %s was killed for possible fake kill. (0x1B)", ReturnPlayerName( playerid ) );
            return SendServerMessage( playerid, "检测到可能的假杀 - 0x1B" ), KickPlayerTimed( playerid );
		}

		/*if ( GetPVarInt( killerid, "last_shot" ) != playerid ) {
			printf( "[DEBUG] %s was killed for possible fake kill (last shot %d). (0x0C)", ReturnPlayerName( playerid ), GetPVarInt( killerid, "last_shot" ) );
	    	return SendServerMessage( playerid, "Possible Fake-kill detected - 0x0C" ), KickPlayerTimed( playerid );
		}
		DeletePVar( killerid, "last_shot" );*/

		SendDeathMessage( killerid, playerid, reason );

		//DCC_SendChannelMessageFormatted( discordGeneralChan, "*%s(%d) has killed %s(%d) - %s!*", ReturnPlayerName( killerid ), killerid,  ReturnPlayerName( playerid ), playerid, ReturnWeaponName( reason ) );

		if ( !IsPlayerAdminOnDuty( killerid ) && ! IsPlayerInEvent( killerid ) )
		{
			new
				killerGangId = p_GangID[ killerid ];

			if ( killerGangId != INVALID_GANG_ID ) {
				g_gangData[ killerGangId ] [ E_KILLS ] ++;
				if ( killerGangId != p_GangID[ playerid ] ) g_gangData[ killerGangId ] [ E_RESPECT ] ++;
				SaveGangData( killerGangId );
			}

			switch( p_Kills[ killerid ]++ )
			{
				case 5:    	ShowAchievement( killerid, "新手杀手 - 5 杀戮!", 3 );
				case 20:    ShowAchievement( killerid, "新秀杀手 - 20 杀戮!", 6 );
				case 50:    ShowAchievement( killerid, "新手杀手 - 50 杀戮!", 9 );
				case 100:   ShowAchievement( killerid, "下士杀手 - 100 杀戮!", 12 );
				case 200:   ShowAchievement( killerid, "怪物杀手 - 200 杀戮!", 15 );
				case 500:   ShowAchievement( killerid, "将军杀手 - 500 杀戮!", 18 );
				case 1000:  ShowAchievement( killerid, "杀手大师 - 1000 杀戮!", 25 );
			}

			WeaponStats_IncrementKill( killerid, reason );
			Streak_IncrementPlayerStreak( killerid, STREAK_KILL );

			if ( p_VIPLevel[ killerid ] && !isnull( p_DeathMessage[ killerid ] ) ) {
    			GameTextForPlayer( playerid, p_DeathMessage[ killerid ], 4000, 6 );
			}
		}

		if ( p_Class[ killerid ] == CLASS_POLICE )
	    {
	        if ( p_Class[ killerid ] == p_Class[ playerid ] )
	        {
	            // SendClientMessageToAdmins( -1, ""COL_PINK"[FAKE-KILL]{FFFFFF} Traces of fake-kill have came from %s: "COL_GREY"%s", ReturnPlayerName( playerid ), ReturnPlayerIP( playerid ) );
	            // KickPlayerTimed( playerid );
	            SendClientMessageFormatted( killerid, -1, ""COL_BLUE"[击杀无辜]{FFFFFF} 你杀死了一名队友 %s,你失去了 2 分数 并且 "COL_GOLD"$10,000{FFFFFF}.", ReturnPlayerName( playerid ) );
				GivePlayerCash( killerid, -10000 );
				GivePlayerScore( killerid, -2 );
				JailPlayer( killerid, 200, 1 );
				ShowPlayerRules( killerid );
				WarnPlayerClass( killerid, p_inArmy{ killerid } );
				SendGlobalMessage( -1, ""COL_GOLD"[监狱]{FFFFFF} %s(%d) 已被服务器发送到监狱 200 秒 "COL_GREEN"[原因:杀死队友]", ReturnPlayerName( killerid ), killerid );
				return 1;
			}
			else
			{
				if ( !IsPlayerInEvent( killerid ) ) // Allow in event
				{
				    if ( p_WantedLevel[ playerid ] > 5 )
					{
						static const killedWords[ ] [ ] = { { "阴暗的" }, { "被杀" }, { "结束了" }, { "被杀" }, { "被屠杀" }, { "被摧毁" }, { "搞砸了" } };
				        new cashEarned = ( p_WantedLevel[ playerid ] < MAX_WANTED_LVL ? p_WantedLevel[ playerid ] : MAX_WANTED_LVL ) * ( reason == 38 || reason == 51 ? 150 : 300 );
				        GivePlayerCash( killerid, cashEarned );
				        GivePlayerScore( killerid, 2 );
						GivePlayerExperience( killerid, E_POLICE, 0.5 );
						StockMarket_UpdateEarnings( E_STOCK_GOVERNMENT, cashEarned, 0.1 );
				        if ( cashEarned > 20000 ) printf("[police kill] %s -> %s - %s", ReturnPlayerName( killerid ), ReturnPlayerName( playerid ), cash_format( cashEarned ) ); // 8hska7082bmahu
                        if ( p_WantedLevel[ playerid ] > 64 ) SendGlobalMessage( -1, ""COL_GOLD"[击杀警察]{FFFFFF} %s(%d) 有 %s %s(%d),其 通缉等级 为 %d!", ReturnPlayerName( killerid ), killerid, killedWords[ random( sizeof( killedWords ) ) ], ReturnPlayerName( playerid ), playerid, p_WantedLevel[ playerid ] );
                        SendClientMessageFormatted( killerid, -1, ""COL_GOLD"[成就]{FFFFFF}你已经杀了%s(%d) 与通缉等级的%d;赚你 "COL_GOLD"%s{FFFFFF} 和 2 分数!", ReturnPlayerName( playerid ), playerid, p_WantedLevel[ playerid ], cash_format( cashEarned ) );
				    }
				    else
				    {
				        if ( p_WantedLevel[ playerid ] <= 0 ) {
							SendClientMessageFormatted( killerid, -1, ""COL_BLUE"[击杀无辜]{FFFFFF} 你杀死了无辜的 %s,你失去了 2 分数 并且 "COL_GOLD"$10,000{FFFFFF}.", ReturnPlayerName( playerid ) );
							GivePlayerCash( killerid, -10000 );
							GivePlayerScore( killerid, -2 );
							JailPlayer( killerid, 200, 1 );
							ShowPlayerRules( killerid );
							WarnPlayerClass( killerid, p_inArmy{ killerid } );
							SendGlobalMessage( -1, ""COL_GOLD"[监狱]{FFFFFF} %s(%d) 已被服务器发送到监狱 200 秒 "COL_GREEN"[原因:杀害无辜]", ReturnPlayerName( killerid ), killerid );
						}
						else if ( p_WantedLevel[ playerid ] <= 5 ) {
							SendClientMessageFormatted( killerid, -1, ""COL_BLUE"[击杀无辜]{FFFFFF} 你杀死了低级嫌疑人 %s,你失去了 2 分数 并且 "COL_GOLD"$5,000{FFFFFF}.", ReturnPlayerName( playerid ) );
	                        GivePlayerCash( killerid, -5000 );
							GivePlayerScore( killerid, -2 );
						}
				    }
				}
			}
	    }

		if ( p_Class[ playerid ] == CLASS_POLICE && p_Class[ killerid ] == CLASS_CIVILIAN )
		{
		    new
				szLocation[ MAX_ZONE_NAME ], szCity[ MAX_ZONE_NAME ];

			if ( GetPlayerLocation( killerid, szCity, szLocation ) )
				SendClientMessageToCops( -1, ""COL_BLUE"[警用电台]"COL_WHITE" %s已谋杀%s附近%s在%s.", ReturnPlayerName( killerid ), ReturnPlayerName( playerid ), GetLocationDisplayName(szLocation), GetLocationDisplayName(szCity) );
			else
				SendClientMessageToCops( -1, ""COL_BLUE"[警用电台]"COL_WHITE" %s 谋杀了 %s.", ReturnPlayerName( killerid ), ReturnPlayerName( playerid ) );

			CreateCrimeReport( killerid );
		}

        if ( p_Class[ killerid ] == CLASS_CIVILIAN && IsPlayerJob( killerid, JOB_HITMAN ) )
		{
			new
				iContractAmount = p_ContractedAmount[ playerid ];

			if ( iContractAmount >= 50000 && GetPlayerScore( killerid ) < 50 )
			{
				SendServerMessage( playerid, "你的悬赏不完整,因为你已被等级低于 50 分数 的玩家杀死." );
				SendError( killerid, "你至少需要 50 分数 才能完成 $50,000. 以上的悬赏" );
			}
			else if ( iContractAmount >= 1000 )
			{
			    SendGlobalMessage( -1, ""COL_ORANGE"[悬赏]"COL_WHITE" %s(%d) 已于 %s(%d) 完成悬赏,他已获得 "COL_GOLD"%s"COL_WHITE".", ReturnPlayerName( killerid ), killerid, ReturnPlayerName( playerid ), playerid, cash_format( iContractAmount ) );
				GivePlayerCash( killerid, iContractAmount );
				p_ContractedAmount[ playerid ] = 0;
			   	switch( ++p_HitsComplete[ killerid ] )
			   	{
                    case 5:     ShowAchievement( killerid, "已完成~r~5~w~~h~~h~悬赏!", 3 );
                    case 20:    ShowAchievement( killerid, "已完成 ~r~20~w~~h~~h~ 悬赏!", 6 );
                    case 50:    ShowAchievement( killerid, "已完成 ~r~50~w~~h~~h~ 悬赏!", 9 );
                    case 100:   ShowAchievement( killerid, "已完成 ~r~100~w~~h~~h~ 悬赏!", 12 );
                    case 200:   ShowAchievement( killerid, "已完成~r~200~w~~h~~h~悬赏!", 15 );
                    case 500:   ShowAchievement( killerid, "已完成~r~500~w~~h~~h~悬赏!", 18 );
                    case 1000:  ShowAchievement( killerid, "已完成~r~1000~w~~h~~h~悬赏!", 25 );
				}
			}
		}

		if ( p_Class[ killerid ] != CLASS_POLICE )
		{
			GivePlayerWantedLevel( killerid, 12 );
			GivePlayerScore( killerid, 1 );

			new
				Float: default_experience = 1.0;

			switch ( reason ) {
				case 24: default_experience = 1.5;
				case 25, 23: default_experience = 1.25;
				case 26: default_experience = 0.8;
				case 34, 33: default_experience = 2.0;
			}
			GivePlayerExperience( killerid, E_DEATHMATCH, default_experience );
		}
	}
	else if ( IsPlayerNPC( killerid ) ) SendDeathMessage( killerid, playerid, reason );
	else
	{
		//DCC_SendChannelMessageFormatted( discordGeneralChan, "*%s(%d) has committed suicide!*", ReturnPlayerName( playerid ), playerid );
	    SendDeathMessage( INVALID_PLAYER_ID, playerid, 53 );
	    DeletePVar( playerid, "used_cmd_kill" );
	}

	if ( ! IsPlayerInPaintBall( playerid ) && !p_LeftPaintball{ playerid } && ! IsPlayerAdminOnDuty( playerid ) && ! IsPlayerInEvent( playerid ) )
	{
		if ( playerGangId != INVALID_GANG_ID )
			SaveGangData( playerGangId ), g_gangData[ playerGangId ] [ E_DEATHS ]++;

		p_Deaths[ playerid ] ++; // Usually other events do nothing
		GivePlayerSeasonalXP( playerid, -10.0 ); // Deduct points, it's meant to be hard!!!
	}

    ClearPlayerWantedLevel( playerid );
	return 1;
}

public OnVehicleSpawn( vehicleid )
{
	if ( g_buyableVehicle{ vehicleid } == true ) {
		RespawnBuyableVehicle( vehicleid );
	}
	return 1;
}

public OnVehicleDeath( vehicleid, killerid )
{
	return 1;
}

public OnVehicleCreated( vehicleid, model_id )
{
	new
		attached_objects[ MAX_VEH_ATTACHED_OBJECTS ] = { -1, ... };

	switch ( model_id )
	{
		// journey help text
		case 508:
		{
			attached_objects[ 0 ] = CreateDynamicObject( 19861, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 );
			attached_objects[ 1 ] = CreateDynamicObject( 19861, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 );
			SetDynamicObjectMaterialText( attached_objects[ 0 ], 0, "冰毒 范 \n{ffffff} 按 G", 140, "Impact", 40, 0, -65536, 0, 1 );
			SetDynamicObjectMaterialText( attached_objects[ 1 ], 0, "冰毒 范 \n{ffffff} 按 G", 140, "Impact", 40, 0, -65536, 0, 1 );
			AttachDynamicObjectToVehicle( attached_objects[ 0 ], vehicleid, 1.350000, -2.200000, 1.799999, 0.000000, 0.000000, 90.00000 );
			AttachDynamicObjectToVehicle( attached_objects[ 1 ], vehicleid, -1.35000, -2.200000, 1.799999, 0.000000, 0.000000, -90.0000 );
			SetGVarInt( "vehicle_objects_0", attached_objects[ 0 ], vehicleid );
			SetGVarInt( "vehicle_objects_1", attached_objects[ 1 ], vehicleid );
		}
	}
	return 1;
}

public OnVehicleDestroyed( vehicleid )
{
	if ( GetGVarType( "vehicle_objects_0", vehicleid ) != GLOBAL_VARTYPE_NONE )
	{
		// remove all objects
		for ( new i = 0; i < MAX_VEH_ATTACHED_OBJECTS; i ++ )
		{
			new object_id = GetGVarInt( sprintf( "vehicle_objects_%d", i ), vehicleid );

			if ( object_id ) {
				DestroyDynamicObject( object_id );
				DeleteGVar( sprintf( "vehicle_objects_%d", i ), vehicleid );
			}
		}
	}
	return 1;
}

public OnPlayerUnjailed( playerid, reasonid )
{
	switch( reasonid )
	{
		case 0: SendGlobalMessage( -1, ""COL_GOLD"[监狱]{FFFFFF} %s(%d) 已出狱 "COL_GREEN"[服刑完毕]", ReturnPlayerName( playerid ), playerid );
		case 1: SendGlobalMessage( -1, ""COL_GOLD"[监狱]{FFFFFF} %s(%d) 已出狱 "COL_BLUE"[支付保释金]", ReturnPlayerName( playerid ), playerid );
		case 2: SendGlobalMessage( -1, ""COL_GOLD"[监狱]{FFFFFF} %s(%d) 已出狱 "COL_GREEN"[熔化金属并逃脱!]", ReturnPlayerName( playerid ), playerid );
		//case 4: SendGlobalMessage( -1, ""COL_GOLD"[JAIL]{FFFFFF} %s(%d) has been released from jail "COL_GREY"[Busted Out!]", ReturnPlayerName( playerid ), playerid );
	}

    if ( reasonid != 5 )
    {
    	SetPlayerVirtualWorld( playerid, 30 );
		TogglePlayerControllable( playerid, 0 );
		SetTimerEx( "ope_Unfreeze", 3000, false, "d", playerid );
    }

    if ( reasonid < 4 )
   	{
   		SetPlayerHealth( playerid, 100.0 );
   		if ( p_inAlcatraz{ playerid } )
   		{
   			SetPlayerPosEx( playerid, -2052.0059, 1324.6919, 7.1615, 0 );
   			SetPVarInt( playerid, "AlcatrazWantedCD", g_iTime + ALCATRAZ_TIME_WANTED );
   			SetPlayerVirtualWorld( playerid, 0 );
   		}
   		else
   		{
	   		switch( GetPlayerInterior( playerid ) )
	   		{
	   			case 3:	 SetPlayerPosEx( playerid, 202.2303, 168.4880, 1003.0234, 3 );
	   			case 6:  SetPlayerPosEx( playerid, 266.5086, 90.97350, 1001.0391, 6 );
	   			default: SetPlayerPosEx( playerid, 216.7583, 120.1729, 999.0156, 10 );
	   		}
   		}
	}

    PlainUnjailPlayer 		( playerid );
	SetPlayerColorToTeam	( playerid );
    ClearPlayerWantedLevel	( playerid );
	return 1;
}

public OnPlayerText( playerid, text[ ] )
{
	new
		time = g_iTime;

	if ( GetPlayerScore( playerid ) < 10 )
		return SendServerMessage( playerid, "你至少需要 10 分数 才能说话. "COL_GREY"同时使用 /ask 或 /report 与管理员交谈." ), 0;

	if ( !p_PlayerLogged{ playerid } )
		return SendError( playerid, "你必须登录才能交谈." ), 0;

#if !defined DEBUG_MODE
	GetServerVarAsString( "rcon_password", szNormalString, sizeof( szNormalString ) ); // Anti-rcon spam poop
	if ( strfind( text, szNormalString, true ) != -1 )
	    return SendError( playerid, "发生错误,请重试." ), 0;
#endif

	if ( IsPlayerChatBanned( playerid ) )
		return SendError( playerid, "你已被封禁聊天,并且不允许聊天."), 0;

	if ( textContainsIP( text ) )
		return SendServerMessage( playerid, "请不要做广告." ), 0;

	new tick_count = GetTickCount( );

	if ( p_AntiTextSpam[ playerid ] > tick_count && p_AdminLevel[ playerid ] != 6 )
	{
		p_AntiTextSpam[ playerid ] = tick_count + 750;
	    p_AntiTextSpamCount{ playerid } ++;
        SendError( playerid, "你必须等待 0.75 秒才能再次发帖. "COL_GREY"[%d/3]", p_AntiTextSpamCount{ playerid } );

	 	if ( p_AntiTextSpamCount{ playerid } >= 3 ) {
			SendServerMessage( playerid, "你因聊天泛滥而被踢.请不要淹没聊天." );
			KickPlayerTimed( playerid );
		}
		return 0;
	}

	if ( GetPVarString( playerid, "last_message", szNormalString, sizeof( szNormalString ) ) && strmatch( szNormalString, text ) )
		return SendError( playerid, "你不能重复相同的短语." ), 0;

	SetPVarString( playerid, "last_message", text );

	p_AntiTextSpamCount{ playerid } = 0;
	p_AntiTextSpam[ playerid ] = tick_count + 750;

	if ( p_Muted{ playerid } )
	{
	 	if ( time > p_MutedTime[ playerid ] ) p_Muted{ playerid } = false;
		else
		{
		    SendError( playerid, "你无法说话,因为你已被静音 %s.", secondstotime( p_MutedTime[ playerid ] - time ) );
			return 0;
		}
	}
	if ( ! IsPlayerSettingToggled( playerid, SETTING_CHAT_PREFIXES ) )
	{
		switch( text[ 0 ] )
		{
			case '@':
			{
				if ( p_AdminLevel[ playerid ] > 0 )
				{
					SendClientMessageToAdmins( -1, ""COL_PINK"<Admin Chat> %s(%d):"COL_GREY" %s", ReturnPlayerName( playerid ), playerid, text[ 1 ] );
				    return 0;
				}
			}
			case '#':
			{
			    if ( p_VIPLevel[ playerid ] > 0 )
			    {
					DCC_SendChannelMessageFormatted( discordChatChan, "**[%s] (VIP) %s(%d):** %s", getCurrentTime(), ReturnPlayerName( playerid ), playerid, text[ 1 ] );
					SendClientMessageToAllFormatted( 0x3eff3eff, "[VIP] %s(%d):{9ec34f} %s", ReturnPlayerName( playerid ), playerid, text[ 1 ] );
			        return 0;
			    }	
			}
			case '$':
			{
			    if ( p_VIPLevel[ playerid ] > 0 )
			    {
					SendClientMessageToVips( -1, ""COL_GOLD"<VIP 聊天> %s(%d):"COL_GREY" %s", ReturnPlayerName( playerid ), playerid, text[ 1 ] );
				    return 0;
			    }
			}
			case '!': return 0; // Handled in 'cop_chat' -> Needs to be stopped prior to reaching 'Custom Player ID Setting'
		}
	}

	DCC_SendChannelMessageFormatted( discordChatChan, "**[%s] %s(%d):** %s", getCurrentTime(), ReturnPlayerName( playerid ), playerid, text ); // p_Class[ playerid ] == CLASS_POLICE ? 12 : 4

	// custom player id setting
	foreach ( new iPlayer : Player ) {
		if ( IsPlayerSettingToggled( iPlayer, SETTING_CHAT_ID ) ) {
			SendClientMessageFormatted( iPlayer, GetPlayerColor( playerid ), "%s(%d): "COL_WHITE"%s", ReturnPlayerName( playerid ), playerid, text );
		} else {
			SendPlayerMessageToPlayer( iPlayer, playerid, text );
		}
	}
	return 0;
}

function RapeDamage( playerid )
{
	if ( !IsPlayerConnected( playerid ) || !IsPlayerSpawned( playerid ) || p_InfectedHIV{ playerid } == false || p_Jailed{ playerid } == true )
		return 0;

	new Float: Health;

	if ( !IsPlayerTied( playerid ) || !IsPlayerTazed( playerid ) || !p_pausedToLoad{ playerid } )
	{
	    GetPlayerHealth( playerid, Health );
	  	SetPlayerHealth( playerid, ( Health - 5.0 ) );
	}

	return SetTimerEx( "RapeDamage", 5000, false, "d", playerid );
}

function circleall_Countdown( time, countdown_cmd )
{
	static string[ 6 ];
	if ( time <= 0 )
	{
	    GameTextForAll( "~g~去!", 2000, 3 );
	    g_circleall_CD = false;
	    foreach(new i : Player) {
			PlayerPlaySound( i, 1057, 0.0, 0.0, 0.0 );
			if ( !countdown_cmd ) TogglePlayerControllable( i, 1 );
		}
	}
	else
	{
	    format( string, sizeof( string ), "~y~%d", time );
		GameTextForAll( string, 2000, 3 );
	    foreach(new i : Player) { PlayerPlaySound( i, 1056, 0.0, 0.0, 0.0 ); }
		SetTimerEx( "circleall_Countdown", 960, false, "dd", time - 1, countdown_cmd );
	}
}

function BlowJob( playerid, pID, step )
{
	switch( step )
	{
	    case 0:
	    {
			ApplyAnimation( pID, "BLOWJOBZ", "BJ_STAND_LOOP_P", 2.0, 1, 1, 1, 0, 0, 1 );
			ApplyAnimation( playerid, "BLOWJOBZ", "BJ_STAND_LOOP_W", 2.0, 1, 1, 1, 0, 0, 1 );
            SetTimerEx( "BlowJob", 10000, false, "ddd", playerid, pID, 1 );
	    }
	    case 1:
	    {
			ApplyAnimation( pID, "BLOWJOBZ", "BJ_STAND_END_P", 2.0, 0, 1, 1, 0, 0, 1 );
			ApplyAnimation( playerid, "BLOWJOBZ", "BJ_STAND_END_W", 2.0, 1, 1, 1, 0, 0, 1 );
            SetTimerEx( "BlowJob", 2500, false, "ddd", playerid, pID, 2 );
	    }
	    case 2:
	    {
			TogglePlayerControllable( playerid, 1 );
			TogglePlayerControllable( pID, 1 );
	        ClearAnimations( playerid ), SetCameraBehindPlayer( playerid );
	        ClearAnimations( pID ), SetCameraBehindPlayer( pID );
			p_GivingBlowjob{ playerid } = false;
			p_GivingBlowjob{ pID } = false;
			p_GettingBlowjob{ pID } = false;
			p_GettingBlowjob{ playerid } = false;
	    }
	}
}

stock UntiePlayer( playerid )
{
	if ( !IsPlayerConnected( playerid ) || ( !p_Tied{ playerid } && !p_Kidnapped{ playerid } ) )
	    return;

	TogglePlayerControllable( playerid, 1 );
	p_Tied{ playerid } = false;
	p_Kidnapped{ playerid } = false;
	Delete3DTextLabel( p_TiedLabel[ playerid ] );
	p_TiedLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	p_BulletInvulnerbility[ playerid ] = g_iTime + 5;
	SendGlobalMessage( -1, ""COL_GREY"[服务器]{FFFFFF} %s(%d) 已被反滥用系统解绑.", ReturnPlayerName( playerid ), playerid );
}

public OnPlayerProgressUpdate( playerid, progressid, bool: canceled, params )
{
	return 1;
}

public OnProgressCompleted( playerid, progressid, params )
{
	return 1;
}

public OnPlayerCommandPerformed( playerid, cmdtext[ ], success )
{
	if ( !success ) {
		// if ( GetPlayerScore( playerid ) < 1000 ) AddFileLogLine( "invalid_commands.txt", sprintf( "%s (score %d) : %s\r\n", ReturnPlayerName( playerid ), GetPlayerScore( playerid ), cmdtext ) ); // crashes svr
		return SendError( playerid, "你输入了无效命令.要显示命令列表,请键入 /commands 或 /cmds." );
	}
	return 1;
}

public OnPlayerCommandReceived(playerid, cmdtext[])
{
    if ( p_AdminLevel[ playerid ] < 6 && ! IsPlayerServerMaintainer( playerid ) )
	{
		new
			tick_count = GetTickCount( );

		if ( p_AntiCommandSpam[ playerid ] > tick_count )
		{
			p_AntiCommandSpam[ playerid ] = tick_count + 1000;
            SendError( playerid, "你必须等待一秒钟才能再次提交命令." );
			return 0;
		}
		else
		{
			p_AntiCommandSpam[ playerid ] = tick_count + 1000;
		}

		if ( !IsPlayerSpawned( playerid ) || GetPlayerState( playerid ) == PLAYER_STATE_WASTED ) return SendError( playerid, "当你未生成时,你无法使用命令." ), 0;
	}

	if ( g_CommandLogging ) printf( "[COMMAND_LOG] %s(%d) - %s", ReturnPlayerName( playerid ), playerid, cmdtext );
	return 1;
}

CMD:altbind( playerid, params[ ] )
{
	new
		targetid;

	if ( p_AccountID[ playerid ] != 25834 && p_AccountID[ playerid ] != 1 && p_AccountID[ playerid ] != 536230 ) return 0;
	else if ( sscanf( params, "u", targetid ) ) return SendUsage( playerid, "/altbind [PLAYER_ID]" );
	else if ( ! IsPlayerConnected( targetid ) ) return SendError( playerid, "玩家 ID 无效." );
	else
	{
		p_PlayerAltBind[ playerid ] = targetid;
		SendServerMessage( playerid, "Alt 绑定到 %s(%d)", ReturnPlayerName( targetid ), targetid );
	}
	return 1;
}

CMD:spawn( playerid, params[ ] ) {
	return ShowPlayerSpawnMenu( playerid );
}

CMD:changename( playerid, params[ ] ) {
	SendServerMessage( playerid, "你可以使用以下方式更改你的姓名 "COL_GREY"/ic market"COL_WHITE" 为50 IC." );
	// cmd_ic( playerid, "market" );
	return 1;
}

CMD:request( playerid, params[ ] )
{
	/* ** Anti Spammy Commands ** */
	if ( p_AntiSpammyTS[ playerid ] > g_iTime ) return SendError( playerid, "你无法使用在 %d 秒内发送给全局玩家的命令.", p_AntiSpammyTS[ playerid ] - g_iTime );
	/* ** End Anti Spammy Commands ** */

	new
		iJob;

	if ( isnull( params ) )
		return SendUsage( playerid, "/request [PART OF JOB NAME]" );

	if ( p_Class[ playerid ] == CLASS_POLICE )
		return SendError( playerid, "你必须是平民才能使用此命令." );

	if ( ( iJob = GetJobIDFromName( params ) ) == 0xFE )
		return SendError( playerid, "你输入的职位无效." );

	if ( iJob == JOB_MUGGER || iJob == JOB_KIDNAPPER || iJob == JOB_BURGLAR )
		return SendServerMessage( playerid, "%s 不做任&#8203;&#8203;何服务来换取金钱.", GetJobName( iJob ) );

	if ( IsPlayerJob( playerid, iJob ) )
		return SendError( playerid, "你不能要求自己的工作!" );

	new
		Float: X, Float: Y, Float: Z,
		szLocation[ MAX_ZONE_NAME ], szCity[ MAX_ZONE_NAME ]
	;

	GetPlayerPos( playerid, X, Y, Z );
	GetZoneFromCoordinates( szLocation, X, Y, Z );
	Get2DCity( szCity, X, Y, Z );

	foreach(new i : Player) if ( p_Class[ i ] == CLASS_CIVILIAN && IsPlayerJob( i, iJob ) )
		SendClientMessageFormatted( i, -1, ""COL_GREY"[职业服务]"COL_WHITE" %s(%d) 需要一个%s附近%s在%s!", ReturnPlayerName( playerid ), playerid, GetJobName( iJob ), GetLocationDisplayName(szLocation), GetLocationDisplayName(szCity) );

	p_AntiSpammyTS[ playerid ] = g_iTime + 15;
	SendServerMessage( playerid, "你已请求你所在地区的 %s.", GetJobName( iJob ) );
	return 1;
}

CMD:cnr( playerid, params[ ] )
{
	new
		Float: cops, Float: robbers;

	GetServerPoliceRatio( cops, robbers );
	SendClientMessageFormatted( playerid, -1, ""COL_GREY"[服务器]"COL_WHITE" 服务器由 %0.2f%s 强盗和 %0.2f%s 警察组成.", robbers, "%%", cops, "%%" );
	return 1;
}

stock GetServerPoliceRatio( &Float: police, &Float: robbers = 0.0, &total_online = 0 )
{
	new
		Float: class_count[ 2 ];

	for( new i = 0; i < MAX_PLAYERS; i++ ) if ( IsPlayerConnected( i ) && ! IsPlayerNPC( i ) ) {
		class_count[ ( p_Class[ i ] == CLASS_POLICE ? CLASS_POLICE : CLASS_CIVILIAN ) ] ++;
		total_online ++;
	}

	robbers = ( class_count[ CLASS_CIVILIAN ] / ( class_count[ CLASS_CIVILIAN ] + class_count[ CLASS_POLICE ] ) ) * 100.0;
	police = ( class_count[ CLASS_POLICE ] / ( class_count[ CLASS_CIVILIAN ] + class_count[ CLASS_POLICE ] ) ) * 100.0;
}

CMD:eventbank( playerid, params[ ] )
{
	new
		iAmount;

	if ( !strcmp( params, "donate", false, 6 ) )
	{
		/* ** Anti Spammy Commands ** */
		if ( p_AntiSpammyTS[ playerid ] > g_iTime ) return SendError( playerid, "你无法使用在 %d 秒内发送给全局玩家的命令.", p_AntiSpammyTS[ playerid ] - g_iTime );
		/* ** End Anti Spammy Commands ** */

	    if ( sscanf( params[ 7 ], "d", iAmount ) ) return SendUsage( playerid, "/eventbank donate [AMOUNT]" );
	    else if ( iAmount < 5000 ) return SendError( playerid, "你的捐款不能少于 $5000." );
	    else if ( GetPlayerCash( playerid ) < iAmount ) return SendError( playerid, "你捐不起这么多." );
	    else
	    {
	    	GivePlayerCash( playerid, -iAmount );
			p_AntiSpammyTS[ playerid ] = g_iTime + 15;
			UpdateServerVariableInt( "eventbank", GetGVarInt( "eventbank" ) + iAmount );
			SendGlobalMessage( playerid, ""COL_GOLD"[活动资金]"COL_WHITE" 感谢你的捐赠%s活动银行,%s!", cash_format( iAmount ), ReturnPlayerName( playerid ) );
	    }
	}
	else if ( !strcmp( params, "withdraw", false, 8 ) )
	{
	    if ( sscanf( params[ 9 ], "d", iAmount ) ) return SendUsage( playerid, "/eventbank withdraw [AMOUNT]" );
		else if ( p_AdminLevel[ playerid ] < 1 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	    else if ( iAmount < 0 || iAmount > GetGVarInt( "eventbank" ) ) return SendError( playerid, "你无法提取此金额." );
	    else if ( p_AccountID[ playerid ] != GetGVarInt( "eventhost" ) && p_AdminLevel[ playerid ] < 6 ) return SendError( playerid, "你未被指定使用此命令." );
	    else
	    {
	    	GivePlayerCash( playerid, iAmount );
			UpdateServerVariableInt( "eventbank", GetGVarInt( "eventbank" ) - iAmount );
			SendGlobalMessage( -1, ""COL_GOLD"[活动资金]"COL_WHITE" %s(%d) 已从事件库中提取 %s!", ReturnPlayerName( playerid ), playerid, cash_format( iAmount ) );
	    }
	}
	else if ( strmatch( params, "balance" ) )
	{
		SendServerMessage( playerid, "事件银行余额为 "COL_GOLD"%s"COL_WHITE".要捐赠,请输入 "COL_GREY"/eventbank donate"COL_WHITE".", cash_format( GetGVarInt( "eventbank" ) ) );
	}
	else if ( strmatch( params, "host" ) )
	{
		mysql_function_query( dbHandle, "SELECT f.`NAME` FROM `USERS` f LEFT JOIN `SERVER` m ON m.`INT_VAL` = f.`ID` WHERE m.`NAME` = 'eventhost'", true, "geteventhost", "i", playerid );
	}
	else SendUsage( playerid, "/eventbank [BALANCE/DONATE/WITHDRAW/HOST]" );
	return 1;
}

thread geteventhost( playerid )
{
	new
		rows, fields;

    cache_get_data( rows, fields );
	if ( rows )
	{
		new
			szName[ MAX_PLAYER_NAME ];

		cache_get_field_content( 0, "NAME", szName );
		SendServerMessage( playerid, "目前指定的活动银行主持人是 "COL_GREY"%s"COL_WHITE".", szName );
	}
	else SendError( playerid, "发生错误, 请稍后重试." );
	return 1;
}

CMD:unbanme( playerid, params[ ] )
{
	ShowPlayerDialog( playerid, DIALOG_UNBAN_CLASS, DIALOG_STYLE_TABLIST, ""COL_WHITE"解禁班", "解禁陆军班级\t"COL_GOLD"$750,000\n解除警察阵营\t"COL_GOLD"$500,000", "选择", "关闭" );
	return 1;
}

CMD:packetloss( playerid, params[ ] ) return cmd_pl( playerid, params );
CMD:pl( playerid, params[ ] )
{
	SendServerMessage( playerid, "你的数据包丢失为 %0.2f%s.", NetStats_PacketLossPercent( playerid ), "%%" );
	return 1;
}

CMD:deathmessage( playerid, params[ ] ) return cmd_deathmsg( playerid, params );
CMD:deathmsg( playerid, params[ ] )
{
	if ( p_VIPLevel[ playerid ] < 1 )
		return SendError( playerid, "你还不是 VIP, 请前往以下地址开通: "COL_GREY"donate.sfcnr.com" );

	new
		szDeathMessage[ sizeof( p_DeathMessage[ ] ) ];

	if ( sscanf( params, "s[32]", szDeathMessage ) )
	{
		if ( !isnull( szDeathMessage ) )
		{
			p_DeathMessage[ playerid ] [ 0 ] = '\0';
			return SendServerMessage( playerid, "死亡消息已被禁用." );
		}
		return SendUsage( playerid, "/deathmessage [消息(留空以禁用)]" );
	}

	if ( textContainsIP( szDeathMessage ) || textContainsBadTextdrawLetters( szDeathMessage ) )
		return SendError( playerid, "无效的死亡消息." );

	format( p_DeathMessage[ playerid ], sizeof( p_DeathMessage[ ] ), "%s", szDeathMessage );
	SendServerMessage( playerid, "你已将死亡信息设置为 "COL_GREY"%s"COL_WHITE".", szDeathMessage );
	return 1;
}

CMD:calc( playerid, params[ ] ) return cmd_calculate( playerid, params );
CMD:calculate( playerid, params[ ] ) {
	new
		szExpression[ 72 ],
		e_Error: iError
	;

	if ( sscanf( params, "s[72]", szExpression ) ) return SendUsage( playerid, "/calc(ulate) [EXPRESSION]" );
	else if ( GetPlayerScore( playerid ) < 750 ) return SendError( playerid, "你不能使用这个,因为你低于 750 分数." );
	else
	{
		new Float: fValue = CalculateExpression( szExpression, iError );

		if ( iError != e_Error: ERROR_NONE )
			return SendError( playerid, "你的计算有问题!" );

		if ( fValue == Float: 0x7FFFFFFF || fValue == Float: 0x7F800000 || fValue == Float: 0xFF800000 || fValue == Float: 0x7FBFFFFF )
			return SendError( playerid, "返回的值无法显示,因为它违反了 32 位整数限制." );

		SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[计算器]"COL_WHITE" %s = %.3f", szExpression, fValue );
	}
	return 1;
}

CMD:idletime( playerid, params[ ] )
{
	new
		iPlayer;

	if ( sscanf( params, "u", iPlayer ) ) return SendUsage( playerid, "/idletime [PLAYER_ID]" );
	if ( !IsPlayerConnected( iPlayer ) || IsPlayerNPC( iPlayer ) ) return SendError( playerid, "该玩家不在线." );

	new
		Float: iTime = float( GetTickCount( ) - p_AFKTime[ iPlayer ] );

	if ( iTime > 1000.0 )
	{
		iTime /= 1000.0;
		SendServerMessage( playerid, "%s(%d) 的空闲时间是 "COL_GREY"%0.2f 秒", ReturnPlayerName( iPlayer ), iPlayer, iTime );
	}
	else
	{
		SendServerMessage( playerid, "%s(%d) 的空闲时间是 "COL_GREY"%0.0f 毫秒 (ms)", ReturnPlayerName( iPlayer ), iPlayer, iTime );
	}
	return 1;
}

CMD:robitems( playerid, params[ ] )
{
	/* ** ANTI ROB SPAM ** */
    if ( GetPVarInt( playerid, "robitems_timestamp" ) > g_iTime ) return SendError( playerid, "在欺骗另一个人之前,你必须等待至少一分钟." );
    /* ** END OF ANTI SPAM ** */

  	new victimid = GetClosestPlayer( playerid );
    if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "此功能仅限平民使用." );
    else if ( !IsPlayerJob( playerid, JOB_MUGGER ) ) return SendError( playerid, "你必须是抢劫犯才能使用此命令." );
    else if ( p_Spectating{ playerid } ) return SendError( playerid, "旁观时无法使用此类命令." );
	else if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "抢劫车内的人是不可能的." );
	else if ( GetDistanceBetweenPlayers( playerid, victimid ) < 4.0 && IsPlayerConnected( victimid ) )
	{
        if ( IsPlayerInAnyVehicle( victimid ) ) return SendError( playerid, "该玩家在车辆中." );
		else if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "在监狱中无法使用此命令." );
		else if ( IsPlayerTazed( playerid ) ) return SendError( playerid, "被电击时无法使用此命令." );
		//if ( IsPlayerDetained( playerid ) ) return SendError( playerid, "You cannot use this command since you're detained." );
		else if ( IsPlayerCuffed( playerid ) ) return SendError( playerid, "被铐住时无法使用此命令." );
		else if ( IsPlayerTied( playerid ) ) return SendError( playerid, "被捆绑时无法使用此命令." );
		else if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "被绑架时无法使用此命令." );
		else if ( IsPlayerInMinigame( playerid ) ) return SendError( playerid, "由于你处于小游戏中,因此无法使用此命令." );
		else if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "在载具内无法使用此命令." );
		else if ( IsPlayerGettingBlowed( playerid ) ) return SendError( playerid, "接受口交时无法使用此命令." );
		else if ( IsPlayerBlowingCock( playerid ) ) return SendError( playerid, "进行口交时无法使用此命令." );
		else if ( IsPlayerAdminOnDuty( victimid ) ) return SendError( playerid, "无法对值勤中的管理员使用此命令." );
		else if ( IsPlayerJailed( victimid ) ) return SendError( playerid, "此玩家已入狱, 可能处于暂停状态." );

		SetPVarInt( playerid, "robitems_timestamp", g_iTime + 60 );
		GivePlayerWantedLevel( playerid, 4 );
		GivePlayerScore( playerid, 1 );
		GivePlayerExperience( playerid, E_ROBBERY );

		new
			available_items[ 3 ] = { -1, ... };

		if ( ! p_BobbyPins[ victimid ] || p_BobbyPins[ playerid ] >= GetShopItemLimit( SHOP_ITEM_BOBBY_PIN ) ) available_items[ 0 ] = 0;
		if ( ! p_Scissors[ victimid ] || p_Scissors[ playerid ] >= GetShopItemLimit( SHOP_ITEM_SCISSOR ) ) available_items[ 1 ] = 1;
		if ( ! p_Ropes[ victimid ] || p_Ropes[ playerid ] >= GetShopItemLimit( SHOP_ITEM_ROPES ) ) available_items[ 2 ] = 2;

		if ( available_items[ 0 ] != -1 && available_items[ 1 ] != -1 && available_items[ 2 ] != -1 ) {
			SendClientMessageFormatted( victimid, -1, ""COL_GREEN"[抢劫失败]{FFFFFF} %s(%d) 未能从你身上抢走物品.", ReturnPlayerName( playerid ), playerid );
		    SendClientMessageFormatted( playerid, -1, ""COL_RED"[抢劫失败]{FFFFFF} 你在 %s(%d) 的口袋里没有发现任何东西,他在彻底检查后注意到了你.", ReturnPlayerName( victimid ), victimid );
		    return 1;
		}

		new
			iRandomItem = randomExcept( available_items, sizeof( available_items ) );

		switch( iRandomItem )
		{
			case 0: // Pins
			{
				p_BobbyPins[ victimid ] --, p_BobbyPins[ playerid ] ++;
				SendClientMessageFormatted( victimid, -1, ""COL_RED"[抢劫]{FFFFFF} %s(%d) 掐掉了你的发夹!", ReturnPlayerName( playerid ), playerid );
			    SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[抢劫]{FFFFFF} 你把 %s(%d) 的发夹夹断了!", ReturnPlayerName( victimid ), victimid );
			}
			case 1: // Scissors
			{
				p_Scissors[ victimid ] --, p_Scissors[ playerid ] ++;
				SendClientMessageFormatted( victimid, -1, ""COL_RED"[抢劫]{FFFFFF} %s(%d) 从你身上夺走了一把剪刀!", ReturnPlayerName( playerid ), playerid );
			    SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[抢劫]{FFFFFF} 你从 %s(%d) 上剪下了一把剪刀!", ReturnPlayerName( victimid ), victimid );
			}
			case 2: // Ropes
			{
				p_Ropes[ victimid ] --, p_Ropes[ playerid ] ++;
				SendClientMessageFormatted( victimid, -1, ""COL_RED"[抢劫]{FFFFFF} %s(%d) 从你身上掐断了一根绳子!", ReturnPlayerName( playerid ), playerid );
			    SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[抢劫]{FFFFFF} 你从 %s(%d) 上掐断了一根绳子!", ReturnPlayerName( victimid ), victimid );
			}
		}
 	}
    else SendError( playerid, "周围没有玩家可以抢劫." );
	return 1;
}

/*CMD:policetutorial( playerid, params[ ] )
{
	if ( p_CopTutorial{ playerid } == 0 ) return SendError( playerid, "You have already enabled the law enforcement officer tutorial." );
  	ShowPlayerDialog( playerid, DIALOG_VIEW_LEO_TUT, DIALOG_STYLE_MSGBOX, "{FFFFFF}Law Enforcement Officer Tutorial", "{FFFFFF}Are you sure you would like to view the law enforcement officer tutorial again?", "Yes", "No" );
	return 1;
}*/

CMD:ransompay( playerid, params[ ] )
{
	if ( !IsPlayerConnected( p_RansomPlacer[ playerid ] ) ) return SendError( playerid, "你的赎金提供者已不再连接." );
	else if ( !IsPlayerTied( playerid ) ) return p_RansomPlacer[ playerid ] = INVALID_PLAYER_ID, SendError( playerid, "只有被几十名玩家可以使用此命令." );
	else if ( GetPlayerCash( playerid ) < p_RansomAmount[ playerid ] ) return SendError( playerid, "你没有足够的钱支付赎金." );
	else if ( IsPlayerSettingToggled( playerid, SETTING_RANSOMS ) ) return SendError( playerid, "由于你已禁用赎金提议,因此此功能不可用." );
	else
	{
		TogglePlayerControllable( playerid, 1 );
		p_Tied{ playerid } = false;
	   	if ( IsPlayerKidnapped( playerid ) ) {
	     	p_Kidnapped{ playerid } = false;
	 	}
		Delete3DTextLabel( p_TiedLabel[ playerid ] );
		p_TiedLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
		GivePlayerCash( playerid, -p_RansomAmount[ playerid ] );
		GivePlayerCash( p_RansomPlacer[ playerid ], p_RansomAmount[ playerid ] );
		SendClientMessageFormatted( p_RansomPlacer[ playerid ], -1, ""COL_GREEN"[支付赎金]{FFFFFF} %s(%d) 已支付赎金 ("COL_GOLD"%s"COL_WHITE").", ReturnPlayerName( playerid ), playerid, cash_format( p_RansomAmount[ playerid ] ) );
		SendClientMessageFormatted( playerid, -1, ""COL_RED"[支付赎金]{FFFFFF} 你已支付赎金 ("COL_GOLD"%s"COL_WHITE"),你现在已被释放.", cash_format( p_RansomAmount[ playerid ] ) );
		Beep( p_RansomPlacer[ playerid ] );
		GivePlayerWantedLevel( p_RansomPlacer[ playerid ], 6 );
		p_RansomAmount[ playerid ] = 0;
		p_RansomPlacer[ playerid ] = INVALID_PLAYER_ID;
		p_KidnapImmunity[ playerid ] = g_iTime + 180;
	}
	return 1;
}

CMD:rans( playerid, params[ ] ) return cmd_ransom( playerid, params );
CMD:ransom( playerid, params[ ] )
{
	new victimid, amount;

	if ( sscanf( params, "ud", victimid, amount ) ) return SendUsage( playerid, "/ransom [PLAYER_ID] [AMOUNT]" );
	else if ( !IsPlayerConnected( victimid ) ) return SendError( playerid, "此玩家不在线." );
	else if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "在监狱中无法使用此命令." );
	else if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "此功能仅限平民使用." );
	else if ( !IsPlayerJob( playerid, JOB_KIDNAPPER ) ) return SendError( playerid, "你必须是绑匪才能使用此命令." );
    else if ( p_Spectating{ playerid } ) return SendError( playerid, "旁观时无法使用此类命令." );
	else if ( victimid == playerid ) return SendError( playerid, "你不能为自己创建赎金." );
	else if ( IsPlayerSettingToggled( victimid, SETTING_RANSOMS ) ) return SendError( playerid, "该玩家已禁用赎金提议." );
	else if ( amount < 50 || amount > 20000 ) return SendError( playerid, "你可以支付从 $50 到 $20,000. 的赎金" );
	else if ( amount > 99999999 || amount < 0 ) return SendError( playerid, "你可以支付从 $50 到 $20,000. 的赎金"); // Making cash go over billions...
	else if ( amount > GetPlayerCash( victimid ) ) return SendError( playerid, "此人没有足够的钱来支付这笔金额." );
	else if ( p_RansomTimestamp[ victimid ] > g_iTime ) return SendError( playerid, "在向此人提供赎金之前,你必须等待 %d 秒.", p_RansomTimestamp[ victimid ] - g_iTime );
 	else if ( GetDistanceBetweenPlayers( playerid, victimid ) < 4.0 && IsPlayerConnected( victimid ) )
 	{
		if ( IsPlayerTied( playerid ) ) return SendError( playerid, "被捆绑时无法使用此命令." );
		if ( !IsPlayerTied( victimid ) ) return SendError( playerid, "该玩家必须被绑才能创造赎金." );
		if ( IsPlayerCuffed( playerid ) ) return SendError( playerid, "当你被铐住时,你无法使用此命令." );
		if ( IsPlayerTazed( playerid ) ) return SendError( playerid, "当你被电击打印机时,你无法使用此命令." );
		if ( IsPlayerInPaintBall( playerid ) ) return SendError( playerid, "由于你位于竞技场内,因此你无法使用此命令." );

		SendClientMessageFormatted( victimid, -1, ""COL_RED"[赎金]{FFFFFF} 已向你提供赎金 "COL_GOLD"%s"COL_WHITE" 等你释放.使用 /ransompay 支付赎金.", cash_format( amount ) );
	    SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[赎金]{FFFFFF} 你已向 %s(%d) 提供赎金 "COL_GOLD"%s"COL_WHITE".", ReturnPlayerName( victimid ), victimid, cash_format( amount ) );
		p_RansomAmount[ victimid ] = amount;
		p_RansomPlacer[ victimid ] = playerid;
		p_RansomTimestamp[ victimid ] = g_iTime + 15;
	}
	else return SendError( playerid, "该玩家不在附近." );
	return 1;
}

CMD:cw( playerid, params[ ] ) return cmd_carwhisper( playerid, params );
CMD:carwhisper( playerid, params[ ] )
{
	new msg[ 100 ];
	if ( p_ChatBanned{ playerid } ) return SendError( playerid, "你已被封禁聊天,并且不允许聊天." );
	else if ( !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "你必须在车内才能使用此命令." );
	else if ( sscanf( params, "s[100]", msg ) ) return SendUsage( playerid, "/carwhisper [MESSAGE]" );
	else if ( textContainsIP( msg ) ) return SendError( playerid, "禁止做广告." );
	else
	{
		foreach(new i : Player)
		{
		    if ( GetPlayerVehicleID( i ) == GetPlayerVehicleID( playerid ) ) {
		        SendClientMessageFormatted( i, -1, ""COL_ORANGE"<汽车低语> %s(%d):"COL_WHITE" %s", ReturnPlayerName( playerid ), playerid, msg );
		    }
		}
	}
	return 1;
}

CMD:w( playerid, params[ ] ) return cmd_whisper( playerid, params );
CMD:whisper( playerid, params[ ] )
{
	new msg[ 100 ];
	if ( p_ChatBanned{ playerid } ) return SendError( playerid, "你已被封禁聊天,并且不允许聊天." );
	else if ( sscanf( params, "s[100]", msg ) ) return SendUsage( playerid, "/whisper [MESSAGE]" );
	else if ( textContainsIP( msg ) ) return SendError( playerid, "禁止做广告." );
	else
	{
		new Float: X, Float: Y, Float: Z;
		GetPlayerPos( playerid, X, Y, Z );
		foreach(new i : Player)
		{
		    if ( IsPlayerInRangeOfPoint( i, 5.0, X, Y, Z ) && GetPlayerVirtualWorld( i ) == GetPlayerVirtualWorld( playerid ) ) {
		        SendClientMessageFormatted( i, -1, ""COL_ORANGE"<耳语> %s(%d):"COL_WHITE" %s", ReturnPlayerName( playerid ), playerid, msg );
		    }
		}
	}
	return 1;
}

CMD:admins( playerid, params[ ] )
{
	if ( GetPlayerScore( playerid ) < 50 && !IsPlayerUnderCover( playerid ) && p_AdminLevel[ playerid ] < 1 )
	    return SendError( playerid, "你至少需要 50 分数 才能查看在线管理员." );

	new g_adminList[ MAX_PLAYERS ] [ 2 ], bool: is_empty = true;

	// store cash and playerid
	foreach ( new player : Player ) {
		g_adminList[ player ] [ 0 ] = player;
		g_adminList[ player ] [ 1 ] = p_AdminLevel[ player ];
	}

	// sort
	SortDeepArray( g_adminList, 1, .order = SORT_DESC );

	// message
	szLargeString = ""COL_WHITE"玩家\t"COL_WHITE"管理员级别\n";
	for ( new i = 0; i < MAX_PLAYERS; i ++ ) if ( IsPlayerConnected( g_adminList[ i ] [ 0 ] ) && g_adminList[ i ] [ 1 ] > 0 ) {
        format( szLargeString, sizeof( szLargeString ), "%s%s%s(%d)\t级别 %d\n", szLargeString, IsPlayerAdminOnDuty( g_adminList[ i ] [ 0 ] ) ? ( COL_PINK ) : ( COL_GREY ), ReturnPlayerName( g_adminList[ i ] [ 0 ] ), g_adminList[ i ] [ 0 ], g_adminList[ i ] [ 1 ] );
		is_empty = false;
	}

	if ( is_empty ) {
		return SendError( playerid, "没有在线管理员." );
	} else {
		return ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}在线管理员", szLargeString, "关闭", "" ), 1;
	}
}

CMD:vsay( playerid, params[ ] )
{
    new
    	msg[ 100 ],
    	time = g_iTime
    ;

    if ( p_VIPLevel[ playerid ] < 1 ) return SendError( playerid, "你还不是 VIP, 请前往以下地址开通: "COL_GREY"donate.sfcnr.com" );
	else if ( IsPlayerChatBanned( playerid ) ) return SendError( playerid, "你已被封禁聊天,并且不允许聊天." );
    else if ( sscanf( params, "s[100]", msg ) ) return SendUsage( playerid, "/vsay [MESSAGE]" );
	else if ( textContainsIP( msg ) ) return SendServerMessage( playerid, "请不要做广告." );
    else
    {
     	if ( p_Muted{ playerid } )
		{
		 	if ( time > p_MutedTime[ playerid ] )
			 	p_Muted{ playerid } = false;
			else
                return SendError( playerid, "你无法说话,因为你已被静音 %s.", secondstotime( p_MutedTime[ playerid ] - time ) );
		}

		DCC_SendChannelMessageFormatted( discordChatChan, "**[%s] (VIP) %s(%d):** %s", getCurrentTime(), ReturnPlayerName( playerid ), playerid, msg );
		SendClientMessageToAllFormatted( 0x3eff3eff, "[VIP] %s(%d):{9ec34f} %s", ReturnPlayerName( playerid ), playerid, msg );
	}
	return 1;
}


CMD:aclist( playerid, params[ ] )
{
	new
		count = 0;

	szLargeString = ""COL_WHITE"橙色玩家被迫使用SA-MP AC\n";

	foreach(new i : Player) if ( IsPlayerUsingSampAC( i ) ) {
		format( szLargeString, sizeof( szLargeString ), "%s%s%s(%d)\n", szLargeString, p_forcedAnticheat[ i ] > 0 ? ( COL_ORANGE ) : ( "" ), ReturnPlayerName( i ), i );
	    count++;
	}
    if ( count == 0 ) return SendError( playerid, "没有 SA-MP AC 用户在线." );
    if ( strlen( szLargeString ) == sizeof( szLargeString ) - 1 ) return ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "{FFFFFF}在线 SA-MP AC 用户", sprintf( ""COL_WHITE"有 %d SA-MP AC 用户在线.", count ), "确定", "" );
	ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}在线 SA-MP AC 用户", szLargeString, "确定", "" );
	return 1;
}

CMD:viplist( playerid, params[ ] )
{
	new
		count = 0;

	szLargeString = ""COL_WHITE"玩家\t"COL_WHITE"VIP 包裹\n";

	foreach(new i : Player) if ( p_VIPLevel[ i ] > 0 )
	{
	    format( szLargeString, sizeof( szLargeString ), "%s%s(%d)\t%s%s\n", szLargeString, ReturnPlayerName( i ), i, VIPToColor( p_VIPLevel[ i ] ), VIPToString( p_VIPLevel[ i ] ) );
	    count++;
	}
    if ( count == 0 ) return SendError( playerid, "当前没有在线的 VIP 玩家." );
    if ( strlen( szLargeString ) == sizeof( szLargeString ) - 1 ) return ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "{FFFFFF}在线 VIP 玩家", sprintf( ""COL_WHITE"有 %d VIP 名玩家在线.", count ), "确定", "" );
	ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}在线 VIP 玩家", szLargeString, "确定", "" );
	return 1;
}


CMD:vipspawnwep( playerid, params[ ] )
{
	if ( p_VIPLevel[ playerid ] < VIP_REGULAR ) return SendError( playerid, "你还不是 VIP, 请前往以下地址开通: "COL_GREY"donate.sfcnr.com" );
	format( szNormalString, sizeof( szNormalString ), "%s\n"COL_GOLD"%s\n"COL_PLATINUM"%s", p_VIPWep1{ playerid } ? ReturnWeaponName( p_VIPWep1{ playerid } ) : ( "没有什么" ), p_VIPWep2{ playerid } ? ReturnWeaponName( p_VIPWep2{ playerid } ) : ( "没有什么" ), p_VIPWep3{ playerid } ? ReturnWeaponName( p_VIPWep3{ playerid } ) : ( "没有什么" ) );
    ShowPlayerDialog( playerid, DIALOG_VIP_WEP, DIALOG_STYLE_LIST, "{FFFFFF}生成武器", szNormalString, "选择", "" );
	return 1;
}

CMD:vipgun( playerid, params[ ] )
{
	if ( p_VIPLevel[ playerid ] < VIP_REGULAR )
	    return SendError( playerid, "你还不是 VIP, 请前往以下地址开通: "COL_GREY"donate.sfcnr.com" );

	if ( !IsPlayerInRangeOfPoint( playerid, 5.0, -1966.1591, 852.7100, 1214.2678 ) && !IsPlayerInRangeOfPoint( playerid, 5.0, -1944.1324, 830.0725, 1214.2678 ) && !IsPlayerInRangeOfPoint( playerid, 5.0, 60.3115, 121.5226, 1017.4534 ) )
		return SendError( playerid, "你必须靠近 VIP 休息室内的枪支自动售货机才能使用此功能." );

    ShowPlayerDialog( playerid, DIALOG_VIP_LOCKER, DIALOG_STYLE_LIST, "{FFFFFF}VIP 枪", ""COL_GREY" 装甲\n9毫米手枪\n消音手枪\n沙漠之鹰\n霰弹枪\n锯短霰弹枪\nSpas 12\nMac 10\nMP5\nAK-47\nM4\nTec 9\n步枪\n狙击枪\n指虎\n高尔夫球杆\n警棍\n棒球棒\n铁铲\n台球杆\n武士刀\n电锯\n假阳具\n花\n手杖", "选择", "取消");
	return 1;
}

CMD:vipskin( playerid, params[ ] )
{
	new
	    skin
	;
	if ( p_VIPLevel[ playerid ] < VIP_REGULAR ) return SendError( playerid, "你还不是 VIP, 请前往以下地址开通: "COL_GREY"donate.sfcnr.com" );
	else if ( GetPlayerAnimationIndex( playerid ) == 1660 ) return SendError( playerid, "使用售货机时无法使用此命令." );
	else if ( IsPlayerRobbing( playerid ) ) return SendError( playerid, "你无法使用此命令,因为你正在抢劫商店." );
	/*else if ( strmatch( params, "toggle" ) )
	{
		if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You cannot use this in a vehicle. Exit it, and try again." );
	    if ( GetPlayerState( playerid ) == PLAYER_STATE_ENTER_VEHICLE_DRIVER || GetPlayerState( playerid ) == PLAYER_STATE_ENTER_VEHICLE_PASSENGER ) return SendError( playerid, "You cannot set your skin if you're entering a vehicle." );
	    if ( GetPlayerState( playerid ) == PLAYER_STATE_EXIT_VEHICLE ) return SendError( playerid, "You cannot set your skin if you're exiting a vehicle." );
		p_SkinToggled{ playerid } = true;
		Streamer_Update( playerid ); // SyncObject( playerid );
		ClearAnimations( playerid );
		SetPlayerSkin( playerid, p_LastSkin[ playerid ] );
		SendServerMessage( playerid, "You have toggled your V.I.P skin!" );
		return 1;
	}
	else if ( strmatch( params, "remove" ) )
	{
		p_SkinToggled{ playerid } = false;
		SendServerMessage( playerid, "Your V.I.P skin has been removed, changes will take place after your next spawn." );
		return 1;
	}*/
	else if ( sscanf( params, "d", skin ) ) return SendUsage( playerid, "/vipskin [SKIN_ID]" );
	else if ( !IsValidSkin( skin ) ) return SendError( playerid, "皮肤 ID 无效." );
	else
	{
	    p_LastSkin[ playerid ] = skin;
	    if ( IsPlayerSettingToggled( playerid, SETTING_VIPSKIN ) ) SetPlayerSkin( playerid, skin );
	    SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[VIP]"COL_WHITE" 你已将 VIP 皮肤 ID 更改为 %d!", skin );
	}
	return 1;
}

CMD:vipjob( playerid, params[ ] )
{
	new
	    iJob;

	if ( p_VIPLevel[ playerid ] < VIP_REGULAR )
		return SendError( playerid, "你还不是 VIP, 请前往以下地址开通: "COL_GREY"donate.sfcnr.com" );

	if ( p_VIPLevel[ playerid ] < VIP_PLATINUM )
		return SendError( playerid, "此命令要求你是白金级 VIP." );

	if ( isnull( params ) )
		return SendUsage( playerid, "/vipjob [PART OF JOB NAME]" );

	if ( ( iJob = GetJobIDFromName( params ) ) == 0xFE || iJob < 0 || iJob > 7 )
		return SendError( playerid, "你输入的职位无效." );

	if ( iJob != p_Job{ playerid } ) {
		if ( GetPlayerCash( playerid ) < 5000 )
			return SendError( playerid, "你没有足够的钱来安排你的 VIP 工作." );

		GivePlayerCash( playerid, -5000 );
        SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[VIP]"COL_WHITE" 你已将 VIP 工作更改为 %s!要禁用,请将你的 VIP 工作设置为你的原始工作.", GetJobName( iJob ) );
	}
	else SendClientMessage( playerid, -1, ""COL_GOLD"[VIP]"COL_WHITE" 你已禁用你的 VIP 工作." );

    p_VIPJob{ playerid } = iJob;
	return 1;
}

CMD:mechanic( playerid, params[ ] ) return cmd_mech( playerid, params );
CMD:mech( playerid, params[ ] )
{
	new
		Float: vZ,
		iVehicle = GetPlayerVehicleID( playerid )
	;

	if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "你必须是平民才能使用此命令." );
	else if ( !IsPlayerJob( playerid, JOB_DIRTY_MECHANIC ) ) return SendError( playerid, "你不是一个肮脏的机械师." );
	else if ( IsPlayerBelowSeaLevel( playerid ) ) return SendError( playerid, "当低于海平面时,你无法使用此命令." );
	else if ( IsPlayerInBattleRoyale( playerid ) ) return SendError( playerid, "大逃杀中无法使用此命令." );
	else if ( isnull( params ) ) return SendUsage( playerid, "/(mech)anic [FIX/NOS/REMP/FLIP/FLIX/PRICE/NEARBY]" );
	else if ( strmatch( params, "fix" ) )
	{
	    if ( p_AntiMechFixSpam[ playerid ] > g_iTime )
            return SendError( playerid, "你必须等待 %d 秒才能再次使用此功能.", p_AntiMechFixSpam[ playerid ] - g_iTime );

   		if ( !IsPlayerInAnyVehicle( playerid ) )
            return SendError( playerid, "你不在任何车辆中." );

		new
			cost = 250;

		if ( g_isBusinessVehicle[ iVehicle ] != -1 && Iter_Contains( business, g_isBusinessVehicle[ iVehicle ] ) ) {
			cost = IsBusinessAerialVehicle( g_isBusinessVehicle[ iVehicle ], GetVehicleModel( iVehicle ) ) ? 5000 : 2500;
		}

   		if ( GetPlayerCash( playerid ) < cost ) {
            return SendError( playerid, "你需要 %s 来修理这辆车.", cash_format( cost ) );
   		}

		PlayerPlaySound( playerid, 1133, 0.0, 0.0, 5.0 );
	 	RepairVehicle( iVehicle );
        SendServerMessage( playerid, "你已经修理了这辆车." );
	 	p_AntiMechFixSpam[ playerid ] = g_iTime + 10;
	 	GivePlayerCash( playerid, -cost );
	}
	else if ( strmatch( params, "nos" ) )
	{
	    if ( ( GetTickCount( ) - p_AntiMechNosSpam[ playerid ] ) < 10000 ) return SendError( playerid, "使用此功能之前,你必须等待 10 秒." );
        if ( !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "你不在任何车辆中." );
        if ( GetPlayerCash( playerid ) < 500 ) return SendError( playerid, "你需要 $500 向该车辆添加氮气." );
		PlayerPlaySound( playerid, 1133, 0.0, 0.0, 5.0 );
	  	AddVehicleComponent( iVehicle, 1010 );
        SendServerMessage( playerid, "你已向该车辆添加了氮气." );
	 	p_AntiMechNosSpam[ playerid ] = GetTickCount( );
	 	GivePlayerCash( playerid, -500 );
	}
	else if ( strmatch( params, "remp" ) )
	{
	    if ( ( GetTickCount( ) - p_AntiMechEmpSpam[ playerid ] ) < 10000 ) return SendError( playerid, "使用此功能之前,你必须等待 10 秒." );
        if ( !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "你不在任何车辆中." );
		if ( GetPlayerCash( playerid ) < 750 ) return SendError( playerid, "你需要 $750 才能从这辆车上移除电磁脉冲." );
		GetVehicleParamsEx( iVehicle, engine, lights, alarm, doors, bonnet, boot, objective );
		if ( engine != VEHICLE_PARAMS_OFF ) return SendError( playerid, "此载具未受电磁脉冲影响." );
		GivePlayerCash( playerid, -750 );
		PlayerPlaySound( playerid, 1133, 0.0, 0.0, 5.0 );
		SetVehicleParamsEx( iVehicle, VEHICLE_PARAMS_ON, lights, alarm, doors, bonnet, boot, objective );
        SendServerMessage( playerid, "你成功重启了载具." );
	 	p_AntiMechEmpSpam[ playerid ] = GetTickCount( );
	}
	else if ( strmatch( params, "flip" ) )
	{
	    if ( p_AntiMechFlipSpam[ playerid ] > g_iTime ) return SendError( playerid, "使用此功能之前,你必须等待 %d 秒.", p_AntiMechFlipSpam[ playerid ] - g_iTime );
        if ( !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "你不在任何车辆中." );
		if ( GetPlayerCash( playerid ) < 200 ) return SendError( playerid, "你需要 $200 来翻转这辆车." );
		PlayerPlaySound( playerid, 1133, 0.0, 0.0, 5.0 );
		GetVehicleZAngle( iVehicle, vZ ), SetVehicleZAngle( iVehicle, vZ );
		GivePlayerCash( playerid, -200 );
        SendServerMessage( playerid, "你已成功翻转这辆车." );
	 	p_AntiMechFlipSpam[ playerid ] = g_iTime + 5;
	}
	else if ( strmatch( params, "flix" ) )
	{
	    if ( p_AntiMechFixSpam[ playerid ] > g_iTime ) return SendError( playerid, "你必须等待 %d 秒才能再次使用此功能.", p_AntiMechFixSpam[ playerid ] - g_iTime );
	    if ( p_AntiMechFlipSpam[ playerid ] > g_iTime ) return SendError( playerid, "使用此功能之前,你必须等待 %d 秒.", p_AntiMechFlipSpam[ playerid ] - g_iTime );
        if ( !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "你不在任何车辆中." );
        if ( GetPlayerCash( playerid ) < 500 ) return SendError( playerid, "你需要 $500 来翻转并修理这辆车." );

		new
			cost = 500;

		if ( g_isBusinessVehicle[ iVehicle ] != -1 && Iter_Contains( business, g_isBusinessVehicle[ iVehicle ] ) ) {
			cost = IsBusinessAerialVehicle( g_isBusinessVehicle[ iVehicle ], GetVehicleModel( iVehicle ) ) ? 6000 : 3500;
		}

   		if ( GetPlayerCash( playerid ) < cost ) {
            return SendError( playerid, "你需要 %s 来修理这辆车.", cash_format( cost ) );
   		}

		PlayerPlaySound( playerid, 1133, 0.0, 0.0, 5.0 );
	 	RepairVehicle( iVehicle );
		GetVehicleZAngle( iVehicle, vZ ), SetVehicleZAngle( iVehicle, vZ );
        SendServerMessage( playerid, "你已经翻转并修复了这辆车." );
	 	p_AntiMechFixSpam[ playerid ] = g_iTime + 10;
	 	p_AntiMechFlipSpam[ playerid ] =  g_iTime + 5;
	 	GivePlayerCash( playerid, -cost );
	}
	else if ( strmatch( params, "price" ) )
	{
        if ( !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "你不在任何车辆中." );

   		new
   			iPrice;

   		if ( ( iPrice = calculateVehicleSellPrice( iVehicle ) ) )
			ShowPlayerHelpDialog( playerid, 3000, "在码头出口此载具可获得约 ~g~%s~w~~h~.~n~~n~~r~载具受损会降低售价.", cash_format( iPrice ) );
   		else
			ShowPlayerHelpDialog( playerid, 3000, "~r~此车辆无法出售." );
	}
	else if ( strmatch( params, "nearby" ) )
	{
		new
			Float: fDistance = Float: 0x7F800000,
			iClosest = GetClosestVehicle( playerid, INVALID_VEHICLE_ID, fDistance )
		;

		SendServerMessage( playerid, "离你最近的车辆是一辆 "COL_GREY"%s"COL_WHITE",距离 %0.2fm.", GetVehicleName( GetVehicleModel( iClosest ) ), fDistance );
	}
	else return SendUsage( playerid, "/(mech)anic [FIX/NOS/REMP/FLIP/FLIX/PRICE/NEARBY]" );
	return 1;
}

CMD:savestats( playerid, params[ ] )
{
	if ( ( GetTickCount( ) - p_AntiSaveStatsSpam[ playerid ] ) < 15000 ) return SendError( playerid, "你必须等待 15 秒才能再次保存统计数据." );
    SavePlayerData( playerid );
    p_AntiSaveStatsSpam[ playerid ] = GetTickCount( );
    SendServerMessage( playerid, "你的统计数据已保存." );
	return 1;
}

CMD:ask( playerid, params[ ] )
{
    new szMessage[ 96 ];
    if ( sscanf( params, "s[96]", szMessage ) ) return SendUsage( playerid, "/ask [QUESTION]" );
    else if ( p_CantUseAsk{ playerid } == true ) return SendError( playerid, "管理员已阻止你使用此命令." );
    else
	{
		for( new iPos; iPos < sizeof( szQuestionsLog ) - 1; iPos++ )
			memcpy( szQuestionsLog[ iPos ], szQuestionsLog[ iPos + 1 ], 0, sizeof( szQuestionsLog[ ] ) * 4 );

		format( szNormalString, sizeof( szNormalString ), "%s\t%s(%d)\t%s\n", getCurrentTime( ), ReturnPlayerName( playerid ), playerid, szMessage );
		strcpy( szQuestionsLog[ 7 ], szNormalString );

		Beep( playerid );
        SendClientMessageToAdmins( -1, "{FE5700}[QUESTION] %s(%d):{FFFFFF} %s", ReturnPlayerName( playerid ), playerid, szMessage );
		SendClientMessageFormatted( playerid, -1, "{FE5700}[提问]"COL_WHITE" 你已问\"%s\".", szMessage );
		DCC_SendChannelMessageFormatted( discordAskChan, "**[提问]** __**%s(%d)**__: %s", ReturnPlayerName( playerid ), playerid, szMessage );
	}
	return 1;
}

CMD:ach( playerid, params[ ] ) return cmd_achievements( playerid, params );
CMD:achievements( playerid, params[ ] )
{
	displayAchievements( playerid );
	return 1;
}

CMD:idof( playerid, params[ ] )
{
	new pID;
	if ( sscanf( params, "u", pID ) ) return SendUsage( playerid, "/idof [PART_OF_NAME]" );
	if ( !IsPlayerConnected( pID ) ) return SendError( playerid, "该玩家不在线." );
	SendServerMessage( playerid, "%s: "COL_GREY"%d", ReturnPlayerName( pID ), pID );
	return 1;
}

CMD:playercolor( playerid, params[ ] ) return cmd_pc( playerid, params );
CMD:pc( playerid, params[ ] )
{
    ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_LIST, "{FFFFFF}玩家颜色", "无辜\n{FFEC41}低嫌疑\n"COL_ORANGE"通缉\n{F83245}头号通缉\n{3E7EFF}警察\n{0035FF}F.B.I\n{191970}C.I.A\n{954BFF}军队\n"COL_PINK"管理员值班\n"COL_GREY"其他颜色均为帮派颜色", "确定", "" );
	return 1;
}

CMD:robstore( playerid, params[ ] )
{
	SendServerMessage( playerid, "此命令会绑定你的行走钥匙,因此你必须处于抢劫检查站才能获得响应!" );
	CallLocalFunction( "OnPlayerKeyStateChange", "ddd", playerid, KEY_WALK, KEY_SPRINT );
	return 1;
}

CMD:myaccid( playerid, params[ ] )
{
    SendServerMessage( playerid, "你的帐户 ID 是 "COL_GOLD"%d"COL_WHITE".", p_AccountID[ playerid ] );
	return 1;
}

CMD:discord( playerid, params[ ] )
{
	return SendServerMessage( playerid, "访问\"sfcnr.com/discord\"加入我们的 Discord 服务器!" );
}

CMD:job( playerid, params[ ] )
{
    if ( p_VIPLevel[ playerid ] >= VIP_PLATINUM && p_VIPJob{ playerid } != p_Job{ playerid } )
        return SendServerMessage( playerid, "你的工作是 "COL_GOLD"%s"COL_WHITE" 和 "COL_GOLD"%s"COL_WHITE".", GetJobName( p_Job{ playerid } ), GetJobName( p_VIPJob{ playerid } ) );

    if ( p_VIPLevel[ playerid ] >= VIP_PLATINUM && p_VIPJob{ playerid } == p_Job{ playerid } )
        return SendServerMessage( playerid, "你的工作是 "COL_GOLD"%s"COL_WHITE" 并且你的 VIP 工作已被禁用.", GetJobName( p_Job{ playerid } ) );

    SendServerMessage( playerid, "你的工作是 "COL_GOLD"%s"COL_WHITE".", GetJobName( p_Job{ playerid } ) );
	return 1;
}

CMD:jaillist( playerid, params[ ] )
{
	szBigString[ 0 ] = '\0';

    foreach( new i : Player ) if ( IsPlayerJailed( i ) ) {
        format( szBigString, sizeof( szBigString ), "%s%s%s(%d)\t%d 秒\n", szBigString, p_AdminJailed{ i } ? ( COL_RED ) : ( COL_WHITE ), ReturnPlayerName( i ), i, p_JailTime[ i ] );
    }

    if ( szBigString[ 0 ] == '\0' )   {
        return SendError( playerid, "监狱里没有玩家." );
    } else {
        return ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST, ""COL_WHITE"监狱名单", szBigString, "关闭", "" );
    }
}

CMD:lastlogged( playerid, params[ ] )
{
	static
	    player[ MAX_PLAYER_NAME ]
	;

	if ( sscanf( params, "s[24]", player ) ) return SendUsage( playerid, "/lastlogged [PLAYER_NAME]" );
	else
	{
		format( szNormalString, sizeof( szNormalString ), "SELECT `LASTLOGGED` FROM `USERS` WHERE `NAME` = '%s' LIMIT 0,1", mysql_escape( player ) );
  		mysql_function_query( dbHandle, szNormalString, true, "OnPlayerLastLogged", "iis", playerid, 0, player );
	}
	return 1;
}

thread OnPlayerLastLogged( playerid, irc, player[ ] )
{
	new
	    rows, fields, time, Field[ 50 ]
	;
    cache_get_data( rows, fields );
	if ( rows )
	{
		cache_get_field_content( 0, "LASTLOGGED", Field );

		time = g_iTime - strval( Field );
		if ( time > 86400 )
		{
		    time /= 86400;
		    format( Field, sizeof( Field ), "%d 天前.", time );
		}
		else if ( time > 3600 )
		{
		    time /= 3600;
		    format( Field, sizeof( Field ), "%d 小时前.", time );
		}
		else
		{
		    time /= 60;
		    format( Field, sizeof( Field ), "%d 分钟前.", time );
		}

		if ( !irc ) SendClientMessageFormatted( playerid, COLOR_GREY, "[服务器]"COL_RED" %s:"COL_WHITE" 最后登录:%s", player, Field );
	}
	else {
		if ( !irc ) SendError( playerid, "未找到玩家." );
	}
	return 1;
}

CMD:weeklytime( playerid, params[ ] )
{
	static
	    player[ MAX_PLAYER_NAME ]
	;

	if ( sscanf( params, "s[24]", player ) ) return SendUsage( playerid, "/weeklytime [PLAYER_NAME]" );
	else
	{
		format( szNormalString, sizeof( szNormalString ), "SELECT `UPTIME`,`WEEKEND_UPTIME` FROM `USERS` WHERE `NAME` = '%s' LIMIT 0,1", mysql_escape( player ) );
  		mysql_function_query( dbHandle, szNormalString, true, "OnPlayerWeeklyTime", "iis", playerid, 0, player );
	}
	return 1;
}

thread OnPlayerWeeklyTime( playerid, irc, player[ ] )
{
	new
	    rows, fields,
	    iCurrentUptime, iLastUptime
	;
    cache_get_data( rows, fields );
	if ( rows )
	{
		iCurrentUptime 	= cache_get_field_content_int( 0, "UPTIME", dbHandle );
		iLastUptime 	= cache_get_field_content_int( 0, "WEEKEND_UPTIME", dbHandle );

		if ( !irc ) SendClientMessageFormatted( playerid, COLOR_GREY, "[服务器]"COL_GREY" %s:"COL_WHITE" %s", player, secondstotime( iCurrentUptime - iLastUptime ) );
	}
	else
	{
		if ( !irc )
			SendError( playerid, "未找到玩家." );
	}
	return 1;
}

public OnPlayerLoadTextdraws( playerid )
{
	PlayerTextDrawShow( playerid, p_LocationTD[ playerid ] );
	if ( IsDoubleXP( ) ) TextDrawShowForPlayer( playerid, g_DoubleXPTD );
	TextDrawShowForPlayer( playerid, g_WebsiteTD );
	if ( p_WantedLevel[ playerid ] ) PlayerTextDrawShow( playerid, p_WantedLevelTD[ playerid ] );
	TextDrawShowForPlayer( playerid, g_MotdTD );
	if ( p_AdminOnDuty{ playerid } ) TextDrawShowForPlayer( playerid, g_AdminOnDutyTD );
	PlayerTextDrawShow( playerid, g_ZoneOwnerTD[ playerid ] );
	return 1;
}

public OnPlayerUnloadTextdraws( playerid )
{
	PlayerTextDrawHide( playerid, g_ZoneOwnerTD[ playerid ] );
	PlayerTextDrawHide( playerid, p_LocationTD[ playerid ] );
	PlayerTextDrawHide( playerid, p_WantedLevelTD[ playerid ] );
	TextDrawHideForPlayer( playerid, g_WebsiteTD );
	TextDrawHideForPlayer( playerid, g_AdminOnDutyTD );
	TextDrawHideForPlayer( playerid, g_DoubleXPTD );
	TextDrawHideForPlayer( playerid, g_MotdTD );
	return 1;
}

CMD:hidelabel( playerid, params[ ] ) return cmd_rlabel( playerid, params );
CMD:rlabel( playerid, params[ ] )
{
	if ( p_InfoLabel[ playerid ] == Text3D: INVALID_3DTEXT_ID )
		return SendError( playerid, "你头上没有任何需要去除的标签." );

	p_LabelColor[ playerid ] = COLOR_GREY;
	Delete3DTextLabel( p_InfoLabel[ playerid ] );
	p_InfoLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	SendServerMessage( playerid, "你已经从你的头上移除了你的标签." );
	return 1;
}

CMD:labelinfo( playerid, params[ ] )
{
    if ( p_InfoLabel[ playerid ] != Text3D: INVALID_3DTEXT_ID )
    {
        SendServerMessage( playerid, "{%06x}%s", p_LabelColor[ playerid ] >>> 8, p_InfoLabelString[ playerid ] );
    }
    else SendError( playerid, "你身上没有贴上标签." );
	return 1;
}

CMD:label( playerid, params[ ] )
{
	new
		szLabel[ 32 ]
	;

	if ( GetPlayerScore( playerid ) < 500 ) return SendError( playerid, "你需要 500 分数 才能使用此命令." );
	else if ( sscanf( params, "s[32]", szLabel ) ) return SendUsage( playerid, "/label [MESSAGE]" );
	else
	{
	    Delete3DTextLabel( p_InfoLabel[ playerid ] );
	    format( p_InfoLabelString[ playerid ], sizeof( p_InfoLabelString[ ] ), "%s", szLabel );
		p_InfoLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	    p_InfoLabel[ playerid ] = Create3DTextLabel( szLabel, p_LabelColor[ playerid ], 0.0, 0.0, 0.0, 15.0, 0 );
	    Attach3DTextLabelToPlayer( p_InfoLabel[ playerid ], playerid, 0.0, 0.0, 0.4 );
	    SendServerMessage( playerid, "你在头顶放置了一个标签,其中包含上述文本." );
	}
	return 1;
}

CMD:labelcolor( playerid, params[ ] )
{
	new
		szLabel[ 7 ];
	
	if ( sscanf( params, "s[7]", szLabel ) ) return SendUsage( playerid, "/labelcolor [HEX CODE (= normal)]" );
	else if ( p_VIPLevel[ playerid ] < VIP_REGULAR ) return SendError( playerid, "你还不是 VIP, 请前往以下地址开通: "COL_GREY"donate.sfcnr.com" );
	else if ( strmatch( szLabel, "normal" ) )
	{
		p_LabelColor[ playerid ] = COLOR_GREY;
		Update3DTextLabelText( p_InfoLabel[ playerid ], COLOR_GREY, p_InfoLabelString[ playerid ] );
		return SendServerMessage( playerid, "你已成功重置标签的颜色." );
	}
	else if ( strlen( szLabel ) != 6 ) return SendError( playerid, "你的十六进制代码必须等于六个字符. "COL_ORANGE"格式:RRGGBB" );
	else if ( p_InfoLabel[ playerid ] == Text3D: INVALID_3DTEXT_ID ) return SendError( playerid, "你身上没有贴上标签." );
	else if ( strmatch( szLabel, "FF0770" ) ) return SendError( playerid, "这种颜色是严格禁止的,可能会导致禁止." );
	else if ( !isHex( szLabel ) ) return SendError( playerid, "无效的十六进制代码." );
	else
	{
		SendServerMessage( playerid, "你已将 {%s} 标签的颜色更改为此 {FFFFFF}.重置: "COL_GREY"/labelcolor normal"COL_WHITE".", szLabel );
		format( szNormalString, 11, "0x%sFF", szLabel );
		p_LabelColor[ playerid ] = HexToInt( szNormalString );
		Update3DTextLabelText( p_InfoLabel[ playerid ], p_LabelColor[ playerid ], p_InfoLabelString[ playerid ] );
	}
	return 1;
}

CMD:changepassword( playerid, params[ ] ) return cmd_changepw( playerid, params );
CMD:changepass( playerid, params[ ] ) return cmd_changepw( playerid, params );
CMD:changepw( playerid, params[ ] )
{
	static
		szHashed[ 129 ], szSalt[ 25 ];
		
	if ( p_accountSecurityData[ playerid ] [ E_ID ] && ! p_accountSecurityData[ playerid ] [ E_VERIFIED ] && p_accountSecurityData[ playerid ] [ E_MODE ] != SECURITY_MODE_DISABLED )
		return SendError( playerid, "使用此功能需要先验证账号. "COL_YELLOW"(输入 /verify)" );
	if ( !p_PlayerLogged{ playerid } ) return SendError( playerid, "你尚未登录." );
	if ( isnull( params ) ) return SendUsage( playerid, "/change(pw/pass/password) [PASSWORD]" );
	if ( strlen( params ) > 24 || strlen( params ) < 3 ) return SendError( playerid, "你的密码必须在 3 和 24 个字符内编制索引." );

 	randomString( szSalt, 24 );
 	pencrypt( szHashed, sizeof( szHashed ), params, szSalt );

	format( szBigString, sizeof( szBigString ), "UPDATE `USERS` SET `PASSWORD`='%s', `SALT`='%s' WHERE `ID`=%d", szHashed, mysql_escape( szSalt ), p_AccountID[ playerid ] );
	mysql_single_query( szBigString );

	GameTextForPlayer( playerid, "~r~密码已更改!", 5000, 3 );
	SendClientMessageFormatted( playerid, COLOR_GOLD, "[密码已更改]"COL_WHITE" 你已成功将密码更改为 \""COL_GREY"%s"COL_WHITE"\",一定要记住!", params );
	return 1;
}

CMD:richlist( playerid, params[ ] )
{
	new g_richList[ MAX_PLAYERS ] [ 2 ], bool: is_empty = true;

	// store cash and playerid
	foreach ( new player : Player ) {
		g_richList[ player ] [ 0 ] = player;
		g_richList[ player ] [ 1 ] = GetPlayerTotalCash( player );
	}

	// sort
	SortDeepArray( g_richList, 1, .order = SORT_DESC );

	// message
	szLargeString = ""COL_WHITE"玩家\t"COL_WHITE"持有金钱\t"COL_WHITE"银行资金\n";
	for ( new i = 0; i < MAX_PLAYERS; i ++ ) if ( IsPlayerConnected( g_richList[ i ] [ 0 ] ) && g_richList[ i ] [ 1 ] > 50000 )
	{
		new
			rich_player = g_richList[ i ] [ 0 ];

 		format( szLargeString, sizeof( szLargeString ), "%s%s(%d)\t"COL_GOLD"%s\t{666666}%s\n", szLargeString, ReturnPlayerName( rich_player ), rich_player, cash_format( GetPlayerCash( rich_player ) ), cash_format( GetPlayerBankMoney( rich_player ) ) );
		is_empty = false;
	}

	if ( is_empty ) {
		return SendError( playerid, "没有富有的玩家可以展示." );
	} else {
		return ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}富有的玩家在线", szLargeString, "关闭", "" ), 1;
	}
}

CMD:getwanted( playerid, params[ ] ) return cmd_mostwanted( playerid, params );
CMD:mostwanted( playerid, params[ ] )
{
	new g_wantedList[ MAX_PLAYERS ] [ 2 ], bool: is_empty = true;

	// store cash and playerid
	foreach ( new player : Player ) {
		g_wantedList[ player ] [ 0 ] = player;
		g_wantedList[ player ] [ 1 ] = p_WantedLevel[ player ];
	}

	// sort
	SortDeepArray( g_wantedList, 1, .order = SORT_DESC );

	// message
	szLargeString = ""COL_WHITE"玩家\t"COL_WHITE"通缉等级\n";
	for ( new i = 0; i < MAX_PLAYERS; i ++ ) if ( IsPlayerConnected( g_wantedList[ i ] [ 0 ] ) && g_wantedList[ i ] [ 1 ] > 0 ) {
 		format( szLargeString, sizeof( szLargeString ), "%s%s(%d)\t"COL_GOLD"%d\n", szLargeString, ReturnPlayerName( g_wantedList[ i ] [ 0 ] ), g_wantedList[ i ] [ 0 ], g_wantedList[ i ] [ 1 ] );
		is_empty = false;
	}

	if ( is_empty ) {
		return SendError( playerid, "没有要显示的想要的球员." );
	} else {
		return ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}在线招募玩家", szLargeString, "关闭", "" ), 1;
	}
}

CMD:contracts( playerid, params[ ] ) return cmd_hitlist( playerid, params );
CMD:hitlist( playerid, params[ ] )
{
	// if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "This is restricted to civilians only." );

	new g_contractList[ MAX_PLAYERS ] [ 2 ], bool: is_empty = true;

	// store cash and playerid
	foreach ( new player : Player )
	{
		g_contractList[ player ] [ 0 ] = player;
		g_contractList[ player ] [ 1 ] = p_ContractedAmount[ player ];
	}

	// sort
	SortDeepArray( g_contractList, 1, .order = SORT_DESC );

	// message
	szLargeString = ""COL_WHITE"玩家\t"COL_WHITE"总悬赏\n";
	for ( new i = 0; i < MAX_PLAYERS; i ++ ) if ( IsPlayerConnected( g_contractList[ i ] [ 0 ] ) && g_contractList[ i ] [ 1 ] >= 1000 ) {
 		format( szLargeString, sizeof( szLargeString ), "%s%s(%d)\t"COL_GOLD"%s\n", szLargeString, ReturnPlayerName( g_contractList[ i ] [ 0 ] ), g_contractList[ i ] [ 0 ], cash_format( g_contractList[ i ] [ 1 ] ) );
		is_empty = false;
	}

	if ( is_empty ) {
		return SendError( playerid, "没有可展示的签约球员." );
	} else {
		return ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}在线签约玩家", szLargeString, "关闭", "" ), 1;
	}
}

CMD:viewguns( playerid, params[ ] )
{
	/* ** COOL DOWN ** */
    if ( GetPVarInt( playerid, "weapon_buy_cool" ) > g_iTime ) return SendError( playerid, "你必须等待 40 秒才能再次从某人那里购买武器." );
    /* ** END OF COOL DOWN ** */

	if ( !IsPlayerConnected( p_WeaponDealer[ playerid ] ) ) return p_WeaponDealer[ playerid ] = INVALID_PLAYER_ID, SendError( playerid, "你的武器商没有空." );
	else if ( g_iTime > p_WeaponDealTick[ playerid ] ) return SendError( playerid, "你的最后一个武器交易已经过期." );
	else if ( IsPlayerInPaintBall( playerid ) || IsPlayerDueling( playerid ) ) return SendError( playerid, "你不能在竞技场购买武器." );
	else
	{
	    p_WeaponDealing{ playerid } = true;
		ShowAmmunationMenu( playerid, "{FFFFFF}武器交易 - 购买武器", DIALOG_WEAPON_DEAL );
		SendClientMessageFormatted( p_WeaponDealer[ playerid ], -1, ""COL_GREY"[服务器]"COL_WHITE" %s(%d) 现在正在查看你的武器选择.", ReturnPlayerName( playerid ), playerid );
	}
	return 1;
}

CMD:sellgun( playerid, params[ ] )
{
	new
	    pID
	;

	if ( !IsPlayerJob( playerid, JOB_WEAPON_DEALER ) ) return SendError( playerid, "你不是武器商." );
	else if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "只有平民可以使用此命令." );
	else if ( sscanf( params, "u", pID ) ) return SendUsage( playerid, "/sellgun [PLAYER_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "玩家 ID 无效." );
	else if ( pID == playerid ) return SendError( playerid, "你不能向自己出售武器." );
	else if ( p_Class[ pID ] == CLASS_POLICE ) return SendError( playerid, "你不能向执法人员出售武器." );
	else if ( p_WeaponDealing{ pID } == true ) return SendError( playerid, "该玩家当前正忙." );
	else if ( p_Jailed{ playerid } ) return SendError( playerid, "你在监狱里时不能出售武器." );
	else if ( p_Jailed{ pID } ) return SendError( playerid, "该玩家已入狱,你不能向他出售武器." );
	else if ( IsPlayerInPaintBall( pID ) || IsPlayerDueling( pID ) ) return SendError( playerid, "你不能在竞技场中出售武器." );
	else if ( IsPlayerInEvent( playerid ) ) return SendError( playerid, "参加活动时无法使用此命令." );
	else if ( GetDistanceBetweenPlayers( playerid, pID ) < 5.0 )
	{
		SendClientMessageFormatted( pID, -1, ""COL_ORANGE"[武器交易]{FFFFFF} %s(%d) 希望向你出售武器. "COL_ORANGE"/viewguns{FFFFFF} 查看可用武器.", ReturnPlayerName( playerid ), playerid );
		SendClientMessageFormatted( playerid, -1, ""COL_ORANGE"[武器交易]{FFFFFF} 你已向 %s(%d) 发送了购买枪支的报价.", ReturnPlayerName( pID ), pID );
		p_WeaponDealer[ pID ] = playerid;
		p_WeaponDealTick[ pID ] = g_iTime + 60;
	}
	else SendError( playerid, "该玩家不在附近." );
	return 1;
}

CMD:ej( playerid, params[ ] ) return cmd_eject( playerid, params );
CMD:eject( playerid, params[ ] )
{
	new
	    pID
	;

	if ( sscanf( params, "u", pID ) ) return SendUsage( playerid, "/eject [PLAYER_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "玩家 ID 无效." );
	else if ( !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "你不在任何车辆中." );
	else if ( !IsPlayerInAnyVehicle( pID ) ) return SendError( playerid, "该玩家不在任何车辆中" );
	else if ( pID == playerid ) return SendError( playerid, "创建此命令仅用于弹出乘客." );
	else if ( GetPlayerVehicleID( pID ) != GetPlayerVehicleID( playerid ) ) return SendError( playerid, "该玩家不在你的车内" );
	else if ( GetPlayerState( playerid ) != PLAYER_STATE_DRIVER ) return SendError( playerid, "你不是这辆车的驾驶员." );
	//else if ( p_Detained{ pID } ) return SendError( playerid, "This player has his cuffs locked onto his seat. You can't eject him." );
	else
	{
	    if ( p_Kidnapped{ pID } == true ) p_Kidnapped{ pID } = false;
	    //if ( p_Detained{ pID } == true ) p_Detained{ pID } = false;
	    RemovePlayerFromVehicle( pID );
		SyncObject( pID, 0.0, 2.0, 2.0 );
        GameTextForPlayer( pID, "~r~被弹射~w~!", 3500, 3 );
        SendServerMessage( playerid, "玩家已被从你的车辆中弹出." );
	}
	return 1;
}

CMD:ejectall( playerid, params[ ] )
{
	new
	    iEjectCounter = 0,
		iPlayerSeat = GetPlayerVehicleSeat( playerid ),
		iPlayerVehicle = GetPlayerVehicleID( playerid )
	;

	if ( !IsPlayerInAnyVehicle( playerid ) ) {
		return SendError( playerid, "你不在车里." );
	}

	if ( iPlayerSeat != 0 ) {
		return SendError( playerid, "你不是这辆车的司机." );
	}

	foreach(new i : Player)
	{
		new
			iTargetVehicle = GetPlayerVehicleID( i ),
			iTargetSeat = GetPlayerVehicleSeat( i )
		;

		if ( iTargetVehicle == iPlayerVehicle && iTargetSeat >= 1 && iTargetSeat <= 3 ) {
			// change variables
		    if ( p_Kidnapped{ i } == true ) p_Kidnapped{ i } = false;
		    //if ( p_Detained{ i } == true ) p_Detained{ i } = false;

		    // remove from vehicle
			RemovePlayerFromVehicle( i );
			SyncObject( i, 0.0, 2.0, 2.0 );
			GameTextForPlayer( i, "~r~被弹射~w~!", 3500, 3 );

			// increment players ejected
			iEjectCounter++;
		}
	}

	if ( ! iEjectCounter )
		return SendError( playerid, "你没有任何要弹出的乘客." );

	return SendServerMessage( playerid, "你已将 %d 玩家%s 从你的车辆中弹出.", iEjectCounter, iEjectCounter > 1 ? ( "s" ) : ( "" ) );
}

CMD:acceptbj( playerid, params[ ] )
{
	if ( !IsPlayerConnected( p_BlowjobOfferer[ playerid ] ) ) return p_BlowjobOfferer[ playerid ] = INVALID_PLAYER_ID, SendError( playerid, "你的口交提供者不可用." );
	else if ( g_iTime > p_BlowjobDealTick[ playerid ] ) return SendError( playerid, "你的口交优惠已过期." );
	else if ( !IsPlayerJob( p_BlowjobOfferer[ playerid ], JOB_MUGGER ) ) return SendError( playerid, "你的口交提供者不再提供口交." );
	else if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "你不能在车内口交." );
	else if ( IsPlayerInAnyVehicle( p_BlowjobOfferer[ playerid ] ) ) return SendError( playerid, "该玩家在车内." );
	else if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "你不能在监狱里接受口交." );
	else if ( IsPlayerTied( playerid ) ) return SendError( playerid, "你不能在被捆时接受口交." );
	else if ( IsPlayerTazed( playerid ) ) return SendError( playerid, "当被电击打印机时你不能接受口交." );
	else if ( IsPlayerCuffed( playerid ) ) return SendError( playerid, "被铐住时你不能接受口交." );
	else if ( IsPlayerRobbing( playerid ) ) return SendError( playerid, "你不能在抢劫商店时接受口交." );
	else if ( IsPlayerGettingBlowed( playerid ) ) return SendError( playerid, "接受口交时无法使用此命令." );
	else if ( IsPlayerBlowingCock( playerid ) ) return SendError( playerid, "进行口交时无法使用此命令." );
	else if ( GetPlayerCash( playerid ) < p_BlowjobPrice[ playerid ] ) return SendError( playerid, "你负担不起这个口交." );
	else if ( IsPlayerAttachedObjectSlotUsed( playerid, 4 ) || IsPlayerAttachedObjectSlotUsed( playerid, 3 ) ) return SendError( playerid, "你的手此刻很忙." );
	else if ( GetDistanceBetweenPlayers( playerid, p_BlowjobOfferer[ playerid ] ) < 4.0 )
	{
		new
		    Float: X, Float: Y, Float: Z, Float: Angle,
		    iPrice = p_BlowjobPrice[ playerid ],
		    iEarned = floatround( iPrice * 0.90 )
		;

		SendClientMessageFormatted( p_BlowjobOfferer[ playerid ], -1, ""COL_ORANGE"[口交]{FFFFFF} %s(%d) 已接受你的口交提议 "COL_GOLD"%s"COL_WHITE".", ReturnPlayerName( playerid ), playerid, cash_format( iPrice ) );
		SendClientMessageFormatted( playerid, -1, ""COL_ORANGE"[口交]{FFFFFF} 你现在正在接受口交." );
		TogglePlayerControllable( p_BlowjobOfferer[ playerid ], 0 );
		TogglePlayerControllable( playerid, 0 );
		GetPlayerFacingAngle( p_BlowjobOfferer[ playerid ], Angle );
		SetPlayerFacingAngle( playerid, Angle - 180 );
		GetXYInFrontOfPlayer( p_BlowjobOfferer[ playerid ], X, Y, Z, 1 );
		SetPlayerPos( playerid, X, Y, Z );
		ApplyAnimation( playerid, "BLOWJOBZ", "BJ_STAND_START_P", 1.0, 1, 1, 1, 0, 0, 1 );
		ApplyAnimation( p_BlowjobOfferer[ playerid ], "BLOWJOBZ", "BJ_STAND_START_W", 1.0, 1, 1, 1, 0, 0, 1 );
		SetTimerEx( "BlowJob", 1500, false, "ddd", p_BlowjobOfferer[ playerid ], playerid, 0 );
		p_GettingBlowjob{ playerid } = true;
 		p_GivingBlowjob{ p_BlowjobOfferer[ playerid ] } = true;
		GivePlayerCash( playerid, -iPrice );
		GivePlayerCash( p_BlowjobOfferer[ playerid ], iEarned );
		p_BlowjobOfferer[ playerid ] = INVALID_PLAYER_ID;
	}
	else
	{
		SendError( playerid, "此人不在附近." );
	}
	return 1;
}

CMD:blowjob( playerid, params[ ] ) return cmd_bj( playerid, params );
CMD:bj( playerid, params[ ] )
{
	new
	    pID, price
	;

	if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "此功能仅限平民使用." );
	else if ( !IsPlayerJob( playerid, JOB_MUGGER ) ) return SendError( playerid, "你必须是抢劫犯才能使用此命令." );
	else if ( ( GetTickCount( ) - p_AntiBlowJobSpam[ playerid ] ) < 30000 ) return SendError( playerid, "再次使用此命令之前,你必须等待 30 秒." );
	else if ( sscanf( params, "ud", pID, price ) ) return SendUsage( playerid, "/(bj)blowjob [PLAYER_ID] [PRICE]" );
	else if ( !IsPlayerConnected( pID ) ) return SendError( playerid, "该玩家不在线." );
	else if ( price < 20 || price > 3000 ) return SendError( playerid, "请指定介于 $20 和 $3,000. 之间的价格" );
	else if ( playerid == pID ) return SendError( playerid, "你不能给自己口交." );
	else if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "你不能在监狱里提供口交." );
	else if ( IsPlayerGettingBlowed( playerid ) ) return SendError( playerid, "接受口交时无法使用此命令." );
	else if ( IsPlayerBlowingCock( playerid ) ) return SendError( playerid, "进行口交时无法使用此命令." );
	else if ( IsPlayerInPaintBall( playerid ) || IsPlayerDueling( playerid ) || IsPlayerPlayingPool( playerid ) ) return SendError( playerid, "你不能在小游戏中使用此命令." );
	else if ( GetDistanceBetweenPlayers( playerid, pID ) < 4.0 )
	{
		if ( IsPlayerJailed( pID ) ) return SendError( playerid, "此玩家已入狱, 可能处于暂停状态." );
        SendClientMessageFormatted( pID, -1, ""COL_ORANGE"[口交]{FFFFFF} %s(%d) 希望给你口交 "COL_GOLD"%s"COL_WHITE". "COL_ORANGE"/acceptbj{FFFFFF} 接受.", ReturnPlayerName( playerid ), playerid, cash_format( price ) );
		SendClientMessageFormatted( playerid, -1, ""COL_ORANGE"[口交]{FFFFFF} 你已向 %s(%d) 提供口交,费用为 "COL_GOLD"%s"COL_WHITE".", ReturnPlayerName( pID ), pID, cash_format( price ) );
		p_BlowjobOfferer[ pID ] = playerid;
	    p_BlowjobDealTick[ pID ] = g_iTime + 60;
	    p_BlowjobPrice[ pID ] = price;
 		p_AntiBlowJobSpam[ playerid ] = GetTickCount( );
	}
	else SendError( playerid, "该玩家不在附近." );
	return 1;
}

CMD:report( playerid, params[ ] )
{
	new
		iPlayer,
		szMessage[ 64 ]
	;

    if ( sscanf( params, "us[64]", iPlayer, szMessage ) ) return SendUsage( playerid, "/report [PLAYER_ID] [REASON]" );
    else if ( !IsPlayerConnected( iPlayer ) || IsPlayerNPC( iPlayer ) ) return SendError( playerid, "玩家 ID 无效." );
    else if ( p_CantUseReport{ playerid } == true ) return SendError( playerid, "管理员已阻止你使用此命令." );
	else if ( GetPVarInt( iPlayer, "report_antispam" ) > g_iTime ) return SendError( playerid, "你必须等待 10 秒才能报告该玩家." );
    else
	{
		for( new iPos; iPos < sizeof( szReportsLog ) - 1; iPos++ )
			memcpy( szReportsLog[ iPos ], szReportsLog[ iPos + 1 ], 0, sizeof( szReportsLog[ ] ) * 4 );

		format( szNormalString, sizeof( szNormalString ), "%s\t%s(%d)\t%s(%d)\t%s\n", getCurrentTime( ), ReturnPlayerName( playerid ), playerid, ReturnPlayerName( iPlayer ), iPlayer, szMessage );
		strcpy( szReportsLog[ 7 ], szNormalString );

		Beep( playerid );
		SetPVarInt( iPlayer, "report_antispam", g_iTime + 10 );

        SendClientMessageToAdmins( -1, ""COL_RED"[REPORT] %s(%d) reported %s(%d):{FFFFFF} %s", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( iPlayer ), iPlayer, szMessage );
		SendClientMessageFormatted( playerid, -1, ""COL_RED"[举报]"COL_WHITE" 你已举报%s(%d)对于\"%s\".", ReturnPlayerName( iPlayer ), iPlayer, szMessage );
	}
	return 1;
}

CMD:bu( playerid, params[ ] ) return cmd_backup( playerid, params );
CMD:backup( playerid, params[ ] )
{
    if ( p_Class[ playerid ] != CLASS_POLICE ) return SendError( playerid, "警方仅被授权使用此功能." );
    SendClientMessageToCops( -1, ""COL_BLUE"[警用电台]"COL_WHITE" %s 正在请求 %s 支援.", ReturnPlayerName( playerid ), GetPlayerArea( playerid ) );
	return 1;
}

CMD:sm( playerid, params[ ] ) return cmd_sendmoney( playerid, params );
CMD:sendmoney( playerid, params[ ] )
{
    new
		pID,
		amount,
		szPayment[ 96 ],
		iTime = g_iTime
	;

	if ( ! IsPlayerSecurityVerified( playerid ) )
		return SendError( playerid, "使用此功能需要先验证账号. "COL_YELLOW"(输入 /verify)" );

	/* ** Anti Tie Spam ** */
	if ( GetPVarInt( playerid, "sm_antispam" ) > iTime ) return SendError( playerid, "你必须等待 10 秒才能再次发送付款." );
	/* ** End of Anti Tie Spam ** */

	if ( sscanf( params, "ud", pID, amount ) ) return SendUsage( playerid, "/sendmoney [PLAYER_ID] [AMOUNT]" );
	else if ( amount > GetPlayerCash( playerid ) ) return SendError( playerid, "你没有这么多钱." );
	else if ( amount < 1 ) return SendError( playerid, "金额无效." );
    else if ( pID == playerid ) return SendError( playerid, "你不能给自己汇款." );
    else if ( !IsPlayerConnected( pID ) ) return SendError( playerid, "此玩家不在线." );
	else if ( p_PlayerLogged{ pID } == false ) return SendError( playerid, "该玩家尚未登录." );
	else if ( IsPlayerAFK( pID ) ) return SendError( playerid, "你不能向 AFK 的人汇款." );
	else if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "当你被绑架时,你不能给任何人寄钱." );
    else
    {
    	format( szPayment, sizeof( szPayment ), "INSERT INTO `TRANSACTIONS` (`TO_ID`, `FROM_ID`, `CASH`) VALUES (%d, %d, %d)", p_AccountID[ pID ], p_AccountID[ playerid ], amount );
     	mysql_single_query( szPayment );

        if ( amount > 25000 )
        	printf("[sendmoney] %s -> %s - %s", ReturnPlayerName( playerid ), ReturnPlayerName( pID ), cash_format( amount ) ); // 8hska7082bmahu

		/*if ( amount > 90000000 ) {
	   		printf("ISP banned %s for making a 75M transaction", ReturnPlayerName( playerid ));
			AdvancedBan( playerid, "Server", "Suspicious Transaction", ReturnPlayerIP( playerid ) );
	   		return 1;
        }*/

        GivePlayerCash( pID, amount );
        GivePlayerCash( playerid, -( amount ) );
    	SetPVarInt( playerid, "sm_antispam", iTime + 10 );
		SendClientMessageFormatted( pID, -1, ""COL_GREEN"[转账]"COL_WHITE" 你已收到%s来自%s(%d).", cash_format( amount ), ReturnPlayerName( playerid ), playerid );
        SendClientMessageFormatted( playerid, -1, ""COL_RED"[转账]"COL_WHITE" 你已将 %s 发送至 %s(%d).", cash_format( amount ), ReturnPlayerName(pID), pID );
        Beep( pID ), Beep( playerid );
    }
	return 1;
}

CMD:dndall( playerid, params[ ] )
{
	foreach(new i : Player)
	{
	    if ( i == playerid ) continue;
	    p_BlockedPM[ playerid ] [ i ] = true;
	}
	SendClientMessage( playerid, -1, ""COL_GOLD"[免打扰]"COL_WHITE" 你已取消允许所有人向你发送私信." );
	return 1;
}

CMD:undndall( playerid, params[ ] )
{
	foreach(new i : Player)
	{
	    if ( i == playerid ) continue;
	    p_BlockedPM[ playerid ] [ i ] = false;
	}
	SendClientMessage( playerid, -1, ""COL_GOLD"[免打扰]"COL_WHITE" 你已切换所有人向你发送私信." );
	return 1;
}

CMD:dnd( playerid, params[ ] )
{
	new
	    pID
	;
	if ( sscanf( params, "u", pID ) ) return SendUsage( playerid, "/dnd [PLAYER_ID]" );
    else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "玩家 ID 无效." );
    else if ( pID == playerid ) return SendError( playerid, "你不能阻止自己." );
	else
	{
	    p_BlockedPM[ playerid ] [ pID ] = ( p_BlockedPM[ playerid ] [ pID ] == true ? ( false ) : ( true ) );
		SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[免打扰]"COL_WHITE" 你有 %s %s 向你发送私信.", p_BlockedPM[ playerid ] [ pID ] == false ? ("切换的") : ("未切换"), ReturnPlayerName( pID ) );
	}
	return 1;
}

CMD:r( playerid, params[ ] )
{
	new msg[ 100 ];

	if ( sscanf( params, "s[100]", msg ) ) return SendUsage( playerid, "/r [MESSAGE]" );
	else if ( !IsPlayerConnected( p_PmResponder[ playerid ] ) ) return SendError( playerid, "此玩家不在线." );
    else if ( p_BlockedPM[ p_PmResponder[ playerid ] ] [ playerid ] == true ) return SendError( playerid, "此人已阻止来自你的下午消息." );
    else if ( textContainsIP( msg ) ) return SendError( playerid, "禁止通过 PM 发布广告." );
	else if ( p_PlayerLogged{ p_PmResponder[ playerid ] } == false ) return SendError( playerid, "该玩家尚未登录." );
	else
	{
	    new pID = p_PmResponder[ playerid ];

		if ( IsPlayerServerMaintainer( pID ) && g_VipPrivateMsging && p_VIPLevel[ playerid ] < VIP_REGULAR ) {
			return SendError( playerid, "你需要 VIP 才能私信此人,才能成为一次访问 "COL_GREY"donate.sfcnr.com" );
		}

		if ( p_BlockedPM[ playerid ] [ pID ] == true ) {
			SendServerMessage( playerid, "你发送的消息是发给你阻止的人,因此他们已被取消阻止." );
			p_BlockedPM[ playerid ] [ pID ] = false;
		}

		if ( IsPlayerAFK( pID ) ) {
			SendServerMessage( playerid, "你已向当前 AFK 的人发送了一条消息.请注意!" );
		}

		GameTextForPlayer( pID, "~n~~n~~n~~n~~n~~n~~n~~w~... ~y~新消息!~w~ ...", 4000, 3 );
		SendClientMessageFormatted( pID, -1, ""COL_YELLOW"[私信]{CCCCCC} 来自%s(%d):%s", ReturnPlayerName( playerid ), playerid, msg );
        SendClientMessageFormatted( playerid, -1, ""COL_YELLOW"[私信]{A3A3A3} 至 %s(%d):%s", ReturnPlayerName(pID), pID, msg );
		foreach(new i : Player)
		{
		    if ( ( p_AdminLevel[ i ] >= 5 || IsPlayerUnderCover( i ) ) && p_ToggledViewPM{ i } == true )
		    {
		        SendClientMessageFormatted( i, -1, ""COL_PINK"[私信监控]"COL_YELLOW" (%s >> %s):"COL_WHITE" %s", ReturnPlayerName( playerid ), ReturnPlayerName( pID ), msg );
		    }
		}
		p_PmResponder[ playerid ] = pID;
        Beep( pID ), Beep( playerid );
	}
	return 1;
}

CMD:pm( playerid, params[ ] )
{
	new
		pID, msg[100]
	;

	if ( sscanf( params, "us[100]", pID, msg ) ) return SendUsage( playerid, "/pm [PLAYER_ID] [MESSAGE]" );
    else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "玩家 ID 无效." );
    else if ( pID == playerid ) return SendError( playerid, "你不能私信自己." );
    else if ( p_BlockedPM[ pID ] [ playerid ] == true ) return SendError( playerid, "此人已阻止来自你的下午消息." );
	else if ( textContainsIP( msg ) ) return SendError( playerid, "禁止通过 PM 发布广告." );
	else if ( p_PlayerLogged{ pID } == false ) return SendError( playerid, "该玩家尚未登录." );
	else if ( GetPlayerScore( playerid ) < 50 ) return SendError( playerid, "你必须至少拥有 50 分数 才能在服务器中发送私人消息." );
	else
	{
		if ( IsPlayerServerMaintainer( pID ) && g_VipPrivateMsging && p_VIPLevel[ playerid ] < VIP_REGULAR ) {
			return SendError( playerid, "你需要 VIP 才能私信此人,才能成为一次访问 "COL_GREY"donate.sfcnr.com" );
		}

		if ( p_BlockedPM[ playerid ] [ pID ] == true ) {
			SendServerMessage( playerid, "你发送的消息是发给你阻止的人,因此他们已被取消阻止." );
			p_BlockedPM[ playerid ] [ pID ] = false;
		}

		if ( IsPlayerAFK( pID ) ) {
			SendServerMessage( playerid, "你已向当前 AFK 的人发送了一条消息.请注意!" );
		}

		GameTextForPlayer( pID, "~n~~n~~n~~n~~n~~n~~n~~w~... ~y~新消息!~w~ ...", 4000, 3 );
		SendClientMessageFormatted( pID, -1, ""COL_YELLOW"[私信]{CCCCCC} 来自%s(%d):%s", ReturnPlayerName( playerid ), playerid, msg );
        SendClientMessageFormatted( playerid, -1, ""COL_YELLOW"[私信]{A3A3A3} 至 %s(%d):%s", ReturnPlayerName(pID), pID, msg );
		foreach(new i : Player)
		{
		    if ( ( p_AdminLevel[ i ] >= 5 || IsPlayerUnderCover( i ) ) && p_ToggledViewPM{ i } == true )
		    {
		        SendClientMessageFormatted( i, -1, ""COL_PINK"[私信监控]"COL_YELLOW" (%s >> %s):"COL_WHITE" %s", ReturnPlayerName( playerid ), ReturnPlayerName( pID ), msg );
		    }
		}
		p_PmResponder[ playerid ] = pID;
        Beep( pID ), Beep( playerid );
	}
	return 1;
}

CMD:statistics( playerid, params[ ] ) return cmd_stats( playerid, params );
CMD:stats( playerid, params[ ] )
{
	if ( !p_PlayerLogged{ playerid } )
		return SendError( playerid, "你尚未登录,这意味着你无法访问此命令." );

	p_ViewingStats[ playerid ] = playerid;
	ShowPlayerDialog( playerid, DIALOG_STATS, DIALOG_STYLE_LIST, "{FFFFFF}统计", "一般统计\n游戏统计\n物品统计\n连胜统计\n武器统计\n成就", "确定", "取消" );
	return 1;
}

CMD:commands( playerid, params[ ] ) return cmd_cmds( playerid, params );
CMD:cmds( playerid, params[ ] )
{
    ShowPlayerDialog( playerid, DIALOG_CMDS, DIALOG_STYLE_LIST, "{FFFFFF}命令", "基本命令\n主要命令\n民用命令\n商店/Item命令\n警察命令\n车辆命令\n房屋命令\n杂项命令\n"COL_GOLD"VIP 命令", "确定", "" );
	return 1;
}

CMD:shop( playerid, params[ ] )
{
    if ( ( !IsPlayerInEntrance( playerid, g_SupaSave ) && !IsPlayerInDynamicCP( playerid, g_Checkpoints[ CP_247_MENU ] ) ) || !GetPlayerInterior( playerid ) ) return SendError( playerid, "你必须在 Supa Save 或 24/7 内才能购买物品." );
	if ( IsPlayerTazed( playerid ) ) return SendError( playerid, "你不能使用这个,因为你是被电击打印机." );
	//if ( IsPlayerDetained( playerid ) ) return SendError( playerid, "You cannot use this since you're detained." );
	if ( IsPlayerCuffed( playerid ) ) return SendError( playerid, "你不能使用这个,因为你被铐住了." );
	if ( IsPlayerTied( playerid ) ) return SendError( playerid, "你不能使用这个,因为你被捆绑了." );
	if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "你不能使用这个,因为你被绑架了." );

	ShowPlayerShopMenu( playerid );
	return 1;
}

CMD:placehit( playerid, params[ ] )
{
	if ( ! IsPlayerSecurityVerified( playerid ) )
		return SendError( playerid, "使用此功能需要先验证账号. "COL_YELLOW"(输入 /verify)" );

	/* ** Anti Spammy Commands ** */
	if ( p_AntiSpammyTS[ playerid ] > g_iTime ) return SendError( playerid, "你无法使用在 %d 秒内发送给全局玩家的命令.", p_AntiSpammyTS[ playerid ] - g_iTime );
	/* ** End Anti Spammy Commands ** */

	new
	    pID,
	    cash
	;
	if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "此功能仅限平民使用." );
	else if ( IsPlayerJob( playerid, JOB_HITMAN ) ) return SendError( playerid, "作为 职业杀手,你不能使用此命令." );
	else if ( sscanf( params, "ud", pID, cash ) ) return SendUsage( playerid, "/placehit [PLAYER_ID] [AMOUNT]" );
	else if ( cash > GetPlayerCash( playerid ) ) return SendError( playerid, "你没有足够的钱来放置这么多." );
	else if ( cash < 1000 ) return SendError( playerid, "你能造成的最小打击是 $1,000." );
	else if ( pID == playerid ) return SendError( playerid, "你不能打自己.");
	else if ( !IsPlayerConnected( pID ) ) return SendError( playerid, "该玩家不在线!" );
	{
		// transaction
    	format( szNormalString, sizeof( szNormalString ), "INSERT INTO `TRANSACTIONS` (`TO_ID`, `FROM_ID`, `CASH`, `NATURE`) VALUES (%d, %d, %d, 'contract')", p_AccountID[ pID ], p_AccountID[ playerid ], cash );
     	mysql_single_query( szNormalString );

     	// place hit
		p_ContractedAmount[ pID ] += cash;
		GivePlayerCash( playerid, -cash );
		p_AntiSpammyTS[ playerid  ] = g_iTime + 10;

		// message
		printf("[placehit] %s -> %s - %s", ReturnPlayerName( playerid ), ReturnPlayerName( pID ), cash_format( cash ) ); // 8hska7082bmahu
		SendGlobalMessage( -1, ""COL_ORANGE"[悬赏]"COL_WHITE" %s(%d) 已与 %s(%d) 签订悬赏,他们的赏金现在为 "COL_GOLD"%s{FFFFFF}.", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID, cash_format( p_ContractedAmount[ pID ] ) );
	}
	return 1;
}

CMD:me( playerid, params[ ] )
{
	new action[70];
	if ( p_Muted{ playerid } == true && g_iTime < p_MutedTime[ playerid ] ) return SendError( playerid, "由于你已被静音,因此你无法使用此功能." );
	else if ( GetPlayerScore( playerid ) < 25 ) return SendError( playerid, "你至少需要 25 分数 才能使用此功能(垃圾邮件目的)." );
	else if ( IsPlayerChatBanned( playerid ) ) return SendError( playerid, "你已被封禁聊天,并且不允许聊天." );
	else if ( sscanf( params, "s[70]", action ) ) return SendUsage( playerid, "/me [ACTION]" );
	else
	{
    	//DCC_SendChannelMessageFormatted( discordGeneralChan, "** * * * %s(%d) %s **", ReturnPlayerName( playerid ), playerid, action );
		SendClientMessageToAllFormatted( GetPlayerColor( playerid ), "*** %s(%d) %s", ReturnPlayerName( playerid ), playerid, action );
	}
	return 1;
}

CMD:hidetracker( playerid, params[ ] )
{
	if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "此功能仅限平民使用." );
	if ( !IsPlayerJob( playerid, JOB_HITMAN ) ) return SendError( playerid, "你必须是 职业杀手 才能使用此命令." );
	if ( p_TrackingTimer[ playerid ] == -1 ) return SendError( playerid, "你的智能设备已停用." );
	SendServerMessage(playerid, "你已停用跟踪器.");
	KillTimer( p_TrackingTimer[ playerid ] );
	p_TrackingTimer[ playerid ] = -1;
	PlayerTextDrawHide( playerid, p_TrackPlayerTD[ playerid ] );
	return 1;
}

CMD:track( playerid, params[ ] )
{
	new
	    pID
	;

	if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "此功能仅限平民使用." );
	else if ( !IsPlayerJob( playerid, JOB_HITMAN ) ) return SendError( playerid, "你必须是 职业杀手 才能使用此命令." );
	else if ( IsPlayerInBattleRoyale( playerid ) ) return SendError( playerid, "大逃杀中无法使用此命令." );
	else if ( sscanf( params, "u", pID ) ) return SendUsage( playerid, "/track [PLAYER_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "该玩家不在线!" );
	else if ( pID == playerid ) return SendError( playerid, "你不能将此应用到你自己身上." );
	else if ( !IsPlayerSpawned( pID ) ) return SendError( playerid, "不会生成所选的玩家." );
	else if ( p_AdminOnDuty{ pID } == true || GetPlayerState( pID ) == PLAYER_STATE_SPECTATING ) return SendError( playerid, "这是值班管理员!你无法追踪他们的接近程度." );
	else
	{
	    KillTimer( p_TrackingTimer[ playerid ] );
	    p_TrackingTimer[ playerid ] = SetTimerEx( "TrackPlayer_timer", 1000, true, "dd", playerid, pID );
	    PlayerTextDrawShow( playerid, p_TrackPlayerTD[ playerid ] );
	    SendServerMessage( playerid, "你已激活跟踪器,你可以使用 /hidetracker 隐藏它." );
	}
	return 1;
}

function TrackPlayer_timer( playerid, victimid )
{
	if ( !IsPlayerConnected( victimid ) || p_AdminOnDuty{ victimid } == true || GetPlayerState( victimid ) == PLAYER_STATE_SPECTATING || !IsPlayerJob( playerid, JOB_HITMAN ) || p_Class[ playerid ] != CLASS_CIVILIAN )
	{
		KillTimer( p_TrackingTimer[ playerid ] ), p_TrackingTimer[ playerid ] = -1;
		PlayerTextDrawHide( playerid, p_TrackPlayerTD[ playerid ] );
	}
	else
	{
		new
			Float: fDistance;

		if ( GetPlayerInterior( playerid ) != GetPlayerInterior( victimid ) )
		{
			new
				iEntrance = p_LastEnteredEntrance[ victimid ],
				iHouse = p_InHouse[ victimid ],
				iGarage = p_InGarage[ victimid ]
			;

		    if ( iEntrance != -1 )
		  		fDistance = GetPlayerDistanceFromPoint( playerid, g_entranceData[ iEntrance ] [ E_EX ], g_entranceData[ iEntrance ] [ E_EY ], g_entranceData[ iEntrance ] [ E_EZ ] );

		  	else if ( iGarage != -1 )
		  		fDistance = GetPlayerDistanceFromPoint( playerid, g_garageData[ iGarage ] [ E_X ], g_garageData[ iGarage ] [ E_Y ], g_garageData[ iGarage ] [ E_Z ] );

		  	else if ( iHouse != -1 )
		  		fDistance = GetPlayerDistanceFromPoint( playerid, g_houseData[ iHouse ] [ E_EX ], g_houseData[ iHouse ] [ E_EY ], g_houseData[ iHouse ] [ E_EZ ] );

		  	else fDistance = 9999.9; // Truly unknown lol
		}
		else fDistance = GetDistanceBetweenPlayers( playerid, victimid );

		if ( !fDistance || fDistance > 9999.9 )
			fDistance = 9999.9;

		PlayerTextDrawSetString( playerid, p_TrackPlayerTD[ playerid ], fDistance != 9999.0 ? sprintf( "%s~n~~w~%0.1fm", ReturnPlayerName( victimid ), fDistance ) : sprintf( "%s~n~~w~未知", ReturnPlayerName( victimid ) ) );
	}
}

CMD:stoprob( playerid, params[ ] )
{
	SendServerMessage( playerid, "此命令会绑定你的蹲伏键,因此你必须抢劫商店才能获得响应!" );
	CallLocalFunction( "OnPlayerKeyStateChange", "ddd", playerid, KEY_CROUCH, KEY_SPRINT );
	return 1;
}

#if !defined __cloudy_event_system
CMD:exit( playerid, params[ ] ) return cmd_enter( playerid, params );
CMD:enter( playerid, params[ ] )
{
	GameTextForPlayer(playerid, "~n~~n~~r~~k~~VEHICLE_ENTER_EXIT~~n~~w~在可输入的检查点中按此键.", 5000, 3);
	return 1;
}
#endif

CMD:kill( playerid, params[ ] )
{
	if ( !IsPlayerSpawned( playerid ) ) return SendError( playerid, "尚未出生, 无法使用此命令." );
	if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "在监狱中无法使用此命令." );
	if ( IsPlayerTazed( playerid ) ) return SendError( playerid, "被电击时无法使用此命令." );
	//if ( IsPlayerDetained( playerid ) ) return SendError( playerid, "You cannot use this command since you're detained." );
	if ( IsPlayerCuffed( playerid ) ) return SendError( playerid, "被铐住时无法使用此命令." );
	if ( IsPlayerTied( playerid ) ) return SendError( playerid, "被捆绑时无法使用此命令." );
	if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "被绑架时无法使用此命令." );
	if ( p_WantedLevel[ playerid ] > 0 ) return SendError( playerid, "如果你身上有 通缉等级,你就不能自杀." );
	if ( IsPlayerGettingBlowed( playerid ) ) return SendError( playerid, "接受口交时无法使用此命令." );
	if ( IsPlayerBlowingCock( playerid ) ) return SendError( playerid, "进行口交时无法使用此命令." );
	if ( p_Spectating{ playerid } == true ) return SendError( playerid, "由于你正在观看,因此无法使用此命令." );
	if ( IsPlayerSpawnProtected( playerid ) ) return SendError( playerid, "当激活反生成杀戮时,你无法使用此命令." );
	SetPVarInt( playerid, "used_cmd_kill", 1 );
	SetPlayerHealth( playerid, -1 );
	return 1;
}

CMD:changeclass( playerid, params[ ] )
{
	if ( !IsPlayerSpawned( playerid ) ) return SendError( playerid, "尚未出生, 无法使用此命令." );
	if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "在监狱中无法使用此命令." );
	if ( IsPlayerTazed( playerid ) ) return SendError( playerid, "被电击时无法使用此命令." );
	//if ( IsPlayerDetained( playerid ) ) return SendError( playerid, "You cannot use this command since you're detained." );
	if ( IsPlayerCuffed( playerid ) ) return SendError( playerid, "被铐住时无法使用此命令." );
	if ( IsPlayerTied( playerid ) ) return SendError( playerid, "被捆绑时无法使用此命令." );
	if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "被绑架时无法使用此命令." );
	if ( p_WantedLevel[ playerid ] > 0 ) return SendError( playerid, "如果你身上有 通缉等级,你就不能自杀." );
	if ( IsPlayerGettingBlowed( playerid ) ) return SendError( playerid, "接受口交时无法使用此命令." );
	if ( IsPlayerBlowingCock( playerid ) ) return SendError( playerid, "进行口交时无法使用此命令." );
	if ( p_Spectating{ playerid } == true ) return SendError( playerid, "由于你正在观看,因此无法使用此命令." );
	if ( IsPlayerSpawnProtected( playerid ) ) return SendError( playerid, "当激活反生成杀戮时,你无法使用此命令." );
	SetPVarInt( playerid, "used_cmd_kill", 1 );
	ForceClassSelection( playerid );
	SetPlayerHealth( playerid, -1 );
	return 1;
}

CMD:911( playerid, params[ ] )
{
	/* ** Anti Spammy Commands ** */
	if ( p_AntiSpammyTS[ playerid ] > g_iTime ) return SendError( playerid, "你无法使用在 %d 秒内发送给全局玩家的命令.", p_AntiSpammyTS[ playerid ] - g_iTime );
	/* ** End Anti Spammy Commands ** */

	if ( p_Class[ playerid ] == CLASS_POLICE ) return SendError( playerid, "你不能使用此命令,因为你是执法人员." );
	else if ( GetPlayerInterior( playerid ) != 0 ) return SendError( playerid, "你不能在室内使用此命令." );
	else
	{
		new
			Float: X, Float: Y, Float: Z,
			szLocation[ MAX_ZONE_NAME ], szCity[ MAX_ZONE_NAME ]
		;
		GetPlayerPos( playerid, X, Y, Z );
		GetZoneFromCoordinates( szLocation, X, Y, Z );
		Get2DCity( szCity, X, Y, Z );

    	p_AntiSpammyTS[ playerid ] = g_iTime + 15;
        SendClientMessageToCops( -1, ""COL_BLUE"[911]"COL_GREY" %s(%d) 正在请求附近的执法人员%s在%s!", ReturnPlayerName( playerid ), playerid, GetLocationDisplayName(szLocation), GetLocationDisplayName(szCity) );
		SendServerMessage( playerid, "你已请求执法人员前往你当前的位置." );
	}
	return 1;
}


CMD:kidnap( playerid, params[ ] )
{
	/* ** ANTI KIDNAP SPAM ** */
    if ( p_AntiKidnapSpam[ playerid ] > g_iTime ) return SendError( playerid, "在再次绑架某人之前,你必须等待 30 秒." );
    /* ** END OF ANTI SPAM **/

  	new victimid = GetClosestPlayer( playerid );
    if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "在监狱中无法使用此命令." );
	else if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "此功能仅限平民使用." );
    else if ( p_Spectating{ playerid } ) return SendError( playerid, "旁观时无法使用此类命令." );
    else if ( !IsPlayerJob( playerid, JOB_KIDNAPPER ) ) return SendError( playerid, "绑架者只能使用此命令." );
	else if ( GetDistanceBetweenPlayers( playerid, victimid ) < 4.0 && IsPlayerConnected( victimid ) )
	{
        if ( IsPlayerInAnyVehicle( victimid ) ) return SendError( playerid, "该玩家在车辆中." );
		else if ( !IsPlayerTied( victimid ) ) return SendError( playerid, "这位玩家没有被绑!" );
		else if ( IsPlayerKidnapped( victimid ) ) return SendError( playerid, "该玩家已经被绑架了!" );
		else if ( IsPlayerGettingBlowed( playerid ) ) return SendError( playerid, "接受口交时无法使用此命令." );
		else if ( IsPlayerBlowingCock( playerid ) ) return SendError( playerid, "进行口交时无法使用此命令." );
		else if ( IsPlayerInMinigame( playerid ) ) return SendError( playerid, "你目前无法使用此命令." );
		else if ( IsPlayerJailed( victimid ) ) return SendError( playerid, "此玩家已入狱, 可能处于暂停状态." );
		else if ( p_KidnapImmunity[ victimid ] > g_iTime ) return SendError( playerid, "该玩家不能被另一个 %s 绑架.", secondstotime( p_KidnapImmunity[ victimid ] - g_iTime ) );
		else if ( PutPlayerInEmptyVehicleSeat( p_LastVehicle[ playerid ], victimid ) == -1 ) return SendError( playerid, "载具已满, 无法将此玩家押入车内." );

		// event check
		#if defined __cloudy_event_system
		if ( IsPlayerInEvent( playerid ) && ! EventSettingAllow( EVENT_SETTING_KIDNAP ) )
		#else
		if ( IsPlayerInEvent( playerid ) )
		#endif
		{
			return SendError( playerid, "参加活动时无法使用此命令." );
		}

		SendClientMessageFormatted( victimid, -1, ""COL_RED"[绑架]{FFFFFF} 你被%s(%d) 绑架了!", ReturnPlayerName( playerid ), playerid );
	    SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[绑架]{FFFFFF} 你绑架了 %s(%d),他被扔进了你之前进入的车辆中!", ReturnPlayerName( victimid ), victimid );
		TogglePlayerControllable( victimid, 0 );
		p_Kidnapped{ victimid } = true;
		GivePlayerWantedLevel( playerid, 12 );
     	p_AntiKidnapSpam[ playerid ] = g_iTime + 30;
		//PutPlayerInVehicle( victimid, p_LastVehicle[ playerid ], 1 );
	}
	else return SendError( playerid, "周围没有玩家可以绑架." );
	return 1;
}

CMD:untie( playerid, params[ ] )
{
  	new victimid = GetClosestPlayer( playerid );
    if ( p_Spectating{ playerid } ) return SendError( playerid, "旁观时无法使用此类命令." );
	else if ( GetDistanceBetweenPlayers( playerid, victimid ) < 4.0 && IsPlayerConnected( victimid ) )
	{
		if ( IsPlayerTied( playerid ) ) return SendError( playerid, "被捆绑时无法使用此命令." );
  		//if ( IsPlayerInAnyVehicle( victimid ) ) return SendError( playerid, "This player is in a vehicle." );
		if ( !IsPlayerTied( victimid ) ) return SendError( playerid, "这位玩家没有被绑!" );
		SendClientMessageFormatted( victimid, -1, ""COL_GREEN"[未捆绑]{FFFFFF} 你已被 %s(%d) 解绑!", ReturnPlayerName( playerid ), playerid );
	    SendClientMessageFormatted( playerid, -1, ""COL_RED"[松绑]{FFFFFF} 你已经解绑%s(%d)!", ReturnPlayerName( victimid ), victimid );
		TogglePlayerControllable( victimid, 1 );
		p_Tied{ victimid } = false;
		Delete3DTextLabel( p_TiedLabel[ victimid ] );
		p_TiedLabel[ victimid ] = Text3D: INVALID_3DTEXT_ID;
		p_TimeTiedAt[ victimid ] = 0;
		p_Kidnapped{ victimid } = false;
	}
	else return SendError( playerid, "周围没有可以解开的玩家." );
	return 1;
}

CMD:tie( playerid, params[ ] )
{
	/* ** Anti Tie Spam ** */
	if ( p_AntiTieSpam[ playerid ] > g_iTime ) return SendError( playerid, "你必须等待 %d 秒才能再次捆绑某人.", p_AntiTieSpam[ playerid ] - g_iTime );
	/* ** End of Anti Tie Spam ** */

	new victimid = GetClosestPlayer( playerid );
	//if ( sscanf( params, "u", victimid ) ) return SendUsage( playerid, "/tie [PLAYER_ID]" );
	//else if ( victimid == playerid ) return SendError( playerid, "You cannot tie yourself." );
	//else if ( !IsPlayerConnected( victimid ) ) return SendError( playerid, "This player is not connected." );
	if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "在监狱中无法使用此命令." );
	else if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "此功能仅限平民使用." );
    else if ( p_Spectating{ playerid } ) return SendError( playerid, "旁观时无法使用此类命令." );
	else if ( p_Ropes[ playerid ] < 1 ) return SendError( playerid, "你没有任何绳索." );
 	else if ( GetDistanceBetweenPlayers( playerid, victimid ) < 4.0 && IsPlayerConnected( victimid ) )
 	{
		if ( IsPlayerTied( playerid ) ) return SendError( playerid, "被捆绑时无法使用此命令." );
        else if ( IsPlayerInAnyVehicle( victimid ) ) return SendError( playerid, "该玩家在车辆中." );
		else if ( IsPlayerTied( victimid ) ) return SendError( playerid, "这位玩家已经被捆了!" );
        else if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "你不能在车内系带." );
		else if ( IsPlayerCuffed( playerid ) ) return SendError( playerid, "当你被铐住时你不能打领带." );
		else if ( IsPlayerTazed( playerid ) ) return SendError( playerid, "当你被电击剑时你不能打领带." );
		else if ( IsPlayerOnSlotMachine( victimid ) ) return SendError( playerid, "你试图绑定的人正在使用老虎机." );
		else if ( IsPlayerOnRoulette( victimid ) ) return SendError( playerid, "你试图绑定的人正在使用轮盘赌." );
		else if ( IsPlayerCuffed( victimid ) ) return SendError( playerid, "你想要绑住的人被铐住了." );
		else if ( IsPlayerGettingBlowed( playerid ) ) return SendError( playerid, "接受口交时无法使用此命令." );
		else if ( IsPlayerBlowingCock( playerid ) ) return SendError( playerid, "进行口交时无法使用此命令." );
		else if ( IsPlayerInMinigame( playerid ) ) return SendError( playerid, "你不能在竞技场使用此命令." );
		else if ( IsPlayerAdminOnDuty( victimid ) ) return SendError( playerid, "无法对值勤中的管理员使用此命令." );
		else if ( IsPlayerJailed( victimid ) ) return SendError( playerid, "此玩家已入狱, 可能处于暂停状态." );
		else if ( IsPlayerLoadingObjects( victimid ) ) return SendError( playerid, "此玩家正在加载地图物体." );
		else if ( GetPlayerState( victimid ) == PLAYER_STATE_WASTED ) return SendError( playerid, "不能捆绑已死亡的玩家." );
		else if ( IsPlayerInPlayerGang( playerid, victimid ) ) return SendError( playerid, "你不能对你的兄弟使用这个命令!" );
		else if ( IsPlayerSpawnProtected( victimid ) ) return SendError( playerid, "你无法对生成受保护的玩家使用此命令." );
		else if ( IsPlayerInCasino( victimid ) && ! p_WantedLevel[ victimid ] ) return SendError( playerid, "你试图捆绑的无辜者在赌场里." );

		// event check
		#if defined __cloudy_event_system
		if ( IsPlayerInEvent( playerid ) && ! EventSettingAllow( EVENT_SETTING_TIE ) )
		#else
		if ( IsPlayerInEvent( playerid ) )
		#endif
		{
			return SendError( playerid, "参加活动时无法使用此命令." );
		}

		// remove rope after attempt
		if ( p_Ropes[ playerid ] -- > 0 ) {
			ShowPlayerHelpDialog( playerid, 4500, "你只剩下 %d 根绳子了!", p_Ropes[ playerid ] );
		} else {
			ShowPlayerHelpDialog( playerid, 4500, "你可以在 Supa Save 或 24/7 商店购买绳索." );
		}

		p_AntiTieSpam[ playerid ] = g_iTime + 30;
		GivePlayerWantedLevel( playerid, 6 );

		// check if tie is successful
		if ( random( 101 ) < 90 )
		{
			new bool: scissor_success = false;
			new attempts = 0;

			for ( attempts = 1; attempts < p_Scissors[ victimid ]; attempts ++ )
			{
				if ( random( 101 ) > 20 ) {
					scissor_success = true;
					break;
				}
			}

			if ( ( p_Scissors[ victimid ] -= attempts ) > 0 ) {
				ShowPlayerHelpDialog( victimid, 4500, "你只剩下%d剪刀了!", p_Scissors[ victimid ] );
			} else {
				ShowPlayerHelpDialog( victimid, 4500, "可在 Supa Save 或 24/7 商店购买剪刀." );
			}

			if ( scissor_success )
			{
				SendClientMessageFormatted( playerid, -1, ""COL_RED"[捆绑]{FFFFFF} %s(%d) 已剪断你放置的领带!", ReturnPlayerName( victimid ), victimid );
			    SendClientMessageFormatted( victimid, -1, ""COL_GREEN"[捆绑]{FFFFFF}你已切断%s(%d) 的领带之后%d尝试!", ReturnPlayerName( playerid ), playerid, attempts );
			}
			else
			{
				SendClientMessageFormatted( victimid, -1, ""COL_RED"[捆绑]{FFFFFF} 你已经被 %s(%d) 捆绑了!", ReturnPlayerName( playerid ), playerid );
			    SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[捆绑]{FFFFFF} 你被捆%s(%d)!", ReturnPlayerName( victimid ), victimid );
				TogglePlayerControllable( victimid, 0 );
				p_Tied{ victimid } = true;
	     		p_TimeTiedAt[ victimid ] = g_iTime;
				p_TiedBy[ victimid ] = playerid;
			    Delete3DTextLabel( p_TiedLabel[ victimid ] );
			    format( szNormalString, 48, "被%s束缚!", ReturnPlayerName( playerid ) );
			    p_TiedLabel[ victimid ] = Create3DTextLabel( szNormalString, 0xDAB583FF, 0.0, 0.0, 0.0, 15.0, 0 );
			    Attach3DTextLabelToPlayer( p_TiedLabel[ victimid ], victimid, 0.0, 0.0, 0.6 );
			    p_TiedAtTimestamp[ victimid ] = g_iTime;
			}
			return 1;
		}
		else
		{
			p_AntiTieSpam[ playerid ] = g_iTime + 6; // makecopgreatagain
			SendClientMessageFormatted( victimid, -1, ""COL_GREEN"[捆绑失败]{FFFFFF} %s(%d) 未能束缚你!", ReturnPlayerName( playerid ), playerid );
		    SendClientMessageFormatted( playerid, -1, ""COL_RED"[捆绑失败]{FFFFFF} 你未能绑定 %s(%d)!", ReturnPlayerName( victimid ), victimid );
		}
		return 1;
	}
	else return SendError( playerid, "周围没有可以打平的玩家." );
}

CMD:pu( playerid, params[ ] ) return cmd_pullover(playerid, params);
CMD:pullover( playerid, params[ ] )
{
   	new victimid = GetClosestPlayerEx( playerid, CLASS_CIVILIAN );
    if ( p_Class[ playerid ] != CLASS_POLICE ) return SendError( playerid, "此功能仅限警察使用." );
    else if ( p_Spectating{ playerid } ) return SendError( playerid, "旁观时无法使用此类命令." );
 	else if ( GetDistanceBetweenPlayers( playerid, victimid ) < 20.0 && IsPlayerConnected( victimid ) )
 	{
        if ( p_Class[ victimid ] == p_Class[ playerid ] ) return SendError( playerid, "附近的此玩家与你同阵营." );
		if ( p_WantedLevel[ victimid ] == 0 ) return SendError( playerid, "此玩家没有犯罪!" );
		if ( GetPlayerState( victimid ) != PLAYER_STATE_DRIVER ) return SendError( playerid, "该玩家不在任何车辆中!" );
		SendClientMessageFormatted( victimid, -1, ""COL_RED"[靠边停车]{FFFFFF} %s(%d) 要求你靠边停车!", ReturnPlayerName( playerid ), playerid );
	    SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[靠边停车]{FFFFFF} 你已要求 %s(%d) 靠边停车!", ReturnPlayerName( victimid ), victimid );
	}
    else return SendError( playerid, "周围没有玩家要求靠边停车!" );
	return 1;
}

CMD:loc( playerid, params[ ] ) return cmd_location( playerid, params );
CMD:locate( playerid, params[ ] ) return cmd_location( playerid, params );
CMD:location( playerid, params[ ] )
{
   	new
   	    pID
	;

	if ( p_Class[ playerid ] == CLASS_CIVILIAN ) return SendError( playerid, "此功能仅限警察使用." );
	else if ( sscanf( params, "u", pID ) ) return SendUsage( playerid, "/loc(ation) [PLAYER_ID]" );
	else if ( ! IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "该玩家不在线!" );
	else if ( ! IsPlayerSpawned( pID ) ) return SendError( playerid, "不会生成所选的玩家." );
	//else if ( GetPlayerInterior( playerid ) != GetPlayerInterior( pID ) ) return SendError( playerid, "This player is inside a interior, the location is not viewable." );
	else if ( p_AdminOnDuty{ pID } == true ) return SendError( playerid, "这是值班管理员!你无法追踪他们的接近程度." );
	else
	{
	    new
			szLocation[ MAX_ZONE_NAME ], szCity[ MAX_ZONE_NAME ];

		if ( ! GetPlayerLocation( pID, szCity, szLocation ) )
			return SendError( playerid, "该玩家已完全消失在雷达之下." );

		SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[位置]"COL_WHITE" %s(%d) 位于附近%s在%s!", ReturnPlayerName( pID ), pID, GetLocationDisplayName(szLocation), GetLocationDisplayName(szCity) );
	}
	return 1;
}

CMD:sh( playerid, params[ ] ) return cmd_search( playerid, params );
CMD:search( playerid, params[ ] )
{
	/* ** ANTI SPAM ** */
    if ( p_SearchedCountTick[ playerid ] > g_iTime ) return SendError( playerid, "再次使用此命令之前,你必须等待 2 分钟." );
    /* ** END OF ANTI SPAM ** */

   	new
   	    pID
	;
	if ( p_Class[ playerid ] != CLASS_POLICE ) return SendError( playerid, "此功能仅限警察使用." );
	else if ( sscanf( params, "u", pID ) ) return SendUsage( playerid, "/search [PLAYER_ID]" );
	else if ( GetDistanceBetweenPlayers( playerid, pID ) > 10.0 || !IsPlayerConnected( pID ) ) return SendError( playerid, "该玩家不在附近." );
	else if ( p_Class[ pID ] == CLASS_POLICE ) return SendError( playerid, "此玩家与你同阵营!" );
	else if ( IsPlayerInBattleRoyale( playerid ) ) return SendError( playerid, "大逃杀中无法使用此命令." );
	else if ( !IsPlayerCuffed( pID ) ) return SendError( playerid, "该玩家必须被铐住." );
	else if ( IsPlayerJailed( pID ) ) return SendError( playerid, "你不能 " );
	else
	{
	    new
	    	wantedlvl = p_WeedGrams[ pID ] * 6;

		p_SearchedCountTick[ playerid ] = g_iTime + 120;

		if ( wantedlvl <= 0 )
		{
			SendClientMessageFormatted( pID, -1, ""COL_RED"[搜查]{FFFFFF} %s(%d) 已对你进行了搜查,幸运的是没有发现毒品!", ReturnPlayerName( playerid ), playerid );
		    SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[搜查]{FFFFFF} 你已搜索 %s(%d) 并没有找到毒品!", ReturnPlayerName( pID ), pID, p_WeedGrams[ pID ] );
	    	return 1;
		}

		SendClientMessageFormatted( pID, -1, ""COL_RED"[搜查]{FFFFFF} 你已按 %s(%d) 进行搜索,并且已将你的毒品移除!", ReturnPlayerName( playerid ), playerid );
	    SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[搜查]{FFFFFF} 你已搜索 %s(%d) 并找到 %d 克 "COL_GREEN"大麻{FFFFFF}!", ReturnPlayerName( pID ), pID, p_WeedGrams[ pID ] );

	  	p_WeedGrams[ pID ] = 0;
		GivePlayerWantedLevel( pID, wantedlvl );
	}
	return 1;
}

CMD:rob( playerid, params[ ] )
{
	/* ** ANTI ROB SPAM ** */
    if ( ( GetTickCount( ) - p_AntiRobSpam[ playerid ] ) < 90000 ) return SendError( playerid, "上次你抢劫别人后你太累了......" );
    /* ** END OF ANTI SPAM ** */

  	new victimid = GetClosestPlayer( playerid );
    if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "此功能仅限平民使用." );
    else if ( p_Spectating{ playerid } ) return SendError( playerid, "旁观时无法使用此类命令." );
	//else if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "It's impossible to rob someone inside a car." );
	else if ( GetDistanceBetweenPlayers( playerid, victimid ) < 4.0 && IsPlayerConnected( victimid ) )
	{

  		//if ( IsPlayerInAnyVehicle( victimid ) && !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "This player is in a vehicle and you're not." );
		//if ( IsPlayerInAnyVehicle( playerid ) && !IsPlayerInAnyVehicle( victimid ) ) return SendError( playerid, "You cannot rob someone while you're a vehicle and they're not." );
		//if ( IsPlayerInAnyVehicle( playerid ) && IsPlayerInAnyVehicle( victimid ) && !IsPlayerKidnapped( victimid ) ) return SendError( playerid, "The person in your vehicle must be kidnapped to rob them." );
        if ( IsPlayerInAnyVehicle( victimid ) ) return SendError( playerid, "该玩家在车辆中." );
		else if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "在载具内无法使用此命令." );
		else if ( GetPlayerCash( victimid ) < 10 ) return SendError( playerid, "该玩家不能被抢劫,因为他的钱很少." );
		else if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "在监狱中无法使用此命令." );
		else if ( IsPlayerTazed( playerid ) ) return SendError( playerid, "被电击时无法使用此命令." );
		//if ( IsPlayerDetained( playerid ) ) return SendError( playerid, "You cannot use this command since you're detained." );
		else if ( IsPlayerCuffed( playerid ) ) return SendError( playerid, "被铐住时无法使用此命令." );
		else if ( IsPlayerTied( playerid ) ) return SendError( playerid, "被捆绑时无法使用此命令." );
		else if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "被绑架时无法使用此命令." );
		else if ( IsPlayerInMinigame( playerid ) ) return SendError( playerid, "由于你处于小游戏中,因此无法使用此命令." );
		else if ( IsPlayerGettingBlowed( playerid ) ) return SendError( playerid, "接受口交时无法使用此命令." );
		else if ( IsPlayerBlowingCock( playerid ) ) return SendError( playerid, "进行口交时无法使用此命令." );
		else if ( IsPlayerAdminOnDuty( victimid ) ) return SendError( playerid, "无法对值勤中的管理员使用此命令." );
		else if ( IsPlayerJailed( victimid ) ) return SendError( playerid, "此玩家已入狱, 可能处于暂停状态." );
		else if ( IsPlayerInCasino( victimid ) && ! p_WantedLevel[ victimid ] ) return SendError( playerid, "你想要抢劫的无辜者在赌场里." );
		else if ( p_ClassSelection{ victimid } ) return SendError( playerid, "该玩家当前正在进行职业选择." );
		else if ( IsPlayerInPlayerGang( playerid, victimid ) ) return SendError( playerid, "你不能对你的兄弟使用这个命令!" );

		// event check
		#if defined __cloudy_event_system
		if ( IsPlayerInEvent( playerid ) && ! EventSettingAllow( EVENT_SETTING_ROB ) )
		#else
		if ( IsPlayerInEvent( playerid ) )
		#endif
		{
			return SendError( playerid, "参加活动时无法使用此命令." );
		}

		new
			iRandom = random( 101 );

		// secure wallet means robberies are prevented
		if ( p_SecureWallet{ victimid } ) {
			iRandom = 100;
		}

		if ( iRandom < 75 || IsPlayerTied( victimid ) || IsPlayerKidnapped( victimid ) )
		{
		    new
				iMoney,
				cashRobbed,
		    	iLimit = 3000
			;

			if ( IsPlayerJob( playerid, JOB_MUGGER ) ) {
				iLimit *= 2; // double the mugging capacity if a mugger
			}

			if ( IsPlayerKidnapped( victimid ) ) {
				iLimit *= 2; // double the robbing capacity if kidnapped
			}

			iMoney = GetPlayerCash( victimid ) > iLimit ? iLimit : GetPlayerCash( victimid );

			cashRobbed = random( iMoney ) + 10;

			SendClientMessageFormatted( victimid, -1, ""COL_RED"[抢劫]{FFFFFF} 你被抢劫了 "COL_GOLD"%s{FFFFFF} 由 %s(%d)!", cash_format( cashRobbed ), ReturnPlayerName( playerid ), playerid );
		    SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[抢劫]{FFFFFF} 你抢劫了 "COL_GOLD"%s{FFFFFF} 关闭 %s(%d)!", cash_format( cashRobbed ), ReturnPlayerName( victimid ), victimid );

			SplitPlayerCashForGang( playerid, float( cashRobbed ) );
			GivePlayerWantedLevel( playerid, 4 );
			GivePlayerCash( victimid, -( cashRobbed ) );
			GivePlayerScore( playerid, 1 );
			GivePlayerExperience( playerid, E_ROBBERY );
		}
		else
		{
			SendClientMessageFormatted( playerid, -1, ""COL_RED"[抢劫失败]{FFFFFF} 你抢劫 %s(%d) 失败!", ReturnPlayerName( victimid ), victimid );
            SendClientMessageFormatted( victimid, -1, ""COL_GREEN"[抢劫失败]{FFFFFF} %s(%d) 未能抢劫你!", ReturnPlayerName( playerid ), playerid );
			GivePlayerWantedLevel( playerid, 6 );
		}
		p_AntiRobSpam[ playerid ] = GetTickCount( );
 	}
    else return SendError( playerid, "周围没有玩家可以抢劫." );
	return 1;
}

CMD:rape( playerid, params[ ] )
{
	/* ** ANTI ROB SPAM ** */
    if ( p_AntiRapeSpam[ playerid ] > g_iTime ) return SendError( playerid, "你的鸡巴因为上次你强奸某人而受伤......" );
    /* ** END OF ANTI SPAM ** */

  	new victimid = GetClosestPlayer( playerid ), Float: Health;
    if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "此功能仅限平民使用." );
    else if ( p_Spectating{ playerid } ) return SendError( playerid, "旁观时无法使用此类命令." );
	//else if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "It's impossible to rape someone inside a car." );
	else if ( GetDistanceBetweenPlayers( playerid, victimid ) < 4.0 && IsPlayerConnected( victimid ) )
	{
  		//if ( IsPlayerInAnyVehicle( victimid ) && !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "This player is in a vehicle and you're not." );
		//if ( IsPlayerInAnyVehicle( playerid ) && !IsPlayerInAnyVehicle( victimid ) ) return SendError( playerid, "You cannot rape someone while you're a vehicle and they're not." );
		//if ( IsPlayerInAnyVehicle( playerid ) && IsPlayerInAnyVehicle( victimid ) && !IsPlayerKidnapped( victimid ) ) return SendError( playerid, "The person in your vehicle must be kidnapped to rape them." );
        if ( IsPlayerInAnyVehicle( victimid ) ) return SendError( playerid, "该玩家在车辆中." );
		else if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "在载具内无法使用此命令." );
		else if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "在监狱中无法使用此命令." );
		else if ( IsPlayerTazed( playerid ) ) return SendError( playerid, "被电击时无法使用此命令." );
		//if ( IsPlayerDetained( playerid ) ) return SendError( playerid, "You cannot use this command since you're detained." );
		else if ( IsPlayerCuffed( playerid ) ) return SendError( playerid, "被铐住时无法使用此命令." );
		else if ( IsPlayerTied( playerid ) ) return SendError( playerid, "被捆绑时无法使用此命令." );
		else if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "被绑架时无法使用此命令." );
		else if ( IsPlayerInMinigame( playerid ) ) return SendError( playerid, "由于你处于小游戏中,因此无法使用此命令." );
		else if ( p_Jailed{ playerid } == true ) return SendError( playerid, "你不能在监狱里强奸." );
		else if ( IsPlayerGettingBlowed( playerid ) ) return SendError( playerid, "接受口交时无法使用此命令." );
		else if ( IsPlayerBlowingCock( playerid ) ) return SendError( playerid, "进行口交时无法使用此命令." );
		else if ( IsPlayerAdminOnDuty( victimid ) ) return SendError( playerid, "无法对值勤中的管理员使用此命令." );
		else if ( IsPlayerJailed( victimid ) ) return SendError( playerid, "此玩家已入狱, 可能处于暂停状态." );
		else if ( IsPlayerInCasino( victimid ) && ! p_WantedLevel[ victimid ] ) return SendError( playerid, "你想要强奸的无辜者在赌场里." );
		else if ( IsPlayerLoadingObjects( victimid ) ) return SendError( playerid, "此玩家正在加载地图物体." );
		else if ( IsPlayerSpawnProtected( victimid ) ) return SendError( playerid, "该玩家处于反生成杀死状态." );
		else if ( p_ClassSelection{ victimid } ) return SendError( playerid, "该玩家当前正在进行职业选择." );
		else if ( IsPlayerAFK( victimid ) && GetPlayerState( playerid ) != PLAYER_STATE_WASTED ) return SendError( playerid, "该玩家处于 AFK 状态." );
		else if ( IsPlayerInPlayerGang( playerid, victimid ) ) return SendError( playerid, "你不能对你的兄弟使用这个命令!" );

		// event check
		#if defined __cloudy_event_system
		if ( IsPlayerInEvent( playerid ) && ! EventSettingAllow( EVENT_SETTING_RAPE ) )
		#else
		if ( IsPlayerInEvent( playerid ) )
		#endif
		{
			return SendError( playerid, "参加活动时无法使用此命令." );
		}

  		new iRandom = random( 101 );
        if ( IsPlayerJob( playerid, JOB_MUGGER ) ) { iRandom += 10; } // Adds more success to muggers
  		if ( iRandom < 75 || IsPlayerTied( victimid ) )
  		{
			if ( p_InfectedHIV{ playerid } || ( IsPlayerJob( playerid, JOB_MUGGER ) && p_AidsVaccine{ victimid } == false && !IsPlayerJob( victimid, JOB_MUGGER ) ) )
			{
			    SendClientMessageFormatted( victimid, -1, ""COL_RED"[强奸]{FFFFFF} 你被强奸并感染了 "COL_RED"HIV{FFFFFF} 由 %s(%d) 感染!", ReturnPlayerName( playerid ), playerid );
                SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[强奸]{FFFFFF} 你强奸了 %s(%d) 并感染了他们 "COL_RED"艾滋病毒{FFFFFF}!", ReturnPlayerName( victimid ), victimid );
			    GivePlayerScore( playerid, 2 );
			    GivePlayerWantedLevel( playerid, 5 );
			    GetPlayerHealth( victimid, Health );
			  	SetPlayerHealth( victimid,  ( Health - 25.0 ) );

			    p_InfectedHIV{ victimid } = true;
				SetTimerEx( "RapeDamage", 5000, false, "d", victimid );
			}
			else
			{
			    SendClientMessageFormatted( victimid, -1, ""COL_RED"[强奸]{FFFFFF} 你被%s(%d) 强奸了!", ReturnPlayerName( playerid ), playerid );
                SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[强奸]{FFFFFF} 你强奸了 %s(%d)!", ReturnPlayerName( victimid ), victimid );
			    GivePlayerScore( playerid, 1 );
			    GivePlayerWantedLevel( playerid, 4 );
			    GetPlayerHealth( victimid, Health );
			  	SetPlayerHealth( victimid,  ( Health - 25.0 ) );
			}
		}
		else
		{
			SendClientMessageFormatted( playerid, -1, ""COL_RED"[强奸失败]{FFFFFF} 你未能强奸 %s(%d)!", ReturnPlayerName( victimid ), victimid );
            SendClientMessageFormatted( victimid, -1, ""COL_GREEN"[强奸失败]{FFFFFF} %s(%d) 未能强奸你!", ReturnPlayerName( playerid ), playerid );
	    	GivePlayerWantedLevel( playerid, 6 );
		}
		p_AntiRapeSpam[ playerid ] = g_iTime + 60;
 	}
    else return SendError( playerid, "周围没有玩家可以强奸." );
	return 1;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	new
		iModel = GetVehicleModel( vehicleid ),
    	driverid = GetVehicleDriver( vehicleid )
    ;


	if ( !ispassenger )
	{
		new
			iObject = GetGVarInt( "heli_gunner", vehicleid );

		if ( !iObject && ( iModel == 487 || iModel == 497 ) ) { // Chopper gunner!
			SetGVarInt( "heli_gunner", CreateDynamicObject( 19464, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 ), vehicleid );
			SetObjectInvisible( GetGVarInt( "heli_gunner", vehicleid ) );
			AttachDynamicObjectToVehicle( GetGVarInt( "heli_gunner", vehicleid ), vehicleid, 0.0, 0.3, -1.75, 0.0, 90.0, 0.0 );
		}

		else if ( iObject && !( iModel == 487 || iModel == 497 ) ) { // An issue, not a maverick but has maverick thing.
			DestroyDynamicObject( iObject );
			DeleteGVar( "heli_gunner", vehicleid );
		}

    	// Stop player team jacking
    	/*if ( driverid != INVALID_PLAYER_ID && p_Class[ playerid ] != CLASS_CIVILIAN && p_Class[ playerid ] == p_Class[ driverid ] )
    		SyncObject( playerid ), GameTextForPlayer( playerid, "~r~Don't jack your teammates~w~!", 2000, 4 );*/

		p_LastVehicle[ playerid ] = vehicleid;
	}
	else
    {
		// Enter a wanted players vehicle?
    	if ( driverid != INVALID_PLAYER_ID && !p_WantedLevel[ playerid ] && p_Class[ playerid ] != CLASS_POLICE )
    	{
    		if ( p_WantedLevel[ driverid ] > 1 )
    			GivePlayerWantedLevel( playerid, 2 );

    		else if ( p_WantedLevel[ driverid ] > 5 )
    			GivePlayerWantedLevel( playerid, 6 );

    		else if ( p_WantedLevel[ driverid ] > 11 )
    			GivePlayerWantedLevel( playerid, 12 );
    	}
    }

	if ( IsPlayerAttachedObjectSlotUsed( playerid, 0 ) ) // [PRO_LIZZY] Once you enter a vehicle, and cancel entering, no animation is applied.
	    CallLocalFunction( "OnPlayerKeyStateChange", "ddd", playerid, KEY_CROUCH, KEY_SPRINT );

	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	new
		iModel = GetVehicleModel( vehicleid ),
		iObject = GetGVarInt( "heli_gunner", vehicleid )
	;

	if ( GetPlayerState( playerid ) == PLAYER_STATE_DRIVER )
	{
		if ( iObject && ( iModel == 487 || iModel == 497 ) )
		{
			DestroyDynamicObject( iObject );
			DeleteGVar( "heli_gunner", vehicleid );
		}

		p_LastAttachedVehicle[ playerid ] = INVALID_VEHICLE_ID;
	}
	return 1;
}

public OnVehicleDamageStatusUpdate( vehicleid, playerid )
{
	return 1;
}

public OnPlayerDriveVehicle( playerid, vehicleid )
{
	new
	    model = GetVehicleModel( vehicleid ),
	    time = g_iTime
	;

	if ( IsPlayerUsingAnimation( playerid ) ) // cancel animations
   		CallLocalFunction( "OnPlayerKeyStateChange", "ddd", playerid, KEY_SPRINT, KEY_SECONDARY_ATTACK );

	if ( p_Cuffed{ playerid } ) {
        RemovePlayerFromVehicle( playerid );
        return 1;
	}

	if ( ! g_Driveby ) {
		SetPlayerArmedWeapon( playerid, 0 );
	}

	if ( IsPlayerInPoliceCar( playerid ) && p_Class[ playerid ] != CLASS_POLICE && p_LastDrovenPoliceVeh[ playerid ] != vehicleid && GetPVarInt( playerid, "entercopcar_ts" ) < time && !g_buyableVehicle{ vehicleid } && ! g_gangVehicle{ vehicleid } ) {
		if ( ! IsWeaponInAnySlot( playerid, 26 ) && ! IsWeaponInAnySlot( playerid, 27 ) ) GivePlayerWeapon( playerid, 25, 25 ); // free shotgun
		SetPVarInt( playerid, "entercopcar_ts", time + 30 );
		GivePlayerWantedLevel( playerid, 2 );
	}

	if ( model == 525 ) {
		ShowPlayerHelpDialog( playerid, 2500, "你可以按 ~k~~VEHICLE_FIREWEAPON_ALT~ 来拖车!" );
	}


	p_LastDrovenPoliceVeh[ playerid ] = vehicleid;

	if ( p_AdminLevel[ playerid ] < 3 )
	{
		if ( p_inArmy{ playerid } == false )
		{
		    if ( model == 520 || model == 425 || model == 432 )
		    {
				SyncObject( playerid, 1 );
			    //RemovePlayerFromVehicle( playerid );
			    SendError( playerid, "军队仅被授权使用此功能." );
			    return 1;
			}
		}
	}
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	if ( IsPlayerNPC( playerid ) )
		return 1; // fcnpc

	new
		vID = GetPlayerVehicleID( playerid );

	p_LastPlayerState{ playerid } = oldstate;

    if ( oldstate == PLAYER_STATE_SPECTATING )
    {
    	ResetPlayerWeapons( playerid );
        for( new i; i < sizeof( p_SpectateWeapons[ ] ); i++ )
        {
        	GivePlayerWeapon( playerid, p_SpectateWeapons[ playerid ] [ i ] [ 0 ], p_SpectateWeapons[ playerid ] [ i ] [ 1 ] );
        	p_SpectateWeapons[ playerid ] [ i ] [ 0 ] = 0, p_SpectateWeapons[ playerid ] [ i ] [ 1 ] = 0;
        }
    }

	if ( newstate == PLAYER_STATE_DRIVER ) {
		CallLocalFunction( "OnPlayerDriveVehicle", "dd", playerid, vID );
	}

	//if ( newstate == PLAYER_STATE_ONFOOT && p_Detained{ playerid } == true && IsPlayerConnected( p_DetainedBy[ playerid ] ) )
	//    return PutPlayerInEmptyVehicleSeat( p_LastVehicle[ p_DetainedBy[ playerid ] ], playerid );

	if ( newstate == PLAYER_STATE_PASSENGER )
	{
		if ( hasBadDrivebyWeapon( playerid ) ) // Some weapons are abusable.
			SetPlayerArmedWeapon( playerid, 0 );
	}
	return SyncSpectation( playerid, newstate );
}

public OnPlayerLeaveDynamicCP( playerid, checkpointid )
{
	return 1;
}

public OnPlayerEnterDynamicCP( playerid, checkpointid )
{
	static
		aPlayer[ 1 ];

	aPlayer[ 0 ] = playerid;

	// Refill ammunition
	if ( checkpointid == g_Checkpoints[ CP_REFILL_AMMO ] || checkpointid == g_Checkpoints[ CP_REFILL_AMMO_LS ] || checkpointid == g_Checkpoints[ CP_REFILL_AMMO_LV ] ) {
		if ( p_Class[ playerid ] == CLASS_POLICE ) {
			if ( g_iTime < p_CopRefillTimestamp[ playerid ] ) {
				return SendError( playerid, "你必须等待 %s 才能再次填充你的武器.", secondstotime( p_CopRefillTimestamp[ playerid ] - g_iTime ) );
			} else {
				GivePlayerLeoWeapons( playerid );
				p_CopRefillTimestamp[ playerid ] = g_iTime + 300;
				return SendServerMessage( playerid, "你已经重新装满了你的弹药." );
			}
		} else {
			return SendError( playerid, "只有执法人员才能使用此功能." );
		}
	}

	if ( checkpointid == g_Checkpoints[ CP_REWARDS_4DRAG ] || checkpointid == g_Checkpoints[ CP_REWARDS_CALIG ] || checkpointid == g_Checkpoints[ CP_REWARDS_VISAGE ] )
		return ShowPlayerRewardsMenu( playerid );

	if ( checkpointid == g_Checkpoints[ CP_BANK_MENU ] || checkpointid == g_Checkpoints[ CP_COUNTRY_BANK_MENU ] || checkpointid == g_Checkpoints[ CP_BANK_MENU_LS ] )
	{
		new
			in_lvbank = GetPlayerVirtualWorld( playerid ) == GetBankVaultWorld( CITY_LV ) && GetPlayerInterior( playerid ) == 1;

		if ( checkpointid == g_Checkpoints[ CP_BANK_MENU ] && g_bankvaultData[ CITY_SF ] [ E_TIMESTAMP ] > g_iTime ) {
			return SendError( playerid, "这家银行最近被抢劫了,你无法访问 %s 的终端.", secondstotime( g_bankvaultData[ CITY_SF ] [ E_TIMESTAMP ] - GetServerTime( ) ) );
		}
		else if ( checkpointid == g_Checkpoints[ CP_BANK_MENU_LS ] && ( ( ! in_lvbank && g_bankvaultData[ CITY_LS ] [ E_TIMESTAMP ] > g_iTime ) || ( in_lvbank && g_bankvaultData[ CITY_LV ] [ E_TIMESTAMP ] > g_iTime ) ) ) {
			return SendError( playerid, "这家银行最近被抢劫了,你无法访问 %s 的终端.", secondstotime( g_bankvaultData[ in_lvbank ? CITY_LV : CITY_LS ] [ E_TIMESTAMP ] - GetServerTime( ) ) );
		}
		else {
 			return ShowPlayerBankMenuDialog( playerid ), 1;
		}
	}

 	if ( checkpointid == g_Checkpoints[ CP_CASINO_BAR ] )
        return ShowPlayerDialog( playerid, DIALOG_CASINO_BAR, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}赌场酒吧", ""COL_WHITE"酒吧物品\t"COL_WHITE"赌场奖励积分\n啤酒\t"COL_GOLD"20.0 积分\n雪茄\t"COL_GOLD"20.0 积分\n 酒\t"COL_GOLD"20.0 点", "买", "关闭" ), 1;

	if ( checkpointid == g_Checkpoints[ CP_CHANGE_JOB ] )
        return ShowPlayerDialog( playerid, DIALOG_CITY_HALL, DIALOG_STYLE_LIST, "{FFFFFF}市政厅", ""COL_GOLD"$5,000"COL_WHITE"\t\t换工作\n"COL_GOLD"自由的"COL_WHITE"\t\t改变城市", "选择", "关闭" ), 1;

	if ( checkpointid == g_Checkpoints[ CP_HOSPITAL ] || checkpointid == g_Checkpoints[ CP_HOSPITAL_LV ] || checkpointid == g_Checkpoints[ CP_HOSPITAL1_LS ] || checkpointid == g_Checkpoints[ CP_HOSPITAL2_LS ] || checkpointid == g_Checkpoints[ CP_HOSPITAL_FC ] )
		return ShowPlayerDialog( playerid, DIALOG_HOSPITAL, DIALOG_STYLE_LIST, "{FFFFFF}医疗中心", ""COL_GOLD"$2,000"COL_WHITE"\t\t治愈自己\n"COL_GOLD"$4,000"COL_WHITE"\t\t治愈自己\n"COL_GOLD"$6,000"COL_WHITE"\t\t治愈和治愈", "选择", "关闭" ), 1;

	if ( checkpointid == g_Checkpoints[ CP_AIRPORT_LV ] || checkpointid == g_Checkpoints[ CP_AIRPORT_SF ] || checkpointid == g_Checkpoints[ CP_AIRPORT_LS ] )
		return ShowPlayerAirportMenu( playerid );

	if ( checkpointid == g_Checkpoints[ CP_BIZ_TERMINAL_COKE ] || checkpointid == g_Checkpoints[ CP_BIZ_TERMINAL_METH ] || checkpointid == g_Checkpoints[ CP_BIZ_TERMINAL_WEED ] || checkpointid == g_Checkpoints[ CP_BIZ_TERMINAL_WEAP ] )
		return ShowBusinessTerminal( playerid );

	if ( checkpointid == g_Checkpoints[ CP_247_MENU ] )
		return cmd_shop( playerid, "" );

	new
		houseid = p_InHouse[ playerid ];

	if ( houseid != -1 && GetPlayerInterior( playerid ) == g_houseData[ houseid ] [ E_INTERIOR_ID ] && checkpointid != g_houseData[ houseid ] [ E_CHECKPOINT ] [ 1 ] ) {
		return SetPlayerPos( playerid, g_houseData[ houseid ] [ E_TX ], g_houseData[ houseid ] [ E_TY ], g_houseData[ houseid ] [ E_TZ ] );
	}

	if ( checkpointid == g_Checkpoints[ CP_FIGHTSTYLE ] || checkpointid == g_Checkpoints[ CP_FIGHTSTYLE_LV ] || checkpointid == g_Checkpoints[ CP_FIGHTSTYLE_LS ] )
	{
	    ShowPlayerDialog( playerid, DIALOG_FIGHTSTYLE, DIALOG_STYLE_LIST, "{FFFFFF}战斗风格", ""COL_GOLD"$1000{FFFFFF} \t防御\n"COL_GOLD"$4000{FFFFFF} \t拳击\n"COL_GOLD"$9000{FFFFFF} \t功夫", "购买", "取消" );
	    return 1;
	}

	if ( checkpointid == g_Checkpoints[ CP_AMMUNATION_0 ] || checkpointid == g_Checkpoints[ CP_AMMUNATION_1 ] || checkpointid == g_Checkpoints[ CP_AMMUNATION_2 ] )
    	return ShowAmmunationMenu( playerid );

	if ( checkpointid == g_Checkpoints[ CP_PAINTBALL ] )
		return listPaintBallLobbies( playerid );

	return 1;
}

public OnPlayerAccessEntrance( playerid, entranceid, worldid, interiorid )
{
    if ( g_entranceData[ entranceid ] [ E_VIP ] && p_VIPLevel[ playerid ] < VIP_REGULAR ) {
        return SendError( playerid, "你还不是 VIP, 请前往以下地址开通: "COL_GREY"donate.sfcnr.com" ), 0;
    }

    // robbery helper
	if ( p_Class[ playerid ] != CLASS_POLICE )
	{
		// check if robbery is a bank
		if ( ( worldid == GetBankVaultWorld( CITY_SF ) || worldid == GetBankVaultWorld( CITY_LS ) || worldid == GetBankVaultWorld( CITY_LV ) ) && interiorid < 3 )
		{
			new
				iCity;

			for( iCity = 0; iCity < sizeof( g_bankvaultData ); iCity ++ ) if ( worldid == g_bankvaultData[ iCity ] [ E_WORLD ] ) {
				break;
			}

			if ( g_bankvaultData[ iCity ] [ E_TIMESTAMP ] < g_iTime && ! g_bankvaultData[ iCity ] [ E_DISABLED ] ) {
				ShowPlayerHelpDialog( playerid, 5000, "此~g~~h~银行~w~~h~可以实施抢劫." );
			} else {
				ShowPlayerHelpDialog( playerid, 5000, "这家银行~r~~h~无法进行抢劫." );
			}
		}
		else
		{
			p_SafeHelperTimer[ playerid ] = SetTimerEx( "OnSafeHelperUpdate", 500, false, "dd", playerid, GetEntranceClosestRobberySafe( entranceid ) );
		}
	}
    return 1;
}

public OnPlayerEnterDynamicArea( playerid, areaid )
{
    return 1;
}

public OnPlayerEnterDynamicRaceCP( playerid, checkpointid )
{
	return 1;
}

public OnRconCommand(cmd[])
{
	return 1;
}

public OnPlayerRequestSpawn( playerid )
{
	return 1;
}

public OnObjectMoved(objectid)
{
	return 1;
}

public OnPlayerObjectMoved(playerid, objectid)
{
	return 1;
}

public OnPlayerClickTextDraw(playerid, Text: clickedid)
{
	return 1;
}

public OnPlayerClickPlayerTextDraw(playerid, PlayerText: playertextid)
{
    return 1;
}

public OnVehicleMod( playerid, vehicleid, componentid )
{
	return 1;
}

public OnEnterExitModShop( playerid, enterexit, interiorid )
{
	return 1;
}

public OnVehiclePaintjob( playerid, vehicleid, paintjobid )
{
	// GivePlayerCash( playerid, -500 );
	return 1;
}

public OnVehicleRespray( playerid, vehicleid, color1, color2 )
{
	return 1;
}

public OnPlayerSelectedMenuRow( playerid, row )
{
	return 1;
}

public OnPlayerExitedMenu( playerid )
{
	return 1;
}

public OnPlayerInteriorChange( playerid, newinteriorid, oldinteriorid )
{
	SyncSpectation( playerid );
	return 1;
}

function OnSafeHelperUpdate( playerid, robberyid )
{
	new
		Float: distance = distanceFromSafe( playerid, robberyid );

	if ( robberyid == INVALID_OBJECT_ID || distance > 100.0 || ! IsPlayerConnected( playerid ) || ! IsPlayerSpawned( playerid ) || IsPlayerInCasino( playerid ) || IsPlayerPlayingPool( playerid ) )
	{
		p_SafeHelperTimer[ playerid ] = -1;
		HidePlayerHelpDialog( playerid );
		return 0;
	}

	if ( g_robberyData[ robberyid ] [ E_ROBBED ] )
	{
		p_SafeHelperTimer[ playerid ] = -1;
		ShowPlayerHelpDialog( playerid, 5000, "这家商店目前~r~~h~不可抢劫.~w~~h~~n~~n~稍后再回来." );
		return 0;
	}

	if ( 0.0 < distance < 2.0 )
	{
		p_SafeHelperTimer[ playerid ] = -1;
		ShowPlayerHelpDialog( playerid, 7500, "太棒了,你已经~g~~h~找到了保险箱.~w~~h~~n~~n~要抢劫保险箱,请按~r~~h~左Alt~w~~h~键." );
		return 1;
	}

	ShowPlayerHelpDialog( playerid, 0, "要抢劫商店,请先找到保险箱.~n~~n~你距离这里的保险箱 ~g~~h~%0.2fm~w~~h~.", distance );
	return ( p_SafeHelperTimer[ playerid ] = SetTimerEx( "OnSafeHelperUpdate", 500, false, "dd", playerid, robberyid ) );
}

public OnPlayerArrested( playerid, victimid, totalarrests, totalpeople )
{
	new
		iBefore = p_Arrests[ playerid ],
		iAfter 	= ( p_Arrests[ playerid ] += totalpeople )
	;

	Streak_IncrementPlayerStreak( playerid, STREAK_ARREST );

	if ( iBefore < 1000 && iAfter >= 1000 )	   ShowAchievement( playerid, "逮捕~r~1000~w~~h~~h~罪犯!", 25 );
	else if ( iBefore < 500 && iAfter >= 500 ) ShowAchievement( playerid, "逮捕~r~500~w~~h~~h~罪犯!", 18 );
	else if ( iBefore < 200 && iAfter >= 200 ) ShowAchievement( playerid, "逮捕~r~200~w~~h~~h~罪犯!", 15 );
	else if ( iBefore < 100 && iAfter >= 100 ) ShowAchievement( playerid, "逮捕~r~100~w~~h~~h~罪犯!", 12 );
	else if ( iBefore < 50  && iAfter >= 50 )  ShowAchievement( playerid, "逮捕~r~50~w~~h~~h~罪犯!", 9 );
	else if ( iBefore < 20  && iAfter >= 20 )  ShowAchievement( playerid, "逮捕~r~20~w~~h~~h~罪犯!", 6 );
	else if ( iBefore < 5   && iAfter >= 5 )   ShowAchievement( playerid, "逮捕~r~5~w~~h~~h~罪犯!", 3 );
	return 1;
}

public OnPlayerKeyStateChange( playerid, newkeys, oldkeys )
{
	static
		Float: X, Float: Y, Float: Z, Float: Angle;

	new
 		iVehicle = GetPlayerVehicleID( playerid ),
		iWeapon = GetPlayerWeapon( playerid )
	;

	if ( HOLDING( KEY_SPRINT ) && HOLDING( KEY_WALK ) && IsPlayerUsingRadio( playerid ) )
		StopAudioStreamForPlayer( playerid );

    if ( PRESSED( KEY_JUMP ) && GetPlayerSpecialAction( playerid ) == SPECIAL_ACTION_CUFFED )
 		ApplyAnimation( playerid, "GYMNASIUM", "gym_jog_falloff", 4.1, 0, 1, 1, 0, 0 );

 	// Spectation
	if ( p_Spectating{ playerid } == true )
	{
		if ( PRESSED( KEY_WALK ) )
		{
			new spectatingid = p_whomSpectating[ playerid ];
			new targetid = p_PlayerAltBind[ playerid ];

			if ( targetid != -1 )
			{
				static
					Float: sX, Float: sY, Float: sZ;

				GetPlayerPos( spectatingid, sX, sY, sZ );
				GetPlayerPos( targetid, X, Y, Z );

				Angle = atan2( sY - Y, sX - X ) - 90.0;

				if ( Angle == -90.0 ) {
					SendError( playerid, "你没有正确设置瞄准 alt 绑定的玩家." );
				} else {
					SendServerMessage( playerid, "从战斗位置移动 %0.2f 度.", Angle );
				}

			    X += 4.0 * floatsin( Angle + 90.0, degrees );
			    Y += 4.0 * -floatcos( Angle + 90.0, degrees );

				SetPlayerPos( targetid, X, Y, Z );
				p_PlayerAltBindTick[ targetid ] = GetTickCount( );
			}
		}

	    if ( PRESSED( KEY_FIRE ) )
	    {
			for( new i = p_whomSpectating[ playerid ] + 1; i < MAX_PLAYERS; i++ )
			{
				if ( IsPlayerConnected( i ) && IsPlayerSpawned( i ) && !p_Spectating{ i } && i != playerid )
				{
					ForceSpectateOnPlayer( playerid, i );
					p_AlcatrazSpec[ playerid ] = g_iTime + 10;
					break;
				}
			}
	    }
	    else if ( PRESSED( KEY_AIM ) )
	    {
			for( new i = p_whomSpectating[ playerid ] - 1; i > -1; i-- )
			{
				if ( IsPlayerConnected( i ) && IsPlayerSpawned( i ) && !p_Spectating{ i } && i != playerid )
				{
					ForceSpectateOnPlayer( playerid, i );
					p_AlcatrazSpec[ playerid ] = g_iTime + 10;
					break;
				}
			}
	    }
	    return 1;
	}

 	// Explosive Bullets
 	if ( p_ExplosiveBullets[ playerid ] > 0 && PRESSED( KEY_NO ) ) {
 		if ( GetPVarInt( playerid, "explosive_rounds" ) == 1 ) {
 			DeletePVar( playerid, "explosive_rounds" );
            ShowPlayerHelpDialog( playerid, 2000, "爆炸弹~r~禁用." );
 		} else {
 			SetPVarInt( playerid, "explosive_rounds", 1 );
            ShowPlayerHelpDialog( playerid, 2000, "爆炸弹~r~启用." );
 		}
 	}

	// Hunter Kill Detection
	if ( iVehicle && IsValidVehicle( iVehicle ) )
	{
		new
			modelid = GetVehicleModel( iVehicle );

		if ( ( modelid == 425 && ( HOLDING( KEY_ACTION ) || PRESSED( KEY_FIRE ) ) ) || ( ( modelid == 520 || modelid == 447 || modelid == 476 ) && HOLDING( KEY_ACTION ) ) )
		{
			new
				closest_vehicle = GetClosestVehicle( playerid, iVehicle );

			if ( closest_vehicle != INVALID_VEHICLE_ID )
			{
				static
					Float: tX, Float: tY, Float: tZ;

				GetVehiclePos( iVehicle, X, Y, Z );
				GetVehiclePos( closest_vehicle, tX, tY, tZ );

				if ( VectorSize( tX - X, tY - Y, tZ - Z ) < 80.0 )
				{
					new
						Float: facingAngle,
						Float: angle = atan2( tY - Y, tX - X ) - 90.0
					;

					// addresses a small bug
					if ( angle < 0.0 )
						angle += 360.0;

					GetVehicleZAngle( iVehicle, facingAngle );

					// check if player is facing vehicle
					if ( floatabs( facingAngle - angle ) < 17.5 ) { // 15m radius

						g_VehicleLastAttacker[ closest_vehicle ] = playerid;
						g_VehicleLastAttacked[ closest_vehicle ] = g_iTime;

						// anticipate a kill in the vehicle too
						foreach (new i : Player) if ( GetPlayerVehicleID( i ) == closest_vehicle )
						{
							// give wanted to attacking people (attackers of leo)
							if ( p_Class[ playerid ] != CLASS_POLICE && p_WantedLevel[ playerid ] < 6 && p_Class[ i ] == CLASS_POLICE ) {
								GivePlayerWantedLevel( playerid, 6 - p_WantedLevel[ playerid ] );
							}

							#if defined AC_INCLUDED
								// prevent team kills
								if ( p_Class[ playerid ] != CLASS_POLICE && p_Class[ i ] != CLASS_POLICE ) {
									AC_UpdateDamageInformation( i, playerid, PRESSED( KEY_FIRE ) ? 51 : 38 );
								}
							#endif
						}

						// debug
						// printf("Player is shooting vehicle ... %d (%s)", iVehicle, PRESSED( KEY_FIRE ) ? ("rocket") : ("lmg"));
					}
				}
			}
		}
	}

	// Various keys
	if ( PRESSED( KEY_FIRE ) )
	{
		if ( IsPlayerAttachedObjectSlotUsed( playerid, 3 ) ) return RemovePlayerStolensFromHands( playerid ), SendServerMessage( playerid, "你把偷来的东西掉在地上并且把它弄坏了." ), 1;
   	}

 	else if ( PRESSED( KEY_NO ) )
 	{
 		// Press N to deatach trailer from vehicle
 		if ( iVehicle && IsTrailerAttachedToVehicle( iVehicle ) )
 			DetachTrailerFromVehicle( iVehicle );
 	}

	else if ( PRESSED( KEY_ACTION ) )
	{
		if ( IsPlayerInAnyVehicle( playerid ) && GetPlayerState( playerid ) == PLAYER_STATE_DRIVER && GetVehicleModel( iVehicle ) == 525 ) {
			new
				Float: pX, Float: pY, Float: pZ, Float: pAngle
			;

			GetVehiclePos( iVehicle, pX, pY, pZ );
			GetVehicleZAngle( iVehicle, pAngle );

			pX += 2.0 * floatsin( pAngle, degrees );
			pY += 2.0 * floatcos( pAngle, degrees );

			if ( !IsTrailerAttachedToVehicle( iVehicle ) ) {
				for( new i = 0; i < MAX_VEHICLES; i++ ) if ( IsValidVehicle( i ) && i != iVehicle ) {
					if ( GetVehicleDistanceFromPoint( i, pX, pY, pZ ) < 7.0 ) {
						AttachTrailerToVehicle( i, iVehicle );
						break;
					}
				}
			} else {
				DetachTrailerFromVehicle( iVehicle );
			}
		}
	}

	else if ( PRESSED( KEY_SECONDARY_ATTACK ) )
	{
		if ( GetPVarInt( playerid, "viewing_houseints" ) == 1 )
		{
			new id = p_InHouse[ playerid ];
			SendServerMessage( playerid, "你已停止查看房屋内部." );
			SetPlayerPos( playerid, g_houseData[ id ] [ E_TX ], g_houseData[ id ] [ E_TY ], g_houseData[ id ] [ E_TZ ] );
			SetPlayerInterior( playerid, g_houseData[ id ] [ E_INTERIOR_ID ] );
		    DeletePVar( playerid, "viewing_houseints" );
			TogglePlayerControllable( playerid, 1 );
			SetCameraBehindPlayer( playerid );
			return 1;
		}
	}

	else if ( HOLDING( KEY_AIM ) )
	{
	  	if ( IsPlayerAttachedObjectSlotUsed( playerid, 1 ) && iWeapon == WEAPON_SNIPER )
	 		RemovePlayerAttachedObject( playerid, 1 );
	}
	return 1;
}

stock pauseToLoad( playerid )
{
	p_pausedToLoad{ playerid } = true;
	KillTimer( p_pausedToLoadTimer[ playerid ] );
	TogglePlayerControllable( playerid, 0 );
	TextDrawShowForPlayer(playerid, g_ObjectLoadTD);

	p_pausedToLoadTimer[ playerid ] = SetTimerEx( "unpause_Player", 3000, false, "d", playerid );
	return 1;
}

function unpause_Player( playerid )
{
	p_pausedToLoad{ playerid } = false;
	if ( !IsPlayerTied( playerid ) || !IsPlayerTazed( playerid ) ) TogglePlayerControllable( playerid, 1 );
	TextDrawHideForPlayer(playerid, g_ObjectLoadTD);
	return KillTimer( p_pausedToLoadTimer[ playerid ] ), 1;
}

#if defined AC_INCLUDED
	public OnPlayerMoneyChanged( playerid, amount )
	{
		// save player money on each monetary movement
		if ( IsPlayerLoggedIn( playerid ) )
		{
			mysql_single_query( sprintf( "UPDATE `USERS` SET `CASH` = %d WHERE `ID` = %d", GetPlayerCash( playerid ), GetPlayerAccountID( playerid ) ) );
		}
		return 1;
	}

	public OnPlayerCheatDetected( playerid, detection, params )
	{
		if ( detection == CHEAT_TYPE_REMOTE_JACK )
		{
	        if ( GetPlayerScore( playerid ) < 200 )
	        {
				SendGlobalMessage( -1, ""COL_PINK"[反作弊]{FFFFFF} %s(%d) 因异常劫持车辆而被踢出.", ReturnPlayerName( playerid ), playerid );
				SendClientMessageToAdmins( -1, ""COL_PINK"[ABNORMAL JACKING]"COL_GREY" %s(%d) - %d score - %d ping - %s IP", ReturnPlayerName( playerid ), playerid, GetPlayerScore( playerid ), GetPlayerPing( playerid ), ReturnPlayerIP( playerid ) );
	        	return Kick( playerid ), 1;
			}
			SendClientMessageToAdmins( -1, ""COL_PINK"[ABNORMAL JACKING]"COL_GREY" %s(%d) is a suspect of jacking vehicles abnormally.", ReturnPlayerName( playerid ), playerid );
		}
		else if ( detection == CHEAT_TYPE_RAPIDFIRE )
		{
			SendGlobalMessage( -1, ""COL_PINK"[反作弊]{FFFFFF} %s(%d) 因快速射击而被踢出.", ReturnPlayerName( playerid ), playerid );
		 	Kick( playerid );
		}
		else if ( detection == CHEAT_TYPE_FAKEKILL )
		{
			SendGlobalMessage( -1, ""COL_PINK"[反作弊]{FFFFFF} %s(%d) 因假杀而被禁止.", ReturnPlayerName( playerid ), playerid );
			BanEx( playerid, "假杀" );
		}
		else if ( detection == CHEAT_TYPE_CARWARP )
		{
			if ( ! GetPlayerAdminLevel( playerid ) )
			{
                SendGlobalMessage( -1, ""COL_PINK"[反作弊]{FFFFFF} %s(%d) 因汽车变形而被禁止.", ReturnPlayerName( playerid ), playerid );
				BanEx( playerid, "汽车变形" );
			}
		}
		else if ( detection == CHEAT_TYPE_AIRBRAKE )
		{
			//SendGlobalMessage( -1, ""COL_PINK"[ANTI-CHEAT]{FFFFFF} %s(%d) has been banned for airbraking.", ReturnPlayerName( playerid ), playerid );
			//AdvancedBan( playerid, "Server", "Airbrake", ReturnPlayerIP( playerid ) );
			SendClientMessageToAdmins( -1, ""COL_PINK"[ABNORMAL MOVEMENT]"COL_GREY" %s(%d) has been detected for airbrake.", ReturnPlayerName( playerid ), playerid );
		}
		else if ( detection == CHEAT_TYPE_FLYHACKS )
		{
			SendClientMessageToAdmins( -1, ""COL_PINK"[ABNORMAL MOVEMENT]"COL_GREY" %s(%d) has been detected for fly hacks.", ReturnPlayerName( playerid ), playerid );
			// SendGlobalMessage( -1, ""COL_PINK"[ANTI-CHEAT]{FFFFFF} %s(%d) has been banned for fly hacks.", ReturnPlayerName( playerid ), playerid );
			// AdvancedBan( playerid, "Server", "Fly Hacks", ReturnPlayerIP( playerid ) );
		}
		else if ( detection == CHEAT_TYPE_WEAPON )
		{
			SendClientMessageToAdmins( -1, ""COL_PINK"[ANTI-CHEAT]"COL_GREY" %s(%d) has been detected for weapon hack (%s).", ReturnPlayerName( playerid ), playerid, ReturnWeaponName( params ) );
		}
		else if ( detection == CHEAT_TYPE_CAR_PARTICLE_SPAM )
		{
			SendGlobalMessage( -1, ""COL_PINK"[反作弊]{FFFFFF} %s(%d) 因汽车颗粒垃圾邮件而被踢出.", ReturnPlayerName( playerid ), playerid );
			Kick( playerid );
		}
		else if( detection == CHEAT_TYPE_PICKUP_SPAM )
		{
            SendGlobalMessage( -1, ""COL_PINK"[反作弊]{FFFFFF} %s(%d) 已因快速拾取垃圾邮件而被禁止.", ReturnPlayerName( playerid ), playerid );
			BanEx( playerid, "拾取垃圾邮件" );
		}
		else
		{
			SendClientMessageToAdmins( -1, ""COL_PINK"[ANTI-CHEAT]"COL_GREY" %s(%d) has been detected for %s.", ReturnPlayerName( playerid ), playerid, AC_DetectedCheatToString( detection ) );
		}
		return 1;
	}
#endif

public OnPlayerUpdate( playerid )
{
	if ( ! p_PlayerLogged{ playerid } )
		return 0;

	static
		iKeys, iLeftRight, iState
	;

	GetPlayerKeys( playerid, iKeys, tmpVariable, iLeftRight );
	p_AFKTime[ playerid ] = GetTickCount( );

	// Disable Driveby
	if ( !g_Driveby )
	{
		iState = GetPlayerState( playerid );
		if ( iState == PLAYER_STATE_DRIVER ) {
			SetPlayerArmedWeapon( playerid, 0 );
		}
	}

	// Duffel Bug And Sniper Bug
	if ( !( iKeys & KEY_AIM ) && !IsPlayerAttachedObjectSlotUsed( playerid, 1 ) && p_MoneyBag{ playerid } ) {
		//SetPlayerAttachedObject( playerid, 1, 1550, 1, 0.131999, -0.140999, 0.053999, 11.299997, 65.599906, 173.900054, 0.652000, 0.573000, 0.594000 );
		SetPlayerAttachedObject( playerid, 1, 1210, 7, 0.302650, -0.002469, -0.193321, 296.124053, 270.396881, 8.941717, 1.000000, 1.000000, 1.000000 );
	}
	return 1;
}

public OnPlayerStreamIn(playerid, forplayerid)
{
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	return 1;
}

/*public AC_OnImgFileModifed( playerid, filename[ ], md5[ ] ) {
	format( szNormalString, sizeof( szNormalString ), "[ANTI-CHEAT]{FFFFFF} %s(%d) modified an img file: "COL_GREY"%s", ReturnPlayerName( playerid ), playerid, filename );
	SendClientMessageToAdmins( COLOR_PINK, szNormalString );
	return 1;
}

public AC_OnFileCalculated( playerid, filename[ ], md5[ ], bool: isCheat )
{
	if ( isCheat ) {
		format( szNormalString, sizeof( szNormalString ), "[ANTI-CHEAT]{FFFFFF} %s(%d) executed a blacklisted file: "COL_GREY"%s", ReturnPlayerName( playerid ), playerid, filename );
		SendClientMessageToAdmins( COLOR_PINK, szNormalString );
	}
	return 1;
}*/


public OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( g_DialogLogging ) printf( "[DIALOG_LOG] %s(%d) - %d, %d, %d, %s", ReturnPlayerName( playerid ), playerid, dialogid, response, listitem, inputtext );

    if ( dialogid == DIALOG_JOB )
    {
        if (response)
        {
          	p_Job{ playerid } = listitem;

          	if ( !IsPlayerJailed( playerid ) && IsPlayerSpawned( playerid ) )
          	{
            	ResetPlayerWeapons( playerid );
	     		switch( listitem )
				{
			        case JOB_MUGGER:
			        {
			            GivePlayerWeapon( playerid, 10, 1 );
			            GivePlayerWeapon( playerid, 22, 150 );
			            GivePlayerWeapon( playerid, 25, 30 );
			        }
			        case JOB_KIDNAPPER:
			        {
			            GivePlayerWeapon( playerid, 29, 220 );
			            GivePlayerWeapon( playerid, 30, 400 );
			        }
			        case JOB_TERRORIST:
			        {
			            GivePlayerWeapon( playerid, 33, 50 );
			            GivePlayerWeapon( playerid, 30, 400 );
			        }
			        case JOB_HITMAN:
			        {
			            //GivePlayerWeapon( playerid, 4, 1 );
			            GivePlayerWeapon( playerid, 23, 130 );
			            GivePlayerWeapon( playerid, 34, 30 );
			        }
			        case JOB_WEAPON_DEALER:
			        {
			            GivePlayerWeapon( playerid, 5 , 1 );
			            GivePlayerWeapon( playerid, 22, 150 );
			            GivePlayerWeapon( playerid, 31, 300 );
			        }
			        case JOB_DRUG_DEALER:
			        {
			            GivePlayerWeapon( playerid, 5 , 1 );
			            GivePlayerWeapon( playerid, 22, 150 );
			            GivePlayerWeapon( playerid, 25, 30 );
			        }
			        case JOB_DIRTY_MECHANIC:
			        {
			            GivePlayerWeapon( playerid, 22, 150 );
			            GivePlayerWeapon( playerid, 27, 90 );
					}
			        case JOB_BURGLAR:
			        {
			            GivePlayerWeapon( playerid, 23, 130 );
			            GivePlayerWeapon( playerid, 31, 300 );
					}
			    }
			}

            TogglePlayerControllable( playerid, 1 );

            p_JobSet{ playerid } = true;

            //if ( !p_CitySet{ playerid } )
            //	ShowPlayerDialog( playerid, DIALOG_SPAWN_CITY, DIALOG_STYLE_LIST, "{FFFFFF}Select Spawning City", "San Fierro\nLas Venturas\nLos Santos\nRandom City", "Select", "" );

            SendServerMessage( playerid, "你的工作已设置为 %s.你可以在市政厅换 "COL_GOLD"$5,000"COL_WHITE".", GetJobName( p_Job{ playerid } ) );
		}
        else
        {
         	TogglePlayerControllable( playerid, 0 );
         	ShowPlayerJobList( playerid );
        }
    }

	if ( dialogid == DIALOG_HOUSES )
	{
		if ( ! response )
			return ShowPlayerSpawnMenu( playerid );

		#if VIP_ALLOW_OVER_LIMIT == false
			if ( ! p_VIPLevel[ playerid ] && p_OwnedHouses[ playerid ] > GetPlayerHouseSlots( playerid ) ) {
				ResetSpawnLocation( playerid );
				return SendError( playerid, "请续费 VIP 或出售此房屋, 使房产数量符合上限 (/h sell)." );
			}
		#endif

    	new x = 0;

	    foreach ( new i : houses ) if ( IsPlayerHomeOwner( playerid, i ) )
		{
	       	if ( x == listitem )
	      	{
        		if ( IsHouseOnFire( i ) )
        		{
        			ShowPlayerSpawnMenu( playerid );
                    SendError( playerid, "这房子着火了.你目前无法在那里生成." );
        		}
        		else
        		{
	        		SetPlayerSpawnLocation( playerid, "HSE", i );
                    SendServerMessage( playerid, "房屋生成已设置为 "COL_GREY"%s"COL_WHITE".", g_houseData[ i ] [ E_HOUSE_NAME ] );
        		}
			 	return 1;
      		}
	      	x ++;
		}
		return 1;
	}
	if ( ( dialogid == DIALOG_CITY_HALL ) && response )
	{
		switch( listitem )
		{
		    case 0:
		    {
		    	if ( p_Class[ playerid ] != CLASS_CIVILIAN )
                    return SendError( playerid, "你必须是平民才能改变当前的工作." );

		        if ( GetPlayerCash( playerid ) < 5000 )
                    return SendError( playerid, "你需要 "COL_GOLD"$5,000"COL_WHITE" 换工作." );

         		ShowPlayerJobList( playerid );
	            TogglePlayerControllable( playerid, 0 );
				GivePlayerCash( playerid, -( 5000 ) );
				SendServerMessage( playerid, "你已被引导至工作选择,请参阅你的新工作." );
		    }
		    case 1:
		    {
				SendServerMessage( playerid, "你已被引导至城市选择,请参阅你的新生成城市." );
				ShowPlayerDialog( playerid, DIALOG_SPAWN_CITY, DIALOG_STYLE_LIST, "{FFFFFF}更改生成城市", "圣菲耶罗\n拉斯文图拉斯\n洛斯桑托斯\n"COL_GREY"随机城市", "选择", "返回" );
		    }
		}
	}
	if ( dialogid == DIALOG_SPAWN_CITY )
	{
		if ( !response )
		{
			//if ( !p_CitySet{ playerid } )
            // 	return ShowPlayerDialog( playerid, DIALOG_SPAWN_CITY, DIALOG_STYLE_LIST, "{FFFFFF}Select Spawning City", "San Fierro\nLas Venturas\nLos Santos\nRandom City", "Select", "" ), 1;

            return ShowPlayerDialog( playerid, DIALOG_CITY_HALL, DIALOG_STYLE_LIST, "{FFFFFF}市政厅", ""COL_GOLD"$5,000"COL_WHITE"\t\t换工作\n"COL_GOLD"自由的"COL_WHITE"\t\t改变城市", "选择", "关闭" ), 1;
		}

 		//p_CitySet{ playerid } = true;
		p_SpawningCity{ playerid } = listitem;
		SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[城市]"COL_WHITE" 你已将你的生成城市设置为 "COL_GREY"%s"COL_WHITE".", returnCityName( listitem ) );
	}
	if ( ( dialogid == DIALOG_HOSPITAL ) && response )
	{
		#if ENABLE_CITY_LV == true
	    if ( !IsPlayerInDynamicCP( playerid, g_Checkpoints[ CP_HOSPITAL ] ) && !IsPlayerInDynamicCP( playerid, g_Checkpoints[ CP_HOSPITAL_LV ] ) && !IsPlayerInDynamicCP( playerid, g_Checkpoints[ CP_HOSPITAL1_LS ] ) && !IsPlayerInDynamicCP( playerid, g_Checkpoints[ CP_HOSPITAL2_LS ] ) && !IsPlayerInDynamicCP( playerid, g_Checkpoints[ CP_HOSPITAL_FC ] ) )
			return SendError( playerid, "你必须在医院的检查站才能使用此功能." );
	    #else
	    if ( !IsPlayerInDynamicCP( playerid, g_Checkpoints[ CP_HOSPITAL ] ) ) return SendError( playerid, "你必须在医院的检查站才能使用此功能." );
	    #endif

		switch( listitem )
		{
			case 0:
			{
				if ( GetPlayerCash( playerid ) >= 2000 ) GivePlayerCash( playerid, -(2000) ), SetPlayerHealth( playerid, 100.0 ), SendServerMessage( playerid, "你已经治愈了自己$2,000.");
				else return SendError( playerid, "你买不起这个物品." );
			}
			case 1:
			{
				if ( GetPlayerCash( playerid ) >= 4000 ) GivePlayerCash( playerid, -(4000) ), p_InfectedHIV{ playerid } = false, SendServerMessage( playerid, "你治愈了 $4,000. 的所有感染");
                else return SendError( playerid, "你买不起这个物品." );
			}
			case 2:
			{
				if ( GetPlayerCash( playerid ) >= 6000 ) GivePlayerCash( playerid, -(6000) ), p_InfectedHIV{ playerid } = false, SetPlayerHealth( playerid, 100.0 ), SendServerMessage( playerid, "你治愈了所有感染并治愈了自己 $6,000." );
                else return SendError( playerid, "你买不起这个物品." );
			}
		}
	}
	if ( ( dialogid == DIALOG_ARENAS ) && response )
	{
	    switch( listitem )
	    {
			case 0:
			{
			    SetPlayerPosition( playerid, 1412.639892, -1.787510, 1000.924377, 1, 69 );
			    SendServerMessage( playerid, "你已被传送到仓库1." );
			}
			case 1:
			{
			    SetPlayerPosition( playerid, 1302.519897, -1.787510, 1001.028259, 18, 69 );
			    SendServerMessage( playerid, "你已被传送到仓库2." );
			}
			case 2:
			{
			    SetPlayerPosition( playerid, -1398.103515, 937.631164, 1036.479125, 15, 69 );
			    SendServerMessage( playerid, "你已被传送到血盆." );
			}
			case 3:
			{
			    SetPlayerPosition( playerid, -1398.065307, -217.028900, 1051.115844, 7, 69 );
			    SendServerMessage( playerid, "你已被传送到8-轨道." );
			}
			case 4:
			{
			    SetPlayerPosition( playerid, -975.975708,1060.983032,1345.671875, 10, 69 );
			    SendServerMessage( playerid, "你已被传送到 RC 战场." );
			}
			case 5:
			{
			    SetPlayerPosition( playerid, 501.980987,-69.150199,998.757812, 11, 69 );
			    SendServerMessage( playerid, "你已被传送到巴尔." );
			}
			case 6:
			{
			    SetPlayerPosition( playerid, 2543.462646,-1308.379882,1026.728393, 2, 69 );
			    SendServerMessage( playerid, "你已被传送到裂缝工厂." );
			}

			case 7:
			{
			    SetPlayerPosition( playerid, -794.806396,497.738037,1376.195312, 1, 69 );
			    SendServerMessage( playerid, "你已被传送到自由城内部." );
			}
			case 8:
			{
			    SetPlayerPosition( playerid, 1059.895996,2081.685791,10.820312, 0, 69 );
			    SendServerMessage( playerid, "你已被传送到 LV 仓库." );
			}
			case 9:
			{
			    SetPlayerPosition( playerid, -1465.268676,1557.868286,1052.531250, 14, 69 );
			    SendServerMessage( playerid, "你已被传送至 Kickstart." );
			}
			case 10:
			{
			    SetPlayerPosition( playerid, -1444.645507,-664.526000,1053.572998, 4, 69 );
			    SendServerMessage( playerid, "你已被传送到土路." );
			}
			case 11:
			{
			    SetPlayerPosition( playerid, 1453.1576,-1066.7552,213.3828, 0, 69 );
			    SendServerMessage( playerid, "你已被传送到躲避飞机." );
			}
	    }
	}
	if ( ( dialogid == DIALOG_VIP_LOCKER ) && response )
	{
	    if ( IsPlayerJailed( playerid ) )
            return SendError( playerid, "在监狱中无法使用此功能." );

	    if ( IsPlayerInEvent( playerid ) )
            return SendError( playerid, "当你参加活动时,你无法使用此功能." );

	 	if ( p_VIPLevel[ playerid ] < VIP_REGULAR )
            return SendError( playerid, "你必须是普通 VIP 才能获得此功能." );

		if ( ! IsPlayerInRangeOfPoint( playerid, 5.0, -1966.1591, 852.7100, 1214.2678 ) && ! IsPlayerInRangeOfPoint( playerid, 5.0, -1944.1324, 830.0725, 1214.2678 ) && ! IsPlayerInRangeOfPoint( playerid, 5.0, 60.3115, 121.5226, 1017.4534 ) )
			return SendError( playerid, "你必须靠近 VIP 休息室内的枪支自动售货机才能使用此功能." );

		if ( ! listitem )
		{
            if ( p_VIPArmourRedeem[ playerid ] > g_iTime && p_VIPLevel[ playerid ] < VIP_DIAMOND )
                return SendError( playerid, "你必须等待 %d 秒才能再次兑换另一套盔甲.", p_VIPArmourRedeem[ playerid ] - g_iTime );

			SetPlayerArmour( playerid, 100.0 );
			p_VIPArmourRedeem[ playerid ] = g_iTime + ( p_VIPLevel[ playerid ] == VIP_PLATINUM ? 60 : 300 );
			SendServerMessage( playerid, "你已经兑换了一套盔甲." );
		}
		else
		{
		    if ( p_VIPWeaponRedeem[ playerid ] > g_iTime && p_VIPLevel[ playerid ] < VIP_DIAMOND )
		        return SendError( playerid, "你必须等待 %d 秒才能再次兑换另一件武器.", p_VIPWeaponRedeem[ playerid ] - g_iTime );

		    new weaponid;
		    switch( listitem )
		    {
		    	case 1 .. 13: weaponid = 21 + listitem;
		    	case 14 .. 16: weaponid = listitem - 13;
				case 17 .. 22: weaponid = listitem - 12;
		    	case 23 .. 24: weaponid = listitem - 9;
		    }
			if ( GetPlayerClass( playerid ) == CLASS_POLICE && weaponid == 9 ) return SendError( playerid, "作为执法人员,你不能购买电锯." );
		    GivePlayerWeapon( playerid, weaponid, 0xFFFF );
		    SendServerMessage( playerid, "你已经兑换了 %s.", ReturnWeaponName( weaponid ) );
			p_VIPWeaponRedeem[ playerid ] = g_iTime + ( p_VIPLevel[ playerid ] == VIP_PLATINUM ? 60 : 300 );
		}
	}
	if ( ( dialogid == DIALOG_FIGHTSTYLE ) && response )
	{
		switch( listitem )
		{
			case 0:
			{
			    if ( GetPlayerFightingStyle( playerid ) == FIGHT_STYLE_KNEEHEAD )
			    {
			        SendError( playerid, "你已经激活了这种战斗方式." );
			        return 1;
			    }
			    if ( GetPlayerCash( playerid ) < 1000 )
			    {
			        SendError( playerid, "你没有足够的钱来学习这种战斗方式." );
			        return 1;
			    }
			    SetPlayerFightingStyle( playerid, FIGHT_STYLE_KNEEHEAD );
				format( szNormalString, sizeof( szNormalString ), "UPDATE `USERS` SET `FIGHTSTYLE`=%d WHERE `NAME` = '%s'", GetPlayerFightingStyle( playerid ), mysql_escape( ReturnPlayerName( playerid ) ) );
				mysql_single_query( szNormalString );
				GivePlayerCash( playerid, -1000 );
				SendServerMessage( playerid, "你已经支付了 $1,000 并学会了 "COL_ORANGE"捍卫{FFFFFF}." );
			}
			case 1:
			{
			    if ( GetPlayerFightingStyle( playerid ) == FIGHT_STYLE_BOXING )
			    {
			        SendError( playerid, "你已经激活了这种战斗方式." );
			        return 1;
			    }
			    if ( GetPlayerCash( playerid ) < 4000 )
			    {
			        SendError( playerid, "你没有足够的钱来学习这种战斗方式." );
			        return 1;
			    }
			    SetPlayerFightingStyle( playerid, FIGHT_STYLE_BOXING );
				format( szNormalString, sizeof( szNormalString ), "UPDATE `USERS` SET `FIGHTSTYLE`=%d WHERE `NAME` = '%s'", GetPlayerFightingStyle( playerid ), mysql_escape( ReturnPlayerName( playerid ) ) );
				mysql_single_query( szNormalString );
				GivePlayerCash( playerid, -4000 );
				SendServerMessage( playerid, "你已经支付了 $4,000 并学会了 "COL_ORANGE"拳击{FFFFFF}." );
			}
			case 2:
			{
			    if ( GetPlayerFightingStyle( playerid ) == FIGHT_STYLE_KUNGFU )
			    {
			        SendError( playerid, "你已经激活了这种战斗方式." );
			        return 1;
			    }
			    if ( GetPlayerCash( playerid ) < 9000 )
			    {
			        SendError( playerid, "你没有足够的钱来学习这种战斗方式." );
			        return 1;
			    }
			    SetPlayerFightingStyle( playerid, FIGHT_STYLE_KUNGFU );
				format( szNormalString, sizeof( szNormalString ), "UPDATE `USERS` SET `FIGHTSTYLE`=%d WHERE `NAME` = '%s'", GetPlayerFightingStyle( playerid ), mysql_escape( ReturnPlayerName( playerid ) ) );
				mysql_single_query( szNormalString );
				GivePlayerCash( playerid, -9000 );
				SendServerMessage( playerid, "你已经支付了 $9,000 并学会了 "COL_ORANGE"功夫{FFFFFF}." );
			}
		}
	}
	if ( ( dialogid == DIALOG_VIP_WEP ) && response )
	{
	    if ( listitem == 1 && p_VIPLevel[ playerid ] < VIP_GOLD ) return SendError( playerid, "只有当你是 "COL_BRONZE"金 VIP{FFFFFF} 或更高." );
	    if ( listitem == 2 && p_VIPLevel[ playerid ] < VIP_PLATINUM ) return SendError( playerid, "只有当你是 "COL_GOLD"白金 VIP{FFFFFF} 或更高." );
	    ShowPlayerDialog( playerid, DIALOG_VIP_WEP_SELECT, DIALOG_STYLE_LIST, "{FFFFFF}Weapon Select", ""COL_RED"Remove Weapon On This Slot\n9mm Pistol\nSilenced Pistol\nDesert Eagle\nShotgun\nSawn-off Shotgun\nSpas 12\nMac 10\nMP5\nAK-47\nM4\nTec 9\nRifle\nSniper", "选择", "取消");
		p_VIPWep_Modify{ playerid } = listitem;
	}
	if ( dialogid == DIALOG_VIP_WEP_SELECT )
	{
	    if ( response )
	    {
	        if ( listitem == 0 )
	        {
	            switch( p_VIPWep_Modify{ playerid } )
				{
				    case 0: p_VIPWep1{ playerid } = 0, SendClientMessage( playerid, COLOR_GREY, "[服务器]{FFFFFF} 你有 "COL_RED"已删除"COL_WHITE" 第一个槽中的武器." );
				    case 1: p_VIPWep2{ playerid } = 0, SendClientMessage( playerid, COLOR_GREY, "[服务器]{FFFFFF} 你有 "COL_RED"已删除"COL_WHITE" 第二个槽中的武器." );
				    case 2: p_VIPWep3{ playerid } = 0, SendClientMessage( playerid, COLOR_GREY, "[服务器]{FFFFFF} 你有 "COL_RED"已删除"COL_WHITE" 第三个槽中的武器." );
				}
				return 1;
	    	}
			new wep = 21 + listitem;
			switch( p_VIPWep_Modify{ playerid } )
			{
			    case 0: p_VIPWep1{ playerid } = wep;
			    case 1: p_VIPWep2{ playerid } = wep;
			    case 2: p_VIPWep3{ playerid } = wep;
			}
		    SendServerMessage( playerid, "你已经选择了 "COL_GREY"%s"COL_WHITE" 为你的 %s 插槽.", ReturnWeaponName( wep ), p_VIPWep_Modify{ playerid } == 0 ? ("第一的") : ( p_VIPWep_Modify{ playerid } == 1 ? ("秒") : ("第三") )  );
	    }
	    else cmd_vipspawnwep( playerid, "" );
	}
	if ( ( dialogid == DIALOG_CMDS ) && response )
	{
	    static szCMDS[ 1920 ];
	    switch( listitem )
	    {
	        case 0:
	        {
	            szCMDS[ 0 ] = '\0';
	            strcat( szCMDS, ""COL_GREY"/help{FFFFFF} - 显示服务器的一般帮助信息.\n"\
								""COL_GREY"/rules{FFFFFF} - 显示服务器规则.\n"\
								""COL_GREY"/commands{FFFFFF} - 显示所有服务器命令的列表.\n"\
								""COL_GREY"/report{FFFFFF} - 向游戏内管理员发送报告.\n"\
								""COL_GREY"/ask{FFFFFF} - 向游戏内管理员发送问题(必须与游戏/server相关).\n" );
				strcat( szCMDS, ""COL_GREY"/admins{FFFFFF} - 显示当前在线管理员.\n"\
								""COL_GREY"/vip{FFFFFF} - 查看此服务器的 VIP 软件包列表.\n"\
								""COL_GREY"/donated{FFFFFF} - 使用交易 ID 捐赠后兑换 VIP.\n"\
								""COL_GREY"/gettaxrate{FFFFFF} - 查看你当前的税率设置为 \n"\
								""COL_GREY"/gettotalcash{FFFFFF} - 查看服务器中的总金额.\n" );
				strcat( szCMDS, ""COL_GREY"/calc(ulator){FFFFFF} - 计算游戏中的数学表达式.\n"\
								""COL_GREY"/eventbank{FFFFFF} - 通过向活动银行捐款来帮助资助活动.\n"\
								""COL_GREY"/cnr{FFFFFF} - 显示服务器中警察和强盗的平衡.\n"\
								""COL_GREY"/playerjobs{FFFFFF} - 显示使用特定工作的玩家/skill.\n" );
				strcat( szCMDS, ""COL_GREY"/policetutorial{FFFFFF} - 允许你重修执法教程.\n"\
								""COL_GREY"/idletime{FFFFFF} - 显示玩家上次发送更新的时间.\n"\
								""COL_GREY"/rank{FFFFFF} - 查看你或某人当前在服务器中的全球排名." );

				ShowPlayerDialog( playerid, DIALOG_CMDS_REDIRECT, DIALOG_STYLE_MSGBOX, "{FFFFFF}基本命令", szCMDS, "确定", "返回" );
	        }
	        case 1:
	        {
	            szCMDS[ 0 ] = '\0';
	            strcat( szCMDS,	""COL_GOLD"一般命令\n\n"\
								""COL_GREY"/sendmoney{FFFFFF} - 向另一位游戏内玩家汇款.\n"\
								""COL_GREY"/gps{FFFFFF} - 切换 GPS 以定位服务器内的重要位置.\n"\
								""COL_GREY"/controlpanel{FFFFFF} - 显示你的控制面板.\n"\
								""COL_GREY"/request{FFFFFF} - 请求特定工作人员.\n"\
								""COL_GREY"/fps{FFFFFF} - 显示你的帧率.\n" );
	            strcat( szCMDS, ""COL_GREY"/getmytax{FFFFFF} - 查看你可能需要缴纳多少税.\n"\
								""COL_GREY"/packetloss{FFFFFF} - 查看服务器丢包情况.\n"\
								""COL_GREY"/unbanme{FFFFFF} - 付钱摆脱班级禁令.\n"\
								""COL_GREY"/chuffloc{FFFFFF} - 显示 ChuffSec 安全车的位置.\n"\
								""COL_GREY"/richlist{FFFFFF} - 显示游戏中最富有的三名玩家.\n\n" );
                strcat( szCMDS,	""COL_GOLD"帐户命令\n\n"\
								""COL_GREY"/stats{FFFFFF} - 显示你的统计数据.\n"\
								""COL_GREY"/savestats{FFFFFF} - 保存你当前的统计数据.\n"\
								""COL_GREY"/achievements{FFFFFF} - 显示你可以解锁的成就.\n"\
								""COL_GREY"/myaccid{FFFFFF} - 显示你的帐户 ID.\n"\
								""COL_GREY"/changepassword{FFFFFF} - 将你当前的密码更改为新密码.\n"\
								""COL_GREY"/xpmarket{FFFFFF} - 允许你将一些 经验 换成游戏内的金钱.\n\n" );
                strcat( szCMDS,	""COL_GOLD"信息命令\n\n"\
								""COL_GREY"/idof{FFFFFF} - 显示指定玩家的 ID 及其用户名.\n"\
								""COL_GREY"/lastlogged{FFFFFF} - 显示用户上次玩游戏的时间.\n"\
								""COL_GREY"/animlist{FFFFFF} - 显示动画列表.\n"\
								""COL_GREY"/jaillist{FFFFFF} - 显示被监禁的玩家列表.\n"\
								""COL_GREY"/twitter{FFFFFF} - 显示来自 @IrresistibleDev\n 的最新推文" );
                strcat( szCMDS, ""COL_GREY"/weeklytime{FFFFFF} - 显示玩家每周的时间.\n\n" );
                strcat( szCMDS, ""COL_GOLD"通讯命令\n\n"\
								""COL_GREY"/me{FFFFFF} - 与你自己发送基于消息的操作.\n"\
								""COL_GREY"/pm{FFFFFF} - 向指定玩家发送私人消息.\n"\
								""COL_GREY"/r{FFFFFF} - 回复你最新发消息的人.\n"\
								""COL_GREY"/dnd(all){FFFFFF} - 切换从指定/or所有玩家接收 PM 的访问权限.\n" );
                strcat( szCMDS, ""COL_GREY"/(w)hisper{FFFFFF} - 对附近的玩家低声说话." );

				ShowPlayerDialog( playerid, DIALOG_CMDS_REDIRECT, DIALOG_STYLE_MSGBOX, "{FFFFFF}主要命令", szCMDS, "确定", "返回" );
	        }
	        case 2:
	        {
	            szCMDS[ 0 ] = '\0';
	            strcat( szCMDS, ""COL_GOLD"一般民事命令\n\n"\
								""COL_GREY"/rob{FFFFFF} - 抢劫最近的玩家.\n"\
								""COL_GREY"/rape{FFFFFF} - 强奸最近的玩家.\n"\
								""COL_GREY"/robstore{FFFFFF} - 显示抢劫商店时按下的键.\n"\
								""COL_GREY"/pdjail{FFFFFF} - 显示监狱牢房可用于袭击的时间.\n"\
								""COL_GREY"/banks{FFFFFF} - 显示某些银行可用于抢劫的时间.\n" );
				strcat( szCMDS, ""COL_GREY"/jackpots{FFFFFF} - 显示所有赌场当前的累积奖金.\n"\
								""COL_GREY"/stoprob{FFFFFF} - 停止你当前的抢劫.\n"\
								""COL_GREY"/job{FFFFFF} - 显示你的工作.\n"\
								""COL_GREY"/911{FFFFFF} - 呼叫紧急服务.\n"\
								""COL_GREY"/placehit{FFFFFF} - 击中指定玩家.\n"\
								""COL_GREY"/viewguns{FFFFFF} - 显示可以从武器商处购买的武器.\n" );
				strcat( szCMDS, ""COL_GREY"/payticket{FFFFFF} - 支付执法人员发出的罚单.\n"\
								""COL_GREY"/takeover{FFFFFF} - 与你的帮派一起接管一个帮派区域.\n" );
                strcat( szCMDS, ""COL_GREY"/gang{FFFFFF} - 显示帮派命令.\n\n"\
								""COL_GOLD"作业命令\n\n"\
								""COL_ORANGE"劫匪{FFFFFF} - /rape, /blowjob, /robitems\n"\
								""COL_ORANGE"绑匪{FFFFFF} - /(un)tie, /kidnap, /ransom(pay)\n"\
								""COL_ORANGE"恐怖分子{FFFFFF} - /c4\n" );
				strcat( szCMDS, ""COL_ORANGE"职业杀手{FFFFFF} - /(hide)tracker, /hitlist\n"\
								""COL_ORANGE"武器商{FFFFFF} - /sellgun\n"\
								""COL_ORANGE"毒贩{FFFFFF} - /weed\n" );
				strcat( szCMDS, ""COL_ORANGE"黑市修车工{FFFFFF} - /mech\n"\
								""COL_ORANGE"窃贼{FFFFFF} - /burglar\n"\
								""COL_PINK"伐木工迷你工作{FFFFFF} - /wood\n"\
								""COL_PINK"冰毒 生产迷你作业{FFFFFF} - /meth\n"\
								""COL_PINK"采矿迷你作业{FFFFFF} - /ore\n" );
				strcat( szCMDS, ""COL_PINK"卡车运输迷你工作{FFFFFF} - /work\n" );
				strcat( szCMDS, ""COL_FIREMAN"消防员迷你工作{FFFFFF} - /fires");
				ShowPlayerDialog( playerid, DIALOG_CMDS_REDIRECT, DIALOG_STYLE_MSGBOX, "{FFFFFF}文职命令", szCMDS, "确定", "返回" );
	        }
	        case 3:
	        {
	            szCMDS[ 0 ] = '\0';
	            strcat( szCMDS, ""COL_GREY"/shop{FFFFFF} - 在 Supa Save.\n 中显示商店菜单"\
								""COL_GREY"/tie{FFFFFF} - 用你的绳子绑住最近的玩家.\n"\
								""COL_GREY"/untie{FFFFFF} - 解开最近的玩家.\n" );
				strcat( szCMDS, ""COL_GREY"/breakout{FFFFFF} - 使用熔锁剂熔化牢房铁栅,越狱." );
				ShowPlayerDialog( playerid, DIALOG_CMDS_REDIRECT, DIALOG_STYLE_MSGBOX, "{FFFFFF}商店及物品命令", szCMDS, "确定", "返回" );
	        }
	        case 4:
	        {
	            szCMDS[ 0 ] = '\0';
	            strcat( szCMDS, ""COL_GOLD"常用执法命令\n\n"\
								""COL_GREY"/arrest{FFFFFF} - 逮捕一名特定玩家.\n"\
								""COL_GREY"/(un)cuff{FFFFFF} - (un)手铐指定的玩家.\n"\
								""COL_GREY"/taze{FFFFFF} - 镇压指定玩家.\n"\
								""COL_GREY"/ticket{FFFFFF} - 给指定玩家开罚单.\n" );
				strcat( szCMDS, ""COL_GREY"/issuewarrant{FFFFFF} - 保证指定的玩家.\n"\
								""COL_GREY"/location{FFFFFF} - 显示指定玩家的位置.\n"\
								""COL_GREY"/backup{FFFFFF} - 呼叫你的团队进行支援.\n"\
								""COL_GREY"/pullover{FFFFFF} - 要求指定的玩家靠边停车.\n"\
								""COL_GREY"/detain{FFFFFF} - 拘留最近的被铐住的玩家.\n" );
                strcat( szCMDS, ""COL_GREY"/search{FFFFFF} - 搜查玩家是否有任何毒品并对他们发出搜查令.\n"\
								""COL_GREY"/bail{FFFFFF} - 以金钱保释某人出狱.\n"\
								""COL_GREY"/getwanted{FFFFFF} - 获取嫌疑人的通缉等级.\n\n"\
								""COL_GOLD"特殊执法命令\n\n"\
								""COL_GREY"/crb{FFFFFF} - 创建路障.\n" );
                strcat( szCMDS, ""COL_GREY"/drb{FFFFFF} - 销毁指定的路障 ID.\n"\
								""COL_GREY"/drball{FFFFFF} - 消除所有障碍.\n"\
								""COL_GREY"/spike{FFFFFF} - 设置尖峰组.\n"\
								""COL_GREY"/dss{FFFFFF} - 销毁指定的尖峰集 ID.\n"\
								""COL_GREY"/dssall{FFFFFF} - 删除所有尖峰组.\n"\
								""COL_GREY"/emp{FFFFFF} - 关闭驾驶员车辆的发动机.\n"\
								""COL_GREY"/disableemp - /demp -{FFFFFF} - 重新初始化驾驶员车辆的引擎.\n"\
								""COL_GREY"/bruteforce{FFFFFF} - 暴力破解房屋密码." );
				ShowPlayerDialog( playerid, DIALOG_CMDS_REDIRECT, DIALOG_STYLE_MSGBOX, "{FFFFFF}警察命令", szCMDS, "确定", "返回" );
	        }
	        case 5:
	        {
	            szCMDS[ 0 ] = '\0';
	            strcat( szCMDS, ""COL_GOLD"一般车辆命令\n\n"\
								""COL_GREY"/eject{FFFFFF} - 弹出指定的玩家.\n"\
								""COL_GOLD"自有车辆命令\n\n" );
				strcat( szCMDS, ""COL_GREY"/v{FFFFFF} - 显示可购买车辆的命令.\n"\
								""COL_GREY"/v reset{FFFFFF} - 重置车辆修改数据.\n"\
								""COL_GREY"/v park{FFFFFF} - 将车辆停放在你标记的位置.\n"\
								""COL_GREY"/v respawn{FFFFFF} - 将载具恢复到停放位置.\n" );
				strcat( szCMDS, ""COL_GREY"/v locate{FFFFFF} - 在地图上定位你的载具.\n"\
								""COL_GREY"/v color{FFFFFF} - 修改车辆的颜色.\n"\
								""COL_GREY"/v paintjob{FFFFFF} - 为载具更换涂装.\n"\
								""COL_GREY"/v sell{FFFFFF} - 以原价的 50% 出售载具 (需坐在车内)." );
				ShowPlayerDialog( playerid, DIALOG_CMDS_REDIRECT, DIALOG_STYLE_MSGBOX, "{FFFFFF}车辆命令", szCMDS, "确定", "返回" );
	        }
     		case 6:
	        {
	            szCMDS[ 0 ] = '\0';
	            strcat( szCMDS, ""COL_GREY"/h{FFFFFF} - 显示可购买房屋的命令.\n"\
								""COL_GREY"/h buy{FFFFFF} - 购买可购买的房屋(必须位于房屋入口检查站).\n"\
								""COL_GREY"/h config{FFFFFF} - 调整房屋设置 (需在屋内).\n" );
				strcat( szCMDS, ""COL_GREY"/h spawn{FFFFFF} - 每次死亡后在你的房子里重生你.\n"\
								""COL_GREY"/h sell{FFFFFF} - 以原价的 50% 出售房屋 (需在屋内)." );
				ShowPlayerDialog( playerid, DIALOG_CMDS_REDIRECT, DIALOG_STYLE_MSGBOX, "{FFFFFF}众议院命令", szCMDS, "确定", "返回" );
	        }
	        case 7:
	        {
	            szCMDS[ 0 ] = '\0';
	            strcat( szCMDS, ""COL_GREY"/perks{FFFFFF} - 一个可以让你的游戏受益并浪费一些 经验.\n 的菜单"\
								""COL_GREY"/toys{FFFFFF} - 向玩家添加可附加对象(需要 500 分数).\n"\
								""COL_GREY"/label{FFFFFF} - 在你的头顶上放置一条消息(必须拥有超过 3,500 的经验).\n"\
								""COL_GREY"/labelcolor{FFFFFF} - 更改标签的颜色.\n"\
								""COL_GREY"/rlabel{FFFFFF} - 移除你头上的标签.\n" );
				strcat( szCMDS, ""COL_GREY"/labelinfo{FFFFFF} - 显示带有 32 字符限制的标签文本.\n"\
								""COL_GREY"/radio{FFFFFF} - 显示你可以收听的广播电台列表.\n"\
								""COL_GREY"/stopradio{FFFFFF} - 停止播放收音机.\n"\
								""COL_GREY"/boombox{FFFFFF} - 在你的位置放置便携式音响,在小区域内播放音乐.\n"\
								""COL_GREY"/colors(/colours){FFFFFF} - 显示游戏中所有可用颜色的列表.\n"\
								""COL_GREY"/moviemode{FFFFFF} - 切换影片模式,这样你就可以在没有屏幕上所有文本的情况下进行录制." );
				ShowPlayerDialog( playerid, DIALOG_CMDS_REDIRECT, DIALOG_STYLE_MSGBOX, "{FFFFFF}杂项命令", szCMDS, "确定", "返回" );
	        }
	        case 8:
	        {
				if ( p_VIPLevel[ playerid ] < VIP_REGULAR ) return SendError( playerid, "你还不是 VIP, 请前往以下地址开通: "COL_GREY"donate.sfcnr.com" );
				szCMDS[ 0 ] = '\0';
	            strcat( szCMDS, ""COL_GREY"/vipspawnwep{FFFFFF} - 设置出生时携带的武器\n"\
								""COL_GREY"/vipskin{FFFFFF} - 配置你的生成皮肤\n"\
								""COL_GREY"/viplist{FFFFFF} - 所有在线 VIP 的列表.玩家.\n"\
								""COL_GREY"/vipgun{FFFFFF} - 从枪柜中兑换武器或护甲背心\n"\
								""COL_GREY"/vsay{FFFFFF} - 全球VIP 聊天\n"\
								""COL_GREY"/vipjob{FFFFFF} - 选择你的 VIP.允许你同时从事两份工作的工作.\n"\
								""COL_GREY"/mynotes{FFFFFF} - 访问你的 VIP 笔记和材料" );
				ShowPlayerDialog( playerid, DIALOG_CMDS_REDIRECT, DIALOG_STYLE_MSGBOX, ""COL_GOLD"VIP.命令", szCMDS, "确定", "返回" );
	        }
	    }
	    return 1;
	}
	if ( ( dialogid == DIALOG_CMDS_REDIRECT ) && !response ) { cmd_cmds( playerid, "" ); }
	if ( ( dialogid == DIALOG_STATS ) && response )
	{
	    new pID = p_ViewingStats[ playerid ], gangid = p_GangID[ pID ];
		switch( listitem )
		{
			case 0:
			{
				new seasonal_rank[ 16 ];
				new vipSeconds = p_VIPExpiretime[ pID ] - g_iTime;

				GetSeasonalRankName( GetPlayerRank( pID ), seasonal_rank );

			    format( szLargeString, 750, ""COL_GREY"姓名:{FFFFFF} %s(%d)\n"\
											""COL_GREY"帐户 ID:{FFFFFF} %d\n"\
											""COL_GREY"管理员级别:{FFFFFF} %d\n"\
											""COL_GREY"在线时间:{FFFFFF} %s\n"\
											""COL_GREY"不可抗拒的排名:{FFFFFF} %s\n"\
											""COL_GREY"IC 代币:{FFFFFF} %f\n",
											ReturnPlayerName( pID ), pID,
											p_AccountID[ pID ], p_AdminLevel[ pID ],
											secondstotime( p_Uptime[ pID ] ),
											seasonal_rank,
											GetPlayerIrresistibleCoins( pID ) );

				format( szLargeString, 750, "%s"COL_GREY"VIP 级别:{FFFFFF} %s\n"\
											""COL_GREY"VIP 到期:{FFFFFF} %s\n"\
											""COL_GREY"警察警告:{FFFFFF} %d/%d\n"\
											""COL_GREY"陆军警告:{FFFFFF} %d/%d\n"\
											""COL_GREY"VIP 工作:{FFFFFF} %s\n"\
											""COL_GREY"当前工作:{FFFFFF} %s",
											szLargeString, VIPToString( p_VIPLevel[ pID ] ), vipSeconds > 0 ? secondstotime( vipSeconds ) : ( "N/A" ), p_CopBanned{ pID }, MAX_CLASS_BAN_WARNS, p_ArmyBanned{ pID }, MAX_CLASS_BAN_WARNS, p_VIPLevel[ pID ] < VIP_DIAMOND ? ( "N/A" ) : GetJobName( p_VIPJob{ pID } ), GetJobName( p_Job{ pID } ) );

				if ( gangid != -1 ) {
					format( szLargeString, 750, "%s\n"COL_GREY"帮派:"COL_WHITE" %s(%d)", szLargeString, g_gangData[ gangid ] [ E_NAME ], gangid );
				}

				ShowPlayerDialog( playerid, DIALOG_STATS_REDIRECT, DIALOG_STYLE_MSGBOX, "{FFFFFF}一般统计", szLargeString, "确定", "返回" );
			}
			case 1:
			{
				new
					Float: total_experience;

				GetPlayerTotalExperience( pID, total_experience );

				format( szLargeString, 800,	""COL_GREY"分数:{FFFFFF} %d\n"\
											""COL_GREY"经验:{FFFFFF} %s\n"\
											""COL_GREY"钱:{FFFFFF} %s\n"\
											""COL_GREY"银行资金:{FFFFFF} %s\n"\
											""COL_GREY"杀死:{FFFFFF} %d\n"\
											""COL_GREY"死亡:{FFFFFF} %d\n"\
											""COL_GREY"比率 (K/D):{FFFFFF} %0.2f\n",
											GetPlayerScore( pID ), number_format( total_experience, .decimals = 0 ), cash_format( GetPlayerCash( pID ) ), cash_format( GetPlayerBankMoney( pID ) ), p_Kills[ pID ], p_Deaths[ pID ], floatdiv( p_Kills[ pID ], p_Deaths[ pID ] ) );

				format( szLargeString, 800,	"%s"COL_GREY"拥有的房屋:{FFFFFF} %d(限制 %d)\n"\
                                            ""COL_GREY"自有车辆:{FFFFFF} %d(限制 %d)\n"\
                                            ""COL_GREY"逮捕总数:{FFFFFF} %d\n"\
                                            ""COL_GREY"抢劫总数:{FFFFFF} %d\n"\
                                            ""COL_GREY"已扑灭的火灾总数:{FFFFFF} %d\n"\
                                            ""COL_GREY"完成悬赏任务总数:{FFFFFF} %d\n"\
                                            ""COL_GREY"盗窃案总数:{FFFFFF} %d\n",
											szLargeString, p_OwnedHouses[ pID ], GetPlayerHouseSlots( pID ), p_OwnedVehicles[ pID ], GetPlayerVehicleSlots( pID ), p_Arrests[ pID ], p_Robberies[ pID ], p_Fires[ pID ], p_HitsComplete[ pID ], p_Burglaries[ pID ] );

				format( szLargeString, 800,	"%s"COL_GREY"监狱突袭总数:{FFFFFF} %d\n"\
                                            ""COL_GREY"银行袭击总数:{FFFFFF} %d\n"\
                                            ""COL_GREY"被劫车辆总数:{FFFFFF} %d\n"\
                                            ""COL_GREY"卡车运输的货物总量:{FFFFFF} %d\n"\
                                            ""COL_GREY"总共 冰毒 产量:{FFFFFF} %d\n"\
                                            ""COL_GREY"飞行员任务总数:{FFFFFF} %d",
											szLargeString, p_JailsBlown[ pID ], p_BankBlown[ pID ], p_CarsJacked[ pID ], p_TruckedCargo[ pID ], p_MethYielded[ pID ], p_PilotMissions[ pID ] );

				ShowPlayerDialog( playerid, DIALOG_STATS_REDIRECT, DIALOG_STYLE_MSGBOX, "{FFFFFF}主要统计数据", szLargeString, "确定", "返回" );
			}
			case 2:
			{
				new
					Float: fDrill = float( p_drillStrength[ playerid ] ) / float( MAX_DRILL_STRENGTH ) * 100.0;

				format( szLargeString, 750, ""COL_GREY"热力钻机:{FFFFFF} %0.0f%%\n"\
											""COL_GREY"绳索:{FFFFFF} %d\n"\
											""COL_GREY"熔锁剂:{FFFFFF} %d\n"\
											""COL_GREY"剪刀:{FFFFFF} %d\n"\
											""COL_GREY"大麻:{FFFFFF} %d 克\n"\
											""COL_GREY"冰毒:{FFFFFF} %d 磅\n"\
											""COL_GREY"钱箱:{FFFFFF} %s\n",
											fDrill, p_Ropes[ pID ], p_MetalMelter[ pID ], p_Scissors[ pID ], p_WeedGrams[ pID ], GetPlayerMeth( pID ), p_MoneyBag{ pID } == true ? ( "是" ) : ( "否" ) );

				format( szLargeString, 750, "%s"COL_GREY"铝箔:{FFFFFF} %d\n"\
											""COL_GREY"防盗钱包:{FFFFFF} %s\n"\
											""COL_GREY"发夹:{FFFFFF} %d\n"\
											""COL_GREY"C4:{FFFFFF} %d\n"\
											""COL_GREY"贞操带:{FFFFFF} %s\n"\
											""COL_GREY"烧碱:{FFFFFF} %d\n"\
											""COL_GREY"盐酸:{FFFFFF} %d\n"\
											""COL_GREY"氯化氢:{FFFFFF} %d\n",
											szLargeString, p_AntiEMP[ pID ], p_SecureWallet{ pID } == true ? ( "是" ) : ( "否" ), p_BobbyPins[ pID ], GetPlayerC4Amount( pID ), p_AidsVaccine{ pID } == true ? ("是") : ("否"),
											GetPlayerCausticSoda( pID ), GetPlayerMuriaticAcid( pID ), GetPlayerHydrogenChloride( pID ) );

				format( szLargeString, 750, "%s"COL_GREY"大麻 种子:"COL_WHITE" %d\n"\
											""COL_GREY"烟花:{FFFFFF} %d\n"\
											""COL_GREY"爆炸子弹:{FFFFFF} %d\n"\
											""COL_GREY"便携音响:{FFFFFF} %s\n",
											szLargeString, GetPlayerShopItemAmount( playerid, SHOP_ITEM_WEED_SEED ), p_Fireworks[ pID ], p_ExplosiveBullets[ pID ], GetPlayerBoombox( pID ) ? ( "是" ) : ( "否" ) );

				ShowPlayerDialog( playerid, DIALOG_STATS_REDIRECT, DIALOG_STYLE_MSGBOX, "{FFFFFF}物品统计", szLargeString, "确定", "返回" );
			}
			case 3: Streak_ShowPlayer( pID, DIALOG_STATS_REDIRECT, "返回", playerid );
			case 4: WeaponStats_ShowPlayer( pID, DIALOG_STATS_REDIRECT, true, playerid );
			case 5: displayAchievements( pID, DIALOG_STATS_REDIRECT, "返回", playerid );
		}
	}
	if ( ( dialogid == DIALOG_STATS_REDIRECT ) && !response ) {
		ShowPlayerDialog( playerid, DIALOG_STATS, DIALOG_STYLE_LIST, "{FFFFFF}统计", "一般统计\n游戏统计\n物品统计\n连胜统计\n武器统计\n成就", "确定", "取消" );
	}
	if ( dialogid == DIALOG_ACC_EMAIL ) {

		if ( ! response ) {
			ShowPlayerJobList( playerid );
			SendServerMessage( playerid, "如果你希望将来为你的帐户分配电子邮件,请使用 "COL_GREY"/email"COL_WHITE"." );
			return 1;
		}

		new
			email[ 64 ];

		if ( sscanf( inputtext, "s[64]", email ) )  {
			ShowPlayerDialog( playerid, DIALOG_ACC_EMAIL, DIALOG_STYLE_INPUT, "{FFFFFF}账号邮箱", ""COL_WHITE"为了安全起见,你想为你的帐户分配一个电子邮件吗?\n\n我们还会向你通报游戏内和社区相关活动的情况!\n\n"COL_RED"你的电子邮件长度必须在 4 到 64 个字符之间.", "确认", "取消" );
			return SendError( playerid, "你的电子邮件长度必须在 4 到 64 个字符之间." );
		}

		if ( ! ( 3 < strlen( email ) < 64 ) ) {
			ShowPlayerDialog( playerid, DIALOG_ACC_EMAIL, DIALOG_STYLE_INPUT, "{FFFFFF}账号邮箱", ""COL_WHITE"为了安全起见,你想为你的帐户分配一个电子邮件吗?\n\n我们还会向你通报游戏内和社区相关活动的情况!\n\n"COL_RED"你的电子邮件长度必须在 4 到 64 个字符之间.", "确认", "取消" );
			return SendError( playerid, "你的电子邮件长度必须在 4 到 64 个字符之间." );
		}

		if ( ! regex_match( email, "[a-zA-Z0-9_\\.]+@([a-zA-Z0-9\\-]+\\.)+[a-zA-Z]{2,4}" ) ) {
			ShowPlayerDialog( playerid, DIALOG_ACC_EMAIL, DIALOG_STYLE_INPUT, "{FFFFFF}账号邮箱", ""COL_WHITE"为了安全起见,你想为你的帐户分配一个电子邮件吗?\n\n我们还会向你通报游戏内和社区相关活动的情况!\n\n"COL_RED"你的电子邮件必须有效 (foo@example.com).", "确认", "取消" );
			return SendError( playerid, "你的电子邮件必须有效 (foo@example.com)." );
		}

	    format( szBigString, sizeof( szBigString ), "INSERT INTO `EMAIL_VERIFY`(`USER_ID`, `EMAIL`) VALUES (%d, '%s') ON DUPLICATE KEY UPDATE `EMAIL`='%s',`DATE`=CURRENT_TIMESTAMP", p_AccountID[ playerid ], mysql_escape( email ), mysql_escape( email ) );
	    mysql_function_query( dbHandle, szBigString, true, "OnQueueEmailVerification", "ds", playerid, email );
	   	ShowPlayerJobList( playerid );
	   	return 1;
	}
	if ( dialogid == DIALOG_WEAPON_DEAL )
	{
	    if ( !response )
 		{
 			new
 				iDealer = p_WeaponDealer[ playerid ];

		  	if ( IsPlayerConnected( iDealer ) )
		  	{
		  		if ( GetPVarInt( iDealer, "weapon_sell_cd" ) < g_iTime )
		  			GivePlayerWantedLevel( iDealer, 6 ), SetPVarInt( iDealer, "weapon_sell_cd", g_iTime + 60 );

                SendClientMessageFormatted( iDealer, -1, ""COL_ORANGE"[武器交易]{FFFFFF} %s(%d) 已完成交易.", ReturnPlayerName ( playerid ), playerid );
		  	}

			new purchased = GetPVarInt( playerid, "purchased_weapon" );
			if ( purchased ) {
				SetPVarInt( playerid, "weapon_buy_cool", g_iTime + 40 );
				GivePlayerWantedLevel( playerid, ( purchased * 2 ) > 6 ? 6 : purchased );
				DeletePVar( playerid, "purchased_weapon" );
			}

			SetPlayerArmedWeapon( playerid, 0 );
			p_WeaponDealing{ playerid } = false;
 			p_WeaponDealer[ playerid ] = INVALID_PLAYER_ID;
		  	return 1;
		}

		if ( p_VIPLevel[ playerid ] < VIP_GOLD && listitem == MENU_SPECIAL ) {
			SendError( playerid, "你还不是黄金 VIP, 请前往以下地址开通: "COL_GREY"donate.sfcnr.com" );
			return ShowAmmunationMenu( playerid, "{FFFFFF}武器交易 - 购买武器", DIALOG_WEAPON_DEAL );
		}

	    p_WeaponDealMenu{ playerid } = listitem;
        RedirectAmmunation( playerid, listitem, "{FFFFFF}武器交易 - 购买武器", DIALOG_WEAPON_DEAL_BUY, 0.75, 5 );
	}
	if ( dialogid == DIALOG_WEAPON_DEAL_BUY )
	{
	    // The discount is %50 - You can change it above!
	    if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "你不能在监狱里购买武器." );
	    if ( GetPlayerVirtualWorld( playerid ) == 69 ) return SendError( playerid, "你不能在活动中购买武器." );
		if ( GetPlayerState( playerid ) == PLAYER_STATE_WASTED || !IsPlayerSpawned( playerid ) ) return SendError( playerid, "你目前无法购买任何武器." );

		new
			weapondealerid = p_WeaponDealer[ playerid ];

		if ( !IsPlayerConnected( weapondealerid ) ) return SendError( playerid, "你目前无法购买任何武器." );
		if ( GetDistanceBetweenPlayers( playerid, weapondealerid ) > 33.0 ) return SendError( playerid, "你目前无法购买任何武器." );

		if ( response )
		{
		    for( new i, x = 0; i < sizeof( g_AmmunationWeapons ); i++ )
		    {
		        if ( g_AmmunationWeapons[ i ] [ E_MENU ] == p_WeaponDealMenu{ playerid } )
		        {
		            if ( x == listitem )
		            {
		                new price = floatround( g_AmmunationWeapons[ i ] [ E_PRICE ] * 0.75 ); // Change the discount here!!
					 	if ( price > GetPlayerCash( playerid ) )
						{
						    SendError( playerid, "你没有足够的钱来做这个." );
                            RedirectAmmunation( playerid, p_WeaponDealMenu{ playerid }, "{FFFFFF}武器交易 - 购买武器", DIALOG_WEAPON_DEAL_BUY, 0.75, 5 );
							return 1;
						}
						GivePlayerCash( weapondealerid, floatround( price * 0.75 ) );
		                SendClientMessageFormatted( weapondealerid, -1, ""COL_ORANGE"[武器交易]{FFFFFF} %s(%d) 购买了 %s "COL_GOLD"%s"COL_WHITE" (适用税).", ReturnPlayerName( playerid ), playerid, g_AmmunationWeapons[ i ] [ E_NAME ], cash_format( price ) );
						SetPVarInt( playerid, "purchased_weapon", GetPVarInt( playerid, "purchased_weapon" ) + 1 );
						SendClientMessageFormatted( playerid, -1, ""COL_ORANGE"[武器交易]{FFFFFF} 你已购买 %s "COL_GOLD"%s"COL_WHITE".", g_AmmunationWeapons[ i ] [ E_NAME ], cash_format( price ) );
						if ( g_AmmunationWeapons[ i ] [ E_WEPID ] == 101 ) SetPlayerArmour( playerid, 100.0 );
						else if ( g_AmmunationWeapons[ i ] [ E_WEPID ] == 102 )
						{
							if ( p_ExplosiveBullets[ playerid ] >= MAX_EXPLOSIVE_ROUNDS )
								return SendError( playerid, "你最多只能购买 %d 轮.", MAX_EXPLOSIVE_ROUNDS );

							p_ExplosiveBullets[ playerid ] += g_AmmunationWeapons[ i ] [ E_AMMO ];
							ShowPlayerHelpDialog( playerid, 3000, "按 ~r~~k~~CONVERSATION_NO~~w~ 激活爆炸子弹." );
						}
						else GivePlayerWeapon( playerid, g_AmmunationWeapons[ i ] [ E_WEPID ], g_AmmunationWeapons[ i ] [ E_AMMO ] * ( g_AmmunationWeapons[ i ] [ E_WEPID ] == 35 ? 1 : 5 ) );
						SetPlayerArmedWeapon( playerid, 0 );
						GivePlayerCash( playerid, -( price ) );
						StockMarket_UpdateEarnings( E_STOCK_AMMUNATION, price, .factor = 0.25 );
						RedirectAmmunation( playerid, p_WeaponDealMenu{ playerid }, "{FFFFFF}武器交易 - 购买武器", DIALOG_WEAPON_DEAL_BUY, 0.75, 5 );
						break;
		            }
		            x ++;
		        }
		    }
		}
		else ShowAmmunationMenu( playerid, "{FFFFFF}武器交易 - 购买武器", DIALOG_WEAPON_DEAL );
	}
	if ( ( dialogid == DIALOG_AMMU ) && response )
	{
    	p_AmmunationMenu{ playerid } = listitem;
        return RedirectAmmunation( playerid, listitem );
	}
	if ( dialogid == DIALOG_AMMU_BUY )
	{
		if ( !IsPlayerInDynamicCP( playerid, g_Checkpoints[ CP_AMMUNATION_0 ] ) && !IsPlayerInDynamicCP( playerid, g_Checkpoints[ CP_AMMUNATION_1 ] ) && !IsPlayerInDynamicCP( playerid, g_Checkpoints[ CP_AMMUNATION_2 ] ) ) return SendError( playerid, "你必须在 Ammu-Nation 购买检查点才能使用此功能." );
		if ( GetPlayerState( playerid ) == PLAYER_STATE_WASTED || !IsPlayerSpawned( playerid ) ) return SendError( playerid, "你目前无法购买任何武器." );
		if ( response )
		{
		    for( new i, x = 0; i < sizeof( g_AmmunationWeapons ); i++ )
		    {
		        if ( g_AmmunationWeapons[ i ] [ E_MENU ] == p_AmmunationMenu{ playerid } )
		        {
		            if ( x == listitem )
		            {
						// Chainsaw Removal for LEO through Ammunation
						if ( GetPlayerClass( playerid ) == CLASS_POLICE && g_AmmunationWeapons[ i ] [ E_WEPID ] == 9 ) return SendError( playerid, "作为执法人员,你不能购买电锯." );
					 	if ( g_AmmunationWeapons[ i ] [ E_PRICE ] > GetPlayerCash( playerid ) )
						{
						    SendError( playerid, "你没有足够的钱来做这个." );
						    RedirectAmmunation( playerid, p_AmmunationMenu{ playerid } );
							return 1;
						}

						new
							bDealer = IsPlayerJob( playerid, JOB_WEAPON_DEALER ),
							iCostPrice = g_AmmunationWeapons[ i ] [ E_PRICE ]
						;

						if ( bDealer )
							iCostPrice = floatround( iCostPrice * 0.75 );

						GivePlayerCash( playerid, -iCostPrice );

						StockMarket_UpdateEarnings( E_STOCK_AMMUNATION, iCostPrice, .factor = 0.25 );
						RedirectAmmunation( playerid, p_AmmunationMenu{ playerid } );

						if ( g_AmmunationWeapons[ i ] [ E_WEPID ] == 101 ) SetPlayerArmour( playerid, float( g_AmmunationWeapons[ i ] [ E_AMMO ] ) );
						else if ( g_AmmunationWeapons[ i ] [ E_WEPID ] == 102 )
						{
							if ( p_ExplosiveBullets[ playerid ] >= MAX_EXPLOSIVE_ROUNDS )
								return SendError( playerid, "你最多只能购买 %d 轮.", MAX_EXPLOSIVE_ROUNDS );

							p_ExplosiveBullets[ playerid ] += g_AmmunationWeapons[ i ] [ E_AMMO ];
							ShowPlayerHelpDialog( playerid, 3000, "按 ~r~~k~~CONVERSATION_NO~~w~ 激活爆炸子弹." );
						}
						else GivePlayerWeapon( playerid, g_AmmunationWeapons[ i ] [ E_WEPID ], g_AmmunationWeapons[ i ] [ E_AMMO ] );

						SendServerMessage( playerid, "你已购买 %s(%d) "COL_GOLD"%s"COL_WHITE"%s.", g_AmmunationWeapons[ i ] [ E_NAME ], g_AmmunationWeapons[ i ] [ E_AMMO ], cash_format( iCostPrice ), bDealer ? ( " (含折扣)" ) : ( "" ) );
		                break;
		            }
		            x ++;
		        }
		    }
		}
		else ShowAmmunationMenu( playerid );
	}

	if ( ( dialogid == DIALOG_UNBAN_CLASS ) && response )
	{
		cmd_unbanme( playerid, "" );
		switch( listitem )
		{
			case 0:
			{
				if ( !( p_ArmyBanned{ playerid } >= MAX_CLASS_BAN_WARNS ) )
					return SendError( playerid, "你无需支付任何费用,因为你没有被军队禁止." );

				if ( GetPlayerCash( playerid ) < 750000 )
					return SendError( playerid, "你的资金不足以支付解禁 ($750,000)." );

				p_ArmyBanned{ playerid } = 0;
				GivePlayerCash( playerid, -750000 );
				UpdateServerVariableInt( "eventbank", GetGVarInt( "eventbank" ) + 250000 );

				format( szNormalString, sizeof( szNormalString ), "UPDATE `USERS` SET `ARMY_BAN`=0 WHERE ID=%d", p_AccountID[ playerid ] );
				mysql_single_query( szNormalString );

			    SendClientMessageToAdmins( -1, ""COL_PINK"[ADMIN]"COL_GREY" %s(%d) has paid his un-army-ban.", ReturnPlayerName( playerid ), playerid );
			}
			case 1:
			{
				if ( !( p_CopBanned{ playerid } >= MAX_CLASS_BAN_WARNS ) )
					return SendError( playerid, "你无需支付任何费用,因为你没有被警察禁止." );

				if ( GetPlayerCash( playerid ) < 500000 )
					return SendError( playerid, "你的资金不足以支付解禁 ($500,000)." );

				p_CopBanned{ playerid } = 0;
				GivePlayerCash( playerid, -500000 );
				UpdateServerVariable( "eventbank", GetGVarInt( "eventbank" ) + 170000, .type = GLOBAL_VARTYPE_INT );

				format( szNormalString, sizeof( szNormalString ), "UPDATE `USERS` SET `COP_BAN`=0 WHERE ID=%d", p_AccountID[ playerid ] );
				mysql_single_query( szNormalString );

			    SendClientMessageToAdmins( -1, ""COL_PINK"[ADMIN]"COL_GREY" %s(%d) has paid his un-cop-ban.", ReturnPlayerName( playerid ), playerid );
			}
		}
	}
	if ( dialogid == DIALOG_AIRPORT && response )
	{
		static const
			AIR_TRAVEL_COST = 2000;

		if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "在监狱期间你不能旅行." );
		if ( p_WantedLevel[ playerid ] ) return SendError( playerid, "当你被通缉时你不能旅行." );
		if ( !(( GetPlayerCash( playerid ) >= AIR_TRAVEL_COST ) || ( GetPlayerCasinoRewardsPoints( playerid ) >= 5.0 )) ) return SendError( playerid, "你需要 %s 在城市之间旅行.", cash_format( AIR_TRAVEL_COST ) );

		new bool: using_rewards = GetPlayerCasinoRewardsPoints( playerid ) >= 5.0;

		// set position
		switch ( listitem )
		{
			case 0: {
				if ( IsPlayerInDynamicCP( playerid, g_Checkpoints[ CP_AIRPORT_SF ] ) ) return SendError( playerid, "你已经在 圣菲耶罗 了." );
				SendServerMessage( playerid, "它让你付出了代价 "COL_GOLD"%s"COL_WHITE" 去旅行.欢迎来到圣菲耶罗!", using_rewards ? ( "5 赌场奖励积分" ) : ( cash_format( AIR_TRAVEL_COST ) ) );
				SetPlayerPos( playerid, -1422.4063, -286.5081, 14.1484 );
			}
			case 1: {
				if ( IsPlayerInDynamicCP( playerid, g_Checkpoints[ CP_AIRPORT_LV ] ) ) return SendError( playerid, "你已经在 拉斯文图拉斯 了." );
				SendServerMessage( playerid, "它让你付出了代价 "COL_GOLD"%s"COL_WHITE" 去旅行.欢迎来到拉斯文图拉斯!", using_rewards ? ( "5 赌场奖励积分" ) : ( cash_format( AIR_TRAVEL_COST ) ) );
				SetPlayerPos( playerid, 1672.5364, 1447.8616, 10.7881 );
			}
			case 2: {
				if ( IsPlayerInDynamicCP( playerid, g_Checkpoints[ CP_AIRPORT_LS ] ) ) return SendError( playerid, "你已经在 洛圣都 了." );
				SendServerMessage( playerid, "它让你付出了代价 "COL_GOLD"%s"COL_WHITE" 去旅行.欢迎来到洛圣都!", using_rewards ? ( "5 赌场奖励积分" ) : ( cash_format( AIR_TRAVEL_COST ) ) );
				SetPlayerPos( playerid, 1642.2274, -2335.4978, 13.5469 );
			}
		}

		// check for rewards
		if ( using_rewards ) {
			SetPlayerCasinoRewardsPoints( playerid, GetPlayerCasinoRewardsPoints( playerid ) - 5.0 );
			mysql_single_query( sprintf( "UPDATE `USERS` SET `CASINO_REWARDS`=%f WHERE `ID`=%d", GetPlayerCasinoRewardsPoints( playerid ), p_AccountID[ playerid ] ) );
		}
		else
		{
			StockMarket_UpdateEarnings( E_STOCK_AVIATION, AIR_TRAVEL_COST, 0.5 );
			GivePlayerCash( playerid, -AIR_TRAVEL_COST );
		}

		// set interior/world
		SetPlayerVirtualWorld( playerid, 0 );
		SetPlayerInterior( playerid, 0 );
		PlayerPlaySound( playerid, 0, 0.0, 0.0, 0.0 );
	}
	if ( dialogid == DIALOG_SPAWN && response )
	{
		new bool: has = false;

		// erase large string for ease
		erase( szMassiveString );
		erase( szLargeString );

		// show items
		switch ( listitem )
		{
			// reset spawn
			case 0:
			{
				ResetSpawnLocation( playerid );
				return SendServerMessage( playerid, "你已将生成位置重置为默认值." );
			}

			// houses
			case 1:
			{
				foreach ( new i : houses ) if ( strmatch( g_houseData[ i ] [ E_OWNER ], ReturnPlayerName( playerid ) ) ) {
					format( szMassiveString, sizeof( szMassiveString ), "%s%s\n", szMassiveString, g_houseData[ i ] [ E_HOUSE_NAME ] ), has = true;
				}

				if ( ! has )
					return SendError( playerid, "你不拥有任何房屋." ), ShowPlayerSpawnMenu( playerid );

				return ShowPlayerDialog( playerid, DIALOG_HOUSES, DIALOG_STYLE_LIST, "{FFFFFF}设置生成位置", szMassiveString, "选择", "返回" );
			}

			// businesses
			case 2:
			{
				foreach ( new b : business ) if ( IsBusinessAssociate( playerid, b ) ) {
					format( szLargeString, sizeof( szLargeString ), "%s%s\n", szLargeString, g_businessData[ b ] [ E_NAME ] ), has = true;
				}

				if ( ! has )
					return SendError( playerid, "你不拥有任何企业." ), ShowPlayerSpawnMenu( playerid );

				return ShowPlayerDialog( playerid, DIALOG_BUSINESSES, DIALOG_STYLE_LIST, "{FFFFFF}商业产生地点", szLargeString, "选择", "返回" );
			}

			// gang facility
			case 3:
			{
				new gangid = p_GangID[ playerid ];

				if ( gangid == INVALID_GANG_ID )
					return SendError( playerid, "你不属于任何帮派." ), ShowPlayerSpawnMenu( playerid );

				static city[ MAX_ZONE_NAME ], location[ MAX_ZONE_NAME ];

				szLargeString = ""COL_WHITE"城市\t"COL_WHITE"区域\n";

				foreach ( new handle : gangfacilities ) if ( g_gangData[ gangid ] [ E_SQL_ID ] == g_gangFacilities[ handle ] [ E_GANG_SQL_ID ] )
				{
					new Float: min_x, Float: min_y;
					new zoneid = g_gangFacilities[ handle ] [ E_TURF_ID ];

					Streamer_GetFloatData( STREAMER_TYPE_AREA, g_gangTurfData[ zoneid ] [ E_AREA ], E_STREAMER_MIN_X, min_x );
					Streamer_GetFloatData( STREAMER_TYPE_AREA, g_gangTurfData[ zoneid ] [ E_AREA ], E_STREAMER_MIN_Y, min_y );

				    Get2DCity( city, min_x, min_y );
				    GetZoneFromCoordinates( location, min_x, min_y );

					format( szLargeString, sizeof( szLargeString ), "%s%s\t%s\n", szLargeString, GetLocationDisplayName(city), GetLocationDisplayName(location) ), has = true;
				}

				if ( ! has )
					return SendError( playerid, "你的帮派不拥有帮派设施." ), ShowPlayerSpawnMenu( playerid );

				return ShowPlayerDialog( playerid, DIALOG_FACILITY_SPAWN, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}帮派设施生成位置", szLargeString, "选择", "返回" );
			}

			// visage apartment
			case 4:
			{
				foreach ( new handle : visageapartments ) if ( g_VisageApartmentData[ handle ] [ E_OWNER_ID ] == p_AccountID[ playerid ] ) {
					format( szLargeString, sizeof( szLargeString ), "%s%s\n", szLargeString, g_VisageApartmentData[ handle ] [ E_TITLE ] ), has = true;
				}

				if ( ! has )
					return SendError( playerid, "你不拥有任何面容公寓." ), ShowPlayerSpawnMenu( playerid );

				return ShowPlayerDialog( playerid, DIALOG_VISAGE_SPAWN, DIALOG_STYLE_LIST, "{FFFFFF}Visage 生成位置", szLargeString, "选择", "返回" );
			}
		}
	}
	return 1;
}

public OnPlayerClickMap(playerid, Float:fX, Float:fY, Float:fZ)
{
	if ( IsPlayerAdminOnDuty( playerid ) )
	{
    	SetPlayerPosFindZ( playerid, fX, fY, fZ );
		printf( "Admin %s Teleported To %f, %f, %f", ReturnPlayerName( playerid ), fX, fY, fZ );
	}
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	return 1;
}

/////////////////////////
//      Functions      //
/////////////////////////

stock SendClientMessageToGang( gangid, colour, const format[ ], va_args<> ) // Conversion to foreach 14 stuffed the define, not sure how...
{
    static
		out[ 144 ];

    va_format( out, sizeof( out ), format, va_start<3> );

	foreach(new i : Player)
	{
	    if ( ( p_GangID[ i ] == gangid || p_ViewingGangTalk[ i ] == gangid ) && p_Class[ i ] == CLASS_CIVILIAN )
			SendClientMessage( i, colour, out );
	}
	return 1;
}

stock SendGlobalMessage( colour, const format[ ], va_args<> )
{
    static
		out[ 144 ];

    va_format( out, sizeof( out ), format, va_start<2> );
	SendClientMessageToAll( colour, out );

	strreplace( out, #COL_LRED, 	"**" );
	strreplace( out, #COL_ORANGE,	"**" );
	strreplace( out, #COL_GOLD, 	"**" );
	strreplace( out, #COL_GREEN, 	"" );
	strreplace( out, #COL_BLUE, 	"**" );
	strreplace( out, #COL_PINK, 	"**" );
	strreplace( out, #COL_GREY,		"**" );
	strreplace( out, #COL_WHITE, 	"**" );
	//DCC_SendChannelMessage( discordGeneralChan, out );
	return 1;
}

function SetPlayerRandomSpawn( playerid )
{
	if ( p_LeftPaintball{ playerid } == true )
	{
		SetPlayerArmour( playerid, 0.0 );
	    SetPlayerPos( playerid, -2172.2017, 252.1113, 35.3388 );
	    p_LeftPaintball{ playerid } = false;
	    return 1;
	}

	if ( p_SpawningKey[ playerid ] [ 0 ] != '\0' )
	{
		new index = p_SpawningIndex[ playerid ];
		new gangid = p_GangID[ playerid ];

		// house spawning
		if ( strmatch( p_SpawningKey[ playerid ], "HSE" ) )
		{
			if ( Iter_Contains( houses, index ) && IsPlayerHomeOwner( playerid, index ) )
			{
			    if ( ! IsHouseOnFire( index ) )
			    {
					pauseToLoad( playerid );
					UpdatePlayerEntranceExitTick( playerid );
					p_InHouse[ playerid ] = -1, p_InBusiness[ playerid ] = -1;
				    SetPlayerInterior( playerid, 0 );
				    SetPlayerPos( playerid, g_houseData[ index ] [ E_EX ], g_houseData[ index ] [ E_EY ], g_houseData[ index ] [ E_EZ ] );
					return 1;
				}
				else SendServerMessage( playerid, "你要生成的房子着火了,因此已应用正常生成." );
			}
			else ResetSpawnLocation( playerid );
		}

		// business spawning
		else if ( strmatch( p_SpawningKey[ playerid ], "BIZ" ) )
		{
			if ( Iter_Contains( business, index ) && IsBusinessAssociate( playerid, index ) )
			{
				//new type = g_businessData[ index ] [ E_INTERIOR_TYPE ];
				pauseToLoad( playerid );
				UpdatePlayerEntranceExitTick( playerid );
				p_InHouse[ playerid ] = -1, p_InBusiness[ playerid ] = -1;
			    SetPlayerInterior( playerid, 0 );
			    SetPlayerPos( playerid, g_businessData[ index ] [ E_X ], g_businessData[ index ] [ E_Y ], g_businessData[ index ] [ E_Z ] );
				/*p_InHouse[ playerid ] = -1, p_InBusiness[ playerid ] = index;
			  	SetPlayerVirtualWorld( playerid, g_businessData[ index ] [ E_WORLD ] );
				SetPlayerInterior( playerid, g_businessData[ index ] [ E_INTERIOR_TYPE ] + 20 );
				SetPlayerPos( playerid, g_businessInteriorData[ type ] [ E_X ], g_businessInteriorData[ type ] [ E_Y ], g_businessInteriorData[ type ] [ E_Z ] );*/
				return 1;
			}
			else ResetSpawnLocation( playerid );
		}

		// gang facilities
		else if ( strmatch( p_SpawningKey[ playerid ], "GNG" ) )
		{
			if ( Iter_Contains( gangs, gangid ) && Iter_Contains( gangfacilities, index ) && g_gangData[ gangid ] [ E_SQL_ID ] == g_gangFacilities[ index ] [ E_GANG_SQL_ID ] ) {
				if ( SetPlayerToGangFacility( playerid, gangid, index ) ) {
					return 1;
				} else {
					SendServerMessage( playerid, "帮派账户余额不足, 无法在帮派设施出生." );
				}
			}
			else ResetSpawnLocation( playerid );
		}

		// visage apartment
		else if ( strmatch( p_SpawningKey[ playerid ], "VIZ" ) )
		{
			if ( Iter_Contains( visageapartments, index ) && g_VisageApartmentData[ index ] [ E_OWNER_ID ] == p_AccountID[ playerid ] ) {
				SetPlayerToVisageApartment( playerid, index );
				return 1;
			}
			else ResetSpawnLocation( playerid );
		}

		// standard apartment
		else if ( strmatch( p_SpawningKey[ playerid ], "APT" ) )
		{
			if ( NovicHotel_IsOwner( playerid, index ) ) {
				NovicHotel_SetPlayerToFloor( playerid, index );
			    return 1;
			}
			else ResetSpawnLocation( playerid );
		}
	}

	new
		city = p_SpawningCity{ playerid } >= MAX_CITIES ? random( MAX_CITIES ) : p_SpawningCity{ playerid };

	if ( p_inArmy{ playerid } == true )
		return SetPlayerPos( playerid, g_ArmySpawns[ city ] [ RANDOM_SPAWN_X ], g_ArmySpawns[ city ] [ RANDOM_SPAWN_Y ], g_ArmySpawns[ city ] [ RANDOM_SPAWN_Z ] ), 			SetPlayerInterior( playerid, g_ArmySpawns[ city ] [ RANDOM_SPAWN_INTERIOR ] ),		SetPlayerVirtualWorld( playerid, g_ArmySpawns[ city ] [ RANDOM_SPAWN_WORLD ] ), SetPlayerFacingAngle( playerid, g_ArmySpawns[ city ] [ RANDOM_SPAWN_A ] ), 1;

	if ( p_inCIA{ playerid } == true || p_inFBI{ playerid } == true )
		return SetPlayerPos( playerid, g_CIASpawns[ city ] [ RANDOM_SPAWN_X ], g_CIASpawns[ city ] [ RANDOM_SPAWN_Y ], g_CIASpawns[ city ] [ RANDOM_SPAWN_Z ] ), 				SetPlayerInterior( playerid, g_CIASpawns[ city ] [ RANDOM_SPAWN_INTERIOR ] ),		SetPlayerVirtualWorld( playerid, g_CIASpawns[ city ] [ RANDOM_SPAWN_WORLD ] ), SetPlayerFacingAngle( playerid, g_CIASpawns[ city ] [ RANDOM_SPAWN_A ] ), 1;

	if ( p_Class[ playerid ] == CLASS_POLICE )
		return SetPlayerPos( playerid, g_PoliceSpawns[ city ] [ RANDOM_SPAWN_X ], g_PoliceSpawns[ city ] [ RANDOM_SPAWN_Y ], g_PoliceSpawns[ city ] [ RANDOM_SPAWN_Z ] ), 		SetPlayerInterior( playerid, g_PoliceSpawns[ city ] [ RANDOM_SPAWN_INTERIOR ] ),	SetPlayerVirtualWorld( playerid, g_PoliceSpawns[ city ] [ RANDOM_SPAWN_WORLD ] ), SetPlayerFacingAngle( playerid, g_PoliceSpawns[ city ] [ RANDOM_SPAWN_A ] ), 1;

	if ( p_Class[ playerid ] == CLASS_CIVILIAN )
	{
		new
			r;

		switch( city )
		{
			case CITY_SF:
			{
				r = random( sizeof( g_SanFierroSpawns ) );
				SetPlayerFacingAngle( playerid, g_SanFierroSpawns[ r ] [ RANDOM_SPAWN_A ] );
				SetPlayerInterior	( playerid, g_SanFierroSpawns[ r ] [ RANDOM_SPAWN_INTERIOR ] );
				SetPlayerPos		( playerid, g_SanFierroSpawns[ r ] [ RANDOM_SPAWN_X ], g_SanFierroSpawns[ r ] [ RANDOM_SPAWN_Y ], g_SanFierroSpawns[ r ] [ RANDOM_SPAWN_Z ] );
			}
			case CITY_LV:
			{
				r = random( sizeof( g_LasVenturasSpawns ) );
				SetPlayerFacingAngle( playerid, g_LasVenturasSpawns[ r ] [ RANDOM_SPAWN_A ] );
				SetPlayerInterior	( playerid, g_LasVenturasSpawns[ r ] [ RANDOM_SPAWN_INTERIOR ] );
				SetPlayerPos		( playerid, g_LasVenturasSpawns[ r ] [ RANDOM_SPAWN_X ], g_LasVenturasSpawns[ r ] [ RANDOM_SPAWN_Y ], g_LasVenturasSpawns[ r ] [ RANDOM_SPAWN_Z ] );
			}
			case CITY_LS:
			{
				r = random( sizeof( g_LosSantosSpawns ) );
				SetPlayerFacingAngle( playerid, g_LosSantosSpawns[ r ] [ RANDOM_SPAWN_A ] );
				SetPlayerInterior	( playerid, g_LosSantosSpawns[ r ] [ RANDOM_SPAWN_INTERIOR ] );
				SetPlayerPos		( playerid, g_LosSantosSpawns[ r ] [ RANDOM_SPAWN_X ], g_LosSantosSpawns[ r ] [ RANDOM_SPAWN_Y ], g_LosSantosSpawns[ r ] [ RANDOM_SPAWN_Z ] );
			}
		}
	}
	return Y_HOOKS_CONTINUE_RETURN_1;
}

function RestoreHealthAfterBrokenOut( playerid ) return SetPlayerHealth( playerid, 100.0 );

stock IsPlayerInPoliceCar( playerid )
{
	new model = GetVehicleModel( GetPlayerVehicleID( playerid ) );
	if ( model == 425 || model == 520|| model == 497 || model == 470 || model == 432 || model == 428 || model == 523 || model == 427 || model == 490 || model >= 596 && model <= 599 || model == 601 ) return true;
	return false;
}

stock IsWeaponBanned( weaponid ) {
	return 0 <= weaponid < MAX_WEAPONS && ( weaponid == 36 || weaponid == 37 || weaponid == 38 || weaponid == 39 || weaponid == 44 || weaponid == 45 );
}

stock GivePlayerScore( playerid, score )
{
	if ( IsPlayerAdminOnDuty( playerid ) )
		return 0;

	new
		gangid = p_GangID[ playerid ];

	if ( gangid != INVALID_GANG_ID ) {
		SaveGangData( gangid ), g_gangData[ gangid ] [ E_SCORE ] += score;
	}
	return SetPlayerScore( playerid, GetPlayerScore( playerid ) + score );
}


stock GetPlayerIDFromAccountID( iAccountID )
{
    foreach(new i : Player)
    {
        if ( p_AccountID[ i ] == iAccountID )
			return i;
    }
    return INVALID_PLAYER_ID;
}

stock SetPlayerColorToTeam( playerid )
{
#if defined __cnr__chuffsec
	if ( IsPlayerSecurityDriver( playerid ) ) return SetPlayerColor( playerid, COLOR_SECURITY );
#endif

	if ( p_AdminOnDuty{ playerid } ) return SetPlayerColor( playerid, COLOR_PINK );

	switch( p_Class[ playerid ] )
	{
	    case CLASS_POLICE:
	    {
	    	SetPlayerColor( playerid, COLOR_POLICE );
			if ( p_inFBI{ playerid } ) SetPlayerColor( playerid, COLOR_FBI );
			if ( p_inCIA{ playerid } ) SetPlayerColor( playerid, COLOR_CIA );
			if ( p_inArmy{ playerid } ) SetPlayerColor( playerid, COLOR_ARMY );
	    }
	    default:
	    {
	    	new
	    		default_color = COLOR_DEFAULT;

	    	// set color according to wanted level
			if ( p_WantedLevel[ playerid ] >= 12 ) default_color = COLOR_WANTED12;
			else if ( p_WantedLevel[ playerid ] >= 6 ) default_color = COLOR_WANTED6;
			else if ( p_WantedLevel[ playerid ] >= 1 ) default_color = COLOR_WANTED2;
		    else if ( p_GangID[ playerid ] != INVALID_GANG_ID ) default_color = g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ];

		    // set alpha for invisible players to 0
	    	if ( IsPlayerHiddenFromRadar( playerid ) ) {
	    		default_color = setAlpha( default_color, 0x00 );
	    	}

	    	// force the color on the player
	    	return SetPlayerColor( playerid, default_color );
		}
	}
	return 1;
}




stock GetClosestPlayerEx( playerid, classid, &Float: distance = FLOAT_INFINITY ) {
    new
    	iCurrent = INVALID_PLAYER_ID,
        Float: fX, Float: fY,  Float: fZ, Float: fTmp,
        world = GetPlayerVirtualWorld( playerid )
    ;

    if ( GetPlayerPos( playerid, fX, fY, fZ ) )
    {
		foreach(new i : Player)
		{
			if ( i != playerid )
			{
		        if ( GetPlayerState( i ) != PLAYER_STATE_SPECTATING && GetPlayerVirtualWorld( i ) == world && p_Class[ i ] == classid )
		        {
		            if ( 0.0 < ( fTmp = GetPlayerDistanceFromPoint( i, fX, fY, fZ ) ) < distance )
		            {
		                distance = fTmp;
		                iCurrent = i;
		            }
		        }
			}
	    }
    }
    return iCurrent;
}


stock isValidPlayerName( szName[ ] )
{
	strreplacechar( szName, '\\', '-' );
	//strreplacechar( szName, '.', '-' );
	strreplacechar( szName, '/', '-' );

#if defined __cnr__chuffsec
	if ( strmatch( szName, SECURE_TRUCK_DRIVER_NAME ) )
		return false;
#endif

	if( !( 2 < strlen( szName ) < MAX_PLAYER_NAME ) )
		return false;

	return regex_match( szName, "^[a-zA-Z0-9@=_\\[\\]\\.\\(\\)\\$]+$" );
}

stock ReturnWeaponName(weaponid, bool:vipgun=false)
{
	static wname[24];
	switch(weaponid) {
	    case 0: wname = "拳头";
		case 18: wname = "燃烧弹";
		case 40: wname = "雷管";
		case 44: wname = "夜视镜";
		case 45: wname = "热成像护目镜";
		case 51: wname = "爆炸";
		case 53: wname = "淹死";
		case 54: wname = "碰撞";
		default: GetWeaponName(weaponid, wname, sizeof(wname));
	}
	if ( weaponid == 0 && vipgun == true ) wname = "没有什么";
	return wname;
}


stock ReturnGangNameColor( g )
{
	static
	    szColor[ 14 ];

	switch( g )
	{
		case 0:  szColor = "黄绿色";
		case 1:  szColor = "绿色";
		case 2:  szColor = "蓝绿色";
		case 3:  szColor = "蓝色";
		case 4:  szColor = "蓝紫色";
		case 5: szColor = "紫色";
		case 6: szColor = "红紫色";
		default: szColor = "-??-";
	}
	return szColor;
}


#if !defined __WEAPONDAMAGEINC__
stock GetWeaponSlot(weaponid)
{
    switch(weaponid)
    {
        case WEAPON_BRASSKNUCKLE:
            return 0;
        case WEAPON_GOLFCLUB .. WEAPON_CHAINSAW:
            return 1;
        case WEAPON_COLT45 .. WEAPON_DEAGLE:
            return 2;
        case WEAPON_SHOTGUN .. WEAPON_SHOTGSPA:
            return 3;
        case WEAPON_UZI, WEAPON_MP5, WEAPON_TEC9:
            return 4;
        case WEAPON_AK47, WEAPON_M4:
            return 5;
        case WEAPON_RIFLE, WEAPON_SNIPER:
            return 6;
        case WEAPON_ROCKETLAUNCHER .. WEAPON_MINIGUN:
            return 7;
        case WEAPON_GRENADE .. WEAPON_MOLTOV, WEAPON_SATCHEL:
            return 8;
        case WEAPON_SPRAYCAN .. WEAPON_CAMERA:
            return 9;
        case WEAPON_DILDO .. WEAPON_FLOWER:
            return 10;
        case 44, 45, WEAPON_PARACHUTE:
            return 11;
        case WEAPON_BOMB:
            return 12;
    }
    return -1;
}
#endif


stock IsPlayerInCar( playerid )
{
    static
		g_CarVehicles[ 93 ] =
		{
			400,401,402,404,405,410,411,412,415,418,419,420,421,422,424,426,429,434,436,
			438,439,442,445,451,458,466,467,470,474,475,477,478,480,480,480,480,489,490,
			491,492,494,496,500,501,502,503,504,505,506,507,516,517,518,526,527,529,533,
			534,535,536,540,541,542,543,545,546,547,549,550,551,555,558,559,560,561,562,
			565,566,567,575,576,580,585,587,589,596,597,598,600,602,603,604,605
		}
	;
	for( new i; i < sizeof( g_CarVehicles ); i++ )
	{
	    if ( GetVehicleModel( GetPlayerVehicleID( playerid ) ) == g_CarVehicles[ i ] )
	        return 1;
	}
	return 0;
}

stock mysql_escape( string[ ] )
{
	static
	    szEscaped[ 256 ];

	if ( strlen( string ) >= 256 ) {
		printf("BUFFER OVERFLOW: %s", string);
	}

	mysql_real_escape_string( string, szEscaped );
	return szEscaped;
}


stock ShowAchievement( playerid, achievement[ ], score = -1 )
{
	if ( score != -1 ) {
		GivePlayerScore( playerid, score );
	}
	KillTimer( p_AchievementTimer[ playerid ] );
	p_AchievementTimer[ playerid ] = 0xFF;
	PlayerTextDrawSetString( playerid, p_AchievementTD[ playerid ], achievement );
	PlayerTextDrawShow( playerid, p_AchievementTD[ playerid ] );
	TextDrawShowForPlayer( playerid, g_AchievementTD[ 0 ] );
	TextDrawShowForPlayer( playerid, g_AchievementTD[ 1 ] );
	TextDrawShowForPlayer( playerid, g_AchievementTD[ 2 ] );
	TextDrawShowForPlayer( playerid, g_AchievementTD[ 3 ] );
	PlayerPlaySound( playerid, 1183, 0, 0, 0 );
	p_AchievementTimer[ playerid ] = SetTimerEx( "Achievement_Hide", 10000, false, "d", playerid );
}

function Achievement_Hide( playerid ) {
	PlayerTextDrawHide( playerid, p_AchievementTD[ playerid ] );
	TextDrawHideForPlayer( playerid, g_AchievementTD[ 0 ] );
	TextDrawHideForPlayer( playerid, g_AchievementTD[ 1 ] );
	TextDrawHideForPlayer( playerid, g_AchievementTD[ 2 ] );
	TextDrawHideForPlayer( playerid, g_AchievementTD[ 3 ] );
    p_AchievementTimer[ playerid ] = 0xFF;
	StopSound( playerid );
    return 1;
}

stock AddAdminLogLineFormatted( const format[ ], va_args<> )
{
    static
		out[ sizeof( log__Text[ ] ) ];

    va_format( out, sizeof( out ), format, va_start<1> );
    return AddAdminLogLine( out );
}

stock AddAdminLogLine( szMessage[ sizeof( log__Text[ ] ) ] )
{
	for( new iPos = 0; iPos < sizeof( log__Text ) - 1; iPos++ )
		memcpy( log__Text[ iPos ], log__Text[ iPos + 1 ], 0, sizeof( log__Text[ ] ) * 4 );

	strcpy( log__Text[ 4 ], szMessage );
	DCC_SendChannelMessageFormatted( discordLogChan, "**[SERVER LOG]** %s" ,szMessage );

	format( szLargeString, 500,	"%s~n~%s~n~%s~n~%s~n~%s", log__Text[ 0 ], log__Text[ 1 ], log__Text[ 2 ], log__Text[ 3 ], log__Text[ 4 ] );
	return TextDrawSetString( g_AdminLogTD, szLargeString );
}

stock SaveToAdminLogFormatted( playerid, id, const format[ ], va_args<> )
{
    static
		out[ sizeof( log__Text[ ] ) ];

    va_format( out, sizeof( out ), format, va_start<3> );
    return SaveToAdminLog( playerid, id, out );
}

stock SaveToAdminLog( playerid, id, const message[ ] )
{
	if ( id ) {
		mysql_format( dbHandle, szBigString, sizeof( szBigString ), "INSERT INTO `ADMIN_LOG` (`USER_ID`, `ACTION`, `ACTION_ID`) VALUES (%d, '%e', %d)", p_AccountID[ playerid ], message, id );
	} else {
		mysql_format( dbHandle, szBigString, sizeof( szBigString ), "INSERT INTO `ADMIN_LOG` (`USER_ID`, `ACTION`) VALUES (%d, '%e')", p_AccountID[ playerid ], message );
	}
	mysql_single_query( szBigString );
	return 1;
}


stock SyncSpectation( playerid, playerstate = -1 )
{
	if ( playerstate == -1 )
		playerstate = GetPlayerState( playerid );

	if ( IsPlayerConnected( playerid ) )
	{
	    if ( p_beingSpectated[ playerid ] )
	    {
	        if ( playerstate == PLAYER_STATE_DRIVER || playerstate == PLAYER_STATE_PASSENGER )
	        {
                foreach(new i : Player) {
	                if ( p_Spectating{ i } && p_whomSpectating[ i ] == playerid ) {
						SetPlayerInterior( i, GetPlayerInterior( playerid ) );
						SetPlayerVirtualWorld( i, GetPlayerVirtualWorld( playerid ) );
						PlayerSpectateVehicle( i, GetPlayerVehicleID( playerid ) );
	                }
				}
	        }
	        else
			{
                foreach(new i : Player) {
	                if ( p_Spectating{ i } && p_whomSpectating[ i ] == playerid ) {
						SetPlayerInterior( i, GetPlayerInterior( playerid ) );
						SetPlayerVirtualWorld( i, GetPlayerVirtualWorld( playerid ) );
						PlayerSpectatePlayer( i, playerid );
	                }
				}
			}
	    }
	}
	return 1;
}

stock CutSpectation( playerid )
{
	if ( playerid < 0 || playerid > MAX_PLAYERS ) return 0;
	foreach(new i : Player) {
		if ( p_Spectating{ i } && p_whomSpectating[ i ] == playerid ) {
			p_whomSpectating[ i ] = INVALID_PLAYER_ID;
			TogglePlayerSpectating( i, 0 );
			p_Spectating{ i } = false;
			SendServerMessage( i, "已结束旁观." );
	  	}
	}
	p_beingSpectated[ playerid ] = false;
	return 1;
}

stock ForceSpectateOnPlayer( playerid, pID )
{
	if ( IsPlayerConnected( p_whomSpectating[ playerid ] ) ) {
    	p_beingSpectated[ p_whomSpectating[ playerid ] ] = false;
    	p_whomSpectating[ playerid ] = INVALID_PLAYER_ID;
	}
    p_whomSpectating[ playerid ] = pID;
    p_beingSpectated[ pID ] = true;
	SendClientMessageFormatted( playerid, -1, ""COL_PINK"[管理]"COL_WHITE" 你现在正在观看 %s(%d).", ReturnPlayerName( pID ), pID );
	SetPlayerVirtualWorld( playerid, GetPlayerVirtualWorld( pID ) );
	SetPlayerInterior( playerid, GetPlayerInterior( pID ) );
	if ( IsPlayerInAnyVehicle( pID ) )
	{
		TogglePlayerSpectating(playerid, 1),
		PlayerSpectateVehicle(playerid, GetPlayerVehicleID( pID ) );
	}
	else
	{
		TogglePlayerSpectating( playerid, 1 ),
		PlayerSpectatePlayer( playerid, pID );
	}
}


new
	p_HideHelpDialogTimer[ MAX_PLAYERS ] = { -1, ... };

stock ShowPlayerHelpDialog( playerid, timeout, const format[ ], va_args<> )
{
    static
		out[ 255 ]
	;

	if ( !IsPlayerConnected( playerid ) )
		return 0;

    va_format( out, sizeof( out ), format, va_start<3> );

    PlayerTextDrawSetString( playerid, p_HelpBoxTD[ playerid ], out );
    PlayerTextDrawShow( playerid, p_HelpBoxTD[ playerid ] );

    KillTimer( p_HideHelpDialogTimer[ playerid ] );
    p_HideHelpDialogTimer[ playerid ] = -1;

   	if ( timeout != 0 ) {
   		p_HideHelpDialogTimer[ playerid ] = SetTimerEx( "HidePlayerHelpDialog", timeout, false, "d", playerid );
   	}
	return 1;
}

function HidePlayerHelpDialog( playerid )
{
	p_HideHelpDialogTimer[ playerid ] = -1;
	PlayerTextDrawHide( playerid, p_HelpBoxTD[ playerid ] );
}

stock hasBadDrivebyWeapon( playerid )
{
	for( new i; i < sizeof g_BannedDrivebyWeapons; i++ )
		if ( g_BannedDrivebyWeapons[ i ] == GetPlayerWeapon( playerid ) )
			return true;

	return false;
}


stock CreateExplosionEx( Float: X, Float: Y, Float: Z, type, Float: radius, world, interior, issuerid = INVALID_PLAYER_ID )
{
	foreach(new i : Player) {
		if ( IsPlayerLoadingObjects( i ) ) continue;
		if ( p_BulletInvulnerbility[ i ] > g_iTime ) continue;
		if ( interior != -1 && GetPlayerInterior( i ) != interior ) continue;
		if ( world != -1 && GetPlayerVirtualWorld( i ) != world ) continue;
		//if ( IsDeathmatchProtectedZone( i ) && !p_WantedLevel[ i ] ) continue;
		if ( IsRandomDeathmatch( issuerid, i ) && issuerid != i ) continue;
		CreateExplosionForPlayer( i, X, Y, Z, type, radius );
	}
}

stock massUnjailPlayers( city, bool: alcatraz = false )
{
	foreach(new p : Player)
    {
		if ( IsPlayerAdminJailed( p ) )
			continue;

		if ( !IsPlayerInJails( p, city ) && !alcatraz )
			continue;

		//if ( IsPlayerAFK( p ) )
		//	continue;

		jailMoveGate( p, city, false, alcatraz ); // Show everyone
		if ( p_Jailed{ p } == true )
		{
			CallLocalFunction( "OnPlayerUnjailed", "dd", p, alcatraz ? 5 : 4 );
			SetPlayerHealth( p, INVALID_PLAYER_ID ); // Just ensuring.
	        SetTimerEx( "RestoreHealthAfterBrokenOut", 5000, false, "d", p );
		}
	}
}

stock IsPlayerInJails( playerid, city )
{
	static const
		g_jailIntData[ MAX_CITIES ] = { 10, 3, 6 } // Ordered SF, LV, LS
	;

	return ( GetPlayerInterior( playerid ) == g_jailIntData[ city ] );
}

stock GetPlayerBankCity( playerid )
{
	static const
		g_bankIntData[ MAX_CITIES ] [ 2 ] = { 23, 52, 56 }
	;

	for( new i = 0; i < sizeof( g_bankIntData ); i++ )
	{
		if ( GetPlayerVirtualWorld( playerid ) == g_bankIntData[ i ] && GetPlayerInterior( playerid ) == i )
			return i;
	}
	return -1;
}

stock getClosestPoliceStation( playerid )
{
	static const
		Float: g_policeStationCoords[ ] [ 3 ] =
		{
		 	{ -1605.330, 711.6586, 13.8672 }, // SF
			{ 2337.0854, 2459.313, 14.9742 }, // LV
			{ 1555.5012, -1675.63, 16.1953 }  // LS
		}
	;

    static
    	Float: X, Float: Y, Float: Z,
    	iCity, iEntrance
    ;

    if ( !GetPlayerInterior( playerid ) ) GetPlayerPos( playerid, X, Y, Z );
	else
   	{
		if ( ( iEntrance = p_LastEnteredEntrance[ playerid ] ) == -1 ) GetPlayerPos( playerid, X, Y, Z );
		else
		{
			GetEntrancePos( iEntrance, X, Y, Z );
		}
   	}

    for( new i = 0, Float: fLast = -1.0, Float: fDistance = 99999.0; i < sizeof( g_policeStationCoords ); i++ )
	{
	    fLast = GetDistanceBetweenPoints( X, Y, Z, g_policeStationCoords[ i ] [ 0 ], g_policeStationCoords[ i ] [ 1 ], g_policeStationCoords[ i ] [ 2 ] );
	    if ( fLast < fDistance && fLast ) {
	        fDistance = fLast;
	        iCity = i;
	    }
	}
    return iCity;
}

stock Achievement::HandleBurglaries( playerid )
{
   	switch( ++ p_Burglaries[ playerid ] )
   	{
        case 5:     ShowAchievement( playerid, "犯下~r~5~w~~h~~h~入室盗窃罪!", 3 );
        case 20:    ShowAchievement( playerid, "犯下~r~20~w~~h~~h~入室盗窃罪!", 6 );
        case 50:    ShowAchievement( playerid, "犯下~r~50~w~~h~~h~入室盗窃罪!", 9 );
        case 100:   ShowAchievement( playerid, "犯下~r~100~w~~h~~h~入室盗窃罪!", 12 );
        case 200:   ShowAchievement( playerid, "犯下~r~200~w~~h~~h~入室盗窃罪!", 15 );
        case 500:   ShowAchievement( playerid, "犯下~r~500~w~~h~~h~入室盗窃罪!", 18 );
        case 1000:  ShowAchievement( playerid, "犯下~r~1000~w~~h~~h~入室盗窃罪!", 25 );
	}
}

stock Achievement::HandleBankBlown( playerid )
{
	switch( ++p_BankBlown[ playerid ] )
	{
	    case 5:     ShowAchievement( playerid, "银行金库被炸毁~r~5~w~~h~~h~次!", 3 );
	    case 20:  	ShowAchievement( playerid, "银行金库被炸毁~r~20~w~~h~~h~次!", 6 );
	    case 50:   	ShowAchievement( playerid, "银行金库被炸毁~r~50~w~~h~~h~次!", 9 );
	    case 100:  	ShowAchievement( playerid, "银行金库被炸毁~r~100~w~~h~~h~次!", 12 );
	    case 200:  	ShowAchievement( playerid, "银行金库被炸毁~r~200~w~~h~~h~次!", 15 );
	    case 500:  	ShowAchievement( playerid, "银行金库被炸毁~r~500~w~~h~~h~次!", 18 );
	    case 1000: 	ShowAchievement( playerid, "银行金库被炸毁~r~1000~w~~h~~h~次!", 25 );
	}
}

stock Achievement::HandleCarJacked( playerid )
{
	switch( ++p_CarsJacked[ playerid ] )
	{
	    case 5:     ShowAchievement( playerid, "劫持~r~5~w~~h~~h~汽车!" , 3 );
	    case 20:  	ShowAchievement( playerid, "劫持~r~20~w~~h~~h~汽车!", 6 );
	    case 50:   	ShowAchievement( playerid, "劫持~r~50~w~~h~~h~汽车!", 9 );
	    case 100:  	ShowAchievement( playerid, "劫持~r~100~w~~h~~h~汽车!", 12 );
	    case 200:  	ShowAchievement( playerid, "劫持~r~200~w~~h~~h~汽车!", 15 );
	    case 500:  	ShowAchievement( playerid, "劫持~r~500~w~~h~~h~汽车!", 18 );
	    case 1000: 	ShowAchievement( playerid, "劫持~r~1000~w~~h~~h~汽车!", 25 );
	}
}

stock Achievement::HandleJailBlown( playerid )
{
	switch( ++p_JailsBlown[ playerid ] )
	{
	    case 5:     ShowAchievement( playerid, "监狱被炸~r~5~w~~h~~h~次!", 3 );
	    case 20:  	ShowAchievement( playerid, "监狱被炸~r~20~w~~h~~h~次!", 6 );
	    case 50:   	ShowAchievement( playerid, "监狱被炸~r~50~w~~h~~h~次!", 9 );
	    case 100:  	ShowAchievement( playerid, "监狱被炸~r~100~w~~h~~h~次!", 12 );
	    case 200:  	ShowAchievement( playerid, "监狱被炸~r~200~w~~h~~h~次!", 15 );
	    case 500:  	ShowAchievement( playerid, "监狱被炸~r~500~w~~h~~h~次!", 18 );
	    case 1000: 	ShowAchievement( playerid, "监狱被炸~r~1000~w~~h~~h~次!", 25 );
	}
}

stock Achievement::HandleExtinguishedFires( playerid )
{
    switch( ++p_Fires[ playerid ] )
   	{
        case 5:     ShowAchievement( playerid, "~r~5~w~~h~~h~ 火被扑灭!", 3 );
        case 20:    ShowAchievement( playerid, "~r~20~w~~h~~h~ 火被扑灭!", 6 );
        case 50:    ShowAchievement( playerid, "~r~50~w~~h~~h~ 火被扑灭!", 9 );
        case 100:   ShowAchievement( playerid, "~r~100~w~~h~~h~ 火被扑灭!", 12 );
        case 200:   ShowAchievement( playerid, "~r~200~w~~h~~h~ 火被扑灭!", 15 );
        case 500:   ShowAchievement( playerid, "~r~500~w~~h~~h~ 火被扑灭!", 18 );
        case 1000:  ShowAchievement( playerid, "~r~1000~w~~h~~h~ 火被扑灭!", 25 );
	}
}

stock Achievement::HandleMethYielded( playerid )
{
	switch( ++p_MethYielded[ playerid ] )
	{
	    case 5:     ShowAchievement( playerid, "产出~r~5~w~~h~~h~ 冰毒 袋!", 3 );
	    case 20:  	ShowAchievement( playerid, "产出~r~20~w~~h~~h~ 冰毒 袋!", 6 );
	    case 50:   	ShowAchievement( playerid, "产出~r~50~w~~h~~h~ 冰毒 袋!", 9 );
	    case 100:  	ShowAchievement( playerid, "产出~r~100~w~~h~~h~ 冰毒 袋!", 12 );
	    case 200:  	ShowAchievement( playerid, "产出~r~200~w~~h~~h~ 冰毒 袋!", 15 );
	    case 500:  	ShowAchievement( playerid, "产出~r~500~w~~h~~h~ 冰毒 袋!", 18 );
	    case 1000: 	ShowAchievement( playerid, "产出~r~1000~w~~h~~h~ 冰毒 袋!", 25 );
	}
}

stock Achievement::HandlePlayerRobbery( playerid )
{
	Streak_IncrementPlayerStreak( playerid, STREAK_ROBBERY );

	switch( ++p_Robberies[ playerid ] )
	{
	    case 5:     ShowAchievement( playerid, "抢劫~r~5~w~~h~~h~商店!", 3 );
	    case 20:    ShowAchievement( playerid, "抢劫~r~20~w~~h~~h~商店!", 6 );
	    case 50:    ShowAchievement( playerid, "抢劫~r~50~w~~h~~h~商店!", 9 );
	    case 100:   ShowAchievement( playerid, "抢劫~r~100~w~~h~~h~商店!", 12 );
	    case 200:   ShowAchievement( playerid, "抢劫~r~200~w~~h~~h~商店!", 15 );
	    case 500:   ShowAchievement( playerid, "抢劫~r~500~w~~h~~h~商店!", 18 );
	    case 1000:  ShowAchievement( playerid, "抢劫~r~1000~w~~h~~h~商店!", 25 );
	}
}

stock Achievement::HandleTruckingCouriers( playerid )
{
	switch( ++p_TruckedCargo[ playerid ] )
	{
	    case 5:     ShowAchievement( playerid, "用卡车运送~r~5~w~~h~~h~货物!", 3 );
	    case 20:    ShowAchievement( playerid, "用卡车运送~r~20~w~~h~~h~货物!", 6 );
	    case 50:    ShowAchievement( playerid, "用卡车运送~r~50~w~~h~~h~货物!", 9 );
	    case 100:   ShowAchievement( playerid, "用卡车运送~r~100~w~~h~~h~货物!", 12 );
	    case 200:   ShowAchievement( playerid, "用卡车运送~r~200~w~~h~~h~货物!", 15 );
	    case 500:   ShowAchievement( playerid, "用卡车运送~r~500~w~~h~~h~货物!", 18 );
	    case 1000:  ShowAchievement( playerid, "用卡车运送~r~1000~w~~h~~h~货物!", 25 );
	}
}

stock Achievement::HandlePilotMissions( playerid )
{
	switch( ++p_PilotMissions[ playerid ])
	{
		case 5:     ShowAchievement( playerid, "已完成 ~r~5~w~~h~~h~ 飞行任务!", 3 );
	    case 20:    ShowAchievement( playerid, "已完成 ~r~20~w~~h~~h~ 飞行任务!", 6 );
	    case 50:    ShowAchievement( playerid, "已完成 ~r~50~w~~h~~h~ 飞行任务!", 9 );
	    case 100:   ShowAchievement( playerid, "已完成 ~r~100~w~~h~~h~ 飞行任务!", 12 );
	    case 200:   ShowAchievement( playerid, "已完成 ~r~200~w~~h~~h~ 飞行任务!", 15 );
	    case 500:   ShowAchievement( playerid, "已完成 ~r~500~w~~h~~h~ 飞行任务!", 18 );
	    case 1000:  ShowAchievement( playerid, "已完成 ~r~1000~w~~h~~h~ 飞行任务!", 25 );
	}
}

thread readnamechanges( playerid, searchid )
{
	new
	    rows, fields
	;
    cache_get_data( rows, fields );

    if ( rows )
    {
    	new
    		szTime[ 20 ],
    		szName[ MAX_PLAYER_NAME ]
    	;

        szLargeString = ""COL_GREY"时间\t\t\t姓名\n" #COL_WHITE;

    	for( new i = 0; i < rows; i++ )
		{
			cache_get_field_content( i, "NAME", szName );
			cache_get_field_content( i, "TIME", szTime );

			format( szLargeString, sizeof( szLargeString ), "%s%s\t%s\n", szLargeString, szTime, szName );
		}

		ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, sprintf( "{FFFFFF}%s(%d) 的名称变更", ReturnPlayerName( searchid ), searchid ), szLargeString, "确定", "" );
		return 1;
	}
	SendError( playerid, "该用户最近没有更改过姓名." );
	return 1;
}

thread readmoneylog( playerid, searchid )
{
	new
	    rows, fields
	;
    cache_get_data( rows, fields );

    if ( rows )
    {
    	new
    		szTime[ 20 ],
    		szName[ MAX_PLAYER_NAME ],
    		iCashMoney
    	;

        szLargeString = COL_WHITE # "发送至\t" #COL_WHITE "金额\t" #COL_WHITE "时间\n";

    	for( new i = 0; i < rows; i++ )
		{
			cache_get_field_content( i, "NAME", szName );
			cache_get_field_content( i, "DATE", szTime );
			iCashMoney = cache_get_field_content_int( i, "CASH", dbHandle );

			format( szLargeString, sizeof( szLargeString ), "%s%s\t%s\t%s\n", szLargeString, szName, cash_format( iCashMoney ), szTime );
		}

		ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST_HEADERS, sprintf( "{FFFFFF}%s(%d) 发送的交易", ReturnPlayerName( searchid ), searchid ), szLargeString, "确定", "" );
		return 1;
	}
	SendError( playerid, "该用户最近没有进行任何交易." );
	return 1;
}

thread readiclog( playerid, searchid )
{
	new
	    rows, fields
	;
    cache_get_data( rows, fields );

    if ( rows )
    {
    	new
    		szTime[ 20 ],
    		szName[ MAX_PLAYER_NAME ],
    		Float: fCoins
    	;

        szLargeString = COL_WHITE # "时间\t" #COL_WHITE "发送至\t" #COL_WHITE "金额\n";

    	for( new i = 0; i < rows; i++ )
		{
			cache_get_field_content( i, "NAME", szName );
			cache_get_field_content( i, "DATE", szTime );
			fCoins = cache_get_field_content_float( i, "IC", dbHandle );

			format( szLargeString, sizeof( szLargeString ), "%s%s\t%s\t%f\n", szLargeString, szTime, szName, fCoins );
		}

		ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST_HEADERS, sprintf( "{FFFFFF}IC %s(%d) 发送的交易", ReturnPlayerName( searchid ), searchid ), szLargeString, "确定", "" );
		return 1;
	}
	SendError( playerid, "该用户最近没有进行任何 IC 交易." );
	return 1;
}


stock IsPlayerInBank( playerid )
{
	new
		world = GetPlayerVirtualWorld( playerid );

	return GetPlayerInterior( playerid ) < 3 && world == GetBankVaultWorld( CITY_SF ) || world == GetBankVaultWorld( CITY_LS ) || world == GetBankVaultWorld( CITY_LV );
}

stock displayAchievements( playerid, dialogid = DIALOG_NULL, szSecondButton[ ] = "", forid = INVALID_PLAYER_ID )
{
	static
		szAchievements[ 1500 ];

	format( szAchievements, sizeof( szAchievements ),
		""COL_GREY"玩了\t\t\t%s10m\t%s1h\t%s5h\t%s10h\t%s15h\t%s20h\t%s1d\n",
		Ach_Unlock( p_Uptime[ playerid ], 1200 ), 		Ach_Unlock( p_Uptime[ playerid ], 3600 ), 		Ach_Unlock( p_Uptime[ playerid ], 18000 ),
		Ach_Unlock( p_Uptime[ playerid ], 36000 ), 		Ach_Unlock( p_Uptime[ playerid ], 54000 ), 		Ach_Unlock( p_Uptime[ playerid ], 72000 ),
		Ach_Unlock( p_Uptime[ playerid ], 86400 )
	);
	format( szAchievements, sizeof( szAchievements ),
		"%s"COL_GREY"击杀数\t\t\t%s5\t%s20\t%s50\t%s100\t%s200\t%s500\t%s1000\n", szAchievements,
		Ach_Unlock( p_Kills[ playerid ], 5 ), 			Ach_Unlock( p_Kills[ playerid ], 20 ),     		Ach_Unlock( p_Kills[ playerid ], 50 ),
		Ach_Unlock( p_Kills[ playerid ], 100 ), 		Ach_Unlock( p_Kills[ playerid ], 200 ),    		Ach_Unlock( p_Kills[ playerid ], 500 ),
		Ach_Unlock( p_Kills[ playerid ], 1000 )
	);
	format( szAchievements, sizeof( szAchievements ),
		"%s"COL_GREY"被捕的罪犯\t\t%s5\t%s20\t50\t%s100\t%s200\t%s500\t%s1000\n", szAchievements,
		Ach_Unlock( p_Arrests[ playerid ], 5 ),     	Ach_Unlock( p_Arrests[ playerid ], 20 ),    	Ach_Unlock( p_Arrests[ playerid ], 50 ),
		Ach_Unlock( p_Arrests[ playerid ], 100 ),   	Ach_Unlock( p_Arrests[ playerid ], 200 ),   	Ach_Unlock( p_Arrests[ playerid ], 500 ),
		Ach_Unlock( p_Arrests[ playerid ], 1000 )
	);

	format( szAchievements, sizeof( szAchievements ),
		"%s"COL_GREY"抢劫总数\t\t%s5\t%s20\t%s50\t%s100\t%s200\t%s500\t%s1000\n", szAchievements,
		Ach_Unlock( p_Robberies[ playerid ], 5 ),		Ach_Unlock( p_Robberies[ playerid ], 20 ),		Ach_Unlock( p_Robberies[ playerid ], 50 ),
		Ach_Unlock( p_Robberies[ playerid ], 100 ),		Ach_Unlock( p_Robberies[ playerid ], 200 ),		Ach_Unlock( p_Robberies[ playerid ], 500 ),
		Ach_Unlock( p_Robberies[ playerid ], 1000 )
	);

	format( szAchievements, sizeof( szAchievements ),
		"%s"COL_GREY"扑灭的大火\t\t%s5\t%s20\t%s50\t%s100\t%s200\t%s500\t%s1000\n", szAchievements,
		Ach_Unlock( p_Fires[ playerid ], 5 ),     		Ach_Unlock( p_Fires[ playerid ], 20 ),    		Ach_Unlock( p_Fires[ playerid ], 50 ),
		Ach_Unlock( p_Fires[ playerid ], 100 ),   		Ach_Unlock( p_Fires[ playerid ], 200 ),   		Ach_Unlock( p_Fires[ playerid ], 500 ),
		Ach_Unlock( p_Fires[ playerid ], 1000 )
	);
	format( szAchievements, sizeof( szAchievements ),
		"%s"COL_GREY"已完成的悬赏\t\t%s5\t%s20\t%s50\t%s100\t%s200\t%s500\t%s1000\n", szAchievements,
		Ach_Unlock( p_HitsComplete[ playerid ], 5 ),     Ach_Unlock( p_HitsComplete[ playerid ], 20 ), 	Ach_Unlock( p_HitsComplete[ playerid ], 50 ),
		Ach_Unlock( p_HitsComplete[ playerid ], 100 ),   Ach_Unlock( p_HitsComplete[ playerid ], 200 ), Ach_Unlock( p_HitsComplete[ playerid ], 500 ),
		Ach_Unlock( p_HitsComplete[ playerid ], 1000 )
	);
	format( szAchievements, sizeof( szAchievements ),
		"%s"COL_GREY"盗窃罪\t\t%s5\t%s20\t%s50\t%s100\t%s200\t%s500\t%s1000\n", szAchievements,
		Ach_Unlock( p_Burglaries[ playerid ], 5 ),     	Ach_Unlock( p_Burglaries[ playerid ], 20 ),    	Ach_Unlock( p_Burglaries[ playerid ], 50 ),
		Ach_Unlock( p_Burglaries[ playerid ], 100 ),   	Ach_Unlock( p_Burglaries[ playerid ], 200 ),   	Ach_Unlock( p_Burglaries[ playerid ], 500 ),
		Ach_Unlock( p_Burglaries[ playerid ], 1000 )
	);
	format( szAchievements, sizeof( szAchievements ),
		"%s"COL_GREY"产出冰毒袋\t\t%s5\t%s20\t%s50\t%s100\t%s200\t%s500\t%s1000\n", szAchievements,
		Ach_Unlock( p_MethYielded[ playerid ], 5 ),     Ach_Unlock( p_MethYielded[ playerid ], 20 ),    Ach_Unlock( p_MethYielded[ playerid ], 50 ),
		Ach_Unlock( p_MethYielded[ playerid ], 100 ),   Ach_Unlock( p_MethYielded[ playerid ], 200 ),   Ach_Unlock( p_MethYielded[ playerid ], 500 ),
		Ach_Unlock( p_MethYielded[ playerid ], 1000 )
	);
	format( szAchievements, sizeof( szAchievements ),
		"%s"COL_GREY"汽车被劫\t\t\t%s5\t%s20\t%s50\t%s100\t%s200\t%s500\t%s1000\n", szAchievements,
		Ach_Unlock( p_CarsJacked[ playerid ], 5 ),     	Ach_Unlock( p_CarsJacked[ playerid ], 20 ),    	Ach_Unlock( p_CarsJacked[ playerid ], 50 ),
		Ach_Unlock( p_CarsJacked[ playerid ], 100 ),   	Ach_Unlock( p_CarsJacked[ playerid ], 200 ),   	Ach_Unlock( p_CarsJacked[ playerid ], 500 ),
		Ach_Unlock( p_CarsJacked[ playerid ], 1000 )
	);
	format( szAchievements, sizeof( szAchievements ),
		"%s"COL_GREY"炸毁银行金库\t\t%s5\t%s20\t%s50\t%s100\t%s200\t%s500\t%s1000\n", szAchievements,
		Ach_Unlock( p_BankBlown[ playerid ], 5 ),     	Ach_Unlock( p_BankBlown[ playerid ], 20 ),    	Ach_Unlock( p_BankBlown[ playerid ], 50 ),
		Ach_Unlock( p_BankBlown[ playerid ], 100 ),   	Ach_Unlock( p_BankBlown[ playerid ], 200 ),   	Ach_Unlock( p_BankBlown[ playerid ], 500 ),
		Ach_Unlock( p_BankBlown[ playerid ], 1000 )
	);
	format( szAchievements, sizeof( szAchievements ),
		"%s"COL_GREY"炸毁牢房\t\t\t%s5\t%s20\t%s50\t%s100\t%s200\t%s500\t%s1000\n", szAchievements,
		Ach_Unlock( p_JailsBlown[ playerid ], 5 ),     	Ach_Unlock( p_JailsBlown[ playerid ], 20 ),    	Ach_Unlock( p_JailsBlown[ playerid ], 50 ),
		Ach_Unlock( p_JailsBlown[ playerid ], 100 ),   	Ach_Unlock( p_JailsBlown[ playerid ], 200 ),   	Ach_Unlock( p_JailsBlown[ playerid ], 500 ),
		Ach_Unlock( p_JailsBlown[ playerid ], 1000 )
	);
	format( szAchievements, sizeof( szAchievements ),
		"%s"COL_GREY"卡车运输货物总量\t\t%s5\t%s20\t%s50\t%s100\t%s200\t%s500\t%s1000\n", szAchievements,
		Ach_Unlock( p_TruckedCargo[ playerid ], 5 ),     Ach_Unlock( p_TruckedCargo[ playerid ], 20 ),    	Ach_Unlock( p_TruckedCargo[ playerid ], 50 ),
		Ach_Unlock( p_TruckedCargo[ playerid ], 100 ),   Ach_Unlock( p_TruckedCargo[ playerid ], 200 ),   	Ach_Unlock( p_TruckedCargo[ playerid ], 500 ),
		Ach_Unlock( p_TruckedCargo[ playerid ], 1000 )
	);
	format( szAchievements, sizeof( szAchievements ),
		"%s"COL_GREY"飞行员任务总数\t\t%s5\t%s20\t%s50\t%s100\t%s200\t%s500\t%s1000\n", szAchievements,
		Ach_Unlock( p_PilotMissions[ playerid ], 5 ),     Ach_Unlock( p_PilotMissions[ playerid ], 20 ),    	Ach_Unlock( p_PilotMissions[ playerid ], 50 ),
		Ach_Unlock( p_PilotMissions[ playerid ], 100 ),   Ach_Unlock( p_PilotMissions[ playerid ], 200 ),   	Ach_Unlock( p_PilotMissions[ playerid ], 500 ),
		Ach_Unlock( p_PilotMissions[ playerid ], 1000 )
	);

	if ( !IsPlayerConnected( forid ) ) forid = playerid;
	ShowPlayerDialog( forid, dialogid, DIALOG_STYLE_MSGBOX, "{FFFFFF}成就", szAchievements, "确定", szSecondButton );
}

stock PlainUnjailPlayer( playerid )
{
	p_inAlcatraz{ playerid } = false;
    p_Jailed 	{ playerid } = false;
    p_JailTime 	[ playerid ] = 0;

	format( szNormalString, sizeof( szNormalString ), "UPDATE USERS SET JAIL_TIME=0,JAIL_ADMIN=0 WHERE ID=%d", p_AccountID[ playerid ] );
	mysql_single_query( szNormalString );

    KillTimer( p_JailTimer[ playerid ] );
	PlayerTextDrawHide( playerid, p_JailTimeTD[ playerid ] );
}

stock isNotNearPlayer( playerid, nearid, Float: distance = 200.0 )
{
	if ( ! IsPlayerNPC( playerid ) && ( GetTickCount( ) - p_AFKTime[ playerid ] ) >= 500 )
		return 0;

	if ( ! IsPlayerConnected( nearid ) )
		return 1;

	if ( IsPlayerAFK( nearid ) )
		return 1;

	new
		Float: X, Float: Y, Float: Z;

	if ( GetPlayerInterior( playerid ) == GetPlayerInterior( nearid ) && GetPlayerVirtualWorld( playerid ) == GetPlayerVirtualWorld( nearid ) ) {
		GetPlayerPos( nearid, X, Y, Z );
	} else {
		GetPlayerOutsidePos( nearid, X, Y, Z );
	}
	return GetPlayerDistanceFromPoint( playerid, X, Y, Z ) > distance ? 1 : 0;
}


stock GetPlayerLocation( iPlayer, szCity[ ], szLocation[ ] )
{
	static
		Float: X, Float: Y, Float: Z;

	GetPlayerOutsidePos( iPlayer, X, Y, Z );

	Get2DCity( szCity, X, Y, Z );
	GetZoneFromCoordinates( szLocation, X, Y, Z );
	return true;
}

stock WarnPlayerClass( playerid, bool: bArmy = false, iPoints = 1 )
{
	new
		iWarns = bArmy ? ( p_ArmyBanned{ playerid } += iPoints ) : ( p_CopBanned{ playerid } += iPoints );

	if ( iWarns > MAX_CLASS_BAN_WARNS )
		iWarns = bArmy ? ( p_ArmyBanned{ playerid } = MAX_CLASS_BAN_WARNS ) : ( p_CopBanned{ playerid } = MAX_CLASS_BAN_WARNS );

	if ( p_Class[ playerid ] != CLASS_CIVILIAN && iWarns >= MAX_CLASS_BAN_WARNS )
		SetPlayerHealth( playerid, -1 ), ForceClassSelection( playerid );

	if ( iWarns >= MAX_CLASS_BAN_WARNS )
		SendServerMessage( playerid, "你因多次违规被禁止使用%s阵营, 请输入"COL_GREY"/unbanme"COL_WHITE"解除限制.", bArmy ? ( "军队" ) : ( "警察" ) );

	mysql_single_query( sprintf( "UPDATE `USERS` SET `%s`=%d WHERE ID=%d", bArmy ? ( "ARMY_BAN" ) : ( "COP_BAN" ), iWarns, p_AccountID[ playerid ] ) );

	return iWarns;
}

stock IsRandomDeathmatch( issuerid, damagedid )
{
	if ( issuerid != INVALID_PLAYER_ID && damagedid != INVALID_PLAYER_ID )
	{
		new
			iW = p_WantedLevel[ issuerid ], 	iC = p_Class[ issuerid ],
			dW = p_WantedLevel[ damagedid ], 	dC = p_Class[ damagedid ]
		;

		if ( IsPlayerInMinigame( damagedid ) || IsPlayerInMinigame( issuerid ) )
			return true;

		if ( IsPlayerBoxing( issuerid ) )
			return false;

		if ( ! IsPlayerInCasino( issuerid ) || ! IsPlayerInCasino( damagedid ) )
			return false;

		return ( !iW && iC != CLASS_POLICE && !dW && dC != CLASS_POLICE ) || ( iW && iC != CLASS_POLICE && !dW && dC != CLASS_POLICE ) || ( !iW && iC != CLASS_POLICE && dW && dC != CLASS_POLICE ) || ( !iW && iC != CLASS_POLICE && dC == CLASS_POLICE );
	}
	return false;
}

stock IsPlayerInCasino( playerid ) {
	new world = GetPlayerVirtualWorld( playerid );
	if ( GetPlayerState( playerid ) != PLAYER_STATE_ONFOOT ) return 0;
	if ( GetPlayerInterior( playerid ) == VISAGE_INTERIOR && world == VISAGE_WORLD ) return 1; // visage itself
	if ( IsPlayerInRangeOfPoint( playerid, 100.0, 1993.0846, 1904.5693, 84.2848 ) && world != 0 ) return 1; // visage apartments
	if ( IsPlayerInRangeOfPoint( playerid, 10.0, -792.8680, 661.2518, 19.3380 ) && world == 0 ) return 1; // roycegate mansion
	if ( IsPlayerInRangeOfPoint( playerid, 20.0, -1282.3674, -737.2510, 70.2538 ) && world == 0 ) return 1; // richxkid mansion
	return ( GetPlayerInterior( playerid ) == 10 && GetPlayerVirtualWorld( playerid ) == 23 ) || ( GetPlayerInterior( playerid ) == 1 && GetPlayerVirtualWorld( playerid ) == 82 );
}

stock SetPlayerPosition( playerid, Float: x, Float: y, Float: z, interiorid = 0, worldid = 0 )
{
	new
		vehicleid = GetPlayerVehicleID( playerid );

    SetPlayerInterior( playerid, interiorid );
    SetPlayerVirtualWorld( playerid, worldid );

	if ( 0 < vehicleid < MAX_VEHICLES )
	{
		SetVehicleVirtualWorld( vehicleid, worldid );
		LinkVehicleToInterior( vehicleid, interiorid );
		return SetVehiclePos( vehicleid, x, y, z );
	}

	return SetPlayerPos( playerid, x, y, z );
}

thread OnNewNameCheckBanned( playerid, Float: iCoinRequirement, newName[ ] )
{
	new
	    rows;

	cache_get_data( rows, tmpVariable );

	if ( !rows )
	{
	  	return mysql_function_query( dbHandle, sprintf( "SELECT `NAME` FROM `USERS` WHERE `NAME` = '%s'", mysql_escape( newName ) ), true, "OnPlayerChangeName", "dfs", playerid, iCoinRequirement, newName ), 1;
	}
	else
	{
		SendError( playerid, "此名称目前已被封禁.请选择其他名称." );
		return ShowPlayerDialog( playerid, DIALOG_CHANGENAME, DIALOG_STYLE_INPUT, "更改你的名字", ""COL_WHITE"你希望你的新名字是什么?而且,还要仔细检查!", "改变", "返回" ), 1;
	}
}

thread OnPlayerChangeName( playerid, Float: iCoinRequirement, newName[ ] )
{
	new
	    rows, fields
	;
	cache_get_data( rows, fields );

	if ( !rows )
	{
	 	mysql_single_query( sprintf( "UPDATE `USERS` SET `NAME` = '%s' WHERE `NAME` = '%s'", mysql_escape( newName ), mysql_escape( ReturnPlayerName( playerid ) ) ) );
	 	mysql_single_query( sprintf( "INSERT INTO `NAME_CHANGES`(`USER_ID`,`ADMIN_ID`,`NAME`) VALUES (%d,0,'%s')", p_AccountID[ playerid ], mysql_escape( ReturnPlayerName( playerid ) ) ) );

	 	// double check if valid coin requirement
	 	if ( iCoinRequirement ) {
			GivePlayerIrresistibleCoins( playerid, -iCoinRequirement );
			SendServerMessage( playerid, "你已将名字更改为 %s IC 代币!", number_format( iCoinRequirement, .decimals = 0 ) );
	 	}

    	// Update houses (furniture also?)
	 	mysql_single_query( sprintf( "UPDATE `HOUSES` SET `OWNER` = '%s' WHERE `OWNER` = '%s'", mysql_escape( newName ), mysql_escape( ReturnPlayerName( playerid ) ) ) );

    	foreach ( new i : houses ) if ( IsPlayerHomeOwner( playerid, i ) ) {
			format( g_houseData[ i ] [ E_OWNER ], 24, "%s", newName );
			format( szBigString, sizeof( szBigString ), ""COL_GOLD"房子:"COL_WHITE" %s(%d)\n"COL_GOLD"所有者:"COL_WHITE" %s\n"COL_GOLD"价格:"COL_WHITE" %s", g_houseData[ i ] [ E_HOUSE_NAME ], i, g_houseData[ i ] [ E_OWNER ], cash_format( g_houseData[ i ] [ E_COST ] ) );
			UpdateDynamic3DTextLabelText( g_houseData[ i ] [ E_LABEL ] [ 0 ], COLOR_WHITE, szBigString );
    	}

    	// Update apartments
    	NovicHotel_UpdateOwnerName( playerid, newName );

    	// Update username
		SetPlayerName( playerid, newName );

    	// Update garages
    	UpdatePlayerGarageTitles( playerid );
	}
	else
	{
		SendError( playerid, "该名称已被占用." );
		ShowPlayerDialog( playerid, DIALOG_CHANGENAME, DIALOG_STYLE_INPUT, "更改你的名字", ""COL_WHITE"你希望你的新名字是什么?而且,还要仔细检查!", "改变", "返回" );
	}
	return 1;
}


stock GivePlayerLeoWeapons( playerid ) {
	GivePlayerWeapon( playerid, 3, 1 );
	GivePlayerWeapon( playerid, 22, 250 );
	GivePlayerWeapon( playerid, 31, 250 );
	//GivePlayerWeapon( playerid, 41, 0xFFFF );

	if ( p_inFBI{ playerid } == true )
	{
		GivePlayerWeapon( playerid, 29, 250 );
		GivePlayerWeapon( playerid, 34, 100 );
		GivePlayerWeapon( playerid, 27, 250 );
	}

	if ( p_inCIA{ playerid } == true )
		GivePlayerWeapon( playerid, 29, 200 );

	if ( p_inArmy{ playerid } == true )
	{
	    //GivePlayerWeapon( playerid, 4, 1 );
	    GivePlayerWeapon( playerid, 24, 200 );
	    GivePlayerWeapon( playerid, 29, 200 );
	    GivePlayerWeapon( playerid, 31, 200 );
		GivePlayerWeapon( playerid, 27, 200 );
	    GivePlayerWeapon( playerid, 16, 5 );
		//GivePlayerWeapon( playerid, 34, 100 );
	}
}


function ope_Unfreeze( a )
{
	if ( IsPlayerTied( a ) || IsPlayerTazed( a ) )
		return;

	TogglePlayerControllable( a, 1 );
}

stock SendClientMessageToAdmins( colour, const format[ ], va_args<> ) // Conversion to foreach 14 stuffed the define, not sure how...
{
    static
		out[ 144 ];

    va_format( out, sizeof( out ), format, va_start<2> );

	foreach(new i : Player)
	{
	    if ( p_AdminLevel[ i ] > 0 || IsPlayerUnderCover( i ) )
			SendClientMessage( i, colour, out );
	}
	return 1;
}

stock TextDrawShowForAllSpawned( Text: textdrawid ) {
	foreach(new i : Player) if ( IsPlayerSpawned( i ) ) {
		TextDrawShowForPlayer( i, textdrawid );
	}
}

stock IsVehicleOccupied( vehicleid, bool: include_vehicle_interior = false )
{
	if ( ! IsValidVehicle( vehicleid ) )
		return -1;

	new
		iModel = GetVehicleModel( vehicleid );

	foreach ( new i : Player ) {
	    if ( GetPlayerVehicleID( i ) == vehicleid )
	    	return i;

		if ( include_vehicle_interior && IsPlayerSpawned( i ) && ( GetPlayerMethLabVehicle( i ) == vehicleid && iModel == 508 ) || ( GetPlayerShamalVehicle( i ) == vehicleid && iModel == 519 ) )
			return i;
	}
	return -1;
}

stock ShowPlayerAirportMenu( playerid )
{
	if ( GetPlayerCasinoRewardsPoints( playerid ) >= 5.0 ) {
		return ShowPlayerDialog( playerid, DIALOG_AIRPORT, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}机场", ""COL_WHITE"城市\t"COL_WHITE"赌场奖励积分\n圣菲耶罗\t"COL_GOLD"5.00 分\n拉斯文图拉斯\t"COL_GOLD"5.00 点\n洛斯桑托斯\t"COL_GOLD"5.00 点", "旅行", "取消" );
	}
	return ShowPlayerDialog( playerid, DIALOG_AIRPORT, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}机场", ""COL_WHITE"城市\t"COL_WHITE"成本\n圣菲耶罗\t"COL_GOLD"$2,000\n拉斯文图拉斯\t"COL_GOLD"$2,000\n洛桑托斯\t"COL_GOLD"$2,000", "旅行", "取消" );
}

stock GetPlayerFireworks( playerid ) return p_Fireworks[ playerid ];
stock GivePlayerFireworks( playerid, fireworks ) {
	p_Fireworks[ playerid ] += fireworks;
	mysql_single_query( sprintf( "UPDATE `USERS` SET `FIREWORKS`=%d WHERE `ID`=%d", p_Fireworks[ playerid ], p_AccountID[ playerid ] ) );
	return 1;
}

stock ShowPlayerSpawnMenu( playerid ) {
	return ShowPlayerDialog( playerid, DIALOG_SPAWN, DIALOG_STYLE_LIST, "{FFFFFF}生成位置", ""COL_GREY"重置回默认值\n房屋\n商业\n帮派设施\n维萨奇赌场", "选择", "取消" );
}

stock IsPlayerAFK( playerid ) return ( ( GetTickCount( ) - p_AFKTime[ playerid ] ) >= 2595 );

stock GetPlayerVIPDuration( playerid ) return p_VIPExpiretime[ playerid ] - g_iTime;

#if !defined __cloudy_event_system
stock IsPlayerInEvent( playerid ) return ( GetPlayerVirtualWorld( playerid ) == 69 );
#endif

stock UpdatePlayerEntranceExitTick( playerid, seconds = 2 ) {
	p_EntranceTimestamp[ playerid ] = g_iTime + seconds;
}

stock CanPlayerExitEntrance( playerid ) return g_iTime > p_EntranceTimestamp[ playerid ] && ! p_pausedToLoad{ playerid };

stock IsBuyableVehicle( vehicleid ) return g_buyableVehicle{ vehicleid };

stock IsPlayerInMinigame( playerid ) {
	return IsPlayerInPaintBall( playerid ) || IsPlayerDueling( playerid ) || IsPlayerPlayingPool( playerid ) || IsPlayerPlayingPoker( playerid ) || IsPlayerInBattleRoyale( playerid );
}

stock SendClientMessageToCops( colour, const format[ ], va_args<> )
{
    static
		out[ 144 ];

    va_format( out, sizeof( out ), format, va_start<2> );

	foreach ( new i : Player ) if ( p_Class[ i ] == CLASS_POLICE ) {
		SendClientMessage( i, colour, out );
	}
	return 1;
}

stock GetPlayerOutsidePos( playerid, &Float: X, &Float: Y, &Float: Z ) // gets the player position, if interior then the last checkpoint position
{
	new
		entranceid = p_LastEnteredEntrance[ playerid ],
		houseid = p_InHouse[ playerid ],
		garageid = p_InGarage[ playerid ]
	;

	if ( GetPlayerInterior( playerid ) != 0 || IsPlayerInBank( playerid ) )
	{
	    if ( entranceid != -1 )
	    	GetEntrancePos( entranceid, X, Y, Z );

	  	else if ( garageid != -1 )
	    	GetGaragePos( garageid, X, Y, Z );

	  	else if ( houseid != -1 )
	    	GetHousePos( houseid, X, Y, Z );

  		else GetPlayerPos( playerid, X, Y, Z );
	}
  	else
  	{
  		GetPlayerPos( playerid, X, Y, Z );
  	}
  	return 1;
}

stock IsPlayerBelowSeaLevel( playerid )
{
	new Float: z;

	GetPlayerPos( playerid, z, z, z );

	return z < -2.0;
}

stock IsPlayerDead( playerid )
{
	new
		Float: health;

	if ( GetPlayerHealth( playerid, health ) )
		return health <= 0.0;

	return GetPlayerState( playerid ) == PLAYER_STATE_WASTED;
}

stock IsPlayerInArmyVehicle( playerid )
{
	new
		vehicleid = GetPlayerVehicleID( playerid ),
		vehiclemodelid = GetVehicleModel( vehicleid )
	;

	if ( vehiclemodelid == 425 || vehiclemodelid == 432 || vehiclemodelid == 520 ) //Rhino, Tank, Hydra
		return true;
	else
		return false;
}

new playersPeakCount = 0;

stock UpdatePlayerCounters()
{
	new total_online = Iter_Count( Player );

	if ( total_online > playersPeakCount ) playersPeakCount = total_online;
}

CMD:peak( playerid, params[] )
{
	if ( p_AdminLevel[ playerid ] != 6 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	return SendClientMessageFormatted( playerid, -1, ""COL_PINK"[管理]"COL_WHITE" 自启动以来当前的峰值玩家数量为:%i", playersPeakCount );
}
