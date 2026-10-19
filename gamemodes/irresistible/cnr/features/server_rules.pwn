/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\server_rules.pwn
 * Purpose: server rules implementation (/rules) that scans URL
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Variables ** */
	static stock szRules				[ 3300 ];

/* ** Commands ** */
CMD:rules( playerid, params[ ] ) {
	return ShowPlayerRules( playerid );
}

#if defined SERVER_RULES_URL

	/* ** Forwards ** */
	public OnRulesHTTPResponse( index, response_code, data[ ] );

	/* ** Hooks ** */
	hook OnScriptInit( ) {
		HTTP( 0, HTTP_GET, SERVER_RULES_URL, "", "OnRulesHTTPResponse" );
		return 1;
	}

	/* ** Functions ** */
	public OnRulesHTTPResponse( index, response_code, data[ ] ) {
		if ( response_code == 200 ) {
			printf( "[RULES] Rules have been updated! Character Size: %d", strlen( data ) );
			strcpy( szRules, data );
		}
		return 1;
	}

#endif

/* ** Functions ** */
stock ShowPlayerRules( playerid )
{
	/*#if !defined SERVER_RULES_URL
		#pragma unused playerid
		return 1;
	#else
	#endif*/
	format( szRules, sizeof( szRules ), "{FFFFFF}1. 尊重所有玩家并服从管理员管理, 否则将被禁言.\n2. 禁止刷屏, 否则将被禁言.\n3. 禁止冒充玩家, 管理员或服主, 违者封禁.\n4. 禁止反复对他人使用命令进行骚扰.\n5. 执法人员不得协助罪犯, 否则将被监禁.\n6. 禁止蹲守建筑出口, 滥射火箭弹, 或用战斗载具的机枪持续攻击玩家.\n7. 禁止利用喷水载具或带特殊效果的武器骚扰玩家.\n8. 私人载具必须停在自家入口附近或停车场, 否则可能被移走或删除.\n9. 诈骗金额上限为 $10,000. 超过此数额将被封禁并清空账号数据.\n10. 不要干涉他人的封禁处理.\n11. 禁止恶意刷取金钱, 经验, 悬赏, 逮捕或击杀记录, 违者封禁并清空数据.\n12. 发现漏洞请向管理员或论坛报告. 禁止利用漏洞, 违者封禁.\n13. 禁止使用任何作弊工具!\n14. 证据充分且理由正当时, 管理团队可一致决定暂停用户账号." );
	return ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "{FFFFFF}规则", szRules, "确定", "" ), 1;
}