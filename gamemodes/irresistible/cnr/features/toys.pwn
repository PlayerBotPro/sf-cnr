/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\toys.pwn
 * Purpose: toy system for players (attach objects to player)
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_TOYS                ( sizeof( g_ToyData ) )
#define MAX_TOY_UNLOCKS 		( 200 ) // should be ideally MAX_TOYS

#define CATEGORY_WATCHES 		( 0 )
#define CATEGORY_BERETS 		( 1 )
#define CATEGORY_HATS 			( 2 )
#define CATEGORY_HEADPHONES 	( 3 )
#define CATEGORY_MASKS 			( 4 )
#define CATEGORY_MOTORCYCLE 	( 5 )
#define CATEGORY_GUITARS		( 6 )
#define CATEGORY_GLASSES 		( 7 )
#define CATEGORY_HANDHELD 		( 8 )
#define CATEGORY_WEAPONS 		( 9 )
#define CATEGORY_MISC 			( 10 )
#define CATEGORY_VIP 			( 11 )

#define MODEL_PREVIEW_TOY 		( 15 )

/* ** Variables ** */
enum E_ATTACHED_DATA
{
	E_ENABLED, 			E_MODELID, 		E_BONE,
	Float: E_OX,		Float: E_OY, 	Float: E_OZ,
	Float: E_RX, 		Float: E_RY, 	Float: E_RZ,
	Float: E_SX, 		Float: E_SY, 	Float: E_SZ,
	E_COLOR, 			E_SQL_ID
};

enum E_TOY_DATA
{
	E_CATEGORY, 		E_ID,			E_NAME[ 24 ],
	E_MODEL, 			E_PRICE,		E_DEFAULT_BONE
};

