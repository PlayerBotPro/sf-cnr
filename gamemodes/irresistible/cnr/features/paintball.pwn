/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc, Stev
 * Module: cnr/features/paintball.pwn
 * Purpose: paintball related features
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_PAINTBALL_ARENAS 		( 6 )
#define MAX_RANDOM_SPAWNS 			( 6 )

/* ** Variables ** */
enum E_PAINTBALL_DATA
{
	E_NAME[ 16 ],		E_HOST, 				E_PASSWORD[ 5 ],
	E_LIMIT,			E_WEAPONS[ 3 ],			E_PLAYERS,
	E_ARENA, 			Float: E_ARMOUR, 		Float: E_HEALTH,
	bool: E_ACTIVE,		bool: E_PASSWORDED, 	bool: E_REFILLER,
	E_CD_TIMER,			bool: E_HEADSHOT, 		bool: E_CHAT,
	bool: E_RANDOM
};

enum E_PAINTBALL_ARENAS
{
	Float: E_X, 		Float: E_Y, 			Float: E_Z,
	E_INTERIOR, 		E_NAME[ 16 ]
};

enum E_PAINTBALL_SPAWNS
{
	E_ARENA_ID,			Float: E_X,			Float: E_Y,
	Float: E_Z,			E_INTERIOR
}

new
	g_paintballArenaData			[ ] [ E_PAINTBALL_ARENAS ] =
	{
		{ 1412.639892, -1.787510, 1000.924377, 1 , 	"仓库1" },
		{ 1302.519897, -1.787510, 1001.028259, 18, 	"仓库2" },
		{ 1063.650400, 2134.9487, 10.82030000, 0 , 	"仓库3" },
		{ -2659.28170, 1410.3884, 910.1703000, 3 , 	"吉兹的" },
		{ 296.8772000, 174.79120, 1007.171900, 3 ,	"左室PD" },
		//{ 1265.012900, -775.0262, 1091.906300, 5 ,	"Mad Doggs" },
		{ -1401.68950, 107.43800, 1032.273400, 1 , 	"体育场1" },
		{ 2193.399700, -1142.272, 1029.796900, 15, 	"杰斐逊汽车旅馆" },
		{ -949.294600, 1887.0156, 5.000000000, 17, 	"谢尔曼大坝" },
		{ 1721.863800, -1655.338, 20.96800000, 18,  "中庭" }
	},

	Float: g_paintballSpawns 				[ sizeof( g_paintballArenaData ) ] [ MAX_RANDOM_SPAWNS ] [ 3 ] =
	{
		// warehouse 1
		{
			{ 1412.6399, -1.7875, 1000.9244 }, 	{ 1367.4644, -1.3951, 1000.9219 }, 	{ 1402.3909, -23.1311, 1000.9103 },
			{ 1384.0382, -22.2924, 1000.9230 }, { 1415.2482, -40.9799, 1000.9257 }, { 1366.4021, -44.1363, 1000.9192 }
		},

		// warehouse 2
		{
			{ 1302.5199, -1.7875, 1001.0283 }, 	{ 1278.9091, -12.1906, 1001.0156 }, { 1252.9880, -58.8240, 1002.4990 },
			{ 1294.0881, -64.9856, 1002.4960 }, { 1303.2255, -44.0086, 1001.0367 }, { 1251.5754, 2.1243, 1001.0344 }
		},

		// warehouse 3
		{
			{ 1063.6504, 2134.9487, 10.8203 },	{ 1089.6921, 2117.0010, 10.8203 },	{ 1089.5262, 2081.0449, 10.8203 },
			{ 1089.7534, 2077.9897, 15.3504 },	{ 1092.3716, 2119.8259, 15.3504 },	{ 1069.9283, 2103.4949, 10.8203 }
		},

		// Jizzy's
		{
			{ -2659.2817, 1410.3884, 910.1703 }, { -2688.3000, 1430.0179, 906.4609 }, { -2652.9834, 1427.8518, 912.4114 },
			{ -2636.7776, 1406.3575, 906.4609 }, { -2633.1707, 1392.9563, 906.4609 }, { -2649.0347, 1391.7921, 918.3582 }
		},

		// LV-PD
		{
			{ 296.8772, 174.7912, 1007.1719 }, { 297.3651, 191.2529, 1007.1719 }, { 246.5930, 185.2390, 1008.1719 },
			{ 231.5877, 171.6264, 1003.0234 }, { 202.1714, 167.9985, 1003.0234 }, { 239.5641, 141.4648, 1003.0234 }
		},
		
		// Stadium 1
		{
			{ -1401.6895, 107.4380, 1032.2734 }, { -1403.2545, 126.9025, 1030.4382 }, { -1419.7942, 127.4668, 1030.7443 },
			{ -1420.6074, 94.6617, 1031.5850 }, { -1403.0911, 87.1951, 1031.0742 }, { -1383.1639, 94.1880, 1030.7531 }
		},
		
		// Jefferson Motel
		{
			{ 2193.3997,- 1142.2720, 1029.7969 }, { 2189.8071,- 1146.4943, 1033.7969 }, { 2186.7761,- 1156.9148, 1029.7969 },
			{ 2187.3259,- 1180.2784, 1029.7969 }, { 2192.7627,- 1181.1935, 1033.7896 }, { 2236.1255,- 1192.7971, 1029.8043 }
		},
		
		// Sherman Dam
		{
			{ -949.2946, 1887.0156, 5.0000 }, { -961.5467, 1867.0323, 9.0000 }, { -951.4822, 1847.6415, 5.0000 },
			{ -956.1313, 1910.7572, 5.0000 }, { -955.7346, 1930.8940, 5.0000 }, { -942.3181, 1951.5886, 5.0000 }
		},
		
		// Atrium
		{
			{ 1721.8638, -1655.3380, 20.9688 }, { 1733.5320, -1640.5344, 20.2306 }, { 1702.6398, -1667.7361, 20.2188 },
			{ 1727.9952, -1640.1686, 23.7289 }, { 1729.5344, -1669.1146, 22.6151 }, { 1709.9868, -1643.1584, 20.2188 }
		}
	},

	g_paintballData       			[ MAX_PAINTBALL_ARENAS ] [ E_PAINTBALL_DATA ],

	bool: p_LeftPaintball           [ MAX_PLAYERS char ],
 	p_PaintBallArena				[ MAX_PLAYERS char ],

	// Iterator
	Iterator:paintball<MAX_PAINTBALL_ARENAS>
