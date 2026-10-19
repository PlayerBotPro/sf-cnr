/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\gates.pwn
 * Purpose: personal player gate system
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_GATES 					( 300 )

/* ** Variables ** */
enum E_GATE_DATA
{
	E_OBJECT,			E_PASS[ 8 ], 			Float: E_SPEED,
	Float: E_RANGE,		E_MODEL, 				bool: E_MOVING,
	E_OWNER,			E_NAME[ 24 ],			E_TIME,
	E_GANG_SQL_ID,

	Float: E_X,			Float: E_Y,				Float: E_Z,
	Float: E_RX,		Float: E_RY,			Float: E_RZ,

	Float: E_MOVE_X,	Float: E_MOVE_Y,		Float: E_MOVE_Z,
	Float: E_MOVE_RX,	Float: E_MOVE_RY,		Float: E_MOVE_RZ,

	E_CLOSE_TIMER
};

static stock
	g_gateData 						[ MAX_GATES ] [ E_GATE_DATA ],
	Iterator: gates 				< MAX_GATES >
;

/* ** Hooks ** */
hook OnScriptInit( )
{
	mysql_function_query( dbHandle, "SELECT * FROM `GATES`", true, "OnGatesLoad", "" );
	return 1;
}

hook OnPlayerKeyStateChange( playerid, newkeys, oldkeys )
{
	if ( PRESSED( KEY_LOOK_BEHIND ) ) // MMB to open gate
	{
		new
			Float: gate_distance = 99999.9,
			gate_id = getClosestGate( playerid, gate_distance )
		;

		if ( gate_id != INVALID_OBJECT_ID && gate_distance < g_gateData[ gate_id ] [ E_RANGE ] )
		{
			new
				gangId = p_GangID[ playerid ];

			if ( p_AdminLevel[ playerid ] >= 5 || g_gateData[ gate_id ] [ E_OWNER ] == p_AccountID[ playerid ] || ( Iter_Contains( gangs, gangId ) && g_gateData[ gate_id ] [ E_GANG_SQL_ID ] == g_gangData[ gangId ] [ E_SQL_ID ] ) ) {
				OpenPlayerGate( playerid, gate_id );
			}
		}
	}
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_GATE && response )
	{
		new
			objectid = GetPVarInt( playerid, "gate_editing" );

		SetPVarInt( playerid, "gate_edititem", listitem );

		if ( listitem == 0 )
		{
			Iter_Remove( gates, objectid );
			DestroyDynamicObject( g_gateData[ objectid ] [ E_OBJECT ] );
			g_gateData[ objectid ] [ E_OBJECT ] = INVALID_OBJECT_ID;
			DeletePVar( playerid, "gate_editing" );
			DeletePVar( playerid, "gate_edititem" );

			SaveToAdminLog( playerid, objectid, "destroyed gate" );
			format( szNormalString, sizeof( szNormalString ), "DELETE FROM `GATES` WHERE ID=%d", objectid );
			mysql_single_query( szNormalString );

			SendClientMessageFormatted( playerid, -1, ""COL_PINK"[大门]"COL_WHITE" 你移除了大门: "COL_GREY"%s"COL_WHITE".", g_gateData[ objectid ] [ E_NAME ] );
		}
		else if ( listitem < 9 ) ShowPlayerDialog( playerid, DIALOG_GATE_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}大门 - 编辑", ""COL_WHITE"请输入新值:", "应用", "返回" );
		else
		{
			SendServerMessage( playerid, "点击保存图标以更新门的位置." );
			EditDynamicObject( playerid, g_gateData[ objectid ] [ E_OBJECT ] );
		}
	}
	else if ( dialogid == DIALOG_GATE_OWNER && response )
	{
		SetPVarInt( playerid, "gate_o_edititem", listitem );
		ShowPlayerDialog( playerid, DIALOG_GATE_OWNER_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}大门 - 编辑", ""COL_WHITE"你想将其更改为什么?", "应用", "返回" );
	}
	else if ( dialogid == DIALOG_GATE_OWNER_EDIT )
	{
		new
			gID = GetPVarInt( playerid, "gate_o_editing" );

		if ( ! Iter_Contains( gates, gID ) )
			return SendError( playerid, "检测到无效的门,请重试." );

		if ( g_gateData[ gID ] [ E_OWNER ] != p_AccountID[ playerid ] )
			return SendError( playerid, "你需要成为此门的所有者才能对其进行编辑." );

		if ( response )
		{
			switch( GetPVarInt( playerid, "gate_o_edititem" ) )
			{
				case 0:
				{
					if ( strlen( inputtext ) < 3 || strlen( inputtext ) >= 24 )
						return ShowPlayerDialog( playerid, DIALOG_GATE_OWNER_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}大门 - 编辑", ""COL_WHITE"你想把它改成什么?\n\n"COL_RED"名称的范围必须介于 3 和 24 个字符之间.", "应用", "返回" );

					format( g_gateData[ gID ] [ E_NAME ], 24, "%s", inputtext );
					SendServerMessage( playerid, "你的门名称已设置为 \"%s\".", g_gateData[ gID ] [ E_NAME ] );
					UpdateGateData( gID, .recreate_obj = false );
				}
				case 1:
				{
					if ( strlen( inputtext ) < 3 || strlen( inputtext ) >= 8 )
                        return ShowPlayerDialog( playerid, DIALOG_GATE_OWNER_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}大门 - 编辑", ""COL_WHITE"你想把它改成什么?\n\n"COL_RED"密码的范围必须介于 3 和 8 个字符之间.", "应用", "返回" );

					format( g_gateData[ gID ] [ E_PASS ], 8, "%s", inputtext );
					SendServerMessage( playerid, "你的门密码已设置为 \"%s\".", g_gateData[ gID ] [ E_PASS ] );
					UpdateGateData( gID, .recreate_obj = false );
				}
				case 2:
				{
					new
						sql_id;

					if ( sscanf( inputtext, "D(0)", sql_id ) ) {
						return ShowPlayerDialog( playerid, DIALOG_GATE_OWNER_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}大门 - 编辑", ""COL_WHITE"你想把它改成什么?\n\n"COL_RED"帮派 ID 必须是整数.", "应用", "返回" );
					}

					// check if valid gang lol
					if ( sql_id != 0 )
					{
						new
							gangId = -1;

						foreach ( new g : gangs ) if ( sql_id == g_gangData[ g ] [ E_SQL_ID ] ) {
							gangId = g;
						}

						if ( gangId == -1 ) {
							return ShowPlayerDialog( playerid, DIALOG_GATE_OWNER_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}大门 - 编辑", ""COL_WHITE"你想把它改成什么?\n\n"COL_RED"该帮派无效或当前不在线.", "应用", "返回" );
						} else {
							SendServerMessage( playerid, "你的大门可由 \"%s\" 的成员打开.", g_gangData[ gangId ] [ E_NAME ] );
						}
					} else {
						SendServerMessage( playerid, "你已从你的大门取消分配一个帮派." );
					}

					g_gateData[ gID ] [ E_GANG_SQL_ID ] = sql_id;
					mysql_single_query( sprintf( "UPDATE `GATES` SET `GANG_ID`=%d WHERE `ID`=%d", sql_id, gID ) );
				}
			}
		}

		// redirect
		format( szNormalString, sizeof( szNormalString ), ""COL_WHITE"门标签\t"COL_GREY"%s\n"COL_WHITE"门禁密码\t"COL_GREY"%s\n"COL_WHITE"门帮ID\t"COL_GREY"%d", g_gateData[ gID ] [ E_NAME ], g_gateData[ gID ] [ E_PASS ], g_gateData[ gID ] [ E_GANG_SQL_ID ] );
		ShowPlayerDialog( playerid, DIALOG_GATE_OWNER, DIALOG_STYLE_TABLIST, "{FFFFFF}编辑门", szNormalString, "选择", "取消" );
		return 1;
	}
	else if ( dialogid == DIALOG_GATE_EDIT )
	{
		new
			gID = GetPVarInt( playerid, "gate_editing" );

		if ( response )
		{
			switch( GetPVarInt( playerid, "gate_edititem" ) )
			{
				case 1:
				{
					new
						pID;

					if ( sscanf( inputtext, "u", pID ) )
					{
						SendError( playerid, "该值必须是数字." );
						return ShowPlayerDialog( playerid, DIALOG_GATE_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}大门 - 编辑", ""COL_WHITE"请输入新值:", "应用", "返回" );
					}
					else if ( !IsPlayerConnected( pID ) )
					{
						SendError( playerid, "玩家 ID 无效." );
						return ShowPlayerDialog( playerid, DIALOG_GATE_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}大门 - 编辑", ""COL_WHITE"请输入新值:", "应用", "返回" );
					}
					g_gateData[ gID ] [ E_OWNER ] = p_AccountID[ pID ];
				}
				case 2:
				{
					if ( strlen( inputtext ) < 3 || strlen( inputtext ) >= 24 )
					{
						SendError( playerid, "名称的范围必须介于 3 和 24 个字符之间." );
						return ShowPlayerDialog( playerid, DIALOG_GATE_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}大门 - 编辑", ""COL_WHITE"请输入新值:", "应用", "返回" );
					}
					format( g_gateData[ gID ] [ E_NAME ], 24, "%s", inputtext );
				}
				case 3:
				{
					if ( strlen( inputtext ) < 3 || strlen( inputtext ) >= 8 )
					{
						SendError( playerid, "密码的范围必须介于 3 和 8 个字符之间." );
						return ShowPlayerDialog( playerid, DIALOG_GATE_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}大门 - 编辑", ""COL_WHITE"请输入新值:", "应用", "返回" );
					}
					format( g_gateData[ gID ] [ E_PASS ], 8, "%s", inputtext );
				}
				case 4:
				{
					new
						model;

					if ( sscanf( inputtext, "d", model ) )
					{
						SendError( playerid, "该值必须是数字." );
						return ShowPlayerDialog( playerid, DIALOG_GATE_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}大门 - 编辑", ""COL_WHITE"请输入新值:", "应用", "返回" );
					}
					g_gateData[ gID ] [ E_MODEL ] = model;
				}
				case 5:
				{
					new
						Float: speed;

					if ( sscanf( inputtext, "f", speed ) )
					{
						SendError( playerid, "该值必须是数字." );
						return ShowPlayerDialog( playerid, DIALOG_GATE_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}大门 - 编辑", ""COL_WHITE"请输入新值:", "应用", "返回" );
					}
					g_gateData[ gID ] [ E_SPEED ] = speed;
				}
				case 6:
				{
					new
						Float: range;

					if ( sscanf( inputtext, "f", range ) )
					{
						SendError( playerid, "该值必须是数字." );
						return ShowPlayerDialog( playerid, DIALOG_GATE_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}大门 - 编辑", ""COL_WHITE"请输入新值:", "应用", "返回" );
					}
					else if ( ! ( 1.0 <= range <= 100.0 ) )
					{
						SendError( playerid, "请指定 1.0 到 100.0 米之间的范围." );
						return ShowPlayerDialog( playerid, DIALOG_GATE_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}大门 - 编辑", ""COL_WHITE"请输入新值:", "应用", "返回" );
					}
					g_gateData[ gID ] [ E_RANGE ] = range;
				}
				case 7:
				{
					new
						time;

					if ( sscanf( inputtext, "d", time ) )
					{
						SendError( playerid, "该值必须是数字." );
						return ShowPlayerDialog( playerid, DIALOG_GATE_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}大门 - 编辑", ""COL_WHITE"请输入新值:", "应用", "返回" );
					}
					else if ( time < 100 || time > 60000 )
					{
						SendError( playerid, "该值必须介于 100 和 60000 毫秒之间." );
						return ShowPlayerDialog( playerid, DIALOG_GATE_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}大门 - 编辑", ""COL_WHITE"请输入新值:", "应用", "返回" );
					}
					g_gateData[ gID ] [ E_TIME ] = time;
				}
				case 8:
				{
					new
						sql_id;

					if ( sscanf( inputtext, "d", sql_id ) )
					{
						SendError( playerid, "该值必须是数字." );
						return ShowPlayerDialog( playerid, DIALOG_GATE_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}大门 - 编辑", ""COL_WHITE"请输入新值:", "应用", "返回" );
					}
					else if ( ! ( 0 <= sql_id < 1000000 ) )
					{
						SendError( playerid, "指定的帮派 ID 无效." );
						return ShowPlayerDialog( playerid, DIALOG_GATE_EDIT, DIALOG_STYLE_INPUT, "{FFFFFF}大门 - 编辑", ""COL_WHITE"请输入新值:", "应用", "返回" );
					}
					g_gateData[ gID ] [ E_GANG_SQL_ID ] = sql_id;
					mysql_single_query( sprintf( "UPDATE `GATES` SET `GANG_ID`=%d WHERE `ID`=%d", sql_id, gID ) );
				}
			}
			UpdateGateData( gID );
			Streamer_Update( playerid );
			cmd_editgate( playerid, sprintf( "%d", gID ) );
			SendServerMessage( playerid, "你已成功更新此门." );
		}
		else cmd_editgate( playerid, sprintf( "%d", gID ) );
	}
	return 1;
}

