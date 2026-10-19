/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\vip\player_market.pwn
 * Purpose: a selling market for irresistible coins between players
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Error Checking ** */
#if !defined __cnr__irresistiblecoins
	#endinput
#endif

/* ** Definitions ** */
// #define DIALOG_IC_SELLORDERS		( 5921 )
// #define DIALOG_IC_BUY				( 5922 )

/* ** Variables ** */
static const
	p_PlayerMarket_SellOrders 		[ MAX_PLAYERS ] [ 50 ];


/* ** Hooks ** */
hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_IC_SELLORDERS && response )
	{
		for ( new i = 0, x = 0; i < sizeof ( p_PlayerMarket_SellOrders ); i ++ ) if ( p_PlayerMarket_SellOrders[ playerid ] [ i ] != -1 )
		{
			if ( x == listitem )
			{
				PlayerMarket_ShowSellOrder( playerid, p_PlayerMarket_SellOrders[ playerid ] [ i ] );
				break;
			}
			x ++;
		}
	}
	else if ( dialogid == DIALOG_IC_BUY )
	{
		if ( ! response ) {
			return ShowPlayerCoinSellOrders( playerid );
		}


		new sellorderid = GetPVarInt( playerid, "playermarket_sellorder" );
		new Float: purchase_amount;

		if ( strmatch( inputtext, "ALL" ) || strmatch( inputtext, "MAX" ) )
		{
			purchase_amount = float( GetPlayerCash( playerid ) ) / float( GetPVarInt( playerid, "playermarket_askprice" ) );

			if ( purchase_amount > GetPVarFloat( playerid, "playermarket_available" ) ) {
				purchase_amount = GetPVarFloat( playerid, "playermarket_available" );
			}
		}
		else if ( sscanf( inputtext, "f", purchase_amount ) )
		{
			return SendError( playerid, "请指定有效金额." ), PlayerMarket_ShowSellOrder( playerid, sellorderid ), 1;
		}

		if ( ! ( 0.5 <= purchase_amount <= 10000.0 ) )
		{
			return SendError( playerid, "请指定介于 0.5 和 10,000 IC 之间的金额." ), PlayerMarket_ShowSellOrder( playerid, sellorderid ), 1;
		}
		else
		{
			mysql_tquery( dbHandle, sprintf( "SELECT * FROM `IC_SELL_ORDERS` WHERE `ID` = %d", sellorderid ), "PlayerMarket_OnPurchaseOrder", "ddf", playerid, sellorderid, purchase_amount );
			return 1;
		}
	}
	return 1;
}

/* ** Commands ** */
hook cmd_ic( playerid, params[ ] )
{
	if ( ! IsPlayerSecurityVerified( playerid ) ) {
		return SendError( playerid, "使用此功能需要先验证账号. "COL_YELLOW"(输入 /verify)" ), Y_HOOKS_BREAK_RETURN_1;
	}

	if ( !strcmp( params, "sell", true, 4 ) )
	{
		new
			Float: quantity, price;

		if ( GetPlayerVIPLevel( playerid ) < VIP_BRONZE ) SendError( playerid, "你还不是青铜 VIP, 请前往以下地址开通: "COL_GREY"donate.sfcnr.com" );
		else if ( sscanf( params[ 5 ], "fd", quantity, price ) ) SendUsage( playerid, "/ic sell [COINS] [PRICE_PER_COIN]" );
		else if ( quantity < 1.0 ) SendError( playerid, "你可以出售的最低数量是 1.0 IC 代币." );
		else if ( quantity > GetPlayerIrresistibleCoins( playerid ) ) SendError( playerid, "你没有这么多IC 代币." );
		else if ( ! ( 1000 <= price <= 125000 )) SendError( playerid, "每枚硬币的售价必须介于 $1,000 和 $125,000 之间." );
		else
		{
			new
				Float: sell_volume = float( price ) * quantity;

			if ( ! ( 1000.0 <= sell_volume <= 2000000000.0 ) ) {
				return SendError( playerid, "每个订单的最大交易量为 $2,000,000,000." ); // prevent bugs
			}

			// insert into database
			mysql_format( dbHandle, szBigString, sizeof( szBigString ), "INSERT INTO IC_SELL_ORDERS (USER_ID, ASK_PRICE, AVAILABLE_IC, TOTAL_IC) VALUES (%d, %d, %f, %f)", GetPlayerAccountID( playerid ), price, quantity, quantity );
			mysql_single_query( szBigString );

			// deduct the coins
			SendServerMessage( playerid, "已下达 %s IC 代币(在 %s/IC)的卖单.取消通过 "COL_GREY"/ic cancel"COL_WHITE".", number_format( quantity, .decimals = 3 ), cash_format( price ) );
			GivePlayerIrresistibleCoins( playerid, -quantity );
		}
		return Y_HOOKS_BREAK_RETURN_1;
	}
	else if ( strmatch( params, "buy" ) )
	{
		ShowPlayerCoinSellOrders( playerid );
		return Y_HOOKS_BREAK_RETURN_1;
	}
	else if ( strmatch( params, "cancel" ) )
	{
		mysql_tquery( dbHandle, sprintf( "SELECT * FROM `IC_SELL_ORDERS` WHERE `USER_ID` = %d", GetPlayerAccountID( playerid ) ), "PlayerMarket_OnCancelOrders", "d", playerid );
		return Y_HOOKS_BREAK_RETURN_1;
	}
	return 1;
}