new
	g_ToyCategory[ ] [ ] =
	{
		{ "手表" },  { "贝雷帽" }, { "帽子" }, { "耳机" }, { "面具" },
		{ "摩托车头盔" }, { "吉他" }, { "眼镜" }, { "手持式" },
		{ "武器" }, { "杂项" }, { "V.I.P" }
	},
 	g_ToyData[ ] [ E_TOY_DATA ] =
	{
		// WATCHES
		{ CATEGORY_WATCHES, 0, 	"劳力士日志型 II", 		19039, 220000,	5 },
		{ CATEGORY_WATCHES, 1, 	"劳力士日志型 I", 		19042, 160000,	5 },
		{ CATEGORY_WATCHES, 2, 	"劳力士探险家号", 			19040, 140800,	5 },
		{ CATEGORY_WATCHES, 3, 	"劳力士 Sky-Dweller", 	 	19041, 95000,	5 },
		{ CATEGORY_WATCHES, 4, 	"G-Shock 迷彩", 	 		19053, 25000,	5 },
		{ CATEGORY_WATCHES, 5, 	"G-Shock 海军迷彩", 	 	19048, 20000,	5 },
		{ CATEGORY_WATCHES, 6, 	"G-Shock 粉色迷彩", 	 	19049, 17500,	5 },
		{ CATEGORY_WATCHES, 7, 	"G-Shock 橙色迷彩", 		19051, 17500,	5 },
		{ CATEGORY_WATCHES, 8, 	"G-Shock 紫色", 	 		19047, 10000,	5 },
		{ CATEGORY_WATCHES, 9, 	"G-Shock 粉色", 	 		19045, 10000,	5 },
		{ CATEGORY_WATCHES, 10, "G-Shock 绿色", 			19046, 5000,	5 },

		// BERET
		{ CATEGORY_BERETS, 11, 	"迷彩贝雷帽", 				18924, 750,		2 },
		// { CATEGORY_BERETS, 12,	"Gucci Black", 				18921, 340,		2 },
		// { CATEGORY_BERETS, 13,	"Gucci Red", 				18922, 340,		2 },
		// { CATEGORY_BERETS, 14,	"Gucci Blue", 				18923, 340,		2 },

		// HATS
		{ CATEGORY_HATS, 126,	"女巫帽",				19528, 6666,	2 }, // special
		{ CATEGORY_HATS, 93,	"圣诞老人帽",				19064, 5000,	2 }, // special
		{ CATEGORY_HATS, 15,	"黑帮无檐便帽", 			19067, 1300, 	2 },
		{ CATEGORY_HATS, 16,	"蛇皮帽子", 			18973, 1000, 	2 },
		{ CATEGORY_HATS, 17,	"老虎印花帽子", 			18970, 1000, 	2 },
		{ CATEGORY_HATS, 18,	"骷髅帽", 			19069, 1000, 	2 },
		{ CATEGORY_HATS, 19,	"拳击头盔", 			18952, 900, 	2 },
		// { CATEGORY_HATS, 20,	"Knit Cap Grey", 			18954, 800, 	2 },
		// { CATEGORY_HATS, 21,	"Knit Cap Black", 			18953, 800, 	2 },
		{ CATEGORY_HATS, 22,	"公爵帽", 				18972, 800, 	2 },
		{ CATEGORY_HATS, 23,	"牛仔帽", 				18962, 800, 	2 },
		{ CATEGORY_HATS, 24,	"卡车司机帽", 				18961, 700, 	2 },
		//{ CATEGORY_HATS, 25,	"Black Bowler", 			18944, 500, 	2 },
		{ CATEGORY_HATS, 26,	"白色软呢帽", 			19488, 500, 	2 },
		//{ CATEGORY_HATS, 27,	"Blue Bowler", 				18945, 500, 	2 },
		{ CATEGORY_HATS, 28,	"岛屿软呢帽", 				18946, 500, 	2 },
		{ CATEGORY_HATS, 29,	"血腥软呢帽", 				18950, 500, 	2 },
		// { CATEGORY_HATS, 30,	"Yellow Bowler", 			18951, 500, 	2 },
		{ CATEGORY_HATS, 31,	"溜冰者渔夫帽", 		18968, 500, 	2 },
		//{ CATEGORY_HATS, 32,	"Fishing Cap", 				18969, 500, 	2 },
		{ CATEGORY_HATS, 33,	"黑色高顶礼帽", 			19352, 500, 	2 },
		{ CATEGORY_HATS, 34,	"白色高顶礼帽", 			19487, 500, 	2 },
		{ CATEGORY_HATS, 35,	"消防头盔", 			19330, 400, 	2 },
		{ CATEGORY_HATS, 36,	"警长帽", 				19099, 300, 	2 },
		{ CATEGORY_HATS, 37,	"迷彩帽", 				18926, 240, 	2 },
		{ CATEGORY_HATS, 38,	"鸡帽",				19137, 240,		2 },
		{ CATEGORY_HATS, 39,	"汉堡帽", 			19094, 240, 	2 },
		{ CATEGORY_HATS, 40,	"警察帽", 				18636, 240, 	2 },
		{ CATEGORY_HATS, 41,	"防毒面具",					19472, 240,		2 },

		// HEADPHONES
		{ CATEGORY_HEADPHONES, 41,	"白色节拍", 			19421, 550, 	2 },
		{ CATEGORY_HEADPHONES, 42,	"黑色节拍", 			19422, 550, 	2 },
		{ CATEGORY_HEADPHONES, 43,	"红色节拍", 			19423, 550, 	2 },
		{ CATEGORY_HEADPHONES, 44,	"蓝色节拍", 			19424, 550, 	2 },

		// MASKS
		{ CATEGORY_MASKS, 96, 	"古驰巴拉克拉法帽",			19801, 	10000,	2 },
		{ CATEGORY_MASKS, 45,	"黑面具",				18912, 	6000,	2 },
		{ CATEGORY_MASKS, 46,	"绿色面膜",				18913, 	5200,	2 },
		{ CATEGORY_MASKS, 47,	"大麻 头巾",				18894, 	4500,	2 },
		{ CATEGORY_MASKS, 48,	"瘸子面具",				19163, 	300,	2 },
		{ CATEGORY_MASKS, 49,	"曲棍球面具白色",		19036, 	250,	2 },
		{ CATEGORY_MASKS, 50,	"曲棍球面具红色",			19037, 	250,	2 },
		{ CATEGORY_MASKS, 51,	"蓝色头巾",				18897, 	100,	2 },
		{ CATEGORY_MASKS, 53,	"格罗夫面具",				18913, 	200,	2 },
		{ CATEGORY_MASKS, 54,	"佐罗面具",				18974, 	100,	2 },

		// MOTORCYCLE HELMETS
		{ CATEGORY_MOTORCYCLE, 87, "火焰头盔",		18645, 	1000,	2 },
		{ CATEGORY_MOTORCYCLE, 88, "蓝盔",			18976, 	800,	2 },
		{ CATEGORY_MOTORCYCLE, 89, "红头盔",			18977, 	700,	2 },
		{ CATEGORY_MOTORCYCLE, 90, "白头盔",			18978, 	700,	2 },
		{ CATEGORY_MOTORCYCLE, 91, "粉红头盔",			18979, 	500,	2 },

		// GUITARS
		{ CATEGORY_GUITARS, 55,	"术士吉他",			19319, 	1250,	1 },
		{ CATEGORY_GUITARS, 56,	"飞行吉他",			19318, 	800,	1 },
		{ CATEGORY_GUITARS, 57,	"低音吉他",				19317, 	400,	1 },

		// GLASSES
		{ CATEGORY_GLASSES, 58,	"奥克利·法拉利", 			19006, 900, 	2 },
		{ CATEGORY_GLASSES, 59,	"阿玛尼飞行员经典", 	19022, 840, 	2 },
		// { CATEGORY_GLASSES, 61,	"Armani Aviator Blue" , 	19023, 840, 	2 },
		// { CATEGORY_GLASSES, 62,	"Armani Aviator Purple", 	19024, 840, 	2 },
		{ CATEGORY_GLASSES, 63,	"阿玛尼飞行员粉色", 		19025, 840, 	2 },
		// { CATEGORY_GLASSES, 64,	"Armani Aviator Orange", 	19027, 840, 	2 },
		// { CATEGORY_GLASSES, 65,	"Armani Aviator Yellow", 	19028, 840, 	2 },
		// { CATEGORY_GLASSES, 65,	"Armani Aviator Green", 	19029, 840, 	2 },
		// { CATEGORY_GLASSES, 66,	"Gucci Techno Yellow" , 	19017, 650, 	2 },
		// { CATEGORY_GLASSES, 67,	"Gucci Techno Salmon" , 	19018, 650, 	2 },
		{ CATEGORY_GLASSES, 68,	"古驰科技红" , 		19019, 650, 	2 },
		{ CATEGORY_GLASSES, 69,	"古驰科技蓝" , 		19020, 650, 	2 },
		{ CATEGORY_GLASSES, 70,	"古驰科技绿" , 		19021, 650, 	2 },
		// { CATEGORY_GLASSES, 71,	"Versace Vintage", 			19033, 520, 	2 },
		// { CATEGORY_GLASSES, 72,	"Versace Havana Wrap", 		19030, 490, 	2 },
		{ CATEGORY_GLASSES, 73,	"奥克利威斯克", 			19008, 400, 	2 },
		{ CATEGORY_GLASSES, 76,	"范思哲大理石广场", 	19035, 380, 	2 },

		// HANDHELD
		{ CATEGORY_HANDHELD, 100, "古董剑", 			19590, 	15000, 	6 },
		{ CATEGORY_HANDHELD, 101, "麦克风", 			19610, 	900, 	6 },
		{ CATEGORY_HANDHELD, 102, "警察电台", 			19942, 	750, 	6 },
		{ CATEGORY_HANDHELD, 103, "左拳击手套", 		19555, 	250, 	6 },
		{ CATEGORY_HANDHELD, 104, "右拳击手套", 	19556, 	250, 	5 },
		{ CATEGORY_HANDHELD, 105, "公文包", 				19624, 	100, 	6 },

		// WEAPONS
		{ CATEGORY_WEAPONS, 125, "RPG", 					359, 13337, 1 },
		{ CATEGORY_WEAPONS, 124, "追踪火箭筒", 				360, 13337, 1 },
		{ CATEGORY_WEAPONS, 123, "转机枪", 				362, 13337, 1 },
		{ CATEGORY_WEAPONS, 121, "Spas 12", 				351, 9000, 1 },
		{ CATEGORY_WEAPONS, 122, "M4", 						356, 9000, 1 },
		{ CATEGORY_WEAPONS, 119, "短管霰弹枪", 		350, 8000, 1 },
		{ CATEGORY_WEAPONS, 120, "狙击枪", 					358, 8000, 1 },
		{ CATEGORY_WEAPONS, 118, "霰弹枪", 				349, 6000, 1 },
		{ CATEGORY_WEAPONS, 117, "沙漠之鹰", 			348, 5000, 1 },
		{ CATEGORY_WEAPONS, 116, "步枪", 					357, 3000, 1 },
		{ CATEGORY_WEAPONS, 115, "Tec 9", 					372, 2900, 1 },
		{ CATEGORY_WEAPONS, 114, "Mac 10", 					352, 2500, 1 },
		{ CATEGORY_WEAPONS, 109, "紫色假阳具", 			321, 690, 1 },
		{ CATEGORY_WEAPONS, 108, "降落伞", 				371, 600, 1 },
		{ CATEGORY_WEAPONS,	107, "台球杆",				338, 400, 1 },
		{ CATEGORY_WEAPONS, 106, "指虎", 			331, 250, 1 },

		// MISC
		{ CATEGORY_MISC, 99, "金条", 					19941, 	38000,	1 },
		{ CATEGORY_MISC, 74, "牛仔靴",				11735, 	3000,	1 },
		{ CATEGORY_MISC, 77, "大麻卷",				2901, 	2000, 	1 },
		{ CATEGORY_MISC, 75, "手枪皮套",				19773, 	1000,	1 },
		{ CATEGORY_MISC, 79, "警灯",   				19419, 	600,	1 },
		{ CATEGORY_MISC, 94, "圣诞盒1",					19054,  500,	1 },
		{ CATEGORY_MISC, 95, "圣诞盒2",					19056,  500,	1 },
		{ CATEGORY_MISC, 80, "冲浪板",					2406,  	250,	1 },
		{ CATEGORY_MISC, 97, "滑板",					19878, 	200, 	1 },
		{ CATEGORY_MISC, 81, "滑翔机",         				2512, 	150,	1 },
		{ CATEGORY_MISC, 82, "飞机",          				2510, 	120,	1 },
		{ CATEGORY_MISC, 98, "徒步旅行者背包", 				19559, 	100, 	1 },
		{ CATEGORY_MISC, 78, "背包",					3026,	90,		1 },
		{ CATEGORY_MISC, 83, "垃圾桶",   				1343, 	80,		1 },
		{ CATEGORY_MISC, 84, "电锯假阳具",				19086, 	69,		5 },
		{ CATEGORY_MISC, 85, "复活节彩蛋",					19344, 	50,		2 },
		{ CATEGORY_MISC, 86, "河马蛋白",					1371, 	50,		1 },
		{ CATEGORY_MISC, 92, "南瓜",						19320, 	10,		1 },

		// VIP
		{ CATEGORY_VIP, -1,	"小火",     				18688,	0,		1 },
		{ CATEGORY_VIP, -1,	"炸药",      				1654,	0,		6 },
		{ CATEGORY_VIP, -1,	"小心桶", 				1218,	0,		1 },
		{ CATEGORY_VIP, -1,	"储气罐",    					918,	0,		1 },
		{ CATEGORY_VIP, -1,	"鹦鹉",         				19079, 	0,	   15 },
		{ CATEGORY_VIP, -1,	"钱堆", 					1212, 	0,		6 },
		{ CATEGORY_VIP, -1,	"龟", 						1609, 	0,		1 },
		{ CATEGORY_VIP, -1,	"特警头盔", 				19141, 	0,		2 },
		{ CATEGORY_VIP, -1,	"特警装甲", 				19142, 	0,		1 },
		{ CATEGORY_VIP, -1, "建筑背心",			19904, 	0,		1 },
		{ CATEGORY_VIP, -1, "大锤", 				19631, 	0,		5 },
		{ CATEGORY_VIP, -1, "激光瞄准器", 					18643, 	0,		5 },
		{ CATEGORY_VIP, -1,	"更好的圣诞老人帽子",     		19065,	0,		2 }
	},
	p_AttachedObjectsData     	[ MAX_PLAYERS ] [ 3 ] [ E_ATTACHED_DATA ],
	p_ToySlotSelected			[ MAX_PLAYERS char ],
	p_ToyCategorySelected 		[ MAX_PLAYERS char ],
	p_ToyIDSelected 			[ MAX_PLAYERS char ],
	bool: p_ToyUnlocked     	[ MAX_PLAYERS ] [ MAX_TOY_UNLOCKS char ]
