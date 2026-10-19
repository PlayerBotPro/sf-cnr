/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\cop\arrest.pwn
 * Purpose: taze, cuff and arresting system for police
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Variables ** */
static const COP_ARREST_PAY_PER_WANTED = 330;
static const COP_DETAIN_PAY_PER_WANTED = 385;

/* ** Forwards ** */
forward OnPlayerArrested( playerid, victimid, totalarrests, totalpeople );

/* ** Hooks ** */
hook OnPlayerDisconnect( playerid, reason )
{
	// Quit to Avoid - Award Handling
	AwardNearestLEO( playerid, 0 );
	return 1;
}

hook OnPlayerEnterDynamicCP( playerid, checkpointid )
{
	// Detain Mechanism
	if ( checkpointid == g_Checkpoints[ CP_DROP_OFF_COP ] ||
		checkpointid == g_Checkpoints[ CP_DROP_OFF_FC ] || checkpointid == g_Checkpoints[ CP_DROP_OFF_DILLIMORE ] ||
		checkpointid == g_Checkpoints[ CP_DROP_OFF_DIABLO ] || checkpointid == g_Checkpoints[ CP_DROP_OFF_QUBRADOS ] ||
		checkpointid == g_Checkpoints[ CP_DROP_OFF_COP_LS ] || checkpointid == g_Checkpoints[ CP_DROP_OFF_FBI_LS ] ||
		checkpointid == g_Checkpoints[ CP_DROP_OFF_FBI_LV ] || checkpointid == g_Checkpoints[ CP_DROP_OFF_COP_LV ] ||
		checkpointid == g_Checkpoints[ CP_DROP_OFF_FBI ] || checkpointid == g_Checkpoints[ CP_DROP_OFF_HELI ] )
	{
	    if ( p_Class[ playerid ] != CLASS_POLICE )
	    	return 1;

	    new
	    	iState = GetPlayerState( playerid ),
	    	iVehicle = GetPlayerVehicleID( playerid )
	    ;

	    if ( iState == PLAYER_STATE_DRIVER && iVehicle != 0 )
	    {
	    	new
	    		iDetained = 0, iCashEarned = 0;

	    	foreach(new victimid : Player)
	    	{
	    		if ( victimid != playerid && p_WantedLevel[ victimid ] && p_Class[ victimid ] != CLASS_POLICE )
	    		{
	    			if ( IsPlayerInVehicle( victimid, iVehicle ) && IsPlayerDetained( victimid ) )
	    			{
						new
							totalSeconds = p_WantedLevel[ victimid ] * ( JAIL_SECONDS_MULTIPLIER );

						iDetained++;
						iCashEarned += ( p_WantedLevel[ victimid ] < MAX_WANTED_LVL ? p_WantedLevel[ victimid ] : MAX_WANTED_LVL ) * ( COP_DETAIN_PAY_PER_WANTED );
						KillTimer( p_CuffAbuseTimer[ victimid ] );
						SetPlayerSpecialAction( victimid, SPECIAL_ACTION_NONE );
			        	RemovePlayerAttachedObject( victimid, 2 );
						TogglePlayerControllable( victimid, 1 );
						p_Cuffed{ victimid } = false;
						GameTextForPlayer( victimid, "~r~被捕!", 4000, 0 );
						ClearAnimations( victimid );
						JailPlayer( victimid, totalSeconds );
						GivePlayerSeasonalXP( victimid, -2 );
						SendGlobalMessage( -1, ""COL_GOLD"[监狱]{FFFFFF} %s(%d) 将 %s(%d) 送入监狱, 刑期 %d 秒!", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( victimid ), victimid, totalSeconds );
	    			}
	    		}
	    	}

	    	if ( iDetained )
	    	{
				if ( iCashEarned > 30000 )
					printf("[police dropoff] %s -> %d people - %s", ReturnPlayerName( playerid ), iDetained, cash_format( iCashEarned ) ); // 8hska7082bmahu

				GivePlayerCash( playerid, iCashEarned );
				GivePlayerScore( playerid, iDetained * 2 );
				CallLocalFunction( "OnPlayerArrested", "dddd", playerid, INVALID_PLAYER_ID, p_Arrests[ playerid ], iDetained );
                return SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[成就]{FFFFFF} 你获得了"COL_GOLD"%s{FFFFFF} 和 %d 分数, 共押送 %d 名罪犯入狱.", cash_format( iCashEarned ), iDetained * 2, iDetained );
	    	}
            else return SendError( playerid, "车内没有可以送入监狱的在押罪犯." );
	    }
	    else return SendError( playerid, "必须驾驶载有在押罪犯的载具才能使用此功能." );
	}
	return 1;
}