hook OnPlayerEditDynObject( playerid, objectid, response, Float: x, Float: y, Float: z, Float: rx, Float: ry, Float: rz )
{
	new
		gateItem = GetPVarInt( playerid, "gate_edititem" );

	if ( gateItem > 6 )
	{
		if ( response == EDIT_RESPONSE_FINAL )
		{
			new
				gID = GetPVarInt( playerid, "gate_editing" );

			switch( gateItem )
			{
				case 9:
				{
					g_gateData[ gID ] [ E_X ] = x;
					g_gateData[ gID ] [ E_Y ] = y;
					g_gateData[ gID ] [ E_Z ] = z;
					g_gateData[ gID ] [ E_RX ] = float( floatround( rx ) );
					g_gateData[ gID ] [ E_RY ] = float( floatround( ry ) );
					g_gateData[ gID ] [ E_RZ ] = float( floatround( rz ) );
					SendClientMessageFormatted( playerid, -1, ""COL_PINK"[大门]"COL_WHITE" 门关闭位置: "COL_GREY" %f, %f, %f, %f, %f, %f", g_gateData[ gID ] [ E_X ], g_gateData[ gID ] [ E_Y ], g_gateData[ gID ] [ E_Z ], g_gateData[ gID ] [ E_RX ], g_gateData[ gID ] [ E_RY ], g_gateData[ gID ] [ E_RZ ] );
				}
				case 10:
				{
					g_gateData[ gID ] [ E_MOVE_X ] = x;
					g_gateData[ gID ] [ E_MOVE_Y ] = y;
					g_gateData[ gID ] [ E_MOVE_Z ] = z;
					g_gateData[ gID ] [ E_MOVE_RX ] = float( floatround( rx ) );
					g_gateData[ gID ] [ E_MOVE_RY ] = float( floatround( ry ) );
					g_gateData[ gID ] [ E_MOVE_RZ ] = float( floatround( rz ) );
					SendClientMessageFormatted( playerid, -1, ""COL_PINK"[大门]"COL_WHITE" 门打开位置: "COL_GREY" %f, %f, %f, %f, %f, %f", g_gateData[ gID ] [ E_MOVE_X ], g_gateData[ gID ] [ E_MOVE_Y ], g_gateData[ gID ] [ E_MOVE_Z ], g_gateData[ gID ] [ E_MOVE_RX ], g_gateData[ gID ] [ E_MOVE_RY ], g_gateData[ gID ] [ E_MOVE_RZ ] );
				}
			}
			UpdateGateData( gID );
			cmd_editgate( playerid, sprintf( "%d", gID ) );
			Streamer_Update( playerid );
		}
	}
	return 1;
}