/* ** SQL Threads ** */
thread PlayerMarket_OnShowSellOrders( playerid )
{
	new
		rows = cache_get_row_count( );

	if ( rows )
	{
		static
			seller[ 24 ];

		// set headers
		szHugeString = ""COL_GREY"玩家\t"COL_GREY"可用数量 (IC)\t"COL_GREY"每枚硬币的价格 ($)\n";

		for ( new row = 0; row < sizeof ( p_PlayerMarket_SellOrders[ ] ); row ++ )
		{
			if ( row < rows )
			{
				// store all the listing ids to the player
				p_PlayerMarket_SellOrders[ playerid ] [ row ] = cache_get_field_content_int( row, "ID" );

				cache_get_field_content( row, "NAME", seller );

				new Float: quantity = cache_get_field_content_float( row, "AVAILABLE_IC" );
				new ask_price = cache_get_field_content_int( row, "ASK_PRICE" );

				format( szHugeString, sizeof( szHugeString ), "%s%s\t%s IC\t"COL_GREEN"%s\n", szHugeString, seller, number_format( quantity, .decimals = 3 ), cash_format( ask_price ) );
			}
			else
			{
				p_PlayerMarket_SellOrders[ playerid ] [ row ] = -1;
			}
		}
		return ShowPlayerDialog( playerid, DIALOG_IC_SELLORDERS, DIALOG_STYLE_TABLIST_HEADERS, ""COL_GOLD"IC 代币 - "COL_WHITE"购买金币", szHugeString, "买", "关闭" );
	}
	else
	{
		return SendError( playerid, "目前没有可用的硬币销售订单." );
	}
}

thread PlayerMarket_OnShowSellOrder( playerid, sellorderid )
{
	new
		rows = cache_get_row_count( );

	if ( ! rows ) {
		return SendError( playerid, "该卖单不再存在.请再试一次." );
	}

	new Float: quantity = cache_get_field_content_float( 0, "AVAILABLE_IC" );
	new ask_price = cache_get_field_content_int( 0, "ASK_PRICE" );

	SetPVarInt( playerid, "playermarket_sellorder", sellorderid );
	SetPVarInt( playerid, "playermarket_askprice", ask_price );
	SetPVarFloat( playerid, "playermarket_available", quantity );

	format( szBigString, sizeof( szBigString ), ""COL_WHITE"该玩家有 %s IC 代币 可以以每枚硬币 %s 的价格出售.\n\n你想购买多少 IC 代币?", number_format( quantity, .decimals = 3 ), cash_format( ask_price ) );
	return ShowPlayerDialog( playerid, DIALOG_IC_BUY, DIALOG_STYLE_INPUT, ""COL_GOLD"IC 代币 - "COL_WHITE"购买金币", szBigString, "买", "返回" ), 1;
}

thread PlayerMarket_OnCancelOrders( playerid )
{
	new
		rows = cache_get_row_count( );

	if ( ! rows ) {
		return SendError( playerid, "你目前没有任何卖单." );
	}

	new
		Float: coins_accum = 0.0;

	for ( new row = 0; row < rows; row ++ ) {
		coins_accum += cache_get_field_content_float( row, "AVAILABLE_IC" );
	}

	// delete from db
	mysql_single_query( sprintf( "DELETE FROM IC_SELL_ORDERS WHERE USER_ID = %d", GetPlayerAccountID( playerid ) ) );

	// credit back user
	GivePlayerIrresistibleCoins( playerid, coins_accum );
	SendServerMessage( playerid, "你已取消 %d 卖单.你已返回 %s IC.", rows, number_format( coins_accum, .decimals = 3 ) );
	return 1;
}

