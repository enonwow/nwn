#include "lib_mrel"

// Place on a Placeable (OnUsed event) for demo / testing.
// Using it opens the Living Relics window for the activating PC.
// Using it while holding Shift simulates a kill-trigger (+2 memory) for testing.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // If the PC has a held item (via ActionUseItem with tag "mrel_test_feed"),
    // simulate a kill event instead of opening the window.
    // For standard use: just open the window.
    MrelCreateWindow(oPC);
}