/* ** Commands ** */
CMD:taze( playerid, params[ ] )
{
   	new victimid;
    if ( p_Class[ playerid ] != CLASS_POLICE ) return SendError( playerid, "此功能仅限警察使用." );
	else if ( sscanf( params, "u", victimid ) ) return SendUsage( playerid, "/taze [PLAYER_ID]" );
	else if ( victimid == playerid ) return SendError( playerid, "你不能电击自己." );
	else if ( !IsPlayerConnected( victimid ) ) return SendError( playerid, "附近没有可电击的玩家." );
	else if ( p_Spectating{ playerid } ) return SendError( playerid, "旁观时无法使用此类命令." );
    else if ( IsPlayerInBattleRoyale( playerid ) ) return SendError( playerid, "大逃杀中无法使用此命令." );
	else if ( GetDistanceBetweenPlayers( playerid, victimid ) < 5.0 && IsPlayerConnected( victimid ) )
 	{
        if ( p_Class[ victimid ] == p_Class[ playerid ] ) return SendError( playerid, "此玩家与你同阵营." );
		if ( p_WantedLevel[ victimid ] == 0 ) return SendError( playerid, "此玩家没有犯罪!" );
		if ( IsPlayerInAnyVehicle( victimid ) ) return SendError( playerid, "此玩家正在载具内." );
		if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "在载具内无法进行此操作." );
		if ( IsPlayerTazed( victimid ) ) return SendError( playerid, "此玩家已被电击制服." );
		if ( IsPlayerDead( victimid ) ) return SendError( playerid, "此玩家已经死亡." );
		if ( IsPlayerCuffed( victimid ) ) return SendError( playerid, "此玩家已被铐住." );
		if ( IsPlayerDetained( victimid ) ) return SendError( playerid, "此玩家已被拘留." );
		if ( IsPlayerGettingBlowed( playerid ) ) return SendError( playerid, "接受口交时无法使用此命令." );
		if ( IsPlayerBlowingCock( playerid ) ) return SendError( playerid, "进行口交时无法使用此命令." );
		if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "被绑架时无法进行此操作." );
		if ( IsPlayerTied( playerid ) ) return SendError( playerid, "被捆绑时无法进行此操作." );
		if ( IsPlayerAdminOnDuty( victimid ) ) return SendError( playerid, "无法对值勤中的管理员使用此命令." );
		if ( IsPlayerJailed( victimid ) ) return SendError( playerid, "此玩家已入狱, 可能处于暂停状态." );
		if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "在监狱中无法使用此命令." );
		if ( IsPlayerTied( victimid ) ) return SendError( playerid, "电击已被捆绑的玩家没有意义, 你可以先用 /untie 松绑!" );
		if ( IsPlayerLoadingObjects( victimid ) ) return SendError( playerid, "此玩家正在加载地图物体." );
		if ( GetPlayerState( playerid ) == PLAYER_STATE_WASTED ) return SendError( playerid, "死亡时无法使用此命令." );
		if ( p_TazingImmunity[ victimid ] > g_iTime ) return SendError( playerid, "再次电击此玩家需要等待 %d 秒.", p_TazingImmunity[ victimid ] - g_iTime );

		// event check
		#if defined __cloudy_event_system
		if ( IsPlayerInEvent( playerid ) && ! EventSettingAllow( EVENT_SETTING_ARREST ) )
		#else
		if ( IsPlayerInEvent( playerid ) )
		#endif
		{
			return SendError( playerid, "参加活动时无法使用此命令." );
		}

		if ( random( 101 ) < 90 )
		{
			GameTextForPlayer( victimid, "~n~~r~被电击!", 2000, 4 );
			GameTextForPlayer( playerid, "~n~~y~~h~/cuff", 2000, 4 );
			SendClientMessageFormatted( victimid, -1, ""COL_RED"[电击]{FFFFFF} 你被 %s(%d) 电击制服了 5 秒!", ReturnPlayerName( playerid ), playerid );
		    SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[电击]{FFFFFF} 你电击制服了 %s(%d), 持续 5 秒!", ReturnPlayerName( victimid ), victimid );
	        SetTimerEx( "Untaze", 5000, false, "dd", victimid, 6 );
			TogglePlayerControllable( victimid, 0 );
			ApplyAnimation( victimid, "CRACK", "crckdeth2", 5.0, 1, 1, 1, 0, 0 );
			p_Tazed{ victimid } = true;
		}
		else
		{
			SendClientMessageFormatted( playerid, -1, ""COL_RED"[电击失败]{FFFFFF} 你未能电击 %s(%d)!", ReturnPlayerName( victimid ), victimid );
            SendClientMessageFormatted( victimid, -1, ""COL_GREEN"[电击失败]{FFFFFF} %s(%d) 未能电击你!", ReturnPlayerName( playerid ), playerid );
		}
		p_TazingImmunity[ victimid ] = g_iTime + 6;
		return 1;
 	} else {
		return SendError( playerid, "附近没有可电击的玩家." );
	}
}

