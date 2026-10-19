/*
 * Irresistible Gaming 2018
 * Developed by Lorenc
 * Module: gta\vehicles.inc
 * Purpose: gta vehicle related data
 */

/* ** Macros ** */
#define GetVehicleName(%0)  ((%0 - 400) < 0 || (%0 - 400 >= sizeof(g_aVehicleDisplayNames)) ? ("\206;\180;\214;\170;") : g_aVehicleDisplayNames[%0 - 400])

/* ** Variables ** */
stock const g_aVehicleNames[ 212 ] [ ] =
{
	{ "Landstalker" },	{ "Bravura" },				{ "Buffalo" },			{ "Linerunner" },		{ "Perenniel" },		{ "Sentinel" },			{ "Dumper" },
	{ "Firetruck" },	{ "Trashmaster" },			{ "Stretch" },			{ "Manana" },			{ "Infernus" },			{ "Voodoo" },			{ "Pony" },				{ "Mule" },
	{ "Cheetah" },		{ "Ambulance" },			{ "Leviathan" },		{ "Moonbeam" },			{ "Esperanto" },		{ "Taxi" },				{ "Washington" },
	{ "Bobcat" },		{ "Mr Whoopee" },			{ "BF Injection" },		{ "Hunter" },			{ "Premier" },			{ "Enforcer" },			{ "Securicar" },
	{ "Banshee" },		{ "Predator" },				{ "Bus" },{ "Rhino" },	{ "Barracks" },			{ "Hotknife" },			{ "Trailer 1" },		{ "Previon" },
	{ "Coach" },		{ "Cabbie" },				{ "Stallion" },			{ "Rumpo" },			{ "RC Bandit" },		{ "Romero" },			{ "Packer" },			{ "Monster" },
	{ "Admiral" },		{ "Squalo" },				{ "Seasparrow" },		{ "Pizzaboy" },			{ "Tram" },				{ "Trailer 2" },		{ "Turismo" },
	{ "Speeder" },		{ "Reefer" },				{ "Tropic" },			{ "Flatbed" },			{ "Yankee" },			{ "Caddy" },			{ "Solair" },			{ "Berkley's RC Van" },
	{ "Skimmer" },		{ "PCJ-600" },				{ "Faggio" },			{ "Freeway" },			{ "RC Baron" },			{ "RC Raider" },		{ "Glendale" },			{ "Oceanic" },
	{ "Sanchez" },		{ "Sparrow" },				{ "Patriot" },			{ "Quad" },				{ "Coastguard" },		{ "Dinghy" },			{ "Hermes" },			{ "Sabre" },
	{ "Rustler" },		{ "ZR-350" },				{ "Walton" },			{ "Regina" },			{ "Comet" },			{ "BMX" },				{ "Burrito" },			{ "Camper" },			{ "Marquis" },
	{ "Baggage" },		{ "Dozer" },				{ "Maverick" },			{ "News Chopper" },		{ "Rancher" },			{ "FBI Rancher" },		{ "Virgo" },			{ "Greenwood" },
	{ "Jetmax" },		{ "Hotring" },				{ "Sandking" },			{ "Blista Compact" },	{ "Police Maverick" },	{ "Boxville" },			{ "Benson" },
	{ "Mesa" },			{ "RC Goblin" },			{ "Hotring Racer A" },	{ "Hotring Racer B" },	{ "Bloodring Banger" },	{ "Rancher" },
	{ "Super GT" },		{ "Elegant" },				{ "Journey" },			{ "Bike" },				{ "Mountain Bike" },	{ "Beagle" },			{ "Cropdust" },			{ "Stuntplane" },
	{ "Tanker" }, 		{ "Roadtrain" },			{ "Nebula" },			{ "Majestic" },			{ "Buccaneer" },		{ "Shamal" },			{ "Hydra" },			{ "FCR-900" },
	{ "NRG-500" },		{ "HPV1000" },				{ "Cement Truck" },		{ "Tow Truck" },		{ "Fortune" },			{ "Cadrona" },			{ "FBI Truck" },
	{ "Willard" },		{ "Forklift" },				{ "Tractor" },			{ "Combine" },			{ "Feltzer" },			{ "Remington" },		{ "Slamvan" },
	{ "Blade" },		{ "Freight" },				{ "Streak" },			{ "Vortex" },			{ "Vincent" },			{ "Bullet" },			{ "Clover" },			{ "Sadler" },
	{ "Firetruck LA" },	{ "Hustler" },				{ "Intruder" },			{ "Primo" },			{ "Cargobob" },			{ "Tampa" },			{ "Sunrise" },			{ "Merit" },
	{ "Utility" },		{ "Nevada" },				{ "Yosemite" },			{ "Windsor" },			{ "Monster A" },		{ "Monster B" },		{ "Uranus" },			{ "Jester" },
	{ "Sultan" },		{ "Stratum" },				{ "Elegy" },			{ "Raindance" },		{ "RC Tiger" },			{ "Flash" },			{ "Tahoma" },			{ "Savanna" },
	{ "Bandito" },		{ "Freight Flat" },			{ "Streak Carriage" },	{ "Kart" },				{ "Mower" },			{ "Duneride" },			{ "Sweeper" },
	{ "Broadway" },		{ "Tornado" },				{ "AT-400" },			{ "DFT-30" },			{ "Huntley" },			{ "Stafford" },			{ "BF-400" },			{ "Newsvan" },
	{ "Tug" },			{ "Trailer 3" },			{ "Emperor" },			{ "Wayfarer" },			{ "Euros" },			{ "Hotdog" },			{ "Club" },				{ "Freight Carriage" },
	{ "Trailer 3" },	{ "Andromada" },			{ "Dodo" },				{ "RC Cam" },			{ "Launch" },			{ "Police Car LSPD" },	{ "Police Car SFPD" },
	{ "Police LVPD" },	{ "Police Ranger" },		{ "Picador" },			{ "SWAT. Van" },		{ "Alpha" },			{ "Phoenix" },			{ "Glendale" },
	{ "Sadler" },		{ "Luggage Trailer A" },	{ "Luggage Trailer B" },{ "Stair Trailer" },	{ "Boxville" },			{ "Farm Plow" },
	{ "Utility Trailer"}
};