;

/* ** Hooks ** */
hook OnPlayerDisconnect( playerid, reason )
{
	for ( new i = 0; i < MAX_TOY_UNLOCKS; i ++ )
	{
		p_ToyUnlocked[ playerid ] { i } = false;

		// reset attached toy data in the loop .. reusing it
		if ( i < sizeof( p_AttachedObjectsData[ ] ) ) {
			resetPlayerToys( playerid, i );
		}
	}
	return 1;
}

hook OnPlayerSpawn( playerid )
{
	reloadPlayerToys( playerid );
	return 1;
}

hook OnPlayerLogin( playerid )
{
	new
		accountid = GetPlayerAccountID( playerid );

	mysql_function_query( dbHandle, sprintf( "SELECT * FROM `TOY_UNLOCKS` WHERE `USER_ID`=%d", accountid ), true, "OnToyLoad", "d", playerid );
	mysql_function_query( dbHandle, sprintf( "SELECT * FROM `TOYS` WHERE `USER_ID`=%d", accountid ), true, "OnToyOffsetLoad", "d", playerid );
	return 1;
}

hook OnPlayerEnterDynamicCP( playerid, checkpointid )
{
	if ( checkpointid == g_Checkpoints[ CP_PAWNSHOP ] ) {
		return ShowPlayerDialog( playerid, DIALOG_TOYS_BUY, DIALOG_STYLE_LIST, "{FFFFFF}购买玩具", getToyCategories( .pawnshop = true ), "选择", "取消" );
	}
	return 1;
}

