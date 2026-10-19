/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\vehicles\garages.pwn
 * Purpose: garage system to allow players to store their personal vehicles
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Macros ** */
#define UpdateGarageTitle(%0) \
	mysql_function_query(dbHandle,sprintf("SELECT f.`NAME` FROM `USERS` f LEFT JOIN `GARAGES` m ON m.`OWNER`=f.`ID` WHERE m.`ID`=%d",(%0)),true,"OnUpdateGarageTitle","i",(%0))

#define UpdateGarageData(%0) \
	mysql_function_query(dbHandle,sprintf("UPDATE `GARAGES` SET OWNER=%d,PRICE=%d,INTERIOR=%d WHERE ID=%d",g_garageData[(%0)][E_OWNER_ID],g_garageData[(%0)][E_PRICE],g_garageData[(%0)][E_INTERIOR_ID],(%0)),true,"","")

/* ** Definitions ** */
#define MAX_GARAGES 					( 200 )

/* ** Variables ** */
enum E_GARAGE_DATA
{
	E_OWNER_ID,					E_PRICE,					E_INTERIOR_ID,
	Float: E_X,         		Float: E_Y,             	Float: E_Z,
	Float: E_ANGLE,    			E_SQL_ID,					E_CHECKPOINT,
	Text3D: E_LABEL, 			E_WORLD
};

enum E_GARAGE_INT_DATA
{
	E_NAME[ 17 ],				E_INTERIOR,
	E_VEHICLE_CAPACITY,			E_PRICE,					Float: E_ANGLE,
	Float: E_X,					Float: E_Y, 				Float: E_Z,
	Float: E_PREVIEW_POS[ 3 ],	Float: E_PREVIEW_LOOKAT[ 3 ]
};

new
	g_garageInteriorData 			[ ] [ E_GARAGE_INT_DATA ] =
	{
		{ "默认内饰",	11, 3, 	0, 		 0.0, 		405.0301, 2508.6348, 16.7825, { 419.2017, 2517.6489, 17.9550 }, { 401.4677, 2506.3042, 16.9824 } },
		{ "中型内饰", 	22, 5, 	1500000, 180.0, 	150.8938, 2497.9995, 16.5999, { 140.8066, 2483.9426, 16.7998 }, { 159.9573, 2501.1057, 16.7998 } },
		{ "豪华内饰", 	33, 10, 3000000, 270.0, 	380.1852, 2496.8149, 16.4343, { 375.7204, 2486.4741, 16.6344 }, { 427.4626, 2505.8796, 16.6344 } }
	},
	g_garageData 					[ MAX_GARAGES ] [ E_GARAGE_DATA ],
	szg_garageInteriors				[ 174 ],

	// Iterator
	Iterator:garages<MAX_GARAGES>
;

