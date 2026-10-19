#include <a_samp>
#include "../gamemodes/irresistible/gta/vehicle_data.pwn"
#include "../gamemodes/irresistible/gta/map.pwn"

new failures;

stock Check(bool:condition, const label[])
{
    if (!condition)
    {
        printf("[LOCALIZATION CHECK] FAIL: %s", label);
        failures++;
    }
}

main() {}
forward StopLocalizationTest();
public StopLocalizationTest() { SendRconCommand("exit"); }

public OnGameModeInit()
{
    Check(GetVehicleModelFromName("Ambulance") == 416, "English vehicle lookup");
    Check(GetVehicleModelFromName("aMbUlAnCe") == 416, "case-insensitive vehicle lookup");
    Check(GetVehicleModelFromName("Infernus") == 411, "retained model name");
    Check(GetVehicleModelFromName("not-a-vehicle") == -1, "unknown vehicle lookup");

    new vehicle[32], modelid = 416;
    format(vehicle, sizeof(vehicle), "%s", GetVehicleName(modelid));
    Check(strlen(vehicle) == 6 && vehicle[0] == 190 && vehicle[1] == 200
          && vehicle[2] == 187 && vehicle[3] == 164
          && vehicle[4] == 179 && vehicle[5] == 181, "CP936 vehicle display bytes");
    modelid = 411;
    format(vehicle, sizeof(vehicle), "%s", GetVehicleName(modelid));
    Check(!strcmp(vehicle, "Infernus"), "vehicle proper name display");
    modelid = 399;
    format(vehicle, sizeof(vehicle), "%s", GetVehicleName(modelid));
    Check(strlen(vehicle) == 4, "invalid vehicle model display");

    new city[MAX_ZONE_NAME];
    Get2DCity(city, -1700.0, 700.0);
    Check(!strcmp(city, "San Fierro"), "canonical SF name used by robbery payouts");
    Get2DCity(city, 1500.0, -1700.0);
    Check(!strcmp(city, "Los Santos"), "canonical LS name used by robbery payouts");
    Get2DCity(city, 2000.0, 1500.0);
    Check(!strcmp(city, "Las Venturas"), "canonical LV name used by robbery payouts");

    format(city, sizeof(city), "%s", GetLocationDisplayName("San Fierro"));
    Check(strlen(city) == 8 && city[0] == 202 && city[1] == 165
          && city[2] == 183 && city[3] == 198, "CP936 city display bytes");
    new combined[64];
    format(combined, sizeof(combined), "%s|%s", GetLocationDisplayName("San Fierro"),
           GetLocationDisplayName("Los Santos"));
    Check(strlen(combined) == 15 && combined[8] == '|', "two location displays in one message");
    Check(!strcmp(GetLocationDisplayName("custom-place"), "custom-place"), "custom location passthrough");

    printf("[LOCALIZATION CHECK] Completed: %d failures", failures);
    SetTimer("StopLocalizationTest", 100, false);
    return 1;
}
