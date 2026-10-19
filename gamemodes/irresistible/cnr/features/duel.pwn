/*
 * Irresistible Gaming (c) 2018
 * Developed by Stev
 * Module: cnr/features/duel.pwn
 * Purpose: player dueling system
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define COL_DUEL 					"{B74AFF}"

/* ** Variables ** */
enum E_DUEL_DATA
{
	E_PLAYER,						E_WEAPON[ 2 ],						E_BET,
	Float: E_ARMOUR, 				Float: E_HEALTH, 					E_COUNTDOWN,
	E_TIMER, 						E_LOCATION_ID, 						E_ROUNDS,
	bool: E_CAC
};

enum E_DUEL_LOCATION_DATA
{
	E_NAME [ 22 ],					Float: E_POS_ONE[ 3 ], 				Float: E_POS_TWO[ 3 ]
};

new
	Float: g_DuelCoordinates 		[ 3 ] = 							{ -2226.1938, 251.9206, 35.3203 },
	g_WeaponList					[ ] = 								{ 0, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34 },
	g_duelData 						[ MAX_PLAYERS ][ E_DUEL_DATA ],
	g_duelLocationData 				[ ][ E_DUEL_LOCATION_DATA ] =
	{
		{ "圣玛丽亚海滩",		{ 369.75770, -1831.576, 7.67190 }, { 369.65890, -1871.215, 7.67190 } },
		{ "格林格拉斯学院",		{ 1078.0353, 1084.4989, 10.8359 }, { 1095.4019, 1064.7239, 10.8359 } },
		{ "棒球竞技场",			{ 1393.0995, 2177.4585, 9.75780 }, { 1377.7881, 2195.4214, 9.75780 } },
		{ "奇利亚德山",			{ -2318.471, -1632.880, 483.703 }, { -2329.174, -1604.657, 483.760 } },
		{ "农场",				{ -1044.856, -996.8120, 129.218 }, { -1125.599, -996.7523, 129.218 } },
		{ "网球场",			{ 755.93790, -1280.710, 13.5565 }, { 755.93960, -1238.688, 13.5516 } },
		{ "海底世界",		{ 520.59600, -2125.663, -28.257 }, { 517.96600, -2093.610, -28.257 } },
		{ "格罗夫街",			{ 2476.4580, -1668.631, 13.3249 }, { 2501.1560, -1667.655, 13.3559 } },
		{ "海洋码头",			{ 2683.5440, -2485.137, 13.5425 }, { 2683.8470, -2433.726, 13.5553 } },
		{ "加西亚棒球场",	{ -2305.7549, 92.3505, 35.3516  }, { -2322.0908, 108.5021, 35.3984 } }
	},

	bool: p_playerDueling			[ MAX_PLAYERS char ],
	p_duelInvitation           		[ MAX_PLAYERS ][ MAX_PLAYERS ],

	g_DuelCheckpoint				= -1
;

/* ** Hooks ** */
hook OnScriptInit( )
{
	CreateDynamicMapIcon( g_DuelCoordinates[ 0 ], g_DuelCoordinates[ 1 ], g_DuelCoordinates[ 2 ], 23, 0, -1, -1, -1, 750.0 );
	g_DuelCheckpoint = CreateDynamicCP( g_DuelCoordinates[ 0 ], g_DuelCoordinates[ 1 ], g_DuelCoordinates[ 2 ], 1.5, 0, 0, -1 );
	CreateDynamic3DTextLabel( ""COL_GOLD"[决斗玩家]", -1, g_DuelCoordinates[ 0 ], g_DuelCoordinates[ 1 ], g_DuelCoordinates[ 2 ], 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1 );

	return 1;
}

hook OnPlayerConnect( playerid )
{
	p_playerDueling{ playerid } 				= false;
	g_duelData[ playerid ][ E_PLAYER ] 			= INVALID_PLAYER_ID;
	g_duelData[ playerid ][ E_WEAPON ][ 0 ] 	= 0;
	g_duelData[ playerid ][ E_WEAPON ][ 1 ] 	= 0;
	g_duelData[ playerid ][ E_HEALTH ] 			= 100.0;
	g_duelData[ playerid ][ E_ARMOUR ] 			= 100.0;
	g_duelData[ playerid ][ E_BET ] 			= 0;
	return 1;
}

