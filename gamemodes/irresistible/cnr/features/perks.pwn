/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\perks.pwn
 * Purpose: perks system
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Variables ** */
static stock
	bool: p_OffRadar 				[ MAX_PLAYERS char ],
	p_OffRadarTimestamp 			[ MAX_PLAYERS ],
	p_OffRadarVisible 				[ MAX_PLAYERS ]
;

/* ** Hooks ** */
hook OnPlayerDisconnect( playerid, reason )
{
	p_OffRadar{ playerid } = false;
	return 1;
}

hook OnPlayerSpawn( playerid )
{
	p_OffRadar{ playerid } = false;
	return 1;
}

hook OnPlayerUpdateEx( playerid )
{
	if ( IsPlayerHiddenFromRadar( playerid ) )
	{
		new
			current_time = GetServerTime( );

		// Expire stealth mode after 30 seconds
		if ( p_OffRadarTimestamp[ playerid ] != 0 && current_time > p_OffRadarTimestamp[ playerid ] ) {
			p_OffRadar{ playerid } = false;
			SetPlayerColorToTeam( playerid );
			SendServerMessage( playerid, "你的雷达隐藏能力现已过期." );
		}

		// Stealth mode after getting shot
		else if ( p_OffRadarVisible[ playerid ] != 0 && current_time > p_OffRadarVisible[ playerid ] ) {
			SetPlayerColorToTeam( playerid ), p_OffRadarVisible[ playerid ] = 0;
		}
	}
	return 1;
}

