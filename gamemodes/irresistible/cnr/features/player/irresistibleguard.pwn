/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\irresistibleguard.pwn
 * Purpose: provides account protection in the form of email securing
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Configuration ** */
#define DISABLE_FREE_VIP

/* ** Definitions ** */
#define SECURITY_MODE_MILD					( 0 )
#define SECURITY_MODE_PARANOID				( 1 )
#define SECURITY_MODE_DISABLED				( 2 )

/* ** Variables ** */
enum E_IRRESISTIBLE_GUARD
{
	E_ID,						E_EMAIL[ 64 ],					E_MODE,
	bool: E_VERIFIED,			E_LAST_DISABLED
};

new
	p_accountSecurityData		[ MAX_PLAYERS ] [ E_IRRESISTIBLE_GUARD ]
;

/* ** Hooks ** */
hook OnPlayerDisconnect( playerid, reason )
{
	p_accountSecurityData[ playerid ] [ E_VERIFIED ] = false;
	p_accountSecurityData[ playerid ] [ E_ID ] = 0;
	p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] = 0;
	return 1;
}

hook OnPlayerLogin( playerid )
{
	format( szNormalString, sizeof( szNormalString ), "SELECT * FROM `EMAILS` WHERE `USER_ID`=%d", GetPlayerAccountID( playerid ) );
	mysql_function_query( dbHandle, szNormalString, true, "OnEmailLoad", "d", playerid );
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_ACC_GUARD && response )
	{
		if ( p_accountSecurityData[ playerid ] [ E_ID ] && ! p_accountSecurityData[ playerid ] [ E_VERIFIED ] && p_accountSecurityData[ playerid ] [ E_MODE ] != SECURITY_MODE_DISABLED )
			return SendError( playerid, "你必须经过验证才能使用此功能." );

		switch ( listitem )
		{
			case 0:
			{
				if ( p_accountSecurityData[ playerid ] [ E_ID ] )
					return SendError( playerid, "你的电子邮件已确认!" ), ShowPlayerAccountGuard( playerid ), 1;

				format( szNormalString, sizeof( szNormalString ), "SELECT * FROM `EMAILS` WHERE `USER_ID`=%d", p_AccountID[ playerid ] );
	    		mysql_function_query( dbHandle, szNormalString, true, "OnEmailConfirm", "d", playerid );
			}
			case 1: ShowPlayerDialog( playerid, DIALOG_ACC_GUARD_MODE, DIALOG_STYLE_TABLIST, "{FFFFFF}不可抗拒的守卫-模式", "轻度\t"COL_GREY"交易前必须验证 IP\n严格防护\t"COL_GREY"登录后必须验证 IP\n禁用\t"COL_GREY"没有任何形式的验证", "选择", "返回" );
			case 2:
			{
				format( szBigString, sizeof( szBigString ), "SELECT * FROM `EMAILS` WHERE `ID`=%d", p_accountSecurityData[ playerid ] [ E_ID ] );
				mysql_function_query( dbHandle, szBigString, true, "OnAccountGuardDelete", "d", playerid );
			}
		#if !defined DISABLE_FREE_VIP
			case 3:
			{
				if ( p_AddedEmail{ playerid } )
					return SendError( playerid, "你之前已将电子邮件添加到你的帐户." );

				if ( GetPlayerScore( playerid ) < 1000 )
					return SendServerMessage( playerid, "至少获取 1000 分数,然后使用此功能." );

				Beep( playerid );
				p_AddedEmail{ playerid } = true;
				SetPlayerVipLevel( playerid, VIP_REGULAR, .interval = 259560, .credit_assets = false ); // 3 days of vip
				mysql_single_query( sprintf( "UPDATE `USERS` SET `USED_EMAIL`=1 WHERE `ID`=%d", p_AccountID[ playerid ] ) );
				SendGlobalMessage( COLOR_GOLD, "[邮箱已确认]"COL_GREY" %s(%d)已经确认了他们的 "COL_GOLD"/email"COL_GREY" 并收到 3 天的 VIP!", ReturnPlayerName( playerid ), playerid );
 				return 1;
			}
		#endif
		}
		return 1;
	}
	else if ( dialogid == DIALOG_ACC_GUARD_CONFIRM )
	{
		if ( ! response )
		{
			if ( p_accountSecurityData[ playerid ] [ E_MODE ] == SECURITY_MODE_PARANOID ) {
				return Kick( playerid );
			}

			// allow other modes
			return 1;
		}

		static
			szInput[ 10 ];

		format( szInput, sizeof( szInput ), "%s", inputtext );
		trimString( szInput ); // gotta take out the whitespace

		if ( strlen( szInput ) != 8 )
			return SendError( playerid, "验证码必须是 8 个字符." ), ShowPlayerAccountVerification( playerid );

		mysql_format( dbHandle, szBigString, sizeof( szBigString ), "SELECT * FROM `USER_CONFIRMED_IPS` WHERE `USER_ID`=%d AND `IP`='%e' AND `TOKEN`='%e'", p_AccountID[ playerid ], ReturnPlayerIP( playerid ), szInput );
		mysql_function_query( dbHandle, szBigString, true, "OnAccountGuardVerify", "d", playerid );
		return 1;
	}
	else if ( dialogid == DIALOG_ACC_GUARD_DEL_CANCEL )
	{
		if ( !response )
			return ShowPlayerAccountGuard( playerid );

		p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] = 0;
		mysql_single_query( sprintf( "UPDATE `EMAILS` SET `LAST_CHANGED`=%d,`LAST_DISABLED`=0 WHERE `ID`=%d", g_iTime, p_accountSecurityData[ playerid ] [ E_ID ] ) );
		return SendServerMessage( playerid, "你已取消移除不可抗拒守卫的过程." );
	}
	else if ( dialogid == DIALOG_ACC_GUARD_MODE )
	{
		if ( !response )
			return ShowPlayerAccountGuard( playerid );

		if ( ! p_accountSecurityData[ playerid ] [ E_ID ] )
			return SendError( playerid, "你需要为你的帐户分配一个电子邮件." );

		p_accountSecurityData[ playerid ] [ E_MODE ] = listitem;
		mysql_single_query( sprintf( "UPDATE `EMAILS` SET `MODE`=%d WHERE `ID`=%d", listitem, p_accountSecurityData[ playerid ] [ E_ID ] ) );
		SendServerMessage( playerid, "你的不可抗拒守卫模式现已设置为 "COL_GREY"%s"COL_WHITE".", SecurityModeToString( listitem ) );
		return ShowPlayerAccountGuard( playerid );
	}
	else if ( dialogid == DIALOG_ACC_GUARD_EMAIL && response )
	{
		new
			email[ 64 ];

		if ( sscanf( inputtext, "s[64]", email ) )
			return SendError( playerid, "你的电子邮件长度必须在 4 到 64 个字符之间." );

		if ( ! ( 3 < strlen( email ) < 64 ) )
			return SendError( playerid, "你的电子邮件长度必须在 4 到 64 个字符之间." );

		if ( ! regex_match( email, "[a-zA-Z0-9_\\.]+@([a-zA-Z0-9\\-]+\\.)+[a-zA-Z]{2,4}" ) )
			return SendError( playerid, "你的电子邮件必须有效 (foo@example.com)." );

	    format( szBigString, sizeof( szBigString ), "INSERT INTO `EMAIL_VERIFY`(`USER_ID`, `EMAIL`) VALUES (%d, '%s') ON DUPLICATE KEY UPDATE `EMAIL`='%s',`DATE`=CURRENT_TIMESTAMP", p_AccountID[ playerid ], mysql_escape( email ), mysql_escape( email ) );
	    mysql_function_query( dbHandle, szBigString, true, "OnQueueEmailVerification", "ds", playerid, email );
		return 1;
	}
	return 1;
}

