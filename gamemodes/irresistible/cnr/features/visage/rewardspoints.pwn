/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\visage\rewardspoints.pwn
 * Purpose: rewards points system for gambling
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define CASINO_REWARDS_PAYOUT_PERCENT	20.0
#define CASINO_REWARDS_DIVISOR 			10.0 	// 1000 points becomes 1 point
#define CASINO_REWARDS_COST_MP 			1.0 	// half of the price (since it costs (1/payout_percent) times more)

#define CASINO_POINTS_SELL_MINIMUM 		10000
#define CASINO_POINTS_SELL_VALUE		10.0

/* ** Variables ** */
enum E_REWARDS_DATA
{
	E_NAME[ 32 ], 		Float: E_POINTS
};

static stock
	g_casinoRewardsItems[ ] [ E_REWARDS_DATA ] = {
		{ "10 爆炸子弹", 12500.0 },
		{ "豪赌者访问", 200000.0 }
	},
	E_SHOP_ITEMS: g_casinoRewardsShopItems[ ] = {
		SHOP_ITEM_SCISSOR,
		SHOP_ITEM_ROPES,
		SHOP_ITEM_FOIL,
		SHOP_ITEM_BOBBY_PIN,
		SHOP_ITEM_MONEY_CASE,
		SHOP_ITEM_DRILL,
		SHOP_ITEM_METAL_MELTER,
		SHOP_ITEM_WEED_SEED,
		SHOP_ITEM_FIREWORKS
	},
	Float: p_CasinoRewardsPoints 		[ MAX_PLAYERS ],
	bool: p_IsCasinoHighRoller 			[ MAX_PLAYERS char ],
	Text3D: p_RewardsLabel_4Drags		[ MAX_PLAYERS ] = { Text3D: INVALID_3DTEXT_ID, ... },
	Text3D: p_RewardsLabel_Caligs		[ MAX_PLAYERS ] = { Text3D: INVALID_3DTEXT_ID, ... },
	Text3D: p_RewardsLabel_Visage		[ MAX_PLAYERS ] = { Text3D: INVALID_3DTEXT_ID, ... },
	p_HighrollersBarrier 				[ MAX_PLAYERS ] [ 2 ]
;