hook OnPlayerEditAttachedObj( playerid, response, index, modelid, boneid, Float:fOffsetX, Float:fOffsetY, Float:fOffsetZ, Float:fRotX, Float:fRotY, Float:fRotZ, Float:fScaleX, Float:fScaleY, Float:fScaleZ )
{
	new slot = p_ToySlotSelected{ playerid };
	new color = p_AttachedObjectsData[ playerid ] [ slot ] [ E_COLOR ];

	if ( response )
	{
		new bool: modded;

	    if ( fScaleX < 0.1 || fScaleX > 2.5 ) fScaleX = 1.0, modded = true;
	    if ( fScaleY < 0.1 || fScaleY > 2.5 ) fScaleY = 1.0, modded = true;
	    if ( fScaleZ < 0.1 || fScaleZ > 2.5 ) fScaleZ = 1.0, modded = true;
	    if ( modded ) SendServerMessage( playerid, "某些缩放部件要么太小,要么太大.它们已缩放至默认大小." );

	   	p_AttachedObjectsData[ playerid ] [ slot ] [ E_BONE ] = boneid;
		p_AttachedObjectsData[ playerid ] [ slot ] [ E_OX ] = fOffsetX;
		p_AttachedObjectsData[ playerid ] [ slot ] [ E_OY ] = fOffsetY;
		p_AttachedObjectsData[ playerid ] [ slot ] [ E_OZ ] = fOffsetZ;
		p_AttachedObjectsData[ playerid ] [ slot ] [ E_RX ] = fRotX;
		p_AttachedObjectsData[ playerid ] [ slot ] [ E_RY ] = fRotY;
		p_AttachedObjectsData[ playerid ] [ slot ] [ E_RZ ] = fRotZ;
		p_AttachedObjectsData[ playerid ] [ slot ] [ E_SX ] = fScaleX;
		p_AttachedObjectsData[ playerid ] [ slot ] [ E_SY ] = fScaleY;
		p_AttachedObjectsData[ playerid ] [ slot ] [ E_SZ ] = fScaleZ;
		p_AttachedObjectsData[ playerid ] [ slot ] [ E_MODELID ] = modelid;

		RemovePlayerAttachedObject( playerid, index );
		SetPlayerAttachedObject( playerid, index, modelid, boneid, fOffsetX, fOffsetY, fOffsetZ, fRotX, fRotY, fRotZ, fScaleX, fScaleY, fScaleZ, color, color );

		format( szBigString, sizeof( szBigString ), "UPDATE `TOYS` SET `OX`=%f,`OY`=%f,`OZ`=%f,`RX`=%f,`RY`=%f,`RZ`=%f,`SX`=%f,`SY`=%f,`SZ`=%f WHERE `ID`=%d", fOffsetX, fOffsetY, fOffsetZ, fRotX, fRotY, fRotZ, fScaleX, fScaleY, fScaleZ, p_AttachedObjectsData[ playerid ] [ slot ] [ E_SQL_ID ] );
		mysql_single_query( szBigString );

		//printf("SetPlayerAttachedObject( playerid, %d, %d, %d, %f, %f, %f, %f, %f, %f, %f, %f, %f );",index, modelid, boneid, fOffsetX, fOffsetY, fOffsetZ, fRotX, fRotY, fRotZ, fScaleX, fScaleY, fScaleZ );
	}
	else
	{
		// User Cancelled
		RemovePlayerAttachedObject( playerid, index );
		SetPlayerAttachedObject( playerid, index, p_AttachedObjectsData[ playerid ] [ slot ] [ E_MODELID ], p_AttachedObjectsData[ playerid ] [ slot ] [ E_BONE ],
			p_AttachedObjectsData[ playerid ] [ slot ] [ E_OX ], p_AttachedObjectsData[ playerid ] [ slot ] [ E_OY ], p_AttachedObjectsData[ playerid ] [ slot ] [ E_OZ ],
			p_AttachedObjectsData[ playerid ] [ slot ] [ E_RX ], p_AttachedObjectsData[ playerid ] [ slot ] [ E_RY ], p_AttachedObjectsData[ playerid ] [ slot ] [ E_RZ ],
			p_AttachedObjectsData[ playerid ] [ slot ] [ E_SX ], p_AttachedObjectsData[ playerid ] [ slot ] [ E_SY ], p_AttachedObjectsData[ playerid ] [ slot ] [ E_SZ ],
			color, color
		);
	}
	showToyEditMenu( playerid, slot );
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_TOYS_MAIN && response )
	{
		if ( !listitem )
		{
			if ( !p_AttachedObjectsData[ playerid ] [ 0 ] [ E_ENABLED ] && !p_AttachedObjectsData[ playerid ] [ 1 ] [ E_ENABLED ] && !p_AttachedObjectsData[ playerid ] [ 2 ] [ E_ENABLED ] )
				return SendError( playerid, "所有附加的玩具均已被禁用." );

			format( szNormalString, sizeof( szNormalString ), "UPDATE `TOYS` SET `ENABLED`=0 WHERE `USER_ID`=%d", p_AccountID[ playerid ] );
			mysql_single_query( szNormalString );

			RemovePlayerAttachedObject( playerid, 9 );
			RemovePlayerAttachedObject( playerid, 8 );
			RemovePlayerAttachedObject( playerid, 7 );
			p_AttachedObjectsData[ playerid ] [ 0 ] [ E_ENABLED ] = 0;
			p_AttachedObjectsData[ playerid ] [ 1 ] [ E_ENABLED ] = 0;
			p_AttachedObjectsData[ playerid ] [ 2 ] [ E_ENABLED ] = 0;
			return SendServerMessage( playerid, "所有附加的玩具均已被禁用." );
		}

		p_ToySlotSelected{ playerid } = listitem - 1;
		if ( p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_BONE ] ) {
			showToyEditMenu( playerid, p_ToySlotSelected{ playerid } );
		} else {
            ShowPlayerDialog( playerid, DIALOG_TOYS, DIALOG_STYLE_LIST, "{FFFFFF}玩具", getToyCategories( ), "选择", "返回" );
      	}
	}
	else if ( dialogid == DIALOG_TOYS_ITEMS )
	{
	    if ( !response )
            return ShowPlayerDialog( playerid, DIALOG_TOYS, DIALOG_STYLE_LIST, "{FFFFFF}玩具", getToyCategories( ), "选择", "返回" );

		for( new id, x = 0; id < MAX_TOYS; id++ )
		{
			if ( g_ToyData[ id ] [ E_CATEGORY ] == p_ToyCategorySelected{ playerid } )
			{
		       	if ( x == listitem )
		      	{
		      		p_ToyIDSelected{ playerid } = id;

				    if ( g_ToyData[ id ] [ E_ID ] == -1 )
				    {
						showToyCategoryItems( playerid, p_ToyCategorySelected{ playerid } );

				    	if ( p_VIPLevel[ playerid ] < VIP_REGULAR )
                            return SendError( playerid, "你必须是 VIP 才能使用此功能,才能成为一次访问 "COL_GREY"donate.sfcnr.com" ), 1;

						if ( ( ( p_VIPExpiretime[ playerid ] - g_iTime ) / 86400 ) < 3 )
							return SendError( playerid, "你需要超过 3 天的 VIP 才能完成此任务." ), 1;
				    }

				    if ( g_ToyData[ id ] [ E_ID ] != -1 && !p_ToyUnlocked[ playerid ] { g_ToyData[ id ] [ E_ID ] } )
				    {
						showToyCategoryItems( playerid, p_ToyCategorySelected{ playerid } );
						return SendError( playerid, "你尚未解锁该玩具." );
				    }

                    SendServerMessage( playerid, "你已经选择了 "COL_GREY"%s"COL_WHITE".继续选择骨骼以放置玩具.", g_ToyData[ id ] [ E_NAME ] );
                    ShowPlayerDialog( playerid, DIALOG_TOYS_BONE, DIALOG_STYLE_LIST, "{FFFFFF}玩具 - 骨头", ""COL_GREY"使用默认骨骼\n脊柱\n头部\n左上臂\n右上臂\n左手\n右手\n左大腿\n右大腿\n左脚\n右脚\n右小腿\n左小腿\n左前臂\n右前臂\n左锁骨\n右锁骨\n颈部\n下颌", "选择", "返回" );
					break;
		   		}
		      	x ++;
			}
		}
	}
	else if ( dialogid == DIALOG_TOYS_ITEMS_BUY )
	{
	    if ( !response )
            return ShowPlayerDialog( playerid, DIALOG_TOYS_BUY, DIALOG_STYLE_LIST, "{FFFFFF}购买玩具", getToyCategories( .pawnshop = true ), "选择", "取消" );

		for( new id, x = 0; id < MAX_TOYS; id++ )
		{
			if ( g_ToyData[ id ] [ E_CATEGORY ] == p_ToyCategorySelected{ playerid } )
			{
		       	if ( x == listitem )
		      	{
		      		SetPVarInt( playerid, "toy_item", id );
					ShowPlayerDialog( playerid, DIALOG_TOY_PREVIEW, DIALOG_STYLE_TABLIST, "{FFFFFF}购买玩具", sprintf( "购买玩具\t"COL_GOLD"%s\n预览玩具\t ", cash_format( g_ToyData[ id ] [ E_PRICE ] ) ), "选择", "返回" );
		      		break;
		   		}
		      	x ++;
			}
		}
	}
	else if ( dialogid == DIALOG_TOY_PREVIEW )
	{
		if ( ! response )
			return showToyCategoryItems( playerid, p_ToyCategorySelected{ playerid }, .pawnshop = true );

		new
			id = GetPVarInt( playerid, "toy_item" );

		if ( ! ( 0 <= id < sizeof( g_ToyData ) ) )
			return SendError( playerid, "发生错误,请重试." );

		switch ( listitem )
		{
			// bought
			case 0:
			{
				if ( p_ToyUnlocked[ playerid ] { g_ToyData[ id ] [ E_ID ] } )
			    {
					showToyCategoryItems( playerid, p_ToyCategorySelected{ playerid }, .pawnshop = true );
					return SendError( playerid, "你已经购买了这个玩具." );
			    }

	      		if ( GetPlayerCash( playerid ) < g_ToyData[ id ] [ E_PRICE ] )
	      		{
					showToyCategoryItems( playerid, p_ToyCategorySelected{ playerid }, .pawnshop = true );
					return SendError( playerid, "你买不起这个玩具." );
	      		}

			    UnlockPlayerToy( playerid, g_ToyData[ id ] [ E_ID ] );
			    GivePlayerCash( playerid, -g_ToyData[ id ] [ E_PRICE ] );
				StockMarket_UpdateEarnings( E_STOCK_PAWN_STORE, g_ToyData[ id ] [ E_PRICE ], 0.25 );
				showToyCategoryItems( playerid, p_ToyCategorySelected{ playerid }, .pawnshop = true );
                SendServerMessage( playerid, "你已购买了 "COL_GREY"%s"COL_WHITE", 获得"COL_GOLD"%s"COL_WHITE".", g_ToyData[ id ] [ E_NAME ], cash_format( g_ToyData[ id ] [ E_PRICE ] ) );
			}

			// preview
			case 1:
			{
				return ShowPlayerModelPreview( playerid, MODEL_PREVIEW_TOY, "玩具预览", g_ToyData[ id ] [ E_MODEL ] );
			}
		}
	}
	else if ( dialogid == DIALOG_TOYS_BONE || dialogid == DIALOG_TOYS_BONE_EDIT )
	{
		new
			iSlot = p_ToySlotSelected{ playerid };

	    if ( !response && dialogid == DIALOG_TOYS_BONE )
			return showToyCategoryItems( playerid, p_ToyCategorySelected{ playerid } );

	    if ( !response && dialogid == DIALOG_TOYS_BONE_EDIT )
			return showToyEditMenu( playerid, iSlot );

	    if ( !listitem ) {
    		p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_BONE ] = g_ToyData[ p_ToyIDSelected{ playerid } ] [ E_DEFAULT_BONE ];
	        SendServerMessage( playerid, "你现在已将玩具放置在默认骨骼上." );
	    }
	    else {
	        p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_BONE ] = listitem;
	        SendServerMessage( playerid, "现在你已将玩具放在这块骨头上." );
	    }

		RemovePlayerAttachedObject( playerid, 7 + iSlot );
	    SetPlayerAttachedObject( playerid, 7 + iSlot, g_ToyData[ p_ToyIDSelected{ playerid } ] [ E_MODEL ], p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_BONE ] );

	    p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_ENABLED ] = 1;
		p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_MODELID ] = g_ToyData[ p_ToyIDSelected{ playerid } ] [ E_MODEL ];

	    if ( dialogid == DIALOG_TOYS_BONE ) {
			format( szBigString, sizeof( szBigString ), "INSERT INTO `TOYS`(`USER_ID`,`SLOT_ID`,`ENABLED`,`MODEL_ID`,`BONE`) VALUES (%d,%d,1,%d,%d)", p_AccountID[ playerid ], iSlot, g_ToyData[ p_ToyIDSelected{ playerid } ] [ E_MODEL ], p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_BONE ] );
			mysql_function_query( dbHandle, szBigString, true, "OnPlayerAddToy", "dd", playerid, iSlot );
	    } else {
			format( szNormalString, sizeof( szNormalString ), "UPDATE `TOYS` SET `BONE`=%d,`OX`=0,`OY`=0,`OZ`=0,`RX`=0,`RY`=0,`RZ`=0,`SX`=1,`SY`=1,`SZ`=1 WHERE `ID`=%d", p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_BONE ], p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_SQL_ID ] );
			mysql_single_query( szNormalString );
	    }

		showToyEditMenu( playerid, iSlot );
	}
	else if ( dialogid == DIALOG_TOYS_COLOR )
	{
		new
			slot = p_ToySlotSelected{ playerid };

	    if ( !response )
			return showToyEditMenu( playerid, slot );

		new
			hexcode[ 7 ];

		if ( sscanf( inputtext, "S(000000)[7]", hexcode ) ) SendError( playerid, "请确保你的十六进制最多为 6 个字符 (RRGGBB)." );
		else if ( ! isHex( hexcode ) ) SendError( playerid, "这不是有效的十六进制代码." );
		else
		{
			if ( strmatch( hexcode, "000000" ) )
			{
		    	p_AttachedObjectsData[ playerid ] [ slot ] [ E_COLOR ] = 0;
		    	mysql_single_query( sprintf( "UPDATE `TOYS` SET `COLOR`=0 WHERE `ID`=%d", p_AttachedObjectsData[ playerid ] [ slot ] [ E_SQL_ID ] ) );
				SendServerMessage( playerid, "你已重置玩具的颜色." );
			}
			else
			{
				new
					final_hex;

				if ( ! sscanf( sprintf( "0xFF%s", hexcode ), "h", final_hex ) )
				{
			    	p_AttachedObjectsData[ playerid ] [ slot ] [ E_COLOR ] = final_hex;
			    	mysql_single_query( sprintf( "UPDATE `TOYS` SET `COLOR`=%d WHERE `ID`=%d", p_AttachedObjectsData[ playerid ] [ slot ] [ E_COLOR ], p_AttachedObjectsData[ playerid ] [ slot ] [ E_SQL_ID ] ) );
					SendServerMessage( playerid, "你已将玩具的颜色设置为 {%s}%s"COL_WHITE".", hexcode, hexcode );
				}
				else SendError( playerid, "这不是有效的十六进制代码." );
			}
			return reloadPlayerToys( playerid );
		}
		return showToyEditMenu( playerid, slot );
	}
	else if ( dialogid == DIALOG_TOYS_EDIT )
	{
		if ( !response )
			return cmd_toys( playerid, "" );

		switch( listitem )
		{
			case 0:
			{
				if ( !p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_ENABLED ] ) {
					SendError( playerid, "你无法编辑禁用的玩具." );
					return showToyEditMenu( playerid, p_ToySlotSelected{ playerid } );
				}

			    EditAttachedObject( playerid, 7 + p_ToySlotSelected{ playerid } );
			    SendServerMessage( playerid, "你现在正在编辑一个玩具." );
			}
			case 1:
			{
				if ( !p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_ENABLED ] ) {
					SendError( playerid, "你无法重新选择已禁用玩具的骨骼." );
					return showToyEditMenu( playerid, p_ToySlotSelected{ playerid } );
				}

				ShowPlayerDialog( playerid, DIALOG_TOYS_BONE_EDIT, DIALOG_STYLE_LIST, "{FFFFFF}玩具 - 骨头", ""COL_GREY"使用默认骨骼\n脊柱\n头部\n左上臂\n右上臂\n左手\n右手\n左大腿\n右大腿\n左脚\n右脚\n右小腿\n左小腿\n左前臂\n右前臂\n左锁骨\n右锁骨\n颈部\n下颌", "选择", "返回" );
			    SendServerMessage( playerid, "你现在正在重新选择玩具的骨头." );
			}
			case 2:
			{
				if ( !p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_ENABLED ] ) {
					SendError( playerid, "你无法设置禁用玩具的颜色." );
					return showToyEditMenu( playerid, p_ToySlotSelected{ playerid } );
				}

				ShowPlayerDialog( playerid, DIALOG_TOYS_COLOR, DIALOG_STYLE_INPUT, "{FFFFFF}玩具 - 颜色", ""COL_WHITE"请将颜色(十六进制)代码指定为 "COL_RED"RR"COL_GREEN"GG"COL_BLUE"BB"COL_WHITE" 如下:", "选择", "返回" );
			    SendServerMessage( playerid, "你现在正在编辑玩具的颜色,请不输入任何内容或输入 000000 来重置它." );
			}
			case 3:
			{
				p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_ENABLED ] = !p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_ENABLED ];

				if ( !p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_ENABLED ] )
				{
					RemovePlayerAttachedObject( playerid, 7 + p_ToySlotSelected{ playerid } );
					SendServerMessage( playerid, "你已经禁用了这个玩具." );
				}
				else
				{
					RemovePlayerAttachedObject( playerid, 7 + p_ToySlotSelected{ playerid } ); // Just incase.
					SetPlayerAttachedObject( playerid, 7 + p_ToySlotSelected{ playerid }, p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_MODELID ], p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_BONE ],
						p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_OX ], p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_OY ], p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_OZ ],
						p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_RX ], p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_RY ], p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_RZ ],
						p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_SX ], p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_SY ], p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_SZ ],
						p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_COLOR ], p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_COLOR ]
					);
					SendServerMessage( playerid, "你已启用此玩具." );
				}

				format( szNormalString, sizeof( szNormalString ), "UPDATE `TOYS` SET `ENABLED`=%d WHERE `ID`=%d", p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_ENABLED ], p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_SQL_ID ] );
				mysql_single_query( szNormalString );

				showToyEditMenu( playerid, p_ToySlotSelected{ playerid } );
			}
			case 4:
			{
				RemovePlayerAttachedObject( playerid, 7 + p_ToySlotSelected{ playerid } );
			   	p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_BONE ] = 0;
				p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_MODELID ] = 0;

				format( szNormalString, sizeof( szNormalString ), "DELETE FROM `TOYS` WHERE `ID`=%d", p_AttachedObjectsData[ playerid ] [ p_ToySlotSelected{ playerid } ] [ E_SQL_ID ] );
				mysql_single_query( szNormalString );

				SendServerMessage( playerid, "你已经移除了这个玩具." );
				cmd_toys( playerid, "" );
			}
		}
	}
	else if ( dialogid == DIALOG_TOYS ) {
		if ( !response )
			return cmd_toys( playerid, "" );

		p_ToyCategorySelected{ playerid } = listitem;
		showToyCategoryItems( playerid, listitem );
	}
	else if ( dialogid == DIALOG_TOYS_BUY && response ) {
		p_ToyCategorySelected{ playerid } = listitem;
		showToyCategoryItems( playerid, listitem, .pawnshop = true );
	}
	return 1;
}

