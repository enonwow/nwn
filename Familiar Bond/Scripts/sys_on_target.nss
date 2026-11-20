#include "lib_fam"

void main()
{
    object oPC = GetLastPlayerToSelectTarget();
    if(!GetIsPC(oPC)) return;

    if(!GetLocalInt(oPC, FAM_LVAR_TARGETING)) return;
    DeleteLocalInt(oPC, FAM_LVAR_TARGETING);

    FamOnCarryTarget(oPC);
}
