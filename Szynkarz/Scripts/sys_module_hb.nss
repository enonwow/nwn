// sys_module_hb.nss — Szynkarz: per-heartbeat intox decay
// Hook: Module Properties -> Events -> OnHeartbeat
// Fires every 6 seconds; decay logic runs every SYN_HB_DECAY_EVERY ticks (~30 s).

#include "lib_syn"

void main()
{
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(!GetIsDM(oPC))
        {
            // Only process if PC has nonzero cached intox (avoids SQL per tick)
            if(GetLocalInt(oPC, "SYN_INTOX_CACHE") > 0)
                SynOnHeartbeat(oPC);
        }
        oPC = GetNextPC();
    }
}
