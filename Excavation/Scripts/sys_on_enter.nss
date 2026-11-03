#include "lib_exc"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    // Re-apply relic bonuses each login; effects are permanent but stripped on logout
    ExcApplyRelicEffects(oPC);
}
