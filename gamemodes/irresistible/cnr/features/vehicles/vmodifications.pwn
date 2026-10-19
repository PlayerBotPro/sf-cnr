/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc, Cloudy
 * Module: cnr\features\vehicles\vehicle_modifications.pwn
 * Purpose: custom vehicle components (objects) for player vehicles
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */

/* ** Variables ** */
#define MAX_PIMPS 					( 10 )
#define MAX_COMPONENT_NAME			( 32 )

#define CATEGORY_SPOILERS 			( 0 )
#define CATEGORY_HOOD 				( 1 )
#define CATEGORY_BAGS				( 2 )
#define CATEGORY_LAMPS				( 3 )
#define CATEGORY_WHEELS				( 4 )
#define CATEGORY_BULLBAR			( 5 )
#define CATEGORY_FRONT_BUMPER		( 6 )
#define CATEGORY_REAR_BUMPER		( 7 )
#define CATEGORY_VENTS				( 8 )
#define CATEGORY_NEON				( 9 )
#define CATEGORY_MECHANIC_ITEMS 	( 10 )
#define CATEGORY_MILITARY_ITEMS 	( 11 )
#define CATEGORY_MISCELLANEOUS		( 12 )

#define PREVIEW_MODEL_COMPONENT 	( 10 ) // some random number

#define COMPONENT_EDIT_TYPE_X		0
#define COMPONENT_EDIT_TYPE_Y		1
#define COMPONENT_EDIT_TYPE_Z		2
#define COMPONENT_EDIT_TYPE_RX		3
#define COMPONENT_EDIT_TYPE_RY		4
#define COMPONENT_EDIT_TYPE_RZ		5

#define TIMER_UPDATE_RATE			50
#define MAX_COMPONENT_OFFSET 		3.0

enum E_CAR_MODS
{
	E_CATEGORY,						E_LIMIT,						E_MODEL_ID,
	E_NAME[ MAX_COMPONENT_NAME ], 	E_PRICE
};

enum E_PIMP_DATA
{
	bool: E_CREATED[ MAX_PIMPS ],	E_OBJECT[ MAX_PIMPS ],			E_MODEL[ MAX_PIMPS ],
	Float: E_X[ MAX_PIMPS ],		Float: E_Y[ MAX_PIMPS ],		Float: E_Z[ MAX_PIMPS ],
	Float: E_RX[ MAX_PIMPS ],		Float: E_RY[ MAX_PIMPS ],		Float: E_RZ[ MAX_PIMPS ],
	E_SQL_ID[ MAX_PIMPS ],			bool: E_DISABLED[ MAX_PIMPS ]
};

