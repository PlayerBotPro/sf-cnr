/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\crowdfund.pwn
 * Purpose: off-ucp crowdfunding feature (all done in-game)
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_CROWDFUNDS 				10 		// dont bother editing

/* ** Hooks ** */
hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_CROWDFUNDS && response )
	{
		new crowdfund_ids_string[ MAX_CROWDFUNDS * 3 ];
		new crowdfunds_ids[ MAX_CROWDFUNDS ];

    	GetPVarString( playerid, "crowdfunds_shown", crowdfund_ids_string, sizeof( crowdfund_ids_string ) );

		if ( sscanf( crowdfund_ids_string, "a<i>[" # MAX_CROWDFUNDS "]", crowdfunds_ids ) ) {
			return SendError( playerid, "读取众筹时出错,请稍后再试." );
		}

		for ( new i = 0, x = 0; i < sizeof( crowdfunds_ids ); i ++ ) if ( crowdfunds_ids[ i ] != 0 )
		{
			if ( x == listitem )
			{
				SetPVarInt( playerid, "viewing_crowdfund", crowdfunds_ids[ i ] );
				break;
			}
			x ++;
		}
		return ShowPlayerDialog( playerid, DIALOG_CROWDFUND_OPTIONS, DIALOG_STYLE_LIST, ""COL_GOLD"特色众筹", "查看众筹详情\n查看众筹赞助人\n"COL_GOLD"为众筹做出贡献 <3", "选择", "关闭" );
	}
	else if ( dialogid == DIALOG_CROWDFUND_OPTIONS )
	{
		if ( ! response )
			return ShowPlayerCrowdfunds( playerid );

		new
			viewing_crowdfund = GetPVarInt( playerid, "viewing_crowdfund" );

		if ( ! viewing_crowdfund ) {
			return SendError( playerid, "出现错误.请再次尝试为众筹捐款." );
		}

		switch ( listitem )
		{
			case 0:
			{
				mysql_tquery(
					dbHandle,
					sprintf( "SELECT CROWDFUND_PACKAGES.*, CROWDFUNDS.DESCRIPTION AS CF_DESCRIPTION FROM CROWDFUND_PACKAGES INNER JOIN CROWDFUNDS ON CROWDFUNDS.ID = CROWDFUND_PACKAGES.CROWDFUND_ID WHERE CROWDFUND_ID = %d ORDER BY REQUIRED_AMOUNT DESC", viewing_crowdfund ),
					"OnDisplayCrowdfundInfo", "ii", playerid, viewing_crowdfund
				);
			}
			case 1:
			{
				mysql_tquery(
					dbHandle,
					sprintf( "SELECT USERS.NAME, SUM(AMOUNT) AS TOTAL FROM CROWDFUND_PATREONS INNER JOIN USERS ON USERS.ID = CROWDFUND_PATREONS.USER_ID WHERE CROWDFUND_PATREONS.CROWDFUND_ID = %d GROUP BY CROWDFUND_PATREONS.USER_ID ORDER BY TOTAL DESC", viewing_crowdfund ),
					"OnDisplayCrowdfundPatreons", "ii", playerid, viewing_crowdfund
				);
			}
			case 2:
			{
				return ShowPlayerDialog( playerid, DIALOG_CROWDFUND_DONATE, DIALOG_STYLE_INPUT, ""COL_GOLD"特色众筹", ""COL_WHITE"请注明你希望捐款的 IC 金额:\n\n"COL_ORANGE"警告:没有确认对话框.", "贡献", "返回" );
			}
		}
	}
	else if ( dialogid == DIALOG_CROWDFUND_INFO && ! response ) {
		return ShowPlayerDialog( playerid, DIALOG_CROWDFUND_OPTIONS, DIALOG_STYLE_LIST, ""COL_GOLD"特色众筹", "查看众筹详情\n查看众筹赞助人\n"COL_GOLD"为众筹做出贡献 <3", "选择", "关闭" );
	}
	else if ( dialogid == DIALOG_CROWDFUND_DONATE )
	{
		if ( ! response )
			return ShowPlayerDialog( playerid, DIALOG_CROWDFUND_OPTIONS, DIALOG_STYLE_LIST, ""COL_GOLD"特色众筹", "查看众筹详情\n查看众筹赞助人\n"COL_GOLD"为众筹做出贡献 <3", "选择", "关闭" );

		new
			viewing_crowdfund = GetPVarInt( playerid, "viewing_crowdfund" );

		if ( ! viewing_crowdfund ) {
			return SendError( playerid, "出现错误.请再次尝试为众筹捐款." );
		}

		new
			Float: amount;

		if ( sscanf( inputtext, "f", amount ) ) {
			return ShowPlayerDialog( playerid, DIALOG_CROWDFUND_DONATE, DIALOG_STYLE_INPUT, ""COL_GOLD"特色众筹", ""COL_WHITE"请注明你希望捐款的 IC 金额:\n\n"COL_RED"请指定一个小数!", "贡献", "关闭" );
		} else if ( amount < 10.0 ) {
			return ShowPlayerDialog( playerid, DIALOG_CROWDFUND_DONATE, DIALOG_STYLE_INPUT, ""COL_GOLD"特色众筹", ""COL_WHITE"请注明你希望捐款的 IC 金额:\n\n"COL_RED"你可以贡献的最低金额是 10.00 IC!", "贡献", "关闭" );
		} else if ( amount > GetPlayerIrresistibleCoins( playerid ) ) {
			return ShowPlayerDialog( playerid, DIALOG_CROWDFUND_DONATE, DIALOG_STYLE_INPUT, ""COL_GOLD"特色众筹", ""COL_WHITE"请注明你希望捐款的 IC 金额:\n\n"COL_RED"你的帐户中没有这么多硬币!", "贡献", "关闭" );
		} else {
			// check if expired/ended/valid before even submitting
			mysql_tquery( dbHandle, sprintf( "SELECT FEATURE, UNIX_TIMESTAMP(RELEASE_DATE) AS `RELEASE`, UNIX_TIMESTAMP(END_DATE) AS `END` FROM CROWDFUNDS WHERE ID = %d", viewing_crowdfund ), "OnPlayerCrowdfundContribute", "ddf", playerid, viewing_crowdfund, amount );
		}
		return 1;
	}
	return 1;
}

