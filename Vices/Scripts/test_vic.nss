// test_vic.nss — OnUsed script for a demo placeable.
// Place a placeable with this script on OnUsed to open the Vices panel.
// The "Spożyj" buttons consume doses directly (no item requirement in demo mode).
#include "lib_vic"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    VicOpenWindow(oPC);
}