new
	g_vehicleComponentsCategories[ ] [ MAX_COMPONENT_NAME ] = {
		"扰流板", "引擎盖", "挂包", "车灯", "轮毂", "防撞杠", "前保险杠", "后保险杠", "通风口", "霓虹灯", "维修工具", "军用物品", "杂项"
	},
	g_vehicleComponentsData[ ] [ E_CAR_MODS ] =
	{
		// Spoilers
		{ CATEGORY_SPOILERS, 0, 1023, "Fury", 8000 },
		{ CATEGORY_SPOILERS, 0, 1001, "Win", 9000 },
		{ CATEGORY_SPOILERS, 0, 1000, "Pro", 10000 },
		{ CATEGORY_SPOILERS, 0, 1016, "Worx", 10000 },
		{ CATEGORY_SPOILERS, 0, 1058, "Alien - Stratum", 10000 },
		{ CATEGORY_SPOILERS, 0, 1014, "Champ", 11000 },
		{ CATEGORY_SPOILERS, 0, 1003, "Alpha", 12000 },
		{ CATEGORY_SPOILERS, 0, 1002, "直线竞速型", 13000 },
		{ CATEGORY_SPOILERS, 0, 1015, "赛道型", 14000 },
		{ CATEGORY_SPOILERS, 0, 1060, "X-Flow - Stratum", 14000 },
		{ CATEGORY_SPOILERS, 0, 1049, "Alien - Flash", 14000 },
		{ CATEGORY_SPOILERS, 0, 1162, "Alien - Jester", 18000 },
		{ CATEGORY_SPOILERS, 0, 1164, "Alien - Uranus", 19000 },
		{ CATEGORY_SPOILERS, 0, 1147, "Alien - Elegy", 22000 },
		{ CATEGORY_SPOILERS, 0, 1050, "X-Flow - Flash", 23000 },
		{ CATEGORY_SPOILERS, 0, 1138, "Alien - Sultan", 25000 },
		{ CATEGORY_SPOILERS, 0, 1158, "X-Flow - Jester", 27000 },
		{ CATEGORY_SPOILERS, 0, 1163, "X-Flow - Uranus", 28000 },
		{ CATEGORY_SPOILERS, 0, 1146, "X-Flow - Elegy", 30000 },
		{ CATEGORY_SPOILERS, 0, 1139, "X-Flow - Sultan", 35000 },

		// Hood
		{ CATEGORY_HOOD, 0, 1011, "Race 进气罩", 13000 },
		{ CATEGORY_HOOD, 0, 1004, "Champ 进气罩", 15000 },
		{ CATEGORY_HOOD, 0, 1005, "Fury 进气罩", 16000 },
		{ CATEGORY_HOOD, 0, 1012, "Worx 进气罩", 23000 },

		// Bags
		{ CATEGORY_BAGS, 0, 11745, "挂包", 15000 },
		{ CATEGORY_BAGS, 0, 1279, "帐篷包", 17000 },
		{ CATEGORY_BAGS, 0, 1550, "钱袋", 35000 },
		{ CATEGORY_BAGS, 0, 1210, "钱箱", 25000 },
		{ CATEGORY_BAGS, 0, 1575, "灰色毒品袋", 15000 },
		{ CATEGORY_BAGS, 0, 1576, "橙色毒品袋", 15000 },
		{ CATEGORY_BAGS, 0, 1577, "黄色毒品袋", 15000 },
		{ CATEGORY_BAGS, 0, 1578, "绿色毒品袋", 15000 },
		{ CATEGORY_BAGS, 0, 1579, "蓝色毒品袋", 15000 },
		{ CATEGORY_BAGS, 0, 1580, "红色毒品袋", 15000 },

		// Lamps
		{ CATEGORY_LAMPS, 0, 1013, "圆形雾灯", 15000 },
		{ CATEGORY_LAMPS, 0, 1024, "方形雾灯", 25000 },

		// Wheels
		{ CATEGORY_WHEELS, 0, 1025, "越野", 25000 },
		{ CATEGORY_WHEELS, 0, 1080, "Switch", 25000 },
		{ CATEGORY_WHEELS, 0, 1077, "Classic", 30000 },
		{ CATEGORY_WHEELS, 0, 1073, "Shadow", 35000 },
		{ CATEGORY_WHEELS, 0, 1079, "Cutter", 35000 },
		{ CATEGORY_WHEELS, 0, 1085, "Atomic", 35000 },
		{ CATEGORY_WHEELS, 0, 1096, "Ahab", 35000 },
		{ CATEGORY_WHEELS, 0, 1078, "Twist", 40000 },
		{ CATEGORY_WHEELS, 0, 1081, "Grove", 40000 },
		{ CATEGORY_WHEELS, 0, 1084, "Trance", 45000 },
		{ CATEGORY_WHEELS, 0, 1075, "Rimshine", 45000 },
		{ CATEGORY_WHEELS, 0, 1074, "Mega", 45000 },
		{ CATEGORY_WHEELS, 0, 1076, "Wires", 50000 },
		{ CATEGORY_WHEELS, 0, 1098, "Access", 55000 },
		{ CATEGORY_WHEELS, 0, 1097, "Virtual", 65000 },
		{ CATEGORY_WHEELS, 0, 1082, "Import", 75000},
		{ CATEGORY_WHEELS, 0, 1327, "大轮", 80000 },
		{ CATEGORY_WHEELS, 0, 1083, "Dollar", 100000 },

		// Bullbar
		{ CATEGORY_BULLBAR, 0, 1123, "防撞镀铬条", 30000 },
		{ CATEGORY_BULLBAR, 0, 1100, "镀铬格栅", 35000 },
		{ CATEGORY_BULLBAR, 0, 1125, "防撞镀铬灯", 37000 },

		// Front Bumper
		{ CATEGORY_FRONT_BUMPER, 0, 1155, "Alien - Stratum", 15000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1160, "Alien - Jester", 20000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1166, "Alien - Uranus", 20000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1153, "Alien - Flash", 25000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1157, "X-Flow - Stratum", 25000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1171, "Alien - Elegy", 25000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1181, "Slamin - Blade", 25000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1185, "Slamin - Remington", 25000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1190, "Slamin - Tornado", 25000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1165, "X-Flow - Uranus", 30000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1169, "Alien - Sultan", 30000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1173, "X-Flow - Jester", 30000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1152, "X-Flow - Flash", 35000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1172, "X-Flow - Elegy", 35000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1170, "X-Flow - Sultan", 40000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1174, "镀铬 - Broadway 1", 45000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1176, "镀铬 - Broadway 2", 45000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1117, "镀铬 - Slamvan", 50000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1182, "镀铬 - Blade", 50000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1188, "Slamin - Savanna", 50000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1189, "镀铬 - Savanna",50000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1191, "镀铬 - Tornado", 50000 },
		{ CATEGORY_FRONT_BUMPER, 0, 1179, "镀铬 - Remington", 55000 },

		// Rear Bumper
		{ CATEGORY_REAR_BUMPER, 0, 1154, "Alien - Stratum", 15000 },
		{ CATEGORY_REAR_BUMPER, 0, 1159, "Alien - Jester", 15000 },
		{ CATEGORY_REAR_BUMPER, 0, 1168, "Alien - Uranus", 15000 },
		{ CATEGORY_REAR_BUMPER, 0, 1175, "Slamin - Broadway", 15000 },
		{ CATEGORY_REAR_BUMPER, 0, 1150, "Alien - Flash", 18000 },
		{ CATEGORY_REAR_BUMPER, 0, 1149, "Alien - Elegy", 19000 },
		{ CATEGORY_REAR_BUMPER, 0, 1140, "X-Flow - Sultan", 20000 },
		{ CATEGORY_REAR_BUMPER, 0, 1178, "Slamin - Remington", 23000 },
		{ CATEGORY_REAR_BUMPER, 0, 1156, "X-Flow Straum", 25000 },
		{ CATEGORY_REAR_BUMPER, 0, 1161, "X-Flow - Jester", 25000 },
		{ CATEGORY_REAR_BUMPER, 0, 1183, "Slamin - Blade", 25000 },
		{ CATEGORY_REAR_BUMPER, 0, 1186, "Slamin - Savanna", 25000 },
		{ CATEGORY_REAR_BUMPER, 0, 1167, "X-Flow - Uranus", 25000 },
		{ CATEGORY_REAR_BUMPER, 0, 1193, "Slamin - Tornado", 25000 },
		{ CATEGORY_REAR_BUMPER, 0, 1151, "X-Flow - Flash", 28000 },
		{ CATEGORY_REAR_BUMPER, 0, 1148, "X-Flow - Elegy", 29000 },
		{ CATEGORY_REAR_BUMPER, 0, 1141, "Alien - Sultan", 30000 },
		{ CATEGORY_REAR_BUMPER, 0, 1177, "Slamin - Broadway", 35000 },
		{ CATEGORY_REAR_BUMPER, 0, 1180, "镀铬 - Remington", 50000 },
		{ CATEGORY_REAR_BUMPER, 0, 1184, "镀铬 - Blade", 50000 },
		{ CATEGORY_REAR_BUMPER, 0, 1187, "镀铬 - Savanna", 50000 },
		{ CATEGORY_REAR_BUMPER, 0, 1192, "镀铬 - Tornado", 50000 },

		// Vents
		{ CATEGORY_VENTS, 0, 1142, "左椭圆形通风口", 4000 },
		{ CATEGORY_VENTS, 0, 1143, "右椭圆形通风口", 4000 },
		{ CATEGORY_VENTS, 0, 1144, "左方形通风口", 6000 },
		{ CATEGORY_VENTS, 0, 1145, "右方形通风口", 6000 },
		{ CATEGORY_VENTS, 3, 914, "大通风口", 250000 },

		// Neon
		{ CATEGORY_NEON, 0, 18647, "红色霓虹灯", 200000 },
		{ CATEGORY_NEON, 0, 18648, "蓝色霓虹灯", 200000 },
		{ CATEGORY_NEON, 0, 18649, "绿色霓虹灯", 200000 },
		{ CATEGORY_NEON, 0, 18650, "黄色霓虹灯", 200000 },
		{ CATEGORY_NEON, 0, 18651, "粉红霓虹灯", 200000 },
		{ CATEGORY_NEON, 0, 18652, "白色霓虹灯", 200000 },

		// Military Items
		{ CATEGORY_MILITARY_ITEMS, 0, 1654, "炸药", 8000 },
		{ CATEGORY_MILITARY_ITEMS, 0, 19590, "剑", 14000 },
		{ CATEGORY_MILITARY_ITEMS, 0, 19832, "弹药箱", 20000 },
		{ CATEGORY_MILITARY_ITEMS, 0, 2040, "弹药箱关闭", 20000 },
		{ CATEGORY_MILITARY_ITEMS, 0, 2041, "弹药箱打开", 20000 },
		{ CATEGORY_MILITARY_ITEMS, 1, 964, "军用板条箱", 40000 },
		{ CATEGORY_MILITARY_ITEMS, 0, 11738, "医疗包", 135000 },

		// Mechanic Items
		{ CATEGORY_MECHANIC_ITEMS, 0, 18644, "螺丝刀", 1500 },
		{ CATEGORY_MECHANIC_ITEMS, 0, 18633, "扳手", 2500 },
		{ CATEGORY_MECHANIC_ITEMS, 0, 18635, "锤", 2500 },
		{ CATEGORY_MECHANIC_ITEMS, 0, 1650, "煤气罐", 5000 },
		{ CATEGORY_MECHANIC_ITEMS, 0, 19621, "油罐", 7500 },
		{ CATEGORY_MECHANIC_ITEMS, 0, 19816, "氧气罐", 20000 },
		{ CATEGORY_MECHANIC_ITEMS, 0, 19921, "工具箱", 23000 },
		{ CATEGORY_MECHANIC_ITEMS, 1, 19917, "引擎", 65000 },
		{ CATEGORY_MECHANIC_ITEMS, 1, 920, "发电机", 80000 },
		{ CATEGORY_MECHANIC_ITEMS, 0, 19631, "大锤", 90000 },

		// Miscellaneous
		{ CATEGORY_MISCELLANEOUS, 0, 19309, "出租车白色", 2000 },
		{ CATEGORY_MISCELLANEOUS, 0, 19310, "出租车黑色", 4000 },
		{ CATEGORY_MISCELLANEOUS, 0, 18632, "钓竿", 8000 },
		{ CATEGORY_MISCELLANEOUS, 0, 19624, "手提箱", 15000 },
		{ CATEGORY_MISCELLANEOUS, 0, 19314, "扩音器", 15000 },
		{ CATEGORY_MISCELLANEOUS, 0, 18646, "警灯", 25000 },
		{ CATEGORY_MISCELLANEOUS, 0, 19280, "泛光灯", 30000 },
		{ CATEGORY_MISCELLANEOUS, 0, 19419, "警灯带", 45000 },
		{ CATEGORY_MISCELLANEOUS, 0, 19320, "南瓜", 45000 },
		{ CATEGORY_MISCELLANEOUS, 0, 19306, "红旗", 50000 },
		{ CATEGORY_MISCELLANEOUS, 0, 19307, "蓝旗", 50000 },
		{ CATEGORY_MISCELLANEOUS, 0, 19086, "电锯假阳具", 69696},
		{ CATEGORY_MISCELLANEOUS, 0, 11704, "恶魔面具", 75000 },
		{ CATEGORY_MISCELLANEOUS, 2, 2985, "机枪", 80000 },
		{ CATEGORY_MISCELLANEOUS, 0, 19315, "鹿", 133769 },
		{ CATEGORY_MISCELLANEOUS, 0, 1609, "龟", 250000 }
		//{ CATEGORY_MISCELLANEOUS, 1, 19601, "Snow Plough", 1500000 }
	},

	g_vehiclePimpData[ MAX_PLAYERS ] [ MAX_BUYABLE_VEHICLES ] [ E_PIMP_DATA ]
