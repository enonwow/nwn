// test_hench.nss
// OnUsed (lever) - opens the henchman system window
#include "lib_hench"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;
    CreateHenchWindow(oPC);
}
