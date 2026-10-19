/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\random_messages.pwn
 * Purpose: make bot (Stephanie) randomly send global messages about the server
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Variables ** */
static stock
	g_randomMessages 				[ ] [ 137 ] =
	{
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 你可以在 Supa Save 或 24/7 商店购买绳子来绑人!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 将我们保存在你最喜欢的位置,这样你就不会错过行动!" },
        { "{8ADE47}斯蒂芬妮:"COL_WHITE" 你可以在我们的网站上获取更新 - "#SERVER_WEBSITE"!" },
        { "{8ADE47}斯蒂芬妮:"COL_WHITE" 想开通 VIP? 请输入"COL_GREY"/vip"COL_WHITE" 了解更多详情!" },
        { "{8ADE47}斯蒂芬妮:"COL_WHITE" 考虑通过捐赠来帮助社区!你将收到 IC 代币 来兑换 VIP!" },
        { "{8ADE47}斯蒂芬妮:"COL_WHITE" 刚刚捐款?检查你的电子邮件中的交易 ID,并使用 /donated 轻松兑换你的硬币!" },
        { "{8ADE47}斯蒂芬妮:"COL_WHITE" 不要与任何人分享你的密码,甚至不要在朋友的服务器中使用它!" },
        { "{8ADE47}斯蒂芬妮:"COL_WHITE" 到达目的地有困难吗?使用 "COL_GREY"/gps{FFFFFF} inside a vehicle!" },
        { "{8ADE47}斯蒂芬妮:"COL_WHITE" 捐赠者收到 IC 代币 作为慷慨捐赠的回报,用于赎回 VIP!" },
        { "{8ADE47}斯蒂芬妮:"COL_WHITE" 抢劫商店并赚取分数,你拥有的经验越多,你获得的好处就越多!" },
        { "{8ADE47}斯蒂芬妮:"COL_WHITE" 房屋是可购买的,你可以购买一栋并将你的产卵位置设置在该房屋内!" },
        { "{8ADE47}斯蒂芬妮:"COL_WHITE" 记得检查一下 "COL_GREY"/rules{FFFFFF}!违反规则可能会受到惩罚!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 见过骗子吗?使用 "COL_GREY"/report {FFFFFF}告诉管理员." },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 要更改你的班级,请输入 "COL_GREY"/changeclass{FFFFFF}." },
		// { "{8ADE47}Stephanie:"COL_WHITE" Detaining a suspect as a cop pays more than arresting by itself, and killing." },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 通过私信被某些会员惹恼了? "COL_GREY"/dnd{FFFFFF} 阻止他们!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 看 "COL_GREY"/animlist {FFFFFF} 用于动画." },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 类型 "COL_GREY"/help {FFFFFF}有关服务器的信息!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 需要一组命令来查看?使用 "COL_GREY"/cmds{FFFFFF}!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 要给玩家金钱,请使用 "COL_GREY"/sendmoney{FFFFFF} or "COL_GREY"/sm{FFFFFF}." },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 可用 IC 代币开通 VIP! 欢迎访问网站捐助以获取更多代币!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 炸毁银行金库,或牢房;将 C4 种在两个细胞上然后爆炸!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 厌倦了一个玩家?你可以在他们头上签下一份悬赏 "COL_GREY"/placehit{FFFFFF}!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 需要在头上贴上带有信息信息的标签吗?你可以使用 "COL_GREY"/label{FFFFFF}!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 屏幕右下角的金色条是你拥有的 经验 数量!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 在推特上关注我们! "COL_GREY"@IrresistibleDev{FFFFFF}!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 保持 "COL_GREY"左 ALT{FFFFFF} 和 "COL_GREY"SPACE{FFFFFF} 停止你当前正在播放的收音机." },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 你可以在以下位置更改你当前的工作 "COL_GREY"市政厅{FFFFFF}!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 你可以在以下位置更改你的生成城市 "COL_GREY"市政厅{FFFFFF}!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 你可以在 "COL_GREY"当铺{FFFFFF}!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 切勿分享你的密码,即使是与服务器所有者也不行!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 你可以访问我们的 Discord 服务器:{7289da}sfcnr.com/discord" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 找到 ChuffSec 的保安卡车 "COL_GREY"/chuffloc{FFFFFF} 并抢劫他的保安卡车以获取现金!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 买一个 "COL_GREY"钱箱{FFFFFF} 增加你从 Supa Save 或 24/7 商店抢劫的战利品! " },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 抓住一辆卡车,将其连接到拖车上,然后开始 "COL_GREY"/work{FFFFFF}! It's rewarding!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 找点事做?致力于你的 "COL_GREY"/achievements"COL_WHITE"!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 检查你的全球 SF-CNR 排名 "COL_GREY"/rank"COL_WHITE"!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 考虑在吉兹附近或采石场开采一些矿石!这可是一笔不错的工资啊!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 看看你生成了多少个 IC 代币 "COL_GREY"/irresistiblecoins"COL_WHITE"." },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 与你的帮派成员分享你的抢劫利润 "COL_GREY"/gang splitprofit"COL_WHITE"." },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 切换你生成的总金币栏 "COL_GREY"/cp"COL_WHITE"." },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 通过经常玩游戏并利用所有功能来分配等级!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 查看你目前正在进行的抢劫,逮捕和杀戮 "COL_GREY"/streaks"COL_WHITE"!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 看看你最喜欢的武器是什么 "COL_GREY"/weaponstats"COL_WHITE"!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 秘密每月最高捐助者可以在月底领取奖品!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 对服务器有任何反馈吗?使用 "COL_GREY"/feedback"COL_WHITE"!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 使用以下方式将电子邮件附加到你的帐户 "COL_GREY"/email"COL_WHITE" 安全功能和免费 3 天 VIP!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 想组建犯罪企业?创建一个帮派并邀请你的朋友一起 "COL_GREY"/gang create"COL_WHITE"!" },
		{ "SLOT_MACHINES" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 在赌场玩轮盘赌,你在单个数字上投入的钱最多可赢得 35x!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 在赌场玩二十一点,很快你的钱就会翻倍!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 在任何赌场与你的朋友一起玩扑克!踏上致富之路!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 通过在任何赌场赌博获得赌场奖励积分!使用 "COL_GREY"/casino rewards"COL_WHITE" 花他们!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 使用以下方法在街头比赛或超越比赛中与你的朋友比赛 "COL_GREY"/race"COL_WHITE"!" },
		//{ "{8ADE47}Stephanie:"COL_WHITE" Want 3 days of free V.I.P? Add an "COL_GREY"/email"COL_WHITE" to your account!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 为我们的功能做出贡献 "COL_GREY"/crowdfunds"COL_WHITE"!早期支持者获得福利!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 你可以使用以下方式购买高级玩家房屋 "COL_GREY"/estate"COL_WHITE"!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 你可以使用以下方式从玩家那里购买 IC 代币 "COL_GREY"/ic buy"COL_WHITE"!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 购买一个安全的钱包,以减少你死时掉落的金钱数量!" },
		{ "{8ADE47}斯蒂芬妮:"COL_WHITE" 购买便携式音响,与你所在地区的朋友一起举办音乐派对!" }
	},
	g_randomMessageTick 			= 0
;

/* ** Hooks ** */
hook OnServerUpdate( )
{
	if ( GetServerTime( ) > g_randomMessageTick )
	{
		new
			iRandomMessage = random( sizeof( g_randomMessages ) );

		if ( strmatch( g_randomMessages[ iRandomMessage ], "SLOT_MACHINES" ) )
		{
			new
				iRandom = random( 3 );

			if ( iRandom == 2 )
				SendClientMessageToAllFormatted( -1, "{8ADE47}斯蒂芬妮:"COL_WHITE" Visage 赌场的奖池为 "COL_GREY"%s"COL_WHITE",用老虎机来试试赢吧!", cash_format( g_casinoPoolData[ 2 ] [ E_POOL ] ) );
			else if ( iRandom == 1 )
				SendClientMessageToAllFormatted( -1, "{8ADE47}斯蒂芬妮:"COL_WHITE" 4 龙赌场的奖池为 "COL_GREY"%s"COL_WHITE",用老虎机来试试赢吧!", cash_format( g_casinoPoolData[ 1 ] [ E_POOL ] ) );
			else
				SendClientMessageToAllFormatted( -1, "{8ADE47}斯蒂芬妮:"COL_WHITE" 卡利古拉斯赌场的奖池为 "COL_GREY"%s"COL_WHITE",用老虎机来试试赢吧!", cash_format( g_casinoPoolData[ 0 ] [ E_POOL ] ) );
		}
		else
		{
	 		SendClientMessageToAll( -1, g_randomMessages[ iRandomMessage ] );
		}

		// throttle
		g_randomMessageTick = GetServerTime( ) + 60;
	}
	return Y_HOOKS_CONTINUE_RETURN_1;
}
