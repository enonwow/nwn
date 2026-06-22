// test_lch.nss — placeable OnUsed: opens the Lichwiarz (Usurer) window
// Place any placeable in the module, set its OnUsed script to test_lch.
#include "lib_lch"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;
    LchOpenWindow(oPC);
}
