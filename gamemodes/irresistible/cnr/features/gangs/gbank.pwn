/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: irresistible\cnr\features\gangs\gbank.pwn
 * Purpose: banking system for gangs
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Hooks ** */
hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
    if ( dialogid == DIALOG_BANK_MENU && response )
	{
		new
			gangid = p_GangID[ playerid ];

	    if ( IsPlayerJailed( playerid ) )
            return SendError( playerid, "在监狱中无法使用此功能." );

		if ( gangid == INVALID_GANG_ID && listitem > 2 )
            return SendError( playerid, "你不属于任何帮派!" );

        switch( listitem )
		{
            case 3:
            {
                format( szBigString, sizeof( szBigString ), "{FFFFFF}输入你愿意从帮派银行帐户中提取的金额.\n\n"COL_GREY"当前余额:"COL_WHITE" %s", cash_format( g_gangData[ gangid ] [ E_BANK ] ) );
                ShowPlayerDialog( playerid, DIALOG_GANG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{FFFFFF}帮派账户", szBigString, "取款", "返回" );
            }
           	case 4:
            {
                format( szBigString, sizeof( szBigString ), "{FFFFFF}在下面输入你愿意存入你的帮派银行帐户的金额.\n\n"COL_GREY"当前余额:"COL_WHITE" %s", cash_format( g_gangData[ gangid ] [ E_BANK ] ) );
                ShowPlayerDialog( playerid, DIALOG_GANG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{FFFFFF}帮派账户", szBigString, "订金", "返回" );
            }
            case 5:
            {
                format( szBigString, sizeof( szBigString ), ""COL_GREY"当前余额:"COL_WHITE" %s\n"COL_GREY"当前货币:{FFFFFF} %s", cash_format( g_gangData[ gangid ] [ E_BANK ] ), cash_format( GetPlayerCash( playerid ) ) );
                ShowPlayerDialog( playerid, DIALOG_GANG_BANK_INFO, DIALOG_STYLE_MSGBOX, "{FFFFFF}帮派账户", szBigString, "好的", "返回" );
            }
        }
        return 1;
    }
	else if ( dialogid == DIALOG_GANG_BANK_WITHDRAW )
	{
		if ( !response )
			return ShowPlayerBankMenuDialog( playerid );

		new
			iWithdraw,
			gangid = p_GangID[ playerid ]
		;

		if ( gangid == INVALID_GANG_ID )
			return SendError( playerid, "你必须在帮派中才能使用此功能." );

	    if ( IsPlayerJailed( playerid ) )
            return SendError( playerid, "在监狱中无法使用此功能." );

	    if ( ! IsPlayerGangLeader( playerid, gangid ) )
            return ShowPlayerBankMenuDialog( playerid ), SendError( playerid, "你必须是帮派头目才能使用此功能." );

		if ( strmatch( inputtext, "MAX" ) || strmatch( inputtext, "ALL" ) )
		{
			iWithdraw = g_gangData[ gangid ] [ E_BANK ];
		}
	  	else if ( sscanf( inputtext, "d", iWithdraw ) )
	    {
		    format( szBigString, sizeof( szBigString ), "{FFFFFF}输入你愿意从帮派银行帐户中提取的金额.\n\n"COL_RED"输入的金额无效!\n\n"COL_GREY"当前余额:"COL_WHITE" %s", cash_format( g_gangData[ gangid ] [ E_BANK ] ) );
            return ShowPlayerDialog( playerid, DIALOG_GANG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{FFFFFF}帮派账户", szBigString, "取款", "返回" );
	    }

	    // double check quantity
		if ( iWithdraw > 99999999 || iWithdraw <= 0 )
        {
            format( szBigString, sizeof( szBigString ), "{FFFFFF}输入你愿意从帮派银行帐户中提取的金额.\n\n"COL_RED"输入的金额无效!\n\n"COL_GREY"当前余额:"COL_WHITE" %s", cash_format( g_gangData[ gangid ] [ E_BANK ] ) );
            ShowPlayerDialog( playerid, DIALOG_GANG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{FFFFFF}帮派账户", szBigString, "取款", "返回" );
        }
        else if ( iWithdraw > g_gangData[ gangid ] [ E_BANK ] )
        {
            format( szBigString, sizeof( szBigString ), "{FFFFFF}输入你愿意从帮派银行帐户中提取的金额.\n\n"COL_RED"余额不足,提现失败.\n\n"COL_GREY"当前余额:"COL_WHITE" %s", cash_format( g_gangData[ gangid ] [ E_BANK ] ) );
            ShowPlayerDialog( playerid, DIALOG_GANG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{FFFFFF}帮派账户", szBigString, "取款", "返回" );
        }
        else
        {
            g_gangData[ gangid ] [ E_BANK ] -= iWithdraw;
            GivePlayerCash( playerid, iWithdraw );
            SaveGangData( gangid );

			// transaction
	    	format( szNormalString, sizeof( szNormalString ), "INSERT INTO `TRANSACTIONS` (`TO_ID`, `FROM_ID`, `CASH`, `NATURE`) VALUES (%d, %d, %d, 'gang withdraw')", p_AccountID[ playerid ], g_gangData[ gangid ] [ E_SQL_ID ], iWithdraw );
	     	mysql_single_query( szNormalString );

	     	// withdraw
            SendClientMessageToGang( gangid, g_gangData[ gangid ] [ E_COLOR ], "[帮派]"COL_GREY" %s(%d) 已从帮派银行账户中提取 %s.", ReturnPlayerName( playerid ), playerid, cash_format( iWithdraw ), "%%" );
            format( szBigString, sizeof( szBigString ), ""COL_GREY"提取金额:"COL_WHITE" %s\n"COL_GREY"当前余额:"COL_WHITE" %s\n"COL_GREY"当前货币:{FFFFFF} %s", cash_format( iWithdraw ), cash_format( g_gangData[ gangid ] [ E_BANK ] ), cash_format( GetPlayerCash( playerid ) ) );
            ShowPlayerDialog( playerid, DIALOG_GANG_BANK_INFO, DIALOG_STYLE_MSGBOX, "{FFFFFF}帮派账户", szBigString, "好的", "返回" );
        }
        return 1;
    }
	else if ( dialogid == DIALOG_GANG_BANK_DEPOSIT )
	{
		if ( ! response )
			return ShowPlayerBankMenuDialog( playerid );

		if ( ! IsPlayerSecurityVerified( playerid ) )
			return SendError( playerid, "使用此功能需要先验证账号. "COL_YELLOW"(输入 /verify)" );

		new
			iDeposit,
			gangid = p_GangID[ playerid ]
		;

		if ( gangid == INVALID_GANG_ID )
			return SendError( playerid, "你必须在帮派中才能使用此功能." );

	    if ( IsPlayerJailed( playerid ) )
            return SendError( playerid, "在监狱中无法使用此功能." );

		if ( strmatch( inputtext, "MAX" ) || strmatch( inputtext, "ALL" ) )
		{
			iDeposit = GetPlayerCash( playerid );
		}
        else if ( sscanf( inputtext, "d", iDeposit ) )
        {
            format( szBigString, sizeof( szBigString ), "{FFFFFF}在下面输入你愿意存入你的帮派银行帐户的金额.\n\n"COL_RED"输入的金额无效!\n\n"COL_GREY"当前余额:"COL_WHITE" %s", cash_format( g_gangData[ gangid ] [ E_BANK ] ) );
            ShowPlayerDialog( playerid, DIALOG_GANG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{FFFFFF}帮派账户", szBigString, "订金", "返回" );
        }

	    // double check
     	if ( iDeposit > 99999999 || iDeposit < 1 )
        {
            format( szBigString, sizeof( szBigString ), "{FFFFFF}在下面输入你愿意存入你的帮派银行帐户的金额.\n\n"COL_RED"输入的金额无效!\n\n"COL_GREY"当前余额:"COL_WHITE" %s", cash_format( g_gangData[ gangid ] [ E_BANK ] ) );
            ShowPlayerDialog( playerid, DIALOG_GANG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{FFFFFF}帮派账户", szBigString, "订金", "返回" );
        }
        else if ( iDeposit > GetPlayerCash( playerid ) )
        {
            format( szBigString, sizeof( szBigString ), "{FFFFFF}在下面输入你愿意存入你的帮派银行帐户的金额.\n\n"COL_RED"余额不足,因此存款失败.\n\n"COL_GREY"当前余额:"COL_WHITE" %s", cash_format( g_gangData[ gangid ] [ E_BANK ] ) );
            ShowPlayerDialog( playerid, DIALOG_GANG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{FFFFFF}帮派账户", szBigString, "订金", "返回" );
        }
        else
        {
            g_gangData[ gangid ] [ E_BANK ] += iDeposit;
            GivePlayerCash( playerid, -iDeposit );
            SaveGangData( gangid );

			// transaction
	    	format( szNormalString, sizeof( szNormalString ), "INSERT INTO `TRANSACTIONS` (`TO_ID`, `FROM_ID`, `CASH`, `NATURE`) VALUES (%d, %d, %d, 'gang deposit')", p_AccountID[ playerid ], g_gangData[ gangid ] [ E_SQL_ID ], iDeposit );
	     	mysql_single_query( szNormalString );

	     	// deposit
            SendClientMessageToGang( gangid, g_gangData[ gangid ] [ E_COLOR ], "[帮派]"COL_GREY" %s(%d) 已将 %s 存入帮派银行账户.", ReturnPlayerName( playerid ), playerid, cash_format( iDeposit ) );
            format( szBigString, sizeof( szBigString ), ""COL_GREY"存入金额:"COL_WHITE" %s\n"COL_GREY"当前余额:"COL_WHITE" %s\n"COL_GREY"当前货币:{FFFFFF} %s", cash_format( iDeposit ), cash_format( g_gangData[ gangid ] [ E_BANK ] ), cash_format( GetPlayerCash( playerid ) ) );
            ShowPlayerDialog( playerid, DIALOG_GANG_BANK_INFO, DIALOG_STYLE_MSGBOX, "{FFFFFF}帮派账户", szBigString, "好的", "返回" );
        }
        return 1;
    }
    return 1;
}

/* ** Functions ** */
stock ShowPlayerGangBankMenuDialog( playerid )
{
	new
		gangid = p_GangID[ playerid ];

	if ( gangid != -1 && Iter_Contains( gangs, gangid ) ) {
		format( szBigString, sizeof( szBigString ), "提款\n存款\n账户信息\n{%06x}帮行提款\n{%06x}帮行存款\n{%06x}帮行余额", g_gangData[ gangid ] [ E_COLOR ] >>> 8, g_gangData[ gangid ] [ E_COLOR ] >>> 8, g_gangData[ gangid ] [ E_COLOR ] >>> 8 );
		return ShowPlayerDialog( playerid, DIALOG_BANK_MENU, DIALOG_STYLE_LIST, "{FFFFFF}帐户", szBigString, "选择", "取消" );
	} else {
        return 0;
    }
}