;

/* ** Forwards ** */
forward OnUpdateVehicleComponents( playerid );

/* ** Hooks ** */
hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( ( dialogid == DIALOG_COMPONENTS_CATEGORY ) && response ) {
		SetPVarInt( playerid, "components_category", listitem );
		return ShowPlayerVehicleComponents( playerid, listitem );
	}
	else if ( dialogid == DIALOG_COMPONENTS )
	{
		SetPVarInt( playerid, "components_item", listitem );
		if ( response )
		{
			ShowPlayerDialog(playerid, DIALOG_COMPONENTS_RESPONSE, DIALOG_STYLE_LIST, ""COL_WHITE"拉皮条我的旅程", "购买组件\n预览组件", "选择", "返回" );
		}
		else
		{
			return cmd_garage( playerid, "vehicle pimp" );
		}
	}

	else if ( dialogid == DIALOG_COMPONENTS_RESPONSE )
	{
		new
			iItem = GetPVarInt( playerid, "components_item" ),
			iComponent = GetPVarInt( playerid, "components_category" );

		if ( response )
		{
			switch( listitem )
			{
				case 0:
				{
					for( new i = 0, x = 0; i < sizeof( g_vehicleComponentsData ); i++ ) if ( g_vehicleComponentsData[ i ] [ E_CATEGORY ] == iComponent )
					{
						if ( iItem == x++ )
						{
						    if ( !IsPlayerInAnyVehicle( playerid ) )
                                return SendError( playerid, "你需要在车辆中才能使用此命令." );

							if ( GetPlayerCash( playerid ) < g_vehicleComponentsData[ i ] [ E_PRICE ] )
								return SendError( playerid, "你需要 %s 才能购买此车辆组件.", cash_format( g_vehicleComponentsData[ i ] [ E_PRICE ] ) );

						    if ( GetPlayerState( playerid ) != PLAYER_STATE_DRIVER )
                                return SendError( playerid, "你需要成为驾驶员才能使用此命令." );

					        new
					        	ownerid = INVALID_PLAYER_ID,
					        	vehicleid = getVehicleSlotFromID( GetPlayerVehicleID( playerid ), ownerid )
							;

							if ( vehicleid == -1 )
								return SendError( playerid, "这辆车不是可购买的车辆." );

							if ( playerid != ownerid )
								return SendError( playerid, "这辆车不属于你." );

							if ( GetVehicleCustomComponents( ownerid, vehicleid ) >= GetPlayerPimpVehicleSlots( ownerid ) )
								return SendError( playerid, "你不能购买超过 %d 个车辆部件.", GetPlayerPimpVehicleSlots( ownerid ) );

							new
								slotid = GetVehicleComponentSlot( ownerid, vehicleid );

							if ( slotid == -1 )
								return SendError( playerid, "你向车辆添加的组件不得超过 %d 个.", MAX_PIMPS );

							// make sure the person is above the limit
							if ( g_vehicleComponentsData[ i ] [ E_LIMIT ] != 0 )
							{
								new
									instances = 0;

								for( new p = 0; p < MAX_PIMPS; p++ )
									if ( g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_CREATED ] [ p ] && g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_MODEL ] [ p ] == g_vehicleComponentsData[ i ] [ E_MODEL_ID ] )
										instances ++;

								if ( instances >= g_vehicleComponentsData[ i ] [ E_LIMIT ] )
									return SendError( playerid, "你最多可以放置 %s %d 次.", g_vehicleComponentsData[ i ] [ E_NAME ], g_vehicleComponentsData[ i ] [ E_LIMIT ] );
							}

							new
								Float: X, Float: Y, Float: Z;

							GivePlayerCash( playerid, -g_vehicleComponentsData[ i ] [ E_PRICE ] );
							StockMarket_UpdateEarnings( E_STOCK_VEHICLE_DEALERSHIP, g_vehicleComponentsData[ i ] [ E_PRICE ], 0.025 );

							g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_CREATED ] [ slotid ] = true;
							g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_DISABLED ] [ slotid ] = false;
							g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_MODEL ] [ slotid ] = g_vehicleComponentsData[ i ] [ E_MODEL_ID ];
							g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_X ] [ slotid ] = 0.0;
							g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_Y ] [ slotid ] = 0.0;
							g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_Z ] [ slotid ] = 1.0;
							g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_RX ] [ slotid ] = 0.0;
							g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_RY ] [ slotid ] = 0.0;
							g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_RZ ] [ slotid ] = 0.0;

							format( szNormalString, sizeof( szNormalString ), "INSERT INTO `COMPONENTS` (`VEHICLE_ID`,`MODEL`,`X`,`Y`,`Z`,`RX`,`RY`,`RZ`) VALUES (%d,%d,0.0,0.0,1.0,0.0,0.0,0.0)", g_vehicleData[ ownerid ] [ vehicleid ] [ E_SQL_ID ], g_vehicleComponentsData[ i ] [ E_MODEL_ID ] );
							mysql_function_query( dbHandle, szNormalString, true, "OnPlayerCreateVehicleComponent", "ddd", playerid, vehicleid, slotid );

							GetVehiclePos( g_vehicleData[ ownerid ] [ vehicleid ] [ E_VEHICLE_ID ], X, Y, Z );
							SetVehiclePos( g_vehicleData[ ownerid ] [ vehicleid ] [ E_VEHICLE_ID ], X, Y, Z + 0.05 );

							g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_OBJECT ] [ slotid ] = CreateDynamicObject( g_vehicleComponentsData[ i ] [ E_MODEL_ID ], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, .worldid = GetVehicleVirtualWorld( g_vehicleData[ ownerid ] [ vehicleid ] [ E_VEHICLE_ID ]) );
							AttachDynamicObjectToVehicle( g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_OBJECT ] [ slotid ], g_vehicleData[ ownerid ] [ vehicleid ] [ E_VEHICLE_ID ], 0.0, 0.0, 1.0, 0.0, 0.0, 0.0 );
							return SendServerMessage( playerid, "你已购买了 "COL_GREY"%s"COL_WHITE", 获得"COL_GOLD"%s"COL_WHITE".", g_vehicleComponentsData[ i ] [ E_NAME ], cash_format( g_vehicleComponentsData[ i ] [ E_PRICE ] ) );
						}
					}
				}
				case 1:
				{
					for( new i = 0, x = 0; i < sizeof( g_vehicleComponentsData ); i++ ) if ( g_vehicleComponentsData[ i ] [ E_CATEGORY ] == iComponent )
					{
						if ( iItem == x++ )
						{
							return ShowPlayerModelPreview( playerid, PREVIEW_MODEL_COMPONENT, "组件预览", g_vehicleComponentsData[ i ] [ E_MODEL_ID ], .bgcolor = 0xFFFFFF70 );
						}
					}

				}
			}
		}
		else
		{
			return cmd_garage( playerid, "vehicle pimp" );
		}
	}
	else if ( ( dialogid == DIALOG_COMPONENT_MENU ) && response )
	{
		new
	    	ownerid = INVALID_PLAYER_ID,
	    	vehicleid = getVehicleSlotFromID( GetPlayerVehicleID( playerid ), ownerid )
		;

		if ( vehicleid == -1 )
			return SendError( playerid, "这辆车不是可购买的车辆." );

		if ( playerid != ownerid )
			return SendError( playerid, "这辆车不属于你." );

		for( new i = 0, x = 0; i < MAX_PIMPS; i++ ) if ( g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_CREATED ] [ i ] ) {
			if ( listitem == x++ ) {
				return ShowPlayerVehicleComponentMenu( playerid, ownerid, vehicleid, i );
			}
		}
	}
	else if ( ( dialogid == DIALOG_COMPONENT_EDIT ) && response )
	{
		new
	    	ownerid = INVALID_PLAYER_ID,
	    	i = GetPVarInt( playerid, "components_editing" ),
	    	vehicleid = getVehicleSlotFromID( GetPlayerVehicleID( playerid ), ownerid )
		;

		if ( vehicleid == -1 )
			return SendError( playerid, "这辆车不是可购买的车辆." );

		if ( playerid != ownerid )
			return SendError( playerid, "这辆车不属于你." );

		switch( listitem )
		{
			case 0: // Disable
			{
				if ( ( g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_DISABLED ] [ i ] = !g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_DISABLED ] [ i ] ) == false )
				{
					new
						Float: X, Float: Y, Float: Z;

					// Recreate object
					g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_OBJECT ] [ i ] = CreateDynamicObject( g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_MODEL ] [ i ], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, .worldid = GetVehicleVirtualWorld( g_vehicleData[ ownerid ] [ vehicleid ] [ E_VEHICLE_ID ] ) );

					// Attach object to vehicle
					AttachDynamicObjectToVehicle( g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_OBJECT ] [ i ], g_vehicleData[ ownerid ] [ vehicleid ] [ E_VEHICLE_ID ],
										g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_X ] [ i ], g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_Y ] [ i ], g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_Z ] [ i ],
										g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_RX ] [ i ], g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_RY ] [ i ], g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_RZ ] [ i ] );

					// Reposition vehicle
					GetVehiclePos( g_vehicleData[ ownerid ] [ vehicleid ] [ E_VEHICLE_ID ], X, Y, Z );
					SetVehiclePos( g_vehicleData[ ownerid ] [ vehicleid ] [ E_VEHICLE_ID ], X, Y, Z + 0.05 );

					SendServerMessage( playerid, "你已成功启用你的车辆组件" );
				}
				else
				{
					DestroyDynamicObject( g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_OBJECT ] [ i ] );
					g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_OBJECT ] [ i ] = -1;
					SendServerMessage( playerid, "你已成功禁用你的车辆组件" );
				}

				mysql_single_query( sprintf( "UPDATE `COMPONENTS` SET `DISABLED`=%d WHERE `ID`=%d", g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_DISABLED ] [ i ], g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_SQL_ID ] [ i ] ) );
				return ShowPlayerVehicleComponentMenu( playerid, ownerid, vehicleid, i );
			}
			case 1: // Edit
			{
				if ( g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_DISABLED ] [ i ] )
				{
					SendError( playerid, "该组件已禁用,请先启用它." );
					return ShowPlayerVehicleComponentMenu( playerid, ownerid, vehicleid, i );
				}

				SetPVarFloat( playerid, "component_pos_x", g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_X ] [ i ] );
				SetPVarFloat( playerid, "component_pos_y", g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_Y ] [ i ] );
				SetPVarFloat( playerid, "component_pos_z", g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_Z ] [ i ] );
				SetPVarFloat( playerid, "component_rot_x", g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_RX ] [ i ] );
				SetPVarFloat( playerid, "component_rot_y", g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_RY ] [ i ] );
				SetPVarFloat( playerid, "component_rot_z", g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_RZ ] [ i ] );

				ShowPlayerHelpDialog(
					playerid, 0,
					"~g~A 或 D -~w~ 移动对象~n~"\
					"~g~/px - ~w~X 轴~n~\
					~g~/py - ~w~Y 轴~n~\
					~g~/pz - ~w~Z 轴~n~\
					~g~/rx - ~w~X 旋转~n~\
					~g~/ry - ~w~Y 旋转~n~\
					~g~/rz - ~w~Z 旋转~n~\
					~g~按 Y - ~w~保存~n~\
					~g~按 N - ~w~取消~n~\
					~g~按住空格 - ~w~更快编辑"
				);

				SendClientMessage( playerid, -1, ""COL_GREY"[车库]"COL_WHITE" 你已开始编辑组件." );
				SetTimerEx( "OnUpdateVehicleComponents", TIMER_UPDATE_RATE, false, "d", playerid );
			}
			case 2: // sell
			{
				new
					pimpid;

				for( ; pimpid < sizeof( g_vehicleComponentsData ); pimpid++ )
					if ( g_vehicleComponentsData[ pimpid ] [ E_MODEL_ID ] == g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_MODEL ] [ i ] )
						break;

				new
					sellPrice = floatround( g_vehicleComponentsData[ pimpid ] [ E_PRICE ] * 0.5 );

				ShowPlayerDialog( playerid, DIALOG_COMPONENTS_SELL, DIALOG_STYLE_MSGBOX, ""COL_WHITE"销售组件", sprintf( ""COL_WHITE"你确定要卖掉你的 "COL_GREY"%s "COL_WHITE"为了 "COL_GOLD"%s?\n", g_vehicleComponentsData[ pimpid ] [ E_NAME ], cash_format( sellPrice ) ), "出售", "返回" );
			}
		}
	}
	else if ( dialogid == DIALOG_COMPONENTS_SELL )
	{
		new
	    	ownerid = INVALID_PLAYER_ID,
	    	i = GetPVarInt( playerid, "components_editing" ),
	    	vehicleid = getVehicleSlotFromID( GetPlayerVehicleID( playerid ), ownerid )
		;

		if ( vehicleid == -1 )
			return SendError( playerid, "这辆车不是可购买的车辆." );

		if ( playerid != ownerid )
			return SendError( playerid, "这辆车不属于你." );

		if ( ! response)
		{
			for( new y = 0, x = 0; y < MAX_PIMPS; y++ ) if ( g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_CREATED ] [ y ] ) {
				if ( listitem == x++ ) {
					return ShowPlayerVehicleComponentMenu( playerid, ownerid, vehicleid, i );
				}
			}
		}
		else
		{
			new
				pimpid;

			for( ; pimpid < sizeof( g_vehicleComponentsData ); pimpid++ )
				if ( g_vehicleComponentsData[ pimpid ] [ E_MODEL_ID ] == g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_MODEL ] [ i ] )
					break;

			if ( g_vehicleComponentsData[ pimpid ] [ E_MODEL_ID ] != g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_MODEL ] [ i ] )
				return SendError( playerid, "你无法出售该组件,因为它不再存在." );

			new
				sellPrice = floatround( g_vehicleComponentsData[ pimpid ] [ E_PRICE ] * 0.5 );

			GivePlayerCash( playerid, sellPrice );
			DestroyDynamicObject( g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_OBJECT ] [ i ] );

			g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_OBJECT ] [ i ] = -1;
			g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_CREATED ] [ i ] = false;

			mysql_single_query( sprintf( "DELETE FROM `COMPONENTS` WHERE `ID`=%d", g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_SQL_ID ] [ i ] ) );
			SendServerMessage( playerid, "你已经卖掉了你的 "COL_GREY"%s"COL_WHITE", 获得"COL_GOLD"%s"COL_WHITE".", g_vehicleComponentsData[ pimpid ] [ E_NAME ], cash_format( sellPrice ) );
		}
		return 1;
	}
	return 1;
}