/* ** Commands ** */
CMD:gate( playerid, params[ ] )
{
	new
        Float: distance = 99999.99,
		gID = getClosestGate( playerid, distance )
	;

	if ( gID == INVALID_OBJECT_ID )
		return SendError( playerid, "你不靠近任何大门." );

	if ( strmatch( params, "edit" ) )
	{
		if ( g_gateData[ gID ] [ E_OWNER ] != p_AccountID[ playerid ] )
			return SendError( playerid, "你需要成为此门的所有者才能对其进行编辑." );

		format( szNormalString, sizeof( szNormalString ), ""COL_WHITE"门标签\t"COL_GREY"%s\n"COL_WHITE"门禁密码\t"COL_GREY"%s\n"COL_WHITE"门帮ID\t"COL_GREY"%d", g_gateData[ gID ] [ E_NAME ], g_gateData[ gID ] [ E_PASS ], g_gateData[ gID ] [ E_GANG_SQL_ID ] );
		ShowPlayerDialog( playerid, DIALOG_GATE_OWNER, DIALOG_STYLE_TABLIST, "{FFFFFF}编辑门", szNormalString, "选择", "取消" );

		SetPVarInt( playerid, "gate_o_editing", gID );
		SendClientMessageFormatted( playerid, -1, ""COL_GREY"[大门]"COL_WHITE" 你现在正在编辑 "COL_GREY"%s"COL_WHITE".", g_gateData[ gID ] [ E_NAME ] );
	}
	else if ( !strcmp( params, "open", true, 4 ) )
	{
		new
			szPassword[ 8 ];

		strreplacechar( params, '\\', '/' );

		if ( sscanf( params[ 5 ], "s[8]", szPassword ) )
			return SendUsage( playerid, "/gate open [PASSWORD]" );

		new
			gates = 0;

		foreach(new g : gates)
		{
			if ( ( distance = GetPlayerDistanceFromPoint( playerid, g_gateData[ g ] [ E_X ], g_gateData[ g ] [ E_Y ], g_gateData[ g ] [ E_Z ] ) ) > g_gateData[ g ] [ E_RANGE ] )
				continue; // return SendError( playerid, "You're not within the gates' operation range." );

			if ( strcmp( szPassword, g_gateData[ g ] [ E_PASS ], false ) )
				continue; // return SendError( playerid, "Incorrect password. Please try again." );

			if ( OpenPlayerGate( playerid, g ) ) {
				gates ++;
			}
		}
		return !gates ? SendError( playerid, "某个门正在运行,但不在范围内,或者只是密码不正确." ) : 1;
	}
	else if ( strmatch( params, "closest" ) && p_AdminLevel[ playerid ] > 1 )
	{
		SendServerMessage( playerid, "距离你最近的登机口是 "COL_GREY"%s"COL_WHITE". (ID:%d,距离:%f)", g_gateData[ gID ] [ E_NAME ], gID, distance );
	}
	else SendUsage( playerid, "/gate [OPEN/EDIT]" );
	return 1;
}

