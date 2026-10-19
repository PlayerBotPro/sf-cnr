/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\houses\house.pwn
 * Purpose: player house system
 */

/* ** Error checking ** */
#if !defined __sfcnr__houses
	#define __sfcnr__houses
#endif

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_HOUSES                  ( 2000 )
#define MAX_HOUSE_WEAPONS           ( 7 ) 		// (do not change)
#define HOUSE_MAPICON_RADIUS 		( 25.0 )

#define H_DEFAULT_X					266.4996
#define H_DEFAULT_Y					304.9577
#define H_DEFAULT_Z					999.1484

/* ** Macros ** */
#define IsPlayerHomeOwner(%0,%1)	( strmatch( g_houseData[ %1 ] [ E_OWNER ], ReturnPlayerName( %0 ) ) )
#define IsValidHouse(%0)			( 0 <= %0 < MAX_HOUSES && Iter_Contains( houses, %0 ) )
#define GetPlayerEnteredHouse(%0)	( p_InHouse[ %0 ] )

/* ** Variables ** */
enum E_HOUSE_DATA
{
	E_OWNER[ 24 ],    	E_HOUSE_NAME[ 30 ],

	Float: E_EX,      	Float: E_EY,           	Float: E_EZ,
	Float: E_TX,     	Float: E_TY,          	Float: E_TZ,

	E_COST,        		E_INTERIOR_ID,          E_CHECKPOINT[ 2 ],
	E_WORLD, 			Text3D: E_LABEL [ 2 ], 	E_PASSWORD[ 5 ],

	bool: E_CRACKED, 	bool: E_BEING_CRACKED,  E_CRACKED_TS,
	E_CRACKED_WAIT,		E_MAP_ICON
};

enum E_HINTERIOR_DATA
{
	E_NAME[ 19 ], 		Float: E_EX, 				Float: E_EY,
	Float: E_EZ, 		E_INTERIOR_ID, 				E_COST,
	bool: E_VIP,		Float: E_PREVIEW_POS[ 3 ],	Float: E_PREVIEW_LOOKAT[ 3 ]
};

new
	g_houseInteriors[ ] [ E_HINTERIOR_DATA ] =
  	{
      	{ "Cattus Interior",   	H_DEFAULT_X, H_DEFAULT_Y, H_DEFAULT_Z, 	2,  0,	false, { 266.60010, 302.42820, 999.14840 }, { 271.44260, 306.64240, 999.15580 } },
   		{ "Assum Interior",   	243.71980, 304.963500, 999.14840, 	1,  10000,	false, { 249.61870, 300.89080, 999.14840 }, { 244.85410, 305.49680, 999.14840 } },
      	{ "Fossor Interior", 	2218.4036, -1076.2621, 1050.4844,	1,	15000,	false, { 2202.6704, -1078.198, 1050.4844 }, { 2211.8030, -1074.362, 1050.4844 } },
      	//{ "Angusto Interior", 	260.98790, 1284.29470, 1080.2578,	4,	20000,	false, { 253.80180, 1294.2167, 1080.2578 }, { 258.55260, 1288.3639, 1080.2578 } },
      	{ "Organum Interior", 	309.37170, 311.674700, 1003.3047,	4,  25000,	false, { 310.13720, 310.80550, 1003.3047 }, { 300.02930, 300.86170, 1003.5391 } },
      	//{ "Bulbus Interior", 	-68.84510, 1351.19570, 1080.2109,	6,	25000,	false, { -71.41990, 1366.0359, 1080.2185 }, { -64.59070, 1360.7052, 1080.2185 } },
      	//{ "Vindemia Interior", 	295.08510, 1472.25520, 1080.2578,	15,	25000,	false, { 290.14430, 1488.8372, 1080.2578 }, { 294.96960, 1483.6603, 1080.2578 } },
      	{ "Aurora Interior", 	-2170.344, 639.502500, 1052.3750,	1,	30000,	false, { -2168.073, 646.40000, 1057.5938 }, { -2158.598, 638.13010, 1057.5861 } },
      	{ "Fragor Interior",   	318.58580, 1114.47920, 1083.8828,	5,	35000,	false, { 326.31450, 1117.5468, 1083.8828 }, { 317.28550, 1122.6113, 1083.8828 } },
      	//{ "Mundus Interior", 	24.012500, 1340.15890, 1084.3750,	10,	40000,	false, { 19.801100, 1340.7814, 1084.3750 }, { 34.253800, 1342.9272, 1084.3750 } },
      	{ "Artus Interior", 	2237.5259, -1081.6458, 1049.0234,	2,	40000,	false, { 2236.2290, -1081.065, 1049.0234 }, { 2244.2285, -1069.357, 1049.0234 } },
      	{ "Caelum Interior", 	2233.6931, -1115.2620, 1050.8828,	5,	40000,	false, { 2235.1128, -1114.911, 1050.8828 }, { 2229.8982, -1105.175, 1050.8903 } },
      	{ "Rotta Interior",		2495.9663, -1692.0857, 1014.7422,	3,	50000,	false, { 2491.1794, -1694.953, 1014.7461 }, { 2497.4587, -1704.258, 1014.7422 } },
      	{ "Ascensor Interior", 	2317.8369, -1026.7662, 1050.2178,	9,	50000,	false, { 2320.9111, -1025.776, 1050.2109 }, { 2319.0242, -1014.091, 1050.2109 } },
      	{ "Colonel Interior",	2807.5693, -1174.7520, 1025.5703,	8,	60000,	false, { 2812.0911, -1173.043, 1025.5703 }, { 2806.0210, -1165.486, 1025.5703 } },
      	//{ "Godfather Interior", 140.28170, 1365.92150, 1083.8594,	5,	65000,	false, { 135.53440, 1366.6400, 1083.8615 }, { 143.49590, 1375.7461, 1083.8668 } },
      	{ "Recens Interior",	2270.4192, -1210.5172, 1047.5625,	10,	70000,	false, { 2248.2854, -1207.207, 1049.0234 }, { 2261.0574, -1213.011, 1049.0234 } },
      	{ "Novus Interior",		2365.2341, -1135.5957, 1050.8826,	8,	72000,	false, { 2375.3567, -1121.340, 1050.8750 }, { 2367.7095, -1130.863, 1050.8826 } },
      	{ "Securuse Interior",	2324.3826, -1149.5442, 1050.7101,	12,	80000,	false, { 2317.5684, -1136.016, 1054.3047 }, { 2333.1262, -1147.694, 1050.7031 } },
      	//{ "Lorem Interior", 	234.13900, 1063.72110, 1084.2123,	6,	82500,	false, { 235.83530, 1070.2394, 1084.1903 }, { 226.63560, 1073.0388, 1086.2266 } },
      	//{ "Domus Interior", 	225.73480, 1021.44500, 1084.0177,	7,	120000,	false, { 224.76680, 1022.3558, 1084.0150 }, { 241.65380, 1037.2081, 1084.0118 } },
      	{ "Madd Doggs Mansion", 1260.6455, -785.46530, 1091.9063,	5,	1337,	true , { 1262.1033, -772.6712, 1091.9063 }, { 1282.7361, -783.5193, 1089.9375 } },
      	{ "Butcher Interior", 	964.93310, 2160.13210, 1011.0303, 	1,	1337,	true , { 933.67050, 2118.9556, 1012.8329 }, { 947.38930, 2163.8730, 1011.0234 } },
      	{ "Bar Interior", 		501.93780, -67.563000, 998.75780, 	11, 1337,	true , { 511.80380, -68.01930, 999.25000 }, { 490.78870, -78.92080, 998.75780 } },
      	{ "Casino Interior", 	1133.1831, -15.833100, 1000.6797, 	12, 1337,	true , { 1114.8433, -12.31790, 1003.0643 }, { 1136.3059, 2.6477000, 1000.6797 } }
  	},
	g_houseData                     [ MAX_HOUSES ] [ E_HOUSE_DATA ],
	Iterator: houses 				< MAX_HOUSES >,

	szg_houseInteriors				[ 24 * sizeof( g_houseInteriors ) ],
	g_HouseWeapons					[ MAX_HOUSES ] [ MAX_HOUSE_WEAPONS ],
	g_HouseWeaponAmmo				[ MAX_HOUSES ] [ MAX_HOUSE_WEAPONS ],

	p_InHouse                       [ MAX_PLAYERS ]