CMD:ar( playerid, params[ ] ) return cmd_arrest(playerid, params);
CMD:arrest( playerid, params[ ] )
{
   	new victimid;
	if ( p_Class[ playerid ] != CLASS_POLICE ) return SendError( playerid, "此功能仅限警察使用." );
	else if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "在监狱中无法使用此命令." );
	else if ( sscanf( params, "u", victimid ) ) return SendUsage( playerid, "/ar(rest) [PLAYER_ID]" );
	else if ( victimid == playerid ) return SendError( playerid, "你不能逮捕自己." );
	else if ( !IsPlayerConnected( victimid ) ) return SendError( playerid, "此玩家不在线." );
	else if ( p_Spectating{ playerid } ) return SendError( playerid, "旁观时无法使用此类命令." );
    else if ( IsPlayerInBattleRoyale( playerid ) ) return SendError( playerid, "大逃杀中无法使用此命令." );
	else if ( GetDistanceBetweenPlayers( playerid, victimid ) < 4.0 && IsPlayerConnected( victimid ) )
 	{
        if ( p_Class[ victimid ] == p_Class[ playerid ] ) return SendError( playerid, "此玩家与你同阵营." );
		if ( p_WantedLevel[ victimid ] == 0 ) return SendError( playerid, "此玩家没有犯罪!" );
		if ( !IsPlayerCuffed( victimid ) ) return SendError( playerid, "此玩家尚未被铐住." );
		if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "被绑架时无法进行此操作." );
		if ( IsPlayerDead( victimid ) ) return SendError( playerid, "此玩家已经死亡." );
		if ( IsPlayerDetained( victimid ) ) return SendError( playerid, "此玩家已被拘留, 无法逮捕." );
		if ( IsPlayerTied( playerid ) ) return SendError( playerid, "被捆绑时无法进行此操作." );
		if ( IsPlayerJailed( victimid ) ) return SendError( playerid, "此玩家已入狱, 可能处于暂停状态." );
		if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "在载具内无法逮捕此玩家." );
		if ( IsPlayerInAnyVehicle( victimid ) ) return SendError( playerid, "无法逮捕载具内的玩家." );
		if ( IsPlayerAdminOnDuty( victimid ) ) return SendError( playerid, "无法对值勤中的管理员使用此命令." );
		if ( GetPlayerState( playerid ) == PLAYER_STATE_WASTED ) return SendError( playerid, "死亡时无法使用此命令." );
		new totalCash = ( p_WantedLevel[ victimid ] < MAX_WANTED_LVL ? p_WantedLevel[ victimid ] : MAX_WANTED_LVL ) * ( COP_ARREST_PAY_PER_WANTED );
		new totalSeconds = p_WantedLevel[ victimid ] * ( JAIL_SECONDS_MULTIPLIER );
		if ( GetPlayerLevel( victimid, E_POLICE ) >= 75.0 ) {
			totalSeconds = floatround( float( totalSeconds ) * 0.5 );
		}
		GivePlayerScore( playerid, 2 );
		GivePlayerExperience( playerid, E_POLICE );
		GivePlayerCash( playerid, totalCash );
		StockMarket_UpdateEarnings( E_STOCK_GOVERNMENT, totalCash, 0.1 );
		if ( totalCash > 20000 ) printf("[police arrest] %s -> %s - %s", ReturnPlayerName( playerid ), ReturnPlayerName( victimid ), cash_format( totalCash ) ); // 8hska7082bmahu
		SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[成就]{FFFFFF} 你获得了"COL_GOLD"%s{FFFFFF} 和 2 分数, 逮捕目标: %s(%d)!", cash_format( totalCash ), ReturnPlayerName( victimid ), victimid );
		GameTextForPlayer( victimid, "~r~被捕!", 4000, 0 );
		CallLocalFunction( "OnPlayerArrested", "dddd", playerid, victimid, p_Arrests[ playerid ], 1 );
		Untaze( victimid, 6 );
		GivePlayerSeasonalXP( victimid, -20.0 );
		SendGlobalMessage( -1, ""COL_GOLD"[监狱]{FFFFFF} %s(%d) 将 %s(%d) 送入监狱, 刑期 %d 秒!", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( victimid ), victimid, totalSeconds );
		JailPlayer( victimid, totalSeconds );
		return 1;
 	}
    else return SendError( playerid, "附近没有可逮捕的玩家." );
}

