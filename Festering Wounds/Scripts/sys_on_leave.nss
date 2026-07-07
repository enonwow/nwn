#include "lib_fwnd_def"

void main()
{
    object oPC = GetExitingObject();
    if(!GetIsPC(oPC)) return;

    // Stop the per-PC heartbeat loop — effects are re-applied on next login.
    SetLocalInt(oPC, FWND_LVAR_LOOP_RUN, 0);
}