/* ** Hooks ** */
hook OnScriptInit( )
{
	// format garage interior list
	for( new i = 0; i < sizeof( g_garageInteriorData ); i++ ) {
		format( szg_garageInteriors, sizeof( szg_garageInteriors ), "%s"COL_GREY"%d 车辆槽位"COL_WHITE"\t%s\n", szg_garageInteriors, g_garageInteriorData[ i ] [ E_VEHICLE_CAPACITY ], g_garageInteriorData[ i ] [ E_NAME ] );
	}

	// load all garages
	mysql_function_query( dbHandle, "SELECT * FROM `GARAGES`", true, "OnGaragesLoad", "" );
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_GARAGE_INTERIORS )
	{
	    if ( response )
	    {
	        if ( p_InGarage[ playerid ] == -1 )
				return SendError( playerid, "你不在任何车库内." );

	        if ( g_garageData[ p_InGarage[ playerid ] ] [ E_OWNER_ID ] != p_AccountID[ playerid ] )
				return SendError( playerid, "你不是这个车库的所有者." );

			p_ViewingInterior{ playerid } = listitem;
			ShowPlayerDialog( playerid, DIALOG_GARAGE_INT_CONFIRM, DIALOG_STYLE_LIST, "{FFFFFF}车库内饰", "购买车库内部\n预览车库内部", "选择", "返回" );
		}
	}
	else if ( dialogid == DIALOG_GARAGE_INT_CONFIRM )
	{
		if ( response )
		{
	        if ( p_InGarage[ playerid ] == -1 )
				return SendError( playerid, "你不在任何车库内." );

	        if ( g_garageData[ p_InGarage[ playerid ] ] [ E_OWNER_ID ] != p_AccountID[ playerid ] )
				return SendError( playerid, "你不是这个车库的所有者." );

			new
				intid = p_ViewingInterior{ playerid };

			switch( listitem )
			{
				case 0:
				{
					if ( g_garageInteriorData[ intid ] [ E_PRICE ] > GetPlayerCash( playerid ) )
					{
						ShowPlayerDialog( playerid, DIALOG_GARAGE_INT_CONFIRM, DIALOG_STYLE_LIST, "{FFFFFF}车库内饰", "购买车库内部\n预览车库内部", "选择", "返回" );
						SendError( playerid, "这个内饰成本 "COL_GOLD"%s"COL_WHITE".你没有这个金额.", cash_format( g_garageInteriorData[ intid ] [ E_PRICE ] ) );
					}
					else if ( ArePlayersInGarage( playerid, p_InGarage[ playerid ] ) )
					{
						ShowPlayerDialog( playerid, DIALOG_GARAGE_INT_CONFIRM, DIALOG_STYLE_LIST, "{FFFFFF}车库内饰", "购买车库内部\n预览车库内部", "选择", "返回" );
						SendError( playerid, "如果建筑物内有人,则你无法购买车库内部." );
					}
					else if ( GetPlayerVehiclesInGarage( playerid, p_InGarage[ playerid ], .strict_mode = true ) )
					{
						ShowPlayerDialog( playerid, DIALOG_GARAGE_INT_CONFIRM, DIALOG_STYLE_LIST, "{FFFFFF}车库内饰", "购买车库内部\n预览车库内部", "选择", "返回" );
						SendError( playerid, "如果建筑物内有车辆,则你无法购买车库内部." );
					}
					else
					{
					    new garageid = p_InGarage[ playerid ];
					    GivePlayerCash( playerid, -( g_garageInteriorData[ intid ] [ E_PRICE ] ) );

					    if ( intid != 0 )
							SendServerMessage( playerid, "你已经购买了%s "COL_GOLD"%s"COL_WHITE" 你的车库.", g_garageInteriorData[ intid ] [ E_NAME ], cash_format( g_garageInteriorData[ intid ] [ E_PRICE ] ) );
						else
						    SendServerMessage( playerid, "你已成功将内部装饰重置为默认内部装饰." );

						pauseToLoad( playerid );

						SetPlayerPos( playerid, g_garageInteriorData[ intid ] [ E_X ], g_garageInteriorData[ intid ] [ E_Y ], g_garageInteriorData[ intid ] [ E_Z ] );
						SetPlayerInterior( playerid, g_garageInteriorData[ intid ] [ E_INTERIOR ] );
					  	SetPlayerVirtualWorld( playerid, g_garageData[ garageid ] [ E_WORLD ] );

						mysql_single_query( sprintf( "UPDATE `GARAGES` SET `INTERIOR`=%d WHERE `ID`=%d", ( g_garageData[ garageid ] [ E_INTERIOR_ID ] = intid ), garageid ) );
					}
				}
				case 1:
				{
					if ( p_WantedLevel[ playerid ] ) {
						ShowPlayerDialog( playerid, DIALOG_GARAGE_INT_CONFIRM, DIALOG_STYLE_LIST, "{FFFFFF}车库内饰", "购买车库内部\n预览车库内部", "选择", "返回" );
						return SendError( playerid, "此功能要求你不能有 通缉等级." );
					}
					if ( ArePlayersInGarage( playerid, p_InGarage[ playerid ] ) ) {
						ShowPlayerDialog( playerid, DIALOG_GARAGE_INT_CONFIRM, DIALOG_STYLE_LIST, "{FFFFFF}车库内饰", "购买车库内部\n预览车库内部", "选择", "返回" );
						return SendError( playerid, "如果建筑物内有人,你将无法查看车库内部." );
					}

					TogglePlayerControllable( playerid, 0 );

					SetPlayerPos( playerid, g_garageInteriorData[ intid ] [ E_X ], g_garageInteriorData[ intid ] [ E_Y ], g_garageInteriorData[ intid ] [ E_Z ] );
					SetPlayerInterior( playerid, g_garageInteriorData[ intid ] [ E_INTERIOR ] );

					InterpolateCameraPos( playerid, g_garageInteriorData[ intid ] [ E_PREVIEW_POS ] [ 0 ], g_garageInteriorData[ intid ] [ E_PREVIEW_POS ] [ 1 ], g_garageInteriorData[ intid ] [ E_PREVIEW_POS ] [ 2 ] + 1.5, g_garageInteriorData[ intid ] [ E_PREVIEW_LOOKAT ] [ 0 ], g_garageInteriorData[ intid ] [ E_PREVIEW_LOOKAT ] [ 1 ], g_garageInteriorData[ intid ] [ E_PREVIEW_LOOKAT ] [ 2 ], 15000, CAMERA_MOVE );
					InterpolateCameraLookAt( playerid, g_garageInteriorData[ intid ] [ E_PREVIEW_LOOKAT ] [ 0 ], g_garageInteriorData[ intid ] [ E_PREVIEW_LOOKAT ] [ 1 ], g_garageInteriorData[ intid ] [ E_PREVIEW_LOOKAT ] [ 2 ], g_garageInteriorData[ intid ] [ E_PREVIEW_POS ] [ 0 ], g_garageInteriorData[ intid ] [ E_PREVIEW_POS ] [ 1 ], g_garageInteriorData[ intid ] [ E_PREVIEW_POS ] [ 2 ] + 1.5, 15000, CAMERA_MOVE );

					SendServerMessage( playerid, "你现在正在预览 "COL_GREY"%s "COL_GOLD"%s"COL_WHITE".按 Enter 键停止.", g_garageInteriorData[ intid ] [ E_NAME ], cash_format( g_garageInteriorData[ intid ] [ E_PRICE ] ) );
					SetPVarInt( playerid, "viewing_garageints", 1 );
				}
			}
		}
		else ShowPlayerDialog( playerid, DIALOG_GARAGE_INTERIORS, DIALOG_STYLE_LIST, "{FFFFFF}车库内饰", szg_garageInteriors, "选择", "返回" );
	}
	return 1;
}