CMD:cuff( playerid, params[ ] )
{
	new victimid;
    if ( p_Class[ playerid ] != CLASS_POLICE ) return SendError( playerid, "此功能仅限警察使用." );
	else if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "在监狱中无法使用此命令." );
	else if ( sscanf( params, "u", victimid ) ) return SendUsage( playerid, "/cuff [PLAYER_ID]" );
	else if ( victimid == playerid ) return SendError( playerid, "你不能给自己上铐." );
	else if ( !IsPlayerConnected( victimid ) || IsPlayerNPC( victimid ) ) return SendError( playerid, "此玩家不在线." );
	else if ( p_Spectating{ playerid } ) return SendError( playerid, "旁观时无法使用此类命令." );
	else if ( IsPlayerInBattleRoyale( playerid ) ) return SendError( playerid, "大逃杀中无法使用此命令." );
 	else if ( GetDistanceBetweenPlayers( playerid, victimid ) < 4.0 && IsPlayerConnected( victimid ) )
 	{
        if ( p_Class[ victimid ] == p_Class[ playerid ] ) return SendError( playerid, "此玩家与你同阵营." );
		if ( p_WantedLevel[ victimid ] == 0 ) return SendError( playerid, "此玩家没有犯罪!" );
		if ( p_WantedLevel[ victimid ] < 6 ) return SendError( playerid, "此玩家罪行较轻, 请向其开罚单." );
		if ( IsPlayerInAnyVehicle( victimid ) ) return SendError( playerid, "此玩家正在载具内." );
		if ( IsPlayerDead( victimid ) ) return SendError( playerid, "此玩家已经死亡." );
		if ( IsPlayerDetained( victimid ) ) return SendError( playerid, "此玩家已被拘留." );
		if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "在载具内无法进行此操作." );
		if ( IsPlayerCuffed( victimid ) ) return SendError( playerid, "此玩家已被铐住." );
		if ( IsPlayerJailed( victimid ) ) return SendError( playerid, "此玩家已入狱, 可能处于暂停状态." );
		if ( !IsPlayerTazed( victimid ) ) return SendError( playerid, "必须先电击制服此玩家才能上铐." );
		if ( IsPlayerGettingBlowed( playerid ) ) return SendError( playerid, "接受口交时无法使用此命令." );
		if ( IsPlayerBlowingCock( playerid ) ) return SendError( playerid, "进行口交时无法使用此命令." );
		if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "被绑架时无法进行此操作." );
		if ( IsPlayerTied( playerid ) ) return SendError( playerid, "被捆绑时无法进行此操作." );
		if ( IsPlayerAdminOnDuty( victimid ) ) return SendError( playerid, "无法对值勤中的管理员使用此命令." );
		if ( IsPlayerJailed( victimid ) ) return SendError( playerid, "此玩家已入狱, 可能处于暂停状态." );
		if ( IsPlayerLoadingObjects( victimid ) ) return SendError( playerid, "此玩家正在加载地图物体." );
		if ( GetPlayerState( playerid ) == PLAYER_STATE_WASTED ) return SendError( playerid, "死亡时无法使用此命令." );
		if ( !IsPlayerSpawned( victimid ) ) return SendError( playerid, "此玩家必须先出生." );

		GameTextForPlayer( victimid, "~n~~r~被铐住!", 2000, 4 );
		GameTextForPlayer( playerid, "~n~~y~~h~/arrest", 2000, 4 );

		SendClientMessageFormatted( victimid, -1, ""COL_RED"[上铐]{FFFFFF} %s(%d) 给你戴上了手铐!", ReturnPlayerName( playerid ), playerid );
		SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[上铐]{FFFFFF} 你给 %s(%d) 戴上了手铐!", ReturnPlayerName( victimid ), victimid );

		p_Cuffed{ victimid } = true;
		p_QuitToAvoidTimestamp[ victimid ] = g_iTime + 3;
		SetPlayerAttachedObject( victimid, 2, 19418, 6, -0.011000, 0.028000, -0.022000, -15.600012, -33.699977, -81.700035, 0.891999, 1.000000, 1.168000 );
		SetPlayerSpecialAction( victimid, SPECIAL_ACTION_CUFFED );

		KillTimer( p_CuffAbuseTimer[ victimid ] );
		p_CuffAbuseTimer[ victimid ] = SetTimerEx( "Uncuff", ( 60 * 1000 ), false, "d", victimid );
		return 1;
 	}
    else return SendError( playerid, "附近没有可上铐的玩家." );
}