hook OnPlayerDisconnect( playerid, reason )
{
	forfeitPlayerDuel( playerid );
	return 1;
}

#if defined AC_INCLUDED
hook OnPlayerDeathEx(playerid, killerid, reason, Float: damage, bodypart)
#else
hook OnPlayerDeath(playerid, killerid, reason)
#endif
{
	forfeitPlayerDuel( playerid );
	return 1;
}

hook SetPlayerRandomSpawn( playerid )
{
	if ( IsPlayerDueling( playerid ))
	{
		// teleport back to pb
		SetPlayerPos( playerid, g_DuelCoordinates[0], g_DuelCoordinates[1], g_DuelCoordinates[2] );
		SetPlayerInterior( playerid, 0 );
		SetPlayerVirtualWorld( playerid, 0 );

		// reset duel variables
		p_playerDueling{ playerid } 		= false;
		g_duelData[ playerid ][ E_PLAYER ] 	= INVALID_PLAYER_ID;
		return Y_HOOKS_BREAK_RETURN_1;
	}
	return 1;
}

hook OnPlayerEnterDynamicCP( playerid, checkpointid )
{
	if ( GetPlayerState( playerid ) == PLAYER_STATE_SPECTATING ) {
		return 1;
	}

	if ( checkpointid == g_DuelCheckpoint )
	{
		ShowPlayerDuelMenu( playerid );
		return 1;
	}
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[] )
{
	if ( ( dialogid == DIALOG_DUEL ) && response )
	{
		erase ( szBigString );

		switch ( listitem )
		{
			case 0: ShowPlayerDialog( playerid, DIALOG_DUEL_PLAYER, DIALOG_STYLE_INPUT, ""COL_WHITE"决斗设置 - 选择玩家", ""COL_WHITE"请输入你想要决斗的玩家姓名:\n\n"COL_GREY"注意:你可以输入部分姓名.", "选择", "返回");
			case 1: ShowPlayerDialog( playerid, DIALOG_DUEL_HEALTH, DIALOG_STYLE_INPUT, ""COL_WHITE"决斗设置 - 生命值", ""COL_WHITE"输入你将开始的生命值:\n\n"COL_GREY"注意:默认健康状况为 100.0.", "选择", "返回");
			case 2: ShowPlayerDialog( playerid, DIALOG_DUEL_ARMOUR, DIALOG_STYLE_INPUT, ""COL_WHITE"决斗设置 - 护甲", ""COL_WHITE"输入你将开始的护甲数量:\n\n"COL_GREY"注意:默认护甲是 100.0.", "选择", "返回");

			case 3:
			{
				new
					iWeapon = g_duelData [ playerid ] [ E_WEAPON ] [ 0 ];

				for ( new i = 0; i < sizeof( g_WeaponList ); i ++) {
					format( szBigString, sizeof( szBigString ), "%s%s%s\n", szBigString, iWeapon == g_WeaponList [ i ] ? ( COL_GREY ) : ( COL_WHITE ), ReturnWeaponName( g_WeaponList[ i ] ) );
				}

				ShowPlayerDialog( playerid, DIALOG_DUEL_WEAPON, DIALOG_STYLE_LIST, ""COL_WHITE"决斗设置 - 更改主要武器", szBigString, "选择", "返回");
			}

			case 4:
			{
				new
					iWeapon = g_duelData [ playerid ] [ E_WEAPON ] [ 1 ];

				for ( new i = 0; i < sizeof( g_WeaponList ); i ++ ) {
					format( szBigString, sizeof( szBigString ), "%s%s%s\n", szBigString, iWeapon == g_WeaponList [ i ] ? ( COL_GREY ) : ( COL_WHITE ), ReturnWeaponName( g_WeaponList [ i ]) );
				}

				ShowPlayerDialog( playerid, DIALOG_DUEL_WEAPON_TWO, DIALOG_STYLE_LIST, ""COL_WHITE"决斗设置 - 更改辅助武器", szBigString, "选择", "返回");
			}

			case 5:
			{
				new
					iLocationID = g_duelData [ playerid ][ E_LOCATION_ID ];

				for ( new i = 0; i < sizeof( g_duelLocationData ); i ++ ) {
					format( szBigString, sizeof( szBigString ), "%s%s%s\n", szBigString, iLocationID == i ? ( COL_GREY ) : ( COL_WHITE ), g_duelLocationData[ i ][ E_NAME ] );
				}

				ShowPlayerDialog(playerid, DIALOG_DUEL_LOCATION, DIALOG_STYLE_LIST, ""COL_WHITE"决斗设置 - 更改位置", szBigString, "选择", "返回");
			}

			case 6: ShowPlayerDialog(playerid, DIALOG_DUEL_WAGER, DIALOG_STYLE_INPUT, ""COL_WHITE"决斗设置 - 下注", ""COL_WHITE"请输入本次决斗的赌注:", "选择", "返回");

			case 7:
			{
				g_duelData[ playerid ][ E_CAC ] = !g_duelData[ playerid ][ E_CAC ];

				SendClientMessageFormatted( playerid, -1, ""COL_DUEL"[决斗]{FFFFFF} 你有 %s "COL_GREY"的 CAC 模式"COL_WHITE".", g_duelData[ playerid ][ E_CAC ] ? ( "启用" ) : ( "禁用" ) );
				ShowPlayerDuelMenu( playerid );
			}

			case 8:
			{
				new
					pID = g_duelData [ playerid ][ E_PLAYER ];

				if ( !IsPlayerConnected( pID ) )
				{
					SendError( playerid, "你还没有选择任何人来决斗!" );
					return ShowPlayerDuelMenu( playerid );
				}

				if ( g_duelData[ playerid ][ E_CAC ] && ( ! IsPlayerUsingSampAC( pID ) && ! IsPlayerUsingSampAC( playerid ) ) )
				{
					SendError( playerid, "你和你的对手必须使用CAC来决斗!" );
					return ShowPlayerDuelMenu( playerid );
				}

				p_duelInvitation[ playerid ][ pID ] = gettime( ) + 60;
				ShowPlayerHelpDialog( pID, 10000, "%s想要决斗!~n~~n~~y~地点:~w~%s~n~~y~武器:~w~%s和%s~n~~y~赌注:~w~%s~n~~y~CAC:~w~%s", ReturnPlayerName( playerid ), g_duelLocationData [ g_duelData[ playerid ][ E_LOCATION_ID ] ][ E_NAME ], ReturnWeaponName( g_duelData[ playerid ][ E_WEAPON ][ 0 ] ), ReturnWeaponName( g_duelData[ playerid ][ E_WEAPON ][ 1 ] ), cash_format(g_duelData[ playerid ][ E_BET ] ), g_duelData[ playerid ][ E_CAC ] ? ( "~g~是的" ) : ( "~r~没有" ) );
				
				SendClientMessageFormatted( playerid, -1, ""COL_DUEL"[决斗]"COL_WHITE" 你已向 %s 发送了决斗邀请 "COL_GOLD"%s"COL_WHITE".", ReturnPlayerName( pID ), cash_format( g_duelData[ playerid ][ E_BET ] ) );
				SendClientMessageFormatted( pID, -1, ""COL_DUEL"[决斗]"COL_WHITE" 邀请你决斗 %s "COL_GOLD"%s"COL_WHITE", 输入 \"/duel accept %d\".", ReturnPlayerName( playerid ), cash_format( g_duelData[ playerid ][ E_BET ] ), playerid );
			}
		}
		return 1;
	}

	else if ( dialogid == DIALOG_DUEL_PLAYER )
	{
		if ( !response )
			return ShowPlayerDuelMenu( playerid );

		new
			pID
		;

		if ( sscanf( inputtext, "u", pID) )
			return ShowPlayerDialog( playerid, DIALOG_DUEL_PLAYER, DIALOG_STYLE_INPUT, ""COL_WHITE"决斗设置 - 选择玩家", ""COL_WHITE"请输入你想要决斗的玩家姓名:\n\n"COL_GREY"注意:你可以输入部分姓名.", "选择", "返回" );

		if ( pID == playerid )
			return ShowPlayerDialog( playerid, DIALOG_DUEL_PLAYER, DIALOG_STYLE_INPUT, ""COL_WHITE"决斗设置 - 选择玩家", ""COL_WHITE"请输入你想要决斗的玩家姓名:\n\n"COL_RED"你不能邀请自己决斗!", "选择", "返回" );

		if ( pID == INVALID_PLAYER_ID || !IsPlayerConnected( pID ) )
			return ShowPlayerDialog( playerid, DIALOG_DUEL_PLAYER, DIALOG_STYLE_INPUT, ""COL_WHITE"决斗设置 - 选择玩家", ""COL_WHITE"请输入你想要决斗的玩家姓名:\n\n"COL_RED"该玩家不在线!", "选择", "返回" );

		if ( IsPlayerDueling( playerid ) )
			return ShowPlayerDialog( playerid, DIALOG_DUEL_PLAYER, DIALOG_STYLE_INPUT, ""COL_WHITE"决斗设置 - 选择玩家", ""COL_WHITE"请输入你想要决斗的玩家姓名:\n\n"COL_RED"你已经在决斗了!", "选择", "返回" );

		if ( IsPlayerDueling( pID ) )
			return ShowPlayerDialog( playerid, DIALOG_DUEL_PLAYER, DIALOG_STYLE_INPUT, ""COL_WHITE"决斗设置 - 选择玩家", ""COL_WHITE"请输入你想要决斗的玩家姓名:\n\n"COL_RED"该玩家已经在决斗中!", "选择", "返回" );

		if ( GetPlayerWantedLevel( pID ) )
			return ShowPlayerDialog( playerid, DIALOG_DUEL_PLAYER, DIALOG_STYLE_INPUT, ""COL_WHITE"决斗设置 - 选择玩家", ""COL_WHITE"请输入你想要决斗的玩家姓名:\n\n"COL_RED"你现在不能和这个人决斗,他们被通缉", "选择", "返回" );

		if ( GetDistanceBetweenPlayers( playerid, pID ) > 25.0 )
			return ShowPlayerDialog( playerid, DIALOG_DUEL_PLAYER, DIALOG_STYLE_INPUT, ""COL_WHITE"决斗设置 - 选择玩家", ""COL_WHITE"请输入你想要决斗的玩家姓名:\n\n"COL_RED"你想要决斗的玩家不在你附近.", "选择", "返回" );

		if ( IsPlayerJailed( pID ) )
			return ShowPlayerDialog( playerid, DIALOG_DUEL_PLAYER, DIALOG_STYLE_INPUT, ""COL_WHITE"决斗设置 - 选择玩家", ""COL_WHITE"请输入你想要决斗的玩家姓名:\n\n"COL_RED"你现在不能与这个人决斗,他们目前在监狱里.", "选择", "返回" );

		SendClientMessageFormatted( playerid, -1, ""COL_DUEL"[决斗]{FFFFFF} 你已选择 {C0C0C0}%s {FFFFFF} 作为对手.", ReturnPlayerName( pID ) );

		g_duelData[ playerid ][ E_PLAYER ] = pID;
		return ShowPlayerDuelMenu( playerid ), 1;
	}

	else if ( dialogid == DIALOG_DUEL_LOCATION )
	{
		if ( !response )
			return ShowPlayerDuelMenu( playerid );

		if ( g_duelData[ playerid ][ E_LOCATION_ID ] == listitem )
		{
			SendError( playerid, "你已经选择了这个位置!" );
			return ShowPlayerDuelMenu( playerid );
		}

		SendClientMessageFormatted( playerid, -1, ""COL_DUEL"[决斗]"COL_WHITE" 你已将决斗地点更改为 {C0C0C0}%s{FFFFFF}.", g_duelLocationData [ listitem ][ E_NAME ]);

		g_duelData[ playerid ][ E_LOCATION_ID ] = listitem;
		ShowPlayerDuelMenu( playerid );
		return 1;
	}

	else if ( dialogid == DIALOG_DUEL_WEAPON )
	{
		if ( !response )
			return ShowPlayerDuelMenu( playerid );

		if ( g_duelData[ playerid ][ E_WEAPON ][ 0 ] == g_WeaponList[ listitem ] )
		{
			SendError( playerid, "你已经选择了这个武器!");
			return ShowPlayerDuelMenu( playerid );
		}

		SendClientMessageFormatted( playerid, -1, ""COL_DUEL"[决斗]"COL_WHITE" 你已将主要武器更改为 {C0C0C0}%s{FFFFFF}.", ReturnWeaponName( g_WeaponList[ listitem ]) );
		g_duelData[ playerid ][ E_WEAPON ][ 0 ] = g_WeaponList[ listitem ];
		ShowPlayerDuelMenu( playerid );
		return 1;
	}

	else if ( dialogid == DIALOG_DUEL_WEAPON_TWO )
	{
		if ( !response )
			return ShowPlayerDuelMenu( playerid );

		if ( g_duelData[ playerid ][ E_WEAPON ][ 1 ] == g_WeaponList[ listitem ] )
		{
			SendError( playerid, "你已经选择了这个武器!");
			return ShowPlayerDuelMenu( playerid );
		}

		SendClientMessageFormatted( playerid, -1, ""COL_DUEL"[决斗]"COL_WHITE" 你已将次要武器更改为 {C0C0C0}%s{FFFFFF}.", ReturnWeaponName( g_WeaponList[ listitem ]) );
		g_duelData[ playerid ][ E_WEAPON ][ 1 ] = g_WeaponList[ listitem ];
		ShowPlayerDuelMenu( playerid );
		return 1;
	}

	else if ( dialogid == DIALOG_DUEL_HEALTH )
	{
		if ( !response )
			return ShowPlayerDuelMenu( playerid );

		new
			Float: fHealth;

		if ( sscanf( inputtext, "f", fHealth ) )
			return ShowPlayerDialog( playerid, DIALOG_DUEL_HEALTH, DIALOG_STYLE_INPUT, ""COL_WHITE"决斗设置 - 生命值", ""COL_WHITE"输入你将开始的生命值:\n\n"COL_GREY"注意:默认健康状况为 100.0.", "选择", "返回" );

		if ( !( 1.0 <= fHealth <= 100.0 ) )
			return ShowPlayerDialog( playerid, DIALOG_DUEL_HEALTH, DIALOG_STYLE_INPUT, ""COL_WHITE"决斗设置 - 生命值", ""COL_WHITE"输入你将开始的生命值:\n\n"COL_RED"你输入的金额无效,仅 1 到 100!", "选择", "返回" );

		SendClientMessageFormatted(playerid, -1, ""COL_DUEL"[决斗]"COL_WHITE" 你已将生命值更改为 {C0C0C0}%0.2f%%"COL_WHITE".", fHealth);
		g_duelData[ playerid ][ E_HEALTH ] = fHealth;
		ShowPlayerDuelMenu( playerid );
		return 1;
	}

	else if (dialogid == DIALOG_DUEL_ARMOUR)
	{
		if ( !response )
			return ShowPlayerDuelMenu( playerid );

		new
			Float: fArmour;

		if ( sscanf( inputtext, "f", fArmour ) )
			return ShowPlayerDialog( playerid, DIALOG_DUEL_ARMOUR, DIALOG_STYLE_INPUT, ""COL_WHITE"决斗设置 - 护甲", ""COL_WHITE"输入你将开始的护甲数量:\n\n"COL_GREY"注意:默认护甲是 100.0.", "选择", "返回" );

		if ( !( 0.0 <= fArmour <= 100.0 ) )
			return ShowPlayerDialog( playerid, DIALOG_DUEL_ARMOUR, DIALOG_STYLE_INPUT, ""COL_WHITE"决斗设置 - 护甲", ""COL_WHITE"输入你将开始的护甲数量:\n\n"COL_RED"你输入的金额无效,仅 0 到 100!", "选择", "返回" );

		SendClientMessageFormatted( playerid, -1, ""COL_DUEL"[决斗]"COL_WHITE" 你已将护甲更改为 {C0C0C0}%0.2f%%"COL_WHITE".", fArmour );
		g_duelData[ playerid ][ E_ARMOUR ] = fArmour;
		ShowPlayerDuelMenu( playerid );
		return 1;
	}

	else if (dialogid == DIALOG_DUEL_WAGER)
	{
		if ( IsPlayerDueling( playerid ) ) // prevent spawning money
			return SendError( playerid, "你目前无法使用此功能." );

		if ( !response )
			return ShowPlayerDuelMenu( playerid );

		new
			iBet
		;

		if ( sscanf( inputtext, "d", iBet ) )
			return ShowPlayerDialog( playerid, DIALOG_DUEL_WAGER, DIALOG_STYLE_INPUT, ""COL_WHITE"决斗设置 - 下注", ""COL_WHITE"请输入本次决斗的赌注:", "选择", "返回");

		if ( ! ( 0 <= iBet < 10000000 ) )
			return ShowPlayerDialog( playerid, DIALOG_DUEL_WAGER, DIALOG_STYLE_INPUT, ""COL_WHITE"决斗设置 - 下注", ""COL_WHITE"请输入本次决斗的赌注:\n\n"COL_RED"赌注必须在 $0 和 $10,000,000. 之间", "选择", "返回");

		g_duelData[playerid][ E_BET ] = iBet;
		SendClientMessageFormatted( playerid, -1, ""COL_DUEL"[决斗]"COL_WHITE" 你已将赌注更改为 %s.", cash_format(g_duelData[playerid][ E_BET ]));
		ShowPlayerDuelMenu( playerid );
		return 1;
	}
	return 1;
}

