/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\vip\redeem_code.pwn
 * Purpose: code redemption system for newly donating donors
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Error Checking ** */
#if !defined __cnr__irresistiblecoins
	#endinput
#endif

/* ** Definitions ** */
#define szRedemptionSalt 			"7resta#ecacakumedeM=yespawr!d@et"

/* ** Variables ** */
enum E_DONATION_DATA
{
	E_TRANSACTION_ID[ 17 ],
	E_NAME[ 24 ],
	E_AMOUNT[ 11 ],
	E_PURPOSE[ 64 ],
	E_DATE
};

static stock g_redeemVipWait 		= 0;
static stock g_TopDonorWall 		= INVALID_OBJECT_ID;
stock Text: g_TopDonorTD            = Text: INVALID_TEXT_DRAW;

/* ** Forwards ** */
forward OnDonationRedemptionResponse( index, response_code, data[ ] );

/* ** Hooks ** */
hook OnScriptInit( )
{
	// Server Variables
	AddServerVariable( "donation_goal_amount", "250.0", GLOBAL_VARTYPE_FLOAT );

	// Wall of Donors
	SetDynamicObjectMaterialText( CreateDynamicObject( 3074, -1574.3559, 885.1296, 28.4690, 0.0000, 0.0000, -0.0156 ), 0, "谢谢每月捐助者", 130, "Times New Roman", 64, 1, -65536, 0, 1 );
	SetDynamicObjectMaterialText( ( g_TopDonorWall = CreateDynamicObject( 3074, -1574.3559, 885.1296, 14.0153, 0.0000, 0.0000, -0.0156 ) ), 0, "没有人捐款:(", 130, "Arial", 48, 0, -65536, 0, 1 );

    // Latest Donor TD
	g_TopDonorTD = TextDrawCreate(320.000000, 2.000000, "顶级捐助者 " SERVER_OPERATOR " -$0.00, ~w~~h~~h~最新捐赠者 " SERVER_OPERATOR " - $0.00");
	TextDrawAlignment(g_TopDonorTD, 2);
	TextDrawBackgroundColor(g_TopDonorTD, 0);
	TextDrawFont(g_TopDonorTD, 1);
	TextDrawLetterSize(g_TopDonorTD, 0.139999, 0.799999);
	TextDrawColor(g_TopDonorTD, -2347265);
	TextDrawSetOutline(g_TopDonorTD, 1);
	TextDrawSetProportional(g_TopDonorTD, 1);
	return 1;
}

hook OnServerVariablesLoaded( )
{
	UpdateGlobalDonated( );
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_VIP && response )
	{
		if ( strlen( inputtext ) != 16 )
		{
			cmd_donated( playerid, "" );
			return SendError( playerid, "你输入的交易 ID 无效." );
		}

		if ( g_redeemVipWait > g_iTime )
		{
			cmd_donated( playerid, "" );
			return SendServerMessage( playerid, "我们的反漏洞利用系统要求你在兑换前再等待 %d 秒.", g_redeemVipWait - g_iTime );
		}

		HTTP( playerid, HTTP_GET, sprintf( "donate.sfcnr.com/validate_code/%s", inputtext ), "", "OnDonationRedemptionResponse" );
		SendServerMessage( playerid, "我们现在正在查找这笔交易.请稍候." );
        return 1;
	}
	else if ( dialogid == DIALOG_DONATED )
	{
		szLargeString[ 0 ] = '\0';
		strcat( szLargeString,	""COL_WHITE"非常感谢你的捐赠! :D 作为对你尊严的回报,你已收到 IC 代币.\n\n"\
								""COL_GREY" * 我该怎么处理 IC 代币?"COL_WHITE" 你可以通过以下方式认领你选择的 VIP "COL_GREY"/irresistiblecoins market"COL_WHITE".\n" );
		strcat( szLargeString,	""COL_GREY" * 我有多少?"COL_WHITE" 你可以通过以下方式查看你有多少 IC 代币 "COL_GREY"/irresistiblecoins"COL_WHITE".\n" \
								""COL_GREY" * 我不确定,有帮助吗?"COL_WHITE" 如有疑问, 请输入 /ask 联系管理员, 或咨询" SERVER_OPERATOR " 通过论坛!\n\n再次感谢你对我们社区的贡献! :P"  );
		return ShowPlayerDialog( playerid, DIALOG_FINISHED_DONATING, DIALOG_STYLE_MSGBOX, ""COL_GOLD"SF-CNR 捐赠", szLargeString, "明白了!", "" );
	}
	else if ( dialogid == DIALOG_FINISHED_DONATING )
    {
		return ShowPlayerDialog( playerid, DIALOG_LATEST_DONOR, DIALOG_STYLE_MSGBOX, ""COL_GOLD"SF-CNR 捐赠", ""COL_WHITE"你想被显示为最新的捐赠者吗?", "是", "否" );
	}
	else if ( dialogid == DIALOG_LATEST_DONOR )
    {
		if ( GetPVarType( playerid, "just_donated" ) != PLAYER_VARTYPE_FLOAT )
			return SendError( playerid, "似乎是一个问题,我们无法找到你捐赠了多少.报告至 " SERVER_OPERATOR "." );

		new
			Float: fAmount = GetPVarFloat( playerid, "just_donated" );

		DeletePVar( playerid, "just_donated" );
		return UpdateGlobalDonated( playerid, fAmount, !response );
	}
    return 1;
}