CMD:uncuff( playerid, params[ ] )
{
	new victimid;
    if ( p_Spectating{ playerid } ) return SendError( playerid, "旁观时无法使用此类命令." );
	else if ( sscanf( params, "u", victimid ) ) return SendUsage( playerid, "/uncuff [PLAYER_ID]" );
	else if ( victimid == playerid ) return SendError( playerid, "你不能给自己解铐." );
 	else if ( GetDistanceBetweenPlayers( playerid, victimid ) < 4.0 && IsPlayerConnected( victimid ) )
 	{
		if ( p_WantedLevel[ victimid ] == 0 ) return SendError( playerid, "此玩家没有犯罪!" );
		if ( !IsPlayerCuffed( victimid ) ) return SendError( playerid, "此玩家尚未被铐住." );
		if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "在载具内无法进行此操作." );
		if ( IsPlayerLoadingObjects( victimid ) ) return SendError( playerid, "此玩家正在加载地图物体." );
		if ( IsPlayerTied( playerid ) ) return SendError( playerid, "被捆绑时无法使用此命令." );
		if ( IsPlayerTazed( playerid ) ) return SendError( playerid, "被电击时无法使用此命令." );
		if ( IsPlayerCuffed( playerid ) ) return SendError( playerid, "被铐住时无法使用此命令." );
		if ( IsPlayerKidnapped( playerid ) ) return SendError( playerid, "被绑架时无法使用此命令." );
		if ( IsPlayerDetained( playerid ) ) return SendError( playerid, "被拘留时无法使用此命令." );
		SendClientMessageFormatted( victimid, -1, ""COL_RED"[解铐]{FFFFFF} %s(%d) 解开了你的手铐!", ReturnPlayerName( playerid ), playerid );
	    SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[解铐]{FFFFFF} 你解开了 %s(%d) 的手铐!", ReturnPlayerName( victimid ), victimid );
        ClearAnimations( victimid );
		TogglePlayerControllable( victimid, 1 );
		p_Cuffed{ victimid } = false;
		p_Detained{ victimid } = false;
		Delete3DTextLabel( p_DetainedLabel[ victimid ] );
		p_DetainedLabel[ victimid ] = Text3D: INVALID_3DTEXT_ID;
		p_DetainedBy[ victimid ] = INVALID_PLAYER_ID;
		KillTimer( p_CuffAbuseTimer[ victimid ] );
        SetPlayerSpecialAction( victimid, SPECIAL_ACTION_NONE );
        RemovePlayerAttachedObject( victimid, 2 );
 	}
    else return SendError( playerid, "附近没有可解铐的玩家." );
	return 1;
}

