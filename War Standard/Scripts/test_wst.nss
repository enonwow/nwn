// =============================================================================
// test_wst.nss
// =============================================================================
// OnUsed script for a test placeable.  Assign this script to any placeable in
// the toolset to get a quick in-game demo of the War Standard system:
//
//   - Use the placeable once  → opens the overview panel
//   - Opens a plant dialog from the overview → plants a Legion standard at
//     the PC's feet with the inscription "Testowy"
//   - Use the placeable again to refresh the overview list
//
// This script does not modify any module-level state.
// =============================================================================

#include "lib_wst"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // Ensure tables exist (safe to call multiple times).
    WstCreateTables();

    WstOpenOverview(oPC);
    SendMessageToPC(oPC, "[War Standard] Panel otwarty. Użyj przycisku 'Wznieś Sztandar' aby przetestować.");
}