;


static const g_houseInteriorDisplayNames[][48] =
{
	"卡图斯内饰",
	"阿萨姆内饰",
	"福索尔内饰",
	"欧加努内饰",
	"极光内饰",
	"弗拉戈内饰",
	"阿图斯内饰",
	"凯勒姆内饰",
	"罗塔内饰",
	"升腾内饰",
	"内政上校",
	"最新内饰",
	"诺伟斯内饰",
	"安全内饰",
	"麦德道格斯大厦",
	"屠夫内饰",
	"酒吧内饰",
	"赌场内部"
};

/* ** Hooks ** */
hook OnScriptInit( )
{
	// load all house interiors into a string once
	for( new i = 0; i < sizeof( g_houseInteriors ); i++ ) {
		format( szg_houseInteriors, sizeof( szg_houseInteriors ), "%s%s%s\n", szg_houseInteriors, g_houseInteriors[ i ] [ E_VIP ] ? ( COL_GOLD ) : "", g_houseInteriorDisplayNames[ i ] );
	}

	// load all houses
	mysql_function_query( dbHandle, "SELECT * FROM `HOUSES`", true, "OnHouseLoad", "" );
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_HOUSE_SELL && response )
	{
		new
			ID = GetPVarInt( playerid, "house_sell_id" );

		if ( ! Iter_Contains( houses, ID ) || ! IsPlayerHomeOwner( playerid, ID ) ) {
			return SendError( playerid, "你无权使用此功能." );
		}

		format( szBigString, sizeof( szBigString ), "[出售] [%s] %s | %s | %d\r\n", getCurrentDate( ), ReturnPlayerName( playerid ), g_houseData[ ID ][ E_OWNER ], ID );
		AddFileLogLine( "log_houses.txt", szBigString );
		p_OwnedHouses[ playerid ] --;
		SetHouseForAuction( ID );
		GivePlayerCash( playerid, ( g_houseData[ ID ] [ E_COST ] / 2 ) );
		SetPlayerPos( playerid, g_houseData[ ID ] [ E_EX ], g_houseData[ ID ] [ E_EY ], g_houseData[ ID ] [ E_EZ ] );
		SetPlayerInterior( playerid, 0 ), SetPlayerVirtualWorld( playerid, 0 );
		SendServerMessage( playerid, "你已经成功卖掉了你的房子 "COL_GOLD"%s", cash_format( ( g_houseData[ ID ] [ E_COST ] / 2 ) ) );

		DeletePVar( playerid, "house_sell_id" );
		return 1;
	}
	else if ( dialogid == DIALOG_HOUSE_CONFIG && response )
	{
		if ( p_InHouse[ playerid ] == -1 ) return SendError( playerid, "你不在任何房子里." );
        if ( !strmatch( g_houseData[ p_InHouse[ playerid ] ] [ E_OWNER ], ReturnPlayerName( playerid ) ) ) return SendError( playerid, "你不是这所房子的主人." );
	   	DeletePVar( playerid, "gate_edititem" ); // Definitely not in the gate dialog lol
		switch( listitem )
		{
		    case 0: ShowPlayerDialog( playerid, DIALOG_HOUSE_TITLE, DIALOG_STYLE_INPUT, "{FFFFFF}设置房屋所有权", ""COL_WHITE"输入你想要更改的房屋产权:", "确认", "返回" );
		    case 1: ShowPlayerDialog( playerid, DIALOG_HOUSE_INTERIORS, DIALOG_STYLE_LIST, "{FFFFFF}房屋内饰", szg_houseInteriors, "选择", "返回" );
		    case 2: ShowPlayerDialog( playerid, DIALOG_HOUSE_SET_PW, DIALOG_STYLE_INPUT, "{FFFFFF}设置房屋密码", ""COL_WHITE"在下面输入你想要的房屋密码.\n\n"COL_GREY"注意:"COL_WHITE" 你可以通过键入 \"N/A\"(不带引号)来禁用它.", "确认", "返回" );
			case 3: ShowHouseWeaponStorage( playerid );
			case 4: ShowPlayerDialog( playerid, DIALOG_FURNITURE, DIALOG_STYLE_LIST, "{FFFFFF}家具", "购买家具\n轻松选择家具\n手动选择家具\n选择最近的家具\n"COL_RED"拆除所有家具", "确认", "返回" );
		}
	}
	else if ( dialogid == DIALOG_HOUSE_WEAPONS )
	{
        if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "在监狱中无法使用此功能." );
	    if ( response )
	    {
	        if ( p_InHouse[ playerid ] == -1 ) return SendError( playerid, "你不在任何房子里." );
	        if ( !strmatch( g_houseData[ p_InHouse[ playerid ] ] [ E_OWNER ], ReturnPlayerName( playerid ) ) ) return SendError( playerid, "你不是这所房子的主人." );
			if ( g_HouseWeapons[ p_InHouse[ playerid ] ] [ listitem ] != 0 )
			{
				GivePlayerWeapon( playerid, g_HouseWeapons[ p_InHouse[ playerid ] ] [ listitem ], g_HouseWeaponAmmo[ p_InHouse[ playerid ] ] [ listitem ] );
			    SendServerMessage( playerid, "你已撤回你的 "COL_GREY"%s"COL_WHITE" 带有%d弹药.", ReturnWeaponName( g_HouseWeapons[ p_InHouse[ playerid ] ] [ listitem ] ), g_HouseWeaponAmmo[ p_InHouse[ playerid ] ] [ listitem ] );
                g_HouseWeapons[ p_InHouse[ playerid ] ] [ listitem ] = 0;
			    g_HouseWeaponAmmo[ p_InHouse[ playerid ] ] [ listitem ] = -1;
                SaveHouseWeaponStorage( p_InHouse[ playerid ] );
			    ShowHouseWeaponStorage( playerid );
			}
			else
			{
				if ( listitem > 2 && p_VIPLevel[ playerid ] < VIP_REGULAR ) return SendError( playerid, "你还不是 VIP, 请前往以下地址开通: "COL_GREY"donate.sfcnr.com" );
				p_HouseWeaponAddSlot{ playerid } = listitem;
				ShowPlayerDialog( playerid, DIALOG_HOUSE_WEAPONS_ADD, DIALOG_STYLE_MSGBOX, "{FFFFFF}房屋武器储藏室", "{FFFFFF}你想将当前武器插入此插槽吗?", "插入", "返回" );
			}
	    }
	    else cmd_h( playerid, "config" );
	}
	else if ( dialogid == DIALOG_HOUSE_WEAPONS_ADD )
	{
	    if ( response )
	    {
            if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "在监狱中无法使用此功能." );
	        if ( p_InHouse[ playerid ] == -1 ) return SendError( playerid, "你不在任何房子里." );
	        if ( !strmatch( g_houseData[ p_InHouse[ playerid ] ] [ E_OWNER ], ReturnPlayerName( playerid ) ) ) return SendError( playerid, "你不是这所房子的主人." );
			if ( IsMeleeWeapon( GetPlayerWeapon( playerid ) ) )
			{
			    SendError( playerid, "你不能插入近战武器." );
			    cmd_h( playerid, "config" );
			    return 1;
			}
			new current_weapon = GetPlayerWeapon( playerid );
			new current_ammo = GetPlayerAmmo( playerid );
			if ( ( 16 <= current_weapon <= 18 ) || current_weapon == 35 ) {
			    SendError( playerid, "你无法存放此武器." );
			    cmd_h( playerid, "config" );
			    return 1;
			}
			if ( current_ammo > 0x7FFF || current_ammo <= 0 ) current_ammo = 0x7FFF;
			listitem = p_HouseWeaponAddSlot{ playerid };
            g_HouseWeapons[ p_InHouse[ playerid ] ] [ listitem ] = current_weapon;
            g_HouseWeaponAmmo[ p_InHouse[ playerid ] ] [ listitem ] = current_ammo;
            SendServerMessage( playerid, "你已插入你的 "COL_GREY"%s"COL_WHITE" 进入你的武器仓库.", ReturnWeaponName( current_weapon ) );
            RemovePlayerWeapon( playerid, current_weapon );
         	SaveHouseWeaponStorage( p_InHouse[ playerid ] );
			ShowHouseWeaponStorage( playerid );
	    }
	    else ShowHouseWeaponStorage( playerid );
	}
	else if ( dialogid == DIALOG_HOUSE_SET_PW )
	{
	    if ( response )
	    {
	        if ( p_InHouse[ playerid ] == -1 ) return SendError( playerid, "你不在任何房子里." );
	        else if ( !strmatch( g_houseData[ p_InHouse[ playerid ] ] [ E_OWNER ], ReturnPlayerName( playerid ) ) ) return SendError( playerid, "你不是这所房子的主人." );
			else if ( !strlen( inputtext ) || strlen( inputtext ) > 4 )
			{
			    SendError( playerid, "你的密码必须在 0 和 4 个字符之间变化." );
				ShowPlayerDialog( playerid, DIALOG_HOUSE_SET_PW, DIALOG_STYLE_INPUT, "{FFFFFF}设置房屋密码", ""COL_WHITE"在下面输入你想要的房屋密码.\n\n"COL_GREY"注意:"COL_WHITE" 你可以通过键入 \"N/A\" 或 \"NULL\"(不带引号)来禁用它.", "确认", "返回" );
			}
			else if ( strmatch( inputtext, "N/A" ) || strmatch( inputtext, "NULL" ) )
			{
				format( g_houseData[ p_InHouse[ playerid ] ] [ E_PASSWORD ], 4, "N/A" );
			    SendServerMessage( playerid, "你已成功禁用你房屋的密码." );
			    format( szNormalString, 60, "UPDATE `HOUSES` SET `PASSWORD`='N/A' WHERE `ID`=%d", p_InHouse[ playerid ] );
			    mysql_single_query( szNormalString );
			    cmd_h( playerid, "config" );
			}
			else
			{
			    SendServerMessage( playerid, "你已将你的房屋密码更改为 "COL_GREY"%s"COL_WHITE".", inputtext );
			    format( g_houseData[ p_InHouse[ playerid ] ] [ E_PASSWORD ], 5, "%s", inputtext );
			    format( szNormalString, 60, "UPDATE `HOUSES` SET `PASSWORD`='%s' WHERE `ID`=%d", mysql_escape( inputtext ), p_InHouse[ playerid ] );
			    mysql_single_query( szNormalString );
			    cmd_h( playerid, "config" );
			}
	    }
	    else cmd_h( playerid, "config" );
	}
	else if ( dialogid == DIALOG_HOUSE_INTERIORS )
	{
	    if ( response )
	    {
	        if ( p_InHouse[ playerid ] == -1 )
				return SendError( playerid, "你不在任何房子里." );

	        if ( !strmatch( g_houseData[ p_InHouse[ playerid ] ] [ E_OWNER ], ReturnPlayerName( playerid ) ) )
				return SendError( playerid, "你不是这所房子的主人." );

			p_ViewingInterior{ playerid } = listitem;
			ShowPlayerDialog( playerid, DIALOG_HOUSE_INT_CONFIRM, DIALOG_STYLE_LIST, "{FFFFFF}房屋内饰", "购买房屋内部\n预览房屋内部", "选择", "返回" );
		}
	    else cmd_h( playerid, "config" );
	}
	else if ( dialogid == DIALOG_HOUSE_INT_CONFIRM )
	{
		if ( response )
		{
	        if ( p_InHouse[ playerid ] == -1 )
				return SendError( playerid, "你不在任何房子里." );

	        if ( !strmatch( g_houseData[ p_InHouse[ playerid ] ] [ E_OWNER ], ReturnPlayerName( playerid ) ) )
				return SendError( playerid, "你不是这所房子的主人." );

			new
				intid = p_ViewingInterior{ playerid };

			switch( listitem )
			{
				case 0:
				{
					if ( g_houseInteriors[ intid ] [ E_COST ] > GetPlayerCash( playerid ) )
					{
						ShowPlayerDialog( playerid, DIALOG_HOUSE_INT_CONFIRM, DIALOG_STYLE_LIST, "{FFFFFF}房屋内饰", "购买房屋内部\n预览房屋内部", "选择", "返回" );
						SendError( playerid, "这个内饰成本 "COL_GOLD"%s"COL_WHITE".你没有这个金额.", cash_format( g_houseInteriors[ intid ] [ E_COST ] ) );
					}
					else if ( g_houseInteriors[ intid ] [ E_VIP ] && !p_VIPLevel[ playerid ] )
					{
						ShowPlayerDialog( playerid, DIALOG_HOUSE_INT_CONFIRM, DIALOG_STYLE_LIST, "{FFFFFF}房屋内饰", "购买房屋内部\n预览房屋内部", "选择", "返回" );
						SendError( playerid, "你还不是 VIP, 请前往以下地址开通: "COL_GREY"donate.sfcnr.com" );
					}
					else if ( ArePlayersInHouse( p_InHouse[ playerid ], playerid ) )
					{
						ShowPlayerDialog( playerid, DIALOG_HOUSE_INT_CONFIRM, DIALOG_STYLE_LIST, "{FFFFFF}房屋内饰", "购买房屋内部\n预览房屋内部", "选择", "返回" );
						SendError( playerid, "如果建筑物内有人,则你无法购买房屋内部." );
					}
					else
					{
						if ( g_houseInteriors[ intid ] [ E_VIP ] && p_VIPLevel[ playerid ] && ( ( p_VIPExpiretime[ playerid ] - g_iTime ) / 86400 ) < 3 )
							return SendError( playerid, "你需要超过 3 天的 VIP 才能完成此任务." );

					    new houseid = p_InHouse[ playerid ];
					    GivePlayerCash( playerid, -( g_houseInteriors[ intid ] [ E_COST ] ) );

					    if ( intid != 0 )
							SendServerMessage( playerid, "你已经购买了%s "COL_GOLD"%s"COL_WHITE".这已应用于房屋 ID %d.", g_houseInteriorDisplayNames[ intid ], cash_format( g_houseInteriors[ intid ] [ E_COST ] ), houseid );
						else
						    SendServerMessage( playerid, "你已成功将内部装饰重置为默认内部装饰." );

		                destroyAllFurniture( houseid );
						FillHomeWithFurniture( houseid, intid );
						g_houseData[ houseid ] [ E_TX ] = g_houseInteriors[ intid ] [ E_EX ];
					    g_houseData[ houseid ] [ E_TY ] = g_houseInteriors[ intid ] [ E_EY ];
					    g_houseData[ houseid ] [ E_TZ ] = g_houseInteriors[ intid ] [ E_EZ ];
					    g_houseData[ houseid ] [ E_INTERIOR_ID ] = g_houseInteriors[ intid ] [ E_INTERIOR_ID ];
					    SetPlayerPos( playerid, g_houseInteriors[ intid ] [ E_EX ], g_houseInteriors[ intid ] [ E_EY ], g_houseInteriors[ intid ] [ E_EZ ] );
					    SetPlayerInterior( playerid, g_houseInteriors[ intid ] [ E_INTERIOR_ID ] );
					    DestroyDynamicCP( g_houseData[ houseid ] [ E_CHECKPOINT ] [ 1 ] );
					    g_houseData[ houseid ] [ E_CHECKPOINT ] [ 1 ] = CreateDynamicCP( g_houseInteriors[ intid ] [ E_EX ], g_houseInteriors[ intid ] [ E_EY ], g_houseInteriors[ intid ] [ E_EZ ], 1.0, g_houseData[ houseid ] [ E_WORLD ], g_houseData[ houseid ] [ E_INTERIOR_ID ], -1, 50.0 );
						format( szBigString, sizeof( szBigString ), "UPDATE HOUSES SET TX=%f, TY=%f, TZ=%f, INTERIOR=%d WHERE ID=%d", g_houseInteriors[ intid ] [ E_EX ], g_houseInteriors[ intid ] [ E_EY ], g_houseInteriors[ intid ] [ E_EZ ], g_houseData[ houseid ] [ E_INTERIOR_ID ], houseid );
						mysql_single_query( szBigString );
						DestroyDynamic3DTextLabel( g_houseData[ houseid ] [ E_LABEL ] [ 1 ] );
						g_houseData[ houseid ] [ E_LABEL ] [ 1 ] = CreateDynamic3DTextLabel( "[出口]", COLOR_GOLD, g_houseData[ houseid ] [ E_TX ], g_houseData[ houseid ] [ E_TY ], g_houseData[ houseid ] [ E_TZ ], 20.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, g_houseData[ houseid ] [ E_WORLD ] );
						pauseToLoad( playerid );
					}
				}
				case 1:
				{
					if ( p_WantedLevel[ playerid ] ) {
						ShowPlayerDialog( playerid, DIALOG_HOUSE_INT_CONFIRM, DIALOG_STYLE_LIST, "{FFFFFF}房屋内饰", "购买房屋内部\n预览房屋内部", "选择", "返回" );
						return SendError( playerid, "此功能要求你不能有 通缉等级." );
					}
					if ( ArePlayersInHouse( p_InHouse[ playerid ], playerid ) ) {
						ShowPlayerDialog( playerid, DIALOG_HOUSE_INT_CONFIRM, DIALOG_STYLE_LIST, "{FFFFFF}房屋内饰", "购买房屋内部\n预览房屋内部", "选择", "返回" );
						return SendError( playerid, "如果建筑物内有人,你将无法查看房屋内部." );
					}
					TogglePlayerControllable( playerid, 0 );
				    SetPlayerPos( playerid, g_houseInteriors[ intid ] [ E_EX ], g_houseInteriors[ intid ] [ E_EY ], g_houseInteriors[ intid ] [ E_EZ ] );
				    SetPlayerInterior( playerid, g_houseInteriors[ intid ] [ E_INTERIOR_ID ] );
					InterpolateCameraPos( playerid, g_houseInteriors[ intid ] [ E_PREVIEW_POS ] [ 0 ], g_houseInteriors[ intid ] [ E_PREVIEW_POS ] [ 1 ], g_houseInteriors[ intid ] [ E_PREVIEW_POS ] [ 2 ] + 1.5, g_houseInteriors[ intid ] [ E_PREVIEW_LOOKAT ] [ 0 ], g_houseInteriors[ intid ] [ E_PREVIEW_LOOKAT ] [ 1 ], g_houseInteriors[ intid ] [ E_PREVIEW_LOOKAT ] [ 2 ], 15000, CAMERA_MOVE );
					InterpolateCameraLookAt( playerid, g_houseInteriors[ intid ] [ E_PREVIEW_LOOKAT ] [ 0 ], g_houseInteriors[ intid ] [ E_PREVIEW_LOOKAT ] [ 1 ], g_houseInteriors[ intid ] [ E_PREVIEW_LOOKAT ] [ 2 ], g_houseInteriors[ intid ] [ E_PREVIEW_POS ] [ 0 ], g_houseInteriors[ intid ] [ E_PREVIEW_POS ] [ 1 ], g_houseInteriors[ intid ] [ E_PREVIEW_POS ] [ 2 ] + 1.5, 15000, CAMERA_MOVE );
					SendServerMessage( playerid, "你现在正在预览 "COL_GREY"%s "COL_GOLD"%s"COL_WHITE".按 Enter 键停止.", g_houseInteriorDisplayNames[ intid ], cash_format( g_houseInteriors[ intid ] [ E_COST ] ) );
					SetPVarInt( playerid, "viewing_houseints", 1 );
				}
			}
		}
		else ShowPlayerDialog( playerid, DIALOG_HOUSE_INTERIORS, DIALOG_STYLE_LIST, "{FFFFFF}房屋内饰", szg_houseInteriors, "选择", "返回" );
	}
	else if ( dialogid == DIALOG_HOUSE_TITLE )
	{
	    if ( response )
	    {
	        if ( p_InHouse[ playerid ] == -1 )
				return SendError( playerid, "你不在任何房子里." );

	        if ( !strmatch( g_houseData[ p_InHouse[ playerid ] ] [ E_OWNER ], ReturnPlayerName( playerid ) ) )
				return SendError( playerid, "你不是这所房子的主人." );

	        if ( ! ( 1 <= strlen( inputtext ) <= 30 ) )
				return ShowPlayerDialog( playerid, DIALOG_HOUSE_TITLE, DIALOG_STYLE_INPUT, "{FFFFFF}设置房屋所有权", ""COL_WHITE"输入你想要更改的房屋产权:\n\n"COL_RED"必须介于 1 和 30 字符之间.", "确认", "返回" );

			if ( textContainsIP( inputtext ) )
				return SendError( playerid, "禁止发布广告." );

			new houseid = p_InHouse[ playerid ];
			format( g_houseData[ houseid ] [ E_HOUSE_NAME ], 30, "%s", inputtext);
			mysql_format( dbHandle, szNormalString, sizeof( szNormalString ), "UPDATE `HOUSES` SET `NAME`='%e' WHERE `ID`=%d", g_houseData[ houseid ] [ E_HOUSE_NAME ], p_InHouse[ playerid ] );
			mysql_single_query( szNormalString );
			format( szBigString, sizeof( szBigString ), ""COL_GOLD"房子:"COL_WHITE" %s(%d)\n"COL_GOLD"所有者:"COL_WHITE" %s\n"COL_GOLD"价格:"COL_WHITE" %s", g_houseData[ houseid ] [ E_HOUSE_NAME ], houseid, g_houseData[ houseid ] [ E_OWNER ], cash_format( g_houseData[ houseid ] [ E_COST ] ) );
 			UpdateDynamic3DTextLabelText( g_houseData[ houseid ] [ E_LABEL ] [ 0 ], COLOR_WHITE, szBigString );
            SendServerMessage( playerid, "你已成功更改房屋名称." );
 			cmd_h( playerid, "config" );
	    }
	    else cmd_h( playerid, "config" );
	}
	else if ( dialogid == DIALOG_HOUSE_PW && response )
	{
		new i = p_PasswordedHouse[ playerid ];
		if ( !strlen( inputtext ) || strlen( inputtext ) > 4 || strmatch( inputtext, "N/A" ) || !strmatch( inputtext, g_houseData[ i ] [ E_PASSWORD ] ) ) ShowPlayerDialog( playerid, DIALOG_HOUSE_PW, DIALOG_STYLE_PASSWORD, "{FFFFFF}房屋认证", ""COL_GREEN"这房子被密码锁住了!\n"COL_WHITE"只有输入正确的密码才能进入这所房子.\n\n"COL_RED"密码不正确!", "进入", "取消" );
		else
		{
			if ( !IsPlayerInRangeOfPoint( playerid, 3.0, g_houseData[ i ] [ E_EX ], g_houseData[ i ] [ E_EY ], g_houseData[ i ] [ E_EZ ] ) ) return SendError( playerid, "你不在房子入口附近!" );
			SendServerMessage( playerid, "密码正确.已授予访问权限." );
			p_InHouse[ playerid ] = i;
			UpdatePlayerEntranceExitTick( playerid );
			SetPlayerPos( playerid, g_houseData[ i ] [ E_TX ], g_houseData[ i ] [ E_TY ], g_houseData[ i ] [ E_TZ ] );
		  	SetPlayerVirtualWorld( playerid, g_houseData[ i ] [ E_WORLD ] );
			SetPlayerInterior( playerid, g_houseData[ i ] [ E_INTERIOR_ID ] );
		}
	}
	return 1;
}