/* ** Commands ** */
CMD:crowdfund( playerid, params[ ] ) return cmd_crowdfunds( playerid, params );
CMD:crowdfunds( playerid, params[ ] ) return ShowPlayerCrowdfunds( playerid );

/* ** Functions ** */
stock ShowPlayerCrowdfunds( playerid ) {
	return mysql_tquery( dbHandle,
		"SELECT CROWDFUNDS.ID, CROWDFUNDS.FEATURE, CROWDFUNDS.FUND_TARGET, SUM(CROWDFUND_PATREONS.AMOUNT) AS RAISED, UNIX_TIMESTAMP(RELEASE_DATE) AS RELEASE_TS, UNIX_TIMESTAMP(END_DATE) AS END_TS FROM CROWDFUNDS " \
		"LEFT JOIN CROWDFUND_PATREONS on CROWDFUNDS.ID = CROWDFUND_PATREONS.CROWDFUND_ID " \
		"GROUP BY CROWDFUNDS.ID ORDER BY CROWDFUNDS.ID DESC LIMIT " # MAX_CROWDFUNDS,
		"OnDisplayCrowdfunds", "i", playerid
	), 1;
}

thread OnPlayerCrowdfundContribute( playerid, crowdfund_id, Float: amount )
{
	new
		rows = cache_get_row_count( );

	if ( rows )
	{
		new feature[ 64 ];
		new curr_timestamp = gettime( );
		new release_timestamp = cache_get_field_content_int( 0, "RELEASE", dbHandle );
		new end_timestamp = cache_get_field_content_int( 0, "END", dbHandle );

		// check if released or ended
		if ( ( curr_timestamp > release_timestamp && release_timestamp != 0 ) || ( curr_timestamp > end_timestamp ) ) {
			SendError( playerid, "由于该众筹已发布或结束,你无法再为此众筹捐款." );
			return ShowPlayerCrowdfunds( playerid );
		}

		// double check valid amounts again
		if ( amount < 10.0 || amount > GetPlayerIrresistibleCoins( playerid ) ) {
			SendError( playerid, "由于捐款金额无效,你无法再为此众筹捐款." );
			return ShowPlayerCrowdfunds( playerid );
		}

		// get feature name
		cache_get_field_content( 0, "FEATURE", feature );

		// notify and deduct ic
		GivePlayerIrresistibleCoins( playerid, -amount );
		SendClientMessageToAllFormatted( -1, ""COL_GOLD"[众筹]"COL_WHITE" %s(%d) 已将 %s IC 捐赠给 %s 众筹! <3", ReturnPlayerName( playerid ), playerid, number_format( amount, .prefix = '\0', .decimals = 2 ), feature );
		SavePlayerData( playerid ); // force save just incase

		// insert into database
		mysql_format(
			dbHandle, szBigString, sizeof( szBigString ),
			"INSERT INTO CROWDFUND_PATREONS (USER_ID, CROWDFUND_ID, AMOUNT) VALUES (%d, %d, %f)",
			GetPlayerAccountID( playerid ), crowdfund_id, amount
		);
		mysql_single_query( szBigString );
		return 1;
	}
	else
	{
		return SendError( playerid, "你尝试捐款的众筹已不存在." );
	}
}

