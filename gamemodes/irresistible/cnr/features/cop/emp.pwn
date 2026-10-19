/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: \cnr\features\cop\emp.pwn
 * Purpose: handle vehicle emp
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Commands ** */
CMD:emp( playerid, params[ ] )
{
	new
		pID
	;
	if ( p_Class[ playerid ] != CLASS_POLICE ) return SendError( playerid, "此功能仅限警察使用." );
	else if ( p_inCIA{ playerid } == false || p_inArmy{ playerid } == true ) return SendError( playerid, "这仅限于 CIA." );
	else if ( sscanf( params, "u", pID ) ) return SendUsage( playerid, "/emp [PLAYER_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "玩家 ID 无效." );
	else if ( pID == playerid ) return SendError( playerid, "你不能对自己进行此操作." );
	else if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "被绑架时无法进行此操作." );
	else if ( IsPlayerTied( playerid ) ) return SendError( playerid, "被捆绑时无法进行此操作." );
	else if ( IsPlayerAdminOnDuty( pID ) ) return SendError( playerid, "此玩家是值勤中的管理员!" );
    else if ( IsPlayerAdminOnDuty( playerid ) ) return SendError( playerid, "AOD 时无法使用此命令." );
	else if ( p_Class[ pID ] == CLASS_POLICE ) return SendError( playerid, "此玩家属于执法阵营." );
	else if ( !p_WantedLevel[ pID ] ) return SendError( playerid, "这个人是无辜的!" );
	else if ( !IsPlayerInAnyVehicle( pID ) ) return SendError( playerid, "该玩家不在任何车辆内." );
	else if ( GetPlayerState( pID ) != PLAYER_STATE_DRIVER ) return SendError( playerid, "该玩家不是任何车辆的驾驶员." );
    else if ( GetDistanceBetweenPlayers( playerid, pID ) < 30.0 )
	{
	    /* ** ANTI EMP SPAM ** */
	    if ( p_AntiEmpSpam[ pID ] > g_iTime )
            return SendError( playerid, "对此玩家使用 EMP 还需等待 %s.", secondstotime( p_AntiEmpSpam[ pID ] - g_iTime ) );
	    /* ** END OF ANTI SPAM ** */

	    new
	    	iVehicle = GetPlayerVehicleID( pID );

		if ( g_buyableVehicle{ iVehicle } )
			return SendError( playerid, "未能对该玩家的载具施加电磁脉冲." );

		p_AntiEmpSpam[ pID ] = g_iTime + 60;

	    if ( p_AntiEMP[ pID ] > 0 )
	    {
		    p_AntiEMP[ pID ] --;

		    new
		    	iRandom = random( 101 );

	    	if ( iRandom < 90 )
	    	{
		        SendClientMessage( playerid, -1, ""COL_RED"[EMP]{FFFFFF} 电磁脉冲被铝箔挡下了!" );
				SendClientMessage( pID, -1, ""COL_GREEN"[EMP]{FFFFFF} 载具上的铝箔挡下了电磁脉冲." );
				p_QuitToAvoidTimestamp[ pID ] = g_iTime + 15;
	    		return 1;
	    	}
	    }

        SendClientMessageFormatted( pID, -1, ""COL_RED"[EMP]{FFFFFF} %s(%d) 对你的载具施加了电磁脉冲, 载具将瘫痪 30 秒.", ReturnPlayerName( playerid ), playerid );
		SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[EMP]{FFFFFF} 你对 %s(%d) 的载具施加了电磁脉冲!", ReturnPlayerName( pID ), pID );
		p_QuitToAvoidTimestamp[ pID ] = g_iTime + 15;
		SetTimerEx( "emp_deactivate", 30000, false, "d", GetPlayerVehicleID( pID ) );
		GetVehicleParamsEx( iVehicle, engine, lights, alarm, doors, bonnet, boot, objective );
		SetVehicleParamsEx( iVehicle, VEHICLE_PARAMS_OFF, lights, alarm, doors, bonnet, boot, objective );
	}
	else SendError( playerid, "该玩家不在附近." );
	return 1;
}

CMD:demp( playerid, params[ ] ) return cmd_disableemp(playerid, params);
CMD:disableemp( playerid, params[ ] )
{
    if ( p_Class[ playerid ] != CLASS_POLICE ) return SendError( playerid, "此功能仅限警察使用." );
	else if ( p_inCIA{ playerid } == false || p_inArmy{ playerid } == true ) return SendError( playerid, "这仅限于 CIA." );
	else if ( IsPlayerTied( playerid ) ) return SendError( playerid, "被捆绑时无法进行此操作." );
	else if ( !IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "你不在任何车辆中." );
    
    new
        iVehicle = GetPlayerVehicleID( playerid );

    GetVehicleParamsEx( iVehicle, engine, lights, alarm, doors, bonnet, boot, objective );

    if ( engine != VEHICLE_PARAMS_OFF ) return SendError( playerid, "此载具未受电磁脉冲影响.");

    SetVehicleParamsEx( iVehicle, VEHICLE_PARAMS_ON, lights, alarm, doors, bonnet, boot, objective );

    return SendServerMessage( playerid, "你成功重启了载具." );
}

function emp_deactivate( vehicleid )
{
	if ( !IsValidVehicle( vehicleid ) ) return 0;
	GetVehicleParamsEx( vehicleid, engine, lights, alarm, doors, bonnet, boot, objective );
	SetVehicleParamsEx( vehicleid, VEHICLE_PARAMS_ON, lights, alarm, doors, bonnet, boot, objective );
	return 1;
}