/* ** Commands ** */
CMD:duel( playerid, params[ ] )
{
	if ( !strcmp(params, "accept", false, 6))
	{
		new
			targetid;

		if ( sscanf( params[ 7 ], "u", targetid ) )
			return SendUsage( playerid, "/duel accept [PLAYER_ID]");

		if ( !IsPlayerConnected( targetid ) )
			return SendError( playerid, "你没有任何可以接受的决斗邀请.");

		if ( gettime( ) > p_duelInvitation[ targetid ][ playerid ] )
			return SendError( playerid, "%s 尚未邀请你决斗,或者邀请已过期.");

		if ( IsPlayerDueling( playerid ) )
			return SendError( playerid, "你无法接受此邀请,因为你目前正在决斗.");

		if ( GetDistanceBetweenPlayers( playerid, targetid ) > 25.0)
			return SendError( playerid, "你必须距离对手 25.0 米以内!");

		new
			waged_amount = g_duelData[ targetid ][ E_BET ];

		if ( g_duelData[ targetid ][ E_BET ] != 0 )
		{
			if ( GetPlayerCash( targetid ) < waged_amount )
			{
				SendClientMessageFormatted( targetid, -1, ""COL_DUEL"[决斗]"COL_WHITE" %s 已接受决斗邀请, 但你的钱不足以支付赌注 (%s).", ReturnPlayerName( playerid ), cash_format( waged_amount ) );
				SendClientMessageFormatted( playerid, -1, ""COL_DUEL"[决斗]"COL_WHITE" 你已经接受%s的决斗邀请,但他们没有钱.", ReturnPlayerName( targetid ) );
				return 1;
			}
			else if ( GetPlayerCash( playerid ) < waged_amount )
			{
				SendClientMessageFormatted( playerid, -1, ""COL_DUEL"[决斗]"COL_WHITE" 与 %s 决斗需要支付 %s 赌注.", ReturnPlayerName( targetid ), cash_format( waged_amount ) );
				SendClientMessageFormatted( targetid, -1, ""COL_DUEL"[决斗]"COL_WHITE" %s 已接受决斗邀请, 但其资金不足以支付赌注.", ReturnPlayerName( playerid ) );
				return 1;
			}
			else
			{
				GivePlayerCash( playerid, -waged_amount );
				GivePlayerCash( targetid, -waged_amount );
			}
		}

		SendClientMessageFormatted( targetid, -1, ""COL_DUEL"[决斗]"COL_WHITE" %s 已接受你的决斗邀请.", ReturnPlayerName( playerid ) );
		SendClientMessageFormatted( playerid, -1, ""COL_DUEL"[决斗]"COL_WHITE" 你已接受%s的决斗邀请.", ReturnPlayerName( targetid ) );

		p_playerDueling{ targetid } = true;
		p_playerDueling{ playerid } = true;

		g_duelData[ targetid ][ E_PLAYER ] = playerid;
		g_duelData[ playerid ][ E_PLAYER ] = targetid;
		g_duelData[ playerid ][ E_BET ] = g_duelData[targetid][ E_BET ];
		g_duelData[ playerid ][ E_ROUNDS ] = 1;
		g_duelData[ targetid ][ E_ROUNDS ] = 1;

		new
			iLocation = g_duelData[ targetid ][ E_LOCATION_ID ];

		ResetPlayerWeapons( targetid );
		RemovePlayerFromVehicle( targetid );
		SetPlayerArmour( targetid, g_duelData[ targetid ][ E_ARMOUR ]);
		SetPlayerHealth( targetid, g_duelData[ targetid ][ E_HEALTH ]);
		SetPlayerVirtualWorld( targetid, targetid + 1 );
		SetPlayerPos( targetid, g_duelLocationData[ iLocation ][ E_POS_TWO ][0], g_duelLocationData[ iLocation ][ E_POS_TWO ][1], g_duelLocationData[ iLocation ][ E_POS_TWO ][2] );

		ResetPlayerWeapons( playerid );
		RemovePlayerFromVehicle( playerid );
		SetPlayerArmour( playerid, g_duelData[ targetid ][ E_ARMOUR ]);
		SetPlayerHealth( playerid, g_duelData[ targetid ][ E_HEALTH ]);
		SetPlayerVirtualWorld( playerid, targetid + 1 );
		SetPlayerPos( playerid, g_duelLocationData[ iLocation ][ E_POS_ONE ][0], g_duelLocationData[ iLocation ][ E_POS_ONE ][1], g_duelLocationData[ iLocation ][ E_POS_ONE ][2] );

		// freeze
		TogglePlayerControllable( playerid, 0 );
		TogglePlayerControllable( targetid, 0 );

		// start countdown
		g_duelData[ targetid ][ E_COUNTDOWN ] = 10;
		g_duelData[ targetid ][ E_TIMER ] = SetTimerEx( "OnDuelTimer", 960, true, "d", targetid );

		// give weapon
		GivePlayerWeapon( playerid, g_duelData[ targetid ][ E_WEAPON ][0], 5000);
		GivePlayerWeapon( targetid, g_duelData[ targetid ][ E_WEAPON ][0], 5000);
		GivePlayerWeapon( playerid, g_duelData[ targetid ][ E_WEAPON ][1], 5000);
		GivePlayerWeapon( targetid, g_duelData[ targetid ][ E_WEAPON ][1], 5000);

		// clear invites for safety
		for (new i = 0; i < MAX_PLAYERS; i ++) {
			p_duelInvitation[ playerid ][ i ] = 0;
			p_duelInvitation[ targetid ][ i ] = 0;
		}
		return 1;
	}
	else if ( strmatch( params, "cancel" ) )
	{
		if ( ClearDuelInvites( playerid ) )
		{
			return SendServerMessage( playerid, "你已经取消了你提出的每一个决斗提议." );
		}
		else
		{
			return SendError( playerid, "你最近没有提出任何决斗要约." );
		}
	}
	return SendUsage( playerid, "/duel [ACCEPT/CANCEL]" );
}