thread OnDisplayCrowdfundPatreons( playerid, crowdfund_id )
{
	new
		rows = cache_get_row_count( );

	if ( ! rows ) {
		return ShowPlayerDialog( playerid, DIALOG_CROWDFUND_INFO, DIALOG_STYLE_TABLIST_HEADERS, ""COL_GOLD"特色众筹", ""COL_GREY"贡献者\t"COL_GREY"金额 (IC)\n"COL_RED"无人\t"COL_RED"N/A", "关闭", "返回" ), 1;
	}

	new patreon[ MAX_PLAYER_NAME ];

	szHugeString = ""COL_GREY"贡献者\t"COL_GREY"金额 (IC)\n";

	for ( new row = 0; row < rows; row ++ )
	{
		cache_get_field_content( row, "NAME", patreon );

		new Float: contribution = cache_get_field_content_float( row, "TOTAL", dbHandle );

		format( szHugeString, sizeof( szHugeString ), "%s%s\t%s IC\n", szHugeString, patreon, number_format( contribution, .prefix = '\0', .decimals = 2 ) );
	}
	return ShowPlayerDialog( playerid, DIALOG_CROWDFUND_INFO, DIALOG_STYLE_TABLIST_HEADERS, ""COL_GOLD"特色众筹", szHugeString, "关闭", "返回" ), 1;
}

