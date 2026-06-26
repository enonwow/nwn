#include "lib_wkr"

// Runs on OnModuleHeartbeat. HB fires every 6 seconds in NWN.
// Proximity updates run every tick; debt violation check runs every
// WKR_HB_INTERVAL ticks (~1 minute) to avoid excessive SQL queries.
void main()
{
    int nTick = GetLocalInt(GetModule(), WKR_LVAR_HB_TICK) + 1;
    SetLocalInt(GetModule(), WKR_LVAR_HB_TICK, nTick);

    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        WkrUpdateProximityForPC(oPC);
        oPC = GetNextPC();
    }

    if(nTick % WKR_HB_INTERVAL == 0)
        WkrCheckOverdueDebts();
}
