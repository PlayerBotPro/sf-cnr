/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\vip\coin_market.pwn
 * Purpose: coin market associated information
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Error Checking ** */
#if !defined __cnr__irresistiblecoins
	#define __cnr__irresistiblecoins
#endif

/* ** Settings ** */
#define VIP_ALLOW_OVER_LIMIT 		( true ) // allow player from using house/vehicle/garage cmds if over the limit

#define VIP_MAX_EXTRA_SLOTS 		( 5 ) // max extra slots a person can buy

/* ** Coin Market VIP Levels ** */
#define VIP_REGULAR 				( 1 )
#define VIP_BRONZE 					( 2 )
#define VIP_GOLD 					( 3 )
#define VIP_PLATINUM 				( 4 )
#define VIP_DIAMOND 				( 5 )

/* ** Coin Market Pages ** */
#define ICM_PAGE_DEFAULT 			( 0 )
#define ICM_PAGE_CASHCARD 			( 1 )
#define ICM_PAGE_ASSETS 			( 2 )
//#define ICM_PAGE_UPGRADE 			( 3 )

/* ** Coin Market Items ** */
#define ICM_COKE_BIZ 				( 0 )
#define ICM_METH_BIZ 				( 1 )
#define ICM_WEED_BIZ 				( 2 )
#define ICM_HOUSE 					( 3 )
#define ICM_VEHICLE					( 4 )
#define ICM_GATE					( 5 )
#define ICM_GARAGE					( 6 )
#define ICM_NAME					( 7 )
#define ICM_VEH_SLOT 				( 8 )

/* ** Variables ** */
enum E_IC_MARKET_DATA
{
	E_ID,	E_NAME[ 19 ],	Float: E_PRICE,
	bool: E_MULTI_BUY,
};

static stock
	g_irresistibleVipItems			[ ] [ E_IC_MARKET_DATA ] =
	{
		{ VIP_DIAMOND,	"钻石VIP",	10000.0 },
		{ VIP_PLATINUM,	"白金VIP",	5000.0 },
		{ VIP_GOLD,		"黄金 VIP",		2500.0 },
		{ VIP_BRONZE,	"青铜VIP", 	1500.0 },
		{ VIP_REGULAR, 	"普通 VIP",	500.0 }
	},

	g_irresistibleCashCards 		[ ] [ E_IC_MARKET_DATA ] =
	{
		{ 1250000,		"虎鲨",			225.0 },
		{ 2750000,		"牛鲨",			450.0 },
		{ 6000000,		"大白鲨",	900.0 },
		{ 10000000,		"鲸鲨",			1350.0 },
		{ 20000000,		"巨齿鲨",		2250.0 }
	},

	g_irresistibleMarketItems		[ ] [ E_IC_MARKET_DATA ] =
	{
		{ ICM_COKE_BIZ,	"帮派设施",		4500.0 },
		{ ICM_COKE_BIZ,	"燃油业务",		3900.0 },
		{ ICM_COKE_BIZ,	"可口可乐业务",		1500.0 },
		{ ICM_METH_BIZ,	"冰毒业务",		700.0 },
		{ ICM_WEED_BIZ,	"大麻业务",		500.0 },
		{ ICM_VEHICLE,	"选择车辆",		500.0 },
		{ ICM_HOUSE,	"选择房子",			500.0 },
		{ ICM_GATE,		"定制门",			350.0 },
		{ ICM_VEH_SLOT,	"额外车辆槽位", 	350.0 },
		{ ICM_GARAGE,	"选择车库", 		250.0 },
		{ ICM_NAME,		"更改你的名字", 	50.0 }
	},

	p_CoinMarketPage 				[ MAX_PLAYERS char ],
	p_CoinMarketSelectedItem 		[ MAX_PLAYERS char ],

	p_SelectedPackage 				[ MAX_PLAYERS char ]
;

/* ** Global Variables ** */
static stock
	p_ExtraAssetSlots 				[ MAX_PLAYERS char ],
	Float: p_IrresistibleCoins 		[ MAX_PLAYERS ]
;

/* ** Forwards ** */
forward Float: GetPlayerIrresistibleCoins( playerid );

/* ** Hooks ** */
#if defined SERVER_PLS_DONATE_MP3
hook OnServerGameDayEnd( )
{
	foreach ( new p : Player ) if ( ! p_VIPLevel[ p ] && ! IsPlayerUsingRadio( p ) )
	{
		PlayAudioStreamForPlayer( p, SERVER_PLS_DONATE_MP3 );
	}
	return 1;
}
#endif

hook OnPlayerUpdateEx( playerid )
{
	CheckPlayerVipExpiry( playerid );
	return 1;
}

hook OnPlayerDisconnect( playerid, reason )
{
	p_SelectedPackage{ playerid } = -1;
	p_ExtraAssetSlots{ playerid } = 0;
	p_IrresistibleCoins[ playerid ] = 0.0;
	return 1;
}

hook OnPlayerRegister( playerid )
{
	p_IrresistibleCoins[ playerid ] = 0.0;
	return 1;
}

