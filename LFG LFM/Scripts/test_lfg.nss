// test_lfg.nss
// OnUsed script for the LFG/LFM lever (placeable)

#include "lib_lfg"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;
    CreateLfgWindow(oPC);
}