/* ** Functions ** */
static stock ClearDuelInvites( playerid )
{
	new current_time = gettime( );
	new count = 0;

	for ( new i = 0; i < MAX_PLAYERS; i ++ )
	{
		if ( p_duelInvitation[ playerid ][ i ] != 0 && current_time > p_duelInvitation[ playerid ][ i ])
		{
			p_duelInvitation[ playerid ][ i ] = 0;
			count ++;
		}
	}
	return count;
}

stock IsPlayerDueling( playerid ) {
	return p_playerDueling{ playerid };
}

stock ShowPlayerDuelMenu( playerid )
{
	if ( p_Class[ playerid ] != CLASS_CIVILIAN )
		return SendError( playerid, "你只能以平民身份使用此功能.");

	if ( p_WantedLevel[ playerid ] > 0 )
		return SendError( playerid, "当你拥有 通缉等级 时,你不能决斗.");

	format( szBigString, sizeof(szBigString),
		"玩家\t"COL_GREY"%s\n健康\t"COL_GREY"%.2f%%\n装甲\t"COL_GREY"%.2f%%\n主要武器\t"COL_GREY"%s\n辅助武器\t"COL_GREY"%s\n地点\t"COL_GREY"%s\n赌注\t"COL_GREY"%s\n仅限 CAC\t"COL_GREY"%s\n"COL_GOLD"发送邀请\t"COL_GOLD">>>",
		( ! IsPlayerConnected( g_duelData[ playerid ][ E_PLAYER ] ) ? ( ""COL_RED"无人" ) : ( ReturnPlayerName( g_duelData[ playerid ][ E_PLAYER ] ) ) ),
		g_duelData[ playerid ][ E_HEALTH ],
		g_duelData[ playerid ][ E_ARMOUR ],
		ReturnWeaponName( g_duelData[ playerid ][ E_WEAPON ][ 0 ] ),
		ReturnWeaponName( g_duelData[ playerid ][ E_WEAPON ][ 1 ] ),
		g_duelLocationData[ g_duelData[ playerid ][ E_LOCATION_ID ] ][ E_NAME ],
		cash_format( g_duelData[ playerid ][ E_BET ] ),
		( g_duelData[ playerid ][ E_CAC ] ? ( ""COL_GREEN"已启用" ) : ( ""COL_RED"禁用" ) )
	);

	ShowPlayerDialog( playerid, DIALOG_DUEL, DIALOG_STYLE_TABLIST, ""COL_WHITE"决斗设定", szBigString, "选择", "取消" );
	return 1;
}

