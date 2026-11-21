#include "lib_carto"

// OnUsed script for a test placeable — opens the Cartomancer journal.
// Place a placeable in your test module, set its OnUsed script to test_carto.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    CartoOpen(oPC);
}