/* ** Functions ** */
stock GetVehicleModelFromName( const szVehicleName[ ] )
{
	for( new i = 400; i <= 611; i++ )
		if( strfind( g_aVehicleNames[ i - 400 ], szVehicleName, true ) != -1 )
			return i;

	return -1;
}

stock IsBoatVehicle(value)
{
	static const valid_values[6] = {
		29425665, -2143286272, 0, 0, 0, 32
	};

	if (430 <= value <= 595) {
		value -= 430;
		return (valid_values[value >>> 5] & (1 << (value & 31))) || false;
	}
	return false;
}

stock IsAirVehicle(value)
{
	static const valid_values[6] = {
		1073742081, 135268352, -1073676096, 192, 262408, 98305
	};

	if (417 <= value <= 593) {
		value -= 417;
		return (valid_values[value >>> 5] & (1 << (value & 31))) || false;
	}
	return false;
}

stock IsBikeVehicle(value)
{
	static const valid_values[5] = {
		1105921, 1610612738, 1536, 0, 1056
	};

	if (448 <= value <= 586) {
		value -= 448;
		return (valid_values[value >>> 5] & (1 << (value & 31))) || false;
	}
	return false;
}

stock IsTrailerVehicle(model) {
	static const valid_values[6] = {
		32769, 0, 0, 0, 270532608, 112640
	};

	if (435 <= model <= 611) {
		model -= 435;
		return (valid_values[model >>> 5] & (1 << (model & 31))) || false;
	}
	return false;
}

stock IsLowriderVehicle(model)
{
	static const valid_values[6] = {
		1, 0, 0, 469762048, 201326592, 24
	};

	if (412 <= model <= 576) {
		model -= 412;
		return (valid_values[model >>> 5] & (1 << (model & 31))) || false;
	}
	return false;
}

stock GetVehicleSeatCount(iModel)
{
    if (400 <= iModel <= 611)
    {
        static
            s_MaxPassengers[] =
            {
                271782163, 288428337, 288559891, -2146225407, 327282960, 271651075, 268443408, 286339857, 319894289, 823136512, 805311233,
                285414161, 286331697, 268513553, 18026752, 286331152, 286261297, 286458129, 856765201, 286331137, 856690995, 269484528,
                51589393, -15658689, 322109713, -15527663, 65343
            }
        ;
        return ((s_MaxPassengers[(iModel -= 400) >>> 3] >>> ((iModel & 7) << 2)) & 0xF);
    }
    return 0xF;
}

stock IsPaintJobVehicle(value) {
    static const valid_values[3] = {
        1, 3670016, 806680576
    };
    if (483 <= value <= 576) {
        value -= 483;
        return (valid_values[value >>> 5] & (1 << (value & 31))) || false;
    }
    return false;
}