/* ** Callbacks ** */
public OnDonationRedemptionResponse( index, response_code, data[ ] )
{
    if ( response_code == 200 )
    {
		if ( strmatch( data, "{FFFFFF}Unable to identify transaction." ) ) ShowPlayerDialog( index, DIALOG_NULL, DIALOG_STYLE_MSGBOX, ""COL_GOLD"SF-CNR 捐赠", data, "确定", "" );
		else
		{
			static aDonation[ E_DONATION_DATA ];
			sscanf( data, "p<|>e<s[17]s[24]s[11]s[64]d>", aDonation );

			// printf("donation {id:%s, name:%s, amount:%s, purpose:%s, date:%d}", aDonation[ E_TRANSACTION_ID ],aDonation[ E_NAME ],aDonation[ E_AMOUNT ],aDonation[ E_PURPOSE ],aDonation[ E_DATE ]);
			if ( strfind( aDonation[ E_PURPOSE ], "San Fierro: Cops And Robbers" ) == -1 ) {
				ShowPlayerDialog( index, DIALOG_NULL, DIALOG_STYLE_MSGBOX, ""COL_GOLD"SF-CNR 捐赠", ""COL_WHITE"此捐赠并非专门用于该服务器,因此你无法检索任何内容.", "确定", "" );
				return 0;
			}

			// SELECT * FROM `REDEEMED` WHERE `ID` = MD5('%s7resta#ecacakumedeM=yespawr!d@et') LIMIT 0,1
			mysql_format( dbHandle, szNormalString, sizeof( szNormalString ), "SELECT * FROM `REDEEMED` WHERE `ID` = MD5('%e%s') LIMIT 0,1", aDonation[ E_TRANSACTION_ID ], szRedemptionSalt );
	 		mysql_tquery( dbHandle, szNormalString, "OnCheckForRedeemedVIP", "is", index, data );
		}
	}
 	else
    {
        return ShowPlayerDialog( index, DIALOG_NULL, DIALOG_STYLE_MSGBOX, ""COL_GOLD"SF-CNR 捐赠", ""COL_WHITE"无法连接到捐赠数据库.请稍后重试.", "确定", "" );
    }
    return 1;
}

