/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module:
 * Purpose:
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_C4                      ( 10 )

/* ** Variables ** */
enum E_C4_DATA
{
	bool: E_SET,		E_OBJECT, 		E_VEHICLE,
	Text3D: E_LABEL, 	E_WORLD, 		E_INTERIOR
};

static stock
    CP_BOMB_SHOP                    = -1,
    CP_BOMB_SHOP_LV                 = -1,
    CP_BOMB_SHOP_LS                 = -1,

	g_C4Data						[ MAX_PLAYERS ] [ MAX_C4 ] [ E_C4_DATA ],
   	p_C4Amount          			[ MAX_PLAYERS ]
;

/* ** Forwards ** */
forward OnPlayerC4Blown( playerid, Float: X, Float: Y, Float: Z, worldid );

/* ** Hooks ** */
hook OnScriptInit( )
{
	CreateDynamic3DTextLabel("[炸弹商店]", COLOR_GOLD, -1923.7546, 303.3475, 41.0469, 20.0);
	CP_BOMB_SHOP = CreateDynamicCP( -1923.7546, 303.3475, 41.0469, 2.0, 0, -1, -1, 100.0 );

	CreateDynamic3DTextLabel("[炸弹商店]", COLOR_GOLD, 1998.7263, 2298.5562, 10.8203, 20.0);
	CP_BOMB_SHOP_LV = CreateDynamicCP( 1998.7263, 2298.5562, 10.8203, 2.0, 0, -1, -1, 100.0 );

	CreateDynamic3DTextLabel("[炸弹商店]", COLOR_GOLD, 1911.2462, -1775.8755, 13.3828, 20.0);
	CP_BOMB_SHOP_LS = CreateDynamicCP( 1911.2462, -1775.8755, 13.3828, 2.0, 0, -1, -1, 100.0 );
    return 1;
}

hook OnPlayerEnterDynamicCP( playerid, checkpointid )
{
	if ( checkpointid == CP_BOMB_SHOP || checkpointid == CP_BOMB_SHOP_LV || checkpointid == CP_BOMB_SHOP_LS )
	{
		if ( ! IsPlayerJob( playerid, JOB_TERRORIST ) )
			ShowPlayerHelpDialog( playerid, 4000, "你不是~r~恐怖分子~w~~h~, 无法使用购买的 C4!" );

		return ShowPlayerDialog( playerid, DIALOG_BOMB_SHOP, DIALOG_STYLE_TABLIST, "{FFFFFF}C4 商店", "1 C4\t"COL_GOLD"$500\n5 C4\t"COL_GOLD"$2450\n出售 C4\t"COL_GREEN"$250", "选择", "取消" ), 1;
	}
    return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_BOMB_SHOP )
	{
	    if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "在监狱中无法使用此功能." );
		if ( response )
		{
			if ( ! listitem )
			{
			    if ( GetPlayerCash( playerid ) < 500 )
			        return SendError( playerid, "你的钱不足以购买此物品." );

				if ( p_C4Amount[ playerid ] >= MAX_C4 )
					return SendError( playerid, "你的 C4 数量已达到上限." );

				GivePlayerC4( playerid, 1 );
			    GivePlayerCash( playerid, -500 );
				SendServerMessage( playerid, "你购买了 1 枚 C4, 花费"COL_GOLD"$500"COL_WHITE"." );
			}
			else if ( listitem == ( 1 ) )
			{
			    if ( GetPlayerCash( playerid ) < 2450 )
			        return SendError( playerid, "你的钱不足以购买此物品." );

				if ( p_C4Amount[ playerid ] >= MAX_C4 )
					return SendError( playerid, "你的 C4 数量已达到上限." );

				if ( p_C4Amount[ playerid ] + 5 > MAX_C4 )
				{
				    new amount = MAX_C4 - p_C4Amount[ playerid ];
					SendServerMessage( playerid, "你购买了 %d 枚 C4, 花费"COL_GOLD"%s"COL_WHITE", 因为再购买 5 枚会超过携带上限.", MAX_C4 - p_C4Amount[ playerid ], cash_format( amount * 495 ) );
				    GivePlayerC4( playerid, amount );
				    GivePlayerCash( playerid, -( amount * 495 ) );
				}
				else
				{
				    SendServerMessage( playerid, "你购买了 5 枚 C4, 花费"COL_GOLD"$2450"COL_WHITE"." );
				    GivePlayerC4( playerid, 5 );
				    GivePlayerCash( playerid, -2450 );
				}
			}
			else if ( listitem == ( 2 ) )
			{
			    if ( p_C4Amount[ playerid ] < 1 )
			        return SendError( playerid, "你没有 C4." );

                GivePlayerCash( playerid, 250 );
                GivePlayerC4( playerid, -1 );

				SendServerMessage( playerid, "你出售了 1 枚 C4, 获得"COL_GOLD"$250"COL_WHITE"." );
			}
			return ShowPlayerDialog( playerid, DIALOG_BOMB_SHOP, DIALOG_STYLE_TABLIST, "{FFFFFF}C4 商店", "1 C4\t"COL_GOLD"$500\n5 C4\t"COL_GOLD"$2450\n出售 C4\t"COL_GREEN"$250", "选择", "取消" ), 1;
		}
	}
    return 1;
}

