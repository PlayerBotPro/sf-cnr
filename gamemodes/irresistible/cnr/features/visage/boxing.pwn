/*
 * Irresistible Gaming (c) 2018
 * Developed by Damen, Lorenc
 * Module: Boxing
 * Purpose: Boxing for Visage
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define IsPlayerBoxing(%0) 			(g_boxingPlayerData[ %0 ] [ E_FIGHTING ])
#define SendBoxing(%0,%1) 			(SendClientMessageFormatted( %0, -1, "{B74AFF}[\200;\173;\187;\247;] {FFFFFF}" # %1))
#define SendBoxingGlobal(%0) 		(SendClientMessageFormatted( INVALID_PLAYER_ID, -1, "{B74AFF}[\200;\173;\187;\247;] {FFFFFF}" # %0))
#define IsPlayerNearBoxingArena(%0) (GetPlayerDistanceFromPoint( %0, 2654.885986, 1613.157958, 1506.269042 ) < 25.0)

/* ** Variables ** */
enum E_BOXER_DATA {
	bool: E_FIGHTING,
	E_OPPONENT,
	bool: E_INVITED,
	E_INVITE_TIMESTAMP,
	E_ROUNDS_SET,
	E_BET_AMOUNT_SET,
	bool: E_IS_HOST,
	E_SCORE,
	Float: E_PRIOR_HEALTH,
	Float: E_PRIOR_ARMOUR,
	E_PRIOR_WEP[ 12 ],
	E_PRIOR_WEP_AMMO[ 12 ],
	E_PRIOR_SKIN
};

enum E_ARENA_DATA {
	bool: E_OCCUPIED,
	E_CD_TIMER,
	E_CURRENT_ROUNDS,
	E_ROUNDS,
	E_BET
};

new g_boxingPlayerData 				[ MAX_PLAYERS ] [ E_BOXER_DATA ];
new g_boxingArenaData 				[ E_ARENA_DATA ];
new Text3D: arenaLabel 				= Text3D: INVALID_3DTEXT_ID;

/* ** Hooks ** */
hook OnGameModeInit( ) {
	print( "-> Boxing System - By: Damen" );
	arenaLabel = CreateDynamic3DTextLabel( "拳击竞技场\n{FFFFFF}/boxing fight", COLOR_GREY, 2655.3022, 1613.6146, 1507.0977, 15.0 );
	return 1;
}

hook OnPlayerConnect( playerid ) {
	g_boxingPlayerData[ playerid ] [ E_FIGHTING ] = false;
	g_boxingPlayerData[ playerid ] [ E_OPPONENT ] = -1;
	g_boxingPlayerData[ playerid ] [ E_INVITED ] = false;
	g_boxingPlayerData[ playerid ] [ E_ROUNDS_SET ] = 1;
	g_boxingPlayerData[ playerid ] [ E_BET_AMOUNT_SET ] = 0;
	g_boxingPlayerData[ playerid ] [ E_IS_HOST ] = false;
	g_boxingPlayerData[ playerid ] [ E_SCORE ] = 0;
	return 1;
}

hook OnPlayerDisconnect( playerid, reason ) {
	boxing_ForfeitMatch( playerid, g_boxingPlayerData[ playerid ] [ E_OPPONENT ] );
	return 1;
}

#if defined AC_INCLUDED
hook OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
hook OnPlayerDeath( playerid, killerid, reason )
#endif
{
	boxing_ForfeitMatch( playerid, g_boxingPlayerData[ playerid ] [ E_OPPONENT ] );
	// printf("BOXING MATCH DEATH BY %s -> RETURN %d", ReturnPlayerName(playerid), );
	return 1;
}