hook OnPlayerEndModelPreview( playerid, handleid )
{
	if ( handleid == MODEL_PREVIEW_TOY )
	{
		new
			id = GetPVarInt( playerid, "toy_item" );

		SendServerMessage( playerid, "你已经看完这个玩具预览." );
		return ShowPlayerDialog( playerid, DIALOG_TOY_PREVIEW, DIALOG_STYLE_TABLIST, "{FFFFFF}购买玩具", sprintf( "购买玩具\t"COL_GOLD"%s\n预览玩具\t ", cash_format( g_ToyData[ id ] [ E_PRICE ] ) ), "选择", "返回" ), Y_HOOKS_BREAK_RETURN_1;
	}
	return 1;
}

/* ** Commands ** */
CMD:toys( playerid, params[ ] )
{
	if ( !IsPlayerSpawned( playerid ) )
		return SendError( playerid, "当你未生成时,你无法使用此命令." );

	return ShowPlayerToys( playerid );
}

/* ** SQL Threads ** */
thread OnToyLoad( playerid )
{
	if ( !IsPlayerConnected( playerid ) )
		return 0;

	new
		rows, fields, i = -1
	;

	cache_get_data( rows, fields );
	if ( rows ) {
		while( ++i < rows ) {
			new iToy = cache_get_field_content_int( i, "TOY_ID", dbHandle );

			if ( iToy < MAX_TOY_UNLOCKS ) // Must be something wrong otherwise...
				p_ToyUnlocked[ playerid ] { iToy } = true;
		}
	}
	return 1;
}

