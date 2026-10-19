/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\roadblocks.pwn
 * Purpose: roadblocks system for police
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_ROADBLOCKS              ( 32 )

/* ** Variables ** */
enum E_ROADBLOCK_DATA
{
	E_OBJECT_ID,               		Text3D: E_LABEL,				E_CREATOR,

	Float: E_X, 					Float: E_Y, 					Float: E_Z
};

enum E_ROADBLOCK_OBJ_DATA
{
	E_NAME[ 17 ],		E_MODEL,					Float: E_OFFSET
};

static stock
	g_roadblockData                 [ MAX_ROADBLOCKS ] [ E_ROADBLOCK_DATA ],
	Iterator: roadblocks 			< MAX_ROADBLOCKS >,

	g_roadblockObjectData 			[ ] [ E_ROADBLOCK_OBJ_DATA ] =
	{
		{ "Small Roadblock",	1459,	0.2 },
		{ "Medium Roadblock",	978,	0.5 },
		{ "Big Roadblock",		981,	0.2 },
		{ "Detour Sign",		1425,	0.6 },
		{ "Will Be Sign",		3265,	0.9 },
		{ "Line Closed Sign",	3091,	0.5 }
	}
;


static const g_roadblockDisplayNames[][17] =
{
	"小路障",
	"中型路障",
	"大路障",
	"绕行标志",
	"将会标志",
	"线路封闭标志"
};

/* ** Hooks ** */
hook OnPlayerDisconnect( playerid, reason )
{
	ClearPlayerRoadblocks( playerid, .distance_check = false );
	return 1;
}

#if defined AC_INCLUDED
hook OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
hook OnPlayerDeath( playerid, killerid, reason )
#endif
{
	ClearPlayerRoadblocks( playerid, .distance_check = false );
	return 1;
}

hook OnPlayerUpdateEx( playerid )
{
	if ( IsPlayerSpawned( playerid ) && GetPlayerClass( playerid ) == CLASS_POLICE ) {
		ClearPlayerRoadblocks( playerid );
	}
	return 1;
}

/* ** Commands ** */
CMD:drball( playerid, params[ ] )
{
	if ( ! p_inFBI{ playerid } && ! p_AdminLevel[ playerid ] )
		return SendError( playerid, "你不在FBI." );

	new
		removed = 0;

	foreach ( new handle : roadblocks )
	{
		if ( ! p_AdminLevel[ playerid ] && g_roadblockData[ handle ] [ E_CREATOR ] != playerid )
			continue;

		new
			cur = handle;

		destroyRoadBlockStrip( handle, .remove_iter = false );
		Iter_SafeRemove( roadblocks, cur, handle );
		removed ++;
	}

	if ( removed ) {
		return SendServerMessage( playerid, "你已经清除了所有的障碍." );
	} else {
		return SendError( playerid, "没有任何障碍需要你清除." );
	}
}

CMD:drb( playerid, params[ ] )
{
	new
	    rbID
	;

	if ( !p_inFBI{ playerid } ) return SendError( playerid, "你不在FBI." );
	else if ( GetPlayerScore( playerid ) < 250 ) return SendError( playerid, "你至少需要 250 分数 才能使用此功能." );
	else if ( sscanf( params, "d", rbID ) ) return SendUsage( playerid, "/drb [ROADBLOCK_ID]" );
	else if ( rbID < 0 || rbID > MAX_ROADBLOCKS ) return SendError( playerid, "路障 ID 无效." );
	else if ( Iter_Contains( roadblocks, rbID ) ) return SendError( playerid, "路障 ID 无效." );
	else if ( g_roadblockData[ rbID ] [ E_CREATOR ] != playerid ) return SendError( playerid, "你尚未创建此尖峰带." );
	else
	{
	    destroyRoadBlockStrip( rbID, .remove_iter = true );
	    SendServerMessage( playerid, "你已经成功摧毁了一个路障." );
	}
	return 1;
}

