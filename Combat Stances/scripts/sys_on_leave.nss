#include "lib_stn"

void main()
{
    object oPC = GetExitingObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    // Remove stance effects on exit; they are restored on next enter.
    StnRemoveEffects(oPC);
}