/* ** Commands ** */
CMD:boxing( playerid, params[ ] ) {

	if ( !IsPlayerNearBoxingArena( playerid ) )
		return SendError( playerid, "你必须位于竞技场 25 米范围内才能使用此命令." );

	if ( g_boxingArenaData[ E_OCCUPIED ] == true )
		return SendError( playerid, "竞技场当前已被占用.请等待竞技场清空." );

	if ( GetPlayerWantedLevel( playerid ) )
		return SendError( playerid, "当你当前被通缉时,你不能装箱." );

	if ( !strcmp( params, "fight", true, 5 ) ) {

		new targetID, betAmount, rounds;

		if ( g_boxingPlayerData[ playerid ] [ E_FIGHTING ] == true )
			return SendError( playerid, "你当前正在与对手战斗.请结束你的战斗." );

		if ( sscanf( params[ 6 ], "uD(0)D(3)", targetID, betAmount, rounds ) )
			return SendUsage( playerid, "/boxing fight [PLAYER_ID] [BET_AMOUNT (0)] [ROUNDS (3)]" );

		if ( ! IsPlayerConnected( targetID ) )
			return SendError( playerid, "播放器未连接." );

		if ( targetID == playerid )
			return SendError( playerid, "你不能邀请自己参加拳击比赛." );

		if ( !IsPlayerNearBoxingArena( targetID ) )
			return SendError( playerid, "你邀请参加拳击比赛的选手不在拳击场附近." );

		if ( GetPlayerCash( targetID ) < betAmount )
			return SendError( playerid, "你邀请的玩家没有足够的钱来下注该金额." );

		if ( ! ( 0 <= betAmount <= 10000000 ) )
			return SendError( playerid, "请指定介于 $0 和 $10,000,000. 之间的金额" );

		if ( rounds != 1 && rounds != 3 && rounds != 5 && rounds != 9 )
			return SendError( playerid, "请在 1, 3, 5, 或 9 轮之间进行选择." );

		if ( g_boxingPlayerData[ targetID ] [ E_INVITED ] == true )
			return SendError( playerid, "该玩家已被邀请参加战斗." );

		if ( g_boxingPlayerData[ targetID ] [ E_FIGHTING ] == true )
			return SendError( playerid, "该玩家当前正在与另一个对手战斗.请等到比赛结束后再重新邀请他们." );

		if ( GetPlayerWantedLevel( targetID ) )
			return SendError( playerid, "你不能对通缉的球员进行拳击." );

		if ( g_boxingPlayerData[ playerid ] [ E_INVITED ] == true ) {
			SendBoxing( playerid, "你已取消对 %s 的邀请.", ReturnPlayerName( g_boxingPlayerData[ playerid ] [ E_OPPONENT ] ) );
			SendBoxing( g_boxingPlayerData[ playerid ] [ E_OPPONENT ], "%s 已取消比赛邀请.", ReturnPlayerName( playerid ) );
			ResetBoxingPlayerVariables( playerid, g_boxingPlayerData[ playerid ] [ E_OPPONENT ] );
		}

		g_boxingPlayerData[ playerid ] [ E_INVITED ] = true;
		g_boxingPlayerData[ playerid ] [ E_OPPONENT ] = targetID;
		g_boxingPlayerData[ playerid ] [ E_IS_HOST ] = true;
		g_boxingPlayerData[ playerid ] [ E_ROUNDS_SET ] = rounds;
		g_boxingPlayerData[ playerid ] [ E_BET_AMOUNT_SET ] = betAmount;
		g_boxingPlayerData[ targetID ] [ E_INVITED ] = true;
		g_boxingPlayerData[ targetID ] [ E_OPPONENT ] = playerid;
		g_boxingPlayerData[ targetID ] [ E_INVITE_TIMESTAMP ] = GetServerTime( ) + 30000;

		if ( g_boxingPlayerData[ playerid ] [ E_BET_AMOUNT_SET ] == 0 ) {

			SendBoxing( playerid, "你已邀请 %s 参加一场拳击比赛,但在 %i 轮中没有下注.", ReturnPlayerName( targetID ), g_boxingPlayerData[ playerid ] [ E_ROUNDS_SET ] );
			SendBoxing( playerid, "要取消你的邀请,请使用 /boxing [取消]." );

			SendBoxing( targetID, "%s 邀请你参加一场 %i 轮无赌注的拳击比赛.", ReturnPlayerName( playerid ), g_boxingPlayerData[ playerid ] [ E_ROUNDS_SET ] );
			SendBoxing( targetID, "要接受或拒绝邀请,请使用 /boxing [ACCEPT/DECLINE]." );

		} else {

			SendBoxing( playerid, "你已邀请 %s 参加一场拳击比赛,赌注为 %s 至 %i 轮.", ReturnPlayerName( targetID ), cash_format( g_boxingPlayerData[ playerid ] [ E_BET_AMOUNT_SET ] ), g_boxingPlayerData[ playerid ] [ E_ROUNDS_SET ] );
			SendBoxing( playerid, "要取消你的邀请,请使用 /boxing [取消]." );

			SendBoxing( targetID, "%s 邀请你参加一场拳击比赛,赌注为 %s 至 %i 轮.", ReturnPlayerName( playerid ), cash_format( g_boxingPlayerData[ playerid ] [ E_BET_AMOUNT_SET ] ), g_boxingPlayerData[ playerid ] [ E_ROUNDS_SET ] );
			SendBoxing( targetID, "要接受或拒绝邀请,请使用 /boxing [ACCEPT/DECLINE]." );

		}
		return 1;

	} else if ( !strcmp( params, "cancel", true, 6 ) ) {

		new opponent = g_boxingPlayerData[ playerid ] [ E_OPPONENT ];

		if ( g_boxingPlayerData[ playerid ] [ E_FIGHTING ] == true )
			return SendError( playerid, "你当前正在参加一场拳击比赛.如果你想放弃比赛,请使用 /boxing [弃权]." );

		if ( g_boxingPlayerData[ playerid ] [ E_IS_HOST ] == false )
			return SendError( playerid, "你没有可&#8203;&#8203;以取消的拳击比赛邀请." );

		SendBoxing( opponent, "%s 已取消拳击比赛邀请.", ReturnPlayerName( playerid ) );
		SendBoxing( playerid, "你已取消发送至 %s 的拳击比赛邀请.", ReturnPlayerName( opponent ) );
		ResetBoxingPlayerVariables( playerid, opponent );
		return 1;

	} else if ( !strcmp( params, "accept", true, 6 ) ) {

		new opponent = g_boxingPlayerData[ playerid ] [ E_OPPONENT ];

		if ( GetServerTime( ) > g_boxingPlayerData[ playerid ] [ E_INVITE_TIMESTAMP ] && g_boxingPlayerData[ playerid ] [ E_INVITED ] ) {
			SendServerMessage( opponent, "%s 在你的拳击邀请过期后尝试接受它.", ReturnPlayerName( playerid ) );
			ResetBoxingPlayerVariables( playerid, opponent );
			return SendError( playerid, "此邀请已过期." );
		}

		if ( g_boxingPlayerData[ playerid ] [ E_INVITED ] == false )
			return SendError( playerid, "你没有任何要接受的拳击比赛邀请." );

		if ( opponent == -1 )
			return SendError( playerid, "你的对手无法再战斗." );

		if ( !IsPlayerNearBoxingArena( opponent ) ) {

			SendError( playerid, "%s 不再靠近竞技场.你的邀请已被取消.", ReturnPlayerName( opponent ) );
			SendBoxing( opponent, "当你不在竞技场附近时,%s 已尝试接受你的邀请.", ReturnPlayerName( playerid ) );
			return ResetBoxingPlayerVariables( playerid, opponent );

		}

		if ( GetPlayerCash( playerid ) < g_boxingPlayerData[ opponent ] [ E_BET_AMOUNT_SET ] ) {

			SendError( playerid, "你没有足够的钱来参加所设置的投注金额的比赛." );
			SendError( opponent, "%s 没有足够的钱来参加所设定的投注金额的比赛.", ReturnPlayerName( playerid ) );
			return ResetBoxingPlayerVariables( playerid, opponent );

		} else if ( GetPlayerCash( opponent ) < g_boxingPlayerData[ opponent ] [ E_BET_AMOUNT_SET ] ) {

			SendError( opponent, "你没有足够的钱来参加所设置的投注金额的比赛." );
			SendError( playerid, "%s 没有足够的钱来参加所设定的投注金额的比赛.", ReturnPlayerName( opponent ) );
			return ResetBoxingPlayerVariables( playerid, opponent );

		}

		g_boxingArenaData[ E_OCCUPIED ] = true;

		g_boxingPlayerData[ playerid ] [ E_FIGHTING ] = true;
		g_boxingPlayerData[ playerid ] [ E_INVITED ] = false;

		g_boxingPlayerData[ opponent ] [ E_FIGHTING ] = true;
		g_boxingPlayerData[ opponent ] [ E_INVITED ] = false;
		g_boxingPlayerData[ opponent ] [ E_IS_HOST ] = true;

		return StartMatch( playerid, opponent );

	} else if ( !strcmp( params, "decline", true, 7 ) ) {

		new opponent = g_boxingPlayerData[ playerid ] [ E_OPPONENT ];

		if ( g_boxingPlayerData[ playerid ] [ E_INVITED ] == false )
			return SendError( playerid, "你没有任何要拒绝的拳击比赛邀请." );

		if ( g_boxingPlayerData[ playerid ] [ E_OPPONENT ] == -1 )
			return SendError( playerid, "你的对手无法再战斗." );

		SendBoxing( opponent, "%s 已拒绝你的邀请.", ReturnPlayerName( playerid ) );

		SendBoxing( playerid, "你拒绝了 %s 的邀请.", ReturnPlayerName( opponent ) );

		return ResetBoxingPlayerVariables( playerid, opponent );

	} else if ( !strcmp( params, "forfeit", true, 7 ) ) {
		if ( ! boxing_ForfeitMatch( playerid, g_boxingPlayerData[ playerid ] [ E_OPPONENT ] ) ) {
			return SendError( playerid, "你没有与任何人战斗." );
		}
		return 1;
	}
	return SendUsage( playerid, "/boxing [FIGHT/CANCEL/ACCEPT/DECLINE/FORFEIT]" );
}

