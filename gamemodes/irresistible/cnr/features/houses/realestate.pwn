/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\home\realestate.pwn
 * Purpose: home listings for player homes
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
// #define DIALOG_HOUSE_LISTINGS		5838
// #define DIALOG_HOUSE_LIST_VIEW		5839

/* ** Macros ** */
#define ShowPlayerHomeListing(%0,%1) \
	mysql_tquery( dbHandle, sprintf( "SELECT * FROM `HOUSE_LISTINGS` WHERE `ID` = %d", %1 ), "HouseListing_OnShowHome", "dd", %0, %1 )

/* ** Constants ** */
static const
	HOUSE_LISTING_FEE 				= 50000;

/* ** Variables ** */
static stock
	p_CurrentListings 				[ MAX_PLAYERS ] [ 20 ];

/* ** Hooks ** */
hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_HOUSE_LISTINGS && response )
	{
		new curr_page = GetPVarInt( playerid, "houselisting_page" );
		new curr_page_items = GetPVarInt( playerid, "houselisting_rows" );

		// pressed previous
		if ( listitem >= curr_page_items + 1 )
		{
			return ShowPlayerHomeListings( playerid, curr_page - 1 );
		}

		// pressed previous (on last page) / next page
		else if ( listitem == curr_page_items )
		{
			// pressed first item, but theres not even 20 items?
			if ( curr_page_items < sizeof ( p_CurrentListings[ ] ) ) {
				return ShowPlayerHomeListings( playerid, curr_page - 1 );
			} else {
				return ShowPlayerHomeListings( playerid, curr_page + 1 );
			}
		}

		else
		{
			for ( new i = 0, x = 0; i < sizeof ( p_CurrentListings[ ] ); i ++ ) if ( p_CurrentListings[ playerid ] [ i ] != -1 )
			{
				if ( x == listitem )
				{
					ShowPlayerHomeListing( playerid, p_CurrentListings[ playerid ] [ i ] );
					break;
				}
				x ++;
			}
		}
		return 1;
	}
	else if ( dialogid == DIALOG_HOUSE_LIST_VIEW )
	{
		if ( ! response )
			return ShowPlayerHomeListings( playerid, GetPVarInt( playerid, "houselisting_page" ) );

		new houseid = GetPVarInt( playerid, "house_listing_houseid" );
		new listingid = GetPVarInt( playerid, "house_listing_viewid" );

		switch ( listitem )
		{
			case 0: mysql_tquery( dbHandle, sprintf( "SELECT *, UNIX_TIMESTAMP(`SALE_DATE`) as `SALE_DATE_TS` FROM `HOUSE_LISTINGS` WHERE `ID` = %d", listingid ), "HouseListing_OnBuyHome", "dd", playerid, listingid );
			case 1:
			{
				if ( IsPlayerInAnyVehicle( playerid ) )
				{
					GPS_SetPlayerWaypoint( playerid, g_houseData[ houseid ] [ E_HOUSE_NAME ], g_houseData[ houseid ] [ E_EX ], g_houseData[ houseid ] [ E_EY ], g_houseData[ houseid ] [ E_EZ ] );
					SendClientMessageFormatted( playerid, -1, ""COL_GREY"[GPS]"COL_WHITE" 你已将目的地设置为 %s"COL_WHITE".按照箭头到达目的地.", g_houseData[ houseid ] [ E_HOUSE_NAME ] );
				}
				else
				{
					ShowPlayerHomeListing( playerid, listingid );
					SendError( playerid, "你需要在车内才能设置 GPS 航路点." );
					return 1;
				}
			}
		}
	}
	return 1;
}

hook OnHouseOwnerChange( houseid, owner )
{
	mysql_single_query( sprintf( "DELETE FROM `HOUSE_LISTINGS` WHERE `HOUSE_ID` = %d AND `SALE_DATE` IS NULL", houseid ) );
	return 1;
}

