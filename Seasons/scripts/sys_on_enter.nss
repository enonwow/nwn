#include "lib_sea"

void main()
{
    object oPC = GetEnteringObject();
    if (!GetIsPC(oPC)) return;

    // Apply current weather penalties; also removes stale effects for returning PCs
    SeaApplyWeatherEffects(oPC);

    // Notify if effects are active
    json jState = SeaGetStateRow();
    if (JsonGetType(jState) == JSON_TYPE_NULL) return;

    int nSeason  = JsonGetInt(JsonObjectGet(jState, "season"));
    int nWeather = JsonGetInt(JsonObjectGet(jState, "weather"));

    string sMsg = SeaGetSeasonName(nSeason) + " — " + SeaGetWeatherName(nWeather) + ".";
    SendMessageToPC(oPC, "[Klimat] " + sMsg);
}