/* ** Functions ** */
stock StartMatch( playerid, targetID ) {

	if ( g_boxingPlayerData[ playerid ] [ E_FIGHTING ] && g_boxingPlayerData[ targetID ] [ E_FIGHTING ] ) {

		new Float:health_P, Float:armour_P, Float:health_T, Float:armour_T;

		ClearAnimations( playerid );
		GetPlayerHealth( playerid, health_P );
		GetPlayerArmour( playerid, armour_P );
		SetPlayerSpecialAction( playerid, SPECIAL_ACTION_NONE );
		g_boxingPlayerData[ playerid ] [ E_PRIOR_HEALTH ] = health_P;
		g_boxingPlayerData[ playerid ] [ E_PRIOR_ARMOUR ] = armour_P;
		g_boxingPlayerData[ playerid ] [ E_PRIOR_SKIN ] = GetPlayerSkin( playerid );
		SetPlayerSkin( playerid, 81 );

		ClearAnimations( targetID );
		GetPlayerHealth( targetID, health_T );
		GetPlayerArmour( targetID, armour_T );
		SetPlayerSpecialAction( targetID, SPECIAL_ACTION_NONE );
		g_boxingPlayerData[ targetID ] [ E_PRIOR_HEALTH ] = health_T;
		g_boxingPlayerData[ targetID ] [ E_PRIOR_ARMOUR ] = armour_T;
		g_boxingPlayerData[ targetID ] [ E_PRIOR_SKIN ] = GetPlayerSkin( targetID );
		SetPlayerSkin( targetID, 80 );

		// save weapons
		for( new iSlot = 0; iSlot != 12; iSlot++ ) {
			GetPlayerWeaponData( playerid, iSlot, g_boxingPlayerData[ playerid ] [ E_PRIOR_WEP ] [ iSlot ], g_boxingPlayerData[ playerid ] [ E_PRIOR_WEP_AMMO ] [ iSlot ] );
			GetPlayerWeaponData( targetID, iSlot, g_boxingPlayerData[ targetID ] [ E_PRIOR_WEP ] [ iSlot ], g_boxingPlayerData[ targetID ] [ E_PRIOR_WEP_AMMO ] [ iSlot ] );
		}

		g_boxingArenaData[ E_ROUNDS ] = g_boxingPlayerData[ targetID ] [ E_ROUNDS_SET ];
		g_boxingArenaData[ E_BET ] = g_boxingPlayerData[ targetID ] [ E_BET_AMOUNT_SET ];

		if ( g_boxingArenaData[ E_BET ] > 0 ) {
			GivePlayerCash( playerid, -g_boxingArenaData[ E_BET ] );
			GivePlayerCash( targetID, -g_boxingArenaData[ E_BET ] );
		}

		SetBoxingPlayerConfig( playerid, targetID );

		KillTimer( g_boxingArenaData[ E_CD_TIMER ] );
		g_boxingArenaData[ E_CD_TIMER ] = SetTimerEx( "boxingCountDown", 960, false, "d", 5 );

		SendBoxing( playerid, "你正在与 %s 进行 %i 轮的最佳比赛.祝你好运!", ReturnPlayerName( targetID ), g_boxingArenaData[ E_ROUNDS ] );
		SendBoxing( targetID, "你正在与 %s 进行 %i 轮的最佳比赛.祝你好运!", ReturnPlayerName( playerid ), g_boxingArenaData[ E_ROUNDS ] );

		UpdateArenaScoreLabel( playerid, targetID );
		return true;

	} else {
		return SendError( playerid, "对不起.比赛开始时出了严重的问题.请再试一次." );
	}
}

