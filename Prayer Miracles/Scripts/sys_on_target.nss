#include "lib_pr"

void main()
{
    object oPC = GetLastPlayerToSelectTarget();
    if(!GetIsPC(oPC)) return;
    if(GetLocalInt(oPC, PR_LVAR_PENDING_TARGET) > 0)
        PrOnPlayerTarget(oPC);
}
