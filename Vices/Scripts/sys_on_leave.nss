// sys_on_leave.nss — OnClientLeave hook for Vices.
// Stops the tick and strips engine effects (they will be reapplied on next login).
#include "lib_vic"

void main()
{
    object oPC = GetExitingObject();
    if(!GetIsPC(oPC)) return;

    VicStopTick(oPC);

    int i;
    for(i = 0; i < VICE_COUNT; i++)
        VicRemoveEffects(oPC, i);
}
