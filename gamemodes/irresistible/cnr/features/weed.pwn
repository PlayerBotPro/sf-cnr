/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\weed.pwn
 * Purpose: weed growing system
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_WEED                    ( 64 )
#define MAX_WEED_STORAGE 			( 25 )

#define WEED_REQUIRED_GROW_TIME 	( 600 )

/* ** Variables ** */
enum E_WEED_DATA
{
	E_OBJECT,       	Text3D: E_LABEL,		E_GROW_TIME,
	E_USER_ID,			E_MAP_ICON,

	Float: E_X,         Float: E_Y,     		Float: E_Z
};

static stock
	g_weedData                      [ MAX_WEED ] [ E_WEED_DATA ],
	Iterator: weedplants 			< MAX_WEED >
;

/* ** Hooks ** */
hook OnServerUpdate( )
{
	new
		server_time = GetServerTime( );

	foreach ( new weedid : weedplants ) if ( g_weedData[ weedid ] [ E_GROW_TIME ] != 0 )
	{
		if ( g_weedData[ weedid ] [ E_GROW_TIME ] > server_time )
		{
			new
				Float: percentage = 100.0 - ( float( g_weedData[ weedid ] [ E_GROW_TIME ] - server_time ) / float( WEED_REQUIRED_GROW_TIME ) ) * 100.0;

			UpdateDynamic3DTextLabelText( g_weedData[ weedid ] [ E_LABEL ], COLOR_GREEN, sprintf( "%s 的 大麻 植物\n"COL_WHITE"%0.1f%% 长大了", ReturnPlayerName( g_weedData[ weedid ] [ E_USER_ID ] ), percentage ) );
		}
		else
		{
			new
				growerid = g_weedData[ weedid ] [ E_USER_ID ];

			if ( IsPlayerConnected( growerid ) ) {
				SendServerMessage( growerid, "你的一株大麻植物已经完成生长!" );
			}

			UpdateDynamic3DTextLabelText( g_weedData[ weedid ] [ E_LABEL ], COLOR_GREEN, sprintf( "%s 的 大麻 植物\n"COL_GREY"按左 ALT 键采摘", ReturnPlayerName( g_weedData[ weedid ] [ E_USER_ID ] ) ) );
			g_weedData[ weedid ] [ E_GROW_TIME ] = 0;
		}
	}
	return 1;
}

hook OnPlayerDisconnect( playerid, reason )
{
	Weed_RemovePlayerPlants( playerid );
	Weed_ResetSellingProperties( playerid );
	return 1;
}

hook OnPlayerKeyStateChange( playerid, newkeys, oldkeys )
{
	if ( PRESSED( KEY_WALK ) )
	{
		new
			player_class = GetPlayerClass( playerid );

		foreach ( new weedid : weedplants ) if ( IsPlayerInRangeOfPoint( playerid, 3.0, g_weedData[ weedid ] [ E_X ], g_weedData[ weedid ] [ E_Y ], g_weedData[ weedid ] [ E_Z ] ) )
		{
			if ( ! g_weedData[ weedid ] [ E_GROW_TIME ] )
			{
				if ( player_class != CLASS_POLICE )
				{
					if ( g_weedData[ weedid ] [ E_USER_ID ] != playerid )
					{
						SendServerMessage( g_weedData[ weedid ] [ E_USER_ID ], "%s(%d) 从你的植物中偷走了一克 大麻!", ReturnPlayerName( playerid ), playerid );
					}
					GivePlayerWantedLevel( playerid, 6 ); // give wanted level to police
				}

				p_WeedGrams[ playerid ] ++;
				SendServerMessage( playerid, "你已经收集了一克 "COL_GREEN"大麻"COL_WHITE"." );

				Weed_RemovePlant( weedid );
			}
			else if ( player_class == CLASS_POLICE )
			{
				new
					weed_seed_cost = GetShopItemCost( SHOP_ITEM_WEED_SEED );

				GivePlayerCash( playerid, weed_seed_cost );
				GivePlayerExperience( playerid, E_POLICE, 0.5 );
				SendServerMessage( playerid, "你已经摧毁了一个 "COL_GREEN"大麻"COL_WHITE" 植物 "COL_GOLD"%s"COL_WHITE".", cash_format( weed_seed_cost ) );

				Weed_RemovePlant( weedid );
			}
			break;
		}
		return 1;
	}
	return 1;
}