/* ** SQL Threads ** */
thread OnQueueEmailVerification( playerid, email[ ] )
{
	new
		verification_id = cache_insert_id( );

	// alert
	SendServerMessage( playerid, "一封电子邮件已发送至 "COL_GREY"%s"COL_WHITE" 包含确认你的帐户的说明.", email );

	// sending an email
	format( szLargeString, sizeof( szLargeString ), "<p>你好 %s,你收到这封电子邮件是因为你想要将 Irresistible Guard 添加到你的帐户.</p><p><a href='http://" # MAILING_URL "/email/verify/%d/%d'>点击此处验证你的电子邮件</a></p>", ReturnPlayerName( playerid ), p_AccountID[ playerid ], verification_id );
	SendMail( email, ReturnPlayerName( playerid ), sprintf( "验证你的帐户,%s", ReturnPlayerName( playerid ) ), szLargeString );
	return 1;
}

thread OnAccountGuardVerify( playerid )
{
	new
	    rows, fields;

    cache_get_data( rows, fields );

	if ( rows )
	{
		new
			userConfirmedIpId = cache_get_field_content_int( 0, "ID", dbHandle );

		p_accountSecurityData[ playerid ] [ E_VERIFIED ] = true;
		mysql_single_query( sprintf( "UPDATE `USER_CONFIRMED_IPS` SET `CONFIRMED`=1 WHERE `ID`=%d", userConfirmedIpId ) );

		// alert
		SendServerMessage( playerid, "你已确认你的 IP 地址.谢谢你!" );
	}
	else
	{
		SendError( playerid, "指定的验证码不正确.请再试一次." );
		ShowPlayerAccountVerification( playerid );
	}
	return 1;
}

thread OnAccountEmailVerify( playerid, login_force )
{
	new
	    rows, fields, timestamp;

    cache_get_data( rows, fields );

	if ( rows )
	{
		new
			confirmed = cache_get_field_content_int( 0, "CONFIRMED", dbHandle );

		if ( confirmed )
		{
			// verify
	    	p_accountSecurityData[ playerid ] [ E_VERIFIED ] = true;

			// alert
			return SendServerMessage( playerid, "此帐户受不可抗拒的守卫保护. "COL_GREEN"你正在玩的IP已被验证." ), 1;
		}

		// assign last time
		timestamp = cache_get_field_content_int( 0, "DATE", dbHandle );
	}

	// No point making a disabled user validate
	if ( login_force && p_accountSecurityData[ playerid ] [ E_MODE ] == SECURITY_MODE_DISABLED )
		return 1;

	// No point forcing a mild mode user to validate
	if ( login_force && p_accountSecurityData[ playerid ] [ E_MODE ] == SECURITY_MODE_MILD )
		return SendError( playerid, "此帐户受不可抗拒的守卫保护. "COL_RED"请通过你的电子邮件验证你的 IP 以进行游戏内交易." );

	if ( g_iTime - timestamp >= 300 )
	{
		new
			iRandom = RandomEx( 10000000, 99999999 );

		// insert into database
		format( szBigString, sizeof( szBigString ), "INSERT INTO `USER_CONFIRMED_IPS`(`USER_ID`,`IP`,`TOKEN`,`CONFIRMED`) VALUES (%d,'%s','%d',0) ON DUPLICATE KEY UPDATE `TOKEN`='%d',`DATE`=CURRENT_TIMESTAMP", p_AccountID[ playerid ], ReturnPlayerIP( playerid ), iRandom, iRandom );
		mysql_single_query( szBigString );

		// email
		format( szLargeString, sizeof( szLargeString ), "<p>嘿 %s,你收到这封电子邮件是因为未经授权的 IP 正在访问你的帐户.</p>"\
														"<p>IP:%s<br>国家/地区:%s(可能不准确)</p>"\
														"<p>你的验证令牌是<strong>%d</strong> - 仅供你自己使用!</p>"\
														"<p style='color: red'>如果你未授权,请在游戏中更改密码或联系管理员!</p>",
														ReturnPlayerName( playerid ), ReturnPlayerIP( playerid ), GetPlayerCountryName( playerid ), iRandom );

		SendMail( p_accountSecurityData[ playerid ] [ E_EMAIL ], ReturnPlayerName( playerid ), sprintf( "有人访问你的帐户,%s", ReturnPlayerName( playerid ) ), szLargeString );
	}
	else
	{
		SendServerMessage( playerid, "请检查你的电子邮件以获取其他令牌.可以在 %s 中生成新代码.", secondstotime( 300 - ( g_iTime - timestamp ) ) );
	}

	// force verification
	ShowPlayerAccountVerification( playerid );

	// alert
	if ( p_accountSecurityData[ playerid ] [ E_MODE ] == SECURITY_MODE_PARANOID ) {
		SendError( playerid, "此帐户受不可抗拒的守卫保护. "COL_RED"请通过你的电子邮件验证你的 IP 才能进行游戏." );
	} else if ( p_accountSecurityData[ playerid ] [ E_MODE ] == SECURITY_MODE_MILD ) {
		SendError( playerid, "此帐户受不可抗拒的守卫保护. "COL_RED"请通过你的电子邮件验证你的 IP 以进行游戏内交易." );
	}
	return 1;
}

thread OnEmailLoad( playerid )
{
	new
	    rows, fields;

    cache_get_data( rows, fields );

    if ( rows )
    {
    	p_accountSecurityData[ playerid ] [ E_VERIFIED ] = false;
    	p_accountSecurityData[ playerid ] [ E_ID ] = cache_get_field_content_int( 0, "ID", dbHandle );
    	p_accountSecurityData[ playerid ] [ E_MODE ] = cache_get_field_content_int( 0, "MODE", dbHandle );
    	p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] = cache_get_field_content_int( 0, "LAST_DISABLED", dbHandle );
    	cache_get_field_content( 0, "EMAIL", p_accountSecurityData[ playerid ] [ E_EMAIL ], dbHandle, 64 );

    	// IP Check
		format( szBigString, 196, "SELECT `CONFIRMED`,UNIX_TIMESTAMP(`DATE`) as `DATE` FROM `USER_CONFIRMED_IPS` WHERE `USER_ID`=%d AND `IP`='%s'", p_AccountID[ playerid ], mysql_escape( ReturnPlayerIP( playerid ) ) );
		mysql_function_query( dbHandle, szBigString, true, "OnAccountEmailVerify", "dd", playerid, 1 );
    }
}

