#include "lib_bld"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    BldEnsureRecord(oPC);
    BldApplyEffects(oPC);
}