CMD:detain( playerid, params[ ] )
{
	new victimid = GetClosestPlayer( playerid );
    if ( p_Class[ playerid ] != CLASS_POLICE ) return SendError( playerid, "此功能仅限警察使用." );
	else if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "在监狱中无法使用此命令." );
    else if ( p_Spectating{ playerid } ) return SendError( playerid, "旁观时无法使用此类命令." );
	//else if ( sscanf( params, "u", victimid ) ) return SendUsage( playerid, "/detain [PLAYER_ID]" );
	//else if ( victimid == playerid ) return SendError( playerid, "You cannot detain yourself." );
 	else if ( GetDistanceBetweenPlayers( playerid, victimid ) < 4.0 && IsPlayerConnected( victimid ) )
 	{
	    if ( p_Class[ victimid ] == p_Class[ playerid ] ) return SendError( playerid, "附近的此玩家与你同阵营." );
		if ( p_WantedLevel[ victimid ] == 0 ) return SendError( playerid, "此玩家没有犯罪!" );
		if ( IsPlayerInAnyVehicle( victimid ) ) return SendError( playerid, "此玩家正在载具内." );
		if ( IsPlayerDetained( victimid ) ) return SendError( playerid, "此玩家已被拘留." );
		if ( !IsPlayerCuffed( victimid ) ) return SendError( playerid, "此玩家尚未被铐住." );
		if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "在载具内无法进行此操作." );
		if ( IsPlayerLoadingObjects( victimid ) ) return SendError( playerid, "此玩家正在加载地图物体." );
		if ( !IsValidVehicle( p_LastVehicle[ playerid ] ) ) return SendError( playerid, "你的上一辆载具已被摧毁或尚未生成." );
		if ( PutPlayerInEmptyVehicleSeat( p_LastVehicle[ playerid ], victimid ) == -1 ) return SendError( playerid, "载具已满, 无法将此玩家押入车内." );
		if ( GetPlayerState( playerid ) == PLAYER_STATE_WASTED ) return SendError( playerid, "死亡时无法使用此命令." );
		SendClientMessageFormatted( victimid, -1, ""COL_RED"[拘留]{FFFFFF} 你被 %s(%d) 拘留了!", ReturnPlayerName( playerid ), playerid );
	    SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[拘留]{FFFFFF} 你拘留了 %s(%d), 已将其押入你上次驾驶的载具!", ReturnPlayerName( victimid ), victimid );
		KillTimer( p_CuffAbuseTimer[ victimid ] );
		p_CuffAbuseTimer[ victimid ] = SetTimerEx( "Uncuff", ( 300 * 1000 ), false, "d", victimid );
		p_Detained{ victimid } = true;
		p_Tazed{ victimid } = false;
		p_DetainedBy[ victimid ] = playerid;
		p_TiedAtTimestamp[ victimid ] = g_iTime;
	    Delete3DTextLabel( p_DetainedLabel[ victimid ] );
	    p_DetainedLabel[ victimid ] = Create3DTextLabel( "在押罪犯", COLOR_BLUE, 0.0, 0.0, 0.0, 15.0, 0 );
	    Attach3DTextLabelToPlayer( p_DetainedLabel[ victimid ], victimid, 0.0, 0.0, 0.6 );
		TogglePlayerControllable( victimid, 0 );
 	}
    else return SendError( playerid, "附近没有可拘留的玩家." );
	return 1;
}

CMD:bc( playerid, params[ ] ) return cmd_breakcuffs(playerid, params);
CMD:breakcuffs( playerid, params[ ] )
{
	return BreakPlayerCuffs( playerid ), 1;
}