/* ** SQL Threads ** */
thread OnCheckForRedeemedVIP( playerid, data[ ] )
{
	static
		aDonation[ E_DONATION_DATA ],
	    rows, fields
	;
    cache_get_data( rows, fields );

	if ( rows )
	{
		static
			szName[ MAX_PLAYER_NAME ];

		cache_get_field_content( 0, "REDEEMER", szName );
		ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, ""COL_GOLD"SF-CNR 捐赠", sprintf( ""COL_WHITE"抱歉,该交易 ID 已被 %s 兑换.", szName ), "确定", "" );
	}
	else
	{
		g_redeemVipWait = g_iTime + 10;

		sscanf( data, "p<|>e<s[17]s[24]s[11]s[64]d>", aDonation );

		mysql_format( dbHandle, szNormalString, sizeof( szNormalString ), "INSERT INTO `REDEEMED`(`ID`, `REDEEMER`) VALUES (MD5('%e%s'), '%e')", aDonation[ E_TRANSACTION_ID ], szRedemptionSalt, ReturnPlayerName( playerid ) );
		mysql_single_query( szNormalString );

		//printf( "%s\n%s | %s | %f | %s | %d", data, aDonation[ E_TRANSACTION_ID ], aDonation[ E_EMAIL ], floatstr( aDonation[ E_AMOUNT ] ), aDonation[ E_PURPOSE ], aDonation[ E_DATE ]);

		new
			Float: fAmount = floatstr( aDonation[ E_AMOUNT ] ),
			Float: iCoins = fAmount * ( 1 + GetGVarFloat( "vip_bonus" ) ) * 100.0
		;

		if ( p_Uptime[ playerid ] > 604800 )
		{
			if ( fAmount < 1.99999 )
				return SendError( playerid, "感谢你的捐赠!由于这笔捐款低于 $2.00 美元,因此没有发行任何硬币." );
		}
		else
		{
			if ( fAmount < 4.99999 )
				return SendError( playerid, "感谢你的捐赠!由于这笔捐款低于 $5.00 美元,因此尚未发行任何硬币." );
		}

		GivePlayerIrresistibleCoins( playerid, iCoins );
		SetPVarFloat( playerid, "just_donated", fAmount );

		SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[VIP 套餐]"COL_WHITE" 你已经收到%0.0f IC 代币!感谢你捐赠 %s!!! :D", iCoins, ReturnPlayerName( playerid ) );

		format( szBigString, 256, ""COL_GREY"交易 ID:\t"COL_WHITE"%s\n"COL_GREY"捐助者姓名:\t"COL_WHITE"%s\n"COL_GREY"金额:\t"COL_WHITE"$%0.2f\n"COL_GREY"总金币:\t"COL_WHITE"%0.0f\n"COL_GREY"前时间:\t"COL_WHITE"%s",
				aDonation[ E_TRANSACTION_ID ], aDonation[ E_NAME ], floatstr( aDonation[ E_AMOUNT ] ), iCoins, secondstotime( g_iTime - aDonation[ E_DATE ] ) );

		ShowPlayerDialog( playerid, DIALOG_DONATED, DIALOG_STYLE_MSGBOX, ""COL_GOLD"SF-CNR 捐赠", szBigString, "继续", "" );
	}
	return 1;
}

thread OnGrabLatestDonor( hidden )
{
	new
		rows = cache_get_row_count( );

	if ( rows )
	{
		static
			szName[ MAX_PLAYER_NAME ];

		cache_get_field_content( 0, "NAME", szName );

		new Float: last_donation = cache_get_field_content_float( 0, "LAST_AMOUNT", dbHandle );
		new Float: total_donations = cache_get_field_content_float( 0, "TOTAL_DONATIONS", dbHandle );

		new Float: funding_goal = GetServerVariableFloat( "donation_goal_amount" );

		// make this optional
		if ( funding_goal > 0.0 ) {
			new Float: funding_goal_percent = total_donations / funding_goal * 100.0;

			// Prevents total revenue for the month being disclosed mathematically
			if ( funding_goal_percent >= 100.0 ) {
				TextDrawSetString( g_TopDonorTD, sprintf( "最新捐助者 %s - $%0.2f,~g~ 月已全额资助 %0.2f%%!", szName, last_donation, 100.0 ) );
			} else {
				TextDrawSetString( g_TopDonorTD, sprintf( "最新捐助者 %s - $%0.2f,~r~ 月仅 %0.2f%% 提供资金!", szName, last_donation, funding_goal_percent ) );
			}
		} else {
			TextDrawSetString( g_TopDonorTD, sprintf( "最新捐赠者 %s - $%0.2f", szName, last_donation ) );
		}

		// Play song!
		if ( ! hidden ) {
			GameTextForAll( sprintf( "~y~~h~~h~新捐赠者!~n~~w~%s", szName ), 6000, 3 );

			// Play sound
			foreach(new p : Player) if ( !IsPlayerUsingRadio( p ) ) {
				PlayAudioStreamForPlayer( p, "http://files.sfcnr.com/game_sounds/donated.mp3" );
			}
		}
	}
	else
	{
		TextDrawSetString( g_TopDonorTD, "没有人捐款:(" );
	}
	return 1;
}

thread OnUpdateWallOfDonors( )
{
	new
		rows;

    cache_get_data( rows, tmpVariable );

	if( rows )
	{
		new
			szString[ 600 ],
			iLine = 1,
			iPosition = 0;

		for( new row = 0; row < rows; row++ )
		{
			new
				szName[ MAX_PLAYER_NAME ];

			cache_get_field_content( row, "NAME", szName );

			new
				iOldLength = strlen( szString ) + 4; // 4 is an offset

			if( iOldLength - iPosition > 24 ) {
				iPosition = iOldLength;
				strcat( szString, "\n" ), iLine ++;
			}

			// The wall of donors
			format( szString, sizeof( szString ), "%s%s, ", szString, szName );
		}

		// The wall of donors formatting
		new
			iLength = strlen( szString );

		strdel( szString, iLength - 2, iLength );

		// Develop a size and format
		SetDynamicObjectMaterialText( g_TopDonorWall, 0, szString, 130, "Arial", floatround( 48.0 * floatpower( 0.925, iLine - 1 ), floatround_ceil ), 0, -65536, 0, 1 );
	}
	else
	{
		SetDynamicObjectMaterialText( g_TopDonorWall, 0, "没有人捐款:(", 130, "Arial", 48, 0, -65536, 0, 1 );
	}
	return 1;
}

