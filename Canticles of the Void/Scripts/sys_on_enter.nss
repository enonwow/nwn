#include "lib_cvoid"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    // Decay taint naturally (1 per elapsed day, max 10 per login)
    CvoidTickDailyDecay(oPC);

    // Reapply persistent corruption effects based on current taint
    int nTaint = CvoidGetTaint(oPC);
    if(nTaint > 0)
        CvoidApplyTaintEffects(oPC, nTaint);
}