hook OnPlayerShootDynObject( playerid, weaponid, objectid, Float: x, Float: y, Float: z )
{
	new
		modelid = Streamer_GetIntData( STREAMER_TYPE_OBJECT, objectid, E_STREAMER_MODEL_ID );

	// Explosive Bullets
	CreateExplosiveBullet( playerid );

	switch( modelid )
	{
		// C4
		case 19602:
		{
			foreach(new p : Player)
			{
				for( new i = 0; i < MAX_C4; i++ )
				{
					if ( objectid == g_C4Data[ p ] [ i ] [ E_OBJECT ] )
					{
						ExplodePlayerC4s( p, i, i + 1 );
						break;
					}
				}
			}
		}
	}
	return 1;
}

hook OnPlayerKeyStateChange( playerid, newkeys, oldkeys ) {
    if ( PRESSED( KEY_YES ) ) {
	    if ( p_Class[ playerid ] == CLASS_CIVILIAN && IsPlayerJob( playerid, JOB_TERRORIST ) && !IsPlayerJailed( playerid ) ) {
	   		ExplodePlayerC4s( playerid );
        }
   	}
    return 1;
}

/* ** Commands ** */
CMD:c4( playerid, params[ ] )
{
	#if defined __cloudy_event_system
	if ( IsPlayerInEvent( playerid ) && ! EventSettingAllow( EVENT_SETTING_C4 ) ) {
		return SendError( playerid, "参加活动时无法使用此命令." );
	}
	#endif

	if ( !strcmp( params, "plant", true, 5 ) )
	{
		new
		    ID = -1
		;

		if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "在监狱中无法使用此命令." );
		if ( p_Spectating{ playerid } ) return SendError( playerid, "旁观时无法使用此类命令." );
		if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "此功能仅限平民使用." );
		if ( !IsPlayerJob( playerid, JOB_TERRORIST ) ) return SendError( playerid, "此功能仅限恐怖分子使用." );
		if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "在监狱中无法使用此命令." );
		if ( IsPlayerTazed( playerid ) ) return SendError( playerid, "被电击时无法使用此命令." );
		if ( IsPlayerDetained( playerid ) ) return SendError( playerid, "被拘留时无法使用此命令." );
		if ( IsPlayerCuffed( playerid ) ) return SendError( playerid, "被铐住时无法使用此命令." );
		if ( IsPlayerTied( playerid ) ) return SendError( playerid, "被捆绑时无法使用此命令." );
		if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "被绑架时无法使用此命令." );
		if ( IsPlayerInCasino( playerid ) ) return SendError( playerid, "在赌场内无法使用此命令." );
		if ( IsPlayerInPaintBall( playerid ) || IsPlayerDueling( playerid ) ) return SendError( playerid, "在竞技场内无法使用此命令." );
		if ( p_C4Amount[ playerid ] < 1 ) return SendError( playerid, "你没有 C4." );

		#if defined __cnr__chuffsec
			if ( IsPlayerInVehicle( playerid, g_secureTruckVehicle ) ) return SendError( playerid, "安装 C4 时不能坐在此载具内." );
		#endif

		for( new i; i < MAX_C4; i++ ) {
		    if ( !g_C4Data[ playerid ] [ i ] [ E_SET ] ) {
		        ID = i;
		        break;
			}
		}

		if ( ID != -1 )
		{
			new
		        Float: distance = 99999.99,
				robberyid = getClosestRobberySafe( playerid, distance )
			;

			if ( robberyid != INVALID_OBJECT_ID && distance < 1.50 && !g_robberyData[ robberyid ] [ E_STATE ] && AttachToRobberySafe( robberyid, playerid, ROBBERY_TYPE_C4 ) )
			{
				SendServerMessage( playerid, "你已在此处安装 C4: "COL_ORANGE"保险箱"COL_WHITE", 将自动引爆." );

				if ( g_Debugging )
				{
					printf("[DEBUG] [ROBBERY] [%d] Planted C4 { open : %d, robbed : %d, c4: %d, drill : %d, dplacer : %d, deffect : %d, replenish : %d, raw ts : %d, current ts : %d, name : %s, state : %d }",
								robberyid,
								g_robberyData[ robberyid ] [ E_OPEN ], g_robberyData[ robberyid ] [ E_ROBBED ], g_robberyData[ robberyid ] [ E_C4 ],
								g_robberyData[ robberyid ] [ E_DRILL ], g_robberyData[ robberyid ] [ E_DRILL_PLACER ], g_robberyData[ robberyid ] [ E_DRILL_EFFECT ], g_robberyData[ robberyid ] [ E_ROB_TIME ] - g_iTime,
								g_robberyData[ robberyid ] [ E_ROB_TIME ], g_iTime, g_robberyData[ robberyid ] [ E_NAME ], g_robberyData[ robberyid ] [ E_STATE ] );
				}
			}
			else
			{
				new
				    Float: X, Float: Y, Float: Z,
					iVehicle = GetPlayerVehicleID( playerid )
				;

				GetPlayerPos( playerid, X, Y, Z );

				format( szNormalString, 64, "C4 %d\n安装者: %s!", ID, ReturnPlayerName( playerid ) );
				g_C4Data[ playerid ] [ ID ] [ E_LABEL ] = Create3DTextLabel( szNormalString, setAlpha( COLOR_GREY, 0x50 ), X, Y, Z - 1.0, 15.0, GetPlayerVirtualWorld( playerid ) );
				g_C4Data[ playerid ] [ ID ] [ E_OBJECT ] = CreateDynamicObject( 19602, X, Y, Z - 0.92, 0, 0, 0, GetPlayerVirtualWorld( playerid ), GetPlayerInterior( playerid ), -1, 50.0 ); // 363 prev, Rx -90.0
				g_C4Data[ playerid ] [ ID ] [ E_WORLD ] = GetPlayerVirtualWorld( playerid );
				g_C4Data[ playerid ] [ ID ] [ E_INTERIOR ] = GetPlayerInterior( playerid );
				g_C4Data[ playerid ] [ ID ] [ E_SET ] = true;

				if ( ! iVehicle ) {
					iVehicle = GetPlayerSurfingVehicleID( playerid );
				}

			#if defined __cnr__chuffsec
				if ( iVehicle == g_secureTruckVehicle ) {
					iVehicle = INVALID_VEHICLE_ID;
				}
			#endif

				if ( IsValidVehicle( iVehicle ) )
				{
					GetVehiclePos( iVehicle, X, Y, Z );

		            g_C4Data[ playerid ] [ ID ] [ E_VEHICLE ] = iVehicle + 100; // Plus 100 just for verification

					//if ( GetOffsetFromPosition( iVehicle, X, Y, Z, vX, vY, vZ ) )
			   		//	g_C4Data[ playerid ] [ ID ] [ E_X ] = X + vX, g_C4Data[ playerid ] [ ID ] [ E_Y ] = Y + vY, g_C4Data[ playerid ] [ ID ] [ E_Z ] = Z + vY - vOffset;

					SendServerMessage( playerid, "你已安装 C4, 目标: "COL_GREY"载具"COL_WHITE", 按以下按键引爆: "COL_GREY"Y 键"COL_WHITE"." );
				    AttachDynamicObjectToVehicle( g_C4Data[ playerid ] [ ID ] [ E_OBJECT ], iVehicle, 0.0, 0.0, 6000.0, 0.0, 0.0, 0.0 );
				    Attach3DTextLabelToVehicle( g_C4Data[ playerid ] [ ID ] [ E_LABEL ], iVehicle, 0.0, 0.0, 0.0 );
				}
				else SendServerMessage( playerid, "你已安装 C4, 按以下按键引爆: "COL_GREY"Y 键"COL_WHITE"." );
			}
		}
		else return SendError( playerid, "已达到 C4 安装上限." );

        GivePlayerC4( playerid, -1 );
    	PlayerPlaySound( playerid, 25800, 0.0, 0.0, 0.0 );
		return 1;
	}
	else if ( !strcmp( params, "detonate", true, 8 ) )
	{
		new cID;

		if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "在监狱中无法使用此命令." );
		else if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "此功能仅限平民使用." );
		else if ( !IsPlayerJob( playerid, JOB_TERRORIST ) ) return SendError( playerid, "此功能仅限恐怖分子使用." );
		else if ( sscanf( params[ 9 ], "d", cID ) ) return SendUsage( playerid, "/c4 detonate [C4_ID] "COL_GREY"- 使用雷管炸毁一切." );
		else if ( cID < 0 || cID >= MAX_C4 ) return SendError( playerid, "指定的 C4 ID 无效." );
		else if ( g_C4Data[ playerid ] [ cID ] [ E_SET ] == false ) return SendError( playerid, "此 ID 的 C4 尚未安装." );
		else
		{
			if ( ExplodePlayerC4s( playerid, cID, cID + 1 ) )
				SendServerMessage( playerid, "你成功引爆了 C4, ID: %d.", cID );
			else
				SendError( playerid, "现在无法安装 C4, 请稍后重试." );
		}
		return 1;
	}
	return SendUsage( playerid, "/c4 [PLANT/DETONATE]" );
}