/* ** SQL Threads ** */
hook OnVehicleComponentsLoad( playerid, vid )
{
	if ( !IsPlayerConnected( playerid ) )
		return 0;

	if ( !g_vehicleData[ playerid ] [ vid ] [ E_CREATED ] )
		return 0;

	new
		rows, fields, i = -1, cid
	;

	cache_get_data( rows, fields );

	if ( rows )
	{
		while( ++i < rows )
		{
			for( cid = 0; cid < MAX_PIMPS; cid++ )
				if ( !g_vehiclePimpData[ playerid ] [ vid ] [ E_CREATED ] [ cid ] ) break;

			if ( cid >= MAX_PIMPS )
				continue;

			if ( g_vehiclePimpData[ playerid ] [ vid ] [ E_CREATED ] [ cid ] )
			    continue;

			g_vehiclePimpData[ playerid ] [ vid ] [ E_CREATED ] [ cid ] = true;
			g_vehiclePimpData[ playerid ] [ vid ] [ E_SQL_ID ] [ cid ] = cache_get_field_content_int( i, "ID", dbHandle );
			g_vehiclePimpData[ playerid ] [ vid ] [ E_MODEL ] [ cid ] = cache_get_field_content_int( i, "MODEL", dbHandle );
			g_vehiclePimpData[ playerid ] [ vid ] [ E_X ] [ cid ] = cache_get_field_content_float( i, "X", dbHandle );
			g_vehiclePimpData[ playerid ] [ vid ] [ E_Y ] [ cid ] = cache_get_field_content_float( i, "Y", dbHandle );
			g_vehiclePimpData[ playerid ] [ vid ] [ E_Z ] [ cid ] = cache_get_field_content_float( i, "Z", dbHandle );
			g_vehiclePimpData[ playerid ] [ vid ] [ E_RX ] [ cid ] = cache_get_field_content_float( i, "RX", dbHandle );
			g_vehiclePimpData[ playerid ] [ vid ] [ E_RY ] [ cid ] = cache_get_field_content_float( i, "RY", dbHandle );
			g_vehiclePimpData[ playerid ] [ vid ] [ E_RZ ] [ cid ] = cache_get_field_content_float( i, "RZ", dbHandle );
			g_vehiclePimpData[ playerid ] [ vid ] [ E_DISABLED ] [ cid ] = !!cache_get_field_content_int( i, "DISABLED", dbHandle );

			DestroyDynamicObject( g_vehiclePimpData[ playerid ] [ vid ] [ E_OBJECT ] [ cid ] );
			g_vehiclePimpData[ playerid ] [ vid ] [ E_OBJECT ] [ cid ] = -1;

			if ( g_vehiclePimpData[ playerid ] [ vid ] [ E_DISABLED ] [ cid ] == false )
			{
				g_vehiclePimpData[ playerid ] [ vid ] [ E_OBJECT ] [ cid ] = CreateDynamicObject( g_vehiclePimpData[ playerid ] [ vid ] [ E_MODEL ] [ cid ], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, .worldid = GetVehicleVirtualWorld( g_vehicleData[ playerid ] [ vid ] [ E_VEHICLE_ID ] ) );
				AttachDynamicObjectToVehicle( g_vehiclePimpData[ playerid ] [ vid ] [ E_OBJECT ] [ cid ], g_vehicleData[ playerid ] [ vid ] [ E_VEHICLE_ID ],
											g_vehiclePimpData[ playerid ] [ vid ] [ E_X ] [ cid ], g_vehiclePimpData[ playerid ] [ vid ] [ E_Y ] [ cid ], g_vehiclePimpData[ playerid ] [ vid ] [ E_Z ] [ cid ],
											g_vehiclePimpData[ playerid ] [ vid ] [ E_RX ] [ cid ], g_vehiclePimpData[ playerid ] [ vid ] [ E_RY ] [ cid ], g_vehiclePimpData[ playerid ] [ vid ] [ E_RZ ] [ cid ] );
			}
		}
	}
	return 1;
}