hook OnPlayerKeyStateChange( playerid, newkeys, oldkeys )
{
	if ( PRESSED( KEY_SECONDARY_ATTACK ) )
	{
		if ( GetPVarInt( playerid, "viewing_garageints" ) == 1 )
		{
			new
				iInterior = g_garageData[ p_InGarage[ playerid ] ] [ E_INTERIOR_ID ];

			SendServerMessage( playerid, "你已停止查看车库内部." );
			SetPlayerPos( playerid, g_garageInteriorData[ iInterior ] [ E_X ], g_garageInteriorData[ iInterior ] [ E_Y ], g_garageInteriorData[ iInterior ] [ E_Z ] );
			SetPlayerInterior( playerid, g_garageInteriorData[ iInterior ] [ E_INTERIOR ] );
		    DeletePVar( playerid, "viewing_garageints" );
			TogglePlayerControllable( playerid, 1 );
			SetCameraBehindPlayer( playerid );
			return 1;
		}
	}
	return 1;
}

/* ** Commands ** */
CMD:garage( playerid, params[ ] )
{
	if ( p_accountSecurityData[ playerid ] [ E_ID ] && ! p_accountSecurityData[ playerid ] [ E_VERIFIED ] && p_accountSecurityData[ playerid ] [ E_MODE ] != SECURITY_MODE_DISABLED )
		return SendError( playerid, "使用此功能需要先验证账号. "COL_YELLOW"(输入 /verify)" );

	new
		iOwner = INVALID_PLAYER_ID,
		iGarage = p_InGarage[ playerid ],
		iVehicle = GetPlayerVehicleID( playerid ),
		iVehicleSeat = GetPlayerVehicleSeat( playerid )
	;

	if ( strmatch( params, "buy" ) )
	{
		if ( GetPlayerOwnedGarages( playerid ) >= GetPlayerGarageSlots( playerid ) ) return SendError( playerid, "你无法再购买更多车库,你已达到限制." );
		if ( GetPlayerScore( playerid ) < 500 ) return SendError( playerid, "你至少需要 500 分数 才能购买车库." );

		foreach(new g : garages)
		{
			if ( IsPlayerInDynamicCP( playerid, g_garageData[ g ] [ E_CHECKPOINT ] ) )
			{
			    if ( !g_garageData[ g ] [ E_OWNER_ID ] )
			    {
			        if ( GetPlayerCash( playerid ) < g_garageData[ g ] [ E_PRICE ] )
						return SendError( playerid, "你没有足够的钱来购买这个车库." );

					g_garageData[ g ] [ E_OWNER_ID ] = p_AccountID[ playerid ];
					UpdateGarageData( g );
					UpdateGarageTitle( g );
					GivePlayerCash( playerid, -( g_garageData[ g ] [ E_PRICE ] ) );
					SendClientMessageFormatted( playerid, -1, ""COL_GREY"[车库]"COL_WHITE" 你已经买了这个车库 "COL_GOLD"%s"COL_WHITE".", cash_format( g_garageData[ g ] [ E_PRICE ] ) );
					return 1;
				}
			    else return SendError( playerid, "这个车库不出售." );
			}
		}
		SendError( playerid, "你不在任何车库入口附近." );
		return 1;
	}
	else if ( strmatch( params, "upgrade" ) )
	{
		if ( iGarage == -1 ) return SendError( playerid, "你不在任何车库里." );
		else if ( g_garageData[ iGarage ] [ E_OWNER_ID ] != p_AccountID[ playerid ] ) return SendError( playerid, "你不是这个车库的所有者." );
		else
		{
			ShowPlayerDialog( playerid, DIALOG_GARAGE_INTERIORS, DIALOG_STYLE_LIST, "{FFFFFF}车库内饰", szg_garageInteriors, "选择", "返回" );
		}
		return 1;
	}
	else if ( strmatch( params, "enter" ) )
	{
		foreach(new g : garages)
		{
			if ( IsPlayerInDynamicCP( playerid, g_garageData[ g ] [ E_CHECKPOINT ] ) )
			{
				new
					iInterior = g_garageData[ g ] [ E_INTERIOR_ID ]
				;

				if ( iVehicle != 0 && iVehicleSeat == 0 )
				{
					if ( !g_garageData[ g ] [ E_OWNER_ID ] )
						return SendServerMessage( playerid, "你不能进入无主车库.要购买此产品,请输入 "COL_GREY"/garage buy"COL_WHITE"." );

					if ( !g_buyableVehicle{ iVehicle } || g_adminSpawnedCar{ iVehicle } )
						return SendError( playerid, "只有通过车辆经销商销售的车辆才能进入." );

					new iSlot = getVehicleSlotFromID( iVehicle, iOwner );

					if ( p_AccountID[ iOwner ] != g_garageData[ g ] [ E_OWNER_ID ] )
						return SendError( playerid, "你不能驾驶不属于该车库所有者的车辆进入." );

					if ( g_vehicleData[ iOwner ] [ iSlot ] [ E_LOCKED ] && playerid != iOwner )
						return SendError( playerid, "载具已上锁, 无法驾驶它进出车库." );

					SetPlayerVehicleInteriorData( iOwner, iSlot, g_garageInteriorData[ iInterior ] [ E_INTERIOR ], g_garageData[ g ] [ E_WORLD ], g_garageInteriorData[ iInterior ] [ E_X ], g_garageInteriorData[ iInterior ] [ E_Y ], g_garageInteriorData[ iInterior ] [ E_Z ] + 2.0, g_garageInteriorData[ iInterior ] [ E_ANGLE ], g );
				}
				else
				{
					pauseToLoad( playerid );
					SetPlayerPos( playerid, g_garageInteriorData[ iInterior ] [ E_X ], g_garageInteriorData[ iInterior ] [ E_Y ], g_garageInteriorData[ iInterior ] [ E_Z ] );
					SetPlayerInterior( playerid, g_garageInteriorData[ iInterior ] [ E_INTERIOR ] );
				  	SetPlayerVirtualWorld( playerid, g_garageData[ g ] [ E_WORLD ] );
				}
				return ( p_InGarage[ playerid ] = g ), 1;
			}
		}
		return SendError( playerid, "你不在任何车库入口附近." );
	}
	else if ( strmatch( params, "exit" ) )
	{
		if ( iGarage == -1 ) return SendError( playerid, "你不在任何车库里." );
		else
		{
			if ( iVehicle != 0 && iVehicleSeat == 0 )
			{
				new
					iSlot = getVehicleSlotFromID( iVehicle, iOwner );

				if ( g_vehicleData[ iOwner ] [ iSlot ] [ E_LOCKED ] && playerid != iOwner )
					return SendError( playerid, "载具已上锁, 无法驾驶它进出车库." );

				SetPlayerVehicleInteriorData( iOwner, iSlot, 0, 0, g_garageData[ iGarage ] [ E_X ], g_garageData[ iGarage ] [ E_Y ], g_garageData[ iGarage ] [ E_Z ], g_garageData[ iGarage ] [ E_ANGLE ] );
			}
			else
			{
				SetPlayerPosEx( playerid, g_garageData[ iGarage ] [ E_X ], g_garageData[ iGarage ] [ E_Y ], g_garageData[ iGarage ] [ E_Z ], 0 ), SetPlayerVirtualWorld( playerid, 0 );
			}
			return ( p_InGarage[ playerid ] = -1 ), 1;
		}
	}
	else if ( strmatch( params, "sell" ) )
	{
		if ( iGarage == -1 ) return SendError( playerid, "你不在任何车库里." );
		else if ( g_garageData[ iGarage ] [ E_OWNER_ID ] != p_AccountID[ playerid ] ) return SendError( playerid, "你不是这个车库的所有者." );
		else
		{
			new
				iCashMoney = floatround( ( g_garageData[ iGarage ] [ E_PRICE ] / 2 ) + ( g_garageInteriorData[ g_garageData[ iGarage ] [ E_INTERIOR_ID ] ] [ E_PRICE ] / 2 ) );

			if ( GetPlayerVehiclesInGarage( playerid, iGarage, .strict_mode = true ) )
				return SendError( playerid, "你必须确保在出售之前将所有车辆从设施中移走." );

			g_garageData[ iGarage ] [ E_OWNER_ID ] 		= 0;
			g_garageData[ iGarage ] [ E_INTERIOR_ID ] 	= 0;

			// UpdateGarageData( iGarage ); (add on resale)
			// OnUpdateGarageTitle( iGarage ); // No point querying (add on resale)
			GivePlayerCash( playerid, iCashMoney );

			SetPlayerPosEx( playerid, g_garageData[ iGarage ] [ E_X ], g_garageData[ iGarage ] [ E_Y ], g_garageData[ iGarage ] [ E_Z ], 0 ), SetPlayerVirtualWorld( playerid, 0 );
			SendServerMessage( playerid, "你已成功出售你的车库 "COL_GOLD"%s"COL_WHITE".", cash_format( iCashMoney ) );

			// Destroy garage, prevent resale
			DestroyGarage( iGarage );
		}
		return 1;
	}
	else if ( !strcmp( params, "vehicle", false, 7 ) )
	{
	    new
	    	ownerid = INVALID_PLAYER_ID,
	    	vehicleid = getVehicleSlotFromID( GetPlayerVehicleID( playerid ), ownerid )
		;

		if ( iGarage == -1 )
			return SendError( playerid, "你不在任何车库里." );

		if ( g_garageData[ iGarage ] [ E_OWNER_ID ] != p_AccountID[ playerid ] )
			return SendError( playerid, "你不是这个车库的所有者." );

		if ( !IsPlayerInAnyVehicle( playerid ) )
			return SendError( playerid, "你需要在车辆中才能使用此命令." );

		if ( GetPlayerState( playerid ) != PLAYER_STATE_DRIVER )
			return SendError( playerid, "你需要成为驾驶员才能使用此命令." );

		if ( vehicleid == -1 )
			return SendError( playerid, "这辆车不是可购买的车辆." );

		if ( playerid != ownerid )
			return SendError( playerid, "这辆车不属于你." );

		if ( !strlen( params[ 8 ] ) )
			return SendUsage( playerid, "/garage vehicle [PIMP/EDIT]" );

		if ( strmatch( params[ 8 ], "pimp" ) )
		{
			if ( GetVehicleCustomComponents( ownerid, vehicleid ) >= GetPlayerPimpVehicleSlots( ownerid ) )
				return SendError( playerid, "你不能购买超过 %d 个车辆部件.", GetPlayerPimpVehicleSlots( ownerid ) );

			return ShowVehicleComponentCategories( playerid );
		}
		else if ( strmatch( params[ 8 ], "edit" ) )
		{
			new
				count = 0;

			szBigString[ 0 ] = '\0';

			for( new i = 0; i < MAX_PIMPS; i++ ) if ( g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_CREATED ] [ i ] ) {
				for( new c = 0; c < sizeof( g_vehicleComponentsData ); c++ ) if ( g_vehicleComponentsData[ c ] [ E_MODEL_ID ] == g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_MODEL ] [ i ] )  {
					format( szBigString, sizeof( szBigString ), "%s%s\n", szBigString, g_vehicleComponentsData[ c ] [ E_NAME ] );
				}
				count ++;
			}

			if ( !count )
				return SendError( playerid, "该车辆没有任何组件." );

			return ShowPlayerDialog( playerid, DIALOG_COMPONENT_MENU, DIALOG_STYLE_LIST, "车辆零部件", szBigString, "选择", "取消" );
		}
		else return SendUsage( playerid, "/garage vehicle [PIMP/EDIT]" );
	}
	return SendUsage( playerid, "/garage [BUY/UPGRADE/VEHICLE/ENTER/EXIT/SELL]" );
}