/* ** Hooks ** */
hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_CASINO_REWARDS && response )
	{
	    if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "在监狱中无法使用此功能." );

	    if ( listitem >= sizeof( g_casinoRewardsShopItems ) )
	    {
	    	new rewards_item = listitem - sizeof( g_casinoRewardsShopItems );

			if ( rewards_item >= sizeof( g_casinoRewardsItems ) ) {
				return ShowPlayerSellMenu( playerid );
			}

	    	new Float: rewards_points = g_casinoRewardsItems[ rewards_item ] [ E_POINTS ];

    		if ( p_CasinoRewardsPoints[ playerid ] < rewards_points )
                return SendError( playerid, "你需要 %s 奖励积分才能购买该物品.", points_format( rewards_points ) );

    		switch ( rewards_item )
    		{
    			case 0:
    			{
					if ( p_ExplosiveBullets[ playerid ] >= MAX_EXPLOSIVE_ROUNDS )
						return SendError( playerid, "你最多只能购买 %d 轮.", MAX_EXPLOSIVE_ROUNDS );

    				p_ExplosiveBullets[ playerid ] += 10;
                    ShowPlayerHelpDialog( playerid, 3000, "按 ~r~~k~~CONVERSATION_NO~~w~ 激活爆炸子弹." );
    			}
    			case 1: // highroller
    			{
                    if ( p_IsCasinoHighRoller{ playerid } ) return SendError( playerid, "你已经被视为赌场豪客." );
					mysql_single_query( sprintf( "UPDATE `USERS` SET `VISAGE_HIGHROLLER`=1 WHERE `ID`=%d", p_AccountID[ playerid ] ) );
					DestroyDynamicObject( p_HighrollersBarrier[ playerid ] [ 0 ] ), p_HighrollersBarrier[ playerid ] [ 0 ] = -1;
					DestroyDynamicObject( p_HighrollersBarrier[ playerid ] [ 1 ] ), p_HighrollersBarrier[ playerid ] [ 1 ] = -1;
    				p_IsCasinoHighRoller{ playerid } = true;
    			}
    		}

    		p_CasinoRewardsPoints[ playerid ] -= rewards_points;
			mysql_single_query( sprintf( "UPDATE `USERS` SET `CASINO_REWARDS` = %f WHERE `ID`=%d", p_CasinoRewardsPoints[ playerid ], p_AccountID[ playerid ] ) );
			SendServerMessage( playerid, "你已经买了 "COL_GREY"%s"COL_WHITE", 获得"COL_GOLD"%s"COL_WHITE" 奖励积分.", g_casinoRewardsItems[ rewards_item ] [ E_NAME ], points_format( rewards_points ) );
    		return ShowPlayerRewardsMenu( playerid );
	    }
	    else
	    {
		    for ( new i = 0, x = 0; i < sizeof ( g_shopItemData ); i ++ ) if ( IsCasinoRewardsShopItem( g_shopItemData[ i ] [ E_ID ] ) )
		    {
		    	if ( x == listitem )
		    	{
		    		new Float: rewards_cost = ( float( g_shopItemData[ i ] [ E_PRICE ] ) * CASINO_REWARDS_COST_MP ) / CASINO_REWARDS_DIVISOR;

		    		if ( p_CasinoRewardsPoints[ playerid ] < rewards_cost )
                        return SendError( playerid, "你需要 %s 奖励积分才能购买该物品.", points_format( rewards_cost ) );

		    		// shop limits
		    		if ( g_shopItemData[ i ] [ E_LIMIT ] == 1 )
		    		{
		    			if ( g_shopItemData[ i ] [ E_ID ] == SHOP_ITEM_DRILL ) {
                            if ( p_drillStrength[ playerid ] == MAX_DRILL_STRENGTH ) return SendError( playerid, "你已经购买了该物品." );
		        			p_drillStrength[ playerid ] = MAX_DRILL_STRENGTH;
		    			} else if ( g_shopItemData[ i ] [ E_ID ] == SHOP_ITEM_MONEY_CASE ) {
                            if ( p_MoneyBag{ playerid } == true ) return SendError( playerid, "你已经购买了该物品." );
							if ( p_Class[ playerid ] != CLASS_POLICE ) SetPlayerAttachedObject( playerid, 1, 1210, 7, 0.302650, -0.002469, -0.193321, 296.124053, 270.396881, 8.941717, 1.000000, 1.000000, 1.000000 );
		        			p_MoneyBag{ playerid } = true;
	        			}
		    		}
		    		else
		    		{
		    			new iCurrentQuantity = GetShopItemAmount( playerid, i );
			    		new iLimit = g_shopItemData[ i ] [ E_LIMIT ] + ( 2 * p_VIPLevel[ playerid ] );

			    		if ( iCurrentQuantity >= iLimit )
                            return SendError( playerid, "你无法用你的奖励积分购买更多该物品." );

		    			SetPlayerShopItemAmount( playerid, i, iCurrentQuantity + 1 );
		    		}

		    		// deduct points
					p_CasinoRewardsPoints[ playerid ] -= rewards_cost;
					mysql_single_query( sprintf( "UPDATE `USERS` SET `CASINO_REWARDS` = %f WHERE `ID`=%d", p_CasinoRewardsPoints[ playerid ], p_AccountID[ playerid ] ) );
					SendServerMessage( playerid, "你已经购买了1x "COL_GREY"%s"COL_WHITE", 获得"COL_GOLD"%s"COL_WHITE" 奖励积分.", g_shopItemData[ i ] [ E_NAME ], points_format( rewards_cost ) );
		    		return ShowPlayerRewardsMenu( playerid );
		    	}
		    	x ++;
		    }
	    }
	    return 1;
	}
	else if ( dialogid == DIALOG_CASINO_BAR && response )
	{
		if ( p_CasinoRewardsPoints[ playerid ] < 20.0 ) return SendError( playerid, "你需要 20.0 赌场奖励积分才能从赌场酒吧购买物品." );

		// what did they buy
		switch ( listitem )
		{
			case 0: SetPlayerSpecialAction( playerid, 20 ), SendServerMessage( playerid, "你买了一瓶啤酒 "COL_GOLD"20.0 赌场奖励积分"COL_WHITE"." );
			case 1: SetPlayerSpecialAction( playerid, 21 ), SendServerMessage( playerid, "你买了一支雪茄 "COL_GOLD"20.0 赌场奖励积分"COL_WHITE"." );
			case 2: SetPlayerSpecialAction( playerid, 22 ), SendServerMessage( playerid, "你买了酒 "COL_GOLD"20.0 赌场奖励积分"COL_WHITE"." );
		}

		// update account
		p_CasinoRewardsPoints[ playerid ] -= 20.0;
		mysql_single_query( sprintf( "UPDATE `USERS` SET `CASINO_REWARDS` = %f WHERE `ID`=%d", p_CasinoRewardsPoints[ playerid ], p_AccountID[ playerid ] ) );
		return 1;
	}
	else if ( dialogid == DIALOG_CASINO_POINTS_MARKET )
	{
		if ( ! response ) {
			return ShowPlayerRewardsMenu( playerid );
		}

		new total_points = floatround( p_CasinoRewardsPoints[ playerid ], floatround_floor );
		new sell_amount = strval( inputtext );

		if ( sell_amount < CASINO_POINTS_SELL_MINIMUM )
		{
			SendError( playerid, "你可以出售的赌场积分的最低金额为 %s.", number_format( CASINO_POINTS_SELL_MINIMUM ) );
			return ShowPlayerSellMenu( playerid );
		}
		else if ( sell_amount > total_points )
		{
			SendError( playerid, "你没有这么多赌场积分." );
			return ShowPlayerSellMenu( playerid );
		}
		else
		{
			new
				credit = floatround( float( sell_amount ) * CASINO_POINTS_SELL_VALUE, floatround_floor );

			GivePlayerCash( playerid, credit );
			p_CasinoRewardsPoints[ playerid ] -= float( sell_amount );
			SendGlobalMessage( -1, ""COL_GREY"[赌场]{FFFFFF} %s(%d) 已售出 %s 赌场积分 "COL_GOLD"%s"COL_WHITE"!", ReturnPlayerName( playerid ), playerid, points_format( sell_amount ), cash_format( credit ) );
			mysql_single_query( sprintf( "UPDATE `USERS` SET `CASINO_REWARDS` = %f WHERE `ID`=%d", p_CasinoRewardsPoints[ playerid ], p_AccountID[ playerid ] ) );
		}
		return 1;
	}
	return 1;
}