hook OnPlayerEnterDynamicCP( playerid, checkpointid )
{
	if ( CanPlayerExitEntrance( playerid ) && ! IsPlayerInAnyVehicle( playerid ) )
	{
		// Enter Houses
		foreach ( new i : houses )
		{
			if ( checkpointid == g_houseData[ i ] [ E_CHECKPOINT ] [ 0 ] )
			{
				ClearAnimations( playerid ); // clear-fix

				if ( IsHouseOnFire( i ) ) {
					return SendError( playerid, "这房子着火了,你不能进去!" ), 1;
				}

				if ( GetPlayerSpecialAction( playerid ) == SPECIAL_ACTION_CUFFED ) {
					return SendError( playerid, "你已被铐住, 无法操作." ), 1;
				}

				if ( g_iTime > g_houseData[ i ] [ E_CRACKED_TS ] && g_houseData[ i ] [ E_CRACKED ] )
					g_houseData[ i ] [ E_CRACKED ] = false; // The Virus Is Disabled.

				new is_owner = strmatch( g_houseData[ i ] [ E_OWNER ], ReturnPlayerName( playerid ) );

				if ( ! g_houseData[ i ] [ E_CRACKED ] && ! strmatch( g_houseData[ i ] [ E_PASSWORD ], "N/A" ) && ! is_owner )
				{
					p_PasswordedHouse[ playerid ] = i;
					CallLocalFunction( "OnPlayerAttemptBreakIn", "ddd", playerid, i, -1 ); // attempting a break in as a burglar/cop
					ShowPlayerDialog( playerid, DIALOG_HOUSE_PW, DIALOG_STYLE_PASSWORD, "{FFFFFF}房屋认证", ""COL_GREEN"这房子被密码锁住了!\n"COL_WHITE"只有输入正确的密码,你才能进入这所房子.", "进入", "取消" );
					return 1;
				}

				p_InHouse[ playerid ] = i;
				UpdatePlayerEntranceExitTick( playerid );
				SetPlayerVirtualWorld( playerid, g_houseData[ i ] [ E_WORLD ] );
				SetPlayerInterior( playerid, g_houseData[ i ] [ E_INTERIOR_ID ] );
				SetPlayerPos( playerid, g_houseData[ i ] [ E_TX ], g_houseData[ i ] [ E_TY ], g_houseData[ i ] [ E_TZ ] );
				CallLocalFunction( "OnPlayerEnterHouse", "dd", playerid, i );
				return 1;
			}
			else if ( checkpointid == g_houseData[ i ] [ E_CHECKPOINT ] [ 1 ] )
			{
				p_InHouse[ playerid ] = -1;
				CancelEdit( playerid );
				TogglePlayerControllable( playerid, 0 );
				UpdatePlayerEntranceExitTick( playerid );
				SetTimerEx( "ope_Unfreeze", 1250, false, "d", playerid );
				SetPlayerPosEx( playerid, g_houseData[ i ] [ E_EX ], g_houseData[ i ] [ E_EY ], g_houseData[ i ] [ E_EZ ], 0 ), SetPlayerVirtualWorld( playerid, 0 );
				return 1;
			}
		}
	}
	return 1;
}