/* ** Commands ** */
CMD:realestate( playerid, params[ ] ) return cmd_estate( playerid, params );
CMD:estate( playerid, params[ ] )
{
	new
		houseid = p_InHouse[ playerid ];

	if ( strmatch( params, "list cancel" ) )
	{
		if ( ! Iter_Contains( houses, houseid ) ) return SendError( playerid, "你不在任何家里." );
		else if ( ! IsPlayerHomeOwner( playerid, houseid ) ) return SendError( playerid, "你不是这个家的主人." );
		{
			mysql_tquery( dbHandle, sprintf( "DELETE FROM `HOUSE_LISTINGS` WHERE `HOUSE_ID` = %d AND `SALE_DATE` IS NULL", houseid ), "HouseListing_OnDeleteListing", "dd", playerid, houseid );
		}
		return 1;
	}
	else if ( !strcmp( params, "list", false, 4 ) )
	{
		new
			cash;

		if ( sscanf( params[ 5 ], "d", cash ) ) return SendUsage( playerid, "/estate list [CASH_ASK_PRICE/CANCEL]");
		else if ( ! Iter_Contains( houses, houseid ) ) return SendError( playerid, "你不在任何家里." );
		else if ( g_houseData[ houseid ] [ E_COST ] > 2500 ) return SendError( playerid, "这个家不是 VIP 家." );
		else if ( ! IsPlayerHomeOwner( playerid, houseid ) ) return SendError( playerid, "你不是这个家的主人." );
		else if ( cash < 10000 ) return SendError( playerid, "请指定大于 $100,000. 的要价" );
		else if ( cash > 100000000 ) return SendError( playerid, "请指定低于 $100,000,000. 的要价" );
		else if ( GetPlayerCash( playerid ) < HOUSE_LISTING_FEE && GetPlayerVIPLevel( playerid ) < VIP_PLATINUM ) return SendError( playerid, "你至少需要 %s 才能创建房屋列表.", cash_format( HOUSE_LISTING_FEE ) );
		else
		{
			mysql_tquery( dbHandle, sprintf( "SELECT * FROM `HOUSE_LISTINGS` WHERE `HOUSE_ID` = %d AND `SALE_DATE` IS NULL", houseid ), "HouseListing_OnCreateListing", "ddf", playerid, houseid, cash );
		}
		return 1;
	}
	else
	{
		SendServerMessage( playerid, "你可以使用列出你自己的家 "COL_GREY"/estate list"COL_WHITE" 为%s.", p_VIPLevel[ playerid ] < VIP_PLATINUM ? ( cash_format( HOUSE_LISTING_FEE ) ) : ( "免费" ) );
		return ShowPlayerHomeListings( playerid );
	}
}

/* ** SQL Threads ** */
thread HouseListing_OnShowHomes( playerid, page )
{
	new
		rows = cache_get_row_count( );

	if ( rows )
	{
		static
			location[ MAX_ZONE_NAME ],
			city[ 3 ],
			house_name[ 32 ],
			owner[ 24 ];

		// set headers
		szHugeString = ""COL_GREY"房子\t"COL_GREY"所有者\t"COL_GREY"地点\t"COL_GREY"要价 ($)\n";

		for ( new row = 0; row < sizeof ( p_CurrentListings[ ] ); row ++ )
		{
			if ( row < rows )
			{
				// store all the listing ids to the player
				p_CurrentListings[ playerid ] [ row ] = cache_get_field_content_int( row, "ID" );

				cache_get_field_content( row, "NAME", house_name );
				cache_get_field_content( row, "OWNER", owner );

				new houseid = cache_get_field_content_int( row, "HOUSE_ID" );

			    Get2DCityShort( city, g_houseData[ houseid ] [ E_EX ], g_houseData[ houseid ] [ E_EY ] );
			    GetZoneFromCoordinates( location, g_houseData[ houseid ] [ E_EX ], g_houseData[ houseid ] [ E_EY ], .placeholder = "岛" );

				new cash = cache_get_field_content_int( row, "ASK" );

				format( szHugeString, sizeof( szHugeString ), "%s%s\t%s\t%s, %s\t"COL_GREEN"%s\n", szHugeString, house_name, owner, GetLocationDisplayName(location), GetLocationDisplayName(city), cash_format( cash ) );
			}
			else
			{
				p_CurrentListings[ playerid ] [ row ] = -1;
			}
		}

		if ( rows >= sizeof ( p_CurrentListings[ ] ) ) {
			strcat( szHugeString, ""COL_GREEN"下一页\t"COL_GREEN">>>\t"COL_GREEN">>>\t"COL_GREEN">>>\t"COL_GREEN">>>\n" );
		}

		if ( page ) {
			strcat( szHugeString, ""COL_ORANGE"上一页\t"COL_ORANGE"<<<\t"COL_ORANGE"<<<\t"COL_ORANGE"<<<\t"COL_ORANGE"<<<\n" );
		}

		SetPVarInt( playerid, "houselisting_page", page );
		SetPVarInt( playerid, "houselisting_rows", rows );

		return ShowPlayerDialog( playerid, DIALOG_HOUSE_LISTINGS, DIALOG_STYLE_TABLIST_HEADERS, "高级住宅区", szHugeString, "选择", "关闭" );
	}
	else
	{
		return SendError( playerid, "目前没有可供出售的房屋." );
	}
}