hook OnPlayerUpdateEx( playerid )
{
	if ( ! IsPlayerSpawned( playerid ) )
		return 1;

	// Update casino labels
	UpdateDynamic3DTextLabelText( p_RewardsLabel_Caligs[ playerid ], COLOR_GOLD, sprintf( "[赌场奖励]\n\n"COL_WHITE"你有 %s 奖励积分!", points_format( p_CasinoRewardsPoints[ playerid ] ) ) );
	UpdateDynamic3DTextLabelText( p_RewardsLabel_4Drags[ playerid ], COLOR_GOLD, sprintf( "[赌场奖励]\n\n"COL_WHITE"你有 %s 奖励积分!", points_format( p_CasinoRewardsPoints[ playerid ] ) ) );
	UpdateDynamic3DTextLabelText( p_RewardsLabel_Visage[ playerid ], COLOR_GOLD, sprintf( "[赌场奖励]\n\n"COL_WHITE"你有 %s 奖励积分!", points_format( p_CasinoRewardsPoints[ playerid ] ) ) );

 	// Remove invalid visage highrollers
 	if ( ! p_IsCasinoHighRoller{ playerid } && IsPlayerInHighRoller( playerid ) ) {
 		SetPlayerPos( playerid, 2597.8943, 1603.1852, 1506.1733 );
        SendError( playerid, "你需要成为豪赌者才能进入该区域.通过赌场奖励获得访问权限." );
 	}
	return 1;
}