;

/* ** Hooks ** */
#if defined AC_INCLUDED
hook OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
hook OnPlayerDeath( playerid, killerid, reason )
#endif
{
	if ( ! ( 0 <= killerid < MAX_PLAYERS ) ) // ignore invalid id / npc killers
		return 1;

	if ( p_inPaintBall{ killerid } == true )
	{
		new
			a = p_PaintBallArena{ killerid };

		if ( g_paintballData[ a ] [ E_REFILLER ] )
		{
			SetPlayerHealth( killerid, g_paintballData[ a ] [ E_HEALTH ] );
			SetPlayerArmour( killerid, g_paintballData[ a ] [ E_ARMOUR ] );
		}

		SendDeathMessage( killerid, playerid, reason );
		return Y_HOOKS_BREAK_RETURN_1;
	}
	return 1;
}

hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if ( ( dialogid == DIALOG_PAINTBALL ) && response )
	{
		for( new id, x = 0; id < MAX_PAINTBALL_ARENAS; id ++ )
		{
	       	if ( x == listitem )
	      	{
				if ( Iter_Contains(paintball, id) )
				{
					if ( !g_paintballData[ id ] [ E_ACTIVE ] )
					{
						SendError( playerid, "此 彩弹竞技 房间 当前未激活且正在编辑." );
						listPaintBallLobbies( playerid );
						return 1;
					}

		      		if ( g_paintballData[ id ] [ E_PASSWORDED ] && !isnull( g_paintballData[ id ] [ E_PASSWORD ] ) && !strmatch( g_paintballData[ id ] [ E_PASSWORD ], "NULL" ) )
		      		{
					 	if ( g_Debugging ) {
					 		SendClientMessageToRCON( COLOR_YELLOW, "PAINTBALL: host %s, passworded %d, password %s", ReturnPlayerName( g_paintballData[ id ] [ E_HOST ] ), g_paintballData[ id ] [ E_PASSWORDED ], g_paintballData[ id ] [ E_PASSWORD ] );
					 	}
						p_PaintBallArena{ playerid } = id;
                        SendServerMessage( playerid, "你正在尝试加入 彩弹竞技 房间: "COL_GREY"%s", g_paintballData[ id ] [ E_NAME ] );
                        ShowPlayerDialog( playerid, DIALOG_PAINTBALL_PW, DIALOG_STYLE_INPUT, "{FFFFFF}彩弹竞技 - 加入", "{FFFFFF}此 房间 需要密码.", "加入", "返回" );
		      			return 1;
		      		}
		      		JoinPlayerPaintball( playerid, id );
				}
				else
				{
			    	if ( hasPaintBallArena( playerid ) )
                        return SendError( playerid, "你已经拥有一套 彩弹竞技 竞技场.你已经被催生了" ), SpawnPlayer( playerid );

				  	if ( GetPlayerCash( playerid ) < 5000 )
                        return listPaintBallLobbies( playerid ), SendError( playerid, "你的资金不足. ($5,000)" ), 1;

                    if ( !CreatePaintballLobby( id, playerid, "彩弹竞技", 8, 0 ) )
                        return SendError( playerid, "由于错误,无法创建 房间.也许有人占据了这个位置?" );

			    	GivePlayerCash( playerid, -5000 );
			    	showPaintBallLobbyData( playerid, id );
			    	p_PaintBallArena{ playerid } = id;
				}
				break;
	   		}
	      	x ++;
		}
	}
	if ( dialogid == DIALOG_PAINTBALL_PW )
	{
		if ( response )
		{
			new
				szPassword[ 5 ];

			strreplacechar( inputtext, '\\', '/' );
			if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "由于你入狱,此功能不再可用." );
            if ( !Iter_Contains( paintball, p_PaintBallArena{ playerid } ) ) return SendError( playerid, "这个 房间 不再存在." );
            if ( sscanf( inputtext, "s[5]", szPassword ) ) return ShowPlayerDialog( playerid, DIALOG_PAINTBALL_PW, DIALOG_STYLE_INPUT, "{FFFFFF}彩弹竞技 - 加入", "{FFFFFF}此 房间 需要密码.\n\n"COL_RED"密码不正确,请重试.", "加入", "返回" );
			if ( g_paintballData[ p_PaintBallArena{ playerid } ] [ E_PASSWORDED ] ) {
				if ( !strmatch( szPassword, g_paintballData[ p_PaintBallArena{ playerid } ] [ E_PASSWORD ] ) ) return ShowPlayerDialog( playerid, DIALOG_PAINTBALL_PW, DIALOG_STYLE_INPUT, "{FFFFFF}彩弹竞技 - 加入", "{FFFFFF}此 房间 需要密码.\n\n"COL_RED"密码不正确,请重试.", "加入", "返回" );
			}
			else SendServerMessage( playerid, "看来你尝试加入的 房间 不再有密码." );
			JoinPlayerPaintball( playerid, p_PaintBallArena{ playerid } );
		}
		else listPaintBallLobbies( playerid );
	}
	if ( dialogid == DIALOG_PAINTBALL_EDIT )
	{
		if ( response )
		{
			new
				iLobby = p_PaintBallArena{ playerid };

			SetPVarInt( playerid, "paintball_edititem", listitem );

			switch( listitem )
			{
				case 0 .. 4: 	ShowPlayerDialog( playerid, DIALOG_PAINTBALL_EDIT_VAL, DIALOG_STYLE_INPUT, "{FFFFFF}彩弹竞技 - 编辑", "{FFFFFF}你想将此值设置为多少?", "应用", "返回" );
				case 5:
				{
					g_paintballData[ iLobby ] [ E_REFILLER ] = !g_paintballData[ iLobby ] [ E_REFILLER ];
					SendClientMessageToPaintball( iLobby, -1, ""COL_GREY"[彩弹竞技]"COL_WHITE" 死亡后将%s恢复护甲和生命值.", g_paintballData[ iLobby ] [ E_REFILLER ] == false ? ( "不" ) : ( "" ) );
					showPaintBallLobbyData( playerid, iLobby );
				}
				case 6: 		ShowPlayerPaintballArenas( playerid );
				case 7 .. 9: 	ShowPlayerDialog( playerid, DIALOG_PAINTBALL_WEP, DIALOG_STYLE_LIST, "{FFFFFF}彩弹竞技 - 编辑", ""COL_RED"移除此槽上的武器\n9毫米手枪\n消音手枪\n沙漠之鹰\n霰弹枪\n锯短霰弹枪\nSpas 12\nMac 10\nMP5\nAK-47\nM4\nTec 9\n步枪\n狙击手", "选择", "取消");
				case 10:
				{
					g_paintballData[ iLobby ] [ E_HEADSHOT ] = !g_paintballData[ iLobby ] [ E_HEADSHOT ];
					SendClientMessageToPaintball( iLobby, -1, ""COL_GREY"[彩弹竞技]"COL_WHITE" 爆头模式已 %s.", g_paintballData[ iLobby ] [ E_HEADSHOT ] == false ? ( "未切换" ) : ( "切换的" ) );
					showPaintBallLobbyData( playerid, iLobby );
				}
				case 11:
				{
					g_paintballData[ iLobby ] [ E_CHAT ] = !g_paintballData[ iLobby ] [ E_CHAT ];
					SendClientMessageToPaintball( iLobby, -1, ""COL_GREY"[彩弹竞技]"COL_WHITE" 死亡后将%s恢复护甲和生命值.", g_paintballData[ iLobby ] [ E_CHAT ] == false ? ( "不" ) : ( "" ) );
					showPaintBallLobbyData( playerid, iLobby );
				}
				case 12:
				{
					g_paintballData[ iLobby ] [ E_RANDOM ] = !g_paintballData[ iLobby ] [ E_RANDOM ];
					SendClientMessageToPaintball( iLobby, -1, ""COL_GREY"[彩弹竞技]"COL_WHITE" 随机生成已 %s.", g_paintballData[ iLobby ] [ E_RANDOM ] == false ? ( "未切换" ) : ( "切换的" ) );
					showPaintBallLobbyData( playerid, iLobby );
				}
			}
		}
		else
		{
			new
				i = p_PaintBallArena{ playerid };

			if ( !g_paintballData[ i ] [ E_ACTIVE ] )
			{
				g_paintballData[ i ] [ E_ACTIVE ] = true;
			  	JoinPlayerPaintball( playerid, i );
                SendServerMessage( playerid, "你可以编辑你的 房间 "COL_GREY"/paintball edit"COL_WHITE"." );
			}
		}
	}
	if ( dialogid == DIALOG_PAINTBALL_EDIT_VAL )
	{
		new
			iLobby = p_PaintBallArena{ playerid };

		if ( response )
		{
			switch( GetPVarInt( playerid, "paintball_edititem" ) )
			{
				case 0: // name
				{
					new
						szName[ 16 ];

					if ( sscanf( inputtext, "s[16]", szName ) )
                        return ShowPlayerDialog( playerid, DIALOG_PAINTBALL_EDIT_VAL, DIALOG_STYLE_INPUT, "{FFFFFF}彩弹竞技 - 编辑", "{FFFFFF}你想将其值设置为多少?\n\n"COL_RED"房间 名称无效.", "应用", "返回" );

					if ( strlen( inputtext ) < 3 || strlen( inputtext ) >= 16 )
                        return ShowPlayerDialog( playerid, DIALOG_PAINTBALL_EDIT_VAL, DIALOG_STYLE_INPUT, "{FFFFFF}彩弹竞技 - 编辑", "{FFFFFF}你想将其值设置为多少?\n\n"COL_RED"房间 名称必须介于 3 和 16 个字符之间.", "应用", "返回" );

					format( g_paintballData[ iLobby ] [ E_NAME ], 16, "%s", szName );
					SendClientMessageToPaintball( iLobby, -1, ""COL_GREY"[彩弹竞技]"COL_WHITE" 房间 姓名已由 %s(%d) 更新", ReturnPlayerName( playerid ), playerid );
				}
				case 1: // pw
				{
					new
						szPassword[ 5 ];

					if ( sscanf( inputtext, "s[5]", szPassword ) ) return ShowPlayerDialog( playerid, DIALOG_PAINTBALL_EDIT_VAL, DIALOG_STYLE_INPUT, "{FFFFFF}彩弹竞技 - 编辑", "{FFFFFF}你想将其值设置为多少?\n\n"COL_RED"密码最多只能有 4 个字符.设置为 NULL 以禁用.", "应用", "返回" );
					if ( !strlen( szPassword ) || strlen( szPassword ) >= 5 ) return ShowPlayerDialog( playerid, DIALOG_PAINTBALL_EDIT_VAL, DIALOG_STYLE_INPUT, "{FFFFFF}彩弹竞技 - 编辑", "{FFFFFF}你想将其值设置为多少?\n\n"COL_RED"密码最多只能有 4 个字符.设置为 NULL 以禁用.", "应用", "返回" );

					if ( strmatch( szPassword, "NULL" ) )
					{
						SendClientMessageToPaintball( iLobby, -1, ""COL_GREY"[彩弹竞技]"COL_WHITE" 房间 密码已被 %s 禁用.", " " );
						g_paintballData[ iLobby ] [ E_PASSWORDED ] = false;
					}
					else
					{
						SendClientMessageToPaintball( iLobby, -1, ""COL_GREY"[彩弹竞技]"COL_WHITE" 房间 密码已更改为: "COL_GREY"%s"COL_WHITE".", szPassword );
						g_paintballData[ iLobby ] [ E_PASSWORDED ] = true;
					}
					format( g_paintballData[ iLobby ] [ E_PASSWORD ], 5, "%s", szPassword );
				}
				case 2: // limit
				{
					new iLimit;

					if ( sscanf( inputtext, "d", iLimit ) )
                        return ShowPlayerDialog( playerid, DIALOG_PAINTBALL_EDIT_VAL, DIALOG_STYLE_INPUT, "{FFFFFF}彩弹竞技 - 编辑", "{FFFFFF}你想将其值设置为多少?\n\n"COL_RED"确保玩家容量是整数.", "应用", "返回" );

					if ( iLimit < 2 || iLimit > 32 )
                        return ShowPlayerDialog( playerid, DIALOG_PAINTBALL_EDIT_VAL, DIALOG_STYLE_INPUT, "{FFFFFF}彩弹竞技 - 编辑", "{FFFFFF}你想将其值设置为多少?\n\n"COL_RED"请在 2 和 32 玩家之间指定.", "应用", "返回" );

					if ( iLimit < g_paintballData[ iLobby ] [ E_PLAYERS ] )
						return ShowPlayerDialog( playerid, DIALOG_PAINTBALL_EDIT_VAL, DIALOG_STYLE_INPUT, "{FFFFFF}彩弹竞技 - 编辑", "{FFFFFF}你想将其值设置为多少?\n\n"COL_RED"你的限制不能少于已经加入的玩家数量.", "应用", "返回" );

				 	g_paintballData[ iLobby ] [ E_LIMIT ] = iLimit;
					SendClientMessageToPaintball( iLobby, -1, ""COL_GREY"[彩弹竞技]"COL_WHITE" 房间 玩家限制已设置为 %d.", g_paintballData[ iLobby ] [ E_LIMIT ] );
				}
				case 3: // health
				{
					new Float: fHealth;

					if ( sscanf( inputtext, "f", fHealth ) )
                        return ShowPlayerDialog( playerid, DIALOG_PAINTBALL_EDIT_VAL, DIALOG_STYLE_INPUT, "{FFFFFF}彩弹竞技 - 编辑", "{FFFFFF}你想将其值设置为多少?\n\n"COL_RED"确保玩家容量是数字.", "应用", "返回" );

					if ( fHealth < 1 || fHealth > 150 )
                        return ShowPlayerDialog( playerid, DIALOG_PAINTBALL_EDIT_VAL, DIALOG_STYLE_INPUT, "{FFFFFF}彩弹竞技 - 编辑", "{FFFFFF}你想将其值设置为多少?\n\n"COL_RED"请指定 1 和 150 之间的健康状况.", "应用", "返回" );

				 	g_paintballData[ iLobby ] [ E_HEALTH ] = fHealth;
					SendClientMessageToPaintball( iLobby, -1, ""COL_GREY"[彩弹竞技]"COL_WHITE" 房间 生成健康状况已设置为 %0.2f.", g_paintballData[ iLobby ] [ E_HEALTH ] );

					respawnAllInPaintballLobby( iLobby );
				}
				case 4: // armour
				{
					new Float: fArmour;

					if ( sscanf( inputtext, "f", fArmour ) )
                        return ShowPlayerDialog( playerid, DIALOG_PAINTBALL_EDIT_VAL, DIALOG_STYLE_INPUT, "{FFFFFF}彩弹竞技 - 编辑", "{FFFFFF}你想将其值设置为多少?\n\n"COL_RED"确保玩家容量是数字.", "应用", "返回" );

					if ( fArmour < 0 || fArmour > 150 )
                        return ShowPlayerDialog( playerid, DIALOG_PAINTBALL_EDIT_VAL, DIALOG_STYLE_INPUT, "{FFFFFF}彩弹竞技 - 编辑", "{FFFFFF}你想将其值设置为多少?\n\n"COL_RED"请在 0 和 150 装甲之间指定.", "应用", "返回" );

				 	g_paintballData[ iLobby ] [ E_ARMOUR ] = fArmour;
					SendClientMessageToPaintball( iLobby, -1, ""COL_GREY"[彩弹竞技]"COL_WHITE" 房间 生成装甲已设置为 %0.2f.", g_paintballData[ iLobby ] [ E_ARMOUR ] );

					respawnAllInPaintballLobby( iLobby );
				}
			}
			showPaintBallLobbyData( playerid, iLobby );
		}
		else showPaintBallLobbyData( playerid, iLobby );
	}
	if ( dialogid == DIALOG_PAINTBALL_ARENAS )
	{
		new
			iLobby = p_PaintBallArena{ playerid };

		if ( response )
		{
			g_paintballData[ iLobby ] [ E_ARENA ] = listitem;
			SendClientMessageToPaintball( iLobby, -1, ""COL_GREY"[彩弹竞技]"COL_WHITE" 房间 竞技场已设置为 %s.", g_paintballArenaData[ listitem ] [ E_NAME ] );
			respawnAllInPaintballLobby( iLobby );
			showPaintBallLobbyData( playerid, iLobby );
		}
		else showPaintBallLobbyData( playerid, iLobby );
	}
	if ( dialogid == DIALOG_PAINTBALL_WEP )
	{
		new
			iLobby = p_PaintBallArena{ playerid };

		if ( response )
		{
			if ( !listitem )
				g_paintballData[ iLobby ] [ E_WEAPONS ] [ GetPVarInt( playerid, "paintball_edititem" ) - 7 ] = 0;
			else
				g_paintballData[ iLobby ] [ E_WEAPONS ] [ GetPVarInt( playerid, "paintball_edititem" ) - 7 ] = 21 + listitem;

			SendClientMessageToPaintball( iLobby, -1, ""COL_GREY"[彩弹竞技]"COL_WHITE" 房间 武器组已%s 更新.", " " );
			respawnAllInPaintballLobby( iLobby );
			showPaintBallLobbyData( playerid, iLobby );
		}
		else showPaintBallLobbyData( playerid, iLobby );
	}
	return 1;
}

