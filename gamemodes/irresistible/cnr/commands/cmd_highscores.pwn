/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc, Stev
 * Module: cnr\commands\cmd_highscores.pwn
 * Purpose: /highscores to show all highscores by a player
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Commands ** */
CMD:top( playerid, params[ ] ) return cmd_highscores( playerid, params );
CMD:highscores( playerid, params[ ] )
{
	ShowPlayerDialog( playerid, DIALOG_HIGHSCORES, DIALOG_STYLE_LIST, "{FFFFFF}排行榜", "赛季等级\n总分数\n总击杀\n总逮捕\n总抢劫\n完成悬赏\n扑灭火灾\n入室盗窃\n炸毁监狱\n炸毁金库\n劫车数量\n冰毒产量\n货运总量\n飞行任务总数", "选择", "关闭" );
	return 1;
}

/* ** Hooks ** */
hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_HIGHSCORES && response )
	{
		switch ( listitem )
		{
			// seasonal
			case 0: mysql_tquery( dbHandle, "SELECT `NAME`, `RANK` as `SCORE_VAL` FROM `USERS` ORDER BY `RANK` DESC LIMIT 25", "OnHighScoreCheck", "ii", playerid, 0 );

			// total score
			case 1: mysql_tquery( dbHandle, "SELECT `NAME`, `SCORE` as `SCORE_VAL` FROM `USERS` ORDER BY `SCORE` DESC LIMIT 25", "OnHighScoreCheck", "ii", playerid, 1 );

			// total kills
			case 2: mysql_tquery( dbHandle, "SELECT `NAME`, `KILLS` as `SCORE_VAL` FROM `USERS` ORDER BY `KILLS` DESC LIMIT 25", "OnHighScoreCheck", "ii", playerid, 2 );

			// total arrests
			case 3: mysql_tquery( dbHandle, "SELECT `NAME`, `ARRESTS` as `SCORE_VAL` FROM `USERS` ORDER BY `ARRESTS` DESC LIMIT 25", "OnHighScoreCheck", "ii", playerid, 3 );

			// total robberies
			case 4: mysql_tquery( dbHandle, "SELECT `NAME`, `ROBBERIES` as `SCORE_VAL` FROM `USERS` ORDER BY `ROBBERIES` DESC LIMIT 25", "OnHighScoreCheck", "ii", playerid, 4 );

			// hits completed
			case 5: mysql_tquery( dbHandle, "SELECT `NAME`, `CONTRACTS` as `SCORE_VAL` FROM `USERS` ORDER BY `CONTRACTS` DESC LIMIT 25", "OnHighScoreCheck", "ii", playerid, 5 );

			// fires
			case 6: mysql_tquery( dbHandle, "SELECT `NAME`, `FIRES` as `SCORE_VAL` FROM `USERS` ORDER BY `FIRES` DESC LIMIT 25", "OnHighScoreCheck", "ii", playerid, 6 );

			// burglaries
			case 7: mysql_tquery( dbHandle, "SELECT `NAME`, `BURGLARIES` as `SCORE_VAL` FROM `USERS` ORDER BY `BURGLARIES` DESC LIMIT 25", "OnHighScoreCheck", "ii", playerid, 7 );

			// blown jails
			case 8: mysql_tquery( dbHandle, "SELECT `NAME`, `BLEW_JAILS` as `SCORE_VAL` FROM `USERS` ORDER BY `BLEW_JAILS` DESC LIMIT 25", "OnHighScoreCheck", "ii", playerid, 8 );

			// blown vaults
			case 9: mysql_tquery( dbHandle, "SELECT `NAME`, `BLEW_VAULT` as `SCORE_VAL` FROM `USERS` ORDER BY `BLEW_VAULT` DESC LIMIT 25", "OnHighScoreCheck", "ii", playerid, 9 );

			// vehicles jacked
			case 10: mysql_tquery( dbHandle, "SELECT `NAME`, `VEHICLES_JACKED` as `SCORE_VAL` FROM `USERS` ORDER BY `VEHICLES_JACKED` DESC LIMIT 25", "OnHighScoreCheck", "ii", playerid, 10 );

			// meth yielded
			case 11: mysql_tquery( dbHandle, "SELECT `NAME`, `METH_YIELDED` as `SCORE_VAL` FROM `USERS` ORDER BY `METH_YIELDED` DESC LIMIT 25", "OnHighScoreCheck", "ii", playerid, 11 );

			// total trucked cargo
			case 12: mysql_tquery( dbHandle, "SELECT `NAME`, `TRUCKED` as `SCORE_VAL` FROM `USERS` ORDER BY `TRUCKED` DESC LIMIT 25", "OnHighScoreCheck", "ii", playerid, 12 );

			// pilot missons
			case 13: mysql_tquery( dbHandle, "SELECT `NAME`, `PILOT` as `SCORE_VAL` FROM `USERS` ORDER BY `PILOT` DESC LIMIT 25", "OnHighScoreCheck", "ii", playerid, 13 );
		}
	}
	else if ( dialogid == DIALOG_HIGHSCORES_BACK && ! response ) {
		return ShowPlayerDialog( playerid, DIALOG_HIGHSCORES, DIALOG_STYLE_LIST, "{FFFFFF}排行榜", "赛季等级\n总分数\n总击杀\n总逮捕\n总抢劫\n完成悬赏\n扑灭火灾\n入室盗窃\n炸毁监狱\n炸毁金库\n劫车数量\n冰毒产量\n货运总量\n飞行任务总数", "选择", "关闭" );
	}
    return 1;
}