CMD:crb( playerid, params[ ] )
{
	new
		iRoadBlock;

	if ( GetPlayerInterior( playerid ) != 0 || GetPlayerVirtualWorld( playerid ) != 0 ) return SendError( playerid, "你不能在建筑物内使用此命令." );
	else if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "被绑架时无法进行此操作." );
	else if ( IsPlayerTied( playerid ) ) return SendError( playerid, "被捆绑时无法进行此操作." );
	else if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "你被监禁了,你不能这样做." );
	else if ( !p_inFBI{ playerid } ) return SendError( playerid, "你不在FBI." );
	else if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "你不能在车内使用此命令." );
	else if ( IsPlayerInWater( playerid ) ) return SendError( playerid, "在水中无法使用此命令." );
	else if ( isnull( params ) ) return SendUsage( playerid, "/crb [SMALL/MEDIUM/BIG/CONE/DETOUR/WILL BE SIGN/LINE CLOSED]" );
	else
	{
		for( iRoadBlock = 0; iRoadBlock < sizeof( g_roadblockObjectData ); iRoadBlock++ )
			if ( strfind( g_roadblockObjectData[ iRoadBlock ] [ E_NAME ], params, true ) != -1 )
				break;

		if ( iRoadBlock >= sizeof( g_roadblockObjectData ) )
			return SendError( playerid, "你输入了无效的路障." );

		new
			iTmp = createRoadBlockStrip( playerid, iRoadBlock );

		if ( iTmp != -1 )
			SendServerMessage( playerid, "你已经成功放置了一个 "COL_GREY"%s"COL_WHITE".", g_roadblockDisplayNames[ iRoadBlock ] );
		else
			SendError( playerid, "由于意外错误,未能放置路障." );
	}
	return 1;
}

/* ** Functions ** */
stock destroyRoadBlockStrip( rbid, bool: remove_iter = false )
{
	if ( ! Iter_Contains( roadblocks, rbid ) )
	    return 0;

	DestroyDynamicObject( g_roadblockData[ rbid ] [ E_OBJECT_ID ] );
	DestroyDynamic3DTextLabel( g_roadblockData[ rbid ] [ E_LABEL ] );

	g_roadblockData[ rbid ] [ E_LABEL ] = Text3D: INVALID_3DTEXT_ID;
	g_roadblockData[ rbid ] [ E_OBJECT_ID ] = INVALID_OBJECT_ID;

	if ( remove_iter ) Iter_Remove( roadblocks, rbid );
	return 1;
}

stock createRoadBlockStrip( playerid, type )
{
	new
 		ID = Iter_Free( roadblocks ),
		Float: X, Float: Y, Float: Z, Float: Degree
	;

	if ( ID != ITER_NONE )
	{
	    GetXYInFrontOfPlayer( playerid, X, Y, Z, 2.0 );
		GetPlayerFacingAngle( playerid, Degree );

		g_roadblockData[ ID ] [ E_CREATOR ] = playerid;
		g_roadblockData[ ID ] [ E_X ] = X;
		g_roadblockData[ ID ] [ E_Y ] = Y;
		g_roadblockData[ ID ] [ E_Z ] = Z;

		DestroyDynamicObject( g_roadblockData[ ID ] [ E_OBJECT_ID ] );
		DestroyDynamic3DTextLabel( g_roadblockData[ ID ] [ E_LABEL ] );

		g_roadblockData[ ID ] [ E_OBJECT_ID ] = CreateDynamicObject( g_roadblockObjectData[ type ] [ E_MODEL ], X, Y, Z - g_roadblockObjectData[ type ] [ E_OFFSET ], 0, 0, Degree + 180.0 );
		g_roadblockData[ ID ] [ E_LABEL ] = CreateDynamic3DTextLabel( sprintf( "%s(%d)\n"COL_GREY"放置者:%s!", g_roadblockDisplayNames[ type ], ID, ReturnPlayerName( playerid ) ), COLOR_GOLD, X, Y, Z, 20.0 );

		Streamer_Update( playerid );
		Iter_Add( roadblocks, ID );
	}
	return ID;
}

stock ClearPlayerRoadblocks( playerid, bool: distance_check = true )
{
	// remove roadblocks
	foreach ( new handle : roadblocks ) if ( g_roadblockData[ handle ] [ E_CREATOR ] == playerid )
	{
		if ( distance_check && GetPlayerDistanceFromPoint( playerid, g_roadblockData[ handle ] [ E_X ], g_roadblockData[ handle ] [ E_Y ], g_roadblockData[ handle ] [ E_Z ] ) < 100.0 ) {
			continue;
		}

		new
			cur = handle;

		destroyRoadBlockStrip( handle, .remove_iter = false );
		Iter_SafeRemove( roadblocks, cur, handle );
	}
	return 1;
}