/* ** Commands ** */
CMD:pb( playerid, params[ ] ) return cmd_paintball( playerid, params );
CMD:paintball( playerid, params[ ] )
{
	if ( !IsPlayerInPaintBall( playerid ) )
		return SendError( playerid, "你不属于任何彩弹竞技 房间." );

	if ( strmatch( params, "leave" ) )
	{
		if ( !IsPlayerInPaintBall( playerid ) )
		    return SendError( playerid, "你不在 彩弹竞技 内." );

		LeavePlayerPaintball( playerid );
	    SetPlayerHealth( playerid, -1 );
	    SendServerMessage( playerid, "你已经离开彩弹竞技竞技场." );
	    return 1;
	}

	if ( !hasPaintBallArena( playerid ) )
		return SendError( playerid, "此命令要求你成为 房间 的主机." );

	new
		id = p_PaintBallArena{ playerid },
		pID
	;

	if ( strmatch( params, "edit" ) )
	{
		showPaintBallLobbyData( playerid, id, "关闭" );
	}
	else if ( !strcmp( params, "kick", false, 4 ) )
	{
		if ( sscanf( params[ 5 ], "u", pID ) ) return SendUsage( playerid, "/paintball kick [PLAYER_ID]" );
		else if ( !IsPlayerConnected( pID ) ) return SendError( playerid, "此玩家不在线." );
		else if ( !IsPlayerInPaintBall( pID ) ) return SendError( playerid, "该玩家不在 彩弹竞技." );
		else if ( p_PaintBallArena{ pID } != id ) return SendError( playerid, "该玩家不在你的 彩弹竞技 房间 中." );
		else if ( pID == playerid ) return SendError( playerid, "你不能踢自己." );
		else
		{
			SendClientMessageToPaintball( id, -1, ""COL_GREY"[彩弹竞技]"COL_WHITE" %s(%d) 已离开 房间(被踢)", ReturnPlayerName( pID ), pID );
			LeavePlayerPaintball( pID );
			SetPlayerHealth( pID, -1 );
		}
	}
	else if ( !strcmp( params, "leader", false, 6 ) )
	{
		if ( sscanf( params[ 7 ], "u", pID ) ) return SendUsage( playerid, "/paintball paintball [PLAYER_ID]" );
		else if ( !IsPlayerConnected( pID ) ) return SendError( playerid, "此玩家不在线." );
		else if ( !IsPlayerInPaintBall( pID ) ) return SendError( playerid, "该玩家不在 彩弹竞技." );
		else if ( p_PaintBallArena{ pID } != id ) return SendError( playerid, "该玩家不在你的 彩弹竞技 房间 中." );
		else if ( pID == playerid ) return SendError( playerid, "你不能将此操作应用于你自己." );
		else
		{
			g_paintballData[ id ] [ E_HOST ] = pID;
			SendClientMessageToPaintball( id, -1, ""COL_GREY"[彩弹竞技]"COL_WHITE" %s(%d) 是新的 彩弹竞技 领导者.", ReturnPlayerName( pID ), pID );
		}
	}
	else if ( !strcmp( params, "countdown", false, 6 ) )
	{
		new
			iSeconds;

		if ( sscanf( params[ 10 ], "D(10)", iSeconds ) ) return SendUsage( playerid, "/paintball countdown [SECONDS]" );
		else if ( iSeconds < 1 || iSeconds > 30 ) return SendError( playerid, "请指定 1 和 30. 之间的倒计时秒数" );
		else
		{
			SendServerMessage( playerid, "你已开始倒计时%d在你的彩弹竞技游戏.", iSeconds );

		 	KillTimer( g_paintballData[ id ] [ E_CD_TIMER ] );
			g_paintballData[ id ] [ E_CD_TIMER ] = SetTimerEx( "paintballCountDown", 960, false, "dd", id, iSeconds - 1 );
		}
	}
	else
	{
		SendUsage( playerid, "/paintball [LEAVE/EDIT/KICK/COUNTDOWN/LEADER]" );
	}
	return 1;
}