/* ** SQL Threads ** */
thread OnGatesLoad( )
{
	new
		rows, fields, i = -1, gID,
	    loadingTick = GetTickCount( )
	;

	cache_get_data( rows, fields );
	if ( rows )
	{
		while( ++i < rows )
		{
			gID = cache_get_field_content_int( i, "ID", dbHandle );

			cache_get_field_content( i, "PASSWORD", 			g_gateData[ gID ] [ E_PASS ], dbHandle, 8 );
			cache_get_field_content( i, "NAME", 				g_gateData[ gID ] [ E_NAME ], dbHandle, 24 );

			g_gateData[ gID ] [ E_OWNER ] = cache_get_field_content_int( i, "OWNER", dbHandle );
			g_gateData[ gID ] [ E_MODEL ] = cache_get_field_content_int( i, "MODEL", dbHandle );
			g_gateData[ gID ] [ E_TIME ] = cache_get_field_content_int( i, "TIME", dbHandle );
			g_gateData[ gID ] [ E_SPEED ] = cache_get_field_content_float( i, "SPEED", dbHandle );
			g_gateData[ gID ] [ E_RANGE ] = cache_get_field_content_float( i, "RANGE", dbHandle );
			g_gateData[ gID ] [ E_X ] = cache_get_field_content_float( i, "X", dbHandle );
			g_gateData[ gID ] [ E_Y ] = cache_get_field_content_float( i, "Y", dbHandle );
			g_gateData[ gID ] [ E_Z ] = cache_get_field_content_float( i, "Z", dbHandle );
			g_gateData[ gID ] [ E_RX ] = cache_get_field_content_float( i, "RX", dbHandle );
			g_gateData[ gID ] [ E_RY ] = cache_get_field_content_float( i, "RY", dbHandle );
			g_gateData[ gID ] [ E_RZ ] = cache_get_field_content_float( i, "RZ", dbHandle );
			g_gateData[ gID ] [ E_MOVE_X ] = cache_get_field_content_float( i, "MOVE_X", dbHandle );
			g_gateData[ gID ] [ E_MOVE_Y ] = cache_get_field_content_float( i, "MOVE_Y", dbHandle );
			g_gateData[ gID ] [ E_MOVE_Z ] = cache_get_field_content_float( i, "MOVE_Z", dbHandle );
			g_gateData[ gID ] [ E_MOVE_RX ] = cache_get_field_content_float( i, "MOVE_RX", dbHandle );
			g_gateData[ gID ] [ E_MOVE_RY ] = cache_get_field_content_float( i, "MOVE_RY", dbHandle );
			g_gateData[ gID ] [ E_MOVE_RZ ] = cache_get_field_content_float( i, "MOVE_RZ", dbHandle );
			g_gateData[ gID ] [ E_GANG_SQL_ID ] = cache_get_field_content_int( i, "GANG_ID", dbHandle );

			g_gateData[ gID ] [ E_CLOSE_TIMER ] = -1;
			g_gateData[ gID ] [ E_OBJECT ] = CreateDynamicObject( g_gateData[ gID ] [ E_MODEL ], g_gateData[ gID ] [ E_X ], g_gateData[ gID ] [ E_Y ], g_gateData[ gID ] [ E_Z ], g_gateData[ gID ] [ E_RX ], g_gateData[ gID ] [ E_RY ], g_gateData[ gID ] [ E_RZ ] );

	    	Iter_Add(gates, gID);
		}
	}
	printf( "[GATES]: %d gates have been loaded. (Tick: %dms)", i, GetTickCount( ) - loadingTick );
	return 1;
}

