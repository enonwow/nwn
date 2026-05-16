// test_haz.nss — OnUsed script for the gambling-table placeable demo
// Place a placeable in the toolset, set its OnUsed event to this script.
#include "lib_haz"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;
    HazOpenWindow(oPC);
}