CMD:p( playerid, params[ ] )
{
	if ( !IsPlayerInPaintBall( playerid ) )
		return SendError( playerid, "你不属于任何彩弹竞技 房间." );

	new
	    id = p_PaintBallArena{ playerid },
	    msg[ 90 ]
	;

	if ( sscanf( params, "s[90]", msg ) ) return SendUsage( playerid, "/p [MESSAGE]" );
	else if ( textContainsIP( msg ) ) return SendServerMessage( playerid, "请不要做广告." );
    else if ( !g_paintballData[ id ] [ E_CHAT ] ) return SendError( playerid, "彩弹竞技 聊天在此 房间 中被禁用." );
    else
	{
		SendClientMessageToPaintball( id, -1, ""COL_GREY"<彩弹竞技 聊天> %s(%d):"COL_WHITE" %s", ReturnPlayerName( playerid ), playerid, msg );

		foreach ( new i : Player ) if ( ( p_AdminLevel[ i ] >= 5 || IsPlayerUnderCover( i ) ) && p_TogglePBChat{ i } == true )  {
			SendClientMessageFormatted( i, -1, ""COL_GREY"<彩弹竞技 聊天 房间 %d > %s(%d):"COL_WHITE" %s", id, ReturnPlayerName( playerid ), playerid, msg );
		}
	}
	return 1;
}