/* ** SQL Threads ** */
thread OnGaragesLoad( )
{
	new
		rows, fields, i = -1,
	    loadingTick = GetTickCount( )
	;

	cache_get_data( rows, fields );
	if ( rows )
	{
		while( ++i < rows )
		{
			CreateGarage(
				cache_get_field_content_int( i, "OWNER", dbHandle ),
				cache_get_field_content_int( i, "PRICE", dbHandle ),
				cache_get_field_content_int( i, "INTERIOR", dbHandle ),
				cache_get_field_content_float( i, "X", dbHandle ),
				cache_get_field_content_float( i, "Y", dbHandle ),
				cache_get_field_content_float( i, "Z", dbHandle ),
				cache_get_field_content_float( i, "ANGLE", dbHandle ),
				cache_get_field_content_int( i, "ID", dbHandle )
			);
		}
	}
	printf( "[GARAGES]: %d garages have been loaded. (Tick: %dms)", i, GetTickCount( ) - loadingTick );
	return 1;
}

thread OnUpdateGarageTitle( slot )
{
	new
		rows, szOwner[ MAX_PLAYER_NAME ] = "无人";

	cache_get_data( rows, tmpVariable );

	if ( rows )
		cache_get_field_content( 0, "NAME", szOwner );

	UpdateDynamic3DTextLabelText( g_garageData[ slot ] [ E_LABEL ], COLOR_GOLD, sprintf( "车库(%d)\n所有者:"COL_WHITE" %s\n"COL_GOLD"价格:"COL_WHITE" %s", slot, szOwner, cash_format( g_garageData[ slot ] [ E_PRICE ] ) ) );
	return 1;
}