static stock forfeitPlayerDuel(playerid)
{
	if ( !IsPlayerDueling( playerid ) )
		return 0;

	ClearDuelInvites( playerid );

	new
		winnerid = g_duelData[ playerid ][ E_PLAYER ];

	if ( ! IsPlayerConnected( winnerid ) || ! IsPlayerDueling( winnerid ) )
		return 0;

	// begin wager info
	new
		amount_waged = g_duelData[ playerid ][ E_BET ];

	SpawnPlayer( winnerid );
	ClearDuelInvites( winnerid );

	// decrement rounds
	g_duelData[ playerid ][ E_ROUNDS ] --;
	g_duelData[ winnerid ][ E_ROUNDS ] = g_duelData[ playerid ][ E_ROUNDS ];

	// check if theres a remaining round
	if ( g_duelData[ playerid ][ E_ROUNDS ] == 0)
	{
		if ( 0 < amount_waged < 10000000 )
		{
			new
				winning_prize = floatround( float( amount_waged ) * 1.95 ); // We take 2.5% of the total pot

			GivePlayerCash( winnerid, winning_prize );
			SendClientMessageToAllFormatted( -1, ""COL_DUEL"[决斗]"COL_WHITE" %s(%d) 赢得了 %s(%d) 的 %s 决斗!", ReturnPlayerName( winnerid ), winnerid, ReturnPlayerName( playerid ), playerid, cash_format( winning_prize ) );
		}
		else
		{
			SendClientMessageToAllFormatted( -1, ""COL_DUEL"[决斗]"COL_WHITE" %s(%d) 赢得了对 %s(%d) 的决斗!", ReturnPlayerName( winnerid ), winnerid, ReturnPlayerName( playerid ), playerid );
		}
	}
	return 1;
}

