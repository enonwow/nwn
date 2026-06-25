#include "lib_rlc"

void main()
{
    // Throttle: run the full PC sweep only ~once per 60 heartbeats (~6 min real time).
    // The SQL timestamp guard in RlcNeedsCurseTick prevents double escalation regardless.
    int nCount = GetLocalInt(GetModule(), "RLC_HB_COUNT");
    nCount++;
    if(nCount < 60)
    {
        SetLocalInt(GetModule(), "RLC_HB_COUNT", nCount);
        return;
    }
    SetLocalInt(GetModule(), "RLC_HB_COUNT", 0);

    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        RlcCheckCurseTick(oPC);
        oPC = GetNextPC();
    }
}