/* ** Commands ** */
CMD:house( playerid, params[ ] ) return cmd_h( playerid, params );
CMD:h( playerid, params[ ] )
{
	if ( p_accountSecurityData[ playerid ] [ E_ID ] && ! p_accountSecurityData[ playerid ] [ E_VERIFIED ] && p_accountSecurityData[ playerid ] [ E_MODE ] != SECURITY_MODE_DISABLED )
		return SendError( playerid, "使用此功能需要先验证账号. "COL_YELLOW"(输入 /verify)" );

#if VIP_ALLOW_OVER_LIMIT == false
	if ( ! p_VIPLevel[ playerid ] && p_OwnedHouses[ playerid ] > GetPlayerHouseSlots( playerid ) && ! strmatch( params, "sell" ) ) {
		ResetSpawnLocation( playerid );
		return SendError( playerid, "请续费 VIP 或出售此房屋, 使房产数量符合上限 (/h sell)." );
	}
#endif

	new
	    ID = p_InHouse[ playerid ];

	if ( strmatch( params, "spawn" ) )
	{
		SendServerMessage( playerid, "此命令已改为"COL_GREY"/spawn"COL_WHITE"." );
		return ShowPlayerSpawnMenu( playerid );
	}
	else if ( strmatch( params, "config" ) )
	{
		if ( ID == -1 ) return SendError( playerid, "你不在任何房子里." );
		else if ( !strmatch( g_houseData[ ID ] [ E_OWNER ], ReturnPlayerName( playerid ) ) ) return SendError( playerid, "你不是这所房子的主人." );
		else
		{
			szBigString = ""COL_WHITE"选项\t"COL_WHITE"当前值\n";

			format(szBigString, sizeof( szBigString ), "%s设置房屋名称\t%s\n升级内饰\t\n设置房屋密码\t"COL_GREY"%s\n武器储存\t\n家具\t\n",
				szBigString,
				g_houseData[ ID ] [ E_HOUSE_NAME ],
				g_houseData[ ID ] [ E_PASSWORD ] );

		    ShowPlayerDialog( playerid, DIALOG_HOUSE_CONFIG, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}房屋配置", szBigString, "选择", "取消" );
		    //ShowPlayerDialog( playerid, DIALOG_HOUSE_CONFIG, DIALOG_STYLE_LIST, "{FFFFFF}House Configuration", "Set House Title\nUpgrade Interior\nSet House Password\nWeapon Storage\nFurniture", "Select", "Cancel" );
		}
		return 1;
	}
	else if ( strmatch( params, "buy" ) )
	{
		if ( p_OwnedHouses[ playerid ] >= GetPlayerHouseSlots( playerid ) ) return SendError( playerid, "你无法再购买任何房屋,你已达到限制." );
		if ( GetPlayerScore( playerid ) < 200 ) return SendError( playerid, "你至少需要 200 分数 才能买房子." );

		foreach ( new i : houses )
		{
			if ( IsPlayerInDynamicCP( playerid, g_houseData[ i ] [ E_CHECKPOINT ] [ 0 ] ) || ( ID != -1 && ID == i ) )
			{
			    if ( strmatch( g_houseData[ i ] [ E_OWNER ], "No-one" ) )
			    {
			        if ( GetPlayerCash( playerid ) < g_houseData[ i ] [ E_COST ] )
						return SendError( playerid, "你没有足够的钱来购买这所房子." );

					if ( g_houseData[ i ] [ E_COST ] == 1337 && !p_VIPLevel[ playerid ] )
						return SendError( playerid, "你还不是 VIP, 请前往以下地址开通: "COL_GREY"donate.sfcnr.com" );

					GivePlayerCash( playerid, -( g_houseData[ i ] [ E_COST ] ) );
					SendServerMessage( playerid, "你购买此房屋的价格为 "COL_GOLD"%s"COL_WHITE"!", cash_format( g_houseData[ i ] [ E_COST ] ) );
                    SetHouseOwner( i, p_AccountID[ playerid ], ReturnPlayerName( playerid ) );

					p_OwnedHouses[ playerid ] ++;
					return 1;
				}
			    else return SendError( playerid, "这所房子不出售." );
			}
		}
		return SendError( playerid, "你不在任何房屋入口附近." );
	}
	else if ( strmatch( params, "sell" ) )
	{
	    if ( ID == -1 ) return SendError( playerid, "你不在任何房子里." );
		else if ( !strmatch( g_houseData[ ID ] [ E_OWNER ], ReturnPlayerName( playerid ) ) ) return SendError( playerid, "你不是这所房子的主人." );
		else
		{
			SetPVarInt( playerid, "house_sell_id", ID );
			ShowPlayerDialog( playerid, DIALOG_HOUSE_SELL, DIALOG_STYLE_MSGBOX, ""COL_WHITE"卖房子", sprintf( ""COL_WHITE"你确定要以以下价格出售这所房子吗 "COL_GOLD"%s"COL_WHITE"?", cash_format( ( g_houseData[ ID ] [ E_COST ] / 2 ) ) ), "出售", "取消" );
		}
		return 1;
	}
	else if ( strmatch( params, "offer cancel" ) )
	{
		new
			bool: bResults = false;

		foreach(new i : Player)
		{
			if ( p_HouseOfferer[ i ] == playerid )
			{
				bResults = true;
				p_HouseOfferer		[ i ] = INVALID_PLAYER_ID;
				p_HouseOfferTicks	[ i ] = 0;
				p_HouseSellingID	[ i ] = 0;
				p_HouseSellingPrice	[ i ] = 0;
			}
		}

		if ( bResults )
			return SendServerMessage( playerid, "你已成功取消向玩家提供的所有房屋优惠." );

		return SendError( playerid, "你尚未向任何人提出任何房屋报价." );
	}
	else if ( strmatch( params, "offer take" ) )
	{
		new
			houseid = p_HouseSellingID[ playerid ],
			sellerid = p_HouseOfferer[ playerid ],
			sellingprice = p_HouseSellingPrice[ playerid ]
		;

		if ( !IsPlayerConnected( sellerid ) ) SendError( playerid, "为你提供房子的人不再在线." );
		else if ( p_HouseOfferTicks[ playerid ] < g_iTime ) SendError( playerid, "此房屋报价已在 %d 秒前过期.", g_iTime - p_HouseOfferTicks[ playerid ] );
		else if ( GetPlayerCash( playerid ) < p_HouseSellingPrice[ playerid ] ) SendError( playerid, "你没有足够的钱来接受此优惠 (%s).", cash_format( p_HouseSellingPrice[ playerid ] ) );
		else if ( g_houseData[ houseid ] [ E_COST ] <= 1337 && !p_VIPLevel[ playerid ] ) SendError( playerid, "你还不是 VIP, 请前往以下地址开通: "COL_GREY"donate.sfcnr.com" );
		else if ( p_OwnedHouses[ playerid ] >= GetPlayerHouseSlots( playerid ) ) SendError( playerid, "你无法再购买任何房屋,你已达到限制." );
		else
		{
			format( szBigString, sizeof( szBigString ), "[出售给] [%s] %s | %s | %s | %d\r\n", getCurrentDate( ), ReturnPlayerName( playerid ), ReturnPlayerName( sellerid ), cash_format( sellingprice ), houseid );
		    AddFileLogLine( "log_houses.txt", szBigString );

			p_OwnedHouses[ sellerid ] --;
			p_OwnedHouses[ playerid ] ++;

		    // destroyAllFurniture( houseid );
			SetHouseOwner( houseid, p_AccountID[ playerid ], ReturnPlayerName( playerid ) );

			GivePlayerCash( playerid, -sellingprice );
			GivePlayerCash( sellerid, sellingprice );

			SendServerMessage( sellerid, "你已经成功卖掉了你的房子 "COL_GOLD"%s"COL_WHITE" 到 %s(%d)!", cash_format( p_HouseSellingPrice[ playerid ] ), ReturnPlayerName( playerid ), playerid );
			SendServerMessage( playerid, "你已经成功购买了 %s(%d) 的房子 "COL_GOLD"%s"COL_WHITE"!", ReturnPlayerName( sellerid ), sellerid, cash_format( p_HouseSellingPrice[ playerid ] ) );
		}
		return ( p_HouseOfferer[ playerid ] = INVALID_PLAYER_ID ), ( p_HouseOfferTicks[ playerid ] = 0 ), 1;
	}
	else if ( !strcmp( params, "offer", false, 5 ) )
	{
	    new offerid, price;

	    if ( ID == -1 ) return SendError( playerid, "你不在任何房子里." );
		else if ( !strmatch( g_houseData[ ID ] [ E_OWNER ], ReturnPlayerName( playerid ) ) ) return SendError( playerid, "你不是这所房子的主人." );
	    else if ( sscanf( params[ 6 ], "ud", offerid, price ) ) return SendUsage( playerid, "/h offer [PLAYER_ID] [PRICE]" );
	    else if ( !IsPlayerConnected( offerid ) ) return SendError( playerid, "此玩家不在线." );
	    else if ( offerid == playerid ) return SendError( playerid, "你不能向自己提出房屋报价." );
	    else if ( price > 30000000 ) return SendError( playerid, "出售房屋的最高金额是 $30,000,000." );
	    else if ( price < g_houseData[ ID ] [ E_COST ] / 2 ) return SendError( playerid, "你不能以低于一半的成本将你的房子卖给某人." );
		else if ( GetDistanceBetweenPlayers( playerid, offerid ) > 4.0 ) return SendError( playerid, "你无法向不在你附近的玩家发送报价." );
		else if ( p_HouseOfferTicks[ offerid ] > g_iTime ) return SendError( playerid, "请等待 %d 秒,以便再次向该玩家报价.", p_HouseOfferTicks[ offerid ] - g_iTime );
		else if ( g_houseData[ ID ] [ E_COST ] <= 1337 && !p_VIPLevel[ offerid ] ) return SendError( playerid, "你不能向普通玩家提供 VIP 房屋出售." );
		else if ( p_OwnedHouses[ offerid ] >= GetPlayerHouseSlots( offerid ) ) return SendError( playerid, "该玩家无法再购买任何房屋,他们已达到限制." );
		else
	    {
	    	// Cannot sell to non vip vip homes k
			p_HouseOfferer[ offerid ] = playerid;
			p_HouseOfferTicks[ offerid ] = g_iTime + 15;
			p_HouseSellingID[ offerid ] = ID;
			p_HouseSellingPrice[ offerid ] = price;
			SendServerMessage( offerid, "%s(%d) 希望提供他的房子 (id%d)对于%s给你.使用 "COL_GREY"/h offer take"COL_WHITE" 接受邀请.", ReturnPlayerName( playerid ), playerid, ID, cash_format( price ) );
			SendServerMessage( playerid, "你已提供%s(%d) %s你的房子(id%d),取消报价 "COL_GREY"/h offer cancel"COL_WHITE".", ReturnPlayerName( offerid ), offerid, cash_format( price ), ID );
	    }
	    return 1;
	}
	return SendUsage( playerid, "/h [CONFIG/BUY/SELL/OFFER/OFFER TAKE/OFFER CANCEL]" );
}

