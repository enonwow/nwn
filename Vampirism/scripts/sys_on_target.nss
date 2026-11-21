#include "lib_vamp"

// OnPlayerTarget: routes the creature-select result back to the feeding mechanic.
// This script must be assigned to the module's OnPlayerTarget event.

void main()
{
    object oPC = GetLastPlayerToSelectTarget();
    if(!GetIsPC(oPC)) return;
    if(!GetLocalInt(oPC, VAMP_LVAR_IS_FEEDING)) return;
    if(!VampIsVampire(oPC)) return;

    object oTarget = GetTargetingModeSelectedObject();
    VampFeedOnTarget(oPC, oTarget);
}