/* ** Functions ** */
stock CreateGarage( iAccountID, iPrice, iInterior, Float: fX, Float: fY, Float: fZ, Float: fAngle, iExistingID = ITER_NONE )
{
	new
		iGarage = iExistingID != ITER_NONE ? iExistingID : Iter_Free(garages);

	if ( Iter_Contains( garages, iExistingID ) )
		iGarage = ITER_NONE; // In the unlikelihood...

	if ( iGarage != ITER_NONE )
	{
		g_garageData[ iGarage ] [ E_OWNER_ID ] 		= iAccountID;
		g_garageData[ iGarage ] [ E_PRICE ] 		= iPrice;
		g_garageData[ iGarage ] [ E_INTERIOR_ID ] 	= iInterior;
		g_garageData[ iGarage ] [ E_WORLD ] 		= iGarage + ( MAX_GARAGES * 32 ); // Random

		g_garageData[ iGarage ] [ E_X ] 	= fX;
		g_garageData[ iGarage ] [ E_Y ] 	= fY;
		g_garageData[ iGarage ] [ E_Z ] 	= fZ;
		g_garageData[ iGarage ] [ E_ANGLE ] = fAngle;

		g_garageData[ iGarage ] [ E_CHECKPOINT ] = CreateDynamicCP( fX, fY, fZ, 3.0, -1, 0, -1, 100.0 );
	    g_garageData[ iGarage ] [ E_LABEL ] 	 = CreateDynamic3DTextLabel( sprintf( "车库(%d)\n所有者:"COL_WHITE" 无人\n"COL_GOLD"价格:"COL_WHITE" %s", iGarage, cash_format( g_garageData[ iGarage ] [ E_PRICE ] ) ), COLOR_GOLD, fX, fY, fZ, 20.0 );

		if ( iExistingID != ITER_NONE && iAccountID ) UpdateGarageTitle( iGarage );
		else if ( iExistingID == ITER_NONE )
		{
			format( szBigString, 162, "INSERT INTO `GARAGES`(`ID`,`OWNER`,`PRICE`,`INTERIOR`,`X`,`Y`,`Z`,`ANGLE`) VALUES (%d,%d,%d,%d,%f,%f,%f,%f)", iGarage, iAccountID, iPrice, iInterior, fX, fY, fZ, fAngle );
			mysql_single_query( szBigString );
		}

		Iter_Add(garages, iGarage);
	}
	return iGarage;
}

