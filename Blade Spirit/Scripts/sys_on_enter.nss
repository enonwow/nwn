#include "lib_bs_def"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    BsCheckAndApplyBonuses(oPC);
}