/* ** Functions ** */
stock CreateGate( playerid, password[ 8 ], model, Float: speed, Float: range, Float: x, Float: y, Float: z, Float: rx, Float: ry, Float: rz )
{
	new gID = Iter_Free(gates);

	if ( gID != ITER_NONE )
	{
		erase( g_gateData[ gID ] [ E_NAME ] );

		format( g_gateData[ gID ] [ E_PASS ], 8, "%s", password );
		format( g_gateData[ gID ] [ E_NAME ], 24, "门" );
		g_gateData[ gID ] [ E_OWNER ] = p_AccountID[ playerid ];
		g_gateData[ gID ] [ E_MODEL ] = model;
		g_gateData[ gID ] [ E_SPEED ] = speed;
		g_gateData[ gID ] [ E_TIME ] = 2000;
		g_gateData[ gID ] [ E_CLOSE_TIMER ] = -1;
		g_gateData[ gID ] [ E_RANGE ] = range;
		g_gateData[ gID ] [ E_X ] = x;
		g_gateData[ gID ] [ E_Y ] = y;
		g_gateData[ gID ] [ E_Z ] = z;
		g_gateData[ gID ] [ E_RX ] = rx;
		g_gateData[ gID ] [ E_RY ] = ry;
		g_gateData[ gID ] [ E_RZ ] = rz;
		g_gateData[ gID ] [ E_MOVE_X ] = x;
		g_gateData[ gID ] [ E_MOVE_Y ] = y;
		g_gateData[ gID ] [ E_MOVE_Z ] = z;
		g_gateData[ gID ] [ E_MOVE_RX ] = rx;
		g_gateData[ gID ] [ E_MOVE_RY ] = ry;
		g_gateData[ gID ] [ E_MOVE_RZ ] = rz;
		g_gateData[ gID ] [ E_GANG_SQL_ID ] = 0;

		format( szBigString, sizeof( szBigString ), "INSERT INTO `GATES` VALUES(%d,%d,'%s','Gate',%d,2000,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,0)", gID, playerid, mysql_escape( password ), model, speed, range, x, y, z, rx, ry, rz, x, y, z, rx, ry, rz );
		mysql_single_query( szBigString );

		g_gateData[ gID ] [ E_OBJECT ] = CreateDynamicObject( g_gateData[ gID ] [ E_MODEL ], g_gateData[ gID ] [ E_X ], g_gateData[ gID ] [ E_Y ], g_gateData[ gID ] [ E_Z ], g_gateData[ gID ] [ E_RX ], g_gateData[ gID ] [ E_RY ], g_gateData[ gID ] [ E_RZ ] );
		Iter_Add(gates, gID);
	}
	return gID;
}

