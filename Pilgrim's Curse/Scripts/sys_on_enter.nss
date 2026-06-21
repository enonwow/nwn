#include "lib_plg"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    PlgRegisterPlayer(oPC);
    PlgApplyBurdenEffects(oPC);
}
