#include "lib_fcraft_ev"

void main()
{
    object oPC = GetLastPlayerToSelectTarget();
    if(!GetIsPC(oPC)) return;

    // Only handle if we set the targeting flag for this module
    if(GetLocalString(oPC, FCRAFT_LVAR_TARGETING) == "") return;

    FcraftOnTarget(oPC);
}