thread OnEmailConfirm( playerid )
{
	new
	    rows, fields;

    cache_get_data( rows, fields );

    if ( rows )
    {
    	// fill data
    	p_accountSecurityData[ playerid ] [ E_VERIFIED ] = true;
    	p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] = 0;
    	p_accountSecurityData[ playerid ] [ E_ID ] = cache_get_field_content_int( 0, "ID", dbHandle );
    	p_accountSecurityData[ playerid ] [ E_MODE ] = cache_get_field_content_int( 0, "MODE", dbHandle );
    	cache_get_field_content( 0, "EMAIL", p_accountSecurityData[ playerid ] [ E_EMAIL ], dbHandle, 64 );

    	// log ip and alert
    	format( szNormalString, sizeof( szNormalString ), "INSERT INTO `USER_CONFIRMED_IPS`(`USER_ID`,`IP`,`CONFIRMED`) VALUES (%d,'%s',1)", p_AccountID[ playerid ], ReturnPlayerIP( playerid ) );
    	mysql_single_query( szNormalString );

    	// alert
        SendServerMessage( playerid, "你的电子邮件已确认,%s.", ReturnPlayerName( playerid ) );
    }
    else
    {
		format( szNormalString, sizeof( szNormalString ), "SELECT `EMAIL`,UNIX_TIMESTAMP(`DATE`) as `DATE` FROM `EMAIL_VERIFY` WHERE `USER_ID`=%d", p_AccountID[ playerid ] );
		mysql_function_query( dbHandle, szNormalString, true, "OnEmailVerifying", "d", playerid );
    }
	return 1;
}