/* ** Commands ** */
CMD:weed( playerid, params[ ] )
{
	new
		Float: X, Float: Y, Float: Z;

	if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "你不是平民." );

	if ( IsPlayerTied( playerid ) || IsPlayerTazed( playerid ) || IsPlayerCuffed( playerid ) || IsPlayerJailed( playerid ) || IsPlayerInMinigame( playerid ) )
		return SendError( playerid, "你目前无法使用此命令." );

	#if defined __cloudy_event_system
	if ( IsPlayerInEvent( playerid ) && ! EventSettingAllow( EVENT_SETTING_WEED ) ) {
		return SendError( playerid, "参加活动时无法使用此命令." );
	}
	#endif

	if ( strmatch( params, "plant" ) )
	{
		if ( ! IsPlayerJob( playerid, JOB_DRUG_DEALER ) ) return SendError( playerid, "你不是毒贩." );
		//if ( p_WeedGrams[ playerid ] >= MAX_WEED_STORAGE ) return SendError( playerid, "You can only carry %d grams of weed.", MAX_WEED_STORAGE );
		if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "收集 大麻 时你不得在车内." );
		if ( GetPlayerVirtualWorld( playerid ) != 0 && GetPlayerInterior( playerid ) != 0 ) return SendError( playerid, "你不能在室内使用它." );
		if ( ! GetPlayerShopItemAmount( playerid, SHOP_ITEM_WEED_SEED ) ) return SendError( playerid, "你没有任何 大麻 种子可以种植." );

		new planted_weed = Weed_GetPlayerWeedPlants( playerid );
		new planted_weed_limit = Weed_GetPlantLimit( playerid );

		if ( planted_weed >= planted_weed_limit ) {
			return SendError( playerid, "你一次只能种植 %d 株植物.", planted_weed_limit );
		}

		GetPlayerPos( playerid, X, Y, Z );
		MapAndreas_FindZ_For2DCoord( X, Y, Z );

		foreach ( new weedid : weedplants ) {
			if ( IsPointToPoint( 2.0, g_weedData[ weedid ] [ E_X ], g_weedData[ weedid ] [ E_Y ], g_weedData[ weedid ] [ E_Z ], X, Y, Z ) ) {
				return SendError( playerid, "你不能将 大麻 植物种植得离一株植物太近." );
			}
		}

		if ( Weed_CreatePlant( playerid, X, Y, Z ) != ITER_NONE ) {
			GivePlayerWantedLevel( playerid, 2 );
			GivePlayerShopItem( playerid, SHOP_ITEM_WEED_SEED, -1 );
			return SendServerMessage( playerid, "你已经种植了大麻.需要 %s 才能成长.", secondstotime( WEED_REQUIRED_GROW_TIME ) );
		} else {
			return SendError( playerid, "你目前无法创建 大麻 植物,请稍后再试." );
		}
	}
	else if ( !strcmp( params, "sell", false, 4 ) )
	{
	    new pID, iAmount, iCost;

		if ( !IsPlayerJob( playerid, JOB_DRUG_DEALER ) ) return SendError( playerid, "你不是毒贩." );
	    else if ( p_SellingWeedTick[ playerid ] > g_iTime ) return SendError( playerid, "在再次出售 大麻 之前,你必须等待一分钟." );
		else if ( !p_WeedGrams[ playerid ] ) return SendError( playerid, "你没有带任何大麻." );
	    else if ( sscanf( params[ 5 ], "udd", pID, iAmount, iCost ) ) return SendUsage( playerid, "/weed sell [PLAYER_ID] [GRAMS] [PRICE]" );
	    else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "玩家 ID 无效." );
	    else if ( pID == playerid ) return SendError( playerid, "你不能出卖自己大麻." );
		else if ( p_Class[ pID ] != CLASS_CIVILIAN ) return SendError( playerid, "这个人不是平民." );
		else if ( iAmount > p_WeedGrams[ playerid ] ) return SendError( playerid, "你身上只有 %d 克 大麻.", p_WeedGrams[ playerid ] );
		else if ( iAmount < 1 || iAmount > 25 ) return SendError( playerid, "你只能向玩家出售 1 到 25 克的 大麻." );
		else if ( iCost <= 0 || iCost > 100000 ) return SendError( playerid, "价格必须介于 1 和 100000. 之间" );
	    else if ( GetDistanceBetweenPlayers( playerid, pID ) < 5.0 )
	    {
			if ( GetPlayerCash( pID ) < iCost ) return SendError( playerid, "这个人没有足够的钱." );

			p_WeedDealer[ pID ] = playerid;
			p_WeedTick[ pID ] = GetServerTime( ) + 120;
			p_WeedSellingGrams[ pID ] = iAmount;
			p_WeedSellingPrice[ pID ] = iCost;
			p_SellingWeedTick[ playerid ] = g_iTime + 60;
			SendClientMessageFormatted( pID, -1, ""COL_ORANGE"[毒品交易]{FFFFFF} %s(%d) 正在出卖你%d克大麻对于%s. "COL_ORANGE"/weed buy"COL_WHITE" 买.", ReturnPlayerName( playerid ), playerid, iAmount, cash_format( iCost ) );
			SendClientMessageFormatted( playerid, -1, ""COL_ORANGE"[毒品交易]{FFFFFF} 你已向 %s(%d) 发送了购买 %d 克 大麻 的报价,价格为 "COL_GOLD"%s.", ReturnPlayerName( pID ), pID, iAmount, cash_format( iCost ) );
	 		return 1;
	    }
	    else
	    {
            return SendError( playerid, "该玩家不在附近." );
	    }
	}
	else if ( strmatch( params, "buy" ) )
	{
	    if ( !IsPlayerConnected( p_WeedDealer[ playerid ] ) ) return SendError( playerid, "你的经销商已不再连接." );
		else if ( GetServerTime( ) > p_WeedTick[ playerid ] ) return Weed_ResetSellingProperties( playerid ), SendError( playerid, "此交易已结束,每笔交易最多持续 2 分钟.你迟到了." );
		else
		{
		    new
		    	dealerid = p_WeedDealer[ playerid ],
		    	iGrams 	 = p_WeedSellingGrams[ playerid ],
		    	iCost 	 = p_WeedSellingPrice[ playerid ]
		    ;

			if ( GetPlayerCash( playerid ) < iCost ) return SendError( playerid, "你需要 %s 才能购买 %d 克 大麻.", cash_format( iCost ), iGrams );
			else if ( IsPlayerInPaintBall( dealerid ) || IsPlayerDueling( dealerid ) ) return SendError( playerid, "你的发牌员不能在竞技场发牌." );
			else if ( p_Class[ dealerid ] != CLASS_CIVILIAN ) return Weed_ResetSellingProperties( playerid ), SendError( playerid, "这笔交易已经结束,经销商不是平民." );
			else if ( !IsPlayerJob( dealerid, JOB_DRUG_DEALER ) ) return SendError( playerid, "你的毒贩不再贩毒." );
			else if ( !p_WeedGrams[ dealerid ] ) return Weed_ResetSellingProperties( playerid ),  SendError( playerid, "你的经销商没有更多的 大麻." );
			//else if ( ( p_WeedGrams[ playerid ] + iGrams ) > MAX_WEED_STORAGE ) return SendError( playerid, "You can only carry %d grams of weed.", MAX_WEED_STORAGE );
			else
			{
	         	p_WeedGrams[ playerid ] += iGrams;
	         	p_WeedGrams[ dealerid ] -= iGrams;

				GivePlayerCash( playerid, -iCost );
				GivePlayerCash( dealerid, iCost );

				SendClientMessageFormatted( dealerid, -1, ""COL_ORANGE"[毒品交易]{FFFFFF} %s(%d) 已购买%d克大麻离开你%s.", ReturnPlayerName( playerid ), playerid, iGrams, cash_format( iCost ) );
				SendClientMessageFormatted( playerid, -1, ""COL_ORANGE"[毒品交易]{FFFFFF} 你已购买 %d 克 大麻,价格为 %s.", iGrams, cash_format( iCost ) );

				GivePlayerWantedLevel( dealerid, 6 );
				GivePlayerWantedLevel( playerid, 6 );

				Beep( dealerid );
				Weed_ResetSellingProperties( playerid );
			}
		}
		return 1;
	}
	else if ( strmatch( params, "use" ) )
	{
        if ( GetPVarInt( playerid, "weed_timestamp" ) > g_iTime ) return SendError( playerid, "使用此命令之前,你必须等待至少 %d 秒.", GetPVarInt( playerid, "weed_timestamp" ) - g_iTime );
		if ( p_WeedGrams[ playerid ] < 1 ) return SendError( playerid, "你没有带任何大麻." );
		if ( p_Jailed{ playerid } == true ) return SendError( playerid, "你不能在监狱里使用这个." );
		if ( IsPlayerLoadingObjects( playerid ) ) return SendError( playerid, "你正处于对象加载状态,请稍候." );
		if ( IsPlayerAttachedObjectSlotUsed( playerid, 0 ) ) return SendError( playerid, "抢劫时无法使用此命令." );
		// if ( IsPlayerJob( playerid, JOB_DRUG_DEALER ) ) return SendError( playerid, "You cannot use your own products, they are for resale only!" );
		//if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You cannot use this command in a vehicle." );
	    //if ( GetPlayerState( playerid ) == PLAYER_STATE_ENTER_VEHICLE_DRIVER || GetPlayerState( playerid ) == PLAYER_STATE_ENTER_VEHICLE_PASSENGER ) return SendError( playerid, "You cannot use this command if you're entering a vehicle." );
	    //if ( GetPlayerState( playerid ) == PLAYER_STATE_EXIT_VEHICLE ) return SendError( playerid, "You cannot use this command if you're exiting a vehicle." );
		//if ( p_InAnimation{ playerid } || GetPlayerSpecialAction( playerid ) != SPECIAL_ACTION_NONE ) return SendError( playerid, "You cannot use this command since you're in animation." );
		SetPVarInt( playerid, "weed_timestamp", g_iTime + 120 );
		p_WeedGrams[ playerid ] --;
		SetPlayerHealth( playerid, 150 );
		SetPlayerDrunkLevel( playerid, 5000 );
		SendServerMessage( playerid, "你已经吸了一克大麻." );
		DestroyDynamic3DTextLabel( p_WeedLabel[ playerid ] );
	    p_WeedLabel[ playerid ] = CreateDynamic3DTextLabel( "最近很火爆W33D!", COLOR_GREEN, X, Y, Z + 1.0, 15, playerid );
		//ApplyAnimation( playerid, "GANGS", "smkcig_prtl", 4.1, 0, 1, 1, 0, 0, 1 );
		return 1;
	}
	else
	{
		return SendUsage( playerid, "/weed [PLANT/SELL/BUY/USE]" ), 1;
	}
}