stock getClosestGate( playerid, &Float: dis = 99999.99 )
{
	new
		Float: dis2,
		object = INVALID_OBJECT_ID
	;
	foreach(new i : gates)
	{
    	dis2 = GetPlayerDistanceFromPoint( playerid, g_gateData[ i ] [ E_X ], g_gateData[ i ] [ E_Y ], g_gateData[ i ] [ E_Z ] );
    	if ( dis2 < dis && dis2 != -1.00 ) {
    	    dis = dis2;
    	    object = i;
		}
	}
	return object;
}

stock UpdateGateData( gID, bool: recreate_obj = true )
{
	if ( Iter_Contains( gates, gID ) )
	{
		format( szLargeString, sizeof( szLargeString ),
			"UPDATE `GATES` SET `OWNER`=%d,`NAME`='%s',`PASSWORD`='%s',`MODEL`=%d,`TIME`=%d,`SPEED`=%f,`RANGE`=%f,`X`=%f,`Y`=%f,`Z`=%f,`RX`=%f,`RY`=%f,`RZ`=%f,`MOVE_X`=%f,`MOVE_Y`=%f,`MOVE_Z`=%f,`MOVE_RX`=%f,`MOVE_RY`=%f,`MOVE_RZ`=%f WHERE `ID`=%d",
			g_gateData[ gID ] [ E_OWNER ], mysql_escape( g_gateData[ gID ] [ E_NAME ] ), mysql_escape( g_gateData[ gID ] [ E_PASS ] ), g_gateData[ gID ] [ E_MODEL ], g_gateData[ gID ] [ E_TIME ], g_gateData[ gID ] [ E_SPEED ], g_gateData[ gID ] [ E_RANGE ],
			g_gateData[ gID ] [ E_X ], g_gateData[ gID ] [ E_Y ], g_gateData[ gID ] [ E_Z ], g_gateData[ gID ] [ E_RX ], g_gateData[ gID ] [ E_RY ], g_gateData[ gID ] [ E_RZ ],
			g_gateData[ gID ] [ E_MOVE_X ], g_gateData[ gID ] [ E_MOVE_Y ], g_gateData[ gID ] [ E_MOVE_Z ], g_gateData[ gID ] [ E_MOVE_RX ], g_gateData[ gID ] [ E_MOVE_RY ], g_gateData[ gID ] [ E_MOVE_RZ ], gID );

		mysql_single_query( szLargeString );

		if ( recreate_obj ) {
			DestroyDynamicObject( g_gateData[ gID ] [ E_OBJECT ] );
			g_gateData[ gID ] [ E_OBJECT ] = CreateDynamicObject( g_gateData[ gID ] [ E_MODEL ], g_gateData[ gID ] [ E_X ], g_gateData[ gID ] [ E_Y ], g_gateData[ gID ] [ E_Z ], g_gateData[ gID ] [ E_RX ], g_gateData[ gID ] [ E_RY ], g_gateData[ gID ] [ E_RZ ] );
		}
	}
}