hook OnPlayerWeaponShot( playerid, weaponid, hittype, hitid, Float: fX, Float: fY, Float: fZ )
{
	if ( hittype == BULLET_HIT_TYPE_PLAYER ) {
		// Exposing stealth mode player
		if ( IsPlayerHiddenFromRadar( playerid ) ) {
			SetPlayerColor( playerid, setAlpha( GetPlayerColor( playerid ), 0xFF ) ), p_OffRadarVisible[ playerid ] = g_iTime + 2;
		}
	}
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	#if defined __cloudy_event_system
	if ( IsPlayerInEvent( playerid ) && ! EventSettingAllow( EVENT_SETTING_PERKS ) ) {
		return 1;
	}
	#endif

	if ( dialogid == DIALOG_PERKS && response )
	{
		switch( listitem )
		{
			case 0: ShowPlayerDialog( playerid, DIALOG_PERKS_P, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}死亡竞赛福利", ""COL_WHITE"物品名称\t"COL_WHITE"成本 (经验)\n躲避雷达\t"COL_GREEN"250 经验\n无限弹药\t"COL_GREEN"100 经验", "选择", "返回" );
			case 1: ShowPlayerDialog( playerid, DIALOG_PERKS_V, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}抢劫津贴", ""COL_WHITE"物品名称\t"COL_WHITE"成本 (经验)\n修理和翻转车辆\t"COL_GREEN"180 经验\n修理车辆\t"COL_GREEN"120 经验\n添加 NOS\t"COL_GREEN"80 经验\n翻转车辆\t"COL_GREEN"50 经验", "选择", "返回" );
		}
	}
	else if ( dialogid == DIALOG_PERKS_P )
	{
	    if ( !response )
	        return ShowPlayerDialog( playerid, DIALOG_PERKS, DIALOG_STYLE_LIST, "{FFFFFF}游戏福利", "死亡竞赛福利\n抢劫福利", "选择", "取消" );

	    new
			Float: total_dm_xp = GetPlayerExperience( playerid, E_DEATHMATCH );

	    switch( listitem )
	    {
	        case 0:
	        {
	        	if ( total_dm_xp < 250 ) {
                    return SendError( playerid, "对于此物品,你至少需要 250 死亡竞赛 经验." );
	        	}

	        	if ( GetPlayerClass( playerid ) != CLASS_CIVILIAN ) {
                    return SendError( playerid, "你需要是平民才能使用这项福利." );
	        	}

	        	p_OffRadar{ playerid } = true;
				p_OffRadarTimestamp[ playerid ] = GetServerTime( ) + 180;

	        	GivePlayerExperience( playerid, E_DEATHMATCH, -250, .with_dilation = false );

                SendServerMessage( playerid, "你已经躲过了雷达(3分钟)为250死斗经验." );
                ShowPlayerHelpDialog( playerid, 3000, "~g~~h~躲避雷达 ~w~ 将在 3 分钟内停用." );

	        	SetPlayerColor( playerid, setAlpha( GetPlayerColor( playerid ), 0x00 ) );
	        	Beep( playerid );
	        }

	        case 1:
	        {
	        	if ( total_dm_xp < 100 ) {
                    return SendError( playerid, "对于此物品,你至少需要 100 死亡竞赛 经验." );
	        	}

                for ( new i = 0; i < MAX_WEAPONS; i++ )
				{
				    if ( IsWeaponInAnySlot( playerid, i ) && i != 0 && !( 16 <= i <= 18 ) && i != 35 && i != 47 && i != WEAPON_BOMB )
				    {
				        GivePlayerWeapon( playerid, i, 15000 );
				    }
				}

	        	GivePlayerExperience( playerid, E_DEATHMATCH, -100, .with_dilation = false );

				SendServerMessage( playerid, "你已为 100 死斗 经验 购买了无限弹药." );
				SetPlayerArmedWeapon( playerid, 0 );
				Beep( playerid );
	        }
	    }
	}
	else if ( dialogid == DIALOG_PERKS_V )
	{
	    if ( !response )
	        return ShowPlayerDialog( playerid, DIALOG_PERKS, DIALOG_STYLE_LIST, "{FFFFFF}游戏福利", "死亡竞赛福利\n抢劫福利", "选择", "取消" );

		if ( !IsPlayerInAnyVehicle( playerid ) || GetPlayerState( playerid ) != PLAYER_STATE_DRIVER )
		    return SendError( playerid, "你没有作为驾驶员驾驶任何车辆." );

		new
			Float: total_robbery_xp = GetPlayerExperience( playerid, E_ROBBERY );

	    switch( listitem )
	    {
	    	case 0:
	        {
	        	if ( total_robbery_xp < 180 ) {
                    return SendError( playerid, "对于此物品,你至少需要 180 抢劫 经验." );
	        	}

	            new Float: vZ, vehicleid = GetPlayerVehicleID( playerid );
				GetVehicleZAngle( vehicleid, vZ ), SetVehicleZAngle( vehicleid, vZ );
                RepairVehicle( vehicleid );
				GivePlayerExperience( playerid, E_ROBBERY, -180, .with_dilation = false );
				SendServerMessage( playerid, "你已经修理并翻转了你的车辆,以进行 180 抢劫 经验." );
				PlayerPlaySound( playerid, 1133, 0.0, 0.0, 5.0 );
	        }
	        case 1:
	        {
	        	if ( total_robbery_xp < 120 ) {
                    return SendError( playerid, "对于此物品,你至少需要 120 抢劫 经验." );
	        	}

            	new vehicleid = GetPlayerVehicleID( playerid );
				PlayerPlaySound( playerid, 1133, 0.0, 0.0, 5.0 );
                RepairVehicle( vehicleid );
				GivePlayerExperience( playerid, E_ROBBERY, -120, .with_dilation = false );
				SendServerMessage( playerid, "你已因 120 抢劫 经验 修理了你的汽车." );
	        }
	        case 2:
	        {
	        	if ( total_robbery_xp < 80 ) {
                    return SendError( playerid, "对于此物品,你至少需要 80 抢劫 经验." );
	        	}

                AddVehicleComponent( GetPlayerVehicleID( playerid ), 1010 );
				GivePlayerExperience( playerid, E_ROBBERY, -80, .with_dilation = false );
				SendServerMessage( playerid, "你已因 80 抢劫 经验 修理了你的汽车." );
				PlayerPlaySound( playerid, 1133, 0.0, 0.0, 5.0 );
	        }
	        case 3:
	        {
	        	if ( total_robbery_xp < 50 ) {
                    return SendError( playerid, "对于此物品,你至少需要 50 抢劫 经验." );
	        	}

	            new Float: vZ, vehicleid = GetPlayerVehicleID( playerid );
				GetVehicleZAngle( vehicleid, vZ ), SetVehicleZAngle( vehicleid, vZ );
				GivePlayerExperience( playerid, E_ROBBERY, -50, .with_dilation = false );
				SendServerMessage( playerid, "你已因 50 抢劫 经验 修理了你的汽车." );
				PlayerPlaySound( playerid, 1133, 0.0, 0.0, 5.0 );
	        }
	    }
	}
	return 1;
}

/* ** Commands ** */
CMD:perks( playerid, params[ ] )
{
	#if defined __cloudy_event_system
	if ( IsPlayerInEvent( playerid ) && ! EventSettingAllow( EVENT_SETTING_PERKS ) ) {
		return SendError( playerid, "参加活动时无法使用此命令." );
	}
	#else
	if ( IsPlayerInEvent( playerid ) || IsPlayerInBattleRoyale( playerid ) ) {
		return SendError( playerid, "参加活动时无法使用此命令." );
	}
	#endif

	if ( IsPlayerInArmyVehicle( playerid ) )
		return SendError( playerid, "在军车中时你无法使用此命令." );

	return ShowPlayerDialog( playerid, DIALOG_PERKS, DIALOG_STYLE_LIST, "{FFFFFF}游戏福利", "死亡竞赛福利\n抢劫福利", "选择", "取消" );
}

/* ** Functions ** */
stock IsPlayerHiddenFromRadar( playerid ) {
	return p_OffRadar{ playerid };
}