/* ** Functions ** */
stock Weed_CreatePlant( playerid, Float: X, Float: Y, Float: Z, required_time = WEED_REQUIRED_GROW_TIME )
{
	new
		weedid = Iter_Free( weedplants );

	if ( weedid != ITER_NONE )
	{
		static const Float: WEED_LOWER_OFFSET = 1.50; // put it 1.5m into the ground
		static const Float: WEED_RAISE_OFFSET = 0.35; // then raise it 0.35m to grow

		g_weedData[ weedid ] [ E_LABEL ] = CreateDynamic3DTextLabel( sprintf( "%s 的 大麻 植物\n"COL_WHITE"生长进度 0.0%%", ReturnPlayerName( playerid ) ), COLOR_GREEN, X, Y, Z + 0.5, 30.0 );
		g_weedData[ weedid ] [ E_OBJECT ] = CreateDynamicObject( 19473, X, Y, Z - WEED_LOWER_OFFSET, 0.0, 0.0, 0.0 );
		g_weedData[ weedid ] [ E_MAP_ICON ] = CreateDynamicMapIcon( X, Y, Z, 0, COLOR_GREEN, -1, -1, -1, 250.0 );
		g_weedData[ weedid ] [ E_GROW_TIME ] = GetServerTime( ) + required_time;
		g_weedData[ weedid ] [ E_USER_ID ] = playerid;
		g_weedData[ weedid ] [ E_X ] = X;
		g_weedData[ weedid ] [ E_Y ] = Y;
		g_weedData[ weedid ] [ E_Z ] = Z;

		Streamer_Update( playerid );
		MoveDynamicObject( g_weedData[ weedid ] [ E_OBJECT ], X, Y, Z + WEED_RAISE_OFFSET, ( WEED_LOWER_OFFSET + WEED_RAISE_OFFSET ) / float( required_time ) );

		Iter_Add( weedplants, weedid );
	}
	return weedid;
}