stock DestroyGarage( iGarage )
{
	if ( iGarage < 0 || iGarage >= MAX_GARAGES )
		return 0;

	if ( !Iter_Contains( garages, iGarage ) )
	    return 0;

	new
		playerid = GetPlayerIDFromAccountID( g_garageData[ iGarage ] [ E_OWNER_ID ] );

	if ( IsPlayerConnected( playerid ) )
	{
		for( new i = 0; i < MAX_BUYABLE_VEHICLES; i++ )
			if ( g_vehicleData[ playerid ] [ i ] [ E_CREATED ] && g_vehicleData[ playerid ] [ i ] [ E_GARAGE ] == iGarage )
				SetVehiclePos( g_vehicleData[ playerid ] [ i ] [ E_VEHICLE_ID ], g_garageData[ iGarage ] [ E_X ], g_garageData[ iGarage ] [ E_Y ], g_garageData[ iGarage ] [ E_Z ] ), LinkVehicleToInterior( g_vehicleData[ playerid ] [ i ] [ E_VEHICLE_ID ], 0 ), SetVehicleVirtualWorld( g_vehicleData[ playerid ] [ i ] [ E_VEHICLE_ID ], 0 );

	    SendClientMessage( playerid, -1, ""COL_PINK"[车库]"COL_WHITE" 你的车库之一已被摧毁.");
	}

	mysql_single_query( sprintf( "UPDATE `VEHICLES` SET `X`=%f,`Y`=%f,`Z`=%f,`GARAGE`=-1 WHERE `GARAGE`=%d", g_garageData[ iGarage ] [ E_X ], g_garageData[ iGarage ] [ E_Y ], g_garageData[ iGarage ] [ E_Z ], iGarage ) );
	mysql_single_query( sprintf( "DELETE FROM `GARAGES` WHERE `ID`=%d", iGarage ) );

	Iter_Remove(garages, iGarage);
	g_garageData[ iGarage ] [ E_OWNER_ID ] = 0;
	DestroyDynamicCP( g_garageData[ iGarage ] [ E_CHECKPOINT ] );
	DestroyDynamic3DTextLabel( g_garageData[ iGarage ] [ E_LABEL ] );
	return 1;
}