thread OnToyOffsetLoad( playerid )
{
	if ( !IsPlayerConnected( playerid ) )
		return 0;

	new
		rows, fields, i = -1
	;

	cache_get_data( rows, fields );
	if ( rows ) {
		while( ++i < rows ) {
			new
				iSlot = cache_get_field_content_int( i, "SLOT_ID", dbHandle );

			if ( iSlot < sizeof( p_AttachedObjectsData[ ] ) ) {
				p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_SQL_ID ] = cache_get_field_content_int( i, "ID", dbHandle );
				p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_ENABLED ] = cache_get_field_content_int( i, "ENABLED", dbHandle );
				p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_MODELID ] = cache_get_field_content_int( i, "MODEL_ID", dbHandle );
				p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_BONE ] = cache_get_field_content_int( i, "BONE", dbHandle );
				p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_OX ] = cache_get_field_content_float( i, "OX", dbHandle );
				p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_OY ] = cache_get_field_content_float( i, "OY", dbHandle );
				p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_OZ ] = cache_get_field_content_float( i, "OZ", dbHandle );
				p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_RX ] = cache_get_field_content_float( i, "RX", dbHandle );
				p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_RY ] = cache_get_field_content_float( i, "RY", dbHandle );
				p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_RZ ] = cache_get_field_content_float( i, "RZ", dbHandle );
				p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_SX ] = cache_get_field_content_float( i, "SX", dbHandle );
				p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_SY ] = cache_get_field_content_float( i, "SY", dbHandle );
				p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_SZ ] = cache_get_field_content_float( i, "SZ", dbHandle );
				p_AttachedObjectsData[ playerid ] [ iSlot ] [ E_COLOR ] = cache_get_field_content_int( i, "COLOR", dbHandle );
			}
		}
	}
	return 1;
}

