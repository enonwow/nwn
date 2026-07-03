// =============================================================================
// test_wnt.nss
// =============================================================================
// Demonstration script — place on a Placeable's OnUsed event.
//
// Each use adds 25 heat points (counts as one crime), then opens the Records
// Panel so you can observe the threshold system and test the bribe/surrender
// buttons. Use repeatedly to climb through all five wanted levels.
//
// To reset: log out and wait for decay (at test rate ~4 minutes for full drain),
// or trigger WantedSurrender() directly from a DM conversation script.
// =============================================================================

#include "lib_wnt"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;

    // Simulate one crime: add 25 heat.
    WantedAddHeat(oPC, 25, TRUE);

    string sUuid = GetObjectUUID(oPC);
    struct WantedState s = WantedGetState(sUuid);
    int nHeat = WantedCalcHeat(s);
    int nLvl  = WantedGetLevel(nHeat);

    SendMessageToPC(oPC,
        "[Wanted] Popelniles przestepstwo! "
        + "Goraczka: " + IntToString(nHeat) + "/100. "
        + "Status: " + WantedGetLevelName(nLvl) + ". "
        + "Przestepstw lacznie: " + IntToString(s.crimes_committed));

    // Ensure the HUD is visible.
    if(NuiFindWindow(oPC, WNT_HUD_WIN) == 0)
        WantedCreateHud(oPC);

    // Open the Records Panel (toggle: second use while panel is open closes it).
    if(NuiFindWindow(oPC, WNT_PANEL_WIN) != 0)
        WantedDestroyPanel(oPC);
    else
        WantedOpenPanel(oPC);
}
