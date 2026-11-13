#include "lib_sdebt"

// OnUsed on a placeable ("Księga Dusz") — opens the Soul Debt window for the activator.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;
    SDebtOpenWindow(oPC);
}