stock NextRound( playerid, targetID )
{
	UpdateArenaScoreLabel( playerid, targetID );
	SetBoxingPlayerConfig( playerid, targetID );
	KillTimer( g_boxingArenaData[ E_CD_TIMER ] );
	g_boxingArenaData[ E_CD_TIMER ] = SetTimerEx( "boxingCountDown", 960, false, "d", 5 );
	return 1;
}

stock EndMatch( playerid, targetID ) {

	new winnerid = g_boxingPlayerData[ targetID ] [ E_SCORE ] > g_boxingPlayerData[ playerid ] [ E_SCORE ] ? targetID : playerid;
	new loserid = winnerid == playerid ? targetID : playerid;

	if ( g_boxingArenaData[ E_BET ] <= 0 ) {
		SendBoxingGlobal( "%s 赢得了一场对 %s 的拳击比赛,最终 分数 为 %i!", ReturnPlayerName( winnerid ), ReturnPlayerName( loserid ), g_boxingPlayerData[ winnerid ] [ E_SCORE ] );
	} else {
		new winning_prize = floatround( float( g_boxingArenaData[ E_BET ] ) * 1.9 ); // We take 5% of the total pot
		GivePlayerCash( winnerid, winning_prize );
		SendBoxingGlobal( "%s 赢得了与 %s 的拳击比赛, 获得 %s, 最终比分 %i!", ReturnPlayerName( winnerid ), ReturnPlayerName( loserid ), cash_format( g_boxingArenaData[ E_BET ] ), g_boxingPlayerData[ winnerid ] [ E_SCORE ] );
	}

	boxing_RestorePlayer( playerid );
	boxing_RestorePlayer( targetID );

	SetPlayerPos( playerid, 2658.3181, 1607.2100, 1507.1793 );
	SetPlayerPos( targetID, 2652.0947, 1607.2100, 1507.1793 );

	ResetBoxingArenaVariables();
	ResetBoxingPlayerVariables( playerid, targetID );
	UpdateDynamic3DTextLabelText( arenaLabel, COLOR_GREY, "拳击竞技场\n"COL_WHITE"/boxing fight" );
	return 1;
}