hook OnPlayerLogin( playerid )
{
	CheckPlayerVipExpiry( playerid );
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_IC_MARKET && response )
	{
		//new current_vip = GetPlayerVIPLevel( playerid );

		if ( listitem == sizeof( g_irresistibleVipItems ) ) {
			return ShowPlayerCoinMarketDialog( playerid, ICM_PAGE_CASHCARD );
		}
		else if ( listitem == sizeof( g_irresistibleVipItems ) + 1 ) {
			return ShowPlayerHomeListings( playerid );
		}
		else if ( listitem > sizeof( g_irresistibleVipItems ) + 1 ) {
			return ShowPlayerCoinMarketDialog( playerid, ICM_PAGE_ASSETS );
		}
		else {
			new Float: iCoinRequirement = g_irresistibleVipItems[ listitem ] [ E_PRICE ] * GetGVarFloat( "vip_discount" );
			//new selected_vip = g_irresistibleVipItems[ listitem ] [ E_ID ];

			p_CoinMarketPage{ playerid } = ICM_PAGE_DEFAULT;
			p_CoinMarketSelectedItem{ playerid } = listitem;
			return ShowPlayerDialog( playerid, DIALOG_YOU_SURE_VIP, DIALOG_STYLE_MSGBOX, ""COL_GOLD"IC 代币 -"COL_WHITE" 确认", sprintf( ""COL_WHITE"你确定要花费 %s IC 吗?", number_format( iCoinRequirement, .decimals = 2 ) ), "是", "否" );
		}
	}
	else if ( dialogid == DIALOG_IC_MARKET_2 || dialogid == DIALOG_IC_MARKET_3 )
	{
		if ( ! response )
			return ShowPlayerCoinMarketDialog( playerid );

		new Float: iCoinRequirement = GetGVarFloat( "vip_discount" );

		// assets
		if ( dialogid == DIALOG_IC_MARKET_2 ) {
			iCoinRequirement *= g_irresistibleMarketItems[ listitem ] [ E_PRICE ];
		}
		// cash cards
		else if ( dialogid == DIALOG_IC_MARKET_3 ) {
			iCoinRequirement *= g_irresistibleCashCards[ listitem ] [ E_PRICE ];
		}

		p_CoinMarketPage{ playerid } = ( dialogid == DIALOG_IC_MARKET_3 ) ? ICM_PAGE_CASHCARD : ICM_PAGE_ASSETS;
		p_CoinMarketSelectedItem{ playerid } = listitem;
		return ShowPlayerDialog( playerid, DIALOG_YOU_SURE_VIP, DIALOG_STYLE_MSGBOX, ""COL_GOLD"IC 代币 -"COL_WHITE" 确认", sprintf( ""COL_WHITE"你确定要花费 %s IC 吗?", number_format( iCoinRequirement, .decimals = 2 ) ), "是", "否" );
	}
	else if ( dialogid == DIALOG_YOU_SURE_VIP )
	{
		if ( !response )
			return ShowPlayerCoinMarketDialog( playerid, p_CoinMarketPage{ playerid } );

		new Float: player_coins = GetPlayerIrresistibleCoins( playerid );

		// restore listitem of whatever player selected
		listitem = p_CoinMarketSelectedItem{ playerid };

		// default page
		if ( p_CoinMarketPage{ playerid } == ICM_PAGE_DEFAULT )
		{
			new Float: iCoinRequirement = g_irresistibleVipItems[ listitem ] [ E_PRICE ] * GetGVarFloat( "vip_discount" );
			new selected_vip = g_irresistibleVipItems[ listitem ] [ E_ID ];

			if ( player_coins < iCoinRequirement ) {
				SendError( playerid, "你需要大约 %s 个硬币才能获得这个 VIP!", number_format( iCoinRequirement - player_coins, .decimals = 2 ) );
				return ShowPlayerCoinMarketDialog( playerid, p_CoinMarketPage{ playerid } );
			}

			// Deduct IC
			GivePlayerIrresistibleCoins( playerid, -iCoinRequirement );

			// Set VIP Level
			SetPlayerVipLevel( playerid, selected_vip );

			// Send message
			SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[VIP 套餐]"COL_WHITE" 你已将 %s VIP 兑换成 %s IC 代币!恭喜! :D", VIPToString( selected_vip ), number_format( iCoinRequirement, .decimals = 0 ) );

			// Redirect player
			if ( selected_vip == VIP_DIAMOND )
			{
				ShowPlayerDialog( playerid, DIALOG_DONATED_DIAGOLD, DIALOG_STYLE_INPUT, ""COL_GOLD"SF-CNR 捐赠", ""COL_WHITE"当你兑换了钻石 VIP 后,你可以选择将金币 VIP 赠送给某人.\n\n如果你想将其赠送给自己,请输入你的姓名/id 或你要赠送的人.\n\n"COL_ORANGE"如果你还不知道,请取消并私信 " SERVER_OPERATOR " 当你做出决定时就在论坛上!", "礼物吧!", "我会想!" );
			}
			else if ( selected_vip == VIP_PLATINUM )
			{
				ShowPlayerDialog( playerid, DIALOG_DONATED_PLATBRONZE, DIALOG_STYLE_INPUT, ""COL_GOLD"SF-CNR 捐赠", ""COL_WHITE"当你兑换了白金 VIP 后,你可以选择将青铜 VIP 赠送给某人.\n\n如果你想将其赠送给自己,请输入你的姓名/id 或你要赠送的人.\n\n"COL_ORANGE"如果你还不知道,请取消并私信 " SERVER_OPERATOR " 当你做出决定时就在论坛上!", "礼物吧!", "我会想!" );
			}
			else
			{
				ShowPlayerVipRedeemedDialog( playerid );
			}
			return 1;
		}

		// buy cash cards
		else if ( p_CoinMarketPage{ playerid } == ICM_PAGE_CASHCARD )
		{
			new Float: iCoinRequirement = g_irresistibleCashCards[ listitem ] [ E_PRICE ] * GetGVarFloat( "vip_discount" );

			if ( player_coins < iCoinRequirement ) {
				SendError( playerid, "你需要大约 %s 硬币才能得到这个!", number_format( iCoinRequirement - player_coins, .decimals = 2 ) );
				return ShowPlayerCoinMarketDialog( playerid, p_CoinMarketPage{ playerid } );
			}

			new cash_amount = g_irresistibleCashCards[ listitem ] [ E_ID ];

			GivePlayerCash( playerid, cash_amount );
			GivePlayerIrresistibleCoins( playerid, -iCoinRequirement );
			SendServerMessage( playerid, "你已经订购了 "COL_GREEN"%s 现金卡 (%s)"COL_WHITE" 为了%s IC 代币!", g_irresistibleCashCards[ listitem ] [ E_NAME ], number_format( cash_amount ), number_format( iCoinRequirement, .decimals = 0 ) );
			ShowPlayerHelpDialog( playerid, 10000, "你购买了一张~g~%s~w~ %s 现金卡!", number_format( cash_amount ), g_irresistibleCashCards[ listitem ] [ E_NAME ] );
		}

		// all other market items
		else
		{
			new Float: iCoinRequirement = g_irresistibleMarketItems[ listitem ] [ E_PRICE ] * GetGVarFloat( "vip_discount" );

			if ( player_coins < iCoinRequirement ) {
				SendError( playerid, "你需要大约 %s 硬币才能得到这个!", number_format( iCoinRequirement - player_coins, .decimals = 2 ) );
				return ShowPlayerCoinMarketDialog( playerid, p_CoinMarketPage{ playerid } );
			}

			new selectedItemID = g_irresistibleMarketItems[ listitem ] [ E_ID ];

			// show new name dialog before charging
			if ( selectedItemID == ICM_NAME ) {
				ShowPlayerDialog( playerid, DIALOG_CHANGENAME, DIALOG_STYLE_INPUT, "更改你的名字", ""COL_WHITE"你希望你的新名字是什么?而且,还要仔细检查!", "改变", "返回" );
			}
			else if ( selectedItemID == ICM_VEH_SLOT ) {
				if ( p_ExtraAssetSlots{ playerid } >= VIP_MAX_EXTRA_SLOTS ) {
					SendError( playerid, "你已达到附加插槽的限制(限制 %d).", VIP_MAX_EXTRA_SLOTS );
					return ShowPlayerCoinMarketDialog( playerid, ICM_PAGE_ASSETS );
				}

				p_ExtraAssetSlots{ playerid } ++;
				GivePlayerIrresistibleCoins( playerid, -iCoinRequirement );
                SendServerMessage( playerid, "你已兑换了 "COL_GOLD"车辆槽"COL_WHITE" 为了%s IC 代币!", number_format( iCoinRequirement, .decimals = 0 ) );
				mysql_single_query( sprintf( "UPDATE `USERS` SET `EXTRA_SLOTS` = %d WHERE `ID` = %d", p_ExtraAssetSlots{ playerid }, GetPlayerAccountID( playerid ) ) );
                AddPlayerNote( playerid, -1, sprintf( "买了额外的插槽,有 %d 额外", p_ExtraAssetSlots{ playerid } ) );
			}
			else
			{
				GivePlayerIrresistibleCoins( playerid, -iCoinRequirement );
    			AddPlayerNote( playerid, -1, sprintf( ""COL_GOLD"%s" #COL_WHITE, g_irresistibleMarketItems[ listitem ] [ E_NAME ] ) );
    			SendClientMessageToAdmins( -1, ""COL_PINK"[DONOR NEEDS HELP]"COL_GREY" %s(%d) needs a %s. (/viewnotes)", ReturnPlayerName( playerid ), playerid, g_irresistibleMarketItems[ listitem ] [ E_NAME ] );
                SendServerMessage( playerid, "你已经订购了 "COL_GOLD"%s"COL_WHITE" 为了%s IC 代币!", g_irresistibleMarketItems[ listitem ] [ E_NAME ], number_format( iCoinRequirement, .decimals = 0 ) );
                SendServerMessage( playerid, "在线管理员已收到有关你购买的通知.使用 "COL_GREY"/notes"COL_WHITE" 跟踪你的订单并提醒在线管理员." );
                ShowPlayerHelpDialog( playerid, 10000, "你可以使用 ~y~/notes~w~ 来跟踪你的订单.~n~~n~此外,将使用此命令提醒管理员." );
			}

			/*case 8:
			{
				if ( ( iCoinRequirement = 100.0 * GetGVarFloat( "vip_discount" ) ) <= GetPlayerIrresistibleCoins( playerid ) )
				{
			        new
			        	ownerid = INVALID_PLAYER_ID,
			        	vehicleid = GetPlayerVehicleID( playerid ),
			        	buyableid = getVehicleSlotFromID( vehicleid, ownerid ),
			        	modelid = GetVehicleModel( vehicleid )
			        ;

				    if ( !vehicleid ) SendError( playerid, "You need to be in a vehicle to use this command." );
					else if ( buyableid == -1 ) SendError( playerid, "This vehicle isn't a buyable vehicle." );
					else if ( playerid != ownerid ) SendError( playerid, "You are not the owner of this vehicle." );
					else if ( IsBoatVehicle( modelid ) || IsAirVehicle( modelid ) ) SendError( playerid, "You cannot apply gold rims to this type of vehicle." );
					else
					{
     					if ( AddVehicleComponent( vehicleid, 1080 ) )
     					{
					        if ( UpdateBuyableVehicleMods( playerid, buyableid ) )
					        {
					        	new
					        		szMods[ MAX_CAR_MODS * 10 ];

								for( new i; i < MAX_CAR_MODS; i++ )
									format( szMods, sizeof( szMods ), "%s%d.", szMods, g_vehicleModifications[ playerid ] [ buyableid ] [ i ] );

								format( szBigString, sizeof( szBigString ), "UPDATE `VEHICLES` SET `MODS`='%s' WHERE `ID`=%d", szMods, g_vehicleData[ playerid ] [ buyableid ] [ E_SQL_ID ] );
								mysql_single_query( szBigString );
					        }

							GivePlayerIrresistibleCoins( playerid, - iCoinRequirement );
		    				SendServerMessage( playerid, "You have redeemed "COL_GOLD"Gold Rims"COL_WHITE" on your vehicle for %s Irresistible Coins!", number_format( iCoinRequirement, .decimals = 0 ) );

		    				// Receipt
	    					AddPlayerNote( playerid, -1, sprintf( "Bought gold rims on vehicle #%d", g_vehicleData[ playerid ] [ buyableid ] [ E_SQL_ID ] ) );
					   	}
					   	else SendError( playerid, "We were unable to place gold rims on this vehicle (0xF92D)." );
		    		}
					return ShowPlayerCoinMarketDialog( playerid, true );
				}
				else
				{
					SendError( playerid, "You need around %s coins before you can get this!", number_format( iCoinRequirement - GetPlayerIrresistibleCoins( playerid ), .decimals = 2 ) );
					return ShowPlayerCoinMarketDialog( playerid, true );
				}
			}*/
		}
	}
	else if ( dialogid == DIALOG_CHANGENAME )
	{
		if ( !response )
			return ShowPlayerCoinMarketDialog( playerid, ICM_PAGE_ASSETS );

		new selected_item = p_CoinMarketSelectedItem{ playerid };

		if ( ! ( 0 <= selected_item < sizeof( g_irresistibleMarketItems ) && g_irresistibleMarketItems[ selected_item ] [ E_ID ] == ICM_NAME ) ) {
			return SendError( playerid, "选择的选项无效,请重试." );
		}

		new Float: iCoinRequirement = g_irresistibleMarketItems[ selected_item ] [ E_PRICE ] * GetGVarFloat( "vip_discount" );
		new Float: player_coins = GetPlayerIrresistibleCoins( playerid );

		if ( player_coins < iCoinRequirement ) {
			SendError( playerid, "你需要大约 %s 硬币才能得到这个!", number_format( iCoinRequirement - player_coins, .decimals = 2 ) );
			return ShowPlayerCoinMarketDialog( playerid, ICM_PAGE_ASSETS );
		}

		new szName[ 20 ];

		if ( sscanf( inputtext, "s[20]", szName ) ) SendError( playerid, "你输入的名称被视为无效." );
		else if ( !isValidPlayerName( szName ) ) SendError( playerid, "该名称包含无效字符." );
		else {
			return mysql_function_query( dbHandle, sprintf( "SELECT `NAME` FROM `BANS` WHERE `NAME`='%s'", mysql_escape( szName ) ), true, "OnNewNameCheckBanned", "dfs", playerid, iCoinRequirement, szName );
		}
		return ShowPlayerDialog( playerid, DIALOG_CHANGENAME, DIALOG_STYLE_INPUT, "更改你的名字", ""COL_WHITE"你希望你的新名字是什么?而且,还要仔细检查!", "改变", "返回" );
	}
	else if ( dialogid == DIALOG_VIP_MAIN && response )
	{
		static
			vip_description[ 1420 ];

		switch ( listitem )
		{
			case 0: format( vip_description, sizeof( vip_description ), "\t"COL_GREY"功能\t"COL_GREY"奖励\n"\
																		"提供金钱\t"COL_GREEN"$25,000,000\n"\
																		"提供房屋\t"COL_GREEN"是的\n"\
																		"提供车辆\t"COL_GREEN"是的\n"\
																		"提供车库\t"COL_GREEN"是的\n"\
																		"提供门\t"COL_GREEN"是的\n"\
																		"大麻 提供业务\t"COL_GREEN"是的\n"\
																		"房屋定制\t"COL_GREEN"大\n"\
																		"房屋空位总数\t"COL_GREEN"没有限制\n"\
																		"车库槽位总数\t"COL_GREEN"没有限制\n"\
																		"总营业时段\t"COL_GREEN"没有限制\n"\
																		"车辆槽总数\t"COL_GREEN"20\n"\
																		"重生时的武器\t"COL_GREEN"3\n"\
																		"重生时的护甲\t"COL_GREEN"是的\n"\
																		"硬币生成量增加\t"COL_GREEN"25%%\n"\
																		"转移硬币的能力 P2P\t"COL_GREEN"是的\n"\
																		"可在代币市场出售代币 (/ic sell)\t"COL_GREEN"是的\n"\
																		"能够同时从事两项工作 (/vipjob)\t"COL_GREEN"是的\n"\
																		"免除高级住宅挂牌费\t"COL_GREEN"是的\n"\
																		"减税\t"COL_GREEN"50%%\n"\
																		"不活跃资产保护\t"COL_GREEN"30天\n"\
																		"总车辆组件编辑槽\t"COL_GREEN"10\n"\
																		"家具槽位可用\t"COL_GREEN"50\n"\
																		"VIP 休息室武器兑换冷却时间\t"COL_GREEN"没有限制\n"\
																		"VIP 在论坛上标记\t"COL_GREEN"是的\n"\
																		"访问VIP聊天\t"COL_GREEN"是的\n"\
																		"进入VIP休息室\t"COL_GREEN"是的\n"\
																		"可以生成特定的皮肤\t"COL_GREEN"是的\n"\
																		"获得VIP玩具\t"COL_GREEN"是的\n"\
																		"访问自定义帮派颜色 (/gangcolor)\t"COL_GREEN"是的\n"\
																		"使用额外的房屋武器存储槽\t"COL_GREEN"是的\n"\
																		"可以播放自定义广播 URL (/radio)\t"COL_GREEN"是的\n"\
																		"能够调整标签颜色 (/labelcolor)\t"COL_GREEN"是的\n"\
																		"可以向你杀死的人显示一条消息 (/deathmsg)\t"COL_GREEN"是的\n"\
																		"可以调整命中标记的声音 (/hitmarker)\t"COL_GREEN"是" );

			case 1: format( vip_description, sizeof( vip_description ), "\t"COL_GREY"功能\t"COL_GREY"奖励\n"\
																		"提供金钱\t"COL_GREEN"$12,500,000\n"\
																		"提供房屋\t"COL_GREEN"是的\n"\
																		"提供车辆\t"COL_GREEN"是的\n"\
																		"提供车库\t"COL_RED"否\n"\
																		"提供门\t"COL_RED"否\n"\
																		"大麻 提供业务\t"COL_RED"否\n"\
																		"房屋定制\t"COL_GREEN"中等\n"\
																		"房屋空位总数\t"COL_GREEN"10\n"\
																		"车库槽位总数\t"COL_GREEN"10\n"\
																		"总营业时段\t"COL_GREEN"10\n"\
																		"车辆槽总数\t"COL_GREEN"10\n"\
																		"重生时的武器\t"COL_GREEN"3\n"\
																		"重生时的护甲\t"COL_GREEN"是的\n"\
																		"硬币生成量增加\t"COL_GREEN"10%%\n"\
																		"转移硬币的能力 P2P\t"COL_GREEN"是的\n"\
																		"可在代币市场出售代币 (/ic sell)\t"COL_GREEN"是的\n"\
																		"能够同时从事两项工作 (/vipjob)\t"COL_RED"否\n"\
																		"免除高级住宅挂牌费\t"COL_GREEN"是的\n"\
																		"减税\t"COL_RED"0%%\n"\
																		"不活跃资产保护\t"COL_GREEN"14天\n"\
																		"总车辆组件编辑槽\t"COL_GREEN"8\n"\
																		"家具槽位可用\t"COL_GREEN"45\n"\
																		"VIP 休息室武器兑换冷却时间\t"COL_GREEN"1 分钟\n"\
																		"VIP 在论坛上标记\t"COL_GREEN"是的\n"\
																		"访问VIP聊天\t"COL_GREEN"是的\n"\
																		"进入VIP休息室\t"COL_GREEN"是的\n"\
																		"可以生成特定的皮肤\t"COL_GREEN"是的\n"\
																		"获得VIP玩具\t"COL_GREEN"是的\n"\
																		"访问自定义帮派颜色 (/gangcolor)\t"COL_GREEN"是的\n"\
																		"使用额外的房屋武器存储槽\t"COL_GREEN"是的\n"\
																		"可以播放自定义广播 URL (/radio)\t"COL_GREEN"是的\n"\
																		"能够调整标签颜色 (/labelcolor)\t"COL_GREEN"是的\n"\
																		"可以向你杀死的人显示一条消息 (/deathmsg)\t"COL_GREEN"是的\n"\
																		"可以调整命中标记的声音 (/hitmarker)\t"COL_GREEN"是" );

			case 2: format( vip_description, sizeof( vip_description ), "\t"COL_GREY"功能\t"COL_GREY"奖励\n"\
																		"提供金钱\t"COL_GREEN"$5,000,000\n"\
																		"提供房屋\t"COL_GREEN"是的\n"\
																		"提供车辆\t"COL_GREEN"是的\n"\
																		"提供车库\t"COL_RED"否\n"\
																		"提供门\t"COL_RED"否\n"\
																		"大麻 提供业务\t"COL_RED"否\n"\
																		"房屋定制\t"COL_GREEN"小\n"\
																		"房屋空位总数\t"COL_GREEN"8\n"\
																		"车库槽位总数\t"COL_GREEN"8\n"\
																		"总营业时段\t"COL_GREEN"8\n"\
																		"车辆槽总数\t"COL_GREEN"6\n"\
																		"重生时的武器\t"COL_GREEN"2\n"\
																		"重生时的护甲\t"COL_GREEN"是的\n"\
																		"硬币生成量增加\t"COL_RED"0%%\n"\
																		"转移硬币的能力 P2P\t"COL_GREEN"是的\n"\
																		"可在代币市场出售代币 (/ic sell)\t"COL_GREEN"是的\n"\
																		"能够同时从事两项工作 (/vipjob)\t"COL_RED"否\n"\
																		"免除高级住宅挂牌费\t"COL_RED"否\n"\
																		"减税\t"COL_RED"0%%\n"\
																		"不活跃资产保护\t"COL_GREEN"14天\n"\
																		"总车辆组件编辑槽\t"COL_GREEN"6\n"\
																		"家具槽位可用\t"COL_GREEN"40\n"\
																		"VIP 休息室武器兑换冷却时间\t"COL_GREEN"5 分钟\n"\
																		"VIP 在论坛上标记\t"COL_GREEN"是的\n"\
																		"访问VIP聊天\t"COL_GREEN"是的\n"\
																		"进入VIP休息室\t"COL_GREEN"是的\n"\
																		"可以生成特定的皮肤\t"COL_GREEN"是的\n"\
																		"获得VIP玩具\t"COL_GREEN"是的\n"\
																		"访问自定义帮派颜色 (/gangcolor)\t"COL_GREEN"是的\n"\
																		"使用额外的房屋武器存储槽\t"COL_GREEN"是的\n"\
																		"可以播放自定义广播 URL (/radio)\t"COL_GREEN"是的\n"\
																		"能够调整标签颜色 (/labelcolor)\t"COL_GREEN"是的\n"\
																		"可以向你杀死的人显示一条消息 (/deathmsg)\t"COL_GREEN"是的\n"\
																		"可以调整命中标记的声音 (/hitmarker)\t"COL_GREEN"是" );

			case 3: format( vip_description, sizeof( vip_description ), "\t"COL_GREY"功能\t"COL_GREY"奖励\n"\
																		"提供金钱\t"COL_GREEN"$2,500,000\n"\
																		"提供房屋\t"COL_RED"否\n"\
																		"提供车辆\t"COL_RED"否\n"\
																		"提供车库\t"COL_RED"否\n"\
																		"提供门\t"COL_RED"否\n"\
																		"大麻 提供业务\t"COL_RED"否\n"\
																		"房屋定制\t"COL_RED"否\n"\
																		"房屋空位总数\t"COL_GREEN"6\n"\
																		"车库槽位总数\t"COL_GREEN"6\n"\
																		"总营业时段\t"COL_GREEN"6\n"\
																		"车辆槽总数\t"COL_GREEN"4\n"\
																		"重生时的武器\t"COL_GREEN"1\n"\
																		"重生时的护甲\t"COL_RED"否\n"\
																		"硬币生成量增加\t"COL_RED"0%%\n"\
																		"转移硬币的能力 P2P\t"COL_GREEN"是的\n"\
																		"可在代币市场出售代币 (/ic sell)\t"COL_GREEN"是的\n"\
																		"能够同时从事两项工作 (/vipjob)\t"COL_RED"否\n"\
																		"免除高级住宅挂牌费\t"COL_RED"否\n"\
																		"减税\t"COL_RED"0%%\n"\
																		"不活跃资产保护\t"COL_GREEN"14天\n"\
																		"总车辆组件编辑槽\t"COL_GREEN"4\n"\
																		"家具槽位可用\t"COL_GREEN"35\n"\
																		"VIP 休息室武器兑换冷却时间\t"COL_GREEN"5 分钟\n"\
																		"VIP 在论坛上标记\t"COL_GREEN"是的\n"\
																		"访问VIP聊天\t"COL_GREEN"是的\n"\
																		"进入VIP休息室\t"COL_GREEN"是的\n"\
																		"可以生成特定的皮肤\t"COL_GREEN"是的\n"\
																		"获得VIP玩具\t"COL_GREEN"是的\n"\
																		"访问自定义帮派颜色 (/gangcolor)\t"COL_GREEN"是的\n"\
																		"使用额外的房屋武器存储槽\t"COL_GREEN"是的\n"\
																		"可以播放自定义广播 URL (/radio)\t"COL_GREEN"是的\n"\
																		"能够调整标签颜色 (/labelcolor)\t"COL_GREEN"是的\n"\
																		"可以向你杀死的人显示一条消息 (/deathmsg)\t"COL_GREEN"是的\n"\
																		"可以调整命中标记的声音 (/hitmarker)\t"COL_GREEN"是" );

			case 4: format( vip_description, sizeof( vip_description ), "\t"COL_GREY"功能\t"COL_GREY"奖励\n"\
																		"提供金钱\t"COL_GREEN"$500,000\n"\
																		"提供房屋\t"COL_RED"否\n"\
																		"提供车辆\t"COL_RED"否\n"\
																		"提供车库\t"COL_RED"否\n"\
																		"提供门\t"COL_RED"否\n"\
																		"大麻 提供业务\t"COL_RED"否\n"\
																		"房屋定制\t"COL_RED"否\n"\
																		"房屋空位总数\t"COL_GREEN"5\n"\
																		"车库槽位总数\t"COL_GREEN"5\n"\
																		"总营业时段\t"COL_GREEN"5\n"\
																		"车辆槽总数\t"COL_GREEN"3\n"\
																		"重生时的武器\t"COL_GREEN"1\n"\
																		"重生时的护甲\t"COL_RED"否\n"\
																		"硬币生成量增加\t"COL_RED"0%%\n"\
																		"转移硬币的能力 P2P\t"COL_RED"否\n"\
																		"可在代币市场出售代币 (/ic sell)\t"COL_RED"否\n"\
																		"能够同时从事两项工作 (/vipjob)\t"COL_RED"否\n"\
																		"免除高级住宅挂牌费\t"COL_RED"否\n"\
																		"减税\t"COL_RED"0%%\n"\
																		"不活跃资产保护\t"COL_GREEN"14天\n"\
																		"总车辆组件编辑槽\t"COL_GREEN"3\n"\
																		"家具槽位可用\t"COL_GREEN"30\n"\
																		"VIP 休息室武器兑换冷却时间\t"COL_GREEN"5 分钟\n"\
																		"VIP 在论坛上标记\t"COL_GREEN"是的\n"\
																		"访问VIP聊天\t"COL_GREEN"是的\n"\
																		"进入VIP休息室\t"COL_GREEN"是的\n"\
																		"可以生成特定的皮肤\t"COL_GREEN"是的\n"\
																		"获得VIP玩具\t"COL_GREEN"是的\n"\
																		"访问自定义帮派颜色 (/gangcolor)\t"COL_GREEN"是的\n"\
																		"使用额外的房屋武器存储槽\t"COL_GREEN"是的\n"\
																		"可以播放自定义广播 URL (/radio)\t"COL_GREEN"是的\n"\
																		"能够调整标签颜色 (/labelcolor)\t"COL_GREEN"是的\n"\
																		"可以向你杀死的人显示一条消息 (/deathmsg)\t"COL_GREEN"是的\n"\
																		"可以调整命中标记的声音 (/hitmarker)\t"COL_GREEN"是" );
		}

		ShowPlayerDialog( playerid, DIALOG_BUY_VIP_MAIN, DIALOG_STYLE_TABLIST_HEADERS, sprintf( ""COL_GOLD"%s", g_irresistibleVipItems[ listitem ][ E_NAME ] ), vip_description, "买", "返回" );
		return 1;
	}
	else if ( dialogid == DIALOG_BUY_VIP_MAIN )
	{
		// if the player clicked on the right button, return /vip
		if ( ! response ) return cmd_vip( playerid, " " );
		else if ( response ) return ShowPlayerCoinMarketDialog( playerid );
	}

	else if ( dialogid == DIALOG_BUY_VIP && response )
	{
		return ShowPlayerCoinMarketDialog( playerid );
	}
	else if ( dialogid == DIALOG_DONATED_PLATBRONZE )
	{
		if ( response )
		{
			new
				pID;

			if ( sscanf( inputtext, "u", pID ) )
			{
				SendError( playerid, "请输入玩家的 ID 或姓名." );
				ShowPlayerDialog( playerid, DIALOG_DONATED_PLATBRONZE, DIALOG_STYLE_INPUT, ""COL_GOLD"SF-CNR 捐赠", ""COL_WHITE"当你兑换了白金 VIP 后,你可以选择将青铜 VIP 赠送给某人.\n\n如果你想将其赠送给自己,请输入你的姓名/id 或你要赠送的人.\n\n"COL_ORANGE"如果你还不知道,请取消并私信 " SERVER_OPERATOR " 当你做出决定时就在论坛上!", "礼物吧!", "我会想!" );
			}
			else if ( !IsPlayerConnected( pID ) )
			{
				SendError( playerid, "此玩家不在线." );
				ShowPlayerDialog( playerid, DIALOG_DONATED_PLATBRONZE, DIALOG_STYLE_INPUT, ""COL_GOLD"SF-CNR 捐赠", ""COL_WHITE"当你兑换了白金 VIP 后,你可以选择将青铜 VIP 赠送给某人.\n\n如果你想将其赠送给自己,请输入你的姓名/id 或你要赠送的人.\n\n"COL_ORANGE"如果你还不知道,请取消并私信 " SERVER_OPERATOR " 当你做出决定时就在论坛上!", "礼物吧!", "我会想!" );
			}
			else
			{
				SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[V.I.P]"COL_WHITE" 你已将青铜 VIP 赠送给 %s(%d)!", ReturnPlayerName( pID ), pID );
				SetPlayerVipLevel( pID, VIP_BRONZE );
				ShowPlayerVipRedeemedDialog( playerid );
			}
		}
		else
		{
            AddPlayerNote( playerid, -1, "{CD7F32}青铜VIP" #COL_WHITE );
			SendServerMessage( playerid, "这已记录在你的帐户中,并将在你需要的阶段提供给你,请联系主管." );
			ShowPlayerVipRedeemedDialog( playerid );
		}
	}
	else if ( dialogid == DIALOG_DONATED_DIAGOLD )
	{
		if ( response )
		{
			new
				pID;

			if ( sscanf( inputtext, "u", pID ) )
			{
				SendError( playerid, "请输入玩家的 ID 或姓名." );
				ShowPlayerDialog( playerid, DIALOG_DONATED_DIAGOLD, DIALOG_STYLE_INPUT, ""COL_GOLD"SF-CNR 捐赠", ""COL_WHITE"当你兑换了钻石 VIP 后,你可以选择将金币 VIP 赠送给某人.\n\n如果你想将其赠送给自己,请输入你的姓名/id 或你要赠送的人.\n\n"COL_ORANGE"如果你还不知道,请取消并私信 " SERVER_OPERATOR " 当你做出决定时就在论坛上!", "礼物吧!", "我会想!" );
			}
			else if ( !IsPlayerConnected( pID ) )
			{
				SendError( playerid, "此玩家不在线." );
				ShowPlayerDialog( playerid, DIALOG_DONATED_DIAGOLD, DIALOG_STYLE_INPUT, ""COL_GOLD"SF-CNR 捐赠", ""COL_WHITE"当你兑换了钻石 VIP 后,你可以选择将金币 VIP 赠送给某人.\n\n如果你想将其赠送给自己,请输入你的姓名/id 或你要赠送的人.\n\n"COL_ORANGE"如果你还不知道,请取消并私信 " SERVER_OPERATOR " 当你做出决定时就在论坛上!", "礼物吧!", "我会想!" );
			}
			else
			{
				SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[V.I.P]"COL_WHITE" 你已将金币 VIP 赠送给 %s(%d)!", ReturnPlayerName( pID ), pID );
				SetPlayerVipLevel( pID, VIP_GOLD );
				ShowPlayerVipRedeemedDialog( playerid );
			}
		}
		else
		{
            AddPlayerNote( playerid, -1, ""COL_GOLD"黄金 VIP" #COL_WHITE );
			SendServerMessage( playerid, "这已记录在你的帐户中,并将在你需要的阶段提供给你,请联系主管." );
			ShowPlayerVipRedeemedDialog( playerid );
		}
	}
	return 1;
}

/* ** Commands ** */
CMD:ic( playerid, params[ ] ) return cmd_irresistiblecoins( playerid, params );
CMD:irresistiblecoins( playerid, params[ ] )
{
	if ( ! IsPlayerSecurityVerified( playerid ) )
		return SendError( playerid, "使用此功能需要先验证账号. "COL_YELLOW"(输入 /verify)" );

	if ( strmatch( params, "balance" ) )
	{
		return SendServerMessage( playerid, "你目前拥有精确的 "COL_GOLD"%s"COL_WHITE" IC 代币!", number_format( GetPlayerIrresistibleCoins( playerid ) ) );
	}
	else if ( strmatch( params, "market" ) )
	{
		return ShowPlayerCoinMarketDialog( playerid );
	}
	else if ( !strcmp( params, "send", false, 4 ) )
	{
		new
			senttoid, Float: coins;

	    if ( sscanf( params[ 5 ],"uf", senttoid, coins ) ) return SendUsage( playerid, "/irresistiblecoins send [PLAYER_ID] [COINS]" );
	    else if ( !IsPlayerConnected( senttoid ) || IsPlayerNPC( senttoid ) ) return SendError( playerid, "玩家 ID 无效." );
		else if ( p_VIPLevel[ playerid ] < VIP_BRONZE ) return SendError( playerid, "你还不是青铜 VIP, 请前往以下地址开通: "COL_GREY"donate.sfcnr.com" );
	    else if ( coins < 0.1 || coins > 10000.0 ) return SendError( playerid, "你一次只能发送 0.1 到 10,000.0 个硬币." );
		else if ( coins > 99999999 || coins < 0 ) return SendError( playerid, "你一次只能发送 0.1 到 5,000.0 个硬币." ); // Making cash go over billions...
	    else if ( GetPlayerIrresistibleCoins( playerid ) < coins ) return SendError( playerid, "你没有可&#8203;&#8203;以发送的硬币数量." );
	    else if ( GetPlayerScore( playerid ) < 1000 ) return SendError( playerid, "你至少需要 1,000 分数 才能向其他玩家发送硬币." );
		else if ( senttoid == playerid ) return SendError( playerid, "你不能给自己发送硬币." );
	    else
	    {
	    	if ( GetDistanceBetweenPlayers( playerid, senttoid ) > 8.0 || p_Spectating{ senttoid } )
				return SendError( playerid, "在向玩家发送硬币之前,请确保你离玩家很近." );

	    	format( szNormalString, sizeof( szNormalString ), "INSERT INTO `TRANSACTIONS_IC` (`TO_ID`, `FROM_ID`, `IC`) VALUES (%d, %d, %f)", p_AccountID[ senttoid ], p_AccountID[ playerid ], coins );
	     	mysql_single_query( szNormalString );

	    	GivePlayerIrresistibleCoins( senttoid, coins );
	    	GivePlayerIrresistibleCoins( playerid, -coins );

            SendServerMessage( playerid, "你已发送 "COL_GOLD"%s"COL_WHITE" IC 代币 到 %s(%d)!", number_format( coins, .decimals = 2 ), ReturnPlayerName( senttoid ), senttoid );
            SendServerMessage( senttoid, "你已收到 "COL_GOLD"%s"COL_WHITE" IC 代币 来自 %s(%d)!", number_format( coins, .decimals = 2 ), ReturnPlayerName( playerid ), playerid );
		}
		return 1;
	}
	return SendUsage( playerid, "/irresistiblecoins [BALANCE/BUY/SELL/MARKET/SEND/CANCEL]" );
}

CMD:donate( playerid, params[ ] ) return cmd_vip( playerid, params );
CMD:vip( playerid, params[ ] )
{
	p_SelectedPackage{ playerid } = -1;
	ShowPlayerDialog( playerid, DIALOG_VIP_MAIN, DIALOG_STYLE_TABLIST, ""COL_GOLD"VIP 套餐", "{4EE2EC}钻石VIP\t"COL_GREEN"$100.00 美元 \n{E0E0E0} 白金 VIP\t"COL_GREEN"$50.00 美元\n"COL_GOLD"金 VIP\t"COL_GREEN"$25.00 美元 \n{CD7F32} 青铜 VIP\t"COL_GREEN"$15.00 美元\n"COL_GREY"常规 VIP\t"COL_GREEN"$5.00 美元", "选择", "关闭" );
	return 1;
}

CMD:vipcmds( playerid, params[ ] )
{
	if ( p_VIPLevel[ playerid ] < 1 ) return SendError( playerid, "你还不是 VIP, 请前往以下地址开通: "COL_GREY"donate.sfcnr.com" );

	erase( szLargeString );
	strcat( szLargeString,	""COL_GREY"/vipspawnwep"COL_WHITE" - 设置出生时携带的武器\n"\
							""COL_GREY"/vipskin"COL_WHITE" - 配置你的生成皮肤\n"\
							""COL_GREY"/viplist"COL_WHITE" - 所有在线 VIP 的列表.玩家.\n"\
							""COL_GREY"/vipgun"COL_WHITE" - 从枪柜里兑换武器或装甲背心\n"\
							""COL_GREY"/vsay"COL_WHITE" -全球VIP聊天\n"\
							""COL_GREY"/vipjob"COL_WHITE" - 设置 VIP 副职业, 同时拥有两份职业.\n"\
							""COL_GREY"/mynotes"COL_WHITE" - 访问你的 VIP 笔记和材料" );

	ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, ""COL_GOLD"VIP 命令", szLargeString, "确定", "" );
	return 1;
}

/* ** Functions ** */
stock ShowPlayerCoinMarketDialog( playerid, page = ICM_PAGE_DEFAULT )
{
	// if ( p_accountSecurityData[ playerid ] [ E_ID ] && ! p_accountSecurityData[ playerid ] [ E_VERIFIED ] && p_accountSecurityData[ playerid ] [ E_MODE ] != SECURITY_MODE_DISABLED )
	// 	return SendError( playerid, "You must be verified in order to use this feature. "COL_YELLOW"(use /verify)" );

	new Float: discount = GetGVarFloat( "vip_discount" );
	new szMarket[ 512 ] = ""COL_GREY"物品名称\t"COL_GREY"需要金币\n";

	if ( page == ICM_PAGE_DEFAULT )
	{
		//new current_vip = GetPlayerVIPLevel( playerid );

		for( new i = 0; i < sizeof( g_irresistibleVipItems ); i++ )
		{
			new Float: iCoinRequirement = g_irresistibleVipItems[ i ] [ E_PRICE ] * discount;

			/*if ( current_vip != 0 && current_vip != g_irresistibleVipItems[ i ] [ E_ID ] ) {
				format( szMarket, sizeof( szMarket ), "%s{333333}%s\t{333333}%s\n", szMarket, g_irresistibleVipItems[ i ] [ E_NAME ], number_format( iCoinRequirement, .decimals = 0 ) );
			} else { }*/

			format( szMarket, sizeof( szMarket ), "%s%s\t"COL_GOLD"%s\n", szMarket, g_irresistibleVipItems[ i ] [ E_NAME ], number_format( iCoinRequirement, .decimals = 0 ) );
		}

		// thats it
		strcat( szMarket, ""COL_GREEN"购买鲨鱼卡...\t"COL_GREEN">>>\n" );
		strcat( szMarket, ""COL_PURPLE"购买优质住宅...\t"COL_PURPLE">>>\n" );
		strcat( szMarket, ""COL_GREY"查看其他项目...\t"COL_GREY">>>" );
		return ShowPlayerDialog( playerid, DIALOG_IC_MARKET, DIALOG_STYLE_TABLIST_HEADERS, ""COL_GOLD"IC 代币 -"COL_WHITE" 市场", szMarket, "选择", "" );
	}
	else if ( page == ICM_PAGE_CASHCARD )
	{
		szMarket = ""COL_GREY"现金卡\t"COL_GREY"金额 ($)\t"COL_GREY"需要金币\n";

		for( new i = 0; i < sizeof( g_irresistibleCashCards ); i++ )
		{
			new iCoinRequirement = floatround( g_irresistibleCashCards[ i ] [ E_PRICE ] * discount );
			format( szMarket, sizeof( szMarket ), "%s%s\t"COL_GREEN"%s\t"COL_GOLD"%s\n", szMarket, g_irresistibleCashCards[ i ] [ E_NAME ], number_format( g_irresistibleCashCards[ i ] [ E_ID ] ), number_format( iCoinRequirement, .decimals = 0 ) );
		}
		return ShowPlayerDialog( playerid, DIALOG_IC_MARKET_3, DIALOG_STYLE_TABLIST_HEADERS, ""COL_GOLD"IC 代币 -"COL_WHITE" 现金卡", szMarket, "选择", "返回" );
	}
	else
	{
		for( new i = 0; i < sizeof( g_irresistibleMarketItems ); i++ )
		{
			new iCoinRequirement = floatround( g_irresistibleMarketItems[ i ] [ E_PRICE ] * discount );
			format( szMarket, sizeof( szMarket ), "%s%s\t"COL_GOLD"%s\n", szMarket, g_irresistibleMarketItems[ i ] [ E_NAME ], number_format( iCoinRequirement, .decimals = 0 ) );
		}
		return ShowPlayerDialog( playerid, DIALOG_IC_MARKET_2, DIALOG_STYLE_TABLIST_HEADERS, ""COL_GOLD"IC 代币 -"COL_WHITE" 资产市场", szMarket, "选择", "返回" );
	}
}

stock GetPlayerHouseSlots( playerid )
{
	new vip_level = GetPlayerVIPLevel( playerid );
	new slots = 3;

	switch( vip_level )
	{
		case VIP_DIAMOND:
			slots = 255; // infinite

		case VIP_PLATINUM:
			slots = 10;

		case VIP_GOLD:
			slots = 8;

		case VIP_BRONZE:
			slots = 6;

		case VIP_REGULAR:
			slots = 5;
	}
	return slots; // + p_ExtraAssetSlots{ playerid };
}

stock GetPlayerBusinessSlots( playerid ) return GetPlayerHouseSlots( playerid );
stock GetPlayerGarageSlots( playerid ) return GetPlayerHouseSlots( playerid );

stock GetPlayerVehicleSlots( playerid )
{
	static const
		slots[ 6 ] = { 3, 4, 6, 8, 10, 20 };

	return slots[ GetPlayerVIPLevel( playerid ) ] + p_ExtraAssetSlots{ playerid };
}

stock GetPlayerPimpVehicleSlots( playerid )
{
	static const
		slots[ 6 ] = { 2, 3, 4, 6, 8, 10 };

	return slots[ GetPlayerVIPLevel( playerid ) ];
}

stock VIPToString( viplvl )
{
	static
		string[ 16 ];

	switch( viplvl )
	{
	    case VIP_DIAMOND: string = "钻石";
	    case VIP_PLATINUM: string = "铂";
	    case VIP_GOLD: string = "金子";
		case VIP_BRONZE: string = "青铜";
		case VIP_REGULAR: string = "常规的";
		default: string = "N/A";
	}
	return string;
}

stock VIPToColor( viplvl )
{
	static
		string[ 16 ];

	switch( viplvl )
	{
	    case VIP_DIAMOND: string = COL_DIAMOND;
	    case VIP_PLATINUM: string = COL_PLATINUM;
	    case VIP_GOLD: string = COL_GOLD;
		case VIP_BRONZE: string = COL_BRONZE;
		case VIP_REGULAR: string = COL_GREY;
		default: string = COL_WHITE;
	}
	return string;
}

stock SetPlayerVipLevel( playerid, level, interval = 2592000, bool: credit_assets = true )
{
	if ( ! IsPlayerConnected( playerid ) )
		return;

	// force upgrade
	if ( p_VIPLevel[ playerid ] < level ) {
		p_VIPLevel[ playerid ] = level;
	}

	// check if player already has vip
	if ( level ) {
	    if ( p_VIPExpiretime[ playerid ] > g_iTime ) p_VIPExpiretime[ playerid ] += interval;
	    else p_VIPExpiretime[ playerid ] += ( g_iTime + interval );
	}

	// expire the players vip if level 0
	else {
		p_VIPExpiretime[ playerid ] = 0;
	}

	// give player appropriate notes/items
	if ( credit_assets )
	{
		switch ( level )
		{
			case VIP_REGULAR:
			{
				GivePlayerCash( playerid, 500000 );
			}
			case VIP_BRONZE:
			{
				GivePlayerCash( playerid, 2500000 );
				AddPlayerNote( playerid, -1, COL_GOLD # "VIP 房子(青铜)" # COL_WHITE );
				SendClientMessageToAdmins( -1, ""COL_PINK"[VIP NOTE]"COL_GREY" %s(%d) needs a House. (/viewnotes)", ReturnPlayerName( playerid ), playerid );
			}
			case VIP_GOLD:
			{
				GivePlayerCash( playerid, 5000000 );
				AddPlayerNote( playerid, -1, COL_GOLD # "VIP 房子 (金)" # COL_WHITE );
				AddPlayerNote( playerid, -1, COL_GOLD # "VIP 车辆(金)" # COL_WHITE );
				SendClientMessageToAdmins( -1, ""COL_PINK"[VIP NOTE]"COL_GREY" %s(%d) needs a House and Vehicle. (/viewnotes)", ReturnPlayerName( playerid ), playerid );
			}
			case VIP_PLATINUM:
			{
				GivePlayerCash( playerid, 12500000 );
				AddPlayerNote( playerid, -1, COL_GOLD # "VIP 房子 (白金)" # COL_WHITE );
				AddPlayerNote( playerid, -1, COL_GOLD # "VIP 车辆(白金)" # COL_WHITE );
				AddPlayerNote( playerid, -1, COL_GOLD # "VIP 车库" # COL_WHITE );
				SendClientMessageToAdmins( -1, ""COL_PINK"[VIP NOTE]"COL_GREY" %s(%d) needs a House, Vehicle and Garage. (/viewnotes)", ReturnPlayerName( playerid ), playerid );
			}
			case VIP_DIAMOND:
			{
				GivePlayerCash( playerid, 25000000 );
				AddPlayerNote( playerid, -1, COL_GOLD # "VIP 房子 (钻石)" # COL_WHITE );
				AddPlayerNote( playerid, -1, COL_GOLD # "VIP 车辆(钻石)" # COL_WHITE );
				AddPlayerNote( playerid, -1, COL_GOLD # "VIP 车库(钻石)" # COL_WHITE );
				AddPlayerNote( playerid, -1, COL_GOLD # "VIP 门(钻石)" # COL_WHITE );
				AddPlayerNote( playerid, -1, COL_GOLD # "VIP 大麻 商业(钻石)" # COL_WHITE );
				SendClientMessageToAdmins( -1, ""COL_PINK"[VIP NOTE]"COL_GREY" %s(%d) needs a House, Vehicle, Garage, Gate and Weed Biz. (/viewnotes)", ReturnPlayerName( playerid ), playerid );
			}
		}
	}
}

static stock CheckPlayerVipExpiry( playerid )
{
    if ( p_VIPLevel[ playerid ] > 0 && g_iTime > p_VIPExpiretime[ playerid ] )
    {
		SetPlayerArmour( playerid, 0.0 );
        p_VIPExpiretime[ playerid ] = 0;
        SendClientMessage( playerid, -1, ""COL_GREY"[通知]"COL_WHITE" 你的 VIP 已过期,请考虑再次捐赠,以使你的 VIP 再次恢复一段时间." );
        p_VIPLevel[ playerid ] = 0;
        p_VIPWep1{ playerid } = 0;
        p_VIPWep2{ playerid } = 0;
        p_VIPWep3{ playerid } = 0;
	}
}

static stock ShowPlayerVipRedeemedDialog( playerid )
{
	szLargeString[ 0 ] = '\0';
	strcat( szLargeString,	""COL_WHITE"你已使用 IC 代币开通 VIP, 恭喜! :D\n\n"\
							""COL_GREY" * 命令是什么?"COL_WHITE" 使用 /vipcmds 查看 VIP 命令的详细列表.\n"\
							""COL_GREY" * 我收到了什么?"COL_WHITE" 通过我们的网站(论坛 -> 公告板)检查你的 VIP 包裹内容.\n" );
	strcat( szLargeString,	""COL_GREY" * 如何赎回我的房屋/vehicles?"COL_WHITE" 你将被通知给管理员并记录下来寻求帮助,所以请稍候!\n"\
							""COL_GREY" * 我不确定,有帮助吗?"COL_WHITE" 如有疑问, 请输入 /ask 联系管理员, 或咨询" SERVER_OPERATOR " 通过论坛!\n\n感谢你选择花费 IC 代币,享受你所拥有的! :P"  );
	ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, ""COL_GOLD"SF-CNR 捐赠", szLargeString, "明白了!", "" );
}

stock SendClientMessageToVips( colour, const format[ ], va_args<> )
{
    static
		out[ 144 ];

    va_format( out, sizeof( out ), format, va_start<2> );

	foreach ( new i : Player ) if ( p_VIPLevel[ i ] >= VIP_REGULAR ) {
		SendClientMessage( i, colour, out );
	}
	return 1;
}

stock IsPlayerPlatinumVIP( playerid ) return p_VIPLevel[ playerid ] >= VIP_PLATINUM;

stock Float: GetPlayerIrresistibleCoins( playerid ) {
	return p_IrresistibleCoins[ playerid ];
}

stock GivePlayerIrresistibleCoins( playerid, Float: amount )
{
	// set variable prior, then just save the value of it
	p_IrresistibleCoins[ playerid ] += amount;

	// save player coins on a out/inflow of coins
	mysql_single_query( sprintf( "UPDATE `USERS` SET `COINS` = %f WHERE `ID` = %d", p_IrresistibleCoins[ playerid ], GetPlayerAccountID( playerid ) ) );
}

stock SetPlayerIrresistibleCoins( playerid, Float: amount ) {
	GivePlayerIrresistibleCoins( playerid, - p_IrresistibleCoins[ playerid ] + amount );
}

stock SetPlayerExtraSlots( playerid, slots ) {
	p_ExtraAssetSlots{ playerid } = slots;
}
