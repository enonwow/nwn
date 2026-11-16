// test_bld.nss
// Place as OnUsed on any placeable (e.g. a Blood Font) to open the Bloodline window.

#include "lib_bld"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return;

    BldOpenWindow(oPC);
}