thread OnPlayerCreateVehicleComponent( playerid, vehicleid, slotid )
{
	g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_SQL_ID ] [ slotid ] = cache_insert_id( );
	return 1;
}

/* ** Callbacks ** */
public OnUpdateVehicleComponents( playerid )
{
	// just incase, to avoid bugs
	if ( ! IsPlayerEditingVehicle( playerid ) || ! IsPlayerInGarage( playerid ) )
		return EndPlayerEditComponent( playerid );

	new
		ownerid = INVALID_PLAYER_ID,
		vehicleid = GetPlayerVehicleID( playerid ),
		slotid = GetPVarInt( playerid, "components_editing" ),
		v = getVehicleSlotFromID( vehicleid, ownerid )
	;
	if ( v == -1 || playerid != ownerid || ! g_vehiclePimpData[ ownerid ] [ v ] [ E_CREATED ] [ slotid ] || g_vehiclePimpData[ ownerid ] [ v ] [ E_DISABLED ] [ slotid ] )
		return SendServerMessage( playerid, "车辆组件编辑已取消." ), EndPlayerEditComponent( playerid );

	new
		LR, KEYS, Float: VALUE = -1.0;

	GetPlayerKeys( playerid, KEYS, tmpVariable, LR );

	if ( KEYS & KEY_YES )
	{
		SendClientMessageFormatted( playerid, -1, ""COL_GREY"[车库]"COL_WHITE" 你已保存正在编辑的组件." );
		return EndPlayerEditComponent( ownerid, v, slotid, true );
	}
	else if ( KEYS & KEY_NO )
	{
		SendClientMessage( playerid, -1, ""COL_GREY"[车库]"COL_WHITE" 你已取消编辑该组件." );
		return EndPlayerEditComponent( ownerid, v, slotid );
	}

	if ( LR > 0 )
		VALUE = 0.01;

	else if ( LR < 0 )
		VALUE = -0.01;

	if ( VALUE != -1.0 )
	{
		// hold space to edit components faster
		if ( KEYS & KEY_HANDBRAKE )
			VALUE *= 3;

		new Float: tmpPosX = GetPVarFloat( playerid, "component_pos_x" );
		new Float: tmpPosY = GetPVarFloat( playerid, "component_pos_y" );
		new Float: tmpPosZ = GetPVarFloat( playerid, "component_pos_z" );
		new Float: tmpRotX = GetPVarFloat( playerid, "component_rot_x" );
		new Float: tmpRotY = GetPVarFloat( playerid, "component_rot_y" );
		new Float: tmpRotZ = GetPVarFloat( playerid, "component_rot_z" );

		switch( GetPVarInt( playerid, "component_edit_type" ) )
		{
			case COMPONENT_EDIT_TYPE_X:
				SetPVarFloat( playerid, "component_pos_x", ( tmpPosX += VALUE ) );

			case COMPONENT_EDIT_TYPE_Y:
				SetPVarFloat( playerid, "component_pos_y", ( tmpPosY += VALUE ) );

			case COMPONENT_EDIT_TYPE_Z:
				SetPVarFloat( playerid, "component_pos_z", ( tmpPosZ += VALUE ) );

			case COMPONENT_EDIT_TYPE_RX:
				SetPVarFloat( playerid, "component_rot_x", ( tmpRotX += ( ( VALUE * 360 ) / 100 ) * 10 ) );

			case COMPONENT_EDIT_TYPE_RY:
				SetPVarFloat( playerid, "component_rot_y", ( tmpRotY += ( ( VALUE * 360 ) / 100 ) * 10 ) );

			case COMPONENT_EDIT_TYPE_RZ:
				SetPVarFloat( playerid, "component_rot_z", ( tmpRotZ += ( ( VALUE * 360 ) / 100 ) * 10 ) );

			default:
				return EndPlayerEditComponent( playerid, v, slotid );
		}

		// add movement limit of MAX_COMPONENT_OFFSET units
		if ( tmpPosX > MAX_COMPONENT_OFFSET ) tmpPosX = MAX_COMPONENT_OFFSET;
		else if ( tmpPosX < -MAX_COMPONENT_OFFSET ) tmpPosX = -MAX_COMPONENT_OFFSET;

		if ( tmpPosY > MAX_COMPONENT_OFFSET ) tmpPosY = MAX_COMPONENT_OFFSET;
		else if ( tmpPosY < -MAX_COMPONENT_OFFSET ) tmpPosY = -MAX_COMPONENT_OFFSET;

		if ( tmpPosZ > MAX_COMPONENT_OFFSET ) tmpPosZ = MAX_COMPONENT_OFFSET;
		else if ( tmpPosZ < -MAX_COMPONENT_OFFSET ) tmpPosZ = -MAX_COMPONENT_OFFSET;

		// attach object to vehicle
		AttachDynamicObjectToVehicle(
			g_vehiclePimpData[ ownerid ] [ v ] [ E_OBJECT ] [ slotid ], g_vehicleData[ ownerid ] [ v ] [ E_VEHICLE_ID ],
			tmpPosX, tmpPosY, tmpPosZ,
			tmpRotX, tmpRotY, tmpRotZ
		);
	}
	return SetTimerEx( "OnUpdateVehicleComponents", TIMER_UPDATE_RATE, false, "d", playerid );
}