hook OnPlayerConnect( playerid )
{
	// Create casino label
	DestroyDynamic3DTextLabel( p_RewardsLabel_Caligs[ playerid ] );
	DestroyDynamic3DTextLabel( p_RewardsLabel_4Drags[ playerid ] );
	DestroyDynamic3DTextLabel( p_RewardsLabel_Visage[ playerid ] );
	p_RewardsLabel_Caligs[ playerid ] = CreateDynamic3DTextLabel( "[赌场奖励]", COLOR_GOLD, 2157.6294, 1599.4355, 1006.1797, 20.0, .playerid = playerid );
	p_RewardsLabel_4Drags[ playerid ] = CreateDynamic3DTextLabel( "[赌场奖励]", COLOR_GOLD, 1951.7191, 997.55550, 992.85940, 20.0, .playerid = playerid );
	p_RewardsLabel_Visage[ playerid ] = CreateDynamic3DTextLabel( "[赌场奖励]", COLOR_GOLD, 2604.1323, 1570.1182, 1508.3530, 20.0, .playerid = playerid );

	// Create highroller objects
	p_HighrollersBarrier[ playerid ] [ 0 ] = CreateDynamicObject( 19545, 2592.604980, 1610.016967, 1499.139038, 90.000000, 90.000000, 0.000000, .worldid = VISAGE_WORLD, .playerid = playerid );
	p_HighrollersBarrier[ playerid ] [ 1 ] = CreateDynamicObject( 19545, 2592.604003, 1595.026000, 1499.140991, 90.000000, 90.000000, 0.000000, .worldid = VISAGE_WORLD, .playerid = playerid );
	SetDynamicObjectMaterial( p_HighrollersBarrier[ playerid ] [ 0 ], 0, 11751, "enexmarkers", "enex", -9170 );
	SetDynamicObjectMaterial( p_HighrollersBarrier[ playerid ] [ 1 ], 0, 11751, "enexmarkers", "enex", -9170 );
	return 1;
}

hook OnPlayerDisconnect( playerid, reason )
{
	p_IsCasinoHighRoller{ playerid } = false;
	p_CasinoRewardsPoints[ playerid ] = 0.0;
	DestroyDynamicObject( p_HighrollersBarrier[ playerid ] [ 0 ] ), p_HighrollersBarrier[ playerid ] [ 0 ] = -1;
	DestroyDynamicObject( p_HighrollersBarrier[ playerid ] [ 1 ] ), p_HighrollersBarrier[ playerid ] [ 1 ] = -1;
	return 1;
}

hook OnPlayerLogin( playerid )
{
	if ( p_IsCasinoHighRoller{ playerid } ) {
		DestroyDynamicObject( p_HighrollersBarrier[ playerid ] [ 0 ] ), p_HighrollersBarrier[ playerid ] [ 0 ] = -1;
		DestroyDynamicObject( p_HighrollersBarrier[ playerid ] [ 1 ] ), p_HighrollersBarrier[ playerid ] [ 1 ] = -1;
	}
	return 1;
}

/* ** Commands ** */
CMD:casino( playerid, params[ ] )
{
	if ( strmatch( params, "rewards" ) ) {
		if ( ! IsPlayerInCasino( playerid ) ) return SendError( playerid, "你需要在赌场才能使用此功能." );
		return ShowPlayerRewardsMenu( playerid );
	} else if ( strmatch( params, "points" ) ) {
		return SendServerMessage( playerid, "你目前有 "COL_GOLD"%s"COL_WHITE" 赌场奖励积分.", points_format( p_CasinoRewardsPoints[ playerid ] ) );
	}
	return SendUsage( playerid, "/casino [REWARDS/POINTS]" );
}