stock Weed_RemovePlant( weedid )
{
	DestroyDynamicObject( g_weedData[ weedid ] [ E_OBJECT ] );
	g_weedData[ weedid ] [ E_OBJECT ] = INVALID_OBJECT_ID;

	DestroyDynamic3DTextLabel( g_weedData[ weedid ] [ E_LABEL ] );
	g_weedData[ weedid ] [ E_LABEL ] = Text3D: INVALID_3DTEXT_ID;

	DestroyDynamicMapIcon( g_weedData[ weedid ] [ E_MAP_ICON ] );
	g_weedData[ weedid ] [ E_MAP_ICON ] = -1;

	Iter_Remove( weedplants, weedid );
	return 1;
}

stock Weed_RemovePlayerPlants( playerid ) {
	for ( new weedid = 0; weedid < sizeof( g_weedData ); weedid ++ ) if ( g_weedData[ weedid ] [ E_USER_ID ] == playerid ) {
		Weed_RemovePlant( weedid );
	}
}

stock Weed_GetPlayerWeedPlants( playerid )
{
	new
		count = 0;

	foreach ( new weedid : weedplants ) if ( g_weedData[ weedid ] [ E_USER_ID ] == playerid ) {
		count ++;
	}
	return count;
}

stock Weed_GetPlantLimit( playerid )
{
	new
		vip_level = GetPlayerVIPLevel( playerid );

	if ( vip_level >= VIP_GOLD ) {
		return 15;
	}
	else if ( vip_level >= VIP_BRONZE ) {
		return 10;
	}
	else {
		return 5;
	}
}

stock Weed_ResetSellingProperties( playerid )
{
	p_WeedDealer[ playerid ] = INVALID_PLAYER_ID;
	p_WeedSellingGrams[ playerid ] = 0;
	p_WeedSellingPrice[ playerid ] = 0;
	return 1;
}