thread PlayerMarket_OnPurchaseOrder( playerid, sellorderid, Float: purchase_amount )
{
	new
		rows = cache_get_row_count( );

	if ( ! rows ) {
		return SendError( playerid, "该卖单不再存在.请再试一次." );
	}

	// check if the player has the money for the purchase
	new ask_price = cache_get_field_content_int( 0, "ASK_PRICE" );
	new purchase_cost = floatround( float( ask_price ) * purchase_amount );

	if ( GetPlayerCash( playerid ) < purchase_cost ) {
		return SendError( playerid, "你至少需要 %s 才能购买这么多硬币.", cash_format( purchase_cost ) ), PlayerMarket_ShowSellOrder( playerid, sellorderid ), 1;
	}

	// check if quantity is valid
	new Float: available_quantity = cache_get_field_content_float( 0, "AVAILABLE_IC" );

	if ( purchase_amount > available_quantity ) {
		return SendError( playerid, "该玩家没有那么多硬币可供出售." ), PlayerMarket_ShowSellOrder( playerid, sellorderid ), 1;
	}

	// check if seller is the buyer
	new seller_account_id = cache_get_field_content_int( 0, "USER_ID" );

	if ( GetPlayerAccountID( playerid ) == seller_account_id ) {
		return SendError( playerid, "你不能购买自己的硬币." ), PlayerMarket_ShowSellOrder( playerid, sellorderid ), 1;
	}

	// delete the sell order if theres little remaining else reduce
	if ( available_quantity - purchase_amount < 0.5 ) {
		mysql_single_query( sprintf( "DELETE FROM IC_SELL_ORDERS WHERE ID = %d", sellorderid ) );
	} else {
		mysql_single_query( sprintf( "UPDATE IC_SELL_ORDERS SET AVAILABLE_IC = AVAILABLE_IC - %f WHERE ID = %d", purchase_amount, sellorderid ) );
	}

	// check if the seller is online
	new
		sellerid;

	foreach ( sellerid : Player ) if ( GetPlayerAccountID( sellerid ) == seller_account_id ) {
		break;
	}

	new after_fee_amount = floatround( float( purchase_cost ) * 0.995, floatround_floor );

	if ( 0 <= sellerid < MAX_PLAYERS && Iter_Contains( Player, sellerid ) && IsPlayerLoggedIn( sellerid )  ) {
		GivePlayerBankMoney( sellerid, after_fee_amount ), Beep( sellerid );
		SendServerMessage( sellerid, "售出 %s IC 给 %s(%d), 收入"COL_GOLD"%s"COL_WHITE" (手续费 0.5%s)!", number_format( purchase_amount, .decimals = 3 ), ReturnPlayerName( playerid ), playerid, cash_format( after_fee_amount ), "%%" );
	} else {
		mysql_single_query( sprintf( "UPDATE `USERS` SET `BANKMONEY` = `BANKMONEY` + %d WHERE `ID` = %d", after_fee_amount, seller_account_id ) );
	}

	// log the purchase
	mysql_format( dbHandle, szBigString, sizeof( szBigString ), "INSERT INTO IC_MARKET_LOG (SELLER_ID, BUYER_ID, ASK_RATE, IC_AMOUNT) VALUES (%d, %d, %d, %f)", seller_account_id, GetPlayerAccountID( playerid ), ask_price, purchase_amount );
	mysql_single_query( szBigString );

	// credit the buyer
	GivePlayerCash( playerid, -purchase_cost );
	GivePlayerIrresistibleCoins( playerid, purchase_amount );
	SendServerMessage( playerid, "你已成功购买 %s IC (@ %s/IC),价格为 %s.", number_format( purchase_amount, .decimals = 3 ), cash_format( ask_price ), cash_format( purchase_cost ) );
	return 1;
}

/* ** Functions ** */
stock ShowPlayerCoinSellOrders( playerid ) {
	mysql_tquery( dbHandle, "SELECT IC_SELL_ORDERS.*,USERS.NAME FROM IC_SELL_ORDERS INNER JOIN USERS ON USERS.ID = IC_SELL_ORDERS.USER_ID ORDER BY ASK_PRICE ASC", "PlayerMarket_OnShowSellOrders", "d", playerid );
	return 1;
}

static stock PlayerMarket_ShowSellOrder( playerid, sellorderid ) {
	mysql_tquery( dbHandle, sprintf( "SELECT * FROM `IC_SELL_ORDERS` WHERE `ID` = %d", sellorderid ), "PlayerMarket_OnShowSellOrder", "dd", playerid, sellorderid );
	return 1;
}

/* ** Migrations ** */
/*
	CREATE TABLE IF NOT EXISTS IC_SELL_ORDERS (
		`ID` int(11) AUTO_INCREMENT PRIMARY KEY,
		`USER_ID` int(11),
		`ASK_PRICE` int(11),
		`AVAILABLE_IC` float,
		`TOTAL_IC` float,
		`LISTING_DATE` TIMESTAMP default CURRENT_TIMESTAMP
	);

	CREATE TABLE IF NOT EXISTS IC_MARKET_LOG (
		`ID` int(11) AUTO_INCREMENT PRIMARY KEY,
		`SELLER_ID` int(11),
		`BUYER_ID` int(11),
		`ASK_RATE` int(11),
		`IC_AMOUNT` float,
		`DATE` TIMESTAMP default CURRENT_TIMESTAMP
	);
*/