stock boxing_RestorePlayer( playerid )
{
	// user reported 0xff health, maybe spawn protection
	if ( g_boxingPlayerData[ playerid ] [ E_PRIOR_HEALTH ] > 100.0 ) g_boxingPlayerData[ playerid ] [ E_PRIOR_HEALTH ] = 100.0;
	if ( g_boxingPlayerData[ playerid ] [ E_PRIOR_ARMOUR ] > 100.0 ) g_boxingPlayerData[ playerid ] [ E_PRIOR_ARMOUR ] = 100.0;

	// set prior health
	SetPlayerHealth( playerid, g_boxingPlayerData[ playerid ] [ E_PRIOR_HEALTH ] );
	SetPlayerArmour( playerid, g_boxingPlayerData[ playerid ] [ E_PRIOR_ARMOUR ] );
	SetPlayerSkin( playerid, g_boxingPlayerData[ playerid ] [ E_PRIOR_SKIN ] );
	ResetPlayerWeapons( playerid );

	for ( new iSlot = 0; iSlot != 12; iSlot++ ) {
	    GivePlayerWeapon( playerid, g_boxingPlayerData[ playerid ] [ E_PRIOR_WEP ] [ iSlot ], g_boxingPlayerData[ playerid ] [ E_PRIOR_WEP_AMMO ] [ iSlot ] );
	}
}