function OnDuelTimer( targetid )
{
	new
		playerid = g_duelData[ targetid ][ E_PLAYER ];

	g_duelData[ targetid ][ E_COUNTDOWN ] --;

	if ( g_duelData[ targetid ][ E_COUNTDOWN ] <= 0)
	{
		GameTextForPlayer( targetid, "~g~~h~战斗!", 1500, 4 );
		GameTextForPlayer( playerid, "~g~~h~战斗!", 1500, 4 );

		PlayerPlaySound( targetid, 1057, 0.0, 0.0, 0.0 );
		PlayerPlaySound( playerid, 1057, 0.0, 0.0, 0.0 );

		TogglePlayerControllable( playerid, 1 );
		TogglePlayerControllable( targetid, 1 );

		KillTimer( g_duelData[ targetid ][ E_TIMER ] );
	}
	else
	{
		format( szSmallString, sizeof( szSmallString ), "~w~%d", g_duelData[ targetid ][ E_COUNTDOWN ] );
		GameTextForPlayer( targetid, szSmallString, 1500, 4 );
		GameTextForPlayer( playerid, szSmallString, 1500, 4 );

		PlayerPlaySound( targetid, 1056, 0.0, 0.0, 0.0 );
		PlayerPlaySound( playerid, 1056, 0.0, 0.0, 0.0 );
	}
	return 1;
}