thread OnPlayerAddToy( playerid, slotid ) {
	p_AttachedObjectsData[ playerid ] [ slotid ] [ E_SQL_ID ] = cache_insert_id( );
	return 1;
}


/* ** Functions ** */
stock getToyCategories( bool: pawnshop = false )
{
	static
		szToyCategory[ 150 ],
		szPawnCategory[ 150 ];

	if ( szToyCategory[ 0 ] == '\0' ) {
		for( new i = 0; i < sizeof( g_ToyCategory ); i++ )
			format( szToyCategory, sizeof( szToyCategory ), "%s%s\n", szToyCategory, g_ToyCategory[ i ] );
	}

	if ( szPawnCategory[ 0 ] == '\0' ) {
		for( new i = 0; i < sizeof( g_ToyCategory ); i++ ) if ( i != CATEGORY_VIP )
			format( szPawnCategory, sizeof( szPawnCategory ), "%s%s\n", szPawnCategory, g_ToyCategory[ i ] );
	}

	return pawnshop ? szPawnCategory : szToyCategory;
}

stock showToyCategoryItems( playerid, category, bool: pawnshop = false )
{
	erase( szLargeString );

	for( new i = 0; i < sizeof( g_ToyData ); i++ )
	{
		if ( g_ToyData[ i ] [ E_CATEGORY ] == category )
		{
			if ( pawnshop ) {
				format( szLargeString, sizeof( szLargeString ), "%s%s%s\t"COL_GOLD"%s\n", szLargeString, p_ToyUnlocked[ playerid ] { g_ToyData[ i ] [ E_ID ] } ? ( #COL_LGREEN ) : ( #COL_WHITE ), g_ToyData[ i ] [ E_NAME ], cash_format( g_ToyData[ i ] [ E_PRICE ] ) );
			} else {
				format( szLargeString, sizeof( szLargeString ), "%s%s%s\n", szLargeString, g_ToyData[ i ] [ E_ID ] != -1 ? ( !p_ToyUnlocked[ playerid ] { g_ToyData[ i ] [ E_ID ] } ? ( "{3D3D3D}" ) : ( "{FFFFFF}" ) ) : ( COL_GOLD ), g_ToyData[ i ] [ E_NAME ] );
			}
		}
	}

	if ( pawnshop ) {
		return ShowPlayerDialog( playerid, DIALOG_TOYS_ITEMS_BUY, DIALOG_STYLE_TABLIST, pawnshop ? ( "{FFFFFF}购买玩具" ) : ( "{FFFFFF}玩具" ), szLargeString, "选择", "返回" );
	} else {
		return ShowPlayerDialog( playerid, DIALOG_TOYS_ITEMS, DIALOG_STYLE_LIST, pawnshop ? ( "{FFFFFF}购买玩具" ) : ( "{FFFFFF}玩具" ), szLargeString, "选择", "返回" );
	}
}

stock UnlockPlayerToy( playerid, toy_id )
{
	if ( toy_id > MAX_TOY_UNLOCKS )
		return;

	p_ToyUnlocked[ playerid ] { toy_id } = true;
	format( szNormalString, 72, "INSERT INTO `TOY_UNLOCKS`(`USER_ID`, `TOY_ID`) VALUES (%d, %d)", p_AccountID[ playerid ], toy_id);
	mysql_single_query( szNormalString );
}

stock resetPlayerToys( playerid, slot ) {
   	p_AttachedObjectsData[ playerid ] [ slot ] [ E_ENABLED ] = 0;
	p_AttachedObjectsData[ playerid ] [ slot ] [ E_MODELID ] = 0;
   	p_AttachedObjectsData[ playerid ] [ slot ] [ E_BONE ] = 0;
	p_AttachedObjectsData[ playerid ] [ slot ] [ E_OX ] = 0.0;
	p_AttachedObjectsData[ playerid ] [ slot ] [ E_OY ] = 0.0;
	p_AttachedObjectsData[ playerid ] [ slot ] [ E_OZ ] = 0.0;
	p_AttachedObjectsData[ playerid ] [ slot ] [ E_RX ] = 0.0;
	p_AttachedObjectsData[ playerid ] [ slot ] [ E_RY ] = 0.0;
	p_AttachedObjectsData[ playerid ] [ slot ] [ E_RZ ] = 0.0;
	p_AttachedObjectsData[ playerid ] [ slot ] [ E_SX ] = 0.0;
	p_AttachedObjectsData[ playerid ] [ slot ] [ E_SY ] = 0.0;
	p_AttachedObjectsData[ playerid ] [ slot ] [ E_SZ ] = 0.0;
	p_AttachedObjectsData[ playerid ] [ slot ] [ E_COLOR ] = 0;
}

stock showToyEditMenu( playerid, slot )
{
	if ( p_AttachedObjectsData[ playerid ] [ slot ] [ E_ENABLED ] ) {
		return ShowPlayerDialog( playerid, DIALOG_TOYS_EDIT, DIALOG_STYLE_LIST, "{FFFFFF}玩具", ""COL_WHITE"编辑玩具位置\n"COL_WHITE"编辑玩具骨头\n"COL_WHITE"编辑玩具颜色\n禁用玩具\n"COL_LRED"移除玩具", "选择", "返回" );
	} else {
		return ShowPlayerDialog( playerid, DIALOG_TOYS_EDIT, DIALOG_STYLE_LIST, "{FFFFFF}玩具", ""COL_BLACK"编辑玩具位置\n"COL_BLACK"编辑玩具骨头\n"COL_BLACK"编辑玩具颜色\n启用玩具", "选择", "返回" );
	}
}

stock reloadPlayerToys( playerid )
{
	for ( new i = 0; i < sizeof ( p_AttachedObjectsData[ ] ); i ++ ) {
		if ( p_AttachedObjectsData[ playerid ] [ i ] [ E_ENABLED ] ) {
			RemovePlayerAttachedObject( playerid, 7 + i );
			SetPlayerAttachedObject( playerid, 7 + i, p_AttachedObjectsData[ playerid ] [ i ] [ E_MODELID ], p_AttachedObjectsData[ playerid ] [ i ] [ E_BONE ],
				p_AttachedObjectsData[ playerid ] [ i ] [ E_OX ], p_AttachedObjectsData[ playerid ] [ i ] [ E_OY ], p_AttachedObjectsData[ playerid ] [ i ] [ E_OZ ],
				p_AttachedObjectsData[ playerid ] [ i ] [ E_RX ], p_AttachedObjectsData[ playerid ] [ i ] [ E_RY ], p_AttachedObjectsData[ playerid ] [ i ] [ E_RZ ],
				p_AttachedObjectsData[ playerid ] [ i ] [ E_SX ], p_AttachedObjectsData[ playerid ] [ i ] [ E_SY ], p_AttachedObjectsData[ playerid ] [ i ] [ E_SZ ],
				p_AttachedObjectsData[ playerid ] [ i ] [ E_COLOR ], p_AttachedObjectsData[ playerid ] [ i ] [ E_COLOR ]
			);
		}
	}
	return 1;
}

stock ShowPlayerToys( playerid )
{
	new
		iToy[ 3 ] [ 24 ] = { { "没有任何" }, { "没有任何" }, { "没有任何" } };

	for( new i = 0; i < sizeof( g_ToyData ); i++ ) {
 		for( new x = 0; x < sizeof( iToy ); x++ ) {
			if ( g_ToyData[ i ] [ E_MODEL ] == p_AttachedObjectsData[ playerid ] [ x ] [ E_MODELID ] )
				strcpy( iToy[ x ], g_ToyData[ i ] [ E_NAME ] );
 		}
 	}

	format( szNormalString, sizeof( szNormalString ), ""COL_GREY"禁用所有玩具\n插槽 1 (%s)\n插槽 2 (%s)\n插槽 3 (%s)", iToy[ 0 ], iToy[ 1 ], iToy[ 2 ] );
	return ShowPlayerDialog( playerid, DIALOG_TOYS_MAIN, DIALOG_STYLE_LIST, "{FFFFFF}玩具", szNormalString, "选择", "关闭" ), 1;
}