stock boxing_ForfeitMatch( playerid, targetID ) {
	if ( ! g_boxingPlayerData[ playerid ] [ E_FIGHTING ] ) return 0;

	if ( g_boxingArenaData[ E_BET ] == 0 ) {
		SendBoxingGlobal( "%s 通过对 %s 的弃权赢得了一场拳击比赛.", ReturnPlayerName( targetID ), ReturnPlayerName( playerid ) );
	} else if ( g_boxingArenaData[ E_BET ] > 0 ) {
		GivePlayerCash( targetID, g_boxingArenaData[ E_BET ] );
		SendBoxingGlobal( "%s通过弃权赢得了一场拳击比赛%s对于%s.", ReturnPlayerName( targetID ), ReturnPlayerName( playerid ), cash_format( g_boxingArenaData[ E_BET ] ) );
	}

	boxing_RestorePlayer( playerid );
	SetPlayerPos( playerid, 2658.3181, 1607.2100, 1507.1793 );

	if ( 0 <= targetID < MAX_PLAYERS ) {
		boxing_RestorePlayer( targetID );
		SetPlayerPos( targetID, 2652.0947, 1607.2100, 1507.1793 );
	}

	ResetBoxingArenaVariables();
	ResetBoxingPlayerVariables( playerid, targetID );
	UpdateDynamic3DTextLabelText( arenaLabel, COLOR_GREY, "拳击竞技场\n"COL_WHITE"/boxing fight" );
	return 1;
}

stock SetBoxingPlayerConfig( playerid, targetID ) {

	SetPlayerPos( playerid, 2657.4133, 1615.7841, 1507.0977 );
	SetPlayerPos( targetID, 2653.1357, 1611.4575, 1507.0977 );

	SetPlayerFacingAngle( playerid, 136 );
	SetPlayerFacingAngle( targetID, 315 );

	SetCameraBehindPlayer( playerid );
	SetCameraBehindPlayer( targetID );

	SetPlayerHealth( playerid, 100.0 );
	SetPlayerHealth( targetID, 100.0 );

	SetPlayerArmour( playerid, 100.0 );
	SetPlayerArmour( targetID, 100.0 );

	ResetPlayerWeapons( playerid );
	ResetPlayerWeapons( targetID );

	TogglePlayerControllable( playerid, 0 );
	TogglePlayerControllable( targetID, 0 );
	return true;

}

function boxingCountDown( time ) {

	if ( !time ) {
		foreach( new playerid : Player ) {
			if ( g_boxingPlayerData[ playerid ] [ E_FIGHTING ] == true ) {
				format( szNormalString, sizeof( szNormalString ), "~r~战斗!", time );
				GameTextForPlayer( playerid, szNormalString, 2000, 3 );
				PlayerPlaySound( playerid, 1057, 0.0, 0.0, 0.0 );
				TogglePlayerControllable( playerid, 1 );
			}
		}
		g_boxingArenaData[ E_CD_TIMER ] = -1;

	} else {
		foreach( new playerid : Player ) {
			if ( g_boxingPlayerData[ playerid ] [ E_FIGHTING ] == true ) {
				format( szNormalString, sizeof( szNormalString ), "~y~%d", time );
				GameTextForPlayer( playerid, szNormalString, 2000, 3 );
				PlayerPlaySound( playerid, 1056, 0.0, 0.0, 0.0 );
			}
		}
		g_boxingArenaData[ E_CD_TIMER ] = SetTimerEx( "boxingCountDown", 960, false, "d", time - 1 );
	}
	return 1;
}