/* ** SQL Threads ** */
thread OnHouseLoad( )
{
	new
		rows, fields, i = -1,
	    loadingTick = GetTickCount( )
	;

	cache_get_data( rows, fields );
	if ( rows )
	{
		static weapon_info[ 40 ], house_name[ 30 ], password[ 5 ], owner[ 24 ];

		while( ++ i < rows )
		{
			// set name., owner, password again (less memory)
			cache_get_field_content( i, "NAME", house_name, dbHandle, 30 );
			cache_get_field_content( i, "PASSWORD", password, dbHandle, 5 );
			cache_get_field_content( i, "OWNER", owner, dbHandle, 24 );

			// create home handle
			new house_sql_id = cache_get_field_content_int( i, "ID", dbHandle );
			new handle = CreateHouse( house_name,
				cache_get_field_content_int( i, "COST", dbHandle ),
				cache_get_field_content_float( i, "EX", dbHandle ),
				cache_get_field_content_float( i, "EY", dbHandle ),
				cache_get_field_content_float( i, "EZ", dbHandle ),
				cache_get_field_content_float( i, "TX", dbHandle ),
				cache_get_field_content_float( i, "TY", dbHandle ),
				cache_get_field_content_float( i, "TZ", dbHandle ),
				cache_get_field_content_int( i, "INTERIOR", dbHandle ),
				password, owner, house_sql_id
			);

			if ( handle != ITER_NONE ) {
				// store weapon information
				cache_get_field_content( i, "WEAPONS", weapon_info ), sscanf( weapon_info, "p<.>e<ddddddd>", g_HouseWeapons[ handle ] );
				cache_get_field_content( i, "AMMO", weapon_info ), sscanf( weapon_info, "p<.>e<ddddddd>", g_HouseWeaponAmmo[ handle ] );
			}
		}
	}
	printf( "[HOUSES]: %d houses have been loaded. (Tick: %dms)", rows, GetTickCount( ) - loadingTick );

	// Make server operator the owner of unowned VIP houses
	foreach ( new houseid : houses ) if ( g_houseData[ houseid ] [ E_COST ] < 10000 ) {
		if ( strmatch( g_houseData[ houseid ] [ E_OWNER ], "No-one" ) ) {
			SetHouseOwner( houseid, SERVER_OPERATOR_ACC_ID, SERVER_OPERATOR );
		}
	}
	return 1;
}

