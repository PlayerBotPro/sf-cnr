/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: irresistible\cnr\features\player\bank.pwn
 * Purpose: banking system for players
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Macros ** */
#define GetPlayerTotalCash(%0)  	( GetPlayerBankMoney( %0 ) + GetPlayerCash( %0 ) ) // Bank Money and Money

/* ** Variables ** */
static stock p_BankMoney            [ MAX_PLAYERS ];

/* ** Forwards ** */
forward OnPlayerBankMoneyChanged    ( playerid, amount );

/* ** Hooks ** */
hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
    if ( dialogid == DIALOG_BANK_MENU && response )
	{
	    if ( IsPlayerJailed( playerid ) )
            return SendError( playerid, "在监狱中无法使用此功能." );

        switch( listitem )
		{
            case 0:
            {
                format( szBigString, sizeof( szBigString ), "{FFFFFF}输入你愿意从银行帐户中提取的金额.\n\n"COL_GREY"当前余额:"COL_WHITE" %s", cash_format( GetPlayerBankMoney( playerid ) ) );
                ShowPlayerDialog( playerid, DIALOG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{FFFFFF}个人帐户", szBigString, "取款", "返回" );
            }
            case 1:
            {
                format( szBigString, sizeof( szBigString ), "{FFFFFF}在下方输入你愿意存入银行帐户的金额.\n\n"COL_GREY"当前余额:"COL_WHITE" %s", cash_format( GetPlayerBankMoney( playerid ) ) );
                ShowPlayerDialog( playerid, DIALOG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{FFFFFF}个人帐户", szBigString, "订金", "返回" );
            }
            case 2:
            {
                format( szBigString, sizeof( szBigString ), ""COL_GREY"当前余额:"COL_WHITE" %s\n"COL_GREY"当前货币:{FFFFFF} %s", cash_format( GetPlayerBankMoney( playerid ) ), cash_format( GetPlayerCash( playerid ) ) );
                ShowPlayerDialog( playerid, DIALOG_BANK_INFO, DIALOG_STYLE_MSGBOX, "{FFFFFF}个人帐户", szBigString, "好的", "返回" );
            }
            // ... cases 3, 4, 5 handled in cnr\features\gangs\gbank.pwn
        }
        return 1;
    }
    else if ( dialogid == DIALOG_BANK_WITHDRAW )
	{
	    if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "在监狱中无法使用此功能." );
        if ( ! response ) return ShowPlayerBankMenuDialog( playerid );

        new
            money_withdraw[ 24 ];

        format( money_withdraw, sizeof( money_withdraw ), "%s", inputtext );

        if ( strmatch( money_withdraw, "MAX" ) || strmatch( money_withdraw, "ALL" ) ) {
            format( money_withdraw, sizeof( money_withdraw ), "%d", GetPlayerBankMoney( playerid ) );
        }

        if ( ! strlen( money_withdraw ) )
        {
            format( szBigString, sizeof( szBigString ), "{FFFFFF}输入你愿意从银行帐户中提取的金额.\n\n"COL_RED"输入的金额无效!\n\n"COL_GREY"当前余额:"COL_WHITE" %s", cash_format( GetPlayerBankMoney( playerid ) ) );
            ShowPlayerDialog( playerid, DIALOG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{FFFFFF}个人帐户", szBigString, "取款", "返回" );
        }
        else if ( ! IsNumeric( money_withdraw ) ) {
            format( szBigString, sizeof( szBigString ), "{FFFFFF}输入你愿意从银行帐户中提取的金额.\n\n"COL_RED"输入的金额无效!\n\n"COL_GREY"当前余额:"COL_WHITE" %s", cash_format( GetPlayerBankMoney( playerid ) ) );
            ShowPlayerDialog( playerid, DIALOG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{FFFFFF}个人帐户", szBigString, "取款", "返回" );
        }
        else if ( strval( money_withdraw ) > 99999999 || strval( money_withdraw ) <= 0 )
        {
            format( szBigString, sizeof( szBigString ), "{FFFFFF}输入你愿意从银行帐户中提取的金额.\n\n"COL_RED"输入的金额无效!\n\n"COL_GREY"当前余额:"COL_WHITE" %s", cash_format( GetPlayerBankMoney( playerid ) ) );
            ShowPlayerDialog( playerid, DIALOG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{FFFFFF}个人帐户", szBigString, "取款", "返回" );
        }
        else if ( strval( money_withdraw ) > GetPlayerBankMoney( playerid ) ) {
            format( szBigString, sizeof( szBigString ), "{FFFFFF}输入你愿意从银行帐户中提取的金额.\n\n"COL_RED"余额不足,提现失败.\n\n"COL_GREY"当前余额:"COL_WHITE" %s", cash_format( GetPlayerBankMoney( playerid ) ) );
            ShowPlayerDialog( playerid, DIALOG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{FFFFFF}个人帐户", szBigString, "取款", "返回" );
        }
        else
        {
            new iWithdraw = strval( money_withdraw );
            GivePlayerBankMoney( playerid, -iWithdraw );
            GivePlayerCash( playerid, iWithdraw );
            format( szBigString, sizeof( szBigString ), ""COL_GREY"提取金额:"COL_WHITE" %s\n"COL_GREY"当前余额:"COL_WHITE" %s\n"COL_GREY"当前货币:{FFFFFF} %s", cash_format( iWithdraw ), cash_format( GetPlayerBankMoney( playerid ) ), cash_format( GetPlayerCash( playerid ) ) );
            ShowPlayerDialog( playerid, DIALOG_BANK_INFO, DIALOG_STYLE_MSGBOX, "{FFFFFF}个人帐户", szBigString, "好的", "返回" );
        }
        return 1;
    }
    else if ( dialogid == DIALOG_BANK_DEPOSIT )
	{
	    if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "在监狱中无法使用此功能." );

        if ( response )
        {
        	new
        		money_deposit[ 24 ];

        	format( money_deposit, sizeof( money_deposit ), "%s", inputtext );

            // quick deposite feature
        	if ( strmatch( money_deposit, "MAX" ) || strmatch( money_deposit, "ALL" ) ) {
                format( money_deposit, sizeof( money_deposit ), "%d", GetPlayerCash( playerid ) );
            }

            // validate amount
            if ( !strlen( money_deposit ) ) {
                format( szBigString, sizeof( szBigString ), "{FFFFFF}在下方输入你愿意存入银行帐户的金额.\n\n"COL_RED"输入的金额无效!\n\n"COL_GREY"当前余额:"COL_WHITE" %s", cash_format( GetPlayerBankMoney( playerid ) ) );
                ShowPlayerDialog( playerid, DIALOG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{FFFFFF}个人帐户", szBigString, "订金", "返回" );
            }
            else if ( ! IsNumeric( money_deposit ) ) {
                format( szBigString, sizeof( szBigString ), "{FFFFFF}在下方输入你愿意存入银行帐户的金额.\n\n"COL_RED"输入的金额无效!\n\n"COL_GREY"当前余额:"COL_WHITE" %s", cash_format( GetPlayerBankMoney( playerid ) ) );
                ShowPlayerDialog( playerid, DIALOG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{FFFFFF}个人帐户", szBigString, "订金", "返回" );
            }
            else if ( strval( money_deposit ) > GetPlayerCash( playerid ) ) {
                format( szBigString, sizeof( szBigString ), "{FFFFFF}在下方输入你愿意存入银行帐户的金额.\n\n"COL_RED"余额不足,因此存款失败.\n\n"COL_GREY"当前余额:"COL_WHITE" %s", cash_format( GetPlayerBankMoney( playerid ) ) );
                ShowPlayerDialog( playerid, DIALOG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{FFFFFF}个人帐户", szBigString, "订金", "返回" );
            }
            else if ( strval( money_deposit ) > 99999999 || strval( money_deposit ) <= 0 )
            {
                format( szBigString, sizeof( szBigString ), "{FFFFFF}在下方输入你愿意存入银行帐户的金额.\n\n"COL_RED"输入的金额无效!\n\n"COL_GREY"当前余额:"COL_WHITE" %s", cash_format( GetPlayerBankMoney( playerid ) ) );
                ShowPlayerDialog( playerid, DIALOG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{FFFFFF}个人帐户", szBigString, "订金", "返回" );
            }
            else
            {
                new iDeposit = strval( money_deposit );
                GivePlayerBankMoney( playerid, iDeposit );
                GivePlayerCash( playerid, -iDeposit );
                format( szBigString, sizeof( szBigString ), ""COL_GREY"存入金额:"COL_WHITE" %s\n"COL_GREY"当前余额:"COL_WHITE" %s\n"COL_GREY"当前货币:{FFFFFF} %s", cash_format( iDeposit ), cash_format( GetPlayerBankMoney( playerid ) ), cash_format( GetPlayerCash( playerid ) ) );
                ShowPlayerDialog( playerid, DIALOG_BANK_INFO, DIALOG_STYLE_MSGBOX, "{FFFFFF}个人帐户", szBigString, "好的", "返回" );
            }
        }
        else ShowPlayerBankMenuDialog( playerid );
    }
    else if ( ( dialogid == DIALOG_BANK_INFO || dialogid == DIALOG_GANG_BANK_INFO ) && !response )
    {
	    if ( IsPlayerJailed( playerid ) )
            return SendError( playerid, "在监狱中无法使用此功能." );

  		return ShowPlayerBankMenuDialog( playerid );
    }
    return 1;
}

hook OnPlayerDisconnect( playerid, reason ) {
    p_BankMoney[ playerid ] = 0;
    return 1;
}

/* ** Callbacks ** */
public OnPlayerBankMoneyChanged( playerid, amount )
{
    // save player bank money on each monetary movement
    if ( IsPlayerLoggedIn( playerid ) )
    {
        mysql_single_query( sprintf( "UPDATE `USERS` SET `BANKMONEY` = %d WHERE `ID` = %d", GetPlayerBankMoney( playerid ), GetPlayerAccountID( playerid ) ) );
    }
    return 1;
}

/* ** Functions ** */
stock GetPlayerBankMoney( playerid ) {
    return p_BankMoney[ playerid ];
}

stock SetPlayerBankMoney( playerid, money ) {
	p_BankMoney[ playerid ] = money;
}

stock GivePlayerBankMoney( playerid, money ) {
	p_BankMoney[ playerid ] += money;
    CallRemoteFunction( "OnPlayerBankMoneyChanged", "dd", playerid, money );
}

stock ShowPlayerBankMenuDialog( playerid )
{
	if ( ! ShowPlayerGangBankMenuDialog( playerid ) ) {
	    return ShowPlayerDialog( playerid, DIALOG_BANK_MENU, DIALOG_STYLE_LIST, "{FFFFFF}帐户", "提款\n存款\n账户信息", "选择", "取消" );
    } else {
        return 1;
    }
}