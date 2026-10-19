/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\jobs.pwn
 * Purpose: job/skill related data and helpers
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_JOB_NAME 				( 16 )

/* ** Variables ** */
enum
{
	JOB_MUGGER,
	JOB_KIDNAPPER,
	JOB_TERRORIST,
	JOB_HITMAN,
	JOB_WEAPON_DEALER,
	JOB_DRUG_DEALER,
	JOB_DIRTY_MECHANIC,
	JOB_BURGLAR
};

static const
	g_jobsData[ ] [ MAX_JOB_NAME ] =
	{
		{ "Mugger" }, { "Kidnapper" }, { "Terrorist" }, { "Hitman" },
		{ "Weapon Dealer" }, { "Drug Dealer" }, { "Dirty Mechanic" }, { "Burglar" }
	}
;

static const g_jobDisplayNames[][MAX_JOB_NAME] =
{
	"劫匪", "绑匪", "恐怖分子", "职业杀手",
	"武器商", "毒贩", "黑市修车工", "窃贼"
};

static stock
	g_jobList[ 100 ];

/* ** Hooks ** */
hook OnScriptInit( )
{
	for ( new i = 0; i < sizeof( g_jobsData ); i ++ ) {
		format( g_jobList, sizeof( g_jobList ), "%s%s\n", g_jobList, g_jobDisplayNames[ i ] );
	}
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_ONLINE_JOB && response )
	{
		szLargeString[ 0 ] = '\0';

		foreach ( new pID : Player ) if ( IsPlayerJob( pID, listitem ) && p_Class[ pID ] == CLASS_CIVILIAN ) {
	        format( szLargeString, sizeof( szLargeString ), "%s%s(%d)\n", szLargeString, ReturnPlayerName( pID ), pID );
		}

		// found no users
		if ( szLargeString[ 0 ] == '\0' ) {
			szLargeString = ""COL_RED"N/A";
		}

		ShowPlayerDialog( playerid, DIALOG_ONLINE_JOB_R, DIALOG_STYLE_LIST, sprintf( "{FFFFFF}在线%s", GetJobName( listitem ) ), szLargeString, "确定", "返回" );
	}
	else if ( dialogid == DIALOG_ONLINE_JOB_R && ! response ) {
		ShowPlayerDialog( playerid, DIALOG_ONLINE_JOB, DIALOG_STYLE_LIST, "{FFFFFF}玩家职业", g_jobList, "选择", "取消" );
	}
	return 1;
}

/* ** Commands ** */
CMD:playerjobs( playerid, params[ ] )
{
	ShowPlayerDialog( playerid, DIALOG_ONLINE_JOB, DIALOG_STYLE_LIST, "{FFFFFF}玩家职业", g_jobList, "选择", "取消" );
	return 1;
}

/* ** Functions ** */
stock IsPlayerJob( playerid, jobid ) {
	return ( p_Job{ playerid } == jobid ) || ( IsPlayerPlatinumVIP( playerid ) && p_VIPJob{ playerid } == jobid );
}

stock GetJobIDFromName( const job_name[ ] )
{
	for ( new iJob = 0; iJob < sizeof( g_jobsData ); iJob ++ ) {
		if ( strfind( g_jobsData[ iJob ], job_name, true ) != -1 ) {
			return iJob;
		}
	}
	return -1;
}

stock GetJobName( iJob ) {
	return 0 <= iJob < sizeof( g_jobsData ) ? g_jobDisplayNames[ iJob ] : ( "未知" );
}

stock ShowPlayerJobList( playerid )
{
	return ShowPlayerDialog( playerid, DIALOG_JOB, DIALOG_STYLE_LIST, "{FFFFFF}选择职业", g_jobList, "选择", "" );
}
