#include "lib_fmask"

void main()
{
    object oPC = GetLastPlayerToSelectTarget();
    if(!GetLocalInt(oPC, FMASK_LVAR_TARGETING)) return;
    DeleteLocalInt(oPC, FMASK_LVAR_TARGETING);

    FmaskHandleFlayTarget(oPC);
}
