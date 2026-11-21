#include "lib_dur"

// Fires every 6 seconds (NWN default module heartbeat).
// Every 10th tick (~60 s) we apply combat-based durability decay to
// all PCs currently fighting. Counters persist only for this session;
// a server restart resets them, which is acceptable.

void main()
{
    int nTick = GetLocalInt(GetModule(), "DUR_HB_TICK") + 1;
    SetLocalInt(GetModule(), "DUR_HB_TICK", nTick);

    if(nTick % 10 != 0) return;

    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(!GetIsDMPossessed(oPC) && GetIsInCombat(oPC))
            DurDecayCombatPC(oPC);
        oPC = GetNextPC();
    }
}
