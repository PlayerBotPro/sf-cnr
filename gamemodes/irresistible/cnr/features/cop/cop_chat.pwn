/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\cop\cop_chat.pwn
 * Purpose: chat system for police (team) ... includes a 10-code feature
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Variables ** */
enum E_TEN_CODES
{
	E_CODE[ 6 ], 		E_SUBJECT[ 50 ]
};

static stock
	g_coptenCodes[ ] [ E_TEN_CODES ] =
	{
		{ "10-10", "正在斗殴" }, 						{ "10-11", "抢劫" },
		{ "10-12", "待命" }, 								{ "10-13", "天气及路况报告" },
		{ "10-14", "可疑人员报告" }, 							{ "10-15", "交通检查" },
		{ "10-16", "家庭纠纷" }, 					{ "10-17", "会见报案人" },
		{ "10-18", "迅速" },									{ "10-19", "返回" },
		{ "10-20", "地点" }, 								{ "10-21", "致电" },
		{ "10-22", "忽略" }, 								{ "10-23", "到达现场" },
		{ "10-24", "任务完成" }, 					{ "10-25", "亲自报告" },
		{ "10-26", "正在拘留嫌犯, 请加快支援" },				{ "10-27", "驾驶执照信息" },
		{ "10-28", "车辆登记信息" },		{ "10-29", "查询通缉情况" },
		{ "10-30", "非必要使用电台" }, 				{ "10-31", "犯罪进行中" },
		{ "10-32", "持枪人员" }, 							{ "10-33", "紧急情况" },
		{ "10-34", "暴动" },									{ "10-35", "重大犯罪警报" },
		{ "10-36", "校准时间" }, 							{ "10-37", "(调查)可疑车辆" },
		{ "10-38", "拦截可疑车辆" }, 			{ "10-39", "紧急 - 使用灯光,警报器" },
		{ "10-40", "静默行动, 不开警灯和警笛" }, 			{ "10-41", "开始执勤" },
		{ "10-42", "结束执勤" }, 					{ "10-43", "信息" },
		{ "10-44", "请求允许离开前往" }, 				{ "10-45", "绑架" },
		{ "10-46", "协助驾驶者" }, 						{ "10-47", "紧急道路抢修地点" },
		{ "10-48", "道路例行维修地点" }, 				{ "10-49", "交通灯故障地点" },
		{ "10-50", "事故" }, 								{ "10-51", "需要清障车" },
		{ "10-52", "需要救护车" }, 						{ "10-53", "道路封锁地点" },
		{ "10-54", "高速公路上的牲畜" }, 					{ "10-55", "疑似酒后驾车" },
		{ "10-56", "醉酒的行人" }, 					{ "10-57", "打了就跑" },
		{ "10-58", "疏导交通" }, 							{ "10-59", "护送或护送" },
		{ "10-60", "附近有警员" }, 						{ "10-61", "请单独接收消息" },
		{ "10-62", "回复消息" }, 						{ "10-63", "准备记录" },
		{ "10-64", "需本地转达的消息" }, 				{ "10-65", "通信任务" },
		{ "10-66", "消息取消" }, 					{ "10-67", "可以发送通信消息" },
		{ "10-68", "发货信息" }, 					{ "10-69", "收到消息" },
		{ "10-70", "火灾" }, 									{ "10-71", "请报告火灾类型" },
		{ "10-72", "报告灭火进展" }, 				{ "10-73", "烟雾报告" },
		{ "10-74", "否定" }, 								{ "10-75", "已接触" },
		{ "10-76", "贿赂" }, 									{ "10-77", "ETA" },
		{ "10-78", "需要帮助" }, 						{ "10-79", "通知验尸官" },
		{ "10-80", "追逐进行中" }, 						{ "10-81", "毒品活动" },
		{ "10-82", "预订住宿" }, 						{ "10-83", "嫌犯在雷达上隐身" },
		{ "10-84", "如果见面,请告知预计到达时间" }, 					{ "10-85", "延误的原因是" },
		{ "10-86", "值班人员" }, 						{ "10-87", "领取或分发支票" },
		{ "10-88", "请提供电话号码" }, 			{ "10-89", "炸弹威胁" },
		{ "10-90", "银行警报地点" }, 							{ "10-91", "押送囚犯或嫌犯" },
		{ "10-92", "违规停车" }, 				{ "10-93", "封锁" },
		{ "10-94", "飙车" }, 							{ "10-95", "囚犯或嫌犯已被拘留" },
		{ "10-96", "疑似精神异常人员" }, 							{ "10-97", "检查信号" },
		{ "10-98", "越狱" }, 						{ "10-99", "确认被通缉或失窃" },
		// Some bug, so I'll do this.
	    { "10-0", "警告" }, 									{ "10-1", "无法抄收" },
		{ "10-2", "信号良好" }, 								{ "10-3", "停止发射" },
		{ "10-4", "收到" }, 							{ "10-5", "转达" },
		{ "10-6", "正在忙, 非紧急情况请稍候" },				{ "10-7", "停止执勤" },
		{ "10-8", "正在执勤" }, 								{ "10-9", "重复" }
	}
