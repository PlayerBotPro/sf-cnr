/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\cop\bail.pwn
 * Purpose: bail system for criminals
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define BAIL_DOLLARS_PER_SECOND     ( 50 )

/* ** Variables ** */
static stock p_BailOfferer          [ MAX_PLAYERS ] = { INVALID_PLAYER_ID, ... };

/* ** Commands ** */
CMD:bail( playerid, params[ ] )
{
	new
	    pID,
	    equa
	;

	if ( p_Class[ playerid ] != CLASS_POLICE ) return SendError( playerid, "此功能仅限警察使用." );
	else if ( sscanf( params, "u", pID ) ) return SendUsage( playerid, "/bail [PLAYER_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "玩家 ID 无效." );
	else if ( pID == playerid ) return SendError( playerid, "你不能为自己提供保释服务." );
	else if ( !IsPlayerJailed( pID ) ) return SendError( playerid, "此玩家没有入狱." );
	else if ( IsPlayerAdminJailed( pID ) ) return SendError( playerid, "此玩家已被管理员监禁." );
	else if ( IsPlayerSettingToggled( pID, SETTING_BAILOFFERS ) ) return SendError( playerid, "此玩家已关闭保释通知." );
	else if ( GetPVarInt( pID, "bail_antispam" ) > g_iTime ) return SendError( playerid, "你必须等待 10 秒才能向该玩家提供保释." );
	else
	{
		equa = floatround( float( BAIL_DOLLARS_PER_SECOND * p_JailTime[ pID ] ) * ( 1.0 - GetPlayerLevel( pID, E_POLICE ) / 125.0 ) );
		if ( p_JailTime[ pID ] >= ALCATRAZ_TIME_WANTED ) equa *= 2;
		p_BailOfferer[ pID ] = playerid;
		p_BailTimestamp[ pID ] = g_iTime + 120;
		SetPVarInt( pID, "bail_antispam", g_iTime + 1 );
		SendServerMessage( playerid, "你向 %s(%d) 提供了保释服务, 费用"COL_GOLD"%s", ReturnPlayerName( pID ), pID, cash_format( equa ) );
		SendClientMessageFormatted( pID, -1, ""COL_GREY"[服务器]"COL_WHITE" %s(%d) 愿意为你提供保释服务, 费用"COL_GOLD"%s"COL_WHITE". "COL_ORANGE"/acceptbail"COL_WHITE"接受保释服务.", ReturnPlayerName( playerid ), playerid, cash_format( equa ) );
	}
	return 1;
}

CMD:acceptbail( playerid, params[ ] )
{
	new
		equa = floatround( float( BAIL_DOLLARS_PER_SECOND * p_JailTime[ playerid ] ) * ( 1.0 - GetPlayerLevel( playerid, E_POLICE ) / 125.0 ) );

	if ( p_JailTime[ playerid ] >= ALCATRAZ_TIME_WANTED )
		equa *= 2;

	if ( GetPlayerCash( playerid ) < equa ) return p_BailOfferer[ playerid ] = INVALID_PLAYER_ID, SendError( playerid, "你的钱不够支付保释费用." );
	else if ( IsPlayerAdminJailed( playerid ) ) return p_BailOfferer[ playerid ] = INVALID_PLAYER_ID, SendError( playerid, "你已被管理员监禁, 无法使用此功能." );
	else if ( !IsPlayerJailed( playerid ) ) return SendError( playerid, "你没有入狱!" );
	else if ( !IsPlayerConnected( p_BailOfferer[ playerid ] ) ) return p_BailOfferer[ playerid ] = INVALID_PLAYER_ID, SendError( playerid, "提供保释服务的玩家已离线." );
	else if ( p_BailTimestamp[ playerid ] < g_iTime ) return p_BailOfferer[ playerid ] = INVALID_PLAYER_ID, SendError( playerid, "此保释服务已超过一分钟, 已失效." );
	else
	{
		new
			cashEarned = floatround( equa * 0.70 );

		GivePlayerCash( playerid, -equa );
		GivePlayerCash( p_BailOfferer[ playerid ], cashEarned );
		StockMarket_UpdateEarnings( E_STOCK_GOVERNMENT, cashEarned, 0.1 );
		SendClientMessageFormatted( p_BailOfferer[ playerid ], -1, ""COL_GREEN"[保释]"COL_WHITE" %s(%d) 支付了保释费, 你赚取了"COL_GOLD"%s"COL_WHITE"的保释服务收入.", ReturnPlayerName( playerid ), playerid, cash_format( cashEarned ) );
    	p_BailOfferer[ playerid ] = INVALID_PLAYER_ID;
        SendServerMessage( playerid, "你已支付保释费用, 现在自由了!" );
	   	CallLocalFunction( "OnPlayerUnjailed", "dd", playerid, 1 );
	}
	return 1;
}

/* ** Hooks ** */
hook OnPlayerDisconnect( playerid, reason )
{
	p_BailOfferer[ playerid ] = INVALID_PLAYER_ID;
    return 1;
}