CMD:pleave( playerid, params[ ] ) return cmd_pb( playerid, "leave" );

/* ** Functions ** */
function paintballCountDown( paintballid, time )
{
	if ( paintballid == -1 )
		return;

	if ( !time )
	{
	    foreach(new playerid : Player)
	    {
	    	if ( IsPlayerInPaintBall( playerid ) && p_PaintBallArena{ playerid } == paintballid )
	    	{
                GameTextForPlayer( playerid, "~g~去!", 2000, 3 );
				PlayerPlaySound( playerid, 1057, 0.0, 0.0, 0.0 );
			}
		}
		g_paintballData[ paintballid ] [ E_CD_TIMER ] = 0xFFFF;
	}
	else
	{
	    foreach(new playerid : Player)
	    {
	    	if ( IsPlayerInPaintBall( playerid ) && p_PaintBallArena{ playerid } == paintballid )
	    	{
	    		GameTextForPlayer( playerid, sprintf( "~y~%d", time ), 2000, 3 );
	    		PlayerPlaySound( playerid, 1056, 0.0, 0.0, 0.0 );
	    	}
	    }
		g_paintballData[ paintballid ] [ E_CD_TIMER ] = SetTimerEx( "paintballCountDown", 960, false, "dd", paintballid, time - 1 );
	}
}

