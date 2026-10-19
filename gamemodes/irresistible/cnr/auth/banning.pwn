/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\auth\banning.pwn
 * Purpose: module associated with player banning components
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Hooks ** */
hook OnPlayerConnect( playerid )
{
    static
        Query[ 200 ];

	// Ultra fast queries...
	mysql_format( dbHandle, Query, sizeof( Query ), "SELECT * FROM `BANS` WHERE (`NAME`='%e' OR `IP`='%e') AND `SERVER`=0 LIMIT 0,1", ReturnPlayerName( playerid ), ReturnPlayerIP( playerid ) );
	mysql_tquery( dbHandle, Query, "Banning_CheckPlayerBan", "i", playerid );
    return 1;
}

/* ** SQL Threads ** */
thread Banning_CheckPlayerBan( playerid )
{
	new
		rows = cache_get_row_count( );

	if ( rows )
	{
	    new
			bannedUser[ 24 ],
			bannedIP[ 16 ],
			bannedbyUser[ 24 ],
			bannedReason[ 50 ],
			//bannedSerial[ 41 ],
			bannedExpire = 0,
			server = 1,
			serial = 0
		;

		server  	 = cache_get_field_content_int( 0, "SERVER", dbHandle );
		bannedExpire = cache_get_field_content_int( 0, "EXPIRE", dbHandle );

		cache_get_field_content( 0, "BANBY", bannedbyUser );
		cache_get_field_content( 0, "REASON", bannedReason );
		//cache_get_field_content( 0, "SERIAL", bannedSerial );
		cache_get_field_content( 0, "NAME", bannedUser );
		cache_get_field_content( 0, "IP", bannedIP );

		/*gpci( playerid, szNormalString, 41 );
		if ( strmatch( bannedSerial, szNormalString ) )
		{
			serial = 1;
			format( szBigString, sizeof( szBigString ), "[%s %s] %s => {%s, %s, %s, %s, %s}\n\r", getCurrentDate( ), getCurrentTime( ), ReturnPlayerName( playerid ), bannedbyUser, bannedReason, bannedSerial, bannedUser, bannedIP );
			AddFileLogLine( "gpcid.txt", szBigString );
		}*/

		// CNR BANS ONLY
		if ( ! server )
		{
			if ( !bannedExpire )
			{
				// "COL_ORANGE"Ban evading will be fatal to your account. Do not do it.
				format( szLargeString, 600, "{FFFFFF}你已被此服务器封禁.\n{FFFFFF}如有异议, 请前往以下地址申诉: "COL_BLUE""#SERVER_WEBSITE"{FFFFFF}\n\n"COL_RED"用户名:{FFFFFF} %s\n"COL_RED"IP 地址:{FFFFFF} %s\n", bannedUser, bannedIP );
				format( szLargeString, 600, "%s"COL_RED"原因:{FFFFFF} %s\n"COL_RED"服务器:{FFFFFF} %s\n"COL_RED"禁止者:{FFFFFF} %s%s", szLargeString, bannedReason, GetServerName( server ), bannedbyUser, strmatch( ReturnPlayerName( playerid ), bannedUser ) ? ("") : ( serial ? ("\n\n"COL_RED"我们的禁令规避系统找到了你!如果这是错误的,请访问我们的论坛.") : ("\n\n"COL_RED"你的 IP 地址已被封禁,如果这是问题,请访问我们的论坛.") ) );
                ShowPlayerDialog( playerid, DIALOG_BANNED, DIALOG_STYLE_MSGBOX, "{FFFFFF}封禁信息", szLargeString, "确定", "" );
		      	KickPlayerTimed( playerid );
		  		return 1;
			}
			else
			{
				if ( GetServerTime( ) > bannedExpire )
				{
					SendServerMessage( playerid, "此账号的停权期限已结束, 现在可以继续游戏." );
					mysql_format( dbHandle, szNormalString, 100, "DELETE FROM `BANS` WHERE `NAME`= '%e' OR `IP` = '%e'", ReturnPlayerName( playerid ), ReturnPlayerIP( playerid ) );
                    mysql_single_query( szNormalString );
				}
				else
				{
					format( szLargeString, 700, "{FFFFFF}此账号已被暂停使用.\n{FFFFFF}如有异议, 请前往以下地址申诉: "COL_BLUE""#SERVER_WEBSITE"{FFFFFF}\n\n"COL_RED"用户名:{FFFFFF} %s\n"COL_RED"IP 地址:{FFFFFF} %s\n", bannedUser, bannedIP );
					format( szLargeString, 700, "%s"COL_RED"原因:{FFFFFF} %s\n"COL_RED"服务器:{FFFFFF} %s\n"COL_RED"暂停人:{FFFFFF} %s\n"COL_RED"过期时间:{FFFFFF} %s%s", szLargeString, bannedReason, GetServerName( server ), bannedbyUser, secondstotime( bannedExpire - GetServerTime( ) ), strmatch( ReturnPlayerName( playerid ), bannedUser ) ? (" ") : ("\n\n"COL_RED"你的 IP 地址已被暂停,如果这是问题,请访问我们的论坛.") );
                    ShowPlayerDialog( playerid, DIALOG_BANNED, DIALOG_STYLE_MSGBOX, "{FFFFFF}停权信息", szLargeString, "确定", "" );
		      		KickPlayerTimed( playerid );
			  		return 1;
			  	}
			}
		}
		else
        {
            SendClientMessageToAdmins( -1, ""COL_PINK"[ADMIN]"COL_GREY" %s(%d) has been identified as banned under %s.", ReturnPlayerName( playerid ), playerid, bannedbyUser );
        }
	}
	return CallLocalFunction( "OnPlayerPassedBanCheck", "d", playerid ), 1;
}

thread OnAdvanceBanCheck( playerid, szBannedBy[ ], szReason[ ], szIP[ ], lol_time )
{
	static szPlayerNameBanned[ MAX_PLAYER_NAME ], szSerial[ 41 ];

	gpci( playerid, szSerial, sizeof( szSerial ) );
	GetPlayerName( playerid, szPlayerNameBanned, MAX_PLAYER_NAME );

	new rows = cache_get_row_count( );

	if ( rows )
	{
		SendClientMessageToAdmins( -1, ""COL_PINK"[ADMIN]"COL_GREY" Edited ban entry for %s to "#SERVER_NAME".", szPlayerNameBanned );
		mysql_format( dbHandle, szBigString, 72, "UPDATE `BANS` SET `SERVER`=0 WHERE `NAME`='%e'", szPlayerNameBanned );
		mysql_single_query( szBigString );
	}
	else
	{
		new
			enabled = IsProxyEnabledForPlayer( playerid );

		if ( ! enabled )
		{
			mysql_format( dbHandle, szLargeString, sizeof( szLargeString ), "INSERT INTO `BANS`(`NAME`,`IP`,`REASON`,`BANBY`,`DATE`,`EXPIRE`,`SERVER`,`SERIAL`) VALUES ('%e','%e','%e','%e',%d,%d,0,'%e')", szPlayerNameBanned, szIP, szReason, szBannedBy, GetServerTime( ), lol_time, szSerial );
		}
		else
		{
			// include country why not
			mysql_format( dbHandle, szLargeString, sizeof( szLargeString ), "INSERT INTO `BANS`(`NAME`,`IP`,`REASON`,`BANBY`,`DATE`,`EXPIRE`,`SERVER`,`SERIAL`,`COUNTRY`) VALUES ('%e','%e','%e','%e',%d,%d,0,'%e','%e')", szPlayerNameBanned, szIP, szReason, szBannedBy, GetServerTime( ), lol_time, szSerial, GetPlayerCountryCode( playerid ) );
		}

		mysql_single_query( szLargeString );
	}
	return KickPlayerTimed( playerid ), 1;
}

/* ** Functions ** */
stock AdvancedBan( playerid, szBannedBy[ ], szReason[ ], szIP[ ], lol_time=0 )
{
	static
		szPlayerNameBanned[ MAX_PLAYER_NAME ];

	GetPlayerName( playerid, szPlayerNameBanned, MAX_PLAYER_NAME );

	mysql_format( dbHandle, szNormalString, sizeof( szNormalString ), "SELECT `NAME` FROM `BANS` WHERE `NAME` = '%e' LIMIT 0,1", szPlayerNameBanned );
	mysql_tquery( dbHandle, szNormalString, "OnAdvanceBanCheck", "isssi", playerid, szBannedBy, szReason, szIP, lol_time );
}

stock KickPlayerTimed( playerid )
	return SetTimerEx( "KickPlayer", 500, false, "d", playerid );

function KickPlayer( playerid )
	return SetPVarInt( playerid, "banned_connection", 1 ), Kick( playerid );