/* ** Functions ** */
stock GivePlayerCasinoRewardsPoints( playerid, bet_amount, Float: house_edge ) {
	if ( bet_amount < 0 ) bet_amount *= -1; // profit or loss, does not matter
	// printf("(%f * ((%f * 100.0) * (%f / 100.0))) / %f\n",bet_amount, house_edge,  CASINO_REWARDS_PAYOUT_PERCENT, CASINO_REWARDS_DIVISOR);
	new Float: final_points = ( bet_amount * ( ( house_edge / 100.0 ) * ( CASINO_REWARDS_PAYOUT_PERCENT / 100.0 ) ) ) / CASINO_REWARDS_DIVISOR;
	p_CasinoRewardsPoints[ playerid ] += final_points;
	mysql_single_query( sprintf( "UPDATE `USERS` SET `CASINO_REWARDS`=%f WHERE `ID`=%d", p_CasinoRewardsPoints[ playerid ], p_AccountID[ playerid ] ) );
	return 1;
}

stock ShowPlayerRewardsMenu( playerid )
{
	static szString[ 800 ];

	if ( szString[ 0 ] == '\0' )
	{
		strcat( szString, ""COL_WHITE"物品\t"COL_WHITE"目的\t"COL_WHITE"奖励积分\n" );
		for( new i; i < sizeof( g_shopItemData ); i++ ) if ( IsCasinoRewardsShopItem( g_shopItemData[ i ] [ E_ID ] ) ) {
			new Float: rewards_cost = ( float( g_shopItemData[ i ] [ E_PRICE ] ) * CASINO_REWARDS_COST_MP ) / CASINO_REWARDS_DIVISOR;
            format( szString, sizeof( szString ), "%s%s\t"COL_GREY"%s\t"COL_GOLD"%s 点 \n", szString, g_shopItemData[ i ] [ E_NAME ], g_shopItemData[ i ] [ E_USAGE ], points_format( rewards_cost ) );
		}
		for ( new i = 0; i < sizeof( g_casinoRewardsItems ); i ++ ) {
            format( szString, sizeof( szString ), "%s%s\t \t"COL_GOLD"%s 点 \n", szString, g_casinoRewardsItems[ i ] [ E_NAME ], points_format( g_casinoRewardsItems[ i ] [ E_POINTS ] ) );
		}
		strcat( szString, ""COL_GREEN"出售你的积分\t \t"COL_GREEN">>>" );
	}
	return ShowPlayerDialog( playerid, DIALOG_CASINO_REWARDS, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}赌场奖励物品", szString, "买", "取消" );
}

stock ShowPlayerSellMenu( playerid )
{
	new value = floatround( p_CasinoRewardsPoints[ playerid ] * CASINO_POINTS_SELL_VALUE );

	format( szBigString, sizeof( szBigString ),
		""COL_WHITE"请输入你想出售多少赌场积分.\n\n"\
		"汇率为 "COL_GOLD"1 "COL_WHITE"赌场积分 "COL_GOLD"%s\n\n"\
		""COL_WHITE"你已"COL_GOLD"%s "COL_WHITE"可以出售的赌场积分 "COL_GOLD"%s",
		cash_format( CASINO_POINTS_SELL_VALUE, .decimals = 0 ),
		points_format( p_CasinoRewardsPoints[ playerid ] ),
		cash_format( value, .decimals = 0 )
	);

	return ShowPlayerDialog( playerid, DIALOG_CASINO_POINTS_MARKET, DIALOG_STYLE_INPUT, "{FFFFFF}赌场积分市场", szBigString, "出售", "返回" );
}

stock IsCasinoRewardsShopItem( E_SHOP_ITEMS: itemid ) {
	for ( new i = 0; i < sizeof( g_casinoRewardsShopItems ); i ++ ) if ( itemid == g_casinoRewardsShopItems[ i ] ) {
		return true;
	}
	return false;
}

stock Float: GetPlayerCasinoRewardsPoints( playerid ) {
	return p_CasinoRewardsPoints[ playerid ];
}

stock SetPlayerCasinoRewardsPoints( playerid, Float: rewards ) {
	p_CasinoRewardsPoints[ playerid ] = rewards;
}

stock SetPlayerCasinoHighroller( playerid, bool: toggle ) {
	p_IsCasinoHighRoller{ playerid } = toggle;
}