/* ** Functions ** */
stock CreateHouse( house_name[ 30 ], cost, Float: eX, Float: eY, Float: eZ, Float: tX = H_DEFAULT_X, Float: tY = H_DEFAULT_Y, Float: tZ = H_DEFAULT_Z, interior = 2, password[ 5 ] = "N/A", owner[ 24 ] = "无人", sql_id = ITER_NONE )
{
	new
		hID = ( 0 <= sql_id < MAX_HOUSES ) ? sql_id : Iter_Free( houses );

	if ( Iter_Contains( houses, sql_id ) )
		hID = ITER_NONE;

	if ( hID != ITER_NONE )
	{
		Iter_Add( houses, hID );

		// set house name, password, owner
		format( g_houseData[ hID ] [ E_HOUSE_NAME ], 30, "%s", house_name );
		format( g_houseData[ hID ] [ E_PASSWORD ], 5, "%s", password );
		format( g_houseData[ hID ] [ E_OWNER ], 24, "%s", owner );

		// set home variables
		g_houseData[ hID ] [ E_COST ] = cost;
		g_houseData[ hID ] [ E_EX ] = eX;
		g_houseData[ hID ] [ E_EY ] = eY;
		g_houseData[ hID ] [ E_EZ ] = eZ;
		g_houseData[ hID ] [ E_TX ] = tX;
		g_houseData[ hID ] [ E_TY ] = tY;
		g_houseData[ hID ] [ E_TZ ] = tZ;
		g_houseData[ hID ] [ E_INTERIOR_ID ] = interior;
		g_houseData[ hID ] [ E_WORLD ] = ( hID + MAX_HOUSES );

		// reset weapons (in case)
		for( new i; i < MAX_HOUSE_WEAPONS; i++ ) {
		    g_HouseWeapons[ hID ] [ i ] = 0, g_HouseWeaponAmmo[ hID ] [ i ] = -1;
		}

		// prefurnish home
		if ( sql_id == ITER_NONE ) FillHomeWithFurniture( hID, 0 );

		// set global
		g_houseData[ hID ] [ E_MAP_ICON ] = strmatch( owner, "No-one" ) ? CreateDynamicMapIcon( eX, eY, eZ, 31, 0, -1, -1, -1, HOUSE_MAPICON_RADIUS ) : -1;

		g_houseData[ hID ] [ E_CHECKPOINT ] [ 0 ] = CreateDynamicCP( eX, eY, eZ, 1.0, -1, 0, -1, 100.0 );
		g_houseData[ hID ] [ E_CHECKPOINT ] [ 1 ] = CreateDynamicCP( tX, tY, tZ, 1.0, g_houseData[ hID ] [ E_WORLD ], g_houseData[ hID ] [ E_INTERIOR_ID ], -1, 100.0 );

		format( szBigString, sizeof( szBigString ), ""COL_GOLD"房子:"COL_WHITE" %s(%d)\n"COL_GOLD"所有者:"COL_WHITE" %s\n"COL_GOLD"价格:"COL_WHITE" %s", g_houseData[ hID ] [ E_HOUSE_NAME ], hID, g_houseData[ hID ] [ E_OWNER ], cash_format( cost ) );

	    g_houseData[ hID ] [ E_LABEL ] [ 0 ] = CreateDynamic3DTextLabel( szBigString, COLOR_WHITE, eX, eY, eZ, 20.0 );
		g_houseData[ hID ] [ E_LABEL ] [ 1 ] = CreateDynamic3DTextLabel( "[出口]", COLOR_GOLD, tX, tY, tZ, 20.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, g_houseData[ hID ] [ E_WORLD ] );

		// insert if non existant prior
		if ( sql_id == ITER_NONE ) {
			format( szBigString, sizeof( szBigString ), "INSERT INTO `HOUSES` VALUES (%d,'Home','No-one',%d,%f,%f,%f,%f,%f,%f,%d,'N/A','0.0.0.0.0.0.0.','-1.-1.-1.-1.-1.-1.-1.')", hID, cost, eX, eY, eZ, tX, tY, tZ, interior );
			mysql_single_query( szBigString );
		}
	}
	return hID;
}