thread OnEmailVerifying( playerid )
{
	new
		rows, fields, email[ 64 ];

	cache_get_data( rows, fields );

	if ( rows )
	{
		new
			timestamp = cache_get_field_content_int( 0, "DATE", dbHandle );

		if ( g_iTime - timestamp < 300 )
		{
			cache_get_field_content( 0, "EMAIL", email );
			return SendError( playerid, "一封电子邮件已发送至 "COL_GREY"%s"COL_WHITE",请在 %s 内验证.", email, secondstotime( 300 - ( g_iTime - timestamp ) ) ), 1;
		}
	}
	return ShowPlayerDialog( playerid, DIALOG_ACC_GUARD_EMAIL, DIALOG_STYLE_INPUT, "{FFFFFF}不可抗拒的守卫", ""COL_WHITE"请在下方输入邮箱. 此邮箱也可能用于发送游戏及社区活动消息.\n\n"COL_ORANGE"此功能只能每 5 分钟使用一次.", "选择", "取消" ), 1;
}

thread OnAccountGuardDelete( playerid )
{
	new
		rows, fields;

	cache_get_data( rows, fields );

	if ( !rows ) SendError( playerid, "似乎没有与你的帐户关联的电子邮件." );
	else
	{
		new
			id = cache_get_field_content_int( 0, "ID", dbHandle ),
			last_disabled = cache_get_field_content_int( 0, "LAST_DISABLED", dbHandle ),
			last_changed = cache_get_field_content_int( 0, "LAST_CHANGED", dbHandle )
		;

		if ( id != p_accountSecurityData[ playerid ] [ E_ID ] )
			return SendError( playerid, "你的电子邮件有问题.交谈 " SERVER_OPERATOR "." ), 1;

		if ( g_iTime - last_changed < 300 ) {
			return SendError( playerid, "你可以在 %s 中使用此功能.", secondstotime( 300 - ( g_iTime - last_changed ) ) );
		}

		if ( ! last_disabled )
		{
			// first time disabling
			SendServerMessage( playerid, "你现在开始从你的帐户中删除该电子邮件.这将需要 24 小时." );
			mysql_single_query( sprintf( "UPDATE `EMAILS` SET `LAST_DISABLED`=%d WHERE `ID`=%d", g_iTime + 86400, id ) );

			// email
			format( szLargeString, sizeof( szLargeString ), "<p>嘿 %s,你收到这封电子邮件是因为你正在移除不可抗拒的守卫.</p>"\
															"<p>IP:%s<br>国家/地区:%s</p>"\
															"<p style='color: red'>如果你未授权,请在游戏中更改密码或联系管理员!</p>",
															ReturnPlayerName( playerid ), ReturnPlayerIP( playerid ), GetPlayerCountryName( playerid ) );

			SendMail( p_accountSecurityData[ playerid ] [ E_EMAIL ], ReturnPlayerName( playerid ), sprintf( "你正在移除不可抗拒的守卫,%s", ReturnPlayerName( playerid ) ), szLargeString );

			// update variables
			p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] = g_iTime + 86400;
		}
		else if ( g_iTime > last_disabled )
		{
			// under process of disabling
			mysql_single_query( sprintf( "DELETE FROM `EMAILS` WHERE `USER_ID`=%d", p_AccountID[ playerid ] ) );
			mysql_single_query( sprintf( "DELETE FROM `EMAIL_VERIFY` WHERE `USER_ID`=%d", p_AccountID[ playerid ] ) );
			mysql_single_query( sprintf( "DELETE FROM `USER_CONFIRMED_IPS` WHERE `USER_ID`=%d", p_AccountID[ playerid ] ) );

			// email
			format( szLargeString, sizeof( szLargeString ), "<p>嘿 %s,你收到这封电子邮件是因为 Irresistible Guard 已从你的帐户中删除.</p>"\
															"<p>IP:%s<br>国家/地区:%s</p>"\
															"<p style='color: red'>如果你未授权,请在游戏中更改密码或联系管理员!</p>",
															ReturnPlayerName( playerid ), ReturnPlayerIP( playerid ), GetPlayerCountryName( playerid ) );

			SendMail( p_accountSecurityData[ playerid ] [ E_EMAIL ], ReturnPlayerName( playerid ), sprintf( "不可抗拒的守卫被移除,%s", ReturnPlayerName( playerid ) ), szLargeString );

			// reset variables
			p_accountSecurityData[ playerid ] [ E_VERIFIED ] = false;
			p_accountSecurityData[ playerid ] [ E_ID ] = 0;
			p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] = 0;

			// alert
			SendServerMessage( playerid, "你已成功从你的帐户中删除 Irresistible Guard." );
		}
		else
		{
			// update last disabled anyway
			p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] = last_disabled;

			// show dialog
			format( szNormalString, sizeof( szNormalString ), ""COL_WHITE"你必须再等待 %s 才能删除你的电子邮件.\n\n你希望停止此过程吗?", secondstotime( last_disabled - g_iTime ) );
			ShowPlayerDialog( playerid, DIALOG_ACC_GUARD_DEL_CANCEL, DIALOG_STYLE_MSGBOX, "{FFFFFF}不可抗拒的守卫-停止删除", szNormalString, "是", "否" );
		}
	}
	return 1;
}

