/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\billboards.pwn
 * Purpose: specially placed billboards to help user experience in the cities
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Macros ** */
#define CreateBillboard(%0,%1,%2,%3,%4) \
    SetDynamicObjectMaterialText( CreateDynamicObject( 7246, %1, %2, %3, 0, 0, %4 ), 0, (%0), 120, "Arial", 24, 0, -1, -16777216, 1 )

/* ** Hooks ** */
hook OnScriptInit( )
{
	CreateBillboard( "想成为 VIP? 欢迎捐助服务器!\n"COL_GREY"donate.sfcnr.com", -2016.22, 326.580, 37.950, 48.9000 );
	CreateBillboard( "请将本服加入收藏!\n"#SERVER_IP"", -1809.64, -590.29, 19.360, -147.30 );
	CreateBillboard( "可在我们的网站查看更新!\n"COL_GREY""#SERVER_WEBSITE"", -1571.11, 939.860, 10.030, 45.9600 );
	CreateBillboard( "请记得查看"COL_GREY"/rules"COL_WHITE"!\n违反规则将受到处罚!", -1911.05, 858.870, 36.290, 44.5200 );
	CreateBillboard( "想查看命令?\n请输入"COL_GREY"/commands{FFFFFF}!", -2423.40, -621.18, 135.46, -195.90 );
	CreateBillboard( "需要帮助?\n请输入"COL_GREY"/ask"COL_WHITE"联系管理员!", -2659.78, 1277.70, 9.8600, 125.100 );
	CreateBillboard( "发现作弊者? 请输入"COL_GREY"/report{FFFFFF}!", -2443.63, 719.970, 37.900, 0.00000 );
	CreateBillboard( "你可以输入"COL_GREY"/vipcmds"COL_WHITE"查看你的\nVIP 命令!", -1958.975830, 841.130798, 1208.881469, -43.700046 );
    return 1;
}