stock CreatePaintballLobby( pid, playerid, const szLobbyName[ 16 ], iPlayerCap, iArena, Float: fHealth = 100.0, Float: fArmour = 100.0 )
{
	if ( !Iter_Contains(paintball, pid) )
	{
		format( g_paintballData[ pid ] [ E_NAME ], 16, "%s", szLobbyName );
		g_paintballData[ pid ] [ E_PASSWORD ] [ 0 ] = '\0';
		g_paintballData[ pid ] [ E_PASSWORDED ]		= false;
		g_paintballData[ pid ] [ E_HOST ] 			= playerid;
		g_paintballData[ pid ] [ E_PLAYERS ] 		= 0;
		g_paintballData[ pid ] [ E_LIMIT ] 			= iPlayerCap;
		g_paintballData[ pid ] [ E_WEAPONS ] [ 0 ] 	= 0;
		g_paintballData[ pid ] [ E_WEAPONS ] [ 1 ] 	= 0;
		g_paintballData[ pid ] [ E_WEAPONS ] [ 2 ] 	= 0;
		g_paintballData[ pid ] [ E_ARMOUR ] 		= fHealth;
		g_paintballData[ pid ] [ E_HEALTH ] 		= fArmour;
		g_paintballData[ pid ] [ E_ARENA ] 			= iArena;
		g_paintballData[ pid ] [ E_ACTIVE ] 		= false;
		g_paintballData[ pid ] [ E_REFILLER ] 		= false;
		g_paintballData[ pid ] [ E_CD_TIMER ] 		= 0xFFFF;
		Iter_Add(paintball, pid);
		return true;
	}
	return false;
}

