// test_san.nss — OnUsed script for the demo placeable.
//   Place a placeable (tag: "san_mirror") in the test module and assign
//   this script to its OnUsed event.  Using it opens the Sanity window.
//   A second placeable (tag: "san_altar_dark") can be used to simulate
//   a horror-area sanity drain for testing without a live heartbeat.

#include "lib_san"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    string sTag = GetTag(OBJECT_SELF);

    if(sTag == "san_mirror")
    {
        SanOpen(oPC);
        return;
    }

    if(sTag == "san_altar_dark")
    {
        // Simulate a horror-zone drain — useful for QA.
        int nNew = SanAdjust(oPC, -SAN_LOSS_HORROR_AREA * 5,
            "Czarny ołtarz wysysa twoją wolę");
        if(nNew >= 0) SanSyncEffects(oPC);

        FloatingTextStringOnCreature(
            "Czarny ołtarz pulsuje złowrogą mocą...", oPC, FALSE);

        int nToken = NuiFindWindow(oPC, SAN_WINDOW);
        if(nToken != 0) SanFeedWindow(oPC, nToken);
        return;
    }

    if(sTag == "san_font_holy")
    {
        // Simulate holy-water recovery — useful for QA.
        int nSan = SanGetSanity(oPC);
        if(nSan >= SAN_MAX)
        {
            SendMessageToPC(oPC, "[Szaleństwo] Twój umysł jest już spokojny.");
            return;
        }
        SanAdjust(oPC, SAN_GAIN_HOLY, "Święte źródło");
        SanSyncEffects(oPC);
        FloatingTextStringOnCreature(
            "Święta woda spływa spokojnie przez twój umysł...", oPC, FALSE);

        int nToken = NuiFindWindow(oPC, SAN_WINDOW);
        if(nToken != 0) SanFeedWindow(oPC, nToken);
        return;
    }
}