thread OnDisplayCrowdfundInfo( playerid, crowdfund_id )
{
	new
		rows = cache_get_row_count( );

	if ( ! rows ) {
		return SendError( playerid, "没有可显示的众筹信息.稍后再试." );
	}

	new cf_description[ 100 ];
	new description[ 100 ];
	new title[ 48 ];

	cache_get_field_content( 0, "CF_DESCRIPTION", cf_description );

	if ( strlen( cf_description ) < sizeof( cf_description ) - 1 ) {
		format( szHugeString, sizeof( szHugeString ), ""COL_WHITE"%s\n\n", cf_description );
	} else {
		format( szHugeString, sizeof( szHugeString ), ""COL_WHITE"%s"COL_GREY"...(在 sfcnr.com 上了解更多信息)\n\n", cf_description );
	}

	for ( new row = 0; row < rows; row ++ )
	{
		cache_get_field_content( row, "TITLE", title );
		cache_get_field_content( row, "DESCRIPTION", description );

		new Float: req_amount = cache_get_field_content_float( row, "REQUIRED_AMOUNT", dbHandle );

		if ( strlen( description ) < sizeof( description ) - 1 ) {
			format( szHugeString, sizeof( szHugeString ), "%s"COL_GOLD"%s (%s IC+)"COL_WHITE"\n%s\n\n", szHugeString, title, number_format( req_amount, .prefix = '\0', .decimals = 2 ), description );
		} else {
			format( szHugeString, sizeof( szHugeString ), "%s"COL_GOLD"%s (%s IC+)"COL_WHITE"\n%s"COL_GREY"...(在 sfcnr.com 上了解更多信息)\n\n", szHugeString, title, number_format( req_amount, .prefix = '\0', .decimals = 2 ), description );
		}
	}
	return ShowPlayerDialog( playerid, DIALOG_CROWDFUND_INFO, DIALOG_STYLE_MSGBOX, ""COL_GOLD"特色众筹", szHugeString, "关闭", "返回" ), 1;
}

thread OnDisplayCrowdfunds( playerid )
{
	new
		rows = cache_get_row_count( );

	if ( ! rows ) {
		return SendError( playerid, "没有可显示的众筹.稍后再试." );
	}

	new feature[ 64 ];
	new crowdfund_ids[ MAX_CROWDFUNDS * 3 ];

	// header
	szLargeString = ""COL_WHITE"功能\t"COL_WHITE"提出 (IC)\t"COL_WHITE"目标 (IC)\t"COL_WHITE"完成度 (%)\n";

	for ( new row = 0; row < MAX_CROWDFUNDS; row ++ )
	{
		new
			id = 0;

		if ( row < rows )
		{
			id = cache_get_field_content_int( row, "ID" );
			cache_get_field_content( row, "FEATURE", feature );

			new Float: amount_raised = cache_get_field_content_float( row, "RAISED", dbHandle );
			new Float: target_amount = cache_get_field_content_float( row, "FUND_TARGET", dbHandle );
			new Float: percent_raised = ( amount_raised / target_amount ) * 100.0;

			new curr_timestamp = gettime( );
			new release_timestamp = cache_get_field_content_int( row, "RELEASE_TS", dbHandle );
			new end_timestamp = cache_get_field_content_int( row, "END_TS", dbHandle );

			// inactive
			if ( ( curr_timestamp > release_timestamp && release_timestamp != 0 ) || ( curr_timestamp > end_timestamp ) )
			{
				format( szLargeString, sizeof( szLargeString ),
					"%s{333333}%s\t{333333}%s IC\t{333333}%s IC\t%s%0.1f%\n",
					szLargeString, feature,
					number_format( amount_raised, .prefix = '\0', .decimals = 1 ),
					number_format( target_amount, .prefix = '\0', .decimals = 1 ),
					percent_raised >= 100.0 ? ( COL_GREEN ) : ( COL_WHITE ), percent_raised
				);
			}
			else
			{
				format( szLargeString, sizeof( szLargeString ),
					"%s%s\t%s IC\t%s IC\t%s%0.1f%\n",
					szLargeString, feature,
					number_format( amount_raised, .prefix = '\0', .decimals = 1 ),
					number_format( target_amount, .prefix = '\0', .decimals = 1 ),
					percent_raised >= 100.0 ? ( COL_GREEN ) : ( COL_WHITE ), percent_raised
				);
			}
		}
		format( crowdfund_ids, sizeof( crowdfund_ids ), "%s%d ", crowdfund_ids, id );
	}

	// save ids for response
	SetPVarString( playerid, "crowdfunds_shown", crowdfund_ids );
	return ShowPlayerDialog( playerid, DIALOG_CROWDFUNDS, DIALOG_STYLE_TABLIST_HEADERS, ""COL_GOLD"特色众筹", szLargeString, "选择", "关闭" ), 1;
}