stock DestroyPaintballArena( p )
{
	if ( !Iter_Contains(paintball, p) )
		return false;

	Iter_Remove(paintball, p);
	g_paintballData[ p ] [ E_HOST ] = INVALID_PLAYER_ID;
	g_paintballData[ p ] [ E_PLAYERS ] = 0;
	g_paintballData[ p ] [ E_ACTIVE ] = false;
	g_paintballData[ p ] [ E_CD_TIMER ] = 0xFFFF;
	return true;
}

stock listPaintBallLobbies( playerid )
{
	if ( p_WantedLevel[ playerid ] ) return SendError( playerid, "你一定不会被邀请加入 彩弹竞技 竞技场." );
	if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "你必须是平民才能加入 彩弹竞技 竞技场." );

	new
		szLobbies[ 64 * MAX_PAINTBALL_ARENAS + 64 ];

	for( new p = 0; p < MAX_PAINTBALL_ARENAS; p++ )
	{
		if ( !g_paintballData[ p ] [ E_ACTIVE ] && !Iter_Contains(paintball, p) ) {
			format( szLobbies, sizeof( szLobbies ), "%s{334D5C}空 彩弹竞技 插槽 ($5,000)\n", szLobbies );
		}
		else if ( Iter_Contains(paintball, p) ) {
			format( szLobbies, sizeof( szLobbies ), "%s%s%s[%02d/%02d] %s 由 %s\n 主办",
				szLobbies, g_paintballData[ p ] [ E_PASSWORDED ] ? ( "{DF4949}" ) : ( "{53B240}" ), g_paintballData[ p ] [ E_ACTIVE ] ? ( "" ) : ( "{EFC94C}" ), g_paintballData[ p ] [ E_PLAYERS ], g_paintballData[ p ] [ E_LIMIT ], g_paintballData[ p ] [ E_NAME ], ReturnPlayerName( g_paintballData[ p ] [ E_HOST ] )
			);
		}
	}
    return ShowPlayerDialog( playerid, DIALOG_PAINTBALL, DIALOG_STYLE_LIST, "{FFFFFF}彩弹竞技 - 选择", szLobbies, "选择", "取消" );
}

stock showPaintBallLobbyData( playerid, id, second_button[ ] = "加入游戏" )
{
	format( szLargeString, sizeof( szLargeString ), "房间名称\t"COL_GREY"%s"COL_WHITE"\n房间密码\t%s"COL_WHITE"\n玩家容量\t"COL_GREY"%d"COL_WHITE"\n健康\t"COL_GREY"%0.2f%%"COL_WHITE"\n盔甲\t"COL_GREY"%0.2f%%"COL_WHITE"\n恢复生命值及护甲\t%s"COL_WHITE"\n竞技场\t"COL_GREY"%s"COL_WHITE"\n主要武器\t"COL_GREY"%s"COL_WHITE"\n辅助武器\t"COL_GREY"%s"COL_WHITE"\n第三武器\t"COL_GREY"%s"COL_WHITE"\n爆头模式\t"COL_GREY"%s"COL_WHITE"\n聊天\t"COL_GREY"%s\n随机生成\t"COL_GREY"%s",
		g_paintballData[ id ] [ E_NAME ],
		g_paintballData[ id ] [ E_PASSWORDED ] == true ? ( ""COL_GREEN"已启用" ) : ( ""COL_RED"禁用" ),
		g_paintballData[ id ] [ E_LIMIT ],
		g_paintballData[ id ] [ E_HEALTH ],
		g_paintballData[ id ] [ E_ARMOUR ],
		g_paintballData[ id ] [ E_REFILLER ] == true ? ( ""COL_GREEN"已启用" ) : ( ""COL_RED"禁用" ),
		g_paintballArenaData[ g_paintballData[ id ] [ E_ARENA ] ] [ E_NAME ],
		ReturnWeaponName( g_paintballData[ id ] [ E_WEAPONS ] [ 0 ] ),
		ReturnWeaponName( g_paintballData[ id ] [ E_WEAPONS ] [ 1 ] ),
		ReturnWeaponName( g_paintballData[ id ] [ E_WEAPONS ] [ 2 ] ),
		g_paintballData[ id ] [ E_HEADSHOT ] == true ? ( ""COL_GREEN"已启用" ) : ( ""COL_RED"禁用" ),
		g_paintballData[ id ] [ E_CHAT ] == true ? ( ""COL_GREEN"已启用" ) : ( ""COL_RED"禁用" ),
		g_paintballData[ id ] [ E_RANDOM ] == true ? ( ""COL_GREEN"已启用" ) : ( ""COL_RED"禁用" )
	);
	ShowPlayerDialog( playerid, DIALOG_PAINTBALL_EDIT, DIALOG_STYLE_TABLIST, "{FFFFFF}彩弹竞技 - 房间 设置", szLargeString, "改变", second_button );
}

stock ShowPlayerPaintballArenas( playerid )
{
	static
		szArenas[ 16 * sizeof( g_paintballArenaData ) ];

	if ( szArenas[ 0 ] == '\0' )
	{
		for( new i; i < sizeof( g_paintballArenaData ); i++ )
		{
			strcat( szArenas, g_paintballArenaData[ i ] [ E_NAME ] );
			strcat( szArenas, "\n" );
		}
	}

	ShowPlayerDialog( playerid, DIALOG_PAINTBALL_ARENAS, DIALOG_STYLE_LIST, "{FFFFFF}彩弹竞技 - 编辑", szArenas, "选择", "返回" );
}

