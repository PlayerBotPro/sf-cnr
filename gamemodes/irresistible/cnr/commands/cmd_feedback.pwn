/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\commands\cmd_feedback.pwn
 * Purpose: create /feedback (or /suggest) about the server
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Commands ** */
CMD:suggest( playerid, params[ ] ) return cmd_feedback( playerid, params );
CMD:feedback( playerid, params[ ] )
{
	return ShowPlayerDialog( playerid, DIALOG_FEEDBACK, DIALOG_STYLE_INPUT, ""COL_GOLD"服务器反馈", ""COL_WHITE"欢迎提出改善游戏体验的建议! 有价值的反馈可获奖励.\n\n    请直接说明问题, 尽量提供具体的改进意见.", "提交", "关闭" );
}

/* ** Hooks ** */
hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( ( dialogid == DIALOG_FEEDBACK ) && response )
	{
		if ( ! ( 10 < strlen( inputtext ) <= 512 ) )
		{
			SendError( playerid, "反馈长度必须为 10 至 512 个字符." );
			return ShowPlayerDialog( playerid, DIALOG_FEEDBACK, DIALOG_STYLE_INPUT, ""COL_GOLD"服务器反馈", ""COL_WHITE"欢迎提出改善游戏体验的建议! 有价值的反馈可获奖励.\n\n    请直接说明问题, 尽量提供具体的改进意见.\n\n"COL_RED"反馈长度必须为 10 至 512 个字符.", "提交", "关闭" );
		}

		// insert into database
		mysql_format( dbHandle, szLargeString, sizeof( szLargeString ), "INSERT INTO `FEEDBACK` (`USER_ID`, `FEEDBACK`) VALUES (%d, '%e')", p_AccountID[ playerid ], inputtext );
		mysql_single_query( szLargeString );

		return ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, ""COL_GOLD"服务器反馈", ""COL_GOLD"感谢你的反馈!"COL_WHITE" 如果建议能改善服务器, 你将获得奖励.\n\n欢迎直言, 保持建设性即可.", "关闭", "" );
	}
    return 1;
}