;

/* ** Hooks ** */
hook OnPlayerText( playerid, text[ ] )
{
	if ( text[ 0 ] == '!' && ! IsPlayerSettingToggled( playerid, SETTING_CHAT_PREFIXES ) )
	{
        if ( p_Class[ playerid ] == CLASS_POLICE && ! IsPlayerChatBanned ( playerid ) )
        {
            format( szBigString, 144, "%s", text );

            for ( new i = 0; i < sizeof( g_coptenCodes ); i++ ) if ( strfind( szBigString, g_coptenCodes[ i ] [ E_CODE ] ) != -1 ) {
                strreplace( szBigString, g_coptenCodes[ i ] [ E_CODE ], g_coptenCodes[ i ] [ E_SUBJECT ] );
            }

            SendClientMessageToCops( -1, ""COL_BLUE"<警察电台>%s(%d):"COL_WHITE" %s", ReturnPlayerName( playerid ), playerid, szBigString[ 1 ] );

            foreach ( new i : Player ) if ( ( p_AdminLevel[ i ] >= 5 || IsPlayerUnderCover( i ) ) && p_ToggleCopChat{ i } == true ) {
                SendClientMessageFormatted( i, -1, ""COL_BLUE"<警察电台>%s(%d):"COL_GREY" %s", ReturnPlayerName( playerid ), playerid, szBigString[ 1 ] );
            }
            return 0;
        }

        else if ( p_Class[ playerid ] == CLASS_CIVILIAN && p_GangID[ playerid ] != INVALID_GANG_ID )
        {
            SendClientMessageToGang( p_GangID[ playerid ], g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ], "<帮派聊天> %s(%d):{FFFFFF} %s", ReturnPlayerName( playerid ), playerid, text[ 1 ] );
            return 0;
        }
    }
    return 1;
}

/* ** Commands ** */
CMD:t( playerid, params[ ] )
{
	new
	    msg[ 90 ]
	;

	if ( GetPlayerClass( playerid ) != CLASS_POLICE ) return SendError( playerid, "只有警察可以使用此命令!" );
    else if ( IsPlayerChatBanned( playerid ) ) return SendError( playerid, "你已被禁止聊天, 无法使用此功能." );
	else if ( sscanf( params, "s[90]", msg ) ) return SendUsage( playerid, "/t [MESSAGE]" );
    else
	{
		if ( p_Class[ playerid ] == CLASS_POLICE )
		{
			format( szBigString, 144, "%s", msg );

			for ( new i = 0; i < sizeof( g_coptenCodes ); i++ ) if ( strfind( szBigString, g_coptenCodes[ i ] [ E_CODE ] ) != -1 ) {
		        strreplace( szBigString, g_coptenCodes[ i ] [ E_CODE ], g_coptenCodes[ i ] [ E_SUBJECT ] );
			}

			SendClientMessageToCops( -1, ""COL_BLUE"<警察电台>%s(%d):"COL_WHITE" %s", ReturnPlayerName( playerid ), playerid, szBigString );
		}
	}
	return 1;
}