stock JoinPlayerPaintball( playerid, p )
{
	if ( !IsPlayerConnected( playerid ) )
		return -1;

	if ( !Iter_Contains( paintball, p ) )
		return -1;

	if ( g_paintballData[ p ] [ E_PLAYERS ] >= g_paintballData[ p ] [ E_LIMIT ] )
		return SendError( playerid, "此 房间 目前已满,你无法加入." );

	p_PaintBallArena	{ playerid } = p;
	p_inPaintBall		{ playerid } = true;
	g_paintballData 	[ p ] [ E_PLAYERS ] ++;

	SpawnToPaintball( playerid, p );
	SendClientMessageFormatted( playerid, -1, ""COL_GREY"[彩弹竞技]"COL_WHITE" 你已加入 彩弹竞技 区域: "COL_GREY"%s"COL_WHITE".", g_paintballData[ p ] [ E_NAME ] );
	return 1;
}

stock SpawnToPaintball( playerid, p )
{
	if ( !IsPlayerConnected( playerid ) )
		return;

	if ( !Iter_Contains( paintball, p ) )
		return;

	new
		iArena = g_paintballData[ p ] [ E_ARENA ];

    ResetPlayerWeapons( playerid );

    GivePlayerWeapon( playerid, g_paintballData[ p ] [ E_WEAPONS ] [ 0 ], 16000 );
    GivePlayerWeapon( playerid, g_paintballData[ p ] [ E_WEAPONS ] [ 1 ], 16000 );
    GivePlayerWeapon( playerid, g_paintballData[ p ] [ E_WEAPONS ] [ 2 ], 16000 );

    SetPlayerHealth( playerid, g_paintballData[ p ] [ E_HEALTH ] );
	SetPlayerArmour( playerid, g_paintballData[ p ] [ E_ARMOUR ] );

 	
	// random spawns
	if ( g_paintballData[ p ][ E_RANDOM ] )
	{
		new 
			random_spawn_id = random( MAX_RANDOM_SPAWNS );
		
		SetPlayerPos( playerid, g_paintballSpawns[ iArena ][ random_spawn_id ][ 0 ], g_paintballSpawns[ iArena ][ random_spawn_id ][ 1 ], g_paintballSpawns[ iArena ][ random_spawn_id ][ 2 ] );
	}
	else SetPlayerPos( playerid, g_paintballArenaData[ iArena ] [ E_X ], g_paintballArenaData[ iArena ] [ E_Y ], g_paintballArenaData[ iArena ] [ E_Z ] );

	SetPlayerInterior( playerid, g_paintballArenaData[ iArena ] [ E_INTERIOR ] );
    SetPlayerVirtualWorld( playerid, p + 10000 );
}

stock LeavePlayerPaintball( playerid )
{
	if ( !IsPlayerConnected( playerid ) )
		return;

	new
		p = -1;

	if ( !hasPaintBallArena( playerid, p ) )
		p = p_PaintBallArena{ playerid }; // Backup

	if ( IsPlayerInPaintBall( playerid ) )
	{
		p_inPaintBall		{ playerid } = false;
		p_LeftPaintball		{ playerid } = true;
		g_paintballData 	[ p ] [ E_PLAYERS ] --;
	}

	if ( !Iter_Contains( paintball, p ) )
		return;

	if ( g_paintballData[ p ] [ E_HOST ] == playerid )
	{
		new
			oldHost = g_paintballData[ p ] [ E_HOST ];

		foreach(new i : Player)
		{
			if ( IsPlayerInPaintBall( i ) && p_PaintBallArena{ i } == p && playerid != i )
			{
				g_paintballData[ p ] [ E_HOST ] = i;
				SendClientMessageFormatted( i, -1, ""COL_GREY"[彩弹竞技]"COL_WHITE" %s(%d) 现在是 房间 的领导者.", ReturnPlayerName( i ), i );
				break;
			}
		}

		if ( oldHost == g_paintballData[ p ] [ E_HOST ] )
		{
			SendClientMessage( playerid, -1, ""COL_GREY"[彩弹竞技]"COL_WHITE" 没有人在你的 房间 中玩游戏,因此游戏已被破坏." );
			DestroyPaintballArena( p );
		}
	}
}

stock respawnAllInPaintballLobby( lobby )
{
	foreach(new i : Player)
	{
		if ( IsPlayerInPaintBall( i ) && p_PaintBallArena{ i } == lobby && GetPlayerState( i ) != PLAYER_STATE_WASTED && IsPlayerSpawned( i ) )
			SpawnPlayer( i ), SendServerMessage( i, "当 房间 主机更改了一些设置时,你就被生成了." );
	}
}

stock hasPaintBallArena( playerid, &arena = -1 )
{
	foreach(new i : paintball) {
		if ( g_paintballData[ i ] [ E_HOST ] == playerid ) {
			arena = i;
			return true;
		}
	}
	return false;
}

stock IsPlayerLeavingPaintball( playerid ) {
	return p_LeftPaintball{ playerid };
}

stock SendClientMessageToPaintball( paintballid, colour, const format[ ], va_args<> )
{
    static
		out[ 144 ];

    va_format( out, sizeof( out ), format, va_start<3> );

	foreach ( new i : Player ) if ( p_inPaintBall{ i } && p_PaintBallArena{ i } == paintballid ) {
		SendClientMessage( i, colour, out );
	}
	return 1;
}
