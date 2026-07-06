// test_hom.nss — placeable OnUsed script; opens the Homunculus panel
// Attach to a placeable (e.g. an alchemical workbench) as its OnUsed event.
#include "lib_hom"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    HomCreateWindow(oPC);
}