/* ** Commands ** */
CMD:email( playerid, params[ ] ) {
	return ShowPlayerAccountGuard( playerid );
}

CMD:verify( playerid, params[ ] )
{
	if ( ! p_accountSecurityData[ playerid ] [ E_ID ] )
		return SendError( playerid, "你的帐户没有分配电子邮件." );

	if ( p_accountSecurityData[ playerid ] [ E_VERIFIED ] )
		return SendError( playerid, "你已经通过验证." );

	if ( p_accountSecurityData[ playerid ] [ E_MODE ] == SECURITY_MODE_DISABLED )
		return SendError( playerid, "你的安全模式已设置为禁用." );

	format( szBigString, 196, "SELECT `CONFIRMED`,UNIX_TIMESTAMP(`DATE`) as `DATE` FROM `USER_CONFIRMED_IPS` WHERE `USER_ID`=%d AND `IP`='%s'", p_AccountID[ playerid ], mysql_escape( ReturnPlayerIP( playerid ) ) );
	mysql_function_query( dbHandle, szBigString, true, "OnAccountEmailVerify", "dd", playerid, 0 );
	return 1;
}

/* ** Functions ** */
stock SecurityModeToString( modeid )
{
	static
		szMode[ 9 ];

	switch ( modeid )
	{
		case 0: szMode = "温和的";
		case 1: szMode = "偏执狂";
		case 2: szMode = "残疾人";
		default: szMode = "n/a";
	}
	return szMode;
}