thread HouseListing_OnShowHome( playerid, house_listing_id )
{
	new
		rows = cache_get_row_count( );

	if ( rows )
	{
		new house_id = cache_get_field_content_int( 0, "HOUSE_ID" );
		new cash = cache_get_field_content_int( 0, "ASK" );

		SetPVarInt( playerid, "house_listing_viewid", house_listing_id );
		SetPVarInt( playerid, "house_listing_houseid", house_id );

		return ShowPlayerDialog(
			playerid, DIALOG_HOUSE_LIST_VIEW, DIALOG_STYLE_TABLIST,
			"高级住宅区",
			sprintf( "购买房屋\t"COL_GREEN"%s\n设置 GPS 航点\t"COL_GREY">>>", cash_format( cash ) ),
			"选择", "返回"
		);
	}
	else
	{
		return SendError( playerid, "发生错误,请重试." );
	}
}

thread HouseListing_OnBuyHome( playerid, house_listing_id )
{
	new
		rows = cache_get_row_count( );

	if ( rows )
	{
		new
			ask_price = cache_get_field_content_int( 0, "ASK" );

		// does the dude even have the cash
		if ( GetPlayerCash( playerid ) < ask_price ) {
			ShowPlayerHomeListing( playerid, house_listing_id );
			return SendError( playerid, "你没有足够的钱买这个家 (%s).", cash_format( ask_price ) );
		}

		// check if player is over the limit
		if ( p_OwnedHouses[ playerid ] >= GetPlayerHouseSlots( playerid ) ) {
			ShowPlayerHomeListing( playerid, house_listing_id );
			return SendError( playerid, "你无法再购买任何房屋,你已达到限制." );
		}

		// check if sale already completed
		new
			sale_date_ts = cache_get_field_content_int( 0, "SALE_DATE_TS" );

		if ( sale_date_ts != 0 && GetServerTime( ) > sale_date_ts ) {
			return SendError( playerid, "你不能再购买该房屋,因为它已被出售." );
		}

		// check if buyer is the player himself
		new
			owner_account_id = cache_get_field_content_int( 0, "USER_ID" );

		if ( GetPlayerAccountID( playerid ) == owner_account_id ) {
			ShowPlayerHomeListing( playerid, house_listing_id );
			return SendError( playerid, "你不能购买自己的房子." );
		}

		// credit seller if they are on/offline
		new
			houseid = cache_get_field_content_int( 0, "HOUSE_ID" ),
			sellerid;

		foreach ( sellerid : Player ) if ( GetPlayerAccountID( sellerid ) == owner_account_id ) {
			break;
		}

		// validate seller id
		if ( 0 <= sellerid < MAX_PLAYERS && Iter_Contains( Player, sellerid ) ) {
			p_OwnedHouses[ sellerid ] --;
			GivePlayerCash( sellerid, ask_price );
			SendServerMessage( sellerid, "你已成功出售你的房屋 (%s) "COL_GOLD"%s"COL_WHITE" 到 %s(%d)!", g_houseData[ houseid ] [ E_HOUSE_NAME ], cash_format( ask_price ), ReturnPlayerName( playerid ), playerid );
		} else {
			mysql_single_query( sprintf( "UPDATE `USERS` SET `CASH` = `CASH` + %d WHERE `ID` = %d", ask_price, owner_account_id ) );
		}

		// show sellers name & house name
		SendServerMessage( playerid, "你已成功购买 %s 的房屋 (%s"COL_WHITE") 为 "COL_GOLD"%s"COL_WHITE"!", g_houseData[ houseid ] [ E_OWNER ], g_houseData[ houseid ] [ E_HOUSE_NAME ], cash_format( ask_price ) );

		// set listing as sold and transfer home
		mysql_single_query( sprintf( "UPDATE `HOUSE_LISTINGS` SET `SALE_DATE` = CURRENT_TIMESTAMP WHERE `ID` = %d", house_listing_id ) );
		SetHouseOwner( houseid, GetPlayerAccountID( playerid ), ReturnPlayerName( playerid ) );
		GivePlayerCash( playerid, -ask_price );
		p_OwnedHouses[ playerid ] ++;
		return 1;
	}
	else
	{
		return SendError( playerid, "发生错误,请重试." );
	}
}

