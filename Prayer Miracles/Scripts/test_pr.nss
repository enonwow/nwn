#include "lib_pr"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;
    CreatePrWindow(oPC);
}
