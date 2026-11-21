#include "lib_exrc"

// Wire this into the module's OnModuleHeartbeat script.
// Whispers fire roughly once per minute per possessed PC (checked each HB,
// i.e., every 6 seconds, gated by a cooldown LVAR).

const string EXRC_HB_TICK = "EXRC_HB_TICK";
const int    EXRC_HB_FREQ = 10;    // every ~60 seconds (10 x 6s heartbeats)

void main()
{
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        int nLevel = ExrcGetLevel(oPC);
        if(nLevel > EXRC_LEVEL_CLEAN)
        {
            int nTick = GetLocalInt(oPC, EXRC_HB_TICK) + 1;
            SetLocalInt(oPC, EXRC_HB_TICK, nTick);
            if(nTick >= EXRC_HB_FREQ)
            {
                SetLocalInt(oPC, EXRC_HB_TICK, 0);
                ExrcSendWhisper(oPC);
            }
        }
        oPC = GetNextPC();
    }
}
