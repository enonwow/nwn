// test_eatt.nss — OnUsed script for Resonance Stone placeable
// Place a placeable with Tag "EATT_STONE" in the module and assign this script to its OnUsed event.
#include "lib_eatt"

void main()
{
    object oPC = GetLastUsedBy();
    if (!GetIsPC(oPC)) return;
    EattOpenWindow(oPC);
}
