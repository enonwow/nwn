#include "lib_mia"

// Module OnClientLeave. Cleans up effects so they don't persist in the PC save.
void main()
{
    object oPC = GetExitingObject();
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;

    MiaRemoveEffects(oPC);
    MiaHideGauge(oPC);
    DeleteLocalInt(oPC, MIA_LVAR_TICKING);
    DeleteLocalInt(oPC, MIA_LVAR_EXPOSURE);
    DeleteLocalInt(oPC, MIA_LVAR_TYPE);
    DeleteLocalInt(oPC, MIA_LVAR_LAST_LVL);
}