/* ** Functions ** */
stock EndPlayerEditComponent( playerid, vehicleid = -1, slotid = -1, bool: save = false )
{
	if ( save )
	{
		g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_RX ] [ slotid ] = GetPVarFloat( playerid, "component_rot_x" );
		g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_RY ] [ slotid ] = GetPVarFloat( playerid, "component_rot_y" );
		g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_RZ ] [ slotid ] = GetPVarFloat( playerid, "component_rot_z" );

		g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_X ] [ slotid ] = GetPVarFloat( playerid, "component_pos_x" );
		g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_Y ] [ slotid ] = GetPVarFloat( playerid, "component_pos_y" );
		g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_Z ] [ slotid ] = GetPVarFloat( playerid, "component_pos_z" );

		format(
			szNormalString, sizeof( szNormalString ),
			"UPDATE `COMPONENTS` SET `X`=%f,`Y`=%f,`Z`=%f,`RX`=%f,`RY`=%f,`RZ`=%f WHERE `ID`=%d",
			g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_X ] [ slotid ], g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_Y ] [ slotid ], g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_Z ] [ slotid ],
			g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_RX ] [ slotid ], g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_RY ] [ slotid ], g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_RZ ] [ slotid ],
			g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_SQL_ID ] [ slotid ]
		);
		mysql_single_query( szNormalString );
	}

	DeletePVar( playerid, "components_editing" );
	DeletePVar( playerid, "component_edit_type" );
	DeletePVar( playerid, "component_pos_x" );
	DeletePVar( playerid, "component_pos_y" );
	DeletePVar( playerid, "component_pos_z" );
	DeletePVar( playerid, "component_rot_x" );
	DeletePVar( playerid, "component_rot_y" );
	DeletePVar( playerid, "component_rot_z" );

	if ( vehicleid != -1 && slotid != -1 )
	{
		AttachDynamicObjectToVehicle(
			g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_OBJECT ] [ slotid ],
			g_vehicleData[ playerid ] [ vehicleid ] [ E_VEHICLE_ID ],
			g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_X ] [ slotid ],
			g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_Y ] [ slotid ],
			g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_Z ] [ slotid ],
			g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_RX ] [ slotid ],
			g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_RY ] [ slotid ],
			g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_RZ ] [ slotid ]
		);
	}

	HidePlayerHelpDialog( playerid );
	return 1;
}