stock PlayerBreachedGarageLimit( playerid, vID, bool: admin_place = false )
{
	new
		iOwner = playerid;

	if ( admin_place ) /// Admin Mode
 		getVehicleSlotFromID( GetPlayerVehicleID( playerid ), iOwner );

	// Garage System
	if ( ( g_vehicleData[ iOwner ] [ vID ] [ E_GARAGE ] = p_InGarage[ playerid ] ) != -1 )
	{
		new
			iGarage = g_vehicleData[ iOwner ] [ vID ] [ E_GARAGE ],
			iVehiclesOccupying = GetPlayerVehiclesInGarage( iOwner, iGarage )
		;

		if ( g_vehicleData[ iOwner ] [ vID ] [ E_OWNER_ID ] != g_garageData[ iGarage ] [ E_OWNER_ID ] )
			return g_vehicleData[ iOwner ] [ vID ] [ E_GARAGE ] = -1, -1;

		if ( iVehiclesOccupying > g_garageInteriorData[ g_garageData[ iGarage ] [ E_INTERIOR_ID ] ] [ E_VEHICLE_CAPACITY ] )
			return g_vehicleData[ iOwner ] [ vID ] [ E_GARAGE ] = -1, -2;
	}
	return 1;
}

stock GetPlayerOwnedGarages( playerid ) {
	new
		count = 0;

	foreach ( new garageid : garages ) if ( g_garageData[ garageid ] [ E_OWNER_ID ] == p_AccountID[ playerid ] ) {
		count ++;
	}
	return count;
}