thread HouseListing_OnCreateListing( playerid, houseid, ask_price )
{
	new
		rows = cache_get_row_count( );

	if ( ! rows )
	{
		// debit user account
		if ( GetPlayerVIPLevel( playerid ) < VIP_PLATINUM ) {
			GivePlayerCash( playerid, -HOUSE_LISTING_FEE );
		}

		// insert into database and notify
		mysql_single_query( sprintf( "INSERT INTO `HOUSE_LISTINGS` (`HOUSE_ID`, `USER_ID`, `ASK`) VALUES (%d, %d, %d)", houseid, GetPlayerAccountID( playerid ), ask_price ) );
		return SendServerMessage( playerid, "你已列出你的家 "COL_GOLD"%s"COL_WHITE".撤回列表 "COL_GREY"/estate list cancel"COL_WHITE".", cash_format( ask_price ) );
	}
	else
	{
		return SendError( playerid, "该房屋已列出.你可以使用以下方式撤消你的列表 "COL_GREY"/estate list cancel"COL_WHITE"." );
	}
}

thread HouseListing_OnDeleteListing( playerid, houseid )
{
	new
		deleted_rows = cache_affected_rows( );

	if ( deleted_rows )
	{
		return SendServerMessage( playerid, "你已将你的房屋除名.你可以使用以下命令创建新列表 "COL_GREY"/estate list"COL_WHITE"." );
	}
	else
	{
		return SendError( playerid, "该房屋未在优质房地产市场上市." );
	}
}

/* ** Functions ** */
stock ShowPlayerHomeListings( playerid, page = 0 )
{
	// just incase we get some negative page from user ... reset
	if ( page < 0 ) {
		page = 0;
	}

	// format query, offset according to page
	format(
		szBigString, sizeof( szBigString ),
		"SELECT HL.ID, HL.HOUSE_ID, H.NAME, U.NAME AS OWNER, HL.ASK FROM HOUSE_LISTINGS HL " \
		"INNER JOIN HOUSES H ON H.ID = HL.HOUSE_ID " \
		"INNER JOIN USERS U ON U.ID = HL.USER_ID " \
		"WHERE SALE_DATE IS NULL LIMIT %d OFFSET %d",
		sizeof( p_CurrentListings[ ] ), page * sizeof( p_CurrentListings[ ] )
	);
	return mysql_tquery( dbHandle, szBigString, "HouseListing_OnShowHomes", "dd", playerid, page );
}

/* ** Migrations ** */
/*
	DROP TABLE HOUSE_LISTINGS;
	CREATE TABLE IF NOT EXISTS HOUSE_LISTINGS (
		ID int(11) AUTO_INCREMENT PRIMARY KEY,
		HOUSE_ID int(11),
		USER_ID int(11),
		ASK int(11),
		LISTING_DATE TIMESTAMP default CURRENT_TIMESTAMP,
		SALE_DATE TIMESTAMP nullable default null,
		FOREIGN KEY (HOUSE_ID) REFERENCES HOUSES (ID) ON DELETE CASCADE
	)
*/