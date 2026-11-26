#include "lib_lbr"

void main()
{
    object oPC = GetLastPlayerToSelectTarget();
    if(!GetLocalInt(oPC, LBR_LVAR_TARGETING)) return;

    object oTarget = GetTargetingModeSelectedObject();
    LbrHarvestEssence(oPC, oTarget);

    // Re-open collection window after harvesting
    LbrOpenWindow(oPC);
}
