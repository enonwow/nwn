#include "lib_obs"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    ObsRegisterPC(oPC);
    DelayCommand(3.0, ObsRestoreEffects(oPC));
}
