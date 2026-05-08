// test_fac.nss - Faction Reputation: demo placeable OnUsed script
//
// Place a placeable (e.g. a notice board) in the toolset and set its
// OnUsed event to "test_fac". Using it cycles through demo scenarios:
//
//   First use:  opens the Faction Reputation window
//   !fac <faction_id> <delta> in chat: adjusts reputation (DM only)
//
// Demonstrates the full flow: reputation change -> standing tier flip ->
// effect reapplication -> UI refresh.

#include "lib_fac"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // Demo: grant starting reputation spread so the window is interesting
    int nAlreadySeeded = GetLocalInt(oPC, "FAC_TEST_SEEDED");
    if(!nAlreadySeeded)
    {
        SetLocalInt(oPC, "FAC_TEST_SEEDED", 1);

        // Iron Guard: friendly territory
        FacAdjust(oPC, FAC_ID_IRON_GUARD,  200, "test:seed");
        // Brotherhood: mild dislike (rival penalty already reduced Iron Guard a bit)
        // Night Cult: deep hostile
        FacAdjust(oPC, FAC_ID_NIGHT_CULT, -300, "test:seed");
        // Order of Flame: honored
        FacAdjust(oPC, FAC_ID_ORDER_FLAME, 600, "test:seed");

        SendMessageToPC(oPC,
            "[Test Frakcji] Reputacja startowa ustawiona. "
            "Otwieranie panelu...");
    }

    FacOpenWindow(oPC);
}