stock GetVehicleComponentSlot( playerid, vehicleid ) {

	for( new id = 0; id < MAX_PIMPS; id++ ) {
		if ( g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_CREATED ] [ id ] == false ) {
			return id;
		}
	}
	return -1;
}

stock ShowPlayerVehicleComponents( playerid, categoryid ) {

	erase( szLargeString );

	for( new i = 0; i < sizeof( g_vehicleComponentsData ); i++ ) if ( g_vehicleComponentsData[ i ] [ E_CATEGORY ] == categoryid ) {
		format( szLargeString, sizeof( szLargeString ), "%s%s\t"COL_GOLD"%s\n", szLargeString, g_vehicleComponentsData[ i ] [ E_NAME ], cash_format( g_vehicleComponentsData[ i ] [ E_PRICE ] ) );
	}
	return ShowPlayerDialog( playerid, DIALOG_COMPONENTS, DIALOG_STYLE_TABLIST, sprintf( "给我的座驾拉皮条 - %s", g_vehicleComponentsCategories[ categoryid ] ), szLargeString, "购买", "返回" );
}

stock DestroyVehicleCustomComponents( playerid, vehicleid, bool: destroy_db = false )
{
	for( new slotid = 0; slotid < MAX_PIMPS; slotid++ ) {
		g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_CREATED ] [ slotid ] = false;
		DestroyDynamicObject( g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_OBJECT ] [ slotid ] );
		g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_OBJECT ] [ slotid ] = -1;
	}

	if ( destroy_db ) {
		mysql_single_query( sprintf( "DELETE FROM `COMPONENTS` WHERE `VEHICLE_ID`=%d", g_vehicleData[ playerid ] [ vehicleid ] [ E_SQL_ID ] ) );
	}
}

stock ReplaceVehicleCustomComponents( ownerid, v, bool: recreate_obj = false ) {

	for( new slotid; slotid < MAX_PIMPS; slotid++ ) if ( g_vehiclePimpData[ ownerid ] [ v ] [ E_CREATED ] [ slotid ] && !g_vehiclePimpData[ ownerid ] [ v ] [ E_DISABLED ] ) {
		// Recreate object
		if ( recreate_obj ) {
			DestroyDynamicObject( g_vehiclePimpData[ ownerid ] [ v ] [ E_OBJECT ] [ slotid ] );
			g_vehiclePimpData[ ownerid ] [ v ] [ E_OBJECT ] [ slotid ] = CreateDynamicObject( g_vehiclePimpData[ ownerid ] [ v ] [ E_MODEL ] [ slotid ], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 );
		}

		// Attach object to vehicle
		AttachDynamicObjectToVehicle( g_vehiclePimpData[ ownerid ] [ v ] [ E_OBJECT ] [ slotid ], g_vehicleData[ ownerid ] [ v ] [ E_VEHICLE_ID ],
							g_vehiclePimpData[ ownerid ] [ v ] [ E_X ] [ slotid ], g_vehiclePimpData[ ownerid ] [ v ] [ E_Y ] [ slotid ], g_vehiclePimpData[ ownerid ] [ v ] [ E_Z ] [ slotid ],
							g_vehiclePimpData[ ownerid ] [ v ] [ E_RX ] [ slotid ], g_vehiclePimpData[ ownerid ] [ v ] [ E_RY ] [ slotid ], g_vehiclePimpData[ ownerid ] [ v ] [ E_RZ ] [ slotid ] );

		// Update virtual world - There was an error appearing here, so make sure object is valid.
		if ( IsValidDynamicObject( g_vehiclePimpData[ ownerid ] [ v ] [ E_OBJECT ] [ slotid ] ) )
			Streamer_SetIntData( STREAMER_TYPE_OBJECT, g_vehiclePimpData[ ownerid ] [ v ] [ E_OBJECT ] [ slotid ], E_STREAMER_WORLD_ID, GetVehicleVirtualWorld( g_vehicleData[ ownerid ] [ v ] [ E_VEHICLE_ID ] ) );
	}
}