stock const g_aVehicleDisplayNames[212][] =
{
	"Landstalker",
	"Bravura",
	"Buffalo",
	"重型牵引车",
	"Perenniel",
	"Sentinel",
	"Dumper",
	"消防车",
	"垃圾车",
	"加长礼车",
	"Manana",
	"Infernus",
	"Voodoo",
	"Pony",
	"Mule",
	"Cheetah",
	"救护车",
	"Leviathan",
	"Moonbeam",
	"Esperanto",
	"出租车",
	"Washington",
	"Bobcat",
	"冰淇淋车",
	"BF Injection",
	"Hunter",
	"Premier",
	"防暴警车",
	"运钞车",
	"Banshee",
	"Predator",
	"长途客车",
	"坦克",
	"军用卡车",
	"Hotknife",
	"货运挂车 1",
	"Previon",
	"旅游巴士",
	"出租车",
	"Stallion",
	"Rumpo",
	"遥控越野车",
	"Romero",
	"运车卡车",
	"Monster",
	"Admiral",
	"Squalo",
	"Seasparrow",
	"送餐摩托",
	"有轨电车",
	"货运挂车 2",
	"Turismo",
	"Speeder",
	"Reefer",
	"Tropic",
	"平板卡车",
	"Yankee",
	"高尔夫球车",
	"Solair",
	"Berkley's RC Van",
	"Skimmer",
	"PCJ-600",
	"Faggio",
	"Freeway",
	"RC Baron",
	"遥控直升机",
	"轿车",
	"Oceanic",
	"Sanchez",
	"Sparrow",
	"Patriot",
	"Quad",
	"海岸巡逻艇",
	"Dinghy",
	"Hermes",
	"Sabre",
	"Rustler",
	"ZR-350",
	"Walton",
	"Regina",
	"Comet",
	"自行车",
	"Burrito",
	"Camper",
	"Marquis",
	"机场牵引车",
	"推土机",
	"Maverick",
	"News Chopper",
	"Rancher",
	"FBI Rancher",
	"Virgo",
	"Greenwood",
	"快艇",
	"赛车",
	"Sandking",
	"Blista Compact",
	"Police Maverick",
	"厢式货车",
	"货车",
	"Mesa",
	"遥控直升机",
	"赛车 A",
	"赛车 B",
	"竞技改装车",
	"Rancher",
	"Super GT",
	"Elegant",
	"房车",
	"自行车",
	"山地自行车",
	"Beagle",
	"农用飞机",
	"特技飞机",
	"油罐牵引车",
	"公路牵引车",
	"Nebula",
	"Majestic",
	"Buccaneer",
	"Shamal",
	"Hydra",
	"FCR-900",
	"NRG-500",
	"HPV1000",
	"水泥搅拌车",
	"拖车",
	"Fortune",
	"Cadrona",
	"FBI 装甲车",
	"Willard",
	"叉车",
	"拖拉机",
	"联合收割机",
	"Feltzer",
	"Remington",
	"Slamvan",
	"Blade",
	"货运机车",
	"客运机车",
	"气垫船",
	"Vincent",
	"Bullet",
	"Clover",
	"Sadler",
	"云梯消防车",
	"Hustler",
	"Intruder",
	"Primo",
	"Cargobob",
	"Tampa",
	"Sunrise",
	"Merit",
	"工程车",
	"Nevada",
	"Yosemite",
	"Windsor",
	"Monster A",
	"Monster B",
	"Uranus",
	"Jester",
	"Sultan",
	"Stratum",
	"Elegy",
	"Raindance",
	"遥控坦克",
	"Flash",
	"Tahoma",
	"Savanna",
	"沙丘越野车",
	"货运车厢",
	"客运车厢",
	"卡丁车",
	"割草车",
	"越野卡车",
	"扫路车",
	"Broadway",
	"Tornado",
	"客机",
	"平板货车",
	"Huntley",
	"Stafford",
	"BF-400",
	"Newsvan",
	"机场牵引车",
	"油罐挂车",
	"Emperor",
	"Wayfarer",
	"Euros",
	"热狗餐车",
	"Club",
	"货运车厢",
	"货运挂车 3",
	"Andromada",
	"Dodo",
	"遥控侦察机",
	"巡逻艇",
	"洛圣都警车",
	"圣菲耶罗警车",
	"拉斯文图拉斯警车",
	"越野警车",
	"Picador",
	"水炮车",
	"Alpha",
	"Phoenix",
	"Glendale",
	"Sadler",
	"行李挂车 A",
	"行李挂车 B",
	"登机梯车",
	"厢式货车",
	"农用挂车",
	"工具挂车"
};
