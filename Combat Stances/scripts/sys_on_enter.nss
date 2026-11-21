#include "lib_stn"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    StnRegisterPlayer(oPC);

    int nActive = StnGetActiveStance(oPC);
    StnApplyEffects(oPC, nActive);

    // Show widget if using a non-neutral stance
    if(nActive != STN_STANCE_READY)
        CreateStanceWidget(oPC);
}
