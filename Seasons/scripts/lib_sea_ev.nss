#include "lib_sea"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    // ---- Player window ----
    if (nToken == NuiFindWindow(oPC, SEA_WIN_PLAYER))
    {
        if (sEvent == EVENT_TYPE_CLICK && sElem == SEA_BTN_CLOSE)
            NuiDestroy(oPC, nToken);
        return;
    }

    // ---- DM window ----
    if (nToken != NuiFindWindow(oPC, SEA_WIN_DM)) return;
    if (!GetIsDM(oPC) && !GetIsDMPossessed(oPC)) return;

    if (sEvent == EVENT_TYPE_CLICK)
    {
        if (sElem == SEA_BTN_DM_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        // Season cycling — takes effect immediately
        if (sElem == SEA_BTN_NEXT_SEA || sElem == SEA_BTN_PREV_SEA)
        {
            json jState  = SeaGetStateRow();
            int  nCur    = JsonGetInt(JsonObjectGet(jState, "season"));
            int  nNew    = (sElem == SEA_BTN_NEXT_SEA) ? SeaNextSeason(nCur) : SeaPrevSeason(nCur);
            SeaSetSeason(nNew);
            SeaUpdateAllPCs();
            SeaUpdateAllWindows();
            SeaNotifyAll("Nadeszła nowa pora roku: " + SeaGetSeasonName(nNew) + ".");
            return;
        }

        // Weather cycling — takes effect immediately
        if (sElem == SEA_BTN_NEXT_WEA || sElem == SEA_BTN_PREV_WEA)
        {
            json jState  = SeaGetStateRow();
            int  nCur    = JsonGetInt(JsonObjectGet(jState, "weather"));
            int  nNew    = (sElem == SEA_BTN_NEXT_WEA) ? SeaNextWeather(nCur) : SeaPrevWeather(nCur);
            SeaSetWeather(nNew);
            SeaUpdateAllPCs();
            SeaUpdateAllWindows();
            SeaNotifyAll(SeaGetWeatherName(nNew) + " — zmieniła się pogoda.");
            return;
        }

        // Climate zone buttons for the DM's current area
        int ci;
        for (ci = 0; ci < SEA_CLIMATE_COUNT; ci++)
        {
            if (sElem == SEA_BTN_CLIMATE + IntToString(ci))
            {
                object oArea    = GetArea(oPC);
                string sAreaTag = GetTag(oArea);
                SeaSetAreaClimate(sAreaTag, ci);
                SendMessageToPC(oPC, "[Klimat] Ustawiono strefę '"
                    + SeaGetClimateName(ci) + "' dla: " + GetName(oArea) + ".");
                SeaFeedDMWindow(oPC, nToken);
                return;
            }
        }
    }
}