/* ** SQL Threads ** */
thread OnHighScoreCheck( playerid, highscore_item )
{
	new
		rows;

	cache_get_data( rows, tmpVariable );

	if ( ! rows ) {
		return SendError( playerid, "暂无可显示的信息, 请稍后重试." );
	}

	new
		name[ MAX_PLAYER_NAME ];

	switch ( highscore_item )
	{
		case 0:  szLargeString = ""COL_GOLD"玩家\t"COL_GOLD"赛季等级\n", szSmallString = "赛季前 25 名";
		case 1:  szLargeString = ""COL_GOLD"玩家\t"COL_GOLD"分数\n", szSmallString = "分数前 25 名";
		case 2:  szLargeString = ""COL_GOLD"玩家\t"COL_GOLD"击杀\n", szSmallString = "击杀前 25 名";
		case 3:  szLargeString = ""COL_GOLD"玩家\t"COL_GOLD"逮捕\n", szSmallString = "逮捕前 25 名";
		case 4:  szLargeString = ""COL_GOLD"玩家\t"COL_GOLD"抢劫\n", szSmallString = "抢劫前 25 名";
		case 5:  szLargeString = ""COL_GOLD"玩家\t"COL_GOLD"悬赏\n", szSmallString = "悬赏前 25 名";
		case 6:  szLargeString = ""COL_GOLD"玩家\t"COL_GOLD"火灾\n", szSmallString = "灭火前 25 名";
		case 7:  szLargeString = ""COL_GOLD"玩家\t"COL_GOLD"入室盗窃\n", szSmallString = "入室盗窃前 25 名";
		case 8:  szLargeString = ""COL_GOLD"玩家\t"COL_GOLD"监狱\n", szSmallString = "炸毁监狱前 25 名";
		case 9:  szLargeString = ""COL_GOLD"玩家\t"COL_GOLD"金库\n", szSmallString = "炸毁金库前 25 名";
		case 10: szLargeString = ""COL_GOLD"玩家\t"COL_GOLD"载具\n", szSmallString = "劫车前 25 名";
		case 11: szLargeString = ""COL_GOLD"玩家\t"COL_GOLD"冰毒\n", szSmallString = "冰毒产量前 25 名";
		case 12: szLargeString = ""COL_GOLD"玩家\t"COL_GOLD"货运\n", szSmallString = "货运总量前 25 名";
		case 13: szLargeString = ""COL_GOLD"玩家\t"COL_GOLD"任务\n", szSmallString = "飞行任务前 25 名";
	}

	for ( new row = 0; row < rows; row ++ )
	{
		// get name
		cache_get_field_content( row, "NAME", name );

		// format item appropriately
		switch ( highscore_item )
		{
			case 0:
			{
				new Float: score_value = cache_get_field_content_float( row, "SCORE_VAL", dbHandle );
				new rank = GetRankFromXP( score_value );

				new seasonal_rank[ 16 ];
				GetSeasonalRankName( rank, seasonal_rank );

				format( szLargeString, sizeof( szLargeString ), "%s%s%s\t{%06x}%s\n", szLargeString, strmatch( name, ReturnPlayerName( playerid ) ) ? COL_GREEN : COL_WHITE, name, GetSeasonalRankColour( rank ) >>> 8, seasonal_rank );
			}
			default:
			{
				new
					score_value = cache_get_field_content_int( row, "SCORE_VAL", dbHandle );

				format( szLargeString, sizeof( szLargeString ), "%s%s%s\t%d\n", szLargeString, strmatch( name, ReturnPlayerName( playerid ) ) ? COL_GREEN : COL_WHITE, name, score_value );
			}
		}
	}
	return ShowPlayerDialog( playerid, DIALOG_HIGHSCORES_BACK, DIALOG_STYLE_TABLIST_HEADERS, sprintf( "{FFFFFF}排行榜 - %s", szSmallString ), szLargeString, "关闭", "返回" ), 1;
}