stock UpdateArenaScoreLabel( playerid, opponent ) {
	format( szNormalString, sizeof( szNormalString ), "%s [ %i ] - [ %i ] %s", ReturnPlayerName( playerid ), g_boxingPlayerData[ playerid ] [ E_SCORE ], g_boxingPlayerData[ opponent ] [ E_SCORE ], ReturnPlayerName( opponent ) );
	return UpdateDynamic3DTextLabelText( arenaLabel, COLOR_GOLD, szNormalString );
}

stock ResetBoxingPlayerVariables( playerid, targetID ) {

	g_boxingPlayerData[ playerid ] [ E_INVITED ] = false;
	g_boxingPlayerData[ playerid ] [ E_OPPONENT ] = -1;
	g_boxingPlayerData[ playerid ] [ E_IS_HOST ] = false;
	g_boxingPlayerData[ playerid ] [ E_FIGHTING ] = false;
	g_boxingPlayerData[ playerid ] [ E_SCORE ] = 0;
	TogglePlayerControllable( playerid, 1 );

	if ( 0 <= targetID < MAX_PLAYERS )
	{
		g_boxingPlayerData[ targetID ] [ E_INVITED ] = false;
		g_boxingPlayerData[ targetID ] [ E_OPPONENT ] = -1;
		g_boxingPlayerData[ targetID ] [ E_IS_HOST ] = false;
		g_boxingPlayerData[ targetID ] [ E_FIGHTING ] = false;
		g_boxingPlayerData[ targetID ] [ E_SCORE ] = 0;
		TogglePlayerControllable( targetID, 1 );
	}
	return true;
}

stock ResetBoxingArenaVariables() {
	g_boxingArenaData[ E_OCCUPIED ] = false;
	g_boxingArenaData[ E_CURRENT_ROUNDS ] = 0;
	g_boxingArenaData[ E_ROUNDS ] = 0;
	g_boxingArenaData[ E_BET ] = 0;
	return true;

}

/* Hooks */
#if defined AC_INCLUDED
hook OnPlayerDamagePlayer( playerid, damagedid, Float: amount, weaponid, bodypart )
#else
hook OnPlayerGiveDamage( playerid, damagedid, Float: amount, weaponid, bodypart )
#endif
{
	if ( g_boxingPlayerData[ damagedid ] [ E_FIGHTING ] == true ) {

		new Float:currentArmour;

		GetPlayerArmour( damagedid, currentArmour );

		if ( currentArmour <= 0.0 ) {

			new opponent = g_boxingPlayerData[ damagedid ] [ E_OPPONENT ];

			g_boxingPlayerData[ opponent ] [ E_SCORE ] ++;
			g_boxingArenaData[ E_CURRENT_ROUNDS ] ++;

			if ( g_boxingArenaData[ E_CURRENT_ROUNDS ] == g_boxingArenaData[ E_ROUNDS ] ) {
				return EndMatch( damagedid, opponent );
			}

			SendBoxing( damagedid, "你已经输掉了这一轮.让下一轮开始吧." );
			SendBoxing( opponent, "你已经赢得了这一轮.让下一轮开始吧." );

			SendBoxing( damagedid, "最佳 %i - [ %s: %i ] - [ %s: %i ]", g_boxingArenaData[ E_ROUNDS ], ReturnPlayerName( damagedid ), g_boxingPlayerData[ damagedid ] [ E_SCORE ], ReturnPlayerName( opponent ), g_boxingPlayerData[ opponent ] [ E_SCORE ]  );
			SendBoxing( opponent, "最佳 %i - [ %s: %i ] - [ %s: %i ]", g_boxingArenaData[ E_ROUNDS ], ReturnPlayerName( damagedid ), g_boxingPlayerData[ damagedid ] [ E_SCORE ], ReturnPlayerName( opponent ), g_boxingPlayerData[ opponent ] [ E_SCORE ]  );

			NextRound( damagedid, opponent );
		}
	}
	return Y_HOOKS_CONTINUE_RETURN_1;

}
