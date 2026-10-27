// sys_on_hbeat.nss — Wyrd System module heartbeat.
// Hook as OnModuleHeartbeat (fires every 6 real seconds).
// Loops all PCs: ticks wyrd decay and checks for spirit spawns.
// If the module already has a heartbeat script, call WyrdModuleHeartbeat()
// from it instead.
#include "lib_wyrd"

void WyrdModuleHeartbeat()
{
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(!GetIsDMPossessed(oPC))
        {
            WyrdDecayTick(oPC);
            WyrdCheckSpirits(oPC);
        }
        oPC = GetNextPC();
    }
}

void main()
{
    WyrdModuleHeartbeat();
}
