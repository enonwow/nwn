// sys_on_enter.nss — OnClientEnter hook for Vices.
// Restores effects and starts the per-PC addiction tick.
#include "lib_vic"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    VicRestoreEffects(oPC);
    VicStartTick(oPC);
}
