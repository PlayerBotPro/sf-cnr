/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\info_pickups.pwn
 * Purpose: informational pickups located between features
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Variables ** */
enum E_INFO_PICKUP_DATA
{
	Float: E_X,					Float: E_Y, 				Float: E_Z,
	E_PICKUP_ID,				E_TEXT[ 128 ]
};

static stock
	g_informationPickupsData 		[ ] [ E_INFO_PICKUP_DATA ] =
	{
		{ -2118.1787, -77.9626, 35.3203, 0xFFFF, "{FFFFFF}在这里,你可以通过将拖车连接到卡车上然后前往 /work 来完成卡车运输任务!" }, 		// Trucking
		{ -2025.9523, -136.965, 35.2906, 0xFFFF, "{FFFFFF}曾经想过要破坏吗?作为乘客进入房车并开始产生 冰毒!确保你有材料!" }, 	// Meth
		{ -1497.1375, 914.6858, 7.18750, 0xFFFF, "{FFFFFF}所有平民都应该将钱存入银行,以保护自己并节省一些税款!" }, 						// Bank
		{ -2450.2261, 752.2170, 35.1719, 0xFFFF, "{FFFFFF}购买可以帮助你完成冰毒生产等任务的材料,或者购买其他必需品!" }, 			// Supa
		{ -1589.4668, 115.8173, 3.54950, 0xFFFF, "{FFFFFF}肮脏的机械师可以出口车辆并根据可以从车辆上获取的材料接收金钱!" },	 		// Car Jacker
		{ -2767.3765, 1257.077, 11.7703, 0xFFFF, "{FFFFFF}你可以开采矿石并将矿石储存在沙丘中以供出口!拿起铁锹,挖矿石吧!" },						// Mining
		{ 1954.71890, 1038.251, 992.859, 0xFFFF, "{FFFFFF}在老虎机上试试你的运气,也许你可能会赢得巨额奖金!" },										// Slots
		{ 1955.69070, 1005.167, 992.468, 0xFFFF, "{FFFFFF}轮盘赌最高可支付 $3.5M!单注返还 35x 你的资金,而外围投注则可返还 2x 至 3x!" },			// Roulette
		{ 2085.5896, 1239.4589, 414.745, 0xFFFF, "{FFFFFF}在便利店购买原料后可制作冰毒! 输入 /meth cook, 瞄准并射击各原料进行添加!" }, 		// Meth Cook
		{ -1486.1608, 701.3732, 7.17900, 0xFFFF, "{FFFFFF}找一艘船,绕海航行,每隔几秒就钓到一条鱼." }		 									// Fishing
	}
;

/* ** Hooks ** */
hook OnScriptInit( )
{
	for( new i = 0; i < sizeof( g_informationPickupsData ); i++ )
	{
		g_informationPickupsData[ i ] [ E_PICKUP_ID ] = CreateDynamicPickup( 1239, 2, g_informationPickupsData[ i ] [ E_X ], g_informationPickupsData[ i ] [ E_Y ], g_informationPickupsData[ i ] [ E_Z ] );

		// dont need map icons for interior infos
		if ( g_informationPickupsData[ i ] [ E_Z ] < 800.0 ) {
			CreateDynamicMapIcon( g_informationPickupsData[ i ] [ E_X ], g_informationPickupsData[ i ] [ E_Y ], g_informationPickupsData[ i ] [ E_Z ], 37, 0, -1, -1, -1, 50.0 );
		}
	}
	return 1;
}

hook OnPlayerPickUpDynPickup( playerid, pickupid )
{
	for( new i = 0; i < sizeof( g_informationPickupsData ); i++ ) if ( g_informationPickupsData[ i ] [ E_PICKUP_ID ] == pickupid ) {
		return ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "{FFFFFF}地区信息", g_informationPickupsData[ i ] [ E_TEXT ], "确定", "" ), Y_HOOKS_BREAK_RETURN_1;
	}
	return 1;
}