stock DestroyHouse( houseid )
{
	if ( ! Iter_Contains( houses, houseid ) )
	    return 0;

	new
	    query[ 40 ],
		playerid = GetPlayerIDFromName( g_houseData[ houseid ] [ E_OWNER ] )
	;

	if ( IsPlayerConnected( playerid ) )
	{
	    SendClientMessage( playerid, -1, ""COL_PINK"[房屋]"COL_WHITE" 你的一栋房子被毁了.");
		p_OwnedHouses[ playerid ] --;
	}

	format( query, sizeof( query ), "DELETE FROM HOUSES WHERE ID=%d", houseid );
	mysql_single_query( query );
    destroyAllFurniture( houseid );
	g_houseData[ houseid ] [ E_HOUSE_NAME ] [ 0 ] = '\0';
	g_houseData[ houseid ] [ E_OWNER ] [ 0 ] = '\0';
	DestroyDynamicMapIcon( g_houseData[ houseid ] [ E_MAP_ICON ] );
	DestroyDynamicCP( g_houseData[ houseid ] [ E_CHECKPOINT ] [ 0 ] );
	DestroyDynamicCP( g_houseData[ houseid ] [ E_CHECKPOINT ] [ 1 ] );
	DestroyDynamic3DTextLabel( g_houseData[ houseid ] [ E_LABEL ] [ 0 ] );
	DestroyDynamic3DTextLabel( g_houseData[ houseid ] [ E_LABEL ] [ 1 ] );
	Iter_Remove( houses, houseid );
	return 1;
}

stock SetHouseForAuction( ID )
{
	if ( ID == -1 )
		return 0;

	if ( ! Iter_Contains( houses, ID ) )
	    return 0;

	new
	    query[ 128 ],
		player = GetPlayerIDFromName( g_houseData[ ID ] [ E_OWNER ] )
	;

	if ( IsPlayerConnected( player ) )
	{
	    SendClientMessage( player, -1, ""COL_PINK"[房屋]"COL_WHITE" 你的一栋房子已被拍卖.");
		p_OwnedHouses[ player ] --;
	}
	CallLocalFunction( "OnHouseOwnerChange", "dd", ID, 0 );
	for( new i; i < MAX_HOUSE_WEAPONS; i++ ) { g_HouseWeapons[ ID ] [ i ] = 0, g_HouseWeaponAmmo[ ID ] [ i ] = -1; }
	SaveHouseWeaponStorage( ID );
	format( g_houseData[ ID ] [ E_PASSWORD ], 4, "N/A" );
	format( g_houseData[ ID ] [ E_OWNER ], 7, "无人" );
	format( g_houseData[ ID ] [ E_HOUSE_NAME ], 5, "家" );
	g_houseData[ ID ] [ E_TX ] = g_houseInteriors[ 0 ] [ E_EX ];
	g_houseData[ ID ] [ E_TY ] = g_houseInteriors[ 0 ] [ E_EY ];
	g_houseData[ ID ] [ E_TZ ] = g_houseInteriors[ 0 ] [ E_EZ ];
	g_houseData[ ID ] [ E_INTERIOR_ID ] = 2;
	destroyAllFurniture( ID );
	FillHomeWithFurniture( ID, 0 );
	format( query, sizeof( query ), "UPDATE HOUSES SET OWNER='No-one',PASSWORD='N/A',NAME='Home',TX=%f,TY=%f,TZ=%f,INTERIOR=%d WHERE ID=%d", g_houseData[ ID ] [ E_TX ], g_houseData[ ID ] [ E_TY ], g_houseData[ ID ] [ E_TZ ], g_houseData[ ID ] [ E_INTERIOR_ID ], ID );
    mysql_single_query( query );
	format( szBigString, sizeof( szBigString ), ""COL_GOLD"房子:"COL_WHITE" 首页(%d)\n"COL_GOLD"所有者:"COL_WHITE" 无人\n"COL_GOLD"价格:"COL_WHITE" %s", ID, cash_format( g_houseData[ ID ] [ E_COST ] ) );
	UpdateDynamic3DTextLabelText( g_houseData[ ID ] [ E_LABEL ] [ 0 ], COLOR_WHITE, szBigString);
	DestroyDynamic3DTextLabel( g_houseData[ ID ] [ E_LABEL ] [ 1 ] );
	g_houseData[ ID ] [ E_LABEL ] [ 1 ] = CreateDynamic3DTextLabel( "[出口]", COLOR_GOLD, g_houseData[ ID ] [ E_TX ], g_houseData[ ID ] [ E_TY ], g_houseData[ ID ] [ E_TZ ], 20.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, g_houseData[ ID ] [ E_WORLD ] );
	DestroyDynamicCP( g_houseData[ ID ] [ E_CHECKPOINT ] [ 1 ] );
	g_houseData[ ID ] [ E_CHECKPOINT ] [ 1 ] = CreateDynamicCP( g_houseData[ ID ] [ E_TX ], g_houseData[ ID ] [ E_TY ], g_houseData[ ID ] [ E_TZ ], 1.0, g_houseData[ ID ] [ E_WORLD ], g_houseData[ ID ] [ E_INTERIOR_ID ], -1, 50.0 );
	DestroyDynamicMapIcon( g_houseData[ ID ] [ E_MAP_ICON ] );
	g_houseData[ ID ] [ E_MAP_ICON ] = CreateDynamicMapIcon( g_houseData[ ID ] [ E_EX ], g_houseData[ ID ] [ E_EY ], g_houseData[ ID ] [ E_EZ ], 31, 0, -1, -1, -1, HOUSE_MAPICON_RADIUS );
	return 1;
}

