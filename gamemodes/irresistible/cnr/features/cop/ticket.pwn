/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\cop\ticket.pwn
 * Purpose: ticketing system for police
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Variables ** */
static stock
  	p_TicketTimestamp  				[ MAX_PLAYERS ],
   	p_TicketIssuer           		[ MAX_PLAYERS ] = { INVALID_PLAYER_ID, ... }
;

/* ** Hooks ** */
hook OnPlayerDisconnect( playerid, reason )
{
	p_TicketIssuer[ playerid ] = INVALID_PLAYER_ID;
	p_TicketTimestamp[ playerid ] = 0;
    return 1;
}

#if defined AC_INCLUDED
hook OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
hook OnPlayerDeath( playerid, killerid, reason )
#endif
{
	p_TicketIssuer[ playerid ] = INVALID_PLAYER_ID;
	p_TicketTimestamp[ playerid ] = 0;
    return 1;
}

hook OnPlayerUpdateEx( playerid )
{
    // Failed to pay ticket
    if ( p_TicketTimestamp[ playerid ] != 0 && g_iTime > p_TicketTimestamp[ playerid ] )
    {
        // inform user
        SendServerMessage( playerid, "你拒付罚单, 已成为通缉犯." );
        SendClientMessageToCops( -1, ""COL_BLUE"[犯罪]"COL_WHITE" %s(%d) 拒绝支付罚单.", ReturnPlayerName( playerid ), playerid );

        // remove ticket
        p_TicketTimestamp[ playerid ] = 0;
        p_TicketIssuer[ playerid ] = INVALID_PLAYER_ID;
        GivePlayerWantedLevel( playerid, 6 );
    }
    return 1;
}

hook OnPlayerJailed( playerid )
{
	p_TicketIssuer[ playerid ] = INVALID_PLAYER_ID;
	p_TicketTimestamp[ playerid ] = 0;
    return 1;
}

/* ** Variables ** */
CMD:tk( playerid, params[ ] ) return cmd_ticket( playerid, params );
CMD:ticket( playerid, params[ ] )
{
   	new
   		pID = GetClosestPlayer( playerid );

	TicketPlayer( pID, playerid );
	SendServerMessage( playerid, "按鼠标中键可向附近的玩家开罚单." );
	return 1;
}

CMD:payticket( playerid, params[] )
{
	if ( !p_WantedLevel[ playerid ] )
		return SendError( playerid, "你没有通缉等级, 无需支付罚单." );

	if ( p_WantedLevel[ playerid ] > 5 )
		return SendError( playerid, "你的通缉等级过高, 无法通过罚单清除." );

	if ( !p_TicketTimestamp[ playerid ] )
		return SendError( playerid, "你没有待支付的罚单!" );

	if ( GetPlayerCash( playerid ) < 2000 )
		return SendError( playerid, "你的钱不够支付罚单." );

	new
		copid = p_TicketIssuer[ playerid ];

	// remove ticket
	p_TicketTimestamp[ playerid ] = 0;
	p_TicketIssuer[ playerid ] = INVALID_PLAYER_ID;

	// remove wanted level
	GivePlayerCash( playerid, -2000 );
	GivePlayerWantedLevel( playerid, -6 );
	SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[罚单]{FFFFFF} 你已经付款 "COL_GOLD"$2,000{FFFFFF} 的罚款." );

	// pay cop
	if ( IsPlayerConnected( copid ) ) {
		GivePlayerScore( copid, 2 );
		GivePlayerCash( copid, 1500 );
		GivePlayerExperience( copid, E_POLICE, 0.5 );
		GameTextForPlayer( copid, "~n~~g~~h~罚单已支付!", 2000, 4 );
		SendClientMessageFormatted( copid, -1, ""COL_GREEN"[罚单]{FFFFFF} %s(%d) 支付了罚单, 你获得了"COL_GOLD"$1,500{FFFFFF}!", ReturnPlayerName( playerid ), playerid );
	}
	return 1;
}

/* ** Functions ** */
stock TicketPlayer( pID, playerid )
{
	if ( p_Class[ playerid ] != CLASS_POLICE ) return SendError( playerid, "此功能仅限警察使用." );
	else if ( GetDistanceBetweenPlayers( playerid, pID ) > 10.0 || !IsPlayerConnected( pID ) ) return SendError( playerid, "附近没有可开罚单的玩家." );
	else if ( p_TicketIssuer[ pID ] == playerid ) return SendError( playerid, "你已经给此玩家开过罚单." );
	else if ( p_Class[ pID ] == CLASS_POLICE ) return SendError( playerid, "此玩家与你同阵营!" );
	else if ( p_WantedLevel[ pID ] > 5 ) return SendError( playerid, "此玩家的罪行过重, 请直接逮捕." );
	else if ( p_WantedLevel[ pID ] < 1 ) return SendError( playerid, "不能向无辜玩家开罚单." );
	else if ( p_Jailed{ playerid } ) return SendError( playerid, "你不能在监狱中使用此命令." );
	else if ( IsPlayerDetained( pID ) ) return SendError( playerid, "此玩家已被管理员监禁, 无法进行此操作." );
	else if ( g_iTime < p_TicketTimestamp[ pID ] ) return SendError( playerid, "此玩家已经入狱, 将在 %d 秒后获释.", g_iTime - p_TicketTimestamp[ pID ] );
	else
	{
		if ( p_AdminOnDuty{ pID } == true ) return SendError( playerid, "这是值班管理员!" );
		if ( IsPlayerJailed( pID ) ) return SendError( playerid, "此玩家已入狱, 可能处于暂停状态." );
		if ( IsPlayerTied( pID ) ) return SendError( playerid, "此玩家已被捆绑, 手铐已解除, 无法向其开罚单." );
		if ( GetPlayerState( pID ) == PLAYER_STATE_WASTED ) return SendError( playerid, "不能向挂机玩家开罚单." );

	    p_TicketTimestamp[ pID ] = g_iTime + 15;
	    p_TicketIssuer[ pID ] = playerid;

		GameTextForPlayer( pID, "~n~~r~收到罚单!~n~~w~/payticket", 2000, 4 );
		SendClientMessageFormatted( pID, -1, ""COL_RED"[罚单]{FFFFFF} 你已获得 "COL_GOLD"$2,000{FFFFFF} 的罚单, 开单警员: %s(%d), 原因是近期的犯罪活动!", ReturnPlayerName( playerid ), playerid );
		SendClientMessageFormatted( pID, -1, ""COL_RED"[罚单]{FFFFFF} 你有 15 秒时间输入"COL_GREY"/payticket"COL_WHITE"支付罚单, 否则将视为拒捕并被通缉." );
		SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[罚单]{FFFFFF} 你开出了一张罚单, 金额"COL_GOLD"$2,000{FFFFFF}, 对象: %s(%d)!", ReturnPlayerName( pID ), pID );
	}
	return 1;
}