/* ** Functions ** */
stock DestroyAllPlayerC4s( playerid, bool: resetc4 = false )
{
	for( new i; i < MAX_C4; i++ )
	{
	    if ( g_C4Data[ playerid ] [ i ] [ E_SET ] == true )
	    {
	    	Delete3DTextLabel( g_C4Data[ playerid ] [ i ] [ E_LABEL ] );
	        DestroyDynamicObject( g_C4Data[ playerid ] [ i ] [ E_OBJECT ] );
	        g_C4Data[ playerid ] [ i ] [ E_VEHICLE ] = -100;
	  		g_C4Data[ playerid ] [ i ] [ E_WORLD ] = 0;
			g_C4Data[ playerid ] [ i ] [ E_INTERIOR ] = 0;
			g_C4Data[ playerid ] [ i ] [ E_SET ] = false;
	    }
	}

	if ( resetc4 ) {
        GivePlayerC4( playerid, GetPlayerC4Amount( playerid ) );
    }
}

stock ExplodePlayerC4s( playerid, start=0, end=MAX_C4 )
{
	if ( IsPlayerInEvent( playerid ) || IsPlayerInPaintBall( playerid ) || IsPlayerDueling( playerid ) || p_Class[ playerid ] == CLASS_POLICE )
		return 0;

	new
		Float: X, Float: Y, Float: Z, Float: Angle;

	for( new i = start; i < end; i++ )
	{
	    if ( g_C4Data[ playerid ] [ i ] [ E_SET ] == false ) continue;
		g_C4Data[ playerid ] [ i ] [ E_SET ] = false;

		new
			vehicleid = g_C4Data[ playerid ] [ i ] [ E_VEHICLE ] - 100;

		if ( IsValidVehicle( vehicleid ) )
		{
			// Physics
            SetVehicleAngularVelocity( vehicleid, ( random( 20 ) - 10 ) * 0.05, ( random( 20 ) - 10 ) * 0.05, ( random( 20 ) - 10 ) * 0.008 );
            GetVehicleVelocity( vehicleid, X, Y, Z );
            SetVehicleVelocity( vehicleid, X, Y, Z + ( random( 15 ) * 0.0008 ) );
        	SetVehicleHealth( vehicleid, 0.0 );
        	GetVehiclePos( vehicleid, X, Y, Z );
        	GetVehicleZAngle( vehicleid, Angle );
		    X += ( 2.0 * floatsin( -Angle, degrees ) );
		    Y += ( 2.0 * floatcos( -Angle, degrees ) );
		}
		else GetDynamicObjectPos( g_C4Data[ playerid ] [ i ] [ E_OBJECT ], X, Y, Z );

        // Callback
        CallLocalFunction( "OnPlayerC4Blown", "dfffd", playerid, X, Y, Z, g_C4Data[ playerid ] [ i ] [ E_WORLD ] );

		// prevent spamming wanted for farming
		if ( GetPVarInt( playerid, "C4WantedCD" ) < g_iTime && p_Class[ playerid ] != CLASS_POLICE ) {
			GivePlayerWantedLevel( playerid, 6 );
			SetPVarInt( playerid, "C4WantedCD", g_iTime + 30 );
		}

		CreateExplosionEx( X, Y, Z, 0, 10.0, g_C4Data[ playerid ] [ i ] [ E_WORLD ], g_C4Data[ playerid ] [ i ] [ E_INTERIOR ], playerid );
	    g_C4Data[ playerid ] [ i ] [ E_VEHICLE ] = -100;
	  	Delete3DTextLabel( g_C4Data[ playerid ] [ i ] [ E_LABEL ] );
		DestroyDynamicObject( g_C4Data[ playerid ] [ i ] [ E_OBJECT ] );
	}
	return 1;
}

stock hasC4Planted( playerid )
{
	for( new iC4 = 0; iC4 < MAX_C4; iC4++ )
	    if ( g_C4Data[ playerid ] [ iC4 ] [ E_SET ] )
		    return true;

	return false;
}

stock GetPlayerC4Amount( playerid ) return p_C4Amount[ playerid ];

stock SetPlayerC4Amount( playerid, amount ) {
    p_C4Amount[ playerid ] = amount;
}

stock GivePlayerC4( playerid, amount )
{
    mysql_single_query( sprintf( "UPDATE `USERS` SET `C4` = %d WHERE `ID` = %d", GetPlayerC4Amount( playerid ) + amount, GetPlayerAccountID( playerid ) ) );
    SetPlayerC4Amount( playerid, GetPlayerC4Amount( playerid ) + amount );
}