stock GetPlayerVehiclesInGarage( playerid, slot, strict_mode=0 )
{
	new
		count = 0;

	if ( Iter_Contains( garages, slot ) )
	{
		for( new i = 0; i < MAX_BUYABLE_VEHICLES; i++ ) if ( g_vehicleData[ playerid ] [ i ] [ E_CREATED ] ) {
			if ( g_vehicleData[ playerid ] [ i ] [ E_GARAGE ] == slot || ( strict_mode && GetVehicleVirtualWorld( g_vehicleData[ playerid ] [ i ] [ E_VEHICLE_ID ] ) == g_garageData[ slot ] [ E_WORLD ] ) )
				count++;
		}
	}
	return count;
}

stock ArePlayersInGarage( playerid, slot )
{
	foreach ( new i : Player ) {
		if ( p_InGarage[ i ] == slot && i != playerid ) {
			return true;
		}
	}
	return false;
}

stock UpdatePlayerGarageTitles( playerid )
{
    foreach ( new g : garages ) if ( g_garageData[ g ] [ E_OWNER_ID ] == GetPlayerAccountID( playerid ) ) {
		UpdateGarageTitle( g );
    }
	return 1;
}

stock GetGarageVehicleCapacity( garageid ) {
	return g_garageInteriorData[ g_garageData[ garageid ] [ E_INTERIOR_ID ] ] [ E_VEHICLE_CAPACITY ];
}

stock GetGarageInteriorID( garageid ) {
	return g_garageInteriorData[ g_garageData[ garageid ] [ E_INTERIOR_ID ] ] [ E_INTERIOR ];
}

stock GetGarageVirtualWorld( garageid ) {
	return g_garageData[ garageid ] [ E_WORLD ];
}

stock GetGaragePos( garageid, &Float: X, &Float: Y, &Float: Z ) {
	X = g_garageData[ garageid ] [ E_X ];
	Y = g_garageData[ garageid ] [ E_Y ];
	Z = g_garageData[ garageid ] [ E_Z ];
}

stock IsPlayerInGarage( playerid ) {
	return p_InGarage[ playerid ] != -1;
}