stock OpenPlayerGate( forplayerid, g )
{
	if ( g_gateData[ g ] [ E_CLOSE_TIMER ] != -1 ) {
		return 0;
	}

	if ( forplayerid != INVALID_PLAYER_ID && !strmatch( g_gateData[ g ] [ E_NAME ], "N/A" ) ) {
		SendClientMessageFormatted( forplayerid, -1, ""COL_GREY"[大门]"COL_WHITE" 你已经打开了 "COL_GREY"%s"COL_WHITE".", g_gateData[ g ] [ E_NAME ] );
	}

	new
		travelInterval = MoveDynamicObject( g_gateData[ g ] [ E_OBJECT ], g_gateData[ g ] [ E_MOVE_X ], g_gateData[ g ] [ E_MOVE_Y ], g_gateData[ g ] [ E_MOVE_Z ], g_gateData[ g ] [ E_SPEED ], g_gateData[ g ] [ E_MOVE_RX ], g_gateData[ g ] [ E_MOVE_RY ], g_gateData[ g ] [ E_MOVE_RZ ] );

	g_gateData[ g ] [ E_CLOSE_TIMER ] = SetTimerEx( "StartGateClose", travelInterval + g_gateData[ g ] [ E_TIME ], false, "d", g );
	return 1;
}