stock SetHouseOwner( houseid, owner, owner_name[ 24 ] )
{
	if ( ! Iter_Contains( houses, houseid ) || ! strlen( owner_name ) )
		return 0;

	// copy home owner name to variable
	strcpy( g_houseData[ houseid ] [ E_OWNER ], owner_name );

	// update in database
	mysql_format( dbHandle, szNormalString, sizeof( szNormalString ), "UPDATE HOUSES SET OWNER='%e' WHERE ID=%d", g_houseData[ houseid ] [ E_OWNER ], houseid );
	mysql_single_query( szNormalString );

	// callback when the home owner changes
	CallLocalFunction( "OnHouseOwnerChange", "dd", houseid, owner );

	// refresh label
	DestroyDynamicMapIcon( g_houseData[ houseid ] [ E_MAP_ICON ] );
	format( szBigString, sizeof( szBigString ), ""COL_GOLD"房子:"COL_WHITE" 首页(%d)\n"COL_GOLD"所有者:"COL_WHITE" %s\n"COL_GOLD"价格:"COL_WHITE" %s", houseid, g_houseData[ houseid ] [ E_OWNER ], cash_format( g_houseData[ houseid ] [ E_COST ] ) );
 	UpdateDynamic3DTextLabelText( g_houseData[ houseid ] [ E_LABEL ] [ 0 ], COLOR_WHITE, szBigString );
	return 1;
}

/*stock SwitchHouseOwners( ID, playerid, buyerid )
{
	if ( IsPlayerConnected( playerid ) )
	{
		p_OwnedHouses[ playerid ] --;
		SetPlayerInterior( playerid, 0 );
		SetPlayerVirtualWorld( playerid, 0 );
		SendServerMessage( playerid, "You have successfully sold your house for "COL_GOLD"%s", cash_format( ( g_houseData[ ID ] [ E_COST ] / 2 ) ) );
		SetPlayerPos( playerid, g_houseData[ ID ] [ E_EX ], g_houseData[ ID ] [ E_EY ], g_houseData[ ID ] [ E_EZ ] );
	}

	strcpy( g_houseData[ ID ] [ E_PASSWORD ], "N/A" );
	strcpy( g_houseData[ ID ] [ E_HOUSE_NAME ], "Home" );
	format( g_houseData[ ID ] [ E_OWNER ], 7, "%s", ReturnPlayerName( buyerid ) );

	format( szBigString, sizeof( szBigString ), "UPDATE HOUSES SET OWNER='%s',PASSWORD='N/A',NAME='Home' WHERE ID=%d", mysql_escape( ReturnPlayerName( buyerid ) ) , ID );
    mysql_single_query( szBigString );

	format( szBigString, sizeof( szBigString ), ""COL_GOLD"House:"COL_WHITE" Home(%d)\n"COL_GOLD"Owner:"COL_WHITE" No-one\n"COL_GOLD"Price:"COL_WHITE" %s", ID, cash_format( g_houseData[ ID ] [ E_COST ] ) );
	UpdateDynamic3DTextLabelText( g_houseData[ ID ] [ E_LABEL ] [ 0 ], COLOR_WHITE, szBigString );

	DestroyDynamic3DTextLabel( g_houseData[ ID ] [ E_LABEL ] [ 1 ] );
	g_houseData[ ID ] [ E_LABEL ] [ 1 ] = CreateDynamic3DTextLabel( "[EXIT]", COLOR_GOLD, g_houseData[ ID ] [ E_TX ], g_houseData[ ID ] [ E_TY ], g_houseData[ ID ] [ E_TZ ], 20.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, g_houseData[ ID ] [ E_WORLD ] );

	DestroyDynamicCP( g_houseData[ ID ] [ E_CHECKPOINT ] [ 1 ] );
	g_houseData[ ID ] [ E_CHECKPOINT ] [ 1 ] = CreateDynamicCP( g_houseData[ ID ] [ E_TX ], g_houseData[ ID ] [ E_TY ], g_houseData[ ID ] [ E_TZ ], 1.0, g_houseData[ ID ] [ E_WORLD ], g_houseData[ ID ] [ E_INTERIOR_ID ], -1, 50.0 );

	DestroyDynamicMapIcon( g_houseData[ ID ] [ E_MAP_ICON ] );
}*/

stock GetPlayerOwnedHouses( playerid )
{
	new
		count = 0;

	foreach ( new i : houses ) if ( IsPlayerHomeOwner( playerid, i ) ) {
		count ++;
	}
	return count;
}

stock ShowHouseWeaponStorage( playerid )
{
	if ( !IsPlayerConnected( playerid ) )
	    return 0;

    new id = p_InHouse[ playerid ];
	if ( id == -1 ) return SendError( playerid, "你不在任何房子里." );
	if ( !strmatch( g_houseData[ id ] [ E_OWNER ], ReturnPlayerName( playerid ) ) ) return SendError( playerid, "你不是这所房子的主人." );
    szLargeString[ 0 ] = '\0';
    for( new i = 0; i < MAX_HOUSE_WEAPONS; i++ )
    {
		if ( g_HouseWeapons[ id ] [ i ] != 0 )
			format( szLargeString, sizeof( szLargeString ), "%s%s%s(%d)\n", szLargeString, i > 2 ? (""#COL_GOLD"") : ("{FFFFFF}"), ReturnWeaponName( g_HouseWeapons[ id ] [ i ] ), g_HouseWeaponAmmo[ id ] [ i ] );
		else
			strcat( szLargeString, i > 2 ? ( ""COL_GOLD"空\n" ) : ( ""COL_WHITE"空\n" ) );

	}
	ShowPlayerDialog( playerid, DIALOG_HOUSE_WEAPONS, DIALOG_STYLE_LIST, "{FFFFFF}房屋武器储藏室", szLargeString, "取款", "返回" );
	return 1;
}

stock SaveHouseWeaponStorage( houseid )
{
	new szWeapon[ 21 ], szAmmo[ 50 ];
    for( new i; i < MAX_HOUSE_WEAPONS; i++ )
    {
        format( szWeapon, sizeof( szWeapon ), "%s%d.", szWeapon, g_HouseWeapons[ houseid ] [ i ] );
        format( szAmmo, sizeof( szAmmo ), "%s%d.", szAmmo, g_HouseWeaponAmmo[ houseid ] [ i ] );
	}
	format( szBigString, sizeof( szBigString ), "UPDATE `HOUSES` SET `WEAPONS`='%s',`AMMO`='%s' WHERE `ID`=%d", szWeapon, szAmmo, houseid );
	mysql_single_query( szBigString );
	return 1;
}

stock ArePlayersInHouse( houseid, owner )
{
	foreach ( new i : Player ) if ( i != owner )
	{
		if ( p_InHouse[ i ] == houseid )
		{
			if ( GetPlayerVirtualWorld( i ) == g_houseData[ houseid ] [ E_WORLD ] )
				return true;

			p_InHouse[ i ] = -1; // They're bugged probably
		}
	}
	return false;
}

stock GetHousePos( houseid, &Float: X, &Float: Y, &Float: Z ) {
	X = g_houseData[ houseid ] [ E_EX ];
	Y = g_houseData[ houseid ] [ E_EY ];
	Z = g_houseData[ houseid ] [ E_EZ ];
}