/* ** Commands ** */
CMD:redeemvip( playerid, params[ ] ) return cmd_donated( playerid, params );
CMD:donated( playerid, params[ ] )
{
	ShowPlayerDialog( playerid, DIALOG_VIP, DIALOG_STYLE_INPUT, ""COL_GOLD"SF-CNR 捐赠", ""COL_WHITE"在下面输入你捐赠的交易 ID.\n\n"COL_GREY"有关详细信息,请参阅 http://forum.sfcnr.com/showthread.php?10125.", "兑换", "关闭" );
	return 1;
}

/* ** RCON Commands ** */
CMD:updatedonategoal( playerid, params[ ] )
{
	new
		Float: donation_goal;

	if ( ! IsPlayerAdmin( playerid ) && ! IsPlayerLeadMaintainer( playerid ) ) return 0;
	else if ( sscanf( params, "f", donation_goal ) ) return SendUsage( playerid, "/updatedonationreq [DONATION_GOAL_AMOUNT]" );
	else if ( ! ( 0.0 <= donation_goal < 10000.0 ) ) return SendError( playerid, "捐赠目标金额必须介于 $0 和 $10,000. 之间" );
	else
	{
		new
			Float: previous_goal = GetServerVariableFloat( "donation_goal_amount" );

		UpdateGlobalDonated( .hidden = 1 );
		SendServerMessage( playerid, "将捐赠目标从 $%s 更新为 $%s!", number_format( previous_goal, .decimals = 2 ), number_format( donation_goal, .decimals = 2 ) );
		UpdateServerVariableFloat( "donation_goal_amount", donation_goal );
	}
	return 1;
}

CMD:updatedonortd( playerid, params[ ] )
{
	new
		targetid, Float: amount, reset;

	if ( ! IsPlayerAdmin( playerid ) && ! IsPlayerLeadMaintainer( playerid ) ) return 0;
	else if ( sscanf( params, "D(0)D(65535)F(0.0)", reset, targetid, amount ) ) return SendUsage( playerid, "/updatedonortd [RESET] [PLAYER_ID] [AMOUNT]" );
	else
	{
		// Reset the top donor
		if ( reset ) {
			TextDrawSetString( g_TopDonorTD, "没有人捐款:(" );
		}

		// Update it incase
		UpdateGlobalDonated( targetid, amount );
		SendServerMessage( playerid, "立即更新最新捐赠者(玩家 ID %d,金额 %f)", targetid, amount );
	}
	return 1;
}

/* ** Functions ** */
static stock UpdateGlobalDonated( playerid = INVALID_PLAYER_ID, Float: amount = 0.0, hidden = 0 )
{
	if ( playerid != INVALID_PLAYER_ID && amount > 0.0 ) {
		format( szBigString, sizeof( szBigString ), "INSERT INTO `TOP_DONOR` (`USER_ID`,`AMOUNT`,`LAST_AMOUNT`,`TIME`,`HIDE`) VALUES(%d,%f,%f,%d,%d) ON DUPLICATE KEY UPDATE `AMOUNT`=`AMOUNT`+%f,`LAST_AMOUNT`=%f,`TIME`=%d,`HIDE`=%d;", p_AccountID[ playerid ], amount, amount, g_iTime, hidden, amount, amount, g_iTime, hidden );
		mysql_single_query( szBigString );
	}

	// top donor
	mysql_tquery( dbHandle, "SELECT `NAME`,`LAST_AMOUNT`,(SELECT SUM(`AMOUNT`) FROM `TOP_DONOR`) AS `TOTAL_DONATIONS` FROM `TOP_DONOR` LEFT JOIN `USERS` ON `TOP_DONOR`.`USER_ID`=`USERS`.`ID` WHERE `LAST_AMOUNT` > 0 AND `HIDE` < 1 ORDER BY `TIME` DESC LIMIT 1", "OnGrabLatestDonor", "d", hidden );

	// wall of donors
	mysql_tquery( dbHandle, "SELECT `USERS`.`NAME` FROM `TOP_DONOR` INNER JOIN `USERS` ON `TOP_DONOR`.`USER_ID`=`USERS`.`ID` WHERE `HIDE` < 1 ORDER BY `AMOUNT` DESC, `TIME` DESC", "OnUpdateWallOfDonors", "" );
	return 1;
}