function StartGateClose( gID ) {
	g_gateData[ gID ] [ E_CLOSE_TIMER ] = -1;
	return MoveDynamicObject( g_gateData[ gID ] [ E_OBJECT ], g_gateData[ gID ] [ E_X ], g_gateData[ gID ] [ E_Y ], g_gateData[ gID ] [ E_Z ], g_gateData[ gID ] [ E_SPEED ], g_gateData[ gID ] [ E_RX ], g_gateData[ gID ] [ E_RY ], g_gateData[ gID ] [ E_RZ ] ), 1;
}

stock Gate_Exists( gateid ) {
	return 0 <= gateid < MAX_GATES && Iter_Contains( gates, gateid );
}

stock SetPlayerEditGate( playerid, gateid )
{
	format( szLargeString, sizeof( szLargeString ),
		""COL_RED"移除这扇门?\t \n所有者 ID\t"COL_GREY"%d\n姓名\t"COL_GREY"%s\n密码\t"COL_GREY"%s\n型号\t"COL_GREY"%d\n速度\t"COL_GREY"%f\n范围\t"COL_GREY"%f\n暂停\t"COL_GREY"%d MS\n帮派 ID\t%d\n更改闭合位置\t \n更改打开位置\t ",
		g_gateData[ gateid ] [ E_OWNER ], g_gateData[ gateid ] [ E_NAME ], g_gateData[ gateid ] [ E_PASS ], g_gateData[ gateid ] [ E_MODEL ], g_gateData[ gateid ] [ E_SPEED ], g_gateData[ gateid ] [ E_RANGE ], g_gateData[ gateid ] [ E_TIME ], g_gateData[ gateid ] [ E_GANG_SQL_ID ]
	);

	SetPVarInt( playerid, "gate_editing", gateid );
	ShowPlayerDialog( playerid, DIALOG_GATE, DIALOG_STYLE_TABLIST, "{FFFFFF}编辑门", szLargeString, "选择", "取消" );
}