stock GetVehicleCustomComponents( playerid, vehicleid ) {
	new
		count = 0;

	for( new i = 0; i < MAX_PIMPS; i++ )
		if ( g_vehiclePimpData[ playerid ] [ vehicleid ] [ E_CREATED ] [ i ] )
			count ++;

	return count;
}

stock ShowPlayerVehicleComponentMenu( playerid, ownerid, vehicleid, i )
{
	new
		pimpid;

	for( ; pimpid < sizeof( g_vehicleComponentsData ); pimpid++ )
		if ( g_vehicleComponentsData[ pimpid ] [ E_MODEL_ID ] == g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_MODEL ] [ i ] )
			break;

	if ( !( 0 <= pimpid < sizeof( g_vehicleComponentsData ) ) || g_vehicleComponentsData[ pimpid ] [ E_MODEL_ID ] != g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_MODEL ] [ i ] )
		return SendError( playerid, "你无法出售该组件,因为它不再存在." );

	new
		sellPrice = floatround( g_vehicleComponentsData[ pimpid ] [ E_PRICE ] * 0.5 );

	SetPVarInt( playerid, "components_editing", i );
	return ShowPlayerDialog( playerid, DIALOG_COMPONENT_EDIT, DIALOG_STYLE_TABLIST, "车辆零部件", sprintf( "%s 组件\t\n编辑组件\t\n销售组件\t"COL_GOLD"%s", g_vehiclePimpData[ ownerid ] [ vehicleid ] [ E_DISABLED ] [ i ] ? ( "使能够" ) : ( "禁用" ), cash_format( sellPrice ) ), "选择", "取消" );
}

stock ShowVehicleComponentCategories( playerid )
{
	static
		szCategory[ sizeof( g_vehicleComponentsCategories ) * 12 ];

	if ( szCategory[ 0 ] == '\0') {
		for( new i = 0; i < sizeof( g_vehicleComponentsCategories ); i++ ) {
			format( szCategory, sizeof( szCategory ), "%s%s\n", szCategory, g_vehicleComponentsCategories[ i ] );
		}
	}
	return ShowPlayerDialog( playerid, DIALOG_COMPONENTS_CATEGORY, DIALOG_STYLE_LIST, "皮条客我的旅程 - 类别", szCategory, "选择", "取消" );
}

hook OnPlayerEndModelPreview( playerid, handleid )
{
	if ( handleid == PREVIEW_MODEL_COMPONENT )
	{
		SendServerMessage( playerid, "你已看完此车辆改装预览." );
		ShowPlayerDialog(playerid, DIALOG_COMPONENTS_RESPONSE, DIALOG_STYLE_LIST, ""COL_WHITE"拉皮条我的旅程", "购买组件\n预览组件", "选择", "返回" );
		return Y_HOOKS_BREAK_RETURN_1;
	}
	return 1;
}

/* ** Commands ** */
CMD:px( playerid, params[ ] )
{
	if ( ! IsPlayerEditingVehicle( playerid ) ) return SendError( playerid, "你没有编辑车辆." );

	SetPVarInt( playerid, "component_edit_type", COMPONENT_EDIT_TYPE_X );
	return SendClientMessageFormatted( playerid, -1, ""COL_GREY"[车库]"COL_WHITE" 你现在正在编辑组件的 X 轴." );
}

CMD:py( playerid, params[ ] )
{
	if ( ! IsPlayerEditingVehicle( playerid ) ) return SendError( playerid, "你没有编辑车辆." );

	SetPVarInt( playerid, "component_edit_type", COMPONENT_EDIT_TYPE_Y );
	return SendClientMessageFormatted( playerid, -1, ""COL_GREY"[车库]"COL_WHITE" 你现在正在编辑组件的 Y 轴." );
}

CMD:pz( playerid, params[ ] )
{
	if ( ! IsPlayerEditingVehicle( playerid ) ) return SendError( playerid, "你没有编辑车辆." );

	SetPVarInt( playerid, "component_edit_type", COMPONENT_EDIT_TYPE_Z );
	return SendClientMessageFormatted( playerid, -1, ""COL_GREY"[车库]"COL_WHITE" 你现在正在编辑组件的 Z 轴." );
}

CMD:rx( playerid, params[ ] )
{
	if ( ! IsPlayerEditingVehicle( playerid ) ) return SendError( playerid, "你没有编辑车辆." );

	SetPVarInt( playerid, "component_edit_type", COMPONENT_EDIT_TYPE_RX );
	return SendClientMessageFormatted( playerid, -1, ""COL_GREY"[车库]"COL_WHITE" 你现在正在编辑组件的 X 旋转." );
}

CMD:ry( playerid, params[ ] )
{
	if ( ! IsPlayerEditingVehicle( playerid ) ) return SendError( playerid, "你没有编辑车辆." );

	SetPVarInt( playerid, "component_edit_type", COMPONENT_EDIT_TYPE_RY );
	return SendClientMessageFormatted( playerid, -1, ""COL_GREY"[车库]"COL_WHITE" 你现在正在编辑组件的 Y 旋转." );
}

CMD:rz( playerid, params[ ] )
{
	if ( ! IsPlayerEditingVehicle( playerid ) ) return SendError( playerid, "你没有编辑车辆." );

	SetPVarInt( playerid, "component_edit_type", COMPONENT_EDIT_TYPE_RZ );
	return SendClientMessageFormatted( playerid, -1, ""COL_GREY"[车库]"COL_WHITE" 你现在正在编辑组件的 Z 旋转." );
}

stock IsPlayerEditingVehicle( playerid ) {
	return GetPVarType( playerid, "components_editing" ) != 0;
}