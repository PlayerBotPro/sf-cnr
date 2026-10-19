/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\eastereggs.pwn
 * Purpose: treasure (easter eggs) hunting system
 */

/* ** Error checking ** */
#if !defined __cnr__eastereggs
	#define __cnr__eastereggs
#else
	#endinput
#endif

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define EASTEREGG_LABEL 			"[\184;\180;\187;\238;\189;\218;\178;\202;\181;\176;]"
#define EASTEREGG_NAME 				"\184;\180;\187;\238;\189;\218;\178;\202;\181;\176;"
#define EASTEREGG_MODEL 			randarg( 19341, 19342, 19343, 19344, 19345 )
#define MAX_EGGS 					( 6 )

/* ** Variables ** */
enum E_EASTEREGG_DATA
{
	Float: E_X,     		Float: E_Y,			Float: E_Z,
	E_PICK_UP, 				Text3D: E_LABEL
};

new
	g_EasterEggs                    [ MAX_EGGS ] [ E_EASTEREGG_DATA ],
	Iterator: eastereggs 			< MAX_EGGS >,
	bool: g_EasterHunt              = false
;

/* ** Hooks ** */
hook OnPlayerUpdateEx( playerid )
{
	// Easter Egg Hunt
	if ( ! GetPlayerAdminLevel( playerid ) )
	{
		if ( g_EasterHunt )
		{
			foreach(new easterid : eastereggs)
			{
				if ( IsPlayerInRangeOfPoint( playerid, 2.0, g_EasterEggs[ easterid ] [ E_X ], g_EasterEggs[ easterid ] [ E_Y ], g_EasterEggs[ easterid ] [ E_Z ] ) )
				{
				    new
				    	iMoney, Float: iCoins, szPrize[ 16 ];

					switch( random( 4 ) )
					{
					    case 0:
					    {
                            szPrize = "一个家";
							AddPlayerNote( playerid, -1, ""COL_GOLD"寻宝之家" #COL_WHITE );
                            SendClientMessage( playerid, -1, ""COL_GOLD"[房屋]"COL_GREY" 你已赢得房屋,请联系 5 级管理员在有利位置兑换房屋." );
					    }
					    case 1:
					    {
                            szPrize = "一辆车";
							AddPlayerNote( playerid, -1, ""COL_GOLD"寻宝车" #COL_WHITE );
                            SendClientMessage( playerid, -1, ""COL_GOLD"[汽车]"COL_GREY" 你赢得了一辆汽车,请联系 5 级管理员兑换你选择的汽车!" );
					    }
					    case 2:
					    {
					    	GivePlayerCash( playerid, ( iMoney = RandomEx( 600000, 1500000 ) ) );
					    	format( szPrize, sizeof( szPrize ), "%s", cash_format( iMoney ) );
					    }
					    case 3:
					    {
					    	( iCoins = fRandomEx( 75.0, 250.0 ) );
							GivePlayerIrresistibleCoins( playerid, iCoins );
                            format( szPrize, sizeof( szPrize ), "%0.2f 硬币", iCoins );
					    }
					}

		            DestroyEasterEgg( easterid );
		            SendGlobalMessage( -1, ""COL_GOLD""#EASTEREGG_LABEL""COL_WHITE" %s(%d) 已找到 " #EASTEREGG_NAME " 并赢得了 "COL_GOLD"%s{FFFFFF}.", ReturnPlayerName( playerid ), playerid, szPrize );

					if ( !Iter_Count(eastereggs) )
					{
					    g_EasterHunt = false;
						SendClientMessage( playerid, -1, ""COL_PINK"[管理]"COL_GOLD" 寻宝已被停用.全部 " #EASTEREGG_NAME "被发现了." );
					}
					break;
				}
			}
		}
	}
	return 1;
}

/* ** Commands ** */
CMD:treasures( playerid, params[ ] )
{
	new
		count = Iter_Count( eastereggs );

	if ( ! g_EasterHunt )
		return SendError( playerid, "寻宝活动未激活,因此此功能被禁用." );

 	if ( !count ) {
        return SendServerMessage( playerid, "没有 " #EASTEREGG_NAME "目前已种植." ), 1;
 	} else {
        return SendServerMessage( playerid, "有%d " #EASTEREGG_NAME "(s) 目前已种植.", count ), 1;
 	}
}

CMD:setegg( playerid, params[ ] )
{
	if ( !IsPlayerAdmin( playerid ) )
		return 0;

	if ( g_EasterHunt )
		return SendError( playerid, "这 " #EASTEREGG_NAME " 狩猎已经开始了." );

	new
	    Float: X, Float: Y, Float: Z;

	GetPlayerPos( playerid, X, Y, Z );

	if ( CreateEasterEgg( X, Y, Z ) != -1 ) {
		AddAdminLogLineFormatted( "%s(%d) has set a " #EASTEREGG_NAME "", ReturnPlayerName( playerid ), playerid );
		return SendServerMessage( playerid, "种植 " #EASTEREGG_NAME " 在你当前的位置." ), 1;
	} else {
		return SendError( playerid, "没有足够的空间容纳另一个 " #EASTEREGG_NAME "." ), 1;
	}
}

CMD:treasurehunt( playerid, params[ ] )
{
	if ( !IsPlayerAdmin( playerid ) )
		return 0;

	if ( Iter_Count( eastereggs ) < 1 )
		return SendError( playerid, "还不够 " #EASTEREGG_NAME "埋伏开始寻宝." );

	// if its false, destroy all egs
	if ( ( g_EasterHunt = ! g_EasterHunt ) == false )
    {
		for ( new i = 0; i < MAX_EGGS; i ++)
			DestroyEasterEgg( i );
    }

    // alert admin log
	AddAdminLogLineFormatted( "%s(%d) has started a treasurehunt", ReturnPlayerName( playerid ), playerid );
    SendClientMessageFormatted( playerid, -1, ""COL_PINK"[管理]"COL_GOLD" 寻宝活动已%s", g_EasterHunt == true ? ("激活,四处寻找 " #EASTEREGG_NAME "并获得一份免费礼物.") : ("已停用.") );
	return 1;
}

/* ** Functions ** */
stock DestroyEasterEgg( id )
{
	if ( !( 0 <= id < MAX_EGGS ) )
		return 0;

	Iter_Remove(eastereggs, id);
    DestroyDynamicPickup( g_EasterEggs[ id ] [ E_PICK_UP ] );
    DestroyDynamic3DTextLabel( g_EasterEggs[ id ] [ E_LABEL ] );
	return 1;
}

stock CreateEasterEgg( Float: X, Float: Y, Float: Z )
{
	new
	    ID = Iter_Free(eastereggs);

	if ( ID != ITER_NONE ) {
		Iter_Add( eastereggs, ID );
	    g_EasterEggs[ ID ] [ E_X ] = X;
	    g_EasterEggs[ ID ] [ E_Y ] = Y;
	    g_EasterEggs[ ID ] [ E_Z ] = Z;
	    g_EasterEggs[ ID ] [ E_PICK_UP ] = CreateDynamicPickup( EASTEREGG_MODEL, 1, X, Y, Z );
	    g_EasterEggs[ ID ] [ E_LABEL ] = CreateDynamic3DTextLabel( EASTEREGG_LABEL, COLOR_GOLD, X, Y, Z, 10.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, 0 );
	}
	return ID;
}