/* ** Functions ** */
stock AwardArrest( victimid, playerid )
{
	p_QuitToAvoidTimestamp[ playerid ] = 0;
	new totalCash = ( p_WantedLevel[ victimid ] < MAX_WANTED_LVL ? p_WantedLevel[ victimid ] : MAX_WANTED_LVL ) * ( 300 );
	new totalSeconds = p_WantedLevel[ victimid ] * ( JAIL_SECONDS_MULTIPLIER );
	GivePlayerScore( playerid, 2 );
	GivePlayerExperience( playerid, E_POLICE );
	GivePlayerCash( playerid, totalCash );
	StockMarket_UpdateEarnings( E_STOCK_GOVERNMENT, totalCash, 0.1 );
	if ( totalCash > 20000 ) printf("[police arrest] %s -> %s - %s", ReturnPlayerName( playerid ), ReturnPlayerName( victimid ), cash_format( totalCash ) ); // 8hska7082bmahu
	SendClientMessageFormatted( playerid, -1, ""COL_GREEN"[成就]{FFFFFF} 你获得了"COL_GOLD"%s{FFFFFF} 和 2 分数, 逮捕目标: %s(%d)!", cash_format( totalCash ), ReturnPlayerName( victimid ), victimid );
	GameTextForPlayer( victimid, "~r~被捕!", 4000, 0 );
	CallLocalFunction( "OnPlayerArrested", "dddd", playerid, victimid, p_Arrests[ playerid ], 1 );
	GivePlayerSeasonalXP( victimid, -20.0 );
	JailPlayer( victimid, totalSeconds );
	return 1;
}

function Untaze( playerid, taze_immunity_seconds )
{
	if ( !IsPlayerConnected( playerid ) || !p_Tazed{ playerid } ) // || p_Detained{ playerid } == true
	    return 0;

	if ( ! IsPlayerTied( playerid ) )
		TogglePlayerControllable( playerid, 1 );

	if ( GetPlayerSpecialAction( playerid ) != SPECIAL_ACTION_CUFFED )
		SetPlayerSpecialAction( playerid, SPECIAL_ACTION_NONE );

	ClearAnimations( playerid );
	p_BulletInvulnerbility[ playerid ] = g_iTime + 3;
	p_TazingImmunity[ playerid ] = g_iTime + taze_immunity_seconds;
	p_Tazed{ playerid } = false;
	return 1;
}

function Uncuff( playerid )
{
	if ( !IsPlayerConnected( playerid ) || !IsPlayerCuffed( playerid ) || !IsPlayerAttachedObjectSlotUsed( playerid, 2 ) )
	    return 0;

	TogglePlayerControllable( playerid, 1 );
 	RemovePlayerAttachedObject( playerid, 2 );
	SetPlayerSpecialAction( playerid, SPECIAL_ACTION_NONE );
	if ( !IsPlayerInAnyVehicle( playerid ) ) {
		ClearAnimations( playerid );
	}
	p_Cuffed{ playerid } = false;
	p_Detained{ playerid } = false;
	Delete3DTextLabel( p_DetainedLabel[ playerid ] );
	p_DetainedLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	p_DetainedBy[ playerid ] = INVALID_PLAYER_ID;
	p_BulletInvulnerbility[ playerid ] = g_iTime + 5;

    SendGlobalMessage( -1, ""COL_GREY"[服务器]{FFFFFF} 防滥用系统已为 %s(%d) 解铐并解除拘留.", ReturnPlayerName( playerid ), playerid );
	return 1;
}