stock ShowPlayerAccountGuard( playerid )
{
	if ( p_accountSecurityData[ playerid ] [ E_ID ] != 0 ) {
		if ( p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] && p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] < g_iTime ) {
			format( szBigString, sizeof( szBigString ), ""COL_WHITE"你的帐户电子邮件是 "COL_GREEN"确认\t \n确认电子邮件\t"COL_GREEN"%s\n安全模式\t%s\n"COL_RED"移除不可抗拒的守卫\t"COL_GREEN"准备好", CensoreString( p_accountSecurityData[ playerid ] [ E_EMAIL ] ), SecurityModeToString( p_accountSecurityData[ playerid ] [ E_MODE ] ) );
		} else if ( p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] ) {
			format( szBigString, sizeof( szBigString ), ""COL_WHITE"你的帐户电子邮件是 "COL_GREEN"确认\t \n确认电子邮件\t"COL_GREEN"%s\n安全模式\t%s\n"COL_ORANGE"停止待删除\t"COL_ORANGE"%s", CensoreString( p_accountSecurityData[ playerid ] [ E_EMAIL ] ), SecurityModeToString( p_accountSecurityData[ playerid ] [ E_MODE ] ), secondstotime( p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] - g_iTime ) );
		} else {
			format( szBigString, sizeof( szBigString ), ""COL_WHITE"你的帐户电子邮件是 "COL_GREEN"确认\t \n确认电子邮件\t"COL_GREEN"%s\n安全模式\t%s\n"COL_RED"移除不可抗拒的守卫\t"COL_RED"大约24小时", CensoreString( p_accountSecurityData[ playerid ] [ E_EMAIL ] ), SecurityModeToString( p_accountSecurityData[ playerid ] [ E_MODE ] ) );
		}

	#if !defined DISABLE_FREE_VIP
		// award user for adding their email
		if ( p_AddedEmail{ playerid } == false ) {
			strcat( szBigString, "\n"COL_GOLD"要求免费 3 天的常规 VIP!\t"COL_GOLD">>>" );
		}
	#endif
	} else {
		szBigString = ""COL_WHITE"你的帐户电子邮件是 "COL_RED"未确认\t \n确认电子邮件\t"COL_GREY">>>";
	}
	return ShowPlayerDialog( playerid, DIALOG_ACC_GUARD, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}不可抗拒的守卫", szBigString, "选择", "关闭" );
}

stock ShowPlayerAccountVerification( playerid )
{
	if ( p_accountSecurityData[ playerid ] [ E_MODE ] == 1 ) {
		return ShowPlayerDialog( playerid, DIALOG_ACC_GUARD_CONFIRM, DIALOG_STYLE_INPUT, "{FFFFFF}不可抗拒的守卫", ""COL_WHITE"请输入通过电子邮件发送给你的验证令牌.", "确认", "辞职" ), 1;
	} else {
		return ShowPlayerDialog( playerid, DIALOG_ACC_GUARD_CONFIRM, DIALOG_STYLE_INPUT, "{FFFFFF}不可抗拒的守卫", ""COL_WHITE"请输入通过电子邮件发送给你的验证令牌.", "确认", "关闭" ), 1;
	}
}

stock IsPlayerSecurityFullyVerified( playerid ) { // paranoid check
	return ! ( p_accountSecurityData[ playerid ] [ E_ID ] && ! p_accountSecurityData[ playerid ] [ E_VERIFIED ] && p_accountSecurityData[ playerid ] [ E_MODE ] == SECURITY_MODE_PARANOID );
}

stock IsPlayerSecurityVerified( playerid ) {
	return ! ( p_accountSecurityData[ playerid ] [ E_ID ] && ! p_accountSecurityData[ playerid ] [ E_VERIFIED ] && p_accountSecurityData[ playerid ] [ E_MODE ] != SECURITY_MODE_DISABLED );
}

stock IsPlayerEmailVerified( playerid ) {
	return p_accountSecurityData[ playerid ] [ E_ID ];
}