stock BreakPlayerCuffs( playerid )
{
	if ( !IsPlayerConnected( playerid ) || IsPlayerDead( playerid ) ) return false;

	if ( !IsPlayerCuffed( playerid ) ) return SendError( playerid, "你没有被铐住." );

	if ( p_BobbyPins[ playerid ] < 1 )
	{
		ShowPlayerHelpDialog( playerid, 4000, "可在 Supa Save 或 24/7 商店购买发夹, 用来撬开手铐." );
		return false;
	}
	else p_BobbyPins[ playerid ] --;

	new Float: probability = fRandomEx( 0.0, 100.0 );

	// multiply success rate every 25 levels (only 1, 2, 3, 4x)
	probability *= GetPlayerLevel( playerid, E_POLICE ) / 25.0 + 1.0;

	// if probability >= n% after multiplying as well then uncuff
	if ( probability >= 75.0 )
	{
		if ( ! IsPlayerCuffed( playerid ) )
		{
			Untaze( playerid, 10 );
			GivePlayerWantedLevel( playerid, 6 );
		}
		else
		{
			if ( ! IsPlayerAttachedObjectSlotUsed( playerid, 2 ) )
				return false;

			TogglePlayerControllable( playerid, 1 );
			RemovePlayerAttachedObject( playerid, 2 );
			SetPlayerSpecialAction( playerid, SPECIAL_ACTION_NONE );

			if ( ! IsPlayerInAnyVehicle( playerid ) ) {
				ClearAnimations( playerid );
			}

			p_Cuffed{ playerid } = false;
			p_BulletInvulnerbility[ playerid ] = g_iTime + 5;
			p_Detained{ playerid } = false;
			Delete3DTextLabel( p_DetainedLabel[ playerid ] );
			p_DetainedLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
			p_DetainedBy[ playerid ] = INVALID_PLAYER_ID;
		}
		SendServerMessage( playerid, "你成功撬开了手铐!" );
		return true;
	}
	else
	{
		SendServerMessage( playerid, "发夹折断了, 你未能撬开手铐." );
		return false;
	}
}

stock AwardNearestLEO( playerid, reason )
{
	if ( ! IsPlayerConnected( playerid ) || playerid == INVALID_PLAYER_ID || GetPlayerWantedLevel( playerid ) < 2 || IsPlayerDead( playerid ) )
		return false;

	#if defined __cloudy_event_system
	if ( IsPlayerInEvent( playerid ) )
		return false;
	#endif

	new Float: radius = ( IsPlayerInAnyVehicle( playerid ) ? 150.0 : 75.0 ); // If player is in a vehicle, increase radius due to ability to get farther quicker.

	new closestLEO = GetClosestPlayerEx( playerid, CLASS_POLICE, radius );

	if ( IsPlayerConnected( closestLEO ) && !p_Spectating{ closestLEO } )
	{
		new reasonText[ 24 ];

		switch ( reason )
		{
			case 0: reasonText = "退出游戏逃避追捕";
			case 1: reasonText = "被通缉时挂机";
		}

		AwardArrest( playerid, closestLEO );
		SendGlobalMessage( -1, ""COL_GOLD"[监狱]{FFFFFF} %s(%d) 获得了逮捕 %s(%d) 的奖励, 原因: "COL_LRED"%s.", ReturnPlayerName( closestLEO ), closestLEO, ReturnPlayerName( playerid ), playerid, reasonText );
		return true;
	}
	return false;
}

hook OnPlayerAccessEntrance( playerid, entranceid, worldid, interiorid )
{
	if ( GetPlayerWantedLevel( playerid ) > 2 )
	{

		new Float: x, Float: y, Float: z;

		GetEntrancePos( entranceid, x, y, z );

		foreach ( new pID : Player )
		{
			if ( p_Class[ pID ] != CLASS_POLICE ) continue;

			new Float: distance = GetPlayerDistanceFromPoint( pID, x, y, z );

			if ( distance < 50 )
			{
				p_QuitToAvoidTimestamp[ playerid ] = g_iTime + 30;
				break;
			}
		}
	}
	return 1;
}

hook OnPlayerUpdateEx( playerid )
{
	if ( p_Class[ playerid ] == CLASS_POLICE && GetPlayerScore( playerid ) < 50 )
	{
		new
			Float: radius = 25.0,
			closestCivilian = GetClosestPlayerEx( playerid, CLASS_CIVILIAN, radius );

		if ( closestCivilian != INVALID_PLAYER_ID && GetPlayerWantedLevel( closestCivilian ) != 0 )
		{
			return ShowPlayerHelpDialog( playerid, 4000, "使用 ~y~/taze [ID]~w~, ~b~/cuff [ID]~w~ 和 ~r~/ar [ID] ~w~ 逮捕罪犯." );
		}
	}
	return 1;
}
